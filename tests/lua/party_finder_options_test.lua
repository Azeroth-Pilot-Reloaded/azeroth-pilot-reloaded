-- Finder settings have their own category and delegate to the same owner as quick controls.
dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
for _, key in ipairs({
    "GAMEOPTIONS_MENU", "LFG_LIST_SEARCH_AGAIN", "GROUP_INVITE", "WHISPER", "LANGUAGES_LABEL",
    "DEFAULT", "PREVIEW", "ENABLE_SOUND", "MASTER_VOLUME", "FX_VOLUME", "DIALOG_VOLUME",
    "ENABLE", "LFG_TITLE", "ALL", "NONE", "AUDIO_LABEL", "REQUEST_INVITE", "SECONDS",
}) do
    _G[key] = "Native:" .. key
end
dofile("APR-Core/integrations/SkinRegistry.lua")
GENERAL, OPTIONS, DISPLAY = "General", "Options", "Display"
local oldLibStub = LibStub
local registered = {}
function LibStub(name, ...)
    if name == "AceConfig-3.0" then
        return { RegisterOptionsTable = function(_, key, options) registered[key] = options end }
    elseif name == "AceDBOptions-3.0" then
        return { GetOptionsTable = function() return { type = "group", name = "Profiles", args = {} } end }
    end
    return oldLibStub(name, ...)
end
dofile("APR-Core/utils/TextStyleUtils.lua")
dofile("APR-Core/config/AboutData.lua")
dofile("APR-Core/config/Config_GroupFinder.lua")
dofile("APR-Core/features/group/PartyFinderProtocol.lua")
dofile("APR-Core/config/Config.lua")

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end
local defaults = APR.GroupFinderDefaults
assert(defaults.visible and defaults.enabled and defaults.showButton and defaults.showBadge)
assert(not defaults.autoScan and not defaults.notifications and defaults.recruiting)
assert(defaults.matchMode == "nearby" and defaults.stepRange == 5)
assert(not next(defaults.languages) and not next(defaults.blockedLanguages) and not next(defaults.visibleLanguages))
assert(defaults.sounds.match.enabled and not defaults.sounds.received.enabled,
    "Optional discovery sounds and native invitation sounds have distinct defaults")
assert(defaults.sounds.sent == nil, "Sending an invitation has no configurable audio event")

APR.title, APR.version = "APR", "synthetic"
APR.settings.profile = { enableAddon = true, groupFinder = copy(defaults) }
APR.routeconfig = { InitRouteConfig = function() return {} end }
Settings = { RegisterCanvasLayoutCategory = function() return { ID = 1 } end }
function APR:IsRemixCharacter() return false end
APR.settings:createBlizzOptions()
local originalGroup = APR.settings.optionsTable.args.group_Group
assert(originalGroup.args.subgroup_Group and originalGroup.args.partyTextAppearance,
    "Existing group progress and appearance controls remain available")
local finderOptions = APR.settings.optionsTable.args.groupFinder
assert(finderOptions and not originalGroup.args.groupFinder and registered.APR == APR.settings.optionsTable)
local generalOptions = finderOptions.args.general.args.general

-- Legacy initialization can expose the definitions before the controller is ready.
assert(generalOptions.args.enabled.disabled())
generalOptions.args.visible.set({ "visible" }, false)
assert(defaults.visible, "Missing owner must not mutate shared defaults")

local calls, refreshes, previews = {}, 0, 0
APR.partyFinder = {
    GetSettings = function() return APR.settings.profile.groupFinder end,
    GetLanguageValues = function() return { en = "First", fr = "Second" } end,
    GetSoundChoices = function() return { default = "Default", example = "Example" } end,
    SetOption = function(_, key, value)
        calls[#calls + 1] = { kind = "option", key = key, value = value }
        APR.settings.profile.groupFinder[key] = value
    end,
    SetLanguageOption = function(_, field, code, value)
        calls[#calls + 1] = { kind = "language", key = field, code = code, value = value }
        APR.settings.profile.groupFinder[field][code] = value or nil
    end,
    SetSoundOption = function(_, event, key, value)
        calls[#calls + 1] = { kind = "sound", event = event, key = key, value = value }
        APR.settings.profile.groupFinder.sounds[event][key] = value
    end,
    PreviewSound = function(_, event) assert(event == "declined"); previews = previews + 1 end,
    RefreshSettings = function() refreshes = refreshes + 1 end,
}
local general = generalOptions.args
assert(not general.enabled.disabled())
general.autoScan.set({ "autoScan" }, true)
assert(calls[#calls].key == "autoScan" and general.autoScan.get({ "autoScan" }))
general.visible.set({ "visible" }, false)
assert(not general.visible.get({ "visible" }) and general.autoScan.get({ "autoScan" }),
    "Visibility and automatic scanning remain independent")
general.enabled.set({ "enabled" }, false)
assert(not general.enabled.disabled() and general.visible.disabled(),
    "The master control stays usable when the feature is disabled")
general.enabled.set({ "enabled" }, true)

local criteria = finderOptions.args.general.args.criteria.args
criteria.matchMode.set({ "matchMode" }, "step")
assert(criteria.stepRange.disabled(), "A nearby-step margin is irrelevant to exact-step matching")
criteria.matchMode.set({ "matchMode" }, "nearby")
assert(not criteria.stepRange.disabled())
criteria.minLevel.set({ "minLevel" }, 7)
criteria.maxLevel.set({ "maxLevel" }, 19)
assert(APR.settings.profile.groupFinder.minLevel == 7 and APR.settings.profile.groupFinder.maxLevel == 19)

local languages = finderOptions.args.languages.args
assert(languages.languages.arg.aprEmptyText == ALL and languages.visibleLanguages.arg.aprEmptyText == ALL
    and languages.spokenLanguages.arg.aprEmptyText == NONE and languages.blockedLanguages.arg.aprEmptyText == NONE,
    "Empty language controls distinguish unrestricted discovery from no declared or blocked languages")
local locale = "frFR"
function GetLocale() return locale end
assert(languages.primaryLanguage.get({"primaryLanguage"}) == "fr"
    and APR.settings.profile.groupFinder.primaryLanguage == "",
    "The client language is preselected without turning automatic inference into a saved declaration")
locale = "enGB"
assert(languages.primaryLanguage.get({"primaryLanguage"}) == "en")
locale = "ptBR"
assert(languages.primaryLanguage.get({"primaryLanguage"}) == "pt")
languages.languages.set({}, "fr", true)
assert(languages.languages.get({}, "fr") and not languages.blockedLanguages.get({}, "fr")
    and not languages.visibleLanguages.get({}, "fr"), "The three language policies are separate")
languages.visibleLanguages.set({}, "en", true)
languages.blockedLanguages.set({}, "en", true)
languages.spokenLanguages.set({}, "fr", true)
languages.primaryLanguage.set({ "primaryLanguage" }, "en")
assert(calls[#calls].kind == "option" and calls[#calls].key == "primaryLanguage")
assert(languages.primaryLanguage.get({"primaryLanguage"}) == "en",
    "An explicit language selection takes precedence over the client language")
assert(languages.languages.values().fr == "Second")

local notification = finderOptions.args.notifications.args.notifications.args
assert(notification.notificationCooldown == nil, "Notification timing is not exposed in settings")
notification.notifications.set({ "notifications" }, true)
assert(notification.notifications.get({"notifications"})
    and APR.settings.profile.groupFinder.notificationCooldown == defaults.notificationCooldown,
    "Removing timing controls preserves the internal notification safeguards")

local sounds = finderOptions.args.notifications.args.sounds.args
assert(sounds.sent == nil, "The invitation-sent sound card is absent")
local declined = sounds.declined.args
notification.notifications.set({"notifications"}, false)
assert(sounds.match.args.enabled.disabled() and sounds.match.args.sound.disabled()
    and not declined.enabled.disabled(),
    "Discovery audio must not appear active while discovery notifications are disabled; invitation sounds remain independent")
notification.notifications.set({"notifications"}, true)
assert(not sounds.match.args.enabled.disabled() and not sounds.match.args.sound.disabled())
declined.enabled.set({ "enabled" }, true)
declined.sound.set({ "sound" }, "example")
declined.preview.func()
assert(previews == 1 and declined.sound.get({ "sound" }) == "example")
assert(calls[#calls].event == "declined" and calls[#calls].key == "sound" and calls[#calls].value == "example")
sounds.soundEnabled.set({ "soundEnabled" }, false)
assert(declined.enabled.disabled() and declined.sound.disabled())

-- Finder navigation is separate from party progress, with only the requested three tabs.
dofile("APR-Core/config/WorkspaceOptions.lua")
local section
for _, entry in ipairs(APR.WorkspaceOptions:Build(APR.settings)) do
    if entry.id == "groupFinder" then section = entry end
end
local views = APR.WorkspaceOptions:Views(section)
assert(#views == 3 and views[1].id == "general" and views[2].id == "languages" and views[3].id == "notifications")
assert(views[1].options.args.general.args.autoScan.set == general.autoScan.set
    and views[1].options.args.criteria.args.matchMode.set == criteria.matchMode.set,
    "The workspace retains the exact authoritative callbacks")
local renderedSounds = views[3].options.args.sounds.args
assert(renderedSounds.declined.args.sound.set == declined.sound.set)
assert(renderedSounds.sent == nil, "Workspace rendering cannot restore the removed audio card")
local cardCount = 0
for _, option in pairs(renderedSounds) do
    if option.arg and option.arg.aprSoundCard then cardCount = cardCount + 1 end
end
assert(cardCount == 6, "Only the six remaining sound events render as cards")
for _, event in ipairs({"match", "received", "joined", "declined", "expired", "error"}) do
    local card = renderedSounds[event]
    assert(card.arg.aprSoundCard and card.args.sound.arg.aprSoundEvent == event,
        "Sound cards identify their group without relying on translated titles")
    assert(card.args.sound.dialogControl == "APRSettingsSoundSelect",
        "Sound catalogs use the bounded dropdown rather than an eager AceGUI menu")
    assert(card.args.enabled.order < card.args.preview.order and card.args.preview.order < card.args.sound.order,
        "Each sound card places enable/preview above its sound selector")
    assert(card.args.enabled.arg.aprSoundWidth + card.args.preview.arg.aprSoundWidth == 1)
    assert(card.args.sound.arg.aprSoundWidth == 1 and card.args.cooldown == nil,
        "Every sound selector uses the full card width without a duration control")
    for key, option in pairs(renderedSounds[event].args) do
        assert(option.arg.aprInline and option.arg.aprSoundEvent == event
            and type(option.width) == "number" and option.width > 0 and option.width <= 1,
            "Sound controls retain responsive inline widths through workspace copying")
        assert(option.width == sounds[event].args[key].width
            and option.arg.aprSoundWidth == sounds[event].args[key].arg.aprSoundWidth)
    end
end

local reloads = 0
function APR:RequestReload() reloads = reloads + 1 end
APR.settings.db = { profile = { enableAddon = true, groupFinder = copy(defaults) } }
APR.settings.db.profile.groupFinder.recruiting = false
APR.settings:RefreshProfile()
assert(refreshes == 1 and reloads == 1 and APR.settings.profile == APR.settings.db.profile,
    "Changing profiles immediately refreshes discovery before the normal reload flow")
assert(not general.recruiting.get({"recruiting"}), "An existing recruitment choice is preserved")
APR.settings.profile.enableAddon = false
assert(general.enabled.disabled(), "Disabling APR also disables its finder preferences")

-- Exercise the shipped AceConfig renderer rather than reproducing its multiselect branch.
-- Four language policies must stay four compact controls when the options form is rebuilt.
local rendered = {}
local renderer = {frame = {GetScript = function() end, SetScript = function() end}}
local controlMethods = {}
for _, method in ipairs({"SetLabel", "SetTitle", "SetLayout", "PauseLayout", "ResumeLayout", "DoLayout", "SetWidth"}) do
    controlMethods[method] = function() end
end
function controlMethods:SetUserData(key, value) self.user[key] = value end
function controlMethods:GetUserData(key) return self.user[key] end
function controlMethods:GetUserDataTable() return self.user end
function controlMethods:SetCallback(event, callback) self.callbacks[event] = callback end
function controlMethods:AddChild(child) self.children[#self.children + 1] = child end
function controlMethods:SetMultiselect(value) self.multiselect = value end
function controlMethods:SetList(values) self.values = values end
function controlMethods:SetDisabled(value) self.disabled = value end
function controlMethods:SetItemValue(key, value) self.items[key] = value end
function controlMethods:SetValue(value) self.value = value end
function controlMethods:SetTriState() end
function controlMethods:IsReleasing() return false end
local function Control(kind)
    return setmetatable({type = kind, user = {}, callbacks = {}, children = {}, items = {}}, {__index = controlMethods})
end
local gui = {Create = function(_, kind)
    local control = Control(kind)
    rendered[#rendered + 1] = control
    return control
end}
local savedLibStub = LibStub
LibStub = setmetatable({NewLibrary = function() return renderer end}, {__call = function(_, name)
    if name == "AceGUI-3.0" then return gui end
    assert(name == "AceConfigRegistry-3.0")
    return {RegisterCallback = function() end}
end})
table.wipe, strmatch = wipe, string.match
local originalXpcall = xpcall
function xpcall(callback, handler, ...)
    local args = {...}
    return originalXpcall(function() return callback(unpack(args)) end, handler)
end
dofile("APR-Core/libs/AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua")
LibStub, xpcall = savedLibStub, originalXpcall

APR.settings.profile = {enableAddon = true, groupFinder = copy(defaults)}
local syntheticLanguages = {a = "First", b = "Second", c = "Third", d = "Fourth", e = "Fifth",
    f = "Sixth", g = "Seventh", h = "Eighth", i = "Ninth", j = "Tenth"}
function APR.partyFinder:GetLanguageValues() return syntheticLanguages end
local languageOnly = {type = "group", name = "Synthetic language form", args = {}}
local policyFields = {"spokenLanguages", "languages", "blockedLanguages", "visibleLanguages"}
for _, field in ipairs(policyFields) do languageOnly.args[field] = languages[field] end
local host = Control("InlineGroup")
renderer:FeedGroup("SyntheticFinderOptions", languageOnly, host, host, {})
assert(#rendered == 4, "Ten choices in each language policy must render four controls, not forty checkboxes")
for _, control in ipairs(rendered) do
    assert(control.type == "Dropdown" and control.multiselect, "Compact language controls retain multiple selection")
    assert(control.values.a == "First" and control.values.j == "Tenth", "The full choice list remains available")
end

local display
for _, control in ipairs(rendered) do
    if control.user.option == languages.languages then display = control end
end
assert(display and not display.disabled)
-- AceConfig applies choices without rebuilding the form until the pullout closes.
local rebuilds = 0
function renderer:Open() rebuilds = rebuilds + 1 end
display.callbacks.OnValueChanged(display, "OnValueChanged", "a", true)
display.callbacks.OnValueChanged(display, "OnValueChanged", "c", true)
assert(APR.settings.profile.groupFinder.languages.a and APR.settings.profile.groupFinder.languages.c,
    "Selecting a second language must preserve the first selection")
assert(not next(APR.settings.profile.groupFinder.blockedLanguages), "Display choices must not change another policy")
assert(rebuilds == 0, "Changing choices inside an open language menu must not rebuild the settings form")
display.callbacks.OnClosed(display, "OnClosed")
assert(rebuilds == 1, "Closing a changed language menu refreshes dependent options once")

general.enabled.set({"enabled"}, false)
rendered, host = {}, Control("InlineGroup")
renderer:FeedGroup("SyntheticFinderOptions", languageOnly, host, host, {})
assert(#rendered == 4)
for _, control in ipairs(rendered) do assert(control.disabled, "Master disable propagates to compact language menus") end
general.enabled.set({"enabled"}, true)
rendered, host = {}, Control("InlineGroup")
renderer:FeedGroup("SyntheticFinderOptions", languageOnly, host, host, {})
assert(#rendered == 4)
for _, control in ipairs(rendered) do
    assert(not control.disabled, "Re-enabling restores each language menu")
    control.callbacks.OnClosed(control, "OnClosed")
end
assert(rebuilds == 1, "Closing an unchanged language menu must not rebuild the form")

print("Companion options: standalone category, compact controls, client language, shared callbacks and profile lifecycle passed")
