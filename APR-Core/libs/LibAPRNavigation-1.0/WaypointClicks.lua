local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("waypointClicks", 1) then return end
local Instance = Lib.Instance

local function Number(value)
    return not (issecretvalue and issecretvalue(value)) and type(value) == "number"
        and value == value and value > -math.huge and value < math.huge
end

local function MapID(value)
    return Number(value) and value > 0 and value % 1 == 0
end

local function OnMap(x, y)
    return Number(x) and Number(y) and x >= 0 and x <= 1 and y >= 0 and y <= 1
end

function Instance:ResolveMapWaypoint(mapID, x, y)
    if not MapID(mapID) or not OnMap(x, y) then return end
    local point = self:NormalizeLocation({space = "map", uiMapID = mapID, x = x, y = y})
    if not point then return end
    local info = self:GetMapAncestryInfo(mapID)
    if not info or not Number(info.mapType) or info.mapType > 2 or not self.env.worldToMap then return point end
    -- Use the local map's access rules when a continent click resolves to a zone.
    local localMap, localX, localY = self.env.worldToMap(point.instanceID, point.x, point.y)
    if not MapID(localMap) or localMap == mapID or not OnMap(localX, localY) then return point end
    local parent, seen = localMap, {}
    while MapID(parent) and not seen[parent] do
        if parent == mapID then
            return self:NormalizeLocation({instanceID = point.instanceID, uiMapID = localMap, x = point.x, y = point.y}) or point
        end
        seen[parent] = true
        local ancestor = self:GetMapAncestryInfo(parent)
        parent = ancestor and ancestor.parentMapID
    end
    return point
end

-- Entries identify which quadrants have a rounded edge, in screen coordinates.
local roundQuadrants = {
    SQUARE = {},
    ["CORNER-TOPLEFT"] = {true},
    ["CORNER-TOPRIGHT"] = {[3] = true},
    ["CORNER-BOTTOMLEFT"] = {[2] = true},
    ["CORNER-BOTTOMRIGHT"] = {[4] = true},
    ["SIDE-LEFT"] = {true, true},
    ["SIDE-RIGHT"] = {[3] = true, [4] = true},
    ["SIDE-TOP"] = {true, false, true},
    ["SIDE-BOTTOM"] = {false, true, false, true},
    ["TRICORNER-TOPLEFT"] = {true, true, true},
    ["TRICORNER-TOPRIGHT"] = {true, false, true, true},
    ["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
    ["TRICORNER-BOTTOMRIGHT"] = {false, true, true, true},
}

function Instance:ResolveMinimapWaypoint(minimap)
    local radius = C_Minimap and C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()
    if not Number(radius) or radius <= 0 or not GetCursorPosition then return end
    local cx, cy = minimap:GetCenter()
    local width, height, scale = minimap:GetWidth(), minimap:GetHeight(), minimap:GetEffectiveScale()
    local mx, my = GetCursorPosition()
    if not Number(cx) or not Number(cy) or not Number(mx) or not Number(my)
        or not Number(scale) or scale <= 0 or not Number(width) or width <= 0 or not Number(height) or height <= 0 then return end
    local east, north = (mx / scale - cx) * 2 / width, (my / scale - cy) * 2 / height
    if math.abs(east) > 1 or math.abs(north) > 1 then return end
    local shape = GetMinimapShape and roundQuadrants[GetMinimapShape()]
    local quadrant = (east < 0 and 1 or 3) + (north < 0 and 1 or 0)
    if (not shape or shape[quadrant]) and east * east + north * north > 1 then return end

    if GetCVar and GetCVar("rotateMinimap") == "1"
        and not (C_Minimap.IsRotateMinimapIgnored and C_Minimap.IsRotateMinimapIgnored()) then
        local facing = GetPlayerFacing and GetPlayerFacing()
        if not Number(facing) then return end
        local sin, cos = math.sin(facing), math.cos(facing)
        east, north = east * cos - north * sin, east * sin + north * cos
    end
    local player = self.env.getPlayerPosition and self.env.getPlayerPosition()
    local project = self.env.worldToMap
    if not project or (issecretvalue and issecretvalue(player)) or type(player) ~= "table"
        or not Number(player.x) or not Number(player.y) or not Number(player.instanceID) then return end
    -- Engine positions follow UnitPosition, with north as X and west as Y.
    local x, y = player.x + north * radius, player.y - east * radius
    local mapID, mapX, mapY
    if MapID(player.uiMapID) then mapID, mapX, mapY = project(player.instanceID, x, y, player.uiMapID) end
    if not MapID(mapID) or mapID ~= player.uiMapID or not OnMap(mapX, mapY) then
        mapID, mapX, mapY = project(player.instanceID, x, y)
    end
    local point = self:ResolveMapWaypoint(mapID, mapX, mapY)
    if point and point.instanceID == self:GetWorldInstanceID(player.instanceID) then return point end
end

local function ClickOwner(button)
    local owner = Lib.waypointClickOwner
    if owner and button == "LeftButton" and IsShiftKeyDown and IsShiftKeyDown()
        and not (IsControlKeyDown and IsControlKeyDown()) and not (IsAltKeyDown and IsAltKeyDown()) then
        return owner
    end
end

local function WorldClick(map, button, x, y)
    local owner = ClickOwner(button)
    local point = owner and owner:ResolveMapWaypoint(map:GetMapID(), x, y)
    return point ~= nil and owner.waypointClickHandler(point, "worldmap") == true
end

local function MinimapClick(minimap, button)
    local owner = ClickOwner(button)
    local point = owner and owner:ResolveMinimapWaypoint(minimap)
    if point then owner.waypointClickHandler(point, "minimap") end
end

local function Attach()
    if not Lib.waypointClickWorldMap and WorldMapFrame and WorldMapFrame.AddCanvasClickHandler then
        WorldMapFrame:AddCanvasClickHandler(WorldClick)
        Lib.waypointClickWorldMap = true
    end
    if not Lib.waypointClickMinimap and Minimap and Minimap.HookScript then
        Minimap:HookScript("OnMouseUp", MinimapClick)
        Lib.waypointClickMinimap = true
    end
    return Lib.waypointClickWorldMap and Lib.waypointClickMinimap
end

-- Only one consumer owns the native gesture at a time. Passing nil releases it.
function Instance:SetWaypointClickHandler(handler)
    assert(handler == nil or type(handler) == "function", "waypoint click handler must be a function")
    self.waypointClickHandler = handler
    local frame = Lib.waypointClickLoader
    if not handler then
        if Lib.waypointClickOwner == self then
            Lib.waypointClickOwner = nil
            if frame then frame:UnregisterAllEvents() end
        end
        return
    end
    Lib.waypointClickOwner = self
    if Attach() then
        if frame then frame:UnregisterAllEvents() end
        return
    end
    if not CreateFrame then return end
    if not frame then
        frame = CreateFrame("Frame")
        Lib.waypointClickLoader = frame
        frame:SetScript("OnEvent", function(self, event, addon)
            if event == "PLAYER_LOGIN" or addon == "Blizzard_WorldMap" or addon == "Blizzard_Minimap" then
                if Attach() then self:UnregisterAllEvents() end
            end
        end)
    end
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("ADDON_LOADED")
end
