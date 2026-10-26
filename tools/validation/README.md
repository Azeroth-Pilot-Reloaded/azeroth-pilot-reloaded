# Route performance checks

All regression tests now live in `tests/`. Run `python tests/run.py` for all
Python, Lua and route syntax checks; see `tests/README.md` for dependencies and CI.

## Whole-addon diagnostics

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
4. Run `/apr perf` to print call counts, total milliseconds, and maximum duration.
5. Run `/apr perf off`, then `/reload` or log out normally to flush SavedVariables.

The capture is saved as `APRData.PerformanceLog` in
`World of Warcraft/_retail_/WTF/Account/<account>/SavedVariables/APR.lua`.
Only that table is needed for diagnosis. It contains aggregate timings and a ring of
at most 100 operations lasting at least 10 ms, with the active route and step.
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
must not be summed as independent frame time. No per-frame polling or chat logging
is performed during capture. The list renderer uses OnUpdate only while a build is pending.

## Navigation catalogue review

Navigation catalogue research, generation and static data audits live in
`Route-generator/tools/validation/navigation_data` in the route-gen repository.
APR's runtime tests and CI do not depend on that checkout.
