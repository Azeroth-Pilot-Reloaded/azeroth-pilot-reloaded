"""Exercise optional output in isolated Lua 5.1 runtimes."""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


class WaypointTests(unittest.TestCase):
    def test_contracts(self):
        suites = sorted(Path(__file__).parent.glob("*_test.lua"))
        self.assertTrue(suites, "No waypoint contracts discovered")
        for path in suites:
            with self.subTest(suite=path.name):
                LuaRuntime(unpack_returned_tuples=True).execute(
                    path.read_text(encoding="utf-8"), name="@" + path.as_posix()
                )
