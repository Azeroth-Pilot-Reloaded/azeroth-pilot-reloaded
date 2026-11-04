# Retail movement

`NavigationV2Retail.New(observation, settings)` is a pure cost/access profile for
the existing V2 search. `LibAPRNavigationV2.NewRetailMovement` exposes the same
constructor. Forever keeps its own profile and level contract.

The observation distinguishes collected/usable mount capability
(`mountOwned`, `mountUsable`, `skyridingOwned`, `skyridingUsable`), permission at
the current departure (`canMountHere`, `canSkyridingHere`) and `initialMode`
(`walk`, `mount`, `swim`, `skyriding`). Booleans may be absent when unknown.
Loading discards movement evidence. No Retail level40 threshold is inferred.

An admitted movement declaration has a mode and nonnegative `distance` in yards.
For skyriding this is horizontal distance; optional nonnegative `rise` and `fall`
are supplied metrics, never inferred from an absent height. `canMount` and
`canFly` are available/unavailable/unknown constraints. Explicit skyriding means
an admitted model connection; omitted `canFly` adds no additional restriction.
Omitted `canMount` leaves a future mounting transition unknown, as in Forever.
`groundOnly=true` prohibits flight. `requiresExit=true` marks an attempted local
connector across a mandatory boundary and prohibits that connector; the actual
declared exit must be a separate edge. The data owner preserves world/region,
space, access, direction and passage topology before admitting such an edge.

The model estimates `distance/skyridingSpeed + rise/climbSpeed + fall/descentSpeed`.
Defaults are60/15/45yards/s. Ground defaults are7yards/s walking,14mounted,
4.7swimming. Mounting is3s; dismounting and landing are0s estimates; swim entry
and exit are0.75s each. All values are explicit configurable assumptions, not
measurements or guaranteed future performance. A setting of `false` means
unknown. Native instantaneous gliding speed never calibrates these values.

`NavigationV2Movement.Capture` chooses Retail using APR's client family. Its
native reads run at capture boundaries, never inside search Step/GetResult.
It feature-detects optional APIs and rejects errors, nil and secret values.
Collected dragonriding IDs plus positive usability establish a usable mount
candidate; negative local usability never becomes a global future-world denial.
Current flight permission additionally needs IsAdvancedFlyableArea and a known
outdoor state. Gliding is called mounted skyriding only with a collected active
journal mount. IsDragonridingUnlocked is not used as a universal flight gate:
Blizzard documents that function as unlocking flight-style switching.

Sources checked through Context7 and Blizzard-generated API documentation:
[MountJournal](https://raw.githubusercontent.com/Gethe/wow-ui-source/11.2.7/Interface/AddOns/Blizzard_APIDocumentationGenerated/MountJournalDocumentation.lua),
[PlayerInfo](https://raw.githubusercontent.com/Gethe/wow-ui-source/11.2.7/Interface/AddOns/Blizzard_APIDocumentationGenerated/PlayerInfoDocumentation.lua),
[PlayerScript](https://raw.githubusercontent.com/Gethe/wow-ui-source/11.2.7/Interface/AddOns/Blizzard_APIDocumentationGenerated/PlayerScriptDocumentation.lua),
and the same generated documents in the current live/forever branches. The
GetCollectedDragonridingMounts/GetMountUsabilityByID/GetGlidingInfo/
IsAdvancedFlyableArea/IsIndoors signatures were also inspected in12.0.0,12.0.1,
12.0.5,12.0.7,12.1.0 and12.1.5. Documentation compatibility is distinct from native
operation, event timing, mount execution and taint, which these fixtures cannot
certify.

Planner:SetMovement compares owned profile snapshots and invalidates previous
jobs. The existing host observes mount display/usability/inventory changes;
additional native changes of flight permission within one map require a fresh
capture. This unit does not add event subscriptions or automatic mount actions.
