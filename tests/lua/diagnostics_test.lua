local env = dofile("tests/lua/route_ui_test_env.lua")
function GetLocale() return "enUS" end
function GetBuildInfo() return "12.1.5", "123", "", 120105 end
function GetTime() return 123 end
function UnitIsDeadOrGhost() return false end
function GetRealmName() return "Private realm" end
UIParent:SetSize(1920, 1080)
dofile("APR-Core/ui/foundations/InterfaceStrings.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/core/Diagnostics.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/features/questing/StepDiagnostics.lua")
dofile("APR-Core/ui/panels/Diagnostics.lua")
APR.PlayerID, APR.Username, APR.ActiveRoute = "Test-Realm", "Private name", "route"
APRData = {[APR.PlayerID] = {route = 1}}
APR.RouteQuestStepList = {route = {steps = {{Qpart = {[100] = {1}}}}}}
APR.ActiveQuests = {}
APR.QUEST_STATUS = {COMPLETE = 1}
function APR:GetStepString() return "Quest objective", "Qpart" end
function APR:GetRecentTransitions() return {} end
function APR:CanUndoManualSkip() return false end
function APR:GetRouteSteps() error("Diagnostics must never activate parallel route steps") end
local onQuest = false
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end, IsOnQuest = function() return onQuest end }
APR.settings.profile.enableAddon = true
assert(APR:DescribeStepWait()[1]:find("Accept quest 100", 1, true))
onQuest = true
assert(APR:DescribeStepWait()[1]:find("still loading", 1, true))
APR.ActiveQuests[100] = {objectives = {{status = 0, text = "Collect objects"}}}
assert(APR:DescribeStepWait()[1]:find("Collect objects", 1, true))
APR.IsInRouteZone = false
assert(APR:DescribeStepWait()[1] == APR:LocalizeUI("OUT_OF_ZONE"))
function GetRealZoneText() return "Test zone" end
function GetCVar() return "EU" end
function date() return "2026-10-08 12:00:00" end
function UnitPosition() return 130, 240, 0, 7 end
C_Map = {GetBestMapForUnit = function() return 123 end,
    GetPlayerMapPosition = function() return {x = 0.25, y = 0.75} end}
function APR:GetContinent() return 42 end
function APR:GetMapInfoCached() return {name = "Test continent"} end
function APR:GetClassNameById() return "Mage" end
APR.ClassId, APR.Level, APR.Faction = 8, 90, "Horde"
local report = APR:BuildDiagnosticSnapshot()
assert(not report.player and not report.realm and report.interface == 120105 and report.step == 1)
assert(report.location.name == "Test zone" and report.location.continent == "Test continent")
assert(report.location.x == 25 and report.location.y == 75 and report.location.worldX == 240 and report.location.worldY == 130)
assert(report.character.className == "Mage" and report.server == "EU" and report.capturedAt == date())
assert(APR:BuildDiagnosticSnapshot(true).player == "Private name")
local sections = APR:BuildDiagnosticSections(report)
assert(#sections == 5 and sections[4].title == APR:LocalizeUI("EXPLAIN"))
assert(table.concat(sections[3].lines, "\n"):find("240.00, 130.00", 1, true))
APR:ShowDiagnostics()
local frame = APR.DiagnosticsFrame
assert(frame:IsShown() and #frame.sections == 5 and not frame.reportScroll:IsShown())
frame.copy.scripts.OnClick()
assert(frame.reportShown and frame.report:find('["client"] = "12.1.5"', 1, true))
assert(not frame.report:find("Private name", 1, true) and not frame.report:find("Private realm", 1, true))
local selectedReport = frame.report
APR.Level = 91
APR:RefreshDiagnostics()
assert(frame.report == selectedReport and frame.snapshot.character.level == 90,
    "Live status events cannot replace the report while the user selects it")
frame.toggleReport.scripts.OnClick()
assert(not frame.text:HasFocus() and not frame.reportShown)
APR:RefreshDiagnostics()
assert(frame.snapshot.character.level == 91)
frame.copy.scripts.OnClick()
frame.redact.scripts.OnClick(frame.redact)
assert(frame.report:find("Private name", 1, true) and frame.report:find("Private realm", 1, true))
local frames = env.frames()
for _ = 1, 20 do APR:RefreshDiagnostics(true) end
assert(env.frames() == frames, "Status refresh reuses its section frames")
local decoded = assert(loadstring("return " .. frame.report))()
assert(decoded.location.x == 25 and decoded.stepData.Qpart[100][1] == 1)
local timerCalls, timer = 0
C_Timer = {NewTimer = function(_, callback)
    timerCalls = timerCalls + 1
    timer = {Cancel = function(self) self.cancelled = true end, callback = callback}
    return timer
end}
frame.scripts.OnEvent(); frame.scripts.OnEvent()
assert(timerCalls == 1)
frame:Hide(); frame.scripts.OnHide(frame)
assert(timer.cancelled and not frame.refreshTimer)
function APR:CanAccessValue(value) return type(value) ~= "table" or not value.restricted end
local opaque = {restricted = true}
function UnitPosition() return opaque, opaque, opaque, opaque end
assert(APR:BuildDiagnosticSnapshot().location.worldX == nil, "Restricted coordinates are not formatted")
APR.ActiveRoute = nil
assert(APR:DescribeStepWait()[1] == APR:LocalizeUI("NO_ROUTE"))
APR.settings.profile.enableAddon = false
assert(APR:DescribeStepWait()[1] == APR:LocalizeUI("PAUSED"))
print("Diagnostics: full status, read-only lookup, formatted Lua, identity redaction, restricted coordinates and pooled sections passed")
