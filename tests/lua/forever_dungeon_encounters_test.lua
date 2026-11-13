local handler
function LibStub()
    return { GetLocale = function() return {} end }
end
function CreateFrame()
    return {
        RegisterEvent = function(_, event) assert(event ~= "COMBAT_LOG_EVENT_UNFILTERED") end,
        SetScript = function(_, _, fn) handler = fn end,
    }
end
local instance, step, advanced, refreshes = 389, {}, 0, 0
function IsInInstance() return true, "party" end
function GetInstanceInfo() return "Dungeon", "party", 0, "", 0, 0, false, instance end
function UnitGUID() error("Encounter completion must not depend on a unit GUID") end
APR = { PlayerID = "one", settings = { profile = { enableAddon = true } } }
APRData = { one = {} }
function APR:GetGameVersion() return "forever" end
function APR:GetCurrentStep() return step end
function APR:UpdateStep() refreshes = refreshes + 1 end
function APR:UpdateNextStep() advanced = advanced + 1 end
dofile("APR-Core/utils/DungeonUtils.lua")

local function forbiddenRead() error("Secret encounter contents must not be read") end
local secret = setmetatable({}, { __index = forbiddenRead, __eq = forbiddenRead })
function canaccessvalue(value) return not rawequal(value, secret) end
function issecretvalue(value) return rawequal(value, secret) end

-- Invented encounters exercise engine behavior independently of shipped guides.
APR.DungeonData = { forever = {
    PRIMARY = { instanceID = 83000, instanceType = "party", bosses = { [92001] = true, [92002] = true, [92003] = true },
        encounters = { [91001] = 92001, [91002] = { 92002, 92003 } } },
    SECONDARY = { instanceID = 83001, instanceType = "party", bosses = { [92004] = true },
        encounters = { [91003] = 92004 } },
} }
local cases = {
    { "PRIMARY", 83000, 91001, { 92001 } },
    { "PRIMARY", 83000, 91002, { 92002, 92003 } },
    { "SECONDARY", 83001, 91003, { 92004 } },
}
for _, case in ipairs(cases) do
    local key, correctInstance, encounter, npcs = unpack(case)
    APR.ActiveRoute = "forever-" .. key
    step = { Dungeon = key, KillNPC = { dungeonKey = key, npcID = npcs[1] } }
    for _, payload in ipairs({ {}, secret, { { creatureID = secret, remainingHealthPercent = secret } } }) do
        APR:ResetDungeonRun(APR.ActiveRoute)
        instance = correctInstance + 100000
        handler(nil, "ENCOUNTER_END", encounter, "boss", 1, 5, 1, payload)
        assert(not APR:GetDungeonRun(APR.ActiveRoute, key), "Wrong instance must not grant credit")
        instance = correctInstance
        handler(nil, "ENCOUNTER_END", encounter, "boss", 1, 5, 0, payload)
        assert(not APR:GetDungeonRun(APR.ActiveRoute, key), "Wipes must not grant credit")
        local before = refreshes
        handler(nil, "ENCOUNTER_END", encounter, "boss", 1, 5, 1, payload)
        local run = APR:GetDungeonRun(APR.ActiveRoute, key)
        assert(run and refreshes == before + 1, "A successful encounter refreshes once")
        local count = 0
        for _ in pairs(run.kills) do
            count = count + 1
        end
        assert(count == #npcs, "Only the encounter's NPCs receive credit")
        for _, npcID in ipairs(npcs) do
            assert(run.kills[npcID], "Missing canonical NPC credit: " .. npcID)
            step.KillNPC.npcID = npcID
            local previous = advanced
            APR:RenderDungeonKill(step, false)
            assert(advanced == previous + 1, "Each credited NPC completes its own checkpoint")
        end
    end
end

-- Credit collected before a boss step is rendered remains usable afterward.
APR.ActiveRoute, instance = "early-credit", 83000
step = { Dungeon = "PRIMARY", Note = "Before the boss" }
local before = refreshes
handler(nil, "ENCOUNTER_END", 91001, "Invented boss", 1, 5, 1, {})
assert(refreshes == before, "Earlier notes must not rebuild on boss credit")
step = { Dungeon = "PRIMARY", KillNPC = { dungeonKey = "PRIMARY", npcID = 92001 } }
before = advanced
APR:RenderDungeonKill(step, false)
assert(advanced == before + 1)

-- Unknown encounters cannot grant kills even with an otherwise valid payload.
APR:ResetDungeonRun(APR.ActiveRoute)
for _, encounter in ipairs({ 91990, 91991, 91992 }) do
    handler(nil, "ENCOUNTER_END", encounter, "Unknown boss", 1, 5, 1, {})
end
assert(not APR:GetDungeonRun(APR.ActiveRoute, "PRIMARY"))
print("Forever: synthetic single/multiple NPC credit, secret payloads, wrong instances and unknown encounters passed")
