# FarstriderLib

**FarstriderLib** is a standalone navigation and pathfinding library for World of Warcraft addons.

It provides the runtime logic used to compute travel paths between map locations, including navigation from the player's current position to a target destination.

### What This Library Provides

* Pathfinding between two explicit map positions
* Navigation from the player's current location to a target
* Travel graph evaluation across routes such as direct travel, flight paths, portals, boats, zeppelins, items, and spells
* Cross-flavor support for Retail and Classic clients

### Public API

```lua
-- Via the versioned API table (recommended)
local optimizedPath, path, edges = FarstriderLib_API.FindTrail(startMapId, startX, startY, 0, goalMapId, endX, endY, 0)
local optimizedPath, path, edges = FarstriderLib_API.FindTrailTo(goalMapId, endX, endY, 0)

-- Re-initialize after data changes
FarstriderLib_API.Rebuild()

-- Access data layer
local waypoints = FarstriderLib_API.DATA.WAYPOINTS
local config    = FarstriderLib_API.DATA.CONFIG
```

The legacy `FarstriderLib.FindTrail` / `FarstriderLib.FindTrailTo` globals still work but will be removed in a future update.

### Dependency

**FarstriderLibData** provides the waypoint graph, map overrides, and supporting navigation data. For standalone installs, it should be installed alongside this library. In embedded addon setups, both packages may already be bundled by the parent addon.

### Who Should Install This

* End users when a dependent addon uses FarstriderLib as a standalone package
* Addon authors who want to embed or depend on a reusable WoW navigation library

### What This Package Does Not Do

* No standalone UI
* No slash commands
* No direct player-facing functionality without a dependent addon

### Installation

For standalone installs:

1. Install **FarstriderLib**.
2. Install **FarstriderLib Data**.
3. Install and enable any addon that depends on them.

### Support and Feedback

For support, bug reports, or integration feedback, join the community on [Discord](https://discord.gg/TrJFGcah7z).
