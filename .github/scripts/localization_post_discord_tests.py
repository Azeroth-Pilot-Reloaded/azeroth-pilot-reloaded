import sys
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

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


if __name__ == "__main__":
    unittest.main()
