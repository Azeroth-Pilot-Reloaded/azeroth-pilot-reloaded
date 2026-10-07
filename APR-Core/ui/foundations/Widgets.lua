-- Small APR-owned controls shared by the library, settings, diagnostics and performance windows.
-- Windows are lazy, clamped to screen, keyboard-dismissable and registered with the selected skin.

APR.UI = {}
local UI = APR.UI

function UI:Label(parent, text, size, role)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    APR:RegisterFontString(label, "general", { role = role or "base", sizeDelta = (size or 12) - 12 })
    return label
end

function UI:Panel(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    APR:RegisterSkinTarget(frame, "panel", { themeSurface = true, preserveContent = true })
    return frame
end

function UI:Button(parent, text, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 130, 30)
    local label = self:Label(button, text, 12)
    label:SetPoint("LEFT", 10, 0)
    label:SetPoint("RIGHT", -10, 0)
    label:SetJustifyH("CENTER")
    button:SetFontString(label)
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self)
        if self:IsEnabled() and self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(APR:GetThemeColor("accent"))) end
    end)
    button:SetScript("OnLeave", function(self)
        if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(APR:GetThemeColor("border"))) end
    end)
    button:SetScript("OnEnable", function() label:SetAlpha(1) end)
    button:SetScript("OnDisable", function() label:SetAlpha(0.4) end)
    APR:RegisterSkinTarget(button, "button", { themeSurface = true })
    return button
end

function UI:SearchBox(parent, width, placeholder, changed)
    local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    edit:SetSize(width or 280, 32)
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlight)
    edit:SetTextInsets(10, 10, 0, 0)
    edit:SetMaxLetters(160)
    edit.placeholder = self:Label(edit, placeholder, 12, "muted")
    edit.placeholder:SetPoint("LEFT", 10, 0)
    edit.placeholder:SetPoint("RIGHT", -10, 0)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self)
        self.placeholder:SetShown(self:GetText() == "")
        changed(self:GetText())
    end)
    APR:RegisterSkinTarget(edit, "editbox", { themeSurface = true })
    return edit
end

function UI:Tooltip(control, title, description)
    control:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        APR:SetTooltipText(GameTooltip, title, "general", "accent")
        if description then APR:AddTooltipLine(GameTooltip, description, "general", "base", true) end
        GameTooltip:Show()
    end)
    control:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

function UI:Window(name, title, width, height)
    local frame = self:Panel(UIParent)
    _G[name] = frame
    frame:SetSize(math.min(width, UIParent:GetWidth() - 40), math.min(height, UIParent:GetHeight() - 60))
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(math.min(680, UIParent:GetWidth() - 40), math.min(430, UIParent:GetHeight() - 60))
    frame:EnableMouse(true)
    frame:SetToplevel(true)
    frame.header = CreateFrame("Frame", nil, frame)
    frame.header:SetPoint("TOPLEFT", 16, -8)
    frame.header:SetPoint("TOPRIGHT", -52, -8)
    frame.header:SetHeight(42)
    frame.header:EnableMouse(true)
    frame.header.Text = self:Label(frame.header, title, 20, "accent")
    frame.header.Text:SetPoint("LEFT")
    APR:SetupHeaderDrag(frame.header, frame, function() return not InCombatLockdown() end)
    frame.close = self:Button(frame, "×", 30, function() frame:Hide() end)
    frame.close:SetPoint("TOPRIGHT", -12, -12)
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", 16, -58)
    frame.content:SetPoint("BOTTOMRIGHT", -16, 16)
    frame.resize = self:Button(frame, "◢", 22, function() end)
    frame.resize:SetHeight(22)
    frame.resize:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.resize:SetScript("OnMouseDown", function() if not InCombatLockdown() then frame:StartSizing("BOTTOMRIGHT") end end)
    frame.resize:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
    frame:SetScript("OnHide", function(self) self:StopMovingOrSizing(); GameTooltip:Hide() end)
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, name)
    frame:Hide()
    return frame
end
