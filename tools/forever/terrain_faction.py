"""Prepare a build-matched faction layer for APR's Forever terrain packs."""

import argparse
import hashlib
import json
import math
from pathlib import Path
import re


WORLDS = (0, 1, 2991)
FACTION_DATA = Path(__file__).resolve().with_name("terrain")
SIDES = {2: "Alliance", 4: "Horde", 6: "Neutral"}
SHARED_AREAS = {
    35, 392, 976, 2255, 3425, 16624,
}
GEOMETRY_TILE = 1600 / 3
TEAM_TEMPLATES = {"Alliance": (1, 3, 4, 115), "Horde": (2, 5, 6, 116)}
HUB = re.compile(
    r'^\s*\{ id = "([a-z0-9-]+)", side = "(Alliance|Horde)", name = "(?:[^"\\]|\\.)*", '
    r'areaId = (\d+), disks = \{(.+)\} \},\s*$'
)
DISK = re.compile(r'\{\s*(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)\s*\}')


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def faction_policy_path(build):
    if not re.fullmatch(r"\d+(?:\.\d+){2,}", build):
        raise ValueError(f"Invalid Forever build: {build}")
    return FACTION_DATA / build / "faction.json"


def tile_at(x, y):
    return math.floor(32 - y / GEOMETRY_TILE), math.floor(32 - x / GEOMETRY_TILE)


def load_table(path, build):
    table = read(path)
    if (table["product"], table["build"]) != ("wowf", build):
        raise ValueError(f"Table does not match Forever {build}: {path.name}")
    rows = {row["ID"]: row for row in table["rows"]}
    if not rows or len(rows) != len(table["rows"]):
        raise ValueError(f"Missing or duplicate rows: {path.name}")
    return rows


def area_owners(areas, maps):
    owners = {world: {} for world in maps}
    for area_id, area in areas.items():
        world = area["ContinentID"]
        if world not in owners:
            continue
        visited = set()
        parent_id = area_id
        while parent_id and parent_id not in visited:
            if parent_id in SHARED_AREAS:
                owners[world][str(area_id)] = "Neutral"
                break
            parent = areas.get(parent_id)
            if not parent or parent["ContinentID"] != world:
                break
            side = SIDES.get(parent["FactionGroupMask"])
            if side:
                owners[world][str(area_id)] = side
                break
            visited.add(parent_id)
            parent_id = parent["ParentAreaID"]
    return owners


def hub_candidates(path):
    with path.open(encoding="utf-8-sig") as source:
        for line in source:
            if match := HUB.fullmatch(line.rstrip("\r\n")):
                identifier, side, area_id, disks = match.groups()
                values = [[float(n) for n in d.groups()] for d in DISK.finditer(disks)]
                remainder = DISK.sub("", disks)
                if not values or remainder.strip(" ,\t"):
                    raise ValueError(f"Malformed hub {identifier}")
                yield identifier, side, int(area_id), values
            elif 'id = "' in line and "areaId = " in line and "disks = " in line:
                raise ValueError(f"Malformed hub record in {path.name}")


def collect_hubs(world, path, areas, owners, tiles, report):
    entries = []
    for identifier, side, area_id, disks in hub_candidates(path):
        area = areas.get(area_id)
        if area_id in SHARED_AREAS or owners.get(str(area_id)) == "Neutral":
            report["shared"].append(identifier)
            continue
        if area and area["ContinentID"] != world:
            report["inconsistent"].append(identifier)
            continue
        if area and SIDES.get(area["FactionGroupMask"]) not in (None, side):
            report["overlapsTerritory"].append(identifier)
        retained = [disk for disk in disks if tile_at(*disk[:2]) in tiles and 0 < disk[2] <= 100]
        if not retained:
            report["outsideCoverage"].append(identifier)
            continue
        if len(retained) != len(disks):
            report["outsideCoverage"].append(identifier)
        entries.append({"id": identifier, "side": side, "areaId": area_id,
                        "name": area["AreaName_lang"] if area else "", "disks": retained})
    return sorted(entries, key=lambda row: row["id"])


def prepare(args):
    geometry = read(args.geometry)
    build = geometry["build"]
    if geometry["product"] != "wowf" or geometry["selection"] != "maps":
        raise ValueError("Faction generation needs complete Forever map extraction")
    tiles = {m["id"]: {(t["x"], t["y"]) for t in m["tiles"]} for m in geometry["maps"]}
    if sorted(tiles) != list(WORLDS):
        raise ValueError("Expected all three Forever worlds")
    areas = load_table(args.areas, build)
    factions = load_table(args.factions, build)
    for expected, side in ((2, "Alliance"), (4, "Horde")):
        if any(not factions.get(template, {}).get("FactionGroup", 0) & expected
               for template in TEAM_TEMPLATES[side]):
            raise ValueError(f"Unverified FactionTemplate group for {side}")

    owners = area_owners(areas, tiles)
    report = {"shared": [], "inconsistent": [], "outsideCoverage": [], "unverifiedJoins": [], "overlapsTerritory": []}
    hubs = {world: [] for world in tiles}
    hub_files = {}
    for world, path in args.hubs:
        if world not in tiles or world in hub_files:
            raise ValueError(f"Duplicate or unsupported hub world {world}")
        hub_files[world] = sha(path)
        hubs[world] = collect_hubs(world, path, areas, owners[world], tiles[world], report)
    if not all(hubs[world] for world in (0, 1)):
        raise ValueError("Missing reviewed camps on a continent")

    joins = read(args.joins)
    cuts = []
    for cut in joins["cuts"]:
        if cut["map"] in tiles and all(tile_at(*p) in tiles[cut["map"]] for p in (cut["a"], cut["b"])):
            cuts.append({k: cut[k] for k in ("id", "map", "a", "b", "z")})
        else:
            report["outsideCoverage"].append(cut["id"])
    for join in joins["joins"]:
        report["unverifiedJoins"].append(join["id"])
    source = {"referenceRevision": args.source_revision, "clientBuild": build,
              "areaTableSha256": sha(args.areas), "factionTemplateSha256": sha(args.factions),
              "hubExportsSha256": hub_files, "joinsSha256": sha(args.joins)}
    destination = args.out or faction_policy_path(build)
    review = args.report or destination.with_name("faction-review.json")
    review.parent.mkdir(parents=True, exist_ok=True)
    review.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps({"schema": 1, "build": build, "source": source, "maps": hubs,
                                       "areas": owners, "cuts": cuts}, ensure_ascii=False,
                                      separators=(",", ":")) + "\n", encoding="utf-8")


def hub_export(value):
    world, separator, filename = value.partition("=")
    if not separator:
        raise argparse.ArgumentTypeError("Use MAP=PATH for each hub export")
    return int(world), Path(filename)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("geometry", "areas", "factions", "joins"):
        parser.add_argument(f"--{name}", type=Path, required=True)
    parser.add_argument("--out", type=Path, help="Policy path. Defaults to tools/forever/terrain/<build>/faction.json.")
    parser.add_argument("--report", type=Path, help="Review path. Defaults to faction-review.json beside the policy.")
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--hubs", action="append", type=hub_export, required=True)
    prepare(parser.parse_args())
