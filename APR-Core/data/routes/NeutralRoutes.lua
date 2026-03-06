local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Route metadata registry: maps expansion -> { routeKey -> label }
-- These are routes available to all factions (no faction condition = universal availability).
-- Alliance-specific and Horde-specific routes are defined in AllianceRoutes.lua / HordeRoutes.lua
-- and are registered with a Faction condition during InitAllianceRoutes / InitHordeRoutes.
local neutralRoutesByExpansion = {


}

-- Common starting routes
local startRoutes = {
    -- Races

function APR:InitRoutes()
    -- First, register all neutral routes (available to all factions)
    APR:MergeExpansionRoutes(neutralRoutesByExpansion)


    ---
    ---  WARNING Class before race
    ---

    local routesToAssign = {}
    local className = APR:GetClassNameById(APR.ClassId)
    if APR:IsRemixCharacter() then
        -- specific remix start routes
    elseif APR.ClassId == APR.Classes["Death Knight"] then
        -- Use allied start if race ID is >= 23; otherwise, default Death Knight start
        if APR.RaceID >= 23 then
            table.insert(routesToAssign, startRoutes["Death Knight"].allied)
        else
            table.insert(routesToAssign, startRoutes["Death Knight"].default)
        end
    elseif APR.Race == "Dracthyr" then
        -- Check for Dracthyr Evoker-specific start, else use general Dracthyr start
        if APR.ClassId == APR.Classes.Evoker then
            table.insert(routesToAssign, startRoutes.Dracthyr.evoker)
        else
            table.insert(routesToAssign, startRoutes.Dracthyr.default)
        end
    elseif startRoutes[className].default then
        -- Classes
        table.insert(routesToAssign, startRoutes[className].default)
    else
        -- Race
        table.insert(routesToAssign, startRoutes[APR.Race])
    end


    -- Class Specs
    if startRoutes[className] and startRoutes[className].spec then
        for specName, specRoute in pairs(startRoutes[className].spec) do
            table.insert(routesToAssign, specRoute)
        end
    end



    -- Lumbermill Wod route
    -- Special case for Warlords of Draenor route based on quest completion
    local gorgrondRoute
    if C_QuestLog.IsQuestFlaggedCompleted(35049) then
        gorgrondRoute = {
            expansion = "WarlordsOfDraenor",
            key = "543-DesMephisto-Gorgrond-Lumbermill",
            label = L["WOD04 - Gorgrond"],
        }
    else
        gorgrondRoute = {
            expansion = "WarlordsOfDraenor",
            key = "543-DesMephisto-Gorgrond",
            label = L["WOD04 - Gorgrond"],
        }
    end
    table.insert(routesToAssign, gorgrondRoute)

    -- Apply all collected routes
    APR:assignRoutes(routesToAssign)
end
