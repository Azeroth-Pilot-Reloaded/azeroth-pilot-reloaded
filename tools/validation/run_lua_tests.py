"""Compatibility entry point for the Lua suites now stored under tests/lua."""

import argparse
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tests.lua.test_regressions import LuaRegressionTests

GROUPS = {
    "forever-only": ("farstrider_data", "taxi_discovery", "forever_travel",
                     "client_compatibility", "level_requirements", "reputation_progress",
                     "route_conditions", "route_action_usage", "native_route_actions",
                     "area_navigation", "route_engine", "step_progression", "skill_api", "secret_compatibility"),
    "ui-only": ("current_step_render", "route_panels_render", "reputation_progress",
                "quest_order_performance", "ui_skin"),
    "skins-only": ("ui_skin", "eui_settings"),
    "xp-overlay-only": ("xp_overlay_persistence",),
    "zone-performance-only": ("zone_transition_performance", "farstrider_routing_performance"),
    "performance-only": ("quest_order_performance", "zone_transition_performance",
                         "farstrider_routing_performance", "step_progression",
                         "resource_monitor", "performance_dashboard", "route_path_performance",
                         "arrow_visibility", "idle_tracker_performance"),
}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    options = parser.add_mutually_exclusive_group()
    for group in GROUPS:
        options.add_argument("--" + group, dest="group", action="store_const", const=group)
    args = parser.parse_args(argv)
    if args.group:
        suite = unittest.TestSuite(LuaRegressionTests("test_" + name) for name in GROUPS[args.group])
    else:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(LuaRegressionTests)
    if args.group == "forever-only":
        suite.addTests(unittest.defaultTestLoader.discover(
            str(ROOT / "tests/routes"), pattern="test_*.py", top_level_dir=str(ROOT)
        ))
    return 0 if unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
