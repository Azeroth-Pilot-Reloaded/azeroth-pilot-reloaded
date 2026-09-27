"""Discover every Lua regression suite, with an isolated runtime per file."""

import os
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[2]


def run_lua_suite(path: Path) -> LuaRuntime:
    runtime = LuaRuntime(unpack_returned_tuples=True)
    previous = Path.cwd()
    try:
        os.chdir(ROOT)
        runtime.execute(path.read_text(encoding="utf-8"), name="@" + path.relative_to(ROOT).as_posix())
    finally:
        os.chdir(previous)
    return runtime


class LuaRegressionTests(unittest.TestCase):
    pass


def make_test(path):
    def test(self):
        run_lua_suite(path)
    return test


SUITES = sorted(Path(__file__).parent.glob("*_test.lua"))
if not SUITES:
    raise RuntimeError("No Lua regression suites found")
for path in SUITES:
    setattr(LuaRegressionTests, "test_" + path.stem.removesuffix("_test"), make_test(path))
