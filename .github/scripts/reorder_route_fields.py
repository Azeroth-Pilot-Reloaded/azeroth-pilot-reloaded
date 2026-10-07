#!/usr/bin/env python3
"""Order route step fields like APR Route Recorder's Lua editor, without evaluating Lua.

Only direct fields of steps/parallelSteps are moved. Source text, nested payloads,
comments, route metadata and step order are retained.
"""

from __future__ import annotations

import argparse
from functools import cmp_to_key
from pathlib import Path
import re
import sys

from fix_route_indexes import all_route_files, get_repo_root, process_files, staged_route_files


ROOT = Path(__file__).resolve().parents[2]

# Mirrors utils/Utils.lua: CustomSortKeys and CustomSortStepKeys in APR-Route-Recorder.
PRIORITY = """
Waypoint TakePortal WaypointDB NonSkippableWaypoint PickUp PickUpDB Qpart QpartPart QpartDB
Done DoneDB LeaveQuests Treasure Scenario Achievement EnterScenario DoScenario LeaveScenario
EnterInstance LeaveInstance LearnProfession Grind Reputation DropQuest DroppableQuest LootItems
LootMoney UseItem UseSpell ChromiePick SetHS GetFP UseHS UseDalaHS UseGarrisonHS UseFlightPath
Name NodeID WarMode Coord Coords Zone Zones Fillers BuyMerchant Button SpellButton
ExtraLineText ExtraLineText2 ExtraLineText3 ExtraLineText4 ExtraLineText5 ExtraLineText6
ExtraLineText7 GossipOptionIDs Range NoArrow DenyNPC NpcDismount skipForLvl IsAdventureMap
ZoneStepTrigger Buffs ReputationLevel SkipForReputation SkipForPrimaryProfessions
""".split()
PRIORITY_INDEX = {key: index for index, key in enumerate(PRIORITY)}
CONDITIONS = set("""
VendorMoney Money ItemCount EquippedItemStat Hardcore AllOf Not Skill SkipForPrimaryProfessions
EquippedItem Collection Faction OnlyInZones SkipInZones Race Gender Class ClassNot ClassSpec
Level MinLevel MaxLevel BeLvl SkipForLvl AlliedRace Event HasAchievement DontHaveAchievement
HasAura DontHaveAura HasSpell DontHaveSpell IsQuestReadyForTurnIn IsQuestOnQuest IsQuestNotOnQuest
AnyOf ReputationLevel SkipForReputation IsQuestCompleted IsQuestUncompleted IsOneOfQuestsCompleted
IsOneOfQuestsUncompleted IsOneOfQuestsCompletedOnAccount IsOneOfQuestsUncompletedOnAccount
IsQuestsCompleted IsQuestsUncompleted IsQuestsCompletedOnAccount IsQuestsUncompletedOnAccount
QuestLineSkip PickedLoa IsCampaignQuest InterfaceVersion
""".split())
COMPANIONS = {"NonSkippableWaypoint", "NodeID", "Boat"}
GROUPS = {
    "DroppableQuest": 2, "Fillers": 3, "Note": 4, "ExtraLine": 4, "_comment": 4,
    "Coord": 5, "Coords": 5, "Range": 6,
    "Gossip": 7, "GossipOptionIDs": 7, "GossipETA": 7,
    "Button": 8, "SpellButton": 8, "ExtraActionB": 8,
    "conditions": 10, "skipForLvl": 10, "InterfaceVersionExact": 10,
    "Zone": 11, "Zones": 11, "_index": 12,
}
FALLBACK_ACTIONS = ("PickUpDB", "QpartDB", "DoneDB", "WaypointDB", "DroppableQuest",
                    "Note", "GossipOptionIDs", "Gossip", "Fillers")


def action_keys() -> set[str]:
    """Read APR's action lists so newly added actions automatically sort first."""
    source = (ROOT / "APR-Core/utils/StepUtils.lua").read_text(encoding="utf-8")
    actions = {"Waypoint", "DropQuest", "Group", "GroupTask", "MountVehicle", "VehicleExit", "EquipItem"}
    for name in ("mainStepOptions", "secondaryStepOptions"):
        match = re.search(r"APR\." + name + r"\s*=\s*\{([^}]+)\}", source)
        if not match:
            raise ValueError(f"Cannot find APR.{name}")
        actions.update(re.findall(r'"(\w+)"', match[1]))
    return actions


def ordered_keys(values: dict[str, str], actions: set[str]) -> list[str]:
    base = sorted(values, key=lambda key: (0, PRIORITY_INDEX[key]) if key in PRIORITY_INDEX else (1, key))
    ranks = {}
    for key in base:
        rank = GROUPS.get(key)
        if rank is None:
            if re.fullmatch(r"(?:ExtraLineText|TrigText)\d*", key):
                rank = 4
            elif key.endswith("DB") or key in COMPANIONS:
                rank = 2
            elif key in CONDITIONS:
                rank = 10
            elif values[key] != "false" and key in actions:
                rank = 1
        ranks[key] = rank if rank is not None else 9
    if 1 not in ranks.values():
        for key in FALLBACK_ACTIONS:
            if key in values and values[key] not in ("false", "nil"):
                ranks[key] = 1
                break
    positions = {key: index for index, key in enumerate(base)}

    def compare(a: str, b: str) -> int:
        if a == b:
            return 0
        if ranks[a] != ranks[b]:
            return ranks[a] - ranks[b]
        if ranks[a] == 4:
            if a == "Note" or b == "Note":
                return -1 if a == "Note" else 1
            ma, mb = re.fullmatch(r"([A-Za-z]+)(\d*)", a), re.fullmatch(r"([A-Za-z]+)(\d*)", b)
            if ma and mb and ma[1] == mb[1]:
                difference = int(ma[2] or 1) - int(mb[2] or 1)
                if difference:
                    return difference
        return positions[a] - positions[b]

    return sorted(base, key=cmp_to_key(compare))


# Long strings/comments and quoted strings are single tokens: braces, commas,
# escaped quotes and route-looking text inside them never participate in parsing.
LEXEME = re.compile(
    r"(?P<space>\s+)|(?P<comment>--\[(?P<ceq>=*)\[.*?\](?P=ceq)\]|--[^\r\n]*)"
    r"|(?P<string>\[(?P<seq>=*)\[.*?\](?P=seq)\]|\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*')"
    r"|(?P<word>[A-Za-z_]\w*)|(?P<number>\d+(?:\.\d+)?)|(?P<symbol>.)", re.S,
)


class LuaSource:
    def __init__(self, text: str):
        self.text = text
        self.tokens = [m for m in LEXEME.finditer(text) if m.lastgroup not in ("space", "comment")]
        self.pairs = {}
        stack = []
        for index, token in enumerate(self.tokens):
            value = token[0]
            if token.lastgroup != "symbol":
                continue
            if value in ("{", "[", "("):
                stack.append(index)
            elif value in ("}", "]", ")"):
                if not stack or self.tokens[stack[-1]][0] != {"}": "{", "]": "[", ")": "("}[value]:
                    raise ValueError("Unbalanced Lua delimiters")
                opening = stack.pop()
                self.pairs[opening] = index
        if stack:
            raise ValueError("Unbalanced Lua delimiters")

    def fields(self, opening: int) -> list[tuple[str | None, int, int, int]]:
        """Return (key, first token, value token, last token) for direct fields."""
        fields = []
        closing = self.pairs[opening]
        index = opening + 1
        while index < closing:
            first = index
            key = None
            if self.tokens[index].lastgroup == "word" and self.tokens[index + 1][0] == "=":
                key = self.tokens[index][0]
                index += 2
            elif self.tokens[index][0] == "[" and self.tokens[self.pairs[index] + 1][0] == "=":
                key_token = self.tokens[index + 1][0]
                if self.pairs[index] == index + 2 and re.fullmatch(r'''["'][A-Za-z_]\w*["']''', key_token):
                    key = key_token[1:-1]
                index = self.pairs[index] + 2
            value = index
            while index < closing and self.tokens[index][0] not in (",", ";"):
                if self.tokens[index][0] == "function":
                    raise ValueError("Function-valued route fields cannot be safely reordered")
                index = self.pairs.get(index, index) + 1
            last = index if index < closing else index - 1
            fields.append((key, first, value, last))
            index += 1
        return fields

    def inline_end(self, start: int, limit: int) -> int:
        """Keep a comment on the same line attached to the preceding field."""
        position = start
        while position < limit and self.text[position] in " \t":
            position += 1
        if not self.text.startswith("--", position):
            return start
        comment = LEXEME.match(self.text, position)
        if not comment or comment.lastgroup != "comment":
            return start
        return min(comment.end(), limit)

    def reorder_step(self, opening: int, actions: set[str]) -> tuple[int, int, str] | None:
        fields = self.fields(opening)
        if not fields:
            return None
        keys = [field[0] for field in fields]
        if None in keys or len(set(keys)) != len(keys):
            raise ValueError("Step fields must have distinct literal names to be safely reordered")
        values = {key: self.tokens[value][0] for key, _, value, _ in fields}
        ordered = ordered_keys(values, actions)
        if keys == ordered:
            return None
        start = self.tokens[opening].end()
        closing = self.tokens[self.pairs[opening]].start()
        chunks = {}
        for offset, (key, _, _, last) in enumerate(fields):
            token = self.tokens[last]
            limit = self.tokens[fields[offset + 1][1]].start() if offset + 1 < len(fields) else closing
            end = self.inline_end(token.end(), limit)
            chunk = self.text[start:end]
            # A field originally last may lack a separator and move to the middle.
            if token[0] not in (",", ";") and key != ordered[-1]:
                relative = token.end() - start
                chunk = chunk[:relative] + "," + chunk[relative:]
            chunks[key] = chunk
            start = end
        body_start = self.tokens[opening].end()
        return body_start, closing, "".join(chunks[key] for key in ordered) + self.text[start:closing]

    def step_tables(self):
        def value_table(fields, name):
            return next((value for key, _, value, _ in fields
                         if key == name and self.tokens[value][0] == "{"), None)

        def steps(opening):
            for _, _, value, _ in self.fields(opening):
                if self.tokens[value][0] == "{":
                    yield value

        for index in range(len(self.tokens) - 7):
            if [token[0] for token in self.tokens[index:index + 4]] != ["APR", ".", "RouteQuestStepList", "["]:
                continue
            assignment = self.pairs[index + 3] + 1
            if [token[0] for token in self.tokens[assignment:assignment + 2]] != ["=", "{"]:
                continue
            route_fields = self.fields(assignment + 1)
            main = value_table(route_fields, "steps")
            if main is not None:
                yield from steps(main)
            parallel = value_table(route_fields, "parallelSteps")
            if parallel is not None:
                for group in steps(parallel):
                    group_steps = value_table(self.fields(group), "steps")
                    if group_steps is not None:
                        yield from steps(group_steps)


def normalize_text(text: str) -> str:
    source = LuaSource(text)
    actions = action_keys()
    replacements = [replacement for table in source.step_tables()
                    if (replacement := source.reorder_step(table, actions)) is not None]
    for start, end, replacement in sorted(replacements, reverse=True):
        text = text[:start] + replacement + text[end:]
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*", help="Route Lua files to reorder.")
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument("--staged", action="store_true", help="Reorder staged route blobs only.")
    selection.add_argument("--all", action="store_true", help="Reorder every Routes/**/*.lua file.")
    parser.add_argument("--no-stage", action="store_true", help="Do not update the Git index.")
    parser.add_argument("--quiet", action="store_true", help="Only report changes or errors.")
    args = parser.parse_args()
    root = get_repo_root()
    if args.staged:
        targets = staged_route_files(root)
    elif args.all:
        targets = all_route_files(root)
    elif args.files:
        targets = [Path(path).resolve() for path in args.files]
    else:
        parser.error("Use --staged, --all, or pass file paths.")
    try:
        changed = process_files(targets, root, normalize_text, staged=args.staged, no_stage=args.no_stage)
    except (ValueError, UnicodeError) as error:
        print(f"Cannot reorder route fields: {error}", file=sys.stderr)
        return 1
    if changed or not args.quiet:
        print(f"Reordered step fields in {len(changed)} route file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
