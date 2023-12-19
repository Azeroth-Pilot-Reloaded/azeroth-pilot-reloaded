local _G = _G

local MapRects = {}
local Vector2D = CreateVector2D(0, 0);

--- Getting the continent the player is on and its info
function APR:GetContinent(mapId)
    if (APR.settings.profile.debug) then
        print("Function: APR.getContinent()")
    end
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

    -- Determine the coordinates to use for calculations
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

function APR:GetPlayerParentMapID()
    local playerMapId
    local currentMapId = C_Map.GetBestMapForUnit('player')
    if currentMapId and Enum and Enum.UIMapType then
        playerMapId = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Zone, true)
        playerMapId = playerMapId and playerMapId.mapID or currentMapId
    end
    return playerMapId
end

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

-- check if the zone ID is in the route map IDs
--- @param mapIds number
--- @param mapId Array<number>
function APR:IsInExpansionRouteMaps(mapIds, mapId)
    return Contains(mapIds, mapId)
end
