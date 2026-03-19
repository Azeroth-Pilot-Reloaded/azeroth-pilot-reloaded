#!/usr/bin/env python3
"""Re-number `_index` fields in APR route files.

By default, this script can process:
- staged route files (`--staged`)
- explicitly provided file paths
- all route files (`--all`)

It replaces every `_index = <number>,` occurrence in each target file with a
strictly increasing sequence starting at 1 for each
`APR.RouteQuestStepList[...]` block, preserving indentation and suffix.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

INDEX_RE = re.compile(r"^(\s*_index\s*=\s*)(\d+)(\s*,)(\s*(?:--.*)?)$")
ROUTE_START_RE = re.compile(r"^\s*APR\.RouteQuestStepList\[[^\]]+\]\s*=\s*\{")


def _run_git(args: list[str]) -> str:
    completed = subprocess.run(
        ["git", *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
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
    output = _run_git(["diff", "--cached", "--name-only", "--diff-filter=ACMR"])
    files: list[Path] = []
    for raw in output.splitlines():
        rel = raw.strip().replace("\\", "/")
        if not rel.startswith("Routes/") or not rel.endswith(".lua"):
            continue
        files.append(repo_root / rel)
    return files


def all_route_files(repo_root: Path) -> list[Path]:
    return sorted((repo_root / "Routes").rglob("*.lua"))


def normalize_file(path: Path) -> bool:
    if not path.exists() or not path.is_file():
        return False

    with path.open("r", encoding="utf-8", newline="") as handle:
        original = handle.read()
    lines = original.splitlines(keepends=True)

    current_index = 1
    changed = False
    normalized_lines: list[str] = []

    for line in lines:
        line_ending = ""
        line_content = line
        if line.endswith("\r\n"):
            line_ending = "\r\n"
            line_content = line[:-2]
        elif line.endswith("\n") or line.endswith("\r"):
            line_ending = line[-1]
            line_content = line[:-1]

        if ROUTE_START_RE.match(line_content):
            current_index = 1

        match = INDEX_RE.match(line_content)
        if not match:
            normalized_lines.append(line)
            continue

        new_line = f"{match.group(1)}{current_index}{match.group(3)}{match.group(4)}{line_ending}"
        if new_line != line:
            changed = True
        normalized_lines.append(new_line)
        current_index += 1

    if changed:
        with path.open("w", encoding="utf-8", newline="") as handle:
            handle.write("".join(normalized_lines))

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
        print("No route files matched the selection.")
        return 0

    changed_files: list[Path] = []
    for target in targets:
        try:
            if normalize_file(target):
                changed_files.append(target)
        except UnicodeDecodeError:
            print(f"Skipped non UTF-8 file: {target}", file=sys.stderr)

    if changed_files and not args.no_stage:
        stage_files(changed_files, repo_root)

    if changed_files:
        print("Updated _index sequence in:")
        for path in changed_files:
            try:
                rel = path.relative_to(repo_root)
            except ValueError:
                rel = path
            print(f"- {str(rel).replace('\\', '/')}")
    else:
        print("No _index updates were required.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
