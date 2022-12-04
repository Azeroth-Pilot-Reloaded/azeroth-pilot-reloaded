local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("APR")

--Resets settings for APR
function APR.ResetSettings()
	APR1[APR.Realm][APR.Name]["Settings"] = {}
	APR1[APR.Realm][APR.Name]["Settings"]["left"] = 150
	APR1[APR.Realm][APR.Name]["Settings"]["top"] = -150
	APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = 150
	APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = -150
	APR1[APR.Realm][APR.Name]["Settings"]["Scale"] = UIParent:GetScale()
	APR1[APR.Realm][APR.Name]["Settings"]["Lock"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["Hide"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["alpha"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"] = 150
	APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"] = -150
	APR1[APR.Realm][APR.Name]["Settings"]["Hcampleft"] = 150
	APR1[APR.Realm][APR.Name]["Settings"]["Hcamptop"] = -150
	APR1[APR.Realm][APR.Name]["Settings"]["CutScene"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["ChooseQuests"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] = UIParent:GetScale()
	APR1[APR.Realm][APR.Name]["Settings"]["AutoHandInChoice"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["AutoVendor"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["AutoRepair"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["AutoGossip"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["BannerShow"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ShowBlobs"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"] = 2
	APR1[APR.Realm][APR.Name]["Settings"]["DisableHeirloomWarning"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["MiniMapBlobAlpha"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["OrderListScale"] = 1
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 0) then
		APR.OptionsFrame.ShowQListCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.ShowQListCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"] == 0) then
		APR.OptionsFrame.ShowGroupCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.ShowGroupCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoGossip"] == 0) then
		APR.OptionsFrame.AutoGossipCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoGossipCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoVendor"] == 0) then
		APR.OptionsFrame.AutoVendorCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoVendorCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoRepair"] == 0) then
		APR.OptionsFrame.AutoRepairCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoRepairCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["Lock"] == 0) then
		APR.OptionsFrame.LockQuestListCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.LockQuestListCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["CutScene"] == 0) then
		APR.OptionsFrame.CutSceneCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.CutSceneCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] == 0) then
		APR.OptionsFrame.AutoAcceptCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoAcceptCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] == 0) then
		APR.OptionsFrame.AutoHandInCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoHandInCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoHandInChoice"] == 0) then
		APR.OptionsFrame.AutoHandInChoiceCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoHandInChoiceCheckButton:SetChecked(true)
	end
	-- UI stuff regarding questlist and options frame
	APR.QuestList.ButtonParent:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["Scale"])
	APR.QuestList.ListFrame:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["Scale"])
	APR.QuestList21:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["Scale"])
	APR.OptionsFrame.QuestListScaleSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["Scale"] * 100)
	APR.OptionsFrame.ArrowScaleSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] * 100)

	APR.QuestList.MainFrame:ClearAllPoints()
	APR.QuestList.MainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
	APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"])
	APR.ArrowFrameM:ClearAllPoints()
	APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"], APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"])
	APR.ZoneQuestOrder:ClearAllPoints()
	APR.ZoneQuestOrder:SetPoint("CENTER", UIParent, "CENTER",1,1)
	APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] = UIParent:GetScale()
	APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"] = 2
	APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"] = GetScreenWidth() / 2.05
	APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"] = -(GetScreenHeight() / 1.5)
	APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"])
	APR.ArrowFrameM:ClearAllPoints()
	APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"], APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"])
	APR.OptionsFrame.ArrowFpsSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"])
	if (APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] == 0) then
		APR.OptionsFrame.LockArrowCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.LockArrowCheckButton:SetChecked(true)
	end
	APR.OptionsFrame.ArrowScaleSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] * 100)
end

APR.APR_panel = CreateFrame( "Frame", "CLPanelFrame", UIParent)
APR.APR_panel.name = "Azeroth Pilot Reloaded" -- Name of the wow ui panel in interface > options menu
InterfaceOptions_AddCategory(APR.APR_panel)
APR_panel = {}
APR_panel.title = CreateFrame("SimpleHTML",nil,APR.APR_panel)
APR_panel.title:SetWidth(500)
APR_panel.title:SetHeight(20)
APR_panel.title:SetPoint("TOPLEFT", APR.APR_panel, 0,-30)

APR_panel.title:SetText("Azeroth Pilot Reloaded - " .. APR.Version) -- Header text of the options menu

APR_panel.Button1 = CreateFrame("Button", "ZPButton2", APR.APR_panel)
APR_panel.Button1:SetPoint("TOPLEFT", APR.APR_panel, "TOPLEFT", 120, -100)
APR_panel.Button1:SetWidth(70)
APR_panel.Button1:SetHeight(30)
APR_panel.Button1:SetText(L["LOAD"])
APR_panel.Button1:SetNormalFontObject("GameFontNormal")
APR_panel.Button1ntex = APR_panel.Button1:CreateTexture()
APR_panel.Button1ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
APR_panel.Button1ntex:SetTexCoord(0, 0.625, 0, 0.6875)
APR_panel.Button1ntex:SetAllPoints()
--APR_panel.Button1:SetNormalTexture(APR_panel.Button1ntex)
APR_panel.Button1htex = APR_panel.Button1:CreateTexture()
APR_panel.Button1htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
APR_panel.Button1htex:SetTexCoord(0, 0.625, 0, 0.6875)
APR_panel.Button1htex:SetAllPoints()
APR_panel.Button1:SetHighlightTexture(APR_panel.Button1htex)
APR_panel.Button1ptex = APR_panel.Button1:CreateTexture()
APR_panel.Button1ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
APR_panel.Button1ptex:SetTexCoord(0, 0.625, 0, 0.6875)
APR_panel.Button1ptex:SetAllPoints()
APR_panel.Button1:SetPushedTexture(APR_panel.Button1ptex)
APR_panel.Button1:SetScript("OnClick", function(self, arg1)
	HideUIPanel(SettingsPanel)
	APR.OptionsFrame.MainFrame:Show()
end)
function APR.LoadOptionsFrame()
	APR.OptionsFrame = {}
	APR.OptionsFrame.MainFrame = CreateFrame("frame", "APR_OptionsMainFrame",  UIParent)
	APR.OptionsFrame.MainFrame:SetWidth(450)
	APR.OptionsFrame.MainFrame:SetHeight(360)
	APR.OptionsFrame.MainFrame:SetFrameStrata("MEDIUM")
	APR.OptionsFrame.MainFrame:SetPoint("CENTER",  UIParent, "CENTER",0,0)
	APR.OptionsFrame.MainFrame:SetMovable(true)
	APR.OptionsFrame.MainFrame:EnableMouse(true)

local t = APR.OptionsFrame.MainFrame:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.OptionsFrame.MainFrame)
APR.OptionsFrame.MainFrame.texture = t

	APR.OptionsFrame.MainFrame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StartMoving();
			APR.OptionsFrame.MainFrame.isMoving = true;
		end
	end)
	APR.OptionsFrame.MainFrame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame:SetScript("OnHide", function(self)
		if ( APR.OptionsFrame.MainFrame.isMoving ) then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame:Hide()

	APR.OptionsFrame.MainFrame.Options = CreateFrame("frame", "APR_OptionsMainFrame_1",  APR_OptionsMainFrame)
	APR.OptionsFrame.MainFrame.Options:SetWidth(150)
	APR.OptionsFrame.MainFrame.Options:SetHeight(320)
	APR.OptionsFrame.MainFrame.Options:SetFrameStrata("Low")
	APR.OptionsFrame.MainFrame.Options:SetPoint("LEFT",  APR_OptionsMainFrame, "LEFT",0,-20)
	APR.OptionsFrame.MainFrame.Options:SetMovable(true)
	APR.OptionsFrame.MainFrame.Options:EnableMouse(true)

local t = APR.OptionsFrame.MainFrame.Options:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.OptionsFrame.MainFrame.Options)
APR.OptionsFrame.MainFrame.Options.texture = t

	APR.OptionsFrame.MainFrame.Options:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StartMoving();
			APR.OptionsFrame.MainFrame.isMoving = true;
		end
	end)
	APR.OptionsFrame.MainFrame.Options:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.Options:SetScript("OnHide", function(self)
		if ( APR.OptionsFrame.MainFrame.isMoving ) then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.FontString1 = APR.OptionsFrame.MainFrame:CreateFontString("APRSettingsFS1","ARTWORK", "ChatFontNormal")
	APR.OptionsFrame.FontString1:SetParent(APR.OptionsFrame.MainFrame)
	APR.OptionsFrame.FontString1:SetPoint("TOP",APR.OptionsFrame.MainFrame,"TOP",0,0)
	APR.OptionsFrame.FontString1:SetText("Azeroth Pilot Reloaded - " .. APR.Version)
	APR.OptionsFrame.FontString1:SetWidth(APR.OptionsFrame.FontString1:GetStringWidth() * 1.5)
	APR.OptionsFrame.FontString1:SetHeight(20)
	APR.OptionsFrame.FontString1:SetFontObject("GameFontHighlightLarge")
	APR.OptionsFrame.FontString1:SetTextColor(1, 1, 0)
-------------------- Quest Options ----------------------------------------
	APR.OptionsFrame.MainFrame.OptionsB1 = CreateFrame("frame", "APR_OptionsMainFrame_QuestOptions",  APR_OptionsMainFrame)
	APR.OptionsFrame.MainFrame.OptionsB1:SetWidth(150)
	APR.OptionsFrame.MainFrame.OptionsB1:SetHeight(30)
	APR.OptionsFrame.MainFrame.OptionsB1:SetFrameStrata("HIGH")
	APR.OptionsFrame.MainFrame.OptionsB1:SetPoint("TOPLEFT",  APR_OptionsMainFrame, "TOPLEFT",0,-40)
	APR.OptionsFrame.MainFrame.OptionsB1:SetMovable(true)
	APR.OptionsFrame.MainFrame.OptionsB1:EnableMouse(true)
	--[[ From original author
		APR.OptionsFrame.MainFrame.OptionsB1:SetBackdrop( {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
		});
	]]
local t = APR.OptionsFrame.MainFrame.OptionsB1:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.OptionsFrame.MainFrame.OptionsB1)
APR.OptionsFrame.MainFrame.OptionsB1.texture = t

	APR.OptionsFrame.MainFrame.OptionsB1:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			APR.OptionsFrame.MainFrame.OptionsQuests:Show()
			APR.OptionsFrame.MainFrame.OptionsArrow:Hide()
			APR.OptionsFrame.MainFrame.OptionsGeneral:Hide()
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsB1:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsB1:SetScript("OnHide", function(self)
		if ( APR.OptionsFrame.MainFrame.isMoving ) then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsB1.FontString = APR.OptionsFrame.MainFrame:CreateFontString("APR_OptionsB1FS1","ARTWORK", "ChatFontNormal")
	APR.OptionsFrame.MainFrame.OptionsB1.FontString:SetParent(APR.OptionsFrame.MainFrame.OptionsB1)
	APR.OptionsFrame.MainFrame.OptionsB1.FontString:SetPoint("CENTER",APR.OptionsFrame.MainFrame.OptionsB1,"CENTER",0,0)
	APR.OptionsFrame.MainFrame.OptionsB1.FontString:SetWidth(240)
	APR.OptionsFrame.MainFrame.OptionsB1.FontString:SetHeight(20)
	APR.OptionsFrame.MainFrame.OptionsB1.FontString:SetFontObject("GameFontHighlightLarge")
	APR.OptionsFrame.MainFrame.OptionsB1.FontString:SetText(L["Q_OPTIONS"])
	APR.OptionsFrame.MainFrame.OptionsB1.FontString:SetTextColor(1, 1, 0)

	APR.OptionsFrame.MainFrame.OptionsQuests = CreateFrame("frame", "APR_OptionsMainFrame_Quests",  APR_OptionsMainFrame)
	APR.OptionsFrame.MainFrame.OptionsQuests:SetWidth(295)
	APR.OptionsFrame.MainFrame.OptionsQuests:SetHeight(320)
	APR.OptionsFrame.MainFrame.OptionsQuests:SetFrameStrata("MEDIUM")
	APR.OptionsFrame.MainFrame.OptionsQuests:SetPoint("LEFT",  APR_OptionsMainFrame, "LEFT",155,-20)
	APR.OptionsFrame.MainFrame.OptionsQuests:SetMovable(true)
	APR.OptionsFrame.MainFrame.OptionsQuests:EnableMouse(true)

local t = APR.OptionsFrame.MainFrame.OptionsQuests:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.OptionsFrame.MainFrame.OptionsQuests)
APR.OptionsFrame.MainFrame.OptionsQuests.texture = t

	APR.OptionsFrame.MainFrame.OptionsQuests:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StartMoving();
			APR.OptionsFrame.MainFrame.isMoving = true;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsQuests:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsQuests:SetScript("OnHide", function(self)
		if ( APR.OptionsFrame.MainFrame.isMoving ) then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsQuests:Hide()
		APR.OptionsFrame.AutoAcceptCheckButton = CreateFrame("CheckButton", "APR_AutoAcceptCheckButton", APR.OptionsFrame.MainFrame.OptionsQuests, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.AutoAcceptCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsQuests, "TOPLEFT", 10, -10)
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] == 0) then
		APR.OptionsFrame.AutoAcceptCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoAcceptCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.AutoAcceptCheckButton:GetName() .. 'Text'):SetText(": "..L["ACCEPT_Q"])
	getglobal(APR.OptionsFrame.AutoAcceptCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.AutoAcceptCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.AutoAcceptCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] = 0
		end
	end)
	APR.OptionsFrame.AutoHandInCheckButton = CreateFrame("CheckButton", "APR_AutoHandInCheckButton", APR.OptionsFrame.MainFrame.OptionsQuests, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.AutoHandInCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsQuests, "TOPLEFT", 10, -30)
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] == 0) then
		APR.OptionsFrame.AutoHandInCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoHandInCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.AutoHandInCheckButton:GetName() .. 'Text'):SetText(": "..L["TURN_IN_Q"])
	getglobal(APR.OptionsFrame.AutoHandInCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.AutoHandInCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.AutoHandInCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] = 0
		end
	end)
	APR.OptionsFrame.AutoHandInChoiceCheckButton = CreateFrame("CheckButton", "APR_AutoHandInChoiceCheckButton", APR.OptionsFrame.MainFrame.OptionsQuests, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.AutoHandInChoiceCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsQuests, "TOPLEFT", 10, -50)
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoHandInChoice"] == 0) then
		APR.OptionsFrame.AutoHandInChoiceCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoHandInChoiceCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.AutoHandInChoiceCheckButton:GetName() .. 'Text'):SetText(": "..L["AUTO_PICK_REWARD_ITEM"])
	getglobal(APR.OptionsFrame.AutoHandInChoiceCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.AutoHandInChoiceCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.AutoHandInChoiceCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["AutoHandInChoice"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["AutoHandInChoice"] = 0
		end
	end)
	APR.OptionsFrame.ShowQListCheckButton = CreateFrame("CheckButton", "APR_ShowQListCheckButton", APR.OptionsFrame.MainFrame.OptionsQuests, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.ShowQListCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsQuests, "TOPLEFT", 10, -70)
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 0) then
		APR.OptionsFrame.ShowQListCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.ShowQListCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.ShowQListCheckButton:GetName() .. 'Text'):SetText(": "..L["SHOW_QLIST"])
	getglobal(APR.OptionsFrame.ShowQListCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.ShowQListCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.ShowQListCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] = 1
			APR.BookingList["PrintQStep"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] = 0
			for CLi = 1, 10 do
				APR.QuestList.QuestFrames[CLi]:Hide()
				APR.QuestList.QuestFrames["FS"..CLi]["Button"]:Hide()
				APR.QuestList2["BF"..CLi]:Hide()
			end
			APR.BookingList["PrintQStep"] = 1
		end
	end)
	APR.OptionsFrame.LockQuestListCheckButton = CreateFrame("CheckButton", "APR_LockQuestListCheckButton", APR.OptionsFrame.MainFrame.OptionsQuests, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.LockQuestListCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsQuests, "TOPLEFT", 10, -90)
	if (APR1[APR.Realm][APR.Name]["Settings"]["Lock"] == 0) then
		APR.OptionsFrame.LockQuestListCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.LockQuestListCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.LockQuestListCheckButton:GetName() .. 'Text'):SetText(": "..L["LOCK_QLIST_WINDOW"])
	getglobal(APR.OptionsFrame.LockQuestListCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.LockQuestListCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.LockQuestListCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["Lock"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["Lock"] = 0
		end
	end)
	APR.OptionsFrame.QuestListScaleSlider = CreateFrame("Slider", "APR_QuestListScaleSlider",APR.OptionsFrame.MainFrame.OptionsQuests, "OptionsSliderTemplate")
	APR.OptionsFrame.QuestListScaleSlider:SetWidth(160)
	APR.OptionsFrame.QuestListScaleSlider:SetHeight(15)
	APR.OptionsFrame.QuestListScaleSlider:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsQuests, "TOPLEFT", 20, -120)
	APR.OptionsFrame.QuestListScaleSlider:SetOrientation("HORIZONTAL")
	APR.OptionsFrame.QuestListScaleSlider:SetMinMaxValues(1, 200)
	APR.OptionsFrame.QuestListScaleSlider.minValue, APR.OptionsFrame.QuestListScaleSlider.maxValue = APR.OptionsFrame.QuestListScaleSlider:GetMinMaxValues()
	getglobal(APR.OptionsFrame.QuestListScaleSlider:GetName() .. 'Low'):SetText("1%")
	getglobal(APR.OptionsFrame.QuestListScaleSlider:GetName() .. 'High'):SetText("200%")
	getglobal(APR.OptionsFrame.QuestListScaleSlider:GetName() .. 'Text'):SetText(L["QLIST_SCALE"]..":")
	APR.OptionsFrame.QuestListScaleSlider:SetValueStep(1)
	APR.OptionsFrame.QuestListScaleSlider:SetValue(100)
	APR.OptionsFrame.QuestListScaleSlider:SetScript("OnValueChanged", function(self,event)
		event = event - event%1
		APR1[APR.Realm][APR.Name]["Settings"]["Scale"] = event / 100
		APR.QuestList.ButtonParent:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["Scale"])
		APR.QuestList.ListFrame:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["Scale"])
		APR.QuestList21:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["Scale"])
	end)
	APR.OptionsFrame.QuestListScaleSlider:SetScript("OnMouseWheel", function(self,delta)
		if tonumber(self:GetValue()) == nil then return end
		self:SetValue(tonumber(self:GetValue())+delta)
	end)
	APR.OptionsFrame.QuestListScaleSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["Scale"] * 100)

	APR.OptionsFrame.QuestOrderListScaleSlider = CreateFrame("Slider", "APR_QuestOrderListScaleSlider",APR.OptionsFrame.MainFrame.OptionsQuests, "OptionsSliderTemplate")
	APR.OptionsFrame.QuestOrderListScaleSlider:SetWidth(160)
	APR.OptionsFrame.QuestOrderListScaleSlider:SetHeight(15)
	APR.OptionsFrame.QuestOrderListScaleSlider:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsQuests, "TOPLEFT", 20, -160)
	APR.OptionsFrame.QuestOrderListScaleSlider:SetOrientation("HORIZONTAL")
	APR.OptionsFrame.QuestOrderListScaleSlider:SetMinMaxValues(1, 200)
	APR.OptionsFrame.QuestOrderListScaleSlider.minValue, APR.OptionsFrame.QuestOrderListScaleSlider.maxValue = APR.OptionsFrame.QuestOrderListScaleSlider:GetMinMaxValues()
	getglobal(APR.OptionsFrame.QuestOrderListScaleSlider:GetName() .. 'Low'):SetText("1%")
	getglobal(APR.OptionsFrame.QuestOrderListScaleSlider:GetName() .. 'High'):SetText("200%")
	getglobal(APR.OptionsFrame.QuestOrderListScaleSlider:GetName() .. 'Text'):SetText(L["QORDERLIST_SCALE"]..":")
	APR.OptionsFrame.QuestOrderListScaleSlider:SetValueStep(1)
	APR.OptionsFrame.QuestOrderListScaleSlider:SetValue(100)
	APR.OptionsFrame.QuestOrderListScaleSlider:SetScript("OnValueChanged", function(self,event)
		event = event - event%1
		APR1[APR.Realm][APR.Name]["Settings"]["OrderListScale"] = event / 100
		APR.ZoneQuestOrder:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["OrderListScale"])
	end)
	APR.OptionsFrame.QuestOrderListScaleSlider:SetScript("OnMouseWheel", function(self,delta)
		if tonumber(self:GetValue()) == nil then return end
		self:SetValue(tonumber(self:GetValue())+delta)
	end)
	APR.OptionsFrame.QuestOrderListScaleSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["OrderListScale"] * 100)

	APR.OptionsFrame.QorderListzCheckButton = CreateFrame("CheckButton", "APR_QorderListzCheckButton", APR.OptionsFrame.MainFrame.OptionsQuests, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.QorderListzCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsQuests, "TOPLEFT", 10, -185)
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQuestListOrder"] == 0) then
		APR.OptionsFrame.QorderListzCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.QorderListzCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.QorderListzCheckButton:GetName() .. 'Text'):SetText(L["SHOW_QORDERLIST"])
	getglobal(APR.OptionsFrame.QorderListzCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.QorderListzCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.QorderListzCheckButton:GetChecked() == true) then
			APR.UpdateZoneQuestOrderList("LoadIn")
			APR1[APR.Realm][APR.Name]["Settings"]["ShowQuestListOrder"] = 1
			APR.ZoneQuestOrder:Show()
		else
			APR1[APR.Realm][APR.Name]["Settings"]["ShowQuestListOrder"] = 0
			APR.ZoneQuestOrder:Hide()
		end
	end)

	APR.OptionsFrame["ResetQorderL"] = CreateFrame("Button", "APR_OptionsButtons3", APR.OptionsFrame.MainFrame.OptionsQuests, "SecureActionButtonTemplate")
	APR.OptionsFrame["ResetQorderL"]:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsQuests, "TOPLEFT", 10, -210)
	APR.OptionsFrame["ResetQorderL"]:SetWidth(150)
	APR.OptionsFrame["ResetQorderL"]:SetHeight(30)
	APR.OptionsFrame["ResetQorderL"]:SetText(L["RESET_QORDERLIST"])
	APR.OptionsFrame["ResetQorderL"]:SetParent(APR.OptionsFrame.MainFrame.OptionsQuests)
	APR.OptionsFrame.ResetQorderL:SetFrameStrata("HIGH")
	APR.OptionsFrame.ResetQorderL:SetNormalFontObject("GameFontNormal")
	APR.OptionsFrame.ResetQorderLntex = APR.OptionsFrame.ResetQorderL:CreateTexture()
	APR.OptionsFrame.ResetQorderLntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	APR.OptionsFrame.ResetQorderLntex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.ResetQorderLntex:SetAllPoints()
--	APR.OptionsFrame.ResetQorderL:SetNormalTexture(APR.OptionsFrame.ResetQorderLntex)
	APR.OptionsFrame.ResetQorderLhtex = APR.OptionsFrame.ResetQorderL:CreateTexture()
	APR.OptionsFrame.ResetQorderLhtex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.OptionsFrame.ResetQorderLhtex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.ResetQorderLhtex:SetAllPoints()
	APR.OptionsFrame.ResetQorderL:SetHighlightTexture(APR.OptionsFrame.ResetQorderLhtex)
	APR.OptionsFrame.ResetQorderLptex = APR.OptionsFrame.ResetQorderL:CreateTexture()
	APR.OptionsFrame.ResetQorderLptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	APR.OptionsFrame.ResetQorderLptex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.ResetQorderLptex:SetAllPoints()
	APR.OptionsFrame.ResetQorderL:SetPushedTexture(APR.OptionsFrame.ResetQorderLptex)
	APR.OptionsFrame["ResetQorderL"]:SetScript("OnClick", function(self, arg1)
		APR.ZoneQuestOrder:ClearAllPoints()
		APR.ZoneQuestOrder:SetPoint("CENTER", UIParent, "CENTER",1,1)
	end)

----------------- Arrow Options --------------------------------------------------------------------------------------------
	APR.OptionsFrame.MainFrame.OptionsB2 = CreateFrame("frame", "APR_OptionsMainFrame_ArrowOptions",  APR_OptionsMainFrame)
	APR.OptionsFrame.MainFrame.OptionsB2:SetWidth(150)
	APR.OptionsFrame.MainFrame.OptionsB2:SetHeight(30)
	APR.OptionsFrame.MainFrame.OptionsB2:SetFrameStrata("HIGH")
	APR.OptionsFrame.MainFrame.OptionsB2:SetPoint("TOPLEFT",  APR_OptionsMainFrame, "TOPLEFT",0,-70)
	APR.OptionsFrame.MainFrame.OptionsB2:SetMovable(true)
	APR.OptionsFrame.MainFrame.OptionsB2:EnableMouse(true)

local t = APR.OptionsFrame.MainFrame.OptionsB2:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.OptionsFrame.MainFrame.OptionsB2)
APR.OptionsFrame.MainFrame.OptionsB2.texture = t

	APR.OptionsFrame.MainFrame.OptionsB2:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			APR.OptionsFrame.MainFrame.OptionsQuests:Hide()
			APR.OptionsFrame.MainFrame.OptionsArrow:Show()
			APR.OptionsFrame.MainFrame.OptionsGeneral:Hide()
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsB2:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsB2:SetScript("OnHide", function(self)
		if ( APR.OptionsFrame.MainFrame.isMoving ) then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsB2.FontString = APR.OptionsFrame.MainFrame:CreateFontString("APR_OptionsB2FS1","ARTWORK", "ChatFontNormal")
	APR.OptionsFrame.MainFrame.OptionsB2.FontString:SetParent(APR.OptionsFrame.MainFrame.OptionsB2)
	APR.OptionsFrame.MainFrame.OptionsB2.FontString:SetPoint("CENTER",APR.OptionsFrame.MainFrame.OptionsB2,"CENTER",0,0)
	APR.OptionsFrame.MainFrame.OptionsB2.FontString:SetWidth(240)
	APR.OptionsFrame.MainFrame.OptionsB2.FontString:SetHeight(20)
	APR.OptionsFrame.MainFrame.OptionsB2.FontString:SetFontObject("GameFontHighlightLarge")
	APR.OptionsFrame.MainFrame.OptionsB2.FontString:SetText(L["ARROW_OPTION"])
	APR.OptionsFrame.MainFrame.OptionsB2.FontString:SetTextColor(1, 1, 0)

	APR.OptionsFrame.MainFrame.OptionsArrow = CreateFrame("frame", "APR_OptionsMainFrame_Arrow",  APR_OptionsMainFrame)
	APR.OptionsFrame.MainFrame.OptionsArrow:SetWidth(295)
	APR.OptionsFrame.MainFrame.OptionsArrow:SetHeight(320)
	APR.OptionsFrame.MainFrame.OptionsArrow:SetFrameStrata("MEDIUM")
	APR.OptionsFrame.MainFrame.OptionsArrow:SetPoint("LEFT",  APR_OptionsMainFrame, "LEFT",155,-20)
	APR.OptionsFrame.MainFrame.OptionsArrow:SetMovable(true)
	APR.OptionsFrame.MainFrame.OptionsArrow:EnableMouse(true)

local t = APR.OptionsFrame.MainFrame.OptionsArrow:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.OptionsFrame.MainFrame.OptionsArrow)
APR.OptionsFrame.MainFrame.OptionsArrow.texture = t

	APR.OptionsFrame.MainFrame.OptionsArrow:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StartMoving();
			APR.OptionsFrame.MainFrame.isMoving = true;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsArrow:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsArrow:SetScript("OnHide", function(self)
		if ( APR.OptionsFrame.MainFrame.isMoving ) then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsArrow:Hide()
	APR.OptionsFrame.LockArrowCheckButton = CreateFrame("CheckButton", "APR_LockArrowCheckButton", APR.OptionsFrame.MainFrame.OptionsArrow, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.LockArrowCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsArrow, "TOPLEFT", 10, -10)
	if (APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] == 0) then
		APR.OptionsFrame.LockArrowCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.LockArrowCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.LockArrowCheckButton:GetName() .. 'Text'):SetText(": "..L["LOCK_ARROW_WINDOW"])
	getglobal(APR.OptionsFrame.LockArrowCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.LockArrowCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.LockArrowCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] = 0
		end
	end)
	APR.OptionsFrame.ShowArrowCheckButton = CreateFrame("CheckButton", "APR_ShowArrowCheckButton", APR.OptionsFrame.MainFrame.OptionsArrow, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.ShowArrowCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsArrow, "TOPLEFT", 10, -30)
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowArrow"] == 0) then
		APR.OptionsFrame.ShowArrowCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.ShowArrowCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.ShowArrowCheckButton:GetName() .. 'Text'):SetText(": "..L["SHOW_ARROW"])
	getglobal(APR.OptionsFrame.ShowArrowCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.ShowArrowCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.ShowArrowCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["ShowArrow"] = 1
			APR.ArrowActive = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["ShowArrow"] = 0
		end
	end)
	APR.OptionsFrame.ArrowScaleSlider = CreateFrame("Slider", "APR_ArrowScaleSlider",APR.OptionsFrame.MainFrame.OptionsArrow, "OptionsSliderTemplate")
	APR.OptionsFrame.ArrowScaleSlider:SetWidth(160)
	APR.OptionsFrame.ArrowScaleSlider:SetHeight(15)
	APR.OptionsFrame.ArrowScaleSlider:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsArrow, "TOPLEFT", 20, -70)
	APR.OptionsFrame.ArrowScaleSlider:SetOrientation("HORIZONTAL")
	APR.OptionsFrame.ArrowScaleSlider:SetMinMaxValues(1, 200)
	APR.OptionsFrame.ArrowScaleSlider.minValue, APR.OptionsFrame.ArrowScaleSlider.maxValue = APR.OptionsFrame.ArrowScaleSlider:GetMinMaxValues()
	getglobal(APR.OptionsFrame.ArrowScaleSlider:GetName() .. 'Low'):SetText("1%")
	getglobal(APR.OptionsFrame.ArrowScaleSlider:GetName() .. 'High'):SetText("200%")
	getglobal(APR.OptionsFrame.ArrowScaleSlider:GetName() .. 'Text'):SetText(L["ARROW_SCALE"]..":")
	APR.OptionsFrame.ArrowScaleSlider:SetValueStep(1)
	APR.OptionsFrame.ArrowScaleSlider:SetValue(100)
	APR.OptionsFrame.ArrowScaleSlider:SetScript("OnValueChanged", function(self,event)
		event = event - event%1
		APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] = event / 100
		APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"])

	end)
	APR.OptionsFrame.ArrowScaleSlider:SetScript("OnMouseWheel", function(self,delta)
		if tonumber(self:GetValue()) == nil then return end
		self:SetValue(tonumber(self:GetValue())+delta)
	end)
	APR.OptionsFrame.ArrowScaleSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] * 100)

	APR.OptionsFrame.ArrowFpsSlider = CreateFrame("Slider", "APR_ArrowFpsSlider",APR.OptionsFrame.MainFrame.OptionsArrow, "OptionsSliderTemplate")
	APR.OptionsFrame.ArrowFpsSlider:SetWidth(160)
	APR.OptionsFrame.ArrowFpsSlider:SetHeight(15)
	APR.OptionsFrame.ArrowFpsSlider:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsArrow, "TOPLEFT", 20, -110)
	APR.OptionsFrame.ArrowFpsSlider:SetOrientation("HORIZONTAL")
	APR.OptionsFrame.ArrowFpsSlider:SetMinMaxValues(1, 5)
	APR.OptionsFrame.ArrowFpsSlider.minValue, APR.OptionsFrame.ArrowFpsSlider.maxValue = APR.OptionsFrame.ArrowFpsSlider:GetMinMaxValues()
	getglobal(APR.OptionsFrame.ArrowFpsSlider:GetName() .. 'Low'):SetText("1")
	getglobal(APR.OptionsFrame.ArrowFpsSlider:GetName() .. 'High'):SetText("5")
	getglobal(APR.OptionsFrame.ArrowFpsSlider:GetName() .. 'Text'):SetText(L["UPDATE_ARROW"].." "..APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"].." FPS:")
	APR.OptionsFrame.ArrowFpsSlider:SetValueStep(1)
	APR.OptionsFrame.ArrowFpsSlider:SetValue(2)
	APR.OptionsFrame.ArrowFpsSlider:SetScript("OnValueChanged", function(self,event)
		event = event - event%1
		APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"] = floor(event)
		getglobal(APR.OptionsFrame.ArrowFpsSlider:GetName() .. 'Text'):SetText(L["UPDATE_ARROW"].." "..APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"].." FPS:")
	end)
	APR.OptionsFrame.ArrowFpsSlider:SetScript("OnMouseWheel", function(self,delta)
		if tonumber(self:GetValue()) == nil then return end
		self:SetValue(tonumber(self:GetValue())+delta)
	end)
	APR.OptionsFrame.ArrowFpsSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"])

	APR.OptionsFrame["ResetARrow"] = CreateFrame("Button", "APR_OptionsButtons3", APR.OptionsFrame.MainFrame.OptionsArrow, "SecureActionButtonTemplate")
	APR.OptionsFrame["ResetARrow"]:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsArrow, "TOPLEFT", 20, -140)
	APR.OptionsFrame["ResetARrow"]:SetWidth(90)
	APR.OptionsFrame["ResetARrow"]:SetHeight(30)
	APR.OptionsFrame["ResetARrow"]:SetText(L["RESET_ARROW"])
	APR.OptionsFrame["ResetARrow"]:SetParent(APR.OptionsFrame.MainFrame.OptionsArrow)
	APR.OptionsFrame.ResetARrow:SetFrameStrata("HIGH")
	APR.OptionsFrame.ResetARrow:SetNormalFontObject("GameFontNormal")
	APR.OptionsFrame.ResetARrowntex = APR.OptionsFrame.ResetARrow:CreateTexture()
	APR.OptionsFrame.ResetARrowntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	APR.OptionsFrame.ResetARrowntex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.ResetARrowntex:SetAllPoints()
--	APR.OptionsFrame.ResetARrow:SetNormalTexture(APR.OptionsFrame.ResetARrowntex)
	APR.OptionsFrame.ResetARrowhtex = APR.OptionsFrame.ResetARrow:CreateTexture()
	APR.OptionsFrame.ResetARrowhtex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.OptionsFrame.ResetARrowhtex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.ResetARrowhtex:SetAllPoints()
	APR.OptionsFrame.ResetARrow:SetHighlightTexture(APR.OptionsFrame.ResetARrowhtex)
	APR.OptionsFrame.ResetARrowptex = APR.OptionsFrame.ResetARrow:CreateTexture()
	APR.OptionsFrame.ResetARrowptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	APR.OptionsFrame.ResetARrowptex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.ResetARrowptex:SetAllPoints()
	APR.OptionsFrame.ResetARrow:SetPushedTexture(APR.OptionsFrame.ResetARrowptex)
	APR.OptionsFrame["ResetARrow"]:SetScript("OnClick", function(self, arg1)
		APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] = UIParent:GetScale()
		APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] = 0
		APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"] = 2
		APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"] = GetScreenWidth() / 2.05
		APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"] = -(GetScreenHeight() / 1.5)
		APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"])
		APR.ArrowFrameM:ClearAllPoints()
		APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"], APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"])
		APR.OptionsFrame.ArrowFpsSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"])
		if (APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] == 0) then
			APR.OptionsFrame.LockArrowCheckButton:SetChecked(false)
		else
			APR.OptionsFrame.LockArrowCheckButton:SetChecked(true)
		end
		APR.OptionsFrame.ArrowScaleSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] * 100)
	end)

------------------------- General Options --------------------------------------------------------------------------
	APR.OptionsFrame.MainFrame.OptionsB3 = CreateFrame("frame", "APR_OptionsMainFrame_GeneralOptions",  APR_OptionsMainFrame)
	APR.OptionsFrame.MainFrame.OptionsB3:SetWidth(150)
	APR.OptionsFrame.MainFrame.OptionsB3:SetHeight(30)
	APR.OptionsFrame.MainFrame.OptionsB3:SetFrameStrata("HIGH")
	APR.OptionsFrame.MainFrame.OptionsB3:SetPoint("TOPLEFT",  APR_OptionsMainFrame, "TOPLEFT",0,-100)
	APR.OptionsFrame.MainFrame.OptionsB3:SetMovable(true)
	APR.OptionsFrame.MainFrame.OptionsB3:EnableMouse(true)
	local t = APR.OptionsFrame.MainFrame.OptionsB3:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.OptionsFrame.MainFrame.OptionsB3)
APR.OptionsFrame.MainFrame.OptionsB3.texture = t

	APR.OptionsFrame.MainFrame.OptionsB3:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			APR.OptionsFrame.MainFrame.OptionsQuests:Hide()
			APR.OptionsFrame.MainFrame.OptionsArrow:Hide()
			APR.OptionsFrame.MainFrame.OptionsGeneral:Show()
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsB3:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsB3:SetScript("OnHide", function(self)
		if ( APR.OptionsFrame.MainFrame.isMoving ) then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsB3.FontString = APR.OptionsFrame.MainFrame:CreateFontString("APR_OptionsB3FS1","ARTWORK", "ChatFontNormal")
	APR.OptionsFrame.MainFrame.OptionsB3.FontString:SetParent(APR.OptionsFrame.MainFrame.OptionsB3)
	APR.OptionsFrame.MainFrame.OptionsB3.FontString:SetPoint("CENTER",APR.OptionsFrame.MainFrame.OptionsB3,"CENTER",0,0)
	APR.OptionsFrame.MainFrame.OptionsB3.FontString:SetWidth(240)
	APR.OptionsFrame.MainFrame.OptionsB3.FontString:SetHeight(20)
	APR.OptionsFrame.MainFrame.OptionsB3.FontString:SetFontObject("GameFontHighlightLarge")
	APR.OptionsFrame.MainFrame.OptionsB3.FontString:SetText(L["GENERAL_OPTION"])
	APR.OptionsFrame.MainFrame.OptionsB3.FontString:SetTextColor(1, 1, 0)

	APR.OptionsFrame.MainFrame.OptionsGeneral = CreateFrame("frame", "APR_OptionsMainFrame_General",  APR_OptionsMainFrame)
	APR.OptionsFrame.MainFrame.OptionsGeneral:SetWidth(295)
	APR.OptionsFrame.MainFrame.OptionsGeneral:SetHeight(320)
	APR.OptionsFrame.MainFrame.OptionsGeneral:SetFrameStrata("MEDIUM")
	APR.OptionsFrame.MainFrame.OptionsGeneral:SetPoint("LEFT",  APR_OptionsMainFrame, "LEFT",155,-20)
	APR.OptionsFrame.MainFrame.OptionsGeneral:SetMovable(true)
	APR.OptionsFrame.MainFrame.OptionsGeneral:EnableMouse(true)

local t = APR.OptionsFrame.MainFrame.OptionsGeneral:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.OptionsFrame.MainFrame.OptionsGeneral)
APR.OptionsFrame.MainFrame.OptionsGeneral.texture = t

	APR.OptionsFrame.MainFrame.OptionsGeneral:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StartMoving();
			APR.OptionsFrame.MainFrame.isMoving = true;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsGeneral:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.OptionsFrame.MainFrame.isMoving then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsGeneral:SetScript("OnHide", function(self)
		if ( APR.OptionsFrame.MainFrame.isMoving ) then
			APR.OptionsFrame.MainFrame:StopMovingOrSizing();
			APR.OptionsFrame.MainFrame.isMoving = false;
		end
	end)
	APR.OptionsFrame.MainFrame.OptionsGeneral:Hide()
	APR.OptionsFrame.CutSceneCheckButton = CreateFrame("CheckButton", "APR_CutSceneCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.CutSceneCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -10)
	if (APR1[APR.Realm][APR.Name]["Settings"]["CutScene"] == 0) then
		APR.OptionsFrame.CutSceneCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.CutSceneCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.CutSceneCheckButton:GetName() .. 'Text'):SetText(": "..L["SKIPPED_CUTSCENE"])
	getglobal(APR.OptionsFrame.CutSceneCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.CutSceneCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.CutSceneCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["CutScene"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["CutScene"] = 0
		end
	end)
	APR.OptionsFrame.AutoVendorCheckButton = CreateFrame("CheckButton", "APR_AutoVendorCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.AutoVendorCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -30)
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoVendor"] == 0) then
		APR.OptionsFrame.AutoVendorCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoVendorCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.AutoVendorCheckButton:GetName() .. 'Text'):SetText(": "..L["AUTO_VENDOR"])
	getglobal(APR.OptionsFrame.AutoVendorCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.AutoVendorCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.AutoVendorCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["AutoVendor"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["AutoVendor"] = 0
		end
	end)
	APR.OptionsFrame.AutoRepairCheckButton = CreateFrame("CheckButton", "APR_AutoRepairCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.AutoRepairCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -50)
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoRepair"] == 0) then
		APR.OptionsFrame.AutoRepairCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoRepairCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.AutoRepairCheckButton:GetName() .. 'Text'):SetText(": "..L["AUTO_REPAIR"])
	getglobal(APR.OptionsFrame.AutoRepairCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.AutoRepairCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.AutoRepairCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["AutoRepair"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["AutoRepair"] = 0
		end
	end)
	APR.OptionsFrame.ShowGroupCheckButton = CreateFrame("CheckButton", "APR_ShowGroupCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.ShowGroupCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -70)
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"] == 0) then
		APR.OptionsFrame.ShowGroupCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.ShowGroupCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.ShowGroupCheckButton:GetName() .. 'Text'):SetText(": "..L["SHOW_GROUP_PROGRESS"])
	getglobal(APR.OptionsFrame.ShowGroupCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.ShowGroupCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.ShowGroupCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"] = 0
			for CLi = 1, 5 do
				APR.PartyList.PartyFrames[CLi]:Hide()
				APR.PartyList.PartyFrames2[CLi]:Hide()
			end
		end
	end)
	APR.OptionsFrame.AutoGossipCheckButton = CreateFrame("CheckButton", "APR_AutoGossipCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.AutoGossipCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -90)
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoGossip"] == 0) then
		APR.OptionsFrame.AutoGossipCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoGossipCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.AutoGossipCheckButton:GetName() .. 'Text'):SetText(": "..L["AUTO_SELECTION_OF_DIALOG"])
	getglobal(APR.OptionsFrame.AutoGossipCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.AutoGossipCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.AutoGossipCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["AutoGossip"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["AutoGossip"] = 0
		end
	end)

	APR.OptionsFrame.AutoFlightCheckButton = CreateFrame("CheckButton", "APR_AutoFlightCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.AutoFlightCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -110)
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoFlight"] == 0) then
		APR.OptionsFrame.AutoFlightCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoFlightCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.AutoFlightCheckButton:GetName() .. 'Text'):SetText(": Auto Use Flightpaths")
	getglobal(APR.OptionsFrame.AutoFlightCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.AutoFlightCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.AutoFlightCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["AutoFlight"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["AutoFlight"] = 0
		end
	end)

	APR.OptionsFrame.BlobsShowCheckButton = CreateFrame("CheckButton", "APR_BlobsShowCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.BlobsShowCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -170)
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowBlobs"] == 0) then
		APR.OptionsFrame.BlobsShowCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.BlobsShowCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.BlobsShowCheckButton:GetName() .. 'Text'):SetText(": "..L["SHOW_BLOBS_ON_MINIMAP"])
	getglobal(APR.OptionsFrame.BlobsShowCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.BlobsShowCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.BlobsShowCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["ShowBlobs"] = 1
			APR.OptionsFrame.MiniMapBlobAlphaSlider:Show()
		else
			APR1[APR.Realm][APR.Name]["Settings"]["ShowBlobs"] = 0
			APR.RemoveIcons()
			APR.OptionsFrame.MiniMapBlobAlphaSlider:Hide()
		end
	end)

	APR.OptionsFrame.MiniMapBlobAlphaSlider = CreateFrame("Slider", "APR_MiniMapBlobAlphaSlider",APR.OptionsFrame.MainFrame.OptionsGeneral, "OptionsSliderTemplate")
	APR.OptionsFrame.MiniMapBlobAlphaSlider:SetWidth(160)
	APR.OptionsFrame.MiniMapBlobAlphaSlider:SetHeight(15)
	APR.OptionsFrame.MiniMapBlobAlphaSlider:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 50, -205)
	APR.OptionsFrame.MiniMapBlobAlphaSlider:SetOrientation("HORIZONTAL")
	APR.OptionsFrame.MiniMapBlobAlphaSlider:SetMinMaxValues(1, 100)
	APR.OptionsFrame.MiniMapBlobAlphaSlider.minValue, APR.OptionsFrame.MiniMapBlobAlphaSlider.maxValue = APR.OptionsFrame.MiniMapBlobAlphaSlider:GetMinMaxValues()
	getglobal(APR.OptionsFrame.MiniMapBlobAlphaSlider:GetName() .. 'Low'):SetText("1%")
	getglobal(APR.OptionsFrame.MiniMapBlobAlphaSlider:GetName() .. 'High'):SetText("100%")
	getglobal(APR.OptionsFrame.MiniMapBlobAlphaSlider:GetName() .. 'Text'):SetText(L["MINIMAP_BLOB_ALPHA"])
	APR.OptionsFrame.MiniMapBlobAlphaSlider:SetValueStep(1)
	APR.OptionsFrame.MiniMapBlobAlphaSlider:SetValue(100)
	APR.OptionsFrame.MiniMapBlobAlphaSlider:SetScript("OnValueChanged", function(self,event)
		event = event - event%1
		APR1[APR.Realm][APR.Name]["Settings"]["MiniMapBlobAlpha"] = event / 100
		local CLi
		for CLi = 1, 20 do
			APR["Icons"][CLi].texture:SetAlpha(APR1[APR.Realm][APR.Name]["Settings"]["MiniMapBlobAlpha"])
		end
	end)
	APR.OptionsFrame.MiniMapBlobAlphaSlider:SetScript("OnMouseWheel", function(self,delta)
		if tonumber(self:GetValue()) == nil then return end
		self:SetValue(tonumber(self:GetValue())+delta)
	end)
	APR.OptionsFrame.MiniMapBlobAlphaSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["MiniMapBlobAlpha"] * 100)
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowBlobs"] == 0) then
		APR.OptionsFrame.MiniMapBlobAlphaSlider:Hide()
	end

	APR.OptionsFrame.MapBlobsShowCheckButton = CreateFrame("CheckButton", "APR_MapBlobsShowCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.MapBlobsShowCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -225)
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowMapBlobs"] == 0) then
		APR.OptionsFrame.MapBlobsShowCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.MapBlobsShowCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.MapBlobsShowCheckButton:GetName() .. 'Text'):SetText(": "..L["SHOW_BLOBS_ON_MAP"])
	getglobal(APR.OptionsFrame.MapBlobsShowCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.MapBlobsShowCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.MapBlobsShowCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["ShowMapBlobs"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["ShowMapBlobs"] = 0
			APR:MoveMapIcons()
		end
	end)

	APR.OptionsFrame.ShowMap10sCheckButton = CreateFrame("CheckButton", "APR_ShowMap10sCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.ShowMap10sCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -245)
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowMap10s"] == 0) then
		APR.OptionsFrame.ShowMap10sCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.ShowMap10sCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.ShowMap10sCheckButton:GetName() .. 'Text'):SetText(L["SHOW_STEPS_MAP"])
	getglobal(APR.OptionsFrame.ShowMap10sCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.ShowMap10sCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.ShowMap10sCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["ShowMap10s"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["ShowMap10s"] = 0
			APR.HBDP:RemoveAllWorldMapIcons("APRMapOrder")
		end
	end)

	APR.OptionsFrame.DisableHeirloomWarningCheckButton = CreateFrame("CheckButton", "APR_DisableHeirloomWarningCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.DisableHeirloomWarningCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -265)
	if (APR1[APR.Realm][APR.Name]["Settings"]["DisableHeirloomWarning"] == 0) then
		APR.OptionsFrame.DisableHeirloomWarningCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.DisableHeirloomWarningCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.DisableHeirloomWarningCheckButton:GetName() .. 'Text'):SetText(L["DISABLE_HEIRLOOM_WARNING"])
	getglobal(APR.OptionsFrame.DisableHeirloomWarningCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.DisableHeirloomWarningCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.DisableHeirloomWarningCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["DisableHeirloomWarning"] = 1
			APR.BookingList["PrintQStep"] = 1
		else
			APR1[APR.Realm][APR.Name]["Settings"]["DisableHeirloomWarning"] = 0
			APR.BookingList["PrintQStep"] = 1
		end
	end)

	APR.OptionsFrame.QuestButtonsCheckButton = CreateFrame("CheckButton", "APR_QuestButtonsCheckButton", APR.OptionsFrame.MainFrame.OptionsGeneral, "ChatConfigCheckButtonTemplate");
	APR.OptionsFrame.QuestButtonsCheckButton:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 10, -200)
	if (APR1[APR.Realm][APR.Name]["Settings"]["QuestButtonDetatch"] == 0) then
		APR.OptionsFrame.QuestButtonsCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.QuestButtonsCheckButton:SetChecked(true)
	end
	getglobal(APR.OptionsFrame.QuestButtonsCheckButton:GetName() .. 'Text'):SetText(L["DETACH_Q_ITEM_BTN"])
	getglobal(APR.OptionsFrame.QuestButtonsCheckButton:GetName() .. 'Text'):SetTextColor(1, 1, 1)
	APR.OptionsFrame.QuestButtonsCheckButton:SetScript("OnClick", function()
		if (APR.OptionsFrame.QuestButtonsCheckButton:GetChecked() == true) then
			APR1[APR.Realm][APR.Name]["Settings"]["QuestButtonDetatch"] = 1
			APR.OptionsFrame.QuestButtonsSlider:Show()
		else
			APR1[APR.Realm][APR.Name]["Settings"]["QuestButtonDetatch"] = 0
			local Topz = APR1[APR.Realm][APR.Name]["Settings"]["left"]
			local Topz2 = APR1[APR.Realm][APR.Name]["Settings"]["top"]
			APR.QuestList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT", Topz, Topz2)
			for CLi = 1, 3 do
				APR1[APR.Realm][APR.Name]["Settings"]["QuestButtons"] = 1
				APR.QuestList2["BF"..CLi]:SetPoint("BOTTOMLEFT", APR.QuestList21, "BOTTOMLEFT",0,-((CLi * 38)+CLi))
				APR.QuestList2["BF"..CLi]["APR_Button"]:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["QuestButtons"])
				APR.OptionsFrame.QuestButtonsSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["QuestButtons"] * 100)
			end
			APR.OptionsFrame.QuestButtonsSlider:Hide()
		end
	end)

	APR.OptionsFrame.QuestButtonsCheckButton:Hide()

	APR.OptionsFrame.QuestButtonsSlider = CreateFrame("Slider", "APR_QuestButtonsSlider",APR.OptionsFrame.MainFrame.OptionsGeneral, "OptionsSliderTemplate")
	APR.OptionsFrame.QuestButtonsSlider:SetWidth(160)
	APR.OptionsFrame.QuestButtonsSlider:SetHeight(15)
	APR.OptionsFrame.QuestButtonsSlider:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame.OptionsGeneral, "TOPLEFT", 20, -240)
	APR.OptionsFrame.QuestButtonsSlider:SetOrientation("HORIZONTAL")
	APR.OptionsFrame.QuestButtonsSlider:SetMinMaxValues(1, 200)
	APR.OptionsFrame.QuestButtonsSlider.minValue, APR.OptionsFrame.QuestButtonsSlider.maxValue = APR.OptionsFrame.QuestButtonsSlider:GetMinMaxValues()
	getglobal(APR.OptionsFrame.QuestButtonsSlider:GetName() .. 'Low'):SetText("1%")
	getglobal(APR.OptionsFrame.QuestButtonsSlider:GetName() .. 'High'):SetText("200%")
	getglobal(APR.OptionsFrame.QuestButtonsSlider:GetName() .. 'Text'):SetText(L["Q_BTN_SCALE"])
	APR.OptionsFrame.QuestButtonsSlider:SetValueStep(1)
	APR.OptionsFrame.QuestButtonsSlider:SetValue(100)
	APR.OptionsFrame.QuestButtonsSlider:SetScript("OnValueChanged", function(self,event)
		event = event - event%1
		APR1[APR.Realm][APR.Name]["Settings"]["QuestButtons"] = event / 100
		local CLi
		for CLi = 1, 20 do
			APR.QuestList2["BF"..CLi]["APR_Button"]:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["QuestButtons"])
		end
	end)
	APR.OptionsFrame.QuestButtonsSlider:SetScript("OnMouseWheel", function(self,delta)
		if tonumber(self:GetValue()) == nil then return end
		self:SetValue(tonumber(self:GetValue())+delta)
	end)
	APR.OptionsFrame.QuestButtonsSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["QuestButtons"] * 100)
	if (APR1[APR.Realm][APR.Name]["Settings"]["QuestButtonDetatch"] == 1) then
		APR.OptionsFrame.QuestButtonsSlider:Show()
	else
		APR.OptionsFrame.QuestButtonsSlider:Hide()
	end

	APR.OptionsFrame["Button1"] = CreateFrame("Button", "APR_OptionsButtons1", APR.OptionsFrame.MainFrame, "SecureActionButtonTemplate")
	APR.OptionsFrame["Button1"]:SetPoint("BOTTOMRIGHT",APR.OptionsFrame.MainFrame,"BOTTOMRIGHT",-5,5)
	APR.OptionsFrame["Button1"]:SetWidth(70)
	APR.OptionsFrame["Button1"]:SetHeight(30)
	APR.OptionsFrame["Button1"]:SetText(L["CLOSE"])
	APR.OptionsFrame["Button1"]:SetParent(APR.OptionsFrame.MainFrame)
	APR.OptionsFrame.Button1:SetFrameStrata("HIGH")
	APR.OptionsFrame.Button1:SetNormalFontObject("GameFontNormal")
	APR.OptionsFrame.Button1ntex = APR.OptionsFrame.Button1:CreateTexture()
	APR.OptionsFrame.Button1ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	APR.OptionsFrame.Button1ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.Button1ntex:SetAllPoints()
--	APR.OptionsFrame.Button1:SetNormalTexture(APR.OptionsFrame.Button1ntex)
	APR.OptionsFrame.Button1htex = APR.OptionsFrame.Button1:CreateTexture()
	APR.OptionsFrame.Button1htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.OptionsFrame.Button1htex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.Button1htex:SetAllPoints()
	APR.OptionsFrame.Button1:SetHighlightTexture(APR.OptionsFrame.Button1htex)
	APR.OptionsFrame.Button1ptex = APR.OptionsFrame.Button1:CreateTexture()
	APR.OptionsFrame.Button1ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	APR.OptionsFrame.Button1ptex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.Button1ptex:SetAllPoints()
	APR.OptionsFrame.Button1:SetPushedTexture(APR.OptionsFrame.Button1ptex)
	APR.OptionsFrame["Button1"]:SetScript("OnClick", function(self, arg1)
		APR.OptionsFrame.MainFrame:Hide()
		APR.SettingsOpen = 0
		APR.BookingList["ClosedSettings"] = 1
	end)

	APR.OptionsFrame["ShowStuffs"] = CreateFrame("Button", "APR_RoutePlan_FG1_ShowStuffs", APR.OptionsFrame.MainFrame, "UIPanelButtonTemplate")
	APR.OptionsFrame["ShowStuffs"]:SetWidth(140)
	APR.OptionsFrame["ShowStuffs"]:SetHeight(30)
	APR.OptionsFrame["ShowStuffs"]:SetFrameStrata("HIGH")
	APR.OptionsFrame["ShowStuffs"]:SetText(L["CUSTOM_PATH"])
	APR.OptionsFrame["ShowStuffs"]:SetPoint("BOTTOMRIGHT",APR.OptionsFrame.MainFrame,"BOTTOMRIGHT",-300,5)
	APR.OptionsFrame["ShowStuffs"]:SetNormalFontObject("GameFontNormalLarge")
	APR.OptionsFrame["ShowStuffs"]:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			APR.RoutePlan.FG1:Show()
			APR.OptionsFrame.MainFrame:Hide()
			APR.SettingsOpen = 0
			APR.BookingList["ClosedSettings"] = 1
		end
	end)
	APR.OptionsFrame["ShowStuffs2"] = CreateFrame("Button", "APR_RoutePlan_FG1_ShowStuffs2", APR.OptionsFrame.MainFrame, "UIPanelButtonTemplate")
	APR.OptionsFrame["ShowStuffs2"]:SetWidth(150)
	APR.OptionsFrame["ShowStuffs2"]:SetHeight(30)
	APR.OptionsFrame["ShowStuffs2"]:SetFrameStrata("HIGH")
	APR.OptionsFrame["ShowStuffs2"]:SetText(L["AUTO_PATH_HELPER"])
	APR.OptionsFrame["ShowStuffs2"]:SetPoint("BOTTOMRIGHT",APR.OptionsFrame.MainFrame,"BOTTOMRIGHT",-300,35)
	APR.OptionsFrame["ShowStuffs2"]:SetNormalFontObject("GameFontNormalLarge")
	APR.OptionsFrame["ShowStuffs2"]:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			APR.LoadInOptionFrame:Show()
			APR.OptionsFrame.MainFrame:Hide()
			APR.SettingsOpen = 0
			APR.BookingList["ClosedSettings"] = 1
		end
	end)

	APR.OptionsFrame["Button2"] = CreateFrame("Button", "APR_OptionsButtons2", APR.OptionsFrame.MainFrame, "SecureActionButtonTemplate")
	APR.OptionsFrame["Button2"]:SetPoint("BOTTOMRIGHT",APR.OptionsFrame.MainFrame,"BOTTOMRIGHT",-185,5)
	APR.OptionsFrame["Button2"]:SetWidth(100)
	APR.OptionsFrame["Button2"]:SetHeight(30)
	APR.OptionsFrame["Button2"]:SetText(L["KEYBINDS"])
	APR.OptionsFrame["Button2"]:SetParent(APR.OptionsFrame.MainFrame)
	APR.OptionsFrame.Button2:SetFrameStrata("HIGH")
	APR.OptionsFrame.Button2:SetNormalFontObject("GameFontNormal")
	APR.OptionsFrame.Button2ntex = APR.OptionsFrame.Button2:CreateTexture()
	APR.OptionsFrame.Button2ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	APR.OptionsFrame.Button2ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.Button2ntex:SetAllPoints()
--	APR.OptionsFrame.Button2:SetNormalTexture(APR.OptionsFrame.Button2ntex)
	APR.OptionsFrame.Button2htex = APR.OptionsFrame.Button2:CreateTexture()
	APR.OptionsFrame.Button2htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.OptionsFrame.Button2htex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.Button2htex:SetAllPoints()
	APR.OptionsFrame.Button2:SetHighlightTexture(APR.OptionsFrame.Button2htex)
	APR.OptionsFrame.Button2ptex = APR.OptionsFrame.Button2:CreateTexture()
	APR.OptionsFrame.Button2ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	APR.OptionsFrame.Button2ptex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.Button2ptex:SetAllPoints()
	APR.OptionsFrame.Button2:SetPushedTexture(APR.OptionsFrame.Button2ptex)
	APR.OptionsFrame["Button2"]:SetScript("OnClick", function(self, arg1)
		--KeyBindingFrame_LoadUI()
		--KeyBindingFrame:Show()
		ShowUIPanel(KeyBindingFrame)
		--QuickKeybindFrame:Show()
	end)

	APR.OptionsFrame["Button3"] = CreateFrame("Button", "APR_OptionsButtons3", APR.OptionsFrame.MainFrame, "SecureActionButtonTemplate")
	APR.OptionsFrame["Button3"]:SetPoint("BOTTOMRIGHT",APR.OptionsFrame.MainFrame,"BOTTOMRIGHT",-90,5)
	APR.OptionsFrame["Button3"]:SetWidth(70)
	APR.OptionsFrame["Button3"]:SetHeight(30)
	APR.OptionsFrame["Button3"]:SetText(L["RESET"])
	APR.OptionsFrame["Button3"]:SetParent(APR.OptionsFrame.MainFrame)
	APR.OptionsFrame.Button3:SetFrameStrata("HIGH")
	APR.OptionsFrame.Button3:SetNormalFontObject("GameFontNormal")
	APR.OptionsFrame.Button3ntex = APR.OptionsFrame.Button3:CreateTexture()
	APR.OptionsFrame.Button3ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	APR.OptionsFrame.Button3ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.Button3ntex:SetAllPoints()
--	APR.OptionsFrame.Button3:SetNormalTexture(APR.OptionsFrame.Button3ntex)
	APR.OptionsFrame.Button3htex = APR.OptionsFrame.Button3:CreateTexture()
	APR.OptionsFrame.Button3htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	APR.OptionsFrame.Button3htex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.Button3htex:SetAllPoints()
	APR.OptionsFrame.Button3:SetHighlightTexture(APR.OptionsFrame.Button3htex)
	APR.OptionsFrame.Button3ptex = APR.OptionsFrame.Button3:CreateTexture()
	APR.OptionsFrame.Button3ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	APR.OptionsFrame.Button3ptex:SetTexCoord(0, 0.625, 0, 0.6875)
	APR.OptionsFrame.Button3ptex:SetAllPoints()
	APR.OptionsFrame.Button3:SetPushedTexture(APR.OptionsFrame.Button3ptex)
	APR.OptionsFrame["Button3"]:SetScript("OnClick", function(self, arg1)
		APR.ResetSettings()
	end)

end
