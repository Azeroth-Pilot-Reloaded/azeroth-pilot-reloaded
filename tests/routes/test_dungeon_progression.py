"""Forever dungeon progression regressions confirmed against the client and Questie."""

import unittest

from tests.routes.route_loader import ROOT, load_routes
from tests.routes.route_schema import RouteSchema


class DungeonProgressionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = load_routes([
            *sorted((ROOT / "Routes/Forever/Dungeons/Alliance").glob("*.lua")),
            *sorted((ROOT / "Routes/Forever/Dungeons/Horde").glob("*.lua")),
        ])

    def test_hall_of_thanes_tracks_every_boss_in_corridor_order(self):
        route = self.catalog.routes["Forever-Alliance-Dungeons-Hall-of-Thanes"]
        bosses = [step for step in route["steps"].values() if "KillNPC" in step]
        # DungeonMaster/ATT/Scout agree on Magmatus -> Plunder between Faldrim and Durgen.
        self.assertEqual([step["KillNPC"]["npcID"] for step in bosses],
                         [261306, 261316, 261311, 261319])
        for step in bosses:
            self.assertEqual(step["Dungeon"], "HOT")
            self.assertEqual(step["KillNPC"]["dungeonKey"], "HOT")
            self.assertTrue(step["InstanceQuest"])
            self.assertTrue(step["NoArrow"])

    def test_farsight_waits_for_quest_credit_and_offers_its_gossip_action(self):
        for key in ("Forever-Alliance-Dungeons-Hall-of-Thanes",
                    "Forever-Alliance-Dungeons-Darkshore-Loch-Modan-NightElf"):
            with self.subTest(route=key):
                steps = self.catalog.routes[key]["steps"].values()
                objectives = [step for step in steps if 96392 in step.get("Qpart", {})]
                self.assertEqual(len(objectives), 1)
                step = objectives[0]
                self.assertEqual(step["Qpart"][96392], {1: 1})
                self.assertEqual(step["GossipOptionIDs"], {1: 139831})
                self.assertEqual(step["IsQuestOnQuest"], 96392)
                self.assertNotIn("Waypoint", step)
                self.assertIn("Coord", step)
                self.assertEqual(step["Note"], {1: "CANCEL_FARSIGHT_OBJECTIVE_COMPLETES"})

    def test_early_pickups_respect_quest_minimum_and_remain_available_later(self):
        # Source quest levels differ from these actual acceptance minima.
        for key, quest, required in (
            ("Forever-Horde-Dungeons-Silverpine", 92401, 15),
            ("Forever-Alliance-Dungeons-Westfall", 65, 14),
        ):
            route = self.catalog.routes[key]
            pickups = [step for step in route["steps"].values()
                       if quest in step.get("PickUp", {}).values()]
            self.assertTrue(pickups)
            for step in pickups:
                self.assertGreaterEqual(step.get("MinLevel", 0), required)

        later = self.catalog.routes["Forever-Horde-Dungeons-Ruins-of-Lordaeron"]
        self.assertGreaterEqual(later["conditions"]["MinLevel"], 15)
        self.assertTrue(any(92401 in step.get("PickUp", {}).values()
                            for step in later["steps"].values()))

    def test_progression_declarations_remain_valid_and_sequential(self):
        schema = RouteSchema(self.catalog)
        for key, route in self.catalog.routes.items():
            with self.subTest(route=key):
                schema.validate(key, route)
                self.assertEqual([step["_index"] for step in route["steps"].values()],
                                 list(range(1, len(route["steps"]) + 1)))


if __name__ == "__main__":
    unittest.main()
