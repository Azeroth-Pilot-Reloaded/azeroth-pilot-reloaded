# Retail declaration preparation

`namespace.NavigationV2RetailData.Prepare({config,connections,bindings}, request,
options)` returns a bounded `Step(operations,milliseconds)` / `Cancel()` job.
`config` and `connections` are the existing public data tables, not V1 edge
builders or geometry/routing algorithms. The caller retains them read-only while
the job runs. Request endpoints are copied at creation.

`request.from/to` accept normalized map points (`mapID` or `uiMapID`, `x/y`)
or declared world points (`space='world', instanceID, x/y`, optional z/map).
The benchmark may provide `coordinateUnit='map-percent'`; only those request
points are divided by100. Source V1 map declarations are already normalized.
The benchmark factory may instead normalize its copy once and omit that unit.
After range validation, normalized map numbers use a common15-significant-decimal
representation before projection and node identity. This removes the final binary
bit introduced by percent scaling. It is a numerical unit codec; it adds no
distance radius or walking edge. World coordinates, floors, phases, access keys
and world IDs remain separate. The caller's input and source tables are unchanged.

`options.mapToWorld(mapID,xNormalized,yNormalized)` may return worldID,xWorld,yWorld
in yards. It is the caller's guarded conversion callback. World0 is valid.
Without it, an exact map endpoint can still use a declared passage with an
explicit cost; a free approach needing world distance remains unavailable.
No map bounds are converted into invented native coordinates or collision proof.

Options include `movement` (the captured Retail profile), `actor` with observed
faction/class/level/raceID/inGroup, `conditionObservation`, `resources` and `walkSpeed` (7yards/s
default model). `clock` is monotone **milliseconds**, as supplied by the benchmark
driver. Budgets are1ms/slice,100ms CPU,5000ms elapsed, optionally reduced by the
driver's remaining allowance. Step never resets its cumulative budget. The
driver measures factory/preparation/solver together and owns the total allowance.
The result does not return replacement clocks or a fresh solver budget.

Success returns `{status='complete', graph, request={from=string,to=string},
options, positions, provenance, diagnostics}`. The caller invokes the existing
New/Plan/Step solver. No output, event, mount, quest or normal-host activation is
performed. Cancel/terminal budget stops release partial arrays and do not retry.

This first projection retains physical passage/portal/boat/zeppelin/tram/elevator
declarations touching a request map or world. It preserves explicit direction
and seconds. Unknown cost remains an unknown edge, never a usable free crossing.
An explicit nonnegative `seconds`, including0, overrides estimation and is charged
once. An absent `seconds` on `kind='passage', costMode='ground'` uses the existing
planar walking model: endpoint XY distance in yards divided by captured
`walkSpeed` (default7yards/s). Both endpoints must have a known equal world and
finite declared/projected world coordinates. Map fractions without conversion
cannot provide yards; different world frames cannot provide a distance. No
height is fabricated or required by this planar model. A supplied invalid total
is unknown, not an invitation to estimate. A `path` or `via` without an explicit
total is not projected by this adapter and remains a local
`ground_geometry_unsupported` gap; it is never replaced by its endpoint chord.
The ground passage keeps its direction, access conditions and mandatory endpoints;
its cost is not replaced by mounting/skyriding speed. This is a movement estimate
from the declared passage, not measured terrain or exhaustive collision proof.
Raw quest completion is compiled into the existing typed conjunction; known
faction/class/level/race/group restrictions are evaluated from the captured actor. Unsupported
predicates remain local unknown edges with bounded gap receipts. Endpoint world,
space, floor and phase are positions, not global current-player requirements.

Raw `all`, `any`, `questsAll`, `questsAny` and `notCondition` preserve conjunction,
alternatives and negation through bounded parallel conjunctions in the existing
Conditions tracker. There are at most64 alternatives/facts and12nested levels;
excess/unsupported structure becomes a local unknown. Quest completion uses the
quest map; account/active quests, achievements, toys, auras, holiday, phase,
map-art, garrison and housing predicates expose explicit access-fact dependencies.
`mapID/maps/notMaps/outdoors/notInstance` use each planned source point's known
location, not the actor's unrelated current map. Config.MapRequirements for both
ends remain access conditions. No native query runs in this compiler.
An instance ancestor remains an instance for an outdoor child. A reliable current
origin may supply its actual indoor/instance state only at that matching node.

The graph is always partial (`complete=false`). It does not claim a global optimum
or prove disconnection. Unrelated worlds are counted in `outsideScope`.

Spell/item declarations retain their action alternatives and individual
requirements. `groupSpellID` is a separately observed spell alternative for an
observed group, with its declared group reagent if present. A dynamic destination
requires `dynamicPositions[kind]={reliable=true,position=<map/world point>}`.
For bind, `reliable=true,areaID=<observed binding ID>` may select the corresponding
existing GetBindings candidate. No first candidate or future node becomes the
current player's binding. Unknown bind/camp/housing observations stay local gaps.

`personalObservation` uses the existing Personal snapshot fields, with actions
keyed by canonical `spell:<id>` / `item:<id>`, not source route aliases. Cast
duration comes from captured action facts or an explicitly declared source
default; loading uses an explicit policy or source config estimate. A declared
total is retained exactly once. Missing costs/readiness/inventory are unknown.
The observation epoch (observedAt/readyAt in seconds) must match the solver clock.

Complete known cooldown/charge policies with a supplied reliable origin use the
existing Personal planner, including waits, regeneration and shared resources.
No execution/secure/waypoint API is called. When a future period/charge policy or
cost split is unknown, an action already confirmed ready can use a conservative
first-use resource token shared by its declared cooldownGroup or canonical API.
The token is never restored from an invented period. Missing execution-origin
proof uses that planning-only first-use projection too; it never fabricates a
Personal native-origin observation. Consumables/reagents/money share the existing
Resources balances across the path. Unknown required quantities cannot become0.
Item aliases share inventory and known charge mode. Catalogue/resource ceilings
remain explicit; this partial graph does not certify all possible future journeys.
Known absence of a spell/item remains a capability denial. Current local
unusability/combat/casting denies the confirmed current origin; other future
departures remain unknown unless independently supported. No current indoor or
usability observation is promoted to a universal future-world permission/denial.

For native capture, `options.deferObservations=true` pauses once after source
discovery: `Step` returns running/phase=`observation_required`.
`job:GetObservationRequests()` exposes read-only `{origin,actions,quests,access,
dynamic}`. Actions are a canonical dictionary; access entries retain predicate
parameters. `job:ResumeObservations({personalObservation?,conditionObservation?,
dynamicPositions?,actionPolicies?})` resumes the SAME job and budgets once. Native
reads/batching belong to the caller at this explicit boundary, not to Data or the
solver. Without opt-in, absent observations stay unknown locally and previously
known paths still calculate. Stale/cancelled/finished jobs reject a second resume.
`actionPolicies[canonical]` may supply known cooldownSeconds/chargeBased/loading
and reagent quantities. A newly resolved dynamic target can reveal additional
destination-map facts; uncaptured facts remain unknown, never true by default.

Local connections require matching known world/region, compatible access/floor/
phase, no noAutoconnect and no unresolved enclosed-space ambiguity. Parent
restrictions inherit; direct children of a declared isolated continent remain
separate regions. A building/cave requires its declared exit before connecting to
another space. Within a known space, planar movement is an explicit model; there
is no exhaustive ground collision prerequisite. Outdoors do not acquire a new
mandatory height field. `groundOnly` prohibits the generated skyriding connector.
With a profile, the solver compares walking, mounting and usable mounted skyriding
using its model costs. Without one, this job creates walking connectors only.
World-only endpoints also query existing bounded spaces without requiring a new
UI-map hint. Restricted/isolated overlaps remain ambiguous; unrestricted duplicate
presentation maps do not create an artificial floor requirement.

The caller must bind native departure observations to the actual player's
departure. A manual benchmark point elsewhere must not silently inherit the
player's indoor/flyable state or claim that player's mount mode there. The
factory owns that capture/model distinction; the preparation does not mutate
an already-owned movement profile.

Preparation metrics count actual source declarations, conversions, work units
and generated edges. `positions` and graph IDs are technical diagnostics only.
The report's real30s passage receipt exercises actual maintained declarations
through this job and the real solver; it is not native arrival, UI, unrestricted
XY or world-wide coverage certification.
