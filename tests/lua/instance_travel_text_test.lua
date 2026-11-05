-- Synthetic destinations exercise every instance-entry label without loading
-- maintained guides, dungeon catalogues or a duplicate of packaged locales.
local noop = function() end
local labels = {}
local locale = {
    ENTER_IN = "Entrer dans %s : %s", DUNGEON = "donjon", RAID = "raid",
    DELVE = "gouffre", SCENARIO = "scénario",
    LEAVE_DUNGEON = "Quitter le donjon : %s", LEAVE_RAID = "Quitter le raid : %s",
    LEAVE_DELVE = "Quitter le gouffre : %s", LEAVE_SCENARIO = "Quitter le scénario : %s",
}
function LibStub() return { GetLocale = function() return locale end } end
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
UNKNOWN, LEAVE_ZONE = "Inconnu", "Quitter %s"
local version, kind, inside = "forever", "DUNGEON", false
APR = {
    stepHandlers = {},
    DungeonData = {
        forever = { invented = { name = "Fallback name", areaID = 81001 } },
        retail = { invented = { name = "Fallback name", journalInstanceID = 82001 } },
    },
    currentStep = { AddQuestSteps = function(_, key, text) labels[key] = text end },
    Arrow = { SetCoord = noop },
}
function APR:GetGameVersion() return version end
function APR:GetScenarioZoneInfo() return { type = kind } end
function APR:GetMapInfoCached() return { name = "Salle inventée" } end
function APR:IsInScenarioMap() return inside end
local name = "Salle inventée"
C_Map = { GetAreaInfo = function(id) assert(id == 81001); return name end }
function EJ_GetInstanceInfo(id) assert(id == 82001); return name end
dofile("APR-Core/utils/DungeonUtils.lua")
dofile("APR-Core/features/questing/StepTravelHandlers.lua")

for _, profile in ipairs({ "retail", "forever" }) do
    version = profile
    local enter = { EnterInstance = { dungeonKey = "invented" } }
    name = "Salle inventée"
    ENTER_DUNGEON = "Entrer dans %s"
    assert(APR:GetDungeonTravelText(enter) == "Entrer dans Salle inventée",
        "The native entry placeholder receives the destination name directly")
    ENTER_DUNGEON = "Entrer dans le donjon"
    assert(APR:GetDungeonTravelText(enter) == "Entrer dans le donjon: Salle inventée",
        "A native entry caption without placeholders keeps its destination")
    ENTER_DUNGEON, name = "Entrer dans %s", "Salle 100%"
    assert(APR:GetDungeonTravelText(enter) == "Entrer dans Salle 100%",
        "Destination names are data, never another format template")
    name = nil
    assert(APR:GetDungeonTravelText(enter) == "Entrer dans Fallback name")
    assert(APR:GetDungeonTravelText({ EnterInstance = { dungeonKey = "missing" } }) == "Entrer dans Inconnu")
    for _, category in ipairs({ "DUNGEON", "RAID", "DELVE", "SCENARIO" }) do
        kind = category
        inside = false
        for _, action in ipairs({ "EnterInstance", "EnterScenario" }) do
            APR.stepHandlers.RenderScenarioTravel({ [action] = { mapID = 83001 } }, 1)
            assert(labels["ENTER_IN_" .. category] == "Entrer dans " .. locale[category] .. " : Salle inventée",
                "Generic entry formats both the category and the name: " .. category .. "/" .. action)
        end
        inside = true
        local prefixes = { DUNGEON = "Quitter le donjon : ", RAID = "Quitter le raid : ",
            DELVE = "Quitter le gouffre : ", SCENARIO = "Quitter le scénario : " }
        for _, action in ipairs({ "LeaveInstance", "LeaveScenario" }) do
            APR.stepHandlers.RenderScenarioTravel({ [action] = { mapID = 83001 } }, 1)
            assert(labels["LEAVE_" .. category] == prefixes[category] .. "Salle inventée",
                "Exit formats the instance name directly on " .. profile .. ": " .. category .. "/" .. action)
        end
    end
end
print("Instance entry text: native captions/templates, dungeon/raid/delve/scenario names and fallbacks passed")
