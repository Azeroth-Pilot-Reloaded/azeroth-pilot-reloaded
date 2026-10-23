"""Validate APR localization and compare PR diagnostics with its merge base."""

import argparse
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from contextlib import nullcontext
import difflib
from html import escape
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tarfile
import tempfile
from urllib.parse import quote

import requests
from dotenv import load_dotenv

from curseforge_localization_fetch import fetch_localization_export
from localization_quality import evaluate_catalogs, evaluate_local_catalogs, parse_catalog
from localization_source import analyze_sources, scan_sources

load_dotenv()

LOCALES = ("deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW")
CHECKS = {
    "missing_key": "Source keys missing from CurseForge",
    "hardcoded_fallback": "Forbidden hardcoded fallback text",
    "hardcoded_locale_definition": "Forbidden runtime translation definitions",
    "raw_text": "Text without a translation key",
    "unused_key": "Unused CurseForge keys",
    "unresolved_dynamic": "Dynamic keys requiring review",
    "placeholder_mismatch": "Format parameters",
    "invalid_placeholder": "Invalid format parameters",
    "invalid_markup": "WoW markup",
    "markup_mismatch": "Missing WoW markup",
    "missing_translation": "Translation coverage",
    "export_error": "Export availability",
}


def fetch_translations_from_curseforge(api_url, api_key):
    return fetch_localization_export(api_url, api_key)


def set_localization_url(slug, cf_token, project_site, export_type="TableAdditions",
                         locale="enUS", unlocalized="Ignore", table_name="L",
                         escape_non_ascii_characters=False, true_if_value_equals_key=False):
    if not (slug and cf_token and project_site):
        return None
    params = [
        ("export-type", export_type), ("lang", locale), ("unlocalized", unlocalized),
        ("table-name", table_name),
        ("escape-non-ascii-characters", str(escape_non_ascii_characters).lower()),
        ("true-if-value-equals-key", str(true_if_value_equals_key).lower()),
    ]
    return f"{project_site.rstrip('/')}/api/projects/{slug}/localization/export?" + "&".join(
        f"{key}={value}" for key, value in params
    )


def get_locales_kv_table_additions(text):
    """Compatibility helper; commented/missing entries are never translations."""
    return list(parse_catalog(text).items())


def git(root, *args, binary=False):
    result = subprocess.run(
        ["git", "-C", str(root), *args], capture_output=True, timeout=90,
        text=not binary, encoding=None if binary else "utf-8",
    )
    if result.returncode:
        raise ValueError("Unable to read the Git comparison. Fetch the PR base and head history.")
    return result.stdout if binary else result.stdout.strip()


def current_commit(root):
    try:
        return git(root, "rev-parse", "--verify", "HEAD")
    except ValueError:
        return None


def diagnostic_identity(item):
    # Locations can shift when unrelated code is inserted above the same finding.
    return tuple(str(item.get(field, "")) for field in (
        "code", "severity", "key", "path", "locale", "message",
    ))


def classify_diagnostics(diagnostics, baseline=None):
    """Match occurrences, preserving new duplicates and ignoring line shifts."""
    previous = Counter(diagnostic_identity(item) for item in (baseline or []))
    result = []
    seen = set()
    for item in sorted(diagnostics, key=lambda d: (
            d.get("path", ""), d.get("line", 0), diagnostic_identity(d))):
        identity = diagnostic_identity(item)
        location = identity, item.get("line", 0)
        if location in seen:
            continue
        seen.add(location)
        existing = previous[identity] > 0 and not item.get("operational", False)
        if existing:
            previous[identity] -= 1
        result.append({**item, "is_new": not existing})
    return result


def referenced_keys(scan, catalog):
    import fnmatch
    keys = {entry["key"] for entry in scan["references"]}
    for pattern in scan.get("dynamic_patterns", []):
        keys.update(key for key in catalog if fnmatch.fnmatchcase(key, pattern))
    return keys


def analyze_tree(root, catalogs):
    scan = scan_sources(root)
    used = referenced_keys(scan, catalogs["enUS"])
    quality = evaluate_catalogs(catalogs, used_keys=used)
    local = evaluate_local_catalogs(root)
    diagnostics = analyze_sources(scan, set(catalogs["enUS"]))
    diagnostics.extend(quality["diagnostics"])
    diagnostics.extend(local["diagnostics"])
    locations = defaultdict(list)
    for entry in scan["references"]:
        location = {"path": entry["path"], "line": entry["line"]}
        if location not in locations[entry["key"]]:
            locations[entry["key"]].append(location)
    for item in diagnostics:
        if item.get("key") in locations:
            item["locations"] = locations[item["key"]]
    return diagnostics, quality["coverage"] + local["coverage"]


def compare_baseline(root, base_ref, catalogs):
    resolved = git(root, "rev-parse", "--verify", "--end-of-options", base_ref + "^{commit}")
    if not re.fullmatch(r"[0-9a-f]{40,64}", resolved):
        raise ValueError("Invalid base commit")
    merge_base = git(root, "merge-base", resolved, "HEAD")
    paths = git(root, "ls-tree", "--name-only", merge_base, "--", "APR-Core", "Routes").splitlines()
    archive = git(root, "archive", "--format=tar", merge_base, "--", *paths, binary=True) if paths else None
    # Read only Lua data from the base; never run its scripts or initialize a checkout.
    with tempfile.TemporaryDirectory(prefix="apr-localization-base-") as directory:
        snapshot = Path(directory)
        with (tarfile.open(fileobj=io.BytesIO(archive)) if archive else nullcontext([])) as tree:
            for member in tree:
                relative = PurePosixPath(member.name)
                if (not member.isfile() or relative.is_absolute() or ".." in relative.parts
                        or "\\" in member.name or relative.parts[0] not in {"APR-Core", "Routes"}
                        or relative.suffix.lower() != ".lua"):
                    continue
                target = snapshot.joinpath(*relative.parts)
                target.parent.mkdir(parents=True, exist_ok=True)
                with tree.extractfile(member) as source:
                    target.write_bytes(source.read())
        diagnostics, _ = analyze_tree(snapshot, catalogs)
    return diagnostics, merge_base


def report_code(value):
    value = str(value).replace("\r", "\\r").replace("\n", "\\n")
    return f"<code>{escape(value)}</code>"


def totals(diagnostics):
    return {
        f"{age}_{severity}s": sum(
            d["severity"] == severity and d.get("is_new", True) == (age == "new")
            for d in diagnostics
        )
        for age in ("new", "existing") for severity in ("warning", "error")
    }


def result_status(items):
    counts = totals(items)
    if counts["new_errors"]:
        return "❌ Failed"
    if counts["existing_errors"] or counts["new_warnings"] or counts["existing_warnings"]:
        return "⚠️ Review"
    return "✅ Passed"


def source_location(item, root=None, head_sha=None):
    path, line = item.get("path", ""), item.get("line", 0)
    if not line or not path:
        locations = item.get("locations", [])
        if locations:
            path, line = locations[0]["path"], locations[0]["line"]
    if not path:
        return ""
    label = f"{path}:{line}" if line else path
    repo = os.getenv("GITHUB_REPOSITORY", "")
    if (root and head_sha and line and re.fullmatch(r"[\w.-]+/[\w.-]+", repo)
            and not PurePosixPath(path).is_absolute() and ".." not in PurePosixPath(path).parts
            and (Path(root) / path).is_file()):
        server = os.getenv("GITHUB_SERVER_URL", "https://github.com").rstrip("/")
        return f"[{report_code(label)}]({server}/{repo}/blob/{head_sha}/{quote(path, safe='/')}#L{line})"
    return report_code(label)


def diagnostic_line(item, root=None, head_sha=None):
    parts = [report_code(item.get("key", "")), report_code(item.get("locale", "enUS")),
             report_code(item["code"])]
    location = source_location(item, root, head_sha)
    if location:
        parts.append(location)
    return "- " + " · ".join(parts) + " — " + report_code(item["message"])


def write_markdown_report(diagnostics, coverage=(), output_path="translation-report.md", *,
                          skip_reason=None, error_reason=None, baseline_sha=None,
                          root=None, head_sha=None):
    lines = ["## 🌍 Localization check report", ""]
    if skip_reason or error_reason:
        status = "❌ Check could not complete" if error_reason else "⏭️ Check skipped"
        lines.extend([
            f"**{status}**", "", "| Check | Result | Warnings | Errors |",
            "| --- | --- | ---: | ---: |", f"| Localization validation | {status} | — | — |", "",
            "Translation counts are unavailable because validation did not complete.", "",
            "<details>", "<summary>Details</summary>", "",
            report_code((error_reason or skip_reason)[:2000]), "", "</details>",
        ])
    else:
        count = totals(diagnostics)
        status = result_status(diagnostics)
        lines.extend([
            f"**{status} · {count['new_errors']} new errors · {count['new_warnings']} new warnings**", "",
            "| Check | Result | New warnings | Existing warnings | New errors | Existing errors |",
            "| --- | --- | ---: | ---: | ---: | ---: |",
        ])
        codes = list(CHECKS) + sorted({d["code"] for d in diagnostics} - CHECKS.keys())
        for code in codes:
            items = [d for d in diagnostics if d["code"] == code]
            counts = totals(items)
            lines.append(
                f"| {CHECKS.get(code, code.replace('_', ' ').capitalize())} | {result_status(items)} | "
                f"{counts['new_warnings']} | {counts['existing_warnings']} | "
                f"{counts['new_errors']} | {counts['existing_errors']} |"
            )
        lines.extend([
            f"| **Total** | **{status}** | **{count['new_warnings']}** | **{count['existing_warnings']}** | "
            f"**{count['new_errors']}** | **{count['existing_errors']}** |", "",
        ])
        if baseline_sha:
            lines.extend([f"Compared with merge base {report_code(baseline_sha)}.",
                          "Only new errors fail this PR. Existing findings remain visible.", ""])
        else:
            lines.extend(["Full validation: all errors fail the check; warnings are advisory.", ""])
        if coverage:
            lines.extend([
                "### Translation coverage", "",
                "| Catalog | Locale | Translated | Total | Coverage | Missing |",
                "| --- | --- | ---: | ---: | ---: | ---: |",
            ])
            for row in coverage:
                if row.get("unavailable"):
                    lines.append(f"| {row.get('source', 'CurseForge')} | {row['locale']} | — | — | ❌ Unavailable | — |")
                else:
                    lines.append(
                        f"| {row.get('source', 'CurseForge')} | {row['locale']} | {row['translated']} | "
                        f"{row['total']} | {row['percent']:.1f}% | {row['missing']} |"
                    )
            lines.append("")
        if diagnostics:
            lines.extend(["<details>", "<summary>Details · new and existing findings</summary>", ""])
            for is_new, severity, label in (
                (True, "error", "❌ New errors"), (True, "warning", "⚠️ New warnings"),
                (False, "error", "❌ Existing errors"), (False, "warning", "⚠️ Existing warnings"),
            ):
                items = [d for d in diagnostics if d.get("is_new", True) == is_new and d["severity"] == severity]
                if not items:
                    continue
                lines.extend([f"### {label} ({len(items)})", ""])
                budget, shown = 10_000, 0
                for item in items:
                    line = diagnostic_line(item, root, head_sha)
                    size = len(line.encode("utf-8")) + 1
                    if size > budget:
                        break
                    lines.append(line)
                    budget -= size
                    shown += 1
                if shown < len(items):
                    lines.extend(["", f"Showing {shown} of {len(items)} findings. "
                                  "See the JSON artifact and workflow logs for the complete list."])
                lines.append("")
            lines.append("</details>")
        else:
            lines.append("All localization checks passed.")
    Path(output_path).write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_json_report(path, payload):
    Path(path).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def fetch_catalogs(token, locales):
    def fetch(locale):
        url = set_localization_url(618667, token, "https://wow.curseforge.com",
                                   locale=locale, unlocalized="ShowBlankAsComment")
        return parse_catalog(fetch_translations_from_curseforge(url, token), locale, allow_empty=locale != "enUS")
    catalogs = {"enUS": fetch("enUS")}
    problems = []
    def safe_fetch(locale):
        try:
            return locale, fetch(locale), None
        except (requests.RequestException, ValueError) as error:
            return locale, None, type(error).__name__
    with ThreadPoolExecutor(max_workers=3) as pool:
        for locale, catalog, error in pool.map(safe_fetch, locales):
            if error:
                problems.append({
                    "code": "export_error", "severity": "error", "key": "", "path": "", "line": 0,
                    "locale": locale, "message": f"Unable to validate export ({error}).",
                    "operational": True,
                })
            else:
                catalogs[locale] = catalog
    return catalogs, problems


def run_checks(args):
    root = Path(args.root).resolve()
    token = os.getenv("CF_API_KEY")
    if not token:
        raise ValueError("Missing CurseForge API token")
    catalogs, operational = fetch_catalogs(token, args.locales)
    diagnostics, coverage = analyze_tree(root, catalogs)
    base_diagnostics, base_sha = None, None
    if args.base_ref:
        base_diagnostics, base_sha = compare_baseline(root, args.base_ref, catalogs)
    diagnostics = classify_diagnostics(diagnostics + operational, base_diagnostics)
    for item in operational:
        coverage.append({"locale": item["locale"], "source": "CurseForge", "unavailable": True})
    head_sha = current_commit(root)
    write_markdown_report(diagnostics, coverage, args.output, baseline_sha=base_sha, root=root, head_sha=head_sha)
    payload = {
        "schema_version": 1, "status": result_status(diagnostics), "head_sha": head_sha,
        "baseline_sha": base_sha, "mode": "new_errors" if base_sha else "all_errors",
        "totals": totals(diagnostics), "coverage": coverage, "diagnostics": diagnostics,
    }
    write_json_report(args.json_output, payload)
    for item in diagnostics:
        print(f"{'NEW' if item['is_new'] else 'EXISTING'} {item['severity'].upper()} "
              f"{item.get('path', '')}:{item.get('line', 0)} [{item.get('locale', 'enUS')}] "
              f"{item['code']} {item.get('key', '')}: {item['message']}")
    print(json.dumps(payload["totals"]))
    if not args.skip_similarity_check:
        values = list(catalogs["enUS"].items())
        similar = sum(
            difflib.SequenceMatcher(None, text, other).ratio() >= 0.9
            for index, (_, text) in enumerate(values) for _, other in values[index + 1:]
            if text and other
        )
        print(f"Similar enUS text pairs (>= 90%): {similar}")
    return int(bool(payload["totals"]["new_errors"]))


def locale_list(value):
    locales = tuple(dict.fromkeys(part.strip() for part in value.split(",") if part.strip() and part.strip() != "enUS"))
    if any(locale not in LOCALES for locale in locales):
        raise argparse.ArgumentTypeError("Unsupported locale; choose from " + ", ".join(LOCALES))
    return locales


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="Addon repository directory")
    parser.add_argument("--base-ref", help="PR base commit/ref; compare diagnostics against its merge base")
    parser.add_argument("--locales", type=locale_list, default=LOCALES, help="Comma-separated target locales (default: all)")
    parser.add_argument("--output", default="translation-report.md", help="Markdown report path")
    parser.add_argument("--json-output", default="translation-report.json", help="Complete diagnostic JSON path")
    parser.add_argument("--skip-similarity-check", action="store_true", help="Skip the optional enUS text similarity check")
    parser.add_argument("--skip-reason", help="Write an explicit skipped report without contacting CurseForge")
    args = parser.parse_args(argv)
    if args.skip_reason:
        write_markdown_report([], output_path=args.output, skip_reason=args.skip_reason)
        write_json_report(args.json_output, {"schema_version": 1, "status": "skipped", "reason": args.skip_reason,
                                            "diagnostics": [], "coverage": [], "totals": None})
        return 0
    try:
        return run_checks(args)
    except (requests.RequestException, OSError, ValueError, subprocess.TimeoutExpired, tarfile.TarError) as error:
        # Request exceptions can contain server bodies or URLs; never publish their text.
        reason = f"Localization validation failed ({type(error).__name__}). Check exports, source syntax and Git history."
        print(reason)
        write_markdown_report([], output_path=args.output, error_reason=reason)
        write_json_report(args.json_output, {"schema_version": 1, "status": "incomplete", "reason": reason,
                                            "diagnostics": [], "coverage": [], "totals": None})
        return 1


if __name__ == "__main__":
    sys.exit(main())
