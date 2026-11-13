"""Explicit offline instance authoring, never run by tests or addon startup.

Supply an instance source directory (Data.lua, Curated.lua), a quest database
and a corroborating JSONL dataset. Lua declarations run in an empty environment.
No manifests or locale files are written. Existing detailed runs are preserved.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from lupa.lua51 import LuaRuntime
from tests.routes.route_loader import plain


class Expr(str):
    pass


def lua(value, indent=0):
    if isinstance(value, Expr):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, (float, int)):
        return str(value)
    if isinstance(value, list):
        return "{ " + ", ".join(lua(v, indent) for v in value) + " }"
    if isinstance(value, dict):
        if not value:
            return "{}"
        return "{\n" + "".join(" " * (indent + 4) +
            (k if isinstance(k, str) and re.fullmatch(r"[A-Za-z_]\w*", k) else "[" + lua(k) + "]") +
            " = " + lua(v, indent + 4) + ",\n" for k, v in sorted(value.items(), key=lambda p: (isinstance(p[0], str), p[0]))) + " " * indent + "}"
    raise TypeError(value)


def values(table):
    return [v for _, v in sorted((table or {}).items(), key=lambda p: int(p[0]))]


def declared_tables(directory):
    runtime = LuaRuntime(register_eval=False, register_builtins=False)
    ns = runtime.table()
    evaluate = runtime.eval('function(s, ns) local f=assert(loadstring(s)); setfenv(f, {}); f("Source", ns) end')
    for name in ("Data.lua", "Curated.lua"):
        evaluate((directory / name).read_text(encoding="utf-8-sig"), ns)
    return plain(ns)


def encounter_reference(path):
    """Read constructor-style encounter declarations without client APIs."""
    runtime = LuaRuntime(unpack_returned_tuples=True, register_eval=False, register_builtins=False,
                         max_memory=128 * 1024 * 1024)
    extract = runtime.execute('''
        local app, roots = {}, {}
        setmetatable(app, {__index=function(_, key)
            if key:match("^Create") then return function(id, data, extra)
                if type(data) ~= "table" then data = extra or {} end
                if key == "CreateInstance" then data._instance = id end
                if key == "CreateEncounter" then data._encounter = id end
                if key == "CreateNPC" then data._npc = id end
                return data
            end end
            error("Unsupported source constructor: " .. key)
        end})
        app.asset = function(name) return name end
        app.ResolveQuestData = function(data) return data end
        app.Settings, app.L, app.FactionID, app.Level = {}, {}, 1, 80
        app.OnUpdateDB = setmetatable({}, {__index=function() return function() end end})
        app.OnTooltipDB = app.OnUpdateDB
        app.AddEventHandler = function(_, callback) callback(roots) end
        return function(source)
            local chunk = assert(loadstring(source))
            setfenv(chunk, {type=type, ipairs=ipairs, pairs=pairs, select=select,
                Enum={FlightPathFaction={Horde=1}}, GetCVar=function() return "US" end})
            debug.sethook(function() error("Source instruction budget exceeded") end, "", 10000000)
            local ok, err = pcall(chunk, "InstanceSource", app)
            debug.sethook()
            if not ok then error(err) end
            local result = {}
            local function visit(node, instance, saved, depth)
                assert(depth < 60)
                instance = node._instance or instance
                saved = node._instance and node.savedInstanceID or saved
                if node._encounter or node._npc then
                    local npcs = {}
                    if node.npcID then npcs[#npcs+1] = node.npcID end
                    if node._npc then npcs[#npcs+1] = node._npc end
                    for _, id in ipairs(node.crs or {}) do npcs[#npcs+1] = id end
                    if #npcs > 0 then result[#result+1] = {instance=saved or instance,
                        encounter=node._encounter, npcs=npcs} end
                end
                for _, child in ipairs(node.g or {}) do visit(child, instance, saved, depth+1) end
                for _, child in ipairs(node) do
                    if type(child) == "table" then visit(child, instance, saved, depth+1) end
                end
            end
            for _, root in pairs(roots) do visit(root, nil, nil, 0) end
            return result
        end
    ''')
    return values(plain(extract(path.read_text(encoding="utf-8-sig"))))


def slug(name):
    return re.sub(r"[^A-Za-z0-9]+", "-", name).strip("-")


def quest_dependencies(quest):
    """Single prerequisites are OR; Group prerequisites are AND."""
    single = [int(v) for v in values(quest.get("preQuestSingle"))]
    group = [int(v) for v in values(quest.get("preQuestGroup"))]
    if any(v <= 0 for v in single + group):
        raise ValueError("active/negative prerequisite")
    return single, group


def schedule_quests(entries, enter, leave, kills):
    """Topologically schedule quest actions, crossing the instance when needed.

    Every quest is a pickup/objective/turn-in chain. A later pickup cannot be
    emitted before its prerequisite turn-in, even across an instance boundary.
    """
    ends = {q: (q, len(stages) - 1) for q, _, stages in entries}
    nodes = []
    for q, prerequisites, stages in entries:
        for i, (inside, step) in enumerate(stages):
            dependencies = ({(q, i - 1)} if i else {ends[p] for p in prerequisites if p in ends})
            nodes.append(((q, i), dependencies, inside, step))
    complete, output = set(), []
    inside, ran_bosses = False, False
    while len(complete) < len(nodes):
        progressed = False
        while True:
            ready = [n for n in nodes if n[0] not in complete and n[1] <= complete and n[2] == inside]
            if not ready:
                break
            # Initial interior NPC pickups precede combat; dropped starters do not.
            if inside and not ran_bosses:
                pickups = [n for n in ready if n[3].get("PickUp") and not n[3].get("Button")]
                if not pickups:
                    output.extend(kills)
                    ran_bosses = True
                else:
                    ready = pickups
            for identity, _, _, step in ready:
                output.append(step)
                complete.add(identity)
                progressed = True
        remaining = [n for n in nodes if n[0] not in complete]
        if not remaining:
            break
        if not any(n[1] <= complete and n[2] != inside for n in remaining):
            raise ValueError("Unresolvable quest-stage dependency graph")
        if inside:
            output.append(leave.copy())
        else:
            output.append(enter.copy())
        inside = not inside
    if not ran_bosses:
        if not inside:
            output.append(enter.copy())
            inside = True
        output.extend(kills)
    if inside:
        output.append(leave.copy())
    return output


def table_end(source, start):
    """Return the end of a Lua table while respecting quoted strings/comments."""
    depth, i = 0, start
    while i < len(source):
        c = source[i]
        if source.startswith("--", i):
            i = source.find("\n", i)
            if i < 0:
                break
            continue
        if c in ('"', "'"):
            quote = c
            i += 1
            while i < len(source):
                if source[i] == "\\":
                    i += 2
                    continue
                if source[i] == quote:
                    break
                i += 1
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError("Unclosed Lua table")


def step_blocks(source):
    match = re.search(r"^    steps = \{", source, re.M)
    if not match:
        raise ValueError("Missing ordinary route steps")
    begin = source.index("{", match.start())
    end = table_end(source, begin)
    blocks, i = [], begin + 1
    while i < end - 1:
        if source[i] == "{":
            stop = table_end(source, i)
            blocks.append(source[i:stop])
            i = stop
        else:
            i += 1
    return begin, end, blocks


def replace_step_blocks(source, blocks):
    begin, end, _ = step_blocks(source)
    result = []
    for i, block in enumerate(blocks, 1):
        if re.search(r"_index\s*=", block):
            block = re.sub(r"_index\s*=\s*\d+", "_index = " + str(i), block)
        else:
            block = block[:-1] + "    _index = " + str(i) + ",\n        }"
        result.append("        " + block)
    return source[:begin] + "{\n" + ",\n".join(result) + ",\n    }" + source[end:]


def clean_legacy_routes(root, scope):
    """Remove unrelated leveling activities without renaming historical keys."""
    from tests.routes.route_loader import load_routes
    paths = sorted(p for faction in ("Alliance", "Horde") for p in (root / "Routes/Forever/Dungeons" / faction).glob("*.lua"))
    catalog = load_routes(paths)
    count = 0
    for path in paths:
        matches = [(k, v) for k, v in catalog.routes.items() if catalog.sources[k] == path.relative_to(ROOT).as_posix()]
        if len(matches) != 1:
            raise ValueError("Legacy authoring expects one declaration per file")
        key, route = matches[0]
        name = path.name
        instances = ([3065] if "Hall_of_Thanes" in name or "Loch_Modan" in name else
                     [2999] if "Ruins_of_Lordaeron" in name else [36] if "Deadmines" in name or "Westfall" in name or "Elwynn" in name else
                     [389] if "Ragefire" in name else [43] if "Wailing" in name else
                     [43, 48] if "Darkshore" in name else [2999, 389, 33] if "Silverpine" in name else [389, 43, 47])
        allowed = set().union(*(scope.get(i, set()) for i in instances))
        source = path.read_text(encoding="utf-8")
        _, _, blocks = step_blocks(source)
        if len(blocks) != len(route["steps"]):
            raise ValueError("Cannot align legacy steps: " + key)
        kept = []
        for step, block in zip(values(route["steps"]), blocks):
            related = set()
            for field in ("PickUp", "Done", "Qpart", "Waypoint", "UseFlightPath", "GetFP", "UseHS", "SetHS"):
                value = step.get(field)
                if isinstance(value, dict):
                    related.update(value if field == "Qpart" else value.values())
                elif isinstance(value, int):
                    related.add(value)
            if not related.intersection(allowed) and not step.get("Dungeon") and not step.get("RouteCompleted"):
                continue
            for field in ("PickUp", "Done", "Qpart", "Fillers"):
                value = step.get(field)
                if not isinstance(value, dict):
                    continue
                replacement = ({q: values(v) for q, v in value.items() if q in allowed}
                               if field in ("Qpart", "Fillers") else [q for q in value.values() if q in allowed])
                match = re.search(r"\b" + field + r"\s*=\s*\{", block)
                if not match:
                    continue
                begin = block.index("{", match.start())
                end = table_end(block, begin)
                if replacement:
                    block = block[:begin] + lua(replacement, 12) + block[end:]
                else:
                    stop = end + (1 if block[end:end + 1] == "," else 0)
                    block = block[:match.start()] + block[stop:]
            kept.append(block)
        if not kept or "RouteCompleted" not in kept[-1]:
            kept.append("{\n            RouteCompleted = true,\n            _index = 1,\n        }")
        source = replace_step_blocks(source, kept)
        source = re.sub(r'^        \{ route = "([^"]+)"[^\n]*\n',
                        lambda match: match[0] if "-Dungeons-" in match[1] else "", source, flags=re.M)
        # Remove leveling-only background shopping/training from these chapters.
        match = re.search(r"^    parallelSteps = \{", source, re.M)
        if match:
            end = table_end(source, source.index("{", match.start()))
            source = source[:match.start()] + source[end + 1:].lstrip("\n")
        if len(kept) == 1 and "hiddenFromSelection" not in source:
            source = source.replace("    steps = {", "    hiddenFromSelection = true,\n    steps = {", 1)
        path.write_text(source, encoding="utf-8")
        count += 1
    return count


def extend_detailed_route(path, entries, bosses, key):
    """Retain authored mechanics; add absent prerequisites, quests and bosses."""
    from tests.routes.route_loader import load_routes
    catalog = load_routes([path])
    route = next(iter(catalog.routes.values()))
    known = set()
    for step in values(route["steps"]):
        for field in ("PickUp", "Done", "Qpart"):
            if isinstance(step.get(field), dict):
                known.update(step[field] if field == "Qpart" else step[field].values())
    for parallel in values(route.get("parallelSteps")):
        for step in values(parallel.get("steps")):
            known.update((step.get("PickUp") or {}).values())
    source = path.read_text(encoding="utf-8")
    _, _, blocks = step_blocks(source)
    rows = values(route["steps"])
    before, initial, interior, after = [], [], [], []
    inside_quests = {q for q, _, stages in entries if any(inside for inside, _ in stages)}
    later = set(inside_quests)
    for q, prerequisites, stages in entries:
        if any(p in later for p in prerequisites):
            later.add(q)
        if q in known:
            continue
        for inside, step in stages:
            if inside:
                target = initial if step.get("PickUp") and not step.get("Button") else interior
            else:
                target = after if q in later else before
            target.append(lua(step, 8))
    present = {s["KillNPC"]["npcID"] for s in rows if s.get("KillNPC")}
    rank = {npc: i for i, (npc, _) in enumerate(bosses)}
    for npc, name in bosses:
        if npc in present:
            continue
        following = next((i for i, step in enumerate(rows) if step.get("KillNPC") and rank.get(step["KillNPC"]["npcID"], -1) > rank[npc]), None)
        if following is None:
            following = next(i for i, step in enumerate(rows) if step.get("LeaveInstance"))
        step = {"KillNPC": {"dungeonKey": key, "npcID": npc, "name": name}, "Dungeon": key, "InstanceQuest": True, "NoArrow": True}
        rows.insert(following, step)
        blocks.insert(following, lua(step, 8))
    enter = next(i for i, step in enumerate(rows) if step.get("EnterInstance"))
    leave = next(i for i, step in enumerate(rows) if step.get("LeaveInstance"))
    blocks = before + blocks[:enter + 1] + initial + blocks[enter + 1:leave] + interior + blocks[leave:-1] + after + blocks[-1:]
    source = replace_step_blocks(source, blocks)
    path.write_text(source, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--instance-source", type=Path, required=True)
    parser.add_argument("--quest-database", type=Path, required=True)
    parser.add_argument("--reference-data", type=Path, required=True)
    parser.add_argument("--encounter-reference", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=ROOT)
    args = parser.parse_args()
    data = declared_tables(args.instance_source)
    encounter_rows = encounter_reference(args.encounter_reference)
    encounter_npcs = {row["encounter"]: values(row["npcs"]) for row in encounter_rows if row.get("encounter")}
    instance_npcs = {}
    for row in encounter_rows:
        instance_npcs.setdefault(row.get("instance"), set()).update(values(row["npcs"]))
    dbpath = args.quest_database
    with sqlite3.connect(f"file:{dbpath.as_posix()}?mode=ro", uri=True) as db:
        entities = {kind: {int(i): json.loads(raw) for i, raw in db.execute(
            "SELECT id,data_json FROM entities WHERE kind=?", (kind,))} for kind in ("Quest", "Npc", "Object", "Item")}
        zones = json.loads(db.execute("SELECT data_json FROM support WHERE name=?", ("ZoneDB",)).fetchone()[0])
    quests = entities["Quest"]
    reference_npcs = {row["id"]: row for line in (args.reference_data / "npc.jsonl").read_text(encoding="utf-8").splitlines() if (row := json.loads(line))}
    reference_quests = {row["id"]: row for line in (args.reference_data / "quest.jsonl").read_text(encoding="utf-8").splitlines() if (row := json.loads(line))}
    # Fill missing contracts using the corroborating structured export.
    for q, record in reference_quests.items():
        if not record.get("title") and q not in quests:
            continue
        quests.setdefault(q, {"name": record.get("title", "")})
        for target, source in (("requiredLevel", "min_level"), ("requiredRaces", "races"), ("requiredClasses", "classes")):
            if source in record:
                quests[q].setdefault(target, record[source])
    for filename, field in (("quest_start", "startedBy"), ("quest_end", "finishedBy")):
        for line in (args.reference_data / (filename + ".jsonl")).read_text(encoding="utf-8").splitlines():
            row = json.loads(line)
            typ = {"npc": "1", "object": "2", "item": "3"}.get(row["kind"])
            if row["quest"] not in quests:
                continue
            quest = quests[row["quest"]]
            if typ and not quest.get(field):
                quest[field] = {typ: {"1": row["id"]}}
    psobjectives = {}
    for line in (args.reference_data / "quest_objective.jsonl").read_text(encoding="utf-8").splitlines():
        row = json.loads(line)
        psobjectives.setdefault(row["quest"], set()).add(row["n"])
    for npc, record in reference_npcs.items():
        if record.get("name"):
            entities["Npc"].setdefault(npc, {"name": record["name"]})
    area_map_source = zones["private"]["areaIdToUiMapId"]
    area_maps = {int(a): int(m) for a, m in re.findall(r"\[(\d+)\]\s*=\s*(\d+)", area_map_source)}
    map_geometry = {r["ui_map"]: r for line in (args.reference_data / "ui_map.jsonl").read_text(encoding="utf-8").splitlines() if (r := json.loads(line))}
    # Legacy dungeon aliases are never modern interior coordinates.
    dungeon_areas = {int(v) for v in zones["instanceIdToAreaId"].values()}
    runtime = LuaRuntime(register_eval=False, register_builtins=False)
    runtime.execute("APR={}")
    runtime.execute((ROOT / "APR-Core/data/Dungeons/DungeonsForever.lua").read_text(encoding="utf-8"))
    catalog = plain(runtime.globals().APR.DungeonData.forever)
    by_instance = {v.get("instanceID"): k for k, v in catalog.items() if v.get("instanceID")}
    announced = {"The Drowned City": "DROWNED_CITY", "Krol'dok Stronghold": "KROLDOK", "Alcaz Prison": "ALCAZ_PRISON", "Blackmaw Hold": "BLACKMAW_HOLD", "The Shaper's Terrace": "SHAPERS_TERRACE"}
    notes = []
    stats = []
    patches = []
    quest_scope = {}
    translation_path = args.output / "tools/localization/forever-dungeons-translations.json"
    exports = json.loads(translation_path.read_text(encoding="utf-8")) if translation_path.exists() else {"enUS": {}, "frFR": {}}
    route_dir = args.output / "Routes/Forever/Dungeons/Shared"
    route_dir.mkdir(parents=True, exist_ok=True)
    definitions = {int(k): v.copy() for k, v in data["data"].items()}
    for q, fix in data["curated"].items():
        definitions.setdefault(int(q), {}).update(fix)
    for q, definition in definitions.items():
        chain = [int(v) for v in values(definition.get("chain"))]
        if definition.get("prev"):
            chain.append(int(definition["prev"]))
        if chain:
            chain.append(q)
            for previous, current in zip(chain, chain[1:]):
                if current in quests and previous in quests and not (quests[current].get("preQuestSingle") or quests[current].get("preQuestGroup")):
                    quests[current]["preQuestSingle"] = {"1": previous}

    def location(kind, entity_id):
        for area, spawns in sorted(entities[kind].get(entity_id, {}).get("spawns", {}).items(), key=lambda p: int(p[0])):
            area = int(area)
            if area in dungeon_areas or area >= 10000 and area < 10090:
                continue
            m = area_maps.get(area)
            if not m:
                continue
            for point in values(spawns):
                x, y = point.get("1"), point.get("2")
                if x is not None and y is not None and 0 < x < 100 and 0 < y < 100:
                    return m, x, y
        return None

    def position(step, point):
        if point:
            m, x, y = point
            step.update(Zone=m, Coord=Expr(f"APR.worldCoordinateConverter:ConvertMapCoordinate({m}, {x}, {y})"))
        else:
            step["NoArrow"] = True

    for inst, dungeon in sorted(data["dungeons"].items()):
        if dungeon.get("raid"):
            continue
        key = by_instance.get(inst) or announced.get(dungeon["name"])
        if not key:
            notes.append(f"{dungeon['name']}: no registered dungeon key; omitted")
            continue
        fix = data["curatedDungeons"].get(inst, {})
        base_bosses = {b["name"]: b for b in values(dungeon.get("bosses"))}
        names = values(fix.get("order")) or list(base_bosses)
        bosses = []
        encounters = {}
        encounter_names = {}
        npc_names = {}
        for name in names:
            name = {"Kirtonos": "Kirtonos the Herald", "Ras Frostwhisperer": "Ras Frostwhisper"}.get(name, name)
            boss = {**base_bosses.get(name, {"name": name}), **fix.get("bosses", {}).get(name, {})}
            npc = boss.get("npcID")
            encounter_ids = encounter_npcs.get(boss.get("encounter"), [])
            if npc and entities["Npc"].get(npc, {}).get("name") and entities["Npc"][npc]["name"] != name:
                name = entities["Npc"][npc]["name"]
            if npc and not entities["Npc"].get(npc) and len(encounter_ids) == 1:
                npc = encounter_ids[0]
            if not npc and len(encounter_ids) == 1:
                npc = encounter_ids[0]
            if not npc:
                matches = [i for i, n in entities["Npc"].items() if n.get("name") == name]
                if len(matches) == 1:
                    npc = matches[0]
            corroborated = npc and (entities["Npc"].get(npc, {}).get("name") == name or npc in encounter_ids or npc in instance_npcs.get(inst, set()))
            if not corroborated:
                notes.append(f"{dungeon['name']}: no corroborated NPC identity for {name}; omitted kill")
                continue
            if npc in reference_npcs and reference_npcs[npc].get("name", name) != name:
                notes.append(f"{dungeon['name']}: reference name mismatch for {npc}; omitted kill")
                continue
            npc_names[npc] = name
            encounter = boss.get("encounter")
            if encounter:
                encounters[encounter] = npc
                encounter_names[encounter] = name
            if not boss.get("rare") and name not in ("Lyn the Ignored", "Lord Valthalak", "Kormok"):
                bosses.append((npc, name))
        existing = catalog[key]
        merged_encounters = dict(existing.get("encounters", {}))
        for encounter, npc in encounters.items():
            previous = merged_encounters.get(encounter)
            if isinstance(previous, dict):
                previous = values(previous)
            if isinstance(previous, list):
                merged_encounters[encounter] = list(dict.fromkeys(previous + [npc]))
            else:
                merged_encounters[encounter] = npc
        # Add corrected/verified identifiers, leaving existing encounter metadata intact.
        patched = {**existing, "instanceID": inst, "areaID": int(zones["instanceIdToAreaId"].get(str(inst), existing.get("areaID", 0))),
                   "bosses": {**existing.get("bosses", {}), **{i: True for i in npc_names}},
                   "npcNames": {**existing.get("npcNames", {}), **npc_names},
                   "encounters": merged_encounters,
                   "encounterNames": {**existing.get("encounterNames", {}), **encounter_names}}
        patched.pop("status", None)
        patches.append(f"APR.DungeonData.forever.{key} = " + lua(patched) + "\n")
        selected = {q for q, v in definitions.items() if v.get("instance") == inst and not v.get("hide") and q in quests}
        # Include prerequisites and documented post-dungeon chains, not unrelated leveling.
        closure = set(selected)
        pending = list(selected)
        invalid = set()
        while pending:
            q = pending.pop()
            try:
                single, group = quest_dependencies(quests[q])
            except ValueError as error:
                notes.append(f"{dungeon['name']}: quest {q}: {error}; excluded")
                invalid.add(q)
                continue
            for p in single + group:
                if p in quests and p not in closure:
                    closure.add(p)
                    pending.append(p)
            following = quests[q].get("nextQuestInChain")
            if following and following in quests and following in definitions and following not in closure and definitions[following].get("instance", inst) == inst:
                closure.add(following)
                pending.append(following)
        for q, definition in definitions.items():
            chain = values(definition.get("chain"))
            if q in quests and chain and any(int(p) in selected for p in chain):
                closure.add(q)
        order = []
        visited = set()
        def visit(q, active=()):
            if q in visited or q in invalid:
                return
            if q in active:
                raise ValueError(f"cyclic quest dependency: {active + (q,)}")
            single, group = quest_dependencies(quests[q])
            for p in single + group:
                if p in closure:
                    visit(p, active + (q,))
            visited.add(q)
            order.append(q)
        for q in sorted(closure):
            visit(q)
        quest_scope[inst] = closure
        before, during, after = [], [], []
        quest_stages = []
        interior_related = set(selected)
        late = set()
        included = []
        for q in order:
            quest = quests[q]
            definition = definitions.get(q, {})
            single, group = quest_dependencies(quest)
            starts = quest.get("startedBy", {})
            ends = quest.get("finishedBy", {})
            if not starts or not ends:
                notes.append(f"{dungeon['name']}: quest {q} ({quest.get('name')}): incomplete starter/finisher; omitted")
                continue
            guards = {"MinLevel": quest.get("requiredLevel", 1)}
            faction = definition.get("faction")
            if not faction or faction == "Both":
                side = reference_quests.get(q, {}).get("side")
                faction = {1: "Alliance", 2: "Horde"}.get(side)
            if faction in ("Alliance", "Horde"):
                guards["Faction"] = faction
            classes = int(quest.get("requiredClasses", 0))
            class_bits = ((1, "WARRIOR"), (2, "PALADIN"), (4, "HUNTER"), (8, "ROGUE"), (16, "PRIEST"), (64, "SHAMAN"), (128, "MAGE"), (256, "WARLOCK"), (1024, "DRUID"))
            if classes:
                guards["Class"] = [name for bit, name in class_bits if classes & bit]
                if not guards["Class"]:
                    notes.append(f"{dungeon['name']}: quest {q}: unsupported class restriction; omitted")
                    continue
            # Preserve partial race restrictions, including Forever's high Skyborne bit.
            races = int(quest.get("requiredRaces", 0))
            race_bits = ((1, "Human"), (2, "Orc"), (4, "Dwarf"), (8, "NightElf"), (16, "Scourge"), (32, "Tauren"), (64, "Gnome"), (128, "Troll"), (12884901888, "Skyborne"))
            # Whole-faction historical masks must not exclude new Forever races.
            whole_faction = races & 77 == 77 or races & 178 == 178
            if races and not whole_faction:
                guards["Race"] = [name for bit, name in race_bits if races & bit]
                if not guards["Race"]:
                    notes.append(f"{dungeon['name']}: quest {q}: unknown race mask; omitted")
                    continue
            for p in group:
                guards.setdefault("AllOf", []).append({"IsQuestCompleted": p})
            if single:
                guards["AnyOf"] = [{"IsQuestCompleted": p} for p in single]
            pickup = {"PickUp": [q], **guards}
            done = {"Done": [q], "IsQuestOnQuest": q, **{k: v for k, v in guards.items() if k in ("Faction", "Race", "Class")}}
            start_kind = next((k for k in ("1", "2", "3") if starts.get(k)), None)
            end_kind = next((k for k in ("1", "2") if ends.get(k)), None)
            if not start_kind or not end_kind:
                notes.append(f"{dungeon['name']}: quest {q}: unsupported starter/finisher; omitted")
                continue
            starter = int(values(starts[start_kind])[0])
            finisher = int(values(ends[end_kind])[0])
            if start_kind == "1" and not pickup.get("Faction"):
                npc_faction = {"A": "Alliance", "H": "Horde"}.get(entities["Npc"].get(starter, {}).get("friendlyToFaction"))
                if npc_faction:
                    pickup["Faction"] = npc_faction
            start_pos = location({"1": "Npc", "2": "Object", "3": "Item"}[start_kind], starter)
            end_pos = location({"1": "Npc", "2": "Object"}[end_kind], finisher)
            inside_start = definition.get("inside") or (q in selected and not start_pos)
            inside_end = q in selected and not end_pos
            if start_kind == "3":
                pickup["Button"] = {str(q): starter}
                pickup["ItemCount"] = {"itemID": starter, "count": 1}
                pickup["NoArrow"] = True
                # Dropped starters remain optional unless an authoritative source locates them.
                inside_start = q in selected
            elif start_kind == "1":
                pickup["RaidIcon"] = [{"npcID": starter, "questID": q}]
            if end_kind == "1":
                done["RaidIcon"] = [{"npcID": finisher, "questID": q}]
            position(pickup, start_pos)
            position(done, end_pos)
            objectives = quest.get("objectivesText", {})
            objective_indices = sorted(psobjectives.get(q) or {int(i) for i in objectives if str(i).isdigit()})
            part = ({"Qpart": {q: objective_indices}, "IsQuestOnQuest": q, "NoArrow": True}
                    if objective_indices and (quest.get("objectives") or quest.get("triggerEnd") or q in psobjectives) else None)
            if q in selected:
                if inside_start:
                    pickup.update(Dungeon=key, InstanceQuest=True, NoArrow=True)
                    pickup.pop("Coord", None)
                    pickup.pop("Zone", None)
                    during.append(pickup)
                else:
                    before.append(pickup)
                if part:
                    part.update(Dungeon=key, InstanceQuest=True)
                    during.append(part)
                if inside_end:
                    done.update(Dungeon=key, InstanceQuest=True)
                    during.append(done)
                else:
                    after.append(done)
                late.add(q)
            else:
                is_late = any(p in late for p in single + group)
                target = after if is_late else before
                if is_late:
                    late.add(q)
                target.append(pickup)
                if part:
                    # Exterior prerequisite objectives use source target coordinates when known.
                    objective_points = []
                    for typ, rows in quest.get("objectives", {}).items():
                        for row in values(rows):
                            if not isinstance(row, dict) or not isinstance(row.get("1"), (int, float)):
                                continue
                            entity = int(row["1"])
                            kind = {"1": "Npc", "2": "Object", "3": "Item"}.get(typ)
                            if kind:
                                p = location(kind, entity)
                                if not p and kind == "Item":
                                    for n in values(entities["Item"].get(entity, {}).get("npcDrops")):
                                        p = location("Npc", int(n))
                                        if p:
                                            break
                                if p:
                                    objective_points.append(p)
                    if objective_points:
                        part.pop("NoArrow", None)
                        position(part, objective_points[0])
                    target.append(part)
                target.append(done)
            included.append(q)
            quest_stages.append((q, single + group, [(bool(step.get("Dungeon")), step) for step in (pickup, part, done) if step]))
        entrance = fix.get("entrance")
        if entrance:
            point = (entrance["map"], entrance["x"], entrance["y"])
        elif inst == 2959:
            point = (1421, 69.28, 45.55)  # Two independent faction walkthroughs agree.
        elif dungeon.get("entrance"):
            e = dungeon["entrance"]
            point = (e[1], e[2], e[3])
            # Repair overlapping zone-rectangle guesses from continent geometry.
            outside = {43: 1413, 47: 1413, 48: 1440, 70: 1418, 129: 1413, 189: 1420}.get(inst)
            if outside:
                continent, zone = map_geometry[e[4]], map_geometry[outside]
                world_x = continent["left"] + (continent["right"] - continent["left"]) * e[5] / 100
                world_y = continent["top"] + (continent["bottom"] - continent["top"]) * e[6] / 100
                point = (outside, round(100 * (world_x - zone["left"]) / (zone["right"] - zone["left"]), 3),
                         round(100 * (world_y - zone["top"]) / (zone["bottom"] - zone["top"]), 3))
        elif inst == 2998:
            point = (1437, 48.22, 56.49)  # Independent faction walkthroughs agree.
        else:
            point = None
            notes.append(f"{dungeon['name']}: no verified entrance coordinate; manual entry instruction only")
        enter = {"EnterInstance": {"dungeonKey": key}, "Dungeon": key, "InstanceQuest": True}
        position(enter, point)
        kills = [{"KillNPC": {"dungeonKey": key, "npcID": i, "name": name}, "Dungeon": key, "InstanceQuest": True, "NoArrow": True} for i, name in bosses]
        leave = {"LeaveInstance": {"dungeonKey": key}, "Dungeon": key, "NoArrow": True}
        steps = schedule_quests(quest_stages, enter, leave, kills) + [{"RouteCompleted": True}]
        name = "Blackrock Spire" if inst == 229 else dungeon["name"].removeprefix("The ")
        route_key = "Forever-Shared-Dungeons-" + slug(name)
        filename = "Forever_Shared_Dungeons_" + slug(name).replace("-", "_") + ".lua"
        path = route_dir / filename
        preserved = path.exists() and key in ("HOT", "RFC", "ROL", "DM", "WC")
        if not preserved:
            label = "Forever - Dungeon - " + name
            exports["enUS"].setdefault(label, "Dungeon Only - " + name)
            exports["frFR"].setdefault(label, "Donjon uniquement - " + name)
            for i, step in enumerate(steps, 1):
                step["_index"] = i
            header = {"label": Expr("L[" + lua(label) + "]"), "expansion": Expr("APR.EXPANSIONS.Forever"),
                      "gameVersion": Expr("APR.GAME_VERSIONS.Forever"), "category": Expr("APR.CATEGORIES.Dungeons"),
                      "mapID": point[0] if point else 0, "conditions": {"MinLevel": dungeon["min"]},
                      "levelRange": {"min": dungeon["min"], "max": dungeon["max"]}, "steps": steps}
            path.write_text('local L = LibStub("AceLocale-3.0"):GetLocale("APR")\n\n-- Verified offline instance and quest contracts.\nAPR.RouteQuestStepList[' + lua(route_key) + "] = " + lua(header) + "\n", encoding="utf-8")
        elif args.output.resolve() == ROOT:
            extend_detailed_route(path, quest_stages, bosses, key)
        stats.append({"instanceID": inst, "key": key, "name": dungeon["name"], "route": str(path.relative_to(args.output)).replace('\\', '/'), "preserved": preserved, "quests": included, "bosses": bosses, "entrance": point})
    patch_path = args.output / "APR-Core/data/Dungeons/DungeonsForever.lua"
    original = patch_path.read_text(encoding="utf-8") if patch_path.exists() else (ROOT / "APR-Core/data/Dungeons/DungeonsForever.lua").read_text(encoding="utf-8")
    for patch in patches:
        key, _, body = patch.partition(" = ")
        key = key.rsplit(".", 1)[-1]
        match = re.search(r"^    " + re.escape(key) + r" = \{", original, re.M)
        if not match:
            raise ValueError("Missing existing catalogue slot: " + key)
        begin = original.index("{", match.start())
        end = table_end(original, begin)
        # Re-indent a replacement value, touching only this party entry.
        body = body.strip().replace("\n", "\n    ")
        original = original[:begin] + body + original[end:]
    patch_path.parent.mkdir(parents=True, exist_ok=True)
    patch_path.write_text(original, encoding="utf-8")
    report = {"sourceHashes": {name: hashlib.sha256(p.read_bytes()).hexdigest() for name, p in (("instances", args.instance_source / "Data.lua"), ("corrections", args.instance_source / "Curated.lua"), ("questContracts", dbpath), ("npcReference", args.reference_data / "npc.jsonl"), ("questReference", args.reference_data / "quest.jsonl"))}, "dungeons": stats, "limitations": notes}
    report_path = args.output / ".cache/forever-dungeons/review.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    translations = args.output / "tools/localization/forever-dungeons-translations.json"
    translations.parent.mkdir(parents=True, exist_ok=True)
    translations.write_text(json.dumps(exports, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    legacy = clean_legacy_routes(ROOT, quest_scope) if args.output.resolve() == ROOT else 0
    print(json.dumps({"dungeons": len(stats), "newRoutes": sum(not s["preserved"] for s in stats), "legacyReviewed": legacy, "limitations": len(notes)}, indent=2))


if __name__ == "__main__":
    main()
