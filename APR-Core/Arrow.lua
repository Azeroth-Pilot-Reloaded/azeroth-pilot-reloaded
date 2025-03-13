local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")


-- Initialize module
APR.Arrow = APR:NewModule("Arrow")

APR.Arrow = {
    currentStep = 0,
    Active = false,
    x = 0,
    y = 0,
    Distance = 0,
    MaxDistanceWrongZone = 4000,
    ticker = nill
}


---------------------------------------------------------------------------------------
----------------------------------- Arrow Frames --------------------------------------
---------------------------------------------------------------------------------------

-- //TODO Rework Arrow frame
--More UI stuff, to do with arrowframe
--Arrowframe is the "arrow" that looks like the tomtom one
APR.ArrowFrameM = CreateFrame("Button", "APR_Arrow", UIParent)
APR.ArrowFrameM:SetHeight(1)
APR.ArrowFrameM:SetWidth(1)
APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
APR.ArrowFrameM:EnableMouse(true)
APR.ArrowFrameM:SetMovable(true)

APR.ArrowFrame = CreateFrame("Button", "APR_Arrow", UIParent)
APR.ArrowFrame:SetHeight(42)
APR.ArrowFrame:SetWidth(56)
APR.ArrowFrame:SetPoint("TOPLEFT", APR.ArrowFrameM, "TOPLEFT", 0, 0)
APR.ArrowFrame:EnableMouse(true)
APR.ArrowFrame:SetMovable(true)
APR.ArrowFrame.arrow = APR.ArrowFrame:CreateTexture(nil, "OVERLAY")
APR.ArrowFrame.arrow:SetTexture("Interface\\Addons\\APR\\APR-Core\\assets\\Arrow.blp")
APR.ArrowFrame.arrow:SetAllPoints()
APR.ArrowFrame.distance = APR.ArrowFrame:CreateFontString("distance", "ARTWORK", "ChatFontNormal")
APR.ArrowFrame.distance:SetFontObject("GameFontNormalSmall")
APR.ArrowFrame.distance:SetPoint("TOP", APR.ArrowFrame, "BOTTOM", 0, 0)
APR.ArrowFrame:Hide()
APR.ArrowFrame:SetScript("OnMouseDown", function(self, button) --Mouse clicking arrowframe
    if button == "LeftButton" and not APR.ArrowFrameM.isMoving and not APR.settings.profile.lockArrow then
        APR.ArrowFrameM:StartMoving();
        APR.ArrowFrameM.isMoving = true;
    end
end)
--Mouse unclicking arrowframe (releasing mouse)
APR.ArrowFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and APR.ArrowFrameM.isMoving then
        APR.ArrowFrameM:StopMovingOrSizing();
        APR.ArrowFrameM.isMoving = false;
        APR.settings.profile.arrowleft = APR.ArrowFrameM:GetLeft()
        APR.settings.profile.arrowtop = APR.ArrowFrameM:GetTop() - GetScreenHeight()
        APR.ArrowFrameM:ClearAllPoints()
        APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.arrowleft,
            APR.settings.profile.arrowtop)
    end
end)
--When arrowframe hides
APR.ArrowFrame:SetScript("OnHide", function(self)
    if (APR.ArrowFrameM.isMoving) then
        APR.ArrowFrameM:StopMovingOrSizing(); -- prevent it from moving or rescaling in the background, it cant be seen anyways
        APR.ArrowFrameM.isMoving = false;
        APR.settings.profile.arrowleft = APR.ArrowFrameM:GetLeft()
        APR.settings.profile.arrowtop = APR.ArrowFrameM:GetTop() - GetScreenHeight()
        APR.ArrowFrameM:ClearAllPoints()
        APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.arrowleft,
            APR.settings.profile.arrowtop)
    end
end)

APR.ArrowFrame.Button = CreateFrame("Button", "APR_ArrowActiveButton", APR.ArrowFrame)
APR.ArrowFrame.Button:SetParent(APR.ArrowFrame)
APR.ArrowFrame.Button:SetPoint("BOTTOM", APR.ArrowFrame, "BOTTOM", 0, -40)
APR.ArrowFrame.Button:SetScript("OnMouseDown", function(self, button)
    APR.ArrowFrame.Button:Hide()
    print("APR: " .. L["SKIP_WAYPOINT"])
    APR:NextQuestStep()
    APR.Arrow.x = 0
    APR.Arrow.y = 0
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

local function CheckDistance()
    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if CurStep and APR.RouteQuestStepList[APR.ActiveRoute] and APR.RouteQuestStepList[APR.ActiveRoute][CurStep] then
        local step = APR.RouteQuestStepList[APR.ActiveRoute]
        if not step[CurStep].Coord or step[CurStep].NoArrow then
            return 0
        end
        -- To skip HS
        if step[CurStep] and (step[CurStep].UseHS or step[CurStep].UseDalaHS or step[CurStep].UseGarrisonHS) then
            APR.ArrowFrame.Button:Show()
        end
        if step[CurStep] and step[CurStep].Waypoint then
            APR.ArrowFrame.Button:Show()
            local curStepIndex = CurStep
            local distance = 0
            while true do
                local oldx, oldy = step[curStepIndex].Coord.x, step[curStepIndex].Coord.y
                curStepIndex = curStepIndex + 1
                local tmpStep = step[curStepIndex]
                if tmpStep and tmpStep.Coord then
                    local newx, newy = tmpStep.Coord.x, tmpStep.Coord.y
                    local deltaX, deltaY = oldx - newx, newy - oldy
                    local subDistance = (deltaX * deltaX + deltaY * deltaY) ^ 0.5
                    distance = distance + subDistance
                end
                if not tmpStep.Waypoint then
                    return floor(distance + 0.5)
                end
            end
        end
    end
    return 0
end

function APR.Arrow:SetCoord()
    if (APR.settings.profile.debug) then
        print("Function: APR.Arrow:SetCoord")
    end
    if not APR.ActiveRoute then
        return
    end

    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if not APR.RouteQuestStepList[APR.ActiveRoute] then
        return
    end
    local step = APR.RouteQuestStepList[APR.ActiveRoute][CurStep]
    if step and step.NoArrow and APR.IsInRouteZone then
        self:SetArrowActive(false, 0, 0)
        return
    end

    if APR.Arrow.currentStep ~= CurStep and step.Coord and APR.IsInRouteZone then
        self:SetArrowActive(true, step.Coord.x, step.Coord.y)
        APR.Arrow.currentStep = CurStep
    end
end

function APR.Arrow:CalculPosition()
    local playerY, playerX = UnitPosition("player")

    if not playerY or not APR.ActiveRoute or not APR.RouteQuestStepList then
        APR.ArrowFrame:Hide()
        return
    end

    if not APR.settings.profile.showArrow or not APR.Arrow.Active or APR.Arrow.x == 0 or C_PetBattles.IsInBattle() or not APR:IsInstanceWithUI() then
        APR.ArrowFrame:Hide()
        return
    end

    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    local questStep = APR.RouteQuestStepList[APR.ActiveRoute] and APR.RouteQuestStepList[APR.ActiveRoute][CurStep]

    if questStep and questStep.ZoneStepTrigger then -- to trigger a zone detection
        local trigger = questStep.ZoneStepTrigger
        local deltaX, deltaY = playerX - trigger.x, trigger.y - playerY
        local distance = (deltaX * deltaX + deltaY * deltaY) ^ 0.5

        if trigger.Range > distance then
            APR.Arrow.currentStep = 0
            APR:NextQuestStep()
            return
        end
    end

    APR.ArrowFrame:Show()
    APR.ArrowFrame.Button:Hide()

    if not GetPlayerFacing() then return end
    local x, y = APR.Arrow.x, APR.Arrow.y
    local deltaX, deltaY = playerX - x, y - playerY
    local distance = (deltaX * deltaX + deltaY * deltaY) ^ 0.5
    local angle = math.atan2(-deltaX, deltaY) - GetPlayerFacing()
    local perc = math.abs((math.pi - math.abs(angle)) / math.pi)

    -- Set global distance for transport
    APR.Arrow.Distance = distance
    if distance >= APR.Arrow.MaxDistanceWrongZone and (questStep and not questStep.InstanceQuest) then
        APR:UpdateMapId()
        return
    end

    if questStep and (questStep.Waypoint or questStep.Range) and APR.IsInRouteZone then
        local range = questStep.Range
        if distance < range then
            APR.Arrow.x = 0
            if questStep.Waypoint then
                APR.Arrow.currentStep = 0
                APR:NextQuestStep()
            end
            return
        end
    end

    if perc > 0.98 then
        APR.ArrowFrame.arrow:SetVertexColor(0, 1, 0)
    elseif perc > 0.49 then
        APR.ArrowFrame.arrow:SetVertexColor((1 - perc) * 2, 1, 0)
    else
        APR.ArrowFrame.arrow:SetVertexColor(1, perc * 2, 0)
    end

    local cell = math.floor(angle / (2 * math.pi) * 108 + 0.5) % 108
    local col = cell % 9
    local row = math.floor(cell / 9)
    APR.ArrowFrame.arrow:SetTexCoord((col * 56) / 512, ((col + 1) * 56) / 512, (row * 42) / 512, ((row + 1) * 42) / 512)
    APR.ArrowFrame.distance:SetText(math.floor(distance + CheckDistance()) .. " " .. L["YARDS"])
end

function APR.Arrow:SetArrowActive(isActive, x, y)
    APR.Arrow.Active = isActive
    APR.Arrow.x = x
    APR.Arrow.y = y
end

-- Function to start the periodic update
function APR.Arrow:StartUpdating()
    local interval = 1 / APR.settings.profile.arrowFPS
    APR.Arrow.ticker = C_Timer.NewTicker(interval, function()
        APR.Arrow:CalculPosition()
    end)
end

-- Function to stop the periodic update
function APR.Arrow:StopUpdating()
    if APR.Arrow.ticker then
        APR.Arrow.ticker:Cancel()
        APR.Arrow.ticker = nil
    end
end
