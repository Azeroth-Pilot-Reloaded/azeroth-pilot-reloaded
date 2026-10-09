-- About reflects loaded metadata and the live command list without generating effective routes.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/core/Commands.lua")
dofile("APR-Core/config/AboutData.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/panels/Workspace.lua")
dofile("APR-Core/ui/panels/AboutPanel.lua")
FRFR, DEDE, ESMX, RURU = "French", "German", "Spanish", "Russian"
APR.version, APR.title = "@project-version@", "APR"
APR.github, APR.discord = "https://github.com/example/apr", "https://discord.gg/example"
function APR:GetGameVersion() return "retail" end
function GetBuildInfo() return "12.1.5" end
APR.RouteQuestStepList = {
    default = {steps = {}, expansion = "One"},
    community = {steps = {}, expansion = "One", author = "Route author"},
    other = {steps = {}, expansion = "Two", author = "Route author"},
    unfinished = {steps = {}, author = "Other author"},
    invalid = true,
}
function APR:GetRouteSteps() error("About must not build an effective route") end
local count, expansions, authors = APR.AboutData:GetRouteSummary()
assert(count == 4 and expansions == 2 and authors == "Other author, Route author")
APR.AboutPanel:Create(UIParent)
APR.AboutPanel:Refresh()
local about = APR.AboutPanel
assert(not about.version:GetText():find("@project-version@", 1, true))
local rows = #about.credits.rows
APR.RouteQuestStepList.community.author = "Updated author"
for _ = 1, 20 do about:Refresh(); about:SetPage("commands"); about:SetPage("guide") end
assert(#about.credits.rows == rows, "Refreshing metadata must reuse the text rows")
assert(about.credits.rows[rows].text:GetText():find("Updated author", 1, true))
about:SetPage("commands")
for index, entry in ipairs(APR.command:GetHelpEntries()) do
    assert(about.help.rows[index].title:GetText() == entry[1])
    assert(about.help.rows[index].text:GetText() == entry[2])
end
local originalHelp = APR.command.GetHelpEntries
APR.command.GetHelpEntries = function() return {{"/apr example", "Updated help"}} end
about:SetPage("commands")
assert(about.help.rows[1].title:GetText() == "/apr example" and not about.help.rows[2]:IsShown(),
    "About must consume the command source instead of preserving a stale copy")
APR.command.GetHelpEntries = originalHelp

local diagnostic = 'message = "unexpected ``` in input"'
APR.UI:ShowTextReport("Error", diagnostic, about.frame, "lua")
local report = APR.UI.reportWindow
assert(report.edit:GetText() == "````lua\n" .. diagnostic .. "\n````",
    "Backticks in a diagnostic must not terminate its code block")
APR.settings.profile.enableAddon = true
for _, command in ipairs({"discord", "github"}) do
    report.edit:ClearFocus()
    report.edit.highlighted = false
    APR.command:SlashCmd(command)
    assert(APR.UI.reportWindow == report and report.edit:GetText() == APR[command],
        "Link commands reuse the report window with a plain URL, without diagnostic fences")
    assert(report.edit:HasFocus() and report.edit.highlighted,
        "Each link is selected for copying even when the report window is already open")
end
report:Hide()
report.scripts.OnHide(report) -- This fixture invokes lifecycle scripts explicitly.
assert(not report.edit:HasFocus(), "Closing a copy window releases keyboard focus")
print("About: metadata counts, live authors, shared command help, row reuse and copy links passed")
