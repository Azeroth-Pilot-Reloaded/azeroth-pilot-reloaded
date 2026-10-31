-- Native equipment confirmation, real route actions/events/rendering/progression.
-- Inventory, item data and combat are client boundaries; no guide data is loaded.
local env = dofile("tests/lua/addon_journey_quest_env.lua")
dofile("APR-Core/features/questing/RouteActions.lua")
local function noop() end
APR.currentStep.UpdateStepButtonCooldowns = noop
APR.currentStep.UpdateStepButtonUsability = noop
APR.RouteQuestStepList = {}
APRCustomPath.player = {}

local equipped, missingItemData, reads, directEquips = {}, {}, {}, 0
local getItemInfo = C_Item.GetItemInfo
function C_Item.GetItemInfo(id)
    if missingItemData[id] then return nil end
    return getItemInfo(id)
end
function GetInventoryItemID(unit, slot)
    assert(unit == "player", "Equipment must be confirmed on the player")
    reads[#reads + 1] = slot
    return equipped[slot]
end
function EquipItemByName()
    directEquips = directEquips + 1
    error("Equipment requires a native hardware action")
end

local serial = 0
local function start(itemID, slot)
    serial = serial + 1
    local route = "equipment-contract-" .. serial
    APR.RouteQuestStepList[route] = { label = "Synthetic equipment", mapID = 10,
        steps = { { EquipItem = { itemID = itemID, slot = slot } }, { Note = "Equipment confirmed" } } }
    APRData.player[route] = 1
    APRCustomPath.player[#APRCustomPath.player + 1] = route
    assert(APR:ActivateRoute(route, "equipment_test"))
    APR:UpdateQuestAndStep()
    H.settle()
    return route
end
local function refresh(slot)
    H.emit("PLAYER_EQUIPMENT_CHANGED", slot, true)
    H.settle()
end
local function progress(route, expected, message)
    assert(APRData.player[route] == expected, message)
end
local function buttonFor(itemID, slot)
    local row = APR.currentStep.questsList["EquipItem-EquipItem"]
    assert(row and row.objectiveText:find("Item " .. itemID, 1, true), "Equipment instruction must name its item")
    local button = row.IconButton
    assert(button and button.itemID == itemID and button.equipSlot == slot, "Current row must bind the requested item and slot")
    assert(button.attributes.type1 == "macro", "Equipment uses a secure hardware action")
    assert(button.attributes.macrotext == "/equipslot [nocombat] " .. slot .. " item:" .. itemID,
        "The secure action must equip the requested item in the requested slot outside combat")
    return button
end

-- Owning the item, another item in the right slot, and the right item in the
-- wrong slot are all insufficient. Only the native target slot completes it.
H.items[9101] = 1
local route = start(9101, 16)
progress(route, 1, "A nil native slot must not complete an equip instruction")
assert(reads[#reads] == 16, "The action must query the authored slot")
buttonFor(9101, 16)
equipped[16], equipped[17] = 9199, 9101
refresh(17)
progress(route, 1, "An item in the wrong slot must not complete the action")
equipped[16] = nil
refresh(16)
progress(route, 1, "A transient nil result must preserve progress")
equipped[16] = 9101
refresh(16)
progress(route, 2, "Delayed native confirmation must complete exactly the current equipment action")
refresh(16)
progress(route, 2, "A repeated equipment event must not skip the following instruction")
assert(not APR.currentStep.questsList["EquipItem-EquipItem"], "A completed equipment action must release its row")

-- Already equipped items complete on activation without requiring a click.
equipped[18] = 9103
local already = start(9103, 18)
progress(already, 2, "Already equipped gear must be recognized on the initial native snapshot")
assert(not APR.currentStep.questsList["EquipItem-EquipItem"], "Already equipped gear must not leave an obsolete action")

-- Item information may arrive after the step: keep a useful numeric instruction
-- and wait for inventory confirmation, then refresh both label and secure icon.
missingItemData[9104] = true
local late = start(9104, 19)
local row = APR.currentStep.questsList["EquipItem-EquipItem"]
assert(row and row.objectiveText:find("9104", 1, true), "Missing item data must retain a useful item identifier")
assert(not row.IconButton, "Missing item data must not bind an invalid secure icon")
progress(late, 1, "Missing names are not equipment confirmation")
missingItemData[9104] = nil
H.emit("GET_ITEM_INFO_RECEIVED", 9104, true)
H.settle()
buttonFor(9104, 19)
progress(late, 1, "Loading item data must not itself advance the route")
equipped[19] = 9104
refresh(19)
progress(late, 2, "Late item data must not prevent subsequent native equipment confirmation")

-- An event queued for an old route must read the new route's requirement.
equipped[16], equipped[17] = nil, nil
local previous = start(9105, 16)
equipped[16] = 9105
H.emit("PLAYER_EQUIPMENT_CHANGED", 16, true)
local replacement = start(9106, 17)
progress(previous, 1, "Switching routes must not apply a queued receipt to the former action")
progress(replacement, 1, "An old route's equipment must not confirm the new item/slot")
buttonFor(9106, 17)
equipped[17] = 9106
refresh(17)
progress(replacement, 2, "The new route must remain completable after cancellation")

-- No secure mutation occurs during combat. A route change must replace pending
-- bindings, and regeneration must expose only the current hardware action.
env.setCombat(true)
local combatOld = start(9107, 16)
local combatCurrent = start(9108, 17)
progress(combatOld, 1, "Combat cannot manufacture equipment confirmation")
progress(combatCurrent, 1, "A nil slot in combat must preserve the new instruction")
equipped[16] = 9107
refresh(16)
progress(combatCurrent, 1, "The former combat instruction must not complete its replacement")
env.setCombat(false)
H.emit("PLAYER_REGEN_ENABLED")
H.settle()
buttonFor(9108, 17)
env.setCombat(true)
equipped[17] = 9108
refresh(17)
progress(combatCurrent, 2, "Observing confirmed equipment remains safe in combat")
env.setCombat(false)
H.emit("PLAYER_REGEN_ENABLED")
H.settle()
progress(combatCurrent, 2, "Leaving combat must not replay a completed equipment action")
assert(not APR.currentStep.questsList["EquipItem-EquipItem"], "Combat recovery must release the former action")
assert(directEquips == 0, "The addon must never equip an item through an unprotected Lua call")
assert(#H.errors == 0, "Equipment lifecycle must not report native/UI errors")
