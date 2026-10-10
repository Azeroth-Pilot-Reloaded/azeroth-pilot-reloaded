"""Independent main/parallel numbering and source preservation regressions."""

from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".github/scripts"))
import fix_route_indexes as indexes
sys.path.pop(0)


class RouteIndexTests(unittest.TestCase):
    def test_independent_sequences_in_either_field_order(self):
        main = '''steps = {
        { Note = "main one", _index = 91 },
        { Note = "main two", _index = 92 },
    }'''
        parallel = '''parallelSteps = {
        { conditions = { MinLevel = 3 }, steps = {
            { Note = "parallel one", _index = 93 },
            { Note = "parallel two", _index = 94 },
        } },
        { steps = { { Note = "parallel three", _index = 95 } } },
    }'''
        for fields in ((main, parallel), (parallel, main)):
            with self.subTest(parallel_first=fields[0] == parallel):
                source = 'APR.RouteQuestStepList["test"] = {\n' + ',\n'.join(fields) + '\n}'
                expected = source
                for old, new in ((91, 1), (92, 2), (93, 1), (94, 2), (95, 3)):
                    expected = expected.replace(f'_index = {old}', f'_index = {new}')
                self.assertEqual(indexes.normalize_text(source), expected)
                self.assertEqual(indexes.normalize_text(expected), expected)

    def test_each_route_resets_both_sequences(self):
        route = '''APR.RouteQuestStepList["NAME"] = {
    steps = { { _index = 8 }, { _index = 9 } },
    parallelSteps = { { steps = { { _index = 10 }, { _index = 11 } } } },
}
'''
        source = route.replace("NAME", "first") + route.replace("NAME", "second")
        expected = source
        for old, new in ((8, 1), (9, 2), (10, 1), (11, 2)):
            expected = expected.replace(f'_index = {old}', f'_index = {new}')
        self.assertEqual(indexes.normalize_text(source), expected)

    def test_comments_strings_payloads_and_line_endings_are_preserved(self):
        source = '''-- APR.RouteQuestStepList["ignored"] = { steps = { { _index = 80 } } }
local example = [=[
APR.RouteQuestStepList["ignored"] = {
    _index = 81,
}
]=]
APR.RouteQuestStepList["test"] = {
    conditions = { _index = 82 },
    steps = {
        {
            Note = [==[ braces } parallelSteps = { _index = 83, ]==],
            FutureData = {
                _index = 84,
            },
            _index = 85, -- keep comment
        },
        { Note = "no index" },
        { ["_index"] = 86; },
    },
    parallelSteps = { { steps = { { _index = 87 } } } },
}'''
        source = '\ufeff' + source.replace('\n', '\r\n')
        expected = source.replace('_index = 85', '_index = 1').replace(
            '["_index"] = 86', '["_index"] = 2').replace('_index = 87', '_index = 1')
        self.assertEqual(indexes.normalize_text(source), expected)

    def test_nonliteral_indexes_are_preserved(self):
        source = '''APR.RouteQuestStepList["test"] = {
    steps = { { _index = 5 + 2 }, { _index = 1.5 }, { _index = 99 } },
}'''
        self.assertEqual(indexes.normalize_text(source), source.replace('_index = 99', '_index = 1'))
