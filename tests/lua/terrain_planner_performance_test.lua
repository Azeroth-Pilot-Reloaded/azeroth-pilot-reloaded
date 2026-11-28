local library = dofile("tests/lua/navigation_engine_fixture.lua")
local engine = library.Engine
local function point(x, z) return {x = x, y = 0, z = z or 0, instanceID = 1, region = "outside"} end
local function pair(a, b) return a.x .. ":" .. b.x end
local function provider(costs, failedPaths)
    local p = {queries = {}, paths = {}, jobs = {}, now = 0}
    local function work(run)
        local j = {remaining = 3}
        function j:Step(operations, milliseconds)
            assert(operations == 1 and milliseconds > 0 and milliseconds <= p.deadline - p.now + 0.00001,
                "Priority terrain and regular terrain share the remaining operation/time budgets")
            self.remaining, self.workLastStep, p.now = self.remaining - 1, 1, p.now + 0.15
            if self.remaining > 0 then return "planning" end
            return run()
        end
        function j:Cancel() self.cancelled = true end
        p.jobs[#p.jobs + 1] = j
        return j
    end
    function p:CreateCostJob(from, targets)
        self.queries[#self.queries + 1] = {from = from, targets = targets}
        return work(function()
            local result = {costs = {}}
            for i, target in ipairs(targets) do
                local value = costs[pair(from, target)]
                result.costs[i] = type(value) == "number" and {state = "ready", seconds = value, yards = value * 7}
                    or {state = value or "no_path"}
            end
            return "ready", result
        end)
    end
    function p:CreatePathJob(from, to)
        self.paths[#self.paths + 1] = pair(from, to)
        return work(function()
            if failedPaths and failedPaths[pair(from, to)] then
                local value = failedPaths[pair(from, to)]
                if type(value) == "table" then return "ready", value end
                return value
            end
            return "ready", {path = {from, {x = from.x, y = 20, instanceID = 1}, to}}
        end)
    end
    function p:Queried(fromX, toX)
        local count = 0
        for _, query in ipairs(self.queries) do
            for _, target in ipairs(query.targets) do
                if query.from.x == fromX and target.x == toX then count = count + 1 end
            end
        end
        return count
    end
    return p
end

-- A walk to a candidate entrance can guide while the destination is being
-- proved. It participates in pricing at the usual point, even when a second
-- entrance eventually wins.
do
    local start, near, far = point(0), point(7), point(21)
    local nearLanding, farLanding, goal = point(91), point(86), point(98)
    nearLanding.region, farLanding.region, goal.region = "inside", "inside", "inside"
    local calls = {}
    local terrain = {proveCandidatePaths = true, RequiresWalkingProof = function() return true end}
    function terrain:CreatePathJob(from, to, context)
        calls[#calls + 1] = {from, to}
        local seconds = from == start and (to == near and 2 or 4) or (from == nearLanding and 30 or 3)
        local path = {from, to}
        local job = {Step = function() return "ready", {seconds = seconds, path = path} end}
        if from == start and to == near then
            assert(context.walkingGoal == near and context.previewWalking and not context.walkingGoalXY)
            local finish = job.Step
            function job:Step()
                if self.walkingPreview then return finish() end
                self.walkingPreview = {{path = path}, {path = {nearLanding, goal}, breakBefore = true}}
                return "planning"
            end
        end
        return job
    end
    local search = engine:CreateSearch({
        start = start, goal = goal, walkingProvider = terrain, walkingSpeedCeiling = 7,
        walkingGoalXY = true, previewEntryWalk = true, batchTerrainWork = true,
        canWalk = function(from, to)
            return (from == start and (to == near or to == far))
                or ((from == nearLanding or from == farLanding) and to == goal)
        end,
        edges = {
            {kind = "elevator", from = near, to = nearLanding, seconds = 1},
            {kind = "elevator", from = far, to = farLanding, seconds = 2},
        },
    })
    local sawPreview
    for slice = 1, 2000 do
        local status, result = search:Step(1, 1)
        if status ~= "planning" then
            assert(status == "ready" and sawPreview and result.totalSeconds == 9)
            assert(result.segments[1].path[2] == far and result.segments[2].kind == "elevator")
            assert(result.segments[3].path[2] == goal)
            break
        end
        if search.entryWalkPreview and not sawPreview then
            local preview = search.entryWalkPreview
            assert(#preview == 1 and preview[1].path[2] == near and #calls == 1,
                "Only the departure walk can be published before destination checks")
            sawPreview = true
        end
        assert(slice < 2000)
    end
    local nearCalls = 0
    for _, call in ipairs(calls) do
        if call[1] == start and call[2] == near then nearCalls = nearCalls + 1 end
    end
    assert(nearCalls == 1, "Pricing can reuse the first departure's completed proof")
end

local function edge(from, to, seconds) return {kind = "boat", from = from, to = to, seconds = seconds} end
local a, goal, far, farEnd = point(0), point(7), point(700), point(707)
local function create(p, extra)
    local request = {start = a, goal = goal, edges = {edge(far, farEnd, 3)},
        walkingProvider = p, walkingSpeedCeiling = 7, walkSpeed = 7, clock = function() return p.now end}
    for k, v in pairs(extra or {}) do request[k] = v end
    return engine:CreateSearch(request)
end
local function finish(job, p)
    for _ = 1, 10000 do
        p.deadline = p.now + 0.5
        local status, result = job:Step(8, 0.5)
        assert((job.workLastStep or 0) <= 8)
        if status ~= "planning" then return status, result end
    end
    error("Bounded terrain search did not finish")
end

local p = provider({["0:7"] = 10})
local status, result = finish(create(p), p)
assert(status == "ready" and result.totalSeconds == 10 and #result.segments[1].path == 3)
assert(#p.queries == 1 and #p.queries[1].targets == 1 and p.queries[1].targets[1] == goal,
    "Measure the physical direct route first and never request candidates whose lower bound already loses")
local many = {}
for i = 1, 1000 do many[i] = edge(point(700 + i * 14), point(707 + i * 14), 3) end
p = provider({["0:7"] = 10})
local dense = create(p, {edges = many})
status, result = finish(dense, p)
assert(status == "ready" and result.totalSeconds == 10 and #p.queries == 1
    and #p.queries[1].targets == 1 and #dense.nodes == 2002,
    "Large catalogs retain all endpoints but request only the physically relevant terrain target")
p = provider({["0:7"] = "unavailable"}, {["0:7"] = "unavailable"})
dense = create(p, {edges = many})
status, result = finish(dense, p)
assert(status == "ready" and result.totalSeconds == 1 and #p.queries == 1
    and #p.queries[1].targets == 1 and #dense.nodes == 2002 and result.segments[1].path == nil,
    "Ambiguous terrain does not scan a thousand irrelevant transports or fabricate a measured path")
p = provider({["0:7"] = 10, ["0:70"] = 10})
status, result = finish(create(p, {edges = {edge(point(70), goal, 0)}}), p)
assert(status == "ready" and result.totalSeconds == 10 and p:Queried(0, 70) == 1,
    "A lower bound equal to the incumbent remains eligible for ties")

-- A high vertical difference is part of the admissible lower bound as well.
p = provider({["0:7"] = 10})
status, result = finish(create(p, {edges = {edge(point(1, 700), point(2, 700), 3)}}), p)
assert(status == "ready" and #p.queries == 1, "The bound uses three-dimensional endpoint distance")

local b, c, d = point(7), point(13), point(14)
p = provider({["0:14"] = 80, ["0:7"] = 1, ["13:14"] = 1})
status, result = finish(create(p, {goal = d, edges = {edge(b, c, 3)}}), p)
assert(status == "ready" and result.totalSeconds == 5 and result.segments[2].kind == "boat"
    and p:Queried(0, 7) == 1, "A real transport improvement remains eligible behind an obstacle")
assert(p:Queried(0, 14) == 1, "The priority direct cost is reused by the origin batch")

-- The edge's endpoints remain useful even when the edge itself loses to U.
p = provider({["0:14"] = 80, ["0:7"] = 1, ["7:13"] = 1, ["13:14"] = 1})
status, result = finish(create(p, {goal = d, edges = {edge(b, c, 100)}}), p)
assert(status == "ready" and result.totalSeconds == 3 and #result.segments == 3,
    "The bound never reintroduces expensive-edge endpoint omission or transitive walking pruning")

-- Generic callbacks have no implied speed ceiling. These physical costs are
-- consistent with speed 700, despite the ordinary default walkSpeed being 7.
for _, ceiling in ipairs({false, 0, -1, math.huge, 0 / 0, "7", 700}) do
    p = provider({["0:7"] = 80, ["0:700"] = 1, ["707:7"] = 1})
    status, result = finish(create(p, {walkingSpeedCeiling = ceiling,
        walkSpeedAt = function() return 700 end}), p)
    assert(status == "ready" and result.totalSeconds == 5 and p:Queried(0, 700) == 1,
        "Only an explicit finite positive promise may narrow variable-speed terrain requests")
end
p = provider({})
status, result = finish(create(p, {walkingProvider = false}), p)
assert(status == "ready" and result.totalSeconds == 1 and #p.queries == 0,
    "An explicit ceiling without an active provider retains ordinary direct walking")

p = provider({["0:14"] = "no_path", ["0:7"] = 1, ["13:14"] = 1})
status, result = finish(create(p, {goal = d, edges = {edge(b, c, 3)}}), p)
assert(status == "ready" and result.totalSeconds == 5 and p:Queried(0, 14) == 1,
    "A disconnected direct route provides no upper bound and remains absent from later batches")
p = provider({["0:7"] = "unavailable"}, {["0:7"] = "unavailable"})
status, result = finish(create(p), p)
assert(status == "ready" and result.totalSeconds == 1 and p:Queried(0, 700) == 0,
    "The authorized unavailable fallback bounds the same graph model without querying distant losers")

-- A cost-ready route can fail final path materialization. Previously filtered
-- targets must become unknown/eligible again, never cached as disconnected.
p = provider({["0:7"] = 10, ["0:700"] = 100, ["707:7"] = 100}, {["0:7"] = "no_path"})
status, result = finish(create(p), p)
assert(status == "ready" and result.totalSeconds == 203 and result.segments[2].kind == "boat"
    and p:Queried(0, 700) == 1, "A failed direct path removes its bound and recovers formerly excluded targets")
p = provider({["0:7"] = "unavailable", ["0:700"] = 100, ["707:7"] = 100}, {["0:7"] = "no_path"})
status, result = finish(create(p), p)
assert(status == "ready" and result.totalSeconds == 203 and result.segments[2].kind == "boat"
    and p:Queried(0, 700) == 1, "A later proven wall also retires the provisional unavailable bound")
p = provider({["0:7"] = "unavailable", ["0:14"] = 2, ["21:7"] = 2},
    {["0:7"] = {path = {a, goal}, seconds = 10}})
status, result = finish(create(p, {edges = {edge(point(14), point(21), 1)}}), p)
assert(status == "ready" and result.totalSeconds == 5 and result.segments[2].kind == "boat",
    "A later physical price replaces the fallback and reopens candidates excluded by its estimate")
p = provider({["0:7"] = "unavailable"}, {["0:7"] = {path = {a, goal}, seconds = 10}})
status, result = finish(create(p, {edges = {}}), p)
assert(status == "ready" and result.totalSeconds == 10 and #result.segments[1].path == 2,
    "Without an alternative, the corrected physical walk remains feasible at its measured price")

-- A newly reached goal can tighten the original direct upper bound.
local other = point(100)
p = provider({["0:14"] = 80, ["0:7"] = 1, ["13:14"] = 1})
status, result = finish(create(p, {goal = d, edges = {edge(b, c, 3), edge(a, other, 4.5)}}), p)
assert(status == "ready" and result.totalSeconds == 5)
for _, query in ipairs(p.queries) do
    assert(query.from ~= other, "The best accepted goal cost also narrows later origin batches")
end

p = provider({["0:7"] = 10, ["0:14"] = 20})
status, result = finish(create(p, {goals = {goal, d}, walkingSpeedCeiling = false}), p)
assert(status == "ready" and result.totalSeconds == 10 and #p.queries[1].targets == 4,
    "Multi-goal searches without a speed ceiling retain the original complete batch behavior")
p = provider({["0:7"] = 10})
assert(finish(create(p, {canWalk = function() return false end}), p) == "no_path" and #p.queries == 0,
    "A speed bound never authorizes a walk rejected by the host")

p = provider({["0:7"] = 10})
local pending = create(p)
assert(pending:Step(0, 1) == "planning" and #p.jobs == 0)
assert(pending:Step(10, 0) == "planning" and #p.jobs == 0)
for _ = 1, 30 do
    p.deadline = p.now + 1
    pending:Step(1, 1)
    if #p.jobs > 0 then break end
end
pending:Cancel()
assert(p.jobs[1] and p.jobs[1].cancelled and pending:Step(100, 1) == "cancelled",
    "Cancellation reaches the priority direct terrain job before graph ingestion")

APR = {}
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local seen = 0
local request = {start = a, goal = goal, walkingProvider = p, walkingSpeedCeiling = 7,
    data = {CreateEdgeBuild = function() return {Step = function() return "ready", {}, {blockedEdges = {{id = "locked"}}} end} end},
    taxiData = {CreateEdgeBuild = function() return {Step = function() return "ready", {} end} end},
    engine = {CreateSearch = function(_, options)
        assert(options.walkingSpeedCeiling == 7, "Normal and diagnostic planners retain the explicit speed ceiling")
        seen = seen + 1
        return {Step = function() return "no_path" end, GetResult = function() end}
    end}}
assert(finish(APR.NavigationPlanner:Create(request), p) == "no_path" and seen == 2)
print("Bounded terrain planner: priority physical direct, admissible 3D pruning, ceilings, transport improvements, retry, multi-goals and shared budgets passed")

-- Foreground work may spend the remaining slice on the winning corridor.
-- A tempting but blocked walk must trigger a fresh comparison, including
-- the longer walk to a usable transport. Expensive losing walks stay unprobed.
do
    local start, goal = point(0), point(100)
    local near, usable, distant = point(7), point(14), point(700)
    local checked, largestGrant = {}, 0
    local function job(state, result)
        return {
            Step = function(self, operations)
                largestGrant = math.max(largestGrant, operations)
                self.workLastStep = operations
                return state, result
            end,
        }
    end
    local terrain = {}
    function terrain:CreateCostJob(from, targets)
        assert(from == start and #targets == 1)
        local target = targets[1]
        checked[target] = true
        if target == near then return job("no_path") end
        assert(target == goal or target == usable)
        return job("ready", {costs = {{state = "ready", seconds = target == goal and 40 or 5}}})
    end
    function terrain:CreatePathJob(from, to)
        checked[to] = true
        if from == start and to == usable then
            return job("ready", {path = {from, to}})
        end
        return job("no_path")
    end
    local search = engine:CreateSearch({start = start, goal = goal, walkSpeed = 7,
        walkingProvider = terrain, walkingSpeedCeiling = 7, batchTerrainWork = true,
        canWalk = function(from) return from == start end,
        edges = {edge(near, goal, 1), edge(usable, goal, 3), edge(distant, goal, 100)}})
    for slice = 1, 1000 do
        local status, result = search:Step(16, 1)
        assert(search.workLastStep <= 16)
        if status ~= "planning" then
            assert(status == "ready" and result.totalSeconds == 8 and result.segments[2].kind == "boat")
            assert(checked[near] and checked[usable] and not checked[distant] and largestGrant > 1)
            break
        end
        assert(slice < 1000)
    end
end

-- A provider that supplies cost and geometry together resolves the contender
-- once, even when its measured cost forces the transport labels to restart.
do
    local start, goal = point(0), point(100)
    local blocked, usable = point(7), point(14)
    local paths = {}
    local terrain = {proveCandidatePaths = true, RequiresWalkingProof = function() return true end}
    function terrain:CreateCostJob()
        error("The selected terrain walk should provide cost and geometry together")
    end
    function terrain:CreatePathJob(from, to)
        assert(from == start and (to == blocked or to == usable))
        paths[to] = (paths[to] or 0) + 1
        return {Step = function()
            if to == blocked then return "no_path" end
            return "ready", {seconds = 4, path = {from, to}}
        end}
    end
    local search = engine:CreateSearch({start = start, goal = goal, walkSpeed = 7,
        walkingProvider = terrain, walkingSpeedCeiling = 7, batchTerrainWork = true,
        canWalk = function(from) return from == start end,
        edges = {edge(blocked, goal, 1), edge(usable, goal, 3)}})
    for slice = 1, 1000 do
        local status, route = search:Step(16, 1)
        if status ~= "planning" then
            assert(status == "ready" and route.totalSeconds == 7 and route.segments[2].kind == "boat")
            assert(route.segments[1].path[2] == usable and paths[blocked] == 1 and paths[usable] == 1)
            break
        end
        assert(slice < 1000)
    end
end
