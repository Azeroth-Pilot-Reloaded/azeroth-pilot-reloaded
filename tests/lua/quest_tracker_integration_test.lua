local env = dofile("tests/lua/route_ui_test_env.lua")
local tracker, profile = APR.QuestTracker, APR.settings.profile
local stub = LibStub
function LibStub(name, ...)
    if name == "LibSharedMedia-3.0" then return {Fetch = function() return "tracker-font" end} end
    return stub(name, ...)
end
function APR:CanAccessValue(value) return type(value) ~= "table" end
function APR:IsPetBattleActive() return false end
function APR:IsInstanceWithUI() return true end
function GetTime() return 10 end
function env.methods:GetCenter() return (self.point and self.point[4] or (self.parent and self.parent:GetCenter()) or 800), self:GetTop() - self:GetHeight() / 2 end
function env.methods:GetTop() return self.point and self.point[5] or (self.parent and self.parent:GetTop()) or 900 end
function env.methods:GetBottom() return self:GetTop() - self:GetHeight() end
function env.methods:GetLeft() return self:GetCenter() - self:GetWidth() / 2 end
function env.methods:GetBackdropBorderColor() return unpack(self.borderColor or {1, 1, 1, 1}) end
function env.methods:GetFont() return "tracker-font", 15, "OUTLINE" end
function env.methods:GetTextColor() return 0.6, 0.7, 0.8, 1 end

local legacy, fresh = {currentStepAttachFrameToQuestLog = true}, {}
assert(tracker:GetSide(legacy) == "below" and tracker:GetSide(fresh) == "above")
legacy.currentStepAttachFrameToQuestLog = false
assert(tracker:GetSide(legacy) == "below", "Changing attachment cannot rewrite the migrated side")
profile.currentStepTrackerSide = "above"
profile.currentStepAttachFrameToQuestLog, profile.enableAddon = true, true
profile.currentStepMatchTrackerStyle = true
profile.afkSnapToCurrentStep, profile.fillersFrameSnapToCurrentStep, profile.questOrderListSnapToCurrentStep = true, true, true
profile.fillersFrameShowHeader, profile.fillersFrameSnapGap = true, 7
CurrentStepScreenPanel:SetSize(250, 100)
CurrentStepFrameHeader:SetHeight(22)
function APR.currentStep:GetContentHeight() return 100 end
APR.AFK = {timerEnd = 30}
AfkFrameScreen, FillersScreenPanel, QuestOrderListPanel = env.widget(UIParent), env.widget(UIParent), env.widget(UIParent)
AfkFrameScreen:SetHeight(20); FillersScreenPanel:SetHeight(45); QuestOrderListPanel:SetHeight(200)
local total = 100 + 20 + 29 + 45 + 30 + 200
assert(APR:GetSnappedStackHeight() == total)

ObjectiveTrackerFrame = env.widget(UIParent)
local root = ObjectiveTrackerFrame
root:SetPoint("TOP", UIParent, "BOTTOMLEFT", 800, 900)
root:SetSize(300, 250)
root.Header = env.widget(root)
root.Header:SetHeight(22)
local function assertAbove(expectedHeight)
    local x, y = tracker:GetAnchor()
    assert(x == 800 and y == 878, "APR stays put when the attached stack changes")
    assert(root.point[2] == UIParent, "Tracker never joins APR's secure anchor chain")
    assert(root.point[5] == 900 - (22 + expectedHeight + 12), "Tracker reserves the complete stack")
end
assertAbove(total)
local moves = root.anchors
for _ = 1, 10 do assertAbove(total) end
assert(root.anchors == moves, "Stable layout must not mutate the tracker")
QuestOrderListPanel:Hide()
assertAbove(total - 230)
AfkFrameScreen:Hide()
assertAbove(total - 250)
profile.fillersFrameSnapToCurrentStep = false
assertAbove(100)
CurrentStepScreenPanel.collapsed = true
assertAbove(100)
CurrentStepScreenPanel.collapsed = false
env.setCombat(true)
assert(tracker:GetAnchor() == nil)
tracker:Release()
assert(root.point[5] ~= 900, "Combat defers restoring the tracker as well")
env.setCombat(false)
tracker:Release()
assert(root.point[5] == 900, "Detaching restores the owner's original points")

assertAbove(100)
root:SetPoint("TOP", UIParent, "BOTTOMLEFT", 700, 700)
tracker:Release()
assert(root.point[4] == 700 and root.point[5] == 700, "Do not overwrite a user or addon move")
tracker:GetAnchor()
tracker:Release()
assert(root.point[5] == 700, "Subsequent attachment remembers the new baseline")

-- Both third-party roots and their styles are resolved independently of Blizzard.
Questie = {db = {profile = {trackerEnabled = true, trackerFontSizeObjective = 13, trackerFontOutline = "OUTLINE"}}}
Questie_BaseFrame = env.widget(UIParent)
Questie_BaseFrame:SetPoint("TOP", UIParent, "BOTTOMLEFT", 600, 850)
Questie_BaseFrame:SetHeight(100)
Questie_BaseFrame:SetBackdrop({bgFile = "questie-bg"})
Questie_BaseFrame:SetBackdropColor(0.2, 0.3, 0.4, 0.6)
Questie_HeaderFrame = {trackedQuests = {label = env.widget()}}
local x, y = tracker:GetAnchor()
assert(x == 600 and y == 828)
local style = tracker:Style("currentStep")
assert(style.provider == "questie" and style.size == 13 and style.color[4] == 0.6)
assert(tracker:Style("arrow") == nil and tracker:Style("fillers") == nil)
local ownBackdrop = {bgFile = "apr-bg"}
CurrentStepScreenPanel:SetBackdrop(ownBackdrop)
APR:SetPanelColor(CurrentStepScreenPanel, {0, 0, 0, 0.5})
assert(CurrentStepScreenPanel:GetBackdrop().bgFile == "questie-bg")
profile.currentStepMatchTrackerStyle = false
APR:SetPanelColor(CurrentStepScreenPanel, {0, 0, 0, 0.5})
assert(CurrentStepScreenPanel:GetBackdrop() == ownBackdrop, "Opting out restores APR styling")
profile.currentStepTrackerSide = "below"
x, y = tracker:GetAnchor()
assert(x == 600 and y == 715 and Questie_BaseFrame.point[5] == 850)

local kaliel = env.widget(UIParent)
_G["!KalielsTrackerFrame"] = kaliel
kaliel:SetPoint("TOP", UIParent, "BOTTOMLEFT", 400, 800)
kaliel:SetSize(300, 600)
kaliel.Background = env.widget(kaliel)
kaliel.Background:SetHeight(80) -- visible content, NOT its 600px scroll viewport
KT_ObjectiveTrackerFrame = {Header = {Text = env.widget()}}
kaliel.SetPoint, kaliel.ClearAllPoints = function() error("Kaliel's locked setter") end, function() error("Kaliel's locked setter") end
x, y = tracker:GetAnchor()
assert(x == 400 and y == 694, "Below Kaliel follows the visible background")
profile.currentStepTrackerSide = "above"
x, y = tracker:GetAnchor()
assert(y == 778 and kaliel.point[5] == 674, "Above Kaliel translates only its outer container")
assert(Questie_BaseFrame.point[5] == 850, "Changing providers restores the previous tracker")
tracker:Release()
assert(kaliel.point[5] == 800)

-- A placement draft records a group offset, never unsets the attachment or
-- overwrites the independent current-step position. Both attachment sides move
-- the whole group and restore the tracker's base coordinates on detach.
profile.currentStepTrackerSide = "below"
tracker:GetAnchor()
local preview = env.widget(UIParent)
preview:SetSize(250, 100)
preview:SetPoint("TOP", UIParent, "BOTTOMLEFT", 420, 715)
tracker:SavePreviewPosition(preview)
assert(profile.currentStepTrackerOffset.x == 20 and profile.currentStepTrackerOffset.y == 21)
x, y = tracker:GetAnchor()
assert(x == 420 and y == 715 and kaliel.point[4] == 420 and kaliel.point[5] == 821)
tracker:Release()
assert(kaliel.point[4] == 400 and kaliel.point[5] == 800)
profile.currentStepTrackerOffset = nil

-- Appearance is scoped, reversible, and uses the provider's actual header texture.
local function texture(path)
    return {
        path = path, shown = true, alpha = 1, height = 24, color = {0.7, 0.8, 0.9, 1}, coords = {0, 1, 0, 1},
        GetTexture = function(self) return self.path end, GetAtlas = function() end,
        GetTexCoord = function(self) return unpack(self.coords) end, GetVertexColor = function(self) return unpack(self.color) end,
        GetAlpha = function(self) return self.alpha end, GetHeight = function(self) return self.height end,
        IsShown = function(self) return self.shown end, SetTexture = function(self, path) self.path = path end,
        SetTexCoord = function(self, ...) self.coords = {...} end, SetVertexColor = function(self, ...) self.color = {...} end,
        SetAlpha = function(self, alpha) self.alpha = alpha end, SetHeight = function(self, height) self.height = height end,
        SetShown = function(self, shown) self.shown = shown end, Hide = function(self) self.shown = false end,
    }
end
profile.currentStepMatchTrackerStyle = true
local header = {Background = texture("apr-header")}
tracker.headers[header] = "currentStep"
KT_ObjectiveTrackerFrame.Header.Background = texture("kaliel-header")
tracker:RefreshHeaders()
assert(header.Background.path == "kaliel-header")
profile.currentStepMatchTrackerStyle = false
tracker:RefreshHeaders()
assert(header.Background.path == "apr-header", "Native header returns when integration is disabled")
print("Tracker integration: migration, full stack, stable above/below, combat, restoration, provider changes and appearance passed")
