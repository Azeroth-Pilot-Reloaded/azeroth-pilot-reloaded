local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load()
local lib = LibStub("LibAPRNavigation-1.0")
data.env.getQuestName = function() return "Return to the Veiled Market" end
data.env.isQuestCompleted = function() return false end
data.env.isQuestActive = function() return false end
data.env.getAchievementName = function() return "Test achievement" end
data.env.isAchievementCompleted = function() return false end
local edge = { instruction = "Take the portal to Tazavesh",
    blockedRequirements = { any = { { quest = 84957 }, { questActive = 84957 } } } }
local text, lines = data:GetBlockedRouteText({ edge, edge })
assert(text == "No accessible route found.\n\nTake the portal to Tazavesh\n"
    .. "  - Complete quest Return to the Veiled Market [84957]\n  or\n"
    .. "  - Have quest Return to the Veiled Market [84957] in the quest log",
    "One passage, two alternatives, no redundant parentheses or repeated passage")
assert(#lines == 6 and lines[1].kind == "status" and lines[3].kind == "passage"
    and lines[4].kind == "requirement" and lines[5].kind == "operator")
assert(not text:find("|c", 1, true), "The reusable library returns host-independent plain text")

edge.blockedRequirements = { minLevel = 120,
    any = { { quest = 84957 }, { all = { { questActive = 84957 }, { achievement = 123 } } } } }
text = data:GetBlockedRouteText({ edge })
assert(text:find("  - Complete quest", 1, true)
    and text:find("\n      - Have quest", 1, true)
    and text:find("\n      and\n      - Earn achievement", 1, true)
    and text:find("\n  and\n  - Reach level 120", 1, true),
    "Mixed AND/OR groups keep their scope through indentation")

edge.blockedRequirements = { notCondition = { quest = 84957 } }
data.env.isQuestCompleted = function() return true end
text = data:GetBlockedRouteText({ edge })
assert(text:find("  - Must not meet: Complete quest", 1, true), "Negation survives singleton removal")
data.env.isQuestCompleted = function() return nil end
text = data:GetBlockedRouteText({ edge })
assert(text:find("Unverified client data:", 1, true), "Uncertain data stays explicit")

text, lines = data:GetBlockedRouteText({})
assert(#lines == 3 and lines[2].text == "" and lines[3].kind == "requirement"
    and text:find(data:GetText("NAVIGATION_NO_KNOWN_PASSAGE"), 1, true), "Empty diagnostics keep a useful explanation")

data.env.isQuestCompleted = function() return false end
edge.blockedRequirements = { any = { { quest = 84957 }, { questActive = 84957 } } }
for locale in pairs(lib.locales) do
    data.env.getLocale = function() return locale end
    text = data:GetBlockedRouteText({ edge })
    local join = data:GetText("NAVIGATION_OR"):match("^%s*(.-)%s*$")
    assert(text:sub(1, #lib.locales[locale].PATH_NOT_FOUND) == lib.locales[locale].PATH_NOT_FOUND)
    assert(text:find("\n  " .. join .. "\n", 1, true), locale .. " keeps its localized alternative separator")
end
data.env.getLocale = function() return "enUS" end

local previous = APR.WrapTextWithAppearanceColor
local roles = {}
function APR:WrapTextWithAppearanceColor(value, scope, role)
    assert(scope == "currentStep" and role)
    roles[role] = true
    return "<" .. role .. ">" .. value .. "</" .. role .. ">"
end
text = APR.NavigationAdapter:GetBlockedRouteText({ edge }, true)
assert(roles.error and roles.title and roles.base and roles.muted,
    "The host uses themed warning, passage, action and separator colors")
assert(text:find("</error>\n\n<title>", 1, true), "Visual grouping retains its blank line")
assert(not APR.NavigationAdapter:GetBlockedRouteText({ edge }):find("<error>", 1, true),
    "Plain-text callers do not receive UI styling")
APR.WrapTextWithAppearanceColor = previous
print("Navigation diagnostics layout: alternatives, nested scope, negation, unknowns, locales and themed roles passed")
