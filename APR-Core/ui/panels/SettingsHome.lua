-- Presents daily settings first and searches the complete AceConfig option tree on demand.
-- Theme changes are immediate; external integrations explicitly defer their skin reset to /reload.

APR.SettingsHome = { query = "" }
local Home, UI = APR.SettingsHome, APR.UI
local function T(key) return APR:LocalizeUI(key) end

function Home:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    local records, query = {}, APR:NormalizeSearchText(self.query)
    for _, record in ipairs(APR.SettingsIndex:Build()) do
        if query == "" and record.priority or query ~= "" and record.search:find(query, 1, true) then
            records[#records + 1] = record
        end
    end
    self.list:SetItems(records, true)
    self.empty:SetShown(#records == 0)
    self.theme:SetOptions(self.themeOptions, APR.settings.profile.uiTheme or "wow")
    self.integration:SetOptions({ {value = "native", label = "APR"}, {value = "elvui", label = "ElvUI"},
        {value = "ellesmere", label = "EllesmereUI"}, {value = "auto", label = T("AUTOMATIC")} },
        APR.settings.profile.elvuiSkin and (APR.settings.profile.ellesmereuiSkin and "auto" or "elvui") or
        APR.settings.profile.ellesmereuiSkin and "ellesmere" or "native")
end

function Home:Create()
    local frame = UI:Window("APRSettingsHome", T("SETTINGS"), 940, 720)
    self.frame = frame
    local root = frame.content
    local navigation = { {"ROUTES", function() APR.RouteBrowser:Show() end},
        {"LAYOUT", function() APR.LayoutEditor:Show() end},
        {"PERFORMANCE", function() APR.PerformanceDashboard:Show() end},
        {"DIAGNOSTICS", function() APR:ShowDiagnostics() end} }
    for index, entry in ipairs(navigation) do
        local button = UI:Button(root, T(entry[1]), 150, entry[2])
        button:SetPoint("TOPLEFT", (index - 1) * 158, 0)
    end
    self.search = UI:SearchBox(root, 600, T("SEARCH_OPTIONS"), function(query) self.query = query; self:Refresh() end)
    self.search:SetPoint("TOPLEFT", 0, -42)
    self.search:SetPoint("TOPRIGHT", 0, -42)
    self.themeOptions = {}
    for _, key in ipairs(APR.ThemeOrder) do
        self.themeOptions[#self.themeOptions + 1] = {value = key, label = T(APR.Themes[key].label)}
    end
    local themeLabel = UI:Label(root, T("THEME"), 12, "muted")
    themeLabel:SetPoint("TOPLEFT", 0, -88)
    self.theme = UI:Select(root, 210, function(key) APR:SetTheme(key) end)
    self.theme:SetPoint("TOPLEFT", 0, -108)
    local integrationLabel = UI:Label(root, T("INTEGRATION"), 12, "muted")
    integrationLabel:SetPoint("TOPLEFT", 224, -88)
    self.integration = UI:Select(root, 210, function(value)
        APR.settings.profile.elvuiSkin = value == "elvui" or value == "auto"
        APR.settings.profile.ellesmereuiSkin = value == "ellesmere" or value == "auto"
        self.reloadHint:Show()
        self.reload:Show()
    end)
    self.integration:SetPoint("TOPLEFT", 224, -108)
    self.reload = UI:Button(root, T("RELOAD"), 188, function() if not InCombatLockdown() then C_UI.Reload() end end)
    self.reload:SetPoint("TOPLEFT", 448, -108)
    self.reload:Hide()
    self.reloadHint = UI:Label(root, T("RELOAD_HINT"), 12, "warning")
    self.reloadHint:SetPoint("TOPLEFT", 0, -149)
    self.reloadHint:SetPoint("TOPRIGHT", 0, -149)
    self.reloadHint:Hide()
    local scroll = UI:Scroll(root)
    scroll:SetPoint("TOPLEFT", 0, -180)
    scroll:SetPoint("BOTTOMRIGHT", -26, 50)
    self.list = APR.VirtualList:New(scroll, function(parent)
        local row = UI:Panel(parent)
        row.label = UI:Label(row, "", 14)
        row.label:SetPoint("TOPLEFT", 12, -10)
        row.label:SetPoint("TOPRIGHT", -125, -10)
        row.label:SetHeight(20)
        row.label:SetWordWrap(false)
        row.description = UI:Label(row, "", 11, "muted")
        row.description:SetPoint("TOPLEFT", 12, -34)
        row.description:SetPoint("BOTTOMRIGHT", -125, 8)
        row:EnableMouse(true)
        UI:Tooltip(row, function(control) return control.item.label end,
            function(control) return control.item.description end)
        row.action = UI:Button(row, "", 100, function()
            if not APR.SettingsIndex:Toggle(row.item) then APR.SettingsIndex:OpenAdvanced(row.item) end
            self:Refresh()
        end)
        row.action:SetPoint("RIGHT", -12, 0)
        return row
    end, function(row, record)
        row.label:SetText(record.label)
        row.description:SetText(record.description)
        local editable = record.option.type == "toggle" and not record.option.confirm and type(record.get) == "function"
        row.action:SetText(editable and (record.get(record.info) and T("ENABLED") or T("DISABLED")) or T("ADVANCED"))
        row.action:SetEnabled(not record.disabled and not InCombatLockdown())
    end, 84)
    self.empty = UI:Label(root, T("NO_RESULTS"), 13, "muted")
    self.empty:SetPoint("TOPLEFT", 12, -200)
    local advanced = UI:Button(root, T("ADVANCED"), 200, function() APR.SettingsIndex:OpenAdvanced() end)
    advanced:SetPoint("BOTTOMLEFT")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function() self:Refresh() end)
    frame:HookScript("OnShow", function() self:Refresh() end)
end

function Home:Show()
    if not self.frame then self:Create() end
    self.frame:Show()
    self:Refresh()
end
