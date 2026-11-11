local env = dofile("tests/lua/route_ui_test_env.lua")
local methods, created = env.methods, {}
local create = CreateFrame
function CreateFrame(...)
    local frame = create(...)
    created[#created + 1] = frame
    return frame
end
function methods:RegisterEvent(event)
    self.events = self.events or {}
    self.events[event] = true
end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:SetResizeBounds(...)
    assert(not InCombatLockdown(), "Resize bounds cannot be changed in combat")
    self.resizeBounds = { ... }
    self.boundsWrites = (self.boundsWrites or 0) + 1
end
function hooksecurefunc(object, key, callback)
    local original = object[key]
    object[key] = function(...)
        original(...)
        callback(...)
    end
end
UIParent:SetSize(1600, 900)
UIParent:SetScale(0.5)
local parent = CreateFrame("Frame", nil, UIParent)
local frame = CreateFrame("Frame", nil, parent)
frame:SetScale(1.5)
frame:SetSize(2000, 1500)
APR:SetScreenResizeBounds(frame, 400, 200)
local watcher = created[#created]
assert(math.abs(frame.resizeBounds[3] - 1600 / 1.5) < 0.001 and frame.resizeBounds[4] == 600)
assert(frame:GetWidth() == frame.resizeBounds[3] and frame:GetHeight() == 600,
    "Previously oversized frames also fit the screen")
APR:SetScreenResizeBounds(frame, 400, 200, 640, 480)
assert(frame.resizeBounds[3] == 640 and frame.resizeBounds[4] == 480, "Stricter bounds stay intact")
APR:SetScreenResizeBounds(frame, 2000, 1000)
assert(frame.resizeBounds[1] == frame.resizeBounds[3] and frame.resizeBounds[2] == 600,
    "Small screens cannot have a minimum larger than the maximum")
UIParent:SetSize(1000, 600)
watcher.scripts.OnEvent(watcher, "DISPLAY_SIZE_CHANGED")
assert(frame.resizeBounds[4] == 400 and frame:GetHeight() == 400)
parent:SetScale(2)
assert(math.abs(frame.resizeBounds[3] - 1000 / 3) < 0.001 and frame.resizeBounds[4] == 200,
    "Inherited addon scale changes update bounds without changing the physical screen")
frame:SetScale(1)
assert(frame.resizeBounds[3] == 500 and frame.resizeBounds[4] == 300)
UIParent:SetSize(0, 0)
watcher.scripts.OnEvent(watcher, "UI_SCALE_CHANGED")
assert(frame.resizeBounds[3] == 500, "Unavailable display geometry retains valid bounds")
UIParent:SetSize(800, 500)
env.setCombat(true)
local writes = frame.boundsWrites
watcher.scripts.OnEvent(watcher, "DISPLAY_SIZE_CHANGED")
assert(frame.boundsWrites == writes and watcher.events.PLAYER_REGEN_ENABLED, "Combat defers geometry changes")
env.setCombat(false)
watcher.scripts.OnEvent(watcher, "PLAYER_REGEN_ENABLED")
assert(frame.resizeBounds[3] == 400 and frame.resizeBounds[4] == 250 and not watcher.events.PLAYER_REGEN_ENABLED)
UIParent:SetSize(1200, 800)
frame.scripts.OnShow(frame)
assert(frame.resizeBounds[3] == 600 and frame.resizeBounds[4] == 400, "Opening refreshes current screen bounds")

-- Native size notifications occur for both mouse sizing and SetSize/SetHeight.
-- Bounds can notify synchronously, so the recovery must also resist reentrancy.
local setSize, setHeight, setWidth = methods.SetSize, methods.SetHeight, methods.SetWidth
local function sizeChanged(target)
    if target.scripts.OnSizeChanged then target.scripts.OnSizeChanged(target, target:GetWidth(), target:GetHeight()) end
end
function methods:SetSize(...) setSize(self, ...); sizeChanged(self) end
function methods:SetHeight(...) setHeight(self, ...); sizeChanged(self) end
function methods:SetWidth(...) setWidth(self, ...); sizeChanged(self) end
local setBounds = methods.SetResizeBounds
function methods:SetResizeBounds(...)
    setBounds(self, ...)
    sizeChanged(self)
end
function methods:GetClampRectInsets() return unpack(self.clampInsets or { 0, 0, 0, 0 }) end
function methods:GetLeft() return self.left end
function methods:GetTop() return self.top end
UIParent:SetSize(1600, 900)
local window = CreateFrame("Frame", nil, UIParent)
window:SetScale(1.25)
window.clampInsets = { -24, 0, 26, 0 }
window.left, window.top = -80, 1600
window:SetSize(1900, 2000)
APR:SetScreenResizeBounds(window, 400, 200)
assert(window:GetWidth() == 1256 and window:GetHeight() == 694,
    "The complete window, including external logo and tabs, must fit the screen")
assert(window.point[1] == "TOPLEFT" and window.point[4] == 24 and window.point[5] == -26,
    "Opening a saved oversized/off-screen window recovers its header and resize handle")
window:SetHeight(3000)
assert(window:GetHeight() == 694, "A height change cannot escape the ceiling after initialization")
window:SetSize(3000, 3000)
assert(window:GetWidth() == 1256 and window:GetHeight() == 694, "Both dimensions are enforced during native sizing")
window:SetWidth(3000)
assert(window:GetWidth() == 1256)
window.left, window.top = 300, 400
window:StopMovingOrSizing()
assert(window.point[4] == 24 and window.point[5] == -26,
    "Releasing a resize or move recovers an off-screen lower edge")
print("Screen resize bounds: scale, stricter limits, small displays, restored geometry and combat deferral passed")
