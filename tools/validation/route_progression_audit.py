"""Conservative declarative progression audit; never executes client APIs.

Filters are visibility/skip predicates, not wait objectives (RouteUtils.lua).
Unsatisfiable filters therefore report unreachable instructions, not deadlocks.
The bounded symbolic model preserves unknown predicates as independent atoms;
SAT witnesses are abstract possibilities, never certified playable characters.
Dynamic/external acquisition, quest availability, account state, map transitions,
manual skip and saved progress remain outside this analysis.
"""
from dataclasses import dataclass
import json
import math

from tests.routes.route_schema import RouteSchema


LIMIT = 512
LIMITATIONS = (
    "Static filters are not waits: a known false filter advances the cursor; pending startup data does not.",
    "Unknown API/account/world predicates are independent symbolic atoms; witnesses are abstract states, not playable characters.",
    "External quests, item drops, trainers, spells, reputation, manual skip and saved progress cannot be certified offline.",
    "Route selection level advice differs from strict step filters; route conditions are not imposed on every step.",
    "Branch expansion is bounded; exhausted analyses return unknown and cannot prove contradictions.",
    "No full temporal planner: cross-step acquisition and prerequisite cycles are review warnings, not proven gameplay deadlocks.",
)


def values(value):
    return list(value.values()) if isinstance(value, dict) else [value]


def freeze(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True)


def atom(key, operator, value):
    return ("atom", str(key), operator, value)


def both(*children):
    return ("and", *children)


def either(*children):
    return ("or", *children)


def negate(child):
    return ("not", child)


@dataclass
class Analysis:
    status: str  # satisfiable / unsatisfiable / unknown
    witness: dict | None = None


class ConditionModel:
    """Boolean expressions plus scalar comparisons, following route predicates.

    Unsupported predicates are opaque, retaining exact repeats/negations. This
    over-approximates real states: UNSAT is a proof, SAT is only a possibility.
    Numeric level thresholds in XP/profile forms deliberately stay opaque.
    """

    def __init__(self, catalog):
        self.fields = RouteSchema(catalog).condition_fields
        self.classes = {name.upper().replace(" ", ""): value
                        for name, value in catalog.enums.get("Classes", {}).items()}
        self.class_category = catalog.enums.get("CATEGORIES", {}).get("Class")

    def expression(self, conditions):
        terms = []
        for name, value in (conditions or {}).items():
            if name not in self.fields:
                continue
            if name in ("AllOf", "AnyOf"):
                children = [self.expression(child) for child in values(value)]
                terms.append((both if name == "AllOf" else either)(*children))
            elif name == "Not":
                terms.append(negate(self.expression(value)))
            else:
                terms.append(self.predicate(name, value))
        return both(*terms)

    def predicate(self, name, value):
        scalar = {"Faction", "Gender", "Hardcore", "AlliedRace", "ClassSpec"}
        if name in scalar:
            return atom(name, "==", value)
        if name in ("Class", "ClassNot", "Race"):
            choices = values(value)
            if name.startswith("Class"):
                choices = [self.classes.get(v, v) for v in choices]
            # Race name/ID aliases are client data, not present in the enums.
            # Keep mixed representations opaque rather than invent mappings.
            if name == "Race":
                return either(*(atom("race-id" if type(v) in (int, float) else "race-name", "==", v) for v in choices))
            result = either(*(atom("Class", "==", v) for v in choices))
            return negate(result) if name == "ClassNot" else result
        numeric = {"Level": ">=", "MinLevel": ">=", "MaxLevel": "<=", "SkipForLvl": "<"}
        if name in numeric and type(value) in (int, float):
            return atom("level", numeric[name], value)
        if name == "BeLvl" and type(value) in (int, float):
            return both(atom("level", ">=", value), atom("level", "<", math.floor(value) + 1))
        for yes, no, prefix in (
            ("IsQuestOnQuest", "IsQuestNotOnQuest", "quest-on:"),
            ("IsQuestCompleted", "IsQuestUncompleted", "quest-complete:"),
            ("HasSpell", "DontHaveSpell", "spell:"),
            ("HasAura", "DontHaveAura", "aura:"),
            ("HasAchievement", "DontHaveAchievement", "achievement:"),
        ):
            if name in (yes, no):
                return both(*(atom(prefix + str(v), "==", name == yes) for v in values(value)))
        if name == "IsQuestReadyForTurnIn":
            # QuestUtils requires every quest ready (or already completed).
            return both(*(atom("quest-ready:" + str(v), "==", True) for v in values(value)))
        if name.startswith("Is") and "Quests" in name:
            account = "account-" if name.endswith("OnAccount") else ""
            children = [atom(account + "quest-complete:" + str(v), "==", True) for v in values(value)]
            result = (either if "OneOf" in name else both)(*children)
            return negate(result) if "Uncompleted" in name else result
        if name == "Skill":
            identity = value.get("skillID", value.get("skill", value.get("name")))
            # Symbolic aliases retain their authored form; numeric IDs unify.
            key = "skill:" + str(identity) + (":maximum" if value.get("maximum") else "")
            return atom(key, value.get("operator", ">="), value.get("rank", 1))
        if name == "ItemCount":
            if "itemID" in value and "itemIDs" not in value and not value.get("includeUsableToys"):
                key = "item:" + str(value["itemID"]) + (":bank" if value.get("includeBank") else "")
                return atom(key, value.get("operator", ">="), value["count"])
        if name in ("ReputationLevel", "SkipForReputation"):
            key = "reputation:" + str(value["factionID"]) + ":" + value.get("type", "standard")
            return atom(key, ">=" if name == "ReputationLevel" else "<", value["level"])
        if name in ("Money", "SkipForPrimaryProfessions"):
            return atom("money", value.get("operator", ">="), value["copper"]) if name == "Money" else atom("professions", "<", value)
        return atom("unknown:" + name + ":" + freeze(value), "==", True)


INVERSE = {"==": "~=", "~=": "==", "<": ">=", ">=": "<", ">": "<=", "<=": ">"}


class BudgetExceeded(Exception):
    pass


def branches(expression, negative=False):
    kind, *args = expression
    if kind == "not":
        return branches(args[0], not negative)
    if kind == "atom":
        key, operator, value = args
        return [[(key, INVERSE[operator] if negative else operator, value)]]
    conjunction = (kind == "and") != negative
    result = [[]] if conjunction else []
    for child in args:
        parts = branches(child, negative)
        if conjunction:
            if len(result) * len(parts) > LIMIT:
                raise BudgetExceeded
            result = [left + right for left in result for right in parts]
        else:
            result.extend(parts)
            if len(result) > LIMIT:
                raise BudgetExceeded
    return result


def branch_witness(constraints):
    domains = {}
    for key, operator, value in constraints:
        domains.setdefault(key, []).append((operator, value))
    witness = {}
    for key, tests in domains.items():
        equal = [value for op, value in tests if op == "=="]
        excluded = [value for op, value in tests if op == "~="]
        if equal:
            candidate = equal[0]
            if any(v != candidate for v in equal) or candidate in excluded:
                return None
        elif all(op in ("==", "~=") for op, _ in tests):
            candidate = (False if True in excluded else True) if all(type(v) is bool for v in excluded) else "<other>"
            if candidate in excluded:
                # Categorical domains are open; Boolean domains are closed.
                if all(type(v) is bool for v in excluded):
                    return None
                candidate = "<other>"
        else:
            low, low_closed, high, high_closed = 0, True, math.inf, False
            for op, value in tests:
                if op in (">", ">=") and (value > low or value == low and op == ">"):
                    low, low_closed = value, op == ">="
                if op in ("<", "<=") and (value < high or value == high and op == "<"):
                    high, high_closed = value, op == "<="
            if low > high or low == high and not (low_closed and high_closed):
                return None
            if key == "level":
                candidate = low if low_closed else (low + high) / 2 if math.isfinite(high) else low + 0.5
                for _ in range(len(excluded) + 1):
                    if candidate not in excluded:
                        break
                    candidate = (candidate + high) / 2 if math.isfinite(high) else candidate + 0.25
            else:
                candidate = math.ceil(low) if low_closed else math.floor(low) + 1
                while candidate in excluded:
                    candidate += 1
        for op, value in tests:
            if not {"==": lambda: candidate == value, "~=": lambda: candidate != value,
                    "<": lambda: candidate < value, "<=": lambda: candidate <= value,
                    ">": lambda: candidate > value, ">=": lambda: candidate >= value}[op]():
                return None
        witness[key] = candidate
    return witness


def analyze(expression):
    try:
        for branch in branches(expression):
            witness = branch_witness(branch)
            if witness is not None:
                return Analysis("satisfiable", witness)
        return Analysis("unsatisfiable")
    except BudgetExceeded:
        return Analysis("unknown")


def stable_entry(expression, keep, negative=False):
    """Retain only immutable hard entry literals; mutable entry data can change.

    Dropping literals after pushing Not inward over-approximates eligibility.
    Race/class advice is intentionally not inherited as a hard step filter.
    """
    kind, *args = expression
    if kind == "not":
        return stable_entry(args[0], keep, not negative)
    if kind == "atom":
        return (negate(expression) if negative else expression) if args[0] in keep else both()
    conjunction = (kind == "and") != negative
    return (both if conjunction else either)(*(stable_entry(child, keep, negative) for child in args))


def step_blocks(route):
    """Visit every ordinary/scenario/parallel declaration without flattening order."""
    for name in ("steps", "scenarios"):
        entries = route.get(name, {})
        if not isinstance(entries, dict):
            continue
        if entries and any(isinstance(s, dict) and "steps" in s for s in entries.values()):
            for index, scenario in entries.items():
                yield f"{name}[{index}].steps", scenario.get("steps", {}), None
        elif name == "steps":
            yield name, entries, None
    for index, group in route.get("parallelSteps", {}).items():
        yield f"parallelSteps[{index}].steps", group.get("steps", {}), group.get("conditions", {})


def completion_analysis(route, model):
    """Return ``(gap_analysis, terminal_paths)`` for ordinary explicit endings.

    UNSAT proves no abstract state admitted by stable entry gates skips every
    explicit marker. SAT describes a possible gap, without a temporal proof.
    UNKNOWN with terminal paths means the branch budget was exceeded. UNKNOWN
    with no paths means this route has a temporary/scenario lifecycle outside
    this analysis. A normal route without markers has a satisfiable empty gap.
    """
    if route.get("temporary"):
        return Analysis("unknown"), []
    steps = route.get("steps", {})
    if any(isinstance(step, dict) and "steps" in step for step in steps.values()) or "scenarios" in route:
        return Analysis("unknown"), []
    terminals = [(index, step) for index, step in steps.items()
                 if isinstance(step, dict) and step.get("RouteCompleted")]
    stable_fields = {"Faction"}
    if model.class_category is not None and route.get("category") == model.class_category:
        stable_fields.add("Class")
    route_entry = stable_entry(model.expression(route.get("conditions")), stable_fields)
    available = either(*(model.expression(step) for _, step in terminals))
    return analyze(both(route_entry, negate(available))), [f"steps[{index}]" for index, _ in terminals]


def audit_routes(catalog):
    """Return conservative findings for all declarations supplied by the caller."""
    model = ConditionModel(catalog)
    findings = []
    def report(key, path, rule, message, **evidence):
        findings.append(dict(severity="warning", rule=rule, route=key, path=path,
                             message=message, evidence=evidence))

    for key, route in sorted(catalog.routes.items()):
        main_pickups = {q for _, block, activation in step_blocks(route) if activation is None
                        for step in block.values() if isinstance(step, dict)
                        for q in values(step.get("PickUp", {})) if step.get("PickUp")}
        for base, steps, group in step_blocks(route):
            if group is not None:
                activation = model.expression(group)
                status = analyze(activation).status
                if status == "unsatisfiable":
                    report(key, base.removesuffix(".steps") + ".conditions", "progression.impossible-group",
                           "Parallel activation conditions are contradictory; this group cannot activate.", classification="unreachable", conditions=group)
                elif status == "satisfiable":
                    for step in steps.values():
                        for quest in values(step.get("PickUp", {})) if step.get("PickUp") else []:
                            if quest not in main_pickups and analyze(both(activation, atom("quest-on:" + str(quest), "==", False))).status == "unsatisfiable":
                                report(key, base.removesuffix(".steps") + ".conditions", "progression.group-self-initialization",
                                       "This group's pickup cannot initialize its own active-quest activation predicate; acquisition must occur externally or in another group.", questID=quest, classification="external-initialization", witness=analyze(activation).witness)
            for index, step in steps.items():
                if not isinstance(step, dict):
                    continue
                path = f"{base}[{index}]"
                expression = model.expression(step)
                state = analyze(expression)
                if state.status == "unknown":
                    report(key, path, "progression.analysis-budget", "Condition expansion exceeded the analysis bound; reachability is unknown.")
                    continue
                if state.status == "unsatisfiable":
                    report(key, path, "progression.impossible-filter", "Filters contradict each other; the engine skips this instruction once data are known.", classification="unreachable", filters={k: v for k, v in step.items() if k in model.fields})
                    continue
                # An active goal whose unmet state is excluded cannot teach or
                # collect the requested target. It need not stall the cursor.
                goals = []
                if "SkillGoal" in step:
                    goal = step["SkillGoal"]
                    goals.append(("SkillGoal", atom("skill:" + str(goal["skillID"]), ">=", goal["rank"])))
                if "Reputation" in step:
                    goals.append(("Reputation", model.predicate("ReputationLevel", step["Reputation"])))
                for name, goal in goals:
                    if analyze(both(expression, negate(goal))).status == "unsatisfiable":
                        report(key, path, "progression.goal-already-required", f"{name} is visible only after its target is reached; it cannot guide the unmet target.", classification="skipped-training", witness=state.witness, goal=step[name])
                learn = step.get("LearnProfession")
                if learn and analyze(both(expression, atom("spell:" + str(learn), "==", False))).status == "unsatisfiable":
                    report(key, path, "progression.learning-already-required", "Learning is shown only when its spell is already known.", spellID=learn, witness=state.witness)
                for collection_entry in values(step.get("LootItems", {})) if step.get("LootItems") else []:
                    if not isinstance(collection_entry, dict) or "quantity" not in collection_entry:
                        continue
                    target = atom("item:" + str(collection_entry["itemID"]) + (":bank" if collection_entry.get("includeBank") else ""), ">=", collection_entry["quantity"])
                    if analyze(both(expression, negate(target))).status == "unsatisfiable":
                        report(key, path, "progression.collection-already-required", "Collection is visible only when the requested item quantity is already owned.", item=collection_entry, witness=state.witness)
                for action in ("Done", "Qpart", "QpartPart"):
                    quests = step.get(action, {})
                    for quest in (quests.keys() if action.startswith("Qpart") else values(quests)):
                        if not quests:
                            continue
                        needed = atom("quest-on:" + str(quest), "==", True)
                        completed = atom("quest-complete:" + str(quest), "==", True)
                        if analyze(both(expression, needed)).status == "unsatisfiable":
                            missing = analyze(both(expression, negate(completed)))
                            if missing.status == "satisfiable":
                                report(key, path, "progression.quest-excluded-by-filter", f"{action} excludes an active quest it can still wait for; external acquisition or manual recovery may be needed.", questID=quest, witness=missing.witness, classification="possible-wait")
                for quest in values(step.get("PickUp", {})) if step.get("PickUp") else []:
                    unmet = both(atom("quest-on:" + str(quest), "==", False), atom("quest-complete:" + str(quest), "==", False))
                    if analyze(both(expression, unmet)).status == "unsatisfiable":
                        report(key, path, "progression.pickup-already-required", "Pickup filters exclude the state in which acceptance is needed; the handler only acknowledges an already acquired/completed quest.", questID=quest, witness=state.witness)
        missing, terminal_paths = completion_analysis(route, model)
        if terminal_paths and missing.status == "unknown":
            report(key, "steps", "progression.analysis-budget", "Completion condition expansion exceeded the analysis bound; terminal coverage is unknown.", terminalPaths=terminal_paths, analysis="completion")
        elif terminal_paths and missing.status == "satisfiable":
            report(key, "steps", "progression.conditional-terminal", "Some abstract states admitted by stable entry gates skip every explicit completion marker; ordinary array exhaustion does not record completion or dequeue the route.", witness=missing.witness, terminalPaths=terminal_paths, classification="possible-unrecorded-completion", temporalProof=False)
    # Forever requires ANY completed compatible predecessor, not ALL. Compute
    # a deliberately permissive bootstrap closure, allowing unknown references
    # as external entry points and ignoring compatibility. If even that closure
    # cannot enter a component, its first completion needs pre-existing history.
    forever = {key for key, route in catalog.routes.items()
               if route.get("gameVersion") == catalog.enums.get("GAME_VERSIONS", {}).get("Forever", object())
               or route.get("expansion") == catalog.enums.get("EXPANSIONS", {}).get("Forever", object())}
    dependencies = {key: set(values(catalog.routes[key].get("requiredRoute", {}))) if catalog.routes[key].get("requiredRoute") else set()
                    for key in forever}
    entered = {key for key, required in dependencies.items() if not required or required - forever}
    while True:
        completed_labels = {catalog.routes[key].get("label") for key in entered}
        additions = {key for key, required in dependencies.items() if key not in entered
                     and (required & entered or catalog.routes[key].get("label") in completed_labels)}
        if not additions:
            break
        entered.update(additions)
    for key in sorted(forever - entered):
        report(key, "requiredRoute", "progression.closed-prerequisite-component",
               "No prerequisite chain reaches an entry route, even treating alternatives permissively; fresh completion history cannot initialize this component.",
               requiredRoutes=sorted(dependencies[key]), classification="requires-existing-completion", initialCompletedRoutes=[], compatibility="over-approximated")
    return findings
