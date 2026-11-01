# Route performance checks

All regression tests now live in `tests/`. Run `python tests/run.py` for all
Python, Lua and route syntax checks; see `tests/README.md` for dependencies and CI.

## Luacheck while editing in VS Code

Install the recommended `trixnz.vscode-lua` extension alongside Lua Language
Server (`sumneko.lua`). Install [Luacheck](https://github.com/lunarmodules/luacheck#installation)
and set `lua.luacheckPath` in your workspace settings to its executable's absolute
path (Windows binaries are available from the project's releases). Set
`lua.preferLuaCheckErrors` to `true` and `lua.targetVersion` to `"5.1"`.

The extension checks open Lua buffers on content changes, including unsaved
edits, and reports warnings/errors inline and in **Problems** (`Ctrl+Shift+M`).
It discovers the repository's `.luacheckrc` from each file's directory, keeping
the same rules as CI. Lua Language Server provides completion and
navigation; it does not read `.luacheckrc`. To use Luacheck as the sole diagnostic
provider, set `Lua.diagnostics.enable` to `false`. This retains completion and
navigation, but disables LuaLS type/API diagnostics. The project's `.luacheckrc`
also ignores global-variable diagnostics, so this setup does not detect unknown
WoW globals. Exclude `tests` and `tools` via `Lua.workspace.ignoreDir` to keep
standalone mocks out of addon completion and inferred signatures.

After changing the executable path, run **Developer: Reload Window** if needed.
For a full check matching CI, run `luacheck ./APR-Core` and `luacheck ./Routes`
from the repository root (or invoke the configured executable by its full path).
Workspace settings are ignored by Git; configure this path on each machine.

## Whole-addon diagnostics

### Gameplay spike audit: 2026-10-30.1

The audit follows event dispatch, quest synchronization, guide rows, progress
bars, XP reminders, bank snapshots, navigation preparation/search/arrival,
map/arrow updates, group traffic, pooled widgets and diagnostic collection.
Findings below describe source behavior and synthetic workloads. They do not
attribute a measured client freeze to APR or establish an FPS improvement.

| Mechanism | Change | Regression evidence |
| --- | --- | --- |
| Every quest-log update replaced objective tables and relaid out unchanged visible rows | Reuse objective records; skip unchanged text/geometry and arrow writes; retire removed objectives | 100 unchanged refreshes, 150 synthetic objectives and 12 visible rows: **1,500 layout passes at HEAD b630fb76, zero after the change**; all 150 objective identities remain stable |
| Percentage bars reset anchors and full guide geometry on every log refresh | Update only the value/label for an existing bar; rebuild geometry on appearance/removal | Percentage changes with identical objective text remain live; repeated hidden bars cause no further layouts |
| Combined quest/step synchronization updated rows immediately before rebuilding them | Data-only synchronization when the caller already owns the following render | Deferred synchronization performs zero objective/filler row updates |
| Bank slot notifications each scanned the entire bank | Coalesce slot/bag bursts into one 50 ms snapshot; flush a pending snapshot on close while data is still accessible | 1,000 notifications share one scan; closed, cancelled and disabled callbacks cannot overwrite it |
| XP reminder events rebuilt unchanged labels, anchors and visibility | Reconcile existing rows; ignore unrelated item data; avoid scheduling inactive/combat refreshes | 100 identical refreshes produce zero visibility/anchor/label/icon/height writes; 1,000 unrelated item events schedule zero timers |
| Other units and foreign addon messages entered the full gameplay dispatcher | Native player unit registration for aura/cast/quest-log events, with a Lua fallback; reject unknown communication prefixes early | 1,000 other-unit events and 1,000 foreign messages perform zero settings/instance/step probes; player and opaque unit payloads retain delivery |
| Auto-complete notifications could each create a permanent one-second polling chain | One cancellable chain, at most five delayed attempts, validated against settings and step context | 1,000 duplicate requests share one timer; delayed data, route changes, modifier override and stale callbacks are covered |

Cleanup removes the unused `navigation:OnArrowUpdate` forwarding hook and the
duplicate `ShowQuestOffer(1)` calls preceding the actual quest popup. The
navigation controller retains arrival ownership. Source instrumentation and its
manifest are regenerated, and new captures identify revision 2026-10-30.1.
Embedded third-party libraries and SavedVariables formats are unchanged.

Navigation was already cooperative and cached. Running
`python tools/validation/benchmark_navigation.py --runs 3` with Lua 5.1 on the
audit host gave these observations (milliseconds, three runs per scenario):

| Scenario | Median total work | 95th percentile slice | Maximum slice |
| --- | ---: | ---: | ---: |
| Taxi index, cold | 22.09 | 0.92 | 1.12 |
| Taxi index, warm | 0.12 | 0.12 | 0.12 |
| Retail catalogue, cold | 12.52 | 0.92 | 1.12 |
| Forever catalogue, cold | 1.08 | 0.91 | 0.91 |
| Synthetic search | 56.82 | 0.92 | 1.17 |
| Dense synthetic search | 8.00 | 0.91 | 0.91 |

Total worker duration spans multiple frames. These fixture timings include
Lua/Python crossings and host scheduling; they are neither client measurements
nor hard upper bounds. A native API call or individual widget binding can still
exceed a cooperative budget. The existing settings/skin/quest-list publication
checks, bounded group-finder queues and explicit-only memory scanner remain
relevant protections; reducing their coverage would hide useful failure modes.

API compatibility was checked against Blizzard's exported
[Retail frame utilities](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua),
[Classic frame utilities](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua),
[Retail timers](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua)
and [Classic timers](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua).
Forever remains a client variant whose behavior must also be checked in game;
native unit registration falls back to ordinary registration when unavailable.

For release validation on Retail and Forever, record a fresh `/apr perf on`
capture with `/apr debug off`: advance quest objectives including percentage
bars, open/transfer/close a full bank, gain/lose XP bonuses across combat, and
exercise delayed auto-completion while changing route/settings. Include a busy
group area, a long itinerary and first/repeated settings opens. Stop with
`/apr perf off` and export the diagnostic report. Compare APR root/self timings
with client frame spikes and repeat normal play with capture disabled; capture
overhead and a global client spike alone cannot establish addon causation.

The source-checkout localization contract currently reports an empty `enUS`
companion catalog: locale files contain packager/CurseForge directives before
translation injection. The complete runner reports this failure rather than
skipping the contract or inventing translations for the performance patch.

`python tools/validation/instrument_lua.py --write` instruments every owned Lua
function in `APR-Core/` and `Routes/`, including local functions, nested functions,
anonymous callbacks, and coroutine workers. Edit function bodies normally and
rerun the generator. Its marked additions are removed before regeneration;
running it twice produces identical output. `--check` and the Lua CI suite reject
missing/stale instrumentation. The generated `DiagnosticManifest.lua` records
coverage and explicit exclusions: third-party libraries, diagnostic recorders,
resource sampling and safe error handling. Calls into libraries are measured at
APR call sites, not attributed to individual library internals.
The diagnostic viewer records its root cost but suppresses nested drawing/filtering
traces, so refreshing the log cannot overwrite the gameplay events being inspected.

In game, `/apr perf on` captures timings; `/apr debug on` additionally captures
function calls in the bounded journal. `/apr debug` opens the searchable log.
Use `/apr perf off` and `/apr debug off` before exporting from the Perf window or
with `/apr debug export`. `/apr debug clear` clears the journal. Debug and perf
switches are independent. Continuous debug no longer floods chat: entries include
time, category, source, route/step, durations and repeat counts. The report lists
all observed metrics, slow calls, client frame spikes, coverage and exclusions.
The report identifies the loaded diagnostic revision, the revision that started
the performance capture and journal, and whether debug CALL tracing was enabled
at any point during capture. Older saved captures remain marked unknown rather
than being attributed to a newly loaded exporter. After syncing addon files,
reload WoW's UI and start a fresh capture before comparing revisions.
Fast debug calls below 3 ms from the same source and route/step share a journal
entry for up to one second, even when interleaved with other calls. Counts, summed
durations, maximum duration and first/last timestamps are retained. Slow calls
remain individual entries and performance metrics still count every invocation.
This bounds allocation pressure as well as retained memory during full capture.
Frame-spike exports also include completed APR main-thread root timings from the
preceding frame, when available, and the largest contributing source. Nested
calls are not added twice; multi-frame coroutine workers are accounted through
their resume caller. These timings include capture overhead. Missing attribution
is unknown, not zero, and a client frame spike alone does not establish causation.

The 2026-10-18.2 client capture confirmed low navigation call maxima, but linked
a 102 ms client frame to 94 ms opening settings and a 100 ms frame to 78 ms of
post-combat skin refresh. Revision 2026-10-18.3 flushes only pending skin targets
after combat unless a full appearance refresh was explicitly requested, and
styles an AceConfig settings tree once after nested Open/FeedGroup calls finish.
`skin_pending_performance` checks a 1,000-control registry and explicit theme
changes; `settings_widgets` verifies one layout pass and nested-error recovery.
Recheck combat exit and first/repeated settings opens in WoW; the client capture
included debug tracing, and these changes do not explain every global frame spike.
Another .2 capture showed settings calls up to 261 ms and post-combat list refreshes
up to 15 ms. Revision 2026-10-18.4 additionally suppresses styling hooks while
AceConfig initializes/reuses its controls, then styles the completed tree, and
refreshes only dirty list rows after combat. Explicit theme refreshes still visit
the full list registry. Tests cover reacquiring real AceGUI checkboxes, error
recovery, 1,000 idle rows, repeated dirty changes and deferred icon creation.

Revision 2026-10-18.5 targets gameplay with the arrow, current step and quest list
visible. The .2 capture still showed list batches reaching 22.45 ms: the progression
visibility scan and the final reputation scan were outside the row budget. Both
now run in the cancellable worker, with checkpoints through nested reputation
conditions. Publishing a rebuilt list binds the current-step viewport directly,
avoiding a first-page bind followed by a deferred scroll. Tests cover 1,200 route
entries, nested reputation requirements, unchanged-model reuse, changed filters,
cancellation and a single destination viewport bind. The 3 ms budget is checked
between work units, not a hard limit on a native UI call or final publication.
Repeat a gameplay capture to measure `QuestOrderListBatch` and `UpdateStepPass`;
automated scheduling tests do not establish a new client maximum or FPS gain.

Revision 2026-10-19.1 reduces menu work without changing diagnostic coverage.
Route searches tokenize once per filter, sort comparisons use prepared keys,
and catalog rebuilds reuse unchanged normalized metadata while rereading live
visibility, progress and favorites. Opening Routes no longer refreshes twice
through both OnShow and the workspace. Release-note blocks and rows are reused
until their text or embedded colors change. Regression tests count normalization,
parsing and refresh calls, including changes that must invalidate cached values.

Reputation notifications now coalesce into cancellable 3 ms scan batches. Route
counting and nested reputation signatures yield between entries; only a validated
result publishes the total, with the current-step UI rebuilt on a subsequent
timer tick. New notifications, route/progress changes and event cleanup cancel
obsolete work. `ReputationScanBatch` measures each active batch; `ReputationRefresh`
now measures the separate commit, so it is not directly comparable to the old
combined operation. A single native call or the step rebuild can still exceed the
scan budget. `reputation_scheduling` covers 1,200 steps with synthetic CPU costs,
including capture enabled; repeat menu opens and reputation gains in WoW to
measure actual frame-time improvement.

Revision 2026-10-19.2 targets catch-up through already-completed routes. The .1
capture recorded 623 step passes and 600 transitions in 56 seconds; commit work
alone accumulated 1.6 seconds, and scheduled navigation reached 30 ms. Interrupted
passes now leave geometry dirty for the next successful commit instead of laying
out each skipped step. Map updates publish only a settled step, and navigation
waits before quest synchronization as well as before pathfinding while progression
is pending. Tests exercise 1,250 completed objectives, 600 interrupted UI passes,
manual cancellation and routing deferral, including diagnostic capture enabled.
Virtual lists also skip row binding beneath hidden ancestors until OnShow.
`StepRenderCommit` now includes the deferred map notification; compare full passes
and counts rather than treating changes in this submetric as a direct speedup.
Coroutine worker totals still span multiple batches: the observed 154 ms worker
was not a single-frame block. The client capture must validate the remaining
quest-list publication peak (26.9 ms before these changes).

Revision 2026-10-19.3 removes the delayed duplicate path notification after route
completion. Catalog publication waits until catch-up has settled, including across
yielded step batches. Ordinary step-triggered navigation reuses an already committed
step only while its context is still current; explicit zone/retry requests retain
quest synchronization. `ZoneRoutingReuseStep` counts that reuse and is nested inside
`ZoneRoutingQuestSync`; it is not an additional cost to add to navigation totals.

Quest-list prefix offsets are prepared inside the existing 3 ms model worker.
`QuestOrderListPublish` measures model publication; the visible rows now bind in
separate `QuestOrderListViewportBatch` slices with a 2 ms budget checked after each
row. A single row/native call can exceed that budget. Pending viewport work follows
the latest scroll position and model generation, stops while hidden and releases
its worker on errors. Published models are complete before binding starts; visible
rows can appear over several frames. Tests simulate expensive bindings, replacement,
scrolling, hidden parents and error recovery, with diagnostics both on and off.
Compare these new metrics and `ScheduledNavigation` in a fresh client capture;
automated timings are not measurements of the user's hardware.

Timings are inclusive; the Self column excludes instrumented child calls.
Coroutine suspension time is excluded through APR-owned yield/resume call sites.
Capture itself adds overhead. Disabled wrappers only forward calls; they retain
callback identity and do no timing, stack allocation or logging. Captures retain
up to 8,192 metric names, 100 slow calls, 1,000 journal entries, 100 frame spikes
and 600 resource samples; older ring entries are overwritten. Coverage means
instrumented source definitions, not proof that every function ran in a session.

Route syntax checks report a missing `RouteCompleted = true` without modifying
the route. Scenario routes keep their separate instance completion flow. Run
`python tools/validation/route_completion.py` explicitly to repair ordinary
endings, or add `--check` for a read-only report. The repair preserves existing
steps, comments, encoding and line endings; a second repair makes no changes.

Current-step rendering regression:

```text
lua tests/lua/current_step_render_test.lua
lua tests/lua/route_panels_render_test.lua
# All focused UI checks using the Lua 5.1 runtime from lupa:
.venv/Scripts/python.exe tools/validation/run_lua_tests.py --ui-only
```

The test loads the frame and row modules and runs 100 identical content passes.
It checks zero additional frame/font allocations, no row/action hide calls, one
layout per pass, updated tooltips, wrapping, route progress reuse, collapse state,
percentage labels, and secure-row replacement and cleanup across combat. The
Python runner discovers all Lua suites automatically. Widget mocks do not validate the
client's rendering or taint system: also check a long objective, a pickup list,
image previews, collapse/expand, and an item-use step during combat in game.

Quest-action bindings keep `CLICK APR_ItemButton:LeftButton` for the primary
action and expose `CLICK APR_TargetButton:LeftButton` separately for the NPC
target/raid-marker control. The action shortcut never retargets implicitly.
Visible guide actions take precedence over optional filler actions, following
each panel's displayed row order rather than frame creation or pool order.
The first action stays selected on repeated presses; other actions remain
clickable. Cooldowns and missing items do not silently select a different action.
With no matching visible control the shortcut clears its payload and does nothing.

`gamepad_test.lua` models restricted frame handles (without native Button methods)
and verifies scalar action dispatch, payload cleanup, stable ordering, separate
targeting, combat resolution and housing bookkeeping. `quest_action_binding_test.lua`
also exercises registration through the actual guide renderer and recycled rows.
In game, `/reload`, bind both shortcuts in APR's key-binding category and check
an item, two simultaneous actions, target plus item, a target-only step, an empty
step and a filler. Check both ActionButtonUseKeyDown preferences, modifiers and
an already-created item button during combat. New/reconfigured protected controls
still wait for combat to end; simulated widgets cannot certify native taint rules.

`ui/foundations/StatusBars.lua` creates all APR bars as native `StatusBar` frames
and applies their configured RGBA colors. The guide's color option refreshes its
header, quest objectives, reputation and money bars together; AFK retains its own
color option. `Love()` / `ApplyLoveColors()` recolor existing and future bars pink
without changing their alpha. EllesmereUI supplies textures while APR owns fill
colors. `status_bar_colors_test.lua` and `ui_skin_test.lua` verify these rules.
`afk_bar_lifecycle_test.lua` covers native ownership, countdown formatting,
restart/expiry, snapping and disable. AFK updates at most every 40 ms while its
timer is active and removes its update script when stopped. Check the countdown,
both color options and theme changes in game as well.

`CurrentStep.lua` owns the window, progress bar placement and secure controls;
`CurrentStepRows.lua` owns keyed rows, reconciliation and layout. `UpdateStep`
brackets each pass with `BeginContentUpdate` / `EndContentUpdate`. During a pass,
removal marks old rows; add/update calls retain rows with matching keys and kinds;
the successful final pass retires untouched rows and positions the result once.
An interrupted pass retains the previous content. Callers outside a pass still
get immediate updates. Protected rows are retired by frame identity and deferred
anchors are applied after combat, so reusing a key cannot destroy its replacement.

Retired rows now enter pools separated by parent and row kind. Their secure action
buttons, cooldowns, detail fonts and preview thumbnails are reused. Combat cleanup
waits until protected frames can be changed, then prefers pooled secure rows over
converting another temporary plain row. Configuration lists also recycle their
rows, and heirloom buttons are cached by toy ID. `memory_recycling_test.lua` checks
1,000 step/action changes, 100 combat cycles and repeated configuration/heirloom
refreshes without further widget allocations after warm-up.

`route_panels_render_test.lua` loads the real Fillers and Quest Order List modules
using the shared `route_ui_test_env.lua` widgets. It covers 100 filler refreshes
without new frames/fonts or hidden rows, stable objective ordering, wrapping,
collapse, snapping, and combat cleanup. It also renders a 1,200-step route to check
budgeted preparation/recycling, unchanged-view reuse, scroll preservation, stale
job cancellation, missing/filtered rows, resize coalescing and error recovery.

The Quest Order List keeps two reusable scroll children: one visible, one being
prepared within the existing 3 ms batch budget. It publishes the prepared child
only when complete and changed. This trades up to two sets of route widgets for
a stable visible list during refreshes. Ordinary forward progression still updates
the active row in place. `QuestOrderListRows.lua` owns route presentation;
`QuestOrderList.lua` owns the window and render lifecycle. The Fillers frame joins
the current-step content transaction and applies pending protected geometry after
combat. In game, also check manual scrolling during quest updates, rollback,
resizing, independent/snapped collapse, and item buttons during combat.

Client packaging and visibility checks:

```text
lua tests/lua/client_compatibility_test.lua
python tools/validation/check_package.py PATH_TO_UNPACKED_APR
```

The package check expects a single release containing the generated Mainline and
Camelot TOCs. It follows the TOC/XML include graph to verify all runtime dependencies,
checks separate route manifests, and rejects development files, SVG sources and
standalone library TOCs. Runtime textures and third-party license notices stay in
the release; `.pkgmeta` excludes the tooling, source artwork and documentation.
The Lua check covers hidden incompatible routes, saved imports, prefab popups and
missing Retail APIs/events. These mocks do not replace an in-game Forever smoke test.

Automatic external waypoints:

`APR-Core/features/navigation/NavigationAdapter.lua` supplies the effective authored
Waypoint or accepted transient/retained target after step rendering settles.
The library's `WaypointUI.lua` and `AzerothWaypoint.lua` own publication, provider
selection, ownership and cleanup. APR enables this integration automatically while
the addon is active, independently of its arrow visibility; a former profile's
`waypointUI = false` is ignored. No separate APR waypoint setting is exposed.
Target resolution uses `GetStepCoord` and the shared preview projection, including
native map, floor and world-instance identity. Retained guidance keeps its map,
label and ID while replacement navigation is calculated. The integration never
advances a route; completed WaypointDB anchors and direct arrivals only retire
presentation.

Outside APR, consumers can enable the library's `waypoints` option and provide
`environment.getWaypointTarget()`, or use `SetWaypoint`, `SetWaypointForSegment`
and `ClearWaypoint` manually. `RefreshWaypoints()` synchronizes immediately;
`ReleaseWaypoints()` performs technical cleanup, and `ReleaseWaypoints(true)`
also suppresses the current authored context until it changes. APR's navigation,
step-transition, rendering and profile hooks call these library APIs.

Consumer precedence and API contracts (checked 2026-10-23):

- AzerothWaypoint's existing `apr` guide provider takes precedence. The library decorates
  its extractor and activation token through the exported registry, preserving
  its visibility, hooks, ordinary quest presentation, provider selection, manual
  authority, routing and TomTom carrier. It signals normal provider evaluation
  without explicit takeover. No second Blizzard/TomTom waypoint is created.
  Unsupported or missing registry contracts are left alone.
- Otherwise the library uses `WaypointUIAPI.Navigation.NewUserNavigation`, unless
  Waypoint UI's own `APRSupportEnabled` setting is enabled. In that case the
  native adapter keeps ownership. APR does not change third-party settings.
  Existing quest/other supertracking is sufficient when its next waypoint
  matches APR's effective position; an intermediate waypoint at another position
  still needs guidance. Existing player/addon pins always keep ownership.
- Waypoint UI receives percentages and a `name` containing the current summary,
  localized notes and extra instructions; its returned session uses normalized
  coordinates. The library retains that session object and its unique instance
  flag. Cleanup verifies ownership, preserves a replacement native marker and
  calls `ClearUserNavigation(preserveWaypoint)` without `suppressAdvance`, which
  would also prevent Waypoint UI's own path cleanup. No persistent pin is added.

An explicitly cleared itinerary remains suppressed for its step context;
technical replanning can republish the same target. Manual dismissal and direct
arrival stay suppressed for the same target identity. Route/step/revision changes
and re-enabling permit fresh guidance. Mutations are deferred during combat and
the latest target is resolved afterwards, including when APR settings are disabled.
Waypoint UI's transport overlay can temporarily remove native supertracking
without abandoning the owned destination. AWP retains its own combat handling.

API sources: Waypoint UI 1.7.4 was installed locally; AzerothWaypoint was not.
The official sources inspected were Waypoint UI
[`API.lua`](https://github.com/Adaptvx/Waypoint-UI/blob/c3fdd2077debfde6d0dd768a4a7513e6ede0358e/API.lua),
[`MapPin.lua`](https://github.com/Adaptvx/Waypoint-UI/blob/c3fdd2077debfde6d0dd768a4a7513e6ede0358e/Code/MapPin/MapPin.lua)
and its native APR/TomTom adapters, plus AzerothWaypoint
[`apr_provider.lua`](https://github.com/MorningStarGG/AzerothWaypoint/blob/a40b7fce8c0115f0b6c0204c94a787b26595e98c/integrations/guides/apr/apr_provider.lua)
and [`guide.lua`](https://github.com/MorningStarGG/AzerothWaypoint/blob/a40b7fce8c0115f0b6c0204c94a787b26595e98c/bridge/routing/guide.lua).
Next-waypoint detection supports the current `C_Navigation` API and older
`C_SuperTrack` form used by the installed WUI, with capability checks.

`waypoint_integration_test.lua` exercises real APR step/context/projection code
through the library with isolated consumer API fixtures. Its 50 scenarios cover
automatic publication with older disabled profile values, ownership, relevant supertracking,
native adapter handoff, AWP provider decoration, transit/retained targets, text,
combat, cancellation, arrival, WaypointDB, zone/floor/instance changes and disabled
or missing APIs. Step-transition, progression and controller suites also check the
publication/cleanup hooks. `navigation_waypoint_ui_test.lua`,
`navigation_waypoint_ui_auto_test.lua` and `navigation_azeroth_waypoint_test.lua`
also exercise manual/automatic library use without APR. Run the full Lua suite
and regenerate diagnostics:

```text
python tools/validation/instrument_lua.py --write
python tests/run.py --suite lua
```

In-game smoke checks still include WUI pathfinding through a transport overlay,
manual marker replacement during combat, both addons together with TomTom, and
changing an APR route while temporary guidance is active. Native third-party
adapters retain their own lifecycle rules when they own navigation.

Run the focused regressions from the repository root with Lua 5.1:

```text
lua tests/lua/quest_order_performance_test.lua
```

Or use the Python runner with `lupa` installed:

```text
.venv/Scripts/python.exe tools/validation/run_lua_tests.py --performance-only
```

For the zone-transition regression alone:

```text
.venv/Scripts/python.exe tools/validation/run_lua_tests.py --zone-performance-only
```

The tests cover frame/font reuse over 30 redraws of 1,000 rows, tooltip and text reset,
coalescing 100 reputation notifications, unchanged completed quest objectives, and the
bounded performance log. They use simulated widgets; they do not measure actual client
rendering latency. The original allocation path was also checked using the Git HEAD
version: 30,000 frames and 150,000 font strings versus 1,000 and 5,000 with reuse.

`zone_transition_performance_test.lua` sends a burst of 100 `ZONE_CHANGED*` events and
asserts that they schedule one Navigation route calculation instead of 100 synchronous
calculations. It also verifies that a simulated 25 ms calculation is recorded as
`ZoneTransitionRouting` in the bounded performance log. A loading-screen transition
also keeps its bounded safety retries, but skips the final three as soon as the first
route check succeeds or produces a valid navigation path.

`navigation_scheduling_test.lua` verifies that ten identical transition
retries reuse one Dijkstra result. A map change, route-step change, cache expiry or
explicit invalidation still forces a fresh path. Captures split the work into
`ZoneRoutingContext`, `ZoneRoutingQuestSync`, `ZoneRoutingZoneCheck` and
`NavigationSearch`.

The scheduler test also renders all 1,224 rows across multiple simulated frames,
checks the 3 ms budget between rows, and checks cancellation/replacement. The budget
cannot interrupt a single expensive row. The hidden buffer fills progressively;
the visible list stays in place until the replacement is complete.
The supplied client capture measured 10 synchronous list rebuilds averaging 76.2 ms
(87.4 ms maximum) despite widget reuse. Rendering now yields between rows and records
`QuestOrderListBatch` per game frame instead of timing an entire synchronous build.

The Python performance-only runner also executes `step_progression_test.lua`. It
skips a Note followed by 1,250 completed QpartPart objectives using the real update
and navigation helpers, then stops on an unfinished objective. It checks deferred
continuation cancellation and recovery after errors. Automatic step updates now
use a reentrancy guard and iterative batches (25 passes or 3 ms between passes),
preventing stack overflow when many steps are already complete. A single pass
cannot be interrupted. Client testing is still needed for scenario transitions.

`python tests/run.py --suite routes` validates Lua syntax, options, types and nested
conditions for every route, with the same schema for every expansion. There are no
guide-specific snapshots. `route_engine_test.lua` exercises parallel groups,
prerequisites, saved aliases and temporary routes using synthetic guides;
`route_conditions_test.lua` tests shared predicates independently of route data.

`level_requirements_test.lua` checks absolute XP offsets through the existing level
resolver: exact boundaries, client-specific XP totals, level filters, display and
missing XP data. It runs alongside the client compatibility checks in the runner.

## In-game capture

`reputation_progress_test.lua` covers current-step bars for standing, renown and
friendship, legacy faction APIs, unavailable data, frame reuse, text resizing and
cleanup. Reputation events continue using the existing coalesced refresh path.

The second client capture confirmed list batches below 3.5 ms, but quest removal
still reached 95 ms. Quest removal now avoids inline navigation and duplicate step
refreshes; combined quest/step updates synchronize the cache before rendering once.
Focused tests cover both paths with changed objectives. Additional measurements
`UpdateStepPass`, `CountSkippedSteps`, `CountTotalSteps`, and `ScheduledNavigation`
separate the remaining work. These nested timings overlap; do not add them together.

1. Update the addon and `/reload` to clear widgets accumulated by the old implementation.
2. Run `/apr perf on` to start a fresh capture.
3. Turn in several quests or reproduce the freeze.
4. Run `/apr perf` to open the dashboard with call counts, total milliseconds, and maximum duration.
5. Run `/apr perf off`, then `/reload` or log out normally to flush SavedVariables.

The capture is saved as `APRData.PerformanceLog` in
`World of Warcraft/_retail_/WTF/Account/<account>/SavedVariables/APR.lua`.
Only that table is needed for diagnosis. It contains aggregate timings and a ring of
at most 100 slow operations (3 ms by default), with the active route and step.
Capturing is off by default and is not automatically re-enabled after a reload.
Starting a new capture replaces only the previous performance log.

CPU capture never calls `UpdateAddOnMemoryUsage` automatically. Use **Measure memory**
on the resource page for an explicit reading, then compare its age/peak with another
manual reading. The scan's blocking duration is included as `ResourceMemoryScan`.
During a scan-free capture, reproduce zone changes and consecutive completed routes:
`NavigationSearch` should reuse ready-zone results within its ten-second TTL, and
the navigation render should not schedule a second immediate route calculation.
Same-map transport paths still require the solver; do not bypass them using map equality.
Compare `StepRenderContent`, `StepRenderCommit`, and `RoutePathUiRefresh` to locate any
remaining client-specific rendering spikes. Automated tests simulate scheduling and
costs; repeat the capture in WoW to measure the actual FPS improvement.

For idle comparisons, keep the same location, FPS cap and visible panels; close the
performance dashboard while capturing. Compare `ArrowPositionUpdate`, `TrackerGeometryProbe`,
`TrackerLayoutUpdate` and `TrackerAppearanceUpdate`. The Lua suites count actual map resolutions,
display writes and complete layout work: unchanged arrows avoid repeated writes, tracker work
is bounded by the one-second safety poll, and changes/combat exits invalidate the idle state.
Move, turn, advance a waypoint, resize the tracker and enter/leave combat after the idle test
to verify guidance and attachment in the client. Displayed CPU percentages depend on frame time.

Recorded operations include event callbacks, deferred quest-log refreshes, coalesced
reputation refreshes, zone-transition routing and quest-order-list rendering. Nested durations overlap and
must not be summed as independent frame time. A frame-interval observer runs only
while capture is active; resource samples run once a second without automatic
memory scans or chat logging. The list renderer uses OnUpdate only while a build is pending.

## Performance audit 30 October 2026

The audit focused on work that can accumulate in one frame: event bursts, route
resolution, navigation action matching, hidden UI builds and diagnostic allocations.
Existing staged work on quest caches, bank refreshes, event lifetimes and XP
overlays was retained. The changes below are additional to that starting state.

### Corrected paths and measured work

Operation counts use invented fixtures in Lua 5.1. They establish removed work,
not a measured FPS increase or a worst-case duration in a running WoW client.

| Controlled workload | Before | After |
| --- | --- | --- |
| 1,000 warm route reads with 60 active parallel groups | 1,000 sorts, 60,000 formats, 1,000 concatenations for cache keys | Zero key sorts, formats or concatenations |
| 1,000 warm scenario reads with 50 steps, two blocks and an active parallel group | 56,000 table insertions and 2,000 sorts | Zero insertions or sorts |
| A second burst of 500 player casts over 1,002 synthetic transport connections | 500,500 reads of absent route-action fields across the catalogue | Zero catalogue-field reads after the initial index |
| 100 progress changes while a 1,200-step list is collapsed | Background preparation could continue or restart | Zero visibility scans and no pending model build; reopening publishes current progress |
| 20 simulated seconds with the guide hidden or detached | Repeated appearance safety polls | Zero recurring appearance polls after one possible restoration |
| Formatting a two-million-byte diagnostic string | Full-string substitutions before output truncation | At most 240 input bytes passed to sanitization |

`RouteManager` compares saved activation snapshots without constructing textual
keys on every hit. Parallel definitions reuse their filtered group array.
`DelveRoutes` returns its validated read-only scenario blocks and checks scenario
membership without building a sorted ID list. Flattened scenario steps retain
only two variants per block collection: all blocks and the latest selection.
This also fixes stale effective steps when switching between equally sized
scenarios with active parallel groups. Direct saved-state changes, source
replacement and explicit invalidation remain covered.

`TravelActions` indexes the route-action subset once, retaining definition
references and resolving selected items' effects from live client data. Appending
connections or replacing their array rebuilds the index. Navigation frames use
player-scoped spell registrations where available and retain Lua filtering for
fallback clients. Ordinary casts already avoided graph invalidation before this
audit; the improvement concerns event delivery and catalogue traversal.

`QuestOrderList` cancels pending rendering and scrolling on collapse, preserves
the last complete model, and rebuilds from current progress on expansion.
`QuestTracker` suspends external appearance polling when its guide is hidden or
detached. Diagnostic string truncation now precedes sanitization, preserving the
previous output while avoiding full-payload copies.

### Coverage and retained safeguards

Both client manifests were followed through nested XML includes. All 127
APR-owned Lua modules outside locales/libraries are reachable; none was identified
as an orphan. At this audit snapshot, Retail loads 48 route files (7,434,296 source
bytes) and Forever 96 (7,562,519 source bytes). These are inventory observations,
not test expectations or estimates of runtime memory. Client route separation and
the existing release exclusions for unused library modules remain in place.

The reviewed navigation planner/search/catalogue pipelines already have cooperative
budgets and cancellation. Quest/event work already coalesces bursts and reuses
records. The visible list is recycled, party queues/caches are bounded, and CPU
capture does not automatically run the native memory scan. Third-party libraries
were not modified. No SavedVariables schema, route content or translation keys
were changed by this audit.

The unit-event contract was checked against Blizzard's generated frame API for
[11.2.7](https://github.com/Gethe/wow-ui-source/blob/11.2.7/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua)
and [12.0.0](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua),
and Blizzard's spell-sequence handler for
[12.0.1](https://github.com/Gethe/wow-ui-source/blob/12.0.1/Interface/AddOns/Blizzard_ChatFrameBase/Shared/CastSequenceManager.lua),
[12.0.5](https://github.com/Gethe/wow-ui-source/blob/12.0.5/Interface/AddOns/Blizzard_ChatFrameBase/Shared/CastSequenceManager.lua),
[12.0.7](https://github.com/Gethe/wow-ui-source/blob/12.0.7/Interface/AddOns/Blizzard_ChatFrameBase/Shared/CastSequenceManager.lua),
[12.1.0](https://github.com/Gethe/wow-ui-source/blob/12.1.0/Interface/AddOns/Blizzard_ChatFrameBase/Shared/CastSequenceManager.lua)
and [12.1.5](https://github.com/Gethe/wow-ui-source/blob/12.1.5/Interface/AddOns/Blizzard_ChatFrameBase/Shared/CastSequenceManager.lua).
The [Classic handler](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_ChatFrameBase/Shared/CastSequenceManager.lua)
also uses player-scoped spell events. Forever's custom 16001 client retains the
explicit fallback; native rendering and client-specific behavior still require
an in-game check. The other changes use existing frame methods and Lua operations.

### Remaining cases to measure in game

Cooperative budgets cannot interrupt an individual native API call, string-height
measurement or C sort. An exceptionally long single label can therefore exceed
a list-render budget. Initial travel-action indexing, navigation instance copies
and the first full mount-journal search also remain synchronous. The subsequent
passes below address repeated mount searches and temporary prefixes, and yield
inside dense rows. Remaining native-call costs need real client captures before
a larger architectural change is justified.

Warm route caches still compare references linearly to detect in-place edits;
they are not constant-time lookups. The transport index assumes structural changes
use instance creation or array extension/replacement, as production does.
An explicit **Measure memory** action can stall inside `UpdateAddOnMemoryUsage`;
it remains user-triggered and its duration is recorded. Debug tracing and the
dashboard add their own overhead while enabled.

On Retail and Forever, compare a scan-free `/apr perf on` capture with debug off
and the dashboard closed: combat casts, rapid pickups/turn-ins, scenario changes,
collapsed/expanded lists, tracker attachment, bank access, teleport/flight arrivals
and loading screens. Stop with `/apr perf off`. Inspect individual slow calls
and previous-frame APR root work; a global slow frame alone does not prove APR
caused it. Keep FPS cap, location and other addons consistent between captures.

### Follow-up on startup inventory groups and diagnostic UI

The next pass covered startup suggestions, inventory labels and valuation,
AFK layout notifications, party membership checks, companion filtering and the
performance viewer. Operation counts below use independent synthetic fixtures.

| Controlled workload | Before | After |
| --- | --- | --- |
| Text for 20 inventory-action items across 200 slots | 4,000 container item reads | 200 reads, one snapshot local to the render |
| Resale estimate for 200 identical stacks plus equipped copies | 201 item-price queries | One query for the exact variant in that estimate |
| 1,250 AFK hides with no active timer | 1,250 deferred callbacks | Zero callbacks |
| 50 rapid AFK show/hide/hide cycles | 150 callbacks | One coalesced child-layout refresh |
| 500 party packets in one frame | 2,000 native unit-name reads | Four reads, with immediate refresh on roster notifications |
| Language filtering for 200 companion candidates | 600 normalizations and 601 sorts | Two normalizations and three sorts |
| Startup index over 3,000 steps without quest triggers | 6,000 synchronous step-field reads | Zero during initialization; work resumes in at most 64 operations or a 1 ms cooperative slice |
| Warm live-viewer refresh with 1,200 metric rows | 1,200 newly allocated metric row tables | Reuse of the same viewer-owned row objects |
| Uniform publication of 1,200 metric rows | A dense 1,201-entry offset array | One sentinel offset; indexed access serves the viewport |
| 100 refreshes of an unchanged stopped capture | 100 repeated row constructions and list publications | Zero repeated row constructions/publications |

Inventory counts and item prices are cached only inside their current render or
estimate. The next call reads fresh bags, bank availability and late item data;
different exact item links retain different prices. Future action previews do
not inspect today's inventory. AFK updates now ignore an already inactive timer
and share one pending layout callback across visibility changes.

Party membership reuse lasts only for the current frame timestamp, and explicit
roster updates, party/raid changes, leaving the group and resets invalidate it.
Realm-specific sender validation remains unchanged. Companion language preferences
are compiled once per list refresh; accepted, blocked, bilingual and unknown
languages retain their previous behavior.

A further confirmed spike came from incomplete hyperlink/texture tags in party
tooltip data. Unanchored non-greedy Lua patterns retried from each opener, producing
quadratic work even within the existing message-size budget. The replacement
scans forward without retrying an unmatched suffix and preserves the old output.
On the audit host, 30 repetitions of a synthetic 20-line, 1,000-byte-per-line
snapshot averaged 20.77 ms for incomplete links and 31.50 ms for incomplete art
before the change, and about 0.90 ms for each afterward. These host timings are
indicative, not WoW frame measurements. Regression tests assert linear scan work
and independently chosen text outputs; an additional read-only comparison of
20,000 generated strings produced identical old/new text.

Startup suggestion indexing keeps incoming quest IDs until the full index is
ready, then rechecks current addon preferences and active-route state before
showing choices. Reinitialization cancels stale continuations. A worker failure
reports the error and clears its partial index; a later initialization can recover.
The timer contract was checked in Blizzard's generated documentation for
[11.2.7](https://github.com/Gethe/wow-ui-source/blob/11.2.7/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua),
[12.0.0](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua),
[12.0.1](https://github.com/Gethe/wow-ui-source/blob/12.0.1/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua),
[12.0.5](https://github.com/Gethe/wow-ui-source/blob/12.0.5/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua),
[12.0.7](https://github.com/Gethe/wow-ui-source/blob/12.0.7/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua),
[12.1.0](https://github.com/Gethe/wow-ui-source/blob/12.1.0/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua),
[12.1.5](https://github.com/Gethe/wow-ui-source/blob/12.1.5/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua)
and [Forever 1.60.1](https://github.com/Gethe/wow-ui-source/blob/1.60.1/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua).

Viewer row reuse is opt-in: ordinary diagnostic exports still receive independent
snapshots. Slow-call and journal records are not recycled as metric rows. Stopping
capture publishes final measurements once; search, mode, log replacement and reset
still refresh the view. The row sort remains synchronous during live capture.
Party deserialization and progress-distance calculations also remain synchronous
within their existing bounded inputs. No third-party libraries, SavedVariables
schema, authored route content or translation keys changed in this follow-up.

### Follow-up on dense rows temporary routes mounts and font callbacks

The third pass removes work that still escaped the existing frame budgets, plus
a Lua 5.1 diagnostic lifetime leak. Every fixture uses invented steps, scenarios,
mounts or workers; no shipped itinerary is required to retain a particular shape.

| Controlled workload | Before | After |
| --- | --- | --- |
| 1,000 warm temporary-route reads with an inserted parent prefix | 1,000 effective-route misses/reconstructions and 1,000 sorts | 1,000 hits, zero reconstructions or sorts |
| One mount lookup plus 100 replans over a 1,000-entry skyriding journal | 101 list requests and 101,000 usability reads | One list request, 1,100 usability reads and 100 ownership revalidations |
| The equivalent ground-mount workload | 101 list requests and 101,000 information reads | One list request and 1,100 information reads |
| 300 pending objectives from one quest in a preview row | 300 native objective-table requests | One native request per quest within that row build, including missing data |
| 200 release-note font callbacks | 40,000 row-height measurements | One deferred layout with 200 measurements |
| 200 diagnostic workers, half completed and half abandoned | All 200 retained after collection | All 200 collectible; caller-owned suspended workers remain usable |

The dense-row fixture assigns deterministic costs to API calls, font creation,
text updates and measurements. With the same synthetic clock and 300 objectives,
the indexed baseline's largest model batch was 255.40 ms and first viewport batch
165.60 ms. The new first build recorded 3.25 / 2.10 ms. Across cancellation and
failure recovery, the regression fixture's maxima are 3.40 / 2.40 ms: the existing
3 ms / 2 ms cooperative budgets plus one small atomic operation. These values
describe the controlled clock, not elapsed CPU time or a real WoW frame.

Construction now yields between objectives and measured sub-lines. Viewport
binders can explicitly report an unfinished row; ordinary binders returning nil
retain their original contract. An incomplete row stays hidden, and `model.frame`
is published only on completion. Recycled rows, generations and changed model
state discard stale work. Color changes and collapsing a published model also
reuse the viewport budget instead of changing every font inline. The fixture
checks stale scrolling, partial measurement, buffer reuse and recovery after both
model and viewport errors, including execution with diagnostics enabled.

Temporary-route prefixes retain one snapshot for the active session. Parent and
scenario references, range boundaries, character and imported state are checked
on reuse. Parent/temporary/global invalidation and clearing the session release
the snapshot. Only a candidate mount ID is retained for repeated capability
checks: native ownership and usability are observed again before reuse. Rejected
or unknown observations fall back to the full search. The cold search remains
synchronous and the existing short ground-capability TTL is unchanged.

Release-note font callbacks and resize bursts now schedule one layout for their
final metrics. Hidden readers do no background measurement. Explicit content
publication and reopening still measure immediately and invalidate stale queued
callbacks. The Lua 5.1 diagnostic registry previously stored its coroutine key
again inside the weak table's value, preventing that key from being collected.
The context now stores only the boolean distinction from the main thread; its
timing, pause and resume behavior are unchanged. Explicit collections occur only
in the regression test, never in addon runtime code.

Blizzard's frame and mount-journal contracts were checked at all eight declared
client tags: 11.2.7, 12.0.0, 12.0.1, 12.0.5, 12.0.7, 12.1.0, 12.1.5 and 1.60.1.
The generated declarations include the frame visibility query and the collected
flag returned by mount information. See the
[Retail frame API](https://github.com/Gethe/wow-ui-source/blob/12.1.5/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua),
[Forever frame API](https://github.com/Gethe/wow-ui-source/blob/1.60.1/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua),
[Retail mount API](https://github.com/Gethe/wow-ui-source/blob/12.1.5/Interface/AddOns/Blizzard_APIDocumentationGenerated/MountJournalDocumentation.lua)
and [Forever mount API](https://github.com/Gethe/wow-ui-source/blob/1.60.1/Interface/AddOns/Blizzard_APIDocumentationGenerated/MountJournalDocumentation.lua).
The optional visibility fallback and unavailable/opaque mount-data guards remain
explicit. This pass adds no translated UI text or SavedVariables schema changes.

### Follow-up on startup validation catalogue alternatives and text parsing

The fourth pass addresses work inside operations that were already scheduled,
but could still monopolize one frame. All measurements below use synthetic input.

| Controlled workload | Before | After |
| --- | --- | --- |
| Startup scan containing a 4,096-byte synthetic note, charging 0.01 ms per hashed byte | One 41.25 ms batch | 17 batches, largest 2.65 ms on the controlled clock |
| One directional gamepad input among 200 controls in two nested scroll frames | 805 rectangle queries | 207 queries, including revealing the selected control |
| A 1 ms catalogue-preparation slice with 500 alternatives costing 0.25 ms each | 500 probes, 125 ms on the controlled clock | At most four probes, 1 ms on the controlled clock |
| Parsing 8,000 unmatched Markdown link openers | About 807 ms on the audit host | Less than 1 ms on the audit host |
| Parsing a heading containing 8,000 spaces without closing hashes | About 714 ms on the audit host | About 1 ms on the audit host |

Startup route validation now runs in cooperative 2 ms batches. Key enumeration
and strings longer than 128 bytes have checkpoints. The hash arithmetic,
delimiters, key order and historical signed hexadecimal formatting are unchanged;
there is no SavedVariables schema migration or forced fingerprint reset. Golden
fixtures cover the historical LuaBitOp double-number conversion. An independent
comparison of 200 generated routes produced identical synchronous and suspended
signatures, including 12,904 checkpoints.

The scan prepares every result before changing saved progress. Character/data
replacement, removed signature/completion tables and replaced route components
retire an obsolete scan. Explicit route selection, reset and clear intentions
survive suspension, cancellation and resumption. The actual settings toggle
resumes an interrupted scan without requiring gameplay-event registration.
Failure publishes no partial cleanup and has one automatic retry; continued
failure keeps automation suspended until an explicit retry or re-enable.

Gameplay observations remain active during validation. Step progression, route
rendering and automated NPC/taxi actions wait for validated state. Obsolete
timers cannot release a newer job or reactivate an old selection. Native
completion events retain at most one deferred advance for the current context;
100 duplicates still advance once, while a reset or changed definition rejects
the old completion. Visible NPC pages reconcile with fresh state after validation.
Escort confirmation timers also recheck validation, route context, preferences
and modifiers immediately before accepting.
Native calls, table sorting and the final saved-state publication remain atomic;
the cooperative budget is not a hard real-time guarantee.

Gamepad navigation observes one fresh layout per input. Candidates are measured
once and shared viewport rectangles are reused for that input only. The selected
control is measured again during reveal, so scrolling, movement and independent
scales remain current. Direction scoring and clipping rules are unchanged.

Catalogue preparation yields between action alternatives. It still selects one
action for both directions, preserves priority and random selection, and retains
its per-build observation snapshot. Cancellation releases the suspended work.
Definitions with zero or one alternative keep their direct path. Requirements
inside one alternative and native API calls remain atomic operations.

The Markdown parser previously retried unmatched opening brackets and long
whitespace runs at every possible starting point. Forward link scanning and a
backward closing-heading scan remove those quadratic paths. Regression tests
assert work counts and independently chosen output, including malformed text,
links, code spans, escapes and UTF-8. A separate comparison of 20,000 generated
inputs produced identical old/new output. The host timings above are indicative;
they are not measurements of a WoW frame.

No new WoW API is introduced. The existing rectangle and effective-scale
contracts were checked in Blizzard's generated declarations at all eight client
tags listed above; they include missing rectangle results and modern secret-value
annotations. See the
[Retail geometry contract](https://github.com/Gethe/wow-ui-source/blob/12.1.5/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScriptRegionAPIDocumentation.lua),
[Forever geometry contract](https://github.com/Gethe/wow-ui-source/blob/1.60.1/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScriptRegionAPIDocumentation.lua)
and [effective-scale contract](https://github.com/Gethe/wow-ui-source/blob/12.1.5/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua).
The gamepad change reads the same addon-owned controls and retains its existing
combat guard. This pass changes no third-party library or translated UI text.

### Automated validation

After the fourth pass, `.venv/Scripts/python.exe tests/run.py` ran 506 tests:
505 passed and one errored.
All Lua regressions, including instrumentation and the new performance fixtures,
passed. Additional runs exercised startup suggestions, party text, companion
filters, inventory actions and reusable metric rows with diagnostic tracing
enabled. The dense-row, coroutine-lifecycle and startup-validation tests also
enable diagnostic capture to check coroutine behavior. The error at that stage was
`PartyFinderLocalizationTests.test_declared_locales_cover_companion_strings_and_preserve_formats`:
it extracts literal `L["GF_..."]` assignments from locale source files, but this
checkout contains packager localization directives instead. Parsing the resulting
empty English catalogue raises `CatalogParseError`. The test, parser and English
source are unchanged between HEAD, the initial index and the audited worktree;
the same extraction fails in all three. No assertion was removed or relaxed.

On the managed Windows test host, temporary files were directed to
`.cache/audit-test-temp`. The complete run required execution outside the network
sandbox because Python's asyncio self-pipe blocked in its local socket accept;
the actual test suite and its mocked remote calls were unchanged.

## Cross-module addon journey validation

The performance changes are also exercised as complete invented journeys, with
changing player/native state rather than a fixed shipped guide. The existing
behavior suites remain in place; the journey fixtures connect their module
boundaries and check independently chosen progression and cancellation results.

| Area | Journey coverage |
| --- | --- |
| Quests and suggestions | `addon_quest_journey_test.lua` and `test_addon_journey_quest.py`: native acceptance before indexing, suggestion/popup selection, opt-out, real conditions/cache/rendering, turn-in and next pickup, missing native records, duplicate/foreign events and stale choices |
| Fillers and startup | The widget journey uses real CurrentStep/FillersFrame rows, conditional parallel insertion, filler completion without main-step advancement, actual signature validation, cancellation/resumption and one coalesced native completion |
| Groups and companion discovery | `group_instance_journey_test.lua`: real Party/Finder/World/Invites, codecs and core dispatch; private/world queries, invitation/nonce/roster, party/instance channels, raid conversion, queued-message cancellation, disable/re-enable |
| Instance lifecycle | The group journey uses real RouteManager/StepTransitions/DelveRoutes for party instances, scenarios, delves and raids; early/complete exit, missing loading map, session reload and parent/custom-path restoration |
| Navigation | `navigation_journey_integration_test.lua`: real controller/adapter/planner/taxi/library on Retail/Forever profiles; denied access, wrong world/zone, movement, geometry invalidation, burst coalescing, manual taxi, portals, combat, teleport/loading, cooldowns, death and cancellation |
| Conditions and objective actions | Existing synthetic `route_conditions`, `route_engine`, `reward_groups`, `native_route_actions`, `step_progression` and dungeon suites remain required alongside the journeys |

The journey uncovered a taxi defect already present in HEAD: manual boarding
could be observed before an off-taxi origin poll, setting `boarded` without
`departureSeen`. Arrival then could not finish that leg. Native boarding now
records both facts. Reinjecting the old branch in memory fails the new regression;
the corrected branch passes. A wrong destination still cannot complete travel.

The common quest-chain path was also replayed in memory against HEAD and the
working sources, with identical independently asserted business states. That
comparison excludes intentional differences in asynchronous publication, cache
object identity, startup suspension and the old empty-objective refresh behavior;
the committed current-source tests retain those stronger checks separately.

The previous localization-suite error was a source/package contract mismatch:
repository locales contain CurseForge directives, not expanded dictionaries.
The offline test now verifies those bindings separately and uses recorded
CurseForge companion exports for every discovered locale. Cross-locale keys,
printf arguments, line breaks and WoW markup keep their original assertions;
invalid printf output, current static references and negative fixtures add checks.
The snapshots contain only `GF_*` strings and no guide content. Current remote
translator edits still belong to translation CI, not these offline snapshots.

Native APIs and widgets are simulated. These tests establish addon behavior and
contracts under controlled observations; they cannot certify actual client
rendering, taint/secret-value enforcement, channel delivery or real frame time.
No authored route changes belong to the runtime-fix commits or push.

The fresh independent review repeated `.venv/Scripts/python.exe tests/run.py`
from zero: **512 tests passed in 107.478 seconds**, with no failures or errors.
Three independent reviews covered quest/startup state, navigation/groups and
UI/diagnostics/localization. Additional focused runs passed, and 40,000 synthetic
Markdown inputs retained the baseline parser output. Reinjecting only the old
taxi boarding branch in memory failed the new departure regression; both client
profiles passed with the correction, including wrong-destination rejection.
Instrumentation consistency passed for 2,877 definitions across 115 files.
The authorized runtime/test commits exclude the local `Routes/` changes.

## Additional lag-spike pass

This pass closes two nested operations that escaped cooperative budgets and
removes repeated work in guide-action registration and group snapshots. No
third-party library, authored guide, translation or SavedVariables schema changed.
The changes use existing APIs; the new scheduling/indexing logic is ordinary Lua.

| Controlled workload | Before | After |
| --- | --- | --- |
| One 1 ms search slice comparing arrivals with 500 resources, charging 0.25 ms per resource observation | 125.25 ms on the controlled clock | At most 1.25 ms, including one small atomic observation |
| Display-name resolution among 2,003 declarations at 0.02 ms per visited entry | One 40.06 ms operation inside startup validation | 20 cooperative batches, largest 2.02 ms; total scan work remains 40.06 ms |
| A group tooltip with 3,000 populated rows | 6,000 font reads and 3,000 rows sorted before the tooltip is discarded | 129 font reads, no sort; the entire oversized tooltip is still omitted |
| 100 warm re-registrations of 200 action buttons | 2,090,000 retained-registry visits | Zero registry visits, sorting or secure writes |

Resource dominance now advances through resource keys as part of `Search:Step`,
without allocating a coroutine or comparison table. Empty/one-resource and
scalar rejection paths finish inline. A controlled ordinary 80-node/18-action
workload used the same 5,625 operations before and after. Exhaustive route
oracles, reverse pruning, preserved consumables and cancellation retain their
behavior. Initial isolated instance copies and native calls remain atomic.

Route-label resolution selects the same lexical/visible variant in one scan
without sorting. Exact keys retain their direct path, and only duplicate labels
need candidate records. Startup callers pass checkpoints through the lookup.
Candidate identities, aliases and catalogue replacement are rechecked; custom
imports increment a session revision so a retired lookup restarts through the
existing startup worker before publishing saved state. There is no persistent
label cache. Ordinary synchronous lookups still traverse the current catalogue.

The group sender passes its existing 128-row/2,048-byte limits into snapshot
construction. Overflow retains authoritative progress and discards the entire
optional tooltip, matching its existing wire behavior. Ordinary exports remain
complete and independent. A wire comparison under the limits was byte-for-byte
identical to HEAD. On the audit host, 30 repetitions of the dense fixture averaged
18.929 ms before and 0.036 ms after; these are indicative host timings, not WoW
frame measurements. Containers with no emitted text still need to be visited.

The gamepad membership index shares the retained button registry's lifetime.
Priority sorting, action-kind changes, scalar secure attributes, hardware click
dispatch and combat guards are unchanged. First registration or rebinding still
sorts and republishes frame references; the secure click-time scan is necessary
and remains in place.

Focused tests include instrumented execution with diagnostic/performance capture
enabled. The four new fixtures use invented data, exact boundaries and failure
recovery; no maintained route is frozen as expected output.
The full `.venv/Scripts/python.exe tests/run.py` run passed **520 tests** in
107.629 seconds, with no failures or errors. Generated instrumentation is current
for 2,912 definitions across 117 files, and `git diff --check` is clean.

## Guide layout and map lifecycle pass

This pass removes retained map frames, repeated marker refreshes, repeated
objective layout and exponential prerequisite traversal. All fixtures use
invented data; no authored guide, translated text, third-party library or
SavedVariables schema changed.

| Controlled workload | Before | After |
| --- | --- | --- |
| Advance 200 steps while displaying five world and two minimap markers | 405 marker frames created/retained | Seven marker frames reused |
| 200 quest/addon-map notifications before one existing animation pass | 200 marker rebuilds | One rebuild using final state |
| One refresh changing 100 main objectives and 100 fillers | 300 layout publications, 20,100 height measurements, 100 arrow-text refreshes | Two publications, 300 measurements, one arrow-text refresh |
| Add an invented prerequisite graph containing 25 declarations and 12 shared diamonds | 8,191 expansions | 25 expansions, same path and ordering |

Authored map markers are pooled by simultaneous visible slot, separately for
world/minimap/guidance, instead of retaining each step number ever displayed.
Each reuse replaces the step, filtered number and tooltip source. Pools grow
only when the required simultaneous display count grows. Quest/message bursts
share the existing 0.1-second map animation; direct settings/geometry refreshes
consume pending work, and pre-initialization calls retain their immediate path.
No additional timer or worker was introduced.

Quest cache and text updates remain synchronous. A nested update counter merges
their layout and arrow-text publications after successful synchronization.
Errors release the guard and preserve pending work for recovery; an existing
content transaction keeps ownership of its final publication. Combat deferral
is preserved. After changed combat content leaves geometry pending, 30 unchanged
refreshes perform zero layout, measurement, filler-refresh or arrow-text work.
When `UpdateStep` exhausts its pass budget, the cache batch also leaves geometry
to the pending continuation. A regression using the real scheduler runs 25 passes
without publication, then five more and one final main/filler layout. The final
content owner clears the batch requests. The pre-fix branch fails that regression.

Prerequisite traversal retains its visited set for one operation, rather than
forgetting completed branches on each recursive return. A new call gets a fresh
set and reevaluates eligibility/completion. Cycles, absent dependencies, shared
labels and Forever completion gates keep their prior behavior. At a controlled
0.05 ms per expansion, the diamond fixture falls from 409.55 ms to 1.25 ms;
these are simulated costs, not elapsed WoW time.

Navigation preparation/search/taxi stages were reviewed again without finding
another demonstrated cause warranting a change. Initial isolated instance
copies, native taxi signatures and individual large condition/diagnostic calls
remain atomic. They require real-client captures before a broader redesign is
justified. Ordinary long-route prefix filtering for marker numbering also
remains synchronous; this pass reduces its repeated invocation and retained pins.
The full `.venv/Scripts/python.exe tests/run.py` run, including the continuation
regression, passed **523 tests** in 112.038 seconds on a fresh validation, with
no failures or errors. Three completed independent reviews and focused execution
covered continuation ownership, quest/group/navigation journeys, nested/error/combat
layout recovery and debug/performance capture. Substituting the pre-fix source
in memory fails the intermediate-publication assertion. Generated instrumentation covers
2,916 definitions across 117 files and `git diff --check` is clean.

## Navigation catalogue review

Navigation catalogue research, generation and static data audits live in
`Route-generator/tools/validation/navigation_data` in the route-gen repository.
APR's runtime tests and CI do not depend on that checkout.
