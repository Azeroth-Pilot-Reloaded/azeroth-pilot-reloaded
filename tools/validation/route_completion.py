"""Append missing completion steps without rewriting existing route declarations."""
import argparse
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tests.routes.route_loader import load_routes
from tests.routes.route_schema import RouteSchema


def ensure_unconditional_route_endings(directory=ROOT / 'Routes', *, check=False, route_keys=None):
    """Explicit authoring repair; never called by tests on maintained sources.

    Only the last marker of an ordinary, non-temporary route is changed. Earlier
    shortcuts, scenario blocks, route eligibility and all action steps retain
    their predicates. The optional key selection comes from a reviewed audit.
    """
    sys.path.insert(0, str(ROOT / '.github/scripts'))
    from reorder_route_fields import LuaSource
    from lupa.lua51 import LuaRuntime

    paths = sorted(Path(directory).rglob('*.lua'))
    catalog = load_routes(paths)
    conditions = set(RouteSchema(catalog).condition_fields)
    selected = set()
    for key, route in catalog.routes.items():
        steps = route.get('steps')
        if (route.get('temporary') or route.get('scenarios') or not steps
                or 'steps' in steps.get(1, {}) or (route_keys is not None and key not in route_keys)):
            continue
        last = steps[len(steps)]
        if last.get('RouteCompleted') is True and last.keys() & conditions:
            selected.add(key)
    runtime = LuaRuntime(register_eval=False, register_builtins=False)
    changed, updates = [], []
    for path in paths:
        raw = path.read_bytes()
        text = raw.decode('utf-8-sig')
        parsed = LuaSource(text)
        tokens, edits = parsed.tokens, []
        for index in range(len(tokens) - 7):
            if [t[0] for t in tokens[index:index + 4]] != ['APR', '.', 'RouteQuestStepList', '[']:
                continue
            closing = parsed.pairs[index + 3]
            # A literal key is safe to evaluate in an otherwise empty Lua VM.
            if closing != index + 5 or tokens[index + 4].lastgroup != 'string':
                continue
            if [t[0] for t in tokens[closing + 1:closing + 3]] != ['=', '{']:
                continue
            key = runtime.eval(tokens[index + 4][0])
            if key not in selected:
                continue
            route_fields = parsed.fields(closing + 2)
            main = next(value for name, _, value, _ in route_fields if name == 'steps')
            step_fields = parsed.fields(main)
            marker = step_fields[-1][2]
            removed = False
            for name, first, _, last in parsed.fields(marker):
                if name not in conditions:
                    continue
                start, end = tokens[first].start(), tokens[last].end()
                line = text.rfind('\n', 0, start) + 1
                if not text[line:start].strip():
                    start = line
                    newline = text.find('\n', end)
                    if newline != -1 and not text[end:newline].strip():
                        end = newline + 1
                else:
                    while start > 0 and text[start - 1] in ' \t':
                        start -= 1
                edits.append((start, end))
                removed = True
            if removed:
                changed.append(key)
        if edits:
            for start, end in sorted(edits, reverse=True):
                text = text[:start] + text[end:]
            encoded = text.encode('utf-8')
            if raw.startswith(b'\xef\xbb\xbf'):
                encoded = b'\xef\xbb\xbf' + encoded
            updates.append((path, encoded))
    if set(changed) != selected:
        raise ValueError('Could not locate every selected literal route ending; no files written')
    if not check:
        for path, encoded in updates:
            path.write_bytes(encoded)
    return changed


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
    parser.add_argument('--unconditional', action='store_true', help='Also remove filters from final ordinary completion markers')
    args = parser.parse_args()
    changed = ensure_route_completions(args.directory, check=args.check)
    if args.unconditional:
        changed = list(dict.fromkeys(changed + ensure_unconditional_route_endings(args.directory, check=args.check)))
    action = (('requiring repair' if args.check else 'repaired') if args.unconditional
              else ('missing' if args.check else 'added'))
    print(f'{len(changed)} route endings {action}')
    for key in changed: print(key)
    raise SystemExit(1 if args.check and changed else 0)
