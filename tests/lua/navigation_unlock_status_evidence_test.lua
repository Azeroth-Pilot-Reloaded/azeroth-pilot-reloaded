-- The status export must distinguish an orphaned attempt from active native
-- guidance without starting, restoring, copying or advancing that guidance.
local locale = setmetatable({}, { __index = function(_, key) return key end })
local library = { modules = { geography = 42, conditions = 8, unlock_runner = 4, unlocks = 1, unlock_locales = 3 } }
function LibStub(name)
    if name == "AceLocale-3.0" then return { GetLocale = function() return locale end } end
    if name == "LibAPRNavigation-1.0" then return library, 19 end
end
UNKNOWN, FRIENDS_LIST_REALM, NAME, NARRATION_STATUS_HIDDEN = "Unknown", "Realm", "Name", "Hidden"
CHARACTER, YES, NO = "Character", "Yes", "No"
function GetRealmName() return "PrivateRealm" end
local text, activeReads = nil, 0
local function forbidden() error("Export must not execute the navigation runtime") end
APR = { PlayerID = "Private-Realm", Username = "PrivateCharacter", ActiveRoute = "custom-route", NavigationUnlockRevision = 3,
    UI = { ShowTextReport = function(_, _, value) text = value end },
    NavigationData = { profile = "retail", unlockRoutes = { {}, {}, {} }, unlockSources = { {} },
        CreateUnlockSession = forbidden, RestoreUnlockSession = forbidden, GetUnlockRoutes = forbidden,
        env = { getQuestAvailabilityEvidence = forbidden, isQuestAvailable = forbidden } },
    StartNavigationUnlock = forbidden, RefreshNavigationUnlockRoute = forbidden,
    navigation = { state = "no_path", cursor = 1, generation = 12, queue = {}, reason = "search_failed",
        GetActiveStep = function() activeReads = activeReads + 1; return nil end,
        Update = forbidden },
}
function APR:CanAccessValue(value) return type(value) ~= "table" or not value.restricted end
function APR:GetSkinProviderName() return "wow" end
function APR:PeekCurrentStep() return { Waypoint = 1, Zone = 2472 }, 8 end
APRData = { [APR.PlayerID] = { NavigationUnlockAttempts = {
    route = "custom-route", index = 8, edges = { ["portal-karesh"] = true },
} } }
dofile("APR-Core/ui/panels/StatusReport.lua")
function APR:getStatusReportInfos()
    local values = {}
    for _, key in ipairs({ "aprVersion", "wowVersion", "clientLanguage", "serverType", "currentTime", "currentRoute",
        "currentStep", "currentContinent", "currentZone", "currentCoords", "currentWorldCoords", "charFaction", "charClass", "charLevel" }) do
        values[key] = { key, key }
    end
    return values
end
APR:ExportStatusReport()
assert(text:find("**hostReady**: true", 1, true) and text:find("**libraryLoaded**: true", 1, true)
    and text:find("**libraryVersion**: 19", 1, true) and text:find("**hostRevision**: 3", 1, true))
assert(text:find("**unlock\\_runner**: 4", 1, true) and text:find("**unlockRoutes**: 3", 1, true))
assert(text:find("**geography**: 42", 1, true), "Status identifies the loaded geography implementation")
assert(text:find("**active**: false", 1, true) and text:find("**saved**: false", 1, true)
    and text:find("**attempts**:", 1, true) and text:find("**portal-karesh**: true", 1, true),
    "An orphaned attempted entrance remains distinguishable from an active or saved session")
assert(APRData[APR.PlayerID].NavigationUnlockAttempts.edges["portal-karesh"] == true and not APR._navigationUnlock)

local root = { status = "planning", cursor = 1, depth = 0, Step = forbidden,
    build = { status = "planning", scoredRecipes = 73, worker = "never-export-worker" },
    plan = { edgeID = "portal-karesh", steps = { {}, {} }, graph = "never-export-plan" } }
local child = { status = "missing_data", cursor = 3, depth = 1,
    action = { kind = "missing", questID = 84956, reason = "quest_unavailable", private = "never-export-action" }, child = root,
    acceptanceEvidence = { questID = 84956, offer = "unavailable", requirements = "blocked", known = true, complete = false,
        conditions = { { key = "quest", value = 79573, state = "blocked", private = "never-export-condition" },
            { key = "currency", id = 2900, state = "passed" } },
        server = { npcID = 227758, kind = "gossip", offered = false, source = "npc_interaction", questID = 84956,
            private = "never-export-server" } } }
root.child = child
APR._navigationUnlock = { context = { route = "custom-route", index = 8, player = APR.Username },
    timer = { callback = forbidden }, session = root }
APRData[APR.PlayerID].NavigationUnlockState = { route = "custom-route", index = 8,
    library = { schema = 1, private = "never-export-saved-state" } }
APR:ExportStatusReport()
assert(text:find("**active**: true", 1, true) and text:find("**saved**: true", 1, true)
    and text:find("**scoredRecipes**: 73", 1, true) and text:find("**questID**: 84956", 1, true)
    and text:find("**sessionsTruncated**: true", 1, true), "Cycles in unexpectedly retained sessions are bounded")
assert(not text:find("never-export", 1, true) and not text:find("PrivateCharacter", 1, true)
    and not text:find("PrivateRealm", 1, true), "Session internals, saved payloads and identity remain private")
assert(root.child == child and child.child == root and root.build.scoredRecipes == 73)
assert(text:find("**acceptanceEvidence**:", 1, true) and text:find("**offer**: unavailable", 1, true)
    and text:find("**requirements**: blocked", 1, true) and text:find("**known**: true", 1, true)
    and text:find("**complete**: false", 1, true), "Cached acceptance evidence separates server offers from extracted conditions")
assert(text:find("**value**: 79573", 1, true) and text:find("**id**: 2900", 1, true)
    and text:find("**npcID**: 227758", 1, true) and text:find("**offered**: false", 1, true),
    "Condition identity and the already-observed matching server interaction remain explicit")
for index = 1, 20 do APRData[APR.PlayerID].NavigationUnlockAttempts.edges["edge-" .. index] = true end
for index = 3, 50 do
    child.acceptanceEvidence.conditions[index] = { key = "condition-" .. index, value = index, state = "unknown" }
end
APR:ExportStatusReport()
local _, edges = text:gsub("%*%*edge%-", "")
assert(edges <= 8 and text:find("**truncated**: true", 1, true))
local _, conditions = text:gsub("condition%-", "")
assert(conditions <= 30 and text:find("**conditionsTruncated**: true", 1, true), "Acceptance condition evidence is bounded at32")
assert(#child.acceptanceEvidence.conditions == 50 and child.acceptanceEvidence.server.offered == false,
    "Export does not alter cached acceptance evidence")
library.modules = { restricted = true }
APR:ExportStatusReport()
assert(not text:find("**modules**", 1, true), "Restricted library internals are not enumerated")
assert(activeReads == 4, "Each export keeps the existing single read of the published active step")
print("Unlock status evidence: readiness, versions, catalogue sizes, orphaned attempts, bounded sessions and read-only privacy passed")
