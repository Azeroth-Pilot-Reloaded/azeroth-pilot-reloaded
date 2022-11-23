local app = select(2, ...);
local L = app.L;

function AddQListButton(text, index, buttonFunction)
	APR.QList.QFrames["FS"..index].Button = CreateFrame("Button", "APR_SkipActiveButton"..index, APR.QList.QFrames[index])
	APR.QList.QFrames["FS"..index].Button:SetPoint("RIGHT", APR.QList.QFrames[index], "RIGHT", 0, 0)
	APR.QList.QFrames["FS"..index].Button:SetScript("OnMouseDown", buttonFunction)
	local t = APR.QList.QFrames["FS"..index].Button:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.QList.QFrames["FS"..index].Button)
	APR.QList.QFrames["FS"..index].Button.texture = t

	APR.QList.QFrames["FS"..index].Fontstring = APR.ArrowFrame:CreateFontString("CLSettingsFS2212","ARTWORK", "ChatFontNormal")
	APR.QList.QFrames["FS"..index].Fontstring:SetParent(APR.QList.QFrames["FS"..index].Button)
	APR.QList.QFrames["FS"..index].Fontstring:SetPoint("CENTER", APR.QList.QFrames["FS"..index].Button)
	APR.QList.QFrames["FS"..index].Fontstring:SetText(text)
	local skiplenght = APR.QList.QFrames["FS"..index].Fontstring:GetStringWidth()+20
	APR.QList.QFrames["FS"..index].Button:SetWidth(skiplenght)
	APR.QList.QFrames["FS"..index].Button:SetHeight(20)
	APR.QList.QFrames["FS"..index].Fontstring:SetWidth(skiplenght)
	APR.QList.QFrames["FS"..index].Fontstring:SetHeight(APR.QList.QFrames["FS"..index].Button:GetHeight() - 3)
	APR.QList.QFrames["FS"..index].Fontstring:SetFontObject("GameFontNormalLarge")
	APR.QList.QFrames["FS"..index].Fontstring:SetTextColor(1, 1, 0)
	APR.QList.QFrames["FS"..index].Button:Hide()
end

local function APR_CreateQList()
	if (not APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"]) then
		APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"] = GetScreenWidth() / 2.5
	end
	if (not APR1[APR.Realm][APR.Name]["Settings"]["Partytop"]) then
		APR1[APR.Realm][APR.Name]["Settings"]["Partytop"] = -(GetScreenHeight() / 4)
	end
	if (not APR1[APR.Realm][APR.Name]["Settings"]["MiniMapBlobAlpha"]) then
		APR1[APR.Realm][APR.Name]["Settings"]["MiniMapBlobAlpha"] = 1
	end
	if (not APR.PartyList) then
		APR.PartyList = {}
	end
	APR.PartyList.PartyFrame = CreateFrame("frame", "APR_PartyListFrame1", UIParent)
	APR.PartyList.PartyFrame:SetWidth(1)
	APR.PartyList.PartyFrame:SetHeight(1)
	APR.PartyList.PartyFrame:SetMovable(true)
	APR.PartyList.PartyFrame:EnableMouse(true)
	APR.PartyList.PartyFrame:SetFrameStrata("LOW")
	APR.PartyList.PartyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"], APR1[APR.Realm][APR.Name]["Settings"]["Partytop"])

	APR.PartyList.PartyFrames = {}
	APR.PartyList.PartyFrames2 = {}
	APR.PartyList.PartyFramesFS1 = {}
	APR.PartyList.PartyFramesFS2 = {}
	local CLi
	for CLi = 1, 5 do
		APR.PartyList.PartyFrames[CLi] = CreateFrame("frame", "CLQaaListF"..CLi, APR.PartyList.PartyFrame)
		APR.PartyList.PartyFrames[CLi]:SetWidth(120)

		APR.PartyList.PartyFrames[CLi]:SetHeight(25)
		APR.PartyList.PartyFrames[CLi]:SetPoint("BOTTOMLEFT", APR.PartyList.PartyFrame, "BOTTOMLEFT",40,-((25*CLi)-25))
		APR.PartyList.PartyFrames[CLi]:Hide()
		--APR.PartyList.PartyFrames[CLi]:SetBackdrop( {
		--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
		--});
		local t = APR.PartyList.PartyFrames[CLi]:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
		t:SetAllPoints(APR.PartyList.PartyFrames[CLi])
		APR.PartyList.PartyFrames[CLi].texture = t

		APR.PartyList.PartyFrames[CLi]:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" and APR1[APR.Realm][APR.Name]["Settings"]["Lock"] == 0 then
				APR.PartyList.PartyFrame:StartMoving();
				APR.PartyList.PartyFrame.isMoving = true;
			end
		end)
		APR.PartyList.PartyFrames[CLi]:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and APR.PartyList.PartyFrame.isMoving then
				APR.PartyList.PartyFrame:StopMovingOrSizing();
				APR.PartyList.PartyFrame.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"] = APR.PartyList.PartyFrame:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["Partytop"] = APR.PartyList.PartyFrame:GetTop() - GetScreenHeight()
				--APR.PartyList.PartyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"], APR1[APR.Realm][APR.Name]["Settings"]["Partytop"])
			end
		end)
		APR.PartyList.PartyFrames[CLi]:SetScript("OnHide", function(self)
			if ( APR.PartyList.PartyFrame.isMoving ) then
				APR.PartyList.PartyFrame:StopMovingOrSizing();
				APR.PartyList.PartyFrame.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"] = APR.PartyList.PartyFrame:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["Partytop"] = APR.PartyList.PartyFrame:GetTop() - GetScreenHeight()
				--APR.PartyList.PartyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"], APR1[APR.Realm][APR.Name]["Settings"]["Partytop"])
			end
		end)

		APR.PartyList.PartyFramesFS1[CLi] = APR.PartyList.PartyFrames[CLi]:CreateFontString("CLQaasFS1","ARTWORK", "ChatFontNormal")
		APR.PartyList.PartyFramesFS1[CLi]:SetParent(APR.PartyList.PartyFrames[CLi])
		APR.PartyList.PartyFramesFS1[CLi]:SetPoint("LEFT",APR.PartyList.PartyFrames[CLi],"LEFT",5,0)
		APR.PartyList.PartyFramesFS1[CLi]:SetWidth(300)
		APR.PartyList.PartyFramesFS1[CLi]:SetHeight(38)
		APR.PartyList.PartyFramesFS1[CLi]:SetJustifyH("LEFT")
		APR.PartyList.PartyFramesFS1[CLi]:SetFontObject("GameFontNormalLarge")
		APR.PartyList.PartyFramesFS1[CLi]:SetText(L["NAME"])
		APR.PartyList.PartyFramesFS1[CLi]:SetTextColor(1, 1, 0)

		APR.PartyList.PartyFrames2[CLi] = CreateFrame("frame", "CLQaListF"..CLi, APR.PartyList.PartyFrame)
		APR.PartyList.PartyFrames2[CLi]:SetWidth(40)

		APR.PartyList.PartyFrames2[CLi]:SetHeight(25)
		APR.PartyList.PartyFrames2[CLi]:SetPoint("BOTTOMLEFT", APR.PartyList.PartyFrame, "BOTTOMLEFT",0,-((25*CLi)-25))
		APR.PartyList.PartyFrames2[CLi]:Hide()
		--APR.PartyList.PartyFrames2[CLi]:SetBackdrop( {
		--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
		--});
		local t = APR.PartyList.PartyFrames2[CLi]:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
		t:SetAllPoints(APR.PartyList.PartyFrames2[CLi])
		APR.PartyList.PartyFrames2[CLi].texture = t

		APR.PartyList.PartyFrames2[CLi]:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" and APR1[APR.Realm][APR.Name]["Settings"]["Lock"] == 0 then
				APR.PartyList.PartyFrame:StartMoving();
				APR.PartyList.PartyFrame.isMoving = true;
			end
		end)
		APR.PartyList.PartyFrames2[CLi]:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and APR.PartyList.PartyFrame.isMoving then
				APR.PartyList.PartyFrame:StopMovingOrSizing();
				APR.PartyList.PartyFrame.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"] = APR.PartyList.PartyFrame:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["Partytop"] = APR.PartyList.PartyFrame:GetTop() - GetScreenHeight()
				APR.PartyList.PartyFrame:ClearAllPoints()
				APR.PartyList.PartyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"], APR1[APR.Realm][APR.Name]["Settings"]["Partytop"])
			end
		end)
		APR.PartyList.PartyFrames2[CLi]:SetScript("OnHide", function(self)
			if ( APR.PartyList.PartyFrame.isMoving ) then
				APR.PartyList.PartyFrame:StopMovingOrSizing();
				APR.PartyList.PartyFrame.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"] = APR.PartyList.PartyFrame:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["Partytop"] = APR.PartyList.PartyFrame:GetTop() - GetScreenHeight()
				APR.PartyList.PartyFrame:ClearAllPoints()
				APR.PartyList.PartyFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["Partyleft"], APR1[APR.Realm][APR.Name]["Settings"]["Partytop"])
			end
		end)

		APR.PartyList.PartyFramesFS2[CLi] = APR.PartyList.PartyFrames2[CLi]:CreateFontString("CLQaasFS1","ARTWORK", "ChatFontNormal")
		APR.PartyList.PartyFramesFS2[CLi]:SetParent(APR.PartyList.PartyFrames[CLi])
		APR.PartyList.PartyFramesFS2[CLi]:SetPoint("CENTER",APR.PartyList.PartyFrames2[CLi],"CENTER",0,0)
		APR.PartyList.PartyFramesFS2[CLi]:SetWidth(40)
		APR.PartyList.PartyFramesFS2[CLi]:SetHeight(38)
		APR.PartyList.PartyFramesFS2[CLi]:SetJustifyH("CENTER")
		APR.PartyList.PartyFramesFS2[CLi]:SetFontObject("GameFontNormalLarge")
		APR.PartyList.PartyFramesFS2[CLi]:SetText("123")
		APR.PartyList.PartyFramesFS2[CLi]:SetTextColor(1, 1, 0)

	end
	APR.QList.SugQFrame = {}
	APR.QList.SugQFrame = CreateFrame("frame", "APR_SugQFrameFrame", UIParent)
	APR.QList.SugQFrame:SetWidth(300)
	APR.QList.SugQFrame:SetHeight(150)
	APR.QList.SugQFrame:SetMovable(true)
	APR.QList.SugQFrame:EnableMouse(true)
	APR.QList.SugQFrame:SetFrameStrata("LOW")
	APR.QList.SugQFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["Sugleft"], APR1[APR.Realm][APR.Name]["Settings"]["Sugtop"])
	--APR.QList.SugQFrame:SetBackdrop( {
	--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
	--});
	local t = APR.QList.SugQFrame:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.QList.SugQFrame)
	APR.QList.SugQFrame.texture = t

	APR.QList.SugQFrame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			APR.QList.SugQFrame:StartMoving();
			APR.QList.SugQFrame.isMoving = true;
		end
	end)
	APR.QList.SugQFrame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.QList.SugQFrame.isMoving then
			APR.QList.SugQFrame:StopMovingOrSizing();
			APR.QList.SugQFrame.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["Sugleft"] = APR.QList.SugQFrame:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["Sugtop"] = APR.QList.SugQFrame:GetTop() - GetScreenHeight()
			APR.QList.SugQFrame:ClearAllPoints()
			APR.QList.SugQFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["Sugleft"], APR1[APR.Realm][APR.Name]["Settings"]["Sugtop"])
		end
	end)
	APR.QList.SugQFrame:SetScript("OnHide", function(self)
		if ( APR.QList.SugQFrame.isMoving ) then
			APR.QList.SugQFrame:StopMovingOrSizing();
			APR.QList.SugQFrame.isMoving = false;
		end
	end)
	APR.QList.SugQFrame:Hide()

	APR.QList.SugQFrameFS1 = APR.QList.SugQFrame:CreateFontString("CLQaaFS1","ARTWORK", "ChatFontNormal")
	APR.QList.SugQFrameFS1:SetParent(APR.QList.SugQFrame)
	APR.QList.SugQFrameFS1:SetPoint("TOPLEFT",APR.QList.SugQFrame,"TOPLEFT",0,0)
	APR.QList.SugQFrameFS1:SetWidth(300)
	APR.QList.SugQFrameFS1:SetHeight(38)
	APR.QList.SugQFrameFS1:SetJustifyH("CENTER")
	APR.QList.SugQFrameFS1:SetFontObject("GameFontNormalLarge")
	APR.QList.SugQFrameFS1:SetText(L["QS_TEXT"])
	APR.QList.SugQFrameFS1:SetTextColor(1, 1, 0)
	APR.QList.SugQFrameFS2 = APR.QList.SugQFrame:CreateFontString("CLQaaFS2","ARTWORK", "ChatFontNormal")
	APR.QList.SugQFrameFS2:SetParent(APR.QList.SugQFrame)
	APR.QList.SugQFrameFS2:SetPoint("TOPLEFT",APR.QList.SugQFrame,"TOPLEFT",0,-30)
	APR.QList.SugQFrameFS2:SetWidth(300)
	APR.QList.SugQFrameFS2:SetHeight(38)
	APR.QList.SugQFrameFS2:SetJustifyH("CENTER")
	APR.QList.SugQFrameFS2:SetFontObject("GameFontNormalLarge")
	APR.QList.SugQFrameFS2:SetText(L["SUGGESTED_PLAYERS"]..": ")
	APR.QList.SugQFrameFS2:SetTextColor(1, 1, 0)

	APR.QList.SugQFrame["Button1"] = CreateFrame("Button", "APR_SBX1", UIParent, "SecureActionButtonTemplate")
	APR.QList.SugQFrame["Button1"]:SetPoint("BOTTOMLEFT",APR.QList.SugQFrame,"BOTTOMLEFT",15,5)
	APR.QList.SugQFrame["Button1"]:SetWidth(110)
	APR.QList.SugQFrame["Button1"]:SetHeight(30)
	APR.QList.SugQFrame["Button1"]:SetText(L["ACCEPT_Q"])
	APR.QList.SugQFrame["Button1"]:SetParent(APR.QList.SugQFrame)
	APR.QList.SugQFrame.Button1:SetNormalFontObject("GameFontNormal")
	APR.QList.SugQFrame.Button1ntex = APR.QList.SugQFrame.Button1:CreateTexture()
	APR.QList.SugQFrame.Button1ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	APR.QList.SugQFrame.Button1ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.QList.SugQFrame.Button1ntex:SetAllPoints()
	APR.QList.SugQFrame.Button1:SetNormalTexture(APR.QList.SugQFrame.Button1ntex)
	APR.QList.SugQFrame.Button1htex = APR.QList.SugQFrame.Button1:CreateTexture()
	APR.QList.SugQFrame.Button1htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.QList.SugQFrame.Button1htex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.QList.SugQFrame.Button1htex:SetAllPoints()
	APR.QList.SugQFrame.Button1:SetHighlightTexture(APR.QList.SugQFrame.Button1htex)
	APR.QList.SugQFrame.Button1ptex = APR.QList.SugQFrame.Button1:CreateTexture()
	APR.QList.SugQFrame.Button1ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	APR.QList.SugQFrame.Button1ptex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.QList.SugQFrame.Button1ptex:SetAllPoints()
	APR.QList.SugQFrame.Button1:SetPushedTexture(APR.QList.SugQFrame.Button1ptex)
	APR.QList.SugQFrame["Button1"]:SetScript("OnClick", function(self, arg1)
		APR.QAskPopWantedAsk("yes")
	end)
	APR.QList.SugQFrame["Button2"] = CreateFrame("Button", "APR_SBX2", UIParent, "SecureActionButtonTemplate")
	APR.QList.SugQFrame["Button2"]:SetPoint("BOTTOMRIGHT",APR.QList.SugQFrame,"BOTTOMRIGHT",-15,5)
	APR.QList.SugQFrame["Button2"]:SetWidth(110)
	APR.QList.SugQFrame["Button2"]:SetHeight(30)
	APR.QList.SugQFrame["Button2"]:SetText(L["DECLINE_Q"])
	APR.QList.SugQFrame["Button2"]:SetParent(APR.QList.SugQFrame)
	APR.QList.SugQFrame.Button2:SetNormalFontObject("GameFontNormal")
	APR.QList.SugQFrame.Button2ntex = APR.QList.SugQFrame.Button2:CreateTexture()
	APR.QList.SugQFrame.Button2ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	APR.QList.SugQFrame.Button2ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.QList.SugQFrame.Button2ntex:SetAllPoints()
	APR.QList.SugQFrame.Button2:SetNormalTexture(APR.QList.SugQFrame.Button2ntex)
	APR.QList.SugQFrame.Button2htex = APR.QList.SugQFrame.Button2:CreateTexture()
	APR.QList.SugQFrame.Button2htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.QList.SugQFrame.Button2htex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.QList.SugQFrame.Button2htex:SetAllPoints()
	APR.QList.SugQFrame.Button2:SetHighlightTexture(APR.QList.SugQFrame.Button2htex)
	APR.QList.SugQFrame.Button2ptex = APR.QList.SugQFrame.Button2:CreateTexture()
	APR.QList.SugQFrame.Button2ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	APR.QList.SugQFrame.Button2ptex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.QList.SugQFrame.Button2ptex:SetAllPoints()
	APR.QList.SugQFrame.Button2:SetPushedTexture(APR.QList.SugQFrame.Button2ptex)
	APR.QList.SugQFrame["Button2"]:SetScript("OnClick", function(self, arg1)
		APR.QAskPopWantedAsk("no")
	end)
	APR.QList.Greetings = CreateFrame("frame", "APR_GreetingsFrame", UIParent)
	APR.QList.Greetings:SetWidth(330)
	APR.QList.Greetings:SetHeight(200)
	APR.QList.Greetings:SetMovable(true)
	APR.QList.Greetings:EnableMouse(true)
	APR.QList.Greetings:SetFrameStrata("LOW")
	APR.QList.Greetings:SetPoint("LEFT", UIParent, "LEFT", 300, 0)
	--APR.QList.Greetings:SetBackdrop( {
	--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
	--});
	local t = APR.QList.Greetings:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.QList.Greetings)
	APR.QList.Greetings.texture = t

	APR.QList.Greetings:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			APR.QList.Greetings:StartMoving();
			APR.QList.Greetings.isMoving = true;
		end
	end)
	APR.QList.Greetings:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.QList.Greetings.isMoving then
			APR.QList.Greetings:StopMovingOrSizing();
			APR.QList.Greetings.isMoving = false;
		end
	end)
	APR.QList.Greetings:SetScript("OnHide", function(self)
		if ( APR.QList.Greetings.isMoving ) then
			APR.QList.Greetings:StopMovingOrSizing();
			APR.QList.Greetings.isMoving = false;
		end
	end)
	APR.QList.Greetings2FS1 = APR.QList.Greetings:CreateFontString("APRGreetingsFS1","ARTWORK", "ChatFontNormal")
	APR.QList.Greetings2FS1:SetParent(APR.QList.Greetings)
	APR.QList.Greetings2FS1:SetPoint("TOP",APR.QList.Greetings,"TOP",0,0)
	APR.QList.Greetings2FS1:SetWidth(300)
	APR.QList.Greetings2FS1:SetHeight(38)
	APR.QList.Greetings2FS1:SetJustifyH("LEFT")
	APR.QList.Greetings2FS1:SetFontObject("GameFontNormal")
	APR.QList.Greetings2FS1:SetText("Welcome to Azeroth Pilot Reloaded")
	APR.QList.Greetings2FS1:SetTextColor(1, 1, 0)

	APR.QList.Greetings2FS221 = APR.QList.Greetings:CreateFontString("APRGreetingsFS221","ARTWORK", "ChatFontNormal")
	APR.QList.Greetings2FS221:SetParent(APR.QList.Greetings)
	APR.QList.Greetings2FS221:SetPoint("TOP",APR.QList.Greetings,"TOP",0,-8)
	APR.QList.Greetings2FS221:SetWidth(290)
	APR.QList.Greetings2FS221:SetHeight(72)
	APR.QList.Greetings2FS221:SetJustifyH("LEFT")
	APR.QList.Greetings2FS221:SetFontObject("GameFontNormal")
	APR.QList.Greetings2FS221:SetText("Require 5+ Goblin Glider kits.")
	APR.QList.Greetings2FS221:SetTextColor(1, 1, 0)

	APR.QList.Greetings2FS2 = APR.QList.Greetings:CreateFontString("APRGreetingsFS2","ARTWORK", "ChatFontNormal")
	APR.QList.Greetings2FS2:SetParent(APR.QList.Greetings)
	APR.QList.Greetings2FS2:SetPoint("TOP",APR.QList.Greetings,"TOP",0,-38)
	APR.QList.Greetings2FS2:SetWidth(290)
	APR.QList.Greetings2FS2:SetHeight(72)
	APR.QList.Greetings2FS2:SetJustifyH("LEFT")
	APR.QList.Greetings2FS2:SetFontObject("GameFontNormal")
	APR.QList.Greetings2FS2:SetText("Special thanks to BrutallStatic for helping with 50-60, catch him at:")
	APR.QList.Greetings2FS2:SetTextColor(1, 1, 0)

	APR.QList.Greetings2EB1 = CreateFrame("EditBox", "APRGreetEBox", APR.QList.Greetings, "InputBoxTemplate")
	APR.QList.Greetings2EB1:SetSize(200, 20)
	APR.QList.Greetings2EB1:SetPoint("TOP",APR.QList.Greetings,"TOP",0,-88)
	APR.QList.Greetings2EB1:SetAutoFocus(false)
	APR.QList.Greetings2EB1:SetText("www.twitch.tv/brutallstatic")
	APR.QList.Greetings2EB1:SetCursorPosition(0)

	APR.QList.Greetings2FS3 = APR.QList.Greetings:CreateFontString("APRGreetingsFS3","ARTWORK", "ChatFontNormal")
	APR.QList.Greetings2FS3:SetParent(APR.QList.Greetings)
	APR.QList.Greetings2FS3:SetPoint("TOP",APR.QList.Greetings,"TOP",0,-98)
	APR.QList.Greetings2FS3:SetWidth(290)
	APR.QList.Greetings2FS3:SetHeight(72)
	APR.QList.Greetings2FS3:SetJustifyH("LEFT")
	APR.QList.Greetings2FS3:SetFontObject("GameFontNormal")
	APR.QList.Greetings2FS3:SetText("Special thanks to DesMephisto for helping with route for 1-50, catch him at:")
	APR.QList.Greetings2FS3:SetTextColor(1, 1, 0)

	APR.QList.Greetings2EB2 = CreateFrame("EditBox", "APRGreetEBox2", APR.QList.Greetings, "InputBoxTemplate")
	APR.QList.Greetings2EB2:SetSize(200, 20)
	APR.QList.Greetings2EB2:SetPoint("TOP",APR.QList.Greetings,"TOP",0,-148)
	APR.QList.Greetings2EB2:SetAutoFocus(false)
	APR.QList.Greetings2EB2:SetText("www.twitch.tv/desmephisto")

	APR.QList.GreetingsHideB = CreateFrame("Button", "APR_GreetingsHideB", APR.QList.Greetings, "SecureActionButtonTemplate")
	APR.QList.GreetingsHideB:SetPoint("BOTTOMRIGHT",APR.QList.Greetings,"BOTTOMRIGHT",-15,5)
	APR.QList.GreetingsHideB:SetWidth(90)
	APR.QList.GreetingsHideB:SetHeight(22)
	APR.QList.GreetingsHideB:SetText(L["CLOSE"])
	APR.QList.GreetingsHideB:SetParent(APR.QList.Greetings)
	APR.QList.GreetingsHideB:SetNormalFontObject("GameFontNormalLarge")
	APR.QList.GreetingsHideBntex = APR.QList.GreetingsHideB:CreateTexture()
	APR.QList.GreetingsHideBntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	APR.QList.GreetingsHideBntex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.QList.GreetingsHideBntex:SetAllPoints()
	APR.QList.GreetingsHideB:SetNormalTexture(APR.QList.GreetingsHideBntex)
	APR.QList.GreetingsHideBhtex = APR.QList.GreetingsHideB:CreateTexture()
	APR.QList.GreetingsHideBhtex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.QList.GreetingsHideBhtex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.QList.GreetingsHideBhtex:SetAllPoints()
	APR.QList.GreetingsHideB:SetHighlightTexture(APR.QList.GreetingsHideBhtex)
	APR.QList.GreetingsHideBptex = APR.QList.GreetingsHideB:CreateTexture()
	APR.QList.GreetingsHideBptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	APR.QList.GreetingsHideBptex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.QList.GreetingsHideBptex:SetAllPoints()
	APR.QList.GreetingsHideB:SetPushedTexture(APR.QList.GreetingsHideBptex)
	APR.QList.GreetingsHideB:SetScript("OnClick", function(self, arg1)
		APR1[APR.Realm][APR.Name]["Settings"]["Greetings2"] = 1
		APR.QList.Greetings:Hide()
	end)
	if (APR1[APR.Realm][APR.Name]["Settings"]["Greetings2"] == 1) then
		APR.QList.Greetings:Hide()
	end

	APR.QList.MainFrame = CreateFrame("frame", "APR_QFrame", UIParent)
	APR.QList.MainFrame:SetWidth(1)
	APR.QList.MainFrame:SetHeight(1)
	APR.QList.MainFrame:SetMovable(true)
	APR.QList.MainFrame:EnableMouse(true)
	APR.QList.MainFrame:SetFrameStrata("MEDIUM")
	APR.QList.MainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
	APR.QList.ListFrame = CreateFrame("frame", "APR_QFrameList", UIParent)
	if (APR1[APR.Realm][APR.Name]["Settings"]["top"] > 6) then
		APR1[APR.Realm][APR.Name]["Settings"]["left"] = 150
		APR1[APR.Realm][APR.Name]["Settings"]["top"] = -150
		APR.QList.MainFrame:ClearAllPoints()
		APR.QList.MainFrame:SetPoint("TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
		print("APR: "..L["QLIST_OUT_SCREEN"])
	end
	APR.QList.ListFrame:SetWidth(1)
	APR.QList.ListFrame:SetHeight(1)
	APR.QList.ListFrame:SetFrameStrata("MEDIUM")
	APR.QList.ListFrame:SetPoint("TOPLEFT", APR.QList.MainFrame, "TOPLEFT",0,0)
	APR.QList.ListFrame:SetMovable(true)
	APR.QList.ListFrame:EnableMouse(true)
	APR.QList.ListFrame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not APR.QList.MainFrame.isMoving and APR1[APR.Realm][APR.Name]["Settings"]["Lock"] == 0 then
			APR.QList.MainFrame:StartMoving();
			APR.QList.MainFrame.isMoving = true;
		end
	end)
	APR.QList.ListFrame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.QList.MainFrame.isMoving then
			APR.QList.MainFrame:StopMovingOrSizing();
			APR.QList.MainFrame.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["left"] = APR.QList.MainFrame:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["top"] = APR.QList.MainFrame:GetTop() - GetScreenHeight()
			APR.QList.MainFrame:ClearAllPoints()
			APR.QList.MainFrame:SetPoint("TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
			if (APR1[APR.Realm][APR.Name]["Settings"]["top"] > 6) then
				APR1[APR.Realm][APR.Name]["Settings"]["left"] = 150
				APR1[APR.Realm][APR.Name]["Settings"]["top"] = -150
				APR.QList.MainFrame:ClearAllPoints()
				APR.QList.MainFrame:SetPoint("TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
				print("APR: "..L["QLIST_OUT_SCREEN"])
			end
			APR_CombatTestVar = 1
		end
	end)
	APR.QList.ListFrame:SetScript("OnHide", function(self)
		if ( APR.QList.MainFrame.isMoving ) then
			APR.QList.MainFrame:StopMovingOrSizing();
			APR.QList.MainFrame.isMoving = false;
		end
	end)

	APR.QList20 = CreateFrame("frame", "APR_QFrame20", UIParent)
	APR.QList20:SetWidth(1)
	APR.QList20:SetHeight(1)
	APR.QList20:SetFrameStrata("MEDIUM")
	APR.QList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])

	APR.QList21 = CreateFrame("frame", "APR_QFrame21", UIParent)
	APR.QList21:SetWidth(1)
	APR.QList21:SetHeight(1)
	APR.QList21:SetFrameStrata("MEDIUM")
	APR.QList21:SetPoint("TOPLEFT", APR.QList20, "TOPLEFT",0,0)

	APR.QList.ButtonParent = CreateFrame("frame", "CLQListFddd", UIParent)
	APR.QList.ButtonParent:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["Scale"])
	APR.QList.QFrames = {}
	APR.QList2 = {}

	APR.QList.QFrames["MyProgress"] = CreateFrame("frame", "CLQListMyProgress", APR.QList.ListFrame)
	APR.QList.QFrames["MyProgress"]:SetWidth(150)
	APR.QList.QFrames["MyProgress"]:SetHeight(22)
	APR.QList.QFrames["MyProgress"]:SetPoint("BOTTOMLEFT", APR.QList.ListFrame, "BOTTOMLEFT",0,0)
	--APR.QList.QFrames["MyProgress"]:SetBackdrop( {
	--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
	--});
	local t = APR.QList.QFrames["MyProgress"]:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.QList.QFrames["MyProgress"])
	APR.QList.QFrames["MyProgress"].texture = t

	APR.QList.QFrames["MyProgress"]:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not APR.QList.MainFrame.isMoving and APR1[APR.Realm][APR.Name]["Settings"]["Lock"] == 0 then
			APR.QList.MainFrame:StartMoving();
			APR.QList.MainFrame.isMoving = true;
		end
	end)
	APR.QList.QFrames["MyProgress"]:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.QList.MainFrame.isMoving then
			APR.QList.MainFrame:StopMovingOrSizing();
			APR.QList.MainFrame.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["left"] = APR.QList.MainFrame:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["top"] = APR.QList.MainFrame:GetTop() - GetScreenHeight()
			APR.QList.MainFrame:ClearAllPoints()
			APR.QList.MainFrame:SetPoint("TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
			if (APR1[APR.Realm][APR.Name]["Settings"]["top"] > 6) then
				APR1[APR.Realm][APR.Name]["Settings"]["left"] = 150
				APR1[APR.Realm][APR.Name]["Settings"]["top"] = -150
				APR.QList.MainFrame:ClearAllPoints()
				APR.QList.MainFrame:SetPoint("TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
				print("APR: "..L["QLIST_OUT_SCREEN"])
			end
			APR_CombatTestVar = 1
		end
	end)
	APR.QList.QFrames["MyProgress"]:SetScript("OnHide", function(self)
		if ( APR.QList.MainFrame.isMoving ) then
			APR.QList.MainFrame:StopMovingOrSizing();
			APR.QList.MainFrame.isMoving = false;
		end
	end)

	APR.QList.QFrames["MyProgressFS"] = APR.QList.ListFrame:CreateFontString("CLQFSProgR","ARTWORK", "ChatFontNormal")
	APR.QList.QFrames["MyProgressFS"]:SetParent(APR.QList.QFrames["MyProgress"])
	APR.QList.QFrames["MyProgressFS"]:SetPoint("BOTTOMLEFT",APR.QList.QFrames["MyProgress"],"BOTTOMLEFT",0,2)
	APR.QList.QFrames["MyProgressFS"]:SetWidth(150)
	APR.QList.QFrames["MyProgressFS"]:SetHeight(18)
	APR.QList.QFrames["MyProgressFS"]:SetJustifyH("CENTER")
	APR.QList.QFrames["MyProgressFS"]:SetFontObject("GameFontNormalSmall")
	APR.QList.QFrames["MyProgressFS"]:SetText("")
	APR.QList.QFrames["MyProgressFS"]:SetTextColor(1, 1, 0)
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 0) then
		APR.QList.QFrames["MyProgress"]:Hide()
	end
	local CLi
	for CLi = 1, 20 do

		APR["Icons"][CLi] = CreateFrame("Frame",nil,UIParent)
		APR["Icons"][CLi]:SetFrameStrata("HIGH")
		APR["Icons"][CLi]:SetWidth(5)
		APR["Icons"][CLi]:SetHeight(5)
		local t = 	APR["Icons"][CLi]:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.blp")
		t:SetAllPoints(APR["Icons"][CLi])
		APR["Icons"][CLi].texture = t
		APR["Icons"][CLi]:SetPoint("CENTER",0,0)
		APR["Icons"][CLi]:Hide()
		APR["Icons"][CLi].P = 0
		APR["Icons"][CLi].A = 0
		APR["Icons"][CLi].D = 0
		APR["Icons"][CLi].texture:SetAlpha(APR1[APR.Realm][APR.Name]["Settings"]["MiniMapBlobAlpha"])

		APR["MapIcons"][CLi] = CreateFrame("Frame",nil,UIParent)
		APR["MapIcons"][CLi]:SetFrameStrata("HIGH")
		APR["MapIcons"][CLi]:SetWidth(5)
		APR["MapIcons"][CLi]:SetHeight(5)
		local t = 	APR["MapIcons"][CLi]:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.blp")
		t:SetAllPoints(APR["MapIcons"][CLi])
		APR["MapIcons"][CLi].texture = t
		APR["MapIcons"][CLi]:SetPoint("CENTER",0,0)
		APR["MapIcons"][CLi]:Hide()
		APR["MapIcons"][CLi].P = 0
		APR["MapIcons"][CLi].A = 0
		APR["MapIcons"][CLi].D = 0

		APR.QList.QFrames[CLi] = CreateFrame("frame", "CLQListF"..CLi, APR.QList.ListFrame)
		APR.QList.QFrames[CLi]:SetWidth(410)

		APR.QList.QFrames[CLi]:SetHeight(38)
		APR.QList.QFrames[CLi]:SetPoint("BOTTOMLEFT", APR.QList.ListFrame, "BOTTOMLEFT",0,-((CLi * 38)+CLi))
		--APR.QList.QFrames[CLi]:SetBackdrop( {
		--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
		--});
		local t = APR.QList.QFrames[CLi]:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
		t:SetAllPoints(APR.QList.QFrames[CLi])
		APR.QList.QFrames[CLi].texture = t

		APR.QList.QFrames[CLi]:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" and not APR.QList.MainFrame.isMoving and APR1[APR.Realm][APR.Name]["Settings"]["Lock"] == 0 then
				APR.QList.MainFrame:StartMoving();
				APR.QList.MainFrame.isMoving = true;
			end
		end)
		APR.QList.QFrames[CLi]:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and APR.QList.MainFrame.isMoving then
				APR.QList.MainFrame:StopMovingOrSizing();
				APR.QList.MainFrame.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["left"] = APR.QList.MainFrame:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["top"] = APR.QList.MainFrame:GetTop() - GetScreenHeight()
				APR.QList.MainFrame:ClearAllPoints()
				APR.QList.MainFrame:SetPoint("TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
				if (APR1[APR.Realm][APR.Name]["Settings"]["top"] > 6) then
					APR1[APR.Realm][APR.Name]["Settings"]["left"] = 150
					APR1[APR.Realm][APR.Name]["Settings"]["top"] = -150
					APR.QList.MainFrame:ClearAllPoints()
					APR.QList.MainFrame:SetPoint("TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
					print("APR: "..L["QLIST_OUT_SCREEN"])
				end
				APR_CombatTestVar = 1
			end
		end)
		APR.QList.QFrames[CLi]:SetScript("OnHide", function(self)
			if ( APR.QList.MainFrame.isMoving ) then
				APR.QList.MainFrame:StopMovingOrSizing();
				APR.QList.MainFrame.isMoving = false;
			end
		end)
		APR.QList.QFrames[CLi]:Hide()
		APR.QList.QFrames["FS"..CLi] = APR.QList.ListFrame:CreateFontString("CLQFS"..CLi,"ARTWORK", "ChatFontNormal")
		APR.QList.QFrames["FS"..CLi]:SetParent(APR.QList.QFrames[CLi])
		APR.QList.QFrames["FS"..CLi]:SetPoint("TOPLEFT",APR.QList.QFrames[CLi],"TOPLEFT",5,0)
		APR.QList.QFrames["FS"..CLi]:SetWidth(800)
		APR.QList.QFrames["FS"..CLi]:SetHeight(38)
		APR.QList.QFrames["FS"..CLi]:SetJustifyH("LEFT")
		APR.QList.QFrames["FS"..CLi]:SetFontObject("GameFontNormalLarge")
		APR.QList.QFrames["FS"..CLi]:SetText("")
		APR.QList.QFrames["FS"..CLi]:SetTextColor(1, 1, 0)

		APR.QList.QFrames["FS"..CLi]["BQid"] = 0
		--skip waypoint button
		AddQListButton(L["SKIP_BUTTON"], CLi, function(self, button)
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			if (APR.QStepList[APR.ActiveMap] and APR.QStepList[APR.ActiveMap][CurStep]) then
				local steps = APR.QStepList[APR.ActiveMap][CurStep]
				if (steps and steps["UseDalaHS"]) then
					APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
					APR.BookingList["PrintQStep"] = 1
					APR.QList.QFrames["FS"..CLi].Button:Hide()
				else
					APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
					APR.BookingList["PrintQStep"] = 1
					APR.QList.QFrames["FS"..CLi].Button:Hide()
				end
			end
		end)

		APR.QList2["BF"..CLi] = CreateFrame("frame", "CLQListF2z"..CLi, APR.QList21)
		APR.QList2["BF"..CLi]:SetWidth(410)
		APR.QList2["BF"..CLi]:SetHeight(38)
		APR.QList2["BF"..CLi]:SetPoint("BOTTOMLEFT", APR.QList21, "BOTTOMLEFT",0,0)

		APR.QList2["BF"..CLi]:Hide()
		APR.QList2["BF"..CLi]:SetParent(APR.QList.ButtonParent)
		APR.QList2["BF"..CLi]["APR_Button"] = CreateFrame("Button", "APR_SBX"..CLi, APR.QList2["BF"..CLi], "SecureActionButtonTemplate")
		APR.QList2["BF"..CLi]["APR_Button"]:SetWidth(38)
		APR.QList2["BF"..CLi]["APR_Button"]:SetHeight(38)
		APR.QList2["BF"..CLi]["APR_Button"]:SetText("X")
		APR.QList2["BF"..CLi]["APR_Button"]:SetPoint("LEFT",APR.QList2["BF"..CLi],"RIGHT",0,0)
		APR.QList2["BF"..CLi]["APR_Button"]:SetNormalFontObject("GameFontNormalLarge")
		APR.QList2["BF"..CLi]["APR_Buttonntex"] = APR.QList2["BF"..CLi]["APR_Button"]:CreateTexture()
		APR.QList2["BF"..CLi]["APR_Buttonntex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
		APR.QList2["BF"..CLi]["APR_Buttonntex"]:SetTexCoord(0, 0.625, 0, 0.6875)
		APR.QList2["BF"..CLi]["APR_Buttonntex"]:SetAllPoints()
		APR.QList2["BF"..CLi]["APR_Button"]:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Highlight")
		APR.QList2["BF"..CLi]["APR_Buttonhtex"] = APR.QList2["BF"..CLi]["APR_Button"]:CreateTexture()
		APR.QList2["BF"..CLi]["APR_Buttonhtex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
		APR.QList2["BF"..CLi]["APR_Buttonhtex"]:SetTexCoord(0, 0.625, 0, 0.6875)
		APR.QList2["BF"..CLi]["APR_Buttonhtex"]:SetAllPoints()
		APR.QList2["BF"..CLi]["APR_Button"]:SetHighlightTexture(APR.QList2["BF"..CLi]["APR_Buttonhtex"])
		APR.QList2["BF"..CLi]["APR_Buttonptex"] = APR.QList2["BF"..CLi]["APR_Button"]:CreateTexture()
		APR.QList2["BF"..CLi]["APR_Buttonptex"]:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
		APR.QList2["BF"..CLi]["APR_Buttonptex"]:SetTexCoord(0, 0.625, 0, 0.6875)
		APR.QList2["BF"..CLi]["APR_Buttonptex"]:SetAllPoints()
		APR.QList2["BF"..CLi]["APR_Button"]:SetPushedTexture(APR.QList2["BF"..CLi]["APR_Buttonptex"])
		APR.QList2["BF"..CLi]["APR_ButtonCD"] = CreateFrame("Cooldown", "APR_Cooldown"..CLi, APR.QList2["BF"..CLi]["APR_Button"], "CooldownFrameTemplate")
		APR.QList2["BF"..CLi]["APR_ButtonCD"]:SetAllPoints()

	end

	APR.QList.QBuffFrame = CreateFrame("frame", "APR_SugQFrameFramebufffra", UIParent)
	APR.QList.QBuffFrame:SetWidth(230)
	APR.QList.QBuffFrame:SetHeight(110)
	APR.QList.QBuffFrame:SetMovable(true)
	APR.QList.QBuffFrame:EnableMouse(true)
	APR.QList.QBuffFrame:SetFrameStrata("LOW")
	APR.QList.QBuffFrame:SetPoint("TOPLEFT", UIParent, 300, -300)
	--APR.QList.QBuffFrame:SetBackdrop( {
	--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
	--});
	APR.QList.QBuffFrame:Hide()
	local t = APR.QList.QBuffFrame:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.QList.QBuffFrame)
	APR.QList.QBuffFrame.texture = t

	APR.QList.QBuffFrame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			APR.QList.QBuffFrame:StartMoving();
			APR.QList.QBuffFrame.isMoving = true;
		end
	end)
	APR.QList.QBuffFrame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.QList.QBuffFrame.isMoving then
			APR.QList.QBuffFrame:StopMovingOrSizing();
			APR.QList.QBuffFrame.isMoving = false;
		end
	end)
	APR.QList.QBuffFrame:SetScript("OnHide", function(self)
		if ( APR.QList.QBuffFrame.isMoving ) then
			APR.QList.QBuffFrame:StopMovingOrSizing();
			APR.QList.QBuffFrame.isMoving = false;
		end
	end)
	APR.QList.QBuffFrame.FS1 = APR.QList.QBuffFrame:CreateFontString("APR_QList_QBuffFrame_FS1","ARTWORK", "ChatFontNormal")
	APR.QList.QBuffFrame.FS1:SetParent(APR.QList.QBuffFrame)
	APR.QList.QBuffFrame.FS1:SetPoint("TOPLEFT",APR.QList.QBuffFrame,"TOPLEFT",5,0)
	APR.QList.QBuffFrame.FS1:SetWidth(300)
	APR.QList.QBuffFrame.FS1:SetHeight(38)
	APR.QList.QBuffFrame.FS1:SetJustifyH("LEFT")
	APR.QList.QBuffFrame.FS1:SetFontObject("GameFontNormal")
	APR.QList.QBuffFrame.FS1:SetText(L["NEDD_BUFF_DISARM_TRAP"])
	APR.QList.QBuffFrame.FS1:SetTextColor(1, 1, 0)

	APR.QList.QBuffFrame.Traps = CreateFrame("frame", "APR_SugQFrameFramebufffraTraps", APR.QList.QBuffFrame)
	APR.QList.QBuffFrame.Traps:SetWidth(220)
	APR.QList.QBuffFrame.Traps:SetHeight(18)
	APR.QList.QBuffFrame.Traps:SetMovable(true)
	APR.QList.QBuffFrame.Traps:EnableMouse(true)
	APR.QList.QBuffFrame.Traps:SetFrameStrata("LOW")
	APR.QList.QBuffFrame.Traps:SetPoint("TOPLEFT",APR.QList.QBuffFrame,"TOPLEFT",2,-40)
	local t = APR.QList.QBuffFrame.Traps:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\Buttons\\WHITE8X8")
	t:SetAllPoints(APR.QList.QBuffFrame.Traps)
	t:SetColorTexture(0.5,0.1,0.1,1)
	APR.QList.QBuffFrame.Traps.texture = t

	APR.QList.QBuffFrame.FS2 = APR.QList.QBuffFrame:CreateFontString("APR_QList_QBuffFrame_FS2","ARTWORK", "ChatFontNormal")
	APR.QList.QBuffFrame.FS2:SetParent(APR.QList.QBuffFrame.Traps)
	APR.QList.QBuffFrame.FS2:SetPoint("LEFT",APR.QList.QBuffFrame.Traps,"LEFT",5,0)
	APR.QList.QBuffFrame.FS2:SetWidth(300)
	APR.QList.QBuffFrame.FS2:SetHeight(38)
	APR.QList.QBuffFrame.FS2:SetJustifyH("LEFT")
	APR.QList.QBuffFrame.FS2:SetFontObject("GameFontNormalSmall")
	APR.QList.QBuffFrame.FS2:SetText(L["SOULWEB_TRAP"])
	APR.QList.QBuffFrame.FS2:SetTextColor(1, 1, 0)

	APR.QList.QBuffFrame.FS21 = APR.QList.QBuffFrame:CreateFontString("APR_QList_QBuffFrame_FS21","ARTWORK", "ChatFontNormal")
	APR.QList.QBuffFrame.FS21:SetParent(APR.QList.QBuffFrame.Traps)
	APR.QList.QBuffFrame.FS21:SetPoint("LEFT",APR.QList.QBuffFrame.Traps,"LEFT",85,0)
	APR.QList.QBuffFrame.FS21:SetWidth(300)
	APR.QList.QBuffFrame.FS21:SetHeight(38)
	APR.QList.QBuffFrame.FS21:SetJustifyH("LEFT")
	APR.QList.QBuffFrame.FS21:SetFontObject("GameFontNormalSmall")
	APR.QList.QBuffFrame.FS21:SetText(L["FRESHLEAF_BUFF"])
	APR.QList.QBuffFrame.FS21:SetTextColor(1, 1, 0)
	APR.QList.QBuffFrame.Traps2 = CreateFrame("frame", "APR_SugQFrameFramebufffraTraps2", APR.QList.QBuffFrame)
	APR.QList.QBuffFrame.Traps2:SetWidth(220)
	APR.QList.QBuffFrame.Traps2:SetHeight(18)
	APR.QList.QBuffFrame.Traps2:SetMovable(true)
	APR.QList.QBuffFrame.Traps2:EnableMouse(true)
	APR.QList.QBuffFrame.Traps2:SetPoint("TOPLEFT",APR.QList.QBuffFrame,"TOPLEFT",2,-60)
	local t = APR.QList.QBuffFrame.Traps2:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\Buttons\\WHITE8X8")
	t:SetAllPoints(APR.QList.QBuffFrame.Traps2)
	t:SetColorTexture(0.5,0.1,0.1,1)
	APR.QList.QBuffFrame.Traps2.texture = t
	APR.QList.QBuffFrame.FS3 = APR.QList.QBuffFrame:CreateFontString("APR_QList_QBuffFrame_FS3","ARTWORK", "ChatFontNormal")
	APR.QList.QBuffFrame.FS3:SetParent(APR.QList.QBuffFrame.Traps2)
	APR.QList.QBuffFrame.FS3:SetPoint("LEFT",APR.QList.QBuffFrame.Traps2,"LEFT",5,0)
	APR.QList.QBuffFrame.FS3:SetWidth(300)
	APR.QList.QBuffFrame.FS3:SetHeight(38)
	APR.QList.QBuffFrame.FS3:SetJustifyH("LEFT")
	APR.QList.QBuffFrame.FS3:SetFontObject("GameFontNormalSmall")
	APR.QList.QBuffFrame.FS3:SetText(L["HARP_TRAP"])
	APR.QList.QBuffFrame.FS3:SetTextColor(1, 1, 0)
	APR.QList.QBuffFrame.FS31 = APR.QList.QBuffFrame:CreateFontString("APR_QList_QBuffFrame_FS31","ARTWORK", "ChatFontNormal")
	APR.QList.QBuffFrame.FS31:SetParent(APR.QList.QBuffFrame.Traps2)
	APR.QList.QBuffFrame.FS31:SetPoint("LEFT",APR.QList.QBuffFrame.Traps2,"LEFT",85,0)
	APR.QList.QBuffFrame.FS31:SetWidth(300)
	APR.QList.QBuffFrame.FS31:SetHeight(38)
	APR.QList.QBuffFrame.FS31:SetJustifyH("LEFT")
	APR.QList.QBuffFrame.FS31:SetFontObject("GameFontNormalSmall")
	APR.QList.QBuffFrame.FS31:SetText(L["GOSSAMER_THREAD_BUFF"])
	APR.QList.QBuffFrame.FS31:SetTextColor(1, 1, 0)
	APR.QList.QBuffFrame.Traps3 = CreateFrame("frame", "APR_SugQFrameFramebufffraTraps3", APR.QList.QBuffFrame)
	APR.QList.QBuffFrame.Traps3:SetWidth(220)
	APR.QList.QBuffFrame.Traps3:SetHeight(18)
	APR.QList.QBuffFrame.Traps3:SetMovable(true)
	APR.QList.QBuffFrame.Traps3:EnableMouse(true)
	APR.QList.QBuffFrame.Traps3:SetPoint("TOPLEFT",APR.QList.QBuffFrame,"TOPLEFT",2,-80)
	local t = APR.QList.QBuffFrame.Traps3:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\Buttons\\WHITE8X8")
	t:SetAllPoints(APR.QList.QBuffFrame.Traps3)
	t:SetColorTexture(0.5,0.1,0.1,1)
	APR.QList.QBuffFrame.Traps3.texture = t
	APR.QList.QBuffFrame.FS4 = APR.QList.QBuffFrame:CreateFontString("APR_QList_QBuffFrame_FS4","ARTWORK", "ChatFontNormal")
	APR.QList.QBuffFrame.FS4:SetParent(APR.QList.QBuffFrame.Traps3)
	APR.QList.QBuffFrame.FS4:SetPoint("LEFT",APR.QList.QBuffFrame.Traps3,"LEFT",5,0)
	APR.QList.QBuffFrame.FS4:SetWidth(300)
	APR.QList.QBuffFrame.FS4:SetHeight(38)
	APR.QList.QBuffFrame.FS4:SetJustifyH("LEFT")
	APR.QList.QBuffFrame.FS4:SetFontObject("GameFontNormalSmall")
	APR.QList.QBuffFrame.FS4:SetText(L["BASKET_TRAP"])
	APR.QList.QBuffFrame.FS4:SetTextColor(1, 1, 0)
	APR.QList.QBuffFrame.FS41 = APR.QList.QBuffFrame:CreateFontString("APR_QList_QBuffFrame_FS41","ARTWORK", "ChatFontNormal")
	APR.QList.QBuffFrame.FS41:SetParent(APR.QList.QBuffFrame.Traps3)
	APR.QList.QBuffFrame.FS41:SetPoint("LEFT",APR.QList.QBuffFrame.Traps3,"LEFT",85,0)
	APR.QList.QBuffFrame.FS41:SetWidth(300)
	APR.QList.QBuffFrame.FS41:SetHeight(38)
	APR.QList.QBuffFrame.FS41:SetJustifyH("LEFT")
	APR.QList.QBuffFrame.FS41:SetFontObject("GameFontNormalSmall")
	APR.QList.QBuffFrame.FS41:SetText(L["SHUMMERDUST_BUFF"])
	APR.QList.QBuffFrame.FS41:SetTextColor(1, 1, 0)

end

APR.QListEventFrame = CreateFrame("Frame")
APR.QListEventFrame:RegisterEvent ("ADDON_LOADED")
APR.QListEventFrame:SetScript("OnEvent", function(self, event, ...)
	if (event=="ADDON_LOADED") then
		local arg1, arg2, arg3, arg4, arg5 = ...;
		if (arg1 == "APR-Core") then
			APR_CreateQList()
			APR.QListLoadin = 1
		end
	end
end)
