-- Settings read as a form: explanation on the left, a consistently aligned control on the right.
-- AceGUI still owns values, focus, color pickers and callbacks; these helpers only lay out APR's private widgets.
APR.SettingsRows = {}
local Rows, UI = APR.SettingsRows, APR.UI
local supported = {CheckBox = true, Slider = true, Dropdown = true, ColorPicker = true, EditBox = true,
    APRSettingsAction = true}

local function Anchor(region, point, relative, relativePoint, x, y, width, height)
    region:ClearAllPoints()
    region:SetPoint(point, relative, relativePoint, x, y)
    if width then region:SetWidth(width) end
    if height then region:SetHeight(height) end
end

function Rows:Checkbox(widget)
    if not widget.aprCheckBox then
        local box = UI:Panel(widget.frame)
        box:SetSize(22, 22)
        box:EnableMouse(false)
        widget.aprCheckBox = box
        widget.checkbg:SetAlpha(0)
        widget.highlight:SetAlpha(0)
        -- Textures on the parent are drawn beneath a child panel, regardless of their draw layer.
        -- Reparent the actual checked texture so AceGUI's true/false/mixed state remains authoritative.
        widget.check:SetParent(box)
        widget.check:ClearAllPoints()
        widget.check:SetPoint("TOPLEFT", 3, -3)
        widget.check:SetPoint("BOTTOMRIGHT", -3, 3)
        widget.check:SetDrawLayer("OVERLAY", 2)
    end
    UI:SetIcon(widget.check, "check")
    widget.aprCheckBox:SetAlpha(widget.disabled and 0.45 or 1)
end

local function Layout(widget)
    if widget.aprLayingOut or not widget.aprRow then return end
    local option = widget:GetUserData("option")
    if not option then return end
    widget.aprLayingOut = true
    local frame, kind = widget.frame, widget.type
    local width = math.max(320, frame:GetWidth())
    local controlWidth = math.min(290, math.max(190, width * 0.34))
    if kind == "APRSettingsAction" then controlWidth = 160 end
    local label = (kind == "CheckBox" or kind == "ColorPicker") and widget.text or widget.label
    Anchor(label, "TOPLEFT", frame, "TOPLEFT", 12, -14, width - controlWidth - 40, 0)
    label:SetJustifyH("LEFT"); label:SetWordWrap(true)
    local labelHeight = math.max(18, label:GetStringHeight())
    local description = type(option.desc) == "string" and option.desc or ""
    if description == label:GetText() then description = "" end
    local note = widget.aprRow.note
    note:SetText(description)
    note:SetShown(description ~= "")
    Anchor(note, "TOPLEFT", frame, "TOPLEFT", 12, -18 - labelHeight, width - controlWidth - 40, 0)
    local height = math.max(kind == "Slider" and 68 or 52,
        labelHeight + (description ~= "" and note:GetStringHeight() + 6 or 0) + 28)
    if kind == "CheckBox" then
        Rows:Checkbox(widget)
        Anchor(widget.aprCheckBox, "TOPRIGHT", frame, "TOPRIGHT", -12, -14)
        Anchor(widget.checkbg, "CENTER", widget.aprCheckBox, "CENTER", 0, 0, 22, 22)
    elseif kind == "Slider" then
        Anchor(widget.slider, "TOPRIGHT", frame, "TOPRIGHT", -96, -20, controlWidth - 84, 16)
        Anchor(widget.editbox, "TOPRIGHT", frame, "TOPRIGHT", -12, -14, 72, 28)
        local limitWidth = (controlWidth - 84) / 2 - 6
        Anchor(widget.lowtext, "TOPLEFT", widget.slider, "BOTTOMLEFT", 0, -6, limitWidth, 0)
        Anchor(widget.hightext, "TOPRIGHT", widget.slider, "BOTTOMRIGHT", 0, -6, limitWidth, 0)
        widget.lowtext:SetJustifyH("LEFT"); widget.hightext:SetJustifyH("RIGHT")
        height = math.max(height, 20 + 16 + 6 + math.max(widget.lowtext:GetStringHeight(), widget.hightext:GetStringHeight()) + 12)
    elseif kind == "Dropdown" then
        Anchor(widget.dropdown, "TOPRIGHT", frame, "TOPRIGHT", -12, -12, controlWidth, 30)
        Anchor(widget.button_cover, "TOPRIGHT", frame, "TOPRIGHT", -12, -12, controlWidth, 30)
        Anchor(widget.button, "RIGHT", widget.button_cover, "RIGHT", -4, 0, 22, 22)
        widget.text:ClearAllPoints()
        widget.text:SetPoint("LEFT", widget.button_cover, "LEFT", 10, 0)
        widget.text:SetPoint("RIGHT", widget.button_cover, "RIGHT", -32, 0)
        widget.text:SetJustifyH("LEFT")
        widget:SetPulloutWidth(controlWidth)
    elseif kind == "EditBox" then
        Anchor(widget.editbox, "TOPRIGHT", frame, "TOPRIGHT", -12, -12, controlWidth, 30)
        Anchor(widget.button, "TOPRIGHT", widget.editbox, "BOTTOMRIGHT", 0, -8, 64, 28)
        widget.editbox:SetTextInsets(8, 8, 3, 3)
        widget.button:SetEnabled(not widget.disabled)
        -- Reserve the submit row even while AceGUI hides OK, so typing never moves the following controls.
        height = math.max(height, 92)
    elseif kind == "ColorPicker" then
        Anchor(widget.colorSwatch, "TOPRIGHT", frame, "TOPRIGHT", -12, -13, 26, 26)
    elseif kind == "APRSettingsAction" then
        Anchor(widget.button, "TOPRIGHT", frame, "TOPRIGHT", -12, -12, 160, 30)
    end
    widget.alignoffset = 0
    widget:SetHeight(height)
    widget.aprLayingOut = nil
end

function Rows:Apply(widget)
    if not widget then return end
    if supported[widget.type] and widget:GetUserData("option") then
        if not widget.aprRow then
            local frame = widget.frame
            local separator = frame:CreateTexture(nil, "BACKGROUND")
            separator:SetPoint("BOTTOMLEFT", 12, 0); separator:SetPoint("BOTTOMRIGHT", -12, 0)
            separator:SetHeight(1)
            APR:RegisterThemeRegion(separator, "border", 0.28)
            widget.aprRow = {note = UI:Label(frame, "", 11, "muted")}
            local original = widget.OnWidthSet
            widget.OnWidthSet = function(self, width)
                if original then original(self, width) end
                Layout(self)
            end
            for _, method in ipairs({"SetLabel", "SetValue", "SetDisabled", "SetType", "SetSliderValues", "SetIsPercent",
                "SetText", "DisableButton"}) do
                if widget[method] then hooksecurefunc(widget, method, function() Layout(widget) end) end
            end
            if widget.type == "CheckBox" then
                frame:HookScript("OnMouseDown", function() Layout(widget) end)
                frame:HookScript("OnMouseUp", function() Layout(widget) end)
            elseif widget.type == "EditBox" then
                -- AceGUI still owns validation/visibility; keep its submit button outside the typing area.
                widget.button:SetParent(frame)
                widget.editbox:HookScript("OnTextChanged", function() Layout(widget) end)
                widget.editbox:HookScript("OnEnterPressed", function() Layout(widget) end)
                widget.button:HookScript("OnClick", function() Layout(widget) end)
            end
        end
        -- Dropdown pullouts are released separately and recreated when their owner is reused.
        if widget.type == "Dropdown" and widget.pullout and not widget.pullout.aprRowAnchor then
            widget.pullout.aprRowAnchor = true
            hooksecurefunc(widget.pullout, "Open", function(pullout)
                local owner = pullout:GetUserData("obj")
                if owner and owner.aprRow then
                    pullout.frame:ClearAllPoints()
                    pullout.frame:SetPoint("TOPRIGHT", owner.button_cover, "BOTTOMRIGHT", 0, -2)
                    pullout.frame:RegisterEvent("GLOBAL_MOUSE_DOWN")
                end
            end)
            local pullout = widget.pullout
            pullout.frame:HookScript("OnEvent", function(frame, event)
                local owner = pullout:GetUserData("obj")
                if event == "GLOBAL_MOUSE_DOWN" and owner and owner.open
                    and not frame:IsMouseOver() and not owner.button_cover:IsMouseOver() then
                    -- Close through AceGUI so its open state and callbacks stay in sync.
                    -- Observing the event lets the clicked control receive the same click.
                    owner:ClearFocus()
                end
            end)
            pullout.frame:HookScript("OnHide", function(frame) frame:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
        end
        Layout(widget)
    end
    for _, child in ipairs(widget.children or {}) do self:Apply(child) end
    if widget.DoLayout then widget:DoLayout() end
end
