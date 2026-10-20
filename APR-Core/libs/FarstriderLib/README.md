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

### Localization

Navigation instructions live in `Locale/FarstriderLib_Locale.<locale>.lua`,
loaded through `Locale/FarstriderLib_Locales.xml` before the data adapter.
The eleven shipped locales are enUS, deDE, esES, esMX, frFR, itIT, koKR,
ptBR, ruRU, zhCN and zhTW. enGB and unsupported locales use English;
missing translation keys also fall back to English.

FarstriderLibData has its own matching `Locale/` catalogue for generic
instructions, unknown item/spell labels and Forever port names. Its existing
`Waypoints/Standard/` and `Waypoints/Vanilla/` files retain the translations
of named connections. The engine's fallback remains usable without the data
addon. Consumers display the returned `loca` text without translating it again.

When editing generic messages, keep both library catalogues in agreement and
preserve the number/order of `%s` arguments. Run
`python -m unittest tests.lua.test_regressions.LuaRegressionTests.test_farstrider_locale`
from the repository root to check all languages and manifests.

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
