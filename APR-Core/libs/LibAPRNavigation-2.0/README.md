# LibAPRNavigation-2.0 — NAV-01

This first slice plans travel through a **supplied synthetic directed graph**.
It does not yet infer terrain connectivity, transport eligibility, cooldowns,
resources or unlock prerequisites. No world data or V1 implementation is loaded.
APR keeps its existing navigation engine active by default.

## Pure Lua 5.1 API

```lua
local namespace = {}
for _, module in ipairs({ "Graph", "Search", "Navigation" }) do
    assert(loadfile("APR-Core/libs/LibAPRNavigation-2.0/" .. module .. ".lua"))("standalone", namespace)
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
| `complete` | Minimum estimated time in the known usable graph, including all required visits. `optimal=true`, `estimatedSeconds`, ordered `segments` and `nodes`. |
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
