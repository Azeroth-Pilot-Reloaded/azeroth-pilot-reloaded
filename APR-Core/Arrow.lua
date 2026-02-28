local L = LibStub("AceLocale-3.0"):GetLocale("APR")


-- Initialize module
APR.Arrow = APR:NewModule("Arrow")


local ARROW_TEXTURE = "Interface\\Addons\\APR\\APR-Core\\assets\\Arrow.blp"
local TEXTURE_COLUMNS = 9
local TEXTURE_ROWS = 12
local CELL_WIDTH = 56
local CELL_HEIGHT = 42

local mathAbs, mathAtan2, mathFloor = math.abs, math.atan2, math.floor

APR.Arrow.currentStep = 0
APR.Arrow.Active = false
APR.Arrow.x = 0
APR.Arrow.y = 0
APR.Arrow.Distance = 0
APR.Arrow.QuestStepDistance = 0
APR.Arrow.MaxDistanceWrongZone = 10000
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

local function GetCurrentRouteStep()
    if not APR.ActiveRoute or not APR.RouteQuestStepList then
        return
    end

    local playerRouteData = APRData[APR.PlayerID]
    if not playerRouteData then
        return
    end

    local currentStepIndex = playerRouteData[APR.ActiveRoute]
    if not currentStepIndex then
        return
    end

    local routeSteps = APR.RouteQuestStepList[APR.ActiveRoute]
    if not routeSteps then
        return
    end

    return routeSteps, routeSteps[currentStepIndex], currentStepIndex
end

local function ShouldShowArrow()
    if not APR.settings.profile.showArrow then return false end
    if not APR.Arrow.Active then return false end
    if APR.Arrow.x == 0 then return false end
    if C_PetBattles.IsInBattle() then return false end
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
APR.ArrowFrame.arrow:SetTexture(ARROW_TEXTURE)
APR.ArrowFrame.arrow:SetAllPoints()
APR.ArrowFrame.distance = APR.ArrowFrame:CreateFontString("distance", "ARTWORK", "ChatFontNormal")
APR.ArrowFrame.distance:SetFontObject("GameFontNormalSmall")
APR.ArrowFrame.distance:SetPoint("TOP", APR.ArrowFrame, "BOTTOM", 0, 0)
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

    APR.Arrow:CalculPosition()
end)


APR.ArrowFrame.Button = CreateFrame("Button", "APR_ArrowActiveButton", APR.ArrowFrame)
APR.ArrowFrame.Button:SetParent(APR.ArrowFrame)
APR.ArrowFrame.Button:SetPoint("BOTTOM", APR.ArrowFrame, "BOTTOM", 0, -40)
APR.ArrowFrame.Button:SetScript("OnMouseDown", function(self, button)
    APR.ArrowFrame.Button:Hide()
    APR:PrintInfo("APR: " .. L["SKIP_WAYPOINT"])
    APR:NextQuestStep()
end)

local t = APR.ArrowFrame.Button:CreateTexture(nil, "BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ArrowFrame.Button)
APR.ArrowFrame.Button.texture = t

APR.ArrowFrame.Fontstring = APR.ArrowFrame:CreateFontString("CLSettingsFS2212", "ARTWORK", "ChatFontNormal")
APR.ArrowFrame.Fontstring:SetParent(APR.ArrowFrame.Button)
APR.ArrowFrame.Fontstring:SetPoint("CENTER", APR.ArrowFrame.Button)
APR.ArrowFrame.Fontstring:SetText(L["SKIP_WAYPOINT"])
local skipWidth = APR.ArrowFrame.Fontstring:GetStringWidth() + 10 < 85 and
    (APR.ArrowFrame.Fontstring:GetStringWidth() + 10) / 2 or 85
local skipHeight = skipWidth < 85 and APR.ArrowFrame.Fontstring:GetStringHeight() + 10 or
    APR.ArrowFrame.Fontstring:GetStringHeight() + 5
APR.ArrowFrame.Button:SetWidth(skipWidth)
APR.ArrowFrame.Button:SetHeight(skipHeight)
APR.ArrowFrame.Fontstring:SetWidth(skipWidth)
APR.ArrowFrame.Fontstring:SetWordWrap(true)
APR.ArrowFrame.Fontstring:SetFontObject("GameFontNormalSmall")
APR.ArrowFrame.Fontstring:SetTextColor(1, 1, 0)
APR.ArrowFrame.Button:Hide()

---------------------------------------------------------------------------------------
--------------------------------- Arrow Function --------------------------------------
---------------------------------------------------------------------------------------


function APR.Arrow:Init()
    -- Set Arrow scale and position
    APR.ArrowFrame:SetScale(APR.settings.profile.arrowScale)
    APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.arrowleft,
        APR.settings.profile.arrowtop)
end

local function CheckDistance()
    local routeSteps, currentStep, currentStepIndex = GetCurrentRouteStep()
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

    local routeSteps, step, currentStepIndex = GetCurrentRouteStep()
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
        self:SetArrowActive(true, stepCoord.x, stepCoord.y)
        self.currentStep = currentStepIndex
    end
end

function APR.Arrow:CalculPosition()
    local playerY, playerX = UnitPosition("player")

    if not playerY or not APR.ActiveRoute or not APR.RouteQuestStepList then
        APR.ArrowFrame:Hide()
        return
    end

    if not ShouldShowArrow() then
        APR.ArrowFrame:Hide()
        return
    end

    local routeSteps, questStep = GetCurrentRouteStep()
    if not routeSteps then
        APR.ArrowFrame:Hide()
        return
    end

    local stepCoord = questStep and APR:GetStepCoord(questStep, nil, APR:GetPlayerParentMapID()) or nil
    if questStep and questStep.ZoneStepTrigger then -- to trigger a zone detection
        local trigger = questStep.ZoneStepTrigger
        local dist = DistanceBetween(playerX, playerY, trigger.x, trigger.y)
        if trigger.Range > dist then
            self.currentStep = 0
            APR:NextQuestStep()
            return
        end
    end

    APR.ArrowFrame:Show()
    APR.ArrowFrame.Button:Hide()

    local facing = GetPlayerFacing()
    if not facing then return end
    local x, y = self.x, self.y
    local distance = DistanceBetween(playerX, playerY, x, y)
    local dx, dy = playerX - x, y - playerY
    local angle = mathAtan2(-dx, dy) - facing
    local perc = mathAbs((math.pi - mathAbs(angle)) / math.pi)

    -- Distance from questStep.Coord if available
    if stepCoord then
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

    -- Set global distance for transport
    -- Prefer QuestStepDistance (from fresh stepCoord) over distance (from potentially stale self.x/self.y)
    -- self.x/self.y are only updated by SetCoord() when IsInRouteZone is true, so they can be stale
    self.Distance = stepCoord and self.QuestStepDistance or distance
    if self.Distance >= self.MaxDistanceWrongZone and (questStep and not questStep.InstanceQuest) then
        -- Only trigger routing if not already handling wrong zone
        -- Once GetMeToRightZone has set IsInRouteZone=false, zone events will handle re-checks
        if APR.IsInRouteZone ~= false then
            APR:UpdateMapId()
        end
        return
    end

    if questStep and (questStep.Waypoint or questStep.Range) and APR.IsInRouteZone then
        local range = questStep.Range or 0
        if distance < range then
            self.x = 0
            if questStep.Waypoint then
                self.currentStep = 0
                APR:NextQuestStep()
            end
            return
        end
    end

    -- Arrow color
    local r, g, b = GetArrowColor(perc)
    APR.ArrowFrame.arrow:SetVertexColor(r, g, b)

    -- Arrow texture
    local cell = mathFloor(angle / (2 * math.pi) * (TEXTURE_COLUMNS * TEXTURE_ROWS) + 0.5) %
        (TEXTURE_COLUMNS * TEXTURE_ROWS)
    local col, row = cell % TEXTURE_COLUMNS, mathFloor(cell / TEXTURE_COLUMNS)
    APR.ArrowFrame.arrow:SetTexCoord((col * CELL_WIDTH) / 512, ((col + 1) * CELL_WIDTH) / 512,
        (row * CELL_HEIGHT) / 512, ((row + 1) * CELL_HEIGHT) / 512)

    -- Distance display
    APR.ArrowFrame.distance:SetText(mathFloor(distance + CheckDistance()) .. " " .. L["YARDS"])
end

function APR.Arrow:SetArrowActive(isActive, x, y)
    local a = APR.Arrow
    a.arrowUpdateRate = APR.settings.profile.arrowFPS / 100 -- Update rate in seconds (ie: 2/100 = 0.02 seconds)
    a.Active = isActive
    a.x = x or 0
    a.y = y or 0
    if isActive and x and y then
        APR.ArrowFrame:Show()
    else
        APR.ArrowFrame:Hide()
    end
end
