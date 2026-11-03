local Fixture = {}

function Fixture.Load()
    local namespace = {}
    local root = "APR-Core/libs/LibAPRNavigation-2.0/"
    local manifest = assert(io.open(root .. "LibAPRNavigation.xml", "r"))
    local xml = manifest:read("*a")
    manifest:close()
    for name in xml:gmatch('<Script%s+file="([^"]+)"') do
        assert(loadfile(root .. name))("APR", namespace)
    end
    return namespace.LibAPRNavigationV2, namespace
end

Fixture.Library = Fixture.Load()

function Fixture.New(graph, budgets)
    local time = { wall = 0, cpu = 0, tick = 0 }
    local planner, reason = Fixture.Library.New(graph, {
        clock = function() return time.wall end,
        profileClock = function()
            local value = time.cpu
            time.cpu = value + time.tick
            return value
        end,
        budgets = budgets,
    })
    assert(planner, reason)
    return planner, time
end

function Fixture.Finish(job, operations)
    for _ = 1, 10000 do
        local result = assert(job:Step(operations or 3))
        if result.status ~= "running" then return result end
    end
    error("Job did not terminate")
end

function Fixture.Graph()
    return {
        complete = true,
        nodes = { "start", "gate", "far", "goal" },
        edges = {
            { id = "direct", from = "start", to = "goal", seconds = 1 },
            { id = "approach", from = "start", to = "gate", seconds = 4 },
            { id = "passage", from = "gate", to = "far", seconds = 2 },
            { id = "finish", from = "far", to = "goal", seconds = 3 },
            { id = "detour", from = "gate", to = "goal", seconds = 20 },
        },
    }
end

return Fixture
