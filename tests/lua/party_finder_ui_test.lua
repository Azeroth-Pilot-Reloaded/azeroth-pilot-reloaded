-- Discovery controls share persisted state; only an explicit candidate-row action can invite.
local env = dofile("tests/lua/route_ui_test_env.lua")
local locale = dofile("tests/lua/localization_test_env.lua")
locale.GF_RESULT_COUNT, locale.GF_RESULTS_TOOLTIP = "%d results", "%d results"
locale.GF_LAST_SEEN, locale.GF_LEVEL_CLASS, locale.GF_GROUP_SIZE = "Age %d", "%d / %s", "%d slots"
locale.GF_MATCH_CRITERIA, locale.GF_INVITE_CONTEXT = "%s / %s", "%s / %s"
GAMEOPTIONS_MENU = "Options"
ALL, LANGUAGES_LABEL, LFG_LIST_SEARCH_AGAIN = "All entries", "Languages", "Refresh"
GROUP_INVITE, REQUEST_INVITE, WHISPER = "Invite", "Request", "Whisper"
UIParent:SetSize(1920, 1080)
function env.methods:SetChecked(value) self.checked = value end
function env.methods:GetChecked() return self.checked end
function env.methods:SetAtlas(value) self.atlas = value end
function env.methods:SetJustifyH(value) self.justifyH = value end
function env.methods:SetJustifyV(value) self.justifyV = value end
local setPoint = env.methods.SetPoint
function env.methods:SetPoint(...)
    setPoint(self, ...)
    self.points = self.points or {}
    self.points[select(1, ...)] = {...}
end
function env.methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function env.methods:RegisterEvent(event)
    self.events = self.events or {}
    self.events[event] = true
    self.eventRegistrations = (self.eventRegistrations or 0) + 1
end
function env.methods:UnregisterEvent(event)
    if self.events then self.events[event] = nil end
end
function env.methods:GetBottom() return 700 end
function env.methods:GetTop() return 730 end
function env.methods:IsMouseOver() return self.mouseOver == true end
function GetTime() return 100 end
local timers = {}
C_Timer = {NewTimer = function(delay, callback)
    local timer = {delay = delay, callback = callback}
    function timer:Cancel() self.cancelled = true end
    timers[#timers + 1] = timer
    return timer
end}
APR.title = "Example"
APR.settings.profile.enableAddon = true
local settings = {enabled = true, visible = true, autoScan = false, showButton = true, showBadge = true,
    languages = {}, matchMode = "nearby"}
local candidates = {
    {key = "Alpha-Realm", name = "Alpha", primary = "fr", spokenLanguages = {"fr", "en"},
        level = 15, class = 3, groupSize = 0, seenAt = 80, languageSource = "player"},
    {key = "Bravo-Realm", name = "Bravo", primary = "en", spokenLanguages = {"en"},
        level = 17, class = 2, groupSize = 3, leader = true, recruiting = true, seenAt = 90},
    {key = "Charlie-Realm", name = "Charlie", spokenLanguages = {},
        level = 19, class = 1, groupSize = 0, pending = true, seenAt = 95},
}
local calls, scanCount, status = {}, 0, "ready"
local function call(kind, key) calls[#calls + 1] = {kind = kind, key = key} end
APR.partyFinder = {
    GetSettings = function() return settings end,
    SetOption = function(_, key, value) settings[key] = value; call("option", key) end,
    GetLanguageValues = function() return {en = "English", fr = "French"} end,
    SetLanguageFilter = function(_, code, enabled) settings.languages[code] = enabled or nil; call("language", code) end,
    Search = function() scanCount = scanCount + 1; return true end,
    GetCandidates = function() return candidates end,
    GetCount = function() return #candidates end,
    GetStatus = function() return status end,
    GetRouteLabel = function() error("The companion window must not look up the current route label") end,
    GetCandidateDescription = function(_, candidate) return candidate.key or "Context" end,
    CanInvite = function(_, candidate) return not candidate.pending, candidate.pending and "Pending" or nil end,
    Invite = function(_, key) call("invite", key) end,
    RequestInvite = function(_, key) call("request", key) end,
    Whisper = function(_, key) call("whisper", key) end,
    OpenSettings = function() call("configure") end,
    OpenBlizzard = function() error("Companions must only search for and group APR players") end,
}
APR.PartyFinderProtocol = {LanguageAtlas = function(code)
    return ({fr = "Lang-Regions-frFR", en = "Lang-Regions-enUS"})[code]
end}
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/ui/panels/Workspace.lua")
dofile("APR-Core/ui/panels/PartyFinderPanel.lua")
local panel = APR.PartyFinderPanel

-- An incoming native invitation can acquire context before the main window exists.
panel:ShowInviteContext({name = "Inviter", description = "Example step"})
assert(panel.inviteContext:IsShown() and not APR.Workspace.frame)
assert(panel.inviteContext.text:GetText() == "Inviter / Example step")
local firstTimer = panel.inviteTimer
panel:ShowInviteContext({name = "Other", description = "Second step"})
assert(firstTimer.cancelled and panel.inviteTimer.delay == 30)
panel:HideInviteContext()
assert(not panel.inviteContext:IsShown() and not panel.inviteTimer)
assert(#calls == 0, "Context display has no invitation, acceptance or chat action")

panel:Create(UIParent)
assert(panel.blizzardSearch == nil and panel.blizzardPublish == nil,
    "Companions exposes no native finder search or create shortcuts")
assert(panel.frame.parent == UIParent and APRCompanions == panel.frame and not APR.Workspace.frame,
    "Companions owns an independent window without constructing the workspace")
panel.frame.content:SetWidth(1008)
panel:Layout()
assert(panel.count.point[1] == "LEFT" and panel.count.point[3] == "BOTTOMLEFT"
    and panel.count.point[5] == 8 and panel.count:GetWidth() == 1008,
    "The result count occupies the full-width compact footer")
local compactFooter = panel.results.points.BOTTOMRIGHT[5]
assert(compactFooter == 42 and panel.status.point[5] == 26,
    "Results leave only enough footer space for the count and optional status")
assert(panel.autoScan.point[5] == panel.visible.point[5]
    and panel.visible.point[4] > panel.autoScan.point[4] + panel.autoScan.label:GetStringWidth() + 26,
    "Quick controls reserve the actual localized label widths")
panel.frame.content:SetWidth(520)
panel:Layout()
assert(panel.autoScan.point[5] < 0 and panel.languages.point[5] < panel.autoScan.point[5],
    "Narrow windows move the quick controls above filters rather than over the option button")
assert(panel.count.point[5] == 8 and panel.count:GetWidth() == 520
    and panel.results.points.BOTTOMRIGHT[5] == compactFooter,
    "Narrow layouts retain the same compact footer without reserving any action-button rows")
panel.frame.content:SetWidth(1008)
panel:Layout()
panel.frame:Show()
panel.scroll:SetSize(900, 152)
panel:Refresh()
assert(panel.autoScan:GetChecked() == false and panel.visible:GetChecked() == true)
assert(panel.route == nil and panel.match:GetText() == locale.GF_MATCH_NEARBY,
    "With no selected route, the mode remains an actual filter rather than unexplained text beside languages")
local beforeRouteTop, beforeRouteAnchors = panel.results.points.TOPLEFT[5], panel.results.anchors
APR.ActiveRoute = "synthetic"
panel:Refresh()
assert(panel.route == nil and panel.results.points.TOPLEFT[5] == beforeRouteTop
    and panel.results.anchors == beforeRouteAnchors,
    "Selecting a route adds no label or spacing and does not reflow the companion window")
local first = panel.list.active[1]
assert(first and first.name:GetText() == "Alpha")
assert(first.flag.atlas == "Lang-Regions-frFR" and first.extraLanguages:GetText() == "+1")
assert(first.age:GetText() == "Age 20")
assert(not panel.list.active[3].invite:IsEnabled(), "The action respects current invitation eligibility")
assert(panel.list.active[3].languageFallback:IsShown(), "Unknown languages have a neutral text fallback")

first.invite.scripts.OnClick(first.invite)
assert(calls[#calls].kind == "invite" and calls[#calls].key == "Alpha-Realm")
panel.list.active[2].invite.scripts.OnClick(panel.list.active[2].invite)
assert(calls[#calls].kind == "request" and calls[#calls].key == "Bravo-Realm")
first.whisper.scripts.OnClick(first.whisper)
assert(calls[#calls].kind == "whisper" and calls[#calls].key == "Alpha-Realm")
panel.autoScan:SetChecked(true); panel.autoScan.scripts.OnClick(panel.autoScan)
assert(settings.autoScan == true and settings.visible == true)
settings.visible = false; settings.autoScan = false
panel:Refresh()
assert(panel.visible:GetChecked() == false and panel.autoScan:GetChecked() == false,
    "Changes from Group options are reflected in the quick controls")
panel.visible:SetChecked(true); panel.visible.scripts.OnClick(panel.visible)
assert(settings.visible == true and settings.autoScan == false, "Visibility does not enable the scanner")
panel.refresh.scripts.OnClick(panel.refresh)
assert(scanCount == 1)
panel.configure.scripts.OnClick(panel.configure)
assert(calls[#calls].kind == "configure")

-- Both filters use APR selectors, including on clients without MenuUtil.
MenuUtil = nil
panel.languages.scripts.OnClick(panel.languages)
local languageMenu = panel.languages.menu
languageMenu.list.scroll:SetSize(260, 104)
languageMenu.list:RefreshVisible()
assert(languageMenu and #languageMenu.list.items == 3)
assert(languageMenu.list.active[1].check:IsShown())
languageMenu.list.active[3].scripts.OnClick(languageMenu.list.active[3])
assert(settings.languages.fr == true and panel.languages:GetText():find("French", 1, true))
assert(languageMenu:IsShown() and languageMenu.list.active[3].check:IsShown())
languageMenu.list.active[1].scripts.OnClick(languageMenu.list.active[1])
assert(next(settings.languages) == nil and languageMenu.list.active[1].check:IsShown())
panel.match.scripts.OnClick(panel.match)
local matchMenu = panel.match.menu
matchMenu.list.scroll:SetSize(200, 104)
matchMenu.list:RefreshVisible()
assert(matchMenu and #matchMenu.list.items == 3 and matchMenu.list.active[1].check:IsShown())
matchMenu.list.active[3].scripts.OnClick(matchMenu.list.active[3])
assert(settings.matchMode == "zone" and panel.match:GetText() == locale.GF_MATCH_ZONE
    and calls[#calls].kind == "option" and calls[#calls].key == "matchMode",
    "The criterion menu updates the same saved preference as the options page")
assert(not matchMenu:IsShown())
settings.matchMode = "nearby"
panel:Refresh()

-- Empty-state changes cannot leave a status-sized blank band above the results.
-- Long translated filters wrap by structure, while the message stays centred.
local normalCandidates, languageValues, oldZoneLabel = candidates, APR.partyFinder.GetLanguageValues, locale.GF_MATCH_ZONE
candidates, APR.ActiveRoute = {}, nil
function APR.partyFinder:GetLanguageValues() return {fr = string.rep("Long language label ", 12)} end
locale.GF_MATCH_ZONE = string.rep("A long matching criterion ", 8)
settings.languages.fr, settings.matchMode = true, "zone"
panel.frame.content:SetWidth(520)
panel:Refresh()
assert(panel.languages:GetWidth() <= 300 and panel.match:GetWidth() <= 360
    and panel.match.point[5] == panel.languages.point[5] - 40,
    "Long language and criterion labels move to separate bounded filter rows")
local resultsTop, resultAnchors = panel.results.points.TOPLEFT[5], panel.results.anchors
assert(resultsTop == panel.match.point[5] - panel.match:GetHeight() - 12,
    "Results follow the last filter with one small gap, without an unused status row")
APR.ActiveRoute = "synthetic"
panel:Refresh()
assert(panel.results.points.TOPLEFT[5] == resultsTop and panel.results.anchors == resultAnchors,
    "A selected route also leaves no unused row in narrow layouts with wrapped filters")
for _, nextStatus in ipairs({"restricted", "instance", "searching", "ready"}) do
    status = nextStatus
    panel:Refresh()
    assert(panel.empty:IsShown() and panel.empty.justifyH == "CENTER" and panel.empty.justifyV == "MIDDLE"
        and panel.empty.point[1] == "CENTER", "Every empty-state message is centred inside its list")
    assert(not panel.status:IsShown() and panel.results.anchors == resultAnchors
        and panel.results.points.TOPLEFT[5] == resultsTop,
        "Status changes neither duplicate the message nor reflow unchanged filters")
end
for _ = 1, 20 do panel:Refresh() end
assert(panel.results.anchors == resultAnchors, "Unchanged discovery refreshes do not measure or anchor chrome again")
candidates, status = normalCandidates, "searching"
panel:Refresh()
assert(not panel.empty:IsShown() and panel.status:IsShown() and panel.status.point[3] == "BOTTOMLEFT",
    "A search with existing results reports progress in the footer without moving its rows")
APR.partyFinder.GetLanguageValues, locale.GF_MATCH_ZONE = languageValues, oldZoneLabel
settings.languages, settings.matchMode, APR.ActiveRoute = {}, "nearby", "synthetic"
panel.frame.content:SetWidth(1008)
status = "ready"
panel:Refresh()

-- Long result sets bind only the viewport and keep callbacks pointed at the recycled item.
candidates = {}
for index = 1, 200 do
    candidates[index] = {key = "Example" .. index .. "-Realm", name = "Example" .. index,
        primary = "en", spokenLanguages = {"en"}, level = 10, class = 1, groupSize = 0, seenAt = 100}
end
panel:Refresh()
panel.list:ScrollToIndex(100)
local middle = panel.list.active[100]
assert(middle and middle.item.key == "Example100-Realm")
middle.invite.scripts.OnClick(middle.invite)
assert(calls[#calls].key == "Example100-Realm")
local frames, fonts = env.frames(), env.fonts()
for _ = 1, 20 do panel:Refresh() end
assert(env.frames() == frames and env.fonts() == fonts, "Repeated refreshes reuse all viewport widgets")
local activeCount = 0
for _ in pairs(panel.list.active) do activeCount = activeCount + 1 end
assert(activeCount <= 5, "A dense result list must not allocate one row per player")

candidates = {}; status = "unsupported"
panel:Refresh()
assert(panel.empty:IsShown() and panel.empty:GetText() == locale.GF_STATUS_unavailable,
    "An unavailable transport must not claim a successful empty search")
panel.frame:Hide()
local serial = panel.refreshSerial
panel:Refresh()
assert(panel.refreshSerial == serial, "Hidden pages do no display work")

-- A badge click opens/searches; it cannot invite a cached candidate.
local invitesBefore = #calls
local originalShow = panel.Show
local shows = 0
function panel:Show() shows = shows + 1 end
local headerButton = APR.currentStep.partyFinderButton
local headerText = CurrentStepFrameHeader:CreateFontString()
CurrentStepFrameHeader.Text = headerText
headerButton.secure, headerText.secure = true, true
APR.currentStep:RefreshPartyFinderButton(3)
assert(headerButton:IsShown() and headerButton.badge:GetText() == "3")
headerButton.scripts.OnClick(headerButton)
assert(shows == 1 and #calls == invitesBefore)
settings.showBadge = false
APR.currentStep:RefreshPartyFinderButton(3)
assert(not headerButton.badge:IsShown())
settings.showButton = false
env.setCombat(true)
APR.currentStep:RefreshPartyFinderButton(0)
assert(headerButton:IsShown() and APR.currentStep.partyFinderButtonDirty)
local combatRegistrations = headerButton.eventRegistrations
for _ = 1, 100 do APR.currentStep:RefreshPartyFinderButton(0) end
assert(headerButton.eventRegistrations == combatRegistrations,
    "Combat refresh bursts share a single recovery subscription")
local function EndCombat()
    env.setCombat(false)
    assert(headerButton.events and headerButton.events.PLAYER_REGEN_ENABLED)
    headerButton.scripts.OnEvent(headerButton, "PLAYER_REGEN_ENABLED")
    assert(not next(headerButton.events) and not APR.currentStep.partyFinderButtonDirty,
        "Recovery unregisters its listener immediately, without polling")
end
EndCombat()
assert(not headerButton:IsShown() and headerText.point[2] == CurrentStepFrameSettingsButton)

-- Finder/global disable removes discovery listeners, so the button must own
-- its recovery and read the final settings when combat actually ends.
for _, disable in ipairs({"finder", "addon"}) do
    settings.showButton, settings.enabled, APR.settings.profile.enableAddon = true, true, true
    APR.currentStep:RefreshPartyFinderButton(2)
    assert(headerButton:IsShown() and APR.currentStep.partyFinderAnchorVisible)
    env.setCombat(true)
    if disable == "finder" then settings.enabled = false
    else APR.settings.profile.enableAddon = false end
    APR.currentStep:RefreshPartyFinderButton(0)
    assert(headerButton:IsShown(), "Protected layout stays unchanged during combat")
    EndCombat()
    assert(not headerButton:IsShown() and not APR.currentStep.partyFinderAnchorVisible,
        "The deferred disable applies even with no discovery event subscriptions")
    assert(headerText.point[2] == CurrentStepFrameSettingsButton,
        "Disabling the entry point releases its header text space")
end
settings.enabled, APR.settings.profile.enableAddon = true, true
env.setCombat(true)
APR.currentStep:RefreshPartyFinderButton(0)
settings.showButton = false
APR.currentStep:RefreshPartyFinderButton(0)
settings.showButton = true
EndCombat()
assert(headerButton:IsShown() and APR.currentStep.partyFinderAnchorVisible,
    "Combat recovery uses the latest preference, not an old deferred snapshot")
settings.showButton = false
env.setCombat(false)
APR.currentStep:RefreshPartyFinderButton(0)
assert(not headerButton:IsShown() and not APR.currentStep.partyFinderButtonDirty)

function APR:TrimString(value) return value:match("^%s*(.-)%s*$") end
function APR:RemoveContiguousSpaces(value) return value:gsub("%s+", " ") end
dofile("APR-Core/core/Commands.lua")
APR.command:SlashCmd(" group ")
assert(shows == 2 and #calls == invitesBefore, "The command only opens discovery")
panel.Show = originalShow

-- Old workspace links open the standalone window without creating a hidden workspace shell.
local creates, originalCreate = 0, panel.Create
function panel:Create(parent) creates = creates + 1; return originalCreate(self, parent) end
local window = panel.frame
local before = env.frames()
APR.Workspace:Show("group")
assert(not APR.Workspace.frame and not APR.Workspace.tabs.group and not APR.Workspace.pages.group)
APR.Workspace:Show("group")
assert(creates == 0 and panel.frame == window and panel.frame:IsShown() and env.frames() == before,
    "Repeated opens reuse the same independently owned window")
print("Companion UI: standalone window, aligned controls/footer, shared toggles, languages, row-only actions, pooled results, honest empty states, badge and context passed")
