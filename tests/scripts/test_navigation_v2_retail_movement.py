"""Small Retail movement contracts, without maintained route fixtures."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]


class RetailMovementTests(unittest.TestCase):
    def run_contract(self, name):
        path = ROOT / 'tests/lua/navigation_v2_retail_movement' / (name + '_test.lua')
        LuaRuntime(unpack_returned_tuples=True).execute(
            path.read_text(encoding='utf-8'), name='@' + path.as_posix())

    def test_profile(self):
        self.run_contract('profile')

    def test_planner(self):
        self.run_contract('planner')

    def test_observation(self):
        self.run_contract('observation')

    def test_host(self):
        self.run_contract('host')
