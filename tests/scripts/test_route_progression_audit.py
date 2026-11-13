"""Progression contracts on invented routes and the real filter/action code."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime

from tests.routes.route_loader import RouteCatalog
from tools.validation.instrument_lua import clean
from tools.validation.route_progression_audit import (
    ConditionModel, analyze, atom, audit_routes, both, completion_analysis, negate,
)


ROOT = Path(__file__).resolve().parents[2]


def catalog(routes=None):
    enums = {name: {} for name in (
        "CATEGORIES", "EXPANSIONS", "PREFAB_TYPES", "GAME_VERSIONS", "RACES",
        "Classes", "Specs", "EVENTS", "REPUTATION_TYPE", "REPUTATION_STANDING")}
    enums["Classes"] = {"Warrior": 1, "Mage": 8}
    return RouteCatalog(routes or {}, {}, enums, set())


class ProgressionAuditTests(unittest.TestCase):
    def setUp(self):
        self.model = ConditionModel(catalog())

    def status(self, condition):
        return analyze(self.model.expression(condition)).status

    def audit(self, *steps, **metadata):
        return audit_routes(catalog({"invented": {"label": "Invented", "steps": dict(enumerate(steps, 1)), **metadata}}))

    def rules(self, *steps, **metadata):
        return {finding["rule"] for finding in self.audit(*steps, **metadata)}

    def test_nested_logic_and_numeric_boundaries(self):
        self.assertEqual("unsatisfiable", self.status({"MinLevel": 12, "SkipForLvl": 12}))
        self.assertEqual("satisfiable", self.status({"MinLevel": 12, "MaxLevel": 12}))
        self.assertEqual("satisfiable", self.status({"BeLvl": 12.5, "MaxLevel": 12.75}))
        self.assertEqual("unsatisfiable", self.status({"BeLvl": 12.5, "MinLevel": 13}))
        self.assertEqual("unsatisfiable", self.status({"AnyOf": {}}))
        self.assertEqual("satisfiable", self.status({"Not": {"AnyOf": {}}}))
        self.assertEqual("unsatisfiable", self.status({"AllOf": {
            1: {"Faction": "Horde"}, 2: {"Not": {"Faction": "Horde"}}}}))
        self.assertEqual("satisfiable", self.status({"Faction": "Horde", "AnyOf": {
            1: {"Faction": "Alliance"}, 2: {"MinLevel": 4}}}))

    def test_class_alias_race_and_quest_logic(self):
        self.assertEqual("satisfiable", self.status({"Class": "WARRIOR", "AllOf": {1: {"Class": 1}}}))
        self.assertEqual("unsatisfiable", self.status({"Class": 1, "ClassNot": "WARRIOR"}))
        self.assertEqual("unsatisfiable", self.status({"Race": "Human", "AllOf": {1: {"Race": "Orc"}}}))
        self.assertEqual("satisfiable", self.status({"Race": "Human", "AllOf": {1: {"Race": 1}}}))
        self.assertEqual("unsatisfiable", self.status({"IsQuestOnQuest": 41, "IsQuestNotOnQuest": 41}))
        self.assertEqual("unsatisfiable", self.status({"IsOneOfQuestsUncompleted": {1: 41, 2: 42}, "IsQuestCompleted": 41}))
        # IsQuestsUncompleted negates ALL completed; it is not ALL incomplete.
        self.assertEqual("satisfiable", self.status({"IsQuestsUncompleted": {1: 41, 2: 42}, "IsQuestCompleted": 41}))
        self.assertEqual("unsatisfiable", self.status({"HasSpell": 71, "DontHaveSpell": {1: 71, 2: 72}}))

    def test_inventory_skill_reputation_and_opaque_states(self):
        self.assertEqual("unsatisfiable", self.status({"Skill": {"skillID": 55, "rank": 9}, "AllOf": {
            1: {"Skill": {"skillID": 55, "rank": 9, "operator": "<"}}}}))
        self.assertEqual("unsatisfiable", self.status({"ItemCount": {"itemID": 8, "count": 3}, "Not": {
            "ItemCount": {"itemID": 8, "count": 2}}}))
        self.assertEqual("satisfiable", self.status({"ItemCount": {"itemID": 8, "count": 3, "includeBank": True}, "Not": {
            "ItemCount": {"itemID": 8, "count": 2}}}))
        self.assertEqual("unsatisfiable", self.status({"ReputationLevel": {"factionID": 6, "level": 4}, "SkipForReputation": {"factionID": 6, "level": 4}}))
        self.assertEqual("satisfiable", self.status({"Level": "unknown-profile", "HasAura": 82}))
        self.assertEqual("unsatisfiable", analyze(both(atom("skill:5", ">", 2), atom("skill:5", "<", 3))).status)

    def test_budget_is_unknown_instead_of_false_proof(self):
        condition = {"AllOf": {i: {"AnyOf": {1: {"HasAura": i}, 2: {"DontHaveAura": i}}} for i in range(1, 12)}}
        self.assertEqual("unknown", self.status(condition))
        self.assertIn("progression.analysis-budget", self.rules({"Note": "Observe", **condition}))

    def test_unreachable_is_not_called_a_gameplay_deadlock(self):
        findings = self.audit({"Note": "Observe", "MinLevel": 8, "MaxLevel": 7})
        self.assertEqual(1, len(findings))
        self.assertEqual("warning", findings[0]["severity"])
        self.assertEqual("unreachable", findings[0]["evidence"]["classification"])
        self.assertEqual("steps[1]", findings[0]["path"])

    def test_goals_require_unmet_state_and_external_quest_is_legitimate(self):
        rules = self.rules(
            {"SkillGoal": {"skillID": 5, "rank": 10}, "Skill": {"skillID": 5, "rank": 10}},
            {"Reputation": {"factionID": 6, "level": 4}, "ReputationLevel": {"factionID": 6, "level": 4}},
            {"LearnProfession": 91, "HasSpell": 91},
            {"LootItems": {1: {"itemID": 3, "quantity": 2}}, "ItemCount": {"itemID": 3, "count": 2}},
            {"PickUp": {1: 40}, "IsQuestOnQuest": 40},
        )
        self.assertEqual({"progression.goal-already-required", "progression.learning-already-required",
                          "progression.collection-already-required", "progression.pickup-already-required"}, rules)
        self.assertEqual(set(), self.rules(
            {"SkillGoal": {"skillID": 5, "rank": 10}, "Skill": {"skillID": 5, "rank": 1}},
            {"Qpart": {40: {1: 1}}, "IsQuestOnQuest": 40},
            {"Done": {1: 40}, "IsQuestCompleted": 40},
            {"RouteCompleted": True},
        ))

    def test_missing_active_quest_warning_has_a_witness(self):
        findings = self.audit({"Qpart": {40: {1: 1}}, "IsQuestNotOnQuest": 40},
                              {"Done": {1: 41}, "IsQuestNotOnQuest": 41})
        self.assertEqual(2, len(findings))
        self.assertTrue(all(f["rule"] == "progression.quest-excluded-by-filter" for f in findings))
        self.assertEqual(False, findings[0]["evidence"]["witness"]["quest-complete:40"])

    def test_parallel_scenario_and_terminal_paths(self):
        route = {"label": "Invented", "steps": {1: {"scenarioID": 3, "steps": {
            1: {"RouteCompleted": True, "Faction": "Horde"}}}}, "parallelSteps": {
            1: {"conditions": {"IsQuestOnQuest": 40}, "steps": {1: {"PickUp": {1: 40}}}},
            2: {"conditions": {"HasSpell": 9, "DontHaveSpell": 9}, "steps": {1: {"Note": "Observe"}}}}}
        findings = audit_routes(catalog({"invented": route}))
        self.assertEqual({"progression.group-self-initialization", "progression.impossible-group"}, {f["rule"] for f in findings})
        self.assertEqual("parallelSteps[1].conditions", findings[0]["path"])
        self.assertIn("progression.conditional-terminal", self.rules({"RouteCompleted": True, "Faction": "Horde"}))
        self.assertEqual(set(), self.rules({"RouteCompleted": True, "Faction": "Horde"}, conditions={"Faction": "Horde"}))
        self.assertEqual(set(), self.rules({"RouteCompleted": True, "HasSpell": 19}, temporary=True))

    def test_independent_inventory_and_quest_contradictions(self):
        rules = self.rules(
            {"Note": "Observe", "ItemCount": {"itemID": 17, "count": 1, "operator": "<"},
             "AllOf": {1: {"ItemCount": {"itemID": 17, "count": 4}}}},
            {"Note": "Observe", "IsQuestCompleted": 28, "IsQuestUncompleted": 28},
        )
        self.assertEqual({"progression.impossible-filter"}, rules)

    def test_collection_does_not_replace_terminal_entry_context(self):
        collection = {"LootItems": {1: {"itemID": 73, "quantity": 3}}}
        protected = {"label": "Protected", "conditions": {"Faction": "Horde"}, "steps": {
            1: collection, 2: {"RouteCompleted": True, "Faction": "Horde"}}}
        possible_gap = {"label": "Gap", "conditions": {"Faction": "Horde"}, "steps": {
            1: collection, 2: {"RouteCompleted": True, "Faction": "Horde", "HasSpell": 84}}}
        result, paths = completion_analysis(protected, self.model)
        self.assertEqual("unsatisfiable", result.status)
        self.assertEqual(["steps[2]"], paths)
        self.assertEqual([], audit_routes(catalog({"protected": protected})))
        result, paths = completion_analysis(possible_gap, self.model)
        self.assertEqual("satisfiable", result.status)
        self.assertEqual(["steps[2]"], paths)
        self.assertEqual({"Faction": "Horde", "spell:84": False}, result.witness)
        findings = audit_routes(catalog({"gap": possible_gap}))
        self.assertEqual(["progression.conditional-terminal"], [f["rule"] for f in findings])
        self.assertEqual(False, findings[0]["evidence"]["witness"]["spell:84"])

    def test_completion_budget_is_reported_and_never_claims_coverage(self):
        route = {"label": "Bounded", "steps": {1: {"RouteCompleted": True, "AnyOf": {
            i: {"AllOf": {1: {"HasAura": i}, 2: {"HasSpell": i}}} for i in range(1, 12)}}}}
        result, paths = completion_analysis(route, self.model)
        self.assertEqual("unknown", result.status)
        self.assertEqual(["steps[1]"], paths)
        findings = audit_routes(catalog({"bounded": route}))
        self.assertEqual(["progression.analysis-budget"], [f["rule"] for f in findings])
        self.assertEqual("completion", findings[0]["evidence"]["analysis"])

    def test_prerequisites_use_any_alternative_and_external_history_is_unknown(self):
        declarations = {
            "a": {"label": "A", "gameVersion": "forever", "requiredRoute": {1: "b"}, "steps": {}},
            "b": {"label": "B", "gameVersion": "forever", "requiredRoute": {1: "a"}, "steps": {}},
            "root": {"label": "Root", "gameVersion": "forever", "steps": {}},
        }
        data = catalog(declarations)
        data.enums["GAME_VERSIONS"]["Forever"] = "forever"
        findings = audit_routes(data)
        self.assertEqual({"a", "b"}, {f["route"] for f in findings})
        self.assertTrue(all(f["rule"] == "progression.closed-prerequisite-component" for f in findings))
        declarations["b"]["requiredRoute"][2] = "root"
        self.assertEqual([], audit_routes(data))
        declarations["b"]["requiredRoute"][2] = "external"
        self.assertEqual([], audit_routes(data))
        del declarations["b"]["requiredRoute"][2]
        # Completion is recorded by label, including alternate declarations.
        declarations["root"]["label"] = "B"
        self.assertEqual([], audit_routes(data))

    def test_real_lua_filter_skips_and_pending_data_preserves_cursor(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
            APR = {Faction="Horde", PlayerID="p", ActiveRoute="r", stepHandlers={}}
            APRData = {p={r=1}}
            function LibStub() return {GetLocale=function() return {} end} end
            function APR:UpdateNextStep() APRData.p.r = APRData.p.r + 1 end
        ''')
        lua.execute(clean((ROOT / "APR-Core/utils/RouteUtils.lua").read_text(encoding="utf-8")))
        self.assertTrue(lua.execute('return APR:SkipStepCondition({Faction="Alliance"})'))
        self.assertEqual(2, lua.eval("APRData.p.r"))
        lua.execute("APR.startupQuestStatePending=true")
        self.assertFalse(lua.execute('return APR:SkipStepCondition({Faction="Alliance", IsQuestOnQuest=40})'))
        self.assertEqual(2, lua.eval("APRData.p.r"))

    def test_real_quest_objective_waits_then_advances_when_state_changes(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
            APR = {stepHandlers={}, ActiveQuests={}, QUEST_STATUS={COMPLETE="done"},
                BonusObj={}, MaxLevel=60, PlayerID="p"}
            APRData = {p={BonusSkips={}}}
            C_QuestLog = {IsQuestFlaggedCompleted=function() return false end}
            function LibStub() return {GetLocale=function() return {} end} end
            function APR:Debug() end
            function APR:Contains() return false end
            function APR:TrackQuest() end
            function APR:UpdateNextStep() self.advanced=(self.advanced or 0)+1 end
            function UnitLevel() return 5 end
        ''')
        lua.execute(clean((ROOT / "APR-Core/features/questing/StepQuestHandlers.lua").read_text(encoding="utf-8")))
        self.assertIsNone(lua.execute("return APR.stepHandlers.Qpart({Qpart={[40]={1}}}, false, 1)"))
        self.assertIsNone(lua.eval("APR.advanced"))
        lua.execute('APR.ActiveQuests[40]={objectives={[1]={status="active"}}}')
        self.assertIsNone(lua.execute("return APR.stepHandlers.Qpart({Qpart={[40]={1}}}, false, 1)"))
        lua.execute('APR.ActiveQuests[40].objectives[1].status="done"')
        self.assertTrue(lua.execute("return APR.stepHandlers.Qpart({Qpart={[40]={1}}}, false, 1)"))
        self.assertEqual(1, lua.eval("APR.advanced"))

    def test_real_array_end_preserves_normal_queue_but_completes_temporary_route(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
            APR = {stepHandlers={}, settings={profile={enableAddon=true}},
                PlayerID="p", ActiveRoute="r", currentStep={previousState={}},
                routeconfig={CheckIsCustomPathEmpty=function() end}}
            APRData={p={r=2}}; APRCustomPath={p={"Invented"}}; APRZoneCompleted={p={}}
            function LibStub() return {GetLocale=function() return {} end} end
            function APR:CaptureStepContext() return {} end
            function APR:GetCurrentStepToken() return "token" end
            function APR:ResetMissingQuests() end
            function APR:GetStep() return nil end
            function APR:Debug() end
            function APR:IsTemporaryRouteActive() return self.temporary or false end
            function APR:ClearTemporaryRoute(options) self.completedTemporary=options.completed end
            function UnitIsDeadOrGhost() return false end
        ''')
        lua.execute(clean((ROOT / "APR-Core/features/questing/StepRenderer.lua").read_text(encoding="utf-8")))
        lua.execute("APR:RenderCurrentStep()")
        self.assertEqual(1, lua.eval("#APRCustomPath.p"))
        self.assertIsNone(lua.eval("APRZoneCompleted.p.Invented"))
        lua.execute("APR.temporary=true; APR:RenderCurrentStep()")
        self.assertTrue(lua.eval("APR.completedTemporary"))


if __name__ == "__main__":
    unittest.main()
