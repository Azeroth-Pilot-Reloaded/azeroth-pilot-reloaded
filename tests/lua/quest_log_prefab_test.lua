dofile("tests/lua/route_browser_test_env.lua")
dofile("APR-Core/features/questing/QuestLogSuggestions.lua")
local browser = APR.RouteBrowser
browser:Create()
local button
for _, candidate in ipairs(browser.prefabs) do
    if candidate.prefabKind == "quest_log" then button = candidate end
end
assert(button and button:IsShown() and button:IsEnabled(), "Journal prefab is visible independently of authored prefabs")
local opened = 0
function APR.QuestLogSuggestions:Open() opened = opened + 1 end
button.scripts.OnClick()
assert(opened == 1, "Journal prefab dispatches to its warning/search flow")
APR.RouteQuestStepList = {}
browser:RefreshPrefabs()
assert(#browser.prefabs == 1 and browser.prefabs[1] == button, "An empty catalog still allows an explicit journal search")
print("Journal prefab: visible, dispatches correctly and survives an empty catalog")
