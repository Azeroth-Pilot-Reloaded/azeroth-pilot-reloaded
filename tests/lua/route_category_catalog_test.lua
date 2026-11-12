-- Synthetic localized catalogs: ordering is a client policy, never a shipped itinerary.
dofile("tests/lua/route_browser_test_env.lua")
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local catalog = APR.RouteCatalog
local version = APR.GAME_VERSIONS.Forever
function APR:GetGameVersion() return version end

local function checkLocale(labels)
    DUNGEONS, REPUTATION, RAIDS, LEGACY = labels.dungeon, labels.reputation, labels.raids, labels.legacy
    L.LEVELING_CAT, L.Professions, L.Miscellaneous = labels.leveling, labels.professions, labels.misc
    dofile("APR-Core/data/models/Enums.lua")
    for key in pairs(APR.CATEGORIES) do
        assert(type(APR.CATEGORY_SORT_NAMES[key]) == "string", "Every declared category needs an English sort name")
    end
    assert(APR.CATEGORIES.Reputation == labels.reputation)
    assert(APR.CATEGORIES.Raids == labels.raids)
    assert(APR.CATEGORIES.Legacy == labels.legacy)
    local categories = APR.CATEGORIES
    local expected = { categories.Leveling, categories.Dungeons, categories.Legacy,
        categories.Miscellaneous, categories.Professions, categories.Raids, categories.Reputation }
    APR.RouteQuestStepList = {}
    for index, category in ipairs(expected) do
        APR.RouteQuestStepList["invented" .. index] = {
            label = "Invented guide " .. index, category = category, expansion = APR.EXPANSIONS.Forever,
        }
    end
    APR.RouteQuestStepList.hidden = {
        label = "Hidden guide", category = categories.Toy, visibility = "hidden",
    }
    local records = catalog:Build()
    local options, seen = catalog:GetCategories(records, {})
    assert(#options == #expected + 1 and options[1].value == false)
    for index, category in ipairs(expected) do
        assert(options[index + 1].value == category and options[index + 1].label == category,
            "Forever sorts by English category names while displaying localized labels")
    end
    assert(not seen[categories.Toy] and not seen[categories.Pet], "Hidden and empty categories stay absent")
    local navigation = catalog:GetNavigation(records)
    assert(#navigation == #expected + 2 and navigation[2].heading)
    for index, category in ipairs(expected) do
        assert(navigation[index + 2].value == category and navigation[index + 2].count == 1)
    end
    local scoped = catalog:GetCategories(records, { expansion = categories.Professions })
    assert(#scoped == 2 and scoped[2].value == categories.Professions)
    local absent = catalog:GetCategories(records, { expansion = "Unpopulated scope" })
    assert(#absent == 1)

    version = APR.GAME_VERSIONS.Retail
    local retail = catalog:GetCategories(records, {})
    for index = 3, #retail do
        assert(retail[index - 1].label < retail[index].label, "Retail retains localized alphabetical ordering")
    end
    version = APR.GAME_VERSIONS.Forever
end

checkLocale({ dungeon = "Zulu", leveling = "Yankee", legacy = "Xray", misc = "Whiskey",
    professions = "Victor", raids = "Uniform", reputation = "Tango" })
checkLocale({ dungeon = "Alpha", leveling = "Bravo", legacy = "Charlie", misc = "Delta",
    professions = "Echo", raids = "Foxtrot", reputation = "Golf" })

-- Existing locale fallback remains available on clients without the optional native label.
LEGACY, L.LEGACY = nil, "Synthetic legacy fallback"
dofile("APR-Core/data/models/Enums.lua")
assert(APR.CATEGORIES.Legacy == "Synthetic legacy fallback")
APR.RouteQuestStepList = {}
local empty = catalog:GetNavigation(catalog:Build())
assert(#empty == 1 and empty[1].value == "all")
print("Category catalog: localized labels, stable Forever ordering, populated scopes and Retail order passed")
