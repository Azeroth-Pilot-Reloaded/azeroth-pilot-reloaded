#!/usr/bin/env python3
"""Update every library embedded in APR from its authoritative release source."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import re
import shutil
import sys
import tempfile
import time
import urllib.error
import urllib.request
import uuid
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any
from xml.etree import ElementTree


ROOT = Path(__file__).resolve().parents[1]
LIBS_DIR = ROOT / "APR-Core" / "libs"
DEFAULT_MANIFEST = ROOT / "tools" / "libraries.json"
LOCK_FILE = ROOT / "tools" / "libraries.lock.json"
USER_AGENT = "APR-library-updater/1.0 (+https://github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded)"
MAX_ARCHIVE_SIZE = 25 * 1024 * 1024
TEXT_SUFFIXES = {".lua", ".toc", ".xml"}


def request_bytes(url: str, *, accept: str | None = None) -> bytes:
    headers = {"User-Agent": USER_AGENT}
    if accept:
        headers["Accept"] = accept
    github_token = os.environ.get("GITHUB_TOKEN")
    if github_token and "github.com" in url:
        headers["Authorization"] = f"Bearer {github_token}"

    last_error: Exception | None = None
    for attempt in range(3):
        try:
            request = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(request, timeout=60) as response:
                declared_size = response.headers.get("Content-Length")
                if declared_size and int(declared_size) > MAX_ARCHIVE_SIZE:
                    raise RuntimeError(f"download is unexpectedly large: {declared_size} bytes")
                payload = response.read(MAX_ARCHIVE_SIZE + 1)
                if len(payload) > MAX_ARCHIVE_SIZE:
                    raise RuntimeError("download exceeded the 25 MiB safety limit")
                return payload
        except (OSError, urllib.error.URLError, RuntimeError) as error:
            last_error = error
            if attempt < 2:
                time.sleep(1 + attempt)
    raise RuntimeError(f"failed to download {url}: {last_error}")


def request_json(url: str) -> dict[str, Any]:
    return json.loads(request_bytes(url, accept="application/json").decode("utf-8"))


def latest_curseforge_release(source: dict[str, Any]) -> tuple[bytes, dict[str, Any], str]:
    project_id = int(source["project_id"])
    files_url = f"https://www.curseforge.com/api/v1/mods/{project_id}/files"
    files = request_json(files_url).get("data", [])
    releases = [
        file
        for file in files
        if file.get("releaseType") == 1 and file.get("status") == 4
    ]
    if not releases:
        raise RuntimeError(f"CurseForge project {project_id} has no published stable release")

    release = max(releases, key=lambda file: (file.get("dateCreated", ""), int(file["id"])))
    file_id = int(release["id"])
    download_url = f"https://www.curseforge.com/api/v1/mods/{project_id}/files/{file_id}/download"
    archive = request_bytes(download_url)
    metadata = {
        "source": "curseforge",
        "project_id": project_id,
        "file_id": file_id,
        "version": release.get("displayName"),
        "file_name": release.get("fileName"),
        "date_created": release.get("dateCreated"),
        "archive_sha256": hashlib.sha256(archive).hexdigest(),
    }
    return archive, metadata, str(source["archive_root"])


def latest_github_archive(source: dict[str, Any]) -> tuple[bytes, dict[str, Any], str | None]:
    repository = str(source["repository"])
    ref = str(source.get("ref", "main"))
    commit_url = f"https://api.github.com/repos/{repository}/commits/{ref}"
    commit = request_json(commit_url)
    sha = str(commit["sha"])
    archive_url = f"https://codeload.github.com/{repository}/zip/{sha}"
    archive = request_bytes(archive_url)
    metadata = {
        "source": "github",
        "repository": repository,
        "ref": ref,
        "commit": sha,
        "date_created": commit.get("commit", {}).get("committer", {}).get("date"),
        "archive_sha256": hashlib.sha256(archive).hexdigest(),
    }
    return archive, metadata, None


def safe_relative_path(value: str, label: str) -> PurePosixPath:
    path = PurePosixPath(value.replace("\\", "/"))
    if path.is_absolute() or not path.parts or any(part in ("", ".", "..") for part in path.parts):
        raise RuntimeError(f"unsafe {label} path in manifest: {value!r}")
    return path


def normalized_text_bytes(contents: bytes, path: PurePosixPath) -> bytes:
    if path.suffix.lower() not in TEXT_SUFFIXES or b"\0" in contents:
        return contents
    normalized = contents.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    existing_path = LIBS_DIR.joinpath(*path.parts)
    existing = existing_path.read_bytes() if existing_path.is_file() else b""
    should_end_with_newline = not existing or existing.endswith((b"\n", b"\r"))
    if should_end_with_newline and not normalized.endswith(b"\n"):
        normalized += b"\n"
    elif not should_end_with_newline:
        normalized = normalized.rstrip(b"\n")
    if os.linesep == "\r\n":
        return normalized.replace(b"\n", b"\r\n")
    return normalized


def preserve_equivalent_packaging_metadata(contents: bytes, path: PurePosixPath) -> bytes:
    if path.suffix.lower() != ".lua":
        return contents
    existing_path = LIBS_DIR.joinpath(*path.parts)
    if not existing_path.is_file():
        return contents
    existing = existing_path.read_bytes()

    def canonical(value: bytes) -> bytes:
        value = value.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
        value = re.sub(rb"\$Id(?::[^$\n]*)?\s*\$", b"$Id$", value)
        return value.rstrip(b"\n")

    return existing if canonical(existing) == canonical(contents) else contents


def normalized_archive_files(archive: bytes, configured_root: str | None) -> dict[PurePosixPath, bytes]:
    try:
        package = zipfile.ZipFile(io.BytesIO(archive))
    except zipfile.BadZipFile as error:
        raise RuntimeError("downloaded release is not a valid ZIP archive") from error

    file_infos = [info for info in package.infolist() if not info.is_dir()]
    if not file_infos:
        raise RuntimeError("downloaded release archive is empty")

    if configured_root is None:
        roots = {PurePosixPath(info.filename).parts[0] for info in file_infos}
        if len(roots) != 1:
            raise RuntimeError("GitHub archive does not have a single root directory")
        configured_root = roots.pop()

    root = safe_relative_path(configured_root, "archive root")
    files: dict[PurePosixPath, bytes] = {}
    for info in file_infos:
        archive_path = safe_relative_path(info.filename, "archive")
        if len(archive_path.parts) <= len(root.parts) or archive_path.parts[: len(root.parts)] != root.parts:
            continue
        relative = PurePosixPath(*archive_path.parts[len(root.parts) :])
        if relative.parts[0] == "__MACOSX":
            continue
        if relative in files:
            raise RuntimeError(f"duplicate archive path: {relative}")
        files[relative] = package.read(info)
    if not files:
        raise RuntimeError(f"archive root {configured_root!r} contains no files")
    return files


def write_mappings(
    archive_files: dict[PurePosixPath, bytes],
    mappings: list[dict[str, str]],
    staging: Path,
) -> list[Path]:
    written_files = []
    for mapping in mappings:
        source = safe_relative_path(mapping["from"], "source")
        destination = safe_relative_path(mapping["to"], "destination")
        selected: list[tuple[PurePosixPath, bytes]] = []

        if source in archive_files:
            selected.append((destination, archive_files[source]))
        else:
            for archive_path, contents in archive_files.items():
                if len(archive_path.parts) > len(source.parts) and archive_path.parts[: len(source.parts)] == source.parts:
                    suffix = archive_path.parts[len(source.parts) :]
                    selected.append((PurePosixPath(*destination.parts, *suffix), contents))

        if not selected:
            raise RuntimeError(f"release archive is missing expected path: {source}")

        for relative_path, contents in selected:
            output = staging.joinpath(*relative_path.parts)
            output.parent.mkdir(parents=True, exist_ok=True)
            if output.exists():
                raise RuntimeError(f"multiple mappings write the same path: {relative_path}")
            contents = normalized_text_bytes(contents, relative_path)
            output.write_bytes(preserve_equivalent_packaging_metadata(contents, relative_path))
            written_files.append(output)
    return written_files


def replace_package_tokens(files: list[Path], metadata: dict[str, Any]) -> None:
    version = metadata.get("version")
    if not version and metadata.get("commit"):
        version = f"git-{metadata['commit'][:7]}"
    if not version:
        return

    for path in files:
        if path.suffix.lower() != ".toc":
            continue
        contents = path.read_text(encoding="utf-8")
        replaced = contents.replace("@project-version@", str(version))
        if replaced != contents:
            path.write_text(replaced, encoding="utf-8", newline=os.linesep)


def validate_embeds(staging: Path) -> None:
    embeds = staging / "embeds.xml"
    try:
        root = ElementTree.parse(embeds).getroot()
    except (OSError, ElementTree.ParseError) as error:
        raise RuntimeError(f"cannot parse {embeds.relative_to(staging)}: {error}") from error

    missing = []
    for element in root.iter():
        referenced_file = element.attrib.get("file")
        if not referenced_file:
            continue
        relative = safe_relative_path(referenced_file, "embeds.xml")
        if not staging.joinpath(*relative.parts).is_file():
            missing.append(str(relative))
    if missing:
        raise RuntimeError("updated libraries are missing embeds.xml references: " + ", ".join(missing))


def snapshot(root: Path) -> dict[str, str]:
    if not root.exists():
        return {}
    return {
        path.relative_to(root).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


def changed_paths(before: dict[str, str], after: dict[str, str]) -> list[str]:
    changes = []
    for path in sorted(before.keys() | after.keys()):
        if path not in before:
            changes.append(f"A {path}")
        elif path not in after:
            changes.append(f"D {path}")
        elif before[path] != after[path]:
            changes.append(f"M {path}")
    return changes


def replace_library_tree(staging: Path) -> None:
    parent = LIBS_DIR.parent
    replacement = parent / f".libs-update-{uuid.uuid4().hex}"
    backup = parent / f".libs-backup-{uuid.uuid4().hex}"
    shutil.copytree(staging, replacement)
    try:
        LIBS_DIR.rename(backup)
        replacement.rename(LIBS_DIR)
    except Exception:
        if not LIBS_DIR.exists() and backup.exists():
            backup.rename(LIBS_DIR)
        raise
    finally:
        if replacement.exists():
            shutil.rmtree(replacement)
    shutil.rmtree(backup)


def encoded_lock(metadata: dict[str, Any]) -> bytes:
    return (json.dumps(metadata, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="report available changes without writing them")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    args = parser.parse_args()

    manifest_path = args.manifest.resolve()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("schema") != 1 or not manifest.get("libraries"):
        raise RuntimeError(f"unsupported or empty manifest: {manifest_path}")

    lock: dict[str, Any] = {"schema": 1, "libraries": {}}
    with tempfile.TemporaryDirectory(prefix="apr-libraries-") as temporary_directory:
        staging = Path(temporary_directory) / "libs"
        staging.mkdir()
        shutil.copy2(LIBS_DIR / "embeds.xml", staging / "embeds.xml")

        for library in manifest["libraries"]:
            name = str(library["name"])
            source = library["source"]
            print(f"Resolving {name}...", flush=True)
            if source["type"] == "curseforge":
                archive, metadata, archive_root = latest_curseforge_release(source)
            elif source["type"] == "github":
                archive, metadata, archive_root = latest_github_archive(source)
            else:
                raise RuntimeError(f"unsupported source type for {name}: {source['type']}")
            archive_files = normalized_archive_files(archive, archive_root)
            written_files = write_mappings(archive_files, library["mappings"], staging)
            replace_package_tokens(written_files, metadata)
            lock["libraries"][name] = metadata
            print(f"  {metadata.get('version') or metadata.get('commit')}")

        validate_embeds(staging)
        library_changes = changed_paths(snapshot(LIBS_DIR), snapshot(staging))
        new_lock = encoded_lock(lock)
        old_lock = LOCK_FILE.read_bytes() if LOCK_FILE.exists() else b""
        lock_changed = old_lock != new_lock

        if not library_changes and not lock_changed:
            print("All embedded libraries are already up to date.")
            return 0

        print("Changes detected:")
        for change in library_changes:
            print(f"  {change}")
        if lock_changed:
            print(f"  M {LOCK_FILE.relative_to(ROOT).as_posix()}")

        if args.check:
            print("Run tools/update_libraries.py without --check to apply these changes.")
            return 1

        replace_library_tree(staging)
        temporary_lock = LOCK_FILE.with_suffix(".json.tmp")
        temporary_lock.write_bytes(new_lock)
        temporary_lock.replace(LOCK_FILE)
        print("Embedded libraries updated successfully.")
        return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (KeyError, OSError, RuntimeError, ValueError, json.JSONDecodeError) as error:
        print(f"Library update failed: {error}", file=sys.stderr)
        raise SystemExit(2)
