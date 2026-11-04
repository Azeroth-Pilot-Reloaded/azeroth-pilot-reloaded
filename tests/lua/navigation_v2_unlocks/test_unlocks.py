"""Execute each synthetic contract in its own Lua 5.1 runtime."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


class UnlockTests(unittest.TestCase):
    def test_contracts(self):
        paths = sorted(Path(__file__).parent.glob("*_test.lua"))
        self.assertTrue(paths, "No unlock contracts discovered")
        for path in paths:
            with self.subTest(suite=path.name):
                LuaRuntime(unpack_returned_tuples=True).execute(
                    path.read_text(encoding="utf-8"), name="@" + path.as_posix()
                )
