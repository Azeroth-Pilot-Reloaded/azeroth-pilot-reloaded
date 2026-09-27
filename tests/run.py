"""Run all tests or one CI suite; also write a GitHub Actions job summary."""

import argparse
import os
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--suite", choices=("scripts", "lua", "routes", "all"), default="all")
    args = parser.parse_args()
    sys.path.insert(0, str(ROOT))
    os.chdir(ROOT)
    directory = ROOT / "tests"
    if args.suite != "all":
        directory /= args.suite
    suite = unittest.defaultTestLoader.discover(str(directory), pattern="test_*.py", top_level_dir=str(ROOT))
    if suite.countTestCases() == 0:
        raise RuntimeError(f"No tests discovered for {args.suite}")
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            handle.write(
                f"## Tests / {args.suite}\n\n"
                f"{'✅ Success' if result.wasSuccessful() else '❌ Failure'}\n\n"
                f"{result.testsRun} tests run · {len(result.failures)} failures · "
                f"{len(result.errors)} errors · {len(result.skipped)} skipped\n"
            )
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
