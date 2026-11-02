-- UnitPosition can report zero indoors. Ground geometry may supply an effective
-- height, while the original native observation remains available to diagnostics.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("terrain-height", 2) then return end
local Instance = Lib.Instance
local EPSILON = 0.05
local function Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function SameSpace(first, last)
    return first and last and first.instanceID == last.instanceID and first.accessKey == last.accessKey
        and (first.floor == nil or last.floor == nil or first.floor == last.floor)
        and (first.region == nil or last.region == nil or first.region == last.region)
        and (type(first.indoors) ~= "boolean" or type(last.indoors) ~= "boolean" or first.indoors == last.indoors)
end
local function Horizontal(first, last)
    return math.sqrt((first.x-last.x)^2 + (first.y-last.y)^2)
end
local function CopyPoint(point)
    local copy = {}
    for key, value in pairs(point) do copy[key] = value end
    return copy
end
local function InXY(point, anchor)
    return anchor.mode == "ground" and Finite(anchor.minZ) and Finite(anchor.maxZ)
        and (type(point.indoors) ~= "boolean" or type(anchor.indoor) ~= "boolean" or point.indoors == anchor.indoor)
        and SameSpace(point, anchor.entry or anchor.node)
        and point.x >= anchor.minX and point.x <= anchor.maxX
        and point.y >= anchor.minY and point.y <= anchor.maxY
end
local function HasHeight(anchor, height)
    return (anchor.minZ == nil or height >= anchor.minZ-EPSILON)
        and (anchor.maxZ == nil or height <= anchor.maxZ+EPSILON)
end
local function Projection(point, first, last)
    if not SameSpace(point, first) or not SameSpace(first, last) or not Finite(first.z) or not Finite(last.z) then return nil end
    local dx, dy = last.x-first.x, last.y-first.y
    local length = dx*dx + dy*dy
    -- A vertical link cannot infer progress from unavailable native height.
    if length <= EPSILON*EPSILON then return nil end
    local raw = ((point.x-first.x)*dx + (point.y-first.y)*dy)/length
    local fraction = math.max(0, math.min(1, raw))
    local x, y = first.x+fraction*dx, first.y+fraction*dy
    return first.z+fraction*(last.z-first.z), math.sqrt((point.x-x)^2+(point.y-y)^2), raw
end

local function GuidedHeight(point, hint, anchors, revision)
    if type(hint) ~= "table" or hint.status == "cancelled" or hint.status == "arrived" then return nil end
    local segmentIndex, index = hint.segmentIndex or 1, hint.pointIndex or 1
    local prepared = hint.segments and hint.segments[segmentIndex]
    local source = prepared and prepared.source or hint.route and hint.route.segments and hint.route.segments[segmentIndex]
    if not source or source.terrain ~= true or (source.movementMode or "ground") ~= "ground" then return nil end
    local points = prepared and prepared.points or source.polyline or { source.from, source.to }
    local first, last = points[index], points[index+1]
    if not first or not last then return nil end
    local proof = hint._terrainGroundProof
    if proof and (proof.revision ~= revision or proof.source ~= source or index < proof.index) then return nil end
    local previous = proof and proof.position or first
    local options = hint.options or {}
    if not SameSpace(point, previous) or Horizontal(point, previous) > (options.maxGroundHeightDistance or 30) then return nil end
    local height, separation, raw = Projection(point, first, last)
    if not height then return nil end
    -- Only the next connected leg is eligible, after crossing this corner.
    -- A nearby parallel corridor cannot skip the intervening turn.
    if raw >= 1 and points[index+2] then
        local nextHeight, nextDistance, nextRaw = Projection(point, last, points[index+2])
        if nextHeight and nextRaw >= 0 and nextRaw <= 1 and nextDistance < separation then
            height, separation = nextHeight, nextDistance
        end
    end
    if separation > (options.groundHeightTolerance or 4)
        or math.abs(height-previous.z) > (options.maxGroundHeightChange or 15) then return nil end
    for _, anchor in ipairs(anchors) do
        if HasHeight(anchor, height) then
            return height, { source = source, index = index, revision = revision }
        end
    end
end

local function ConnectedHeight(owner, point, anchors, revision)
    local proof = owner._terrainGroundObservation
    local previous = proof and proof.revision == revision and proof.position
    if not SameSpace(point, previous) or Horizontal(point, previous) > 30 then return nil end
    local height, ambiguous
    for _, anchor in ipairs(anchors) do
        local z = (anchor.entry or anchor.node).z
        if Finite(z) and math.abs(z-previous.z) <= 15 then
            local candidate = { x = point.x, y = point.y, z = z, instanceID = point.instanceID,
                accessKey = point.accessKey, region = point.region, floor = point.floor }
            if owner:CanTraverseTerrain(previous, candidate, "ground") == true then
                if height and math.abs(height-z) > EPSILON then ambiguous = true else height = height or z end
            end
        end
    end
    return not ambiguous and height or nil
end

local function SameSurface(owner, first, last)
    local from, to = first.entry or first.node, last.entry or last.node
    if math.abs(from.z-to.z) <= EPSILON then return true end
    if not HasHeight(first, to.z) or not HasHeight(last, from.z) or Horizontal(from, to) <= EPSILON then return false end
    local face = ((math.abs(first.maxX-last.minX) <= EPSILON or math.abs(last.maxX-first.minX) <= EPSILON)
            and math.min(first.maxY,last.maxY)-math.max(first.minY,last.minY) > EPSILON)
        or ((math.abs(first.maxY-last.minY) <= EPSILON or math.abs(last.maxY-first.minY) <= EPSILON)
            and math.min(first.maxX,last.maxX)-math.max(first.minX,last.minX) > EPSILON)
    return face and owner:CanTraverseTerrain(from, to, "ground") == true
end

local function OneSurface(owner, anchors)
    local joined, count = { [1] = true }, 1
    while count < #anchors do
        local changed
        for index, anchor in ipairs(anchors) do
            if not joined[index] then
                for previous in pairs(joined) do
                    if SameSurface(owner, anchors[previous], anchor) then
                        joined[index], count, changed = true, count+1, true
                        break
                    end
                end
            end
        end
        if not changed then return false end
    end
    return true
end

function Instance:ResolveTerrainGroundPosition(point, hint)
    if type(point) ~= "table" or not Finite(point.x) or not Finite(point.y) or not Finite(point.instanceID) then
        return nil, "invalid_terrain_position"
    end
    if point.positionSource ~= "unit" then return point, "observed_height" end
    local observedHeight = Finite(point.z) and point.z ~= 0 and point.heightSource ~= "terrain"
    local cache = self._terrainVisibility
    if not cache or cache.revision ~= (Lib.terrainRevision or 0) then
        if observedHeight then return point, "observed_height" end
        return nil, "terrain_height_unavailable"
    end
    local world = self:GetWorldInstanceID(point.instanceID)
    local levels = cache.worlds[world]
    if not levels then
        if observedHeight then return point, "observed_height" end
        return nil, "terrain_height_unavailable"
    end
    local anchors, seen = {}, {}
    for size, buckets in pairs(levels) do
        local bucket = buckets[tostring(math.floor(point.x/size)) .. ":" .. tostring(math.floor(point.y/size))]
        for _, anchor in ipairs(bucket or {}) do
            if not seen[anchor] and InXY(point, anchor) then
                anchors[#anchors+1], seen[anchor] = anchor, true
            end
        end
    end
    if observedHeight then
        for _, anchor in ipairs(anchors) do
            if HasHeight(anchor, point.z) then
                self._terrainGroundObservation = { position = CopyPoint(point), revision = cache.revision }
                break
            end
        end
        return point, "observed_height"
    end
    if #anchors == 0 then return nil, "terrain_anchor_missing" end
    local height, ambiguous
    for _, anchor in ipairs(anchors) do
        local z = (anchor.entry or anchor.node).z
        if Finite(z) then
            if height and math.abs(height-z) > EPSILON then ambiguous = true else height = height or z end
        end
    end
    if ambiguous and OneSurface(self, anchors) then ambiguous = false end
    local proof
    if hint then
        local guided, evidence = GuidedHeight(point, hint, anchors, cache.revision)
        if guided then height, proof, ambiguous = guided, evidence, false
        elseif ambiguous then return nil, "ambiguous_terrain_surface"
        else
            -- Once continuity has been established, a jump cannot silently
            -- reset it merely because its new XY happens to have one layer.
            if hint._terrainGroundProof then return nil, "terrain_height_disconnected" end
        end
    end
    if ambiguous and not hint then
        local connected = ConnectedHeight(self, point, anchors, cache.revision)
        if connected then height, ambiguous = connected, false end
    end
    if ambiguous then return nil, "ambiguous_terrain_surface" end
    if not height then return nil, "terrain_height_unavailable" end
    local resolved = CopyPoint(point)
    resolved.z, resolved.heightSource = height, "terrain"
    if resolved.observedZ == nil then resolved.observedZ = point.z end
    if proof then proof.position, hint._terrainGroundProof = CopyPoint(resolved), proof end
    self._terrainGroundObservation = { position = CopyPoint(resolved), revision = cache.revision }
    return resolved, "terrain_ground_height"
end
