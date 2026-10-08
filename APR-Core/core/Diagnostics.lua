-- Captures public status data without advancing the route, and prepares readable sections for the status window.
-- Character identity is opt-in; inaccessible coordinates are omitted instead of being compared or formatted.

local function PublicNumber(value)
    if APR.CanAccessValue and not APR:CanAccessValue(value) then return end
    if type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then return value end
end

local function CaptureLocation()
    local location = {name = GetRealZoneText and GetRealZoneText()}
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    location.mapID = PublicNumber(mapID)
    if location.mapID and C_Map.GetPlayerMapPosition then
        local point = C_Map.GetPlayerMapPosition(location.mapID, "player")
        if (not APR.CanAccessValue or APR:CanAccessValue(point)) and point then
            local x, y = PublicNumber(point.x), PublicNumber(point.y)
            if x and y then location.x, location.y = x * 100, y * 100 end
        end
    end
    if UnitPosition then
        -- UnitPosition returns north/south first; APR displays east/west as X.
        local y, x, _, instance = UnitPosition("player")
        location.worldX, location.worldY, location.instance = PublicNumber(x), PublicNumber(y), PublicNumber(instance)
    end
    return location
end

function APR:BuildDiagnosticSnapshot(includeIdentity)
    local step, index = self:PeekCurrentStep()
    local reasons, action = self:DescribeStepWait()
    local profile = self:GetSettingsProfile() or {}
    local version, build, _, interface = GetBuildInfo()
    local cache = self.ZoneDetection and self.ZoneDetection.playerContextCache
    local zone = self.ZoneDetection and self.GetZoneDetectionReport and self:GetZoneDetectionReport()
    local location = CaptureLocation()
    location.continentID = zone and zone.playerContinent or (self.GetContinent and self:GetContinent())
    local continent = location.continentID and self.GetMapInfoCached and self:GetMapInfoCached(location.continentID)
    location.continent = continent and continent.name
    local route = self.RouteQuestStepList and self.RouteQuestStepList[self.ActiveRoute]
    local snapshot = {
        addon = self.version, client = version, build = build, interface = interface, locale = GetLocale(),
        capturedAt = date and date("%Y-%m-%d %H:%M:%S"), server = GetCVar and GetCVar("portal"),
        route = self.ActiveRoute, routeLabel = route and route.label, step = index, action = action,
        stepData = self:DeepCopyTable(step), revision = self.stepRevision, reasons = reasons, transitions = self:GetRecentTransitions(),
        canUndo = self:CanUndoManualSkip(), theme = "wow", skin = self:GetSkinProviderName() or "APR",
        combat = InCombatLockdown(), inRouteZone = self.IsInRouteZone, location = location,
        character = {faction = self.Faction, level = self.Level, class = self.ClassId,
            className = self.ClassId and self.GetClassNameById and self:GetClassNameById(self.ClassId)},
        settings = {enabled = profile.enableAddon, routeQuestsOnly = profile.autoAcceptQuestRoute,
            acceptAllQuests = profile.autoAccept, turnIn = profile.autoHandIn, gossip = profile.autoGossip,
            skipCutscenes = profile.autoSkipCutScene},
        zone = zone,
        routing = {updatePending = self.stepUpdateTimer ~= nil,
            renderPending = self.questOrderList and self.questOrderList.renderRequest ~= nil,
            renderFailed = self.questOrderList and self.questOrderList.renderFailed or false,
            zoneCacheAge = cache and cache.timestamp and math.max(0, GetTime() - cache.timestamp)},
        party = {rejected = self.party and self.party.rejectedMessages or 0,
            lastRejectReason = self.party and self.party.lastRejectReason},
        performance = self:DeepCopyTable(APRData and APRData.PerformanceLog and APRData.PerformanceLog.summary),
        captureActive = self.performanceLogging == true,
    }
    if includeIdentity then snapshot.player, snapshot.realm = self.Username, GetRealmName() end
    return snapshot
end

-- Every field from the former status window remains visible; the wait explanation is an additional section.
function APR:BuildDiagnosticSections(snapshot)
    local function T(key) return self:LocalizeUI(key) end
    local function value(item)
        if (self.CanAccessValue and not self:CanAccessValue(item)) or item == nil then return T("DATA_UNAVAILABLE") end
        if type(item) == "boolean" then return T(item and "YES" or "NO") end
        return tostring(item)
    end
    local function line(key, item) return T(key) .. ": " .. value(item) end
    local function coordinates(x, y)
        return x and y and string.format("%.2f, %.2f", x, y) or T("DATA_UNAVAILABLE")
    end
    local character, location, routing = snapshot.character, snapshot.location, snapshot.routing
    return {
        {title = T("STATUS_CLIENT"), lines = {
            line("STATUS_ADDON_VERSION", snapshot.addon),
            line("STATUS_CLIENT_VERSION", snapshot.client .. " / " .. snapshot.build),
            line("STATUS_INTERFACE", snapshot.interface), line("STATUS_LANGUAGE", snapshot.locale),
            line("STATUS_SERVER", snapshot.server), line("STATUS_DATE", snapshot.capturedAt),
            line("INTEGRATION", snapshot.skin),
        }},
        {title = T("STATUS_CHARACTER"), lines = {
            line("STATUS_NAME", snapshot.player or T("HIDDEN")), line("STATUS_REALM", snapshot.realm or T("HIDDEN")),
            line("STATUS_LEVEL", character.level), line("STATUS_CLASS", character.className or character.class),
            line("STATUS_FACTION", character.faction), line("STATUS_COMBAT", snapshot.combat),
        }},
        {title = T("STATUS_ROUTE"), lines = {
            line("STATUS_ROUTE", snapshot.routeLabel or snapshot.route),
            line("STATUS_ROUTE_KEY", snapshot.route), line("STATUS_STEP", snapshot.step), line("STATUS_ACTION", snapshot.action),
            line("STATUS_CONTINENT", location.continent or location.continentID), line("STATUS_ZONE", location.name),
            line("STATUS_MAP", location.mapID), line("COORDINATES", coordinates(location.x, location.y)),
            line("STATUS_WORLD_COORDS", coordinates(location.worldX, location.worldY)),
            line("STATUS_ROUTE_ZONE", snapshot.inRouteZone),
        }},
        {title = T("EXPLAIN"), lines = snapshot.reasons},
        {title = T("STATUS_RUNTIME"), lines = {
            line("ENABLE_ADDON", snapshot.settings.enabled), line("STATUS_UPDATE_PENDING", routing.updatePending),
            line("STATUS_RENDER_PENDING", routing.renderPending), line("STATUS_RENDER_FAILED", routing.renderFailed),
            line("STATUS_CACHE_AGE", routing.zoneCacheAge and string.format("%.1f s", routing.zoneCacheAge)),
            line("STATUS_REJECTED", snapshot.party.rejected), line("STATUS_LAST_REJECT", snapshot.party.lastRejectReason),
            line("STATUS_CAPTURE", snapshot.captureActive), line("STATUS_TRANSITIONS", #snapshot.transitions),
        }},
    }
end
