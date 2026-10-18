import sys
import unittest
from pathlib import Path
from unittest.mock import Mock, call, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / ".github/scripts"))

import curseforge_localization_fetch as fetch


class LocalizationExportTests(unittest.TestCase):
    def setUp(self):
        get_patch = patch.object(fetch.requests, "get")
        sleep_patch = patch.object(fetch.time, "sleep")
        self.get = get_patch.start()
        self.sleep = sleep_patch.start()
        self.addCleanup(get_patch.stop)
        self.addCleanup(sleep_patch.stop)
        self.url = fetch.set_localization_export_url(618667, "frFR")
        self.success = Mock(status_code=200, text='L["Key"] = "Translation"')

    def fetch(self):
        return fetch.fetch_localization_export(self.url, "test-secret")

    def test_success_does_not_retry(self):
        self.get.return_value = self.success
        self.assertEqual(self.fetch(), self.success.text)
        self.get.assert_called_once_with(
            self.url, headers={"X-Api-Token": "test-secret"}, timeout=(10, 30),
        )
        self.sleep.assert_not_called()

    def test_transient_network_errors_recover_with_backoff(self):
        self.get.side_effect = [
            fetch.requests.ReadTimeout("test-secret"),
            fetch.requests.ConnectionError("test-secret"),
            self.success,
        ]
        with self.assertLogs(fetch.LOG) as logs:
            self.assertEqual(self.fetch(), self.success.text)
        self.assertEqual(self.get.call_count, 3)
        self.assertEqual(self.sleep.call_args_list, [call(2), call(4)])
        self.assertIn("attempt 2/3", "\n".join(logs.output))
        self.assertNotIn("test-secret", "\n".join(logs.output))

    def test_temporary_http_errors_recover(self):
        for status in (429, 500, 502, 503, 504):
            with self.subTest(status=status):
                self.get.reset_mock()
                self.sleep.reset_mock()
                failed = Mock(status_code=status, headers={"Retry-After": "7"})
                failed.raise_for_status.side_effect = fetch.requests.HTTPError()
                self.get.side_effect = [failed, self.success]
                with self.assertLogs(fetch.LOG):
                    self.assertEqual(self.fetch(), self.success.text)
                self.assertEqual(self.get.call_count, 2)
                self.sleep.assert_called_once_with(7)

    def test_retry_after_is_bounded(self):
        failed = Mock(status_code=429, headers={"Retry-After": "3600"})
        failed.raise_for_status.side_effect = fetch.requests.HTTPError()
        self.get.side_effect = [failed, self.success]
        with self.assertLogs(fetch.LOG):
            self.fetch()
        self.sleep.assert_called_once_with(60)

    def test_permanent_http_errors_fail_immediately(self):
        for status in (400, 401, 403, 404):
            with self.subTest(status=status):
                self.get.reset_mock()
                self.get.return_value = Mock(status_code=status)
                self.get.return_value.raise_for_status.side_effect = fetch.requests.HTTPError()
                with self.assertRaises(fetch.requests.HTTPError):
                    self.fetch()
                self.get.assert_called_once()
                self.sleep.assert_not_called()

    def test_persistent_failure_stops_after_three_attempts(self):
        for error in (fetch.requests.ReadTimeout("offline"), fetch.requests.HTTPError("unavailable")):
            with self.subTest(error=type(error).__name__):
                self.get.reset_mock(side_effect=True)
                self.sleep.reset_mock()
                if isinstance(error, fetch.requests.HTTPError):
                    self.get.return_value = Mock(status_code=503, headers={})
                    self.get.return_value.raise_for_status.side_effect = error
                else:
                    self.get.side_effect = error
                with self.assertLogs(fetch.LOG), self.assertRaises(type(error)) as raised:
                    self.fetch()
                self.assertIs(raised.exception, error)
                self.assertEqual(self.get.call_count, 3)
                self.assertEqual(self.sleep.call_args_list, [call(2), call(4)])


if __name__ == "__main__":
    unittest.main()
