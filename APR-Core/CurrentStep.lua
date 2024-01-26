local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

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
local isDragging = false

---------------------------------------------------------------------------------------
--------------------------------- Current Step Frames ---------------------------------
---------------------------------------------------------------------------------------

-- Create the main current step frame
local CurrentStepFrame = CreateFrame("Frame", "CurrentStepScreenPanel", UIParent, "BackdropTemplate")
CurrentStepFrame:SetSize(FRAME_WIDTH, 50)
CurrentStepFrame:SetFrameStrata("HIGH")
CurrentStepFrame:SetClampedToScreen(true)
CurrentStepFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    tile = true,
    tileSize = 16
})
CurrentStepFrame:SetBackdropColor(0, 0, 0, 0)

-- Create the step holder frame
local CurrentStepFrame_StepHolder = CreateFrame("Frame", "CurrentStepFrame_StepHolder", CurrentStepFrame,
    "BackdropTemplate")
CurrentStepFrame_StepHolder:SetAllPoints()

-- Create the frame header
local CurrentStepFrameHeader = CreateFrame("Frame", "CurrentStepFrameHeader", CurrentStepFrame,
    "ObjectiveTrackerHeaderTemplate")
CurrentStepFrameHeader.Text:SetText("Azeroth Pilot Reloaded") -- Replace with APR.title if needed

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
        local menu = CreateFrame("Frame", "CurrentStepHeaderContextMenu", UIParent, "UIDropDownMenuTemplate")
        local toggleAddon = ''
        if APR.settings.profile.enableAddon then
            toggleAddon = "|ccce0000f " .. L["DISABLE"] .. "|r"
        else
            toggleAddon = "|c33ecc00f " .. L["ENABLE"] .. "|r"
        end
        local menuList = {
            { text = APR.title,         isTitle = true, notCheckable = true },
            {
                text = L["SHOW_MENU"],
                func = function()
                    APR.settings:OpenSettings(APR.title)
                end
            },
            {
                text = L["ROUTE"],
                func = function()
                    APR.settings:OpenSettings(L["ROUTE"])
                end
            },
            {
                text = L["PROFILES"],
                func = function()
                    APR.settings:OpenSettings(L["PROFILES"])
                end
            },
            {
                text = L["ABOUT_HELP"],
                func = function()
                    APR.settings:OpenSettings(L["ABOUT_HELP"])
                end
            },
            {
                text = toggleAddon .. " " .. L["ADDON"],
                func = function()
                    APR.settings.profile.enableAddon = not APR.settings.profile.enableAddon
                    APR.settings:ToggleAddon()
                end
            },
            { text = L["CURRENT_STEP"], isTitle = true, notCheckable = true },
            {
                text = L["QLIST_ATTACH_QUESTLOG"],
                func = function()
                    APR.settings.profile.currentStepAttachFrameToQuestLog = not APR.settings.profile
                        .currentStepAttachFrameToQuestLog
                    APR.currentStep:RefreshCurrentStepFrameAnchor()
                end
            },
            {
                text = L["LOCK_WINDOW"],
                func = function()
                    APR.settings.profile.currentStepLock = not APR.settings.profile
                        .currentStepLock
                    APR.currentStep:RefreshCurrentStepFrameAnchor()
                end
            },
            {
                text = L["RESET_CURRENT_STEP_FRAME_POSITION"],
                func = function()
                    APR.currentStep:ResetPosition()
                end
            },

        }
        EasyMenu(menuList, menu, "cursor", 0, 0, "MENU", 5)
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
        APR.currentStep:UpdateBackgroundColorAlpha({ 0, 0, 0, 0 })
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
    APR.currentStep:UpdateBackgroundColorAlpha()
end

-- Update the frame scale
function APR.currentStep:UpdateFrameScale()
    LibWindow.SetScale(CurrentStepScreenPanel, APR.settings.profile.currentStepScale)
end

function APR.currentStep:UpdateBackgroundColorAlpha(color)
    CurrentStepFrame:SetBackdropColor(unpack(color or APR.settings.profile.currentStepbackgroundColorAlpha))
    local UpdateColor = function(list)
        for _, container in pairs(list) do
            container:SetBackdropColor(unpack(color or APR.settings.profile.currentStepbackgroundColorAlpha))
        end
    end
    UpdateColor(self.questsList)
    UpdateColor(self.questsExtraTextList)
end

-- Refresh the frame positioning
function APR.currentStep:RefreshCurrentStepFrameAnchor()
    if InCombatLockdown() then
        return
    end
    if (not APR.settings.profile.currentStepShow or not APR.settings.profile.enableAddon or C_PetBattles.IsInBattle()) then
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
                yOfs + FRAME_STEP_HOLDER_HEIGHT - 40)
        end

        if (APR.currentStep.FrameAttachToModule) then
            CurrentStepScreenPanel:ClearAllPoints()
            CurrentStepScreenPanel:SetPoint("top", APR.currentStep.FrameAttachToModule.Header, "bottom", 0,
                -APR.currentStep.FrameHeight +
                (FRAME_STEP_HOLDER_HEIGHT == FRAME_HEADER_OPFFSET and 0 or FRAME_STEP_HOLDER_HEIGHT) + 20)
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
    self:SetDefaultDisplay()
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
    rollbackButton:SetPoint("BOTTOMLEFT", CurrentStepFrameHeader, "BOTTOMLEFT", 5, -30)
    rollbackButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Up]])
    rollbackButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Down]])
    rollbackButton:SetDisabledTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Disabled]])
    rollbackButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    CurrentStepFrame_StepHolder.rollbackButton = rollbackButton

    local skipButton = CreateButton("CurrentStepFrame_StepHolder_SkipButton", CurrentStepFrameHeader, 30, 30, L["SKIP"],
        function()
            APR.command:SlashCmd('skip')
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
        if totalSteps > 0 then
            progressBarText:SetText(currentStep .. " / " .. totalSteps)
        else
            progressBarText:SetText("")
        end

        self.progressBar = progressBar
        self.progressBar.Text = progressBarText
        self.progressBar.key = key
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
            _G.GetTotalSteps()
        end
        local curStepDisplayed = CurStep - (APRData[APR.PlayerID][APR.ActiveRoute .. '-SkippedStep'] or 0)
        APR.currentStep:ProgressBar(APR.ActiveRoute, APRData[APR.PlayerID]
            [APR.ActiveRoute .. '-TotalSteps'], curStepDisplayed)
    end
end

-- Displaying quest information
local function AddStepsFrame(questDesc, extraLineText, noStars)
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
        font:SetText(TextWithStars(extraLineText, noStars and 0 or 2))
    else
        font:SetText('- ' .. questDesc)
    end
    font:SetJustifyH("LEFT")
    -- Set the size of the container based on the text length
    container:SetWidth(FRAME_WIDTH)
    container:SetHeight(font:GetStringHeight() + 10)
    container:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        tile = true,
        tileSize = 16
    })
    container:SetBackdropColor(unpack(APR.settings.profile.currentStepbackgroundColorAlpha))

    return container
end

-- Displaying extra line text information
local function AddExtraLineTextFrame(extraLineText, noStars)
    return AddStepsFrame(nil, extraLineText, noStars)
end

-- Add/Update quest steps
function APR.currentStep:UpdateQuestSteps(questID, textObjective, objectiveIndex)
    if InCombatLockdown() or not APR.settings.profile.currentStepShow then
        return
    end
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
function APR.currentStep:AddExtraLineText(key, text, noStars)
    if InCombatLockdown() or not APR.settings.profile.currentStepShow then
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

    local extraLineTextContainer = AddExtraLineTextFrame(text, noStars)
    extraLineTextContainer:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)
    extraLineTextContainer.key = key
    self.questsExtraTextList[key] = extraLineTextContainer
    FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - extraLineTextContainer:GetHeight()

    self:ReOrderExtraLineText()
end

function APR.currentStep:ReOrderExtraLineText()
    if InCombatLockdown() or not APR.settings.profile.currentStepShow then
        return
    end
    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
    for id, textContainer in pairs(self.questsExtraTextList) do
        textContainer:ClearAllPoints()
        textContainer:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)
        FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - textContainer:GetHeight()
    end
    self:ReOrderQuestSteps(false)
end

--- Re order all the quest Step
--- @param hasExtraLineHeight boolean to get the extra line height
function APR.currentStep:ReOrderQuestSteps(hasExtraLineHeight)
    if InCombatLockdown() or not APR.settings.profile.currentStepShow then
        return
    end
    hasExtraLineHeight = hasExtraLineHeight or true
    if hasExtraLineHeight then
        FRAME_STEP_HOLDER_HEIGHT = getExtraLineHeight()
    end
    for id, questContainer in pairs(self.questsList) do
        questContainer:ClearAllPoints()
        questContainer:SetPoint("TOPLEFT", CurrentStepFrame, "TOPLEFT", 0, FRAME_STEP_HOLDER_HEIGHT)
        FRAME_STEP_HOLDER_HEIGHT = FRAME_STEP_HOLDER_HEIGHT - questContainer:GetHeight()
    end
end

-- Remove all  quest steps and extra line texts
function APR.currentStep:RemoveQuestStepsAndExtraLineTexts()
    if InCombatLockdown() or not APR.settings.profile.currentStepShow then
        return
    end
    local ResetList = function(list)
        for id, questContainer in pairs(list) do
            questContainer:Hide()
            questContainer:ClearAllPoints()
            questContainer = nil
        end
    end
    ResetList(self.questsList)
    self.questsList = {}
    ResetList(self.questsExtraTextList)
    self.questsExtraTextList = {}
    FRAME_STEP_HOLDER_HEIGHT = FRAME_HEADER_OPFFSET
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
    if InCombatLockdown() or not APR.settings.profile.currentStepShow and itemID then
        return
    end
    attribute = attribute or "item"
    local container = self.questsList[questsListKey]
    if container == nil then
        local containerId = next(self.questsList) or next(self.questsExtraTextList)
        if containerId == nil then
            return
        else
            container = self.questsList[containerId]
        end
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
    if IconButton then
        container.IconButton = IconButton
    end
end

function APR.currentStep:RemoveStepButtonByKey(questsListKey)
    if InCombatLockdown() or not APR.settings.profile.currentStepShow then
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
    self:RefreshCurrentStepFrameAnchor()
end
