-- FarstriderLib~Core.lua
-- Public navigation API and PLAYER_LOGIN bootstrap.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end

--- Look up a corrected Z elevation from config.
--- Many Shadowlands / Dragonflight maps share a continent but differ in altitude;
--- this table prevents incorrect "direct fly" distance calculations.
---@param mapId number
---@return number
local function GetZ(mapId)
    local overrides = FarstriderLib.Data.CONFIG.ElevationOverrides
    return overrides and overrides[mapId] or 0
end

--- Find the shortest path between two explicit map positions.
--- Coordinates use UI-map space (0-1 range). Pass z = 0 to auto-resolve
--- elevation from config.ElevationOverrides.
---@param startMapId MapId
---@param startX number
---@param startY number
---@param startZ number
---@param goalMapId MapId
---@param endX number
---@param endY number
---@param endZ number
---@return table[] optimizedPath, NavNode[] path, NavEdge[] edges
function FarstriderLib.FindTrail(startMapId, startX, startY, startZ, goalMapId, endX, endY, endZ)
    local startLocation = { mapId = startMapId, pos = { x = startX, y = startY, z = startZ == 0 and GetZ(startMapId) or startZ }, isUI = true } ---@type NavLocation
    local goalLocation = { mapId = goalMapId, pos = { x = endX, y = endY, z = endZ == 0 and GetZ(goalMapId) or endZ }, isUI = true } ---@type NavLocation
    local optimizedPath, path, edges = FarstriderLib.Pathfinding:FindPathBetweenLocations2(startLocation, goalLocation)


    return optimizedPath, path, edges
end

--- Find the shortest path from the player's current position to a goal.
--- Automatically resolves the player's map and position.
---@param goalMapId MapId
---@param endX number
---@param endY number
---@param endZ number
---@return table[]? optimizedPath, NavNode[]? path, NavEdge[]? edges
function FarstriderLib.FindTrailTo(goalMapId, endX, endY, endZ)
    local playerMapId = C_Map.GetBestMapForUnit("player")
    if not playerMapId then
        FarstriderLib.Logger:Error("No map found for the player.")
        return
    end

    local playerPosition = C_Map.GetPlayerMapPosition(playerMapId, "player")
    if not playerPosition then
        local parentMapId = C_Map.GetMapInfo(playerMapId).parentMapID
        if parentMapId then
            playerMapId = parentMapId
            local instanceId = EJ_GetInstanceForMap(playerMapId)
            local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(parentMapId)
            for _, entrance in ipairs(dungeonEntrances) do
                if entrance.journalInstanceID == instanceId then
                    playerPosition = entrance.position
                end
            end
        end

        if not playerPosition then
            playerPosition = { x = 0.5, y = 0.5 }
        end
    end

    return FarstriderLib.FindTrail(playerMapId, playerPosition.x, playerPosition.y, 0, goalMapId, endX, endY, endZ)
end

-- Auto-initialize on PLAYER_LOGIN
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    FarstriderLib.Pathfinding:Rebuild()
end)
