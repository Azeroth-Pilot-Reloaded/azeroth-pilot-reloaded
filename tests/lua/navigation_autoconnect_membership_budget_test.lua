-- Interior membership rules out every automatic walk at that endpoint;
-- explicit geometry/portal arcs must remain available without pairwise scans.
local engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
local function point(index, world, inside)
    return {x = index, y = 0, instanceID = world or 8, region = "invented-region", inside = inside}
end
local start, goal = point(0), point(999, 9)
local nodes, edges = {}, {}
local previous = start
for index = 1, 420 do
    local node = point(index, 8, true)
    nodes[index] = node
    edges[#edges + 1] = {kind = "walk", terrain = true, from = previous, to = node, seconds = 1}
    previous = node
end
edges[#edges + 1] = {kind = "portal", from = previous, to = goal, seconds = 7}
local now, membershipReads, permissionReads, speedReads, regionReads = 0, 0, 0, 0, 0
local function request()
    return {start = start, goal = goal, edges = edges,
        clock = function() return now end,
        canAutoconnectAt = function(p)
            membershipReads, now = membershipReads + 1, now + 0.05
            if p.inside then return false end
            -- Unknown membership keeps the normal permission predicate.
        end,
        canWalk = function(a, b)
            permissionReads, now = permissionReads + 1, now + 0.25
            return not a.inside and not b.inside
        end,
        walkSpeedAt = function() speedReads, now = speedReads + 1, now + 0.05; return 7 end,
        walkingRegionFor = function(p) regionReads = regionReads + 1; return p.region end}
end
local search = engine:CreateSearch(request())
assert(now == 0 and membershipReads == 0 and speedReads == 0 and regionReads == 0,
    "Creating a search cannot classify native endpoints or invoke host speed/region callbacks")
local function finish(job, bound)
    for slice = 1, bound or 5000 do
        local began = now
        local status = job:Step(4096, 1)
        assert(job.workLastStep <= 4096 and now - began <= 1.051,
            "Membership preparation remains in the same resumable frame budget")
        if status ~= "planning" then return job:GetResult(), slice end
    end
    error("Endpoint membership fixture exceeded its finite work bound")
end
local result, slices = finish(search)
assert(result.totalSeconds == 427 and #result.segments == 421 and result.segments[#result.segments].kind == "portal",
    "Every explicit interior transition and the physical portal remain usable")
assert(membershipReads == #nodes + 2 and permissionReads == 0 and speedReads == 2 and slices < 50,
    "Classify each endpoint once instead of repeatedly rejecting all pairs of interior nodes")

local a, b = point(0), point(10)
membershipReads = 0
search = engine:CreateSearch({start = a, goal = b, walkSpeed = 1,
    canAutoconnectAt = function() membershipReads = membershipReads + 1 end})
assert(membershipReads == 0)
result = finish(search)
assert(result.totalSeconds == 10 and membershipReads == 2,
    "An unknown membership response never suppresses a legal automatic walk")
search = engine:CreateSearch({start = a, goal = b, canAutoconnectAt = function() return false end,
    canWalk = function() error("An excluded endpoint has no automatic walk, including the direct shortcut") end})
assert(not finish(search), "A direct route cannot bypass an authoritative endpoint exclusion")

-- Personal travel is explicit too; it can escape an excluded native origin.
a.inside = true
search = engine:CreateSearch({start = a, goal = goal, canAutoconnectAt = function() return false end,
    edges = {{kind = "spell", from = b, to = goal, sourceFree = true, seconds = 3}}})
result = finish(search)
assert(result.totalSeconds == 3 and #result.segments == 1 and result.segments[1].from == a,
    "An item/spell cast in place does not need a fabricated walking link")

-- Exclusions belong to the current immutable graph. A fresh observation can
-- rebuild with new geometry, while a cancelled graph remains retired.
local allowed, calls = false, 0
local function fresh()
    return engine:CreateSearch({start = a, goal = b, walkSpeed = 1,
        canAutoconnectAt = function() calls = calls + 1; return allowed end})
end
search = fresh()
assert(not finish(search))
allowed = true
search = fresh()
result = finish(search)
assert(result.totalSeconds == 10 and calls == 4, "New requests do not reuse a previous endpoint exclusion")
search = fresh()
search:Step(1, 1)
search:Cancel()
local before = calls
assert(search:Step(4096, 1) == "cancelled" and calls == before,
    "Retired membership work cannot resume or publish from a stale callback")
print("Automatic walking membership: deferred bounded preparation, dense interiors, explicit escape and fresh/cancelled graph lifetime passed")
