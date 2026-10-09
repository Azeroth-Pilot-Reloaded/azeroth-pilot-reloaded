-- Connects catalog/path notifications to the route engine; RouteBrowser owns selection and path editing.
-- Presets and progression keep their existing display-name path contract and navigation refresh behavior.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.routeconfig = APR:NewModule("routeconfig", "AceEvent-3.0")

function APR.routeconfig:InitRouteConfig()
    -- Catalog changes need not reset the active step or restart navigation.
    APR.routeconfig:RegisterMessage("APR_Route_Catalog_Update", function()
        APR.RouteBrowser:Refresh(true)
    end)

    APR.routeconfig:RegisterMessage("APR_Custom_Path_Update", function()
        -- to trigger the frame
        APR:Debug("Caller: APR.routeconfig:InitRouteConfig/Custom_Path_Update -> GetCurrentRouteMapIDsAndName")
        APR.currentStep:Reset()
        APR.Buff:RemoveAllBuffIcon()

        local routeZoneMapIDs, mapID, routeFileName, expansion = APR:GetCurrentRouteMapIDsAndName()
        APR:ActivateRoute(routeFileName)
        APR.XPBuffOverlay:QueueRefresh()

        APR:UpdateMapId()
        APR:UpdateStep()

        -- Invalidate zone check cache when route changes to ensure fresh detection
        APR._lastRouteZoneCheck = nil
        APR._lastRouteZoneResult = nil

        -- Trigger zone detection and navigation after loading new prefab routes
        local profile = APR:GetSettingsProfile()
        if APR.ActiveRoute and profile and profile.enableAddon then
            APR:InvalidatePlayerZoneCache()
        end

        -- Completing several routes can emit this message while a step is rendering.
        -- Rebuild the catalog/status once after the burst, outside the step transaction.
        if self.pathUiRefreshTimer then self.pathUiRefreshTimer:Cancel() end
        local timer
        timer = C_Timer.NewTimer(0.05, function()
            if self.pathUiRefreshTimer ~= timer then return end
            self.pathUiRefreshTimer = nil
            local profileStart = APR:StartPerformanceSample()
            APR.RouteBrowser:Refresh(true)
            if APR.StatusFrame and APR.StatusFrame:IsShown() and APR.updateStatusFrame then
                APR:updateStatusFrame()
            end
            APR:FinishPerformanceSample("RoutePathUiRefresh", profileStart)
        end)
        self.pathUiRefreshTimer = timer
    end)
    return {
        name = L["ROUTE_SELECTION"], type = "group",
        args = {
            openRoutes = {type = "execute", order = 1, name = L["OPEN_ROUTE_OPTIONS"],
                func = function() APR.RouteBrowser:Show() end},
        },
    }
end

function APR.routeconfig:SendCustomPathUpdate(suppressUpdate)
    if suppressUpdate or self._isBuildingSpeedrunPrefab then
        return
    end
    self:SendMessage("APR_Custom_Path_Update")
end

---------------------------------------------------------------------------------------
------------------------------ Route config function ----------------------------------
---------------------------------------------------------------------------------------

function APR.routeconfig:HasRouteInCustomPath()
    if APR:IsTemporaryRouteActive() then
        return true
    end

    if APRCustomPath[APR.PlayerID] and not next(APRCustomPath[APR.PlayerID]) then
        return false
    end
    return true
end

function APR.routeconfig:CheckIsCustomPathEmpty()
    APR:Debug("Function: APR.routeconfig:CheckIsCustomPathEmpty()")
    if not self:HasRouteInCustomPath() then
        APR:ActivateRoute(nil)
        APR.XPBuffOverlay:QueueRefresh()
        APR.currentStep:Reset()
        APR.Buff:RemoveAllBuffIcon()
        APR.currentStep:AddExtraLineText("NO_ROUTE", L["NO_ROUTE"])
        APR:SendMessage("APR_MAP_UPDATE")
        APR.map:RemoveMapLine()
        APR.map:RemoveMinimapLine()
        APR.questOrderList:AddStepFromRoute()
        APR.Arrow.Active = false
        APR.party:SendGroupMessage()
    end
end

function APR.routeconfig:CheckRouteResetOnLvlUp()
    if not APR:IsTableEmpty(APRCustomPath[APR.PlayerID]) then
        local _, currentRouteName = next(APRCustomPath[APR.PlayerID])
        local currentRouteKey = APR:GetRouteKeyFromDisplayName(currentRouteName)
        local currentRouteData = APR:GetRouteData(currentRouteKey)

        if currentRouteData and currentRouteData.notSkippable then
            return
        elseif APR.Level == 10 or APR.Level == APR.PreviousMaxLvl then
            if APR.Level == APR.PreviousMaxLvl and currentRouteData and
                currentRouteData.expansion == APR.EXPANSIONS.Midnight and
                currentRouteData.prefab and currentRouteData.prefab[APR.PREFAB_TYPES.Speedrun] then
                return
            end
            APR.questionDialog:CreateQuestionPopup("RESET_ROUTE_FOR_SPEEDRUN",
                string.format(L["RESET_ROUTE_FOR_SPEEDRUN"], APR.Level), function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetSpeedRunPrefab()
                end)
        elseif APR.Level == APR.MaxLevelChromie then
            APR.questionDialog:CreateQuestionPopup("RESET_ROUTE_FOR_TWW",
                string.format(L["RESET_ROUTE_FOR_TWW"], APR.Level),
                function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:BuildLevelingPrefab(APR.EXPANSIONS.TheWarWithin)
                end)
        end
    end
end
