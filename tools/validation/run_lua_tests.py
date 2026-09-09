"""Run the Midnight route regression checks using the Lua 5.1 runtime from lupa.

Alternatively, run `lua tools/validation/midnight_speedrun_alt_test.lua` from the repo root.
"""

from pathlib import Path
from collections import defaultdict
import csv
import os
import sys
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


def lua_array_values(table):
    """Return a Lua array in numeric-index order."""
    return [table[index] for index in range(1, len(table) + 1)]


def audit_route(root, runtime):
    """Compare the executable route with independently collected quest prerequisites."""
    key = "2393-Midnight-Speedrun-alt"
    route = runtime.globals().APR.RouteQuestStepList[key]
    steps = lua_array_values(route.steps)
    for group in lua_array_values(route.parallelSteps):
        steps.extend(lua_array_values(group.steps))
    steps.sort(key=lambda step: step._index)
    pickups, handins, objectives = defaultdict(list), defaultdict(list), defaultdict(set)
    for step in steps:
        for field, records in (("PickUp", pickups), ("Done", handins)):
            for quest in (step[field].values() if step[field] else []):
                records[quest].append(step._index)
        for field in ("Qpart", "QpartPart", "Fillers"):
            for quest, indexes in (step[field].items() if step[field] else []):
                objectives[quest].update(indexes.values())

    scripts = [element.attrib["file"] for element in ET.parse(root / "Routes/RouteList.xml").getroot()]
    route_file = f"Routes/Midnight/midnight-Speedrun/{key}.lua"
    assert scripts.count(route_file) == 1, "The route must be loaded exactly once"
    assert all((root / path).is_file() for path in scripts), "A registered route file is missing"
    toc = (root / "APR.toc").read_text(encoding="utf-8-sig")
    assert "120100" in toc.splitlines()[0]
    assert toc.index("APR-Core/features/navigation/WorldCoordinateConverter.lua") < toc.index("Routes/RouteList.xml")

    reference_path = root / f"docs/routes/{key}-quests.csv"
    if not reference_path.is_file():
        print(f"Quest audit skipped: optional snapshot not found at {reference_path.relative_to(root)}")
        return

    with reference_path.open(encoding="utf-8", newline="") as handle:
        records = {int(row["quest_id"]): row for row in csv.DictReader(handle)}
    assert set(records) == set(pickups) == set(handins), "Quest audit and executable route disagree"
    assert set(objectives) <= set(pickups), "An objective has no corresponding quest pickup"
    for quest, record in records.items():
        assert pickups[quest] == list(map(int, record["pickup_steps"].split())), quest
        assert handins[quest] == list(map(int, record["turnin_steps"].split())), quest
        assert objectives[quest] == set(map(int, record["apr_objective_indexes"].split())), quest
        if record["att_base_min_level"] == "unknown":
            assert quest == 91281, "Only the supplied introductory quest lacks an ATT minimum"
        else:
            assert int(record["att_base_min_level"]) < 90, f"Endgame quest included: {quest}"
        for entry in filter(None, record["parent_resolution"].split("; ")):
            parent_text, resolution = entry.split(":", 1)
            parent = int(parent_text)
            if resolution == "ordered":
                assert min(handins[parent]) < min(pickups[quest]), (quest, parent)
            elif resolution == "accepted-wrapper":
                assert min(pickups[parent]) < min(pickups[quest]), (quest, parent)
                assert min(handins[quest]) < min(handins[parent]), (quest, parent)
            else:
                assert resolution in {
                    "optional-breadcrumb-omitted",
                    "adventure-map-alternative-94871",
                    "supplied-intro-skip-and-account-campaign",
                    "account-campaign-adventure-mode",
                }, (quest, parent, resolution)
                assert route.conditions.HasAchievement == 42045

    print(f"Quest audit: {len(records)} quests; prerequisites, objectives and XML registration passed")


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[2]
    os.chdir(root)
    if "--performance-only" not in sys.argv:
        runtime = LuaRuntime(unpack_returned_tuples=True)
        runtime.execute((root / "tools/validation/midnight_speedrun_alt_test.lua").read_text(encoding="utf-8"))
        audit_route(root, runtime)
    performance_runtime = LuaRuntime(unpack_returned_tuples=True)
    performance_runtime.execute((root / "tools/validation/quest_order_performance_test.lua").read_text(encoding="utf-8"))
    progression_runtime = LuaRuntime(unpack_returned_tuples=True)
    progression_runtime.execute((root / "tools/validation/step_progression_test.lua").read_text(encoding="utf-8"))
    zone_runtime = LuaRuntime(unpack_returned_tuples=True)
    zone_runtime.execute((root / "tools/validation/zone_conditions_test.lua").read_text(encoding="utf-8"))
    delve_level_runtime = LuaRuntime(unpack_returned_tuples=True)
    delve_level_runtime.execute((root / "tools/validation/delve_level_policy_test.lua").read_text(encoding="utf-8"))
    silvermoon_runtime = LuaRuntime(unpack_returned_tuples=True)
    silvermoon_runtime.execute((root / "tools/validation/silvermoon_intro_test.lua").read_text(encoding="utf-8"))
