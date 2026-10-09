-- Diagnostic data stays complete; error details and all exports obey the same identity toggle.
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
-- The store UI is not loaded in a normal session; reproduces the reported charRealm crash.
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
-- Approximate wrapping at the assigned width so resizing exercises the measured layout.
function env.methods:GetStringHeight()
    return math.max(1, math.ceil(#(self.text or "") * 6 / math.max(1, self:GetWidth()))) * 12
end
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
dofile("tests/lua/localization_test_env.lua")
VAS_REALM_LABEL, FRIENDS_LIST_REALM = nil, "Realm: "
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
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
local panel = APR.StatusPanel
assert(frame:IsShown() and #panel.groups == 3)
assert(not panel.fields.charName.value:GetText():find(APR.Username, 1, true))
assert(panel.fields.charRealm.label:GetText() == "Realm",
    "The realm caption must work without loading Blizzard's store UI")
for key, item in pairs(report) do
    assert(panel.fields[key].label:GetText() == item[1] and panel.fields[key].value:GetText() == tostring(item[2]),
        "Every overview field retains its complete value, separately from its label: " .. key)
end

-- A long route must grow vertically at narrow widths without overlapping the next field.
frame.content:SetSize(1208, 776)
panel.infoScroll:SetWidth(1166)
local route = APR.ActiveRoute
APR.ActiveRoute = string.rep("route-identifier-", 14)
panel:Refresh()
local wideHeight = panel.infoContent:GetHeight()
panel.infoScroll:SetWidth(866)
panel.infoScroll.scripts.OnSizeChanged()
assert(panel.infoContent:GetHeight() > wideHeight, "Narrowing the overview must reflow long values")
assert(panel.fields.currentRoute.value:GetText() == APR.ActiveRoute, "Route identifiers are never shortened")
for _, field in pairs(panel.fields) do
    local label, value, card = field.label, field.value, field.value:GetParent()
    assert(-label.point[5] + label:GetStringHeight() < -value.point[5], "Values appear below their own labels")
    assert(value.point[4] + value:GetWidth() <= card:GetWidth(), "Values stay inside their card horizontally")
    assert(-value.point[5] + value:GetStringHeight() < card:GetHeight(), "The card contains the complete value")
end
local nextLabel = panel.fields.currentStep.label
local routeValue = panel.fields.currentRoute.value
assert(-routeValue.point[5] + routeValue:GetStringHeight() < -nextLabel.point[5],
    "The next field must clear every line of a wrapped route")
frame.content:SetHeight(450)
frame.content.scripts.OnSizeChanged()
assert(panel.infoContent:GetHeight() > panel.infoPanel:GetHeight() - 52,
    "A short window scrolls the overview instead of dropping fields")
assert(frame.content:GetHeight() - panel.infoPanel:GetHeight() - 60 >= 180,
    "The error table keeps usable space below the overview")
APR.ActiveRoute = route
frame.content:SetHeight(776)
panel:Refresh()
APR.ErrorLog = {entries = {{source = "Core.lua:12", message = "APR: Private name / Private realm",
    stack = "Private name traceback", count = 3, last = 123}}, revision = 1, provider = "native"}
panel:Refresh()
frame.CopyButton.scripts.OnClick()
local export = APR.UI.reportWindow
local text = export.edit:GetText()
assert(export.edit:HasFocus() and export.edit.highlighted, "Exports are selected and ready to copy on opening")
local function decodeReport(value)
    local source = assert(("\n" .. value .. "\n"):match("\n```lua\n(.-)\n```\n"), "Errors include a Lua Markdown fence")
    return assert(loadstring("return " .. source))()
end
assert(text:match("^# Azeroth Pilot Reloaded") and not text:match("^```"),
    "Status is a Markdown document, not one large code block")
assert(text:find("\n## ROUTE\n", 1, true) and text:find("\n## CHARACTER\n", 1, true))
assert(not text:find("Private name", 1, true) and not text:find("Private realm", 1, true))
for _, item in pairs(report) do
    assert(text:find(tostring(item[2]), 1, true), "The Markdown overview keeps each status value")
end
assert(text:find("    - **100**: \n      - **1**: 1", 1, true),
    "Nested current-step keys and values are exported as Markdown lists")
local decoded = decodeReport(text)
assert(decoded.count == 3 and not decoded.stack:find(APR.Username, 1, true))
assert(not decoded.currentRoute and not decoded.currentStepData, "Only the error payload goes inside the code block")
APR.runtimeRouteStep = {route = "route", index = 1, step = {Qpart = {[100] = {1}}, Coord = {x = 25, y = 75}}}
APR:ExportStatusReport()
text = export.edit:GetText()
assert(text:find("    - **x**: 25", 1, true) and text:find("    - **y**: 75", 1, true),
    "Export uses the active runtime step, including navigation adjustments")
assert(APR.RouteQuestStepList.route.steps[1].Coord == nil, "Export cannot modify the route definition")
export.edit:SetFocus(); export.edit:HighlightText()
APR.Level = 91
APR:updateStatusFrame()
assert(export.edit:GetText() == text and export.edit:HasFocus(), "Status refresh preserves export selection")
frame.IdentityButton.scripts.OnClick()
assert(panel.fields.charName.value:GetText() == APR.Username)
assert(panel.fields.charRealm.value:GetText() == GetRealmName())
assert(export.edit:GetText():find("Private name", 1, true) and export.edit:GetText():find("Private realm", 1, true))
frame.IdentityButton.scripts.OnClick()
assert(not export.edit:GetText():find("Private name", 1, true), "Hiding identity also redacts an open status export")
local errorRow = panel.errors.active[1]
errorRow.scripts.OnClick(errorRow)
decoded = decodeReport(export.edit:GetText())
assert(decoded.count == 3 and not decoded.message:find(APR.Username, 1, true),
    "Individual error exports retain their complete, redacted payload in a Lua code block")
frame.IdentityButton.scripts.OnClick()
assert(decodeReport(export.edit:GetText()).message:find(APR.Username, 1, true))
frame.IdentityButton.scripts.OnClick()
assert(not decodeReport(export.edit:GetText()).message:find(APR.Username, 1, true),
    "Re-redacting an open error must preserve its Markdown wrapper")
APR.UI:ShowTextReport("Performance", "unrelated report")
frame.IdentityButton.scripts.OnClick()
assert(export.edit:GetText() == "unrelated report", "Identity button cannot overwrite performance exports")
local frames = env.frames()
for _ = 1, 20 do APR:updateStatusFrame() end
assert(env.frames() == frames, "Status updates reuse overview and error rows")
local opaque = {restricted = true}
function UnitPosition() return opaque, opaque end
C_Map.GetPlayerMapPosition = function() return {x = opaque, y = opaque} end
assert(APR:getStatusReportInfos().currentCoords[2] == UNKNOWN)
assert(APR:getStatusReportInfos().currentWorldCoords[2] == UNKNOWN)
APR.ActiveRoute = nil
APR.settings.profile.enableAddon = false
APR:ExportStatusReport()
assert(not export.edit:GetText():find("**Qpart**", 1, true), "No active route must not export a stale runtime step")
APR.ErrorLog.entries = {}
APR:ExportStatusReport()
text = export.edit:GetText()
assert(not text:find("```", 1, true), "A status without errors has no code blocks")
assert(text:find("UI\\_ERRORS\\_EMPTY", 1, true), "An empty session is stated explicitly")
APR.ErrorLog.provider = "unavailable"
APR:ExportStatusReport()
assert(export.edit:GetText():find("UI\\_ERRORS\\_UNAVAILABLE", 1, true),
    "Unavailable capture must not be reported as an error-free session")

-- Values with Markdown syntax stay literal, and privacy is applied before escaping.
APR.ActiveRoute, APR.Username = "route", "Private_name"
APR.runtimeRouteStep = {route = "route", index = 1, step = {
    Text = "**important** Private_name / Private realm", enabled = false, empty = {},
}}
APR.runtimeRouteStep.step.loop = APR.runtimeRouteStep.step
APR:ExportStatusReport()
assert(export.edit:GetText():find("Private\\_name", 1, true))
frame.IdentityButton.scripts.OnClick() -- Identity was shown by the unrelated-export test.
text = export.edit:GetText()
assert(not text:find("Private_name", 1, true) and not text:find("Private\\_name", 1, true))
assert(not text:find("Private realm", 1, true), "Identity in nested step data is hidden too")
assert(text:find("\\*\\*important\\*\\*", 1, true) and text:find("\\<hidden\\>", 1, true))
assert(text:find("**enabled**: false", 1, true) and text:find("**empty**: {}", 1, true))
assert(text:find("\\<circular\\>", 1, true), "Cyclic runtime data cannot hang Markdown export")
APR.ErrorLog.entries = {
    {source = "One.lua:1", count = 2, message = "literal ``` sequence", stack = "Private_name traceback"},
    {source = "Two.lua:2", count = 4, message = "second error"},
}
APR:ExportStatusReport()
text = export.edit:GetText()
local payload = assert(text:match("````lua\n(.-)\n````"))
assert(assert(loadstring("return " .. payload))().message == "literal ``` sequence",
    "Embedded backticks cannot break a full report's error blocks")
assert(text:find("\n### 1. One.lua:1", 1, true) and text:find("\n### 2. Two.lua:2", 1, true))
assert(decodeReport(text).count == 4, "Each error has a separate complete code block")
APR:updateStatusFrame()
APR:closeStatusReport()
assert(not frame:IsShown() and not frame.scripts.OnUpdate, "Hidden status stops its refresh work")
print("Status: complete overview, error details, identity toggle, readable export, selection and restricted coordinates passed")
