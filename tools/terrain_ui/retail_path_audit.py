"""Replay walking paths in the installed Retail packs for a client map tree."""

import argparse
import base64
from collections import defaultdict
import json
from pathlib import Path
import time
import xml.etree.ElementTree as ET
import zlib

LIBRARY = Path(__file__).resolve().parents[2] / "APR-Core/libs/LibAPRNavigation-1.0"
PACKS = LIBRARY / "Data/retail/Terrain"


def load_json(path):
    return json.loads(path.read_bytes())


def map_tree(catalogue, root):
    maps = catalogue["ui"]
    children = defaultdict(list)
    for ui, row in maps.items():
        children[row["ParentUiMapID"]].append(int(ui))
    pending = sorted(children[root])
    seen = {root}
    while pending:
        ui = pending.pop()
        if ui in seen:
            continue
        seen.add(ui)
        pending.extend(sorted(children[ui]))
        yield ui, maps[str(ui)]


def execute_manifest(lua, manifest):
    for entry in ET.parse(manifest).getroot():
        path = manifest.parent / entry.attrib["file"]
        if entry.tag.endswith("}Include"):
            execute_manifest(lua, path)
        else:
            lua.execute(path.read_bytes(), name=str(path))


def runtime():
    from lupa.lua51 import LuaRuntime

    lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)
    lua.globals().inflate = zlib.decompress
    lua.globals().decode = lambda value: base64.b64decode(value, validate=True)
    lua.globals().clock = lambda: time.perf_counter() * 1000
    lua.execute(b"""
        strmatch = string.match
        function GetBuildInfo() return version, revision, nil, toc end
        Enum = { CompressionMethod = { Zlib = 1 } }
        C_EncodingUtil = { DecodeBase64 = function(value) return decode(value) end,
            DecompressString = function(value) return inflate(value) end }
    """)
    for source in ("../HereBeDragons/LibStub/LibStub.lua", "Core.lua", "Locales.lua", "Geography.lua",
                   "Conditions.lua", "Catalog.lua", "Search.lua"):
        lua.execute((LIBRARY / source).read_bytes())
    execute_manifest(lua, LIBRARY / "Terrain/Runtime.xml")
    lua.execute(b'auditGrid = LibStub("LibAPRNavigation-1.0")._TerrainNamespace.PathGrid')
    lua.execute((LIBRARY / "Terrain.lua").read_bytes())
    for name in ("Geography", "Availability", "Passages", "Boats", "Zeppelins", "Portals"):
        lua.execute((LIBRARY / "Data/retail" / f"{name}.lua").read_bytes())
    return lua, *lua.execute(Path(__file__).with_suffix(".lua").read_bytes())


def unpack(value):
    from lupa.lua51 import lua_type

    if lua_type(value) == "table":
        if len(value):
            return [unpack(value[index]) for index in range(1, len(value) + 1)]
        return {unpack(key): unpack(item) for key, item in value.items()}
    return value.decode() if isinstance(value, bytes) else value


def client_maps(lua, catalogue):
    maps = {int(ui): {b"mapType": row["Type"], b"parentMapID": row["ParentUiMapID"]}
            for ui, row in catalogue["ui"].items()}
    projections = {}
    for ui, entries in catalogue["assignments"].items():
        candidates = [(world, box) for world, area, box in entries if box and area != 0]
        candidates = candidates or [(world, box) for world, _, box in entries if box]
        if len(set(world for world, _ in candidates)) == 1:
            world, box = candidates[0]
            projections[int(ui)] = [world, *box]
    return lua.table_from(maps, recursive=True), lua.table_from(projections, recursive=True)


def select_build(lua, build):
    version, revision = build.rsplit(".", 1)
    major, minor, patch = map(int, version.split("."))
    lua.globals().version = version.encode()
    lua.globals().revision = revision.encode()
    lua.globals().toc = major * 10000 + minor * 100 + patch


def available_packs():
    return {entry.attrib["file"] for entry in ET.parse(PACKS / "Terrain.xml").getroot()}


def audit(catalogue, root, build, seconds, hub, record):
    lua, replay, transitions, _ = runtime()
    select_build(lua, build)
    includes = available_packs()
    regions = defaultdict(list)
    region_maps = {}
    for ui, row in sorted(map_tree(catalogue, root)):
        projections = {(world, tuple(box)) for world, _, box in catalogue["assignments"].get(str(ui), ()) if box}
        region = {"uiMap": ui, "name": row["name"], "type": row["Type"]}
        if not projections:
            record({**region, "status": "missing_projection"})
        else:
            region_maps[ui] = row["Type"]
        for world, box in sorted(projections):
            regions[world].append({**region, "world": world, "bounds": box})

    for world, entries in sorted(regions.items()):
        folder = PACKS / str(world)
        manifest = f"{world}/Terrain.xml"
        status = None
        generation = {}
        if manifest not in includes:
            status = "missing_pack"
        else:
            generation = load_json(folder / "Generation.json")
            if generation["clientBuild"] != build:
                status = "build_mismatch"
        if status:
            for entry in entries:
                record({**entry, "status": status})
            continue
        execute_manifest(lua, PACKS / manifest)
        relocations = {
            window["relocatedUiMap"]["previous"]: window
            for window in generation.get("surfaceWindows", ()) if "relocatedUiMap" in window
        }
        for entry in entries:
            result = unpack(replay(world, entry["uiMap"], lua.table_from(entry["bounds"]), seconds * 1000))
            window = relocations.get(entry["uiMap"])
            if result["status"] == "no_witness" and window:
                relocation = window["relocatedUiMap"]
                entry["originalProjectionStatus"] = result["status"]
                entry["testedBounds"] = window["bounds"]
                entry["relocatedUiMap"] = relocation
                result = unpack(replay(world, relocation["current"], lua.table_from(window["bounds"]),
                                       seconds * 1000, lua.table_from(relocation["heightRange"])))
            record({**entry, **result})

    maps, projections = client_maps(lua, catalogue)
    checks, trips = transitions(maps, projections, lua.table_from(region_maps), seconds * 1000, hub)
    return unpack(checks) or [], unpack(trips) or []


def audit_journeys(catalogue, build, seconds, journeys):
    lua, _, _, replay = runtime()
    select_build(lua, build)
    includes = available_packs()
    maps, projections = client_maps(lua, catalogue)
    worlds = {journey[key]["instanceID"] for journey in journeys
              for key in ("from", "to", "returnFrom", "returnTo") if key in journey}
    worlds.update(world for journey in journeys for world in journey.get("viaWorlds", ()))
    for world in sorted(worlds):
        manifest = f"{world}/Terrain.xml"
        if manifest not in includes or load_json(PACKS / str(world) / "Generation.json")["clientBuild"] != build:
            raise ValueError(f"No Retail terrain pack for world {world} on build {build}.")
        execute_manifest(lua, PACKS / manifest)
    reports = []
    for journey in journeys:
        result = unpack(replay(maps, projections, lua.table_from(_lua_values(journey), recursive=True),
                               seconds * 1000))
        reports.append(result)
        print(result["name"], result["outbound"]["status"], result["return"]["status"], flush=True)
    return reports


def _lua_values(value):
    if isinstance(value, dict):
        return {key.encode(): _lua_values(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_lua_values(item) for item in value]
    return value.encode() if isinstance(value, str) else value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalogue", type=Path, required=True, help="Installed client's catalogue-v2.json")
    parser.add_argument("--root", type=int, default=2274, help="Root UiMapID (default: Khaz Algar)")
    parser.add_argument("--hub", type=int, help="Compare transport reachability to and from this UiMapID")
    parser.add_argument("--journeys", type=Path, help="Replay both ways between explicit world positions with terrain")
    parser.add_argument("--build", required=True, help="Exact Retail build used by both catalogue and packs")
    parser.add_argument("--seconds", type=float, default=4, help="Time budget per path replay")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    catalogue = load_json(args.catalogue)
    if args.journeys and args.hub is not None:
        parser.error("--hub is only available for map tree audits.")
    if args.seconds <= 0:
        parser.error("A positive per-path time budget is required.")
    if args.journeys:
        journeys = load_json(args.journeys)
        if not isinstance(journeys, list) or not journeys:
            parser.error("--journeys requires a nonempty JSON list of journeys.")
        records = audit_journeys(catalogue, args.build, args.seconds, journeys)
        with args.out.open("w", encoding="utf-8") as output:
            json.dump({"build": args.build, "journeys": records}, output, ensure_ascii=False, indent=2)
            output.write("\n")
        return any(row[direction]["status"] != "ready" for row in records for direction in ("outbound", "return"))

    if str(args.root) not in catalogue["ui"]:
        parser.error("A known root UiMapID is required.")
    if args.hub is not None and args.hub not in {ui for ui, _ in map_tree(catalogue, args.root)}:
        parser.error("The hub must be a descendant of the selected root UiMapID.")
    report = {"build": args.build, "root": args.root, "regions": []}
    def record(region):
        report["regions"].append(region)
        print(region["uiMap"], region.get("world"), region["status"], len(region.get("checks", ())), flush=True)

    report["transitions"], report["hubRoutes"] = audit(catalogue, args.root, args.build, args.seconds, args.hub, record)
    with args.out.open("w", encoding="utf-8") as output:
        json.dump(report, output, ensure_ascii=False, indent=2)
        output.write("\n")
    terrain_failure = any(region["status"] != "checked" or any(
        check["outcome"] != "pass" for check in region.get("checks", ())
    ) for region in report["regions"])
    transition_failure = any(row["status"] != "checked" or any(
        direction["status"] != "ready" or not direction["used"] for direction in row["directions"]
    ) for row in report["transitions"])
    return terrain_failure or transition_failure or any(row["status"] != "ready" for row in report["hubRoutes"])


if __name__ == "__main__":
    raise SystemExit(main())
