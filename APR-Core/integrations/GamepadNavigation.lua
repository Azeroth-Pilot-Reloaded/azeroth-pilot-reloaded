-- APR supplies predictable neighbours; Forever still owns input and hardware clicks.
local Pad = APR.Gamepad
local directions = {"LEFT", "RIGHT", "UP", "DOWN"}

local function Within(frame, ancestor)
    while frame do
        if frame == ancestor then return true end
        frame = frame:GetParent()
    end
    return false
end

function Pad:CanFocus(frame)
    if not frame or not frame:IsVisible() or (frame.IsEnabled and not frame:IsEnabled()) then return false end
    if frame.obj and frame.obj.disabled then return false end
    if frame.smartNavigationIgnoredDontPropagate or frame.smartNavigationIgnoredContainerFrame then return false end
    local parent = frame
    while parent do
        if parent.smartNavigationIgnored then return false end
        parent = parent:GetParent()
    end
    return frame.smartNavigationCanFocus or frame:IsObjectType("Button") or frame:IsObjectType("EditBox")
        or frame:GetScript("OnMouseDown") or frame:GetScript("OnMouseUp")
end

-- Work in a single coordinate space, including controls with independently scaled parents.
local function Rect(frame)
    local region = frame.aprGamepadRect or frame
    if not region.GetRect then return end
    local x, y, width, height = region:GetRect()
    if not x or not y or not width or not height or width <= 0 or height <= 0 then return end
    local scale = region:GetEffectiveScale()
    return {left = x * scale, bottom = y * scale, right = (x + width) * scale,
        top = (y + height) * scale, x = (x + width / 2) * scale, y = (y + height / 2) * scale}
end

local function Viewport(frame)
    local parent = frame:GetParent()
    while parent do
        if parent:IsObjectType("ScrollFrame") then return parent end
        parent = parent:GetParent()
    end
end

local function InView(frame)
    local box, scroll = Rect(frame), Viewport(frame)
    if not box then return false end
    while scroll do
        local view = Rect(scroll)
        if view and (box.top <= view.bottom or box.bottom >= view.top
            or box.right <= view.left or box.left >= view.right) then return false end
        scroll = Viewport(scroll)
    end
    return true
end

function Pad:Reveal(frame)
    local scroll = Viewport(frame)
    while scroll do
        local box, view = Rect(frame), Rect(scroll)
        if box and view and scroll.GetVerticalScroll and scroll.SetVerticalScroll then
            local delta = box.top > view.top and view.top - box.top
                or box.bottom < view.bottom and view.bottom - box.bottom or 0
            if delta ~= 0 then
                local offset = scroll:GetVerticalScroll() + delta / scroll:GetEffectiveScale()
                scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScrollRange(), offset)))
            end
        end
        scroll = Viewport(scroll)
    end
end

function Pad:SetDirection(frame, direction, target)
    frame.aprPadDirections = frame.aprPadDirections or {}
    frame.aprPadDirections[direction] = target
    self:InstallControl(frame)
end

function Pad:InstallControl(frame)
    if not SmartNavigation_AddJumpNavigationOverride or not SMART_NAV_INPUT_DIRECTION then return end
    if frame.aprPadNavigation then return end
    frame.aprPadNavigation = true
    for _, key in ipairs(directions) do
        local direction = key
        SmartNavigation_AddJumpNavigationOverride(frame, SMART_NAV_INPUT_DIRECTION[key], function()
            return self:NavigateControl(frame, direction)
        end)
    end
end

function Pad:LinkHorizontal(buttons, leaveRow)
    for index, button in ipairs(buttons) do
        for _, entry in ipairs({{"LEFT", -1}, {"RIGHT", 1}}) do
            local start, delta = index, entry[2]
            self:SetDirection(button, entry[1], function()
                local nextIndex = start + delta
                while buttons[nextIndex] do
                    if self:CanFocus(buttons[nextIndex]) then
                        local source, target = Rect(button), Rect(buttons[nextIndex])
                        if source and target and math.min(source.top, target.top) <= math.max(source.bottom, target.bottom) then
                            return true -- wrapped settings tabs belong to a different visual row
                        end
                        return buttons[nextIndex]
                    end
                    nextIndex = nextIndex + delta
                end
                if not leaveRow then return true end -- keep header rows from jumping diagonally
            end)
        end
    end
end

function Pad:CollectControls(root)
    local controls = {}
    local function visit(frame)
        if not frame:IsVisible() or frame.smartNavigationIgnored then return end
        -- A dropdown/confirmation owns its own navigation while it is open.
        if frame ~= root and self.windows[frame] then return end
        local count = #controls
        local isScroll = frame:IsObjectType("ScrollFrame")
        if frame ~= root and not isScroll and self:CanFocus(frame) then
            controls[#controls + 1] = frame
            self:InstallControl(frame)
        end
        for _, child in ipairs({frame:GetChildren()}) do visit(child) end
        if frame ~= root and isScroll and #controls == count and self:CanFocus(frame) then
            controls[#controls + 1] = frame
            self:InstallControl(frame)
        end
    end
    visit(root)
    return controls
end

function Pad:BuildNavigation(root)
    local entry = self.windows[root]
    if entry then entry.controls = self:CollectControls(root) end
end

function Pad:NavigateControl(source, direction)
    local root = SmartNavigation:GetActiveFrame()
    local entry = root and self.windows[root]
    -- A pooled AceGUI control can later belong to another addon.
    if not entry or not entry.active or (entry.owns and not entry.owns()) then return end
    if InCombatLockdown() or not self:IsEnabled() then return true end
    local override = source.aprPadDirections and source.aprPadDirections[direction]
    if override then
        local result = override
        if type(override) == "function" then result = override() end
        if result == true then return true end
        if self:CanFocus(result) then self:Reveal(result); return result end
    end
    local origin = Rect(source)
    if not entry or not origin then return true end
    local horizontal = direction == "LEFT" or direction == "RIGHT"
    local positive = direction == "RIGHT" or direction == "UP"
    local best, bestScore
    local viewport = Viewport(source)
    for _, candidate in ipairs(entry.controls or {}) do
        if candidate ~= source and self:CanFocus(candidate)
            and (InView(candidate) or (not horizontal and viewport and Viewport(candidate) == viewport)) then
            local box = Rect(candidate)
            if box then
                local primary = horizontal and box.x - origin.x or box.y - origin.y
                if not positive then primary = -primary end
                if primary > 1 then
                    local overlap = horizontal and math.min(origin.top, box.top) - math.max(origin.bottom, box.bottom)
                        or not horizontal and math.min(origin.right, box.right) - math.max(origin.left, box.left)
                    local cross = horizontal and math.abs(box.y - origin.y) or math.abs(box.x - origin.x)
                    -- Prioritise the same row/column before distance. Wide buttons must not
                    -- lose to a nearer diagonal, as with native centre-to-centre navigation.
                    local score = (overlap > 1 and 0 or 1000000) + primary + cross * 0.25
                    if not bestScore or score < bestScore then best, bestScore = candidate, score end
                end
            end
        end
    end
    if best then self:Reveal(best); return best end
    return true
end

function Pad:OwnSettingsWidget(widget)
    if widget.aprPadOwned then return end
    widget.aprPadOwned = true
    local release = widget.OnRelease
    local flags = {}
    local function remember(frame)
        if not frame then return end
        flags[#flags + 1] = {frame = frame, ignored = frame.smartNavigationIgnored,
            ignoredSelf = frame.smartNavigationIgnoredDontPropagate, focus = frame.smartNavigationCanFocus,
            click = frame.OnSmartNavClick}
    end
    remember(widget.frame); remember(widget.slider); remember(widget.button); remember(widget.scrollbar)
    widget.OnRelease = function(target, ...)
        self.settingsRoots[target] = nil
        target.aprPadOwned, target.OnRelease = nil, release
        for _, saved in ipairs(flags) do
            local frame = saved.frame
            frame.smartNavigationIgnored, frame.smartNavigationIgnoredDontPropagate = saved.ignored, saved.ignoredSelf
            frame.smartNavigationCanFocus, frame.OnSmartNavClick = saved.focus, saved.click
            frame.aprPadDirections = nil
        end
        if target.frame then self:HideWindow(target.frame) end
        if release then return release(target, ...) end
    end
end

function Pad:RequestFocus(root, opener)
    if not self:IsEnabled() or InCombatLockdown() then return end
    self.focusRequest = {root = root, opener = opener}
    self:Refresh(root)
end

function Pad:ApplyFocusRequest(window)
    local request = self.focusRequest
    if not request or not Within(request.root, window) then return end
    self.focusRequest = nil
    if SmartNavigation:GetActiveFrame() ~= window or not request.root:IsVisible() then return end
    for _, control in ipairs(self:CollectControls(request.root)) do
        if self:CanFocus(control) then
            self:Reveal(control)
            SmartNavigation:SelectButton(control)
            if request.opener then self.windows[window].detailOpener = request.opener end
            return
        end
    end
end

-- Confirm and secondary click on a navigation tab enter its new content after AceConfig
-- has finished rebuilding it. Directional Right/Down can use the same transition.
function Pad:BindDetails(button, direction, open, content)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local function enter()
        open()
        self:RequestFocus(content(), button)
        return true
    end
    self:SetDirection(button, direction, enter)
    if not button.aprPadDetailsHook then
        button.aprPadDetailsHook = true
        button:HookScript("OnClick", function()
            if self:IsEnabled() and SmartNavigation:GetCurrentButton() == button then
                self:RequestFocus(content(), button)
            end
        end)
    end
end

-- AceGUI scrolls by moving its child anchors and stores 0..1000 in its scrollbar.
-- Adapt only these instances to the pixel API consumed by Forever. No double scrolling,
-- and restore the native methods when a widget returns to an external/shared pool.
function Pad:AdaptAceScroll(widget, scroll, child, bar)
    if not scroll or not child or not bar or widget.aprPadScroll then return end
    local saved = {scroll.GetVerticalScroll, scroll.GetVerticalScrollRange, scroll.SetVerticalScroll}
    widget.aprPadScroll = saved
    scroll.GetVerticalScrollRange = function() return math.max(0, child:GetHeight() - scroll:GetHeight()) end
    scroll.GetVerticalScroll = function()
        local status = widget.status or widget.localstatus or widget.scrollStatus
        return status and status.offset or 0
    end
    scroll.SetVerticalScroll = function(_, offset)
        local range = scroll:GetVerticalScrollRange()
        local value = range > 0 and math.max(0, math.min(1000, offset / range * 1000)) or 0
        bar:SetValue(value)
        widget:SetScroll(value)
    end
    bar.smartNavigationIgnored = true
    local release = widget.OnRelease
    widget.OnRelease = function(self, ...)
        scroll.GetVerticalScroll, scroll.GetVerticalScrollRange, scroll.SetVerticalScroll = unpack(saved)
        self.aprPadScroll = nil
        self.OnRelease = release
        if release then return release(self, ...) end
    end
end

-- Non-Ace scrollable reports still need an entry point even if they contain only text.
function Pad:PrepareScroll(scroll)
    scroll.smartNavigationCanFocus = true
    scroll.OnSmartNavClick = function() end
    if scroll.ScrollBar then scroll.ScrollBar.smartNavigationIgnored = true end
end
