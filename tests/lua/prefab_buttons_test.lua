-- Catalogue support keeps buttons visible independently of live eligibility.
local env = dofile("tests/lua/route_browser_test_env.lua")
dofile("APR-Core/data/models/Classes.lua")
local browser, config, kind = APR.RouteBrowser, APR.routeconfig, APR.PREFAB_TYPES
local version = APR.GAME_VERSIONS.Forever
function APR:GetGameVersion() return version end
function APR:GetPlayerEffectiveLevel() return self.Level end
APR.Faction, APR.Race, APR.ClassName, APR.ClassId = "Horde", "Orc", "WARRIOR", 1
APR.MaxLevel, APR.Level = 60, 20
APR.RouteQuestStepList = {
    outdoor = {
        label = "Invented itinerary",
        expansion = APR.EXPANSIONS.Forever,
        conditions = { MinLevel = 10, Class = "WARRIOR" },
        prefab = { [kind.Leveling] = 1, [kind.Speedrun] = { index = 1, endLevel = 60 } },
    },
    dungeon = {
        label = "Invented dungeon",
        expansion = APR.EXPANSIONS.Forever,
        conditions = { MinLevel = 20, Class = "WARRIOR" },
        category = APR.CATEGORIES.Dungeons,
        prefab = { [kind.Dungeons] = 1 },
        nextRoute = { "outdoor" },
    },
    otherClient = {
        label = "Other client",
        expansion = APR.EXPANSIONS.Midnight,
        prefab = { [kind.Leveling] = 1, [kind.Speedrun] = 1, [kind.AllQuests] = 1 },
    },
}
local updates, messages = 0, 0
function config:SendCustomPathUpdate() updates = updates + 1 end
APR.questionDialog = { CreateMessagePopup = function() messages = messages + 1 end }
browser:Show()
local buttons = {}
for _, button in ipairs(browser.prefabButtons) do
    buttons[button.prefabKind] = button
end
local function visible(enabled, levelingEnabled)
    if levelingEnabled == nil then levelingEnabled = enabled end
    assert(#browser.prefabs == 3 and browser.prefabPanel:IsShown())
    assert(
        browser.prefabs[1] == buttons.speedrun
            and browser.prefabs[2] == buttons.dungeons
            and browser.prefabs[3] == buttons.leveling,
        "Keep the supported button order and layout"
    )
    assert(buttons.speedrun:IsShown() and buttons.leveling:IsShown() and buttons.dungeons:IsShown())
    assert(buttons.speedrun:IsEnabled() == enabled and buttons.leveling:IsEnabled() == levelingEnabled)
    assert(
        buttons.dungeons:IsEnabled() == enabled and not buttons.all_quests:IsShown(),
        "Current dungeon availability and client-specific content stay independent"
    )
    assert(browser.prefabs[1].width > 0 and browser.prefabs[3].point[4] > browser.prefabs[1].point[4])
end
visible(true)
local originalWidth = buttons.leveling.width
APRCustomPath.test, APRData.test.outdoor = { "Existing path" }, 7
local path, progress = APRCustomPath.test, APRData.test
for _, level in ipairs({ 60, 1, 60 }) do
    APR.Level = level
    browser:Refresh(true)
    visible(false)
    assert(buttons.leveling.width == originalWidth, "Availability cannot collapse the button row")
    assert(not config:HasPrefab("leveling") and config:HasPrefab("leveling", true))
    assert(not config:HasPrefab("speedrun") and config:HasPrefab("speedrun", true))
    -- Even a direct/stale callback must retain the planner's atomic refusal.
    buttons.leveling.scripts.OnClick()
    buttons.speedrun.scripts.OnClick()
    assert(APRCustomPath.test == path and APRData.test == progress and APRData.test.outdoor == 7 and updates == 0)
end
assert(messages == 3)
APR.Level = 20
browser:Refresh(true)
visible(true)
APR.ClassName, APR.ClassId = "MAGE", 8
browser:Refresh(true)
visible(false)
APR.ClassName, APR.ClassId = "WARRIOR", 1
APRZoneCompleted.test[APR.RouteQuestStepList.outdoor.label] = true
browser:Refresh(true)
visible(false, true) -- The dungeon choice remains available through Leveling.
APRZoneCompleted.test = {}
browser:Refresh(true)
visible(true)

-- Retail keeps its own supported row at the cap without importing Forever.
version, APR.MaxLevel, APR.Level = APR.GAME_VERSIONS.Retail, 90, 90
browser:Refresh(true)
assert(#browser.prefabs == 3 and browser.prefabPanel:IsShown())
assert(buttons.speedrun:IsShown() and buttons.leveling:IsShown() and buttons.all_quests:IsShown())
assert(not buttons.dungeons:IsShown() and not buttons.leveling:IsEnabled())
assert(APRCustomPath.test == path and APRData.test.outdoor == 7 and updates == 0)

-- Internal/temporary/absent declarations cannot fabricate client support.
APR.RouteQuestStepList.otherClient.hiddenFromSelection = true
browser:Refresh(true)
assert(#browser.prefabs == 0 and not browser.prefabPanel:IsShown())
APR.RouteQuestStepList.otherClient.hiddenFromSelection = nil
APR.RouteQuestStepList.otherClient.temporary = true
browser:Refresh(true)
assert(#browser.prefabs == 0)
APR.RouteQuestStepList = {}
browser:Refresh(true)
assert(#browser.prefabs == 0 and not browser.prefabPanel:IsShown() and browser.filterPanel.point[5] == 0)
print(
    "Prefab buttons: visible at cap and before entry, live enablement, progress/class/client isolation, stale refusal and stable layout passed"
)
