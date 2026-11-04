# Declared road collision cells

`RoadCollision.lua` is a new pure Lua 5.1 reader of the already declared V1 RLE
mask model. It proves or rejects one straight XY segment. It does not search for
a detour, attach to a road, publish a waypoint, estimate travel time, observe a
player, or establish an undeclared floor/phase/height. The module is exported as
`namespace.NavigationV2RoadCollision`; this unit does not add it to the manifest.

The public V1 data contract is in `LibAPRNavigation-1.0/README.md`, under
“Editable Forever road catalogues”. Only that contract and supplied data were
used, not V1 routing algorithms.

## Interface

```lua
local source, reason = namespace.NavigationV2RoadCollision.New({
    worldID = 0,
    base = resolvedBaseMask,
    overlays = { resolvedHighestPriorityMask, resolvedNextMask },
    -- Optional actual constraints, never fabricated:
    identity = { floor = "declared-floor", phase = "declared-phase" },
    -- Optional already resolved 2D barrier segments:
    walls = { { from = {x=1,y=2}, to = {x=3,y=4} } },
}, {
    clock = monotonicSeconds,
    profileClock = monotonicMilliseconds,
})
assert(source, reason)

local state = source:Step(64) -- repeat while status == "running"
-- status ready means MASK HEADERS ready, not globally valid geometry.
assert(state.status == "ready", state.reason)

local job, why = source:Query({
    from = {x=3.8,y=3.8},
    to = {x=3.2,y=3.2},
    mode = "walk", -- exactly walk or swim
})
assert(job, why)
local result = job:Step(64) -- repeat while running; optional lower slice in ms
-- or job:Cancel()
```

`New` and `Query` construct work without scanning rows. `New` requires explicit
clock functions and resolved masks; it never resolves a catalogue ID or infers
a world. No native API is called. `source:Step` validates/copies mask headers,
overlay order and supplied barrier segments one bounded work unit at a time.
`source:Query` returns `nil, "source_not_ready"` before that preparation finishes.
The input definitions, including unvisited rows/runs, must remain immutable for
the lifetime of the source. Create a new source on a data revision. Query points
and their supplied identities are captured by value.

Each mask has `id`, `originX`, `originY`, `cellSize`, `width`, `height`, `rows`,
and optional `splitHeight`, `blockedRuns`. A row is a dense array of inclusive
`{from=column, to=column, state=...}` spans covering exactly 1 through width.
Rows are addressed by one-based row number; X and Y decrease as row/column
increase. The first overlay is highest priority, followed by the other overlays
in order, then base. Outside an overlay, lookup continues below it. Only
`inherit` consults the next underlying mask; `unknown-floor` never does.

Unknown source/mask/point fields, metatables and malformed records are rejected
instead of silently losing a constraint. In particular, canonical `openings`
and raw wall polygons/strokes are not accepted by this interface. The future
assembler must resolve that geometry into the supplied barrier segments or
perform its own geometry check before accepting the connector. It must not
label an unresolved opening as an absent wall.

## Meaning and scope of a result

Sources expose `Step`, `Cancel`, `GetState`, `Query`. Query jobs expose `Step`,
`Cancel`, `GetState`. Returned states are fresh scalar tables. Terminal states
are stable and do no more work; cancel is idempotent. Cancelling a query retains
the shared source/cache. `source:Cancel` cancels unfinished header preparation;
it does not invalidate a ready source or other queries. Explicitly cancel unused
queries so their bounded active-job slots are released.

| Query status | Meaning |
| --- | --- |
| `complete` | Every touched cell in this straight segment passed the declared mode and identity constraints, and no supplied barrier intersects it. |
| `blocked` | An explicit blocker/mode/identity mismatch was encountered. |
| `unknown` | The visited scope lacks a usable row/domain, has an unresolved local modifier/floor, or the clock is unusable. |
| `invalid` | An invalid structural declaration or Step argument was encountered. |
| `budget_exceeded` | A cell/CPU/elapsed bound stopped this attempt. |
| `cancelled` | The caller cancelled this attempt. |

`complete` always carries `scope="declared_collision_cells_2d"`,
`validationScope="visited_rows_only"`, `globallyValidated=false`. It is a local
model proof, not a whole-world validation or observed client execution. The
source state carries `validationScope="mask_headers_only"` even after ready.
Unvisited rows may be absent or malformed; that never grants them a connection.
The first attempt to use such a row returns a precise non-positive result.

`wallScope` is `supplied_barrier_segments` when `walls` was supplied, including
an explicitly empty list, and `not_supplied` otherwise. A mask proof must not be
promoted to a claim about unsupplied walls/openings. Touching a supplied barrier,
including a collinear overlap or endpoint, blocks the segment conservatively.

`open` passes **walk** only; `water` passes **swim** only. Reasons include
`blocked_cell`, `water_requires_swim`, `land_requires_walk`, `wall_intersection`,
`unknown_floor`, `outside_domain`, `missing_row`, `invalid_row`, `row_span_limit`,
`split_height_unresolved`, and `blocked_run_unresolved`. Mode transitions and
mixed walk/swim connectors belong to the assembler, which can split the leg.
A walk proof never establishes mounted clearance.

Points can carry `worldID`, `space`, `floor`, `phase`, optional Z. Coordinates
without `worldID` are explicitly addressed in the source's already resolved
world. A supplied different world is rejected. Only identities actually
declared by the source or endpoints constrain the query. If a constrained
identity is missing at either endpoint the result is unknown; disagreement is
blocked. A plain 2D domain does not acquire fabricated Z/floor/phase fields.
Z is accepted but this unit makes no 3D surface claim from it.

## Local validation and bounded reuse

A visited row is validated in full, with a yield per key/span, before any of
its cells can pass. Gaps, overlaps, sparse/non-array keys and unknown states
therefore cannot hide behind a positive span. Only a copied, fully validated
row (or its failure) enters the source's LRU cache. Repeated queries reuse it;
an evicted row is revalidated. Cancelled partial row work is not published.
The cache is shared by all queries of this immutable source. Concurrent queries
may duplicate unfinished row work; they cannot observe a half-validated row.

Candidate masks are filtered by header bounds. A segment streams successive
grid-plane events from these candidates, evaluates each open interval and its
boundary, and composes overlay/base lookup for each touching quadrant. Thus a
fine overlay cannot be skipped by the base grid. Corner touches, grid-aligned
segments and endpoints check both sides conservatively. The outer domain
boundary has an unproved touching side and returns `outside_domain`. Numerical
rounding tolerance only broadens the cells checked; it never grants proximity
permission. No million-cell expansion or all-row validation occurs per query.

`splitHeight` is retained. Its unresolved convention makes a non-inherit positive
cell in that mask unknown, with `split_height_unresolved`; an unaffected area or
transparent inherit still uses the other masks. `blockedRuns` is indexed lazily
for a mask actually consulted, yielding per entry. A cell in a named run is
unknown with `blocked_run_unresolved`, unless already explicitly blocked. Other
cells remain usable. No unverified floor interpretation or ignored blocker is
introduced. Invalid run metadata rejects that attempt; the rest of the source
does not become globally admitted or globally unusable.

Clocks are required, finite, nonnegative and monotonic. Default budgets come
from `NavigationV2Graph.Budgets` (standalone fallback: 1 ms per slice, 100 ms
active CPU total, 5,000 ms elapsed). Options may only lower them. CPU includes
work between the profiling samples and excludes idle gaps between Step calls;
elapsed starts at the first Step. Exact total deadlines stop the attempt.
Checking after every bounded unit can overrun a slice by that unit. A stopped
attempt never restarts itself.

Default hard ceilings (options may only lower them):

| Option | Ceiling |
| --- | ---: |
| `maxMasks` (including base) | 512 |
| `maxRowSpans` | 4,096 |
| `maxCachedRows` | 256 |
| `maxCachedSpans` | 65,536 |
| `maxRuns` (indexed across source) | 65,536 |
| Runs per row | 128 |
| `maxCells` (touching-cell checks per query) | 65,536 |
| `maxWalls` | 4,096 |
| `maxJobs` | 8 |
| Step operations | 4,096 |
| Mask width/height | 4,000,000 |

Each active query can additionally hold one current row (at most
`maxRowSpans`/`maxCachedSpans`) and one unfinished run index (at most `maxRuns`), candidate headers
and at most two event streams per mask. Completed jobs release those source
references. Caller-owned immutable declarations are not duplicated globally.
Coordinates/origins are bounded to 2,147,483.647 yards; cell size is 0.001 through
2,147,483.647 yards. Limits report their scope; they do not mean data is absent.

## Verification and next consumer

The independent family is discovered by
`tests/scripts/test_navigation_v2_road_collision.py` and can run with:

```powershell
python -m unittest tests.scripts.test_navigation_v2_road_collision -v
```

Synthetic tests cover free points, RLE integrity, positive/negative cells and
explicit identities/modes, overlay precedence/inherit, modifiers, walls,
corner/boundary/numerical cases, 60 exhaustive rectangle-oracle cases, a large
unvisited world, LRU reuse/eviction, cancellation, clocks and budgets. No shipped
route, mask name/count or itinerary is frozen in these tests.

ROOT owns manifest/instrumentation integration and the frozen global test gate.
The later assembler must supply resolved worlds/masks/geometry, handle source
revisions, connect to declared road segments/joins, find detours if needed and
compose the movement costs and guidance. None of that is claimed by this unit.
