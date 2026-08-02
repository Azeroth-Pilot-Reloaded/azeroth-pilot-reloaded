local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.farstrider = APR:NewModule("Farstrider")

APR.farstrider.ErrorDestinationLineKey = "00_ERROR_DESTINATION"
APR.farstrider.NavigationDividerStepKey = "03_NAVIGATION_DIVIDER"
APR.farstrider.NavigationStepKey = "01_FARSTRIDER_PATH"
APR.farstrider.ErrorStepKey = "01_FARSTRIDER_ERROR"
APR.farstrider.ErrorTextColor = (APR.HEXColor and APR.HEXColor.red) or "ff3333"
APR.farstrider.showOutOfZoneStepContent = false

local ARRIVAL_DISTANCE = 15
local ROUTING_RETRY_DELAY = 1.5

local function GetCurrentRouteStep()
    if not APR.ActiveRoute or not APRData[APR.PlayerID] then
        return nil
    end

    local stepIndex = APRData[APR.PlayerID][APR.ActiveRoute]
    local routeSteps = APR:GetRouteSteps(APR.ActiveRoute)
    return routeSteps and stepIndex and routeSteps[stepIndex] or nil
end

local function RequiresScenarioNavigation(step)
    local scenarioMapID = step and APR:GetScenarioMapIDForStep(step) or nil
    if not scenarioMapID then
        return false
    end

    local currentMapID = C_Map.GetBestMapForUnit("player")
    local parentMapID = APR:GetPlayerParentMapID()
    local isInsideScenario = currentMapID == scenarioMapID or parentMapID == scenarioMapID

    if step.LeaveScenario or step.LeaveInstance then
        return isInsideScenario
    end

    return not isInsideScenario and
        (step.Scenario or step.EnterScenario or step.DoScenario or step.EnterInstance) ~= nil
end

local function GetFarstriderAPI()
    local api = _G.FarstriderLib_API
    local missingDependencies = {}
    local hasFarstrider = type(api) == "table" and type(api.FindTrailTo) == "function"
    if not hasFarstrider then
        table.insert(missingDependencies, "FarstriderLib")
    end

    -- FarstriderLib exposes an empty data proxy when FarstriderLib Data is not
    -- loaded. A non-empty public WAYPOINTS table therefore detects the data
    -- package without pinning APR to one of its release numbers.
    local data
    if hasFarstrider then
        data = api.DATA
    else
        data = _G.FarstriderLibData_API
    end
    local hasFarstriderData = type(data) == "table" and
        type(data.WAYPOINTS) == "table" and next(data.WAYPOINTS) ~= nil
    if not hasFarstriderData then
        table.insert(missingDependencies, "FarstriderLibData")
    end

    if #missingDependencies > 0 then
        return nil, table.concat(missingDependencies, ", ")
    end

    return api
end

local missingDependencyWarningShown = false

local function ReportMissingDependencies(missingDependencies)
    if missingDependencyWarningShown or not missingDependencies then
        return
    end

    missingDependencyWarningShown = true
    APR:PrintError(string.format(L["ADDON_DEPENDENCY_MISSING"], missingDependencies))
end

local dependencyEventFrame = CreateFrame("Frame")
dependencyEventFrame:RegisterEvent("PLAYER_LOGIN")
dependencyEventFrame:SetScript("OnEvent", function()
    local _, missingDependencies = GetFarstriderAPI()
    ReportMissingDependencies(missingDependencies)
end)

local function IsActionUsable(action)
    if type(action) ~= "table" then
        return false
    end

    if action.type == "housing" then
        local api = GetFarstriderAPI()
        return C_Housing ~= nil and api ~= nil and type(api.DATA.GetHousingData) == "function" and
            api.DATA.GetHousingData() ~= nil
    end

    if action.type == "housing_return" then
        return C_Housing ~= nil
    end

    if not action.data then
        return false
    end

    if action.type == "spell" then
        if not APR:IsSpellKnown(action.data) then
            return false
        end

        local charges = C_Spell.GetSpellCharges(action.data)
        if charges and charges.currentCharges and charges.currentCharges > 0 then
            return true
        end

        local cooldown = C_Spell.GetSpellCooldown(action.data)
        return not cooldown or (cooldown.duration or 0) <= 0
    end

    if action.type == "item" then
        local hasToy = PlayerHasToy and PlayerHasToy(action.data)
        if hasToy and C_ToyBox and C_ToyBox.IsToyUsable and C_ToyBox.IsToyUsable(action.data) == false then
            hasToy = false
        end

        local itemCount = C_Item.GetItemCount and C_Item.GetItemCount(action.data) or 0
        if not hasToy and itemCount <= 0 then
            return false
        end
        if C_Item.IsUsableItem and C_Item.IsUsableItem(action.data) == false then
            return false
        end

        local duration = C_Item.GetItemCooldown and select(2, C_Item.GetItemCooldown(action.data)) or nil
        if duration == nil and C_Container and C_Container.GetItemCooldown then
            duration = select(2, C_Container.GetItemCooldown(action.data))
        end
        return (duration or 0) <= 0
    end

    return false
end

local function SelectAction(actionOptions)
    if type(actionOptions) ~= "table" then
        return nil
    end

    for _, action in ipairs(actionOptions) do
        if IsActionUsable(action) then
            return action
        end
    end

    return nil
end

--- Convert an APR world coordinate into a Farstrider UI-map coordinate.
---@param mapID number
---@param coord table
---@return number|nil uiMapID
---@return number|nil x
---@return number|nil y
local function WorldCoordToMapPosition(mapID, coord)
    if not APR:IsValidMapID(mapID) or not coord or coord.x == nil or coord.y == nil then
        return nil
    end

    local continentMapID = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0.5, 0.5))
    if not continentMapID then
        return nil
    end

    -- APR stores UnitPosition coordinates as { x = worldY, y = worldX }.
    local worldPosition = CreateVector2D(coord.y, coord.x)
    local uiMapID, mapPosition = C_Map.GetMapPosFromWorldPos(continentMapID, worldPosition, mapID)
    if not uiMapID or not mapPosition then
        return nil
    end

    return uiMapID, mapPosition.x, mapPosition.y
end

--- Convert a Farstrider location into the world-coordinate orientation used by APR.Arrow.
---@param location table
---@return number|nil x
---@return number|nil y
local function FarstriderLocationToArrowPosition(location)
    if not location or not location.pos then
        return nil
    end

    local worldPosition
    if location.isUI == false then
        worldPosition = CreateVector2D(location.pos.x, location.pos.y)
    else
        _, worldPosition = C_Map.GetWorldPosFromMapPos(
            location.mapId,
            CreateVector2D(location.pos.x, location.pos.y)
        )
    end

    if not worldPosition then
        return nil
    end

    return worldPosition.y, worldPosition.x
end

local function LocationsDiffer(a, b)
    if not a or not b or not a.pos or not b.pos then
        return false
    end

    if a.mapId ~= b.mapId or a.isUI ~= b.isUI then
        return true
    end

    return math.abs(a.pos.x - b.pos.x) > 0.00001 or
        math.abs(a.pos.y - b.pos.y) > 0.00001 or
        math.abs((a.pos.z or 0) - (b.pos.z or 0)) > 0.1
end

local function PathRequiresTravelAction(path)
    if type(path) ~= "table" or #path == 0 then
        return false
    end

    if #path > 1 then
        return true
    end

    local pathStep = path[1]
    return (type(pathStep.actionOptions) == "table" and #pathStep.actionOptions > 0) or
        LocationsDiffer(pathStep.loc, pathStep.completionLoc)
end

function APR.farstrider:IsNavigating()
    return self.activePathStep ~= nil and APR.IsInRouteZone == false
end

function APR.farstrider:ForceRefresh()
    local now = GetTime()
    if self._routingThrottle then
        self._routingThrottle.count = 0
        self._routingThrottle.firstCall = now
        self._routingThrottle.lastCall = 0
    end
    self._routingForceRefresh = true
end

function APR.farstrider:ClearNavigationUiLines()
    local currentStep = APR.currentStep
    if not currentStep or not currentStep.pendingRemoval then
        return
    end

    local inCombat = InCombatLockdown()
    for key, container in pairs(currentStep.questsList) do
        if APR:IsNavigationQuestUiKey(key) then
            if inCombat then
                currentStep:SoftHide(container)
                table.insert(currentStep.pendingContainerDestroy, container)
                currentStep.pendingButtonRequests[key] = nil
                currentStep.questsList[key] = nil
            else
                currentStep.pendingRemoval[key] = true
            end
        end
    end

    for key, container in pairs(currentStep.questsExtraTextList) do
        if APR:IsNavigationExtraTextUiKey(key) then
            if inCombat then
                currentStep:SoftHide(container)
                table.insert(currentStep.pendingContainerDestroy, container)
                currentStep.questsExtraTextList[key] = nil
            else
                currentStep.pendingRemoval[key] = true
            end
        end
    end

    if not inCombat and next(currentStep.pendingRemoval) then
        currentStep:FlushPendingContainers()
    end
end

function APR.farstrider:ClearActivePath()
    self.activePathStep = nil
end

function APR.farstrider:MarkRouteReady()
    local shouldRefreshStep = APR.IsInRouteZone == false or
        self.showOutOfZoneStepContent or self.activePathStep ~= nil
    APR.IsInRouteZone = true
    self.showOutOfZoneStepContent = false
    self._retryPending = false
    self:ClearActivePath()

    if shouldRefreshStep then
        self:ClearNavigationUiLines()
        APR.Arrow.currentStep = 0
        APR:UpdateStep()
    end
end

function APR.farstrider:ScheduleRouteCheck(stepToken)
    if not stepToken or self._scheduledStepToken == stepToken then
        return
    end

    self._scheduledStepToken = stepToken
    if self._stepCheckTimer then
        self._stepCheckTimer:Cancel()
    end

    self._stepCheckTimer = C_Timer.NewTimer(0.05, function()
        self._stepCheckTimer = nil
        local profile = APR:GetSettingsProfile()
        if not APR.ActiveRoute or not profile or not profile.enableAddon then
            return
        end

        self:ForceRefresh()
        self:GetMeToRightZone()
    end)
end

function APR.farstrider:OnArrowUpdate(distance)
    local pathStep = self.activePathStep
    if not pathStep then
        return
    end

    local arrivalDistance = distance
    if pathStep.checkDistance then
        local completionX, completionY = FarstriderLocationToArrowPosition(pathStep.completionLoc)
        local playerY, playerX = UnitPosition("player")
        if not completionX or not playerY then
            return
        end

        local dx = playerX - completionX
        local dy = playerY - completionY
        arrivalDistance = math.sqrt(dx * dx + dy * dy)
    end

    if arrivalDistance > ARRIVAL_DISTANCE then
        return
    end

    local now = GetTime()
    if self._lastArrivalCheck and now - self._lastArrivalCheck < 1 then
        return
    end

    self._lastArrivalCheck = now
    self:ForceRefresh()
    self:GetMeToRightZone(true)
end

function APR.farstrider:GetDestination(step, fallbackMapID)
    local preferredZone = APR:GetPreferredStepZone(step, fallbackMapID)
    if not preferredZone then
        return nil
    end

    local coord, coordZone = APR:GetStepCoord(step, fallbackMapID, preferredZone)
    local targetZone = coordZone or preferredZone
    if not coord then
        -- Zone-only steps (hearthstone, notes, some transport steps) still need
        -- a valid Farstrider goal. The zone centre lets the graph select the
        -- correct inter-map connection without restoring APR's old entry DB.
        return {
            mapID = targetZone,
            x = 0.5,
            y = 0.5,
            zone = targetZone,
        }
    end

    local uiMapID, x, y = WorldCoordToMapPosition(targetZone, coord)
    if not uiMapID then
        return {
            mapID = targetZone,
            x = 0.5,
            y = 0.5,
            zone = targetZone,
        }
    end

    return {
        mapID = uiMapID,
        x = x,
        y = y,
        zone = targetZone,
        worldCoord = coord,
    }
end

function APR.farstrider:ShowPathStep(path, destination)
    local pathStep = path and path[1] or nil
    if not pathStep or not pathStep.loc then
        return false
    end

    self.activePathStep = pathStep

    local action = SelectAction(pathStep.actionOptions)
    local instruction = pathStep.loca or L["PATH_NOT_FOUND"]

    if IsInInstance() and not action then
        instruction = L["LEAVE_INSTANCE"]
        APR.Arrow:SetArrowActive(false, 0, 0)
    else
        local arrowX, arrowY = FarstriderLocationToArrowPosition(pathStep.loc)
        if action then
            -- Action edges originate at the player's current position.
            APR.Arrow:SetArrowActive(false, 0, 0)
        elseif arrowX and arrowY then
            APR.Arrow:SetArrowActive(true, arrowX, arrowY)
        else
            self:ClearActivePath()
            return false
        end
    end

    local objectiveID = pathStep.id or destination.mapID
    APR.currentStep:AddQuestSteps(
        self.NavigationStepKey,
        instruction,
        objectiveID,
        nil,
        true,
        false
    )

    if action then
        APR.currentStep:AddStepButton(
            self.NavigationStepKey .. "-" .. tostring(objectiveID),
            action.data,
            action.type
        )
    end

    APR.currentStep:AddQuestDivider(self.NavigationDividerStepKey)
    return true
end

function APR.farstrider:ShowPathError(destination, detail)
    local mapInfo = destination and APR:GetMapInfoCached(destination.zone or destination.mapID) or nil
    local destinationName = mapInfo and mapInfo.name or UNKNOWN
    local suffix = detail and (" (" .. detail .. ")") or ""

    APR.currentStep:AddQuestSteps(
        self.ErrorStepKey,
        L["ERROR"] .. " - " .. L["PATH_NOT_FOUND"] .. " " .. destinationName .. suffix,
        destination and destination.mapID or 0,
        nil,
        true,
        false,
        self.ErrorTextColor
    )
    APR.currentStep:AddQuestDivider(self.NavigationDividerStepKey)
    APR.Arrow:SetArrowActive(false, 0, 0)
end

function APR.farstrider:GetMeToRightZone(isRetry)
    APR:Debug("Function: APR.farstrider:GetMeToRightZone()", isRetry and "(retry)" or "")

    local now = GetTime()
    if not self._routingThrottle then
        self._routingThrottle = { count = 0, firstCall = now, lastCall = 0 }
    end

    local throttle = self._routingThrottle
    if now - throttle.lastCall < 0.3 then
        return
    end

    if now - throttle.firstCall > 3 then
        throttle.count = 0
        throttle.firstCall = now
    end

    throttle.count = throttle.count + 1
    throttle.lastCall = now
    if throttle.count > 15 and not self._routingForceRefresh then
        return
    end
    self._routingForceRefresh = nil

    if not C_Map.GetBestMapForUnit("player") then
        APR:Debug("Farstrider: map API not ready")
        return
    end

    local playerContext = APR:ResolvePlayerZoneContext()
    if not playerContext.allRelevant or #playerContext.allRelevant == 0 then
        APR:Debug("Farstrider: player zone context is not ready")
        return
    end

    local routeZoneMapIDs, fallbackMapID, routeName = APR:GetCurrentRouteMapIDsAndName()
    if routeZoneMapIDs and fallbackMapID and routeName then
        APR.ActiveRoute = routeName
        if not APR.currentStep:IsShown() then
            APR.currentStep:RefreshCurrentStepFrameAnchor()
        end
    end

    if not APR.ActiveRoute or not APR.routeconfig:HasRouteInCustomPaht() then
        APR.routeconfig:CheckIsCustomPathEmpty()
        return
    end

    if not APR:IsInstanceWithUI() or
        (not APRCustomPath[APR.PlayerID] and not APR:IsTemporaryRouteActive()) then
        return
    end

    APR:UpdateQuestAndStep()
    local step = GetCurrentRouteStep()
    if not step then
        return
    end

    local destination = self:GetDestination(step, fallbackMapID)
    local farAway = false
    if destination and destination.worldCoord then
        local playerY, playerX = UnitPosition("player")
        if playerY and playerX then
            local dx = playerX - destination.worldCoord.x
            local dy = playerY - destination.worldCoord.y
            farAway = math.sqrt(dx * dx + dy * dy) > APR.Arrow.MaxDistanceWrongZone
        end
    end

    local requiresScenarioNavigation = RequiresScenarioNavigation(step)
    local isInRouteZone = APR:CheckIsInRouteZone()
    local api, missingDependencies = GetFarstriderAPI()
    local pathCallOk = false
    local optimizedPath
    if api and destination then
        pathCallOk, optimizedPath = pcall(
            api.FindTrailTo,
            destination.mapID,
            destination.x,
            destination.y,
            0
        )
        if not pathCallOk then
            APR:Debug("FarstriderLib FindTrailTo failed:", optimizedPath)
        end
    end

    local needsNavigation = not isInRouteZone or farAway or requiresScenarioNavigation or
        (pathCallOk and PathRequiresTravelAction(optimizedPath))
    if not needsNavigation then
        self:MarkRouteReady()
        return
    end

    APR.IsInRouteZone = false
    local wasShowingNavigation = self.showOutOfZoneStepContent
    self.showOutOfZoneStepContent = true
    self:ClearNavigationUiLines()
    self:ClearActivePath()

    if not wasShowingNavigation then
        APR.currentStep:RemoveQuestStepsAndExtraLineTexts()
        if APR.fillersFrame and APR.fillersFrame.RemoveFillerSteps then
            APR.fillersFrame:RemoveFillerSteps()
        end
    end

    if not destination then
        if not wasShowingNavigation then
            APR:UpdateStep()
        end
        self:ShowPathError(nil, L["PATH_ERROR_DESTINATION_MISSING"])
        return
    end

    if not isRetry and not self._retryPending then
        self._retryPending = true
        C_Timer.After(ROUTING_RETRY_DELAY, function()
            self._retryPending = false
            if APR.IsInRouteZone or not APR.ActiveRoute then
                return
            end

            APR:InvalidatePlayerZoneCache()
            APR._lastRouteZoneCheck = nil
            APR._lastRouteZoneResult = nil
            self:ForceRefresh()
            self:GetMeToRightZone(true)
        end)
    end

    local targetMapInfo = APR:GetMapInfoCached(destination.zone)
    local parentMapInfo = targetMapInfo and targetMapInfo.parentMapID and
        APR:GetMapInfoCached(targetMapInfo.parentMapID) or nil
    local reason = farAway and L["TOO_FAR_AWAY"] or L["WRONG_ZONE"]
    local destinationText = string.format(
        L["TRANSPORT_DESTINATION_ERROR"],
        reason,
        targetMapInfo and targetMapInfo.name or UNKNOWN,
        parentMapInfo and parentMapInfo.name or UNKNOWN,
        tostring(destination.zone)
    )
    APR.currentStep:AddExtraLineText(
        self.ErrorDestinationLineKey,
        destinationText,
        self.ErrorTextColor,
        false
    )

    if not wasShowingNavigation then
        APR:UpdateStep()
    end

    APR.Arrow:SetArrowActive(false, 0, 0)

    if not api then
        ReportMissingDependencies(missingDependencies)
        self:ShowPathError(
            destination,
            string.format(L["PATH_ERROR_DEPENDENCY_MISSING"], missingDependencies)
        )
        return
    end

    if not pathCallOk then
        self:ShowPathError(destination, L["PATH_ERROR_ROUTING_FAILED"])
        return
    end

    if not optimizedPath or #optimizedPath == 0 or not self:ShowPathStep(optimizedPath, destination) then
        self:ShowPathError(destination)
    end
end
