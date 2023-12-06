local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")
local candy = LibStub("LibCandyBar-3.0")

-- Initialize module
APR.AFK = APR:NewModule("AFK")

local FRAME_WIDTH = 250
local FRAME_HEIGHT = 30

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
AfkFrame:SetBackdropColor(0, 0, 0, 0.75)

local bar = candy:New("Interface\\TargetingFrame\\UI-StatusBar", FRAME_WIDTH, FRAME_HEIGHT)
bar:SetLabel(L["AFK"])
bar:SetColor(0, 87 / 255, 183 / 255, 1)
bar:SetShadowColor(0, 0, 0, 0.85)
bar:SetPoint("CENTER", AfkFrame)


---------------------------------------------------------------------------------------
-------------------------------- Function AFK Frames ----------------------------------
---------------------------------------------------------------------------------------

function APR.AFK:AFKFrameOnInit()
    LibWindow.RegisterConfig(AfkFrameScreen, APR.settings.profile.afkFrame)
    AfkFrameScreen.RegisteredForLibWindow = true
    LibWindow.MakeDraggable(AfkFrameScreen)
    LibWindow.RestorePosition(AfkFrameScreen)
    AfkFrameScreen:EnableMouse(true)
    AfkFrameScreen:Hide()

    local function onStop()
        AfkFrameScreen:Hide()
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
end

function APR.AFK:SetAfkTimer(duration)
    if not APR.settings.profile.enableAddon then
        bar:Stop()
        AfkFrameScreen:Hide()
        return
    end
    AfkFrameScreen:Show()
    bar:SetDuration(duration)
    bar:Start()
end

function APR.AFK:HideFrame()
    AfkFrameScreen:Hide()
end
