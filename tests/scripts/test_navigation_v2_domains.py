"""Position-domain contracts through the shared V2 engine, using invented data."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]


class DomainTests(unittest.TestCase):
    def test_contracts(self):
        for path in sorted((ROOT/'tests/lua/navigation_v2_domains').glob('*_test.lua')):
            with self.subTest(suite=path.name):
                LuaRuntime(unpack_returned_tuples=True).execute(
                    path.read_text(encoding='utf-8'), name='@'+path.as_posix())
