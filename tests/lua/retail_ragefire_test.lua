local handler
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
function CreateFrame()
    return { RegisterEvent = function(_, event) assert(event ~= "COMBAT_LOG_EVENT_UNFILTERED") end,
        SetScript = function(_, _, fn) handler = fn end }
end
local inside, instance, version = true, 389, "retail"
function IsInInstance() return inside, "party" end
function GetInstanceInfo() return "Ragefire", "party", 0, "", 0, 0, false, instance end
local step = { Dungeon = "RFC", KillNPC = { dungeonKey = "RFC", npcID = 61408, name = "Adarogg" } }
local advanced, refreshes = 0, 0
APR = { PlayerID = "one", ActiveRoute = "Retail-Test", settings = { profile = { enableAddon = true } } }
APRData = { one = {} }
function APR:GetGameVersion() return version end
function APR:GetCurrentStep() return step end
function APR:UpdateNextStep() advanced = advanced + 1 end
function APR:UpdateStep() refreshes = refreshes + 1 end
dofile("APR-Core/utils/DungeonUtils.lua")
assert(APR:IsInsideDungeon("RFC"))
assert(not APR:GetDungeonDefinition("ROL"), "Retail must not use a Forever-only definition")
assert(not APR:RecordDungeonKill(11517), "Classic NPCs cannot validate Retail RFC")
handler(nil, "ENCOUNTER_END", 1443, "Adarogg", 1, 5, 0)
handler(nil, "ENCOUNTER_END", 123, "Unknown", 1, 5, 1)
for _, journalID in ipairs({ 694, 695, 696, 697 }) do
    handler(nil, "ENCOUNTER_END", journalID, "Journal ID", 1, 5, 1)
end
assert(not APR:GetDungeonRun("Retail-Test", "RFC"))
for encounter, npc in pairs({ [1443] = 61408, [1444] = 61412, [1445] = 61463, [1446] = 61528 }) do
    step.KillNPC.npcID = npc
    handler(nil, "ENCOUNTER_END", encounter, "boss", 1, 5, 1)
    APR:RenderDungeonKill(step, false)
end
assert(advanced == 4, "Retail's encounter IDs validate all four modern bosses")

-- Retail 12.1.5 sends a sixth argument even when it cannot identify a dead unit.
-- This matches the reported Koranthal encounter (1444, success=1, table payload).
APR:ResetDungeonRun("Retail-Test")
step.KillNPC.npcID = 61412
handler(nil, "ENCOUNTER_END", 1444, "Sombre chaman Koranthal", 1, 5, 1, {})
local run = APR:GetDungeonRun("Retail-Test", "RFC")
assert(run and run.kills[61412], "A table payload must not suppress a known successful Retail encounter")
assert(not run.kills[61408], "Koranthal does not grant Adarogg credit")
APR:RenderDungeonKill(step, false)
assert(advanced == 5)

-- Do not inspect secret values/tables to recover the NPC from a unit-status row.
local function forbiddenRead() error("Secret encounter contents must not be read") end
local secret = setmetatable({}, { __index = forbiddenRead, __eq = forbiddenRead })
local lockedTable = setmetatable({}, { __index = forbiddenRead })
function canaccessvalue(value) return not rawequal(value, secret) end
function issecretvalue(value) return rawequal(value, secret) end
function canaccesstable(value) return not rawequal(value, lockedTable) end
for _, payload in ipairs({
    {}, secret, lockedTable, { secret }, { lockedTable },
    { { creatureID = secret, remainingHealthPercent = secret } },
    { { creatureID = 61412, remainingHealthPercent = secret } },
    { { creatureID = secret, remainingHealthPercent = 0 } },
    { { creatureID = 61408, remainingHealthPercent = 100 } },
}) do
    APR:ResetDungeonRun("Retail-Test")
    local before = refreshes
    handler(nil, "ENCOUNTER_END", 1444, "Koranthal", 1, 5, 1, payload)
    run = APR:GetDungeonRun("Retail-Test", "RFC")
    assert(run and run.kills[61412], "Known encounter credit is independent of unit identities")
    assert(not run.kills[61408], "Only the encounter's own boss receives mapped credit")
    assert(refreshes == before + 1, "Each victory refreshes the checkpoint once")
end
APR:ResetDungeonRun("Retail-Test")
assert(not APR:RecordDungeonKill(secret), "Secret NPC IDs must never enter saved credits")
local before = refreshes
handler(nil, "ENCOUNTER_END", 1444, "Koranthal", 1, 5, secret, {})
handler(nil, "ENCOUNTER_END", secret, "Unknown", 1, 5, 1, {})
for _, payload in ipairs({ secret, lockedTable, { secret }, { lockedTable },
    { { creatureID = 61412, remainingHealthPercent = secret } },
    { { creatureID = secret, remainingHealthPercent = 0 } },
}) do
    handler(nil, "ENCOUNTER_END", 123, "Unknown", 1, 5, 1, payload)
end
assert(not APR:GetDungeonRun("Retail-Test", "RFC") and refreshes == before,
    "Unknown encounters require accessible explicit dead-boss data")
handler(nil, "ENCOUNTER_END", 123, "Unknown", 1, 5, 1, {
    secret, { creatureID = 61408, remainingHealthPercent = secret },
    { creatureID = 61412, remainingHealthPercent = 0 },
})
assert(APR:GetDungeonRun("Retail-Test", "RFC").kills[61412], "Public death data still works among inaccessible rows")

instance = 43
APR:ResetDungeonRun("Retail-Test")
handler(nil, "ENCOUNTER_END", 1443, "Adarogg", 1, 5, 1, {})
assert(not APR:GetDungeonRun("Retail-Test", "RFC"))
instance, version, APR.ActiveRoute = 389, "forever", "Forever-Test"
step.KillNPC.npcID = 11517
handler(nil, "ENCOUNTER_END", 1443, "Adarogg", 1, 5, 1, {})
assert(not APR:GetDungeonRun("Forever-Test", "RFC"), "Retail encounter mappings cannot grant Forever credit")
assert(not APR:RecordDungeonKill(61408))
handler(nil, "ENCOUNTER_END", 1, "Oggleflint", 1, 5, 1,
    { { creatureID = 11517, remainingHealthPercent = 0 } })
assert(APR:GetDungeonRun("Forever-Test", "RFC").kills[11517])
print("Ragefire: Retail/Forever boss isolation, public encounters and wrong-instance checks passed")
