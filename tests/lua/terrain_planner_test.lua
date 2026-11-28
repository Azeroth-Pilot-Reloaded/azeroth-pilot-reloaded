local library = dofile("tests/lua/navigation_engine_fixture.lua")
local engine = library.Engine
local function point(x)
    return {x = x, y = 0, z = 0, instanceID = 1, uiMapID = 2, region = "outside", accessKey = "open"}
end
local function key(a, b) return a.x .. ":" .. b.x end
local function provider(costs, paths)
    local p = {batches = {}, paths = {}, jobs = {}, now = 0}
    local function job(run)
        local j = {remaining = 3}
        function j:Step(operations, milliseconds)
            assert(operations == 1 and milliseconds > 0, "Nested work receives only the remaining shared allowance")
            assert(not p.sliceDeadline or milliseconds <= p.sliceDeadline - p.now + 0.00001,
                "Every nested job receives the remaining deadline, never a fresh allowance")
            p.now = p.now + 0.2
            self.workLastStep = 1
            self.remaining = self.remaining - 1
            if self.remaining > 0 then return "planning" end
            return run()
        end
        function j:Cancel() self.cancelled = true end
        p.jobs[#p.jobs + 1] = j
        return j
    end
    function p:CreateCostJob(from, targets, context)
        assert(context.walkSpeed == 7 and context.clock, "Walking context preserves speeds and caller clock")
        assert(not self.batches[from.x], "One batched terrain query per origin")
        self.batches[from.x] = targets
        return job(function()
            local result = {costs = {}}
            for i, to in ipairs(targets) do
                local cost = costs[key(from, to)]
                result.costs[i] = type(cost) == "number" and {state = "ready", seconds = cost, yards = cost * 7}
                    or {state = cost or "no_path"}
            end
            return "ready", result
        end)
    end
    function p:CreatePathJob(from, to)
        self.paths[#self.paths + 1] = key(from, to)
        return job(function()
            local state = paths and paths[key(from, to)]
            if state then return state end
            local cost = costs[key(from, to)]
            if type(cost) ~= "number" then return "unavailable" end
            return "ready", {path = {from, {x = from.x, y = 50, z = 0, instanceID = 1}, to},
                seconds = cost, yards = cost * 7}
        end)
    end
    return p
end
local function withHazard(p, weight)
    local createCostJob, createPathJob = p.CreateCostJob, p.CreatePathJob
    local function adjust(job, matches, batched)
        local step = job.Step
        function job:Step(...)
            local status, result = step(self, ...)
            if status == "ready" then
                if batched then
                    for i, cost in ipairs(result.costs) do
                        if matches[i] then cost.weightedSeconds = weight end
                    end
                elseif matches then
                    result.weightedSeconds = weight
                end
            end
            return status, result
        end
        return job
    end
    function p:CreateCostJob(from, targets, context)
        local matches = {}
        for i, to in ipairs(targets) do matches[i] = key(from, to) == "0:14" end
        return adjust(createCostJob(self, from, targets, context), matches, true)
    end
    function p:CreatePathJob(from, to, context)
        return adjust(createPathJob(self, from, to, context), key(from, to) == "0:14", false)
    end
    return p
end
local function finish(search, p)
    for _ = 1, 10000 do
        local before = p and p.now or 0
        if p then p.sliceDeadline = p.now + 0.5 end
        local status, result = search:Step(8, 0.5)
        assert(search.workLastStep <= 8, "Provider work counts against operation budget")
        assert(not p or p.now - before <= 0.60001, "Nested jobs share the caller deadline")
        if status ~= "planning" then return status, result end
    end
    error("Terrain search did not finish")
end
local a, b, c, d = point(0), point(7), point(13), point(14)
local function transport(from, to, seconds)
    return {id = "synthetic-crossing", kind = "boat", from = from, to = to, seconds = seconds, copper = 0}
end
local function search(p, edges, extra)
    local request = {start = a, goal = d, edges = edges or {}, walkingProvider = p,
        clock = function() return p.now end, walkSpeed = 7}
    for k, v in pairs(extra or {}) do request[k] = v end
    return engine:CreateSearch(request)
end

-- A geometrically nearby goal lies behind a physical obstacle. Boarding a
-- transport beats the actual detour even though its crossing loses to a chord.
local p = provider({["0:14"] = 80, ["0:7"] = 1, ["13:14"] = 1})
local status, result = finish(search(p, {transport(b, c, 3)}), p)
assert(status == "ready" and result.totalSeconds == 5 and #result.segments == 3,
    "Terrain costs must choose the physically faster transport itinerary")
assert(result.segments[2].kind == "boat" and #result.segments[1].path == 3)
assert(result.segments[1].path[1] == a and result.segments[3].path[3] == d,
    "Materialized paths retain endpoint and access metadata")
assert(#p.batches[0] == 3 and #p.paths == 2, "Batch all authorized targets but materialize only the winning legs")

-- Weight changes the choice, while the published itinerary retains its duration.
p = withHazard(provider({["0:14"] = 2, ["0:7"] = 1, ["13:14"] = 1}), 40)
status, result = finish(search(p, {transport(b, c, 3)}), p)
assert(status == "ready" and result.totalSeconds == 5 and result.segments[2].kind == "boat")
p = withHazard(provider({["0:14"] = 2}), 40)
status, result = finish(search(p), p)
assert(status == "ready" and result.totalSeconds == 2 and result.segments[1].seconds == 2)

-- Terrain distances need not obey the old Euclidean/transitive shortcut.
p = provider({["0:14"] = 80, ["0:7"] = 1, ["7:13"] = 1, ["13:14"] = 1})
status, result = finish(search(p, {transport(b, c, 100)}), p)
assert(status == "ready" and result.totalSeconds == 3 and #result.segments == 3,
    "Consecutive terrain walks remain eligible even with default transitive permissions")

p = provider({["0:14"] = "unavailable"})
status, result = finish(search(p), p)
assert(status == "ready" and result.totalSeconds == 2 and not result.segments[1].path,
    "Unavailable terrain falls back to the authorized estimate")
p = provider({})
assert(finish(search(p), p) == "no_path", "Proven disconnection must never become a straight walk")
p = provider({["0:14"] = 5})
assert(finish(search(p, nil, {canWalk = function() return false end}), p) == "no_path")
assert(next(p.batches) == nil, "Host walking permissions remain authoritative before terrain")

-- One origin can contain ready, disconnected and missing-data targets. The
-- fallback keeps the configured speed and never revives the disconnected one.
p = provider({["0:14"] = "no_path", ["0:7"] = "unavailable", ["13:14"] = 2})
local speeds = 0
status, result = finish(search(p, {transport(b, c, 3)}, {walkSpeedFor = function()
    speeds = speeds + 1
    return 3.5
end}), p)
assert(status == "ready" and result.totalSeconds == 7 and speeds > 0,
    "Mixed terrain states retain host speed policy only for unavailable edges")

-- The same graph in another request must observe newly supplied terrain costs.
local first = provider({["0:14"] = 9})
local second = provider({["0:14"] = 6})
local _, firstResult = finish(search(first), first)
local _, secondResult = finish(search(second), second)
assert(firstResult.totalSeconds == 9 and secondResult.totalSeconds == 6,
    "Terrain cost caches belong to one search request")

-- A failed final path invalidates only that candidate, then allows an alternate
-- transport even when it had been pruned by the former best goal bound.
p = provider({["0:14"] = 2, ["0:7"] = 1, ["13:14"] = 1}, {["0:14"] = "no_path"})
status, result = finish(search(p, {transport(b, c, 10)}), p)
assert(status == "ready" and result.totalSeconds == 12 and result.segments[2].kind == "boat",
    "A path failure resumes a sound search instead of publishing an invalid chord")

p = provider({["0:14"] = 5}, {["0:14"] = "unavailable"})
status, result = finish(search(p), p)
assert(status == "ready" and result.totalSeconds == 5 and not result.segments[1].path,
    "Unavailable materialization retains the physically priced fallback segment")

for _, phase in ipairs({"cost", "path"}) do
    p = provider({["0:14"] = 5})
    local pending = search(p)
    assert(pending:Step(0, 1) == "planning" and #p.jobs == 0)
    assert(pending:Step(10, 0) == "planning" and #p.jobs == 0)
    for _ = 1, 500 do
        pending:Step(1, 1)
        if (phase == "cost" and #p.jobs > 0) or (phase == "path" and #p.paths > 0) then break end
    end
    local nested = p.jobs[#p.jobs]
    pending:Cancel()
    assert(nested and nested.cancelled and pending:Step(100, 1) == "cancelled",
        "Cancellation propagates to the active terrain " .. phase .. " job")
end

status, result = finish(engine:CreateSearch({start = a, goal = d, edges = {transport(b, c, 3)}}))
assert(status == "ready" and result.totalSeconds == 2 and #result.segments == 1,
    "Without a provider, the existing direct walking behavior is preserved")
print("Terrain planner: physical costs, batching, obstacle transport, transitive walks, fallback, path recovery, cancellation and shared budgets passed")
