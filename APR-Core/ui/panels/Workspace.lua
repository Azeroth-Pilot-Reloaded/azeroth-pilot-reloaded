-- One lazy window for routes, diagnostics and configuration. Hidden pages do no refresh work.
-- Page controllers retain their state; only the shell owns window geometry and Escape handling.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local UI = APR.UI
APR.Workspace = { pages = {}, tabs = {} }
local Workspace = APR.Workspace

local definitions = {
    { id = "route", label = L["ROUTE"], controller = "RouteBrowser" },
    { id = "status", label = L["STATUS"], controller = "StatusPanel" },
    { id = "about", label = L["ABOUT_HELP"], controller = "AboutPanel" },
    { id = "options", label = GAMEOPTIONS_MENU, controller = "OptionsPanel" },
    { id = "perf", label = L["UI_PERFORMANCE"], controller = "PerformanceDashboard" },
}

-- Embedded pages have the same content contract as standalone utility windows.
function UI:Page(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page.content = CreateFrame("Frame", nil, page)
    page.content:SetAllPoints()
    page:Hide()
    return page
end

function Workspace:Create()
    local frame = UI:Window("APRWorkspace", APR.title, 1240, 850, "library", "logo")
    self.frame = frame
    -- Include the attached tabs in screen clamping when dragging the window upward.
    frame:SetClampRectInsets(-24, 0, 26, 0)
    frame:SetFrameLevel(math.max(3, frame:GetFrameLevel()))
    frame:SetResizeBounds(math.min(940, UIParent:GetWidth() - 40), math.min(740, UIParent:GetHeight() - 60))
    frame:SetSize(math.max(frame:GetWidth(), math.min(940, UIParent:GetWidth() - 40)),
        math.max(frame:GetHeight(), math.min(740, UIParent:GetHeight() - 60)))
    -- Attached tabs sit outside the shell, leaving its original logo/title/content geometry intact.
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", 72, -48)
    line:SetPoint("TOPRIGHT", -16, -48)
    line:SetHeight(1)
    APR:RegisterThemeRegion(line, "border", 0.6)
    for _, definition in ipairs(definitions) do
        local tab = UI:Button(frame, definition.label, 130, function() self:Show(definition.id) end)
        tab:SetHeight(28)
        -- The shell covers the lower edge of the tab, like a folder attached behind its border.
        tab:SetFrameLevel(frame:GetFrameLevel() - 1)
        self.tabs[definition.id] = tab
    end
    frame:HookScript("OnSizeChanged", function() self:LayoutTabs() end)
    frame:HookScript("OnHide", function()
        if UI.activeMenu then UI.activeMenu:Hide() end
        if UI.selectionDialog then UI.selectionDialog:Hide() end
    end)
    self:LayoutTabs()
end

function Workspace:LayoutTabs()
    if not self.frame then return end
    local showPerf = APR:GetSettingsProfile().showPerformanceTab == true
    local right = -16
    for index = #definitions, 1, -1 do
        local definition = definitions[index]
        local tab = self.tabs[definition.id]
        local visible = definition.id ~= "perf" or showPerf
        tab:SetShown(visible)
        if visible then
            local width = math.min(190, math.max(110, tab:GetFontString():GetStringWidth() + 30))
            tab:ClearAllPoints()
            tab:SetPoint("BOTTOMRIGHT", self.frame, "TOPRIGHT", right, -5)
            tab:SetWidth(width)
            UI:SetButtonActive(tab, self.active == definition.id)
            right = right - width - 4
        end
    end
end

function Workspace:Show(id, section)
    id = id or "route"
    if SettingsPanel then SettingsPanel:Hide() end
    if InterfaceOptionsFrame then InterfaceOptionsFrame:Hide() end
    if APR.LayoutEditor and APR.LayoutEditor.active then APR.LayoutEditor:Hide(false) end
    if not self.frame then self:Create() end
    local definition
    for _, entry in ipairs(definitions) do if entry.id == id then definition = entry; break end end
    if not definition then return end
    if UI.activeMenu then UI.activeMenu:Hide() end
    if self.active ~= id and UI.selectionDialog then UI.selectionDialog:Hide() end
    local controller = APR[definition.controller]
    if not self.pages[id] then
        controller:Create(self.frame.content)
        self.pages[id] = controller.frame
    end
    self.active = id
    for key, page in pairs(self.pages) do page:SetShown(key == id) end
    self.frame.header.Text:SetText(APR.title .. "  ·  " .. definition.label)
    self:LayoutTabs()
    self.frame:Show()
    self.frame:Raise()
    if section and controller.Select then controller:Select(section)
    elseif controller.Refresh then controller:Refresh() end
end

function Workspace:Hide()
    if self.frame then self.frame:Hide() end
end
