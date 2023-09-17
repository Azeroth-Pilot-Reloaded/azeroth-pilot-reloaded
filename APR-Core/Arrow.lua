local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Arrow Frame

APR.ArrowActive = 0
APR.ArrowActive_X = 0
APR.ArrowActive_Y = 0

-- TODO Rework Arrow frame
--More UI stuff, to do with arrowframe
--Arrowframe is the "arrow" that looks like the tomtom one
APR.ArrowFrameM = CreateFrame("Button", "APR_Arrow", UIParent)
APR.ArrowFrameM:SetHeight(1)
APR.ArrowFrameM:SetWidth(1)
APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
APR.ArrowFrameM:EnableMouse(true)
APR.ArrowFrameM:SetMovable(true)

APR.ArrowFrame = CreateFrame("Button", "APR_Arrow", UIParent)
APR.ArrowFrame:SetHeight(42)
APR.ArrowFrame:SetWidth(56)
APR.ArrowFrame:SetPoint("TOPLEFT", APR.ArrowFrameM, "TOPLEFT", 0, 0)
APR.ArrowFrame:EnableMouse(true)
APR.ArrowFrame:SetMovable(true)
APR.ArrowFrame.arrow = APR.ArrowFrame:CreateTexture(nil, "OVERLAY")
APR.ArrowFrame.arrow:SetTexture("Interface\\Addons\\APR-Core\\Img\\Arrow.blp")
APR.ArrowFrame.arrow:SetAllPoints()
APR.ArrowFrame.distance = APR.ArrowFrame:CreateFontString("distance", "ARTWORK", "ChatFontNormal")
APR.ArrowFrame.distance:SetFontObject("GameFontNormalSmall")
APR.ArrowFrame.distance:SetPoint("TOP", APR.ArrowFrame, "BOTTOM", 0, 0)
APR.ArrowFrame:Hide()
APR.ArrowFrame:SetScript("OnMouseDown", function(self, button) --Mouse clicking arrowframe
    if button == "LeftButton" and not APR.ArrowFrameM.isMoving and not APR.settings.profile.lockArrow then
        APR.ArrowFrameM:StartMoving();
        APR.ArrowFrameM.isMoving = true;
    end
end)
--Mouse unclicking arrowframe (releasing mouse)
APR.ArrowFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and APR.ArrowFrameM.isMoving then
        APR.ArrowFrameM:StopMovingOrSizing();
        APR.ArrowFrameM.isMoving = false;
        APR.settings.profile.arrowleft = APR.ArrowFrameM:GetLeft()
        APR.settings.profile.arrowtop = APR.ArrowFrameM:GetTop() - GetScreenHeight()
        APR.ArrowFrameM:ClearAllPoints()
        APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.arrowleft,
            APR.settings.profile.arrowtop)
    end
end)
--When arrowframe hides
APR.ArrowFrame:SetScript("OnHide", function(self)
    if (APR.ArrowFrameM.isMoving) then
        APR.ArrowFrameM:StopMovingOrSizing(); -- prevent it from moving or rescaling in the background, it cant be seen anyways
        APR.ArrowFrameM.isMoving = false;
        APR.settings.profile.arrowleft = APR.ArrowFrameM:GetLeft()
        APR.settings.profile.arrowtop = APR.ArrowFrameM:GetTop() - GetScreenHeight()
        APR.ArrowFrameM:ClearAllPoints()
        APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.arrowleft,
            APR.settings.profile.arrowtop)
    end
end)

APR.ArrowFrame.Button = CreateFrame("Button", "APR_ArrowActiveButton", APR.ArrowFrame)
APR.ArrowFrame.Button:SetParent(APR.ArrowFrame)
APR.ArrowFrame.Button:SetPoint("BOTTOM", APR.ArrowFrame, "BOTTOM", 0, -40)
APR.ArrowFrame.Button:SetScript("OnMouseDown", function(self, button)
    APR.ArrowFrame.Button:Hide()
    print("APR: " .. L["SKIP_WAYPOINT"])
    APRData[APR.Realm][APR.Name][APR.ActiveMap] = APRData[APR.Realm][APR.Name][APR.ActiveMap] + 1
    APR.ArrowActive_X = 0
    APR.ArrowActive_Y = 0
    APR.BookingList["UpdateQuest"] = 1
    APR.BookingList["PrintQStep"] = 1
end)

local t = APR.ArrowFrame.Button:CreateTexture(nil, "BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ArrowFrame.Button)
APR.ArrowFrame.Button.texture = t

APR.ArrowFrame.Fontstring = APR.ArrowFrame:CreateFontString("CLSettingsFS2212", "ARTWORK", "ChatFontNormal")
APR.ArrowFrame.Fontstring:SetParent(APR.ArrowFrame.Button)
APR.ArrowFrame.Fontstring:SetPoint("CENTER", APR.ArrowFrame.Button)
APR.ArrowFrame.Fontstring:SetText(L["SKIP_WAYPOINT"])
local skipWidth = APR.ArrowFrame.Fontstring:GetStringWidth() + 10 < 85 and
    (APR.ArrowFrame.Fontstring:GetStringWidth() + 10) / 2 or 85
local skipHeight = skipWidth < 85 and APR.ArrowFrame.Fontstring:GetStringHeight() + 10 or
    APR.ArrowFrame.Fontstring:GetStringHeight() + 5
APR.ArrowFrame.Button:SetWidth(skipWidth)
APR.ArrowFrame.Button:SetHeight(skipHeight)
APR.ArrowFrame.Fontstring:SetWidth(skipWidth)
APR.ArrowFrame.Fontstring:SetWordWrap(true)
APR.ArrowFrame.Fontstring:SetFontObject("GameFontNormalSmall")
APR.ArrowFrame.Fontstring:SetTextColor(1, 1, 0)
APR.ArrowFrame.Button:Hide()

