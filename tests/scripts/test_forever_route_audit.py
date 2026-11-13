"""Audit orchestration uses temporary, invented routes and never repairs inputs."""
from pathlib import Path
import tempfile
import unittest

from tools.validation.audit_forever_routes import audit_directory, manifest_findings, merge_overlapping_checks


def declaration(key, body="{ RouteCompleted = true }"):
    return f'APR.RouteQuestStepList["{key}"] = {{ label = "Invented {key}", steps = {{ {body} }} }}'


class ForeverAuditTests(unittest.TestCase):
    def audit(self, directory, analyzers=()):
        return audit_directory(directory, analyzers=analyzers, source_auditor=lambda paths: [])

    def test_file_failure_does_not_hide_other_routes_or_modify_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "bad.lua").write_text("this is not Lua", encoding="utf-8")
            (root / "good.lua").write_text(declaration("invented"), encoding="utf-8")
            before = {p.name: p.read_bytes() for p in root.iterdir()}
            report = self.audit(root)
            self.assertEqual(report["files"], 2)
            self.assertEqual(report["routes"], 1)
            self.assertEqual(report["semantic_routes"], 1)
            self.assertEqual(len(report["failed_files"]), 1)
            self.assertIn("route_load", report["rules"])
            self.assertEqual(before, {p.name: p.read_bytes() for p in root.iterdir()})

    def test_duplicate_route_keys_across_files_are_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("one", "two"):
                (root / (name + ".lua")).write_text(declaration("duplicate"), encoding="utf-8")
            report = self.audit(root)
            self.assertEqual(report["rules"]["duplicate_route_key"], 1)
            finding = next(f for f in report["findings"] if f["rule"] == "duplicate_route_key")
            self.assertNotEqual(finding["file"], finding["evidence"]["other_file"])

    def test_invalid_schema_is_excluded_from_semantic_analysis(self):
        observed = []
        def structural(catalog):
            observed.append(set(catalog.routes))
            return []
        def semantic(catalog):
            observed.append(set(catalog.routes))
            return []
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "valid.lua").write_text(declaration("valid"), encoding="utf-8")
            (root / "invalid.lua").write_text(declaration("invalid", "{ Faction = 'Nobody' }"), encoding="utf-8")
            report = self.audit(root, (structural, semantic))
            self.assertEqual(observed, [{"valid", "invalid"}, {"valid"}])
            self.assertEqual(report["skipped_invalid_routes"], ["invalid"])
            self.assertEqual(report["summary"]["error"], 1)

    def test_empty_input_is_not_a_success(self):
        with tempfile.TemporaryDirectory() as directory:
            report = self.audit(directory)
            self.assertEqual(report["rules"]["no_route_sources"], 1)

    def test_identical_findings_are_deduplicated_but_distinct_witnesses_survive(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "guide.lua").write_text(declaration("invented"), encoding="utf-8")
            base = dict(severity="warning", rule="invented_rule", route="invented", path="steps[1]", message="Review")
            def analyzer(catalog):
                return [base, dict(base), {**base, "evidence": {"witness": {"Faction": "Horde"}}}]
            report = self.audit(root, (analyzer,))
            self.assertEqual(report["summary"], {"warning": 2})
            self.assertTrue(all(f["file"].endswith("guide.lua") for f in report["findings"]))

    def test_registration_checks_discovered_sources_only(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "guide.lua"
            source.write_text(declaration("invented"), encoding="utf-8")
            manifest = root / "files.xml"
            manifest.write_text(f'<Ui><Script file="{source.as_posix()}"/></Ui>', encoding="utf-8")
            self.assertEqual(manifest_findings([source], [manifest]), [])
            duplicate = root / "duplicate.xml"
            duplicate.write_bytes(manifest.read_bytes())
            self.assertEqual(manifest_findings([source], [manifest, duplicate])[0]["rule"], "manifest_registration")
            self.assertEqual(manifest_findings([source], [])[0]["rule"], "manifest_registration")

    def test_overlapping_checks_keep_evidence_without_duplicate_issues(self):
        base = dict(route="invented", file="fixture.lua", path="steps[2]", message="Review")
        primary = {**base, "severity": "error", "rule": "guard.step-contradiction"}
        repeated = {**base, "severity": "warning", "rule": "progression.impossible-filter", "evidence": {"filters": {"MinLevel": 15}}}
        terminal = {**base, "path": "steps", "severity": "warning", "rule": "progression.conditional-terminal",
                    "evidence": {"terminalPaths": ["steps[3]"]}}
        structural = {**base, "path": "steps[3]", "severity": "warning", "rule": "conditional-route-completion"}
        result = merge_overlapping_checks([repeated, primary, structural, terminal])
        self.assertEqual(len(result), 2)
        self.assertEqual(primary["evidence"]["supporting_checks"][0]["evidence"]["filters"]["MinLevel"], 15)
        self.assertEqual(terminal["evidence"]["supporting_checks"][0]["path"], "steps[3]")

    def test_only_proved_completion_coverage_suppresses_structural_hint(self):
        hint = dict(severity="warning", rule="conditional-route-completion", route="invented",
                    path="steps[3]", message="Review", file="fixture.lua")
        self.assertEqual(merge_overlapping_checks([hint], {"invented": "unsatisfiable"}), [])
        for status in ("unknown", "satisfiable"):
            self.assertEqual(merge_overlapping_checks([hint], {"invented": status}), [hint])
