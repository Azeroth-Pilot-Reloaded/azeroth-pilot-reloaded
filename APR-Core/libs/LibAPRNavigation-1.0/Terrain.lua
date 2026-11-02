-- Declarative terrain is supplied by the consumer; this module never queries WoW.
-- Only a proved convex anchor may connect a live position to the terrain graph.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("terrain", 3) then return end
local Instance, Terrain = Lib.Instance, {}
Lib.Terrain = Terrain
local Build = {}
Build.__index = Build
local MODES = { ground = true, steady = true, skyriding = true }

local function Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function Nonnegative(value) return Finite(value) and value >= 0 end
local function Positive(value, fallback) return Finite(value) and value > 0 and value or fallback end
local function Identity(value)
    return (type(value) == "string" and value ~= "")
        or (Nonnegative(value) and value % 1 == 0)
end
local function Channel(value) return value == nil or type(value) == "string" or Finite(value) end
local function Fail(job, reason)
    job.status, job.reason = "invalid_data", reason
    job.coverage.missingData, job.coverage.covered = true, false
    job.coverage.reason = reason
end
local function Key(world, pack, id) return tostring(world) .. ":" .. tostring(pack) .. ":" .. tostring(id) end

local function Slab(first, last, lower, upper, lo, hi)
    if lower == nil and upper == nil then return lo, hi end
    if not Finite(first) or not Finite(last) then return nil end
    local delta = last - first
    if delta == 0 then
        if (lower and first < lower) or (upper and first > upper) then return nil end
        return lo, hi
    end
    local near, far
    if delta > 0 then
        near, far = lower and (lower - first) / delta or -math.huge, upper and (upper - first) / delta or math.huge
    else
        near, far = upper and (upper - first) / delta or -math.huge, lower and (lower - first) / delta or math.huge
    end
    lo, hi = math.max(lo, near), math.min(hi, far)
    if lo > hi then return nil end
    return lo, hi
end

function Terrain.ScopeValid(scope)
    if type(scope) ~= "table" or type(scope.id) ~= "string" or scope.id == "" or not Channel(scope.accessKey) then return false end
    local bounds = scope.bounds
    if type(bounds) ~= "table" then return false end
    for _, axis in ipairs({ "X", "Y", "Z" }) do
        local low, high = bounds["min" .. axis], bounds["max" .. axis]
        if not Finite(low) or not Finite(high) or low >= high then return false end
    end
    return scope.groundOnly == nil or type(scope.groundOnly) == "boolean"
end

local function UnknownNativeHeight(point)
    return point.positionSource == "unit" and point.heightSource ~= "terrain" and point.z == 0
end

function Terrain.ScopeContains(scope, point)
    if not Terrain.ScopeValid(scope) or type(point) ~= "table" or not Finite(point.x) or not Finite(point.y) then return false end
    if point.terrainBoundary == scope.id then return false end
    if scope.accessKey ~= nil and scope.accessKey ~= point.accessKey
        and (point.accessKey ~= nil or UnknownNativeHeight(point)) then return false end
    local b = scope.bounds
    if point.x < b.minX or point.x > b.maxX or point.y < b.minY or point.y > b.maxY then return false end
    return UnknownNativeHeight(point) or not Finite(point.z) or (point.z >= b.minZ and point.z <= b.maxZ)
end

local function ScopeBlocks(scope, from, to)
    if not Terrain.ScopeValid(scope) then return true end
    if scope.accessKey ~= nil and from.accessKey ~= nil and to.accessKey ~= nil
        and scope.accessKey ~= from.accessKey and scope.accessKey ~= to.accessKey then return false end
    if scope.accessKey ~= nil and from.accessKey == nil and to.accessKey == nil
        and (UnknownNativeHeight(from) or UnknownNativeHeight(to)) then return false end
    local b, inset = scope.bounds, 0.005
    -- Boundary points belong to the exterior walking graph. Tangency does not
    -- authorize a chord through the open interior of this volume.
    local lo, hi = Slab(from.x, to.x, b.minX + inset, b.maxX - inset, 0, 1)
    if not lo then return false end
    lo, hi = Slab(from.y, to.y, b.minY + inset, b.maxY - inset, lo, hi)
    if not lo then return false end
    if Finite(from.z) and Finite(to.z) and not UnknownNativeHeight(from) and not UnknownNativeHeight(to) then
        lo, hi = Slab(from.z, to.z, b.minZ, b.maxZ, lo, hi)
    end
    return lo ~= nil and hi - lo > 0.0000001
end

function Instance:GetTerrainScopes(world)
    if self.env.getTerrainScopes then
        local scopes, unbounded = self.env.getTerrainScopes(self.profile, world)
        if type(scopes) == "table" then return scopes, unbounded == true end
    end
    local profile = Lib.terrainDatasets and Lib.terrainDatasets[self.profile]
    local record = profile and profile[world]
    local scopes, seen = {}, {}
    for _, pack in pairs(record and record.packs or {}) do
        local scope = pack.data.scope
        if scope == nil then return {}, true end
        if not seen[scope.id] then scopes[#scopes + 1], seen[scope.id] = scope, true end
    end
    if #scopes == 0 and self.env.hasTerrainData and self.env.hasTerrainData(self.profile, world) == true then return {}, true end
    return scopes, false
end

local function ContainsAny(scopes, point)
    for _, scope in ipairs(scopes) do if Terrain.ScopeContains(scope, point) then return true end end
    return false
end

function Instance:RequiresTerrainRoute(from, to)
    if type(from) ~= "table" or type(to) ~= "table" then return false end
    local first, last = self:GetWorldInstanceID(from.instanceID), self:GetWorldInstanceID(to.instanceID)
    if self:HasTerrainData(from) or self:HasTerrainData(to) then return true end
    if first ~= last then return false end
    local scopes = self:GetTerrainScopes(first)
    for _, scope in ipairs(scopes) do if ScopeBlocks(scope, from, to) then return true end end
    return false
end

function Lib.ValidateTerrainData(data, worldID)
    assert(type(data) == "table" and data.format == 1, "unsupported terrain format")
    assert(Nonnegative(worldID), "terrain world required")
    assert(data.worldID == nil or data.worldID == worldID, "terrain world mismatch")
    assert(type(data.nodes) == "table" and type(data.edges) == "table", "terrain graph required")
    assert(data.anchors == nil or type(data.anchors) == "table", "terrain anchors must be an array")
    assert(data.scope == nil or Terrain.ScopeValid(data.scope), "invalid terrain scope")
    -- Each record is checked while the build is stepped, rather than doing an
    -- unbounded validation pass when a load-on-demand pack is registered.
end

function Terrain.Profile(request)
    local source = request.movementProfile or {}
    return {
        groundSpeed = Positive(source.groundSpeed, Positive(request.walkSpeed, 7)),
        steadySpeed = Positive(source.steadySpeed, 30),
        skyridingSpeed = Positive(source.skyridingSpeed, 60),
        climbSpeed = Positive(source.climbSpeed, 15), descentSpeed = Positive(source.descentSpeed, 45),
        canGround = source.canGround ~= false,
        canSteady = source.canSteady == true, canSkyriding = source.canSkyriding == true,
        currentMode = MODES[source.currentMode] and source.currentMode or "ground",
        canFlyAt = source.canFlyAt,
    }
end

function Terrain.Enabled(profile, mode)
    if mode == "ground" then return profile.canGround end
    if mode == "steady" then return profile.canSteady end
    return mode == "skyriding" and profile.canSkyriding
end

function Terrain.Seconds(edge, from, to, profile)
    if edge.seconds ~= nil then return edge.seconds end
    local dx, dy = to.x - from.x, to.y - from.y
    local dz = Finite(from.z) and Finite(to.z) and to.z - from.z or 0
    local horizontal = edge.horizontal or math.sqrt(dx * dx + dy * dy)
    local seconds
    if edge.mode == "ground" then
        seconds = (edge.length or math.sqrt(horizontal * horizontal + dz * dz)) / profile.groundSpeed
    else
        local speed = edge.mode == "steady" and profile.steadySpeed or profile.skyridingSpeed
        seconds = horizontal / speed + (edge.rise or math.max(0, dz)) / profile.climbSpeed
            + (edge.fall or math.max(0, -dz)) / profile.descentSpeed
    end
    return seconds + (edge.transitionSeconds or 0)
end

function Instance:HasTerrainData(point)
    local profile = Lib.terrainDatasets and Lib.terrainDatasets[self.profile]
    if not point then
        if profile and next(profile) then return true end
        return self.env.hasTerrainData and self.env.hasTerrainData(self.profile) == true or false
    end
    local world = self:GetWorldInstanceID(point.instanceID)
    if profile and profile[world] and next(profile[world].packs or {}) then
        if point.x == nil and point.y == nil then return true end
        local scopes, unbounded = self:GetTerrainScopes(world)
        return unbounded or ContainsAny(scopes, point)
    end
    return self.env.hasTerrainData and self.env.hasTerrainData(self.profile, world, point) == true or false
end

local function NodePosition(raw, world, pack, scope)
    if type(raw) ~= "table" or not Identity(raw.id) or not Finite(raw.x) or not Finite(raw.y)
        or not Finite(raw.z) or not Channel(raw.floor) or not Channel(raw.accessKey)
        or (raw.region ~= nil and type(raw.region) ~= "string")
        or (raw.indoor ~= nil and type(raw.indoor) ~= "boolean") then return nil end
    if raw.instanceID ~= nil and raw.instanceID ~= world then return nil end
    if raw.movementMode ~= nil and not MODES[raw.movementMode] then return nil end
    local boundary = raw.terrainBoundary
    if boundary ~= nil then
        if not scope or boundary ~= scope.id or (raw.movementMode and raw.movementMode ~= "ground") then return nil end
        local b, tolerance = scope.bounds, 0.01
        if raw.x < b.minX-tolerance or raw.x > b.maxX+tolerance or raw.y < b.minY-tolerance or raw.y > b.maxY+tolerance
            or raw.z < b.minZ-tolerance or raw.z > b.maxZ+tolerance then return nil end
        if math.min(math.abs(raw.x-b.minX),math.abs(raw.x-b.maxX),math.abs(raw.y-b.minY),math.abs(raw.y-b.maxY)) > tolerance then return nil end
    end
    return { x = raw.x, y = raw.y, z = raw.z, instanceID = world, uiMapID = raw.uiMapID,
        floor = raw.floor, accessKey = raw.accessKey, region = raw.region, indoor = raw.indoor,
        groundOnly = raw.groundOnly or (scope and scope.groundOnly), movementMode = raw.movementMode or "ground",
        noFly = raw.noFly or (scope and scope.groundOnly),
        terrainNodeKey = Key(world, pack, raw.id), terrainBoundary = boundary, noAutoconnect = boundary == nil }
end

function Build:AddPoint(point)
    if type(point) ~= "table" or self.pointSeen[point] then return end
    if not Finite(point.instanceID) or not Finite(point.x) or not Finite(point.y) then return end
    self.pointSeen[point] = true
    self.points[#self.points + 1] = point
end

function Build:CollectOne()
    local group = self.groups[self.group]
    if not group then self.phase, self.index = "load", 1; return end
    local edge = group[self.index]
    if not edge then self.group, self.index = self.group + 1, 1; return end
    self.index = self.index + 1
    self:AddPoint(edge.from); self:AddPoint(edge.to)
end

function Build:LoadOne()
    local point = self.points[self.index]
    if not point then self.phase, self.worldCursor = "cache", nil; return end
    self.index = self.index + 1
    local world = self.owner:GetWorldInstanceID(point.instanceID)
    if self.request.terrainWorlds and not self.request.terrainWorlds[world] then return end
    local scopes, unbounded = self.owner:GetTerrainScopes(world)
    if not unbounded and #scopes == 0 and not self.owner:HasTerrainData(point) then return end
    self.scopes[world], self.unbounded[world] = scopes, unbounded
    self.managed[world] = true
    if not unbounded and self.loadedWorlds[world] then return end
    self.loadedWorlds[world] = true
    if self.owner.env.requestTerrainData then
        local requestedPoint = unbounded and point or nil
        local state, reason = self.owner.env.requestTerrainData(self.owner.profile, world, requestedPoint)
        local waiting = state == "planning" or state == "waiting_data"
        if state == "missing" and reason == "terrain_point_unavailable" then
            self.unavailablePoints[point] = reason
        elseif waiting or state == "missing" then
            self.unavailableWorlds[world] = { reason = reason or "pack_unavailable", waiting = waiting }
            if not unbounded then self:Missing(point, reason or "pack_unavailable", waiting) end
            -- A registration alone does not authorize a pack rejected by the
            -- consumer's current build/revision checks, including warm caches.
            self.owner._terrainVisibility, self.owner._terrainGeometryCache = nil, nil
        end
    end
end

function Build:CacheOne()
    local cache = self.owner._terrainGeometryCache
    if next(self.unavailableWorlds) or not cache or cache.revision ~= (Lib.terrainRevision or 0) or cache.profile ~= self.owner.profile then
        self.phase, self.worldCursor = "packs", nil; return
    end
    local world = next(self.managed, self.worldCursor)
    if world ~= nil then
        self.worldCursor = world
        if not cache.worlds[world] then self.phase, self.worldCursor = "packs", nil end
        return
    end
    self.nodes, self.aliases, self.anchors = cache.nodes, cache.aliases, cache.anchors
    self.visibility, self.packs, self.pathPositionCache = cache.visibility, cache.packs, cache.pathPositions
    self.sourceRevision, self.geometryCached = cache.revision, true
    self.owner._terrainVisibility = { revision = cache.revision, worlds = cache.visibility }
    self.phase, self.packIndex, self.index = "edges", 1, 1
end

function Build:PackOne()
    self.sourceRevision = self.sourceRevision or Lib.terrainRevision or 0
    if self.packWorld then
        local packID, entry = next(self.packWorld.packs or {}, self.packCursor)
        if packID ~= nil then
            self.packCursor = packID
            self.packs[#self.packs + 1] = { id = packID, world = self.worldCursor, data = entry.data }
            return
        end
        self.packWorld, self.packCursor = nil, nil
    end
    local world = next(self.managed, self.worldCursor)
    if world == nil then self.phase, self.packIndex, self.index = "nodes", 1, 1; return end
    self.worldCursor = world
    local datasets = Lib.terrainDatasets and Lib.terrainDatasets[self.owner.profile]
    if not self.unavailableWorlds[world] then
        self.geometryWorlds[world] = true
        self.packWorld = datasets and datasets[world] or { packs = {} }
    else self.packWorld = { packs = {} } end
end

function Build:NextPack(phase)
    self.packIndex, self.index = self.packIndex + 1, 1
    if not self.packs[self.packIndex] then
        self.phase, self.packIndex = self.geometryCached and phase == "anchors" and "attach" or phase, 1
    end
end

function Build:NodeOne()
    local pack = self.packs[self.packIndex]
    if not pack then self.phase, self.packIndex, self.index = "edges", 1, 1; return end
    local raw = pack.data.nodes[self.index]
    if not raw then self:NextPack("edges"); return end
    self.index = self.index + 1
    local point = NodePosition(raw, pack.world, pack.id, pack.data.scope)
    if not point or self.nodes[point.terrainNodeKey] then Fail(self, "invalid_terrain_node"); return end
    if not point.region then point.region = self.owner:GetPositionRegion(point) end
    self.nodes[point.terrainNodeKey] = point
    local alias = Key(pack.world, "", raw.id)
    if self.aliases[alias] == nil then self.aliases[alias] = point else self.aliases[alias] = false end
    local anchors = self.anchors[pack.world] or {}
    self.anchors[pack.world] = anchors
    anchors[#anchors + 1] = { node = point, entry = point, path = { point }, reversePath = { point }, mode = point.movementMode,
        minX = point.x, maxX = point.x, minY = point.y, maxY = point.y, minZ = point.z, maxZ = point.z, indoor = point.indoor }
end

function Build:Resolve(reference, pack)
    if type(reference) == "table" then
        return self.nodes[Key(pack.world, reference.pack or pack.id, reference.node)]
    end
    return self.nodes[Key(pack.world, pack.id, reference)] or self.aliases[Key(pack.world, "", reference)]
end

local function ValidMetrics(edge)
    for _, key in ipairs({ "seconds", "length", "horizontal", "rise", "fall", "transitionSeconds" }) do
        if edge[key] ~= nil and not Nonnegative(edge[key]) then return false end
    end
    return true
end
local function EdgeRecord(from, to, mode, seconds, id, mandatory)
    return { from = from, to = to, kind = "walk", movementMode = mode, seconds = seconds,
        copper = 0, terrain = true, id = id, mandatory = mandatory == true }
end

local function FlightAllowed(profile, point, mode)
    if mode == "ground" then return true end
    if point.groundOnly or point.noFly then return false end
    return not profile.canFlyAt or profile.canFlyAt(point, mode) == true
end

function Build:EdgeOne()
    local pack = self.packs[self.packIndex]
    if not pack then self.phase, self.packIndex, self.index = self.geometryCached and "attach" or "anchors", 1, 1; return end
    local raw = pack.data.edges[self.index]
    if not raw then self:NextPack("anchors"); return end
    local id = self.index
    self.index = self.index + 1
    if type(raw) ~= "table" or not MODES[raw.mode] or not ValidMetrics(raw) then
        Fail(self, "invalid_terrain_edge"); return
    end
    local from, to = self:Resolve(raw.from, pack), self:Resolve(raw.to, pack)
    if not from or not to then Fail(self, "unknown_terrain_node"); return end
    if not Terrain.Enabled(self.profile, raw.mode) then return end
    if not FlightAllowed(self.profile, from, raw.mode) or not FlightAllowed(self.profile, to, raw.mode) then return end
    local seconds = Terrain.Seconds(raw, from, to, self.profile)
    if not Nonnegative(seconds) then Fail(self, "invalid_terrain_cost"); return end
    local edge = EdgeRecord(from, to, raw.mode, seconds,
        "terrain:" .. Key(pack.world, pack.id, id), raw.mandatory)
    edge.transitionSeconds, edge.polylineWeights = raw.transitionSeconds or 0, { 0 }
    if raw.polyline ~= nil and type(raw.polyline) ~= "table" then Fail(self, "invalid_terrain_polyline"); return end
    edge.polyline = { from }
    self.pendingEdge = { edge = edge, source = raw.polyline or {}, index = 1, pack = pack }
    self.phase = "polyline"
end

function Build:PolylineOne()
    local pending = self.pendingEdge
    local raw = pending.source[pending.index]
    if raw then
        pending.index = pending.index + 1
        if type(raw) ~= "table" or not Finite(raw.x) or not Finite(raw.y) or not Finite(raw.z) then
            Fail(self, "invalid_terrain_polyline"); return
        end
        local previous = pending.edge.polyline[#pending.edge.polyline]
        local point = self:PathPosition(raw, previous)
        if not FlightAllowed(self.profile, point, pending.edge.movementMode) then pending.rejected = true end
        if raw.x ~= previous.x or raw.y ~= previous.y or raw.z ~= previous.z then
            pending.edge.polyline[#pending.edge.polyline + 1] = point
            local weights = pending.edge.polylineWeights
            weights[#weights + 1] = weights[#weights] + Terrain.Seconds({ mode = pending.edge.movementMode }, previous, point, self.profile)
        end
        return
    end
    local edge = pending.edge
    local last = edge.polyline[#edge.polyline]
    if last.x ~= edge.to.x or last.y ~= edge.to.y or last.z ~= edge.to.z then
        edge.polyline[#edge.polyline + 1] = edge.to
        local weights = edge.polylineWeights
        weights[#weights + 1] = weights[#weights] + Terrain.Seconds({ mode = edge.movementMode }, last, edge.to, self.profile)
    end
    edge.polylineWeightTotal = edge.polylineWeights[#edge.polylineWeights]
    if not pending.rejected then self.result[#self.result + 1] = edge end
    self.pendingEdge, self.phase = nil, "edges"
end

local function EqualPosition(a, b)
    return a and b and a.x == b.x and a.y == b.y and a.z == b.z
end

local function InAnchorBounds(point, anchor)
    return point.x >= anchor.minX and point.x <= anchor.maxX and point.y >= anchor.minY and point.y <= anchor.maxY
        and (anchor.minZ == nil or point.z >= anchor.minZ) and (anchor.maxZ == nil or point.z <= anchor.maxZ)
end

local function AnchorRecord(raw, point)
    if not Finite(raw.minX) or not Finite(raw.maxX) or raw.minX > raw.maxX
        or not Finite(raw.minY) or not Finite(raw.maxY) or raw.minY > raw.maxY then return nil end
    if (raw.minZ ~= nil and not Finite(raw.minZ)) or (raw.maxZ ~= nil and not Finite(raw.maxZ)) then return nil end
    if raw.minZ and raw.maxZ and raw.minZ > raw.maxZ then return nil end
    if raw.indoor ~= nil and type(raw.indoor) ~= "boolean" then return nil end
    local mode = raw.mode or point.movementMode
    if not MODES[mode] then return nil end
    if mode ~= "ground" and (raw.minZ == nil or raw.maxZ == nil) then return nil end
    if raw.path ~= nil and type(raw.path) ~= "table" then return nil end
    if raw.reversePath ~= nil and type(raw.reversePath) ~= "table" then return nil end
    if raw.reversePath and not raw.path then return nil end
    if not raw.path and not InAnchorBounds(point, raw) then return nil end
    return { node = point, minX = raw.minX, maxX = raw.maxX, minY = raw.minY, maxY = raw.maxY,
        minZ = raw.minZ, maxZ = raw.maxZ, mode = mode, indoor = raw.indoor }
end

function Build:AnchorOne()
    local pack = self.packs[self.packIndex]
    if not pack then self.phase, self.index, self.anchorIndex = "visibility", 1, 1; return end
    local raw = (pack.data.anchors or {})[self.index]
    if not raw then self:NextPack("visibility"); self.anchorIndex = 1; return end
    self.index = self.index + 1
    if type(raw) ~= "table" then Fail(self, "invalid_terrain_anchor"); return end
    local node = self:Resolve(raw.node, pack)
    local anchor = node and AnchorRecord(raw, node)
    if not anchor then Fail(self, "invalid_terrain_anchor"); return end
    if raw.path then
        local entry = self:PathPosition(raw.path[1], node)
        local last = raw.path[#raw.path]
        if not entry or type(last) ~= "table" or not EqualPosition(last, node) or not InAnchorBounds(entry, anchor) then
            Fail(self, "invalid_terrain_anchor_path"); return
        end
        if raw.reversePath then
            local first, finish = raw.reversePath[1], raw.reversePath[#raw.reversePath]
            if type(first) ~= "table" or type(finish) ~= "table" or not EqualPosition(first, node) or not EqualPosition(finish, entry) then
                Fail(self, "invalid_terrain_anchor_reverse_path"); return
            end
        end
        anchor.entry, anchor.path, anchor.reversePath = entry, raw.path, raw.reversePath
        anchor.bidirectional = raw.bidirectional == true
    else
        anchor.entry, anchor.path, anchor.reversePath = node, { node }, { node }
    end
    self.anchors[pack.world][#self.anchors[pack.world] + 1] = anchor
end

function Build:PathPosition(raw, node)
    if type(raw) ~= "table" or not Finite(raw.x) or not Finite(raw.y) or not Finite(raw.z) then return nil end
    if raw.instanceID ~= nil and raw.instanceID ~= node.instanceID then return nil end
    local map, floor = raw.uiMapID or node.uiMapID, raw.floor or node.floor
    local access, region = raw.accessKey or node.accessKey, raw.region or node.region
    local noFly, groundOnly = raw.noFly or node.noFly, raw.groundOnly or node.groundOnly
    local cached = self.pathPositionCache[raw]
    if cached and cached.instanceID == node.instanceID and cached.uiMapID == map
        and cached.floor == floor and cached.accessKey == access and cached.region == region
        and cached.noFly == noFly and cached.groundOnly == groundOnly then return cached end
    local point = { x = raw.x, y = raw.y, z = raw.z, instanceID = node.instanceID, uiMapID = map,
        floor = floor, accessKey = access, region = region,
        noFly = noFly, groundOnly = groundOnly }
    self.pathPositionCache[raw] = point
    return point
end
local function VisibilitySize(anchor)
    local extent = math.max(anchor.maxX - anchor.minX, anchor.maxY - anchor.minY)
    -- Interior collision cells are often only a yard wide. A continent-sized
    -- minimum would fill one local bucket beyond the bounded query budget.
    local size = 2
    while size < extent do size = size * 2 end
    return size
end
local function BucketKey(x, y) return tostring(x) .. ":" .. tostring(y) end

function Build:VisibilityOne()
    local pending = self.pendingVisibility
    if pending then
        local key = BucketKey(pending.x, pending.y)
        local bucket = pending.buckets[key] or {}
        pending.buckets[key] = bucket
        bucket[#bucket + 1] = pending.anchor
        pending.x = pending.x + 1
        if pending.x > pending.maxX then pending.x, pending.y = pending.minX, pending.y + 1 end
        if pending.y > pending.maxY then self.pendingVisibility = nil end
        return
    end
    local anchors = self.visibilityWorld and self.anchors[self.visibilityWorld]
    local anchor = anchors and anchors[self.anchorIndex]
    if not anchor then
        local world = next(self.anchors, self.visibilityWorld)
        self.visibilityWorld, self.anchorIndex = world, 1
        if world == nil then
            self.owner._terrainVisibility = { revision = self.sourceRevision or Lib.terrainRevision or 0, worlds = self.visibility }
            self.owner._terrainGeometryCache = { revision = self.sourceRevision or Lib.terrainRevision or 0,
                profile = self.owner.profile, nodes = self.nodes, aliases = self.aliases, anchors = self.anchors,
                visibility = self.visibility, packs = self.packs, worlds = self.geometryWorlds, pathPositions = self.pathPositionCache }
            self.phase, self.index, self.anchorIndex = "attach", 1, 1
        end
        return
    end
    self.anchorIndex = self.anchorIndex + 1
    local size = VisibilitySize(anchor)
    local world = self.visibility[self.visibilityWorld] or {}
    self.visibility[self.visibilityWorld] = world
    local buckets = world[size] or {}
    world[size] = buckets
    local minX, minY = math.floor(anchor.minX / size), math.floor(anchor.minY / size)
    self.pendingVisibility = { anchor = anchor, buckets = buckets, x = minX, y = minY, minX = minX,
        maxX = math.floor(anchor.maxX / size), maxY = math.floor(anchor.maxY / size) }
end

local function Inside(point, anchor, mode)
    local node = anchor.entry or anchor.node
    if mode ~= anchor.mode or point.accessKey ~= node.accessKey then return false end
    if point.floor ~= nil and point.floor ~= node.floor then return false end
    if point.region and node.region and point.region ~= node.region then return false end
    if point.x < anchor.minX or point.x > anchor.maxX or point.y < anchor.minY or point.y > anchor.maxY then return false end
    if Finite(point.z) then
        if anchor.minZ and point.z < anchor.minZ then return false end
        if anchor.maxZ and point.z > anchor.maxZ then return false end
    end
    return true
end

function Build:Missing(point, reason, waiting)
    self.coverage.covered = false
    self.coverage.missingData = self.coverage.missingData or not waiting
    self.coverage.waitingData = self.coverage.waitingData or waiting
    self.coverage.missing[#self.coverage.missing + 1] = { position = point, reason = reason }
end

function Build:Candidate(anchor, point)
    local node = anchor.node
    if self.firstCandidate and not Finite(point.z) then
        local first, current = self.firstCandidate.entry or self.firstCandidate.node, anchor.entry or node
        if first.floor ~= current.floor or math.abs(first.z - current.z) > 0.01 then self.ambiguous = true end
    end
    self.firstCandidate = self.firstCandidate or anchor
    self.candidates[#self.candidates + 1] = anchor
end

function Build:FinishPoint(point)
    if self.ambiguous then self:Missing(point, "ambiguous_terrain_surface", true)
    elseif #self.candidates == 0 then self:Missing(point, "terrain_anchor_missing", false)
    else self.phase, self.connectIndex = "connect", 1; return end
    self.index, self.anchorIndex = self.index + 1, 1
    self.candidates, self.firstCandidate, self.ambiguous = {}, nil, nil
end

function Build:AttachOne()
    local point = self.points[self.index]
    if not point then
        self.status = "ready"
        if not next(self.managed) then self.coverage.covered = false end
        return
    end
    local world = self.owner:GetWorldInstanceID(point.instanceID)
    if not self.managed[world] then self.index = self.index + 1; return end
    if not self.unbounded[world] and not ContainsAny(self.scopes[world], point) then self.index = self.index + 1; return end
    local unavailable = self.unavailableWorlds[world]
    if unavailable or self.unavailablePoints[point] then
        self:Missing(point, unavailable and unavailable.reason or self.unavailablePoints[point], unavailable and unavailable.waiting)
        self.index = self.index + 1
        return
    end
    -- Authored mandatory approach chains deliberately forbid free attachment.
    -- Their explicit passage edges remain the sole way into those endpoints.
    if point.noAutoconnect then self.index = self.index + 1; return end
    if self.attachPoint ~= point then self.attachGeometryPoint = nil end
    local geometryPoint = point
    if self.owner.ResolveTerrainGroundPosition and point.positionSource == "unit"
        and (UnknownNativeHeight(point) or not Finite(point.z)) then
        if self.attachPoint ~= point then
            local reason
            geometryPoint, reason = self.owner:ResolveTerrainGroundPosition(point, self.request.groundHint)
            if not geometryPoint then
                self:Missing(point, reason or "terrain_altitude_missing", true)
                self.index = self.index + 1
                return
            end
            self.attachGeometryPoint = geometryPoint
        else geometryPoint = self.attachGeometryPoint or point end
    end
    local mode = point.movementMode or (point == self.request.start and self.profile.currentMode) or "ground"
    if mode ~= "ground" and not Finite(point.z) then
        self:Missing(point, "terrain_altitude_missing", true)
        self.index = self.index + 1
        return
    end
    if self.attachPoint ~= point then
        self.attachPoint, self.attachLevel, self.attachBucket, self.attachBucketIndex = point, nil, nil, 1
    end
    local anchor = self.attachBucket and self.attachBucket[self.attachBucketIndex]
    if not anchor then
        local size, buckets = next(self.visibility[world] or {}, self.attachLevel)
        if not size then self:FinishPoint(point); return end
        self.attachLevel, self.attachBucketIndex = size, 1
        self.attachBucket = buckets[BucketKey(math.floor(point.x / size), math.floor(point.y / size))] or {}
        return
    end
    self.attachBucketIndex = self.attachBucketIndex + 1
    if Inside(geometryPoint, anchor, mode) then self:Candidate(anchor, geometryPoint) end
end

local function EndpointPosition(point, anchor)
    if Finite(point.z) then return point end
    local projected = {}
    for key, value in pairs(point) do projected[key] = value end
    projected.z, projected.movementMode = (anchor.entry or anchor.node).z, anchor.mode
    return projected
end

function Build:ConnectOne()
    local anchor = self.candidates[self.connectIndex]
    local point = self.points[self.index]
    if not anchor then
        self.coverage.attached[point] = true
        self.index, self.anchorIndex, self.phase = self.index + 1, 1, "attach"
        self.candidates, self.firstCandidate, self.ambiguous = {}, nil, nil
        return
    end
    self.connectIndex = self.connectIndex + 1
    if not Terrain.Enabled(self.profile, anchor.mode) or not FlightAllowed(self.profile, point, anchor.mode) then return end
    local to = anchor.node
    local geometryPoint = EndpointPosition(self.attachGeometryPoint or point, anchor)
    self.pendingConnection = { anchor = anchor, point = point, geometryPoint = geometryPoint, index = 1, direction = "outward",
        edge = EdgeRecord(point, to, anchor.mode, 0, nil) }
    self.pendingConnection.edge.polyline = { geometryPoint }
    self.pendingConnection.edge.polylineWeights = { 0 }
    self.phase = "connectPath"
end

function Build:ConnectPathOne()
    local pending = self.pendingConnection
    local anchor, edge = pending.anchor, pending.edge
    local source = pending.direction == "outward" and anchor.path or (anchor.reversePath or anchor.path)
    local index = pending.direction == "inward" and not anchor.reversePath and #source - pending.index + 1 or pending.index
    local point = source[index]
    if not point and pending.direction == "inward" and not pending.finishedEndpoint then
        point, pending.finishedEndpoint = pending.geometryPoint, true
    end
    if point then
        pending.index = pending.index + 1
        point = (point == anchor.node or point == pending.geometryPoint) and point or self:PathPosition(point, anchor.node)
        if not point then Fail(self, "invalid_terrain_anchor_path"); return end
        if not FlightAllowed(self.profile, point, anchor.mode) then pending.rejected = true end
        local previous = edge.polyline[#edge.polyline]
        if not EqualPosition(previous, point) then
            edge.seconds = edge.seconds + Terrain.Seconds({ mode = anchor.mode }, previous, point, self.profile)
            edge.polyline[#edge.polyline + 1] = point
            edge.polylineWeights[#edge.polylineWeights + 1] = edge.seconds
        end
        return
    end
    edge.polylineWeightTotal = edge.seconds
    if not pending.rejected then self.result[#self.result + 1] = edge end
    if pending.direction == "outward" and (anchor.reversePath or anchor.bidirectional) then
        pending.direction, pending.index = "inward", 1
        pending.rejected = nil
        pending.edge = EdgeRecord(anchor.node, pending.point, anchor.mode, 0, nil)
        pending.edge.polyline = { anchor.node }
        pending.edge.polylineWeights = { 0 }
        return
    end
    self.pendingConnection, self.phase = nil, "connect"
end

local STEPS = { collect = Build.CollectOne, load = Build.LoadOne, cache = Build.CacheOne, packs = Build.PackOne,
    nodes = Build.NodeOne, edges = Build.EdgeOne, polyline = Build.PolylineOne,
    anchors = Build.AnchorOne, visibility = Build.VisibilityOne,
    attach = Build.AttachOne, connect = Build.ConnectOne, connectPath = Build.ConnectPathOne }

function Build:Step(operations, milliseconds)
    if self.status ~= "planning" then return self.status, self.result, self.coverage end
    if self.sourceRevision and self.sourceRevision ~= (Lib.terrainRevision or 0) then
        local fresh = self.owner:CreateTerrainEdgeBuild(self.request)
        for key in pairs(self) do self[key] = nil end
        for key, value in pairs(fresh) do self[key] = value end
    end
    operations = Finite(operations) and math.max(0, math.floor(operations)) or 64
    milliseconds = Finite(milliseconds) and math.max(0, milliseconds) or 1
    self.workLastStep = 0
    if operations == 0 or milliseconds == 0 then return self.status end
    local deadline = self.clock and self.clock() + milliseconds
    for _ = 1, operations do
        if deadline and self.workLastStep > 0 and self.clock() >= deadline then break end
        self.workLastStep = self.workLastStep + 1
        STEPS[self.phase](self)
        if self.status ~= "planning" then break end
    end
    self.coverage.revision = self.sourceRevision or Lib.terrainRevision or 0
    return self.status, self.result, self.coverage
end

function Build:Cancel()
    self.status, self.result = "cancelled", nil
    self.groups, self.points, self.nodes, self.anchors, self.packs = {}, {}, {}, {}, {}
    self.candidates, self.pendingEdge = {}, nil
    self.pendingAnchor, self.pendingConnection = nil, nil
end

function Instance:CreateTerrainEdgeBuild(request)
    request = type(request) == "table" and request or {}
    local managed = {}
    local coverage = { terrainRegions = managed, covered = true, waitingData = false,
        missingData = false, missing = {}, attached = {} }
    local fallback, owner = request.canWalk, self
    local scopes, unbounded = {}, {}
    coverage.canWalk = function(from, to)
        local first, last = owner:GetWorldInstanceID(from.instanceID), owner:GetWorldInstanceID(to.instanceID)
        if (managed[first] and unbounded[first]) or (managed[last] and unbounded[last]) then return false end
        if first == last and managed[first] then
            if ContainsAny(scopes[first], from) or ContainsAny(scopes[first], to) then return false end
            for _, scope in ipairs(scopes[first]) do if ScopeBlocks(scope, from, to) then return false end end
        end
        return fallback and fallback(from, to) or false
    end
    local groups = {}
    if type(request.edges) == "table" then groups[#groups + 1] = request.edges end
    for _, group in ipairs(request.edgeGroups or {}) do groups[#groups + 1] = group end
    local build = setmetatable({ owner = self, request = request, clock = request.clock,
        status = "planning", phase = "collect", group = 1, index = 1, groups = groups,
        points = {}, pointSeen = {}, unavailablePoints = {}, unavailableWorlds = {}, geometryWorlds = {}, managed = managed,
        scopes = scopes, unbounded = unbounded, loadedWorlds = {},
        packs = {}, nodes = {}, aliases = {}, anchors = {}, visibility = {}, pathPositionCache = {}, result = {}, coverage = coverage,
        candidates = {}, profile = Terrain.Profile(request) }, Build)
    build:AddPoint(request.start); build:AddPoint(request.goal)
    return build
end

local function SegmentInterval(from, to, anchor, mode)
    local entry = anchor.entry or anchor.node
    if mode ~= "ground" and (entry.noFly or entry.groundOnly) then return nil end
    if anchor.mode ~= mode or from.accessKey ~= entry.accessKey or to.accessKey ~= entry.accessKey then return nil end
    if (from.floor ~= nil and from.floor ~= entry.floor) or (to.floor ~= nil and to.floor ~= entry.floor) then return nil end
    if (from.region and entry.region and from.region ~= entry.region) or (to.region and entry.region and to.region ~= entry.region) then return nil end
    local lo, hi = Slab(from.x, to.x, anchor.minX, anchor.maxX, 0, 1)
    if not lo then return nil end
    lo, hi = Slab(from.y, to.y, anchor.minY, anchor.maxY, lo, hi)
    if not lo then return nil end
    return Slab(from.z, to.z, anchor.minZ, anchor.maxZ, lo, hi)
end

local function VisibilityIntervals(world, from, to, mode)
    local intervals, seen, work = {}, {}, 0
    for size, buckets in pairs(world) do
        local x, y = math.floor(from.x / size), math.floor(from.y / size)
        local endX, endY = math.floor(to.x / size), math.floor(to.y / size)
        local dx, dy = to.x - from.x, to.y - from.y
        local stepX, stepY = dx < 0 and -1 or 1, dy < 0 and -1 or 1
        local nextX = dx == 0 and math.huge or ((x + (dx > 0 and 1 or 0)) * size - from.x) / dx
        local nextY = dy == 0 and math.huge or ((y + (dy > 0 and 1 or 0)) * size - from.y) / dy
        local deltaX, deltaY = dx == 0 and math.huge or size / math.abs(dx), dy == 0 and math.huge or size / math.abs(dy)
        local visited = 0
        -- Visit the segment's cells, not its entire enclosing rectangle. Every
        -- anchor is indexed into the buckets touched by its closed XY bounds,
        -- including cells that meet the line only at an edge or corner.
        while true do
            visited, work = visited + 1, work + 1
            if visited > 64 or work > 512 then return nil end
            for _, anchor in ipairs(buckets[BucketKey(x, y)] or {}) do
                work = work + 1
                if work > 512 then return nil end
                if not seen[anchor] then
                    seen[anchor] = true
                    local lo, hi = SegmentInterval(from, to, anchor, mode)
                    if lo then intervals[#intervals + 1] = { lo, hi } end
                    if #intervals > 256 then return nil end
                end
            end
            if x == endX and y == endY then break end
            if nextX < nextY then
                x, nextX = x + stepX, nextX + deltaX
            elseif nextY < nextX then
                y, nextY = y + stepY, nextY + deltaY
            else
                x, y = x + stepX, y + stepY
                nextX, nextY = nextX + deltaX, nextY + deltaY
            end
        end
    end
    return intervals
end

function Instance:CanTraverseTerrain(from, to, mode)
    if type(from) ~= "table" or type(to) ~= "table" or not Finite(from.x) or not Finite(from.y)
        or not Finite(to.x) or not Finite(to.y) then return nil end
    local world = self:GetWorldInstanceID(from.instanceID)
    if world ~= self:GetWorldInstanceID(to.instanceID) then return false end
    local cache = self._terrainVisibility
    if not cache or cache.revision ~= (Lib.terrainRevision or 0) then return nil end
    local geometry = cache.worlds[world]
    if not geometry then return nil end
    local intervals = VisibilityIntervals(geometry, from, to, mode or "ground")
    if not intervals then return nil end
    table.sort(intervals, function(a, b) return a[1] < b[1] end)
    local reached = 0
    for _, interval in ipairs(intervals) do
        if interval[1] > reached + 0.0000001 then break end
        reached = math.max(reached, interval[2])
        if reached >= 1 then return true end
    end
    if reached <= 0 then return nil end
    reached = math.max(0, reached - 0.000001)
    return nil, { instanceID = from.instanceID, uiMapID = from.uiMapID, floor = from.floor,
        accessKey = from.accessKey, region = from.region,
        x = from.x + (to.x - from.x) * reached, y = from.y + (to.y - from.y) * reached,
        z = Finite(from.z) and Finite(to.z) and from.z + (to.z - from.z) * reached or nil,
        movementMode = mode or "ground" }
end
