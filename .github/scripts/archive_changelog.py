#!/usr/bin/env python3
"""Archive CurseForge changelogs for every APR locale (preview by default)."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import sys

import requests
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
PROJECT_ID = 618667
LOCALES = ("enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW")
KEYS = ("New Changelog", "Prev Changelog")
MAX_VERSIONS = 4
VERSION = re.compile(
    r"(?m)^[ \t]*[vV]?(\d+(?:\.\d+){1,3}(?:[-+][0-9A-Za-z.-]+)?)"
    r"[ \t]*(?:\([^\r\n]*\))?[ \t]*$"
)
LONG_STRING = re.compile(r"\[(=*)\[")


def normalize(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def lua_tokens(text: str):
    """Read Lua data without executing it; preserve UTF-8 and multiline strings."""
    index = 0
    while index < len(text):
        char = text[index]
        if char.isspace() or char == "\ufeff":
            index += 1
            continue
        if text.startswith("--", index):
            start = LONG_STRING.match(text, index + 2)
            if start:
                close = "]" + start[1] + "]"
                end = text.find(close, start.end())
                if end < 0:
                    raise ValueError("Unterminated Lua comment")
                index = end + len(close)
            else:
                end = text.find("\n", index)
                index = len(text) if end < 0 else end + 1
            continue
        start = LONG_STRING.match(text, index)
        if start:
            close = "]" + start[1] + "]"
            end = text.find(close, start.end())
            if end < 0:
                raise ValueError("Unterminated Lua long string")
            value = normalize(text[start.end():end])
            if value.startswith("\n"):
                value = value[1:]
            yield "string", value
            index = end + len(close)
            continue
        if char in ('"', "'"):
            quote = char
            index += 1
            value = bytearray()
            while index < len(text) and text[index] != quote:
                char = text[index]
                index += 1
                if char != "\\":
                    value.extend(char.encode("utf-8"))
                    continue
                if index == len(text):
                    raise ValueError("Unterminated Lua escape")
                char = text[index]
                index += 1
                escapes = {"a": "\a", "b": "\b", "f": "\f", "n": "\n", "r": "\r", "t": "\t", "v": "\v", "\\": "\\", '"': '"', "'": "'"}
                if char in escapes:
                    value.extend(escapes[char].encode("utf-8"))
                elif char.isascii() and char.isdigit():
                    digits = char
                    while index < len(text) and len(digits) < 3 and text[index] in "0123456789":
                        digits += text[index]
                        index += 1
                    value.append(int(digits))
                elif char in "\r\n":
                    if char == "\r" and index < len(text) and text[index] == "\n":
                        index += 1
                    value.extend(b"\n")
                else:
                    raise ValueError(f"Unsupported Lua escape: \\{char}")
            if index == len(text):
                raise ValueError("Unterminated Lua quoted string")
            index += 1
            yield "string", normalize(value.decode("utf-8"))
            continue
        word = re.match(r"[A-Za-z_][A-Za-z_0-9]*", text[index:])
        if word:
            yield "word", word[0]
            index += len(word[0])
        else:
            yield "symbol", char
            index += 1


def parse_changelogs(text: str) -> dict[str, str]:
    tokens = list(lua_tokens(text))
    values = {}
    for index in range(len(tokens) - 5):
        part = tokens[index:index + 6]
        if (part[0] == ("word", "L") and part[1] == ("symbol", "[")
                and part[2][0] == "string" and part[2][1] in KEYS
                and part[3] == ("symbol", "]") and part[4] == ("symbol", "=")):
            key = part[2][1]
            if key in values or part[5][0] != "string":
                raise ValueError(f"Duplicate or non-string {key!r} in export")
            if index + 6 < len(tokens) and tokens[index + 6] == ("symbol", "."):
                raise ValueError(f"Expected a literal string for {key!r}")
            values[key] = part[5][1]
    return values


def split_versions(text: str) -> list[tuple[str, str]]:
    text = normalize(text).strip()
    if not text:
        return []
    headers = list(VERSION.finditer(text))
    if not headers or headers[0].start() != 0:
        raise ValueError("Changelog must start with a version header, e.g. v6.8.0 (2026-10-08)")
    return [
        (header[1], text[header.start():headers[index + 1].start() if index + 1 < len(headers) else len(text)].strip())
        for index, header in enumerate(headers)
    ]


def archive_values(values: dict[str, str]) -> dict[str, str] | None:
    new = values.get(KEYS[0], "")
    if not new.strip():
        return None
    releases = split_versions(new) + split_versions(values.get(KEYS[1], ""))
    seen = set()
    kept = []
    for version, block in releases:
        if version not in seen:
            seen.add(version)
            kept.append(block)
        if len(kept) == MAX_VERSIONS:
            break
    return {KEYS[0]: "", KEYS[1]: "\n\n".join(kept)}


def lua_quote(value: str) -> str:
    escapes = {"\\": "\\\\", '"': '\\"', "\n": "\\n", "\r": "\\r", "\t": "\\t"}
    return '"' + "".join(escapes.get(char, f"\\{ord(char):03d}" if ord(char) < 32 else char) for char in value) + '"'


class CurseForge:
    def __init__(self, project_id: int, token: str):
        self.url = f"https://wow.curseforge.com/api/projects/{project_id}/localization"
        self.session = requests.Session()
        self.session.headers.update({"X-Api-Token": token})

    def export(self, locale: str) -> dict[str, str]:
        response = self.session.get(self.url + "/export", params={
            "lang": locale, "export-type": "TableAdditions", "table-name": "L",
            "unlocalized": "Ignore", "escape-non-ascii-characters": "false",
            "true-if-value-equals-key": "false",
        }, timeout=30)
        response.raise_for_status()
        response.encoding = "utf-8"
        if "<html" in response.text.lower() or "<!doctype html" in response.text.lower():
            raise ValueError(f"{locale}: received an HTML page instead of a localization export")
        return parse_changelogs(response.text)

    def upload(self, locale: str, values: dict[str, str]) -> None:
        response = self.session.post(self.url + "/import", json={
            "metadata": {
                "language": locale, "formatType": "TableAdditions",
                "missing-phrase-handling": "DoNothing",
            },
            "localizations": "\n".join(f"L[{lua_quote(key)}] = {lua_quote(value)}" for key, value in values.items()),
        }, timeout=30)
        response.raise_for_status()


def same_values(actual: dict[str, str], expected: dict[str, str]) -> bool:
    # CurseForge may omit an explicitly empty translation from Ignore exports.
    return all(actual.get(key, "") == expected.get(key, "") for key in KEYS)


def prepare(api: CurseForge, locales: list[str]) -> dict:
    plan = {}
    for locale in locales:
        before = api.export(locale)
        try:
            after = archive_values(before)
        except ValueError as error:
            raise ValueError(f"{locale}: {error}") from error
        plan[locale] = {"before": before, "after": after}
        if after is None:
            print(f"{locale}: skipped (New Changelog empty or untranslated)")
        else:
            versions = ", ".join(version for version, _ in split_versions(after[KEYS[1]]))
            print(f"{locale}: New Changelog -> empty; Prev Changelog -> {versions}")
    return plan


def apply_plan(api: CurseForge, plan: dict) -> None:
    # Update the primary locale last, after archiving all existing translations.
    for locale in sorted(plan, key=lambda value: value == "enUS"):
        before, after = plan[locale]["before"], plan[locale]["after"]
        if after is None:
            continue
        if not same_values(api.export(locale), before):
            raise RuntimeError(f"{locale}: translations changed after export; stopped before upload")
        # Store and verify the archive before clearing the current changelog.
        api.upload(locale, {KEYS[1]: after[KEYS[1]]})
        archived = {**before, KEYS[1]: after[KEYS[1]]}
        if not same_values(api.export(locale), archived):
            raise RuntimeError(f"{locale}: archive verification failed; New Changelog has not been cleared")
        api.upload(locale, {KEYS[0]: ""})
        if not same_values(api.export(locale), after):
            raise RuntimeError(f"{locale}: final verification failed; check the saved backup and CurseForge")
        print(f"{locale}: uploaded and verified")


def main(argv: list[str] | None = None) -> int:
    load_dotenv(ROOT / ".env")
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true", help="Upload changes to CurseForge")
    mode.add_argument("--dry-run", action="store_true", help="Preview only (default)")
    parser.add_argument("--project-id", type=int, default=PROJECT_ID)
    parser.add_argument("--locales", default=",".join(LOCALES), help="Comma-separated locales (default: all eleven APR locales)")
    parser.add_argument("--backup-dir", type=Path, default=ROOT / ".cache/changelog")
    args = parser.parse_args(argv)
    token = os.getenv("CF_API_KEY")
    if not token:
        parser.error("Set CF_API_KEY in the environment or the repository's .env file")
    locales = list(dict.fromkeys(value.strip() for value in args.locales.split(",") if value.strip()))
    if args.project_id <= 0 or not locales or any(locale not in LOCALES for locale in locales):
        parser.error("Use a positive project ID and supported APR locales: " + ",".join(LOCALES))
    backup = None
    try:
        api = CurseForge(args.project_id, token)
        plan = prepare(api, locales)
        args.backup_dir.mkdir(parents=True, exist_ok=True)
        backup = args.backup_dir / (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ") + ".json")
        with backup.open("x", encoding="utf-8") as handle:
            json.dump({"project_id": args.project_id, "mode": "apply" if args.apply else "dry-run", "locales": plan}, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        print(f"Backup and preview: {backup}")
        if args.apply:
            apply_plan(api, plan)
        else:
            print("Preview only. Run again with --apply to upload.")
        return 0
    except (requests.RequestException, ValueError, RuntimeError, OSError) as error:
        print(f"Error: {error}", file=sys.stderr)
        if args.apply and backup:
            print(f"Some locales may already be updated. Original values are saved in {backup}. Fix the issue and rerun; archived versions are deduplicated.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
