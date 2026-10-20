-- Load the shipped locale manifests: language ownership stays in the libraries.
local clientLocale
function GetLocale() return clientLocale end

local function loadLocales(directory, prefix, namespace)
    local file = assert(io.open(directory .. '/' .. prefix .. '_Locales.xml', 'r'))
    local manifest = file:read('*a')
    file:close()
    local count = 0
    for relative in manifest:gmatch('<Script%s+file="([^"]+)"') do
        count = count + 1
        if count == 1 then assert(relative == prefix .. '_Locale.enUS.lua', 'English must load first') end
        assert(loadfile(directory .. '/' .. relative))('APR', namespace)
    end
    assert(count == 11, 'Every supported locale must be shipped in the manifest')
end

local function copy(source)
    local result = {}
    for key, value in pairs(source) do result[key] = value end
    return result
end

local function signature(text)
    local types = {}
    for specifier in text:gmatch('%%([a-zA-Z])') do types[#types + 1] = specifier end
    return table.concat(types)
end

local function assertComplete(actual, english)
    local count, expected = 0, 0
    for key, text in pairs(english) do
        expected = expected + 1
        local translation = rawget(actual, key)
        assert(type(translation) == 'string' and translation ~= '', 'Missing translation: ' .. key)
        assert(signature(translation) == signature(text), 'Format arguments changed for ' .. key)
        local args = {}
        for _ in signature(text):gmatch('.') do args[#args + 1] = 'argument-' .. (#args + 1) end
        local formatted = string.format(translation, unpack(args))
        for _, value in ipairs(args) do assert(formatted:find(value, 1, true), 'Lost format argument') end
    end
    for key in pairs(actual) do
        count = count + 1
        assert(english[key], 'Unknown locale key: ' .. key)
    end
    assert(count == expected, 'Locale key sets must match')
end

local engineDirectory = 'APR-Core/libs/FarstriderLib/Locale'
local dataDirectory = 'APR-Core/libs/FarstriderLibData/Locale'
local english, englishData
for _, locale in ipairs({'enUS', 'deDE', 'esES', 'esMX', 'frFR', 'itIT', 'koKR', 'ptBR',
    'ruRU', 'zhCN', 'zhTW', 'enGB', 'xxXX'}) do
    clientLocale = locale
    FarstriderLibData_API = nil
    local engine = {Internal = true}
    loadLocales(engineDirectory, 'FarstriderLib', engine)
    assert(loadfile('APR-Core/libs/FarstriderLib/FarstriderLib~Data.lua'))('APR', engine)
    assert(loadfile('APR-Core/libs/FarstriderLib/FarstriderLib~Pathfinding.lua'))('APR', engine)
    local data = {Internal = true, WaypointL = {}, Waypoints = {}, Config = {}}
    loadLocales(dataDirectory, 'FarstriderLibData', data)
    if locale == 'enUS' then english, englishData = copy(engine.Locale), copy(data.L) end
    assertComplete(engine.Locale, english)
    assertComplete(data.L, englishData)
    if locale == 'enGB' or locale == 'xxXX' then
        assert(engine.Locale.Waypoint_1000 == english.Waypoint_1000, 'Unknown/English locales fall back to enUS')
    elseif locale ~= 'enUS' then
        assert(engine.Locale.Waypoint_1000 ~= english.Waypoint_1000, 'The selected locale must replace English')
        local engineValue, dataValue = engine.Locale.Waypoint_1000, data.L.ForeverPort_Gromgol
        engine.Locale.Waypoint_1000, data.L.ForeverPort_Gromgol = nil, nil
        assert(engine.Locale.Waypoint_1000 == english.Waypoint_1000, 'Missing engine keys fall back to English')
        assert(data.L.ForeverPort_Gromgol == englishData.ForeverPort_Gromgol, 'Missing data keys fall back to English')
        engine.Locale.Waypoint_1000, data.L.ForeverPort_Gromgol = engineValue, dataValue
    end

    for id = 1000, 1006 do
        assert(engine.Pathfinding:GetNodeLocaDirect(id) == data.L['Waypoint_' .. id],
            'Engine fallback and data translations must agree')
    end
    assert(engine.Pathfinding:GetNodeLocaDirect(nil) == engine.Locale['Unknown Location'],
        'Missing location IDs must not expose a hardcoded English diagnostic')
    FarstriderLibData_API = {WAYPOINTS = {true}}
    assert(engine.Pathfinding:GetNodeLocaDirect(1000) == data.L.Waypoint_1000,
        'A provider without a localization method uses the localized engine fallback')

    local itemName, spellName
    Item = {CreateFromItemID = function() return {GetItemName = function() return itemName end} end}
    Spell = {CreateFromSpellID = function() return {GetSpellName = function() return spellName end} end}
    assert(loadfile('APR-Core/libs/FarstriderLibData/FarstriderLibData~Util.lua'))('APR', data)
    assert(data.Util.GetItemNameSafe(1) == data.L['Unknown Item'], 'Uncached item names stay localized')
    assert(data.Util.GetSpellNameSafe(1) == data.L['Unknown Spell'], 'Uncached spell names stay localized')
    itemName, spellName = 'Client item name', 'Client spell name'
    assert(data.Util.GetItemNameSafe(1) == itemName and data.Util.GetSpellNameSafe(1) == spellName,
        'Client-provided names remain authoritative')

    data.WaypointL[1000], data.WaypointL[123] = 'Stale generic label', 'Custom transport label'
    assert(loadfile('APR-Core/libs/FarstriderLibData/FarstriderLibData~Finalizer.lua'))('APR', data)
    for id = 1000, 1006 do
        assert(engine.Pathfinding:GetNodeLocaDirect(id) == data.L['Waypoint_' .. id],
            'Reserved generic IDs follow the active locale, not stale waypoint labels')
    end
    assert(engine.Pathfinding:GetNodeLocaDirect(123) == 'Custom transport label', 'Keep named transport translations')
    assert(engine.Pathfinding:GetNodeLocaDirect(999999) == engine.Locale['Unknown Location'], 'Unknown labels stay localized')

    -- APR embeds both libraries in one addon namespace. Locale tables must not
    -- overwrite one another when their manifests run consecutively.
    local shared = {Internal = true}
    loadLocales(dataDirectory, 'FarstriderLibData', shared)
    local portLabels = shared.L
    loadLocales(engineDirectory, 'FarstriderLib', shared)
    assert(shared.L == portLabels and shared.Locale.Waypoint_1000 == shared.L.Waypoint_1000,
        'Embedding both libraries together preserves the data locale catalogue')
end

local inactive = {}
loadLocales(engineDirectory, 'FarstriderLib', inactive)
loadLocales(dataDirectory, 'FarstriderLibData', inactive)
assert(inactive.L == nil and inactive.Locale == nil, 'Inactive library copies must not install locale tables')
print('Farstrider locales: eleven shipped languages, English aliases/fallbacks, formatting, native data and missing API/name coverage passed')
