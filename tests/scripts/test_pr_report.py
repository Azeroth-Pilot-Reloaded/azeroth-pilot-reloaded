"""Exercise the actual workflow comment script against a mocked GitHub API."""

import json
from pathlib import Path
import subprocess
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/test-report.yml"
DRIVER = r"""
const fs = require('node:fs');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const calls = [];
const run = {
  id: 100, head_sha: 'abc123', head_branch: 'feature', head_repository: {id: 42},
  conclusion: 'success', html_url: 'https://example.test/runs/100', pull_requests: [{number: 7}],
  ...input.run
};
const pr = {
  number: 7, state: 'open', draft: false,
  head: {sha: run.head_sha, ref: run.head_branch, repo: {id: 42}}, ...input.pr
};
const jobs = ['scripts', 'lua', 'routes'].map(suite => ({
  name: `Tests / ${suite}`, conclusion: 'success', html_url: `https://example.test/jobs/${suite}`
}));
const github = {
  rest: {
    repos: {listPullRequestsAssociatedWithCommit: 'associated'},
    actions: {listJobsForWorkflowRun: 'jobs'},
    pulls: {get: async args => {calls.push(['pull', args]); return {data: pr};}},
    issues: {
      listComments: 'comments',
      createComment: async args => calls.push(['create', args]),
      updateComment: async args => calls.push(['update', args])
    }
  },
  paginate: async (method, args) => {
    calls.push([method, args]);
    if (method === 'associated') return [{number: 7}];
    if (method === 'jobs') return input.jobs ?? jobs;
    if (method === 'comments') return input.comments ?? [];
    throw Error(`Unexpected API: ${method}`);
  }
};
const context = {repo: {owner: 'APR', repo: 'addon'}, payload: {workflow_run: run}};
const AsyncFunction = Object.getPrototypeOf(async function() {}).constructor;
new AsyncFunction('github', 'context', input.script)(github, context)
  .then(() => process.stdout.write(JSON.stringify(calls)))
  .catch(error => {console.error(error); process.exitCode = 1;});
"""


class PrReportTests(unittest.TestCase):
    def run_report(self, **scenario):
        script = textwrap.dedent(WORKFLOW.read_text(encoding="utf-8").split("script: |\n", 1)[1])
        result = subprocess.run(
            ["node", "-e", DRIVER], input=json.dumps({"script": script, **scenario}),
            capture_output=True, text=True, encoding="utf-8", timeout=20,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def mutations(self, calls):
        return [call for call in calls if call[0] in {"create", "update"}]

    def test_creates_report_with_all_suites_and_commit(self):
        calls = self.mutations(self.run_report())
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][0], "create")
        self.assertEqual(calls[0][1]["issue_number"], 7)
        body = calls[0][1]["body"]
        for text in ("abc123", "Scripts Python", "Régressions Lua", "Syntaxe de toutes les routes"):
            self.assertIn(text, body)

    def test_updates_own_comment_without_touching_other_comments(self):
        calls = self.mutations(self.run_report(comments=[
            {"id": 8, "user": {"login": "contributor"}, "body": "<!-- apr-pr-tests -->"},
            {"id": 9, "user": {"login": "github-actions[bot]"}, "body": "<!-- apr-pr-tests -->"},
        ]))
        self.assertEqual(calls[0][0], "update")
        self.assertEqual(calls[0][1]["comment_id"], 9)
        self.assertEqual(len(calls), 1)

    def test_finds_fork_pr_when_event_has_no_pull_requests(self):
        calls = self.run_report(run={"pull_requests": []})
        self.assertIn("associated", [call[0] for call in calls])
        self.assertEqual(len(self.mutations(calls)), 1)

    def test_ignores_draft_and_closed_prs(self):
        for pr in ({"draft": True}, {"state": "closed"}):
            with self.subTest(pr=pr):
                self.assertEqual(self.mutations(self.run_report(pr=pr)), [])

    def test_ignores_old_commits_and_unrelated_branches_or_repositories(self):
        for head in (
            {"sha": "new", "ref": "feature", "repo": {"id": 42}},
            {"sha": "abc123", "ref": "other", "repo": {"id": 42}},
            {"sha": "abc123", "ref": "feature", "repo": {"id": 99}},
        ):
            with self.subTest(head=head):
                self.assertEqual(self.mutations(self.run_report(pr={"head": head})), [])

    def test_old_run_cannot_overwrite_newer_report_for_same_commit(self):
        calls = self.run_report(comments=[{
            "id": 9, "user": {"login": "github-actions[bot]"},
            "body": "<!-- apr-pr-tests -->\n<!-- apr-pr-tests-run: 101 -->",
        }])
        self.assertEqual(self.mutations(calls), [])

    def test_failure_and_missing_suites_are_visible(self):
        calls = self.mutations(self.run_report(run={"conclusion": "failure"}, jobs=[{
            "name": "Tests / lua", "conclusion": "failure", "html_url": "https://example.test/job",
        }]))
        body = calls[0][1]["body"]
        self.assertIn("❌ Échec", body)
        self.assertIn("⚠️ Résultat absent", body)
