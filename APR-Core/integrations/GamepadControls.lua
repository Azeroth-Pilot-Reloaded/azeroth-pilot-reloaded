-- Controller-only editors for operations which otherwise require a mouse drag.
local Pad, UI = APR.Gamepad, APR.UI
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function Pad:CaptureMenuBinding()
    if InCombatLockdown() or not self:IsEnabled() then return end
    if not self.bindingCapture then
        local frame = UI:Window("APRGamepadBinding", L["GAMEPAD_MENU"], 560, 260)
        self.bindingCapture = frame
        self.windows[frame].popup = true
        frame:SetResizeBounds(400, 230)
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:SetFrameLevel(1000)
        local help = UI:Label(frame.content, L["GAMEPAD_BIND_PROMPT"], 14)
        help:SetPoint("TOPLEFT"); help:SetPoint("TOPRIGHT"); help:SetWordWrap(true)
        local cancel = UI:Button(frame.content, CANCEL, 150, function() frame:Hide() end)
        cancel:SetPoint("BOTTOMRIGHT")
        frame:EnableKeyboard(true)
        frame:SetPropagateKeyboardInput(false)
        frame:SetScript("OnKeyDown", function(_, key) if key == "ESCAPE" then frame:Hide() end end)
        frame:SetScript("OnGamePadButtonDown", function(_, button)
            if InCombatLockdown() then frame:Hide(); return end
            if button == "PADBACK" then frame:Hide(); return end
            -- Match Blizzard's keybind editor, including emulated modifier chords.
            local key = GetConvertedKeyOrButton and GetConvertedKeyOrButton(button) or button
            if IsKeyPressIgnoredForBinding and IsKeyPressIgnoredForBinding(key) then return end
            if not key:match("^PAD") then return end
            for _, modifier in ipairs({"GamePadEmulateCtrl", "GamePadEmulateShift", "GamePadEmulateAlt"}) do
                if GetCVar(modifier) == button then return end
            end
            if CreateKeyChordStringUsingMetaKeyState then key = CreateKeyChordStringUsingMetaKeyState(key) end
            local context = C_KeyBindings and C_KeyBindings.GetBindingContextForAction("APR_MENU")
            local old = GetBindingAction(key, false, context)
            frame:Hide()
            local label = GetBindingText and GetBindingText(key, "KEY_") or key
            local message = string.format(L["GAMEPAD_BIND_CONFIRM"], label)
            if old and old ~= "" and old ~= "APR_MENU" then
                message = message .. "\n" .. string.format(L["GAMEPAD_BIND_REPLACE"], _G["BINDING_NAME_" .. old] or old)
            end
            UI:ShowConfirmationDialog(message, function()
                if InCombatLockdown() then APR:PrintInfo(L["GAMEPAD_COMBAT"]); return end
                if SetBinding(key, "APR_MENU", context) then
                    SaveBindings(GetCurrentBindingSet())
                    APR:PrintInfo(string.format(L["GAMEPAD_BIND_SAVED"], label))
                else APR:PrintInfo(L["GAMEPAD_BIND_FAILED"]) end
            end, nil, self.menu)
        end)
        frame:HookScript("OnShow", function() frame:EnableGamePadButton(true) end)
        frame:HookScript("OnHide", function() frame:EnableGamePadButton(false) end)
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        APR:RegisterSupportedEvent(frame, "GAME_PAD_DISCONNECTED")
        frame:SetScript("OnEvent", function() frame:Hide() end)
    end
    self.bindingCapture:Show()
end

-- Keep changes private until Apply. Cancel/Back therefore never alter settings or
-- the theme draft (including its class-colour choice).
function Pad:ShowColor(widget)
    if InCombatLockdown() or widget.disabled then return end
    if not self.colorEditor then
        local frame = UI:Window("APRGamepadColor", COLOR_PICKER or "Color", 540, 370)
        self.colorEditor = frame
        self.windows[frame].popup = true
        frame:SetResizeBounds(440, 350)
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame.channels = {}
        for index, name in ipairs({"R", "G", "B", "A"}) do
            local channel = index
            local label = UI:Label(frame.content, name, 14)
            label:SetPoint("TOPLEFT", 4, -(index - 1) * 49)
            local slider = CreateFrame("Slider", nil, frame.content, "OptionsSliderTemplate")
            slider:SetPoint("TOPLEFT", 88, -(index - 1) * 49)
            slider:SetPoint("TOPRIGHT", -12, -(index - 1) * 49)
            slider:SetHeight(18); slider:SetMinMaxValues(0, 255); slider:SetValueStep(1)
            slider:SetObeyStepOnDrag(true)
            slider.smartNavigationCanFocus = true
            slider.OnSmartNavClick = function() end
            slider:SetScript("OnValueChanged", function(_, value)
                frame.values[channel] = math.floor(value + 0.5) / 255
                label:SetText(name .. "  " .. math.floor(value + 0.5))
                frame.swatch:SetColorTexture(unpack(frame.values))
            end)
            for _, entry in ipairs({{"LEFT", -1}, {"RIGHT", 1}}) do
                local delta = entry[2]
                self:SetDirection(slider, entry[1], function()
                    slider:SetValue(math.max(0, math.min(255, slider:GetValue() + delta)))
                    return true
                end)
            end
            frame.channels[index] = {slider = slider, label = label}
        end
        frame.swatch = frame.content:CreateTexture(nil, "ARTWORK")
        frame.swatch:SetPoint("BOTTOMLEFT", 4, 0); frame.swatch:SetSize(48, 30)
        local apply = UI:Button(frame.content, APPLY, 135, function()
            local target, values = frame.target, frame.values
            frame:Hide()
            if InCombatLockdown() or not target or target.disabled or not target.frame:IsVisible() then return end
            target:SetColor(unpack(values))
            -- AceConfig commits both callbacks. Fire only the final one, as it may
            -- immediately release and recycle the originating widget.
            target:Fire("OnValueConfirmed", unpack(values))
        end)
        apply:SetPoint("BOTTOMRIGHT")
        local cancel = UI:Button(frame.content, CANCEL, 135, function() frame:Hide() end)
        cancel:SetPoint("RIGHT", apply, "LEFT", -8, 0)
        self:LinkHorizontal({cancel, apply})
        frame:HookScript("OnHide", function() frame.target = nil end)
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:SetScript("OnEvent", function() frame:Hide() end)
    end
    local frame = self.colorEditor
    frame.target, frame.values = widget, {widget.r, widget.g, widget.b, widget.HasAlpha and (widget.a or 1) or 1}
    for index, channel in ipairs(frame.channels) do
        local visible = index < 4 or widget.HasAlpha
        channel.slider:SetShown(visible); channel.label:SetShown(visible)
        channel.slider:SetValue(frame.values[index] * 255)
    end
    frame.swatch:SetColorTexture(unpack(frame.values))
    frame:Show()
    self:RequestFocus(frame.content)
end

function Pad:AdaptColor(widget)
    if widget.aprPadColor then return end
    widget.aprPadColor = true
    local frame = widget.frame
    local click, smartClick, release = frame:GetScript("OnClick"), frame.OnSmartNavClick, widget.OnRelease
    local rect = frame.aprGamepadRect
    frame.aprGamepadRect = widget.colorSwatch
    if widget.classButton then self:LinkHorizontal({widget.classButton, frame}) end
    frame.OnSmartNavClick = function() self:ShowColor(widget) end
    frame:SetScript("OnClick", function(button, ...)
        if self:IsEnabled() and SmartNavigation:GetCurrentButton() == button then self:ShowColor(widget)
        elseif click then click(button, ...) end
    end)
    widget.OnRelease = function(target, ...)
        if self.colorEditor and self.colorEditor.target == target then self.colorEditor:Hide() end
        frame:SetScript("OnClick", click); frame.OnSmartNavClick = smartClick
        frame.aprGamepadRect = rect
        if widget.classButton then widget.classButton.aprPadDirections = nil end
        target.aprPadColor, target.OnRelease = nil, release
        if release then return release(target, ...) end
    end
end
