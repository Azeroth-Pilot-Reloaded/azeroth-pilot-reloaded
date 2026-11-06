-- Execute the shipped restricted snippets through a small API-contract handle.
-- Native taint cannot be reproduced here; ownership and combat cleanup can.
local fixture = dofile("tests/lua/gamepad_test.lua")
local pad, env = fixture.pad, fixture.env
local bindings, drivers, restricted = {}, {}, false
local function execute(frame, attribute, newstate)
    local source = frame:GetAttribute(attribute)
    if not source then return end
    local handle = {
        GetAttribute = function(_, name) return frame:GetAttribute(name) end,
        SetBindingClick = function(_, priority, key, button)
            assert(restricted and priority)
            bindings[frame] = bindings[frame] or {}
            bindings[frame][key] = button
        end,
        ClearBindings = function() assert(restricted); bindings[frame] = {} end,
        Hide = function()
            frame.shown = false
            execute(frame, "_onhide")
        end,
    }
    local chunk = assert(loadstring("return function(self, newstate) " .. source .. " end"))
    setfenv(chunk, {})
    local old = restricted
    restricted = true
    chunk()(handle, newstate)
    restricted = old
end
local show, hide = env.methods.Show, env.methods.Hide
function env.methods:Show()
    local changed = not self.shown
    show(self)
    if changed and drivers[self] then execute(self, "_onshow") end
end
function env.methods:Hide()
    local changed = self.shown
    hide(self)
    if changed and drivers[self] then execute(self, "_onhide") end
end
function RegisterStateDriver(frame, state, condition)
    assert(state == "combat" and condition == "[combat] 1; 0")
    drivers[frame] = true
    frame.secure = true
end
function SetBinding() error("An input overlay must not change saved bindings") end
function SaveBindings() error("An input overlay must not persist bindings") end
dofile("APR-Core/integrations/GamepadInput.lua")
local watcher = fixture.created[#fixture.created]
local owner = CreateFrame("Frame", nil, UIParent)
pad:RegisterWindow(owner)
local changes, releases, editing = 0, 0, false
pad:RegisterInputHandler(owner, {
    buttons = {
        PADLTRIGGER = function(down) if down then changes = changes - 1 end end,
        PADRTRIGGER = function(down) if down then changes = changes + 1 end end,
        PAD1 = function(down) if down then changes = changes + 10 end end,
    },
    wantsKey = function(key) return key ~= "PAD1" or editing end,
    release = function() releases = releases + 1 end,
})
pad:FocusWindow(owner); pad:RefreshInputOwner()
local router = pad.inputHandlers[owner].router
assert(router:IsShown() and bindings[router].PADRTRIGGER and bindings[router].PADLTRIGGER)
assert(not bindings[router].PAD1, "Native Confirm stays available outside placement mode")
local function press(key, down)
    local button = _G[assert(bindings[router][key])]
    button:GetScript("OnClick")(button, "LeftButton", down)
end
press("PADRTRIGGER", true); press("PADRTRIGGER", false)
assert(changes == 1, "A trigger produces one page change per press")
press("PADLTRIGGER", true); assert(changes == 0)
editing = true; pad:RefreshInputOwner()
assert(bindings[router].PAD1)
press("PAD1", true); assert(changes == 10)
local beforeDisconnect = releases
watcher:GetScript("OnEvent")(watcher, "GAME_PAD_DISCONNECTED")
assert(releases == beforeDisconnect + 1, "Unplugging a controller must release held movement immediately")
local popup = CreateFrame("Frame", nil, UIParent)
pad:RegisterWindow(popup, true)
pad:FocusWindow(popup); pad:RefreshInputOwner()
assert(not router:IsShown() and next(bindings[router]) == nil and releases > 0,
    "A popup must release every owner-specific override")
pad:DispatchInput(owner, "PADRTRIGGER", true)
assert(changes == 10, "A stale callback cannot change an unfocused window")
popup:Hide(); pad:FocusWindow(owner); pad:RefreshInputOwner()
assert(router:IsShown())
env.setCombat(true)
execute(router, "_onstate-combat", "1")
assert(not router:IsShown() and next(bindings[router]) == nil,
    "The secure state driver releases overrides during combat without an addon protected call")
pad:RefreshInputOwner(); pad:DispatchInput(owner, "PAD1", true)
assert(changes == 10)
env.setCombat(false)
pad:RefreshInputOwner(); assert(router:IsShown())
owner:Hide()
assert(not router:IsShown() and next(bindings[router]) == nil)
print("Gamepad input: secure scoped overrides, down/up events, modal focus, stale callbacks and combat release passed")
