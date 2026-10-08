import sys
import json
import tempfile
import unittest
from contextlib import ExitStack
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import AsyncMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / ".github/scripts"))

import localization_post_discord as notification
from curseforge_localization_states_scrape import parse_language_counts


class LocalizationNotificationTests(unittest.TestCase):
    def test_unchanged_counts_wait_for_three_day_cooldown(self):
        previous = {
            "missing": 7,
            "review": 1,
            "last_ping": (datetime.now(timezone.utc) - timedelta(days=2)).isoformat(),
        }
        self.assertFalse(notification.should_ping(previous, 7, 1))

        previous["last_ping"] = (
            datetime.now(timezone.utc) - timedelta(days=3, minutes=1)
        ).isoformat()
        self.assertTrue(notification.should_ping(previous, 7, 1))

    def test_summary_and_detail_keep_both_counts(self):
        self.assertEqual(notification.build_summary_counts(7, 2), "7M/2R")
        detail = notification.build_need_text("frFR", 7, 2)
        self.assertIn("**7** traductions manquantes", detail)
        self.assertIn("**2** en relecture", detail)

    def test_phrase_page_counts_both_states(self):
        html = """
        <ul>
          <li data-target="phrase" data-phrase-id="1" class="needs-translation phrase"></li>
          <li data-target="phrase" data-phrase-id="2" class="needs-review phrase"></li>
          <li data-target="phrase" data-phrase-id="3" class="needs-review phrase"></li>
          <li data-target="phrase" data-phrase-id="4" class="has-translation phrase"></li>
        </ul>
        """
        self.assertEqual(parse_language_counts(html), {"missing": 1, "review": 2})


class LocalizationPreparationTests(unittest.TestCase):
    def setUp(self):
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        directory = Path(self.stack.enter_context(tempfile.TemporaryDirectory()))
        self.state_file = directory / "state.json"
        self.message_file = directory / "message.txt"
        self.initial_state = json.dumps({
            "frFR": {"missing": 1, "review": 1, "last_ping": "2020-01-01T00:00:00+00:00"},
        })
        self.state_file.write_text(self.initial_state, encoding="utf-8")
        self.stack.enter_context(patch.object(notification, "STATE_FILE", str(self.state_file)))
        self.stack.enter_context(patch.object(notification, "LOCALES_ENV", "frFR,deDE"))
        self.stack.enter_context(patch.object(notification, "fetch_localization_stats", return_value={
            "frFR": {"missing": 7}, "deDE": {"missing": 0},
        }))
        self.scrape = self.stack.enter_context(patch.object(
            notification, "fetch_localization_states", new_callable=AsyncMock,
        ))
        self.post = self.stack.enter_context(patch.object(notification, "post_to_discord"))

    def assert_nothing_prepared(self):
        self.assertEqual(self.state_file.read_text(encoding="utf-8"), self.initial_state)
        self.assertFalse(self.message_file.exists())
        self.post.assert_not_called()

    def test_missing_review_counts_fail_without_changing_state(self):
        for states in ({}, {"frFR": {"review": 2}, "deDE": {"state": "needs_review"}}):
            with self.subTest(states=states):
                self.scrape.return_value = states
                with self.assertRaisesRegex(RuntimeError, "could not be fetched.*deDE"):
                    notification.main(str(self.message_file))
                self.assert_nothing_prepared()

    def test_scraper_failure_preserves_state(self):
        self.scrape.side_effect = RuntimeError("Cloudflare challenge detected")
        with self.assertRaisesRegex(RuntimeError, "Cloudflare challenge"):
            notification.main(str(self.message_file))
        self.assert_nothing_prepared()

    def test_valid_counts_prepare_notification_and_persist_cooldown(self):
        self.scrape.return_value = {"frFR": {"review": 2}, "deDE": {"review": 0}}
        notification.main(str(self.message_file))

        message = self.message_file.read_text(encoding="utf-8")
        self.assertIn("7M/2R", message)
        self.assertIn("**7** traductions manquantes", message)
        self.assertIn("**2** en relecture", message)
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertEqual(state["frFR"]["missing"], 7)
        self.assertEqual(state["frFR"]["review"], 2)
        self.assertEqual(notification.days_since(state["frFR"]["last_ping"]), 0)
        self.post.assert_not_called()

        # A subsequent run during the cooldown must not prepare another ping.
        self.message_file.unlink()
        notification.main(str(self.message_file))
        self.assertFalse(self.message_file.exists())


if __name__ == "__main__":
    unittest.main()
