## APR — quick orientation for coding agents

This repository contains a World of Warcraft AddOn (Azeroth Pilot Reloaded). Runtime: Lua + Ace3 (embedded under `libs/`). The goal of this file is to give an AI coding agent or a new contributor a short, actionable orientation so they can start working quickly.

Key locations
- `APR-Core/` — runtime modules and UI frames. Read `Core.lua`, `Config.lua`, `Arrow.lua`, `Party.lua`, `Transport.lua` first.
- `Routes/` and `data/models/` — route files and canonical step models (waypoints, quest-step metadata).
- `locales/` — translations used via `LibStub("AceLocale-3.0")`. Keep translations in these files and update `locales.xml`.

Big picture (very short)
- Global addon object: `APR` (created in `APR-Core/Core.lua` with `AceAddon-3.0`). Modules attach via `APR:NewModule("Name")` and call each other (e.g., `APR.map:UpdateMapLineStyle()`).
- Persistent state: saved-variables (e.g., `APRData`, `APRTaxiNodes`) are created in `Core.lua` and serialized by the game — do not rename these top-level tables.

Developer quick-start (5 steps)
1. Copy repo into your WoW AddOns folder as `Interface/AddOns/APR` or zip the repo root for install.
2. Reload the UI in-game (`/reload`) and use `/apr help` to open the options.
3. Enable debug: toggle debug in the addon's options or set `APR.settings.profile.debug = true` in the saved profile and reload.
4. Trace with `APR:Debug("...")` call sites (search `APR:Debug` — many in `Arrow.lua`, `Party.lua`, `Transport.lua`).
5. For runtime UI changes, use helpers like `ResetPosition`, `RefreshFrameAnchor`, and `UpdateFrameScale` so user settings are preserved.

Conventions & patterns (explicit)
- Module-first code: add functionality as `APR:NewModule("Name")` and use `APR.<module>:Method()`; avoid adding global functions.
- Settings: live in `APR.settings.profile` (AceDB). Defaults are defined in `APR-Core/Config.lua` (`settingsDBDefaults`). Check flags before acting.
- Localization: add keys in `locales/*.lua` and update `locales.xml`. Don't hardcode UI text.
- Saved-variables: never rename top-level tables (e.g., `APRData`), migrations require careful handling.

Integration & communication
- Embedded libs: use `LibStub` to access Ace3 modules. Upgrading embedded libs may change behavior; be cautious.
- Addon messaging: `C_ChatInfo.RegisterAddonMessagePrefix("APRPartyData")` is used for party sync. `APR-Core/Party.lua` fragments messages and reassembles them. Preserve fragmentation and deserialization behavior when editing.

Minimal contract (what to maintain)
- Inputs: route files (Lua tables under `Routes/`), events from the WoW API, saved profiles (`APRData`, `APR.settings`).
- Outputs: UI frames (arrow, quest list), map/minimap lines, outgoing party messages.
- Error handling: code should nil-check route data, missing locales, and saved-variable shapes; prefer graceful fallback.

Edge cases
- Missing or corrupted saved-variables — avoid breaking changes and provide migrations if schema changes.
- Partial/missing message fragments — implement timeouts and safe failure in `APR-Core/Party.lua`.
- Cross-continent/taxi calculations — `Transport.lua` contains helpers; test cross-continent route transitions.

Concrete examples
- Minimal route step schema (example):

```lua
{ id = 12345,
  title = "Kill Mobs",
  type = "kill",
  coord = { 45.3, 12.8, mapID = 123 },
  objective = { mob = 9876, count = 10 }
}
```

- Party message flow (simplified): sender serializes data, splits into fragments, sends with prefix `APRPartyData`. Receiver collects fragments, reassembles, deserializes and updates `APR.party` state. See `APR-Core/Party.lua` for exact fragment/time handling.

Next low-risk tasks I recommend
1) Add `scripts/package.sh`: create a zip ready for `Interface/AddOns/APR` (I can implement this).
2) Add CI: GitHub Action to run `lua -p` on all `.lua` files and optional `luacheck` linting.
3) Triage `//TODO` markers in `APR-Core/` and fix low-risk issues (typos, nil-checks).

If you'd like, I can implement packaging and the CI workflow now, or produce an annotated example of `APR-Core/Party.lua`'s message format and the canonical route step schema. Tell me which and I'll proceed.
## APR — quick orientation for coding agents

This repo is a World of Warcraft AddOn (Azeroth Pilot Reloaded). Core code is Lua and uses Ace3 libs (embedded under `libs/`). Use this file for a fast, actionable orientation.

Key locations
- `APR-Core/` — runtime modules and UI frames. Start with `Core.lua`, `Config.lua`, `Arrow.lua`, `Party.lua`, `Transport.lua`.
- `Routes/` and `data/models/` — route definitions and step models (waypoints, quest-step metadata).
- `locales/` — translations accessed via `LibStub("AceLocale-3.0")`.

Big picture (short)
- Global addon object is `APR` (created in `APR-Core/Core.lua` with AceAddon). Modules attach via `APR:NewModule("Name")`.
- State is persisted to global saved-variables (e.g. `APRData`, `APRTaxiNodes`), created in `Core.lua` and serialized by WoW.
- Interactions: modules call each other (e.g., `APR.map:UpdateMapLineStyle()`); cross-client sync uses `C_ChatInfo.RegisterAddonMessagePrefix` and message fragments in `APR-Core/Party.lua`.

Dev & debug quick-start
- Install for testing: copy repo into your WoW AddOns folder as `Interface/AddOns/APR` (or zip the repo root for an installer).
- In-game commands: `/apr help`, `/apr status`, `/apr route`, etc. See `APR-Core/Config.lua` for the command wiring.
- Enable debug logging: set `APR.settings.profile.debug = true` (via saved profile or options) then reload the UI (in-game). Search the code for `APR:Debug("...")` to find useful trace points (e.g., `APR-Core/Arrow.lua`, `APR-Core/Party.lua`).

Conventions to follow
- Localization: always add keys to `locales/*.lua` and update `locales.xml` instead of raw strings.
- Settings: stored in `APR.settings.profile` (AceDB). Defaults live in `APR-Core/Config.lua` (`settingsDBDefaults`). Check `self.profile.<flag>` before changing runtime behavior.
- UI frames: use provided helpers (`ResetPosition`, `RefreshFrameAnchor`, `UpdateFrameScale`) to preserve user settings.
- Saved-variables: never rename top-level tables like `APRData` — that breaks users' saved profiles.

Integration notes & risks
- The project embeds Ace3 libs; changing them risks behavior differences. Prefer to use `LibStub"` accessors.
- Many TODOs exist in `APR-Core/` (arrow, quest handler, event parsing) and comments in embedded libs — expect work to be split between data (routes) and runtime logic.

Suggested next steps for a tidy-up
1) Polish docs and add a `scripts/package.sh` (zip ready for `Interface/AddOns/APR`).
2) Add a simple CI job to run `lua -p` or `luacheck` on committed Lua files.
3) Triage TODOs in `APR-Core/` and fix low-risk items (typos, nil-checks, small refactors).

If you want, I can: add the packaging script, create a lightweight GitHub Action to syntax-check Lua, or produce a short annotated example of a route file and the Party message format. Tell me which and I'll implement it next.
