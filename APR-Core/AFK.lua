local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")
local candy = LibStub("LibCandyBar-3.0")

-- Initialize module
APR.AFK = APR:NewModule("AFK")

APR.AFK.lastStep = nil
APR.AFK.defaultSnapHeight = 20
APR.AFK.fakeTimerActive = false
APR.AFK.lastSizeWidth = nil
APR.AFK.lastSizeHeight = nil
APR.AFK.lastFillersRefresh = 0
APR.AFK.isSnapped = false

local FRAME_WIDTH = 250
local FRAME_HEIGHT = 30
local FILLERS_REFRESH_THROTTLE = 0.15

---------------------------------------------------------------------------------------
----------------------------------- AFK Frames ----------------------------------------
---------------------------------------------------------------------------------------

local AfkFrame = CreateFrame("Frame", "AfkFrameScreen", UIParent, "BackdropTemplate")
AfkFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
AfkFrame:SetFrameStrata("LOW")
AfkFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
AfkFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 16
})
AfkFrame:SetBackdropColor(unpack(APR.Color.defaultBackdrop))

local bar = candy:New("Interface\\TargetingFrame\\UI-StatusBar", FRAME_WIDTH, FRAME_HEIGHT)
bar:SetLabel(L["AFK"])
bar:SetColor(unpack(APR.Color.blue))
bar:SetShadowColor(0, 0, 0, 0.85)
bar:SetPoint("CENTER", AfkFrame)


---------------------------------------------------------------------------------------
-------------------------------- Function AFK Frames ----------------------------------
---------------------------------------------------------------------------------------

function APR.AFK:AFKFrameOnInit()
    APR.settings.profile.afkFrame = APR.settings.profile.afkFrame or {}

    LibWindow.RegisterConfig(AfkFrameScreen, APR.settings.profile.afkFrame)
    AfkFrameScreen.RegisteredForLibWindow = true
    LibWindow.MakeDraggable(AfkFrameScreen)

    -- Do not force RestorePosition if no point has been saved yet
    if APR.settings.profile.afkFrame.point then
        LibWindow.RestorePosition(AfkFrameScreen)
    end
    AfkFrameScreen:EnableMouse(true)
    AfkFrameScreen:Hide()

    local function onStop()
        AfkFrameScreen:Hide()
        APR.AFK.fakeTimerActive = false
        if APR.currentStep and APR.currentStep.RefreshFillersFrame then
            APR.currentStep:RefreshFillersFrame()
        end
        if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
            APR.questOrderList:ApplySnapAnchor()
        end
    end
    candy:RegisterCallback("LibCandyBar_Stop", onStop)

    APR.AFK.eventFrame = CreateFrame("Frame")
    APR.AFK.TaxiTimerRecorder = APR.AFK.eventFrame:CreateAnimationGroup()
    APR.AFK.TaxiTimerRecorder.anim = APR.AFK.TaxiTimerRecorder:CreateAnimation()
    APR.AFK.TaxiTimerRecorder.anim:SetDuration(1)
    APR.AFK.TaxiTimerRecorder:SetLooping("REPEAT")
    APR.AFK.TaxiTimerRecorder:SetScript("OnLoop", function(self, event, ...)
        if (UnitOnTaxi("player")) then
            local taxiPath = APR.transport.CurrentTaxiNode.name .. "-" .. APR.transport.StepTaxiNode.name
            if not APRTaxiNodesTimer[taxiPath] then
                APRTaxiNodesTimer[taxiPath] = 1
            end
            APRTaxiNodesTimer[taxiPath] = APRTaxiNodesTimer[taxiPath] + 1
        else
            APR.AFK.TaxiTimerRecorder:Stop()
        end
    end)

    APR.AFK:UpdateBarColor()
    APR.AFK:RefreshFrameAnchor(true)
end

function APR.AFK:SetAfkTimer(duration)
    if not APR.settings.profile.enableAddon then
        bar:Stop()
        AfkFrameScreen:Hide()
        return
    end
    APR.AFK:RefreshFrameAnchor()
    AfkFrameScreen:Show()
    bar:SetDuration(duration)
    bar:Start()
    if APR.currentStep and APR.currentStep.RefreshFillersFrame then
        APR.currentStep:RefreshFillersFrame()
    end
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
end

function APR.AFK:HideFrame()
    bar:Stop()
    AfkFrameScreen:Hide()
    self.fakeTimerActive = false
    if APR.currentStep and APR.currentStep.RefreshFillersFrame then
        APR.currentStep:RefreshFillersFrame()
    end
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
end

function APR.AFK:UpdateBarColor()
    local color = APR.settings.profile.afkBarColor or { APR.Color.blue[1], APR.Color.blue[2], APR.Color.blue[3], 1 }
    bar:SetColor(color[1], color[2], color[3], color[4])
end

function APR.AFK:UpdateSize(width, height)
    local w = width or APR.settings.profile.afkWidth or FRAME_WIDTH
    local h = height or APR.settings.profile.afkHeight or FRAME_HEIGHT

    local sizeChanged = (self.lastSizeWidth ~= w) or (self.lastSizeHeight ~= h)
    self.lastSizeWidth = w
    self.lastSizeHeight = h

    AfkFrame:SetSize(w, h)
    AfkFrameScreen:SetSize(w, h)
    bar:SetWidth(w)
    bar:SetHeight(h)

    if sizeChanged
        and APR.settings.profile.afkSnapToCurrentStep
        and APR.currentStep
        and APR.currentStep.RefreshFillersFrame then
        local now = GetTime()
        if now - (self.lastFillersRefresh or 0) >= FILLERS_REFRESH_THROTTLE then
            self.lastFillersRefresh = now
            APR.currentStep:RefreshFillersFrame()
        end
    end
end

function APR.AFK:RefreshFrameAnchor(initial)
    local currentStepPanel = _G.CurrentStepScreenPanel
    local wasSnapped = self.isSnapped

    if APR.settings.profile.afkSnapToCurrentStep and currentStepPanel then
        self.isSnapped = true
        local scale = currentStepPanel:GetScale() or 1
        local width = currentStepPanel:GetWidth() or FRAME_WIDTH
        local configuredHeight = APR.settings.profile.afkHeight or FRAME_HEIGHT
        if configuredHeight == FRAME_HEIGHT then
            configuredHeight = self.defaultSnapHeight or FRAME_HEIGHT
        end
        local afkHeight = configuredHeight
        local contentHeight = APR.currentStep and APR.currentStep.GetContentHeight
            and APR.currentStep:GetContentHeight(false) or 0

        local anchorHeight = (contentHeight > 0 and contentHeight) or (currentStepPanel:GetHeight() or FRAME_HEIGHT)

        AfkFrameScreen:ClearAllPoints()
        AfkFrameScreen:SetScale(scale)
        AfkFrameScreen:SetPoint("TOP", currentStepPanel, "TOP", 0, -anchorHeight)
        AfkFrameScreen:EnableMouse(false)
        self:UpdateSize(width, afkHeight)
    else
        self.isSnapped = false
        AfkFrameScreen:SetScale(1)
        self:UpdateSize()
        if not initial
            and AfkFrameScreen.RegisteredForLibWindow
            and APR.settings.profile.afkFrame
            and APR.settings.profile.afkFrame.point then
            LibWindow.RestorePosition(AfkFrameScreen)
        end
        if not APR.settings.profile.currentStepLock then
            AfkFrameScreen:EnableMouse(true)
        end
    end

    if wasSnapped ~= self.isSnapped
        and APR.currentStep
        and APR.currentStep.RefreshFillersFrame then
        APR.currentStep:RefreshFillersFrame()
    end

    self:UpdateBarColor()
    if not initial and APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
end

function APR.AFK:ToggleFakeTimer()
    if self.fakeTimerActive then
        self.fakeTimerActive = false
        bar:Stop()
        return
    end

    if not APR.settings.profile.enableAddon then
        return
    end

    self.fakeTimerActive = true
    self:SetAfkTimer(300)
end

function APR.AFK:ResetPosition()
    if APR.settings.profile.afkSnapToCurrentStep then
        return
    end
    AfkFrameScreen:ClearAllPoints()
    AfkFrameScreen:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    LibWindow.SavePosition(AfkFrameScreen)
end
