local function forbidden() error("Do not read protected combat logs or unit health") end
CombatLogGetCurrentEventInfo, UnitHealth, UnitHealthMax = forbidden, forbidden, forbidden
local secret = {}
function canaccessvalue(value) return not rawequal(value, secret) end
dofile("APR-Core/utils/SecretUtils.lua")
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
local handler, registered = nil, {}
function CreateFrame()
    return {
        RegisterEvent = function(_, name)
            assert(name ~= "COMBAT_LOG_EVENT_UNFILTERED")
            registered[name] = true
        end,
        SetScript = function(_, name, fn) assert(name == "OnEvent"); handler = fn end,
    }
end
local inside, map = false, 1411
local npc, guid, dead, denied, attackable = 3100, "boar-1", false, false, true
function IsInInstance() return inside end
C_Map = { GetBestMapForUnit = function() return map end }
function UnitGUID() return guid end
function UnitCreatureID() return npc end
function UnitIsDead() return dead end
function UnitIsTapDenied() return denied end
function UnitCanAttack() return attackable end
local step = { KillNPC = { npcID = 3100, name = "Boar" }, Zone = 1411 }
local advanced, refreshed = 0, 0
APR = { PlayerID = "one", ActiveRoute = "test", currentStep = {},
    settings = { profile = { enableAddon = true } } }
APRData = { one = { test = 1 }, two = { test = 1 } }
function APR:GetCurrentStep() return step end
function APR:GetRouteActionState()
    local token = self.PlayerID .. ":" .. self.ActiveRoute .. ":" .. APRData[self.PlayerID][self.ActiveRoute]
    if not self.routeActionState or self.routeActionState.token ~= token then self.routeActionState = { token = token } end
    return self.routeActionState
end
function APR:GetDungeonKillText(rule) return rule.name end
function APR:UpdateStep() refreshed = refreshed + 1 end
function APR:UpdateNextStep() advanced = advanced + 1 end
function APR.currentStep:AddQuestSteps() end
dofile("APR-Core/utils/OutdoorKillUtils.lua")
assert(registered.UNIT_HEALTH and registered.UNIT_FLAGS and registered.PLAYER_TARGET_CHANGED)
local function reset()
    APR:ResetOutdoorKills("test")
    APR.routeActionState = nil
    inside, map, npc, guid, dead, denied, attackable = false, 1411, 3100, "boar-1", false, false, true
end

-- Corpse first, then another creature's corpse: neither proves this kill.
dead = true
handler(nil, "PLAYER_TARGET_CHANGED")
assert(not APR:IsOutdoorKillComplete(step))
dead = false
handler(nil, "PLAYER_TARGET_CHANGED")
guid, dead = "boar-2", true
handler(nil, "UNIT_HEALTH", "target")
assert(not APR:IsOutdoorKillComplete(step))
guid = "boar-1"
handler(nil, "UNIT_FLAGS", "target")
assert(APR:IsOutdoorKillComplete(step) and refreshed == 1)
handler(nil, "UNIT_HEALTH", "target")
assert(refreshed == 1, "Repeated events must not duplicate credit/refresh")
APR:RenderOutdoorKill(step, true)
assert(advanced == 1)
APR.routeActionState = nil -- reload/refresh loses transient sightings, keeps confirmed credit
assert(APR:IsOutdoorKillComplete(step))
APR.PlayerID = "two"
assert(not APR:IsOutdoorKillComplete(step))
APR.PlayerID, APR.ActiveRoute = "one", "another"
assert(not APR:IsOutdoorKillComplete(step))
APR.ActiveRoute = "test"

-- Disabled, wrong NPC/map/instance, friendly or other player's tag never credit.
for _, invalid in ipairs({ "disabled", "npc", "map", "instance", "friendly", "tagged" }) do
    reset()
    if invalid == "disabled" then APR.settings.profile.enableAddon = false end
    if invalid == "npc" then npc = 42 end
    if invalid == "map" then map = 1 end
    if invalid == "instance" then inside = true end
    if invalid == "friendly" then attackable = false end
    if invalid == "tagged" then denied = true end
    handler(nil, "PLAYER_TARGET_CHANGED")
    dead = true
    handler(nil, "UNIT_HEALTH", "target")
    assert(not APR:IsOutdoorKillComplete(step), invalid)
    APR.settings.profile.enableAddon = true
end

-- Losing a tap or crossing zones invalidates sightings, even on returning.
reset(); handler(nil, "PLAYER_TARGET_CHANGED")
denied = true; handler(nil, "UNIT_FACTION", "target")
denied, dead = false, true; handler(nil, "UNIT_HEALTH", "target")
assert(not APR:IsOutdoorKillComplete(step))
reset(); handler(nil, "PLAYER_TARGET_CHANGED")
map = 1; handler(nil, "ZONE_CHANGED_NEW_AREA")
map, dead = 1411, true; handler(nil, "UNIT_HEALTH", "target")
assert(not APR:IsOutdoorKillComplete(step))

-- Secret tokens/identity/death/tag/map/attackability never enter branches or keys.
for _, kind in ipairs({ "unit", "guid", "npc", "dead", "denied", "map", "attackable" }) do
    reset()
    if kind == "guid" then guid = secret end
    if kind == "npc" then npc = secret end
    if kind == "dead" then dead = secret end
    if kind == "denied" then denied = secret end
    if kind == "map" then map = secret end
    if kind == "attackable" then attackable = secret end
    handler(nil, "UNIT_HEALTH", kind == "unit" and secret or "target")
    dead = true
    handler(nil, "UNIT_FLAGS", "target")
    assert(not APR:IsOutdoorKillComplete(step), kind)
end

-- Unit events can follow nameplates across target changes without health polling.
reset(); handler(nil, "NAME_PLATE_UNIT_ADDED", "nameplate1")
dead = true; handler(nil, "UNIT_HEALTH", "nameplate1")
assert(APR:IsOutdoorKillComplete(step))

-- Route resets at step one still clear saved outdoor credit.
dofile("APR-Core/features/questing/StepTransitions.lua")
APR:SetRouteProgress("test", 1, "reset")
assert(not APR:IsOutdoorKillComplete(step))
reset()
local deadAPI = UnitIsDead
UnitIsDead = nil
APR:RenderOutdoorKill(step, true)
assert(not APR:IsOutdoorKillComplete(step), "Unavailable public APIs leave manual fallback")
UnitIsDead = deadAPI
print("Outdoor KillNPC: death transitions, zone, GUID, secrets, character/route isolation and reset passed")
