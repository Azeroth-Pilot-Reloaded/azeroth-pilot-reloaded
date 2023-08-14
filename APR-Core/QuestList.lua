local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function AddQuestListButton(text, index, buttonFunction)
    APR.QuestList.QuestFrames["FS" .. index].Button = CreateFrame("Button", "APR_SkipActiveButton" .. index,
        APR.QuestList.QuestFrames[index])
    APR.QuestList.QuestFrames["FS" .. index].Button:SetPoint("RIGHT", APR.QuestList.QuestFrames[index], "RIGHT", 0, 0)
    APR.QuestList.QuestFrames["FS" .. index].Button:SetScript("OnMouseDown", buttonFunction)
    local t = APR.QuestList.QuestFrames["FS" .. index].Button:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.QuestList.QuestFrames["FS" .. index].Button)
    APR.QuestList.QuestFrames["FS" .. index].Button.texture = t

    APR.QuestList.QuestFrames["FS" .. index].Fontstring = APR.ArrowFrame:CreateFontString("CLSettingsFS2212", "ARTWORK",
        "ChatFontNormal")
    APR.QuestList.QuestFrames["FS" .. index].Fontstring:SetParent(APR.QuestList.QuestFrames["FS" .. index].Button)
    APR.QuestList.QuestFrames["FS" .. index].Fontstring:SetPoint("CENTER",
        APR.QuestList.QuestFrames["FS" .. index].Button)
    APR.QuestList.QuestFrames["FS" .. index].Fontstring:SetText(text)
    local skiplenght = APR.QuestList.QuestFrames["FS" .. index].Fontstring:GetStringWidth() + 20
    APR.QuestList.QuestFrames["FS" .. index].Button:SetWidth(skiplenght)
    APR.QuestList.QuestFrames["FS" .. index].Button:SetHeight(20)
    APR.QuestList.QuestFrames["FS" .. index].Fontstring:SetWidth(skiplenght)
    APR.QuestList.QuestFrames["FS" .. index].Fontstring:SetHeight(APR.QuestList.QuestFrames["FS" .. index].Button
        :GetHeight() - 3)
    APR.QuestList.QuestFrames["FS" .. index].Fontstring:SetFontObject("GameFontNormalLarge")
    APR.QuestList.QuestFrames["FS" .. index].Fontstring:SetTextColor(1, 1, 0)
    APR.QuestList.QuestFrames["FS" .. index].Button:Hide()
end

local function APR_CreateQuestList()
    if (not APR.PartyList) then
        APR.PartyList = {}
    end
    -- TODO Party group to ACE3 Frame
    APR.PartyList.PartyFrame = CreateFrame("frame", "APR_PartyListFrame1", UIParent)
    APR.PartyList.PartyFrame:SetWidth(1)
    APR.PartyList.PartyFrame:SetHeight(1)
    APR.PartyList.PartyFrame:SetMovable(true)
    APR.PartyList.PartyFrame:EnableMouse(true)
    APR.PartyList.PartyFrame:SetFrameStrata("LOW")
    APR.PartyList.PartyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.partyLeft,
        APR.settings.profile.partyTop)

    APR.PartyList.PartyFrames = {}
    APR.PartyList.PartyFrames2 = {}
    APR.PartyList.PartyFramesFS1 = {}
    APR.PartyList.PartyFramesFS2 = {}
    local CLi
    for CLi = 1, 5 do
        APR.PartyList.PartyFrames[CLi] = CreateFrame("frame", "CLQaaListF" .. CLi, APR.PartyList.PartyFrame)
        APR.PartyList.PartyFrames[CLi]:SetWidth(120)

        APR.PartyList.PartyFrames[CLi]:SetHeight(25)
        APR.PartyList.PartyFrames[CLi]:SetPoint("BOTTOMLEFT", APR.PartyList.PartyFrame, "BOTTOMLEFT", 40,
            -((25 * CLi) - 25))
        APR.PartyList.PartyFrames[CLi]:Hide()
        --APR.PartyList.PartyFrames[CLi]:SetBackdrop( {
        --	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        --	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        --	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
        --});
        local t = APR.PartyList.PartyFrames[CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        t:SetAllPoints(APR.PartyList.PartyFrames[CLi])
        APR.PartyList.PartyFrames[CLi].texture = t

        APR.PartyList.PartyFrames[CLi]:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and not APR.settings.profile.lockCurrentStep then
                APR.PartyList.PartyFrame:StartMoving();
                APR.PartyList.PartyFrame.isMoving = true;
            end
        end)
        APR.PartyList.PartyFrames[CLi]:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and APR.PartyList.PartyFrame.isMoving then
                APR.PartyList.PartyFrame:StopMovingOrSizing();
                APR.PartyList.PartyFrame.isMoving = false;
                APR.settings.profile.partyLeft = APR.PartyList.PartyFrame:GetLeft()
                APR.settings.profile.partyTop = APR.PartyList.PartyFrame:GetTop() - GetScreenHeight()
                --APR.PartyList.PartyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.partyLeft, APR.settings.profile.partyTop)
            end
        end)
        APR.PartyList.PartyFrames[CLi]:SetScript("OnHide", function(self)
            if (APR.PartyList.PartyFrame.isMoving) then
                APR.PartyList.PartyFrame:StopMovingOrSizing();
                APR.PartyList.PartyFrame.isMoving = false;
                APR.settings.profile.partyLeft = APR.PartyList.PartyFrame:GetLeft()
                APR.settings.profile.partyTop = APR.PartyList.PartyFrame:GetTop() - GetScreenHeight()
                --APR.PartyList.PartyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.partyLeft, APR.settings.profile.partyTop)
            end
        end)

        APR.PartyList.PartyFramesFS1[CLi] = APR.PartyList.PartyFrames[CLi]:CreateFontString("CLQaasFS1", "ARTWORK",
            "ChatFontNormal")
        APR.PartyList.PartyFramesFS1[CLi]:SetParent(APR.PartyList.PartyFrames[CLi])
        APR.PartyList.PartyFramesFS1[CLi]:SetPoint("LEFT", APR.PartyList.PartyFrames[CLi], "LEFT", 5, 0)
        APR.PartyList.PartyFramesFS1[CLi]:SetWidth(300)
        APR.PartyList.PartyFramesFS1[CLi]:SetHeight(38)
        APR.PartyList.PartyFramesFS1[CLi]:SetJustifyH("LEFT")
        APR.PartyList.PartyFramesFS1[CLi]:SetFontObject("GameFontNormalLarge")
        APR.PartyList.PartyFramesFS1[CLi]:SetText(L["NAME"])
        APR.PartyList.PartyFramesFS1[CLi]:SetTextColor(1, 1, 0)

        APR.PartyList.PartyFrames2[CLi] = CreateFrame("frame", "CLQaListF" .. CLi, APR.PartyList.PartyFrame)
        APR.PartyList.PartyFrames2[CLi]:SetWidth(40)

        APR.PartyList.PartyFrames2[CLi]:SetHeight(25)
        APR.PartyList.PartyFrames2[CLi]:SetPoint("BOTTOMLEFT", APR.PartyList.PartyFrame, "BOTTOMLEFT", 0,
            -((25 * CLi) - 25))
        APR.PartyList.PartyFrames2[CLi]:Hide()
        --APR.PartyList.PartyFrames2[CLi]:SetBackdrop( {
        --	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        --	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        --	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
        --});
        local t = APR.PartyList.PartyFrames2[CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        t:SetAllPoints(APR.PartyList.PartyFrames2[CLi])
        APR.PartyList.PartyFrames2[CLi].texture = t

        APR.PartyList.PartyFrames2[CLi]:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and not APR.settings.profile.lockCurrentStep then
                APR.PartyList.PartyFrame:StartMoving();
                APR.PartyList.PartyFrame.isMoving = true;
            end
        end)
        APR.PartyList.PartyFrames2[CLi]:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and APR.PartyList.PartyFrame.isMoving then
                APR.PartyList.PartyFrame:StopMovingOrSizing();
                APR.PartyList.PartyFrame.isMoving = false;
                APR.settings.profile.partyLeft = APR.PartyList.PartyFrame:GetLeft()
                APR.settings.profile.partyTop = APR.PartyList.PartyFrame:GetTop() - GetScreenHeight()
                APR.PartyList.PartyFrame:ClearAllPoints()
                APR.PartyList.PartyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
                    APR.settings.profile.partyLeft, APR.settings.profile.Partytop)
            end
        end)
        APR.PartyList.PartyFrames2[CLi]:SetScript("OnHide", function(self)
            if (APR.PartyList.PartyFrame.isMoving) then
                APR.PartyList.PartyFrame:StopMovingOrSizing();
                APR.PartyList.PartyFrame.isMoving = false;
                APR.settings.profile.partyLeft = APR.PartyList.PartyFrame:GetLeft()
                APR.settings.profile.partyTop = APR.PartyList.PartyFrame:GetTop() - GetScreenHeight()
                APR.PartyList.PartyFrame:ClearAllPoints()
                APR.PartyList.PartyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
                    APR.settings.profile.partyLeft, APR.settings.profile.Partytop)
            end
        end)

        APR.PartyList.PartyFramesFS2[CLi] = APR.PartyList.PartyFrames2[CLi]:CreateFontString("CLQaasFS1", "ARTWORK",
            "ChatFontNormal")
        APR.PartyList.PartyFramesFS2[CLi]:SetParent(APR.PartyList.PartyFrames[CLi])
        APR.PartyList.PartyFramesFS2[CLi]:SetPoint("CENTER", APR.PartyList.PartyFrames2[CLi], "CENTER", 0, 0)
        APR.PartyList.PartyFramesFS2[CLi]:SetWidth(40)
        APR.PartyList.PartyFramesFS2[CLi]:SetHeight(38)
        APR.PartyList.PartyFramesFS2[CLi]:SetJustifyH("CENTER")
        APR.PartyList.PartyFramesFS2[CLi]:SetFontObject("GameFontNormalLarge")
        APR.PartyList.PartyFramesFS2[CLi]:SetText("123")
        APR.PartyList.PartyFramesFS2[CLi]:SetTextColor(1, 1, 0)
    end

    -- TODO SugQuestFrame (IDK) to ACE3 Frame
    APR.QuestList.SugQuestFrame = {}
    APR.QuestList.SugQuestFrame = CreateFrame("frame", "APR_SugQuestFrameFrame", UIParent)
    APR.QuestList.SugQuestFrame:SetWidth(300)
    APR.QuestList.SugQuestFrame:SetHeight(150)
    APR.QuestList.SugQuestFrame:SetMovable(true)
    APR.QuestList.SugQuestFrame:EnableMouse(true)
    APR.QuestList.SugQuestFrame:SetFrameStrata("LOW")
    APR.QuestList.SugQuestFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.sugQuestLeft,
        APR.settings.profile.sugQuestTop)
    local t = APR.QuestList.SugQuestFrame:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.QuestList.SugQuestFrame)
    APR.QuestList.SugQuestFrame.texture = t

    APR.QuestList.SugQuestFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            APR.QuestList.SugQuestFrame:StartMoving();
            APR.QuestList.SugQuestFrame.isMoving = true;
        end
    end)
    APR.QuestList.SugQuestFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and APR.QuestList.SugQuestFrame.isMoving then
            APR.QuestList.SugQuestFrame:StopMovingOrSizing();
            APR.QuestList.SugQuestFrame.isMoving = false;
            APR.settings.profile.sugQuestLeft = APR.QuestList.SugQuestFrame:GetLeft()
            APR.settings.profile.sugQuestTop = APR.QuestList.SugQuestFrame:GetTop() - GetScreenHeight()
            APR.QuestList.SugQuestFrame:ClearAllPoints()
            APR.QuestList.SugQuestFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
                APR.settings.profile.sugQuestLeft, APR.settings.profile.sugQuestTop)
        end
    end)
    APR.QuestList.SugQuestFrame:SetScript("OnHide", function(self)
        if (APR.QuestList.SugQuestFrame.isMoving) then
            APR.QuestList.SugQuestFrame:StopMovingOrSizing();
            APR.QuestList.SugQuestFrame.isMoving = false;
        end
    end)
    APR.QuestList.SugQuestFrame:Hide()

    APR.QuestList.SugQuestFrameFS1 = APR.QuestList.SugQuestFrame:CreateFontString("CLQaaFS1", "ARTWORK", "ChatFontNormal")
    APR.QuestList.SugQuestFrameFS1:SetParent(APR.QuestList.SugQuestFrame)
    APR.QuestList.SugQuestFrameFS1:SetPoint("TOPLEFT", APR.QuestList.SugQuestFrame, "TOPLEFT", 0, 0)
    APR.QuestList.SugQuestFrameFS1:SetWidth(300)
    APR.QuestList.SugQuestFrameFS1:SetHeight(38)
    APR.QuestList.SugQuestFrameFS1:SetJustifyH("CENTER")
    APR.QuestList.SugQuestFrameFS1:SetFontObject("GameFontNormalLarge")
    APR.QuestList.SugQuestFrameFS1:SetText(L["Q_TEXT"])
    APR.QuestList.SugQuestFrameFS1:SetTextColor(1, 1, 0)
    APR.QuestList.SugQuestFrameFS2 = APR.QuestList.SugQuestFrame:CreateFontString("CLQaaFS2", "ARTWORK", "ChatFontNormal")
    APR.QuestList.SugQuestFrameFS2:SetParent(APR.QuestList.SugQuestFrame)
    APR.QuestList.SugQuestFrameFS2:SetPoint("TOPLEFT", APR.QuestList.SugQuestFrame, "TOPLEFT", 0, -30)
    APR.QuestList.SugQuestFrameFS2:SetWidth(300)
    APR.QuestList.SugQuestFrameFS2:SetHeight(38)
    APR.QuestList.SugQuestFrameFS2:SetJustifyH("CENTER")
    APR.QuestList.SugQuestFrameFS2:SetFontObject("GameFontNormalLarge")
    APR.QuestList.SugQuestFrameFS2:SetText(L["SUGGESTED_PLAYERS"] .. ": ")
    APR.QuestList.SugQuestFrameFS2:SetTextColor(1, 1, 0)

    APR.QuestList.SugQuestFrame["Button1"] = CreateFrame("Button", "APR_SBX1", UIParent, "SecureActionButtonTemplate")
    APR.QuestList.SugQuestFrame["Button1"]:SetPoint("BOTTOMLEFT", APR.QuestList.SugQuestFrame, "BOTTOMLEFT", 15, 5)
    APR.QuestList.SugQuestFrame["Button1"]:SetWidth(110)
    APR.QuestList.SugQuestFrame["Button1"]:SetHeight(30)
    APR.QuestList.SugQuestFrame["Button1"]:SetText(L["ACCEPT_Q"])
    APR.QuestList.SugQuestFrame["Button1"]:SetParent(APR.QuestList.SugQuestFrame)
    APR.QuestList.SugQuestFrame.Button1:SetNormalFontObject("GameFontNormal")
    APR.QuestList.SugQuestFrame.Button1ntex = APR.QuestList.SugQuestFrame.Button1:CreateTexture()
    APR.QuestList.SugQuestFrame.Button1ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
    APR.QuestList.SugQuestFrame.Button1ntex:SetTexCoord(0, 0.625, 0, 0.6875)
    APR.QuestList.SugQuestFrame.Button1ntex:SetAllPoints()
    APR.QuestList.SugQuestFrame.Button1:SetNormalTexture(APR.QuestList.SugQuestFrame.Button1ntex)
    APR.QuestList.SugQuestFrame.Button1htex = APR.QuestList.SugQuestFrame.Button1:CreateTexture()
    APR.QuestList.SugQuestFrame.Button1htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    APR.QuestList.SugQuestFrame.Button1htex:SetTexCoord(0, 0.625, 0, 0.6875)
    APR.QuestList.SugQuestFrame.Button1htex:SetAllPoints()
    APR.QuestList.SugQuestFrame.Button1:SetHighlightTexture(APR.QuestList.SugQuestFrame.Button1htex)
    APR.QuestList.SugQuestFrame.Button1ptex = APR.QuestList.SugQuestFrame.Button1:CreateTexture()
    APR.QuestList.SugQuestFrame.Button1ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
    APR.QuestList.SugQuestFrame.Button1ptex:SetTexCoord(0, 0.625, 0, 0.6875)
    APR.QuestList.SugQuestFrame.Button1ptex:SetAllPoints()
    APR.QuestList.SugQuestFrame.Button1:SetPushedTexture(APR.QuestList.SugQuestFrame.Button1ptex)
    APR.QuestList.SugQuestFrame["Button1"]:SetScript("OnClick", function(self, arg1)
        APR.QAskPopWantedAsk("yes")
    end)
    APR.QuestList.SugQuestFrame["Button2"] = CreateFrame("Button", "APR_SBX2", UIParent, "SecureActionButtonTemplate")
    APR.QuestList.SugQuestFrame["Button2"]:SetPoint("BOTTOMRIGHT", APR.QuestList.SugQuestFrame, "BOTTOMRIGHT", -15, 5)
    APR.QuestList.SugQuestFrame["Button2"]:SetWidth(110)
    APR.QuestList.SugQuestFrame["Button2"]:SetHeight(30)
    APR.QuestList.SugQuestFrame["Button2"]:SetText(L["DECLINE_Q"])
    APR.QuestList.SugQuestFrame["Button2"]:SetParent(APR.QuestList.SugQuestFrame)
    APR.QuestList.SugQuestFrame.Button2:SetNormalFontObject("GameFontNormal")
    APR.QuestList.SugQuestFrame.Button2ntex = APR.QuestList.SugQuestFrame.Button2:CreateTexture()
    APR.QuestList.SugQuestFrame.Button2ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
    APR.QuestList.SugQuestFrame.Button2ntex:SetTexCoord(0, 0.625, 0, 0.6875)
    APR.QuestList.SugQuestFrame.Button2ntex:SetAllPoints()
    APR.QuestList.SugQuestFrame.Button2:SetNormalTexture(APR.QuestList.SugQuestFrame.Button2ntex)
    APR.QuestList.SugQuestFrame.Button2htex = APR.QuestList.SugQuestFrame.Button2:CreateTexture()
    APR.QuestList.SugQuestFrame.Button2htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    APR.QuestList.SugQuestFrame.Button2htex:SetTexCoord(0, 0.625, 0, 0.6875)
    APR.QuestList.SugQuestFrame.Button2htex:SetAllPoints()
    APR.QuestList.SugQuestFrame.Button2:SetHighlightTexture(APR.QuestList.SugQuestFrame.Button2htex)
    APR.QuestList.SugQuestFrame.Button2ptex = APR.QuestList.SugQuestFrame.Button2:CreateTexture()
    APR.QuestList.SugQuestFrame.Button2ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
    APR.QuestList.SugQuestFrame.Button2ptex:SetTexCoord(0, 0.625, 0, 0.6875)
    APR.QuestList.SugQuestFrame.Button2ptex:SetAllPoints()
    APR.QuestList.SugQuestFrame.Button2:SetPushedTexture(APR.QuestList.SugQuestFrame.Button2ptex)
    APR.QuestList.SugQuestFrame["Button2"]:SetScript("OnClick", function(self, arg1)
        APR.QAskPopWantedAsk("no")
    end)

    -- TODO change to quest log frame + windowlib
    APR.QuestList.MainFrame = CreateFrame("frame", "APR_QuestFrame", UIParent)
    APR.QuestList.MainFrame:SetWidth(1)
    APR.QuestList.MainFrame:SetHeight(1)
    APR.QuestList.MainFrame:SetMovable(true)
    APR.QuestList.MainFrame:EnableMouse(true)
    APR.QuestList.MainFrame:SetFrameStrata("MEDIUM")
    APR.QuestList.MainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.currentStepButtonLeft,
        APR.settings.profile.currentStepButtonTop)
    APR.QuestList.ListFrame = CreateFrame("frame", "APR_QuestFrameList", UIParent)
    if (APR.settings.profile.currentStepButtonTop > 6) then
        APR.settings.profile.currentStepButtonLeft = 150
        APR.settings.profile.currentStepButtonTop = -150
        APR.QuestList.MainFrame:ClearAllPoints()
        APR.QuestList.MainFrame:SetPoint("TOPLEFT", APR.settings.profile.currentStepButtonLeft,
            APR.settings.profile.currentStepButtonTop)
        print("APR: " .. L["QLIST_OUT_SCREEN"])
    end
    APR.QuestList.ListFrame:SetWidth(1)
    APR.QuestList.ListFrame:SetHeight(1)
    APR.QuestList.ListFrame:SetFrameStrata("MEDIUM")
    APR.QuestList.ListFrame:SetPoint("TOPLEFT", APR.QuestList.MainFrame, "TOPLEFT", 0, 0)
    APR.QuestList.ListFrame:SetMovable(true)
    APR.QuestList.ListFrame:EnableMouse(true)
    APR.QuestList.ListFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not APR.QuestList.MainFrame.isMoving and not APR.settings.profile.lockCurrentStep then
            APR.QuestList.MainFrame:StartMoving();
            APR.QuestList.MainFrame.isMoving = true;
        end
    end)
    APR.QuestList.ListFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and APR.QuestList.MainFrame.isMoving then
            APR.QuestList.MainFrame:StopMovingOrSizing();
            APR.QuestList.MainFrame.isMoving = false;
            APR.settings.profile.currentStepButtonLeft = APR.QuestList.MainFrame:GetLeft()
            APR.settings.profile.currentStepButtonTop = APR.QuestList.MainFrame:GetTop() - GetScreenHeight()
            APR.QuestList.MainFrame:ClearAllPoints()
            APR.QuestList.MainFrame:SetPoint("TOPLEFT", APR.settings.profile.currentStepButtonLeft,
                APR.settings.profile.currentStepButtonTop)
            if (APR.settings.profile.currentStepButtonTop > 6) then
                APR.settings.profile.currentStepButtonLeft = 150
                APR.settings.profile.currentStepButtonTop = -150
                APR.QuestList.MainFrame:ClearAllPoints()
                APR.QuestList.MainFrame:SetPoint("TOPLEFT", APR.settings.profile.currentStepButtonLeft,
                    APR.settings.profile.currentStepButtonTop)
                print("APR: " .. L["QLIST_OUT_SCREEN"])
            end
            APR_CombatTestVar = 1
        end
    end)
    APR.QuestList.ListFrame:SetScript("OnHide", function(self)
        if (APR.QuestList.MainFrame.isMoving) then
            APR.QuestList.MainFrame:StopMovingOrSizing();
            APR.QuestList.MainFrame.isMoving = false;
        end
    end)

    APR.QuestList20 = CreateFrame("frame", "APR_QuestFrame20", UIParent)
    APR.QuestList20:SetWidth(1)
    APR.QuestList20:SetHeight(1)
    APR.QuestList20:SetFrameStrata("MEDIUM")
    APR.QuestList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.currentStepButtonLeft,
        APR.settings.profile.currentStepButtonTop)

    APR.QuestList21 = CreateFrame("frame", "APR_QuestFrame21", UIParent)
    APR.QuestList21:SetWidth(1)
    APR.QuestList21:SetHeight(1)
    APR.QuestList21:SetFrameStrata("MEDIUM")
    APR.QuestList21:SetPoint("TOPLEFT", APR.QuestList20, "TOPLEFT", 0, 0)

    APR.QuestList.ButtonParent = CreateFrame("frame", "CLQListFddd", UIParent)
    APR.QuestList.ButtonParent:SetScale(APR.settings.profile.currentStepScale)
    APR.QuestList.QuestFrames = {}
    APR.QuestList2 = {}

    APR.QuestList.QuestFrames["MyProgress"] = CreateFrame("frame", "CLQListMyProgress", APR.QuestList.ListFrame)
    APR.QuestList.QuestFrames["MyProgress"]:SetWidth(150)
    APR.QuestList.QuestFrames["MyProgress"]:SetHeight(22)
    APR.QuestList.QuestFrames["MyProgress"]:SetPoint("BOTTOMLEFT", APR.QuestList.ListFrame, "BOTTOMLEFT", 0, 0)
    --APR.QuestList.QuestFrames["MyProgress"]:SetBackdrop( {
    --	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    --	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    --	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
    --});
    local t = APR.QuestList.QuestFrames["MyProgress"]:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.QuestList.QuestFrames["MyProgress"])
    APR.QuestList.QuestFrames["MyProgress"].texture = t

    APR.QuestList.QuestFrames["MyProgress"]:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not APR.QuestList.MainFrame.isMoving and not APR.settings.profile.lockCurrentStep then
            APR.QuestList.MainFrame:StartMoving();
            APR.QuestList.MainFrame.isMoving = true;
        end
    end)
    APR.QuestList.QuestFrames["MyProgress"]:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and APR.QuestList.MainFrame.isMoving then
            APR.QuestList.MainFrame:StopMovingOrSizing();
            APR.QuestList.MainFrame.isMoving = false;
            APR.settings.profile.currentStepButtonLeft = APR.QuestList.MainFrame:GetLeft()
            APR.settings.profile.currentStepButtonTop = APR.QuestList.MainFrame:GetTop() - GetScreenHeight()
            APR.QuestList.MainFrame:ClearAllPoints()
            APR.QuestList.MainFrame:SetPoint("TOPLEFT", APR.settings.profile.currentStepButtonLeft,
                APR.settings.profile.currentStepButtonTop)
            if (APR.settings.profile.currentStepButtonTop > 6) then
                APR.settings.profile.currentStepButtonLeft = 150
                APR.settings.profile.currentStepButtonTop = -150
                APR.QuestList.MainFrame:ClearAllPoints()
                APR.QuestList.MainFrame:SetPoint("TOPLEFT", APR.settings.profile.currentStepButtonLeft,
                    APR.settings.profile.currentStepButtonTop)
                print("APR: " .. L["QLIST_OUT_SCREEN"])
            end
            APR_CombatTestVar = 1
        end
    end)
    APR.QuestList.QuestFrames["MyProgress"]:SetScript("OnHide", function(self)
        if (APR.QuestList.MainFrame.isMoving) then
            APR.QuestList.MainFrame:StopMovingOrSizing();
            APR.QuestList.MainFrame.isMoving = false;
        end
    end)

    APR.QuestList.QuestFrames["MyProgressFS"] = APR.QuestList.ListFrame:CreateFontString("CLQFSProgR", "ARTWORK",
        "ChatFontNormal")
    APR.QuestList.QuestFrames["MyProgressFS"]:SetParent(APR.QuestList.QuestFrames["MyProgress"])
    APR.QuestList.QuestFrames["MyProgressFS"]:SetPoint("BOTTOMLEFT", APR.QuestList.QuestFrames["MyProgress"],
        "BOTTOMLEFT",
        0, 2)
    APR.QuestList.QuestFrames["MyProgressFS"]:SetWidth(150)
    APR.QuestList.QuestFrames["MyProgressFS"]:SetHeight(18)
    APR.QuestList.QuestFrames["MyProgressFS"]:SetJustifyH("CENTER")
    APR.QuestList.QuestFrames["MyProgressFS"]:SetFontObject("GameFontNormalSmall")
    APR.QuestList.QuestFrames["MyProgressFS"]:SetText("")
    APR.QuestList.QuestFrames["MyProgressFS"]:SetTextColor(1, 1, 0)
    if (not APR.settings.profile.showCurrentStep) then
        APR.QuestList.QuestFrames["MyProgress"]:Hide()
    end
    local CLi
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

        APR.QuestList.QuestFrames[CLi] = CreateFrame("frame", "CLQListF" .. CLi, APR.QuestList.ListFrame)
        APR.QuestList.QuestFrames[CLi]:SetWidth(410)

        APR.QuestList.QuestFrames[CLi]:SetHeight(38)
        APR.QuestList.QuestFrames[CLi]:SetPoint("BOTTOMLEFT", APR.QuestList.ListFrame, "BOTTOMLEFT", 0,
            -((CLi * 38) + CLi))
        --APR.QuestList.QuestFrames[CLi]:SetBackdrop( {
        --	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        --	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        --	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
        --});
        local t = APR.QuestList.QuestFrames[CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        t:SetAllPoints(APR.QuestList.QuestFrames[CLi])
        APR.QuestList.QuestFrames[CLi].texture = t

        APR.QuestList.QuestFrames[CLi]:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and not APR.QuestList.MainFrame.isMoving and not APR.settings.profile.lockCurrentStep then
                APR.QuestList.MainFrame:StartMoving();
                APR.QuestList.MainFrame.isMoving = true;
            end
        end)
        APR.QuestList.QuestFrames[CLi]:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and APR.QuestList.MainFrame.isMoving then
                APR.QuestList.MainFrame:StopMovingOrSizing();
                APR.QuestList.MainFrame.isMoving = false;
                APR.settings.profile.currentStepButtonLeft = APR.QuestList.MainFrame:GetLeft()
                APR.settings.profile.currentStepButtonTop = APR.QuestList.MainFrame:GetTop() - GetScreenHeight()
                APR.QuestList.MainFrame:ClearAllPoints()
                APR.QuestList.MainFrame:SetPoint("TOPLEFT", APR.settings.profile.currentStepButtonLeft,
                    APR.settings.profile.currentStepButtonTop)
                if (APR.settings.profile.currentStepButtonTop > 6) then
                    APR.settings.profile.currentStepButtonLeft = 150
                    APR.settings.profile.currentStepButtonTop = -150
                    APR.QuestList.MainFrame:ClearAllPoints()
                    APR.QuestList.MainFrame:SetPoint("TOPLEFT", APR.settings.profile.currentStepButtonLeft,
                        APR.settings.profile.currentStepButtonTop)
                    print("APR: " .. L["QLIST_OUT_SCREEN"])
                end
                APR_CombatTestVar = 1
            end
        end)
        APR.QuestList.QuestFrames[CLi]:SetScript("OnHide", function(self)
            if (APR.QuestList.MainFrame.isMoving) then
                APR.QuestList.MainFrame:StopMovingOrSizing();
                APR.QuestList.MainFrame.isMoving = false;
            end
        end)
        APR.QuestList.QuestFrames[CLi]:Hide()
        APR.QuestList.QuestFrames["FS" .. CLi] = APR.QuestList.ListFrame:CreateFontString("CLQFS" .. CLi, "ARTWORK",
            "ChatFontNormal")
        APR.QuestList.QuestFrames["FS" .. CLi]:SetParent(APR.QuestList.QuestFrames[CLi])
        APR.QuestList.QuestFrames["FS" .. CLi]:SetPoint("TOPLEFT", APR.QuestList.QuestFrames[CLi], "TOPLEFT", 5, 0)
        APR.QuestList.QuestFrames["FS" .. CLi]:SetWidth(800)
        APR.QuestList.QuestFrames["FS" .. CLi]:SetHeight(38)
        APR.QuestList.QuestFrames["FS" .. CLi]:SetJustifyH("LEFT")
        APR.QuestList.QuestFrames["FS" .. CLi]:SetFontObject("GameFontNormalLarge")
        APR.QuestList.QuestFrames["FS" .. CLi]:SetText("")
        APR.QuestList.QuestFrames["FS" .. CLi]:SetTextColor(1, 1, 0)

        APR.QuestList.QuestFrames["FS" .. CLi]["BQid"] = 0
        --skip waypoint button
        AddQuestListButton(L["SKIP_BUTTON"], CLi, function(self, button)
            local CurStep = APRData[APR.Realm][APR.Name][APR.ActiveMap]
            if (APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
                local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
                if (steps and steps["UseDalaHS"]) then
                    APRData[APR.Realm][APR.Name][APR.ActiveMap] = APRData[APR.Realm][APR.Name][APR.ActiveMap] + 1
                    APR.BookingList["PrintQStep"] = 1
                    APR.QuestList.QuestFrames["FS" .. CLi].Button:Hide()
                else
                    APRData[APR.Realm][APR.Name][APR.ActiveMap] = APRData[APR.Realm][APR.Name][APR.ActiveMap] + 1
                    APR.BookingList["PrintQStep"] = 1
                    APR.QuestList.QuestFrames["FS" .. CLi].Button:Hide()
                end
            end
        end)

        APR.QuestList2["BF" .. CLi] = CreateFrame("frame", "CLQListF2z" .. CLi, APR.QuestList21)
        APR.QuestList2["BF" .. CLi]:SetWidth(410)
        APR.QuestList2["BF" .. CLi]:SetHeight(38)
        APR.QuestList2["BF" .. CLi]:SetPoint("BOTTOMLEFT", APR.QuestList21, "BOTTOMLEFT", 0, 0)

        APR.QuestList2["BF" .. CLi]:Hide()
        APR.QuestList2["BF" .. CLi]:SetParent(APR.QuestList.ButtonParent)
        APR.QuestList2["BF" .. CLi]["APR_Button"] = CreateFrame("Button", "APR_SBX" .. CLi, APR.QuestList2["BF" .. CLi],
            "SecureActionButtonTemplate")
        APR.QuestList2["BF" .. CLi]["APR_Button"]:SetWidth(38)
        APR.QuestList2["BF" .. CLi]["APR_Button"]:SetHeight(38)
        APR.QuestList2["BF" .. CLi]["APR_Button"]:SetText("X")
        APR.QuestList2["BF" .. CLi]["APR_Button"]:SetPoint("LEFT", APR.QuestList2["BF" .. CLi], "RIGHT", 0, 0)
        APR.QuestList2["BF" .. CLi]["APR_Button"]:SetNormalFontObject("GameFontNormalLarge")
        APR.QuestList2["BF" .. CLi]["APR_Buttonntex"] = APR.QuestList2["BF" .. CLi]["APR_Button"]:CreateTexture()
        APR.QuestList2["BF" .. CLi]["APR_Buttonntex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
        APR.QuestList2["BF" .. CLi]["APR_Buttonntex"]:SetTexCoord(0, 0.625, 0, 0.6875)
        APR.QuestList2["BF" .. CLi]["APR_Buttonntex"]:SetAllPoints()
        APR.QuestList2["BF" .. CLi]["APR_Button"]:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Highlight")
        APR.QuestList2["BF" .. CLi]["APR_Buttonhtex"] = APR.QuestList2["BF" .. CLi]["APR_Button"]:CreateTexture()
        APR.QuestList2["BF" .. CLi]["APR_Buttonhtex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
        APR.QuestList2["BF" .. CLi]["APR_Buttonhtex"]:SetTexCoord(0, 0.625, 0, 0.6875)
        APR.QuestList2["BF" .. CLi]["APR_Buttonhtex"]:SetAllPoints()
        APR.QuestList2["BF" .. CLi]["APR_Button"]:SetHighlightTexture(APR.QuestList2["BF" .. CLi]["APR_Buttonhtex"])
        APR.QuestList2["BF" .. CLi]["APR_Buttonptex"] = APR.QuestList2["BF" .. CLi]["APR_Button"]:CreateTexture()
        APR.QuestList2["BF" .. CLi]["APR_Buttonptex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
        APR.QuestList2["BF" .. CLi]["APR_Buttonptex"]:SetTexCoord(0, 0.625, 0, 0.6875)
        APR.QuestList2["BF" .. CLi]["APR_Buttonptex"]:SetAllPoints()
        APR.QuestList2["BF" .. CLi]["APR_Button"]:SetPushedTexture(APR.QuestList2["BF" .. CLi]["APR_Buttonptex"])
        APR.QuestList2["BF" .. CLi]["APR_ButtonCD"] = CreateFrame("Cooldown", "APR_Cooldown" .. CLi,
            APR.QuestList2["BF" .. CLi]["APR_Button"], "CooldownFrameTemplate")
        APR.QuestList2["BF" .. CLi]["APR_ButtonCD"]:SetAllPoints()
    end

    -- TODO SweatOfOurBrowBuffFrame
    APR.QuestList.SweatOfOurBrowBuffFrame = CreateFrame("frame", "APR_SugQuestFrameFramebufffra", UIParent)
    APR.QuestList.SweatOfOurBrowBuffFrame:SetWidth(230)
    APR.QuestList.SweatOfOurBrowBuffFrame:SetHeight(110)
    APR.QuestList.SweatOfOurBrowBuffFrame:SetMovable(true)
    APR.QuestList.SweatOfOurBrowBuffFrame:EnableMouse(true)
    APR.QuestList.SweatOfOurBrowBuffFrame:SetFrameStrata("LOW")
    APR.QuestList.SweatOfOurBrowBuffFrame:SetPoint("TOPLEFT", UIParent, 300, -300)
    --APR.QuestList.SweatOfOurBrowBuffFrame:SetBackdrop( {
    --	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    --	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    --	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
    --});
    APR.QuestList.SweatOfOurBrowBuffFrame:Hide()
    local t = APR.QuestList.SweatOfOurBrowBuffFrame:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.QuestList.SweatOfOurBrowBuffFrame)
    APR.QuestList.SweatOfOurBrowBuffFrame.texture = t

    APR.QuestList.SweatOfOurBrowBuffFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            APR.QuestList.SweatOfOurBrowBuffFrame:StartMoving();
            APR.QuestList.SweatOfOurBrowBuffFrame.isMoving = true;
        end
    end)
    APR.QuestList.SweatOfOurBrowBuffFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and APR.QuestList.SweatOfOurBrowBuffFrame.isMoving then
            APR.QuestList.SweatOfOurBrowBuffFrame:StopMovingOrSizing();
            APR.QuestList.SweatOfOurBrowBuffFrame.isMoving = false;
        end
    end)
    APR.QuestList.SweatOfOurBrowBuffFrame:SetScript("OnHide", function(self)
        if (APR.QuestList.SweatOfOurBrowBuffFrame.isMoving) then
            APR.QuestList.SweatOfOurBrowBuffFrame:StopMovingOrSizing();
            APR.QuestList.SweatOfOurBrowBuffFrame.isMoving = false;
        end
    end)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS1 = APR.QuestList.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS1", "ARTWORK", "ChatFontNormal")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS1:SetParent(APR.QuestList.SweatOfOurBrowBuffFrame)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS1:SetPoint("TOPLEFT", APR.QuestList.SweatOfOurBrowBuffFrame, "TOPLEFT", 5, 0)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS1:SetWidth(300)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS1:SetHeight(38)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS1:SetJustifyH("LEFT")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS1:SetFontObject("GameFontNormal")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS1:SetText(L["NEDD_BUFF_DISARM_TRAP"])
    APR.QuestList.SweatOfOurBrowBuffFrame.FS1:SetTextColor(1, 1, 0)

    APR.QuestList.SweatOfOurBrowBuffFrame.Traps = CreateFrame("frame", "APR_SugQuestFrameFramebufffraTraps",
        APR.QuestList.SweatOfOurBrowBuffFrame)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps:SetWidth(220)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps:SetHeight(18)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps:SetMovable(true)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps:EnableMouse(true)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps:SetFrameStrata("LOW")
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps:SetPoint("TOPLEFT", APR.QuestList.SweatOfOurBrowBuffFrame, "TOPLEFT", 2,
        -40)
    local t = APR.QuestList.SweatOfOurBrowBuffFrame.Traps:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetAllPoints(APR.QuestList.SweatOfOurBrowBuffFrame.Traps)
    t:SetColorTexture(0.5, 0.1, 0.1, 1)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps.texture = t

    APR.QuestList.SweatOfOurBrowBuffFrame.FS2 = APR.QuestList.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS2", "ARTWORK", "ChatFontNormal")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS2:SetParent(APR.QuestList.SweatOfOurBrowBuffFrame.Traps)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS2:SetPoint("LEFT", APR.QuestList.SweatOfOurBrowBuffFrame.Traps, "LEFT", 5, 0)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS2:SetWidth(300)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS2:SetHeight(38)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS2:SetJustifyH("LEFT")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS2:SetFontObject("GameFontNormalSmall")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS2:SetText(L["SOULWEB_TRAP"])
    APR.QuestList.SweatOfOurBrowBuffFrame.FS2:SetTextColor(1, 1, 0)

    APR.QuestList.SweatOfOurBrowBuffFrame.FS21 = APR.QuestList.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS21", "ARTWORK", "ChatFontNormal")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS21:SetParent(APR.QuestList.SweatOfOurBrowBuffFrame.Traps)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS21:SetPoint("LEFT", APR.QuestList.SweatOfOurBrowBuffFrame.Traps, "LEFT", 85,
        0)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS21:SetWidth(300)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS21:SetHeight(38)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS21:SetJustifyH("LEFT")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS21:SetFontObject("GameFontNormalSmall")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS21:SetText(L["FRESHLEAF_BUFF"])
    APR.QuestList.SweatOfOurBrowBuffFrame.FS21:SetTextColor(1, 1, 0)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps2 = CreateFrame("frame", "APR_SugQuestFrameFramebufffraTraps2",
        APR.QuestList.SweatOfOurBrowBuffFrame)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps2:SetWidth(220)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps2:SetHeight(18)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps2:SetMovable(true)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps2:EnableMouse(true)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps2:SetPoint("TOPLEFT", APR.QuestList.SweatOfOurBrowBuffFrame, "TOPLEFT", 2,
        -60)
    local t = APR.QuestList.SweatOfOurBrowBuffFrame.Traps2:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetAllPoints(APR.QuestList.SweatOfOurBrowBuffFrame.Traps2)
    t:SetColorTexture(0.5, 0.1, 0.1, 1)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps2.texture = t
    APR.QuestList.SweatOfOurBrowBuffFrame.FS3 = APR.QuestList.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS3", "ARTWORK", "ChatFontNormal")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS3:SetParent(APR.QuestList.SweatOfOurBrowBuffFrame.Traps2)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS3:SetPoint("LEFT", APR.QuestList.SweatOfOurBrowBuffFrame.Traps2, "LEFT", 5, 0)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS3:SetWidth(300)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS3:SetHeight(38)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS3:SetJustifyH("LEFT")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS3:SetFontObject("GameFontNormalSmall")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS3:SetText(L["HARP_TRAP"])
    APR.QuestList.SweatOfOurBrowBuffFrame.FS3:SetTextColor(1, 1, 0)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS31 = APR.QuestList.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS31", "ARTWORK", "ChatFontNormal")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS31:SetParent(APR.QuestList.SweatOfOurBrowBuffFrame.Traps2)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS31:SetPoint("LEFT", APR.QuestList.SweatOfOurBrowBuffFrame.Traps2, "LEFT", 85,
        0)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS31:SetWidth(300)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS31:SetHeight(38)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS31:SetJustifyH("LEFT")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS31:SetFontObject("GameFontNormalSmall")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS31:SetText(L["GOSSAMER_THREAD_BUFF"])
    APR.QuestList.SweatOfOurBrowBuffFrame.FS31:SetTextColor(1, 1, 0)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps3 = CreateFrame("frame", "APR_SugQuestFrameFramebufffraTraps3",
        APR.QuestList.SweatOfOurBrowBuffFrame)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps3:SetWidth(220)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps3:SetHeight(18)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps3:SetMovable(true)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps3:EnableMouse(true)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps3:SetPoint("TOPLEFT", APR.QuestList.SweatOfOurBrowBuffFrame, "TOPLEFT", 2,
        -80)
    local t = APR.QuestList.SweatOfOurBrowBuffFrame.Traps3:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetAllPoints(APR.QuestList.SweatOfOurBrowBuffFrame.Traps3)
    t:SetColorTexture(0.5, 0.1, 0.1, 1)
    APR.QuestList.SweatOfOurBrowBuffFrame.Traps3.texture = t
    APR.QuestList.SweatOfOurBrowBuffFrame.FS4 = APR.QuestList.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS4", "ARTWORK", "ChatFontNormal")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS4:SetParent(APR.QuestList.SweatOfOurBrowBuffFrame.Traps3)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS4:SetPoint("LEFT", APR.QuestList.SweatOfOurBrowBuffFrame.Traps3, "LEFT", 5, 0)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS4:SetWidth(300)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS4:SetHeight(38)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS4:SetJustifyH("LEFT")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS4:SetFontObject("GameFontNormalSmall")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS4:SetText(L["UNTOUCHED_BASKET"])
    APR.QuestList.SweatOfOurBrowBuffFrame.FS4:SetTextColor(1, 1, 0)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS41 = APR.QuestList.SweatOfOurBrowBuffFrame:CreateFontString(
        "APR_QuestList_SweatOfOurBrowBuffFrame_FS41", "ARTWORK", "ChatFontNormal")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS41:SetParent(APR.QuestList.SweatOfOurBrowBuffFrame.Traps3)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS41:SetPoint("LEFT", APR.QuestList.SweatOfOurBrowBuffFrame.Traps3, "LEFT", 85,
        0)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS41:SetWidth(300)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS41:SetHeight(38)
    APR.QuestList.SweatOfOurBrowBuffFrame.FS41:SetJustifyH("LEFT")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS41:SetFontObject("GameFontNormalSmall")
    APR.QuestList.SweatOfOurBrowBuffFrame.FS41:SetText(L["SHUMMERDUST_BUFF"])
    APR.QuestList.SweatOfOurBrowBuffFrame.FS41:SetTextColor(1, 1, 0)
end

APR.QuestListEventFrame = CreateFrame("Frame")
APR.QuestListEventFrame:RegisterEvent("ADDON_LOADED")
APR.QuestListEventFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "ADDON_LOADED") then
        local arg1, arg2, arg3, arg4, arg5 = ...;
        if (arg1 == "APR-Core") then
            APR_CreateQuestList()
            APR.QuestListLoadin = true
        end
    end
end)
