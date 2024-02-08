local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.transport = APR:NewModule("Transport")

APR.transport.CurrentTaxiNode = {}
APR.transport.StepTaxiNode = {}

--- Guide the player to the right zone / continent / taxi / position
function APR.transport:GetMeToRightZone()
    if (APR.settings.profile.debug) then
        print("Function: APR.transport:GetMeToRightZone()")
    end

    local routeZoneMapIDs, mapID, routeName, expansion = self:GetRouteMapIDsAndName()
    if (routeZoneMapIDs and mapID and routeName) then
        APR.ActiveRoute = routeName
    end
    if not APR.ActiveRoute or not next(APRCustomPath[APR.PlayerID]) then
        APR.routeconfig:CheckIsCustomPathEmpty()
        return
    end
    if not APR:IsInInstanceQuest() or not APRCustomPath[APR.PlayerID] then
        return
    end

    _G.UpdateQuestAndStep()
    local farAway = APR.Arrow.Distance > APR.Arrow.MaxDistanceWrongZone
    if CheckIsInRouteZone() and not farAway then
        APR.IsInRouteZone = true
        -- To avoid unwanted auto taxi
        APR.transport.wrongZoneDestTaxiName = nil
        return
    else
        -- reset the is in route bool
        APR.IsInRouteZone = false
        APR.currentStep:RemoveQuestStepsAndExtraLineTexts()
        local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
        if not CurStep then
            return
        end
        local step = APR.RouteQuestStepList[APR.ActiveRoute][CurStep]
        if not step then
            return
        end
        local nextZone = step.Zone or mapID
        local mapInfo = C_Map.GetMapInfo(nextZone)
        if not mapInfo then
            return
        end
        local parentMapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
        if not parentMapInfo then
            return
        end

        local reason = ""
        if farAway then
            reason = L["TOO_FAR_AWAY"]
        else
            reason = L["WRONG_ZONE"]
        end
        local destinationText = reason ..
            " - " .. L["DESTINATION"] .. ": " .. mapInfo.name .. ", " .. parentMapInfo.name .. " (" .. nextZone .. ")"
        APR.currentStep:AddExtraLineText("DESTINATION", destinationText)
        -- Hide the arrow
        APR.Arrow.Active = false
        local currentContinent = APR:GetContinent()
        local isSameContinent, nextContinent = self:IsSameContinent(nextZone)
        if not isSameContinent then
            self:GetPortal(currentContinent, nextContinent, nextZone)
            return
        else
            local portal = self:GetPortal(currentContinent, nextContinent, nextZone)
            if portal then
                --portal found donc need to check the closestTaxi
                return
            end
            local posY, posX = UnitPosition("player")
            local playerTaxiNodeId, playerTaxiName, playerTaxiX, playerTaxiY = self:ClosestTaxi(posX, posY)
            if step.Coord then
                local _, objectiveTaxiName, _, _ = self:ClosestTaxi(step.Coord.x, step.Coord.y)
                if playerTaxiNodeId ~= objectiveTaxiName then
                    APR.transport.wrongZoneDestTaxiName = objectiveTaxiName
                    APR.currentStep:AddExtraLineText("FLY_TO_" .. objectiveTaxiName,
                        L["FLY_TO"] .. " " .. objectiveTaxiName)
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. playerTaxiName,
                        L["CLOSEST_FP"] .. ": " .. playerTaxiName)
                    APR.Arrow:SetArrowActive(true, playerTaxiX, playerTaxiY)
                    return
                else
                    local zoneEntryMapID, zoneEntryX, zoneEntryY = self:GetZoneMoveOrder(nextZone, playerMapInfo)
                    if zoneEntryMapID then
                        local zoneEntryMapInfo = C_Map.GetMapInfo(zoneEntryMapID)
                        APR.currentStep:AddExtraLineText("GO_TO" .. zoneEntryMapInfo.name,
                            L["GO_TO"] .. ": " .. zoneEntryMapInfo.name)
                        APR.Arrow:SetArrowActive(true, zoneEntryX, zoneEntryY)
                        return
                    end
                end
            end
            APR.currentStep:AddExtraLineText("ERROR_PATH_NOT_FOUND", L["ERROR"] ..
                " - " .. L["PATH_NOT_FOUND"] .. " " .. mapInfo.name .. " (" .. mapID .. ")")
            APR:PrintError(L["PATH_NOT_FOUND"] .. " " .. mapInfo.name)
            APR.Arrow:SetArrowActive(false, 0, 0)
        end
    end
end

--- Get Route zone mapID and name
---@return Array<number> routeZoneMapIDs MapIDs list of the mapid for the route
---@return number mapID  the main mapid for the route
---@return string routeFileName Route File Name
---@return string expansion expansion name
function APR.transport:GetRouteMapIDsAndName()
    if (APR.settings.profile.debug) then
        print("Function: APR.transport:GetRouteMapIDAndName()")
    end

    if not APRCustomPath or not APRCustomPath[APR.PlayerID] then
        APR:PrintError('No APRCustomPath')
        return
    end
    -- Get the current Route wanted MapIDs and Route File
    local _, currentRouteName = next(APRCustomPath[APR.PlayerID])
    for expansion, routeList in pairs(APR.RouteList) do
        for routeFileName, routeName in pairs(routeList) do
            if routeName == currentRouteName then
                APR.routeconfig:LoadRouteAddonFile(expansion)
                return APR.ZonesData.ExtensionRouteMaps[APR.Faction][expansion], APR.RouteMainMapID[routeName],
                    routeFileName, expansion
            end
        end
    end
end

--- Retrun the next MapIDs and worl position zone entry
--- @param nextMapId number the wanted zone ID to reach
--- @param currentMapID number you current zone ID
--- @return number zoneMoveOrder
--- @return number closestX
--- @return number closestY
function APR.transport:GetZoneMoveOrder(nextMapId, currentMapID)
    local zoneMoveOrder = APR.ZonesData["ZoneMoveOrder"][currentMapID] and
        APR.ZonesData["ZoneMoveOrder"][currentMapID][nextMapId]
    if not zoneMoveOrder then
        return
    end

    local continent = APR:GetContinent()
    local zoneEntries = APR.ZonesData["ZoneEntry"][continent] and APR.ZonesData["ZoneEntry"][continent][zoneMoveOrder]
    if not zoneEntries then
        return
    end

    local closestDistance = math.huge
    local closestX, closestY = 0, 0
    local playerY, playerX = UnitPosition("player")

    for _, entry in pairs(zoneEntries) do
        local deltaX, deltaY = playerX - entry.x, entry.y - playerY
        local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)

        if distance < closestDistance then
            closestDistance = distance
            closestX, closestY = entry.x, entry.y
        end
    end

    return zoneMoveOrder, closestX, closestY
end

--- Checks if a given mapID is on the same continent as the player.
--- @param mapID number The map ID to check.
--- @return boolean isSameContinent true if the mapID is on the same continent as the player, false otherwise.
--- @return number newContient new contient ID
function APR.transport:IsSameContinent(mapID)
    if (APR.settings.profile.debug) then
        print("Function: APR.transport:IsSameContinent()")
    end
    local playerContinentID = APR:GetContinent()
    local mapContinentID = APR:GetContinent(mapID)

    local isSameContinent = (playerContinentID == mapContinentID)
    return isSameContinent, mapContinentID
end

--- Set the current step frame and arrow with the new continent data*
---@param CurContinent number the contient map ID
---@param nextContinent number the wanted reachable contient map ID
---@param nodeId number the wanted zone ID to reach in the nextContinent
function APR.transport:GetPortal(CurContinent, nextContinent, nextZone)
    local function handlePortals(portalMappings)
        local closestPortal, closestPortalPosition, closestDistance = nil, nil, nil
        local playerY, playerX = UnitPosition("player")
        if not playerY or not playerX then
            return
        end

        for _, portal in ipairs(portalMappings) do
            if CurContinent == portal.continent and (nextContinent == portal.nextContinent or nextZone == portal.nextZone) then
                local portalPosition = APR.Portals[APR.Faction][portal.continent][portal.portalKey]
                local distance = math.sqrt((playerX - portalPosition.x) ^ 2 + (playerY - portalPosition.y) ^ 2)

                if closestDistance == nil or distance < closestDistance then
                    closestPortal = portal
                    closestPortalPosition = portalPosition
                    closestDistance = distance
                end
            end
        end

        return closestPortal, closestPortalPosition
    end

    local function handlePortalsCapital(portalMappings, capitalNextContinent, capitalNextZone)
        for _, portal in ipairs(portalMappings) do
            if CurContinent == portal.continent and (capitalNextContinent == portal.nextContinent or capitalNextZone == portal.nextZone) then
                local portalPosition = APR.Portals[APR.Faction][portal.continent][portal.portalKey]
                return portal, portalPosition
            end
        end
    end

    local function handleTaxi(closestTaxiName, destTaxiName)
        APR.currentStep:AddExtraLineText("FLY_TO_" .. destTaxiName, L["FLY_TO"] .. " " .. destTaxiName)
        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. closestTaxiName, L["CLOSEST_FP"] .. ": " .. closestTaxiName)
        APR.transport.wrongZoneDestTaxiName = destTaxiName
    end

    -- Portal
    local portalsDB = APR.ZonesData.SwitchCont[APR.Faction]
    local portal, portalPosition = handlePortals(portalsDB)

    -- If no portal is found, redirect to the default capital
    if not portal then
        if APR.Faction == "Alliance" then
            portal, portalPosition = handlePortalsCapital(portalsDB, 13, 84) -- Stormwind
        else
            portal, portalPosition = handlePortalsCapital(portalsDB, 12, 85) -- Orgrimmar
        end
    end
    if not portalPosition then
        -- local nextZoneMapInfo = C_Map.GetMapInfo(nextZone)
        -- APR:PrintError(L["PATH_NOT_FOUND"] .. " " .. nextZoneMapInfo.name)
        return
    end

    -- TaxiNode
    local posY, posX = UnitPosition("player")
    local playerTaxiNodeId, playerTaxiName, playerTaxiX, playerTaxiY = self:ClosestTaxi(posX, posY)
    local portalTaxiNodeId, portalTaxiName, _, _ = self:ClosestTaxi(portalPosition.x, portalPosition.y)

    if playerTaxiNodeId == portalTaxiNodeId then
        -- handle the Alliance portals room
        if APR.Faction == "Alliance" and CurContinent == 13 and (posY > -8981.3 and posX < 866.7) then
            APR.currentStep:AddExtraLineText("GO_PORTAL_ROOM", L["GO_PORTAL_ROOM"])
            local portalRoom = APR.Portals["Alliance"][CurContinent]["StormwindPortalRoom"]
            APR.Arrow:SetArrowActive(true, portalRoom.x, portalRoom.y)
        else
            local extraText = portal.extraText or "USE_PORTAL_TO"
            APR.currentStep:AddExtraLineText(portal.portalKey,
                L[extraText] .. " " .. C_Map.GetMapInfo(portal.nextZone).name)
            APR.Arrow:SetArrowActive(true, portalPosition.x, portalPosition.y)
        end
    else
        handleTaxi(playerTaxiName, portalTaxiName)
        APR.Arrow:SetArrowActive(true, playerTaxiX, playerTaxiY)
    end
    return portal
end

--- Get Closes TaxiNode
--- @param posX number the world X position to find the closestDistance
--- @param posY number the world Y position to find the closestDistance
--- @return string nodeId Taxi node id
--- @return string name Taxi node name
--- @return number x Taxi node X position
--- @return number y Taxi node Y position
function APR.transport:ClosestTaxi(posX, posY)
    if (APR.settings.profile.debug) then
        print("Function: APR.transport:ClosestTaxi()")
    end

    local continent = APR:GetContinent()
    local function findClosestTaxi(faction)
        local closestDistance = math.huge
        local closestNodeId, closestName, closestX, closestY = nil, nil, 0, 0

        if APR.TaxiNodes[faction] and APR.TaxiNodes[faction][continent] then
            for nodeId, taxi in pairs(APR.TaxiNodes[faction][continent]) do
                local taxiX, taxiY = taxi.x, taxi.y
                local deltaX, deltaY = posX - taxiX, taxiY - posY
                local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)

                if distance < closestDistance then
                    closestDistance = distance
                    closestName = taxi.Name
                    closestX = taxiX
                    closestY = taxiY
                    closestNodeId = nodeId
                end
            end
        end

        return closestNodeId, closestName, closestX, closestY, closestDistance
    end

    local closestNodeId, closestName, closestX, closestY, closestDistance = findClosestTaxi(APR.Faction)
    local neutralNodeId, neutralName, neutralX, neutralY, neutralDistance = findClosestTaxi("Neutral")

    if neutralDistance < closestDistance then
        return neutralNodeId, (APRTaxiNodes[APR.PlayerID][neutralNodeId] or neutralName), neutralX, neutralY
    else
        return closestNodeId, (APRTaxiNodes[APR.PlayerID][closestNodeId] or closestName), closestX, closestY
    end
end

APR.transport.eventFrame = CreateFrame("Frame")
APR.transport.eventFrame:RegisterEvent("TAXIMAP_OPENED")
APR.transport.eventFrame:RegisterEvent("PLAYER_CONTROL_LOST")
APR.transport.eventFrame:RegisterEvent("ZONE_CHANGED")
APR.transport.eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
APR.transport.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
APR.transport.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
APR.transport.eventFrame:RegisterEvent("WAYPOINT_UPDATE")
APR.transport.eventFrame:SetScript("OnEvent", function(self, event, ...)
    local steps = APR.ActiveRoute and GetSteps(APRData[APR.PlayerID][APR.ActiveRoute]) or nil
    if APR.settings.profile.showEvent then
        print("EVENT: Transport - ", event)
    end
    if not APR.settings.profile.enableAddon then
        return
    end
    if event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "WAYPOINT_UPDATE"
        or event == "PLAYER_ENTERING_WORLD" then
        if APR.IsInRouteZone then
            APR.transport:GetMeToRightZone()
        end
    elseif (event == "TAXIMAP_OPENED") then
        ------------------------------------------
        --------------- Save FP ------------------
        ------------------------------------------

        local playerMapID = APR:GetPlayerParentMapID()
        local taxiNodes = C_TaxiMap.GetAllTaxiNodes(playerMapID)

        for _, node in ipairs(taxiNodes) do
            if node.state ~= Enum.FlightPathState.Unreachable and not APRTaxiNodes[APR.PlayerID][node.nodeID] then
                APRTaxiNodes[APR.PlayerID][node.nodeID] = node.name
            end
            if node.state == Enum.FlightPathState.Current then
                APR.transport.CurrentTaxiNode = node
            end
            if steps then
                if steps.NodeID == node.nodeID then
                    APR.transport.StepTaxiNode = node
                end
            end
        end
        -------------------------------------------
        --------------- Auto Flight----------------
        -------------------------------------------
        if steps then
            if steps.UseFlightPath or APR.transport.wrongZoneDestTaxiName then
                if APR.transport.CurrentTaxiNode.nodeID == APR.transport.StepTaxiNode.nodeId then
                    NextQuestStep()
                elseif not IsModifierKeyDown() then
                    for taxiIndex = 1, _G.NumTaxiNodes() do
                        local name = _G.TaxiNodeName(taxiIndex)
                        if name == APR.transport.StepTaxiNode.name or name == APR.transport.wrongZoneDestTaxiName then
                            if APR.settings.profile.autoFlight then
                                TakeTaxiNode(taxiIndex)
                            end
                            break
                        end
                    end
                end
            end
        end
    elseif event == "PLAYER_CONTROL_LOST" then
        C_Timer.After(2, function()
            if UnitOnTaxi("player") then
                if steps and steps.ETA then
                    APR.AFK:SetAfkTimer(steps.ETA)
                elseif next(APR.transport.CurrentTaxiNode) and next(APR.transport.StepTaxiNode) then
                    -- Reccord timer or play if already in the table
                    local timer = APRTaxiNodesTimer
                        [APR.transport.CurrentTaxiNode.name .. "-" .. APR.transport.StepTaxiNode.name]
                    if not timer then
                        APR.AFK.TaxiTimerRecorder:Play()
                    else
                        APR.AFK:SetAfkTimer(timer)
                    end
                end
                if steps and steps.UseFlightPath and not APR.transport.wrongZoneDestTaxiName then
                    UpdateNextStep()
                end
                -- reset
                APR.transport.wrongZoneDestTaxiName = nil
            end
        end)
    end
end)
