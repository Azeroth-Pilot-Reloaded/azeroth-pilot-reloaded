local L = LibStub("AceLocale-3.0"):GetLocale("APR")

--Resets settings for APR
function APR.ResetSettings()
  APR1[APR.Realm][APR.Name].Settings = {}
  APR1[APR.Realm][APR.Name].Settings["left"] = 150
  APR1[APR.Realm][APR.Name].Settings["top"] = -150
  APR1[APR.Realm][APR.Name].Settings["leftLiz"] = 150
  APR1[APR.Realm][APR.Name].Settings["topLiz"] = -150
  APR1[APR.Realm][APR.Name].Settings["Scale"] = UIParent:GetScale()
  APR1[APR.Realm][APR.Name].Settings["Lock"] = 0
  APR1[APR.Realm][APR.Name].Settings["Hide"] = 0
  APR1[APR.Realm][APR.Name].Settings["alpha"] = 1
  APR1[APR.Realm][APR.Name].Settings["arrowleft"] = 150
  APR1[APR.Realm][APR.Name].Settings["arrowtop"] = -150
  APR1[APR.Realm][APR.Name].Settings["Hcampleft"] = 150
  APR1[APR.Realm][APR.Name].Settings["Hcamptop"] = -150
  APR1[APR.Realm][APR.Name].Settings["CutScene"] = 1
  APR1[APR.Realm][APR.Name].Settings["AutoAccept"] = 0
  APR1[APR.Realm][APR.Name].Settings["AutoAcceptQuestRoute"] = 1
  APR1[APR.Realm][APR.Name].Settings["AutoHandIn"] = 1
  APR1[APR.Realm][APR.Name].Settings["ArrowScale"] = UIParent:GetScale()
  APR1[APR.Realm][APR.Name].Settings["AutoHandInChoice"] = 0
  APR1[APR.Realm][APR.Name].Settings["ShowQList"] = 1
  APR1[APR.Realm][APR.Name].Settings["AutoVendor"] = 0
  APR1[APR.Realm][APR.Name].Settings["AutoRepair"] = 0
  APR1[APR.Realm][APR.Name].Settings["ShowGroup"] = 1
  APR1[APR.Realm][APR.Name].Settings["AutoGossip"] = 1
  APR1[APR.Realm][APR.Name].Settings["ShowBlobs"] = 1
  APR1[APR.Realm][APR.Name].Settings["LockArrow"] = 0
  APR1[APR.Realm][APR.Name].Settings["ArrowFPS"] = 2
  APR1[APR.Realm][APR.Name].Settings["DisableHeirloomWarning"] = 0
  APR1[APR.Realm][APR.Name].Settings["MiniMapBlobAlpha"] = 1
  APR1[APR.Realm][APR.Name].Settings["OrderListScale"] = 1

  APR.OptionsFrame.ShowQListCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings["ShowQList"]))
  APR.OptionsFrame.ShowGroupCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings["ShowGroup"]))
  APR.OptionsFrame.AutoGossipCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings["AutoGossip"]))
  APR.OptionsFrame.AutoVendorCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings["AutoVendor"]))
  APR.OptionsFrame.AutoRepairCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings["AutoRepair"]))
  APR.OptionsFrame.LockQuestListCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings["Lock"]))
  APR.OptionsFrame.CutSceneCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings["CutScene"]))
  APR.OptionsFrame.AutoAcceptCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings["AutoAccept"]))
  APR.OptionsFrame.AutoAcceptQuestRouteCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings
    ["AutoAcceptQuestRoute"]))
  APR.OptionsFrame.AutoHandInCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings["AutoHandIn"]))
  APR.OptionsFrame.AutoHandInChoiceCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings
    ["AutoHandInChoice"]))

  -- UI stuff regarding questlist and options frame
  APR.QuestList.ButtonParent:SetScale(APR1[APR.Realm][APR.Name].Settings["Scale"])
  APR.QuestList.ListFrame:SetScale(APR1[APR.Realm][APR.Name].Settings["Scale"])
  APR.QuestList21:SetScale(APR1[APR.Realm][APR.Name].Settings["Scale"])
  APR.OptionsFrame.QuestListScaleSlider:SetValue(APR1[APR.Realm][APR.Name].Settings["Scale"] * 100)
  APR.OptionsFrame.ArrowScaleSlider:SetValue(APR1[APR.Realm][APR.Name].Settings["ArrowScale"] * 100)

  APR.QuestList.MainFrame:ClearAllPoints()
  APR.QuestList.MainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name].Settings["left"],
    APR1[APR.Realm][APR.Name].Settings["top"])
  APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name].Settings["ArrowScale"])
  APR.ArrowFrameM:ClearAllPoints()
  APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name].Settings["arrowleft"],
    APR1[APR.Realm][APR.Name].Settings["arrowtop"])
  APR.ZoneQuestOrder:ClearAllPoints()
  APR.ZoneQuestOrder:SetPoint("CENTER", UIParent, "CENTER", 1, 1)
  APR1[APR.Realm][APR.Name].Settings["ArrowScale"] = UIParent:GetScale()
  APR1[APR.Realm][APR.Name].Settings["LockArrow"] = 0
  APR1[APR.Realm][APR.Name].Settings["ArrowFPS"] = 2
  APR1[APR.Realm][APR.Name].Settings["arrowleft"] = GetScreenWidth() / 2.05
  APR1[APR.Realm][APR.Name].Settings["arrowtop"] = -(GetScreenHeight() / 1.5)
  APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name].Settings["ArrowScale"])
  APR.ArrowFrameM:ClearAllPoints()
  APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name].Settings["arrowleft"],
    APR1[APR.Realm][APR.Name].Settings["arrowtop"])
  APR.OptionsFrame.ArrowFpsSlider:SetValue(APR1[APR.Realm][APR.Name].Settings["ArrowFPS"])
  APR.OptionsFrame.LockArrowCheckButton:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings["LockArrow"]))
  APR.OptionsFrame.ArrowScaleSlider:SetValue(APR1[APR.Realm][APR.Name].Settings["ArrowScale"] * 100)
end



local function displayOptionSection(optionFrame, subOptionFrame, frameName, x, y, checkValue, text)
  APR.OptionsFrame.MainFrame[optionFrame] = CreateFrame("frame", frameName, APR_OptionsMainFrame)
  APR.OptionsFrame.MainFrame[optionFrame]:SetWidth(150)
  APR.OptionsFrame.MainFrame[optionFrame]:SetHeight(30)
  APR.OptionsFrame.MainFrame[optionFrame]:SetFrameStrata("HIGH")
  APR.OptionsFrame.MainFrame[optionFrame]:SetPoint(checkValue, APR_OptionsMainFrame, checkValue, x, y)
  APR.OptionsFrame.MainFrame[optionFrame]:SetMovable(true)
  APR.OptionsFrame.MainFrame[optionFrame]:EnableMouse(true)
  local t = APR.OptionsFrame.MainFrame[optionFrame]:CreateTexture(nil, "BACKGROUND")
  t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
  t:SetAllPoints(APR.OptionsFrame.MainFrame[optionFrame])
  APR.OptionsFrame.MainFrame[optionFrame].texture = t

  APR.OptionsFrame.MainFrame[optionFrame]:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      APR.OptionsFrame.MainFrame.OptionsQuests:Hide()
      APR.OptionsFrame.MainFrame.OptionsArrow:Hide()
      APR.OptionsFrame.MainFrame.OptionsGeneral:Hide()
      APR.OptionsFrame.MainFrame[subOptionFrame]:Show()
    end
  end)
  APR.OptionsFrame.MainFrame[optionFrame]:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and APR.OptionsFrame.MainFrame.isMoving then
      APR.OptionsFrame.MainFrame:StopMovingOrSizing();
      APR.OptionsFrame.MainFrame.isMoving = false;
    end
  end)
  APR.OptionsFrame.MainFrame[optionFrame]:SetScript("OnHide", function(self)
    if (APR.OptionsFrame.MainFrame.isMoving) then
      APR.OptionsFrame.MainFrame:StopMovingOrSizing();
      APR.OptionsFrame.MainFrame.isMoving = false;
    end
  end)
  APR.OptionsFrame.MainFrame[optionFrame].FontString = APR.OptionsFrame.MainFrame:CreateFontString("APR_OptionsB3FS1",
    "ARTWORK", "ChatFontNormal")
  APR.OptionsFrame.MainFrame[optionFrame].FontString:SetParent(APR.OptionsFrame.MainFrame[optionFrame])
  APR.OptionsFrame.MainFrame[optionFrame].FontString:SetPoint("CENTER", APR.OptionsFrame.MainFrame[optionFrame],
    "CENTER",
    0, 0)
  APR.OptionsFrame.MainFrame[optionFrame].FontString:SetWidth(240)
  APR.OptionsFrame.MainFrame[optionFrame].FontString:SetHeight(20)
  APR.OptionsFrame.MainFrame[optionFrame].FontString:SetFontObject("GameFontHighlightLarge")
  APR.OptionsFrame.MainFrame[optionFrame].FontString:SetText(text)
  APR.OptionsFrame.MainFrame[optionFrame].FontString:SetTextColor(1, 1, 0)

  APR.OptionsFrame.MainFrame[subOptionFrame] = CreateFrame("frame", "APR_OptionsMainFrame_General",
    APR_OptionsMainFrame)
  APR.OptionsFrame.MainFrame[subOptionFrame]:SetWidth(295)
  APR.OptionsFrame.MainFrame[subOptionFrame]:SetHeight(320)
  APR.OptionsFrame.MainFrame[subOptionFrame]:SetFrameStrata("MEDIUM")
  APR.OptionsFrame.MainFrame[subOptionFrame]:SetPoint("LEFT", APR_OptionsMainFrame, "LEFT", 155, -20)
  APR.OptionsFrame.MainFrame[subOptionFrame]:SetMovable(true)
  APR.OptionsFrame.MainFrame[subOptionFrame]:EnableMouse(true)

  local t = APR.OptionsFrame.MainFrame[subOptionFrame]:CreateTexture(nil, "BACKGROUND")
  t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
  t:SetAllPoints(APR.OptionsFrame.MainFrame[subOptionFrame])
  APR.OptionsFrame.MainFrame[subOptionFrame].texture = t

  APR.OptionsFrame.MainFrame[subOptionFrame]:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not APR.OptionsFrame.MainFrame.isMoving then
      APR.OptionsFrame.MainFrame:StartMoving();
      APR.OptionsFrame.MainFrame.isMoving = true;
    end
  end)
  APR.OptionsFrame.MainFrame[subOptionFrame]:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and APR.OptionsFrame.MainFrame.isMoving then
      APR.OptionsFrame.MainFrame:StopMovingOrSizing();
      APR.OptionsFrame.MainFrame.isMoving = false;
    end
  end)
  APR.OptionsFrame.MainFrame[subOptionFrame]:SetScript("OnHide", function(self)
    if (APR.OptionsFrame.MainFrame.isMoving) then
      APR.OptionsFrame.MainFrame:StopMovingOrSizing();
      APR.OptionsFrame.MainFrame.isMoving = false;
    end
  end)
  APR.OptionsFrame.MainFrame[subOptionFrame]:Hide()
end

local function checkboxOptionline(parentFrame, optionFrameButton, frameName, x, y, checkValue, text, optionalFunction)
  APR.OptionsFrame[optionFrameButton] = CreateFrame("CheckButton", frameName, APR.OptionsFrame.MainFrame[parentFrame],
    "ChatConfigCheckButtonTemplate");
  APR.OptionsFrame[optionFrameButton]:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame[parentFrame], "TOPLEFT", x, y)
  APR.OptionsFrame[optionFrameButton]:SetChecked(NumToBool(APR1[APR.Realm][APR.Name].Settings[checkValue]))
  getglobal(APR.OptionsFrame[optionFrameButton]:GetName() .. 'Text'):SetText(": " .. text)
  getglobal(APR.OptionsFrame[optionFrameButton]:GetName() .. 'Text'):SetTextColor(1, 1, 1)
  optionalFunction = optionalFunction or
      function()
        APR1[APR.Realm][APR.Name].Settings[checkValue] = Booltonumber(APR.OptionsFrame[optionFrameButton]
          :GetChecked())
      end
  APR.OptionsFrame[optionFrameButton]:SetScript("OnClick", optionalFunction)
end

local function sliderOptionLine(parentFrame, optionFrameSlide, frameName, x, y, checkValue, text, functionOnChanged,
                                offset)
  APR.OptionsFrame[optionFrameSlide] = CreateFrame("Slider", frameName, APR.OptionsFrame.MainFrame[parentFrame],
    "OptionsSliderTemplate")
  APR.OptionsFrame[optionFrameSlide]:SetWidth(160)
  APR.OptionsFrame[optionFrameSlide]:SetHeight(15)
  APR.OptionsFrame[optionFrameSlide]:SetPoint("TOPLEFT", APR.OptionsFrame.MainFrame[parentFrame], "TOPLEFT", x, y)
  APR.OptionsFrame[optionFrameSlide]:SetOrientation("HORIZONTAL")
  APR.OptionsFrame[optionFrameSlide]:SetMinMaxValues(1, 200)
  APR.OptionsFrame[optionFrameSlide].minValue, APR.OptionsFrame[optionFrameSlide].maxValue = APR.OptionsFrame
      [optionFrameSlide]:GetMinMaxValues()
  getglobal(APR.OptionsFrame[optionFrameSlide]:GetName() .. 'Low'):SetText("1%")
  getglobal(APR.OptionsFrame[optionFrameSlide]:GetName() .. 'High'):SetText("200%")
  getglobal(APR.OptionsFrame[optionFrameSlide]:GetName() .. 'Text'):SetText(text .. ":")
  APR.OptionsFrame[optionFrameSlide]:SetValueStep(1)
  APR.OptionsFrame[optionFrameSlide]:SetValue(100)
  APR.OptionsFrame[optionFrameSlide]:SetScript("OnValueChanged", functionOnChanged)
  APR.OptionsFrame[optionFrameSlide]:SetScript("OnMouseWheel", function(self, delta)
    if tonumber(self:GetValue()) == nil then return end
    self:SetValue(tonumber(self:GetValue()) + delta)
  end)
  offset = offset or 100
  APR.OptionsFrame[optionFrameSlide]:SetValue(APR1[APR.Realm][APR.Name].Settings[checkValue] * offset)
end
local function displayButton(parentFrame, optionFrameButton, frameName, width, height, x, y, pointValue, text, fontStyle,
                             onClickFunction)
  APR.OptionsFrame[optionFrameButton] = CreateFrame("Button", frameName, parentFrame, "UIPanelButtonTemplate")

  APR.OptionsFrame[optionFrameButton].Fontstring = APR.OptionsFrame.MainFrame:CreateFontString("APRSettingsFS1",
    "ARTWORK", "ChatFontNormal")
  APR.OptionsFrame[optionFrameButton].Fontstring:SetParent(APR.OptionsFrame[optionFrameButton])
  APR.OptionsFrame[optionFrameButton].Fontstring:SetPoint("CENTER", APR.OptionsFrame[optionFrameButton])
  APR.OptionsFrame[optionFrameButton].Fontstring:SetText(text)
  APR.OptionsFrame[optionFrameButton].Fontstring:Hide()

  local newWidth = APR.OptionsFrame[optionFrameButton].Fontstring:GetStringWidth() + 20
  APR.OptionsFrame[optionFrameButton]:SetWidth(newWidth)
  APR.OptionsFrame[optionFrameButton]:SetHeight(height)
  APR.OptionsFrame[optionFrameButton]:SetFrameStrata("HIGH")
  APR.OptionsFrame[optionFrameButton]:SetText(text)
  APR.OptionsFrame[optionFrameButton]:SetPoint(pointValue, parentFrame, pointValue, x, y)
  APR.OptionsFrame[optionFrameButton]:SetNormalFontObject(fontStyle)
  APR.OptionsFrame[optionFrameButton]:SetScript("OnClick", onClickFunction)
end


function APR.LoadOptionsFrame()
  APR.OptionsFrame = {}
  APR.OptionsFrame.MainFrame = CreateFrame("frame", "APR_OptionsMainFrame", UIParent)
  APR.OptionsFrame.MainFrame:SetWidth(450)
  APR.OptionsFrame.MainFrame:SetHeight(360)
  APR.OptionsFrame.MainFrame:SetFrameStrata("MEDIUM")
  APR.OptionsFrame.MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  APR.OptionsFrame.MainFrame:SetMovable(true)
  APR.OptionsFrame.MainFrame:EnableMouse(true)

  local t = APR.OptionsFrame.MainFrame:CreateTexture(nil, "BACKGROUND")
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
    if (APR.OptionsFrame.MainFrame.isMoving) then
      APR.OptionsFrame.MainFrame:StopMovingOrSizing();
      APR.OptionsFrame.MainFrame.isMoving = false;
    end
  end)
  APR.OptionsFrame.MainFrame:Hide()

  APR.OptionsFrame.MainFrame.Options = CreateFrame("frame", "APR_OptionsMainFrame_1", APR_OptionsMainFrame)
  APR.OptionsFrame.MainFrame.Options:SetWidth(150)
  APR.OptionsFrame.MainFrame.Options:SetHeight(320)
  APR.OptionsFrame.MainFrame.Options:SetFrameStrata("Low")
  APR.OptionsFrame.MainFrame.Options:SetPoint("LEFT", APR_OptionsMainFrame, "LEFT", 0, -20)
  APR.OptionsFrame.MainFrame.Options:SetMovable(true)
  APR.OptionsFrame.MainFrame.Options:EnableMouse(true)

  local t = APR.OptionsFrame.MainFrame.Options:CreateTexture(nil, "BACKGROUND")
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
    if (APR.OptionsFrame.MainFrame.isMoving) then
      APR.OptionsFrame.MainFrame:StopMovingOrSizing();
      APR.OptionsFrame.MainFrame.isMoving = false;
    end
  end)
  APR.OptionsFrame.FontString1 = APR.OptionsFrame.MainFrame:CreateFontString("APRSettingsFS1", "ARTWORK",
    "ChatFontNormal")
  APR.OptionsFrame.FontString1:SetParent(APR.OptionsFrame.MainFrame)
  APR.OptionsFrame.FontString1:SetPoint("TOP", APR.OptionsFrame.MainFrame, "TOP", 0, 0)
  APR.OptionsFrame.FontString1:SetText(APR.title .. " - " .. APR.version)
  APR.OptionsFrame.FontString1:SetWidth(APR.OptionsFrame.FontString1:GetStringWidth() * 1.5)
  APR.OptionsFrame.FontString1:SetHeight(20)
  APR.OptionsFrame.FontString1:SetFontObject("GameFontHighlightLarge")
  APR.OptionsFrame.FontString1:SetTextColor(1, 1, 0)
  -------------------- Quest Options ----------------------------------------

  displayOptionSection("OptionsB1", "OptionsQuests", "APR_OptionsMainFrame_QuestOptions", 0, -40, "TOPLEFT",
    L["Q_OPTIONS"])
  APR.OptionsFrame.MainFrame.OptionsQuests:Show()
  -- Auto pickup checkbox
  checkboxOptionline("OptionsQuests", "AutoAcceptCheckButton", "APR_AutoAcceptCheckButton", 10, -10, "AutoAccept",
    L["ACCEPT_Q"],
    function()
      APR1[APR.Realm][APR.Name].Settings.AutoAccept = Booltonumber(APR.OptionsFrame.AutoAcceptCheckButton
        :GetChecked())
      if (APR.OptionsFrame.AutoAcceptCheckButton:GetChecked() == true) then
        APR1[APR.Realm][APR.Name].Settings.AutoAcceptQuestRoute = 0
        APR.OptionsFrame.AutoAcceptQuestRouteCheckButton:SetChecked(false)
      end
    end)
  -- Auto pickup quest route checkbox
  checkboxOptionline("OptionsQuests", "AutoAcceptQuestRouteCheckButton", "APR_AutoAcceptQuestRouteCheckButton", 10, -30,
    "AutoAcceptQuestRoute", L["ACCEPT_Q_ROUTE"],
    function()
      APR1[APR.Realm][APR.Name].Settings.AutoAcceptQuestRoute = Booltonumber(APR.OptionsFrame
        .AutoAcceptQuestRouteCheckButton:GetChecked())
      if (APR.OptionsFrame.AutoAcceptQuestRouteCheckButton:GetChecked() == true) then
        APR1[APR.Realm][APR.Name].Settings.AutoAccept = 0
        APR.OptionsFrame.AutoAcceptCheckButton:SetChecked(false)
      end
    end)
  -- Auto handin checkbox
  checkboxOptionline("OptionsQuests", "AutoHandInCheckButton", "APR_AutoHandInCheckButton", 10, -50, "AutoHandIn",
    L["TURN_IN_Q"])
  -- Auto handi item choice checkbox
  checkboxOptionline("OptionsQuests", "AutoHandInChoiceCheckButton", "APR_AutoHandInChoiceCheckButton", 10, -70,
    "AutoHandInChoice", L["AUTO_PICK_REWARD_ITEM"])
  -- Display Quest list/ current step checkbox
  checkboxOptionline("OptionsQuests", "ShowQListCheckButton", "APR_ShowQListCheckButton", 10, -90, "ShowQList",
    L["SHOW_QLIST"], function()
      APR1[APR.Realm][APR.Name].Settings.ShowQList = Booltonumber(APR.OptionsFrame.ShowQListCheckButton:GetChecked())
      APR.BookingList.PrintQStep = 1
      if (APR.OptionsFrame.ShowQListCheckButton:GetChecked() == false) then
        for CLi = 1, 10 do
          APR.QuestList.QuestFrames[CLi]:Hide()
          APR.QuestList.QuestFrames["FS" .. CLi].Button:Hide()
          APR.QuestList2["BF" .. CLi]:Hide()
        end
      end
    end)
  -- Display Quest list/ current step checkbox
  checkboxOptionline("OptionsQuests", "LockQuestListCheckButton", "APR_LockQuestListCheckButton", 10, -110, "Lock",
    L["LOCK_QLIST_WINDOW"])
  -- Quest list/ current step scale slider
  sliderOptionLine("OptionsQuests", "QuestListScaleSlider", "APR_QuestListScaleSlider", 62, -150, "Scale",
    L["QLIST_SCALE"], function(self, event)
      event = event - event % 1
      APR1[APR.Realm][APR.Name].Settings.Scale = event / 100
      APR.QuestList.ButtonParent:SetScale(APR1[APR.Realm][APR.Name].Settings.Scale)
      APR.QuestList.ListFrame:SetScale(APR1[APR.Realm][APR.Name].Settings.Scale)
      APR.QuestList21:SetScale(APR1[APR.Realm][APR.Name].Settings.Scale)
    end)
  -- DQuest order list scale slider
  sliderOptionLine("OptionsQuests", "QuestOrderListScaleSlider", "APR_QuestOrderListScaleSlider", 62, -190,
    "OrderListScale", L["QORDERLIST_SCALE"], function(self, event)
      event = event - event % 1
      APR1[APR.Realm][APR.Name].Settings.OrderListScale = event / 100
      APR.ZoneQuestOrder:SetScale(APR1[APR.Realm][APR.Name].Settings.OrderListScale)
    end)
  -- Display Quest order list checkbox
  checkboxOptionline("OptionsQuests", "QorderListzCheckButton", "APR_QorderListzCheckButton", 10, -215,
    "ShowQuestListOrder", L["SHOW_QORDERLIST"], function()
      APR1[APR.Realm][APR.Name].Settings.ShowQuestListOrder = Booltonumber(APR.OptionsFrame.QorderListzCheckButton
        :GetChecked())
      if (APR.OptionsFrame.QorderListzCheckButton:GetChecked() == true) then
        APR.UpdateZoneQuestOrderList("LoadIn")
        APR.ZoneQuestOrder:Show()
      else
        APR.ZoneQuestOrder:Hide()
      end
    end)
  -- Reset quest order list button
  displayButton(APR.OptionsFrame.MainFrame.OptionsQuests, "ResetQorderL", "APR_OptionsButtons3", 150, 30, 50, -245,
    "TOPLEFT", L["RESET_QORDERLIST"], "GameFontNormal", function(self, arg1)
      APR.ZoneQuestOrder:ClearAllPoints()
      APR.ZoneQuestOrder:SetPoint("CENTER", UIParent, "CENTER", 1, 1)
    end)
  ----------------- Arrow Options --------------------------------------------------------------------------------------------
  displayOptionSection("OptionsB2", "OptionsArrow", "APR_OptionsMainFrame_ArrowOptions", 0, -70, "TOPLEFT",
    L["ARROW_OPTION"])
  -- Arrow locker checkbox
  checkboxOptionline("OptionsArrow", "LockArrowCheckButton", "APR_LockArrowCheckButton", 10, -10, "LockArrow",
    L["LOCK_ARROW_WINDOW"])
  -- Display arrow checkbox
  checkboxOptionline("OptionsArrow", "ShowArrowCheckButton", "APR_ShowArrowCheckButton", 10, -30, "ShowArrow",
    L["SHOW_ARROW"], function()
      APR1[APR.Realm][APR.Name].Settings.ShowArrow = Booltonumber(APR.OptionsFrame.ShowArrowCheckButton:GetChecked())
      if (APR.OptionsFrame.ShowArrowCheckButton:GetChecked() == true) then
        APR.ArrowActive = 1
      end
    end)
  -- Arrow scale slider
  sliderOptionLine("OptionsArrow", "ArrowScaleSlider", "APR_ArrowScaleSlider", 62, -70, "ArrowScale", L["ARROW_SCALE"],
    function(self, event)
      event = event - event % 1
      APR1[APR.Realm][APR.Name].Settings.ArrowScale = event / 100
      APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name].Settings.ArrowScale)
    end)
  -- Update arrow FPS slider
  sliderOptionLine("OptionsArrow", "ArrowFpsSlider", "APR_ArrowFpsSlider", 62, -110, "ArrowFPS",
    L["UPDATE_ARROW"] .. " " .. APR1[APR.Realm][APR.Name].Settings["ArrowFPS"] .. " FPS", function(self, event)
      event = event - event % 1
      APR1[APR.Realm][APR.Name].Settings["ArrowFPS"] = floor(event)
      getglobal(APR.OptionsFrame.ArrowFpsSlider:GetName() .. 'Text'):SetText(L["UPDATE_ARROW"] ..
        " " .. APR1[APR.Realm][APR.Name].Settings["ArrowFPS"] .. " FPS:")
    end, 1)
  -- Reset arrow button
  displayButton(APR.OptionsFrame.MainFrame.OptionsArrow, "ResetARrow", "APR_OptionsButtons3", 90, 30, 50, -140,
    "TOPLEFT",
    L["RESET_ARROW"], "GameFontNormal", function(self, arg1)
      APR1[APR.Realm][APR.Name].Settings["ArrowScale"] = UIParent:GetScale()
      APR1[APR.Realm][APR.Name].Settings["LockArrow"] = 0
      APR1[APR.Realm][APR.Name].Settings["ArrowFPS"] = 2
      APR1[APR.Realm][APR.Name].Settings["arrowleft"] = GetScreenWidth() / 2.05
      APR1[APR.Realm][APR.Name].Settings["arrowtop"] = -(GetScreenHeight() / 1.5)
      APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name].Settings["ArrowScale"])
      APR.ArrowFrameM:ClearAllPoints()
      APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name].Settings["arrowleft"],
        APR1[APR.Realm][APR.Name].Settings["arrowtop"])
      APR.OptionsFrame.ArrowFpsSlider:SetValue(APR1[APR.Realm][APR.Name].Settings["ArrowFPS"])
      if (APR1[APR.Realm][APR.Name].Settings["LockArrow"] == 0) then
        APR.OptionsFrame.LockArrowCheckButton:SetChecked(false)
      else
        APR.OptionsFrame.LockArrowCheckButton:SetChecked(true)
      end
      APR.OptionsFrame.ArrowScaleSlider:SetValue(APR1[APR.Realm][APR.Name].Settings["ArrowScale"] * 100)
    end)

  ------------------------- General Options --------------------------------------------------------------------------
  displayOptionSection("OptionsB3", "OptionsGeneral", "APR_OptionsMainFrame_GeneralOptions", 0, -100, "TOPLEFT",
    L["GENERAL_OPTION"])
  -- auto skip scene checkbox
  checkboxOptionline("OptionsGeneral", "CutSceneCheckButton", "APR_CutSceneCheckButton", 10, -10, "CutScene",
    L["SKIPPED_CUTSCENE"])
  -- auto sell checkbox
  checkboxOptionline("OptionsGeneral", "AutoVendorCheckButton", "APR_AutoVendorCheckButton", 10, -30, "AutoVendor",
    L["AUTO_VENDOR"])
  -- auto repair checkbox
  checkboxOptionline("OptionsGeneral", "AutoRepairCheckButton", "APR_AutoRepairCheckButton", 10, -50, "AutoRepair",
    L["AUTO_REPAIR"])
  -- Group progress checkbox
  checkboxOptionline("OptionsGeneral", "ShowGroupCheckButton", "APR_ShowGroupCheckButton", 10, -70, "ShowGroup",
    L["SHOW_GROUP_PROGRESS"], function()
      APR1[APR.Realm][APR.Name].Settings.ShowGroup = Booltonumber(APR.OptionsFrame.ShowGroupCheckButton:GetChecked())
      if (APR.OptionsFrame.ShowGroupCheckButton:GetChecked() == false) then
        for CLi = 1, 5 do
          APR.PartyList.PartyFrames[CLi]:Hide()
          APR.PartyList.PartyFrames2[CLi]:Hide()
        end
      end
    end)
  -- auto gossip checkbox
  checkboxOptionline("OptionsGeneral", "AutoGossipCheckButton", "APR_AutoGossipCheckButton", 10, -90, "AutoGossip",
    L["AUTO_SELECTION_OF_DIALOG"])
  -- auto fly checkbox
  checkboxOptionline("OptionsGeneral", "AutoFlightCheckButton", "APR_AutoFlightCheckButton", 10, -110, "AutoFlight",
    L["AUTO_USE_FLIGHTPATHS"])
  -- MiniMap quest blob display checkbox
  checkboxOptionline("OptionsGeneral", "BlobsShowCheckButton", "APR_BlobsShowCheckButton", 10, -130, "ShowBlobs",
    L["SHOW_BLOBS_ON_MINIMAP"], function()
      APR1[APR.Realm][APR.Name].Settings.ShowBlobs = Booltonumber(APR.OptionsFrame.BlobsShowCheckButton:GetChecked())
      if (APR.OptionsFrame.BlobsShowCheckButton:GetChecked() == true) then
        APR.OptionsFrame.MiniMapBlobAlphaSlider:Show()
      else
        APR.RemoveIcons()
        APR.OptionsFrame.MiniMapBlobAlphaSlider:Hide()
      end
    end)

  -- MiniMap Blob Alpha scale slider
  sliderOptionLine("OptionsGeneral", "MiniMapBlobAlphaSlider", "APR_MiniMapBlobAlphaSlider", 62, -160,
    "MiniMapBlobAlpha",
    L["MINIMAP_BLOB_ALPHA"], function(self, event)
      event = event - event % 1
      APR1[APR.Realm][APR.Name].Settings.MiniMapBlobAlpha = event / 100
      for CLi = 1, 20 do
        APR["Icons"][CLi].texture:SetAlpha(APR1[APR.Realm][APR.Name].Settings.MiniMapBlobAlpha)
      end
    end)
  if (APR1[APR.Realm][APR.Name].Settings.ShowBlobs == 0) then
    APR.OptionsFrame.MiniMapBlobAlphaSlider:Hide()
  end
  -- Map quest blob display checkbox
  checkboxOptionline("OptionsGeneral", "MapBlobsShowCheckButton", "APR_MapBlobsShowCheckButton", 10, -180,
    "ShowMapBlobs",
    L["SHOW_BLOBS_ON_MAP"], function()
      APR1[APR.Realm][APR.Name].Settings.ShowMapBlobs = Booltonumber(APR.OptionsFrame.MapBlobsShowCheckButton
        :GetChecked())
      if (APR.OptionsFrame.MapBlobsShowCheckButton:GetChecked() == false) then
        APR:MoveMapIcons()
      end
    end)
  -- Map 10 next quest marker display checkbox
  checkboxOptionline("OptionsGeneral", "ShowMap10sCheckButton", "APR_ShowMap10sCheckButton", 10, -200, "ShowMap10s",
    L["SHOW_STEPS_MAP"], function()
      APR1[APR.Realm][APR.Name].Settings.ShowMap10s = Booltonumber(APR.OptionsFrame.ShowMap10sCheckButton
        :GetChecked())
      if (APR.OptionsFrame.ShowMap10sCheckButton:GetChecked() == false) then
        APR.HBDP:RemoveAllWorldMapIcons("APRMapOrder")
      end
    end)
  -- Heirloom checkbox
  checkboxOptionline("OptionsGeneral", "QuestButtonsCheckButton", "APR_QuestButtonsCheckButton", 10, -220,
    "QuestButtonDetatch", L["DETACH_Q_ITEM_BTN"], function()
      APR1[APR.Realm][APR.Name].Settings.QuestButtonDetatch = Booltonumber(APR.OptionsFrame
        .QuestButtonsCheckButton
        :GetChecked())
      if (APR.OptionsFrame.QuestButtonsCheckButton:GetChecked() == true) then
        APR.OptionsFrame.QuestButtonsSlider:Show()
      else
        APR.QuestList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name].Settings["left"],
          APR1[APR.Realm][APR.Name].Settings["top"])
        for CLi = 1, 3 do
          APR1[APR.Realm][APR.Name].Settings.QuestButtons = 1
          APR.QuestList2["BF" .. CLi]:SetPoint("BOTTOMLEFT", APR.QuestList21, "BOTTOMLEFT", 0,
            -((CLi * 38) + CLi))
          APR.QuestList2["BF" .. CLi].APR_Button:SetScale(APR1[APR.Realm][APR.Name].Settings.QuestButtons)
          APR.OptionsFrame.QuestButtonsSlider:SetValue(APR1[APR.Realm][APR.Name].Settings.QuestButtons * 100)
        end
        APR.OptionsFrame.QuestButtonsSlider:Hide()
      end
    end)
  -- Quest buttons scale slider
  sliderOptionLine("OptionsGeneral", "QuestButtonsSlider", "APR_QuestButtonsSlider", 62, -260, "QuestButtons",
    L["Q_BTN_SCALE"], function(self, event)
      event = event - event % 1
      APR1[APR.Realm][APR.Name].Settings.QuestButtons = event / 100
      for CLi = 1, 20 do
        APR.QuestList2["BF" .. CLi].APR_Button:SetScale(APR1[APR.Realm][APR.Name].Settings.QuestButtons)
      end
    end)
  if (APR1[APR.Realm][APR.Name].Settings.QuestButtonDetatch == 0) then
    APR.OptionsFrame.QuestButtonsSlider:Hide()
  end
  -- Heirloom checkbox
  checkboxOptionline("OptionsGeneral", "DisableHeirloomWarningCheckButton", "APR_DisableHeirloomWarningCheckButton", 10,
    -280, "DisableHeirloomWarning", L["DISABLE_HEIRLOOM_WARNING"], function()
      APR1[APR.Realm][APR.Name].Settings.DisableHeirloomWarning = Booltonumber(APR.OptionsFrame
        .DisableHeirloomWarningCheckButton:GetChecked())
      APR.BookingList.PrintQStep = 1
    end)
  -- hide/useless broken settings
  APR.OptionsFrame.QuestButtonsCheckButton:Hide()
  APR.OptionsFrame.QuestButtonsSlider:Hide()
  APR.OptionsFrame.DisableHeirloomWarningCheckButton:Hide()

  -- Keybind button
  displayButton(APR.OptionsFrame.MainFrame, "Button2", "APR_OptionsButtons2", 100, 30, -175, 5, "BOTTOMRIGHT",
    L["KEYBINDS"], "GameFontNormal", function(self, arg1)
      ShowUIPanel(KeyBindingFrame)
    end)
  -- Reset button
  displayButton(APR.OptionsFrame.MainFrame, "Button3", "APR_OptionsButtons3", 70, 30, -80, 5, "BOTTOMRIGHT", L
    ["RESET"],
    "GameFontNormal", function(self, arg1)
      APR.ResetSettings()
    end)
  -- Close button
  displayButton(APR.OptionsFrame.MainFrame, "Button1", "APR_OptionsButtons1", 70, 30, -5, 5, "BOTTOMRIGHT", L["CLOSE"],
    "GameFontNormal", function(self, arg1)
      APR.OptionsFrame.MainFrame:Hide()
      APR.SettingsOpen = 0
      APR.BookingList["ClosedSettings"] = 1
    end)
  ------------------------- General Button --------------------------------------------------------------------------
  -- Auto path helper button
  APR.OptionsFrame["ShowStuffs2"] = CreateFrame("Button", "APR_RoutePlan_FG1_ShowStuffs2", APR.OptionsFrame.MainFrame,
    "UIPanelButtonTemplate")
  APR.OptionsFrame["ShowStuffs2"]:SetWidth(150)
  APR.OptionsFrame["ShowStuffs2"]:SetHeight(30)
  APR.OptionsFrame["ShowStuffs2"]:SetFrameStrata("HIGH")
  APR.OptionsFrame["ShowStuffs2"]:SetText(L["AUTO_PATH_HELPER"])
  APR.OptionsFrame["ShowStuffs2"]:SetPoint("BOTTOMRIGHT", APR.OptionsFrame.MainFrame, "BOTTOMRIGHT", -300, 35)
  APR.OptionsFrame["ShowStuffs2"]:SetNormalFontObject("GameFontNormalLarge")
  APR.OptionsFrame["ShowStuffs2"]:SetScript("OnClick", function(self, button)
    APR.LoadInOptionFrame:Show()
    APR.OptionsFrame.MainFrame:Hide()
    APR.SettingsOpen = 0
    APR.BookingList["ClosedSettings"] = 1
  end)
  -- Custom path button
  APR.OptionsFrame["ShowStuffs"] = CreateFrame("Button", "APR_RoutePlan_FG1_ShowStuffs", APR.OptionsFrame.MainFrame,
    "UIPanelButtonTemplate")
  APR.OptionsFrame["ShowStuffs"]:SetWidth(150)
  APR.OptionsFrame["ShowStuffs"]:SetHeight(30)
  APR.OptionsFrame["ShowStuffs"]:SetFrameStrata("HIGH")
  APR.OptionsFrame["ShowStuffs"]:SetText(L["CUSTOM_PATH"])
  APR.OptionsFrame["ShowStuffs"]:SetPoint("BOTTOMRIGHT", APR.OptionsFrame.MainFrame, "BOTTOMRIGHT", -300, 5)
  APR.OptionsFrame["ShowStuffs"]:SetNormalFontObject("GameFontNormalLarge")
  APR.OptionsFrame["ShowStuffs"]:SetScript("OnClick", function(self, button)
    APR.RoutePlan.FG1:Show()
    APR.OptionsFrame.MainFrame:Hide()
    APR.SettingsOpen = 0
    APR.BookingList["ClosedSettings"] = 1
  end)
end
