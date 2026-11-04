"""Read, write and validate the editable LibAPRNavigation road catalogues.

Lua declarations are the canonical data. This tool never downloads data or
rewrites catalogues during validation. Collision rows contain explicit column
ranges and named states; road points and edges remain editable Lua records.
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path
import re

from lupa.lua51 import LuaRuntime, lua_type

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "APR-Core/libs/LibAPRNavigation-1.0/Data"
NETWORK_FIELDS = {"id", "instanceID", "uiMapID", "kind", "collision", "sections", "walls", "openings"}
SECTION_FIELDS = {"id", "kind", "joinRadius", "nodes", "edges", "joins"}
NODE_FIELDS = {"id", "x", "y", "z"}
EDGE_FIELDS = {"id", "from", "to", "points", "kind", "dropHeight", "costDistance", "bidirectional"}
COLLISION_FIELDS = {"id", "originX", "originY", "cellSize", "width", "height",
                    "rows", "splitHeight", "blockedRuns"}
COLLISION_STATES = {"open", "water", "blocked", "inherit", "unknown-floor"}
FIELD_ORDER = {name: index for index, name in enumerate((
    "id", "instanceID", "uiMapID", "from", "to", "state", "kind", "bidirectional", "joinRadius",
    "dropHeight", "costDistance", "x", "y", "z", "originX", "originY", "cellSize", "width", "height",
    "collision", "sections", "nodes", "edges", "joins", "walls", "openings", "radius", "points",
    "splitHeight", "blockedRuns", "rows"))}


def slug(value):
    return re.sub(r"[^a-z0-9]+", "-", str(value).lower()).strip("-")


def quote(value):
    replacements = {"\\": "\\\\", '"': '\\"', "\n": "\\n", "\r": "\\r", "\t": "\\t"}
    return '"' + ''.join(replacements.get(c, "\\%03d" % ord(c) if ord(c) < 32 else c) for c in value) + '"'


def lua_value(value, indent=0):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        if not math.isfinite(value):
            raise ValueError("Non-finite coordinate")
        return repr(value)
    if isinstance(value, str):
        return quote(value)
    if isinstance(value, dict):
        keys = sorted(value, key=lambda key: (FIELD_ORDER.get(key, len(FIELD_ORDER)), str(key)))
        fields = [(key if re.fullmatch(r"[A-Za-z_]\w*", str(key)) else '[' + quote(str(key)) + ']')
                  + " = " + lua_value(value[key], indent + 4) for key in keys]
    elif isinstance(value, (list, tuple)):
        fields = [lua_value(child, indent + 4) for child in value]
    else:
        raise ValueError("Unsupported declaration value")
    inline = "{ " + ", ".join(fields) + " }"
    if not fields:
        return "{}"
    if "\n" not in inline and indent + len(inline) <= 155:
        return inline
    pad = " " * (indent + 4)
    return "{\n" + "\n".join(pad + field + "," for field in fields) + "\n" + " " * indent + "}"


def render(api, profile, definition, revision=1):
    if api not in ("RegisterRoadNetwork", "RegisterRoadCollision"):
        raise ValueError("Unknown road declaration")
    return ('-- LibAPRNavigation: editable ' + ('road network' if api == 'RegisterRoadNetwork' else 'collision mask')
            + '. Coordinates are world yards.\n'
            + 'LibStub("LibAPRNavigation-1.0"):' + api + '(' + quote(profile) + ', '
            + lua_value(definition) + ', ' + str(revision) + ')\n')


def plain(value):
    if lua_type(value) == "table":
        keys = list(value.keys())
        if keys and set(keys) == set(range(1, len(keys) + 1)):
            return [plain(value[index]) for index in range(1, len(keys) + 1)]
        result = {key: plain(child) for key, child in value.items()}
        for key in ("sections", "nodes", "edges", "points", "joins", "walls", "openings", "overlays", "blockedRuns", "rows"):
            if result.get(key) == {}:
                result[key] = []
        return result
    if lua_type(value) is not None:
        raise ValueError("Catalogues must be declarative")
    return value


def read_declarations(paths):
    runtime = LuaRuntime(unpack_returned_tuples=True, register_eval=False, register_builtins=False)
    records = []
    runtime.globals().capture = lambda api, profile, data, revision: records.append(
        {"api": api, "profile": profile, "data": plain(data), "revision": revision or 1})
    runtime.execute('''
        local library = {}
        function library:RegisterRoadNetwork(profile, data, revision) capture("RegisterRoadNetwork", profile, data, revision) end
        function library:RegisterRoadCollision(profile, data, revision) capture("RegisterRoadCollision", profile, data, revision) end
        function LibStub(name) assert(name == "LibAPRNavigation-1.0"); return library end
    ''')
    for path in paths:
        before = len(records)
        runtime.execute(Path(path).read_text(encoding="utf-8-sig"), name="@" + str(path))
        for record in records[before:]:
            record["file"] = str(path)
    return records


def fields(record, supported):
    if not isinstance(record, dict) or set(record) - supported:
        raise ValueError("Unsupported fields: " + str(set(record) - supported if isinstance(record, dict) else record))


def finite(value):
    return not isinstance(value, bool) and isinstance(value, (int, float)) and math.isfinite(value)


def identifier(value):
    if not isinstance(value, str) or not re.fullmatch(r"[a-z][a-z0-9]*(?:-[a-z0-9]+)*", value):
        raise ValueError("Readable lowercase identifier required: " + str(value))


def point(value, node=False):
    fields(value, NODE_FIELDS if node else {"x", "y", "z"})
    if not all(finite(value.get(axis)) for axis in ("x", "y")) or ("z" in value and not finite(value["z"])):
        raise ValueError("Finite world coordinates required")
    if node:
        identifier(value.get("id"))


def validate_network(data):
    fields(data, NETWORK_FIELDS)
    identifier(data.get("id"))
    if not finite(data.get("instanceID")) or data["instanceID"] < 0 or data["instanceID"] % 1:
        raise ValueError("Native world identity required")
    if data.get("kind") not in ("world", "city", "instance"):
        raise ValueError("Unknown network kind")
    identities = {data["id"]}
    for section in data.get("sections", []):
        fields(section, SECTION_FIELDS)
        identifier(section.get("id"))
        if section["id"] in identities:
            raise ValueError("Duplicate section identity")
        identities.add(section["id"])
        if section.get("kind") not in ("road", "cave", "building", "city", "recorded"):
            raise ValueError("Unknown section kind")
        nodes = set()
        for node in section.get("nodes", []):
            point(node, True)
            if node["id"] in identities:
                raise ValueError("Duplicate node identity")
            nodes.add(node["id"])
            identities.add(node["id"])
        for edge in section.get("edges", []):
            fields(edge, EDGE_FIELDS)
            identifier(edge.get("id"))
            if edge["id"] in identities:
                raise ValueError("Duplicate edge identity")
            identities.add(edge["id"])
            if edge.get("from") not in nodes or edge.get("to") not in nodes:
                raise ValueError("Unknown edge endpoint")
            if edge.get("kind") not in ("road", "stairs", "elevator", "swim"):
                raise ValueError("Unknown edge kind")
            if len(edge.get("points", [])) < 2:
                raise ValueError("Explicit road polyline required")
            for vertex in edge["points"]:
                point(vertex)
            for key in ("dropHeight", "costDistance"):
                if key in edge and (not finite(edge[key]) or edge[key] < 0):
                    raise ValueError("Nonnegative cost or drop required")
        if any(node not in nodes for node in section.get("joins", [])):
            raise ValueError("Unknown join node")
    return identities


def validate_collision(data):
    fields(data, COLLISION_FIELDS)
    identifier(data.get("id"))
    for key in ("originX", "originY", "cellSize", "width", "height"):
        if not finite(data.get(key)):
            raise ValueError("Finite grid geometry required")
    if data["cellSize"] <= 0 or data["width"] <= 0 or data["height"] <= 0 or data["width"] % 1 or data["height"] % 1:
        raise ValueError("Positive grid dimensions required")
    rows = data.get("rows")
    if not isinstance(rows, list):
        raise ValueError("Explicit collision rows required")
    if len(rows) != data["height"]:
        raise ValueError("Collision row count differs from height")
    for row in rows:
        if not isinstance(row, list) or not row:
            raise ValueError("Explicit collision column ranges required")
        column = 1
        for span in row:
            fields(span, {"from", "to", "state"})
            first, last = span.get("from"), span.get("to")
            if (not finite(first) or not finite(last) or first % 1 or last % 1
                    or first != column or last < first or last > data["width"]):
                raise ValueError("Collision ranges must cover columns in order without gaps or overlaps")
            if not isinstance(span.get("state"), str) or span["state"] not in COLLISION_STATES:
                raise ValueError("Unknown collision state")
            column = last + 1
        if column != data["width"] + 1:
            raise ValueError("Collision row width differs from grid")


def validate_catalogue(records):
    networks, masks, identities = {}, {}, set()
    for record in records:
        key = record["profile"], record["data"]["id"]
        if key in identities:
            raise ValueError("Duplicate registered identity: " + str(key))
        identities.add(key)
        if record["api"] == "RegisterRoadNetwork":
            validate_network(record["data"])
            networks[key] = record["data"]
        else:
            validate_collision(record["data"])
            masks[key] = record["data"]
    for (profile, _), network in networks.items():
        collision = network.get("collision", {})
        for mask in ([collision["base"]] if collision.get("base") else []) + collision.get("overlays", []):
            if (profile, mask) not in masks:
                raise ValueError("Unknown collision mask: " + mask)
        if collision.get("base"):
            base = masks[(profile, collision["base"])]
            if any(span["state"] == "inherit" for row in base["rows"] for span in row):
                raise ValueError("A base collision mask cannot inherit from another mask")
    return len(networks), len(masks)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args()
    paths = args.paths or sorted(DATA.glob("*/Roads/**/*.lua"))
    networks, masks = validate_catalogue(read_declarations(paths))
    print(f"Road catalogues valid: {networks} networks, {masks} collision masks")


if __name__ == "__main__":
    main()
