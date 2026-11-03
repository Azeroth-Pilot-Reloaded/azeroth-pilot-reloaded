# Observed transports

Portals are optional authored data, not inferred connections. No live portal
catalogue or provenance is invented here. Data tickets must supply client-specific
declarations and sources before rollout. V1 remains the active default.

`Library.New(graph, options)` accepts `portals` (dense array, at most256) and an
optional `portalObservation`. Each portal declares `id`, graph node `from`/`to`,
origin `phase`, `destination={space,phase}`, nonnegative finite `waitSeconds`,
`useSeconds`, `loadingSeconds`, positive `timeoutSeconds`, optional `name` and
optional real `entry={mapID,x,y}` with normalized map coordinates. Graph node IDs
must describe distinct localized world/floor/phase nodes; proximity creates no
edge. Approach/final movement remains the surrounding graph's edges, charged
once. Waiting, use and loading are charged by the portal edge. Positions are
technical data; names pass the shared coordinate-free text boundary.

Observations have `{revision,phase,portals={[id]={open,access}}}`. A known phase
mismatch, closed portal or denied access blocks the arc. Missing phase/open/access
is unknown. A known route wins over an unknown candidate. Missing observations
cannot prove no path. `planner:ObservePortals(snapshot)` accepts strictly newer
revisions, captures the effective access and invalidates only an actual change.
`planner:SetPortalCosts(id, partialCosts)` accepts the three cost fields above;
manual values take effect directly and invalidate only when changed. Neither
method retries a request itself. The APR host replans its retained objective once
for a changed observation, and does nothing for unchanged/stale snapshots.

Dynamic arcs disable prepared potential estimates, refinement and witness
certificates, even if all portals are currently closed. Existing audited adjacency
pages, cache bounds, lazy loading and the unchanged1ms/100ms/5s budgets remain.
No world scan occurs in New/Plan and no second search engine is used. This does
not make a mutated raw terrain graph match an old adjacency atlas: source edits
still require NAV-07's fresh import audit or omission of the old routing atlas.

`planner:StartTravel(result)` requires a current complete result and creates a
pure lifecycle. `GetAction`, `Observe`, `BeginUse`, `Tick`, `Cancel` return machine
actions for APR. Moving/approach actions identify the mandatory node and supply
the real entry position only where declared. No fake position is generated.
`BeginUse` is APR's explicit user-interaction boundary: it performs no protected
game action. It returns an opaque per-use `attempt` token and absolute deadline.

Travel observations require a fresh positive `sequence`. A movement observation
needs `reliable=true` and an exact localized node; the portal origin also needs
its known phase. After BeginUse, completion requires all of:

- a fresh reliable location at the portal's exact destination node, space and phase;
- `loading` not true;
- `transition={portalId,from,to,complete=true,attempt}` matching the active use.

The observer must derive that proof from actual game evidence; it must not set
confirmed identity from a radius or a world/loading event alone. The library and
host never manufacture it. A missing/wrong/stale arrival stays pending until the
fixed terminal timeout. Same-map portals require an independently corroborated
transition; if the client cannot supply it the conservative result is timeout.
New objectives, cancellation and planner invalidation stop the old lifecycle.

APR explicitly starts through `NavigationV2:StartTravel(result,{resolveTarget},
context)`, then feeds `ObserveTravel` and calls `BeginPortalUse` at its interaction
boundary. `resolveTarget(node,action)` may return a localized normal waypoint
target for a walking node. Missing positions clear output. Planning alone never
publishes. `GetTravelAction` refreshes lifecycle/context; one cancellable timer
handles each portal deadline, with no polling loop. If C_Timer is unavailable,
explicit refresh/Tick still enforces the deadline. Status tokens are technical;
the host must localize any displayed instructions via existing text policy.
Waypoints cannot advance quests.

Native timer signatures were checked via Context7 and Blizzard's generated
[Retail](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua)
and [Classic Era](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua)
API sources. No new native portal API/event is assumed. Real identity observation,
Forever/Retail loading delays, provider rendering, combat and taint remain in-game
switch gates. Synthetic proofs establish contracts, not those client observations.

## Movement and scheduled services

The actual library XML loads `Movement/Forever.lua`, `Scheduled.lua` and the
shared `Actions.lua`; APR.toc loads the observer before the host. The existing
Search remains the only planner. Actions now owns path progression and dispatches
the captured scheduled execution; the portal catalogue contains no second path
lifecycle. No NAV-09/12 source or test was rewritten for this integration.

`Library.NewForeverMovement(observation,settings)` creates the explicit Forever
profile; pass it as `options.movement`. Graph captures each declared `movement`
through its validated boundary. Search includes mode in dominance and parents,
evaluates the selected geometry, and charges a transition once. Segments retain
mode and transitionSeconds. A transport imposes walking and charges any required
descent. A missing initial mode is unknown. `planner:SetMovement(profile)` replaces
a changed captured profile and invalidates old jobs/results; equal profiles do
nothing. No mount/spell action is performed by this code.

`options.scheduled` is an authored array accepted by Scheduled.NewCatalog;
`scheduledOverrides` holds manual per-id cost/wait settings. The route's own
approach/boarding costs are separate from preceding graph edges; authors must not
declare the same movement twice. Each relaxation passes the frozen query epoch
plus the accumulated label cost AND preceding dismount time to Catalog.Edge.
The dismount is then added to edge seconds exactly once. Fixed waits and FIFO
periodic schedules are supported. Unsupported/missing/overflowed costs remain
unknown. Segments retain transportId and costDetail, including actual estimated
wait and departure. `planner:SetScheduled(declarations,overrides)` captures a new
snapshot and invalidates only an actual change. Catalogues/settings/observations
remain fixed for the query; there is no unchanged automatic retry.

Prepared Routing and Sectors currently return terrain seconds without native
movement geometry/mode metadata. Some seconds already include static swimming
changes. With a dynamic movement profile, these edges yield
`movement_metadata_missing`; they are not treated as walking distances, granted
mounted clearance or charged another inferred transition. Plain authored fixed
edges without movement retain the explicit fixed-time walk policy. Terrain mode
metadata requires a later data/generator contract before full Forever movement
can use these prepared terrain edges. No Data/generator file is modified here.

The shared travel API accepts `{objectiveID,scheduledTimeoutSeconds}`. Scheduled
execution has a fixed total deadline from entering that segment (default120s,
explicitly adjustable); waiting does not extend it. Its correlated stop/vehicle
observations are delegated unchanged to Scheduled, including the opaque attempt.
Only confirmed disembarkation resumes the next path segment. The host publishes
only real targets returned by that execution, clears output for nonpositional
phases, cancels one deadline timer on replacement/cancellation, and cannot advance
quests. Walk actions also expose required mode and transitionSeconds for APR's
secure interaction flow.

APR `Enable` accepts the same movement/scheduled options, or explicit Forever
observation opt-in `{observeMovement=true,movementAPI=api,movementSettings=settings}`.
That observer captures at Enable, Plan, explicit ObserveMovement and StartTravel
consumption. Manual settings override observed rates. Step, GetResult and travel
display never rescan the mount journal. Four verified native events
(PLAYER_MOUNT_DISPLAY_CHANGED, PLAYER_LEVEL_UP, MOUNT_JOURNAL_USABILITY_CHANGED,
NEW_MOUNT_ADDED) only mark the snapshot dirty and invalidate once; recapture waits
for a boundary. Loading/swimming or other host-observed changes can explicitly use
ObserveMovement(loading) or MarkMovementDirty. No permanent polling is installed.
A manual SetMovement releases journal registrations; the host keeps world observations until Disable. This
Forever opt-in is not Retail mount eligibility or a client rollout.

`Host:SetMovement`, `SetScheduled`, `SetPortalCosts` stop old execution and reject
stale results when settings change. Movement events do not automatically replan
from a possibly obsolete origin: the caller must localize and Plan a fresh request.
ObservePortals replans once for a changed access observation from confirmed path
progress, removing already visited mandatory nodes. An unconfirmed portal or
scheduled transition cannot provide an origin: output stops, the stale request
retains its goal, and the caller must supply a fresh localized request. The host's
resolver and trusted observations own real localization; this layer never invents
it.

Request localization now lives in a Journey owned by the host request. The host
creates it at an explicitly localized Plan; each replacement Travel uses that
same observation record. Invalidate/StopTravel may cancel guidance without
discarding its confirmed node and completed mandatory visits. BeginUse, a
scheduled transition or a loading/unknown location revokes the node; cancellation
cannot restore objective.from. Only a new confirmed observation or an independently
localized request restores location. An execution restart with unknown/changed
origin is rejected, even if the old result's planner revision still matches.
Explicit Cancel/goal replacement releases the Journey.

The movement observer also registers PLAYER_LEAVING_WORLD/PLAYER_ENTERING_WORLD.
Leaving revokes location and invalidates cached result/execution immediately,
without reading the journal. Captures remain unknown while that native loading
interval is active, including an explicit ObserveMovement(false); entering alone
does not locate the player. The event definitions were verified
in SystemDocumentation from both installed Forever and Retail clients. Scheduled
actions also retain the freshly copied `wait` metadata from GetState: known,
estimated or periodic with numeric seconds/departure/period, without runtime
provenance or a private source lookup.


World observation is owned by the enabled host, independently of an optional
movement source. Its event-only frame always subscribes to entering/leaving when
that native surface is available; four journal events are added only for the
Forever observer. SetMovement cannot remove the world subscription. ObserveWorld
revokes location and invalidates guidance/results for every profile variant. During
loading the host passes `Plan(request,{locationKnown=false})`; this pure constraint
returns unknown/location_unknown with the goal retained and zero preparation or
search operations. Explicit movement and fixed-time graphs receive the same rule.
Entering never restores an old position or output, and Disable unregisters the
world observer. No visual region, interaction handler, OnUpdate or ticker is used.


## Activation and observation gaps

World knowledge has one tri-state value: `worldLoading=true` is observed loading,
`false` is freshly observed ready, and `nil` is unknown. Initial activation and a
real Disable/re-enable gap start unknown. Enable accepts configuration but never
proves readiness; planning then retains the goal as unknown/location_unknown and
SetTarget returns world_unknown without publishing. The caller must first activate
the observer, then supply a genuinely fresh trusted ObserveWorld(false), or receive
PLAYER_ENTERING_WORLD. ObserveWorld while disabled is rejected, because a proof
before an unobserved interval could itself become stale. After readiness, a new
independently localized request may resume immediately; no polling or future-event
wait is required. Production must provide this trustworthy observation source
before rollout; tests' synthetic bootstrap is not native game evidence.

An already-active Enable/EnableSectors replacement preserves continuous world
observation and its current ready/loading/unknown knowledge. Only navigation is
reset after all replacement validation succeeds. A failed replacement preserves
its old plan, action and subscriptions. World listeners are never unregistered
while reconfiguring or switching movement; only the four journal registrations
are removed selectively with the client-verified UnregisterEvent method. A real
Disable cancels execution, unregisters everything and revokes world knowledge.
An entering event missed while disabled is not invented on reactivation: the
state stays unknown until a fresh observation. No native readiness query, login
inference, map non-nil check or elapsed-time guess is used.
