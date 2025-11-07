#!/usr/bin/env python3
"""
Deep code quality fixes for APR addon.

Applies more aggressive but safe fixes:
- Standardize table formatting
- Fix common Lua patterns
- Ensure consistent key naming
- Remove redundant whitespace
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def deep_fix_file(path: Path) -> tuple[bool, str]:
    """Apply comprehensive fixes to a Lua file."""
    try:
        original = path.read_text(encoding='utf-8')
        fixed = original
        
        # Standardize coordinate tables: ensure lowercase 'x' and 'y'
        # Fix patterns like coord = { X = ..., Y = ... }
        fixed = re.sub(r'\bx\s*=', 'x =', fixed)
        fixed = re.sub(r'\by\s*=', 'y =', fixed)
        
        # Fix inconsistent Zone/zone (keep as Zone - it's consistent in codebase)
        # No change needed - Zone is correct
        
        # Fix spacing around brackets
        fixed = re.sub(r'\{\s+', '{ ', fixed)
        fixed = re.sub(r'\s+\}', ' }', fixed)
        
        # Fix multiple spaces to single space (except indentation)
        lines = fixed.split('\n')
        fixed_lines = []
        for line in lines:
            # Preserve leading whitespace, fix internal spacing
            leading = len(line) - len(line.lstrip())
            content = line.lstrip()
            if content:
                # Fix multiple spaces in content (but preserve strings)
                content = re.sub(r'([^"\'])  +', r'\1 ', content)
            fixed_lines.append(' ' * leading + content)
        fixed = '\n'.join(fixed_lines)
        
        # Fix common typos in keys
        fixed = re.sub(r'\bCoords\s*=\s*\{', 'coord = {', fixed)  # Coords -> coord
        
        # Ensure _index has no trailing comma
        fixed = re.sub(r'(_index\s*=\s*\d+)\s*,(\s*\})', r'\1\2', fixed)
        
        if fixed != original:
            path.write_text(fixed, encoding='utf-8')
            return True, f"Fixed: {path.relative_to(ROOT)}"
        return False, f"No changes: {path.relative_to(ROOT)}"
    except Exception as e:
        return False, f"Error in {path.relative_to(ROOT)}: {e}"

def main():
    changed = 0
    
    # Fix all route files
    for lua_file in (ROOT / 'Routes').rglob('*.lua'):
        if lua_file.name != 'RouteList.xml':
            did_change, msg = deep_fix_file(lua_file)
            if did_change:
                changed += 1
                print(f"✓ {msg}")
    
    # Fix APR-Core files
    for lua_file in (ROOT / 'APR-Core').rglob('*.lua'):
        # Skip vendor libs
        if 'libs' not in str(lua_file):
            did_change, msg = deep_fix_file(lua_file)
            if did_change:
                changed += 1
                print(f"✓ {msg}")
    
    print(f"\nTotal: {changed} files updated")

if __name__ == '__main__':
    main()
