-- One navigation input can share viewport measurements, but subsequent inputs
-- must observe moved/scaled frames instead of retaining geometry across calls.
local fixture = dofile("tests/lua/gamepad_test.lua")
local pad, env = fixture.pad, fixture.env
local reads = 0
function env.methods:GetRect()
    reads = reads + 1
    if self.rect then return unpack(self.rect) end
end
local window = CreateFrame("Frame", nil, UIParent)
pad:RegisterWindow(window)
local outer = CreateFrame("ScrollFrame", nil, window)
outer.rect = { 0, 0, 10000, 10000 }
function outer:GetVerticalScrollRange() return 10000 end
local inner = CreateFrame("ScrollFrame", nil, outer)
inner.rect = { 0, 0, 10000, 10000 }
function inner:GetVerticalScrollRange() return 10000 end
local child = CreateFrame("Frame", nil, inner)
local function button(x, y)
    local frame = CreateFrame("Button", nil, child)
    frame.rect = { x, y, 10, 10 }
    return frame
end
local source, candidates = button(5, 9000), {}
for index = 1, 200 do candidates[index] = button(100 + index * 10, 9000) end
pad:BuildNavigation(window)
reads = 0
assert(pad:NavigateControl(source, "RIGHT") == candidates[1])
assert(reads == 207,
    "200 candidates and two shared viewports need 207 rectangle reads, including final focus reveal")

-- Shared clipping changes are visible on the very next input.
inner.rect = { 0, 0, 10000, 500 }
reads = 0
assert(pad:NavigateControl(source, "RIGHT") == true, "Horizontal navigation must reject newly clipped controls")
assert(reads == 202, "A clipped inner viewport is read once; no outer/reveal probes are needed")
inner.rect = { 0, 0, 10000, 10000 }
candidates[1].rect[1] = 5000
assert(pad:NavigateControl(source, "RIGHT") == candidates[2], "Moved candidate rectangles are not cached between inputs")
candidates[1]:Hide()
candidates[2]:SetEnabled(false)
assert(pad:NavigateControl(source, "RIGHT") == candidates[3], "Visibility and enabled-state rules still filter before measurement")

-- Nested clipping still permits vertical movement inside the same viewport;
-- Reveal uses current geometry after selection and adjusts native scrolling.
for _, candidate in ipairs(candidates) do candidate:Hide() end
local lower = button(5, -50)
pad:BuildNavigation(window)
source.rect[2] = 5
assert(pad:NavigateControl(source, "DOWN") == lower)
assert(inner:GetVerticalScroll() == 50 and outer:GetVerticalScroll() == 50,
    "Offscreen vertical navigation reveals through both nested scroll frames")
source.rect[2], lower.rect[2] = 200, 190
lower:SetScale(2)
assert(pad:NavigateControl(source, "UP") == lower, "Independently scaled controls retain screen-space direction")
print("Gamepad geometry: 200 candidates share viewport reads per input; movement, clipping, hidden controls, nested reveal and scale stay live")
