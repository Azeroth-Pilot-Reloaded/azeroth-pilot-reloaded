#!/usr/bin/env python3
import json
from pathlib import Path
root=Path('.')
json_path=Path('reports/quest_report.json')
md_path=Path('reports/quest-report.md')
if not json_path.exists():
    print('Missing', json_path)
    raise SystemExit(1)
j=json.load(open(json_path))
lines=[]
lines.append('# Quest scan report')
lines.append('')
lines.append(f"Files scanned: {j['summary']['files_scanned']}")
lines.append(f"Files with issues: {j['summary']['files_with_issues']}")
lines.append('')
lines.append('Top files (first 30):')
lines.append('')
for f in j.get('top_files',[])[:30]:
    lines.append(f"## {f['file']}  ({f['count']} issues)")
    lines.append('')
    for issue in f['issues'][:20]:
        kind=issue.get('kind')
        line=issue.get('line','?')
        snippet=issue.get('snippet','').strip()
        lines.append(f"- {kind} @ line {line}: `{snippet}`")
    lines.append('')
md_path.parent.mkdir(parents=True, exist_ok=True)
md_path.write_text('\n'.join(lines))
print('Wrote', md_path)
