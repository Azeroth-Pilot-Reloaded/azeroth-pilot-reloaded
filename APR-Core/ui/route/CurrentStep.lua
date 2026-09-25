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
APR.currentStep.pendingContainerDestroy = {}
APR.currentStep.pendingRaidIconNpcId = nil
APR.currentStep.raidIconAdded = false
APR.currentStep.pendingRaidIconMacroRefresh = false
APR.currentStep.raidIconButton = nil
-- Height of the quest frame
APR.currentStep.FrameHeight = 0

-- Save the previous
APR.currentStep.previousState = {}

--Local constant
APR.currentStep.layout = { width = 250, topOffset = 30, padding = 16, indent = 25, detailGap = 3 }
local FRAME_WIDTH = APR.currentStep.layout.width
local FRAME_ATTACH_OFFSET = -35
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

if APR.currentStepImagePreview and APR.currentStepImagePreview.ConfigureCurrentStepPreview then
    APR.currentStepImagePreview:ConfigureCurrentStepPreview(CurrentStepFrame_StepHolder, FRAME_WIDTH)
end

-- Create the frame header
local CurrentStepFrameHeader = APR:CreateFrameHeader("CurrentStepFrameHeader", CurrentStepFrame,
    "Azeroth Pilot Reloaded", "ObjectiveTrackerContainerHeaderTemplate", "currentStep") -- don't replace with APR.title

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
    MenuUtil.CreateContextMenu(CurrentStepFrameHeader, APR.GetMenu)
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
CurrentStepFrameSettingsButton:SetSize(22, 22)
CurrentStepFrameSettingsButton:SetPoint("RIGHT", CurrentStepFrameHeader.MinimizeButton, "LEFT", -3, 0)
CurrentStepFrameSettingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
CurrentStepFrameSettingsButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
CurrentStepFrameSettingsButton:SetScript("OnClick", function(self, button)
    MenuUtil.CreateContextMenu(self, APR.GetMenu)
end)
CurrentStepFrameSettingsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    APR:SetTooltipText(GameTooltip, L["SHOW_MENU"] or "Settings", "currentStep", "base")
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
    if APR.currentStep.progressBar then
        APR.currentStep.progressBar:Hide()
    end
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
    APR.currentStep:SetDefaultDisplay()
    APR.currentStep:ButtonShow()
    if APR.currentStep.progressBar then
        APR.currentStep.progressBar:Show()
    end
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
    -- ElvUI arrow skinning strips text fontstrings from buttons; these controls use
    -- icon textures, not visible text, so avoid creating a fontstring before the skin runs.
    button:SetScript("OnClick", script)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        APR:AddTooltipLine(GameTooltip, text, "currentStep", "base")
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    return button
end

-- Rollback / skip button
function APR.currentStep:PreviousNextStepButton()
    local rollbackButton = CreateButton("CurrentStepFrame_StepHolder_RollbackButton", CurrentStepFrameHeader, 24, 24,
        L["ROLLBACK"],
        function()
            APR.command:SlashCmd('rollback')
        end)
    rollbackButton:SetPoint("BOTTOMLEFT", CurrentStepFrameHeader, "BOTTOMLEFT", 8, -28)
    rollbackButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Up]])
    rollbackButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Down]])
    rollbackButton:SetDisabledTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Disabled]])
    rollbackButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    CurrentStepFrame_StepHolder.rollbackButton = rollbackButton

    local skipButton = CreateButton("CurrentStepFrame_StepHolder_SkipButton", CurrentStepFrameHeader, 24, 24, L["SKIP"],
        function()
            APR.command:SlashCmd('skip')
        end)
    skipButton:SetPoint("BOTTOMRIGHT", CurrentStepFrameHeader, "BOTTOMRIGHT", -8, -28)
    skipButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
    skipButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Down]])
    skipButton:SetDisabledTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Disabled]])
    skipButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    CurrentStepFrame_StepHolder.skipButton = skipButton
    if APR.RegisterSkinTarget then
        APR:RegisterSkinTarget(rollbackButton, "arrow", { direction = "left" })
        APR:RegisterSkinTarget(skipButton, "arrow", { direction = "right" })
    end

    self.ButtonHide = function()
        rollbackButton:Hide()
        skipButton:Hide()
    end

    self.ButtonShow = function()
        if CurrentStepFrame.collapsed then
            rollbackButton:Hide()
            skipButton:Hide()
            return
        end

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

    local totalSteps = total or 0
    local currentStep = current or 0

    if not self.progressBar then
        local progressBar = CreateFrame("StatusBar", "CurrentStepFrame_StepHolder_ProgressBar", CurrentStepFrameHeader,
            "BackdropTemplate")
        progressBar:SetSize(FRAME_WIDTH - 92, 18)
        progressBar:SetPoint("BOTTOM", CurrentStepFrameHeader, "BOTTOM", 0, -25)
        progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        APR.currentStep:UpdateProgressBarColor(progressBar)
        progressBar:SetMinMaxValues(0, math.max(totalSteps, 1))
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
        APR:RegisterFontString(progressBarText, "currentStep", { role = "base" })

        if APR.RegisterSkinTarget then APR:RegisterSkinTarget(progressBar, "statusbar") end
        self.progressBar = progressBar
        self.progressBar.Text = progressBarText
        self.progressBar.key = key
        self.progressBar.currentStep = currentStep
    else
        self.progressBar:SetMinMaxValues(0, math.max(totalSteps, 1))
        self.progressBar.key = key
        self.progressBar:SetValue(currentStep)
        self.progressBar.currentStep = currentStep
        if totalSteps > 0 then
            self.progressBar.Text:SetText(currentStep .. " / " .. totalSteps)
        else
            self.progressBar.Text:SetText("")
        end
        self:UpdateProgressBarColor(self.progressBar)
    end

    -- A refresh can rebuild the progress bar while the frame is collapsed.
    -- Keep header-owned controls hidden until the user expands the frame.
    if CurrentStepFrame.collapsed then
        self.progressBar:Hide()
    else
        self.progressBar:Show()
    end
end

function APR.currentStep:UpdateProgressBarColor(barOverride)
    local profile = APR:GetSettingsProfile()
    local color = (profile and profile.currentStepProgressBarColor) or
        { APR.Color.blue[1], APR.Color.blue[2], APR.Color.blue[3], 1 }
    local targetBar = barOverride or self.progressBar
    if targetBar then
        if APR.EllesmereUISkin and APR.EllesmereUISkin:ApplyBarFill(targetBar) then return end
        targetBar:SetStatusBarColor(unpack(color))
    end
end

function APR.currentStep:SetProgressBar(CurStep)
    if APR.ActiveRoute then
        if not APRData[APR.PlayerID]
            [APR.ActiveRoute .. '-TotalSteps'] then
            APR:GetTotalSteps()
        end

        -- Calculate the number of skipped steps BEFORE the current step only
        local skippedBeforeCurrent = APR:CountSkippedStepsBefore(APR.ActiveRoute, CurStep)

        local curStepDisplayed = CurStep - skippedBeforeCurrent
        APR.currentStep:ProgressBar(APR.ActiveRoute, APRData[APR.PlayerID]
            [APR.ActiveRoute .. '-TotalSteps'], curStepDisplayed)
    end
end

function APR.currentStep:AddReputationStep(requirement)
    local _, factionID = APR:GetReputationRequirement(requirement)
    local id = "REPUTATION-" .. tostring(factionID or "UNKNOWN")
    self:AddQuestSteps(id, APR:GetReputationStepText(requirement), "Reputation", false, true, false)
    local container = self.questsList[id .. "-Reputation"]
    if not container then return end

    local current, total, text = APR:GetReputationBarProgress(requirement)
    self:AddObjectiveProgressBar(container, "reputationBar", current, total, text)
end

function APR.currentStep:AddLootMoneyStep(rule, cash, resale, required)
    self:AddQuestSteps("LOOT_MONEY", APR:GetLootMoneyStepText(rule), "LootMoney", false, true, false)
    local container = self.questsList["LOOT_MONEY-LootMoney"]
    if not container then return end
    local text = APR:FormatLootMoney(cash) .. " + " .. APR:FormatLootMoney(resale) .. " / " ..
        APR:FormatLootMoney(required)
    self:AddObjectiveProgressBar(container, "lootMoneyBar", math.min(cash + resale, required), required, text)
end

function APR.currentStep:AddObjectiveProgressBar(container, key, current, total, text, replaceText)
    local owner = (replaceText or key == "questProgressBar") and container or self
    local bar = owner[key]
    if not current then
        if bar then bar:Hide() end
        container.extraContentHeight = nil
        self:ReOrderQuestSteps()
        return
    end
    if not bar then
        bar = CreateFrame("StatusBar", nil, container, "BackdropTemplate")
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        bar:SetBackdropColor(0, 0, 0, 0.5)
        bar.Text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        bar.Text:SetPoint("CENTER")
        APR:RegisterFontString(bar.Text, "currentStep", { role = "base" })
        if APR.RegisterSkinTarget then APR:RegisterSkinTarget(bar, "statusbar") end
        owner[key] = bar
    end
    -- Reuse the bar across resource refreshes; its row owns visibility and cleanup.
    bar:SetParent(container)
    bar:ClearAllPoints()
    if replaceText then
        bar:SetPoint("TOPLEFT", container, "TOPLEFT", 16, -5)
        bar:SetPoint("TOPRIGHT", container, "TOPRIGHT", -16, -5)
        container.font:Hide()
        container.progressBarOnly = true
    else
        bar:SetPoint("TOPLEFT", container.font, "BOTTOMLEFT", 0, -5)
        bar:SetPoint("TOPRIGHT", container.font, "BOTTOMRIGHT", 0, -5)
    end
    bar:SetHeight(20)
    self:UpdateProgressBarColor(bar)
    bar:SetMinMaxValues(0, total)
    bar:SetValue(current)
    bar.Text:SetText(text)
    bar:Show()
    container.extraContentHeight = replaceText and 0 or 25
    self:ReOrderQuestSteps()
end

function APR.currentStep:UpdateQuestObjectiveProgressBar(container, questID, objectiveIndex)
    local percent = container.isQuestObjective and APR:GetQuestObjectiveProgressPercent(questID, objectiveIndex)
    if percent then
        self:AddObjectiveProgressBar(container, "questProgressBar", percent, 100, percent .. "%")
    elseif container.questProgressBar then
        container.questProgressBar:Hide()
        container.progressBarOnly = nil
        container.extraContentHeight = nil
        container.font:Show()
        self:ReOrderQuestSteps()
    end
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
    if attribute == "emote" then
        return 6642733 -- random icon for the button (but it's cute)
    elseif attribute == "item" then
        local _, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemID)
        return itemTexture
    elseif attribute == "spell" then
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
    button:SetScript("PreClick", nil)
    button:SetAttribute("type", nil)
    button:SetAttribute("type1", nil)
    button:SetAttribute("item", nil)
    button:SetAttribute("spell", nil)
    button:SetAttribute("macrotext", nil)
    button:SetAttribute("house-neighborhood-guid", nil)
    button:SetAttribute("house-guid", nil)
    button:SetAttribute("house-plot-id", nil)
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        normalTexture:SetTexture(nil)
    end
    local highlightTexture = button:GetHighlightTexture()
    if highlightTexture then
        highlightTexture:SetTexture(nil)
    end
    local pushedTexture = button:GetPushedTexture()
    if pushedTexture then
        pushedTexture:SetTexture(nil)
    end
    button.itemID = nil
    button.attribute = nil
    button.actionUsable = nil
    button.actionReason = nil
    if button.cooldown then
        button.cooldown:Hide()
        button.cooldown:Clear()
    end
    container.IconButton = nil
    if container.RaidIconButton then PositionStepButtons(container, container.RaidIconButton) end
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
    if container.RaidIconButton and container.RaidIconButton.npcID == npcID then
        self.raidIconButton = container.RaidIconButton
        self:UpdateRaidIconButtonMacro()
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
        APR:AddTooltipLine(GameTooltip, "Raid icon (skull)", "currentStep", "accent")
        if npcName then
            APR:AddTooltipLine(GameTooltip, npcName, "currentStep", "base", true)
        else
            APR:AddTooltipLine(GameTooltip, "Mouseover target", "currentStep", "muted", true)
        end
        GameTooltip:Show()
    end)

    RaidIconButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    RaidIconButton.npcID = npcID
    container.RaidIconButton = RaidIconButton
    container.hasSecureControls = true
    if APR.RegisterSkinTarget then
        APR:RegisterSkinTarget(RaidIconButton, "icon", { texture = RaidIconButton:GetNormalTexture() })
    end
    self.raidIconButton = RaidIconButton
    self:UpdateRaidIconButtonMacro()
end

function APR.currentStep:AddRaidIconButton(questsListKey, npcID)
    if not APR.settings.profile.currentStepShow or not npcID then
        return
    end

    local container = GetRaidIconContainer(self, questsListKey)
    if container then container.raidSeen = true end
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

function APR.currentStep:CreateSecureStepButton(questsListKey, itemID, attribute, equipSlot)
    attribute = attribute or "item"
    if attribute == "emote" and (type(itemID) ~= "string" or not itemID:match("^[a-zA-Z]+$")) then return end
    local container = self.questsList[questsListKey] or self.fillersList[questsListKey]
    if not container then
        return
    end

    if container.IconButton and container.IconButton.itemID == itemID and
        container.IconButton.attribute == attribute and container.IconButton.equipSlot == equipSlot and
        attribute ~= "housing" then
        PositionStepButtons(container, container.IconButton)
        if container.RaidIconButton then
            PositionStepButtons(container, container.RaidIconButton, container.IconButton)
        end
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

    local isHousingAction = attribute == "housing" or attribute == "housing_return"
    local farstriderData = attribute == "housing" and APR.farstrider and APR.farstrider:GetData() or nil
    local housingData = attribute == "housing" and farstriderData and
        type(farstriderData.GetHousingData) == "function" and farstriderData.GetHousingData() or nil
    if attribute == "housing" and not housingData then
        return
    end

    local iconTexture = not isHousingAction and GetStepButtonIcon(attribute, itemID) or nil
    if not isHousingAction and not iconTexture then
        return
    end

    local IconButton = CreateFrame("Button", nil, container,
        "SecureActionButtonTemplate, BackdropTemplate")
    IconButton:SetSize(25, 25)
    PositionStepButtons(container, IconButton)
    if isHousingAction then
        IconButton:SetNormalAtlas("dashboard-panel-homestone-teleport-button")
        IconButton:SetHighlightAtlas("dashboard-panel-homestone-teleport-button")
        IconButton:SetPushedAtlas("dashboard-panel-homestone-teleport-button")
    else
        IconButton:SetNormalTexture(iconTexture)
        IconButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    end
    IconButton:RegisterForClicks("AnyUp", "AnyDown")
    if attribute == "item" then
        if equipSlot then
            IconButton:SetAttribute("type1", "macro")
            IconButton:SetAttribute("macrotext", "/equipslot [nocombat] " .. equipSlot .. " item:" .. itemID)
        else
            IconButton:SetAttribute("type1", "item")
            IconButton:SetAttribute("item", "item:" .. tostring(itemID))
        end
    elseif attribute == "emote" then
        IconButton:SetAttribute("type1", "macro")
        IconButton:SetAttribute("macrotext", '/run APR:PerformEmote("' .. itemID .. '")')
    elseif attribute == "spell" then
        IconButton:SetAttribute("type1", "spell")
        IconButton:SetAttribute("spell", tonumber(itemID) or itemID)
    elseif attribute == "housing" then
        IconButton:SetAttribute("type", "teleporthome")
        IconButton:SetAttribute("type1", "teleporthome")
        IconButton:SetAttribute("house-neighborhood-guid", housingData.neighborhoodGUID)
        IconButton:SetAttribute("house-guid", housingData.houseGUID)
        IconButton:SetAttribute("house-plot-id", housingData.plotID)
        IconButton:SetScript("PreClick", function()
            if farstriderData and type(farstriderData.UpdateHousingExitLocation) == "function" then
                farstriderData.UpdateHousingExitLocation()
            end
        end)
    elseif attribute == "housing_return" then
        IconButton:SetAttribute("type", "returnhome")
        IconButton:SetAttribute("type1", "returnhome")
    end

    IconButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        if attribute == "item" then
            GameTooltip:SetItemByID(itemID)

            local targetContext = APR:GetTargetSpellItemContext(itemID)
            if targetContext then
                if targetContext.description and targetContext.description ~= "" then
                    APR:AddTooltipLine(GameTooltip, targetContext.description, "currentStep", "muted", true)
                end
                if not targetContext.matches then
                    APR:AddTooltipLine(GameTooltip, _G.SPELL_FAILED_BAD_TARGETS, "currentStep", "error", true)
                end
            end
        elseif attribute == "spell" then
            GameTooltip:SetSpellByID(itemID)
        elseif container.font then
            APR:AddTooltipLine(GameTooltip, container.font:GetText(), "currentStep", "base", true)
        end

        if self.actionUsable == false then
            local statusText = APR:GetRouteActionStatusText(self.actionReason)
            if statusText then
                APR:AddTooltipLine(GameTooltip, statusText, "currentStep", "error", true)
            end
        end
        GameTooltip:Show()
    end)

    IconButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    IconButton.cooldown = CreateFrame("Cooldown", "$parentCooldown", IconButton, "CooldownFrameTemplate")
    IconButton.cooldown:SetAllPoints()
    IconButton.cooldown:Hide()

    IconButton.itemID = itemID
    IconButton.attribute = attribute
    IconButton.equipSlot = equipSlot
    container.IconButton = IconButton
    container.hasSecureControls = true
    if APR.RegisterSkinTarget then
        APR:RegisterSkinTarget(IconButton, "icon", { texture = IconButton:GetNormalTexture() })
    end

    local actionID = tonumber(itemID) or itemID
    if (attribute == "spell" or attribute == "item") and actionID ~= nil then
        local actionFilter = { [attribute] = { [actionID] = true } }
        self:UpdateStepButtonUsability(actionFilter)
        self:UpdateStepButtonCooldowns(actionFilter)
    end

    -- Reposition raid icon button if it exists (to display both buttons side by side)
    if container.RaidIconButton then
        PositionStepButtons(container, container.RaidIconButton, IconButton)
    end
end

--- Queue or create a secure button depending on combat lockdown state
---@param questsListKey string
---@param itemID number|nil
---@param attribute string
function APR.currentStep:AddStepButton(questsListKey, itemID, attribute, equipSlot)
    if attribute == 'spell' and type(itemID) == 'string' and C_Spell then
        local info = C_Spell.GetSpellInfo(itemID)
        itemID = info and info.spellID or itemID
    end
    if not APR.settings.profile.currentStepShow then
        return
    end

    attribute = attribute or "item"
    local container = self.questsList[questsListKey] or self.fillersList[questsListKey]
    if container then container.actionSeen = true end
    self:MaybeAttachRaidIconButton(questsListKey)
    if InCombatLockdown() then
        self.pendingButtonRequests[questsListKey] = { itemID = itemID, attribute = attribute, equipSlot = equipSlot }
        return
    end

    self.pendingButtonRequests[questsListKey] = nil
    self:CreateSecureStepButton(questsListKey, itemID, attribute, equipSlot)
end

function APR.currentStep:ProcessPendingStepButtons()
    if InCombatLockdown() then
        return
    end

    local needsLayout = next(self.pendingButtonResets) or next(self.pendingButtonRequests) or
        next(self.pendingRaidIconRequests)
    self:ProcessPendingButtonResets()

    for questsListKey, data in pairs(self.pendingButtonRequests) do
        self:CreateSecureStepButton(questsListKey, data.itemID, data.attribute, data.equipSlot)
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
    if needsLayout then
        self:ReOrderQuestSteps()
        if APR.fillersFrame and APR.fillersFrame.FlushPendingLayout then APR.fillersFrame:FlushPendingLayout(true) end
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

local function ShouldUpdateStepButton(IconButton, filter)
    if not filter then
        return true
    end

    local attributeFilter = filter[IconButton.attribute]
    if attributeFilter == true then
        return true
    end
    if type(attributeFilter) ~= "table" then
        return false
    end

    local actionID = tonumber(IconButton.itemID) or IconButton.itemID
    return attributeFilter[actionID] == true
end

local function ClearStepButtonCooldown(IconButton)
    IconButton.cooldown:Clear()
    IconButton.cooldown:Hide()
end

local function UpdateSpellButtonCooldown(IconButton)
    local spellID = tonumber(IconButton.itemID)
    if not spellID or not C_Spell then
        ClearStepButtonCooldown(IconButton)
        return
    end

    -- Duration objects safely carry restricted cooldown timing directly into the widget on every 12.0.x/12.1 client.
    if C_Spell.GetSpellCooldownDuration and IconButton.cooldown.SetCooldownFromDurationObject then
        local duration = C_Spell.GetSpellCooldownDuration(spellID)
        if duration then
            IconButton.cooldown:SetCooldownFromDurationObject(duration, true)
            IconButton.cooldown:Show()
            return
        end
    end

    local cooldownInfo = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellID) or nil
    if not cooldownInfo then
        ClearStepButtonCooldown(IconButton)
        return
    end

    if cooldownInfo.isActive ~= nil then
        -- A restricted cooldown must never fall through to numeric comparisons.
        ClearStepButtonCooldown(IconButton)
        return
    end

    -- Legacy fallback for clients without DurationObject cooldown APIs.
    local startTime, duration = cooldownInfo.startTime, cooldownInfo.duration
    if (APR.CanAccessValue and (not APR:CanAccessValue(startTime) or not APR:CanAccessValue(duration))) or
        type(startTime) ~= "number" or type(duration) ~= "number" then
        ClearStepButtonCooldown(IconButton)
        return
    end

    if cooldownInfo.isEnabled ~= false and startTime > 0 and duration > 0 then
        IconButton.cooldown:SetCooldown(startTime, duration, cooldownInfo.modRate or 1)
        IconButton.cooldown:Show()
    else
        ClearStepButtonCooldown(IconButton)
    end
end

local function UpdateItemButtonCooldown(IconButton)
    local itemID = tonumber(IconButton.itemID)
    local startTime, duration, enabled
    if itemID and C_Item and C_Item.GetItemCooldown then
        startTime, duration, enabled = C_Item.GetItemCooldown(itemID)
    elseif itemID and C_Container and C_Container.GetItemCooldown then
        startTime, duration, enabled = C_Container.GetItemCooldown(itemID)
    end

    local cooldownEnabled = enabled == true or enabled == 1
    if cooldownEnabled and type(startTime) == "number" and startTime > 0 and
        type(duration) == "number" and duration > 0 then
        IconButton.cooldown:SetCooldown(startTime, duration)
        IconButton.cooldown:Show()
    else
        ClearStepButtonCooldown(IconButton)
    end
end

--- Refresh the secure action buttons from dedicated cooldown events.
---@param filter table|nil A map such as { spell = true } or { item = { [itemID] = true } }.
function APR.currentStep:UpdateStepButtonCooldowns(filter)
    local function updateContainerList(list)
        for _, container in pairs(list) do
            -- Ignore soft-hidden containers (during combat)
            if container and not container.hiddenInCombat then
                local IconButton = container.IconButton
                if IconButton and ShouldUpdateStepButton(IconButton, filter) then
                    if not IconButton:IsShown() then
                        ClearStepButtonCooldown(IconButton)
                    elseif IconButton.attribute == "spell" then
                        UpdateSpellButtonCooldown(IconButton)
                    elseif IconButton.attribute == "item" then
                        UpdateItemButtonCooldown(IconButton)
                    else
                        ClearStepButtonCooldown(IconButton)
                    end
                end
            end
        end
    end

    updateContainerList(self.questsList)
    updateContainerList(self.fillersList)
end

--- Refresh visual availability without changing protected secure-action attributes.
---@param filter table|nil
function APR.currentStep:UpdateStepButtonUsability(filter)
    local function updateContainerList(list)
        for _, container in pairs(list) do
            local IconButton = container and container.IconButton or nil
            if IconButton and not container.hiddenInCombat and ShouldUpdateStepButton(IconButton, filter) then
                local actionType = IconButton.attribute
                local isAction = actionType == "spell" or actionType == "item"
                local usable, reason = true, nil
                if isAction then
                    usable, reason = APR:GetRouteActionUsability(actionType, IconButton.itemID, true)
                end

                IconButton.actionUsable = usable
                IconButton.actionReason = reason

                local normalTexture = IconButton:GetNormalTexture()
                if normalTexture and normalTexture.SetDesaturated and isAction then
                    normalTexture:SetDesaturated(not usable)
                    if normalTexture.SetVertexColor then
                        if usable then
                            normalTexture:SetVertexColor(1, 1, 1, 1)
                        else
                            normalTexture:SetVertexColor(0.55, 0.55, 0.55, 1)
                        end
                    end
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
    if self.contentUpdateActive then
        self.pendingRaidIconNpcId = nil
        self.raidIconAdded = false
        self:ButtonShow()
        self:ButtonDisable()
        self:RemoveQuestStepsAndExtraLineTexts()
        APR.fillersFrame:RemoveFillerSteps()
        return
    end
    self:ButtonShow()
    self:ButtonDisable()
    self:ProgressBar()

    if InCombatLockdown() then
        -- In combat: don't wipe secure button references.
        -- Mark containers for soft-hide via RemoveQuestStepsAndExtraLineTexts,
        -- and schedule a full reset after combat ends.
        self._pendingFullReset = true
        self:RemoveQuestStepsAndExtraLineTexts()
        APR.fillersFrame:RemoveFillerSteps()
        return
    end

    self._pendingFullReset = false
    self.pendingRaidIconNpcId = nil
    self.raidIconAdded = false
    self.pendingRaidIconRequests = {}
    self.pendingButtonResets = {}
    self.pendingContainerDestroy = {}
    self.pendingRaidIconMacroRefresh = false
    self.raidIconButton = nil
    self:RemoveQuestStepsAndExtraLineTexts()
    APR.fillersFrame:RemoveFillerSteps()
end

function APR.GetMenu(owner, rootDescription)
    local toggleAddon = ''
    if APR.settings.profile.enableAddon then
        toggleAddon = APR:WrapTextWithAppearanceColor(" " .. L["DISABLE"], "general", "error")
    else
        toggleAddon = APR:WrapTextWithAppearanceColor(" " .. L["ENABLE"], "general", "success")
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

    local function sectionTitle(text)
        return APR:WrapTextWithAppearanceColor(text, "currentStep", "accent")
    end

    rootDescription:CreateTitle(sectionTitle(APR.title))

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
    rootDescription:CreateTitle(sectionTitle(L["CURRENT_STEP"]))

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
    rootDescription:CreateTitle(sectionTitle(L["FILLERS_FRAME"]))

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
    rootDescription:CreateTitle(sectionTitle(L["QUEST_ORDER_LIST"]))

    createToggleItem(L["SNAP_TO_CURRENT_STEP"], function()
        return APR.settings.profile.questOrderListSnapToCurrentStep
    end, function()
        APR.settings.profile.questOrderListSnapToCurrentStep = not APR.settings.profile.questOrderListSnapToCurrentStep
        APR.questOrderList:RefreshFrameAnchor()
    end)

    createToggleItem(L["SHOW_QORDERLIST"], function()
        return APR.settings.profile.showQuestOrderList
    end, function()
        APR.settings.profile.showQuestOrderList = not APR.settings.profile.showQuestOrderList
        APR.questOrderList:RefreshFrameAnchor()
    end)



    rootDescription:CreateDivider()
    rootDescription:CreateTitle(sectionTitle(L["AFK"]))

    createToggleItem(L["SNAP_TO_CURRENT_STEP"], function()
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
    -- Retired secure children still belong to their row. Remember this even
    -- after the active button reference is cleared so reused rows stay safe.
    return not InCombatLockdown() or not (container.hasSecureControls or
        (container.IconButton and container.IconButton:IsProtected()) or
        (container.RaidIconButton and container.RaidIconButton:IsProtected()))
end

function APR.currentStep:SoftHide(container)
    container.hiddenInCombat = true
    container:SetAlpha(0.001)
    -- Strip tooltip scripts to prevent ghost tooltips (safe in combat)
    container:SetScript("OnEnter", nil)
    container:SetScript("OnLeave", nil)
    -- EnableMouse is protected on secure frames; only call outside combat
    if not InCombatLockdown() then
        container:EnableMouse(false)
    end
    if container.IconButton then
        container.IconButton:SetScript("OnEnter", nil)
        container.IconButton:SetScript("OnLeave", nil)
        if not InCombatLockdown() then
            container.IconButton:EnableMouse(false)
        end
    end
    if container.RaidIconButton then
        container.RaidIconButton:SetScript("OnEnter", nil)
        container.RaidIconButton:SetScript("OnLeave", nil)
        if not InCombatLockdown() then
            container.RaidIconButton:EnableMouse(false)
        end
    end
end

function APR.currentStep:FlushPendingContainers()
    -- Flush orphaned containers (replaced during combat)
    for _, container in ipairs(self.pendingContainerDestroy) do
        if container then
            container.hiddenInCombat = nil
            container:SetAlpha(1)
            container:EnableMouse(true)
            container:SetScript("OnEnter", nil)
            container:SetScript("OnLeave", nil)
            container:ClearAllPoints()
            container:Hide()
            if container.IconButton then
                self:ResetSecureStepButton(container, nil, true)
            end
            if container.RaidIconButton then
                self:ResetSecureRaidIconButton(container, nil, true)
            end
        end
    end
    wipe(self.pendingContainerDestroy)

    if not next(self.pendingRemoval) then
        if self.layoutDirty then self:ReOrderQuestSteps() end
        if APR.fillersFrame and APR.fillersFrame.FlushPendingLayout then APR.fillersFrame:FlushPendingLayout() end
        return
    end
    for id, _ in pairs(self.pendingRemoval) do
        local container = self.questsList[id] or self.questsExtraTextList[id] or self.fillersList[id]
        if container then
            container.hiddenInCombat = nil
            container:SetAlpha(1)
            container:EnableMouse(true)
            container:SetScript("OnEnter", nil)
            container:SetScript("OnLeave", nil)
            container:ClearAllPoints()
            container:Hide()
            if container.IconButton then
                self:ResetSecureStepButton(container, id, true)
            end
            if container.RaidIconButton then
                self:ResetSecureRaidIconButton(container, id, true)
            end
        end
        self.questsList[id] = nil
        self.questsExtraTextList[id] = nil
        self.fillersList[id] = nil
    end
    wipe(self.pendingRemoval)
    self:ReOrderQuestSteps(true)
    if APR.fillersFrame then
        APR.fillersFrame:ReOrderFillerSteps()
    end
end

function APR.currentStep:GetCurrentStepDetails()
    if not APR.ActiveRoute then return nil end
    local playerData = APRData and APRData[APR.PlayerID] or {}
    local currentIndex = playerData[APR.ActiveRoute]
    local progressBar = self.progressBar
    local displayedStep
    if progressBar and progressBar.key == APR.ActiveRoute and type(progressBar.currentStep) == "number" then
        displayedStep = progressBar.currentStep
    elseif type(currentIndex) == "number" then
        displayedStep = currentIndex - APR:CountSkippedStepsBefore(APR.ActiveRoute, currentIndex)
    end

    local stepDetails = {
        extraLines = {},
        questSteps = {},
        fillerSteps = {},
        progress = {
            index = currentIndex,
            step = displayedStep,
            total = playerData[APR.ActiveRoute .. '-TotalSteps'],
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
