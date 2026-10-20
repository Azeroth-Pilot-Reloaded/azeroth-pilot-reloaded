APR = {}
dofile("tests/lua/dungeon_data_test_env.lua")
local function dataOnly(value)
    assert(type(value) ~= "function", "Catalogs must contain data only")
    if type(value) == "table" then for k, v in pairs(value) do dataOnly(k); dataOnly(v) end end
end
dataOnly(APR.DungeonData)
dataOnly(APR.DungeonNPCJournal)
for flavor, catalog in pairs(APR.DungeonData) do
    local count, raids = 0, 0
    for key, data in pairs(catalog) do
        count = count + 1
        assert(data.instanceType == "party" or data.instanceType == "raid")
        if data.instanceType == "raid" then raids = raids + 1 end
        if data.status == "announced" then
            assert(not data.instanceID and not next(data.encounters), "Never fabricate unreleased encounter IDs")
        else
            assert(type(data.instanceID) == "number" and data.instanceID > 0, key)
        end
        for encounter, ids in pairs(data.encounters) do
            assert(data.encounterNames[encounter], "Mapped encounter must have source metadata")
            if type(ids) == "number" then ids = { ids } end
            assert(#ids > 0)
            for _, npc in ipairs(ids) do assert(data.bosses[npc], "Encounter credit must belong to the instance") end
        end
        for _, canonical in pairs(data.bossAliases or {}) do assert(data.bosses[canonical]) end
    end
    assert(count >= ({ classic = 35, forever = 44, retail = 200 })[flavor])
    assert(raids >= ({ classic = 7, forever = 7, retail = 60 })[flavor])
end
assert(APR.DungeonData.forever.ROL.encounters[3355] == 250660, "The Baron has a verified ATT association")

function LibStub() return { GetLocale = function() return {} end } end
function CreateFrame() return { RegisterEvent = function() end, SetScript = function() end } end
APR.PlayerID, APR.ActiveRoute = "one", "raid"
APRData = { one = {} }
local inside, kind, instance = true, "raid", 409
function IsInInstance() return inside, kind end
function GetInstanceInfo() return "Molten Core", kind, 0, "", 0, 0, false, instance end
function APR:GetGameVersion() return "classic" end
local step = { Dungeon = "INSTANCE_409", KillNPC = { dungeonKey = "INSTANCE_409", npcID = 11502 } }
function APR:GetCurrentStep() return step end
dofile("APR-Core/utils/DungeonUtils.lua")
assert(APR:IsInsideDungeon("INSTANCE_409"), "Raids are valid instance contexts")
assert(APR:RecordDungeonKill(11502), "A Classic raid boss can grant credit")
kind = "party"
assert(not APR:IsInsideDungeon("INSTANCE_409"), "Raid and dungeon kinds must match")
kind, inside = "raid", false
assert(not APR:RecordDungeonKill(11502))
print("Catalogs: Classic/Forever/Retail instances and raids, data integrity, planned entries and raid context passed")
