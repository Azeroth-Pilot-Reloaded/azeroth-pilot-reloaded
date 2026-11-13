"""Synthetic conversion inputs; no maintained itinerary is a test fixture."""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import json

from tests.routes.route_loader import load_routes
from tests.routes.route_schema import RouteSchema
from tools.conversion import forever_reputation as converter


class ReputationConversionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'source'
        self.source.mkdir()
        self.output = self.root / 'output'
        self.translations = self.root / 'translations.json'
        self.entry = ('invented', 98765, 'Invented', 'Inventée', 'Alliance', 17, 123,
                      [(5, 'gather'), (8, 'exchange')])
        self.activities = {'gather': {'enUS': 'Gather tokens.', 'frFR': 'Récupérez les jetons.'},
                           'exchange': {'enUS': 'Exchange tokens.', 'frFR': 'Échangez les jetons.'}}
        self.source.joinpath('invented.guide').write_text(
            'guide fixture\n  rep 98765 Friendly\n  rep 98765 Exalted optional\n', encoding='utf-8')
        self.addCleanup(patch.stopall)
        patch.object(converter, 'CATALOG', [self.entry]).start()
        patch.object(converter, 'all_activities', return_value=self.activities).start()

    def test_builds_native_progression_and_separate_translation_export(self):
        converter.build(self.source, self.output, self.translations)
        exported = json.loads(self.translations.read_text(encoding='utf-8'))
        paths = list(self.output.glob('*.lua'))
        catalog = load_routes(paths, translations=exported['frFR'])
        self.assertEqual(len(catalog.routes), 1)
        route = catalog.routes['Forever-Reputation-98765']
        RouteSchema(catalog).validate('invented', route)
        self.assertEqual(route['label'], 'Forever - Inventée')
        self.assertEqual(route['conditions'], {'MinLevel': 17, 'Faction': 'Alliance'})
        self.assertFalse(route['autoStartOnMap'])
        self.assertEqual(route['steps'][1]['Reputation'],
                         {'factionID': 98765, 'level': 5, 'type': 'standard'})
        self.assertEqual(route['steps'][2]['Reputation']['level'], 8)
        self.assertTrue(route['steps'][3]['RouteCompleted'])
        self.assertEqual(exported['frFR']['FOREVER_REPUTATION_ACTIVITY_EXCHANGE'],
                         'Échangez les jetons.')

    def test_undocumented_target_does_not_overwrite_existing_outputs(self):
        self.source.joinpath('invented.guide').write_text('  rep 98765 Friendly\n', encoding='utf-8')
        self.output.mkdir()
        original = self.output / 'Forever_Reputations.lua'
        original.write_text('previous declaration', encoding='utf-8')
        self.translations.write_text('previous export', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'Undocumented target'):
            converter.build(self.source, self.output, self.translations)
        self.assertEqual(original.read_text(), 'previous declaration')
        self.assertEqual(self.translations.read_text(), 'previous export')

    def test_new_source_requires_review_without_creating_outputs(self):
        self.source.joinpath('unreviewed.guide').write_text('  rep 87654 Neutral\n', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'Source coverage changed'):
            converter.build(self.source, self.output, self.translations)
        self.assertFalse(self.output.exists())
        self.assertFalse(self.translations.exists())

    def test_duplicate_identity_is_rejected_before_writes(self):
        with patch.object(converter, 'CATALOG', [self.entry, self.entry]):
            with self.assertRaisesRegex(ValueError, 'Duplicate faction ID'):
                converter.build(self.source, self.output, self.translations)
        self.assertFalse(self.output.exists())

    def test_parser_accepts_indentation_and_optional_targets_only(self):
        text = ('  rep 87654 Unfriendly\n\trep 87654 Exalted optional\n'
                '# rep 999 Friendly\ntip rep 111 Honored\n'
                'rep 222 Exaltedness\nrep 333 Unknown\n')
        self.assertEqual(converter.read_targets(text), {(87654, 3), (87654, 8)})

    def test_repeatable_traversal_uses_live_state_without_permanent_flags(self):
        steps = converter.quest(12345, converter.point(987, 20, 30),
                                [converter.objective([1, 2], converter.point(987, 40, 50))],
                                npc=55555, repeatable=True)
        self.assertEqual(steps[0]['PickUp'], [12345])
        self.assertEqual(steps[0]['IsQuestNotOnQuest'], 12345)
        self.assertEqual(steps[0]['Range'], 5)
        self.assertEqual(steps[1]['Qpart'], {12345: [1, 2]})
        self.assertEqual(steps[1]['IsQuestOnQuest'], 12345)
        self.assertEqual(steps[2]['Done'], [12345])
        self.assertEqual(steps[2]['IsQuestOnQuest'], 12345)
        for step in steps:
            self.assertNotIn('IsQuestCompleted', step)
            self.assertNotIn('IsQuestUncompleted', step)

    def test_injected_unlocks_preserve_native_order_and_contiguous_indexes(self):
        steps = converter.quest(54321, converter.point(321, 12.5, 72),
                                [converter.objective([1], converter.point(321, 20, 25))])
        self.source.joinpath('invented.guide').write_text(
            'rep 98765 Friendly\nrep 98765 Exalted\naccept 54321\nturnin 54321\n', encoding='utf-8')
        with patch.object(converter, 'native_plan', return_value={0: steps}):
            converter.build(self.source, self.output, self.translations)
        catalog = load_routes(list(self.output.glob('*.lua')))
        route = catalog.routes['Forever-Reputation-98765']
        RouteSchema(catalog).validate('invented', route)
        self.assertEqual([route['steps'][i]['_index'] for i in range(1, 7)], list(range(1, 7)))
        self.assertEqual(route['steps'][1]['PickUp'], {1: 54321})
        self.assertEqual(route['steps'][1]['IsQuestUncompleted'], 54321)
        self.assertEqual(route['steps'][1]['Coord'], {'x': 12.5, 'y': 72})
        self.assertEqual(route['steps'][1]['Zone'], 321)
        self.assertEqual(route['steps'][2]['Qpart'], {54321: {1: 1}})
        self.assertEqual(route['steps'][3]['Done'], {1: 54321})
        self.assertEqual(route['steps'][4]['Reputation']['level'], 5)
        self.assertEqual(route['steps'][5]['Reputation']['level'], 8)
        self.assertTrue(route['steps'][6]['RouteCompleted'])

    def test_undocumented_native_quest_is_rejected_before_writes(self):
        with patch.object(converter, 'native_plan', return_value={0: [{'PickUp': [76543]}]}):
            with self.assertRaisesRegex(ValueError, 'Undocumented native quests'):
                converter.build(self.source, self.output, self.translations)
        self.assertFalse(self.output.exists())


if __name__ == '__main__':
    unittest.main()
