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

local playerX, playerY, facing, instanceID = -4272.50, -719.40, 0, 0
local seconds = 0
function GetTime() return seconds end
function UnitPosition() return playerY, playerX, 0, instanceID end
function GetPlayerFacing() return facing end
local navigating, advanced, navigationUpdates = false, 0, 0
local step = { LootMoney = { copper = 40 }, Coord = { x = -4281.07, y = -720.15 }, Range = 30 }
local steps = { step }
APR = {
    PlayerID = "player", ActiveRoute = "route", IsInRouteZone = true,
    RouteQuestStepList = { route = { steps = steps } },
    GAME_VERSIONS = { Forever = "forever" },
    settings = { profile = { showArrow = true, arrowFPS = 2 } },
    navigation = {
        IsNavigating = function() return navigating end,
        GetActiveStep = function() return navigating and { Coord = step.Coord } or nil end,
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
    seconds = seconds + 0.03
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
    assert(frame:IsShown(), "Route step Range must not hide navigation guidance")
    tick()
    assert(navigationUpdates == 0 and frame:IsShown(), "Arrow rendering never owns guidance arrival")
    step.NoArrow = true
    refresh()
    assert(frame:IsShown(), "Injected guidance overrides the original objective's NoArrow field")
    local beforeSkip = advanced
    frame.Button.scripts.OnMouseDown(frame.Button, "LeftButton")
    assert(advanced == beforeSkip, "A mandatory guidance target cannot skip the original route step")
    step.NoArrow = nil
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

-- An idle character still needs movement detection, but must not resolve maps or
-- rewrite identical artwork/text at the configured high-frequency cadence.
APR.settings.profile.showArrow, APR.settings.profile.arrowFPS = true, 2
APR.IsInRouteZone, navigating = true, false
step.NoArrow, step.Waypoint, step.Range = nil, nil, nil
playerX, playerY, facing = step.Coord.x + 100, step.Coord.y, 0
refresh(); tick()
local mapReads, textWrites, textureWrites, colorWrites, eligibilityReads = 0, 0, 0, 0, 0
local petBattle = false
function APR:IsPetBattleActive() eligibilityReads = eligibilityReads + 1; return petBattle end
function APR:GetPlayerParentMapID() mapReads = mapReads + 1; return 1411 end
local setText, setCoords, setColor = methods.SetText, methods.SetTexCoord, methods.SetVertexColor
function methods:SetText(value)
    if self == frame.distance then textWrites = textWrites + 1 end
    setText(self, value)
end
function methods:SetTexCoord(...)
    if self == frame.arrow then textureWrites = textureWrites + 1 end
    setCoords(self, ...)
end
function methods:SetVertexColor(...)
    if self == frame.arrow then colorWrites = colorWrites + 1 end
    setColor(self, ...)
end
for _ = 1, 200 do tick() end
assert(mapReads <= 7, "Six idle seconds need only bounded safety checks, not 200 map resolutions")
assert(eligibilityReads <= 7, "Unchanged idle polls do not repeatedly query pet battle or instance eligibility")
assert(textWrites == 0 and textureWrites == 0 and colorWrites == 0,
    "Safety checks cannot rewrite unchanged arrow output")
local before = mapReads
playerX = playerX + 5
tick()
assert(mapReads == before + 1 and textWrites == 1, "Movement updates distance on the very next tick")
local oldCoords = table.concat(frame.arrow.coords, ",")
facing = math.pi / 2
tick()
assert(table.concat(frame.arrow.coords, ",") ~= oldCoords, "Turning updates the heading immediately")
before = mapReads
APR:SetRouteProgress(APR.ActiveRoute, 2, "manual_skip")
tick()
assert(mapReads > before or not frame:IsShown(), "A step change cannot be hidden by the idle cache")
APR:SetRouteProgress(APR.ActiveRoute, 1, "rollback")
refresh(); tick()
before = mapReads
arrow:SetArrowActive(true, arrow.x + 10, arrow.y)
tick()
assert(mapReads == before + 1, "Replacing a target invalidates the idle cache")
print("Idle arrow: 200 unchanged ticks avoid repeated map work and all display writes; movement/turns/steps remain immediate")

petBattle = true
arrow:RefreshVisibility()
assert(not frame:IsShown(), "A pet-battle event bypasses the idle cache and hides immediately")
petBattle = false
arrow:RefreshVisibility()
assert(frame:IsShown(), "Closing a pet battle restores a valid arrow without waiting for movement")

local pathResolutions, stepReads = 0, 0
step = APR:GetCurrentStep()
local getCurrentStep = APR.GetCurrentStep
function APR:GetCurrentStep() stepReads = stepReads + 1; return getCurrentStep(self) end
function APR:GetCurrentRouteMapIDsAndName() pathResolutions = pathResolutions + 1; return 1411, 1411 end
for _ = 1, 100 do playerX = playerX + 1; tick() end
assert(pathResolutions == 0 and stepReads == 100,
    "Moving on an ordinary quest step resolves the step once and never resolves the custom path")
step.UseHS = true
playerX = playerX + 1; tick()
assert(frame.Button:IsShown() and pathResolutions == 0, "Hearthstone skip button needs no route distance scan")
step.UseHS, step.Waypoint = nil, 1
steps[2] = {Coord = {x = step.Coord.x + 30, y = step.Coord.y + 40}}
playerX = playerX + 1; tick()
assert(pathResolutions == 0 and frame.Button:IsShown(), "Waypoints use active metadata without resolving the custom path")
local distance = ((playerX - arrow.x)^2 + (playerY - arrow.y)^2)^0.5
assert(frame.distance.text == math.floor(distance + 50) .. " yards", "Waypoint distance includes the following segment")
print("Moving arrow: no duplicate step/custom-path resolution; hearthstone button and waypoint distance preserved")

-- Replanning can retire an unusable itinerary while its last direction stays
-- visible. That display is informational until the controller publishes a route.
local retainedReads, retainedValid, triggerReads = 0, true, 0
function APR.navigation:GetRetainedArrow()
    retainedReads = retainedReads + 1
    return retainedValid and self.retainedArrow or nil
end
function APR:IsTransportStep() return false end
function APR:IsZoneStepTriggerReached() triggerReads = triggerReads + 1; return true end
step.Waypoint, step.Range, step.ZoneStepTrigger, step.NoArrow = 1, 30, {}, true
navigating, APR.IsInRouteZone = false, true
APR.navigation.retainedArrow = { Coord = { x = playerX + 10, y = playerY }, instanceID = 0 }
local previousAdvanced = advanced
refresh(); tick()
assert(frame:IsShown() and not frame.Button:IsShown(), "Pending guidance keeps the arrow without an authored skip button")
assert(advanced == previousAdvanced and triggerReads == 0,
    "A retained target inside Range cannot complete a waypoint or evaluate its zone trigger")
assert(frame.distance.text == "10 yards", "Pending guidance shows only its own distance, without the authored waypoint chain")
frame.Button.scripts.OnMouseDown(frame.Button, "LeftButton")
assert(advanced == previousAdvanced, "A stale skip click cannot advance a route during recalculation")
local previousHeading = table.concat(frame.arrow.coords, ",")
facing = facing + math.pi / 2; tick()
assert(table.concat(frame.arrow.coords, ",") ~= previousHeading, "The retained direction follows player rotation")
playerX = playerX + 4; tick()
assert(frame:IsShown() and frame.distance.text == "6 yards", "Movement updates retained distance without hiding near its target")

retainedReads = 0
for _ = 1, 200 do tick() end
assert(retainedReads <= 7, "Stationary retained guidance validates its context once per second, not every arrow tick")
APR.navigation.retainedArrow = { Coord = { x = playerX + 30, y = playerY }, instanceID = 0 }
tick()
assert(arrow.x == playerX + 30 and frame.distance.text == "30 yards",
    "Replacing the retained target bypasses the stationary cache")

-- Matching coordinates in another world are not a valid direction.
instanceID = 1; tick()
assert(not frame:IsShown() and not arrow.Active, "Changing world instances hides a retained direction immediately")
instanceID = 0; refresh(); tick()
assert(frame:IsShown(), "A retained target can render again in its own world")
retainedValid = false
arrow:RefreshVisibility()
assert(not frame:IsShown() and not arrow.Active, "An obsolete objective snapshot cannot fall back to authored arrival logic")

-- Publishing replaces the snapshot in one coordinate refresh.
retainedValid, APR.navigation.retainedArrow = true, nil
step.NoArrow, step.ZoneStepTrigger, step.Waypoint, step.Range = nil, nil, nil, nil
step.Coord = { x = playerX + 60, y = playerY }
refresh(); tick()
assert(frame:IsShown() and arrow.x == step.Coord.x and frame.distance.text == "60 yards",
    "A completed replacement resumes the current authored target")
APR.navigation.retainedArrow = { Coord = { x = 0, y = playerY }, instanceID = 0 }
refresh(); tick()
assert(frame:IsShown(), "World X zero is a valid retained target, not an arrival sentinel")
APR.settings.profile.showArrow = false
refresh()
assert(not frame:IsShown(), "Retained guidance still respects the arrow visibility setting")
print("Replanning arrow: retained direction stays responsive, cannot progress or skip quests, and rejects obsolete worlds and objectives")

-- A personal teleport is usable at the player, not at the old search origin.
-- Only the current-step secure button offers the action; the arrow has no target.
APR.settings.profile.showArrow = true
APR.navigation.retainedArrow = nil
navigating, retainedValid = true, true
local guidance = { kind = "spell", sourceFree = true, action = { type = "spell", data = 3567 }, instanceID = 0 }
function APR.navigation:GetActiveStep() return navigating and guidance end
local iconReads = 0
C_Spell = { GetSpellTexture = function(id) iconReads = iconReads + 1; return id + 1000 end }
C_Item = { GetItemIconByID = function(id) iconReads = iconReads + 1; return id + 2000 end }
step.NoArrow, step.Waypoint, step.Range, step.ZoneStepTrigger = true, 1, 100, {}
local arrivalsBefore, triggersBefore, stepReadsBefore = advanced, triggerReads, stepReads
refresh(); tick()
assert(not frame:IsShown(), "Personal travel does not turn the draggable arrow into an inert action button")
assert(frame.distance.text == "" and not frame.Button:IsShown() and arrow.x == 0 and arrow.y == 0,
    "A cast-anywhere action has neither a cast-origin direction nor yard or skip text")
for _ = 1, 200 do playerX = playerX + 1; facing = facing + 0.1; tick() end
assert(iconReads == 0 and stepReads == stepReadsBefore,
    "Personal guidance does not resolve a duplicate icon or authored route on movement")
assert(advanced == arrivalsBefore and triggerReads == triggersBefore and frame.distance.text == "",
    "Personal travel never completes authored arrival or zone-trigger conditions")
arrow:ApplyStyle()
assert(not frame:IsShown(), "Style refreshes cannot show a false cast-location arrow")

guidance = { kind = "item", sourceFree = true, action = { type = "item", data = 253629 }, instanceID = 0 }
refresh(); tick()
assert(not frame:IsShown() and iconReads == 0, "Items and toys use their existing secure current-step button")
navigating = false
APR.navigation.retainedArrow = { displayAction = { type = "item", data = 253629 }, instanceID = 0 }
refresh(); tick()
assert(not frame:IsShown() and frame.distance.text == "" and iconReads == 0,
    "Recalculation after a personal action cannot display an inert button or stale direction")
frame.Button.scripts.OnMouseDown(frame.Button, "LeftButton")
assert(advanced == arrivalsBefore, "A retained personal action cannot expose the authored skip command")
retainedValid = false
arrow:RefreshVisibility()
assert(not frame:IsShown(), "An obsolete retained personal action cannot show a target or inert button")

retainedValid, navigating, APR.navigation.retainedArrow = true, true, nil
guidance = { kind = "portal", Coord = { x = playerX + 38, y = playerY }, instanceID = 0 }
refresh(); tick()
local expectedTexture = APR.settings.profile.arrowStyle == "apr" and "Arrow-APR.tga" or "Arrow.blp"
assert(frame:IsShown() and frame.arrow.texture:find(expectedTexture, 1, true)
    and math.abs(frame.width / frame.height - 56 / 42) < 0.001,
    "A fixed portal or walk restores the selected arrow texture and original rectangular geometry")
assert(frame.distance.text == "38 yards" and table.concat(frame.arrow.coords, ",") ~= "0,1,0,1",
    "Normal guidance restores heading cells, color and distance after a personal action")
print("Personal travel: secure controls stay in the current step; physical portals restore directional guidance")

navigating = false
APR.navigation.retainedArrow = nil
APR.IsInRouteZone = true
step.NoArrow, step.Waypoint = nil, nil
local progressBeforeHearth = advanced
for _, action in ipairs({ "UseHS", "UseDalaHS", "UseGarrisonHS" }) do
    step[action] = 901
    frame:Hide(); frame.showCount = 0
    refresh(); tick()
    assert(not frame:IsShown() and frame.showCount == 0 and arrow.x == 0 and arrow.y == 0,
        "An authored hearth must never point toward its old cast coordinates: " .. action)
    assert(advanced == progressBeforeHearth, "Hiding a hearth arrow cannot complete the cast")
    step[action] = nil
end
refresh(); tick()
assert(frame:IsShown(), "The next ordinary objective restores its geographic arrow")
