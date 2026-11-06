local fixture = dofile("tests/lua/gamepad_interface_test.lua")
local pad, env, tick = fixture.pad, fixture.env, fixture.tick
pad.menu:Hide()
GROUP_INVITE, REQUEST_INVITE, WHISPER = "Invite", "Request", "Whisper"
LFG_LIST_SEARCH_AGAIN, LANGUAGES_LABEL, WORLD = "Search again", "Languages", "World"
function env.methods:SetChecked(value) self.checked = value end
function env.methods:GetChecked() return self.checked end
function env.methods:UnregisterEvent(event)
    if self.events then self.events[event] = nil end
end
function env.methods:SetMinMaxValues(minimum, maximum)
    self.minimum, self.maximum = minimum, maximum
end
function env.methods:GetMinMaxValues() return self.minimum, self.maximum end
function env.methods:SetValue(value)
    self.value = value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function env.methods:GetValue() return self.value or 0 end
function env.methods:CreateAnimationGroup()
    local animation = {}
    function animation:CreateAnimation()
        return { SetDegrees = function() end, SetDuration = function() end }
    end
    function animation:SetLooping() end
    function animation:Play() self.playing = true end
    function animation:Stop() self.playing = false end
    function animation:IsPlaying() return self.playing end
    return animation
end
local settings = { enabled = true, matchMode = "nearby", languages = {}, stepRange = 5, minLevel = 0, maxLevel = 0 }
local candidates = {
    { key = "one", name = "One", level = 8, class = 1, spokenLanguages = {} },
    { key = "two", name = "Two", level = 9, class = 2, spokenLanguages = {} },
}
local searches, invites = 0, {}
APR.partyFinder = {
    GetSettings = function() return settings end,
    GetLanguageValues = function() return { en = "English", fr = "French" } end,
    GetStatus = function() return "ready" end,
    GetCandidates = function() return candidates end,
    Search = function() searches = searches + 1 end,
    CanInvite = function() return true end,
    Invite = function(_, key) invites[#invites + 1] = key end,
    SetOption = function(_, key, value) settings[key] = value end,
    SetLanguageFilter = function(_, key, value) settings.languages[key] = value or nil end,
    GetCandidateDescription = function() return "Synthetic objective" end,
}
dofile("APR-Core/ui/panels/PartyFinderPanel.lua")
pad:RunAction("partyfinder")
tick()
local panel = APR.PartyFinderPanel
assert(SmartNavigation:GetActiveFrame() == panel.frame and SmartNavigation:GetCurrentButton() == panel.refresh)
assert(searches == 1 and #invites == 0, "Opening discovery starts its normal search without inviting anyone")
panel.refresh:GetScript("OnClick")(panel.refresh)
assert(searches == 2)
assert(panel.refresh.overrides.right() == panel.autoScan)
assert(panel.languages.overrides.right() == panel.match)
panel.stepRange.slider.overrides.right()
assert(settings.stepRange == 6 and panel.stepRange.edit:GetText() == "6")
settings.matchMode = "route"
panel:Refresh()
assert(
    not pad:CanFocus(panel.stepRange.slider) and not pad:CanFocus(panel.stepRange.edit),
    "A filter disabled by the selected match mode must not trap controller navigation"
)
settings.matchMode = "nearby"
panel:Refresh()
panel.languages:GetScript("OnClick")(panel.languages)
tick()
assert(panel.languages.menu:IsShown() and SmartNavigation:GetActiveFrame() == panel.languages.menu)
panel.languages.menu:SmartNavigationCloseHandler()
tick()
panel.scroll:SetSize(900, 200)
panel.list:RefreshVisible(true)
tick()
local first, second = panel.list.active[1], panel.list.active[2]
assert(first and second and first.invite.overrides.left() == first.whisper)
assert(first.whisper.overrides.right() == first.invite)
assert(
    first.invite.overrides.down() == second.invite,
    "Down keeps the candidate action column while traversing results"
)
pad:SelectButton(first.invite, panel.frame)
assert(#invites == 0, "Focusing an invitation must never send it")
first.invite:GetScript("OnClick")(first.invite)
assert(#invites == 1 and invites[1] == "one")
print(
    "Gamepad discovery: menu access, focus/search, filters/sliders, dropdown Back, result traversal and explicit invitation passed"
)
