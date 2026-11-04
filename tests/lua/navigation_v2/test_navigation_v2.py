"""Run pure Lua 5.1 contracts without any game or V1 runtime."""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


class NavigationV2Tests(unittest.TestCase):
    def test_contracts(self):
        directory = Path(__file__).parent
        suites = sorted(directory.glob("*_test.lua"))
        self.assertTrue(suites, "No navigation V2 contracts discovered")
        for path in suites:
            with self.subTest(suite=path.name):
                LuaRuntime(unpack_returned_tuples=True).execute(
                    path.read_text(encoding="utf-8"), name="@" + path.as_posix()
                )
