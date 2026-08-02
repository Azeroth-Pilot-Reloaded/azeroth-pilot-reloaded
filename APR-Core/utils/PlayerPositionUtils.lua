-----------------------------------------------------------
-- Player Position Utilities
-- Functions for player position calculations, map projections,
-- and world/map coordinate conversion
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
    if not APR:IsValidMapID(MapID) then
        return
    end

    local R, P = MapRects[MapID], Vector2D;
    -- If the zone does not have a rect yet, calculate and store it for later use
    if not R then
        R = {};
        _, R[1] = C_Map.GetWorldPosFromMapPos(MapID, CreateVector2D(0, 0));
        if not R[1] then
            return
        end
        _, R[2] = C_Map.GetWorldPosFromMapPos(MapID, CreateVector2D(1, 1));
        if not R[2] then
            return
        end
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
