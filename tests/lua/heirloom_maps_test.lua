-- Synthetic maps exercise ownership, personal use, event refreshes and secure buttons.
local env = dofile("tests/lua/route_ui_test_env.lua")
local nativeCreateFrame = CreateFrame
function env.methods:RegisterEvent(event)
    self.events = self.events or {}
    self.events[event] = true
end
function env.methods:RegisterUnitEvent(event, unit)
    self:RegisterEvent(event)
    self.unit = unit
end
function env.methods:UnregisterEvent(event) self.events[event] = nil end
function CreateFrame(kind, name, parent, template)
    local frame = nativeCreateFrame(kind, name, parent, template)
    if template == "ObjectiveTrackerContainerHeaderTemplate" then
        frame.Text = frame:CreateFontString()
        frame.MinimizeButton = nativeCreateFrame("Button", nil, frame)
        frame.MinimizeButton:SetNormalTexture("normal")
        frame.MinimizeButton.GetPushedTexture = frame.MinimizeButton.GetNormalTexture
    end
    return frame
end
APR.Color.defaultLightBackdrop = {0, 0, 0, 1}
APR.settings.profile.enableAddon = true
APR.settings.profile.heirloomFrame = {}
APR.settings.db = { char = {} }
function APR:IsPetBattleActive() return false end
function APR:IsRemixCharacter() return false end
local known, owned, personal, itemSpell, loads = {}, {}, {}, {}, 0
APR.Faction = "Alliance"
function APR:IsSpellKnown(id) return known[id] end
function PlayerHasToy(id) return owned[id] end
function GetAchievementInfo(id)
    -- The account has every achievement; this character only has selected ones.
    return id, "Exploration", 10, true, nil, nil, nil, "", 0, 123, "", false, personal[id]
end
C_Heirloom = { GetHeirloomItemIDs = function() return {} end }
C_ToyBox = { GetToyInfo = function(id) return id, "Synthetic map", 123 end }
C_Item.GetItemSpell = function(id)
    loads = loads + 1
    return "Synthetic map spell", itemSpell[id]
end
C_Spell = { GetSpellInfo = function(id) return { name = "Synthetic spell", iconID = 456 } end }
dofile("APR-Core/utils/ProfileUtils.lua")
dofile("APR-Core/features/player/Heirloom.lua")
local maps = {
    {name = "map", id = 880001, faction = "Alliance", achievementID = 990001},
    {name = "map", id = 880002, faction = "Neutral", achievementID = 990002},
    {name = "map", id = 880003, faction = "Horde"},
    {name = "map", id = 880004, faction = "Neutral"},
    {name = "spellMap", id = 880005, spellID = 990005},
}
local function reminders() return maps end
local module = APR.heirloom
module.GetReminders = reminders
owned[880001], owned[880002], owned[880003] = true, true, true
itemSpell[880001], itemSpell[880002] = 990011, 990012
known[990005] = true
module:HeirloomOnInit()
local watcher = module.mapWatcher
local function emit(event, ...) watcher.scripts.OnEvent(watcher, event, ...) end
local function ids(...)
    local expected = {...}
    assert(#module.buttons == #expected, "Unexpected visible map count")
    for index, id in ipairs(expected) do
        assert(module.buttons[index] == module.iconButtons[id], "Unexpected visible map/order")
    end
    assert(HeirloomPanel:IsShown() == (#expected > 0), "Empty map panel must be hidden")
end
ids(880001, 880002, 880005)
assert(module.iconButtons[880001].attributes.type1 == "item")
assert(module.iconButtons[880001].attributes.item == "item:880001")
assert(module.iconButtons[880005].attributes.type1 == "spell")
assert(module.iconButtons[880005].attributes.spell == 990005)
local frames = env.frames()
module:EnsureMapWatcher()
assert(module.mapWatcher == watcher and env.frames() == frames, "One event watcher per module")

-- Other players, unrelated spells and unsuccessful casts cannot mark a map used.
emit("UNIT_SPELLCAST_SUCCEEDED", "party1", "cast", 990011)
emit("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 12345)
assert(next(APR.settings.db.char.usedHeirloomMaps) == nil)
ids(880001, 880002, 880005)
local before = loads
for _ = 1, 100 do emit("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 12345) end
assert(loads == before, "Normal spellcasts must not request item data")
local opaque = {}
function APR:CanAccessValue(value) return value ~= opaque end
emit("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", opaque)
emit("UNIT_SPELLCAST_SUCCEEDED", opaque, "cast", 990011)
assert(next(APR.settings.db.char.usedHeirloomMaps) == nil, "Restricted casts cannot change saved usage")
local achievementInfo = GetAchievementInfo
GetAchievementInfo = function() return nil end
module:RefreshFrameAnchor()
ids(880001, 880002, 880005)
GetAchievementInfo = achievementInfo

-- Personal exploration hides a map even if it was used before this addon update.
personal[990002] = true
emit("ACHIEVEMENT_EARNED", 990002)
ids(880001, 880005)
assert(not module.iconButtons[880002]:IsShown())

-- A successful use anywhere records character state and refreshes immediately.
emit("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 990011)
ids(880005)
assert(APR.settings.db.char.usedHeirloomMaps[880001])
assert(not module.iconButtons[880001]:IsShown())

-- Keep protected widgets unchanged until combat ends, while recording the use now.
env.setCombat(true)
local spellButton = module.iconButtons[880005]
emit("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 990005)
assert(APR.settings.db.char.usedHeirloomMaps[880005] and module._pendingCombatRefresh)
assert(spellButton:IsShown(), "Secure button stays untouched in combat")
env.setCombat(false)
module._combatWatcher.scripts.OnEvent(module._combatWatcher)
ids()

-- Used state survives module reload, independent of shared profile dismissal.
dofile("APR-Core/features/player/Heirloom.lua")
module = APR.heirloom
module.GetReminders = reminders
module:HeirloomOnInit()
watcher = module.mapWatcher
ids()
APR.settings.db.char = {}
personal[990002] = false
module:RefreshFrameAnchor()
ids(880001, 880002, 880005)

-- Recover uncached map spells and avoid refreshing for unrelated item results.
owned[880004] = true
emit("TOYS_UPDATED")
ids(880001, 880002, 880004, 880005)
before = loads
emit("GET_ITEM_INFO_RECEIVED", 777777, true)
assert(loads == before)
itemSpell[880004] = 990014
emit("GET_ITEM_INFO_RECEIVED", 880004, true)
emit("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 990014)
ids(880001, 880002, 880005)
assert(APR.settings.db.char.usedHeirloomMaps[880004])

-- Optional client APIs and missing achievement data remain safe.
C_Heirloom, C_ToyBox, GetAchievementInfo = nil, nil, nil
module:RefreshFrameAnchor()
ids(880005)
known[990005] = false
emit("SPELLS_CHANGED")
ids()
APR.GetGameVersion = function() return APR.GAME_VERSIONS.Forever end
module.mapWatcher = nil
module:EnsureMapWatcher()
assert(module.mapWatcher == nil, "Forever must not register Retail map listeners")
print("Heirloom maps: ownership, exploration, successful use, persistence, combat and late data passed")
