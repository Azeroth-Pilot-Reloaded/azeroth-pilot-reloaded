-- Every editable setting must survive the new navigation with its original callbacks and constraints.
dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
GENERAL, OPTIONS = "General", "Options"
DISPLAY = "Display"
local oldLibStub = LibStub
local registered = {}
local config = {RegisterOptionsTable = function(_, name, options) registered[name] = options end}
local dialog = {AddToBlizOptions = function() error("Blizzard must not expose AceConfig subcategories") end}
function LibStub(name, ...)
    if name == "AceConfig-3.0" then return config end
    if name == "AceConfigDialog-3.0" then return dialog end
    if name == "AceDBOptions-3.0" then return {GetOptionsTable = function() return {type = "group", name = "Profiles", args = {}} end} end
    return oldLibStub(name, ...)
end
dofile("APR-Core/utils/TextStyleUtils.lua")
dofile("APR-Core/config/AboutData.lua")
dofile("APR-Core/config/Config.lua")
APR.title, APR.version = "APR", "test"
APR.GAME_VERSIONS = {Forever = "Forever"}
function APR:GetGameVersion() return "Retail" end
function APR:IsRemixCharacter() return false end
APR.settings.profile = {}
APR.routeconfig = {InitRouteConfig = function() return {} end}
Settings = {RegisterCanvasLayoutCategory = function() return {ID = 1} end}
APR.settings:createBlizzOptions()
dofile("APR-Core/config/WorkspaceOptions.lua")
local sections = APR.WorkspaceOptions:Build(APR.settings)
local rendered = {}
local function walk(option, callback, path)
    if option.args then
        for key, child in pairs(option.args) do walk(child, callback, (path or "") .. "/" .. key) end
    elseif option.type ~= "header" and option.type ~= "description" then callback(option, path) end
end
local function retain(option, path) rendered[#rendered + 1] = {option = option, key = path:match("([^/]+)$")} end
retain(APR.WorkspaceOptions:ResetAction(APR.settings), "/resetButton")
for _, section in ipairs(sections) do
    for _, view in ipairs(APR.WorkspaceOptions:Views(section)) do
        walk(view.options, retain)
        for _, action in ipairs(view.actions or {}) do retain(action.option, "/" .. action.key) end
    end
    for _, action in ipairs(section.actions or {}) do retain(action.option, "/" .. action.key) end
end
local count = 0
walk(APR.settings.optionsTable, function(option, path)
    -- These actions have moved to top-level Status and the release-notes category itself.
    if path == "/statusButton" or path == "/group_Debug/subgroup_Enable/resetPartyPosition"
        or path == "/discordButton" or path == "/githubButton" then return end
    local found, matches = nil, 0
    for _, entry in ipairs(rendered) do
        if entry.key == path:match("([^/]+)$") and entry.option.name == option.name
            and entry.option.get == option.get and entry.option.set == option.set and entry.option.func == option.func then
            found = entry.option
            matches = matches + 1
        end
    end
    assert(found, "Missing setting/action: " .. path)
    assert(matches == 1, "Duplicated setting/action: " .. path)
    for _, key in ipairs({"disabled", "hidden", "confirm", "confirmText", "values", "min", "max", "step"}) do
        assert(found[key] == option[key], "Lost constraint " .. key .. ": " .. path)
    end
    count = count + 1
end)
assert(count > 120, "The complete settings schema must be checked")
local expectedOrder = {"automation", "group_Current_Step", "group_FillersFrame", "group_quest_order_list_step",
    "group_Arrow", "group_map_minimap", "group_AFK", "group_Group", "group_Heirloom", "group_XP_Buff",
    "appearance", "profiles", "changelog", "debug"}
assert(#sections == #expectedOrder)
for index, id in ipairs(expectedOrder) do assert(sections[index].id == id, "Unexpected category order at " .. index) end
local expectedViews = {
    automation = {"main", "subgroup_waypoints", "group_gossip_automation", "group_reward_automation"},
    group_Current_Step = {"subgroup_CurrentStep", "placement", "currentStepTextAppearance"},
    group_quest_order_list_step = {"subgroup_QuestOrderList", "questOrderListTextAppearance"},
    group_Arrow = {"subgroup_Arrow", "arrowTextAppearance"},
    group_map_minimap = {"group_map", "group_minimap", "group_map_color"},
    group_AFK = {"subgroup_AFK", "afkTextAppearance"},
    group_Group = {"subgroup_Group", "partyTextAppearance"},
    group_Heirloom = {"general", "heirloomTextAppearance"},
    appearance = {"theme", "group_GlobalTextAppearance"},
}
local panels, categories = {}, {}
for _, section in ipairs(sections) do
    categories[section.id] = section
    panels[section.id] = {}
    local views = APR.WorkspaceOptions:Views(section)
    local expected = expectedViews[section.id] or {"general"}
    assert(#views == #expected, "Unexpected number of tabs in " .. section.id)
    for index, view in ipairs(views) do
        assert(view.id == expected[index], "Unexpected tab order in " .. section.id)
        panels[section.id][view.id] = view
        local function inlineOnly(options)
            for _, option in pairs(options.args or {}) do
                if option.args then assert(option.inline, "No third level of tabs"); inlineOnly(option) end
            end
        end
        inlineOnly(view.options)
    end
end
local current = categories.group_Current_Step
assert(not current.options.args.subgroup_FillersFrame, "Secondary objectives have their own category")
assert(not current.actions and panels.group_Current_Step.placement.options.args.resetCurrentStepPosition,
    "Placement reset belongs at the bottom of the placement tab")
assert(panels.group_Heirloom.general.options.disabled == APR.settings.optionsTable.args.group_Heirloom.disabled,
    "Moving a group must preserve inherited restrictions")
local fillerView = panels.group_FillersFrame.general
local fillerReset = fillerView.options.args.fillersFrameResetPosition
APR.settings.profile.fillersFrameSnapToCurrentStep = true
assert(fillerReset.disabled(), "An attached filler cannot have its position reset")
APR.settings.profile.fillersFrameSnapToCurrentStep = false
assert(not fillerReset.disabled(), "A detached filler can have its position reset")
assert(not categories.general and not categories.tracking and not categories.navigation and not categories.progression)
local combined = panels.automation.main.options.args
local automation = combined.quests.args
assert(combined.quests.inline and combined.comfort.inline and combined.comfort.args.autoRepair,
    "Principal and advanced automation share a page with separate boxes")
assert(automation.pickupQuestLookahead and automation.sojournerSkipCampaign,
    "Quest preferences belong with quests, not gameplay convenience")
local afkSection = categories.group_AFK
assert(afkSection.actions[1].key == "afkFakeTimer" and not panels.group_AFK.subgroup_AFK.options.args.afkFakeTimer)
APR.AFK = {ToggleFakeTimer = function(self) self.fakeTimerActive = not self.fakeTimerActive end}
local action = afkSection.actions[1].option
local before = action.name()
action.func()
assert(before ~= action.name(), "AFK header action keeps its dynamic start/stop label")
local args = panels.debug.general.options.args
for key, option in pairs(args) do
    if key ~= "enableAddon" then assert(args.enableAddon.order < option.order, "Activation is first in Debug") end
end
local appearance = categories.appearance
assert(#appearance.actions == 1 and appearance.actions[1].key == "layoutEditor")
local launched = false
APR.LayoutEditor = {ShowFromSettings = function() launched = true end}
appearance.actions[1].option.func()
assert(launched, "Placement uses the safe settings entry point")
local xp = panels.group_XP_Buff.general.options.args
assert(xp.showXPBuffOverlay and xp.xpBonusSelection, "XP keeps its own category and all preferences")
local arrowStyle = panels.group_Arrow.subgroup_Arrow.options.args.arrowStyle
local restyles = 0
APR.Arrow = {ApplyStyle = function() restyles = restyles + 1 end}
assert(arrowStyle.get() == "classic")
arrowStyle.set({"arrowStyle"}, "apr")
assert(APR.settings.profile.arrowStyle == "apr" and arrowStyle.get() == "apr" and restyles == 1)
arrowStyle.set({"arrowStyle"}, "classic")
assert(APR.settings.profile.arrowStyle == "classic" and restyles == 2, "The style changes immediately in both directions")
local arrowOptions = panels.group_Arrow.subgroup_Arrow.options.args
local resized = 0
function APR.Arrow:GetTextScale()
    local profile = APR.settings.profile
    if profile.arrowTextScale == nil then profile.arrowTextScale = profile.arrowScale or 1 end
    return profile.arrowTextScale
end
function APR.Arrow:ApplySize() resized = resized + 1 end
APR.settings.profile.arrowScale = 2
arrowOptions.arrowScale.set({"arrowScale"}, 1.5)
assert(APR.settings.profile.arrowScale == 1.5 and arrowOptions.arrowTextScale.get() == 2,
    "Changing artwork size first retains the legacy text size before storing the new arrow size")
arrowOptions.arrowTextScale.set({"arrowTextScale"}, 1.25)
assert(APR.settings.profile.arrowScale == 1.5 and APR.settings.profile.arrowTextScale == 1.25 and resized == 2)
assert(arrowOptions.arrowScale.order < arrowOptions.arrowTextScale.order
    and arrowOptions.arrowTextScale.order < arrowOptions.arrowFPS.order,
    "Arrow and text size controls are adjacent")
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
APR.ArrowFrameM = CreateFrame("Frame")
arrowOptions.arrowReset.func()
assert(APR.settings.profile.arrowScale == 1 and APR.settings.profile.arrowTextScale == 1 and resized == 3,
    "Arrow reset restores both independent sizes")

-- A single theme choice retains existing saved flags and only offers loaded integrations.
local skin = panels.appearance.theme.options.args.uiSkin
local reloads = 0
function ReloadUI() reloads = reloads + 1 end
assert(skin.get() == "wow" and skin.values().wow and not skin.values().ElvUI and not skin.values().EllesmereUI)
ElvUI, EllesmereUI = {}, {RegisterSkin = function() end}
assert(skin.get() == "ElvUI" and skin.values().ElvUI and skin.values().EllesmereUI)
assert(skin.confirm and skin.confirmText, "Switching providers requires the existing reload confirmation flow")
skin.set(nil, "EllesmereUI")
assert(reloads == 1 and not APR.settings.profile.elvuiSkin and APR.settings.profile.ellesmereuiSkin)
assert(skin.get() == "EllesmereUI")
skin.set(nil, "ElvUI")
assert(skin.get() == "ElvUI" and APR.settings.profile.elvuiSkin and not APR.settings.profile.ellesmereuiSkin)
skin.set(nil, "wow")
assert(skin.get() == "wow" and not APR.settings.profile.elvuiSkin and not APR.settings.profile.ellesmereuiSkin)
ElvUI, EllesmereUI = nil, {}
assert(not skin.values().EllesmereUI, "An incompatible EllesmereUI version cannot be selected")
EllesmereUI = nil

-- Profile presentation must preserve inherited AceDB string handlers and confirmation semantics.
local profileHandler = {GetCurrentProfile = function() return "Default" end}
local function currentProfile(info) return "Current: " .. info.handler:GetCurrentProfile() end
local validate = function(_, text) return #text > 0 end
local profileSource = {type = "group", name = "Profiles", handler = profileHandler, args = {
    current = {type = "description", name = currentProfile},
    descreset = {type = "description", name = "Restore the current profile to its defaults."},
    choose = {type = "select", name = "Existing", get = "GetCurrentProfile", set = "SetProfile", values = "ListProfiles", arg = "common"},
    new = {type = "input", name = "New", set = "SetProfile", validate = validate},
    copyfrom = {type = "select", name = "Copy", set = "CopyProfile", values = "ListProfiles", arg = "nocurrent", disabled = "HasNoProfiles"},
    delete = {type = "select", name = "Delete", set = "DeleteProfile", values = "ListProfiles", arg = "nocurrent", confirm = true, confirmText = "Delete?"},
    reset = {type = "execute", name = "Reset", func = "Reset", order = 10},
    reset_all_profiles = APR.settings.profileOptions.args.reset_all_profiles,
}}
APR.settings.profileOptions = profileSource
for _, section in ipairs(APR.WorkspaceOptions:Build(APR.settings)) do
    if section.id == "profiles" then
        local views = APR.WorkspaceOptions:Views(section)
        assert(#views == 1 and views[1].options.handler == profileHandler)
        local groups = views[1].options.args
        assert(groups.active.name({handler = profileHandler}) == "Current: Default")
        local found = {}
        walk(views[1].options, function(option, path) found[path:match("([^/]+)$")] = option end)
        for key, original in pairs(profileSource.args) do
            if original.type ~= "description" then
                local option = assert(found[key], "Missing profile action: " .. key)
                for _, field in ipairs({"get", "set", "func", "arg", "values", "validate", "disabled", "confirm", "confirmText"}) do
                    assert(option[field] == original[field], "Lost profile behavior: " .. key .. "/" .. field)
                end
            end
        end
        assert(found.reset.width == "full" and found.reset.dialogControl == "APRSettingsAction")
        assert(found.reset_all_profiles.width == "full" and found.reset_all_profiles.dialogControl == "APRSettingsAction")
        assert(found.reset_all_profiles.desc == found.reset_all_profiles.confirmText:match("[^\r\n]+"),
            "The effect on all profiles is explained before the confirmation")
        assert(not profileSource.args.reset.dialogControl and profileSource.args.reset.order == 10,
            "The AceDB schema must not be mutated")
    end
end
local resets = {resetCurrentStepPosition = true, fillersFrameResetPosition = true,
    arrowReset = true, afkResetPosition = true, resetPartyPosition = true}
local resetCount = 0
local function checkSpacing(option)
    for key, child in pairs(option.args or {}) do
        if resets[key] then
            resetCount = resetCount + 1
            local spacer = option.args[key .. "Spacing"]
            assert(spacer and spacer.width == "full" and spacer.order < child.order)
            for otherKey, other in pairs(option.args) do
                if otherKey ~= key then assert(other.order < child.order, "Reset must follow all settings") end
            end
        end
        checkSpacing(child)
    end
end
for _, section in ipairs(sections) do
    for _, view in ipairs(APR.WorkspaceOptions:Views(section)) do checkSpacing(view.options) end
end
assert(resetCount == 6, "Every position reset is checked")

automation.autoAccept.set({"autoAccept"}, true)
assert(APR.settings.profile.autoAccept and APR.settings.profile.autoAcceptQuestRoute == false)
automation.autoAcceptQuestRoute.set({"autoAcceptQuestRoute"}, true)
assert(APR.settings.profile.autoAcceptQuestRoute and APR.settings.profile.autoAccept == false)
local waypoints = panels.automation.subgroup_waypoints.options.args
waypoints.autoSkipAllWaypoints.set({"autoSkipAllWaypoints"}, true)
assert(APR.settings.profile.autoSkipAllWaypoints and APR.settings.profile.autoSkipWaypointsFly == false)
waypoints.autoSkipWaypointsFly.set({"autoSkipWaypointsFly"}, true)
assert(APR.settings.profile.autoSkipWaypointsFly and APR.settings.profile.autoSkipAllWaypoints == false)
assert(APR.settings.optionsTable.args.group_Debug.args.subgroup_Enable.args.showChangeLog,
    "Building the views cannot mutate the native schema")
assert(APR.settings.optionsTable.args.group_Advanced_Automation.args.subgroup_waypoints,
    "Moving automation cannot remove it from the native options schema")
print("Workspace options: " .. count .. " settings/actions retained; original mutual exclusions and definitions preserved")

-- Exercise the real navigation controller: moved categories still resolve to their panels,
-- category changes retain the last tab and contextual actions do not leak to another page.
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/ui/panels/Workspace.lua")
function APR:RegisterSupportedEvent(frame, event) frame:RegisterEvent(event) end
function APR.UI:SettingsHost(parent)
    return {frame = CreateFrame("Frame", nil, parent), data = {}, callbacks = {},
        SetCallback = function(self, event, callback) self.callbacks[event] = callback end,
        SetUserData = function(self, key, value) self.data[key] = value end,
        ReleaseChildren = function() end}
end
local opened
function dialog:Open(app, host)
    opened = app
    host:SetUserData("appName", app)
    host.callbacks.OnOptionsRefreshed()
end
dofile("APR-Core/ui/panels/OptionsPanel.lua")
local panel = APR.OptionsPanel
panel:Create(UIParent)
panel.body:SetSize(760, 600)
APR.settings.profile.enableAddon = true
panel.frame.scripts.OnShow()
assert(panel.selected == "automation" and panel.view.id == "main", "Options opens on Automation")
local resetButton = panel.resetButton
local resetPoint, resetParent, resetRelativePoint, resetX, resetY = unpack(resetButton.point)
local confirmedReset, resetCount = nil, 0
APR.questionDialog = {CreateQuestionPopup = function(_, key, _, accept)
    assert(key == "RESET_SETTINGS"); confirmedReset = accept
end}
function APR.settings:ResetSettings() resetCount = resetCount + 1 end
resetButton.scripts.OnClick(resetButton)
assert(confirmedReset and resetCount == 0, "The persistent reset still asks before modifying settings")
confirmedReset()
assert(resetCount == 1)
panel:Select("group_AFK")
assert(panel.selected == "group_AFK" and panel.view.id == "subgroup_AFK")
assert(opened:find("/group_AFK/subgroup_AFK$"))
local testButton = panel.actionButtons[1]
assert(testButton:IsShown() and testButton:IsEnabled())
local previousText = testButton:GetText()
testButton.scripts.OnClick(testButton)
assert(testButton:GetText() ~= previousText, "The AFK action refreshes its start/stop label in its new category")
panel:SelectView("afkTextAppearance")
assert(testButton:IsShown(), "The AFK preview remains available while adjusting its typography")
panel:Select("group_XP_Buff")
assert(panel.view.id == "general" and not testButton:IsShown())
panel:Select("group_AFK")
assert(panel.view.id == "afkTextAppearance" and testButton:IsShown(), "Returning restores the last tab and its actions")
panel:Select("group_FillersFrame")
assert(panel.selected == "group_FillersFrame" and not testButton:IsShown())
panel:Select("group_Arrow")
assert(panel.selected == "group_Arrow" and panel.view.id == "subgroup_Arrow")
panel:Select("automation")
panel:SelectView("subgroup_waypoints")
panel:Select("group_map_minimap")
assert(panel.selected == "group_map_minimap" and #panel.section.views == 3,
    "Map and minimap retain their separate category")
panel:SelectView("group_minimap")
panel:Select("automation")
assert(panel.view.id == "subgroup_waypoints")
panel:Select("group_map_minimap")
assert(panel.view.id == "group_minimap")
panel:Select("appearance")
assert(panel.view.id == "theme" and testButton:IsShown())
panel:SelectView("group_GlobalTextAppearance")
testButton.scripts.OnClick(testButton)
assert(launched and testButton:IsShown(), "Placement remains available across Appearance tabs")
-- Check the same reset button on every category, including the custom release-notes page.
APR.ReleaseNotesPanel = {Create = function() return {Show = function() end, Hide = function() end} end}
for _, section in ipairs(panel.sections) do
    panel:Select(section.id)
    for _, view in ipairs(section.views) do
        panel:SelectView(view.id)
        local point, parent, relativePoint, x, y = unpack(resetButton.point)
        assert(resetButton == panel.resetButton and resetButton:IsShown() and resetButton:IsEnabled())
        assert(point == resetPoint and parent == resetParent and relativePoint == resetRelativePoint
            and x == resetX and y == resetY, "Reset moves between option pages")
    end
end
print("Options navigation: standalone categories, remembered tabs, persistent reset and contextual actions passed")
