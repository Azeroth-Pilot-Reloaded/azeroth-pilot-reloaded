local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")


-- Initialize module
APR.Arrow = APR:NewModule("Arrow")

APR.Arrow.currentStep = 0
APR.ArrowActive = 0
APR.ArrowActive_X = 0
APR.ArrowActive_Y = 0

---------------------------------------------------------------------------------------
----------------------------------- Arrow Frames --------------------------------------
---------------------------------------------------------------------------------------

-- TODO Rework Arrow frame
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
APR.ArrowFrame.arrow:SetTexture("Interface\\Addons\\APR-Core\\assets\\Arrow.blp")
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
    _G.NextQuestStep()
    APR.ArrowActive_X = 0
    APR.ArrowActive_Y = 0
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
    if CurStep and APR.QuestStepList[APR.ActiveRoute] and APR.QuestStepList[APR.ActiveRoute][CurStep] then
        local stepList = APR.QuestStepList[APR.ActiveRoute]
        if (stepList[CurStep] and stepList[CurStep]["CRange"]) then
            APR.ArrowFrame.Button:Show()
            local curStepIndex = CurStep
            local distance = 0
            while true do
                local oldx, oldy = stepList[curStepIndex]["TT"]["x"], stepList[curStepIndex]["TT"]["y"]
                curStepIndex = curStepIndex + 1
                local step = stepList[curStepIndex]
                if (step and step["CRange"]) then
                    local newx, newy = step["TT"]["x"], step["TT"]["y"]
                    local deltaX, deltaY = oldx - newx, newy - oldy
                    local subDistance = (deltaX * deltaX + deltaY * deltaY) ^ 0.5
                    distance = distance + subDistance
                else
                    if (step and step["TT"]) then
                        local newx, newy = step["TT"]["x"], step["TT"]["y"]
                        local deltaX, deltaY = oldx - newx, newy - oldy
                        local subDistance = (deltaX * deltaX + deltaY * deltaY) ^ 0.5
                        distance = distance + subDistance
                    end
                    return floor(distance + 0.5)
                end
            end
        end
    end
    return 0
end

function APR.Arrow:SetQPTT()
    if (APR.settings.profile.debug) then
        print("Function: APR_SetQPTT()")
    end
    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if (APR.Arrow.currentStep ~= CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveRoute] and APR.QuestStepList[APR.ActiveRoute][CurStep] and APR.QuestStepList[APR.ActiveRoute][CurStep]["TT"]) then
        APR.ArrowActive = 1
        APR.ArrowActive_X = APR.QuestStepList[APR.ActiveRoute][CurStep]["TT"]["x"]
        APR.ArrowActive_Y = APR.QuestStepList[APR.ActiveRoute][CurStep]["TT"]["y"]
        APR.Arrow.currentStep = CurStep
    end
end

function APR.Arrow:CalculPosition()
    local d_y, d_x = UnitPosition("player")

    if not d_y then
        APR.ArrowFrame:Hide()
        return
    end

    if not APR.settings.profile.showArrow or APR.ArrowActive == 0 or APR.ArrowActive_X == 0 or IsInInstance() or not APR.QuestStepList or C_PetBattles.IsInBattle() then
        APR.ArrowFrame:Hide()
        return
    end

    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    local questStep = APR.QuestStepList[APR.ActiveRoute] and APR.QuestStepList[APR.ActiveRoute][CurStep]

    if questStep and questStep.AreaTriggerZ then
        local trigger = questStep.AreaTriggerZ
        local x, y = trigger.x, trigger.y
        local deltaX, deltaY = d_x - x, y - d_y
        local distance = (deltaX * deltaX + deltaY * deltaY) ^ 0.5

        if trigger.R > distance then
            APR.Arrow.currentStep = 0
            _G.NextQuestStep()
            return
        end
    end

    APR.ArrowFrame:Show()
    APR.ArrowFrame.Button:Hide()

    local x, y = APR.ArrowActive_X, APR.ArrowActive_Y
    local deltaX, deltaY = d_x - x, y - d_y
    local distance = (deltaX * deltaX + deltaY * deltaY) ^ 0.5
    local angle = math.atan2(-deltaX, deltaY) - GetPlayerFacing()
    local perc = math.abs((math.pi - math.abs(angle)) / math.pi)

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

    if CurStep and APR.ActiveRoute and questStep and questStep.Trigger then
        local trigger = questStep.Trigger
        local APR_ArrowActive_Trigger_X = trigger.x
        local APR_ArrowActive_Trigger_Y = trigger.y
        local deltaX, deltaY = d_x - APR_ArrowActive_Trigger_X, APR_ArrowActive_Trigger_Y - d_y
        local APR_ArrowActive_Distance = (deltaX * deltaX + deltaY * deltaY) ^ 0.5
        local APR_ArrowActive_TrigDistance = questStep.Range

        if distance < 5 and APR_ArrowActive_Distance == 0 or (APR_ArrowActive_Distance and APR_ArrowActive_TrigDistance and APR_ArrowActive_Distance < APR_ArrowActive_TrigDistance) then
            APR.ArrowActive_X = 0

            if CurStep and APR.ActiveRoute and questStep.CRange then
                APR.Arrow.currentStep = 0
                _G.NextQuestStep()
            end
        end
    end
end
