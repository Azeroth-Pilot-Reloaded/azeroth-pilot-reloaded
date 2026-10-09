local env = dofile("tests/lua/route_ui_test_env.lua")
local methods, profile = env.methods, APR.settings.profile
local nativePoint, nativeHeight = methods.SetPoint, methods.SetHeight
local nativeGetHeight = methods.GetHeight
function methods:SetHeight(value)
    if self.kalielRoot then self.actualHeight = value else nativeHeight(self, value) end
end
function methods:GetHeight() return self.kalielRoot and self.actualHeight or nativeGetHeight(self) end
function methods:SetClampedToScreen(value) self.clamped = value end
function methods:IsClampedToScreen() return self.clamped == true end
function methods:SetPoint(point, relative, relativePoint, x, y)
    nativePoint(self, point, relative, relativePoint, math.floor(x * 64 + 0.5) / 64, math.floor(y * 64 + 0.5) / 64)
end
function methods:GetTop()
    local top = self.point and self.point[5] or (self.parent and self.parent:GetTop()) or 1000
    if self.clamped then top = math.max(self:GetHeight(), math.min(1000, top)) end
    return top
end
function methods:GetCenter() return self.point and self.point[4] or (self.parent and self.parent:GetCenter()) or 800, self:GetTop() - self:GetHeight() / 2 end
function methods:GetBottom() return self:GetTop() - self:GetHeight() end
function methods:GetBackdropBorderColor() return unpack(self.borderColor or {1, 1, 1, 1}) end
function methods:GetFont() return "old-font", 12, "" end
function methods:GetTextColor() return 1, 1, 1, 1 end
function APR:CanAccessValue(value) return type(value) ~= "table" end
function hooksecurefunc(target, key, callback)
    local original = target[key]
    target[key] = function(...) original(...); callback(...) end
end

-- Reload after installing native frame behaviour, as WoW has it before loading APR.
dofile("APR-Core/integrations/QuestTracker.lua")
local tracker = APR.QuestTracker
local root = env.widget(UIParent)
_G["!KalielsTrackerFrame"] = root
root.Background = env.widget(root)
root:SetSize(305, 600)
root.kalielRoot, root.actualHeight = true, 600
root.Background:SetSize(305, 600)
root:SetClampedToScreen(true)
root:SetPoint("TOP", UIParent, "BOTTOMLEFT", 700, 900)
root.Scroll = env.widget(root)
root.Scroll.scroll = 500
function root.Scroll:GetVerticalScrollRange() return math.max(0, 800 - root:GetHeight()) end
root.SetPoint, root.SetHeight, root.SetClampedToScreen = function() error("Locked SetPoint") end,
    function() error("Locked SetHeight") end, function() error("Locked SetClampedToScreen") end
local kt = {
    frame = root, font = "kaliel-font", MEDIA_PATH = "kaliel-media/",
    db = {profile = {maxHeight = 600, fontSize = 14, fontFlag = "OUTLINE", fontShadow = 0,
        hdrBgr = 2, hdrTrackerBgrShow = true, hdrTxtColor = {r = 1, g = 0.8, b = 0},
        hdrBgrColor = {r = 0.8, g = 0.6, b = 0}, hdrBtnColor = {r = 1, g = 0.8, b = 0}}},
    contentHeight = 600, x = 700, top = 900,
}
function kt:Tracker_Move() methods.SetPoint(root, "TOP", UIParent, "BOTTOMLEFT", self.x, self.top) end
function kt:Tracker_SetSize(forced)
    local height = math.min(self.contentHeight, self.db.profile.maxHeight)
    if height ~= root.height or forced then
        methods.SetHeight(root, self.db.profile.maxHeight)
        root.Background:SetHeight(height)
        root.height = height
    end
end
function kt.QuestButtons_Move() root.buttonsTop = root:GetTop() end
local stub = LibStub
function LibStub(name, ...)
    -- Real MSA-AceAddon removes Kaliel from the AceAddon registry after creation.
    if name == "MSA-AceAddon-3.0" then return {GetAddon = function() return nil end} end
    if name == "MSA-Event-1.0" then return {embeds = {[kt] = true, [{frame = env.widget()}] = true}} end
    return stub(name, ...)
end
assert(tracker:GetKaliel() == kt, "Resolve the real embedded instance even when AceAddon cannot find it")
KT_ObjectiveTrackerFrame = {Header = {Text = env.widget()}}
profile.currentStepAttachFrameToQuestLog, profile.currentStepMatchTrackerStyle = true, true
profile.currentStepTrackerSide = "above"
local stackHeight = 400
function APR:GetSnappedStackHeight() return stackHeight end
function APR:GetSnappedStack() return {{frame = CurrentStepScreenPanel, height = stackHeight}} end
CurrentStepFrameHeader:SetHeight(22)
local function checkAbove()
    local x, y = tracker:GetAnchor()
    assert(x == kt.x and y == kt.top - 22, "APR keeps its top fixed")
    local target = kt.top - 22 - stackHeight - 4
    assert(root:GetTop() == target, "Screen clamping must not push Kaliel back over APR")
    assert(root:GetBottom() >= 12, "The scroll viewport fits below the complete APR stack")
    assert(root.buttonsTop == target, "Separate quest-item buttons follow the actual tracker")
    assert(kt.db.profile.maxHeight == 600, "The user's configured height is never modified")
end
checkAbove()
assert(root:GetHeight() == 462 and root.Background:GetHeight() == 462)
assert(CurrentStepScreenPanel:GetWidth() + 16 == root.Background:GetWidth(), "APR and Kaliel backgrounds have equal widths")
local moves = root.anchors
for _ = 1, 10 do checkAbove() end
assert(root.anchors == moves, "No repeated point mutations at rest")
stackHeight = 520
checkAbove()
assert(root:GetHeight() == 342)
kt:Tracker_SetSize()
assert(root:GetHeight() == 342, "A Kaliel content update cannot reclaim the reserved space")
stackHeight = 200
checkAbove()
assert(root.Background:GetHeight() == 600, "The journal regains its height when APR shrinks, even after a no-op owner update")
stackHeight = 520
checkAbove()
kt.contentHeight = 100
kt:Tracker_SetSize()
checkAbove()
assert(root.Background:GetHeight() == 100)
kt.top = 950
kt:Tracker_Move()
checkAbove()
env.setCombat(true)
local previousTop = root:GetTop()
kt.contentHeight = 140
kt:Tracker_SetSize()
tracker:Release()
assert(root:GetTop() == previousTop and tracker.displacement, "Combat defers restoration")
env.setCombat(false)
checkAbove()
assert(root.Background:GetHeight() == 140, "A size update during combat is remembered")
tracker:Release()
assert(root:GetTop() == 950 and root:GetHeight() == 600 and root:IsClampedToScreen())
assert(root.Background:GetHeight() == 140 and root.buttonsTop == 950)

-- Rounded native anchors must still be recognized when detaching.
profile.currentStepTrackerOffset = {x = 0.12345, y = 0.54321}
tracker:GetAnchor()
tracker:GetAnchor()
tracker:Release()
assert(root:GetTop() == 950 and root.point[4] == 700, "Restore after native anchor rounding")
profile.currentStepTrackerOffset = nil
profile.currentStepTrackerSide = "below"
local _, y = tracker:GetAnchor()
assert(y == 784 and root:GetTop() == 950, "Below keeps Kaliel's top and follows its visible content with a compact gap")
kt.contentHeight = 600
kt:Tracker_SetSize()
_, y = tracker:GetAnchor()
assert(root:GetHeight() == 392 and y - stackHeight == 12, "Below reserves room for all of APR, including its header")
local previousAnchors = root.anchors
for _ = 1, 10 do tracker:GetAnchor() end
assert(root.anchors == previousAnchors, "Below must not drift or repeatedly restore/reapply the viewport")
stackHeight = 100
_, y = tracker:GetAnchor()
assert(root:GetHeight() == 600 and y - stackHeight >= 12, "Kaliel expands again when the APR stack shrinks")
tracker:Release()
assert(root:IsClampedToScreen() and root:GetHeight() == 600 and root:GetTop() == 950)

-- The body has one surface, while main/module headers use distinct artwork.
local function texture(path)
    local tex = env.widget()
    tex.path, tex.coords, tex.color, tex.alpha = path, {0, 1, 0, 1}, {1, 1, 1, 1}, 1
    function tex:GetTexture() return self.path end
    function tex:SetTexture(value) self.path = value end
    function tex:GetAtlas() return self.atlas end
    function tex:SetAtlas(value) self.atlas = value end
    function tex:GetTexCoord() return unpack(self.coords) end
    function tex:SetTexCoord(...) self.coords = {...} end
    function tex:GetVertexColor() return unpack(self.color) end
    function tex:SetVertexColor(...) self.color = {...} end
    function tex:GetAlpha() return self.alpha end
    function tex:SetAlpha(value) self.alpha = value end
    return tex
end
local function button()
    local b = env.widget()
    for _, state in ipairs({"Normal", "Pushed", "Highlight", "Disabled"}) do
        b[state] = texture("apr-" .. state)
        b["Get" .. state .. "Texture"] = function(self) return self[state] end
        b["Set" .. state .. "Texture"] = function(self, path) self[state]:SetTexture(path) end
    end
    return b
end
function kt.SetSprite(tex, sprite) tex:SetTexture(sprite); tex:SetTexCoord(0.1, 0.9, 0.2, 0.8) end
local header = env.widget(CurrentStepScreenPanel)
header.Background, header.MinimizeButton = texture("apr-header"), button()
header.MinimizeButton:SetScript("OnClick", function(self)
    CurrentStepScreenPanel.collapsed = true
    self.Normal:SetTexture("apr-expanded-Normal")
    self.Pushed:SetTexture("apr-expanded-Pushed")
end)
local moduleHeader = env.widget(QuestOrderListPanel)
moduleHeader.Background = texture("apr-module")
tracker.headers[header], tracker.headers[moduleHeader] = "currentStep", "questOrderList"
profile.questOrderListSnapToCurrentStep = true
CurrentStepFrameSettingsButton = button()
CurrentStepFrame_StepHolder_RollbackButton = button()
CurrentStepFrame_StepHolder_SkipButton = button()
root.Background:SetBackdrop({bgFile = "kaliel-background", edgeFile = "kaliel-border"})
root.Background:SetBackdropColor(0.1, 0.2, 0.3, 0.7)
tracker:RefreshHeaders()
assert(header.Background.path == "tracker-header-bgr-1")
assert(moduleHeader.Background.path == "module-header-bgr-1")
assert(header.MinimizeButton:GetWidth() == 16)
header.MinimizeButton.scripts.OnClick(header.MinimizeButton)
assert(header.MinimizeButton.Normal.coords[3] == 0, "Collapse immediately uses Kaliel's expand icon")
assert(CurrentStepFrame_StepHolder_RollbackButton.Normal.path == "arrow-left")
assert(CurrentStepFrame_StepHolder_RollbackButton:GetWidth() == 20)
assert(CurrentStepFrameSettingsButton.Normal.path == "kaliel-media/UI-KT-HeaderButtons", "Menu uses Kaliel artwork, not the Blizzard gear")
assert(header:GetWidth() == CurrentStepScreenPanel:GetWidth(), "Header follows the adapted width")
local row = env.widget(CurrentStepScreenPanel)
APR:SetPanelColor(row, {0, 0, 0, 0.5})
APR:SetPanelColor(CurrentStepScreenPanel, {0, 0, 0, 0.5})
tracker:RefreshSurface()
assert(row.backdropColor[4] == 0 and CurrentStepScreenPanel.backdropColor[4] == 0, "Rows must not stack translucent backgrounds")
assert(tracker.surface:GetHeight() == stackHeight + 30, "Background covers actual content, not the 30px root")
assert(tracker.surface:GetBackdrop().bgFile == "kaliel-background" and tracker.surface.backdropColor[4] == 0.7)
local style = tracker:Style("currentStep")
assert(style.font == "kaliel-font" and style.size == 14 and style.headerSize == 15 and style.shadow == 0)
root.Background:SetWidth(360)
tracker:RefreshWidths()
tracker:RefreshHeaders()
tracker:RefreshSurface()
assert(CurrentStepScreenPanel:GetWidth() == 344 and tracker.surface:GetWidth() == 360, "Live Kaliel resizing includes the surface padding")
assert(header:GetWidth() == 344)
root:SetScale(0.8)
tracker:RefreshWidths()
tracker:RefreshHeaders()
tracker:RefreshSurface()
assert(math.abs(tracker.surface:GetWidth() - 288) < 0.01, "Widths use rendered pixels at non-default tracker scales")
assert(math.abs(header.MinimizeButton:GetWidth() - 12.8) < 0.01)
assert(math.abs(tracker:Style("currentStep").size - 11.2) < 0.01, "Fonts and icons follow the tracker scale too")
root:SetScale(1)
kt.db.profile.hdrBgr = 1
tracker:RefreshHeaders()
assert(not header.Background:IsShown() and not moduleHeader.Background:IsShown())
profile.currentStepMatchTrackerStyle = false
tracker:RefreshWidths()
tracker:RefreshHeaders()
tracker:RefreshSurface()
assert(header.Background.path == "apr-header" and header.Background:IsShown())
assert(header.MinimizeButton.Normal.path == "apr-expanded-Normal" and header.MinimizeButton:GetWidth() == 250)
assert(row.backdropColor[4] == 0.5 and not tracker.surface:IsShown(), "Detaching restores APR's original surfaces")
assert(CurrentStepScreenPanel:GetWidth() == 250 and APR.currentStep.layout.width == 250, "Opt-out restores APR's native width")
print("Kaliel: screen clamping, viewport, owner callbacks, rounding, combat, restore, headers, controls and continuous surface passed")
