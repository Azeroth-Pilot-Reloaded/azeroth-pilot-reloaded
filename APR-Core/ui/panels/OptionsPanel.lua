-- Workspace settings: compact category navigation and a wide, scrollable AceConfig body.
-- Every control is generated from the existing option definitions, never a second set of setters.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local UI = APR.UI
APR.OptionsPanel = {}
local Options = APR.OptionsPanel
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
    self.viewTabs, self.selectedViews, self.actionButtons = {}, {}, {}
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
        local row = UI:Button(container, "", 1, function(button) self:Select(button.item.id) end, "flat")
        row:GetFontString():SetJustifyH("LEFT")
        row.marker = row:CreateTexture(nil, "OVERLAY")
        row.marker:SetPoint("TOPLEFT", 0, -4); row.marker:SetPoint("BOTTOMLEFT", 0, 4)
        row.marker:SetWidth(2)
        APR:RegisterThemeRegion(row.marker, "accent")
        return row
    end, function(row, section)
        row:SetText(section.label)
        UI:SetButtonActive(row, section.id == self.selected)
        row.marker:SetShown(section.id == self.selected)
    end, 38)
    self.navigation:SetItems(self.sections)
    self.body:HookScript("OnSizeChanged", function() self:LayoutViews() end)
    APR:RegisterSupportedEvent(self.frame, "PLAYER_REGEN_DISABLED")
    APR:RegisterSupportedEvent(self.frame, "PLAYER_REGEN_ENABLED")
    self.frame:SetScript("OnEvent", function() self:RefreshActions() end)
    self.frame:SetScript("OnShow", function() self:Select(self.selected or "automation") end)
    self.frame:SetScript("OnHide", function()
        self.host:ReleaseChildren()
        self.host:SetUserData("appName", nil)
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
    for _, button in ipairs(self.actionButtons) do
        local option = button.option
        local disabled = option and option.disabled
        if type(disabled) == "function" then disabled = disabled() end
        button:SetEnabled(not disabled)
        if option then button:SetText(Resolve(option.name)) end
    end
end

function Options:LayoutViews()
    if not self.section then return end
    local width, x, y = self.body:GetWidth() - 24, 0, 42
    local visible = #self.section.views > 1
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
    self.body.title:SetWidth(width - resetWidth - 44)
    if actionsWidth > 0 then
        -- Contextual actions share the tab row; reset always stays in the title row above them.
        local right = -44
        for index = #(self.actions or {}), 1, -1 do
            local button = self.actionButtons[index]
            button:ClearAllPoints()
            button:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", right, -42)
            right = right - button:GetWidth() - 8
        end
        if not visible then y = 82 end
    end
    local tabRowWidth = actionsWidth > 0 and width - actionsWidth - 40 or width
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
end

function Options:SelectView(id)
    for _, view in ipairs(self.section.views) do
        if view.id == id then
            self.view = view
            self.selectedViews[self.selected] = id
            self:SetActions(view.actions or self.section.actions)
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
                end
                self.viewTabs[index].viewID = view.id
                self.viewTabs[index]:SetText(view.label)
            end
            self:SelectView(requestedView or self.selectedViews[section.id] or section.views[1].id)
            self.navigation:RefreshVisible(true)
            return
        end
    end
end
