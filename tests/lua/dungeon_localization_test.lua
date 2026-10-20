local locale, version, handler = "frFR", "retail"
function GetLocale() return locale end
function LibStub() return { GetLocale = function() return {} end } end
function CreateFrame() return { RegisterEvent = function() end, SetScript = function(_, _, fn) handler = fn end } end
function IsInInstance() return true, "party" end
function GetInstanceInfo() return "Ragefeu", "party", 0, "", 0, 0, false, 389 end
function GetRealZoneText() return "Durotar" end
function EJ_GetInstanceInfo(id) assert(id == 226); return "Gouffre de Ragefeu" end
BOSS, ENTER_DUNGEON, LEAVE_ZONE, UNKNOWN = "Boss", "Entrer", "Quitter %s", "Inconnu"
APR = { PlayerID = "one", ActiveRoute = "test", settings = { profile = { enableAddon = true } } }
APRData = { one = {} }
local step = { Dungeon = "RFC", KillNPC = { dungeonKey = "RFC", npcID = 61412, name = "Dark Shaman Koranthal" } }
function APR:GetGameVersion() return version end
function APR:GetCurrentStep() return step end
local refreshes = 0
function APR:UpdateStep() refreshes = refreshes + 1 end
dofile("APR-Core/utils/SecretUtils.lua")
dofile("APR-Core/utils/TargetUtils.lua")
dofile("tests/lua/dungeon_data_test_env.lua")
dofile("APR-Core/utils/DungeonUtils.lua")
local journalName = "Sombre chaman Koranthal"
function EJ_GetCreatureInfo(index, encounter)
    assert(index == 1 and encounter == 695)
    return 123, journalName
end
assert(APR:GetDungeonKillText(step.KillNPC) == "Boss: Sombre chaman Koranthal")
assert(APR:BuildRaidIconMacro(61412):find("/targetexact Sombre chaman Koranthal", 1, true))
assert(APR:GetDungeonTravelText({ EnterInstance = { dungeonKey = "RFC" } }) == "Entrer: Gouffre de Ragefeu")

locale, journalName = "deDE", "Dunkelschamane Koranthal"
assert(APR:GetDungeonKillText(step.KillNPC) == "Boss: Dunkelschamane Koranthal", "A locale change drops stale names")

-- Forever without the adventure journal learns public localized encounter names.
version, locale, EJ_GetCreatureInfo = "forever", "frFR", nil
EJ_GetInstanceInfo = nil
C_Map = { GetAreaInfo = function(areaID) assert(areaID == APR.DungeonData.forever.RFC.areaID); return "Gouffre de Ragefeu" end }
assert(APR:GetDungeonTravelText({ EnterInstance = { dungeonKey = "RFC" } }) == "Entrer: Gouffre de Ragefeu",
    "Travel uses the destination area rather than the player's current zone")
step.KillNPC.npcID, step.KillNPC.name = 11520, "Taragaman the Hungerer"
handler(nil, "ENCOUNTER_START", 2733, "Taragaman l'Affameur", 1, 5)
assert(refreshes == 1 and APR:GetDungeonKillText(step.KillNPC) == "Boss: Taragaman l'Affameur")
assert(not APR:GetDungeonRun("test", "RFC"), "A localized name must never grant a kill")
handler(nil, "ENCOUNTER_END", 2733, "Taragaman l'Affameur", 1, 5, 1, {})
assert(APR:GetDungeonRun("test", "RFC").kills[11520] and refreshes == 2)

-- A display name must not become the NPC's macro name when the event names differ.
function GetInstanceInfo() return "Ruines", "party", 0, "", 0, 0, false, 2999 end
step = { Dungeon = "ROL", KillNPC = { dungeonKey = "ROL", npcID = 250660, name = "The Baron" } }
handler(nil, "ENCOUNTER_START", 3355, "Le Boucher", 1, 5)
assert(not APRData.NPCList[250660], "Encounter titles must not impersonate different NPC names")
handler(nil, "ENCOUNTER_END", 3355, "Le Boucher", 1, 5, 1,
    { { creatureID = 250660, creatureName = "Le Baron", remainingHealthPercent = 0 } })
assert(APR:GetDungeonKillText(step.KillNPC) == "Boss: Le Baron")

local secret = setmetatable({}, { __index = function() error("Secret name was read") end })
function canaccessvalue(value) return not rawequal(value, secret) end
assert(not APR:RememberNPCName(250660, secret))
assert(APRData.NPCList[250660] == "Le Baron")

-- Public unit-name discovery refreshes both the active label and secure action.
local queued, macros = 0, 0
APR.event = { QueueStepRefresh = function() queued = queued + 1 end }
APR.currentStep = { UpdateRaidIconButtonMacro = function() macros = macros + 1 end }
function APR:Debug() end
function UnitExists() return true end
function UnitIsPlayer() return false end
function UnitCanAttack() return true end
function UnitCreatureID() return 250660 end
function UnitName() return "Le Baron corrigé" end
APR:ScanUnitForNPC("target", "TARGET")
assert(queued == 1 and macros == 1 and APR:GetDungeonKillText(step.KillNPC) == "Boss: Le Baron corrigé")
APR:ScanUnitForNPC("target", "TARGET")
assert(queued == 1 and macros == 1, "Unchanged names do not rebuild the guide")
print("Dungeon names: journal, encounter discovery, public unit names, locale changes and secret guards passed")
