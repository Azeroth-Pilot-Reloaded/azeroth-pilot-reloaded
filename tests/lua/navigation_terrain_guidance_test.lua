LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
dofile(root .. "Core.lua")
dofile(root .. "Terrain.lua")
dofile(root .. "LocalRouting.lua")
local file = io.open(root .. "Guidance.lua")
if file then file:close(); dofile(root .. "Guidance.lua") end
local lib = LibStub("LibAPRNavigation-1.0")
assert(type(lib.Instance.CreateGuidance) == "function", "continuous terrain guidance API must exist")
local instance = lib:New({ profile = "fixture", environment = {} })
local function p(x, y, z, floor)
    return { x = x, y = y, z = z, instanceID = 7, uiMapID = 17, floor = floor }
end
local a, b, c, d = p(0, 0, 0), p(0, 50, 0), p(50, 50, 0), p(50, 0, 0)
local route = { totalSeconds = 15, segments = {
    { from = a, to = d, kind = "walk", terrain = true, seconds = 15, movementMode = "ground", polyline = { a, b, c, d } },
} }
local session = instance:CreateGuidance(route)
local delayedPosition = instance:CreateGuidance(route, { maxOperations = 1 })
assert(select(2, delayedPosition:Update(nil)) == "waiting_data")
local resumedTarget, resumedStatus
for _ = 1, 30 do
    resumedTarget, resumedStatus = delayedPosition:Update(p(0, 0, 0))
    if resumedStatus == "guiding" then break end
end
assert(resumedStatus == "guiding" and resumedTarget.y == 30,
    "a position unavailable during preparation must recover with bounded work")
assert(select(2, delayedPosition:Update({ x = math.huge, y = 0 })) == "waiting_data")
assert(select(2, delayedPosition:Update(p(0, 0, 0))) == "guiding",
    "temporary missing observations also recover after preparation")
local cancelledBeforePosition = instance:CreateGuidance(route)
cancelledBeforePosition:Update(nil)
cancelledBeforePosition:Cancel()
assert(select(2, cancelledBeforePosition:Update(p(0, 0, 0))) == "cancelled",
    "a new observation must not revive a cancelled session")
local target, status = session:Update(p(0, 0, 0))
assert(status == "guiding" and target.x == 0 and target.y == 30, "lookahead remains before the first corner")
assert(session.remainingSeconds == 15)
target = session:Update(p(0, 49, 0))
assert(target.x == 0 and target.y == 50, "proximity must not cut a wall corner")
target = session:Update(p(0, 50, 0))
assert(target.x == 30 and target.y == 50)
assert(math.abs(session.remainingSeconds - 10) < 0.001)
target, status = session:Update(p(45, 50, 0))
assert(status == "guiding" and target.x == 50 and target.y == 50)
target = session:Update(p(50, 50, 0))
assert(target.x == 50 and target.y == 20)
target, status = session:Update(p(50, 0, 0))
assert(status == "arrived" and target == nil and session.remainingSeconds == 0)

session = instance:CreateGuidance(route)
target, status = session:Update(p(40, 0, 0))
assert(status == "deviated", "distance to the active corridor triggers re-routing")

local sky = { totalSeconds = 2, segments = {
    { from = p(0, 0, 100), to = p(120, 0, 100), kind = "walk", terrain = true,
        seconds = 2, movementMode = "skyriding", polyline = { p(0, 0, 100), p(120, 0, 100) } },
} }
session = instance:CreateGuidance(sky, { movementProfile = { skyridingSpeed = 60 } })
target, status = session:Update(p(0, 0, 100))
assert(status == "guiding" and target.x == 120 and target.z == 100)
target, status = session:Update(p(0, 0, 0))
assert(status == "deviated", "flying deviation is measured in three dimensions")

session = instance:CreateGuidance(sky)
target, status = session:Update(p(120, 0))
assert(status == "waiting_data", "unknown altitude cannot prove arrival in an airborne corridor")

local crossing = { totalSeconds = 10, segments = {
    { from = a, to = p(100, 0, 0), kind = "walk", seconds = 10, mandatory = true,
        polyline = { a, p(100, 0, 0) } },
} }
session = instance:CreateGuidance(crossing)
session:Update(p(90, 0, 0))
target, status = session:Update(p(110, 0, 0))
assert(status == "arrived", "a swept arrival catches a point passed between polls")
session = instance:CreateGuidance(crossing)
session:Update(p(90, 20, 0))
target, status = session:Update(p(110, 20, 0))
assert(status ~= "arrived", "passing beside a mandatory point does not complete it")
session:Cancel()
assert(select(2, session:Update(a)) == "cancelled")
session = instance:CreateGuidance(route)
assert(select(2, session:Update(p(0, 0))) == "waiting_data", "ground altitude is required where the path provides it")
local calls = 0
session = instance:CreateGuidance(route, { canTraverse = function()
    calls = calls + 1
    return nil, p(0, 10, 0)
end })
target = session:Update(p(1, 0, 0))
assert(target.x == 0 and target.y == 10 and calls == 1, "lookahead shrinks to a proved reachable prefix")
session = instance:CreateGuidance(route, { canTraverse = function() error("a point on the proved segment needs no raycast") end })
target = session:Update(p(0, 0, 0))
assert(target.y == 30)
session = instance:CreateGuidance(route)
session:Update(p(0, 49, 0))
target = session:Update(p(5, 50, 0))
assert(target.x == 35 and target.y == 50, "a corner passed between polls does not pull guidance backwards")
local airCorner = { totalSeconds = 2, segments = {
    { kind = "walk", terrain = true, movementMode = "skyriding", seconds = 2,
        from = p(0, 0, 100), to = p(50, 50, 100), polyline = { p(0, 0, 100), p(0, 50, 100), p(50, 50, 100) } },
} }
session = instance:CreateGuidance(airCorner)
session:Update(p(0, 49, 100))
target = session:Update(p(5, 50, 100))
assert(target.x == 50 and target.y == 50 and target.z == 100)

-- Climb and level flight have different time weights, even after coalescing.
local flightProfile = { skyridingSpeed = 10, climbSpeed = 2, descentSpeed = 5 }
local low, summit, endPoint = p(0, 0, 0), p(100, 0, 100), p(200, 0, 100)
local timed = { totalSeconds = 70, segments = {
    { kind = "walk", terrain = true, movementMode = "skyriding", seconds = 60, from = low, to = summit, polyline = { low, summit } },
    { kind = "walk", terrain = true, movementMode = "skyriding", seconds = 10, from = summit, to = endPoint, polyline = { summit, endPoint } },
} }
local assembly = instance:CreateTerrainRouteBuild(timed, { movementProfile = flightProfile })
local assemblyState, assembled
repeat assemblyState, assembled = assembly:Step(5, 1) until assemblyState ~= "planning"
assert(assemblyState == "ready" and #assembled.segments == 1)
session = instance:CreateGuidance(assembled, { movementProfile = flightProfile })
session:Update(summit)
assert(math.abs(session.remainingSeconds - 10) < 0.00001, "ETA retains climb cost before the summit and level cost after it")
local delayed = { totalSeconds = 13, segments = {
    { kind = "walk", terrain = true, movementMode = "skyriding", seconds = 13, transitionSeconds = 3,
        from = low, to = p(100, 0, 0), polyline = { low, p(100, 0, 0) } },
} }
session = instance:CreateGuidance(delayed, { movementProfile = flightProfile })
session:Update(p(0, 0, 0)); assert(session.remainingSeconds == 13)
session:Update(p(50, 0, 0)); assert(math.abs(session.remainingSeconds - 5) < 0.00001, "departure delay is consumed once movement starts")
session = instance:CreateGuidance(crossing)
session:Update(p(-1000, 0, 0))
assert(select(2, session:Update(p(1000, 0, 0))) ~= "arrived", "a teleport cannot sweep through a mandatory point")
print("Terrain guidance: safe lookahead, continuous ETA, 3D deviation, swept arrival and cancellation passed")
