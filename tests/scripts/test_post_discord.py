import io
import os
import sys
import unittest
from pathlib import Path
from unittest.mock import Mock, call, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / ".github/scripts"))

import post_discord as notification


class ReleaseMessageTests(unittest.TestCase):
    def assert_valid_chunks(self, message, chunks, limit=2000):
        self.assertTrue(all(0 < len(chunk) <= limit for chunk in chunks))
        self.assertEqual(message.split(), " ".join(chunks).split())

    def test_short_message_and_exact_limit_remain_single_messages(self):
        for message in ("A short release note.", "x" * 2000):
            with self.subTest(length=len(message)):
                self.assertEqual(notification.split_message(message), [message])

    def test_empty_message_produces_no_posts(self):
        self.assertEqual(notification.split_message(" \n\t"), [])

    def test_paragraphs_are_kept_together(self):
        paragraphs = ["A" * 900, "B" * 900 + "\n" + "C" * 300]
        message = "\n\n".join(paragraphs)
        chunks = notification.split_message(message)
        self.assertEqual(chunks, paragraphs)
        self.assert_valid_chunks(message, chunks)

    def test_bullet_lines_and_changelog_link_are_preserved(self):
        lines = [f"* Fix {index}: " + "route " * 45 + "completed." for index in range(30)]
        lines.append("**Full Changelog**: [v1...v2](https://github.com/example/repo/compare/v1...v2)")
        message = "\n".join(lines)
        chunks = notification.split_message(message)
        self.assertGreater(len(chunks), 2)
        self.assert_valid_chunks(message, chunks)
        self.assertEqual([line for chunk in chunks for line in chunk.splitlines()], lines)

    def test_long_line_splits_between_complete_sentences(self):
        for ending in (".", "!", "?", "\u2026", '."', '!\u00bb', '.**'):
            with self.subTest(ending=ending):
                sentence = "Updated " + "quest " * 140 + "tracking" + ending
                message = " ".join([sentence] * 7)
                chunks = notification.split_message(message)
                self.assertGreater(len(chunks), 1)
                self.assert_valid_chunks(message, chunks)
                self.assertTrue(all(chunk.endswith(ending) for chunk in chunks))

    def test_periods_in_versions_and_urls_are_not_sentence_boundaries(self):
        sentence = "Update v1.2.3 at https://example.com/path. "
        message = sentence * 100
        chunks = notification.split_message(message)
        self.assert_valid_chunks(message, chunks)
        self.assertTrue(all(chunk.endswith("/path.") for chunk in chunks))

    def test_wrapped_prose_does_not_split_in_the_middle_of_a_sentence(self):
        sentences = ["A" * 900 + "\n" + "B" * 500 + ".", "C" * 600 + "\n" + "D" * 600 + "."]
        message = "\n".join(sentences)
        chunks = notification.split_message(message)
        self.assertEqual(chunks, sentences)
        self.assert_valid_chunks(message, chunks)

    def test_nested_bullet_indentation_survives_a_message_boundary(self):
        lines = ["* " + "a" * 1200, "  * " + "b" * 1200]
        self.assertEqual(notification.split_message("\n".join(lines)), lines)

    def test_sentence_exceeding_limit_splits_between_words(self):
        message = "word " * 600
        chunks = notification.split_message(message)
        self.assert_valid_chunks(message, chunks)
        self.assertTrue(all(word == "word" for chunk in chunks for word in chunk.split()))

    def test_single_token_exceeding_limit_is_not_lost(self):
        message = "x" * 4500
        chunks = notification.split_message(message)
        self.assertEqual([len(chunk) for chunk in chunks], [2000, 2000, 500])
        self.assertEqual("".join(chunks), message)

    def test_separator_immediately_after_limit_does_not_force_an_early_split(self):
        for separator in (" ", "\n", "\n\n"):
            message = "x" * 1999 + "." + separator + "Next sentence."
            with self.subTest(separator=separator):
                self.assertEqual(
                    notification.split_message(message),
                    ["x" * 1999 + ".", "Next sentence."],
                )

    def test_formatting_keeps_header_separate_and_rewrites_changelog(self):
        url = "https://github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded/compare/1.0...1.1"
        message = notification.format_release_notes(
            "1.1", f"Original title\n* Fixed routes.\n\n**Full Changelog**: {url}",
        )
        self.assertTrue(message.startswith(
            "## Patch Note - Version 1.1 <:apr:1271743726225719296>\n* Fixed routes.",
        ))
        self.assertNotIn("Original title", message)
        self.assertIn(f"**Full Changelog**: [1.0...1.1]({url})", message)


class ReleaseDeliveryTests(unittest.TestCase):
    def setUp(self):
        self.post = patch.object(notification.requests, "post").start()
        self.sleep = patch.object(notification.time, "sleep").start()
        patch("sys.stdout", new_callable=io.StringIO).start()
        self.addCleanup(patch.stopall)
        self.post.return_value = Mock(status_code=204, headers={})

    def test_pipeline_environment_sends_all_notes_in_order(self):
        body = "Original title\n" + "\n".join(
            f"* Fix {index}: " + "quest " * 60 + "completed." for index in range(30)
        )
        env = {
            "RELEASE_TAG": "1.1", "RELEASE_BODY": body,
            "DISCORD_WEBHOOK_URL": "https://example.invalid/webhook",
        }
        with (
            patch.dict(os.environ, env, clear=True),
            patch.object(notification, "load_dotenv"),
            patch.object(sys, "argv", ["post_discord.py"]),
        ):
            self.assertEqual(notification.main(), 0)
        payloads = [item.kwargs["json"] for item in self.post.call_args_list]
        self.assertGreater(len(payloads), 1)
        self.assertTrue(all(0 < len(payload["content"]) <= 2000 for payload in payloads))
        self.assertTrue(all(payload["flags"] == 4 for payload in payloads))
        expected = notification.format_release_notes("1.1", body)
        self.assertEqual(
            expected.splitlines(),
            [line for payload in payloads for line in payload["content"].splitlines()],
        )

    def test_rate_limit_retries_only_the_current_message(self):
        for headers in ({"Retry-After": "1.5"}, {}):
            with self.subTest(headers=headers):
                self.post.reset_mock()
                self.sleep.reset_mock()
                limited = Mock(status_code=429, headers=headers)
                limited.json.return_value = {"retry_after": 1.5}
                self.post.side_effect = [
                    Mock(status_code=204, headers={}), limited,
                    Mock(status_code=204, headers={}),
                ]
                notification.post_messages("webhook", ["First.", "Second."])
                self.assertEqual(
                    [item.kwargs["json"]["content"] for item in self.post.call_args_list],
                    ["First.", "Second.", "Second."],
                )
                self.sleep.assert_called_once_with(1.5)

    def test_exhausted_bucket_waits_before_next_message(self):
        headers = {"X-RateLimit-Remaining": "0", "X-RateLimit-Reset-After": "0.75"}
        self.post.side_effect = [
            Mock(status_code=204, headers=headers), Mock(status_code=200, headers=headers),
        ]
        notification.post_messages("webhook", ["First.", "Second."])
        self.sleep.assert_called_once_with(0.75)

    def test_repeated_rate_limits_eventually_fail(self):
        self.post.return_value = Mock(
            status_code=429, headers={"Retry-After": "1"}, text="Too many requests",
        )
        with self.assertRaisesRegex(RuntimeError, "message 1/2.*429"):
            notification.post_messages("webhook", ["First.", "Second."])
        self.assertEqual(self.post.call_count, 4)
        self.assertEqual(self.sleep.call_args_list, [call(1.0)] * 3)

    def test_failed_message_stops_subsequent_posts(self):
        self.post.side_effect = [
            Mock(status_code=204, headers={}), Mock(status_code=400, text="Invalid body"),
        ]
        with self.assertRaisesRegex(RuntimeError, "message 2/3.*400"):
            notification.post_messages("webhook", ["First.", "Second.", "Third."])
        self.assertEqual(self.post.call_count, 2)


if __name__ == "__main__":
    unittest.main()
