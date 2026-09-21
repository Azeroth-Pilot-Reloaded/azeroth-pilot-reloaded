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

function CreateFrame()
    return { RegisterEvent = function() end, SetScript = function() end }
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

local function loadClient(game, locale, faction, withTaxi, existingAPI)
    FarstriderLibData_API = existingAPI
    FarstriderLib_API = nil
    FarstriderLibData = nil
    LibTaxiData_API = withTaxi and taxi or nil
    WOW_PROJECT_ID = game == "Standard" and WOW_PROJECT_MAINLINE or 99
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
                    assert(not portal, "Forever must not inherit the Retail portal graph")
                    assert(boat and boat.from.loc.mapId == 0 and boat.to.loc.mapId == 1,
                        "Vanilla must retain its native Menethil-Theramore transport")
                    assert(boat.condition() == (faction == "Alliance"))
                    local label = api.GetLocalizedString(boat.from.locaId)
                    assert(label == (locale == "frFR"
                        and "Prendre le bateau de la baie de Barardin vers l’île de Theramore"
                        or "Take the boat from Baradin Bay to Theramore Isle"))
                else
                    assert(portal and portal.from.loc.mapId == 870 and portal.to.loc.mapId == 0,
                        "Retail must retain its native Paw'don-Stormwind portal")
                    assert(oribosFlight, "Farstrider's explicitly defined flights must remain available")
                    local label = api.GetLocalizedString(portal.from.locaId)
                    assert(label:find(locale == "frFR" and "Hurlevent" or "Paw'don Village", 1, true),
                        "Retail must retain its native transport translations")
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

local existingAPI = { VERSION = 9999999999, WAYPOINTS = {} }
for _, game in ipairs({ "Standard", "Camelot" }) do
    local data, api = loadClient(game, "enUS", "Alliance", true, existingAPI)
    assert(api == existingAPI and next(api.WAYPOINTS) == nil)
    assert(not data.Areas, "A newer standalone data library must keep ownership")
end
print(string.format("Farstrider data: %d client/locale/faction/taxi combinations and standalone version guards passed",
    cases))
