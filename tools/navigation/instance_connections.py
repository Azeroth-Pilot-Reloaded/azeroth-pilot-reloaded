"""Validate and format APR's editable instance connection catalogues.

The Lua catalogue is the maintained data. This tool needs no other addon or
source manifest. Run --check after editing it; --format is an explicit write.
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path
import re
import unicodedata

from lupa.lua51 import LuaRuntime, lua_type


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CATALOGUE = ROOT / "APR-Core/libs/LibAPRNavigation-1.0/Data/forever/InstanceConnections.lua"
IDENTIFIER = re.compile(r"^apr-[a-z0-9]+(?:-[a-z0-9]+)+$")


def slug(value):
    """Use a readable place name, without depending on a display translation."""
    value = unicodedata.normalize("NFKD", str(value)).encode("ascii", "ignore").decode().lower()
    value = value.replace("'", "").replace("’", "")
    result = re.sub(r"[^a-z0-9]+", "-", value).strip("-")
    if not result:
        raise ValueError("A readable place name is required")
    return result


def coordinate(value, positive, negative):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValueError("Finite coordinates are required")
    if value == 0:
        return "zero"
    # str preserves the authored precision. An edited coordinate is visible in
    # its identity rather than hidden behind a digest or an unstable ordinal.
    number = str(abs(value))
    if number.endswith(".0"):
        number = number[:-2]
    number = number.replace(".", "p").replace("e+", "e").replace("e-", "e-minus-")
    return (positive if value > 0 else negative) + "-" + number


def connection_id(kind, place, origin=None, point=None, profile="forever", destination=None):
    """Create a stable APR identity; callers keep existing IDs when editing."""
    values = ["apr", slug(profile), slug(kind), slug(place)]
    if origin:
        values.extend(("from", slug(origin)))
    if point is not None:
        values.extend(("at", coordinate(point["x"], "north", "south"),
                       coordinate(point["y"], "west", "east")))
        if "z" in point:
            values.extend(("height", coordinate(point["z"], "above", "below")))
    if destination is not None:
        values.extend(("to", coordinate(destination["x"], "north", "south"),
                       coordinate(destination["y"], "west", "east")))
        if "z" in destination:
            values.extend(("height", coordinate(destination["z"], "above", "below")))
    return "-".join(values)


def _array(value, label):
    if isinstance(value, list):
        return value
    if isinstance(value, dict) and set(value) == set(range(1, len(value) + 1)):
        return [value[index] for index in range(1, len(value) + 1)]
    raise ValueError(label + " must be a contiguous array")


def _finite(value):
    return not isinstance(value, bool) and isinstance(value, (int, float)) and math.isfinite(value)


def _integer(value):
    return _finite(value) and value >= 0 and value % 1 == 0


def _position(point):
    if not isinstance(point, dict) or not _finite(point.get("x")) or not _finite(point.get("y")):
        raise ValueError("Finite position coordinates are required")
    if point.get("space", "world") != "world" or not _integer(point.get("instanceID")):
        raise ValueError("A native world instance is required")
    if "z" in point and not _finite(point["z"]):
        raise ValueError("A known height must be finite")


def validate_catalogue(data):
    """Check all current records with common rules, without repairing them."""
    if not isinstance(data, dict):
        raise ValueError("A catalogue table is required")
    identities = set()

    def identity(record):
        value = record.get("id")
        if not isinstance(value, str) or not IDENTIFIER.fullmatch(value):
            raise ValueError("A readable APR identity is required")
        if value in identities:
            raise ValueError("Duplicate APR identity: " + value)
        identities.add(value)

    connections = _array(data.get("connections", []), "Connections")
    entrances = _array(data.get("entrances", []), "Entrances")
    spaces = _array(data.get("config", {}).get("NavigationSpaces", []), "Navigation spaces")
    for record in connections:
        identity(record)
        if record.get("kind") not in {"portal", "passage", "elevator", "tram"}:
            raise ValueError("An explicit physical connection kind is required")
        _position(record.get("from"))
        _position(record.get("to"))
        if not _finite(record.get("seconds")) or record["seconds"] < 0:
            raise ValueError("A nonnegative travel duration is required")
        if not isinstance(record.get("bidirectional", False), bool):
            raise ValueError("Connection direction must be explicit")
        if record.get("reviewStatus", "confirmed") not in {"confirmed", "candidate", "disabled"}:
            raise ValueError("A connection review status must be confirmed, candidate or disabled")
    for record in entrances:
        identity(record)
        if record.get("kind") not in {"dungeon", "raid"} or not _integer(record.get("instanceID")):
            raise ValueError("An instance entrance identity is required")
        if record.get("reviewStatus") not in {"confirmed", "candidate", "disabled"}:
            raise ValueError("An entrance review status is required")
        _position(record.get("exterior"))
        _array(record.get("interiorMapIDs", []), "Interior map IDs")
    for record in spaces:
        identity(record)
        if record.get("kind") not in {"instance", "transport"} or not _integer(record.get("worldID")):
            raise ValueError("A native instance space is required")
        _array(record.get("mapIDs", []), "Space map IDs")
        bounds = record.get("bounds", {})
        for axis in ("X", "Y", "Z"):
            low, high = bounds.get("min" + axis), bounds.get("max" + axis)
            if not _finite(low) or not _finite(high) or low >= high:
                raise ValueError("Valid instance bounds are required")
    return {"connections": len(connections), "entrances": len(entrances), "spaces": len(spaces)}


def _plain(value):
    if lua_type(value) == "table":
        return {key: _plain(child) for key, child in value.items()}
    return value


def load_catalogue(path):
    runtime = LuaRuntime(unpack_returned_tuples=True, register_eval=False, register_builtins=False)
    captured = []

    def register(_, profile, category, data, revision):
        captured.append((profile, category, _plain(data), revision))

    library = runtime.table()
    library["RegisterData"] = register
    runtime.globals()["LibStub"] = lambda _: library
    runtime.execute(Path(path).read_text(encoding="utf-8-sig"), name="@" + str(path))
    if len(captured) != 1:
        raise ValueError("One APR instance catalogue declaration is required")
    profile, category, data, revision = captured[0]
    if category != "instance-connections":
        raise ValueError("Unexpected APR instance catalogue category")
    validate_catalogue(data)
    return profile, data, revision


def _quote(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r") + '"'


def _lua(value, indent=0):
    if isinstance(value, str):
        return _quote(value)
    if value is True:
        return "true"
    if value is False:
        return "false"
    if value is None:
        return "nil"
    if isinstance(value, (int, float)):
        if not _finite(value):
            raise ValueError("A finite catalogue number is required")
        return str(value)
    if isinstance(value, list) or isinstance(value, dict) and set(value) == set(range(1, len(value) + 1)):
        values = _array(value, "Lua array")
        if not values:
            return "{}"
        fields = [_lua(child, indent + 4) for child in values]
    elif isinstance(value, dict):
        order = ("id", "kind", "bidirectional", "reviewStatus", "instanceID", "worldID", "from", "to", "seconds",
                 "requirements", "exterior", "interiorMapIDs", "mapIDs", "bounds", "requiresExit", "groundOnly",
                 "space", "uiMapID", "x", "y", "z", "minX", "maxX", "minY", "maxY", "minZ", "maxZ")
        keys = sorted(value, key=lambda key: (order.index(key) if key in order else len(order), str(key)))
        fields = [(str(key) if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", str(key)) else "[" + _quote(str(key)) + "]")
                  + " = " + _lua(value[key], indent + 4) for key in keys]
        if not fields:
            return "{}"
        if set(value) <= {"space", "instanceID", "uiMapID", "x", "y", "z", "isInstance"}:
            return "{ " + ", ".join(fields) + " }"
    else:
        raise ValueError("Only declarative catalogue fields are supported")
    prefix = " " * (indent + 4)
    return "{\n" + "\n".join(prefix + field + "," for field in fields) + "\n" + " " * indent + "}"


def render_catalogue(data, profile="forever", revision=1):
    validate_catalogue(data)
    return ("-- APR instance connections and exterior entrances. Edit these records directly.\n"
            "-- World coordinates are yards; missing Z remains unknown.\n"
            'LibStub("LibAPRNavigation-1.0"):RegisterData(' + _quote(profile)
            + ', "instance-connections", ' + _lua(data) + ", " + str(revision) + ")\n")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("catalogue", type=Path, nargs="?", default=DEFAULT_CATALOGUE)
    parser.add_argument("--check", action="store_true", help="Validate only; never repair data")
    parser.add_argument("--format", action="store_true", help="Explicitly format the maintained catalogue")
    args = parser.parse_args(argv)
    if args.check and args.format:
        parser.error("--check and --format are mutually exclusive")
    profile, data, revision = load_catalogue(args.catalogue)
    if args.format:
        args.catalogue.write_text(render_catalogue(data, profile, revision), encoding="utf-8", newline="\n")
    print(validate_catalogue(data))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
