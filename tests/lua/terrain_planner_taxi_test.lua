local function noop() end
function CreateFrame() return {SetScript = noop} end
function LibStub()
    return {GetLocale = function() return {NAVIGATION_CONSULT_TAXI = "Consult"} end}
end
APR = {PlayerID = "terrain-taxi"}
function APR:NewModule() return {} end
function APR:GetGameVersion() return "forever" end
function APR:HasTaxiNode() return true end
APRData = {[APR.PlayerID] = {}}
local positions = {
    [1] = {x = 1, y = 0, instanceID = 1}, [2] = {x = 99, y = 0, instanceID = 1},
    [3] = {x = 20, y = 0, instanceID = 1}, [4] = {x = 80, y = 0, instanceID = 1},
}
local source = {profile = "forever", build = "fixture", paths = {fingerprint = "fixture"}}
LibTaxiData_API = {
    GetSource = function() return source end,
    GetAllPaths = function() return {
        [1] = {fromNodeID = 1, toNodeID = 2, durationSeconds = 5},
        [2] = {fromNodeID = 3, toNodeID = 4, durationSeconds = 5},
    } end,
    GetNodeWorldPosition = function(id) return positions[id] end,
    IsNodeAvailable = function() return true end,
}
-- Static catalog identities are immutable, including the table returned by the API.
local paths = LibTaxiData_API.GetAllPaths()
LibTaxiData_API.GetAllPaths = function() return paths end
function GetTime() return 0 end
dofile("APR-Core/features/navigation/NavigationTaxi.lua")
local taxi = APR.taxiData
local a, goal = {x = 0, y = 0, instanceID = 1}, {x = 100, y = 0, instanceID = 1}
local function provider()
    local p = {now = 0, batches = {}, pathCalls = {}, active = {}}
    local function work(run)
        local j = {remaining = 3}
        function j:Step(operations, milliseconds)
            assert(operations == 1 and milliseconds > 0 and milliseconds <= p.deadline - p.now + 0.00001)
            self.workLastStep, self.remaining, p.now = 1, self.remaining - 1, p.now + 0.2
            if self.remaining > 0 then return "planning" end
            return run()
        end
        function j:Cancel() self.cancelled = true end
        p.active[#p.active + 1] = j
        return j
    end
    function p:CreateCostJob(from, targets)
        assert(not self.batches[from.x], "Probe ground queries batch once per origin")
        self.batches[from.x] = targets
        return work(function()
            local costs = {}
            for i, to in ipairs(targets) do
                costs[i] = {state = self.unavailable and "unavailable"
                    or self.disconnect and from.x == 0 and to.x == 20 and "no_path" or "ready",
                    seconds = from.x == 0 and (to.x == 1 and 100 or 10) or 10, yards = 100}
            end
            return "ready", {costs = costs}
        end)
    end
    function p:CreatePathJob(from, to)
        self.pathCalls[#self.pathCalls + 1] = {from = from, to = to}
        return work(function()
            if self.pathUnavailable then return "unavailable" end
            if self.pathFailure == to.x and from.x == 0 then return "no_path" end
            return "ready", {path = {from, {x = from.x, y = 25, instanceID = 1}, to}}
        end)
    end
    return p
end
local function make(p, suffix, baseline)
    return taxi:CreateProbeSearch(a, goal, baseline or 80, {contextKey = "synthetic:" .. (suffix or "one"),
        walkingProvider = p, walkSpeed = 7, canWalk = function() return true end,
        clock = function() return p.now end})
end
local function finish(job, p)
    for _ = 1, 3000 do
        p.deadline = p.now + 0.5
        local status, result = job:Step(8, 0.5)
        if status ~= "planning" then return status, result end
    end
    error("Terrain taxi did not finish")
end
local p = provider()
local status, result = finish(make(p), p)
assert(status == "ready" and result and result.fromNodeID == 3 and result.estimatedSeconds == 40,
    "A useful probe stays active and ranks physical approaches instead of geometric proximity")
assert(#p.batches[0] == 2 and #p.pathCalls == 2 and #result.approachPath == 3 and #result.exitPath == 3,
    "Probe batches departure costs, then materializes only its selected approach and exit")
assert(result.approachSeconds == 10 and result.exitSeconds == 10)
p = provider(); p.unavailable, p.pathUnavailable = true, true
status, result = finish(make(p, "unavailable"), p)
assert(status == "ready" and result and result.fromNodeID == 1
    and math.abs(result.estimatedSeconds - (20 + 2 / 7)) < 0.00001 and not result.approachPath,
    "Unavailable terrain preserves authorized taxi exploration and legacy walking estimates")
p = provider(); p.disconnect = true
status, result = finish(make(p, "disconnect"), p)
assert(status == "ready" and not result, "A disconnected approach cannot become an unknown-flight probe")
p = provider(); p.pathFailure = 20
status, result = finish(make(p, "path-failure"), p)
assert(status == "ready" and not result, "A failed final approach rejects the candidate instead of publishing a chord")
p = provider(); p.pathFailure = 20
status, result = finish(make(p, "alternate", 200), p)
assert(status == "ready" and result and result.fromNodeID == 1 and result.estimatedSeconds == 130,
    "A failed final approach reconsiders a slower physically feasible master")
for _, phase in ipairs({"cost", "path"}) do
    p = provider()
    local job = make(p, "cancel:" .. phase)
    for _ = 1, 1000 do
        p.deadline = p.now + 1
        job:Step(1, 1)
        if (#p.active > 0 and phase == "cost") or (#p.pathCalls > 0 and phase == "path") then break end
    end
    job:Cancel()
    assert(p.active[#p.active].cancelled and job:Step(64, 1) == "cancelled",
        "Probe cancellation reaches the active terrain " .. phase .. " job")
end
print("Terrain taxi probes: useful obstacle detours, batching, physical ranking, paths, disconnections and cancellation passed")
