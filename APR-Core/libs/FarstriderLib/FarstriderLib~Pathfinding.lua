-- FarstriderLib~Pathfinding.lua
-- Dijkstra shortest-path engine over the waypoint navigation graph.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end

--- Navigation edge categories.
---@enum EdgeType
FarstriderLib.EdgeType = {
    TRAVEL     = 1000, -- Direct overland / dragonriding travel
    FLIGHTPATH = 1001, -- Flight master route
    PORTAL     = 1002, -- Portal (mage portal, world portal, housing)
    BOAT       = 1003, -- Boat transport
    ZEPPELIN   = 1004, -- Zeppelin transport
    ITEM       = 1005, -- Consumable item (hearthstone, wormhole, etc.)
    SPELL      = 1006, -- Player spell (teleport, astral recall, etc.)
}

---@class Pathfinding
---@field allNodes table<NavKey, NavNode>  The full navigation graph
local Pathfinding = {}
FarstriderLib.Pathfinding = Pathfinding

Pathfinding.allNodes = {} ---@type table<NavKey, NavNode>

-- Cached valid travel nodes (invalidated when conditions might change)
Pathfinding._validTravelNodesCache = nil ---@type table<NavKey, NavNode>?
Pathfinding._validTravelNodesCacheTime = 0

--- Invalidate the valid-travel-nodes cache and continent lookup cache.
function Pathfinding:InvalidateCache()
    self._validTravelNodesCache = nil
    self._validTravelNodesCacheTime = 0
    self._continentCache = {}
end

-- Initialize continent cache
Pathfinding._continentCache = {}

--- Return all nodes that have at least one active (condition-passing) edge.
--- Results are cached for 2 seconds to avoid redundant re-evaluation.
---@return table<NavKey, NavNode>
function Pathfinding:GetValidTravelNodes()
    local now = GetTime()
    -- Reuse cache if less than 2 seconds old (conditions don't change between rapid step clicks)
    if self._validTravelNodesCache and (now - self._validTravelNodesCacheTime) < 2 then
        return self._validTravelNodesCache
    end

    local validTravelNodes = {} ---@type table<NavKey, NavNode>
    for _, navNode in pairs(self.allNodes) do
        if self:NodeContainsAnyActiveEdge(navNode) then
            validTravelNodes[navNode.key] = navNode
        end
    end
    self._validTravelNodesCache = validTravelNodes
    self._validTravelNodesCacheTime = now
    return validTravelNodes
end

local TRAVEL_COST_MULTIPLIER = 1 / 55 -- avg dragonriding speed
if WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC then
    TRAVEL_COST_MULTIPLIER = 1 / 31   -- avg 280% flying speed
end

local DIRECT_TRAVEL_COST_MULTIPLIER = TRAVEL_COST_MULTIPLIER * 0.8

local WIZARDS_SANCTUM_AREA_ID = 10523
local WIZARDS_SANCTUM_NAME

local function GetWizardsSanctumName()
    if WIZARDS_SANCTUM_NAME == nil then
        WIZARDS_SANCTUM_NAME = C_Map.GetAreaInfo(WIZARDS_SANCTUM_AREA_ID) or false
    end
    return WIZARDS_SANCTUM_NAME
end

---@param loc Location|NavLocation
---@return number? comparableZ
local function getComparableZ(loc)
    if not loc or not loc.pos then
        return nil
    end

    if loc.pos.z ~= 0 then
        return loc.pos.z
    end

    local overrideZ = FarstriderLib.Data.CONFIG.ElevationOverrides[loc.mapId]
    if overrideZ then
        return overrideZ
    end

    if loc.isUI then
        return nil
    end

    return loc.pos.z
end

--- Count entries in a hash table.
---@param t table
---@return number
function Pathfinding:len(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

---@param mapID number
---@return boolean
function Pathfinding:IsMapIsolated(mapID)
    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then
        FarstriderLib.Logger:Error("Map information not available for ID:", mapID)
        return false
    end

    local mapTypeOverride = FarstriderLib.Data.CONFIG.MapTypeOverrides[mapID]
    if mapTypeOverride then
        mapInfo.mapType = mapTypeOverride.mapType
    end

    if mapInfo.mapType == Enum.UIMapType.Dungeon then
        return true
    end

    return mapInfo.parentMapID == 0
end

--- Compute world distance between two nav locations.
--- Uses the Z component only when both elevations are trustworthy.
--- Returns `math.huge` if they are on disconnected continents.
---@param navLocationA Location|NavLocation
---@param navLocationB Location|NavLocation
---@return number?
function Pathfinding:GetWorldDistanceBetween(navLocationA, navLocationB)
    if not navLocationA or not navLocationB then
        FarstriderLib.Logger:Error("GetWorldDistanceBetween called with nil nav locations")
        return nil
    end

    local canTravelDirectly = self:HasDirectFlyPath(navLocationA, navLocationB)
    if not canTravelDirectly then
        return math.huge
    else
        local _, posA = C_Map.GetWorldPosFromMapPos(navLocationA.mapId,
            CreateVector2D(navLocationA.pos.x, navLocationA.pos.y))
        local _, posB = C_Map.GetWorldPosFromMapPos(navLocationB.mapId,
            CreateVector2D(navLocationB.pos.x, navLocationB.pos.y))

        if posA and posB then
            local comparableZA = getComparableZ(navLocationA)
            local comparableZB = getComparableZ(navLocationB)
            local deltaZ = (comparableZA and comparableZB) and (comparableZA - comparableZB) or 0
            return math.sqrt((posA.x - posB.x) ^ 2 + (posA.y - posB.y) ^ 2 + deltaZ ^ 2)
        else
            FarstriderLib.Logger:Warning("GetWorldDistanceBetween could not resolve world positions for nav locations:",
                navLocationA.mapId, navLocationB.mapId)
            return nil
        end
    end
end

---@param parentMapID number
---@param pos Vec3
---@return number? childMapID
function Pathfinding:GetSubZoneAtPosition(parentMapID, pos)
    local mapInfo = C_Map.GetMapInfoAtPosition(parentMapID, pos.x, pos.y)
    if mapInfo then
        return mapInfo.mapID
    end
    return nil
end

---@param parentMapID number
---@param pos Vec3
---@return number? childMapID
function Pathfinding:GetMostTopLevelSubZoneAtPosition(parentMapID, pos)
    local mapInfo = C_Map.GetMapInfoAtPosition(parentMapID, pos.x, pos.y)
    if not mapInfo then
        -- Nested city/instance maps can fail position lookup; climb their ancestry instead.
        mapInfo = C_Map.GetMapInfo(parentMapID)
    end

    local parentMapInfo = mapInfo and mapInfo.parentMapID and C_Map.GetMapInfo(mapInfo.parentMapID)
    while parentMapInfo and parentMapInfo.mapType > Enum.UIMapType.Continent do
        mapInfo = parentMapInfo
        parentMapInfo = mapInfo.parentMapID and C_Map.GetMapInfo(mapInfo.parentMapID)
    end
    return mapInfo and mapInfo.mapID or nil
end

---@param mapID number
---@return UiMapDetails
function Pathfinding:GetRootMap(mapID)
    local mapInfo = C_Map.GetMapInfo(mapID)
    while mapInfo and mapInfo.parentMapID and mapInfo.parentMapID ~= 0 do
        FarstriderLib.Logger:Info(string.format("Checking parent map: %s (ID: %d)", mapInfo.name, mapInfo.mapID))
        mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    end
    return mapInfo
end

---@param uiMapID UIMapId
---@return UiMapDetails?
function Pathfinding:GetContinentMapRoot(uiMapID)
    if self._continentCache[uiMapID] ~= nil then
        return self._continentCache[uiMapID] or nil
    end

    local mapInfo = C_Map.GetMapInfo(uiMapID)
    while mapInfo and mapInfo.parentMapID and mapInfo.mapType > Enum.UIMapType.Continent do
        mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    end

    if mapInfo then
        local continentMapOverride = FarstriderLib.Data.CONFIG.ContinentMapOverrides[mapInfo.mapID]
        if continentMapOverride then
            mapInfo = C_Map.GetMapInfo(continentMapOverride)
        end
    end

    self._continentCache[uiMapID] = mapInfo or false
    return mapInfo
end

--- Checks whether or not two maps can be traveled between without any teleportation.
---@param loc1 Location|NavLocation
---@param loc2 Location|NavLocation
---@return boolean
function Pathfinding:HasDirectFlyPath(loc1, loc2)
    local uiMapID1 = loc1.mapId
    local uiMapID2 = loc2.mapId

    if (self:IsMapIsolated(uiMapID1) or self:IsMapIsolated(uiMapID2)) and uiMapID1 ~= uiMapID2 then
        return false
    end

    local continentInfoMap1 = self:GetContinentMapRoot(uiMapID1)
    local continentInfoMap2 = self:GetContinentMapRoot(uiMapID2)

    if not continentInfoMap1 or not continentInfoMap2 then
        FarstriderLib.Logger:Error("Could not find continent information for map IDs:", uiMapID1, uiMapID2)
        return false
    end

    if continentInfoMap1.mapID == continentInfoMap2.mapID then
        local isolatedContinents = FarstriderLib.Data.CONFIG.IsolatedContinents
        if isolatedContinents[continentInfoMap1.mapID] then
            local subzone1 = self:GetMostTopLevelSubZoneAtPosition(uiMapID1, loc1.pos) or uiMapID1
            local subzone2 = self:GetMostTopLevelSubZoneAtPosition(uiMapID2, loc2.pos) or uiMapID2
            return subzone1 == subzone2
        end

        local subzone1 = self:GetMostTopLevelSubZoneAtPosition(uiMapID1, loc1.pos) or uiMapID1
        local subzone2 = self:GetMostTopLevelSubZoneAtPosition(uiMapID2, loc2.pos) or uiMapID2
        local isolatedAreas = FarstriderLib.Data.CONFIG.IsolatedAreas
        return isolatedAreas[subzone1] == isolatedAreas[subzone2]
    end

    return false
end

--- Checks whether or not two NavNodes can be traveled between without any teleportation.
---@param navNode1 NavNode
---@param navNode2 NavNode
---@return boolean
function Pathfinding:HasDirectFlyPathForNavs(navNode1, navNode2)
    if not navNode1 or not navNode2 then
        FarstriderLib.Logger:Error("CanTravelBetweenNavs called with nil nav nodes")
        return false
    end

    return self:HasDirectFlyPath(navNode1:getLocation(), navNode2:getLocation())
end

--- Convert a WaypointLocation (world or UI coords) into a NavNode,
--- reusing an existing node from the graph when the key matches.
---@param waypointLocation WaypointLocation
---@param graph table<NavKey, NavNode>
---@param suffix string  Key suffix for dynamic nodes ("from" / "to")
---@return NavNode?
function Pathfinding:ConvertWaypointLocationToNavLocation(waypointLocation, graph, suffix)
    if not waypointLocation.loc then
        local dynamicNode = FarstriderLib.NavNode.createDynamic(waypointLocation.dynLoc, suffix, {})
        return graph[dynamicNode.key] or dynamicNode
    end

    if waypointLocation.loc.isUI then
        local uiNode = FarstriderLib.NavNode.create(waypointLocation.loc.mapId,
            { x = waypointLocation.loc.pos.x, y = waypointLocation.loc.pos.y, z = waypointLocation.loc.pos.z },
            waypointLocation.loc.isUI, {})
        return graph[uiNode.key] or uiNode
    end

    local worldVec = CreateVector2D(waypointLocation.loc.pos.x, waypointLocation.loc.pos.y)
    local uiMapId, localPos = C_Map.GetMapPosFromWorldPos(waypointLocation.loc.mapId, worldVec, waypointLocation.uiMapHint)

    if not uiMapId or not localPos then
        FarstriderLib.Logger:Error(string.format("Could not resolve UIMapId for locaId %d (continent mapId %d)",
            waypointLocation.locaId, waypointLocation.loc.mapId))
        return nil
    end

    local node = FarstriderLib.NavNode.create(uiMapId, { x = localPos.x, y = localPos.y, z = waypointLocation.loc.pos.z },
        true, {})
    return graph[node.key] or node
end

--- Check whether a node has at least one active (usable) edge.
--- Returns true as soon as any non-travel edge passes its condition,
--- or when a travel edge is encountered (always valid).
---@param node NavNode
---@return boolean
function Pathfinding:NodeContainsAnyActiveEdge(node)
    if not node or not node.edges then
        return false
    end

    local ET = FarstriderLib.EdgeType

    for _, edge in ipairs(node.edges) do
        -- Travel edges are auto-added and always valid
        if edge.locaId == ET.TRAVEL then
            return true
        end
        -- At least one transport edge with a passing (or absent) condition
        if not edge.condition or edge.condition() then
            return true
        end
    end

    return false
end

---@param location NavLocation
---@param nodes table<NavKey, NavNode>
---@param isWizardsSanctum? boolean  Source is inside the Wizard's Sanctum
---@return { navNode: NavNode, cost: number }[] connections
function Pathfinding:FindClosestNavConnections(location, nodes, isWizardsSanctum)
    local connections = {}
    FarstriderLib.Logger:Info(string.format("Finding closest nav connections from map %d at position (%.2f, %.2f, %.2f)",
        location.mapId, location.pos.x, location.pos.y, location.pos.z))

    for _, navNode in pairs(nodes) do
        if not navNode.isDynamic and not navNode.noAutoconnect then
            -- Wizard's Sanctum isolation: WS nodes connect only to other WS
            -- nodes and vice-versa.  Mismatched pairs are skipped.
            if (isWizardsSanctum or false) ~= (navNode.wizardsSanctum or false) then
                -- skip
            elseif self:HasDirectFlyPath(location, navNode:getLocation()) then
                local navNodeLoc = navNode:getLocation()
                local dist = self:GetWorldDistanceBetween(location, navNodeLoc)
                if dist and dist ~= math.huge then
                    table.insert(connections, { navNode = navNode, cost = dist * TRAVEL_COST_MULTIPLIER })
                else
                    FarstriderLib.Logger:Warning(string.format("  Could not resolve world position for node %d",
                        navNodeLoc.mapId))
                end
            end
        end
    end

    table.sort(connections, function(a, b) return a.cost < b.cost end)
    FarstriderLib.Logger:Info(string.format("  Found %d valid connections", #connections))
    return connections
end

--- Resolve the localized description for a navigation edge.
---@param locaId number   EdgeType constant or custom locaId
---@param locaArgs? fun(): any[]  Lazy format-string arguments
---@return string
function Pathfinding:GetNodeLoca(locaId, locaArgs)
    local loca = self:GetNodeLocaDirect(locaId)
    if locaArgs then
        loca = string.format(loca, unpack(locaArgs()))
    end
    return loca
end

--- Resolve the raw (unformatted) localized string for a locaId.
---@param locaId number?
---@return string
function Pathfinding:GetNodeLocaDirect(locaId)
    if not locaId then
        return "Unknown Location (no locaId provided)"
    end

    local loca = FarstriderLib.Data.GetLocalizedString(locaId)
    if not loca then
        return "Unknown Location (locaId " .. locaId .. ")"
    end

    return loca
end

--- Create a virtual NavNode at the specified location with edges to the closest NavNodes
---@param location NavLocation
---@param nodes table<NavKey, NavNode>
---@param isWizardsSanctum? boolean  True when the location is inside the Wizard's Sanctum
---@return NavNode
function Pathfinding:CreateVirtualNavNode(location, nodes, isWizardsSanctum)
    local ET = FarstriderLib.EdgeType
    local virtualNode = FarstriderLib.NavNode.create(location.mapId, location.pos, true, {})
    local connections = self:FindClosestNavConnections(location, nodes, isWizardsSanctum)
    local navEdge ---@type NavEdge
    for _, connection in ipairs(connections) do
        navEdge = { from = virtualNode, to = connection.navNode, cost = connection.cost, flag = 0, locaId = ET.TRAVEL, type = 0, important = false }
        table.insert(virtualNode.edges, navEdge)
        navEdge = { from = connection.navNode, to = virtualNode, cost = connection.cost, flag = 0, locaId = ET.TRAVEL, type = 0, important = false }
        table.insert(connection.navNode.tempEdges, navEdge)
    end

    return virtualNode
end

--- Remove all temporary edges from every node in the graph.
function Pathfinding:CleanupTempEdges()
    for _, navNode in pairs(self.allNodes) do
        navNode.tempEdges = {}
    end
end

--- Find the shortest path and return both the nodes and the edges to traverse
---@param startLocation NavLocation
---@param goalLocation NavLocation
---@return table[] optimizedPath, NavNode[] path, NavEdge[] edges
function Pathfinding:FindPathBetweenLocations2(startLocation, goalLocation)
    self:CleanupTempEdges()

    local ET = FarstriderLib.EdgeType

    FarstriderLib.Logger:Info("=== Starting pathfinding ===")
    FarstriderLib.Logger:Info(string.format("Start: map %d (%.2f, %.2f, %.2f)", startLocation.mapId, startLocation.pos.x,
        startLocation.pos.y, startLocation.pos.z))
    FarstriderLib.Logger:Info(string.format("Goal : map %d (%.2f, %.2f, %.2f)", goalLocation.mapId, goalLocation.pos.x,
        goalLocation.pos.y, goalLocation.pos.z))

    ---@type table<NavKey, NavNode>
    local validTravelNodes = self:GetValidTravelNodes()

    -- Check if the player is inside the Wizard's Sanctum (area 10523).
    -- Virtual start nodes in the sanctum may only auto-connect to other
    -- sanctum-interior nodes, mirroring the graph-time isolation.
    local playerInWizardsSanctum = GetSubZoneText() == GetWizardsSanctumName()

    -- Create virtual NavNodes for start and goal locations
    local startNavNode = self:CreateVirtualNavNode(startLocation, validTravelNodes, playerInWizardsSanctum)

    local dynamicFromNode = self.allNodes["dynamic:from"]
    if dynamicFromNode then
        for _, edge in ipairs(dynamicFromNode.edges) do
            table.insert(startNavNode.tempEdges, edge)
            if (edge.to.key == "dynamic:to" and (not edge.condition or edge.condition())) then
                local loc = edge.to:getLocation()

                local uiMapId, localPos
                if loc.isUI then
                    uiMapId = loc.mapId
                    localPos = CreateVector2D(loc.pos.x, loc.pos.y)
                else
                    uiMapId, localPos = C_Map.GetMapPosFromWorldPos(loc.mapId, CreateVector2D(loc.pos.x, loc.pos.y))
                end

                local connections = self:FindClosestNavConnections(
                    { mapId = uiMapId, pos = { x = localPos.x, y = localPos.y, z = loc.pos.z }, isUI = true },
                    self.allNodes)
                for _, connection in ipairs(connections) do
                    local navEdge = { from = edge.to, to = connection.navNode, cost = connection.cost, flag = 0, locaId = ET.TRAVEL, type = 0 }
                    table.insert(edge.to.tempEdges, navEdge)
                end
            end
        end
    end

    local goalNavNode = self:CreateVirtualNavNode(goalLocation, validTravelNodes)

    local startLoc = startNavNode:getLocation()
    local goalLoc = goalNavNode:getLocation()
    if not playerInWizardsSanctum and self:HasDirectFlyPath(startLoc, goalLoc) then
        local dist = self:GetWorldDistanceBetween(startLoc, goalLoc)
        if dist and dist ~= math.huge then
            table.insert(startNavNode.edges,
                { from = startNavNode, to = goalNavNode, cost = dist * DIRECT_TRAVEL_COST_MULTIPLIER, locaId = ET.TRAVEL })
            table.insert(goalNavNode.edges,
                { from = goalNavNode, to = startNavNode, cost = dist * DIRECT_TRAVEL_COST_MULTIPLIER, locaId = ET.TRAVEL })
        end
    end

    -- Dijkstra setup
    local navCostTable = {} ---@type table<NavKey, number>
    local cameFromTable = {} ---@type table<NavKey, NavNode>
    local cameFromEdgeTable = {} ---@type table<NavKey, NavEdge>
    local visited = {} ---@type table<NavKey, boolean>

    -- Binary min-heap helpers (indexed by priority stored in navCostTable)
    local heap = {} ---@type NavNode[]
    local heapSize = 0
    local heapIndex = {} ---@type table<NavKey, number>

    local function heapSwap(i, j)
        heap[i], heap[j] = heap[j], heap[i]
        heapIndex[heap[i].key] = i
        heapIndex[heap[j].key] = j
    end

    local function heapSiftUp(i)
        while i > 1 do
            local parent = math.floor(i / 2)
            if (navCostTable[heap[i].key] or math.huge) < (navCostTable[heap[parent].key] or math.huge) then
                heapSwap(i, parent)
                i = parent
            else
                break
            end
        end
    end

    local function heapSiftDown(i)
        while true do
            local smallest = i
            local left = 2 * i
            local right = 2 * i + 1
            if left <= heapSize and (navCostTable[heap[left].key] or math.huge) < (navCostTable[heap[smallest].key] or math.huge) then
                smallest = left
            end
            if right <= heapSize and (navCostTable[heap[right].key] or math.huge) < (navCostTable[heap[smallest].key] or math.huge) then
                smallest = right
            end
            if smallest ~= i then
                heapSwap(i, smallest)
                i = smallest
            else
                break
            end
        end
    end

    local function heapPush(node)
        heapSize = heapSize + 1
        heap[heapSize] = node
        heapIndex[node.key] = heapSize
        heapSiftUp(heapSize)
    end

    local function heapPop()
        if heapSize == 0 then return nil end
        local top = heap[1]
        heapIndex[top.key] = nil
        heap[1] = heap[heapSize]
        if heapSize > 1 then
            heapIndex[heap[1].key] = 1
        end
        heap[heapSize] = nil
        heapSize = heapSize - 1
        if heapSize > 0 then
            heapSiftDown(1)
        end
        return top
    end

    local function heapDecreaseKey(node)
        local idx = heapIndex[node.key]
        if idx then
            heapSiftUp(idx)
        end
    end


    navCostTable[startNavNode.key] = 0
    heapPush(startNavNode)

    -- Explore graph
    while heapSize > 0 do
        local current = heapPop() ---@type NavNode

        if visited[current.key] then
            -- Skip already-settled nodes
        else
            visited[current.key] = true

            if current.key == goalNavNode.key then
                local currentLoc = current:getLocation()
                FarstriderLib.Logger:InfoGreen("Reached goal node ", currentLoc.mapId, "at position (", currentLoc.pos.x,
                    ",", currentLoc.pos.y, ")")
                break
            end

            for edge in FarstriderLib.NavNode.iterateAllEdges(current) do
                if not edge.condition or edge.condition() then
                    local neighbour = edge.to
                    local edgeCost = edge.cost or math.huge
                    local newCost = (navCostTable[current.key] or math.huge) + edgeCost
                    local oldCost = navCostTable[neighbour.key] or math.huge

                    if newCost < oldCost then
                        navCostTable[neighbour.key] = newCost
                        cameFromTable[neighbour.key] = current
                        cameFromEdgeTable[neighbour.key] = edge
                        if heapIndex[neighbour.key] then
                            heapDecreaseKey(neighbour)
                        else
                            heapPush(neighbour)
                        end
                    end
                end
            end
        end
    end

    -- Reconstruct path and edges
    local path, edges = {}, {} ---@type NavNode[], NavEdge[]
    local node = goalNavNode
    while node do
        table.insert(path, 1, node)
        if cameFromEdgeTable[node.key] then
            table.insert(edges, 1, cameFromEdgeTable[node.key])
        end
        node = cameFromTable[node.key]
    end

    if #path < 2 then
        FarstriderLib.Logger:Error("Path could not be resolved")
        return {}, {}, {}
    end

    FarstriderLib.Logger:Info(string.format("Path found: %d nodes, %d edges", #path, #edges))

    local virtualGoalKey = goalNavNode.key
    local optimizedPath = {}

    local function isFlightpathEdge(edge)
        return edge.locaId == ET.FLIGHTPATH
    end

    local function shouldSkipOptimizedEdge(index)
        local edge = edges[index]
        if index == #edges or edge.to.key == virtualGoalKey then
            return false
        end

        if edge.skipOptimized then
            return true
        end

        if edge.locaId == ET.TRAVEL then
            return true
        end

        -- Chained taxi hops are still a single player action: pick the final
        -- destination once and let the route transfer automatically.
        return isFlightpathEdge(edge) and index + 1 < #edges and isFlightpathEdge(edges[index + 1])
    end

    local function getOptimizedStepLocation(index)
        local edge = edges[index]
        if edge.important and edge.from then
            return edge.from:getLocation()
        end

        return edge.to:getLocation()
    end

    local function getOptimizedStepCompletionLocation(index)
        return edges[index].to:getLocation()
    end

    for i = 1, #edges do
        local edge = edges[i]

        if not shouldSkipOptimizedEdge(i) then
            table.insert(optimizedPath, {
                id = edge.to.key,
                loc = getOptimizedStepLocation(i),
                completionLoc = getOptimizedStepCompletionLocation(i),
                loca = self:GetNodeLoca(edge.locaId, edge.locaArgs),
                actionOptions = edge.actionOptions,
                checkDistance = i ~= #edges
            })
        else
            FarstriderLib.Logger:Info("Skipping intermediate travel-to edge to " .. edge.to.key)
        end
    end

    return optimizedPath, path, edges
end

---@param waypoints Waypoint[]
---@return table<NavKey, NavNode> graph
function Pathfinding:CreateWaypointGraph(waypoints)
    local graph = {} ---@type table<NavKey, NavNode>
    local navEdge ---@type NavEdge

    for _, waypoint in ipairs(waypoints) do
        local valid = not waypoint.condition or waypoint.condition()

        if valid and waypoint.from and waypoint.to then
            local fromNav = self:ConvertWaypointLocationToNavLocation(waypoint.from, graph, "from")
            local toNav = self:ConvertWaypointLocationToNavLocation(waypoint.to, graph, "to")

            if fromNav and toNav then
                graph[fromNav.key] = fromNav
                graph[toNav.key] = toNav

                -- Tag nodes that should not receive auto-generated TRAVEL edges.
                -- Only use Blizzard's explicit NoAutoconnect flag (bit 2).
                -- Do NOT include portal exits (type 2) here — they need TRAVEL
                -- edges so the player can continue after arriving via portal.
                if bit.band(waypoint.from.flags, 2) > 0 then
                    fromNav.noAutoconnect = true
                end
                if bit.band(waypoint.to.flags, 2) > 0 then
                    toNav.noAutoconnect = true
                end

                -- Wizard's Sanctum interior nodes carry flag 0x40.  They form
                -- an isolated sub-graph that only auto-connects internally.
                if bit.band(waypoint.from.flags, 64) > 0 then
                    fromNav.wizardsSanctum = true
                end
                if bit.band(waypoint.to.flags, 64) > 0 then
                    toNav.wizardsSanctum = true
                end

                navEdge = {
                    from = fromNav,
                    to = toNav,
                    cost = waypoint.cost,
                    locaId = waypoint.from.locaId,
                    locaArgs = waypoint.from
                        .locaArgs,
                    flag = waypoint.from.flags,
                    type = waypoint.from.type,
                    condition = waypoint.from.condition,
                    actionOptions =
                        waypoint.from.actionOptions,
                    important = waypoint.from.important,
                    skipOptimized = waypoint.skipOptimized
                }
                table.insert(fromNav.edges, navEdge)
                if waypoint.bidirectional then
                    navEdge = {
                        from = toNav,
                        to = fromNav,
                        cost = waypoint.cost,
                        locaId = waypoint.to.locaId,
                        locaArgs = waypoint.to
                            .locaArgs,
                        flag = waypoint.to.flags,
                        type = waypoint.to.type,
                        condition = waypoint.to.condition,
                        actionOptions =
                            waypoint.to.actionOptions,
                        important = waypoint.to.important,
                        skipOptimized = waypoint.skipOptimized
                    }
                    table.insert(toNav.edges, navEdge)
                end

                FarstriderLib.Logger:Info("Adding waypoint ", fromNav.key, " to ", toNav.key, " for id ", waypoint.id,
                    " with locaId ", waypoint.from.locaId, " from edges ", #fromNav.edges, " to edges ", #toNav.edges)
            end
        end
    end

    return graph
end

--- Render the optimized path as waypoint pins on the world map (debug only).
---@param optimizedPath table[]
---@param path NavNode[]
---@param edges NavEdge[]
function Pathfinding:PrintPath(optimizedPath, path, edges)
    if not path or #path == 0 then
        FarstriderLib.Logger:Error("No path found between the specified locations.")
        return
    end



    local media = FarstriderLib.media_path


    for i, edge in ipairs(optimizedPath) do
        local loc = edge.loc or edge.checkpoint or edge.enter
        if loc then
            FarstriderLib.Logger:Info("Instruction: " .. edge.loca)

            FarstriderLib.PlaceFlare(loc, media .. "Media\\GoldGreenDot", {
                index = i - 1,
                text = self:GetNodeLoca(edge.locaId, edge.locaArgs),
            })
        else
            FarstriderLib.Logger:Error("No location found for edge " .. i)
        end
    end
end

--- Build the navigation graph from data and connect nearby nodes.
function Pathfinding:Initialize()
    local ET = FarstriderLib.EdgeType
    self.allNodes = self:CreateWaypointGraph(FarstriderLib.Data.WAYPOINTS)
    local navEdge ---@type NavEdge

    -- Connect the nav nodes that are directly reachable with each other by creating edges
    for _, navNode in pairs(self.allNodes) do
        if not navNode.isDynamic and not navNode.noAutoconnect then
            local loc = navNode:getLocation()
            if not self:IsMapIsolated(loc.mapId) then
                local connections = self:FindClosestNavConnections({ mapId = loc.mapId, pos = loc.pos, isUI = loc.isUI },
                    self.allNodes, navNode.wizardsSanctum)
                for _, connection in ipairs(connections) do
                    if connection.navNode.key ~= navNode.key and not connection.navNode.noAutoconnect then
                        navEdge = { from = navNode, to = connection.navNode, cost = connection.cost, flag = 0, locaId = ET.TRAVEL, type = 0, important = false }
                        table.insert(navNode.edges, navEdge)
                    end
                end
            end
        end
    end

    FarstriderLib.Logger:Info("Pathfinding initialized with", self:len(self.allNodes), "nodes.")
end

--- Clear the pathfinding cache and re-initialize. Call this after updating any data.
function Pathfinding:Rebuild()
    self:InvalidateCache()
    self:Initialize()
end

--- Override the travel cost multiplier and rebuild the graph.
---@param newMultiplier number
function Pathfinding:ChangeTravelCostMultiplier(newMultiplier)
    TRAVEL_COST_MULTIPLIER = newMultiplier
    FarstriderLib.Logger:Info("Travel cost multiplier changed to:", newMultiplier)
    self:Rebuild()
end
