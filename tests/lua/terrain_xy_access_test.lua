local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
dofile("APR-Core/libs/LibAPRNavigation-1.0/Search.lua")
local start, goal = F.point(1, 1), F.point(4, 1)
start.region, goal.region = "outdoors", "outdoors"
local map = F.map()
local function storey(x, links)
    return F.number(x * 8 + 1, 3) .. "BB" .. F.number(2068, 2) .. F.number(links, 2)
end
map.floor[1] = "AAB" .. storey(4, 0) .. "AAA"
local provider = F.provider(lib, map)
local function route(a, b, options)
    local state, result = F.finish(provider:CreatePathJob(a, b, options), 1)
    if state == "ready" or state == "partial" then
        for i = 2, #result.path do
            assert(provider:CanFollowWalkingSegment(result.path[i-1], result.path[i]))
        end
    end
    return state, result
end
local state, routeXY = route(start, goal, {walkingGoalXY = true})
assert(state == "ready" and routeXY.path[#routeXY.path].z == 0 and goal.z == nil)
assert(route(start, goal, {}) == "unavailable")
assert(route(goal, start, {walkingGoalXY = true}) == "unavailable")
local corridor = {kind = "walk", path = {F.point(3, 1, 0), F.point(5, 1, 0)}}
corridor.path[1].region, corridor.path[2].region = "outdoors", "outdoors"
assert(route(goal, start, {walkingOriginCorridor = corridor}) == "ready" and goal.z == nil)
map.floor[1] = "AAB" .. storey(4, 2) .. "AAA"
F.provider(lib, map, 2)
assert(route(start, goal, {walkingGoalXY = true}) == "unavailable",
    "Two reachable storeys cannot identify one XY target")
assert(route(start, goal, {walkingGoalXY = true, walkingGoalApproach = 0.9 * F.cellSize}) == "unavailable",
    "An approach cannot choose either storey at the ambiguous pin")
state, routeXY = route(start, goal, {walkingGoalXY = true, walkingGoalApproach = 1.1 * F.cellSize})
assert(state == "ready" and routeXY.approach and routeXY.approach.z == 0 and goal.z == nil)
F.near(routeXY.approach.x, F.point(3, 1).x)
F.near(routeXY.remainingYards, F.cellSize)

local wall = F.map({wall = true, disconnected = true})
F.provider(lib, wall, 3)
local blocked = F.point(3, 1)
local radius = 0.6 * F.cellSize
state, routeXY = route(start, blocked, {walkingGoalRange = radius})
assert(state == "ready")
local arrival = routeXY.path[#routeXY.path]
assert(arrival.x < blocked.x and (arrival.x-blocked.x)^2 + (arrival.y-blocked.y)^2 < radius^2)
assert(blocked.x == 3.5 * F.cellSize and blocked.z == nil)
assert(route(start, blocked, {walkingGoalRange = 0.4 * F.cellSize}) == "unavailable")
local area = F.point(4, 1)
local insideRange = 1.75 * F.cellSize
state, routeXY = route(start, area, {walkingGoalRange = insideRange, walkingGoalPreferRange = true})
assert(state == "ready")
arrival = routeXY.path[#routeXY.path]
assert(arrival.x < area.x and (arrival.x-area.x)^2 + (arrival.y-area.y)^2 < insideRange^2)
assert(area.z == nil and area.x == 4.5 * F.cellSize)
local voidState, voidApproach = route(start, blocked, {walkingGoalXY = true, walkingPartialGoal = true})
assert(voidState == "partial" and voidApproach.remainingHeight == nil)
assert(voidApproach.geometryVerified == false, "Coarse reachability does not attest a swept body")
F.near(voidApproach.approach.x, F.point(2, 1).x)

-- A map pin on an obstruction can use a bounded, measured approach after
-- a mandatory entrance. Keep the actual stopping point in the itinerary.
local outdoor = F.point(1, 1, 0)
outdoor.region = "outside"
local interiorLanding = F.point(1, 1, 0)
interiorLanding.region, blocked.region = "inside", "inside"
local function enter(approachRadius, batch)
    return F.finish(lib.Engine:CreateSearch({
        start = outdoor, goal = blocked, walkingProvider = provider, walkingGoalXY = true,
        walkingGoalApproach = approachRadius, batchTerrainWork = batch, walkingSpeedCeiling = 7,
        edges = { { kind = "elevator", from = outdoor, to = interiorLanding, seconds = 5 } },
    }), 32)
end
assert(enter() ~= "ready")
assert(enter(0.9 * F.cellSize) ~= "ready", "An approach beyond the limit cannot stand in for the pin")
for _, batch in ipairs({true, false}) do
    local entered, result = enter(1.1 * F.cellSize, batch)
    assert(entered == "ready" and #result.segments == 2)
    assert(result.segments[1].kind == "elevator" and result.segments[1].mandatory)
    local final = result.segments[2]
    assert(final.approachOnly and final.to.region == "inside")
    F.near(final.to.x, F.point(2, 1).x)
    F.near(final.path[#final.path].x, final.to.x)
    F.near(result.totalSeconds, 5 + F.cellSize / 7)
end
blocked.region = nil

local distant = F.point(6, 1)
assert(route(start, distant, {walkingGoalXY = true}) == "no_path")
state, routeXY = route(start, distant, {walkingGoalXY = true, walkingPartialGoal = true})
assert(state == "partial" and routeXY.partial and routeXY.goal ~= distant)
F.near(routeXY.approach.x, F.point(2, 1).x)
F.near(routeXY.approach.y, distant.y)
F.near(routeXY.remainingYards, 4 * F.cellSize)
F.near(routeXY.remainingHeight, 0)
assert(routeXY.goal.x == distant.x and distant.z == nil)
assert(route(start, F.point(2, 1), {walkingGoalXY = true, walkingPartialGoal = true}) == "ready")

local function search()
    local job = lib.Engine:CreateSearch({start = start, goal = goal, walkingProvider = provider,
        walkingSpeedCeiling = 7, batchTerrainWork = true})
    return F.finish(job, 32)
end
local corrupt = F.map()
corrupt.height[1] = "!"
F.provider(lib, corrupt, 4)
assert(search() == "waiting_data", "A covered but unreadable page cannot produce an estimated walk")
F.provider(lib, F.map(), 5)
state, routeXY = search()
assert(state == "ready" and #routeXY.segments[1].path >= 2)

local bent = F.map({wall = true})
local goals = {F.point(6, 1), F.point(5, 2), F.point(6, 3)}
local function measure(job)
    local ops = 0
    repeat
        local status, result = job:Step(4, 10)
        ops = ops + job.workLastStep
        if status ~= "planning" then return status, result, ops end
    until false
end
F.provider(lib, bent, 6)
local batch, work
state, batch, work = measure(provider:CreateCostJob(start, goals, {}))
assert(state == "ready" and #batch.costs == 3)
F.provider(lib, bent, 7)
local separate = 0
for i, p in ipairs(goals) do
    local status, path, ops = measure(provider:CreatePathJob(start, p, {}))
    assert(status == "ready" and batch.costs[i].state == "ready")
    F.near(path.yards, batch.costs[i].yards)
    separate = separate + ops
end
assert(work < separate, "Nearby targets share the settled departure tree")

local masked = F.map()
-- Forbid travel toward increasing world X in the destination cell. The
-- pack separately certifies its adjacent centre-to-centre grid edges.
masked.clearance = {F.number(4 * 8 + 1, 3) .. F.number(1, 3)}
F.provider(lib, masked, 8)
local endpoint = F.point(4, 1)
endpoint.x = endpoint.x + 0.25 * F.cellSize
state, routeXY = route(start, endpoint, {})
assert(state == "ready" and routeXY.path[#routeXY.path].x == endpoint.x and #routeXY.path >= 3)
assert(provider:CanFollowWalkingSegment(F.point(3, 1, 0), F.point(4, 1, 0)))
assert(not provider:CanFollowWalkingSegment(F.point(4, 1, 0), routeXY.path[#routeXY.path]))
assert(provider:CanFollowWalkingSegment(routeXY.path[#routeXY.path], F.point(4, 1, 0)))
masked.clearance[1] = F.number(4 * 8 + 1, 3) .. F.number(65535, 3)
F.provider(lib, masked, 9)
endpoint.y = endpoint.y + 0.13 * F.cellSize
assert(route(start, endpoint, {}) ~= "ready", "No arbitrary chord through a full obstruction")

local cell = 4 * 8 + 1
local center = F.point(4, 1, 0)
local function inside(fx, fy, z)
    return {instanceID = 900, x = center.x + fx*F.cellSize, y = center.y + fy*F.cellSize, z = z}
end
local masks = {F.number(cell, 3)}
for i = 0, 15 do masks[#masks + 1] = F.number(i == 6 and 1 or 0, 3) end
masked.subclearance = {table.concat(masks)}
F.provider(lib, masked, 10)
local function proof(a, b)
    return F.finish(provider:CreateWalkingSegmentJob(a, b, {}))
end
assert(proof(inside(-.4, -.2, 0), inside(.4, -.2, 0)) == "ready")
assert(proof(inside(-.4, .1, 0), inside(.4, .1, 0)) == "no_path")
assert(proof(inside(.4, .1, 0), inside(-.4, .1, 0)) == "ready")
local heights = {F.number(cell, 3), "AAA"}
for _, z in ipairs({0, 0, 80, 80, 0}) do heights[#heights + 1] = F.number(131072 + z*32, 3) end
masked.support = {table.concat(heights)}
F.provider(lib, masked, 11)
assert(proof(inside(.1, 0, 16), inside(.4, 0, 64)) == "no_path")
assert(proof(center, F.point(5, 1, 0)) == "no_path",
    "A centre-to-centre graph edge still has to follow its intervening terrain triangles")
state, routeXY = route(F.point(3, 1, 0), F.point(5, 1, 0), {})
assert(state == "ready" and #routeXY.path > 2 and routeXY.yards > 2 * F.cellSize,
    "A blocked interior edge can be replaced with a longer verified local detour")
assert(proof(inside(.4, 0, 64), inside(.1, 0, 16)) == "ready")
assert(proof(inside(.4, -.1, 64), inside(.4, .1, 64)) == "no_path",
    "A level chord across a steep face cannot be used to traverse the hillside")
F.near(provider:GetGuidanceHeight(inside(.25, 0)), 40)
assert(proof(inside(-.4, .1, 0), inside(-.3, .1, 0)) == "ready",
    "A flat triangle beside a steep triangle has its own slope")

F.provider(lib, F.map({wall = true, disconnected = true}), 12)
local outside = F.point(12, 1)
outside.region = start.region
local function detour(edges)
    return F.finish(lib.Engine:CreateSearch({start = start, goal = goal, edges = edges,
        walkingProvider = provider, batchTerrainWork = true, walkingSpeedCeiling = 7}), 32)
end
assert(detour({{kind = "boat", from = outside, to = outside, seconds = 1}}) ~= "ready",
    "Two estimates via an uncovered transport stop cannot cross a proven wall")
state, routeXY = detour({{kind = "boat", from = start, to = outside, seconds = 5},
    {kind = "portal", from = outside, to = goal, seconds = 7}})
assert(state == "ready" and #routeXY.segments == 2 and routeXY.segments[1].kind == "boat"
    and routeXY.segments[2].kind == "portal")

-- A small directed gallery beneath a second, isolated floor. The coarse
-- terrain is open in both directions, so falling back would hide a refusal.
local function little(value, size)
    local bytes = {}
    for i = 1, size do
        bytes[i] = string.char(value % 256)
        value = math.floor(value / 256)
    end
    return table.concat(bytes)
end
local function double(value)
    if value == 0 then return string.rep("\0", 8) end
    local fraction, exponent = math.frexp(value)
    return little(0, 4) .. little((exponent + 1022 + 2 * fraction - 1) * 1048576, 4)
end

-- A coarse row crosses a doorway whose clearance requires a turn between
-- cell centres. Only the detailed lattice contains the bend.
do
    local function doorway(sealed)
        local data = F.map()
        data.cells = 128
        data.grid[1] = string.rep("AAQ" .. string.rep("A", 125), 128)
        data.height[1] = string.rep("X", 128)
        data.class[1] = string.rep("A", 128 * 128)

        local vertices, faces, nodes = {}, {}, {}
        local function vertex(x, y, z)
            local index = #vertices
            vertices[index + 1] = double(x) .. double(y) .. double(z)
            return little(index, 4)
        end
        local a, b, c, d = vertex(7, 7, 0), vertex(43, 7, 0), vertex(43, 15, 0), vertex(7, 15, 0)
        faces[1], faces[2] = "\0" .. a .. b .. c, "\0" .. a .. c .. d
        local top = sealed and 15 or 11
        a, b, c, d = vertex(19.5, 7, 0), vertex(19.5, top, 0), vertex(19.5, top, 3), vertex(19.5, 7, 3)
        faces[3], faces[4] = "\1" .. a .. b .. c, "\1" .. a .. c .. d
        for x = 8, 40 do
            for y = 10, 12 do
                local edges = {}
                if x < 40 and (x ~= 19 or not sealed and y == 12) then edges[#edges + 1] = "\0\0" end
                if x > 8 and (x ~= 20 or not sealed and y == 12) then edges[#edges + 1] = "\1\0" end
                if y < 12 then edges[#edges + 1] = "\2\0" end
                if y > 10 then edges[#edges + 1] = "\3\0" end
                nodes[#nodes + 1] = little(x, 2) .. little(y, 2) .. double(0) .. "\0"
                    .. little(#edges, 2) .. table.concat(edges)
            end
        end
        local window = "SFC1" .. little(8, 2) .. little(8, 2) .. little(40, 2) .. little(14, 2)
            .. little(#nodes, 4) .. little(#vertices, 4) .. little(#faces, 4)
            .. table.concat(nodes) .. table.concat(vertices) .. table.concat(faces)
        data.surface = { "SFA1" .. little(1, 4) .. little(#window, 4) .. window }
        return data
    end
    local unit = (1600 / 3) / 128
    local from = { instanceID = 901, x = unit / 2, y = 2.5 * unit, z = 0 }
    local to = { instanceID = 901, x = 7.5 * unit, y = from.y, z = 0 }
    local function check(sealed)
        -- Keep this fixture in its own world so subsequent fixture revisions
        -- and caches do not affect it.
        lib:RegisterTerrainData("forever", 901, doorway(sealed), sealed and 2 or 1)
        for _, endpoints in ipairs({ { from, to }, { to, from } }) do
            local status, result = route(endpoints[1], endpoints[2], {})
            if sealed then
                assert(status ~= "ready", "A closed doorway must remain impassable")
            else
                assert(status == "ready", status)
                assert(#result.path > 2 and result.yards > to.x - from.x)
                for index = 2, #result.path do
                    assert(provider:CanFollowWalkingSegment(result.path[index - 1], result.path[index]))
                end
            end
        end
    end
    check(false)
    check(true)
end

local vertices, faces, nodes = {}, {}, {}
for i, z in ipairs({0, 4}) do
    for _, point in ipairs({{0, 0}, {12, 0}, {0, 12}}) do
        vertices[#vertices+1] = double(point[1]) .. double(point[2]) .. double(z)
    end
    local first = 3 * (i-1)
    faces[i] = string.char(1) .. little(first, 4) .. little(first+1, 4) .. little(first+2, 4)
end
for x = 1, 8 do
    for i, z in ipairs({0, 4}) do
        local edge = x < 8 and i == 1 and string.char(0, 0) or ""
        nodes[#nodes+1] = little(x, 2) .. little(1, 2) .. double(z) .. string.char(i-1)
            .. little(#edge/2, 2) .. edge
    end
end
local window = "SFC1" .. little(0, 2) .. little(0, 2) .. little(9, 2) .. little(2, 2)
    .. little(#nodes, 4) .. little(#vertices, 4) .. little(#faces, 4)
    .. table.concat(nodes) .. table.concat(vertices) .. table.concat(faces)
local fineMap = F.map({class="E"})
fineMap.surface = {"SFA1" .. little(1, 4) .. little(#window, 4) .. window}
F.provider(lib, fineMap, 13)
local source = {instanceID = 900, x = 1.2, y = 1.1, z = 0}
local target = {instanceID = 900, x = 7.8, y = 1.1}
local provenTarget = {instanceID = 900, x = target.x, y = target.y, z = 0, geometryVerified = true}
assert(provider:CanFollowWalkingSegment(source, provenTarget) == nil,
    "A certified segment with a cold atlas needs its bounded reload")
assert(proof(source, provenTarget) == "ready")
assert(provider:CanFollowWalkingSegment(source, provenTarget) == true)
local roofTarget = {instanceID = 900, x = target.x, y = target.y, z = 4, geometryVerified = true}
assert(provider:CanFollowWalkingSegment(source, roofTarget) == false,
    "A loaded atlas can reject a chord between disconnected floors")
assert(provider:CanFollowWalkingSegment(source, roofTarget, true) == false,
    "A live join still needs native proof inside a detailed window")
assert(provider:CanFollowWalkingSegment(source, roofTarget, "outdoor") == false)
state, routeXY = route(source, target, {walkingGoalXY = true})
assert(state == "ready" and routeXY.path[#routeXY.path].z == 0)
assert(routeXY.geometryVerified == true)
assert(routeXY.path[#routeXY.path].x == target.x and routeXY.path[#routeXY.path].y == target.y)
assert(#routeXY.path == 2 and provider:CanFollowWalkingSegment(source,routeXY.path[2]))
F.near(routeXY.yards, 6.6)
local interior = {instanceID=900, x=source.x, y=source.y, indoors=true}
state, routeXY = route(interior, target, {walkingGoalXY = true})
assert(state == "ready" and routeXY.geometryVerified and routeXY.path[1].z == 0,
    "The indoor observation and terrain classification distinguish a floor from the roof above it")
assert(provider:GetGuidanceHeight(interior) == 0 and interior.z == nil)
interior.indoors = nil
assert(provider:GetGuidanceHeight(interior) == nil and route(interior, target, {walkingGoalXY = true}) == "unavailable")
assert(route(source, target, {}) == "unavailable")
target.z = 4
assert(route(source, target, {}) ~= "ready")
target.z = 0
assert(route(target, source, {}) ~= "ready")
local exterior = {instanceID = 900, x = 15, y = target.y, z = 0}
assert(proof(target, exterior) == "ready" and proof(exterior, target) == "ready")
target.z = 4
assert(proof(target, exterior) == "no_path" and proof(exterior, target) == "no_path")
fineMap.surface[1] = fineMap.surface[1]:sub(1,-2)
F.provider(lib, fineMap, 14)
assert(route(source, target, {}) == "unavailable")

local revision = 14
local halfNodes = {}
for ix = 2, 16 do
    local edge = ix < 16 and string.char(0, 0) or ""
    halfNodes[#halfNodes+1] = little(ix, 4) .. little(3, 4) .. double(0)
        .. string.char(0) .. little(#edge/2, 2) .. edge
end
local halfWindow = "SFC2" .. window:sub(5,12) .. little(#halfNodes, 4) .. window:sub(17,24)
    .. table.concat(halfNodes) .. table.concat(vertices) .. table.concat(faces)
fineMap.surface[1] = "SFA1" .. little(1,4) .. little(#halfWindow,4) .. halfWindow
revision = revision + 1
F.provider(lib, fineMap, revision)
target.z = 0
state, routeXY = route(source, target, {})
assert(state == "ready" and #routeXY.path == 2, "Half-yard samples simplify to a single certified chord")
assert(proof(routeXY.path[1],routeXY.path[2]) == "ready")

for name, width in pairs({subclearance = 51, support = 21}) do
    local records = {}
    for node = 0, 58 do
        records[#records+1] = F.number(node, 3) .. string.rep("A", width-3)
    end
    local valid = table.concat(records)
    for _, offset in ipairs({512, 513, 1024, 1025, #valid}) do
        local data = F.map()
        data[name] = {valid:sub(1, offset-1) .. "!" .. valid:sub(offset+1)}
        revision = revision + 1
        F.provider(lib, data, revision)
        local job = provider:CreatePathJob(start, goal, {})
        assert(F.finish(job) == "unavailable" and tostring(job.error):find("invalid terrain record character"))
    end
end

-- The same world instance can contain an isolated city. Only its declared
-- boundary or transport may change regions, even for a free map marker.
local exteriorDoor, interiorDoor = F.point(2, 1, 0), F.point(4, 1, 0)
exteriorDoor.region, interiorDoor.region = "outside", "inside"
local border = {from=exteriorDoor,to=interiorDoor,seconds=2,kind="walk"}
local lift = {from=exteriorDoor,to=interiorDoor,seconds=8,kind="elevator"}
local function city(edges)
    return F.finish(lib.Engine:CreateSearch({start=exteriorDoor,goal=interiorDoor,edges=edges,
        walkingProvider=provider,walkingSpeedCeiling=7,batchTerrainWork=true}), 16)
end
F.provider(lib,F.map(),revision+1)
assert(route(exteriorDoor,interiorDoor,{walkingGoalXY=true,walkingPartialGoal=true}) == "no_path")
assert(city({}) ~= "ready")
state,routeXY = city({border,lift})
assert(state == "ready" and routeXY.segments[1].kind == "walk" and #routeXY.segments[1].path == 2)
F.provider(lib,F.map({wall=true,disconnected=true}),revision+2)
assert(city({border}) == "no_path")
state,routeXY = city({border,lift})
assert(state == "ready" and #routeXY.segments == 1 and routeXY.segments[1].kind == "elevator")

-- Several ferries arrive at the same isolated landing. A missing departure
-- surface rules out all automatic walks from that landing, while an explicit
-- onward transport can still use it.
local origin,landing,destination = F.point(0,0,0), F.point(3,0), F.point(5,0,0)
origin.region,landing.region,destination.region = "coast","island","island"
local fleet = {}
for i=1,5 do
    local port=F.point(i,1,0)
    port.region="coast"
    fleet[i]={kind="boat",from=port,to=landing,seconds=i}
end
local costCalls,departureCalls = 0,0
local mock = {RequiresWalkingProof=function() return true end}
function mock:CreateCostJob(a,targets)
    costCalls=costCalls+1
    if a==landing then departureCalls=departureCalls+1 end
    return {Step=function()
        return "ready",{costs={{state="unavailable",unresolvedSurface=true,
            unresolvedFrom=true,independentFrom=true}}}
    end}
end
local function ferries()
    return F.finish(lib.Engine:CreateSearch({start=origin,goal=destination,edges=fleet,
        walkingProvider=mock,walkingSpeedCeiling=7,batchTerrainWork=true}), 8)
end
assert(ferries() ~= "ready" and costCalls == 1 and departureCalls == 1,
    "Verify the final walk before costing distant approaches to a stranded landing")
fleet[#fleet+1]={kind="boat",from=origin,to=landing,seconds=1}
fleet[#fleet+1]={kind="elevator",from=landing,to=destination,seconds=1}
state,routeXY=ferries()
assert(state=="ready" and #routeXY.segments==2 and routeXY.segments[2].kind=="elevator")

local function landingAt(x,region)
    return {instanceID=900,x=x,y=0,z=0,region=region}
end
local shore, distant, near, gate = landingAt(0,"shore"),landingAt(20,"shore"),
    landingAt(29,"shore"),landingAt(30,"shore")
local island = landingAt(30,"island")
local checks = {}
local domains = {RequiresWalkingProof=function() return true end,
    GetWalkingPage=function(_,p) return p.x >= 29 and 2 or 1 end}
function domains:CreateCostJob(a,targets)
    local b=targets[1]
    local allowed=a==near and b==gate
    if b==gate then checks[a]=(checks[a] or 0)+1 end
    return {Step=function() return "ready",{costs={{state=allowed and "ready" or "no_path",
        seconds=allowed and 1,approachPages=b==gate and not allowed and {[2]=true} or nil}}} end}
end
function domains:CreatePathJob(a,b)
    assert(a==near and b==gate)
    return {Step=function() return "ready",{seconds=1,path={a,b}} end}
end
state,routeXY=F.finish(lib.Engine:CreateSearch({start=shore,goal=island,
    walkingProvider=domains,walkingSpeedCeiling=7,batchTerrainWork=true,edges={
        {from=shore,to=distant,kind="boat",seconds=10},
        {from=shore,to=near,kind="boat",seconds=20},
        {from=gate,to=island,kind="elevator",seconds=2}}}),16)
assert(state=="ready" and #routeXY.segments==3 and routeXY.segments[1].to.x==near.x)
assert(checks[shore]==1 and not checks[distant] and checks[near]==1,
    "A closed entrance admits approaches from its certified predecessor pages")

-- An unattainable marker can still yield a certified approach when both
-- arbitrary endpoints and the complete directed walk lie in a fine window.
local corridorNodes = {}
for x=32,168 do
    local edge = x<168 and string.char(0,0) or ""
    corridorNodes[#corridorNodes+1] = little(x,2)..little(33,2)..double(0)..string.char(0)..little(#edge/2,2)..edge
end
local plane = double(0)..double(0)..double(0)..double(400)..double(0)..double(0)..double(0)..double(400)..double(0)
local corridorWindow = "SFC1"..little(32,2)..little(32,2)..little(168,2)..little(35,2)
    ..little(#corridorNodes,4)..little(3,4)..little(1,4)..table.concat(corridorNodes)..plane..faces[1]
local approachMap=F.map({wall=true,disconnected=true})
approachMap.surface={"SFA1"..little(1,4)..little(#corridorWindow,4)..corridorWindow}
F.provider(lib,approachMap,revision+3)
for _=1,2 do
    local status,result=route(F.point(0,0),F.point(4,0),{walkingGoalXY=true,walkingPartialGoal=true})
    assert(status=="partial" and result.geometryVerified==true and result.path[#result.path].x==168)
end

-- Two disjoint fine windows share a one-way, physically certified bridge.
local function landingWindow(x)
    local n=little(x,2)..little(33,2)..double(0)..string.char(0)..little(0,2)
    local bytes="SFC1"..little(x-1,2)..little(32,2)..little(x+1,2)..little(35,2)
        ..little(1,4)..little(3,4)..little(1,4)..n..plane..faces[1]
    return little(#bytes,4)..bytes
end
local bridge=F.map()
bridge.surface={"SFA1"..little(2,4)..landingWindow(33)..landingWindow(167)}
local function physicalCell(x,east)
    return little(x*8,2)..string.char(0)..double(0)..string.char(east and 1 or 0)
        ..(east and string.char(0,0) or "")
end
bridge.canonical={"PCG1"..little(8,2)..little(3,4)..physicalCell(0,true)..physicalCell(1,true)..physicalCell(2,false)}
F.provider(lib,bridge,revision+4)
local bankA,bankB=F.point(0,0),F.point(2,0)
state,routeXY=route(bankA,bankB,{walkingGoalXY=true})
assert(state=="ready" and routeXY.geometryVerified)
local middle=F.point(1,0,0)
local half=F.point(.5,0,0)
half.geometryVerified=true
assert(provider:CanFollowWalkingSegment(half,middle))
assert(not provider:CanFollowWalkingSegment(middle,half))
local offCenter = {instanceID=900, x=middle.x-6, y=middle.y+2, z=0}
middle.geometryVerified=true
assert(provider:CanFollowWalkingSegment(offCenter,middle) == false)
assert(provider:CanFollowWalkingSegment(offCenter,middle,true) == nil,
    "A passive join leaves cold coarse terrain to the sliced terrain worker")
assert(proof(offCenter,F.point(1,0,0)) == "ready")
assert(provider:CanFollowWalkingSegment(offCenter,middle,true) == true,
    "A short off-centre join can use the resident, collision-checked outdoor terrain")
assert(provider:CanFollowWalkingSegment({instanceID=900,x=middle.x-21,y=middle.y+2,z=0},middle,true) == false,
    "Joining cannot substitute a long coarse shortcut for the certified corridor")
assert(provider:CanFollowWalkingSegment({instanceID=900,x=middle.x-21,y=middle.y+2,z=0},middle,"outdoor") == true,
    "The outdoor follower can use a wider collision-checked merge")
assert(provider:CanFollowWalkingSegment({instanceID=900,x=middle.x-6,y=middle.y+2,z=30},middle,true) == false,
    "The coarse join still has to be on the connected surface")
assert(not provider:CanFollowWalkingSegment(routeXY.path[1],routeXY.path[#routeXY.path]))
assert(route(bankB,bankA,{walkingGoalXY=true})~="ready")
bridge.canonical[1]="PCG1"..little(8,2)..little(3,4)..physicalCell(0,true)..physicalCell(1,false)..physicalCell(2,false)
F.provider(lib,bridge,revision+5)
assert(route(bankA,bankB,{walkingGoalXY=true})~="ready")

-- The total face inclination exceeds the walking grade. A descent on the
-- terrain's fall line is supported, while climbing it or walking sideways
-- on the same face cannot establish the arbitrary endpoint connector.
local slopeNodes={}
for x=2,4 do
    local edge=x<4 and string.char(0,0) or ""
    slopeNodes[#slopeNodes+1]=little(x,2)..little(1,2)..double(12-1.5*x)..string.char(0)..little(#edge/2,2)..edge
end
local slopeVerts=double(0)..double(0)..double(12)..double(8)..double(0)..double(0)..double(0)..double(8)..double(12)
local function hill(material)
    local face=string.char(material)..faces[1]:sub(2)
    local w="SFC1"..little(0,2)..little(0,2)..little(8,2)..little(8,2)
        ..little(3,4)..little(3,4)..little(1,4)..table.concat(slopeNodes)..slopeVerts..face
    local m=F.map()
    m.surface={"SFA1"..little(1,4)..little(#w,4)..w}
    return m
end
local top={instanceID=900,x=1.25,y=1}
local bottom={instanceID=900,x=4.25,y=1}
F.provider(lib,hill(0),revision+6)
state,routeXY=route(top,bottom,{walkingGoalXY=true})
assert(state=="ready" and routeXY.geometryVerified and routeXY.path[1].z==10.125)
assert(route(bottom,top,{walkingGoalXY=true})~="ready")
local sideways={instanceID=900,x=1.25,y=1.5,z=10.125,geometryVerified=true}
assert(not provider:CanFollowWalkingSegment(routeXY.path[1],sideways))
F.provider(lib,hill(1),revision+7)
assert(route(top,bottom,{walkingGoalXY=true})~="ready")

-- A known dry departure inside a region can approach a submerged pin from
-- below a second dry storey. The dry end and the original marker remain distinct.
local wetVertices=double(7)..double(0)..double(.25)..double(11)..double(0)..double(.25)
    ..double(7)..double(4)..double(.25)
local wetFace=string.char(2)..little(6,4)..little(7,4)..little(8,4)
local wetWindow=window:sub(1,16)..little(9,4)..little(3,4)..table.concat(nodes)..table.concat(vertices)
    ..wetVertices..table.concat(faces)..wetFace
local wetMap=F.map()
wetMap.surface={"SFA1"..little(1,4)..little(#wetWindow,4)..wetWindow}
F.provider(lib,wetMap,revision+8)
local pier={instanceID=900,x=1.2,y=1.1,z=0,region="harbor"}
local pin={instanceID=900,x=7.8,y=1.1,region="harbor"}
state,routeXY=route(pier,pin,{walkingGoalXY=true,walkingPartialGoal=true})
assert(state=="partial" and routeXY.geometryVerified and routeXY.goal.x==pin.x)
assert(routeXY.approach.x==6 and routeXY.approach.z==0 and routeXY.remainingYards>1)
pier.region="island"
assert(route(pier,pin,{walkingGoalXY=true,walkingPartialGoal=true})=="no_path")

-- A physical arc cannot override a directed barrier in the current grid.
bridge.canonical[1]="PCG1"..little(8,2)..little(3,4)..physicalCell(0,true)..physicalCell(1,true)..physicalCell(2,false)
local cells=bridge.grid[1]
bridge.grid[1]=cells:sub(1,8).."R"..cells:sub(10)
F.provider(lib,bridge,revision+9)
assert(route(bankA,bankB,{walkingGoalXY=true,quick=true})~="ready")

F.provider(lib,wetMap,revision+10)
pier.region="harbor"
state,routeXY=route(pier,pin,{walkingGoalRange=2,walkingGoalXY=true})
assert(state=="ready" and routeXY.geometryVerified)
local stop=routeXY.path[#routeXY.path]
assert(stop.x==6 and (stop.x-pin.x)^2+(stop.y-pin.y)^2<4 and stop.z==0)

-- A client indoor observation can resolve the departure where native altitude
-- is absent. The same XY with a different observation has no usable route.
local roomMap = F.map()
roomMap.floor[1] = "AAB" .. storey(4, 0) .. "AAA"
local cell = 4 * 8 + 1
roomMap.class[1] = string.rep("A", cell) .. "E" .. string.rep("A", 63 - cell)
F.provider(lib, roomMap, revision + 11)
local room = F.point(4, 1)
room.indoors = true
state, routeXY = route(room, start, {walkingGoalXY = true})
assert(state == "ready" and routeXY.path[1].z == 0 and room.z == nil)
room.indoors = false
assert(provider:GetGuidanceHeight(room) == 20)
assert(route(room, start, {walkingGoalXY = true}) == "no_path")

-- The outdoor observation also identifies a floor when the XY is shared.
local courtyard = F.map()
courtyard.surface = {"SFA1" .. little(1, 4) .. little(#window, 4) .. window}
F.provider(lib, courtyard, revision + 12)
local outdoor = {instanceID = source.instanceID, x = source.x, y = source.y}
local farSide = {instanceID = target.instanceID, x = target.x, y = target.y}
assert(route(outdoor, farSide, {walkingGoalXY = true}) == "unavailable")
assert(provider:GetGuidanceHeight(outdoor) == nil)
outdoor.indoors = false
state, routeXY = route(outdoor, farSide, {walkingGoalXY = true})
assert(state == "ready" and routeXY.geometryVerified and routeXY.path[1].z == 0 and outdoor.z == nil)
assert(provider:GetGuidanceHeight(outdoor) == 0)

-- A doorway drops from a model floor to terrain. The exterior destination is
-- beyond the detailed window and attaches to a directed canonical cell.
local function exitTerrain(blocked)
    local vertices, faces, nodes = {}, {}, {}
    local function quad(kind, points)
        local first = #vertices
        for _, p in ipairs(points) do
            vertices[#vertices+1] = double(p[1]) .. double(p[2]) .. double(p[3])
        end
        faces[#faces+1] = string.char(kind) .. little(first,4) .. little(first+1,4) .. little(first+2,4)
        faces[#faces+1] = string.char(kind) .. little(first,4) .. little(first+2,4) .. little(first+3,4)
    end
    quad(0, {{26,29,0}, {38,29,0}, {38,38,0}, {26,38,0}})
    quad(1, {{27,30,.5}, {31,30,.5}, {31,36,.5}, {27,36,.5}})
    quad(1, {{31,30,0}, {31,36,0}, {31,36,.5}, {31,30,.5}})
    quad(1, {{27,30,5}, {31,30,5}, {31,36,5}, {27,36,5}})
    if blocked then quad(1, {{31.25,30,0}, {31.25,36,0}, {31.25,36,2}, {31.25,30,2}}) end
    for x=58,69 do
        local edge = x~=62 and x~=69 and string.char(0,0) or ""
        nodes[#nodes+1] = little(x,4) .. little(67,4) .. double(x<=62 and .5 or 0)
            .. string.char(0) .. little(#edge/2,2) .. edge
    end
    local bytes="SFC2" .. little(26,2) .. little(29,2) .. little(37,2) .. little(37,2)
        .. little(#nodes,4) .. little(#vertices,4) .. little(#faces,4)
        .. table.concat(nodes) .. table.concat(vertices) .. table.concat(faces)
    local data=F.map()
    data.class[1]="E" .. string.rep("A",63)
    data.surface={"SFA1" .. little(1,4) .. little(#bytes,4) .. bytes}
    data.canonical={"PCG1" .. little(8,2) .. little(2,4) .. physicalCell(0,true) .. physicalCell(1,false)}
    return data
end
local roomExit={instanceID=900,x=29.75,y=33.5,z=.5,uiMapID=901,region="district",indoors=false}
local street={instanceID=900,x=101,y=34,uiMapID=902,region="district"}
F.provider(lib,exitTerrain(false),revision+13)
assert(route(roomExit,street,{walkingGoalXY=true})~="ready")
roomExit.indoors=true
for _=1,2 do
    state,routeXY=route(roomExit,street,{walkingGoalXY=true})
    assert(state=="ready" and routeXY.geometryVerified and routeXY.path[#routeXY.path].coarseEndpoint)
    assert(routeXY.path[#routeXY.path].x==street.x and routeXY.path[#routeXY.path].y==street.y and street.z==nil)
end
local egress = lib.Engine:CreateSearch({start=roomExit,goal=street,walkingProvider=provider,
    walkingGoal=street,walkingGoalXY=true,walkingSpeedCeiling=7,batchTerrainWork=true,
    edges={{from=roomExit,to=street,kind="item",seconds=30,sourceFree=true,hearthstone=true}}})
state,routeXY=F.finish(egress,32)
assert(state=="ready" and #routeXY.segments==1 and routeXY.segments[1].kind=="walk",
    "The proven exit competes as a complete walk against the available recall")
roomExit.z=nil
state,routeXY=route(roomExit,street,{walkingGoalXY=true})
assert(state=="ready" and routeXY.geometryVerified and routeXY.path[1].z==.5 and roomExit.z==nil,
    "Ground below the floor cannot resolve an indoor departure even when its coarse height matches")
assert(provider:GetGuidanceHeight(roomExit)==.5)
local sill={instanceID=900,x=30.5,y=33.5,z=.5,geometryVerified=true}
local landing={instanceID=900,x=31.5,y=33.5,z=0,geometryVerified=true}
assert(provider:CanFollowWalkingSegment(sill,landing))
assert(provider:CanFollowWalkingSegment(landing,sill)==false, "The descent supplies no reverse edge")
street.region="separate"
assert(route(roomExit,street,{walkingGoalXY=true})=="no_path")
street.region="district"
F.provider(lib,exitTerrain(true),revision+14)
assert(route(roomExit,street,{walkingGoalXY=true})~="ready", "A wall over the sill still prevents egress")

-- The outer slope and the tunnel beneath it occupy the same XY.
local classified = F.map()
classified.floor[1] = "AAC" .. storey(3, 1) .. storey(4, 2) .. "AAA"
classified.class[1] = classified.class[1] .. "EE"
F.provider(lib, classified, revision + 15)
local stack = F.point(4, 1)
stack.indoors = false
state, routeXY = route(F.point(1, 1), stack, { walkingGoalXY = true })
assert(state == "ready" and routeXY.path[#routeXY.path].z == 0 and stack.z == nil)
stack.indoors = nil
local anchored = { kind = "walk", path = { F.point(3, 1, 0), F.point(4, 1, 0) } }
assert(provider:GetWalkingCorridorHeight(stack, anchored) == nil)
anchored.walkingLanding = true
assert(provider:GetWalkingCorridorHeight(stack, anchored) == 0, "A confirmed landing supports the adjacent walking floor")

-- A detailed corridor can have many edges within a short distance. The
-- floor above it is disconnected and starts just past its unique landing.
do
    local corridor, packedNodes = {}, {}
    for x = 1, 9 do
        corridor[x] = {instanceID=900, x=x, y=1, z=0, geometryVerified=true, region="gallery"}
        local edge = x < 9 and string.char(0, 0) or ""
        packedNodes[x] = little(x, 2) .. little(1, 2) .. double(0) .. string.char(0)
            .. little(#edge / 2, 2) .. edge
    end
    local function faceVertices(x, z)
        return double(x)..double(0)..double(z) .. double(18)..double(0)..double(z)
            .. double(x)..double(18)..double(z)
    end
    local details = "SFC1" .. little(0, 2)..little(0, 2)..little(10, 2)..little(3, 2)
        .. little(#packedNodes, 4)..little(6, 4)..little(2, 4)..table.concat(packedNodes)
        .. faceVertices(0, 0)..faceVertices(2, 5)..faces[1]..faces[2]
    local gallery = F.map()
    gallery.surface = {"SFA1" .. little(1, 4) .. little(#details, 4) .. details}
    F.provider(lib, gallery, revision + 16)
    assert(route(corridor[1], corridor[#corridor], {walkingGoalXY=true}) == "ready")
    for index = 2, #corridor do assert(provider:CanFollowWalkingSegment(corridor[index - 1], corridor[index])) end
    local observed = {instanceID=900, x=8.5, y=1, region="gallery"}
    local step = {kind="walk", path=corridor, pathCursor=9}
    assert(provider:GetGuidanceHeight(corridor[1]) == 0 and provider:GetGuidanceHeight(observed) == nil)
    assert(provider:GetWalkingObservationHeight(observed) == nil)
    assert(provider:GetWalkingObservationHeight(observed, corridor[1]) == 0,
        "A previous lower floor identifies the current surface through a clear native chord")
    local upper = {instanceID=900, x=7, y=1, z=5}
    assert(provider:GetWalkingObservationHeight(observed, upper) == 5,
        "The same XY can belong to the other floor when movement began there")
    upper.z = 2.5
    assert(provider:GetWalkingObservationHeight(observed, upper) == nil,
        "A point between floors supplies no movement evidence")
    assert(provider:GetWalkingCorridorHeight(observed, step) == 0,
        "Short segments do not push a nearby independent surface witness out of reach")
    corridor[2].region = "closed"
    assert(provider:GetWalkingCorridorHeight(observed, step) == nil,
        "The extended witness search cannot cross an access boundary")
end
