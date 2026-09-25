local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR Quest Order List module
APR.questOrderList = APR:NewModule("QuestOrderList")
APR.questOrderList.stepList = {}
APR.questOrderList.questID = nil
APR.questOrderList.currentStepIndex = nil
APR.questOrderList.updateTimer = nil
APR.questOrderList.pendingUpdate = false
APR.questOrderList.rawStepContainers = {}
APR.questOrderList.renderComplete = false
APR.questOrderList.visibilityState = nil

local QuestOrderListUtils = APR.questOrderListUtils
local getSnapAnchor
local snapToAnchor
local updateSnapSizing
local QuestOrderListFrame
local QuestOrderListFrame_StepHolder
local QuestOrderListFrame_ScrollFrame
local QuestOrderListFrame_ScrollChild
local QuestOrderListFrame_StepHolderHeader

-- Local constants
local FRAME_WIDTH = 258
local FRAME_HEIGHT = 300
local FRAME_MIN_WIDTH = FRAME_WIDTH
local FRAME_MIN_HEIGHT = 100
local FRAME_OFFSET = 10
local FRAME_DATA_START = 0
local SNAP_ANCHOR_GAP = 30
local resizeButton

local function isFrameSuppressed()
    return not APR.settings.profile.showQuestOrderList or not APR.settings.profile.enableAddon or
        APR:IsPetBattleActive() or not APR:IsInstanceWithUI()
end

local function canRenderSteps()
    return not isFrameSuppressed() and APR.RouteQuestStepList[APR.ActiveRoute] and APR.routeconfig:HasRouteInCustomPaht()
end

local function buildLayout(scrollChild)
    return {
        scrollChild = scrollChild or QuestOrderListFrame_ScrollChild,
        frameWidth = math.max(1, FRAME_WIDTH - 22),
        signatureParts = { tostring(FRAME_WIDTH) },
        frameOffset = FRAME_OFFSET,
        dataHeight = FRAME_DATA_START
    }
end

local function isStepVisible(step, sojournerSkipActive)
    return APR:StepFilterQoL(step) and not (sojournerSkipActive and APR:IsStepCampaignQuest(step))
end

local function getVisibilityState(steps, sojournerSkipActive)
    local state = {}
    for rawIndex, step in ipairs(steps or {}) do
        state[rawIndex] = isStepVisible(step, sojournerSkipActive) and "1" or "0"
    end
    return table.concat(state)
end

local function isSnapEnabled()
    return APR.settings.profile.questOrderListSnapToCurrentStep
end

function APR.questOrderList:IsSnapped()
    return isSnapEnabled() and getSnapAnchor() ~= nil
end

getSnapAnchor = function()
    if not isSnapEnabled() then
        return nil
    end

    local currentStepPanel = _G.CurrentStepScreenPanel
    if not currentStepPanel or not currentStepPanel:IsShown() or currentStepPanel.collapsed then
        return nil
    end

    -- Use centralized snap anchor logic from Core
    -- Hierarchy: Fillers (highest) -> AFK (medium) -> CurrentStep (lowest)
    local anchorFrame, anchorHeight = APR:GetSnapAnchorFrame()
    return anchorFrame, anchorHeight
end

snapToAnchor = function(anchorFrame, anchorHeight)
    if not anchorFrame or not QuestOrderListPanel then
        APR.questOrderList.snapAnchor = nil
        return false
    end

    local effectiveHeight = (anchorHeight and anchorHeight > 0) and anchorHeight or (anchorFrame:GetHeight() or 0)
    local owner = APR.questOrderList
    local scale = anchorFrame:GetScale() or 1
    if owner.snapAnchor == anchorFrame and owner.snapHeight == effectiveHeight and
        QuestOrderListPanel:GetScale() == scale then return true end
    -- Use centralized snap positioning helper (no header adjustment for QuestOrderList)
    local anchored = APR:SnapFrameToAnchor(QuestOrderListPanel, anchorFrame, effectiveHeight, SNAP_ANCHOR_GAP, nil)
    if anchored then owner.snapAnchor, owner.snapHeight = anchorFrame, effectiveHeight end
    return anchored
end

updateSnapSizing = function(anchored, anchorFrame)
    if not QuestOrderListFrame then
        return
    end

    if anchored and anchorFrame then
        QuestOrderListFrame:SetResizable(true)
        if resizeButton then
            resizeButton:Show()
            resizeButton:EnableMouse(true)
        end
        if QuestOrderListFrame_StepHolderHeader and QuestOrderListFrame_StepHolderHeader.MinimizeButton then
            QuestOrderListFrame_StepHolderHeader.MinimizeButton:Hide()
        end

        local anchorWidth = anchorFrame:GetWidth()
        if anchorWidth and anchorWidth > 0 then
            local maxHeight = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 2000
            if QuestOrderListFrame:GetWidth() ~= anchorWidth then QuestOrderListFrame:SetWidth(anchorWidth) end
            -- Keep width in sync with the parent while still allowing the user to resize height.
            QuestOrderListFrame:SetResizeBounds(anchorWidth, FRAME_MIN_HEIGHT, anchorWidth, maxHeight)
        end
    else
        QuestOrderListFrame:SetResizeBounds(FRAME_MIN_WIDTH, FRAME_MIN_HEIGHT)
        QuestOrderListFrame:SetResizable(true)
        if resizeButton then
            resizeButton:Show()
            resizeButton:EnableMouse(true)
        end
        if QuestOrderListFrame_StepHolderHeader and QuestOrderListFrame_StepHolderHeader.MinimizeButton then
            QuestOrderListFrame_StepHolderHeader.MinimizeButton:Show()
        end
    end
end

---------------------------------------------------------------------------------------
---------------------------- Quest Order List Frames ----------------------------------
---------------------------------------------------------------------------------------

QuestOrderListFrame = APR:CreateStandardFrame("QuestOrderListPanel", UIParent, FRAME_WIDTH, FRAME_HEIGHT,
    "BackdropTemplate")

QuestOrderListFrame:SetResizable(true)
QuestOrderListFrame:SetResizeBounds(FRAME_MIN_WIDTH, FRAME_MIN_HEIGHT)
APR:SetupFrameDrag(QuestOrderListFrame, function()
    return not APR.settings.profile.questOrderListSnapToCurrentStep and not APR.settings.profile.questOrderListLock
end, function()
    LibWindow.SavePosition(QuestOrderListPanel)
end)
QuestOrderListFrame:SetScript("OnSizeChanged", function(self, width, height)
    local widthChanged = FRAME_WIDTH ~= width
    FRAME_WIDTH = width
    FRAME_HEIGHT = height
    QuestOrderListFrame_StepHolder:SetSize(width, height)
    if widthChanged then APR.questOrderList:UpdateFrameContents() end
    if not APR.questOrderList:IsSnapped() then
        LibWindow.SavePosition(QuestOrderListPanel)
    end
end)

-- Create the step holder frame
QuestOrderListFrame_StepHolder = CreateFrame("Frame", "QuestOrderListFrame_StepHolder", QuestOrderListFrame,
    "BackdropTemplate")
QuestOrderListFrame_StepHolder:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
QuestOrderListFrame_StepHolder:SetAllPoints()

-- Create a scroll frame for the step holder
QuestOrderListFrame_ScrollFrame = CreateFrame("ScrollFrame", "QuestOrderListFrame_ScrollFrame",
    QuestOrderListFrame_StepHolder, "UIPanelScrollFrameTemplate")
QuestOrderListFrame_ScrollFrame:SetPoint("TOPLEFT", QuestOrderListFrame_StepHolder, "TOPLEFT", 0, 0)
QuestOrderListFrame_ScrollFrame:SetPoint("BOTTOMRIGHT", QuestOrderListFrame_StepHolder, "BOTTOMRIGHT", -22, 0)

-- Create a child frame for the scroll frame
QuestOrderListFrame_ScrollChild = CreateFrame("Frame", "QuestOrderListFrame_ScrollChild",
    QuestOrderListFrame_ScrollFrame)
QuestOrderListFrame_ScrollChild:SetSize(FRAME_WIDTH, 1)
QuestOrderListFrame_ScrollFrame:SetScrollChild(QuestOrderListFrame_ScrollChild)

-- Create the frame header
QuestOrderListFrame_StepHolderHeader = APR:CreateFrameHeader("QuestOrderListFrame_StepHolderHeader",
    QuestOrderListFrame, L["QUEST_ORDER_LIST"], "ObjectiveTrackerContainerHeaderTemplate", "questOrderList")
QuestOrderListFrame_StepHolderHeader:SetPoint("TOPLEFT", QuestOrderListFrame, "TOPLEFT", 0, 30)

APR:SetupHeaderDrag(QuestOrderListFrame_StepHolderHeader, QuestOrderListFrame, function()
    return not APR.settings.profile.questOrderListLock and not APR.settings.profile.questOrderListSnapToCurrentStep
end, function()
    LibWindow.SavePosition(QuestOrderListPanel)
end)

APR:SetupMinimizeButton(QuestOrderListFrame_StepHolderHeader, QuestOrderListFrame, function()
    -- Collapse
    QuestOrderListFrame_StepHolder:Hide()
    APR.questOrderList:UpdateBackgroundColorAlpha({ 0, 0, 0, 0 })
end, function()
    -- Expand
    QuestOrderListFrame_StepHolder:Show()
    APR.questOrderList:UpdateBackgroundColorAlpha()
    APR.questOrderList:AddStepFromRoute(true)
end, "ui-questtrackerbutton-collapse-all", "ui-questtrackerbutton-expand-all")


resizeButton = CreateFrame("Button", "QuestOrderListFrameResizeHandle", QuestOrderListFrame)
resizeButton:SetSize(16, 16)
resizeButton:SetPoint("BOTTOMRIGHT", QuestOrderListFrame, "BOTTOMRIGHT", -15, -2)
resizeButton:EnableMouse(true)
resizeButton:SetNormalTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Down")

resizeButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        QuestOrderListFrame:StartSizing("BOTTOMRIGHT")
    end
end)
resizeButton:SetScript("OnMouseUp", function(self, button)
    QuestOrderListFrame:StopMovingOrSizing()
    LibWindow.SavePosition(QuestOrderListPanel)
end)

---------------------------------------------------------------------------------------
-------------------------- Function Quest Order List Frames ---------------------------
---------------------------------------------------------------------------------------

-- Initialize the Quest Order List frame
function APR.questOrderList:QuestOrderListFrameOnInit()
    LibWindow.RegisterConfig(QuestOrderListPanel, APR.settings.profile.questOrderListFrame)
    QuestOrderListPanel.RegisteredForLibWindow = true
    QuestOrderListFrame.collapsed = false
    QuestOrderListFrame_StepHolderHeader:Show()
    QuestOrderListFrame_StepHolder:Show()
    self.currentStepIndex = nil
    self:RefreshFrameAnchor()
end

function APR.questOrderList:ApplySnapAnchor()
    if not QuestOrderListFrame or not QuestOrderListPanel then
        return false
    end
    local anchorFrame, anchorHeight = getSnapAnchor()
    local anchored = snapToAnchor(anchorFrame, anchorHeight)
    updateSnapSizing(anchored, anchorFrame)

    -- When snapped to Current Step, force expanded state for readability.
    if anchored and QuestOrderListFrame.collapsed and QuestOrderListFrame_StepHolderHeader and
        QuestOrderListFrame_StepHolderHeader.MinimizeButton then
        QuestOrderListFrame_StepHolderHeader.MinimizeButton:Click()
    end

    return anchored
end

function APR.questOrderList:RefreshFrameAnchor()
    if isFrameSuppressed() then
        QuestOrderListPanel:Hide()
        return
    end
    if isSnapEnabled() then
        local currentStepPanel = _G.CurrentStepScreenPanel
        if currentStepPanel and currentStepPanel.collapsed then
            QuestOrderListPanel:Hide()
            return
        end
    end
    QuestOrderListFrame:EnableMouse(not APR.settings.profile.questOrderListLock)

    self:UpdateFrameScale()
    self:UpdateBackgroundColorAlpha()

    local anchored = self:ApplySnapAnchor()

    if not anchored then
        LibWindow.RestorePosition(QuestOrderListPanel)
    end

    QuestOrderListPanel:Show()
    self:AddStepFromRoute(true)
end

-- Reset the frame position
function APR.questOrderList:ResetPosition()
    self.snapAnchor = nil
    QuestOrderListPanel:ClearAllPoints()
    QuestOrderListPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    LibWindow.SavePosition(QuestOrderListPanel)
    QuestOrderListPanel:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    APR.questOrderList:UpdateBackgroundColorAlpha()
end

-- Update the frame scale
function APR.questOrderList:UpdateFrameScale()
    LibWindow.SetScale(QuestOrderListPanel, APR.settings.profile.questOrderListScale)
end

function APR.questOrderList:UpdateBackgroundColorAlpha(color)
    QuestOrderListFrame:SetBackdropColor(unpack(color or APR.settings.profile.questOrderListbackgroundColorAlpha))
end

-- Remove all quest steps
function APR.questOrderList:RemoveSteps(hideFrame)
    local profileStart = APR:StartPerformanceSample()
    QuestOrderListUtils:CancelRender(self)
    QuestOrderListUtils:CancelScroll(QuestOrderListFrame_ScrollFrame)
    if self.updateTimer then self.updateTimer:Cancel(); self.updateTimer = nil end
    self.pendingUpdate = false
    self.contentSignature = nil
    self.currentStepIndex = nil
    self.currentRouteKey = nil
    self.renderComplete = false
    self.visibilityState = nil
    wipe(self.rawStepContainers)
    for _, questContainer in pairs(self.stepList) do
        QuestOrderListUtils:ReleaseStepFrame(questContainer)
    end
    wipe(self.stepList)
    if self.renderBuffer then
        for _, row in pairs(self.renderBuffer.stepList) do QuestOrderListUtils:ReleaseStepFrame(row) end
        wipe(self.renderBuffer.stepList)
        wipe(self.renderBuffer.rawStepContainers)
    end
    QuestOrderListFrame_ScrollChild:SetHeight(1)
    QuestOrderListFrame_ScrollFrame:SetVerticalScroll(0)
    if hideFrame ~= false then
        QuestOrderListFrame:Hide()
    end
    APR:FinishPerformanceSample("QuestOrderListRelease", profileStart)
end

function APR.questOrderList:AdvanceRenderedStep(currentStepIndex, visibilityState)
    local previousStepIndex = self.currentStepIndex
    local currentContainer = self.rawStepContainers[currentStepIndex]
    if not previousStepIndex or currentStepIndex <= previousStepIndex or not currentContainer then
        return false
    end

    local layoutChanged = false
    for rawIndex = previousStepIndex, currentStepIndex - 1 do
        local container = self.rawStepContainers[rawIndex]
        if container then
            QuestOrderListUtils:SetStepFrameState(container, "green", false)
            if container.collapseWhenPassed then
                layoutChanged = QuestOrderListUtils:CollapseStepDetails(container) or layoutChanged
            end
        end
    end

    self.currentStepIndex = currentStepIndex
    self.visibilityState = visibilityState
    QuestOrderListUtils:SetCurrentStepIndicator(self.stepList, QuestOrderListFrame_ScrollFrame,
        currentContainer.displayIndex)
    if layoutChanged then self:UpdateFrameContents() end
    return true
end

function APR.questOrderList:UpdateFrameContents()
    -- Width/font changes share the budgeted renderer instead of synchronously
    -- measuring every route row for each mouse movement during a resize.
    self.contentSignature = nil
    self:DelayedUpdate(true)
end

function APR.questOrderList:AddStepFromRoute(forceRendering)
    if not canRenderSteps() then
        self:RemoveSteps()
        APR.questOrderList.questID = nil
        return
    end
    if isSnapEnabled() then
        local currentStepPanel = _G.CurrentStepScreenPanel
        if currentStepPanel and currentStepPanel.collapsed then
            QuestOrderListPanel:Hide()
            return
        end
        self:ApplySnapAnchor()
    end

    APR:Debug("Function: APR.questOrderList:AddStepFromRoute - ", APR.ActiveRoute)

    local currentStepIndex = APRData[APR.PlayerID][APR.ActiveRoute]
    if not currentStepIndex then
        return
    end

    local routeKey = APR.ActiveRoute
    local pending = self.renderRequest
    if not forceRendering and pending and pending.route == routeKey and pending.index == currentStepIndex and
        pending.width == FRAME_WIDTH then return end
    if pending then QuestOrderListUtils:CancelRender(self) end
    local activeRouteSteps = APR:GetRouteSteps(routeKey)
    local sojournerSkipActive = APR:IsSojournerSkipActive()

    -- Compare the current step index with the stored one
    if self.currentRouteKey == routeKey and not forceRendering and not self.renderFailed then
        if currentStepIndex == self.currentStepIndex then return end

        if self.renderComplete and currentStepIndex > (self.currentStepIndex or currentStepIndex) then
            local visibilityState = getVisibilityState(activeRouteSteps, sojournerSkipActive)
            if visibilityState == self.visibilityState and
                self:AdvanceRenderedStep(currentStepIndex, visibilityState) then
                self.contentSignature = nil
                return
            end
        end
    end

    -- Prepare a second scroll child while the published list remains readable.
    QuestOrderListUtils:CancelRender(self)
    local target = self.renderBuffer
    if not target then
        target = { scrollChild = CreateFrame("Frame", nil, QuestOrderListFrame_ScrollFrame),
            stepList = {}, rawStepContainers = {} }
        target.scrollChild:Hide()
        self.renderBuffer = target
    end
    target.visibilityParts, target.questID = {}, nil
    local layout = buildLayout(target.scrollChild)
    target.scrollChild:SetWidth(layout.frameWidth)
    local renderRows = self:CreateRouteRenderer(layout, activeRouteSteps, currentStepIndex, target)
    local function worker()
        -- Recycling is budgeted too; cancelling halfway cannot pool a row twice.
        for index, row in pairs(target.stepList) do
            QuestOrderListUtils:ReleaseStepFrame(row)
            target.stepList[index] = nil
            coroutine.yield()
        end
        wipe(target.rawStepContainers)
        renderRows()
    end
    local playerID = APR.PlayerID
    local request = { route = routeKey, index = currentStepIndex, width = FRAME_WIDTH }
    QuestOrderListUtils:StartRender(self, worker, function()
        if not canRenderSteps() then
            self:RemoveSteps()
            return false
        end
        if APR.ActiveRoute ~= routeKey or APRData[playerID][routeKey] ~= currentStepIndex or
            FRAME_WIDTH ~= request.width then
            self:DelayedUpdate(true)
            return false
        end
        return true
    end, function(finished)
        if not finished then return end
        local signature = table.concat(layout.signatureParts, "|")
        local visibilityState = table.concat(target.visibilityParts)
        self.reputationState = QuestOrderListUtils:GetReputationStateSignature(activeRouteSteps)
        if self.currentRouteKey == routeKey and self.currentStepIndex == currentStepIndex and
            self.contentSignature == signature and self.visibilityState == visibilityState then
            return
        end
        local followStep = self.currentRouteKey ~= routeKey or self.currentStepIndex ~= currentStepIndex
        QuestOrderListUtils:CancelScroll(QuestOrderListFrame_ScrollFrame)
        local scrollOffset = QuestOrderListFrame_ScrollFrame:GetVerticalScroll()
        target.scrollChild:SetHeight(math.max(1, -layout.dataHeight))
        local previous = { scrollChild = QuestOrderListFrame_ScrollChild, stepList = self.stepList,
            rawStepContainers = self.rawStepContainers }
        local tooltipOwner = GameTooltip:GetOwner()
        if tooltipOwner and tooltipOwner:GetParent() == previous.scrollChild then GameTooltip:Hide() end
        previous.scrollChild:Hide()
        QuestOrderListFrame_ScrollChild = target.scrollChild
        QuestOrderListFrame_ScrollFrame:SetScrollChild(target.scrollChild)
        target.scrollChild:Show()
        self.stepList, self.rawStepContainers = target.stepList, target.rawStepContainers
        self.renderBuffer = previous
        self.currentStepIndex, self.currentRouteKey = currentStepIndex, routeKey
        self.questID, self.contentSignature = target.questID, signature
        self.renderComplete, self.visibilityState = true, visibilityState
        local parentCollapsed = isSnapEnabled() and _G.CurrentStepScreenPanel and _G.CurrentStepScreenPanel.collapsed
        if not parentCollapsed then QuestOrderListPanel:Show() end
        if target.currentDisplayIndex then
            QuestOrderListUtils:SetCurrentStepIndicator(self.stepList, QuestOrderListFrame_ScrollFrame,
                target.currentDisplayIndex, followStep)
        end
        if not followStep then
            QuestOrderListFrame_ScrollFrame:SetVerticalScroll(math.min(scrollOffset,
                QuestOrderListFrame_ScrollFrame:GetVerticalScrollRange()))
        end
    end)
    self.renderRequest = request
end

function APR.questOrderList:DelayedUpdate(forceRendering)
    self.pendingUpdate = self.pendingUpdate or forceRendering == true
    if self.updateTimer then return end
    -- Render once after a burst of quest/step changes has settled.
    self.updateTimer = C_Timer.NewTimer(0.1, function()
        self.updateTimer = nil
        local force = self.pendingUpdate
        self.pendingUpdate = false
        self:AddStepFromRoute(force)
    end)
end
