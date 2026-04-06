local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.transport = APR:NewModule("Transport")

APR.transport.CurrentTaxiNode = {}
APR.transport.StepTaxiNode = {}
APR.transport.ErrorDestinationLineKey = "00_ERROR_DESTINATION"
APR.transport.ErrorDividerLineKey = "00A_ERROR_DIVIDER"
APR.transport.TransportDividerStepKey = "03_TRANSPORT_DIVIDER"
APR.transport.ErrorTextColor = (APR.HEXColor and APR.HEXColor.red) or "ff3333"
APR.transport.showOutOfZoneStepContent = false

-- Internal retry flag
APR.transport._retryPending = false

-- Remove only transport/out-of-zone generated UI lines, keep normal step lines.
function APR.transport:ClearTransportUiLines()
    local currentStep = APR.currentStep
    if not currentStep or not currentStep.pendingRemoval then
        return
    end

    for key, _ in pairs(currentStep.questsList) do
        if APR:IsTransportQuestUiKey(key) then
            currentStep.pendingRemoval[key] = true
        end
    end

    for key, _ in pairs(currentStep.questsExtraTextList) do
        if APR:IsTransportExtraTextUiKey(key) then
            currentStep.pendingRemoval[key] = true
        end
    end

    if next(currentStep.pendingRemoval) then
        currentStep:FlushPendingContainers()
    end
end

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

-- Find the closest transport (spell/item) to target coordinates.
-- scope = "continent" (any zone on target continent) or "zone" (exact zone).
-- Returns the transport that teleports closest to targetX, targetY.
local function _FindClosestTransport(kind, db, targetCont, targetZone, scope, targetX, targetY)
    if not db or not targetX or not targetY then return nil end

    local closestPick = nil
    local closestDistance = math.huge

    for _, e in ipairs(db) do
        local okCont = (e.nextContinent == targetCont)
        local okZone = (scope == "continent") or (e.nextZone == targetZone)
        if okCont and okZone and e.coords then
            local id = (kind == "spell") and e.spellID or e.itemID
            if _IsAvailable(kind, id) then
                -- Calculate distance between teleport destination and objective
                local dx = targetX - e.coords.x
                local dy = targetY - e.coords.y
                local distance = math.sqrt(dx * dx + dy * dy)

                if distance < closestDistance then
                    closestDistance = distance
                    local name = (kind == "spell") and APR:GetSpellName(id) or APR:GetItemName(id)
                    closestPick = {
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

    return closestPick
end
-----------------------------------------------------------------------
-- Main router: priority depends on same/different continent
-- Same continent: SwitchZones (physical portals/passages) only
-- Different continent: spell > item > SwitchCont portals > taxi
-----------------------------------------------------------------------
function APR.transport:SelectBestTransport(nextZone, step, mapID)
    local CurContinent = APR:GetContinent()
    local targetContinent = APR:GetContinent(nextZone)
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local isCurrentIsolated = currentMapID and APR.ZoneRestrictions.IsIsolatedMap(currentMapID)
    local isTargetIsolated = APR.ZoneRestrictions.IsIsolatedMap(nextZone)

    -- If same continent, skip teleport spells/items and use SwitchZones directly
    if CurContinent == targetContinent and not isCurrentIsolated and not isTargetIsolated then
        local portal = self:GuideViaPortalDB(APR.Portals.SwitchZones[APR.Faction], CurContinent, targetContinent,
            nextZone)
        if portal then return true end
        return false
    end

    -- Different continent: try teleport spells/items first
    -- Get step coordinates to find closest transport
    local stepCoord = step and mapID and APR:GetStepCoord(step, mapID, nextZone)
    local targetX = stepCoord and stepCoord.x
    local targetY = stepCoord and stepCoord.y

    -- Priority chain: now using closest transport if coordinates available
    local pick = nil
    if targetX and targetY then
        pick =
            _FindClosestTransport("spell", APR.Portals.Spells, targetContinent, nextZone, "continent", targetX, targetY) or
            _FindClosestTransport("spell", APR.Portals.Spells, targetContinent, nextZone, "zone", targetX, targetY) or
            _FindClosestTransport("item", APR.Portals.Items, targetContinent, nextZone, "continent", targetX, targetY) or
            _FindClosestTransport("item", APR.Portals.Items, targetContinent, nextZone, "zone", targetX, targetY)
    else
        -- Fallback to first available if no coordinates
        pick =
            _FindFirst("spell", APR.Portals.Spells, targetContinent, nextZone, "continent") or
            _FindFirst("spell", APR.Portals.Spells, targetContinent, nextZone, "zone") or
            _FindFirst("item", APR.Portals.Items, targetContinent, nextZone, "continent") or
            _FindFirst("item", APR.Portals.Items, targetContinent, nextZone, "zone")
    end

    if pick then
        local transportKeyPrefix = APR.IsInRouteZone and "" or "01_"
        if pick.kind == "spell" then
            -- EXACT UI you requested
            local spellID = pick.id
            local spellName = pick.name
            local questText = string.format(L["USE_SPELL"], spellName or UNKNOWN)
            local transportStepKey = transportKeyPrefix .. "USE_SPELL"
            APR.currentStep:AddQuestSteps(transportStepKey, questText, spellName, nil, nil, false)
            APR.currentStep:AddStepButton(transportStepKey .. "-" .. spellName, spellID, "spell")
        else
            -- EXACT UI for items
            local itemID = pick.id
            local itemName = pick.name
            local questText = string.format(L["USE_ITEM"], itemName or UNKNOWN)
            local transportStepKey = transportKeyPrefix .. "USE_ITEM"
            APR.currentStep:AddQuestSteps(transportStepKey, questText, itemName, nil, nil, false)
            APR.currentStep:AddStepButton(transportStepKey .. "-" .. itemName, itemID, "item")
        end

        if pick.coords then
            local nz = APR:GetMapInfoCached(nextZone)
            APR.currentStep:AddExtraLineText("DESTINATION", string.format(L["DESTINATION"], nz and nz.name or ""),
                self.ErrorTextColor)
        end

        -- Teleports are instant (no arrow); zone change will refresh the flow.
        return true
    end

    -- Portals fallback: same continent uses SwitchZones, cross-continent uses SwitchCont
    local portalDB = (CurContinent == targetContinent)
        and APR.Portals.SwitchZones[APR.Faction]
        or APR.Portals.SwitchCont[APR.Faction]
    local portal = self:GuideViaPortalDB(portalDB, CurContinent, targetContinent, nextZone)

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
        APR.currentStep:AddQuestSteps("01_FLY_TO_" .. destTaxiName, string.format(L["FLY_TO"], destTaxiName),
            destTaxiName, nil, nil, false)
        APR.currentStep:AddQuestSteps("02_CLOSEST_FP" .. closestTaxiName,
            string.format(L["CLOSEST_FP"], closestTaxiName),
            closestTaxiName, nil, nil, false)
        self.wrongZoneDestTaxiName = destTaxiName
    end

    -- Pick the best matching portal (exact nextZone preferred, else closest backup).
    local portal, portalPos = handlePortals(portalDB)
    local selectedFromCapitalFallback = false

    -- Fallback: direct to default capital room
    if not portal and portalDB == APR.Portals.SwitchCont[APR.Faction] then
        if APR.Faction == "Alliance" then
            portal, portalPos = handlePortalsCapital(portalDB, 13, 84) -- Stormwind
        else
            portal, portalPos = handlePortalsCapital(portalDB, 12, 85) -- Orgrimmar
        end
        selectedFromCapitalFallback = portal and true or false
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

    if portal then
        APR:PrintZoneDebug(string.format(
            "Transport selected portal: key=%s | fromCont=%s | toCont=%s | toZone=%s | dist=%.1f | fallbackCapital=%s",
            tostring(portal.portalKey),
            tostring(portal.continent),
            tostring(portal.nextContinent),
            tostring(portal.nextZone),
            playerDistance,
            tostring(selectedFromCapitalFallback)
        ))
    end

    local playerNodeId, playerNodeName, playerNodeX, playerNodeY = self:ClosestTaxi(px, py)
    local _, portalNodeName, _, _, _ = self:ClosestTaxi(portalPos.x, portalPos.y)
    local hasFlyOrDragonRiding = APR:IsSpellKnown(90265) or APR:IsSpellKnown(372608) -- Master Riding or dragonriding
    local canFlyInCurrentZone = hasFlyOrDragonRiding and not APR:IsInNoFlyZone()

    --Same FP or can fly/dragonride close enough: go to portal directly
    if (playerNodeName == portalNodeName or (canFlyInCurrentZone and playerDistance < APR.Arrow.MaxDistanceWrongZone)) and portal then
        -- Special case: Alliance Stormwind portal room (keep original behavior)
        if APR.Faction == "Alliance" and CurContinent == 13 then
            local posY, posX = UnitPosition("player")
            if posY and posX and (posY > -8981.3 and posX < 866.7) then
                APR.currentStep:AddQuestSteps("01_GO_PORTAL_ROOM", L["GO_PORTAL_ROOM"], "GO_PORTAL_ROOM", nil, nil, false)
                local room = APR.Portals.Coords["Alliance"][CurContinent]["StormwindPortalRoom"]
                APR.Arrow:SetArrowActive(true, room.x, room.y)
                return portal
            end
        end
        local extraText = portal.extraText or "USE_PORTAL_TO"
        local portalMapInfo = APR:GetMapInfoCached(portal.nextZone)
        local newZoneName = (portalMapInfo and portalMapInfo.name) or UNKNOWN
        local localized = L[extraText]
        -- Use format only if the locale string expects a %s; otherwise, just append the name.
        if localized and localized:find("%%s") then
            APR.currentStep:AddQuestSteps("01_PORTAL_" .. portal.portalKey, string.format(localized, newZoneName),
                portal.portalKey, nil, nil, false)
        else
            APR.currentStep:AddQuestSteps("01_PORTAL_" .. portal.portalKey, localized .. " " .. newZoneName,
                portal.portalKey, nil, nil, false)
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
        APR.ZonesData.ZoneMoveOrder[currentMapID] and APR.ZonesData.ZoneMoveOrder[currentMapID][nextMapId]
    if not zoneMoveOrder then
        return
    end

    local continent = APR:GetContinent()
    local zoneEntries = APR.ZonesData.ZoneEntry[continent] and APR.ZonesData.ZoneEntry[continent][zoneMoveOrder]
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
-- Core: Guide the player into the right zone
-----------------------------------------------------------------------
function APR.transport:GetMeToRightZone(isRetry)
    APR:Debug("Function: APR.transport:GetMeToRightZone()", isRetry and "(retry)" or "")

    -- Throttle: max 5 rapid checks with 300ms intervals, then only on zone change events
    local now = GetTime()
    if not self._routingThrottle then
        self._routingThrottle = { count = 0, firstCall = now, lastCall = 0 }
    end

    local throttle = self._routingThrottle
    local elapsed = now - throttle.lastCall

    -- Enforce 300ms minimum between calls
    if elapsed < 0.3 then
        return
    end

    -- Reset counter if window expired (3 seconds since first call)
    if (now - throttle.firstCall) > 3 then
        throttle.count = 0
        throttle.firstCall = now
    end

    throttle.count = throttle.count + 1
    throttle.lastCall = now

    -- After 5 checks, only proceed if a zone event reset the flag
    if throttle.count > 15 and not self._routingForceRefresh then
        return
    end
    self._routingForceRefresh = nil

    -- Guard: if the map API is not ready yet (loading screen / transition), bail out.
    -- The delayed PLAYER_ENTERING_WORLD timer will retry once the data is stable.
    local bestMap = C_Map.GetBestMapForUnit("player")
    if not bestMap then
        APR:Debug("GetMeToRightZone: map API not ready (nil), skipping")
        return
    end

    -- Additional guard: verify the player zone context is actually populated.
    -- After a teleport the map API may already return a mapID but the full zone
    -- hierarchy (parent chain, continent) may still be empty / stale.  In that
    -- case we must NOT declare "wrong zone" - just bail out and let the PEW
    -- progressive timers or future ZONE_CHANGED events handle the next check.
    local preCheckContext = APR:ResolvePlayerZoneContext()
    if not preCheckContext.allRelevant or #preCheckContext.allRelevant == 0 then
        APR:Debug("GetMeToRightZone: player zone context empty (transitioning), skipping")
        return
    end

    local routeZoneMapIDs, mapID, routeName, expansion = APR:GetCurrentRouteMapIDsAndName()

    if (routeZoneMapIDs and mapID and routeName) then
        APR.ActiveRoute = routeName
        if not APR.currentStep:IsShown() then
            APR.currentStep:RefreshCurrentStepFrameAnchor()
        end
    end
    if not APR.ActiveRoute or not APR.routeconfig:HasRouteInCustomPaht() then
        APR.routeconfig:CheckIsCustomPathEmpty()
        return
    end
    if not APR:IsInstanceWithUI() or (not APRCustomPath[APR.PlayerID] and not APR:IsTemporaryRouteActive()) then
        return
    end

    APR:UpdateQuestAndStep()
    local currentStepIndex = APRData[APR.PlayerID][APR.ActiveRoute]
    local currentRouteSteps = APR:GetRouteSteps(APR.ActiveRoute)
    local step = currentRouteSteps and currentStepIndex and currentRouteSteps[currentStepIndex] or nil

    -- Compute actual distance from player to step coords (not from stale arrow coords).
    -- APR.Arrow.Distance comes from self.x/self.y which may be stale when IsInRouteZone is false,
    -- because SetCoord() only updates arrow coords when IsInRouteZone is true.
    -- This circular dependency makes the farAway check wrong, so we recalculate here.
    local farAway = false
    if step then
        local posY, posX = UnitPosition("player")
        local stepCoordCheck = APR:GetStepCoord(step, step.Zone or mapID, APR:GetPlayerParentMapID())
        if posY and posX and stepCoordCheck then
            local dx, dy = posX - stepCoordCheck.x, posY - stepCoordCheck.y
            local realDist = (dx * dx + dy * dy) ^ 0.5
            farAway = realDist > APR.Arrow.MaxDistanceWrongZone
        end
    else
        farAway = APR.Arrow.Distance > APR.Arrow.MaxDistanceWrongZone
    end
    if APR:CheckIsInRouteZone() and not farAway then
        local wasOutOfZone = not APR.IsInRouteZone
        local wasShowingOutOfZoneStepContent = self.showOutOfZoneStepContent
        APR.IsInRouteZone = true
        self.showOutOfZoneStepContent = false
        -- Avoid unwanted auto taxi
        self.wrongZoneDestTaxiName = nil
        -- Reset flag, we are in the right zone
        self._retryPending = false
        -- If we were previously in any out-of-zone UI mode, refresh step to clear stale text
        if wasOutOfZone or wasShowingOutOfZoneStepContent then
            APR:UpdateStep()
        end
        return
    else
        -- Reset IsInRouteZone and continue routing
        APR.IsInRouteZone = false
        local wasShowingOutOfZoneStepContent = self.showOutOfZoneStepContent
        self.showOutOfZoneStepContent = true
        -- Always clear previous transport/out-of-zone lines before building new guidance.
        -- This prevents stacked errors/instructions after rapid zone transitions.
        self:ClearTransportUiLines()

        if not wasShowingOutOfZoneStepContent then
            APR.currentStep:RemoveQuestStepsAndExtraLineTexts()
            if APR.fillersFrame and APR.fillersFrame.RemoveFillerSteps then
                APR.fillersFrame:RemoveFillerSteps()
            end
        end

        if not step then
            return
        end

        local nextZone = APR:GetPreferredStepZone(step, mapID)
        if not nextZone then
            return
        end
        local mapInfo = APR:GetMapInfoCached(nextZone)
        if not mapInfo then
            return
        end

        local parentMapInfo = mapInfo.parentMapID and APR:GetMapInfoCached(mapInfo.parentMapID) or nil

        -- Retry: if this is the first detection of wrong zone (not already a
        -- retry), schedule a delayed re-check.  After a teleport/portal the zone
        -- data may still be settling; one extra check often resolves a false
        -- "wrong zone" flash.
        if not isRetry and not self._retryPending then
            self._retryPending = true
            C_Timer.After(1.5, function()
                self._retryPending = false
                if APR.IsInRouteZone then return end
                if not APR.ActiveRoute then return end
                APR:InvalidatePlayerZoneCache()
                APR._lastRouteZoneCheck = nil
                APR._lastRouteZoneResult = nil
                if self._routingThrottle then
                    self._routingThrottle.count = 0
                    self._routingThrottle.firstCall = GetTime()
                end
                self._routingForceRefresh = true
                self:GetMeToRightZone(true)
            end)
        end

        local reason = farAway and L["TOO_FAR_AWAY"] or L["WRONG_ZONE"]
        local parentMapName = parentMapInfo and parentMapInfo.name or "?"
        local destinationText = string.format(L["TRANSPORT_DESTINATION_ERROR"], reason, mapInfo.name or "?",
            parentMapName, tostring(nextZone))
        APR.currentStep:AddExtraLineText(self.ErrorDestinationLineKey, destinationText, self.ErrorTextColor, false)

        if not wasShowingOutOfZoneStepContent then
            APR:UpdateStep()
        end

        -- Hide arrow while computing routing
        APR.Arrow.Active = false

        -- Full router (Spells / Items / SwitchZones / SwitchCont)
        if self:SelectBestTransport(nextZone, step, mapID) then
            APR.currentStep:AddQuestDivider(self.TransportDividerStepKey)
            -- Either a teleport instruction or portal/taxi path has been displayed.
            -- If it's an instance step, refresh the UI immediately.
            if step.InstanceQuest then
                APR.IsInRouteZone = true
                APR:UpdateStep()
            end
            return
        end

        -- If same continent and nothing found above, try classic taxi -> zone entry fallbacks
        if APR:IsSameContinent(nextZone) then
            local posY, posX = UnitPosition("player")
            if not posY or not posX then
                return
            end

            local currentMapID = APR:GetPlayerParentMapID()
            local isCurrentIsolated = currentMapID and APR.ZoneRestrictions.IsIsolatedMap(currentMapID)
            local isTargetIsolated = APR.ZoneRestrictions.IsIsolatedMap(nextZone)
            local playerTaxiNodeId, playerTaxiName, playerTaxiX, playerTaxiY = self:ClosestTaxi(posX, posY)
            local stepCoord = APR:GetStepCoord(step, mapID, nextZone)

            -- For isolated zones without valid coords, still force taxi route
            if not stepCoord and isTargetIsolated then
                APR.currentStep:AddQuestSteps("01_ISOLATED_ZONE_TAXI",
                    L["ISOLATED_ZONE_TAXI"] or "Isolated zone - use taxi only", "TAXI", nil, nil, false)
                APR.currentStep:AddQuestSteps("02_CLOSEST_FP" .. playerTaxiName,
                    string.format(L["CLOSEST_FP"], playerTaxiName), playerTaxiName, nil, nil, false)
                APR.currentStep:AddQuestDivider(self.TransportDividerStepKey)
                APR.Arrow:SetArrowActive(true, playerTaxiX, playerTaxiY)
                return
            end

            if stepCoord then
                local _, objectiveTaxiName = self:ClosestTaxi(stepCoord.x, stepCoord.y)
                if playerTaxiNodeId ~= objectiveTaxiName then
                    self.wrongZoneDestTaxiName = objectiveTaxiName
                    APR.currentStep:AddQuestSteps("01_FLY_TO_" .. objectiveTaxiName,
                        string.format(L["FLY_TO"], objectiveTaxiName),
                        objectiveTaxiName, nil, nil, false)
                    APR.currentStep:AddQuestSteps("02_CLOSEST_FP" .. playerTaxiName,
                        string.format(L["CLOSEST_FP"], playerTaxiName), playerTaxiName, nil, nil, false)
                    APR.currentStep:AddQuestDivider(self.TransportDividerStepKey)
                    APR.Arrow:SetArrowActive(true, playerTaxiX, playerTaxiY)
                    return
                else
                    if isCurrentIsolated or isTargetIsolated then
                        return
                    end
                    local zoneEntryMapID, zoneEntryX, zoneEntryY = self:GetZoneMoveOrder(nextZone)
                    if zoneEntryMapID then
                        local zoneEntryMapInfo = APR:GetMapInfoCached(zoneEntryMapID)
                        if zoneEntryMapInfo then
                            APR.currentStep:AddQuestSteps(
                                "01_GO_TO" .. (zoneEntryMapInfo.name or ""),
                                string.format(L["GO_TO"], zoneEntryMapInfo.name or "?"),
                                zoneEntryMapInfo.name,
                                nil,
                                nil,
                                false
                            )
                            APR.currentStep:AddQuestDivider(self.TransportDividerStepKey)
                            APR.Arrow:SetArrowActive(true, zoneEntryX, zoneEntryY)
                            return
                        end
                    end

                    -- Same continent, same taxi area, no ZoneMoveOrder data:
                    -- Point arrow directly to step coordinates (adjacent zone, walk/fly there)
                    local targetMapInfo = APR:GetMapInfoCached(nextZone)
                    APR.currentStep:AddQuestSteps(
                        "01_GO_TO" .. (targetMapInfo and targetMapInfo.name or "?"),
                        string.format(L["GO_TO"], targetMapInfo and targetMapInfo.name or "?"),
                        targetMapInfo and targetMapInfo.name or "?",
                        nil,
                        nil,
                        false
                    )
                    APR.currentStep:AddQuestDivider(self.TransportDividerStepKey)
                    APR.Arrow:SetArrowActive(true, stepCoord.x, stepCoord.y)
                    return
                end
            end
        end

        -- Total fallback: no route found
        if APR:IsInstanceWithUI() then
            APR.currentStep:AddQuestSteps("01_WRONG_ZONE_INSTANCE", L["WRONG_ZONE_INSTANCE"], nextZone, nil, nil, false,
                self.ErrorTextColor)
            APR.currentStep:AddQuestDivider(self.TransportDividerStepKey)
            APR.Arrow:SetArrowActive(false, 0, 0)
            return
        end

        APR.currentStep:AddQuestSteps(
            "01_ERROR_PATH_NOT_FOUND",
            L["ERROR"] .. " - " .. L["PATH_NOT_FOUND"] .. " " .. (mapInfo.name or "??") .. " (" .. tostring(mapID) .. ")",
            mapID,
            nil,
            nil,
            false,
            self.ErrorTextColor
        )
        APR.currentStep:AddQuestDivider(self.TransportDividerStepKey)
        APR:PrintError(L["PATH_NOT_FOUND"] .. " " .. (mapInfo.name or "??"))
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
