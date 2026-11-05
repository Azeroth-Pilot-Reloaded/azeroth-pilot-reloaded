-- Manual selection warns before any path or saved-progress mutation.
local env = dofile("tests/lua/route_browser_test_env.lua")
CONFIRM_CONTINUE = "Continue?"
APR.RouteQuestStepList = {
    advice = { label = "100% invented chapter", conditions = { MinLevel = 22, MaxLevel = 24 } },
    other = { label = "Another chapter", conditions = { MinLevel = 26 } },
}
APR.Level = 20
function APR:GetPlayerEffectiveLevel() return self.Level end
local catalog, rows = APR.RouteCatalog, APR.RouteBrowserRows
local popup, prompts, resets, checks, notifications = nil, 0, 0, 0, 0
local showConfirmation = APR.UI.ShowConfirmationDialog
function APR.UI:ShowConfirmationDialog(prompt, accept, cancel, owner)
    prompts = prompts + 1
    popup = { prompt = prompt, accept = accept, cancel = cancel, owner = owner }
end
function APR:ResetRoute(key) resets = resets + 1; APRData.test[key] = 1 end
function APR:CheckRouteChanges() checks = checks + 1 end
function APR.routeconfig:SendCustomPathUpdate() notifications = notifications + 1 end
local function record(key)
    for _, item in ipairs(catalog:Build()) do if item.key == key then return item end end
    error("Missing fixture")
end
local function clearPath() APRCustomPath.test = {} end
local function request(key, restart)
    assert(not catalog:ChangePath(record(key), "add", restart), "A warning defers the addition")
    return popup
end
APRData.test.advice = 7
local row = rows:Create(UIParent, {}, false)
row.item = record("advice")
rows:Bind(row, row.item, 1, {}, false)
assert(row.name:GetText() == "100% invented chapter" and row.name.role == "warning",
    "Warning color must not change the route's label")
row.add.scripts.OnClick()
assert(prompts == 1 and #APRCustomPath.test == 0 and checks == 0 and resets == 0 and notifications == 0)
local prompt = popup.prompt
assert(prompt.title == "100% invented chapter" and table.concat(prompt.details, "\n"):find(">= 22", 1, true)
    and prompt.description == "Continue?" and prompt.acceptText == ADD,
    "The popup separates the route, unmet level, question and explicit add action")
local cancelled = popup
cancelled.cancel()
cancelled.accept()
assert(#APRCustomPath.test == 0 and APRData.test.advice == 7 and checks == 0)
row.scripts.OnClick(row, "RightButton")
popup.accept()
assert(#APRCustomPath.test == 1 and APRCustomPath.test[1] == "100% invented chapter")
assert(checks == 1 and resets == 0 and notifications == 1 and APRData.test.advice == 7)
popup.accept()
assert(checks == 1 and notifications == 1, "A confirmation can only be consumed once")

-- Shift+add restarts only after acceptance, even if the modifier is released.
clearPath()
env.setShift(true)
row.add.scripts.OnClick()
env.setShift(false)
assert(resets == 0 and APRData.test.advice == 7)
popup.accept()
assert(resets == 1 and APRData.test.advice == 1 and #APRCustomPath.test == 1)

-- Re-evaluate the current level when clicked, including stale recycled records.
clearPath()
local previousPrompts = prompts
APR.Level = 23
assert(catalog:ChangePath(row.item, "add") and prompts == previousPrompts)
clearPath()
local matching = record("advice")
APR.Level = 20
assert(not catalog:ChangePath(matching, "add") and prompts == previousPrompts + 1)
popup.cancel()
APR.Level = 25
local above = request("advice")
assert(table.concat(above.prompt.details, "\n"):find("<= 24", 1, true))
above.accept()
assert(#APRCustomPath.test == 1)

-- Old dialogs cannot act for a different character, path, definition or profile.
APR.Level = 20
clearPath()
local stale = request("advice")
APR.PlayerID = "other-player"
stale.accept()
APR.PlayerID = "test"
stale.accept()
assert(#APRCustomPath.test == 0)
stale = request("advice")
clearPath()
stale.accept()
assert(#APRCustomPath.test == 0)
stale = request("advice")
local definition = APR.RouteQuestStepList.advice
APR.RouteQuestStepList.advice = { label = definition.label, conditions = { MinLevel = 28 } }
stale.accept()
assert(#APRCustomPath.test == 0)
APR.RouteQuestStepList.advice = definition
stale = request("advice")
local profile = APR.settings.profile
profile.enableAddon = false
stale.accept()
profile.enableAddon = true
assert(#APRCustomPath.test == 0)
stale = request("advice")
APR.settings.profile = {}
stale.accept()
APR.settings.profile = profile
assert(#APRCustomPath.test == 0)

-- Current availability and duplicates are checked again before any reset.
local previousResets = resets
stale = request("advice", true)
definition.visibility = "disabled"
stale.accept()
definition.visibility = nil
assert(#APRCustomPath.test == 0 and resets == previousResets)
stale = request("advice", true)
APRCustomPath.test[1] = definition.label
stale.accept()
assert(#APRCustomPath.test == 1 and resets == previousResets)
clearPath()
local first = request("advice")
local second = request("other")
first.cancel()
first.accept()
assert(#APRCustomPath.test == 0)
second.accept()
assert(#APRCustomPath.test == 1 and APRCustomPath.test[1] == "Another chapter")

-- Use the actual owned modal above a high-level main window, including combat.
APR.UI.ShowConfirmationDialog = showConfirmation
clearPath()
local main = APR.UI:Window("SyntheticRouteOwner", "Routes", 900, 700)
main:SetFrameLevel(900)
main:Show()
APR.Workspace = { frame = main }
env.setCombat(true)
assert(not catalog:ChangePath(record("advice"), "add"))
local dialog = APR.UI.selectionDialog
assert(main:GetFrameStrata() == "DIALOG" and dialog:GetFrameStrata() == "FULLSCREEN_DIALOG",
    "The warning must occupy a higher stratum even when the main window has a high frame level")
assert(dialog:IsShown() and dialog.confirming and dialog.point[2] == main)
assert(dialog.title:GetText():find("100% invented chapter", 1, true), "Owned text preserves literal percent signs")
assert(dialog.description:GetText() == "Continue?" and dialog.title.role == "base"
    and dialog.body:IsShown() and dialog.acceptButton:GetFontString():GetText() == ADD,
    "The route title is neutral, recommendations have their own body and the action says Add")
assert(#APRCustomPath.test == 0, "Bringing the modal forward never accepts the route")
dialog:Accept()
assert(#APRCustomPath.test == 1 and APRCustomPath.test[1] == "100% invented chapter")
env.setCombat(false)
print("Route level confirmation: actions, cancellation, stale contexts, single acceptance and foreground modal in combat passed")
