-- Track visibility transitions, including flashes between step refresh and OnUpdate.
local function noop() end
local methods = {}
local function widget()
    return setmetatable({ shown = true, showCount = 0, scripts = {} }, { __index = methods })
end
setmetatable(methods, { __index = function() return noop end })
function methods:Show() self.shown = true; self.showCount = self.showCount + 1 end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:CreateTexture() return widget() end
function methods:CreateFontString() return widget() end
function methods:GetStringWidth() return 20 end
function methods:GetStringHeight() return 12 end
function CreateFrame() return widget() end
function LibStub() return { GetLocale = function() return { YARDS = "yards" } end } end

local playerX, playerY = -4272.50, -719.40
function UnitPosition() return playerY, playerX end
function GetPlayerFacing() return 0 end
local navigating, advanced, navigationUpdates = false, 0, 0
local step = { LootMoney = { copper = 40 }, Coord = { x = -4281.07, y = -720.15 }, Range = 30 }
local steps = { step }
APR = {
    PlayerID = "player", ActiveRoute = "route", IsInRouteZone = true,
    RouteQuestStepList = { route = { steps = steps } },
    GAME_VERSIONS = { Forever = "forever" },
    settings = { profile = { showArrow = true, arrowFPS = 2 } },
    farstrider = {
        IsNavigating = function() return navigating end,
        OnArrowUpdate = function() navigationUpdates = navigationUpdates + 1 end,
    },
}
APRData = { player = { route = 1 } }
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/StepUtils.lua")
function APR:NewModule() return {} end
function APR:GetGameVersion() return "forever" end
function APR:RegisterFontString() end
function APR:Debug() end
function APR:GetRouteSteps() return steps end
function APR:GetCurrentRouteMapIDsAndName() return 1411, 1411 end
function APR:GetPlayerParentMapID() return 1411 end
function APR:GetStepCoord(current) return current.Coord end
function APR:IsPetBattleActive() return false end
function APR:IsInstanceWithUI() return true end
function APR:NextQuestStep() advanced = advanced + 1 end

step = APR:GetCurrentStep() -- Mutate the same runtime step that navigation consumes.
dofile("APR-Core/features/navigation/Arrow.lua")
local arrow, frame = APR.Arrow, APR.ArrowFrame
local function refresh()
    arrow.currentStep = 0 -- UpdateStep resets the coordinate cache on every refresh.
    arrow:SetCoord()
end
local function tick()
    if frame:IsShown() then frame.scripts.OnUpdate(frame, 0.03) end
end

for _ = 1, 20 do
    refresh()
    assert(not frame:IsShown(), "Refreshing LootMoney inside Range must never show the arrow")
    tick()
end
assert(frame.showCount == 0, "No transient Show calls while already inside the farming area")
assert(arrow.x == 0, "Reached coordinates also suppress the map line")
assert(advanced == 0, "Arrival alone must not complete LootMoney")

playerX = step.Coord.x + 60
refresh()
assert(frame:IsShown(), "Refreshing outside Range restores guidance")
tick()
playerX = step.Coord.x + 8
tick()
assert(not frame:IsShown(), "Entering Range hides on the same update, without waiting another frame")
assert(advanced == 0)

playerX = step.Coord.x + step.Range
refresh()
assert(frame:IsShown(), "Preserve the strict arrival boundary")
playerX = step.Coord.x + 8
step.Waypoint = 123
refresh()
assert(advanced == 0, "Setting coordinates must not synchronously advance waypoints")
tick()
assert(advanced == 1 and not frame:IsShown(), "Waypoints still advance on arrival")
tick()
assert(advanced == 1, "Hidden waypoints must not advance twice")
step.Waypoint = nil

navigating = true
refresh()
assert(frame:IsShown(), "Route step Range must not hide Farstrider navigation")
tick()
assert(navigationUpdates == 1 and frame:IsShown())
navigating = false
APR.IsInRouteZone = false
arrow:SetArrowActive(true, step.Coord.x, step.Coord.y)
tick()
assert(frame:IsShown(), "Range applies only inside the route zone")
APR.IsInRouteZone = true

playerX = step.Coord.x + 60
APR.settings.profile.showArrow = false
refresh()
assert(not frame:IsShown(), "Refreshing must respect the arrow visibility setting immediately")
APR.settings.profile.showArrow = true
step.NoArrow = true
refresh()
assert(not frame:IsShown() and not arrow.Active)
print("Arrow visibility: repeated range refreshes, arrival, waypoints, navigation and settings passed")
