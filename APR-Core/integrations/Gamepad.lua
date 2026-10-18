-- Forever's native navigation owns input, glyphs, the virtual keyboard and secure clicks.
-- Register only APR windows; never replace the player's bindings or gamepad CVars.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local UI = APR.UI
APR.Gamepad = { windows = setmetatable({}, {__mode = "k"}), serial = 0 }
local Pad = APR.Gamepad
Pad.lists = setmetatable({}, {__mode = "k"})
Pad.settingsRoots = setmetatable({}, {__mode = "k"})

-- Bindings.xml references APR_ItemButton while step controls are anonymous.
-- Resolve a visible action in secure code on the hardware click, including in combat.
-- The renderer installs frame references only when creating controls out of combat.
function Pad:RegisterActionButton(button)
    if InCombatLockdown() or not SecureHandlerWrapScript then return end
    if not self.itemProxy then
        self.itemProxy = CreateFrame("Button", "APR_ItemButton", UIParent,
            "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
        self.itemProxy:EnableMouse(false)
        self.itemProxy:RegisterForClicks("AnyDown", "AnyUp")
        self.itemProxy:SetAttribute("type", "click")
        self.actionButtons = {}
        SecureHandlerWrapScript(self.itemProxy, "PreClick", self.itemProxy, [[
            self:SetAttribute("clickbutton", nil)
            for index = 1, self:GetAttribute("actionCount") or 0 do
                local button = self:GetFrameRef("action" .. index)
                if button and button:IsVisible() and button:GetAttribute("type1") then
                    self:SetAttribute("clickbutton", button)
                    break
                end
            end
        ]])
    end
    for _, registered in ipairs(self.actionButtons) do if registered == button then return end end
    self.actionButtons[#self.actionButtons + 1] = button
    self.itemProxy:SetFrameRef("action" .. #self.actionButtons, button)
    self.itemProxy:SetAttribute("actionCount", #self.actionButtons)
end

function Pad:IsAvailable()
    return InputUtil and InputUtil.IsGamepadUIEnabled and GamepadMode
        and GamepadMode.FrameControlsManager and SmartNavigation
end

function Pad:IsEnabled()
    return self:IsAvailable() and InputUtil.IsGamepadUIEnabled()
end

function Pad:ShowWindow(frame)
    local entry = self.windows[frame]
    if not entry or (entry.owns and not entry.owns()) or not frame:IsVisible()
        or not self:IsEnabled() or InCombatLockdown() then return end
    local manager = GamepadMode.FrameControlsManager
    if self.BuildNavigation then self:BuildNavigation(frame) end
    if not entry.active then
        if entry.popup then entry.returnFrame = manager:GetActiveFrame() end
        entry.active = manager:FrameShown(frame, entry.popup) == true
    end
    self:Refresh(frame)
end

function Pad:HideWindow(frame)
    local entry = self.windows[frame]
    if entry and entry.active then
        entry.active = nil
        if self:IsEnabled() then
            local manager = GamepadMode.FrameControlsManager
            local hadFocus = manager:GetActiveFrame() == frame
            manager:FrameHidden(frame)
            if hadFocus and entry.returnFrame and entry.returnFrame:IsVisible() then
                manager:FocusFrame(entry.returnFrame)
            end
        end
        entry.returnFrame = nil
    end
end

function Pad:RegisterWindow(frame, popup, close, owns)
    if not frame then return end
    if self.windows[frame] then self:ShowWindow(frame); return end
    self.serial = self.serial + 1
    self.windows[frame] = {popup = popup, order = self.serial, owns = owns}
    local previousClose = frame.SmartNavigationCloseHandler
    frame.SmartNavigationCloseHandler = function()
        if owns and not owns() then return previousClose and previousClose(frame) end
        if InCombatLockdown() then return true end
        local entry = self.windows[frame]
        if entry.detailOpener and self:IsEnabled() and entry.detailOpener:IsVisible() then
            local opener = entry.detailOpener
            entry.detailOpener = nil
            SmartNavigation:SelectButton(opener)
            return true
        end
        if close then close() else frame:Hide() end
        return true
    end
    local previousSelect = frame.SmartNavigationOnSelect
    frame.SmartNavigationOnSelect = function(owner, button)
        if previousSelect then previousSelect(owner, button) end
        if owns and not owns() then return end
        -- Native right-stick scrolling needs the viewport associated with the current focus.
        local scroll = button
        while scroll and scroll ~= owner and not scroll:IsObjectType("ScrollFrame") do
            scroll = scroll:GetParent()
        end
        if SmartNavigation and SmartNavigation.SetScrollFrameForFrame then
            SmartNavigation:SetScrollFrameForFrame(owner, scroll ~= owner and scroll or nil)
        end
    end
    frame:HookScript("OnShow", function()
        if not self.windows[frame].manual then self:ShowWindow(frame) end
    end)
    frame:HookScript("OnHide", function() self:HideWindow(frame) end)
    frame:HookScript("OnSizeChanged", function() self:Refresh(frame) end)
    self:ShowWindow(frame)
end

-- Refresh after layout and row recycling have finished. No polling while windows are idle.
local refreshFrame = CreateFrame("Frame")
refreshFrame:Hide()
local pending = setmetatable({}, {__mode = "k"})
function Pad:Refresh(frame)
    if not self:IsEnabled() or not frame then return end
    while frame and not self.windows[frame] do frame = frame:GetParent() end
    if frame and self.windows[frame].active then pending[frame] = true; refreshFrame:Show() end
end
refreshFrame:SetScript("OnUpdate", function()
    refreshFrame:Hide()
    for frame in pairs(pending) do
        pending[frame] = nil
        if Pad:IsEnabled() and Pad.windows[frame].active and frame:IsVisible() and not InCombatLockdown() then
            if Pad.BuildNavigation then Pad:BuildNavigation(frame) end
            SmartNavigation:RefreshButtonGroups(frame)
            if Pad.ApplyFocusRequest then Pad:ApplyFocusRequest(frame) end
            if SmartNavigation:GetActiveFrame() == frame then
                local button = SmartNavigation:GetCurrentButton()
                if not button or not button:IsVisible() then SmartNavigation:SelectFirstButton() end
            end
        end
    end
end)

function Pad:RestoreWindows()
    if not self:IsEnabled() or InCombatLockdown() then return end
    local frames = {}
    for frame, entry in pairs(self.windows) do
        if frame:IsVisible() and not entry.manual then frames[#frames + 1] = {frame = frame, order = entry.order} end
    end
    table.sort(frames, function(a, b) return a.order < b.order end)
    for _, entry in ipairs(frames) do self:ShowWindow(entry.frame) end
    -- These controls may have been built before Blizzard's gamepad addons were loaded.
    for list in pairs(self.lists) do
        if list.scroll:IsVisible() then
            for _, row in pairs(list.active) do self:AdaptListRow(list, row) end
        end
    end
    for widget in pairs(self.settingsRoots) do
        if widget.frame and widget.frame:IsVisible() then self:AdaptSettings(widget) end
    end
end

function Pad:InstallTransitions()
    if self.transitions or not self:IsAvailable() or not InputUtil.RegisterGamepadInit
        or not InputUtil.RegisterGamepadUninit or not InputUtil.RegisterForInterfaceTransitions then return end
    self.transitions = true
    InputUtil.RegisterForInterfaceTransitions(self)
    InputUtil.RegisterGamepadUninit(self, function()
        -- Blizzard resets its manager during the high-priority transition phase.
        for _, entry in pairs(self.windows) do entry.active = nil end
    end)
    InputUtil.RegisterGamepadInit(self, function() self:RestoreWindows() end)
end

-- Sliders need an explicit commit: AceConfig writes ranges on OnMouseUp, not SetValue.
function Pad:AdjustSlider(widget, direction)
    if widget.disabled or InCombatLockdown() then return end
    local slider = widget.slider
    local minimum, maximum = slider:GetMinMaxValues()
    local step = widget.step or slider:GetValueStep()
    if not step or step <= 0 then step = (maximum - minimum) / 100 end
    local value = math.max(minimum, math.min(maximum, slider:GetValue() + direction * step))
    slider:SetValue(value)
    local commit = slider:GetScript("OnMouseUp")
    if commit then commit(slider, "LeftButton") end
end

function Pad:AdaptSettings(widget, seen)
    if not widget then return end
    if not seen then self.settingsRoots[widget] = true end
    seen = seen or {}
    if seen[widget] then return end
    seen[widget] = true
    if self.OwnSettingsWidget then self:OwnSettingsWidget(widget) end
    if widget.type == "ScrollFrame" and self.AdaptAceScroll then
        self:AdaptAceScroll(widget, widget.scrollframe, widget.content, widget.scrollbar)
    elseif (widget.type == "ColorPicker" or widget.type == "APRThemeAccent") and self.AdaptColor then
        self:AdaptColor(widget)
    elseif widget.type == "Dropdown" and widget.button_cover then
        -- The arrow and cover execute the same callback; expose one target, not two overlapping ones.
        if widget.button then widget.button.smartNavigationIgnored = true end
        widget.button_cover:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    elseif widget.type == "Slider" and widget.slider and SmartNavigation_AddJumpNavigationOverride
        and SMART_NAV_INPUT_DIRECTION then
        local slider = widget.slider
        widget.frame.smartNavigationIgnoredDontPropagate = true
        slider.smartNavigationCanFocus = true
        -- Leave up/down to native navigation so the user can exit the control.
        for _, entry in ipairs({{"LEFT", -1}, {"RIGHT", 1}}) do
            local direction = entry[2]
            local function adjust()
                self:AdjustSlider(widget, direction)
                return true -- consume this direction even if AceConfig rebuilt the widget
            end
            if self.SetDirection then self:SetDirection(slider, entry[1], adjust)
            else SmartNavigation_AddJumpNavigationOverride(slider, SMART_NAV_INPUT_DIRECTION[entry[1]], adjust) end
        end
        slider.OnSmartNavClick = function()
            -- Confirm reaches exact numeric entry without moving the thumb to the mouse cursor.
            if widget.editbox and widget.editbox:IsVisible() and not widget.disabled and not InCombatLockdown() then
                SmartNavigation:SelectButton(widget.editbox)
            end
        end
    elseif widget.type == "Dropdown-Pullout" and widget.frame then
        if self.AdaptAceScroll then self:AdaptAceScroll(widget, widget.scrollFrame, widget.itemFrame, widget.slider) end
        self:RegisterWindow(widget.frame, true, function() widget:Close() end,
            function() return not self.OwnSettingsWidget or widget.aprPadOwned == true end)
    end
    for _, child in ipairs(widget.children or {}) do self:AdaptSettings(child, seen) end
    if widget.pullout then
        self:AdaptSettings(widget.pullout, seen)
        for _, item in widget.pullout:IterateItems() do self:AdaptSettings(item, seen) end
    end
    if widget.frame then self:Refresh(widget.frame) end
end

-- Navigate by record index, not by recycled frame identity. This reaches every record,
-- including those for which no frame exists yet, and keeps the same action column.
function Pad:NavigateList(list, row, path, delta)
    if InCombatLockdown() then return true end
    local index = row.boundIndex
    if not index or list.active[index] ~= row then return end
    index = index + delta
    while index >= 1 and index <= #list.items do
        local top, bottom = list.offsets[index], list.offsets[index + 1]
        local offset, height = list.scroll:GetVerticalScroll(), list.scroll:GetHeight()
        if top < offset then list:ScrollTo(top)
        elseif bottom > offset + height then list:ScrollTo(bottom - height) end
        local target = list.active[index]
        for _, childIndex in ipairs(path) do
            target = target and ({target:GetChildren()})[childIndex]
        end
        if target and target:IsVisible() and (not target.IsEnabled or target:IsEnabled()) then return target end
        index = index + delta
    end
end

function Pad:AdaptListRow(list, row)
    self.lists[list] = true
    if not SmartNavigation_AddJumpNavigationOverride or not SMART_NAV_INPUT_DIRECTION then return end
    if row.aprGamepadList == list then return end
    row.aprGamepadList = list
    local function visit(frame, path)
        if frame:IsObjectType("Button") or frame:IsObjectType("EditBox") then
            for _, entry in ipairs({{"UP", -1}, {"DOWN", 1}}) do
                local delta = entry[2]
                local function navigate()
                    return self:NavigateList(list, row, path, delta)
                end
                if self.SetDirection then self:SetDirection(frame, entry[1], navigate)
                else SmartNavigation_AddJumpNavigationOverride(frame, SMART_NAV_INPUT_DIRECTION[entry[1]], navigate) end
            end
        end
        for index, child in ipairs({frame:GetChildren()}) do
            local childPath = {unpack(path)}
            childPath[#childPath + 1] = index
            visit(child, childPath)
        end
    end
    visit(row, {})
end

function Pad:RunAction(action)
    if InCombatLockdown() then APR:PrintInfo(L["GAMEPAD_COMBAT"]); return end
    if action == "menu" then self:ToggleMenu(); return end
    if action == "route" or action == "options" or action == "status" or action == "about" or action == "perf" then
        APR.Workspace:Show(action)
        if self:IsEnabled() and APR.Workspace.frame then
            self:ShowWindow(APR.Workspace.frame)
            GamepadMode.FrameControlsManager:FocusFrame(APR.Workspace.frame)
        end
        return
    end
    if action == "layout" then APR.LayoutEditor:Show(); return end
    if action == "binding" then self:CaptureMenuBinding(); return end
    if action == "worldcoords" then APR.worldCoordinateConverter:Show(); return end
    if not APR.settings.profile.enableAddon then return end
    if action == "skip" or action == "rollback" then
        if not APR.ActiveRoute then return end
        APR.command:SlashCmd(action)
    else
        local panels = {step = CurrentStepScreenPanel, steps = QuestOrderListPanel, fillers = FillersScreenPanel,
            xp = APRXPBuffOverlay, group = PartyScreenPanel, heirloom = HeirloomPanel, buffs = BuffFrameScreen}
        local frame = panels[action]
        if not frame or not frame:IsVisible() or not self:IsEnabled() then return end
        -- Gameplay panels join focus only when requested, never on every quest update.
        if not self.windows[frame] then
            self:RegisterWindow(frame, false, function() self:HideWindow(frame) end)
            self.windows[frame].manual = true
        else self:ShowWindow(frame) end
        GamepadMode.FrameControlsManager:FocusFrame(frame)
    end
end

function Pad:ToggleMenu()
    if self.menu and self.menu:IsShown() then self.menu:Hide(); return end
    if not self.menu then
        local frame = UI:Window("APRGamepadMenu", L["GAMEPAD_MENU"], 520, 650, "library")
        self.menu = frame
        local scroll = UI:Scroll(frame.content)
        scroll:SetPoint("TOPLEFT"); scroll:SetPoint("BOTTOMRIGHT", -24, 115)
        local content = CreateFrame("Frame", nil, scroll)
        scroll:SetScrollChild(content)
        scroll:HookScript("OnSizeChanged", function() content:SetWidth(scroll:GetWidth()) end)
        content:SetWidth(scroll:GetWidth())
        local actions = {
            {"route", L["ROUTE_SELECTION"]}, {"options", GAMEOPTIONS_MENU},
            {"step", L["CURRENT_STEP"]}, {"skip", L["SKIP"]}, {"rollback", L["ROLLBACK"]},
            {"steps", L["QUEST_ORDER_LIST"]}, {"fillers", L["STEP_FILLERS"]}, {"xp", L["XP_BUFF_OVERLAY"]},
            {"group", L["GROUP"]}, {"heirloom", L["HEIRLOOM"]}, {"buffs", L["BUFF"]},
            {"layout", L["UI_LAYOUT_TITLE"]}, {"status", L["STATUS"]}, {"about", L["ABOUT_HELP"]},
            {"perf", L["UI_PERFORMANCE"]}, {"worldcoords", L["UI_STATUS_WORLD_COORDINATES"]},
        }
        content:SetHeight(#actions * 42)
        self.menuButtons = {}
        for index, entry in ipairs(actions) do
            local action = entry[1]
            local button = UI:Button(content, entry[2], 1, function()
                frame:Hide(); self:RunAction(action)
            end)
            self.menuButtons[action] = button
            button:SetPoint("TOPLEFT", 4, -(index - 1) * 42)
            button:SetPoint("TOPRIGHT", -4, -(index - 1) * 42)
            button:SetHeight(36)
        end
        local help = UI:Label(frame.content, L["GAMEPAD_HELP"], 12)
        help:SetPoint("BOTTOMLEFT", 4, 40); help:SetPoint("RIGHT", -4, 0)
        help:SetWordWrap(true)
        local bind = UI:Button(frame.content, KEY_BINDINGS, 1, function() self:RunAction("binding") end)
        bind:SetPoint("BOTTOMLEFT", 4, 0); bind:SetPoint("BOTTOMRIGHT", -4, 0)
    end
    local panels = {step = CurrentStepScreenPanel, steps = QuestOrderListPanel, fillers = FillersScreenPanel,
        xp = APRXPBuffOverlay, group = PartyScreenPanel, heirloom = HeirloomPanel, buffs = BuffFrameScreen}
    for _, action in ipairs({"step", "steps", "fillers", "xp", "group", "heirloom", "buffs"}) do
        self.menuButtons[action]:SetEnabled(panels[action] and panels[action]:IsVisible() or false)
    end
    self.menu:Show()
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
watcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Do not leave UI input captured while its actions are unavailable in combat.
        for frame in pairs(Pad.windows) do Pad:HideWindow(frame) end
        return
    end
    Pad:InstallTransitions()
    Pad:RestoreWindows()
end)
Pad:InstallTransitions()

for action, label in pairs({MENU = "GAMEPAD_MENU", ROUTES = "ROUTE_SELECTION", OPTIONS = "SHOW_MENU",
    SKIP = "SKIP", PREVIOUS = "ROLLBACK", STEP = "CURRENT_STEP"}) do
    _G["BINDING_NAME_APR_" .. action] = L[label]
end
