"""Regression tests for the alpha publication cooldown."""

from datetime import datetime, timedelta, timezone
import importlib.util
from pathlib import Path
import unittest
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[2] / ".github/scripts/alpha_release.py"
SPEC = importlib.util.spec_from_file_location("alpha_release", SCRIPT)
alpha = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(alpha)
NOW = datetime(2026, 10, 19, 12, tzinfo=timezone.utc)


def run(run_id=1, sha="previous", updated=NOW):
    return {"id": run_id, "head_sha": sha, "updated_at": updated.isoformat()}


def job(age=timedelta(minutes=30), conclusion="success", name=alpha.PACKAGER_STEP):
    return {"steps": [{
        "name": name,
        "conclusion": conclusion,
        "completed_at": (NOW - age).isoformat(),
    }]}


class AlphaReleaseTests(unittest.TestCase):
    def decide(self, runs=(), jobs=(), **kwargs):
        with mock.patch.object(alpha, "pages", side_effect=lambda path, key, **params:
                               iter(runs if key == "workflow_runs" else jobs)):
            return alpha.decision("current", "push", NOW, **kwargs)[0]

    def test_first_publication_is_allowed(self):
        self.assertTrue(self.decide())

    def test_recent_publication_blocks_another_commit(self):
        self.assertFalse(self.decide([run()], [job()]))

    def test_exactly_one_hour_allows_publication(self):
        self.assertTrue(self.decide([run()], [job(age=timedelta(hours=1))]))

    def test_already_published_commit_is_not_republished_even_days_later(self):
        self.assertFalse(self.decide(
            [run(sha="current", updated=NOW - timedelta(days=3))],
            [job(age=timedelta(days=3))],
        ))

    def test_skipped_failed_and_tag_packagers_do_not_start_cooldown(self):
        for previous in [job(conclusion="skipped"), job(conclusion="failure"),
                         job(name="WoW Packager")]:
            with self.subTest(previous=previous):
                self.assertTrue(self.decide([run()], [previous]))

    def test_manual_release_bypasses_history(self):
        with mock.patch.object(alpha, "pages") as history:
            self.assertTrue(alpha.decision("current", "workflow_dispatch", NOW)[0])
            history.assert_not_called()

    def test_tagged_commit_cannot_be_uploaded_by_alpha_job(self):
        for event in ["push", "schedule", "workflow_dispatch"]:
            with self.subTest(event=event):
                self.assertFalse(alpha.decision("current", event, NOW, tagged=True)[0])

    def test_scheduled_automation_commit_is_ignored(self):
        self.assertFalse(alpha.decision("current", "schedule", NOW, automated=True)[0])

    def test_schedule_catches_up_after_cooldown(self):
        with mock.patch.object(alpha, "pages", return_value=iter(())):
            self.assertTrue(alpha.decision("current", "schedule", NOW)[0])

    def test_old_run_recently_rerun_starts_cooldown(self):
        previous = run()
        previous["created_at"] = (NOW - timedelta(days=30)).isoformat()
        self.assertFalse(self.decide([previous], [job()]))

    def test_history_checks_earlier_attempts_and_other_branches(self):
        with mock.patch.object(alpha, "pages", side_effect=[
            iter([run()]), iter([job(conclusion="skipped"), job()]),
        ]) as history:
            self.assertFalse(alpha.decision("current", "push", NOW)[0])
            history.assert_any_call("actions/runs/1/jobs", "jobs", filter="all")

    def test_pagination_reads_beyond_first_hundred_runs(self):
        with mock.patch.object(alpha, "api", side_effect=[
            {"workflow_runs": [run(i) for i in range(100)]},
            {"workflow_runs": [run(100)]},
        ]) as api:
            self.assertEqual(101, len(list(alpha.pages("runs", "workflow_runs"))))
            self.assertEqual(2, api.call_args.kwargs["page"])

    def test_api_failure_does_not_allow_publication(self):
        with mock.patch.object(alpha, "pages", side_effect=RuntimeError("API unavailable")):
            with self.assertRaisesRegex(RuntimeError, "API unavailable"):
                alpha.decision("current", "push", NOW)


if __name__ == "__main__":
    unittest.main()
