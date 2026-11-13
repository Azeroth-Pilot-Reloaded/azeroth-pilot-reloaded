"""Synthetic conversion contracts, independent of maintained profession guides."""
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tests.routes.route_loader import load_routes
from tests.routes.route_schema import RouteSchema
from tools.forever.professions import LOCALES, PROFESSION_TITLES, Texts, choices, convert_guide, descriptive_note_keys, restrictions, semantic_key


class SyntheticTexts:
    def key(self, slug, value, names, **kwargs):
        return value


class ProfessionConversionTests(unittest.TestCase):
    def convert(self, goals):
        guide = {
            "title": "Invented workshop", "names": {},
            "steps": [
                {"title": "Invented apprenticeship", "goals": [
                    {"t": "train", "skillLine": 171, "rank": 1}]},
                {"title": "Invented objective", "goals": goals},
            ],
        }
        source, _, _ = convert_guide("invented-workshop", guide, SyntheticTexts())
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "workshop.lua"
            path.write_text(source, encoding="utf-8")
            catalog = load_routes([path])
        schema = RouteSchema(catalog)
        for key, route in catalog.routes.items():
            schema.validate(key, route)
        route = next(iter(catalog.routes.values()))
        return list(route["steps"].values())[1:-1]

    def test_recipe_item_is_used_before_waiting_for_known_spell(self):
        steps = self.convert([{"t": "learn", "spell": 810001, "item": 820001}])
        self.assertEqual(steps[0]["UseItem"], {"itemID": 820001})
        self.assertEqual(steps[0]["DontHaveSpell"], 810001)
        self.assertEqual(steps[1]["LearnSkill"], {"spellID": 810001})

    def test_intermediate_crafts_require_manual_confirmation(self):
        steps = self.convert([{"t": "craft", "spell": 810002, "spellName": "Invented component", "count": 7,
                               "skillLine": 171, "reagents": [{"item": 820002, "itemName": "Invented reagent", "count": 3}]}])
        self.assertEqual(len(steps), 1)
        self.assertIn("Note", steps[0])
        self.assertNotIn("LootItems", steps[0])
        self.assertNotIn("SkillGoal", steps[0])
        self.assertEqual(steps[0]["Note"][len(steps[0]["Note"])], "Invented objective")
        self.assertEqual(len(steps[0]["Note"]), 2)
        self.assertNotIn("ExtraLineText", steps[0])
        self.assertNotIn("_comment", steps[0])

    def test_rank_craft_waits_for_skill_and_deduplicates_source_goal(self):
        steps = self.convert([
            {"t": "craft", "spell": 810003, "spellName": "Invented potion", "skillLine": 171, "untilSkill": 93},
            {"t": "skill", "skillLine": 171, "level": 93},
        ])
        self.assertEqual(len(steps), 1)
        self.assertEqual(steps[0]["SkillGoal"], {"skillID": 171, "rank": 93})
        self.assertEqual(steps[0]["Note"][len(steps[0]["Note"])], "Invented objective")

    def test_gathering_location_stays_on_rank_objective(self):
        steps = self.convert([
            {"t": "goto", "map": 1429, "x": 13, "y": 27},
            {"t": "skill", "skillLine": 171, "level": 47},
        ])
        self.assertEqual(len(steps), 1)
        self.assertEqual(steps[0]["Zone"], 1429)
        self.assertEqual(steps[0]["Coord"], {"x": 13, "y": 27})
        self.assertEqual(steps[0]["SkillGoal"]["rank"], 47)

    def test_native_race_identity_and_faction_destination(self):
        inherited = restrictions({"races": ["Undead"]})
        self.assertEqual(inherited, {"Race": "Scourge"})
        goal = {"candidates": [
            {"npc": 830001, "map": 1429, "faction": "A"},
            {"npc": 830002, "map": 1420, "faction": "H"},
        ]}
        selected = choices(goal, inherited)
        self.assertEqual(len(selected), 1)
        self.assertEqual(selected[0][0]["npc"], 830002)
        self.assertEqual(selected[0][1]["Faction"], "Horde")

    def test_initial_training_uses_existing_service_routing(self):
        goal = {"t": "train", "rank": 1, "candidates": [{"npc": 830003, "map": 1453, "faction": "A"}]}
        self.assertEqual(choices(goal, {}), [(None, {})])

    def test_rank_book_is_purchased_and_used_before_rank_wait(self):
        steps = self.convert([{"t": "train", "skillLine": 171, "rank": 3, "text": "{item:820004}"}])
        self.assertEqual(steps[0]["BuyMerchant"], {1: {"itemID": 820004, "quantity": 1}})
        self.assertEqual(steps[1]["UseItem"], {"itemID": 820004})
        self.assertEqual(steps[0]["DontHaveSpell"], steps[2]["LearnProfession"])
        self.assertEqual(steps[1]["DontHaveSpell"], steps[2]["LearnProfession"])

    def test_quest_objectives_keep_the_manual_item_button(self):
        steps = self.convert([{"t": "complete", "quest": 840001, "objs": [{"count": 1}, {"count": 2}], "startItem": 820003}])
        self.assertEqual(steps[0]["Qpart"], {840001: {1: 1, 2: 2}})
        self.assertEqual(steps[0]["Button"], {"840001-1": 820003})

    def text_fixture(self):
        texts = Texts.__new__(Texts)
        texts.existing = {}
        texts.reviewed = {}
        texts.translations = {("invented", locale): {} for locale in LOCALES}
        texts.names = {locale: {} for locale in LOCALES}
        texts.output = {locale: {} for locale in LOCALES}
        texts.note_values = {("invented", "Detailed instruction with a warning.")}
        texts.english_names = {}
        texts.key_names = {"Detailed instruction with a warning.": "FOREVER_PROF_INVENTED_POTION_SAFETY"}
        texts.claimed_keys = {}
        texts.label_replacements = []
        return texts

    def test_reviewed_instructions_survive_regeneration(self):
        texts = self.text_fixture()
        value = "Detailed instruction with a warning."
        key = "FOREVER_PROF_INVENTED_POTION_SAFETY"
        texts.reviewed = {locale: {key: "Complete localized instruction and warning " + locale} for locale in LOCALES}
        texts.existing = {value: key}
        texts.key("invented", value, {})
        for locale in LOCALES:
            self.assertEqual(texts.output[locale][key], "Complete localized instruction and warning " + locale)

    def test_missing_instruction_never_becomes_objective_summary(self):
        texts = self.text_fixture()
        with self.assertRaisesRegex(ValueError, "Missing complete translation"):
            texts.key("invented", "Detailed instruction with a warning.", {})

    def test_empty_reviewed_instruction_is_rejected(self):
        texts = self.text_fixture()
        value = "Detailed instruction with a warning."
        key = "FOREVER_PROF_INVENTED_POTION_SAFETY"
        texts.reviewed = {"enUS": {key: ""}}
        with self.assertRaisesRegex(ValueError, "Invalid reviewed translation"):
            texts.key("invented", value, {})

    def test_title_key_uses_stable_french_profession_without_rank(self):
        texts = self.text_fixture()
        with patch.dict(PROFESSION_TITLES, {"invented": "Métier inventé"}):
            first = texts.key("invented", "Invented craft 1-400", {}, title=True)
        self.assertEqual(first, "Forever - Métier inventé")

    def test_note_keys_describe_subject_and_tier_without_opaque_suffix(self):
        guides = {"invented": {"sections": [{"from": 1, "to": 90}, {"from": 90, "to": 180}], "steps": [
            {"title": "Collect ore", "note": "Ore for early crafts", "section": 1, "goals": [{"t": "collect"}]},
            {"title": "Collect ore", "note": "Ore for later crafts", "section": 2, "goals": [{"t": "collect"}]},
        ]}}
        result = descriptive_note_keys(guides, {})
        self.assertEqual(result["Ore for early crafts"], "FOREVER_PROF_INVENTED_COLLECT_ORE_SKILL_1_90")
        self.assertEqual(result["Ore for later crafts"], "FOREVER_PROF_INVENTED_COLLECT_ORE_SKILL_90_180")
        self.assertEqual(semantic_key("invented", "Boiled clams"), "FOREVER_PROF_INVENTED_BOILED_CLAMS")
        self.assertEqual(semantic_key("invented", "Invented 1-90 vendor goods"), "FOREVER_PROF_INVENTED_1_90_VENDOR_GOODS")

    def test_recipe_subject_is_unqualified_until_context_is_needed(self):
        texts = self.text_fixture()
        self.assertEqual(texts.translation_key("invented", "First recipe", subject="Boiled clams"), "FOREVER_PROF_INVENTED_BOILED_CLAMS")
        self.assertEqual(texts.translation_key("invented", "Shopping instructions", subject="Boiled clams", disambiguator="SHOPPING"), "FOREVER_PROF_INVENTED_BOILED_CLAMS_SHOPPING")

    def test_numeric_fallback_uses_verified_names_without_fake_hyperlinks(self):
        texts = self.text_fixture()
        texts.names["frFR"]["spell:810004"] = "Recette inventée"
        texts.english_names["spell:810005"] = "Verified invented recipe"
        value = "|Hspell:810004|h[#810004]|h / |Hspell:810005|h[#810005]|h"
        self.assertEqual(texts.plain_labels(value, "frFR", "INVENTED_KEY"), "Recette inventée / Verified invented recipe")
        with self.assertRaisesRegex(ValueError, "Unresolved numeric label"):
            texts.plain_labels("|Hspell:899999|h[#899999]|h", "frFR", "INVENTED_KEY")


if __name__ == "__main__":
    unittest.main()
