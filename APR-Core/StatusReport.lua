local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LSM = LibStub("LibSharedMedia-3.0")

local CreateFrame = CreateFrame
local GetRealZoneText = GetRealZoneText

local UNKNOWN = APR.HEXColor.red .. "UNKNOWN"
local NO_ACTIVE = "No active route"

function APR:createStatusContent(num, width, parent, anchorTo, content)
	if not content then content = CreateFrame('Frame', nil, parent) end
	content:SetSize(width, (num * 20) + ((num-1)*5)) --20 height and 5 spacing
	content:SetPoint('TOP', anchorTo, 'BOTTOM')

	local font = LSM:Fetch('font', 'Expressway')
	for i = 1, num do
		if not content['Line'..i] then
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
				line:SetPoint('TOP', content['Line'..(i-1)], 'BOTTOM', 0, -5)
			end

			content['Line'..i] = line
		end
	end

	return content
end

local function exportStatusReport()
	APR.questionDialog:CreateEditBoxPopup(L["COPY_HELPER"], L["CLOSE"],  
	APR:tableToString(APR:getStatusReportInfos(), true))
end

function APR:getStatusReportInfos()
	local playerPosition = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"),"player")
	local coordinates = math.ceil(playerPosition.x*10000)/100 .. " " .. math.ceil(playerPosition.y*10000)/100

	local infoTable = {
		aprVersion = {"APR-Version", APR.version},
		wowVersion = {"Version of WoW", APR.wowpatch},
		wowBuildVersion = {"Build", APR.wowbuild},
		clientLanguage = {"Client-Language", GetLocale()},
		currentRoute = {"Current Route", APR.ActiveRoute or NO_ACTIVE},
		currentStep = {"Current Step", APRData[APR.PlayerID][APR.ActiveRoute] or NO_ACTIVE},
		currentZone = {"Current Zone", GetRealZoneText() or UNKNOWN},
		currentCoords = {"Coordinates", coordinates or UNKNOWN},
		charFaction = {"Faction", APR.Faction},
		charName = {"Name", APR.Username},
		charLevel = {"Level", APR.Level},
		charClass = {"Class", APR.ClassName}
	}

	return infoTable
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
	CloseButton.Texture:SetTexture("Interface\\AddOns\\APR-Core\\assets\\Close")
	CloseButton:HookScript('OnClick', closeClicked)

	--Title logo (drag to move frame)
	local titleLogoFrame = CreateFrame('Frame', nil, StatusFrame, 'TitleDragAreaTemplate')
	titleLogoFrame:SetPoint('CENTER', StatusFrame, 'TOP')
	titleLogoFrame:SetSize(240, 80)
	StatusFrame.TitleLogoFrame = titleLogoFrame

	local LogoTop = StatusFrame.TitleLogoFrame:CreateTexture(nil, 'ARTWORK')
	LogoTop:SetPoint('CENTER', titleLogoFrame, 'TOP', 0, -36)
	LogoTop:SetTexture("Interface\\AddOns\\APR-Core\\assets\\APR_logo")
	LogoTop:SetSize(64, 64)
	titleLogoFrame.LogoTop = LogoTop

	--CopyButton to export the infos - TODO Styling
	local CopyButton = CreateFrame('Button', nil, StatusFrame)
	CopyButton:SetPoint("BOTTOM", StatusFrame, "BOTTOM", 0, 0)
	CopyButton:SetWidth(100)
	CopyButton:SetHeight(30)
    CopyButton:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Up")
	CopyButton:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	CopyButton:SetPushedTexture("Interface/Buttons/UI-Panel-Button-Down")
	local CopyButtonFont = CopyButton:CreateFontString()
	CopyButtonFont:SetFont("Fonts/FRIZQT__.TTF", 9)
	CopyButtonFont:SetPoint("LEFT", CopyButton, "LEFT")
	CopyButtonFont:SetText("Export")
	CopyButton:SetFontString(CopyButtonFont)
	CopyButton:HookScript('OnClick', exportStatusReport)

	--Create Static Content
	APR:createStatusStaticContent(StatusFrame)

	return StatusFrame
end

function APR:createStatusStaticContent(StatusFrame)
	local statusInfos = APR:getStatusReportInfos()
	
	--Section 1 AddOn & WoW Info
	StatusFrame.Section1 = APR:createStatusSection(300, 80, nil, 30, StatusFrame, 'TOP', StatusFrame, 'TOP', -30)
	StatusFrame.Section1.Content = APR:createStatusContent(4, 260, StatusFrame.Section1, StatusFrame.Section1.Header)
	StatusFrame.Section1.Header.Text:SetFormattedText('AddOn & WoW Info|r')

	StatusFrame.Section1.Content.Line1.Text:SetFormattedText('Version of APR: |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.aprVersion[2]) --ToDo: Check if Addon outdated
	StatusFrame.Section1.Content.Line2.Text:SetFormattedText('Version of WoW: |cff' .. APR.HEXColor.green .. '%s (build %s)|r', statusInfos.wowVersion[2], statusInfos.wowBuildVersion[2])
	StatusFrame.Section1.Content.Line3.Text:SetFormattedText('Client Language: |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.clientLanguage[2])

    --Section 2 Route Info
	StatusFrame.Section2 = APR:createStatusSection(300, 95, nil, 30, StatusFrame, 'TOP', StatusFrame.Section1, 'BOTTOM', 0)
	StatusFrame.Section2.Content = APR:createStatusContent(5, 260, StatusFrame.Section2, StatusFrame.Section2.Header)
	StatusFrame.Section2.Header.Text:SetFormattedText('Route Info|r')
    
	--Section 3 Character Info
	StatusFrame.Section3 = APR:createStatusSection(300, 120, nil, 30, StatusFrame, 'TOP', StatusFrame.Section2, 'BOTTOM', 0)
	StatusFrame.Section3.Content = APR:createStatusContent(6, 260, StatusFrame.Section3, StatusFrame.Section3.Header)
	StatusFrame.Section3.Header.Text:SetFormattedText('Character Info|r')

	StatusFrame.Section3.Content.Line1.Text:SetFormattedText('Faction: |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.charFaction[2])
	StatusFrame.Section3.Content.Line2.Text:SetFormattedText('Name: |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.charName[2])
	StatusFrame.Section3.Content.Line4.Text:SetFormattedText('Class: |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.charClass[2])
end

function APR:updateStatusFrame()
	local StatusFrame = APR.StatusFrame
	local statusInfos = APR:getStatusReportInfos()
	local color = APR.HEXColor.green

	if statusInfos.currentRoute[2] == NO_ACTIVE then
		color = APR.HEXColor.red
	end

	StatusFrame.Section2.Content.Line1.Text:SetFormattedText('Current Route: |cff' .. color ..'%s|r', statusInfos.currentRoute[2])
	StatusFrame.Section2.Content.Line2.Text:SetFormattedText('Current Step: |cff' .. color ..'%s|r', statusInfos.currentStep[2])
	StatusFrame.Section2.Content.Line3.Text:SetFormattedText('Current Zone: |cff4beb2c%s|r', statusInfos.currentZone[2])
	StatusFrame.Section2.Content.Line4.Text:SetFormattedText('Coordinates: |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.currentCoords[2])

	StatusFrame.Section3.Content.Line3.Text:SetFormattedText('Level: |cff' .. APR.HEXColor.green .. '%s|r', statusInfos.charLevel[2])
end

function APR:getCurrentRouteInfos()
	local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"),"player")
	pos = math.ceil(pos.x*10000)/100 .. " " .. math.ceil(pos.y*10000)/100
	
	return ActiveRoute, CurrentStep, pos, color
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