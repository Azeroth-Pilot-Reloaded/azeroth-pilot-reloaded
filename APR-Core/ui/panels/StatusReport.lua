-- Displays the original compact status window: client, route and character information.
-- Identity visibility is shared by the window and its separately selectable Lua export.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local CreateFrame = CreateFrame
local GetRealZoneText = GetRealZoneText

local NO_ACTIVE = L["UI_STATUS_NO_ACTIVE_ROUTE"]
local hideIdentity = true
local function SetStatusLine(line, label, value, colorHex)
    local role = APR:ResolveTextColorRole(colorHex, "success")
    line.Text:SetText(string.format(L["UI_LABEL_VALUE_FORMAT"], label, APR:WrapTextWithAppearanceColor(value, "general", role)))
end

function APR:createStatusContent(num, width, parent, anchorTo, content)
    if not content then content = CreateFrame('Frame', nil, parent) end
    content._aprLineCount = num
    content:SetSize(width, (num * 20) + ((num - 1) * 5)) --20 height and 5 spacing
    content:SetPoint('TOP', anchorTo, 'BOTTOM')

    for i = 1, num do
        if not content['Line' .. i] then
            local line = CreateFrame('Frame', nil, content)
            line:SetSize(width, 10)

            local text = line:CreateFontString(nil, 'ARTWORK')
            text:SetAllPoints()
            text:SetJustifyH('LEFT')
            text:SetJustifyV('MIDDLE')
            APR:RegisterFontString(text, "general", { role = "base", sizeDelta = -3 })
            line.Text = text

            if i == 1 then
                line:SetPoint('TOP', content, 'TOP')
            else
                line:SetPoint('TOP', content['Line' .. (i - 1)], 'BOTTOM', 0, -5)
            end

            content['Line' .. i] = line
        end
    end

    return content
end

local function RefreshStatusContentLayout(content)
    if not content then return 0 end
    local totalHeight = 0
    for i = 1, content._aprLineCount or 0 do
        local line = content['Line' .. i]
        if line and line.Text then
            local lineHeight = math.max(10, math.ceil(line.Text:GetStringHeight() or 0) + 2)
            line:SetHeight(lineHeight)
            totalHeight = totalHeight + lineHeight
            if i > 1 then totalHeight = totalHeight + 5 end
        end
    end
    content:SetHeight(totalHeight)
    return totalHeight
end

function APR:RefreshStatusTextLayout()
    local frame = self.StatusFrame
    if not frame then return end

    local totalHeight = 85 -- Title and two footer buttons, outside the status sections.
    for i = 1, 3 do
        local section = frame['Section' .. i]
        if section then
            local contentHeight = RefreshStatusContentLayout(section.Content)
            local headerHeight = section.Header and section.Header:GetHeight() or 0
            local sectionHeight = headerHeight + contentHeight
            section:SetHeight(sectionHeight)
            totalHeight = totalHeight + sectionHeight
        end
    end
    frame:SetHeight(totalHeight + 10)
end

-- Export a snapshot; later status refreshes must not replace text being selected.
function APR:ExportStatusReport()
    local report = self:getStatusReportInfos()
    -- Read the current runtime step without triggering route construction or progression.
    report.currentStepData = self:PeekCurrentStep()
    APR.UI:ShowTextReport(L["STATUS_EXPORT"], self:FormatDebugTable(report), self.StatusFrame)
end

local function GetCurrentStepInfo()
    local step, index = APR:PeekCurrentStep()
    if not index then return NO_ACTIVE end
    local _, action = APR:GetStepString(step)
    return tostring(index) .. ", " .. (action or UNKNOWN)
end

local function PublicNumber(value)
    if not APR:CanAccessValue(value) then return end
    if type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then
        return value
    end
end

function APR:getStatusReportInfos()
    local coordinates, worldCoordinates
    -- Coordinates can be unavailable or restricted in instances; guard before arithmetic.
    if self:IsInstanceWithUI() then
        local mapID = C_Map and C_Map.GetBestMapForUnit and PublicNumber(C_Map.GetBestMapForUnit("player"))
        if mapID and C_Map.GetPlayerMapPosition then
            local position = C_Map.GetPlayerMapPosition(mapID, "player")
            if self:CanAccessValue(position) and position then
                local x, y = PublicNumber(position.x), PublicNumber(position.y)
                if x and y then coordinates = self.coordinate:RoundCoords(x * 100, y * 100, 2) end
            end
        end
        if UnitPosition then
            -- WoW returns north/south first; APR displays east/west as X.
            local y, x = UnitPosition("player")
            x, y = PublicNumber(x), PublicNumber(y)
            if x and y then worldCoordinates = self.coordinate:RoundCoords(x, y, 2) end
        end
    end
    local currentStep = GetCurrentStepInfo()
    local continentID = self:GetContinent()
    local continent = continentID and self:GetMapInfoCached(continentID)
    local infoTable = {
        aprVersion = { L["UI_STATUS_ADDON_VERSION"], APR.version or UNKNOWN },
        wowVersion = { L["UI_STATUS_CLIENT_VERSION"], select(1, GetBuildInfo()) },
        clientLanguage = { L["UI_STATUS_LANGUAGE"], GetLocale() },
        currentTime = { L["UI_STATUS_DATE"], date() },
        serverType = { L["UI_STATUS_SERVER_TYPE"], GetCVar("portal") or UNKNOWN },
        currentRoute = { L["UI_STATUS_ROUTE"], APR.ActiveRoute or NO_ACTIVE },
        currentStep = { L["UI_STATUS_INDEX_ACTION"], currentStep or NO_ACTIVE },
        currentZone = { L["UI_STATUS_ZONE"], GetRealZoneText() or UNKNOWN },
        currentContinent = { L["UI_STATUS_CONTINENT"], continent and continent.name or UNKNOWN },
        currentCoords = { L["UI_STATUS_COORDINATES"], coordinates or UNKNOWN },
        currentWorldCoords = { L["UI_STATUS_WORLD_COORDINATES"], worldCoordinates or UNKNOWN },
        charFaction = { L["UI_STATUS_FACTION"], APR.Faction or UNKNOWN },
        charLevel = { L["UI_STATUS_LEVEL"], APR.Level or UNKNOWN },
        charClass = { L["UI_STATUS_CLASS"], APR:GetClassNameById(APR.ClassId) or UNKNOWN }
    }

    if not hideIdentity then
        infoTable.charName = { L["UI_STATUS_NAME"], self.Username or UNKNOWN }
        infoTable.charRealm = { L["UI_STATUS_REALM"], GetRealmName() or UNKNOWN }
    end
    return infoTable
end

function APR:getStatusColors(infoTable)
    infoTable = infoTable or self:getStatusReportInfos()
    local colorTable = {
        currentRouteColor = APR.HEXColor.green,
        currentStepColor = APR.HEXColor.green,
        currentZoneColor = APR.HEXColor.green,
        currentCoordsColor = APR.HEXColor.green
    }

    if infoTable.currentRoute[2] == NO_ACTIVE then
        colorTable.currentRouteColor = APR.HEXColor.red
        colorTable.currentStepColor = APR.HEXColor.red
    end
    if infoTable.currentZone[2] == UNKNOWN then
        colorTable.currentZoneColor = APR.HEXColor.red
    end
    if IsInInstance() then
        colorTable.currentCoordsColor = APR.HEXColor.red
    end

    return colorTable
end

local function closeClicked()
    APR:closeStatusReport()
end

function APR:createStatusSection(width, height, headerWidth, headerHeight, parent, anchor1, anchorTo, anchor2, yOffset)
    local parentWidth, parentHeight = parent:GetSize()

    if width > parentWidth then parent:SetWidth(width + 25) end
    if height then parent:SetHeight(parentHeight + height) end

    local section = CreateFrame('Frame', nil, parent)
    section:SetSize(width, height or 0)
    section:SetPoint(anchor1, anchorTo, anchor2, 0, yOffset)

    local header = CreateFrame('Frame', nil, section)
    header:SetSize(headerWidth or width, headerHeight)
    header:SetPoint('TOP', section)
    section.Header = header

    local text = section.Header:CreateFontString(nil, 'ARTWORK')
    text:SetPoint('TOP')
    text:SetPoint('BOTTOM')
    text:SetJustifyH('CENTER')
    text:SetJustifyV('MIDDLE')
    APR:RegisterFontString(text, "general", { role = "accent", sizeDelta = 6 })
    section.Header.Text = text

    local leftDivider = section.Header:CreateTexture(nil, 'ARTWORK')
    leftDivider:SetHeight(8)
    leftDivider:SetPoint('LEFT', section.Header, 'LEFT', 5, 0)
    leftDivider:SetPoint('RIGHT', section.Header.Text, 'LEFT', -5, 0)
    leftDivider:SetTexture([[Interface\Tooltips\UI-Tooltip-Border]])
    leftDivider:SetTexCoord(0.81, 0.94, 0.5, 1)
    section.Header.LeftDivider = leftDivider

    local rightDivider = section.Header:CreateTexture(nil, 'ARTWORK')
    rightDivider:SetHeight(8)
    rightDivider:SetPoint('RIGHT', section.Header, 'RIGHT', -5, 0)
    rightDivider:SetPoint('LEFT', section.Header.Text, 'RIGHT', 5, 0)
    rightDivider:SetTexture([[Interface\Tooltips\UI-Tooltip-Border]])
    rightDivider:SetTexCoord(0.81, 0.94, 0.5, 1)
    section.Header.RightDivider = rightDivider
    if APR.RegisterSkinTarget then APR:RegisterSkinTarget(header, "header") end

    return section
end

function APR:createStatusFrame()
    local backdropInfo =
    {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    }

    --Main frame
    local StatusFrame = CreateFrame('Frame', 'APRStatusReport', APR.UIParent, "BackdropTemplate")
    StatusFrame:SetPoint('CENTER', APR.UIParent, 'CENTER')
    StatusFrame:SetFrameStrata('HIGH')
    StatusFrame:SetBackdrop(backdropInfo)
    StatusFrame:SetBackdropColor(0, 0, 0, 0.6)
    StatusFrame:SetMovable(true)
    StatusFrame:SetSize(0, 35)
    StatusFrame:Hide()

    --Close button and script to retoggle the options.
    local CloseButton = CreateFrame('Button', nil, StatusFrame, 'UIPanelCloseButton')
    CloseButton:SetPoint('TOPRIGHT', StatusFrame, 'TOPRIGHT', -2, -2)
    CloseButton:HookScript('OnClick', closeClicked)

    --Title logo (drag to move frame)
    local titleLogoFrame = CreateFrame('Frame', nil, StatusFrame, 'TitleDragAreaTemplate')
    titleLogoFrame:SetPoint('CENTER', StatusFrame, 'TOP')
    titleLogoFrame:SetSize(240, 80)
    StatusFrame.TitleLogoFrame = titleLogoFrame

    local LogoTop = StatusFrame.TitleLogoFrame:CreateTexture(nil, 'ARTWORK')
    LogoTop:SetPoint('CENTER', titleLogoFrame, 'TOP', 0, -36)
    LogoTop:SetTexture("Interface\\AddOns\\APR\\APR-Core\\assets\\APR_logo")
    LogoTop:SetSize(64, 64)
    titleLogoFrame.LogoTop = LogoTop

    --CopyButton to export the infos
    local CopyButton = CreateFrame('Button', nil, StatusFrame, "StaticPopupButtonTemplate")
    CopyButton:SetPoint("BOTTOM", 0, 5)
    CopyButton:SetSize(100, 20)
    local CopyButtonFont = CopyButton:GetFontString()
    if not CopyButtonFont then
        CopyButtonFont = CopyButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        CopyButton:SetFontString(CopyButtonFont)
    end
    APR:RegisterFontString(CopyButtonFont, "general", { role = "base", sizeDelta = -3 })
    CopyButton:SetText(L["STATUS_EXPORT"])
    CopyButton:HookScript('OnClick', function() self:ExportStatusReport() end)
    StatusFrame.CopyButton = CopyButton

    local identityButton = CreateFrame('Button', nil, StatusFrame, "StaticPopupButtonTemplate")
    identityButton:SetPoint("BOTTOM", CopyButton, "TOP", 0, 5)
    identityButton:SetSize(290, 22)
    local identityFont = identityButton:GetFontString() or identityButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    identityButton:SetFontString(identityFont)
    self:RegisterFontString(identityFont, "general", { role = "base", sizeDelta = -3 })
    identityButton:SetScript("OnClick", function()
        hideIdentity = not hideIdentity
        self:updateStatusFrame()
        local report = APR.UI.reportWindow
        if report and report:IsShown() and report.reportOwner == StatusFrame then self:ExportStatusReport() end
    end)
    StatusFrame.IdentityButton = identityButton
    if APR.RegisterSkinTarget then
        APR:RegisterSkinTarget(StatusFrame, "panel")
        APR:RegisterSkinTarget(CloseButton, "close")
        APR:RegisterSkinTarget(CopyButton, "button")
        APR:RegisterSkinTarget(identityButton, "button")
    end

    --Create Static Content
    APR:createStatusStaticContent(StatusFrame)

    return StatusFrame
end

function APR:createStatusStaticContent(StatusFrame)
    local statusInfos = APR:getStatusReportInfos()

    --Section 1 AddOn & WoW Info
    StatusFrame.Section1 = APR:createStatusSection(300, 105, nil, 30, StatusFrame, 'TOP', StatusFrame, 'TOP', -30)
    StatusFrame.Section1.Content = APR:createStatusContent(5, 260, StatusFrame.Section1, StatusFrame.Section1.Header)
    StatusFrame.Section1.Header.Text:SetText(L["UI_STATUS_ADDON_CLIENT"])

    local wowVersionText = string.format("%s", statusInfos.wowVersion[2])
    SetStatusLine(StatusFrame.Section1.Content.Line1, statusInfos.aprVersion[1], statusInfos.aprVersion[2],
        APR.HEXColor.green)
    SetStatusLine(StatusFrame.Section1.Content.Line2, statusInfos.wowVersion[1], wowVersionText, APR.HEXColor.green)
    SetStatusLine(StatusFrame.Section1.Content.Line3, statusInfos.clientLanguage[1], statusInfos.clientLanguage[2],
        APR.HEXColor.green)
    SetStatusLine(StatusFrame.Section1.Content.Line4, statusInfos.serverType[1], statusInfos.serverType[2],
        APR.HEXColor.green)

    --Section 2 Route Info
    StatusFrame.Section2 = APR:createStatusSection(300, 105, nil, 30, StatusFrame, 'TOP', StatusFrame.Section1, 'BOTTOM',
        0)
    StatusFrame.Section2.Content = APR:createStatusContent(5, 260, StatusFrame.Section2, StatusFrame.Section2.Header)
    StatusFrame.Section2.Header.Text:SetText(L["UI_STATUS_CURRENT_ROUTE"])

    --Section 3 Character Info
    StatusFrame.Section3 = APR:createStatusSection(300, 120, nil, 30, StatusFrame, 'TOP', StatusFrame.Section2, 'BOTTOM',
        0)
    StatusFrame.Section3.Content = APR:createStatusContent(4, 260, StatusFrame.Section3, StatusFrame.Section3.Header)
    StatusFrame.Section3.Header.Text:SetText(L["UI_STATUS_CHARACTER"])

    local classText = statusInfos.charClass[2]:lower():gsub("^%l", string.upper)
    SetStatusLine(StatusFrame.Section3.Content.Line1, statusInfos.charFaction[1], statusInfos.charFaction[2],
        APR.HEXColor.green)
    SetStatusLine(StatusFrame.Section3.Content.Line4, statusInfos.charClass[1], classText, APR.HEXColor.green)
end

function APR:updateStatusFrame()
    local StatusFrame = APR.StatusFrame
    local statusInfos = APR:getStatusReportInfos()
    local statusColors = self:getStatusColors(statusInfos)
    local charName = statusInfos.charName and (statusInfos.charName[2] .. "-" .. statusInfos.charRealm[2])
        or self:LocalizeUI("HIDDEN")
    SetStatusLine(StatusFrame.Section3.Content.Line2, L["UI_STATUS_NAME"], charName, APR.HEXColor.green)
    StatusFrame.IdentityButton:SetText((hideIdentity and "[x] " or "[ ] ") .. self:LocalizeUI("REDACT"))

    local coordsText = statusInfos.currentCoords[2] .. " - (" .. statusInfos.currentWorldCoords[2] .. ')'
    SetStatusLine(StatusFrame.Section1.Content.Line5, statusInfos.currentTime[1], statusInfos.currentTime[2],
        APR.HEXColor.green)

    SetStatusLine(StatusFrame.Section2.Content.Line1, statusInfos.currentRoute[1], statusInfos.currentRoute[2],
        statusColors.currentRouteColor)
    SetStatusLine(StatusFrame.Section2.Content.Line2, statusInfos.currentStep[1], statusInfos.currentStep[2],
        statusColors.currentStepColor)
    SetStatusLine(StatusFrame.Section2.Content.Line3, statusInfos.currentContinent[1], statusInfos.currentContinent[2],
        statusColors.currentZoneColor)
    SetStatusLine(StatusFrame.Section2.Content.Line4, statusInfos.currentZone[1], statusInfos.currentZone[2],
        statusColors.currentZoneColor)
    SetStatusLine(StatusFrame.Section2.Content.Line5, statusInfos.currentCoords[1], coordsText,
        statusColors.currentCoordsColor)
    SetStatusLine(StatusFrame.Section3.Content.Line3, statusInfos.charLevel[1], statusInfos.charLevel[2],
        APR.HEXColor.green)
    self:RefreshStatusTextLayout()
end

function APR:showStatusReport()
    if not APR.StatusFrame then
        APR.StatusFrame = APR:createStatusFrame()
    end

    if not APR.StatusFrame:IsShown() then
        APR:updateStatusFrame()
        APR.StatusFrame:Raise() --Set framelevel above everything else
        APR.StatusFrame:Show()
    else
        APR:closeStatusReport()
    end
end

function APR:closeStatusReport()
    APR.StatusFrame:Hide()
    APR.settings:OpenSettings(APR.title)
end
