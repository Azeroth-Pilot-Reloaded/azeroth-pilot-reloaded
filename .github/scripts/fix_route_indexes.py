#!/usr/bin/env python3
"""Re-number `_index` fields in APR route files.

By default, this script can process:
- staged route files (`--staged`)
- explicitly provided file paths
- all route files (`--all`)

It numbers direct step `_index` fields starting at 1 independently for `steps`
and for all `parallelSteps` groups in each `APR.RouteQuestStepList[...]` block,
preserving all other source text.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path

def _run_git(args: list[str]) -> str:
    completed = subprocess.run(
        ["git", *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        check=True,
    )
    return completed.stdout


def get_repo_root() -> Path:
    try:
        root = _run_git(["rev-parse", "--show-toplevel"]).strip()
        if root:
            return Path(root)
    except subprocess.CalledProcessError:
        pass
    return Path.cwd()


def staged_route_files(repo_root: Path) -> list[Path]:
    output = _run_git(["diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z"])
    files: list[Path] = []
    for raw in output.split("\0"):
        rel = raw.replace("\\", "/")
        if not rel.startswith("Routes/") or not rel.endswith(".lua"):
            continue
        files.append(repo_root / rel)
    return files


def all_route_files(repo_root: Path) -> list[Path]:
    return sorted((repo_root / "Routes").rglob("*.lua"))


def normalize_text(original: str) -> str:
    # Import lazily: the field formatter also imports this module's Git helpers.
    from reorder_route_fields import LuaSource

    source = LuaSource(original)
    replacements = []
    for sequence in source.step_sequences():
        current_index = 1
        for step in sequence:
            for key, _, value, last in source.fields(step):
                token = source.tokens[value]
                if key != "_index" or not token[0].isdigit():
                    continue
                # Only replace a literal integer, never part of an expression.
                end = last - 1 if source.tokens[last][0] in (",", ";") else last
                if value != end:
                    continue
                replacement = str(current_index)
                if token[0] != replacement:
                    replacements.append((token.start(), token.end(), replacement))
                current_index += 1
    for start, end, replacement in sorted(replacements, reverse=True):
        original = original[:start] + replacement + original[end:]
    return original


def normalize_file(path: Path) -> bool:
    if not path.is_file():
        return False
    original = path.read_bytes()
    normalized = normalize_text(original.decode("utf-8")).encode("utf-8")
    if original == normalized:
        return False
    path.write_bytes(normalized)
    return True


def process_files(
    files: list[Path], repo_root: Path, transform: Callable[[str], str],
    *, staged: bool = False, no_stage: bool = False,
) -> list[Path]:
    """Transform staged blobs safely, preserving partially staged working files.

    A matching working copy is updated too. An independently edited working copy
    stays untouched; only its staged version is formatted. --no-stage operates on
    working files without updating the index, as with explicit paths or --all.
    """
    updates = []
    for path in files:
        mode = None
        if staged and not no_stage:
            relative = path.relative_to(repo_root).as_posix()
            entry = subprocess.check_output(
                ["git", "ls-files", "--stage", "--", relative], cwd=repo_root,
            ).decode("utf-8")
            mode = entry.split()[0]
            original = subprocess.check_output(["git", "show", ":" + relative], cwd=repo_root)
        else:
            if not path.is_file():
                continue
            original = path.read_bytes()
        try:
            normalized = transform(original.decode("utf-8")).encode("utf-8")
        except (ValueError, UnicodeError) as error:
            raise ValueError(f"{path}: {error}") from error
        if normalized != original:
            updates.append((path, original, normalized, mode))

    for path, original, normalized, mode in updates:
        if mode is not None:
            relative = path.relative_to(repo_root).as_posix()
            blob = subprocess.check_output(
                ["git", "hash-object", "-w", "--stdin"], input=normalized, cwd=repo_root,
            ).decode("ascii").strip()
            subprocess.run(["git", "update-index", "--cacheinfo", mode, blob, relative],
                           cwd=repo_root, check=True)
            if path.is_file() and path.read_bytes() == original:
                path.write_bytes(normalized)
            elif path.is_file():
                working = path.read_bytes()
                # Git's autocrlf can store LF while the unchanged working file
                # uses CRLF. Keep that file synchronized with its own newlines.
                if b"\r\n" in working and b"\r\n" not in original and working.replace(b"\r\n", b"\n") == original:
                    path.write_bytes(normalized.replace(b"\n", b"\r\n"))
        else:
            path.write_bytes(normalized)
    changed = [path for path, *_ in updates]
    if changed and not no_stage and not staged:
        stage_files(changed, repo_root)
    return changed


def stage_files(files: list[Path], repo_root: Path) -> None:
    if not files:
        return
    rel_files = [str(path.relative_to(repo_root)).replace("\\", "/") for path in files]
    subprocess.run(["git", "add", "--", *rel_files], check=True, cwd=repo_root)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fix APR route `_index` fields.")
    parser.add_argument(
        "files",
        nargs="*",
        help="Optional route file paths to normalize.",
    )
    parser.add_argument(
        "--staged",
        action="store_true",
        help="Normalize only staged route Lua files.",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Normalize all route Lua files under Routes/.",
    )
    parser.add_argument(
        "--no-stage",
        action="store_true",
        help="Do not `git add` files after modification.",
    )
    parser.add_argument("--quiet", action="store_true", help="Only report changed files or errors.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = get_repo_root()

    if args.staged:
        targets = staged_route_files(repo_root)
    elif args.all:
        targets = all_route_files(repo_root)
    elif args.files:
        targets = [
            (Path.cwd() / p).resolve() if not Path(p).is_absolute() else Path(p)
            for p in args.files
        ]
    else:
        print("No targets selected. Use --staged, --all, or pass file paths.", file=sys.stderr)
        return 2

    if not targets:
        if not args.quiet:
            print("No route files matched the selection.")
        return 0

    try:
        changed_files = process_files(targets, repo_root, normalize_text,
                                      staged=args.staged, no_stage=args.no_stage)
    except ValueError as error:
        print(f"Cannot normalize route indexes: {error}", file=sys.stderr)
        return 1

    if changed_files:
        print("Updated _index sequence in:")
        for path in changed_files:
            try:
                rel = path.relative_to(repo_root)
            except ValueError:
                rel = path
            print(f"- {str(rel).replace('\\', '/')}")
    elif not args.quiet:
        print("No _index updates were required.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
