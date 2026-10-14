"""Changelog rotation and remote-write safety, without network access."""

import contextlib
from email.parser import BytesParser
from email.policy import default as email_policy
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

    def upload(self, locale, values, **_kwargs):
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
            call = session.return_value.post.call_args
            self.assertEqual(call.args[0], "https://legacy.curseforge.com/api/projects/618667/localization/import")
            self.assertNotIn("json", call.kwargs)
            parts = call.kwargs["files"]
            self.assertEqual(json.loads(parts["metadata"][1]), {"language": "frFR", "missing-phrase-handling": "DoNothing"})
            self.assertEqual(script.parse_changelogs(parts["localizations"][1]), {"Prev Changelog": release("6.8.0")})

    def test_real_prepared_request_is_multipart_with_correct_utf8_fields(self):
        value = release("6.8.0", '- Réparé "中文" \\ chemin')
        with patch.object(script.requests, "Session") as session:
            api = script.CurseForge(618667, "test-token")
            api.upload("deDE", {"Prev Changelog": value, "New Changelog": ""})
            call = session.return_value.post.call_args
            request = script.requests.Request("POST", call.args[0], files=call.kwargs["files"]).prepare()
        self.assertTrue(request.headers["Content-Type"].startswith("multipart/form-data; boundary="))
        message = BytesParser(policy=email_policy).parsebytes(
            ("Content-Type: " + request.headers["Content-Type"] + "\r\nMIME-Version: 1.0\r\n\r\n").encode("ascii") + request.body
        )
        parts = {part.get_param("name", header="content-disposition"): part.get_payload(decode=True).decode("utf-8") for part in message.iter_parts()}
        self.assertEqual(json.loads(parts["metadata"]), {"language": "deDE", "missing-phrase-handling": "DoNothing"})
        self.assertEqual(script.parse_changelogs(parts["localizations"]), {"Prev Changelog": value, "New Changelog": ""})

    def test_api_error_body_is_logged_with_token_redacted_and_length_limited(self):
        with patch.object(script.requests, "Session") as session:
            response = Mock(status_code=403, text="Invalid API token test-secret\n" + "x" * 5000)
            response.raise_for_status.side_effect = script.requests.HTTPError("rejected")
            session.return_value.post.return_value = response
            with self.assertLogs(script.LOG) as captured, self.assertRaises(script.requests.HTTPError):
                script.CurseForge(618667, "test-secret").upload("deDE", {"Prev Changelog": ""})
            logs = "\n".join(captured.output)
        self.assertIn("Invalid API token [REDACTED]", logs)
        self.assertNotIn("test-secret", logs)
        self.assertIn("[truncated]", logs)

    def test_exhausted_upload_is_reported_as_confirmed_not_applied(self):
        before = {"New Changelog": release("6.8.0")}
        with patch.object(script.requests, "Session") as session, patch.object(script.time, "sleep"):
            response = Mock(status_code=500, text='{"errorMessage":"Unhandled exception"}', headers={})
            response.raise_for_status.side_effect = script.requests.HTTPError("server failed")
            session.return_value.post.return_value = response
            api = script.CurseForge(618667, "test", retries=1)
            api.export = Mock(return_value=before)
            with self.assertLogs(script.LOG) as captured, self.assertRaises(script.UploadNotApplied):
                plan = script.prepare(api, ["deDE"])
                script.apply_plan(api, plan)
            self.assertEqual(plan["deDE"]["status"], "archive_not_applied")
            self.assertIn("fresh export confirmed both values unchanged", "\n".join(captured.output))

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
                def interrupted_upload(locale, values, **_kwargs):
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
                def assert_backed_up(locale, values, **_kwargs):
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

    def test_download_timeout_retries_with_backoff_and_visible_attempts(self):
        response = Mock(status_code=200, text='L["New Changelog"] = ""')
        with patch.object(script.requests, "Session") as session, patch.object(script.time, "sleep") as sleep:
            session.return_value.get.side_effect = [script.requests.ReadTimeout("slow"), script.requests.ConnectionError("offline"), response]
            api = script.CurseForge(618667, "secret", retries=3, timeout=75, retry_delay=2)
            with self.assertLogs(script.LOG, level="INFO") as captured:
                self.assertEqual(api.export("frFR"), {"New Changelog": ""})
            self.assertEqual(session.return_value.get.call_count, 3)
            self.assertEqual(session.return_value.get.call_args.kwargs["timeout"], (10, 75))
            self.assertEqual([call.args[0] for call in sleep.call_args_list], [2, 4])
            logs = "\n".join(captured.output)
            self.assertIn("[DOWNLOAD] frFR: attempt 1/4", logs)
            self.assertIn("attempt 3/4", logs)
            self.assertNotIn("secret", logs)

    def test_retries_transient_status_and_respects_numeric_retry_after(self):
        for status in (429, 500, 502, 503, 504):
            with self.subTest(status=status), patch.object(script.requests, "Session") as session, patch.object(script.time, "sleep") as sleep:
                failed = Mock(status_code=status, headers={"Retry-After": "7"})
                failed.raise_for_status.side_effect = script.requests.HTTPError("temporary")
                session.return_value.get.side_effect = [failed, Mock(status_code=200, text="")]
                with self.assertLogs(script.LOG):
                    self.assertEqual(script.CurseForge(618667, "test").export("frFR"), {})
                sleep.assert_called_once_with(7)

    def test_does_not_retry_authentication_or_validation_errors(self):
        for status in (400, 401, 403, 404):
            with self.subTest(status=status), patch.object(script.requests, "Session") as session, patch.object(script.time, "sleep") as sleep:
                session.return_value.post.return_value.status_code = status
                session.return_value.post.return_value.raise_for_status.side_effect = script.requests.HTTPError("rejected")
                with self.assertLogs(script.LOG), self.assertRaises(script.requests.HTTPError):
                    script.CurseForge(618667, "test").upload("frFR", {"New Changelog": ""})
                session.return_value.post.assert_called_once()
                session.return_value.get.assert_not_called()
                sleep.assert_not_called()

    def test_exhausted_download_retries_have_a_finite_limit(self):
        with patch.object(script.requests, "Session") as session, patch.object(script.time, "sleep") as sleep:
            session.return_value.get.side_effect = script.requests.ReadTimeout("slow")
            with self.assertLogs(script.LOG), self.assertRaises(script.requests.ReadTimeout):
                script.CurseForge(618667, "test", retries=2).export("frFR")
            self.assertEqual(session.return_value.get.call_count, 3)
            self.assertEqual(sleep.call_count, 2)

    def test_timed_out_post_already_applied_is_not_resent(self):
        before = {"New Changelog": release("6.8.0"), "Prev Changelog": release("6.7.1")}
        for values in ({"Prev Changelog": script.archive_values(before)["Prev Changelog"]}, {"New Changelog": ""}):
            with self.subTest(key=list(values)), patch.object(script.requests, "Session") as session, patch.object(script.time, "sleep") as sleep:
                api = script.CurseForge(618667, "test")
                api.export = Mock(return_value={**before, **values})
                session.return_value.post.side_effect = script.requests.ReadTimeout("response lost")
                with self.assertLogs(script.LOG) as logs:
                    api.upload("frFR", values, expected_before=before)
                session.return_value.post.assert_called_once()
                sleep.assert_not_called()
                self.assertIn("write confirmed by a fresh export", "\n".join(logs.output))

    def test_timed_out_post_not_applied_is_retried_with_identical_payload(self):
        before = {"New Changelog": release("6.8.0")}
        values = {"Prev Changelog": release("6.8.0")}
        with patch.object(script.requests, "Session") as session, patch.object(script.time, "sleep") as sleep:
            api = script.CurseForge(618667, "test")
            api.export = Mock(return_value=before)
            session.return_value.post.side_effect = [script.requests.ReadTimeout("not sent"), Mock(status_code=200)]
            with self.assertLogs(script.LOG):
                api.upload("frFR", values, expected_before=before)
            calls = session.return_value.post.call_args_list
            self.assertEqual(len(calls), 2)
            self.assertEqual(calls[0], calls[1])
            sleep.assert_called_once_with(2)

    def test_uncertain_post_never_resends_if_verification_fails_or_translator_edited(self):
        before = {"New Changelog": release("6.8.0")}
        for verification in (script.requests.ReadTimeout("verification failed"), {"New Changelog": release("6.9.0")}):
            with self.subTest(verification=verification), patch.object(script.requests, "Session") as session, patch.object(script.time, "sleep") as sleep:
                api = script.CurseForge(618667, "test")
                api.export = Mock(side_effect=verification) if isinstance(verification, Exception) else Mock(return_value=verification)
                session.return_value.post.side_effect = script.requests.ReadTimeout("unknown outcome")
                with self.assertLogs(script.LOG), self.assertRaises(RuntimeError):
                    api.upload("frFR", {"Prev Changelog": release("6.8.0")}, expected_before=before)
                session.return_value.post.assert_called_once()
                sleep.assert_not_called()

    def test_download_failure_saves_partial_progress_and_explicit_no_upload_summary(self):
        api = MemoryAPI({"enUS": {"New Changelog": release("6.8.0")}})
        export = api.export
        api.export = lambda locale: export(locale) if locale == "enUS" else (_ for _ in ()).throw(script.requests.ReadTimeout("slow"))
        output = io.StringIO()
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {"CF_API_KEY": "test"}), patch.object(script, "CurseForge", return_value=api), contextlib.redirect_stdout(output):
            self.assertEqual(script.main(["--apply", "--locales", "enUS,frFR,deDE", "--backup-dir", directory]), 1)
            backup = json.loads(next(Path(directory).glob("*.json")).read_text(encoding="utf-8"))
            self.assertEqual(backup["phase"], "download")
            self.assertEqual(backup["result"], "failed")
            self.assertEqual(backup["locales"]["enUS"]["status"], "planned")
            self.assertEqual(backup["locales"]["frFR"]["status"], "downloading")
            self.assertEqual(backup["locales"]["deDE"]["status"], "pending_download")
            logs = next(Path(directory).glob("*.log")).read_text(encoding="utf-8")
            self.assertIn("No uploads were started", logs)
            self.assertIn("[PLAN ONLY]", output.getvalue())
        self.assertEqual(api.uploads, [])

    def test_failure_after_clear_is_recorded_and_rerun_skips_completed_server_values(self):
        api = MemoryAPI({"frFR": {"New Changelog": release("6.8.0"), "Prev Changelog": release("6.7.1")}})
        export = api.export
        downloads = 0
        def fail_final_verification(locale):
            nonlocal downloads
            downloads += 1
            if downloads == 4:
                raise script.requests.ReadTimeout("final response lost")
            return export(locale)
        api.export = fail_final_verification
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {"CF_API_KEY": "test"}), patch.object(script, "CurseForge", return_value=api), contextlib.redirect_stdout(io.StringIO()):
            args = ["--apply", "--locales", "frFR", "--backup-dir", directory]
            self.assertEqual(script.main(args), 1)
            backup = json.loads(next(Path(directory).glob("*.json")).read_text(encoding="utf-8"))
            self.assertEqual(backup["locales"]["frFR"]["status"], "verifying_final")
            self.assertEqual(backup["result"], "failed")
            self.assertEqual(script.main(args), 0)
            self.assertEqual(len(api.uploads), 2)

    def test_interruption_is_logged_with_a_summary_and_saved_progress(self):
        api = Mock()
        api.export.side_effect = KeyboardInterrupt()
        output = io.StringIO()
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {"CF_API_KEY": "test"}), patch.object(script, "CurseForge", return_value=api), contextlib.redirect_stdout(output):
            self.assertEqual(script.main(["--apply", "--locales", "frFR", "--backup-dir", directory]), 130)
            backup = json.loads(next(Path(directory).glob("*.json")).read_text(encoding="utf-8"))
            self.assertEqual(backup["result"], "interrupted")
        self.assertIn("No uploads were started", output.getvalue())


if __name__ == "__main__":
    unittest.main()
