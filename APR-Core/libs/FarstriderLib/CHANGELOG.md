# Changelog

## 1.4.2

### Changes
- Added support for Interface 11509 (Classic Era 1.15.9)

## 1.4.1

### Fixes
- Restored faction restrictions on travel connections: a 12.0.7 data format change (PlayerCondition `RaceMask` split into `RaceMasks_0/1`) silently dropped all faction gates from the generated waypoint graph, routing Alliance characters through Horde-only transports such as the Grom'gol/Undercity zeppelins (#1)
- Horde-only portals whose faction requirement is only expressed via ModifierTree data (Ruins of Lordaeron and Tirisfal Glades portal networks) are now correctly gated as well (#1)

### Changes
- Added support for Interface 20506

## 1.4.0

### Added
- Added a Silvermoon City portal connection to the Stormwind portal room for Alliance characters

### Fixes
- Item travel connections now defer to the game's own toy usability check (`C_ToyBox.IsToyUsable`), so engineering-gated toys (Wormhole Generators, Dimensional Rippers, Ultrasafe Transporters) are no longer suggested to characters lacking the required profession or specialization
- The Mobile Telemancy Beacon item connection is now restricted to Suramar, where the item can actually be used, so it is no longer suggested elsewhere

### Changes
- Added 12.0.7 entries

## 1.3.3

### Changes
- Added support for Interface 120007

## 1.3.2

### Changes
- Added support for Interface 50504

## 1.3.1

### Changes
- Updated for TBC Phase 2

## 1.3.0

### Added
- Added `ContinentMapOverrides` config: allows remapping a zone's detected continent root to a different continent for pathfinding purposes (e.g. Quel'Thalas → Eastern Kingdoms)

### Changes
- Replaced `IgnoredMaps` default config entry with `ContinentMapOverrides`
- Replaced `IsolatedZones` default config entry with `IsolatedContinents`
- `HasDirectFlyPath` now uses `IsolatedContinents` config instead of a hardcoded Khaz Algar map ID check

## 1.2.1

### Improvements
- Better handling of Wizard's Sanctum check

## 1.2.0

### Fixes
- `FindClosestNavConnections` now respects `noAutoconnect` on target nodes, preventing virtual start/goal nodes from creating TRAVEL edges to isolated portal exits
- Flightpath step pins now point to the departure flightmaster instead of the destination
- Wizard's Sanctum interior nodes (flag 0x40) are now isolated in the nav graph, preventing incorrect auto-connections to exterior Stormwind nodes
- Direct fly-path shortcut is suppressed when the player is inside the Wizard's Sanctum, forcing the pathfinder to route through the exit door

## 1.1.0

### Changes
- Introduced `FarstriderLib_API` as a stable, versioned public API surface
- Added `FarstriderLib~Data.lua` proxy layer with metatable-based access to `FarstriderLibData_API` and safe defaults when data is absent
- Replaced all direct `FarstriderLibData` global access in pathfinding and core with `FarstriderLib.Data.CONFIG.*`
- Moved version guard check from `_G.FarstriderLib` to `FarstriderLib_API`
- Removed named global frame identifiers from the logger UI

### Improvements
- Added `Pathfinding:Rebuild()` for cache-clearing re-initialization after data updates

## 1.0.3

### Initial release
