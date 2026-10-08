-- The historical status remains compact; identity visibility also controls the Lua export.
local env = dofile("tests/lua/route_ui_test_env.lua")
local originalLibStub = LibStub
local locale = setmetatable({}, {__index = function(_, key) return key end})
function LibStub(name)
    if name == "AceLocale-3.0" then return {GetLocale = function() return locale end} end
    return originalLibStub(name)
end
function GetLocale() return "enUS" end
function GetBuildInfo() return "12.1.5", "123", "", 120105 end
function GetRealmName() return "Private realm" end
function GetRealZoneText() return "Test zone" end
function GetCVar() return "EU" end
function date() return "2026-10-08 12:00:00" end
function UnitPosition() return 130, 240, 0, 7 end
function IsInInstance() return false end
C_Map = {GetBestMapForUnit = function() return 123 end,
    GetPlayerMapPosition = function() return {x = 0.25, y = 0.75} end}
UIParent:SetSize(1920, 1080)
function env.methods:SetFormattedText(format, ...) self:SetText(string.format(format, ...)) end
function env.methods:Raise() end
APR.UIParent = UIParent
APR.HEXColor = {green = "00ff00", red = "ff0000"}
function APR:ResolveTextColorRole(_, fallback) return fallback end
function APR:WrapTextWithAppearanceColor(value) return tostring(value) end
function APR:CanAccessValue(value) return type(value) ~= "table" or not value.restricted end
function APR:IsInstanceWithUI() return true end
function APR:GetContinent() return 42 end
function APR:GetMapInfoCached() return {name = "Test continent"} end
function APR:GetClassNameById() return "Mage" end
function APR.settings:OpenSettings() end
APR.coordinate = {RoundCoords = function(_, x, y) return string.format("%.2f, %.2f", x, y) end}
APR.PlayerID, APR.Username, APR.ActiveRoute = "Test-Realm", "Private name", "route"
APR.ClassId, APR.Level, APR.Faction, APR.version = 8, 90, "Horde", "test"
APRData = {[APR.PlayerID] = {route = 1}}
APR.RouteQuestStepList = {route = {steps = {{Qpart = {[100] = {1}}}}}}
dofile("APR-Core/ui/foundations/InterfaceStrings.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/ui/panels/StatusReport.lua")
function APR:GetRouteSteps() error("Reading status must not activate parallel route steps") end
local report = APR:getStatusReportInfos()
assert(not report.charName and not report.charRealm)
assert(report.currentRoute[2] == "route" and report.currentStep[2] == "1, Qpart")
assert(report.wowVersion[2] == "12.1.5" and report.currentTime[2] == date())
assert(report.currentCoords[2] == "25.00, 75.00" and report.currentWorldCoords[2] == "240.00, 130.00")
assert(report.currentContinent[2] == "Test continent" and report.charClass[2] == "Mage")
assert(not report.reasons and not report.transitions)
APR:showStatusReport()
local frame = APR.StatusFrame
assert(frame:IsShown() and frame.Section1 and frame.Section2 and frame.Section3 and not frame.Section4)
assert(frame.Section3.Content.Line2.Text:GetText() == "Name: Hidden")
frame.CopyButton.scripts.OnClick()
local export = APR.UI.reportWindow
local text = export.edit:GetText()
assert(text:find('["currentRoute"] = {', 1, true) and text:find("\n    ", 1, true))
assert(not text:find("Private name", 1, true) and not text:find("Private realm", 1, true))
local decoded = assert(loadstring("return " .. text))()
assert(decoded.currentWorldCoords[2] == "240.00, 130.00")
assert(decoded.currentStepData.Qpart[100][1] == 1, "Export includes the complete current step")
APR.runtimeRouteStep = {route = "route", index = 1, step = {Qpart = {[100] = {1}}, Coord = {x = 25, y = 75}}}
APR:ExportStatusReport()
text = export.edit:GetText()
decoded = assert(loadstring("return " .. text))()
assert(decoded.currentStepData.Coord.x == 25 and decoded.currentStepData.Coord.y == 75,
    "Export uses the active runtime step, including navigation adjustments")
assert(APR.RouteQuestStepList.route.steps[1].Coord == nil, "Export cannot modify the route definition")
export.edit:SetFocus(); export.edit:HighlightText()
APR.Level = 91
APR:updateStatusFrame()
assert(export.edit:GetText() == text and export.edit:HasFocus(), "Status refresh preserves export selection")
frame.IdentityButton.scripts.OnClick()
assert(frame.Section3.Content.Line2.Text:GetText() == "Name: Private name-Private realm")
assert(export.edit:GetText():find("Private name", 1, true) and export.edit:GetText():find("Private realm", 1, true))
frame.IdentityButton.scripts.OnClick()
assert(not export.edit:GetText():find("Private name", 1, true), "Hiding identity also redacts an open status export")
APR.UI:ShowTextReport("Performance", "unrelated report")
frame.IdentityButton.scripts.OnClick()
assert(export.edit:GetText() == "unrelated report", "Identity button cannot overwrite performance exports")
local frames = env.frames()
for _ = 1, 20 do APR:updateStatusFrame() end
assert(env.frames() == frames, "Status updates reuse the historical section frames")
local opaque = {restricted = true}
function UnitPosition() return opaque, opaque end
C_Map.GetPlayerMapPosition = function() return {x = opaque, y = opaque} end
assert(APR:getStatusReportInfos().currentCoords[2] == UNKNOWN)
assert(APR:getStatusReportInfos().currentWorldCoords[2] == UNKNOWN)
APR.ActiveRoute = nil
APR.settings.profile.enableAddon = false
assert(APR:getStatusReportInfos().currentStep[2] == "No active route")
APR:ExportStatusReport()
decoded = assert(loadstring("return " .. export.edit:GetText()))()
assert(decoded.currentStepData == nil, "No active route must not export a stale runtime step")
APR:updateStatusFrame()
APR:showStatusReport()
assert(not frame:IsShown(), "Original status entry toggles the window")
print("Status: historical layout/data, identity toggle, readable export, selection and restricted coordinates passed")
