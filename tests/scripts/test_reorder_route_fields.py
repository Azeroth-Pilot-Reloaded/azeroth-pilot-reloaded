"""Source-preserving route formatting and pre-commit staging regressions."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from tests.routes.route_loader import load_routes, plain
from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".github/scripts"))
import fix_route_indexes as indexes
import reorder_route_fields as reorder
sys.path.pop(0)


class RouteFieldOrderTests(unittest.TestCase):
    def test_recorder_field_groups_and_natural_text_order(self):
        fields = dict.fromkeys((
            "_index", "Zone", "Class", "FutureData", "NoArrow", "SpellButton", "Button",
            "GossipOptionIDs", "Range", "Coord", "ExtraLineText10", "ExtraLineText2",
            "ExtraLineText", "Note", "Fillers", "DroppableQuest", "PickUpDB", "PickUp",
            "Money", "Zones", "AllOf",
        ), "true")
        self.assertEqual(reorder.ordered_keys(fields, reorder.action_keys()), [
            "PickUp", "PickUpDB", "DroppableQuest", "Fillers", "Note", "ExtraLineText",
            "ExtraLineText2", "ExtraLineText10", "Coord", "Range", "GossipOptionIDs",
            "Button", "SpellButton", "NoArrow", "FutureData", "AllOf", "Class", "Money",
            "Zone", "Zones", "_index",
        ])

    def test_primary_and_fallback_actions(self):
        actions = reorder.action_keys()
        for action in ("LearnSkill", "Repair", "BuyMerchant", "Waypoint", "DropQuest", "EquipItem"):
            with self.subTest(action=action):
                fields = dict.fromkeys(("Coord", "Note", "GossipOptionIDs", action), "true")
                self.assertEqual(reorder.ordered_keys(fields, actions)[0], action)
        for action in ("PickUpDB", "QpartDB", "DroppableQuest", "Note", "Gossip", "Fillers"):
            with self.subTest(action=action):
                self.assertEqual(reorder.ordered_keys({"Coord": "{}", action: "true"}, actions)[0], action)
        self.assertEqual(reorder.ordered_keys({"LearnSkill": "false", "Note": '"Text"'}, actions)[0], "Note")
        self.assertEqual(reorder.ordered_keys({"FutureAction": "true", "Coord": "{}"},
                                            actions | {"FutureAction"})[0], "FutureAction")

    def test_comments_follow_fields_and_nested_payloads_stay_intact(self):
        source = '''APR.RouteQuestStepList["test"] = {
    steps = {
        {
            Coord = { x = 1, y = 2 }, --coordinate
            Zone = 1411,
            Class = "WARLOCK",
            --trainer
            LearnSkill = { allAvailable = true, npcID = 3172 },
            FutureData = { Class = "Payload", Zone = 85, _index = 7 },
            _index = 226,
        },
    },
}'''
        expected = '''APR.RouteQuestStepList["test"] = {
    steps = {
        {
            --trainer
            LearnSkill = { allAvailable = true, npcID = 3172 },
            Coord = { x = 1, y = 2 }, --coordinate
            FutureData = { Class = "Payload", Zone = 85, _index = 7 },
            Class = "WARLOCK",
            Zone = 1411,
            _index = 226,
        },
    },
}'''
        self.assertEqual(reorder.normalize_text(source), expected)
        self.assertEqual(reorder.normalize_text(expected), expected)

    def test_parallel_steps_and_metadata_scope(self):
        source = '''-- APR.RouteQuestStepList["ignored"] = { steps = { { Zone = 1 } } }
local example = [=[APR.RouteQuestStepList["ignored"] = { steps = {} }]=]
APR.RouteQuestStepList["test"] = {
    conditions = { Zone = 1, Class = "MAGE" },
    steps = { { Zone = 1, Coord = { y = 2, x = 1 }, LearnSkill = {} } },
    parallelSteps = { {
        conditions = { Zone = 2, Class = "WARLOCK" },
        steps = { { Zone = 2, Coord = {}, BuyMerchant = {} } },
    } },
}'''
        result = reorder.normalize_text(source)
        self.assertIn('conditions = { Zone = 1, Class = "MAGE" }', result)
        self.assertIn('conditions = { Zone = 2, Class = "WARLOCK" }', result)
        self.assertIn('steps = { { LearnSkill = {}, Coord = { y = 2, x = 1 }, Zone = 1, } }', result)
        self.assertIn('steps = { { BuyMerchant = {}, Coord = {}, Zone = 2, } }', result)
        self.assertEqual(source.split("\n")[:2], result.split("\n")[:2])

    def test_lua_strings_comments_separators_and_calls(self):
        source = r'''APR.RouteQuestStepList["test"] = {
    steps = { {
        ["Zone"] = 1; --[==[long comment }, { PickUp = {}]==]
        _index = 8,
        Coord = APR.convert(1, 2, 3),
        Note = { "comma, braces {}, quote\"", [=[multiline
            }, -- not a comment
        ]=] }
    } }
}'''
        result = reorder.normalize_text(source)
        self.assertIn('["Zone"] = 1; --[==[long comment }, { PickUp = {}]==]', result)
        self.assertIn('Coord = APR.convert(1, 2, 3),', result)
        self.assertEqual(reorder.normalize_text(result), result)
        runtime = LuaRuntime()
        runtime.execute('APR = {RouteQuestStepList = {}, convert = function(a,b,c) return {a,b,c} end}')
        runtime.execute(source)
        original = plain(runtime.globals().APR.RouteQuestStepList["test"])
        runtime.execute(result)
        self.assertEqual(plain(runtime.globals().APR.RouteQuestStepList["test"]), original)

    def test_line_endings_and_bom_survive(self):
        source = '\ufeffAPR.RouteQuestStepList["test"] = {\r\n    steps = { {\r\n        Zone = 1,\r\n        PickUp = { 42 },\r\n    } },\r\n}\r\n'
        result = reorder.normalize_text(source)
        self.assertTrue(result.startswith("\ufeff"))
        self.assertEqual(result.count("\r\n"), source.count("\r\n"))
        self.assertEqual(result.count("\n"), result.count("\r\n"))

    def test_ambiguous_step_fields_fail_before_writing(self):
        for body in ("Zone = 1, Zone = 2", "Zone = 1, 42", "Zone = 1, Note = function() return 1 end"):
            with self.subTest(body=body), self.assertRaises(ValueError):
                reorder.normalize_text('APR.RouteQuestStepList["test"] = { steps = { { ' + body + ' } } }')

    def test_all_existing_routes_preserve_lua_data_and_are_idempotent(self):
        originals = load_routes()
        with tempfile.TemporaryDirectory() as directory:
            formatted_paths = []
            for path in sorted((ROOT / "Routes").rglob("*.lua")):
                source = path.read_bytes().decode("utf-8")
                formatted = reorder.normalize_text(source)
                self.assertEqual(reorder.normalize_text(formatted), formatted, str(path))
                target = Path(directory) / path.relative_to(ROOT)
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(formatted.encode("utf-8"))
                formatted_paths.append(target)
            self.assertEqual(load_routes(formatted_paths).routes, originals.routes)


class RouteHookTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="apr route hook ")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.git("init", "-q")
        self.git("config", "user.name", "Route test")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "core.autocrlf", "false")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "core.hooksPath", ".githooks")
        (self.root / ".github/scripts").mkdir(parents=True)
        for name in ("fix_route_indexes.py", "reorder_route_fields.py"):
            shutil.copyfile(ROOT / ".github/scripts" / name, self.root / ".github/scripts" / name)
        (self.root / "APR-Core/utils").mkdir(parents=True)
        shutil.copyfile(ROOT / "APR-Core/utils/StepUtils.lua", self.root / "APR-Core/utils/StepUtils.lua")
        self.path = self.root / "Routes/route with spaces.lua"
        self.path.parent.mkdir()
        self.original = '''APR.RouteQuestStepList["test"] = {
    steps = { {
        Coord = { x = 1, y = 2 },
        Zone = 1411,
        LearnSkill = { npcID = 3172 },
        _index = 8,
    } },
}
'''
        self.path.write_text(self.original, encoding="utf-8", newline="")
        self.git("add", "--", "Routes/route with spaces.lua")
        # Seed an unformatted index before enabling either normalization hook.
        shutil.copytree(ROOT / ".githooks", self.root / ".githooks")
        for name in ("pre-commit", "post-index-change"):
            (self.root / ".githooks" / name).chmod(0o755)

    def git(self, *args):
        environment = os.environ.copy()
        environment["PATH"] = str(Path(sys.executable).parent) + os.pathsep + environment["PATH"]
        return subprocess.check_output(["git", *args], cwd=self.root, env=environment, stderr=subprocess.STDOUT)

    def expected(self):
        return reorder.normalize_text(indexes.normalize_text(self.original)).encode("utf-8")

    def test_add_formats_staged_route_and_matching_working_copy(self):
        self.git("add", "--", "Routes/route with spaces.lua")
        self.assertEqual(self.git("show", ":Routes/route with spaces.lua"), self.expected())
        self.assertEqual(self.path.read_bytes(), self.expected())
        self.assertEqual(self.git("diff", "--", "Routes"), b"")

    def test_add_unrelated_file_preserves_unstaged_route_edits(self):
        working = self.original.replace("LearnSkill =", '-- unstaged text\n        LearnSkill =')
        self.path.write_text(working, encoding="utf-8", newline="")
        (self.root / "unrelated.txt").write_text("unrelated", encoding="utf-8")
        self.git("add", "--", "unrelated.txt")
        self.assertEqual(self.git("show", ":Routes/route with spaces.lua"), self.expected())
        self.assertEqual(self.path.read_bytes(), working.encode("utf-8"))

    def test_commit_formats_staged_route_and_matching_working_copy(self):
        self.git("commit", "-qm", "Format route")
        self.assertEqual(self.git("show", "HEAD:Routes/route with spaces.lua"), self.expected())
        self.assertEqual(self.path.read_bytes(), self.expected())
        self.assertEqual(self.git("status", "--porcelain", "--", "Routes"), b"")

    def test_commit_preserves_unstaged_edits_and_unstaged_routes(self):
        working = self.original.replace("LearnSkill =", '-- unstaged text\n        LearnSkill =')
        self.path.write_text(working, encoding="utf-8", newline="")
        other = self.root / "Routes/unstaged.lua"
        other.write_text(self.original, encoding="utf-8", newline="")
        self.git("commit", "-qm", "Format partially staged route")
        self.assertEqual(self.git("show", "HEAD:Routes/route with spaces.lua"), self.expected())
        self.assertEqual(self.path.read_bytes(), working.encode("utf-8"))
        self.assertEqual(other.read_bytes(), self.original.encode("utf-8"))

    def test_commit_preserves_crlf_when_git_stores_lf(self):
        self.git("config", "core.autocrlf", "true")
        self.path.write_bytes(self.original.replace("\n", "\r\n").encode("utf-8"))
        self.git("add", "--", "Routes/route with spaces.lua")
        self.git("commit", "-qm", "Format Windows route")
        self.assertEqual(self.git("show", "HEAD:Routes/route with spaces.lua"), self.expected())
        self.assertEqual(self.path.read_bytes(), self.expected().replace(b"\n", b"\r\n"))
        self.assertEqual(self.git("status", "--porcelain", "--", "Routes"), b"")

    def test_manual_no_stage_leaves_index_untouched(self):
        subprocess.run([sys.executable, str(ROOT / ".github/scripts/reorder_route_fields.py"),
                        "--staged", "--no-stage"], cwd=self.root, check=True, capture_output=True)
        self.assertEqual(self.git("show", ":Routes/route with spaces.lua"), self.original.encode("utf-8"))
        self.assertEqual(self.path.read_bytes(), reorder.normalize_text(self.original).encode("utf-8"))
