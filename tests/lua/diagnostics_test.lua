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
function APR:TableToDebugString() return "Diagnostic text" end
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
local report = APR:BuildDiagnosticSnapshot()
assert(not report.player and not report.realm and report.interface == 120105 and report.step == 1)
assert(APR:BuildDiagnosticSnapshot(true).player == "Private name")
APR:ShowDiagnostics()
assert(APR.DiagnosticsFrame:IsShown() and APR.DiagnosticsFrame.report == "Diagnostic text")
APR.ActiveRoute = nil
assert(APR:DescribeStepWait()[1] == APR:LocalizeUI("NO_ROUTE"))
APR.settings.profile.enableAddon = false
assert(APR:DescribeStepWait()[1] == APR:LocalizeUI("PAUSED"))
print("Diagnostics: missing/loading objectives, read-only lookup, no route and identity redaction passed")
