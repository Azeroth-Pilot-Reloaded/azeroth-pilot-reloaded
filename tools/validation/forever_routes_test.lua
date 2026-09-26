-- Validate the actual collection and client/character visibility without loading source addons.
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
function UnitLevel() return 60 end
function tContains(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
C_Map = { GetBestMapForUnit = function() return 1411 end }
APR = { RouteQuestStepList = {}, interfaceVersion = 16001, Race = "Orc", ClassId = 1,
    ClassName = "WARRIOR", Faction = "Horde", worldCoordinateConverter = {} }
function APR:IsDelveRoute() return false end
function APR:NewModule() return {} end
dofile("APR-Core/features/navigation/WorldCoordinateConverter.lua")
local conversions = 0
function APR.worldCoordinateConverter:ConvertMapCoordinate(mapID, x, y)
    assert(mapID > 0 and x >= 0 and x <= 100 and y >= 0 and y <= 100)
    conversions = conversions + 1
    return { x = x, y = y }
end
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/data/models/Classes.lua")
dofile("APR-Core/utils/PlayerUtils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/utils/RouteManager.lua")
local handle = assert(io.open("Routes/Forever/RouteList.xml", "r"))
local manifest = handle:read("*a")
handle:close()
local files, count, steps, seen, manual, declarations = {}, 0, 0, {}, 0, {}
for path in manifest:gmatch('file="([^"]+)"') do
    assert(not files[path], "Duplicate manifest entry")
    files[path] = true
    local source = assert(io.open(path, "r"))
    local content = source:read("*a")
    source:close()
    local entries = 0
    for key in content:gmatch('APR%.RouteQuestStepList%["([^"]+)"%]%s*=') do
        assert(not declarations[key], "Duplicate route registration: " .. key)
        declarations[key] = path
        entries = entries + 1
    end
    assert(entries > 0, "Empty zone file: " .. path)
    dofile(path)
    count = count + 1
end
local function validateFilters(step)
    if step.AnyOf then
        for _, alternative in ipairs(step.AnyOf) do
            assert(not alternative.PickUp and not alternative.Done and not alternative.Qpart,
                "Progression must not be buried in conditions")
            validateFilters(alternative)
        end
    end
end
    for key, route in pairs(APR.RouteQuestStepList) do
    assert(not seen[key] and route.gameVersion == "forever" and route.expansion == APR.EXPANSIONS.Forever)
    seen[key] = true
    assert(#route.steps > 1 and route.steps[#route.steps].RouteCompleted)
    if route.prefab then
        for _, entry in pairs(route.prefab) do
            assert(type(entry) ~= "table" or not entry.conditions,
                "Prefab filters must be handled by the route: " .. key)
        end
        if key:match("^Forever%-1%-") then
            assert(route.prefab[APR.PREFAB_TYPES.StartingZone]
                and not route.prefab[APR.PREFAB_TYPES.Leveling]
                and not route.prefab[APR.PREFAB_TYPES.Speedrun],
                "Level 1 guides with prefabs must use StartingZone: " .. key)
        end
    end
    for index, step in ipairs(route.steps) do
        assert(step._index == index)
        for _, itemID in ipairs(step.DestroyItems and step.DestroyItems.items or {}) do
            assert(itemID ~= 6948, key .. ': always keep the Hearthstone')
        end
        for field in pairs(step) do
            assert(not field:match('^ExtraLineText'), key .. ': instructions must use Note')
        end
        for _, field in ipairs({ "UseItem", "UseSpell" }) do
            if step[field] then
                local questID = step[field].questID
                assert(type(questID) == "number" and questID > 0 and questID % 1 == 0,
                    key .. ': ' .. field .. ' requires a questID')
            end
        end
        for _, field in ipairs({ "Button", "SpellButton" }) do
            for questKey in pairs(step[field] or {}) do
                local value = tostring(questKey)
                assert(value:match('^[1-9]%d*$') or value:match('^[1-9]%d*%-[1-9]%d*$'),
                    key .. ': invalid ' .. field .. ' quest/objective key: ' .. value)
            end
        end
        for _, field in ipairs({ "Waypoint", "SetHS", "UseHS", "UseFlightPath" }) do
            if step[field] ~= nil then
                assert(type(step[field]) == "number" and step[field] > 0 and step[field] % 1 == 0,
                    key .. ": " .. field .. " must contain a quest ID")
            end
        end
        if step.UseFlightPath then
            assert(type(step.NodeID) == "number" and step.NodeID > 0, key .. ": missing verified flight node")
        end
        if step.Emote then
            assert(type(step.Emote) == "table" and type(step.Emote.emote) == "string"
                and type(step.Emote.npcID) == "number", key .. ": invalid emote shape")
        end
        validateFilters(step)
        steps = steps + 1
        if step.Note then manual = manual + 1 end
    end
    for _, entry in ipairs(route.nextRoute or {}) do
        local target = type(entry) == "table" and entry.route or entry
        assert(APR.RouteQuestStepList[target], "Missing follow-up: " .. target)
        assert(declarations[target] == declarations[key], "Follow-up leaves its race file: " .. target)
    end
    for _, group in ipairs(route.parallelSteps or {}) do
        for _, step in ipairs(group.steps) do
            assert(step.EquipItem, key .. ': only equipment reminders belong in parallel steps')
        end
    end
    if route.conditions.Race ~= "Orc" then
        assert(APR:GetRouteVisibility(key) == "hidden", "Ineligible characters must not see this guide")
    end
    APR.interfaceVersion = 120105
    assert(APR:GetRouteVisibility(key) == "hidden", "Retail must never expose Forever routes")
    APR.interfaceVersion = 16001
end
local raceFiles = {
    Dwarf = "Forever_Alliance_Dwarf.lua", Gnome = "Forever_Alliance_Gnome.lua",
    Human = "Forever_Alliance_Human.lua", NightElf = "Forever_Alliance_NightElf.lua",
    Orc = "Forever_Horde_Orc.lua", Troll = "Forever_Horde_Troll.lua",
    Scourge = "Forever_Horde_Scourge.lua", Tauren = "Forever_Horde_Tauren.lua",
    Skyborne = "Forever_Skyborne.lua",
}
assert(count == 9 and conversions > 0, "Exactly one file per Forever race is required")
for race, filename in pairs(raceFiles) do
    assert(files["Routes/Forever/" .. filename], "Missing race file: " .. race)
end
for key, route in pairs(APR.RouteQuestStepList) do
    local filename = raceFiles[route.conditions.Race]
    assert(filename and declarations[key] == "Routes/Forever/" .. filename, "Wrong race registration: " .. key)
end
local registered = 0
for key in pairs(seen) do
    assert(declarations[key], "Route not declared by the manifest")
    registered = registered + 1
end
for key in pairs(declarations) do assert(seen[key], "Declared route was not registered") end
-- The introductory boar farm uses class-specific resale goals, not cash filters/travel steps.
for _, race in ipairs({ "Orc", "Troll" }) do
    local route = APR.RouteQuestStepList["Forever-Starting-Zone-" .. race]
    local targets = { [10] = { "SHAMAN", "WARRIOR" }, [35] = { "WARLOCK" }, [60] = { "MAGE" } }
    if race == "Troll" then targets[50] = { "PRIEST" } end
    local count = race == "Troll" and 4 or 3
    for index = 2, count + 1 do
        local step = route.steps[index]
        assert(step.LootMoney and not step.Money and not step.Waypoint and not step.NonSkippableWaypoint)
        local target = step.LootMoney.copper
        local expected = assert(targets[target], "Duplicate or unexpected class copper target")
        local classes = type(step.Class) == "table" and step.Class or { step.Class }
        assert(#classes == #expected)
        for _, class in ipairs(expected) do assert(tContains(classes, class)) end
        targets[target] = nil
        local x, y = -4281.07, -720.15
        if target == 10 then x, y = -4299.05, -494.9 end
        assert(step.Coord.x == x and step.Coord.y == y and step.Zone == 1411 and step.Range == 30)
        assert(tContains(step.LootMoney.equippedSlots, 5) and not tContains(step.LootMoney.equippedSlots, 16))
    end
    assert(not next(targets), "Missing class copper target")
end
local zephras = APR.RouteQuestStepList["Forever-Starting-Zone-Skyborne"]
assert(zephras and zephras.conditions.Race == "Skyborne" and not zephras.conditions.AnyOf)
local warriorTraining, farmingCircuit = false, false
for _, step in ipairs(zephras.steps) do
    if step.LearnSkill and step.LearnSkill.spellID == 6673 then
        assert(step.Class == "WARRIOR" and not step.AnyOf)
        warriorTraining = true
    end
    if step.Qpart and step.Qpart[92462] then
        assert(not step.CoordPath and not step.Waypoint)
        assert(math.abs(step.Coord.x - 44.825) < 0.00001 and math.abs(step.Coord.y - 26.86) < 0.00001)
        assert(step.Range == 30 and step.Fillers and step.Fillers[92461])
        farmingCircuit = true
    end
end
assert(warriorTraining and farmingCircuit)
APR.Race, APR.ClassName, APR.ClassId, APR.Faction = "Skyborne", "MAGE", 8, "Alliance"
assert(APR:GetRouteVisibility("Forever-Starting-Zone-Skyborne") == "visible")
APR.Faction = "Horde"
APR.ClassName, APR.ClassId = "SHAMAN", 7
assert(APR:GetRouteVisibility("Forever-Starting-Zone-Skyborne") == "visible")
print(string.format("Forever collection: %d routes in %d files, %d steps, %d map conversions; character/client visibility and links passed (%d Note steps)",
    registered, count, steps, conversions, manual))
