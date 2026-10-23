"""Exercise the trusted localization workflow script without GitHub or artifacts."""

import json
from pathlib import Path
import subprocess
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/localization-report.yml"
MARKER = "<!-- apr-localization-report -->"
TITLE = "## 🌍 Localization check report"
DRIVER = r"""
const fs = require('node:fs');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const calls = [];
const run = {
  id: 100, run_attempt: 1, workflow_id: 55, event: 'pull_request',
  path: '.github/workflows/check_translations.yml', status: 'completed', conclusion: 'success',
  head_sha: 'abc123', head_branch: 'feature', head_repository: {id: 42},
  pull_requests: [{number: 7}], ...input.run
};
const pr = {
  number: 7, state: 'open',
  head: {sha: run.head_sha, ref: run.head_branch, repo: {id: 42}}, ...input.pr
};
let runChecks = 0;
let prChecks = 0;
const github = {
  rest: {
    actions: {
      getWorkflowRun: async args => {
        calls.push(['run', args]);
        const changes = input.latest_sequence?.[runChecks++] ?? input.latest ?? {};
        return {data: {...run, ...changes}};
      },
      listWorkflowRuns: 'runs'
    },
    repos: {listPullRequestsAssociatedWithCommit: 'associated'},
    pulls: {get: async args => {
      calls.push(['pull', args]);
      const changes = input.pr_sequence?.[prChecks++] ?? {};
      return {data: {...pr, ...changes}};
    }},
    issues: {
      listComments: 'comments',
      createComment: async args => calls.push(['create', args]),
      updateComment: async args => calls.push(['update', args])
    }
  },
  paginate: async (method, args) => {
    calls.push([method, args]);
    if (method === 'runs') return (input.runs ?? [run]).map(other => ({...run, ...other}));
    if (method === 'associated') return [{number: 7}];
    if (method === 'comments') return input.comments ?? [];
    throw Error(`Unexpected API: ${method}`);
  }
};
const defaultReport = '## 🌍 Localization check report\n\n| Check | Result | Warnings | Errors |\n' +
  '| --- | --- | ---: | ---: |\n| Translation coverage | ✅ Passed | 0 | 0 |';
const fileContent = input.body ?? defaultReport;
const artifactFs = {
  lstatSync: file => {
    calls.push(['stat', file]);
    if (file !== '/runner/temp/localization-report/translation-report.md') throw Error('Unexpected path');
    if (input.missing_file) throw Error('ENOENT');
    return {isFile: () => !input.not_a_file, size: input.size ?? Buffer.byteLength(fileContent)};
  },
  readFileSync: (file, encoding) => {
    calls.push(['read', file, encoding]);
    return fileContent;
  }
};
const mockRequire = name => name === 'node:fs' ? artifactFs :
  name === 'node:path' ? require(name).posix : require(name);
const context = {repo: {owner: 'APR', repo: 'addon'}, payload: {workflow_run: run}};
const core = {warning: message => calls.push(['warning', message])};
const mockProcess = {env: {
  RUNNER_TEMP: '/runner/temp', GITHUB_SERVER_URL: 'https://github.example',
  REPORT_DOWNLOAD_OUTCOME: input.download_outcome ?? 'success'
}};
const AsyncFunction = Object.getPrototypeOf(async function() {}).constructor;
new AsyncFunction('require', 'github', 'context', 'core', 'process', input.script)(
  mockRequire, github, context, core, mockProcess
).then(() => process.stdout.write(JSON.stringify(calls)))
 .catch(error => {console.error(error); process.exitCode = 1;});
"""


class LocalizationPrReportTests(unittest.TestCase):
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

    def bot_comment(self, comment_id, body):
        return {"id": comment_id, "user": {"login": "github-actions[bot]"}, "body": body}

    def test_creates_report_with_trusted_identity_and_log_link(self):
        changes = self.mutations(self.run_report())
        self.assertEqual(len(changes), 1)
        kind, args = changes[0]
        self.assertEqual(kind, "create")
        self.assertEqual(args["issue_number"], 7)
        body = args["body"]
        self.assertTrue(body.startswith(MARKER + "\n<!-- apr-localization-run: 100; attempt: 1 -->\n"))
        self.assertIn(TITLE, body)
        self.assertIn("| Translation coverage | ✅ Passed | 0 | 0 |", body)
        self.assertIn("`abc123`", body)
        self.assertIn("https://github.example/APR/addon/actions/runs/100/attempts/1", body)

    def test_updates_marker_comment_even_after_human_or_unrelated_bot_comments(self):
        calls = self.run_report(comments=[
            {"id": 8, "user": {"login": "contributor"}, "body": MARKER},
            self.bot_comment(9, MARKER + "\nold report"),
            self.bot_comment(10, "A different CI report"),
            {"id": 11, "user": {"login": "contributor"}, "body": "Please review"},
        ])
        self.assertEqual([(kind, args["comment_id"]) for kind, args in self.mutations(calls)], [("update", 9)])
        comment_request = next(call[1] for call in calls if call[0] == "comments")
        self.assertEqual(comment_request["per_page"], 100)

    def test_migrates_latest_legacy_report_without_creating_a_third_comment(self):
        calls = self.run_report(comments=[
            self.bot_comment(6364114785, TITLE + "\n\nlatest old report"),
            self.bot_comment(6363038621, TITLE + "\n\nearlier old report"),
            {"id": 7000000000, "user": {"login": "contributor"}, "body": TITLE + "\nuser text"},
        ])
        changes = self.mutations(calls)
        self.assertEqual(len(changes), 1)
        self.assertEqual(changes[0][0], "update")
        self.assertEqual(changes[0][1]["comment_id"], 6364114785)
        self.assertTrue(changes[0][1]["body"].startswith(MARKER))

    def test_prefers_existing_marker_to_newer_legacy_comment(self):
        calls = self.run_report(comments=[
            self.bot_comment(10, MARKER + "\nold report"),
            self.bot_comment(20, TITLE + "\nlegacy report"),
        ])
        self.assertEqual(self.mutations(calls)[0][1]["comment_id"], 10)

    def test_finds_fork_pr_when_event_has_no_pull_requests(self):
        calls = self.run_report(run={"pull_requests": []})
        self.assertIn("associated", [kind for kind, *_ in calls])
        self.assertEqual(len(self.mutations(calls)), 1)

    def test_new_commit_and_rerun_update_the_same_comment(self):
        old = self.bot_comment(9, MARKER + "\n<!-- apr-localization-run: 99; attempt: 1 -->\n" + TITLE)
        for changes in ({"head_sha": "new456"}, {"run_attempt": 2}):
            with self.subTest(changes=changes):
                calls = self.mutations(self.run_report(run=changes, comments=[old]))
                self.assertEqual(calls[0][0], "update")
                self.assertEqual(calls[0][1]["comment_id"], 9)
                self.assertIn(changes.get("head_sha", "abc123"), calls[0][1]["body"])
                self.assertIn(f"attempt: {changes.get('run_attempt', 1)}", calls[0][1]["body"])

    def test_identical_result_for_same_attempt_is_not_reposted(self):
        body = self.mutations(self.run_report())[0][1]["body"]
        self.assertEqual(self.mutations(self.run_report(comments=[self.bot_comment(9, body)])), [])

    def test_ignores_closed_outdated_or_unrelated_prs(self):
        cases = [
            {"state": "closed"},
            {"head": {"sha": "new456", "ref": "feature", "repo": {"id": 42}}},
            {"head": {"sha": "abc123", "ref": "other", "repo": {"id": 42}}},
            {"head": {"sha": "abc123", "ref": "feature", "repo": {"id": 99}}},
        ]
        for pr in cases:
            with self.subTest(pr=pr):
                self.assertEqual(self.mutations(self.run_report(pr=pr)), [])

    def test_rejects_wrong_origin_or_superseded_attempt_from_live_api(self):
        cases = [
            {"event": "workflow_dispatch"}, {"path": ".github/workflows/unrelated.yml"},
            {"workflow_id": 56}, {"run_attempt": 2}, {"status": "in_progress"},
            {"conclusion": "cancelled"}, {"conclusion": "skipped"},
            {"head_sha": "new456"}, {"head_branch": "other"}, {"head_repository": {"id": 99}},
        ]
        for latest in cases:
            with self.subTest(latest=latest):
                calls = self.run_report(latest=latest)
                self.assertEqual(self.mutations(calls), [])
                self.assertNotIn("read", [kind for kind, *_ in calls])

    def test_accepts_api_workflow_path_with_ref_suffix(self):
        calls = self.run_report(latest={"path": ".github/workflows/check_translations.yml@refs/pull/7/merge"})
        self.assertEqual(len(self.mutations(calls)), 1)

    def test_newer_run_for_same_head_blocks_old_report_even_before_new_comment(self):
        self.assertEqual(self.mutations(self.run_report(runs=[{"id": 101, "status": "queued"}])), [])

    def test_newer_run_from_another_fork_or_branch_does_not_block_report(self):
        for other in ({"id": 101, "head_repository": {"id": 99}}, {"id": 101, "head_branch": "other"}):
            with self.subTest(other=other):
                self.assertEqual(len(self.mutations(self.run_report(runs=[other]))), 1)

    def test_newer_comment_run_or_attempt_cannot_be_overwritten(self):
        for run_id, attempt in ((101, 1), (100, 2)):
            with self.subTest(run_id=run_id, attempt=attempt):
                old = self.bot_comment(9, MARKER + f"\n<!-- apr-localization-run: {run_id}; attempt: {attempt} -->")
                self.assertEqual(self.mutations(self.run_report(comments=[old])), [])

    def test_rechecks_pr_head_and_attempt_immediately_before_mutation(self):
        moved_head = {"sha": "new456", "ref": "feature", "repo": {"id": 42}}
        calls = self.run_report(pr_sequence=[{}, {"head": moved_head}])
        self.assertEqual(self.mutations(calls), [])
        calls = self.run_report(latest_sequence=[{}, {"run_attempt": 2, "status": "in_progress"}])
        self.assertEqual(self.mutations(calls), [])

    def test_missing_or_invalid_artifact_reports_failure_instead_of_success(self):
        cases = [
            {"download_outcome": "failure"}, {"missing_file": True}, {"not_a_file": True},
            {"size": 250001}, {"body": TITLE + "\n" + "x" * 60000},
            {"body": "not a localization report"}, {"body": TITLE + "\n\0bad"},
        ]
        for artifact in cases:
            with self.subTest(artifact=list(artifact)):
                calls = self.run_report(**artifact)
                body = self.mutations(calls)[0][1]["body"]
                self.assertIn("| Report generation | ❌ Failed | — | — |", body)
                self.assertIn("<details>", body)
                self.assertIn("Translation coverage was not validated", body)
                self.assertNotIn("✅ Passed", body)
                self.assertIn("warning", [kind for kind, *_ in calls])

    def test_failed_and_skipped_checks_still_update_existing_comment(self):
        for conclusion, text in (("failure", "❌ Failed"), ("success", "⏭ Skipped: token unavailable")):
            with self.subTest(conclusion=conclusion):
                calls = self.run_report(
                    run={"conclusion": conclusion}, body=TITLE + "\n\n" + text,
                    comments=[self.bot_comment(9, MARKER + "\nold report")],
                )
                self.assertEqual(self.mutations(calls)[0][0], "update")
                self.assertIn(text, self.mutations(calls)[0][1]["body"])

    def test_artifact_is_read_as_text_without_running_embedded_code(self):
        payload = TITLE + "\n\nrequire('node:child_process').execSync('do not execute');"
        calls = self.run_report(body=payload)
        self.assertIn(payload, self.mutations(calls)[0][1]["body"])
        self.assertEqual([kind for kind, *_ in calls].count("read"), 1)

    def test_workflows_keep_pr_execution_read_only_and_artifacts_isolated(self):
        source = (ROOT / ".github/workflows/check_translations.yml").read_text(encoding="utf-8")
        reporter = WORKFLOW.read_text(encoding="utf-8")
        self.assertNotIn("pull-requests: write", source)
        self.assertNotIn("createComment", source)
        self.assertNotIn("pull_request_target", source)
        self.assertIn("persist-credentials: false", source)
        self.assertIn("--skip-reason", source)
        self.assertIn("name: localization-report-${{ github.run_attempt }}", source)
        self.assertIn("cat translation-report.md >> \"$GITHUB_STEP_SUMMARY\"", source)
        self.assertNotIn("uses: actions/checkout", reporter)
        self.assertNotRegex(reporter, r"(?m)^\s+run:")
        self.assertIn("path: ${{ runner.temp }}/localization-report", reporter)
        self.assertIn("run-id: ${{ github.event.workflow_run.id }}", reporter)
        self.assertIn("name: localization-report-${{ github.event.workflow_run.run_attempt }}", reporter)


if __name__ == "__main__":
    unittest.main()
