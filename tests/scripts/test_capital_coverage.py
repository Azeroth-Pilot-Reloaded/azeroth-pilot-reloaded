import unittest
from unittest.mock import patch

from tools.terrain_ui import capital_coverage


class CapitalCoverageTests(unittest.TestCase):
    def test_reports_distinct_phases_and_missing_data(self):
        catalogue = {
            "ui": {
                "1": {"Type": 2, "ParentUiMapID": 0, "name": {"fr": "Continent"}},
                "2": {"Type": 3, "ParentUiMapID": 1, "name": {"fr": "Ville"}},
                "3": {"Type": 5, "ParentUiMapID": 2, "name": {"fr": "Étage"}},
            },
            "worlds": {},
            "areas": {},
            "assignments": {"2": [[7, 0, [0, 0, 50, 50]], [7, 8, [0, 0, 50, 50]],
                                  [9, 8, [0, 0, 50, 50]]]},
        }
        scope = [{"expansion": "Expansion", "hubs": [{"maps": [2, 3], "anchor": [50, 50]}]}]

        def measure(world, *_):
            return (3, 2, 40, 10, 4) if world == 7 else None

        with patch.object(capital_coverage, "count_cells", return_value=measure) as load:
            report = list(capital_coverage.audit(catalogue, scope, "1.2.3.4"))

        load.assert_called_once_with("1.2.3.4", {7, 9})
        self.assertEqual([row["status"] for row in report], ["measured", "missing_pack", "missing_projection"])
        self.assertEqual(report[0]["packedTiles"], 2)
        self.assertEqual(report[0]["detailedIndoorCells"], 4)
        self.assertEqual(report[0]["continent"], {"fr": "Continent"})
        self.assertEqual(report[2]["hub"], {"fr": "Ville"})
        self.assertNotIn("indoorCells", report[1])

    def test_hub_without_its_own_map_uses_a_local_area(self):
        catalogue = {"assignments": {"4": [[1, 20, [100, -100, 700, 500]]]}}
        hub = {"area": 99, "anchor": [0, 50]}
        self.assertEqual(list(capital_coverage.hub_assignments(catalogue, hub, 4)),
                         [(1, (250.0, 350.0, 550.0, 500))])


if __name__ == "__main__":
    unittest.main()
