"""Validate localization data without evaluating Lua or contacting CurseForge.

Coverage uses the complete enUS catalog. Diagnostic scope can be restricted to
source references, so the caller can compare a PR with its base revision.
"""

from __future__ import annotations

from collections import Counter
from pathlib import Path
import re

from localization_source import tokenize_lua


# Release automation deliberately clears these values after archiving a release.
ALLOW_BLANK_KEYS = frozenset({"New Changelog", "Prev Changelog"})
NAVIGATION_PATH = "APR-Core/libs/LibAPRNavigation-1.0/Locales.lua"
FORMAT = re.compile(r"%[-+ #0]*\d*(?:\.\d+)?([cdiouxXeEfgGaAqs])")
DATE_DIRECTIVE = r"%[-_0^#]*\d*[aAbBcCdDeFgGhHIjmMnprRStTuUVwWxXyYzZ%]"
DATE_RUN = re.compile(DATE_DIRECTIVE + r"(?:[^A-Za-z0-9%]*" + DATE_DIRECTIVE + r")*")
DATE_ONLY_CODES = frozenset("bBhHjmMnprRtTuUVwWyYzZ")


class CatalogParseError(ValueError):
    """A response is not a valid, literal CurseForge TableAdditions export."""


def _is(token, kind, value):
    return token.kind == kind and token.value == value


def _translated(key, value):
    return bool(value.strip()) or key in ALLOW_BLANK_KEYS


def parse_catalog(text, locale="enUS", allow_empty=False):
    """Read only literal ``L["key"] = "value"``/``true`` assignments.

    Comments represent untranslated entries and are excluded. An export for a
    language with no translations may be empty, but arbitrary HTML, Lua code,
    duplicate assignments and truncated responses always fail validation.
    """
    if not isinstance(text, str):
        raise CatalogParseError(f"{locale}: expected a text localization export")
    try:
        tokens = tokenize_lua(text)
    except ValueError as error:
        raise CatalogParseError(f"{locale}: malformed Lua localization export") from error
    catalog, seen = {}, set()
    index = 0
    # CurseForge prepends this initializer to its real TableAdditions exports.
    # Accept exactly the harmless literal shape, never arbitrary Lua setup code.
    if [(token.kind, token.value) for token in tokens[:6]] == [
        ("word", "L"), ("symbol", "="), ("word", "L"),
        ("word", "or"), ("symbol", "{"), ("symbol", "}"),
    ]:
        index = 6
    while index < len(tokens):
        if _is(tokens[index], "symbol", ";"):
            index += 1
            continue
        part = tokens[index:index + 6]
        if not (len(part) == 6 and _is(part[0], "word", "L")
                and _is(part[1], "symbol", "[") and part[2].kind == "string"
                and _is(part[3], "symbol", "]") and _is(part[4], "symbol", "=")
                and (part[5].kind == "string" or _is(part[5], "word", "true"))):
            raise CatalogParseError(f"{locale}: expected a literal TableAdditions assignment at line {tokens[index].line}")
        key = part[2].value
        if not key or key in seen:
            raise CatalogParseError(f"{locale}: duplicate or empty localization key at line {part[2].line}")
        seen.add(key)
        value = key if part[5].kind == "word" else part[5].value
        if _translated(key, value):
            catalog[key] = value
        index += 6
    if not catalog and not allow_empty:
        raise CatalogParseError(f"{locale}: localization export contains no active translations")
    return catalog


def _date_spans(value):
    """Do not mistake strftime date directives for printf parameters."""
    spans = []
    for match in DATE_RUN.finditer(value):
        codes = re.findall(r"%[-_0^#]*\d*([A-Za-z%])", match[0])
        if any(code in DATE_ONLY_CODES for code in codes):
            spans.append((match.start(), match.end()))
    return spans


def printf_parameters(value, *, formatted=False):
    """Return ordered conversion types and malformed format specifications.

    Width, precision and flags may differ between languages; parameter types and
    their order must match. A percent followed by prose ("50% complete") is
    literal. Unknown percent sequences only fail when a string has clear printf
    parameters, avoiding false errors in percentages and date format strings.
    """
    date_spans = _date_spans(value)
    parameters, errors, unknown = [], [], []
    index = 0
    while index < len(value):
        if value[index] != "%":
            index += 1
            continue
        date_end = next((end for start, end in date_spans if start <= index < end), None)
        if date_end is not None:
            index = date_end
            continue
        if value.startswith("%%", index):
            index += 2
            continue
        match = FORMAT.match(value, index)
        # "% discount", "%failure" and similar prose are not format tokens.
        word_tail = bool(match and match.end() < len(value) and value[match.end()].isalpha())
        before_percent = index - 1
        while before_percent >= 0 and value[before_percent].isspace():
            before_percent -= 1
        numeric_percent = before_percent >= 0 and value[before_percent].isdigit()
        spaced_percent = value[index + 1:index + 2].isspace()
        # Localized percentage prose often starts with a valid format letter:
        # "5% d'expérience", "30% o menos" or "5 %igen". Whitespace may
        # precede the percent sign too, including non-breaking spaces.
        literal_word = (word_tail and spaced_percent) or (numeric_percent and (spaced_percent or word_tail))
        if match and not literal_word:
            parameters.append("d" if match[1] == "i" else match[1])
            index = match.end()
            continue
        tail = value[index + 1:]
        prose = (literal_word or bool(re.match(r"\s+[^\W\d_]{2,}", tail))
                 or numeric_percent)
        if not prose:
            # Preserve only a bounded token in messages, never the full string.
            token = re.match(r"[^\s,;:()<>|]*", tail)[0]
            unknown.append("%" + token[:24])
        index += 1
    explicit_format = any(re.match(r"%[-+#0]*(?:\d+\$|\*|\d+[A-Za-z]|\.\d+|[hlL][cdiouxXeEfgGaAqs])", token)
                          for token in unknown)
    if formatted or parameters or explicit_format:
        errors = [f"Invalid printf specification {token!r}" for token in unknown]
    return tuple(parameters), errors


def wow_markup(value):
    """Check paired WoW colors, hyperlinks, textures and atlases; skip ``||``."""
    counts, issues = Counter(), []
    colors, link, link_start = 0, None, 0
    index = 0
    while index < len(value):
        if value[index] != "|" or index + 1 == len(value):
            index += 1
            continue
        code = value[index + 1]
        if code == "|":
            index += 2
            continue
        if code == "c":
            named = re.match(r"\|cn[A-Za-z_][A-Za-z_0-9]*:", value[index:])
            hex_color = re.match(r"\|c[0-9A-Fa-f]{8}", value[index:])
            match = named or hex_color
            if not match:
                issues.append("Color tag |c must contain eight hexadecimal digits or a named color")
                index += 2
                continue
            colors += 1
            counts["color"] += 1
            index += len(match[0])
            continue
        if code == "r":
            if colors:
                colors -= 1
            else:
                issues.append("Color reset |r has no opening color tag")
        elif code == "H":
            if link is not None:
                issues.append("Hyperlink |H starts before the previous link is closed")
            link = "payload"
            link_start = index + 2
            counts["link"] += 1
        elif code == "h":
            if link == "payload":
                if index == link_start:
                    issues.append("Hyperlink |H has an empty target")
                link = "label"
            elif link == "label":
                link = None
            else:
                issues.append("Hyperlink separator |h has no opening |H")
        elif code in "TA":
            close = "t" if code == "T" else "a"
            kind = "texture" if code == "T" else "atlas"
            counts[kind] += 1
            end = index + 2
            while end < len(value):
                if value.startswith("||", end):
                    end += 2
                elif value[end] == "|":
                    break
                else:
                    end += 1
            if not value.startswith("|" + close, end):
                issues.append(f"Unclosed {kind} tag |{code} (missing |{close})")
            else:
                if end == index + 2:
                    issues.append(f"Empty {kind} tag |{code}")
                index = end + 2
                continue
        elif code in "ta":
            issues.append(f"Closing tag |{code} has no opening |{'T' if code == 't' else 'A'}")
        index += 2
    if colors:
        issues.append(f"{colors} unclosed color tag(s), missing |r")
    if link is not None:
        issues.append("Unclosed hyperlink |H (expected two |h separators)")
    return counts, issues


def _diagnostic(code, severity, key, locale, message, *, path=None, line=0):
    return {"code": code, "severity": severity, "key": key,
            "path": path or f"CurseForge/{locale}", "line": line,
            "locale": locale, "message": message}


def evaluate_catalogs(catalogs, used_keys=None):
    """Compare every supplied language with enUS; no network or Lua execution."""
    if "enUS" not in catalogs:
        raise CatalogParseError("The enUS reference catalog is required")
    reference = catalogs["enUS"]
    reference_keys = set(reference)
    checked_keys = reference_keys if used_keys is None else reference_keys.intersection(used_keys)
    coverage, diagnostics = [], []
    for locale, catalog in sorted(catalogs.items()):
        translated_keys = {key for key in reference_keys if key in catalog and _translated(key, catalog[key])}
        total = len(reference_keys)
        translated = len(translated_keys)
        coverage.append({"locale": locale, "total": total, "translated": translated,
                         "missing": total - translated,
                         "percent": round(100 * translated / total, 2) if total else 100.0,
                         "source": "CurseForge"})
        for key in sorted(checked_keys):
            if key not in translated_keys:
                diagnostics.append(_diagnostic("missing_translation", "error", key, locale,
                                               "Required translation is missing from this locale."))
                continue
            source = reference[key]
            value = catalog[key]
            source_parameters, _ = printf_parameters(source)
            parameters, format_issues = printf_parameters(value, formatted=bool(source_parameters))
            if format_issues:
                diagnostics.append(_diagnostic("invalid_placeholder", "error", key, locale,
                                               "; ".join(format_issues)))
            if locale != "enUS" and parameters != source_parameters:
                diagnostics.append(_diagnostic("placeholder_mismatch", "error", key, locale,
                                               f"Expected parameters {source_parameters!r}; found {parameters!r}"))
            source_markup, _ = wow_markup(source)
            markup, markup_issues = wow_markup(value)
            if markup_issues:
                diagnostics.append(_diagnostic("invalid_markup", "error", key, locale,
                                               "; ".join(markup_issues)))
            elif locale != "enUS" and markup != source_markup:
                diagnostics.append(_diagnostic("markup_mismatch", "error", key, locale,
                                               f"Expected WoW tags {dict(source_markup)!r}; found {dict(markup)!r}"))
    return {"coverage": coverage, "diagnostics": diagnostics}


def _navigation_catalogs(text):
    """Read the repository-owned navigation library's literal locale tables."""
    tokens = tokenize_lua(text)
    start = next((index + 5 for index in range(len(tokens) - 4)
                  if [_token.value for _token in tokens[index:index + 5]] == ["Lib", ".", "locales", "=", "{"]), None)
    if start is None:
        raise CatalogParseError("Navigation locale table was not found")
    catalogs, lines = {}, {}
    index = start
    while index < len(tokens) and tokens[index].value != "}":
        if tokens[index].value in (",", ";"):
            index += 1
            continue
        part = tokens[index:index + 3]
        if not (len(part) == 3 and part[0].kind == "word"
                and re.fullmatch(r"[a-z]{2}[A-Z]{2}", part[0].value)
                and _is(part[1], "symbol", "=") and _is(part[2], "symbol", "{")):
            raise CatalogParseError("Navigation locale tables must use literal language entries")
        locale = part[0].value
        if locale in catalogs:
            raise CatalogParseError(f"Duplicate navigation locale {locale}")
        catalog = catalogs[locale] = {}
        lines[(locale, "")] = part[0].line
        index += 3
        seen = set()
        while index < len(tokens) and tokens[index].value != "}":
            if tokens[index].value in (",", ";"):
                index += 1
                continue
            entry = tokens[index:index + 5]
            if not (len(entry) == 5 and _is(entry[0], "symbol", "[") and entry[1].kind == "string"
                    and _is(entry[2], "symbol", "]") and _is(entry[3], "symbol", "=")
                    and (entry[4].kind == "string" or _is(entry[4], "word", "true"))):
                raise CatalogParseError(f"Invalid navigation translation at line {tokens[index].line}")
            key = entry[1].value
            if key in seen:
                raise CatalogParseError(f"Duplicate navigation key at line {entry[1].line}")
            seen.add(key)
            value = key if entry[4].kind == "word" else entry[4].value
            if _translated(key, value):
                catalog[key] = value
            lines[(locale, key)] = entry[1].line
            index += 5
        if index >= len(tokens):
            raise CatalogParseError(f"Unclosed navigation locale {locale}")
        index += 1
    if index >= len(tokens):
        raise CatalogParseError("Unclosed navigation locale table")
    return catalogs, lines


def evaluate_local_catalogs(root, used_keys=None):
    """Validate all shipped navigation translations, which are not on CF."""
    path = Path(root) / NAVIGATION_PATH
    if not path.is_file():
        return {"coverage": [], "diagnostics": []}
    catalogs, lines = _navigation_catalogs(path.read_text(encoding="utf-8"))
    # A removed language table must still be visible for a locale the addon ships.
    for locale_file in (Path(root) / "APR-Core/locales").glob("*.lua"):
        if re.fullmatch(r"[a-z]{2}[A-Z]{2}", locale_file.stem):
            catalogs.setdefault(locale_file.stem, {})
    result = evaluate_catalogs(catalogs, used_keys)
    for row in result["coverage"]:
        row["source"] = "LibAPRNavigation"
    for diagnostic in result["diagnostics"]:
        diagnostic["path"] = NAVIGATION_PATH
        diagnostic["line"] = lines.get((diagnostic["locale"], diagnostic["key"]),
                                       lines.get((diagnostic["locale"], ""), 1))
    return result
