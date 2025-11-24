local _G = _G

-- Cache of map bounds so we can quickly convert world coords to map coords.
local MapRects = {}
-- Reusable vector to avoid allocations while projecting positions.
local Vector2D = CreateVector2D(0, 0);

--- Get the continent map ID for a given zone (defaults to the player's current zone).
-- We walk the map parents until reaching the continent level to keep logic unified across expansions.
function APR:GetContinent(mapId)
    APR:Debug("Function: APR.getContinent()", mapId)
    mapId = mapId or C_Map.GetBestMapForUnit("player")
    if (mapId == 378) then -- why ?  The Wandering Isle
        return 378
    elseif (mapId) then
        local info = C_Map.GetMapInfo(mapId)
        if (info) then
            while (info and info.mapType and info.mapType > 2) do
                info = C_Map.GetMapInfo(info.parentMapID)
            end
            if (info and info.mapType == 2) then
                return info.mapID
            end
        end
    end
end

--- Project the player's world position into the provided map space.
-- dx/dy can be supplied for ad-hoc projections (e.g., taxi nodes) while reusing the same math.
function APR:GetPlayerMapPos(MapID, dx, dy)
    if (MapID and (MapID == 1726 or MapID == 1727 or MapID == 905 or MapID == 948 or APRt_Zone == 1727)) then
        return
    end

    local R, P = MapRects[MapID], Vector2D;
    -- If the zone does not have a rect yet, calculate and store it for later use
    if not R then
        R = {};
        _, R[1] = C_Map.GetWorldPosFromMapPos(MapID, CreateVector2D(0, 0));
        _, R[2] = C_Map.GetWorldPosFromMapPos(MapID, CreateVector2D(1, 1));
        R[2]:Subtract(R[1]);
        MapRects[MapID] = R;
    end

    -- Determine the coordinates to use for calculations (player by default)
    if dx then
        P.x, P.y = dx, dy
    else
        P.x, P.y = UnitPosition('player');
    end

    -- Perform map position calculations
    if P.x then
        P:Subtract(R[1]);
        local scaleY = 1 / R[2].y;
        local scaleX = 1 / R[2].x;
        return scaleY * P.y, scaleX * P.x;
    end
end

--- Return the parent map for the player (zone by default) at a given hierarchy level.
function APR:GetPlayerParentMapID(mapType)
    mapType = mapType or Enum.UIMapType.Zone
    local playerMapId
    local currentMapId = C_Map.GetBestMapForUnit('player')
    if currentMapId and Enum and Enum.UIMapType then
        playerMapId = MapUtil.GetMapParentInfo(currentMapId, mapType, true)
        playerMapId = playerMapId and playerMapId.mapID or currentMapId
    end
    return playerMapId
end

--- Find the current taxi node the player is attached to while on a flight path.
function APR:GetPlayerCurrentTaxiNode()
    local playerMapID = APR:GetPlayerParentMapID()
    local taxiNodes = C_TaxiMap.GetAllTaxiNodes(playerMapID)

    for _, node in ipairs(taxiNodes) do
        if node.state == Enum.FlightPathState.Current then
            return node
        end
    end
    return {}
end
