-- Track visibility transitions, including flashes between step refresh and OnUpdate.
local function noop() end
local methods = {}
local function widget(parent)
    return setmetatable({ shown = true, showCount = 0, scripts = {}, parent = parent, scale = 1 }, { __index = methods })
end
setmetatable(methods, { __index = function() return noop end })
function methods:Show() self.shown = true; self.showCount = self.showCount + 1 end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:CreateTexture() return widget(self) end
function methods:CreateFontString() return widget(self) end
function methods:SetParent(parent) self.parent = parent end
function methods:SetPoint(...) self.point = {...} end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:SetScale(scale) self.scale = scale end
function methods:GetEffectiveScale()
    local parent = rawget(self, "parent")
    return self.scale * (parent and parent:GetEffectiveScale() or 1)
end
function methods:GetStringWidth() return 20 end
function methods:GetStringHeight() return 12 end
function methods:SetTexture(value) self.texture = value end
function methods:SetTexCoord(...) self.coords = {...} end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetText(value) self.text = value end
function CreateFrame(_, _, parent) return widget(parent) end
function LibStub() return { GetLocale = function() return { YARDS = "yards" } end } end

local playerX, playerY, facing = -4272.50, -719.40, 0
function UnitPosition() return playerY, playerX end
function GetPlayerFacing() return facing end
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

local function verifyNavigation()
    navigating, advanced, navigationUpdates = false, 0, 0
    playerX, playerY = -4272.50, -719.40
    step.NoArrow, step.Waypoint = nil, nil
    APR.settings.profile.showArrow = true
    frame:Hide()
    frame.showCount = 0
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
end

assert(frame.arrow.texture:find("Arrow.blp", 1, true), "Existing profiles must keep the classic artwork")
verifyNavigation()
APR.settings.profile.arrowStyle = "apr"
local originalX, originalY, originalActive, originalAdvanced = arrow.x, arrow.y, arrow.Active, advanced
arrow:ApplyStyle()
assert(frame.arrow.texture:find("Arrow-APR.tga", 1, true))
assert(arrow.x == originalX and arrow.y == originalY and arrow.Active == originalActive and advanced == originalAdvanced,
    "Changing artwork cannot change the target, activate guidance or advance a step")
verifyNavigation()

-- Both sprite sheets use exactly the same heading cells, colors and distance text.
step.NoArrow = nil
playerX, playerY = step.Coord.x, step.Coord.y - 100
local reference = {}
for _, style in ipairs({"classic", "apr"}) do
    APR.settings.profile.arrowStyle = style
    arrow:ApplyStyle()
    refresh()
    for _, heading in ipairs({0, math.pi / 2, math.pi, -math.pi / 2, 2 * math.pi - 0.01}) do
        facing = heading
        tick()
        local state = table.concat(frame.arrow.coords, ",") .. "/" .. table.concat(frame.arrow.color, ",")
            .. "/" .. frame.distance.text
        if style == "classic" then reference[heading] = state
        else assert(reference[heading] == state, "Only the arrow artwork may differ") end
    end
end
APR.settings.profile.arrowStyle = "unknown"
arrow:ApplyStyle()
assert(frame.arrow.texture:find("Arrow.blp", 1, true), "Unknown styles fall back to the existing arrow")
APR.settings.profile.arrowStyle = "apr"
arrow:Init()
assert(frame.arrow.texture:find("Arrow-APR.tga", 1, true), "Initialization restores the profile's selected style")

-- Old profiles keep their text's displayed size; later changes affect only the chosen control.
local profile = APR.settings.profile
profile.arrowStyle, profile.arrowScale, profile.arrowTextScale = "classic", 2, nil
profile.arrowleft, profile.arrowtop = 350, -420
arrow:Init()
assert(frame.width == 112 and frame.height == 84 and frame.scale == 1)
assert(profile.arrowTextScale == 2 and frame.distance:GetEffectiveScale() == 2,
    "An existing profile's text retains the previous combined scale")
assert(frame.Button:GetEffectiveScale() == 2 and frame.Fontstring:GetEffectiveScale() == 2,
    "The skip button's label and click area share the independent text scale")
profile.arrowScale = 1.5
arrow:ApplySize()
assert(frame.width == 84 and frame.height == 63 and frame.distance:GetEffectiveScale() == 2,
    "Resizing the arrow must not resize the distance or action text")
profile.arrowTextScale = 1.25
arrow:ApplySize()
assert(frame.width == 84 and frame.height == 63 and frame.distance:GetEffectiveScale() == 1.25,
    "Resizing text must not resize the artwork")
profile.arrowScale, profile.arrowStyle = 1, "apr"
arrow:ApplyStyle()
assert(math.abs(frame.width - 56 * 1.8) < 0.001 and math.abs(frame.height - 42 * 1.8) < 0.001,
    "APR artwork is 80 percent larger at the same size setting")
assert(frame.distance:GetEffectiveScale() == 1.25 and profile.arrowleft == 350 and profile.arrowtop == -420)
profile.arrowStyle = "classic"
arrow:ApplyStyle()
assert(frame.width == 56 and frame.height == 42 and frame.distance:GetEffectiveScale() == 1.25,
    "Switching back to Classic restores its original geometry without changing text")
arrow:Init()
assert(profile.arrowTextScale == 1.25, "Reinitialization never repeats migration over a chosen text size")
APR.settings.profile = {arrowScale = 1, arrowStyle = "apr"}
arrow:Init()
assert(frame.distance:GetEffectiveScale() == 1 and APR.settings.profile.arrowTextScale == 1,
    "New profiles use the normal text size alongside the larger APR arrow")
print("Arrow: navigation, headings and distances preserved; larger APR art, independent sizes and legacy profiles passed")
