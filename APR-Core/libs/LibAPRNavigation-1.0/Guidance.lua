-- Follow proved path segments without changing the host's objective cursor.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("terrain-guidance", 2) then return end
local Guidance = {}
Guidance.__index = Guidance
local function Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function Distance(a, b, spatial)
    local dx, dy = b.x - a.x, b.y - a.y
    local dz = spatial and Finite(a.z) and Finite(b.z) and b.z - a.z or 0
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function SameSpace(a, b)
    return a and b and a.instanceID == b.instanceID and a.accessKey == b.accessKey
        and (a.floor == nil or b.floor == nil or a.floor == b.floor)
        and (a.region == nil or b.region == nil or a.region == b.region)
end
local function Project(point, from, to, spatial)
    local dx, dy = to.x - from.x, to.y - from.y
    local dz = spatial and (to.z - from.z) or 0
    local pz = spatial and (point.z - from.z) or 0
    local length2 = dx * dx + dy * dy + dz * dz
    local raw = length2 > 0 and ((point.x - from.x) * dx + (point.y - from.y) * dy + pz * dz) / length2 or 1
    local fraction = math.max(0, math.min(1, raw))
    local x, y, z = from.x + fraction * dx, from.y + fraction * dy, spatial and from.z + fraction * dz or nil
    local ex, ey, ez = point.x - x, point.y - y, spatial and point.z - z or 0
    return fraction, math.sqrt(ex * ex + ey * ey + ez * ez), raw
end

function Guidance:PrepareOne()
    local source = (self.route.segments or {})[self.prepareSegment]
    if not source then self.phase, self.suffixIndex, self.suffix = "suffix", #self.segments, 0; return end
    local segment = self.segments[self.prepareSegment]
    if not segment then
        segment = { source = source, points = source.polyline or { source.from, source.to },
            cumulative = { 0 }, timeWeights = source.polylineWeights or { 0 },
            length = 0, seconds = source.seconds or 0, mode = source.movementMode or "ground" }
        self.segments[self.prepareSegment] = segment
    end
    local point = segment.points[self.preparePoint]
    local previous = segment.points[self.preparePoint - 1]
    if not point then
        local weight = source.polylineWeightTotal or segment.timeWeights[#segment.timeWeights]
        local moving = math.max(0, segment.seconds - (source.transitionSeconds or 0))
        segment.timeScale = weight > 0 and moving / weight or 0
        self.prepareSegment, self.preparePoint = self.prepareSegment + 1, 2
        return
    end
    if not previous or not Finite(point.x) or not Finite(point.y) or not Finite(previous.x) or not Finite(previous.y) then
        self.status, self.reason = "invalid_data", "invalid_guidance_polyline"; return
    end
    segment.length = segment.length + Distance(previous, point, true)
    segment.cumulative[self.preparePoint] = segment.length
    if not source.polylineWeights and not source.polylineSeconds then
        local profile = Lib.Terrain and Lib.Terrain.Profile(self.options) or nil
        local weight = profile and Lib.Terrain.Seconds({ mode = segment.mode }, previous, point, profile) or Distance(previous, point, true)
        segment.timeWeights[self.preparePoint] = segment.timeWeights[self.preparePoint - 1] + weight
    end
    self.preparePoint = self.preparePoint + 1
end

function Guidance:SuffixOne()
    local segment = self.segments[self.suffixIndex]
    if not segment then
        self.phase, self.status, self.segmentIndex, self.pointIndex = "follow", "guiding", 1, 1
        self.remainingSeconds = self.suffix
        return
    end
    segment.afterSeconds = self.suffix
    self.suffix = self.suffix + segment.seconds
    self.suffixIndex = self.suffixIndex - 1
end

function Guidance:Step(operations, milliseconds)
    if self.status ~= "planning" then return self.status end
    operations = Finite(operations) and math.max(0, math.floor(operations)) or 64
    milliseconds = Finite(milliseconds) and math.max(0, milliseconds) or 1
    self.workLastStep = 0
    if operations == 0 or milliseconds == 0 then return self.status end
    local deadline = self.options.clock and self.options.clock() + milliseconds
    for _ = 1, operations do
        if deadline and self.workLastStep > 0 and self.options.clock() >= deadline then break end
        self.workLastStep = self.workLastStep + 1
        if self.phase == "prepare" then self:PrepareOne() else self:SuffixOne() end
        if self.status ~= "planning" then break end
    end
    return self.status
end

function Guidance:Arrived(position, destination, spatial)
    if not SameSpace(position, destination) then return false end
    if spatial and (not Finite(position.z) or not Finite(destination.z)) then return false end
    if Distance(position, destination, spatial) <= self.arrivalRange then return true end
    local previous = self.previous
    if not SameSpace(previous, position) or not SameSpace(previous, destination) then return false end
    if spatial and not Finite(previous.z) then return false end
    if Distance(previous, position, spatial) > (self.options.maxSweepDistance or 360) then return false end
    local _, distance = Project(destination, previous, position, spatial)
    return distance <= self.arrivalRange
end

function Guidance:Target(segment, from, to, fraction)
    local length = Distance(from, to, true)
    local lookahead = self.groundLookahead
    if segment.mode ~= "ground" then
        local profile = self.options.movementProfile or {}
        local speed = segment.mode == "steady" and (profile.steadySpeed or 30) or (profile.skyridingSpeed or 60)
        lookahead = math.max(60, math.min(180, speed * 2))
    end
    local nextFraction = length > 0 and math.min(1, fraction + lookahead / length) or 1
    return { instanceID = to.instanceID, uiMapID = to.uiMapID, floor = to.floor, accessKey = to.accessKey,
        region = to.region, x = from.x + (to.x - from.x) * nextFraction,
        y = from.y + (to.y - from.y) * nextFraction,
        z = Finite(from.z) and Finite(to.z) and from.z + (to.z - from.z) * nextFraction or nil,
        movementMode = segment.mode }
end

local function Elapsed(segment, index, fraction)
    local source, before, after, delay = segment.source
    if source.polylineSeconds then
        before, after = source.polylineSeconds[index], source.polylineSeconds[index + 1]
        delay = source.polylineDelays and source.polylineDelays[index] or 0
    else
        delay = index == 1 and (source.transitionSeconds or 0) or 0
        before = (segment.timeWeights[index] or 0) * segment.timeScale
            + (index > 1 and (source.transitionSeconds or 0) or 0)
        after = (segment.timeWeights[index + 1] or 0) * segment.timeScale + (source.transitionSeconds or 0)
    end
    local movement = math.max(0, (after or before) - before - delay)
    return before + (fraction > 0 and delay or 0) + movement * fraction
end

function Guidance:AdvanceCorner(position, segment, distance)
    local points, walked = segment.points, 0
    local last = math.min(#points - 1, self.pointIndex + (self.options.maxProjectionSegments or 16))
    local window = segment.mode == "ground" and 120 or 360
    for index = self.pointIndex + 1, last do
        local from, to = points[index], points[index + 1]
        local spatial = segment.mode ~= "ground" or (Finite(position.z) and Finite(from.z) and Finite(to.z))
        if spatial and (not Finite(position.z) or not Finite(from.z) or not Finite(to.z)) then return false end
        local fraction, separation, raw = Project(position, from, to, spatial)
        local length = Distance(from, to, true)
        if walked + length * fraction > window then return false end
        if raw >= 0 and raw <= 1 and separation < distance and SameSpace(position, from) then
            local proved = segment.source.terrain and separation <= 0.00001
            if not proved and self.options.canTraverse then
                proved = self.options.canTraverse(position, self:Target(segment, from, to, fraction), segment.mode) == true
            end
            if proved then self.pointIndex = index; return true end
        end
        walked = walked + length
    end
    return false
end

function Guidance:FollowOne(position)
    local segment = self.segments[self.segmentIndex]
    if not segment then self.status, self.remainingSeconds = "arrived", 0; return nil, true end
    local points = segment.points
    local from, to = points[self.pointIndex], points[self.pointIndex + 1]
    if not to then self.segmentIndex, self.pointIndex = self.segmentIndex + 1, 1; return nil, false end
    if segment.source.kind and segment.source.kind ~= "walk" then self.status = "action"; return nil, true end
    local spatial = segment.mode ~= "ground" or (Finite(from.z) and Finite(to.z))
    if spatial and (not Finite(position.z) or not Finite(from.z) or not Finite(to.z)) then
        self.status = "waiting_data"; return nil, true
    end
    local finalPoint = self.pointIndex + 1 == #points
    if finalPoint and self:Arrived(position, to, spatial) then self.pointIndex = self.pointIndex + 1; return nil, false end
    if not SameSpace(position, from) then self.status = "deviated"; return nil, true end
    local fraction, distance, raw = Project(position, from, to, spatial)
    self.pathProof = segment.source.terrain == true and distance <= 0.00001
    if distance > self.cornerTolerance and self:AdvanceCorner(position, segment, distance) then return nil, false end
    local deviation = segment.mode == "ground" and self.groundDeviation or self.airDeviation
    if distance > deviation then self.status = "deviated"; return nil, true end
    if not finalPoint and raw >= 1 and distance <= self.cornerTolerance then
        self.pointIndex = self.pointIndex + 1
        return nil, false
    end
    self.remainingSeconds = segment.afterSeconds + math.max(0, segment.seconds - Elapsed(segment, self.pointIndex, fraction))
    self.status = "guiding"
    return self:Target(segment, from, to, fraction), true
end

function Guidance:Update(position)
    if self.status == "cancelled" or self.status == "arrived" or self.status == "invalid_data" then return nil, self.status end
    if type(position) ~= "table" or not Finite(position.x) or not Finite(position.y) then
        self.status = "waiting_data"; return nil, self.status
    end
    if self.phase ~= "follow" then
        if self.status == "waiting_data" then self.status = "planning" end
        self:Step(self.options.maxOperations or 64, self.options.maxMilliseconds or 1)
        if self.status ~= "guiding" then return nil, self.status end
    end
    local target
    -- Bound recovery after a position jumps across many short shape segments.
    for _ = 1, self.options.maxProjectionSegments or 16 do
        local done
        target, done = self:FollowOne(position)
        if done then break end
    end
    self.previous = { x = position.x, y = position.y, z = position.z, instanceID = position.instanceID,
        floor = position.floor, accessKey = position.accessKey, region = position.region }
    if target and not self.pathProof and self.options.canTraverse then
        local allowed, prefix = self.options.canTraverse(position, target, target.movementMode)
        if allowed ~= true then
            if prefix and Distance(position, prefix, true) > self.cornerTolerance then target = prefix
            else target, self.status = nil, "deviated" end
        end
    end
    return target, self.status
end

function Guidance:Cancel()
    self.status, self.segments, self.previous = "cancelled", {}, nil
end

function Lib.Instance:CreateGuidance(route, options)
    options = type(options) == "table" and options or {}
    return setmetatable({ route = route or {}, options = options, segments = {}, phase = "prepare",
        status = "planning", prepareSegment = 1, preparePoint = 2,
        remainingSeconds = route and route.totalSeconds or 0,
        groundLookahead = options.groundLookahead or 30, groundDeviation = options.groundDeviation or 30,
        airDeviation = options.airDeviation or 60, arrivalRange = options.arrivalRange or 5,
        cornerTolerance = options.cornerTolerance or 0.5 }, Guidance)
end
