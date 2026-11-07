APR, APRData = {}, { NPCList = {} }
dofile("APR-Core/utils/SecretUtils.lua")
dofile("APR-Core/utils/TargetUtils.lua")
local function same(actual, expected)
    assert(#actual == #expected, "Unexpected target count")
    for i, value in ipairs(expected) do
        assert(actual[i] == value, "Unexpected target order")
    end
end
same(APR:NormalizeRaidIconTargets(101), { 101 })
local authored = { 202, 101, 202 }
same(APR:NormalizeRaidIconTargets(authored), { 202, 101 })
assert(#authored == 3, "Normalization must not edit route data")
for _, invalid in ipairs({ false, 0, -1, 1.2, "101", {}, { 1, 0 }, { [2] = 101 }, { npcID = 0 } }) do
    same(APR:NormalizeRaidIconTargets(invalid), {})
end
same(APR:NormalizeRaidIconTargets(nil), {})
same(APR:NormalizeRaidIconTargets({npcID = 101, questID = 42}), {101})
same(APR:NormalizeRaidIconTargets({{npcID = 202, questID = 43}, 101}), {202, 101})
print("RaidIcon lists: normalization and invalid data passed")

UNKNOWN = "Unknown"
function APR:GetGameVersion() return "forever" end
function GetLocale() return "frFR" end
APRData.NPCNameLocale = "frFR"
APRData.NPCList = { [101] = "Loup des bois", [202] = "Sanglier", [303] = "Sanglier" }
local units = {}
function GetRaidTargetIndex(unit) return units[unit] and units[unit].marker end
function UnitExists(unit) return units[unit] ~= nil end
function UnitIsDeadOrGhost(unit) return units[unit] and units[unit].dead or false end
function UnitIsPlayer(unit) return units[unit] and units[unit].player or false end
function UnitCreatureID(unit) return units[unit] and units[unit].id end
function UnitName(unit) return units[unit] and units[unit].name end
C_NamePlate = { GetNamePlates = function() return { { namePlateUnitToken = "nameplate1" } } end }
local macro = APR:BuildRaidIconMacro({ 101, 202, 101, 303, 404 })
assert(
    macro
        == "/cleartarget\n/targetexact Loup des bois\n/targetmarker [@target,exists,nodead] !8\n/stopmacro [exists,nodead]\n/targetexact Sanglier\n/stopmacro [exists,nodead]\n/cleartarget [dead]",
    "Search exact localized names in order, skipping missing/duplicate names"
)
assert(APR:BuildRaidIconMacro(404) == "", "An unknown NPC must not target or mark arbitrary units")
APRData.NPCList[404] = "Invalide\n/run forbidden()"
assert(APR:BuildRaidIconMacro(404) == "", "Route data cannot inject macro commands")
APRData.NPCList[505] = string.rep("é", 130)
assert(APR:BuildRaidIconMacro(505) == "", "Never truncate a long UTF-8 name")
local overhead =
    "/cleartarget\n/targetexact \n/targetmarker [@target,exists,nodead] !8\n/stopmacro [exists,nodead]\n/cleartarget [dead]"
APRData.NPCList[606] = string.rep("A", 255 - #overhead)
local exactLimit = APR:BuildRaidIconMacro({ 606 })
assert(#exactLimit == 255 and exactLimit:find(APRData.NPCList[606], 1, true), "The exact byte limit is usable")
APRData.NPCList[606] = APRData.NPCList[606] .. "B"
assert(APR:BuildRaidIconMacro({ 606 }) == "", "One byte beyond the limit cannot produce a partial command")
local large = {}
for i = 1, 15 do
    large[i], APRData.NPCList[1000 + i] = 1000 + i, "Créature " .. i .. string.rep("x", 16)
end
local bounded = APR:BuildRaidIconMacro(large)
local ending = "/cleartarget [dead]"
assert(#bounded <= 255 and bounded:sub(-#ending) == ending, "Reserve the complete macro suffix")
units.nameplate1 = { id = 1015, name = APRData.NPCList[1015] }
local visible = APR:BuildRaidIconMacro(large)
assert(visible:find("/targetexact " .. APRData.NPCList[1015], 1, true), "Known visible targets get budget priority")
units.target = { id = 101, name = "Loup des bois", dead = true }
units.nameplate1 = { id = 202, name = "Sanglier" }
assert(APR:FindRaidIconUnitToken({ 101, 202 }) == "nameplate1", "Skip dead matching units")
units.nameplate1.player = true
assert(not APR:FindRaidIconUnitToken({ 101, 202 }), "Players are not NPC targets")
units.nameplate1 = { id = 999, name = "Unrelated" }
assert(not APR:FindRaidIconUnitToken({ 101, 202 }), "Reject unrelated units")

local active = { RaidIcon = { 101, 202 } }
function APR:GetCurrentStep() return active end

-- Protected APIs must never be invoked by rendering, even on a hardware script path.
function SetRaidTarget() error("Protected marker API called by insecure addon code") end
function GetRaidTargetIndex(unit) return units[unit] and units[unit].marker end
units.target = { id = 101, name = "Loup des bois" }
local first = APR:BuildRaidIconMacro({ 101, 202 })
assert(first:find("/targetmarker [@target,exists,nodead] !8", 1, true), "The first NPC uses native set-unmarked skull")
units.nameplate1 = units.target
units.target = { id = 202, name = "Sanglier" }
local second = APR:BuildRaidIconMacro({ 101, 202 })
assert(
    second:find("/targetmarker [@target,exists,nodead] !7", 1, true),
    "Visible priority cannot change the NPC's assigned marker"
)
units.target.marker = 2
assert(
    APR:BuildRaidIconMacro({ 101, 202 }):find("!7", 1, true),
    "Forever emits its supported non-toggling marker syntax"
)
units.focus = { id = 999, marker = 7 }
assert(not APR:BuildRaidIconMacro({ 101, 202 }):find("!7", 1, true), "Do not steal an observed occupied marker")
units.focus = nil
units.target, units.nameplate1 = nil, nil
function GetNextAvailableRaidTargetMarkerIndex(index, reverse, wrap, dead)
    assert(reverse == false and wrap == false and dead == false)
    return index == 8 and 0 or index
end
assert(not APR:BuildRaidIconMacro(101):find("/targetmarker", 1, true), "Native availability protects markers on unobserved units")
GetNextAvailableRaidTargetMarkerIndex = nil
assert(
    not APR:BuildRaidIconMacro({ 202, 303 }):find("/targetmarker", 1, true),
    "Ambiguous localized names cannot receive an arbitrary ID's marker"
)

local version, interface = "retail", 120007
function APR:GetGameVersion() return version end
function GetBuildInfo() return "", "", "", interface end
for _, build in ipairs({ 120007, 120100, 120105 }) do
    interface = build
    assert(APR:BuildRaidIconMacro(101):find("~8", 1, true), "Supported native non-overwriting markers")
end
for _, build in ipairs({ 110207, 120000, 120001, 120005 }) do
    interface = build
    local compatible = APR:BuildRaidIconMacro(101)
    assert(
        compatible:find("/targetexact Loup des bois", 1, true) and not compatible:find("/targetmarker", 1, true),
        "Older clients retain exact targeting when non-overwriting native marking is unavailable"
    )
end
version, interface = "forever", 16001
assert(APR:BuildRaidIconMacro(101):find("!8", 1, true), "Forever has its own native capability branch")
assert(not APR:BuildRaidIconMacro(101):find("/run", 1, true), "No insecure script performs a protected action")

local refreshes, updates = 0, 0
APR.currentStep = { UpdateRaidIconButtonMacro = function() updates = updates + 1 end }
APR.event = { QueueStepRefresh = function() refreshes = refreshes + 1 end }
function APR:Debug() end
function UnitCanAttack() return true end
units.target = { id = 202, name = "Sanglier localisé" }
APR:ScanUnitForNPC("target", "TEST")
assert(updates == 1, "A newly learned list member name refreshes the secure macro")
APR:ScanUnitForNPC("target", "TEST")
assert(updates == 1, "An unchanged name avoids rebuilding")
units.target = { id = 999, name = "Autre créature" }
APR:ScanUnitForNPC("target", "TEST")
assert(updates == 1, "Unrelated name discovery does not refresh this button")
local secret = setmetatable({}, { __tostring = function() error("secret leaked") end })
function canaccessvalue(value) return not rawequal(value, secret) end
units.target = { id = secret, name = "Restricted", marker = secret }
assert(
    not APR:BuildRaidIconMacro({ 101, 202 }):find("/targetmarker", 1, true),
    "Inaccessible observed markers cannot authorize stealing"
)
local originalExists = UnitExists
function UnitExists(unit)
    if unit == "target" then return secret end
    return originalExists(unit)
end
assert(not APR:FindRaidIconUnitToken({ 101, 202 }), "Secret existence cannot authorize a target")
assert(
    not APR:BuildRaidIconMacro({ 101, 202 }):find("/targetmarker", 1, true),
    "Unknown unit existence also leaves marker availability unknown"
)
UnitExists = originalExists
units.target = { id = 1015, name = APRData.NPCList[1015] }
local beyond = APR:BuildRaidIconMacro(large)
local firstBlock = beyond:match("^(.-)/stopmacro")
assert(
    beyond:find("/targetexact " .. APRData.NPCList[1015], 1, true) and not firstBlock:find("/targetmarker", 1, true),
    "Entries beyond the eight native markers remain targetable"
)
print("RaidIcon: localized lists, byte limits, native markers, older clients, secrets and refresh passed")
