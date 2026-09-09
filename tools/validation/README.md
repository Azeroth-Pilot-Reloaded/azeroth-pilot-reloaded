# Route performance checks

Run the focused regressions from the repository root with Lua 5.1:

```text
lua tools/validation/quest_order_performance_test.lua
```

Or use the Python runner with `lupa` installed:

```text
.venv/Scripts/python.exe tools/validation/run_lua_tests.py --performance-only
```

The tests cover frame/font reuse over 30 redraws of 1,000 rows, tooltip and text reset,
coalescing 100 reputation notifications, unchanged completed quest objectives, and the
bounded performance log. They use simulated widgets; they do not measure actual client
rendering latency. The original allocation path was also checked using the Git HEAD
version: 30,000 frames and 150,000 font strings versus 1,000 and 5,000 with reuse.

The scheduler test also renders all 1,224 rows across multiple simulated frames,
checks the 3 ms budget between rows, and checks cancellation/replacement. The budget
cannot interrupt a single expensive row. The list fills progressively while rendering.
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

## In-game capture

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
reputation refreshes and quest-order-list rendering. Nested durations overlap and
must not be summed as independent frame time. No per-frame polling or chat logging
is performed during capture. The list renderer uses OnUpdate only while a build is pending.
