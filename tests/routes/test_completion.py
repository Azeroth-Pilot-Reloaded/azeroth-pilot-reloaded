from pathlib import Path
import tempfile
import unittest
from tests.routes.route_loader import load_routes
from tools.validation.route_completion import ensure_route_completions


class CompletionRepair(unittest.TestCase):
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
