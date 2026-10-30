local env = dofile("tests/lua/route_ui_test_env.lua")
WorldMapFrame, Minimap = env.widget(), env.widget()
function WorldMapFrame:GetCanvas() return self end
function WorldMapFrame:GetMapID() return 1 end
local worldPins, miniPins = {}, {}
local pins = {
    RemoveAllWorldMapIcons = function() worldPins = {} end,
    RemoveAllMinimapIcons = function() miniPins = {} end,
    AddWorldMapIconMap = function(_, _, pin) worldPins[#worldPins + 1] = pin end,
    AddMinimapIconMap = function(_, _, pin) miniPins[#miniPins + 1] = pin end,
}
local originalLibStub = LibStub
function LibStub(name, ...)
    if name == "HereBeDragons-Pins-2.0" then return pins end
    return originalLibStub(name, ...)
end
function APR:NewModule()
    return { messages = {}, RegisterMessage = function(self, message, callback) self.messages[message] = callback end }
end
C_Map = {GetBestMapForUnit = function() return 1 end, GetPlayerMapPosition = function() return {} end}
local steps = {}
for i = 1, 10000 do steps[i] = {Coord = {x = i, y = i}, id = i} end
APR.ActiveRoute, APR.PlayerID = "route", "player"
APRData = {player = {route = 4}}
APR.RouteQuestStepList = {route = steps}
local profile = APR.settings.profile
profile.enableAddon, profile.mapshowNextSteps, profile.minimapshowNextSteps = true, true, true
profile.mapshowNextStepsCount, profile.minimapshowNextStepsCount = 5, 2
function APR:CheckIsInRouteZone() return true end
function APR:GetPlayerParentMapID() return 1 end
function APR:GetRouteSteps() return steps end
function APR:GetPlayerMapPos() return 0.5, 0.5 end
local filters, coords = 0, 0
function APR:StepFilterQoL(step) filters = filters + 1; return step.id ~= 2 end
function APR:GetStepCoord(step)
    coords = coords + 1
    assert(step.id >= 4 and step.id <= 9, "Resolve coordinates only in the visible window")
    return step.Coord
end
dofile("APR-Core/features/navigation/Map.lua")
local createPin = APR.map.CreatePin
function APR.map:CreatePin() return {text = {SetText = function() end}, Hide = function() end, ClearAllPoints = function() end} end
APR.map:AddMapPins()
assert(filters == 9 and coords == 6, "A 10,000-step route must not trigger 10,000 coordinate/filter evaluations")
assert(#worldPins == 5 and #miniPins == 2)
assert(worldPins[1].stepIndex == 3 and worldPins[1].step.id == 4, "Filtered numbering stays ordered")
APR.map:AddMapPins()
assert(#worldPins == 5 and #miniPins == 2, "Refreshing retains the correct displayed counts")
print("Map pins: bounded coordinate work, ordered filtered numbering and display limits passed")
return { env = env, profile = profile, createPin = createPin,
    worldPins = function() return worldPins end, miniPins = function() return miniPins end }
