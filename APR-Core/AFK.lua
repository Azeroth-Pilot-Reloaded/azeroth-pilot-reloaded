local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")
local candy = LibStub("LibCandyBar-3.0")

-- Initialize APR Party  module
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
    AfkFrame:Hide()

    local function onStop()
        AfkFrame:Hide()
    end
    candy:RegisterCallback("LibCandyBar_Stop", onStop)
end

function APR.AFK:SetAfkTimer(duration)
    if not APR.settings.profile.enableAddon then
        bar:Stop()
        AfkFrame:Hide()
        return
    end
    AfkFrame:Show()
    bar:SetDuration(duration)
    bar:Start()
end

function APR.AFK:HideFrame()
    AfkFrame:Hide()
end
