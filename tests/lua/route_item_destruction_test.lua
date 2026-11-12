-- Protected deletion runs only inside native input, with live route/bag checks.
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
local steps = { { DestroyItems = { items = { 701 } } }, { Note = "Continue" } }
APR = { PlayerID = "player", ActiveRoute = "synthetic",
    RouteQuestStepList = { synthetic = { steps = steps } },
    settings = { profile = { enableAddon = true } } }
APRData = { player = { synthetic = 1 } }
function APR:GetStep(index) return steps[index] end
function APR:HasAnyMainStepOption() return false end
function APR:AreConditionalFiltersMet() return self.eligible ~= false end
function APR:HasPendingStartupQuestConditions() return self.pendingCondition == true end
function APR:GetCurrentStepToken(route, index) return route .. ":" .. index end
function APR:NextQuestStep() self:SetRouteProgress(self.ActiveRoute, 2) end

local frames, hooks, hardware = {}, {}, false
UIParent = {}
WorldFrame = { HookScript = function(_, event, callback)
    assert(not hooks[event], "Install the world hook only once")
    hooks[event] = callback
end }
function CreateFrame()
    local frame = { scripts = {} }
    function frame:Hide() self.shown = false end
    function frame:Show() self.shown = true end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    function frame:EnableKeyboard(value) self.keyboardEnabled = value end
    function frame:SetAllPoints(parent) self.anchor = parent end
    function frame:SetPropagateKeyboardInput(value) assert(value); self.propagates = value end
    frames[#frames + 1] = frame
    return frame
end
local bags, cursor, combat, dead, clock, deletions, pickups, wrongPickup
NUM_BAG_SLOTS = 0
function GetTime() return clock end
function InCombatLockdown() return combat end
function UnitIsDeadOrGhost() return dead end
function CursorHasItem() return cursor and cursor.kind == "item" end
function GetCursorInfo() return cursor and cursor.kind, cursor and cursor.itemID end
function ClearCursor()
    -- Simulate returning the picked-up item to its source slot.
    if cursor then bags[cursor.slot] = cursor.item end
    cursor = nil
end
C_Container = {
    GetContainerNumSlots = function() return 3 end,
    GetContainerItemInfo = function(_, slot) return bags[slot] end,
    PickupContainerItem = function(_, slot)
        assert(hardware and not cursor and not combat)
        pickups = pickups + 1
        cursor = { kind = "item", itemID = wrongPickup and 999 or bags[slot].itemID,
            slot = slot, item = bags[slot] }
        bags[slot] = nil
    end,
}
function DeleteCursorItem()
    assert(hardware and cursor and cursor.itemID == 701 and not combat)
    deletions = deletions + 1
    cursor = nil
end
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/features/questing/RouteActions.lua")

local function reset()
    APR:CancelRouteItemDestruction()
    APRData.player.synthetic, APR.routeActionState = 1, nil
    APR.routeValidationPending, APR.routeValidationFailed, APR.startupQuestStatePending = nil, nil, nil
    APR.eligible, APR.pendingCondition, APR.settings.profile.enableAddon = true, false, true
    bags = { { itemID = 701, stackCount = 2 }, { itemID = 701, stackCount = 3 },
        { itemID = 702, stackCount = 1 } }
    cursor, combat, dead, clock, deletions, pickups, wrongPickup = nil, false, false, 10, 0, 0, false
end
local function render() assert(APR:HandleRouteAction(steps[APRData.player.synthetic])) end
local function input(world)
    hardware = true
    if world then hooks.OnMouseDown()
    elseif APR.routeItemDestructionFrame.shown and APR.routeItemDestructionFrame.keyboardEnabled then
        APR.routeItemDestructionFrame.scripts.OnKeyDown()
    end
    hardware = false
end

reset()
render(); render()
assert(deletions == 0 and pickups == 0 and frames[1].propagates)
assert(frames[1].anchor == UIParent, "The keyboard listener needs screen bounds")
input()
assert(deletions == 1 and bags[1] == nil and bags[2].stackCount == 3 and bags[3].itemID == 702)
assert(APRData.player.synthetic == 1, "Deletion alone must not advance the route")
render()
assert(deletions == 1, "Bag refresh cannot delete the next stack")
input(true)
assert(deletions == 2 and bags[2] == nil and bags[3].itemID == 702)
render()
assert(APRData.player.synthetic == 2 and not frames[1].shown and not APR.routeItemDestruction)
input(true)
assert(deletions == 2 and #frames == 1)
input()
assert(deletions == 2, "A hidden listener must not receive keyboard input")

for _, kind in ipairs({ "item", "spell" }) do
    reset(); render()
    cursor = { kind = kind, itemID = 900 }
    input()
    assert(pickups == 0 and deletions == 0 and cursor.itemID == 900)
    cursor = nil
    input()
    assert(deletions == 1, "Unrelated cursor postpones, rather than cancels, deletion")
end
reset(); render(); combat = true; input()
assert(pickups == 0 and deletions == 0)
combat = false; dead = true; input(); assert(deletions == 0)
dead = false; bags[1].isLocked = true; input(); assert(pickups == 0)
bags[1].isLocked = false; input(); assert(deletions == 1)

-- A changed slot must never delete its replacement; find the currently listed item instead.
reset(); render()
bags[1] = { itemID = 703, stackCount = 1 }
input()
assert(deletions == 1 and bags[1].itemID == 703 and bags[2] == nil)
reset(); render(); wrongPickup = true; input()
assert(deletions == 0 and cursor == nil and bags[1].itemID == 701)
wrongPickup = false; input(); assert(deletions == 1)

for _, flag in ipairs({ "routeValidationPending", "routeValidationFailed", "startupQuestStatePending",
    "pendingCondition" }) do
    reset(); render(); APR[flag] = true; input()
    assert(pickups == 0 and not APR.routeItemDestruction and not frames[1].shown, flag)
end
reset(); render(); APR.eligible = false; input()
assert(pickups == 0 and not frames[1].shown)
reset(); render(); APR.settings.profile.enableAddon = false; input()
assert(pickups == 0 and not frames[1].shown)
reset(); render(); APR.routeActionState = {}; input()
assert(pickups == 0 and not frames[1].shown)
reset(); render(); APR.stepRevision = (APR.stepRevision or 0) + 1; input()
assert(pickups == 0 and not frames[1].shown)
reset(); render(); APR:SetRouteProgress("synthetic", 2, "manual_skip")
assert(not APR.routeItemDestruction and not frames[1].shown)
input(true); assert(deletions == 0)
reset(); render(); APR:ActivateRoute(nil)
assert(not APR.routeItemDestruction and not frames[1].shown)
input(true); assert(deletions == 0)
APR.ActiveRoute = "synthetic"

-- Legacy container APIs share the same hardware gate and inventory revalidation.
local modern = C_Container
C_Container = nil
GetContainerNumSlots = modern.GetContainerNumSlots
PickupContainerItem = modern.PickupContainerItem
function GetContainerItemInfo(bag, slot)
    local info = modern.GetContainerItemInfo(bag, slot)
    if info then return nil, info.stackCount, info.isLocked, nil, nil, nil, nil, nil, nil, info.itemID end
end
reset(); render(); assert(deletions == 0); input(true); assert(deletions == 1)
print("Route destruction: hardware-only stacks, propagation, live bags, guards, cancellation and legacy API passed")
