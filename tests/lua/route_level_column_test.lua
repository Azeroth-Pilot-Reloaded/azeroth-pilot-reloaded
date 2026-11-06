-- Presentation ranges, numeric sorting and recycled widgets use invented routes only.
local env = dofile("tests/lua/route_browser_test_env.lua")
local catalog, browser = APR.RouteCatalog, APR.RouteBrowser
local E, V = APR.EXPANSIONS, APR.GAME_VERSIONS
function UnitLevel() return APR.Level end
local calls, native = {}, {}
C_Map = C_Map or {}
function C_Map.GetMapLevels(id)
    calls[id] = (calls[id] or 0) + 1
    local value = native[id]
    if value == "error" then error("Unavailable native map") end
    if value then return unpack(value) end
end
local function range(data, low, high, key)
    local minimum, maximum = catalog:GetLevelRange(key or "invented", data, {})
    assert(minimum == low and maximum == high,
        "Unexpected range: " .. tostring(minimum) .. "/" .. tostring(maximum))
    return catalog:FormatLevelRange(minimum, maximum)
end
assert(range({gameVersion = V.Forever, levelRange = {min = 3, max = 9}}, 3, 9) == "3-9")
assert(range({gameVersion = V.Forever, conditions = {MinLevel = 17}}, 17, nil) == "17+")
assert(range({gameVersion = V.Forever, conditions = {BeLvl = 9, MaxLevel = 12}}, 9, 9) == "9")
assert(range({gameVersion = V.Forever, conditions = {MaxLevel = 17}}, nil, 17) == "≤17")
for _, expansion in ipairs({E.Vanilla, E.Legion, E.Dragonflight, E.Custom, "Unknown extension"}) do
    assert(range({expansion = expansion}, 10, 70) == "10-70", "Other Retail routes use the requested 10-70 band")
end
assert(range({}, 10, 70) == "10-70")
assert(range({expansion = E.TheWarWithin}, 70, 80) == "70-80")
assert(range({expansion = E.Midnight}, 80, 90) == "80-90")
assert(range({expansion = E.Midnight, conditions = {Level = 90}}, 90, 90) == "90")
assert(range({expansion = E.Vanilla, prefab = {[APR.PREFAB_TYPES.StartingZone] = 1}}, nil, nil) == "",
    "A shared starting preset does not establish a tutorial's level range")
assert(range({levelRange = {min = 1, max = 10}, prefab = {[APR.PREFAB_TYPES.StartingZone] = 1}}, 1, 10) == "1-10")
native[107] = {8, 10}
assert(range({expansion = E.TheWarWithin, mapID = 107, prefab = {[APR.PREFAB_TYPES.StartingZone] = 1}}, 8, 10) == "8-10",
    "Hero and returning-player introductions use native levels instead of a universal starter range")
native[107] = {1, 20}
assert(range({expansion = E.Vanilla, mapID = 107, prefab = {[APR.PREFAB_TYPES.StartingZone] = 1}}, 1, 20) == "1-20")
assert(range({expansion = E.Custom, conditions = {MinLevel = "Missing profile"}}, 10, 70) == "10-70")
native[101] = {25, 48}
assert(range({expansion = E.Legion, mapID = 101, prefab = {[APR.PREFAB_TYPES.StartingZone] = 1},
    conditions = {Level = 30, MaxLevel = 46}}, 30, 46) == "30-46")
native[102] = {1, 80}
assert(range({expansion = E.Midnight, mapID = 102, conditions = {Level = 80}}, 80, 90) == "80-90",
    "A transit capital cannot narrow the expansion intro to one level")
native[103] = {80, 90}
assert(range({expansion = E.Midnight, mapID = 103, conditions = {Level = 90}}, 90, 90) == "90")
assert(range({expansion = E.Midnight, mapID = 103}, 80, 90, "unrelated") == "80-90")
-- Native zones can report narrower/later levels or scale beyond an expansion's
-- leveling band. The column must still apply the requested expansion ranges.
native[108], native[109] = {75, 90}, {90, 90}
native[110] = {10, 80}
assert(range({expansion = E.Legion, mapID = 110}, 10, 70) == "10-70")
assert(range({expansion = E.TheWarWithin, mapID = 108, conditions = {Level = 70}}, 70, 80) == "70-80")
assert(range({expansion = E.Midnight, mapID = 109, conditions = {Level = 80}}, 80, 90) == "80-90")
assert(range({expansion = E.Midnight, mapID = 109, conditions = {MinLevel = 85, MaxLevel = 95}}, 85, 90) == "85-90")
assert(range({expansion = E.TheWarWithin, mapID = 108, conditions = {Level = 60}}, 70, 80) == "70-80")
assert(range({expansion = E.Midnight, mapID = 109, conditions = {Level = 70}}, 80, 90) == "80-90")
assert(range({expansion = E.TheWarWithin, mapID = 108, conditions = {MaxLevel = 78}}, 70, 78) == "70-78")
assert(not calls[108] and not calls[109] and not calls[110], "Native map queries cannot override the requested expansion bands")
native[104] = {10, 70}
assert(range({expansion = E.Legion, conditions = {Level = 85}}, 85, nil, "104-invented") == "85+",
    "An authored requirement above a zone cap must not produce an inverted interval")
for _, value in ipairs({{0, 0}, {40, 20}, {10, math.huge}, {"10", 70}, "error"}) do
    native[105] = value
    assert(range({expansion = E.Legion, mapID = 105, prefab = {[APR.PREFAB_TYPES.StartingZone] = 1},
        conditions = {MinLevel = 14, MaxLevel = 21}}, 14, 21) == "14-21")
end
native[105] = nil
assert(range({expansion = E.TheWarWithin, mapID = 105}, 70, 80) == "70-80")
local mapAPI = C_Map.GetMapLevels
C_Map.GetMapLevels = nil
assert(range({expansion = E.TheWarWithin, mapID = 105}, 70, 80) == "70-80")
C_Map.GetMapLevels = mapAPI
-- Other clients use declaration/condition metadata and never call Retail's map API.
function APR:GetGameVersion() return V.Forever end
local before = calls[101]
assert(range({expansion = E.Forever, mapID = 101, conditions = {MinLevel = 7}}, 7, nil) == "7+")
assert(calls[101] == before)
function APR:GetGameVersion() return V.Retail end

function APR:GetGameVersion() return V.Forever end
APR.RouteQuestStepList = {
    small = {label = "Zeta", expansion = E.Forever, levelRange = {min = 3, max = 9}},
    equal = {label = "Alpha", expansion = E.Forever, levelRange = {min = 11, max = 20}},
    later = {label = "Beta", expansion = E.Forever, levelRange = {min = 11, max = 40}},
    open = {label = "Open", expansion = E.Forever, conditions = {MinLevel = 11}},
    last = {label = "Final", expansion = E.Forever, levelRange = {min = 40, max = 40}},
    unknown = {label = "Unknown", expansion = E.Custom},
    disabled = {label = "Unavailable early", expansion = E.Forever, levelRange = {min = 1, max = 2}, visibility = "disabled"},
}
local function keys(records)
    local result = {}
    for _, record in ipairs(records) do result[#result + 1] = record.key end
    return table.concat(result, ",")
end
local records = catalog:Build()
assert(keys(catalog:Filter(records, {sort = "level"})) == "small,equal,later,open,last,unknown,disabled")
assert(keys(catalog:Filter(records, {sort = "level", descending = true})) == "last,open,later,equal,small,unknown,disabled")
APR.RouteQuestStepList.tie = {label = "Alpha", expansion = E.Forever, levelRange = {min = 11, max = 20}}
assert(keys(catalog:Filter(catalog:Build(), {sort = "level"})) == "small,equal,tie,later,open,last,unknown,disabled")
APR.RouteQuestStepList.equal.legacyLabels = {"Old invented title (11-20)"}
assert(keys(catalog:Filter(catalog:Build(), {query = "old invented (11-20)"})) == "equal")
assert(keys(catalog:Filter(catalog:Build(), {query = "11-40"})) == "later")
-- Two records share one query; timeline changes and previously missing maps are retried on the next build.
function APR:GetGameVersion() return V.Retail end
APR.RouteQuestStepList.nativeA = {label = "Native A", expansion = E.Legion, mapID = 106, prefab = {[APR.PREFAB_TYPES.StartingZone] = 1}}
APR.RouteQuestStepList.nativeB = {label = "Native B", expansion = E.Legion, mapID = 106, prefab = {[APR.PREFAB_TYPES.StartingZone] = 1}}
native[106] = {10, 80}; calls[106] = 0
records = catalog:Build()
assert(calls[106] == 1 and #catalog:Filter(records, {query = "80"}) == 2)
native[106] = {10, 70}
records = catalog:Build()
assert(calls[106] == 2 and #catalog:Filter(records, {query = "80"}) == 0 and #catalog:Filter(records, {query = "native 70"}) == 2)
native[106] = nil; records = catalog:Build()
assert(calls[106] == 3 and #catalog:Filter(records, {query = "native 70"}) == 0)
native[106] = {15, 60}; records = catalog:Build()
assert(calls[106] == 4 and #catalog:Filter(records, {query = "15-60"}) == 2)
APR.RouteQuestStepList.equal.legacyLabels[1] = "Revised alias"
assert(#catalog:Filter(catalog:Build(), {query = "old invented"}) == 0)

browser:Show(); browser:SetScope("all")
assert(browser.headerLabels.level == LEVEL)
browser.headers.level.scripts.OnClick()
assert(browser.filters.sort == "level" and browser.headers.level.icon:IsShown() and not browser.filters.descending)
browser.headers.level.scripts.OnClick()
assert(browser.filters.descending)
for _, width in ipairs({880, 900, 1240, 1500, 1800}) do
    browser.frame:SetSize(width, 780); browser:Layout()
    local columns = APR.RouteBrowserRows:Columns(browser.scroll:GetWidth())
    assert(columns.name[2] >= 90 and columns.levels[2] == 72)
    for _, field in ipairs({"name", "levels", "category", "author", "status"}) do
        if columns[field][2] > 0 then
            assert(columns[field][1] + columns[field][2] <= columns.add[1], "Visible columns must fit before the add action")
            local header = browser.headers[field == "name" and "label" or field == "levels" and "level" or field]
            assert(header.point[4] == 10 + columns[field][1])
            for _, row in pairs(browser.list.active) do
                assert(row[field].point[4] == columns[field][1], "Recycled rows align with their header")
            end
        end
    end
end
local row = browser.list.active[1]
row.scripts.OnEnter(row)
assert(env.tooltip():find(LEVEL .. " " .. row.item.level, 1, true))
-- Rebinding an unknown range clears the old label on a reused row.
row.item = {key = "unknown", label = "Unknown", visibility = "visible", category = "", author = "APR", status = ""}
APR.RouteBrowserRows:Bind(row, row.item, 1, browser)
assert(row.levels:GetText() == "")
for _, width in ipairs({160, 200, 220, 300, 327, 328, 400}) do
    local columns = APR.RouteBrowserRows:Columns(width)
    assert(columns.levels[2] == 72 and columns.name[2] > 0)
    for _, field in ipairs({"name", "levels", "category", "author", "status"}) do
        assert(columns[field][1] + columns[field][2] <= columns.add[1], "Small tables cannot overlap the add action")
    end
    if width < 328 then assert(columns.category[2] == 0) end
end
-- A smaller UIParent lowers the native window's resize minimum. Keep levels,
-- favorite/add actions and the ordered-path controls usable at that minimum.
UIParent:SetSize(640, 480)
browser.frame:SetSize(600, 420); browser:Layout()
assert(browser.scroll:GetWidth() >= 220 and browser.pathScroll:GetWidth() >= 140)
local columns = APR.RouteBrowserRows:Columns(browser.scroll:GetWidth())
assert(columns.name[2] >= 90 and columns.levels[2] == 72)
browser.frame:SetSize(760, 520); browser:Layout()
assert(browser.scroll:GetWidth() >= 220)
print("Route levels: authored/native/fallback ranges, numeric sorting, live search, map budgets, client isolation, headers and recycled geometry passed")
