-----------------------------------------------------------
-- Player Position Utilities
-- Functions for player position calculations, map projections,
-- and movement restrictions
--
-- NOTE: Zone hierarchy functions (GetContinent, GetPlayerParentMapID, etc)
--       have been moved to ZoneDetectionUtils.lua for better organization
-----------------------------------------------------------

-- Cache of map bounds so we can quickly convert world coords to map coords.
local MapRects = {}
-- Reusable vector to avoid allocations while projecting positions.
local Vector2D = CreateVector2D(0, 0);

--- Project the player's world position into the provided map space.
-- dx/dy can be supplied for ad-hoc projections (e.g., taxi nodes) while reusing the same math.
function APR:GetPlayerMapPos(MapID, dx, dy)
    if (MapID and (MapID == 1726 or MapID == 1727 or MapID == 905 or MapID == 948)) then
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

--- Check if player is currently in a no-fly zone
--- Uses ZoneRestrictions.NO_FLY_MAPS data
--- @return boolean isNoFlyZone
function APR:IsInNoFlyZone()
    local currentMapID = C_Map.GetBestMapForUnit("player")
    if not currentMapID then
        return false
    end

    -- Check current map
    if APR.ZoneRestrictions.NO_FLY_MAPS[currentMapID] then
        return true
    end

    -- Check parent map (for sub-zones)
    local parentMapID = self:GetPlayerParentMapID()
    if parentMapID and APR.ZoneRestrictions.NO_FLY_MAPS[parentMapID] then
        return true
    end

    return false
end
