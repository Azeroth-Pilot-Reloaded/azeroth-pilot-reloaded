local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR Quest Order List module
APR.questOrderList = APR:NewModule("QuestOrderList")
APR.questOrderList.stepList = {}
APR.questOrderList.questID = nil
APR.questOrderList.currentStepIndex = nil
APR.questOrderList.updateTimer = nil
APR.questOrderList.pendingUpdate = false

local QuestOrderListUtils = APR.questOrderListUtils
local getSnapAnchor
local snapToAnchor
local updateSnapSizing
local QuestOrderListFrame
local QuestOrderListFrame_StepHolder
local QuestOrderListFrame_ScrollFrame
local QuestOrderListFrame_ScrollChild
local QuestOrderListFrame_StepHolderHeader

-- Local constants
local FRAME_WIDTH = 258
local FRAME_HEIGHT = 300
local FRAME_MIN_WIDTH = FRAME_WIDTH
local FRAME_MIN_HEIGHT = 100
local FRAME_OFFSET = 10
local FRAME_DATA_START = 0
local SNAP_ANCHOR_GAP = 30
local resizeButton

local function isFrameSuppressed()
    return not APR.settings.profile.showQuestOrderList or not APR.settings.profile.enableAddon or
        C_PetBattles.IsInBattle() or not APR:IsInstanceWithUI()
end

local function canRenderSteps()
    return not isFrameSuppressed() and APR.RouteQuestStepList[APR.ActiveRoute] and APR.routeconfig:HasRouteInCustomPaht()
end

local function buildLayout()
    return {
        scrollChild = QuestOrderListFrame_ScrollChild,
        frameWidth = FRAME_WIDTH,
        frameOffset = FRAME_OFFSET,
        dataHeight = FRAME_DATA_START
    }
end

local function colorByCompletion(isCompleted, currentStep, stepIndex)
    return (isCompleted or (currentStep and currentStep > stepIndex)) and "green" or "gray"
end

local function getQuestName(questID)
    return C_QuestLog.GetTitleForQuestID(questID) or UNKNOWN
end

local function isSnapEnabled()
    return APR.settings.profile.questOrderListSnapToCurrentStep
end

function APR.questOrderList:IsSnapped()
    return isSnapEnabled() and getSnapAnchor() ~= nil
end

getSnapAnchor = function()
    if not isSnapEnabled() then
        return nil
    end

    local currentStepPanel = _G.CurrentStepScreenPanel
    if not currentStepPanel or not currentStepPanel:IsShown() or currentStepPanel.collapsed then
        return nil
    end

    -- Use centralized snap anchor logic from Core
    -- Hierarchy: Fillers (highest) -> AFK (medium) -> CurrentStep (lowest)
    local anchorFrame, anchorHeight = APR:GetSnapAnchorFrame()
    return anchorFrame, anchorHeight
end

snapToAnchor = function(anchorFrame, anchorHeight)
    if not anchorFrame or not QuestOrderListPanel then
        return false
    end

    local effectiveHeight = (anchorHeight and anchorHeight > 0) and anchorHeight or (anchorFrame:GetHeight() or 0)
    -- Use centralized snap positioning helper (no header adjustment for QuestOrderList)
    return APR:SnapFrameToAnchor(QuestOrderListPanel, anchorFrame, effectiveHeight, SNAP_ANCHOR_GAP, nil)
end

updateSnapSizing = function(anchored, anchorFrame)
    if not QuestOrderListFrame then
        return
    end

    if anchored and anchorFrame then
        QuestOrderListFrame:SetResizable(true)
        if resizeButton then
            resizeButton:Show()
            resizeButton:EnableMouse(true)
        end
        if QuestOrderListFrame_StepHolderHeader and QuestOrderListFrame_StepHolderHeader.MinimizeButton then
            QuestOrderListFrame_StepHolderHeader.MinimizeButton:Hide()
        end

        local anchorWidth = anchorFrame:GetWidth()
        if anchorWidth and anchorWidth > 0 then
            local maxHeight = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 2000
            QuestOrderListFrame:SetWidth(anchorWidth)
            QuestOrderListFrame_StepHolder:SetWidth(anchorWidth)
            QuestOrderListFrame_ScrollChild:SetWidth(anchorWidth)
            -- Keep width in sync with the parent while still allowing the user to resize height.
            QuestOrderListFrame:SetResizeBounds(anchorWidth, FRAME_MIN_HEIGHT, anchorWidth, maxHeight)
        end
    else
        QuestOrderListFrame:SetResizeBounds(FRAME_MIN_WIDTH, FRAME_MIN_HEIGHT)
        QuestOrderListFrame:SetResizable(true)
        if resizeButton then
            resizeButton:Show()
            resizeButton:EnableMouse(true)
        end
        if QuestOrderListFrame_StepHolderHeader and QuestOrderListFrame_StepHolderHeader.MinimizeButton then
            QuestOrderListFrame_StepHolderHeader.MinimizeButton:Show()
        end
    end
end

---------------------------------------------------------------------------------------
---------------------------- Quest Order List Frames ----------------------------------
---------------------------------------------------------------------------------------

QuestOrderListFrame = APR:CreateStandardFrame("QuestOrderListPanel", UIParent, FRAME_WIDTH, FRAME_HEIGHT,
    "BackdropTemplate")

QuestOrderListFrame:SetResizable(true)
QuestOrderListFrame:SetResizeBounds(FRAME_MIN_WIDTH, FRAME_MIN_HEIGHT)
APR:SetupFrameDrag(QuestOrderListFrame, function()
    return not APR.settings.profile.questOrderListSnapToCurrentStep and not APR.settings.profile.questOrderListLock
end, function()
    LibWindow.SavePosition(QuestOrderListPanel)
end)
QuestOrderListFrame:SetScript("OnSizeChanged", function(self, width, height)
    FRAME_WIDTH = width
    FRAME_HEIGHT = height
    QuestOrderListFrame_StepHolder:SetSize(width, height)
    APR.questOrderList:UpdateFrameContents()
    if not APR.questOrderList:IsSnapped() then
        LibWindow.SavePosition(QuestOrderListPanel)
    end
end)

-- Create the step holder frame
QuestOrderListFrame_StepHolder = CreateFrame("Frame", "QuestOrderListFrame_StepHolder", QuestOrderListFrame,
    "BackdropTemplate")
QuestOrderListFrame_StepHolder:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
QuestOrderListFrame_StepHolder:SetAllPoints()

-- Create a scroll frame for the step holder
QuestOrderListFrame_ScrollFrame = CreateFrame("ScrollFrame", "QuestOrderListFrame_ScrollFrame",
    QuestOrderListFrame_StepHolder, "UIPanelScrollFrameTemplate")
QuestOrderListFrame_ScrollFrame:SetPoint("TOPLEFT", QuestOrderListFrame_StepHolder, "TOPLEFT", 0, 0)
QuestOrderListFrame_ScrollFrame:SetPoint("BOTTOMRIGHT", QuestOrderListFrame_StepHolder, "BOTTOMRIGHT", -22, 0)

-- Create a child frame for the scroll frame
QuestOrderListFrame_ScrollChild = CreateFrame("Frame", "QuestOrderListFrame_ScrollChild",
    QuestOrderListFrame_ScrollFrame)
QuestOrderListFrame_ScrollChild:SetSize(FRAME_WIDTH, 1)
QuestOrderListFrame_ScrollFrame:SetScrollChild(QuestOrderListFrame_ScrollChild)

-- Create the frame header
QuestOrderListFrame_StepHolderHeader = APR:CreateFrameHeader("QuestOrderListFrame_StepHolderHeader",
    QuestOrderListFrame, L["QUEST_ORDER_LIST"], "ObjectiveTrackerContainerHeaderTemplate")
QuestOrderListFrame_StepHolderHeader:SetPoint("TOPLEFT", QuestOrderListFrame, "TOPLEFT", 0, 30)

APR:SetupHeaderDrag(QuestOrderListFrame_StepHolderHeader, QuestOrderListFrame, function()
    return not APR.settings.profile.questOrderListLock and not APR.settings.profile.questOrderListSnapToCurrentStep
end, function()
    LibWindow.SavePosition(QuestOrderListPanel)
end)

-- Customize minimize button to close instead of collapse
QuestOrderListFrame_StepHolderHeader.MinimizeButton:GetNormalTexture():SetAtlas("redbutton-exit")
QuestOrderListFrame_StepHolderHeader.MinimizeButton:GetPushedTexture():SetAtlas("redbutton-exit-pressed")
QuestOrderListFrame_StepHolderHeader.MinimizeButton:SetScript("OnClick", function(self)
    if APR.questOrderList:IsSnapped() then return end
    APR.settings.profile.showQuestOrderList = false
    QuestOrderListPanel:Hide()
end)


resizeButton = CreateFrame("Button", "QuestOrderListFrameResizeHandle", QuestOrderListFrame)
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

function APR.questOrderList:ApplySnapAnchor()
    if not QuestOrderListFrame or not QuestOrderListPanel then
        return false
    end
    local anchorFrame, anchorHeight = getSnapAnchor()
    local anchored = snapToAnchor(anchorFrame, anchorHeight)
    updateSnapSizing(anchored, anchorFrame)
    return anchored
end

function APR.questOrderList:RefreshFrameAnchor()
    if isFrameSuppressed() then
        QuestOrderListPanel:Hide()
        return
    end
    if isSnapEnabled() then
        local currentStepPanel = _G.CurrentStepScreenPanel
        if currentStepPanel and currentStepPanel.collapsed then
            QuestOrderListPanel:Hide()
            return
        end
    end
    QuestOrderListFrame:EnableMouse(not APR.settings.profile.questOrderListLock)

    self:UpdateFrameScale()
    self:UpdateBackgroundColorAlpha()

    local anchored = self:ApplySnapAnchor()

    if not anchored then
        LibWindow.RestorePosition(QuestOrderListPanel)
    end

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

-- Remove all quest steps
function APR.questOrderList:RemoveSteps(hideFrame)
    for _, questContainer in pairs(self.stepList) do
        questContainer:Hide()
        questContainer:ClearAllPoints()
    end
    wipe(self.stepList)
    if hideFrame ~= false then
        QuestOrderListFrame:Hide()
    end
end

function APR.questOrderList:UpdateFrameContents()
    local contentHeight = 0
    local layout = buildLayout()

    for _, container in ipairs(self.stepList) do
        contentHeight = contentHeight + QuestOrderListUtils:UpdateContainerLayout(container, layout)
    end

    QuestOrderListFrame_ScrollChild:SetWidth(FRAME_WIDTH)
    if contentHeight > 0 then
        QuestOrderListFrame_ScrollChild:SetHeight(contentHeight)
    end
end

function APR.questOrderList:AddStepFromRoute(forceRendering)
    if not canRenderSteps() then
        self:RemoveSteps()
        APR.questOrderList.questID = nil
        return
    end
    if isSnapEnabled() then
        local currentStepPanel = _G.CurrentStepScreenPanel
        if currentStepPanel and currentStepPanel.collapsed then
            QuestOrderListPanel:Hide()
            return
        end
        self:ApplySnapAnchor()
    end

    APR:Debug("Function: APR.questOrderList:AddStepFromRoute - ", APR.ActiveRoute)

    local currentStepIndex = APRData[APR.PlayerID][APR.ActiveRoute]
    if not currentStepIndex then
        return
    end

    -- Compare the current step index with the stored one
    if currentStepIndex == self.currentStepIndex and not forceRendering then
        return
    end

    -- Store the current step index
    self.currentStepIndex = currentStepIndex
    -- Clean list
    self:RemoveSteps(false)
    self.questID = nil

    QuestOrderListPanel:Show()
    currentStepIndex = currentStepIndex - (APRData[APR.PlayerID][APR.ActiveRoute .. '-SkippedStep'] or 0)
    local layout = buildLayout()
    local playerID = APR.PlayerID
    local playerData = playerID and APRData and APRData[playerID] or nil

    local function safeTContains(list, value)
        return list ~= nil and tContains(list, value) or false
    end

    -- can't use id from the loop due to faction/race/class/achievement step option
    local stepIndex = 1
    for _, step in ipairs(APR.RouteQuestStepList[APR.ActiveRoute]) do
        -- Hide step for Faction, Race, Class, Achievement
        if APR:StepFilterQoL(step) then
            local container
            local activeQuestId
            local isCurrentStep = stepIndex == currentStepIndex

            if step.ExitTutorial then
                local questID = step.ExitTutorial
                local color = colorByCompletion(C_QuestLog.IsOnQuest(questID), currentStepIndex, stepIndex)
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["SKIP_TUTORIAL"],
                    color, isCurrentStep)
            elseif step.BuyMerchant and not step.Qpart then
                local buyMerchant = step.BuyMerchant
                local questInfo = {}
                local flagged = 0
                for _, item in ipairs(buyMerchant) do
                    if C_QuestLog.IsQuestFlaggedCompleted(item.questID) or currentStepIndex > stepIndex then
                        flagged = flagged + 1
                    else
                        local itemName = C_Item.GetItemInfo(item.itemID) or UNKNOWN
                        table.insert(questInfo, { questID = item.quantity, questName = itemName })
                    end
                end
                if #buyMerchant == flagged then
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["BUY"], "green",
                        isCurrentStep)
                else
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex, L["BUY"],
                        questInfo, "gray", isCurrentStep)
                end
            elseif step.PickUp then
                local idList = step.PickUp
                local dbList = step.PickUpDB or {}
                local questInfo = {}
                local flagged = 0

                for _, questID in pairs(idList) do
                    if QuestOrderListUtils:IsQuestCompletedOrActive(questID) then
                        flagged = flagged + 1
                    else
                        for _, dbQuestID in pairs(dbList) do
                            if QuestOrderListUtils:IsQuestCompletedOrActive(dbQuestID) then
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
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["PICK_UP_Q"],
                        "green", isCurrentStep)
                else
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                        L["PICK_UP_Q"], questInfo, "gray", isCurrentStep)
                end
            elseif step.DropQuest then
                local questData = step.DroppableQuest
                local questID = questData and questData.Qid or 1
                local MobId = questData and questData.MobId or 1
                local MobName = APRData.NPCList[MobId] or (questData and questData.Text or UNKNOWN)
                local questText = format(L["Q_DROP"], MobName)
                local questInfo = { { questID = questID, questName = getQuestName(questID) } }
                local color = QuestOrderListUtils:IsQuestCompletedOrActive(questID) and "green" or "gray"
                container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex, questText,
                    questInfo, color, isCurrentStep)
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
                    local bonusSkips = playerData and playerData.BonusSkips or nil
                    if (isMaxLevel and APR.BonusObj and APR:Contains(APR.BonusObj, questObjectiveId)) or
                        (bonusSkips and bonusSkips[questID]) then
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
                                        questName = getQuestName(questID)
                                    })
                            end
                        end
                    end
                end

                if total == flagged then
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["Q_PART"],
                        "green", isCurrentStep)
                else
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                        L["Q_PART"], questInfo, "gray", isCurrentStep)
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
                            if string.match(key, "TrigText+") and value and text then
                                if APR:TrigTextValueMatch(value, text) then
                                    flagged = flagged + 1
                                end
                            end
                        end
                        local objective = C_QuestLog.GetQuestObjectives(questID)
                        if C_QuestLog.IsQuestFlaggedCompleted(questID) or (objective and objective[objectiveIndex] and objective[objectiveIndex].finished) or (status == APR.QUEST_STATUS.COMPLETE) then
                            flagged = flagged + 1
                        else
                            table.insert(questInfo,
                                { questID = questObjectiveId, questName = getQuestName(questID) })
                        end
                    end
                end
                if total == flagged then
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["Q_PART"],
                        "green", isCurrentStep)
                else
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                        L["Q_PART"], questInfo, "gray", isCurrentStep)
                end
            elseif step.Treasure then
                local questID = step.Treasure
                local questInfo = { { questID = questID, questName = getQuestName(questID) } }
                local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, stepIndex)
                container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                    L["GET_TREASURE"], questInfo, color, isCurrentStep)
            elseif step.Group then
                local questID = step.Group.QuestId
                local questInfo = { { questID = questID, questName = getQuestName(questID) } }
                local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, stepIndex)
                container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex, L["GROUP_Q"],
                    questInfo, color, isCurrentStep)
            elseif step.Done then
                local idList = step.Done
                local dbList = step.DoneDB or {}
                local questInfo = {}
                local flagged = 0

                for _, questID in pairs(idList) do
                    if QuestOrderListUtils:IsQuestCompleted(questID) then
                        flagged = flagged + 1
                    else
                        for _, dbQuestID in pairs(dbList) do
                            if QuestOrderListUtils:IsQuestCompleted(dbQuestID) then
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
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["TURN_IN_Q"],
                        "green", isCurrentStep)
                else
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                        L["TURN_IN_Q"], questInfo, "gray", isCurrentStep)
                end
            elseif step.Scenario then
                local scenario = step.Scenario
                local scenarioInfo = C_ScenarioInfo.GetScenarioInfo()
                if not scenarioInfo then
                    if currentStepIndex > stepIndex then
                        container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["SCENARIO"],
                            "green", isCurrentStep)
                    else
                        local scenarioStepInfo = C_ScenarioInfo.GetScenarioStepInfo(scenario.stepID)
                        local criteriaInfo = C_ScenarioInfo.GetCriteriaInfoByStep(scenario.stepID, scenario
                            .criteriaIndex)
                        local questInfo = { { questID = scenarioStepInfo.title, questName = criteriaInfo.description } }
                        container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                            L["SCENARIO"], questInfo, "gray", isCurrentStep)
                    end
                else
                    local criteriaInfo = C_ScenarioInfo.GetCriteriaInfoByStep(scenario.stepID, scenario.criteriaIndex)
                    local color = criteriaInfo.completed or currentStepIndex > stepIndex and "green" or "gray";
                    local questInfo = { { questID = scenario.criteriaIndex, questName = criteriaInfo.description } }
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                        L["SCENARIO"] .. " - " .. scenarioInfo.name, questInfo, color, isCurrentStep)
                end
            elseif step.EnterScenario then
                local scenarioMapID = step.EnterScenario
                local currentMapID = C_Map.GetBestMapForUnit('player')
                local scenarioContinentID = APR:GetContinent(scenarioMapID)
                local mapInfo = APR:GetMapInfoCached(scenarioMapID)
                local mapName = mapInfo and mapInfo.name or UNKNOWN
                local scenariosByContinent = scenarioContinentID and APR.ZonesData and APR.ZonesData.Scenarios and
                    APR.ZonesData.Scenarios[scenarioContinentID] or nil
                local scenarioInfo = scenariosByContinent and scenariosByContinent[scenarioMapID] or nil
                local isCompleted = safeTContains(
                    APRScenarioMapIDCompleted and playerID and APRScenarioMapIDCompleted[playerID] or nil,
                    scenarioMapID)
                local scenarioTypeLabel = (scenarioInfo and scenarioInfo.type and L[scenarioInfo.type]) or L["SCENARIO"] or
                    UNKNOWN

                local color = (scenarioMapID == currentMapID or isCompleted or currentStepIndex > stepIndex) and "green" or
                    "gray";
                local questInfo = { { questID = mapName } }
                container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                    format(L["ENTER_IN"], scenarioTypeLabel), questInfo, color, isCurrentStep)
            elseif step.DoScenario then
                local scenarioMapID = step.DoScenario
                local scenarioContinentID = APR:GetContinent(scenarioMapID)
                local mapInfo = APR:GetMapInfoCached(scenarioMapID)
                local mapName = mapInfo and mapInfo.name or UNKNOWN
                local scenariosByContinent = scenarioContinentID and APR.ZonesData and APR.ZonesData.Scenarios and
                    APR.ZonesData.Scenarios[scenarioContinentID] or nil
                local scenarioInfo = scenariosByContinent and scenariosByContinent[scenarioMapID] or nil
                local isCompleted = safeTContains(
                    APRScenarioMapIDCompleted and playerID and APRScenarioMapIDCompleted[playerID] or nil,
                    scenarioMapID)
                local scenarioTypeLabel = (scenarioInfo and scenarioInfo.type and L[scenarioInfo.type]) or L["SCENARIO"] or
                    UNKNOWN
                local hasQpartCompleted = false

                local qpart = step.Qpart
                if qpart and type(qpart) == "table" then
                    local questID = next(qpart)
                    if questID then
                        local quest = APR.ActiveQuests[questID]
                        if (quest and quest.status == APR.QUEST_STATUS.COMPLETE) and isCompleted then
                            hasQpartCompleted = true
                        end
                    end
                end

                local color = (hasQpartCompleted and isCompleted) or currentStepIndex > stepIndex and "green" or "gray";
                local questInfo = { { questID = mapName } }
                container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                    format(L["COMPLETE_SOMETHING"], scenarioTypeLabel), questInfo, color, isCurrentStep)
            elseif step.LeaveScenario then
                local scenarioMapID        = step.LeaveScenario
                local currentMapID         = C_Map.GetBestMapForUnit('player')
                local scenarioContinentID  = APR:GetContinent(scenarioMapID)
                local mapInfo              = APR:GetMapInfoCached(scenarioMapID)
                local mapName              = mapInfo and mapInfo.name or UNKNOWN
                local scenariosByContinent = scenarioContinentID and APR.ZonesData and APR.ZonesData.Scenarios and
                    APR.ZonesData.Scenarios[scenarioContinentID] or nil
                local scenarioInfo         = scenariosByContinent and scenariosByContinent[scenarioMapID] or nil
                local isCompleted          = safeTContains(
                    APRScenarioMapIDCompleted and playerID and APRScenarioMapIDCompleted[playerID] or nil,
                    scenarioMapID)

                local color                = ((scenarioMapID ~= currentMapID and isCompleted) or currentStepIndex > stepIndex) and
                    "green" or "gray";
                local questInfo            = { { questID = mapName } }
                local leaveKey             = scenarioInfo and scenarioInfo.type and ("LEAVE_" .. scenarioInfo.type) or
                    nil
                local leaveText            = (leaveKey and L[leaveKey]) or L["SCENARIO"] or UNKNOWN
                container, activeQuestId   = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                    leaveText, questInfo, color, isCurrentStep)
            elseif step.TakePortal then
                local portalData = step.TakePortal
                local questID = portalData.QuestID
                local zoneId = portalData.ZoneId
                local currentMapID = C_Map.GetBestMapForUnit("player")
                local parentMapID = APR:GetPlayerParentMapID()
                local arrived = zoneId and (currentMapID == zoneId or parentMapID == zoneId)
                local completed = (questID and C_QuestLog.IsQuestFlaggedCompleted(questID)) or arrived
                local color = colorByCompletion(completed, currentStepIndex, stepIndex)
                local mapInfo = APR:GetMapInfoCached(zoneId)
                local zoneName = (mapInfo and mapInfo.name) or UNKNOWN
                local stepText = string.format(L["USE_PORTAL_TO"], ':')
                local questInfo = { { questID = zoneName } }
                container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                    stepText, questInfo, color, isCurrentStep)
            elseif step.Waypoint then
                local questID = step.Waypoint
                local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, stepIndex)
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["RUN_WAYPOINT"],
                    color, isCurrentStep)
            elseif step.SetHS then
                local questID = step.SetHS
                local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, stepIndex)
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["SET_HEARTHSTONE"],
                    color, isCurrentStep)
            elseif step.UseHS or step.UseDalaHS or step.UseGarrisonHS then
                local questID = step.UseHS or step.UseDalaHS or step.UseGarrisonHS
                local questText = step.UseHS and L["USE_HEARTHSTONE"] or
                    (step.UseDalaHS and L["USE_DALARAN_HEARTHSTONE"] or L["USE_GARRISON_HEARTHSTONE"])
                local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, stepIndex)
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, questText, color,
                    isCurrentStep)
            elseif step.UseItem then
                local questID = step.UseItem.questID
                local itemID = step.UseItem.itemID
                local itemName = C_Item.GetItemInfo(itemID)
                local questText = L["USE_ITEM"] .. ": " .. (itemName or UNKNOWN)
                local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, stepIndex)
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, questText, color,
                    isCurrentStep)
            elseif step.UseSpell then
                local questID = step.UseSpell.questID
                local spellID = step.UseSpell.spellID
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                local questText = L["USE_SPELL"] .. ": " .. ((spellInfo and spellInfo.name) or UNKNOWN)
                local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, stepIndex)
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, questText, color,
                    isCurrentStep)
            elseif step.GetFP then
                local nodeID = step.GetFP
                local color = (APR:HasTaxiNode(nodeID) or currentStepIndex > stepIndex) and "green" or "gray"
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["GET_FLIGHTPATH"],
                    color, isCurrentStep)
            elseif step.UseFlightPath then
                local questID = step.UseFlightPath
                local questText = step.Boat and L["USE_BOAT"] or L["USE_FLIGHTPATH"]
                local questInfo = { { questID = APR:GetTaxiNodeName(step) } }
                local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, stepIndex)
                container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex, questText,
                    questInfo, color, isCurrentStep)
            elseif step.LearnProfession then
                local spellID = step.LearnProfession
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                local name = (spellInfo and spellInfo.name) or UNKNOWN
                local questInfo = { { questID = name } }
                local color = APR:IsSpellKnown(spellID) and "green" or "gray"
                container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, stepIndex,
                    L["LEARN_PROFESSION"], questInfo, color, isCurrentStep)
            elseif step.LootItems then
                local title = format(L["LOOT_ITEM"], ":")
                local itemsInfo = {}
                local completed = 0

                for _, item in ipairs(step.LootItems) do
                    local itemID = item.itemID
                    local requiredQuantity = math.max(item.quantity or 1, 1)

                    if itemID then
                        local bagCount = C_Item.GetItemCount(itemID, true) or 0
                        local virtualCount = APR.QuestVirtualItemCount[itemID] or 0
                        local currentQuantity = math.max(bagCount, virtualCount)

                        local isDone =
                            currentQuantity >= requiredQuantity
                            or APR.lootUtils:IsLootDone(step, "ITEM", itemID)
                            or currentStepIndex > stepIndex

                        if isDone then
                            completed = completed + 1
                        else
                            local itemName = C_Item.GetItemInfo(itemID) or UNKNOWN
                            table.insert(itemsInfo, {
                                questID = requiredQuantity,
                                questName = itemName,
                            })
                        end
                    end
                end

                if completed == #step.LootItems then
                    container, activeQuestId =
                        QuestOrderListUtils:AddStepFrame(layout, stepIndex, title, "green", isCurrentStep)
                else
                    container, activeQuestId =
                        QuestOrderListUtils:AddStepFrameWithQuest(
                            layout,
                            stepIndex,
                            title,
                            itemsInfo,
                            "gray",
                            isCurrentStep
                        )
                end
            elseif step.WarMode then
                local color = C_PvP.IsWarModeActive() and "green" or "gray"
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["TURN_ON_WARMODE"],
                    color, isCurrentStep)
            elseif step.Grind then
                local color = UnitLevel("player") <= step.Grind and "green" or "gray"
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex,
                    L["GRIND"] .. " " .. step.Grind, color, isCurrentStep)
            elseif step.GossipOptionIDs and not APR:HasAnyMainStepOption(step) then
                local alreadyTalked = APR:hasEveryGossipsCompleted(step.GossipOptionIDs)
                local color = (alreadyTalked or currentStepIndex > stepIndex) and "green" or "gray"
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["TALK_NPC"], color,
                    isCurrentStep)
            elseif step.RouteCompleted then
                container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, stepIndex, L["ROUTE_COMPLETED"],
                    "gray", isCurrentStep)
            end
            if container then
                self.stepList[stepIndex] = container
                if activeQuestId then
                    self.questID = activeQuestId
                end
            end
            stepIndex = stepIndex + 1
        end
    end
    -- set current Step indicator
    QuestOrderListUtils:SetCurrentStepIndicator(self.stepList, QuestOrderListFrame_ScrollFrame, currentStepIndex)
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
