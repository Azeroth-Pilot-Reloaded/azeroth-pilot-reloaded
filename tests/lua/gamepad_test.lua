-- Exercise APR's adapter against the native Forever lifecycle contract, not raw pad events.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local methods, created = env.methods, {}
local createFrame = CreateFrame
function CreateFrame(kind, ...)
    local frame = createFrame(kind, ...)
    frame.kind = kind
    created[#created + 1] = frame
    return frame
end
function methods:IsObjectType(kind) return self.kind == kind end
function methods:GetChildren() return unpack(self.children or {}) end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:GetScript(key) return self.scripts[key] end
function methods:GetAttribute(key) return (self.attributes or {})[key] end
function methods:SetFrameRef(key, value) self.refs = self.refs or {}; self.refs[key] = value end
function methods:GetFrameRef(key) return self.refs[key] end
function methods:EnableMouse(value) self.mouseEnabled = value end
function methods:IsMouseEnabled() return self.mouseEnabled ~= false end
function methods:RegisterForClicks(...) self.clicks = {...} end
function methods:GetMinMaxValues() return self.minimum, self.maximum end
function methods:GetValue() return self.value end
function methods:GetValueStep() return self.step or 1 end
local show, hide = methods.Show, methods.Hide
function methods:Show()
    local changed = not self.shown
    show(self)
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    local changed = self.shown
    hide(self)
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
local function tick()
    for _, frame in ipairs(created) do
        if frame:IsShown() and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 0.01) end
    end
end
APR.UI = {RefreshListRow = function() end}
APR.settings = {profile = {enableAddon = true}}
APR.command = {SlashCmd = function(self, command) self.last = command end}
APR.Workspace = {Show = function(self, page) self.page = page end}
function APR:PrintInfo(message) self.message = message end
-- Secure snippets receive restricted handles, not native widget tables. Only
-- expose APIs actually provided by RestrictedFrames.lua; in particular no Click.
local handles = setmetatable({}, {__mode = "k"})
local function handle(frame)
    if not handles[frame] then
        handles[frame] = {
            GetAttribute = function(_, key) return frame:GetAttribute(key) end,
            SetAttribute = function(_, key, value)
                frame.attributes = frame.attributes or {}
                frame.attributes[key] = value -- secure writes are allowed in combat
            end,
            GetFrameRef = function(_, key)
                local ref = frame:GetFrameRef(key)
                return ref and handle(ref)
            end,
            IsVisible = function() return frame:IsVisible() end,
            IsMouseEnabled = function() return frame:IsMouseEnabled() end,
        }
    end
    return handles[frame]
end
function SecureHandlerWrapScript(frame, script, owner, body)
    assert(script == "PreClick" and frame == owner)
    local chunk = assert(loadstring("return function(self) " .. body .. " end"))
    setfenv(chunk, {ipairs = ipairs, newtable = function(...) return {...} end})
    local snippet = chunk()
    frame.secureClick = function() snippet(handle(frame)) end
end

-- Old clients have no native navigation. Loading, bindings and normal windows still work.
InputUtil, GamepadMode, SmartNavigation = nil, nil, nil
dofile("APR-Core/integrations/Gamepad.lua")
dofile("APR-Core/integrations/GamepadNavigation.lua")
local pad = APR.Gamepad
local events = created[#created]
local window = CreateFrame("Frame", nil, UIParent)
window:Hide()
pad:RegisterWindow(window)
window:Show()
pad:RunAction("route")
assert(APR.Workspace.page == "route")
assert(not pad:IsEnabled())
dofile("APR-Core/ui/foundations/VirtualList.lua")
local earlyScroll = CreateFrame("ScrollFrame", nil, window); earlyScroll:SetSize(300, 90)
local earlyList = APR.VirtualList:New(earlyScroll, function(parent)
    return CreateFrame("Button", nil, parent)
end, function() end, 30)
earlyList:SetItems({1, 2})
assert(not earlyList.active[1].overrides)

local enabled, added, removed, refreshed = true, 0, 0, 0
local transitions = {}
InputUtil = {
    IsGamepadUIEnabled = function() return enabled end,
    RegisterForInterfaceTransitions = function() end,
    RegisterGamepadUninit = function(_, callback) transitions.uninit = callback end,
    RegisterGamepadInit = function(_, callback) transitions.init = callback; callback() end,
}
local manager = {shown = {}}
function manager:FrameShown(frame)
    if self.shown[frame] then return false end
    self.shown[frame] = true; self.active = frame; added = added + 1
    return true
end
function manager:FrameHidden(frame)
    self.shown[frame] = nil; removed = removed + 1
    if self.active == frame then self.active = nil end
end
function manager:GetActiveFrame() return self.active end
function manager:FocusFrame(frame) if self.shown[frame] then self.active = frame end end
GamepadMode = {FrameControlsManager = manager}
SmartNavigation = {
    RefreshButtonGroups = function() refreshed = refreshed + 1 end,
    GetActiveFrame = function() return manager.active end,
    GetCurrentButton = function(self) return self.current end,
    SelectButton = function(self, button) self.current = button end,
    SelectFirstButton = function() end,
    SetScrollFrameForFrame = function(self, owner, scroll) self.scrollOwner, self.scroll = owner, scroll end,
}
SMART_NAV_INPUT_DIRECTION = {LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down"}
function SmartNavigation_AddJumpNavigationOverride(frame, direction, callback)
    frame.overrides = frame.overrides or {}; frame.overrides[direction] = callback
end
pad:InstallTransitions()
assert(manager.active == window and added == 1, "Late-loaded APIs must adopt visible windows")
assert(earlyList.active[1].overrides.down() == earlyList.active[2], "Late APIs adapt existing rows")
pad:InstallTransitions(); pad:RestoreWindows()
assert(added == 1, "Repeated initialization must not re-register windows")
tick(); local before = refreshed
for _ = 1, 100 do pad:Refresh(window) end
tick()
assert(refreshed == before + 1, "Refreshes must coalesce after layout")
tick(); assert(refreshed == before + 1, "Idle windows must do no refresh work")

local popup = CreateFrame("Frame", nil, UIParent)
popup:Hide(); pad:RegisterWindow(popup, true)
popup:Show(); assert(manager.active == popup)
popup:SmartNavigationCloseHandler()
assert(not popup:IsShown() and manager.active == window, "Back returns to the parent window")
local shared = CreateFrame("Frame", nil, UIParent)
shared:Hide()
local owned, cancelled = false, 0
pad:RegisterWindow(shared, true, function() cancelled = cancelled + 1; shared:Hide() end, function() return owned end)
shared:Show(); assert(manager.active == window, "Shared popup is ignored for other addons")
owned = true; pad:RegisterWindow(shared, true)
assert(manager.active == shared, "Reused APR popup must be adopted after styling")
shared:SmartNavigationCloseHandler(); assert(cancelled == 1 and manager.active == window)
owned = false; shared:Show(); shared:SmartNavigationCloseHandler()
assert(cancelled == 1, "Shared popup must not execute APR cancellation for another addon")
shared:Hide()

enabled = false; manager.shown = {}; manager.active = nil; transitions.uninit()
assert(not pad.windows[window].active)
enabled = true; transitions.init(); assert(manager.active == window)
env.setCombat(true)
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
assert(not manager.active and not next(manager.shown), "Combat must release captured gamepad input")
pad:RunAction("skip"); assert(not APR.command.last and APR.message)
pad:RunAction("options"); assert(APR.Workspace.page == "route")
local combatWindow = CreateFrame("Frame", nil, UIParent)
pad:RegisterWindow(combatWindow); assert(not manager.shown[combatWindow])
env.setCombat(false); events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); assert(manager.shown[combatWindow])
combatWindow:Hide()
manager:FocusFrame(window)
APR.ActiveRoute = "route"
pad:RunAction("skip"); assert(APR.command.last == "skip")
pad:RunAction("rollback"); assert(APR.command.last == "rollback")
APR.settings.profile.enableAddon = false
pad:RunAction("skip"); assert(APR.command.last == "rollback")
APR.settings.profile.enableAddon = true

-- Ranges commit through the real OnMouseUp contract and respect their bounds/disabled state.
local widget = {type = "Slider", frame = CreateFrame("Frame", nil, window), step = 0.25}
widget.slider = CreateFrame("Slider", nil, widget.frame)
widget.slider:SetMinMaxValues(0, 1); widget.slider:SetValue(0.5)
local committed, commits
widget.slider:SetScript("OnMouseUp", function(slider) committed = slider:GetValue(); commits = (commits or 0) + 1 end)
pad:AdaptSettings(widget)
assert(widget.slider.overrides.right() == true and committed == 0.75)
widget.slider.overrides.right(); widget.slider.overrides.right(); assert(committed == 1)
widget.slider.overrides.left(); assert(committed == 0.75)
widget.disabled = true; local count = commits
widget.slider.overrides.left(); assert(commits == count)
widget.disabled = false; env.setCombat(true)
widget.slider.overrides.left(); assert(commits == count)
env.setCombat(false)
local dropdown = {type = "Dropdown-Pullout", frame = CreateFrame("Frame", nil, UIParent)}
function dropdown:Close() self.closed = true; self.frame:Hide() end
dropdown.frame:Hide(); pad:AdaptSettings(dropdown); dropdown.frame:Show()
dropdown.frame:SmartNavigationCloseHandler(); assert(dropdown.closed)

-- Thousands of routes remain reachable with bounded row allocation, in both directions.
dofile("APR-Core/ui/foundations/VirtualList.lua")
local scroll = CreateFrame("ScrollFrame", nil, window); scroll:SetSize(300, 90)
local rows = 0
local list = APR.VirtualList:New(scroll, function(parent)
    rows = rows + 1
    local row = CreateFrame("Button", nil, parent)
    row.action = CreateFrame("Button", nil, row)
    return row
end, function(row, item) row.action:SetEnabled(item ~= 50) end, 30)
local items = {}; for index = 1, 1000 do items[index] = index end
list:SetItems(items)
window:SmartNavigationOnSelect(list.active[1].action)
assert(SmartNavigation.scroll == scroll and SmartNavigation.scrollOwner == window,
    "Right stick must scroll the viewport containing the focused action")
window:SmartNavigationOnSelect(window)
assert(SmartNavigation.scroll == nil, "Leaving a list must release its right-stick scroll target")
local row = list.active[1]
for index = 2, 1000 do
    row = row.overrides.down()
    assert(row and row.item == index, "Each down press must select the next route")
end
assert(rows < 10, "Navigation must not instantiate every route")
for index = 999, 1, -1 do row = row.overrides.up(); assert(row.item == index) end
list:ScrollToIndex(49)
local action = list.active[49].action.overrides.down()
assert(action == list.active[51].action, "Keep action column and skip disabled actions")
list:SetItems({8, 7, 6})
row = list.active[1].overrides.down()
assert(row.item == 7, "Rebound rows must navigate the new model")
list:SetItems({}); assert(row.overrides.down() == true)
list:SetSource({count = 1000, get = function(_, index) return index end})
list:ScrollToIndex(998)
row = list.active[998].overrides.down()
assert(row.item == 999)
row = row.overrides.down()
assert(row.item == 1000 and row.overrides.up().item == 999,
    "Indexed media catalogs remain reachable with arithmetic offsets and no dense item array")
assert(#list.offsets == 1 and rows < 10, "Source navigation keeps the same bounded recycled viewport")
list:SetItems({})

-- Reproduce the old failure: the native click handler cannot click a restricted handle.
local first, second = CreateFrame("Button", nil, UIParent), CreateFrame("Button", nil, UIParent)
local ok, failure = pcall(function() handle(first):Click("LeftButton") end)
assert(not ok and failure:find("nil value"), "The fixture must reproduce the reported native/handle mismatch")
first:SetAttribute("type1", "item"); first:SetAttribute("item", "item:100")
second:SetAttribute("type1", "spell"); second:SetAttribute("spell", 200)
-- Register in reverse order, as happens after pooling or deferred combat work.
pad:RegisterActionButton(second, "20-1"); pad:RegisterActionButton(first, "10-1")
pad:RegisterActionButton(first, "10-1")
assert(#pad.actionButtons == 2 and APR_ItemButton == pad.itemProxy)
assert(APR_TargetButton == pad.targetProxy)
local function selectAction(proxy)
    proxy:secureClick()
    assert(not proxy:GetAttribute("clickbutton"), "Never pass a restricted handle to Blizzard's click handler")
    for _, value in pairs(proxy.attributes) do assert(type(value) ~= "table", "Action payloads must be scalar") end
    return proxy:GetAttribute("type")
end
assert(selectAction(pad.itemProxy) == "item" and pad.itemProxy:GetAttribute("item") == "item:100")
first:Hide()
assert(selectAction(pad.itemProxy) == "spell" and pad.itemProxy:GetAttribute("spell") == 200)
assert(not pad.itemProxy:GetAttribute("item"), "Switching actions must clear the previous payload")
second:SetAttribute("type1", nil)
assert(selectAction(pad.itemProxy) == nil and not pad.itemProxy:GetAttribute("spell"), "Empty bindings must be harmless")

-- Targeting never steals the action shortcut, even on a row with both controls.
local target = CreateFrame("Button", nil, UIParent)
target:SetAttribute("type1", "macro"); target:SetAttribute("macrotext", "/targetexact NPC\n/tm 8")
pad:RegisterActionButton(target, "00-1", false, "target")
first:Show()
assert(selectAction(pad.itemProxy) == "item")
assert(selectAction(pad.targetProxy) == "macro" and pad.targetProxy:GetAttribute("macrotext") == "/targetexact NPC\n/tm 8")
target:SetAttribute("macrotext", "/target [@nameplate2,exists]")
selectAction(pad.targetProxy)
assert(pad.targetProxy:GetAttribute("macrotext") == "/target [@nameplate2,exists]", "Target refreshes reach the binding")
first:Hide()
assert(selectAction(pad.itemProxy) == nil, "A target-only step must not repurpose the item shortcut")
target:Hide(); assert(selectAction(pad.targetProxy) == nil and not pad.targetProxy:GetAttribute("macrotext"))

-- Main actions precede fillers; optional rows follow numeric quest/objective order.
local fillerRow = CreateFrame("Frame", nil, UIParent); fillerRow.questID, fillerRow.objectiveIndex = 2, 1
local filler = CreateFrame("Button", nil, fillerRow)
filler:SetAttribute("type1", "toy"); filler:SetAttribute("toy", 300)
pad:RegisterActionButton(filler, "2-1", true)
first:Show(); assert(selectAction(pad.itemProxy) == "item")
first:Hide(); assert(selectAction(pad.itemProxy) == "toy" and pad.itemProxy:GetAttribute("toy") == 300)
local otherRow = CreateFrame("Frame", nil, UIParent); otherRow.questID, otherRow.objectiveIndex = 10, 1
local otherFiller = CreateFrame("Button", nil, otherRow)
otherFiller:SetAttribute("type1", "item"); otherFiller:SetAttribute("item", "item:400")
pad:RegisterActionButton(otherFiller, "10-1", true)
assert(selectAction(pad.itemProxy) == "toy", "Filler 2 must precede filler 10")
fillerRow:Hide()
assert(selectAction(pad.itemProxy) == "item" and not pad.itemProxy:GetAttribute("toy"), "Hidden parent rows are ignored")

-- Secure resolution works in combat without mutating refs/attributes from addon Lua.
env.setCombat(true)
local registered = #pad.actionButtons
pad:RegisterActionButton(CreateFrame("Button")); assert(#pad.actionButtons == registered)
assert(selectAction(pad.itemProxy) == "item" and pad.itemProxy:GetAttribute("item") == "item:400")
assert(selectAction(pad.targetProxy) == nil)
env.setCombat(false)

-- Rebinding a pooled control changes its priority as well as its action payload.
first:Show(); first:SetAttribute("type1", "macro"); first:SetAttribute("item", nil)
first:SetAttribute("macrotext", "/equipslot [nocombat] 16 item:500")
pad:RegisterActionButton(first, "30-1")
second:SetAttribute("type1", "spell"); second:Show()
assert(selectAction(pad.itemProxy) == "spell", "Reused frames must use their new row's order")
second:EnableMouse(false)
assert(selectAction(pad.itemProxy) == "macro" and not pad.itemProxy:GetAttribute("spell"))
first:Hide(); second:Hide(); filler:Hide(); otherFiller:Hide()

-- The proxy retains housing's non-protected departure bookkeeping.
local housing = CreateFrame("Button", nil, UIParent)
housing:SetAttribute("type1", "teleporthome")
housing:SetAttribute("house-neighborhood-guid", "neighborhood")
housing:SetAttribute("house-guid", "house"); housing:SetAttribute("house-plot-id", 7)
pad:RegisterActionButton(housing, "housing")
local departures = 0
APR.navigation = {GetData = function() return {UpdateHousingExitLocation = function() departures = departures + 1 end} end}
assert(selectAction(pad.itemProxy) == "teleporthome" and pad.itemProxy:GetAttribute("house-plot-id") == 7)
pad.itemProxy.scripts.PreClick(pad.itemProxy)
assert(departures == 1)
housing:SetAttribute("type1", "returnhome"); housing:SetAttribute("house-neighborhood-guid", nil)
housing:SetAttribute("house-guid", nil); housing:SetAttribute("house-plot-id", nil)
assert(selectAction(pad.itemProxy) == "returnhome" and not pad.itemProxy:GetAttribute("house-guid"))
housing:Hide(); APR.navigation = nil

-- Native SecureActionButton dispatch must receive both hardware phases so it can
-- honor either ActionButtonUseKeyDown preference.
assert(table.concat(pad.itemProxy.clicks, ",") == "AnyDown,AnyUp")
env.setCombat(false)
print("Gamepad: native lifecycle, modal ownership, deferred refresh, combat, sliders, 1000 recycled routes and secure action routing passed")
return {env = env, pad = pad, manager = manager, window = window, tick = tick, created = created, selectAction = selectAction}
