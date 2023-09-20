local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")
local DF = _G["DetailsFramework"]

-- Initialize APR current step module
APR.currentStep = APR:NewModule("CurrentStep")

-- Init quests List to save quest
APR.currentStep.questsList = {}
APR.currentStep.questsExtraTextList = {}
-- Height of the quest frame
APR.currentStep.FrameHeight = 0

--Local constant
local FRAME_WIDTH = 235
local FRAME_HEADER_OPFFSET = -50
local FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET

---------------------------------------------------------------------------------------
--------------------------------- Current Step Frames ---------------------------------
---------------------------------------------------------------------------------------

-- Create the main current step frame
local CurrentStepFrame = CreateFrame("Frame", "CurrentStepScreenPanel", UIParent, "BackdropTemplate")
CurrentStepFrame:SetSize(FRAME_WIDTH, 500)
CurrentStepFrame:SetFrameStrata("LOW")

-- Create the step holder frame
local CurrentStepFrame_StepHolder = CreateFrame("Frame", "CurrentStepFrame_StepHolder", CurrentStepFrame,
    "BackdropTemplate")
CurrentStepFrame_StepHolder:SetAllPoints()

-- Create the frame header
local CurrentStepFrameHeader = CreateFrame("Frame", "CurrentStepFrameHeader", CurrentStepFrame,
    "ObjectiveTrackerHeaderTemplate")
CurrentStepFrameHeader.Text:SetText("Azeroth Pilot Reloaded") -- Replace with APR.title if needed

-- Create the minimize button
local minimizeButton = CreateFrame("Button", "CurrentStepFrameHeaderMinimizeButton", CurrentStepFrame, "BackdropTemplate")
local minimizeButtonText = minimizeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")

CurrentStepFrameHeader.MinimizeButton:Hide()
minimizeButtonText:SetText(APR.title)
minimizeButtonText:SetPoint("right", minimizeButton, "left", -3, 1)
minimizeButtonText:Hide()

CurrentStepFrame.MinimizeButton = minimizeButton
minimizeButton:SetSize(16, 16)
minimizeButton:SetPoint("topright", CurrentStepFrameHeader, "topright", 0, -4)
minimizeButton:SetScript("OnClick", function()
    if (CurrentStepFrame.collapsed) then
        APR.currentStep:SetDefaultDisplay()
    else
        CurrentStepFrame.collapsed = true
        minimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5)
        minimizeButton:GetPushedTexture():SetTexCoord(0.5, 1, 0, 0.5)
        CurrentStepFrame_StepHolder:Hide()
        CurrentStepFrameHeader:Hide()
        minimizeButtonText:Show()
        minimizeButtonText:SetText(APR.title)
    end
end)

minimizeButton:SetNormalTexture([[Interface\Buttons\UI-Panel-QuestHideButton]])
minimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0.5, 1)
minimizeButton:SetPushedTexture([[Interface\Buttons\UI-Panel-QuestHideButton]])
minimizeButton:GetPushedTexture():SetTexCoord(0.5, 1, 0.5, 1)
minimizeButton:SetHighlightTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]])
minimizeButton:SetDisabledTexture([[Interface\Buttons\UI-Panel-QuestHideButton-disabled]])

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
    minimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0.5, 1)
    minimizeButton:GetPushedTexture():SetTexCoord(0.5, 1, 0.5, 1)
    CurrentStepFrame_StepHolder:Show()
    CurrentStepFrameHeader:Show()
    minimizeButtonText:Hide()
end

-- Update the frame scale
function APR.currentStep:UpdateFrameScale()
    LibWindow.SetScale(CurrentStepScreenPanel, APR.settings.profile.currentStepScale)
end

-- Refresh the frame positioning
function APR.currentStep:RefreshCurrentStepFrameAnchor()
    if InCombatLockdown() then
        return
    end
    if (not APR.settings.profile.currentStepShow or not APR.settings.profile.enableAddon) then
        CurrentStepScreenPanel:Hide()
        return
    end

    if (APR.settings.profile.currentStepAttachFrameToQuestLog) then
        CurrentStepScreenPanel:EnableMouse(false)
        CurrentStepScreenPanel:ClearAllPoints()
        CurrentStepFrame:SetScale(1)

        for i = 1, ObjectiveTrackerFrame:GetNumPoints() do
            local point, relativeTo, relativePoint, xOfs, yOfs = ObjectiveTrackerFrame:GetPoint(i)
            CurrentStepScreenPanel:SetPoint(point, relativeTo, relativePoint, -10 + xOfs,
                yOfs - APR.currentStep.FrameHeight - 20)
        end

        if (APR.currentStep.FrameAttachToModule) then
            CurrentStepScreenPanel:ClearAllPoints()
            CurrentStepScreenPanel:SetPoint("top", APR.currentStep.FrameAttachToModule.Header, "bottom", 0,
                -APR.currentStep.FrameHeight + 10)
        end

        CurrentStepFrameHeader:ClearAllPoints()
        CurrentStepFrameHeader:SetPoint("bottom", CurrentStepFrame, "top", 0, -20)

        CurrentStepScreenPanel:Show()
    else
        if (not APR.settings.profile.currentStepLock) then
            CurrentStepScreenPanel:EnableMouse(true)
        else
            CurrentStepScreenPanel:EnableMouse(false)
        end

        LibWindow.RestorePosition(CurrentStepScreenPanel)
        self:UpdateFrameScale()

        CurrentStepFrameHeader:ClearAllPoints()
        CurrentStepFrameHeader:SetPoint("bottom", CurrentStepFrame, "top", 0, -20)

        CurrentStepScreenPanel:Show()
    end
end

-- Reset the frame position
function APR.currentStep:ResetPosition()
    CurrentStepScreenPanel:ClearAllPoints()
    CurrentStepScreenPanel:SetPoint("center", UIParent, "center", 0, 0)
    LibWindow.SavePosition(CurrentStepScreenPanel)
end

-- Hook on update for ObjectiveTrackerFrame (quests log)
local On_ObjectiveTracker_Update = function()
    local blizzObjectiveTracker = ObjectiveTrackerFrame
    if (not blizzObjectiveTracker.initialized) then
        return
    end

    APR.currentStep.FrameAttachToModule = nil

    if (blizzObjectiveTracker.collapsed) then
        APR.currentStep.FrameHeight = 20
    else
        for moduleId = #blizzObjectiveTracker.MODULES_UI_ORDER, 1, -1 do
            local module = blizzObjectiveTracker.MODULES_UI_ORDER[moduleId]
            if (module.Header:IsShown()) then
                APR.currentStep.FrameAttachToModule = module
                APR.currentStep.FrameHeight = module.contentsHeight
                break
            end
        end
    end

    APR.currentStep:RefreshCurrentStepFrameAnchor()
end

hooksecurefunc("ObjectiveTracker_Update", function(reason, id)
    On_ObjectiveTracker_Update()
    CurrentStepFrameHeader.Text:SetText(APR.title)
end)

ObjectiveTrackerFrame.HeaderMenu.MinimizeButton:HookScript("OnClick", function()
    On_ObjectiveTracker_Update()
end)

-- Rollback / skip button
function APR.currentStep:PreviousNextStepButton()
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

    local rollbackButton = CreateButton("CurrentStepFrame_StepHolder_RollbackButton", CurrentStepFrameHeader, 30, 30,
        L["ROLLBACK"],
        function()
            APR:SlashCmd('rollback')
        end)
    rollbackButton:SetPoint("BOTTOMLEFT", CurrentStepFrameHeader, "BOTTOMLEFT", 5, -30)
    rollbackButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Up]])
    rollbackButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Down]])
    rollbackButton:SetDisabledTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Disabled]])
    rollbackButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    CurrentStepFrame_StepHolder.rollbackButton = rollbackButton

    local skipButton = CreateButton("CurrentStepFrame_StepHolder_SkipButton", CurrentStepFrameHeader, 30, 30, L["SKIP"],
        function()
            APR:SlashCmd('skip')
        end)
    skipButton:SetPoint("BOTTOMRIGHT", CurrentStepFrameHeader, "BOTTOMRIGHT", -5, -30)
    skipButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
    skipButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Down]])
    skipButton:SetDisabledTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Disabled]])
    skipButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    CurrentStepFrame_StepHolder.skipButton = skipButton

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
    local totalSteps = total or 0
    local currentStep = current or 0
    if (self.progressBar) then
        self.progressBar:Hide()
        self.progressBar:ClearAllPoints()
        self.progressBar = nil
    end
    local progressBar = CreateFrame("StatusBar", "CurrentStepFrame_StepHolder_ProgressBar", CurrentStepFrameHeader,
        "BackdropTemplate")
    progressBar:SetSize(155, 20)
    progressBar:SetPoint("BOTTOM", CurrentStepFrameHeader, "BOTTOM", 0, -25)
    progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetStatusBarColor(0, 87 / 255, 183 / 255)
    progressBar:SetMinMaxValues(1, totalSteps)
    progressBar:SetValue(currentStep)
    progressBar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true,
        tileSize = 16
    })
    progressBar:SetBackdropColor(0, 0, 0, 0.75)

    local progressBarText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    progressBarText:SetPoint("CENTER", progressBar, "CENTER", 0, 0)
    progressBarText:SetText(currentStep .. " / " .. totalSteps)

    -- Update the progress bar when the current step changes
    local function UpdateProgressBar(newCurrentStep)
        progressBar:SetValue(newCurrentStep)
        progressBarText:SetText(newCurrentStep .. " / " .. totalSteps)
    end

    -- Call UpdateProgressBar with the current step
    UpdateProgressBar(currentStep)

    APR.currentStep.progressBar = progressBar
    APR.currentStep.progressBar.key = key
end

-- Displaying quest information
local AddStepsFrame = function(questDesc, extraLineText)
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
    if extraLineText then
        font:SetText(TextWithStars(extraLineText))
    else
        font:SetText('- ' .. questDesc)
    end
    font:SetJustifyH("LEFT")
    -- Set the size of the container based on the text length
    container:SetWidth(FRAME_WIDTH)
    container:SetHeight(font:GetStringHeight() + 10)
    -- container:SetBackdrop({
    --     bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    --     tile = true,
    --     tileSize = 16
    -- })
    -- container:SetBackdropColor(0, 0, 0, 0.75)

    return container
end
-- Displaying extra line text information
local AddExtraLineTextFrame = function(extraLineText)
    return AddStepsFrame(nil, extraLineText)
end

-- Add/Update quest steps
function APR.currentStep:UpdateQuestSteps(questID, textObjective, objectiveIndex)
    -- Check if questsExtraTextList or questsList are empty to reset to the default height
    if not next(self.questsExtraTextList) or not next(self.questsList) then
        FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
    end

    local questKey = questID .. "-" .. objectiveIndex
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
    self.questsList[questKey] = objectiveContainer
    FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - objectiveContainer:GetHeight()

    -- to update quest order display
    self:ReOrderQuestSteps()
end

local getExtraLineHeight = function()
    -- Always reset to header offset with a new extra line
    local height = FRAME_HEADER_OPFFSET
    for id, textContainer in pairs(APR.currentStep.questsExtraTextList) do
        height = height - textContainer:GetHeight()
    end
    return height
end

--- Add a new Extra line text
---@param key string Locale table key
---@param text string L[key]
function APR.currentStep:AddExtraLineText(key, text)
    -- Always reset to header height with a new extra line
    FRAME_STEP_HOLDER_HEIGHT = getExtraLineHeight()

    local existingContainer = self.questsExtraTextList[key]
    if existingContainer then
        existingContainer:Hide()
        existingContainer:ClearAllPoints()
        self.questsExtraTextList[key] = nil
    end

    local extraLineTextContainer = AddExtraLineTextFrame(text)
    extraLineTextContainer:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)
    extraLineTextContainer.key = key
    self.questsExtraTextList[key] = extraLineTextContainer
    FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - extraLineTextContainer:GetHeight()

    self:ReOrderExtraLineText()
end

function APR.currentStep:ReOrderExtraLineText()
    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
    for id, textContainer in pairs(self.questsExtraTextList) do
        textContainer:Hide()
        textContainer:ClearAllPoints()
        textContainer:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)
        textContainer:Show()
        FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - textContainer:GetHeight()
    end
    self:ReOrderQuestSteps(false)
end

--- Re order all the quest Step
--- @param hasExtraLineHeight boolean to get the extra line height
function APR.currentStep:ReOrderQuestSteps(hasExtraLineHeight)
    hasExtraLineHeight = hasExtraLineHeight or true
    if hasExtraLineHeight then
        FRAME_STEP_HOLDER_HEIGHT = getExtraLineHeight()
    end
    for id, questContainer in pairs(self.questsList) do
        questContainer:Hide()
        questContainer:ClearAllPoints()
        questContainer:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)
        questContainer:Show()
        FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - questContainer:GetHeight()
    end
end

-- Remove all quest steps
function APR.currentStep:RemoveQuestSteps()
    for id, questContainer in pairs(self.questsList) do
        questContainer:Hide()
        questContainer:ClearAllPoints()
        questContainer = nil
    end
    self.questsList = {}
    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
end

-- Remove all extra line texts
function APR.currentStep:RemoveExtraLineTexts()
    for id, questContainer in pairs(self.questsExtraTextList) do
        questContainer:Hide()
        questContainer:ClearAllPoints()
        questContainer = nil
    end
    self.questsExtraTextList = {}
    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
end

-- Remove all  quest steps and extra line texts
function APR.currentStep:RemoveQuestStepsAndExtraLineTexts()
    self:RemoveQuestSteps()
    self:RemoveExtraLineTexts()
end

-- Button management
--- Create a icon button next to the quest/text step
--- @param questsListKey string the questsList key (questId-index)
--- @param itemID number Item ID
--- @param attribute number Icon attribute spell/item
function APR.currentStep:AddStepButton(questsListKey, itemID, attribute)
    attribute = attribute or "item"
    local container = self.questsList[questsListKey] or next(self.questsList) or next(self.questsExtraTextList)
    if container == nil then
        return
    end
    local function iconName()
        if attribute == "item" then
            local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
            return itemName, itemTexture
        else
            local name, _, icon = GetSpellInfo(itemID)
            return name, icon
        end
    end
    local iconName, iconTexture = iconName()

    local IconButton = CreateFrame("Button", "$parentIconButton", container,
        "SecureActionButtonTemplate, BackdropTemplate")
    IconButton:SetSize(25, 25)
    IconButton:SetPoint("RIGHT", container, "LEFT", -5, 0)
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
    IconButton.cooldown:SetAllPoints();
    IconButton.cooldown:Hide()

    IconButton.itemID = itemID
    IconButton.attribute = attribute
    container.IconButton = IconButton
end

function APR.currentStep:RemoveStepButtonByKey(questsListKey)
    local existingButton = self.questsList[questsListKey]
    if not existingButton then
        return
    end
    existingButton:Hide()
    existingButton:ClearAllPoints()
    self.questsList[questsListKey] = nil
end

function APR.currentStep:UpdateStepButtonCooldowns()
    for id, questContainer in pairs(self.questsList) do
        local IconButton = questContainer.IconButton
        if IconButton then
            if IconButton:IsShown() then
                local start, duration
                if IconButton.attribute == 'spell' then
                    start, duration = GetSpellCooldown(tonumber(IconButton.itemID))
                else
                    start, duration = C_Container.GetItemCooldown(tonumber(IconButton.itemID))
                end
                if start then
                    if IconButton.cooldown:GetCooldownDuration() == 0 or not IconButton.cooldown:IsShown() then
                        IconButton.cooldown:SetCooldown(start, duration)
                    end
                else
                    IconButton.cooldown:Clear()
                end
            else
                IconButton.cooldown:Clear()
            end
        end
    end
end

--- Disable Button, Reset ProgressBar and Remove all quest and extra line
function APR.currentStep:Disable()
    self:ButtonDisable()
    self:ProgressBar()
    self:RemoveQuestStepsAndExtraLineTexts()
end
