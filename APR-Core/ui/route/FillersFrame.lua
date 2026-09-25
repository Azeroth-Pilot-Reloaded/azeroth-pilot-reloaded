local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR fillers frame module
APR.fillersFrame = APR:NewModule("FillersFrame")

local FRAME_WIDTH = APR.currentStep.layout.width
local TEXT_PADDING = APR.currentStep.layout.padding
local HEADER_HEIGHT, CONTENT_PADDING = 22, 5

---------------------------------------------------------------------------------------
----------------------------------- Fillers Frame -------------------------------------
---------------------------------------------------------------------------------------

-- Create the Fillers frame
local FillersFrame = APR:CreateStandardFrame("FillersScreenPanel", UIParent, FRAME_WIDTH, 30, "BackdropTemplate")
FillersFrame:Hide()

-- Setup drag and drop for the frame
APR:SetupFrameDrag(FillersFrame, function()
    -- Defensive nil check: settings may not be initialized yet
    local profile = APR:GetSettingsProfile()
    local shouldAllowDrag = profile and profile.fillersFrameSnapToCurrentStep
    return not InCombatLockdown() and not shouldAllowDrag
end, function()
    LibWindow.SavePosition(FillersFrame)
end)

-- Create the step holder frame for fillers
local FillersFrame_StepHolder = CreateFrame("Frame", "FillersFrame_StepHolder", FillersFrame,
    "BackdropTemplate")
FillersFrame_StepHolder:SetAllPoints()

-- Create the fillers header
local FillersFrameHeader = APR:CreateFrameHeader("FillersFrameHeader", FillersFrame, L["STEP_FILLERS"], nil,
    "fillers")

-- Setup drag and drop for the header
APR:SetupHeaderDrag(FillersFrameHeader, FillersFrame, function()
    local profile = APR:GetSettingsProfile()

    -- Defensive nil check: settings may not be initialized yet
    local shouldAllowDrag = profile and profile.fillersFrameSnapToCurrentStep
    return not InCombatLockdown() and not shouldAllowDrag
end, function()
    LibWindow.SavePosition(FillersFrame)
end)

-- Setup minimize button for Fillers frame
APR:SetupMinimizeButton(FillersFrameHeader, FillersFrame, function()
    -- Collapse
    FillersFrame.collapsed = true
    APR.fillersFrame:RefreshFillersFrame(true)
end, function()
    -- Expand
    APR.fillersFrame:SetDefaultDisplay()
end)

---------------------------------------------------------------------------------------
---------------------------------- Fillers Methods ------------------------------------
---------------------------------------------------------------------------------------

function APR.fillersFrame:OnInit()
    LibWindow.RegisterConfig(FillersFrame, APR.settings.profile.fillersFrame)
    FillersFrame.RegisteredForLibWindow = true

    -- Set default display
    self:SetDefaultDisplay()

    if (not APR.settings.profile.currentStepAttachFrameToQuestLog) then
        LibWindow.RestorePosition(FillersFrame)
        FillersFrame:EnableMouse(true)
    end

    self:UpdateFrameScale()
    self:RefreshFillersFrame(true) -- Force refresh on init
end

function APR.fillersFrame:SetDefaultDisplay()
    FillersFrame.collapsed = false
    self:RefreshFillersFrame(true)
end

-- Update the frame scale
function APR.fillersFrame:UpdateFrameScale()
    if InCombatLockdown() then self.pendingRefresh = true; return end
    LibWindow.SetScale(FillersFrame, APR.settings.profile.currentStepScale)
end

-- Content shares the current-step transaction, so Reset/Add calls never hide
-- an unchanged panel between two update passes.
local function MeasureRow(container)
    local height = container.font:GetStringHeight() + 10
    if container.IconButton or container.RaidIconButton then height = math.max(height, 30) end
    if container:GetHeight() ~= height then
        if APR.currentStep:CanSafelyHide(container) then
            container:SetHeight(height)
        else
            APR.fillersFrame.layoutDirty = true
        end
    end
end

local function ShowQuestTooltip(container)
    GameTooltip:SetOwner(container, "ANCHOR_BOTTOM")
    APR:AddQuestTooltipDetails(GameTooltip, container.questID, {
        objectiveIndex = container.objectiveIndex,
        objectiveText = container.objectiveText,
        includeCampaign = true,
        includeStoryline = true,
    })
    GameTooltip:Show()
end

local function HideTooltip() GameTooltip:Hide() end

function APR.fillersFrame:AddFillerStep(questID, text, objectiveIndex)
    if not APR.settings.profile.currentStepShow then return end
    local currentStep = APR.currentStep
    local key = questID .. "-" .. (objectiveIndex or 0)
    local container = currentStep.fillersList[key]
    if container and container.hiddenInCombat then
        currentStep:ReleaseRow(currentStep.fillersList, key)
        container = nil
    end
    if not container then
        container = APR:CreateStepTextContainer(FillersFrame_StepHolder, FRAME_WIDTH, text, false,
            nil, nil, true, "fillers")
        container.font:ClearAllPoints()
        container.font:SetPoint("TOPLEFT", TEXT_PADDING, -5)
        container.font:SetWidth(FRAME_WIDTH - TEXT_PADDING * 2)
        APR:RegisterFontString(container.font, "fillers", {
            role = "base", onApplied = function() MeasureRow(container) end,
        })
        container:SetScript("OnEnter", ShowQuestTooltip)
        container:SetScript("OnLeave", HideTooltip)
        currentStep.fillersList[key] = container
    end
    currentStep:TouchRow(container)
    container.questID, container.objectiveIndex, container.objectiveText = questID, objectiveIndex, text
    if container.font:GetText() ~= "- " .. text then container.font:SetText("- " .. text) end
    currentStep:MaybeAttachRaidIconButton(key)
    self:ReOrderFillerSteps()
end

function APR.fillersFrame:UpdateFillerStep(questID, text, objectiveIndex)
    local container = APR.currentStep.fillersList[questID .. "-" .. (objectiveIndex or 0)]
    if not container or not APR.settings.profile.currentStepShow then return end
    container.objectiveText = text
    if container.font:GetText() ~= "- " .. text then
        container.font:SetText("- " .. text)
        self:ReOrderFillerSteps()
    end
end

function APR.fillersFrame:ReOrderFillerSteps()
    self.layoutDirty = true
    if APR.currentStep.contentUpdateActive then return end
    self.layoutDirty = false
    local keys = {}
    for key, container in pairs(APR.currentStep.fillersList) do
        if not container.hiddenInCombat then keys[#keys + 1] = key end
    end
    -- Quest then objective order is stable even when the quest log uses pairs().
    table.sort(keys, function(a, b)
        local left, right = APR.currentStep.fillersList[a], APR.currentStep.fillersList[b]
        local leftID, rightID = tonumber(left.questID), tonumber(right.questID)
        if leftID and rightID and leftID ~= rightID then return leftID < rightID end
        if tostring(left.questID) ~= tostring(right.questID) then return tostring(left.questID) < tostring(right.questID) end
        local leftIndex, rightIndex = tonumber(left.objectiveIndex) or 0, tonumber(right.objectiveIndex) or 0
        if leftIndex ~= rightIndex then return leftIndex < rightIndex end
        return tostring(a) < tostring(b)
    end)
    local offset = CONTENT_PADDING
    for _, key in ipairs(keys) do
        local container = APR.currentStep.fillersList[key]
        MeasureRow(container)
        if container.layoutOffset ~= offset then
            if APR.currentStep:CanSafelyHide(container) then
                container:ClearAllPoints()
                container:SetPoint("TOPLEFT", FillersFrame_StepHolder, "TOPLEFT", 0, -offset)
                container.layoutOffset = offset
            else
                self.layoutDirty = true
            end
        end
        offset = offset + container:GetHeight()
    end
    self.contentHeight = offset + CONTENT_PADDING
    self:RefreshFillersFrame(true)
end

function APR.fillersFrame:RefreshTextLayout() self:ReOrderFillerSteps() end

function APR.fillersFrame:FlushPendingLayout(force)
    if InCombatLockdown() then self:RefreshFillersFrame(true); return end
    if self.pendingPositionReset then
        self.pendingPositionReset = nil
        self:ResetPosition()
    end
    if force or self.layoutDirty then
        self:ReOrderFillerSteps()
    elseif self.pendingRefresh then
        self:RefreshFillersFrame(true)
    end
end

function APR.fillersFrame:RemoveFillerSteps()
    local currentStep = APR.currentStep
    for key, container in pairs(currentStep.fillersList) do
        if currentStep.contentUpdateActive then
            container.stale, container.refreshActions = true, true
            container.actionSeen, container.raidSeen = nil, nil
        else
            currentStep:ReleaseRow(currentStep.fillersList, key)
        end
    end
    self:ReOrderFillerSteps()
end

-- Check if any filler container should be shown
local function HasActiveFillers()
    for _, container in pairs(APR.currentStep.fillersList) do
        if container and not container.hiddenInCombat then
            return true
        end
    end
    return false
end

local function SetShown(frame, shown)
    if shown and not frame:IsShown() then frame:Show()
    elseif not shown and frame:IsShown() then frame:Hide() end
end

-- Apply only the final geometry. Combat work is replayed from the current state
-- after PLAYER_REGEN_ENABLED; no timer or per-frame polling is needed.
function APR.fillersFrame:RefreshFillersFrame(forceRefresh)
    if APR.currentStep.contentUpdateActive then self.pendingRefresh = true; return end
    local profile = APR:GetSettingsProfile()
    if not profile then return end
    local visible = not APR:ShouldHideFrames() and not self.hiddenByCurrentStep and HasActiveFillers()
    local snapped = profile.fillersFrameSnapToCurrentStep
    local collapsed = FillersFrame.collapsed and not snapped
    FillersFrame_StepHolder:SetAlpha(collapsed and 0 or 1)
    if InCombatLockdown() then
        self.pendingRefresh = true
        FillersFrame:SetAlpha(visible and 1 or 0)
        return
    end
    self.pendingRefresh = false
    FillersFrame:SetAlpha(1)
    SetShown(FillersFrame, visible)
    if visible then
        local showHeader = not snapped or profile.fillersFrameShowHeader
        SetShown(FillersFrameHeader, showHeader)
        SetShown(FillersFrameHeader.MinimizeButton, not snapped)
        SetShown(FillersFrame_StepHolder, not collapsed)
        FillersFrame:EnableMouse(not snapped)
        local height = collapsed and 1 or (self.contentHeight or CONTENT_PADDING * 2)
        if FillersFrame:GetHeight() ~= height then FillersFrame:SetHeight(height) end
        FillersFrameHeader:SetPoint("BOTTOM", FillersFrame, "TOP", 0, -3)
        if snapped then
            local anchor, anchorHeight = APR:GetSnapAnchorFrame(true)
            if anchor then
                local gap = profile.fillersFrameSnapGap or 0
                local scale = anchor:GetScale() or 1
                if self.anchor ~= anchor or self.anchorHeight ~= anchorHeight or self.anchorGap ~= gap or
                    self.anchorHeader ~= showHeader or FillersFrame:GetScale() ~= scale then
                    APR:SnapFrameToAnchor(FillersFrame, anchor, anchorHeight, gap, showHeader and HEADER_HEIGHT or nil)
                    self.anchor, self.anchorHeight, self.anchorGap, self.anchorHeader = anchor, anchorHeight, gap, showHeader
                end
            end
        else
            if self.wasSnapped ~= false then
                if profile.fillersFrame and profile.fillersFrame.point then
                    LibWindow.RestorePosition(FillersFrame)
                else
                    FillersFrame:ClearAllPoints()
                    FillersFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                end
                self:UpdateFrameScale()
            end
            self.anchor = nil
        end
        self.wasSnapped = snapped and true or false
        self:UpdateBackgroundColorAlpha(collapsed and { 0, 0, 0, 0 } or nil)
    end
    if APR.AFK and APR.AFK.RefreshFrameAnchor then APR.AFK:RefreshFrameAnchor() end
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then APR.questOrderList:ApplySnapAnchor() end
end

-- Get the total height of fillers frame (for positioning)
function APR.fillersFrame:GetFillersHeight()
    if not FillersFrame or not FillersFrame:IsShown() then
        return 0
    end
    return FillersFrame:GetHeight() or 0
end

-- Update background color of fillers frame
function APR.fillersFrame:UpdateBackgroundColorAlpha(color)
    local rgba = color or APR.settings.profile.currentStepbackgroundColorAlpha

    -- Update Fillers frame background
    if FillersFrame then
        FillersFrame:SetBackdropColor(unpack(rgba))
    end
end

function APR.fillersFrame:Hide()
    self.hiddenByCurrentStep = true
    self:RefreshFillersFrame(true)
end

function APR.fillersFrame:Show()
    self.hiddenByCurrentStep = false
    self:RefreshFillersFrame(true)
end

-- Reset the frame position
function APR.fillersFrame:ResetPosition()
    if InCombatLockdown() then self.pendingPositionReset = true; return end
    self.anchor = nil
    if APR.settings.profile.fillersFrameSnapToCurrentStep then
        -- If snapped, just refresh to re-snap
        self:RefreshFillersFrame(true) -- Force refresh on position reset
    else
        -- Clear saved position
        APR.settings.profile.fillersFrame = {}

        -- Set default position (below current step frame or AFK frame)
        FillersFrame:ClearAllPoints()
        local currentStepPanel = _G.CurrentStepScreenPanel
        if currentStepPanel then
            local anchorFrame = currentStepPanel
            local anchorHeight = APR.currentStep:GetContentHeight(false) or currentStepPanel:GetHeight()

            -- Check if AFK frame is visible, active, and snapped
            local afkFrame = _G.AfkFrameScreen
            local isAfkActive = APR.AFK and (APR.AFK.fakeTimerActive == true)
            local isAfkSnapped = APR.settings.profile.afkSnapToCurrentStep
            if afkFrame and afkFrame:IsShown() and isAfkActive and isAfkSnapped then
                anchorFrame = afkFrame
                anchorHeight = afkFrame:GetHeight()
            end

            FillersFrame:SetScale(anchorFrame:GetScale() or 1)
            FillersFrame:SetPoint("TOP", anchorFrame, "TOP", 0, -(anchorHeight + 30))
        else
            FillersFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        end

        -- Save the new position
        LibWindow.SavePosition(FillersFrame)
    end
end

-- Export frames for external access
APR.fillersFrame.Frame = FillersFrame
APR.fillersFrame.FrameHeader = FillersFrameHeader
APR.fillersFrame.StepHolder = FillersFrame_StepHolder
