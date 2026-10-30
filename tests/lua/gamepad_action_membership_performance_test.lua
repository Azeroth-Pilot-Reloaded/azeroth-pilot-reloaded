-- Stable action bindings should not search the entire retained registry again
-- for every visible button on each guide render. Secure publication stays live.
local fixture = dofile("tests/lua/gamepad_test.lua")
local pad, env = fixture.pad, fixture.env
for _, button in ipairs(pad.actionButtons) do button:Hide() end
local buttons = {}
for index = 1, 200 do
    local button = CreateFrame("Button", nil, UIParent)
    button:SetAttribute("type1", "spell")
    button:SetAttribute("spell", 20000 + index)
    buttons[index] = button
    pad:RegisterActionButton(button, string.format("warm-%03d", index))
end
local count = #pad.actionButtons
assert(fixture.selectAction(pad.itemProxy) == "spell" and pad.itemProxy:GetAttribute("spell") == 20001)

local nativeIPairs, nativeSort = ipairs, table.sort
local setRef, setAttribute = env.methods.SetFrameRef, env.methods.SetAttribute
local visits, sorts, writes = 0, 0, 0
function ipairs(values)
    local iterator, state, initial = nativeIPairs(values)
    if values ~= pad.actionButtons then return iterator, state, initial end
    return function(sequence, previous)
        local key, value = iterator(sequence, previous)
        if key then visits = visits + 1 end
        return key, value
    end, state, initial
end
function table.sort(values, ...)
    if values == pad.actionButtons then sorts = sorts + 1 end
    return nativeSort(values, ...)
end
function env.methods:SetFrameRef(...)
    writes = writes + 1
    return setRef(self, ...)
end
function env.methods:SetAttribute(...)
    writes = writes + 1
    return setAttribute(self, ...)
end
for _ = 1, 100 do
    for index, button in nativeIPairs(buttons) do
        pad:RegisterActionButton(button, string.format("warm-%03d", index))
    end
end
GAMEPAD_MEMBERSHIP_VISITS = visits
assert(visits == 0, "20,000 unchanged bindings cannot repeatedly walk the retained action registry")
assert(sorts == 0 and writes == 0 and #pad.actionButtons == count,
    "Stable bindings do no secure publication, sorting or duplicate insertion")
ipairs, table.sort = nativeIPairs, nativeSort
env.methods.SetFrameRef, env.methods.SetAttribute = setRef, setAttribute

pad:RegisterActionButton(buttons[1], "zz-last")
assert(#pad.actionButtons == count and fixture.selectAction(pad.itemProxy) == "spell"
    and pad.itemProxy:GetAttribute("spell") == 20002, "Recycled controls still publish their changed ordering immediately")
pad:RegisterActionButton(buttons[2], "warm-002", false, "target")
assert(fixture.selectAction(pad.targetProxy) == "spell" and pad.targetProxy:GetAttribute("spell") == 20002)
assert(fixture.selectAction(pad.itemProxy) == "spell" and pad.itemProxy:GetAttribute("spell") == 20003,
    "Changing a retained button's action kind updates both secure proxy selections")

local added = CreateFrame("Button", nil, UIParent)
env.setCombat(true)
pad:RegisterActionButton(added, "combat")
pad:RegisterActionButton(buttons[3], "changed-in-combat")
assert(#pad.actionButtons == count and buttons[3].aprActionKey == "warm-003",
    "Combat registration cannot change membership, priorities or secure bindings")
env.setCombat(false)
added:SetAttribute("type1", "item"); added:SetAttribute("item", "item:90000")
pad:RegisterActionButton(added, "first")
pad:RegisterActionButton(added, "first")
assert(#pad.actionButtons == count + 1 and fixture.selectAction(pad.itemProxy) == "item"
    and pad.itemProxy:GetAttribute("item") == "item:90000", "A rejected combat binding is added exactly once afterward")
print("Gamepad action membership: 20,000 stable calls have zero registry visits or secure writes; rebind/kind/combat behavior preserved")
