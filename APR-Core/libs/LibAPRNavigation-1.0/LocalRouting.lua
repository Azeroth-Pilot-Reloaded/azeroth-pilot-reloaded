-- Local planning uses the same explicit-edge search as world travel.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("local-routing", 2) then return end
local Instance, Route = Lib.Instance, {}
Route.__index = Route

local function SamePoint(a, b)
    return a and b and a.x == b.x and a.y == b.y and a.z == b.z
        and a.instanceID == b.instanceID and a.floor == b.floor and a.accessKey == b.accessKey
end
local function Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Route:Prepare()
    local state, edges, coverage = self.build:Step(1, self.milliseconds)
    if state == "planning" then return end
    self.coverage = coverage
    if state ~= "ready" then self.status, self.reason = state, self.build.reason; return end
    if coverage.waitingData then self.status = "waiting_data"; return end
    if not coverage.attached[self.request.start] or not coverage.attached[self.request.goal] then
        self.status = "missing_data"; return
    end
    self.search = self.owner:CreateSearch({ start = self.request.start, goal = self.request.goal,
        edges = edges, canWalk = function() return false end, walkingIsTransitive = false,
        walkSpeed = self.profile.groundSpeed, movementProfile = self.profile })
    self.phase = "search"
end

function Route:Search()
    local state, result = self.search:Step(1, self.milliseconds)
    if state == "planning" then return end
    if state ~= "ready" then self.status = state; return end
    self.result, self.phase = result, "polyline"
    self.segmentIndex, self.pointIndex = 1, 1
    result.polyline, result.coverage = {}, self.coverage
end

function Route:Polyline()
    local segment = self.result.segments[self.segmentIndex]
    if not segment then self.status = "ready"; return end
    local points = segment.polyline or { segment.from, segment.to }
    local point = points[self.pointIndex]
    if not point then self.segmentIndex, self.pointIndex = self.segmentIndex + 1, 1; return end
    self.pointIndex = self.pointIndex + 1
    local output = self.result.polyline
    if not SamePoint(output[#output], point) then output[#output + 1] = point end
end

function Route:Step(operations, milliseconds)
    if self.status ~= "planning" then return self.status, self.result, self.coverage end
    if self.coverage and self.coverage.revision ~= (Lib.terrainRevision or 0) then
        if self.search then self.search:Cancel() end
        self.build, self.search, self.coverage, self.result = self.owner:CreateTerrainEdgeBuild(self.request), nil, nil, nil
        self.phase = "prepare"
    end
    operations = Finite(operations) and math.max(0, math.floor(operations)) or 64
    self.milliseconds = Finite(milliseconds) and math.max(0, milliseconds) or 1
    self.workLastStep = 0
    if operations == 0 or self.milliseconds == 0 then return self.status end
    local deadline = self.request.clock and self.request.clock() + self.milliseconds
    for _ = 1, operations do
        if deadline and self.workLastStep > 0 and self.request.clock() >= deadline then break end
        self.workLastStep = self.workLastStep + 1
        if self.phase == "prepare" then self:Prepare()
        elseif self.phase == "search" then self:Search()
        else self:Polyline() end
        if self.status ~= "planning" then break end
    end
    return self.status, self.result, self.coverage
end

function Route:Cancel()
    self.status, self.result = "cancelled", nil
    if self.build then self.build:Cancel() end
    if self.search then self.search:Cancel() end
end

function Instance:CreateLocalRoute(request)
    request = type(request) == "table" and request or {}
    return setmetatable({ owner = self, request = request, status = "planning", phase = "prepare",
        profile = Lib.Terrain.Profile(request), build = self:CreateTerrainEdgeBuild(request) }, Route)
end

local Assembly = {}
Assembly.__index = Assembly
local function SameChannel(a, b)
    return SamePoint(a, b) and a.region == b.region
end
local function IsTerrainWalk(segment)
    return segment.terrain == true and segment.kind == "walk" and not segment.mandatory
        and not segment.action and not segment.spellID and not segment.itemID
        and (not segment.actions or #segment.actions == 0)
end
local function CopyRecord(source)
    local result = {}
    for key, value in pairs(source) do result[key] = value end
    return result
end

function Assembly:BeginOne()
    local source = (self.source.segments or {})[self.index]
    if not source then self.status = "ready"; return end
    self.index = self.index + 1
    if IsTerrainWalk(source) and (source.seconds or 0) == 0 and SamePoint(source.from, source.to) then return end
    local result = self.result.segments
    local previous = result[#result]
    local merge = previous and IsTerrainWalk(previous) and IsTerrainWalk(source)
        and previous.movementMode == source.movementMode and SameChannel(previous.to, source.from)
    if merge then
        previous.to, previous.seconds = source.to, (previous.seconds or 0) + (source.seconds or 0)
    else
        previous = CopyRecord(source)
        previous.polyline, previous.polylineSeconds, previous.polylineDelays = {}, {}, {}
        previous.polylineWeights, previous.polylineWeightTotal = nil, nil
        result[#result + 1] = previous
    end
    self.pending = { output = previous, segment = source, source = source.polyline or { source.from, source.to }, index = 1,
        offset = previous.polylineSeconds[#previous.polylineSeconds] or 0, weights = source.polylineWeights,
        totalWeight = source.polylineWeightTotal, weightIndex = 2 }
    if not self.pending.weights then self.pending.weights = { 0 }; self.pending.prepareWeights = true end
end

function Assembly:WeightOne()
    local pending = self.pending
    local point = pending.source[pending.weightIndex]
    if not point then
        pending.prepareWeights = false
        pending.totalWeight = pending.weights[#pending.weights]
        return
    end
    local previous = pending.source[pending.weightIndex - 1]
    pending.weights[pending.weightIndex] = pending.weights[pending.weightIndex - 1]
        + Lib.Terrain.Seconds({ mode = pending.segment.movementMode or "ground" }, previous, point, self.profile)
    pending.weightIndex = pending.weightIndex + 1
end

local function PointSeconds(pending)
    if pending.index <= 1 then return pending.offset end
    local delay = pending.segment.transitionSeconds or 0
    local seconds = math.max(0, (pending.segment.seconds or 0) - delay)
    local weight = pending.weights[pending.index] or 0
    return pending.offset + delay + (pending.totalWeight and pending.totalWeight > 0 and seconds * weight / pending.totalWeight or 0)
end

function Assembly:PointOne()
    local pending = self.pending
    local point = pending.source[pending.index]
    if not point then self.pending = nil; return end
    local output = pending.output.polyline
    if not SamePoint(output[#output], point) then
        output[#output + 1] = point
        pending.output.polylineSeconds[#output] = PointSeconds(pending)
    end
    if pending.index == 1 then
        local delays = pending.output.polylineDelays
        delays[#output] = (delays[#output] or 0) + (pending.segment.transitionSeconds or 0)
    end
    pending.index = pending.index + 1
end

function Assembly:Step(operations, milliseconds)
    if self.status ~= "planning" then return self.status, self.result end
    operations = Finite(operations) and math.max(0, math.floor(operations)) or 64
    milliseconds = Finite(milliseconds) and math.max(0, milliseconds) or 1
    self.workLastStep = 0
    if operations == 0 or milliseconds == 0 then return self.status end
    local deadline = self.clock and self.clock() + milliseconds
    for _ = 1, operations do
        if deadline and self.workLastStep > 0 and self.clock() >= deadline then break end
        self.workLastStep = self.workLastStep + 1
        if self.pending and self.pending.prepareWeights then self:WeightOne()
        elseif self.pending then self:PointOne() else self:BeginOne() end
        if self.status ~= "planning" then break end
    end
    return self.status, self.result
end

function Assembly:Cancel()
    self.status, self.result, self.pending = "cancelled", nil, nil
end

function Instance:CreateTerrainRouteBuild(route, options)
    local result = CopyRecord(route or {})
    result.segments, result.polyline = {}, nil
    return setmetatable({ source = route or {}, result = result, status = "planning", index = 1,
        clock = options and options.clock, profile = Lib.Terrain.Profile(options or {}) }, Assembly)
end
