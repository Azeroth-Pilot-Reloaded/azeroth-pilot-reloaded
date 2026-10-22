# Navigation performance

Measured on 21 October 2026 with Lua 5.1 through Lupa and simulated WoW APIs.
The clock uses Python `time.perf_counter_ns`; the measured callback overhead was
about 0.17 microseconds. These timings exclude loading Lua and parsing data files.

## Scheduling contract

APR schedules one planning stage per callback: bind lookup, transport catalogue,
taxi catalogue, graph search, optional flight-master exploration, then guidance
rows. The callback has a 1 ms target. Providers receive at most 0.9 ms, leaving
time for stage transitions and bookkeeping. With a clock, a 4,096-operation cap
also bounds work; without one, the cap is 64 operations.

The previous 64-operation cap left most of the time allowance unused during
search. On the 1,200-edge fixture it required 1,286 slices. The timed cap completes
the same search in about 55 slices. The final route and resource limits are
unchanged.

Deadlines are checked between operations. A client API, allocation, garbage
collection or OS preemption can exceed the remaining time. This is a cooperative
budget, not a hard real-time guarantee. `/apr perf` records actual planning
callbacks under `NavigationPlanningSlice` for verification in the game client.

## Changes that remove repeated work

- Catalogue queries share one build's answers for quests, auras, inventory,
  action usability, cast durations and names. A later build gets fresh answers.
- Successful map projections and ancestry are cached per library instance;
  explicit invalidation clears them. Dynamic destinations remain current.
- Taxi preparation reuses static topology and a completed graph when its inputs
  are unchanged. Each build still checks discoveries, access and current offers.
- Search reads provider arrays separately, indexes walking candidates by world
  instance, and shares unchanged resource tables between labels. Pareto checks
  and result assembly can yield too.
- The map and arrow reuse combined preview points until the queue advances or
  route geometry changes. Rectangle clipping uses scalar bounds instead of
  temporary tables for every segment.

Comments in the implementation explain cache lifetime, cancellation, resource
ownership and coordinate conventions. The controller's scheduling is separated
from the library's graph algorithm and each provider's data preparation.

## Measurements

The reproducible command uses five runs per scenario:

```powershell
py -3 tools/validation/benchmark_navigation.py --runs 5
```

It emits JSON with creation cost, total median time, slice percentiles, maximum
slice time and API counters. Timings are observations, so the script has no
pass/fail timing threshold.

| Scenario | Total median | Median slices | Slice p95 | Maximum slice |
| --- | ---: | ---: | ---: | ---: |
| 4,000 taxi paths, cold cache | 18.967 ms | 21 | 0.937 ms | 1.104 ms |
| Same taxi graph, warm cache | 0.118 ms | 1 | 0.112 ms | 0.112 ms |
| Retail catalogue, cold cache | 4.823 ms | 6 | 0.942 ms | 1.099 ms |
| Retail catalogue, warm cache | 3.619 ms | 4 | 0.914 ms | 0.915 ms |
| Forever catalogue, cold cache | 0.654 ms | 1 | 0.675 ms | 0.682 ms |
| Forever catalogue, warm cache | 0.359 ms | 1 | 0.400 ms | 0.412 ms |
| 1,200-edge search across 20 world instances | 49.628 ms | 55 | 0.907 ms | 0.940 ms |

The catalogue rows were measured again after the travel-data review, with 655
Retail and 64 Forever definitions. These are authored records, not a count of
available routes for a character. Warm builds needed no map/world projections;
availability and cooldown checks still run with fresh client answers. The cold
Retail run exceeded 1 ms once, so the target remains a cooperative budget.

A separate paired before/after run with identical inputs measured search work
falling from 1,444,801 to 82,265 operations, and median total time from 499.6 to
70.3 ms. Creating a search with 10,000 edges fell from 41.94 to 0.032 ms because
graph ingestion now occurs inside the scheduled work. Absolute timings vary
between runs; operation counts and regression tests provide the stable checks.

The tests use controlled clocks to verify deadlines, cancellation and stale
inputs. They also check cache invalidation, cumulative money and reagents, map
restrictions, probes after failed searches, and unchanged optimal routes.

## Idle and movement captures

The two client captures supplied on 21 October covered the same authored
objective. The idle capture lasted 272.516 seconds; the movement capture lasted
45.506 seconds. Complete function tracing was enabled in both.

| Observation | Idle | Moving |
| --- | ---: | ---: |
| Planner jobs created | 0 | 14 |
| Planner jobs cancelled | 0 | 8 |
| Planning slices | 0 | 1,760 |
| Taxi probe candidate evaluations | 0 | 27,578 |
| Median sampled APR CPU per frame | 0.152 ms | 1.185 ms |

The moving capture spent 1,691.779 ms inside planning slices. Inclusive parent
and child timings overlap and must not be added to this value. The capture
also recorded a median 46.512 FPS while moving, but client frame time alone
cannot attribute every slowdown to APR.

The direct-route result expired after two seconds. Ordinary subzone events and
unrelated spell cooldowns then restarted its search; cancelling the old result
also hid the arrow. The fixes retain a valid direct route during background
work, compare objective/access identities, and distinguish travel cooldowns
from the global cooldown. Static endpoint projections survive named subzone
changes, while world transitions and changed map art invalidate geometry.

The regression scenarios now verify:

- One graph build during two minutes of small movements around one objective.
- No arrow hide or UI rebuild when a background search confirms that route.
- No route resolution, projection or clipping during 100 unchanged map refreshes.
- At most seven expensive visibility checks during 200 idle arrow ticks over six seconds.
- Immediate invalidation for changed objectives, access boundaries and map geometry.

The taxi benchmark now includes nearby-objective probes. A paired five-run
comparison, with the same 4,000 paths and warm static index, measured:

| Probe | Previous operations | Current operations | Previous median | Current median |
| --- | ---: | ---: | ---: | ---: |
| 25-second candidate route | 4,001 | 221 | 5.912 ms | 0.270 ms |
| 5-second candidate route | 4,001 | 1 | 6.214 ms | 0.016 ms |

The planner skips creating the second probe entirely because boarding alone
takes longer. Longer probes reject groups of departures before inspecting their
outgoing paths. Unknown fares and the fallback after a failed search remain
covered by tests.

These are fixture measurements, not a post-fix client FPS capture. A full local
benchmark run still observed an isolated 3.161 ms search slice under concurrent
machine activity. The budget remains cooperative; reduced work and operation
counts are the stable evidence. Confirm the frame cost in WoW with the same idle
and movement captures, and with full tracing disabled for normal play.

### Follow-up idle capture

The follow-up client capture lasted 268.468 seconds, with full tracing and debug
calls enabled. It confirms the idle cache behavior:

- No navigation search, cancellation or publication was recorded.
- The arrow ran 267 full updates, about one per second. Its 9,871 outer calls
  checked current inputs; together they took 403.747 ms, including child calls
  (0.041 ms per call on average).
- No route-preview rebuild, segment projection or clipping was recorded.
- Recorder overhead fell from 0.58% to 0.24% of the capture duration.

Median sampled APR CPU was 0.162 ms per frame, compared with 0.152 ms in the
earlier idle capture. The lower routing work did not produce a lower overall
APR median in this run. Median client FPS fell from 96.618 to 35.629, so these
captures do not establish an improvement in client frame rate.

The largest attributed APR stall occurred when opening settings at 265.684 s:
55.581 ms of traced APR work preceded an 83 ms client frame. Other client stalls
had much less attributed APR work: a 69 ms frame had 0.151 ms, and an 89 ms frame
had 3.998 ms. These observations distinguish the settings-opening stall from
the steady idle routing cost; they do not identify the remaining client cost.
A follow-up movement capture is still needed to validate replanning in game.

### Follow-up movement capture and retained arrow

The next movement capture lasted 51.302 seconds. It recorded 20 planner starts,
15 explicit path-cache invalidations, five geometry-cache flushes and six
cancelled planner jobs. The 13 controller cancellation calls also include
cleanup when publishing direct guidance; they are not 13 cancelled searches.

The previous fix retained only a valid itinerary or proven direct route. When
either became invalid, cancelling it still cleared the visible arrow. The
controller now retains a display-only target for the same authored objective
and world while computing its replacement. The renderer updates its direction
and distance, without arrival checks, waypoint skipping or secure travel
actions. Publishing swaps the target without an intermediate hide. Objective
changes, explicit cancellation, death and world changes still invalidate it.

Two sources of redundant invalidation were also corrected:

- Revisiting a known map with unchanged map art retains its static projections.
  First visits, unknown art, real art changes and world loads still invalidate.
- A cooldown scan finishes updating all watched baselines before reporting a
  change. Shared cooldowns therefore produce one update request per scan,
  while each slice retains its operation and time limits.

Regression tests cover repeated replans, unusable actions, stale publications,
missing data, direct and transport replacements, and 100 crossings between
known maps. These verify state transitions and eliminated work; client FPS
after these changes still requires a new in-game capture.

### Personal travel display

The Harandar report showed a teleport instruction beside an arrow about 38 yards
away. The active-step dump confirmed spell 3567 and a direction toward the
search's original player position. That position was near a physical portal,
which made the instruction and arrow appear to describe different transports.

Personal travel actions now keep their planning endpoints without publishing a
fixed cast-location waypoint. The arrow frame is hidden during personal actions;
their executable controls stay in the current-step row. Physical portals keep their
directional arrows, and the map preview preserves necessary approaches and
arrival points without drawing a line back to the old cast origin.

Regression tests verify no duplicate icon lookup across 200 moving updates, restoration
of the normal arrow after an action, and replacement of spell rows and secure
buttons by portal instructions in and out of combat. Status exports now include
a bounded snapshot of the published navigation, its estimated duration and
movement speed, the arrow, and rendered navigation rows. This snapshot is built
only on export.

Instruction labels use parentheses supported by the client fonts. When WoW
initially resolves a world endpoint to a continent, the adapter asks for its
local map and verifies the matching projection. Missing local information keeps
the original map and coordinates together.

### Harandar portal duration correction

The subsequent report confirmed speed 60 and spell 3567 as the selected action.
The nearby Harandar return portal still carried an inherited routing weight of
30, while other imported portals used 5, 10 or 15. The migration had copied these
weights into seconds without evidence that they represented elapsed time.

The 220 inherited Retail portal weights are now omitted. These connections use
the profile's common loading estimate (five seconds), also used after personal
teleport casts. Explicit durations and waits remain supported; estimated edges
report `profile-estimated-loading`. This is an estimate, not a client measurement.

The regression uses the reported world positions and speed with the real
Harandar portal and Orgrimmar spell definitions. The direct portal wins even
against a hypothetical onward portal requiring no approach or final walk in
Orgrimmar. A second case starts farther away and confirms that the faster
personal teleport can still win. No portal identity is privileged by the search.

### Account unlocks and short-route replacement

The Voidstorm report exposed a separate eligibility error: quests 86549, 92423
and 86510 were all false on the alt, while Midnight achievement 42045 unlocked
its portals. The catalogue now accepts that account achievement through the
client API. Initial campaign and permanent portal endpoints have separate
conditions, so account completion does not reopen an obsolete introductory exit.
Achievement queries are memoized within each build and refreshed by live checks.
Earning an achievement requests a new route through the existing event scheduler.

The controller also required at least fifteen seconds of savings before replacing
a valid itinerary. That floor could retain a nineteen-second detour instead of a
fifteen-second direct portal. Replacement now requires a ten-percent improvement,
bounded between one and fifteen seconds. Committed actions remain protected;
near-tied alternatives retain the current guidance. Status exports include the
last comparison and its threshold without rerunning the search.

Tests cover an alt with every relevant character quest false, account completion,
quest-only unlocks, introductory phases, unavailable API data, one achievement
lookup per build, live changes, and direct Voidstorm-to-Silvermoon selection at
the reported coordinates and speed. Controller tests cover a nineteen-to-fifteen
second replacement and repeated half-second alternatives without oscillation.

### Departure conditions and Arcantina comparison

The 2026-10-22 audit covers all 719 catalogue records. Account completion is
queried only for declared shared rewards; character introductions and individual
spell destinations retain their own gates. Rejected map predicates can be
evaluated at a later departure without treating missing quest data as success.
These evaluations use the build's existing memoized API answers. Fixed portals
check each directed entrance; source-free actions retain per-map search caches.

Five local Lua 5.1 catalogue benchmark runs with a 0.9 ms cooperative budget
measured Retail preparation at a 2.84 ms warm median, spread across a median of
four slices. The warm maximum slice was 0.911 ms. Cold preparation had a 4.92 ms
median and a 1.265 ms maximum slice. These include fixture and clock overhead;
an indivisible API call or scheduling pause can exceed the requested slice.
They do not guarantee a frame rate in WoW.

Arcantina route tests compare a nearby direct portal, a distant portal with
fast flight, unavailable direct access, and an owned but unusable key. The
catalogue uses client cast time, two loading estimates and both walking legs.
The retired duplicate portal is excluded. No search weight favours an item ID.

### Shortcuts at every distance

Zone-display thresholds no longer accept a direct journey before comparing
transports. Portal, spell, item and taxi journeys compete on total estimated
time even at 581 or 7,774 yards. A confirmed path stays visible while a new
candidate is prepared, and exact timing ties remain stable. Every meaningful
time improvement can replace an uncommitted route.

Known height participates in node identity and ground costs. Cross-world
coordinates never produce a Euclidean distance. Ground-only map flags prevent
using a flight estimate inside a vault, Arcantina, Undermine, Oribos or the Timeways.
Live ground vehicle speed is retained only in its verified current map.

The catalogue remains incremental: importing more facts does not add an
unbounded synchronous source scan in game. Audit inventories and source parsing
are development tooling, excluded from the package.
