local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LSM = LibStub("LibSharedMedia-3.0")

local CreateFrame = CreateFrame
local GetRealZoneText = GetRealZoneText

local UNKNOWN = "UNKNOWN"
local INSTANCE = "Instance"
local NO_ACTIVE = "No active route"
local font = LSM:Fetch('font', 'Expressway')

function APR:createStatusContent(num, width, parent, anchorTo, content)
    if not content then content = CreateFrame('Frame', nil, parent) end
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
            text:SetFont(font, 9, 'OUTLINE')
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

local function exportStatusReport()
    APR.questionDialog:CreateEditBoxPopup(L["COPY_HELPER"], L["CLOSE"],
        APR:tableToString(APR:getStatusReportInfos(), true))
end

function GetCurrentStepInfo()
    local currentStepID = APRData[APR.PlayerID][APR.ActiveRoute]
    local routeStep = NO_ACTIVE
    if currentStepID then
        local step = APR:GetStep(currentStepID)
        local _, key = APR:GetStepString(step)
        routeStep = currentStepID .. ", " .. key
    end

    return routeStep
end

function APR:getStatusReportInfos()
    local coordinates
    local worldCoordinates
    if APR:IsInstanceWithUI() and UnitPosition("player") then
        local playerPosition = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
        coordinates = APR.coordinate:RoundCoords(playerPosition.x * 100, playerPosition.y * 100, 2)
        local worldPosY, worldPosX = UnitPosition("player")
        worldCoordinates = APR.coordinate:RoundCoords(worldPosX, worldPosY, 2)
    end
    local currentStep = GetCurrentStepInfo()

    local infoTable = {
        aprVersion = { "AddOn Version", APR.version },
        wowVersion = { "Client Version", APR.wowpatch },
        wowBuildVersion = { "Client Build", APR.wowbuild },
        clientLanguage = { "Language", GetLocale() },
        currentTime = { "Time & Date", date() },
        currentRoute = { "Route", APR.ActiveRoute or NO_ACTIVE },
        currentStep = { "Step", currentStep or NO_ACTIVE },
        currentZone = { "Zone", GetRealZoneText() or UNKNOWN },
        currentContinent = { "Continent", C_Map.GetMapInfo(APR:GetContinent()).name },
        currentCoords = { "Coordinates", coordinates or INSTANCE },
        currentWorldCoords = { "World Coordinates", worldCoordinates or INSTANCE },
        charFaction = { "Faction", APR.Faction },
        charName = { "Name", APR.Username },
        charRealm = { "Realm", GetRealmName() },
        charLevel = { "Level", APR.Level },
        charClass = { "Class", APR.ClassName }
    }

    return infoTable
end

function APR:getStatusColors()
    local infoTable = APR:getStatusReportInfos()
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

    local font = LSM:Fetch('font', 'Expressway')
    local text = section.Header:CreateFontString(nil, 'ARTWORK')
    text:SetPoint('TOP')
    text:SetPoint('BOTTOM')
    text:SetJustifyH('CENTER')
    text:SetJustifyV('MIDDLE')
    text:SetFont(font, 18, 'OUTLINE')
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
    local CloseButton = CreateFrame('Button', nil, StatusFrame)
    CloseButton:SetSize(16, 16)
    CloseButton:SetPoint('TOPRIGHT', StatusFrame, 'TOPRIGHT', -6, -6)
    CloseButton:CreateTexture()
    CloseButton.Texture = CloseButton:CreateTexture(nil, 'OVERLAY')
    CloseButton.Texture:SetAllPoints()
    CloseButton.Texture:SetTexture("Interface\\AddOns\\APR\\APR-Core\\assets\\Close")
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
    local CopyButtonFont = CopyButton:CreateFontString()
    CopyButtonFont:SetFont(font, 9)
    CopyButtonFont:SetText(L["STATUS_EXPORT"])
    CopyButton:SetFontString(CopyButtonFont)
    CopyButton:HookScript('OnClick', exportStatusReport)

    --Create Static Content
    APR:createStatusStaticContent(StatusFrame)

    return StatusFrame
end

function APR:createStatusStaticContent(StatusFrame)
    local statusInfos = APR:getStatusReportInfos()

    --Section 1 AddOn & WoW Info
    StatusFrame.Section1 = APR:createStatusSection(300, 90, nil, 30, StatusFrame, 'TOP', StatusFrame, 'TOP', -30)
    StatusFrame.Section1.Content = APR:createStatusContent(4, 260, StatusFrame.Section1, StatusFrame.Section1.Header)
    StatusFrame.Section1.Header.Text:SetFormattedText('Addon & Client|r')

    StatusFrame.Section1.Content.Line1.Text:SetFormattedText(
        statusInfos.aprVersion[1] .. ': |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.aprVersion[2])
    StatusFrame.Section1.Content.Line2.Text:SetFormattedText(
        statusInfos.wowVersion[1] .. ': |cff' .. APR.HEXColor.green .. '%s (build %s)|r', statusInfos.wowVersion[2],
        statusInfos.wowBuildVersion[2])
    StatusFrame.Section1.Content.Line3.Text:SetFormattedText(
        statusInfos.clientLanguage[1] .. ': |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.clientLanguage[2])

    --Section 2 Route Info
    StatusFrame.Section2 = APR:createStatusSection(300, 105, nil, 30, StatusFrame, 'TOP', StatusFrame.Section1, 'BOTTOM',
        0)
    StatusFrame.Section2.Content = APR:createStatusContent(5, 260, StatusFrame.Section2, StatusFrame.Section2.Header)
    StatusFrame.Section2.Header.Text:SetFormattedText('Current Route|r')

    --Section 3 Character Info
    StatusFrame.Section3 = APR:createStatusSection(300, 120, nil, 30, StatusFrame, 'TOP', StatusFrame.Section2, 'BOTTOM',
        0)
    StatusFrame.Section3.Content = APR:createStatusContent(6, 260, StatusFrame.Section3, StatusFrame.Section3.Header)
    StatusFrame.Section3.Header.Text:SetFormattedText('Character|r')

    StatusFrame.Section3.Content.Line1.Text:SetFormattedText(
        statusInfos.charFaction[1] .. ': |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.charFaction[2])
    StatusFrame.Section3.Content.Line2.Text:SetFormattedText(
        statusInfos.charName[1] .. ': |cff' .. APR.HEXColor.green .. '%s|r',
        statusInfos.charName[2] .. "-" .. statusInfos.charRealm[2])
    StatusFrame.Section3.Content.Line4.Text:SetFormattedText(
        statusInfos.charClass[1] .. ': |cff' .. APR.HEXColor.green .. '%s|r',
        statusInfos.charClass[2]:lower():gsub("^%l", string.upper))
end

function APR:updateStatusFrame()
    local StatusFrame = APR.StatusFrame
    local statusInfos = APR:getStatusReportInfos()
    local statusColors = APR:getStatusColors()

    StatusFrame.Section1.Content.Line4.Text:SetFormattedText(
        statusInfos.currentTime[1] .. ': |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.currentTime[2])

    StatusFrame.Section2.Content.Line1.Text:SetFormattedText(
        statusInfos.currentRoute[1] .. ': |cff' .. statusColors.currentRouteColor .. '%s|r', statusInfos.currentRoute[2])
    StatusFrame.Section2.Content.Line2.Text:SetFormattedText(
        statusInfos.currentStep[1] .. ': |cff' .. statusColors.currentStepColor .. '%s|r', statusInfos.currentStep[2])
    StatusFrame.Section2.Content.Line3.Text:SetFormattedText(
        statusInfos.currentContinent[1] .. ': |cff' .. statusColors.currentZoneColor .. '%s|r',
        statusInfos.currentContinent[2])
    StatusFrame.Section2.Content.Line4.Text:SetFormattedText(
        statusInfos.currentZone[1] .. ': |cff' .. statusColors.currentZoneColor .. '%s|r', statusInfos.currentZone[2])
    StatusFrame.Section2.Content.Line5.Text:SetFormattedText(
        statusInfos.currentCoords[1] .. ': |cff' .. statusColors.currentCoordsColor .. '%s|r',
        statusInfos.currentCoords[2] .. " - (" .. statusInfos.currentWorldCoords[2] .. ')')
    StatusFrame.Section3.Content.Line3.Text:SetFormattedText(
        statusInfos.charLevel[1] .. ': |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.charLevel[2])
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
