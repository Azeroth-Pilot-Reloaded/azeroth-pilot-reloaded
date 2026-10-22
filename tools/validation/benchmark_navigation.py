"""Measure navigation preparation and search with Lua 5.1 and a precise clock.

Run from any directory with ``py -3 tools/validation/benchmark_navigation.py``.
The JSON output describes the current checkout only. Client APIs are fixtures;
these measurements do not replace profiling inside WoW.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from statistics import median
from time import perf_counter_ns

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[2]


def milliseconds() -> float:
    return perf_counter_ns() / 1_000_000


def new_runtime() -> LuaRuntime:
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.globals().python_clock = milliseconds
    runtime.execute("function benchmarkClock() return python_clock() end")
    return runtime


def percentile(values: list[float], fraction: float) -> float:
    """Interpolate between adjacent observations instead of selecting a bucket."""
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (position - lower)


def timed_job(factory, options) -> dict:
    started = milliseconds()
    job = factory()
    created = milliseconds()
    slices = []
    operations = 0
    reports_operations = False
    while True:
        slice_start = milliseconds()
        returned = job.Step(job, options.max_operations, options.slice_ms)
        slices.append(milliseconds() - slice_start)
        if job.workLastStep is not None:
            operations += job.workLastStep
            reports_operations = True
        state = returned[0] if isinstance(returned, tuple) else returned
        if state != "planning":
            break
        if len(slices) > 1_000_000:
            raise RuntimeError("Navigation job did not finish after one million slices")
    if state != "ready":
        raise RuntimeError(f"Navigation job ended with {state!r}")
    return {
        "creation_ms": created - started,
        "total_ms": milliseconds() - started,
        "slice_ms": slices,
        "operations": job.operations if job.operations is not None else (operations if reports_operations else None),
    }


def capture_counters(counters) -> dict[str, int]:
    return {str(key): int(value) for key, value in counters.items()}


def summarize(runs: list[dict], **description) -> dict:
    slices = [elapsed for run in runs for elapsed in run["slice_ms"]]
    counter_names = sorted({name for run in runs for name in run["api_calls"]})
    operations = [run["operations"] for run in runs if run["operations"] is not None]
    return {
        **description,
        "runs": len(runs),
        "creation_ms_median": round(median(run["creation_ms"] for run in runs), 4),
        "total_ms_median": round(median(run["total_ms"] for run in runs), 4),
        "slice_count": len(slices),
        "slices_per_run_median": median(len(run["slice_ms"]) for run in runs),
        "slice_ms_p50": round(percentile(slices, 0.50), 4),
        "slice_ms_p95": round(percentile(slices, 0.95), 4),
        "slice_ms_max": round(max(slices), 4),
        "operations_median": median(operations) if operations else None,
        "api_calls_median": {
            name: median(run["api_calls"].get(name, 0) for run in runs)
            for name in counter_names
        },
    }


TAXI_FIXTURE = """
local counters = {}
local function count(name) counters[name] = (counters[name] or 0) + 1 end
local function noop() end
function LibStub()
    return { GetLocale = function()
        return { USE_FLIGHTPATH = "Fly to %s", NAVIGATION_CONSULT_TAXI = "Consult the flight master" }
    end }
end
function CreateFrame() return { SetScript = noop } end
APR = { PlayerID = "navigation-benchmark" }
function APR:NewModule() return {} end
function APR:GetGameVersion() return "retail" end
function APR:HasTaxiNode() count("discovery"); return true end
APRData = { [APR.PlayerID] = {} }
local paths = {}
for id = 1, 4000 do
    local from = ((id - 1) % 200) + 1
    local offset = math.floor((id - 1) / 200) + 1
    paths[id] = { fromNodeID = from, toNodeID = ((from + offset - 1) % 200) + 1,
        durationSeconds = 30, basePriceCopper = 50 }
end
local source = { profile = "retail", build = "benchmark", paths = { fingerprint = "fixture" } }
LibTaxiData_API = {
    GetSource = function() count("source"); return source end,
    GetAllPaths = function() count("paths"); return paths end,
    GetNodeWorldPosition = function(id)
        count("position")
        return { x = id * 100, y = 0, z = 0, instanceID = 0, uiMapID = 100 }
    end,
    GetNodeName = function(id) count("name"); return "Node " .. id end,
    IsNodeAvailable = function() count("availability"); return true end,
}
dofile("APR-Core/features/navigation/NavigationTaxi.lua")
return {
    counters = counters,
    reset = function(cold)
        for key in pairs(counters) do counters[key] = 0 end
        if cold then APR.taxiData:InvalidateStaticCache() end
        collectgarbage("collect")
    end,
    create = function() return APR.taxiData:CreateEdgeBuild({ clock = benchmarkClock }) end,
    createProbe = function(baseline)
        return APR.taxiData:CreateProbeSearch(
            { x = 100, y = 0, instanceID = 0, uiMapID = 100 },
            { x = 135, y = 0, instanceID = 0, uiMapID = 100 }, baseline,
            { clock = benchmarkClock, walkSpeed = 7, contextKey = "nearby-benchmark",
                canWalk = function() return true end })
    end,
}
"""


def benchmark_taxi(options) -> dict:
    runtime = new_runtime()
    fixture = runtime.execute(TAXI_FIXTURE)
    measurements = {"cold": [], "warm": []}
    for _ in range(options.runs):
        for mode in measurements:
            fixture.reset(mode == "cold")
            run = timed_job(fixture.create, options)
            run["api_calls"] = capture_counters(fixture.counters)
            measurements[mode].append(run)
    results = {
        f"taxi_{mode}": summarize(runs, paths=4000, nodes=200)
        for mode, runs in measurements.items()
    }
    # Probe the same indexed network near an objective. These scenarios expose
    # whole-network work that a warm graph-build benchmark alone would miss.
    for name, baseline in (("near", 25), ("local", 5)):
        runs = []
        for _ in range(options.runs):
            fixture.reset(False)
            run = timed_job(lambda: fixture.createProbe(baseline), options)
            run["api_calls"] = capture_counters(fixture.counters)
            runs.append(run)
        results[f"taxi_probe_{name}"] = summarize(runs, paths=4000, baseline_seconds=baseline)
    return results


CATALOG_FIXTURE = """
function createCatalogFixture(profile)
    local fixture = dofile("tests/lua/navigation_fixture.lua")
    fixture.profile, fixture.faction, fixture.spellName = profile, "Alliance", "Known spell"
    fixture.items = setmetatable({}, { __index = function() return 20 end })
    fixture.spells = setmetatable({}, { __index = function() return true end })
    local instance = fixture:Load()
    local counters = {}
    for name, callback in pairs(instance.env) do
        if type(callback) == "function" then
            local queryName, query = name, callback
            instance.env[name] = function(...)
                counters[queryName] = (counters[queryName] or 0) + 1
                return query(...)
            end
        end
    end
    local start = { x = 100, y = 200, instanceID = 0, uiMapID = 2395 }
    return {
        counters = counters,
        definitions = #instance:GetConnections(),
        reset = function(cold)
            for key in pairs(counters) do counters[key] = 0 end
            if cold then instance:InvalidatePositionCache() end
            collectgarbage("collect")
        end,
        create = function()
            return instance:CreateEdgeBuild({ start = start, playerPosition = start, clock = benchmarkClock })
        end,
    }
end
"""


def benchmark_catalog(options, profile: str) -> dict:
    runtime = new_runtime()
    runtime.execute(CATALOG_FIXTURE)
    fixture = runtime.globals().createCatalogFixture(profile)
    measurements = {"cold": [], "warm": []}
    for _ in range(options.runs):
        for mode in measurements:
            fixture.reset(mode == "cold")
            run = timed_job(fixture.create, options)
            run["api_calls"] = capture_counters(fixture.counters)
            measurements[mode].append(run)
    return {
        f"catalog_{profile}_{mode}": summarize(
            runs, profile=profile, definitions=int(fixture.definitions)
        )
        for mode, runs in measurements.items()
    }


SEARCH_FIXTURE = """
local library = dofile("tests/lua/navigation_engine_fixture.lua")
local nodes, edges, counters = {}, {}, {}
for index = 1, 1201 do
    nodes[index] = { x = index, y = 0, instanceID = (index - 1) % 20, region = "benchmark" }
end
for index = 1, 1200 do
    edges[index] = { id = index, from = nodes[index], to = nodes[index + 1],
        seconds = 1, copper = 0, kind = "portal" }
end
return {
    counters = counters,
    reset = function()
        counters.canWalk = 0
        collectgarbage("collect")
    end,
    create = function()
        return library.Engine:CreateSearch({ start = nodes[1], goal = nodes[1201], edges = edges,
            clock = benchmarkClock, canWalk = function()
                counters.canWalk = counters.canWalk + 1
                return false
            end })
    end,
}
"""


def benchmark_search(options) -> dict:
    runtime = new_runtime()
    fixture = runtime.execute(SEARCH_FIXTURE)
    measurements = []
    for _ in range(options.runs):
        fixture.reset()
        run = timed_job(fixture.create, options)
        run["api_calls"] = capture_counters(fixture.counters)
        measurements.append(run)
    return {"search": summarize(measurements, edges=1200, world_instances=20)}


def clock_callback_cost() -> float:
    runtime = new_runtime()
    loop = runtime.eval("function(n) for i = 1, n do benchmarkClock() end end")
    samples = []
    for _ in range(5):
        started = perf_counter_ns()
        loop(20_000)
        samples.append((perf_counter_ns() - started) / 20_000 / 1_000)
    return round(median(samples), 4)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runs", type=int, default=5)
    parser.add_argument("--max-operations", type=int, default=4096)
    parser.add_argument("--slice-ms", type=float, default=0.9,
                        help="Provider budget; APR reserves 0.1 ms of its 1 ms slice for orchestration")
    parser.add_argument("--scenario", choices=("all", "taxi", "catalog", "search"), default="all")
    options = parser.parse_args(argv)
    if options.runs < 1 or options.max_operations < 1 or not 0 < options.slice_ms < float("inf"):
        parser.error("runs, max-operations and slice-ms must be positive finite values")

    # Lua fixtures use repository-relative dofile paths, independent of the shell cwd.
    previous_directory = Path.cwd()
    try:
        os.chdir(ROOT)
        scenarios = {}
        if options.scenario in ("all", "taxi"):
            scenarios.update(benchmark_taxi(options))
        if options.scenario in ("all", "catalog"):
            for profile in ("retail", "forever"):
                scenarios.update(benchmark_catalog(options, profile))
        if options.scenario in ("all", "search"):
            scenarios.update(benchmark_search(options))
        report = {
            "runtime": "lupa.lua51",
            "clock": "Python time.perf_counter_ns, injected into Lua",
            "slice_budget_ms": options.slice_ms,
            "max_operations": options.max_operations,
            "clock_callback_and_timer_us_median": clock_callback_cost(),
            "notes": [
                "Times include Lua/Python crossings and mock API calls; real client calls may cost more.",
                "Preparation, search and complete Lua/runtime initialization are separate; initialization is not timed.",
                "Cold taxi clears the static index; cold catalogs clear position caches. Warm runs retain them.",
                "Garbage collection runs before each measurement; collection during a slice remains included.",
                "Budgets are cooperative: an indivisible operation or OS scheduling may exceed the requested slice.",
                "There are no timing thresholds or performance assertions in this benchmark.",
            ],
            "scenarios": scenarios,
        }
        print(json.dumps(report, indent=2))
    finally:
        os.chdir(previous_directory)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
