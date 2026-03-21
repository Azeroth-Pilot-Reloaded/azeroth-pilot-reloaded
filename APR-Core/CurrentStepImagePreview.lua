local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local _G = _G

APR.currentStepImagePreview = APR:NewModule("CurrentStepImagePreview")

local ApplyOverlayTextureLayout = nil
local GetPreviewTextureAspectRatio = nil
local overlayWindows = {}
local overlayPool = {}
local overlayWindowCount = 0

local currentStepFrameHolder = nil
local currentStepFrameWidth = 250
local OVERLAY_TEXTURE_PADDING = 12
local OVERLAY_PANEL_DEFAULT_WIDTH = 720
local OVERLAY_PANEL_DEFAULT_HEIGHT = 430
local OVERLAY_PANEL_MIN_WIDTH = 420
local OVERLAY_PANEL_MIN_HEIGHT = 250
local OVERLAY_PANEL_MAX_WIDTH = 1400
local OVERLAY_PANEL_MAX_HEIGHT = 1000
local OVERLAY_ZOOM_MIN = 1
local OVERLAY_ZOOM_MAX = 3
local OVERLAY_ZOOM_STEP = 0.1

local function Clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function GetCursorPositionInUiScale()
    local scale = UIParent and UIParent:GetEffectiveScale() or 1
    local cursorX, cursorY = GetCursorPosition()
    return cursorX / scale, cursorY / scale
end

local function StopOverlayPanning(window)
    if not window then
        return
    end

    window.isPanning = false
    window.panLastCursorX = nil
    window.panLastCursorY = nil
    if window.panUpdater then
        window.panUpdater:SetScript("OnUpdate", nil)
    end
end

local function ReturnWindowToPool(window)
    if not window or window.isPooled then
        return
    end

    window.isPooled = true
    StopOverlayPanning(window)
    window.zoomLevel = OVERLAY_ZOOM_MIN
    window.imageAspectRatio = nil
    window.panOffsetX = 0
    window.panOffsetY = 0
    if window.panel then
        window.panel:SetScript("OnUpdate", nil)
        overlayWindows[window.panel] = nil
    end
    if window.texture and window.texture.SetTexture then
        window.texture:SetTexture(nil)
    end
    table.insert(overlayPool, window)
end

local function CloseAllOverlayWindows()
    local toClose = {}
    for panel in pairs(overlayWindows) do
        table.insert(toClose, panel)
    end
    for _, panel in ipairs(toClose) do
        if panel and panel.Hide then
            panel:Hide()
        end
    end
end

local STEP_PREVIEW_CONTAINER_KEY = "05_STEP_PREVIEW_IMAGES"
local STEP_PREVIEW_GAP = 4
local STEP_PREVIEW_SIDE_PADDING = 10
local STEP_PREVIEW_HORIZONTAL_PADDING = 12
local STEP_PREVIEW_VERTICAL_PADDING = 8
local STEP_PREVIEW_MAX_PER_ROW = 4
local STEP_PREVIEW_DEFAULT_ASPECT_RATIO = 16 / 9
local STEP_PREVIEW_MIN_HEIGHT = 52
local STEP_PREVIEW_MAX_HEIGHT = 88
local STEP_PREVIEW_MIN_WIDTH = 52
local STEP_PREVIEW_MAX_WIDTH = 156

local function StartOverlayTextureAspectRatioProbe(window)
    if not window or not window.panel then
        return
    end

    local retries = 0
    window.panel:SetScript("OnUpdate", function(self)
        local canReadTexture = window.texture and
            ((not window.texture.IsObjectLoaded) or window.texture:IsObjectLoaded())
        if canReadTexture then
            local loadedAspectRatio = GetPreviewTextureAspectRatio and GetPreviewTextureAspectRatio(window.texture)
            if loadedAspectRatio then
                window.imageAspectRatio = loadedAspectRatio
                self:SetScript("OnUpdate", nil)
            else
                retries = retries + 1
                if retries > 120 then
                    self:SetScript("OnUpdate", nil)
                end
            end

            if ApplyOverlayTextureLayout then
                ApplyOverlayTextureLayout(window)
            end
        end
    end)
end

local function CreateOverlayWindow(imagePath)
    if not imagePath then
        return nil
    end

    local window
    if #overlayPool > 0 then
        window = table.remove(overlayPool)
        window.isPooled = false
    else
        overlayWindowCount = overlayWindowCount + 1
        local slotIndex = overlayWindowCount
        local panelName = "APRCurrentStepImagePreviewFrame" .. slotIndex
        local panel = CreateFrame("Frame", panelName, UIParent, "BackdropTemplate")
        local offset = ((slotIndex - 1) % 8) * 18
        panel:SetSize(OVERLAY_PANEL_DEFAULT_WIDTH, OVERLAY_PANEL_DEFAULT_HEIGHT)
        panel:SetPoint("CENTER", UIParent, "CENTER", offset, -offset)
        panel:SetFrameStrata("DIALOG")
        panel:SetFrameLevel(900 + ((slotIndex - 1) % 40))
        panel:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        panel:SetBackdropColor(0.04, 0.04, 0.04, 0.96)
        panel:EnableMouse(true)
        panel:SetMovable(true)
        panel:SetResizable(true)
        if panel.SetResizeBounds then
            panel:SetResizeBounds(
                OVERLAY_PANEL_MIN_WIDTH,
                OVERLAY_PANEL_MIN_HEIGHT,
                OVERLAY_PANEL_MAX_WIDTH,
                OVERLAY_PANEL_MAX_HEIGHT
            )
        elseif panel.SetMinResize and panel.SetMaxResize then
            panel:SetMinResize(OVERLAY_PANEL_MIN_WIDTH, OVERLAY_PANEL_MIN_HEIGHT)
            panel:SetMaxResize(OVERLAY_PANEL_MAX_WIDTH, OVERLAY_PANEL_MAX_HEIGHT)
        end
        panel:SetClipsChildren(true)
        panel:RegisterForDrag("LeftButton")

        window = {
            panel = panel,
            texture = nil,
            zoomLevel = OVERLAY_ZOOM_MIN,
            imageAspectRatio = nil,
            isSizing = false,
            isPooled = false,
            resizeCenterX = nil,
            resizeCenterY = nil,
            panUpdater = nil,
            panOffsetX = 0,
            panOffsetY = 0,
            panLastCursorX = nil,
            panLastCursorY = nil,
            isPanning = false,
        }

        panel:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        panel:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
        end)
        panel:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()
            window.isSizing = false
            window.resizeCenterX = nil
            window.resizeCenterY = nil
            StopOverlayPanning(window)
        end)
        panel:EnableMouseWheel(true)
        panel:SetScript("OnMouseWheel", function(_, delta)
            if delta > 0 then
                window.zoomLevel = Clamp(window.zoomLevel + OVERLAY_ZOOM_STEP, OVERLAY_ZOOM_MIN, OVERLAY_ZOOM_MAX)
            else
                window.zoomLevel = Clamp(window.zoomLevel - OVERLAY_ZOOM_STEP, OVERLAY_ZOOM_MIN, OVERLAY_ZOOM_MAX)
            end

            if ApplyOverlayTextureLayout then
                ApplyOverlayTextureLayout(window)
            end
        end)

        panel:SetScript("OnMouseDown", function(_, button)
            -- Right-click drag pans inside the image while zoomed.
            if button == "RightButton" and (window.zoomLevel or OVERLAY_ZOOM_MIN) > OVERLAY_ZOOM_MIN then
                window.isPanning = true
                window.panLastCursorX, window.panLastCursorY = GetCursorPositionInUiScale()

                local panUpdater = window.panUpdater
                if panUpdater and panUpdater.SetScript then
                    panUpdater:SetScript("OnUpdate", function()
                        if not window.isPanning then
                            return
                        end

                        local cursorX, cursorY = GetCursorPositionInUiScale()
                        local deltaX = cursorX - (window.panLastCursorX or cursorX)
                        local deltaY = cursorY - (window.panLastCursorY or cursorY)

                        window.panLastCursorX = cursorX
                        window.panLastCursorY = cursorY
                        window.panOffsetX = window.panOffsetX + deltaX
                        window.panOffsetY = window.panOffsetY + deltaY

                        if ApplyOverlayTextureLayout then
                            ApplyOverlayTextureLayout(window)
                        end
                    end)
                end
            end
        end)

        window.panUpdater = CreateFrame("Frame", nil, panel)

        local texture = panel:CreateTexture(nil, "ARTWORK")
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetPoint("CENTER", panel, "CENTER", 0, 0)
        window.texture = texture

        panel:SetScript("OnSizeChanged", function()
            if window.isSizing and window.resizeCenterX and window.resizeCenterY then
                panel:ClearAllPoints()
                panel:SetPoint("CENTER", UIParent, "BOTTOMLEFT", window.resizeCenterX, window.resizeCenterY)
            end

            if ApplyOverlayTextureLayout then
                ApplyOverlayTextureLayout(window)
            end
        end)

        local resizeHandle = CreateFrame("Button", nil, panel)
        resizeHandle:SetSize(18, 18)
        resizeHandle:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6, 6)
        local resizeTexture = resizeHandle:CreateTexture(nil, "OVERLAY")
        resizeTexture:SetAllPoints(resizeHandle)
        resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight", "ADD")
        resizeHandle:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                window.resizeCenterX, window.resizeCenterY = panel:GetCenter()
                window.isSizing = true
                panel:StartSizing("BOTTOMRIGHT")
            end
        end)
        resizeHandle:SetScript("OnMouseUp", function()
            panel:StopMovingOrSizing()
            window.isSizing = false
            window.resizeCenterX = nil
            window.resizeCenterY = nil
        end)

        local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, -2)
        closeButton:SetFrameStrata("FULLSCREEN_DIALOG")
        closeButton:SetFrameLevel((panel:GetFrameLevel() or 1) + 20)
        closeButton:SetScript("OnClick", function()
            panel:Hide()
        end)

        -- OnHide handles both close-button clicks and Escape-key (UISpecialFrames).
        panel:SetScript("OnHide", function(self)
            self:SetScript("OnUpdate", nil)
            ReturnWindowToPool(window)
        end)

        -- Register each frame name exactly once, the first time its slot is created.
        APR:RegisterUiSpecialFrame(panelName)
    end

    -- Reset per-use state before showing.
    window.zoomLevel = OVERLAY_ZOOM_MIN
    window.imageAspectRatio = nil
    window.panOffsetX = 0
    window.panOffsetY = 0
    window.isSizing = false
    window.resizeCenterX = nil
    window.resizeCenterY = nil

    local texture = window.texture
    if not texture or not texture.SetTexture or not texture.GetTexture then
        ReturnWindowToPool(window)
        return nil
    end

    texture:SetTexture(imagePath)
    if not texture:GetTexture() then
        ReturnWindowToPool(window)
        return nil
    end

    window.imageAspectRatio = GetPreviewTextureAspectRatio and GetPreviewTextureAspectRatio(texture)
    overlayWindows[window.panel] = window
    StartOverlayTextureAspectRatioProbe(window)

    if ApplyOverlayTextureLayout then
        ApplyOverlayTextureLayout(window)
    end

    return window
end

function APR.currentStepImagePreview:Show(imagePath)
    if not imagePath then
        return
    end

    local window = CreateOverlayWindow(imagePath)
    if window and window.panel then
        window.panel:Show()
    end
end

function APR.currentStepImagePreview:ConfigureCurrentStepPreview(stepHolder, frameWidth)
    currentStepFrameHolder = stepHolder
    currentStepFrameWidth = frameWidth or currentStepFrameWidth
end

local function ClampPreviewDimension(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

GetPreviewTextureAspectRatio = function(texture)
    if not texture then
        return nil
    end

    local width = texture.GetTextureFileWidth and texture:GetTextureFileWidth() or 0
    local height = texture.GetTextureFileHeight and texture:GetTextureFileHeight() or 0
    if width and height and width > 0 and height > 0 then
        return width / height
    end

    return nil
end

local function ResolvePreviewAspectRatio(texture)
    return GetPreviewTextureAspectRatio(texture) or STEP_PREVIEW_DEFAULT_ASPECT_RATIO
end

ApplyOverlayTextureLayout = function(window)
    if not window or not window.panel or not window.texture or not window.texture:GetTexture() then
        return
    end

    local overlayPanel = window.panel
    local overlayTexture = window.texture

    local availableWidth = math.max((overlayPanel:GetWidth() or 0) - (OVERLAY_TEXTURE_PADDING * 2), 1)
    local availableHeight = math.max((overlayPanel:GetHeight() or 0) - (OVERLAY_TEXTURE_PADDING * 2), 1)
    local aspectRatio = window.imageAspectRatio or ResolvePreviewAspectRatio(overlayTexture)

    local targetWidth = availableWidth
    local targetHeight = math.floor(targetWidth / aspectRatio)

    if targetHeight > availableHeight then
        targetHeight = availableHeight
        targetWidth = math.floor(targetHeight * aspectRatio)
    end

    local zoom = window.zoomLevel or OVERLAY_ZOOM_MIN
    targetWidth = math.floor(targetWidth * zoom)
    targetHeight = math.floor(targetHeight * zoom)

    local maxPanX = math.max((targetWidth - availableWidth) / 2, 0)
    local maxPanY = math.max((targetHeight - availableHeight) / 2, 0)
    window.panOffsetX = Clamp(window.panOffsetX or 0, -maxPanX, maxPanX)
    window.panOffsetY = Clamp(window.panOffsetY or 0, -maxPanY, maxPanY)

    overlayTexture:ClearAllPoints()
    overlayTexture:SetSize(targetWidth, targetHeight)
    overlayTexture:SetPoint("CENTER", overlayPanel, "CENTER", window.panOffsetX, window.panOffsetY)
end

local function BuildPreviewLayoutMetrics(availableWidth, count, aspectRatios)
    local safeCount = math.max(count or 0, 1)
    local totalGap = math.max(safeCount - 1, 0) * STEP_PREVIEW_GAP
    local targetHeight = ClampPreviewDimension(
        math.floor((availableWidth - totalGap) / (safeCount * STEP_PREVIEW_DEFAULT_ASPECT_RATIO)),
        STEP_PREVIEW_MIN_HEIGHT,
        STEP_PREVIEW_MAX_HEIGHT
    )

    local widths = {}
    local totalWidth = totalGap
    for index = 1, safeCount do
        local aspectRatio = aspectRatios[index] or STEP_PREVIEW_DEFAULT_ASPECT_RATIO
        local width = ClampPreviewDimension(
            math.floor(targetHeight * aspectRatio),
            STEP_PREVIEW_MIN_WIDTH,
            STEP_PREVIEW_MAX_WIDTH
        )
        widths[index] = width
        totalWidth = totalWidth + width
    end

    if totalWidth > availableWidth and totalWidth > 0 then
        local scale = availableWidth / totalWidth
        totalWidth = totalGap
        for index = 1, safeCount do
            local scaledWidth = ClampPreviewDimension(
                math.floor(widths[index] * scale),
                STEP_PREVIEW_MIN_WIDTH,
                STEP_PREVIEW_MAX_WIDTH
            )
            widths[index] = scaledWidth
            totalWidth = totalWidth + scaledWidth
        end

        if totalWidth > availableWidth then
            local overflow = totalWidth - availableWidth
            for index = safeCount, 1, -1 do
                if overflow <= 0 then
                    break
                end
                local reducible = math.max(widths[index] - STEP_PREVIEW_MIN_WIDTH, 0)
                if reducible > 0 then
                    local delta = math.min(reducible, overflow)
                    widths[index] = widths[index] - delta
                    totalWidth = totalWidth - delta
                    overflow = overflow - delta
                end
            end
        end
    end

    return {
        height = targetHeight,
        widths = widths,
        totalWidth = totalWidth,
    }
end

local function ComputePreviewRowSizes(previewCount)
    if previewCount <= STEP_PREVIEW_MAX_PER_ROW then
        return { previewCount }
    end

    local rowCount = math.ceil(previewCount / STEP_PREVIEW_MAX_PER_ROW)
    local baseSize = math.floor(previewCount / rowCount)
    local remainder = previewCount - (baseSize * rowCount)
    local rowSizes = {}

    for index = 1, rowCount do
        rowSizes[index] = baseSize
    end

    for index = rowCount - remainder + 1, rowCount do
        rowSizes[index] = rowSizes[index] + 1
    end

    return rowSizes
end

local function ApplyPreviewButtonLayout(container)
    if not container or not container.previewButtons then
        return
    end

    local availableWidth = currentStepFrameWidth - (STEP_PREVIEW_SIDE_PADDING * 2) -
        (STEP_PREVIEW_HORIZONTAL_PADDING * 2)
    local aspectRatios = {}
    for index, button in ipairs(container.previewButtons) do
        aspectRatios[index] = ResolvePreviewAspectRatio(button.previewTexture)
    end

    local rowWidthOrigin = STEP_PREVIEW_SIDE_PADDING + STEP_PREVIEW_HORIZONTAL_PADDING
    local totalHeight = STEP_PREVIEW_VERTICAL_PADDING * 2
    local currentOffsetY = STEP_PREVIEW_VERTICAL_PADDING
    local previewCount = #container.previewButtons

    local rowSizes = ComputePreviewRowSizes(previewCount)
    local rowStart = 1
    for rowIndex = 1, #rowSizes do
        local rowEnd = rowStart + rowSizes[rowIndex] - 1
        local rowAspectRatios = {}
        local localIndex = 1
        for index = rowStart, rowEnd do
            rowAspectRatios[localIndex] = aspectRatios[index]
            localIndex = localIndex + 1
        end

        local metrics = BuildPreviewLayoutMetrics(availableWidth, rowEnd - rowStart + 1, rowAspectRatios)
        local rowStartX = rowWidthOrigin + math.floor((availableWidth - metrics.totalWidth) / 2)
        local currentOffsetX = rowStartX
        local widthIndex = 1

        for index = rowStart, rowEnd do
            local button = container.previewButtons[index]
            local width = metrics.widths[widthIndex]
            button:ClearAllPoints()
            button:SetSize(width, metrics.height)
            button:SetPoint("TOPLEFT", container, "TOPLEFT", currentOffsetX, -currentOffsetY)
            currentOffsetX = currentOffsetX + width + STEP_PREVIEW_GAP
            widthIndex = widthIndex + 1
        end

        totalHeight = totalHeight + metrics.height
        currentOffsetY = currentOffsetY + metrics.height + STEP_PREVIEW_GAP
        rowStart = rowEnd + 1
    end

    if #rowSizes > 1 then
        totalHeight = totalHeight + ((#rowSizes - 1) * STEP_PREVIEW_GAP)
    end

    container:SetHeight(totalHeight)
end

function APR.currentStepImagePreview:ClearPreviewImages(currentStep)
    if not currentStep then
        return
    end

    -- Step changes should close all opened enlarged image windows.
    CloseAllOverlayWindows()

    local existingContainer = currentStep.questsList[STEP_PREVIEW_CONTAINER_KEY]
    if not existingContainer then
        return
    end

    if currentStep:CanSafelyHide(existingContainer) then
        if existingContainer.previewButtons then
            for _, button in ipairs(existingContainer.previewButtons) do
                button:SetScript("OnUpdate", nil)
                button:SetScript("OnClick", nil)
                button:SetScript("OnEnter", nil)
                button:SetScript("OnLeave", nil)
            end
        end

        existingContainer:SetScript("OnEnter", nil)
        existingContainer:SetScript("OnLeave", nil)
        existingContainer:ClearAllPoints()
        existingContainer:Hide()
        currentStep:ResetSecureStepButton(existingContainer, STEP_PREVIEW_CONTAINER_KEY)
        currentStep:ResetSecureRaidIconButton(existingContainer, STEP_PREVIEW_CONTAINER_KEY)
    else
        currentStep:SoftHide(existingContainer)
        table.insert(currentStep.pendingContainerDestroy, existingContainer)
    end

    currentStep.questsList[STEP_PREVIEW_CONTAINER_KEY] = nil
    currentStep:ReOrderQuestSteps(true)
end

function APR.currentStepImagePreview:SetPreviewImages(currentStep, step)
    if not currentStep or not APR.settings.profile.currentStepShow then
        return
    end

    if type(step) ~= "table" or type(step.PreviewImages) ~= "table" then
        self:ClearPreviewImages(currentStep)
        return
    end

    local imagePaths = APR:NormalizePreviewImages(step)
    if #imagePaths == 0 then
        self:ClearPreviewImages(currentStep)
        return
    end

    local existingContainer = currentStep.questsList[STEP_PREVIEW_CONTAINER_KEY]
    if existingContainer and APR:AreOrderedStringListsEqual(existingContainer.imagePaths, imagePaths) then
        return
    end

    if existingContainer then
        self:ClearPreviewImages(currentStep)
    end

    if not currentStepFrameHolder then
        return
    end

    local container = CreateFrame("Frame", nil, currentStepFrameHolder, "BackdropTemplate")
    container:SetWidth(currentStepFrameWidth)
    container:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        tile = true,
        tileSize = 16
    })
    container:SetBackdropColor(unpack(APR.settings.profile.currentStepbackgroundColorAlpha or APR.Color.defaultBackdrop))
    container.key = STEP_PREVIEW_CONTAINER_KEY
    container.imagePaths = imagePaths
    container.previewButtons = {}

    for _, imagePath in ipairs(imagePaths) do
        local button = CreateFrame("Button", nil, container, "BackdropTemplate")
        button:SetBackdrop({
            bgFile = "Interface\\BUTTONS\\WHITE8X8",
            tile = true,
            tileSize = 16,
        })
        button:SetBackdropColor(0.02, 0.02, 0.02, 0.85)

        local texture = button:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints(button)
        texture:SetTexture(imagePath)
        texture:SetTexCoord(0, 1, 0, 1)
        button.previewTexture = texture
        button.imagePath = imagePath
        button:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]], "ADD")
        button:SetScript("OnClick", function()
            APR.currentStepImagePreview:Show(imagePath)
        end)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(L["PREVIEW_IMG"])
            GameTooltip:AddLine(L["ENLARGE_IMG"], 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        button:SetScript("OnUpdate", function(self)
            local canReadTexture = self.previewTexture and
                ((not self.previewTexture.IsObjectLoaded) or self.previewTexture:IsObjectLoaded())
            if canReadTexture then
                local loadedAspectRatio = GetPreviewTextureAspectRatio(self.previewTexture)
                if loadedAspectRatio then
                    self:SetScript("OnUpdate", nil)
                end
                ApplyPreviewButtonLayout(container)
                currentStep:ReOrderQuestSteps(true)
            end
        end)

        table.insert(container.previewButtons, button)
    end

    ApplyPreviewButtonLayout(container)

    currentStep.questsList[STEP_PREVIEW_CONTAINER_KEY] = container
    currentStep:ReOrderQuestSteps(true)
end
