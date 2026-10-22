-- Arrow text shares guide content and the existing arrow typography/skin scope.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local originalLibStub = LibStub
function LibStub(name, ...)
    if name == "LibSharedMedia-3.0" then
        return {GetDefault = function() return "Native" end, Fetch = function(_, _, name) return name .. ".ttf" end}
    end
    return originalLibStub(name, ...)
end
function APR:ResolveUIFileAsset(path) return path end
function env.methods:SetFont(path, size, flags) self.font, self.size, self.flags = path, size, flags; return true end
function env.methods:SetTextColor(...) self.textColor = {...} end
function env.methods:SetJustifyH(value) self.justify = value end
function env.methods:SetWordWrap(value) self.wrap = value end
function env.methods:SetNonSpaceWrap(value) self.nonSpaceWrap = value end
function env.methods:GetStringHeight()
    return math.max(1, math.ceil(#(self.text or "") / 30)) * (self.size or 12)
end
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/TextStyles.lua")
dofile("APR-Core/features/navigation/Arrow.lua")
local arrow, frame, profile = APR.Arrow, APR.ArrowFrame, APR.settings.profile
profile.globalTextAppearance = APR:CreateTextAppearanceDefaults(false)
profile.arrowTextAppearance = APR:CreateTextAppearanceDefaults(true)
profile.arrowScale, profile.arrowTextScale, profile.arrowStyle = 1, 1.25, "classic"
profile.arrowleft, profile.arrowtop, profile.arrowFPS, profile.showArrow = 320, -250, 2, true
local lines = {{text = "Pick up", role = "title"}, {text = "The next quest", role = "base"}}
function APR.currentStep:GetActionTextLines() return lines end
function APR:IsPetBattleActive() return false end
function APR:IsInstanceWithUI() return true end
arrow:Init()
arrow:UpdateActionText()
assert(not frame.actionTextFrame:IsShown() and #frame.actionTexts == 0,
    "Existing profiles do not create visible action text until enabled")
profile.arrowActionText = true
arrow:UpdateActionText()
local title, detail = frame.actionTexts[1], frame.actionTexts[2]
assert(frame.actionTextFrame:IsShown() and title:GetText() == "Pick up" and detail:GetText() == "The next quest")
assert(title.justify == "CENTER" and title.wrap and title.nonSpaceWrap and title:GetWidth() == 260,
    "Long and unbroken instructions wrap in a centered bounded column")
assert(frame.actionTextFrame.point[2] == frame.distance and frame.Button.point[2] == frame.actionTextFrame,
    "Action text follows distance; the skip control follows the complete text block")
assert(detail.point[5] <= -title:GetStringHeight(), "Multiple lines cannot overlap")
assert(title:GetEffectiveScale() == 1.25 and detail:GetEffectiveScale() == 1.25)
profile.arrowScale, profile.arrowStyle = 2, "apr"
arrow:ApplyStyle()
assert(title:GetEffectiveScale() == 1.25 and profile.arrowleft == 320 and profile.arrowtop == -250,
    "Artwork size/style preserve text scale and the saved position")
profile.arrowTextScale = 1.8
arrow:ApplySize()
assert(title:GetEffectiveScale() == 1.8)

profile.globalTextAppearance.font, profile.globalTextAppearance.size = "Global", 18
profile.globalTextAppearance.flags = "OUTLINE"
APR:RefreshTextAppearance("arrow")
assert(title.font == "Global.ttf" and title.size == 16 and title.flags == "OUTLINE",
    "Global font, size and outline apply through the existing arrow registry")
local oldHeight = frame.actionTextFrame:GetHeight()
profile.arrowTextAppearance.useGlobal = false
profile.arrowTextAppearance.font, profile.arrowTextAppearance.size = "Arrow", 26
profile.arrowTextAppearance.flags = "MONOCHROME"
profile.arrowTextAppearance.color = {0.2, 0.4, 0.7, 0.6}
profile.arrowTextAppearance.colorOverrides = {color = true}
APR:RefreshTextAppearance("arrow")
assert(detail.font == "Arrow.ttf" and detail.size == 24 and detail.flags == "MONOCHROME")
assert(detail.textColor[3] == 0.7 and detail.textColor[4] == 0.6)
assert(frame.actionTextFrame:GetHeight() > oldHeight and detail.point[5] <= -title:GetStringHeight(),
    "Live typography changes remeasure lines and move the skip control")
for _, theme in ipairs({"wow", "modern", "graphiteModern"}) do
    profile.uiTheme = theme
    APR:RefreshRegisteredSkins(true)
    arrow:UpdateTextAppearance()
    assert(detail.font == "Arrow.ttf" and detail.textColor[4] == 0.6,
        "Native skins preserve explicit arrow text preferences")
end
local skinCalls = 0
APR.EllesmereUISkin = {
    GetFont = function(_, scope) if scope == "arrow" then return "Skin.ttf", "OUTLINE" end end,
    ApplyFont = function(_, font, scope) if scope == "arrow" then skinCalls = skinCalls + 1; font.skin = true end end,
    ApplyHeaderTextColor = function() end,
    GetTextColor = function() end,
}
APR:RefreshTextAppearance("arrow")
assert(title.font == "Skin.ttf" and title.flags == "OUTLINE" and title.skin and skinCalls > 0,
    "The existing external skin font path also styles arrow instructions")
assert(detail.textColor[4] == 0.6, "Explicit text colors survive external skin typography")

lines = {{text = string.rep("é中", 90), role = "warning"}}
arrow:UpdateActionText()
assert(frame.actionTexts[1] == title and not detail:IsShown(), "Step changes reuse fonts and retire old lines")
assert(APR.textStyleRegistry[title].options.role == "warning" and frame.actionTextFrame:GetHeight() == title:GetStringHeight())
arrow:SetArrowActive(true, 100, 100)
assert(frame:IsShown())
profile.showArrow = false
arrow:SetArrowActive(true, 100, 100)
assert(not frame:IsShown() and title:GetParent():GetParent():GetParent() == frame,
    "Action text inherits every arrow visibility decision through its parent chain")
profile.arrowActionText = false
arrow:UpdateActionText()
assert(not title:IsShown() and not frame.actionTextFrame:IsShown() and frame.Button.point[2] == frame.distance,
    "Disabling restores the existing distance/skip layout immediately")
profile.arrowActionText, lines = true, {}
arrow:UpdateActionText()
assert(not frame.actionTextFrame:IsShown(), "An empty step never leaves stale action text")
print("Arrow action text: defaults, live typography/colors/skins, wrapping, scaling, anchors, pooling and visibility passed")
