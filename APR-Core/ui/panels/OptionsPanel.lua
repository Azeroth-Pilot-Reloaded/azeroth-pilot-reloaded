-- Workspace settings: compact category navigation and a wide, scrollable AceConfig body.
-- Every control is generated from the existing option definitions, never a second set of setters.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local UI = APR.UI
APR.OptionsPanel = {}
local Options = APR.OptionsPanel
local categoryIcons = {automation = "automation", group_Current_Step = "current-step", group_FillersFrame = "objectives",
    group_quest_order_list_step = "steps", group_Arrow = "arrow", group_map_minimap = "map", group_AFK = "afk",
    group_Group = "group", group_Heirloom = "heirloom", group_XP_Buff = "xp", appearance = "appearance",
    profiles = "profiles", changelog = "changelog", debug = "debug"}
local function Resolve(value)
    if type(value) == "function" then return value() end
    return value
end

function Options:Create(parent)
    self.frame = UI:Page(parent)
    local root = self.frame.content
    self.navigationPanel = UI:Section(root, L["CATEGORY"], "stone")
    self.navigationPanel:SetPoint("TOPLEFT")
    self.navigationPanel:SetPoint("BOTTOMLEFT")
    self.navigationPanel:SetWidth(216)
    self.body = UI:Section(root, GAMEOPTIONS_MENU)
    self.body:SetPoint("TOPLEFT", 228, 0)
    self.body:SetPoint("BOTTOMRIGHT")
    local reset = APR.WorkspaceOptions:ResetAction(APR.settings)
    self.resetButton = UI:Button(self.body, Resolve(reset.name), 200, function() reset.func() end)
    self.resetButton:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", -44, -8)
    UI:Tooltip(self.resetButton, function() return Resolve(reset.name) end, function() return Resolve(reset.desc) end)
    self.content = CreateFrame("Frame", nil, self.body)
    self.content:SetPoint("TOPLEFT", 12, -42)
    self.content:SetPoint("BOTTOMRIGHT", -12, 12)
    self.host = UI:SettingsHost(self.content)
    self.host:SetCallback("OnOptionsRefreshed", function() self:RefreshActions() end)
    self.viewTabs, self.selectedViews, self.actionButtons, self.footerButtons = {}, {}, {}, {}
    self.footer = CreateFrame("Frame", nil, self.body)
    self.footer:SetPoint("BOTTOMLEFT", 12, 12)
    self.footer:SetHeight(32)
    self.footer:Hide()
    self.sections = APR.WorkspaceOptions:Build(APR.settings)
    for _, section in ipairs(self.sections) do
        section.views = APR.WorkspaceOptions:Views(section)
        for _, view in ipairs(section.views) do
            view.app = APR.title .. "/Workspace/Options/" .. section.id .. "/" .. view.id
            LibStub("AceConfig-3.0"):RegisterOptionsTable(view.app, view.options)
        end
    end
    local scroll = UI:Scroll(self.navigationPanel)
    scroll:SetPoint("TOPLEFT", 10, -40)
    scroll:SetPoint("BOTTOMRIGHT", -26, 12)
    self.navigation = APR.VirtualList:New(scroll, function(container)
        local row = UI:ListButton(container, "", 1, function(button) self:Select(button.item.id) end, "appearance")
        if APR.Gamepad then
            APR.Gamepad:BindDetails(row, "RIGHT", function() self:Select(row.item.id) end,
                function() return self.content end)
        end
        return row
    end, function(row, section)
        row:SetText(section.label)
        UI:StyleListRow(row, categoryIcons[section.id] or "appearance")
        UI:SetButtonActive(row, section.id == self.selected)
    end, 42)
    self.navigation:SetItems(self.sections)
    self.body:HookScript("OnSizeChanged", function() self:LayoutViews() end)
    APR:RegisterSupportedEvent(self.frame, "PLAYER_REGEN_DISABLED")
    APR:RegisterSupportedEvent(self.frame, "PLAYER_REGEN_ENABLED")
    self.frame:SetScript("OnEvent", function()
        self:RefreshActions()
        if APR.ThemeCustomization and self.selected == "appearance" and self.view and self.view.id == "theme" then
            LibStub("AceConfigRegistry-3.0"):NotifyChange(self.view.app)
        end
    end)
    self.frame:SetScript("OnShow", function() self:Select(self.selected or "automation") end)
    self.frame:SetScript("OnHide", function()
        self.host:ReleaseChildren()
        self.host:SetUserData("appName", nil)
        if self.themePreview then self.themePreview:SetPreviewActive(false) end
        if APR.ThemeCustomization then APR.ThemeCustomization:Discard() end
        if self.releaseNotes then self.releaseNotes:Hide() end
    end)
end

-- View actions stay outside AceConfig's scroll area but use the authoritative option callbacks.
function Options:SetActions(actions)
    self.actions = actions or {}
    for _, button in ipairs(self.actionButtons) do button:Hide() end
    for index, action in ipairs(self.actions) do
        local button = self.actionButtons[index]
        if not button then
            button = UI:Button(self.body, "", 160, function(control)
                self:RefreshActions()
                if control:IsEnabled() then
                    control.option.func()
                    self:RefreshActions()
                    self:LayoutViews()
                end
            end)
            UI:Tooltip(button, function() return Resolve(button.option.name) end,
                function() return Resolve(button.option.desc) end)
            self.actionButtons[index] = button
        end
        button.option = action.option
        button:SetText(Resolve(action.option.name))
        button:Show()
    end
    self:RefreshActions()
end

function Options:RefreshActions()
    for _, buttons in ipairs({self.actionButtons, self.footerButtons}) do
        for _, button in ipairs(buttons) do
            local option = button.option
            local disabled = option and option.disabled
            if type(disabled) == "function" then disabled = disabled() end
            button:SetEnabled(not disabled)
            if option then button:SetText(Resolve(option.name)) end
        end
    end
end

function Options:SetFooterActions(actions)
    self.footerActions = actions or {}
    for _, button in ipairs(self.footerButtons) do button:Hide() end
    for index, action in ipairs(self.footerActions) do
        local button = self.footerButtons[index]
        if not button then
            button = UI:Button(self.footer, "", 200, function(control)
                self:RefreshActions()
                if control:IsEnabled() then
                    control.option.func()
                    LibStub("AceConfigRegistry-3.0"):NotifyChange(self.view.app)
                    self:RefreshActions()
                end
            end)
            UI:Tooltip(button, function() return Resolve(button.option.name) end,
                function() return Resolve(button.option.desc) end)
            self.footerButtons[index] = button
        end
        button.option = action.option
        button:SetText(Resolve(action.option.name))
        button:Show()
    end
    self.footer:SetShown(#self.footerActions > 0)
    self:RefreshActions()
end

function Options:LayoutViews()
    if not self.section then return end
    local width, x, y = self.body:GetWidth() - 24, 0, 42
    local visible = #self.section.views > 1
    local headingActions = self.selected == "appearance"
    local actionsWidth = 0
    for index in ipairs(self.actions or {}) do
        local button = self.actionButtons[index]
        local buttonWidth = math.min(width / 2 - 18, math.max(160, button:GetFontString():GetStringWidth() + 28))
        button:SetWidth(buttonWidth)
        actionsWidth = actionsWidth + buttonWidth + (index > 1 and 8 or 0)
    end
    self.body.title:ClearAllPoints()
    self.body.title:SetPoint("TOPLEFT", 12, -10)
    local resetWidth = math.min(width / 2 - 18, math.max(160, self.resetButton:GetFontString():GetStringWidth() + 28))
    self.resetButton:SetWidth(resetWidth)
    self.body.title:SetWidth(math.max(1, width - resetWidth - 44 - (headingActions and actionsWidth + 8 or 0)))
    if actionsWidth > 0 then
        local right = headingActions and -44 - resetWidth - 8 or -44
        for index = #(self.actions or {}), 1, -1 do
            local button = self.actionButtons[index]
            button:ClearAllPoints()
            button:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", right, headingActions and -8 or -42)
            right = right - button:GetWidth() - 8
        end
        if not visible and not headingActions then y = 82 end
    end
    local tabRowWidth = actionsWidth > 0 and not headingActions and width - actionsWidth - 40 or width
    for index, view in ipairs(self.section.views) do
        local tab = self.viewTabs[index]
        tab:SetShown(visible)
        if visible then
            local tabWidth = math.min(width, math.max(100, tab:GetFontString():GetStringWidth() + 28))
            if x + tabWidth > tabRowWidth then x, y, tabRowWidth = 0, y + 36, width end
            tab:ClearAllPoints(); tab:SetPoint("TOPLEFT", self.body, "TOPLEFT", 12 + x, -y)
            tab:SetSize(tabWidth, 28)
            x = x + tabWidth + 6
        end
        UI:SetButtonActive(tab, self.selectedViews[self.selected] == view.id)
    end
    self.content:SetPoint("TOPLEFT", 12, -(visible and y + 40 or y))
    self.content:SetPoint("BOTTOMRIGHT", -12, #self.footerActions > 0 and 56 or 12)
    self.host.frame:ClearAllPoints()
    self.host.frame:SetPoint("TOPLEFT")
    if self.themePreviewActive then
        local previewWidth = math.min(300, math.max(190, (self.body:GetWidth() - 24) * 0.35))
        self.themePreview:SetWidth(previewWidth)
        self.themePreview.frame:ClearAllPoints()
        self.themePreview.frame:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, 0)
        self.host.aprRightInset = previewWidth + 16
        self.host.frame:SetPoint("BOTTOMRIGHT", -(previewWidth + 16), 0)
    else
        self.host.aprRightInset = 0
        self.host.frame:SetPoint("BOTTOMRIGHT")
    end
    self.footer:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -12 - self.host.aprRightInset, 12)
    local footerWidth = width - self.host.aprRightInset
    local buttonWidth = math.min(280, (footerWidth - 12) / math.max(1, #self.footerActions))
    local totalWidth = #self.footerActions * buttonWidth + math.max(0, #self.footerActions - 1) * 12
    for index in ipairs(self.footerActions) do
        local button = self.footerButtons[index]
        button:ClearAllPoints()
        button:SetPoint("LEFT", self.footer, "LEFT", (footerWidth - totalWidth) / 2 + (index - 1) * (buttonWidth + 12), 0)
        button:SetSize(buttonWidth, 30)
    end
    if self.host.ResizeToParent then self.host:ResizeToParent() end
end

function Options:SelectView(id)
    for _, view in ipairs(self.section.views) do
        if view.id == id then
            self.view = view
            self.selectedViews[self.selected] = id
            self.themePreviewActive = APR.ThemeCustomization and self.selected == "appearance" and id == "theme" or false
            if self.themePreviewActive and not self.themePreview then
                self.themePreview = LibStub("AceGUI-3.0"):Create("APRThemePreview")
                self.themePreview.frame:SetParent(self.content)
            end
            if self.themePreview then self.themePreview:SetPreviewActive(self.themePreviewActive) end
            self:SetActions(view.actions or self.section.actions)
            self:SetFooterActions(view.footerActions)
            self:LayoutViews()
            if self.selected == "changelog" then
                self.host:ReleaseChildren()
                self.host:SetUserData("appName", nil)
                self.host.frame:Hide()
                if not self.releaseNotes then self.releaseNotes = APR.ReleaseNotesPanel:Create(self.content) end
                self.releaseNotes:Show(view.app)
            else
                if self.releaseNotes then self.releaseNotes:Hide() end
                self.host.frame:Show()
                LibStub("AceConfigDialog-3.0"):Open(view.app, self.host)
            end
            return
        end
    end
end

function Options:Select(id)
    if id == "general" then id = "automation" end
    for _, section in ipairs(self.sections) do
        -- Old category entry points still open the corresponding panel inside its new category.
        local requestedView
        for _, view in ipairs(section.views) do if view.id == id then requestedView = id; break end end
        if section.id == id or requestedView then
            self.selected, self.section = section.id, section
            self.body.title:SetText(section.label)
            for _, tab in ipairs(self.viewTabs) do tab:Hide() end
            for index, view in ipairs(section.views) do
                if not self.viewTabs[index] then
                    self.viewTabs[index] = UI:Button(self.body, "", 100, function(button) self:SelectView(button.viewID) end)
                    if APR.Gamepad then
                        local tab = self.viewTabs[index]
                        APR.Gamepad:BindDetails(tab, "DOWN", function() self:SelectView(tab.viewID) end,
                            function() return self.content end)
                    end
                end
                self.viewTabs[index].viewID = view.id
                self.viewTabs[index]:SetText(view.label)
            end
            self:SelectView(requestedView or self.selectedViews[section.id] or section.views[1].id)
            if APR.Gamepad then APR.Gamepad:LinkHorizontal(self.viewTabs) end
            self.navigation:RefreshVisible(true)
            return
        end
    end
end
