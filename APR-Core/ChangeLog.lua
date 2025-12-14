local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

APR.changelog = APR:NewModule("ChangeLog")


---------------------------------------------------------------------------------------
--------------------------------- Change log Frames -----------------------------------
---------------------------------------------------------------------------------------

local ChangeLogFrame = CreateFrame("Frame", "ChangeLogFrame", UIParent, "BackdropTemplate")
ChangeLogFrame:SetSize(600, 500)
ChangeLogFrame:SetPoint("CENTER", 0, 0)
ChangeLogFrame:SetFrameStrata("FULLSCREEN")
ChangeLogFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 16
})
ChangeLogFrame:SetBackdropColor(unpack(APR.Color.defaultBackdrop))
ChangeLogFrame:EnableMouse(true)

local headerFrame = CreateFrame('Frame', nil, ChangeLogFrame, 'TitleDragAreaTemplate')
headerFrame:SetPoint('CENTER', ChangeLogFrame, 'TOP')
headerFrame:SetSize(600, 150)

local CloseButton = CreateFrame("Button", nil, headerFrame, "UIPanelCloseButton")
CloseButton:SetSize(16, 16)
CloseButton:SetPoint("TOPRIGHT", headerFrame, "TOPRIGHT", 0, -10)
CloseButton:SetScript("OnClick", function()
    ChangeLogFrame:Hide()
end)

local headerTexture = headerFrame:CreateTexture(nil, "ARTWORK")
headerTexture:SetSize(600, 150)
headerTexture:SetPoint("TOP", headerFrame, "TOP", 0, 0)
headerTexture:SetTexture("Interface\\Addons\\APR\\APR-Core\\assets\\header")

local function GetGitHubReleasesUrl()
    local base = APR and APR.github or nil
    if type(base) ~= "string" or base == "" then
        return "https://github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded/releases"
    end
    base = base:gsub("/+$", "")
    return base .. "/releases"
end

local footerFrame = CreateFrame("Frame", nil, ChangeLogFrame)
footerFrame:SetPoint("BOTTOMLEFT", ChangeLogFrame, "BOTTOMLEFT", 16, 12)
footerFrame:SetPoint("BOTTOMRIGHT", ChangeLogFrame, "BOTTOMRIGHT", -16, 12)
footerFrame:SetHeight(22)

local footerButton = CreateFrame("Button", nil, footerFrame, "BackdropTemplate")
footerButton:SetAllPoints(footerFrame)
footerButton:EnableMouse(true)

local footerText = footerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
footerText:SetPoint("CENTER", footerFrame, "CENTER", 0, 0)
footerText:SetJustifyH("CENTER")
footerText:SetWordWrap(true)
footerText:SetWidth(ChangeLogFrame:GetWidth() - 60)
footerText:SetTextColor(0.35, 0.75, 1)

footerButton:SetScript("OnEnter", function(self)
    local url = GetGitHubReleasesUrl()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Click to copy the GitHub releases link", 1, 1, 1, true)
    GameTooltip:AddLine(url, 0.35, 0.75, 1, true)
    GameTooltip:Show()
end)

footerButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

footerButton:SetScript("OnClick", function()
    local url = GetGitHubReleasesUrl()
    if APR.questionDialog and APR.questionDialog.CreateEditBoxPopup then
        APR.questionDialog:CreateEditBoxPopup(L["COPY_HELPER"], CLOSE, url)
        return
    end
    print(url)
end)

local ScrollFrame = CreateFrame("ScrollFrame", "ChangeLogScrollFrame", ChangeLogFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", ChangeLogFrame, "TOPLEFT", 16, -68)
ScrollFrame:SetPoint("BOTTOMRIGHT", footerFrame, "TOPRIGHT", -24, 8)

local TextFrame = CreateFrame("Frame", nil, ScrollFrame)
ScrollFrame:SetScrollChild(TextFrame)

local Text = TextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Text:SetPoint("TOPLEFT", 10, -10)
Text:SetJustifyH("LEFT")
Text:SetWordWrap(true)

local function RefreshChangeLogLayout()
    local scrollWidth = ScrollFrame:GetWidth() or 0
    local scrollHeight = ScrollFrame:GetHeight() or 0

    if scrollWidth <= 0 then
        scrollWidth = (ChangeLogFrame:GetWidth() or 600) - 40
    end
    if scrollHeight <= 0 then
        scrollHeight = (ChangeLogFrame:GetHeight() or 500) - 120
    end

    TextFrame:SetWidth(scrollWidth)
    TextFrame:SetHeight(scrollHeight)
    Text:SetWidth(scrollWidth - 20)
    footerText:SetWidth((ChangeLogFrame:GetWidth() or 600) - 60)
end

ChangeLogFrame:HookScript("OnShow", RefreshChangeLogLayout)
ChangeLogFrame:HookScript("OnSizeChanged", RefreshChangeLogLayout)

---------------------------------------------------------------------------------------
------------------------------ Function Party Frames ----------------------------------
---------------------------------------------------------------------------------------

function APR.changelog:OnInit()
    LibWindow.RegisterConfig(ChangeLogFrame, APR.settings.profile.changeLogFrame)
    ChangeLogFrame.RegisteredForLibWindow = true
    LibWindow.MakeDraggable(ChangeLogFrame)
    RefreshChangeLogLayout()
    self:SetChangeLog()
    ChangeLogFrame:Hide()

    if APR.version ~= APR.settings.profile.lastRecordedVersion then
        if APR.settings.profile.showChangeLog then
            self:ShowChangeLog()
        end
    end
end

function APR.changelog:ShowChangeLog()
    ChangeLogFrame:Show()
    LibWindow.RestorePosition(ChangeLogFrame)
end

function APR.changelog:ParseFormatting(text)
    -- Bold + Italic: ***text*** -> orange
    text = text:gsub("%*%*%*(.-)%*%*%*", "|cffff8800%1|r")

    -- Bold: **text** -> blue
    text = text:gsub("%*%*(.-)%*%*", "|cff00ffff%1|r")

    -- Italic: *text* -> gray
    text = text:gsub("%*(.-)%*", "|cff999999%1|r")

    return text
end

-- Parse full changelog text
function APR.changelog:ParseChangelogText(text)
    local formatted = "|cFFF1F1F1|c33ecc00f" .. APR.title .. "|r"

    for line in text:gmatch("[^\r\n]+") do
        if line:match("^v%d+%.%d+%.%d+") then
            -- Match version line: vX.Y.Z (YYYY-MM-DD)
            local version, date = line:match("^(v%d+%.%d+%.%d+)%s*%((.-)%)")
            if version and date then
                formatted = formatted .. "\n\n|cFFFFFF00" .. version .. " (|cFFFF8800" .. date .. "|r):|r\n"
            end
        elseif line ~= "" and not line:match("^#") then
            -- Regular line
            formatted = formatted .. self:ParseFormatting(line) .. "\n"
        elseif line:match("^#") then
            -- Category line
            formatted = formatted .. "\n|cffeda55f" .. line .. "|r" .. "\n"
        else
            formatted = formatted .. " \n"
        end
    end

    return formatted
end

function APR.changelog:SetChangeLog()
    local changelog = self:ParseChangelogText(L["CHANGELOG"])
    Text:SetText(changelog)
    TextFrame:SetHeight(Text:GetStringHeight())

    local url = GetGitHubReleasesUrl()
    footerText:SetText(L["GITHUB_RELEASES"])
end
