"""Read-only structural, access and progression audit of discovered Forever routes."""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tests.routes.route_loader import RouteCatalog, load_routes
from tests.routes.route_schema import InvalidRoute, RouteSchema


def manifest_findings(paths, manifests):
    """Check only the selected sources; no maintained route inventory is embedded."""
    selected = {path.resolve() for path in paths}
    registered = Counter()
    findings = []
    for manifest in manifests:
        try:
            entries = ET.parse(manifest).getroot()
        except (OSError, ET.ParseError) as error:
            findings.append(dict(severity="error", rule="manifest_parse", route="",
                                 path="", file=str(manifest), message=str(error)))
            continue
        for entry in entries:
            if "file" not in entry.attrib:
                continue
            path = (ROOT / entry.attrib["file"]).resolve()
            if path in selected:
                registered[path] += 1
    for path in sorted(selected):
        if registered[path] != 1:
            findings.append(dict(severity="error", rule="manifest_registration", route="",
                                 path="", file=str(path), message=f"Expected one registration, found {registered[path]}"))
    return findings


def merge_overlapping_checks(findings, completion_results=None):
    """Keep independent evidence without counting one condition problem twice."""
    result = []
    contradictions = {}
    terminals = {}
    for item in findings:
        identity = (item.get("file", ""), item["route"], item["path"])
        if item["rule"] == "guard.step-contradiction":
            contradictions[identity] = item
        elif item["rule"] == "progression.conditional-terminal":
            for path in item.get("evidence", {}).get("terminalPaths", []):
                terminals[(identity[0], identity[1], path)] = item
    for item in findings:
        if (item["rule"] == "conditional-route-completion"
                and (completion_results or {}).get(item["route"]) == "unsatisfiable"):
            # A route-level hard gate can make an authored terminal filter
            # redundant. Keep warnings when proof is absent or exhausted.
            continue
        identity = (item.get("file", ""), item["route"], item["path"])
        target = (contradictions.get(identity) if item["rule"] == "progression.impossible-filter"
                  else terminals.get(identity) if item["rule"] == "conditional-route-completion" else None)
        if target is not None:
            target.setdefault("evidence", {}).setdefault("supporting_checks", []).append(
                {"rule": item["rule"], "path": item["path"], "evidence": item.get("evidence", {})})
        else:
            result.append(item)
    return result


def audit_directory(directory, *, analyzers=None, source_auditor=None, manifests=()):
    """Load files independently so one invalid declaration cannot hide other files."""
    directory = Path(directory).resolve()
    paths = sorted(directory.rglob("*.lua"))
    if analyzers is None or source_auditor is None:
        from tools.validation import route_structure_audit as structure
        from tools.validation import route_guard_audit as guards
        from tools.validation import route_progression_audit as progression
        if analyzers is None:
            analyzers = (structure.audit_routes, guards.audit_routes, progression.audit_routes)
        if source_auditor is None:
            source_auditor = structure.audit_sources
    findings = list(source_auditor(paths))
    findings.extend(manifest_findings(paths, manifests) if manifests else [])
    if not paths:
        findings.append(dict(severity="error", rule="no_route_sources", route="", path="",
                             file=str(directory), message="No Lua route files found"))
    catalog = None
    failed_files = []
    for path in paths:
        try:
            loaded = load_routes([path])
        except Exception as error:
            failed_files.append(str(path))
            findings.append(dict(severity="error", rule="route_load", route="", path="",
                                 file=str(path), message=str(error)))
            continue
        if catalog is None:
            catalog = RouteCatalog({}, {}, loaded.enums, loaded.profiles)
        for key, declaration in loaded.routes.items():
            if key in catalog.routes:
                findings.append(dict(severity="error", rule="duplicate_route_key", route=key,
                                     path="", file=str(path), message="Route key declared in multiple files",
                                     evidence={"other_file": catalog.sources[key]}))
            else:
                catalog.routes[key] = declaration
                catalog.sources[key] = loaded.sources[key]
    skipped = []
    if catalog is not None:
        schema = RouteSchema(catalog)
        valid = {}
        for key, route in catalog.routes.items():
            try:
                schema.validate(key, route)
            except (InvalidRoute, TypeError, ValueError) as error:
                skipped.append(key)
                findings.append(dict(severity="error", rule="route_schema", route=key,
                                     path="", message=str(error)))
            else:
                valid[key] = route
        # Structural analysis also sees invalid shapes to explain their contracts;
        # semantic analyses receive only successfully validated declarations.
        for index, analyzer in enumerate(analyzers):
            target = catalog if index == 0 else RouteCatalog(valid, catalog.sources, catalog.enums, catalog.profiles)
            findings.extend(analyzer(target))
    normalized = []
    seen = set()
    for finding in findings:
        item = dict(finding)
        item.setdefault("route", "")
        item.setdefault("path", "")
        if not item.get("file") and catalog is not None:
            item["file"] = catalog.sources.get(item["route"], "")
        marker = json.dumps(item, sort_keys=True, ensure_ascii=False)
        if marker not in seen:
            seen.add(marker)
            normalized.append(item)
    completion_results = {}
    if catalog is not None and any(getattr(a, "__module__", "").endswith("route_progression_audit") for a in analyzers):
        from tools.validation.route_progression_audit import ConditionModel, completion_analysis
        model = ConditionModel(catalog)
        for item in normalized:
            key = item["route"]
            if item["rule"] == "conditional-route-completion" and key in valid:
                completion_results[key] = completion_analysis(valid[key], model)[0].status
    normalized = merge_overlapping_checks(normalized, completion_results)
    normalized.sort(key=lambda row: (row["severity"] != "error", row.get("file", ""),
                                     row["route"], row["path"], row["rule"]))
    return {
        "directory": str(directory), "files": len(paths),
        "routes": len(catalog.routes) if catalog else 0,
        "semantic_routes": len(catalog.routes) - len(skipped) if catalog else 0,
        "failed_files": failed_files, "skipped_invalid_routes": skipped,
        "summary": dict(Counter(item["severity"] for item in normalized)),
        "rules": dict(sorted(Counter(item["rule"] for item in normalized).items())),
        "findings": normalized,
        "limitations": [
            "Static analysis does not prove completion in the live client.",
            "External quest availability, NPC access, loot, client events and manual actions can remain unknown.",
            "A character filter that skips an instruction is not itself a progression block.",
            "Literal table keys are checked; computed keys and runtime mutations may require separate review.",
            "Character witnesses may represent equivalence classes or unknown race/ID aliases, not playable combinations.",
            "Bounded symbolic analyses report unknown rather than claiming a contradiction when their budget is exhausted.",
        ],
    }


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--routes", type=Path, default=ROOT / "Routes/Forever")
    parser.add_argument("--json", type=Path, help="Write the complete machine-readable report")
    parser.add_argument("--limit", type=int, default=30, help="Maximum findings printed; JSON is never truncated")
    parser.add_argument("--fail-on-warning", action="store_true")
    args = parser.parse_args(argv)
    manifests = tuple(ROOT / f"Routes/RouteList_{client}.xml" for client in ("Camelot", "Standard"))
    report = audit_directory(args.routes, manifests=manifests if args.routes.resolve() == (ROOT / "Routes/Forever").resolve() else ())
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{report['files']} files, {report['routes']} routes; {report['summary'].get('error', 0)} errors, {report['summary'].get('warning', 0)} warnings")
    for item in report["findings"][:max(0, args.limit)]:
        print(f"{item['severity'].upper()} [{item['rule']}] {item.get('file', '')} {item['route']} {item['path']}: {item['message']}")
    if len(report["findings"]) > max(0, args.limit):
        print("Further findings omitted from console; use --json for the complete report.")
    print("Read-only audit; no route was repaired. Live-client completion is not certified.")
    return int(bool(report["summary"].get("error") or (args.fail_on_warning and report["summary"].get("warning"))))


if __name__ == "__main__":
    raise SystemExit(main())
