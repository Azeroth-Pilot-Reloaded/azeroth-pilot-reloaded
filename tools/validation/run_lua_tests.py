"""Compatibility entry point for the Lua suites now stored under tests/lua."""

import argparse
from pathlib import Path

import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tests.lua.test_regressions import LuaRegressionTests

GROUPS = {
    "forever-only": ("navigation_library", "navigation_adapter", "navigation_action_selection", "navigation_catalog_profiles", "navigation_mandatory_chain", "navigation_zones", "taxi_discovery",
                     "navigation_forever_performance", "navigation_forever_projection",
                     "navigation_search_performance", "navigation_search_walking_performance", "navigation_zone_graph",
                     "navigation_catalog_performance", "navigation_taxi_performance", "navigation_scheduling",
                     "navigation_adapter_geometry_cache", "navigation_projection_cache", "navigation_map_projection", "idle_map_lines",
                     "client_compatibility", "level_requirements", "reputation_progress",
                     "route_conditions", "route_action_usage", "native_route_actions",
                     "area_navigation", "route_engine", "step_progression", "skill_api", "secret_compatibility",
                     "merchant_optional", "merchant_target_stock", "gamepad"),
    "ui-only": ("current_step_render", "route_panels_render", "reputation_progress",
                "quest_order_performance", "ui_skin", "gamepad"),
    "skins-only": ("ui_skin", "eui_settings", "skin_pending_performance", "settings_widgets"),
    "xp-overlay-only": ("xp_overlay_persistence",),
    "zone-performance-only": ("zone_transition_performance", "navigation_scheduling"),
    "performance-only": ("quest_order_performance", "zone_transition_performance",
                         "navigation_scheduling", "step_progression",
                         "resource_monitor", "performance_dashboard", "route_path_performance",
                         "arrow_visibility", "idle_tracker_performance", "performance_scopes", "map_pin_performance",
                         "skin_pending_performance", "settings_widgets", "reputation_scheduling", "route_browser"),
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
