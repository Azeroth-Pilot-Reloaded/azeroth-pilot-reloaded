-- Give each fake operation a known CPU cost. The pipeline must spend one shared
-- allowance, including preparation and row conversion, before yielding again.
APR = {}
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local now, calls, created = 0, {}, {}
local function clock() return now end
local function Work(name, output, metadata)
    created[name] = (created[name] or 0) + 1
    local job = { remaining = 20 }
    function job:Step(maxOperations, milliseconds)
        local deadline = now + milliseconds
        calls[name] = (calls[name] or 0) + 1
        for _ = 1, maxOperations do
            if now + 0.25 > deadline then return "planning" end
            now = now + 0.25
            self.remaining = self.remaining - 1
            if self.remaining == 0 then return "ready", output, metadata end
        end
        return "planning"
    end
    function job:Cancel() self.cancelled = true end
    return job
end

local catalogueEdges, taxiEdges = { { id = "catalogue" } }, { { id = "taxi" } }
local result = { segments = {}, totalSeconds = 100 }
for index = 1, 30 do result.segments[index] = { id = index } end
local request = {
    clock = clock, contextKey = "new-objective", canWalk = function() return true end,
    adapter = { CreatePreparation = function() return Work("prepare") end },
    data = { CreateEdgeBuild = function() return Work("catalogue", catalogueEdges, { resources = {} }) end },
    taxiData = {
        SetProbeContext = function(self, contextKey) self.probeContext = contextKey end,
        CreateEdgeBuild = function(self)
            assert(self.probeContext == "new-objective", "A new objective clears old taxi refusals before graph filtering")
            return Work("taxi", taxiEdges, { waitingData = true })
        end,
        CreateProbeSearch = function() return Work("probe") end,
    },
    engine = { CreateSearch = function(_, options)
        assert(options.edgeGroups[1] == catalogueEdges and options.edgeGroups[2] == taxiEdges,
            "The planner passes graph groups without flattening or copying the taxi network")
        return Work("search", result)
    end },
    prepareSegment = function(segment)
        now = now + 0.25
        return { id = segment.id }
    end,
}
local job = APR.NavigationPlanner:Create(request)
assert(next(created) == nil and now == 0, "Creating a plan does not build any provider graph")
local iterations = 0
while job.status == "planning" do
    local started = now
    job:Step(64, 1)
    assert(now - started <= 1.000001, "Preparation, search and publication share the slice allowance")
    iterations = iterations + 1
    assert(iterations < 200)
end
assert(job.status == "ready" and #job:GetResult().queue == 30 and job.waitingData,
    "The resumable pipeline publishes all rows and preserves provider coverage")
assert(created.prepare == 1 and created.catalogue == 1 and created.taxi == 1
    and created.search == 1 and created.probe == 1, "Resuming a phase never recreates its job")
assert(job.totalSliceMilliseconds == 32.5 and job.elapsedMilliseconds == 32.5,
    "The report distinguishes total computation from elapsed scheduling time")
local completedAt = now
assert(job:Step(64, 1) == "ready" and now == completedAt, "Completed planning performs no more clock or API work")

local delayed = APR.NavigationPlanner:Create(request)
repeat
    delayed:Step(64, 1)
    if delayed.status == "planning" then now = now + 10 end
until delayed.status ~= "planning"
assert(delayed.status == "ready" and delayed.totalSliceMilliseconds == 32.5
    and delayed.elapsedMilliseconds > 42.5,
    "Time waiting between frames is not charged as CPU computation")

job = APR.NavigationPlanner:Create(request)
job:Step(1, 1)
local active = job.active
job:Cancel()
assert(active.cancelled and job:Step(64, 1) == "cancelled", "Cancelling propagates to unfinished preparation")

request.adapter.CreatePreparation = function()
    return { Step = function() return "cancelled" end }
end
job = APR.NavigationPlanner:Create(request)
assert(job:Step(64, 1) == "cancelled", "An invalidated provider cannot publish a graph from stale inputs")

request.adapter = nil
request.engine.CreateSearch = function()
    return { Step = function() return "no_path" end, GetResult = function() end }
end
request.taxiData.CreateProbeSearch = function(_, _, _, baseline)
    assert(baseline == math.huge, "A graph failure leaves room for an unpriced flight-master offer")
    return { Step = function() return "ready", { id = "check-master" } end }
end
request.probeSegments = function(probe) return { probe } end
job = APR.NavigationPlanner:Create(request)
while job:Step(64, 1) == "planning" do end
assert(job.status == "ready" and job:GetResult().queue[1].id == "check-master",
    "Missing taxi data can lead to bounded exploration even when the known graph has no route")
request.taxiData.CreateProbeSearch = function() return { Step = function() return "ready" end } end
job = APR.NavigationPlanner:Create(request)
while job:Step(64, 1) == "planning" do end
assert(job.status == "no_path", "A graph failure remains a failure when exploration finds no candidate")

-- A valid nearby route needs no flight-master exploration when boarding alone
-- takes longer. A failed search still allows a provider to offer its fallback.
local probes, baseline = 0, nil
request.engine.CreateSearch = function()
    return { Step = function() return "ready", { segments = {}, totalSeconds = 3 } end }
end
request.taxiData.CanProbeBeat = function(_, seconds)
    baseline = seconds
    return seconds > 15
end
request.taxiData.CreateProbeSearch = function()
    probes = probes + 1
    return { Step = function() return "ready" end }
end
job = APR.NavigationPlanner:Create(request)
while job:Step(64, 1) == "planning" do end
assert(job.status == "ready" and baseline == 3 and probes == 0,
    "A provider lower bound skips a provably useless probe without scanning its network")
request.engine.CreateSearch = function()
    return { Step = function() return "no_path" end, GetResult = function() end }
end
job = APR.NavigationPlanner:Create(request)
while job:Step(64, 1) == "planning" do end
assert(job.status == "no_path" and baseline == math.huge and probes == 1,
    "The same lower bound preserves exploration when the known graph has no path")
print("Navigation planner: shared 1 ms allowance, incremental providers/publication, zero graph copies and cancellation passed")

local locked = { id = "locked", blockedRequirements = { quest = 84957 } }
local diagnostics = { segments = {}, totalSeconds = 50 }
for index = 1, 40 do diagnostics.segments[index] = locked end
request.taxiData.CanProbeBeat = function() return false end
request.data.CreateEdgeBuild = function()
    return Work("catalogue", {}, { resources = {}, blockedEdges = { locked } })
end
request.engine.CreateSearch = function(_, options)
    if options.edgeGroups[3] then return Work("explain", diagnostics) end
    return { Step = function() return "no_path" end, GetResult = function() end }
end
request.prepareSegment = function() error("Diagnostic routes cannot publish guidance rows") end
job = APR.NavigationPlanner:Create(request)
while job:Step(2, 1) == "planning" do
    if job.phase == "explain_collect" then
        assert(not job.blockers or #job.blockers <= 40)
        local before = #job.blockers
        job:Step(2, 1)
        assert(#job.blockers - before <= 2, "Failure explanation also obeys the shared operation budget")
    end
end
assert(job.status == "no_path" and #job.blockers == 40)
job = APR.NavigationPlanner:Create(request)
while job.phase ~= "explain_collect" do job:Step(2, 1) end
job:Cancel()
assert(job.status == "cancelled" and not job.blockers and not job.diagnosticSegments,
    "Cancelled diagnostics release their partial result and cannot report obsolete gates")
