"""Bounded loader contracts using synthetic decoder boundaries in Lua 5.1."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


class TerrainLoaderTests(unittest.TestCase):
    def test_contracts(self):
        for path in sorted(Path(__file__).parent.glob('*_test.lua')):
            with self.subTest(suite=path.name):
                LuaRuntime(unpack_returned_tuples=True).execute(path.read_text(), name='@'+path.as_posix())
