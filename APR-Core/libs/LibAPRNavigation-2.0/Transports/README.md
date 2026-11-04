# Observed transports

Portals are optional authored data, not inferred connections. No live portal
catalogue or provenance is invented here. Data tickets must supply client-specific
declarations and sources before rollout. V1 remains the active default.

`Library.New(graph, options)` accepts `portals` (dense array, at most256) and an
optional `portalObservation`. Each portal declares `id`, graph node `from`/`to`,
optional origin `phase`, `destination={space,phase?}`, nonnegative finite `waitSeconds`,
`useSeconds`, `loadingSeconds`, positive `timeoutSeconds`, optional `name` and
optional real `entry={mapID,x,y}` with normalized map coordinates. Graph node IDs
must describe distinct localized world/floor/phase nodes; proximity creates no
edge. Approach/final movement remains the surrounding graph's edges, charged
once. Waiting, use and loading are charged by the portal edge. Positions are
technical data; names pass the shared coordinate-free text boundary.

Observations have `{revision,phase,portals={[id]={open,access}}}`. A known phase
mismatch against a declared constraint, closed portal or denied access blocks the arc.
Missing required phase/open/access is unknown. An undeclared phase needs no
observation and is never assigned a default. A known route wins over an unknown candidate. Missing observations
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
needs `reliable=true` and an exact localized node; a declared portal origin phase
also needs matching evidence. After BeginUse, completion requires all of:

- a fresh reliable location at the portal's exact destination node and space,
  matching its phase when declared;
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
`scheduledOverrides` holds manual per-id cost/wait settings. Stops require native
`worldID` and a localized `id`; `floorID` and `phaseID` constrain the stop only
when declared. A missing expected constraint cannot confirm a stop; an extra
observed floor/phase imposes no new condition on an unconstrained stop. No floor
zero or default phase is synthesized. Sequence, attempt, vehicle state, departure
and confirmed disembarkation remain necessary throughout execution. The route's own
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
real Disable/re-enable gap start unknown. The host subscribes to world events
before one supported native IsPlayerInWorld readiness probe. Missing/restricted
readiness stays unknown until fresh evidence; it is never inferred from login,
coordinates or elapsed time. ObserveWorld while disabled is rejected. Readiness
alone cannot establish a graph node, floor, phase or arrival. Tests' supplied
ObserveWorld(false) is synthetic evidence, not an in-game validation.

An already-active Enable/EnableSectors replacement preserves continuous world
observation and its current ready/loading/unknown knowledge. Only navigation is
reset after all replacement validation succeeds. A failed replacement preserves
its old plan, action and subscriptions. World listeners are never unregistered
while reconfiguring or switching movement; only the four journal registrations
are removed selectively with the client-verified UnregisterEvent method. A real
Disable cancels execution, unregisters everything and revokes world knowledge.
An entering event missed while disabled is not invented on reactivation: only
the new post-subscription readiness probe or a fresh event can restore readiness.
Active reconfiguration and incidental Plan calls never rerun the Ready probe or
erase observed loading. Optional observePosition/positionExpected world gates
remain separate from both readiness and map projection; World.Match/Project do
not prove physical node membership or geometry coverage.

## Taxi and cumulative resources

`options.taxi` declares directed business routes with readable `id/from/to`,
`origin/destination={id,worldID,floorID,phaseID,taxiNodeID?,title?,position?}`,
`costs={approach,boarding,ride?,loading,disembark,final}` and a positive
`timeoutSeconds`. API node IDs are attributes; slots and localized names never
create a route or stop identity. Approach and final walking arcs participate in
the same search; additional declared components must not duplicate their costs.
No live taxi catalogue is supplied or inferred.

`taxiObservation={revision,nodes={[stopID]={discovered=boolean}},
routes={[routeID]={reachable?,fareCopper?,rideSeconds?}}}` is a bounded copied
snapshot. Missing discovery/reachability/fare is unknown. An explicitly
undiscovered or unreachable destination is unavailable even when its API cost is
zero. `ObserveTaxi` ignores stale/unchanged observations without repeated search.
Manual `taxiSettings.routes[routeID]` costs/fare outrank observations, which
outrank declared costs. Missing ride duration uses `defaultRideSeconds` (default
180 seconds), always positive and marked `costDetail.estimatedRide`.
`SetTaxiCosts(id,costs)` atomically replaces that route's override; `{}` resets it.
Changes invalidate old jobs/results and disable stale bounds/certificates.

`options.resources` and `SetResources` capture named integer balances (`money`
is copper). Graph/transport `resources` maps consume them cumulatively. Missing
quantities are unknown. Snapshots support up to 32 distinct resources; inventory
aliases for one physical resource must be canonicalized before this boundary.
The existing search compares time and cumulative consumption within each
node/ordered visits/movement mode. Each dominance comparison is one budgeted
operation. Static audited adjacency remains usable; dynamic/resource search
never consults stale static potentials or witnesses. Defaults remain 1ms/100ms/5s.

The opt-in host's `observeTaxi=true,taxiAPI?` uses an independent read-only
adapter at activation/planning/consumption and taxi/money event boundaries.
Search, Step and GetResult read no client journal. Both installed clients'
TaxiMap/Unit/PlayerScript/LossOfControl definitions and Blizzard
TaxiFrame/FlightMap/MoneyFrame usage were checked (NAV-11 api-proof.json).
Missing/secret/error results remain unknown. Ambiguous API bindings have no
fallback. Observations live only for this enabled host lifetime, with no
SavedVariables or V1 default changes.

Execution exposes `approach`, `board_taxi`, `awaiting_taxi`, `riding_taxi`, then
the next segment. A missing approach position produces no waypoint or resolver
fallback. `BeginTaxi` rereads the open-map quote, requiring exact business
origin/destination, reachability, expected fare and current money. This only
starts an observation attempt; APR keeps user/secure interactions. No purchase,
TakeTaxiNode, cast, click or protected mutation is performed.

`ObserveTravel` requires a matching opaque attempt and observed boarding, then
off-taxi plus a reliable exact node/stop/world/floor/phase match outside loading.
Host `ObserveTaxiFlight(localization)` adds native on/off-taxi evidence; its
separate localization argument must be genuine trusted evidence. Flight end,
proximity, map availability or entering/loading events cannot prove arrival.
Timeout, failure, context replacement and cancellation are terminal. The Journey
retains its objective/visits and never regains an old origin after boarding.
World/money changes stale plans while committed flights await their proof; a
proven landing requests one fresh remaining plan. Unknown work is not restarted.

Only a proven flight records elapsed boarding-to-confirmed-arrival duration.
It can conservatively include delayed confirmation or in-flight loading; author
additional loading costs accordingly. Manual durations retain priority.
`Host:ResetTaxiDurations` clears calibrations idempotently. Real discovery,
discounts, event timing, destination/floor/phase evidence, combat/taint and native
WUI/AWP behavior require in-game checks on both clients before rollout. The
upstream NAV-03 AWP dismissal gap remains unresolved.

## Personal actions in the same planner

`options.personal` / `personalObservation` register the project-owned Personal
catalogue. Its readable IDs and canonical item/usage keys contribute to the same
resource map as taxi money. Resource fusion replaces only the observer's owned
keys, revokes missing new quantities and validates the complete map atomically.
Known and latent declared keys count toward the32-key limit; exceeding it returns
`resource_limit_exceeded`, preserving the previous state. No balance is truncated.
`ObservePersonal` and `SetPersonalCosts` invalidate old planning results; dynamic
personal arcs also disable static witnesses/potentials while retaining adjacency.

Host native opt-in is `observePersonal=true`, with independent `personalAPI`,
`personalOrigin={node,space,phase?,reliable,indoors?}`, and optional
`personalSettings={allowRare=true}`. Unknown/loading observations stay sparse.
Origin and any observed phase must be genuine supplied evidence; a declared
origin phase stays unknown until observed. Personal `destination={space,phase?}`
always requires space, with phase checked only when declared. A missing expected
arrival phase stays pending; a known incompatible phase is refused. No outdoor check is added unless
authored, and no cave exit or map point is invented. A fresh localized Plan may
supply its trusted source node. Loading revokes old scope. API reads occur at
explicit observation/planning/use boundaries; events mark dirty immediately and
UNIT events filter the player. Step/GetResult/display do not scan inventory.

Personal execution is one bounded captured receipt, independent of new planning
catalogues: canonical declarations/observations, objective/source/destination,
opaque attempt and fixed deadline. `BeginPersonalUse` starts that receipt without
performing a spell/item action. Expected cast/cooldown/loading/resource events
stale future plans while the committed receipt awaits proof. Correlated failure,
incompatible reliable proof, cancellation, objective replacement, Disable or
deadline are terminal. Arrival needs a complete correlated transition and reliable
matching destination outside the host's loading interval. It triggers one new
plan from the confirmed Journey node/remaining mandatory visits, never old legs.

`Host:GetPersonalButton(parent?)` explicitly exposes one reusable APR-owned secure
button for APR to place. Its sanitized `personalButtonLabel` reuses Blizzard USE.
PreClick revalidates current context/result/source and starts the receipt; attributes
remain intact for Blizzard's secure handler. PostClick disarms and shows awaiting.
The host uses explicit key-up handling verified in both installed clients. It
never calls Click/CastSpell/UseItem. Outside combat cancellation disarms immediately;
in combat the adapter's secure guards block stale clicks while protected cleanup
is deferred. Regen drains cleanup before any new action, never restores an old
action, and Disable detaches host scripts when legal. No waypoint is published
for this action. Native cast/use, taint/combat timing and truthful arrival identity
still require real Forever/Retail checks before rollout.

### Future personal use and explicit waits

`Transports/Cooldowns.lua` is a pure arithmetic decision shared by personal
planning and execution. A label's use epoch is the captured planning epoch plus
all preceding leg costs and any required mode transition. A personal edge adds
only the remaining justified wait, followed by use and loading. Its
`costDetail={waitSeconds,useAt,useSeconds,loadingSeconds}` contains exact seconds;
there is no time grid. `Personal:Edge` still reports immediate observed access;
the search uses its cached forecast eligibility after movement evaluation.

One physical ability or authored `cooldownGroup` has one timeline. A noncharged
use starts its declared cooldown at `useAt`. Charged uses consume successive
charges; regeneration is projected only from a positive public recharge duration
with unit playback rate, and a consistent active start when partially depleted.
Missing/secret/rate-uncertain or inconsistent recharge data do not create future
charges. Known current charges remain usable. An exhausted unforecastable group
leaves an explicit unknown possibility, while any known ordinary route can win.
An authored source can be approached; restrictions known only at another source
(space/phase/indoors) remain unknown. No future origin is invented for an
origin-less action.

Money and canonical physical inventory are cumulatively spent by the existing
solver. Renewable group history is compared as future availability, never as a
permanent usage count. Dominance compares the entire remaining recharge sequence,
including whether an earlier arrival can wait until a later label. Past timers
and fully restored queues are removed from label state; unrelated balances never
become state dimensions. `resourcesSpent` still reports all selected edge usage,
including personal uses, during path reconstruction. The32-key resource boundary,
bounded preparation/cache and1ms/100ms/5s budgets are unchanged. Changed forecast
proof invalidates old jobs/results even if raw charge counts did not change.

An explicit travel session may expose `kind='personal',phase='waiting'`,
`instruction='wait_personal'`, `readyAt`, fixed `deadline`, `remainingSeconds` and
sanitized title. APR adds the compatible Blizzard GlobalString
`SPELL_FAILED_NOT_READY` as `message`; no translation key is added. It publishes
no position/waypoint and leaves the secure button disarmed. One cancellable timer
at the fixed wait boundary requests one fresh remaining plan with the same
Journey. It never casts/uses/clicks or resumes old legs. Native facts are recaptured
at planning and at the real hardware click, including when the initial planning
observation was supplied manually. A missing timer API still permits explicit
`RefreshTravel`/`Tick`; it creates no polling loop.

Once `BeginUse` commits, the separate immutable receipt retains its original
attempt, `usedAt` and transition deadline through expected events. The wait clock
does not extend that deadline. Reliable correlated arrival still requires a fresh
remaining plan and cannot advance a quest. Tests cover exact waits, shared
cooldowns, finite/known/unknown recharge, cumulative money/items, invalidation,
90 independently enumerated tiny graphs, real XML/TOC/host/button lifecycle and
obsolete static witnesses. Native timing, truthful arrival, combat/taint and
Forever/Retail gameplay remain unverified before rollout; V1 remains default.
