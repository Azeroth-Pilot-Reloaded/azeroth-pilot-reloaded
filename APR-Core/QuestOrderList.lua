local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR Quest Order List module
APR.questOrderList = APR:NewModule("QuestOrderList")
APR.questOrderList.stepList = {}
APR.currentStep.questID = nil

--Local constant
local FRAME_WIDTH = 250
local FRAME_HEIGHT = 300
local FRAME_MIN_WIDTH = FRAME_WIDTH
local FRAME_MIN_HEIGHT = 100
local FRAME_OFFSET = 10
local FRAME_DATA_HEIGHT = -5

---------------------------------------------------------------------------------------
---------------------------- Quest Order List Frames ----------------------------------
---------------------------------------------------------------------------------------

local QuestOrderListFrame = CreateFrame("Frame", "QuestOrderListPanel", UIParent, "BackdropTemplate")
QuestOrderListFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
QuestOrderListFrame:SetFrameStrata("MEDIUM")
QuestOrderListFrame:SetClampedToScreen(true)
QuestOrderListFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
QuestOrderListFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    tile = true,
    tileSize = 16
})
QuestOrderListFrame:SetBackdropColor(unpack(APR.Color.defaultBackdrop))

QuestOrderListFrame:SetMovable(true)
QuestOrderListFrame:SetResizable(true)
QuestOrderListFrame:SetResizeBounds(FRAME_MIN_WIDTH, FRAME_MIN_HEIGHT)
QuestOrderListFrame:RegisterForDrag("LeftButton")
QuestOrderListFrame:SetScript("OnDragStart", function(self, button)
    self:StartMoving()
end)
QuestOrderListFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    LibWindow.SavePosition(QuestOrderListPanel)
end)
QuestOrderListFrame:SetScript("OnSizeChanged", function(self, width, height)
    FRAME_WIDTH = width
    FRAME_HEIGHT = height
    QuestOrderListFrame_StepHolder:SetSize(width, height)
    APR.questOrderList:UpdateFrameContents()
    LibWindow.SavePosition(QuestOrderListPanel)
end)

-- Create the step holder frame
local QuestOrderListFrame_StepHolder = CreateFrame("Frame", "QuestOrderListFrame_StepHolder", QuestOrderListFrame,
    "BackdropTemplate")
QuestOrderListFrame_StepHolder:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
QuestOrderListFrame_StepHolder:SetPoint("TOPLEFT", QuestOrderListFrame, "TOPLEFT", 0, -20)

-- Create a scroll frame for the step holder
local QuestOrderListFrame_ScrollFrame = CreateFrame("ScrollFrame", "QuestOrderListFrame_ScrollFrame",
    QuestOrderListFrame_StepHolder, "UIPanelScrollFrameTemplate")
QuestOrderListFrame_ScrollFrame:SetPoint("TOPLEFT", QuestOrderListFrame_StepHolder, "TOPLEFT", 0, -5)
QuestOrderListFrame_ScrollFrame:SetPoint("BOTTOMRIGHT", QuestOrderListFrame_StepHolder, "BOTTOMRIGHT", -22, 20)

-- Create a child frame for the scroll frame
local QuestOrderListFrame_ScrollChild = CreateFrame("Frame", "QuestOrderListFrame_ScrollChild",
    QuestOrderListFrame_ScrollFrame)
QuestOrderListFrame_ScrollChild:SetSize(FRAME_WIDTH, 1)
QuestOrderListFrame_ScrollFrame:SetScrollChild(QuestOrderListFrame_ScrollChild)

-- Create the frame header
local QuestOrderListFrame_StepHolderHeader = CreateFrame("Frame", "QuestOrderListFrame_StepHolderHeader",
    QuestOrderListFrame, "ObjectiveTrackerHeaderTemplate")
QuestOrderListFrame_StepHolderHeader:SetPoint("TOPLEFT", QuestOrderListFrame, "TOPLEFT", 0, 0)
QuestOrderListFrame_StepHolderHeader.Text:SetText(L["QUEST_ORDER_LIST"])
QuestOrderListFrame_StepHolderHeader.MinimizeButton:Hide()

local closeButton = CreateFrame("Button", "QuestOrderListFrameCloseButton", QuestOrderListFrame, "UIPanelCloseButton")
closeButton:SetSize(16, 16)
closeButton:SetPoint("topright", QuestOrderListFrame, "topright", 0, -5)
closeButton:SetScript("OnClick", function()
    QuestOrderListPanel:Hide()
    APR.settings.profile.showQuestOrderList = false
end)

local resizeButton = CreateFrame("Button", "QuestOrderListFrameResizeHandle", QuestOrderListFrame)
resizeButton:SetSize(16, 16)
resizeButton:SetPoint("BOTTOMRIGHT", QuestOrderListFrame, "BOTTOMRIGHT", -15, -2)
resizeButton:EnableMouse(true)
resizeButton:SetNormalTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Down")

resizeButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        QuestOrderListFrame:StartSizing("BOTTOMRIGHT")
    end
end)
resizeButton:SetScript("OnMouseUp", function(self, button)
    QuestOrderListFrame:StopMovingOrSizing()
    LibWindow.SavePosition(QuestOrderListPanel)
    APR.questOrderList:UpdateFrameContents()
end)


---------------------------------------------------------------------------------------
-------------------------- Function Quest Order List Frames ---------------------------
---------------------------------------------------------------------------------------

-- Initialize the Quest Order List frame
function APR.questOrderList:QuestOrderListFrameOnInit()
    LibWindow.RegisterConfig(QuestOrderListPanel, APR.settings.profile.questOrderListFrame)
    QuestOrderListPanel.RegisteredForLibWindow = true
    QuestOrderListFrame_StepHolderHeader:Show()
    QuestOrderListFrame_StepHolder:Show()

    self:RefreshFrameAnchor()
end

function APR.questOrderList:RefreshFrameAnchor()
    if (not APR.settings.profile.showQuestOrderList or not APR.settings.profile.enableAddon or C_PetBattles.IsInBattle() or not APR:IsInInstanceQuest()) then
        QuestOrderListPanel:Hide()
        return
    end
    if not APR.settings.profile.questOrderListLock then
        QuestOrderListFrame:EnableMouse(true)
    else
        QuestOrderListFrame:EnableMouse(false)
    end

    APR.questOrderList:UpdateFrameScale()
    APR.questOrderList:UpdateBackgroundColorAlpha()
    LibWindow.RestorePosition(QuestOrderListPanel)
    QuestOrderListPanel:Show()
    self:AddStepFromRoute()
end

-- Reset the frame position
function APR.questOrderList:ResetPosition()
    QuestOrderListPanel:ClearAllPoints()
    QuestOrderListPanel:SetPoint("center", UIParent, "center", 0, 0)
    LibWindow.SavePosition(QuestOrderListPanel)
    QuestOrderListPanel:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    APR.questOrderList:UpdateBackgroundColorAlpha()
end

-- Update the frame scale
function APR.questOrderList:UpdateFrameScale()
    LibWindow.SetScale(QuestOrderListPanel, APR.settings.profile.questOrderListScale)
end

function APR.questOrderList:UpdateBackgroundColorAlpha(color)
    QuestOrderListFrame:SetBackdropColor(unpack(color or APR.settings.profile.questOrderListbackgroundColorAlpha))
end

local SetCurrentStepIndicator = function(stepindex)
    local container = APR.questOrderList.stepList[stepindex]
    if not container then return end
    container.indexFont:SetFontObject("GameFontHighlight")
    container.titleFont:SetFontObject("GameFontHighlight")
    container.indexFont:SetTextColor(unpack(APR.Color.yellow))
    container.titleFont:SetTextColor(unpack(APR.Color.yellow))
    for _, questFont in pairs(container.questFonts) do
        questFont:SetTextColor(unpack(APR.Color.white))
    end

    local scrollFrame = QuestOrderListFrame_ScrollFrame
    if scrollFrame:GetVerticalScrollRange() > 0 then
        local yOffset = 0
        for i = 1, stepindex - 1 do
            local prevContainer = APR.questOrderList.stepList[i]
            yOffset = yOffset + (prevContainer and prevContainer:GetHeight() or 0)
        end

        scrollFrame:SetVerticalScroll(yOffset)
    end
end

local function CreateTextFont(parent, text, width, color)
    local fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontString:SetWordWrap(true)
    fontString:SetJustifyH("LEFT")
    fontString:SetText(text)
    fontString:SetWidth(width)
    if color == "gray" then
        fontString:SetTextColor(unpack(APR.Color.gray))
    elseif color == "green" then
        fontString:SetTextColor(unpack(APR.Color.green))
    else
        fontString:SetTextColor(unpack(APR.Color.darkGray))
    end
    return fontString
end

local AddStepFrameWithQuest = function(stepIndex, stepText, questInfo, color)
    local container = CreateFrame("Frame", nil, QuestOrderListFrame_ScrollChild, "BackdropTemplate")

    local indexStr = tostring(stepIndex)
    local offset = 14 + 7 * string.len(indexStr)

    local indexFont = CreateTextFont(container, stepIndex, FRAME_WIDTH, color)
    local titleFont = CreateTextFont(container, stepText, FRAME_WIDTH - offset, color)
    indexFont:SetPoint("TOPLEFT", container, "TOPLEFT", 5, 0)
    titleFont:SetPoint("TOPLEFT", container, "TOPLEFT", offset, 0)

    container.indexFont = indexFont
    container.titleFont = titleFont
    container.questFonts = {}

    local questFontHeight = 0
    for i, quest in pairs(questInfo) do
        local questName = quest.questName and ' - ' .. quest.questName or ''
        local questText = quest.questID .. questName
        local questFont = CreateTextFont(container, questText, FRAME_WIDTH - offset - 10 - 22) -- offset - 10 - scrollbar offset

        if stepIndex == APRData[APR.PlayerID][APR.ActiveRoute] then
            if string.find(quest.questID, "-") then
                APR.currentStep.questID = string.sub(quest.questID, 1, string.find(quest.questID, "-")-1)
            else
                APR.currentStep.questID = quest.questID
            end
        end

        questFont:SetPoint("TOPLEFT", container, "TOPLEFT", offset + 10,
            -titleFont:GetStringHeight() - 5 - questFontHeight)

        questFontHeight = questFontHeight + questFont:GetStringHeight()
        container.questFonts[i] = questFont
    end

    container:SetWidth(FRAME_WIDTH)
    container:SetHeight(titleFont:GetStringHeight() + questFontHeight + FRAME_OFFSET)

    container:SetPoint("TOPLEFT", QuestOrderListFrame_ScrollChild, "TOPLEFT", 0, FRAME_DATA_HEIGHT)
    APR.questOrderList.stepList[stepIndex] = container
    FRAME_DATA_HEIGHT = FRAME_DATA_HEIGHT - container:GetHeight()
end

local AddStepFrame = function(stepIndex, stepText, color)
    AddStepFrameWithQuest(stepIndex, stepText, {}, color)
end

-- Remove all quest steps
function APR.questOrderList:RemoveSteps()
    for id, questContainer in pairs(self.stepList) do
        questContainer:Hide()
        questContainer:ClearAllPoints()
        questContainer = nil
    end
    self.stepList = {}
    FRAME_DATA_HEIGHT = -5
    QuestOrderListPanel:Hide()
end

function APR.questOrderList:UpdateFrameContents()
    local contentHeight = 0
    FRAME_DATA_HEIGHT = -5
    for id, container in pairs(self.stepList) do
        local offset = 14 + 7 * string.len(id)
        container:SetWidth(FRAME_WIDTH)
        container.indexFont:SetWidth(FRAME_WIDTH)
        container.titleFont:SetWidth(FRAME_WIDTH - offset)
        local questFontHeight = 0
        for _, questFont in pairs(container.questFonts) do
            questFont:SetWidth(FRAME_WIDTH - offset - 10 - 22) -- offset - 10 - scrollbar offset
            questFont:SetPoint("TOPLEFT", container, "TOPLEFT", offset + 10,
                -container.titleFont:GetStringHeight() - 5 - questFontHeight)
            questFontHeight = questFontHeight + questFont:GetStringHeight()
        end

        local containerHeight = container.titleFont:GetStringHeight() + questFontHeight + FRAME_OFFSET
        container:SetHeight(containerHeight)
        contentHeight = contentHeight + containerHeight

        container:SetPoint("TOPLEFT", QuestOrderListFrame_ScrollChild, "TOPLEFT", 0, FRAME_DATA_HEIGHT)
        FRAME_DATA_HEIGHT = FRAME_DATA_HEIGHT - containerHeight
    end

    QuestOrderListFrame_ScrollChild:SetWidth(FRAME_WIDTH)
    if (contentHeight > 0) then
        QuestOrderListFrame_ScrollChild:SetHeight(contentHeight)
    end
end

function APR.questOrderList:AddStepFromRoute()
    if not APR.settings.profile.enableAddon or not APR.settings.profile.showQuestOrderList or not APR.RouteQuestStepList[APR.ActiveRoute] or not APR.routeconfig:HasRouteInCustomPaht() or not APR:IsInInstanceQuest() then
        self:RemoveSteps()
        APR.currentStep.questID = nil
        return
    end
    if APR.settings.profile.debug then
        print("Function: APR.questOrderList:AddStepFromRoute - " .. APR.ActiveRoute)
    end
    -- Clean list
    self:RemoveSteps()

    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if not CurStep then
        return
    end
    QuestOrderListPanel:Show()
    CurStep = CurStep - (APRData[APR.PlayerID][APR.ActiveRoute .. '-SkippedStep'] or 0)
    -- can't use id from the loop due to faction/race/class/achievement step option
    local stepIndex = 1
    for id, step in pairs(APR.RouteQuestStepList[APR.ActiveRoute]) do
        -- Hide step for Faction, Race, Class, Achievement
        if (
                (not step.Faction or step.Faction == APR.Faction) and
                (not step.Race or step.Race == APR.Race) and
                (not step.Gender or step.Gender == APR.Gender) and
                (not step.Class or step.Class == APR.ClassName) and
                (not step.HasAchievement or _G.HasAchievement(step.HasAchievement)) and
                (not step.DontHaveAchievement or not _G.HasAchievement(step.DontHaveAchievement))
            ) then
            if step.ExitTutorial then
                local questID = step.ExitTutorial
                local color = (C_QuestLog.IsOnQuest(questID) or CurStep > stepIndex) and "green" or "gray"
                AddStepFrame(stepIndex, L["SKIP_TUTORIAL"], color)
            elseif step.PickUp then
                IdList = step.PickUp
                local questInfo = {}
                local Flagged = 0
                for _, questID in pairs(IdList) do
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.ActiveQuests[questID] then
                        Flagged = Flagged + 1
                    else
                        tinsert(questInfo, { questID = questID, questName = C_QuestLog.GetTitleForQuestID(questID) })
                    end
                end
                if #IdList == Flagged then
                    AddStepFrame(stepIndex, L["PICK_UP_Q"], "green")
                else
                    AddStepFrameWithQuest(stepIndex, L["PICK_UP_Q"], questInfo, "gray")
                end
            elseif step.DropQuest then
                local questID = step.DropQuest
                local color = (C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.ActiveQuests[questID]) and "green" or
                    "gray"
                AddStepFrame(stepIndex, L["Q_DROP"], color)
            elseif step.Qpart then
                IdList = step.Qpart
                local questInfo = {}
                local flagged = 0
                local total = 0

                local isMaxLevel = UnitLevel("player") == APR.MaxLevel
                for questID, objectives in pairs(IdList) do
                    for _, objectiveIndex in pairs(objectives) do
                        total = total + 1
                        local questObjectiveId = questID .. '-' .. objectiveIndex
                        -- //TODO Remove or add APR_BonusObj from quest handler
                        local questFlagged = C_QuestLog.IsQuestFlaggedCompleted(questID) or
                            (isMaxLevel and APR_BonusObj and Contains(APR_BonusObj, APR_index)) or
                            APRData[APR.PlayerID].BonusSkips[questID]
                        if questFlagged or (APR.ActiveQuests[questObjectiveId] and APR.ActiveQuests[questObjectiveId] == "C") then
                            flagged = flagged + 1
                        elseif not APR.ActiveQuests[qid] or not APR.ActiveQuests[questID] then
                            tinsert(questInfo,
                                { questID = questObjectiveId, questName = C_QuestLog.GetTitleForQuestID(questID) })
                        end
                    end
                end
                if total == flagged then
                    AddStepFrame(stepIndex, L["Q_PART"], "green")
                else
                    AddStepFrameWithQuest(stepIndex, L["Q_PART"], questInfo, "gray")
                end
            elseif step.QpartPart then
                IdList = step.QpartPart
                local questInfo = {}
                local flagged = 0
                local total = 0
                for questID, objectives in pairs(IdList) do
                    for _, objectiveIndex in pairs(objectives) do
                        total = total + 1
                        local questObjectiveId = questID .. '-' .. objectiveIndex
                        if C_QuestLog.IsQuestFlaggedCompleted(questID) or (APR.ActiveQuests[questObjectiveId] and APR.ActiveQuests[questObjectiveId] == "C") then
                            flagged = flagged + 1
                        elseif not APR.ActiveQuests[qid] or not APR.ActiveQuests[questID] then
                            tinsert(questInfo,
                                { questID = questObjectiveId, questName = C_QuestLog.GetTitleForQuestID(questID) })
                        end
                    end
                end
                if total == flagged then
                    AddStepFrame(stepIndex, L["Q_PART"], "green")
                else
                    AddStepFrameWithQuest(stepIndex, L["Q_PART"], questInfo, "gray")
                end
            elseif step.Treasure then
                local questID = step.Treasure
                local questInfo = { { questID = questID, questName = C_QuestLog.GetTitleForQuestID(questID) } }
                local color = C_QuestLog.IsQuestFlaggedCompleted(questID) and "green" or "gray"
                AddStepFrameWithQuest(stepIndex, L["GET_TREASURE"], questInfo, color)
            elseif step.Group then
                local questID = step.Group.QuestId
                local questInfo = { { questID = questID, questName = C_QuestLog.GetTitleForQuestID(questID) } }
                local color = C_QuestLog.IsQuestFlaggedCompleted(questID) and "green" or "gray"
                AddStepFrameWithQuest(stepIndex, L["GROUP_Q"], questInfo, color)
            elseif step.Done then
                IdList = step.Done
                local questInfo = {}
                local Flagged = 0
                for _, questID in pairs(IdList) do
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) then
                        Flagged = Flagged + 1
                    else
                        tinsert(questInfo, { questID = questID, questName = C_QuestLog.GetTitleForQuestID(questID) })
                    end
                end
                if #IdList == Flagged then
                    AddStepFrame(stepIndex, L["TURN_IN_Q"], "green")
                else
                    AddStepFrameWithQuest(stepIndex, L["TURN_IN_Q"], questInfo, "gray")
                end
            elseif step.Waypoint then
                local questID = step.Waypoint
                local color = (C_QuestLog.IsQuestFlaggedCompleted(questID) or CurStep > stepIndex) and "green" or "gray"
                AddStepFrame(stepIndex, L["RUN_WAYPOINT"], color)
            elseif step.SetHS then
                local questID = step.SetHS
                local color = (C_QuestLog.IsQuestFlaggedCompleted(questID) or CurStep > stepIndex) and "green" or "gray"
                AddStepFrame(stepIndex, L["SET_HEARTHSTONE"], color)
            elseif step.UseHS or step.UseDalaHS or step.UseGarrisonHS then
                local questID = step.UseHS or step.UseDalaHS or step.UseGarrisonHS
                local questText = step.UseHS and L["USE_HEARTHSTONE"] or
                    (step.UseDalaHS and L["USE_DALARAN_HEARTHSTONE"] or L["USE_GARRISON_HEARTHSTONE"])
                local color = (C_QuestLog.IsQuestFlaggedCompleted(questID) or CurStep > stepIndex) and "green" or "gray"
                AddStepFrame(stepIndex, questText, color)
            elseif step.GetFP then
                local nodeID = step.GetFP
                local color = (HasTaxiNode(nodeID) or CurStep > stepIndex) and "green" or "gray"
                AddStepFrame(stepIndex, L["GET_FLIGHTPATH"], color)
            elseif step.UseFlightPath then
                local questID = step.UseFlightPath
                local questText = step.Boat and L["USE_BOAT"] or L["USE_FLIGHTPATH"]
                local questInfo = { { questID = APRTaxiNodes[APR.PlayerID][step.NodeID] or step.Name } }
                local color = (C_QuestLog.IsQuestFlaggedCompleted(questID) or CurStep > stepIndex) and "green" or "gray"
                AddStepFrameWithQuest(stepIndex, questText, questInfo, color)
            elseif step.WarMode then
                AddStepFrame(stepIndex, L["TURN_ON_WARMODE"], "gray")
            elseif step.Grind then
                AddStepFrame(stepIndex, L["GRIND"] .. " " .. step.Grind, "gray")
            elseif step.ZoneDoneSave then
                AddStepFrame(stepIndex, L["ROUTE_COMPLETED"], "gray")
            end
            stepIndex = stepIndex + 1
        end
    end
    -- set current Step indicator
    SetCurrentStepIndicator(CurStep)
end
