"""Append missing completion steps without rewriting existing route declarations."""
import argparse
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tests.routes.route_loader import load_routes


def ensure_route_completions(directory=ROOT / 'Routes', *, check=False):
    paths = list(Path(directory).rglob('*.lua'))
    catalog = load_routes(paths)
    changed = []
    updates = {}
    for key, route in catalog.routes.items():
        steps = route.get('steps')
        # Scenario blocks have their own completion/return-to-parent lifecycle.
        if steps is None or (steps and 'steps' in steps.get(1, {})):
            continue
        if steps and steps[len(steps)].get('RouteCompleted') is True:
            continue
        path = ROOT / catalog.sources[key]
        if path not in updates:
            raw = path.read_bytes()
            updates[path] = [raw, raw.decode('utf-8-sig').replace('\r\n', '\n')]
        text = updates[path][1]
        declaration = re.search(r'APR\.RouteQuestStepList\[["\']' + re.escape(key) + r'["\']\]\s*=\s*\{', text)
        if not declaration:
            raise ValueError(f'Cannot safely locate declaration: {key}')
        opening = re.search(r'^    steps = \{\n', text[declaration.end():], re.M)
        if not opening:
            raise ValueError(f'Cannot safely locate main steps: {key}')
        start = declaration.end() + opening.end()
        closing = re.search(r'^    \},?\s*$', text[start:], re.M)
        if not closing:
            raise ValueError(f'Cannot safely locate end of steps: {key}')
        end = start + closing.start()
        # Step IDs must stay unique when a parallel block already occupies len+1.
        indices = [s.get('_index', 0) for s in steps.values()]
        indices += [s.get('_index', 0) for g in route.get('parallelSteps', {}).values()
                    for s in g['steps'].values()]
        index = max(indices, default=0) + 1
        insertion = f'        {{\n            RouteCompleted = true,\n            _index = {index},\n        }},\n'
        # The existing last field may omit its optional trailing comma.
        before = text[:end]
        last = re.search(r'\}(\s*)$', before)
        if steps and last:
            before = before[:last.start()] + '},' + last[1]
        updates[path][1] = before + insertion + text[end:]
        changed.append(key)
    if not check:
        for path, (raw, text) in updates.items():
            newline = '\r\n' if b'\r\n' in raw else '\n'
            encoded = text.replace('\n', newline).encode('utf-8')
            if raw.startswith(b'\xef\xbb\xbf'): encoded = b'\xef\xbb\xbf' + encoded
            path.write_bytes(encoded)
    return changed


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', nargs='?', type=Path, default=ROOT / 'Routes')
    parser.add_argument('--check', action='store_true', help='Report missing endings without adding them')
    args = parser.parse_args()
    changed = ensure_route_completions(args.directory, check=args.check)
    print(f'{len(changed)} route endings ' + ('missing' if args.check else 'added'))
    for key in changed: print(key)
    raise SystemExit(1 if args.check and changed else 0)
