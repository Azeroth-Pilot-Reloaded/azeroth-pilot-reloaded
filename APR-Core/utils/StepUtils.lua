local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Primary and secondary keys that identify the main action for a step.
-- Keeping them here ensures other modules can reason about step intent without re-declaring lists.
APR.mainStepOptions = {
    "ExitTutorial", "PickUp", "DropQuest", "Qpart", "QpartPart", "Treasure", "Group", "Done",
    "Scenario", "EnterScenario", "DoScenario", "LeaveScenario", "UseHS", "UseDalaHS", "UseGarrisonHS",
    "UseItem", "UseSpell", "GetFP", "UseFlightPath", "TakePortal", "LearnProfession", "LootItems", "WarMode", "Grind",
    "RouteCompleted"
}

-- BuyMerchant need to be first
APR.secondaryStepOptions = {
    "BuyMerchant", "GossipOptionIDs"
}

--- Return the localized label for the first recognized step key.
-- This keeps UI construction simple while letting steps remain data-driven.
function APR:GetStepString(step)
    local stepMappings = {
        BuyMerchant = L["BUY"],
        Done = L["TURN_IN_Q"],
        DoScenario = L["SCENARIO"],
        DropQuest = L["Q_DROP"],
        EnterScenario = L["SCENARIO"],
        ExitTutorial = L["SKIP_TUTORIAL"],
        GetFP = L["GET_FLIGHTPATH"],
        GossipOptionIDs = L["TALK_NPC"],
        Grind = L["GRIND"],
        Group = L["GROUP_Q"],
        LearnProfession = L["LEARN_PROFESSION"],
        LeaveScenario = L["SCENARIO"],
        LootItems = L["LOOT_ITEM"],
        PickUp = L["PICK_UP_Q"],
        Qpart = L["Q_PART"],
        QpartPart = L["Q_PART"],
        RouteCompleted = L["ROUTE_COMPLETED"],
        Scenario = L["SCENARIO"],
        SetHS = L["SET_HEARTHSTONE"],
        Treasure = L["GET_TREASURE"],
        TakePortal = L["USE_PORTAL"],
        UseDalaHS = L["USE_DALARAN_HEARTHSTONE"],
        UseFlightPath = L["USE_FLIGHTPATH"],
        UseGarrisonHS = L["USE_GARRISON_HEARTHSTONE"],
        UseHS = L["USE_HEARTHSTONE"],
        UseItem = L["USE_ITEM"],
        UseSpell = L["USE_SPELL"],
        WarMode = L["TURN_ON_WARMODE"],
        Waypoint = L["RUN_WAYPOINT"],
    }

    for key, _ in pairs(step) do
        if stepMappings[key] then
            return stepMappings[key], key
        end
    end

    return ''
end

--- Build the waypoint summary text by scanning upcoming steps for actionable instructions.
-- This mirrors legacy behaviour but is wrapped in a single helper for maintainability.
function APR:CheckWaypointText()
    local currentStepIndex = APRData[APR.PlayerID][APR.ActiveRoute]

    local function IsInList(value, list)
        for _, v in ipairs(list) do
            if v == value then
                return true
            end
        end
        return false
    end

    for i = currentStepIndex, #APR.RouteQuestStepList[APR.ActiveRoute] do
        local step = APR.RouteQuestStepList[APR.ActiveRoute][i]

        if step then
            local stepText, stepKey = APR:GetStepString(step)

            if stepKey then
                if IsInList(stepKey, APR.mainStepOptions) then
                    return "[" .. L["WAYPOINT"] .. "] - " .. stepText
                elseif not step["Waypoint"] and IsInList(stepKey, APR.secondaryStepOptions) then
                    return "[" .. L["WAYPOINT"] .. "] - " .. stepText
                end
            end
        end
    end

    return L["TRAVEL_TO"] .. " - " .. L["WAYPOINT"]
end

--- Quick check for any primary action flags on a step table.
function APR:HasAnyMainStepOption(step)
    if not step then return false end
    for _, key in ipairs(APR.mainStepOptions) do
        if step[key] ~= nil then
            return true
        end
    end
    return false
end

--- Advance helpers ---------------------------------------------------------

--- Update both quest tracker and step view together.
function APR:UpdateQuestAndStep()
    APR:UpdateQuest()
    APR:UpdateStep()
end

--- Move to the next step index, then refresh current step rendering.
function APR:UpdateNextStep()
    APRData[APR.PlayerID][APR.ActiveRoute] = APRData[APR.PlayerID][APR.ActiveRoute] + 1
    APR:UpdateStep()
end

--- Advance both quest and step state in tandem.
function APR:NextQuestStep()
    APRData[APR.PlayerID][APR.ActiveRoute] = APRData[APR.PlayerID][APR.ActiveRoute] + 1
    self:UpdateQuestAndStep()
end

--- Walk backwards in the route until a valid non-filtered step is found.
-- Includes a guard to avoid infinite loops in malformed routes.
function APR:PreviousQuestStep()
    local userData = APRData[APR.PlayerID]
    local activeRoute = APR.ActiveRoute
    local questStepList = APR.RouteQuestStepList[activeRoute]

    -- Safety to prevent infinite loop
    local tries = 0

    while userData[activeRoute] > 1 do
        userData[activeRoute] = userData[activeRoute] - 1
        local step = questStepList[userData[activeRoute]]
        if not (APR:StepFilterQuestHandler(step) or (step and step.Waypoint)) then
            break
        end
        tries = tries + 1
        if tries > 100 then -- Prevent infinite loop
            break
        end
    end

    -- Update the quest and step
    self:UpdateQuestAndStep()
end

--- Lookup helpers ---------------------------------------------------------

--- Retrieve the step table at an index for the active route.
function APR:GetStep(index)
    if (index and APR.RouteQuestStepList and APR.RouteQuestStepList[APR.ActiveRoute]) then
        return APR.RouteQuestStepList[APR.ActiveRoute][index]
    end
    return nil
end

local function NormalizeZoneList(value)
    if value == nil then
        return nil
    end

    if type(value) ~= "table" then
        return { value }
    end

    if #value > 0 then
        return value
    end

    local list = {}
    for _, zone in pairs(value) do
        table.insert(list, zone)
    end
    return list
end

--- Normalize a step's zone definition into a list, falling back to the route map id.
function APR:GetStepZoneList(step, fallbackMapID)
    local zones = step and NormalizeZoneList(step.Zones) or nil
    if not zones or #zones == 0 then
        zones = step and NormalizeZoneList(step.Zone) or nil
    end
    if not zones or #zones == 0 then
        zones = NormalizeZoneList(fallbackMapID)
    end

    return zones or {}
end

--- Pick a routing target from a step zone list, preferring the current continent.
function APR:GetPreferredStepZone(step, fallbackMapID)
    local zones = self:GetStepZoneList(step, fallbackMapID)
    if #zones == 0 then
        return nil
    end

    local playerContinent = self:GetContinent()
    for _, zone in ipairs(zones) do
        if self:GetContinent(zone) == playerContinent then
            return zone
        end
    end

    return zones[1]
end

local function IsCoordTable(value)
    return type(value) == "table" and value.x ~= nil and value.y ~= nil
end

local function ExtractCoord(entry)
    if IsCoordTable(entry) then
        return entry
    end

    if type(entry) == "table" and IsCoordTable(entry.Coord) then
        return entry.Coord
    end

    return nil
end

local function GetEntryZone(entry)
    if type(entry) ~= "table" then
        return nil
    end

    return entry.Zone or entry.zone or entry.mapID or entry.MapID or entry.uiMapID or entry.UiMapID
end

--- Resolve the best-matching zone id for the player, falling back to the preferred zone.
function APR:GetStepZoneForPlayer(step, fallbackMapID, zoneHint, zones)
    zones = zones or self:GetStepZoneList(step, fallbackMapID)
    if #zones == 0 then
        return nil
    end

    if zoneHint and self:Contains(zones, zoneHint) then
        return zoneHint
    end

    local currentMapID = C_Map.GetBestMapForUnit("player")
    if currentMapID and self:Contains(zones, currentMapID) then
        return currentMapID
    end

    local parentMapID = self:GetPlayerParentMapID()
    if parentMapID and self:Contains(zones, parentMapID) then
        return parentMapID
    end

    return self:GetPreferredStepZone(step, fallbackMapID)
end

--- Resolve the coordinate for a step, supporting multi-zone coordinates.
function APR:GetStepCoord(step, fallbackMapID, zoneHint)
    if not step then
        return nil
    end

    if IsCoordTable(step.Coord) then
        return step.Coord, nil
    end

    local coordsSource = step.Coords or step.Coord
    if type(coordsSource) ~= "table" then
        return nil
    end

    local zones = self:GetStepZoneList(step, fallbackMapID)
    local zoneId = self:GetStepZoneForPlayer(step, fallbackMapID, zoneHint, zones)
    local coord = nil

    if #coordsSource == 0 then
        if zoneId then
            coord = ExtractCoord(coordsSource[zoneId])
        end
        if not coord then
            for _, entry in pairs(coordsSource) do
                coord = ExtractCoord(entry)
                if coord then
                    break
                end
            end
        end
        return coord, zoneId
    end

    if zoneId then
        for _, entry in ipairs(coordsSource) do
            if GetEntryZone(entry) == zoneId then
                coord = ExtractCoord(entry)
                if coord then
                    break
                end
            end
        end
    end

    if not coord and zoneId and #zones > 0 then
        for index, zone in ipairs(zones) do
            if zone == zoneId then
                coord = ExtractCoord(coordsSource[index])
                if coord then
                    break
                end
            end
        end
    end

    if not coord then
        for _, entry in ipairs(coordsSource) do
            coord = ExtractCoord(entry)
            if coord then
                break
            end
        end
    end

    return coord, zoneId
end

--- Determine if the provided quest id belongs to the current step.
function APR:IsARouteQuest(questId)
    local step = self:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    return step and self:IsQuestInPool(questId) or false
end

--- Quick check if the active step is a pickup step (for UI hints).
function APR:IsPickupStep()
    local step = self:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    return step and (step.PickUp or step.PickUpDB) or false
end
