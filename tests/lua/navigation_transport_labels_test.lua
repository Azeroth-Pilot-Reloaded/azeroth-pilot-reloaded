-- One interior serves two cities. Display destinations describe arrival stops,
-- independently of the native map used for access, projection and progression.
for _, profile in ipairs({ "retail", "forever" }) do
    UNKNOWN = "Unresolved"
    local f = dofile("tests/lua/navigation_fixture.lua")
    f.profile = profile
    f.translations = setmetatable({ ENTER_TRAM = "Board the tram" }, { __index = function(_, key) return key end })
    local names = { [83101] = "Terminal Alpha", [83102] = "Terminal Beta" }
    local getMapInfo = C_Map.GetMapInfo
    C_Map.GetMapInfo = function(id)
        if id == 83001 then return nil end
        if id == 83101 or id == 83102 then return { mapID = id, name = names[id], parentMapID = 13, mapType = 3 } end
        return getMapInfo(id)
    end
    local stops = {
        { instanceID = 73, x = 0, y = 0, radius = 100, mapID = 83101 },
        { instanceID = 73, x = 0, y = 2000, radius = 100, mapID = 83102 },
    }
    local data = f:Load({
        config = {
            UnmappedAreas = { [83001] = { instanceID = 73, areaID = 84001 } },
            TransportDestinations = { tram = stops },
        },
        connections = {
            {
                id = "invented-tram",
                kind = "tram",
                bidirectional = true,
                seconds = 30,
                from = { instanceID = 73, uiMapID = 83001, x = 0, y = 2000 },
                to = { instanceID = 73, uiMapID = 83001, x = 0, y = 0 },
            },
        },
    })
    local library = LibStub("LibAPRNavigation-1.0")
    library.locales.enUS.ENTER_TRAM = "Ride towards %s"
    library.locales.enUS.RUN_WAYPOINT = "Follow the marker"
    dofile("APR-Core/utils/Utils.lua")
    APR.Debug = function() end
    dofile("APR-Core/utils/NavigationZones.lua")
    dofile("APR-Core/utils/StepUtils.lua")
    local step = { Tram = true, Zone = 83102, ZoneStepTrigger = { mapID = 83001, x = 10, y = 90, Range = 20 } }
    local text, kind = APR:GetTransportStepText(step)
    assert(
        text == "Ride towards Terminal Alpha" and kind == "Tram",
        "An authored journey names its arrival city before entering a mapless tram"
    )
    local target = data:NormalizeLocation({ uiMapID = 83001, x = 90, y = 10 })
    assert(
        data:GetInstruction("tram", nil, target) == "Ride towards Terminal Alpha",
        "Temporary navigation uses the same arrival city as the authored journey"
    )
    assert(
        target.uiMapID == 83001 and target.instanceID == 73 and target.x == 90 and target.y == 10,
        "A display destination cannot replace the interior's real location"
    )

    f.player, f.currentMap = { instanceID = 73, x = 0, y = 2000 }, 83001
    assert(
        APR:GetTransportStepText(step) == "Ride towards Terminal Alpha",
        "Entering at the departure platform cannot reverse the displayed destination"
    )
    step.ZoneStepTrigger.x, step.ZoneStepTrigger.y = 1990, 10
    assert(
        APR:GetTransportStepText(step) == "Ride towards Terminal Beta",
        "The reverse journey names the opposite city inside the same map"
    )
    local edges = data:BuildEdges({ start = target, walkSpeed = 7 })
    assert(
        #edges == 2
            and edges[1].instruction == "Ride towards Terminal Alpha"
            and edges[2].instruction == "Ride towards Terminal Beta",
        "Both directions of a declared transport resolve their own instructions"
    )

    assert(
        data:GetTransportDestinationName("tram", { instanceID = 73, x = 100, y = 0 }) == "Terminal Alpha",
        "A stop includes the exact radius boundary"
    )
    local name, interior = data:GetTransportDestinationName("tram", { instanceID = 73, x = 101, y = 0 })
    assert(name == nil and interior, "Nearby coordinates beyond a stop cannot guess a city")
    name, interior = data:GetTransportDestinationName("tram", { instanceID = 74, x = 0, y = 0 })
    assert(name == nil and not interior, "Identical coordinates in another world cannot select a stop")

    -- A city name may arrive after geography. Retry the native lookup instead
    -- of publishing Unknown or the shared interior's name as a destination.
    names[83101] = nil
    step.ZoneStepTrigger.x, step.ZoneStepTrigger.y = 10, 90
    assert(APR:GetTransportStepText(step) == "Board the tram")
    assert(data:GetInstruction("tram", nil, target) == "Follow the marker")
    names[83101] = "Terminal Alpha"
    assert(
        APR:GetTransportStepText(step) == "Ride towards Terminal Alpha",
        "Late client names recover without a cache reset"
    )
    local declarations = data:GetConfig().TransportDestinations.tram
    declarations[#declarations + 1] = { instanceID = 73, x = 0, y = 0, radius = 100, mapID = 83102 }
    assert(
        data:GetInstruction("tram", nil, target) == "Follow the marker",
        "Conflicting stop declarations cannot arbitrarily choose a city"
    )
    declarations[#declarations] = nil

    APR.NavigationData = nil
    assert(
        APR:GetTransportStepText(step) == "Board the tram",
        "A missing provider leaves a generic tram instruction without an Unknown suffix"
    )
end
print(
    "Transport labels: both terminal cities, shared interiors, authored/library parity, boundaries and late names passed"
)
