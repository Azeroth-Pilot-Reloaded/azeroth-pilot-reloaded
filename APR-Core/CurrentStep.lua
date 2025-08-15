local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR current step module
APR.currentStep = APR:NewModule("CurrentStep")

-- Init quests List to save quest
APR.currentStep.questsList = {}
APR.currentStep.questsExtraTextList = {}
APR.currentStep.pendingRemoval = {}
-- Height of the quest frame
APR.currentStep.FrameHeight = 0

-- Save the previous
APR.currentStep.previousState = {}


--Local constant
local FRAME_WIDTH = 250
local FRAME_HEADER_OPFFSET = -30
local FRAME_ATTACH_OPFFSET = -35
local FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
local isDragging = false

---------------------------------------------------------------------------------------
--------------------------------- Current Step Frames ---------------------------------
---------------------------------------------------------------------------------------

-- Create the main current step frame
local CurrentStepFrame = CreateFrame("Frame", "CurrentStepScreenPanel", UIParent, "BackdropTemplate")
CurrentStepFrame:SetSize(FRAME_WIDTH, 30)
CurrentStepFrame:SetFrameStrata("MEDIUM")
CurrentStepFrame:SetClampedToScreen(true)
CurrentStepFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    tile = true,
    tileSize = 16
})
CurrentStepFrame:SetBackdropColor(unpack(APR.Color.defaultBackdrop))

-- Create the step holder frame
local CurrentStepFrame_StepHolder = CreateFrame("Frame", "CurrentStepFrame_StepHolder", CurrentStepFrame,
    "BackdropTemplate")
CurrentStepFrame_StepHolder:SetAllPoints()

-- Create the frame header
local CurrentStepFrameHeader = CreateFrame("Frame", "CurrentStepFrameHeader", CurrentStepFrame,
    "ObjectiveTrackerContainerHeaderTemplate")
CurrentStepFrameHeader.Text:SetText("Azeroth Pilot Reloaded") -- don't replace it with APR.title

CurrentStepFrameHeader:RegisterForDrag("LeftButton")
CurrentStepFrameHeader:SetScript("OnDragStart", function(self)
    if not APR.settings.profile.currentStepLock and not APR.settings.profile.currentStepAttachFrameToQuestLog then
        self:GetParent():StartMoving()
        isDragging = true
    end
end)

CurrentStepFrameHeader:SetScript("OnDragStop", function(self)
    self:GetParent():StopMovingOrSizing()
    LibWindow.SavePosition(CurrentStepScreenPanel)
    isDragging = false
end)
CurrentStepFrameHeader:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not isDragging and not APR.settings.profile.currentStepLock and not APR.settings.profile.currentStepAttachFrameToQuestLog then
        self:GetParent():StartMoving()
        isDragging = true
    elseif button == "RightButton" then
        MenuUtil.CreateContextMenu(UIParent, APR.GetMenu)
    end
end)

CurrentStepFrameHeader:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and isDragging then
        self:GetParent():StopMovingOrSizing()
        LibWindow.SavePosition(CurrentStepScreenPanel)
        isDragging = false
    end
end)

-- Create the minimize button
CurrentStepFrameHeader.MinimizeButton:SetScript("OnClick", function(self)
    if CurrentStepFrame.collapsed then
        APR.currentStep:ButtonShow()
        APR.currentStep.progressBar:Show()
        APR.currentStep:SetDefaultDisplay()
        self:GetNormalTexture():SetAtlas("ui-questtrackerbutton-collapse-all")
        self:GetPushedTexture():SetAtlas("ui-questtrackerbutton-collapse-all-pressed")
    else
        CurrentStepFrame.collapsed = true
        CurrentStepFrame_StepHolder:Hide()
        APR.currentStep:UpdateBackgroundColorAlpha({ 0, 0, 0, 0 })
        APR.currentStep:ButtonHide()
        APR.currentStep.progressBar:Hide()
        self:GetNormalTexture():SetAtlas("ui-questtrackerbutton-expand-all")
        self:GetPushedTexture():SetAtlas("ui-questtrackerbutton-expand-all-pressed")
    end
end)

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
end

-- Refresh the frame positioning
function APR.currentStep:RefreshCurrentStepFrameAnchor()
    APR:Debug("Function: APR:RefreshCurrentStepFrameAnchor()")
    if not APR.settings.profile.currentStepShow or not APR.settings.profile.enableAddon or C_PetBattles.IsInBattle() or not APR:IsInstanceWithUI() then
        CurrentStepScreenPanel:Hide()
        return
    end

    if APR.settings.profile.currentStepAttachFrameToQuestLog then
        if not InCombatLockdown() then
            CurrentStepScreenPanel:EnableMouse(false)
        end
        CurrentStepScreenPanel:ClearAllPoints()
        CurrentStepFrame:SetScale(1)

        if APR.currentStep.FrameAttachToModule then
            CurrentStepScreenPanel:SetPoint("TOP", APR.currentStep.FrameAttachToModule, "BOTTOM", 0, FRAME_ATTACH_OPFFSET)
        elseif ObjectiveTrackerFrame.Header then
            CurrentStepScreenPanel:SetPoint("TOP", ObjectiveTrackerFrame.Header, "BOTTOM", 0, FRAME_ATTACH_OPFFSET)
        end
    else
        if not InCombatLockdown() then
            if not APR.settings.profile.currentStepLock then
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
    end
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
    if not APR.settings.profile.currentStepShow then
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
        progressBar:SetStatusBarColor(unpack(APR.Color.blue))
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
    local textTemplate = "GameFontHighlight" -- white color
    if extraLineText then
        textTemplate = "GameFontNormal"      -- yellow color
    end
    -- Create a container for quest information
    local container = CreateFrame("Frame", nil, CurrentStepFrame_StepHolder, "BackdropTemplate")
    -- Create a font for quest information
    local font = container:CreateFontString(nil, "OVERLAY", textTemplate)
    font:SetWordWrap(true)
    font:SetWidth(FRAME_WIDTH)
    font:SetPoint("TOPLEFT", 5, -5)
    font:SetText('- ' .. (extraLineText or questDesc))
    font:SetJustifyH("LEFT")

    if color then
        font:SetTextColor(unpack(APR:HexaToRGBA(color)))
    end

    -- Set the size of the container based on the text length
    container:SetWidth(FRAME_WIDTH)
    container:SetHeight(font:GetStringHeight() + 10)
    container:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        tile = true,
        tileSize = 16
    })
    container:SetBackdropColor(unpack(APR.settings.profile.currentStepbackgroundColorAlpha))
    container.font = font

    return container
end

-- Displaying extra line text information
local function AddExtraLineTextFrame(extraLineText, color)
    return AddStepsFrame(nil, extraLineText, color)
end

-- Add/Update quest steps
function APR.currentStep:AddQuestSteps(questID, textObjective, objectiveIndex, isScenario, noTooltip)
    if not APR.settings.profile.currentStepShow then
        return
    end

    -- Check if questsExtraTextList or questsList are empty to reset to the default height
    if not next(self.questsExtraTextList) or not next(self.questsList) then
        FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
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

            if isScenario then
                GameTooltip:AddLine("|c33ecc00f" .. SCENARIOS .. " " .. ID .. ": |r" .. questID, unpack(APR.Color.white))
                GameTooltip:AddLine("|c33ecc00f" .. NAME .. '|r: ' .. C_ScenarioInfo.GetScenarioStepInfo().title,
                    unpack(APR.Color.white))
                GameTooltip:AddLine("|c33ecc00fStepID|r: " .. C_ScenarioInfo.GetScenarioStepInfo().stepID,
                    unpack(APR.Color.white))
                GameTooltip:AddLine(
                    "|c33ecc00f" .. OBJECTIVES_LABEL .. "|r: " .. objectiveIndex .. " - " .. textObjective,
                    1, 1, 1, true)
            else
                GameTooltip:AddLine("|c33ecc00f" .. ID .. ": |r" .. questID, unpack(APR.Color.white))
                local questTitle = C_QuestLog.GetTitleForQuestID(questID)
                if questTitle then
                    GameTooltip:AddLine("|c33ecc00f" .. NAME .. '|r: ' .. questTitle, unpack(APR.Color.white))
                end
                GameTooltip:AddLine(
                    "|c33ecc00f" .. OBJECTIVES_LABEL .. "|r: " .. objectiveIndex .. " - " .. textObjective,
                    1, 1, 1, true)
                GameTooltip:AddLine("|c33ecc00f" .. L["CAMPAIGN"] .. "|r: " ..
                    (APR:IsCampaignQuest(questID) and "|cff00ff00" .. YES .. "|r" or "|ccce0000f" .. NO .. "|r"),
                    unpack(APR.Color.white))
            end
            GameTooltip:Show()
        end)


        objectiveContainer:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    end
    self.questsList[questKey] = objectiveContainer
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
    local height = FRAME_HEADER_OPFFSET
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
        FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
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
    self.questsList[id] = container
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

    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
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
end

-- Remove all  quest steps and extra line texts
function APR.currentStep:RemoveQuestStepsAndExtraLineTexts(removeTextOnly)
    APR:Debug("Function: APR.currentStep:RemoveQuestStepsAndExtraLineTexts()")
    removeTextOnly = removeTextOnly or false
    if not APR.settings.profile.currentStepShow then return end

    local function ResetList(list, isQuestList)
        for id, container in pairs(list) do
            local canHide = self:CanSafelyHide(container)
            if canHide then
                container:ClearAllPoints()
                container:Hide()
                if isQuestList then
                    -- kill button if present (only outside combat)
                    local btn = container.IconButton
                    if btn then
                        btn:Hide()
                        btn:ClearAllPoints()
                        container.IconButton = nil
                    end
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

    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
    -- Reorder ignoring soft-hidden
    self:ReOrderQuestSteps(true)
end

local function PositionStepButtons(container, button)
    if APR.settings.profile.currentStepQuestButtonPositionRight then
        button:SetPoint("LEFT", container, "RIGHT", 5, 0)
    else
        button:SetPoint("RIGHT", container, "LEFT", -5, 0)
    end
end
-- Button management
--- Create a icon button next to the quest/text step
--- @param questsListKey string the questsList key (questId-index)
--- @param itemID number Item ID
--- @param attribute number Icon attribute spell/item
function APR.currentStep:AddStepButton(questsListKey, itemID, attribute)
    if not APR.settings.profile.currentStepShow and itemID then
        return
    end
    attribute = attribute or "item"
    local container = self.questsList[questsListKey]
    if not container then
        return
    end
    local function getIconName()
        if attribute == "item" then
            local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemID)
            return itemName, itemTexture
        else
            local spellInfo = C_Spell.GetSpellInfo(itemID)
            return spellInfo.name, spellInfo.iconID
        end
    end
    local iconName, iconTexture = getIconName()
    if not iconName and not iconTexture then
        return
    end

    local IconButton = CreateFrame("Button", "$parentIconButton", container,
        "SecureActionButtonTemplate, BackdropTemplate")
    IconButton:SetSize(25, 25)
    PositionStepButtons(container, IconButton)
    IconButton:SetNormalTexture(iconTexture)
    IconButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    IconButton:RegisterForClicks("AnyUp", "AnyDown")
    IconButton:SetAttribute("type1", attribute)
    IconButton:SetAttribute(attribute, iconName)

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
    for id, container in pairs(self.questsList) do
        -- Ignore soft-hidden containers (during combat)
        if container and not container.hiddenInCombat then
            local IconButton = container.IconButton
            if IconButton and IconButton:IsShown() then
                local startTime, duration, enable = 0, 0, 0
                local isCooldownShown = IconButton.cooldown:IsShown()
                local cooldownDuration = IconButton.cooldown:GetCooldownDuration()

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

--- Disable Button, Reset ProgressBar and Remove all quest and extra line
function APR.currentStep:Reset()
    APR:Debug("Function: APR.currentStep:Reset()")
    self:ButtonShow()
    self:ButtonDisable()
    self:ProgressBar()
    self:RemoveQuestStepsAndExtraLineTexts()
end

function APR.GetMenu(owner, rootDescription)
    local toggleAddon = ''
    if APR.settings.profile.enableAddon then
        toggleAddon = "|ccce0000f " .. L["DISABLE"] .. "|r"
    else
        toggleAddon = "|cff00ff00 " .. L["ENABLE"] .. "|r"
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

    rootDescription:CreateButton(L["QOL_COMMAND"], function()
        APR.settings.profile.showQuestOrderList = not APR.settings.profile.showQuestOrderList
        APR.questOrderList:RefreshFrameAnchor()
    end)

    rootDescription:CreateButton(toggleAddon .. " " .. L["ADDON"], function()
        APR.settings.profile.enableAddon = not APR.settings.profile.enableAddon
        APR.settings:ToggleAddon()
    end)

    rootDescription:CreateDivider()
    rootDescription:CreateTitle(L["CURRENT_STEP"])

    rootDescription:CreateButton(L["QLIST_ATTACH_QUESTLOG"], function()
        APR.settings.profile.currentStepAttachFrameToQuestLog = not APR.settings.profile
            .currentStepAttachFrameToQuestLog
        APR.currentStep:RefreshCurrentStepFrameAnchor()
    end)

    rootDescription:CreateButton(L["LOCK_WINDOW"], function()
        APR.settings.profile.currentStepLock = not APR.settings.profile.currentStepLock
        APR.currentStep:RefreshCurrentStepFrameAnchor()
    end)

    rootDescription:CreateButton(L["RESET_CURRENT_STEP_FRAME_POSITION"], function()
        APR.currentStep:ResetPosition()
    end)
end

function APR.currentStep:IsShown()
    return CurrentStepScreenPanel:IsShown()
end

function APR.currentStep:CanSafelyHide(container)
    -- If we are in combat AND the container has a secure button, do not hide
    return not InCombatLockdown() or not (container.IconButton and container.IconButton:IsProtected())
end

function APR.currentStep:SoftHide(container)
    container.hiddenInCombat = true
    container:SetAlpha(0.001)
end

function APR.currentStep:FlushPendingContainers()
    if not next(self.pendingRemoval) then return end
    for id, _ in pairs(self.pendingRemoval) do
        local container = self.questsList[id] or self.questsExtraTextList[id]
        if container then
            container.hiddenInCombat = nil
            container:SetAlpha(1)
            container:ClearAllPoints()
            container:Hide()
        end
        self.questsList[id] = nil
        self.questsExtraTextList[id] = nil
    end
    wipe(self.pendingRemoval)
    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
    self:ReOrderQuestSteps(true)
end

function APR.currentStep:GetCurrentStepDetails()
    local stepDetails = {
        extraLines = {},
        questSteps = {},
        progress = {
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
            table.insert(stepDetails.questSteps, {
                key = key,
                text = container.font:GetText(),
            })
        end
    end

    return stepDetails
end
