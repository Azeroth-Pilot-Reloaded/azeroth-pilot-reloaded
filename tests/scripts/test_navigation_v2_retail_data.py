"""Small synthetic preparation-to-real-V2-solver contract."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]


class RetailDataTests(unittest.TestCase):
    def test_declared_ground_cost(self):
        path = ROOT / 'tests/lua/navigation_v2_retail_data/ground_cost_test.lua'
        LuaRuntime(unpack_returned_tuples=True).execute(
            path.read_text(encoding='utf-8'), name='@' + path.as_posix())

    def test_personal_transports(self):
        path = ROOT / 'tests/lua/navigation_v2_retail_data/personal_test.lua'
        LuaRuntime(unpack_returned_tuples=True).execute(
            path.read_text(encoding='utf-8'), name='@' + path.as_posix())

    def test_condition_alternatives(self):
        path = ROOT / 'tests/lua/navigation_v2_retail_data/predicates_test.lua'
        LuaRuntime(unpack_returned_tuples=True).execute(
            path.read_text(encoding='utf-8'), name='@' + path.as_posix())

    def test_preparation_and_solver(self):
        path = ROOT / 'tests/lua/navigation_v2_retail_data/data_test.lua'
        LuaRuntime(unpack_returned_tuples=True).execute(
            path.read_text(encoding='utf-8'), name='@' + path.as_posix())
