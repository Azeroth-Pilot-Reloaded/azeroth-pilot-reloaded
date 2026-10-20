local function forbidden() error("Secret identity must not be read") end
local secret = setmetatable({}, { __index = forbidden, __tostring = forbidden })
function canaccessvalue(value) return not rawequal(value, secret) end
dofile("APR-Core/utils/SecretUtils.lua")
APR, APRData = {}, { NPCList = {} }
UNKNOWN = "Unknown"
local step = { KillNPC = { npcID = 61412, name = "Dark Shaman Koranthal" } }
function APR:GetCurrentStep() return step end
function UnitGUID() return secret end
function UnitCreatureID() return secret end
dofile("APR-Core/utils/TargetUtils.lua")
local queries = 0
C_TooltipInfo = { GetHyperlink = function(link)
    assert(link == "unit:Creature-0-0-0-0-61412-0")
    queries = queries + 1
    return { lines = { { leftText = "Sombre chaman Koranthal" } } }
end }
local macro = APR:BuildRaidIconMacro(61412)
assert(macro == "/cleartarget\n/targetexact Sombre chaman Koranthal\n/tm [@target,exists] 8",
    "A first-seen boss gets a localized secure macro even with a secret GUID")
assert(APR:BuildRaidIconMacro(61412) == macro and queries == 1, "Public localized names are cached")
assert(APR:FindRaidIconUnitToken(61412) == nil, "Secret identity is never used to guess a unit token")
assert(APR:BuildRaidIconMacro(61412, "nameplate2") ==
    "/target [@nameplate2,exists]\n/tm [@nameplate2,exists] 8")
APRData.NPCList = {}
C_TooltipInfo.GetHyperlink = function() return { lines = { { leftText = secret } } } end
assert(APR:BuildRaidIconMacro(61412):find("/targetexact Dark Shaman Koranthal", 1, true),
    "A supplied route name remains available without tooltip data")
function GetLocale() return "frFR" end
assert(APR:BuildRaidIconMacro(61412) == "/tm [@mouseover,exists][@target,exists] 8",
    "An untranslated fallback must not clear the user's target or search for an English NPC on a French client")
step = {}
assert(APR:BuildRaidIconMacro(61412) == "/tm [@mouseover,exists][@target,exists] 8",
    "An unresolved target must have a usable manual mouseover/target action")
APRData.NPCList[61412] = "Boss\n/run unwanted()"
assert(not APR:GetRaidIconNpcName(61412), "Names cannot inject additional macro commands")
print("RaidIcon: localized uncached KillNPC names, secret GUIDs, token targeting and manual fallback passed")
