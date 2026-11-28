"""Build geography from the selected client's DB2 tables and WDT/ADT data."""

from collections import defaultdict
import math
from pathlib import Path
import struct
from threading import Lock
from time import sleep

from .native import (DEFINITIONS, RETAIL, WORKSPACE, decoder_source, load_module, prepare_definitions,
                    read_json, resources, storage_source, wdt_id, write_json)


LOCALES = {"fr": 16, "en": 2}
TILE_SIZE = 1600 / 3
CATALOG_LOCK = Lock()


def chunks(data):
    offset = 0
    while offset < len(data):
        tag, size = struct.unpack_from("<4sI", data, offset)
        offset += 8
        if offset + size > len(data):
            raise ValueError("Truncated client chunk")
        yield tag[::-1], memoryview(data)[offset:offset + size]
        offset += size


def wdt_tiles(data):
    directory = dict(chunks(data))
    flags, = struct.unpack_from("<I", directory[b"MPHD"])
    if flags & 1:
        if not directory.get(b"MODF"):
            raise ValueError("WDT has no global world model")
        return None
    maid = directory[b"MAID"]
    main = directory.get(b"MAIN")
    if len(maid) != 4096 * 32 or (main is not None and len(main) != 4096 * 8):
        raise ValueError("Incomplete ADT directory")
    tiles = {}
    for index in range(4096):
        files = struct.unpack_from("<4I", maid, 32 * index)
        present = main is not None and struct.unpack_from("<I", main, 8 * index)[0] & 1
        if present or any(files):
            tiles[f"{index % 64}_{index // 64}"] = files[0]
    if not tiles:
        raise ValueError("WDT has no terrain tiles")
    return tiles


def client_reader():
    source, dll = resources()
    native = source / "apr-terrain/client/src"
    load_module("apr_storage", source / "navigation_terrain/client.py")
    db = load_module("apr_db2", native / "db2.py")
    decoder = decoder_source(native / "db2.py")
    exec(compile(decoder, str(native / "db2.py"), "exec"), db.__dict__)
    code = storage_source(native / "storage.py")
    namespace = {"__name__": "terrain_ui_catalogue"}
    exec(compile(code.rsplit("\nserve()", 1)[0], str(native / "storage.py"), "exec"), namespace)
    return namespace["Local"], dll


def open_client(client, reader, dll, locale):
    error = None
    for attempt in range(3):
        try:
            reader_instance = reader(Path(client["root"]), client["product"], dll, locale)
        except OSError as exc:
            error = exc
            sleep(0.5 * (attempt + 1))
            continue
        if reader_instance.identity["buildKey"] == client["buildKey"]:
            return reader_instance
        reader_instance.close()
        raise ValueError("The installed client changed. Reload the interface.")
    raise error


def translations(first, second):
    return {language: value for language, value in (("fr", first), ("en", second)) if value}


def bounds(row):
    try:
        coords = tuple(struct.unpack("<f", struct.pack("<I", row[f"Region_{index}"]))[0] for index in (0, 1, 3, 4))
    except (KeyError, struct.error):
        return None
    if all(math.isfinite(v) and abs(v) <= 100_000 for v in coords) and coords[0] < coords[2] and coords[1] < coords[3]:
        return coords
    return None


def catalogue(client):
    folder = WORKSPACE / "clients" / client["id"]
    path = folder / "catalogue-v2.json"
    with CATALOG_LOCK:
        if path.is_file():
            return read_json(path)
        prepare_definitions()
        reader, dll = client_reader()
        tables = defaultdict(dict)
        worlds = {}
        notes = []
        for language, mask in LOCALES.items():
            try:
                store = open_client(client, reader, dll, mask)
            except OSError as error:
                notes.append(f"{language}: {error}")
                continue
            try:
                for name in ("Map", "UiMap", "AreaTable", "UiMapAssignment"):
                    try:
                        rows, _ = store.table(DEFINITIONS, name)
                    except (OSError, ValueError, KeyError, struct.error) as error:
                        if name == "UiMapAssignment":
                            # Some layouts omit a decodable Region. AreaTable is still usable.
                            import apr_db2
                            apr_db2.FIELDS[name] = ("MapID", "UiMapID", "AreaID")
                            try:
                                rows, _ = store.table(DEFINITIONS, name)
                            except (OSError, ValueError, KeyError, struct.error):
                                notes.append(f"{language} · {name}: {error}")
                                continue
                        else:
                            notes.append(f"{language} · {name}: {error}")
                            continue
                    tables[language][name] = {row["ID"]: row for row in rows}
                for world, row in tables[language].get("Map", {}).items():
                    if str(world) in worlds or not (file_id := wdt_id(store, row)):
                        continue
                    try:
                        tiles = wdt_tiles(store.read(file_id))
                    except (OSError, ValueError, KeyError, struct.error):
                        continue
                    worlds[str(world)] = {"id": world, "tiles": tiles, "wdt": file_id}
            finally:
                store.close()
        if not worlds:
            raise ValueError(" · ".join(notes) or "This build contains no readable world geometry.")

        def bilingual(name, label, fields):
            fr, en = (tables[language].get(name, {}) for language in LOCALES)
            return {str(key): {"id": key, "name": translations(fr.get(key, {}).get(label), en.get(key, {}).get(label)),
                               **{field: row.get(field) for field in fields}}
                    for key, row in (en | fr).items()}

        map_names = bilingual("Map", "MapName_lang", ())
        for key, world in worlds.items():
            world["name"] = map_names[key]["name"]
        ui = bilingual("UiMap", "Name_lang", ("Type", "ParentUiMapID"))
        areas = bilingual("AreaTable", "AreaName_lang", ("ContinentID", "ParentAreaID"))
        assignments = defaultdict(list)
        for row in (tables["en"].get("UiMapAssignment", {}) | tables["fr"].get("UiMapAssignment", {})).values():
            if str(row["MapID"]) in worlds:
                assignments[str(row["UiMapID"])].append([row["MapID"], row["AreaID"], bounds(row)])
        value = {"worlds": worlds, "ui": ui, "areas": areas, "assignments": dict(assignments), "notes": notes}
        value["tree"] = geography(value)
        write_json(path, value)
        return value


def area_path(areas, key):
    path = []
    seen = set()
    while key in areas and key not in seen:
        area = areas[key]
        path.insert(0, area)
        seen.add(key)
        key = str(area["ParentAreaID"])
    return path


def geography(data):
    worlds, maps, areas = (data[key] for key in ("worlds", "ui", "areas"))
    assignments = data["assignments"]
    areas_by_world = defaultdict(list)
    for area in areas.values():
        if area["name"]:
            areas_by_world[area["ContinentID"]].append(area)
    continents = {}
    assigned_worlds = set()
    for key, zone in maps.items():
        if zone.get("Type") != 3 or key not in assignments or not zone["name"]:
            continue
        rows = assignments[key]
        zone_worlds = {row[0] for row in rows}
        assigned_worlds.update(zone_worlds)
        parent = str(zone["ParentUiMapID"])
        seen = {key}
        while parent in maps and maps[parent].get("Type") != 2 and parent not in seen:
            seen.add(parent)
            parent = str(maps[parent]["ParentUiMapID"])
        main_world = next(iter(sorted(zone_worlds)))
        continent = maps[parent] if parent in maps and maps[parent].get("Type") == 2 else worlds[str(main_world)]
        continent_id = f"ui:{parent}" if continent is maps.get(parent) else f"world:{main_world}"
        group = continents.setdefault(continent_id, {"id": continent_id, "name": continent["name"], "zones": []})
        roots = {row[1] for row in rows if row[1] > 0}
        for world in zone_worlds:
            roots.update(area["id"] for area in areas_by_world[world] if any(
                zone["name"].get(language) == name for language, name in area["name"].items()))
        children = []
        for world in sorted(zone_worlds):
            for area in areas_by_world[world]:
                lineage = area_path(areas, str(area["id"]))
                if area["id"] not in roots and any(ancestor["id"] in roots for ancestor in lineage):
                    relative = lineage[max(i for i, ancestor in enumerate(lineage) if ancestor["id"] in roots) + 1:]
                    children.append({"id": area["id"], "name": area["name"], "trail": [item["name"] for item in relative]})
        group["zones"].append({"id": key, "name": zone["name"], "worlds": sorted(zone_worlds),
                               "roots": sorted(roots), "subzones": children})
    for key, world in worlds.items():
        if world["id"] in assigned_worlds:
            continue
        roots = [area for area in areas_by_world[world["id"]] if not area["ParentAreaID"] or str(area["ParentAreaID"]) not in areas]
        zones = []
        for area in roots:
            descendants = []
            for child in areas_by_world[world["id"]]:
                lineage = area_path(areas, str(child["id"]))
                if len(lineage) > 1 and lineage[0]["id"] == area["id"]:
                    descendants.append({"id": child["id"], "name": child["name"], "trail": [item["name"] for item in lineage[1:]]})
            zones.append({"id": f"area:{area['id']}", "name": area["name"], "worlds": [world["id"]],
                          "roots": [area["id"]], "subzones": descendants})
        continent_id = f"world:{key}"
        group = continents.setdefault(continent_id, {"id": continent_id, "name": world["name"], "zones": []})
        group["world"] = world["id"]
        group["zones"].extend(zones)
    return list(continents.values())


def select(data, scope):
    continent = next((node for node in data["tree"] if node["id"] == scope.get("continent")), None)
    zone = next((node for node in continent["zones"] if node["id"] == scope.get("zone")), None) if continent else None
    area = next((node for node in zone["subzones"] if node["id"] == scope.get("area")), None) if zone else None
    if any(scope.get(key) is not None and node is None for key, node in (("continent", continent), ("zone", zone), ("area", area))):
        raise ValueError("The selected continent, zone, or subzone does not exist in this client.")
    trail = [item["name"] for item in (continent, zone) if item]
    if area:
        trail.extend(area["trail"])
    if not continent:
        ids = [world["id"] for world in data["worlds"].values()]
    elif zone:
        ids = zone["worlds"]
    elif "world" in continent:
        ids = [continent["world"]]
    else:
        ids = sorted({world for item in continent["zones"] for world in item["worlds"]})
    roots = {area["id"]} if area else (set(zone["roots"]) if zone else set())
    return ids, trail, roots, zone["id"] if zone else None


def with_world_scopes(data):
    """Expose each readable MapID as a scope, including worlds with mapped zones."""
    represented = {group["world"] for group in data["tree"] if "world" in group}
    worlds = [
        {"id": f"map:{world['id']}", "name": world["name"], "world": world["id"], "zones": []}
        for world in data["worlds"].values() if world["id"] not in represented
    ]
    return data | {"tree": [*data["tree"], *worlds]}


def read_area_tiles(store, world, check, folder):
    key = str(world["id"])
    existing = folder / "area-tiles" / f"{key}.json"
    retail = RETAIL / "area-tiles" / f"{key}.json"
    if existing.is_file():
        return read_json(existing)
    if store.identity["product"] == "wow" and store.identity["build"] == "12.1.5.70961" and retail.is_file():
        return read_json(retail)
    result = {"tiles": {}, "errors": {}}
    for tile, file_id in world["tiles"].items():
        check()
        try:
            data = store.read(file_id)
            seen = {struct.unpack_from("<I", chunk, 52)[0] for tag, chunk in chunks(data) if tag == b"MCNK"}
            if not seen:
                raise ValueError("Missing terrain chunks")
            result["tiles"][tile] = sorted(seen - {0})
        except (OSError, ValueError, struct.error) as error:
            result["errors"][tile] = str(error)
    write_json(existing, result)
    return result


def tiles_in_bounds(tiles, ranges):
    selected = set()
    for tile in tiles:
        col, row = map(int, tile.split("_"))
        low_x, low_y = (31 - row) * TILE_SIZE, (31 - col) * TILE_SIZE
        if any(low_x < x2 and low_x + TILE_SIZE > x1 and low_y < y2 and low_y + TILE_SIZE > y1
               for x1, y1, x2, y2 in ranges):
            selected.add(tile)
    return selected
