"""Guard relationships use invented routes and independent character witnesses."""

import unittest

from tests.routes.route_loader import RouteCatalog, load_routes
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


if __name__ == "__main__":
    unittest.main()
