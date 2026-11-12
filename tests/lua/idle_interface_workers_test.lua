local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local frames, animations, timers = {}, {}, {}
local create = CreateFrame
function CreateFrame(...)
    local frame = create(...)
    frames[#frames + 1] = frame
    return frame
end
local function schedule(delay, callback)
    local value = { callback = callback, delay = delay }
    function value:Cancel() self.cancelled = true end
    timers[#timers + 1] = value
    return value
end
C_Timer = { NewTimer = schedule, NewTicker = schedule }
function env.methods:CreateAnimationGroup()
    local group = env.widget()
    animations[#animations + 1] = group
    return group
end
function env.methods:CreateAnimation() return env.widget() end
function env.methods:Play() self.playing = true end
function env.methods:Stop() self.playing = false end
WorldMapFrame, Minimap = env.widget(), env.widget()
function WorldMapFrame:GetCanvas() return self end
function WorldMapFrame:GetMapID() return 1 end
function Minimap:GetZoom() return 0 end
function GetCVar() return "0" end
function GetMinimapShape() return "ROUND" end
function APR:NewModule() return { RegisterMessage = function() end } end
function APR:IsInstanceWithUI() return true end
function APR:IsPetBattleActive() return false end
local reads, macroBuilds, work = 0, 0, 0
function UnitPosition() reads = reads + 1; return 10, 20, 0, 0 end
function APR:BuildRaidIconMacro() macroBuilds = macroBuilds + 1; return "" end
APR.ActiveRoute = nil
APR.settings.profile.enableAddon = true
APR.settings.profile.currentStepAttachFrameToQuestLog = false
APR.settings.profile.showMiniMapLine, APR.settings.profile.showMapLine = true, true
APR.settings.profile.showMiniMapLineColor, APR.settings.profile.showMapLineColor = { 1, 1, 1 }, { 1, 1, 1 }
APR.settings.profile.showMiniMapLineThickness, APR.settings.profile.showMapLineThickness = 2, 2
APR.QuestTracker:Initialize()
dofile("APR-Core/features/navigation/Map.lua")
APR.map:OnInit()
dofile("APR-Core/features/navigation/Arrow.lua")
local stub = LibStub
function LibStub(name, ...)
    if name == "LibWindow-1.1" then return { RestorePosition = function() end } end
    return stub(name, ...)
end
APR.Color.defaultLightBackdrop = { 0.1, 0.1, 0.1, 1 }
dofile("APR-Core/ui/panels/Coordinates.lua")
APR.settings.profile.coordinateShow = false
APR.coordinate:RefreshFrameAnchor()
for _ = 1, 120 * 165 do
    for _, frame in ipairs(frames) do
        if frame:IsShown() and frame.scripts.OnUpdate then
            work = work + 1
            frame.scripts.OnUpdate(frame, 1 / 165)
        end
    end
    for _, group in ipairs(animations) do
        if group.playing then work = work + 1; group.scripts.OnLoop() end
    end
    for _, timer in ipairs(timers) do
        if not timer.cancelled then work = work + 1; timer.callback() end
    end
end
for _ = 1, 30 do APR.RaidIconButtons:RefreshMacros() end
assert(work == 0 and reads == 0 and macroBuilds == 0,
    "Hidden/detached interfaces, empty maps and empty target rails do zero recurring work or macro reconstruction")
assert(APR.QuestTracker.observer.scripts.OnUpdate == nil and APR.ArrowFrame.scripts.OnUpdate == nil)

-- The optional coordinates panel is an independent consumer, even without a route.
APR.settings.profile.coordinateShow = true
APR.coordinate:RefreshFrameAnchor()
CoordinateScreenPanel.scripts.OnShow(CoordinateScreenPanel)
local ticker = timers[#timers]
ticker.callback()
assert(reads == 1 and APR.ActiveRoute == nil)
APR.settings.profile.coordinateShow = false
APR.coordinate:RefreshFrameAnchor()
CoordinateScreenPanel.scripts.OnHide(CoordinateScreenPanel)
assert(ticker.cancelled, "Hiding coordinates cancels their observer")
APR.QuestTracker:RefreshObservationActivity()
assert(APR.QuestTracker.observer.scripts.OnUpdate == nil)
print("Idle interfaces: 120 seconds / 165 FPS, no projection/position/macros, and independent coordinate activation passed")
