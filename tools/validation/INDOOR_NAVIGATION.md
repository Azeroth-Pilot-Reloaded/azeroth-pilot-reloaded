# Bounded indoor navigation

The Retail packs cover the Orgrimmar portal tower (main hall, basement and
connecting stairway) and Stormwind's Wizard's Sanctum (entrance room, rear room
and stairs). They are ground-only collision graphs from installed client
`12.1.5.70688`, product `wow`, build key `0149337da1d526fc64bf43982c650577`.
They do not advertise other interiors or complete world coverage.

## Reproduction and provenance

Route-generator owns `tools/navigation_terrain/regions_cli.js` and the bounded
catalogue `retail-interiors.json`. Run the documented native generation command
there against the exact installed build. Geometry is read from the local CASC
storage; source archives are never modified. ADT/WMO surfaces, walls, clearance,
heights and directed connections determine the graph. Catalogue portal/entry
positions select connected components; they do not create links or invent stairs.

The Orgrimmar source includes WMO 367552, placement 5746298, and stairway group
451646. Stormwind includes WMO 2320850, placement 23477151, and rear hall group
5198158. These are offline provenance, not live-client API requirements. Derived
navigation graphs are shipped, without models, textures or raw source triangles.
`NavigationData/manifest.json` records build/reader identity, scoped tile coverage
and SHA-256 for each shipped file. Index world IDs are numeric Lua keys.

Copy the verified addon folders under `NavigationData/`, replace the lightweight
terrain index, record the discovered sibling moves in `.pkgmeta`, then regenerate
the file manifest. The package validator checks the load-on-demand addons. Common
data integrity tests discover every indexed pack; they do not freeze these rooms'
portal counts, coordinates or itinerary.

## Native height and route proof

The reported client observation was `(1429.8000488281,-4368.8002929688,0,1)`.
Its XY intersects ADT ground near Z20.998 and indoor WMO ground near Z25.454.
Observed indoor state and surface provenance distinguish them. Z0 is retained as
`observedZ`; the effective height is labelled as derived. Missing indoor state or
two matching indoor floors remain ambiguous until connected progress proves the
layer. The same rule follows descending stairways without treating XY proximity
as arrival on another floor.

Real-pack Lua 5.1 smoke runs used the actual library and cold geometry caches.
The reported native-zero start reached upper and lower portal approaches through
87 and 133 shape points respectively; the basement path descended below Z0.
Stormwind's inner entry reached a rear-room portal through 241 points and climbed
from roughly Z65 to Z75. These are measurements of the current bake, not regression
test expectations. Synthetic tests pin engine behavior; discovered common checks
validate the current declarations.

Both packs retain about 36 MiB with a local geometry cache; a live world-planning
job raised the standalone smoke to about 57 MiB. Parsing and registration took
about 0.5–0.9 seconds combined;
that load is synchronous once per load-on-demand addon. Route preparation/search
took about 0.1–0.3 seconds, split into bounded slices. Values vary by host and
client; this representation remains unsuitable for publishing a full continent.

## In-client verification

Install APR and both `APR_NavData_Retail_*` sibling addons before starting WoW.
For the exact supported build, check:

- Begin in the reported Orgrimmar corridor: the minimap line follows the corner
  rather than drawing a chord across the wall.
- Select a basement portal, descend the staircase, and return upstairs. The
  guidance cursor must retain corners and must not complete an approach from the
  other floor.
- Enter Stormwind's tower through its real entrance transition, then walk to a
  rear-room portal through the connecting stairs; test the reverse direction.
- Move off the corridor and change steps: guidance should refresh from the
  observed position. It must stay continuous between route steps.
- Repeat in combat and on an unsupported client build: deferred/refused data
  must not authorize a straight shortcut through the covered room.
- Export APR's status report when a layer cannot be identified. It includes raw
  and effective height, indoor state and the explicit terrain reason.

Automated mocks and collision extraction do not establish the client's rendering,
local portal phasing or the observed indoor flag at every threshold. The reported
native Z0 is confirmed by the user; the final displayed path still needs the
in-client checks above.

## Validation journal

- Reproduced the missing terrain inventory and the reported native Z0. Inspected
  source geometry to distinguish buried ADT terrain from the indoor WMO floor.
- Added synthetic regressions before changes for scoped routing, boundary
  approaches, indoor speed, native-height recovery and catalogue walking hints.
  Independent review reproduced two additional height-continuity defects; both
  received fixes and regression coverage.
- Baked and pruned only physically connected collision components. A second bake
  after the exact-boundary wall check produced byte-identical real packs.
- Ran real Lua planning, assembly and native-zero guidance across both levels and
  the rear room: every smoke guidance session reached `arrived`. The full world
  planner retained the terrain walk before the actual intercontinent portal.
- Reproduced dense-bucket visibility exhaustion, then verified bounded local and
  diagonal queries with synthetic data and both real packs.
- Ran `python tests/run.py`: 581 tests passed. Instrumentation write/check and
  `git diff --check` passed. A local release-layout preview validated APR plus
  both load-on-demand addons and all client runtime references.
- Invoked UB crapper, dryer and mutator for the changed Lua. These installed tools
  reported no supported source files; they do not measure Lua complexity or
  mutation coverage. Generator-side JavaScript checks are recorded separately in
  Route-generator's terrain validation journal.
- Installed the 15 changed runtime files and both terrain addons into the Retail
  addon directory, verifying copied file hashes. No source archives were changed.
