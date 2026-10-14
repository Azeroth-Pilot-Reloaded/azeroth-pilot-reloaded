"""Changelog rotation and remote-write safety, without network access."""

import contextlib
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / ".github/scripts"))
import archive_changelog as script


def release(version, body="- Notes"):
    return f"v{version} (2026-10-08)\n\n# Features\n{body}"


class MemoryAPI:
    def __init__(self, values):
        self.values = {locale: dict(value) for locale, value in values.items()}
        self.uploads = []

    def export(self, locale):
        return dict(self.values[locale])

    def upload(self, locale, values):
        self.uploads.append((locale, values))
        self.values[locale].update(values)


class ArchiveChangelogTests(unittest.TestCase):
    def test_prepends_with_blank_line_and_keeps_four_distinct_versions(self):
        before = {"New Changelog": release("6.8.0"), "Prev Changelog": "\n\n".join(
            release(version) for version in ("6.7.1", "6.7.0", "6.6.0", "6.5.0")
        )}
        after = script.archive_values(before)
        self.assertEqual(after["New Changelog"], "")
        self.assertEqual(after["Prev Changelog"], "\n\n".join(
            release(version) for version in ("6.8.0", "6.7.1", "6.7.0", "6.6.0")
        ))

    def test_retry_replaces_same_version_and_does_not_drop_extra_history(self):
        before = {"New Changelog": release("6.8.0", "- Updated translation"),
                  "Prev Changelog": "\n\n".join(release(v) for v in ("6.8.0", "6.7.1", "6.7.0", "6.6.0"))}
        after = script.archive_values(before)
        versions = script.split_versions(after["Prev Changelog"])
        self.assertEqual([v for v, _ in versions], ["6.8.0", "6.7.1", "6.7.0", "6.6.0"])
        self.assertIn("Updated translation", versions[0][1])
        self.assertIsNone(script.archive_values(after))

    def test_multiversion_new_changelog_and_localized_dates(self):
        after = script.archive_values({"New Changelog": "v6.8.0 (8 octobre 2026)\r\n- Réparations\r\n\r\nv6.7.1\r\n- Précédent",
                                       "Prev Changelog": release("6.7.0")})
        self.assertEqual([v for v, _ in script.split_versions(after["Prev Changelog"])], ["6.8.0", "6.7.1", "6.7.0"])
        self.assertNotIn("\r", after["Prev Changelog"])

    def test_missing_or_empty_new_does_not_touch_old_history(self):
        for values in ({}, {"Prev Changelog": "Unstructured old text"}, {"New Changelog": " \n"}):
            with self.subTest(values=values):
                self.assertIsNone(script.archive_values(values))
        self.assertEqual(script.archive_values({"New Changelog": release("6.8.0")})["Prev Changelog"], release("6.8.0"))

    def test_unknown_version_format_is_rejected_before_losing_history(self):
        for new, prev in (("Invalid", ""), (release("6.8.0"), "Old notes without headers")):
            with self.subTest(new=new, prev=prev), self.assertRaises(ValueError):
                script.archive_values({"New Changelog": new, "Prev Changelog": prev})

    def test_reads_quoted_long_and_commented_lua_without_false_entries(self):
        text = '''-- L["New Changelog"] = "wrong"
--[=[ L["New Changelog"] = "wrong" ]=]
L["Other"] = [==[
L["New Changelog"] = "also wrong"
]==]
L['New Changelog'] = "v6.8.0\\n- \\"Réparé\\" \\\\ \\195\\169"
L["Prev Changelog"] = [=[
v6.7.1
- 修复 ]]
]=]
'''
        self.assertEqual(script.parse_changelogs(text), {
            "New Changelog": 'v6.8.0\n- "Réparé" \\ é',
            "Prev Changelog": "v6.7.1\n- 修复 ]]\n",
        })

    def test_upload_strings_roundtrip_unicode_quotes_backslashes_and_controls(self):
        value = 'v6.8.0\n- "Réparé" \\ 中文 한국어\t\b\f\x01' + "2"
        self.assertEqual(script.parse_changelogs('L["New Changelog"] = ' + script.lua_quote(value)), {"New Changelog": value})

    def test_rejects_unterminated_duplicate_and_nonliteral_values(self):
        for text in ('L["New Changelog"] = "unterminated', 'L["New Changelog"] = [=[broken',
                     'L["New Changelog"] = true', 'L["New Changelog"] = "" .. "body"',
                     'L["New Changelog"] = "a"\nL["New Changelog"] = "b"'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                script.parse_changelogs(text)

    def test_api_contract_has_no_fallback_and_imports_only_requested_keys(self):
        with patch.object(script.requests, "Session") as session:
            api = script.CurseForge(618667, "test-token")
            session.return_value.get.return_value.text = 'L["New Changelog"] = ""'
            api.export("frFR")
            self.assertEqual(session.return_value.get.call_args.kwargs["params"]["unlocalized"], "Ignore")
            api.upload("frFR", {"Prev Changelog": release("6.8.0")})
            payload = session.return_value.post.call_args.kwargs["json"]
            self.assertEqual(payload["metadata"], {"language": "frFR", "formatType": "TableAdditions", "missing-phrase-handling": "DoNothing"})
            self.assertEqual(script.parse_changelogs(payload["localizations"]), {"Prev Changelog": release("6.8.0")})

    def test_archives_then_clears_and_updates_english_last(self):
        api = MemoryAPI({locale: {"New Changelog": release("6.8.0"), "Prev Changelog": release("6.7.1")}
                         for locale in ("enUS", "frFR")})
        with contextlib.redirect_stdout(io.StringIO()):
            plan = script.prepare(api, ["enUS", "frFR"])
            script.apply_plan(api, plan)
        self.assertEqual([(locale, list(values)) for locale, values in api.uploads], [
            ("frFR", ["Prev Changelog"]), ("frFR", ["New Changelog"]),
            ("enUS", ["Prev Changelog"]), ("enUS", ["New Changelog"]),
        ])
        self.assertEqual(api.values["frFR"], plan["frFR"]["after"])

    def test_stops_on_concurrent_edit_before_upload(self):
        api = MemoryAPI({"frFR": {"New Changelog": release("6.8.0")}})
        with contextlib.redirect_stdout(io.StringIO()):
            plan = script.prepare(api, ["frFR"])
        api.values["frFR"]["New Changelog"] += "\n- Translator's edit"
        with self.assertRaisesRegex(RuntimeError, "changed after export"):
            script.apply_plan(api, plan)
        self.assertEqual(api.uploads, [])

    def test_failed_archive_verification_never_clears_current(self):
        api = MemoryAPI({"frFR": {"New Changelog": release("6.8.0")}})
        with contextlib.redirect_stdout(io.StringIO()):
            plan = script.prepare(api, ["frFR"])
        api.upload = Mock()  # Simulate a successful HTTP response that ignored the import.
        with self.assertRaisesRegex(RuntimeError, "has not been cleared"):
            script.apply_plan(api, plan)
        self.assertEqual(api.upload.call_count, 1)
        self.assertEqual(list(api.upload.call_args.args[1]), ["Prev Changelog"])

    def test_rejects_ignored_clear_and_propagates_network_failure(self):
        for ignore_clear in (True, False):
            with self.subTest(ignore_clear=ignore_clear):
                api = MemoryAPI({"frFR": {"New Changelog": release("6.8.0")}})
                with contextlib.redirect_stdout(io.StringIO()):
                    plan = script.prepare(api, ["frFR"])
                upload = api.upload
                def interrupted_upload(locale, values):
                    if "New Changelog" in values:
                        if ignore_clear:
                            return
                        raise script.requests.Timeout("Connection interrupted")
                    upload(locale, values)
                api.upload = interrupted_upload
                with self.assertRaises((RuntimeError, script.requests.Timeout)):
                    script.apply_plan(api, plan)
                self.assertEqual(api.values["frFR"]["New Changelog"], release("6.8.0"))
                self.assertEqual(api.values["frFR"]["Prev Changelog"], release("6.8.0"))

    def test_cli_previews_by_default_and_writes_backup_before_first_upload(self):
        for apply in (False, True):
            with self.subTest(apply=apply), tempfile.TemporaryDirectory() as directory:
                api = MemoryAPI({"frFR": {"New Changelog": release("6.8.0")}})
                upload = api.upload
                def assert_backed_up(locale, values):
                    backup = json.loads(next(Path(directory).glob("*.json")).read_text(encoding="utf-8"))
                    self.assertEqual(backup["locales"]["frFR"]["before"]["New Changelog"], release("6.8.0"))
                    upload(locale, values)
                api.upload = assert_backed_up
                args = ["--locales", "frFR", "--backup-dir", directory] + (["--apply"] if apply else [])
                with patch.dict(os.environ, {"CF_API_KEY": "test-token"}), patch.object(script, "CurseForge", return_value=api), contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(script.main(args), 0)
                self.assertEqual(len(api.uploads), 2 if apply else 0)

    def test_all_locales_are_validated_before_any_upload(self):
        api = MemoryAPI({"enUS": {"New Changelog": release("6.8.0")}, "frFR": {"New Changelog": "Invalid"}})
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {"CF_API_KEY": "test-token"}), patch.object(script, "CurseForge", return_value=api), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(script.main(["--apply", "--locales", "enUS,frFR", "--backup-dir", directory]), 1)
        self.assertEqual(api.uploads, [])


if __name__ == "__main__":
    unittest.main()
