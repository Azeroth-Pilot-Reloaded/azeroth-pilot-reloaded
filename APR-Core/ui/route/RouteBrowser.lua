-- Prefabs first, then a dense expansion catalog beside the ordered custom path.
-- Search/filter/sort only read metadata; virtual lists allocate controls for the viewport, not the catalog.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local UI = APR.UI
APR.RouteBrowser = {filters = {sort = "label"}}
local Browser = APR.RouteBrowser

function Browser:SetScope(value)
    self.filters.expansion = value ~= "all" and value ~= "community" and value or nil
    self.filters.community = value == "community"
    self.filters.query, self.searchExpansion = "", nil
    self.settingSearch = true
    self.search:SetText("")
    self.search.placeholder:Show()
    self.settingSearch = false
    self:Refresh(false, true)
end

-- Navigation starts at the top; path edits keep the reader's place in the catalog.
function Browser:Refresh(rebuild, resetScroll)
    if not self.frame or not self.frame:IsShown() then self.dirty = true; return end
    if rebuild or self.dirty or not self.records then self.records = APR.RouteCatalog:Build(); self.dirty = false end
    local navigation = APR.RouteCatalog:GetNavigation(self.records)
    if not self.initialized then
        local route = APR.ActiveRoute and APR:GetRouteData(APR.ActiveRoute)
        self.filters.expansion = route and route.expansion
        if not self.filters.expansion then
            for _, item in ipairs(navigation) do
                if item.value ~= "all" and item.value ~= "community" and (item.count or 0) > 0 then
                    self.filters.expansion = item.value; break
                end
            end
        end
        self.initialized = true
    end
    local options, categories = APR.RouteCatalog:GetCategories(self.records, self.filters)
    if self.category.menu then self.category.menu:Hide() end
    if self.filters.category and not categories[self.filters.category] then self.filters.category = nil end
    self.category:SetOptions(options, self.filters.category or false)
    UI:SetButtonActive(self.favorites, self.filters.favorites)
    UI:SetIcon(self.favorites.icon, self.filters.favorites and "favorite" or "favorite-outline")
    local queued = {}
    for _, label in ipairs(APR.RouteCatalog:GetPath()) do queued[label] = true end
    for _, record in ipairs(self.records) do record.queued = queued[record.label] end
    local records = APR.RouteCatalog:Filter(self.records, self.filters)
    self.list:SetItems(records, not resetScroll)
    self.navigation:SetItems(navigation, true)
    self.pathList:SetItems(APR.RouteCatalog:GetPathRecords(self.records), true)
    local scope = self.filters.community and CLUB_FINDER_COMMUNITY_TYPE or self.filters.expansion or ALL
    local scopeValue = self.filters.community and "community" or self.filters.expansion or "all"
    local scopeCount = navigation[1].count
    for _, item in ipairs(navigation) do
        if item.value == scopeValue then scopeCount = item.count end
    end
    self.count:SetText(scope .. " (" .. #records .. (#records ~= scopeCount and " / " .. scopeCount or "") .. ")")
    self.pathTitle:SetText(L["CUSTOM_PATH"] .. " (" .. #APR.RouteCatalog:GetPath() .. ")")
    self.clearPath:SetEnabled(#APR.RouteCatalog:GetPath() > 0)
    self.empty:SetShown(#records == 0)
    self.pathEmpty:SetShown(#APR.RouteCatalog:GetPath() == 0)
    for key, header in pairs(self.headers) do
        UI:SetIcon(header.icon, self.filters.descending and "down" or "up")
        header.icon:SetShown(self.filters.sort == key)
        APR:SetFontStringRole(header:GetFontString(), self.filters.sort == key and "accent" or "base")
    end
end

function Browser:CreateNavigation(root)
    self.navScroll = UI:Scroll(root)
    self.navigation = APR.VirtualList:New(self.navScroll, function(parent)
        local row = CreateFrame("Button", nil, parent)
        row.text = UI:Label(row, "", 11)
        row.text:SetPoint("LEFT", 6, 0)
        row.text:SetPoint("RIGHT", -34, 0)
        row.text:SetWordWrap(true)
        row.text:SetHeight(32)
        row.count = UI:Label(row, "", 11, "muted")
        row.count:SetPoint("RIGHT", -4, 0)
        row.background = row:CreateTexture(nil, "BACKGROUND")
        row.background:SetAllPoints()
        row.marker = row:CreateTexture(nil, "ARTWORK")
        row.marker:SetPoint("TOPLEFT", 0, -4)
        row.marker:SetPoint("BOTTOMLEFT", 0, 4)
        row.marker:SetWidth(2)
        APR:RegisterThemeRegion(row.marker, "accent")
        row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
        row.highlight:SetAllPoints()
        APR:RegisterThemeRegion(row.highlight, "accent", 0.08)
        row:SetScript("OnClick", function() if row.item.value then self:SetScope(row.item.value) end end)
        UI:Tooltip(row, function() return row.item and row.item.label end)
        return row
    end, function(row, item)
        row.text:SetText(item.label)
        row.count:SetText(item.count and tostring(item.count) or "")
        row:SetEnabled(not item.heading)
        APR:SetFontStringRole(row.text, item.heading and "muted" or item.value == "community" and "accent" or "base")
        local selected = not item.heading and item.value == (self.filters.community and "community" or self.filters.expansion or "all")
        APR:RegisterThemeRegion(row.background, "selection", selected and 0.28 or 0)
        row.marker:SetShown(selected)
    end, 34)
end

function Browser:Create()
    local frame = UI:Window("APRRouteBrowser", L["ROUTE_SELECTION"], 1240, 780, "library", "logo")
    local minimumWidth, minimumHeight = math.min(880, UIParent:GetWidth() - 40), math.min(560, UIParent:GetHeight() - 60)
    frame:SetResizeBounds(minimumWidth, minimumHeight)
    frame:SetSize(math.max(minimumWidth, frame:GetWidth()), math.max(minimumHeight, frame:GetHeight()))
    self.frame = frame
    local root = frame.content
    frame.headerLine = frame.header:CreateTexture(nil, "ARTWORK")
    frame.headerLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 72, -50)
    frame.headerLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -50)
    frame.headerLine:SetHeight(1)
    APR:RegisterThemeRegion(frame.headerLine, "border", 0.55)
    self.prefabPanel = UI:Section(root, L["UI_ROUTE_PREFABS"], "stone")
    self.prefabTitle = self.prefabPanel.title
    self.prefabs = {}
    local definitions = {
        {label = "SPEEDRUN", tooltip = "SPEEDRUN_TOOLTIPS", action = function()
            APRCustomPath[APR.PlayerID] = {}; APR.routeconfig:GetSpeedRunPrefab()
        end},
        {label = "LEVELING_PREFAB", tooltip = "LEVELING_TOOLTIPS", action = function() APR.routeconfig:OpenLevelingPopup() end},
        {label = "ALL_QUESTS", tooltip = "ALL_QUESTS_TOOLTIPS", action = function() APR.routeconfig:OpenAllQuestsPopup() end},
    }
    for index, definition in ipairs(definitions) do
        local button = UI:Button(self.prefabPanel, L[definition.label], 200, definition.action, "raised")
        UI:Tooltip(button, L[definition.label], L[definition.tooltip])
        self.prefabs[index] = button
    end
    self.filterPanel = UI:Panel(root, "borderedPanel", "inset")
    self.search = UI:SearchBox(self.filterPanel, 350, SEARCH, function(query)
        if self.settingSearch then return end
        if query ~= "" and (not self.filters.query or self.filters.query == "") then
            self.searchExpansion, self.filters.expansion = self.filters.expansion, nil
        elseif query == "" then
            self.filters.expansion, self.searchExpansion = self.searchExpansion, nil
        end
        self.filters.query = query
        self:Refresh(false, true)
    end)
    UI:Tooltip(self.search, SEARCH, L["UI_ROUTE_SEARCH_HELP"])
    self.typeLabel = UI:Label(self.filterPanel, TYPE, 11, "muted")
    self.category = UI:Select(self.filterPanel, 195, function(value) self.filters.category = value or nil; self:Refresh(false, true) end)
    self.favorites = UI:Button(self.filterPanel, FAVORITES, 140, function()
        self.filters.favorites = not self.filters.favorites; self:Refresh(false, true)
    end)
    UI:ButtonIcon(self.favorites, "favorite", 18)
    self.reset = UI:Button(self.filterPanel, RESET, 100, function()
        self.filters = {sort = "label"}; self:SetScope("all")
    end)
    self.navigationPanel = UI:Panel(root, "borderedPanel", "stone")
    self:CreateNavigation(self.navigationPanel)
    self.catalogPanel = UI:Section(root, "", "inset")
    self.count = self.catalogPanel.title
    self.headerBand = self.catalogPanel:CreateTexture(nil, "BACKGROUND")
    APR:RegisterThemeRegion(self.headerBand, "border", 0.18)
    self.scroll = UI:Scroll(self.catalogPanel)
    self.list = APR.VirtualList:New(self.scroll, function(parent) return APR.RouteBrowserRows:Create(parent, self) end,
        function(row, record, index) APR.RouteBrowserRows:Bind(row, record, index, self) end, 26)
    self.headers, self.headerLabels = {}, {label = NAME, category = TYPE, author = string.format(L["AUTHOR"], ""), status = STATUS}
    for _, key in ipairs({"label", "category", "author", "status"}) do
        local field = key
        local header = UI:ColumnHeader(self.catalogPanel, self.headerLabels[field], function()
            self.filters.descending = self.filters.sort == field and not self.filters.descending or false
            self.filters.sort = field; self:Refresh(false, true)
        end)
        self.headers[field] = header
    end
    self.empty = UI:Label(self.catalogPanel, L["UI_ROUTE_NO_RESULTS"], 12, "muted")
    self.pathPanel = UI:Section(root, L["CUSTOM_PATH"], "stone")
    self.pathTitle = self.pathPanel.title
    self.pathScroll = UI:Scroll(self.pathPanel)
    self.pathList = APR.VirtualList:New(self.pathScroll, function(parent) return APR.RouteBrowserRows:Create(parent, self, true) end,
        function(row, record, index) APR.RouteBrowserRows:Bind(row, record, index, self, true) end, 26)
    self.pathEmpty = UI:Label(self.pathPanel, L["UI_ROUTE_PATH_EMPTY"], 12, "muted")
    self.clearPath = UI:Button(self.pathPanel, L["CLEAR"], 120, function()
        UI:ShowConfirmationDialog(L["CLEAR_CUSTOM_PATH"], function()
            APRCustomPath[APR.PlayerID] = {}; APR.routeconfig:SendCustomPathUpdate()
        end, nil, self.frame)
    end)
    self.hint = UI:Label(root, L["UI_ROUTE_SHORTCUTS"], 11, "muted")
    self.legend = CreateFrame("Frame", nil, root)
    self.legend.items = {}
    for _, state in ipairs({"completed", "inProgress", "notStarted"}) do
        local progress = APR.RouteCatalog.progressStates[state]
        local entry = CreateFrame("Frame", nil, self.legend)
        entry.marker = entry:CreateTexture(nil, "ARTWORK")
        entry.marker:SetPoint("LEFT")
        entry.marker:SetSize(3, 12)
        APR:RegisterThemeRegion(entry.marker, progress.role)
        entry.text = UI:Label(entry, progress.label, 11, progress.role)
        entry.text:SetPoint("LEFT", 9, 0)
        self.legend.items[#self.legend.items + 1] = entry
        APR:RegisterFontString(entry.text, "general", {role = progress.role, sizeDelta = -1,
            onApplied = function() self:Layout() end})
    end
    APR:RegisterFontString(self.hint, "general", {role = "muted", sizeDelta = -1,
        onApplied = function() self:Layout() end})
    frame:HookScript("OnSizeChanged", function() self:Layout() end)
    frame:HookScript("OnShow", function() self:Refresh(true) end)
    frame:HookScript("OnHide", function() self.search:ClearFocus() end)
    self:Layout()
end

function Browser:Layout()
    if not self.frame or not self.pathList then return end
    local width, height = self.frame:GetWidth() - 32, self.frame:GetHeight() - 74
    local navWidth, pathWidth = width < 1060 and 156 or 180, width < 1060 and 244 or 292
    local tableLeft, pathLeft = navWidth + 12, width - pathWidth
    -- The existing shortcut translation is a list; reserve its measured height in every locale.
    self.hint:SetWidth(width - tableLeft)
    local hintHeight = math.max(20, self.hint:GetStringHeight())
    local tableWidth, panelHeight = pathLeft - tableLeft - 12, height - 164 - hintHeight
    local function place(region, x, y, w, h)
        region:ClearAllPoints()
        region:SetPoint("TOPLEFT", region:GetParent(), "TOPLEFT", x, -y)
        region:SetSize(w, h)
    end
    place(self.prefabPanel, 0, 0, width, 74)
    local prefabWidth = (width - 44) / 3
    for index, button in ipairs(self.prefabs) do
        place(button, 12 + (index - 1) * (prefabWidth + 10), 34, prefabWidth, 30)
    end
    place(self.filterPanel, 0, 82, width, 46)
    place(self.search, 10, 8, width - 508, 30)
    place(self.typeLabel, width - 490, 8, 32, 30)
    place(self.category, width - 450, 8, 180, 30)
    place(self.favorites, width - 262, 8, 132, 30)
    place(self.reset, width - 122, 8, 112, 30)
    place(self.navigationPanel, 0, 138, navWidth, panelHeight)
    place(self.navScroll, 8, 8, navWidth - 34, panelHeight - 16)
    place(self.catalogPanel, tableLeft, 138, tableWidth, panelHeight)
    place(self.headerBand, 10, 38, tableWidth - 20, 24)
    place(self.scroll, 10, 64, tableWidth - 36, panelHeight - 74)
    local columns = APR.RouteBrowserRows:Columns(tableWidth - 36)
    for key, header in pairs(self.headers) do
        local column = columns[key == "label" and "name" or key]
        place(header, 10 + column[1], 38, math.max(1, column[2]), 24)
        header:SetShown(column[2] > 0)
    end
    place(self.empty, 18, 82, tableWidth - 44, 60)
    place(self.pathPanel, pathLeft, 138, pathWidth, panelHeight)
    place(self.pathScroll, 10, 44, pathWidth - 36, panelHeight - 90)
    place(self.pathEmpty, 18, 54, pathWidth - 44, 80)
    place(self.clearPath, 12, panelHeight - 38, pathWidth - 24, 28)
    place(self.legend, tableLeft, height - hintHeight - 24, width - tableLeft, 18)
    local legendLeft = 0
    for _, entry in ipairs(self.legend.items) do
        local entryWidth = entry.text:GetStringWidth() + 9
        place(entry, legendLeft, 0, entryWidth, 18)
        legendLeft = legendLeft + entryWidth + 18
    end
    place(self.hint, tableLeft, height - hintHeight - 2, width - tableLeft, hintHeight)
    self.list:RefreshVisible(true)
    self.pathList:RefreshVisible(true)
    self.navigation:RefreshVisible(true)
end

function Browser:Show()
    if APR.LayoutEditor and APR.LayoutEditor.active then APR.LayoutEditor:Hide() end
    if not self.frame then self:Create() end
    if APR.settings.CloseSettings then APR.settings:CloseSettings() end
    self.frame:Show()
    self:Refresh(true)
end
