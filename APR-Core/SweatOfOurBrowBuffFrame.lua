local L = LibStub("AceLocale-3.0"):GetLocale("APR")

local function APR_SweatOfOurBrowBuffFrame()
    -- TODO REWORK SweatOfOurBrowBuffFrame
    APR.SweatOfOurBrowBuffFrame = CreateFrame("frame", "APR_SugQuestFrameFramebufffra", UIParent)
    APR.SweatOfOurBrowBuffFrame:SetWidth(230)
    APR.SweatOfOurBrowBuffFrame:SetHeight(110)
    APR.SweatOfOurBrowBuffFrame:SetMovable(true)
    APR.SweatOfOurBrowBuffFrame:EnableMouse(true)
    APR.SweatOfOurBrowBuffFrame:SetFrameStrata("LOW")
    APR.SweatOfOurBrowBuffFrame:SetPoint("TOPLEFT", UIParent, 300, -300)
    --APR.SweatOfOurBrowBuffFrame:SetBackdrop( {
    --	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    --	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    --	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
    --});
    APR.SweatOfOurBrowBuffFrame:Hide()
    local t = APR.SweatOfOurBrowBuffFrame:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.SweatOfOurBrowBuffFrame)
    APR.SweatOfOurBrowBuffFrame.texture = t

    APR.SweatOfOurBrowBuffFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            APR.SweatOfOurBrowBuffFrame:StartMoving();
            APR.SweatOfOurBrowBuffFrame.isMoving = true;
        end
    end)
    APR.SweatOfOurBrowBuffFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and APR.SweatOfOurBrowBuffFrame.isMoving then
            APR.SweatOfOurBrowBuffFrame:StopMovingOrSizing();
            APR.SweatOfOurBrowBuffFrame.isMoving = false;
        end
    end)
    APR.SweatOfOurBrowBuffFrame:SetScript("OnHide", function(self)
        if (APR.SweatOfOurBrowBuffFrame.isMoving) then
            APR.SweatOfOurBrowBuffFrame:StopMovingOrSizing();
            APR.SweatOfOurBrowBuffFrame.isMoving = false;
        end
    end)
    APR.SweatOfOurBrowBuffFrame.FS1 = APR.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS1", "ARTWORK", "ChatFontNormal")
    APR.SweatOfOurBrowBuffFrame.FS1:SetParent(APR.SweatOfOurBrowBuffFrame)
    APR.SweatOfOurBrowBuffFrame.FS1:SetPoint("TOPLEFT", APR.SweatOfOurBrowBuffFrame, "TOPLEFT", 5, 0)
    APR.SweatOfOurBrowBuffFrame.FS1:SetWidth(300)
    APR.SweatOfOurBrowBuffFrame.FS1:SetHeight(38)
    APR.SweatOfOurBrowBuffFrame.FS1:SetJustifyH("LEFT")
    APR.SweatOfOurBrowBuffFrame.FS1:SetFontObject("GameFontNormal")
    APR.SweatOfOurBrowBuffFrame.FS1:SetText(L["NEDD_BUFF_DISARM_TRAP"])
    APR.SweatOfOurBrowBuffFrame.FS1:SetTextColor(1, 1, 0)

    APR.SweatOfOurBrowBuffFrame.Traps = CreateFrame("frame", "APR_SugQuestFrameFramebufffraTraps",
        APR.SweatOfOurBrowBuffFrame)
    APR.SweatOfOurBrowBuffFrame.Traps:SetWidth(220)
    APR.SweatOfOurBrowBuffFrame.Traps:SetHeight(18)
    APR.SweatOfOurBrowBuffFrame.Traps:SetMovable(true)
    APR.SweatOfOurBrowBuffFrame.Traps:EnableMouse(true)
    APR.SweatOfOurBrowBuffFrame.Traps:SetFrameStrata("LOW")
    APR.SweatOfOurBrowBuffFrame.Traps:SetPoint("TOPLEFT", APR.SweatOfOurBrowBuffFrame, "TOPLEFT", 2,
        -40)
    local t = APR.SweatOfOurBrowBuffFrame.Traps:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetAllPoints(APR.SweatOfOurBrowBuffFrame.Traps)
    t:SetColorTexture(0.5, 0.1, 0.1, 1)
    APR.SweatOfOurBrowBuffFrame.Traps.texture = t

    APR.SweatOfOurBrowBuffFrame.FS2 = APR.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS2", "ARTWORK", "ChatFontNormal")
    APR.SweatOfOurBrowBuffFrame.FS2:SetParent(APR.SweatOfOurBrowBuffFrame.Traps)
    APR.SweatOfOurBrowBuffFrame.FS2:SetPoint("LEFT", APR.SweatOfOurBrowBuffFrame.Traps, "LEFT", 5, 0)
    APR.SweatOfOurBrowBuffFrame.FS2:SetWidth(300)
    APR.SweatOfOurBrowBuffFrame.FS2:SetHeight(38)
    APR.SweatOfOurBrowBuffFrame.FS2:SetJustifyH("LEFT")
    APR.SweatOfOurBrowBuffFrame.FS2:SetFontObject("GameFontNormalSmall")
    APR.SweatOfOurBrowBuffFrame.FS2:SetText(L["SOULWEB_TRAP"])
    APR.SweatOfOurBrowBuffFrame.FS2:SetTextColor(1, 1, 0)

    APR.SweatOfOurBrowBuffFrame.FS21 = APR.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS21", "ARTWORK", "ChatFontNormal")
    APR.SweatOfOurBrowBuffFrame.FS21:SetParent(APR.SweatOfOurBrowBuffFrame.Traps)
    APR.SweatOfOurBrowBuffFrame.FS21:SetPoint("LEFT", APR.SweatOfOurBrowBuffFrame.Traps, "LEFT", 85,
        0)
    APR.SweatOfOurBrowBuffFrame.FS21:SetWidth(300)
    APR.SweatOfOurBrowBuffFrame.FS21:SetHeight(38)
    APR.SweatOfOurBrowBuffFrame.FS21:SetJustifyH("LEFT")
    APR.SweatOfOurBrowBuffFrame.FS21:SetFontObject("GameFontNormalSmall")
    APR.SweatOfOurBrowBuffFrame.FS21:SetText(L["FRESHLEAF_BUFF"])
    APR.SweatOfOurBrowBuffFrame.FS21:SetTextColor(1, 1, 0)
    APR.SweatOfOurBrowBuffFrame.Traps2 = CreateFrame("frame", "APR_SugQuestFrameFramebufffraTraps2",
        APR.SweatOfOurBrowBuffFrame)
    APR.SweatOfOurBrowBuffFrame.Traps2:SetWidth(220)
    APR.SweatOfOurBrowBuffFrame.Traps2:SetHeight(18)
    APR.SweatOfOurBrowBuffFrame.Traps2:SetMovable(true)
    APR.SweatOfOurBrowBuffFrame.Traps2:EnableMouse(true)
    APR.SweatOfOurBrowBuffFrame.Traps2:SetPoint("TOPLEFT", APR.SweatOfOurBrowBuffFrame, "TOPLEFT", 2,
        -60)
    local t = APR.SweatOfOurBrowBuffFrame.Traps2:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetAllPoints(APR.SweatOfOurBrowBuffFrame.Traps2)
    t:SetColorTexture(0.5, 0.1, 0.1, 1)
    APR.SweatOfOurBrowBuffFrame.Traps2.texture = t
    APR.SweatOfOurBrowBuffFrame.FS3 = APR.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS3", "ARTWORK", "ChatFontNormal")
    APR.SweatOfOurBrowBuffFrame.FS3:SetParent(APR.SweatOfOurBrowBuffFrame.Traps2)
    APR.SweatOfOurBrowBuffFrame.FS3:SetPoint("LEFT", APR.SweatOfOurBrowBuffFrame.Traps2, "LEFT", 5, 0)
    APR.SweatOfOurBrowBuffFrame.FS3:SetWidth(300)
    APR.SweatOfOurBrowBuffFrame.FS3:SetHeight(38)
    APR.SweatOfOurBrowBuffFrame.FS3:SetJustifyH("LEFT")
    APR.SweatOfOurBrowBuffFrame.FS3:SetFontObject("GameFontNormalSmall")
    APR.SweatOfOurBrowBuffFrame.FS3:SetText(L["HARP_TRAP"])
    APR.SweatOfOurBrowBuffFrame.FS3:SetTextColor(1, 1, 0)
    APR.SweatOfOurBrowBuffFrame.FS31 = APR.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS31", "ARTWORK", "ChatFontNormal")
    APR.SweatOfOurBrowBuffFrame.FS31:SetParent(APR.SweatOfOurBrowBuffFrame.Traps2)
    APR.SweatOfOurBrowBuffFrame.FS31:SetPoint("LEFT", APR.SweatOfOurBrowBuffFrame.Traps2, "LEFT", 85,
        0)
    APR.SweatOfOurBrowBuffFrame.FS31:SetWidth(300)
    APR.SweatOfOurBrowBuffFrame.FS31:SetHeight(38)
    APR.SweatOfOurBrowBuffFrame.FS31:SetJustifyH("LEFT")
    APR.SweatOfOurBrowBuffFrame.FS31:SetFontObject("GameFontNormalSmall")
    APR.SweatOfOurBrowBuffFrame.FS31:SetText(L["GOSSAMER_THREAD_BUFF"])
    APR.SweatOfOurBrowBuffFrame.FS31:SetTextColor(1, 1, 0)
    APR.SweatOfOurBrowBuffFrame.Traps3 = CreateFrame("frame", "APR_SugQuestFrameFramebufffraTraps3",
        APR.SweatOfOurBrowBuffFrame)
    APR.SweatOfOurBrowBuffFrame.Traps3:SetWidth(220)
    APR.SweatOfOurBrowBuffFrame.Traps3:SetHeight(18)
    APR.SweatOfOurBrowBuffFrame.Traps3:SetMovable(true)
    APR.SweatOfOurBrowBuffFrame.Traps3:EnableMouse(true)
    APR.SweatOfOurBrowBuffFrame.Traps3:SetPoint("TOPLEFT", APR.SweatOfOurBrowBuffFrame, "TOPLEFT", 2,
        -80)
    local t = APR.SweatOfOurBrowBuffFrame.Traps3:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetAllPoints(APR.SweatOfOurBrowBuffFrame.Traps3)
    t:SetColorTexture(0.5, 0.1, 0.1, 1)
    APR.SweatOfOurBrowBuffFrame.Traps3.texture = t
    APR.SweatOfOurBrowBuffFrame.FS4 = APR.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS4", "ARTWORK", "ChatFontNormal")
    APR.SweatOfOurBrowBuffFrame.FS4:SetParent(APR.SweatOfOurBrowBuffFrame.Traps3)
    APR.SweatOfOurBrowBuffFrame.FS4:SetPoint("LEFT", APR.SweatOfOurBrowBuffFrame.Traps3, "LEFT", 5, 0)
    APR.SweatOfOurBrowBuffFrame.FS4:SetWidth(300)
    APR.SweatOfOurBrowBuffFrame.FS4:SetHeight(38)
    APR.SweatOfOurBrowBuffFrame.FS4:SetJustifyH("LEFT")
    APR.SweatOfOurBrowBuffFrame.FS4:SetFontObject("GameFontNormalSmall")
    APR.SweatOfOurBrowBuffFrame.FS4:SetText(L["UNTOUCHED_BASKET"])
    APR.SweatOfOurBrowBuffFrame.FS4:SetTextColor(1, 1, 0)
    APR.SweatOfOurBrowBuffFrame.FS41 = APR.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS41", "ARTWORK", "ChatFontNormal")
    APR.SweatOfOurBrowBuffFrame.FS41:SetParent(APR.SweatOfOurBrowBuffFrame.Traps3)
    APR.SweatOfOurBrowBuffFrame.FS41:SetPoint("LEFT", APR.SweatOfOurBrowBuffFrame.Traps3, "LEFT", 85,
        0)
    APR.SweatOfOurBrowBuffFrame.FS41:SetWidth(300)
    APR.SweatOfOurBrowBuffFrame.FS41:SetHeight(38)
    APR.SweatOfOurBrowBuffFrame.FS41:SetJustifyH("LEFT")
    APR.SweatOfOurBrowBuffFrame.FS41:SetFontObject("GameFontNormalSmall")
    APR.SweatOfOurBrowBuffFrame.FS41:SetText(L["SHUMMERDUST_BUFF"])
    APR.SweatOfOurBrowBuffFrame.FS41:SetTextColor(1, 1, 0)
end

APREventFrame = CreateFrame("Frame")
APREventFrame:RegisterEvent("ADDON_LOADED")
APREventFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "ADDON_LOADED") then
        local arg1, arg2, arg3, arg4, arg5 = ...;
        if (arg1 == "APR-Core") then
            APR_SweatOfOurBrowBuffFrame()
        end
    end
end)
