"""Small synthetic sector graphs, run independently of shipped navigation data."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


class SectorContracts(unittest.TestCase):
    def test_contracts(self):
        for path in sorted(Path(__file__).parent.glob('*_test.lua')):
            with self.subTest(suite=path.name):
                LuaRuntime(unpack_returned_tuples=True).execute(
                    path.read_text(encoding='utf-8'), name='@' + path.as_posix())
