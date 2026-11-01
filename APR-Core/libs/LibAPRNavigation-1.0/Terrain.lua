-- Declarative terrain is supplied by the consumer; this module never queries WoW.
-- Only a proved convex anchor may connect a live position to the terrain graph.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("terrain", 1) then return end
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

function Lib.ValidateTerrainData(data, worldID)
    assert(type(data) == "table" and data.format == 1, "unsupported terrain format")
    assert(Nonnegative(worldID), "terrain world required")
    assert(data.worldID == nil or data.worldID == worldID, "terrain world mismatch")
    assert(type(data.nodes) == "table" and type(data.edges) == "table", "terrain graph required")
    assert(data.anchors == nil or type(data.anchors) == "table", "terrain anchors must be an array")
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
    if profile and profile[world] and next(profile[world].packs or {}) then return true end
    return self.env.hasTerrainData and self.env.hasTerrainData(self.profile, world, point) == true or false
end

local function NodePosition(raw, world, pack)
    if type(raw) ~= "table" or not Identity(raw.id) or not Finite(raw.x) or not Finite(raw.y)
        or not Finite(raw.z) or not Channel(raw.floor) or not Channel(raw.accessKey)
        or (raw.region ~= nil and type(raw.region) ~= "string") then return nil end
    if raw.instanceID ~= nil and raw.instanceID ~= world then return nil end
    if raw.movementMode ~= nil and not MODES[raw.movementMode] then return nil end
    return { x = raw.x, y = raw.y, z = raw.z, instanceID = world, uiMapID = raw.uiMapID,
        floor = raw.floor, accessKey = raw.accessKey, region = raw.region,
        groundOnly = raw.groundOnly, movementMode = raw.movementMode or "ground",
        noFly = raw.noFly,
        terrainNodeKey = Key(world, pack, raw.id), noAutoconnect = true }
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
    if not self.owner:HasTerrainData(point) then return end
    self.managed[world] = true
    if self.owner.env.requestTerrainData then
        local state, reason = self.owner.env.requestTerrainData(self.owner.profile, world, point)
        if state == "planning" or state == "waiting_data" then self.coverage.waitingData = true end
        if state == "missing" then self.loadMissing[point] = reason or "pack_unavailable" end
    end
end

function Build:CacheOne()
    local cache = self.owner._terrainGeometryCache
    if not cache or cache.revision ~= (Lib.terrainRevision or 0) or cache.profile ~= self.owner.profile then
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
    self.packWorld = datasets and datasets[world] or { packs = {} }
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
    local point = NodePosition(raw, pack.world, pack.id)
    if not point or self.nodes[point.terrainNodeKey] then Fail(self, "invalid_terrain_node"); return end
    if not point.region then point.region = self.owner:GetPositionRegion(point) end
    self.nodes[point.terrainNodeKey] = point
    local alias = Key(pack.world, "", raw.id)
    if self.aliases[alias] == nil then self.aliases[alias] = point else self.aliases[alias] = false end
    local anchors = self.anchors[pack.world] or {}
    self.anchors[pack.world] = anchors
    anchors[#anchors + 1] = { node = point, entry = point, path = { point }, reversePath = { point }, mode = point.movementMode,
        minX = point.x, maxX = point.x, minY = point.y, maxY = point.y, minZ = point.z, maxZ = point.z }
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
    local mode = raw.mode or point.movementMode
    if not MODES[mode] then return nil end
    if mode ~= "ground" and (raw.minZ == nil or raw.maxZ == nil) then return nil end
    if raw.path ~= nil and type(raw.path) ~= "table" then return nil end
    if raw.reversePath ~= nil and type(raw.reversePath) ~= "table" then return nil end
    if raw.reversePath and not raw.path then return nil end
    if not raw.path and not InAnchorBounds(point, raw) then return nil end
    return { node = point, minX = raw.minX, maxX = raw.maxX, minY = raw.minY, maxY = raw.maxY,
        minZ = raw.minZ, maxZ = raw.maxZ, mode = mode }
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
    local cached = self.pathPositionCache[raw]
    if cached and cached.instanceID == node.instanceID and cached.uiMapID == map
        and cached.floor == floor and cached.accessKey == access and cached.region == region then return cached end
    local point = { x = raw.x, y = raw.y, z = raw.z, instanceID = node.instanceID, uiMapID = map,
        floor = floor, accessKey = access, region = region,
        noFly = raw.noFly, groundOnly = raw.groundOnly }
    self.pathPositionCache[raw] = point
    return point
end
local function VisibilitySize(anchor)
    local extent = math.max(anchor.maxX - anchor.minX, anchor.maxY - anchor.minY)
    local size = 64
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
                visibility = self.visibility, packs = self.packs, worlds = self.managed, pathPositions = self.pathPositionCache }
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
    if self.candidateSeen[node] then return end
    self.candidateSeen[node] = true
    if self.firstCandidate and not Finite(point.z) and point.floor == nil then
        local first, current = self.firstCandidate.entry or self.firstCandidate.node, anchor.entry or node
        if first.floor ~= current.floor or math.abs(first.z - current.z) > 0.01 then self.ambiguous = true end
    end
    self.firstCandidate = self.firstCandidate or anchor
    self.candidates[#self.candidates + 1] = anchor
end

function Build:FinishPoint(point)
    if self.ambiguous then self:Missing(point, "ambiguous_terrain_surface", true)
    elseif #self.candidates == 0 then self:Missing(point, self.loadMissing[point] or "terrain_anchor_missing", false)
    else self.phase, self.connectIndex = "connect", 1; return end
    self.index, self.anchorIndex = self.index + 1, 1
    self.candidates, self.candidateSeen, self.firstCandidate, self.ambiguous = {}, {}, nil, nil
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
    -- Authored mandatory approach chains deliberately forbid free attachment.
    -- Their explicit passage edges remain the sole way into those endpoints.
    if point.noAutoconnect then self.index = self.index + 1; return end
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
    local mode = point.movementMode or (point == self.request.start and self.profile.currentMode) or "ground"
    if Inside(point, anchor, mode) then self:Candidate(anchor, point) end
end

function Build:ConnectOne()
    local anchor = self.candidates[self.connectIndex]
    local point = self.points[self.index]
    if not anchor then
        self.coverage.attached[point] = true
        self.index, self.anchorIndex, self.phase = self.index + 1, 1, "attach"
        self.candidates, self.candidateSeen, self.firstCandidate, self.ambiguous = {}, {}, nil, nil
        return
    end
    self.connectIndex = self.connectIndex + 1
    local to = anchor.node
    self.pendingConnection = { anchor = anchor, point = point, index = 1, direction = "outward",
        edge = EdgeRecord(point, to, anchor.mode, 0, nil) }
    self.pendingConnection.edge.polyline = { point }
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
        point, pending.finishedEndpoint = pending.point, true
    end
    if point then
        pending.index = pending.index + 1
        point = point == anchor.node and point or self:PathPosition(point, anchor.node)
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
    self.candidates, self.candidateSeen, self.pendingEdge = {}, {}, nil
    self.pendingAnchor, self.pendingConnection = nil, nil
end

function Instance:CreateTerrainEdgeBuild(request)
    request = type(request) == "table" and request or {}
    local managed = {}
    local coverage = { terrainRegions = managed, covered = true, waitingData = false,
        missingData = false, missing = {}, attached = {} }
    local fallback, owner = request.canWalk, self
    coverage.canWalk = function(from, to)
        if managed[owner:GetWorldInstanceID(from.instanceID)] or managed[owner:GetWorldInstanceID(to.instanceID)] then return false end
        return fallback and fallback(from, to) or false
    end
    local groups = {}
    if type(request.edges) == "table" then groups[#groups + 1] = request.edges end
    for _, group in ipairs(request.edgeGroups or {}) do groups[#groups + 1] = group end
    local build = setmetatable({ owner = self, request = request, clock = request.clock,
        status = "planning", phase = "collect", group = 1, index = 1, groups = groups,
        points = {}, pointSeen = {}, loadMissing = {}, managed = managed,
        packs = {}, nodes = {}, aliases = {}, anchors = {}, visibility = {}, pathPositionCache = {}, result = {}, coverage = coverage,
        candidates = {}, candidateSeen = {}, profile = Terrain.Profile(request) }, Build)
    build:AddPoint(request.start); build:AddPoint(request.goal)
    return build
end

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
        local minX, maxX = math.floor(math.min(from.x, to.x) / size), math.floor(math.max(from.x, to.x) / size)
        local minY, maxY = math.floor(math.min(from.y, to.y) / size), math.floor(math.max(from.y, to.y) / size)
        if (maxX - minX + 1) * (maxY - minY + 1) > 64 then return nil end
        for x = minX, maxX do
            for y = minY, maxY do
                work = work + 1
                if work > 512 then return nil end
                local bucket = buckets[BucketKey(x, y)] or {}
                for _, anchor in ipairs(bucket) do
                    work = work + 1
                    if work > 512 then return nil end
                    if not seen[anchor] then
                        seen[anchor] = true
                        local lo, hi = SegmentInterval(from, to, anchor, mode)
                        if lo then intervals[#intervals + 1] = { lo, hi } end
                        if #intervals > 256 then return nil end
                    end
                end
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
