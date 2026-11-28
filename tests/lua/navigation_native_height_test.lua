local f = dofile("tests/lua/navigation_fixture.lua")
f:Load({})
dofile("APR-Core/utils/NavigationZones.lua")
APR.GAME_VERSIONS = {Forever = "forever", Retail = "retail"}
local profile = "forever"
function APR:GetGameVersion() return profile end
f.player = {x = 40, y = 80, z = 0, instanceID = 1, uiMapID = 100}
local position = APR:GetNavigationPlayerContext()
assert(position.coordinatesAvailable and position.x == 40 and position.y == 80)
assert(position.z == nil, "Forever's native placeholder zero is unknown height, never sea level")
f.player.z = -12
assert(APR:GetNavigationPlayerContext().z == -12, "A real nonzero height must remain available")
f.player.z = 27
assert(APR:GetNavigationPlayerContext().z == 27)
f.player.z, profile = 0, "retail"
assert(APR:GetNavigationPlayerContext().z == 0, "Retail's existing position contract remains unchanged")
print("Native height: Forever placeholder, genuine signed heights and unchanged Retail passed")
