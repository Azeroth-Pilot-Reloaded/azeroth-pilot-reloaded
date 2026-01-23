local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.transport = APR:NewModule("Transport")

APR.transport.CurrentTaxiNode = {}
APR.transport.StepTaxiNode = {}

-- Internal retry flag
APR.transport._retryPending = false

-----------------------------------------------------------------------
-- SelectBestTransport Helpers: Spells & Items
-----------------------------------------------------------------------

-- Availability check (spell known / item owned).
local function _IsAvailable(kind, id)
    if kind == "spell" then
        return APR:IsSpellKnown(id)
    else
        return APR:PlayerHasItem(id)
    end
end

-- Generic finder over DBs (Spells or Items).
-- scope = "continent" (any zone on target continent) or "zone" (exact zone).
-- Returns a unified pick { kind, id, name, coords, nextContinent, nextZone } or nil.
local function _FindFirst(kind, db, targetCont, targetZone, scope)
    if not db then return nil end
    for _, e in ipairs(db) do
        local okCont = (e.nextContinent == targetCont)
        local okZone = (scope == "continent") or (e.nextZone == targetZone)
        if okCont and okZone then
            local id = (kind == "spell") and e.spellID or e.itemID
            if _IsAvailable(kind, id) then
                local name = (kind == "spell") and APR:GetSpellName(id) or APR:GetItemName(id)
                return {
                    kind = kind,
                    id = id,
                    name = name,
                    coords = e.coords,
                    nextContinent = e.nextContinent,
                    nextZone = e.nextZone,
                }
            end
        end
    end
end
-----------------------------------------------------------------------
-- Main router: priority = spell continent > spell zone > item continent > item zone > portals > taxi
-----------------------------------------------------------------------
function APR.transport:SelectBestTransport(nextZone)
    local CurContinent = APR:GetContinent()
    local _, targetContinent = self:IsSameContinent(nextZone)

    -- Priority chain:
    local pick =
        _FindFirst("spell", APR.Portals.Spells, targetContinent, nextZone, "continent") or -- spell continent
        _FindFirst("spell", APR.Portals.Spells, targetContinent, nextZone, "zone") or      -- spell zone
        _FindFirst("item", APR.Portals.Items, targetContinent, nextZone, "continent") or   -- item continent
        _FindFirst("item", APR.Portals.Items, targetContinent, nextZone, "zone")           -- item zone

    if pick then
        if pick.kind == "spell" then
            -- EXACT UI you requested
            local spellID = pick.id
            local spellName = pick.name
            local questText = L["USE_SPELL"] .. ": " .. (spellName or UNKNOWN)
            APR.currentStep:AddQuestSteps("USE_SPELL", questText, spellName)
            APR.currentStep:AddStepButton("USE_SPELL-" .. spellName, spellID, "spell")
        else
            -- EXACT UI for items
            local itemID = pick.id
            local itemName = pick.name
            local questText = L["USE_ITEM"] .. ": " .. (itemName or UNKNOWN)
            APR.currentStep:AddQuestSteps("USE_ITEM", questText, itemName)
            APR.currentStep:AddStepButton("USE_ITEM-" .. itemName, itemID, "item")
        end

        if pick.coords then
            local nz = C_Map.GetMapInfo(nextZone)
            APR.currentStep:AddExtraLineText("DESTINATION", L["DESTINATION"] .. " " .. (nz and nz.name or ""))
        end

        -- Teleports are instant (no arrow); zone change will refresh the flow.
        return true
    end

    -- Portals fallback: same continent -> SwitchZones ; different continent -> SwitchCont
    local db = (CurContinent == targetContinent) and APR.Portals.SwitchZones[APR.Faction] or
        APR.Portals.SwitchCont[APR.Faction]
    local portal = self:GuideViaPortalDB(db, CurContinent, targetContinent, nextZone)

    if portal then return true end

    return false
end

-----------------------------------------------------------------------
-- Portal guidance engine for SwitchCont / SwitchZones
-----------------------------------------------------------------------
--- Drive the UI/Arrow/Taxis to the best portal from a given portal DB.
--- portalDB must be APR.Portals.SwitchCont[APR.Faction] OR APR.Portals.SwitchZones[APR.Faction].
function APR.transport:GuideViaPortalDB(portalDB, CurContinent, nextContinent, nextZone)
    local function handlePortals(portalMappings)
        local closestPortal, closestPos, closestDist
        local backupPortal, backupPos, backupDist
        local py, px = UnitPosition("player")
        if not py or not px then
            return
        end

        for _, portal in ipairs(portalMappings) do
            if CurContinent == portal.continent and nextContinent == portal.nextContinent then
                local pos = APR.Portals.Coords[APR.Faction][portal.continent][portal.portalKey]
                if pos then
                    local d = math.sqrt((px - pos.x) ^ 2 + (py - pos.y) ^ 2)
                    if nextZone == portal.nextZone then
                        if not closestDist or d < closestDist then
                            closestPortal, closestPos, closestDist = portal, pos, d
                        end
                    else
                        if not backupDist or d < backupDist then
                            backupPortal, backupPos, backupDist = portal, pos, d
                        end
                    end
                end
            end
        end

        if closestPortal then
            return closestPortal, closestPos
        end
        if backupPortal then
            return backupPortal, backupPos
        end
        return nil, nil
    end

    local function handlePortalsCapital(portalMappings, capitalNextContinent, capitalNextZone)
        for _, portal in ipairs(portalMappings) do
            if
                CurContinent == portal.continent and
                (capitalNextContinent == portal.nextContinent or capitalNextZone == portal.nextZone)
            then
                local pos = APR.Portals.Coords[APR.Faction][portal.continent][portal.portalKey]
                if pos then
                    return portal, pos
                end
            end
        end
    end

    local function handleTaxi(closestTaxiName, destTaxiName)
        APR.currentStep:AddExtraLineText("FLY_TO_" .. destTaxiName, L["FLY_TO"] .. " " .. destTaxiName)
        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. closestTaxiName, L["CLOSEST_FP"] .. ": " .. closestTaxiName)
        self.wrongZoneDestTaxiName = destTaxiName
    end

    -- Pick the best matching portal (exact nextZone preferred, else closest backup).
    local portal, portalPos = handlePortals(portalDB)

    -- Fallback: direct to default capital room
    if not portal and portalDB == APR.Portals.SwitchCont[APR.Faction] then
        if APR.Faction == "Alliance" then
            portal, portalPos = handlePortalsCapital(portalDB, 13, 84) -- Stormwind
        else
            portal, portalPos = handlePortalsCapital(portalDB, 12, 85) -- Orgrimmar
        end
    end
    if not portalPos then
        return nil
    end

    -- Taxi vs run: if we share the same FP or Dragonriding can cover it, point straight to the portal.
    local py, px = UnitPosition("player")
    if not py or not px then
        return
    end
    local dx, dy = px - portalPos.x, portalPos.y - py
    local playerDistance = (dx * dx + dy * dy) ^ 0.5

    local playerNodeId, playerNodeName, playerNodeX, playerNodeY = self:ClosestTaxi(px, py)
    local _, portalNodeName, _, _, _ = self:ClosestTaxi(portalPos.x, portalPos.y)
    local hasFlyOrDragonRiding = APR:IsSpellKnown(90265) or APR:IsSpellKnown(372608) -- Master Riding or dragonriding

    --Same FP or can fly/dragonride close enough: go to portal directly
    if (playerNodeName == portalNodeName or (hasFlyOrDragonRiding and playerDistance < APR.Arrow.MaxDistanceWrongZone)) and portal then
        -- Special case: Alliance Stormwind portal room (keep original behavior)
        if APR.Faction == "Alliance" and CurContinent == 13 then
            local posY, posX = UnitPosition("player")
            if posY and posX and (posY > -8981.3 and posX < 866.7) then
                APR.currentStep:AddExtraLineText("GO_PORTAL_ROOM", L["GO_PORTAL_ROOM"])
                local room = APR.Portals.Coords["Alliance"][CurContinent]["StormwindPortalRoom"]
                APR.Arrow:SetArrowActive(true, room.x, room.y)
                return portal
            end
        end
        local extraText = portal.extraText or "USE_PORTAL_TO"
        local newZoneName = (C_Map.GetMapInfo(portal.nextZone) and C_Map.GetMapInfo(portal.nextZone).name) or UNKNOWN
        local localized = L[extraText]
        -- Use format only if the locale string expects a %s; otherwise, just append the name.
        if localized and localized:find("%%s") then
            APR.currentStep:AddExtraLineText(portal.portalKey, string.format(localized, newZoneName))
        else
            APR.currentStep:AddExtraLineText(portal.portalKey, localized .. " " .. newZoneName)
        end

        APR.Arrow:SetArrowActive(true, portalPos.x, portalPos.y)
    else
        -- Different FPs: point to the closest taxinode to reach the portal FP.
        handleTaxi(playerNodeName, portalNodeName)
        APR.Arrow:SetArrowActive(true, playerNodeX, playerNodeY)
    end

    return portal
end

-----------------------------------------------------------------------
-- Get the closest flight path
-----------------------------------------------------------------------
--- Get Closest TaxiNode to a world position.
--- @param posX number
--- @param posY number
--- @return integer|nil nodeId
--- @return string|nil name
--- @return number|nil x
--- @return number|nil y
--- @return number|nil distance
function APR.transport:ClosestTaxi(posX, posY)
    APR:Debug("Function: APR.transport:ClosestTaxi()", { posX, posY })

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
        return neutralNodeId, (APRTaxiNodes[APR.PlayerID][neutralNodeId] or neutralName), neutralX, neutralY,
            neutralDistance
    else
        return closestNodeId, (APRTaxiNodes[APR.PlayerID][closestNodeId] or closestName), closestX, closestY,
            closestDistance
    end
end

-----------------------------------------------------------------------
-- Intra-zone entry guidance
-----------------------------------------------------------------------
--- Return the next MapID and world position of zone entry towards nextMapId.
--- @param nextMapId number
--- @return number|nil zoneMoveOrder
--- @return number|nil closestX
--- @return number|nil closestY
function APR.transport:GetZoneMoveOrder(nextMapId)
    local currentMapID = APR:GetPlayerParentMapID()
    local zoneMoveOrder =
        APR.ZonesData["ZoneMoveOrder"][currentMapID] and APR.ZonesData["ZoneMoveOrder"][currentMapID][nextMapId]
    if not zoneMoveOrder then
        return
    end

    local continent = APR:GetContinent()
    local zoneEntries = APR.ZonesData["ZoneEntry"][continent] and APR.ZonesData["ZoneEntry"][continent][zoneMoveOrder]
    if not zoneEntries then
        return nil, nil, nil
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

-----------------------------------------------------------------------
-- Same-continent check
-----------------------------------------------------------------------
--- Checks if a given mapID is on the same continent as the player.
--- @param mapID number The map ID to check.
--- @return boolean isSameContinent
--- @return number newContinent
function APR.transport:IsSameContinent(mapID)
    APR:Debug("Function: APR.transport:IsSameContinent()", mapID)
    local playerContinentID = APR:GetContinent()
    local mapContinentID = APR:GetContinent(mapID)
    local isSameContinent = (playerContinentID == mapContinentID)
    return isSameContinent, mapContinentID
end

-----------------------------------------------------------------------
-- Core: Guide the player into the right zone
-----------------------------------------------------------------------
function APR.transport:GetMeToRightZone(isRetry)
    APR:Debug("Function: APR.transport:GetMeToRightZone()", isRetry and "(retry)" or "")

    local routeZoneMapIDs, mapID, routeName, expansion = APR:GetCurrentRouteMapIDsAndName()

    if (routeZoneMapIDs and mapID and routeName) then
        APR.ActiveRoute = routeName
        if not APR.currentStep:IsShown() then
            APR.currentStep:RefreshCurrentStepFrameAnchor()
        end
    end
    if not APR.ActiveRoute or not next(APRCustomPath[APR.PlayerID]) then
        APR.routeconfig:CheckIsCustomPathEmpty()
        return
    end
    if not APR:IsInstanceWithUI() or not APRCustomPath[APR.PlayerID] then
        return
    end

    APR:UpdateQuestAndStep()
    local currentStepIndex = APRData[APR.PlayerID][APR.ActiveRoute]
    local currentRouteSteps = APR.RouteQuestStepList[APR.ActiveRoute]
    local step = currentRouteSteps and currentStepIndex and currentRouteSteps[currentStepIndex] or nil

    local farAway = APR.Arrow.Distance > APR.Arrow.MaxDistanceWrongZone
    if APR:CheckIsInRouteZone() and not farAway then
        APR.IsInRouteZone = true
        -- Avoid unwanted auto taxi
        self.wrongZoneDestTaxiName = nil
        -- Reset flag, we are in the right zone
        self._retryPending = false
        return
    else
        -- Reset IsInRouteZone and continue routing
        APR.IsInRouteZone = false

        if not step then
            return
        end

        local nextZone = APR:GetPreferredStepZone(step, mapID)
        if not nextZone then
            return
        end
        local mapInfo = C_Map.GetMapInfo(nextZone)
        if not mapInfo then
            return
        end

        local parentMapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
        if not parentMapInfo then
            return
        end

        -- Retry systems (Disabled)
        if not isRetry and not self._retryPending then
            -- no logic for now
        end

        local reason = farAway and L["TOO_FAR_AWAY"] or L["WRONG_ZONE"]
        APR.currentStep:Reset()
        local destinationText =
            reason ..
            " - " ..
            L["DESTINATION"] ..
            ": " ..
            (mapInfo.name or "?") ..
            ", " .. (parentMapInfo.name or "?") .. " (" .. tostring(nextZone) .. ")"
        APR.currentStep:AddExtraLineText("DESTINATION", destinationText)

        -- Hide arrow while computing routing
        APR.Arrow.Active = false

        -- Full router (Spells / Items / SwitchZones / SwitchCont)
        if self:SelectBestTransport(nextZone) then
            -- Either a teleport instruction or portal/taxi path has been displayed.
            -- If it's an instance step, refresh the UI immediately.
            if step.InstanceQuest then
                APR.IsInRouteZone = true
                APR:UpdateStep()
            end
            return
        end

        -- If same continent and nothing found above, try classic taxi -> zone entry fallbacks
        local isSameContinent = (APR:GetContinent() == APR:GetContinent(nextZone))
        if isSameContinent then
            local posY, posX = UnitPosition("player")
            if not posY or not posX then
                return
            end

            local playerTaxiNodeId, playerTaxiName, playerTaxiX, playerTaxiY = self:ClosestTaxi(posX, posY)
            local stepCoord = APR:GetStepCoord(step, mapID, nextZone)
            if stepCoord then
                local _, objectiveTaxiName = self:ClosestTaxi(stepCoord.x, stepCoord.y)
                if playerTaxiNodeId ~= objectiveTaxiName then
                    self.wrongZoneDestTaxiName = objectiveTaxiName
                    APR.currentStep:AddExtraLineText(
                        "FLY_TO_" .. objectiveTaxiName,
                        L["FLY_TO"] .. " " .. objectiveTaxiName
                    )
                    APR.currentStep:AddExtraLineText(
                        "CLOSEST_FP" .. playerTaxiName,
                        L["CLOSEST_FP"] .. ": " .. playerTaxiName
                    )
                    APR.Arrow:SetArrowActive(true, playerTaxiX, playerTaxiY)
                    return
                else
                    local zoneEntryMapID, zoneEntryX, zoneEntryY = self:GetZoneMoveOrder(nextZone)
                    if zoneEntryMapID then
                        local zoneEntryMapInfo = C_Map.GetMapInfo(zoneEntryMapID)
                        APR.currentStep:AddExtraLineText(
                            "GO_TO" .. (zoneEntryMapInfo.name or ""),
                            string.format(L["GO_TO"], zoneEntryMapInfo.name or "?")
                        )
                        APR.Arrow:SetArrowActive(true, zoneEntryX, zoneEntryY)
                        return
                    end
                end
            end
        end

        -- Total fallback: no route found
        APR.currentStep:AddExtraLineText(
            "ERROR_PATH_NOT_FOUND",
            L["ERROR"] .. " - " .. L["PATH_NOT_FOUND"] .. " " .. (mapInfo.name or "?") .. " (" .. tostring(mapID) .. ")"
        )
        APR:PrintError(L["PATH_NOT_FOUND"] .. " " .. (mapInfo.name or "?"))
        APR.Arrow:SetArrowActive(false, 0, 0)
    end
end

-----------------------------------------------------------------------
-- Event frame
-----------------------------------------------------------------------
APR.transport.eventFrame = CreateFrame("Frame")
APR.transport.eventFrame:RegisterEvent("TAXIMAP_OPENED")
APR.transport.eventFrame:RegisterEvent("PLAYER_CONTROL_LOST")
APR.transport.eventFrame:SetScript("OnEvent", function(self, event, ...)
    if not APR.settings.profile.enableAddon then
        return
    end

    local step = APR.ActiveRoute and APR:GetStep(APRData[APR.PlayerID][APR.ActiveRoute]) or nil
    if APR.settings.profile.showEvent then
        APR:PrintInfo("EVENT: Transport - " .. event)
    end

    if (event == "TAXIMAP_OPENED") then
        ------------------------------------------
        --------------- Save FP ------------------
        ------------------------------------------
        local taxiMapID = GetTaxiMapID()
        local taxiNodes = C_TaxiMap.GetAllTaxiNodes(taxiMapID)

        for _, node in ipairs(taxiNodes) do
            if node.state ~= Enum.FlightPathState.Unreachable and not APRTaxiNodes[APR.PlayerID][node.nodeID] then
                APRTaxiNodes[APR.PlayerID][node.nodeID] = node.name
            end
            if node.state == Enum.FlightPathState.Current then
                APR.transport.CurrentTaxiNode = node
            end
            if step then
                if step.NodeID == node.nodeID then
                    APR.transport.StepTaxiNode = node
                end
            end
        end
        -------------------------------------------
        --------------- Auto Flight----------------
        -------------------------------------------
        if step then
            if step.UseFlightPath or APR.transport.wrongZoneDestTaxiName then
                if APR.transport.CurrentTaxiNode.nodeID == APR.transport.StepTaxiNode.nodeId then
                    APR:NextQuestStep()
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
                if step and step.ETA then
                    APR.AFK:SetAfkTimer(step.ETA)
                elseif next(APR.transport.CurrentTaxiNode) and next(APR.transport.StepTaxiNode) then
                    -- Record timer or play if already known
                    local timer = APRTaxiNodesTimer
                        [APR.transport.CurrentTaxiNode.name .. "-" .. APR.transport.StepTaxiNode.name]
                    if not timer then
                        APR.AFK.TaxiTimerRecorder:Play()
                    else
                        APR.AFK:SetAfkTimer(timer)
                    end
                end
                if step and step.UseFlightPath and not APR.transport.wrongZoneDestTaxiName then
                    APR:UpdateNextStep()
                end
                -- reset
                APR.transport.wrongZoneDestTaxiName = nil
            end
        end)
    end
end)
