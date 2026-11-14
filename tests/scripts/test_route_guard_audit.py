"""Guard relationships use invented routes and independent character witnesses."""

import unittest

from lupa.lua51 import LuaRuntime

from tests.routes.route_loader import ROOT, RouteCatalog, load_routes
from tools.validation.instrument_lua import clean
from tools.validation.route_guard_audit import audit_routes, quest_links


def seq(*entries):
    return dict(enumerate(entries, 1))


class GuardAuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base = load_routes(paths=[])

    def audit(self, steps=None, **route):
        declaration = {"label": "Invented", "steps": seq(*(steps or [])), **route}
        return audit_routes(RouteCatalog({"synthetic": declaration}, {}, self.base.enums, self.base.profiles))

    def test_faction_is_inherited_without_repetition(self):
        self.assertEqual([], self.audit([
            {"PickUp": seq(4201), "Faction": "Alliance"}, {"Done": seq(4201)}
        ], conditions={"Faction": "Alliance"}))

    def test_leaked_quest_action_has_opposite_faction_witness(self):
        results = self.audit([{ "PickUp": seq(4201), "Faction": "Alliance"},
                              {"Qpart": {4201: seq(1)}}])
        self.assertEqual(["guard.link-coverage"], [r["rule"] for r in results])
        self.assertNotEqual("Alliance", results[0]["evidence"]["witness"]["Faction"])
        self.assertEqual("steps[2]", results[0]["path"])

    def test_all_pickup_alternatives_form_coverage(self):
        self.assertEqual([], self.audit([
            {"PickUp": seq(4201), "Faction": "Alliance"},
            {"PickUp": seq(4201), "Not": {"Faction": "Alliance"}},
            {"Done": seq(4201)}]))

    def test_quest_possession_is_a_valid_guard_not_a_required_copy(self):
        self.assertEqual([], self.audit([
            {"PickUp": seq(4201), "Faction": "Alliance", "IsQuestNotOnQuest": 4201},
            {"Done": seq(4201), "IsQuestOnQuest": 4201}]))

    def test_anyof_with_dynamic_arm_prevents_false_contradiction(self):
        self.assertEqual([], self.audit([{"Waypoint": 1, "Faction": "Horde",
            "AnyOf": seq({"Faction": "Alliance"}, {"IsQuestOnQuest": 4201})}]))

    def test_class_alias_and_classnot_contradiction(self):
        results = self.audit([{"UseSpell": {"spellID": 7301}, "Class": "MAGE", "ClassNot": 8}])
        self.assertEqual(["guard.step-contradiction"], [r["rule"] for r in results])

    def test_fractional_level_exact_boundaries_and_unknown_profiles(self):
        results = self.audit([
            {"Waypoint": 1, "BeLvl": 4.5, "MinLevel": 5},
            {"Waypoint": 2, "MinLevel": 4.5, "MaxLevel": 4.5},
            {"Waypoint": 3, "Level": "unknown-profile", "MaxLevel": 1}])
        self.assertEqual(["steps[1]"], [r["path"] for r in results])

    def test_route_entry_level_and_class_advice_do_not_imprison_steps(self):
        self.assertEqual([], self.audit([{"Waypoint": 1, "Class": 1, "MinLevel": 30}],
                                       conditions={"Class": 8, "MaxLevel": 20}))

    def test_parallel_conditions_and_scenarios_are_walked(self):
        results = self.audit(scenarios=seq({"steps": seq({"Waypoint": 1, "Faction": "Horde"})}),
            conditions={"Faction": "Alliance"}, parallelSteps=seq({
                "conditions": {"Class": 8}, "steps": seq({"Waypoint": 2, "ClassNot": 8})}))
        self.assertEqual({"scenarios[1].steps[1]", "parallelSteps[1].steps[1]"}, {r["path"] for r in results})
        self.assertEqual({"error"}, {r["severity"] for r in results})

    def test_boolean_route_context_does_not_infer_faction_from_race(self):
        self.assertEqual([], self.audit([{"Waypoint": 1, "Faction": "Horde"}],
            conditions={"AnyOf": seq({"Race": "InventedRace"}, {"Faction": "Alliance"})}))

    def test_not_and_allof_preserve_contradictions(self):
        results = self.audit([{"Waypoint": 1, "AllOf": seq({"Faction": "Horde"},
                    {"Not": {"Faction": "Horde"}})}])
        self.assertEqual(["guard.step-contradiction"], [r["rule"] for r in results])

    def test_named_and_numeric_races_are_not_assumed_distinct(self):
        self.assertEqual([], self.audit([{"Waypoint": 1, "Race": "InventedRace",
                                         "AllOf": seq({"Race": 999})}]))

    def test_button_navigation_and_purchase_quest_links(self):
        results = self.audit([
            {"PickUp": seq(4201), "Class": 8},
            {"Button": {"4201-1": 8101}, "Waypoint": 1},
            {"BuyMerchant": seq({"itemID": 8102, "quantity": 1, "questID": 4201})}])
        self.assertEqual(1, len(results))
        self.assertEqual({"steps[2]", "steps[3].BuyMerchant[1]"},
                         {a["path"] for a in results[0]["evidence"]["affected_actions"]})

    def test_learned_spell_and_consuming_action_are_linked(self):
        results = self.audit([
            {"LearnSkill": {"spellID": 7301}, "Class": 8},
            {"UseSpell": {"spellID": 7301}}])
        self.assertEqual(["guard.link-coverage"], [r["rule"] for r in results])
        self.assertEqual({"spellID": 7301}, results[0]["evidence"]["link"])

    def test_optional_reused_supply_list_is_only_a_warning(self):
        results = self.audit([{"SkipForLvl": 5, "BuyMerchant": seq({"itemID": 8101,
            "quantity": 1, "optional": True, "conditions": {"MinLevel": 10}})}])
        self.assertEqual([("warning", "guard.optional-entry-unreachable")],
                         [(r["severity"], r["rule"]) for r in results])

    def test_parallel_possession_guards_its_children(self):
        self.assertEqual([], self.audit([{"PickUp": seq(4201), "Faction": "Alliance"}],
            parallelSteps=seq({"conditions": {"IsQuestOnQuest": 4201},
                               "steps": seq({"Qpart": {4201: seq(1)}})})))

    def test_contradictory_authored_advice_is_warning(self):
        results = self.audit([{"Waypoint": 1}], conditions={"Class": 8, "ClassNot": 8})
        self.assertEqual([("warning", "guard.route-recommendation-contradiction")],
                         [(r["severity"], r["rule"]) for r in results])

    def test_different_quest_pickup_is_not_a_producer(self):
        results = self.audit([{"PickUp": seq(4201), "Faction": "Alliance"},
                              {"PickUp": seq(4202), "Qpart": {4201: seq(1)}}])
        self.assertEqual(["guard.link-coverage"], [r["rule"] for r in results])

    def test_negated_unknown_does_not_prove_route_conflict(self):
        self.assertEqual([], self.audit([{"Waypoint": 1, "Faction": "Horde"}],
            conditions={"Not": {"Faction": "Horde", "Race": "InventedRace"}}))

    def test_witness_prefers_an_explicit_positive_source_combination(self):
        results = self.audit([
            {"PickUp": seq(4201), "Faction": "Alliance"}, {"Done": seq(4201)},
            {"Waypoint": 1, "Faction": "Horde", "Race": "InventedRace", "Class": 8}])
        evidence = results[0]["evidence"]
        self.assertEqual({"Faction": "Horde", "Race": "InventedRace", "Class": 8}, evidence["witness"])
        self.assertEqual("source-declared-combination", evidence["witness_evidence"]["status"])
        self.assertEqual("steps[3]", evidence["witness_evidence"]["source"]["path"])
        self.assertEqual("unknown", evidence["witness_evidence"]["server_playability"])

    def test_symbolic_other_is_explicitly_unknown(self):
        results = self.audit([{"PickUp": seq(4201), "Race": "InventedRace"}, {"Done": seq(4201)}])
        self.assertEqual("unknown", results[0]["evidence"]["witness_evidence"]["status"])
        self.assertEqual("unknown", results[0]["evidence"]["witness_evidence"]["server_playability"])

    def test_button_labels_do_not_invent_quest_links(self):
        self.assertEqual({4201, 4202}, quest_links({
            "Button": {"custom-label": 8101, "4201-2": 8102, "4203-custom": 8103},
            "SpellButton": {"custom-spell": 7301, "4202": 7302, "-4204": 7303}}))
        self.assertEqual([], self.audit([
            {"PickUp": seq(4201), "Faction": "Alliance"},
            {"Waypoint": 1, "Button": {"custom-label": 8101}, "SpellButton": {"custom": 7301}}]))

    def test_profession_identifiers_are_not_assumed_interchangeable(self):
        self.assertEqual([], self.audit([
            {"LearnProfession": 9101, "Class": 8},
            {"SkillGoal": {"skillID": 9101, "rank": 50}}]))

    def test_profession_spell_can_link_to_an_explicit_spell_action(self):
        results = self.audit([{ "LearnProfession": 9101, "Class": 8},
                              {"UseSpell": {"spellID": 9101}}])
        self.assertEqual([{"spellID": 9101}], [r["evidence"]["link"] for r in results])

    def test_optional_fillers_do_not_restrict_unrelated_primary_actions(self):
        self.assertEqual({4202}, quest_links({"Fillers": {4201: seq(1)}, "Qpart": {4202: seq(1)}}))
        self.assertEqual([], self.audit([
            {"PickUp": seq(4201), "Faction": "Alliance"},
            {"Waypoint": 1, "Fillers": {4201: seq(1)}}]))
        results = self.audit([
            {"PickUp": seq(4201), "Faction": "Alliance"},
            {"Done": seq(4201), "Fillers": {4201: seq(1)}}])
        self.assertEqual(["guard.link-coverage"], [r["rule"] for r in results])

    def test_real_filler_handler_hides_absent_quest_but_primary_reports_it(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
            function LibStub() return {GetLocale = function() return {} end} end
            local function noop() end
            local count = {fillers = 0, missing = 0, advanced = 0}
            APR = {stepHandlers = {}, currentStep = {}, PlayerID = "synthetic", ActiveRoute = "invented",
                ActiveQuests = {}, QUEST_STATUS = {COMPLETE = "complete"}, MaxLevel = 60,
                Buff = {RemoveAllBuffIcon = noop}, Debug = noop,
                fillersFrame = {AddFillerStep = function() count.fillers = count.fillers + 1 end},
                NextQuestStep = function() count.advanced = count.advanced + 1 end,
                UpdateNextStep = function() count.advanced = count.advanced + 1 end,
                HandleMissingQuest = function() count.missing = count.missing + 1 end,
                Contains = function() return false end,
                TrackQuest = noop}
            APR.currentStep.AddQuestStepsWithDetails = noop
            APRData = {synthetic = {BonusSkips = {}}}
            C_QuestLog = {IsQuestFlaggedCompleted = function() return false end}
            function UnitLevel() return 12 end
            function APR:GetQuestTextForProgressBar() return "Synthetic objective" end
            getn = table.getn
            function counts() return count.fillers, count.missing, count.advanced end
        ''')
        for name in ("StepInstructions.lua", "StepQuestHandlers.lua"):
            lua.execute(clean((ROOT / "APR-Core/features/questing" / name).read_text(encoding="utf-8")))
        lua.execute('APR.stepHandlers.RenderRequirements({Waypoint = 1, Fillers = {[4201] = {1}}}, true, 1)')
        self.assertEqual((0, 0, 0), lua.globals().counts())
        lua.execute('APR.stepHandlers.Qpart({Qpart = {[4201] = {1}}, Fillers = {[4201] = {1}}}, true, 1)')
        self.assertEqual((0, 1, 0), lua.globals().counts())
        lua.execute('APR.stepHandlers.Done({Done = {4201}, Fillers = {[4201] = {1}}}, true, 1)')
        self.assertEqual((0, 2, 0), lua.globals().counts())
        lua.execute('APR.ActiveQuests[4201] = {objectives = {{status = "active"}}}; APR.stepHandlers.RenderRequirements({Fillers = {[4201] = {1}}}, true, 1)')
        self.assertEqual((1, 2, 0), lua.globals().counts())
        # Pre-acceptance collection has an inventory completion contract. The
        # quest label only supplies a completed-quest shortcut, not ownership.
        lua.execute('''
            APR.ActiveQuests = {}
            collected = 0
            function APR:GetCollectionRequiredQuantity(rule) return rule.quantity end
            function APR:GetCollectionItemCount() return collected end
            C_Item = {GetItemInfo = function() return "Synthetic book" end}
            format = function(_, name) return name end
            APR.currentStep.AddQuestSteps = function() end
            APR.stepHandlers.RenderRequirements({LootItems = {{itemID = 8101, quantity = 1, questID = 4201}}}, true, 1)
        ''')
        self.assertEqual((1, 2, 0), lua.globals().counts())
        lua.execute('collected = 1; APR.stepHandlers.RenderRequirements({LootItems = {{itemID = 8101, quantity = 1, questID = 4201}}}, true, 1)')
        self.assertEqual((1, 2, 1), lua.globals().counts())

    def test_real_class_branch_keeps_planned_actions_and_external_quests(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
            APR = {Faction = "Alliance", ClassName = "MAGE", ClassId = 8}
            function LibStub() return {GetLocale = function() return {} end} end
            local owned, completed = false, false
            function context(classID, onQuest, rewarded)
                APR.ClassId = classID
                owned, completed = onQuest, rewarded
            end
            C_QuestLog = {IsOnQuest = function() return owned end,
                         IsQuestFlaggedCompleted = function() return completed end}
            function tContains(t, value)
                for _, item in pairs(t) do if item == value then return true end end
                return false
            end
            branch = {AnyOf = {{Class = {8}}, {IsQuestOnQuest = 4201}, {IsQuestCompleted = 4201}}}
        ''')
        lua.execute(clean((ROOT / "APR-Core/utils/RouteUtils.lua").read_text(encoding="utf-8")))
        accepted = lambda: lua.eval('APR:AreConditionalFiltersMet(branch)')
        self.assertTrue(accepted())  # Planned class keeps missing-quest diagnostics.
        lua.execute('context(7, false, false)')
        self.assertFalse(accepted())
        lua.execute('context(7, true, false)')
        self.assertTrue(accepted())  # Another class can finish an external pickup.
        lua.execute('context(7, false, true)')
        self.assertTrue(accepted())  # Completed quests retain their normal advance.

    def test_collecting_the_pickup_item_precedes_its_possession_guard(self):
        self.assertEqual([], self.audit([
            {"LootItems": seq({"itemID": 8101, "quantity": 1, "questID": 4201})},
            {"PickUp": seq(4201), "Faction": "Alliance", "AnyOf": seq(
                {"ItemCount": {"itemID": 8101, "count": 1}}, {"IsQuestOnQuest": 4201})}]))
        # An unrelated item, a negated gate, or a later collection cannot use
        # the pre-acquisition proof to suppress a useful linked-action warning.
        for guard in ({"ItemCount": {"itemID": 8102, "count": 1}},
                      {"Not": {"ItemCount": {"itemID": 8101, "count": 1}}}):
            results = self.audit([
                {"LootItems": seq({"itemID": 8101, "quantity": 1, "questID": 4201})},
                {"PickUp": seq(4201), "Faction": "Alliance", **guard}])
            self.assertEqual(["guard.link-coverage"], [r["rule"] for r in results])
        results = self.audit([
            {"PickUp": seq(4201), "Faction": "Alliance", "ItemCount": {"itemID": 8101, "count": 1}},
            {"LootItems": seq({"itemID": 8101, "quantity": 1, "questID": 4201})}])
        self.assertEqual(["guard.link-coverage"], [r["rule"] for r in results])


if __name__ == "__main__":
    unittest.main()
