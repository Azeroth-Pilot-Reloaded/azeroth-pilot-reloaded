--[[
    UI-related helpers and lightweight cosmetic utilities.
    Keeping them isolated prevents the base Utils.lua from mixing display logic with technical helpers.
]]

local L = LibStub("AceLocale-3.0"):GetLocale("APR")

local PREVIEW_IMAGE_ASSET_ROOT = "Interface\\AddOns\\APR\\APR-Core\\assets\\"


local function getStatusHex(name, fallback)
    return (APR.HEXColor and APR.HEXColor[name]) or fallback
end

local function tooltipBoolean(value)
    local greenHex = getStatusHex("green")
    local redHex = getStatusHex("red")
    return value and APR:WrapTextInColorCode(YES, greenHex) or APR:WrapTextInColorCode(NO, redHex)
end

local function yellowKey(keyText)
    return APR:WrapTextInColorCode(tostring(keyText), getStatusHex("yellow"))
end

local function addKeyValueLine(tooltip, keyText, valueText)
    tooltip:AddLine(yellowKey(keyText) .. ": " .. tostring(valueText), unpack(APR.Color.white))
end

local function addStorylineLine(tooltip, questIDNum)
    if questIDNum then
        local storylineName, storylineCompleted = APR:GetQuestStorylineInfo(questIDNum)
        if storylineName then
            local text = storylineName
            if storylineCompleted then
                text = text .. " (" .. APR:WrapTextInColorCode(L["COMPLETED"], getStatusHex("green")) .. ")"
            end
            addKeyValueLine(tooltip, L["Storyline"], text)
        end
    end
end

local function addScenarioDetails(tooltip, scenarioRef, objectiveIndex, objectiveText)
    addKeyValueLine(tooltip, SCENARIOS .. " " .. ID, scenarioRef)

    local scenarioInfo = C_ScenarioInfo and C_ScenarioInfo.GetInfo and C_ScenarioInfo.GetInfo()
    if type(scenarioInfo) == "table" then
        local instanceName = rawget(scenarioInfo, "instanceName") or rawget(scenarioInfo, "uiMapName")
        local scenarioID = rawget(scenarioInfo, "scenarioID") or rawget(scenarioInfo, "id")
        local scenarioName = rawget(scenarioInfo, "title") or rawget(scenarioInfo, "name")

        if instanceName then
            addKeyValueLine(tooltip, "INSTANCE", instanceName)
        end
        if scenarioID then
            addKeyValueLine(tooltip, L["Scenario ID"], scenarioID)
        end
        if scenarioName then
            addKeyValueLine(tooltip, L["Scenario Name"], scenarioName)
        end
    end

    if objectiveIndex ~= nil and objectiveText ~= nil then
        addKeyValueLine(tooltip, OBJECTIVES_LABEL, tostring(objectiveIndex) .. " - " .. tostring(objectiveText))
    end
end

--- Add quest/scenario tooltip details.
--- @param tooltip table GameTooltip-like object
--- @param questID string|number
--- @param options table|nil
function APR:AddQuestTooltipDetails(tooltip, questID, options)
    if not tooltip then
        return
    end

    options = options or {}

    if options.addHeader ~= false then
        tooltip:AddLine(L["QUEST_INFO"])
    end

    local questIDText = (questID ~= nil) and tostring(questID) or "?"
    local questIDNum = tonumber(questIDText)
    local objectiveIndex = options.objectiveIndex
    local objectiveText = options.objectiveText

    if options.isScenario then
        addScenarioDetails(tooltip, questIDText, objectiveIndex, objectiveText)
        return
    end

    -- Order requested: ID, Name, StorylineName, Campaign, Objectives
    addKeyValueLine(tooltip, ID, questIDText)

    if questIDNum then
        local questTitle = C_QuestLog.GetTitleForQuestID(questIDNum)
        if questTitle then
            addKeyValueLine(tooltip, NAME, questTitle)
        end
    end

    if options.includeStoryline ~= false then
        addStorylineLine(tooltip, questIDNum)
    end

    if options.includeCampaign ~= false then
        local isCampaign = questIDNum and APR:IsCampaignQuest(questIDNum)
        addKeyValueLine(tooltip, L["Campaign"], tooltipBoolean(isCampaign and true or false))
    end

    if objectiveIndex ~= nil and objectiveText ~= nil then
        addKeyValueLine(tooltip, OBJECTIVES_LABEL, tostring(objectiveIndex) .. " - " .. tostring(objectiveText))
    end
end

--- Performs the "Love" action for the APR module.
-- Updates APR color scheme for Saint Valentin (Feb 14th).
function APR:Love()
    local currentDate = C_DateAndTime.GetCurrentCalendarTime()
    if currentDate.month == 2 and currentDate.monthDay == 14 then
        APR.Color.blue = APR.Color.pink
        APR.Color.yellow = APR.Color.pink
        self.loveColorsPending = true
        self:ApplyLoveColors()
    end
end

-- Apply Love day color overrides to live widgets
function APR:ApplyLoveColors()
    if not self.loveColorsPending then
        return
    end

    local profile = APR.settings and APR.settings.profile
    if not profile then
        return
    end

    local pink = APR.Color.pink or { 1, 0, 1, 1 }
    local function copyWithAlpha(existing)
        local alpha = (existing and existing[4]) or 1
        return { pink[1], pink[2], pink[3], alpha }
    end

    profile.afkBarColor = copyWithAlpha(profile.afkBarColor)
    profile.currentStepProgressBarColor = copyWithAlpha(profile.currentStepProgressBarColor)

    if APR.AFK and APR.AFK.UpdateBarColor then
        APR.AFK:UpdateBarColor()
    end
    if APR.currentStep and APR.currentStep.UpdateProgressBarColor then
        APR.currentStep:UpdateProgressBarColor()
    end

    self.loveColorsPending = false
end

function APR:getStatus()
    APR.settings:CloseSettings()
    APR:showStatusReport()
end

---------------------------------------------------------------------------------------
---------------------- Current Step Preview Helper Utilities --------------------------
---------------------------------------------------------------------------------------

--- Register a frame in UISpecialFrames if available.
---@param frameName string
function APR:RegisterUiSpecialFrame(frameName)
    if type(frameName) ~= "string" or frameName == "" then
        return
    end

    local specialFrames = _G and _G.UISpecialFrames
    if type(specialFrames) ~= "table" then
        return
    end

    for _, name in ipairs(specialFrames) do
        if name == frameName then
            return
        end
    end

    tinsert(specialFrames, frameName)
end

--- Normalize preview image field on a step.
--- Supports only `PreviewImages` as an array of strings.
---@param step table|nil
---@return table
function APR:NormalizePreviewImages(step)
    if type(step) ~= "table" or type(step.PreviewImages) ~= "table" then
        return {}
    end

    local collected = {}

    local function addPath(path)
        if type(path) ~= "string" then
            return
        end

        local trimmed = strtrim(path)
        if trimmed == "" then
            return
        end

        local fullPath = trimmed
        if not trimmed:find("^Interface\\") then
            fullPath = PREVIEW_IMAGE_ASSET_ROOT .. trimmed
        end

        table.insert(collected, fullPath)
    end

    for _, path in ipairs(step.PreviewImages) do
        addPath(path)
    end

    return collected
end

--- Compare two ordered string lists.
---@param a table|nil
---@param b table|nil
---@return boolean
function APR:AreOrderedStringListsEqual(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    if #a ~= #b then
        return false
    end

    for i = 1, #a do
        if a[i] ~= b[i] then
            return false
        end
    end

    return true
end

--- Compute responsive thumbnail size for a single-row preview strip.
---@param availableWidth number
---@param count number
---@param gap number
---@param minSize number
---@param maxSize number
---@return number
function APR:ComputeThumbnailSize(availableWidth, count, gap, minSize, maxSize)
    local safeCount = math.max(tonumber(count) or 0, 1)
    local safeWidth = tonumber(availableWidth) or 0
    local safeGap = tonumber(gap) or 0
    local minValue = tonumber(minSize) or 24
    local maxValue = tonumber(maxSize) or 96

    local computed = math.floor((safeWidth - ((safeCount - 1) * safeGap)) / safeCount)
    return math.max(minValue, math.min(maxValue, computed))
end

---------------------------------------------------------------------------------------
---------------------------- Frame Management Utilities ------------------------------
---------------------------------------------------------------------------------------

--- Check if frames should be hidden based on various conditions
--- Centralizes frame hiding logic to avoid duplication across multiple frame modules
---@return boolean true if frames should be hidden
function APR:ShouldHideFrames()
    return not self.settings.profile.currentStepShow or
        not self.settings.profile.enableAddon or
        C_PetBattles.IsInBattle() or
        not self:IsInstanceWithUI()
end

--- Check if AFK frame is visible, active (timer running), and should snap
--- Implements proper state verification for safe anchor frame selection
---@return boolean true if AFK frame should be used as anchor
function APR:IsAFKFrameActiveShouldSnap()
    -- Quick exit if AFK module or settings not loaded
    if not self.AFK or not self.settings or not self.settings.profile then
        return false
    end

    -- Check if snapping is enabled in settings
    if not self.settings.profile.afkSnapToCurrentStep then
        return false
    end

    -- Check if AFK frame exists and is shown
    local afkFrame = _G.AfkFrameScreen
    if not afkFrame or not afkFrame:IsShown() then
        return false
    end

    -- Check if AFK timer is actually active (fake timer)
    if not self.AFK.fakeTimerActive then
        return false
    end

    return true
end

--- Get the proper snap anchor frame implementing the snap hierarchy
--- Other frames can anchor to this in order: Fillers > AFK > CurrentStep
--- FillersFrame calls with excludeFillers=true to avoid anchoring to itself
---@param excludeFillers boolean|nil If true, skip Fillers in the hierarchy (used by FillersFrame)
---@return table|nil anchorFrame The frame to anchor to, or nil if unavailable
---@return number|nil anchorHeight Height of the anchor frame, or nil if unavailable
function APR:GetSnapAnchorFrame(excludeFillers)
    -- Default to CurrentStep panel
    local currentStepPanel = _G.CurrentStepScreenPanel
    if not currentStepPanel or not currentStepPanel:IsShown() then
        return nil, nil
    end

    -- Hierarchy: Fillers (highest, optional) -> AFK (medium) -> CurrentStep (fallback)

    -- 1. Check Fillers frame (highest priority, unless explicitly excluded)
    if not excludeFillers and self.fillersFrame and self.settings and self.settings.profile then
        local fillersFrame = self.fillersFrame.Frame
        if fillersFrame and fillersFrame:IsShown() and self.settings.profile.fillersFrameSnapToCurrentStep then
            return fillersFrame, fillersFrame:GetHeight()
        end
    end

    -- 2. Check AFK frame (medium priority)
    if self:IsAFKFrameActiveShouldSnap() then
        local afkFrame = _G.AfkFrameScreen
        return afkFrame, afkFrame:GetHeight()
    end

    -- 3. Default to CurrentStep frame (always available as fallback)
    local contentHeight = (self.currentStep and self.currentStep.GetContentHeight) and
        self.currentStep:GetContentHeight(false) or 0

    if not contentHeight or contentHeight <= 0 then
        contentHeight = currentStepPanel:GetHeight() or 300
    end

    return currentStepPanel, contentHeight
end

--- Create a standard APR UI frame with default backdrop styling.
---@param name string
---@param parent table
---@param width number
---@param height number
---@param template string|nil
---@return table
function APR:CreateStandardFrame(name, parent, width, height, template)
    local frame = CreateFrame("Frame", name, parent or UIParent, template or "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        tile = true,
        tileSize = 16
    })
    frame:SetBackdropColor(unpack(APR.Color.defaultBackdrop))
    return frame
end

--- Setup drag handlers for a frame with a guard function and optional stop callback.
---@param frame table
---@param canDrag fun():boolean
---@param onStop fun(frame: table)|nil
function APR:SetupFrameDrag(frame, canDrag, onStop)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if canDrag and not canDrag() then
            return
        end
        self:StartMoving()
        self.isMoving = true
    end)
    frame:SetScript("OnDragStop", function(self)
        if not self.isMoving then
            return
        end
        self:StopMovingOrSizing()
        self.isMoving = false
        if onStop then
            onStop(self)
        end
    end)
end

--- Setup drag handlers on a header to move its parent frame.
---@param header table
---@param parentFrame table
---@param canDrag fun():boolean
---@param onStop fun(frame: table)|nil
---@param rightClickHandler fun()|nil Optional handler for right-click events
function APR:SetupHeaderDrag(header, parentFrame, canDrag, onStop, rightClickHandler)
    header:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" and rightClickHandler then
            rightClickHandler()
            return
        end
        if button ~= "LeftButton" then
            return
        end
        if canDrag and not canDrag() then
            return
        end
        parentFrame:StartMoving()
        parentFrame.isMoving = true
    end)
    header:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then
            return
        end
        if not parentFrame.isMoving then
            return
        end
        parentFrame:StopMovingOrSizing()
        parentFrame.isMoving = false
        if onStop then
            onStop(parentFrame)
        end
    end)
end

--- Create an ObjectiveTracker-style header frame.
---@param name string
---@param parent table
---@param text string
---@param template string|nil Default: "ObjectiveTrackerModuleHeaderTemplate"
---@return table
function APR:CreateFrameHeader(name, parent, text, template)
    local header = CreateFrame("Frame", name, parent, template or "ObjectiveTrackerModuleHeaderTemplate")
    header.Text:SetText(text)
    return header
end

--- Setup minimize/collapse behavior for a frame header.
---@param header table The header with MinimizeButton
---@param parentFrame table The frame to collapse
---@param onCollapse fun()|nil Called when collapsing
---@param onExpand fun()|nil Called when expanding
---@param collapseAtlas string|nil Custom collapse atlas (default: "ui-questtrackerbutton-secondary-collapse")
---@param expandAtlas string|nil Custom expand atlas (default: "ui-questtrackerbutton-secondary-expand")
function APR:SetupMinimizeButton(header, parentFrame, onCollapse, onExpand, collapseAtlas, expandAtlas)
    local collapseNormal = collapseAtlas or "ui-questtrackerbutton-secondary-collapse"
    local collapsePressed = collapseNormal .. "-pressed"
    local expandNormal = expandAtlas or "ui-questtrackerbutton-secondary-expand"
    local expandPressed = expandNormal .. "-pressed"

    header.MinimizeButton:SetScript("OnClick", function(self)
        if parentFrame.collapsed then
            -- Expand
            if onExpand then onExpand() end
            self:GetNormalTexture():SetAtlas(collapseNormal)
            self:GetPushedTexture():SetAtlas(collapsePressed)
            parentFrame.collapsed = false
        else
            -- Collapse
            if onCollapse then onCollapse() end
            self:GetNormalTexture():SetAtlas(expandNormal)
            self:GetPushedTexture():SetAtlas(expandPressed)
            parentFrame.collapsed = true
        end
    end)
end

--- Create a text container used by step/filler lists.
---@param parent table
---@param width number
---@param text string
---@param isExtraLine boolean|nil
---@param color string|nil
---@param backdropColor table|nil
---@param showLeadingDash boolean|nil
---@return table
function APR:CreateStepTextContainer(parent, width, text, isExtraLine, color, backdropColor, showLeadingDash)
    local textTemplate = isExtraLine and "GameFontNormal" or "GameFontHighlight"
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local font = container:CreateFontString(nil, "OVERLAY", textTemplate)
    local useLeadingDash = (showLeadingDash ~= false)
    font:SetWordWrap(true)
    font:SetWidth(width - 5)
    font:SetPoint("TOPLEFT", 5, -5)
    font:SetText((useLeadingDash and "- " or "") .. text)
    font:SetJustifyH("LEFT")

    if color then
        font:SetTextColor(unpack(APR:HexaToRGBA(color)))
    end

    container:SetWidth(width)
    container:SetHeight(font:GetStringHeight() + 10)

    if backdropColor then
        container:SetBackdrop({
            bgFile = "Interface\\BUTTONS\\WHITE8X8",
            tile = true,
            tileSize = 16
        })
        container:SetBackdropColor(unpack(backdropColor))
    else
        container:SetBackdrop(nil)
    end

    container.font = font
    container.showLeadingDash = useLeadingDash
    return container
end

--- Snap a frame to an anchor frame at a calculated distance.
-- Centralizes the snap positioning logic used by multiple modules (FillersFrame, QuestOrderList, AFK).
-- Handles ClearAllPoints + SetPoint with proper offset calculation and scale synchronization.
---@param frame table The frame to position
---@param anchorFrame table The reference frame to snap to
---@param anchorHeight number The effective height of anchor frame (used for offset calculation)
---@param gap number The gap between anchor and frame (positive = below, negative = above)
---@param adjustForHeader number|nil Optional header height to add to offset (e.g., 20 for standard header)
---@return boolean True if successfully snapped, false if anchor is invalid
function APR:SnapFrameToAnchor(frame, anchorFrame, anchorHeight, gap, adjustForHeader)
    if not frame or not anchorFrame then
        return false
    end

    -- Synchronize scale with anchor
    local anchorScale = anchorFrame:GetScale() or 1
    if frame:GetScale() ~= anchorScale then
        frame:SetScale(anchorScale)
    end

    -- Calculate total offset
    local totalOffset = math.floor(anchorHeight + gap)
    if adjustForHeader and adjustForHeader > 0 then
        totalOffset = totalOffset + adjustForHeader
    end

    -- Position frame relative to anchor
    frame:ClearAllPoints()
    frame:SetPoint("TOP", anchorFrame, "TOP", 0, -totalOffset)

    return true
end
