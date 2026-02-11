local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR current step module
APR.currentStep = APR:NewModule("CurrentStep")

-- Init quests List to save quest
APR.currentStep.questsList = {}
APR.currentStep.questsExtraTextList = {}
APR.currentStep.fillersList = {}
APR.currentStep.pendingRemoval = {}
APR.currentStep.pendingButtonRequests = {}
APR.currentStep.pendingRaidIconRequests = {}
APR.currentStep.pendingButtonResets = {}
APR.currentStep.pendingRaidIconNpcId = nil
APR.currentStep.raidIconAdded = false
APR.currentStep.pendingRaidIconMacroRefresh = false
APR.currentStep.raidIconButton = nil
-- Height of the quest frame
APR.currentStep.FrameHeight = 0

-- Save the previous
APR.currentStep.previousState = {}

--Local constant
local FRAME_WIDTH = 250
local FRAME_HEADER_OFFSET = -30
local FRAME_ATTACH_OFFSET = -35
local FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OFFSET
local RAID_ICON_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"

---------------------------------------------------------------------------------------
--------------------------------- Current Step Frames ---------------------------------
---------------------------------------------------------------------------------------

-- Create the main current step frame
local CurrentStepFrame = APR:CreateStandardFrame("CurrentStepScreenPanel", UIParent, FRAME_WIDTH, 30, "BackdropTemplate")

-- Create the step holder frame
local CurrentStepFrame_StepHolder = CreateFrame("Frame", "CurrentStepFrame_StepHolder", CurrentStepFrame,
    "BackdropTemplate")
CurrentStepFrame_StepHolder:SetAllPoints()

-- Create the frame header
local CurrentStepFrameHeader = APR:CreateFrameHeader("CurrentStepFrameHeader", CurrentStepFrame,
    "Azeroth Pilot Reloaded", "ObjectiveTrackerContainerHeaderTemplate") -- don't replace with APR.title

-- Setup drag with right-click menu support
CurrentStepFrameHeader:RegisterForDrag("LeftButton")
APR:SetupHeaderDrag(CurrentStepFrameHeader, CurrentStepFrame, function()
    return not InCombatLockdown() and not APR.settings.profile.currentStepLock and
    not APR.settings.profile.currentStepAttachFrameToQuestLog
end, function()
    LibWindow.SavePosition(CurrentStepScreenPanel)
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
end, function()
    -- Right-click handler
    MenuUtil.CreateContextMenu(UIParent, APR.GetMenu)
end)

-- Also setup drag via RegisterForDrag for smoother behavior
CurrentStepFrameHeader:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() and not APR.settings.profile.currentStepLock and not APR.settings.profile.currentStepAttachFrameToQuestLog then
        self:GetParent():StartMoving()
    end
end)

CurrentStepFrameHeader:SetScript("OnDragStop", function(self)
    self:GetParent():StopMovingOrSizing()
    LibWindow.SavePosition(CurrentStepScreenPanel)
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
end)

-- Create the settings button (left of minimize button)
local CurrentStepFrameSettingsButton = CreateFrame("Button", "CurrentStepFrameSettingsButton", CurrentStepFrameHeader)
CurrentStepFrameSettingsButton:SetSize(16, 16)
CurrentStepFrameSettingsButton:SetPoint("RIGHT", CurrentStepFrameHeader.MinimizeButton, "LEFT", -3, 0)
CurrentStepFrameSettingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
CurrentStepFrameSettingsButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
CurrentStepFrameSettingsButton:SetScript("OnClick", function(self, button)
    MenuUtil.CreateContextMenu(UIParent, APR.GetMenu)
end)
CurrentStepFrameSettingsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["SHOW_MENU"] or "Settings")
    GameTooltip:Show()
end)
CurrentStepFrameSettingsButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Setup minimize button with custom collapse/expand behavior
APR:SetupMinimizeButton(CurrentStepFrameHeader, CurrentStepFrame, function()
    -- Collapse
    CurrentStepFrame_StepHolder:Hide()
    APR.currentStep:UpdateBackgroundColorAlpha({ 0, 0, 0, 0 })
    APR.currentStep:ButtonHide()
    APR.currentStep.progressBar:Hide()
    if APR.fillersFrame then
        APR.fillersFrame:Hide()
    end
    if APR.settings.profile.showQuestOrderList and APR.settings.profile.questOrderListSnapToCurrentStep then
        local qol = _G.QuestOrderListPanel
        if qol then
            qol:Hide()
        end
    end
end, function()
    -- Expand
    APR.currentStep:ButtonShow()
    APR.currentStep.progressBar:Show()
    APR.currentStep:SetDefaultDisplay()
    if APR.fillersFrame then
        APR.fillersFrame:Show()
    end
    if APR.questOrderList and APR.questOrderList.RefreshFrameAnchor and APR.settings.profile.showQuestOrderList then
        APR.questOrderList:RefreshFrameAnchor()
    end
end, "ui-questtrackerbutton-collapse-all", "ui-questtrackerbutton-expand-all")

---------------------------------------------------------------------------------------
---------------------------- Function Current Step Frames -----------------------------
---------------------------------------------------------------------------------------

-- Initialize the current step frame
function APR.currentStep:CurrentStepFrameOnInit()
    LibWindow.RegisterConfig(CurrentStepScreenPanel, APR.settings.profile.currentStepFrame)
    CurrentStepScreenPanel.RegisteredForLibWindow = true
    LibWindow.MakeDraggable(CurrentStepScreenPanel)

    -- Set default display
    self:SetDefaultDisplay()
    -- Add previous/next step buttons and progress bar
    self:PreviousNextStepButton()
    self:ProgressBar()

    if (not APR.settings.profile.currentStepAttachFrameToQuestLog) then
        LibWindow.RestorePosition(CurrentStepScreenPanel)
    end


    self:RefreshCurrentStepFrameAnchor()
    self:UpdateFrameScale()
end

function APR.currentStep:SetDefaultDisplay()
    CurrentStepFrame.collapsed = false
    CurrentStepFrame_StepHolder:Show()
    CurrentStepFrameHeader:Show()
    self:UpdateBackgroundColorAlpha()
end

-- Update the frame scale
function APR.currentStep:UpdateFrameScale()
    LibWindow.SetScale(CurrentStepScreenPanel, APR.settings.profile.currentStepScale)

    if APR.AFK and APR.AFK.RefreshFrameAnchor then
        APR.AFK:RefreshFrameAnchor()
    end
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
end

function APR.currentStep:UpdateBackgroundColorAlpha(color)
    local rgba = color or APR.settings.profile.currentStepbackgroundColorAlpha
    CurrentStepFrame:SetBackdropColor(unpack(rgba))

    local function UpdateColor(list)
        for _, container in pairs(list) do
            -- Don't touch soft-hidden frames during combat
            if container and not container.hiddenInCombat then
                container:SetBackdropColor(unpack(rgba))
            end
        end
    end

    UpdateColor(self.questsList)
    UpdateColor(self.questsExtraTextList)
    UpdateColor(self.fillersList)

    -- Update Fillers frame background
    if APR.fillersFrame then
        APR.fillersFrame:UpdateBackgroundColorAlpha(rgba)
    end
end

-- Refresh the frame positioning
function APR.currentStep:RefreshCurrentStepFrameAnchor()
    APR:Debug("Function: APR:RefreshCurrentStepFrameAnchor()")
    -- Use centralized frame hiding check from Core
    if APR:ShouldHideFrames() then
        CurrentStepScreenPanel:Hide()

        -- When CurrentStep hides, refresh all child frames
        if APR.AFK and APR.AFK.RefreshFrameAnchor then
            APR.AFK:RefreshFrameAnchor()
        end
        if APR.fillersFrame and APR.fillersFrame.RefreshFillersFrame then
            APR.fillersFrame:RefreshFillersFrame()
        end
        if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
            APR.questOrderList:ApplySnapAnchor()
        end
        return
    end

    local profile = APR:GetSettingsProfile()
    if not profile then return end

    if profile.currentStepAttachFrameToQuestLog then
        if not InCombatLockdown() then
            CurrentStepScreenPanel:EnableMouse(false)
        end
        CurrentStepScreenPanel:ClearAllPoints()
        CurrentStepFrame:SetScale(1)

        if APR.currentStep.FrameAttachToModule then
            CurrentStepScreenPanel:SetPoint("TOP", APR.currentStep.FrameAttachToModule, "BOTTOM", 0, FRAME_ATTACH_OFFSET)
        elseif ObjectiveTrackerFrame.Header then
            CurrentStepScreenPanel:SetPoint("TOP", ObjectiveTrackerFrame.Header, "BOTTOM", 0, FRAME_ATTACH_OFFSET)
        end
    else
        if not InCombatLockdown() then
            if not profile.currentStepLock then
                CurrentStepScreenPanel:EnableMouse(true)
            else
                CurrentStepScreenPanel:EnableMouse(false)
            end

            LibWindow.RestorePosition(CurrentStepScreenPanel)
            self:UpdateFrameScale()
        end
    end
    CurrentStepFrameHeader:ClearAllPoints()
    CurrentStepFrameHeader:SetPoint("BOTTOM", CurrentStepFrame, "TOP", 0, -1)

    -- InCombatLockdown to prevent the "UNKNOWN()"-Call issue which happens sometimes when we're in a combat and doing a quest step
    if not InCombatLockdown() then
        CurrentStepScreenPanel:Show()
        if APR.AFK and APR.AFK.RefreshFrameAnchor then
            APR.AFK:RefreshFrameAnchor()
        end
        if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
            APR.questOrderList:ApplySnapAnchor()
        end
    end
end

function APR.currentStep:GetContentHeight(includeFillers)
    if not CurrentStepScreenPanel then
        return nil
    end

    if includeFillers == nil then
        includeFillers = true
    end

    local top = CurrentStepScreenPanel:GetTop()
    local minBottom = CurrentStepScreenPanel:GetBottom()

    if not top or not minBottom then
        return nil
    end

    local function consider(frame)
        if frame and frame:IsShown() then
            local bottom = frame:GetBottom()
            if bottom and bottom < minBottom then
                minBottom = bottom
            end
        end
    end

    consider(CurrentStepFrameHeader)
    consider(CurrentStepFrame_StepHolder and CurrentStepFrame_StepHolder.rollbackButton)
    consider(CurrentStepFrame_StepHolder and CurrentStepFrame_StepHolder.skipButton)
    consider(self.progressBar)

    local function considerList(list)
        for _, container in pairs(list) do
            if container and container:IsShown() then
                consider(container)
                consider(container.IconButton)
                consider(container.RaidIconButton)
            end
        end
    end

    considerList(self.questsExtraTextList)
    considerList(self.questsList)

    -- Consider the fillers frame
    if includeFillers and APR.fillersFrame and APR.fillersFrame.Frame and APR.fillersFrame.Frame:IsShown() then
        consider(APR.fillersFrame.Frame)
        considerList(self.fillersList)
    end

    return top - minBottom
end

-- Reset the frame position
function APR.currentStep:ResetPosition()
    CurrentStepScreenPanel:ClearAllPoints()
    CurrentStepScreenPanel:SetPoint("center", UIParent, "center", 0, 0)
    self:SetDefaultDisplay()
end

-- Hook on update for ObjectiveTrackerFrame (quests log)
hooksecurefunc(ObjectiveTrackerFrame, "Update",
    function()
        if not ObjectiveTrackerFrame and not CurrentStepScreenPanel then
            return
        end

        local modules = ObjectiveTrackerFrame.modules
        local lastModule = nil

        if modules then
            for i = #modules, 1, -1 do
                if modules[i]:IsShown() then
                    lastModule = modules[i]
                    break
                end
            end
        end

        APR.currentStep.FrameAttachToModule = lastModule
        APR.currentStep:RefreshCurrentStepFrameAnchor()
    end)

-- Helper function to create a button
local function CreateButton(name, parent, width, height, text, script)
    local button = CreateFrame("Button", name, parent, "BackdropTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    button:SetScript("OnClick", script)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(text)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    return button
end

-- Rollback / skip button
function APR.currentStep:PreviousNextStepButton()
    local rollbackButton = CreateButton("CurrentStepFrame_StepHolder_RollbackButton", CurrentStepFrameHeader, 30, 30,
        L["ROLLBACK"],
        function()
            APR.command:SlashCmd('rollback')
        end)
    rollbackButton:SetPoint("BOTTOMLEFT", CurrentStepFrameHeader, "BOTTOMLEFT", 10, -30)
    rollbackButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Up]])
    rollbackButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Down]])
    rollbackButton:SetDisabledTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Disabled]])
    rollbackButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    CurrentStepFrame_StepHolder.rollbackButton = rollbackButton

    local skipButton = CreateButton("CurrentStepFrame_StepHolder_SkipButton", CurrentStepFrameHeader, 30, 30, L["SKIP"],
        function()
            APR.command:SlashCmd('skip')
        end)
    skipButton:SetPoint("BOTTOMRIGHT", CurrentStepFrameHeader, "BOTTOMRIGHT", -10, -30)
    skipButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
    skipButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Down]])
    skipButton:SetDisabledTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Disabled]])
    skipButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    CurrentStepFrame_StepHolder.skipButton = skipButton

    self.ButtonHide = function()
        rollbackButton:Hide()
        skipButton:Hide()
    end

    self.ButtonShow = function()
        rollbackButton:Show()
        skipButton:Show()
    end

    self.ButtonDisable = function()
        rollbackButton:Disable()
        skipButton:Disable()
    end

    self.ButtonEnable = function()
        rollbackButton:Enable()
        skipButton:Enable()
    end
end

-- Add a progress bar
function APR.currentStep:ProgressBar(key, total, current)
    local profile = APR:GetSettingsProfile()
    if not profile or not profile.currentStepShow then
        return
    end
    if (self.progressBar and self.progressBar.key ~= key) then
        self.progressBar:Hide()
        self.progressBar:ClearAllPoints()
        self.progressBar = nil
    end

    local totalSteps = total or 0
    local currentStep = current or 0

    if not self.progressBar then
        local progressBar = CreateFrame("StatusBar", "CurrentStepFrame_StepHolder_ProgressBar", CurrentStepFrameHeader,
            "BackdropTemplate")
        progressBar:SetSize(175, 20)
        progressBar:SetPoint("BOTTOM", CurrentStepFrameHeader, "BOTTOM", 0, -25)
        progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        APR.currentStep:UpdateProgressBarColor(progressBar)
        progressBar:SetMinMaxValues(1, totalSteps)
        progressBar:SetValue(currentStep)
        progressBar:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            tile = true,
            tileSize = 16
        })
        progressBar:SetBackdropColor(unpack(APR.Color.defaultBackdrop))

        local progressBarText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        progressBarText:SetPoint("CENTER", progressBar, "CENTER", 0, 0)
        if totalSteps > 0 then
            progressBarText:SetText(currentStep .. " / " .. totalSteps)
        else
            progressBarText:SetText("")
        end

        self.progressBar = progressBar
        self.progressBar.Text = progressBarText
        self.progressBar.key = key
        self.progressBar.currentStep = currentStep
    else
        self.progressBar:SetValue(currentStep)
        if totalSteps > 0 then
            self.progressBar.Text:SetText(currentStep .. " / " .. totalSteps)
        else
            self.progressBar.Text:SetText("")
        end
        self:UpdateProgressBarColor(self.progressBar)
    end
end

function APR.currentStep:UpdateProgressBarColor(barOverride)
    local profile = APR:GetSettingsProfile()
    local color = (profile and profile.currentStepProgressBarColor) or
        { APR.Color.blue[1], APR.Color.blue[2], APR.Color.blue[3], 1 }
    local targetBar = barOverride or self.progressBar
    if targetBar then
        targetBar:SetStatusBarColor(unpack(color))
    end
end

function APR.currentStep:SetProgressBar(CurStep)
    if APR.ActiveRoute then
        if not APRData[APR.PlayerID]
            [APR.ActiveRoute .. '-TotalSteps'] then
            APR:GetTotalSteps()
        end
        local curStepDisplayed = CurStep - (APRData[APR.PlayerID][APR.ActiveRoute .. '-SkippedStep'] or 0)
        APR.currentStep:ProgressBar(APR.ActiveRoute, APRData[APR.PlayerID]
            [APR.ActiveRoute .. '-TotalSteps'], curStepDisplayed)
    end
end

-- Displaying quest information
local function AddStepsFrame(questDesc, extraLineText, color)
    local text = extraLineText or questDesc
    return APR:CreateStepTextContainer(
        CurrentStepFrame_StepHolder,
        FRAME_WIDTH,
        text,
        extraLineText ~= nil,
        color,
        APR.settings.profile.currentStepbackgroundColorAlpha
    )
end

-- Displaying extra line text information
local function AddExtraLineTextFrame(extraLineText, color)
    return AddStepsFrame(nil, extraLineText, color)
end

-- Add/Update quest steps
function APR.currentStep:AddQuestSteps(questID, textObjective, objectiveIndex, isScenario, noTooltip)
    local profile = APR:GetSettingsProfile()
    if not profile or not profile.currentStepShow then
        return
    end

    -- Check if questsExtraTextList or questsList are empty to reset to the default height
    if not next(self.questsExtraTextList) or not next(self.questsList) then
        FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OFFSET
    end

    local questKey = questID .. "-" .. (objectiveIndex or 0)
    local existingContainer = self.questsList[questKey]

    -- remove if it's already exist
    if existingContainer then
        existingContainer:Hide()
        existingContainer:ClearAllPoints()
        self.questsList[questKey] = nil
    end

    local objectiveContainer = AddStepsFrame(textObjective)
    objectiveContainer:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)
    objectiveContainer.questID = questID
    if not noTooltip then
        objectiveContainer:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(L["QUEST_INFO"])

            -- Normalize questID for display vs API calls
            local questIDText = (questID ~= nil) and tostring(questID) or "?"
            local questIDNum  = tonumber(questIDText) -- may be nil if non-numeric string

            if isScenario then
                GameTooltip:AddLine("|c33ecc00f" .. SCENARIOS .. " " .. ID .. ": |r" .. questIDText,
                    unpack(APR.Color.white))

                local scenarInfo = C_ScenarioInfo and C_ScenarioInfo.GetScenarioStepInfo and
                    C_ScenarioInfo.GetScenarioStepInfo()
                local scenarTitle = scenarInfo and scenarInfo.title
                local scenarStepID = scenarInfo and scenarInfo.stepID

                if scenarTitle then
                    GameTooltip:AddLine("|c33ecc00f" .. NAME .. "|r: " .. scenarTitle, unpack(APR.Color.white))
                end
                if scenarStepID then
                    GameTooltip:AddLine("|c33ecc00fStepID|r: " .. scenarStepID, unpack(APR.Color.white))
                end

                GameTooltip:AddLine(
                    "|c33ecc00f" ..
                    OBJECTIVES_LABEL .. "|r: " .. tostring(objectiveIndex) .. " - " .. tostring(textObjective),
                    1, 1, 1, true
                )
            else
                GameTooltip:AddLine("|c33ecc00f" .. ID .. ": |r" .. questIDText, unpack(APR.Color.white))

                -- Title only if we have a numeric ID
                if questIDNum then
                    local questTitle = C_QuestLog.GetTitleForQuestID(questIDNum)
                    if questTitle then
                        GameTooltip:AddLine("|c33ecc00f" .. NAME .. "|r: " .. questTitle, unpack(APR.Color.white))
                    end
                end

                GameTooltip:AddLine(
                    "|c33ecc00f" ..
                    OBJECTIVES_LABEL .. "|r: " .. tostring(objectiveIndex) .. " - " .. tostring(textObjective),
                    1, 1, 1, true
                )

                -- Campaign flag only if we have a numeric ID
                local isCampaign = questIDNum and APR:IsCampaignQuest(questIDNum)
                if isCampaign then
                    GameTooltip:AddLine(
                        "|c33ecc00f" .. L["CAMPAIGN"] .. "|r: " ..
                        (isCampaign and APR:WrapTextInColorCode(YES, "00ff00") or
                            APR:WrapTextInColorCode(NO, "cce0000f")),
                        unpack(APR.Color.white)
                    )
                end
            end

            GameTooltip:Show()
        end)

        objectiveContainer:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    end

    self.questsList[questKey] = objectiveContainer
    self:MaybeAttachRaidIconButton(questKey)
    FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - objectiveContainer:GetHeight()

    -- to update quest order display
    self:ReOrderQuestSteps()
end

function APR.currentStep:UpdateQuestStep(questID, textObjective, objectiveIndex)
    APR:Debug("Function: APR.currentStep:UpdateQuestStep()", questID)
    if not APR.settings.profile.currentStepShow then
        return
    end

    local questKey = questID .. "-" .. objectiveIndex
    local existingContainer = self.questsList[questKey]

    if not existingContainer then
        return
    end

    existingContainer.font:SetText('- ' .. textObjective)
end

local getExtraLineHeight = function()
    -- Always reset to header offset with a new extra line
    local height = FRAME_HEADER_OFFSET
    for id, textContainer in pairs(APR.currentStep.questsExtraTextList) do
        height = height - textContainer:GetHeight()
    end
    return height
end


function APR.currentStep:AddQuestStepsWithDetails(id, text, questIDList)
    if not APR.settings.profile.currentStepShow then
        return
    end

    -- Check if questsExtraTextList or questsList are empty to reset to the default height
    if not next(self.questsExtraTextList) or not next(self.questsList) then
        FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OFFSET
    end

    local existingContainer = self.questsList[id]

    -- Remove if it already exists
    if existingContainer then
        existingContainer:Hide()
        existingContainer:ClearAllPoints()
        self.questsList[id] = nil
    end

    -- Create the main container for the text
    local container = AddExtraLineTextFrame(text .. ":")
    container:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)

    -- Add the sub-container for each quest in the list
    local questFontHeight = 0
    for _, questID in ipairs(questIDList) do
        local questName = C_QuestLog.GetTitleForQuestID(questID)
        local questText = questName and ("- " .. questName) or ("- " .. questID .. " - " .. UNKNOWN)

        local questFont = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        questFont:SetWordWrap(true)
        questFont:SetWidth(FRAME_WIDTH - 20) -- Indent for sub-items
        questFont:SetPoint("TOPLEFT", container, "TOPLEFT", 25,
            -(container.font:GetStringHeight() + 10 + questFontHeight))
        questFont:SetText(questText)
        questFont:SetJustifyH("LEFT")
        questFontHeight = questFontHeight + questFont:GetStringHeight()
        questFont:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(L["QUEST_INFO"])
            GameTooltip:AddLine("|c33ecc00f" .. ID .. ": |r" .. questID, unpack(APR.Color.white))
            GameTooltip:AddLine("|c33ecc00f" .. NAME .. "|r: " .. (questName or UNKNOWN), unpack(APR.Color.white))
            GameTooltip:Show()
        end)
        questFont:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    end

    -- Adjust container height based on the number of quests
    container:SetHeight(container.font:GetStringHeight() + questFontHeight + 15)


    -- Save the subTexts for later reference
    container.subTexts = container.subTexts or {}
    for _, questID in ipairs(questIDList) do
        local questName = C_QuestLog.GetTitleForQuestID(questID)
        local questText = questName and ("- " .. questName) or ("- " .. questID .. " - " .. UNKNOWN)

        table.insert(container.subTexts, {
            questID = questID,
            text = questText,
            name = questName or UNKNOWN,
        })
    end

    -- Save the container in the questsList
    self.questsList[id] = container
    self:MaybeAttachRaidIconButton(id)

    FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - container:GetHeight()

    -- Update the quest order display
    self:ReOrderQuestSteps()
end

--- Add a new Extra line text
---@param key string Locale table key
---@param text string L[key]
function APR.currentStep:AddExtraLineText(key, text, color)
    APR:Debug("Function: APR.currentStep:AddExtraLineText()", { key, text })
    if not APR.settings.profile.currentStepShow then
        return
    end

    -- Always reset to header height with a new extra line
    FRAME_STEP_HOLDER_HEIGHT = getExtraLineHeight()

    local existingContainer = self.questsExtraTextList[key]
    if existingContainer then
        existingContainer:Hide()
        existingContainer:ClearAllPoints()
        self.questsExtraTextList[key] = nil
    end

    local extraLineTextContainer = AddExtraLineTextFrame(text, color)
    extraLineTextContainer:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)
    extraLineTextContainer.key = key
    self.questsExtraTextList[key] = extraLineTextContainer
    self:MaybeAttachRaidIconButton(key)
    FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - extraLineTextContainer:GetHeight()

    self:ReOrderExtraLineText()
end

function APR.currentStep:ReOrderExtraLineText()
    APR:Debug("Function: APR.currentStep:ReOrderExtraLineText()")
    if not APR.settings.profile.currentStepShow then
        return
    end

    -- Convert the table into a sortable list
    local sortedList = {}
    for id, textContainer in pairs(self.questsExtraTextList) do
        table.insert(sortedList, textContainer)
    end

    -- Sort the list based on textContainer.key
    table.sort(sortedList, function(a, b)
        return a.key < b.key
    end)

    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OFFSET
    for _, textContainer in ipairs(sortedList) do
        textContainer:ClearAllPoints()
        textContainer:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)
        FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - textContainer:GetHeight()
    end

    self:ReOrderQuestSteps(false)
end

--- Re order all the quest Step
--- @param hasExtraLineHeight boolean to get the extra line height
function APR.currentStep:ReOrderQuestSteps(hasExtraLineHeight)
    APR:Debug("Function: APR.currentStep:ReOrderQuestSteps()")
    if not APR.settings.profile.currentStepShow then return end

    hasExtraLineHeight = (hasExtraLineHeight ~= false)
    if hasExtraLineHeight then
        FRAME_STEP_HOLDER_HEIGHT = getExtraLineHeight()
    end
    for id, container in pairs(self.questsList) do
        if not container.hiddenInCombat then
            container:ClearAllPoints()
            container:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)
            FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - container:GetHeight()
        end
    end

    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
end

-- Remove all  quest steps and extra line texts
function APR.currentStep:RemoveQuestStepsAndExtraLineTexts(removeTextOnly)
    APR:Debug("Function: APR.currentStep:RemoveQuestStepsAndExtraLineTexts()")
    removeTextOnly = removeTextOnly or false
    local profile = APR:GetSettingsProfile()
    if not profile or not profile.currentStepShow then return end

    local function ResetList(list, isQuestList)
        for id, container in pairs(list) do
            local canHide = self:CanSafelyHide(container)
            if canHide then
                -- Explicit frame cleanup to prevent memory leaks
                container:ClearAllPoints()
                container:Hide()
                if isQuestList then
                    self:ResetSecureStepButton(container, id)
                    self.pendingButtonRequests[id] = nil
                end
                self:ResetSecureRaidIconButton(container, id)
                self.pendingRaidIconRequests[id] = nil

                -- Clear frame scripts and textures to free memory
                if container.Text then
                    container.Text:SetText("")
                end
                if container.IconButton then
                    container.IconButton:SetScript("OnEnter", nil)
                    container.IconButton:SetScript("OnLeave", nil)
                end

                list[id] = nil
            else
                -- Combat: soft-hide + mark for purge post-combat
                self:SoftHide(container)
                self.pendingRemoval[id] = true
                -- DO NOT remove from the list here! Keep the reference for the flush
            end
        end
    end

    if not removeTextOnly then
        ResetList(self.questsList, true)
        if not InCombatLockdown() then
            self.questsList = {}
        end
    end

    ResetList(self.questsExtraTextList, false)
    if not InCombatLockdown() then
        self.questsExtraTextList = {}
    end

    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OFFSET
    -- Reorder ignoring soft-hidden
    self:ReOrderQuestSteps(true)
end

local function PositionStepButtons(container, button, anchorButton)
    button:ClearAllPoints()
    local anchor = anchorButton or container
    if APR.settings.profile.currentStepQuestButtonPositionRight then
        button:SetPoint("LEFT", anchor, "RIGHT", 5, 0)
    else
        button:SetPoint("RIGHT", anchor, "LEFT", -5, 0)
    end
end
-- Create a icon button next to the quest/text step
local function GetStepButtonIcon(attribute, itemID)
    if attribute == "item" then
        local _, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemID)
        return itemTexture
    else
        local spellInfo = C_Spell.GetSpellInfo(itemID)
        return spellInfo and spellInfo.iconID or nil
    end
end


local function GetRaidIconContainer(self, key)
    return self.questsList[key] or self.questsExtraTextList[key] or self.fillersList[key]
end

function APR.currentStep:ResetSecureStepButton(container, questsListKey, force)
    if not container or not container.IconButton then
        return
    end

    local button = container.IconButton
    if InCombatLockdown() and button:IsProtected() and not force then
        if questsListKey then
            self.pendingButtonResets[questsListKey] = true
        end
        return
    end

    button:Hide()
    button:ClearAllPoints()
    button:SetScript("OnEnter", nil)
    button:SetScript("OnLeave", nil)
    button:SetAttribute("type1", nil)
    button:SetAttribute("item", nil)
    button:SetAttribute("spell", nil)
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        normalTexture:SetTexture(nil)
    end
    local highlightTexture = button:GetHighlightTexture()
    if highlightTexture then
        highlightTexture:SetTexture(nil)
    end
    button.itemID = nil
    button.attribute = nil
    if button.cooldown then
        button.cooldown:Hide()
        button.cooldown:Clear()
    end
    container.IconButton = nil
end

function APR.currentStep:ResetSecureRaidIconButton(container, questsListKey, force)
    if not container or not container.RaidIconButton then
        return
    end

    local button = container.RaidIconButton
    if InCombatLockdown() and button:IsProtected() and not force then
        if questsListKey then
            self.pendingButtonResets[questsListKey] = true
        end
        return
    end

    button:Hide()
    button:ClearAllPoints()
    button:SetScript("OnEnter", nil)
    button:SetScript("OnLeave", nil)
    button:SetAttribute("type1", nil)
    button:SetAttribute("macrotext", nil)
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        normalTexture:SetTexture(nil)
    end
    local highlightTexture = button:GetHighlightTexture()
    if highlightTexture then
        highlightTexture:SetTexture(nil)
    end
    button.npcID = nil
    container.RaidIconButton = nil
    if self.raidIconButton == button then
        self.raidIconButton = nil
    end
end

function APR.currentStep:ResetSecureButtonsByKey(questsListKey, force)
    local containerQuest = self.questsList[questsListKey]
    local containerRaid = self.questsList[questsListKey] or self.questsExtraTextList[questsListKey]
    self:ResetSecureStepButton(containerQuest, questsListKey, force)
    self:ResetSecureRaidIconButton(containerRaid, questsListKey, force)
end

function APR.currentStep:ProcessPendingButtonResets()
    if InCombatLockdown() then
        return
    end

    for questsListKey, _ in pairs(self.pendingButtonResets) do
        self:ResetSecureButtonsByKey(questsListKey, true)
        self.pendingButtonResets[questsListKey] = nil
    end
end

function APR.currentStep:PrepareRaidIcon(step)
    if step and (step.RaidIcon or step.DroppableQuest) then
        self.pendingRaidIconNpcId = tonumber(step.RaidIcon or step.DroppableQuest)
    else
        self.pendingRaidIconNpcId = nil
    end
    self.raidIconAdded = false
end

function APR.currentStep:MaybeAttachRaidIconButton(key)
    if not self.pendingRaidIconNpcId or self.raidIconAdded then
        return
    end
    self.raidIconAdded = true
    self:AddRaidIconButton(key, self.pendingRaidIconNpcId)
end

function APR.currentStep:CreateSecureRaidIconButton(questsListKey, npcID)
    local container = GetRaidIconContainer(self, questsListKey)
    if not container then
        return
    end
    if container.RaidIconButton then
        self:ResetSecureRaidIconButton(container, questsListKey)
        if container.RaidIconButton then
            return
        end
    end

    local RaidIconButton = CreateFrame("Button", nil, container,
        "SecureActionButtonTemplate, BackdropTemplate")
    RaidIconButton:SetSize(25, 25)
    PositionStepButtons(container, RaidIconButton, container.IconButton)
    RaidIconButton:SetNormalTexture(RAID_ICON_TEXTURE)
    RaidIconButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    RaidIconButton:RegisterForClicks("AnyUp", "AnyDown")
    RaidIconButton:SetAttribute("type1", "macro")
    RaidIconButton:SetAttribute("macrotext", APR:BuildRaidIconMacro(npcID))

    RaidIconButton:SetScript("OnEnter", function(self)
        local npcName = APR:GetRaidIconNpcName(self.npcID)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Raid icon (skull)")
        if npcName then
            GameTooltip:AddLine(npcName, 1, 1, 1, true)
        else
            GameTooltip:AddLine("Mouseover target", 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)

    RaidIconButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    RaidIconButton.npcID = npcID
    container.RaidIconButton = RaidIconButton
    self.raidIconButton = RaidIconButton
    self:UpdateRaidIconButtonMacro()
end

function APR.currentStep:AddRaidIconButton(questsListKey, npcID)
    if not APR.settings.profile.currentStepShow or not npcID then
        return
    end

    if InCombatLockdown() then
        self.pendingRaidIconRequests[questsListKey] = npcID
        return
    end

    self.pendingRaidIconRequests[questsListKey] = nil
    self:CreateSecureRaidIconButton(questsListKey, npcID)
end

function APR.currentStep:UpdateRaidIconButtonMacro()
    if InCombatLockdown() then
        self.pendingRaidIconMacroRefresh = true
        return
    end

    local button = self.raidIconButton
    if not button or not button.npcID then
        return
    end

    local unitToken = APR:FindRaidIconUnitToken(button.npcID)
    button:SetAttribute("macrotext", APR:BuildRaidIconMacro(button.npcID, unitToken))
end

function APR.currentStep:CreateSecureStepButton(questsListKey, itemID, attribute)
    attribute = attribute or "item"
    local container = self.questsList[questsListKey] or self.fillersList[questsListKey]
    if not container then
        return
    end

    if container.IconButton then
        self:ResetSecureStepButton(container, questsListKey)
        if container.IconButton then
            return
        end
    end

    -- Only clean up raid icon button if this step doesn't have one pending
    if container.RaidIconButton and not self.pendingRaidIconNpcId then
        self:ResetSecureRaidIconButton(container, questsListKey)
    end

    local iconTexture = GetStepButtonIcon(attribute, itemID)
    if not iconTexture then
        return
    end

    local IconButton = CreateFrame("Button", nil, container,
        "SecureActionButtonTemplate, BackdropTemplate")
    IconButton:SetSize(25, 25)
    PositionStepButtons(container, IconButton)
    IconButton:SetNormalTexture(iconTexture)
    IconButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    IconButton:RegisterForClicks("AnyUp", "AnyDown")
    IconButton:SetAttribute("type1", attribute)
    if attribute == "item" then
        IconButton:SetAttribute("item", "item:" .. tostring(itemID))
    else
        IconButton:SetAttribute("spell", tonumber(itemID))
    end

    IconButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        if attribute == "item" then
            GameTooltip:SetItemByID(itemID)
        else
            GameTooltip:SetSpellByID(itemID)
        end
        GameTooltip:Show()
    end)

    IconButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    IconButton.cooldown = CreateFrame("Cooldown", "$parentCooldown", IconButton, "CooldownFrameTemplate")
    IconButton.cooldown:SetAllPoints()
    IconButton.cooldown:Hide()

    IconButton.itemID = itemID
    IconButton.attribute = attribute
    container.IconButton = IconButton

    -- Reposition raid icon button if it exists (to display both buttons side by side)
    if container.RaidIconButton then
        PositionStepButtons(container, container.RaidIconButton, IconButton)
    end
end

--- Queue or create a secure button depending on combat lockdown state
---@param questsListKey string
---@param itemID number
---@param attribute string
function APR.currentStep:AddStepButton(questsListKey, itemID, attribute)
    if not APR.settings.profile.currentStepShow and itemID then
        return
    end

    attribute = attribute or "item"
    self:MaybeAttachRaidIconButton(questsListKey)
    if InCombatLockdown() then
        self.pendingButtonRequests[questsListKey] = { itemID = itemID, attribute = attribute }
        return
    end

    self.pendingButtonRequests[questsListKey] = nil
    self:CreateSecureStepButton(questsListKey, itemID, attribute)
end

function APR.currentStep:ProcessPendingStepButtons()
    if InCombatLockdown() then
        return
    end

    self:ProcessPendingButtonResets()

    for questsListKey, data in pairs(self.pendingButtonRequests) do
        self:CreateSecureStepButton(questsListKey, data.itemID, data.attribute)
        self.pendingButtonRequests[questsListKey] = nil
    end

    for questsListKey, npcID in pairs(self.pendingRaidIconRequests) do
        self:CreateSecureRaidIconButton(questsListKey, npcID)
        self.pendingRaidIconRequests[questsListKey] = nil
    end

    if self.pendingRaidIconMacroRefresh then
        self.pendingRaidIconMacroRefresh = false
        self:UpdateRaidIconButtonMacro()
    end
end

function APR.currentStep:RemoveStepButtonByKey(questsListKey)
    if not APR.settings.profile.currentStepShow then
        return
    end
    local existingButton = self.questsList[questsListKey]
    if not existingButton then
        return
    end
    existingButton:Hide()
    existingButton:ClearAllPoints()
    self.questsList[questsListKey] = nil
end

function APR.currentStep:UpdateStepButtonCooldowns()
    local function updateContainerList(list)
        for id, container in pairs(list) do
            -- Ignore soft-hidden containers (during combat)
            if container and not container.hiddenInCombat then
                local IconButton = container.IconButton
                if IconButton and IconButton:IsShown() then
                    local startTime, duration, enable = 0, 0, 0
                    local isCooldownShown = IconButton.cooldown:IsShown()
                    local cooldownDuration = IconButton.cooldown:GetCooldownDuration() or 0

                    if IconButton.attribute == 'spell' then
                        local info = C_Spell.GetSpellCooldown(tonumber(IconButton.itemID))
                        if info then
                            startTime, duration = info.startTime or 0, info.duration or 0
                            enable = info.isEnabled and 1 or 0
                        end
                    else
                        startTime, duration, enable = C_Container.GetItemCooldown(tonumber(IconButton.itemID))
                    end

                    if enable > 0 and startTime > 0 and (cooldownDuration == 0 or not isCooldownShown) then
                        IconButton.cooldown:SetCooldown(startTime, duration)
                    else
                        IconButton.cooldown:Clear()
                    end
                elseif IconButton then
                    IconButton.cooldown:Clear()
                end
            end
        end
    end

    updateContainerList(self.questsList)
    updateContainerList(self.fillersList)
end

--- Disable Button, Reset ProgressBar and Remove all quest and extra line
function APR.currentStep:Reset()
    APR:Debug("Function: APR.currentStep:Reset()")
    self:ButtonShow()
    self:ButtonDisable()
    self:ProgressBar()
    self.pendingRaidIconNpcId = nil
    self.raidIconAdded = false
    self.pendingRaidIconRequests = {}
    self.pendingButtonResets = {}
    self.pendingRaidIconMacroRefresh = false
    self.raidIconButton = nil
    self:RemoveQuestStepsAndExtraLineTexts()
    APR.fillersFrame:RemoveFillerSteps()
end

function APR.GetMenu(owner, rootDescription)
    local toggleAddon = ''
    if APR.settings.profile.enableAddon then
        toggleAddon = APR:WrapTextInColorCode(" " .. L["DISABLE"], "cce0000f")
    else
        toggleAddon = APR:WrapTextInColorCode(" " .. L["ENABLE"], "00ff00")
    end

    local function createToggleItem(label, getChecked, onToggle)
        if rootDescription.CreateCheckbox then
            local ok = pcall(function()
                rootDescription:CreateCheckbox(label, getChecked, function(...)
                    onToggle(...)
                end)
            end)
            if ok then
                return
            end
        end

        rootDescription:CreateButton(label .. " (" .. (getChecked() and YES or NO) .. ")", function()
            onToggle()
        end)
    end

    rootDescription:CreateTitle(APR.title)

    rootDescription:CreateButton(L["SHOW_MENU"], function()
        APR.settings:OpenSettings(APR.title)
    end)

    rootDescription:CreateButton(L["ROUTE"], function()
        APR.settings:OpenSettings(L["ROUTE"])
    end)

    rootDescription:CreateButton(L["PROFILES"], function()
        APR.settings:OpenSettings(L["PROFILES"])
    end)

    rootDescription:CreateButton(L["ABOUT_HELP"], function()
        APR.settings:OpenSettings(L["ABOUT_HELP"])
    end)

    rootDescription:CreateButton(toggleAddon .. " " .. L["ADDON"], function()
        APR.settings.profile.enableAddon = not APR.settings.profile.enableAddon
        APR.settings:ToggleAddon()
    end)

    rootDescription:CreateDivider()
    rootDescription:CreateTitle(L["CURRENT_STEP"])

    createToggleItem(L["QLIST_ATTACH_QUESTLOG"], function()
        return APR.settings.profile.currentStepAttachFrameToQuestLog
    end, function()
        APR.settings.profile.currentStepAttachFrameToQuestLog = not APR.settings.profile
            .currentStepAttachFrameToQuestLog
        APR.currentStep:RefreshCurrentStepFrameAnchor()
    end)

    createToggleItem(L["LOCK_WINDOW"], function()
        return APR.settings.profile.currentStepLock
    end, function()
        APR.settings.profile.currentStepLock = not APR.settings.profile.currentStepLock
        APR.currentStep:RefreshCurrentStepFrameAnchor()
    end)

    rootDescription:CreateButton(L["CURRENT_STEP_QUEST_BUTTON_POSITION"] .. ": " ..
        (APR.settings.profile.currentStepQuestButtonPositionRight and L["RIGHT"] or L["LEFT"]), function()
            APR.settings.profile.currentStepQuestButtonPositionRight = not APR.settings.profile
                .currentStepQuestButtonPositionRight
            APR:UpdateMapId()
        end)

    rootDescription:CreateButton(L["RESET_CURRENT_STEP_FRAME_POSITION"], function()
        APR.currentStep:ResetPosition()
    end)

    rootDescription:CreateDivider()
    rootDescription:CreateTitle(L["FILLERS_FRAME"])

    createToggleItem(L["SNAP_TO_CURRENT_STEP"], function()
        return APR.settings.profile.fillersFrameSnapToCurrentStep
    end, function()
        APR.settings.profile.fillersFrameSnapToCurrentStep = not APR.settings.profile.fillersFrameSnapToCurrentStep
        if APR.fillersFrame and APR.fillersFrame.RefreshFillersFrame then
            APR.fillersFrame:RefreshFillersFrame()
        end
    end)

    createToggleItem(L["FILLERS_SHOW_HEADER"], function()
        return APR.settings.profile.fillersFrameShowHeader
    end, function()
        APR.settings.profile.fillersFrameShowHeader = not APR.settings.profile.fillersFrameShowHeader
        if APR.fillersFrame and APR.fillersFrame.RefreshFillersFrame then
            APR.fillersFrame:RefreshFillersFrame()
        end
    end)


    rootDescription:CreateDivider()
    rootDescription:CreateTitle(L["QUEST_ORDER_LIST"])

    createToggleItem(L["SHOW_QORDERLIST"], function()
        return APR.settings.profile.showQuestOrderList
    end, function()
        APR.settings.profile.showQuestOrderList = not APR.settings.profile.showQuestOrderList
        APR.questOrderList:RefreshFrameAnchor()
    end)

    createToggleItem(L["QORDERLIST_SNAP_TO_CURRENT_STEP"], function()
        return APR.settings.profile.questOrderListSnapToCurrentStep
    end, function()
        APR.settings.profile.questOrderListSnapToCurrentStep = not APR.settings.profile.questOrderListSnapToCurrentStep
        APR.questOrderList:RefreshFrameAnchor()
    end)

    rootDescription:CreateDivider()
    rootDescription:CreateTitle(L["AFK"])

    createToggleItem(L["AFK_SNAP_TO_CURRENT_STEP"], function()
        return APR.settings.profile.afkSnapToCurrentStep
    end, function()
        APR.settings.profile.afkSnapToCurrentStep = not APR.settings.profile.afkSnapToCurrentStep
        APR.AFK:RefreshFrameAnchor()
    end)
end

function APR.currentStep:IsShown()
    return CurrentStepScreenPanel:IsShown()
end

function APR.currentStep:CanSafelyHide(container)
    -- If we are in combat AND the container has a secure button, do not hide
    return not InCombatLockdown() or not ((container.IconButton and container.IconButton:IsProtected()) or
        (container.RaidIconButton and container.RaidIconButton:IsProtected()))
end

function APR.currentStep:SoftHide(container)
    container.hiddenInCombat = true
    container:SetAlpha(0.001)
end

function APR.currentStep:FlushPendingContainers()
    if not next(self.pendingRemoval) then return end
    for id, _ in pairs(self.pendingRemoval) do
        local container = self.questsList[id] or self.questsExtraTextList[id] or self.fillersList[id]
        if container then
            container.hiddenInCombat = nil
            container:SetAlpha(1)
            container:ClearAllPoints()
            container:Hide()
        end
        self.questsList[id] = nil
        self.questsExtraTextList[id] = nil
        self.fillersList[id] = nil
    end
    wipe(self.pendingRemoval)
    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OFFSET
    self:ReOrderQuestSteps(true)
    if APR.fillersFrame then
        APR.fillersFrame:ReOrderFillerSteps()
    end
end

function APR.currentStep:GetCurrentStepDetails()
    if not APR.ActiveRoute then return nil end
    local stepDetails = {
        extraLines = {},
        questSteps = {},
        fillerSteps = {},
        progress = {
            index = APRData[APR.PlayerID][APR.ActiveRoute],
            step = APR.currentStep.progressBar.currentStep,
            total = APRData[APR.PlayerID][APR.ActiveRoute .. '-TotalSteps'],
        }
    }

    -- Extra lines
    for key, container in pairs(self.questsExtraTextList) do
        if container.font and container.font:GetText() then
            table.insert(stepDetails.extraLines, {
                key = key,
                text = container.font:GetText(),
            })
        end
    end

    -- Quest steps
    for key, container in pairs(self.questsList) do
        if container.font and container.font:GetText() then
            local step = {
                key = key,
                text = container.font:GetText(),
            }

            -- Add sub-steps if they exist
            if container.subTexts then
                step.subSteps = {}
                for _, sub in ipairs(container.subTexts) do
                    table.insert(step.subSteps, {
                        questID = sub.questID,
                        name = sub.name,
                        text = sub.text,
                    })
                end
            end

            table.insert(stepDetails.questSteps, step)
        end
    end

    -- Filler steps
    for key, container in pairs(self.fillersList) do
        if container.font and container.font:GetText() then
            table.insert(stepDetails.fillerSteps, {
                key = key,
                text = container.font:GetText(),
            })
        end
    end

    return stepDetails
end
