# LibAPRNavigation-1.0

An embedded Lua 5.1 travel planner with optional external waypoint output. Load
`LibAPRNavigation.xml` after LibStub. Planning does not access APR, AceLocale,
frames, SavedVariables, protected actions or WoW globals. Each consumer supplies
an environment and owns its character observations. Two consumers can plan
concurrently without sharing their position caches, resources or searches.
Only waypoint output resolves optional provider globals; environment callbacks
can supply their APIs instead. Manual output and automatic
target synchronization are both available.

`config.WorldInstanceOverrides` declares verified phased world spaces with
identical coordinates (for example Draenor garrisons). `GetWorldInstanceID(id)`
returns their canonical world ID; hosts use it for player/arrow/map observations
as well as projected destinations. This does not remove floor, access or map
isolation rules. Ordinary instances remain separate.

Connections may specify `instructionKey` for a localized interaction that is
more specific than their transport kind. Hidden teleports keep their approach
passages as separate edges rather than directing players through cave walls.

## Ownership

| Location | Responsibility |
| --- | --- |
| `Core.lua` | LibStub registration, declarative data validation, independent instances |
| `Locales.lua` | Complete navigation wording for all 11 client languages, with enGB/ptPT aliases |
| `UnlockRunner.lua`, `Unlocks.lua` | Native access detours, bounded discovery, quest/objective progression and resumable destinations |
| `UnlockLocales.lua` | Independent action wording in all eleven client languages |
| `Diagnostics.lua` | Localized, structured explanations of blocked access without host UI dependencies |
| `Geography.lua` | Map projection, access regions, legal free movement, names through the environment |
| `Conditions.lua` | Availability predicates; missing answers remain unknown |
| `Entrances.lua` | Native instance identities and verified exterior approaches; no guessed interior landings |
| `Catalog.lua` | Character-specific transport edges, instructions and cumulative resources |
| `ZoneRouting.lua` | Indexed preferred zone entrances and direct local unlock guidance |
| `ZoneGraph.lua` | Shared physical region topology, bounded transfer search and live access conditions |
| `TravelActions.lua` | Shared route actions and item cast effects for inn, Dalaran and garrison hearthstones |
| `Search.lua` | Incremental Dijkstra, binary heap and non-dominated time/money/resource labels |
| `WaypointUI.lua` | Shared manual/automatic output, lifecycle, projection, ownership and Waypoint UI fallback |
| `AzerothWaypoint.lua` | Independent guide-provider wrapper, metadata preservation, provider arbitration and combat-safe release |
| `Data/retail/`, `Data/forever/` | Positions, directions, costs and requirements, separated by client and transport type |
| APR `NavigationAdapter.lua` | WoW API access, client locale/names, bind/house observations and character settings |
| APR `integrations/NavigationEntrances.lua` | Lazy compatibility facade over the library entrance registry; contains no coordinates |
| APR `Navigation.lua`, `NavigationTaxi.lua`, `Preview.lua` | Route lifecycle, character taxi knowledge, secure buttons and rendering |
| APR `NavigationPlanner.lua` | One scheduler for preparation, search, optional probes and guidance rows |

No legacy connection-building runtime is loaded. The data notice records the
provenance of retained coordinates; it does not introduce a dependency on the
original navigation engine. The updater preserves this owned library instead of
replacing it with a downloaded dependency.

## API

```lua
local library = LibStub("LibAPRNavigation-1.0")
local navigator = library:New({ profile = "forever", environment = environment })
local build = navigator:CreateEdgeBuild({
    start = start, goal = goal, walkSpeed = 7, clock = millisecondsClock,
})
local buildStatus, edges, coverage = build:Step(32, 1)
-- Resume the build on later frames until buildStatus == "ready".
-- Cancel a stale build before starting another one.
-- Only create the search once the edge build is complete:
if buildStatus ~= "ready" then return end
local search = navigator:CreateSearch({
    start = start, goal = goal, edges = edges,
    budget = moneyInCopper, resources = coverage.resources, walkSpeed = 7,
    canWalk = function(a, b) return navigator:CanWalk(a, b) end,
    walkingIsTransitive = true,
    clock = millisecondsClock,
})
local status, route = search:Step(64, 1)
-- Continue in the caller's scheduler while status == "planning".
-- "ready": route.segments, totalSeconds, totalCopper, resourcesUsed.
-- "no_path": no feasible route; consult coverage.waitingData before displaying an error.
-- search:Cancel() releases pending search state. Each search is independent.
```

`Step` limits both operations and, when a clock is supplied, elapsed milliseconds.
Graph ingestion, resource checks and route reconstruction share that budget.
The default is one millisecond. The scheduler checks the clock between operations;
a synchronous host API call, garbage collection or OS preemption can overrun it.
`BuildEdges` remains available as a synchronous compatibility helper.

Source-free actions have a fixed destination, duration and resource cost. When
one is usable at the initial position, its direct use dominates repeating it
after another leg. The search seeds it once. Actions unavailable initially can
still become usable at later departure maps. Dominance comparisons ignore a
start action's consumed cooldown only when no remaining connection needs that
resource; the final `resourcesUsed` always retains the complete consumption.

APR compares ordinary travel with the full shortest-time search. Every physical
approach, crossing, action cast, loading estimate and arrival leg contributes
its duration in seconds. Personal spells, usable items, physical portal chains
and taxis compete even when an entrance is already reachable on foot. A long
walk to a portal cannot bypass a faster teleport to the same city. No fixed
transport preference or distance penalty overrides that duration comparison.

`HousingMaps` identifies housing maps and their descendants. When the current
objective is outside housing and the native return action is confirmed usable,
`GetHousingExitAction(start, goal)` supplies an immediate escape instruction.
This does not require owning the visited house. Its destination can be absent:
it is guidance for the native return button, never an edge with invented world
coordinates. APR bypasses world-graph preparation while offering this exit,
then resumes normal objective routing from the actual outside arrival. Housing
objectives and unavailable return actions retain ordinary transport comparison.

For generated unlock objectives, APR opts into `CreateZoneRoute(context)` before
preparing the world graph. This access-only policy is also available to other
consumers that explicitly choose `preferZoneAccess = true` in APR's planner.
`config.ZoneRoutes[mapID]` selects a preferred physical connection by ID; the
instance builds `connectionLookup` once at initialization. K'aresh (both native
map IDs) and Undermine currently have listed entrances, inherited by child maps.
The job checks only that connection: a failed condition returns its blocker to
the existing unlock session; a permitted entrance reachable on foot returns the
approach, crossing and arrival directly. Unknown flags remain pending data.
Already being in the destination bypasses its entrance condition. Walkable
objectives within `config.threshold` (2,000 yards by default) return a direct
walking segment without scanning transports. More distant objectives use the
full shortest-time search, including personal teleports, physical portal chains
and taxis, even when both endpoints share a region or map. This optimization
limit stays at the base threshold when skyriding is available; the larger
skyriding proximity threshold only controls authored objective visibility.

This access-only policy prefers the listed entrance. Unlisted zones and
entrances requiring another transport use the shared physical region graph.
Its vertices are walkable access regions, with exact separate vertices for
mandatory passage points; directed portals, boats and passages form its links.
The index is built cooperatively once, reused across objectives and invalidated
with the position cache. Missing geometry is retried separately without scanning
successful records again. Each request checks fresh character flags only on
visited links. A breadth-first search prefers fewer physical transfers, retaining
cheaper later arrivals when needed for the remaining fare. A relaxed pass returns
only blockers on a connected potential itinerary; it never publishes locked links
as guidance. Only the chosen connections are materialized into live route rows.
Parallel direct crossings between the start and goal regions are indexed
separately and compared by their complete walking/crossing/arrival duration.
This avoids choosing a distant neutral boat before a nearby faction zeppelin
merely because its record came first in the Forever catalogue.
The APR adapter keeps this geometry across quest, bag and dialogue refreshes;
readable map-art changes invalidate it, with conservative quest-turn-in refreshes
on clients without map art. Bind and house changes still refresh live navigation
without clearing unrelated static transport coordinates.
Forever uses the same routing, cache, cancellation and rendering code with its
own data and unlock coverage. Without a native map-rectangle API, the APR preview
derives a cacheable parent transform from HBD's same-instance affine conversion.
Different-instance artwork and unavailable map data keep the retryable path.
Run `py -3 tools/validation/benchmark_navigation.py --scenario forever` for the
Alliance/Horde cold/warm zone routes and legacy projection benchmarks.

If the physical graph has no supported route, access-only planning falls back to the general
planner for optional personal travel and taxi networks. Consumers using the
search API directly retain full shortest-time graph competition. APR diagnostic
counters distinguish `NavigationZoneReady`, `NavigationZoneBlocked` and
`NavigationFullGraph`, so residual fallbacks can be identified in captures.
`CreateEdgeBuild({ connectionID = id, ... })` prepares only the indexed connection.

`GetBlockedRouteText(blockers)` returns plain text followed by semantic display
lines (`{ kind, text }`). Kinds are `status`, `spacer`, `passage`, `requirement`
and `operator`; consumers may apply their own appearance to each line. Passages
are separated by blank lines, conditions appear as indented lists, and localized
AND/OR separators preserve nested groups without generated parentheses.

`GetQuestUnlockPlans(blockers)` remains a compatibility API for quest-only
alternatives. Native unlock guidance now lives entirely inside the library:
`Data/*/UnlockRoutes.lua`, `UnlockRunner.lua` and `UnlockLocales.lua`. No APR
route table, route engine, localization service or initialization is required.

```lua
local session = navigator:CreateUnlockSession({
    blockers = blockers, destination = originalGoal, clock = millisecondsClock,
})
-- Call once per scheduler slice, then continue on a later frame.
local status, action, originalGoal = session:Step(64, 1)
-- planning: continue on a later frame.
-- action: route to action.target with the normal travel planner, show
--         action.label, action.gossipOptionIDs, action.npcID and action.useActions.
--         Keep polling; arriving at the coordinate does not complete a quest.
-- waiting_data: wait for client observations or map projection.
-- missing_data: show the missing evidence; do not invent or skip an action.
-- resume: replan to originalGoal, which retains the original map/world/position.
-- cancelled: release the consumer's output.
```

Only pass blockers found on a diagnostic path to the actual destination.
Never publish the relaxed diagnostic path itself as accessible guidance.
`CreateUnlockBuild(blockers, options):Step(operations, milliseconds)` exposes
incremental discovery separately. It returns status, plans and missing data;
alternative expansion is bounded to 64 plans and reports truncation. Steps are
bounded to 4096. Library and host callbacks use the caller's scheduler budget;
a single synchronous client callback can still overrun it.

The environment supplies `isQuestCompleted`, `isQuestActive`,
`isQuestCompletedOnAccount`, `isQuestReadyForTurnIn`,
`isQuestObjectiveCompleted(questID, objectiveIndex)` and optional
`getQuestObjectiveText(questID, objectiveIndex)`, plus the normal character,
geometry and name callbacks. `isQuestAvailable(questID, acceptance)` reports an
actual offer in the current NPC interaction: true when offered, false only when
the matching starter's complete offer list proves absence, and nil outside an
observable interaction. APR implements this using gossip, greeting and quest
detail APIs. A different NPC or a closed dialog cannot prove unavailability.
Return nil for unknown observations. Waypoint
actions also need `getPlayerPosition`. Quest acceptance, every authored objective,
and reward remain separate states; abandonment returns to the observed pickup.
Names and objective descriptions come from the game client. All generic action
wording is owned by the library and packaged in all eleven supported languages.
The library never executes protected interactions or presses buttons.

`session:BeginDetour(blockers, options)` handles an inaccessible unlock target,
then resumes its parent action. It rejects repeated edge identities and depths
over 32. Every nested action shares the frame budget. A live unlock of the
parent passage cancels an unnecessary child immediately. `session:Retry()` lets
the consumer retry discovery after previously missing character/client data
becomes available. `session:Cancel()` releases discovery and child sessions.

Persist `session:ExportState()` in the consumer's own storage and reconstruct it
with `navigator:RestoreUnlockSession(state, options)`. Checkpoints contain only
declarative access evidence and the original destination, never closures or an
APR route key. Restore rechecks live flags instead of trusting a saved cursor.

`GetUnlockRoutes()`, `GetUnlockSources()` and `GetUnlockCoverage()` return detached
catalogue copies. `action.prerequisitesKnown == false` marks non-exhaustive source
knowledge. Every accept action carries `acceptance = { requirements, known,
complete, blockingGaps, advisoryGaps, sources, starterNPCIDs }`. `known` means the
supplied evidence was interpreted; `complete` is a separate exhaustive claim.
Recipe requirements, action requirements and acceptance conditions recursively
resolve before a target is published. An unknown offer permits sourced guidance
when known conditions pass; it never completes acceptance. Semantic gaps and a
negative live offer remain blockers. A positive live offer is direct evidence.

The offline compiler reads Route-generator's pinned ATT, BtW, DB2 and APR data.
BtW's explicit `completed` predicate overrides `upto`: a sourced quest can guide
a hidden tracker, but only the actual client tracker confirms that goal.
Authored positions, objective counters, alternative positions, scenarios and
transport observations remain declarative. Missing actions or positions stay
explicit gaps. An inn hearthstone without a proven binding/arrival is a travel
hint to the next real target, never a fabricated landing.

Non-quest recipes use the same runner: an exact `{ key, value }` goal, ordered
steps, `requirements`, selection-only `availability` and `progressive = true`.
Proven reward quests and NPC activities can progress currency, reputation,
items, toys or other predicates. A reward does not imply the final threshold:
the runner rereads it and chooses another eligible source when necessary.
Exhausted sources and the selected source survive reload; obtaining a reward
cannot cancel a following inventory registration action. Faction/class/race
restrictions select alternatives, and are never treated as obtainable rewards.
Positive reputation gains cannot safely solve an upper-bound deficit.
Renown/friendship native values are distinct from standard reaction ranks.

Additional sources register through `RegisterData` with `unlockRoutes`.
`completeWhen` always describes a client observation. Unknown predicates,
unproven acquisitions and missing Forever data are retained as gaps; Retail
requirements never fill Forever gaps. Generic wording stays in all eleven
library-owned locales, and client APIs provide localized quest/NPC/item names.

The route key, route progress, source routes, custom path and temporary route
engine are untouched during an unlock.

A direct-distance A* heuristic would overestimate routes using
portals; Dijkstra preserves the shortest-time result. Resource labels retain a
slower arrival if it preserves money or reagents needed later. Directed edges
never imply a return route. Consumers must revalidate live offers and actions
before using the resulting itinerary.

Large providers can pass `edgeGroups = { catalogueEdges, taxiEdges }` instead of
copying their arrays into one `edges` array. Keep positions, edges and the walking
predicate stable until a search completes or is cancelled. Walking candidates are
indexed by world instance; a bounded cache reuses legal distances when several
resource labels reach the same node.

Hosts can supply `walkingRegionFor(position)` when walking requires matching
region, access key and floor. Search then partitions its walking candidates by
these properties even with a host `canWalk` callback. APR supplies its geography
region lookup, so disconnected regions in one world never produce pairwise
walking checks. Custom predicates without that contract retain instance buckets.

A permitted direct walk bounds the useful alternatives by its total time.
`walkingIsTransitive = true` also lets search omit endpoints belonging only to
slower transports. Use this flag only when permission to walk from A to B and
from B to C guarantees permission from A to C, as `navigator:CanWalk` does.
The built-in walking rule already has this property. Other custom predicates
retain those endpoints because they may serve as required walking bridges.
Actions usable only after moving also preserve their possible departure points;
an action already usable at the start needs no detour to reach its fixed target.

With transitive walking at a uniform speed, search also skips consecutive
automatic walks: the parent's direct link is already at least as fast. Transport
and action expansion at the arrival point still runs. `walkSpeedAt(position)`
can supply a stable speed per endpoint; search snapshots it once per unique node
and uses the minimum of the two endpoint speeds. It takes precedence over
`walkSpeedFor(from, to)`. Mixed endpoint speeds and arbitrary pair-speed callbacks
retain the full walking graph because intermediate points can improve those
travel times. With incomplete heights, search still checks destinations with Z
when a heightless intermediate point can reduce the vertical cost. Callback
results must stay stable for the lifetime of a search.

Unlock ranking indexes recipes once per session cache, then discovers only the
failed prerequisites reachable from the requested goals. Its monotone AND/OR
worklist handles shared dependencies and cycles without scanning unrelated
campaign actions. Nested detours extend the same map-local graph; observations
and retries invalidate its scores, and cancellation discards an unfinished graph.
The APR host resumes pending discovery on the next frame with a one-millisecond
budget, using 4096 operations with a profiling clock and 64 without one.

Edges with requirements expose `canStart(position, live)`: search uses the planned
departure and its character snapshot; `live = true` refreshes character state for
retained guidance. Results are `true`, `false` or `nil` for unavailable data. A
consumer checks the active departure against the player's position, future
departures against each segment's `from`, and lets a confirmed action finish
before applying departure restrictions again. A pending answer must hide the
action without reporting a final route failure.

Instances also expose `GetProfile`, `GetConfig`, `GetConnections`, `GetBindings`,
`NormalizeLocation`, `GetPositionRegion`, `CanWalk`, `GetDisplayMapName`,
`GetActionUsability`, `GetHelpfulItems` and `InvalidatePositionCache`.
Returned configuration and data belong to that instance. Modify data before
planning and invalidate cached positions after a geometry change.
Each edge build caches repeated quest, spell, item and name queries for that build.

### External waypoint output

Both automatic and manual output are included in `LibAPRNavigation.xml`, without
APR. The library selects [AzerothWaypoint](https://github.com/MorningStarGG/AzerothWaypoint)
when the configured guide provider is available, then falls back to
[Waypoint UI](https://github.com/Adaptvx/Waypoint-UI/blob/main/API.lua).

```lua
local activeTarget
local environment = {
    -- Supply the same world/map projection capabilities used by planning.
    getWaypointTarget = function()
        return activeTarget -- A segment, map/world location, or nil.
    end,
}
local navigator = library:New({
    profile = "retail", environment = environment,
    waypoints = { guideProviderID = "my-guide" },
})
-- Existing guidance updates activeTarget; no waypoint API calls are needed.
```

Use `waypoints = true` for Waypoint UI without a guide-provider identity.
AzerothWaypoint integration decorates an existing registered guide provider with
`guideProviderID`; it preserves that provider's availability, priority, selection,
routing and TomTom carrier. Missing or incomplete registries fall back to Waypoint
UI. For APR the identity is `apr`; other consumers supply their own existing ID.
`waypointUI = true` remains a compatibility alias for automatic output, and
`waypoints = { enabled = false, guideProviderID = ... }` configures manual output.
Planning and diagnostic searches never select an active target implicitly.

Automatic output samples `environment.getWaypointTarget()` every 0.2 seconds.
The optional second return value contains display options and stable `token` and
`context` identities. `guideMode = "override"` publishes this target;
`"fallback"` delegates ordinary objectives to AzerothWaypoint's original extractor;
`"blocked"` suppresses it, including when a target is unavailable. Authored
normalized targets can supply `title`, `subtext`, `source`, `kind`, `guideProvider`
and `transient`. Authored overrides preserve the original extractor's quest
metadata; transient navigation never inherits unrelated objective metadata.

The default scheduler is WoW's `C_Timer.NewTicker`. Other hosts can supply
`environment.newWaypointTicker(interval, callback)` returning an object with
`Cancel()`. Late provider loading and failed target resolution are retried.
`SetWaypointsEnabled(false)` stops automatic output and cleans up its own carrier;
combat cleanup keeps the observer alive until mutation is possible. Reenabling
resamples current guidance. A manually published point remains until explicitly
cleared or replaced. `RefreshWaypoints()` optionally synchronizes immediately,
and `GetWaypointStatus()` returns the last point and reason. The previous
`SetWaypointUIEnabled`, `RefreshWaypointUI` and `GetWaypointUIStatus` names remain
aliases.

Manual callers retain the same API, with the same provider precedence:

```lua
navigator:SetWaypointForSegment(route.segments[activeIndex])
navigator:SetWaypoint({ space = "map", uiMapID = 84, x = 0.5, y = 0.6 }, {
    name = "Destination", subtext = "Optional hint",
})
navigator:ClearWaypoint()
```

Map locations use normalized coordinates from zero to one; world locations use
`instanceID`, `x`, `y` and an optional `uiMapID` hint. World output needs all three
`worldToMap` results: map ID and normalized X/Y. Waypoint UI receives percentages;
AzerothWaypoint receives normalized coordinates. Unsupported native waypoint maps
are projected onto a supported ancestor using child rectangles or world geometry.
`SetWaypointForSegment` selects arrival for walking/same-world passages and
departure for transports. Source-free actions and a nil segment clear output.
The consumer owns arrival detection and its route cursor.

Automatic Waypoint UI output preserves existing player markers, other consumers,
relevant objective tracking, and explicit dismissals until the target identity
changes. Ownership requires the original returned session object, its unique flag
and matching position. Path-step markers are treated as the provider's own carrier.
Cleanup preserves a newer native marker and runs Waypoint UI's normal path cleanup;
no saved pin is created or advanced. Creation and release defer during combat.
A successful manual request overrides automatic publication until guidance changes.

`ReleaseWaypoints()` performs technical cleanup that can be republished;
`ReleaseWaypoints(true)` additionally suppresses the current authored `context`,
including AzerothWaypoint's ordinary-objective fallback, until that context changes.
Use these lifecycle methods for accepted route cancellation and transitions.

APR supplies authored waypoint or accepted transient/retained guidance, current
context, and localized notes through its environment. Its navigation cancellation,
step transition, completed render and profile hooks call this library. Ordinary
quest objectives remain with AzerothWaypoint's native extractor. Hidden APR arrows,
completed quest anchors, explicit positional arrivals and combat cleanup retain
the original integration behavior. APR enables external waypoints automatically
while the addon is active. The library respects Waypoint UI's native APR support
through the configured
`nativeSupportSetting = "APRSupportEnabled"`, without adding another APR adapter.

Missing providers report `waypoint_ui_unavailable`; invalid input or unavailable
projection reports `invalid_position` or `projection_unavailable`. Errors do not
escape the observer. `waypoint_combat` indicates deferred mutation, and
`waypoint_scheduler_unavailable` allows explicit refresh without a ticker.

### Instance entrances

`Data/*/InstanceEntrances.lua` registers entrance metadata independently of the
transport graph. It covers delves, quest scenarios, dungeons and raids. Map IDs,
world `instanceID` and `journalInstanceID` are separate fields; none substitutes
for another. The metadata never supplies an artificial interior centre or an
assumed exit to complete a route.

```lua
local definition = navigator:GetEntranceDefinitionForMap(interiorUiMapID)
-- Read-only metadata, including kind, even while locked or loading.
local entrance, reason = navigator:GetEntranceForMap(interiorUiMapID, character)
if entrance then
    local exteriorGoal = entrance.position -- Normalized world point and access flags.
    -- Plan to this point, then wait for actual interior map/instance evidence.
end
local worldEntry = navigator:GetEntranceForInstance(actualWorldInstanceID, character)
```

`GetEntranceDefinitionsForMap` returns the indexed read-only alternatives;
`GetEntranceDefinitionForMap` returns the first confirmed definition, or a
candidate when only unverified evidence exists. Descendants inherit a known
native identity through bounded, cached ancestry. Missing map information is
retryable. The corresponding `...ForInstance` methods use explicit world IDs
only and never interpret them as UI map IDs.

`GetEntrancesForMap` and `GetEntrancesForInstance` resolve all confirmed,
accessible alternatives. The singular resolving methods choose the closest
exterior in the player's current world when a player position is available,
otherwise the first stable catalogue entry. They do not compare complete
transport itineraries between alternative entrances. `character.position` or
`character.playerPosition` can supply the selection position; otherwise the
optional environment `getPlayerPosition()` is used for multiple alternatives.
The resolver checks requirements live. Failure reasons are `unknown_entrance`,
`candidate`, `requirements_unmet`, `pending_data`, or an invalid requirement
reason. Metadata lookup does not authorize a candidate. `GetEntrances()` returns
a defensive inventory copy, including candidates and their reasons.

An observed cave approach contains its ordered exterior points in `approach`.
The first point stays public; subsequent points and the final exterior goal use
`noAutoconnect=true`. Library construction generates mandatory passage edges
between those points, with distance-based costs and the entrance's requirements.
This makes the complete approach part of the ordinary budgeted search. It does
not grant a straight walk through the cave wall. Preserve `noAutoconnect`, map,
world, floor and access-key metadata when passing a resolved goal to the planner.
Actual arrival checks may ignore the graph-only `noAutoconnect` flag, while still
requiring the real map and access region. No return passage is inferred.

Retail evidence includes entrances from the original continents through TBC,
Wrath, Cataclysm, Pandaria, Draenor, Legion, BFA, Shadowlands, Dragonflight, The
War Within and Midnight. This is not complete game coverage: phase-dependent
portals, opaque scenario/class gates, missing native identities and unknown
exteriors remain candidates or inventory gaps. Native orphan map records are
retained only when an explicit source entrance identifies their interior;
their coordinates are never used as a destination inside the instance.
Forever retains independently identified world instances and exterior points;
the upstream Classic source's fabricated `9001+` dungeon UI maps are excluded.
It can therefore resolve supported world-instance entrances without pretending
those fake maps exist in the client.

Regenerate with `py -3 tools/validation/build_instance_entrances.py`. The offline
report `tools/validation/navigation_data/instance_entrances_review.json` retains
source hashes, review decisions, the migrated APR observations and every
unrepresented native dungeon/orphan map. It explicitly reports
`completeGameCoverage=false`. The legacy zero sentinel maps to verified native
map 2348 (Zekvir's Lair); contradictory old records remain candidates. Runtime
data stores no translated zone names or third-party instruction text.

Portal definitions without `seconds` use `config.actionLoadingSeconds` (five
seconds if unset), plus any explicit `waitSeconds`. Their edges report
`durationSource = "profile-estimated-loading"`. Retail's inherited portal
pathfinding weights have been removed: they were not measured durations.
Explicit `seconds`, including zero, override this estimate and can carry a
`durationSource` such as `measured` or `manual`. Personal spells use the client's
cast duration plus the same loading estimate.

Successful static projections and map ancestry survive across builds until
`InvalidatePositionCache`; dynamic locations and live departure checks do not.

Quest, account quest and achievement alternatives use the same evaluator for
every transport kind. Only explicitly declared alternatives can substitute for
character progress. Account toy ownership or a learned spell still requires
live client usability. Multi-destination actions retain each destination's
discovery conditions.

Map predicates apply at departure, including after earlier journey legs. The
builder tests whether a requirement can hold on a later map without assuming
any quest completion; the search then checks the actual departure. Fixed
transport directions are checked against their own recorded entrances.
See [the unlock audit](../../../tools/validation/navigation_data/README.md#travel-unlock-audit) for data scope and gaps.

## Environment contract

All functions are called without a receiver. Missing optional capabilities make
their corresponding transports unavailable; they never authorize a requirement.

| Function | Result |
| --- | --- |
| `getMapInfo(uiMapID)` | Blizzard-shaped map information, including localized `name`, `parentMapID`, `mapType` |
| `getMapArtID(uiMapID)` | Current map phase artwork ID; `nil` while unavailable |
| `getCurrentMapID()` | Optional lightweight actual player UI map; phase detection otherwise uses `getCharacter().mapID` |
| `getAreaName(areaID)` | Localized subzone/area name |
| `mapToWorld(uiMapID, x, y)` | `instanceID, worldX, worldY` |
| `worldToMap(instanceID, x, y, hint)` | `uiMapID`; also return normalized map X/Y for optional world waypoint output |
| `getWaypointUIAPI()` | Optional late lookup of the full `WaypointUIAPI` table |
| `getAzerothWaypointAPI()` | Optional late lookup of the full `AzerothWaypointNS` namespace |
| `getWaypointTarget()` | Current segment or map/world location; optional display, token, context and guideMode options as the second result |
| `isWaypointCombatLocked()` | Optional combat predicate; defaults to the live client |
| `getNativeWaypoint()`, `isWaypointTrackingRelevant(target)` | Optional native-marker and relevant-objective observations |
| `canSetWaypointOnMap(id)`, `getMapRectOnMap(child, parent)` | Optional waypoint map support and parent rectangle capabilities |
| `newWaypointTicker(interval, callback)` | Optional automatic-output scheduler returning a cancellable ticker; defaults to WoW's `C_Timer.NewTicker` only when enabled |
| `getCharacter()` | `faction`, `level`, `raceID`, `class`, `inGroup`, `mapID`, `indoors`, `inInstance` |
| `getDynamicPosition(kind)` | Current world position for `bind`, `housing`, `housing_exit`; unknown is `nil` |
| `getActionUsability(kind, id)` | `usable, reason`; pending reasons are `pending_data` or `restricted` |
| `getItemCount(itemID)` | Inventory count; `nil` means unavailable |
| `getActionCastSeconds(kind, id)` | Actual client cast duration in seconds; item spells are resolved through the client |
| `getSpellInfo(spellID)` | Spell information, including `castTime` in milliseconds |
| `getItemName(itemID)`, `getSpellName(spellID)` | Localized client names |
| `getLocale()` | Client language code; library wording falls back to enUS for unsupported codes |
| `getQuestName(id)`, `getAchievementName(id)` | Localized client titles; numeric IDs remain available as a fallback |
| `getActionUsabilityIgnoringCooldown(kind, id)` | Optional owned/usable check for displaying an authored UseHS button on cooldown; never used to authorize a navigation edge |
| `random(maximum)` | Optional random integer in `1..maximum`; defaults to Lua's `math.random` |
| `getGlobalText(key)` | Client GlobalString, or `nil` when unavailable; used for named interiors without a UI map |
| `isQuestCompleted(id)`, `isQuestActive(id)`, `hasAura(id)`, `hasToy(id)` | Boolean, or `nil` while unavailable |
| `isQuestCompletedOnAccount(id)` | Account completion for explicitly shared unlocks; Boolean or `nil` |
| `isAchievementCompleted(id)` | Completion including account achievements; Boolean or `nil` |
| `getGarrisonLevel(type)` | Level, or `nil` while unavailable |

The environment must filter secret or otherwise inaccessible client values before
returning them. The library uses conventional world X/Y; APR's historical route
coordinates are converted at the adapter boundary.

`library:GetText(key, locale)` and `navigator:GetText(key)` resolve library-owned
wording. Client GlobalStrings remain useful for proper place names, never as a
replacement for complete navigation instructions. APR retains only its three
calculating/waiting/consult-flight-master messages. French uses informal singular
instructions and ASCII apostrophes. Diagnostics call
`navigator:GetBlockedRouteText(blockedEdges)` and preserve AND/OR/NOT predicates.

The ordinary inn hearthstone has one `selection="random"` alternatives record.
Every option is checked for actual character usability, cooldown and its own
requirements before the uniform draw. Draenei-only options do not restrict the
other alternatives. All ordinary variants share one hearthstone resource.
`navigator:GetHearthstoneAction(ignoreCooldown)` also supports authored UseHS;
the host keeps the selected item stable for that step and observes its actual
client cast spell. Recall scrolls are separate consumable actions with their own
cooldown group and verified level ceiling, so they cannot silently become an
ordinary inn hearthstone at high level.

## Declarative data

Each file has one registration call containing plain tables. No player API calls,
condition callbacks, localized zone strings or executable transport constructors
belong in these files. `Boats`, `Zeppelins`, `Portals`, `Items`, `Spells` and
`Passages` are separate in each profile. `Geography` contains access restrictions
and necessary map overrides. `Bindings` contains area IDs and coordinates only;
names come from `C_Map.GetAreaInfo`, never multilingual alias tables.

```lua
LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "example", {
    connections = {
        {
            id = "documented-crossing", kind = "boat",
            from = { space = "map", uiMapID = 1437, x = 0.0464, y = 0.5716 },
            to = { space = "map", uiMapID = 1439, x = 0.3292, y = 0.3990 },
            seconds = 300, waitSeconds = 60, bidirectional = false,
            requirements = { faction = "Alliance" },
            source = "Replace with the observation/reference for the actual route",
        },
    },
})
```

The example demonstrates the schema, not an additional verified transport.
World positions use `space = "world", instanceID, x, y` with optional `uiMapID`,
`areaID`, `nameGlobal`, `accessKey` and `noAutoconnect`. `nameGlobal` stores a
client GlobalString key, never a translated name. An observed world point may
omit `instanceID` when `uiMapID` is supplied: the client resolves its coordinate
space while preserving the observed X/Y. Dynamic endpoints use
`{ dynamic = "player" }`, `bind`, `housing` or `housing_exit`. Intermediate points
of mandatory passages cannot auto-connect to arbitrary outdoor points.

Requirements support `faction`, `raceID`, `class`, `minLevel`, `maxLevel`, `quest`,
`questAccount`, `questActive`, `questsAny`, `questsAll`, `achievement`, `mapID`, `maps`, `notMaps`, `outdoors`,
`notInstance`, `inGroup`, `housing`, `auraSpellID`, `toyID`,
`mapArt = { mapID = ..., artID = ... }`, and
`garrison = { type = ..., minLevel = ... }`. Compose them using `all`, `any`, or
`notCondition`. Unknown predicate names fail closed.

Retail also supports `phase = { group = "tirisfal", phase = "past" }`,
`holiday = "darkmoon_faire"` and `housingInitiative = { id = initiativeID,
neighborhoodGUID = guid, cycleID = cycleID }` (the latter two identity fields
are optional constraints). All three retain true/false/unknown semantics and
are rechecked on retained edges immediately before departure. A completed
endeavor still exists until its cycle ends; completion alone does not close it.

`config.PhaseGroups` records verified map artworks and unambiguous local map
identities. Two separate maps each reporting their static artwork do not prove
the selected timeline. A verified phase recipe may guide to Zidormi even when
the initial phase is unknown, but only native phase evidence completes that
interaction. `phaseAgnostic=true` is reserved for an observer's approach, where
the NPC exists on both sides; it is not an authorization for a portal.

`config.MapRequirements` applies common access rules to every connection whose
resolved endpoint belongs to the map or a descendant, including personal
teleports, physical region routing and instance approaches. Walking to an absent
map also fails closed. Retain explicit requirements on shared-map phases such
as the Dark Portal and Silithus: their UI map alone cannot identify a timeline.

`environment.isHolidayActive(key)` must return a Boolean or nil. APR reads
native holiday icons and exact start/end times against the server calendar,
including a calendar viewed in another month. Unloaded or restricted calendar
data remains unknown. Sombrelune's entrances and faction-specific return portals
share this gate. The adapter refreshes on calendar, zone and endeavor changes
and checks calendar boundaries while the player stays in a zone.

`environment.getHousingInitiative(departureMapID)` supplies loaded native
initiative/cycle/neighborhood identities for the actual visited neighborhood,
or the selected house while outside. Data for another dashboard neighborhood,
an unloaded response or an expired cycle cannot authorize a link. Do not infer
an initiative from the date, localized title, quest completion or another
neighborhood that uses the same UI map. No initiative portal currently has both
its departure and arrival verified in this catalogue; these rotations remain
excluded rather than acquiring an invented landing. The ordinary home and
return-home actions remain independent of endeavor portals.

The phase map/art pairs and Zidormi approaches were checked against
[the maintained phase records](https://github.com/tr0tsky0/Mapzeroth/blob/main/Data/Modern/Containers.lua)
and the existing local source-fact inventory. Native API contracts are in
[CalendarDocumentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CalendarDocumentation.lua)
and [NeighborhoodInitiativeDocumentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/NeighborhoodInitiativeDocumentation.lua).
The elevator retains the recorded world XY and upper/lower Z already used by
the Forever catalogue, with Retail map identities. Its wait and ride duration
remains an estimate. Public arrivals from Orgrimmar, Grom'gol, Howling Fjord,
old Silvermoon and Teleport: Undercity lead to the exterior near Zidormi.
Story-instance variants and present-courtyard portals with unverified unlock
conditions remain candidates.

Retail smoke checks: start outside Tirisfal in each timeline; take a portal to
the exterior, follow Zidormi guidance, descend the elevator and reach an
underground portal. Repeat upward, with no Z observation and after a reload.
Also switch Darkshore, the Blasted Lands, Silithus, Dustwallow, Uldum and the
Vale; cross a Faire opening/closing boundary; select and visit different
neighborhoods on the same UI map. Arathi's extra modern/warfront variants and
other unverified story phases are not inferred from these two-sided records.

Actions contain `type`, `id`, optional `reagentID`, `reagentCount`, `consumable`,
`groupSpellID` and `groupReagentID`. Mage portal preference is applied among usable
actions in a group. Shared cooldowns use an explicit `cooldownGroup`. The catalog
exports consumed resources alongside the edges, and the search checks their sum.

## Research and validation

The accompanying `../../../tools/validation/navigation_data/README.md` records retained data provenance. APR's navigation
research note compares all nine requested addons and distinguishes inspected
ideas from imported data. No third-party addon UI or runtime is embedded here.

Run the Lua regression suite, script tests, instrumentation check and package
validator from the APR repository. The library suite loads this code with a fake
environment and no APR/WoW globals. Live transport arrivals, secure buttons,
phase restrictions and plot coordinates still require Retail/Forever checks.
The reproducible benchmark and measured limits are documented in
[`NAVIGATION_PERFORMANCE.md`](../../../tools/validation/NAVIGATION_PERFORMANCE.md).
Terrain obstacle avoidance is outside this planner's scope: free segments are
direct lines within an authorized region, connected through mandatory passages.


## Catalogue maintenance and access floors

`Passages.lua` owns physical entrances, exits, tunnels and elevators for each
profile. There is no second entrance provider to merge at runtime. Static names
are resolved by the client; factual records contain no external provenance fields.
Required license notices remain in `NOTICE` and `LICENSE-GPL3`.

`reviewStatus = "candidate"` and `"disabled"` never enter a compiled graph, even
without a separate `disabled` flag. Known height participates in node identity
and ground distance. `arrivalZTolerance` is required for stacked elevator platforms;
unknown height cannot prove arrival. Unknown floors and phases remain maintenance
candidates rather than authorizing a direct XY shortcut.

`dynamic = "camp"` is supplied by the host after observing the character's
successful camp-setting cast. A camp that has not been observed is unavailable.
All action learning, ownership, usability and cooldown checks still apply.

The maintenance inventory traverses all 1,974 input CSV IDs per profile. This is
an evidence inventory, not a statement that every instance, phase and cave is
playable through the catalogue. The reports list unresolved facts explicitly.
