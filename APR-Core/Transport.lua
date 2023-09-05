﻿local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.FP = {}
APR.FP.Zonening = 0
local APRLumberCheck = 0

function APR.FP.TestDest()
    APR.FP.TestDestFrame = CreateFrame("frame", "APR.FP.TestDestFramez", UIParent)
    APR.FP.TestDestFrame:SetWidth(200)
    APR.FP.TestDestFrame:SetHeight(190)
    APR.FP.TestDestFrame:SetMovable(true)
    APR.FP.TestDestFrame:EnableMouse(true)
    APR.FP.TestDestFrame:SetFrameStrata("LOW")
    APR.FP.TestDestFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    --APR.FP.TestDestFrame:SetBackdrop( {
    --	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    --	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    --	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
    --});
    local t = APR.FP.TestDestFrame:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.FP.TestDestFrame)
    APR.FP.TestDestFrame.texture = t

    APR.FP.TestDestFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            APR.FP.TestDestFrame:StartMoving();
            APR.FP.TestDestFrame.isMoving = true;
        end
    end)
    APR.FP.TestDestFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and APR.FP.TestDestFrame.isMoving then
            APR.FP.TestDestFrame:StopMovingOrSizing();
            APR.FP.TestDestFrame.isMoving = false;
        end
    end)
    APR.FP.TestDestFrame:SetScript("OnHide", function(self)
        if (APR.FP.TestDestFrame.isMoving) then
            APR.FP.TestDestFrame:StopMovingOrSizing();
            APR.FP.TestDestFrame.isMoving = false;
        end
    end)
    local numbrs = 0
    for APR_index, APR_value in PairsByKeys(APR.TDB["FPs"][APR.Faction]) do
        numbrs = numbrs + 1
        APR.FP.TestDestFrame["F" .. numbrs] = CreateFrame("frame", "TestDestFrames" .. numbrs, APR.FP.TestDestFrame)
        APR.FP.TestDestFrame["F" .. numbrs]:SetWidth(130)
        APR.FP.TestDestFrame["F" .. numbrs]:SetHeight(20)
        --APR.FP.TestDestFrame["F"..numbrs]:SetBackdrop( {
        --	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        --	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        --	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
        --});
        local t = APR.FP.TestDestFrame["F" .. numbrs]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        t:SetAllPoints(APR.FP.TestDestFrame["F" .. numbrs])
        APR.FP.TestDestFrame["F" .. numbrs].texture = t

        APR.FP.TestDestFrame["F" .. numbrs]:SetMovable(true)
        APR.FP.TestDestFrame["F" .. numbrs]:EnableMouse(true)
        APR.FP.TestDestFrame["F" .. numbrs]:SetFrameStrata("LOW")
        APR.FP.TestDestFrame["F" .. numbrs]:SetPoint("TOPLEFT", APR.FP.TestDestFrame, "TOPLEFT", 5, -(numbrs * 20 - 20))
        APR.FP.TestDestFrame["F" .. numbrs]:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                APR.FP.TestDestClick(APR_index)
            else
                APR.FP.TestDestFrame:StartMoving();
                APR.FP.TestDestFrame.isMoving = true;
            end
        end)
        APR.FP.TestDestFrame["F" .. numbrs]:SetScript("OnMouseUp", function(self, button)
            if APR.FP.TestDestFrame.isMoving then
                APR.FP.TestDestFrame:StopMovingOrSizing();
                APR.FP.TestDestFrame.isMoving = false;
            end
        end)
        APR.FP.TestDestFrame["F" .. numbrs]:SetScript("OnHide", function(self)
            if (APR.FP.TestDestFrame.isMoving) then
                APR.FP.TestDestFrame:StopMovingOrSizing();
                APR.FP.TestDestFrame.isMoving = false;
            end
        end)
        APR.FP.TestDestFrame["F" .. numbrs]["FS" .. numbrs] = APR.FP.TestDestFrame["F" .. numbrs]:CreateFontString(
            "TestDestFrameFS" .. numbrs, "ARTWORK", "ChatFontNormal")
        APR.FP.TestDestFrame["F" .. numbrs]["FS" .. numbrs]:SetPoint("TOPLEFT", APR.FP.TestDestFrame["F" .. numbrs],
            "TOPLEFT", 5, 0)
        APR.FP.TestDestFrame["F" .. numbrs]["FS" .. numbrs]:SetWidth(120)
        APR.FP.TestDestFrame["F" .. numbrs]["FS" .. numbrs]:SetHeight(20)
        APR.FP.TestDestFrame["F" .. numbrs]["FS" .. numbrs]:SetJustifyH("LEFT")
        APR.FP.TestDestFrame["F" .. numbrs]["FS" .. numbrs]:SetFontObject("GameFontNormal")
        local zename = C_Map.GetMapInfo(APR_index)
        APR.FP.TestDestFrame["F" .. numbrs]["FS" .. numbrs]:SetText(zename.name)
        APR.FP.TestDestFrame["F" .. numbrs]["FS" .. numbrs]:SetTextColor(1, 1, 0)
    end
    numbrs = 0
    for CLi = 1, 50 do
        numbrs = numbrs + 1
        APR.FP.TestDestFrame["F2" .. numbrs] = CreateFrame("frame", "TestDestFrames2x" .. numbrs, APR.FP.TestDestFrame)
        APR.FP.TestDestFrame["F2" .. numbrs]:SetWidth(130)
        APR.FP.TestDestFrame["F2" .. numbrs]:SetHeight(20)
        --APR.FP.TestDestFrame["F2"..numbrs]:SetBackdrop( {
        --	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        --	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        --	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
        --});
        local t = APR.FP.TestDestFrame["F2" .. numbrs]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        t:SetAllPoints(APR.FP.TestDestFrame["F2" .. numbrs])
        APR.FP.TestDestFrame["F2" .. numbrs].texture = t

        APR.FP.TestDestFrame["F2" .. numbrs]:SetMovable(true)
        APR.FP.TestDestFrame["F2" .. numbrs]:EnableMouse(true)
        APR.FP.TestDestFrame["F2" .. numbrs]:SetFrameStrata("LOW")
        APR.FP.TestDestFrame["F2" .. numbrs]:SetPoint("TOPLEFT", APR.FP.TestDestFrame, "TOPLEFT", 140,
            -(numbrs * 20 - 20))
        APR.FP.TestDestFrame["F2" .. numbrs]:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                APR.FP.TestDestClick2(APR.FP.TestDestFrame["F2" .. CLi]["nr"])
            else
                APR.FP.TestDestFrame:StartMoving();
                APR.FP.TestDestFrame.isMoving = true;
            end
        end)
        APR.FP.TestDestFrame["F2" .. numbrs]:SetScript("OnMouseUp", function(self, button)
            if APR.FP.TestDestFrame.isMoving then
                APR.FP.TestDestFrame:StopMovingOrSizing();
                APR.FP.TestDestFrame.isMoving = false;
            end
        end)
        APR.FP.TestDestFrame["F2" .. numbrs]:SetScript("OnHide", function(self)
            if (APR.FP.TestDestFrame.isMoving) then
                APR.FP.TestDestFrame:StopMovingOrSizing();
                APR.FP.TestDestFrame.isMoving = false;
            end
        end)
        APR.FP.TestDestFrame["F2" .. numbrs]["FS" .. numbrs] = APR.FP.TestDestFrame["F2" .. numbrs]:CreateFontString(
            "TestDestFrameFS" .. numbrs, "ARTWORK", "ChatFontNormal")
        APR.FP.TestDestFrame["F2" .. numbrs]["FS" .. numbrs]:SetPoint("TOPLEFT", APR.FP.TestDestFrame["F2" .. numbrs],
            "TOPLEFT", 5, 0)
        APR.FP.TestDestFrame["F2" .. numbrs]["FS" .. numbrs]:SetWidth(120)
        APR.FP.TestDestFrame["F2" .. numbrs]["FS" .. numbrs]:SetHeight(20)
        APR.FP.TestDestFrame["F2" .. numbrs]["FS" .. numbrs]:SetJustifyH("LEFT")
        APR.FP.TestDestFrame["F2" .. numbrs]["FS" .. numbrs]:SetFontObject("GameFontNormal")
        APR.FP.TestDestFrame["F2" .. numbrs]["FS" .. numbrs]:SetText("")
        APR.FP.TestDestFrame["F2" .. numbrs]["FS" .. numbrs]:SetTextColor(1, 1, 0)
        APR.FP.TestDestFrame["F2" .. numbrs]:Hide()
    end
end

function APR.FP.TestDestClick(Cont)
    for CLi = 1, 50 do
        APR.FP.TestDestFrame["F2" .. CLi]:Hide()
        APR.FP.TestDestFrame["F2" .. CLi]["FS" .. CLi]:SetText("")
    end
    local numbrs = 0
    for APR_index, APR_value in PairsByKeys(APR.TDB["FPs"][APR.Faction][Cont]) do
        numbrs = numbrs + 1
        APR.FP.TestDestFrame["F2" .. numbrs]:Show()
        local zename = C_Map.GetMapInfo(APR_index)
        APR.FP.TestDestFrame["F2" .. numbrs]["FS" .. numbrs]:SetText(zename.name)
        APR.FP.TestDestFrame["F2" .. numbrs]["nr"] = APR_index
    end
end

function APR.FP.TestDestClick2(Zone)
    APR.FP.GoToZone = Zone
    APR.BookingList["GetMeToNextZone"] = 1
    for CLi = 1, 50 do
        APR.FP.TestDestFrame["F2" .. CLi]:Hide()
        APR.FP.TestDestFrame["F2" .. CLi]["FS" .. CLi]:SetText("")
    end
end

function APR.FP.ToyFPs() -- TODO rework map toy
    if (APR.settings.profile.debug) then
        print("Function: APR.FP.ToyFPs()")
    end
    if (APR.Faction == "Alliance") then
        APR.TDB["FPs"]["Horde"] = nil
        APR.TDB["Ports"]["Horde"] = nil
    else
        APR.TDB["FPs"]["Alliance"] = nil
        APR.TDB["Ports"]["Alliance"] = nil
    end
    if (not APR.FP.ToyFrame) then
        if (((PlayerHasToy(150745) or PlayerHasToy(150744)) and APR.Faction == "Horde") or ((PlayerHasToy(150743) or PlayerHasToy(150746)) and APR.Faction == "Alliance")) then
            APR.FP.ToyFrame = CreateFrame("frame", "APR_ToyFramez", UIParent)
            APR.FP.ToyFrame:SetWidth(200)
            APR.FP.ToyFrame:SetHeight(150)
            APR.FP.ToyFrame:SetMovable(true)
            APR.FP.ToyFrame:EnableMouse(true)
            APR.FP.ToyFrame:SetFrameStrata("LOW")
            APR.FP.ToyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            --APR.FP.ToyFrame:SetBackdrop( {
            --	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            --	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            --	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
            --});
            local t = APR.FP.ToyFrame:CreateTexture(nil, "BACKGROUND")
            t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
            t:SetAllPoints(APR.FP.ToyFrame)
            APR.FP.ToyFrame.texture = t

            APR.FP.ToyFrame:SetScript("OnMouseDown", function(self, button)
                if button == "LeftButton" then
                    APR.FP.ToyFrame:StartMoving();
                    APR.FP.ToyFrame.isMoving = true;
                end
            end)
            APR.FP.ToyFrame:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" and APR.FP.ToyFrame.isMoving then
                    APR.FP.ToyFrame:StopMovingOrSizing();
                    APR.FP.ToyFrame.isMoving = false;
                end
            end)
            APR.FP.ToyFrame:SetScript("OnHide", function(self)
                if (APR.FP.ToyFrame.isMoving) then
                    APR.FP.ToyFrame:StopMovingOrSizing();
                    APR.FP.ToyFrame.isMoving = false;
                end
            end)
            APR.FP.ToyFrame.FS1 = APR.FP.ToyFrame:CreateFontString("APRFPToyFrame", "ARTWORK", "ChatFontNormal")
            APR.FP.ToyFrame.FS1:SetParent(APR.FP.ToyFrame)
            APR.FP.ToyFrame.FS1:SetPoint("TOP", APR.FP.ToyFrame, "TOP", 0, 0)
            APR.FP.ToyFrame.FS1:SetWidth(300)
            APR.FP.ToyFrame.FS1:SetHeight(38)
            APR.FP.ToyFrame.FS1:SetJustifyH("TOP")
            APR.FP.ToyFrame.FS1:SetFontObject("GameFontNormalLarge")
            APR.FP.ToyFrame.FS1:SetText(L["USE_FLIGHTPATH"])
            APR.FP.ToyFrame.FS1:SetTextColor(1, 1, 0)
            if (APR.Faction == "Horde") then
                if (PlayerHasToy(150745) and C_QuestLog.IsQuestFlaggedCompleted(47956) == false) then
                    local itemID, toyName, icon, isFavorite, hasFanfare, itemQuality = C_ToyBox.GetToyInfo(150745)
                    APR.FP.ToyFrame.F1 = CreateFrame("Button", "APRFPToyFrameF2", APR.FP.ToyFrame,
                        "SecureActionButtonTemplate")
                    APR.FP.ToyFrame.F1:SetPoint("LEFT", APR.FP.ToyFrame, "LEFT", 15, 0)
                    APR.FP.ToyFrame.F1:SetWidth(80)
                    APR.FP.ToyFrame.F1:SetHeight(80)
                    APR.FP.ToyFrame.F1:SetText("")
                    APR.FP.ToyFrame.F1:SetParent(APR.FP.ToyFrame)
                    APR.FP.ToyFrame.F1:SetNormalFontObject("GameFontNormal")
                    APR.FP.ToyFrame.F1ntex = APR.FP.ToyFrame.F1:CreateTexture()
                    APR.FP.ToyFrame.F1ntex:SetTexture(icon)
                    APR.FP.ToyFrame.F1ntex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F1ntex:SetAllPoints()
                    APR.FP.ToyFrame.F1:SetNormalTexture(APR.FP.ToyFrame.F1ntex)
                    APR.FP.ToyFrame.F1htex = APR.FP.ToyFrame.F1:CreateTexture()
                    APR.FP.ToyFrame.F1htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
                    APR.FP.ToyFrame.F1htex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F1htex:SetAllPoints()
                    APR.FP.ToyFrame.F1:SetHighlightTexture(APR.FP.ToyFrame.F1htex)
                    APR.FP.ToyFrame.F1ptex = APR.FP.ToyFrame.F1:CreateTexture()
                    APR.FP.ToyFrame.F1ptex:SetTexture(icon)
                    APR.FP.ToyFrame.F1ptex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F1ptex:SetAllPoints()
                    APR.FP.ToyFrame.F1:SetPushedTexture(APR.FP.ToyFrame.F1ptex)
                    APR.FP.ToyFrame.F1:SetAttribute("type", "item");
                    APR.FP.ToyFrame.F1:SetAttribute("item", toyName);
                end
                if (PlayerHasToy(150744) and C_QuestLog.IsQuestFlaggedCompleted(47954) == false) then
                    local itemID, toyName, icon, isFavorite, hasFanfare, itemQuality = C_ToyBox.GetToyInfo(150744)
                    APR.FP.ToyFrame.F2 = CreateFrame("Button", "APRFPToyFrameF2", APR.FP.ToyFrame,
                        "SecureActionButtonTemplate")
                    APR.FP.ToyFrame.F2:SetPoint("RIGHT", APR.FP.ToyFrame, "RIGHT", -15, 0)
                    APR.FP.ToyFrame.F2:SetWidth(80)
                    APR.FP.ToyFrame.F2:SetHeight(80)
                    APR.FP.ToyFrame.F2:SetText("")
                    APR.FP.ToyFrame.F2:SetParent(APR.FP.ToyFrame)
                    APR.FP.ToyFrame.F2:SetNormalFontObject("GameFontNormal")
                    APR.FP.ToyFrame.F2ntex = APR.FP.ToyFrame.F2:CreateTexture()
                    APR.FP.ToyFrame.F2ntex:SetTexture(icon)
                    APR.FP.ToyFrame.F2ntex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F2ntex:SetAllPoints()
                    APR.FP.ToyFrame.F2:SetNormalTexture(APR.FP.ToyFrame.F2ntex)
                    APR.FP.ToyFrame.F2htex = APR.FP.ToyFrame.F2:CreateTexture()
                    APR.FP.ToyFrame.F2htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
                    APR.FP.ToyFrame.F2htex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F2htex:SetAllPoints()
                    APR.FP.ToyFrame.F2:SetHighlightTexture(APR.FP.ToyFrame.F2htex)
                    APR.FP.ToyFrame.F2ptex = APR.FP.ToyFrame.F2:CreateTexture()
                    APR.FP.ToyFrame.F2ptex:SetTexture(icon)
                    APR.FP.ToyFrame.F2ptex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F2ptex:SetAllPoints()
                    APR.FP.ToyFrame.F2:SetPushedTexture(APR.FP.ToyFrame.F2ptex)
                    APR.FP.ToyFrame.F2:SetAttribute("type", "item");
                    APR.FP.ToyFrame.F2:SetAttribute("item", toyName);
                end
                if (C_QuestLog.IsQuestFlaggedCompleted(47954) and C_QuestLog.IsQuestFlaggedCompleted(47956)) then
                    APR.FP.ToyFrame:Hide()
                else
                    C_Timer.After(5, APR.FP.testClickedFPS)
                end
            elseif (APR.Faction == "Alliance") then
                if (PlayerHasToy(150743) and C_QuestLog.IsQuestFlaggedCompleted(47954) == false) then
                    local itemID, toyName, icon, isFavorite, hasFanfare, itemQuality = C_ToyBox.GetToyInfo(150743)
                    APR.FP.ToyFrame.F1 = CreateFrame("Button", "APRFPToyFrameF2", APR.FP.ToyFrame,
                        "SecureActionButtonTemplate")
                    APR.FP.ToyFrame.F1:SetPoint("LEFT", APR.FP.ToyFrame, "LEFT", 15, 0)
                    APR.FP.ToyFrame.F1:SetWidth(80)
                    APR.FP.ToyFrame.F1:SetHeight(80)
                    APR.FP.ToyFrame.F1:SetText("")
                    APR.FP.ToyFrame.F1:SetParent(APR.FP.ToyFrame)
                    APR.FP.ToyFrame.F1:SetNormalFontObject("GameFontNormal")
                    APR.FP.ToyFrame.F1ntex = APR.FP.ToyFrame.F1:CreateTexture()
                    APR.FP.ToyFrame.F1ntex:SetTexture(icon)
                    APR.FP.ToyFrame.F1ntex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F1ntex:SetAllPoints()
                    APR.FP.ToyFrame.F1:SetNormalTexture(APR.FP.ToyFrame.F1ntex)
                    APR.FP.ToyFrame.F1htex = APR.FP.ToyFrame.F1:CreateTexture()
                    APR.FP.ToyFrame.F1htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
                    APR.FP.ToyFrame.F1htex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F1htex:SetAllPoints()
                    APR.FP.ToyFrame.F1:SetHighlightTexture(APR.FP.ToyFrame.F1htex)
                    APR.FP.ToyFrame.F1ptex = APR.FP.ToyFrame.F1:CreateTexture()
                    APR.FP.ToyFrame.F1ptex:SetTexture(icon)
                    APR.FP.ToyFrame.F1ptex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F1ptex:SetAllPoints()
                    APR.FP.ToyFrame.F1:SetPushedTexture(APR.FP.ToyFrame.F1ptex)
                    APR.FP.ToyFrame.F1:SetAttribute("type", "item");
                    APR.FP.ToyFrame.F1:SetAttribute("item", toyName);
                end
                if (PlayerHasToy(150746) and C_QuestLog.IsQuestFlaggedCompleted(47956) == false) then
                    local itemID, toyName, icon, isFavorite, hasFanfare, itemQuality = C_ToyBox.GetToyInfo(150746)
                    APR.FP.ToyFrame.F2 = CreateFrame("Button", "APRFPToyFrameF2", APR.FP.ToyFrame,
                        "SecureActionButtonTemplate")
                    APR.FP.ToyFrame.F2:SetPoint("RIGHT", APR.FP.ToyFrame, "RIGHT", -15, 0)
                    APR.FP.ToyFrame.F2:SetWidth(80)
                    APR.FP.ToyFrame.F2:SetHeight(80)
                    APR.FP.ToyFrame.F2:SetText("")
                    APR.FP.ToyFrame.F2:SetParent(APR.FP.ToyFrame)
                    APR.FP.ToyFrame.F2:SetNormalFontObject("GameFontNormal")
                    APR.FP.ToyFrame.F2ntex = APR.FP.ToyFrame.F2:CreateTexture()
                    APR.FP.ToyFrame.F2ntex:SetTexture(icon)
                    APR.FP.ToyFrame.F2ntex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F2ntex:SetAllPoints()
                    APR.FP.ToyFrame.F2:SetNormalTexture(APR.FP.ToyFrame.F2ntex)
                    APR.FP.ToyFrame.F2htex = APR.FP.ToyFrame.F2:CreateTexture()
                    APR.FP.ToyFrame.F2htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
                    APR.FP.ToyFrame.F2htex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F2htex:SetAllPoints()
                    APR.FP.ToyFrame.F2:SetHighlightTexture(APR.FP.ToyFrame.F2htex)
                    APR.FP.ToyFrame.F2ptex = APR.FP.ToyFrame.F2:CreateTexture()
                    APR.FP.ToyFrame.F2ptex:SetTexture(icon)
                    APR.FP.ToyFrame.F2ptex:SetTexCoord(0, 0.625, 0, 0.6875)
                    APR.FP.ToyFrame.F2ptex:SetAllPoints()
                    APR.FP.ToyFrame.F2:SetPushedTexture(APR.FP.ToyFrame.F2ptex)
                    APR.FP.ToyFrame.F2:SetAttribute("type", "item");
                    APR.FP.ToyFrame.F2:SetAttribute("item", toyName);
                end
                if (APR.Faction == "Alliance" and (C_QuestLog.IsQuestFlaggedCompleted(47954) or PlayerHasToy(150743) == false) and (C_QuestLog.IsQuestFlaggedCompleted(47956) or PlayerHasToy(150746) == false)) then
                    APR.FP.ToyFrame:Hide()
                elseif (APR.Faction == "Horde" and (C_QuestLog.IsQuestFlaggedCompleted(47954) or PlayerHasToy(150744) == false) and (C_QuestLog.IsQuestFlaggedCompleted(47956) or PlayerHasToy(150745) == false)) then
                    APR.FP.ToyFrame:Hide()
                else
                    C_Timer.After(5, APR.FP.testClickedFPS)
                end
            end
        end
    end
end

function APR.FP.testClickedFPS()
    if (APR.settings.profile.debug) then
        print("Function: APR.FP.testClickedFPS()")
    end
    if (APR.Faction == "Alliance" and (C_QuestLog.IsQuestFlaggedCompleted(47954) or PlayerHasToy(150743) == false) and (C_QuestLog.IsQuestFlaggedCompleted(47956) or PlayerHasToy(150746) == false)) then
        APR.FP.ToyFrame:Hide()
    elseif (APR.Faction == "Horde" and (C_QuestLog.IsQuestFlaggedCompleted(47954) or PlayerHasToy(150744) == false) and (C_QuestLog.IsQuestFlaggedCompleted(47956) or PlayerHasToy(150745) == false)) then
        APR.FP.ToyFrame:Hide()
    else
        if (APR.Faction == "Alliance") then
            if (C_QuestLog.IsQuestFlaggedCompleted(47956) and APR.FP.ToyFrame.F2) then
                APR.FP.ToyFrame.F2:Hide()
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(47954) and APR.FP.ToyFrame.F1) then
                APR.FP.ToyFrame.F1:Hide()
            end
        elseif (APR.Faction == "Horde") then
            if (C_QuestLog.IsQuestFlaggedCompleted(47956) and APR.FP.ToyFrame.F1) then
                APR.FP.ToyFrame.F1:Hide()
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(47954) and APR.FP.ToyFrame.F2) then
                APR.FP.ToyFrame.F2:Hide()
            end
        end
        C_Timer.After(1, APR.FP.testClickedFPS)
    end
end

function APR.FP.test()
    if (APR.settings.profile.debug) then
        print("Function: APR.FP.test()")
    end
    if (not APR_Transport["Ports"]) then
        APR_Transport["Ports"] = {}
    end
    if (not APR_Transport["Ports"][APR.Faction]) then
        APR_Transport["Ports"][APR.Faction] = {}
    end
    if (not APR_Transport["Ports"][APR.Faction][APR:GetContinent()]) then
        APR_Transport["Ports"][APR.Faction][APR:GetContinent()] = {}
    end
    APR_Transport["Ports"][APR.Faction][APR:GetContinent()]["Port"] = {}
    local d_y, d_x = UnitPosition("player")
    d_y = floor((d_y * 10) + 5) / 10
    d_x = floor((d_x * 10) + 5) / 10
    APR_Transport["Ports"][APR.Faction][APR:GetContinent()]["Port"]["y"] = d_y
    APR_Transport["Ports"][APR.Faction][APR:GetContinent()]["Port"]["x"] = d_x
end

function APR.FP.GetMeToNextZonetest()
    if (APR.settings.profile.debug) then
        print("Function: APR.FP.GetMeToNextZonetest()")
    end
    local APRt_Zone2 = C_Map.GetBestMapForUnit("player")
    local currentMapId, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
    APRt_Zone2 = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent, TOP_MOST)
    if (APRt_Zone2 and APRt_Zone2["mapID"]) then
        APRt_Zone2 = APRt_Zone2["mapID"]
    else
        APRt_Zone2 = C_Map.GetBestMapForUnit("player")
    end
    if (APRt_Zone2 == 1671) then
        APRt_Zone2 = 1670
    elseif (APRt_Zone == 578) then
        APRt_Zone = 577
    elseif (APR.ActiveMap == "A543-DesMephisto-Gorgrond" and APRt_Zone == 535) then
        APRt_Zone = 543
    elseif (APRt_Zone == 1726 or APRt_Zone == 1727 or APRt_Zone == 1728) then
        APRt_Zone = 1409
    end
end

function APR.FP.GetCustomZone()
    local ZeMap = C_Map.GetBestMapForUnit("player")
    local currentMapId, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
    if (Enum and Enum.UIMapType and Enum.UIMapType.Continent and currentMapId) then
        ZeMap = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent + 1, TOP_MOST)
    end
    if (ZeMap and ZeMap["mapID"]) then
        ZeMap = ZeMap["mapID"]
    else
        ZeMap = C_Map.GetBestMapForUnit("player")
    end
    local zenr = 0
    if (APR_Custom and APR_Custom[APR.Name .. "-" .. APR.Realm]) then
        for APR_index2, APR_value2 in PairsByKeys(APR_Custom[APR.Name .. "-" .. APR.Realm]) do
            zenr = zenr + 1
        end
    end
    if (zenr == 0 and UnitFactionGroup("player") == "Alliance" and C_QuestLog.IsQuestFlaggedCompleted(59751) == false and (C_QuestLog.IsQuestFlaggedCompleted(60545) == true or C_QuestLog.IsOnQuest(60545) == true)) then
        return 84, "84-IntroQline"
    end
    if (zenr == 0 and UnitFactionGroup("player") == "Horde" and C_QuestLog.IsQuestFlaggedCompleted(59751) == false and (C_QuestLog.IsQuestFlaggedCompleted(61874) == true or C_QuestLog.IsOnQuest(61874) == true)) then
        return 85, "85-IntroQline"
    end
    if (zenr == 0 and not ZeMap and C_QuestLog.IsOnQuest(57159)) then
        return APR.QuestStepListListingZone["Z-12-Revendreth-Story"], "1525-Z12-Revendreth-Story"
    end
    if (zenr == 0 and C_QuestLog.IsOnQuest(57876) and C_QuestLog.IsQuestFlaggedCompleted(57876) == false) then
        return APR.QuestStepListListingZone["Z-14-Revendreth-Story"], "1525-Z14-Revendreth-Story"
    end
    if (zenr == 0 and APR.Level > 49) then
        APR.ProgressText = "Auto Path"
        if (C_QuestLog.IsQuestFlaggedCompleted(58086) == false and (C_QuestLog.IsOnQuest(61874) == true or C_QuestLog.IsQuestFlaggedCompleted(61874) == true or C_QuestLog.IsOnQuest(59751) or C_QuestLog.IsQuestFlaggedCompleted(59751) == true)) then
            APR.ProgressShown = true
            if (C_QuestLog.IsQuestFlaggedCompleted(59770) == false) then
                return APR.QuestStepListListingZone["Z-00-TheMaw-Story"], "1648-Z0-TheMaw-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(59773) == false) then
                return APR.QuestStepListListingZone["Z-01-Oribos-Story"], "1670-Z1-Oribos-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(60056) == false) then
                return APR.QuestStepListListingZone["Z-02-Bastion-Story"], "1533-Z2-Bastion-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(57386) == false) then
                return APR.QuestStepListListingZone["Z-03-Oribos-Story"], "1613-Z3-Oribos-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(59874) == false) then
                return APR.QuestStepListListingZone["Z-04-Maldraxxus-Story"], "1536-Z4-Maldraxxus-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(59897) == false) then
                return APR.QuestStepListListingZone["Z-05-Oribos-Story"], "1670-Z5-Oribos-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(62654) == false) then
                return APR.QuestStepListListingZone["Z-06-The Maw-Story"], "1543-Z6-TheMaw-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(59011) == false) then
                return APR.QuestStepListListingZone["Z-07-Oribos-Story"], "1670-Z7-Oribos-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(59206) == false) then
                return APR.QuestStepListListingZone["Z-08-Maldraxxus-Story"], "1536-Z8-Maldraxxus-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(60338) == false) then
                return APR.QuestStepListListingZone["Z-09-Oribos-Story"], "1670-Z9-Oribos-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(58724) == false) then
                return APR.QuestStepListListingZone["Z-10-Ardenweald-Story"], "1565-Z10-Ardenweald-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(57025) == false) then
                return APR.QuestStepListListingZone["Z-11-Oribos-Story"], "1671-Z11-Oribos-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(57689) == false) then
                return APR.QuestStepListListingZone["Z-12-Revendreth-Story"], "1525-Z12-Revendreth-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(57693) == false) then
                return APR.QuestStepListListingZone["Z-13-The Maw-Story"], "1543-Z13-TheMaw-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(57876) == false) then
                return APR.QuestStepListListingZone["Z-14-Revendreth-Story"], "1525-Z14-Revendreth-Story"
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(57878) == false) then
                return APR.QuestStepListListingZone["Z-15-Oribos-Story"], "1671-Z15-Oribos-Story"
            end
        else
            APR.ProgressShown = false
            return
        end
    elseif (zenr == 0) then
        APR.ProgressText = "Auto Path"
        APR.ProgressShown = false
        if (ZeMap == 1409 or ZeMap == 1726 or ZeMap == 1727 or ZeMap == 1728) then
            if (IsAddOnLoaded("APR-Shadowlands") == false) then
                local loaded, reason = LoadAddOn("APR-Shadowlands")
                if (not loaded) then
                    if (reason == "DISABLED") then
                        print("APR: APR - Shadowlands " .. L["DISABLED_ADDON_LIST"])
                    end
                end
            end
            return APR.QuestStepListListingZone["01-10 Exile's Reach"], "1409-Exile's Reach"
        end
        if (C_QuestLog.IsQuestFlaggedCompleted(34398) == false and APR.Faction == "Alliance") then
            APR.ProgressShown = true
            return APR.QuestStepListListingZone["(1/7) 1-50 Stormwind"], "A84-DesMephisto-Stormwind-War"
        end
        if (C_QuestLog.IsQuestFlaggedCompleted(35884) == false and APR.Faction == "Alliance") then
            APR.ProgressShown = true
            return APR.QuestStepListListingZone["(2/7) 1-50 Tanaan Jungle"], "A577-DesMephisto-TanaanJungle"
        end
        if (C_QuestLog.IsQuestFlaggedCompleted(35556) == false and APR.Faction == "Alliance") then
            APR.ProgressShown = true
            return APR.QuestStepListListingZone["(3/7) 1-50 Shadowmoon"], "A539-DesMephisto-Shadowmoon1"
        end
        if (C_QuestLog.IsQuestFlaggedCompleted(36937) == false and APR.Faction == "Alliance") then
            APR.ProgressShown = true
            return APR.QuestStepListListingZone["(4/7) 1-50 Gorgrond"], "A543-DesMephisto-Gorgrond"
        end
        if (C_QuestLog.IsQuestFlaggedCompleted(34587) == false and APR.Faction == "Alliance") then
            APR.ProgressShown = true
            return APR.QuestStepListListingZone["(5/7) 1-50 Talador"], "A535-DesMephisto-Talador"
        end
        if (C_QuestLog.IsQuestFlaggedCompleted(34624) == false and APR.Faction == "Alliance") then
            APR.ProgressShown = true
            return APR.QuestStepListListingZone["(6/7) 1-50 Shadowmoon"], "A539-DesMephisto-Shadowmoon2"
        end
        if (C_QuestLog.IsQuestFlaggedCompleted(34707) == false and APR.Faction == "Alliance") then
            APR.ProgressShown = true
            return APR.QuestStepListListingZone["(7/7) 1-50 Talador"], "A535-DesMephisto-Talador2"
        end
    end
    APR.ProgressText = "Custom Path"
    if (not APR_Custom) then
        return
    end
    if (APR.settings.profile.debug) then
        print("Function: APR.FP.GetCustomZone()")
    end
    for CLi = 1, 19 do
        if (APR_Custom[APR.Name .. "-" .. APR.Realm] and APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] and APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]]) then
            if (APR.QuestStepListListingStartAreas["EasternKingdom"]) then
                for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListingStartAreas["EasternKingdom"]) do
                    if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                        APR.ProgressShown = true
                        return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                    end
                end
            end
            if (APR.QuestStepListListingStartAreas["BrokenIsles"]) then
                for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListingStartAreas["BrokenIsles"]) do
                    if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                        APR.ProgressShown = true
                        return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                    end
                end
            end
            if (APR.QuestStepListListingStartAreas["Kalimdor"]) then
                for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListingStartAreas["Kalimdor"]) do
                    if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                        APR.ProgressShown = true
                        return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                    end
                end
            end
            for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["EasternKingdom"]) do
                if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                    APR.ProgressShown = true
                    return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                end
            end
            for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["Kalimdor"]) do
                if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                    APR.ProgressShown = true
                    return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                end
            end
            for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["SpeedRun"]) do
                if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                    APR.ProgressShown = true
                    return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                end
            end
            for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["Shadowlands"]) do
                if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                    APR.ProgressShown = true
                    return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                end
            end
            for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["Extra"]) do
                if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                    APR.ProgressShown = true
                    return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                end
            end
            for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["MISC 1"]) do
                if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                    APR.ProgressShown = true
                    return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                end
            end
            for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["MISC 2"]) do
                if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                    APR.ProgressShown = true
                    return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                end
            end
            for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["Dragonflight"]) do
                if (APR_Custom[APR.Name .. "-" .. APR.Realm][CLi] == APR_value2) then
                    APR.ProgressShown = true
                    return APR.QuestStepListListingZone[APR_Custom[APR.Name .. "-" .. APR.Realm][CLi]], APR_index2
                end
            end
        end
    end
    APR.ProgressText = nil
end

function APR.FP.GetMeToNextZoneSpecialRe(APRt_Zone)
    if (APRLumberCheck == 0 and C_QuestLog.IsQuestFlaggedCompleted(35049)) then
        APR.QuestStepList["A543-DesMephisto-Gorgrond"] = nil
        APR.QuestStepList["A543-DesMephisto-Gorgrond"] = APR.QuestStepList["A543-DesMephisto-Gorgrond-Lumbermill"]
        APRLumberCheck = 1
    end
    if (APRLumberCheck == 0 and C_QuestLog.IsQuestFlaggedCompleted(34992)) then
        APR.QuestStepList["543-DesMephisto-Gorgrond-p1"] = nil
        APR.QuestStepList["543-DesMephisto-Gorgrond-p1"] = APR.QuestStepList["543-DesMephisto-Gorgrond-Lumbermill"]
        APRLumberCheck = 1
    end

    if (((ZeMap == 1409 or ZeMap == 1726) or C_QuestLog.IsQuestFlaggedCompleted(55992) or C_QuestLog.IsQuestFlaggedCompleted(55991) or C_QuestLog.IsQuestFlaggedCompleted(59984) or C_QuestLog.IsQuestFlaggedCompleted(59985)) and APR.Level < 15) then
        if (C_QuestLog.IsOnQuest(59583) == true) then
            C_QuestLog.SetSelectedQuest(59583)
            C_QuestLog.SetAbandonQuest()
            C_QuestLog.AbandonQuest()
        end
        if (C_QuestLog.IsOnQuest(60343) == true) then
            C_QuestLog.SetSelectedQuest(60343)
            C_QuestLog.SetAbandonQuest()
            C_QuestLog.AbandonQuest()
        end
        APR.QuestStepList["A84-DesMephisto-Stormwind-War"] = APR.QuestStepList["A84-DesMephisto-Stormwind-War2"]
    elseif (APR.Level < 15) then
        APR.QuestStepList["A84-DesMephisto-Stormwind-War"] = APR.QuestStepList["A84-DesMephisto-Stormwind-War3"]
    end
    if (APRt_Zone == 1671) then
        APRt_Zone = 1670
    elseif (APRt_Zone == 578) then
        APRt_Zone = 577
    elseif (APR.ActiveMap == "A535-DesMephisto-Talador2" and APRt_Zone == 542) then
        APRt_Zone = 535
    elseif (APR.ActiveMap == "A84-DesMephisto-Stormwind-War" and APRt_Zone == 17) then
        APRt_Zone = 84
    elseif (APR.ActiveMap == "A543-DesMephisto-Gorgrond" and APRt_Zone == 535) then
        APRt_Zone = 543
    elseif (APR.ActiveMap == "A539-DesMephisto-Shadowmoon1" and (APRt_Zone == 84 or APRt_Zone == 543)) then
        APRt_Zone = 539
    elseif (APR.ActiveMap == "A539-DesMephisto-Shadowmoon2" and APRt_Zone == 535) then
        APRt_Zone = 539
    elseif (APR.ActiveMap == "A535-DesMephisto-Talador" and APRt_Zone == 539) then
        APRt_Zone = 535
    elseif (APRt_Zone == 1726 or APRt_Zone == 1727 or APRt_Zone == 1728) then
        APRt_Zone = 1409
    end

    if (APR.ActiveMap == "Shadowlands-StoryOnly-A" and ((APRt_Zone == 84) or (APRt_Zone == 1648) or (APRt_Zone == 1670) or (APRt_Zone == 1671) or (APRt_Zone == 1533) or (APRt_Zone == 1613) or (APRt_Zone == 1536) or (APRt_Zone == 1543) or (APRt_Zone == 1565) or (APRt_Zone == 1525))) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "Shadowlands-StoryOnly-H" and ((APRt_Zone == 85) or (APRt_Zone == 1648) or (APRt_Zone == 1670) or (APRt_Zone == 1671) or (APRt_Zone == 1533) or (APRt_Zone == 1613) or (APRt_Zone == 1536) or (APRt_Zone == 1543) or (APRt_Zone == 1565) or (APRt_Zone == 1525))) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "85-DesMephisto-Orgrimmar-p1" and APRt_Zone == 17) then
        APRt_Zone = 85
    end
    if (APR.ActiveMap == "525-DesMephisto-FrostfireRidge-p1" and APRt_Zone == 85) then
        APRt_Zone = 525
    end
    if (APR.ActiveMap == "525-DesMephisto-FrostfireRidge-p1" and APRt_Zone == 543) then
        APRt_Zone = 525
    end
    if (APR.ActiveMap == "543-DesMephisto-Gorgrond-p1" and APRt_Zone == 535) then
        APRt_Zone = 543
    end
    if (APR.ActiveMap == "535-DesMephisto-Talador-p1" and APRt_Zone == 542) then
        APRt_Zone = 535
    end
    if (APR.ActiveMap == "550-DesMephisto-Nagrand" and APRt_Zone == 535) then
        APRt_Zone = 550
    end

    if (APR.ActiveMap == "1409-Exile's Reach" and APRt_Zone == 85) then
        APRt_Zone = 1409
    end

    if (APR.ActiveMap == "84-IntroQline" and APRt_Zone == 118) then
        APRt_Zone = 84
    end
    if (APR.ActiveMap == "84-IntroQline" and APRt_Zone == 1648) then
        APRt_Zone = 84
    end
    if (APR.ActiveMap == "85-IntroQline" and APRt_Zone == 118) then
        APRt_Zone = 85
    end
    if (APR.ActiveMap == "85-IntroQline" and APRt_Zone == 1648) then
        APRt_Zone = 85
    end
    if (APR.ActiveMap == "1670-Z1-Oribos-Story" and APRt_Zone == 1533) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "1670-Z1-Oribos-Story" and APRt_Zone == 1673) then
        APRt_Zone = 1670
    end

    if (APR.ActiveMap == "1533-Z2-Bastion-Story" and APRt_Zone == 1670) then
        APRt_Zone = 1533
    end
    if (APR.ActiveMap == "1613-Z3-Oribos-Story" and APRt_Zone == 1536) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "1536-Z4-Maldraxxus-Story" and APRt_Zone == 1670) then
        APRt_Zone = 1536
    end
    if (APR.ActiveMap == "1536-Z4-Maldraxxus-Story" and APRt_Zone == 1691) then
        APRt_Zone = 1536
    end
    if (APR.ActiveMap == "1536-Z4-Maldraxxus-Story" and APRt_Zone == 1671) then
        APRt_Zone = 1536
    end
    if (APR.ActiveMap == "1536-Z4-Maldraxxus-Story" and APRt_Zone == 1550) then
        APRt_Zone = 1536
    end
    if (APR.ActiveMap == "1670-Z5-Oribos-Story" and APRt_Zone == 1543) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "1543-Z6-TheMaw-Story" and APRt_Zone == 1670) then
        APRt_Zone = 1543
    end
    if (APR.ActiveMap == "1670-Z7-Oribos-Story" and APRt_Zone == 1536) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "1536-Z8-Maldraxxus-Story" and APRt_Zone == 1670) then
        APRt_Zone = 1536
    end
    if (APR.ActiveMap == "1536-Z8-Maldraxxus-Story" and APRt_Zone == 1550) then
        APRt_Zone = 1536
    end
    if (APR.ActiveMap == "1536-Z8-Maldraxxus-Story" and APRt_Zone == 1671) then
        APRt_Zone = 1536
    end
    if (APR.ActiveMap == "1670-Z9-Oribos-Story" and APRt_Zone == 1565) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "1565-Z10-Ardenweald-Story" and APRt_Zone == 1670) then
        APRt_Zone = 1565
    end
    if (APR.ActiveMap == "1565-Z10-Ardenweald-Story" and APRt_Zone == 1824) then
        APRt_Zone = 1565
    end
    if (APR.ActiveMap == "1565-Z10-Ardenweald-Story" and APRt_Zone == 1642) then
        APRt_Zone = 1565
    end
    if (APR.ActiveMap == "1565-Z10-Ardenweald-Story" and APRt_Zone == 619) then
        APRt_Zone = 1565
    end
    if (APR.ActiveMap == "1671-Z11-Oribos-Story" and APRt_Zone == 1525) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "1525-Z12-Revendreth-Story" and APRt_Zone == 1543) then
        APRt_Zone = 1525
    end
    if (APR.ActiveMap == "1543-Z13-TheMaw-Story" and APRt_Zone == 1525) then
        APRt_Zone = 1543
    end
    if (APR.ActiveMap == "1543-Z13-TheMaw-Story" and APRt_Zone == 1656) then
        APRt_Zone = 1543
    end
    if (APR.ActiveMap == "1525-Z14-Revendreth-Story" and APRt_Zone == 1670) then
        APRt_Zone = 1525
    end
    if (APR.ActiveMap == "1670-Z1-Oribos-StoryXBastion" and APRt_Zone == 1533) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "1670-Z1-Oribos-StoryXMaldraxxus" and APRt_Zone == 1536) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "1670-Z1-Oribos-StoryXArdenweald" and APRt_Zone == 1565) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "1670-Z1-Oribos-StoryXRevendreth" and APRt_Zone == 1525) then
        APRt_Zone = 1670
    end
    if (APR.ActiveMap == "1525-Z12-Revendreth-Story" and APRt_Zone == 1543) then
        APRt_Zone = 1525
    end
    if (APR.ActiveMap == "1543-Z13-TheMaw-Story" and (APRt_Zone == 1762 or APRt_Zone == 1656 or APRt_Zone == 1525)) then
        APRt_Zone = 1543
    end
    if (APR.ActiveMap == "1670-Z1-Oribos-ZonePick" and (APRt_Zone == 1762 or APRt_Zone == 1656 or APRt_Zone == 1525 or APRt_Zone == 1543 or APRt_Zone == 1565 or APRt_Zone == 1533 or APRt_Zone == 1536)) then
        APRt_Zone = 1670
    end
    -- Eastern Kingdoms
    if (APR.ActiveMap == "A23-ScarletEnclave" and (APRt_Zone == 37 or APRt_Zone == 84 or APRt_Zone == 124)) then
        APRt_Zone = 23
    elseif (APR.ActiveMap == "H23-ScarletEnclave" and (APRt_Zone == 1 or APRt_Zone == 85 or APRt_Zone == 124)) then
        APRt_Zone = 23
    end
    -- Dragonflight
    if (APR.ActiveMap == "DF01H-85-Orgrimmar" and APRt_Zone == 1) then
        APRt_Zone = 85
    elseif (APR.ActiveMap == "DF01A-84-Stormwind" and (APRt_Zone == 1978 or APRt_Zone == 2022)) then
        APRt_Zone = 84
    elseif (APR.ActiveMap == "DF02H-1-Durotar" and (APRt_Zone == 1978 or APRt_Zone == 2022)) then
        APRt_Zone = 1
    elseif (APR.ActiveMap == "DF03N-2022-WakingShores" and APRt_Zone == 2023) then
        APRt_Zone = 2022
    elseif (APR.ActiveMap == "DF04-2023-OhnahranPlains" and APRt_Zone == 2024) then
        APRt_Zone = 2023
    elseif (APR.ActiveMap == "DF05-2024-AzureSpan" and APRt_Zone == 2025) then
        APRt_Zone = 2024
    elseif (APR.ActiveMap == "DF06H-2025-Thaldraszus" and (APRt_Zone == 2135 or APRt_Zone == 2090 or APRt_Zone == 2091 or APRt_Zone == 2088 or APRt_Zone == 2089)) then
        APRt_Zone = 2025
    elseif (APR.ActiveMap == "DF06A-2025-Thaldraszus" and (APRt_Zone == 2135 or APRt_Zone == 2090 or APRt_Zone == 2091 or APRt_Zone == 2088 or APRt_Zone == 2089)) then
        APRt_Zone = 2025
    end

    return APRt_Zone
end

function APR.FP.GetMeToNextZone()
    APR.ZoneTransfer = false
    if (APR.settings.profile.debug) then
        print("Function: APR.FP.GetMeToNextZone()")
    end
    local zeZ, Zname = APR.FP.GetCustomZone()
    if (zeZ and Zname) then
        APR.ActiveMap = Zname
        APR.FP.GoToZone = zeZ
    end
    local APRt_Zone = C_Map.GetBestMapForUnit("player")
    local currentMapId, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
    if (not currentMapId) then
        return
    end
    APRt_Zone = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent + 1, TOP_MOST)
    if (APRt_Zone and APRt_Zone["mapID"]) then
        APRt_Zone = APRt_Zone["mapID"]
    else
        APRt_Zone = C_Map.GetBestMapForUnit("player")
    end
    APRt_Zone = APR.FP.GetMeToNextZoneSpecialRe(APRt_Zone)
    for APR_index, APR_value in pairs(APR.QuestStepListListing) do
        if (APR.ActiveMap and APR.QuestStepListListing[APR_index][APR.ActiveMap]) then
            local zerd = APR.QuestStepListListing[APR_index][APR.ActiveMap]
            if (APR.QuestStepListListingZone[zerd] and APRt_Zone and APR.QuestStepListListingZone[zerd] == APRt_Zone) then
                APR.FP.GoToZone = nil
                return
            end
        end
    end
    if (APR.ActiveQuests and APR.ActiveQuests[59974] and (APR.ActiveMap == "A1670-Oribos (Maw-Maldraxxus)" or APR.ActiveMap == "1670-Oribos (Maw-Maldraxxus)" or APR.ActiveMap == "A1670-Z7-Oribos-Story" or APR.ActiveMap == "1670-Z7-Oribos-Story")) then
        APR.FP.GoToZone = nil
        return
    end
    if (APR.ActiveMap == "84-IntroQline" and APRt_Zone == 84) then
        APR.FP.GoToZone = nil
        return
    end
    if (APR.ActiveMap == "85-IntroQline" and APRt_Zone == 85) then
        APR.FP.GoToZone = nil
        return
    end
    if (APR.ActiveQuests and APR.ActiveQuests[32675] and APRt_Zone == 84 and APR.Faction == "Alliance") then
        APR.ActiveMap = "A84-LearnFlying"
        APR.FP.GoToZone = nil
        return
    end
    APR.ZoneTransfer = true
    APR.BookingList["GetMeToNextZone2"] = 1
end

function APR.FP.GetMeToNextZone2()
    -- Disable Current Step button/bar/quest/...
    APR.currentStep:Disable()

    if (APR.FP.Zonening == 1) then
        return
    end
    if (not APR.FP.GoToZone) then
        APR.ZoneTransfer = false
        return
    end
    if (APR.settings.profile.debug) then
        print("Function: APR.FP.GetMeToNextZone2()")
    end
    local APRt_Zone = C_Map.GetBestMapForUnit("player")
    local currentMapId, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
    if (not currentMapId) then
        return
    end
    APRt_Zone = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent + 1, TOP_MOST)
    if (APRt_Zone and APRt_Zone["mapID"]) then
        APRt_Zone = APRt_Zone["mapID"]
    else
        APRt_Zone = C_Map.GetBestMapForUnit("player")
    end
    APRt_Zone = APR.FP.GetMeToNextZoneSpecialRe(APRt_Zone)
    local zeReal = C_Map.GetBestMapForUnit('player')
    local GoToZone = APR.FP.GoToZone
    local CurContinent = APR:GetContinent()
    local Contin, gotoCont = APR.FP.IsSameContinent(GoToZone)
    local mapzinfoz = C_Map.GetMapInfo(GoToZone)
    if (not mapzinfoz) then
        return
    end
    local mapzinfoz2 = C_Map.GetMapInfo(mapzinfoz.parentMapID)
    if (not mapzinfoz2) then
        return
    end
    local DestSet = 0

    if (APRt_Zone ~= GoToZone) then
        APR.currentStep:RemoveQuestStepsAndExtraLineTexts()
        if (APR.ActiveMap) then
            local function checkChromieTimeline(id)
                local chromieExpansionOption = C_ChromieTime.GetChromieTimeExpansionOption(id)
                if (not chromieExpansionOption) then
                    APR.currentStep:AddExtraLineText("NOT_IN_CHROMIE_TIMELINE", L["NOT_IN_CHROMIE_TIMELINE"])
                elseif (chromieExpansionOption.alreadyOn == false) then
                    APR.currentStep:AddExtraLineText("SWITCH_TO_CHROMIE", L["SWITCH_TO_CHROMIE"] ..
                        " " .. chromieExpansionOption.name)
                end
            end
            if (APR.QuestStepListListing["Extra"][APR.ActiveMap]) then
                -- 9 == WOD
                checkChromieTimeline(9)
            end
            -- If we add Sl timeline in the future
            -- if(APR.QuestStepListListing["Shadowlands"][APR.ActiveMap]) then
            -- 	-- 14 == Shadowland
            -- 	checkChromieTimeline(14)
            -- end
        end
        if (not APR.settings.profile.currentStepShow) then
            APR.currentStep:AddExtraLineText("DESTINATION", L["DESTINATION"] ..
                ": " .. mapzinfoz.name .. ", " .. mapzinfoz2.name .. " (" .. GoToZone .. ")")
            DestSet = 1
        end
    end
    if (((APRt_Zone == 181) or (APRt_Zone == 202) or (APRt_Zone == 179)) and APR.ActiveMap == "A179-Gilneas") then
        APR.ZoneTransfer = false
    elseif (((APRt_Zone == 97) or (APRt_Zone == 106)) and APR.ActiveMap == "A106-BloodmystIsle") then
        APR.ZoneTransfer = false
    elseif (((APRt_Zone == 69) or (APRt_Zone == 64)) and APR.ActiveMap == "A64-ThousandNeedles") then
        APR.ZoneTransfer = false
    elseif ((APRt_Zone == 1536) and APR.ActiveQuests and APR.ActiveQuests["59974"]) then
        APR.ZoneTransfer = false
    elseif (((APRt_Zone == 71) or (APRt_Zone == 249)) and APR.ActiveMap == "A71-Tanaris") then
        APR.ZoneTransfer = false
    elseif (APR.ActiveMap == "A84-LearnFlying") then
        APR.ZoneTransfer = false
    elseif (zeReal == 427 and APR.ActiveMap ~= "A27-ColdridgeValleyDwarf") then
        -- Coldridge Valley (Dwarf/gnum)
        APR.currentStep:AddExtraLineText("GO_CAVE", L["GO_CAVE"])
        APR.ArrowActive = 1
        APR.ArrowActive_X = 117.2
        APR.ArrowActive_Y = -6216.2
    elseif (zeReal == 28 and APR.ActiveMap ~= "A27-ColdridgeValleyDwarf") then
        -- Coldridge Valley cave to Dun Morogh
        APR.currentStep:AddExtraLineText("OUT_CAVE", L["OUT_CAVE"])
        APR.ArrowActive = 1
        APR.ArrowActive_X = 48.9
        APR.ArrowActive_Y = -6031.8
    elseif (zeReal == 971 and APR.Level == 20) then
        -- Void Elf lvl20 StartZone
        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormwind",
            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(84).name)
        APR.ArrowActive = 1
        APR.ArrowActive_X = 3331.6
        APR.ArrowActive_Y = 2149.6
    elseif ((zeReal == 940 or zeReal == 941) and APR.Level == 20) then
        -- Lightforged Draenei lvl20 StartZone
        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormwind",
            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(84).name)
        APR.ArrowActive = 1
        APR.ArrowActive_X = 1469.5
        APR.ArrowActive_Y = 499.6
    elseif (zeReal == 680 and APR.Level == 20) then
        -- Nightborne lvl20 StartZone
        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
        APR.ArrowActive = 1
        APR.ArrowActive_X = 3428.6
        APR.ArrowActive_Y = 213.6
    elseif (zeReal == 652 and APR.Level == 20) then
        -- Highmountain Tauren lvl20 StartZone
        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
        APR.ArrowActive = 1
        APR.ArrowActive_X = 4415
        APR.ArrowActive_Y = 4082.4
    elseif (zeReal == 1165 and APR.Level == 20) then
        -- Zandalari Troll lvl20 StartZone
        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
        APR.ArrowActive = 1
        APR.ArrowActive_X = 805.7
        APR.ArrowActive_Y = -1085.1
    elseif (Contin == 0) then
        APR.FP.SwitchCont(CurContinent, gotoCont, GoToZone)
    else
        if (APRt_Zone == GoToZone) then
            APR.FP.GoToZone = nil
            APR.ZoneTransfer = false
        else
            local togozo, ZefpID
            if (APR:GetContinent() and APR_Transport["FPs"][APR.Faction][APR:GetContinent()]) then
                togozo, ZefpID = APR.FP.GetStarterZoneFP(GoToZone)
            end
            if (togozo ~= nil) then
                local ZeContz
                if (not APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm]) then
                    APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm] = {}
                end
                if (APR_Transport["FPs"][APR.Faction][APR:GetContinent()] and APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm]["Conts"] and APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm]["Conts"][APR:GetContinent()]) then
                    ZeContz = APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm]
                        ["Conts"]
                        [APR:GetContinent()]
                else
                    ZeContz = nil
                end
                if (not ZeContz) then
                    local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                    if (Zefp) then
                        APR.currentStep:AddExtraLineText("NEED_CHECK_FPS", L["NEED_CHECK_FPS"] .. ": " .. Zefp)
                        APR.FP.QuedFP = togozo
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = ZeX
                        APR.ArrowActive_Y = ZeY
                    end
                else
                    local zeFP = APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm]
                        [ZefpID]
                    if (zeFP and zeFP == 1) then
                        APR.currentStep:AddExtraLineText("FLY_TO_" .. togozo, L["FLY_TO"] .. " " .. togozo)
                        APR.FP.QuedFP = togozo
                        local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                        if (Zefp and ZeX and ZeY) then
                            APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                            APR.ArrowActive = 1
                            APR.ArrowActive_X = ZeX
                            APR.ArrowActive_Y = ZeY
                        end
                    else
                        local zdse, zX, zY = APR.FP.CheckWheretoRun(GoToZone, APRt_Zone)
                        if (zdse) then
                            local mapzinfozx = C_Map.GetMapInfo(zdse)
                            APR.currentStep:AddExtraLineText("GO_TO" .. mapzinfozx.name,
                                L["GO_TO"] .. ": " .. mapzinfozx.name)
                            APR.ArrowActive = 1
                            APR.ArrowActive_X = zX
                            APR.ArrowActive_Y = zY
                        else
                            APR.currentStep:AddExtraLineText("ERROR_ROUTE_NOT_FOUND", L["ERROR"] ..
                                " - " .. L["ROUTE_NOT_FOUND"] .. " " .. mapzinfoz.name .. " (" .. GoToZone .. ")")
                        end
                    end
                end
            end
        end
    end
    if (APR.ZoneTransfer) then
        C_Timer.After(2, APR.FP.GetMeToNextZone2)
    end
    if (DestSet == 1) then
        APR.ArrowActive = 0
        APR.ArrowActive_X = 0
        APR.ArrowActive_Y = 0
    end
end

function APR.FP.CheckWheretoRun(GoToZone, APRt_Zone)
    if (APR.TDB["ZoneMoveOrder"][APRt_Zone] and APR.TDB["ZoneMoveOrder"][APRt_Zone][GoToZone]) then
        local zdse = APR.TDB["ZoneMoveOrder"][APRt_Zone][GoToZone]
        if (APR.TDB["ZoneEntry"][APR:GetContinent()] and APR.TDB["ZoneEntry"][APR:GetContinent()][zdse]) then
            local closest = 9999
            local zeX = 0
            local zeY = 0
            local d_y, d_x = UnitPosition("player")
            for APR_index, APR_value in pairs(APR.TDB["ZoneEntry"][APR:GetContinent()][zdse]) do
                local x = APR.TDB["ZoneEntry"][APR:GetContinent()][zdse][APR_index]["x"]
                local y = APR.TDB["ZoneEntry"][APR:GetContinent()][zdse][APR_index]["y"]
                local deltaX, deltaY = d_x - x, y - d_y
                local distance = (deltaX * deltaX + deltaY * deltaY) ^ 0.5
                if (distance < closest) then
                    closest = distance
                    zeX = x
                    zeY = y
                end
            end
            return APR.TDB["ZoneMoveOrder"][APRt_Zone][GoToZone], zeX, zeY
        end
    end
end

function APR.FP.GetStarterZoneFP(GoToZone, DestCont)
    if (DestCont) then
        for APR_index, APR_value in pairs(APR.TDB["FPs"][APR.Faction][DestCont][GoToZone]) do
            if (APR.TDB["FPs"][APR.Faction][DestCont][GoToZone][APR_index]["Starter"]) then
                local zclosestname
                if (APR_Transport["FPs"] and APR_Transport["FPs"][APR.Faction] and APR_Transport["FPs"][APR.Faction][DestCont] and APR_Transport["FPs"][APR.Faction][DestCont]["fpn"] and APR_Transport["FPs"][APR.Faction][DestCont]["fpn"][APR_index]) then
                    zclosestname = APR_Transport["FPs"][APR.Faction][DestCont]["fpn"][APR_index]
                else
                    zclosestname = APR.TDB["FPs"][APR.Faction][DestCont][GoToZone][APR_index]["name"]
                end
                return zclosestname, APR_index
            end
        end
    elseif (GoToZone and APR.TDB["FPs"][APR.Faction][APR:GetContinent()] and APR.TDB["FPs"][APR.Faction][APR:GetContinent()][GoToZone]) then
        for APR_index, APR_value in pairs(APR.TDB["FPs"][APR.Faction][APR:GetContinent()][GoToZone]) do
            if (APR.TDB["FPs"][APR.Faction][APR:GetContinent()][GoToZone][APR_index]["Starter"]) then
                local zclosestname
                if (APR_Transport["FPs"] and APR_Transport["FPs"][APR.Faction] and APR_Transport["FPs"][APR.Faction][APR:GetContinent()] and APR_Transport["FPs"][APR.Faction][APR:GetContinent()]["fpn"] and APR_Transport["FPs"][APR.Faction][APR:GetContinent()]["fpn"][APR_index]) then
                    zclosestname = APR_Transport["FPs"][APR.Faction][APR:GetContinent()]["fpn"][APR_index]
                else
                    zclosestname = APR.TDB["FPs"][APR.Faction][APR:GetContinent()][GoToZone][APR_index]["name"]
                end
                return zclosestname, APR_index
            end
        end
    end
end

function APR.FP.IsSameContinent(GoToZone)
    local CurContinent = APR:GetContinent()
    if (APR.TDB["FPs"][APR.Faction]) then
        for APR_index, APR_value in pairs(APR.TDB["FPs"][APR.Faction]) do
            for APR_index2, APR_value2 in pairs(APR.TDB["FPs"][APR.Faction][APR_index]) do
                if (APR_index2 == GoToZone) then
                    if (CurContinent == APR_index) then
                        return 1, APR_index
                    else
                        return 0, APR_index
                    end
                end
            end
        end
    end
    return L["CONTINENT_NOT_FOUND"]
end

function APR.FP.SwitchCont(CurContinent, gotoCont, GoToZone)
    local APRt_Zone = C_Map.GetBestMapForUnit("player")
    local currentMapId, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
    APRt_Zone = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent + 1, TOP_MOST)
    if (APRt_Zone and APRt_Zone["mapID"]) then
        APRt_Zone = APRt_Zone["mapID"]
    else
        APRt_Zone = C_Map.GetBestMapForUnit("player")
    end
    APRt_Zone = APR.FP.GetMeToNextZoneSpecialRe(APRt_Zone)
    if (APR.Faction == "Alliance") then
        if (CurContinent == 13) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Stormwind, Elwynn") then
                local d_y, d_x = UnitPosition("player")
                if (d_y < -8981.3 and d_x > 866.7) then
                    if (gotoCont == 12) then
                        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Exodar",
                            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(103).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Exodar"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Exodar"]["y"]
                    elseif (gotoCont == 101) then
                        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Shattrath",
                            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(111).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Shattrath"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Shattrath"]["y"]
                    elseif (gotoCont == 113) then
                        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Dalaran, Crystalsong Forest",
                            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(125).name .. ', ' .. C_Map.GetMapInfo(127)
                            .name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["DalaranLichKing"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["DalaranLichKing"]["y"]
                    elseif (gotoCont == 424) then
                        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Jade Forest",
                            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(371).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["JadeForestMoP"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["JadeForestMoP"]["y"]
                    elseif (gotoCont == 572) then
                        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormshield",
                            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(622).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["StormshieldWoD"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["StormshieldWoD"]["y"]
                    elseif (gotoCont == 619) then
                        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Azsuna",
                            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(630).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["AzsunaLegion"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["AzsunaLegion"]["y"]
                    elseif (gotoCont == 875 or gotoCont == 876) then
                        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Boralus",
                            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(1161).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["BoralusBFA"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["BoralusBFA"]["y"]
                    end
                else
                    APR.currentStep:AddExtraLineText("GO_PORTAL_ROOM", L["GO_PORTAL_ROOM"])
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["StormwindPortalRoom"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["StormwindPortalRoom"]["y"]
                end
            else
                local zclosestname
                if (APR_Transport["FPs"] and APR_Transport["FPs"][APR.Faction] and APR_Transport["FPs"][APR.Faction][13] and APR_Transport["FPs"][APR.Faction][13]["fpn"] and APR_Transport["FPs"][APR.Faction][13]["fpn"][2]) then
                    zclosestname = APR_Transport["FPs"][APR.Faction][13]["fpn"][2]
                else
                    zclosestname = APR.TDB["FPs"][APR.Faction][13][84][2]["name"]
                end
                APR.currentStep:AddExtraLineText("FLY_TO_" .. zclosestname, L["FLY_TO"] .. " " ..
                    zclosestname)
                APR.FP.QuedFP = zclosestname
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 101) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Shattrath, Terokkar Forest") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormwind",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(84).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Shattrath", L["FLY_TO"] .. " " ..
                    C_Map.GetMapInfo(108).name)
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 113) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Dalaran") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormwind",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(84).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Dalaran", L["FLY_TO"] .. " " ..
                    C_Map.GetMapInfo(41).name)
                APR.FP.QuedFP = "Dalaran"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 1550) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Oribos") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormwind",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(84).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["y"]
            else
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (APRt_Zone == 1536) then
                    if (zdep == "Theater of Pain, Maldraxxus") then
                        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Oribos",
                            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(1670).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["OribosInMaldraxxus"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["OribosInMaldraxxus"]["y"]
                    else
                        APR.currentStep:AddExtraLineText("FLY_TO_", L["FLY_TO"] .. " " ..
                            C_Map.GetMapInfo(1683).name .. ', ' .. C_Map.GetMapInfo(1689).name)
                        APR.FP.QuedFP = "Theater of Pain, Maldraxxus"
                        local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                        if (Zefp) then
                            APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                            APR.ArrowActive = 1
                            APR.ArrowActive_X = ZeX
                            APR.ArrowActive_Y = ZeY
                        end
                    end
                else
                    APR.currentStep:AddExtraLineText("FLY_TO_Oribos", L["FLY_TO"] .. " " ..
                        C_Map.GetMapInfo(1670).name)
                    APR.FP.QuedFP = "Oribos"
                    if (Zefp) then
                        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = ZeX
                        APR.ArrowActive_Y = ZeY
                    end
                end
            end
        elseif (CurContinent == 424) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Paw'Don Village, Jade Forest") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormwind",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(84).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Paw'Don Village", L["FLY_TO"] .. " Paw'Don Village, " ..
                    C_Map.GetMapInfo(371).name)
                APR.FP.QuedFP = "Paw'Don Village, Jade Forest"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 572) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Stormshield (Alliance), Ashran") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormwind",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(84).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Stormshield", L["FLY_TO"] .. " " ..
                    C_Map.GetMapInfo(622).name)
                APR.FP.QuedFP = "Stormshield (Alliance), Ashran"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 12) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "The Exodar") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormwind",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(84).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Exodar", L["FLY_TO"] .. " " ..
                    C_Map.GetMapInfo(103).name)
                APR.FP.QuedFP = "The Exodar"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 619) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Dalaran") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormwind",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(84).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Dalaran", L["FLY_TO"] .. " " ..
                    C_Map.GetMapInfo(125).name)
                APR.FP.QuedFP = "Dalaran"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 875) then
            local zdep = APR.FP.ClosestFP()
            if (APRt_Zone == 862) then
                if (zdep == "Xibala, Zuldazar") then
                    APR.currentStep:AddExtraLineText("TALK_TO_Daria", L["TALK_TO"] .. " Daria Smithson")
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Zuldazar"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Zuldazar"]["y"]
                else
                    APR.currentStep:AddExtraLineText("FLY_TO_", L["FLY_TO"] .. " Xibala, " ..
                        C_Map.GetMapInfo(862).name)
                    APR.FP.QuedFP = "Xibala, Zuldazar"
                    local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                    if (Zefp) then
                        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = ZeX
                        APR.ArrowActive_Y = ZeY
                    end
                end
            elseif (APRt_Zone == 863) then
                if (zdep == "Fort Victory, Nazmir") then
                    APR.currentStep:AddExtraLineText("TALK_TO_Desha Stormwallow", L["TALK_TO"] .. " Desha Stormwallow")
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Nazmir"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Nazmir"]["y"]
                else
                    APR.currentStep:AddExtraLineText("FLY_TO_", L["FLY_TO"] .. " Fort Victory, " ..
                        C_Map.GetMapInfo(863).name)
                    APR.FP.QuedFP = "Fort Victory, Nazmir"
                    local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                    if (Zefp) then
                        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = ZeX
                        APR.ArrowActive_Y = ZeY
                    end
                end
            elseif (APRt_Zone == 864) then
                if (zdep == "Shatterstone Harbor, Vol'dun") then
                    APR.currentStep:AddExtraLineText("TALK_TO_Grand Admiral Jes-Tereth",
                        L["TALK_TO"] .. " Grand Admiral Jes-Tereth")
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Vol'dun"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Vol'dun"]["y"]
                else
                    APR.currentStep:AddExtraLineText("FLY_TO_Shatterstone Harbor",
                        L["FLY_TO"] .. " Shatterstone Harbor, " ..
                        C_Map.GetMapInfo(864).name)
                    APR.FP.QuedFP = "Shatterstone Harbor, Vol'dun"
                    local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                    if (Zefp) then
                        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = ZeX
                        APR.ArrowActive_Y = ZeY
                    end
                end
            end
        elseif (CurContinent == 876) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Tradewinds Market, Tiragarde Sound") then
                if (gotoCont == 875) then
                    if (GoToZone == 862) then
                        APR.currentStep:AddExtraLineText("SAIL_TO_Zuldazar",
                            L["SAIL_TO"] .. " " .. C_Map.GetMapInfo(862).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Zuldazar"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Zuldazar"]["y"]
                    elseif (GoToZone == 863) then
                        APR.currentStep:AddExtraLineText("SAIL_TO_Nazmir",
                            L["SAIL_TO"] .. " " .. C_Map.GetMapInfo(863).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Nazmir"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Nazmir"]["y"]
                    elseif (GoToZone == 864) then
                        APR.currentStep:AddExtraLineText("SAIL_TO_Voldun",
                            L["SAIL_TO"] .. " " .. C_Map.GetMapInfo(864).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Vol'dun"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Vol'dun"]["y"]
                    end
                else
                    APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Stormwind",
                        L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(84).name)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Stormwind"]["y"]
                end
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Tradewinds Market", L["FLY_TO"] .. " Tradewinds Market, " ..
                    C_Map.GetMapInfo(895).name)
                APR.FP.QuedFP = "Tradewinds Market, Tiragarde Sound"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        end
    else
        if (CurContinent == 12) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Orgrimmar, Durotar") then
                if (gotoCont == 13) then
                    if (GoToZone == 51 or GoToZone == 224 or GoToZone == 17 or GoToZone == 36) then
                        APR.currentStep:AddExtraLineText("USE_ZEPPELIN_TO_Stranglethorn",
                            L["USE_ZEPPELIN_TO"] .. " " .. C_Map.GetMapInfo(224).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["STVZep"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["STVZep"]["y"]
                    else
                        APR.currentStep:AddExtraLineText("USE_ZEPPELIN_TO_Undercity",
                            L["USE_ZEPPELIN_TO"] .. " " .. C_Map.GetMapInfo(90).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Undercity"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Undercity"]["y"]
                    end
                elseif (gotoCont == 101) then
                    APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Shattrath",
                        L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(111).name)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Shattrath"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Shattrath"]["y"]
                elseif (gotoCont == 113) then
                    APR.currentStep:AddExtraLineText("USE_PORTAL_TO_ Dalaran, Crystalsong Forest",
                        L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(126).name .. ', ' .. C_Map.GetMapInfo(127).name)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["DalaranLichKing"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["DalaranLichKing"]["y"]
                elseif (gotoCont == 424) then
                    APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Jade Forest",
                        L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(371).name)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["JadeForest"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["JadeForest"]["y"]
                elseif (gotoCont == 572) then
                    APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Warspear",
                        L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(624).name)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["WarspearWoD"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["WarspearWoD"]["y"]
                elseif (gotoCont == 619) then
                    APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Azsuna",
                        L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(630).name)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["AzsunaLegion"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["AzsunaLegion"]["y"]
                elseif (gotoCont == 875 or gotoCont == 876) then
                    APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Zuldazar",
                        L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(862).name)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Zuldazar"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Zuldazar"]["y"]
                end
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Orgrimmar", L["FLY_TO"] .. " " ..
                    C_Map.GetMapInfo(85).name)
                APR.FP.QuedFP = "Orgrimmar, Durotar"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 1550) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Oribos") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["y"]
            else
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (APRt_Zone == 1536) then
                    if (zdep == "Theater of Pain, Maldraxxus") then
                        APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Oribos",
                            L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(1670).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["OribosInMaldraxxus"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["OribosInMaldraxxus"]["y"]
                    else
                        APR.currentStep:AddExtraLineText("FLY_TO_Theater of Pain, Maldraxxus", L["FLY_TO"] .. " " ..
                            C_Map.GetMapInfo(1683).name .. ', ' .. C_Map.GetMapInfo(1689).name)
                        APR.FP.QuedFP = "Theater of Pain, Maldraxxus"
                        local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                        if (Zefp) then
                            APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                            APR.ArrowActive = 1
                            APR.ArrowActive_X = ZeX
                            APR.ArrowActive_Y = ZeY
                        end
                    end
                else
                    APR.currentStep:AddExtraLineText("FLY_TO_Oribos", L["FLY_TO"] .. " " ..
                        C_Map.GetMapInfo(1670).name)
                    APR.FP.QuedFP = "Oribos"
                    if (Zefp) then
                        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = ZeX
                        APR.ArrowActive_Y = ZeY
                    end
                end
            end
        elseif (CurContinent == 13) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Brill, Tirisfal Glades") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Brill", L["FLY_TO"] .. " Brill, " ..
                    C_Map.GetMapInfo(18).name)
                APR.FP.QuedFP = "Brill, Tirisfal Glades"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 101) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Shattrath, Terokkar Forest") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Shattrath, Terokkar Forest", L["FLY_TO"] .. " " ..
                    C_Map.GetMapInfo(111).name .. ', ' .. C_Map.GetMapInfo(108).name)
                APR.FP.QuedFP = "Shattrath, Terokkar Forest"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 113) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Dalaran") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Dalaran", L["FLY_TO"] .. " " ..
                    C_Map.GetMapInfo(125).name)
                APR.FP.QuedFP = "Dalaran"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 424) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Honeydew Village, Jade Forest") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Honeydew Village", L["FLY_TO"] .. " Honeydew Village, " ..
                    C_Map.GetMapInfo(371).name)
                APR.FP.QuedFP = "Honeydew Village, Jade Forest"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 572) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Warspear, Ashran") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Warspear", L["FLY_TO"] .. " " ..
                    C_Map.GetMapInfo(624).name)
                APR.FP.QuedFP = "Warspear, Ashran"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 619) then
            local zdep = APR.FP.ClosestFP()
            if (zdep == "Dalaran") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_Dalaran", L["FLY_TO"] .. " " ..
                    C_Map.GetMapInfo(41).name)
                APR.FP.QuedFP = "Dalaran"
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 875) then
            local zdep = APR.FP.ClosestFP()
            if (gotoCont == 876) then
                if (zdep == "Port of Zandalar, Zuldazar") then
                    if (GoToZone == 896) then
                        APR.currentStep:AddExtraLineText("SAIL_TO_Drustvar",
                            L["SAIL_TO"] .. " " .. C_Map.GetMapInfo(896).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Drustvar"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Drustvar"]["y"]
                    elseif (GoToZone == 942) then
                        APR.currentStep:AddExtraLineText("SAIL_TO_Stormsong Valley",
                            L["SAIL_TO"] .. " " .. C_Map.GetMapInfo(942).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["StormsongValley"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["StormsongValley"]["y"]
                    elseif (GoToZone == 895) then
                        APR.currentStep:AddExtraLineText("SAIL_TO_Tiragarde Sound",
                            L["SAIL_TO"] .. " " .. C_Map.GetMapInfo(895).name)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["TiragardeSound"]["x"]
                        APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["TiragardeSound"]["y"]
                    end
                else
                    APR.currentStep:AddExtraLineText("FLY_TO_Port of Zandalar", L["FLY_TO"] .. " Port of Zandalar, " ..
                        C_Map.GetMapInfo(862).name)
                    APR.FP.QuedFP = "Port of Zandalar, Zuldazar"
                    local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                    if (Zefp) then
                        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = ZeX
                        APR.ArrowActive_Y = ZeY
                    end
                end
            elseif (zdep == "The Great Seal") then
                APR.currentStep:AddExtraLineText("USE_PORTAL_TO_Orgrimmar",
                    L["USE_PORTAL_TO"] .. " " .. C_Map.GetMapInfo(85).name)
                APR.ArrowActive = 1
                APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["x"]
                APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["Orgrimmar"]["y"]
            else
                APR.currentStep:AddExtraLineText("FLY_TO_The Great Seal", L["FLY_TO"] .. " The Great Seal, " ..
                    C_Map.GetMapInfo(1165).name)
                APR.FP.QuedFP = "The Great Seal"
                local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                if (Zefp) then
                    APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = ZeX
                    APR.ArrowActive_Y = ZeY
                end
            end
        elseif (CurContinent == 876) then
            local zdep = APR.FP.ClosestFP()
            if (APRt_Zone == 896) then
                if (zdep == "Anyport, Drustvar") then
                    APR.currentStep:AddExtraLineText("TALK_TO_Swellthrasher", L["TALK_TO"] .. " Swellthrasher")
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["DrustvarSail"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["DrustvarSail"]["y"]
                else
                    APR.currentStep:AddExtraLineText("FLY_TO_Anyport", L["FLY_TO"] .. " Anyport, " ..
                        C_Map.GetMapInfo(896).name)
                    APR.FP.QuedFP = "Anyport, Drustvar"
                    local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                    if (Zefp) then
                        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = ZeX
                        APR.ArrowActive_Y = ZeY
                    end
                end
            elseif (APRt_Zone == 942) then
                if (zdep == "Warfang Hold, Stormsong Valley") then
                    APR.currentStep:AddExtraLineText("TALK_TO_Grok Seahandler", L["TALK_TO"] .. " Grok Seahandler")
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["StormsongValleySail"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["StormsongValleySail"]["y"]
                else
                    APR.currentStep:AddExtraLineText("FLY_TO_Warfang Hold", L["FLY_TO"] .. " Warfang Hold, " ..
                        C_Map.GetMapInfo(942).name)
                    APR.FP.QuedFP = "Warfang Hold, Stormsong Valley"
                    local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                    if (Zefp) then
                        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = ZeX
                        APR.ArrowActive_Y = ZeY
                    end
                end
            elseif (APRt_Zone == 895) then
                if (zdep == "Plunder Harbor, Tiragarde Sound") then
                    print(L["TALK_ERUL"])
                    APR.currentStep:AddExtraLineText("TALK_TO_Erul Dawnbrook", L["TALK_TO"] .. " Erul Dawnbrook")
                    APR.ArrowActive = 1
                    APR.ArrowActive_X = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["TiragardeSoundSail"]["x"]
                    APR.ArrowActive_Y = APR.TDB["Ports"][APR.Faction][APR:GetContinent()]["TiragardeSoundSail"]["y"]
                else
                    APR.currentStep:AddExtraLineText("FLY_TO_Plunder Harbor", L["FLY_TO"] .. " Plunder Harbor, " ..
                        C_Map.GetMapInfo(895).name)
                    APR.FP.QuedFP = "Plunder Harbor, Tiragarde Sound"
                    local Zefp, ZeX, ZeY = APR.FP.ClosestFP()
                    if (Zefp) then
                        APR.currentStep:AddExtraLineText("CLOSEST_FP" .. Zefp, L["CLOSEST_FP"] .. ": " .. Zefp)
                        APR.ArrowActive = 1
                        APR.ArrowActive_X = ZeX
                        APR.ArrowActive_Y = ZeY
                    end
                end
            end
        end
    end
end

function APR.FP.ClosestFP()
    if (APR.settings.profile.debug) then
        print("Function: APR.FP.ClosestFP()")
    end
    local testinstsance = UnitPosition("player")
    if (not testinstsance) then
        return
    end
    local APRt_Zone = C_Map.GetBestMapForUnit("player")
    local currentMapId, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
    if (not currentMapId) then
        return
    end
    APRt_Zone = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent + 1, TOP_MOST)
    if (APRt_Zone and APRt_Zone["mapID"]) then
        APRt_Zone = APRt_Zone["mapID"]
    else
        APRt_Zone = C_Map.GetBestMapForUnit("player")
    end
    APRt_Zone = APR.FP.GetMeToNextZoneSpecialRe(APRt_Zone)
    if (APR.TDB["FPs"][APR.Faction][APR:GetContinent()] and APR.TDB["FPs"][APR.Faction][APR:GetContinent()][APRt_Zone]) then
        local cloasest = 99999
        local closestname = "derp"
        local closestx = 0
        local closesty = 0
        local zclosestname
        for APR_index, APR_value in pairs(APR.TDB["FPs"][APR.Faction][APR:GetContinent()][APRt_Zone]) do
            local d_y, d_x = UnitPosition("player")
            x = APR.TDB["FPs"][APR.Faction][APR:GetContinent()][APRt_Zone][APR_index]["x"]
            y = APR.TDB["FPs"][APR.Faction][APR:GetContinent()][APRt_Zone][APR_index]["y"]
            if (APR_Transport["FPs"] and APR_Transport["FPs"][APR.Faction] and APR_Transport["FPs"][APR.Faction][APR:GetContinent()] and APR_Transport["FPs"][APR.Faction][APR:GetContinent()]["fpn"] and APR_Transport["FPs"][APR.Faction][APR:GetContinent()]["fpn"][APR_index]) then
                zclosestname = APR_Transport["FPs"][APR.Faction][APR:GetContinent()]["fpn"][APR_index]
            else
                zclosestname = APR.TDB["FPs"][APR.Faction][APR:GetContinent()][APRt_Zone][APR_index]["name"]
            end
            local deltaX, deltaY = d_x - x, y - d_y
            local distance = (deltaX * deltaX + deltaY * deltaY) ^ 0.5
            if (cloasest > distance) then
                cloasest = distance
                closestname = zclosestname
                closestx = x
                closesty = y
            end
        end
        return closestname, closestx, closesty
    end
end

APR_Transport_EventFrame = CreateFrame("Frame")
APR_Transport_EventFrame:RegisterEvent("TAXIMAP_OPENED")
APR_Transport_EventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
APR_Transport_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
APR_Transport_EventFrame:SetScript("OnEvent", function(self, event, ...)
    if not APR.settings.profile.enableAddon then
        return
    end
    if (event == "PLAYER_LEAVING_WORLD") then
        APR.FP.Zonening = 1
    elseif (event == "PLAYER_ENTERING_WORLD") then
        APR.FP.Zonening = 0
        if (APR.ZoneTransfer) then
            APR.BookingList["GetMeToNextZone2"] = 1
        end
    elseif (event == "TAXIMAP_OPENED") then
        if (not APR_Transport) then
            APR_Transport = {}
        end
        if (not APR_Transport["FPs"]) then
            APR_Transport["FPs"] = {}
        end
        if (not APR_Transport["FPs"][APR.Faction]) then
            APR_Transport["FPs"][APR.Faction] = {}
        end
        if (not APR_Transport["FPs"][APR.Faction][APR:GetContinent()]) then
            APR_Transport["FPs"][APR.Faction][APR:GetContinent()] = {}
        end
        if (not APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm]) then
            APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm] = {}
        end
        local CLi
        if (not APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm]["Conts"]) then
            APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm]["Conts"] = {}
        end
        if (not APR_Transport["FPs"][APR.Faction][APR:GetContinent()]["fpn"]) then
            APR_Transport["FPs"][APR.Faction][APR:GetContinent()]["fpn"] = {}
        end
        APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm]["Conts"][APR:GetContinent()] = 1
        local APRt_Zone = C_Map.GetBestMapForUnit("player")
        local currentMapId, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
        if (not currentMapId) then
            return
        end
        APRt_Zone = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent + 1, TOP_MOST)
        if (APRt_Zone and APRt_Zone["mapID"]) then
            APRt_Zone = APRt_Zone["mapID"]
        else
            APRt_Zone = C_Map.GetBestMapForUnit("player")
        end
        APRt_Zone = APR.FP.GetMeToNextZoneSpecialRe(APRt_Zone)
        local ZeFPS = C_TaxiMap.GetAllTaxiNodes(APRt_Zone)
        for APR_index2, APR_value2 in PairsByKeys(ZeFPS) do
            local NodeIDZ = ZeFPS[APR_index2]["nodeID"]
            local ZName = ZeFPS[APR_index2]["name"]
            local ZState = ZeFPS[APR_index2]["state"]
            APR_Transport["FPs"][APR.Faction][APR:GetContinent()]["fpn"][NodeIDZ] = ZName
            if (ZState == 0) then
                APR.TaxiTimerCur = ZName
            end
            if (ZState == 2) then
                --APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name.."-"..APR.Realm][NodeIDZ] = 0
            else
                APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Name .. "-" .. APR.Realm][NodeIDZ] = 1
            end
        end
        local CurStep = APRData[APR.Realm][APR.Name][APR.ActiveMap]
        local steps
        if (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
            steps = APR.QuestStepList[APR.ActiveMap][CurStep]
        end
        if (steps and not IsModifierKeyDown() and APR.settings.profile.autoFlight) then
            local TName = steps["Name"]
            local TContonent = APR:GetContinent()
            if (steps["UseFlightPath"]) then
                local zclosestname
                for APR_index, APR_value in pairs(APR.TDB["FPs"][APR.Faction][TContonent]) do
                    for APR_index2, APR_value2 in pairs(APR.TDB["FPs"][APR.Faction][TContonent][APR_index]) do
                        if (APR.TDB["FPs"][APR.Faction][TContonent][APR_index][APR_index2]["name"] == TName) then
                            if (APR_Transport["FPs"] and APR_Transport["FPs"][APR.Faction] and APR_Transport["FPs"][APR.Faction][TContonent] and APR_Transport["FPs"][APR.Faction][TContonent]["fpn"] and APR_Transport["FPs"][APR.Faction][TContonent]["fpn"][APR_index2]) then
                                zclosestname = APR_Transport["FPs"][APR.Faction][TContonent]["fpn"][APR_index2]
                            else
                                zclosestname = APR.TDB["FPs"][APR.Faction][TContonent][APR_index][APR_index2]["name"]
                            end
                            if (zclosestname) then
                                APR.FP.QuedFP = zclosestname
                                break
                            end
                        end
                    end
                    if (zclosestname) then
                        break
                    end
                end
            end
        end

        if (APR.FP.QuedFP and APR.settings.profile.autoFlight) then
            local Nodetotake
            for CLi = 1, NumTaxiNodes() do
                if (TaxiNodeName(CLi) == APR.FP.QuedFP) then
                    if (steps and steps["UseFlightPath"] and TaxiNodeGetType(CLi) == "CURRENT") then
                        APRData[APR.Realm][APR.Name][APR.ActiveMap] = APRData[APR.Realm][APR.Name][APR.ActiveMap] + 1
                        APR.BookingList["UpdateQuest"] = 1
                        APR.BookingList["PrintQStep"] = 1
                    else
                        Nodetotake = CLi
                    end
                    break
                end
            end
            if (Nodetotake) then
                TakeTaxiNode(Nodetotake)
                APR.TimeFPs(APR.TaxiTimerCur, APR.FP.QuedFP)
                APR.BookingList["TestTaxiFunc"] = 1
                APR.FP.QuedFP = nil
                if (steps and steps["ETA"]) then
                    APR.AFK_Timer(steps["ETA"])
                end
            end
            if (UnitOnTaxi("player")) then
                APR.FP.QuedFP = nil
            end
        end
    end
end)
