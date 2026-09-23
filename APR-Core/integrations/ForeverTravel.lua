-- Forever has ground travel and a character-specific flight network. Only add
-- flights actually offered by a flight master, never all pairs of known nodes.
APR.foreverTravel = APR:NewModule("ForeverTravel")

local WALK_SPEED = 7
local FLIGHT_SPEED = 32
local FLIGHT_OVERHEAD = 15

local function GetCharacterData()
    if not APR.GetGameVersion or APR:GetGameVersion() ~= APR.GAME_VERSIONS.Forever then return nil end
    return APRData and APR.PlayerID and APRData[APR.PlayerID]
end

function APR.foreverTravel:ObserveTaxiMap(nodes)
    local character = GetCharacterData()
    if not character then return end
    local current
    for _, node in ipairs(nodes) do
        if node.state == Enum.FlightPathState.Current then current = node.nodeID; break end
    end
    if not current then return end

    character.TaxiRoutes = character.TaxiRoutes or {}
    local routes = character.TaxiRoutes[current] or {}
    character.TaxiRoutes[current] = routes
    local changed = false
    for _, node in ipairs(nodes) do
        if node.nodeID ~= current and not node.isMapLayerTransition then
            local reachable = node.state == Enum.FlightPathState.Reachable and
                node.slotIndex and node.slotIndex > 0 or false
            if reachable and not routes[node.nodeID] then
                routes[node.nodeID] = true
                changed = true
            elseif node.state == Enum.FlightPathState.Unreachable and routes[node.nodeID] then
                routes[node.nodeID] = nil
                changed = true
            end
        end
    end
    if changed then
        self.dirty = true
        if APR.farstrider then
            APR.farstrider:InvalidatePathCache()
            APR.farstrider:ScheduleRouteCheck({})
        end
    end
end

local function GetLocation(nodeID)
    local position = APR.taxiData:GetNodeWorldPosition(nodeID)
    if not position or type(position.x) ~= "number" or type(position.y) ~= "number" or
        type(position.instanceID) ~= "number" then return nil end
    return {
        mapId = position.instanceID,
        pos = { x = position.x, y = position.y, z = position.z or 0 },
        isUI = false,
    }
end

local function MakeFlight(fromID, toID, routes)
    if not APR:HasTaxiNode(fromID) or not APR:HasTaxiNode(toID) then return nil end
    local from, to = GetLocation(fromID), GetLocation(toID)
    if not from or not to or from.mapId ~= to.mapId then return nil end
    local fromName = APR.taxiData:GetNodeName(fromID)
    local toName = APR.taxiData:GetNodeName(toID)
    if not fromName or not toName then return nil end
    local dx, dy = to.pos.x - from.pos.x, to.pos.y - from.pos.y
    local measured = APRTaxiNodesTimer and APRTaxiNodesTimer[fromName .. "-" .. toName]
    -- Costs are seconds. Allow for curved flight paths when no measured duration
    -- exists, plus boarding; walking to/from the master is costed by Farstrider.
    local duration = type(measured) == "number" and measured > 0 and measured or
        math.sqrt(dx * dx + dy * dy) * 1.25 / FLIGHT_SPEED
    return {
        id = "apr-flight-" .. fromID .. "-" .. toID,
        aprObservedFlight = true,
        -- Each observed route can already include transfers. Do not collapse it
        -- with another route unless the client has confirmed that whole journey.
        separateFlight = true,
        cost = FLIGHT_OVERHEAD + duration,
        bidirectional = false,
        from = {
            loc = from, flags = 0, type = 1, important = true, locaId = 1001,
            locaArgs = function() return { APR.taxiData:GetNodeName(toID) or toName } end,
            condition = function()
                return routes[toID] == true and APR:HasTaxiNode(fromID) and APR:HasTaxiNode(toID)
            end,
        },
        to = { loc = to, flags = 0, type = 1, important = true, locaId = 1001 },
    }
end

function APR.foreverTravel:RefreshGraph()
    local character = GetCharacterData()
    local library = _G.FarstriderLib
    local engine = library and library.Pathfinding
    local waypoints = library and library.Data and library.Data.WAYPOINTS
    if not character or not engine or not engine.ChangeTravelCostMultiplier or
        type(waypoints) ~= "table" or not next(waypoints) then return end
    local taxiAPI = APR.taxiData and APR.taxiData:GetAPI()
    if not self.dirty and self.character == character and self.engine == engine and
        self.waypoints == waypoints and self.taxiAPI == taxiAPI then return end

    for index = #waypoints, 1, -1 do
        if waypoints[index].aprObservedFlight then table.remove(waypoints, index) end
    end
    if taxiAPI then
        for fromID, routes in pairs(character.TaxiRoutes or {}) do
            for toID, reachable in pairs(routes) do
                if reachable then
                    local flight = MakeFlight(fromID, toID, routes)
                    if flight then table.insert(waypoints, flight) end
                end
            end
        end
    end
    -- The old setter left the direct shortcut at dragonriding speed. Both
    -- approach legs and the direct route must use ground speed, without a discount.
    engine:ChangeTravelCostMultiplier(1 / WALK_SPEED, 1 / WALK_SPEED)
    self.character, self.engine, self.waypoints, self.taxiAPI = character, engine, waypoints, taxiAPI
    self.dirty = false
    if APR.farstrider then APR.farstrider:InvalidatePathCache() end
end
