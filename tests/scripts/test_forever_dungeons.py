"""Authoring tool behavior uses invented contracts, never a shipped itinerary."""
import unittest

from lupa.lua51 import LuaRuntime
from tools.forever.build_dungeons import lua, quest_dependencies, schedule_quests, step_blocks, replace_step_blocks


class DungeonAuthoringTests(unittest.TestCase):
    def setUp(self):
        self.enter = {"EnterInstance": {"dungeonKey": "INVENTED"}}
        self.leave = {"LeaveInstance": {"dungeonKey": "INVENTED"}}
        self.kill = {"KillNPC": {"npcID": 80003, "name": "Invented captain"}}

    def schedule(self, entries):
        return schedule_quests(entries, self.enter, self.leave, [self.kill])

    def test_prerequisite_delivery_precedes_dependent_pickup(self):
        prep = [(False, {"PickUp": [80001]}), (False, {"Done": [80001]})]
        run = [(False, {"PickUp": [80002]}), (True, {"Qpart": {80002: [1]}}), (False, {"Done": [80002]})]
        steps = self.schedule([(80001, [], prep), (80002, [80001], run)])
        self.assertEqual(steps[:3], [prep[0][1], prep[1][1], run[0][1]])
        self.assertEqual(steps[3:], [self.enter, self.kill, run[1][1], self.leave, run[2][1]])

    def test_return_then_reenter_for_followup(self):
        first = [(False, {"PickUp": [80001]}), (True, {"Qpart": {80001: [1]}}), (False, {"Done": [80001]})]
        second = [(False, {"PickUp": [80002]}), (True, {"Qpart": {80002: [1]}}), (False, {"Done": [80002]})]
        steps = self.schedule([(80001, [], first), (80002, [80001], second)])
        self.assertEqual(steps, [first[0][1], self.enter, self.kill, first[1][1], self.leave,
                                 first[2][1], second[0][1], self.enter, second[1][1], self.leave, second[2][1]])

    def test_interior_npc_pickup_precedes_boss_and_dropped_starter_follows_it(self):
        npc = {"PickUp": [80001]}
        drop = {"PickUp": [80002], "Button": {"80002": 81002}}
        steps = self.schedule([(80001, [], [(True, npc)]), (80002, [], [(True, drop)])])
        self.assertEqual(steps, [self.enter, npc, self.kill, drop, self.leave])

    def test_no_quests_still_enters_kills_and_exits(self):
        self.assertEqual(self.schedule([]), [self.enter, self.kill, self.leave])

    def test_cycles_fail_instead_of_publishing_partial_schedule(self):
        with self.assertRaisesRegex(ValueError, "dependency"):
            self.schedule([(80001, [80002], [(False, {"PickUp": [80001]})]),
                           (80002, [80001], [(True, {"PickUp": [80002]})])])

    def test_dependency_modes_preserve_disjunction_and_conjunction(self):
        self.assertEqual(quest_dependencies({"preQuestSingle": {"1": 80001, "2": 80002},
                                            "preQuestGroup": {"1": 80003}}), ([80001, 80002], [80003]))
        with self.assertRaises(ValueError):
            quest_dependencies({"preQuestSingle": {"1": -80001}})

    def test_table_edit_handles_quoted_braces_and_preserves_surrounding_metadata(self):
        source = 'route = {\n    label = "Synthetic",\n    steps = {\n        { Note = "brace } and \\\" quote", _index = 8 },\n        { RouteCompleted = true, _index = 9 },\n    },\n}\n'
        _, _, blocks = step_blocks(source)
        self.assertEqual(len(blocks), 2)
        edited = replace_step_blocks(source, blocks)
        self.assertIn('label = "Synthetic"', edited)
        self.assertIn('_index = 1', edited)
        self.assertIn('_index = 2', edited)
        LuaRuntime().execute(edited)

    def test_serializer_is_deterministic_and_preserves_multi_npc_associations(self):
        a = {"encounters": {90002: [91002, 91003], 90001: 91001}, "name": "Invented"}
        b = {"name": "Invented", "encounters": {90001: 91001, 90002: [91002, 91003]}}
        self.assertEqual(lua(a), lua(b))
        table = LuaRuntime().eval(lua(a))
        self.assertEqual(list(table.encounters[90002].values()), [91002, 91003])


if __name__ == "__main__":
    unittest.main()
