"""Exercise the localization CI shell without fetching secrets or CurseForge data."""

import os
from pathlib import Path
import shutil
import subprocess
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[2]
SOURCE = (ROOT / ".github/workflows/check_translations.yml").read_text(encoding="utf-8")


def bash_path():
    if os.name == "nt":
        candidate = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Git/bin/bash.exe"
        if candidate.is_file():
            return str(candidate)
    return shutil.which("bash")


class LocalizationWorkflowTests(unittest.TestCase):
    def run_check(self, *, token="token", base="", exit_code=0):
        shell = bash_path()
        if not shell:
            self.skipTest("Bash is required to exercise the Ubuntu workflow")
        step = SOURCE.split("      - name: Run translation check\n", 1)[1].split("\n      - name:", 1)[0]
        script = textwrap.dedent(step.split("        run: |\n", 1)[1])
        # Capture argv exactly, including whitespace and shell metacharacters.
        stub = "python() { printf '%s\\0' \"$@\"; return \"$CHECK_EXIT_CODE\"; };\n"
        result = subprocess.run(
            [shell, "-e", "-o", "pipefail", "-c", stub + script],
            env={**os.environ, "CF_API_KEY": token, "PR_BASE_SHA": base, "CHECK_EXIT_CODE": str(exit_code)},
            capture_output=True, text=True, encoding="utf-8", timeout=20,
        )
        self.assertEqual(result.stderr, "")
        return result.returncode, result.stdout.rstrip("\0").split("\0")

    def test_pr_checks_head_against_base_and_emits_machine_readable_artifact(self):
        status, args = self.run_check(base="abc123")
        self.assertEqual(status, 0)
        self.assertEqual(args[0], ".github/scripts/check_translation_string.py")
        self.assertEqual(args[args.index("--base-ref") + 1], "abc123")
        self.assertEqual(args[args.index("--json-output") + 1], "translation-report.json")
        self.assertNotIn("--skip-reason", args)
        self.assertIn("ref: ${{ github.event.pull_request.head.sha || inputs.branch || github.ref }}", SOURCE)
        self.assertIn("fetch-depth: 0", SOURCE)
        self.assertIn("persist-credentials: false", SOURCE)

    def test_manual_run_has_no_baseline_and_performs_full_check(self):
        status, args = self.run_check()
        self.assertEqual(status, 0)
        self.assertNotIn("--base-ref", args)
        self.assertNotIn("--skip-reason", args)
        self.assertIn("--json-output", args)

    def test_fork_without_token_preserves_baseline_and_records_remote_skip(self):
        status, args = self.run_check(token="", base="base-sha")
        self.assertEqual(status, 0)
        self.assertEqual(args[args.index("--base-ref") + 1], "base-sha")
        self.assertIn("--json-output", args)
        reason = args[args.index("--skip-reason") + 1]
        self.assertIn("CF_API_KEY is unavailable", reason)
        self.assertIn("CurseForge validation was skipped", reason)

    def test_baseline_ref_is_passed_as_data_without_shell_expansion(self):
        base = 'refs/heads/test; $(printf injected) "quoted"'
        status, args = self.run_check(base=base)
        self.assertEqual(status, 0)
        self.assertEqual(args[args.index("--base-ref") + 1], base)
        self.assertEqual(args.count("--base-ref"), 1)
        step = SOURCE.split("      - name: Run translation check\n", 1)[1].split("\n      - name:", 1)[0]
        self.assertNotIn("${{", step.split("        run: |\n", 1)[1])

    def test_failed_check_remains_failure_and_reports_are_published_always(self):
        status, _ = self.run_check(base="abc123", exit_code=1)
        self.assertEqual(status, 1)
        upload = SOURCE.split("      - name: Upload localization report\n", 1)[1].split("\n      - name:", 1)[0]
        self.assertIn("if: always()", upload)
        self.assertIn("            translation-report.md\n            translation-report.json", upload)
        self.assertIn("name: localization-report-${{ github.run_attempt }}", upload)
        self.assertIn("if: steps.translation_check.outcome == 'failure'", SOURCE)
        self.assertIn("contents: read", SOURCE)
        self.assertNotIn("pull-requests: write", SOURCE)


if __name__ == "__main__":
    unittest.main()
