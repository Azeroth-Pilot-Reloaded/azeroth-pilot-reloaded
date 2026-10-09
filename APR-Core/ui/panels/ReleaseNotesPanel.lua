-- Release preferences and a selectable URL remain visible above independently scrolling notes.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local UI = APR.UI
APR.ReleaseNotesPanel = {}
local Panel = APR.ReleaseNotesPanel

function Panel:Create(parent)
    local page = setmetatable({rows = {}}, {__index = self})
    page.frame = CreateFrame("Frame", nil, parent)
    page.frame:SetAllPoints()
    page.preferences = UI:Section(page.frame, GAMEOPTIONS_MENU)
    page.preferences:SetPoint("TOPLEFT")
    page.preferences:SetPoint("TOPRIGHT")
    page.preferences:SetHeight(218)
    local controls = CreateFrame("Frame", nil, page.preferences)
    controls:SetPoint("TOPLEFT", 2, -34)
    controls:SetPoint("BOTTOMRIGHT", -2, 76)
    page.host = UI:SettingsHost(controls)

    local label = UI:Label(page.preferences, L["GITHUB_RELEASES"], 11, "muted")
    label:SetPoint("BOTTOMLEFT", 14, 53)
    label:SetPoint("BOTTOMRIGHT", -14, 53)
    local edit = CreateFrame("EditBox", nil, page.preferences, "BackdropTemplate")
    page.link = edit
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetTextInsets(10, 10, 0, 0)
    edit:SetPoint("BOTTOMLEFT", 14, 14)
    edit:SetPoint("BOTTOMRIGHT", -172, 14)
    edit:SetHeight(30)
    APR:RegisterSkinTarget(edit, "editbox", {themeSurface = true})
    APR:RegisterFontString(edit, "general", {role = "base"})
    edit:SetScript("OnEscapePressed", function() edit:ClearFocus() end)
    edit:SetScript("OnEditFocusGained", function() edit:HighlightText() end)
    edit:SetScript("OnTextChanged", function(_, userInput)
        if userInput then edit:SetText(page.url); edit:HighlightText() end
    end)
    page.copy = UI:Button(page.preferences, "GitHub · Ctrl+C", 144, function()
        edit:SetFocus(); edit:HighlightText()
    end)
    page.copy:SetPoint("BOTTOMRIGHT", -14, 14)
    UI:Tooltip(page.copy, L["COPY_HELPER"])
    page.notes = UI:Section(page.frame, L["UI_RELEASE_NOTES"])
    page.notes:SetPoint("TOPLEFT", page.preferences, "BOTTOMLEFT", 0, -12)
    page.notes:SetPoint("BOTTOMRIGHT")
    page.scroll = UI:Scroll(page.notes)
    page.scroll:SetPoint("TOPLEFT", 14, -40)
    page.scroll:SetPoint("BOTTOMRIGHT", -30, 14)
    page.content = CreateFrame("Frame", nil, page.scroll)
    page.scroll:SetScrollChild(page.content)
    page.scroll:HookScript("OnSizeChanged", function() page:Layout() end)
    return page
end

function Panel:Layout()
    if self.layingOut then return end
    self.layingOut = true
    local width, y = math.max(100, self.scroll:GetWidth()), 0
    self.content:SetWidth(width)
    for _, row in ipairs(self.rows) do
        if row:IsShown() then
            local block = row.block
            y = y + block.gap
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.content, "TOPLEFT", block.indent, -y)
            row:SetWidth(width - block.indent - 8)
            row:SetHeight(0)
            y = y + math.max(block.size + 4, row:GetStringHeight()) + 6
        end
    end
    self.content:SetHeight(math.max(1, y))
    self.scroll:SetVerticalScroll(math.min(self.scroll:GetVerticalScroll(), math.max(0, y - self.scroll:GetHeight())))
    self.layingOut = nil
end

function Panel:Show(app)
    self.frame:Show()
    self.url = APR.github:gsub("/+$", "") .. "/releases"
    self.link:SetText(self.url)
    LibStub("AceConfigDialog-3.0"):Open(app, self.host)
    self.layingOut = true
    for _, row in ipairs(self.rows) do row:Hide() end
    for index, block in ipairs(APR.changelog:GetBlocks()) do
        local row = self.rows[index]
        if not row then
            row = UI:Label(self.content, "")
            row:SetWordWrap(true)
            self.rows[index] = row
        end
        row.block = block
        row:SetText(block.text)
        row:Show()
        APR:RegisterFontString(row, "general", {role = block.role, sizeDelta = block.size - 12,
            themeAccent = true, onApplied = function() self:Layout() end})
    end
    self.layingOut = nil
    self:Layout()
    self.link:SetFocus()
    self.link:HighlightText()
end

function Panel:Hide()
    self.link:ClearFocus()
    self.host:ReleaseChildren()
    self.host:SetUserData("appName", nil)
    self.frame:Hide()
end
