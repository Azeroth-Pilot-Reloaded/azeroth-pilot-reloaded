local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Initialize APR Map module
APR.map = APR:NewModule("MAP")

function APR.map:mapIcon()
    for CLi = 1, 20 do
        APR["Icons"][CLi] = CreateFrame("Frame", nil, UIParent)
        APR["Icons"][CLi]:SetFrameStrata("HIGH")
        APR["Icons"][CLi]:SetWidth(5)
        APR["Icons"][CLi]:SetHeight(5)
        local t = APR["Icons"][CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.blp")
        t:SetAllPoints(APR["Icons"][CLi])
        APR["Icons"][CLi].texture = t
        APR["Icons"][CLi]:SetPoint("CENTER", 0, 0)
        APR["Icons"][CLi]:Hide()
        APR["Icons"][CLi].P = 0
        APR["Icons"][CLi].A = 0
        APR["Icons"][CLi].D = 0
        APR["Icons"][CLi].texture:SetAlpha(APR.settings.profile.miniMapBlobAlpha)

        APR["MapIcons"][CLi] = CreateFrame("Frame", nil, UIParent)
        APR["MapIcons"][CLi]:SetFrameStrata("HIGH")
        APR["MapIcons"][CLi]:SetWidth(5)
        APR["MapIcons"][CLi]:SetHeight(5)
        local t = APR["MapIcons"][CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.blp")
        t:SetAllPoints(APR["MapIcons"][CLi])
        APR["MapIcons"][CLi].texture = t
        APR["MapIcons"][CLi]:SetPoint("CENTER", 0, 0)
        APR["MapIcons"][CLi]:Hide()
        APR["MapIcons"][CLi].P = 0
        APR["MapIcons"][CLi].A = 0
        APR["MapIcons"][CLi].D = 0
    end
end
