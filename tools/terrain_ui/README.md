# APR Terrain

APR Terrain builds walking graphs from an installed World of Warcraft client
and publishes verified Lua packs to LibAPRNavigation.

## Start the local interface

On Windows, run this command from the APR repository root.

```powershell
python tools/terrain_ui/server.py
```

You can also open `server.py` in VS Code and select **Run Python File**. The
server opens `http://127.0.0.1:8765/` in your browser. Keep the terminal open
while a generation is running.

The interface detects active Battle.net products in local installations. Use
`--wow "D:\Jeux\World of Warcraft"` to add an installation root and
`--port 8766` to pick a different port. Use `--no-browser` to open the URL yourself.

The generator uses the sibling `Route-generator` checkout, Rust and Cargo,
CascLib, WoWDBDefs and a prepared road texture list. The first run can compile
the native tools and download missing WoWDBDefs definitions.

## Select terrain and monitor generation

1. Choose a WoW client and a continent, zone or subzone. **All continents and
   worlds** selects every map with readable terrain in that client.
2. Use **Find a map** to search by name or ID. Enter a prefix such as
   `MapID 0`, `UiMapID 37` or `AreaID 18` to specify the ID type.
3. Select **Start generation**. A pause takes effect at the next engine
   checkpoint. The time estimate appears once enough progress has been measured.

The **Français** and **English** buttons switch the interface immediately.
Place names come from the client and fall back to an available language.

The engine retries temporary tile read errors. When a terrain model cannot be
opened, it checks the full CASC index for that build when available. References
missing from the index are logged as orphaned. Failures reading files present
in the index are reported as errors.

If a map exceeds the graph format's capacity, the engine retries all its tiles
at the next lower resolution. Open **Engine logs** to download the full log
and the JSON report. The report records the resolution used, excluded tiles,
unrepresentable floors or transitions, and the stage where a failure occurred.
Use **Retry unfinished maps** to rerun partial or failed maps with the same
selection and settings.

## Project files

The installer publishes verified maps under
`APR-Core/libs/LibAPRNavigation-1.0/Data/<profile>/Terrain/<mapID>/`.
The profile's `Terrain.xml` includes each map's `Terrain.xml`, which loads its
`Nav/` files. The directory also contains pack metadata and the tile inventory.

Retail test products use `Data/retail/Terrain/<product>/<mapID>/`, for example
`Data/retail/Terrain/wowt/<mapID>/`. The pack metadata and Lua load guard record
the exact client build. Publishing a new build reuses the same map directory.
On the same build, a narrower selection includes previously installed tiles
so the generator can rebuild their connections.

The launcher saves `generation.log` and `report.json` under
`tools/terrain_ui/reports/<product>/<build>/<client>/<selection>/`.
Git ignores this local reports directory. Temporary geometry, staged packs,
native build files and job state use the local generation workspace.

## Retail capital coverage

The list in `retail_capitals.json` records the capital maps and expansion hubs
included in the coverage audit. Separate map IDs cover the accessible floors
and phases. Names and world projections come from the selected client's DB2 catalogue.

```powershell
python tools/terrain_ui/capital_coverage.py --catalogue <client-catalogue.json> --build <exact-build> --out <report.json>
```

Use the Terrain interface's cached `catalogue-v2.json` for that build. The
audit loads the same terrain manifests as Retail and counts packed tiles,
indoor cells, overlapping indoor floors and indoor cells covered by detailed
collision. The counts describe the grid, and individual routes still need
walking verification.

## Retail path audit

```powershell
python tools/terrain_ui/retail_path_audit.py --catalogue <client-catalogue.json> --build <exact-build> --hub 2339 --out <report.json>
```

The default root is Khaz Algar. Set `--root` to audit a different UI map tree.
The audit uses the cached client catalogue and the shipped Retail terrain of
the same build. It samples connected graph points in each map projection,
replays local walks, tile crossings, indoor/outdoor transitions and elevation
changes, and checks the returned segments. It also checks that stacked surfaces
reject a direct vertical shortcut and records what happens with unknown origin
height. Authored passages and portals are replayed from their declared endpoints
using simulated quest progress.
The optional hub compares transport connectivity between each zone and that
map. This comparison estimates the walking legs between transport stops.

The JSON report records exact positions, missing coverage, path results and
transport directions. A missing witness, replay failure or timeout returns a
nonzero exit code. A projection supplies horizontal bounds, so overlapping
instance maps may cover the same terrain. For a relocated WMO documented in
the pack, the report retains the original projection status and replays the
specified floor at its current client coordinates. Live boarding, phasing and
traversal still require the game client.

For an entrance or exit, use `--journeys <cases.json>` in place of the map tree
audit. Each case has a `name`, `from` and `to` world positions with
`instanceID`, `uiMapID`, `x`, `y`, `z` and optionally `indoors`. An optional
`connections` list identifies the catalogued passages, lifts or portals to
include. Use `faction`, `level`, and `mapArt` to supply simulated character
observations. Declare any intermediate world packs in `viaWorlds`.
If a return portal lands at a different stop, set `returnFrom` or `returnTo`
to use a different position on the same side for that direction.
The audit computes both directions with the shipped walking provider and
reports the legs used by the planner. Choose points beyond the transition so
each side has a walking leg to verify.

## Forever faction policy

Maps `0`, `1` and `2991` use a faction policy stored in
`tools/forever/terrain/<build>/faction.json`. The launcher looks up the exact
client build automatically. The [1.60.1.71139 policy](../forever/terrain/1.60.1.71139/faction.json)
matches the provenance in the distributed Forever pack.

To prepare a policy for a new build, use a full extraction of all three maps,
matching `AreaTable` and `FactionTemplate` JSON exports, reviewed hub exports
for both continents, and the reviewed joins and cuts JSON. Pass the geometry
index file to `--geometry` and the reference revision used for the inputs to
`--source-revision`. Use `--hubs MAP=PATH` once per continent.

```powershell
python tools/forever/terrain_faction.py --help
```

The script writes `faction.json` and `faction-review.json` to the build directory
by default. Review the report before publishing graphs with the new policy. For a direct
`apr-terrain pack` invocation, pass
`--hubs tools/forever/terrain/<build>/faction.json` alongside the grid and
geometry inputs.

## Retail batch generation

Run the batch generator from the repository root when you have a prepared
Retail workspace for the installed build. It uses the world inventory, area
catalogue, community listfile, road texture list and CASC file index from that
workspace. Use `--cache PATH` to select an existing workspace.

```powershell
python tools/generate_retail_graphs.py --dry-run
python tools/generate_retail_graphs.py
```

Use `--worlds` followed by map IDs to limit the run. The generator verifies and
publishes eligible packs to LibAPRNavigation when generation finishes. The
coverage report and per-map engine logs are saved under
`tools/terrain_ui/reports/wow/<build>/batch/`.
