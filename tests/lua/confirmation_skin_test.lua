-- Shared native popups must keep their callbacks, mandatory flags and original art for the next addon.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local methods = env.methods
function methods:GetScript(key) return self.scripts[key] end
function methods:GetAlpha() return self.alpha or 1 end
function methods:GetFrameLevel()
    local parentLevel = self.parent and self.parent:GetFrameLevel() or 0
    -- Model the client that will not draw a child background below its parent text.
    return math.max(parentLevel, self.level or (self.parent and parentLevel + 1) or 0)
end
function methods:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or "MEDIUM" end
function methods:SetFrameStrata(strata) self.strata = strata end
function methods:SetAllPoints(target) self.allPointsTarget = target or self.parent end
function methods:GetChildren() return unpack(self.children or {}) end
function methods:GetRegions() return unpack(self.regions or {}) end
function methods:IsObjectType(kind) return self.objectType == kind end
function methods:SetFont(font, size, flags) self.font, self.size, self.flags = font, size, flags; return true end
function methods:GetFont() return self.font or "native.ttf", self.size or 12, self.flags or "OUTLINE" end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:GetTextColor() return unpack(self.textColor or {1, 1, 1, 1}) end
function methods:HighlightText() self.selection = {0, #(self:GetText() or "")} end
local texture = methods.CreateTexture
function methods:CreateTexture(...)
    local region = texture(self, ...)
    region.objectType = "Texture"
    self.regions = self.regions or {}; self.regions[#self.regions + 1] = region
    return region
end
local hide = methods.Hide
function methods:Hide()
    local shown = self:IsShown()
    hide(self)
    if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function APR:ResolveUIFileAsset(path) return path end
local lib = LibStub
function LibStub(name, ...)
    if name == "LibSharedMedia-3.0" then return {GetDefault = function() return "Native" end, Fetch = function() return "native.ttf" end} end
    return lib(name, ...)
end
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/TextStyles.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/route/QuestionPopUp.lua")
APR.settings.profile.uiTheme = "modern"
CONFIRM_CONTINUE, OKAY = "Continue?", "OK"
StaticPopupDialogs = {}
local popup = CreateFrame("Frame", "TestSharedPopup", UIParent)
popup:SetSize(380, 90)
popup:SetFrameLevel(0)
popup.text = popup:CreateFontString()
popup.text:SetFont("original.ttf", 12, "OUTLINE")
popup.text:SetTextColor(0.7, 0.7, 0.8, 1)
popup.border = CreateFrame("Frame", nil, popup)
popup.borderArt = popup.border:CreateTexture()
popup.borderArt:SetAlpha(0.8)
popup.button1, popup.button2 = CreateFrame("Button", nil, popup), CreateFrame("Button", nil, popup)
for _, button in ipairs({popup.button1, popup.button2}) do
    button:SetSize(128, 21)
    button:SetFontString(button:CreateFontString())
    button:GetFontString():SetFont("button.ttf", 10, "OUTLINE")
    button:SetNormalTexture(button:CreateTexture())
end
popup.editBox = CreateFrame("EditBox", nil, popup)
popup.editBox:SetFont("edit.ttf", 12, "")
popup:Hide()
function StaticPopup_Hide(name) if popup.which == name then popup:Hide() end end
function StaticPopup_Show(name)
    local definition = StaticPopupDialogs[name]
    popup.which = name
    popup:SetHeight(90)
    APR:GetPopupText(popup):SetText(definition.text)
    local buttons = APR:GetPopupButtons(popup)
    buttons[1]:SetText(definition.button1)
    buttons[2]:SetText(definition.button2 or "")
    buttons[2]:SetShown(definition.button2 ~= nil)
    local box = popup.editBox or popup.EditBox
    box:SetShown(definition.hasEditBox == 1)
    popup:Show()
    if definition.OnShow then definition.OnShow(popup) end
    return popup
end
local accepted, cancelled = 0, 0
local accept = function() accepted = accepted + 1 end
local cancel = function() cancelled = cancelled + 1 end
local function click(index)
    local definition = StaticPopupDialogs[popup.which]
    local callback = index == 1 and definition.OnAccept or definition.OnCancel
    popup:Hide()
    if callback then callback(popup) end
end
APR.questionDialog:CreateQuestionPopup("DISABLE", "Disable APR?", accept, cancel, "Disable", "Cancel")
assert(popup.aprPopupChrome.background:GetBackdrop().edgeSize == 8 and popup.borderArt:GetAlpha() == 0)
assert(popup.button1:GetNormalTexture():GetAlpha() == 0 and popup.button1:GetHeight() == 30)
assert(StaticPopupDialogs.DISABLE.OnAccept == accept and StaticPopupDialogs.DISABLE.OnCancel == cancel,
    "Theme chrome never replaces native action handlers")
assert(popup.button1:GetFontString():GetText() == "Disable")
assert(popup.aprPopupChrome.background:GetParent() == popup:GetParent()
    and popup.aprPopupChrome.background.allPointsTarget == popup
    and popup.aprPopupChrome.buttons[popup.button1].background:GetParent() == popup.button1:GetParent()
    and popup.aprPopupChrome.buttons[popup.button1].background.allPointsTarget == popup.button1,
    "Chrome is a sibling of its owner so the parent-child paint order cannot hide native text")
assert(popup.aprPopupChrome.background:GetFrameLevel() < popup:GetFrameLevel()
    and popup.aprPopupChrome.buttons[popup.button1].background:GetFrameLevel() < popup.button1:GetFrameLevel(),
    "Opaque chrome stays below text even when the native popup starts at frame level zero")
assert(popup.aprPopupChrome.background.ignoreInLayout
    and popup.aprPopupChrome.buttons[popup.button1].background.ignoreInLayout,
    "Native layout does not measure the all-points chrome and feed its size back into the dialog")
APR:StyleStaticPopup(popup) -- Repeated styling cannot overwrite the native snapshot.
assert(popup.aprPopupChrome.buttons[popup.button1].background.aprRoundedFill.pieces[1]:GetAlpha() == 1,
    "Repeated styling must not retire APR's sibling button backdrop as native artwork")
click(2)
assert(accepted == 0 and cancelled == 1)
assert(popup.borderArt:GetAlpha() == 0.8 and popup.button1:GetNormalTexture():GetAlpha() == 1)
assert(popup.button1:GetHeight() == 21 and popup:GetHeight() == 90)
assert(popup:GetFrameLevel() == 0, "Closing the popup restores its original frame level")
assert(popup.button1:GetFontString():GetFont() == "button.ttf" and popup.text:GetFont() == "original.ttf")
assert(not popup.aprPopupChrome.background:IsShown() and not APR.textStyleRegistry[popup.text],
    "A foreign popup reusing the frame has its original artwork and fonts")
popup:Show(); popup.button1.scripts.OnEnter(popup.button1)
assert(not popup.aprPopupChrome.background:IsShown(), "A foreign popup hover cannot reactivate APR chrome")
popup:Hide()

APR.questionDialog:CreateQuestionPopup("DISABLE", "Disable APR?", accept, cancel)
click(1)
assert(accepted == 1 and cancelled == 1)
local frames, fonts = env.frames(), env.fonts()
for _ = 1, 50 do APR.questionDialog:CreateQuestionPopup("DISABLE", "Disable APR?", accept, cancel); popup:Hide() end
assert(env.frames() == frames and env.fonts() == fonts, "Shared popup decoration reuses its controls")
APR.questionDialog:CreateQuestionPopup("LOCKED", "Continue?", accept, cancel, nil, nil, false)
assert(not StaticPopupDialogs.LOCKED.hideOnEscape)
popup:Hide()
APR.questionDialog:CreateMandatoryAction("Read this instruction", accept)
assert(not StaticPopupDialogs.MANDATORY_DIALOG.hideOnEscape and StaticPopupDialogs.MANDATORY_DIALOG.notClosableByLogout
    and StaticPopupDialogs.MANDATORY_DIALOG.noCancelOnReuse and not popup.button2:IsShown())
click(1)
assert(accepted == 2)
APR.questionDialog:CreateEditBoxPopup("Copy link", "Close", "https://example.com")
assert(popup.editBox:GetText() == "https://example.com" and popup.editBox:HasFocus()
    and popup.editBox.selection[2] == #"https://example.com", "Copy dialogs keep editable text and selection")
popup:Hide()
env.setCombat(true)
APR.questionDialog:CreateQuestionPopup("COMBAT", "Continue?", accept, cancel)
assert(not popup.aprPopupChrome.background:IsShown() and StaticPopupDialogs.COMBAT.OnAccept == accept,
    "Combat defers chrome without disabling confirmation actions")
click(1)
env.setCombat(false)
assert(accepted == 3)

-- Current Retail exposes capitalized text and buttons nested inside a layout container.
popup.Text, popup.EditBox = popup.text, popup.editBox
popup.ButtonContainer = CreateFrame("Frame", nil, popup)
popup.ButtonContainer.Buttons = {popup.button1, popup.button2}
for _, button in ipairs(popup.ButtonContainer.Buttons) do button:SetParent(popup.ButtonContainer) end
popup.text, popup.editBox, popup.button1, popup.button2 = nil, nil, nil, nil
function popup:GetTextFontString() return self.Text end
function popup:GetButton(index) return self.ButtonContainer.Buttons[index] end
APR.questionDialog:CreateQuestionPopup("RETAIL", "Disable APR?", accept, cancel, "Disable", "Cancel")
local buttons = APR:GetPopupButtons(popup)
assert(APR.textStyleRegistry[popup.Text] and APR.textStyleRegistry[buttons[1]:GetFontString()]
    and buttons[1]:GetFontString():GetText() == "Disable",
    "The current Retail layout retains visible styled question text and button labels")
assert(popup.aprPopupChrome.buttons[buttons[1]].background:IsShown()
    and popup.aprPopupChrome.background:GetFrameLevel() < popup:GetFrameLevel())
assert(popup.aprPopupChrome.buttons[buttons[1]].background:GetParent() == popup.ButtonContainer
    and popup.aprPopupChrome.buttons[buttons[1]].background:GetFrameLevel() < buttons[1]:GetFrameLevel(),
    "Retail's nested button labels remain above their sibling backdrops")
click(2)
assert(cancelled == 2 and popup:GetFrameLevel() == 0)
APR.settings.profile.uiTheme = "wow"
APR.questionDialog:CreateQuestionPopup("COMPACT", "Disable APR?", accept, cancel, "Disable", "Cancel")
assert(buttons[1]:GetHeight() == 21 and buttons[1]:GetNormalTexture():GetAlpha() == 1,
    "WoW keeps the compact native red buttons")
assert(popup:GetHeight() == popup.Text:GetStringHeight() + 21 + 40 and popup:GetHeight() < 90,
    "A simple WoW confirmation sizes to its text and buttons without surplus empty space")
assert(not popup.aprPopupChrome.buttons[buttons[1]].background:IsShown())
click(1)
assert(accepted == 4 and popup:GetHeight() == 90 and buttons[1]:GetFontString():GetFont() == "button.ttf")
print("Confirmations: theme chrome, callbacks, custom labels, shared-frame restoration, reuse, mandatory flags and combat passed")
