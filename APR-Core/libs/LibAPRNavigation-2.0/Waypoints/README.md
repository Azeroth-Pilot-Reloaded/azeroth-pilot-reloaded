# Optional Waypoint UI output

The planner remains pure Lua and never creates an output session. WUI output is
an explicit execution boundary, independent of graph construction and search:

```lua
local session = Navigation.NewWaypointSession({
    getProvider = function() return WaypointUIAPI and WaypointUIAPI.Navigation end,
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
