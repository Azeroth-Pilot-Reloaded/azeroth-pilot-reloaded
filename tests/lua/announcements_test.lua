-- Synthetic announcements: native transitions, channels, options and recovery.
local L = setmetatable({
    ANNOUNCE_LEVEL = "Level %d.", ANNOUNCE_LEVEL_EMOTE = "reaches %d.",
    ANNOUNCE_QUEST = "Quest %s.", ANNOUNCE_OBJECTIVE = "Objective %s (%s).",
    ANNOUNCE_COLLECT = "Collection %s.", ANNOUNCE_ROUTE = "Route %s.",
    ANNOUNCE_ROUTE_EMOTE = "completes %s.",
}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
local group, raid, instance, lockdown = true, false, false, false
LE_PARTY_CATEGORY_INSTANCE = 2
function IsInGroup(category) return category == 2 and instance or category == nil and group end
function IsInRaid() return raid end
local sent = {}
C_ChatInfo = {
    InChatMessagingLockdown = function() return lockdown end,
    SendChatMessage = function(message, channel) sent[#sent + 1] = { message, channel } end,
}
local options = { enabled = true, group = true, solo = true, level = true, quest = true,
    objective = true, collect = true, flight = true, hearthstone = true, route = true }
APR = { settings = { profile = { enableAddon = true, announcements = options } },
    QUEST_STATUS = { COMPLETE = "done", PROGRESS = "progress" }, ActiveQuests = {} }
APR.GAME_VERSIONS = { Retail = 1, Forever = 2 }
local gameVersion = APR.GAME_VERSIONS.Retail
function APR:GetGameVersion() return gameVersion end
function IsInInstance() return instance end
function APR:GetRouteDisplayName(key) return "Label " .. key end
dofile("APR-Core/features/player/Announcements.lua")
local a = APR.announcements
local function count(n) assert(#sent == n, "Expected " .. n .. " messages; got " .. #sent) end
a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 12)
assert(sent[1][1] == "[APR] Level 12." and sent[1][2] == "PARTY")
raid = true
a:Send("level", "ANNOUNCE_LEVEL", nil, 13)
assert(sent[2][2] == "RAID")
instance = true
a:Send("level", "ANNOUNCE_LEVEL", nil, 14)
assert(sent[3][2] == "INSTANCE_CHAT")
group, raid, instance = false, false, false
a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 15)
assert(sent[4][1] == "reaches 15. [APR]" and sent[4][2] == "EMOTE")
a:Send("quest", "ANNOUNCE_QUEST", nil, "Silent solo")
options.solo = false
a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 16)
count(4)
group, options.solo = true, true
for _, flag in ipairs({ "enabled", "group", "level" }) do
    options[flag] = false
    a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 17)
    options[flag] = true
end
lockdown = true
a:Send("level", "ANNOUNCE_LEVEL", nil, 18)
lockdown = false
APR.routeValidationPending = true
a:Send("level", "ANNOUNCE_LEVEL", nil, 19)
APR.routeValidationPending = nil
count(4)

local quest = { title = "Invented quest", status = "progress", objectives = {
    { text = "Crystals: 0/3", status = "progress", type = "item" },
    { text = "Gate: 0/1", status = "progress", type = "monster" },
} }
APR.ActiveQuests[101] = quest
a:ObserveQuests() -- login baseline
count(4)
quest.objectives[1].text, quest.objectives[1].status = "Crystals: 3/3", "done"
a:ObserveQuests()
assert(sent[5][1] == "[APR] Collection Crystals: 3/3.")
a:ObserveQuests()
count(5)
quest.objectives[2].text, quest.objectives[2].status = "Gate: 1/1", "done"
quest.status = "done"
a:ObserveQuests()
assert(sent[6][1] == "[APR] Quest Invented quest.") -- suppress objective duplicates
a:ObserveQuests()
count(6)
APR.ActiveQuests = {}
a:ObserveQuests()
APR.ActiveQuests[101] = quest
a:ObserveQuests() -- reaccept/late data starts silently
count(6)
quest.status, quest.objectives[2].status = "progress", "progress"
a:ObserveQuests()
quest.objectives[2].status = "done"
a:ObserveQuests()
assert(sent[7][1] == "[APR] Objective Gate: 1/1 (Invented quest).")

APR.transitionHistory = { cursor = 1, entries = { { route = "synthetic", reason = "automatic" } } }
a:RouteCompleted("synthetic")
a:RouteCompleted("synthetic")
assert(sent[8][1] == "[APR] Route Label synthetic.")
APR.transitionHistory.entries[1] = { route = "skipped", reason = "manual_skip" }
a:RouteCompleted("skipped")
a:RouteCompleted("loaded")
count(8)
local ui = APR:CreateAnnouncementOptions()
ui.args.enabled.set(nil, false)
assert(not ui.args.enabled.get() and ui.args.quest.disabled())
assert(not ui.args.enabled.disabled())
ui.args.enabled.set(nil, true)
assert(ui.args.quest.get() and not ui.args.quest.disabled())
ui.args.collect.set(nil, false)
assert(options.collect == false and options.objective == true)
APR.settings.profile.enableAddon = false
assert(ui.args.enabled.disabled())
APR.settings.profile.enableAddon = true

-- Native send failures stay contained; modern and legacy send entry points both work.
C_ChatInfo.SendChatMessage = function() error("native refusal") end
a:Send("level", "ANNOUNCE_LEVEL", nil, 20)
SendChatMessage = function(message, channel) sent[#sent + 1] = { message, channel } end
C_ChatInfo = nil
a:Send("level", "ANNOUNCE_LEVEL", nil, 21)
assert(sent[9][1] == "[APR] Level 21.")
a:Send("quest", "ANNOUNCE_QUEST", nil, string.rep("é", 200))
assert(#sent[10][1] <= 255 and sent[10][1]:sub(-3) == "...")
a:Send("quest", "ANNOUNCE_QUEST", nil, "|cff123456|Hquest:101|h[Name]|h|r\n")
assert(sent[11][1] == "[APR] Quest [Name].")
-- Disabling the whole-quest announcement preserves independently enabled collection notices.
options.quest = false
options.collect = true
local collectQuest = { title = "Another quest", status = "progress", objectives = {
    { text = "Shards: 0/2", status = "progress", type = "item" },
} }
APR.ActiveQuests[102] = collectQuest
a:ObserveQuests()
collectQuest.status, collectQuest.objectives[1].status = "done", "done"
collectQuest.objectives[1].text = "Shards: 2/2"
a:ObserveQuests()
assert(sent[12][1] == "[APR] Collection Shards: 2/2.")
group = false
a:Send("route", "ANNOUNCE_ROUTE", "ANNOUNCE_ROUTE_EMOTE", string.rep("界", 150))
assert(#sent[13][1] <= 255 and sent[13][1]:sub(-6) == " [APR]" and sent[13][2] == "EMOTE")

-- A blocked native call may emit ADDON_ACTION_BLOCKED even when pcall returns normally.
-- Prevent the call itself for automatic outdoor EMOTEs on Forever, on both API paths.
local blocked = 0
local function nativeSend(message, channel)
    if gameVersion == APR.GAME_VERSIONS.Forever and channel == "EMOTE" and not instance then
        blocked = blocked + 1
        return
    end
    sent[#sent + 1] = { message, channel }
end
gameVersion = APR.GAME_VERSIONS.Forever
SendChatMessage = nativeSend
for _, modern in ipairs({ false, true }) do
    C_ChatInfo = modern and { SendChatMessage = nativeSend,
        InChatMessagingLockdown = function() return lockdown end } or nil
    local baseline = #sent
    group, instance = false, false
    a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 22)
    a:Send("route", "ANNOUNCE_ROUTE", "ANNOUNCE_ROUTE_EMOTE", "Invented journey")
    count(baseline)
    assert(blocked == 0, "Outdoor Forever EMOTEs must never reach the protected API")
    instance = true
    a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 23)
    assert(sent[baseline + 1][2] == "EMOTE")
    group, instance = true, false
    a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 24)
    assert(sent[baseline + 2][2] == "PARTY")
    raid = true
    a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 25)
    assert(sent[baseline + 3][2] == "RAID")
    instance = true
    a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 26)
    assert(sent[baseline + 4][2] == "INSTANCE_CHAT")
    if modern then
        lockdown = true
        a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 27)
        count(baseline + 4)
        lockdown = false
    end
    group, raid, instance = false, false, false
    gameVersion = APR.GAME_VERSIONS.Retail
    a:Send("level", "ANNOUNCE_LEVEL", "ANNOUNCE_LEVEL_EMOTE", 28)
    assert(sent[baseline + 5][2] == "EMOTE", "Retail retains automatic solo announcements")
    gameVersion = APR.GAME_VERSIONS.Forever
end
assert(blocked == 0)
print("announcements tests passed")
