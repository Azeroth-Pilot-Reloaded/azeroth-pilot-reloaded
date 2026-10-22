local fixture = dofile("tests/lua/navigation_fixture.lua")
local localeKeys = {
    RUN_WAYPOINT = "Run to the waypoint", USE_FLIGHTPATH = "Use Flightpath to %s",
    USE_PORTAL_TO = "Use Portal to %s", USE_BOAT = "Use Boat to %s",
    USE_ZEPPELIN_TO = "Use Zeppelin to %s", ENTER_TRAM = "Enter the Deeprun Tram",
    USE_ITEM = "Use Item: %s", USE_SPELL = "Use the spell: %s",
}
UNKNOWN = "Client unknown"
for _, locale in ipairs({ "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW", "enGB", "unknown" }) do
    fixture.locale, fixture.translations = locale, {}
    for key in pairs(localeKeys) do fixture.translations[key] = "Unrelated APR text" end
    local data = fixture:Load()
    local library = LibStub("LibAPRNavigation-1.0")
    local strings = library.locales[locale] or library.locales.enUS
    for key, english in pairs(library.locales.enUS) do
        assert(type(strings[key]) == "string" and strings[key] ~= "", locale .. ": " .. key)
        local _, expected = english:gsub("%%s", "")
        local _, actual = strings[key]:gsub("%%s", "")
        assert(expected == actual, "Every translation preserves format parameters: " .. locale .. ": " .. key)
        assert(data:GetText(key) == strings[key], "Library text must not read APR translations: " .. key)
        if locale == "frFR" then assert(not strings[key]:find("’", 1, true) and not strings[key]:find("Consultez", 1, true)) end
    end
    local env = APR.NavigationAdapter.environment
    assert(env.getItemName(123) == data:GetText("UNKNOWN") and env.getSpellName(123) == data:GetText("UNKNOWN"))
    assert(data:GetDisplayMapName({ uiMapID = 8000 }) == "Map 8000")
    assert(data:GetDisplayMapName({ uiMapID = 8000, areaID = 442 }) == "Area 442")
    local instruction = data:GetInstruction("spell", { type = "spell", data = 123 }, { uiMapID = 8000 })
    assert(instruction == data:GetText("USE_SPELL"):format(data:GetText("UNKNOWN")) .. " (Map 8000)")
    PORTAL = "Client portal"
    assert(data:GetText("USE_PORTAL_TO", "PORTAL") == strings.USE_PORTAL_TO,
        "Client nouns cannot replace the library's full instruction")
    library:RegisterData("locale-test", "synthetic", { connections = { { id = "test", kind = "portal", seconds = 10,
        from = { space = "map", uiMapID = 8000, x = 0.1, y = 0.1, name = "Stored translated city" },
        to = { space = "map", uiMapID = 8001, x = 0.2, y = 0.2, name = "Stored translated city" } } } })
    local synthetic = library:New({ profile = "locale-test", environment = env })
    local edges = synthetic:BuildEdges({})
    assert(#edges == 1 and edges[1].instruction:find("Map 8001", 1, true))
    assert(not edges[1].instruction:find("Stored translated", 1, true))
end
local data = fixture:Load()
fixture.bindName = "Live inn name"
data:GetBindings()[999999] = { space = "world", instanceID = 0, uiMapID = 2395, x = 999, y = 888 }
local areaInfo = C_Map.GetAreaInfo
C_Map.GetAreaInfo = function(id) return id == 999999 and fixture.bindName or areaInfo(id) end
assert(data:GetBindPosition().x == 999, "Live localized area names locate the bind without translated aliases")
data:GetCharacterSettings().bindLocation = { name = fixture.bindName,
    location = { space = "world", instanceID = 0, uiMapID = 2395, x = 777, y = 666 } }
assert(data:GetBindPosition().x == 777, "Observed bindings take precedence over coarse area coordinates")
C_Map.GetAreaInfo = areaInfo
print("Navigation localization: 11 complete library-owned translations, client names, exact docks, observed/API binds and no display-zone tables passed")
