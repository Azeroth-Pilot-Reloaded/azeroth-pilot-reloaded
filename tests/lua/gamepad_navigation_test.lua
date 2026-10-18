local fixture = dofile("tests/lua/gamepad_test.lua")
local pad, env, manager = fixture.pad, fixture.env, fixture.manager
function env.methods:GetRect() if self.rect then return unpack(self.rect) end end
function env.methods:RegisterForClicks(...) self.clicks = {...} end
local window = CreateFrame("Frame", nil, UIParent)
pad:RegisterWindow(window)
local function control(parent, x, y, w, h)
    local frame = CreateFrame("Button", nil, parent)
    frame.rect = {x, y, w or 100, h or 30}
    return frame
end
-- The diagonal is much closer to Leveling's centre than either wide neighbour.
local speed = control(window, 0, 500, 460, 36)
local leveling = control(window, 476, 500, 460, 36)
local all = control(window, 952, 500, 460, 36)
local diagonal = control(window, 630, 440, 100, 30)
pad:BuildNavigation(window)
assert(leveling.overrides.left() == speed and leveling.overrides.right() == all,
    "Geometric navigation must prefer overlapping rows over closer diagonals")
pad:LinkHorizontal({speed, leveling, all})
assert(leveling.overrides.left() == speed and leveling.overrides.right() == all)
assert(speed.overrides.left() == true and all.overrides.right() == true, "Row ends consume horizontal input")
leveling:SetEnabled(false)
assert(speed.overrides.right() == all, "Disabled controls must be skipped")
leveling:SetEnabled(true)
speed:SetScale(0.8)
speed.rect[2] = 500 / 0.8
assert(leveling.overrides.left() == speed, "Explicit neighbours survive scale changes")
all.rect[2] = 400
assert(leveling.overrides.right() == true, "Wrapped tabs cannot produce horizontal jumps into another row")
all.rect[2] = 500

-- Right-click and directional entry are deferred until the new detail page is laid out.
local tab = control(window, 0, 600)
local body = CreateFrame("Frame", nil, window); body:Hide()
local detail = control(body, 300, 400)
local opens = 0
local function open() opens = opens + 1; body:Show() end
tab:SetScript("OnClick", open)
pad:BindDetails(tab, "DOWN", open, function() return body end)
SmartNavigation:SelectButton(tab)
assert(tab.clicks[2] == "RightButtonUp")
tab:GetScript("OnClick")(tab, "RightButton")
assert(opens == 1 and SmartNavigation:GetCurrentButton() == tab)
fixture.tick()
assert(SmartNavigation:GetCurrentButton() == detail, "Secondary click must enter rebuilt content")
window:SmartNavigationCloseHandler()
assert(window:IsShown() and SmartNavigation:GetCurrentButton() == tab, "Back returns to the category before closing")
assert(tab.overrides.down() == true)
fixture.tick(); assert(SmartNavigation:GetCurrentButton() == detail)

-- A text-only viewport is focusable, but must not replace actual settings as the entry point.
body:Hide()
local scroll = CreateFrame("ScrollFrame", nil, window)
scroll.rect = {0, 100, 200, 200}; scroll:SetHeight(200)
pad:PrepareScroll(scroll)
local controls = pad:CollectControls(scroll)
local child = CreateFrame("Frame", nil, scroll)
local input = control(child, 5, 240, 150, 25)
controls = pad:CollectControls(window)
local hasScroll, hasInput = false, false
for _, value in ipairs(controls) do hasScroll = hasScroll or value == scroll; hasInput = hasInput or value == input end
assert(hasInput and not hasScroll, "A populated viewport must expose its inputs")
input:Hide(); controls = pad:CollectControls(window)
hasScroll = false
for _, value in ipairs(controls) do hasScroll = hasScroll or value == scroll end
assert(hasScroll, "A text report must have an entry point for right-stick scrolling")

-- Scroll targets use screen rectangles even when the child and viewport have different scales.
input:Show(); input.rect = {5, 40, 150, 25}
function scroll:GetVerticalScrollRange() return 500 end
scroll:SetVerticalScroll(0); pad:Reveal(input)
assert(scroll:GetVerticalScroll() == 60)

-- Reusing an adapted control in a foreign window must fall back to native navigation.
manager.active = CreateFrame("Frame", nil, UIParent)
assert(leveling.overrides.right() == nil)
print("Gamepad navigation: spatial rows, boundaries, deferred secondary-click entry, Back and scroll visibility passed")
