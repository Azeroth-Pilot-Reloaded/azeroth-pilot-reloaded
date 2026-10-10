-- Exercise the actual client manifests and native data independently of LibTaxiData.
local function read(path)
    local file = assert(io.open(path, "r"))
    local contents = file:read("*a")
    file:close()
    return contents
end

local entry = assert(read("APR.toc"):match("\n(APR%-Core/libs/FarstriderLibData_%[Game%]%.xml)"))
local function loadXML(path, namespace, loaded)
    assert(not loaded[path], "Duplicate include: " .. path)
    loaded[path] = true
    local directory = path:match("^(.*)/")
    for kind, relative in read(path):gmatch("<(%a+)%s+file=[\"']([^\"']+)[\"']") do
        local child = directory .. "/" .. relative:gsub("\\", "/")
        if kind == "Include" then
            loadXML(child, namespace, loaded)
        else
            assert(kind == "Script")
            assert(not loaded[child], "Duplicate script: " .. child)
            loaded[child] = true
            assert(loadfile(child))("APR", namespace)
        end
    end
end

function debugstack() return "" end

local registeredEvents
function CreateFrame()
    return { RegisterEvent = function(_, event) registeredEvents[event] = true end, SetScript = function() end }
end

function UnitRace() return "Human", "Human", 1 end

function UnitLevel() return 60 end

WOW_PROJECT_MAINLINE = 1
WOW_PROJECT_MISTS_CLASSIC = 19

-- Expose the former bridge's required API, but fail if Farstrider consults it.
local function unexpectedTaxiCall()
    error("Farstrider must use its native graph, not infer connections from taxi nodes")
end
local taxi = {
    GetAllNodes = unexpectedTaxiCall,
    GetNodeName = unexpectedTaxiCall,
    IsNodeAvailable = unexpectedTaxiCall,
    IsNodeVisible = unexpectedTaxiCall,
}

local function loadClient(game, locale, faction, withTaxi, existingAPI, projectID)
    FarstriderLibData_API = existingAPI
    FarstriderLib_API = nil
    FarstriderLibData = nil
    LibTaxiData_API = withTaxi and taxi or nil
    registeredEvents = {}
    WOW_PROJECT_ID = projectID or WOW_PROJECT_MAINLINE
    function GetBuildInfo() return "version", "build", "date", game == "Camelot" and 16001 or 120105, "extra" end
    function GetExpansionLevel() return game == "Standard" and 11 or 0 end

    function GetLocale() return locale end

    function UnitFactionGroup() return faction end

    function GetBindLocation()
        if locale == "frFR" then
            return game == "Camelot" and "Colline des sentinelles" or "Colline des Sentinelles"
        end
        return "Sentinel Hill"
    end

    local namespace, loaded = {}, {}
    loadXML(entry:gsub("%[Game%]", game), namespace, loaded)
    assert(FarstriderLib_API.DATA.WAYPOINTS == FarstriderLibData_API.WAYPOINTS,
        "The navigation engine must use the published data")
    return namespace, FarstriderLibData_API, loaded
end

local cases = 0
for _, game in ipairs({ "Standard", "Camelot" }) do
    for _, locale in ipairs({ "enUS", "frFR" }) do
        for _, faction in ipairs({ "Alliance", "Horde" }) do
            local nativeWaypointCount
            for _, withTaxi in ipairs({ false, true }) do
                local data, api, loaded = loadClient(game, locale, faction, withTaxi)
                local vanilla = game == "Camelot"
                local flavor = vanilla and "Vanilla" or "Standard"
                local otherFlavor = vanilla and "Standard" or "Vanilla"
                assert(loaded["APR-Core/libs/FarstriderLibData/Areas/" .. flavor .. "/FarstriderLibData_Areas.lua"])
                assert(not loaded
                    ["APR-Core/libs/FarstriderLibData/Areas/" .. otherFlavor .. "/FarstriderLibData_Areas.lua"])
                assert(loaded
                    ["APR-Core/libs/FarstriderLibData/Waypoints/" .. flavor .. "/FarstriderLibData_Waypoints.lua"])
                assert(not loaded
                    ["APR-Core/libs/FarstriderLibData/Waypoints/" .. otherFlavor .. "/FarstriderLibData_Waypoints.lua"])
                assert(api.IsBindLocationSupported())
                local binding = data.Util.GetBindingLocation()
                assert(binding.mapId == 0 and binding.isUI == false)
                local expectedX = vanilla and -10628.889648438 or -10551.900390625
                assert(math.abs(binding.pos.x - expectedX) < 0.001,
                    "Hearthstone must resolve to the client's Sentinel Hill")

                local boat, portal, oribosFlight, flights = nil, nil, nil, 0
                for _, waypoint in ipairs(api.WAYPOINTS) do
                    if waypoint.id == 44 then boat = waypoint end
                    if waypoint.id == 4 then portal = waypoint end
                    if waypoint.from.locaId == 1001 and waypoint.from.loc.mapId == 0 then
                        flights = flights + 1
                    end
                    if waypoint.from.locaId == 1001 and waypoint.from.loc.mapId == 2222 then
                        oribosFlight = waypoint
                    end
                end
                if vanilla then
                    assert(not registeredEvents.PLAYER_HOUSE_LIST_UPDATED,
                        "Forever must not subscribe to Retail housing events")
                    assert(not portal, "Forever must not inherit the Retail portal graph")
                    assert(boat and boat.from.loc.mapId == 1437 and boat.to.loc.mapId == 1445
                        and boat.from.loc.isUI and boat.to.loc.isUI,
                        "Forever must use the measured Menethil-Theramore piers")
                    assert(boat.condition() == (faction == "Alliance"))
                else
                    assert(portal and portal.from.loc.mapId == 870 and portal.to.loc.mapId == 0,
                        "Retail must retain its native Paw'don-Stormwind portal")
                    assert(oribosFlight, "Farstrider's explicitly defined flights must remain available")
                end
                assert(flights == 0, "No inferred Eastern Kingdoms taxi flights should be added")
                if withTaxi then
                    assert(#api.WAYPOINTS == nativeWaypointCount,
                        "Installing LibTaxiData must not change Farstrider's graph")
                else
                    nativeWaypointCount = #api.WAYPOINTS
                end
                cases = cases + 1
            end
        end
    end
end

-- The world data must be independent of Forever sharing Retail's project ID.
C_Map = { GetAreaInfo = function(id) return tostring(id) end }
for _, faction in ipairs({ "Alliance", "Horde" }) do
    local expectedCount
    for _, projectID in ipairs({ WOW_PROJECT_MAINLINE, 99 }) do
        local _, api = loadClient("Camelot", "enUS", faction, false, nil, projectID)
        if expectedCount then assert(#api.WAYPOINTS == expectedCount) end
        expectedCount = #api.WAYPOINTS
        local auberdine, undercity = false, false
        local zeppelins, loopLegs, seenPorts = 0, 0, {}
        local skyborneShip = false
        for _, waypoint in ipairs(api.WAYPOINTS) do
            for _, endpoint in ipairs({ waypoint.from, waypoint.to }) do
                local loc = endpoint.loc
                if loc then
                    assert(loc.mapId ~= 530 and loc.mapId ~= 571 and loc.mapId ~= 2222,
                        "Forever must not inherit expansion continent connections")
                end
            end
            if waypoint.from.locaId == 1003 or waypoint.from.locaId == 1004 then
                assert(waypoint.from.loc.isUI and waypoint.to.loc.isUI,
                    "Forever transports must not retain legacy world-coordinate platforms")
                assert(not waypoint.condition or waypoint.condition() or waypoint.id == 44,
                    "Transports from the other faction must not enter the graph")
                for _, endpoint in ipairs({ waypoint.from, waypoint.to }) do
                    local loc = endpoint.loc
                    if endpoint.locaId == 1004 then
                        local key = string.format("%d:%.4f:%.4f", loc.mapId, loc.pos.x, loc.pos.y)
                        assert(not seenPorts[key], "Each zeppelin leg must have its own boarding platform")
                        seenPorts[key] = true
                    end
                end
                if waypoint.from.locaId == 1004 then zeppelins = zeppelins + 1 end
                local fromMap, toMap = waypoint.from.loc.mapId, waypoint.to.loc.mapId
                local loopMaps = { [1439] = true, [1437] = true, [1424] = true }
                if loopMaps[fromMap] and loopMaps[toMap] then
                    loopLegs = loopLegs + 1
                    assert(not waypoint.bidirectional, "The three-stop ship must retain its directed legs")
                    if fromMap == 1439 and toMap == 1437 then
                        assert(waypoint.cost == 293)
                    elseif fromMap == 1437 and toMap == 1439 then
                        assert(waypoint.cost == 498,
                            "Menethil to Auberdine must include the stop at Southshore")
                    end
                end
                if fromMap == 2521 then
                    skyborneShip = true
                    assert(toMap == (faction == "Horde" and 1412 or 1416),
                        "Skyborne ships must lead to the faction's actual destination")
                end
                local args = waypoint.from.locaArgs()
                if args[1] == "150" and args[2] == "442" then auberdine = true end
                if args[1] == "1497" and args[2] == "1637" then
                    undercity = true
                    assert(fromMap == 1420 and toMap == 1411 and waypoint.bidirectional)
                    assert(waypoint.to.loc.pos.x == 0.5080 and waypoint.to.loc.pos.y == 0.1370,
                        "Undercity's zeppelin must board at the Durotar platform, not inside Orgrimmar")
                end
                assert(args[2] ~= "3981" and args[2] ~= "3537" and args[2] ~= "495"
                    and args[2] ~= "3574" and args[2] ~= "4152" and args[2] ~= "3988",
                    "Forever must not inherit TBC/Wrath boats or zeppelins")
            end
        end
        assert(auberdine == (faction == "Alliance"))
        assert(undercity == (faction == "Horde"))
        assert(zeppelins == (faction == "Horde" and 3 or 0))
        assert(loopLegs == (faction == "Alliance" and 6 or 0))
        assert(skyborneShip)
    end
end

-- Render transport instructions with unavailable map/area APIs, including locales whose L table
-- returns missing keys verbatim. Neither English dock literals nor Area_/ForeverPort_ keys
-- should reach the displayed instructions.
C_Map = { GetAreaInfo = function() return nil end }
local undercityNames = {
    enUS = "Undercity", frFR = "Fossoyeuse", deDE = "Unterstadt",
    ruRU = "Подгород", zhCN = "幽暗城", zhTW = "幽暗城",
}
for locale, undercityName in pairs(undercityNames) do
    for _, faction in ipairs({ "Alliance", "Horde" }) do
        local _, api = loadClient("Camelot", locale, faction, false)
        local renderedUndercity, renderedDalaran = false, false
        for _, waypoint in ipairs(api.WAYPOINTS) do
            if waypoint.from.locaId == 1003 or waypoint.from.locaId == 1004 then
                for _, endpoint in ipairs({ waypoint.from, waypoint.to }) do
                    local args = endpoint.locaArgs()
                    assert(type(args[1]) == "string" and type(args[2]) == "string")
                    local message = string.format(api.GetLocalizedString(endpoint.locaId), unpack(args))
                    assert(not message:find("ForeverPort_", 1, true) and not message:find("Area_", 1, true))
                    assert(not message:find("?", 1, true), "Translated names must retain their Unicode characters")
                    if endpoint.locaId == 1004 and endpoint.loc.mapId == 1420
                        and waypoint.to.loc.mapId == 1411 then
                        renderedUndercity = true
                        assert(args[1] == undercityName)
                        if locale == "frFR" then
                            assert(message == "Prenez le zeppelin de Fossoyeuse vers Orgrimmar")
                        end
                    end
                    if endpoint.loc.mapId == 1416 then
                        renderedDalaran = true
                        assert(args[1] == rawget(FarstriderLibData.L, "ForeverPort_Dalaran"),
                            "Dalaran's dock must display its localized name, not Alterac Mountains")
                    end
                end
            end
        end
        assert(renderedUndercity == (faction == "Horde"))
        assert(renderedDalaran == (faction == "Alliance"))
    end
end

-- Prefer the client's localized map names at display time, even for ports with an area ID
-- or a translated fallback. This also covers locales beyond the library's translations.
local mapNames = { [1411] = "Durotar", [1420] = "Clairières de Tirisfal" }
C_Map = {
    GetMapInfo = function(id) return { name = mapNames[id] or "Carte " .. id } end,
    GetAreaInfo = function() error("Map names must take precedence over area names") end,
}
for _, faction in ipairs({ "Alliance", "Horde" }) do
    local _, api = loadClient("Camelot", "frFR", faction, false)
    for _, waypoint in ipairs(api.WAYPOINTS) do
        if waypoint.from.locaId == 1003 or waypoint.from.locaId == 1004 then
            for _, endpoint in ipairs({ waypoint.from, waypoint.to }) do
                local other = endpoint == waypoint.from and waypoint.to or waypoint.from
                local args = endpoint.locaArgs()
                assert(args[1] == C_Map.GetMapInfo(endpoint.loc.mapId).name)
                assert(args[2] == C_Map.GetMapInfo(other.loc.mapId).name)
                if endpoint.loc.mapId == 1411 and other.loc.mapId == 1420 then
                    assert(string.format(api.GetLocalizedString(endpoint.locaId), unpack(args))
                        == "Prenez le zeppelin de Durotar vers Clairières de Tirisfal")
                end
            end
        end
    end
end

-- Classic clients must keep their own expansion's transport locations, even though Forever
-- starts from Classic-era maps. In particular, Cata+ still boards inside Orgrimmar.
local _, classicAPI = loadClient("Standard", "enUS", "Horde", false, nil, 99)
local classicUndercity = false
for _, waypoint in ipairs(classicAPI.WAYPOINTS) do
    if waypoint.from.locaId == 1004 and waypoint.from.loc.mapId == 0 and waypoint.to.loc.mapId == 1 then
        classicUndercity = true
        assert(not waypoint.to.loc.isUI and waypoint.to.loc.pos.y == -4389.0400390625,
            "Forever transport overrides must not replace Cata+ Classic platforms")
    end
end
assert(classicUndercity)

local existingAPI = { VERSION = 9999999999, WAYPOINTS = {} }
for _, game in ipairs({ "Standard", "Camelot" }) do
    local data, api = loadClient(game, "enUS", "Alliance", true, existingAPI)
    assert(api == existingAPI and next(api.WAYPOINTS) == nil)
    assert(not data.Areas, "A newer standalone data library must keep ownership")
end
print(string.format("Farstrider data: %d client/locale/faction/taxi combinations and standalone version guards passed",
    cases))
