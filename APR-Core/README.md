# APR-Core: architecture and audit

Audit dated 8 October 2026. Scope: **89 Lua files specific to the core**, 11
localization entries, loaded media, and dependencies. The definitions in
`Routes/` are used to verify consumers; only the author and community metadata for
the EclipseGlaives route were added at the maintainer's request. Changes outside
the core concern the manifest, tests, and validation references required for
travel.

Maintenance principle: **readability, readability, readability**. A helper is
shared when it expresses the same contract for multiple consumers. Window
controllers, subscriptions, and business state remain in their own domain.
Comments explain constraints and side effects; they do not repeat accessor names.

## Loading and data flow

[`APR.toc`](../APR.toc) defines the load order. The folders describe the
responsibilities, not the order itself: a function may reference a module loaded
later as long as it is not called until after initialization.

1. Libraries, Farstrider data selected by client, and AceLocale.
2. `SecretUtils`, creation of the AceAddon `APR` object, skin registry, and taxi adapter.
3. Helpers, visual foundations, route engine, and models.
4. Configuration, events, features, windows, and visual integrations.
5. Registration of client routes, then the AceAddon `OnInitialize` call.
6. Identity, AceDB, and save data, followed by window initialization and subscriptions.

```mermaid
flowchart TD
    Settings[Configuration / AceDB] --> Events[Grouped events]
    Game[WoW API] --> Events
    Routes[Route definitions] --> Engine[RouteManager / DelveRoutes]
    Engine --> Filters[RouteUtils / RouteConditions]
    Filters --> Step[StepUtils: in-memory step]
    Events --> Quest[QuestHandler: pass scheduling]
    Quest --> Renderer[StepRenderer / handlers]
    Renderer --> Transitions[StepTransitions: progression and undo]
    Step --> Quest
    Renderer --> Current[CurrentStep / Rows / Fillers]
    Engine --> Preview[QuestOrderList / Rows / Support]
    Step --> Navigation[Farstrider / Arrow / Map]
    Navigation --> Taxi[LibTaxiData / HereBeDragons]
    Current --> Registry[SkinRegistry / Themes / TextStyles / StatusBars]
    Preview --> Registry
    Registry --> Skins[Native APR / ElvUI / EllesmereUI]
    Engine --> Catalog[RouteCatalog / RouteBrowser]
    Catalog --> Virtual[VirtualList: visible lines]
    Preview --> Virtual
    Transitions --> Diagnostics[Diagnostics / PerformanceDashboard]
```

`GetRouteSteps` builds the effective list: scenarios, parallel groups, and
temporary routes. `GetStep` returns a shallow copy for navigation adjustments.
`GetCurrentStep` resolves the saved progression and shares this copy with the arrow
and events. **Nested tables in a definition remain read-only.**

## File map

### Initialization and configuration

| File                                                               | Responsibility                                                               |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| [core/Core.lua](core/Core.lua)                                     | AceAddon object, identity, saves, and module initialization.                 |
| [core/Event.lua](core/Event.lua)                                   | Events, notification grouping, and deferred callbacks.                       |
| [core/Commands.lua](core/Commands.lua)                             | Routing of `/apr` commands to their modules.                                 |
| [core/Performance.lua](core/Performance.lua)                       | Voluntary capture: aggregates, histograms, slow calls, and bounded counters. |
| [core/VersionCheck.lua](core/VersionCheck.lua)                     | Client/addon versions and group announcements without web requests.          |
| [config/Config.lua](config/Config.lua)                             | AceDB defaults, AceConfig options, profiles, and minimap button.             |
| [config/SettingsIndex.lua](config/SettingsIndex.lua)               | Index of AceConfig options; reuses setters, conditions, and descriptions.    |
| [config/Config_Route.lua](config/Config_Route.lua)                 | Route/catalog notifications and AceConfig entry to the single library.       |
| [config/Config_Route_Prefabs.lua](config/Config_Route_Prefabs.lua) | Predefined routes built from metadata and conditions.                        |
| [config/LevelProfiles.lua](config/LevelProfiles.lua)               | XP bonus data and threshold profiles; no rendering.                          |

### Models

| File                                                                 | Responsibility                                              |
| -------------------------------------------------------------------- | ----------------------------------------------------------- |
| [data/models/Classes.lua](data/models/Classes.lua)                   | Class/specialization IDs and locale-independent route keys. |
| [data/models/Enums.lua](data/models/Enums.lua)                       | Shared clients, categories, expansions, and orders.         |
| [data/models/Quest.lua](data/models/Quest.lua)                       | Priority of primary actions and quest/dialogue rules.       |
| [data/models/Spells.lua](data/models/Spells.lua)                     | Hearthstone item/spell matches, toys, and buffs.            |
| [data/zones/ScenarioEntrances.lua](data/zones/ScenarioEntrances.lua) | Scenario entries for external guidance.                     |

### Features and route engine

| File                                                                                                 | Responsibility and contract                                                                       |
| ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| [features/questing/RouteManager.lua](features/questing/RouteManager.lua)                             | Compatibility, prerequisites, and cache of effective steps; distinct visibility for availability. |
| [features/questing/DelveRoutes.lua](features/questing/DelveRoutes.lua)                               | Delves, scenarios, and insertion/restoration of temporary routes.                                 |
| [features/questing/RouteSuggestions.lua](features/questing/RouteSuggestions.lua)                     | Index of the first quests that trigger a route suggestion.                                        |
| [features/questing/QuestHandler.lua](features/questing/QuestHandler.lua)                             | Batch scheduling, render transaction, and rejection of stale callbacks.                           |
| [features/questing/QuestCache.lua](features/questing/QuestCache.lua)                                 | Journal synchronization and quest event handling.                                                 |
| [features/questing/StepRenderer.lua](features/questing/StepRenderer.lua)                             | Pass orchestration, with priority for existing actions.                                           |
| [features/questing/StepInstructions.lua](features/questing/StepInstructions.lua)                     | Additional instructions, buttons, and group quest selection.                                      |
| [features/questing/StepQuestHandlers.lua](features/questing/StepQuestHandlers.lua)                   | Acceptance, objectives, abandonment, and turn-in.                                                 |
| [features/questing/StepTravelHandlers.lua](features/questing/StepTravelHandlers.lua)                 | Hearth, portals, waypoints, taxi, and scenarios.                                                  |
| [features/questing/StepActionHandlers.lua](features/questing/StepActionHandlers.lua)                 | Money, items/spells, treasure, groups, and achievements.                                          |
| [features/questing/StepTransitions.lua](features/questing/StepTransitions.lua)                       | Progress writing, revised context, history, and the last undoable jump.                           |
| [features/questing/StepDiagnostics.lua](features/questing/StepDiagnostics.lua)                       | Wait reasons from a snapshot without executing the engine.                                        |
| [features/questing/RouteCatalog.lua](features/questing/RouteCatalog.lua)                             | Search, provenance, availability, favorites, and route mutations with prerequisites.              |
| [features/questing/RouteActions.lua](features/questing/RouteActions.lua)                             | Inventory, bank, repair, training, death, and taming; context verification before action.         |
| [features/questing/Gossip.lua](features/questing/Gossip.lua)                                         | Automatic dialogues, NPC rules, and delays.                                                       |
| [features/navigation/Arrow.lua](features/navigation/Arrow.lua)                                       | Orientation, distance, visibility, and arrival at a configurable cadence.                         |
| [features/navigation/FlightPath.lua](features/navigation/FlightPath.lua)                             | Taxi discoveries and route-requested flight selection.                                            |
| [features/navigation/Map.lua](features/navigation/Map.lua)                                           | Map and minimap markers and lines using HereBeDragons.                                            |
| [features/navigation/WorldCoordinateConverter.lua](features/navigation/WorldCoordinateConverter.lua) | Author conversion/export on detached copy; geometry of collection zones.                          |
| [features/player/AFK.lua](features/player/AFK.lua)                                                   | Countdown and anchor; no `OnUpdate` once stopped.                                                 |
| [features/player/Buff.lua](features/player/Buff.lua)                                                 | Route buffs via AuraContainer or per-request checks depending on capabilities.                    |
| [features/player/Heirloom.lua](features/player/Heirloom.lua)                                         | Heirloom/enchantment reminders and reused secure buttons.                                         |
| [features/player/XPBuffOverlay.lua](features/player/XPBuffOverlay.lua)                               | Applicable XP reminders, secure actions, and persistent hiding.                                   |
| [features/player/Cutscenes.lua](features/player/Cutscenes.lua)                                       | Movies/cinematics; modifiers, settings, and `Dontskipvid`.                                        |
| [features/group/Party.lua](features/group/Party.lua)                                                 | Group progression, rate-limited sending, and incoming fragments.                                  |
| [features/group/PartyProtocol.lua](features/group/PartyProtocol.lua)                                 | Validation/copy of consumed fields, real sender, and bounded cost.                                |

### Integrations

| File                                                                         | External boundary                                                               |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| [integrations/TaxiData.lua](integrations/TaxiData.lua)                       | `LibTaxiData_API` facade, capability control, and login diagnostics.            |
| [integrations/Farstrider.lua](integrations/Farstrider.lua)                   | Graph to instructions/arrow, path cache, and compatibility predicates.          |
| [integrations/ForeverTravel.lua](integrations/ForeverTravel.lua)             | Flight links observed on Forever, tied to the character.                        |
| [integrations/SkinRegistry.lua](integrations/SkinRegistry.lua)               | Low-level APR control registry, single provider, and out-of-combat application. |
| [integrations/ElvUISkin.lua](integrations/ElvUISkin.lua)                     | ElvUI appearance and anchored panel backgrounds.                                |
| [integrations/EllesmereUISkin.lua](integrations/EllesmereUISkin.lua)         | Public EUI API, updated theme fonts and colors.                                 |
| [integrations/EllesmereUISettings.lua](integrations/EllesmereUISettings.lua) | Private AceGUI pool: the APR skin does not propagate to other addons.           |

### Interface

| File                                                                         | Responsibility and contract                                                       |
| ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| [ui/foundations/TextStyles.lua](ui/foundations/TextStyles.lua)               | Style inheritance, semantic colors, and low-level text/tooltip registry.          |
| [ui/foundations/StatusBars.lua](ui/foundations/StatusBars.lua)               | Native bars; APR owns the colors, skins provide the texture.                      |
| [ui/foundations/Themes.lua](ui/foundations/Themes.lua)                       | Four native themes and restoration of requested backgrounds/colors.               |
| [ui/foundations/Widgets.lua](ui/foundations/Widgets.lua)                     | Persistent windows, buttons, search, menus, tooltips, and shared copyable text.   |
| [ui/foundations/VirtualList.lua](ui/foundations/VirtualList.lua)             | Height indexing and recycling of only visible lines.                              |
| [ui/route/CurrentStep.lua](ui/route/CurrentStep.lua)                         | Window, bars, secure buttons, and delayed changes after combat.                   |
| [ui/route/CurrentStepRows.lua](ui/route/CurrentStepRows.lua)                 | Transactions, matching by key, recycling, and line layout.                        |
| [ui/route/CurrentStepImagePreview.lua](ui/route/CurrentStepImagePreview.lua) | Thumbnails and reusable windows; zoom, movement, and real ratio.                  |
| [ui/route/FillersFrame.lua](ui/route/FillersFrame.lua)                       | Optional objectives, content transactions, and panel anchoring.                   |
| [ui/route/QuestOrderList.lua](ui/route/QuestOrderList.lua)                   | Batch-built templates, atomic publication, and only visible lines instantiated.   |
| [ui/route/QuestOrderListRows.lua](ui/route/QuestOrderListRows.lua)           | Presentation of future actions without executing business logic.                  |
| [ui/route/QuestOrderListSupport.lua](ui/route/QuestOrderListSupport.lua)     | Shared template measurement, reusable rows, coroutine, reputation, and scrolling. |
| [ui/route/QuestionPopUp.lua](ui/route/QuestionPopUp.lua)                     | Confirmations, text inputs, and selections with refreshed callbacks.              |
| [ui/route/RouteSelection.lua](ui/route/RouteSelection.lua)                   | Invitation to choose a route when the path is unusable.                           |
| [ui/route/RouteBrowser.lua](ui/route/RouteBrowser.lua)                       | Resizable library, route details, filters, community, and ordered routes.         |
| [ui/panels/Coordinates.lua](ui/panels/Coordinates.lua)                       | Coordinates for authors and saved window position.                                |
| [ui/panels/ChangeLog.lua](ui/panels/ChangeLog.lua)                           | Version notes and formatting.                                                     |
| [ui/panels/SettingsHome.lua](ui/panels/SettingsHome.lua)                     | Essential settings, search, and access to tools.                                  |
| [ui/panels/LayoutEditor.lua](ui/panels/LayoutEditor.lua)                     | Independent outlines; cancel without mutation, save LibWindow out of combat.      |
| [ui/panels/Diagnostics.lua](ui/panels/Diagnostics.lua)                       | Copyable report, optional identity, wait reasons, and jump cancellation.          |
| [ui/panels/PerformanceDashboard.lua](ui/panels/PerformanceDashboard.lua)     | Peak graph, sortable aggregates, slow calls, counters, and export.                |

### Shared utilities

| File                                                           | Shared contract                                                                        |
| -------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| [utils/Utils.lua](utils/Utils.lua)                             | Tables/strings, deep copy, diagnostics, compatible events, and outbound fragmentation. |
| [utils/SecretUtils.lua](utils/SecretUtils.lua)                 | Access to values/tables and safe identity; loaded before APR.                          |
| [utils/PlayerUtils.lua](utils/PlayerUtils.lua)                 | Client, abilities, spells, resources, reputation, and action availability.             |
| [utils/ProfileUtils.lua](utils/ProfileUtils.lua)               | Character-scoped AceDB and profile-overriding preferences.                             |
| [utils/TextStyleUtils.lua](utils/TextStyleUtils.lua)           | AceConfig style controls; rendered in `TextStyles`.                                    |
| [utils/UIUtils.lua](utils/UIUtils.lua)                         | Frames, movement, anchoring, tooltips, images, and asset validation.                   |
| [utils/TargetUtils.lua](utils/TargetUtils.lua)                 | Public NPC identity, emotes, and raid marker macro.                                    |
| [utils/QuestUtils.lua](utils/QuestUtils.lua)                   | Asynchronous titles, acceptance pool, objectives, and completion.                      |
| [utils/StepUtils.lua](utils/StepUtils.lua)                     | Current step, progression, text, coordinates, and zones.                               |
| [utils/RouteUtils.lua](utils/RouteUtils.lua)                   | Filters, XP thresholds, imports, saved signatures, and keys/labels.                    |
| [utils/RouteConditions.lua](utils/RouteConditions.lua)         | Embedded skills and conditions for execution/preview.                                  |
| [utils/RouteHashUtils.lua](utils/RouteHashUtils.lua)           | Deterministic definition fingerprint, non-cryptographic.                               |
| [utils/SojournerUtils.lua](utils/SojournerUtils.lua)           | Campaign jump, character recall, and group consistency.                                |
| [utils/InstanceUtils.lua](utils/InstanceUtils.lua)             | Instance visibility and character initial preference.                                  |
| [utils/NavigationUtils.lua](utils/NavigationUtils.lua)         | Player body and normalized taxi discoveries.                                           |
| [utils/PlayerPositionUtils.lua](utils/PlayerPositionUtils.lua) | Position and axis order at the WoW/APR boundary.                                       |
| [utils/ZoneDetectionUtils.lua](utils/ZoneDetectionUtils.lua)   | Map cache, parent/child relationships, and player zone.                                |
| [utils/BuyMerchantUtils.lua](utils/BuyMerchantUtils.lua)       | Purchased quantities and localized loot messages.                                      |
| [utils/LootUtils.lua](utils/LootUtils.lua)                     | Collections, remembered bank, and sale value without selling.                          |

## Dependencies, media, and entry points

| Dependency                          | Usage                                                                           |
| ----------------------------------- | ------------------------------------------------------------------------------- |
| LibStub / CallbackHandler           | Internal Ace3/HBD libraries and callbacks.                                      |
| AceAddon / AceEvent                 | Modules, lifecycle, and route/catalog messages.                                 |
| AceDB / AceDBOptions                | Profiles and character scope; live object `APR.settings.db`.                    |
| AceConfig / Registry / Dialog / Cmd | Options; sub-libraries loaded via AceConfig XML.                                |
| AceGUI                              | Options and converter; recycling and private pool for EUI.                      |
| AceConsole                          | Registration of `/apr`.                                                         |
| AceLocale                           | 11 locales, English by default; strings injected at packaging time.             |
| AceSerializer                       | Serialization of progression for the group.                                     |
| HereBeDragons / Pins                | Coordinates and map/minimap markers.                                            |
| FarstriderLib / Data                | Graph and data; manifest `Standard` or `Camelot`, then finalization.            |
| LibTaxiData                         | External dependency required by `.pkgmeta`, optional in the TOC for load order. |
| LibDataBroker / LibDBIcon           | Minimap launcher.                                                               |
| LibSharedMedia                      | Font resolution.                                                                |
| LibWindow                           | Window positions and scales.                                                    |
| ElvUI / EllesmereUI                 | Optional; absence of both keeps native rendering.                               |

AceComm, AceBucket, AceHook, AceTab, and AceTimer are no longer loaded by
`embeds.xml`: no executed consumer was found in APR or the embedded libraries.
Their provider sources remain intact in `libs/`. The provider libraries are not
renamed or annotated as APR code.

The eight media assets in `assets/` cover the logo, header, arrow, minimap icon,
the `/apr 42` sound, and three `routeHelper/` illustrations. The illustration
names may come from routes/recorder data: the absence of a direct call in the core
does not prove a media asset is unused.

External inputs: `/apr`, XML bindings, AceAddon/AceDB callbacks, WoW events,
group messages, and route imports. `RegisterCustomRoute`, legacy flat lists, and
`AprRCData.ExtraLineTexts` remain supported. Option and SavedVariable names are kept.

| Access                                   | Common usage                                                      |
| ---------------------------------------- | ----------------------------------------------------------------- |
| `/apr`                                   | Essential settings, option search, themes, and access to tools.   |
| `/apr route`                             | Library, community, favorites, route, and predefined route flows. |
| `/apr status` or `?` button on the guide | Wait reasons, progression history, and copyable report.           |
| `/apr rollback` / `/apr rb`               | Undo the last valid manual skip, otherwise return to the previous visible step. |
| `/apr perf`                              | Open the dashboard; start/stop, sort, search, and export.         |
| `/apr perf on` / `/apr perf off`         | Control capture without opening the dashboard.                    |
| Placement in the home screen             | Preview positions, undo, save, or recenter.                       |

Advanced settings remain accessible from the home screen. Search uses existing
AceConfig definitions; only toggles without confirmation and with compatible
getters/setters are directly editable.

## Saves and caches

| State                                                | Owner and lifetime                                                                         |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `APRSettings`                                        | AceDB: visual/automation profiles and character preferences.                               |
| `APRData`                                            | Progression by `PlayerID`, imports, NPCs, temporary/parallel state, bank, and performance. |
| `APRCustomPath` / `APRZoneCompleted`                 | Ordered path and completed routes per character.                                           |
| `APRTaxiNodes` / `APRTaxiNodesTimer`                 | Discoveries and trip measurements; legacy names normalized to booleans.                    |
| `APRScenarioCompleted` / `APRScenarioMapIDCompleted` | Scenario progression per character.                                                        |
| `APRItemLooted` / `APRGossipValidated`               | Historical state of items/dialogues; keys preserved for existing progression paths.        |
| `FarstriderLibData_CharacterSettings`                | Character save data for the movement library.                                              |
| Memory caches                                        | Steps, titles, XP, maps, paths, widgets, and skins; invalidation by owner.                 |

Deep import copy (`DeepCopyTable`) isolates saves. Shallow runtime copy (`GetStep`)
shares navigation adjustments. Modifying a route signature can invalidate existing
progression: this is not a simple local optimization.

## Cleanups and fixes applied

- Six controllers moved out of `utils`: coordinates, cinematics, suggestions,
  route engine, delves, and list support.
- Shared deep copy with cycles and shared references for converter, imports, and
  profiles; step lookup, bounds, list comparison, and spell name handling shared.
- Assets moved into `UIUtils`, step text into `StepUtils`, and item/spell capability
  logic into `PlayerUtils`. Literal text search without a pattern and hexadecimal validation.
- Removal of helpers without an identified consumer, currency tracking without a
  reader, unexposed group simulations, and inaccessible image hooks. Methods called
  indirectly by AceAddon are preserved.
- Renames: `HasRouteInCustomPath`, `UpdateQpartPartWithQuestText`,
  `HandleMessageFragment`, `UpdatePosition`, `RegisterEvents`, `TableToDebugString`,
  and `questOrderListSupport`.
- End of generic globals `SettingsDB`, `LoadedProfileKey`, and `UpdateGroupStep`:
  state is attached to its module or local scope.
- Timers canceled via their handle; callback errors passed to the WoW handler.
- Reputation signatures also traverse `AllOf` and `Not` to invalidate stale lists.
- Fragments isolated by sender, index/size validated, duplicates ignored,
  expiration cleaned on assembly, and unnecessary ticker stopping.
- `Dontskipvid` protects films and cinematics; delayed skips re-check preferences.
- EUI settings icon independent of DamageMeters; ElvUI images handled by the common registry.

## Rework contracts

### Progression and diagnostics

`QuestHandler` orchestrates passes; quest, travel, and action handlers remain
separate. `StepTransitions` centralizes progression and provides a
character/route/index/revision context. Deferred callbacks verify this context
before acting. History retains at most 40 transitions.

Undo covers a single manual jump and the steps automatically traversed while it is
being resolved. Later progression or a route change invalidates it. It restores
the guide index, then the engine re-evaluates conditions; it does not restore the
state of in-game quests.

`StepDiagnostics` reads a snapshot with `PeekCurrentStep`: opening the report does
not build an effective route and does not execute any step action. The diagnostic
distinguishes absent quest, remaining objective, data still loading, and off-zone
guidance. For specialized actions, it reuses the actual instruction instead of
inventing a cause. Character/realm identity is hidden by default; free-form route
texts are not anonymized.

### Group messages

Validation after deserialization copies only the fields consumed by the interface,
removes presentation markup, checks finite numbers, and attaches identity to the
true sender. Table traversal is bounded to 128 entries. Assembly accepts up to
128 fragments of 180 bytes, two pending messages per sender, and 80 in total.
Rejected data feeds the diagnostic; it does not spam chat.

The `PartyValidate` measurement allows verifying the actual in-game cost. Offline
tests cover malformed input and limits without claiming to prove the absence of
client-side lag.

### Library and authors

The catalog separates route consultation, availability, and modification.
Multi-word search, expansion, category, and Community/Favorites/My routes tabs
apply without starting a route. Prerequisites pass through the existing engine.
A route removed from the catalog but still saved in a route remains visible in that
route so it can be deleted.

Attribution requested by the maintainer: **APR by default**; the route
`84-EclipseGlaives-10-to-70` is credited to **EclipseGlaives** and promoted in the
Community. This information is stored in the route data, without a catalog-only
exception. The `author` field is optional and defaults to APR; `authors` allows
multiple co-authors when `author` is absent. `community = true` or
`source = "community"` identifies a community route. `description` provides the
optional sheet text. The validation schema knows these fields; authors are never
inferred from Git.

### Lists and measurements

`VirtualList` keeps models and their heights, then instantiates only the viewport
lines with a scrolling margin. The step list uses a hidden measurement line with
the same rendering as the visible lines; it prepares models in batches of 3 ms
and publishes them all at once. `stepList` and `rawStepContainers` now contain
models; their `frame` property is defined only when a line is displayed. Filters,
route changes, and resize events invalidate stale work.

Performance capture is inactive by default and after reload. It keeps up to 64
unique names plus `Other` per family, 100 calls of at least 10 ms, and 120 seconds
of graph history. Histograms use bins of < 1, 1–3, 3–10, and ≥ 10 ms. The
dashboard exposes aggregates, slow calls, and cache counters; its refresh stops
when closed. Closing the dashboard leaves voluntary capture active. Data is saved
in `APRData.PerformanceLog`.

Durations are inclusive: nested calls overlap and their sum is not the addon's total
CPU usage. The dashboard shows instrumented call sites, not every function in the
client or other addons.

## UI/UX and skins

- Four native themes: WoW, Forever also available on Retail, Modern Teal, and High Contrast.
  Custom colors and fallback backgrounds are preserved when switching themes.
- Library list/details, home, diagnostics, and dashboard all use the same controls.
  New windows record size and position in the profile. The placement editor manipulates
  independent outlines until Save; Cancel, Esc, or entering combat abandons the preview.
- Only one provider paints a control: ElvUI takes priority if both are active. Switching
  providers requires a reload.
- APR owns the secure buttons, attributes, and callbacks; the skin modifies the appearance.
  Protected changes wait until combat ends.
- Public EUI primitives and refreshed accents/fonts; bar colors remain consistent with APR options.
- APR AceGUI pool is isolated and does not contaminate other addons' options.
- Quest tracking anchoring maintains Blizzard frame isolation; hierarchy accounts for fillers and AFK.
- Visible content, lines, and scrolling are preserved during refreshes. The list prepares its
  buffer in batches; a costly element may still exceed the budget of a single batch.

The specialized renderings for the step, future list, and group are retained: their information
and interactions differ. Merging them into one large configurable factory would reduce readability.

Design references consulted: [VaultLoom](https://www.curseforge.com/wow/addons/vaultloom),
[Waypoint UI](https://github.com/Adaptvx/Waypoint-UI),
[Narcissus](https://github.com/Peterodox/Narcissus), and
[Plumber](https://github.com/Peterodox/Plumber). The design keeps principles of
clear navigation, visual hierarchy, and contextual detail. No code or assets from these
addons are incorporated into the redesign.

## Validation and evolution

From the root:

```powershell
.venv\Scripts\python.exe tests\run.py
```

Regression coverage added: saves/copies, step lookup, AceDB isolation, timers,
errors, nested reputation, cinematics, and message assembly. Fixtures load the
moved helpers in the same relative order as the TOC; rendering, progression, and
recycling assertions are preserved. The redesign adds scenarios for transitions/undo,
party validation, catalog/authors, setting search, diagnostics, bounded capture,
themes, and virtualization. Tests use the real module code with simulated WoW APIs.

Audit result: **46/46 Lua suites passed; 162/163 tests passed** in the full
validation run. The only failure is
`RouteHookTests.test_manual_no_stage_leaves_index_untouched`, also reproduced with
the scripts, hooks, and `StepUtils.lua` extracted from `HEAD` before the redesign.
This pre-existing test/tooling defect remains out of scope; routes are not modified
to work around it.

The [in-game test plan](TESTS_EN_JEU.md) describes 66 cases, the configurations to
try, and the expected results. **They are not executed by the agent**: rendering,
taint, protected buttons, and real-world cost must be checked manually on both
client families and available skins.

## Possible improvements after validation

| Priority | Proposed follow-up                                                           | Required validation                                                                                     |
| -------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| P1       | Fix the discrepancies observed during the 66 validation cases.               | Reproduction with client, skin, resolution, and report; no visual certification outside the game.       |
| P2       | Split the option families in `Config.lua` and event families in `Event.lua`. | Explicit contracts for shared state and behavior regressions; preserve keys and SavedVariables.         |
| P2       | Localize the new labels beyond FR/EN.                                        | Proofreading via AceLocale `UI_*` keys and in-game length checks.                                       |
| P2       | Complete community entries: descriptions and multiple authors.               | Metadata supplied by maintainers/authors, recorder compatibility; no inferred attribution.              |
| P3       | Adjust build budgets and caches based on real captures.                      | Comparable measurements on the same routes/clients; do not optimize from simulated timings alone.       |
| P3       | Add more explanatory text for specialized actions.                           | Reliable public state and contracts verified per action type; diagnostics must remain side-effect free. |
| P3       | Explore complete keyboard navigation for the new lists.                      | Focus handling, Esc handling, and no keyboard capture after closure, verified in WoW.                   |

Route formats, save data, and signatures must remain compatible with the recorder.
Any future changes to `Routes/` content are a separate project from this APR-Core
audit.

## Appendix: WoW API references used in the core

Static inventory of 124 call references and availability checks for `C_*`
across 43 namespaces, excluding provider code. A reference does not mean the
function is available or called on both clients. Historical globals and widget
methods supplement these interfaces.

| Namespace                    | Referenced functions                                                                                                                                                                                                                                                                                                                                               |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `C_AddOns`                   | `GetAddOnMetadata`                                                                                                                                                                                                                                                                                                                                                 |
| `C_AdventureMap`             | `Close`, `GetNumZoneChoices`, `StartQuest`                                                                                                                                                                                                                                                                                                                         |
| `C_BattleNet`                | `GetFriendAccountInfo`                                                                                                                                                                                                                                                                                                                                             |
| `C_CampaignInfo`             | `IsCampaignQuest`                                                                                                                                                                                                                                                                                                                                                  |
| `C_ChatInfo`                 | `PerformEmote`, `RegisterAddonMessagePrefix`, `SendAddonMessage`                                                                                                                                                                                                                                                                                                   |
| `C_ChromieTime`              | `GetChromieTimeExpansionOption`, `SelectChromieTimeOption`                                                                                                                                                                                                                                                                                                         |
| `C_ColorUtil`                | `WrapTextInColorCode`                                                                                                                                                                                                                                                                                                                                              |
| `C_Container`                | `GetContainerItemID`, `GetContainerItemInfo`, `GetContainerItemLink`, `GetContainerItemQuestInfo`, `GetContainerNumSlots`, `GetItemCooldown`, `UseContainerItem`                                                                                                                                                                                                   |
| `C_CreatureInfo`             | `GetCreatureID`                                                                                                                                                                                                                                                                                                                                                    |
| `C_CurrencyInfo`             | `GetCoinTextureString`                                                                                                                                                                                                                                                                                                                                             |
| `C_DateAndTime`              | `GetCurrentCalendarTime`                                                                                                                                                                                                                                                                                                                                           |
| `C_DeathInfo`                | `GetCorpseMapPosition`                                                                                                                                                                                                                                                                                                                                             |
| `C_EventUtils`               | `IsEventValid`                                                                                                                                                                                                                                                                                                                                                     |
| `C_FriendList`               | `GetFriendInfoByIndex`, `GetNumFriends`                                                                                                                                                                                                                                                                                                                            |
| `C_GameRules`                | `IsHardcoreActive`                                                                                                                                                                                                                                                                                                                                                 |
| `C_GossipInfo`               | `CloseGossip`, `GetActiveQuests`, `GetAvailableQuests`, `GetFriendshipReputation`, `GetFriendshipReputationRanks`, `GetNumActiveQuests`, `GetNumAvailableQuests`, `GetOptions`, `SelectActiveQuest`, `SelectAvailableQuest`, `SelectOption`, `SelectOptionByIndex`                                                                                                 |
| `C_Item`                     | `DoesItemExist`, `DoesItemMatchSpellItemCondition`, `GetDetailedItemLevelInfo`, `GetItemCooldown`, `GetItemCount`, `GetItemID`, `GetItemIconByID`, `GetItemInfo`, `GetItemInfoInstant`, `GetItemSpell`, `GetItemStats`, `IsUsableItem`                                                                                                                             |
| `C_MajorFactions`            | `GetCurrentRenownLevel`, `GetMajorFactionData`                                                                                                                                                                                                                                                                                                                     |
| `C_Map`                      | `GetBestMapForUnit`, `GetMapChildrenInfo`, `GetMapInfo`, `GetMapPosFromWorldPos`, `GetPlayerMapPosition`, `GetWorldPosFromMapPos`                                                                                                                                                                                                                                  |
| `C_Minimap`                  | `GetViewRadius`                                                                                                                                                                                                                                                                                                                                                    |
| `C_NamePlate`                | `GetNamePlates`                                                                                                                                                                                                                                                                                                                                                    |
| `C_PetBattles`               | `IsInBattle`                                                                                                                                                                                                                                                                                                                                                       |
| `C_PlayerChoice`             | `GetCurrentPlayerChoiceInfo`, `SendPlayerChoiceResponse`                                                                                                                                                                                                                                                                                                           |
| `C_PlayerInteractionManager` | `ConfirmationInteraction`                                                                                                                                                                                                                                                                                                                                          |
| `C_PvP`                      | `CanToggleWarMode`, `CanToggleWarModeInArea`, `IsWarModeActive`, `IsWarModeDesired`                                                                                                                                                                                                                                                                                |
| `C_QuestLine`                | `GetQuestLineInfo`                                                                                                                                                                                                                                                                                                                                                 |
| `C_QuestLog`                 | `AbandonQuest`, `AddQuestWatch`, `GetInfo`, `GetLogIndexForQuestID`, `GetMapForQuestPOIs`, `GetNumQuestLogEntries`, `GetNumQuestObjectives`, `GetQuestObjectives`, `GetTitleForQuestID`, `IsComplete`, `IsOnQuest`, `IsPushableQuest`, `IsQuestFlaggedCompleted`, `IsQuestFlaggedCompletedOnAccount`, `ReadyForTurnIn`, `RequestLoadQuestByID`, `SetSelectedQuest` |
| `C_Reputation`               | `GetFactionDataByID`                                                                                                                                                                                                                                                                                                                                               |
| `C_ScenarioInfo`             | `GetCriteriaInfoByStep`, `GetInfo`, `GetScenarioInfo`, `GetScenarioStepInfo`                                                                                                                                                                                                                                                                                       |
| `C_SkillInfo`                | `GetNumSkillLines`, `GetSkillLineInfo`, `GetSkillLineInfoByID`                                                                                                                                                                                                                                                                                                     |
| `C_SpecializationInfo`       | `GetSpecialization`, `GetSpecializationInfo`                                                                                                                                                                                                                                                                                                                       |
| `C_Spell`                    | `GetSpellCooldown`, `GetSpellCooldownDuration`, `GetSpellDescriptionForItemLocation`, `GetSpellInfo`, `GetSpellSubtext`, `GetSpellTexture`, `IsSpellUsable`, `TargetSpellChecksItemCondition`                                                                                                                                                                      |
| `C_SpellBook`                | `IsSpellInSpellBook`, `IsSpellKnown`                                                                                                                                                                                                                                                                                                                               |
| `C_StringUtil`               | `RemoveContiguousSpaces`, `StripHyperlinks`, `Trim`, `trim`                                                                                                                                                                                                                                                                                                        |
| `C_SuperTrack`               | `SetSuperTrackedQuestID`                                                                                                                                                                                                                                                                                                                                           |
| `C_TaskQuest`                | `GetQuestZoneID`                                                                                                                                                                                                                                                                                                                                                   |
| `C_TaxiMap`                  | `GetAllTaxiNodes`                                                                                                                                                                                                                                                                                                                                                  |
| `C_Timer`                    | `After`, `NewTicker`, `NewTimer`                                                                                                                                                                                                                                                                                                                                   |
| `C_ToyBox`                   | `GetToyInfo`, `IsToyUsable`                                                                                                                                                                                                                                                                                                                                        |
| `C_TransmogCollection`       | `GetItemInfo`, `PlayerHasTransmog`                                                                                                                                                                                                                                                                                                                                 |
| `C_UI`                       | `Reload`                                                                                                                                                                                                                                                                                                                                                           |
| `C_UIFileAsset`              | `IsKnownFile`                                                                                                                                                                                                                                                                                                                                                      |
| `C_UnitAuras`                | `GetPlayerAuraBySpellID`                                                                                                                                                                                                                                                                                                                                           |

Templates used: `ActionButtonTemplate`, `BackdropTemplate`, `CooldownFrameTemplate`, `CustomAuraContainerTemplate`, `InputBoxTemplate`, `ObjectiveTrackerContainerHeaderTemplate`, `ObjectiveTrackerModuleHeaderTemplate`, `SecureActionButtonTemplate`, `StaticPopupButtonTemplate`, `UIPanelButtonTemplate`, `UIPanelScrollFrameTemplate`.
