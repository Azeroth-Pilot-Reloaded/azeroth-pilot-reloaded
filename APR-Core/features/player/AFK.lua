local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

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

local bar = APR:CreateStatusBar(AfkFrame, nil, "afk", "afkBarColor")
bar:SetAllPoints()
bar.Text:ClearAllPoints()
bar.Text:SetPoint("TOPLEFT", 2, 0)
bar.Text:SetPoint("BOTTOMRIGHT", -2, 0)
bar.Text:SetJustifyH("LEFT")
bar.Text:SetText(L["AFK"])
bar.Duration = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bar.Duration:SetPoint("TOPLEFT", 2, 0)
bar.Duration:SetPoint("BOTTOMRIGHT", -2, 0)
bar.Duration:SetJustifyH("RIGHT")
APR:RegisterFontString(bar.Duration, "afk", { role = "base" })
for _, font in ipairs({ bar.Text, bar.Duration }) do
    font:SetShadowColor(0, 0, 0, 0.85)
end
bar:Hide()

local function UpdateCountdown(frame)
    local remaining = math.max(0, APR.AFK.timerEnd - GetTime())
    frame:SetValue(remaining)
    if remaining <= 0 then
        APR.AFK:HideFrame()
    elseif remaining > 3599.9 then
        local hours = math.floor(remaining / 3600)
        frame.Duration:SetFormattedText("%d:%02d:%02d", hours, math.floor(remaining / 60) % 60,
            math.floor(remaining) % 60)
    elseif remaining > 59.9 then
        frame.Duration:SetFormattedText("%d:%02d", math.floor(remaining / 60), math.floor(remaining) % 60)
    else
        frame.Duration:SetFormattedText(remaining < 10 and "%.1f" or "%.0f", remaining)
    end
end

local function OnTimerUpdate(frame, elapsed)
    APR.AFK.timerElapsed = APR.AFK.timerElapsed + elapsed
    if APR.AFK.timerElapsed < 0.04 then return end
    APR.AFK.timerElapsed = 0
    UpdateCountdown(frame)
end


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

    APR.AFK.eventFrame = CreateFrame("Frame")
    APR.AFK.TaxiTimerRecorder = APR.AFK.eventFrame:CreateAnimationGroup()
    APR.AFK.TaxiTimerRecorder.anim = APR.AFK.TaxiTimerRecorder:CreateAnimation()
    APR.AFK.TaxiTimerRecorder.anim:SetDuration(1)
    APR.AFK.TaxiTimerRecorder:SetLooping("REPEAT")
    APR.AFK.TaxiTimerRecorder:SetScript("OnLoop", function(self, event, ...)
        if (UnitOnTaxi("player")) then
            local taxiPath = APR.flightPath.CurrentTaxiNode.name .. "-" .. APR.flightPath.StepTaxiNode.name
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
    if not profile or not profile.enableAddon or type(duration) ~= "number" or duration <= 0
        or duration ~= duration or duration == math.huge then
        self:HideFrame()
        return
    end
    local wasHidden = not AfkFrameScreen:IsShown()
    APR.AFK:RefreshFrameAnchor()
    self.timerEnd = GetTime() + duration
    self.timerElapsed = 0
    bar:SetMinMaxValues(0, duration)
    bar:SetScript("OnUpdate", OnTimerUpdate)
    bar:Show()
    AfkFrameScreen:Show()
    UpdateCountdown(bar)

    -- If AFK just appeared, refresh all child frames
    if wasHidden then
        C_Timer.After(0, function()
            APR.AFK:RefreshChildFrames()
        end)
    end
end

function APR.AFK:HideFrame()
    bar:SetScript("OnUpdate", nil)
    bar:Hide()
    bar:SetValue(0)
    bar.Duration:SetText("")
    self.timerEnd = nil
    self.timerElapsed = 0
    AfkFrameScreen:Hide()
    self.fakeTimerActive = false

    -- Wait a frame to ensure the frame is properly hidden before refreshing children
    C_Timer.After(0, function()
        APR.AFK:RefreshChildFrames()
    end)
end

function APR.AFK:UpdateBarColor()
    APR:RefreshStatusBarColors("afkBarColor")
end

function APR.AFK:UpdateSize(width, height)
    local profile = APR:GetSettingsProfile()
    local w = width or (profile and profile.afkWidth) or FRAME_WIDTH
    local h = height or (profile and profile.afkHeight) or FRAME_HEIGHT

    local sizeChanged = (self.lastSizeWidth ~= w) or (self.lastSizeHeight ~= h)
    self.lastSizeWidth = w
    self.lastSizeHeight = h

    AfkFrame:SetSize(w, h)

    if sizeChanged
        and profile
        and profile.afkSnapToCurrentStep
        and APR.fillersFrame
        and APR.fillersFrame.RefreshFillersFrame then
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
        and APR.fillersFrame
        and APR.fillersFrame.RefreshFillersFrame then
        APR.fillersFrame:RefreshFillersFrame()
    end

    self:UpdateBarColor()
    if not initial and APR.questOrderList and APR.questOrderList.ApplySnapAnchor then
        APR.questOrderList:ApplySnapAnchor()
    end
end

function APR.AFK:ToggleFakeTimer()
    if self.fakeTimerActive then
        self:HideFrame()
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
