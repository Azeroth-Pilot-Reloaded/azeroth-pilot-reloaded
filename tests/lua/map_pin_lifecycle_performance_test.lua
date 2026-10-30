-- Authored marker pools follow visible slots, not every step ever displayed.
-- Bursts use the existing map animation while direct refreshes remain immediate.
local fixture = dofile("tests/lua/map_pin_performance_test.lua")
local env, profile, map = fixture.env, fixture.profile, APR.map
profile.mapshowNextStepsSize, profile.minimapshowNextStepsSize = 18, 18
profile.mapshowNextStepsColor, profile.minimapshowNextStepsColor = { 1, 1, 1 }, { 1, 1, 1 }
profile.showMiniMapLineColor, profile.showMapLineColor = { 1, 1, 1 }, { 1, 1, 1 }
profile.showMiniMapLineThickness, profile.showMapLineThickness = 2, 2
profile.showMiniMapLine, profile.showMapLine = false, false
map.pinlist, map.minimapPinlist = {}, {}
local created = 0
function map:CreatePin(...)
    created = created + 1
    return fixture.createPin(self, ...)
end
function APR:GetStepCoord(step) return step.Coord end
function APR:GetStepString(step) return "Instruction " .. step.id end
function APR:AddStepTooltipDetails() return false end
function APR:GetStepQuestIDs() return {} end
local tooltip
function APR:AddTooltipLine(_, text) tooltip = text end
function env.methods:SetOwner() end
local function count(values)
    local total = 0
    for _ in pairs(values) do total = total + 1 end
    return total
end
local event = map.eventFrame.scripts.OnEvent
event(nil, "QUEST_LOG_UPDATE")
assert(created == 7 and not map.pendingPinRefresh,
    "Before map initialization, event refreshes retain their immediate fallback")
for index = 4, 203 do
    APRData.player.route = index
    map:AddMapPins()
end
MAP_LIFECYCLE_PIN_ALLOCATIONS = created
assert(created == 7 and count(map.pinlist) == 5 and count(map.minimapPinlist) == 2,
    "Advancing 200 steps must retain only the configured five world and two minimap markers")
local first = fixture.worldPins()[1]
assert(first.step.id == 203 and first.stepIndex == 202 and tostring(first.text:GetText()) == "202")
first.scripts.OnEnter(first)
assert(tooltip == "202 - Instruction 203", "A reused marker tooltip observes the latest step and filtered numbering")

profile.mapshowNextStepsCount, profile.minimapshowNextStepsCount = 2, 1
map:ToggleMapPins()
assert(#fixture.worldPins() == 2 and #fixture.miniPins() == 1 and created == 7)
profile.mapshowNextStepsCount, profile.minimapshowNextStepsCount = 8, 4
map:ToggleMapPins()
assert(#fixture.worldPins() == 8 and #fixture.miniPins() == 4 and created == 12,
    "Only increasing the simultaneous display limit grows the retained marker pool")

local getSteps = APR.GetRouteSteps
local other = { { id = 90000, Coord = { x = 10, y = 20 } } }
APR.RouteQuestStepList.other, APRData.player.other = other, 1
function APR:GetRouteSteps(key) return key == "other" and other or getSteps(self, key) end
APR.ActiveRoute = "other"
map:AddMapPins()
assert(created == 12 and #fixture.worldPins() == 1 and fixture.worldPins()[1].step.id == 90000,
    "Changing routes rebinds existing slots instead of retaining another route's frames")
APR.ActiveRoute = "route"

function env.methods:CreateAnimationGroup() return env.widget() end
function env.methods:CreateAnimation() return env.widget() end
function env.methods:Play() end
function Minimap:GetZoom() return 0 end
function GetCVar() return "0" end
function GetMinimapShape() return "ROUND" end
map:OnInit()
local tick, addPins = map.stepLines.scripts.OnLoop, map.AddMapPins
local rebuilds = 0
function map:AddMapPins(...)
    rebuilds = rebuilds + 1
    return addPins(self, ...)
end
for _ = 1, 100 do
    event(nil, "QUEST_LOG_UPDATE")
    map.messages.APR_MAP_UPDATE()
end
assert(rebuilds == 0 and map.pendingPinRefresh, "Quest and addon-message bursts perform no inline marker rebuild")
APRData.player.route = 450
tick()
assert(rebuilds == 1 and not map.pendingPinRefresh and fixture.worldPins()[1].step.id == 450,
    "One existing animation pass publishes the final route state for the whole burst")
tick()
assert(rebuilds == 1, "No extra marker rebuild remains when the map is unchanged")
map.messages.APR_MAP_UPDATE()
map:ToggleMapPins()
assert(rebuilds == 2 and not map.pendingPinRefresh)
tick()
assert(rebuilds == 2, "An explicit refresh consumes its pending burst without a later duplicate")
WorldMapFrame:SetWidth(WorldMapFrame:GetWidth() + 50)
tick()
assert(rebuilds == 3, "Geometry changes still rebuild immediately on the existing map cadence")
map.messages.APR_MAP_UPDATE()
profile.enableAddon = false
event(nil, "QUEST_LOG_UPDATE")
assert(not map.pendingPinRefresh and #fixture.worldPins() == 0 and #fixture.miniPins() == 0)
profile.enableAddon = true
map.messages.APR_MAP_UPDATE()
tick()
assert(rebuilds == 4 and #fixture.worldPins() == 8 and #fixture.miniPins() == 4)
assert(created == 12, "Event bursts and lifecycle changes cannot grow warmed marker pools")
print("Map pins: bounded pools across 200 steps, live tooltips/numbering, one burst rebuild, resize, disable and immediate refresh passed")
