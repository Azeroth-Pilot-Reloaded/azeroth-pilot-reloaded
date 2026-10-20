local handler
function LibStub() return { GetLocale = function() return {} end } end
function CreateFrame()
    return { RegisterEvent = function(_, event) assert(event ~= "COMBAT_LOG_EVENT_UNFILTERED") end,
        SetScript = function(_, _, fn) handler = fn end }
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

-- Expected encounter/NPC associations independently checked against Forever's
-- DungeonEncounter 1.60.1.70450 and the NPC IDs used by the playable routes.
local cases = {
    { "RFC", 389, 2732, { 11517 } }, { "RFC", 389, 2733, { 11520 } },
    { "RFC", 389, 2734, { 11518 } }, { "RFC", 389, 2735, { 11519 } },
    { "ROL", 2999, 3353, { 250483 } }, { "ROL", 2999, 3354, { 250657 } },
    { "HOT", 3065, 3493, { 261306 } }, { "HOT", 3065, 3496, { 261319 } },
    { "WC", 43, 585, { 3671 } }, { "WC", 43, 586, { 3669 } },
    { "WC", 43, 588, { 3670 } }, { "WC", 43, 590, { 3673 } },
    { "WC", 43, 591, { 5775 } }, { "WC", 43, 592, { 3654 } },
    { "DM", 36, 2741, { 644 } }, { "DM", 36, 2742, { 642, 643 } },
    { "DM", 36, 2743, { 1763 } }, { "DM", 36, 2744, { 647 } },
    { "DM", 36, 2745, { 646 } }, { "DM", 36, 2746, { 645 } },
    { "DM", 36, 2747, { 639 } },
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
        for _ in pairs(run.kills) do count = count + 1 end
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
APR.ActiveRoute, instance = "early-rfc", 389
step = { Dungeon = "RFC", Note = "Before the boss" }
local before = refreshes
handler(nil, "ENCOUNTER_END", 2733, "Taragaman", 1, 5, 1, {})
assert(refreshes == before, "Earlier notes must not rebuild on boss credit")
step = { Dungeon = "RFC", KillNPC = { dungeonKey = "RFC", npcID = 11520 } }
before = advanced
APR:RenderDungeonKill(step, false)
assert(advanced == before + 1)

-- Retail encounter IDs cannot be repurposed for Classic bosses in Forever.
APR:ResetDungeonRun(APR.ActiveRoute)
for _, encounter in ipairs({ 1443, 1444, 1445, 1446 }) do
    handler(nil, "ENCOUNTER_END", encounter, "Retail boss", 1, 5, 1, {})
end
assert(not APR:GetDungeonRun(APR.ActiveRoute, "RFC"))
print("Forever: 21 encounters across five dungeons, secret payloads, Sneed phases and client isolation passed")
