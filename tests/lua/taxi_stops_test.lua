local function noop() end
function CreateFrame() return { SetScript = noop } end
function LibStub() return { GetLocale = function() return {} end } end

local function point(x, y, z, world)
    return { x = x, y = y, z = z or 0, instanceID = world or 1, uiMapID = 100 }
end
local start, bend, goal = point(0, 0), point(200, 0), point(400, 0)
local nodes = {
    [1] = { point = point(100, 30) },
    [2] = { point = point(300, 30) },
    [3] = { point = point(50, 10), restricted = true },
    [4] = { point = point(60, 10, 0, 2) },
    [5] = { point = point(70, 10), characterBitNumber = 0 },
    [6] = { point = point(80, 10), hidden = true },
    [7] = { point = point(90, 100) },
}
local known = {}
APR = { PlayerID = "scenario" }
APRTaxiNodes = { scenario = known }
APRData = { scenario = {} }
function APR:NewModule() return {} end
function APR:GetGameVersion() return "forever" end
function APR:HasTaxiNode(id) return known[id] == true end
function APR:GetFlightPathDiscoveryText(step) return "Learn " .. step.GetFP end
LibTaxiData_API = {
    GetAllNodes = function() return nodes end,
    IsNodeAvailable = function(id) return not nodes[id].restricted end,
    IsNodeVisible = function(id) return not nodes[id].hidden end,
    GetNodeWorldPosition = function(id) return nodes[id].point end,
}
dofile("APR-Core/features/navigation/NavigationTaxi.lua")
dofile("APR-Core/features/navigation/NavigationPlanner.lua")

local taxi = APR.taxiData
local portal = { kind = "portal", from = goal, to = point(10, 10, 0, 2) }
local original = { id = "walk:1:2", kind = "walk", path = { start, bend, goal }, from = start, to = goal, seconds = 40 }
local segments = { original, portal }
local unreachable, addedYards
local provider = {}
function provider:CreatePathJob(from, to)
    return {
        Step = function()
            if unreachable and from.x == unreachable then return "no_path" end
            local yards = math.sqrt((from.x - to.x) ^ 2 + (from.y - to.y) ^ 2)
            yards = yards + (addedYards and from.x == 100 and addedYards or 0)
            return "ready", { path = { from, to }, seconds = yards / 10, yards = yards }
        end,
        Cancel = noop,
    }
end
local request = {
    taxiData = taxi, allowTaxiStops = true, walkingProvider = provider, budget = 0, walkSpeed = 10,
    canWalk = function(a, b) return a.instanceID == b.instanceID end,
    prepareSegment = function(segment) return segment end,
}
local function plan()
    local job = APR.NavigationPlanner:Create(request)
    job.result = { segments = segments, totalSeconds = 40, totalCopper = 0 }
    job:BeginQueue()
    local status, result
    for _ = 1, 128 do
        status, result = job:Step(4, 1)
        if status ~= "planning" then break end
    end
    assert(status == "ready")
    return result
end
local result = plan()
assert(result.taxiDiscovery and #result.queue == 4 and result.queue[4] == portal)
assert(result.queue[1].from == start and result.queue[1].to.x == 100)
assert(result.queue[2].discoverTaxiNode and result.queue[2].fromNodeID == 1 and result.queue[2].toNodeID == nil)
assert(result.queue[2].instruction == "Learn 1" and result.totalCopper == 0)
assert(result.queue[3].from == result.queue[2].to and result.queue[3].to == goal)
assert(result.queue[3].path[2] == bend and math.abs(result.totalSeconds - 40.8806130178) < 0.0001)
assert(#segments == 2 and #original.path == 3, "Discovery must preserve the original proven path")
known[1] = true
assert(plan().queue[2].fromNodeID == 2, "Replanning after discovery can select the next master on the path")
known[1], unreachable = nil, 100
assert(plan().queue[2].fromNodeID == 2, "Both sides of the first stop must be reachable")
unreachable, addedYards = nil, 130
assert(plan().queue[2].fromNodeID == 2, "A physically long detour must be rejected despite XY proximity")
known[1], known[2] = true, true
result = plan()
assert(not result.taxiDiscovery and #result.queue == 2 and result.queue[1] == original)
print("Taxi stops: unknown nearby masters, walking proof and added distance, onward path and exclusions passed")
