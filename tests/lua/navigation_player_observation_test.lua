-- The host must distinguish an unknown height from an observed sea-level zero.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local opaque, inaccessible = {}, {}
function issecretvalue(value) return rawequal(value, opaque) end
for _, profile in ipairs({ "retail", "forever" }) do
    fixture.profile, fixture.currentMap = profile, 501
    fixture:Load({ config = { WorldInstanceOverrides = { [70] = 7 } }, connections = {} })
    function APR:CanAccessValue(value) return not rawequal(value, inaccessible) end
    dofile("APR-Core/utils/NavigationZones.lua")
    fixture.player = { x = 10, y = 20, instanceID = 70 }
    local position = APR:GetNavigationPlayerPosition()
    assert(position and position.z == nil and position.instanceID == 7,
        "Missing height must remain unknown while valid XY/world observations remain usable")
    local nativeIndoors = IsIndoors
    for _, indoors in ipairs({ true, false }) do
        IsIndoors = function() return indoors end
        assert(APR:GetNavigationPlayerPosition().indoors == indoors, "Finite native indoor state is retained for surface provenance")
    end
    for _, unavailable in ipairs({ opaque, inaccessible, "unknown" }) do
        IsIndoors = function() return unavailable end
        assert(APR:GetNavigationPlayerPosition().indoors == nil, "Unknown or protected indoor state cannot invent a surface kind")
    end
    IsIndoors = function() error("unavailable") end
    assert(APR:GetNavigationPlayerPosition().indoors == nil)
    IsIndoors = nil
    assert(APR:GetNavigationPlayerPosition().indoors == nil)
    IsIndoors = nativeIndoors
    local nativeFlying = IsFlying
    IsFlying = function() return true end
    assert(APR:GetNavigationPlayerPosition().airborne == true,"A positive airborne observation must survive the native provider")
    IsFlying = function() return opaque end
    assert(APR:GetNavigationPlayerPosition().airborne == nil,"Protected flight observations cannot become a positive airborne state")
    IsFlying = nativeFlying
    for _, height in ipairs({ 0, -12.5, 21 }) do
        fixture.player.z = height
        assert(APR:GetNavigationPlayerPosition().z == height, "Real finite heights, including zero, remain unchanged")
    end
    for _, height in ipairs({ math.huge, -math.huge, 0 / 0, "unknown", false, opaque, inaccessible }) do
        fixture.player.z = height
        assert(APR:GetNavigationPlayerPosition().z == nil,
            "Unavailable, nonfinite or protected height cannot select a navigation floor")
    end
    fixture.player.z = 0
    for _, field in ipairs({ "x", "y", "instanceID" }) do
        local original = fixture.player[field]
        for _, value in ipairs({ math.huge, 0 / 0, "unknown", opaque, inaccessible }) do
            fixture.player[field] = value
            assert(APR:GetNavigationPlayerPosition() == nil, "Invalid required observation must wait for valid native data")
        end
        fixture.player[field] = original
    end
    local nativePosition = UnitPosition
    UnitPosition = nil
    assert(APR:GetNavigationPlayerPosition() == nil, "Missing optional native APIs cannot raise a Lua error")
    UnitPosition = function() error("native observation temporarily unavailable") end
    assert(APR:GetNavigationPlayerPosition() == nil, "Unavailable native observations remain retryable")
    UnitPosition = nativePosition
    assert(APR:GetNavigationPlayerPosition().z == 0)
    local nativeMap = C_Map.GetBestMapForUnit
    for _, value in ipairs({ math.huge, "unknown", opaque, inaccessible }) do
        C_Map.GetBestMapForUnit = function() return value end
        assert(APR:GetNavigationPlayerPosition() == nil, "Protected or invalid map identity cannot become navigation input")
    end
    C_Map.GetBestMapForUnit = nativeMap
    assert(APR:GetNavigationPlayerPosition().uiMapID == 501)
    C_Map.GetBestMapForUnit = nil
    assert(APR:GetNavigationPlayerPosition() == nil)
    C_Map.GetBestMapForUnit = function() error("map observation unavailable") end
    assert(APR:GetNavigationPlayerPosition() == nil)
    C_Map.GetBestMapForUnit = nativeMap
end
print("Navigation observations: finite XY/world, unknown versus zero height, protected results and API recovery passed")
