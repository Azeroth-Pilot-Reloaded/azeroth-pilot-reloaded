local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.Test = {}
local MainQuest = 0
local SubQuestId = 0
local SubQuestName = 0
local ScrollMod = 0
local MapIconOrder = {}
local MapIconUpdateStep = 0
local MapRects = {};
local TempVec2D = CreateVector2D(0, 0);
local function GetPlayerMapPos(MapID, dx, dy)
    local R, P, _ = MapRects[MapID], TempVec2D;
    if not R then
        R = {};
        _, R[1] = C_Map.GetWorldPosFromMapPos(MapID, CreateVector2D(0, 0));
        _, R[2] = C_Map.GetWorldPosFromMapPos(MapID, CreateVector2D(1, 1));
        R[2]:Subtract(R[1]);
        MapRects[MapID] = R;
    end
    if (dx) then
        P.x, P.y = dx, dy
    else
        P.x, P.y = UnitPosition('player');
    end
    P:Subtract(R[1]);
    return (1 / R[2].y) * P.y, (1 / R[2].x) * P.x;
end
function APR.ZoneQuestOrderList()
    if (APR1["Debug"]) then
        print("Function: APR.ZoneQuestOrderList()")
    end
    APR.ZoneQuestOrder = CreateFrame("frame", "APRQOrderList", UIParent)
    APR.ZoneQuestOrder:SetWidth(231)
    APR.ZoneQuestOrder:SetHeight(440)
    APR.ZoneQuestOrder:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    APR.ZoneQuestOrder:SetMovable(true)
    APR.ZoneQuestOrder:EnableMouse(true)

    APR.ZoneQuestOrder.ZoneName = CreateFrame("frame", "APR_ZoneQuestOrder_ZoneName", APR.ZoneQuestOrder)
    APR.ZoneQuestOrder.ZoneName:SetWidth(100)
    APR.ZoneQuestOrder.ZoneName:SetHeight(16)
    APR.ZoneQuestOrder.ZoneName:SetPoint("BOTTOM", APR.ZoneQuestOrder, "TOP", 0, 0)
    local t = APR.ZoneQuestOrder.ZoneName:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.ZoneQuestOrder.ZoneName)
    APR.ZoneQuestOrder.ZoneName.texture = t

    APR.ZoneQuestOrder.ZoneName:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StartMoving();
            APR.ZoneQuestOrder.isMoving = true;
        end
    end)
    APR.ZoneQuestOrder.ZoneName:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder.ZoneName:SetScript("OnHide", function(self)
        if (APR.ZoneQuestOrder.isMoving) then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder.ZoneName.FS = APR.ZoneQuestOrder.ZoneName:CreateFontString("APR_ZoneOrder_lvl60_next1_FS",
        "ARTWORK",
        "ChatFontNormal")
    APR.ZoneQuestOrder.ZoneName.FS:SetParent(APR.ZoneQuestOrder.ZoneName)
    APR.ZoneQuestOrder.ZoneName.FS:SetPoint("CENTER", APR.ZoneQuestOrder.ZoneName, "CENTER", 1, 0)
    APR.ZoneQuestOrder.ZoneName.FS:SetWidth(100)
    APR.ZoneQuestOrder.ZoneName.FS:SetHeight(16)
    APR.ZoneQuestOrder.ZoneName.FS:SetJustifyH("CENTER")
    APR.ZoneQuestOrder.ZoneName.FS:SetFontObject("GameFontNormalSmall")
    APR.ZoneQuestOrder.ZoneName.FS:SetText(L["ZONE"])
    APR.ZoneQuestOrder.ZoneName.FS:SetTextColor(1, 1, 0)

    APR.ZoneQuestOrder["APR_Button"] = CreateFrame("Button", "APR_SBXOZ", APR.ZoneQuestOrder, APR.ZoneQuestOrder)
    APR.ZoneQuestOrder["APR_Button"]:SetWidth(15)
    APR.ZoneQuestOrder["APR_Button"]:SetHeight(15)
    APR.ZoneQuestOrder["APR_Button"]:SetText("X")
    APR.ZoneQuestOrder["APR_Button"]:SetFrameStrata("MEDIUM")
    APR.ZoneQuestOrder["APR_Button"]:SetPoint("TOPRIGHT", APR.ZoneQuestOrder, "TOPRIGHT", 5, 5)
    APR.ZoneQuestOrder["APR_Button"]:SetNormalFontObject("GameFontNormalLarge")
    APR.ZoneQuestOrder["APR_Buttonntex"] = APR.ZoneQuestOrder["APR_Button"]:CreateTexture()
    APR.ZoneQuestOrder["APR_Buttonntex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    APR.ZoneQuestOrder["APR_Buttonntex"]:SetTexCoord(0, 0.625, 0, 0.6875)
    APR.ZoneQuestOrder["APR_Buttonntex"]:SetAllPoints()
    APR.ZoneQuestOrder["APR_Button"]:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    APR.ZoneQuestOrder["APR_Buttonhtex"] = APR.ZoneQuestOrder["APR_Button"]:CreateTexture()
    APR.ZoneQuestOrder["APR_Buttonhtex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    APR.ZoneQuestOrder["APR_Buttonhtex"]:SetTexCoord(0, 0.625, 0, 0.6875)
    APR.ZoneQuestOrder["APR_Buttonhtex"]:SetAllPoints()
    APR.ZoneQuestOrder["APR_Button"]:SetHighlightTexture(APR.ZoneQuestOrder["APR_Buttonhtex"])
    APR.ZoneQuestOrder["APR_Buttonptex"] = APR.ZoneQuestOrder["APR_Button"]:CreateTexture()
    APR.ZoneQuestOrder["APR_Buttonptex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    APR.ZoneQuestOrder["APR_Buttonptex"]:SetTexCoord(0, 0.625, 0, 0.6875)
    APR.ZoneQuestOrder["APR_Buttonptex"]:SetAllPoints()
    APR.ZoneQuestOrder["APR_Button"]:SetPushedTexture(APR.ZoneQuestOrder["APR_Buttonptex"])
    APR.ZoneQuestOrder["APR_Button"]:SetScript("OnClick", function(self, arg1)
        APR1[APR.Realm][APR.Name]["Settings"]["ShowQuestListOrder"] = 0
        APR.ZoneQuestOrder:Hide()
        APR.OptionsFrame.QorderListzCheckButton:SetChecked(false)
    end)
    local t = APR.ZoneQuestOrder:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.ZoneQuestOrder)
    APR.ZoneQuestOrder.texture = t

    APR.ZoneQuestOrder:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StartMoving();
            APR.ZoneQuestOrder.isMoving = true;
        end
    end)
    APR.ZoneQuestOrder:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder:SetScript("OnHide", function(self)
        if (APR.ZoneQuestOrder.isMoving) then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder:SetScript("OnMouseWheel", function(self, arg1)
        if (arg1 == 1) then
            if (ScrollMod ~= 0) then
                ScrollMod = ScrollMod - 1
                APR.UpdateZoneQuestOrderList(ScrollMod)
            end
        else
            ScrollMod = ScrollMod + 1
            APR.UpdateZoneQuestOrderList(ScrollMod)
        end
    end)
    APR.ZoneQuestOrder["Current"] = CreateFrame("frame", "APR_ZoneQuestOrderCurrent", APR.ZoneQuestOrder)
    APR.ZoneQuestOrder["Current"]:SetWidth(25)
    APR.ZoneQuestOrder["Current"]:SetHeight(16)
    APR.ZoneQuestOrder["Current"]:SetPoint("RIGHT", APR.ZoneQuestOrder, "LEFT", 0, 0)
    local t = APR.ZoneQuestOrder["Current"]:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.ZoneQuestOrder["Current"])
    APR.ZoneQuestOrder["Current"].texture = t

    APR.ZoneQuestOrder["Current"]["FS"] = APR.ZoneQuestOrder["Current"]:CreateFontString("APRZoneQuestOrderFSCurrent",
        "ARTWORK", "ChatFontNormal")
    APR.ZoneQuestOrder["Current"]["FS"]:SetParent(APR.ZoneQuestOrder["Current"])
    APR.ZoneQuestOrder["Current"]["FS"]:SetPoint("CENTER", APR.ZoneQuestOrder["Current"], "CENTER", 1, 0)
    APR.ZoneQuestOrder["Current"]["FS"]:SetWidth(25)
    APR.ZoneQuestOrder["Current"]["FS"]:SetHeight(16)
    APR.ZoneQuestOrder["Current"]["FS"]:SetJustifyH("CENTER")
    APR.ZoneQuestOrder["Current"]["FS"]:SetFontObject("GameFontNormalSmall")
    APR.ZoneQuestOrder["Current"]["FS"]:SetText(">>>")
    APR.ZoneQuestOrder["Current"]["FS"]:SetTextColor(1, 1, 0)
    APR.ZoneQuestOrder["Current"]:Hide()
    APR.ZoneQuestOrder["FS"] = {}
    APR.ZoneQuestOrder["FS2"] = {}
    APR.ZoneQuestOrder["Order1"] = {}
    APR.ZoneQuestOrder["Order1iD"] = {}
    APR.ZoneQuestOrder["Order1iDFS"] = {}
    APR.ZoneQuestOrder["OrderName"] = {}
    APR.ZoneQuestOrder["OrderNameFS"] = {}
end

function APR.AddQuestOrderFrame(CLi)
    CLPos = CLi * 16
    APR.ZoneQuestOrder[CLi] = CreateFrame("frame", "APR_ZoneQuestOrder" .. CLi, APR.ZoneQuestOrder)
    APR.ZoneQuestOrder[CLi]:SetWidth(25)
    APR.ZoneQuestOrder[CLi]:SetHeight(16)
    APR.ZoneQuestOrder[CLi]:SetPoint("TOPLEFT", APR.ZoneQuestOrder, "TOPLEFT", 5, -((CLPos) - 11))
    local t = APR.ZoneQuestOrder[CLi]:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.ZoneQuestOrder[CLi])
    APR.ZoneQuestOrder[CLi].texture = t

    APR.ZoneQuestOrder[CLi]:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StartMoving();
            APR.ZoneQuestOrder.isMoving = true;
        end
    end)
    APR.ZoneQuestOrder[CLi]:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder[CLi]:SetScript("OnHide", function(self)
        if (APR.ZoneQuestOrder.isMoving) then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder[CLi]:SetScript("OnMouseWheel", function(self, arg1)
        if (arg1 == 1) then
            if (ScrollMod ~= 0) then
                ScrollMod = ScrollMod - 1
                APR.UpdateZoneQuestOrderList(ScrollMod)
            end
        else
            ScrollMod = ScrollMod + 1
            APR.UpdateZoneQuestOrderList(ScrollMod)
        end
    end)
    APR.ZoneQuestOrder["FS"][CLi] = APR.ZoneQuestOrder[CLi]:CreateFontString("APRZoneQuestOrderFS" .. CLi, "ARTWORK",
        "ChatFontNormal")
    APR.ZoneQuestOrder["FS"][CLi]:SetParent(APR.ZoneQuestOrder[CLi])
    APR.ZoneQuestOrder["FS"][CLi]:SetPoint("CENTER", APR.ZoneQuestOrder[CLi], "CENTER", 1, 0)
    APR.ZoneQuestOrder["FS"][CLi]:SetWidth(25)
    APR.ZoneQuestOrder["FS"][CLi]:SetHeight(16)
    APR.ZoneQuestOrder["FS"][CLi]:SetJustifyH("CENTER")
    APR.ZoneQuestOrder["FS"][CLi]:SetFontObject("GameFontNormalSmall")
    APR.ZoneQuestOrder["FS"][CLi]:SetText(CLi)
    APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 1, 0)

    APR.ZoneQuestOrder["Order1"][CLi] = CreateFrame("frame", "APR_ZoneQuestOrder2A" .. CLi, APR.ZoneQuestOrder)
    APR.ZoneQuestOrder["Order1"][CLi]:SetWidth(100)
    APR.ZoneQuestOrder["Order1"][CLi]:SetHeight(16)
    APR.ZoneQuestOrder["Order1"][CLi]:SetPoint("TOPLEFT", APR.ZoneQuestOrder, "TOPLEFT", 32, -((CLPos) - 11))
    local t = APR.ZoneQuestOrder["Order1"][CLi]:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.ZoneQuestOrder["Order1"][CLi])
    APR.ZoneQuestOrder["Order1"][CLi].texture = t

    APR.ZoneQuestOrder["Order1"][CLi]:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StartMoving();
            APR.ZoneQuestOrder.isMoving = true;
        end
    end)
    APR.ZoneQuestOrder["Order1"][CLi]:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder["Order1"][CLi]:SetScript("OnHide", function(self)
        if (APR.ZoneQuestOrder.isMoving) then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder["Order1"][CLi]:SetScript("OnMouseWheel", function(self, arg1)
        if (arg1 == 1) then
            if (ScrollMod ~= 0) then
                ScrollMod = ScrollMod - 1
                APR.UpdateZoneQuestOrderList(ScrollMod)
            end
        else
            ScrollMod = ScrollMod + 1
            APR.UpdateZoneQuestOrderList(ScrollMod)
        end
    end)
    APR.ZoneQuestOrder["FS2"][CLi] = APR.ZoneQuestOrder["Order1"][CLi]:CreateFontString("APRZoneQuestOrderFS2A" .. CLi,
        "ARTWORK", "ChatFontNormal")
    APR.ZoneQuestOrder["FS2"][CLi]:SetParent(APR.ZoneQuestOrder["Order1"][CLi])
    APR.ZoneQuestOrder["FS2"][CLi]:SetPoint("LEFT", APR.ZoneQuestOrder["Order1"][CLi], "LEFT", 5, 0)
    APR.ZoneQuestOrder["FS2"][CLi]:SetWidth(150)
    APR.ZoneQuestOrder["FS2"][CLi]:SetHeight(16)
    APR.ZoneQuestOrder["FS2"][CLi]:SetJustifyH("LEFT")
    APR.ZoneQuestOrder["FS2"][CLi]:SetFontObject("GameFontNormalSmall")
    APR.ZoneQuestOrder["FS2"][CLi]:SetText("")
    APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 1, 0)
end

function APR.AddQuestIdFrame(CLi)
    CLPos = CLi * 16 + 16

    APR.ZoneQuestOrder["Order1iD"][CLi] = CreateFrame("frame", "APR_ZoneQuestOrder2AID" .. CLi, APR.ZoneQuestOrder)
    APR.ZoneQuestOrder["Order1iD"][CLi]:SetWidth(50)
    APR.ZoneQuestOrder["Order1iD"][CLi]:SetHeight(16)
    APR.ZoneQuestOrder["Order1iD"][CLi]:SetPoint("TOPLEFT", APR.ZoneQuestOrder, "TOPLEFT", 65, -((CLPos) - 11))
    local t = APR.ZoneQuestOrder["Order1iD"][CLi]:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.ZoneQuestOrder["Order1iD"][CLi])
    APR.ZoneQuestOrder["Order1iD"][CLi].texture = t

    APR.ZoneQuestOrder["Order1iD"][CLi]:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StartMoving();
            APR.ZoneQuestOrder.isMoving = true;
        end
    end)
    APR.ZoneQuestOrder["Order1iD"][CLi]:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder["Order1iD"][CLi]:SetScript("OnHide", function(self)
        if (APR.ZoneQuestOrder.isMoving) then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder["Order1iD"][CLi]:SetScript("OnMouseWheel", function(self, arg1)
        if (arg1 == 1) then
            if (ScrollMod ~= 0) then
                ScrollMod = ScrollMod - 1
                APR.UpdateZoneQuestOrderList(ScrollMod)
            end
        else
            ScrollMod = ScrollMod + 1
            APR.UpdateZoneQuestOrderList(ScrollMod)
        end
    end)
    APR.ZoneQuestOrder["Order1iDFS"][CLi] = APR.ZoneQuestOrder["Order1iD"][CLi]:CreateFontString(
        "APRZoneQuestOrderFS2AID" .. CLi, "ARTWORK", "ChatFontNormal")
    APR.ZoneQuestOrder["Order1iDFS"][CLi]:SetParent(APR.ZoneQuestOrder["Order1iD"][CLi])
    APR.ZoneQuestOrder["Order1iDFS"][CLi]:SetPoint("LEFT", APR.ZoneQuestOrder["Order1iD"][CLi], "LEFT", 5, 0)
    APR.ZoneQuestOrder["Order1iDFS"][CLi]:SetWidth(50)
    APR.ZoneQuestOrder["Order1iDFS"][CLi]:SetHeight(16)
    APR.ZoneQuestOrder["Order1iDFS"][CLi]:SetJustifyH("LEFT")
    APR.ZoneQuestOrder["Order1iDFS"][CLi]:SetFontObject("GameFontNormalSmall")
    APR.ZoneQuestOrder["Order1iDFS"][CLi]:SetText("")
    APR.ZoneQuestOrder["Order1iDFS"][CLi]:SetTextColor(1, 1, 0)
end

function APR.AddQuestNameFrame(CLi)
    CLPos = CLi * 16 + 16

    APR.ZoneQuestOrder["OrderName"][CLi] = CreateFrame("frame", "APR_ZoneQuestOrder2NameD" .. CLi, APR.ZoneQuestOrder)
    APR.ZoneQuestOrder["OrderName"][CLi]:SetWidth(50)
    APR.ZoneQuestOrder["OrderName"][CLi]:SetHeight(16)
    APR.ZoneQuestOrder["OrderName"][CLi]:SetPoint("TOPLEFT", APR.ZoneQuestOrder, "TOPLEFT", 120, -((CLPos) - 11))
    local t = APR.ZoneQuestOrder["OrderName"][CLi]:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.ZoneQuestOrder["OrderName"][CLi])
    APR.ZoneQuestOrder["OrderName"][CLi].texture = t

    APR.ZoneQuestOrder["OrderName"][CLi]:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StartMoving();
            APR.ZoneQuestOrder.isMoving = true;
        end
    end)
    APR.ZoneQuestOrder["OrderName"][CLi]:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder["OrderName"][CLi]:SetScript("OnHide", function(self)
        if (APR.ZoneQuestOrder.isMoving) then
            APR.ZoneQuestOrder:StopMovingOrSizing();
            APR.ZoneQuestOrder.isMoving = false;
        end
    end)
    APR.ZoneQuestOrder["OrderName"][CLi]:SetScript("OnMouseWheel", function(self, arg1)
        if (arg1 == 1) then
            if (ScrollMod ~= 0) then
                ScrollMod = ScrollMod - 1
                APR.UpdateZoneQuestOrderList(ScrollMod)
            end
        else
            ScrollMod = ScrollMod + 1
            APR.UpdateZoneQuestOrderList(ScrollMod)
        end
    end)
    APR.ZoneQuestOrder["OrderNameFS"][CLi] = APR.ZoneQuestOrder["OrderName"][CLi]:CreateFontString(
        "APRZoneQuestOrderFS2NameD" .. CLi, "ARTWORK", "ChatFontNormal")
    APR.ZoneQuestOrder["OrderNameFS"][CLi]:SetParent(APR.ZoneQuestOrder["OrderName"][CLi])
    APR.ZoneQuestOrder["OrderNameFS"][CLi]:SetPoint("LEFT", APR.ZoneQuestOrder["OrderName"][CLi], "LEFT", 5, 0)
    APR.ZoneQuestOrder["OrderNameFS"][CLi]:SetWidth(50)
    APR.ZoneQuestOrder["OrderNameFS"][CLi]:SetHeight(16)
    APR.ZoneQuestOrder["OrderNameFS"][CLi]:SetJustifyH("LEFT")
    APR.ZoneQuestOrder["OrderNameFS"][CLi]:SetFontObject("GameFontNormalSmall")
    APR.ZoneQuestOrder["OrderNameFS"][CLi]:SetText("")
    APR.ZoneQuestOrder["OrderNameFS"][CLi]:SetTextColor(1, 1, 0)
end

function APR.UpdateZoneQuestOrderList(APRmod)
    if (APR1["Debug"]) then
        print("Function: APR.UpdateZoneQuestOrderList()")
    end
    if (not APRQuestNames) then
        APRQuestNames = {}
    end
    local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
    local steps
    if (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
        steps = APR.QuestStepList[APR.ActiveMap][CurStep]
    end
    APR.ZoneQuestOrder["Current"]:Hide()
    if (steps) then
        if (not APRmod) then
            APRmod = 0
        end
        if (MainQuest > 0) then
            local CLii
            for CLii = 1, MainQuest do
                APR.ZoneQuestOrder[CLii]:Hide()
                APR.ZoneQuestOrder["Order1"][CLii]:Hide()
                APR.ZoneQuestOrder["FS"][CLii]:SetTextColor(1, 1, 0)
                APR.ZoneQuestOrder["FS2"][CLii]:SetTextColor(1, 1, 0)
            end
        end
        if (SubQuestId > 0) then
            local CLii
            for CLii = 1, SubQuestId do
                APR.ZoneQuestOrder["Order1iD"][CLii]:Hide()
            end
        end
        if (SubQuestName > 0) then
            local CLii
            for CLii = 1, SubQuestName do
                APR.ZoneQuestOrder["OrderName"][CLii]:Hide()
            end
        end
        MainQuest = 0
        SubQuestId = 0
        SubQuestName = 0
        local CLi
        local Pos = 0
        if (APRmod == "LoadIn") then
            if (CurStep > 5) then
                APRmod = CurStep - 5
                ScrollMod = APRmod
            else
                APRmod = 0
            end
        end
        for CLi = 1, 27 do
            local CCLi = CLi + APRmod
            MainQuest = MainQuest + 1
            if (not APR.ZoneQuestOrder[MainQuest]) then
                APR.AddQuestOrderFrame(MainQuest)
            end
            if (Pos > 26) then
                break
            end
            Pos = Pos + 1
            APR.ZoneQuestOrder[CLi]:SetPoint("TOPLEFT", APR.ZoneQuestOrder, "TOPLEFT", 5, -((16 * Pos) - 11))
            APR.ZoneQuestOrder["Order1"][CLi]:SetPoint("TOPLEFT", APR.ZoneQuestOrder, "TOPLEFT", 32, -((16 * Pos) - 11))
            if (APR.QuestStepList[APR.ActiveMap][CCLi]) then
                APR.ZoneQuestOrder["FS"][CLi]:SetText(CCLi)
                if (CurStep == CCLi) then
                    APR.ZoneQuestOrder["Current"]:SetPoint("RIGHT", APR.ZoneQuestOrder[CLi], "LEFT", 0, 0)
                    APR.ZoneQuestOrder["Current"]:Show()
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["ExitTutorial"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["SKIP_TUTORIAL"])
                    if (C_QuestLog.IsOnQuest(APR.QuestStepList[APR.ActiveMap][CCLi]["ExitTutorial"]) or CurStep > CCLi) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["PickUp"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["PICK_UP_Q"])
                    IdList = APR.QuestStepList[APR.ActiveMap][CCLi]["PickUp"]
                    local NrLeft = 0
                    local Flagged = 0
                    local Total = 0
                    for h = 1, getn(IdList) do
                        local theqid = IdList[h]
                        Total = Total + 1
                        if (not APR.ActiveQuests[theqid]) then
                            NrLeft = NrLeft + 1
                        end
                        if (C_QuestLog.IsQuestFlaggedCompleted(theqid) or APR.ActiveQuests[theqid] or APR.BreadCrumSkips[theqid]) then
                            Flagged = Flagged + 1
                        end
                    end
                    if (Total == Flagged) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                        for h = 1, getn(IdList) do
                            local theqid = IdList[h]
                            if (Pos > 26) then
                                break
                            end
                            if (C_QuestLog.IsQuestFlaggedCompleted(theqid) or APR.ActiveQuests[theqid]) then
                            else
                                SubQuestId = SubQuestId + 1
                                if (not APR.ZoneQuestOrder["Order1iD"][SubQuestId]) then
                                    APR.AddQuestIdFrame(SubQuestId)
                                end
                                APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetText(theqid)
                                APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetTextColor(1, 1, 0)
                                Pos = Pos + 1
                                APR.ZoneQuestOrder["Order1iD"][SubQuestId]:SetPoint("TOPLEFT", APR.ZoneQuestOrder,
                                    "TOPLEFT", 65,
                                    -((16 * Pos) - 11))
                                APR.ZoneQuestOrder["Order1iD"][SubQuestId]:Show()
                                if (APRQuestNames[theqid] and APRQuestNames[theqid] ~= 1) then
                                    SubQuestName = SubQuestName + 1
                                    if (not APR.ZoneQuestOrder["OrderName"][SubQuestName]) then
                                        APR.AddQuestNameFrame(SubQuestName)
                                    end
                                    APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetPoint("TOPLEFT", APR.ZoneQuestOrder,
                                        "TOPLEFT", 120,
                                        -((16 * Pos) - 11))
                                    APR.ZoneQuestOrder["OrderName"][SubQuestName]:Show()
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetText(APRQuestNames[theqid])
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(250)
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(APR.ZoneQuestOrder
                                        ["OrderNameFS"]
                                        [SubQuestName]:GetStringWidth() + 10)
                                    APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetWidth(APR.ZoneQuestOrder
                                        ["OrderNameFS"][SubQuestName]
                                        :GetStringWidth() + 10)
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetTextColor(1, 1, 0)
                                end
                            end
                        end
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["Qpart"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["Q_PART"])
                    IdList = APR.QuestStepList[APR.ActiveMap][CCLi]["Qpart"]
                    local Flagged = 0
                    local Total = 0
                    for APR_index, APR_value in pairs(IdList) do
                        for APR_index2, APR_value2 in pairs(APR_value) do
                            Total = Total + 1
                            local qid = APR_index .. "-" .. APR_index2
                            if (C_QuestLog.IsQuestFlaggedCompleted(APR_index) or ((UnitLevel("player") == 120) and APR_BonusObj and APR_BonusObj[APR_index]) or APR1[APR.Realm][APR.Name]["BonusSkips"][APR_index]) then
                                Flagged = Flagged + 1
                            elseif (APR.ActiveQuests[qid] and APR.ActiveQuests[qid] == "C") then
                                Flagged = Flagged + 1
                            elseif (APR.ActiveQuests[qid] or not APR.ActiveQuests[APR_index]) then
                                APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                                APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                                local theqid = APR_index
                                if (Pos > 26) then
                                    break
                                end
                                SubQuestId = SubQuestId + 1
                                if (not APR.ZoneQuestOrder["Order1iD"][SubQuestId]) then
                                    APR.AddQuestIdFrame(SubQuestId)
                                end
                                APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetText(theqid)
                                APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetTextColor(1, 1, 0)
                                Pos = Pos + 1
                                APR.ZoneQuestOrder["Order1iD"][SubQuestId]:SetPoint("TOPLEFT", APR.ZoneQuestOrder,
                                    "TOPLEFT", 65,
                                    -((16 * Pos) - 11))
                                APR.ZoneQuestOrder["Order1iD"][SubQuestId]:Show()
                                if (APRQuestNames[theqid] and APRQuestNames[theqid] ~= 1) then
                                    SubQuestName = SubQuestName + 1
                                    if (not APR.ZoneQuestOrder["OrderName"][SubQuestName]) then
                                        APR.AddQuestNameFrame(SubQuestName)
                                    end
                                    APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetPoint("TOPLEFT", APR.ZoneQuestOrder,
                                        "TOPLEFT", 120,
                                        -((16 * Pos) - 11))
                                    APR.ZoneQuestOrder["OrderName"][SubQuestName]:Show()
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetText(APRQuestNames[theqid])
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(250)
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(APR.ZoneQuestOrder
                                        ["OrderNameFS"]
                                        [SubQuestName]:GetStringWidth() + 10)
                                    APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetWidth(APR.ZoneQuestOrder
                                        ["OrderNameFS"][SubQuestName]
                                        :GetStringWidth() + 10)
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetTextColor(1, 1, 0)
                                end
                            end
                        end
                    end
                    if (Flagged == Total and Flagged > 0) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["Done"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["TURN_IN_Q"])
                    IdList = APR.QuestStepList[APR.ActiveMap][CCLi]["Done"]
                    local NrLeft = 0
                    local Flagged = 0
                    local Total = 0
                    for h = 1, getn(IdList) do
                        Total = Total + 1
                        local theqid = IdList[h]
                        if (APR.ActiveQuests[theqid]) then
                            NrLeft = NrLeft + 1
                        end
                        if (C_QuestLog.IsQuestFlaggedCompleted(theqid) or APR.BreadCrumSkips[theqid]) then
                            Flagged = Flagged + 1
                        end
                    end
                    if (Total == Flagged) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                        for h = 1, getn(IdList) do
                            local theqid = IdList[h]
                            if (Pos > 26) then
                                break
                            end
                            SubQuestId = SubQuestId + 1
                            if (not APR.ZoneQuestOrder["Order1iD"][SubQuestId]) then
                                APR.AddQuestIdFrame(SubQuestId)
                            end
                            APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetText(theqid)
                            APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetTextColor(1, 1, 0)
                            Pos = Pos + 1
                            APR.ZoneQuestOrder["Order1iD"][SubQuestId]:SetPoint("TOPLEFT", APR.ZoneQuestOrder, "TOPLEFT",
                                65,
                                -((16 * Pos) - 11))
                            APR.ZoneQuestOrder["Order1iD"][SubQuestId]:Show()
                            if (APRQuestNames[theqid] and APRQuestNames[theqid] ~= 1) then
                                SubQuestName = SubQuestName + 1
                                if (not APR.ZoneQuestOrder["OrderName"][SubQuestName]) then
                                    APR.AddQuestNameFrame(SubQuestName)
                                end
                                APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetPoint("TOPLEFT", APR.ZoneQuestOrder,
                                    "TOPLEFT", 120,
                                    -((16 * Pos) - 11))
                                APR.ZoneQuestOrder["OrderName"][SubQuestName]:Show()
                                APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetText(APRQuestNames[theqid])
                                APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(250)
                                APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth((APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:GetStringWidth() + 10) /
                                    2)
                                APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetWidth(APR.ZoneQuestOrder["OrderNameFS"]
                                    [SubQuestName]
                                    :GetStringWidth() + 10)
                                APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetTextColor(1, 1, 0)
                            end
                        end
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["CRange"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["RUN_WAYPOINT"])
                    if (C_QuestLog.IsQuestFlaggedCompleted(APR.QuestStepList[APR.ActiveMap][CCLi]["CRange"]) or CurStep > CCLi) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["UseDalaHS"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["USE_DALARAN_HEARTHSTONE"])
                    if (C_QuestLog.IsQuestFlaggedCompleted(APR.QuestStepList[APR.ActiveMap][CCLi]["UseDalaHS"]) or CurStep > CCLi) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["DalaranToOgri"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["USE_ORGRIMMAR_PORTAL"])
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["UseGarrisonHS"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["USE_GARRISON_HEARTHSTONE"])
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["ZonePick"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["PICK_ZONE"])
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["QpartPart"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["Q_PART"])
                    IdList = APR.QuestStepList[APR.ActiveMap][CCLi]["QpartPart"]
                    local Flagged = 0
                    local Total = 0
                    for APR_index, APR_value in pairs(IdList) do
                        for APR_index2, APR_value2 in pairs(APR_value) do
                            Total = Total + 1
                            if (C_QuestLog.IsQuestFlaggedCompleted(APR_index)) then
                                Flagged = Flagged + 1
                            end
                            local qid = APR_index .. "-" .. APR_index2
                            if (APR.ActiveQuests[qid] and APR.ActiveQuests[qid] == "C") then
                                Flagged = Flagged + 1
                            elseif (APR.ActiveQuests[qid] or not APR.ActiveQuests[APR_index]) then
                                APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                                APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                                local theqid = APR_index
                                if (Pos > 26) then
                                    break
                                end
                                SubQuestId = SubQuestId + 1
                                if (not APR.ZoneQuestOrder["Order1iD"][SubQuestId]) then
                                    APR.AddQuestIdFrame(SubQuestId)
                                end
                                APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetText(theqid)
                                APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetTextColor(1, 1, 0)
                                Pos = Pos + 1
                                APR.ZoneQuestOrder["Order1iD"][SubQuestId]:SetPoint("TOPLEFT", APR.ZoneQuestOrder,
                                    "TOPLEFT", 65,
                                    -((16 * Pos) - 11))
                                APR.ZoneQuestOrder["Order1iD"][SubQuestId]:Show()
                                if (APRQuestNames[theqid] and APRQuestNames[theqid] ~= 1) then
                                    SubQuestName = SubQuestName + 1
                                    if (not APR.ZoneQuestOrder["OrderName"][SubQuestName]) then
                                        APR.AddQuestNameFrame(SubQuestName)
                                    end
                                    APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetPoint("TOPLEFT", APR.ZoneQuestOrder,
                                        "TOPLEFT", 120,
                                        -((16 * Pos) - 11))
                                    APR.ZoneQuestOrder["OrderName"][SubQuestName]:Show()
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetText(APRQuestNames[theqid])
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(250)
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(APR.ZoneQuestOrder
                                        ["OrderNameFS"]
                                        [SubQuestName]:GetStringWidth() + 10)
                                    APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetWidth(APR.ZoneQuestOrder
                                        ["OrderNameFS"][SubQuestName]
                                        :GetStringWidth() + 10)
                                    APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetTextColor(1, 1, 0)
                                end
                            end
                        end
                    end
                    if (Flagged == Total) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["DropQuest"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["Q_DROP"])
                    if (C_QuestLog.IsQuestFlaggedCompleted(APR.QuestStepList[APR.ActiveMap][CCLi]["DropQuest"]) or APR.ActiveQuests[APR.QuestStepList[APR.ActiveMap][CCLi]["DropQuest"]]) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["SetHS"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["SET_HEARTHSTONE"])
                    if (C_QuestLog.IsQuestFlaggedCompleted(APR.QuestStepList[APR.ActiveMap][CCLi]["SetHS"]) or CurStep > CCLi) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["UseHS"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["USE_HEARTHSTONE"])
                    if (C_QuestLog.IsQuestFlaggedCompleted(APR.QuestStepList[APR.ActiveMap][CCLi]["UseHS"]) or CurStep > CCLi) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["ZoneDoneSave"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["ROUTE_COMPLETED"])
                    APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                    APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["GetFP"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["GET_FLIGHTPATH"])
                    if (C_QuestLog.IsQuestFlaggedCompleted(APR.QuestStepList[APR.ActiveMap][CCLi]["GetFP"]) or CurStep > CCLi) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["UseFlightPath"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["USE_FLIGHTPATH"])
                    if (C_QuestLog.IsQuestFlaggedCompleted(APR.QuestStepList[APR.ActiveMap][CCLi]["UseFlightPath"]) or CurStep > CCLi) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["QaskPopup"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["GROUP_Q"])
                    if (C_QuestLog.IsQuestFlaggedCompleted(APR.QuestStepList[APR.ActiveMap][CCLi]["QaskPopup"]) or CurStep > CCLi) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                        local theqid = APR.QuestStepList[APR.ActiveMap][CCLi]["QaskPopup"]
                        if (Pos > 26) then
                            break
                        end
                        SubQuestId = SubQuestId + 1
                        if (not APR.ZoneQuestOrder["Order1iD"][SubQuestId]) then
                            APR.AddQuestIdFrame(SubQuestId)
                        end
                        APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetText(theqid)
                        APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetTextColor(1, 1, 0)
                        Pos = Pos + 1
                        APR.ZoneQuestOrder["Order1iD"][SubQuestId]:SetPoint("TOPLEFT", APR.ZoneQuestOrder, "TOPLEFT", 65,
                            -((16 * Pos) - 11))
                        APR.ZoneQuestOrder["Order1iD"][SubQuestId]:Show()
                        if (APRQuestNames[theqid] and APRQuestNames[theqid] ~= 1) then
                            SubQuestName = SubQuestName + 1
                            if (not APR.ZoneQuestOrder["OrderName"][SubQuestName]) then
                                APR.AddQuestNameFrame(SubQuestName)
                            end
                            APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetPoint("TOPLEFT", APR.ZoneQuestOrder,
                                "TOPLEFT", 120,
                                -((16 * Pos) - 11))
                            APR.ZoneQuestOrder["OrderName"][SubQuestName]:Show()
                            APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetText(APRQuestNames[theqid])
                            APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(250)
                            APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(APR.ZoneQuestOrder["OrderNameFS"]
                                [SubQuestName]
                                :GetStringWidth() + 10)
                            APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetWidth(APR.ZoneQuestOrder["OrderNameFS"]
                                [SubQuestName]
                                :GetStringWidth() + 10)
                            APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetTextColor(1, 1, 0)
                        end
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["Treasure"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["GET_TREASURE"])
                    if (C_QuestLog.IsQuestFlaggedCompleted(APR.QuestStepList[APR.ActiveMap][CCLi]["Treasure"])) then
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(0, 1, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
                    else
                        APR.ZoneQuestOrder["FS"][CLi]:SetTextColor(1, 0, 0)
                        APR.ZoneQuestOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
                    end

                    local theqid = APR.QuestStepList[APR.ActiveMap][CCLi]["Treasure"]
                    SubQuestId = SubQuestId + 1
                    if (not APR.ZoneQuestOrder["Order1iD"][SubQuestId]) then
                        APR.AddQuestIdFrame(SubQuestId)
                    end
                    APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetText(theqid)
                    APR.ZoneQuestOrder["Order1iDFS"][SubQuestId]:SetTextColor(1, 1, 0)
                    Pos = Pos + 1
                    APR.ZoneQuestOrder["Order1iD"][SubQuestId]:SetPoint("TOPLEFT", APR.ZoneQuestOrder, "TOPLEFT", 65,
                        -((16 * Pos) - 11))
                    APR.ZoneQuestOrder["Order1iD"][SubQuestId]:Show()
                    if (APRQuestNames[theqid] and APRQuestNames[theqid] ~= 1) then
                        SubQuestName = SubQuestName + 1
                        if (not APR.ZoneQuestOrder["OrderName"][SubQuestName]) then
                            APR.AddQuestNameFrame(SubQuestName)
                        end
                        APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetPoint("TOPLEFT", APR.ZoneQuestOrder, "TOPLEFT",
                            120,
                            -((16 * Pos) - 11))
                        APR.ZoneQuestOrder["OrderName"][SubQuestName]:Show()
                        APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetText(APRQuestNames[theqid])
                        APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(250)
                        APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetWidth(APR.ZoneQuestOrder["OrderNameFS"]
                            [SubQuestName]
                            :GetStringWidth() + 10)
                        APR.ZoneQuestOrder["OrderName"][SubQuestName]:SetWidth(APR.ZoneQuestOrder["OrderNameFS"]
                            [SubQuestName]
                            :GetStringWidth() + 10)
                        APR.ZoneQuestOrder["OrderNameFS"][SubQuestName]:SetTextColor(1, 1, 0)
                    end
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["ZoneDone"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["ZONE_DONE"])
                end
                if (APR.QuestStepList[APR.ActiveMap][CCLi]["WarMode"]) then
                    APR.ZoneQuestOrder["FS2"][CLi]:SetText(L["TURN_ON_WARMODE"])
                end
                APR.ZoneQuestOrder[CLi]:Show()
                APR.ZoneQuestOrder["Order1"][CLi]:Show()
            end
        end
    else
        if (MainQuest > 0) then
            local CLii
            for CLii = 1, MainQuest do
                APR.ZoneQuestOrder[CLii]:Hide()
                APR.ZoneQuestOrder["Order1"][CLii]:Hide()
                APR.ZoneQuestOrder["FS"][CLii]:SetTextColor(1, 1, 0)
                APR.ZoneQuestOrder["FS2"][CLii]:SetTextColor(1, 1, 0)
            end
        end
        if (SubQuestId > 0) then
            local CLii
            for CLii = 1, SubQuestId do
                APR.ZoneQuestOrder["Order1iD"][CLii]:Hide()
            end
        end
        if (SubQuestName > 0) then
            local CLii
            for CLii = 1, SubQuestName do
                APR.ZoneQuestOrder["OrderName"][CLii]:Hide()
            end
        end
    end
end

function APR.MakeMapOrderIcons(IdZs)
    APR["MapZoneIcons"][IdZs] = CreateFrame("Frame", "MapZoneOrderIcons", UIParent)
    APR["MapZoneIcons"][IdZs]:SetFrameStrata("MEDIUM")
    APR["MapZoneIcons"][IdZs]:SetWidth(20)
    APR["MapZoneIcons"][IdZs]:SetHeight(20)
    APR["MapZoneIcons"][IdZs]:SetScale(0.8)
    local t = APR["MapZoneIcons"][IdZs]:CreateTexture(nil, "ARTWORK")
    t:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.tga")
    t:SetAllPoints(APR["MapZoneIcons"][IdZs])
    APR["MapZoneIcons"]["FS" .. IdZs] = APR["MapZoneIcons"][IdZs]:CreateFontString("APRMapIconFS" .. IdZs, "ARTWORK",
        "ChatFontNormal")
    APR["MapZoneIcons"]["FS" .. IdZs]:SetParent(APR["MapZoneIcons"][IdZs])
    APR["MapZoneIcons"]["FS" .. IdZs]:SetPoint("CENTER", APR["MapZoneIcons"][IdZs], "CENTER", 0, 0)
    APR["MapZoneIcons"]["FS" .. IdZs]:SetWidth(30)
    APR["MapZoneIcons"]["FS" .. IdZs]:SetHeight(25)
    APR["MapZoneIcons"]["FS" .. IdZs]:SetJustifyH("CENTER")
    APR["MapZoneIcons"]["FS" .. IdZs]:SetFontObject("GameFontNormalSmall")
    APR["MapZoneIcons"]["FS" .. IdZs]:SetText(IdZs)
    APR["MapZoneIcons"]["FS" .. IdZs]:SetTextColor(1, 1, 1)
    APR["MapZoneIconsRed"][IdZs] = CreateFrame("Frame", "MapZoneOrderIconsRed", UIParent)
    APR["MapZoneIconsRed"][IdZs]:SetFrameStrata("MEDIUM")
    APR["MapZoneIconsRed"][IdZs]:SetWidth(20)
    APR["MapZoneIconsRed"][IdZs]:SetHeight(20)
    APR["MapZoneIconsRed"][IdZs]:SetScale(0.6)
    local t = APR["MapZoneIconsRed"][IdZs]:CreateTexture(nil, "HIGH")
    t:SetTexture("Interface\\Addons\\APR-Core\\Img\\RedIcon.tga")
    t:SetAllPoints(APR["MapZoneIconsRed"][IdZs])
    APR["MapZoneIconsRed"]["FS" .. IdZs] = APR["MapZoneIconsRed"][IdZs]:CreateFontString("APRMapIconFS" .. IdZs,
        "ARTWORK",
        "ChatFontNormal")
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetParent(APR["MapZoneIconsRed"][IdZs])
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetPoint("CENTER", APR["MapZoneIconsRed"][IdZs], "CENTER", 0, 0)
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetWidth(30)
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetHeight(25)
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetJustifyH("CENTER")
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetFontObject("GameFontNormalSmall")
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetText(IdZs)
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetTextColor(1, 1, 1)
end

function APR.MapOrderNumbers()
    APR.HBDP:RemoveAllWorldMapIcons("APRMapOrder")
    local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
    if (APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and CurStep) then
        local znr = 0
        local SetMapIDs = WorldMapFrame:GetMapID()
        if (SetMapIDs == nil) then
            SetMapIDs = C_Map.GetBestMapForUnit("player")
        end
        for APR_index, APR_value in pairs(APR.QuestStepList[APR.ActiveMap]) do
            znr = znr + 1
            if (APR.QuestStepList[APR.ActiveMap][znr] and APR.QuestStepList[APR.ActiveMap][znr]["TT"] and CurStep < znr and CurStep > (znr - 11)) then
                if (not APR["MapZoneIcons"][znr]) then
                    APR.MakeMapOrderIcons(znr)
                end
                if (not APR.QuestStepList[APR.ActiveMap][znr]["CRange"]) then
                    ix, iy = GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][znr]["TT"]["y"],
                        APR.QuestStepList[APR.ActiveMap][znr]["TT"]["x"])
                    if (CurStep < znr) then
                        APR.HBDP:AddWorldMapIconMap("APRMapOrder", APR["MapZoneIconsRed"][znr], SetMapIDs, ix, iy,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        APR.HBDP:AddWorldMapIconMap("APRMapOrder", APR["MapZoneIcons"][znr], SetMapIDs, ix, iy,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    end
                end
            end
        end
    end
end

APR_QH_EventFrame = CreateFrame("Frame")
APR_QH_EventFrame:RegisterEvent("QUEST_LOG_UPDATE")
APR_QH_EventFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "QUEST_LOG_UPDATE") then
        if (APR1[APR.Realm][APR.Name]["Settings"]["ShowMap10s"] and APR1[APR.Realm][APR.Name]["Settings"]["ShowMap10s"] == 1 and WorldMapFrame:IsShown() and APR.ActiveMap and APR1[APR.Realm][APR.Name][APR.ActiveMap]) then
            local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
            if (CurStep and MapIconUpdateStep ~= CurStep and CurStep > 1) then
                APR.MapOrderNumbers()
            end
        end
    end
end)
