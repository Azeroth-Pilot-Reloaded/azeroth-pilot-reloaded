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

--- Helper function to safely refresh child frames after AFK changes
--- Verifies addon is still enabled before refreshing
---@return void
function APR.AFK:RefreshChildFrames()
    -- Safety check: verify addon is still enabled (fix for race condition)
    if not APR.settings or not APR.settings.profile or not APR.settings.profile.enableAddon then
        return
    end

    if APR.fillersFrame and APR.fillersFrame.RefreshFillersFrame then
        APR.fillersFrame:RefreshFillersFrame()
    end
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
end

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
        -- Wait a frame to ensure the frame is properly hidden before refreshing children
        -- Addon enabled check is done in RefreshChildFrames
        C_Timer.After(0, function()
            APR.AFK:RefreshChildFrames()
        end)
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
    local profile = APR:GetSettingsProfile()
    if not profile or not profile.enableAddon then
        bar:Stop()
        AfkFrameScreen:Hide()

        -- When AFK hides due to addon disabled, refresh child frames after a frame delay
        C_Timer.After(0, function()
            APR.AFK:RefreshChildFrames()
        end)
        return
    end
    local wasHidden = not AfkFrameScreen:IsShown()
    APR.AFK:RefreshFrameAnchor()
    AfkFrameScreen:Show()
    bar:SetDuration(duration)
    bar:Start()

    -- If AFK just appeared, refresh all child frames
    if wasHidden then
        C_Timer.After(0, function()
            APR.AFK:RefreshChildFrames()
        end)
    end
end

function APR.AFK:HideFrame()
    bar:Stop()
    AfkFrameScreen:Hide()
    self.fakeTimerActive = false

    -- Wait a frame to ensure the frame is properly hidden before refreshing children
    C_Timer.After(0, function()
        APR.AFK:RefreshChildFrames()
    end)
end

function APR.AFK:UpdateBarColor()
    local profile = APR:GetSettingsProfile()
    local color = (profile and profile.afkBarColor) or { APR.Color.blue[1], APR.Color.blue[2], APR.Color.blue[3], 1 }
    bar:SetColor(color[1], color[2], color[3], color[4])
end

function APR.AFK:UpdateSize(width, height)
    local profile = APR:GetSettingsProfile()
    local w = width or (profile and profile.afkWidth) or FRAME_WIDTH
    local h = height or (profile and profile.afkHeight) or FRAME_HEIGHT

    local sizeChanged = (self.lastSizeWidth ~= w) or (self.lastSizeHeight ~= h)
    self.lastSizeWidth = w
    self.lastSizeHeight = h

    AfkFrame:SetSize(w, h)
    AfkFrameScreen:SetSize(w, h)
    bar:SetWidth(w)
    bar:SetHeight(h)

    if sizeChanged
        and profile
        and profile.afkSnapToCurrentStep
        and APR.currentStep
        and APR.currentStep.RefreshFillersFrame then
        local now = GetTime()
        if now - (self.lastFillersRefresh or 0) >= FILLERS_REFRESH_THROTTLE then
            self.lastFillersRefresh = now
            APR.fillersFrame:RefreshFillersFrame()
        end
    end
end

function APR.AFK:RefreshFrameAnchor(initial)
    local profile = APR:GetSettingsProfile()
    if not profile then return end

    local currentStepPanel = _G.CurrentStepScreenPanel
    local wasSnapped = self.isSnapped

    if profile.afkSnapToCurrentStep and currentStepPanel then
        self.isSnapped = true
        local width = currentStepPanel:GetWidth() or FRAME_WIDTH
        local configuredHeight = APR.settings.profile.afkHeight or FRAME_HEIGHT
        if configuredHeight == FRAME_HEIGHT then
            configuredHeight = self.defaultSnapHeight or FRAME_HEIGHT
        end
        local afkHeight = configuredHeight
        local contentHeight = APR.currentStep and APR.currentStep.GetContentHeight
            and APR.currentStep:GetContentHeight(false) or 0

        local anchorHeight = (contentHeight > 0 and contentHeight) or (currentStepPanel:GetHeight() or FRAME_HEIGHT)

        -- Use centralized snap positioning helper (no header adjustment for AFK)
        APR:SnapFrameToAnchor(AfkFrameScreen, currentStepPanel, anchorHeight, 0, nil)
        AfkFrameScreen:EnableMouse(false)
        self:UpdateSize(width, afkHeight)
    else
        self.isSnapped = false
        AfkFrameScreen:SetScale(1)
        self:UpdateSize()
        if not initial
            and AfkFrameScreen.RegisteredForLibWindow
            and profile.afkFrame
            and profile.afkFrame.point then
            LibWindow.RestorePosition(AfkFrameScreen)
        end
        if not profile.currentStepLock then
            AfkFrameScreen:EnableMouse(true)
        end
    end

    if wasSnapped ~= self.isSnapped
        and APR.currentStep
        and APR.currentStep.RefreshFillersFrame then
        APR.fillersFrame:RefreshFillersFrame()
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

    local profile = APR:GetSettingsProfile()
    if not profile or not profile.enableAddon then
        return
    end

    self.fakeTimerActive = true
    self:SetAfkTimer(300)
end

function APR.AFK:ResetPosition()
    local profile = APR:GetSettingsProfile()
    if not profile or profile.afkSnapToCurrentStep then
        return
    end
    AfkFrameScreen:ClearAllPoints()
    AfkFrameScreen:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    LibWindow.SavePosition(AfkFrameScreen)
end
