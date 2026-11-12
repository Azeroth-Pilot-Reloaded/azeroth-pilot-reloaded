local env = dofile("tests/lua/route_ui_test_env.lua")
function env.methods:UnregisterEvent(event)
    if self.events then self.events[event] = nil end
end
local title
local createHeader = APR.CreateFrameHeader
function APR:CreateFrameHeader(name, parent, text, ...)
    title = text
    local header = createHeader(self, name, parent, text, ...)
    header.Text = env.widget(header)
    return header
end
local populated, picked, nativeMenus, prepared = 0, 0, 0, {}
local padEnabled = false
APR.Services = {
    GetText = function() return "Nearest service" end,
    PopulateMenu = function(_, root) assert(root.synthetic); populated = populated + 1 end,
    ShowPicker = function() picked = picked + 1 end,
}
APR.Gamepad = {
    IsEnabled = function() return padEnabled end,
    PrepareButton = function(_, button, label) prepared[button] = label end,
}
MenuUtil = {CreateContextMenu = function(owner, generator)
    assert(owner == APR.currentStep.nearestButton)
    nativeMenus = nativeMenus + 1
    generator(owner, {synthetic = true})
end}
local finderSettings = {enabled = true, showButton = true}
APR.partyFinder = {GetSettings = function() return finderSettings end, GetCount = function() return 0 end}
APR.settings.profile.enableAddon = true
dofile("APR-Core/ui/route/CurrentStep.lua")
APR.currentStep:RefreshPartyFinderButton()
local pin, finder, text = APR.currentStep.nearestButton, APR.currentStep.partyFinderButton, CurrentStepFrameHeader.Text
assert(title == "APR", "The current-step title uses the compact addon name")
assert(pin:IsShown() and pin:GetParent() == CurrentStepFrameHeader)
assert(pin.point[1] == "RIGHT" and pin.point[2] == finder and pin.point[3] == "LEFT",
    "The search pin sits immediately left of Group Finder")
assert(text.point[2] == pin, "The title stops before the leftmost header button")
assert(prepared[pin] == "Nearest service")
pin.scripts.OnClick(pin)
assert(nativeMenus == 1 and populated == 1 and picked == 0)
padEnabled = true
pin.scripts.OnClick(pin)
assert(nativeMenus == 1 and picked == 1, "Controller clicks open APR's picker instead of a native context menu")

local tooltip
function APR:SetTooltipText(_, label) tooltip = label end
pin.scripts.OnEnter(pin)
assert(tooltip == "Nearest service" and GameTooltip:IsShown())
pin.scripts.OnLeave(pin)
assert(not GameTooltip:IsShown())
CurrentStepFrame_StepHolder:Hide()
assert(pin:IsShown(), "Search remains available when the current step is collapsed")

finderSettings.showButton = false
APR.currentStep:RefreshPartyFinderButton()
assert(not finder:IsShown() and pin:IsShown() and pin.point[2] == CurrentStepFrameSettingsButton)
assert(text.point[2] == pin, "Hiding Group Finder closes the gap while preserving search")
env.setCombat(true)
APR.settings.profile.enableAddon = false
APR.currentStep:RefreshPartyFinderButton()
assert(pin:IsShown() and APR.currentStep.partyFinderButtonDirty, "Header layout changes defer in combat")
env.setCombat(false)
finder.scripts.OnEvent(finder, "PLAYER_REGEN_ENABLED")
assert(not pin:IsShown() and text.point[2] == CurrentStepFrameSettingsButton)
APR.settings.profile.enableAddon = true
APR.currentStep:RefreshPartyFinderButton()
assert(pin:IsShown() and text.point[2] == pin)
print("Header search pin: compact title, ordering, shared mouse/controller search, tooltip, collapse, finder visibility and combat recovery passed")
