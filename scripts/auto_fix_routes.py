#!/usr/bin/env python3
"""
Auto-fix safe, obvious issues in APR route files.

Conservative fixes only:
- Normalize capitalization inconsistencies in common keys (Coord/coord, etc.)
- Fix trailing commas before closing braces
- Remove duplicate commas
- Ensure consistent spacing around = and ,

Does NOT:
- Add or modify questID/id values
- Change Qpart structures
- Alter coordinate values
- Modify any game logic
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROUTES = ROOT / 'Routes'

def normalize_keys(content: str) -> str:
    """Normalize common key capitalization inconsistencies."""
    # Common patterns: Coord/coord, Qpart/qpart, etc.
    # Only normalize if the pattern is clear and unambiguous

    # Fix Coord -> coord (but preserve in context like _Coord)
    content = re.sub(r'\bCoord\s*=', 'coord =', content)

    # Fix common spacing issues around =
    content = re.sub(r'(\w+)\s*=\s*{', r'\1 = {', content)

    return content

def fix_syntax(content: str) -> str:
    """Fix obvious syntax issues."""
    # Remove duplicate commas
    content = re.sub(r',\s*,', ',', content)

    # Fix trailing comma before }
    content = re.sub(r',(\s*)\}', r'\1}', content)

    return content

def auto_fix_file(path: Path) -> tuple[bool, str]:
    """Apply safe fixes to a file. Returns (changed, summary)."""
    try:
        original = path.read_text(encoding='utf-8')
        fixed = original

        # Apply fixes
        fixed = normalize_keys(fixed)
        fixed = fix_syntax(fixed)

        if fixed != original:
            path.write_text(fixed, encoding='utf-8')
            return True, f"Fixed: {path.relative_to(ROOT)}"
        return False, f"No changes: {path.relative_to(ROOT)}"
    except Exception as e:
        return False, f"Error in {path.relative_to(ROOT)}: {e}"

def main():
    results = []
    changed_count = 0

    for lua_file in ROUTES.rglob('*.lua'):
        changed, msg = auto_fix_file(lua_file)
        if changed:
            changed_count += 1
            print(f"✓ {msg}")
        results.append(msg)

    print(f"\nSummary: {changed_count} files changed")

if __name__ == '__main__':
    main()
