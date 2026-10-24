"""Localization reports and end-to-end PR comparison without remote writes."""

import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from urllib.parse import parse_qs, urlsplit

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / ".github/scripts"))
import check_translation_string as script


def finding(key="MISSING", *, code="missing_key", severity="error", line=1, is_new=True, **fields):
    return {
        "code": code, "severity": severity, "key": key, "path": "APR-Core/UI.lua",
        "line": line, "locale": "enUS", "message": f"Check {key}", "is_new": is_new, **fields,
    }


class LocalizationReportTests(unittest.TestCase):
    def render(self, diagnostics=(), coverage=(), **options):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "report.md"
            script.write_markdown_report(diagnostics, coverage, output, **options)
            return output.read_text(encoding="utf-8")

    def test_table_separates_new_and_existing_findings_and_collapses_locations(self):
        items = [
            finding("NEW"), finding("OLD", is_new=False),
            finding("RAW", code="raw_text", severity="warning", line=9),
        ]
        body = self.render(items, baseline_sha="a" * 40)
        summary, details = body.split("<details>")
        self.assertIn("| New warnings | Existing warnings | New errors | Existing errors |", summary)
        self.assertIn("| **Total** | **❌ Failed** | **1** | **0** | **1** | **1** |", summary)
        self.assertIn("Only new errors fail this PR", summary)
        self.assertNotIn("<code>NEW</code>", summary)
        self.assertIn("APR-Core/UI.lua:9", details)
        self.assertIn("❌ New errors (1)", details)
        self.assertIn("❌ Existing errors (1)", details)
        self.assertLess(details.index("<code>NEW</code>"), details.index("<code>OLD</code>"))
        self.assertTrue(body.endswith("</details>\n"))
        self.assertNotIn("<details open", body)

    def test_existing_errors_are_advisory_and_success_is_explicit(self):
        self.assertIn("**✅ Passed", self.render())
        self.assertNotIn("<details>", self.render())
        body = self.render([finding(is_new=False)], baseline_sha="abc")
        self.assertIn("**⚠️ Review", body)
        self.assertNotIn("**❌ Failed", body)

    def test_coverage_includes_percent_and_unavailable_locale(self):
        body = self.render(coverage=[
            {"locale": "frFR", "total": 100, "translated": 90, "missing": 10, "percent": 90.0},
            {"locale": "deDE", "unavailable": True},
        ])
        self.assertIn("| CurseForge | frFR | 90 | 100 | 90.0% | 10 |", body)
        self.assertIn("| CurseForge | deDE | — | — | ❌ Unavailable | — |", body)

    def test_keys_and_messages_cannot_close_details_or_inject_markdown(self):
        key = '</code></details>\n<!-- marker -->\n| forged | & "' + chr(96)
        body = self.render([finding(key, message=key)])
        self.assertEqual(body.count("</details>"), 1)
        self.assertNotIn("<!-- marker -->", body)
        self.assertIn("&lt;/code&gt;&lt;/details&gt;\\n", body)
        self.assertIn("&amp;", body)

    def test_large_report_keeps_all_group_totals_within_comment_budget(self):
        items = [
            finding(f"KEY_{index:05}_" + "翻译" * 80, line=index, is_new=is_new, severity=severity)
            for is_new in (True, False) for severity in ("error", "warning") for index in range(2000)
        ]
        body = self.render(items)
        self.assertLess(len(body.encode("utf-8")), 48_000)
        self.assertEqual(body.count("Showing "), 4)
        self.assertIn("JSON artifact and workflow logs", body)
        self.assertIn("| **Total** | **❌ Failed** | **2000** | **2000** | **2000** | **2000** |", body)
        self.assertEqual(body.count("</details>"), 1)

    def test_skip_and_technical_failure_do_not_claim_zero_findings(self):
        for option, status in (("skip_reason", "⏭️ Check skipped"),
                               ("error_reason", "❌ Check could not complete")):
            with self.subTest(option=option):
                body = self.render(**{option: "Export unavailable"})
                self.assertIn(status, body)
                self.assertIn("| — | — |", body)
                self.assertIn("Translation counts are unavailable", body)
                self.assertIn("Export unavailable", body.split("<details>")[1])
                self.assertNotIn("✅ Passed", body)

    def test_github_source_links_use_head_commit_and_encoded_file_path(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "APR-Core" / "My UI.lua"
            path.parent.mkdir()
            path.write_text("local x = 1", encoding="utf-8")
            with patch.dict(os.environ, {"GITHUB_REPOSITORY": "APR/addon", "GITHUB_SERVER_URL": "https://github.com"}):
                body = self.render([finding(path="APR-Core/My UI.lua", line=4)], root=directory, head_sha="abc123")
        self.assertIn("https://github.com/APR/addon/blob/abc123/APR-Core/My%20UI.lua#L4", body)


class DiagnosticComparisonTests(unittest.TestCase):
    def test_line_shifts_do_not_create_new_issues(self):
        result = script.classify_diagnostics([finding(line=20)], [finding(line=1)])
        self.assertFalse(result[0]["is_new"])

    def test_added_occurrence_of_existing_problem_is_new(self):
        result = script.classify_diagnostics([finding(line=1), finding(line=20)], [finding(line=1)])
        self.assertEqual([d["is_new"] for d in result], [False, True])

    def test_changed_key_file_or_locale_is_new(self):
        for changes in ({"key": "OTHER"}, {"path": "APR-Core/Other.lua"}, {"locale": "frFR"}):
            with self.subTest(changes=changes):
                result = script.classify_diagnostics([finding(**changes)], [finding()])
                self.assertTrue(result[0]["is_new"])

    def test_duplicates_are_counted_once_and_operational_errors_always_block(self):
        result = script.classify_diagnostics([finding(), finding()], [finding()])
        self.assertEqual(len(result), 1)
        self.assertFalse(result[0]["is_new"])
        item = finding(code="export_error", operational=True)
        self.assertTrue(script.classify_diagnostics([item], [item])[0]["is_new"])


class LocalizationCheckOutcomeTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        (self.root / "APR-Core").mkdir()
        (self.root / "Routes").mkdir()
        self.source = self.root / "APR-Core/UI.lua"
        self.source.write_text('local label = L["READY"]\n', encoding="utf-8")
        self.output = self.root / "report.md"
        self.json_output = self.root / "report.json"
        self.exports = {
            "enUS": 'L["READY"] = "Hello %s"\nL["UNUSED"] = "Unused"\nL["BAD"] = "Count %d"',
            "frFR": 'L["READY"] = "Bonjour %s"\nL["UNUSED"] = "Inutilisé"\nL["BAD"] = "Nombre %s"',
            "deDE": 'L["READY"] = "Hallo %s"\nL["UNUSED"] = "Unbenutzt"\nL["BAD"] = "Anzahl %d"',
        }
        self.fetch = patch.object(script, "fetch_translations_from_curseforge", side_effect=self.fetch_export).start()
        patch.dict(os.environ, {"CF_API_KEY": "token"}).start()
        self.stdout = patch("sys.stdout", new_callable=io.StringIO).start()
        self.addCleanup(patch.stopall)

    def fetch_export(self, url, token):
        self.assertEqual(token, "token")
        self.assertEqual(parse_qs(urlsplit(url).query)["unlocalized"], ["ShowBlankAsComment"])
        locale = parse_qs(urlsplit(url).query)["lang"][0]
        value = self.exports[locale]
        if isinstance(value, Exception):
            raise value
        return value

    def run_check(self, *args):
        status = script.main([
            "--root", str(self.root), "--skip-similarity-check", "--locales", "frFR,deDE",
            "--output", str(self.output), "--json-output", str(self.json_output), *args,
        ])
        return status, self.output.read_text(encoding="utf-8"), json.loads(self.json_output.read_text(encoding="utf-8"))

    def initialize_git(self):
        def run(*args):
            result = subprocess.run(["git", "-C", str(self.root), *args],
                                    capture_output=True, text=True, encoding="utf-8", timeout=20)
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout.strip()
        run("init", "-b", "codex/localization-test")
        self.git = run
        return self.commit("Base")

    def commit(self, message):
        self.git("add", "APR-Core", "Routes")
        self.git("-c", "user.name=Localization Tests", "-c", "user.email=tests@example.test",
                 "commit", "-m", message)
        return self.git("rev-parse", "HEAD")

    def test_only_errors_fail_completed_check_and_all_locales_are_reported(self):
        status, body, payload = self.run_check()
        self.assertEqual(status, 0)
        self.assertEqual({row["locale"] for row in payload["coverage"]}, {"enUS", "frFR", "deDE"})
        self.assertIn("⚠️ Review", body)
        self.source.write_text('local label = L["MISSING_CORE"]', encoding="utf-8")
        status, body, payload = self.run_check()
        self.assertEqual(status, 1)
        self.assertTrue(any(d["code"] == "missing_key" and d["key"] == "MISSING_CORE" for d in payload["diagnostics"]))
        self.assertIn("APR-Core/UI.lua:1", body)

    def test_note_lists_and_literal_core_keys_are_checked_end_to_end(self):
        (self.root / "Routes/Test.lua").write_text(
            "local x = { Note = {'NOTE_MISSING', {text='Go into the cave'}}, ExtraLineText3='EXTRA_MISSING' }",
            encoding="utf-8",
        )
        status, _, payload = self.run_check()
        self.assertEqual(status, 1)
        keys = {d["key"] for d in payload["diagnostics"] if d["code"] == "missing_key"}
        self.assertEqual(keys, {"NOTE_MISSING", "EXTRA_MISSING"})
        self.assertTrue(any(d["code"] == "raw_text" for d in payload["diagnostics"]))

    def test_used_bad_translation_fails_but_unused_bad_translation_does_not(self):
        self.assertEqual(self.run_check()[0], 0)
        self.source.write_text('local label = L["BAD"]', encoding="utf-8")
        status, _, payload = self.run_check()
        self.assertEqual(status, 1)
        self.assertTrue(any(d["code"] == "placeholder_mismatch" and d["locale"] == "frFR"
                            for d in payload["diagnostics"]))

    def test_route_templates_without_format_arguments_fail_in_scalar_and_list_fields(self):
        (self.root / "Routes/Test.lua").write_text(
            'local x = {\n Note = "READY",\n ExtraLineText = {"READY"},\n ExtraLineText2 = { {text="READY"} }\n}',
            encoding="utf-8",
        )
        status, body, payload = self.run_check()
        self.assertEqual(status, 1)
        errors = [d for d in payload["diagnostics"] if d["code"] == "unformatted_route_text"]
        self.assertEqual([(d["path"], d["line"], d["key"]) for d in errors],
                         [("Routes/Test.lua", line, "READY") for line in (2, 3, 4)])
        self.assertIn("Format parameters without route arguments", body)

    def test_route_literal_percent_and_date_formats_do_not_require_arguments(self):
        for locale in self.exports:
            self.exports[locale] += '\nL["PERCENT"] = "100% complete %%s"\nL["DATE"] = "%Y-%m-%d"'
        (self.root / "Routes/Test.lua").write_text(
            'local x = { Note = {"PERCENT", "DATE"} }', encoding="utf-8",
        )
        status, _, payload = self.run_check()
        self.assertEqual(status, 0)
        self.assertFalse(any(d["code"] == "unformatted_route_text" for d in payload["diagnostics"]))

    def test_locale_export_failure_preserves_available_results_and_blocks(self):
        self.exports["frFR"] = script.requests.HTTPError("sensitive-response")
        status, body, payload = self.run_check()
        self.assertEqual(status, 1)
        self.assertIn("| CurseForge | frFR | — | — | ❌ Unavailable | — |", body)
        self.assertIn("| CurseForge | deDE |", body)
        self.assertTrue(any(d["code"] == "export_error" and d["is_new"] for d in payload["diagnostics"]))
        self.assertNotIn("sensitive-response", body + self.stdout.getvalue() + json.dumps(payload))

    def test_untranslated_locale_is_a_blocking_translation_error_not_an_export_error(self):
        self.exports["frFR"] = '-- L["READY"] = ""\n-- L["UNUSED"] = ""\n-- L["BAD"] = ""'
        status, _, payload = self.run_check()
        self.assertEqual(status, 1)
        row = next(row for row in payload["coverage"] if row["locale"] == "frFR")
        self.assertEqual(row["percent"], 0)
        self.assertTrue(any(d["code"] == "missing_translation" and d["locale"] == "frFR"
                            for d in payload["diagnostics"]))
        self.assertTrue(any(d["code"] == "missing_translation" and d["severity"] == "error"
                            for d in payload["diagnostics"]))
        self.assertFalse(any(d["code"] == "export_error" for d in payload["diagnostics"]))

    def test_skip_writes_markdown_and_json_without_network(self):
        status, body, payload = self.run_check("--skip-reason", "Token unavailable on fork PR")
        self.assertEqual(status, 0)
        self.fetch.assert_not_called()
        self.assertIn("Check skipped", body)
        self.assertEqual(payload["status"], "skipped")
        self.assertIsNone(payload["totals"])

    def test_primary_export_error_replaces_stale_reports_without_secret_text(self):
        self.output.write_text("Old success", encoding="utf-8")
        self.exports["enUS"] = script.requests.HTTPError("sensitive-server-response")
        status, body, payload = self.run_check()
        self.assertEqual(status, 1)
        self.assertIn("Check could not complete", body)
        self.assertNotIn("Old success", body)
        self.assertNotIn("sensitive-server-response", body + self.stdout.getvalue())
        self.assertEqual(payload["status"], "incomplete")

    def test_missing_token_and_invalid_exports_do_not_claim_success(self):
        with patch.dict(os.environ, {"CF_API_KEY": ""}):
            self.assertEqual(self.run_check()[0], 1)
        self.fetch.assert_not_called()
        for export in ("", "   ", "<!DOCTYPE html><html>Unavailable</html>"):
            with self.subTest(export=export):
                self.exports["enUS"] = export
                status, body, payload = self.run_check()
                self.assertEqual(status, 1)
                self.assertIn("Check could not complete", body)
                self.assertEqual(payload["status"], "incomplete")

    def test_baseline_retains_existing_errors_and_blocks_only_new_ones(self):
        self.source.write_text('local label = L["OLD_MISSING"]\n', encoding="utf-8")
        base = self.initialize_git()
        self.source.write_text('\n\nlocal label = L["OLD_MISSING"]\n', encoding="utf-8")
        self.commit("Shift lines")
        status, body, payload = self.run_check("--base-ref", base)
        self.assertEqual(status, 0)
        self.assertEqual(payload["baseline_sha"], base)
        old = [d for d in payload["diagnostics"] if d["key"] == "OLD_MISSING"]
        self.assertEqual(len(old), 1)
        self.assertFalse(old[0]["is_new"])
        self.assertIn("Existing errors", body)
        self.source.write_text('local x = L["OLD_MISSING"]\nlocal y = L["NEW_MISSING"]\n', encoding="utf-8")
        self.commit("Introduce missing key")
        status, _, payload = self.run_check("--base-ref", base)
        self.assertEqual(status, 1)
        errors = {d["key"]: d["is_new"] for d in payload["diagnostics"] if d["code"] == "missing_key"}
        self.assertEqual(errors, {"OLD_MISSING": False, "NEW_MISSING": True})

    def test_baseline_detects_new_usage_of_existing_bad_translation(self):
        base = self.initialize_git()
        self.source.write_text('local x = L["READY"]\nlocal y = L["BAD"]\n', encoding="utf-8")
        self.commit("Use new key")
        status, _, payload = self.run_check("--base-ref", base)
        self.assertEqual(status, 1)
        self.assertTrue(any(d["code"] == "placeholder_mismatch" and d["is_new"] for d in payload["diagnostics"]))

    def test_newly_used_key_requires_a_translation_in_each_target_locale(self):
        self.exports["frFR"] = 'L["READY"] = "Bonjour %s"\nL["UNUSED"] = "Inutilisé"'
        base = self.initialize_git()
        self.source.write_text('local x = L["READY"]\nlocal y = L["BAD"]\n', encoding="utf-8")
        self.commit("Use untranslated key")
        status, _, payload = self.run_check("--base-ref", base)
        self.assertEqual(status, 1)
        self.assertTrue(any(d["code"] == "missing_translation" and d["key"] == "BAD"
                            and d["locale"] == "frFR" and d["is_new"] and d["severity"] == "error"
                            for d in payload["diagnostics"]))

    def test_new_hardcoded_fallback_blocks_even_if_the_key_is_translated(self):
        base = self.initialize_git()
        self.source.write_text('local label = L["READY"] or "Hardcoded English"\n', encoding="utf-8")
        self.commit("Introduce forbidden fallback")
        status, _, payload = self.run_check("--base-ref", base)
        self.assertEqual(status, 1)
        self.assertTrue(any(d["code"] == "hardcoded_fallback" and d["is_new"]
                            and d["severity"] == "error" for d in payload["diagnostics"]))

    def test_invalid_base_never_silently_disables_pr_comparison(self):
        self.initialize_git()
        status, body, payload = self.run_check("--base-ref", "missing-ref")
        self.assertEqual(status, 1)
        self.assertIn("Check could not complete", body)
        self.assertEqual(payload["status"], "incomplete")


class LocalizationUrlTests(unittest.TestCase):
    def test_export_options_and_locale_validation(self):
        url = script.set_localization_url(618667, "token", "https://wow.curseforge.com", locale="frFR",
                                         unlocalized="ShowBlankAsComment")
        self.assertEqual(url, "https://wow.curseforge.com/api/projects/618667/localization/export?"
                         "export-type=TableAdditions&lang=frFR&unlocalized=ShowBlankAsComment&table-name=L&"
                         "escape-non-ascii-characters=false&true-if-value-equals-key=false")
        self.assertEqual(script.locale_list("frFR,enUS,deDE,frFR"), ("frFR", "deDE"))
        with self.assertRaises(script.argparse.ArgumentTypeError):
            script.locale_list("bad")


if __name__ == "__main__":
    unittest.main()
