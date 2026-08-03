# FarstriderLib Data

**FarstriderLib Data** is an optional standalone dependency package for FarstriderLib.

It contains the generated navigation datasets and configuration required by the library's pathfinding engine.

### What This Package Contains

* Area data used by the navigation graph
* Waypoint graph data and generated connections
* Map configuration overrides such as elevation and isolated-area handling
* Localized data used by the navigation system

### Who Should Install This

* Install this package together with **FarstriderLib** only when using standalone packages.
* If a dependent addon already embeds FarstriderLibData, this package is optional and does not need to be installed separately.

### What This Package Does Not Do

* No UI
* No slash commands
* No standalone player-facing functionality without FarstriderLib

### Installation

For standalone dependency installs only:

1. Install **FarstriderLib**.
2. Install **FarstriderLib Data**.
3. Install and enable any addon that depends on them.

Keeping FarstriderLib and FarstriderLib Data on matching versions is recommended.

### Support and Feedback

For support, bug reports, or integration feedback, join the community on [Discord](https://discord.gg/TrJFGcah7z).
