--[[
    ElvUI compatibility skinning for Azeroth Pilot Reloaded.
    Skins all APR frames to match the ElvUI visual theme when ElvUI is active.
    Gracefully does nothing if ElvUI is not installed or the setting is disabled.
]]

-- Bail out immediately if ElvUI is not loaded
if not _G.ElvUI then return end

local E = unpack(_G.ElvUI)
local S = E:GetModule("Skins")

APR.ElvUISkin = APR:NewModule("ElvUISkin")

-- Track skinned frames to avoid double-skinning
local skinnedFrames = {}
local storedCurrentStepBackdropColor
local forcedCurrentStepTransparent = false
local isApplyingBackdropOverride = false

local function IsElvUISkinEnabled()
    if not APR.settings or not APR.settings.profile then
        return true
    end
    return APR.settings.profile.elvuiSkin ~= false
end

local function IsSkinned(frame)
    return frame and skinnedFrames[frame]
end

local function MarkSkinned(frame)
    if frame then
        skinnedFrames[frame] = true
    end
end

--- Check if the current step frame is attached to the quest log (ObjectiveTracker)
---@return boolean
local function IsAttachedToQuestLog()
    return APR.settings and APR.settings.profile
        and APR.settings.profile.currentStepAttachFrameToQuestLog
end

--- When ElvUI skin is active and attached to quest log, keep snapped AFK backdrop transparent.
local function UpdateSnappedBackdrops()
    if isApplyingBackdropOverride then
        return
    end
    isApplyingBackdropOverride = true

    local currentStepFrame = _G.CurrentStepScreenPanel
    if not currentStepFrame or not currentStepFrame.GetBackdropColor then
        isApplyingBackdropOverride = false
        return
    end

    -- If ElvUI skin is disabled, restore any previously forced transparent color.
    if not IsElvUISkinEnabled() then
        if forcedCurrentStepTransparent and storedCurrentStepBackdropColor and currentStepFrame.SetBackdropColor then
            currentStepFrame:SetBackdropColor(unpack(storedCurrentStepBackdropColor))
        end
        forcedCurrentStepTransparent = false
        isApplyingBackdropOverride = false
        return
    end

    local attached = IsAttachedToQuestLog()
    local transparent = { 0, 0, 0, 0 }
    local profile = APR.settings and APR.settings.profile
    local bothFramesSnapped = profile and profile.fillersFrameSnapToCurrentStep and
    profile.questOrderListSnapToCurrentStep

    local function ApplyBackdrop(frame)
        if not frame then return end
        if attached then
            if frame.SetBackdropColor then
                frame:SetBackdropColor(unpack(transparent))
            end
        end
    end

    -- AFK frame
    ApplyBackdrop(_G.AfkFrameScreen)

    -- Current Step frame: transparent while snapped to questlog, restore previous color when unsnapped.
    if attached then
        if not forcedCurrentStepTransparent then
            local r, g, b, a = currentStepFrame:GetBackdropColor()
            storedCurrentStepBackdropColor = { r or 0, g or 0, b or 0, a or 1 }
        end
        if APR.currentStep and APR.currentStep.UpdateBackgroundColorAlpha then
            APR.currentStep:UpdateBackgroundColorAlpha(transparent)
        elseif currentStepFrame.SetBackdropColor then
            currentStepFrame:SetBackdropColor(unpack(transparent))
        end
        forcedCurrentStepTransparent = true

        -- Apply same transparent override to fillers + quest order list only if BOTH are snapped to current step.
        if bothFramesSnapped then
            if APR.fillersFrame and APR.fillersFrame.UpdateBackgroundColorAlpha then
                APR.fillersFrame:UpdateBackgroundColorAlpha(transparent)
            end
            if APR.questOrderList and APR.questOrderList.UpdateBackgroundColorAlpha then
                APR.questOrderList:UpdateBackgroundColorAlpha(transparent)
            end
        end
    else
        if forcedCurrentStepTransparent then
            if storedCurrentStepBackdropColor then
                if APR.currentStep and APR.currentStep.UpdateBackgroundColorAlpha then
                    APR.currentStep:UpdateBackgroundColorAlpha(storedCurrentStepBackdropColor)
                elseif currentStepFrame.SetBackdropColor then
                    currentStepFrame:SetBackdropColor(unpack(storedCurrentStepBackdropColor))
                end
            elseif APR.settings and APR.settings.profile and APR.settings.profile.currentStepbackgroundColorAlpha then
                if APR.currentStep and APR.currentStep.UpdateBackgroundColorAlpha then
                    APR.currentStep:UpdateBackgroundColorAlpha(APR.settings.profile.currentStepbackgroundColorAlpha)
                elseif currentStepFrame.SetBackdropColor then
                    currentStepFrame:SetBackdropColor(unpack(APR.settings.profile.currentStepbackgroundColorAlpha))
                end
            end
        end

        -- Restore child frame colors when leaving snapped questlog mode (only if both are snapped to current step).
        if bothFramesSnapped then
            if APR.fillersFrame and APR.fillersFrame.UpdateBackgroundColorAlpha then
                APR.fillersFrame:UpdateBackgroundColorAlpha()
            end
            if APR.questOrderList and APR.questOrderList.UpdateBackgroundColorAlpha then
                APR.questOrderList:UpdateBackgroundColorAlpha()
            end
        end

        forcedCurrentStepTransparent = false
    end

    isApplyingBackdropOverride = false
end

---------------------------------------------------------------------------------------
------------------------------ Core Skinning Helpers ----------------------------------
---------------------------------------------------------------------------------------

--- Mark a standard frame as processed without touching its backdrop.
---@param frame table
---@param template string|nil "Transparent" (default) or "Default"
local function SkinBackdropFrame(frame, template)
    if not frame or IsSkinned(frame) then return end
    -- Intentionally do nothing: base addon manages frame backgrounds.
    MarkSkinned(frame)
end

--- Mark a dialog frame as processed without touching its backdrop.
---@param frame table
local function SkinDialogFrame(frame)
    if not frame or IsSkinned(frame) then return end
    -- Intentionally do nothing: base addon manages frame backgrounds.
    MarkSkinned(frame)
end

--- Skin a UIPanelButtonTemplate button
---@param button table
local function SkinButton(button)
    if not button or IsSkinned(button) then return end
    if S.HandleButton then
        S:HandleButton(button)
    end
    MarkSkinned(button)
end

--- Skin the current-step settings icon without converting it to a boxed button.
--- Keeping native icon textures avoids the black-square artifact with ElvUI HandleButton.
---@param button table
local function SkinSettingsIconButton(button)
    if not button or IsSkinned(button) then return end
    button:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    button:SetPushedTexture("Interface\\Buttons\\UI-OptionsButton")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    MarkSkinned(button)
end

--- Skin a UIPanelCloseButton
---@param button table
local function SkinCloseButton(button)
    if not button or IsSkinned(button) then return end
    if S.HandleCloseButton then
        S:HandleCloseButton(button)
    end
    MarkSkinned(button)
end

--- Force ObjectiveTracker "secondary" minimize visuals on APR headers when ElvUI skin is enabled.
---@param button table
---@param parentFrame table|nil
local function SkinSecondaryMinimizeButton(button, parentFrame)
    if not button or button.__APRSecondaryMinimizeSkinned then return end

    local function ApplyAtlasState()
        local isCollapsed = parentFrame and parentFrame.collapsed
        local normalAtlas = isCollapsed and "ui-questtrackerbutton-secondary-expand" or
            "ui-questtrackerbutton-secondary-collapse"
        local pushedAtlas = normalAtlas .. "-pressed"

        local normal = button.GetNormalTexture and button:GetNormalTexture()
        local pushed = button.GetPushedTexture and button:GetPushedTexture()
        local highlight = button.GetHighlightTexture and button:GetHighlightTexture()

        if normal and normal.SetAtlas then
            normal:SetAtlas(normalAtlas)
        end
        if pushed and pushed.SetAtlas then
            pushed:SetAtlas(pushedAtlas)
        end
        if highlight and highlight.SetAtlas then
            highlight:SetAtlas("ui-questtrackerbutton-yellow-highlight")
        end
    end

    ApplyAtlasState()
    if button.HookScript then
        button:HookScript("OnClick", ApplyAtlasState)
    end
    button.__APRSecondaryMinimizeSkinned = true
end

--- Skin a scrollbar from a ScrollFrame
---@param scrollFrame table
local function SkinScrollBar(scrollFrame)
    if not scrollFrame then return end
    local name = scrollFrame.GetName and scrollFrame:GetName()
    local scrollbar = scrollFrame.ScrollBar or (name and _G[name .. "ScrollBar"])
    if scrollbar and not IsSkinned(scrollbar) and S.HandleScrollBar then
        S:HandleScrollBar(scrollbar)
        MarkSkinned(scrollbar)
    end
end

--- Skin an ObjectiveTracker-style header
---@param header table
local function SkinOTHeader(header)
    if not header or IsSkinned(header) then return end
    if header.StripTextures then
        header:StripTextures()
    end
    if header.Background then
        header.Background:SetAlpha(0)
    end
    MarkSkinned(header)
end

--- Skin all child buttons inside a frame
---@param frame table
local function SkinChildButtons(frame)
    if not frame then return end
    for _, child in pairs({ frame:GetChildren() }) do
        if child:IsObjectType("Button") and not IsSkinned(child) then
            -- Detect UIPanelButtonTemplate-style buttons (they have Left/Right/Middle textures)
            if child.Left or child.Right or child.Middle then
                SkinButton(child)
            end
        end
    end
end

---------------------------------------------------------------------------------------
------------------------------ Static Frame Skinning ----------------------------------
---------------------------------------------------------------------------------------

local function SkinStaticFrames()
    -- Current Step Frame (header + buttons only, no backdrop)
    local csHeader = _G.CurrentStepFrameHeader
    if csHeader then
        SkinOTHeader(csHeader)
        if csHeader.MinimizeButton then
            SkinSecondaryMinimizeButton(csHeader.MinimizeButton, _G.CurrentStepScreenPanel)
        end
    end

    -- Settings button on current step header
    local csSettings = _G.CurrentStepFrameSettingsButton
    if csSettings then
        SkinSettingsIconButton(csSettings)
    end

    -- Fillers Frame (header only, no backdrop)
    local ffHeader = _G.FillersFrameHeader
    if ffHeader then
        SkinOTHeader(ffHeader)
        if ffHeader.MinimizeButton then
            SkinSecondaryMinimizeButton(ffHeader.MinimizeButton, _G.FillersScreenPanel)
        end
    end

    -- Quest Order List (header + scrollbar only, no backdrop)
    local qolHeader = _G.QuestOrderListFrame_StepHolderHeader
    if qolHeader then
        SkinOTHeader(qolHeader)
    end
    local qolScroll = _G.QuestOrderListFrame_ScrollFrame
    if qolScroll then
        SkinScrollBar(qolScroll)
    end
    if qolHeader and qolHeader.MinimizeButton then
        SkinSecondaryMinimizeButton(qolHeader.MinimizeButton, _G.QuestOrderListPanel)
    end

    -- Coordinate Frame
    local coordPanel = _G.CoordinateScreenPanel
    if coordPanel then
        SkinBackdropFrame(coordPanel)
    end

    -- Route Selection
    local rsPanel = _G.RouteSelectionPanel
    if rsPanel then
        SkinBackdropFrame(rsPanel)
    end
    local rsHeader = _G.RouteSelectionFrameHeader
    if rsHeader then
        SkinOTHeader(rsHeader)
        if rsHeader.MinimizeButton then
            SkinSecondaryMinimizeButton(rsHeader.MinimizeButton, _G.RouteSelectionPanel)
        end
    end
    local rsButton = _G.OpenSettingsButton
    if rsButton then
        SkinButton(rsButton)
    end

    -- Changelog
    local clFrame = _G.ChangeLogFrame
    if clFrame then
        SkinBackdropFrame(clFrame)
    end
    local clScroll = _G.ChangeLogScrollFrame
    if clScroll then
        SkinScrollBar(clScroll)
    end

    -- Party Frame
    local partyPanel = _G.PartyScreenPanel
    if partyPanel then
        SkinBackdropFrame(partyPanel)
    end
    local partyHolder = _G.PartyFrame_TeamHolder
    if partyHolder then
        SkinBackdropFrame(partyHolder)
    end
    local partyHeader = _G.PartyFrameHeader
    if partyHeader then
        SkinOTHeader(partyHeader)
        if partyHeader.MinimizeButton then
            SkinSecondaryMinimizeButton(partyHeader.MinimizeButton, _G.PartyScreenPanel)
        end
    end

    -- Heirloom Frame
    local heirPanel = _G.HeirloomPanel
    if heirPanel then
        SkinBackdropFrame(heirPanel)
    end
    local heirBody = _G.HeirloomFrame_body
    if heirBody then
        SkinBackdropFrame(heirBody)
    end
    local heirHeader = _G.HeirloomFrameHeader
    if heirHeader then
        SkinOTHeader(heirHeader)
        if heirHeader.MinimizeButton then
            SkinSecondaryMinimizeButton(heirHeader.MinimizeButton, _G.HeirloomPanel)
        end
    end

    -- Buff Frame
    local buffFrame = _G.BuffFrameScreen
    if buffFrame then
        SkinBackdropFrame(buffFrame)
    end
    local buffBody = _G.BuffFrame_body
    if buffBody then
        SkinBackdropFrame(buffBody)
    end
    local buffHeader = _G.BuffFrameHeader
    if buffHeader then
        SkinOTHeader(buffHeader)
        if buffHeader.MinimizeButton then
            SkinSecondaryMinimizeButton(buffHeader.MinimizeButton, _G.BuffFrameScreen)
        end
    end

    -- AFK Frame
    local afkFrame = _G.AfkFrameScreen
    if afkFrame then
        SkinBackdropFrame(afkFrame)
    end
end

---------------------------------------------------------------------------------------
----------------------------- Dynamic Frame Skinning ----------------------------------
---------------------------------------------------------------------------------------

--- Skin the route trigger popup if it exists
local function SkinRouteTriggerPopup()
    local frame = _G.APRRouteTriggerPopup
    if frame then
        SkinDialogFrame(frame)
        SkinChildButtons(frame)
    end
end

--- Skin the selection popup if it exists
local function SkinSelectionPopup()
    local frame = _G.APRSelectionPopup
    if frame then
        SkinDialogFrame(frame)
        SkinChildButtons(frame)
    end
end

--- Skin the status report frame if it exists
local function SkinStatusReport()
    local frame = _G.APRStatusReport
    if frame then
        SkinDialogFrame(frame)
        SkinChildButtons(frame)
        -- Skin close button
        for _, child in pairs({ frame:GetChildren() }) do
            if child:IsObjectType("Button") then
                local name = child.GetName and child:GetName()
                if child:GetObjectType() == "Button" then
                    local normal = child:GetNormalTexture()
                    if normal then
                        local texturePath = normal:GetTexture()
                        if type(texturePath) == "string" and texturePath:find("UIPanelCloseButton") then
                            SkinCloseButton(child)
                        end
                    end
                end
            end
        end
    end
end

--- Skin an image preview panel
---@param panel table
local function SkinImagePreviewPanel(panel)
    if not panel or IsSkinned(panel) then return end
    SkinDialogFrame(panel)
end

--- Hook dynamic frame creation functions
local function HookDynamicFrames()
    -- Hook CreateStandardFrame: skins frames as they are created
    if APR.CreateStandardFrame then
        hooksecurefunc(APR, "CreateStandardFrame", function(_, name)
            if not IsElvUISkinEnabled() then return end
            local frame = name and _G[name]
            if frame then
                SkinBackdropFrame(frame)
            end
        end)
    end

    -- Hook popup creation: skin popups when they're first shown
    if APR.questionDialog then
        if APR.questionDialog.CreateRouteTriggerPopup then
            hooksecurefunc(APR.questionDialog, "CreateRouteTriggerPopup", function()
                if IsElvUISkinEnabled() then
                    SkinRouteTriggerPopup()
                end
            end)
        end

        if APR.questionDialog.CreateSelectionPopup then
            hooksecurefunc(APR.questionDialog, "CreateSelectionPopup", function()
                if IsElvUISkinEnabled() then
                    SkinSelectionPopup()
                end
            end)
        end
    end

    -- Hook status report creation
    if APR.showStatusReport then
        hooksecurefunc(APR, "showStatusReport", function()
            if IsElvUISkinEnabled() then
                SkinStatusReport()
            end
        end)
    end

    -- Hook image preview overlay creation
    if APR.currentStepImagePreview and APR.currentStepImagePreview.ShowOverlayForSlot then
        hooksecurefunc(APR.currentStepImagePreview, "ShowOverlayForSlot", function()
            if not IsElvUISkinEnabled() then return end
            -- Skin any new preview panels by scanning global names
            for i = 1, 20 do
                local panelName = "APRCurrentStepImagePreviewFrame" .. i
                local panel = _G[panelName]
                if panel then
                    SkinImagePreviewPanel(panel)
                end
            end
        end)
    end

    -- Hook frame anchor refreshes to update AFK backdrop after repositioning
    if APR.currentStep and APR.currentStep.RefreshCurrentStepFrameAnchor then
        hooksecurefunc(APR.currentStep, "RefreshCurrentStepFrameAnchor", function()
            UpdateSnappedBackdrops()
        end)
    end

    if APR.currentStep and APR.currentStep.UpdateBackgroundColorAlpha then
        hooksecurefunc(APR.currentStep, "UpdateBackgroundColorAlpha", function()
            UpdateSnappedBackdrops()
        end)
    end

    if APR.AFK and APR.AFK.RefreshFrameAnchor then
        hooksecurefunc(APR.AFK, "RefreshFrameAnchor", function()
            UpdateSnappedBackdrops()
        end)
    end
end

---------------------------------------------------------------------------------------
------------------------------ Module Initialization ----------------------------------
---------------------------------------------------------------------------------------

function APR.ElvUISkin:OnEnable()
    if not IsElvUISkinEnabled() then return end

    SkinStaticFrames()
    HookDynamicFrames()
    UpdateSnappedBackdrops()
end

--- Re-apply skins (called when the setting is toggled on)
function APR.ElvUISkin:ApplySkins()
    if not IsElvUISkinEnabled() then return end

    -- Reset tracking so we can re-skin
    skinnedFrames = {}

    SkinStaticFrames()

    -- Skin any lazy frames that may already exist
    SkinRouteTriggerPopup()
    SkinSelectionPopup()
    SkinStatusReport()

    for i = 1, 20 do
        local panelName = "APRCurrentStepImagePreviewFrame" .. i
        local panel = _G[panelName]
        if panel then
            SkinImagePreviewPanel(panel)
        end
    end

    UpdateSnappedBackdrops()
end

--- Check if ElvUI is available (utility for other modules)
---@return boolean
function APR:IsElvUILoaded()
    return _G.ElvUI ~= nil
end
