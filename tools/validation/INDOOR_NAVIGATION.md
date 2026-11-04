# Physical spaces and indoor navigation

APR uses one navigation engine for outdoor zones, subzones, caves, buildings,
floors, instances and transports on Retail and Forever. Logical identity and
physical coverage are separate: knowing that a cave exists does not prove its
stairs, entrance or a walk through its walls. The shipped collision inventory is
partial, and the engine does not claim complete WoW cartography.

## Spaces, containment and local exits

`Data/<profile>/NavigationSpaces.lua` declares native world/map/area identities,
optional 3D bounds, space types and `parentSpace` containment. Floor and access
selectors remain distinct. `groundOnly`, `requiresExit`, and controlled-transit
policy inherit through that hierarchy. The shared resolver rejects missing,
conflicting or ambiguous identity; a UI map is presentation evidence, not by
itself a physical connection between rooms.

When an objective is outside an enclosed origin, APR first proves a physical
local exit. A published exit prefix follows its mandatory corridor points, then
APR recalculates toward the original objective from the observed arrival. Quest
and route-step progress remain independent of this temporary navigation cursor.
Entering a neighboring enclosed room alone is insufficient: that room can lead
onward, but it cannot become an escape that sends the next replan back. Valid
prefix endpoints include an enclosing ancestor, the objective's own enclosure,
or an ordinary open outdoor/subzone space. An outdoor parent does not make all
its enclosed descendants valid exits. Localized physical portals remain real
crossings; an unrelated item/spell round trip does not prove a missing doorway.

An instance without a native UiMap can use its own world-instance coordinates
and a declared bounded mapless space. No synthetic UiMap ID or guessed exterior
landing is created. Ambiguous floors still require height or connected terrain
proof. Local world guidance can remain available while a map/waypoint projection
waits for an actual supported map.

## Native provenance and partial coverage

Route-generator discovers metadata and physical topology from pinned local
clients: Retail `wow` build `12.1.5.70688` and Forever `wowf` build
`1.60.1.70707`. Its `tools/navigation_terrain/topology_cli.js` discovers logical
spaces, native WMO group relationships, instance worlds and bounded collision
chunks. The older `regions_cli.js` also supplies the two portal-room packs.
See the generator's `tools/navigation_terrain/README.md` for prerequisites,
explicit extraction commands, checkpoint recovery and reports.

CASC archives are read without modification. ADT/WMO collision surfaces, walls,
clearance, height and verified transitions determine connections. Catalogue
portal/entrance positions can preserve a physically connected component; they
cannot invent a staircase or bridge a gap. Only derived navigation data ships,
without client models, textures, raw triangles or a native reader executable.

`NavigationData/manifest.json` records identities for both profiles, reader and
space-catalogue hashes, physical coverage reports and file hashes. A metadata-only
space remains valid inventory, with missing collision proof reported explicitly.
Unsupported or failed geometry is excluded. Two Retail WMO formats remain
unsupported by the current reader; discovering those spaces does not provide a
verified walking graph for them.

The current package contains 80 internal terrain chunks, including the two
earlier portal-room chunks. Their Lua sources total about 93.59 MiB. All terrain
files stay inside APR's `NavigationData` directory; no separate terrain addon or
extra addon-list entry is installed. These describe the present bake, not frozen
test fixtures.

## Scoped loading and route proof

`NavigationData/Terrain_[Game].xml` selects the current client's Lua factory
functions at startup. Parsing these functions does not construct their large
graph tables. The host calls a factory only when navigation needs its scope,
then reuses the registered immutable dataset. The other client's factories are
not loaded. The package validator checks that each indexed source is included
exactly once for its profile, after the host loader, and never for another client.
Terrain TOCs and sibling terrain addons are rejected.

The lightweight index selects bounded scopes needed by the request and by
winning transport approaches. A refused or pending scope blocks unsupported
shortcuts through its own volume while another healthy scope in the same world
can still supply a route. Build compatibility and the host loader's response
remain authoritative even when an older registration exists in memory.

Declared `neighborScopeIDs` form a lazy frontier. If the selected chunks cannot
prove a route or local exit, the planner expands adjacent chunks incrementally
and retries. Explicit cross-pack edges join proved seams; an internal chunk seam
is not an outdoor entrance. The frontier is finite, cancellable and shares the
planning budget. No centerline or nearest-node guess replaces missing geometry.
Registered immutable sources and accepted geometry caches are reused without
assuming that every scope in the world is available.

Catalogue passages marked `terrainWalk` yield to collision geometry when covered.
Actual portal/teleport entrances keep their explicit crossing. Outside physical
coverage, ordinary authorized-region navigation remains available, without a
claim that its straight segment has been checked against native collision.

## Faction and movement policy

Faction requirements describe actual transport eligibility. Separate
`transitFaction`/`transitRegion` metadata describes controlled territory: ordinary
transit avoids an opposing faction's controlled endpoints unless the character
already starts there or the explicit objective requires that same transit region.
Neutral physical services stay neutral. Unknown character or declared-space
identity does not authorize a restricted service; retained departures are checked
again against live observations. This policy does not pretend hostile terrain is
physically impossible to walk through.

Flight requires positive capability and local permission. APR does not transfer
a flyable departure's permission to another area or through an indoor volume.
Ground-only spaces and uncertain remote permission keep ground behavior. Aerial
edges require explicit mode states and landing/mount transitions; permitted
steady flight and skyriding compare horizontal travel, climb and descent cost
against verified alternatives. The engine can prefer a proved detour around a
mountain, but a ground-only or incomplete bake cannot establish an optimal flight
through the rest of that mountain. Reference speeds do not simulate skyriding
energy and still need client calibration.

## Native height and measured validation

Native Z0 and an `IsIndoors` observation of false do not establish the correct
surface. Diagnostics retain the native `observedZ`; an inferred ground height is
labelled `heightSource="terrain"`. Unique surface provenance or bounded progress
along the current/immediately connected proved ground leg can establish height.
Physical region/floor changes are allowed at that leg, while world/access-phase
changes, unrelated regions, large jumps and unknown airborne altitude remain
rejected. Unresolved stacked floors stay pending.

A Lua 5.1 smoke run loaded the real generated Cleft topology, library, planner
and guidance with cold caches. It followed 103/103 path observations to a genuine
outdoor endpoint while native Z stayed zero and the indoor observation stayed
false. Guidance reached `arrived`; modeled travel time was 34.624 seconds and
only three terrain chunks were used. This is an offline model measurement, not an
in-game journey, measured player travel time or proof of world coverage.

Synthetic graphs validate routing, containment, stairs, phases, faction policy,
flight permissions, deferred neighbors, failure recovery and scheduler budgets.
Common data checks discover every shipped declaration, verify hashes and space
references, and compile every indexed world with the real library. Tests never
freeze a maintained route, native room's coordinates or current geometry counts.
Run `python tests/run.py`, the instrumentation check and the release package
validator before delivery. Lua complexity/mutation tools currently do not support
these Lua sources; generator tooling has its own validation reports.

## In-client verification

Install APR for the exact supported client build. When upgrading from the old
separate-addon layout, remove the obsolete `APR_NavData_*` sibling folders after
installing the integrated terrain data. The addon list should contain no
separate APR terrain entries. Then verify:

- Follow a cave/building exit through the real corners, continue outside and
  confirm that recalculation retains the original quest/route objective.
- Descend and climb the Horde portal-room stairs; traverse the Alliance tower's
  real entrance transition, rear room and connecting stairs in both directions.
- Cross native map and floor thresholds while height reports zero, including an
  indoor flag of false; check that another floor cannot satisfy arrival.
- Enter an instance with no UiMap, verify local world guidance, and retain an
  explicit waiting state when map projection or floor identity is unavailable.
- Change steps, leave the corridor, reload, cross a loading screen and retry a
  pending source; stale geometry must not create an implicit shortcut.
- Check faction-controlled transit and flight restrictions with both factions,
  including an explicit objective in hostile territory and a no-flight area.
- Export APR's status report for failures: native/effective position, space and
  floor/access identity, scope coverage and the precise blocker should explain
  what remains unproved.

Mocks and extracted collision do not certify live phasing, client rendering,
secure actions or every native observation at a threshold. These client checks
remain necessary on Retail and Forever.
