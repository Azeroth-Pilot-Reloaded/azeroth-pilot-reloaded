# LibAPRNavigation-1.0

An embedded, rendering-free Lua 5.1 travel planner. Load `LibAPRNavigation.xml`
after LibStub. The library does not access APR, AceLocale, frames, SavedVariables,
protected actions or WoW globals. Each consumer supplies an environment and owns
its character observations. Two consumers can plan concurrently without sharing
their position caches, resources or searches.

## Ownership

| Location | Responsibility |
| --- | --- |
| `Core.lua` | LibStub registration, declarative data validation, independent instances |
| `Locales.lua` | Complete navigation wording for all 11 client languages, with enGB/ptPT aliases |
| `Diagnostics.lua` | Localized, structured explanations of blocked access without host UI dependencies |
| `Geography.lua` | Map projection, access regions, legal free movement, names through the environment |
| `Conditions.lua` | Availability predicates; missing answers remain unknown |
| `Entrances.lua` | Native instance identities and verified exterior approaches; no guessed interior landings |
| `Catalog.lua` | Character-specific transport edges, instructions and cumulative resources |
| `TravelActions.lua` | Shared route actions and item cast effects for inn, Dalaran and garrison hearthstones |
| `Search.lua` | Incremental Dijkstra, binary heap and non-dominated time/money/resource labels |
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

A permitted direct walk bounds the useful alternatives by its total time.
`walkingIsTransitive = true` also lets search omit endpoints belonging only to
slower transports. Use this flag only when permission to walk from A to B and
from B to C guarantees permission from A to C, as `navigator:CanWalk` does.
The built-in walking rule already has this property. Other custom predicates
retain those endpoints because they may serve as required walking bridges.
Actions usable only after moving also preserve their possible departure points;
an action already usable at the start needs no detour to reach its fixed target.

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
| `getAreaName(areaID)` | Localized subzone/area name |
| `mapToWorld(uiMapID, x, y)` | `instanceID, worldX, worldY` |
| `worldToMap(instanceID, x, y, hint)` | `uiMapID` |
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
