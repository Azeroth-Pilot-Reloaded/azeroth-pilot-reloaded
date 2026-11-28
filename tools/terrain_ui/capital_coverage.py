"""Measure indoor terrain in the installed Retail capital packs."""

import argparse
import base64
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zlib


ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "APR-Core/libs/LibAPRNavigation-1.0"
PACKS = LIBRARY / "Data/retail/Terrain"
SCOPE = Path(__file__).with_name("retail_capitals.json")


COUNT_CELLS = b"""
function(world, x1, y1, x2, y2)
    local st = Grid.State(world)
    if not st then return end
    local c = st.c
    local ix1, iy1 = math.floor((x1 - st.x0) / st.unit), math.floor((y1 - st.y0) / st.unit)
    local ix2, iy2 = math.ceil((x2 - st.x0) / st.unit) - 1, math.ceil((y2 - st.y0) / st.unit) - 1
    local expected, loaded, indoor, stacked, detailed = 0, 0, 0, 0, 0
    for tx = math.floor(ix1 / c), math.floor(ix2 / c) do
        for ty = math.floor(iy1 / c), math.floor(iy2 / c) do
            expected = expected + 1
            local inPack = tx >= 0 and tx < st.data.nx and ty >= 0 and ty < st.data.ny
            local key = tx * st.data.ny + ty
            local tile = inPack and Grid.grid(st, key)
            if tile then
                loaded = loaded + 1
                local atlas = Grid.surfaceAtlas(st, key, true)
                for ix = math.max(0, ix1 - tx * c), math.min(c - 1, ix2 - tx * c) do
                    for iy = math.max(0, iy1 - ty * c), math.min(c - 1, iy2 - ty * c) do
                        local cell = ix * c + iy
                        local floors = tile.z[cell] and (tile.class[cell] or 0) % 8 == 4 and 1 or 0
                        for _, node in ipairs(tile.layers[cell] or {}) do
                            if (tile.class[node] or 0) % 8 == 4 then floors = floors + 1 end
                        end
                        if floors > 0 then
                            indoor = indoor + 1
                            if floors > 1 then stacked = stacked + 1 end
                            if atlas then
                                local x, y = Grid.position(st, key, cell)
                                for _, window in ipairs(atlas) do
                                    if x >= window.xmin and x <= window.xmax and y >= window.ymin and y <= window.ymax then
                                        detailed = detailed + 1
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return expected, loaded, indoor, stacked, detailed
end
"""


def load_json(path):
    return json.loads(path.read_bytes())


def count_cells(build, worlds):
    from lupa.lua51 import LuaRuntime

    version, revision = build.rsplit(".", 1)
    major, minor, patch = map(int, version.split("."))
    lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)
    lua.globals().inflate = lambda value: zlib.decompress(base64.b64decode(value, validate=True))
    lua.execute(f"""
        strmatch = string.match
        function GetBuildInfo() return "{version}", "{int(revision)}", nil, {major * 10000 + minor * 100 + patch} end
        Enum = {{CompressionMethod = {{Zlib = 1}}}}
        C_EncodingUtil = {{DecodeBase64 = function(value) return value end,
            DecompressString = function(value) return inflate(value) end}}
    """)
    for name in (
        "../HereBeDragons/LibStub/LibStub.lua", "Core.lua", "Terrain/Namespace.lua", "Terrain/Costs.lua",
        "Terrain/PathGrid.lua", "Terrain/Path.lua", "Terrain/Partitions.lua",
    ):
        lua.execute((LIBRARY / name).read_bytes())
    lua.execute(b'Grid = LibStub("LibAPRNavigation-1.0")._TerrainNamespace.PathGrid')
    lua.execute((LIBRARY / "Terrain.lua").read_bytes())
    includes = {entry.attrib["file"] for entry in ET.parse(PACKS / "Terrain.xml").getroot()}
    for world in sorted(worlds):
        if f"{world}/Terrain.xml" not in includes:
            continue
        pack = PACKS / str(world)
        for entry in ET.parse(pack / "Terrain.xml").getroot():
            lua.execute((pack / entry.attrib["file"]).read_bytes())
    return lua.eval(COUNT_CELLS)


def hub_assignments(catalogue, hub, ui):
    assignments = {(world, tuple(bounds)) for world, _, bounds in catalogue["assignments"].get(str(ui), ())}
    for world, bounds in sorted(assignments):
        if "area" in hub:
            x1, y1, x2, y2 = bounds
            east, south = hub["anchor"]
            x, y = x2 - (x2 - x1) * south / 100, y2 - (y2 - y1) * east / 100
            # Subzones without a dedicated UI map share the parent projection.
            # Measure around the hub, including some ground outside its buildings.
            bounds = max(x1, x - 150), max(y1, y - 150), min(x2, x + 150), min(y2, y + 150)
        yield world, bounds


def continent_name(catalogue, ui, world):
    seen = set()
    while ui not in seen:
        seen.add(ui)
        item = catalogue["ui"].get(str(ui))
        if not item:
            break
        if item["Type"] == 2:
            return item["name"]
        ui = item["ParentUiMapID"]
    return catalogue["worlds"].get(str(world), {}).get("name", {})


def audit(catalogue, scope, build):
    worlds = {world for group in scope for hub in group["hubs"] for ui in hub["maps"]
              for world, _ in hub_assignments(catalogue, hub, ui)}
    measure = count_cells(build, worlds)
    columns = "tiles", "packedTiles", "indoorCells", "stackedIndoorCells", "detailedIndoorCells"
    for group in scope:
        for hub in group["hubs"]:
            label = (catalogue["areas"].get(str(hub["area"])) if "area" in hub
                     else catalogue["ui"].get(str(hub["maps"][0])))
            for ui in hub["maps"]:
                assignments = list(hub_assignments(catalogue, hub, ui))
                row = {"expansion": group["expansion"], "hub": label["name"] if label else {},
                       "uiMap": ui, "area": hub.get("area")}
                if not assignments:
                    yield {**row, "status": "missing_projection"}
                for world, box in assignments:
                    values = measure(world, *box)
                    state = "missing_pack" if values is None else "measured"
                    yield {**row, "continent": continent_name(catalogue, ui, world),
                           "world": world, "bounds": box, "status": state,
                           **(dict(zip(columns, values)) if values is not None else {})}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalogue", type=Path, required=True, help="Installed client's catalogue-v2.json")
    parser.add_argument("--build", required=True, help="Exact build used by the client catalogue and packs")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    report = {"build": args.build, "regions": list(audit(load_json(args.catalogue), load_json(SCOPE), args.build))}
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
