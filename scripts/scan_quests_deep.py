#!/usr/bin/env python3
import re,json
from pathlib import Path
root=Path('.')
files=[p for p in root.rglob("*.lua") if "libs" not in str(p) and "dist" not in str(p) and ".git" not in str(p)]
report=[]
pattern_quest=re.compile(r"type\s*=\s*[\"']quest[\"']",re.I)
pattern_qpart=re.compile(r"\bQpart\b|\bQPart\b|\bqpart\b",re.I)
for f in sorted(files, key=lambda p: str(p)):
    try:
        txt=f.read_text(encoding='utf-8')
    except Exception:
        txt=''
    lines=txt.splitlines()
    issues=[]
    ob=sum(l.count('{') for l in lines)
    cb=sum(l.count('}') for l in lines)
    if ob!=cb:
        issues.append({'kind':'braces_mismatch','open_braces':ob,'close_braces':cb})
    # larger window to reduce false positives
    for m in pattern_qpart.finditer(txt):
        start=m.start()
        lineno=txt.count('\n',0,start)+1
        lo=max(0,lineno-40)
        hi=min(len(lines),lineno+40)
        window='\n'.join(lines[lo:hi])
        has_id=bool(re.search(r"\b(id|questID|quest_id)\s*=\s*\d+",window))
        # also check for a nearby 'id =' on the same opening table by scanning backward to previous blank line or '},' separator
        if not has_id:
            # scan backwards line-by-line up to 60 lines looking for "id = <num>" before encountering a line that likely ends a step ("},")
            found=False
            for back in range(lineno-1, max(0,lineno-61), -1):
                line=lines[back].strip()
                if re.search(r"\b(id|questID|quest_id)\s*=\s*\d+", line):
                    found=True
                    break
                if line.endswith('},') or line=='},':
                    # likely end of previous step before reaching id
                    break
            has_id=found
        if not has_id:
            issues.append({'kind':'qpart_without_id','line':lineno,'snippet':lines[lineno-1].strip() if 0<=lineno-1<len(lines) else ''})
    if re.search(r"\bcoords\b",txt) and not re.search(r"\bcoord\b",txt):
        issues.append({'kind':'coords_plural_only'})
    if issues:
        report.append({'file':str(f),'issues':issues,'count':len(issues)})
# sort report by count desc
report_sorted=sorted(report, key=lambda x: x['count'], reverse=True)
summary={'files_scanned':len(files),'files_with_issues':len(report_sorted)}
print(json.dumps({'summary':summary,'top_files':report_sorted[:30]}, indent=2))
