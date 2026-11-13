"""Read-only declaration and source checks, independent of authored itineraries.

Source keys are compared only when literal: computed keys and mutations performed
after construction require runtime analysis. Lua compilation is not execution.
"""
import re
from bisect import bisect_right
from pathlib import Path

from lupa.lua51 import LuaRuntime

from tests.routes.route_schema import InvalidRoute, RouteSchema
from tools.validation.instrument_lua import tokens


def _finding(severity, rule, route, path, message, **extra):
    return dict(severity=severity, rule=rule, route=route, path=path,
                message=message, **extra)


def audit_routes(catalog):
    """Validate each declaration independently; return errors and review warnings."""
    result = []
    schema = RouteSchema(catalog)
    graph = {}
    for key, route in catalog.routes.items():
        try:
            schema.validate(key, route)
        except InvalidRoute as exc:
            # Preserve the shared validator's diagnostic so CLI aggregation can
            # deduplicate its own admission check without losing field context.
            result.append(_finding('error', 'route_schema', key, '', str(exc)))
            # Other rules rely on the shared grammar, never on malformed shapes.
            continue
        graph[key] = list(route.get('requiredRoute', {}).values())
        for field in ('requiredRoute', 'nextRoute'):
            for i, target in route.get(field, {}).items():
                target = target.get('route') if isinstance(target, dict) else target
                if target not in catalog.routes:
                    result.append(_finding('error', 'missing-route-reference', key,
                                           f'{field}[{i}]', f'Unknown route key {target!r}',
                                           evidence={'target': target}))
        def check_steps(steps, path, ordinary=False):
            # _index is authored metadata. Separate blocks can restart numbering;
            # only repetitions within the same list warrant a review hint.
            indexes = {}
            has_unconditional_completion = any(
                step.get('RouteCompleted') is True
                and not step.keys() & schema.condition_fields.keys()
                for step in steps.values())
            for i, step in steps.items():
                here = f'{path}[{i}]'
                index = step.get('_index')
                if index is not None:
                    if index in indexes:
                        result.append(_finding('warning', 'duplicate-step-index', key,
                                               here + '._index', 'Repeated authored step index',
                                               evidence={'index': index, 'first': indexes[index]}))
                    else:
                        indexes[index] = here + '._index'
                if ordinary and step.get('RouteCompleted') is True:
                    conditions = sorted(step.keys() & schema.condition_fields.keys())
                    # Conditional shortcuts do not leave a terminal coverage gap
                    # when characters that skip them reach an unconditional end.
                    if conditions and i == len(steps) and not has_unconditional_completion:
                        result.append(_finding('warning', 'conditional-route-completion', key,
                                               here, 'Completion is filtered; review coverage of other characters/states',
                                               evidence={'conditions': conditions}))
                    elif not conditions and i < len(steps):
                        result.append(_finding('warning', 'early-route-completion', key, here,
                                               'Unconditional completion precedes later main steps'))
            if ordinary and (not steps or steps[len(steps)].get('RouteCompleted') is not True):
                result.append(_finding('error', 'missing-route-completion', key, path,
                                       'Ordinary main steps must end with RouteCompleted'))

        main = route.get('steps')
        if main is not None:
            if main and 'steps' in main.get(1, {}):
                for i, block in main.items():
                    check_steps(block['steps'], f'steps[{i}].steps')
            else:
                check_steps(main, 'steps', ordinary=True)
        for field in ('scenarios', 'parallelSteps'):
            for i, block in route.get(field, {}).items():
                check_steps(block['steps'], f'{field}[{i}].steps')
        # Scenario IDs may repeat intentionally: the manager flattens all
        # matching blocks. Do not impose uniqueness or ordinary completion.

    # Cycles can be bypassed by existing completion or character eligibility;
    # therefore report their structural existence as review warnings.
    visited, active, stack = set(), set(), []

    def visit(key):
        if key in active:
            cycle = stack[stack.index(key):] + [key]
            result.append(_finding('warning', 'required-route-cycle', stack[-1],
                                   'requiredRoute', 'Prerequisite cycle requires review',
                                   evidence={'cycle': cycle}))
            return
        if key in visited:
            return
        visited.add(key)
        active.add(key)
        stack.append(key)
        for target in graph.get(key, ()):
            if target in graph:
                visit(target)
        stack.pop()
        active.remove(key)

    for key in graph:
        visit(key)
    return result


def audit_sources(paths):
    """Compile every file separately and inspect constructor-local literal keys.

    Reuses the repository tokenizer (comments and all Lua string forms). Balanced
    delimiters and function/control blocks keep commas inside calls, expressions,
    anonymous functions and child constructors out of their parent's field list.
    Only literal bracket keys are evaluated, in an isolated Lua runtime.
    """
    runtime = LuaRuntime(register_eval=False, register_builtins=False,
                         unpack_returned_tuples=True)
    compile_source = runtime.eval('function(s,n) local c,e=loadstring(s,n); return c~=nil,e end')
    literal = runtime.eval('function(s) local c=assert(loadstring("return "..s)); setfenv(c,{}); return c() end')
    result = []
    for path in sorted(map(Path, paths)):
        try:
            source = path.read_text(encoding='utf-8-sig')
        except (OSError, UnicodeError) as exc:
            result.append(_finding('error', 'source-read', '', '$', str(exc), file=str(path)))
            continue
        valid, error = compile_source(source, '@' + path.as_posix())
        if not valid:
            result.append(_finding('error', 'lua-syntax', '', '$', str(error), file=str(path)))
            continue
        stream = tokens(source)
        words = [m.group() for m in stream]
        newlines = [m.start() for m in re.finditer('\n', source)]

        def line_at(index):
            return bisect_right(newlines, stream[index].start()) + 1

        def static_key(start, end):
            text = source[stream[start].start():stream[end - 1].end()]
            if (end - start == 1 and (text.startswith(('"', "'", '[')) or text in ('true', 'false'))
                    or re.fullmatch(r'-?(?:0[xX][0-9a-fA-F]+|(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)', text)):
                value = literal(text)
                if isinstance(value, (str, int, float, bool)):
                    # Python bool and int compare equal; Lua keys do not.
                    return ('boolean' if isinstance(value, bool) else 'number'
                            if isinstance(value, (int, float)) else 'string', value)
            return None

        # Compute structural matching once. Function bodies may contain local
        # tables; each is still audited independently below.
        pairs, delimiters = {}, []
        for i, word in enumerate(words):
            if word in ('{', '(', '['):
                delimiters.append(i)
            elif word in ('}', ')', ']'):
                opening = delimiters.pop()
                pairs[opening] = i

        contexts, ancestors = {}, []
        for opening, closing in sorted(pairs.items()):
            if words[opening] != '{':
                continue
            while ancestors and ancestors[-1][0] < opening:
                ancestors.pop()
            inherited = ancestors[-1][1] if ancestors else ''
            route, table_path = contexts.get(opening, (inherited, f'table@{line_at(opening)}'))
            for k in range(max(0, opening - 9), opening):
                if words[k:k+4] == ['APR', '.', 'RouteQuestStepList', '[']:
                    end = pairs.get(k + 3)
                    if end is not None and end + 2 == opening and words[end + 1] == '=':
                        value = static_key(k + 4, end)
                        if value and value[0] == 'string':
                            route, table_path = value[1], '$'
            ancestors.append((closing, route))
            seen, implicit, cursor = {}, 0, opening + 1
            while cursor < closing:
                start = cursor
                key, value_start = None, start
                if words[start] == '[' and pairs[start] + 1 < closing and words[pairs[start]+1] == '=':
                    end = pairs[start]
                    key, value_start = static_key(start + 1, end), end + 2
                elif start + 1 < closing and re.fullmatch(r'[A-Za-z_]\w*', words[start]) and words[start+1] == '=':
                    key, value_start = ('string', words[start]), start + 2
                else:
                    implicit += 1
                    key = ('number', implicit)
                field_path = (f'{table_path}.{key[1]}' if key and key[0] == 'string'
                              else f'{table_path}[{key[1] if key else "computed"}]')
                if key in seen and key is not None:
                    result.append(_finding('error', 'duplicate-lua-table-key', route, field_path,
                                           'Repeated constructor key; Lua overwrites an authored value',
                                           file=str(path), line=line_at(start),
                                           evidence={'key': key[1], 'first_line': seen[key]}))
                if key is not None:
                    seen[key] = line_at(start)
                cursor, blocks = value_start, []
                while cursor < closing:
                    word = words[cursor]
                    if word in ('{', '(', '['):
                        if word == '{':
                            contexts[cursor] = (route, field_path)
                        cursor = pairs[cursor] + 1
                        continue
                    if word in ('function', 'if', 'for', 'while', 'repeat'):
                        blocks.append(word)
                    elif word == 'do':
                        if blocks and blocks[-1] in ('for', 'while'):
                            blocks[-1] = 'loop'
                        else:
                            blocks.append('do')
                    elif word in ('end', 'until') and blocks:
                        blocks.pop()
                    elif word in (',', ';') and not blocks:
                        break
                    cursor += 1
                cursor += 1
    return result
