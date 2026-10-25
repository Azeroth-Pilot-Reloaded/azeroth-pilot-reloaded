-- Physical return points use native arrival conditions, independently of quests.
local advances, map, px, py, timer = 0, 1457, 0, 0, nil
APR = {
    stepHandlers = {},
    settings = { profile = { enableAddon = true } },
    PlayerID = "player", ActiveRoute = "fixture",
    NextQuestStep = function() advances = advances + 1 end,
    AdvanceStep = function() advances = advances + 1 end,
    Debug = function() end,
    CaptureStepContext = function() return "fixture" end,
    IsStepContextCurrent = function() return true end,
    GetPlayerParentMapID = function() return map end,
}
APRData = { player = { fixture = 1 } }
function LibStub() return { GetLocale = function() return {} end } end
C_QuestLog = { IsQuestFlaggedCompleted = function(id) return id == 10 end }
C_Map = { GetBestMapForUnit = function() return map end }
C_Timer = { NewTimer = function(_, callback) timer = callback; return { Cancel = function() end } end }
function UnitIsDeadOrGhost() return false end
function UnitPosition() return py, px end
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/features/questing/StepTravelHandlers.lua")

for _, autoSkip in ipairs({ false, true }) do
    APR.settings.profile.autoSkipAllWaypoints = autoSkip
    for _, anchors in ipairs({ { Waypoint = 10 }, { Waypoint = 20, WaypointDB = { 10 } } }) do
        anchors.NonSkippableWaypoint = true
        anchors.ZoneStepTrigger = { mapID = 1457, x = 50, y = 60, Range = 10 }
        for reset = 1, 3 do
            advances, map, px, py = 0, 1457, 0, 0
            APR.stepHandlers.Waypoint(anchors, false, 1)
            assert(advances == 0, "Rewarded anchors and user preferences must not finish an explicit arrival")
            map, px, py = 1438, 50, 60
            timer()
            assert(advances == 0, "The same coordinates on another map are not an arrival")
            map = 1457
            timer()
            assert(advances == 1, "The return completes at its physical destination after every reset")
        end
    end
end

APR.settings.profile.autoSkipAllWaypoints = false
advances = 0
APR.stepHandlers.Waypoint({ Waypoint = 10, NonSkippableWaypoint = true }, false, 1)
assert(advances == 1, "Ordinary rewarded quest waypoints keep their reset behavior")
APR.stepHandlers.Waypoint({ Waypoint = 20, WaypointDB = { 10 } }, false, 1)
assert(advances == 2, "Ordinary alternate quest anchors still skip after reward")
