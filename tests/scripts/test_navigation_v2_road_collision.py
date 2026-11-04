"""Discover the small synthetic road-collision Lua contracts independently."""
from pathlib import Path
import unittest

from tests.lua.test_regressions import run_lua_suite


ROOT = Path(__file__).resolve().parents[2]
SUITES = sorted((ROOT / 'tests/lua/navigation_v2_road_collision').glob('*_test.lua'))


class RoadCollisionTests(unittest.TestCase):
    pass


def make_test(path):
    def test(self):
        run_lua_suite(path)
    return test


if not SUITES:
    raise RuntimeError('No road-collision contracts found')
for suite in SUITES:
    setattr(RoadCollisionTests, 'test_' + suite.stem.removesuffix('_test'), make_test(suite))
