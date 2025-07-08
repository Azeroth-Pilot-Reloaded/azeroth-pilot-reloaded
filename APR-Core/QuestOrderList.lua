local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR Quest Order List module
APR.questOrderList = APR:NewModule("QuestOrderList")
APR.questOrderList.stepList = {}
APR.questOrderList.questID = nil
APR.questOrderList.currentStepIndex = nil
APR.questOrderList.updateTimer = nil
APR.questOrderList.pendingUpdate = false

-- Local constants
local FRAME_WIDTH = 258
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
QuestOrderListFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
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
QuestOrderListFrame_StepHolder:SetAllPoints()

-- Create a scroll frame for the step holder
local QuestOrderListFrame_ScrollFrame = CreateFrame("ScrollFrame", "QuestOrderListFrame_ScrollFrame",
    QuestOrderListFrame_StepHolder, "UIPanelScrollFrameTemplate")
QuestOrderListFrame_ScrollFrame:SetPoint("TOPLEFT", QuestOrderListFrame_StepHolder, "TOPLEFT", 0, 0)
QuestOrderListFrame_ScrollFrame:SetPoint("BOTTOMRIGHT", QuestOrderListFrame_StepHolder, "BOTTOMRIGHT", -22, 0)

-- Create a child frame for the scroll frame
local QuestOrderListFrame_ScrollChild = CreateFrame("Frame", "QuestOrderListFrame_ScrollChild",
    QuestOrderListFrame_ScrollFrame)
QuestOrderListFrame_ScrollChild:SetSize(FRAME_WIDTH, 1)
QuestOrderListFrame_ScrollFrame:SetScrollChild(QuestOrderListFrame_ScrollChild)

-- Create the frame header
local QuestOrderListFrame_StepHolderHeader = CreateFrame("Frame", "QuestOrderListFrame_StepHolderHeader",
    QuestOrderListFrame, "ObjectiveTrackerContainerHeaderTemplate")
QuestOrderListFrame_StepHolderHeader:SetPoint("TOPLEFT", QuestOrderListFrame, "TOPLEFT", 0, 30)
QuestOrderListFrame_StepHolderHeader.Text:SetText(L["QUEST_ORDER_LIST"])
QuestOrderListFrame_StepHolderHeader:SetScript("OnMouseDown", function(self)
    if not APR.settings.profile.questOrderListLock then
        self:GetParent():StartMoving()
    end
end)
QuestOrderListFrame_StepHolderHeader:SetScript("OnMouseUp", function(self)
    self:GetParent():StopMovingOrSizing()
    LibWindow.SavePosition(QuestOrderListPanel)
end)
QuestOrderListFrame_StepHolderHeader.MinimizeButton:GetNormalTexture():SetAtlas("redbutton-exit")
QuestOrderListFrame_StepHolderHeader.MinimizeButton:GetPushedTexture():SetAtlas("redbutton-exit-pressed")
QuestOrderListFrame_StepHolderHeader.MinimizeButton:SetScript("OnClick", function(self)
    APR.settings.profile.showQuestOrderList = false
    QuestOrderListPanel:Hide()
end)


local resizeButton = CreateFrame("Button", "QuestOrderListFrameResizeHandle", QuestOrderListFrame)
resizeButton:SetSize(16, 16)
resizeButton:SetPoint("BOTTOMRIGHT", QuestOrderListFrame, "BOTTOMRIGHT", -15, -2)
resizeButton:EnableMouse(true)
resizeButton:SetNormalTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Down")

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
    self.currentStepIndex = nil
    self:RefreshFrameAnchor()
end

function APR.questOrderList:RefreshFrameAnchor()
    if (not APR.settings.profile.showQuestOrderList or not APR.settings.profile.enableAddon or C_PetBattles.IsInBattle() or not APR:IsInstanceWithUI()) then
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
    self:AddStepFromRoute(true)
end

-- Reset the frame position
function APR.questOrderList:ResetPosition()
    QuestOrderListPanel:ClearAllPoints()
    QuestOrderListPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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

local function SetCurrentStepIndicator(stepindex)
    local container = APR.questOrderList.stepList[stepindex]
    if not container then return end
    container.indexFont:SetFontObject("GameFontHighlight")
    container.titleFont:SetFontObject("GameFontHighlight")
    container.indexFont:SetTextColor(unpack(APR.Color.yellow))
    container.titleFont:SetTextColor(unpack(APR.Color.yellow))
    for _, questFont in pairs(container.questFonts) do
        questFont:SetTextColor(unpack(APR.Color.white))
    end

    C_Timer.After(0.1, function()
        local scrollFrame = QuestOrderListFrame_ScrollFrame
        if scrollFrame:GetVerticalScrollRange() > 0 then
            local yOffset = 0
            for i = 1, stepindex - 1 do
                local prevContainer = APR.questOrderList.stepList[i]
                yOffset = yOffset + (prevContainer and prevContainer:GetHeight() or 0)
            end
            scrollFrame:SetVerticalScroll(yOffset)
        end
    end)
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

local function AddStepFrameWithQuest(stepIndex, stepText, questInfo, color)
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
                APR.questOrderList.questID = string.sub(quest.questID, 1, string.find(quest.questID, "-") - 1)
            else
                APR.questOrderList.questID = quest.questID
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

local function AddStepFrame(stepIndex, stepText, color)
    AddStepFrameWithQuest(stepIndex, stepText, {}, color)
end

-- Remove all quest steps
function APR.questOrderList:RemoveSteps()
    for _, questContainer in pairs(self.stepList) do
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
    if contentHeight > 0 then
        QuestOrderListFrame_ScrollChild:SetHeight(contentHeight)
    end
end

local function isQuestCompleted(questID)
    return C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.ActiveQuests[questID]
end

function APR.questOrderList:AddStepFromRoute(forceRendering)
    if not APR.settings.profile.enableAddon or not APR.settings.profile.showQuestOrderList or not APR.RouteQuestStepList[APR.ActiveRoute] or not APR.routeconfig:HasRouteInCustomPaht() or not APR:IsInstanceWithUI() then
        self:RemoveSteps()
        APR.questOrderList.questID = nil
        return
    end

    APR:Debug("Function: APR.questOrderList:AddStepFromRoute - ", APR.ActiveRoute)

    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if not CurStep then
        return
    end

    -- Compare the current step index with the stored one
    if CurStep == self.currentStepIndex and not forceRendering then
        return
    end

    -- Store the current step index
    self.currentStepIndex = CurStep
    -- Clean list
    self:RemoveSteps()

    QuestOrderListPanel:Show()
    CurStep = CurStep - (APRData[APR.PlayerID][APR.ActiveRoute .. '-SkippedStep'] or 0)
    -- can't use id from the loop due to faction/race/class/achievement step option
    local stepIndex = 1
    for id, step in pairs(APR.RouteQuestStepList[APR.ActiveRoute]) do
        -- Hide step for Faction, Race, Class, Achievement
        if APR:StepFilterQoL(step) then
            if step.ExitTutorial then
                local questID = step.ExitTutorial
                local color = (C_QuestLog.IsOnQuest(questID) or CurStep > stepIndex) and "green" or "gray"
                AddStepFrame(stepIndex, L["SKIP_TUTORIAL"], color)
            elseif step.BuyMerchant and not step.Qpart then
                local buyMerchant = step.BuyMerchant
                local questInfo = {}
                local flagged = 0
                for _, item in ipairs(buyMerchant) do
                    if C_QuestLog.IsQuestFlaggedCompleted(item.questID) or CurStep > stepIndex then
                        flagged = flagged + 1
                    else
                        local itemName = C_Item.GetItemInfo(item.itemID) or UNKNOWN
                        table.insert(questInfo, { questID = item.quantity, questName = itemName })
                    end
                end
                if #buyMerchant == flagged then
                    AddStepFrame(stepIndex, L["BUY"], "green")
                else
                    AddStepFrameWithQuest(stepIndex, L["BUY"], questInfo, "gray")
                end
            elseif step.PickUp then
                local idList = step.PickUp
                local dbList = step.PickUpDB or {}
                local questInfo = {}
                local flagged = 0

                for _, questID in pairs(idList) do
                    if isQuestCompleted(questID) then
                        flagged = flagged + 1
                    else
                        for _, dbQuestID in pairs(dbList) do
                            if isQuestCompleted(dbQuestID) then
                                flagged = flagged + 1
                                break
                            end
                        end
                        if flagged == 0 then
                            table.insert(questInfo,
                                { questID = questID, questName = C_QuestLog.GetTitleForQuestID(questID) })
                        end
                    end
                end

                if #idList == flagged then
                    AddStepFrame(stepIndex, L["PICK_UP_Q"], "green")
                else
                    AddStepFrameWithQuest(stepIndex, L["PICK_UP_Q"], questInfo, "gray")
                end
            elseif step.DropQuest then
                local questData = step.DroppableQuest
                local questID = questData.Qid
                local MobId = questData.MobId
                local MobName = APRData.NPCList[MobId] or questData.Text
                local questText = format(L["Q_DROP"], MobName)
                local questInfo = { { questID = questID, questName = C_QuestLog.GetTitleForQuestID(questID) } }
                local color = isQuestCompleted(questID) and "green" or
                    "gray"
                AddStepFrameWithQuest(stepIndex, questText, questInfo, color)
            elseif step.Qpart then
                local idList = step.Qpart
                local dbList = step.QpartDB or {}
                local questInfo = {}
                local flagged = 0
                local total = 0

                local isMaxLevel = UnitLevel("player") == APR.MaxLevel

                local function isObjectiveCompleted(questID, objectiveIndex)
                    -- 1- quest completed
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) then
                        return true
                    end

                    -- 2- questB Bonus or skipped
                    local questObjectiveId = questID .. '-' .. objectiveIndex
                    if (isMaxLevel and APR.BonusObj and APR:Contains(APR.BonusObj, questObjectiveId)) or APRData[APR.PlayerID].BonusSkips[questID] then
                        return true
                    end

                    -- 3- quest objective completed
                    local quest = APR.ActiveQuests[questID]
                    if quest and quest.objectives and quest.objectives[objectiveIndex] then
                        return quest.objectives[objectiveIndex].status == APR.QUEST_STATUS.COMPLETE
                    end
                    return false
                end

                for questID, objectives in pairs(idList) do
                    for _, objectiveIndex in pairs(objectives) do
                        total = total + 1
                        if isObjectiveCompleted(questID, objectiveIndex) then
                            flagged = flagged + 1
                        else
                            for _, dbQuestID in pairs(dbList) do
                                if dbQuestID == questID or isObjectiveCompleted(dbQuestID, objectiveIndex) then
                                    flagged = flagged + 1
                                    break
                                end
                            end
                            if flagged == 0 then
                                table.insert(questInfo,
                                    {
                                        questID = questID .. '-' .. objectiveIndex,
                                        questName = C_QuestLog
                                            .GetTitleForQuestID(questID)
                                    })
                            end
                        end
                    end
                end

                if total == flagged then
                    AddStepFrame(stepIndex, L["Q_PART"], "green")
                else
                    AddStepFrameWithQuest(stepIndex, L["Q_PART"], questInfo, "gray")
                end
            elseif step.QpartPart then
                local idList = step.QpartPart
                local questInfo = {}
                local flagged = 0
                local total = 0
                for questID, objectives in pairs(idList) do
                    for _, objectiveIndex in pairs(objectives) do
                        total = total + 1
                        local questObjectiveId = questID .. '-' .. objectiveIndex
                        local quest = APR.ActiveQuests[questID]
                        local questObjective = quest and quest.objectives and quest.objectives[objectiveIndex] or nil
                        local text = questObjective and questObjective.text or nil
                        local status = questObjective and questObjective.status or nil
                        for key, value in pairs(step) do
                            if string.match(key, "TrigText+") then
                                if value and text and string.find(text, value) then
                                    flagged = flagged + 1
                                end
                            end
                        end
                        local objective = C_QuestLog.GetQuestObjectives(questID)
                        if C_QuestLog.IsQuestFlaggedCompleted(questID) or (objective and objective[objectiveIndex] and objective[objectiveIndex].finished) or (status == APR.QUEST_STATUS.COMPLETE) then
                            flagged = flagged + 1
                        else
                            table.insert(questInfo,
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
                local idList = step.Done
                local dbList = step.DoneDB or {}
                local questInfo = {}
                local flagged = 0

                local function isQuestCompleted(questID)
                    return C_QuestLog.IsQuestFlaggedCompleted(questID)
                end

                for _, questID in pairs(idList) do
                    if isQuestCompleted(questID) then
                        flagged = flagged + 1
                    else
                        for _, dbQuestID in pairs(dbList) do
                            if isQuestCompleted(dbQuestID) then
                                flagged = flagged + 1
                                break
                            end
                        end
                        if flagged == 0 then
                            table.insert(questInfo,
                                { questID = questID, questName = C_QuestLog.GetTitleForQuestID(questID) })
                        end
                    end
                end

                if #idList == flagged then
                    AddStepFrame(stepIndex, L["TURN_IN_Q"], "green")
                else
                    AddStepFrameWithQuest(stepIndex, L["TURN_IN_Q"], questInfo, "gray")
                end
            elseif step.Scenario then
                local scenario = step.Scenario
                local scenarioInfo = C_ScenarioInfo.GetScenarioInfo()
                if not scenarioInfo then
                    if CurStep > stepIndex then
                        AddStepFrame(stepIndex, L["SCENARIO"], "green")
                    else
                        local scenarioStepInfo = C_ScenarioInfo.GetScenarioStepInfo(scenario.stepID)
                        local criteriaInfo = C_ScenarioInfo.GetCriteriaInfoByStep(scenario.stepID, scenario
                            .criteriaIndex)
                        local questInfo = { { questID = scenarioStepInfo.title, questName = criteriaInfo.description } }
                        AddStepFrameWithQuest(stepIndex, L["SCENARIO"], questInfo, "gray")
                    end
                else
                    local criteriaInfo = C_ScenarioInfo.GetCriteriaInfoByStep(scenario.stepID, scenario.criteriaIndex)
                    local color = criteriaInfo.completed or CurStep > stepIndex and "green" or "gray";
                    local questInfo = { { questID = scenario.criteriaIndex, questName = criteriaInfo.description } }
                    AddStepFrameWithQuest(stepIndex,
                        L["SCENARIO"] .. " - " .. scenarioInfo.name, questInfo, color)
                end
            elseif step.EnterScenario then
                local scenarioMapID = step.EnterScenario
                local currentMapID = C_Map.GetBestMapForUnit('player')
                local scenarioContinentID = APR:GetContinent(scenarioMapID)
                local mapInfo = C_Map.GetMapInfo(scenarioMapID)
                local scenarioInfo = APR.ZonesData.Scenarios[scenarioContinentID][scenarioMapID]
                local isCompleted = tContains(APRScenarioMapIDCompleted[APR.PlayerID], scenarioMapID)

                local color = (scenarioMapID == currentMapID or isCompleted or CurStep > stepIndex) and "green" or "gray";
                local questInfo = { { questID = mapInfo.name } }
                AddStepFrameWithQuest(stepIndex, format(L["ENTER_IN"], L[scenarioInfo.type]), questInfo, color)
            elseif step.DoScenario then
                local scenarioMapID = step.DoScenario
                local scenarioContinentID = APR:GetContinent(scenarioMapID)
                local mapInfo = C_Map.GetMapInfo(scenarioMapID)
                local scenarioInfo = APR.ZonesData.Scenarios[scenarioContinentID][scenarioMapID]
                local isCompleted = tContains(APRScenarioMapIDCompleted[APR.PlayerID], scenarioMapID)
                local hasQpartCompleted = false

                if step.Qpart then
                    local questID = next(step.Qpart)
                    local quest = APR.ActiveQuests[questID]
                    if (quest and quest.status == APR.QUEST_STATUS.COMPLETE) and isCompleted then
                        hasQpartCompleted = true
                    end
                end

                local color = (hasQpartCompleted and isCompleted) or CurStep > stepIndex and "green" or "gray";
                local questInfo = { { questID = mapInfo.name } }
                AddStepFrameWithQuest(stepIndex, format(L["COMPLETE_SOMETHING"], L[scenarioInfo.type]), questInfo, color)
            elseif step.LeaveScenario then
                local scenarioMapID       = step.LeaveScenario
                local currentMapID        = C_Map.GetBestMapForUnit('player')
                local scenarioContinentID = APR:GetContinent(scenarioMapID)
                local mapInfo             = C_Map.GetMapInfo(scenarioMapID)
                local scenarioInfo        = APR.ZonesData.Scenarios[scenarioContinentID][scenarioMapID]
                local isCompleted         = tContains(APRScenarioMapIDCompleted[APR.PlayerID], scenarioMapID)

                local color               = ((scenarioMapID ~= currentMapID and isCompleted) or CurStep > stepIndex) and
                    "green" or "gray";
                local questInfo           = { { questID = mapInfo.name } }
                AddStepFrameWithQuest(stepIndex, L["LEAVE_" .. scenarioInfo.type], questInfo, color)
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
                local color = (APR:HasTaxiNode(nodeID) or CurStep > stepIndex) and "green" or "gray"
                AddStepFrame(stepIndex, L["GET_FLIGHTPATH"], color)
            elseif step.UseFlightPath then
                local questID = step.UseFlightPath
                local questText = step.Boat and L["USE_BOAT"] or L["USE_FLIGHTPATH"]
                local questInfo = { { questID = APR:GetTaxiNodeName(step) } }
                local color = (C_QuestLog.IsQuestFlaggedCompleted(questID) or CurStep > stepIndex) and "green" or "gray"
                AddStepFrameWithQuest(stepIndex, questText, questInfo, color)
            elseif step.LearnProfession then
                local spellID = step.LearnProfession
                local name = C_Spell.GetSpellInfo(spellID).name
                local questInfo = { { questID = name } }
                local color = IsSpellKnown(spellID) and "green" or "gray"
                AddStepFrameWithQuest(stepIndex, L["LEARN_PROFESSION"], questInfo, color)
            elseif step.LootItem then
                local itemID = step.LootItem
                local itemName, _, _, _, _, _, _, _, _, _ = C_Item.GetItemInfo(itemID)
                local name = itemName or UNKNOWN
                local color = tContains(APRItemLooted[APR.PlayerID], itemID) and "green" or "gray"
                AddStepFrame(stepIndex, format(L["LOOT_ITEM"], name), color)
            elseif step.WarMode then
                local color = C_PvP.IsWarModeActive() and "green" or "gray"
                AddStepFrame(stepIndex, L["TURN_ON_WARMODE"], color)
            elseif step.Grind then
                local color = UnitLevel("player") <= step.Grind and "green" or "gray"
                AddStepFrame(stepIndex, L["GRIND"] .. " " .. step.Grind, color)
            elseif (step.GossipOptionIDs or step.GossipOptionID) and step.NPCIDs then
                AddStepFrame(stepIndex, L["TALK_NPC"], "gray")
            elseif step.RouteCompleted then
                AddStepFrame(stepIndex, L["ROUTE_COMPLETED"], "gray")
            end
            stepIndex = stepIndex + 1
        end
    end
    -- set current Step indicator
    SetCurrentStepIndicator(CurStep)
end

function APR.questOrderList:DelayedUpdate()
    if self.updateTimer then
        self.pendingUpdate = true
    else
        self:AddStepFromRoute()
        self.updateTimer = C_Timer.NewTimer(0.8, function()
            if self.pendingUpdate then
                self:AddStepFromRoute()
                self.pendingUpdate = false
                self.updateTimer = C_Timer.NewTimer(0.8, function()
                    self.updateTimer = nil
                end)
            else
                self.updateTimer = nil
            end
        end)
    end
end
