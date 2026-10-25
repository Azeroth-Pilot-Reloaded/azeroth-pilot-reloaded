"""Regression contracts for Forever quest runs, independent of external addon caches."""

import re
import unittest

from tests.routes.route_loader import ROOT, load_routes


SHARED = "Forever-Shared-Dungeons-"
DUNGEONS = ("Ragefire-Chasm", "Wailing-Caverns", "Deadmines", "Hall-of-Thanes", "Ruins-of-Lordaeron")

# Acceptance minima and prerequisites reviewed against the composed Forever
# Questie records and local dungeon addons. Quest level is not acceptance level.
AVAILABILITY = {
    5722: (9, "Horde", None), 5723: (9, "Horde", None),
    5725: (9, "Horde", None), 5761: (9, "Horde", None),
    5728: (9, "Horde", 5727), 5724: (9, "Horde", 5722),
    5729: (9, "Horde", 5728), 5730: (9, "Horde", 5729),
    962: (14, "Horde", None), 914: (11, "Horde", 1490),
    959: (14, None, None), 1491: (13, None, 865),
    1486: (13, None, None), 1487: (15, None, None), 6981: (15, None, None),
    3369: (15, "Horde", 6981), 3370: (15, "Alliance", 6981),
    166: (14, "Alliance", 155), 214: (14, "Alliance", 155),
    167: (15, "Alliance", None), 168: (14, "Alliance", None),
    2040: (15, "Alliance", None), 373: (16, "Alliance", None),
    92753: (9, "Alliance", 92752), 96393: (9, "Alliance", 96391),
    96394: (10, "Alliance", None), 96403: (10, "Alliance", None),
    98423: (9, "Alliance", None),
    92401: (15, "Horde", None), 92421: (15, "Horde", None),
    92422: (15, "Horde", None), 95216: (16, "Horde", None),
    95250: (16, "Alliance", None), 92415: (15, "Alliance", None),
    95189: (16, "Alliance", None), 95195: (16, "Alliance", None),
    95204: (16, "Horde", None), 97288: (16, "Horde", None),
}

QUEST_CIRCUITS = {
    "Ragefire-Chasm": {5723, 5725, 5728, 5761},
    "Wailing-Caverns": {914, 959, 962, 1486, 1487, 1491, 6981},
    "Deadmines": {166, 167, 168, 214, 2040, 92753},
    "Hall-of-Thanes": {96393, 96394, 96403},
    "Ruins-of-Lordaeron": {92401, 92421, 92422, 95189, 95195, 95216, 95250},
}

DROP_ITEMS = {
    373: {2874}, 6981: {10441}, 98423: {281030}, 92415: {251270, 251520},
    95189: {268579}, 95195: {268535}, 95204: {275521}, 97288: {280438},
}


def sequence(table):
    return [value for _, value in sorted(table.items())]


def entails(condition, field, value):
    """A condition in one AnyOf branch does not protect the other branches."""
    if condition.get(field) == value:
        return True
    if any(entails(child, field, value) for child in condition.get("AllOf", {}).values()):
        return True
    alternatives = condition.get("AnyOf", {})
    return bool(alternatives) and all(entails(child, field, value) for child in alternatives.values())


def guarded(context, field, value):
    return any(entails(condition, field, value) for condition in context)


def steps_with_context(route):
    base = (route.get("conditions", {}),)
    for step in sequence(route["steps"]):
        yield step, base + (step,), False
    for group in route.get("parallelSteps", {}).values():
        for step in sequence(group["steps"]):
            yield step, base + (group.get("conditions", {}), step), True


def quest_actions(route, action, quest):
    return [(step, context, parallel) for step, context, parallel in steps_with_context(route)
            if quest in (step.get(action, {}) if action == "Qpart" else step.get(action, {}).values())]


class ForeverDungeonQuests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Packaged values come from CurseForge. Tests must also work from the
        # clean checkout, whose enUS.lua contains only the packaging directive.
        cls.translations = {
            "Forever - Dungeon - " + name: "Forever - Dungeon Only - " + name
            for name in ("Deadmines", "Hall of Thanes", "Ragefire Chasm",
                         "Ruins of Lordaeron", "Wailing Caverns")
        }
        cls.catalog = load_routes((ROOT / "Routes/Forever/Dungeons").rglob("*.lua"), translations=cls.translations)
        cls.runs = {name: cls.catalog.routes[SHARED + name] for name in DUNGEONS}

    def test_modes_have_distinct_names_and_separate_chains(self):
        for key, route in self.catalog.routes.items():
            with self.subTest(route=key):
                if key.startswith(SHARED):
                    self.assertTrue(route["label"].startswith("Forever - Dungeon Only - "))
                    self.assertNotIn("nextRoute", route)
                    self.assertNotIn("prefab", route)
                else:
                    self.assertTrue(route["label"].startswith("Forever - Leveling Dungeon - "))
                    self.assertIn("prefab", route)
                    for target in route.get("nextRoute", {}).values():
                        target = target if isinstance(target, str) else target["route"]
                        self.assertFalse(target.startswith(SHARED), target)

    def test_translations_control_the_entire_route_name_and_word_order(self):
        catalog = load_routes((ROOT / "Routes/Forever/Dungeons").rglob("*.lua"), translations={
            "Forever - Leveling Dungeon - Deadmines": "Progression avec les Mortemines",
            "Forever - Dungeon - Deadmines": "Les Mortemines : donjon seul",
        })
        leveling = catalog.routes["Forever-Alliance-Dungeons-Deadmines"]["label"]
        standalone = catalog.routes[SHARED + "Deadmines"]["label"]
        self.assertEqual(leveling, "Progression avec les Mortemines (19-20)")
        self.assertEqual(standalone, "Les Mortemines : donjon seul (18-20)")
        self.assertNotEqual(leveling, standalone)

    def test_forever_has_no_legacy_labels_and_dungeon_names_use_one_full_key(self):
        # legacyLabels is reserved for human edits. No agent-created aliases
        # belong in this revision, including on the ordinary Forever routes.
        catalog = load_routes((ROOT / "Routes/Forever").rglob("*.lua"))
        for key, route in catalog.routes.items():
            self.assertNotIn("legacyLabels", route, key)
        for path in (ROOT / "Routes/Forever/Dungeons").rglob("*.lua"):
            label = next(line.strip() for line in path.read_text(encoding="utf-8").splitlines()
                         if line.strip().startswith("label ="))
            self.assertRegex(label, r'^label = L\["Forever - (?:Leveling Dungeon|Dungeon) - [^"]+"\] \.\. " \([0-9]+-[0-9]+\)",$')

    def test_dungeon_routes_keep_existing_keys_and_leveling_uses_its_own_family(self):
        labels = set()
        for path in (ROOT / "Routes/Forever/Dungeons").rglob("*.lua"):
            key = re.search(r'^    label = L\["([^"]+)"\]', path.read_text(encoding="utf-8"), re.M)[1]
            labels.add(key)
        self.assertEqual(sum(key.startswith("Forever - Leveling Dungeon - ") for key in labels), 13)
        self.assertEqual(sum(key.startswith("Forever - Dungeon - ") for key in labels), 5)

    def test_quest_runs_never_require_outdoor_leveling_or_training(self):
        preparation_quests = {65, 132, 135, 141, 142, 155, 5726, 5727, 870, 877,
                              880, 1489, 1490, 865, 96391, 96392,
                              92742, 92744, 92745, 92747, 92748, 92749, 92750, 92751, 92752}
        for name, route in self.runs.items():
            for step, _, _ in steps_with_context(route):
                with self.subTest(dungeon=name, step=step["_index"]):
                    self.assertFalse(set(step).intersection({"Grind", "BeLvl", "Level", "LearnSkill", "LearnProfession", "SetHS"}))
                    self.assertFalse(preparation_quests.intersection(step.get("PickUp", {}).values()))
                    if "UseHS" in step:
                        self.assertTrue(step.get("UseHSIfAvailable"), "A city return cannot require a particular hearthstone")

    def test_each_run_collects_completes_and_returns_its_quests(self):
        for name, quests in QUEST_CIRCUITS.items():
            for quest in quests:
                for action in ("PickUp", "Qpart", "Done"):
                    with self.subTest(dungeon=name, quest=quest, action=action):
                        self.assertTrue(quest_actions(self.runs[name], action, quest))
        for name, quests in {"Ragefire-Chasm": {5722, 5724, 5729, 5730}, "Deadmines": {373},
                            "Hall-of-Thanes": {98423}, "Ruins-of-Lordaeron": {92415, 95204, 97288}}.items():
            for quest in quests:
                self.assertTrue(quest_actions(self.runs[name], "PickUp", quest), (name, quest))
                self.assertTrue(quest_actions(self.runs[name], "Done", quest), (name, quest))

    def test_acceptance_uses_faction_minimum_and_finished_prerequisite(self):
        observed = set()
        for name, route in self.runs.items():
            for step, context, _ in steps_with_context(route):
                for quest in step.get("PickUp", {}).values():
                    with self.subTest(dungeon=name, quest=quest):
                        minimum, faction, prerequisite = AVAILABILITY[quest]
                        observed.add(quest)
                        self.assertTrue(guarded(context, "MinLevel", minimum))
                        if faction:
                            self.assertTrue(guarded(context, "Faction", faction))
                        if prerequisite:
                            self.assertTrue(guarded(context, "IsQuestCompleted", prerequisite))
        self.assertTrue(set(AVAILABILITY).issubset(observed))

    def test_missing_or_unavailable_quests_cannot_block_objectives_and_returns(self):
        for name, route in self.runs.items():
            for step, context, _ in steps_with_context(route):
                quests = set(step.get("Qpart", {})) | set(step.get("Done", {}).values())
                for quest in quests:
                    with self.subTest(dungeon=name, quest=quest, step=step["_index"]):
                        self.assertTrue(guarded(context, "IsQuestOnQuest", quest))

    def test_uncertain_hall_quest_is_tracked_only_after_native_acceptance(self):
        route = self.runs["Hall-of-Thanes"]
        self.assertFalse(quest_actions(route, "PickUp", 96395))
        self.assertTrue(quest_actions(route, "Qpart", 96395))
        self.assertTrue(quest_actions(route, "Done", 96395))
        # Contradictory faction data must not hide a quest actually in the log.
        for action in ("Qpart", "Done"):
            for step, context, _ in quest_actions(route, action, 96395):
                self.assertTrue(guarded(context, "IsQuestOnQuest", 96395))
                self.assertNotIn("Faction", step)

    def test_wailing_shard_followup_is_collected_before_leaving_its_giver(self):
        steps = sequence(self.runs["Wailing-Caverns"]["steps"])
        index_of = lambda action, quest: next(index for index, step in enumerate(steps)
                                              if quest in step.get(action, {}).values())
        self.assertLess(index_of("Done", 6981), index_of("PickUp", 3369))
        self.assertLess(index_of("PickUp", 3369), index_of("Done", 962))
        self.assertLess(index_of("PickUp", 3370), index_of("Done", 962))

    def test_drop_quests_are_opportunistic_and_never_force_item_farming(self):
        observed = set()
        for name, route in self.runs.items():
            for step, context, parallel in steps_with_context(route):
                self.assertNotIn("LootItems", step, (name, step["_index"]))
                for quest in set(step.get("PickUp", {}).values()).intersection(DROP_ITEMS):
                    with self.subTest(dungeon=name, quest=quest):
                        observed.add(quest)
                        self.assertTrue(parallel)
                        self.assertTrue(guarded(context, "IsQuestNotOnQuest", quest))
                        self.assertTrue(guarded(context, "IsQuestUncompleted", quest))
                        self.assertTrue(any(guarded(context, "ItemCount", {"itemID": item, "count": 1})
                                            for item in DROP_ITEMS[quest]))
        self.assertEqual(observed, set(DROP_ITEMS))

    def test_deadmines_exterior_objectives_and_forge_follow_the_actual_run(self):
        steps = sequence(self.runs["Deadmines"]["steps"])
        entering = next(index for index, step in enumerate(steps) if "EnterInstance" in step)
        gilnid = next(index for index, step in enumerate(steps) if step.get("KillNPC", {}).get("npcID") == 1763)
        smite = next(index for index, step in enumerate(steps) if step.get("KillNPC", {}).get("npcID") == 646)
        for quest in (167, 168):
            objectives = [index for index, step in enumerate(steps) if quest in step.get("Qpart", {})]
            self.assertTrue(objectives)
            self.assertTrue(all(index < entering for index in objectives))
        explosives = [index for index, step in enumerate(steps) if 92753 in step.get("Qpart", {})]
        self.assertTrue(explosives)
        self.assertTrue(all(gilnid < index < smite for index in explosives))
        self.assertTrue(all(254553 in steps[index].get("Button", {}).values() for index in explosives))

    def test_hall_of_thanes_visits_four_confirmed_bosses_in_order(self):
        bosses = [step["KillNPC"]["npcID"] for step in self.runs["Hall-of-Thanes"]["steps"].values()
                  if "KillNPC" in step]
        self.assertEqual(bosses, [261306, 261316, 261311, 261319])

    def test_optional_lordaeron_events_and_rare_do_not_gate_the_run(self):
        bosses = {step["KillNPC"]["npcID"] for step in self.runs["Ruins-of-Lordaeron"]["steps"].values()
                  if "KillNPC" in step}
        self.assertFalse(bosses.intersection({250631, 256035, 255699}))
        self.assertTrue({250483, 250660, 250657}.issubset(bosses))


if __name__ == "__main__":
    unittest.main()
