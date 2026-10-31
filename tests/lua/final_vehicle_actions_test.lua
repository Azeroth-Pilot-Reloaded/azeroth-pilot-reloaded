-- Synthetic NPC/vehicle state, real event dispatch, instructions and current-step rows.
local env = dofile("tests/lua/route_ui_test_env.lua")
local function noop() end
local L = setmetatable({
    MOUNT_HORSE_SCARE_SPIDER = "Board the test vehicle",
    SCARE_SPIDER_INTO_LUMBERMILL = "Use the test vehicle action",
}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end

local npc, modifier, mounted, inVehicle = 71001, false, true, false
local dismounts, exits, refreshes, advances = 0, 0, 0, 0
local errors = {}
function geterrorhandler() return function(message) errors[#errors + 1] = message end end
function IsModifierKeyDown() return modifier end
function UnitCreatureID(unit) assert(unit == "target"); return npc end
function UnitInVehicle(unit) assert(unit == "player"); return inVehicle end
function Dismount() dismounts = dismounts + 1; mounted = false end
function VehicleExit() exits = exits + 1; inVehicle = false end
C_GossipInfo = { GetAvailableQuests = function() return {} end, GetActiveQuests = function() return {} end }
C_EventUtils = { IsEventValid = function() return true end }
C_Timer = { NewTimer = function(_, callback)
    return { callback = callback, Cancel = function(self) self.cancelled = true end }
end }
function env.methods:RegisterEvent(event)
    self.events = self.events or {}; self.events[event] = true
end
function env.methods:RegisterUnitEvent(event, unit)
    self.units = self.units or {}; self.units[event] = unit
    self:RegisterEvent(event)
end

APR.PlayerID, APR.ActiveRoute = "player", "vehicle-fixture"
APR.settings.profile.enableAddon = true
APRData = { player = { ["vehicle-fixture"] = 1 } }
APR.ActiveQuests = {}
APR.RouteQuestStepList = { ["vehicle-fixture"] = { steps = { {} } } }
APR.DebugEvent, APR.StartPerformanceSample, APR.FinishPerformanceSample = noop, noop, noop
APR.RefreshInstanceUIVisibility, APR.MaybePromptInstanceUIPreference = noop, noop
function APR:IsInstanceWithUI() return true end
APR.gossip = { HandleGossip = function() return false end }
APR.Buff = { RemoveAllBuffIcon = noop }

dofile("APR-Core/utils/SecretUtils.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/TargetUtils.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/features/questing/StepInstructions.lua")
dofile("APR-Core/core/Event.lua")
dofile("APR-Core/features/questing/NPCInteraction.lua")

function APR:GetCurrentStep()
    local route = self.RouteQuestStepList[self.ActiveRoute]
    return route and route.steps[APRData[self.PlayerID][self.ActiveRoute]]
end
function APR:NextQuestStep() advances = advances + 1 end
local function selectStep(step)
    APR.RouteQuestStepList[APR.ActiveRoute].steps = { step }
    APRData.player[APR.ActiveRoute] = 1
end

local current = APR.currentStep
current:PreviousNextStepButton()
local function render(details)
    current:BeginContentUpdate()
    current:Reset()
    APR.stepHandlers.RenderRequirements(APR:GetCurrentStep(), details, 1)
    current:EndContentUpdate(true)
end
function APR:UpdateStep()
    refreshes = refreshes + 1
    render(true)
end
APR.event:RegisterEvents()
local function emit(tag, event, ...)
    local frame = APR.event.framePool[tag]
    assert(frame.events[event], "The event must reach its registered native receiver")
    frame.scripts.OnEvent(frame, event, ...)
    assert(#errors == 0, table.concat(errors, "\n"))
end
local function expectHint(key, expected)
    local count = 0
    for _, row in pairs(current.questsExtraTextList) do
        if row:IsShown() then count = count + 1 end
    end
    assert(count == (key and 1 or 0), "The current vehicle state must expose exactly its applicable hint")
    if key then
        local row = current.questsExtraTextList[key]
        assert(row and row:IsShown() and row.font:GetText() == expected,
            "The real current-step widget must contain the resolved vehicle instruction")
    end
end

-- Gossip opens the real NPCInteraction path into Event:TalkToDenyNpcLogic.
selectStep({ NpcDismount = 71001 })
emit("gossip", "GOSSIP_SHOW")
assert(dismounts == 1 and not mounted, "The declared NPC interaction actually dismounts the player")
mounted, npc = true, 71002
emit("gossip", "GOSSIP_SHOW")
assert(dismounts == 1 and mounted, "Another NPC cannot dismount the player")
npc = nil
emit("gossip", "GOSSIP_SHOW")
assert(dismounts == 1 and mounted, "Unknown target identity cannot satisfy a declared NPC")
npc = 71001
selectStep({ NpcDismount = 71002 })
emit("gossip", "GOSSIP_SHOW")
assert(dismounts == 1 and mounted, "A changed step must use its current NPC policy")
selectStep({ NpcDismount = 71001 })
for _, guard in ipairs({ "modifier", "disabled", "pending", "failed" }) do
    modifier = guard == "modifier"
    APR.settings.profile.enableAddon = guard ~= "disabled"
    APR.routeValidationPending = guard == "pending" and {} or nil
    APR.routeValidationFailed = guard == "failed" and {} or nil
    emit("gossip", "GOSSIP_SHOW")
    assert(dismounts == 1 and mounted, "Blocked NPC automation must preserve the mount: " .. guard)
end
modifier, APR.settings.profile.enableAddon = false, true
APR.routeValidationPending, APR.routeValidationFailed = nil, nil
emit("gossip", "GOSSIP_CLOSED")
assert(dismounts == 1 and mounted, "Closing gossip is not an NPC dismount action")
emit("gossip", "GOSSIP_SHOW")
assert(dismounts == 2 and not mounted, "Removing the guard restores the current NPC action")
mounted = true
selectStep({})
emit("gossip", "GOSSIP_SHOW")
assert(dismounts == 2 and mounted, "An ordinary step has no dismount action")

-- RenderRequirements executes VehicleExit, independent of whether hints are shown.
inVehicle = true
selectStep({ VehicleExit = true })
render(true)
assert(exits == 1 and not inVehicle, "The authored exit executes the native vehicle action")
inVehicle = true
selectStep({ VehicleExit = false })
render(true)
assert(exits == 1 and inVehicle, "Clearing the exit directive leaves the player in the vehicle")
selectStep({})
render(true)
assert(exits == 1 and inVehicle, "An ordinary render cannot exit a vehicle")
selectStep({ VehicleExit = true })
render(false)
assert(exits == 2 and not inVehicle, "Hiding instruction details does not suppress the explicit exit action")

-- Native player entry/exit refreshes the real rendered InVehicle hints.
for _, mode in ipairs({ 1, 2 }) do
    selectStep({ InVehicle = mode })
    inVehicle = false
    render(true)
    expectHint("MOUNT_HORSE_SCARE_SPIDER", "Board the test vehicle")
    local before = refreshes
    inVehicle = true
    emit("vehicle", "UNIT_ENTERED_VEHICLE", "party1")
    assert(refreshes == before, "Another unit's observation cannot refresh the player's instruction")
    expectHint("MOUNT_HORSE_SCARE_SPIDER", "Board the test vehicle")
    emit("vehicle", "UNIT_ENTERED_VEHICLE", "player")
    assert(refreshes == before + 1)
    if mode == 2 then expectHint("SCARE_SPIDER_INTO_LUMBERMILL", "Use the test vehicle action")
    else expectHint(nil) end
    inVehicle = false
    emit("vehicle", "UNIT_EXITED_VEHICLE", "player")
    assert(refreshes == before + 2)
    expectHint("MOUNT_HORSE_SCARE_SPIDER", "Board the test vehicle")
    render(false)
    expectHint(nil)
end
selectStep({})
render(true)
expectHint(nil)
local before = refreshes
emit("vehicle", "UNIT_ENTERED_VEHICLE", "player")
assert(refreshes == before and advances == 0, "Neither a removed hint nor InVehicle alone grants boarding progress")

-- No hard target is a valid native result during an NPC interaction. Neither
-- missing value proves that an ordinary step requested a dismount.
npc, mounted = nil, true
emit("gossip", "GOSSIP_SHOW")
assert(dismounts == 2 and mounted, "Missing NpcDismount and missing target must not match via nil == nil")
print("Vehicle actions: real NPC dismount dispatch, native exit and rendered player-state hints passed")
