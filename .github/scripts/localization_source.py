"""Static APR localization references. Lua is tokenized, never loaded or executed.

Only actual localization lookups and fields consumed by ResolveStepText are
references. In particular, a comment, a locale definition, or an unrelated
string containing a key does not keep that key alive.
"""

from dataclasses import dataclass
from fnmatch import fnmatchcase
from pathlib import Path
import re


@dataclass(frozen=True, slots=True)
class Token:
    kind: str
    value: str
    line: int
    offset: int
    end: int


_LONG_OPEN = re.compile(r"\[(=*)\[")
_WORD = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")
_SPACE = re.compile(r"\s+")
_ESCAPES = {"a": "\a", "b": "\b", "f": "\f", "n": "\n", "r": "\r",
            "t": "\t", "v": "\v", "\\": "\\", '"': '"', "'": "'"}


def tokenize_lua(source):
    """Return decoded tokens with source locations; omit whitespace/comments.

    Supports Lua short/long strings, long comments, decimal/hex/Unicode escapes,
    and escaped newlines. Invalid lexical input raises ValueError rather than
    letting a truncated export silently pass catalog validation.
    """
    tokens = []
    index, line, length = 0, 1, len(source)
    while index < length:
        start, start_line = index, line
        char = source[index]
        if char.isspace() or (index == 0 and char == "\ufeff"):
            match = _SPACE.match(source, index)
            index = match.end() if match else index + 1
            line += source[start:index].count("\n")
            continue
        comment = source.startswith("--", index)
        long_start = index + 2 if comment else index
        long_match = _LONG_OPEN.match(source, long_start)
        if long_match:
            closer = "]" + long_match.group(1) + "]"
            content_start = long_match.end()
            close = source.find(closer, content_start)
            if close < 0:
                raise ValueError(f"Unterminated Lua long {'comment' if comment else 'string'} at line {line}")
            index = close + len(closer)
            line += source[start:index].count("\n")
            if not comment:
                value = source[content_start:close]
                # Lua discards a single initial newline in long strings.
                value = re.sub(r"^(?:\r\n|\n\r|\n|\r)", "", value)
                value = value.replace("\r\n", "\n").replace("\n\r", "\n").replace("\r", "\n")
                tokens.append(Token("string", value, start_line, start, index))
            continue
        if comment:
            newline = source.find("\n", index)
            index = newline if newline >= 0 else length
            continue
        if char in ('"', "'"):
            quote, value = char, []
            index += 1
            while index < length and source[index] != quote:
                char = source[index]
                if char in "\r\n":
                    raise ValueError(f"Unescaped newline in Lua string at line {start_line}")
                if char != "\\":
                    value.append(char.encode("utf-8"))
                    index += 1
                    continue
                index += 1
                if index >= length:
                    break
                char = source[index]
                if char in _ESCAPES:
                    value.append(_ESCAPES[char].encode("utf-8"))
                    index += 1
                elif char in "\r\n":
                    first = char
                    index += 1
                    if index < length and source[index] in "\r\n" and source[index] != first:
                        index += 1
                    value.append(b"\n")
                    line += 1
                elif char == "z":
                    index += 1
                    match = _SPACE.match(source, index)
                    if match:
                        line += source[index:match.end()].count("\n")
                        index = match.end()
                elif char.isdigit() and char.isascii():
                    match = re.match(r"[0-9]{1,3}", source[index:])
                    number = int(match.group())
                    if number > 255:
                        raise ValueError(f"Invalid Lua decimal escape at line {line}")
                    value.append(bytes([number]))
                    index += len(match.group())
                elif char == "x" and re.match(r"[0-9a-fA-F]{2}", source[index + 1:index + 3]):
                    value.append(bytes([int(source[index + 1:index + 3], 16)]))
                    index += 3
                elif char == "u":
                    match = re.match(r"u\{([0-9a-fA-F]+)\}", source[index:])
                    if not match or int(match.group(1), 16) > 0x10FFFF:
                        raise ValueError(f"Invalid Lua Unicode escape at line {line}")
                    value.append(chr(int(match.group(1), 16)).encode("utf-8"))
                    index += len(match.group())
                else:
                    raise ValueError(f"Invalid Lua escape at line {line}")
            if index >= length:
                raise ValueError(f"Unterminated Lua string at line {start_line}")
            index += 1
            # Lua numeric escapes encode bytes, including UTF-8 exported by
            # CurseForge (e.g. \\195\\169 is one accented character).
            try:
                decoded = b"".join(value).decode("utf-8")
            except UnicodeDecodeError:
                # Lua can also carry binary strings unrelated to translations.
                decoded = b"".join(value).decode("latin-1")
            tokens.append(Token("string", decoded, start_line, start, index))
            continue
        match = _WORD.match(source, index)
        if match:
            index = match.end()
            tokens.append(Token("word", match.group(), line, start, index))
            continue
        symbol = next((item for item in ("...", "..", "==", "~=", "<=", ">=", "::", "//", "<<", ">>")
                       if source.startswith(item, index)), char)
        index += len(symbol)
        tokens.append(Token("symbol", symbol, line, start, index))
    return tokens


def _diagnostic(code, severity, key, path, line, message):
    return dict(code=code, severity=severity, key=key, path=path, line=line,
                locale="enUS", message=message)


def _pairs(tokens):
    """Map balanced delimiters once, so scanning large routes stays linear."""
    stack, pairs = [], {}
    closing = {")": "(", "]": "[", "}": "{"}
    for index, token in enumerate(tokens):
        if token.kind != "symbol":
            continue
        if token.value in ("(", "[", "{"):
            stack.append(index)
        elif token.value in closing:
            if not stack or tokens[stack[-1]].value != closing[token.value]:
                raise ValueError(f"Unbalanced Lua delimiter at line {token.line}")
            start = stack.pop()
            pairs[start] = index
    if stack:
        raise ValueError(f"Unclosed Lua delimiter at line {tokens[stack[-1]].line}")
    return pairs


def _top_level(tokens, start, end, pairs):
    index = start
    while index < end:
        yield index
        index = pairs[index] + 1 if index in pairs else index + 1


def _choices(tokens, start, end, pairs):
    """Finite literal result values (concatenation and Lua and/or idioms)."""
    while start < end and tokens[start].value == "(" and pairs.get(start) == end - 1:
        start, end = start + 1, end - 1
    if end - start == 1 and tokens[start].kind == "string":
        return [(tokens[start].value, tokens[start])]
    top = list(_top_level(tokens, start, end, pairs))
    # An and/or condition's predicate is not a localization key.
    ors = [index for index in top if tokens[index].kind == "word" and tokens[index].value == "or"]
    if ors:
        result, previous = [], start
        for index in ors + [end]:
            choices = _choices(tokens, previous, index, pairs)
            if choices is None:
                return None
            result.extend(choices)
            previous = index + 1
        return result
    ands = [index for index in top if tokens[index].kind == "word" and tokens[index].value == "and"]
    if ands:
        return _choices(tokens, ands[-1] + 1, end, pairs)
    if len(top) >= 3 and len(top) % 2 == 1 and all(
            tokens[index].kind == "string" if offset % 2 == 0 else tokens[index].value == ".."
            for offset, index in enumerate(top)):
        return [("".join(tokens[index].value for index in top[::2]), tokens[start])]
    return None


def _expression_end(tokens, start, limit, pairs):
    """End of a table field expression, with nested calls/tables skipped."""
    for index in _top_level(tokens, start, limit, pairs):
        if tokens[index].value in (",", ";", "}"):
            return index
    return limit


def _fields(tokens, pairs):
    """Yield literal named assignments, including ['Note'] table keys."""
    for index, token in enumerate(tokens):
        if token.kind == "word" and index + 1 < len(tokens) and tokens[index + 1].value == "=":
            yield token.value, index + 2
        elif token.value == "[" and pairs.get(index) == index + 2 and tokens[index + 1].kind == "string":
            if index + 3 < len(tokens) and tokens[index + 3].value == "=":
                yield tokens[index + 1].value, index + 4


def _field_literals(tokens, pairs, field):
    return [(tokens[start].value, tokens[start]) for name, start in _fields(tokens, pairs)
            if name == field and start < len(tokens) and tokens[start].kind == "string"]


def _named_table(tokens, pairs, name, *, keys=False):
    for field, start in _fields(tokens, pairs):
        if field != name or start not in pairs or tokens[start].value != "{":
            continue
        end, result = pairs[start], []
        for index in _top_level(tokens, start + 1, end, pairs):
            token = tokens[index]
            if keys:
                if token.value == "[" and pairs.get(index) == index + 2 and tokens[index + 1].kind == "string":
                    result.append((tokens[index + 1].value, tokens[index + 1]))
                elif token.kind == "word" and index + 1 < end and tokens[index + 1].value == "=":
                    result.append((token.value, token))
            elif token.kind == "string":
                # Ignore dictionary keys; only values of an array/map are wanted.
                if index + 1 == end or tokens[index + 1].value != "=":
                    result.append((token.value, token))
        return result
    return []


# These consumers deliberately use data keys instead of literal L[...] calls.
# Models are restricted by file + expression, never an addon-wide substring.
_FIELD_CONSUMERS = {
    ("APR-Core/config/AboutData.lua", "credit.label"): "label",
    ("APR-Core/ui/panels/LayoutEditor.lua", "definition.label"): "label",
    ("APR-Core/ui/route/RouteBrowser.lua", "definition.label"): "label",
    ("APR-Core/ui/route/RouteBrowser.lua", "definition.tooltip"): "tooltip",
}
_SCENARIO_FILES = {"APR-Core/features/questing/StepTravelHandlers.lua",
                   "APR-Core/ui/route/QuestOrderListRows.lua"}
_SCENARIO_KINDS = ("DUNGEON", "SCENARIO", "DELVE", "RAID")


def _modeled_choices(path, expression, tokens, pairs, lookup):
    field = _FIELD_CONSUMERS.get((path, expression))
    if field:
        return _field_literals(tokens, pairs, field)
    if path == "APR-Core/features/questing/RouteActions.lua" and expression == "key:upper()":
        return [(key.upper(), token) for key, token in _named_table(tokens, pairs, "actionKeys")]
    if path == "APR-Core/core/Event.lua" and expression == "key":
        return _named_table(tokens, pairs, "gigglingBasket", keys=True)
    if path in _SCENARIO_FILES and expression in ("kind", "scenarioInfo.type", '"LEAVE_"..kind', "leaveKey"):
        prefix = "LEAVE_" if "LEAVE_" in expression or expression == "leaveKey" else ""
        return [(prefix + key, lookup) for key in _SCENARIO_KINDS]
    if path == "APR-Core/features/navigation/Navigation.lua" and expression == "key":
        # Local state branch immediately above the lookup; finite, not NAVIGATION_*.
        return [(key, lookup) for key in ("NAVIGATION_CALCULATING", "NAVIGATION_WAITING")]
    if path == "APR-Core/features/player/XPBuffOverlay.lua" and expression == "message":
        result = []
        for index, token in enumerate(tokens):
            if token.value != "SetDismissTooltip" or index + 1 not in pairs:
                continue
            end = pairs[index + 1]
            top = list(_top_level(tokens, index + 2, end, pairs))
            for offset in top:
                if tokens[offset].value == ",":
                    result.extend(_choices(tokens, offset + 1, end, pairs) or [])
                    break
        return result
    if path == "APR-Core/integrations/Gamepad.lua" and expression == "label":
        # The final pairs({...}) defines the binding labels. Other named maps in
        # this file must not keep a translation alive accidentally.
        for index in range(len(tokens) - 3, -1, -1):
            if tokens[index].value == "pairs" and tokens[index + 1].value == "(" and tokens[index + 2].value == "{":
                end = pairs.get(index + 2, index + 2)
                return [
                            (tokens[offset + 2].value, tokens[offset + 2])
                            for offset in _top_level(tokens, index + 3, end, pairs)
                            if tokens[offset].kind == "word" and offset + 2 < end
                            and tokens[offset + 1].value == "=" and tokens[offset + 2].kind == "string"]
    return None


def _expression_label(tokens, start, end):
    # Include quotes to distinguish a literal prefix from a field name.
    return "".join(('"' + token.value.replace('"', '\\"') + '"') if token.kind == "string" else token.value
                   for token in tokens[start:end])


_BINARY_OPERATORS = {"and", "or", "<", ">", "<=", ">=", "~=", "==", "|", "~", "&",
                     "<<", ">>", "..", "+", "-", "*", "/", "//", "%", "^"}


def _operand_end(tokens, start, pairs):
    """Bound one or-operand without crossing into another Lua statement.

    Delimiter pairs skip function arguments and indexes, so an unrelated string
    inside a call is never mistaken for the call's returned fallback text.
    """
    def primary(index):
        if index >= len(tokens):
            return index
        token = tokens[index]
        if token.kind != "string" and token.value in {"not", "#", "-", "~"}:
            return primary(index + 1)
        if token.value in {"(", "{"} and index in pairs:
            end = pairs[index] + 1
        elif token.kind in {"word", "string"} or token.value.isdecimal():
            end = index + 1
            # Numbers are irrelevant to keys and remain symbol tokens. Consume
            # their adjacent pieces here, including decimal and hex notation.
            if token.value.isdecimal():
                while end < len(tokens) and tokens[end - 1].end == tokens[end].offset and (
                        tokens[end].value.isdecimal() or tokens[end].value == "."
                        or re.fullmatch(r"[xXpPeEa-fA-F0-9]+", tokens[end].value)):
                    end += 1
        else:
            return index
        while end < len(tokens):
            if tokens[end].value in {"[", "(", "{"} and end in pairs:
                end = pairs[end] + 1
            elif tokens[end].value in {".", ":"} and end + 1 < len(tokens) and tokens[end + 1].kind == "word":
                end += 2
            elif tokens[end].kind == "string" and tokens[end - 1].kind != "string":
                end += 1  # Lua's f"argument" call syntax.
            else:
                break
        return end

    end = primary(start)
    while (end > start and end < len(tokens) and tokens[end].kind != "string"
           and tokens[end].value in _BINARY_OPERATORS - {"or"}):
        following = primary(end + 1)
        if following == end + 1:
            break
        end = following
    return end


def _literal_results(tokens, start, end, pairs):
    """Literal output branches, never predicates or strings inside calls."""
    while start < end and tokens[start].value == "(" and pairs.get(start) == end - 1:
        start, end = start + 1, end - 1
    if end - start == 1 and tokens[start].kind == "string":
        return [(tokens[start].value, tokens[start])]
    top = list(_top_level(tokens, start, end, pairs))
    ors = [index for index in top if tokens[index].kind == "word" and tokens[index].value == "or"]
    if ors:
        result, previous = [], start
        for index in ors + [end]:
            result.extend(_literal_results(tokens, previous, index, pairs))
            previous = index + 1
        return result
    ands = [index for index in top if tokens[index].kind == "word" and tokens[index].value == "and"]
    if ands:
        return _literal_results(tokens, ands[-1] + 1, end, pairs)
    concats = [index for index in top if tokens[index].value == ".."]
    if concats:
        result, previous = [], start
        for index in concats + [end]:
            result.extend(_literal_results(tokens, previous, index, pairs))
            previous = index + 1
        return result
    return []


def _fallback_literals(tokens, start, end, pairs):
    """Find literal fallbacks after a lookup, including wrapped/chained ors."""
    result = []
    while end < len(tokens):
        if tokens[end].value == ")" and start > 0 and pairs.get(start - 1) == end:
            # Only grouping parentheses, not f(L.KEY)'s call arguments.
            before = tokens[start - 2] if start > 1 else None
            if before is not None and (before.value in {".", ":", ")", "]"}
                                       or before.kind == "word" and before.value not in
                                       {"return", "and", "or", "not", "if", "elseif", "while", "until"}):
                break
            start, end = start - 1, end + 1
            continue
        if tokens[end].kind != "word" or tokens[end].value != "or":
            break
        operand = end + 1
        end = _operand_end(tokens, operand, pairs)
        if end == operand:
            break
        result.extend(_literal_results(tokens, operand, end, pairs))
    # Empty guards and structural metric markers ("-", "…", digits) carry no
    # language. Alphabetic text, including non-Latin scripts, must be catalogued.
    return [(value, origin) for value, origin in result if any(char.isalpha() for char in value)]


def _fallback_diagnostics(tokens, start, end, pairs, choices, path):
    keys = [key for key, _ in choices or []] or ["<dynamic>"]
    return [_diagnostic("hardcoded_fallback", "error", key, path, origin.line,
                        "Hardcoded localization fallback is forbidden; publish and translate the key in CurseForge.")
            for _, origin in _fallback_literals(tokens, start, end, pairs) for key in keys]


def _route_literals(tokens, start, end, pairs):
    """Scalars, lists and {text=..., color=...} without treating colors as keys."""
    choices = _choices(tokens, start, end, pairs)
    if choices is not None:
        return choices
    if start >= end or tokens[start].value != "{" or pairs.get(start) != end - 1:
        return []
    result, index = [], start + 1
    while index < end - 1:
        if tokens[index].value in (",", ";"):
            index += 1
            continue
        value_end = _expression_end(tokens, index, end - 1, pairs)
        if index + 1 < value_end and tokens[index + 1].value == "=":
            if tokens[index].value in ("text", "Text"):
                result.extend(_route_literals(tokens, index + 2, value_end, pairs))
        else:
            result.extend(_route_literals(tokens, index, value_end, pairs))
        index = value_end + 1
    return result


def scan_sources(root: Path):
    """Scan runtime APR-Core and Routes; all paths are repository-relative."""
    root = Path(root)
    references, diagnostics = [], []
    excluded = {"libs", "lib", "vendor", ".git", "locales", "locale"}
    for directory in (root / "APR-Core", root / "Routes"):
        if not directory.exists():
            continue
        for file in sorted(directory.rglob("*.lua")):
            relative = file.relative_to(root)
            if any(part.lower() in excluded for part in relative.parts[:-1]):
                continue
            path = relative.as_posix()
            try:
                tokens = tokenize_lua(file.read_text(encoding="utf-8-sig"))
                pairs = _pairs(tokens)
            except (OSError, UnicodeError, ValueError) as error:
                # Do not include file contents or arbitrary exception text in PR reports.
                location = re.search(r"at line (\d+)", str(error)) if isinstance(error, ValueError) else None
                diagnostic = _diagnostic("source_parse", "error", "", path, int(location.group(1)) if location else 1,
                                         f"Cannot statically parse Lua source ({type(error).__name__}).")
                diagnostic["operational"] = True
                diagnostics.append(diagnostic)
                continue
            for index, token in enumerate(tokens):
                if token.kind == "word" and token.value == "rawget" and index + 1 in pairs:
                    end = pairs[index + 1]
                    if index + 4 < end and tokens[index + 2].value == "L" and tokens[index + 3].value == ",":
                        choices = _choices(tokens, index + 4, end, pairs)
                        for key, origin in choices or []:
                            references.append(dict(key=key, path=path, line=origin.line, kind="lookup"))
                        diagnostics.extend(_fallback_diagnostics(tokens, index, end + 1, pairs, choices, path))
                        expression = _expression_label(tokens, index + 4, end)
                        # ResolveStepText is the documented route-text consumer;
                        # its callers/data fields are scanned above and below.
                        if choices is None and (path, expression) != ("APR-Core/utils/StepUtils.lua", "key"):
                            diagnostics.append(_diagnostic("unresolved_dynamic", "warning", expression, path, token.line,
                                                           "Dynamic localization lookup cannot be resolved statically; review its possible keys."))
                if token.kind != "word" or token.value != "L" or index + 2 >= len(tokens):
                    continue
                start, end, after = None, None, None
                if tokens[index + 1].value == "[" and index + 1 in pairs:
                    start, end = index + 2, pairs[index + 1]
                    after = end + 1
                    choices = _choices(tokens, start, end, pairs)
                elif tokens[index + 1].value == "." and tokens[index + 2].kind == "word":
                    after = index + 3
                    choices = [(tokens[index + 2].value, tokens[index + 2])]
                else:
                    continue
                if after < len(tokens) and tokens[after].value == "=":
                    value_start = after + 1
                    value_end = _operand_end(tokens, value_start, pairs)
                    literal_values = _literal_results(tokens, value_start, value_end, pairs)
                    while (value_start < value_end and tokens[value_start].value == "("
                           and pairs.get(value_start) == value_end - 1):
                        value_start, value_end = value_start + 1, value_end - 1
                    literal_true = value_end - value_start == 1 and tokens[value_start].value == "true"
                    if literal_true or any(value.strip() for value, _ in literal_values):
                        definition_keys = [key for key, _ in choices or []]
                        if not definition_keys:
                            definition_keys = [_expression_label(tokens, start, end)]
                        diagnostics.extend(_diagnostic("hardcoded_locale_definition", "error", key, path, token.line,
                                                       "Runtime locale definitions are forbidden; publish and translate the key in CurseForge.")
                                           for key in definition_keys)
                    continue  # Definitions are not usage.
                diagnostics.extend(_fallback_diagnostics(tokens, index, after, pairs, choices, path))
                if choices is None:
                    expression = _expression_label(tokens, start, end)
                    choices = _modeled_choices(path, expression, tokens, pairs, token)
                    if choices is None or not choices:
                        diagnostics.append(_diagnostic("unresolved_dynamic", "warning", expression, path, token.line,
                                                       "Dynamic localization lookup cannot be resolved statically; review its possible keys."))
                        continue
                for key, origin in choices:
                    references.append(dict(key=key, path=path, line=origin.line, kind="lookup"))
            if relative.parts[0] == "Routes":
                for name, start in _fields(tokens, pairs):
                    if name not in {"Note", "text", "Text", "label", "tooltipMessage"} and not re.fullmatch(r"ExtraLineText\d*", name):
                        continue
                    end = _expression_end(tokens, start, len(tokens), pairs)
                    for key, origin in _route_literals(tokens, start, end, pairs):
                        key = re.sub(r"^\[COLOR:#?[0-9A-Fa-f]+\]\s*", "", key)
                        if key.strip():
                            references.append(dict(key=key, path=path, line=origin.line, kind="route_text"))
    # Deduplicate field-list entries discovered by both the outer and inner text
    # traversal, retaining separate occurrences and exact source locations.
    references = list({(ref["key"], ref["path"], ref["line"], ref["kind"]): ref for ref in references}.values())
    return dict(references=references, diagnostics=diagnostics, dynamic_patterns=[])


def analyze_sources(scan, catalog_keys):
    """Validate references and report exact unused keys, with no Lua execution."""
    catalog_keys = set(catalog_keys)
    diagnostics = list(scan.get("diagnostics", []))
    used = set()
    for reference in scan.get("references", []):
        key = reference["key"]
        if key in catalog_keys:
            used.add(key)
        elif reference["kind"] == "lookup" or re.fullmatch(r"[A-Z_][A-Z0-9_]*", key):
            diagnostics.append(_diagnostic("missing_key", "error", key, reference["path"], reference["line"],
                                           "Localization key is missing from the enUS catalog."))
        else:
            diagnostics.append(_diagnostic("raw_text", "error", key, reference["path"], reference["line"],
                                           "Literal route text is not in the localization catalog; translate it using a catalog key."))
    for pattern in scan.get("dynamic_patterns", []):
        used.update(key for key in catalog_keys if fnmatchcase(key, pattern))
    for key in sorted(catalog_keys - used):
        diagnostics.append(_diagnostic("unused_key", "warning", key, "CurseForge/enUS", 0,
                                       "Catalog key has no statically detected runtime reference."))
    return list({(entry["code"], entry["key"], entry["path"], entry["line"]): entry for entry in diagnostics}.values())
