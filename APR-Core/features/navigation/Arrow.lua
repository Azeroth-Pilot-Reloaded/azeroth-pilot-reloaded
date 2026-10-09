-- Updates the navigation arrow, arrival checks and distance display at the configured cadence.
-- Farstrider owns travel segments; StepUtils supplies the shared runtime route step.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")


-- Initialize module
APR.Arrow = APR:NewModule("Arrow")


local ARROW_TEXTURES = {
    classic = "Interface\\Addons\\APR\\APR-Core\\assets\\Arrow.blp",
    apr = "Interface\\Addons\\APR\\APR-Core\\assets\\Arrow-APR.tga",
}
local TEXTURE_COLUMNS = 9
local TEXTURE_ROWS = 12
local CELL_WIDTH = 56
local CELL_HEIGHT = 42
local APR_STYLE_SCALE = 1.8
local IDLE_CHECK_INTERVAL = 1

local mathAbs, mathAtan2, mathFloor = math.abs, math.atan2, math.floor

APR.Arrow.currentStep = 0
APR.Arrow.Active = false
APR.Arrow.x = 0
APR.Arrow.y = 0
APR.Arrow.Distance = 0
APR.Arrow.QuestStepDistance = 0
APR.Arrow.MaxDistanceWrongZone = APR:GetGameVersion() == APR.GAME_VERSIONS.Forever and 1000 or 10000
APR.Arrow.isWrongZoneDistance = false
APR.Arrow.arrowUpdateRate = 0
APR.Arrow.frameTicker = 0

local function DistanceBetween(ax, ay, bx, by)
    local dx, dy = ax - bx, by - ay
    return (dx * dx + dy * dy) ^ 0.5
end

local function SaveArrowPosition()
    APR.settings.profile.arrowleft = APR.ArrowFrameM:GetLeft()
    APR.settings.profile.arrowtop = APR.ArrowFrameM:GetTop() - GetScreenHeight()
    APR.ArrowFrameM:ClearAllPoints()
    APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.arrowleft,
        APR.settings.profile.arrowtop)
end

local function ShouldShowArrow()
    if not APR.settings.profile.showArrow then return false end
    if not APR.Arrow.Active then return false end
    if APR.Arrow.x == 0 then return false end
    if APR:IsPetBattleActive() then return false end
    if not APR:IsInstanceWithUI() then return false end
    return true
end

local function GetArrowColor(percentage)
    if percentage > 0.98 then
        return 0, 1, 0
    elseif percentage > 0.5 then
        return (1 - percentage) * 2, 1, 0
    end
    return 1, percentage * 2, 0
end

---------------------------------------------------------------------------------------
----------------------------------- Arrow Frames --------------------------------------
---------------------------------------------------------------------------------------

APR.ArrowFrameM = CreateFrame("Button", "APR_Arrow", UIParent)
APR.ArrowFrameM:SetHeight(1)
APR.ArrowFrameM:SetWidth(1)
APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
APR.ArrowFrameM:EnableMouse(true)
APR.ArrowFrameM:SetMovable(true)


APR.ArrowFrame = CreateFrame("Button", "APR_Arrow", UIParent)
APR.ArrowFrame:SetHeight(CELL_HEIGHT)
APR.ArrowFrame:SetWidth(CELL_WIDTH)
APR.ArrowFrame:SetPoint("TOPLEFT", APR.ArrowFrameM, "TOPLEFT", 0, 0)
APR.ArrowFrame:EnableMouse(true)
APR.ArrowFrame:SetMovable(true)
APR.ArrowFrame.arrow = APR.ArrowFrame:CreateTexture(nil, "OVERLAY")
APR.ArrowFrame.arrow:SetTexture(ARROW_TEXTURES.classic)
APR.ArrowFrame.arrow:SetAllPoints()
-- Resize the artwork's frame independently; text and its action share a separate scale.
APR.ArrowFrame.textFrame = CreateFrame("Frame", nil, APR.ArrowFrame)
APR.ArrowFrame.textFrame:SetSize(1, 1)
APR.ArrowFrame.textFrame:SetPoint("TOP", APR.ArrowFrame, "BOTTOM", 0, 0)
APR.ArrowFrame.distance = APR.ArrowFrame.textFrame:CreateFontString("distance", "ARTWORK", "ChatFontNormal")
APR.ArrowFrame.distance:SetPoint("TOP", APR.ArrowFrame.textFrame, "TOP", 0, 0)
APR:RegisterFontString(APR.ArrowFrame.distance, "arrow", { role = "base", sizeDelta = -2 })
APR.ArrowFrame:Hide()
APR.ArrowFrame:SetScript("OnMouseDown", function(self, button) --Mouse clicking arrowframe
    if button == "LeftButton" and not APR.ArrowFrameM.isMoving and not APR.settings.profile.lockArrow then
        APR.ArrowFrameM:StartMoving()
        APR.ArrowFrameM.isMoving = true
    end
end)
--Mouse unclicking arrowframe (releasing mouse)
APR.ArrowFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and APR.ArrowFrameM.isMoving then
        APR.ArrowFrameM:StopMovingOrSizing()
        APR.ArrowFrameM.isMoving = false
        SaveArrowPosition()
    end
end)
--When arrowframe hides
APR.ArrowFrame:SetScript("OnHide", function(self)
    if APR.ArrowFrameM.isMoving then
        APR.ArrowFrameM:StopMovingOrSizing() -- prevent it from moving or rescaling in the background, it cant be seen anyway
        APR.ArrowFrameM.isMoving = false
        SaveArrowPosition()
    end
end)

APR.ArrowFrame:SetScript("OnUpdate", function(self, tick)
    if not APR.ArrowFrame:IsShown() then return end

    APR.Arrow.frameTicker = APR.Arrow.frameTicker + tick
    if APR.Arrow.frameTicker < APR.Arrow.arrowUpdateRate then return end
    APR.Arrow.frameTicker = 0

    APR.Arrow:UpdatePosition()
end)


APR.ArrowFrame.Button = CreateFrame("Button", "APR_ArrowActiveButton", APR.ArrowFrame.textFrame)
APR.ArrowFrame.Button:SetPoint("TOP", APR.ArrowFrame.distance, "BOTTOM", 0, -6)
APR.ArrowFrame.Button:SetScript("OnMouseDown", function(self, button)
    APR.ArrowFrame.Button:Hide()
    APR:PrintInfo("APR: " .. L["SKIP_WAYPOINT"])
    APR:NextQuestStep()
end)

local t = APR.ArrowFrame.Button:CreateTexture(nil, "BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ArrowFrame.Button)
APR.ArrowFrame.Button.texture = t
if APR.RegisterSkinTarget then APR:RegisterSkinTarget(APR.ArrowFrame.Button, "button") end

APR.ArrowFrame.Fontstring = APR.ArrowFrame:CreateFontString("CLSettingsFS2212", "ARTWORK", "ChatFontNormal")
APR.ArrowFrame.Fontstring:SetParent(APR.ArrowFrame.Button)
APR.ArrowFrame.Fontstring:SetPoint("CENTER", APR.ArrowFrame.Button)
APR.ArrowFrame.Fontstring:SetText(L["SKIP_WAYPOINT"])
APR.ArrowFrame.Fontstring:SetWordWrap(true)
APR:RegisterFontString(APR.ArrowFrame.Fontstring, "arrow", { role = "warning", sizeDelta = -2 })

local function UpdateSkipButtonTextLayout()
    APR.ArrowFrame.Fontstring:SetWidth(0)
    local textWidth = APR.ArrowFrame.Fontstring:GetStringWidth() + 10
    local skipWidth = textWidth < 85 and math.max(45, textWidth) or 85
    APR.ArrowFrame.Fontstring:SetWidth(skipWidth)
    local skipHeight = APR.ArrowFrame.Fontstring:GetStringHeight() + 10
    APR.ArrowFrame.Button:SetSize(skipWidth, skipHeight)
end

UpdateSkipButtonTextLayout()
APR.ArrowFrame.Button:Hide()

---------------------------------------------------------------------------------------
--------------------------------- Arrow Function --------------------------------------
---------------------------------------------------------------------------------------


function APR.Arrow:Init()
    -- Restore the profile's independent sizes and its saved screen anchor.
    APR.ArrowFrameM:ClearAllPoints()
    APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.arrowleft,
        APR.settings.profile.arrowtop)
    self:ApplyStyle()
end

function APR.Arrow:ApplyStyle()
    -- Both atlases share the same normalized 9 x 12 cells. Only the artwork changes;
    -- switching style cannot update navigation, advance a waypoint or change the saved anchor.
    APR.ArrowFrame.arrow:SetTexture(ARROW_TEXTURES[APR.settings.profile.arrowStyle] or ARROW_TEXTURES.classic)
    self:ApplySize()
end

function APR.Arrow:GetTextScale()
    local profile = APR.settings.profile
    -- Previously arrowScale also scaled the text. Migrate once per profile, before either slider changes it.
    if profile.arrowTextScale == nil then profile.arrowTextScale = profile.arrowScale or 1 end
    return profile.arrowTextScale
end

function APR.Arrow:ApplySize()
    local profile = APR.settings.profile
    local scale = (profile.arrowScale or 1) * (profile.arrowStyle == "apr" and APR_STYLE_SCALE or 1)
    APR.ArrowFrame:SetScale(1)
    APR.ArrowFrame:SetSize(CELL_WIDTH * scale, CELL_HEIGHT * scale)
    APR.ArrowFrame.textFrame:SetScale(self:GetTextScale())
end

function APR.Arrow:UpdateTextAppearance()
    UpdateSkipButtonTextLayout()
end

local function CheckDistance()
    if APR.farstrider and APR.farstrider:IsNavigating() then
        return 0
    end

    local currentStep, currentStepIndex, routeSteps = APR:GetCurrentStep()
    if not routeSteps or not currentStep or currentStep.NoArrow then
        return 0
    end
    local _, routeMapID = APR:GetCurrentRouteMapIDsAndName()
    local currentCoord = APR:GetStepCoord(currentStep, routeMapID)
    if not currentCoord then
        return 0
    end

    if currentStep.UseHS or currentStep.UseDalaHS or currentStep.UseGarrisonHS then
        APR.ArrowFrame.Button:Show()
    end

    if not currentStep.Waypoint then
        return 0
    end

    if not currentStep.NonSkippableWaypoint then
        APR.ArrowFrame.Button:Show()
    end

    local distance = 0
    local curStepIndex = currentStepIndex
    local previousCoords = currentCoord

    -- If SingleWaypointDisplayDistance is true, only calculate distance to next waypoint
    if currentStep.SingleWaypointDisplayDistance then
        curStepIndex = curStepIndex + 1
        local nextStep = routeSteps[curStepIndex]
        local nextCoord = nextStep and APR:GetStepCoord(nextStep, routeMapID) or nil
        if nextStep and nextCoord then
            distance = DistanceBetween(previousCoords.x, previousCoords.y, nextCoord.x, nextCoord.y)
            return mathFloor(distance + 0.5)
        end
        return 0
    end

    while true do
        curStepIndex = curStepIndex + 1
        local nextStep = routeSteps[curStepIndex]
        local nextCoord = nextStep and APR:GetStepCoord(nextStep, routeMapID) or nil
        if not nextStep or not nextCoord then
            break
        end

        distance = distance + DistanceBetween(previousCoords.x, previousCoords.y, nextCoord.x, nextCoord.y)
        previousCoords = nextCoord

        if not nextStep.Waypoint then
            return mathFloor(distance + 0.5)
        end
    end

    return mathFloor(distance + 0.5)
end

function APR.Arrow:SetCoord()
    APR:Debug("APR.Arrow:SetCoord()")

    local step, currentStepIndex, routeSteps = APR:GetCurrentStep()
    if not routeSteps or not step then
        return
    end

    if step and step.NoArrow and APR.IsInRouteZone then
        APR:Debug("APR.Arrow:SetCoord(): NoArrow step found, hiding arrow")
        self:SetArrowActive(false, 0, 0)
        return
    end

    local _, routeMapID = APR:GetCurrentRouteMapIDsAndName()
    local stepCoord = APR:GetStepCoord(step, routeMapID, APR:GetPlayerParentMapID())
    if not stepCoord and APR.IsInRouteZone then
        APR:Debug("APR.Arrow:SetCoord(): Step has no coordinates, hiding arrow")
        self:SetArrowActive(false, 0, 0)
        return
    end

    if self.currentStep ~= currentStepIndex and stepCoord and APR.IsInRouteZone then
        APR:Debug("APR.Arrow:SetCoord(): Setting arrow for step:" .. currentStepIndex .. " at coordinates:", stepCoord)
        local x = stepCoord.x
        -- Step refreshes must not briefly show an arrow we already reached.
        -- Waypoints still need OnUpdate to perform their step transition.
        if step.Range and not step.Waypoint and not (APR.farstrider and APR.farstrider:IsNavigating()) then
            local playerY, playerX = UnitPosition("player")
            if playerY and DistanceBetween(playerX, playerY, x, stepCoord.y) < step.Range then
                x = 0
            end
        end
        self:SetArrowActive(true, x, stepCoord.y)
        self.currentStep = currentStepIndex
    end
end

local function UpdatePosition(self, playerX, playerY, facing)
    local questStep, _, routeSteps = APR:GetCurrentStep()
    if not routeSteps then
        APR.ArrowFrame:Hide()
        return
    end

    local isNavigating = APR.farstrider and APR.farstrider:IsNavigating()
    local stepCoord = not isNavigating and questStep and
        APR:GetStepCoord(questStep, nil, APR:GetPlayerParentMapID()) or nil
    if not isNavigating and questStep and questStep.ZoneStepTrigger then -- to trigger a zone detection
        local trigger = questStep.ZoneStepTrigger
        local dist = DistanceBetween(playerX, playerY, trigger.x, trigger.y)
        if trigger.Range > dist then
            self.currentStep = 0
            APR:NextQuestStep()
            return
        end
    end

    if not APR.ArrowFrame:IsShown() then APR.ArrowFrame:Show() end
    if APR.ArrowFrame.Button:IsShown() then APR.ArrowFrame.Button:Hide() end
    local x, y = self.x, self.y
    local distance = DistanceBetween(playerX, playerY, x, y)
    local dx, dy = playerX - x, y - playerY
    local angle = mathAtan2(-dx, dy) - facing
    local perc = mathAbs((math.pi - mathAbs(angle)) / math.pi)

    -- Distance from questStep.Coord if available
    if not isNavigating and stepCoord then
        self.QuestStepDistance = DistanceBetween(playerX, playerY, stepCoord.x, stepCoord.y)
        if self.QuestStepDistance >= self.MaxDistanceWrongZone then
            self.isWrongZoneDistance = true
        elseif self.isWrongZoneDistance then
            self.isWrongZoneDistance = false
            C_Timer.After(0.3, function()
                APR.Arrow.currentStep = 0
                APR:UpdateMapId()
            end)
            return
        end
    end

    if isNavigating then
        self.Distance = distance
        self.isWrongZoneDistance = false
        APR.farstrider:OnArrowUpdate(distance)
        if not APR.farstrider:IsNavigating() then
            return
        end
    else
        -- Prefer QuestStepDistance (from fresh stepCoord) over distance (from
        -- potentially stale self.x/self.y).
        self.Distance = stepCoord and self.QuestStepDistance or distance
        if self.Distance >= self.MaxDistanceWrongZone and questStep then
            if APR.IsInRouteZone ~= false then
                APR:UpdateMapId()
            end
            return
        end
    end

    if not isNavigating and questStep and (questStep.Waypoint or questStep.Range) and APR.IsInRouteZone then
        local range = questStep.Range or 0
        if distance < range then
            self.x = 0
            APR.ArrowFrame:Hide()
            if questStep.Waypoint then
                self.currentStep = 0
                APR:NextQuestStep()
            end
            return
        end
    end

    -- Arrow color
    local r, g, b = GetArrowColor(perc)
    if self.lastColorR ~= r or self.lastColorG ~= g or self.lastColorB ~= b then
        APR.ArrowFrame.arrow:SetVertexColor(r, g, b)
        self.lastColorR, self.lastColorG, self.lastColorB = r, g, b
    end

    -- Arrow texture
    local cell = mathFloor(angle / (2 * math.pi) * (TEXTURE_COLUMNS * TEXTURE_ROWS) + 0.5) %
        (TEXTURE_COLUMNS * TEXTURE_ROWS)
    if self.lastTextureCell ~= cell then
        local col, row = cell % TEXTURE_COLUMNS, mathFloor(cell / TEXTURE_COLUMNS)
        APR.ArrowFrame.arrow:SetTexCoord((col * CELL_WIDTH) / 512, ((col + 1) * CELL_WIDTH) / 512,
            (row * CELL_HEIGHT) / 512, ((row + 1) * CELL_HEIGHT) / 512)
        self.lastTextureCell = cell
    end

    -- Distance display
    local displayedDistance = mathFloor(distance + CheckDistance())
    if self.lastDisplayedDistance ~= displayedDistance then
        APR.ArrowFrame.distance:SetText(displayedDistance .. " " .. L["YARDS"])
        self.lastDisplayedDistance = displayedDistance
    end
end

function APR.Arrow:UpdatePosition()
    local playerY, playerX = UnitPosition("player")
    if not playerY or not APR.ActiveRoute or not APR.RouteQuestStepList or not ShouldShowArrow() then
        self.positionCache = nil
        APR.ArrowFrame:Hide()
        return
    end
    local facing = GetPlayerFacing()
    if not facing then return end
    local progress = APRData[APR.PlayerID]
    local index = progress and progress[APR.ActiveRoute]
    local pathStep = APR.farstrider and APR.farstrider.activePathStep
    local definition = APR.RouteQuestStepList[APR.ActiveRoute]
    local now = GetTime and GetTime() or 0
    local cache = self.positionCache
    -- Keep the cheap position/facing checks at the configured cadence. Resolve the
    -- route and map only on change, with a bounded retry for stationary travel actions.
    if cache and now < cache.expires and cache.playerX == playerX and cache.playerY == playerY
        and cache.facing == facing and cache.x == self.x and cache.y == self.y
        and cache.route == APR.ActiveRoute and cache.index == index
        and cache.revision == APR.stepRevision and cache.definition == definition
        and cache.inZone == APR.IsInRouteZone and cache.pathStep == pathStep
        and cache.currentStep == self.currentStep then return end
    cache = cache or {}
    self.positionCache = cache
    cache.playerX, cache.playerY, cache.facing = playerX, playerY, facing
    cache.x, cache.y, cache.route, cache.index = self.x, self.y, APR.ActiveRoute, index
    cache.revision, cache.definition = APR.stepRevision, definition
    cache.inZone, cache.pathStep, cache.currentStep = APR.IsInRouteZone, pathStep, self.currentStep
    cache.expires = now + IDLE_CHECK_INTERVAL
    local started = APR.StartPerformanceSample and APR:StartPerformanceSample()
    UpdatePosition(self, playerX, playerY, facing)
    if APR.FinishPerformanceSample then APR:FinishPerformanceSample("ArrowPositionUpdate", started) end
end

function APR.Arrow:SetArrowActive(isActive, x, y)
    local a = APR.Arrow
    a.positionCache = nil
    a.arrowUpdateRate = APR.settings.profile.arrowFPS / 100 -- Update rate in seconds (ie: 2/100 = 0.02 seconds)
    a.Active = isActive
    a.x = x or 0
    a.y = y or 0
    if isActive and x and y and ShouldShowArrow() then
        APR.ArrowFrame:Show()
    else
        APR.ArrowFrame:Hide()
    end
end
