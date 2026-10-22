-- Crossing a named subzone must not discard all static transport projections.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load()
dofile("APR-Core/utils/Utils.lua")
APR.Debug = function() end
local frames, originalCreateFrame = {}, CreateFrame
function CreateFrame(...)
    local frame = originalCreateFrame(...)
    frames[#frames + 1] = frame
    return frame
end
local artID = 100
C_Map.GetMapArtID = function() return artID end
dofile("APR-Core/utils/NavigationZones.lua")
local frame = frames[1]
local endpoint = { space = "map", uiMapID = 2395, x = 0.1, y = 0.2 }
local context = { playerPosition = { instanceID = 0, uiMapID = 2395, x = 1, y = 2 } }
local first = assert(data:ResolvePosition(endpoint, context))
local firstInfo = APR:GetMapInfoCached(2395)
APR:ResolvePlayerZoneContext()
for index = 1, 100 do
    frame.OnEvent(frame, index % 2 == 0 and "ZONE_CHANGED" or "ZONE_CHANGED_INDOORS")
end
assert(data:ResolvePosition(endpoint, context) == first,
    "A hundred ordinary subzone events retain the same normalized endpoint")
assert(APR.ZoneDetection.mapInfoCache[2395] == firstInfo,
    "Player context changes do not discard static map metadata")
assert(APR.ZoneDetection.playerContextCache.timestamp == 0,
    "The next access check must still read the current player zone")
assert(APR.navigationGeometryRevision == nil,
    "Ordinary notifications do not invalidate a plan's geometry revision")

artID = 101
frame.OnEvent(frame, "ZONE_CHANGED")
local phased = assert(data:ResolvePosition(endpoint, context))
assert(phased ~= first and APR.ZoneDetection.mapInfoCache[2395] == nil,
    "A changed map art invalidates cached geometry even when its map ID is unchanged")
assert(APR.navigationGeometryRevision == 1,
    "A phase change also invalidates a settled plan even if map and access IDs stayed equal")
frame.OnEvent(frame, "ZONE_CHANGED_NEW_AREA")
local afterTransition = assert(data:ResolvePosition(endpoint, context))
assert(afterTransition == phased,
    "Reentering a known map with unchanged art retains static projections")
assert(APR.navigationGeometryRevision == 1,
    "An unchanged map art does not invalidate the published route's geometry")

fixture.currentMap = 2393
frame.OnEvent(frame, "ZONE_CHANGED_NEW_AREA")
local firstVisit = assert(data:ResolvePosition(endpoint, context))
assert(firstVisit ~= afterTransition,
    "A first map visit still refreshes geometry before its art is known")
for index = 1, 100 do
    fixture.currentMap = index % 2 == 0 and 2393 or 2395
    frame.OnEvent(frame, "ZONE_CHANGED_NEW_AREA")
end
assert(data:ResolvePosition(endpoint, context) == firstVisit,
    "Repeated crossings between known maps reuse their static geometry")
assert(APR.navigationGeometryRevision == 2,
    "A hundred unchanged map crossings do not invalidate the whole graph")

artID = nil
frame.OnEvent(frame, "ZONE_CHANGED_NEW_AREA")
local unknownArt = assert(data:ResolvePosition(endpoint, context))
assert(unknownArt ~= firstVisit,
    "Clients without a readable map art retain conservative transition invalidation")
APR:InvalidatePlayerZoneCache()
assert(data:ResolvePosition(endpoint, context) ~= unknownArt,
    "Explicit refresh and world-loading callers retain full invalidation")
print("Navigation zone cache: subzone events and known map crossings retain geometry; phase/world changes refresh it")
