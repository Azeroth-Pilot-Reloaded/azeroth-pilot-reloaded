-- AceConfig retains validation, confirmations and profile callbacks. Only APR workspace widgets are restyled.
-- An isolated AceGUI pool prevents their textures and hooks leaking into other addons' settings.
local styled = setmetatable({}, {__mode = "k"})

local function MatchContainerStrata(widget)
    if not widget or not widget.frame then return end
    -- AceGUI containers explicitly use FULLSCREEN_DIALOG. Embedded content must share its host's strata.
    if widget.type == "InlineGroup" or widget.type == "ScrollFrame" or widget.type == "SimpleGroup" then
        local parent = widget.frame:GetParent()
        if parent then widget.frame:SetFrameStrata(parent:GetFrameStrata()) end
    end
    for _, child in ipairs(widget.children or {}) do MatchContainerStrata(child) end
end

local function SkinFrame(frame, kind, surface)
    if not frame then return end
    if not frame.SetBackdrop and BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
        frame:HookScript("OnSizeChanged", BackdropTemplateMixin.OnBackdropSizeChanged)
    end
    APR:RegisterSkinTarget(frame, kind or "panel", {themeSurface = true, preserveContent = true, surface = surface})
end

local function HideTemplateEdges(frame)
    local name = frame.GetName and frame:GetName()
    for _, key in ipairs({"Left", "Middle", "Right"}) do
        local texture = frame[key] or (name and _G[name .. key])
        if texture then texture:SetAlpha(0) end
    end
end

local function SkinButton(frame)
    HideTemplateEdges(frame)
    for _, state in ipairs({"Normal", "Pushed", "Disabled", "Highlight"}) do
        local texture = frame["Get" .. state .. "Texture"] and frame["Get" .. state .. "Texture"](frame)
        if texture then texture:SetAlpha(0) end
    end
    SkinFrame(frame, "button")
end

local function Style(widget, seen)
    if not widget then return end
    seen = seen or {}
    if seen[widget] then return end
    seen[widget] = true
    if not styled[widget] then
        styled[widget] = true
        local kind, frame = widget.type, widget.frame
        if kind == "Button" or kind == "APRWrappedButton" then
            SkinButton(frame)
        elseif kind == "EditBox" then
            -- InputBoxTemplate's artwork extends outside the actual input's hit area.
            -- Retire it before adding our backdrop to the same, editable frame.
            HideTemplateEdges(widget.editbox)
        elseif kind == "InlineGroup" then SkinFrame(widget.content:GetParent(), "borderedPanel", "inset")
        elseif kind == "CheckBox" then APR.SettingsRows:Checkbox(widget)
        elseif kind == "Slider" then
            SkinFrame(widget.slider)
            local thumb = widget.slider:GetThumbTexture()
            if thumb then thumb:SetSize(8, 14); APR:RegisterThemeRegion(thumb, "accent") end
        elseif kind == "Dropdown" then
            local name = widget.dropdown and widget.dropdown:GetName()
            for _, key in ipairs({"Left", "Middle", "Right"}) do
                local texture = name and _G[name .. key]
                if texture then texture:SetAlpha(0) end
            end
            -- Skin the text's own frame: AceGUI can reset child levels when reparenting pooled widgets.
            -- A separate background child could then cover the selected value and arrow.
            SkinFrame(widget.dropdown)
            widget.text:SetDrawLayer("OVERLAY", 2)
            if widget.button then
                for _, state in ipairs({"Normal", "Pushed", "Disabled", "Highlight"}) do
                    widget.button["Set" .. state .. "Texture"](widget.button, "Interface\\AddOns\\APR\\APR-Core\\assets\\ui\\down.tga")
                    local texture = widget.button["Get" .. state .. "Texture"](widget.button)
                    APR.UI:SetIcon(texture, "down")
                end
            end
        elseif kind == "Dropdown-Pullout" then SkinFrame(frame)
        elseif kind == "MultiLineEditBox" then SkinFrame(widget.scrollBG) end
        for _, key in ipairs({"editbox", "editBox"}) do SkinFrame(widget[key], "editbox") end
        if widget.button and kind ~= "Dropdown" then SkinButton(widget.button) end
        for _, key in ipairs({"scrollbar", "scrollBar"}) do
            if widget[key] then APR:RegisterSkinTarget(widget[key], "scrollbar", {compact = true}) end
        end
        for _, method in ipairs({"SetDisabled", "SetValue", "SetLabel"}) do
            if widget[method] then hooksecurefunc(widget, method, function() Style(widget) end) end
        end
    end
    if widget.type == "CheckBox" then APR.UI:SetIcon(widget.check, "check") end
    for _, key in ipairs({"text", "label", "titletext", "title", "desc", "lowtext", "hightext", "editbox"}) do
        local region = widget[key]
        if (type(region) == "table" or type(region) == "userdata") and region.SetTextColor then
            local role = widget.disabled and "muted" or (key == "title" or key == "titletext" or widget.type == "Heading") and "accent" or "base"
            APR:RegisterFontString(region, "general", {role = role, themeAccent = true})
        end
    end
    if widget.type == "Label" and widget.SetText then widget:SetText(widget.label:GetText()) end
    for _, child in ipairs(widget.children or {}) do Style(child, seen) end
    if widget.pullout then
        Style(widget.pullout, seen)
        for _, item in widget.pullout:IterateItems() do Style(item, seen) end
    end
end

function APR:EnableWorkspaceWidgets()
    if self.workspaceWidgetsInstalled then return end
    self.workspaceWidgetsInstalled = true
    local gui, dialog = LibStub("AceGUI-3.0"), LibStub("AceConfigDialog-3.0")
    -- A form action keeps its explanation separate from the clickable button.
    -- AceConfig still dispatches OnClick, including string handlers and confirmation dialogs.
    gui:RegisterWidgetType("APRSettingsAction", function()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:Hide()
        local widget = {type = "APRSettingsAction", frame = frame}
        widget.label = APR.UI:Label(frame, "")
        widget.button = APR.UI:Button(frame, APPLY, 160, function()
            gui:ClearFocus()
            widget:Fire("OnClick")
        end)
        widget.button:HookScript("OnEnter", function() widget:Fire("OnEnter") end)
        widget.button:HookScript("OnLeave", function() widget:Fire("OnLeave") end)
        function widget:SetText(value) self.label:SetText(value or "") end
        function widget:SetDisabled(disabled)
            self.disabled = disabled
            self.button:SetEnabled(not disabled)
        end
        function widget:OnAcquire()
            self:SetWidth(300); self:SetHeight(68)
            self:SetText(""); self:SetDisabled(false)
        end
        return gui:RegisterAsWidget(widget)
    end, 1)
    local depth, owned = 0, setmetatable({}, {__mode = "k"})
    local create, release = gui.Create, gui.Release
    gui.Create = function(self, kind)
        if depth == 0 then return create(self, kind) end
        local constructor = self.WidgetRegistry[kind]
        if not constructor then return create(self, kind) end
        local privateType = "APRWorkspace:" .. kind
        self:RegisterWidgetType(privateType, constructor, self:GetWidgetVersion(kind))
        local widget = create(self, privateType)
        owned[widget] = privateType
        return widget
    end
    gui.Release = function(self, widget)
        local privateType, releasing = owned[widget], widget.isQueuedForRelease
        release(self, widget)
        if privateType and not releasing then
            self.objPools[widget.type][widget] = nil
            self.objPools[privateType] = self.objPools[privateType] or {}
            self.objPools[privateType][widget] = true
        end
    end
    local prefix = self.title .. "/Workspace/"
    for _, method in ipairs({"Open", "FeedGroup"}) do
        local original = dialog[method]
        dialog[method] = function(self, app, ...)
            -- EllesmereUI already isolates and styles APR's AceGUI widgets with its public skin API.
            if type(app) ~= "string" or app:sub(1, #prefix) ~= prefix then
                return original(self, app, ...)
            end
            local external = APR:GetSkinProviderName() == "EllesmereUI"
            if not external then depth = depth + 1 end
            local result = {pcall(original, self, app, ...)}
            if not external then depth = depth - 1 end
            if not result[1] then error(result[2], 0) end
            local container = method == "FeedGroup" and select(2, ...) or ...
            MatchContainerStrata(container)
            if not external then Style(container) end
            APR.SettingsRows:Apply(container)
            if method == "Open" and container then container:Fire("OnOptionsRefreshed") end
            return unpack(result, 2)
        end
    end
end

-- A fixed-size AceGUI host lets AceConfig create its own scrolling body and preserve scroll state on edits.
function APR.UI:SettingsHost(parent)
    local gui = LibStub("AceGUI-3.0")
    if not gui:GetWidgetVersion("APRSettingsHost") then
        gui:RegisterWidgetType("APRSettingsHost", function()
            local frame = CreateFrame("Frame", nil, UIParent)
            local content = CreateFrame("Frame", nil, frame)
            content:SetAllPoints()
            return gui:RegisterAsContainer({type = "APRSettingsHost", frame = frame, content = content,
                OnAcquire = function() end, LayoutFinished = function() end,
                OnWidthSet = function(self, width) self.content.width = width; self.content:SetWidth(width) end,
                OnHeightSet = function(self, height) self.content.height = height; self.content:SetHeight(height) end})
        end, 1)
    end
    local host = gui:Create("APRSettingsHost")
    host.frame:SetParent(parent)
    host.frame:SetFrameStrata(parent:GetFrameStrata())
    host.frame:SetPoint("TOPLEFT")
    host.frame:SetPoint("BOTTOMRIGHT")
    parent:HookScript("OnSizeChanged", function()
        host:SetWidth(parent:GetWidth()); host:SetHeight(parent:GetHeight()); host:DoLayout()
    end)
    host:SetWidth(parent:GetWidth()); host:SetHeight(parent:GetHeight())
    return host
end
