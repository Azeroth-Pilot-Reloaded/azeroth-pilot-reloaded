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
    assert(not route.parallelSteps or #route.parallelSteps == 0, key .. ': use fillers and Qpart checks')
    for _, entry in ipairs(route.nextRoute or {}) do
        local target = type(entry) == "table" and entry.route or entry
        assert(APR.RouteQuestStepList[target], "Missing follow-up: " .. target)
    end
    if route.conditions.Faction == "Alliance" or route.conditions.Class == 8 or route.conditions.Race == "Skyborne" then
        assert(APR:GetRouteVisibility(key) == "hidden", "Ineligible characters must not see this guide")
    end
    APR.interfaceVersion = 120105
    assert(APR:GetRouteVisibility(key) == "hidden", "Retail must never expose Forever routes")
    APR.interfaceVersion = 16001
end
if count == 0 then
    assert(next(declarations) == nil, "An empty Forever manifest must not register routes")
    print("Forever routes: empty client-specific manifest passed")
    return
end
assert(count > 0 and count < 69 and conversions > 0, "Routes must be grouped into zone files")
local registered = 0
for key in pairs(seen) do
    assert(declarations[key], "Route not declared by the manifest")
    registered = registered + 1
end
for key in pairs(declarations) do assert(seen[key], "Declared route was not registered") end
assert(registered == 73, "All independent routes in the current Forever sources must remain registered")
assert(count == 21 and files['Routes/Forever/Forever-Onyxia-Attunement.lua'])
assert(not files['Routes/Forever/Forever-Badlands.lua'] and not files['Routes/Forever/Forever-Burning-Steppes.lua'])
for _, suffix in ipairs({ 'A', 'H' }) do
    local key = 'Forever-Onyxia-Attunement-' .. suffix
    assert(declarations[key] == 'Routes/Forever/Forever-Onyxia-Attunement.lua')
    local route = APR.RouteQuestStepList[key]
    assert(not route.conditions.Race and not route.conditions.AnyOf)
    assert(route.conditions.Faction == (suffix == 'A' and 'Alliance' or 'Horde'))
    assert(route.mapID == (suffix == 'A' and 1428 or 1418))
end
local zephras = APR.RouteQuestStepList["Forever-1-14-Zephras-Isle"]
assert(zephras.conditions.Race == "Skyborne" and not zephras.conditions.AnyOf)
assert(not zephras.steps[1].AnyOf)
local warriorTraining, farmingCircuit = false, false
for _, step in ipairs(zephras.steps) do
    if step.LearnSkill and step.LearnSkill.spellID == 6673 then
        assert(step.Class == "WARRIOR" and not step.AnyOf)
        warriorTraining = true
    end
    if step.Qpart and step.Qpart[92462] then
        assert(not step.CoordPath and not step.ExtraLineText and not step.Waypoint)
        assert(math.abs(step.Coord.x - 44.825) < 0.00001 and math.abs(step.Coord.y - 26.86) < 0.00001)
        local points = { {44.23,26}, {45.24,25.9}, {46.06,25.33}, {46.77,27.83},
            {45.27,28.36}, {43.84,28.39}, {42.88,27.52} }
        for _, point in ipairs(points) do
            local dx, dy = point[1] - step.Coord.x, point[2] - step.Coord.y
            assert(math.sqrt(dx * dx + dy * dy) + 35 <= step.Range)
        end
        assert(step.Fillers and step.Fillers[92461])
        farmingCircuit = true
    end
end
assert(warriorTraining and farmingCircuit)
assert(APR.RouteQuestStepList["Forever-12-14-Silverpine-Forest"].conditions.Faction == "Horde")
assert(APR.RouteQuestStepList["Forever-10-12-Tirisfal"].conditions.Faction == "Horde")
APR.Race, APR.ClassName, APR.ClassId, APR.Faction = "Skyborne", "MAGE", 8, "Alliance"
assert(APR:GetRouteVisibility("Forever-1-14-Zephras-Isle") == "visible")
APR.Faction = "Horde"
assert(APR:GetRouteVisibility("Forever-1-14-Zephras-Isle") == "visible")
print(string.format("Forever collection: %d routes in %d files, %d steps, %d map conversions; character/client visibility and links passed (%d Note steps)",
    registered, count, steps, conversions, manual))
