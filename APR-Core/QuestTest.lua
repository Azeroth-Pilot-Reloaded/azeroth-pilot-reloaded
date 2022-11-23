local app = select(2, ...);
local L = app.L;

APR.Test = {}
local MainQ = 0
local SubQId = 0
local SubQName = 0
local ScrollMod = 0
local MapIconOrder = {}
local MapIconUpdateStep = 0
local MapRects = {};
local TempVec2D = CreateVector2D(0,0);
local function GetPlayerMapPos(MapID, dx, dy)
    local R,P,_ = MapRects[MapID],TempVec2D;
    if not R then
        R = {};
        _, R[1] = C_Map.GetWorldPosFromMapPos(MapID,CreateVector2D(0,0));
        _, R[2] = C_Map.GetWorldPosFromMapPos(MapID,CreateVector2D(1,1));
        R[2]:Subtract(R[1]);
        MapRects[MapID] = R;
    end
	if (dx) then
		P.x, P.y = dx, dy
	else
		P.x, P.y = UnitPosition('Player');
	end
    P:Subtract(R[1]);
    return (1/R[2].y)*P.y, (1/R[2].x)*P.x;
end
function APR.Testa()
	APRHFiller2 = nil
	APRHFiller2 = {}
	APRHFiller2["LeaveQs"] = {}
	APRHFiller2["LeaveQs"]["LeaveQs"] = {}
	APRHFiller2["LeaveQs"]["LeaveQs"]["LeaveQs"] = {}
	for APR_index,APR_value in pairs(APR.QStepList["A198-80-93"]) do
		if (APR.QStepList["A198-80-93"][APR_index] and APR.QStepList["A198-80-93"][APR_index]["PickUp"]) then
			for APR_index2,APR_value2 in pairs(APR.QStepList["A198-80-93"][APR_index]["PickUp"]) do
				tinsert(APRHFiller2["LeaveQs"]["LeaveQs"]["LeaveQs"], APR_value2)
			end
		end
	end
	for APR_index,APR_value in pairs(APR.QStepList["A371-80-93"]) do
		if (APR.QStepList["A371-80-93"][APR_index] and APR.QStepList["A371-80-93"][APR_index]["PickUp"]) then
			for APR_index2,APR_value2 in pairs(APR.QStepList["A371-80-93"][APR_index]["PickUp"]) do
				tinsert(APRHFiller2["LeaveQs"]["LeaveQs"]["LeaveQs"], APR_value2)
			end
		end
	end
	for APR_index,APR_value in pairs(APR.QStepList["A379-80-93"]) do
		if (APR.QStepList["A379-80-93"][APR_index] and APR.QStepList["A379-80-93"][APR_index]["PickUp"]) then
			for APR_index2,APR_value2 in pairs(APR.QStepList["A379-80-93"][APR_index]["PickUp"]) do
				tinsert(APRHFiller2["LeaveQs"]["LeaveQs"]["LeaveQs"], APR_value2)
			end
		end
	end
	for APR_index,APR_value in pairs(APR.QStepList["A388-80-93"]) do
		if (APR.QStepList["A388-80-93"][APR_index] and APR.QStepList["A388-80-93"][APR_index]["PickUp"]) then
			for APR_index2,APR_value2 in pairs(APR.QStepList["A388-80-93"][APR_index]["PickUp"]) do
				tinsert(APRHFiller2["LeaveQs"]["LeaveQs"]["LeaveQs"], APR_value2)
			end
		end
	end
end
function APR.ZoneQOrderList()
	if (APR1["Debug"]) then
		print("Function: APR.ZoneQOrderList()")
	end
	APR.ZoneQOrder = CreateFrame("frame", "APRQOrderList", UIParent)
	APR.ZoneQOrder:SetWidth(231)
	APR.ZoneQOrder:SetHeight(440)
	APR.ZoneQOrder:SetPoint("CENTER", UIParent, "CENTER",0,0)
	APR.ZoneQOrder:SetMovable(true)
	APR.ZoneQOrder:EnableMouse(true)

	APR.ZoneQOrder.ZoneName = CreateFrame("frame", "APR_ZoneQOrder_ZoneName", APR.ZoneQOrder)
	APR.ZoneQOrder.ZoneName:SetWidth(100)
	APR.ZoneQOrder.ZoneName:SetHeight(16)
	APR.ZoneQOrder.ZoneName:SetPoint("BOTTOM", APR.ZoneQOrder, "TOP",0,0)
	--APR.ZoneQOrder.ZoneName:SetBackdrop( {
	--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
	--});
local t = APR.ZoneQOrder.ZoneName:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ZoneQOrder.ZoneName)
APR.ZoneQOrder.ZoneName.texture = t

	APR.ZoneQOrder.ZoneName:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			APR.ZoneQOrder:StartMoving();
			APR.ZoneQOrder.isMoving = true;
		end
	end)
	APR.ZoneQOrder.ZoneName:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			APR.ZoneQOrder:StopMovingOrSizing();
			APR.ZoneQOrder.isMoving = false;
		end
	end)
	APR.ZoneQOrder.ZoneName:SetScript("OnHide", function(self)
		if ( APR.ZoneQOrder.isMoving ) then
			APR.ZoneQOrder:StopMovingOrSizing();
			APR.ZoneQOrder.isMoving = false;
		end
	end)
	APR.ZoneQOrder.ZoneName.FS = APR.ZoneQOrder.ZoneName:CreateFontString("APR_ZoneOrder_lvl60_next1_FS","ARTWORK", "ChatFontNormal")
	APR.ZoneQOrder.ZoneName.FS:SetParent(APR.ZoneQOrder.ZoneName)
	APR.ZoneQOrder.ZoneName.FS:SetPoint("CENTER",APR.ZoneQOrder.ZoneName,"CENTER",1,0)
	APR.ZoneQOrder.ZoneName.FS:SetWidth(100)
	APR.ZoneQOrder.ZoneName.FS:SetHeight(16)
	APR.ZoneQOrder.ZoneName.FS:SetJustifyH("CENTER")
	APR.ZoneQOrder.ZoneName.FS:SetFontObject("GameFontNormalSmall")
	APR.ZoneQOrder.ZoneName.FS:SetText(L["ZONE"])
	APR.ZoneQOrder.ZoneName.FS:SetTextColor(1, 1, 0)

	APR.ZoneQOrder["APR_Button"] = CreateFrame("Button", "APR_SBXOZ", APR.ZoneQOrder, APR.ZoneQOrder)
	APR.ZoneQOrder["APR_Button"]:SetWidth(15)
	APR.ZoneQOrder["APR_Button"]:SetHeight(15)
	APR.ZoneQOrder["APR_Button"]:SetText("X")
	APR.ZoneQOrder["APR_Button"]:SetFrameStrata("MEDIUM")
	APR.ZoneQOrder["APR_Button"]:SetPoint("TOPRIGHT",APR.ZoneQOrder,"TOPRIGHT",5,5)
	APR.ZoneQOrder["APR_Button"]:SetNormalFontObject("GameFontNormalLarge")
	APR.ZoneQOrder["APR_Buttonntex"] = APR.ZoneQOrder["APR_Button"]:CreateTexture()
	APR.ZoneQOrder["APR_Buttonntex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.ZoneQOrder["APR_Buttonntex"]:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.ZoneQOrder["APR_Buttonntex"]:SetAllPoints()
	APR.ZoneQOrder["APR_Button"]:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.ZoneQOrder["APR_Buttonhtex"] = APR.ZoneQOrder["APR_Button"]:CreateTexture()
	APR.ZoneQOrder["APR_Buttonhtex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.ZoneQOrder["APR_Buttonhtex"]:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.ZoneQOrder["APR_Buttonhtex"]:SetAllPoints()
	APR.ZoneQOrder["APR_Button"]:SetHighlightTexture(APR.ZoneQOrder["APR_Buttonhtex"])
	APR.ZoneQOrder["APR_Buttonptex"] = APR.ZoneQOrder["APR_Button"]:CreateTexture()
	APR.ZoneQOrder["APR_Buttonptex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.ZoneQOrder["APR_Buttonptex"]:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.ZoneQOrder["APR_Buttonptex"]:SetAllPoints()
	APR.ZoneQOrder["APR_Button"]:SetPushedTexture(APR.ZoneQOrder["APR_Buttonptex"])
	APR.ZoneQOrder["APR_Button"]:SetScript("OnClick", function(self, arg1)
		APR1[APR.Realm][APR.Name]["Settings"]["ShowQListOrder"] = 0
		APR.ZoneQOrder:Hide()
		APR.OptionsFrame.QorderListzCheckButton:SetChecked(false)
	end)
	--APR.ZoneQOrder:SetBackdrop( {
	--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
	--});
local t = APR.ZoneQOrder:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ZoneQOrder)
APR.ZoneQOrder.texture = t

	APR.ZoneQOrder:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			APR.ZoneQOrder:StartMoving();
			APR.ZoneQOrder.isMoving = true;
		end
	end)
	APR.ZoneQOrder:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			APR.ZoneQOrder:StopMovingOrSizing();
			APR.ZoneQOrder.isMoving = false;
		end
	end)
	APR.ZoneQOrder:SetScript("OnHide", function(self)
		if ( APR.ZoneQOrder.isMoving ) then
			APR.ZoneQOrder:StopMovingOrSizing();
			APR.ZoneQOrder.isMoving = false;
		end
	end)
	APR.ZoneQOrder:SetScript("OnMouseWheel", function(self, arg1)
		if (arg1 == 1) then
			if (ScrollMod ~= 0) then
			ScrollMod = ScrollMod - 1
			APR.UpdateZoneQOrderList(ScrollMod)
			end
		else
			ScrollMod = ScrollMod + 1
			APR.UpdateZoneQOrderList(ScrollMod)
		end
	end)
	APR.ZoneQOrder["Current"] = CreateFrame("frame", "APR_ZoneQOrderCurrent", APR.ZoneQOrder)
	APR.ZoneQOrder["Current"]:SetWidth(25)
	APR.ZoneQOrder["Current"]:SetHeight(16)
	APR.ZoneQOrder["Current"]:SetPoint("RIGHT", APR.ZoneQOrder, "LEFT",0,0)
	--APR.ZoneQOrder["Current"]:SetBackdrop( {
	--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
	--});
local t = APR.ZoneQOrder["Current"]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ZoneQOrder["Current"])
APR.ZoneQOrder["Current"].texture = t

	APR.ZoneQOrder["Current"]["FS"] = APR.ZoneQOrder["Current"]:CreateFontString("APRZoneQOrderFSCurrent","ARTWORK", "ChatFontNormal")
	APR.ZoneQOrder["Current"]["FS"]:SetParent(APR.ZoneQOrder["Current"])
	APR.ZoneQOrder["Current"]["FS"]:SetPoint("CENTER",APR.ZoneQOrder["Current"],"CENTER",1,0)
	APR.ZoneQOrder["Current"]["FS"]:SetWidth(25)
	APR.ZoneQOrder["Current"]["FS"]:SetHeight(16)
	APR.ZoneQOrder["Current"]["FS"]:SetJustifyH("CENTER")
	APR.ZoneQOrder["Current"]["FS"]:SetFontObject("GameFontNormalSmall")
	APR.ZoneQOrder["Current"]["FS"]:SetText(">>>")
	APR.ZoneQOrder["Current"]["FS"]:SetTextColor(1, 1, 0)
	APR.ZoneQOrder["Current"]:Hide()
	APR.ZoneQOrder["FS"] = {}
	APR.ZoneQOrder["FS2"] = {}
	APR.ZoneQOrder["Order1"] = {}
	APR.ZoneQOrder["Order1iD"] = {}
	APR.ZoneQOrder["Order1iDFS"] = {}
	APR.ZoneQOrder["OrderName"] = {}
	APR.ZoneQOrder["OrderNameFS"] = {}
end
function APR.AddQOrderFrame(CLi)
		CLPos = CLi * 16
		APR.ZoneQOrder[CLi] = CreateFrame("frame", "APR_ZoneQOrder"..CLi, APR.ZoneQOrder)
		APR.ZoneQOrder[CLi]:SetWidth(25)
		APR.ZoneQOrder[CLi]:SetHeight(16)
		APR.ZoneQOrder[CLi]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",5,-((CLPos)-11))
		--APR.ZoneQOrder[CLi]:SetBackdrop( {
		--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
		--});
local t = APR.ZoneQOrder[CLi]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ZoneQOrder[CLi])
APR.ZoneQOrder[CLi].texture = t

		APR.ZoneQOrder[CLi]:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				APR.ZoneQOrder:StartMoving();
				APR.ZoneQOrder.isMoving = true;
			end
		end)
		APR.ZoneQOrder[CLi]:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" then
				APR.ZoneQOrder:StopMovingOrSizing();
				APR.ZoneQOrder.isMoving = false;
			end
		end)
		APR.ZoneQOrder[CLi]:SetScript("OnHide", function(self)
			if ( APR.ZoneQOrder.isMoving ) then
				APR.ZoneQOrder:StopMovingOrSizing();
				APR.ZoneQOrder.isMoving = false;
			end
		end)
		APR.ZoneQOrder[CLi]:SetScript("OnMouseWheel", function(self, arg1)
			if (arg1 == 1) then
				if (ScrollMod ~= 0) then
					ScrollMod = ScrollMod - 1
					APR.UpdateZoneQOrderList(ScrollMod)
				end
			else
				ScrollMod = ScrollMod + 1
				APR.UpdateZoneQOrderList(ScrollMod)
			end
		end)
		APR.ZoneQOrder["FS"][CLi] = APR.ZoneQOrder[CLi]:CreateFontString("APRZoneQOrderFS"..CLi,"ARTWORK", "ChatFontNormal")
		APR.ZoneQOrder["FS"][CLi]:SetParent(APR.ZoneQOrder[CLi])
		APR.ZoneQOrder["FS"][CLi]:SetPoint("CENTER",APR.ZoneQOrder[CLi],"CENTER",1,0)
		APR.ZoneQOrder["FS"][CLi]:SetWidth(25)
		APR.ZoneQOrder["FS"][CLi]:SetHeight(16)
		APR.ZoneQOrder["FS"][CLi]:SetJustifyH("CENTER")
		APR.ZoneQOrder["FS"][CLi]:SetFontObject("GameFontNormalSmall")
		APR.ZoneQOrder["FS"][CLi]:SetText(CLi)
		APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 1, 0)

		APR.ZoneQOrder["Order1"][CLi] = CreateFrame("frame", "APR_ZoneQOrder2A"..CLi, APR.ZoneQOrder)
		APR.ZoneQOrder["Order1"][CLi]:SetWidth(100)
		APR.ZoneQOrder["Order1"][CLi]:SetHeight(16)
		APR.ZoneQOrder["Order1"][CLi]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",32,-((CLPos)-11))
		--APR.ZoneQOrder["Order1"][CLi]:SetBackdrop( {
		--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
		--});
local t = APR.ZoneQOrder["Order1"][CLi]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ZoneQOrder["Order1"][CLi])
APR.ZoneQOrder["Order1"][CLi].texture = t

		APR.ZoneQOrder["Order1"][CLi]:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				APR.ZoneQOrder:StartMoving();
				APR.ZoneQOrder.isMoving = true;
			end
		end)
		APR.ZoneQOrder["Order1"][CLi]:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" then
				APR.ZoneQOrder:StopMovingOrSizing();
				APR.ZoneQOrder.isMoving = false;
			end
		end)
		APR.ZoneQOrder["Order1"][CLi]:SetScript("OnHide", function(self)
			if ( APR.ZoneQOrder.isMoving ) then
				APR.ZoneQOrder:StopMovingOrSizing();
				APR.ZoneQOrder.isMoving = false;
			end
		end)
		APR.ZoneQOrder["Order1"][CLi]:SetScript("OnMouseWheel", function(self, arg1)
			if (arg1 == 1) then
				if (ScrollMod ~= 0) then
					ScrollMod = ScrollMod - 1
					APR.UpdateZoneQOrderList(ScrollMod)
				end
			else
				ScrollMod = ScrollMod + 1
				APR.UpdateZoneQOrderList(ScrollMod)
			end
		end)
		APR.ZoneQOrder["FS2"][CLi] = APR.ZoneQOrder["Order1"][CLi]:CreateFontString("APRZoneQOrderFS2A"..CLi,"ARTWORK", "ChatFontNormal")
		APR.ZoneQOrder["FS2"][CLi]:SetParent(APR.ZoneQOrder["Order1"][CLi])
		APR.ZoneQOrder["FS2"][CLi]:SetPoint("LEFT",APR.ZoneQOrder["Order1"][CLi],"LEFT",5,0)
		APR.ZoneQOrder["FS2"][CLi]:SetWidth(150)
		APR.ZoneQOrder["FS2"][CLi]:SetHeight(16)
		APR.ZoneQOrder["FS2"][CLi]:SetJustifyH("LEFT")
		APR.ZoneQOrder["FS2"][CLi]:SetFontObject("GameFontNormalSmall")
		APR.ZoneQOrder["FS2"][CLi]:SetText("")
		APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 1, 0)
end
function APR.AddQIdFrame(CLi)
		CLPos = CLi * 16 + 16

		APR.ZoneQOrder["Order1iD"][CLi] = CreateFrame("frame", "APR_ZoneQOrder2AID"..CLi, APR.ZoneQOrder)
		APR.ZoneQOrder["Order1iD"][CLi]:SetWidth(50)
		APR.ZoneQOrder["Order1iD"][CLi]:SetHeight(16)
		APR.ZoneQOrder["Order1iD"][CLi]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",65,-((CLPos)-11))
		--APR.ZoneQOrder["Order1iD"][CLi]:SetBackdrop( {
		--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
		--});
local t = APR.ZoneQOrder["Order1iD"][CLi]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ZoneQOrder["Order1iD"][CLi])
APR.ZoneQOrder["Order1iD"][CLi].texture = t

		APR.ZoneQOrder["Order1iD"][CLi]:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				APR.ZoneQOrder:StartMoving();
				APR.ZoneQOrder.isMoving = true;
			end
		end)
		APR.ZoneQOrder["Order1iD"][CLi]:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" then
				APR.ZoneQOrder:StopMovingOrSizing();
				APR.ZoneQOrder.isMoving = false;
			end
		end)
		APR.ZoneQOrder["Order1iD"][CLi]:SetScript("OnHide", function(self)
			if ( APR.ZoneQOrder.isMoving ) then
				APR.ZoneQOrder:StopMovingOrSizing();
				APR.ZoneQOrder.isMoving = false;
			end
		end)
		APR.ZoneQOrder["Order1iD"][CLi]:SetScript("OnMouseWheel", function(self, arg1)
			if (arg1 == 1) then
				if (ScrollMod ~= 0) then
					ScrollMod = ScrollMod - 1
					APR.UpdateZoneQOrderList(ScrollMod)
				end
			else
				ScrollMod = ScrollMod + 1
				APR.UpdateZoneQOrderList(ScrollMod)
			end
		end)
		APR.ZoneQOrder["Order1iDFS"][CLi] = APR.ZoneQOrder["Order1iD"][CLi]:CreateFontString("APRZoneQOrderFS2AID"..CLi,"ARTWORK", "ChatFontNormal")
		APR.ZoneQOrder["Order1iDFS"][CLi]:SetParent(APR.ZoneQOrder["Order1iD"][CLi])
		APR.ZoneQOrder["Order1iDFS"][CLi]:SetPoint("LEFT",APR.ZoneQOrder["Order1iD"][CLi],"LEFT",5,0)
		APR.ZoneQOrder["Order1iDFS"][CLi]:SetWidth(50)
		APR.ZoneQOrder["Order1iDFS"][CLi]:SetHeight(16)
		APR.ZoneQOrder["Order1iDFS"][CLi]:SetJustifyH("LEFT")
		APR.ZoneQOrder["Order1iDFS"][CLi]:SetFontObject("GameFontNormalSmall")
		APR.ZoneQOrder["Order1iDFS"][CLi]:SetText("")
		APR.ZoneQOrder["Order1iDFS"][CLi]:SetTextColor(1, 1, 0)
end
function APR.AddQNameFrame(CLi)
		CLPos = CLi * 16 + 16

		APR.ZoneQOrder["OrderName"][CLi] = CreateFrame("frame", "APR_ZoneQOrder2NameD"..CLi, APR.ZoneQOrder)
		APR.ZoneQOrder["OrderName"][CLi]:SetWidth(50)
		APR.ZoneQOrder["OrderName"][CLi]:SetHeight(16)
		APR.ZoneQOrder["OrderName"][CLi]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",120,-((CLPos)-11))
		--APR.ZoneQOrder["OrderName"][CLi]:SetBackdrop( {
		--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
		--});
local t = APR.ZoneQOrder["OrderName"][CLi]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ZoneQOrder["OrderName"][CLi])
APR.ZoneQOrder["OrderName"][CLi].texture = t

		APR.ZoneQOrder["OrderName"][CLi]:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				APR.ZoneQOrder:StartMoving();
				APR.ZoneQOrder.isMoving = true;
			end
		end)
		APR.ZoneQOrder["OrderName"][CLi]:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" then
				APR.ZoneQOrder:StopMovingOrSizing();
				APR.ZoneQOrder.isMoving = false;
			end
		end)
		APR.ZoneQOrder["OrderName"][CLi]:SetScript("OnHide", function(self)
			if ( APR.ZoneQOrder.isMoving ) then
				APR.ZoneQOrder:StopMovingOrSizing();
				APR.ZoneQOrder.isMoving = false;
			end
		end)
		APR.ZoneQOrder["OrderName"][CLi]:SetScript("OnMouseWheel", function(self, arg1)
			if (arg1 == 1) then
				if (ScrollMod ~= 0) then
					ScrollMod = ScrollMod - 1
					APR.UpdateZoneQOrderList(ScrollMod)
				end
			else
				ScrollMod = ScrollMod + 1
				APR.UpdateZoneQOrderList(ScrollMod)
			end
		end)
		APR.ZoneQOrder["OrderNameFS"][CLi] = APR.ZoneQOrder["OrderName"][CLi]:CreateFontString("APRZoneQOrderFS2NameD"..CLi,"ARTWORK", "ChatFontNormal")
		APR.ZoneQOrder["OrderNameFS"][CLi]:SetParent(APR.ZoneQOrder["OrderName"][CLi])
		APR.ZoneQOrder["OrderNameFS"][CLi]:SetPoint("LEFT",APR.ZoneQOrder["OrderName"][CLi],"LEFT",5,0)
		APR.ZoneQOrder["OrderNameFS"][CLi]:SetWidth(50)
		APR.ZoneQOrder["OrderNameFS"][CLi]:SetHeight(16)
		APR.ZoneQOrder["OrderNameFS"][CLi]:SetJustifyH("LEFT")
		APR.ZoneQOrder["OrderNameFS"][CLi]:SetFontObject("GameFontNormalSmall")
		APR.ZoneQOrder["OrderNameFS"][CLi]:SetText("")
		APR.ZoneQOrder["OrderNameFS"][CLi]:SetTextColor(1, 1, 0)
end
function APR.UpdateZoneQOrderList(APRmod)
	if (APR1["Debug"]) then
		print("Function: APR.UpdateZoneQOrderList()")
	end
	if (not APRQNames) then
		APRQNames = {}
	end
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	local steps
	if (CurStep and APR.ActiveMap and APR.QStepList and APR.QStepList[APR.ActiveMap] and APR.QStepList[APR.ActiveMap][CurStep]) then
		steps = APR.QStepList[APR.ActiveMap][CurStep]
	end
	APR.ZoneQOrder["Current"]:Hide()
	if (steps) then
		if (not APRmod) then
			APRmod = 0
		end
		if (MainQ > 0) then
			local CLii
			for CLii = 1, MainQ do
				APR.ZoneQOrder[CLii]:Hide()
				APR.ZoneQOrder["Order1"][CLii]:Hide()
				APR.ZoneQOrder["FS"][CLii]:SetTextColor(1, 1, 0)
				APR.ZoneQOrder["FS2"][CLii]:SetTextColor(1, 1, 0)
			end
		end
		if (SubQId > 0) then
			local CLii
			for CLii = 1, SubQId do
				APR.ZoneQOrder["Order1iD"][CLii]:Hide()
			end
		end
		if (SubQName > 0) then
			local CLii
			for CLii = 1, SubQName do
				APR.ZoneQOrder["OrderName"][CLii]:Hide()
			end
		end
		MainQ = 0
		SubQId = 0
		SubQName = 0
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
			MainQ = MainQ + 1
			if (not APR.ZoneQOrder[MainQ]) then
				APR.AddQOrderFrame(MainQ)
			end
			if (Pos > 26) then
				break
			end
			Pos = Pos + 1
			APR.ZoneQOrder[CLi]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",5,-((16*Pos)-11))
			APR.ZoneQOrder["Order1"][CLi]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",32,-((16*Pos)-11))
			if (APR.QStepList[APR.ActiveMap][CCLi]) then
				APR.ZoneQOrder["FS"][CLi]:SetText(CCLi)
				if (CurStep == CCLi) then
					APR.ZoneQOrder["Current"]:SetPoint("RIGHT", APR.ZoneQOrder[CLi], "LEFT",0,0)
					APR.ZoneQOrder["Current"]:Show()
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["PickUp"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["PICK_UP_QS"])
					IdList = APR.QStepList[APR.ActiveMap][CCLi]["PickUp"]
					local NrLeft = 0
					local Flagged = 0
					local Total = 0
					local NrLeft2 = 0
					local Flagged2 = 0
					local Total2 = 0
					for h=1, getn(IdList) do
						local theqid = IdList[h]
						Total = Total + 1
						if (not APR.ActiveQs[theqid]) then
							NrLeft = NrLeft + 1
						end
						if (C_QLog.IsQFlaggedCompleted(theqid) or APR.ActiveQs[theqid] or APR.BreadCrumSkips[theqid]) then
							Flagged = Flagged + 1
						end
					end
					if (APR.QStepList[APR.ActiveMap][CCLi]["PickUp2"]) then
						IdList2 = APR.QStepList[APR.ActiveMap][CCLi]["PickUp2"]
						for h=1, getn(IdList2) do
							local theqid = IdList2[h]
							Total2 = Total2 + 1
							if (not APR.ActiveQs[theqid]) then
								NrLeft2 = NrLeft2 + 1
							end
							if (C_QLog.IsQFlaggedCompleted(theqid) or APR.ActiveQs[theqid] or APR.BreadCrumSkips[theqid]) then
								Flagged2 = Flagged2 + 1
							end
						end
					end
					if (Total == Flagged) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					elseif (steps["PickUp2"] and Total2 == Flagged2) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
						for h=1, getn(IdList) do
							local theqid = IdList[h]
							if (Pos > 26) then
								break
							end
							if (C_QLog.IsQFlaggedCompleted(theqid) or APR.ActiveQs[theqid]) then
							else
								SubQId = SubQId + 1
								if (not APR.ZoneQOrder["Order1iD"][SubQId]) then
									APR.AddQIdFrame(SubQId)
								end
								APR.ZoneQOrder["Order1iDFS"][SubQId]:SetText(theqid)
								APR.ZoneQOrder["Order1iDFS"][SubQId]:SetTextColor(1, 1, 0)
								Pos = Pos + 1
								APR.ZoneQOrder["Order1iD"][SubQId]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",65,-((16*Pos)-11))
								APR.ZoneQOrder["Order1iD"][SubQId]:Show()
								if (APRQNames[theqid] and APRQNames[theqid] ~= 1) then
									SubQName = SubQName + 1
									if (not APR.ZoneQOrder["OrderName"][SubQName]) then
										APR.AddQNameFrame(SubQName)
									end
									APR.ZoneQOrder["OrderName"][SubQName]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",120,-((16*Pos)-11))
									APR.ZoneQOrder["OrderName"][SubQName]:Show()
									APR.ZoneQOrder["OrderNameFS"][SubQName]:SetText(APRQNames[theqid])
									APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(250)
									APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
									APR.ZoneQOrder["OrderName"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
									APR.ZoneQOrder["OrderNameFS"][SubQName]:SetTextColor(1, 1, 0)
								end
							end
						end
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["QPart"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["Q_PART"])
					IdList = APR.QStepList[APR.ActiveMap][CCLi]["QPart"]
					local Flagged = 0
					local Total = 0
					for APR_index,APR_value in pairs(IdList) do
						for APR_index2,APR_value2 in pairs(APR_value) do
							Total = Total + 1
							local qid = APR_index.."-"..APR_index2
							if (C_QLog.IsQFlaggedCompleted(APR_index) or ((UnitLevel("player") == 120) and APR_BonusObj and APR_BonusObj[APR_index]) or APR1[APR.Realm][APR.Name]["BonusSkips"][APR_index]) then
								Flagged = Flagged + 1
							elseif (APR.ActiveQs[qid] and APR.ActiveQs[qid] == "C") then
								Flagged = Flagged + 1
							elseif (APR.ActiveQs[qid] or not APR.ActiveQs[APR_index]) then
								APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
								APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
								local theqid = APR_index
								if (Pos > 26) then
									break
								end
								SubQId = SubQId + 1
								if (not APR.ZoneQOrder["Order1iD"][SubQId]) then
									APR.AddQIdFrame(SubQId)
								end
								APR.ZoneQOrder["Order1iDFS"][SubQId]:SetText(theqid)
								APR.ZoneQOrder["Order1iDFS"][SubQId]:SetTextColor(1, 1, 0)
								Pos = Pos + 1
								APR.ZoneQOrder["Order1iD"][SubQId]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",65,-((16*Pos)-11))
								APR.ZoneQOrder["Order1iD"][SubQId]:Show()
								if (APRQNames[theqid] and APRQNames[theqid] ~= 1) then
									SubQName = SubQName + 1
									if (not APR.ZoneQOrder["OrderName"][SubQName]) then
										APR.AddQNameFrame(SubQName)
									end
									APR.ZoneQOrder["OrderName"][SubQName]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",120,-((16*Pos)-11))
									APR.ZoneQOrder["OrderName"][SubQName]:Show()
									APR.ZoneQOrder["OrderNameFS"][SubQName]:SetText(APRQNames[theqid])
									APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(250)
									APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
									APR.ZoneQOrder["OrderName"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
									APR.ZoneQOrder["OrderNameFS"][SubQName]:SetTextColor(1, 1, 0)
								end
							end
						end
					end
					if (Flagged == Total and Flagged > 0) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["Done"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["HAND_IN_Q"])
					IdList = APR.QStepList[APR.ActiveMap][CCLi]["Done"]
					local NrLeft = 0
					local Flagged = 0
					local Total = 0
					for h=1, getn(IdList) do
						Total = Total + 1
						local theqid = IdList[h]
						if (APR.ActiveQs[theqid]) then
							NrLeft = NrLeft + 1
						end
						if (C_QLog.IsQFlaggedCompleted(theqid) or APR.BreadCrumSkips[theqid]) then
							Flagged = Flagged + 1
						end
					end
					if (Total == Flagged) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
						for h=1, getn(IdList) do
							local theqid = IdList[h]
							if (Pos > 26) then
								break
							end
							SubQId = SubQId + 1
							if (not APR.ZoneQOrder["Order1iD"][SubQId]) then
								APR.AddQIdFrame(SubQId)
							end
							APR.ZoneQOrder["Order1iDFS"][SubQId]:SetText(theqid)
							APR.ZoneQOrder["Order1iDFS"][SubQId]:SetTextColor(1, 1, 0)
							Pos = Pos + 1
							APR.ZoneQOrder["Order1iD"][SubQId]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",65,-((16*Pos)-11))
							APR.ZoneQOrder["Order1iD"][SubQId]:Show()
							if (APRQNames[theqid] and APRQNames[theqid] ~= 1) then
								SubQName = SubQName + 1
								if (not APR.ZoneQOrder["OrderName"][SubQName]) then
									APR.AddQNameFrame(SubQName)
								end
								APR.ZoneQOrder["OrderName"][SubQName]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",120,-((16*Pos)-11))
								APR.ZoneQOrder["OrderName"][SubQName]:Show()
								APR.ZoneQOrder["OrderNameFS"][SubQName]:SetText(APRQNames[theqid])
								APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(250)
								APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth((APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)/2)
								APR.ZoneQOrder["OrderName"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
								APR.ZoneQOrder["OrderNameFS"][SubQName]:SetTextColor(1, 1, 0)
							end
						end
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["CRange"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["RUN_WAYPOINT"])
					if (C_QLog.IsQFlaggedCompleted(APR.QStepList[APR.ActiveMap][CCLi]["CRange"]) or CurStep > CCLi) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["UseDalaHS"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["USE_DALARAN_HEARTHSTONE"])
					if (C_QLog.IsQFlaggedCompleted(APR.QStepList[APR.ActiveMap][CCLi]["UseDalaHS"]) or CurStep > CCLi) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["DalaranToOgri"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["USE_ORGRIMMAR_PORTAL"])
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["PahonixMadeMe"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["TRAIN_RIDING"])
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["UseGarrisonHS"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["USE_GARRISON_HEARTHSTONE"])
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["ZonePick"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["PICK_ZONE"])
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["QPartPart"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["Q_PART"])
					IdList = APR.QStepList[APR.ActiveMap][CCLi]["QPartPart"]
					local Flagged = 0
					local Total = 0
					for APR_index,APR_value in pairs(IdList) do
						for APR_index2,APR_value2 in pairs(APR_value) do
							Total = Total + 1
							if (C_QLog.IsQFlaggedCompleted(APR_index)) then
								Flagged = Flagged + 1
							end
							local qid = APR_index.."-"..APR_index2
							if (APR.ActiveQs[qid] and APR.ActiveQs[qid] == "C") then
								Flagged = Flagged + 1
							elseif (APR.ActiveQs[qid] or not APR.ActiveQs[APR_index]) then
								APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
								APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
								local theqid = APR_index
								if (Pos > 26) then
									break
								end
								SubQId = SubQId + 1
								if (not APR.ZoneQOrder["Order1iD"][SubQId]) then
									APR.AddQIdFrame(SubQId)
								end
								APR.ZoneQOrder["Order1iDFS"][SubQId]:SetText(theqid)
								APR.ZoneQOrder["Order1iDFS"][SubQId]:SetTextColor(1, 1, 0)
								Pos = Pos + 1
								APR.ZoneQOrder["Order1iD"][SubQId]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",65,-((16*Pos)-11))
								APR.ZoneQOrder["Order1iD"][SubQId]:Show()
								if (APRQNames[theqid] and APRQNames[theqid] ~= 1) then
									SubQName = SubQName + 1
									if (not APR.ZoneQOrder["OrderName"][SubQName]) then
										APR.AddQNameFrame(SubQName)
									end
										APR.ZoneQOrder["OrderName"][SubQName]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",120,-((16*Pos)-11))
										APR.ZoneQOrder["OrderName"][SubQName]:Show()
										APR.ZoneQOrder["OrderNameFS"][SubQName]:SetText(APRQNames[theqid])
										APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(250)
										APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
										APR.ZoneQOrder["OrderName"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
										APR.ZoneQOrder["OrderNameFS"][SubQName]:SetTextColor(1, 1, 0)
								end
							end
						end
					end
					if (Flagged == Total) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["DropQ"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["Q_DROP"])
					if (C_QLog.IsQFlaggedCompleted(APR.QStepList[APR.ActiveMap][CCLi]["DropQ"]) or APR.ActiveQs[APR.QStepList[APR.ActiveMap][CCLi]["DropQ"]]) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
					end

				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["SetHS"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["SET_HEARTHSTONE"])
					if (C_QLog.IsQFlaggedCompleted(APR.QStepList[APR.ActiveMap][CCLi]["SetHS"]) or CurStep > CCLi) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["UseHS"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["USE_HEARTHSTONE"])
					if (C_QLog.IsQFlaggedCompleted(APR.QStepList[APR.ActiveMap][CCLi]["UseHS"]) or CurStep > CCLi) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["ZoneDoneSave"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["ROUTE_COMPLETED"])
					APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
					APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["GetFP"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["GET_FLIGHPATH"])
					if (C_QLog.IsQFlaggedCompleted(APR.QStepList[APR.ActiveMap][CCLi]["GetFP"]) or CurStep > CCLi) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["UseFlightPath"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["USE_FLIGHTPATH"])
					if (C_QLog.IsQFlaggedCompleted(APR.QStepList[APR.ActiveMap][CCLi]["UseFlightPath"]) or CurStep > CCLi) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["QaskPopup"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["GROUP_Q"])
					if (C_QLog.IsQFlaggedCompleted(APR.QStepList[APR.ActiveMap][CCLi]["QaskPopup"]) or CurStep > CCLi) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
						local theqid = APR.QStepList[APR.ActiveMap][CCLi]["QaskPopup"]
						if (Pos > 26) then
							break
						end
						SubQId = SubQId + 1
						if (not APR.ZoneQOrder["Order1iD"][SubQId]) then
							APR.AddQIdFrame(SubQId)
						end
						APR.ZoneQOrder["Order1iDFS"][SubQId]:SetText(theqid)
						APR.ZoneQOrder["Order1iDFS"][SubQId]:SetTextColor(1, 1, 0)
						Pos = Pos + 1
						APR.ZoneQOrder["Order1iD"][SubQId]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",65,-((16*Pos)-11))
						APR.ZoneQOrder["Order1iD"][SubQId]:Show()
						if (APRQNames[theqid] and APRQNames[theqid] ~= 1) then
							SubQName = SubQName + 1
							if (not APR.ZoneQOrder["OrderName"][SubQName]) then
								APR.AddQNameFrame(SubQName)
							end
							APR.ZoneQOrder["OrderName"][SubQName]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",120,-((16*Pos)-11))
							APR.ZoneQOrder["OrderName"][SubQName]:Show()
							APR.ZoneQOrder["OrderNameFS"][SubQName]:SetText(APRQNames[theqid])
							APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(250)
							APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
							APR.ZoneQOrder["OrderName"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
							APR.ZoneQOrder["OrderNameFS"][SubQName]:SetTextColor(1, 1, 0)
						end
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["Treasure"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["GET_TREASURE"])
					if (C_QLog.IsQFlaggedCompleted(APR.QStepList[APR.ActiveMap][CCLi]["Treasure"])) then
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(0, 1, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(0, 1, 0)
					else
						APR.ZoneQOrder["FS"][CLi]:SetTextColor(1, 0, 0)
						APR.ZoneQOrder["FS2"][CLi]:SetTextColor(1, 0, 0)
					end

					local theqid = APR.QStepList[APR.ActiveMap][CCLi]["Treasure"]
					SubQId = SubQId + 1
					if (not APR.ZoneQOrder["Order1iD"][SubQId]) then
						APR.AddQIdFrame(SubQId)
					end
					APR.ZoneQOrder["Order1iDFS"][SubQId]:SetText(theqid)
					APR.ZoneQOrder["Order1iDFS"][SubQId]:SetTextColor(1, 1, 0)
					Pos = Pos + 1
					APR.ZoneQOrder["Order1iD"][SubQId]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",65,-((16*Pos)-11))
					APR.ZoneQOrder["Order1iD"][SubQId]:Show()
					if (APRQNames[theqid] and APRQNames[theqid] ~= 1) then
						SubQName = SubQName + 1
						if (not APR.ZoneQOrder["OrderName"][SubQName]) then
							APR.AddQNameFrame(SubQName)
						end
						APR.ZoneQOrder["OrderName"][SubQName]:SetPoint("TOPLEFT", APR.ZoneQOrder, "TOPLEFT",120,-((16*Pos)-11))
						APR.ZoneQOrder["OrderName"][SubQName]:Show()
						APR.ZoneQOrder["OrderNameFS"][SubQName]:SetText(APRQNames[theqid])
						APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(250)
						APR.ZoneQOrder["OrderNameFS"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
						APR.ZoneQOrder["OrderName"][SubQName]:SetWidth(APR.ZoneQOrder["OrderNameFS"][SubQName]:GetStringWidth()+10)
						APR.ZoneQOrder["OrderNameFS"][SubQName]:SetTextColor(1, 1, 0)
					end
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["ZoneDone"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["ZONE_DONE"])
				end
				if (APR.QStepList[APR.ActiveMap][CCLi]["WarMode"]) then
					APR.ZoneQOrder["FS2"][CLi]:SetText(L["TURN_ON_WARMODE"])
				end
				APR.ZoneQOrder[CLi]:Show()
				APR.ZoneQOrder["Order1"][CLi]:Show()
			end
		end
	else
		if (MainQ > 0) then
			local CLii
			for CLii = 1, MainQ do
				APR.ZoneQOrder[CLii]:Hide()
				APR.ZoneQOrder["Order1"][CLii]:Hide()
				APR.ZoneQOrder["FS"][CLii]:SetTextColor(1, 1, 0)
				APR.ZoneQOrder["FS2"][CLii]:SetTextColor(1, 1, 0)
			end
		end
		if (SubQId > 0) then
			local CLii
			for CLii = 1, SubQId do
				APR.ZoneQOrder["Order1iD"][CLii]:Hide()
			end
		end
		if (SubQName > 0) then
			local CLii
			for CLii = 1, SubQName do
				APR.ZoneQOrder["OrderName"][CLii]:Hide()
			end
		end
	end
end
function APR.MakeMapOrderIcons(IdZs)
	APR["MapZoneIcons"][IdZs] = CreateFrame("Frame",nil,UIParent)
	APR["MapZoneIcons"][IdZs]:SetFrameStrata("MEDIUM")
	APR["MapZoneIcons"][IdZs]:SetWidth(20)
	APR["MapZoneIcons"][IdZs]:SetHeight(20)
	APR["MapZoneIcons"][IdZs]:SetScale(0.6)
	local t = 	APR["MapZoneIcons"][IdZs]:CreateTexture(nil,"HIGH")
	t:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.blp")
	t:SetAllPoints(APR["MapZoneIcons"][IdZs])
	--APR["MapZoneIcons"][IdZs]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	APR["MapZoneIcons"]["FS"..IdZs] = APR["MapZoneIcons"][IdZs]:CreateFontString("APRMapIconFS"..IdZs,"ARTWORK", "ChatFontNormal")
	APR["MapZoneIcons"]["FS"..IdZs]:SetParent(APR["MapZoneIcons"][IdZs])
	APR["MapZoneIcons"]["FS"..IdZs]:SetPoint("CENTER",APR["MapZoneIcons"][IdZs],"CENTER",0,0)
	APR["MapZoneIcons"]["FS"..IdZs]:SetWidth(30)
	APR["MapZoneIcons"]["FS"..IdZs]:SetHeight(25)
	APR["MapZoneIcons"]["FS"..IdZs]:SetJustifyH("CENTER")
	APR["MapZoneIcons"]["FS"..IdZs]:SetFontObject("GameFontNormalSmall")
	APR["MapZoneIcons"]["FS"..IdZs]:SetText(IdZs)
	APR["MapZoneIcons"]["FS"..IdZs]:SetTextColor(1, 1, 1)
	APR["MapZoneIconsRed"][IdZs] = CreateFrame("Frame",nil,UIParent)
	APR["MapZoneIconsRed"][IdZs]:SetFrameStrata("MEDIUM")
	APR["MapZoneIconsRed"][IdZs]:SetWidth(20)
	APR["MapZoneIconsRed"][IdZs]:SetHeight(20)
	APR["MapZoneIconsRed"][IdZs]:SetScale(0.6)
	local t = 	APR["MapZoneIconsRed"][IdZs]:CreateTexture(nil,"HIGH")
	t:SetTexture("Interface\\Addons\\APR-Core\\Img\\RedIcon.tga")
	t:SetAllPoints(APR["MapZoneIconsRed"][IdZs])
	--APR["MapZoneIconsRed"][IdZs]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	APR["MapZoneIconsRed"]["FS"..IdZs] = APR["MapZoneIconsRed"][IdZs]:CreateFontString("APRMapIconFS"..IdZs,"ARTWORK", "ChatFontNormal")
	APR["MapZoneIconsRed"]["FS"..IdZs]:SetParent(APR["MapZoneIconsRed"][IdZs])
	APR["MapZoneIconsRed"]["FS"..IdZs]:SetPoint("CENTER",APR["MapZoneIconsRed"][IdZs],"CENTER",0,0)
	APR["MapZoneIconsRed"]["FS"..IdZs]:SetWidth(30)
	APR["MapZoneIconsRed"]["FS"..IdZs]:SetHeight(25)
	APR["MapZoneIconsRed"]["FS"..IdZs]:SetJustifyH("CENTER")
	APR["MapZoneIconsRed"]["FS"..IdZs]:SetFontObject("GameFontNormalSmall")
	APR["MapZoneIconsRed"]["FS"..IdZs]:SetText(IdZs)
	APR["MapZoneIconsRed"]["FS"..IdZs]:SetTextColor(1, 1, 1)
end
function APR.MapOrderNumbers()
	APR.HBDP:RemoveAllWorldMapIcons("APRMapOrder")
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	if (APR.ActiveMap and APR.QStepList and APR.QStepList[APR.ActiveMap] and CurStep) then
		local znr = 0
		local SetMapIDs = WorldMapFrame:GetMapID()
		if (SetMapIDs == nil) then
			SetMapIDs = C_Map.GetBestMapForUnit("player")
		end
		for APR_index,APR_value in pairs(APR.QStepList[APR.ActiveMap]) do
			znr = znr + 1
			if (APR.QStepList[APR.ActiveMap][znr] and APR.QStepList[APR.ActiveMap][znr]["TT"] and CurStep < znr and CurStep > (znr-11)) then
				if (not APR["MapZoneIcons"][znr]) then
					APR.MakeMapOrderIcons(znr)
				end
				if (not APR.QStepList[APR.ActiveMap][znr]["CRange"]) then
					ix, iy = GetPlayerMapPos(SetMapIDs, APR.QStepList[APR.ActiveMap][znr]["TT"]["y"],APR.QStepList[APR.ActiveMap][znr]["TT"]["x"])
					if (CurStep < znr) then
						APR.HBDP:AddWorldMapIconMap("APRMapOrder", APR["MapZoneIconsRed"][znr], SetMapIDs, ix, iy, HBD_PINS_WORLDMAP_SHOW_PARENT)
					else
						APR.HBDP:AddWorldMapIconMap("APRMapOrder", APR["MapZoneIcons"][znr], SetMapIDs, ix, iy, HBD_PINS_WORLDMAP_SHOW_PARENT)
					end
				end
			end
		end
	end
end

APR_QH_EventFrame = CreateFrame("Frame")
APR_QH_EventFrame:RegisterEvent ("Q_LOG_UPDATE")
APR_QH_EventFrame:SetScript("OnEvent", function(self, event, ...)
	if (event=="Q_LOG_UPDATE") then
		if (APR1[APR.Realm][APR.Name]["Settings"]["ShowMap10s"] and APR1[APR.Realm][APR.Name]["Settings"]["ShowMap10s"] == 1 and WorldMapFrame:IsShown() and APR.ActiveMap and APR1[APR.Realm][APR.Name][APR.ActiveMap]) then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			if (CurStep and MapIconUpdateStep ~= CurStep and CurStep > 1) then
				APR.MapOrderNumbers()
			end
		end
	end
end)
