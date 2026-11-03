# LibAPRNavigation-2.0 — NAV-01

The pure planner consumes explicitly supplied graphs, transports, observations
and prerequisites. It never infers missing terrain connectivity or access facts.
No V1 implementation is loaded.
APR keeps its existing navigation engine active by default.

## Pure Lua 5.1 API

```lua
local namespace = {}
local root = "APR-Core/libs/LibAPRNavigation-2.0/"
local manifest = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = manifest:read("*a"); manifest:close()
for module in xml:gmatch('<Script%s+file="([^"]+)"') do
    assert(loadfile(root .. module))("standalone", namespace)
end
local Navigation = namespace.LibAPRNavigationV2
local graph = {
    complete = true,
    nodes = { "departure", "passage", "destination" },
    edges = {
        { id = "approach", from = "departure", to = "passage", seconds = 4 },
        { id = "crossing", from = "passage", to = "destination", seconds = 5 },
        { id = "bypass", from = "departure", to = "destination", seconds = 1 },
    },
}
local planner, reason = Navigation.New(graph, {
    clock = elapsedSeconds,       -- injected monotonic wall clock
    profileClock = profileMs,     -- injected high-resolution profiling clock
    -- budgets = { sliceMs = 1, cpuMs = 100, elapsedMs = 5000 },
})
assert(planner, reason)
local job = planner:Plan({ from = "departure", to = "destination", via = { "passage" } })
local result = job:Step(64) -- call again on a later host tick if running
-- Successful result: estimatedSeconds = 9; the bypass misses the required visit.
```

`New` checks the fixed-size envelope and initializes incremental preparation.
Neither `New` nor `Plan` scans the graph. They return without traversing node
or edge arrays, regardless of graph size. Invalid envelopes/options return
`nil, reason`; invalid declarations are reported as terminal `invalid` by a job.

Preparation validates and copies one node or edge per work unit inside `Step`,
using the same slice, cumulative CPU and elapsed limits as search. Array density
is established during that pass; no separate `DenseArray` scan is hidden before
the job. A completed planner owns one reusable index. Later requests and
invalidation reuse it; cancellation/budget exhaustion preserve partial work.
An invalid graph is retained as a diagnosed failure, without repeated validation.

**Input ownership:** keep the source graph and its declarations read-only until
preparation completes. Incremental preparation cannot take an instantaneous
snapshot of the whole graph. Once ready, the independent compiled copy allows
the source tables to be discarded or edited without affecting this planner.
Create a new planner to install different graph data.

IDs are nonempty semantic strings;
nodes and edges are dense arrays and edge IDs are unique. Numeric client API IDs
are not graph keys. `seconds` must be a finite nonnegative estimate including
all relevant approach, mode change, wait, transport/cast, loading and final
movement costs. This slice consumes the estimate supplied by its caller; it
does not invent missing observations.

`access` is `available` (default), `unavailable` or `unknown`. Known usable
travel always takes priority over uncertain travel. `complete` is required:
true certifies that this graph covers the request's entire modeled domain;
false prevents a disconnected search from claiming proven absence. This flag
does not imply real-world coverage. The caller must supply the right domain.

`Plan({from, to, via})` captures a request in at most 65 table visits and returns
a job, including for an invalid request (terminal `invalid`). Graph references
in the captured request are validated one per work unit after preparation.
`via` is an optional ordered array of at
most 64 mandatory node visits. Consecutive repetitions at the current node are
already satisfied; separated repetitions require revisiting it. Search state
includes progress through these visits, so a cheap bypass cannot skip them.

`job:Step(maxOperations, maxMilliseconds)` advances bounded preparation/search work. Both
arguments are optional: 64 operations and the configured slice limit. The time
argument may reduce but never enlarge that slice. Invalid arguments return
`nil, "invalid_step_budget"` without destroying the job. Heap pops, single-edge
relaxations, declaration validation/copy, request-reference validation, path
reconstruction and path reversal all yield between units.
The limits are cooperative: a unit and measurement/return overhead can exceed
the allowance. Only fixed-size envelope/options checks and bounded request
capture happen outside `Step`.

Default limits are centralized: **1 ms per slice, 100 ms accumulated preparation/search
CPU, 5000 ms elapsed since Plan**. `clock` returns seconds and `profileClock`
returns milliseconds. Idle intervals between slices are not charged to CPU.
A missing, throwing, nonfinite or regressing clock stops with `unknown`; no
timer is reset. Host clocks must be cheap and must not recursively step the
same job. Cancellation/replacement during clock sampling is handled.

`job:GetResult()` observes the latest state. `job:Cancel()` is idempotent and
stops an unfinished job. A terminal job never restarts itself. `planner:Invalidate()`
invalidates its revision; any subsequent `Step` on an older job returns `stale`.
`planner:IsCurrent(result)` checks complete-result ownership and revision.
Independent jobs on one planner may coexist; APR retains only its newest one.
The planner keeps no result cache or collection of completed jobs.

Results are caller-read-only tables. They retain `objective`, `revision` and
`diagnostics`: operations, slices, prepared nodes/edges, expanded nodes, relaxed
edges, CPU/elapsed milliseconds and preparation/search phase. Preparation counts
are per job, so a subsequent request using the ready index reports zero.
The opaque `owner` token is only for ownership
checks; do not display, persist or change it. Terminal states:

| status | meaning |
| --- | --- |
| `complete` | A usable itinerary. Normally minimum estimated time through all visits with `optimal=true`. An explicit prerequisite approach has `unlock`, `optimal=false`, `estimateScope='unlock_approach'`; it has not reached the original destination. |
| `no_path` | Complete modeled domain proves disconnection, even allowing uncertain edges. |
| `unknown` | Incomplete domain, a necessary uncertain edge, unavailable/regressing clock or cost overflow. No usable itinerary is asserted. |
| `cancelled` | Explicit cancellation. |
| `budget_exceeded` | CPU or elapsed budget stopped the search; never a proof of absence. |
| `stale` | Planner revision was invalidated. |
| `invalid` | Invalid graph or request. |

Nonterminal state is `running`. A status has a stable machine `reason`; no
user-facing text is generated. Internal IDs and technical diagnostics must not
be rendered as titles, messages or tooltips. No coordinates enter this slice.

## APR opt-in demonstration

The TOC includes `LibAPRNavigation.xml`, loading the three pure modules into the
addon's loader namespace, then loads
`NavigationV2.lua` after the existing navigation module. No LibStub, event,
timer, SavedVariables or default-engine override is installed by the V2 host.

With the `graph` above supplied from a developer addon/test:

```lua
local host = APR.NavigationV2
assert(host:Enable(graph)) -- explicit; GetTime / debugprofilestop are the defaults
host:Plan({ from = "departure", to = "destination", via = { "passage" } }, stepContext)
local result = host:Step() -- schedule later calls only while status == "running"
-- host:GetResult(), host:Invalidate(), host:Cancel(), host:Disable()
```

An optional APR step context is checked through `APR:IsStepContextCurrent`
before/after work and on result observation. Replacing a request cancels the old
job; superseded work is rejected before publication. Invalidation stops the
current request without re-planning. The host retains only one request/result.
`Enable(graph, options)` also accepts explicit clocks/budgets; a failed enable
leaves an existing host intact. Accepting the envelope starts no graph traversal;
declaration validation is deferred to `Step`. Missing APIs reject activation.

This is a planning demonstration, not active guide execution. It neither
publishes waypoints nor advances quests. `APR.navigation` remains the existing
engine even when this separate development host is enabled. It introduces no
user-visible strings, so no translation keys are needed.

Tests: `python -m unittest tests.lua.navigation_v2.test_navigation_v2 -v`.
Actual Retail/Forever loading, timing and gameplay checks have **not** been
performed. API/source evidence and remaining checks are recorded in the NAV-01
report; successful mocks are not an in-game validation.

The optional Personal overlay now evaluates cooldowns at the actual estimated
use epoch, after approach/transport/mode costs. Shared cooldowns and known charge
recharge stay in the same budgeted shortest-path solver; money and items remain
cumulative. Exact bounded waits are explicit actions without waypoints or
automatic use. See [the transport contract](Transports/README.md#future-personal-use-and-explicit-waits)
for observation uncertainty, label dominance, click revalidation and unchanged
committed-attempt semantics. The host remains opt-in and V1 remains default.

## Observed conditions and the first capture boundary

The pure [Conditions contract](Conditions.md) is shared by the same planner.
Optional `requirements` can be attached to the graph, a zone, node, passage or
transport declaration. Simple nodes retain the string form, or use
`{id='gate',zone='hall',requirements={...}}`; zones are
`zones={{id='hall',requirements={...}}}`. Every applicable source/destination,
zone and passage/transport conjunction is checked. Semantic equivalents share
one cached binding even across thousands of nodes. Sector sources can also
carry a global `source.requirements`; compact terrain data is left intact.
Conditional searches cannot use static witnesses/potentials. Access facts and
identity do not add temporal state or a second solver.

Pure callers provide `conditionObservation={sequence,worldState,quests,access,
world,space,floor,phase}` and can use `planner:ObserveConditions` or
`MarkConditionsDirty`. Jobs/results carry a tracker token in addition to their
planner revision; retired tokens never revive. Graph/catalog requirements are
compiled configuration. A new `Enable` replaces that ownership and proof.
`SetScheduled` continues to accept cost changes and unconditional route changes;
changing a conditional route's requirement ownership instead returns
`condition_reconfiguration_requires_enable` atomically, with the old catalogue,
revision and dependency subscriptions preserved.

Native opt-in accepts `observeConditions=true`, `conditionAPI?`,
`conditionIdentity?` and `conditionAccess?`. Preparation remains budgeted and can
discover new required facts after `Plan`. The first job then pauses without
finishing:

```lua
local result = host:Step()
if result.status == 'observation_required' then
    host:ResumeConditions() -- subscribe, capture once, continue this SAME job
end
-- Continue Step later while running. No unchanged replacement Plan is needed.
```

The corresponding pure API is `deferConditions=true` and
`job:ContinueConditions(freshSnapshot)`. The original objective, preparation,
CPU and elapsed budgets survive the continuation. A captured nil/error/secret
fact is an attempted observation, not another dependency request. `Step` and
`GetResult` never query quest APIs or register native listeners.

The existing host event owner coalesces relevant quest/phase dirty bursts and
retires old output/actions immediately. `ResumeConditions` consumes a dirty
burst once, restoring an identical fresh proof through one new plan from the
confirmed Journey. `SetConditionIdentity` and `SetConditionAccess` replace
explicit trusted evidence. Without a confirmed origin, one held
`unknown/location_unknown` result retains the objective/visits; unchanged Resume
calls do not recapture or replan. A new relevant event/proof or trusted request
can recover it. Unrequired facts do not schedule work. No map/Z/phase-reason
inference is used. `UNIT_PHASE`
revokes phase and access proof; loading revokes identity/access and the old
Journey origin. Reconfiguration/Disable discard the source. Hardware use
revalidates facts and preserves only an already committed immutable travel
receipt, never an old itinerary. Native timing, proof lifetime and combat/taint
still require in-game verification before rollout.

## Simple prerequisites as a last resort (NAV-17)

`options.unlocks` is an optional dense array of at most64 explicit declarations:

```lua
unlocks = {{
    id = 'speak-keeper', destination = 'garden', node = 'keeper',
    title = localizedPrerequisiteTitle,
    opens = {access = {{key = 'garden-open', allowed = true}}},
    requirements = {quests = {{questID = knownEligibilityQuestID, completed = true}}},
}}
```

These names illustrate a schema, not a shipped world quest/access declaration.
`destination` explicitly declares applicability to the requested final node.
`node` identifies the concrete prerequisite location. `opens` is exactly one
positive access fact or one completed-character-quest fact, using the existing
Conditions schema. `requirements` is an optional currently observed eligibility
conjunction. Titles must be localized text accepted by the existing coordinate
filter. No new localization key, phase inference or native API is introduced.

The original request always runs first. Even a very expensive usable route
wins. Only proven absence on complete known coverage can select a declaration
whose positive gate fact is the sole known refusal among the traversal requirements.
The fact may belong to a conjunction with other observed satisfied requirements;
an independent refusal or unknown fact cannot justify this simple prerequisite. Missing
entries, unrelated gates, unknown eligibility or unknown access do not authorize
an unlock. `diagnostics.unlockReason` explains refusal, including
`absence_unproven`, `no_simple_unlock`, `unlock_eligibility_unknown`,
`unlock_eligibility_denied` and `ambiguous_unlock`. Multiple eligible declarations
are deliberately ambiguous; chains and comparative alternatives belong to NAV18.
No hypothetical access is installed. The authored destination relation is trusted
data, not a guarantee that all future conditions will remain unchanged.

The SAME job then searches the prerequisite approach with the SAME preparation,
operations, monotonic clocks, slice/CPU/elapsed budgets and cancellation owner.
An incomplete/unknown/budget/stale/cancelled approach exposes no executable
unlock. A successful approach has `status='complete'`, `optimal=false`,
`reason='prerequisite_approach'`, `estimateScope='unlock_approach'`,
`unlock={id,node,title}` and `travelObjective`. `objective` remains the original
request. `estimatedSeconds` covers only the actual approach; it does not pretend
to price the future prerequisite or a completed journey to the destination.

Explicit `StartTravel` creates guidance through the existing lib-owned WUI/AWP
session. At the prerequisite it returns a text-only `kind='unlock'` action with
`reason='unlock_proof_required'`. Marker arrival cannot complete a quest or
change an access fact. No position is fabricated for an unlocalized action.

Journey retains the original objective/ordered visit cursor and confirmed node.
`OriginalRequest()` returns the remaining original request; `RemainingRequest()`
exposes the active concrete subobjective when applicable. `planner:PlanJourney`
and the host's internal continuation preserve this same Journey on changed
conditions, costs and correlated transport arrivals, always checking the normal
destination first. `planner:ResumeUnlock(journey)` and `host:ResumeUnlock()`
resume only after positive actual evidence newer than the denial and from a
confirmed current node. `ResumeConditions` uses that boundary for an active
prerequisite. An unknown origin holds without reusing the original departure.

A genuinely useful revision can make a normal route usable while the selected
gate stays closed. One bounded reconsideration restores that normal route's
priority, retaining APR progress and visits. A dirty burst with identical proof
can recover an interrupted approach once, but cannot repeatedly replan from the
prerequisite. Pure `routeRevision` distinguishes effective routing changes from
condition-token retirement/recovery; ordinary stale-result checks still use the
full planner revision and condition token. Unchanged captures do not loop.

The selected prerequisite owns its supporting proof. Its captured dependencies
are registered incrementally inside the same job budgets; observation of a real
support change retires old jobs/results and guidance even when the whole
conjunction stays denied and its Conditions token stays unchanged. A fresh
identical capture preserves eligibility. Lost support discards the obsolete
subobjective during reconsideration while retaining the original goal and visits.
This proves only the current selection/approach, not a future itinerary or time
to complete the prerequisite.

No real prerequisites have been fabricated. Trusted access proof producers,
quest-history readiness, physical arrival, UI rendering and combat/taint still
require both clients' in-game validation before an engine switch. V1 stays default.

## Optional host calibration (NAV-19 integration)

`Enable(graph,{calibration={client='Forever',build=publicBuild,
computer=explicitInstallationKey,api=optionalApi}, ...})` captures the public
character GUID once and binds the existing catalogues' adjustable fields.
Retail uses `client='Retail'`. Omit calibration to retain existing behavior;
there is no invented native PC identity or extra frame/ticker. Read
[Calibration.md](Calibration.md) for the frozen model, storage schema and policy.

The host exposes `GetCalibrationCost(key)`, `GetCalibrationStats()`,
`SetCalibrationCost(key,secondsOrNil)` and
`ResetCalibrationCosts(keyOrNil,'manual'|'measured'|'all')` (default all).
Readable keys use `portal/<id>/loading`, `personal/<id>/loading`,
`taxi/<id>/ride|loading` or `scheduled/<id>/ride|loading`. Fixed use duration,
fare, approach/boarding/disembark/final costs, observations, requirements and
timetables remain captured from their existing sources. Re-enable to bind a
new catalogue/identity. Persistence copies only `navigationV2Costs` under the
existing `APRNavigationCharacterSettings`; unsupported future storage is not
overwritten. Masked/equal measurements can persist without changing a price.

Actual accepted execution receipts govern measurements: portal use, committed
personal use, taxi boarding and scheduled departure. Scheduled destination
marks the ride end, but only confirmed disembark accepts its measurement.
Ride excludes observed loading and disembark time. The existing world observer
forwards leaving/entering pairs; entry only ends loading. Login/reload, unknown
entry flags, logout, timeout, cancellation, replacement or lost correlation
reject the sample. The accepted receipt/attempt and deadline remain immutable.
The previous full elapsed taxi-duration update is suppressed for a calibrated
attempt, and remains available when calibration is off.

`ApplyCalibrationCosts(recover)` consumes the frozen adapter's numeric Pending
payloads through existing setters, acknowledges successful installation and
coalesces a batch into one revision. Committed transport defers new prices;
arrival applies them and replans the same original Journey/visits/unlock from
the confirmed node once. `ResumeCalibration()` is that explicit recovery seam.
An external replacement cancels the old sample and installs deferred prices
before searching. No pending numeric change means no revision or search.
Step/GetResult/relaxation perform no calibration capture or persistence. Source
and synthetic contracts do not certify native performance or game/taint behavior.
