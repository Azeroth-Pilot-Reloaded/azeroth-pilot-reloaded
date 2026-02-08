local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Initialize APR fillers frame module
APR.fillersFrame = APR:NewModule("FillersFrame")

-- Local constants
local FRAME_WIDTH = 250
local FRAME_FILLERS_HOLDER_HEIGHT = 0

---------------------------------------------------------------------------------------
----------------------------------- Fillers Frame -------------------------------------
---------------------------------------------------------------------------------------

-- Create the Fillers frame
local FillersFrame = CreateFrame("Frame", "FillersScreenPanel", UIParent, "BackdropTemplate")
FillersFrame:SetSize(FRAME_WIDTH, 30)
FillersFrame:SetFrameStrata("MEDIUM")
FillersFrame:SetClampedToScreen(true)
FillersFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    tile = true,
    tileSize = 16
})
FillersFrame:SetBackdropColor(unpack(APR.Color.defaultBackdrop))
FillersFrame:Hide()

-- Create the step holder frame for fillers
local FillersFrame_StepHolder = CreateFrame("Frame", "FillersFrame_StepHolder", FillersFrame,
    "BackdropTemplate")
FillersFrame_StepHolder:SetPoint("TOPLEFT", FillersFrame, "TOPLEFT", 0, -30)
FillersFrame_StepHolder:SetPoint("BOTTOMRIGHT", FillersFrame, "BOTTOMRIGHT", 0, 0)

-- Create the fillers header
local FillersFrameHeader = CreateFrame("Frame", "FillersFrameHeader", FillersFrame,
    "ObjectiveTrackerModuleHeaderTemplate")
FillersFrameHeader.Text:SetText(L["STEP_FILLERS"] or "Step Fillers")
FillersFrameHeader:ClearAllPoints()
FillersFrameHeader:SetPoint("TOP", FillersFrame, "TOP", 0, -1)
FillersFrameHeader:SetScript("OnMouseDown", function(self)
    -- No dragging for fillers frame
end)
FillersFrameHeader:SetScript("OnMouseUp", function(self)
    -- No dragging for fillers frame
end)

-- Hide minimize button for Fillers frame
FillersFrameHeader.MinimizeButton:Hide()

---------------------------------------------------------------------------------------
---------------------------------- Fillers Methods ------------------------------------
---------------------------------------------------------------------------------------

-- Helper function to create step frames
local function AddStepsFrame(questDesc, extraLineText, color)
    local textTemplate = "GameFontHighlight" -- white color
    if extraLineText then
        textTemplate = "GameFontNormal"      -- yellow color
    end
    -- Create a container for quest information
    local container = CreateFrame("Frame", nil, FillersFrame_StepHolder, "BackdropTemplate")
    -- Create a font for quest information
    local font = container:CreateFontString(nil, "OVERLAY", textTemplate)
    font:SetWordWrap(true)
    font:SetWidth(FRAME_WIDTH - 5)
    font:SetPoint("TOPLEFT", 5, -5)
    font:SetText('- ' .. (extraLineText or questDesc))
    font:SetJustifyH("LEFT")

    if color then
        font:SetTextColor(unpack(APR:HexaToRGBA(color)))
    end

    -- Set the size of the container based on the text length
    container:SetWidth(FRAME_WIDTH)
    container:SetHeight(font:GetStringHeight() + 10)
    -- Remove backdrop since FillersFrame already has one
    container:SetBackdrop(nil)
    container.font = font

    return container
end

-- Add a filler step
function APR.fillersFrame:AddFillerStep(questID, textObjective, objectiveIndex)
    APR:Debug("Function: APR.fillersFrame:AddFillerStep()", questID)
    if not APR.settings.profile.currentStepShow then
        return
    end

    -- Check if fillersList is empty to reset to the default height
    if not next(APR.currentStep.fillersList) then
        FRAME_FILLERS_HOLDER_HEIGHT = 0
    end

    local questKey = questID .. "-" .. (objectiveIndex or 0)
    local existingContainer = APR.currentStep.fillersList[questKey]

    -- Remove if it already exists
    if existingContainer then
        existingContainer:Hide()
        existingContainer:ClearAllPoints()
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
    self:RefreshFillersFrame()
end

-- Reorder filler steps
function APR.fillersFrame:ReOrderFillerSteps()
    APR:Debug("Function: APR.fillersFrame:ReOrderFillerSteps()")
    if not APR.settings.profile.currentStepShow then return end

    FRAME_FILLERS_HOLDER_HEIGHT = 0
    for id, container in pairs(APR.currentStep.fillersList) do
        if not container.hiddenInCombat then
            container:ClearAllPoints()
            container:SetPoint("TOPLEFT", FillersFrame_StepHolder, "TOPLEFT", 0, FRAME_FILLERS_HOLDER_HEIGHT)
            FRAME_FILLERS_HOLDER_HEIGHT = FRAME_FILLERS_HOLDER_HEIGHT - container:GetHeight()
        end
    end

    self:RefreshFillersFrame()
end

-- Remove all filler steps
function APR.fillersFrame:RemoveFillerSteps()
    APR:Debug("Function: APR.fillersFrame:RemoveFillerSteps()")
    if not APR.settings.profile.currentStepShow then return end

    for id, container in pairs(APR.currentStep.fillersList) do
        local canHide = APR.currentStep:CanSafelyHide(container)
        if canHide then
            container:ClearAllPoints()
            container:Hide()
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

    FRAME_FILLERS_HOLDER_HEIGHT = 0
    self:RefreshFillersFrame()
end

-- Refresh the fillers frame visibility and positioning
function APR.fillersFrame:RefreshFillersFrame()
    if not APR.settings.profile.currentStepShow then
        FillersFrame:Hide()
        return
    end

    -- Show or hide the fillers frame based on whether there are any fillers
    if next(APR.currentStep.fillersList) then
        FillersFrame:Show()
        FillersFrameHeader:Show()

        -- Reset collapse state when refreshing
        FillersFrame.collapsed = false
        FillersFrame_StepHolder:Show()

        -- Calculate total height needed
        local titleHeight = 30 -- Title space
        local contentHeight = math.abs(FRAME_FILLERS_HOLDER_HEIGHT)
        local totalHeight = titleHeight + contentHeight + 10

        FillersFrame:SetSize(FRAME_WIDTH, totalHeight)

        -- Position relative to CurrentStepFrame (with gap between frames)
        FillersFrame:ClearAllPoints()
        local currentStepPanel = _G.CurrentStepScreenPanel
        if currentStepPanel then
            local anchorFrame = currentStepPanel
            local anchorHeight = APR.currentStep:GetContentHeight(false) or currentStepPanel:GetHeight()
            if APR.AFK and APR.AFK.isSnapped then
                local afkFrame = _G.AfkFrameScreen
                if afkFrame and afkFrame:IsShown() then
                    anchorFrame = afkFrame
                    anchorHeight = afkFrame:GetHeight() or anchorHeight
                end
            end

            FillersFrame:SetScale(anchorFrame:GetScale() or 1)
            FillersFrame:SetPoint("TOP", anchorFrame, "TOP", 0, -anchorHeight)

            -- Update backdrop color
            FillersFrame:SetBackdropColor(unpack(APR.settings.profile.currentStepbackgroundColorAlpha))
        end
    else
        FillersFrame:Hide()
    end

    -- Update positioning of AFK and QuestOrderList
    if APR.AFK and APR.AFK.RefreshFrameAnchor then
        APR.AFK:RefreshFrameAnchor()
    end
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
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

    -- Update individual filler containers
    for _, container in pairs(APR.currentStep.fillersList) do
        -- Don't touch soft-hidden frames during combat
        if container and not container.hiddenInCombat then
            -- No backdrop on individual containers, only on parent
            -- This is intentional based on the original design
        end
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
end

-- Show the fillers frame (used when expanding)
function APR.fillersFrame:Show()
    self:RefreshFillersFrame()
end

-- Export frames for external access
APR.fillersFrame.Frame = FillersFrame
APR.fillersFrame.FrameHeader = FillersFrameHeader
APR.fillersFrame.StepHolder = FillersFrame_StepHolder
