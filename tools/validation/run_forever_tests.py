"""Compatibility alias for the shared Lua runner's Forever group and syntax checks."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tools.validation.run_lua_tests import main


if __name__ == "__main__":
    raise SystemExit(main(["--forever-only", *sys.argv[1:]]))
