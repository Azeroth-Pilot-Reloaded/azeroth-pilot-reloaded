from pathlib import Path
import tempfile
import unittest
from tests.routes.route_loader import load_routes
from tools.validation.route_completion import ensure_route_completions, ensure_unconditional_route_endings


class CompletionRepair(unittest.TestCase):
    def test_explicit_normalization_preserves_actions_shortcuts_and_client_lifecycles(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'invented.lua'
            source = '''APR.RouteQuestStepList["ordinary"] = {
    label = "Invented", conditions = {Faction="Alliance"},
    steps = {
        {RouteCompleted=true, Class="MAGE", _index=1},
        {Note="Keep instruction", MinLevel=23, _index=2},
        {RouteCompleted=true, AllOf={{Faction="Alliance"},{MinLevel=23}},
         IsQuestCompleted=40001, Note="Keep ending text", _index=3},
    },
}
APR.RouteQuestStepList["temporary"] = {label="Temporary", temporary=true,
    steps={{RouteCompleted=true, Class="MAGE"}}}
APR.RouteQuestStepList["scenario"] = {label="Scenario",
    steps={{scenarioID=71,steps={{RouteCompleted=true,Class="MAGE"}}}}}
APR.RouteQuestStepList["other"] = {label="Other",
    steps={{RouteCompleted=true, Class="MAGE"}}}
'''
            path.write_bytes(b'\xef\xbb\xbf' + source.replace('\n', '\r\n').encode())
            before = path.read_bytes()
            selected = {"ordinary"}
            self.assertEqual(ensure_unconditional_route_endings(directory, check=True, route_keys=selected), ['ordinary'])
            self.assertEqual(path.read_bytes(), before)
            self.assertEqual(ensure_unconditional_route_endings(directory, route_keys=selected), ['ordinary'])
            after = path.read_bytes()
            self.assertTrue(after.startswith(b'\xef\xbb\xbf'))
            self.assertEqual(after.count(b'\r\n'), after.count(b'\n'))
            routes = load_routes([path]).routes
            self.assertEqual(routes['ordinary']['conditions']['Faction'], 'Alliance')
            self.assertEqual(routes['ordinary']['steps'][1]['Class'], 'MAGE')
            self.assertEqual(routes['ordinary']['steps'][2]['MinLevel'], 23)
            self.assertEqual(routes['ordinary']['steps'][3], {'RouteCompleted': True, 'Note': 'Keep ending text', '_index': 3})
            self.assertEqual(routes['temporary']['steps'][1]['Class'], 'MAGE')
            self.assertEqual(routes['scenario']['steps'][1]['steps'][1]['Class'], 'MAGE')
            self.assertEqual(routes['other']['steps'][1]['Class'], 'MAGE')
            self.assertEqual(ensure_unconditional_route_endings(directory, route_keys=selected), [])
            self.assertEqual(path.read_bytes(), after)

    def test_adds_only_missing_main_endings_and_preserves_bytes_on_second_run(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'route.lua'
            source = '''APR.RouteQuestStepList["first"] = {
    label = "First",
    parallelSteps = { { steps = { { UseItem = { itemID = 1 }, _index = 2 } } } },
    steps = {
        { Note = { "Keep me" }, _index = 1 }
    }
}
APR.RouteQuestStepList["second"] = {
    label = "Second",
    steps = {
        { RouteCompleted = true, _index = 1 },
    },
}
'''
            path.write_bytes(b'\xef\xbb\xbf' + source.replace('\n', '\r\n').encode())
            self.assertEqual(ensure_route_completions(directory, check=True), ['first'])
            self.assertEqual(ensure_route_completions(directory), ['first'])
            after = path.read_bytes()
            self.assertTrue(after.startswith(b'\xef\xbb\xbf'))
            self.assertEqual(after.count(b'\n'), after.count(b'\r\n'))
            routes = load_routes([path]).routes
            self.assertTrue(routes['first']['steps'][2]['RouteCompleted'])
            self.assertEqual(routes['first']['steps'][2]['_index'], 3)
            self.assertEqual(routes['first']['steps'][1]['Note'][1], 'Keep me')
            self.assertEqual(ensure_route_completions(directory), [])
            self.assertEqual(path.read_bytes(), after)
