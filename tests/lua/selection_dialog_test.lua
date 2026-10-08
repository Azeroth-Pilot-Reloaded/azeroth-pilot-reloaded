-- Exercise real popup callbacks, disabled choices, recycling and constrained-screen layout.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local show, hide = env.methods.Show, env.methods.Hide
function env.methods:Show()
    local changed = not self:IsShown()
    show(self)
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function env.methods:Hide()
    local changed = self:IsShown()
    hide(self)
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function APR:SetTooltipText(_, text) GameTooltip.title = text end
function APR:AddTooltipLine(_, text) GameTooltip.description = text end
UIParent:SetSize(1280, 720)
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/ui/foundations/SelectionDialog.lua")
dofile("APR-Core/ui/route/QuestionPopUp.lua")
local selected, cancelled, chosen = 0, 0, nil
local options = {{key = "open", label = "Available expansion"},
    {key = "locked", label = "Requires level 80", enabled = false, tooltip = "Level restriction"}}
local function open(choices)
    APR.questionDialog:CreateSelectionPopup("Choose an expansion", "Pick a route for your character.", choices or options,
        function(option) selected = selected + 1; chosen = option end,
        function() cancelled = cancelled + 1 end)
    return APR.UI.selectionDialog
end
local frame = open()
assert(frame == APRSelectionPopup and frame:IsShown() and frame.backdropColor[4] == 1)
assert(frame:GetHeight() < UIParent:GetHeight() and frame.close.icon)
local disabled = frame.list.active[2].button
assert(not disabled:IsEnabled())
disabled.scripts.OnClick()
assert(selected == 0 and cancelled == 0 and frame:IsShown())
disabled.scripts.OnEnter(disabled)
assert(GameTooltip.title == options[2].label and GameTooltip.description == "Level restriction")
frame.list.active[1].button.scripts.OnClick()
assert(selected == 1 and chosen == options[1] and cancelled == 0 and not frame:IsShown())
assert(not frame.onSelect and not frame.onCancel and not frame.options and #frame.list.items == 0)
assert(not GameTooltip:IsShown())
open(); frame.close.scripts.OnClick()
assert(cancelled == 1 and selected == 1)
open(); frame.cancelButton.scripts.OnClick()
assert(cancelled == 2)
open(); frame:Hide(); frame:Hide() -- Escape hides UISpecialFrames; repeated hides must not cancel twice.
assert(cancelled == 3)
open(); open()
assert(cancelled == 4 and frame:IsShown(), "Replacing a visible choice resolves the old prompt")
frame:Hide()

-- Long translated choices fit the viewport and callbacks always use the newly bound option.
local many = {}
for index = 1, 100 do many[index] = {key = index, label = string.rep("Expansion ", 8) .. index} end
UIParent:SetSize(800, 480)
open(many)
assert(frame:GetHeight() <= UIParent:GetHeight() - 38)
assert(frame.list.height > frame.scroll:GetHeight())
frame.list:ScrollToIndex(100)
local row = frame.list.active[100]
assert(row and row.item.option.key == 100)
row.button.scripts.OnClick()
assert(chosen == many[100] and selected == 2 and cancelled == 5)
open(); frame:Hide(); open(many); frame:Hide()
local frames, fonts = env.frames(), env.fonts()
for _ = 1, 30 do open(); frame:Hide(); open(many); frame:Hide() end
assert(env.frames() == frames and env.fonts() == fonts, "Reopening and resizing must reuse dialog and row controls")
local registrations = 0
for _, name in ipairs(UISpecialFrames) do if name == "APRSelectionPopup" then registrations = registrations + 1 end end
assert(registrations == 1)
-- Confirmation reuses the shell, but only an explicit Accept invokes its action.
local accepted, declined = 0, 0
local function confirm()
    return APR.UI:ShowConfirmationDialog("Clear custom routes?", function() accepted = accepted + 1 end,
        function() declined = declined + 1 end)
end
frame = confirm()
assert(frame.acceptButton:IsShown() and not frame.body:IsShown())
assert(frame.acceptButton:GetFontString():GetText() == ACCEPT and frame.cancelButton:GetFontString():GetText() == CANCEL)
frame.cancelButton.scripts.OnClick()
assert(accepted == 0 and declined == 1)
confirm(); frame.close.scripts.OnClick()
confirm(); frame:Hide() -- Escape.
assert(accepted == 0 and declined == 3)
confirm(); frame.acceptButton.scripts.OnClick(); frame:Hide()
assert(accepted == 1 and declined == 3 and not frame.onAccept)
open()
assert(not frame.acceptButton:IsShown() and frame.body:IsShown() and #frame.list.items == 2)
frame:Hide()
print("Selection dialog: disabled choices, callbacks, cancellation, replacement, tooltips, bounded layout and recycled controls passed")
