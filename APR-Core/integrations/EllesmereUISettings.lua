-- AceConfig creates and releases controls whenever a settings page changes.
-- APR gets a separate AceGUI pool: themed controls must never enter another
-- addon's options, and the original widget.type must remain intact for AceConfig.
function APR:EnableEllesmereUISettings(S)
    if self._ellesmereSettingsInstalled then return end
    local gui = LibStub("AceGUI-3.0", true)
    local dialog = LibStub("AceConfigDialog-3.0", true)
    if not gui or not dialog then return end
    self._ellesmereSettingsInstalled = true
    local depth = 0
    local owned = setmetatable({}, { __mode = "k" })
    local hooked = setmetatable({}, { __mode = "k" })
    local pending = setmetatable({}, { __mode = "k" })
    local checkboxes = setmetatable({}, { __mode = "k" })
    local toggles = setmetatable({}, { __mode = "k" })
    local swatches = setmetatable({}, { __mode = "k" })
    local fonted = setmetatable({}, { __mode = "k" })
    local styling = setmetatable({}, { __mode = "k" })

    local function Enabled()
        return APR.EllesmereUISkin and APR.EllesmereUISkin:GetFont() ~= nil
    end
    local function IsAPR(app)
        return type(app) == "string" and (app == APR.title or app:sub(1, #APR.title + 1) == APR.title .. "/")
    end
    local function WithContext(fn, ...)
        depth = depth + 1
        local result = { pcall(fn, ...) }
        depth = depth - 1
        if not result[1] then error(result[2], 0) end
        return unpack(result, 2)
    end
    local function Fonts(root)
        if not root or not root.GetRegions then return end

        -- Snapshot the existing frame tree before calling S.Font. EllesmereUI's
        -- font-shadow priming can add helper objects while a font is being
        -- styled; walking that live tree recursively feeds those helpers back
        -- into PrimeFontShadow and eventually overflows the Lua stack.
        local frames = { root }
        local seenFrames = { [root] = true }
        local regions = {}
        local index = 1
        while index <= #frames do
            local frame = frames[index]
            index = index + 1
            for _, region in ipairs({ frame:GetRegions() }) do
                if region and region.IsObjectType and region:IsObjectType("FontString") and not fonted[region] then
                    regions[#regions + 1] = region
                    fonted[region] = true
                end
            end
            if frame.GetChildren then
                for _, child in ipairs({ frame:GetChildren() }) do
                    if child and not seenFrames[child] then
                        seenFrames[child] = true
                        frames[#frames + 1] = child
                    end
                end
            end
        end
        for _, region in ipairs(regions) do S.Font(region) end
    end
    local function Style(widget, visited)
        if not widget then return end
        visited = visited or {}
        if visited[widget] or styling[widget] then return end
        visited[widget] = true
        if not Enabled() then return end
        if gui.IsReleasing and gui:IsReleasing(widget) then return end
        if InCombatLockdown() then pending[widget] = true; return end
        pending[widget] = nil
        styling[widget] = true
        local frame, kind = widget.frame, widget.type
        if kind == "CheckBox" then
            if not checkboxes[widget] then
                local box = CreateFrame("Frame", nil, frame)
                box:SetSize(16, 16)
                box:SetPoint("CENTER", widget.checkbg, "CENTER")
                box:SetFrameLevel(frame:GetFrameLevel())
                box:EnableMouse(false)
                S.Panel(box)
                widget.checkbg:SetAlpha(0)
                checkboxes[widget] = box
            end
            widget.check:SetVertexColor(S.GetAccentColor())
        elseif kind == "ColorPicker" then
            if not swatches[widget] then
                local border = CreateFrame("Frame", nil, frame)
                border:SetAllPoints(widget.colorSwatch)
                border:SetFrameLevel(frame:GetFrameLevel())
                border:EnableMouse(false)
                S.Panel(border, { noBg = true })
                widget.colorSwatch:SetTexture("Interface\\Buttons\\WHITE8X8")
                swatches[widget] = border
            end
        elseif kind == "Dropdown" then
            if widget.dropdown then S.Dropdown(widget.dropdown) end
        elseif kind == "DropdownGroup" then
            Style(widget.dropdown, visited)
            S.Panel(widget.border, { inset = true })
        elseif kind == "Slider" then
            S.Panel(widget.slider)
            local thumb = widget.slider:GetThumbTexture()
            if thumb then
                thumb:SetAlpha(1)
                thumb:SetColorTexture(S.GetAccentColor())
                thumb:SetSize(10, 14)
            end
        elseif kind == "InlineGroup" then
            S.Panel(widget.content:GetParent(), { inset = true })
        elseif kind == "MultiLineEditBox" then
            S.Panel(widget.scrollBG, { inset = true })
        elseif kind == "TreeGroup" then
            S.Panel(widget.treeframe, { inset = true })
            if widget.border then S.Panel(widget.border, { noBg = true }) end
            for _, button in pairs(widget.buttons or {}) do
                S.Button(button, { "icon" })
                if button.text then button.text:SetTextColor(S.GetAccentColor()) end
                if button.toggle then
                    local toggle = button.toggle
                    local label = toggles[toggle]
                    if not label then
                        label = toggle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        label:SetPoint("CENTER")
                        toggles[toggle] = label
                    end
                    local normal = toggle:GetNormalTexture()
                    label:SetText(normal and normal:GetTexture() == 130838 and "+" or "−")
                    S.FadeRegions(toggle)
                    S.Font(label)
                    label:SetTextColor(S.GetAccentColor())
                end
            end
        elseif kind == "TabGroup" then
            for _, tab in pairs(widget.tabs or {}) do S.Tab(tab) end
        elseif kind == "Heading" then
            for _, line in ipairs({ widget.left, widget.right }) do
                line:SetColorTexture(S.GetAccentColor())
                line:SetHeight(1)
            end
        elseif kind == "Frame" or kind == "Window" then
            S.Shell(frame)
        elseif kind == "Dropdown-Pullout" then
            S.Panel(frame)
        elseif kind == "Button" or kind == "APRWrappedButton" then
            S.Button(frame)
            S.StateButtonLabel(frame)
        end
        for _, key in ipairs({ "editbox", "editBox" }) do
            if widget[key] then S.EditBox(widget[key]) end
        end
        for _, key in ipairs({ "scrollbar", "scrollBar" }) do
            if widget[key] then S.ScrollBar(widget[key]) end
        end
        if widget.button and kind ~= "Dropdown" then S.Button(widget.button) end
        if widget.closebutton then S.CloseButton(widget.closebutton) end
        Fonts(frame)
        for _, key in ipairs({ "titletext", "title", "label" }) do
            local text = widget[key]
            if (type(text) == "table" or type(text) == "userdata") and text.SetTextColor then
                if widget.disabled then text:SetTextColor(0.5, 0.5, 0.5)
                elseif kind == "Heading" or key == "titletext" or key == "title" then
                    text:SetTextColor(S.GetAccentColor())
                else
                    text:SetTextColor(0.85, 0.85, 0.85)
                end
            end
        end
        if widget.text then
            if kind == "Heading" then widget.text:SetTextColor(S.GetAccentColor())
            elseif widget.disabled then widget.text:SetTextColor(0.5, 0.5, 0.5)
            else widget.text:SetTextColor(0.85, 0.85, 0.85) end
        end
        if widget.check and kind ~= "CheckBox" then widget.check:SetVertexColor(S.GetAccentColor()) end
        for _, child in ipairs(widget.children or {}) do Style(child, visited) end
        if widget.pullout then
            Style(widget.pullout, visited)
            for _, item in widget.pullout:IterateItems() do Style(item, visited) end
        end
        if not hooked[widget] then
            hooked[widget] = true
            for _, method in ipairs({ "RefreshTree", "BuildTabs", "SetDisabled", "SetLabel", "SetDescription", "SetValue" }) do
                if widget[method] then hooksecurefunc(widget, method, function() Style(widget) end) end
            end
        end
        styling[widget] = nil
    end

    local create, release = gui.Create, gui.Release
    gui.Create = function(self, kind)
        if depth == 0 or not Enabled() then return create(self, kind) end
        local privateType = "APREllesmere:" .. kind
        local constructor = self.WidgetRegistry[kind]
        if not constructor then return create(self, kind) end
        self:RegisterWidgetType(privateType, constructor, self:GetWidgetVersion(kind))
        local widget = create(self, privateType)
        owned[widget] = privateType
        return widget
    end
    gui.Release = function(self, widget)
        local privateType = owned[widget]
        local wasReleasing = widget.isQueuedForRelease
        release(self, widget)
        if privateType and not wasReleasing then
            self.objPools[widget.type][widget] = nil
            self.objPools[privateType] = self.objPools[privateType] or {}
            self.objPools[privateType][widget] = true
        end
    end
    for _, method in ipairs({ "Open", "FeedGroup", "AddToBlizOptions" }) do
        local original = dialog[method]
        dialog[method] = function(self, app, ...)
            if not IsAPR(app) or not Enabled() then return original(self, app, ...) end
            local result = { WithContext(original, self, app, ...) }
            -- Open also handles redraws triggered by option changes. FeedGroup
            -- covers tree/tab navigation without scanning the Blizzard settings UI.
            if method == "FeedGroup" then Style(select(2, ...)) end
            if method == "Open" then
                local container = ...
                if type(container) == "table" then Style(container)
                elseif self.OpenFrames then Style(self.OpenFrames[app]) end
            end
            return unpack(result)
        end
    end
    S.OnLooksChanged(function()
        for widget in pairs(hooked) do
            if widget.frame:IsShown() then Style(widget) end
        end
    end)
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function()
        local queued = pending
        pending = setmetatable({}, { __mode = "k" })
        for widget in pairs(queued) do Style(widget) end
    end)
end
