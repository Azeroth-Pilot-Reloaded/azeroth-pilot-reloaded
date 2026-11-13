"""Conservative character-guard audit over declarations from route_loader.

No quest/NPC restrictions are guessed. Unknown predicates have both possible
truth values, including beneath Not. Bitsets represent controlled characters;
lower/upper truth bounds prevent unknown game state from proving an error.
Route entry levels can change during a journey and character advice can be
waived, so neither is inherited as a permanent step restriction. Faction is.
Numeric and named races can alias: all observed name/ID pairs are considered.
This proves contradictions in the modeled filters, never playability in game.
Resource propagation covers explicit shared itemID/spellID references only.
LearnProfession's scalar spellID and SkillGoal.skillID are not linked: no
attested conversion between those identifier domains is used.
Profession steps still receive their own character/level contradiction checks.
"""

from itertools import product
import math
import re

from tests.routes.route_schema import RouteSchema


CHARACTER = {"Faction", "Race", "Class", "ClassNot"}
LEVELS = {"Level", "MinLevel", "MaxLevel", "SkipForLvl", "BeLvl"}
OTHER = "<other>"


def values(value):
    return list(value.values()) if isinstance(value, dict) else [value]


def walk_conditions(node):
    if not isinstance(node, dict):
        return
    yield node
    for name in ("AnyOf", "AllOf"):
        for child in values(node.get(name, {})):
            yield from walk_conditions(child)
    if "Not" in node:
        yield from walk_conditions(node["Not"])


def iter_steps(route):
    """Yield (path, step/action entry, inherited parallel conditions)."""
    def steps(entries, path, guards=()):
        for index, step in (entries or {}).items():
            if not isinstance(step, dict):
                continue
            current = f"{path}[{index}]"
            if "steps" in step:
                yield from steps(step["steps"], current + ".steps", guards)
                continue
            yield current, step, guards
            # Only purchases have their own condition tree inside an action.
            for action in ("BuyMerchant", "LootItems"):
                for entry_index, entry in step.get(action, {}).items():
                    if isinstance(entry, dict):
                        yield f"{current}.{action}[{entry_index}]", entry, (*guards, step)
    yield from steps(route.get("steps"), "steps")
    for index, scenario in route.get("scenarios", {}).items():
        yield from steps(scenario.get("steps"), f"scenarios[{index}].steps")
    for index, group in route.get("parallelSteps", {}).items():
        yield from steps(group.get("steps"), f"parallelSteps[{index}].steps", (group.get("conditions", {}),))


class CharacterDomain:
    def __init__(self, nodes, enums):
        self.classes = {name.upper().replace(" ", ""): identifier
                        for name, identifier in enums.get("Classes", {}).items()}
        observed = {name: set() for name in ("Race", "Class", "Faction")}
        levels = {1.0}
        for node in nodes:
            for condition in walk_conditions(node):
                for name in CHARACTER & condition.keys():
                    axis = "Class" if name == "ClassNot" else name
                    observed[axis].update(self.normalize(axis, v) for v in values(condition[name]))
                for name in LEVELS & condition.keys():
                    v = condition[name]
                    if type(v) in (int, float):
                        levels.add(float(v))
                        if name == "BeLvl":
                            levels.add(float(math.floor(v) + 1))
        bounds = sorted(levels)
        level_samples = sorted(set(bounds + [(a + b) / 2 for a, b in zip(bounds, bounds[1:])]
                                   + [max(bounds) + 1]))
        races = observed["Race"]
        race_names = sorted((v for v in races if isinstance(v, str))) + [OTHER]
        race_ids = sorted(v for v in races if type(v) is int) + [OTHER]
        factions = ["Alliance", "Horde", "Neutral", OTHER]
        # One unused enum value represents the remaining equivalence class;
        # this supplies a concrete class witness without historical race rules.
        remaining = set(enums.get("Classes", {}).values()) - observed["Class"]
        classes = sorted(observed["Class"] | ({min(remaining)} if remaining else set()), key=str) or [OTHER]
        self.observed = observed
        self.remaining_class = min(remaining) if remaining else OTHER
        self.characters = [dict(Faction=f, Race=r, RaceID=rid, Class=c, level=l)
                           for f, r, rid, c, l in product(factions, race_names, race_ids, classes, level_samples)]
        self.full = (1 << len(self.characters)) - 1
        self.cache = {}
        self.access_indexes = {}
        for index, character in enumerate(self.characters):
            identity = tuple(character[k] for k in ("Faction", "Race", "RaceID", "Class"))
            self.access_indexes.setdefault(identity, index)

    def normalize(self, name, value):
        return self.classes.get(value, value) if name == "Class" else value

    def atom(self, name, value):
        key = (name, repr(value))
        if key in self.cache:
            return self.cache[key]
        wanted = [self.normalize("Class" if name == "ClassNot" else name, v) for v in values(value)]
        def matches(c):
            if name == "Race":
                return c["Race"] in wanted or c["RaceID"] in wanted
            if name == "ClassNot":
                return c["Class"] not in wanted
            if name in CHARACTER:
                return c[name] in wanted
            if type(value) not in (int, float):
                return None
            level = c["level"]
            return {"Level": lambda: level >= value, "MinLevel": lambda: level >= value,
                    "MaxLevel": lambda: level <= value, "SkipForLvl": lambda: level < value,
                    "BeLvl": lambda: value <= level < math.floor(value) + 1}[name]()
        low = high = 0
        for i, character in enumerate(self.characters):
            result = matches(character)
            if result is True:
                low |= 1 << i
            if result is not False:
                high |= 1 << i
        self.cache[key] = low, high
        return low, high

    def evaluate(self, node, fields=None):
        """Return definitely/possibly accepted masks, preserving Boolean logic."""
        low = high = self.full
        for name, value in (node or {}).items():
            if name in ("AnyOf", "AllOf"):
                a = b = 0 if name == "AnyOf" else self.full
                for child in values(value):
                    x, y = self.evaluate(child, fields)
                    a, b = (a | x, b | y) if name == "AnyOf" else (a & x, b & y)
            elif name == "Not":
                x, y = self.evaluate(value, fields)
                a, b = self.full ^ y, self.full ^ x
            elif name in CHARACTER | LEVELS and (fields is None or name in fields):
                a, b = self.atom(name, value)
            elif name in self.condition_fields:
                a, b = 0, self.full
            else:
                continue  # action/metadata, not a predicate
            low, high = low & a, high & b
        return low, high

    def witness(self, mask):
        return self.characters[(mask & -mask).bit_length() - 1]

    def access_witness(self, mask, attestations):
        for character, provenance in attestations:
            race = character["Race"]
            name = race if isinstance(race, str) and race in self.observed["Race"] else OTHER
            identifier = race if type(race) is int and race in self.observed["Race"] else OTHER
            class_id = self.normalize("Class", character["Class"])
            represented_class = class_id if class_id in self.observed["Class"] else self.remaining_class
            identity = (character["Faction"], name, identifier, represented_class)
            index = self.access_indexes.get(identity)
            if index is not None and mask & (1 << index):
                return {**character, "Class": class_id}, {
                    "status": "source-declared-combination",
                    "source": provenance,
                    "server_playability": "unknown",
                }
        witness = {k: v for k, v in self.witness(mask).items() if k != "level"}
        return witness, {"status": "unknown", "server_playability": "unknown",
                         "reason": "Symbolic guard partition; no matching positive source declaration establishes this combination."}


def quest_links(step):
    """Explicit quest references only; proximity/coordinates carry no linkage."""
    links = set()
    for field in ("PickUp", "PickUpDB", "Done", "DoneDB", "QpartDB", "WaypointDB"):
        links.update(values(step.get(field, {})))
    for field in ("Qpart", "QpartPart", "Fillers"):
        links.update(step.get(field, {}))
    for field in ("Button", "SpellButton"):
        for key in step.get(field, {}):
            # Labels are not evidence of a quest association. Only the complete
            # documented quest[-objective] numeric shape establishes a link.
            if re.fullmatch(r"[1-9][0-9]*(?:-[0-9]+)?", str(key)):
                try:
                    links.add(int(str(key).split("-")[0]))
                except ValueError:
                    # Extremely large digit strings may exceed Python's integer
                    # conversion limit; schema/engine validation owns that case.
                    continue
    for value in step.values():
        if isinstance(value, dict) and "questID" in value:
            links.add(value["questID"])
    if "questID" in step:
        links.add(step["questID"])
    return links


def resource_links(step):
    links = set()
    if "LearnProfession" in step:
        # StepInstructions and SPELLS_CHANGED handling treat this scalar as a
        # spell ID, not as SkillGoal's skill-line ID.
        links.add(("spellID", step["LearnProfession"]))
    for field in ("UseItem", "UseSpell", "EquipItem", "LearnSkill", "SpellETA"):
        action = step.get(field, {})
        for kind in ("itemID", "spellID"):
            if kind in action:
                links.add((kind, action[kind]))
        links.update(("spellID", v) for v in values(action.get("spellIDs", {})))
    if "itemID" in step:
        links.add(("itemID", step["itemID"]))
    for field, kind in (("Button", "itemID"), ("SpellButton", "spellID")):
        for value in step.get(field, {}).values():
            links.update((kind, v) for v in values(value))
    return links


def missing_quest_contract(step, quest):
    """Document observed handler behavior, without claiming native availability."""
    if quest in step.get("Qpart", {}) or quest in values(step.get("Done", {})):
        return {
            "missing_uncompleted_quest": "reports-missing-without-automatic-advance",
            "sources": ["APR-Core/features/questing/StepQuestHandlers.lua",
                        "APR-Core/utils/QuestUtils.lua"],
        }
    return {"missing_uncompleted_quest": "not-established-for-this-action"}


def source_character_combinations(catalog):
    """Positive authored conjunctions are provenance, never server API facts.

    Do not combine restrictions from unrelated steps, invert ClassNot, infer
    faction from a race, or import historical class/race compatibility tables.
    """
    result = []
    for key, route in sorted(catalog.routes.items()):
        for path, step, inherited in iter_steps(route):
            choices = {}
            for node in (route.get("conditions", {}), *inherited, step):
                for field in ("Faction", "Race", "Class"):
                    if field in node:
                        candidates = set(values(node[field]))
                        choices[field] = choices.get(field, candidates) & candidates
            if all(choices.get(field) for field in ("Faction", "Race", "Class")):
                for faction, race, class_id in product(*(sorted(choices[f], key=str) for f in ("Faction", "Race", "Class"))):
                    result.append((dict(Faction=faction, Race=race, Class=class_id),
                                   dict(route=key, path=path, file=catalog.sources.get(key))))
    return result


def audit_routes(catalog):
    """Audit all supplied declarations; the caller chooses its catalog scope."""
    findings = []
    attestations = source_character_combinations(catalog)
    condition_fields = set(RouteSchema(catalog).condition_fields)
    def filters(node):
        return {name: value for name, value in node.items() if name in condition_fields}
    for key, route in sorted(catalog.routes.items()):
        entries = list(iter_steps(route))
        route_conditions = route.get("conditions", {})
        nodes = [route_conditions] + [node for _, step, inherited in entries for node in (*inherited, step, step.get("conditions", {}))]
        domain = CharacterDomain(nodes, catalog.enums)
        domain.condition_fields = condition_fields
        # A safe over-approximation of every manual entry projection: only
        # permanent faction restrictions survive. Other fields remain unknown,
        # not erased, which is essential inside negations and alternatives.
        _, context = domain.evaluate(route_conditions, {"Faction"})
        def emit(severity, rule, path, message, **evidence):
            evidence["source"] = catalog.sources.get(key)
            findings.append(dict(severity=severity, rule=rule, route=key, path=path,
                                 message=message, evidence=evidence))
        if not context:
            emit("error", "guard.route-contradiction", "conditions", "No faction can satisfy the route condition tree.", conditions=route_conditions)
        elif not domain.evaluate(route_conditions)[1]:
            emit("warning", "guard.route-recommendation-contradiction", "conditions",
                 "Authored route filters are contradictory; manual entry advice/level projection may waive them.", conditions=route_conditions)
        records = []
        for path, step, inherited in entries:
            guards = (*inherited, step, step.get("conditions", {}))
            possible = domain.full
            coverage_low, coverage_high = context, context
            for guard in guards:
                _, upper = domain.evaluate(guard)
                possible &= upper
                lower, upper = domain.evaluate(guard, CHARACTER)
                coverage_low &= lower
                coverage_high &= upper
            if not possible:
                optional = ".BuyMerchant[" in path and step.get("optional") is True
                emit("warning" if optional else "error",
                     "guard.optional-entry-unreachable" if optional else "guard.step-contradiction", path,
                     "The step/group character or numeric level filters are mutually exclusive."
                     + (" This optional purchase may intentionally reuse a broader supply list." if optional else ""),
                     guards=[filters(g) for g in guards])
            elif context and not (possible & context):
                emit("error", "guard.route-step-conflict", path, "The step filters cannot match any faction admitted by the route.", route_conditions=route_conditions, guards=[filters(g) for g in guards])
            records.append((path, step, coverage_low, coverage_high))
        groups = {}
        for record in records:
            for quest in quest_links(record[1]):
                groups.setdefault(("questID", quest), []).append(record)
            for resource in resource_links(record[1]):
                groups.setdefault(resource, []).append(record)
        for link, members in sorted(groups.items(), key=str):
            # All pickup alternatives collectively define the authored quest
            # access. For resources, use explicitly restricted producers/actions.
            producers = ([r for r in members if link[1] in
                          values(r[1].get("PickUp", {})) + values(r[1].get("PickUpDB", {}))]
                         if link[0] == "questID" else
                         [r for r in members if ".BuyMerchant[" in r[0] or ".LootItems[" in r[0]
                          or "LearnSkill" in r[1] or "LearnProfession" in r[1]])
            if not producers:
                continue
            allowed = 0
            for producer in producers:
                allowed |= producer[3]
            exposed = []
            for path, step, low, _ in members:
                uncovered = low & ~allowed
                if uncovered:
                    witness, witness_evidence = domain.access_witness(uncovered, attestations)
                    # Coverage compares permanent access, not quest progression
                    # levels; a level-one representative is not a live witness.
                    exposed.append(dict(path=path, guards=filters(step), witness=witness,
                                        witness_evidence=witness_evidence,
                                        engine_contract=missing_quest_contract(step, link[1])
                                        if link[0] == "questID" else {}))
            if exposed:
                emit("warning", "guard.link-coverage", exposed[0]["path"],
                     "Explicitly linked actions admit characters excluded by all linked producer guards; inspect quest/item availability and intended alternatives.",
                     link={link[0]: link[1]}, producers=[p[0] for p in producers],
                     producer_guards=[filters(p[1]) for p in producers],
                     affected_actions=exposed, witness=exposed[0]["witness"],
                     witness_evidence=exposed[0]["witness_evidence"],
                     confidence="explicit-guard-discrepancy-only",
                     witness_scope="symbolic access: enum/observed values, no assertion that race/class/faction combination exists on the server",
                     limitation="External quest pickups, server eligibility and prior completion can justify an uncovered action; game blockage is not proven.")
    return findings
