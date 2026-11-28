-- SPDX-License-Identifier: GPL-3.0-or-later
local Lib = LibStub("LibAPRNavigation-1.0")
local Runtime = Lib._TerrainNamespace
Lib._TerrainNamespace = nil
if not Runtime or not Lib:BeginModule("Terrain", 28) then return end
local Grid = Runtime.PathGrid
local Work = Runtime.Work
local maps, providers = {}, setmetatable({}, { __mode = "kv" })
local activeProfile = "forever"
local generation = 0
local Provider, Job = {}, {}
Provider.__index, Job.__index = Provider, Job
Provider.proveCandidatePaths = true

local function Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do
        Work()
        copy[key] = Copy(child)
    end
    return copy
end

function Runtime.Data(mapID)
    return maps[mapID] and maps[mapID].data
end

function Lib:MatchesGeneratedTerrain(profile, build)
    if profile ~= "retail" and profile ~= "forever" then return false end
    local getBuildInfo = rawget(_G, "GetBuildInfo")
    if type(getBuildInfo) ~= "function" then return false end
    local version, number, _, interface = getBuildInfo()
    if type(version) ~= "string" or (type(number) ~= "string" and type(number) ~= "number")
        or version .. "." .. tostring(number) ~= build then return false end
    interface = tonumber(interface) or 0
    if profile == "forever" and (interface < 16000 or interface >= 17000) then return false end
    if profile == "retail" and interface < 100000 then return false end
    if activeProfile ~= profile and next(maps) then return false end
    activeProfile = profile
    return true
end

function Lib:RegisterTerrainData(profile, mapID, data, revision, generated)
    if profile ~= activeProfile or not Finite(mapID) or mapID < 0 or mapID % 1 ~= 0 then return end
    revision = revision or 1
    if not Finite(revision) or type(data) ~= "table" then return end
    generated = generated == true
    local previous = maps[mapID]
    if previous and (previous.generated and not generated
        or (previous.generated == generated and previous.revision >= revision)) then return end
    -- Catalogue declarations contain immutable packed strings. The mutable field
    -- tables belong only to this runtime, never to the registering addon/global.
    local ok, private = pcall(Lib.Copy, data)
    maps[mapID] = { data = ok and private or {}, revision = revision, generated = generated }
    generation = generation + 1
    Grid.Reset()
end

function Lib.Instance:GetWalkingProvider()
    if self.profile ~= activeProfile or not next(maps) then return nil end
    if not providers[self] then providers[self] = setmetatable({ owner = self }, Provider) end
    return providers[self]
end

function Provider:HasMap(instanceID)
    return maps[instanceID] ~= nil
end

local function Metadata(data)
    if data.format ~= 2 and data.format ~= 3 then return false end
    if data.heightDigits ~= nil and data.heightDigits ~= 2 and data.heightDigits ~= 3 then return false end
    if data.part or not Finite(data.cells) or data.cells < 2 or data.cells > 256
        or data.cells % 1 ~= 0 then return false end
    for _, field in ipairs({ "nx", "ny", "cx0", "cy0", "zstep", "swim" }) do
        Work()
        if not Finite(data[field]) then return false end
    end
    return data.nx > 0 and data.ny > 0 and data.nx % 1 == 0 and data.ny % 1 == 0
        and data.zstep > 0 and data.swim > 0
end

local function Whole(data)
    if not Metadata(data) then return false end
    if data.partitionSchema then return Runtime.ValidPartition and Runtime.ValidPartition(data) or false end
    if data.counts then
        if type(data.counts) ~= "table" or type(data.packed) ~= "table" then return false end
        for field, want in pairs(data.counts) do
            Work()
            local count = 0
            if type(data.packed[field]) ~= "table" then return false end
            for _ in pairs(data.packed[field]) do Work(); count = count + 1 end
            if count ~= want then return false end
        end
    end
    local grids = (data.packed and data.packed.grid) or data.grid
    if type(grids) ~= "table" or not next(grids) then return false end
    for key in pairs(grids) do
        Work()
        if not Finite(key) or key < 1 or key > data.nx * data.ny or key % 1 ~= 0 then return false end
        -- Normal-only clusters omit their class page. The declared packed page
        -- counts above still reject a missing non-normal class part.
        for _, field in ipairs({ "grid", "height", "graph" }) do
            Work()
            local loose = data[field] and data[field][key]
            local packed = data.packed and data.packed[field] and data.packed[field][key]
            if type(loose) ~= "string" and type(packed) ~= "table" then return false end
        end
    end
    return true
end

local function Position(point)
    return type(point) == "table" and Finite(point.instanceID)
        and Finite(point.x) and Finite(point.y) and (point.z == nil or Finite(point.z))
end

local function SelectPhase(owner, point, faction)
    local phases = owner.config and owner.config.GarrisonPhases
    if not phases or not point or point.instanceID ~= phases.world then return end
    local observed = point.terrainPhase
    if observed and owner:GetGarrisonPhase(observed) then return maps[observed] and observed or nil end
    local frame = GetTime and GetTime()
    local cached = owner.terrainPhaseObservation
    if frame and cached and cached.frame == frame and (not faction or faction == cached.faction) then
        return cached.phase
    end
    local env = owner.env
    if not faction and env.getCharacter then
        local character = env.getCharacter()
        faction = character and character.faction
    end
    local family = faction and phases[faction]
    local level = family and env.getGarrisonLevel and env.getGarrisonLevel(phases.garrisonType)
    local phase = level and family.levels[level]
    phase = maps[phase] and phase or nil
    owner.terrainPhaseObservation = frame and { frame = frame, faction = faction, phase = phase } or nil
    return phase
end

local function TerrainMap(point, phase)
    local st = phase and Grid.State(phase)
    if st and Grid.locate(st, point.x, point.y) then return phase end
    return point.instanceID
end

local function HasPage(map, point)
    local entry = maps[map]
    if not entry then return false end
    if not entry.validated and not Metadata(entry.data) then return true end
    local st = Grid.State(map)
    local key = Grid.locate(st, point.x, point.y)
    if key == nil then return false end
    if not entry.generated then return true end
    local pages = entry.data.packed and entry.data.packed.grid or entry.data.grid
    return pages ~= nil and pages[key + 1] ~= nil
end

function Provider:RequiresWalkingProof(from, to)
    if not Position(from) or not Position(to) or from.instanceID ~= to.instanceID then return false end
    local phase = SelectPhase(self.owner, from.terrainPhase and from or to)
    return HasPage(TerrainMap(from, phase), from) and HasPage(TerrainMap(to, phase), to)
end

function Provider:HasWalkingCoverage(point)
    if not Position(point) then return false end
    local entry = maps[point.instanceID]
    return entry ~= nil and (not entry.generated or self:RequiresWalkingProof(point, point))
end

function Provider:GetWalkingPage(point)
    -- Search rejection keys are scoped to the geographical world. Phased
    -- candidates discard page-local rejection hints when returning costs.
    local st = Grid.State(point.instanceID)
    if st then return Grid.locate(st, point.x, point.y) end
end

-- Caller-owned observations remain unchanged. These synchronous guidance reads
-- never decode terrain or start work outside the planner's existing budget.
function Provider:IsSameWalkingCell(a, b)
    if not Position(a) or not Position(b) then return nil end
    if a.instanceID ~= b.instanceID then return false end
    local phase = SelectPhase(self.owner, a)
    local map = TerrainMap(a, phase)
    if map ~= TerrainMap(b, phase) then return false end
    local entry = maps[map]
    if not entry or not (entry.validated or Metadata(entry.data)) then return nil end
    local st = Grid.State(map)
    local tileA, cellA = Grid.locate(st, a.x, a.y)
    local tileB, cellB = Grid.locate(st, b.x, b.y)
    if tileA == nil or tileB == nil then return nil end
    return tileA == tileB and cellA == cellB
end

local function ObservedFloors(st, point, load)
    local key, cell = Grid.locate(st, point.x, point.y)
    local tile = key and (load and Grid.grid(st, key) or st.grid[key])
    local heights = {}
    if tile then
        local layers = tile.layers[cell]
        for i = 0, layers and #layers or 0 do
            Work()
            local node = i == 0 and cell or layers[i]
            local class = (tile.class[node] or 0) % 8
            if tile.z[node] and class ~= 5 and (point.indoors == nil or (class == 4) == point.indoors) then
                heights[#heights + 1] = Grid.surfaceHeight(st, tile, node, point.x, point.y)
            end
        end
    end
    return Runtime.MatchSurfaceHeights(st, point, heights, load)
end

local function GuidanceHeight(map, point)
    local height = Runtime.GuidanceHeight(map, point.x, point.y)
    local st = height == nil and type(point.indoors) == "boolean" and Grid.State(map)
    if st then
        local floors = ObservedFloors(st, point, false)
        if #floors == 1 then return floors[1] end
    end
    return height
end

function Provider:GetGuidanceHeight(point)
    if not Position(point) then return nil end
    return GuidanceHeight(TerrainMap(point, SelectPhase(self.owner, point)), point)
end

function Provider:GetWalkingObservationHeight(point, previous)
    if not Position(point) then return end
    local phase = SelectPhase(self.owner, point)
    local map = TerrainMap(point, phase)
    local height = GuidanceHeight(map, point)
    if height ~= nil then return height end
    if Position(previous) and Finite(previous.z) and previous.instanceID == point.instanceID
        and TerrainMap(previous, phase) == map then
        return Runtime.ContinueWalkingHeight(point, previous, map)
    end
end

local function RequiresNativeChord(from, to)
    -- A coarse endpoint is attached to a certified centre by a separately
    -- checked chord. The rest of the detailed path requires native proof.
    return (from.geometryVerified or to.geometryVerified) and not (from.coarseEndpoint or to.coarseEndpoint)
end

local function WalkingFaction(owner)
    local env = owner and owner.env
    if env and env.getCharacter then
        local ok, character = pcall(env.getCharacter)
        if ok and type(character) == "table" then return character.faction end
    end
end

local function ChordMap(owner, from, to)
    local phase = SelectPhase(owner, from.terrainPhase and from or to)
    local first, last = TerrainMap(from, phase), TerrainMap(to, phase)
    if first == last then return first end
    if (from.phaseBoundary or to.phaseBoundary)
        and (from.x - to.x)^2 + (from.y - to.y)^2 <= math.max(20, Grid.State(phase).unit * 1.5)^2 then
        return from.instanceID, true
    end
end

-- Nearby destinations can share a walking direction across several storeys.
-- Prove the whole directed chord from every plausible departure.
local function SharedFloorChord(map, from, to, faction, load)
    local st = map and Grid.State(map)
    local distance = (from.x - to.x)^2 + (from.y - to.y)^2
    if not st or distance > 50 ^ 2 then return end
    if from.z == nil and from.indoors ~= true then return end
    local starts = from.z and {from.z} or ObservedFloors(st, from, load)
    if #starts == 0 or load and #starts == 1 then return end
    local costs = Runtime.FactionCostContext(st, faction, load)
    if Runtime.HostileFraction(costs, from, to) ~= 0 then return end
    local goals = to.z and {to.z} or ObservedFloors(st, to, load)
    local pages = load and {} or nil
    local rise = 0
    for _, startZ in ipairs(starts) do
        local reached
        for _, goalZ in ipairs(goals) do
            Work()
            if Runtime.Sight(map, from.x, from.y, startZ, to.x, to.y, goalZ, pages, nil, true) == true then
                if reached then return end
                reached = goalZ
            end
        end
        if not reached then return end
        rise = math.max(rise, math.abs(reached - startZ))
    end
    return math.sqrt(distance + rise ^ 2)
end

function Provider:CanFollowWalkingSegment(from, to, joining)
    if not Position(from) or not Position(to) or from.instanceID ~= to.instanceID then return nil end
    if to.sharedFloorChord then
        return SharedFloorChord(ChordMap(self.owner, from, to), from, to, WalkingFaction(self.owner), false) ~= nil
    end
    if not Finite(from.z) or not Finite(to.z) then return nil end
    -- Live steering may merge across open terrain. The line still goes through
    -- every intervening cell, and the native surface rules apply inside windows.
    local joinRange = joining == "outdoor" and 100 or joining == true and 20
    local shortJoin = joinRange and not from.geometryVerified
        and (from.x - to.x)^2 + (from.y - to.y)^2 <= joinRange^2
    local map, crosses = ChordMap(self.owner, from, to)
    if not map then return false end
    if joining and self.owner.profile == "forever" then
        local costs = Runtime.FactionCostContext(Grid.State(map), to.terrainFaction or WalkingFaction(self.owner), false)
        local exposure = Runtime.HostileDistance(costs, from, to)
        if exposure == nil then return nil end
        if exposure > (to.hostileDistance or 0) + .001 then return false end
    end
    return Runtime.Sight(map, from.x, from.y, from.z, to.x, to.y, to.z, nil, nil, nil,
        not crosses and RequiresNativeChord(from, to), shortJoin)
end

-- Off the current leg, require two nearby, single-surface witnesses. On
-- the leg itself one unique witness can distinguish the reachable layer,
-- even when the other end of the leg is a stacked bend.
local function CorridorHeight(provider, point, step, loadPages)
    if not Position(point) or point.z ~= nil or not step or step.kind ~= "walk"
        or type(step.path) ~= "table" then return end
    local phase = SelectPhase(provider.owner, point)
    local map = TerrainMap(point, phase)
    local st = Grid.State(map)
    if not st then return end
    local key, cell = Grid.locate(st, point.x, point.y)
    if not key then return end
    local tile = loadPages and Grid.grid(st, key) or st.grid[key]
    local cursor = step.pathCursor or 2
    local pages = loadPages and {} or nil
    local function sight(a, b, unbranched)
        return Runtime.Sight(map, a.x, a.y, a.z, b.x, b.y, b.z, pages, nil, unbranched)
    end
    local function compatible(anchor)
        if not Finite(anchor.z) or anchor.instanceID ~= point.instanceID
            or TerrainMap(anchor, phase) ~= map then return false end
        -- A continuous outdoor corridor can span several client map labels.
        if anchor.uiMapID ~= point.uiMapID and (not anchor.region or anchor.region ~= point.region) then return false end
        for _, field in ipairs({"region", "accessKey", "floor"}) do
            if anchor[field] ~= point[field] then return false end
        end
        if loadPages then
            local anchorKey = Grid.locate(st, anchor.x, anchor.y)
            if not anchorKey or not Grid.grid(st, anchorKey) then return false end
        end
        return true
    end
    local function witness(anchor)
        -- A verified change of access region can place the player on a
        -- landing whose other floors share the same XY. The live cursor
        -- advances this witness only through checked walking segments.
        if step.walkingLanding and anchor == step.path[cursor - 1] then return true end
        local observed = provider:GetGuidanceHeight(anchor)
        return observed ~= nil and math.abs(observed - anchor.z) <= st.data.zstep
    end
    -- Resolve a shared XY on an active native leg from a nearby unique
    -- floor reached along the same consecutive, certified edges.
    if step.path[cursor] and step.path[cursor].geometryVerified then
        local found
        for i=cursor-1,cursor do
            local a,b=step.path[i],step.path[i+1]
            if a and b and a.geometryVerified and b.geometryVerified and compatible(a) and compatible(b) then
                local dx,dy=b.x-a.x,b.y-a.y
                local length=dx*dx+dy*dy
                local u=length>0 and ((point.x-a.x)*dx+(point.y-a.y)*dy)/length
                local precision=math.max(.00001,math.max(math.abs(point.x),math.abs(point.y))*2^-23)
                local margin=length>0 and precision/math.sqrt(length) or 0
                if u and u>=-margin and u<=1+margin and (a.x+u*dx-point.x)^2+(a.y+u*dy-point.y)^2<=precision^2 then
                    local z=a.z+u*(b.z-a.z)
                    local anchored, along = false, 0
                    -- A detailed path can have a vertex every half yard. Find
                    -- the nearby floor by distance, with a bound on edge reads.
                    for j=i,math.max(1,i-23),-1 do
                        local anchor,nextPoint=step.path[j],step.path[j+1]
                        if not anchor.geometryVerified or not nextPoint.geometryVerified
                            or not compatible(anchor) or not compatible(nextPoint) then break end
                        local fraction = j == i and math.max(0, math.min(1, u)) or 1
                        along = along + fraction * math.sqrt((anchor.x-nextPoint.x)^2 + (anchor.y-nextPoint.y)^2)
                        if along > 45 or provider:CanFollowWalkingSegment(anchor,nextPoint) ~= true then break end
                        if witness(anchor) or witness(nextPoint) then anchored=true; break end
                    end
                    if anchored then
                        if found and math.abs(found-z)>.01 then return end
                        found=z
                    end
                end
            end
        end
        if found then return found end
    end
    if not tile then return end
    local function legSurface(a, b)
        local dx, dy = b.x - a.x, b.y - a.y
        local lengthSquared = dx * dx + dy * dy
        if lengthSquared == 0 then return end
        local ax, ay = point.x - a.x, point.y - a.y
        local fraction = math.max(0, math.min(1, (ax * dx + ay * dy) / lengthSquared))
        local onLeg = (ax - fraction * dx)^2 + (ay - fraction * dy)^2 <= 1
        local nearBoth = ax^2 + ay^2 <= 50^2 and (point.x - b.x)^2 + (point.y - b.y)^2 <= 50^2
        if not (onLeg or nearBoth) or not compatible(a) or not compatible(b) then return end
        local first, last = witness(a), witness(b)
        if not (nearBoth and first and last) and not (onLeg and (first or last)
            and sight(a, b)) then return end

        local found, layers = nil, tile.layers[cell]
        for layer = 0, layers and #layers or 0 do
            if loadPages then Work() end
            local node = layer == 0 and cell or layers[layer]
            local z = Grid.surfaceHeight(st, tile, node, point.x, point.y)
            if z then
                local incoming = not first or Runtime.Sight(map, a.x, a.y, a.z,
                    point.x, point.y, z, pages, nil, not last)
                local outgoing = not last or Runtime.Sight(map, point.x, point.y, z,
                    b.x, b.y, b.z, pages, nil, not first)
                if incoming ~= false and outgoing ~= false then
                    if found or not incoming or not outgoing then return nil, true end
                    found = node
                end
            end
        end
        -- A stacked endpoint may confirm continuity after the independent
        -- witness selected one layer. It cannot break a tie between layers.
        if found then
            local z = Grid.surfaceHeight(st, tile, found, point.x, point.y)
            if (first or Runtime.Sight(map, a.x, a.y, a.z, point.x, point.y, z, pages))
                and (last or Runtime.Sight(map, point.x, point.y, z, b.x, b.y, b.z, pages)) then
                return found
            end
        end
    end
    local surface
    for i = cursor - 1, cursor do
        local a, b = step.path[i], step.path[i + 1]
        if Position(a) and Position(b) then
            local node, ambiguous = legSurface(a, b)
            if ambiguous or (node and surface and node ~= surface) then return end
            surface = node or surface
        end
    end
    return surface and Grid.surfaceHeight(st, tile, surface, point.x, point.y)
end

function Provider:GetWalkingCorridorHeight(point, step)
    return CorridorHeight(self, point, step, false)
end

Provider.GetServiceOriginHeight = Provider.GetWalkingCorridorHeight

local function ResolveHeight(st, cluster, cell, point, tolerance)
    if point.z == nil then
        local z = Grid.uniqueHeight(cluster, cell)
        if z == nil then return nil, true end
        local single = cluster.z[cell] and cell or cluster.layers[cell][1]
        return Grid.surfaceHeight(st, cluster, single, point.x, point.y)
    end
    local node, gap = Grid.endpoint(st, cluster, cell, point.z, point.x, point.y)
    if node and gap <= (tolerance or 10) then
        if node ~= cell and cluster.z[cell]
            and math.abs(Grid.surfaceHeight(st, cluster, cell, point.x, point.y) - point.z) == gap then return nil, true end
        if cluster.layers[cell] then
            for _, layer in ipairs(cluster.layers[cell]) do
                if layer ~= node and math.abs(Grid.surfaceHeight(st, cluster, layer, point.x, point.y) - point.z) == gap then
                    return nil, true
                end
            end
        end
        return Grid.surfaceHeight(st, cluster, node, point.x, point.y)
    end
    return nil, true
end

local function Endpoint(st, point, tolerance)
    local k, cell = Grid.locate(st, point.x, point.y)
    if not k then return nil end
    -- A transport search can revisit the same observed endpoint from many
    -- origins after evicting its grid page. Only cache a completed terrain
    -- observation for this generation. Missing pages remain retryable.
    local key = string.format("%.17g/%.17g/%s/%d", point.x, point.y,
        point.z and string.format("%.17g", point.z) or "", tolerance or 10)
    local cache = st.endpointCache
    if not cache then
        cache = {order = {}, cursor = 1}
        st.endpointCache = cache
    end
    local value = cache[key]
    if value ~= nil then
        if value == false then return nil, true end
        return value
    end
    local cluster = Grid.grid(st, k)
    if not cluster then return nil end
    local height, unresolved = ResolveHeight(st, cluster, cell, point, tolerance)
    if height or unresolved then
        local slot = cache.cursor
        local previous = cache.order[slot]
        if previous then cache[previous] = nil end
        cache[key], cache.order[slot] = height or false, key
        cache.cursor = slot % 256 + 1
    end
    return height, unresolved
end

local function Speed(context, from, to)
    local speed = context.walkSpeed
    if context.flight and context.flight.groundSpeedFor then
        speed = context.flight.groundSpeedFor(from, to)
    elseif context.walkSpeedAt then
        local a, b = context.walkSpeedAt(from), context.walkSpeedAt(to)
        if Finite(a) and Finite(b) then speed = math.min(a, b) end
    elseif context.walkSpeedFor then
        speed = context.walkSpeedFor(from, to)
    end
    if not Finite(speed) or speed <= 0 then speed = context.walkSpeed end
    return Finite(speed) and speed > 0 and speed or 7
end

local function Measure(points, context, factionCosts)
    local yards, seconds, weightedSeconds = 0, 0, nil
    for i = 2, #points do
        Work()
        local a, b = points[i - 1], points[i]
        local dz = Finite(a.z) and Finite(b.z) and b.z - a.z or 0
        local distance = math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + dz ^ 2)
        local duration = distance / Speed(context, a, b)
        yards, seconds = yards + distance, seconds + duration
        if factionCosts then
            local exposure = Runtime.HostileFraction(factionCosts, a, b)
            b.hostileDistance = exposure > 0 and math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2) * exposure or nil
            if b.hostileDistance then points.lastHostileIndex = i end
            b.terrainFaction = context.faction
            weightedSeconds = (weightedSeconds or 0) + Runtime.WithFactionCost(duration, exposure or 0)
        end
    end
    return yards, seconds, weightedSeconds
end

local function Corridor(job, from, to)
    local shared = {}
    for _, field in ipairs({ "uiMapID", "accessKey", "floor", "region" }) do
        Work()
        if from[field] ~= nil and from[field] == to[field] then shared[field] = from[field] end
    end
    local owner = job.owner
    if owner and type(owner.config) == "table" then
        for field, method in pairs({ accessKey = "GetLocationAccessKey", region = "GetPositionRegion" }) do
            Work()
            if owner[method] then
                local a, b = owner[method](owner, from), owner[method](owner, to)
                if a ~= nil and a == b then shared[field] = a end
            end
        end
    end
    return shared
end

local function ExactRoute(job, from, target, refusedApproachAnchors)
    local destinations = job.context.serviceTargets
    local serviceTarget = job.context.serviceWalking and (not destinations or destinations[target])
    local to = Copy(target)
    Work()
    if not Position(from) or not Position(to) or from.instanceID ~= to.instanceID then return "unavailable" end
    local map = job.walkMap or from.instanceID
    local entry = maps[map]
    if not entry then return "unavailable" end
    if not entry.validated then
        if not Whole(entry.data) then return "unavailable" end
        entry.validated = true
    end
    local st = Grid.State(map)
    if not st then return "unavailable" end
    if job.context.walkingGoalXY and job.context.walkingGoal == target and to.z == nil
        and type(to.indoors) == "boolean" then
        local floors = ObservedFloors(st, to, true)
        if #floors ~= 1 then return "unavailable", { unresolvedSurface = true, unresolvedTo = true } end
        to.z = floors[1]
    end
    local start, goal = Copy(from), Copy(to)
    local request = { map = map, from = start, to = goal,
        profile = job.context.faction, style = job.context.style, waterWalking = job.context.waterWalking,
        quick = not job.localApproach and job.context.quick or nil, originTree = job.originTree, rejected = job.rejected,
        refusedApproachAnchors = refusedApproachAnchors,
        observedFromZ = from.z, observedToZ = to.z,
        resolveGoalXY = not not (job.context.walkingGoalXY and job.context.walkingGoal == target),
        serviceTarget = not not serviceTarget, resolveEndpoint = Endpoint }
    if job.context.previewWalking and job.from == job.context.walkingOrigin
        and target == job.to and target == job.context.walkingGoal then request.preview = job end
    -- The local baseline, world cost query and winning segment often request
    -- the same corridor. Cache only geometry and price it for each caller.
    local cache = entry.recentRoutes or {}
    entry.recentRoutes = cache
    local points, reason, refusal
    local geometryVerified = false
    for i = #cache, 1, -1 do
        Work()
        local previous = cache[i]
        local a, b = previous.from, previous.to
        if a.x == start.x and a.y == start.y and previous.observedFromZ == start.z and a.indoors == start.indoors
            and b.x == goal.x and b.y == goal.y and previous.observedToZ == goal.z
            and previous.serviceTarget == request.serviceTarget and previous.resolveGoalXY == request.resolveGoalXY
            and previous.profile == request.profile and previous.style == request.style
            and previous.waterWalking == request.waterWalking and previous.quick == request.quick then
            points, reason, refusal = previous.points, previous.reason, previous.approachPages
            geometryVerified = previous.geometryVerified == true
            start.z, goal.z = a.z, b.z
            if points and not job.targets then
                -- The guidance cursor immediately queries the departure
                -- corridor. A returning itinerary may outlive its grid pages.
                if not Runtime.Sight(request.map, a.x, a.y, a.z, points[2].x, points[2].y, points[2].z, {},nil,nil,
                    geometryVerified and not (points[1].coarseEndpoint or points[2].coarseEndpoint)) then
                    return "unavailable"
                end
            end
            break
        end
    end
    if not points and not reason then
        local fine, path, why, detail = Runtime.SurfaceRoute(request)
        if fine then
            if why == "surface" then
                detail.fineSurface = true
                return "unavailable", detail
            end
            points, reason, refusal = path, why, detail
            if path then
                start.z, goal.z = path[1].z, path[#path].z
                geometryVerified = true
            end
        else
            local fromZ, unresolvedFrom = Endpoint(st, from)
            if from.z == nil then
                -- A fine window can identify the actual departure surface
                -- even when the coarse cell also holds a roof or lower floor.
                local height = Runtime.UniqueSurfaceHeight(st, from)
                if height then
                    start.z = height
                    local supported = Endpoint(st, start)
                    if supported then fromZ, unresolvedFrom = supported, false else start.z = nil end
                end
            end
            local toZ, unresolvedTo = Endpoint(st, to, serviceTarget and 5 or nil)
            if fromZ == nil or toZ == nil then
                if unresolvedFrom or unresolvedTo then
                    local fields = st.data.packed or st.data
                    return "unavailable", {unresolvedSurface = true, unresolvedFrom = unresolvedFrom, unresolvedTo = unresolvedTo,
                        independentFrom = not fields.surface and unresolvedFrom,
                        independentTo = not fields.surface and unresolvedTo}
                end
                return "unavailable"
            end
            start.z, goal.z = start.z or fromZ, serviceTarget and toZ or to.z or toZ
            points, reason, refusal = Runtime.Route(request)
            local fields = st.data.packed or st.data
            if reason == "unreachable" and (fields.clearance or fields.support or fields.surface) then refusal = nil end
        end
        request.originTree, request.rejected, request.preview, request.resolveEndpoint = nil, nil, nil, nil
        request.refusedApproachAnchors = nil
        if (points and #points <= 1024) or reason == "unreachable" then
            local size = points and #points or 1
            entry.routePoints = entry.routePoints or 0
            while #cache >= 128 or entry.routePoints + size > 4096 do
                local old = table.remove(cache, 1)
                entry.routePoints = entry.routePoints - (old.points and #old.points or 1)
            end
            request.points, request.reason = points, reason
            request.geometryVerified = geometryVerified
            if reason == "unreachable" then request.approachPages = refusal end
            cache[#cache + 1] = request
            entry.routePoints = entry.routePoints + size
        end
    end
    if not points then
        if reason == "unverified" then return "unavailable", {unverifiedGeometry = refusal or "unknown"} end
        if reason == "unreachable" and refusal then return "no_path", {approachPages = refusal} end
        return reason == "unreachable" and "no_path" or "unavailable"
    end
    local corridor = Corridor(job, from, to)
    local path = {}
    local phase = map == job.phase and job.phase or nil
    for index, point in ipairs(points) do
        Work()
        local location = {x = point.x, y = point.y, z = point.z, instanceID = from.instanceID, terrainPhase = phase}
        for key, value in pairs(corridor) do Work(); location[key] = value end
        path[index] = location
    end
    path[1], path[#path] = Copy(from), Copy(to)
    path[1].z, path[#path].z = start.z, goal.z
    if phase then path[1].terrainPhase, path[#path].terrainPhase = phase, phase end
    path[1].coarseEndpoint = points[1].coarseEndpoint
    path[#path].coarseEndpoint = points[#points].coarseEndpoint
    if geometryVerified and job.from.z == nil and from.z ~= nil then
        -- A height inferred from an earlier corridor can select a path, but
        -- it cannot disambiguate this attestation without a unique fine floor.
        local unique = Grid.surfacePage(st, from.x, from.y, true) and GuidanceHeight(map, from)
        geometryVerified = unique ~= nil and math.abs(unique - start.z) < .01
    end
    if geometryVerified then
        for _,point in ipairs(path) do Work(); point.geometryVerified=true end
    end
    local costs = Runtime.FactionCostContext(st, job.context.faction, true)
    local yards, seconds, weightedSeconds = Measure(path, job.context, costs)
    return "ready", { path = path, yards = yards, seconds = seconds, weightedSeconds = weightedSeconds,
        geometryVerified = geometryVerified }
end

local function SameApproachAccess(job, from, goal, point)
    local owner = job.owner
    if job.context.walkingGoalApproach and owner.GetRemappedMapID
        and owner:GetRemappedMapID(point.uiMapID, point.instanceID, point.x, point.y, point.z) ~= goal.uiMapID then
        return false
    end
    if owner.config and owner.GetLocationAccessKey then
        point.accessKey = nil
        point.accessKey = owner:GetLocationAccessKey(point)
        if point.accessKey ~= owner:GetLocationAccessKey(goal) then return false end
    elseif goal.accessKey then return false end
    return not owner.config or not owner.CanWalk or owner:CanWalk(from, point)
end

local function PreviewDeparture(job, from, entry)
    local to, owner = job.to, job.owner
    if not entry or not Position(to) or from.instanceID ~= to.instanceID
        or not (owner.config and owner.CanWalk and owner.GetRemappedMapID) or owner:CanWalk(from, to) ~= true then return end

    local dx, dy = to.x - from.x, to.y - from.y
    local distance = math.sqrt(dx * dx + dy * dy)
    -- Reading the local corridor only needs enough metadata to decode the
    -- touched pages. The full job still validates the rest of the pack.
    if distance < 20 or not (entry.validated or Metadata(entry.data)) then return end
    local map = job.walkMap or from.instanceID
    local st = Grid.State(map)
    local height, surface = Runtime.PreviewHeight(st, from, Endpoint)
    if not height then return end
    local start = Copy(from)
    start.z = surface and height or from.z or height
    local direction = math.atan2(dy, dx)
    local size = math.min(28, distance / 2)
    local terrain = {}
    local factionCosts = Runtime.FactionCostContext(st, job.context.faction, true)
    terrain.land, terrain.water = Runtime.Prices({profile = job.context.faction, style = job.context.style,
        waterWalking = job.context.waterWalking}, st.data.swim)
    local function test(length, angle)
        Work()
        local point = Copy(from)
        point.x, point.y, point.z = from.x + length * math.cos(angle), from.y + length * math.sin(angle), nil
        local z, destinationSurface = Runtime.PreviewHeight(st, point, Endpoint)
        if not z or destinationSurface ~= surface then return end
        point.z = z
        point.accessKey, point.region = nil, nil
        point.uiMapID = owner:GetRemappedMapID(from.uiMapID, from.instanceID, point.x, point.y, z)
        if point.uiMapID ~= from.uiMapID or not SameApproachAccess(job, from, from, point) then return end
        if factionCosts and Runtime.HostileFraction(factionCosts, start, point) > 0 then return end
        if Runtime.Sight(map, start.x, start.y, start.z, point.x, point.y, point.z,
            terrain, 1, true, surface ~= nil) ~= true then return end
        start.geometryVerified, point.geometryVerified = surface and true, surface and true
        point.region = from.region
        return point
    end
    for _, length in ipairs({size, math.min(size, 12)}) do
        for _, turn in ipairs({0, 1, -1, 2, -2}) do
            local point = test(length, direction + turn * math.pi / 6)
            if point then
                -- This corridor is only the first metres of movement. The
                -- normal path search still proves the entire route to the pin.
                job.walkingPreview = {{path = {start, point}, departure = true}}
                coroutine.yield()
                return
            end
        end
    end
end

local function RangeRoute(job, from, goal, radius,nativeOnly, nearbyOnly)
    local map = job.walkMap or goal.instanceID
    local st = Grid.State(map)
    if not st then return end
    local startWindow=Grid.surfacePage(st,from.x,from.y,true)
    if startWindow and goal.x+radius>=startWindow.xmin and goal.x-radius<=startWindow.xmax
        and goal.y+radius>=startWindow.ymin and goal.y-radius<=startWindow.ymax then
        local function at(node)
            local point=Copy(goal)
            point.x,point.y,point.z=node.x,node.y,node.z
            return point
        end
        local stop=Runtime.SurfaceApproach(map,from,goal,function(node)
            return SameApproachAccess(job,from,goal,at(node))
        end,radius)
        if stop then
            local status,route=ExactRoute(job,from,at(stop))
            if status=="ready" and route.geometryVerified then return route end
        end
    end
    if nativeOnly then return end
    local unit = st.unit
    local dx, dy = from.x - goal.x, from.y - goal.y
    local length = math.sqrt(dx * dx + dy * dy)
    local fraction = length > 0 and math.min(1, math.max(0, radius - unit / 2) / length) or 0
    local x = math.floor((goal.x + fraction * dx - st.x0) / unit)
    local y = math.floor((goal.y + fraction * dy - st.y0) / unit)
    local nx, ny = st.data.nx * st.c, st.data.ny * st.c
    local last = nearbyOnly and 1 or math.min(math.ceil(2 * radius / unit), math.max(nx, ny))
    local function candidate(ix, iy)
        Work()
        if ix < 0 or iy < 0 or ix >= nx or iy >= ny then return end
        local px = st.x0 + (ix + 0.5) * unit
        local py = st.y0 + (iy + 0.5) * unit
        if (px - goal.x)^2 + (py - goal.y)^2 >= radius^2 then
            -- A small circle can intersect an adjacent cell without enclosing
            -- its centre. Sample just inside the intersecting cell.
            local inset = unit * 0.499999
            px = math.max(px - inset, math.min(px + inset, goal.x))
            py = math.max(py - inset, math.min(py + inset, goal.y))
            if (px - goal.x)^2 + (py - goal.y)^2 >= radius^2 then return end
        end
        local point = Copy(goal)
        point.x, point.y = px, py
        if not SameApproachAccess(job, from, goal, point) then return end
        local state, result = ExactRoute(job, from, point)
        if state == "ready" then return result end
    end
    for ring = 0, last do
        for dx = -ring, ring do
            local result = candidate(x + dx, y - ring)
            if not result and ring > 0 then result = candidate(x + dx, y + ring) end
            if result then return result end
        end
        for dy = 1 - ring, ring - 1 do
            local result = candidate(x - ring, y + dy) or candidate(x + ring, y + dy)
            if result then return result end
        end
    end
end

-- A free map marker may be placed on a face where the character cannot
-- stand. Search outward in world space. The first feasible sample in a
-- ring bounds every later sample by its remaining horizontal distance.
local function PartialRoute(job, from, goal, requireUniqueSurface)
    local map = job.walkMap or goal.instanceID
    local st = Grid.State(map)
    if not st then return end
    local z = Endpoint(st, from)
    if not z then return end
    local start = Copy(from)
    start.z = from.z or z
    local height = Endpoint(st, goal)
    local unit = st.unit
    local function distance(x, y, h)
        return (x-goal.x)^2 + (y-goal.y)^2 + (height and (h-height)^2 or 0)
    end
    local radius = job.context.walkingGoalApproach
    local best = math.min(distance(start.x, start.y, start.z), radius and radius^2 or math.huge)
    job.originTree = job.originTree or {}
    local sourceKey, reachable, exits = Runtime.ApproachOrigin({map = map, from = start,
        profile = job.context.faction, style = job.context.style, waterWalking = job.context.waterWalking,
        originTree = job.originTree})
    local gx = math.floor((goal.x - st.x0) / unit)
    local gy = math.floor((goal.y - st.y0) / unit)
    local nx, ny = st.data.nx * st.c, st.data.ny * st.c
    local limit = math.ceil(math.sqrt(best) / unit) + 1
    if not radius then limit = math.min(limit, 6) end
    local selected, candidates
    local refusedApproachAnchors = {}
    local goalKey = Grid.locate(st, goal.x, goal.y)
    local localOnly = sourceKey == goalKey
    local function collect(ix, iy)
        Work()
        if ix < 0 or ix >= nx or iy < 0 or iy >= ny then return end
        local key = math.floor(ix / st.c) * st.data.ny + math.floor(iy / st.c)
        if (localOnly or not exits) and key ~= sourceKey then return end
        local tile = Grid.grid(st, key)
        if not tile then return end
        local cell = ix % st.c * st.c + iy % st.c
        local layers = tile.layers[cell]
        for i = 0, layers and #layers or 0 do
            Work()
            local node = i == 0 and cell or layers[i]
            local rejected = job.rejected[key]
            if tile.z[node] and ((not localOnly and exits) or reachable[node]) and not (rejected and rejected[node]) then
                local fan = Grid.fan(tile, node)
                -- Four interior triangle samples avoid treating a shared
                -- steep vertex as a place to stop. Ordinary walkable cells
                -- retain the centre certified by the navigation graph.
                for side = 1, fan and 4 or 1 do
                    local u, v = 0, 0
                    if fan then
                        if side == 1 then u = 1/3 elseif side == 2 then u = -1/3
                        elseif side == 3 then v = 1/3 else v = -1/3 end
                    end
                    local safe = true
                    if fan then
                        local a, b = Grid.gradient(fan, u, v)
                        local sub = math.floor((u+.5)*4)*4 + math.floor((v+.5)*4)
                        safe = math.sqrt(a*a+b*b) + .1 <= math.tan(math.rad(50))*unit
                            and math.floor(fan.occupied / 2^sub) % 2 == 0
                    elseif tile.clearance and tile.clearance[node] == 65535 then
                        local offset = tile.subclearance and tile.subclearance[node]
                        safe = offset and Grid.submask(tile, offset, 10) == 0
                    end
                    if safe then
                        local x, y = st.x0 + (ix+.5+u)*unit, st.y0 + (iy+.5+v)*unit
                        local h = fan and Grid.fanHeight(fan, u, v) or tile.z[node]
                        local score = distance(x, y, h)
                        if score < best then
                            candidates[#candidates+1] = {x=x, y=y, z=h, score=score, key=key, node=node}
                        end
                    end
                end
            end
        end
    end
    local function explore(ringLimit)
        candidates = {}
        local xmin, xmax, ymin, ymax = -gx, nx-1-gx, -gy, ny-1-gy
        if localOnly or not exits then
            xmin = math.floor(sourceKey / st.data.ny) * st.c - gx
            ymin = sourceKey % st.data.ny * st.c - gy
            xmax, ymax = xmin + st.c - 1, ymin + st.c - 1
            ringLimit = math.min(ringLimit, math.max(-xmin, xmax, -ymin, ymax))
        end
        for ring = math.max(0, xmin, -xmax, ymin, -ymax), ringLimit do
            if ring > 0 and ((ring-1)*unit)^2 >= best then break end
            for dx = math.max(-ring, xmin), math.min(ring, xmax) do
                if -ring >= ymin and -ring <= ymax then collect(gx+dx, gy-ring) end
                if ring > 0 and ring >= ymin and ring <= ymax then collect(gx+dx, gy+ring) end
            end
            for dy = math.max(1-ring, ymin), math.min(ring-1, ymax) do
                if -ring >= xmin and -ring <= xmax then collect(gx-ring, gy+dy) end
                if ring >= xmin and ring <= xmax then collect(gx+ring, gy+dy) end
            end
            table.sort(candidates, function(a, b)
                if a.score ~= b.score then return a.score < b.score end
                if a.x ~= b.x then return a.x < b.x end
                if a.y ~= b.y then return a.y < b.y end
                return a.z < b.z
            end)
            local pending = {}
            -- A later ring can contain a closer sample than the opposite
            -- corner of this ring. Defer the costly path until all closer
            -- horizontal candidates have been visited.
            local boundary = ring == ringLimit and math.huge or (ring * unit)^2
            for _, candidate in ipairs(candidates) do
                Work()
                local rejected = job.rejected[candidate.key]
                if candidate.score >= best then break end
                if candidate.score >= boundary then
                    pending[#pending + 1] = candidate
                elseif not (rejected and rejected[candidate.node]) then
                    local point = Copy(goal)
                    point.x, point.y = candidate.x, candidate.y
                    local surface = requireUniqueSurface and Endpoint(st, point)
                    point.z = candidate.z
                    if (not requireUniqueSurface or surface and math.abs(surface - point.z) <= 1.05)
                        and SameApproachAccess(job, start, goal, point) then
                        job.localApproach = localOnly
                        -- The coarse height helps enumerate candidates. Only
                        -- the original departure can establish its fine floor.
                        local status, result = ExactRoute(job, from, point, refusedApproachAnchors)
                        if status == "ready" then
                            selected, best = result, candidate.score
                            return
                        end
                    end
                end
            end
            candidates = pending
        end
    end
    -- A nearby stop in the observed departure tree already has a directed
    -- witness. Avoid tracing disconnected destination islands through the
    -- continental graph when this local approach is available.
    if localOnly and exits then
        explore(math.min(limit, 8))
        localOnly = false
    end
    if not selected then explore(limit) end
    if selected then
        local last = selected.path[#selected.path]
        selected.partial, selected.goal, selected.approach = true, Copy(goal), Copy(last)
        selected.remainingYards = math.sqrt((last.x-goal.x)^2 + (last.y-goal.y)^2)
        selected.remainingHeight = height and height-last.z
    end
    return selected
end

local function DifferentWalkingRegion(job, from, target)
    return job.context.enforceWalkingRegion and (from.region and target.region and from.region ~= target.region
        or from.accessKey and target.accessKey and from.accessKey ~= target.accessKey
        or from.floor and target.floor and from.floor ~= target.floor)
end

local function GroundRouteOnMap(job, from, target)
    if Position(from) and Position(target) and DifferentWalkingRegion(job, from, target) then return "no_path" end
    local map = job.walkMap or (Position(target) and target.instanceID)
    local entry = maps[map]
    local radius=job.context.walkingGoalRange
    if target == job.context.walkingGoal and Position(from) and Position(target)
        and from.instanceID == target.instanceID and from.indoors == true and from.z == nil
        and (target.z ~= nil or job.context.walkingPartialGoal and job.context.walkingGoalXY)
        and (from.x - target.x)^2 + (from.y - target.y)^2 <= 50 ^ 2
        and entry and (entry.validated or Whole(entry.data)) then
        local yards = SharedFloorChord(map, from, target, job.context.faction, true)
        if yards then
            local finish = Copy(target)
            finish.sharedFloorChord = true
            return "ready", {path = {Copy(from), finish}, yards = yards, seconds = yards / Speed(job.context, from, target)}
        end
    end
    if job.context.walkingGoalPreferRange and target == job.context.walkingGoal and Position(from) and Position(target)
        and from.instanceID == target.instanceID and target.z == nil and target.floor == nil and Finite(radius) and radius > 0
        and (from.x - target.x)^2 + (from.y - target.y)^2 <= (radius + 60)^2
        and entry and (entry.validated or Whole(entry.data)) then
        local approach = RangeRoute(job, from, target, radius, false, true)
        if approach then return "ready", approach end
    end
    if target==job.context.walkingGoal and Position(from) and Position(target) and from.instanceID==target.instanceID
        and target.z==nil and target.floor==nil and Finite(radius) and radius>0
        and entry and (entry.validated or Whole(entry.data))
        and Runtime.StackedSurfaceGoal(map,from,target) then
        local approach=RangeRoute(job,from,target,radius,true)
        if approach then return "ready",approach end
    end
    local state, result = ExactRoute(job, from, target)
    if result and result.unresolvedFrom then
        local floors
        local st = Grid.State(map)
        if from.z == nil and type(from.indoors) == "boolean" then
            floors = ObservedFloors(st, from, true)
            if #floors == 1 then
                local observed = Copy(from)
                observed.z = floors[1]
                return GroundRouteOnMap(job, observed, target)
            end
            result.ambiguousFrom = #floors > 1
        end
        if from.z == nil and (not floors or #floors == 0)
            and not Endpoint(st, from) and not Runtime.UniqueSurfaceHeight(st, from) then
            result.independentFrom = true
        end
        return state, result
    end
    if state == "ready" or job.context.walkingGoal ~= target or not Position(target) or target.z ~= nil then
        return state, result
    end
    local unresolved = result and result.unresolvedTo and not result.unresolvedFrom
    if Finite(radius) and radius > 0 and target.floor == nil and (state == "no_path" or unresolved
        or result and result.unverifiedGeometry) then
        local access = RangeRoute(job, from, target, radius)
        if access then return "ready", access end
    end
    if job.context.walkingGoalXY and unresolved and not result.fineSurface and type(target.indoors) ~= "boolean" then
        local st = Grid.State(map)
        local key, cell = Grid.locate(st, target.x, target.y)
        local tile = Grid.grid(st, key)
        local layers, reachable = tile.layers[cell]
        for i = 0, layers and #layers or 0 do
            Work()
            local z = Grid.surfaceHeight(st, tile, i == 0 and cell or layers[i], target.x, target.y)
            if z then
                local point = Copy(target)
                point.z = z
                local status, route = ExactRoute(job, from, point)
                if status == "ready" then
                    if reachable then
                        -- An XY pin cannot select between two reachable floors.
                        -- A bounded approach can still offer a reachable stop.
                        if job.context.walkingGoalApproach then
                            local approach = PartialRoute(job, from, target, true)
                            if approach then return "ready", approach end
                        end
                        return state, result
                    end
                    reachable = route
                elseif status ~= "no_path" then
                    return state, result
                end
            end
        end
        if reachable then return "ready", reachable end
        -- Every represented surface was ruled out (or the loaded cell
        -- contains no surface). A manual marker may still have an approach.
        if job.rejected then state = "no_path" end
    end
    if job.rejected and (state == "no_path" or result and (result.dryApproach or result.wetFloor or result.unverifiedGeometry)) then
        local approachRadius = job.context.walkingGoalApproach
        local function candidate(node)
            local point=Copy(target)
            point.x,point.y,point.z=node.x,node.y,node.z
            return point
        end
        local stopping = Runtime.SurfaceApproach(map,from,target,function(node)
            return (not result or result.dryApproach or not result.wetFloor or math.abs(result.wetFloor-node.z)<=1.05)
                and SameApproachAccess(job,from,target,candidate(node))
        end, approachRadius)
        if stopping then
            local status,approach=ExactRoute(job,from,candidate(stopping))
            if status=="ready" and approach.geometryVerified
                and (not approachRadius or (stopping.x-target.x)^2+(stopping.y-target.y)^2 < approachRadius^2) then
                local last=approach.path[#approach.path]
                approach.partial,approach.goal,approach.approach=true,Copy(target),Copy(last)
                approach.remainingYards=math.sqrt((last.x-target.x)^2+(last.y-target.y)^2)
                return approachRadius and "ready" or "partial",approach
            end
        end
    end
    if state == "no_path" and job.rejected then
        local partial = PartialRoute(job, from, target)
        if partial then return job.context.walkingGoalApproach and "ready" or "partial", partial end
    end
    return state, result
end

-- The phase WDT replaces one tile in the parent world. Its outer cells
-- overlap the base grid, so a crossing can join two independently proven
-- corridors at a shared surface without changing the displayed world.
local function PhaseCrossings(world, phase)
    local entry = maps[phase]
    local stored = entry.phaseCrossings
    if stored and stored.world == world and stored.generation == generation then return stored.points end
    local st, base = Grid.State(phase), Grid.State(world)
    if not st or not base or st.data.nx ~= 1 or st.data.ny ~= 1 then return {} end
    local cells, points = st.c, {}
    for side = 1, 4 do
        local dx = side == 1 and -1 or side == 2 and 1 or 0
        local dy = side == 3 and -1 or side == 4 and 1 or 0
        for i = 0, cells - 1, math.max(1, math.floor(cells / 32)) do
            Work()
            local ix = dx < 0 and 0 or dx > 0 and cells - 1 or i
            local iy = dy < 0 and 0 or dy > 0 and cells - 1 or i
            local x, y = Grid.position(st, 0, ix * cells + iy)
            local point = { x = x, y = y, instanceID = world, phaseBoundary = true }
            local z, baseZ = Endpoint(st, point), Endpoint(base, point)
            if z and baseZ and math.abs(z - baseZ) <= 0.5 then
                local ox, oy = x + dx * st.unit, y + dy * st.unit
                local outerZ = Endpoint(base, { x = ox, y = oy })
                if outerZ then
                    local entryClear = Runtime.Sight(world, ox, oy, outerZ, x, y, z, {})
                    local exitClear = Runtime.Sight(world, x, y, z, ox, oy, outerZ, {})
                    if entryClear or exitClear then
                        point.z, point.terrainPhase = z, phase
                        local outside = { x = ox, y = oy, z = outerZ, instanceID = world }
                        points[#points + 1] = { inside = point, outside = outside,
                            enter = entryClear, leave = exitClear }
                    end
                end
            end
        end
    end
    entry.phaseCrossings = { world = world, points = points, generation = generation }
    return points
end

local PLANE_AXES = { "x", "y" }

local function IntersectsPhase(st, a, b)
    local size = st.c * st.unit
    local first, last = 0, 1
    for _, axis in ipairs(PLANE_AXES) do
        local origin = axis == "x" and st.x0 or st.y0
        local delta = b[axis] - a[axis]
        if delta == 0 then
            if a[axis] < origin or a[axis] >= origin + size then return false end
        else
            local u, v = (origin - a[axis]) / delta, (origin + size - a[axis]) / delta
            first, last = math.max(first, math.min(u, v)), math.min(last, math.max(u, v))
            if first >= last then return false end
        end
    end
    return true
end

local function StaysOutside(st, result)
    local path = result.path
    for i = 2, #path do
        Work()
        if IntersectsPhase(st, path[i - 1], path[i]) then return false end
    end
    return true
end

local function AppendWalkingPath(path, leg)
    for _, point in ipairs(leg) do
        Work()
        local last = path[#path]
        if not last or last.x ~= point.x or last.y ~= point.y or last.z ~= point.z then
            path[#path + 1] = point
        elseif point.phaseBoundary or point.mandatory then
            path[#path] = point
        end
    end
end

local function CrossPhase(job, from, target, firstMap, lastMap)
    if DifferentWalkingRegion(job, from, target) then return "no_path" end
    local entering = lastMap == job.phase
    local st = Grid.State(job.phase)
    local ranked = {}
    for i, crossing in ipairs(PhaseCrossings(from.instanceID, job.phase)) do
        Work()
        if (entering and crossing.enter) or (not entering and crossing.leave) then
            local p = crossing.inside
            local x, y = p.x, p.y
            ranked[#ranked + 1] = { crossing = crossing, index = i,
                yards = math.sqrt((from.x - x)^2 + (from.y - y)^2)
                    + math.sqrt((target.x - x)^2 + (target.y - y)^2) }
        end
    end
    table.sort(ranked, function(a, b)
        if a.yards == b.yards then return a.index < b.index end
        return a.yards < b.yards
    end)
    local tree, rejected = job.originTree, job.rejected
    local firstTree = tree or {}
    local finalState, finalResult = "no_path", nil
    for _, candidate in ipairs(ranked) do
        Work()
        local crossing = candidate.crossing
        local inside, outside = Copy(crossing.inside), Copy(crossing.outside)
        local exit, entry = entering and outside or inside, entering and inside or outside
        exit.uiMapID, entry.uiMapID = from.uiMapID, target.uiMapID
        exit.region, entry.region = from.region, target.region
        exit.mandatory, entry.mandatory = true, true
        job.walkMap, job.originTree, job.rejected = firstMap, firstTree, nil
        local state, first = GroundRouteOnMap(job, from, exit)
        if first and first.independentFrom then
            finalState, finalResult = state, first
            break
        end
        if state == "ready" and not first.partial and (not entering or StaysOutside(st, first)) then
            job.walkMap, job.originTree, job.rejected = lastMap, nil, not job.targets and {} or nil
            local status, last = GroundRouteOnMap(job, entry, target)
            if last and last.independentTo then
                finalState, finalResult = status, last
                break
            end
            if (status == "ready" or status == "partial") and (entering or StaysOutside(st, last)) then
                local path = {}
                -- The seam must be reached before steering considers a
                -- chord into the other tile.
                AppendWalkingPath(path, first.path)
                AppendWalkingPath(path, last.path)
                local yards, seconds = Measure({exit, entry}, job.context)
                last.path, last.yards = path, first.yards + yards + last.yards
                last.seconds = first.seconds + seconds + last.seconds
                last.geometryVerified = false
                if status == "ready" then
                    finalState, finalResult = status, last
                    break
                end
                if not finalResult or last.remainingYards < finalResult.remainingYards then
                    finalState, finalResult = status, last
                end
            end
        end
    end
    job.walkMap, job.originTree, job.rejected = nil, tree, rejected
    if finalResult then finalResult.approachPages = nil end
    return finalState, finalResult
end

local function GroundRoute(job, from, target)
    if not job.phase or not Position(from) or not Position(target) or from.instanceID ~= target.instanceID then
        return GroundRouteOnMap(job, from, target)
    end
    local first, last = TerrainMap(from, job.phase), TerrainMap(target, job.phase)
    if first ~= last then return CrossPhase(job, from, target, first, last) end
    if first == from.instanceID then return GroundRouteOnMap(job, from, target) end
    local tree = job.originTree
    job.walkMap, job.originTree = first, nil
    local status, result = GroundRouteOnMap(job, from, target)
    job.walkMap, job.originTree = nil, tree
    if result then result.approachPages = nil end
    return status, result
end

local FLIGHT_CLEARANCE = 12
local FLIGHT_TAKEOFF_SECONDS = 2
local AIRBORNE_CLEARANCE = 30
local FLIGHT_SURFACE_TOLERANCE = 8
local FLIGHT_SAMPLE_SPACING = 20
local MAX_FLIGHT_SAMPLES = 768
local FLIGHT_DETOURS = { 0, 0.15, -0.15, 0.30, -0.30 }

-- Walking data can have several surfaces in one column. The highest one
-- represents the obstacle for an overflight, including roofs and bridges.
local function FlightHeight(st, x, y, outdoorOnly, phase)
    local phased = phase and Grid.State(phase)
    if phased and Grid.locate(phased, x, y) then st = phased end
    local key, cell = Grid.locate(st, x, y)
    local tile = key and Grid.grid(st, key)
    if not tile then return end
    local height, highest = Grid.surfaceHeight(st, tile, cell, x, y), cell
    for _, node in ipairs(tile.layers[cell] or {}) do
        Work()
        local z = Grid.surfaceHeight(st, tile, node, x, y)
        if z and (not height or z > height) then height, highest = z, node end
    end
    if outdoorOnly then
        local class = (tile.class[highest] or 0) % 8
        if class == 4 or class == 5 then return end
    end
    return height
end

local function FlightPeak(st, from, to, length, phase)
    local count = math.ceil(length / FLIGHT_SAMPLE_SPACING)
    if count > MAX_FLIGHT_SAMPLES then return end
    local peak = -math.huge
    for i = 1, count do
        Work()
        local t = i / count
        local height = FlightHeight(st, from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t, nil, phase)
        if not height then return end
        peak = math.max(peak, height)
    end
    return peak
end

local function FlightEndpoint(point)
    return not (point.indoors or point.isInstance or point.floor or point.accessKey or point.noAutoconnect)
end

function Provider:GetFlightWalkingLowerBound(from, to, flight, distance)
    if
        self.owner.profile ~= "retail"
        or not flight.groundSpeedFor
        or not Finite(flight.groundSpeedCeiling)
        or flight.groundSpeedCeiling <= 0
        or not Finite(flight.speed)
        or flight.speed <= 0
    then
        return
    end
    local ground = distance / flight.groundSpeedCeiling
    -- Flight and the mixed ground/air routes all require an eligible destination.
    if not FlightEndpoint(to) then return ground end
    local takeoff = from == flight.origin and flight.airborne and 0 or FLIGHT_TAKEOFF_SECONDS
    return math.min(ground, distance / math.max(flight.speed, flight.groundSpeedCeiling) + takeoff)
end

local function FlightRoute(job, from, to)
    local flight = job.context.flight
    if not flight or not Position(from) or not Position(to) or from.instanceID ~= to.instanceID
        or (from.region and to.region and from.region ~= to.region)
        or not FlightEndpoint(from) or not FlightEndpoint(to) or not flight.canFly(from, to) then return end
    local dx, dy = to.x - from.x, to.y - from.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance == 0 then return end
    local liveDeparture = job.from == flight.origin
    local airborne = liveDeparture and flight.airborne
    local takeoff = airborne and 0 or FLIGHT_TAKEOFF_SECONDS
    local start, goal = Copy(from), Copy(to)
    start.z, goal.z = nil, nil
    local entry = maps[from.instanceID]
    local st
    if entry and (entry.validated or Whole(entry.data)) then
        entry.validated = true
        st = Grid.State(from.instanceID)
    end
    local ground = st and FlightHeight(st, from.x, from.y, nil, job.phase)
    local landing = st and FlightHeight(st, to.x, to.y, nil, job.phase)
    if not liveDeparture and from.z and (not ground or math.abs(from.z - ground) > FLIGHT_SURFACE_TOLERANCE) then
        return
    end
    if to.z and (not landing or math.abs(to.z - landing) > FLIGHT_SURFACE_TOLERANCE) then
        -- A covered passage needs a landing at its mouth and a proved ground
        -- corridor to the actual world transition below the roof.
        local entrances = job.context.flightEntrances
        if entrances and entrances[to] and landing and to.z < landing then return nil, st end
        return
    end

    local best, reference
    if ground and landing then
        reference = ground
        if airborne then
            local total, count = ground, 1
            for i = 1, 4 do
                local angle = i * math.pi / 2
                local height = FlightHeight(st, from.x + 30 * math.cos(angle), from.y + 30 * math.sin(angle), nil, job.phase)
                if height then total, count = total + height, count + 1 end
            end
            reference = math.max(ground, total / count) + AIRBORNE_CLEARANCE
        end
        for _, fraction in ipairs(FLIGHT_DETOURS) do
            local path, yards = { start, goal }, distance
            local offset = math.min(math.abs(fraction) * distance, 500) * (fraction < 0 and -1 or 1)
            if offset ~= 0 then
                local bend = { x = from.x + dx / 2 - dy / distance * offset,
                    y = from.y + dy / 2 + dx / distance * offset, instanceID = from.instanceID }
                if from.uiMapID == to.uiMapID then bend.uiMapID = from.uiMapID end
                path = { start, bend, goal }
                yards = 2 * math.sqrt(distance ^ 2 / 4 + offset ^ 2)
            end
            local travel = takeoff + yards / flight.speed
            if not best or travel < best.seconds then
                local a = FlightPeak(st, path[1], path[2], yards / (#path - 1), job.phase)
                local b = a
                if a and #path == 3 then b = FlightPeak(st, path[2], path[3], yards / 2, job.phase) end
                if a and b then
                    local climb = math.max(0, math.max(a, b) + FLIGHT_CLEARANCE - reference)
                    local seconds = travel + climb / flight.climbSpeed
                    if not best or seconds < best.seconds then
                        path.flight = { speed = flight.speed, climb = climb, referenceHeight = reference }
                        best = { path = path, yards = yards, seconds = seconds }
                    end
                end
            end
        end
    end
    if best then return best end
    -- Incomplete coverage still permits the authorized direct flight estimate.
    local path = { start, goal, flight = { speed = flight.speed, estimated = true } }
    return { path = path, yards = distance, seconds = takeoff + distance / flight.speed }
end

local function FlyToCoveredEntrance(job, from, target, st)
    local groundStart = from
    local airborne = job.from == job.context.flight.origin and job.context.flight.airborne
    if airborne then
        -- Find the ground approach from a surface even during an airborne replan.
        groundStart = Copy(from)
        groundStart.z = nil
    end
    local preview = job.context.previewWalking
    job.context.previewWalking = nil
    local status, ground = GroundRoute(job, groundStart, target)
    job.context.previewWalking = preview
    if status ~= "ready" or ground.partial then return status, ground end

    local path, landing, nextIndex = ground.path
    local spacing = math.min(st.unit / 2, FLIGHT_SAMPLE_SPACING)
    -- Walking geometry can simplify a straight tunnel approach into a single
    -- chord. Look for the open-air end along that chord as well as at bends.
    for index = #path, 2, -1 do
        Work()
        local a, b = path[index - 1], path[index]
        local dx, dy = a.x - b.x, a.y - b.y
        local count = math.ceil(math.sqrt(dx * dx + dy * dy) / spacing)
        if a.z and b.z then
            for sample = 1, count do
                Work()
                local t = sample / count
                local x, y, z = b.x + dx * t, b.y + dy * t, b.z + (a.z - b.z) * t
                local height = FlightHeight(st, x, y, nil, job.phase)
                if height and math.abs(height - z) <= FLIGHT_SURFACE_TOLERANCE then
                    landing, nextIndex = Copy(a), index
                    landing.x, landing.y, landing.z = x, y, z
                    break
                end
            end
        end
        if landing then break end
    end
    local air = landing and FlightRoute(job, from, landing)
    if not air then return status, ground end
    local suffix = { landing }
    for i = nextIndex, #path do
        Work()
        suffix[#suffix + 1] = path[i]
    end
    local yards, seconds = Measure(suffix, job.context)
    if airborne or air.seconds + seconds < ground.seconds then
        air.path.flight.groundPath = suffix
        air.path.flight.groundSeconds = seconds
        air.seconds, air.yards = air.seconds + seconds, air.yards + yards
        return "ready", air
    end
    return status, ground
end

-- After an indoor landing, follow the proven ground corridor to open air.
-- Match its height to the exposed surface so a roof above it cannot be a takeoff point.
local function FlyFromInterior(job, target, ground)
    local path = ground.path
    local st = Grid.State(target.instanceID)
    if not st or not path then return end
    local spacing = math.min(st.unit / 2, FLIGHT_SAMPLE_SPACING)
    local prefix = { path[1] }
    for index = 2, #path do
        Work()
        local from, to = path[index - 1], path[index]
        if Finite(from.z) and Finite(to.z) then
            local dx, dy = to.x - from.x, to.y - from.y
            local count = math.ceil(math.sqrt(dx * dx + dy * dy) / spacing)
            for sample = 1, count do
                Work()
                local t = sample / count
                local x, y, z = from.x + dx * t, from.y + dy * t, from.z + (to.z - from.z) * t
                local height = FlightHeight(st, x, y, true, job.phase)
                if height and math.abs(height - z) <= 2 then
                    local takeoff = Copy(from)
                    takeoff.x, takeoff.y, takeoff.z, takeoff.indoors = x, y, z, false
                    local air = FlightRoute(job, takeoff, target)
                    if not air then return end
                    prefix[#prefix + 1] = takeoff
                    local yards, seconds = Measure(prefix, job.context)
                    if seconds + air.seconds < ground.seconds then
                        air.path.flight.groundBefore = prefix
                        air.path.flight.groundBeforeSeconds = seconds
                        air.seconds, air.yards = air.seconds + seconds, air.yards + yards
                        return air
                    end
                    return
                end
            end
        end
        prefix[#prefix + 1] = to
    end
end

local function Route(job, from, target)
    local flight, covered = FlightRoute(job, from, target)
    if covered then return FlyToCoveredEntrance(job, from, target, covered) end
    if not flight then
        local status, ground = GroundRoute(job, from, target)
        local travel = job.context.flight
        if status == "ready" and not ground.partial and from.indoors == true and FlightEndpoint(target)
            and travel and job.context.flightEntrances and travel.canFly(target, target) then
            return status, FlyFromInterior(job, target, ground) or ground
        end
        return status, ground
    end
    if job.from == job.context.flight.origin and job.context.flight.airborne then return "ready", flight end
    local distance = math.sqrt((target.x - from.x) ^ 2 + (target.y - from.y) ^ 2)
    if flight.seconds <= distance / Speed(job.context, from, target) then return "ready", flight end
    local status, ground = GroundRoute(job, from, target)
    if status == "ready" and not ground.partial and ground.seconds <= flight.seconds then return status, ground end
    return "ready", flight
end

local function Run(job)
    Work()
    if job.context.faction == nil then job.context.faction = WalkingFaction(job.owner) end
    local from = Copy(job.from)
    job.phase = Position(from) and SelectPhase(job.owner, from, job.context.faction) or nil
    local map = Position(from) and TerrainMap(from, job.phase)
    local entry = map and maps[map]
    if entry and map == from.instanceID and job.shareOrigin
        and (not entry.data.portalCostPerYard or job.targets and #job.targets > 1) then
        local stored = entry and entry.originTree
        if stored and stored.faction == job.context.faction and stored.style == job.context.style
            and stored.waterWalking == job.context.waterWalking then
            -- Lease exclusively. A suspended Dijkstra expansion must never be
            -- inspected or mutated by a concurrent request.
            job.originTree, entry.originTree = stored, nil
        else
            job.originTree = {faction = job.context.faction, style = job.context.style,
                waterWalking = job.context.waterWalking}
        end
    end
    if Position(from) and from.z == nil and job.context.walkingOriginCorridor then
        if entry and (entry.validated or Whole(entry.data)) then
            entry.validated = true
            from.z = CorridorHeight(providers[job.owner], from, job.context.walkingOriginCorridor, true)
        end
    end
    if not job.targets then
        local flight = job.context.flight
        if job.context.previewDeparture and not (flight and flight.canFly(from, job.to))
            and (not job.phase or Position(job.to) and TerrainMap(job.to, job.phase) == map) then
            job.walkMap = map
            PreviewDeparture(job, from, entry)
            job.walkMap = nil
        end
        return Route(job, from, job.to)
    end
    local costs = {}
    for i, target in ipairs(job.targets) do
        Work()
        -- Lua 5.1 cannot yield through pcall. A child coroutine isolates malformed
        -- data for this target while forwarding every suspension to caller Step.
        local worker = coroutine.create(function() return Route(job, from, target) end)
        local state, result
        while true do
            local ok
            ok, state, result = coroutine.resume(worker)
            if not ok then
                job.originTree, job.walkMap = nil, nil
                state, result = "unavailable", nil
                break
            end
            if coroutine.status(worker) == "dead" then break end
            coroutine.yield()
        end
        costs[i] = {state = state, unresolvedSurface = result and result.unresolvedSurface,
            independentFrom = result and result.independentFrom, independentTo = result and result.independentTo,
            approachPages = result and result.approachPages,
            unverifiedGeometry = result and result.unverifiedGeometry,
            unresolvedFrom = result and result.unresolvedFrom, unresolvedTo = result and result.unresolvedTo,
            yards = result and result.yards, seconds = result and result.seconds,
            weightedSeconds = result and result.weightedSeconds}
    end
    return "ready", { costs = costs }
end

local function Clock()
    if debugprofilestop then return debugprofilestop() end
    return GetTime and GetTime() * 1000 or 0
end

local function SnapshotCorridor(walk)
    local cursor = walk.pathCursor or 2
    local step = {kind = walk.kind, pathCursor = 2, path = {}}
    for i = 1, 3 do
        local p = walk.path and walk.path[cursor + i - 2]
        if p then step.path[i] = Lib.Copy(p) end
    end
    return step
end

local function NewJob(owner, from, to, targets, context)
    context = context or {}
    local snapshot = { serviceWalking = context.serviceWalking, serviceTargets = context.serviceTargets,
        -- Geometry-only callers may inspect a chord between unlike endpoints.
        -- A navigation objective must use a declared transition instead.
        enforceWalkingRegion = context.walkingGoal ~= nil or context.walkingGoalXY or context.walkingGoalRange
            or context.walkingPartialGoal or context.serviceWalking,
        walkingGoalRange = context.walkingGoalRange, walkingGoalPreferRange = context.walkingGoalPreferRange,
        walkingGoalApproach = context.walkingGoalApproach,
        walkingGoal = context.walkingGoal or to,
        walkingGoalXY = context.walkingGoalXY,
        walkingPartialGoal = context.walkingPartialGoal,
        walkingOrigin = context.walkingOrigin, previewWalking = context.previewWalking,
        previewDeparture = context.previewDeparture == true,
        faction = context.faction, style = context.style, waterWalking = context.waterWalking, walkSpeed = context.walkSpeed,
        walkSpeedFor = context.walkSpeedFor, walkSpeedAt = context.walkSpeedAt, quick = context.quick,
        flight = owner.profile == "retail" and context.flight or nil, flightEntrances = context.flightEntrances }
    local walk = context.walkingOriginCorridor
    if walk and (context.walkingOrigin == from or (not context.walkingOrigin and not targets)) then
        snapshot.walkingOriginCorridor = SnapshotCorridor(walk)
    end
    return setmetatable({ owner = owner, from = from, to = to, targets = targets, context = snapshot,
        originTree = targets and #targets > 1 and {} or nil, shareOrigin = context.shareWalkingOrigin and not context.quick,
        rejected = (context.walkingGoalApproach or context.walkingPartialGoal and not targets)
            and not context.serviceWalking and {} or nil,
        clock = context.clock or Clock, status = "planning", workLastStep = 0, generation = generation,
        co = coroutine.create(Run) }, Job)
end

-- Capture just the adjacent vertices. The live cursor can advance while the
-- caller is paging in terrain; the detached job has its own immutable input.
function Provider:CreateServiceOriginJob(point, walk, clock)
    local job = NewJob(self.owner, point, nil, nil, {clock = clock})
    local step = SnapshotCorridor(walk)
    job.co = coroutine.create(function()
        local entry = maps[TerrainMap(point, SelectPhase(self.owner, point))]
        if not entry or not (entry.validated or Whole(entry.data)) then return "unavailable" end
        entry.validated = true
        return "ready", CorridorHeight(self, point, step, true)
    end)
    return job
end

function Provider:CreatePathJob(from, to, context)
    return NewJob(self.owner, from, to, nil, context)
end

-- A declared same-world boundary is allowed at its own endpoints. Verify its
-- actual chord; a detour elsewhere would not establish this map transition.
function Provider:CreatePassageJob(from, to, context)
    local job = NewJob(self.owner, from, to, nil, context)
    job.co = coroutine.create(function()
        if not self:RequiresWalkingProof(from,to) then return "unavailable" end
        local map = ChordMap(self.owner, from, to)
        local entry = maps[map]
        if not entry then return "unavailable" end
        if not entry.validated and not Whole(entry.data) then return "unavailable" end
        entry.validated = true
        local st = Grid.State(map)
        local a,b = Copy(from),Copy(to)
        local function height(point)
            if Grid.surfacePage(st,point.x,point.y,true) then
                return point.z or Runtime.GuidanceHeight(map,point.x,point.y)
            end
            local z = Endpoint(st,point)
            return z and (point.z or z)
        end
        a.z,b.z = height(a),height(b)
        if not a.z or not b.z then return "unavailable" end
        local clear = Runtime.Sight(map,a.x,a.y,a.z,b.x,b.y,b.z,{})
        if clear == nil then return "unavailable" end
        if clear then return "ready", {path={a,b}} end
        return "no_path"
    end)
    return job
end

function Provider:CreateCostJob(from, targets, context)
    return NewJob(self.owner, from, nil, targets or {}, context)
end

function Provider:CreateWalkingSegmentJob(from, to, context)
    local job = NewJob(self.owner, from, to, nil, context)
    job.co = coroutine.create(function()
        if not Position(from) or not Position(to) or not from.z or not to.z or from.instanceID ~= to.instanceID then
            return "unavailable"
        end
        local map, crosses = ChordMap(self.owner, from, to)
        local entry = maps[map]
        if not entry or not (entry.validated or Whole(entry.data)) then return "unavailable" end
        entry.validated = true
        local clear = Runtime.Sight(map, from.x, from.y, from.z, to.x, to.y, to.z, {},nil,nil,
            not crosses and RequiresNativeChord(from, to))
        if clear == nil then return "unavailable" end
        return clear and "ready" or "no_path"
    end)
    return job
end

function Job:Cancel()
    self.surfacePages=nil
    self.walkingPreview = nil
    self.originTree, self.rejected = nil, nil
    self.status, self.result, self.co = "cancelled", nil, nil
    self.from, self.to, self.targets, self.context, self.owner = nil, nil, nil, nil, nil
end

function Job:Step(maxOperations, milliseconds)
    self.workLastStep = 0
    if self.status ~= "planning" then return self.status, self.result end
    if self.generation ~= generation then
        self.surfacePages=nil
        self.originTree, self.rejected = nil, nil
        self.status, self.co = "unavailable", nil
        self.from, self.to, self.targets, self.context, self.owner = nil, nil, nil, nil, nil
        return self.status
    end
    maxOperations, milliseconds = maxOperations or 100, milliseconds or 1
    if not Finite(maxOperations) or not Finite(milliseconds) or maxOperations < 1 or milliseconds <= 0 then
        return self.status
    end
    self.limit, self.deadline, self.quantum = math.floor(maxOperations), self.clock() + milliseconds, 0
    self.partitionImportedThisStep = false
    local previous = Runtime.active
    Runtime.active = self
    local ok, state, result = coroutine.resume(self.co, self)
    Runtime.active = previous
    if not ok then
        self.status, self.error = "unavailable", state
    elseif coroutine.status(self.co) == "dead" then
        self.status, self.result = state, result
    end
    if self.status ~= "planning" then
        self.surfacePages=nil
        if self.shareOrigin and self.status == "ready" and self.originTree and self.originTree.tile
            and TerrainMap(self.from, self.phase) == self.from.instanceID then
            maps[self.from.instanceID].originTree = self.originTree
        end
        self.originTree, self.rejected = nil, nil
        self.co = nil
        self.from, self.to, self.targets, self.context, self.owner = nil, nil, nil, nil, nil
    end
    return self.status, self.result
end
