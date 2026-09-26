# Route performance checks

## Automated validation

Pull requests run the full Lua validation suite and a non-uploading package build
in the `Validate addon` workflow. The workflow verifies the generated package
with `check_package.py`, including client-specific TOCs, route manifests, and
the exclusion of local tooling.

Before running the packager locally, generate the ignored client TOCs:

```text
python tools/package/generate_client_tocs.py
```

`APR_Mainline.toc` and `APR_Camelot.toc` preserve the Retail and Forever route
manifests respectively. The packager copies both generated files into the
single addon release.

BigWigs' packager requires a normal clone whose `.git` is a directory; linked
worktrees use a `.git` file and are not supported by its repository detection.
Do not weaken the package check for worktrees. From a normal clone with the
packager available, run:

```text
python3 tools/package/generate_client_tocs.py
<path-to-bigwigs-packager>/release.sh -d
python3 tools/validation/check_package.py .release/APR
```

After automated and package validation, smoke-test the generated addon in both
Retail and Forever clients. At minimum, load the addon, start a route, advance
a quest step, verify route/arrow navigation, and exercise a Hearthstone or
travel action. Lua mocks cannot validate client API behavior, frame templates,
or protected-combat behavior.

The arrow-frame regression loads `Arrow.lua` with WoW-like global frame-name
checks, ensuring its movable anchor and visible arrow never reuse a name.

Current-step rendering regression:

```text
lua tools/validation/current_step_render_test.lua
lua tools/validation/route_panels_render_test.lua
# All focused UI checks using the Lua 5.1 runtime from lupa:
.venv/Scripts/python.exe tools/validation/run_lua_tests.py --ui-only
```

The test loads the frame and row modules and runs 100 identical content passes.
It checks zero additional frame/font allocations, no row/action hide calls, one
layout per pass, updated tooltips, wrapping, route progress reuse, collapse state,
percentage labels, and secure-row replacement and cleanup across combat. The
Python runner runs it before the route checks. Widget mocks do not validate the
client's rendering or taint system: also check a long objective, a pickup list,
image previews, collapse/expand, and an item-use step during combat in game.

`CurrentStep.lua` owns the window, progress bars and secure controls;
`CurrentStepRows.lua` owns keyed rows, reconciliation and layout. `UpdateStep`
brackets each pass with `BeginContentUpdate` / `EndContentUpdate`. During a pass,
removal marks old rows; add/update calls retain rows with matching keys and kinds;
the successful final pass retires untouched rows and positions the result once.
An interrupted pass retains the previous content. Callers outside a pass still
get immediate updates. Protected rows are retired by frame identity and deferred
anchors are applied after combat, so reusing a key cannot destroy its replacement.

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
lua tools/validation/client_compatibility_test.lua
python tools/validation/check_package.py PATH_TO_UNPACKED_APR
```

The package check expects a single release containing the generated Mainline and
Camelot TOCs. It verifies separate route manifests and exclusion of local tooling.
The Lua check covers hidden incompatible routes, saved imports, prefab popups and
missing Retail APIs/events. These mocks do not replace an in-game Forever smoke test.

Run the focused regressions from the repository root with Lua 5.1:

```text
lua tools/validation/quest_order_performance_test.lua
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
asserts that they schedule one Farstrider route calculation instead of 100 synchronous
calculations. It also verifies that a simulated 25 ms calculation is recorded as
`ZoneTransitionRouting` in the bounded performance log. A loading-screen transition
also keeps its bounded safety retries, but skips the final three as soon as the first
route check succeeds or produces a valid navigation path.

`farstrider_routing_performance_test.lua` verifies that ten identical transition
retries reuse one Dijkstra result. A map change, route-step change, cache expiry or
explicit invalidation still forces a fresh path. Captures split the work into
`ZoneRoutingContext`, `ZoneRoutingQuestSync`, `ZoneRoutingZoneCheck` and
`FarstriderFindTrailTo`.

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

The default runner always checks the Midnight route registration. When the optional,
locally maintained `docs/routes/2393-Midnight-Speedrun-alt-quests.csv` snapshot is
present, it also audits quest prerequisites and objective order against that file.
Fresh checkouts skip only this snapshot audit. The performance-only option skips the
route-specific checks entirely.

`xp_requirements_test.lua` checks absolute XP offsets through the existing level
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

Recorded operations include event callbacks, deferred quest-log refreshes, coalesced
reputation refreshes, zone-transition routing and quest-order-list rendering. Nested durations overlap and
must not be summed as independent frame time. No per-frame polling or chat logging
is performed during capture. The list renderer uses OnUpdate only while a build is pending.
