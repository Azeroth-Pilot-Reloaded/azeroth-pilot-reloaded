import sys
import unittest
from pathlib import Path
from unittest.mock import call, create_autospec, patch

from pydoll import Chrome, Tab
from pydoll.exceptions import WebSocketConnectionClosed

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / ".github/scripts"))

import curseforge_localization_states_scrape as scraper


OVERVIEW_HTML = """
<div class="language-state">
  <h2>Needs Translation</h2>
  <div class="language-box">
    <p>French</p><p>90%</p><a href="/localization/frFR">French</a>
  </div>
  <div class="language-box">
    <p>German</p><p>90%</p>
    <a href="https://www.curseforge.com/localization/deDE">German</a>
  </div>
</div>
"""
PHRASES_HTML = """
<ul>
  <li data-target="phrase" data-phrase-id="1" class="needs-translation"></li>
  <li data-target="phrase" data-phrase-id="2" class="needs-review"></li>
  <li data-target="phrase" data-phrase-id="3" class="needs-review"></li>
</ul>
"""


class LocalizationScraperTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        # Spec against the installed API so removed methods cannot pass tests.
        self.tab = create_autospec(Tab, instance=True, spec_set=True)
        self.browser = create_autospec(Chrome, instance=True, spec_set=True)
        self.browser.start.return_value = self.tab
        self.tab.query.return_value = object()
        self.tab.page_source.side_effect = [OVERVIEW_HTML, PHRASES_HTML, PHRASES_HTML]
        chrome = patch.object(scraper, "Chrome", return_value=self.browser)
        chrome.start()
        self.addCleanup(chrome.stop)

    async def test_counts_both_states_using_current_browser_api(self):
        result = await scraper.fetch_localization_states(["frFR", "deDE"])

        for locale in ("frFR", "deDE"):
            self.assertEqual(result[locale]["missing"], 1)
            self.assertEqual(result[locale]["review"], 2)
        self.assertEqual(self.tab.go_to.await_args_list, [
            call(scraper.LOCALIZATION_URL, timeout=60),
            call("https://www.curseforge.com/localization/frFR", timeout=60),
            call("https://www.curseforge.com/localization/deDE", timeout=60),
        ])
        turnstile = self.tab.expect_cloudflare_turnstile.return_value
        self.assertEqual(turnstile.__aenter__.await_count, 3)
        self.assertEqual(turnstile.__aexit__.await_count, 3)
        self.tab.close.assert_awaited_once()
        self.browser.stop.assert_awaited_once()

    async def test_blocked_or_changed_overview_is_an_error(self):
        for html, found, message in (
            ("<title>Just a moment...</title>", None, "Cloudflare challenge"),
            ("<html></html>", None, "Localization blocks not found"),
            ('<div class="language-state"></div>', object(), "No localization states"),
        ):
            with self.subTest(message=message):
                self.tab.query.return_value = found
                self.tab.page_source.side_effect = [html]
                with self.assertRaisesRegex(RuntimeError, message):
                    await scraper.fetch_localization_states(["frFR"])
        self.assertEqual(self.tab.close.await_count, 3)
        self.assertEqual(self.browser.stop.await_count, 3)

    async def test_missing_locale_page_is_an_error(self):
        with self.assertRaisesRegex(RuntimeError, "page link not found for ruRU"):
            await scraper.fetch_localization_states(["ruRU"])

    async def test_missing_phrases_are_not_counted_as_zero(self):
        self.tab.query.side_effect = [object(), None]
        with self.assertRaisesRegex(RuntimeError, "phrases not found for frFR"):
            await scraper.fetch_localization_states(["frFR"])
        self.tab.close.assert_awaited_once()
        self.browser.stop.assert_awaited_once()

    async def test_connection_error_survives_cleanup_errors(self):
        error = WebSocketConnectionClosed("The WebSocket connection is closed")
        self.tab.go_to.side_effect = error
        self.tab.close.side_effect = error
        self.browser.stop.side_effect = error

        with self.assertRaisesRegex(RuntimeError, "WebSocket connection is closed") as raised:
            await scraper.fetch_localization_states(["frFR"])

        self.assertIs(raised.exception.__cause__, error)
        self.tab.close.assert_awaited_once()
        self.browser.stop.assert_awaited_once()
        self.browser.close.assert_awaited_once()

    async def test_browser_start_error_is_reported(self):
        self.browser.start.side_effect = RuntimeError("Chrome failed to start")
        with self.assertRaisesRegex(RuntimeError, "Chrome failed to start"):
            await scraper.fetch_localization_states(["frFR"])
        self.tab.close.assert_not_awaited()
        self.browser.stop.assert_awaited_once()

    def test_browser_keeps_its_native_user_agent(self):
        options = scraper.build_browser_options()
        self.assertTrue(options.headless)
        self.assertFalse(any(arg.startswith("--user-agent=") for arg in options.arguments))


if __name__ == "__main__":
    unittest.main()
