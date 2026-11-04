"""Offline NAV-00 evidence inventory. No runtime V1 code or client API is loaded.

collect reads native table exports plus declarative addon data. build uses only
the committed, normalized snapshots, so it also works without a sibling checkout.
Neither command activates maps or changes the canonical ticket registry.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import re
import unicodedata


VERSION = 1
CLIENTS = {"forever": ("wowf", "DungeonsForever.lua"),
           "retail": ("wow", "DungeonsRetail.lua")}
KINDS = {0: "outdoor", 1: "dungeon", 2: "raid", 3: "battleground",
         4: "arena", 5: "scenario"}
EXPANSIONS = {name: index for index, name in enumerate((
    "classique", "burning-crusade", "wrath", "cataclysm", "pandaria",
    "draenor", "legion", "battle-for-azeroth", "shadowlands", "dragonflight",
    "war-within", "midnight"))}
TECHNICAL = re.compile(r"\b(test(?:ing)?|prototype|unused|obsolete|development|transport)\b", re.I)
TABLE_FIELDS = {
    "Map": {"ID": "world_id", "MapName_lang": "name", "Directory": "directory",
            "InstanceType": "instance_type", "ExpansionID": "expansion_id",
            "WdtFileDataID": "wdt_file_id"},
    "UiMap": {"ID": "ui_map_id", "Name_lang": "name", "Type": "ui_type",
              "ParentUiMapID": "parent_ui_map_id"},
    "UiMapAssignment": {"UiMapID": "ui_map_id", "MapID": "world_id", "AreaID": "area_id"},
}


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8")


def ordered(rows):
    return sorted(rows, key=lambda row: encoded(row))


def unique(rows):
    return ordered({encoded(row): row for row in rows}.values())


def digest(data):
    return hashlib.sha256(data).hexdigest()


def name_key(value):
    value = value.partition(" — ")[0]
    value = unicodedata.normalize("NFKD", value).casefold()
    return "".join(char for char in value if char.isalnum())


def technical_label(value):
    words = re.sub(r"([a-z])([A-Z])", r"\1 \2", value).replace("_", " ")
    return bool(TECHNICAL.search(words))


def file_fact(path, root):
    # Source paths stay portable, including the separately maintained generator.
    import os
    return {"path": Path(os.path.relpath(path, root)).as_posix(),
            "sha256": digest(path.read_bytes())}


def lua_value(value):
    from lupa.lua51 import lua_type
    if lua_type(value) != "table":
        return value
    values = dict(value.items())
    if values and set(values) == set(range(1, len(values) + 1)):
        return [lua_value(values[index]) for index in range(1, len(values) + 1)]
    return {key: lua_value(item) for key, item in values.items()}


def declarations(path):
    from lupa.lua51 import LuaRuntime
    # The loaded chunk receives only env below; no runtime globals are exposed.
    lua = LuaRuntime()
    load = lua.execute('''
        return function(text, name)
            local registrations = {}
            local recorder = { RegisterData = function(_, client, category, data)
                registrations[#registrations + 1] = {client=client, category=category, data=data}
            end }
            local env = { LibStub = function() return recorder end, APR = {} }
            local chunk = assert(loadstring(text, name))
            setfenv(chunk, env)()
            return { registrations=registrations, dungeons=env.APR.DungeonData }
        end
    ''')
    return lua_value(load(path.read_text(encoding="utf-8-sig"), "@" + path.name))


def native_table(path, table, product, build):
    document = json.loads(path.read_text(encoding="utf-8-sig"))
    if (document["product"], document["build"]) != (product, build):
        raise ValueError(f"native table product/build mismatch: {path}")
    result = []
    for row in document["rows"]:
        result.append({dest: row[src] if dest in ("name", "directory") else int(row[src])
                       for src, dest in TABLE_FIELDS[table].items()})
    return unique(result)


def entrance_rows(records):
    return [{"world_id": row.get("instanceID"), "kind": row["kind"],
             "review_status": row.get("reviewStatus", "candidate"),
             "interior_ui_map_ids": sorted(row.get("interiorMapIDs", [])),
             "exterior_ui_map_id": row.get("exterior", {}).get("uiMapID")}
            for row in records]


def space_rows(records):
    return unique([{"world_id": row["worldID"], "kind": row["kind"],
                    "ui_map_ids": sorted(row.get("mapIDs", []))} for row in records])


def dungeon_rows(records):
    return ordered([{"key": key, "name": row["name"], "world_id": row.get("instanceID"),
                     "instance_type": row["instanceType"], "status": row.get("status", ""),
                     "boss_count": len(row.get("bosses", {})),
                     "encounter_count": len(row.get("encounters", {}))}
                    for key, row in records.items()])


def collect_client(root, tables_root, client, build):
    product, dungeon_file = CLIENTS[client]
    result = {"schema_version": VERSION, "client": client, "build": build, "sources": []}
    for table, dest in [("Map", "worlds"), ("UiMap", "ui_maps"), ("UiMapAssignment", "assignments")]:
        path = tables_root / product / build / (table + ".json")
        result[dest] = native_table(path, table, product, build)
        fact = file_fact(path, root)
        fact.update(table=table, build=build, product=product)
        result["sources"].append(fact)
    data_dir = root / "APR-Core/libs/LibAPRNavigation-1.0/Data" / client
    for filename, category in [("InstanceEntrances.lua", "instance_entrances"),
                               ("NavigationSpaces.lua", "navigation-spaces")]:
        path = data_dir / filename
        registration, = declarations(path)["registrations"]
        if (registration["client"], registration["category"]) != (client, category):
            raise ValueError(f"unexpected declaration: {path}")
        data = registration["data"]
        if category == "instance_entrances":
            result["entrances"] = entrance_rows(data["entrances"])
        else:
            result["spaces"] = space_rows(data["config"]["NavigationSpaces"])
        result["sources"].append(file_fact(path, root))
    path = root / "APR-Core/data/Dungeons" / dungeon_file
    result["dungeons"] = dungeon_rows(declarations(path)["dungeons"][client])
    fact = file_fact(path, root)
    fact["build"] = re.search(r"-- Client ([\d.]+)", path.read_text(encoding="utf-8")).group(1)
    result["sources"].append(fact)
    result["sources"] = ordered(result["sources"])
    return result


def integer(value, field, nullable=False):
    if nullable and value is None:
        return
    if type(value) is not int or value < 0:
        raise ValueError(f"invalid {field}: expected nonnegative integer")


def indexed(rows, field):
    result = {}
    for row in rows:
        integer(row[field], field)
        if row[field] in result:
            raise ValueError(f"duplicate {field}: {row[field]}")
        result[row[field]] = row
    return result


def validate(data):
    if data["schema_version"] != VERSION or data["client"] not in CLIENTS:
        raise ValueError("unsupported inventory schema/client")
    indexed(data["worlds"], "world_id")
    indexed(data["ui_maps"], "ui_map_id")
    validate_assignments(data["assignments"])
    for table in ("entrances", "dungeons", "spaces"):
        for row in data[table]:
            integer(row["world_id"], "world_id", nullable=table != "spaces")


def validate_assignments(rows):
    for row in rows:
        integer(row["ui_map_id"], "ui_map_id")
        integer(row["area_id"], "area_id")
        if type(row["world_id"]) is int and row["world_id"] == -1:
            continue
        integer(row["world_id"], "world_id")


def group(rows, key):
    result = defaultdict(list)
    for row in rows:
        result[row[key]].append(row)
    return result


def map_links(data):
    native, entrances = defaultdict(set), defaultdict(set)
    for row in data["assignments"]:
        if row["world_id"] != -1:
            native[row["ui_map_id"]].add(row["world_id"])
    for row in data["entrances"]:
        if row["world_id"] is None:
            continue
        for ui_map_id in row["interior_ui_map_ids"]:
            entrances[ui_map_id].add(row["world_id"])
    return native, entrances


def resolve_entrance_worlds(data, native_links):
    result, unresolved = [], []
    for original in data["entrances"]:
        row = dict(original)
        if row["world_id"] is None:
            worlds = set().union(*(native_links.get(mid, set()) for mid in row["interior_ui_map_ids"]))
            if len(worlds) == 1:
                row["world_id"] = next(iter(worlds))
            else:
                unresolved.append(dict(row, possible_world_ids=sorted(worlds)))
        result.append(row)
    return result, ordered(unresolved)


def evidence_class(world, entrances, dungeons, zones):
    if technical_label(world.get("name", "")) or technical_label(world.get("directory", "")):
        return "technical", ["technical_name_marker"]
    if "instance_type" not in world:
        return "candidate", ["missing_native_world"]
    if entrances:
        if any(row["review_status"] == "confirmed" for row in entrances):
            return "playable", ["confirmed_catalog_entrance"]
        return "candidate", ["unconfirmed_catalog_entrance"]
    if has_catalog_encounters(dungeons):
        return "playable", ["encounters_in_dungeon_catalog", "access_unverified"]
    if zones and world["instance_type"] == 0:
        return "playable", ["charted_navigation_zone", "access_unverified"]
    return "candidate", ["native_metadata_only"]


def has_catalog_encounters(dungeons):
    return any(row["encounter_count"] > 0 and row["status"] != "announced" for row in dungeons)


def world_record(world_id, native, data, links):
    world = dict(native.get(world_id, {"world_id": world_id}))
    entrances = [r for r in data["entrances"] if r["world_id"] == world_id]
    dungeons = [r for r in data["dungeons"] if r["world_id"] == world_id]
    ui_maps = [r for r in data["ui_maps"] if world_id in links.get(r["ui_map_id"], set())]
    aliases = {r["name"] for r in ui_maps + dungeons}
    if "name" in world:
        aliases.add(world["name"])
    world.setdefault("name", next(iter(sorted(aliases)), "Unknown native identity"))
    nav_maps = {mid for r in data["spaces"] if r["world_id"] == world_id for mid in r["ui_map_ids"]}
    zones = [r for r in ui_maps if r["ui_type"] == 3 and r["ui_map_id"] in nav_maps]
    classification, reasons = evidence_class(world, entrances, dungeons, zones)
    world.update(aliases=sorted(aliases), ui_map_ids=sorted(r["ui_map_id"] for r in ui_maps),
                 kind=KINDS.get(world.get("instance_type"), "unknown"),
                 classification=classification, reasons=reasons, activated=False,
                 entrance_statuses=sorted({r["review_status"] for r in entrances}),
                 entrance_kinds=sorted({r["kind"] for r in entrances}),
                 dungeon_keys=sorted(r["key"] for r in dungeons),
                 has_navigation_spaces=any(r["world_id"] == world_id for r in data["spaces"]))
    return world


def ui_class(row, linked, nav_maps):
    if technical_label(row["name"]):
        return "technical", ["technical_name_marker"]
    if not linked:
        return "candidate", ["missing_world_assignment"]
    if len(linked) > 1:
        return "candidate", ["multiple_world_assignments"]
    world, = linked
    if world["kind"] == "outdoor" and row["ui_map_id"] not in nav_maps:
        return "candidate", ["native_metadata_only"]
    return world["classification"], list(world["reasons"])


def ui_record(row, world_index, native_links, entrance_links, nav_maps):
    result = dict(row, world_ids=sorted(native_links.get(row["ui_map_id"], set())), activated=False)
    linked = [world_index[wid] for wid in result["world_ids"]]
    result["classification"], result["reasons"] = ui_class(row, linked, nav_maps)
    result["entrance_world_ids"] = sorted(entrance_links.get(row["ui_map_id"], set()))
    return result


def ambiguities(worlds, ui_maps):
    result = []
    for name, records in group(worlds, "name").items():
        if len(records) > 1:
            result.append({"type": "name_variants", "name": name,
                           "world_ids": sorted(r["world_id"] for r in records)})
    for row in ui_maps:
        if row["entrance_world_ids"] and row["world_ids"] != row["entrance_world_ids"]:
            result.append({"type": "ui_world_conflict", "ui_map_id": row["ui_map_id"],
                           "native_world_ids": row["world_ids"],
                           "entrance_world_ids": row["entrance_world_ids"]})
    return ordered(result)


def missing_maps(data):
    references = defaultdict(set)
    for row in data["assignments"]:
        references[row["ui_map_id"]].add("native_assignment")
    for row in data["spaces"]:
        for mid in row["ui_map_ids"]:
            references[mid].add("navigation_space")
    for row in data["entrances"]:
        for mid in row["interior_ui_map_ids"]:
            references[mid].add("entrance_interior")
        if row["exterior_ui_map_id"] is not None:
            references[row["exterior_ui_map_id"]].add("entrance_exterior")
    known = {r["ui_map_id"] for r in data["ui_maps"]}
    return [{"type": "missing_native_ui_map", "ui_map_id": mid, "referenced_by": sorted(references[mid])}
            for mid in sorted(set(references) - known)]


def reconcile(data):
    validate(data)
    links, _ = map_links(data)
    entrances, unresolved = resolve_entrance_worlds(data, links)
    data = dict(data, entrances=entrances)
    native = indexed(data["worlds"], "world_id")
    native_links, entrance_links = map_links(data)
    ids = set(native)
    for table in ("assignments", "entrances", "spaces", "dungeons"):
        ids.update(row["world_id"] for row in data[table]
                   if row["world_id"] is not None and row["world_id"] != -1)
    worlds = [world_record(wid, native, data, native_links) for wid in sorted(ids)]
    world_index = indexed(worlds, "world_id")
    nav_maps = {mid for r in data["spaces"] for mid in r["ui_map_ids"]}
    ui_maps = [ui_record(row, world_index, native_links, entrance_links, nav_maps)
               for row in sorted(data["ui_maps"], key=lambda row: row["ui_map_id"])]
    unlocated = [dict(row, classification="candidate", reasons=["missing_native_identity"], activated=False)
                 for row in data["dungeons"] if row["world_id"] is None]
    return {"client": data["client"], "build": data["build"], "worlds": worlds,
            "ui_maps": ui_maps, "unlocated": ordered(unlocated),
            "unlocated_entrances": unresolved,
            "gaps": missing_maps(data),
            "ambiguities": ambiguities(worlds, ui_maps)}


def read_backlog(directory):
    result = []
    pattern = re.compile(r"^# ((?:FZ|FI|RZ|RI)-\S+) — Guider (?:vers et )?dans (.+) — (forever|retail)(?: / (\S+))?$")
    for path in sorted(directory.glob("*.md")):
        first = path.read_text(encoding="utf-8-sig").splitlines()[0]
        match = pattern.match(first)
        if not match:
            if re.match(r"^# (?:FZ|FI|RZ|RI)-", first):
                raise ValueError(f"unrecognized place ticket header: {path.name}")
            continue
        ticket_id, name, client, expansion = match.groups()
        if ticket_id.startswith(("FZ-", "RZ-")):
            kind = "outdoor"
        else:
            kind = next(k for k in ("dungeon", "raid", "scenario", "delve") if f"-{k}-" in ticket_id)
        result.append({"ticket_id": ticket_id, "name": name, "client": client,
                       "kind": kind, "expansion_id": EXPANSIONS.get(expansion), "issue_file": path.name})
    return ordered(result)


def world_matches(ticket, world):
    kinds = set(world["entrance_kinds"]) | {world["kind"]}
    if ticket["kind"] not in kinds:
        return False
    return name_key(ticket["name"]) in {name_key(name) for name in world["aliases"]}


def prefer_expansion(matches, expansion_id):
    if expansion_id is None:
        return matches
    matching = [row for row in matches if row.get("expansion_ids") == [expansion_id]]
    if matching:
        return matching
    return [dict(row, expansion_mismatch=True) for row in matches]


def ticket_matches(ticket, client):
    if ticket["kind"] != "outdoor":
        matches = instance_ticket_matches(ticket, client)
    else:
        matches = zone_ticket_matches(ticket, client)
    return prefer_expansion(matches, ticket["expansion_id"])


def instance_ticket_matches(ticket, client):
    matches = [{"world_id": r["world_id"], "name": r["name"], "classification": r["classification"],
                "expansion_ids": [r["expansion_id"]] if "expansion_id" in r else []}
               for r in client["worlds"] if world_matches(ticket, r)]
    unlocated = [r for r in client["unlocated"] if unlocated_matches(ticket, r)]
    return matches + [{"world_id": None, "key": r["key"], "name": r["name"], "classification": "candidate"}
                      for r in unlocated]


def unlocated_matches(ticket, row):
    kind = {"party": "dungeon", "raid": "raid", "scenario": "scenario"}.get(row["instance_type"])
    return kind == ticket["kind"] and name_key(ticket["name"]) == name_key(row["name"])


def zone_ticket_matches(ticket, client):
    matches = []
    for row in client["ui_maps"]:
        if name_key(ticket["name"]) == name_key(row["name"]):
            matches.append({"ui_map_id": row["ui_map_id"], "world_ids": row["world_ids"],
                            "name": row["name"], "classification": row["classification"],
                            "expansion_ids": sorted({r["expansion_id"] for r in client["worlds"]
                                                     if r["world_id"] in row["world_ids"] and "expansion_id" in r})})
    return matches


def resolution(matches):
    if not matches:
        return "unmatched"
    if any("key" in r for r in matches):
        return "unlocated"
    identities = {tuple(r.get("world_ids", [r.get("world_id")])) for r in matches}
    if len(identities) > 1 or any(len(key) != 1 for key in identities):
        return "ambiguous"
    return "resolved"


def additional(client, covered):
    worlds = [dict(row, client=client["client"], record_type="world")
              for row in client["worlds"] if ("world", row["world_id"]) not in covered]
    zones = [dict(row, client=client["client"], record_type="ui_map")
             for row in client["ui_maps"] if row["ui_type"] == 3 and ("ui", row["ui_map_id"]) not in covered]
    unlocated = [dict(row, client=client["client"], record_type="unlocated") for row in client["unlocated"]
                 if ("name", name_key(row["name"])) not in covered]
    return [dict(row, proposed_action=additional_action(row)) for row in worlds + zones + unlocated]


def additional_action(row):
    return {"technical": "quarantine_technical", "candidate": "review_additional_candidate",
            "playable": "add_or_attach_coverage"}[row["classification"]]


def proposed_action(row):
    if row["resolution"] != "resolved":
        return "resolve_identity"
    if any(r.get("expansion_mismatch") for r in row["matches"]):
        return "review_expansion_metadata"
    if any(r["classification"] == "technical" for r in row["matches"]):
        return "quarantine_technical"
    if any(r["classification"] == "candidate" for r in row["matches"]):
        return "verify_before_coverage"
    return "retain_source_evidenced_scope"


def cover_matches(covered, ticket, matches):
    covered.add(("name", name_key(ticket["name"])))
    for match in matches:
        if "ui_map_id" in match:
            covered.add(("ui", match["ui_map_id"]))
            covered.update(("world", wid) for wid in match["world_ids"])
        else:
            covered.add(("world", match["world_id"]))


def propose(clients, tickets):
    result, extras = [], []
    for client in clients:
        covered = set()
        for ticket in tickets:
            if ticket["client"] != client["client"]:
                continue
            matches = ordered(ticket_matches(ticket, client))
            row = dict(ticket, matches=matches, resolution=resolution(matches))
            row["proposed_action"] = proposed_action(row)
            result.append(row)
            cover_matches(covered, ticket, matches)
        extras.extend(additional(client, covered))
    return {"schema_version": VERSION, "applied": False, "tickets": ordered(result),
            "additional_places": ordered(extras)}


def summary(document, proposal):
    lines = ["# NAV-00 — inventaire des lieux", "", "Inventaire de preuves ; aucune activation ni validation en jeu.", "",
             "`playable` décrit un lieu étayé par les sources, pas une couverture V2 acquise.",
             "`candidate` exige une vérification ; `technical` est exclu par défaut.", "",
             "| Client | Build | Mondes | UiMaps | Sans monde | Ambiguïtés |", "|---|---|---:|---:|---:|---:|"]
    for client in document["clients"]:
        lines.append(f"| {client['client']} | {client['build']} | {len(client['worlds'])} | {len(client['ui_maps'])} | {len(client['unlocated'])} | {len(client['ambiguities'])} |")
    lines += ["", "Les fichiers JSON contiennent toutes les identités, alias, variantes, lieux supplémentaires et propositions par ticket.",
              f"Tickets réconciliés : {len(proposal['tickets'])}. Entrées supplémentaires à examiner : {len(proposal['additional_places'])}.", ""]
    return "\n".join(lines).encode("utf-8")


def build(inputs, output, check=False):
    sources = [json.loads(path.read_text(encoding="utf-8")) for path in sorted(inputs.glob("*.json"))
               if path.name != "backlog.json"]
    clients = [reconcile(data) for data in sources]
    document = {"schema_version": VERSION, "policy_version": VERSION, "clients": clients,
                "inputs_sha256": digest(encoded(sources)),
                "sources": [{"client": data["client"], "files": data["sources"]} for data in sources]}
    proposal = propose(clients, json.loads((inputs / "backlog.json").read_text(encoding="utf-8")))
    files = {"inventory.json": encoded(document), "backlog-proposal.json": encoded(proposal),
             "summary.md": summary(document, proposal)}
    for filename, content in files.items():
        path = output / filename
        if check:
            if not path.exists() or path.read_bytes() != content:
                raise ValueError(f"stale inventory output: {filename}")
        else:
            output.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    collect = commands.add_parser("collect")
    collect.add_argument("--addon-root", type=Path, default=Path.cwd())
    collect.add_argument("--tables-root", type=Path, required=True)
    collect.add_argument("--forever-build", required=True)
    collect.add_argument("--retail-build", required=True)
    collect.add_argument("--backlog", type=Path, required=True)
    collect.add_argument("--output", type=Path, required=True)
    generate = commands.add_parser("build")
    generate.add_argument("--inputs", type=Path, required=True)
    generate.add_argument("--output", type=Path, required=True)
    generate.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.command == "build":
        build(args.inputs, args.output, args.check)
        return
    args.output.mkdir(parents=True, exist_ok=True)
    for client in CLIENTS:
        data = collect_client(args.addon_root, args.tables_root, client, getattr(args, client + "_build"))
        (args.output / (client + ".json")).write_bytes(encoded(data))
    (args.output / "backlog.json").write_bytes(encoded(read_backlog(args.backlog)))


if __name__ == "__main__":
    main()
