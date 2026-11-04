-- Presentation work belongs to selected guidance and relevant blockers, not
-- every candidate in a catalogue. No shipped routes or translations are used.
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
for _, name in ipairs({ "Core", "Conditions", "Geography", "Catalog", "Search", "ZoneRouting" }) do
    dofile(root .. name .. ".lua")
end
local library = LibStub("LibAPRNavigation-1.0")
local function point(world, area)
    return { space = "world", instanceID = world, x = 0, y = 0, noAutoconnect = true,
        region = "synthetic", areaID = area, uiMapID = world + 2000 }
end
local start, goal = point(0, 0), point(1001, 1001)
local definitions = {}
for i = 1, 500 do
    definitions[i] = { id = "unused-" .. i, kind = "portal", from = start, to = point(i, i), seconds = 1 }
end
definitions[501] = { id = "selected", kind = "portal", from = start, to = goal, seconds = 2,
    requirements = { quest = 77 }, instructionKey = "USE_BOAT" }

local function fixture(profile)
    local s = { names = 0, rows = 0, allowed = true, now = 0 }
    library:RegisterData(profile, "synthetic", { connections = definitions })
    local data = library:New({ profile = profile, environment = {
        getCharacter = function() return {} end,
        isQuestCompleted = function() return s.allowed end,
        getAreaName = function(id)
            s.names, s.now = s.names + 1, s.now + 0.25
            if s.cancelOnName then s.job:Cancel() end
            return "Area " .. id
        end,
        getSpellName = function() s.names = s.names + 1; return "Spell name" end,
    } })
    function data:GetText(key)
        return ({ USE_PORTAL_TO = "Portal %s", USE_BOAT = "Board %s", USE_SPELL = "Cast %s",
            UNKNOWN = "Unknown", RUN_WAYPOINT = "Walk %s" })[key] or key
    end
    APR = {}
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    s.data, s.request = data, {
        data = data, engine = library.Engine, start = start, goal = goal,
        deferInstructions = true, clock = function() return s.now end,
        taxiData = { BuildEdges = function() return {}, {} end },
        prepareSegment = function(segment)
            assert(type(segment.instruction) == "string" and not segment.instructionDeferred,
                "A selected transport must have its label before the UI sees it")
            s.rows = s.rows + 1
            return { label = segment.instruction }
        end,
    }
    function s:create()
        self.job = APR.NavigationPlanner:Create(self.request)
        return self.job
    end
    function s:finish()
        local count = 0
        while self.job.status == "planning" do
            local before = self.now
            self.job:Step(8, 1)
            assert(self.now - before <= 1, "Name resolution stays within scheduled publication slices")
            count = count + 1; assert(count < 5000)
        end
        return self.job:GetResult()
    end
    return s
end

for _, profile in ipairs({ "retail", "forever" }) do
    local s = fixture(profile)
    local eager = s.data:BuildEdges({})
    assert(#eager == 501 and s.names == 501 and eager[501].instruction == "Board Area 1001"
        and not eager[501].instructionDeferred and eager[501].instructionKey == nil,
        "Existing library consumers still receive complete eager labels by default")
    s.names = 0
    local deferred = s.data:BuildEdges({ deferInstructions = true })
    assert(#deferred == 501 and s.names == 0 and deferred[501].instructionDeferred,
        "An opted-in build performs no presentation queries for discarded candidates")
    s:create()
    local result = s:finish()
    assert(s.job.status == "ready" and result.totalSeconds == 2 and #result.queue == 1
        and result.queue[1].label == "Board Area 1001" and s.names == 1 and s.rows == 1,
        "Only the winning transport needs a label, including its custom instruction key")
    print(string.format("Deferred instructions %s: 501 candidate names -> %d selected name", profile, s.names))

    s = fixture(profile)
    s.allowed = false
    s:create(); s:finish()
    assert(s.job.status == "no_path" and #s.job.blockers == 1 and s.rows == 0 and s.names == 1
        and s.job.blockers[1].instruction == "Board Area 1001",
        "Failure explanations still label the relevant blocked passage without presenting a route")

    s = fixture(profile)
    s:create()
    while s.job.phase ~= "queue" do s.job:Step(8, 1) end
    assert(s.names == 0)
    s.job:Cancel()
    assert(s.job:Step(100, 1) == "cancelled" and s.names == 0 and s.rows == 0,
        "Cancelled planning cannot fetch names or publish rows")

    for _, allowed in ipairs({ true, false }) do
        s = fixture(profile)
        s.cancelOnName, s.allowed = true, allowed
        s:create(); s:finish()
        assert(s.job.status == "cancelled" and s.names == 1 and s.rows == 0,
            "A name provider that cancels the job cannot publish guidance or blockers")
    end

    for _, cancel in ipairs({ false, true }) do
        s = fixture(profile)
        s.allowed, s.cancelOnName = false, cancel
        s.request.preferZoneAccess = true
        s.data.config.ZoneRoutes = { [goal.uiMapID] = "selected" }
        s:create(); s:finish()
        assert(s.names == 1 and s.rows == 0)
        if cancel then
            assert(s.job.status == "cancelled" and not s.job.blockers,
                "Zone blocker name resolution also respects cancellation")
        else
            assert(s.job.status == "no_path" and s.job.zoneRouted and #s.job.blockers == 1
                and s.job.blockers[1].instruction == "Board Area 1001",
                "An authored zone entrance publishes its deferred failure explanation")
        end
    end

    s = fixture(profile)
    local segments = {}
    for i = 1, 40 do segments[i] = { kind = "portal", to = point(i, i), instructionDeferred = true } end
    s.request.engine = { CreateSearch = function()
        return { Step = function() return "ready", { segments = segments, totalSeconds = 40 } end }
    end }
    s:create()
    result = s:finish()
    assert(#result.queue == 40 and s.names == 40 and s.rows == 40,
        "A long selected itinerary resolves every label across bounded slices")

    s = fixture(profile)
    s.data.env.getAreaName = function() return nil end
    s:create()
    result = s:finish()
    assert(result.queue[1].label == "Board Unknown", "Unavailable names preserve the existing fallback")

    s = fixture(profile)
    assert(s.data:GetEdgeInstruction({ kind = "spell", action = { type = "spell", data = 17 }, to = goal })
        == "Cast Spell name (Area 1001)", "Action labels keep their native name and destination")
    local before = s.names
    assert(s.data:GetEdgeInstruction({ instruction = "Supplied label" }) == "Supplied label" and s.names == before,
        "Explicit labels do not need native lookups")
end
