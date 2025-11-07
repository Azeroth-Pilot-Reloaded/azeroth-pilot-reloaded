#!/usr/bin/env python3
"""
Comprehensive code quality checker for APR addon.
Checks for common issues, inconsistencies, and potential bugs.
"""
import re
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[1]

def check_file(path: Path):
    """Check a single Lua file for common issues."""
    issues = []
    try:
        content = path.read_text(encoding='utf-8')
        lines = content.split('\n')

        for i, line in enumerate(lines, 1):
            # Check for common issues
            if re.search(r'\bCoord\b', line) and 'coord' not in line.lower():
                issues.append((i, 'uppercase_coord', line.strip()[:80]))

            if re.search(r',\s*,', line):
                issues.append((i, 'double_comma', line.strip()[:80]))

            if re.search(r',\s*}', line):
                issues.append((i, 'trailing_comma', line.strip()[:80]))

            # Check for inconsistent spacing
            if re.search(r'\w+=[^=\s]', line) and '--' not in line:
                issues.append((i, 'missing_space_after_equals', line.strip()[:80]))

            # Check for potential nil issues
            if re.search(r'\[\s*\]\s*=', line):
                issues.append((i, 'empty_bracket_key', line.strip()[:80]))

        return issues
    except Exception as e:
        return [(-1, 'error', str(e))]

def main():
    print("Scanning all Lua files...")
    all_issues = defaultdict(list)

    # Check Routes
    for lua_file in (ROOT / 'Routes').rglob('*.lua'):
        issues = check_file(lua_file)
        if issues:
            all_issues[str(lua_file.relative_to(ROOT))].extend(issues)

    # Check APR-Core (excluding libs)
    for lua_file in (ROOT / 'APR-Core').rglob('*.lua'):
        if 'libs' not in str(lua_file):
            issues = check_file(lua_file)
            if issues:
                all_issues[str(lua_file.relative_to(ROOT))].extend(issues)

    # Summary
    total_files_with_issues = len(all_issues)
    total_issues = sum(len(v) for v in all_issues.values())

    print(f"\nTotal files with issues: {total_files_with_issues}")
    print(f"Total issues found: {total_issues}")

    if total_issues > 0:
        issue_types = defaultdict(int)
        for issues in all_issues.values():
            for _, itype, _ in issues:
                issue_types[itype] += 1

        print("\nIssue breakdown:")
        for itype, count in sorted(issue_types.items(), key=lambda x: -x[1]):
            print(f"  {itype}: {count}")

        # Show top files
        print("\nTop 10 files with most issues:")
        sorted_files = sorted(all_issues.items(), key=lambda x: len(x[1]), reverse=True)
        for fpath, issues in sorted_files[:10]:
            print(f"  {fpath}: {len(issues)} issues")

if __name__ == '__main__':
    main()
