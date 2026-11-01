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

-- Export the published navigation state without asking the controller to
-- update, resolve a route or validate an arrival while diagnosing a mismatch.
local textReads, activeStepReads, zoneReportReads = 0, 0, 0
local zoneReport = {
    playerCurrent = 2576, playerParent = 1550, playerContinent = 947,
    playerHierarchy = { 2576, 1550, 947 }, allRelevantMaps = { [2576] = true },
    specialContent = false, cacheValid = true, timestamp = 12345,
}
function APR:GetZoneDetectionReport() zoneReportReads = zoneReportReads + 1; return zoneReport end
local navigationFont = env.widget()
navigationFont:SetText("Private_name: Take the portal")
function navigationFont:GetText() textReads = textReads + 1; return self.text end
local navigationStep = {
    id = "12:1", kind = "spell", label = "Teleport to Orgrimmar", sourceFree = true,
    action = { type = "spell", data = 3567 }, Coord = { x = -263.9, y = -439.8, mapID = 2576 },
    from = { x = -439.8, y = -263.9, uiMapID = 2576, instanceID = 2695 },
    to = { x = 1570, y = -4397, uiMapID = 85, instanceID = 1 },
    diagnosticDetail = { arrivalRadius = 17, note = "Private_name: pending arrival" },
    canStart = function() error("Status must not check travel availability") end,
}
APR.navigation = {
    NavigationStepKey = "01_NAVIGATION_PATH", state = "guiding", generation = 12, cursor = 1,
    controllerRevision = 5, continuationReuses = 3, lastInvalidation = "BAG_UPDATE_DELAYED", worldLoading = false,
    lastWorldEvent = "LOADING_SCREEN_DISABLED",
    lastCancellation = { reason = "replan", queuedSteps = 0, generation = 1, privateGraph = "never-export-cancel-graph" },
    lastCandidateDiscard = { reason = "world_loading", queuedSteps = 4, generation = 11 },
    lastContinuation = { status = "reused", reason = "expected_arrival", queuedSteps = 4, distance = 0.1,
        privateGraph = "never-export-the-continuation-graph" },
    destination = { x = 15000, y = 0, instanceID = 44, uiMapID = 77 },
    start = { x = 10, y = 20, instanceID = 45, uiMapID = 78 },
    queue = { navigationStep, { id = "12:2", kind = "walk", label = "Final synthetic waypoint", seconds = 321,
        from = navigationStep.to, to = { x = 15000, y = 0, instanceID = 44, uiMapID = 77 },
        canStart = function() error("Export cannot validate a future leg") end } },
    search = { privateGraph = "never-export-the-graph",
        status = "planning", slices = 7, elapsedMilliseconds = 125, totalSliceMilliseconds = 5 },
    retainedArrow = { Coord = { x = 10, y = 20 }, instanceID = 2695,
        context = { privateContext = "never-export-the-context" } },
    GetActiveStep = function(self)
        activeStepReads = activeStepReads + 1
        return self.queue[self.cursor or 1]
    end,
    Update = function() error("Status must not start routing") end,
}
APR.Arrow = { Active = true, x = -263.9, y = -439.8, Distance = 38, currentStep = 0 }
APR.currentStep.questsList = {
    ["01_NAVIGATION_PATH-12:1"] = { font = navigationFont, objectiveText = "Take the portal",
        IconButton = { itemID = 3567, attribute = "spell" } },
    ["01_NAVIGATION_PATH-restricted"] = { font = { restricted = true,
        GetText = function() error("A restricted font must not be inspected") end } },
    ordinary = { font = { GetText = function() error("Only navigation rows belong in this snapshot") end } },
}
APR:getStatusReportInfos()
assert(textReads == 0 and activeStepReads == 0 and zoneReportReads == 0,
    "Periodic overview refreshes do not collect diagnostic command results")
APR:ExportStatusReport()
text = export.edit:GetText()
assert(textReads == 1 and text:find("- **Navigation**:", 1, true)
    and text:find("**state**: guiding", 1, true) and text:find("**generation**: 12", 1, true))
assert(activeStepReads == 1 and zoneReportReads == 1,
    "An export captures each manual diagnostic source once")
assert(text:find("**elapsedMilliseconds**: 125", 1, true)
    and text:find("**totalSliceMilliseconds**: 5", 1, true) and text:find("**slices**: 7", 1, true),
    "The bounded navigation snapshot reports actual planning latency and CPU work")
assert(text:find("**continuationReuses**: 3", 1, true), "Status identifies reuse of a precomputed continuation")
assert(text:find("**controllerRevision**: 5", 1, true) and text:find("**reason**: expected\\_arrival", 1, true)
    and text:find("**lastInvalidation**: BAG\\_UPDATE\\_DELAYED", 1, true)
    and not text:find("never-export-the-continuation-graph", 1, true),
    "Continuation diagnostics identify runtime, event and decision without exporting route internals")
assert(text:find("**worldLoading**: false", 1, true) and text:find("**lastCancellation**:", 1, true)
    and text:find("**lastCandidateDiscard**:", 1, true) and not text:find("never-export-cancel-graph", 1, true),
    "The report distinguishes a discarded candidate from a cancelled published itinerary")
assert(text:find("\n## /apr zi\n", 1, true) and text:find("**playerCurrent**: 2576", 1, true)
    and text:find("**playerParent**: 1550", 1, true) and text:find("**playerContinent**: 947", 1, true)
    and text:find("**playerHierarchy**:", 1, true) and text:find("**allRelevantMaps**:", 1, true)
    and text:find("**specialContent**: false", 1, true) and text:find("**cacheValid**: true", 1, true),
    "Zone diagnostics retain the map hierarchy and cache/content flags from /apr zi")
assert(text:find("\n## /dump APR.navigation:GetActiveStep()\n", 1, true)
    and text:find("**diagnosticDetail**:", 1, true) and text:find("**arrivalRadius**: 17", 1, true),
    "The active-step dump includes data beyond the navigation summary")
assert(text:find("**kind**: spell", 1, true) and text:find("**data**: 3567", 1, true)
    and text:find("**sourceFree**: true", 1, true) and text:find("**mapID**: 2576", 1, true)
    and text:find("**uiMapID**: 85", 1, true), "The active leg includes its action and both endpoints")
assert(text:find("**retainedArrow**:", 1, true) and text:find("**actualArrow**:", 1, true)
    and text:find("**Distance**: 38", 1, true) and text:find("**renderedRows**:", 1, true)
    and text:find("**itemID**: 3567", 1, true) and text:find("Take the portal", 1, true),
    "The export can distinguish the selected leg, retained direction and visible instruction/button")
assert(not text:find("Private_name", 1, true) and not text:find("Private\\_name", 1, true)
    and not text:find("never-export", 1, true) and not text:find("canStart", 1, true),
    "Navigation snapshots keep identity masking and exclude callbacks, contexts and the search graph")
assert(APR.navigation.queue[1] == navigationStep and navigationStep.action.data == 3567,
    "Export leaves published guidance untouched")
assert(text:find("**remainingSteps**:", 1, true) and text:find("Final synthetic waypoint", 1, true)
    and text:find("**seconds**: 321", 1, true) and text:find("**destination**:", 1, true)
    and text:find("**uiMapID**: 77", 1, true) and text:find("**start**:", 1, true),
    "The export distinguishes an intermediate portal from the actual waypoint and records all remaining legs")
local publishedQueue = APR.navigation.queue
APR.navigation.queue = { navigationStep }
for index = 2, 40 do
    APR.navigation.queue[index] = { id = tostring(index), label = "Future diagnostic leg " .. index, kind = "walk" }
end
APR:ExportStatusReport()
local bounded = export.edit:GetText()
assert(bounded:find("Future diagnostic leg 16", 1, true) and not bounded:find("Future diagnostic leg 17", 1, true)
    and bounded:find("**queueTruncated**: true", 1, true), "Full-journey diagnostics remain bounded")
APR.navigation.queue = publishedQueue
navigationStep.action.data = opaque
APR:ExportStatusReport()
assert(export.edit:GetText():find("**data**: " .. UNKNOWN, 1, true), "Restricted action values are not serialized")
for index = 1, 12 do
    APR.currentStep.questsList["01_NAVIGATION_PATH-bounded:" .. index] = { objectiveText = "bounded-row-" .. index }
end
APR:ExportStatusReport()
text = export.edit:GetText()
local _, rows = text:gsub("bounded%-row%-", "")
assert(rows <= 8 and text:find("**rowsTruncated**: true", 1, true), "Unexpected navigation rows are bounded")
APR.navigation.cursor = nil
APR:ExportStatusReport()
assert(export.edit:GetText():find("**arrivalRadius**: 17", 1, true),
    "The dump follows GetActiveStep's default cursor")
APR.navigation.queue = {}
APR.navigation.search = nil
APR.navigation.lastPlanning = { status = "ready", elapsedMilliseconds = 250, totalSliceMilliseconds = 8, slices = 12 }
APR:ExportStatusReport()
assert(export.edit:GetText():find("**ActiveStep**: nil", 1, true), "No active navigation step is explicit")
assert(export.edit:GetText():find("**elapsedMilliseconds**: 250", 1, true)
    and export.edit:GetText():find("**totalSliceMilliseconds**: 8", 1, true),
    "Completed planning timings remain available after its search graph is released")
APR.navigation, APR.GetZoneDetectionReport = nil, nil
APR:ExportStatusReport()
assert(export.edit:GetText():find("**ActiveStep**: nil", 1, true)
    and export.edit:GetText():find("**ZoneDetection**: nil", 1, true),
    "Exports still work when diagnostic modules are unavailable")
print("Status navigation: export-only, bounded, redacted snapshots preserve active and rendered state without routing")
