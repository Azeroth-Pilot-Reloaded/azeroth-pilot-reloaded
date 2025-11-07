#!/usr/bin/env python3
"""
Simple table-aware route validator for APR route files.

What it does:
- Walks the `Routes/` directory and reads each `.lua` file
- Performs a lightweight Lua table extraction using brace-depth (ignoring quoted strings and -- comments)
- For each top-level element (depth==2) it inspects the block for keys: id, questID, Qpart, coord, coords
- Produces JSON and Markdown reports under `reports/`

This is intentionally conservative: it avoids executing Lua and uses text-level parsing to reduce false positives.
"""
import os
import re
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROUTES = ROOT / 'Routes'
REPORTS = ROOT / 'reports'
REPORTS.mkdir(exist_ok=True)


def strip_comments(s: str) -> str:
    # remove block comments --[[ ... ]] and line comments -- ...\n
    s = re.sub(r"--\[\[[\s\S]*?\]\]", '', s)
    s = re.sub(r"--.*?$", '', s, flags=re.M)
    return s


def extract_top_level_blocks(text: str):
    """Return list of top-level element blocks (depth == 2) found in the file.

    Approach: scan characters, track brace depth, ignore braces inside quotes.
    Treat first encountered '{' as depth 1 (top-level table); elements inside are depth==2.
    """
    blocks = []
    in_s = None
    esc = False
    depth = 0
    current = None
    i = 0
    L = len(text)
    while i < L:
        ch = text[i]
        if in_s:
            if esc:
                esc = False
            elif ch == '\\':
                esc = True
            elif ch == in_s:
                in_s = None
        else:
            if ch == '"' or ch == "'":
                in_s = ch
            elif ch == '{':
                depth += 1
                if depth == 2:
                    # start a new block; include the char
                    current = []
                    current.append(ch)
                elif depth > 2 and current is not None:
                    current.append(ch)
            elif ch == '}':
                if current is not None:
                    current.append(ch)
                depth -= 1
                if depth == 1 and current is not None:
                    blocks.append(''.join(current))
                    current = None
            else:
                if current is not None:
                    current.append(ch)
        i += 1
    return blocks


def analyze_block(block: str):
    issues = []
    idm = re.search(r'\b(id|questID)\s*=\s*(\d+)', block)
    has_id = bool(idm)
    has_qpart = bool(re.search(r'\bQpart\s*=', block))
    has_coord = bool(re.search(r'\bcoord\s*=', block))
    has_coords = bool(re.search(r'\bcoords\s*=', block))

    if not has_id:
        issues.append('missing_id')
    if has_qpart and not has_id:
        issues.append('qpart_without_id')
    if has_coords:
        issues.append('coords_used')
    if has_coord:
        issues.append('coord_used')

    return issues


def validate_file(path: Path):
    txt = path.read_text(encoding='utf-8')
    stripped = strip_comments(txt)
    blocks = extract_top_level_blocks(stripped)
    file_issues = []
    for idx, b in enumerate(blocks):
        issues = analyze_block(b)
        if issues:
            file_issues.append({'index': idx, 'issues': issues, 'snippet': b[:200].strip().replace('\n', ' ')})
    malformed = False
    # quick brace balance check on stripped content
    if stripped.count('{') != stripped.count('}'):
        malformed = True
    return {
        'file': str(path.relative_to(ROOT)),
        'blocks_scanned': len(blocks),
        'issues': file_issues,
        'malformed': malformed,
    }


def main():
    results = []
    files_scanned = 0
    for p in ROUTES.rglob('*.lua'):
        files_scanned += 1
        try:
            r = validate_file(p)
            if r['issues'] or r['malformed']:
                results.append(r)
        except Exception as e:
            results.append({'file': str(p.relative_to(ROOT)), 'error': str(e)})

    out = {
        'summary': {
            'files_scanned': files_scanned,
            'files_with_issues': len(results),
        },
        'files': results,
    }

    json_path = REPORTS / 'route_validation.json'
    md_path = REPORTS / 'route-validation.md'
    json_path.write_text(json.dumps(out, indent=2), encoding='utf-8')

    # write a simple markdown
    with md_path.open('w', encoding='utf-8') as f:
        f.write('# Route validation report\n\n')
        f.write(f"Files scanned: {files_scanned}\n")
        f.write(f"Files with issues: {len(results)}\n\n")
        for item in results[:300]:
            f.write(f"## {item.get('file')}  (blocks={item.get('blocks_scanned')})\n\n")
            if item.get('malformed'):
                f.write('- malformed (unbalanced braces)\n')
            if 'error' in item:
                f.write(f"- error: {item['error']}\n")
                continue
            for bi in item.get('issues', [])[:200]:
                f.write(f"- {', '.join(bi['issues'])}: `{bi['snippet']}`\n")
            f.write('\n')

    print('Wrote', json_path, md_path)


if __name__ == '__main__':
    main()
