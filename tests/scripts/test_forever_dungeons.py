"""Authoring tool behavior uses invented contracts, never a shipped itinerary."""
import unittest
from contextlib import closing, redirect_stdout
import io
import json
from pathlib import Path
import sqlite3
import sys
from tempfile import TemporaryDirectory
from unittest.mock import patch

from lupa.lua51 import LuaRuntime
from tools.forever.build_dungeons import lua, quest_dependencies, schedule_quests, step_blocks, replace_step_blocks
from tools.forever import build_dungeons


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

    def test_instance_export_preserves_independent_leveling_chapters(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            source, reference = root / 'source', root / 'reference'
            source.mkdir()
            reference.mkdir()
            (source / 'Data.lua').write_text('local _, ns = ...; ns.data = {}; ns.dungeons = {}', encoding='utf-8')
            (source / 'Curated.lua').write_text('local _, ns = ...; ns.curated = {}; ns.curatedDungeons = {}', encoding='utf-8')
            encounters = source / 'encounters.lua'
            encounters.write_text('', encoding='utf-8')
            for name in ('npc', 'quest', 'quest_start', 'quest_end', 'quest_objective', 'ui_map'):
                (reference / (name + '.jsonl')).write_text('', encoding='utf-8')
            database = root / 'quests.sqlite3'
            with closing(sqlite3.connect(database)) as db, db:
                db.execute('CREATE TABLE entities(kind TEXT, id INTEGER, data_json TEXT)')
                db.execute('CREATE TABLE support(name TEXT, data_json TEXT)')
                db.execute('INSERT INTO support VALUES (?, ?)', ('ZoneDB', json.dumps({
                    'private': {'areaIdToUiMapId': ''}, 'instanceIdToAreaId': {}})))
            catalog = root / 'APR-Core/data/Dungeons/DungeonsForever.lua'
            catalog.parent.mkdir(parents=True)
            catalog.write_text('APR.DungeonData = { forever = {} }', encoding='utf-8')
            chapters = []
            for faction in ('Alliance', 'Horde'):
                chapter = root / 'Routes/Forever/Dungeons' / faction / 'invented.lua'
                chapter.parent.mkdir(parents=True)
                chapter.write_text('APR.RouteQuestStepList["invented-' + faction + '"] = {\n'
                    '    nextRoute = {\n        { route = "invented-successor" },\n    },\n'
                    '    parallelSteps = {{steps = {{PickUp={80002}, _index=1}}}},\n'
                    '    steps = {\n        {PickUp={80001}, _index=1},\n'
                    '        {Boat=true, _index=2},\n        {RouteCompleted=true, _index=3},\n    },\n}\n',
                    encoding='utf-8')
                chapters.append((chapter, chapter.read_bytes()))
            arguments = ['build_dungeons', '--instance-source', str(source), '--quest-database', str(database),
                         '--reference-data', str(reference), '--encounter-reference', str(encounters),
                         '--translations', str(root / 'translations.json')]
            with patch.object(build_dungeons, 'ROOT', root), patch.object(sys, 'argv', arguments), redirect_stdout(io.StringIO()):
                build_dungeons.main()
            self.assertTrue((root / '.cache/forever-dungeons/review.json').is_file())
            for chapter, expected in chapters:
                self.assertEqual(chapter.read_bytes(), expected)


if __name__ == "__main__":
    unittest.main()
