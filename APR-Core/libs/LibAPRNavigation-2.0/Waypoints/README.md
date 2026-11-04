# Optional waypoint output

The planner remains pure Lua and never creates an output session. WUI output is
an explicit execution boundary, independent of graph construction and search:

```lua
local session = Navigation.NewWaypointSession({
    getProvider = function() return WaypointUIAPI and WaypointUIAPI.Navigation end,
    getAzerothWaypoint = function() return AzerothWaypointNS end, -- optional APR guide provider
    inCombat = function() return InCombatLockdown() == true end,
    canPublish = function() return C_Map.GetUserWaypoint() == nil end,
    defaultTitle = MAP_PIN, -- Blizzard's localized label; otherwise APR
})
session:SetTarget({
    key = "gate-approach", -- stable identity of the active segment/action
    title = "Enter the gate", -- already localized by the host
    position = { mapID = 42, x = 0.23, y = 0.67 }, -- normalized, known projection
    -- iconTexture, iconType, r, g, b, requestRecolor are optional visual metadata
})
session:Refresh() -- on relevant host events, including the end of combat
session:Clear()   -- explicit cancellation; safe to repeat
```

APR's opt-in `NavigationV2:SetTarget(target, stepContext)` creates this session
automatically. `GetWaypointStatus()` exposes a technical status; it is not a
localized error label. `ClearTarget`, `Cancel`, `Invalidate` and `Disable` clean
only the owned marker. The default engine and existing hosts remain unchanged.

The session chooses a compatible Azeroth Waypoint namespace first, then WUI.
It clears its previous output successfully before publishing to the next one;
cleanup failure blocks the handoff. Provider discovery is repeated on host
events, so a late AWP can replace the session's WUI output. A missing provider
retains the target. A dismissed or arrived action stays terminal across provider
changes and title updates until its `key` changes or the host explicitly clears
the target. A native arrival signal is meaningful only for a WUI carrier.

Targets are copied at the boundary. `key` must be a nonempty string. Position
requires an explicit positive integer map ID and finite normalized x/y. A missing
or invalid position reports `unlocated`, keeps the action's identity and creates
no point; this module never guesses a projection or substitutes the player's
position. Invalid target envelopes leave the accepted target intact. Names are
plain text: color/texture escapes are removed, ordinary numbers in names and
instructions are preserved, and coordinate pairs, axis labels, world-map links
or `/way` commands use the localized human fallback title. Only `name` is passed as
visible text, and `stripCoordinates` is always true. Provider errors are contained
and never returned as raw strings containing technical positions.
`suppressPathfinding=true` asks modern WUI to display APR's active segment without
starting its own route calculation, as implemented by its
[navigation provider](https://github.com/Adaptvx/Waypoint-UI/blob/main/Code/Navigation/Navigation_DataProvider.lua).

WUI accepts percentages and returns normalized session data. Calls use its public
`Navigation.NewUserNavigation(options)`, `GetUserNavigation()`,
`IsUserNavigationTracked()` and `ClearUserNavigation(preserveWaypoint,
suppressAdvance)` functions. The unique APR-prefixed `flags` string plus captured
map, position and name identify ownership. All cleanup rechecks ownership and
suppresses WUI's queue advance; native waypoints are preserved when no longer
tracked by this session. Foreign current sessions are not overwritten, and the
stored pin collection is never changed. If output is occupied, the host may retry
on a later waypoint event. No snapshot of another owner's session is restored.
The optional `canPublish` guard protects native markers outside WUI's session;
APR supplies it and refuses publication when that native API is unavailable.

Manual removal or untracking reports `dismissed`; repeated updates of that key
do not reopen it. An observed arrival reports `arrived`, without progressing a
quest or selecting the next action. A different key or explicit `Clear` starts a
new guidance intent. Combat postpones both publication and cleanup, including
after disabling the host. `provider_unavailable` retains its target for late
load; rejected/throwing publication is attempted once per changed target rather
than being retried unchanged. Cleanup errors retain their handle for a later
event-driven retry, always checking that ownership still holds.

The APR host allocates one event frame only when output needs it. It watches
native waypoint/tracking changes, world loading and combat completion. WUI's
public state settles after its own delayed validation, so changes schedule one
cancelable 0.2 second refresh. `ADDON_LOADED` for WUI and world entry permit at
most four such checks for API readiness. There is no `OnUpdate` or ticker. All
events and pending timers are removed at idle, unlocated, dismissed or arrived.
Arrival accepts `NAVIGATION_DESTINATION_REACHED(true)` only outside world loading,
with matching native map/position, an owned tracked WUI session, readable values
and a finite distance in [0, 5]. A loading event alone is never arrival evidence.
Arrival radius and position tolerance are named constants in the output module;
stabilization delay and readiness retry limit are named constants in the APR host.

## API evidence (checked 2026-11-03)

Context7's resolver had no Waypoint UI entry. Its WoW UI source documentation was
consulted for events and timers; provider details were checked directly against
the author's [public API](https://github.com/Adaptvx/Waypoint-UI/blob/main/API.lua)
and [MapPin implementation](https://github.com/Adaptvx/Waypoint-UI/blob/main/Code/MapPin/MapPin.lua).
The provider declares version 1.7.4 for both
[Retail](https://github.com/Adaptvx/Waypoint-UI/blob/main/WaypointUI.toc) and
[Camelot/Forever](https://github.com/Adaptvx/Waypoint-UI/blob/main/WaypointUI_Camelot.toc).
The navigation arrival event and distance API appear in Blizzard's generated
[Retail](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/InGameNavigationDocumentation.lua)
and [Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/InGameNavigationDocumentation.lua)
documentation. Both clients document `C_Timer.NewTimer` in
[Retail](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua)
and [Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua).
Native waypoint inspection is declared in the
[Retail](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua)
and [Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua)
map API contracts. Event frame registration follows Blizzard's
[FrameUtil](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua).
These are source checks, not observed game sessions. Actual rendering, delayed
readiness, native ownership, loading, arrival and combat/taint behavior must be
verified on both supported clients before switching their active engine.

## Azeroth Waypoint APR provider

AWP uses its public dot-call `GetGuideTargetProvider("apr")`,
`RegisterGuideTargetProvider("apr", adapter)`, `GetGuideRouteState("apr")`,
`ScheduleGuideProviderEvaluation("apr", reason)` and
`ClearGuideRouteState("apr")` functions. A compatible namespace must provide all
five. No native or TomTom waypoint is created by this adapter, and no explicit
takeover is requested: AWP retains its own manual and foreign guide authority.
An `active` status means the target is published to the guide provider; it does
not prove that AWP's asynchronous backend has rendered it or reached it.

The bridge copies the native APR adapter's label, icon, tint, size and installed
hook callback. It supplies only the host's captured execution target, preserving
normalized positions, sanitized title/rawTitle/subtext, semanticKind,
semanticQuestID, semanticTravelType, iconHintKind, iconHintQuestID, aprStepKey,
aprQuestIDs, aprTitleSource, aprSubtextSource and liveRouteLegKind. The target
and each extracted snapshot are isolated from caller/provider mutations.
The bridge never extracts a V1 itinerary. Publication errors are bounded to one
attempt per target/provider transition; no unchanged timer retry is added.

Each owned route has a private source identity. Clearing requires both the
registered adapter identity and the route's source identity. Replaced adapters
and foreign records are preserved. `Clear` retains a silent bridge while V2 is
in use, so AWP's existing APR hooks cannot resurrect legacy targets. `Release`
(called by APR `Disable`) safely clears and restores the previous adapter if
ownership still holds. AWP has no unregister operation; if no previous adapter
existed, the bridge remains silent and reusable by the same session.

`Dismiss` / APR `DismissTarget` withdraws this output while keeping the objective
terminal for its current key. Native waypoint arrival never completes an AWP
target or advances an APR quest. The host installs secure post-observers once
per AWP namespace for public route clearing, provider replacement and carrier
recomputation while `IsRoutingEnabled()` reports false. These observers only
suppress a currently owned publication and schedule a cancelable refresh. They
become inert without a publication; no ticker or OnUpdate is installed. Combat
defers provider mutations, including restoration, while local suppression stops
pending guide evaluations from extracting a cancelled target. A public route
clear has no reason parameter: V2 conservatively treats any such withdrawal of
its publication as terminal, including a provider-initiated visibility clear.

## Unresolved AWP carrier-dismissal contract (NAV-03)

AWP 4.1.3 deliberately reasserts live guide carriers after TomTom
`RemoveWaypoint`, `ClearWaypoint` and `RemoveAllWaypoints`. Its public guide API
does not report whether the physical carrier was manually removed or internally
replaced; the internal-removal counter is private. V2 therefore cannot guarantee
sticky manual TomTom dismissal with this API. It does not hook private state,
replace provider functions or pretend that a native waypoint event identifies
this TomTom carrier. `DismissTarget`, public APR route removal and routing-off
are covered separately. This remaining acceptance gap blocks NAV-03 completion
and the engine switches; the opt-in host and V1 default are retained for review.

Context7 resolved `/morningstargg/azerothwaypoint`; the implementation was checked
against upstream commit `6e158359a503a550af001edea9586233a2f63ae7`:
[guide dispatcher](https://github.com/morningstargg/azerothwaypoint/blob/6e158359a503a550af001edea9586233a2f63ae7/bridge/routing/guide.lua),
[APR adapter](https://github.com/morningstargg/azerothwaypoint/blob/6e158359a503a550af001edea9586233a2f63ae7/integrations/guides/apr/apr_provider.lua),
[carrier removal handling](https://github.com/morningstargg/azerothwaypoint/blob/6e158359a503a550af001edea9586233a2f63ae7/bridge/routing/carrier_tomtom.lua),
and [routing controls](https://github.com/morningstargg/azerothwaypoint/blob/6e158359a503a550af001edea9586233a2f63ae7/interface/commands_settings.lua).
The upstream tree declares only a Retail AWP manifest (`120105`); no Forever
support is claimed. Forever retains feature-detected WUI fallback when AWP is
absent or incompatible. WoW timer/event/native APIs were source-checked for both
clients; actual AWP/WUI rendering and combat/taint checks remain unperformed.
