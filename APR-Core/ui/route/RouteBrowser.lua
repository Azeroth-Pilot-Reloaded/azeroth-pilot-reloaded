-- A resizable route library with a virtualized catalog, explicit provenance and an ordered path.
-- The selected route remains inspectable while filters and path controls are used.

APR.RouteBrowser = { filters = { facet = "all" } }
local Browser, UI = APR.RouteBrowser, APR.UI
local function T(key) return APR:LocalizeUI(key) end

function Browser:Refresh(rebuild)
    if not self.frame or not self.frame:IsShown() then return end
    if rebuild or not self.records then self.records = APR.RouteCatalog:Build() end
    self.expansion:SetOptions(APR.RouteCatalog:GetOptions(self.records, "expansion", T("EXPANSION") .. ": " .. T("ALL")), self.filters.expansion or false)
    self.category:SetOptions(APR.RouteCatalog:GetOptions(self.records, "category", T("CATEGORY") .. ": " .. T("ALL")), self.filters.category or false)
    local records = APR.RouteCatalog:Filter(self.records, self.filters)
    local selected
    for _, record in ipairs(records) do if record.key == self.selectedKey then selected = record end end
    selected = selected or records[1]
    self.selectedKey = selected and selected.key
    self.list:SetItems(records, true)
    self.count:SetText(#records .. " / " .. #self.records)
    self.empty:SetShown(#records == 0)
    self.empty:SetText(self.filters.facet == "community" and T("NO_COMMUNITY_METADATA") or T("NO_RESULTS"))
    for facet, button in pairs(self.tabs) do
        local selected = facet == self.filters.facet
        button:SetText((selected and "• " or "") .. button.labelText)
        APR:SetFontStringRole(button:GetFontString(), selected and "accent" or "base")
    end
    self:ShowDetails(selected)
end

function Browser:ShowDetails(record)
    self.selected = record
    self.details:SetShown(record ~= nil)
    if not record then return end
    self.selectedKey = record.key
    local lines = { record.label, "", T("AUTHOR") .. ": " .. record.author,
        T("EXPANSION") .. ": " .. record.expansion, T("CATEGORY") .. ": " .. record.category }
    if record.community then lines[#lines + 1] = T("COMMUNITY") end
    lines[#lines + 1] = ""
    lines[#lines + 1] = record.completed and T("COMPLETE") or
        string.format("%s: %d / %d", T("STEPS"), math.min(record.progress, record.total), record.total)
    lines[#lines + 1] = record.visibility == "visible" and T("AVAILABLE") or T("UNAVAILABLE")
    for _, condition in ipairs(APR:GetUnmetConditions(record.key)) do lines[#lines + 1] = condition end
    if type(record.description) == "string" then lines[#lines + 1] = "\n" .. record.description end
    self.detailText:SetText(table.concat(lines, "\n"))
    self.detailBody:SetHeight(math.max(1, self.detailText:GetStringHeight() + 16))
    self.add:SetEnabled(record.visibility == "visible" and not record.pathIndex)
    self.remove:SetEnabled(record.pathIndex ~= nil)
    self.up:SetEnabled(record.pathIndex ~= nil and record.pathIndex > 1)
    self.down:SetEnabled(record.pathIndex ~= nil and record.pathIndex < #(APRCustomPath[APR.PlayerID] or {}))
    self.favorite:SetText((record.favorite and "* " or "+ ") .. T("FAVORITES"))
end

function Browser:Create()
    local frame = UI:Window("APRRouteBrowser", T("ROUTES"), 1120, 740)
    self.frame, self.tabs = frame, {}
    local root = frame.content
    self.search = UI:SearchBox(root, 400, T("SEARCH_ROUTES"), function(query)
        self.filters.query = query
        self:Refresh()
    end)
    self.search:SetPoint("TOPLEFT")
    self.search:SetPoint("TOPRIGHT", -80, 0)
    self.count = UI:Label(root, "", 12, "muted")
    self.count:SetPoint("TOPRIGHT", 0, -9)
    local facets = { {"all", "ALL"}, {"community", "COMMUNITY"}, {"favorites", "FAVORITES"}, {"path", "MY_PATH"} }
    for index, pair in ipairs(facets) do
        local facet = pair[1]
        local button = UI:Button(root, T(pair[2]), 146, function()
            self.filters.facet = facet
            -- The path tab must always expose the complete sequence for reordering.
            if facet == "path" then
                self.filters.expansion, self.filters.category = nil, nil
                self.search:SetText("")
            end
            self:Refresh(true)
        end)
        button:SetPoint("TOPLEFT", (index - 1) * 150, -42)
        self.tabs[facet] = button
        button.labelText = T(pair[2])
    end
    self.expansion = UI:Select(root, 245, function(value) self.filters.expansion = value or nil; self:Refresh() end)
    self.expansion:SetPoint("TOPLEFT", 0, -82)
    self.category = UI:Select(root, 245, function(value) self.filters.category = value or nil; self:Refresh() end)
    self.category:SetPoint("TOPLEFT", 255, -82)
    local reset = UI:Button(root, T("RESET_FILTERS"), 132, function()
        self.filters = { facet = "all" }
        self.search:SetText("")
        self:Refresh(true)
    end)
    reset:SetPoint("TOPLEFT", 510, -82)
    local scroll = UI:Scroll(root)
    scroll:SetPoint("TOPLEFT", 0, -124)
    scroll:SetPoint("BOTTOMRIGHT", -294, 48)
    self.list = APR.VirtualList:New(scroll, function(parent)
        local row = UI:Button(parent, "", 300, function(button)
            self:ShowDetails(button.item)
            self.list:RefreshVisible(true)
        end)
        row.title = UI:Label(row, "", 14)
        row.title:SetPoint("TOPLEFT", 10, -8)
        row.title:SetPoint("TOPRIGHT", -10, -8)
        row.title:SetHeight(34)
        row.subtitle = UI:Label(row, "", 11, "muted")
        row.subtitle:SetWordWrap(false)
        row.subtitle:SetPoint("BOTTOMLEFT", 10, 8)
        row.subtitle:SetPoint("BOTTOMRIGHT", -10, 8)
        row:HookScript("OnEnter", function(control)
            local record = control.item
            if not record then return end
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            APR:SetTooltipText(GameTooltip, record.label, "general", "accent")
            APR:AddTooltipLine(GameTooltip, record.author .. "\n" .. record.expansion .. " / " .. record.category, "general", "base", true)
            GameTooltip:Show()
        end)
        row:HookScript("OnLeave", function() GameTooltip:Hide() end)
        return row
    end, function(row, record)
        local prefix = (record.pathIndex and self.filters.facet == "path") and (record.pathIndex .. ". ") or ""
        row.title:SetText(prefix .. (record.favorite and "* " or "") .. record.label)
        row.subtitle:SetText((record.community and T("COMMUNITY") .. " · " or "") .. record.category .. " · " .. record.author)
        row:SetAlpha(record.visibility == "visible" and 1 or 0.65)
        if not APR:GetSkinProviderName() then
            row:SetBackdropBorderColor(unpack(APR:GetThemeColor(record.key == self.selectedKey and "accent" or "border")))
        end
    end, 78)
    self.empty = UI:Label(root, T("NO_RESULTS"), 13, "muted")
    self.empty:SetPoint("TOPLEFT", 12, -148)
    self.empty:SetPoint("RIGHT", scroll, "RIGHT", -12, 0)
    self.details = UI:Panel(root)
    self.details:SetPoint("TOPRIGHT", 0, -124)
    self.details:SetPoint("BOTTOMRIGHT", 0, 48)
    self.details:SetWidth(260)
    local detailScroll = UI:Scroll(self.details)
    detailScroll:SetPoint("TOPLEFT", 10, -12)
    detailScroll:SetPoint("BOTTOMRIGHT", -28, 138)
    self.detailBody = CreateFrame("Frame", nil, detailScroll)
    self.detailBody:SetSize(220, 1)
    detailScroll:SetScrollChild(self.detailBody)
    self.detailText = UI:Label(self.detailBody, "", 13)
    self.detailText:SetPoint("TOPLEFT")
    self.detailText:SetPoint("TOPRIGHT")
    detailScroll:HookScript("OnSizeChanged", function(owner)
        self.detailBody:SetWidth(owner:GetWidth())
        self.detailBody:SetHeight(math.max(1, self.detailText:GetStringHeight() + 16))
    end)
    self.favorite = UI:Button(self.details, T("FAVORITES"), 240, function()
        local favorites = APR.settings.profile.routeFavorites or {}
        APR.settings.profile.routeFavorites = favorites
        favorites[self.selected.key] = not favorites[self.selected.key] or nil
        self:Refresh(true)
    end)
    self.favorite:SetPoint("BOTTOMLEFT", 10, 96)
    self.add = UI:Button(self.details, T("ADD_PATH"), 240, function()
        APR.RouteCatalog:ChangePath(self.selected, "add"); self:Refresh(true)
    end)
    self.add:SetPoint("BOTTOMLEFT", 10, 62)
    self.remove = UI:Button(self.details, T("REMOVE"), 96, function()
        APR.RouteCatalog:ChangePath(self.selected, "remove"); self:Refresh(true)
    end)
    self.remove:SetPoint("BOTTOMLEFT", 10, 24)
    self.up = UI:Button(self.details, "↑", 62, function()
        APR.RouteCatalog:ChangePath(self.selected, "up"); self:Refresh(true)
    end)
    self.up:SetPoint("LEFT", self.remove, "RIGHT", 8, 0)
    UI:Tooltip(self.up, T("UP"))
    self.down = UI:Button(self.details, "↓", 62, function()
        APR.RouteCatalog:ChangePath(self.selected, "down"); self:Refresh(true)
    end)
    self.down:SetPoint("LEFT", self.up, "RIGHT", 8, 0)
    UI:Tooltip(self.down, T("DOWN"))
    local presets = UI:Select(root, 260, function(value)
        if value == "leveling" then APR.routeconfig:OpenLevelingPopup()
        elseif value == "quests" then APR.routeconfig:OpenAllQuestsPopup()
        elseif value == "speedrun" then APR.routeconfig:OpenSpeedrunPreset() end
    end)
    presets:SetOptions({{value = "leveling", label = T("PRESET_LEVELING")},
        {value = "quests", label = T("PRESET_QUESTS")}, {value = "speedrun", label = "Speedrun"}}, false)
    presets:SetText(T("PRESETS"))
    presets:SetPoint("BOTTOMLEFT")
    local settings = UI:Button(root, T("SETTINGS"), 150, function() APR.settings:OpenSettings(APR.title) end)
    settings:SetPoint("BOTTOMRIGHT")
    frame:HookScript("OnShow", function() self:Refresh(true) end)
end

function Browser:Show()
    if not self.frame then self:Create() end
    self.frame:Show()
    self:Refresh(true)
end
