local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR fillers frame module
APR.fillersFrame = APR:NewModule("FillersFrame")

-- Local constants
local FRAME_WIDTH = 250
-- Distance from top where content starts (header offset)
local FRAME_HEADER_OFFSET = -30
local FRAME_FILLERS_HOLDER_HEIGHT = FRAME_HEADER_OFFSET
-- Height of the collapse/expand header section
local HEADER_HEIGHT = 22
-- Small padding before first filler item
local FIRST_ITEM_OFFSET = -5
-- Throttle time for frame refresh (milliseconds)
local REFRESH_THROTTLE = 0.1

-- Track last refresh time to prevent excessive updates
local lastRefreshTime = 0


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
    return not shouldAllowDrag
end, function()
    LibWindow.SavePosition(FillersFrame)
end)

-- Create the step holder frame for fillers
local FillersFrame_StepHolder = CreateFrame("Frame", "FillersFrame_StepHolder", FillersFrame,
    "BackdropTemplate")
FillersFrame_StepHolder:SetAllPoints()

-- Create the fillers header
local FillersFrameHeader = APR:CreateFrameHeader("FillersFrameHeader", FillersFrame, L["STEP_FILLERS"])

-- Setup drag and drop for the header
APR:SetupHeaderDrag(FillersFrameHeader, FillersFrame, function()
    local profile = APR:GetSettingsProfile()

    -- Defensive nil check: settings may not be initialized yet
    local shouldAllowDrag = profile and profile.fillersFrameSnapToCurrentStep
    return not shouldAllowDrag
end, function()
    LibWindow.SavePosition(FillersFrame)
end)

-- Setup minimize button for Fillers frame
APR:SetupMinimizeButton(FillersFrameHeader, FillersFrame, function()
    -- Collapse
    FillersFrame_StepHolder:Hide()
    APR.fillersFrame:UpdateBackgroundColorAlpha({ 0, 0, 0, 0 })
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
    FillersFrame_StepHolder:Show()
    FillersFrameHeader:Show()
    self:UpdateBackgroundColorAlpha()
end

-- Update the frame scale
function APR.fillersFrame:UpdateFrameScale()
    LibWindow.SetScale(FillersFrame, APR.settings.profile.currentStepScale)
end

-- Helper function to destroy a filler container and clean up references
---@param container Frame The container frame to destroy
local function DestroyFillerContainer(container)
    if not container then return end

    -- Hide and clear positioning
    container:Hide()
    container:ClearAllPoints()

    -- Remove all scripts to prevent callback leaks
    container:SetScript("OnEnter", nil)
    container:SetScript("OnLeave", nil)
    container:SetScript("OnUpdate", nil)

    -- Clear all references to break circular references
    container.font = nil
    container.questID = nil
    container.hiddenInCombat = nil

    -- Note: We don't call :Destroy() as it doesn't exist on WoW frames
    -- The frame will be garbage collected when all references are cleared
end

-- Helper function to create step frames
local function AddStepsFrame(questDesc, extraLineText, color)
    local text = extraLineText or questDesc
    return APR:CreateStepTextContainer(FillersFrame_StepHolder, FRAME_WIDTH, text, extraLineText ~= nil, color, nil)
end

-- Add a filler step
function APR.fillersFrame:AddFillerStep(questID, textObjective, objectiveIndex)
    APR:Debug("Function: APR.fillersFrame:AddFillerStep()", questID)
    if not APR.settings.profile.currentStepShow then
        return
    end

    -- Check if fillersList is empty to reset to the default height
    if not next(APR.currentStep.fillersList) then
        FRAME_FILLERS_HOLDER_HEIGHT = FIRST_ITEM_OFFSET
    end

    local questKey = questID .. "-" .. (objectiveIndex or 0)
    local existingContainer = APR.currentStep.fillersList[questKey]

    -- Remove if it already exists
    if existingContainer then
        if APR.currentStep:CanSafelyHide(existingContainer) then
            DestroyFillerContainer(existingContainer)
            APR.currentStep:ResetSecureStepButton(existingContainer, questKey)
            APR.currentStep:ResetSecureRaidIconButton(existingContainer, questKey)
        else
            APR.currentStep:SoftHide(existingContainer)
            table.insert(APR.currentStep.pendingContainerDestroy, existingContainer)
        end
        APR.currentStep.fillersList[questKey] = nil
    end

    local objectiveContainer = AddStepsFrame(textObjective)
    objectiveContainer:SetPoint("TOPLEFT", FillersFrame_StepHolder, "TOPLEFT", 0, FRAME_FILLERS_HOLDER_HEIGHT)
    objectiveContainer.questID = questID

    -- Add tooltip
    objectiveContainer:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(L["QUEST_INFO"])

        local questIDText = (questID ~= nil) and tostring(questID) or "?"
        local questIDNum = tonumber(questIDText)

        GameTooltip:AddLine("|c33ecc00f" .. ID .. ": |r" .. questIDText, unpack(APR.Color.white))

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

        local isCampaign = questIDNum and APR:IsCampaignQuest(questIDNum)
        if isCampaign then
            GameTooltip:AddLine(
                "|c33ecc00f" .. L["CAMPAIGN"] .. "|r: " ..
                (isCampaign and APR:WrapTextInColorCode(YES, "00ff00") or
                    APR:WrapTextInColorCode(NO, "cce0000f")),
                unpack(APR.Color.white)
            )
        end

        GameTooltip:Show()
    end)

    objectiveContainer:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    APR.currentStep.fillersList[questKey] = objectiveContainer
    APR.currentStep:MaybeAttachRaidIconButton(questKey)
    FRAME_FILLERS_HOLDER_HEIGHT = FRAME_FILLERS_HOLDER_HEIGHT - objectiveContainer:GetHeight()

    self:ReOrderFillerSteps()
    -- Note: ReOrderFillerSteps() already calls RefreshFillersFrame(true)
end

-- Update a filler step (called when quest objective progress changes)
function APR.fillersFrame:UpdateFillerStep(questID, textObjective, objectiveIndex)
    APR:Debug("Function: APR.fillersFrame:UpdateFillerStep()", questID)
    if not APR.settings.profile.currentStepShow then
        return
    end

    local questKey = questID .. "-" .. (objectiveIndex or 0)
    local existingContainer = APR.currentStep.fillersList[questKey]

    if existingContainer then
        existingContainer.font:SetText('- ' .. textObjective)
        -- Update container height if text height changed
        local newHeight = existingContainer.font:GetStringHeight() + 10
        if existingContainer:GetHeight() ~= newHeight then
            existingContainer:SetHeight(newHeight)
            self:ReOrderFillerSteps()
        end
    end
end

-- Reorder filler steps
function APR.fillersFrame:ReOrderFillerSteps()
    APR:Debug("Function: APR.fillersFrame:ReOrderFillerSteps()")
    if not APR.settings.profile.currentStepShow then return end

    FRAME_FILLERS_HOLDER_HEIGHT = FIRST_ITEM_OFFSET
    for id, container in pairs(APR.currentStep.fillersList) do
        if not container.hiddenInCombat then
            container:ClearAllPoints()
            container:SetPoint("TOPLEFT", FillersFrame_StepHolder, "TOPLEFT", 0, FRAME_FILLERS_HOLDER_HEIGHT)
            FRAME_FILLERS_HOLDER_HEIGHT = FRAME_FILLERS_HOLDER_HEIGHT - container:GetHeight()
        end
    end

    self:RefreshFillersFrame(true) -- Force refresh after reordering
end

-- Remove all filler steps
function APR.fillersFrame:RemoveFillerSteps()
    APR:Debug("Function: APR.fillersFrame:RemoveFillerSteps()")
    if not APR.settings.profile.currentStepShow then return end

    for id, container in pairs(APR.currentStep.fillersList) do
        local canHide = APR.currentStep:CanSafelyHide(container)
        if canHide then
            -- Properly destroy the container to prevent memory leaks
            DestroyFillerContainer(container)
            APR.currentStep:ResetSecureStepButton(container, id)
            APR.currentStep.pendingButtonRequests[id] = nil
            APR.currentStep:ResetSecureRaidIconButton(container, id)
            APR.currentStep.pendingRaidIconRequests[id] = nil
            APR.currentStep.fillersList[id] = nil
        else
            APR.currentStep:SoftHide(container)
            APR.currentStep.pendingRemoval[id] = true
        end
    end

    if not InCombatLockdown() then
        APR.currentStep.fillersList = {}
    end

    FRAME_FILLERS_HOLDER_HEIGHT = FIRST_ITEM_OFFSET
    self:RefreshFillersFrame(true) -- Force refresh to immediately hide frame

    -- Refresh QuestOrderList when Fillers disappears
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
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

-- Refresh the fillers frame visibility and positioning
-- @param forceRefresh boolean Skip throttle and force immediate refresh
function APR.fillersFrame:RefreshFillersFrame(forceRefresh)
    -- Use ShouldHideFrames from Core for consistent frame hiding logic
    if APR:ShouldHideFrames() then
        FillersFrame:Hide()
        -- If Fillers just disappeared, refresh QuestOrderList
        if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
            APR.questOrderList:ApplySnapAnchor()
        end
        return
    end

    -- Throttle refresh to prevent excessive updates (unless forced)
    if not forceRefresh then
        local now = GetTime()
        -- Initialize on first call
        if lastRefreshTime == 0 then
            lastRefreshTime = now
        end
        -- Skip if throttled
        if now - lastRefreshTime < REFRESH_THROTTLE then
            return
        end
        lastRefreshTime = now
    end

    -- Show or hide the fillers frame based on whether there are any visible fillers
    local wasVisible = FillersFrame:IsShown()
    if HasActiveFillers() then
        FillersFrame:Show()

        -- Check snap settings
        local isSnapped = APR.settings.profile.fillersFrameSnapToCurrentStep
        local snapGap = APR.settings.profile.fillersFrameSnapGap or 0

        -- Header visibility logic
        local showHeader
        if isSnapped then
            showHeader = APR.settings.profile.fillersFrameShowHeader
        else
            showHeader = true -- Mandatory when not snapped
        end

        -- Show/hide header
        if showHeader then
            FillersFrameHeader:Show()
            FillersFrameHeader:ClearAllPoints()
            FillersFrameHeader:SetPoint("BOTTOM", FillersFrame, "TOP", 0, -3)
        else
            FillersFrameHeader:Hide()
        end

        -- Show/hide minimize button based on snap settings
        if isSnapped then
            FillersFrameHeader.MinimizeButton:Hide()
        else
            FillersFrameHeader.MinimizeButton:Show()
        end

        -- Enable/disable mouse based on snap settings
        FillersFrame:EnableMouse(not isSnapped)

        -- Calculate total height needed
        local titleHeight = 0
        local contentHeight = math.abs(FRAME_FILLERS_HOLDER_HEIGHT - FIRST_ITEM_OFFSET)
        local totalHeight = titleHeight + contentHeight + 10

        FillersFrame:SetSize(FRAME_WIDTH, totalHeight)

        -- Adjust StepHolder position
        FillersFrame_StepHolder:ClearAllPoints()
        FillersFrame_StepHolder:SetPoint("TOPLEFT", FillersFrame, "TOPLEFT", 0, 0)
        FillersFrame_StepHolder:SetPoint("BOTTOMRIGHT", FillersFrame, "BOTTOMRIGHT", 0, 0)

        -- Position relative to anchor frame using centralized logic
        FillersFrame:ClearAllPoints()

        if isSnapped then
            -- Use centralized anchor logic from Core
            local anchorFrame, anchorHeight = APR:GetSnapAnchorFrame(true) -- excludeFillers=true to avoid self-anchoring

            if anchorFrame then
                -- Use centralized snap positioning helper
                local headerAdjust = showHeader and HEADER_HEIGHT or nil
                APR:SnapFrameToAnchor(FillersFrame, anchorFrame, anchorHeight, snapGap, headerAdjust)

                -- Update backdrop color to match current step
                self:UpdateBackgroundColorAlpha()
            end
        else
            -- Not snapped - allow independent positioning
            -- Restore position if available
            if APR.settings.profile.fillersFrame and APR.settings.profile.fillersFrame.point then
                LibWindow.RestorePosition(FillersFrame)
            else
                -- Default position when not snapped and no saved position
                FillersFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
            end

            -- Update backdrop color
            self:UpdateBackgroundColorAlpha()
        end

        -- If Fillers just appeared, refresh QuestOrderList
        if not wasVisible then
            if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
                APR.questOrderList:ApplySnapAnchor()
            end
        end
    else
        FillersFrame:Hide()

        -- If Fillers just disappeared, refresh QuestOrderList
        if wasVisible then
            if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
                APR.questOrderList:ApplySnapAnchor()
            end
        end
    end

    -- Update positioning of AFK and QuestOrderList
    if APR.AFK and APR.AFK.RefreshFrameAnchor then
        APR.AFK:RefreshFrameAnchor()
    end
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

-- Hide the fillers frame (used when collapsing)
function APR.fillersFrame:Hide()
    if FillersFrame then
        FillersFrame:Hide()
    end
    if FillersFrameHeader then
        FillersFrameHeader:Hide()
    end

    -- When Fillers hides, refresh QuestOrderList
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
end

-- Show the fillers frame (used when expanding)
function APR.fillersFrame:Show()
    self:RefreshFillersFrame(true) -- Force refresh when explicitly showing
end

-- Reset the frame position
function APR.fillersFrame:ResetPosition()
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
