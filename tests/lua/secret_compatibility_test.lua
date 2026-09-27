-- Lua 5.1 cannot create WoW secrets. Opaque sentinels catch accidental indexing,
-- GUID parsing and propagation; the client's actual taint rules still need live QA.
local function noop() end
local function forbidden() error("Restricted data must not be inspected") end
local secret = setmetatable({}, { __index = forbidden, __tostring = forbidden })
local restrictedTable = setmetatable({}, { __index = forbidden })
function canaccessvalue(value) return not rawequal(value, secret) end

function canaccesstable(value) return not rawequal(value, restrictedTable) end

dofile("APR-Core/utils/SecretUtils.lua")
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return setmetatable({ GetLocale = function() return L end }, { __index = function() return noop end }) end

APR = { RegisterFontString = noop, Color = { defaultBackdrop = {}, white = { 1, 1, 1 }, midGray = { .5, .5, .5 } } }
function APR:NewModule() return {} end

APRSecret:Attach(APR)
local guid, creatureID = "Creature-0-0-0-0-185-0", 185
local calls = 0
function UnitGUID() return guid end

function strsplit(_, value)
    assert(canaccessvalue(value))
    return unpack({ value:match("([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)") })
end

C_CreatureInfo = {
    GetCreatureID = function(value)
        assert(canaccessvalue(value)); calls = calls + 1; return creatureID
    end
}
UnitCreatureID = forbidden
dofile("APR-Core/utils/TargetUtils.lua")
assert(APR:GetTargetID() == 185 and calls == 1, "Prefer C_CreatureInfo over the legacy unit API")
guid = secret
assert(APR:GetTargetID() == nil and calls == 1, "Secret GUIDs must not enter the creature API")
guid, creatureID = "Creature-0-0-0-0-185-0", secret
assert(APR:GetTargetID() == nil)
C_CreatureInfo = nil
UnitCreatureID = function() return secret end
assert(APR:GetTargetID() == nil)
UnitCreatureID = function() return 186 end
assert(APR:GetTargetID() == 186)
UnitCreatureID = nil
assert(APR:GetTargetID() == 185)
guid = "Player-0-0-0-0-185-0"
assert(APR:GetTargetID() == nil, "Do not interpret player GUIDs as NPC IDs")

dofile("APR-Core/features/questing/RouteActions.lua")
APR.routeTrainerOpen = true
GetNumTrainerServices = forbidden
guid = secret
APR:HandleSkillTrainer({ LearnSkill = { npcID = 185 } })
APR:HandleTameBeast({ TameBeast = {} }, "UNIT_SPELLCAST_START", secret, 1515)
APR:HandleTameBeast({ TameBeast = {} }, "UNIT_SPELLCAST_SUCCEEDED", "player", secret)
APR:HandleSpellETA({ SpellETA = { spellID = 1515 } }, secret, 1515)
APR:HandleSpellETA({ SpellETA = { spellID = 1515 } }, "player", secret)
assert(APR.routeActionState == nil, "Restricted casts cannot complete steps or start timers")

-- Minimal stateful frames for Buff's fallback when AuraContainer is unavailable.
local methods = {}
local function object()
    return setmetatable({}, { __index = function(_, key) return methods[key] or noop end })
end
function methods:CreateTexture() return object() end

function methods:SetVertexColor(red) self.red = red end

function CreateFrame(_, name, _, template)
    local frame = object()
    if template == "ObjectiveTrackerContainerHeaderTemplate" then
        frame.Text, frame.MinimizeButton = object(), object()
    end
    if name then _G[name] = frame end
    return frame
end

GameTooltip = object()
C_Spell = { GetSpellInfo = function() return { iconID = 123 } end }
local aura, queries = nil, 0
C_UnitAuras = {
    GetPlayerAuraBySpellID = function()
        queries = queries + 1; return aura
    end
}
dofile("APR-Core/features/player/Buff.lua")
APR.Buff.RefreshFrameAnchor = noop
aura = { spellId = 123, auraInstanceID = 42, icon = 123 }
APR.Buff:AddBuffIcon({ spellId = 123, tooltipMessage = "buff" })
local icon = APR.Buff.auras[1]
assert(icon.auraId == 42 and icon.texture.red == 1)
local before = queries
APR.Buff:HandleUnitAuraUpdate("target", restrictedTable)
assert(queries == before)
aura = nil
APR.Buff:HandleUnitAuraUpdate(secret, restrictedTable)
assert(queries == before + 1 and icon.auraId == 0 and icon.texture.red == .5)
for _, value in ipairs({ secret, restrictedTable, { auraInstanceID = secret, icon = secret } }) do
    aura = value
    APR.Buff:HandleUnitAuraUpdate("player", restrictedTable)
    assert(icon.auraId == 0)
end
aura = { auraInstanceID = 43 }
APR.Buff:HandleUnitAuraUpdate("player", restrictedTable)
assert(icon.auraId == 43 and icon.texture.red == 1, "Public aura data recovers after restrictions")

dofile("APR-Core/utils/PlayerUtils.lua")
aura = secret
assert(not APR:HasAura(123))
aura = {}
assert(APR:HasAura(123))

-- Events must guard values before comparison or use as table keys.
local refreshed, cooldowns, usability = 0, 0, 0
function APR:RefreshLevelProfileTargets() refreshed = refreshed + 1 end

function APR:StepUsesAnyOption() return false end

APR.currentStep = {
    UpdateStepButtonCooldowns = function(_, filter)
        assert(filter == nil); cooldowns = cooldowns + 1
    end,
    UpdateStepButtonUsability = function(_, filter)
        assert(filter == nil); usability = usability + 1
    end,
}
dofile("APR-Core/core/Event.lua")
APR.event.functions.buffs("UNIT_AURA", secret, restrictedTable)
assert(refreshed == 1)
APR.event.functions.spell("UNIT_SPELLCAST_SUCCEEDED", secret, secret, secret)
APR.event.functions.cooldowns("SPELL_UPDATE_COOLDOWN", secret, secret, secret, secret, secret)
assert(cooldowns == 1 and usability == 1)
print("Secrets: NPC APIs, route actions, opaque aura payloads, public recovery and event guards passed")
