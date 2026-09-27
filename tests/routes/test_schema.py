"""Positive and negative examples of the public route declaration language."""

from copy import deepcopy
from pathlib import Path
import re
import tempfile
import unittest

from lupa.lua51 import LuaError

from tests.routes.route_loader import ROOT, load_routes
from tests.routes.route_schema import InvalidRoute, RouteSchema


def seq(*values):
    return dict(enumerate(values, 1))


def examples():
    """Representative declarations, independent of any real guide or expansion."""
    values = {}
    for names, value in (
        ("ChromiePick DropQuest ExitTutorial GetFP GroupTask LearnProfession LeaveQuest NpcDismount "
         "SetHS UseDalaHS UseFlightPath UseGarrisonHS UseHS WarMode Waypoint DenyNPC MerchantNPC "
         "RaidIcon SpellTrigger Zone NodeID QuestLineSkip ExtraLine Gossip Brewery SparringRing "
         "InterfaceVersion InterfaceVersionExact HasAchievement DontHaveAchievement HasAura "
         "DontHaveAura HasSpell IsQuestOnQuest IsQuestNotOnQuest IsQuestCompleted IsQuestUncompleted "
         "InVehicle PickedLoa _index", 1),
        ("Bloodlust Boat DeathSkip Dontskipvid ExtraActionB InstanceQuest IsAdventureMap IsCampaignQuest "
         "MountVehicle NoArrow NoAutoFlightMap NoAutoAccept NoAutoTurnIn NonSkippableWaypoint ResetRoute "
         "RouteCompleted SingleWaypointDisplayDistance SpecialETAHide UseGlider VehicleExit Hardcore AlliedRace", True),
        ("Done DoneDB PickUp PickUpDB QpartDB WaypointDB LeaveQuests GossipOptionIDs Zones OnlyInZones "
         "SkipInZones DontHaveSpell IsQuestReadyForTurnIn IsOneOfQuestsCompleted IsOneOfQuestsUncompleted "
         "IsOneOfQuestsCompletedOnAccount IsOneOfQuestsUncompletedOnAccount IsQuestsCompleted "
         "IsQuestsUncompleted IsQuestsCompletedOnAccount IsQuestsUncompletedOnAccount", seq(1, 2)),
        ("Range ETA EmoteETA GossipETA Level MinLevel MaxLevel SkipForLvl BeLvl Grind", 12.5),
        ("Qpart QpartPart Fillers", {123: seq(1, 2)}),
        ("Name _comment ExtraLineText ExtraLineText12 TrigText TrigText12", "Example"),
        ("Reputation ReputationLevel SkipForReputation", {"factionID": 1, "level": 4, "type": "standard"}),
        ("EnterInstance LeaveInstance EnterScenario DoScenario LeaveScenario TakePortal", {"mapID": 1, "questID": 2}),
        ("BuyMerchant LootItems", seq({"itemID": 1, "quantity": 2, "questID": 3})),
        ("SellItems BankDeposit BankWithdraw DestroyItems", {"items": seq(1, {"itemID": 2, "text": "Item"}), "npcID": 3}),
    ):
        values.update((key, deepcopy(value)) for key in names.split())
    values.update({
        "Faction": "Horde", "Race": seq("Orc", "Troll"), "Class": seq("WARRIOR", 3),
        "ClassNot": "MAGE", "ClassSpec": 253, "Gender": 3, "Event": "Remix",
        "Money": {"copper": 10, "operator": "<"},
        "ItemCount": {"itemIDs": seq(1, 2), "count": 2, "includeBank": True, "includeUsableToys": False},
        "EquippedItemStat": {"slot": 16, "stat": "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "value": 3.5,
                             "operator": "<", "precision": 1, "allowMissing": False},
        "EquippedItem": {"slot": 16, "itemID": 123, "invert": True},
        "Collection": {"itemID": 123, "quantity": 2},
        "Skill": {"skill": "cooking", "rank": 50, "operator": ">=", "maximum": True},
        "AnyOf": seq({"Class": "MAGE"}, {"Not": {"HasSpell": 123}}),
        "AllOf": seq({"IsQuestCompleted": 1}, {"AnyOf": seq({"MinLevel": 5}, {"Hardcore": True})}),
        "Not": {"AllOf": seq({"HasAura": 1}, {"Money": {"copper": 10}})},
        "Note": seq("First instruction", "Second instruction"), "PreviewImages": seq("image.jpg"),
        "Coord": {"x": -42.5, "y": 123.5}, "Coords": seq({"Zone": 1, "x": 1, "y": 2}),
        "ZoneStepTrigger": {"x": 1, "y": 2, "Range": 10},
        "Button": {"123-1": 123}, "SpellButton": {"123-1": "Spell"},
        "UseItem": {"itemID": 123, "itemSpellID": 456}, "UseSpell": {"spellID": 123},
        "Treasure": {"questID": 123, "itemID": 456},
        "Achievement": {"achievementID": 123, "criteriaID": 456, "criteriaIndex": 1, "questID": 2},
        "Scenario": {"scenarioID": 123, "stepID": 456, "criteriaID": 0, "criteriaIndex": 1, "questID": 2},
        "Group": {"questID": 123, "Number": 3}, "DroppableQuest": {"Qid": 123, "MobId": 456, "Text": "Target"},
        "Buffs": seq({"spellId": 123, "tooltipMessage": "Buff"}),
        "LootMoney": {"copper": 10, "includeEquipped": True, "equippedSlots": seq(16, 17)},
        "SpellETA": {"spellID": 123, "seconds": 3}, "Emote": {"emote": "salute", "npcID": 0, "manual": True},
        "EquipItem": {"itemID": 123, "slot": 16}, "TameBeast": {"npcID": 123, "spellID": 1515},
        "LearnSkill": {"spellIDs": seq(123, 456), "npcID": 789},
    })
    return values


class RouteSchemaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = load_routes([])
        cls.schema = RouteSchema(cls.catalog)

    def test_every_declared_option_has_positive_and_negative_examples(self):
        data = examples()
        self.assertEqual(set(data), set(self.schema.step_fields) |
                         {"ExtraLineText", "ExtraLineText12", "TrigText", "TrigText12"})
        for name, value in data.items():
            with self.subTest(option=name):
                self.schema.step({name: value}, "step")
                with self.assertRaises(InvalidRoute):
                    self.schema.step({name: None}, "step")
                with self.assertRaisesRegex(InvalidRoute, "unknown field"):
                    self.schema.step({name + "Typo": value}, "step")

    def test_all_conditions_in_nested_and_parallel_contexts(self):
        for name in self.schema.condition_fields:
            value = examples()[name]
            with self.subTest(condition=name):
                condition = {"AnyOf": seq({"AllOf": seq({"Not": {name: value}})})}
                self.schema.validate("test", {"label": "Test", "steps": {}, "parallelSteps": seq(
                    {"conditions": condition, "steps": seq({"Note": "Example"})})})
                with self.assertRaises(InvalidRoute):
                    self.schema.condition({"Not": {name: None}}, "condition")

    def test_nested_objects_reject_unknown_fields(self):
        def mutations(value):
            if isinstance(value, dict):
                if any(isinstance(key, str) for key in value):
                    yield {**deepcopy(value), "unknownOption": True}
                for key, nested in value.items():
                    for replacement in mutations(nested):
                        yield {**deepcopy(value), key: replacement}
        for name, value in examples().items():
            for mutated in mutations(value):
                with self.subTest(option=name), self.assertRaises(InvalidRoute):
                    self.schema.step({name: mutated}, "step")

    def test_metadata_prefabs_and_scenarios(self):
        route = {"label": "Example", "category": "Campaign", "expansion": "Midnight", "gameVersion": "retail",
                 "mapID": 1, "conditions": {"Level": 10, "AnyOf": seq({"Hardcore": False})},
                 "legacyLabels": seq("Old name"), "autoStartOnMap": True, "notSkippable": True,
                 "hiddenFromSelection": True, "temporary": True, "sojournerAchievementID": 1, "delve": {},
                 "steps": seq({"Note": "Example"}), "scenarios": seq({"label": "Scenario", "scenarioID": 1,
                     "index": 1, "steps": seq({"Note": "Example"})}),
                 "parallelSteps": seq({"conditions": {"Class": 1}, "steps": seq({"Note": "Example"})}),
                 "requiredRoute": seq("previous"), "nextRoute": seq("next", {"route": "branch", "conditions": {"Race": "Orc"}}),
                 "prefab": {"leveling": 1, "speedrun": {"index": 2, "conditions": {"MinLevel": 10}}}}
        self.assertEqual(set(route), set(self.schema.route_fields))
        self.schema.validate("test", route)
        for key in route:
            with self.subTest(field=key), self.assertRaises(InvalidRoute):
                self.schema.validate("test", {**route, key: None})
        for patch in ({"extRoute": {}}, {"conditions": {"Not": {"HasSpell": 1}}},
                      {"prefab": {"leveling": {"index": 1, "conditons": {}}}},
                      {"scenarios": seq({"scenarioID": 1, "steps": seq({"Unknown": True})})},
                      {"nextRoute": seq({"route": "next", "conditions": {"Done": seq(1)}})}):
            with self.subTest(patch=patch), self.assertRaises(InvalidRoute):
                self.schema.validate("test", {**route, **patch})

    def test_supported_alternative_forms_and_empty_placeholders(self):
        for step in ({"LearnSkill": {"allAvailable": True}}, {"LearnSkill": {"spellID": 1}},
                     {"SellItems": {"junk": True}}, {"BankDeposit": seq(1, 2)},
                     {"Money": {"copper": 0, "operator": "~="}}, {"ItemCount": {"itemID": 1, "count": 0}},
                     {"Skill": {"skillID": 171}}, {"Skill": {"name": "Localized profession"}},
                     {"TakePortal": {"mapID": 1}}, {"TakePortal": {"questID": 1}},
                     {"SpellETA": {"itemID": 1, "seconds": 2}}, {"DontHaveSpell": 1},
                     {"Coords": {84: {"x": 1, "y": 2}, 85: {"Coord": {"x": 3, "y": 4}}}},
                     {"Coord": seq({"mapID": 84, "Coord": {"x": 1, "y": 2}})},
                     {"LootItems": seq({"itemID": 123})},
                     {"Note": "Text", "ExtraLineText2": seq("First", "Second")},
                     {"Grind": {"level": 10, "xp": -100}}, {"PickUp": {}, "Qpart": {1: {}}},
                     {"AnyOf": {}, "AllOf": {}}):
            with self.subTest(step=step):
                self.schema.step(step, "step")
        for profile in self.catalog.profiles:
            self.schema.step({"MinLevel": profile}, "step")

    def test_invalid_types_ranges_required_fields_and_lists(self):
        for step in ({"PickUp": {2: 1}}, {"PickUp": {"1": 1}}, {"PickUp": seq(True)},
                     {"Coord": {"x": 1}}, {"Coord": {"x": float("nan"), "y": 1}},
                     {"Coord": {"x": 1, "y": float("inf")}}, {"UseItem": {"questID": 1}},
                     {"Qpart": {"123": seq(1)}}, {"Button": {"123-bad": 1}},
                     {"EquipItem": {"itemID": 1, "slot": 20}}, {"Class": "MAGGE"},
                     {"ClassSpec": 999999}, {"MinLevel": "missing-profile"}, {"MinLevel": {"level": 10, "xpp": 1}},
                     {"AnyOf": seq({"Done": seq(1)})}, {"Not": {"Money": {"copper": 1, "operator": "="}}},
                     {"Money": {"copper": -1}}, {"ItemCount": {"count": 1}}, {"TakePortal": {}},
                     {"LearnSkill": {"allAvailable": False}}, {"SellItems": {"junk": False}},
                     {"NoArrow": 1}, {"PreviewImages": "image.jpg"}, {"TrigTextBad": "text"}):
            with self.subTest(step=step), self.assertRaises(InvalidRoute):
                self.schema.step(step, "step")

    def test_schema_covers_engine_condition_and_primary_action_names(self):
        sources = "\n".join((ROOT / path).read_text(encoding="utf8") for path in
                            ("APR-Core/utils/RouteUtils.lua", "APR-Core/utils/RouteConditions.lua"))
        condition_names = set(re.findall(r"\b(?:conditions|c)\.([A-Z]\w*)", sources)) - {"WarMode"}
        self.assertEqual(condition_names, set(self.schema.condition_fields))
        source = (ROOT / "APR-Core/utils/StepUtils.lua").read_text(encoding="utf8")
        declarations = re.findall(r"APR\.(?:main|secondary)StepOptions\s*=\s*\{(.*?)\}", source, re.S)
        self.assertEqual(len(declarations), 2)
        actions = set(re.findall(r'"(\w+)"', " ".join(declarations)))
        self.assertFalse(actions - self.schema.step_fields.keys(), "New engine actions need a schema rule")

    def test_loader_rejects_lua_errors_unknown_constants_globals_and_duplicate_routes(self):
        for source in ("APR.RouteQuestStepList['x'] = {", "APR.RouteQuestStepList['x'] = {label = missing}",
                       "APR.RouteQuestStepList['x'] = {conditions = {Class = APR.Classes.Magge}}",
                       "APR.RouteQuestStepList['x'] = {}; APR.RouteQuestStepList['x'] = {}",
                       "APR.RouteQuestStepList['x'] = {steps = function() end}"):
            with self.subTest(source=source), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "route.lua"
                path.write_text(source, encoding="utf8")
                with self.assertRaises((ValueError, LuaError)):
                    load_routes([path])

    def test_loader_preserves_unknown_fields_for_schema_errors(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "route.lua"
            path.write_text('APR.RouteQuestStepList["test"] = {label="Test", steps={{AnyOf={{Money={coppr=1}}}}}}', encoding="utf8")
            catalog = load_routes([path])
            with self.assertRaisesRegex(InvalidRoute, r"test.steps.*AnyOf.*Money"):
                RouteSchema(catalog).validate("test", catalog.routes["test"])
