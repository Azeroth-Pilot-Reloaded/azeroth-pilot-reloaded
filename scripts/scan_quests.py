#!/usr/bin/env python3
import re,sys,json
from pathlib import Path
root=Path('.')
files=[p for p in root.rglob("*.lua") if "libs" not in str(p) and "dist" not in str(p) and ".git" not in str(p)]
report=[]
pattern_quest=re.compile(r"type\s*=\s*[\"']quest[\"']",re.I)
pattern_qpart=re.compile(r"\bqpart\b",re.I)
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
    for m in pattern_quest.finditer(txt):
        start=m.start()
        lineno=txt.count('\n',0,start)+1
        lo=max(0,lineno-12)
        hi=min(len(lines),lineno+12)
        window='\n'.join(lines[lo:hi])
        has_id=bool(re.search(r"\b(id|questID|quest_id)\s*=\s*\d+",window))
        has_coord=bool(re.search(r"\bcoord\b\s*=|\bcoords\b\s*=|\bcoord\s*=\s*\{",window))
        issues.append({'kind':'quest_step','line':lineno,'has_id':has_id,'has_coord':has_coord,'snippet':lines[lineno-1].strip() if 0<=lineno-1<len(lines) else ''})
    for m in pattern_qpart.finditer(txt):
        start=m.start()
        lineno=txt.count('\n',0,start)+1
        lo=max(0,lineno-8)
        hi=min(len(lines),lineno+8)
        window='\n'.join(lines[lo:hi])
        has_id=bool(re.search(r"\b(id|questID|quest_id)\s*=\s*\d+",window))
        if not has_id:
            issues.append({'kind':'qpart_without_id','line':lineno,'snippet':lines[lineno-1].strip() if 0<=lineno-1<len(lines) else ''})
    if re.search(r"\bcoords\b",txt) and not re.search(r"\bcoord\b",txt):
        issues.append({'kind':'coords_plural_only'})
    if issues:
        report.append({'file':str(f),'issues':issues})
out={'summary':{'files_scanned':len(files),'files_with_issues':len(report)},'report':report}
print(json.dumps(out,indent=2))
