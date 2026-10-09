-- Model Blizzard's managed positioning, native screen clamp and UpdateHeight.
-- These mechanisms were absent from the simple coordinate-only adapter tests.
local env = dofile("tests/lua/route_ui_test_env.lua")
local methods, profile = env.methods, APR.settings.profile
local nativePoint, nativeHeight = methods.SetPoint, methods.SetHeight
function methods:SetPoint(point, relative, relativePoint, x, y)
    nativePoint(self, point, relative, relativePoint, math.floor(x * 64 + 0.5) / 64, math.floor(y * 64 + 0.5) / 64)
end
function methods:SetHeight(value)
    nativeHeight(self, value)
    if self == ObjectiveTrackerFrame then self.dirty = true end
end
function methods:SetClampedToScreen(value) assert(not InCombatLockdown()); self.clamped = value end
function methods:IsClampedToScreen() return self.clamped == true end
function methods:GetTop()
    if self == UIParent then return self:GetHeight() end
    local p = self.point
    local top
    if p then
        local origin = p[3] == "BOTTOMLEFT" and 0 or p[2]:GetTop()
        top = origin * p[2]:GetEffectiveScale() / self:GetEffectiveScale() + p[5]
    else top = self.parent and self.parent:GetTop() or 0 end
    if self.clamped then top = math.max(self:GetHeight(), top) end
    return top
end
function methods:GetCenter()
    return self.point and self.point[4] or 960, self:GetTop() - self:GetHeight() / 2
end
function methods:GetBottom() return self:GetTop() - self:GetHeight() end
function APR:CanAccessValue(value) return type(value) ~= "table" end
function GetTime() return 10 end
UIParent:SetSize(1920, 1080)
-- Native mutation APIs are captured when the integration loads.
dofile("APR-Core/integrations/QuestTracker.lua")
local tracker = APR.QuestTracker
local manager = env.widget(UIParent)
manager:SetSize(1920, 1080)
manager:SetPoint("TOP", UIParent, "TOPLEFT", 0, 0)
manager.showingFrames = {}
ObjectiveTrackerFrame = env.widget(manager)
local root = ObjectiveTrackerFrame
root.Header = env.widget(root)
root.Header:SetHeight(32)
root.modules = {}
root.defaultPosition, root.editModeHeight = true, 800
root.ownerX, root.ownerY = 1700, -100
root:SetSize(260, 980)
root:SetClampedToScreen(true)
function root:GetManagedFrameContainer() return manager end
function root:IsInDefaultPosition() return self.defaultPosition end
function root:UpdateHeight()
    -- ObjectiveTrackerContainerMixin uses parent height + anchor offset in the
    -- default layout, and the saved Edit Mode height in a customized layout.
    if self:IsInDefaultPosition() then
        self:SetHeight(math.max(self:GetParent():GetHeight() + select(5, self:GetPoint()), 20))
    else self:SetHeight(self.editModeHeight) end
end
function manager:UpdateFrame(frame)
    frame:ClearAllPoints()
    frame:SetParent(self)
    frame:SetPoint("TOP", self, "TOPLEFT", frame.ownerX, frame.ownerY)
    frame:UpdateHeight()
end
function manager:AddManagedFrame(frame)
    if frame.ignoreFramePositionManager or not frame:IsInDefaultPosition() or not frame:IsShown() then return end
    self.showingFrames[frame] = frame
    self:UpdateFrame(frame)
end
function manager:RemoveManagedFrame(frame)
    if not self.showingFrames[frame] then return end
    self.showingFrames[frame] = nil
    frame:UpdateHeight()
end
function manager:UpdateManagedFrames()
    for frame in pairs(self.showingFrames) do self:UpdateFrame(frame) end
end
function root:ApplySystemAnchor()
    if self:IsInDefaultPosition() then
        self.ignoreFramePositionManager = nil
        manager:AddManagedFrame(self)
    else
        self.ignoreFramePositionManager = true
        manager:RemoveManagedFrame(self)
        self:SetParent(UIParent)
        self:SetPoint("TOP", UIParent, "TOPLEFT", self.ownerX / self:GetScale(), self.ownerY / self:GetScale())
    end
    self:UpdateHeight()
end
root:ApplySystemAnchor()
profile.currentStepAttachFrameToQuestLog, profile.enableAddon = true, true
profile.currentStepTrackerSide = "above"
profile.afkSnapToCurrentStep, profile.fillersFrameSnapToCurrentStep, profile.questOrderListSnapToCurrentStep = true, true, true
profile.fillersFrameShowHeader, profile.fillersFrameSnapGap = true, 7
CurrentStepScreenPanel:SetHeight(30)
CurrentStepFrameHeader:SetHeight(32)
function APR.currentStep:GetContentHeight() return 120 end
APR.AFK = {timerEnd = 30}
AfkFrameScreen, FillersScreenPanel, QuestOrderListPanel = env.widget(UIParent), env.widget(UIParent), env.widget(UIParent)
AfkFrameScreen:SetHeight(24); FillersScreenPanel:SetHeight(60); QuestOrderListPanel:SetHeight(240)
local function close(a, b, message) assert(math.abs(a - b) < 0.05, message .. ": " .. a .. " / " .. b) end
local baseX, baseTop = 1700, 980
local function checkAbove()
    local x, y = tracker:GetAnchor()
    local offset = profile.currentStepTrackerOffset or {x = 0, y = 0}
    close(x, baseX + offset.x, "APR keeps its horizontal position")
    close(y, baseTop + offset.y - 32, "APR keeps its top when its stack grows")
    local scale = root:GetEffectiveScale() / UIParent:GetEffectiveScale()
    close(root:GetTop() * scale, y - APR:GetSnappedStackHeight() - 12,
        "Blizzard stays below the complete APR stack, including all gaps")
    assert(root:GetBottom() * scale >= 11.95, "The native viewport must fit on screen")
    assert(root:GetParent() == UIParent and root.point[2] == UIParent,
        "Neither tracker parenting nor anchors may include APR's secure frames")
end
assert(APR:GetSnappedStackHeight() == 503)
checkAbove()
assert(root:GetHeight() == 421 and root.ignoreFramePositionManager and not manager.showingFrames[root])
local moves = root.anchors
for _ = 1, 10 do manager:UpdateManagedFrames(); checkAbove() end
assert(root.anchors == moves, "Default managed updates cannot reset the anchor or create drift")
QuestOrderListPanel:Hide()
checkAbove()
assert(root:GetHeight() == 691)
QuestOrderListPanel:Show()
checkAbove()
profile.fillersFrameSnapGap = 27
checkAbove()
assert(root:GetHeight() == 401, "Configured filler spacing reserves additional space")
AfkFrameScreen:Hide()
checkAbove()
FillersScreenPanel:Hide()
checkAbove()
QuestOrderListPanel:Hide()
checkAbove()
CurrentStepScreenPanel.collapsed = true
checkAbove()
assert(root:GetHeight() == 894, "Collapsing APR returns unused room to Blizzard")
CurrentStepScreenPanel.collapsed = false
QuestOrderListPanel:Show()
-- OnShow / other right-managed frames also call Blizzard's UpdateHeight.
root:UpdateHeight()
manager:AddManagedFrame(root)
checkAbove()
root:ApplySystemAnchor()
checkAbove()
checkAbove()
profile.currentStepTrackerOffset = {x = 0.12345, y = -0.54321}
checkAbove()
checkAbove()
env.setCombat(true)
local before = root.anchors
assert(tracker:GetAnchor() == nil)
tracker:Release()
assert(root.anchors == before and tracker.displacement, "Combat postpones all native layout mutations")
env.setCombat(false)
checkAbove()
tracker:Release()
assert(root:GetParent() == manager and manager.showingFrames[root] and root.ignoreFramePositionManager == nil)
assert(root:GetTop() == 980 and root:GetHeight() == 980 and root:IsClampedToScreen(),
    "Unsnap restores native position, managed layout, full height and screen clamping")
profile.currentStepTrackerOffset = nil

-- Release before Edit Mode moves the tracker, then respect its new anchor/scale.
checkAbove()
EditModeManagerFrame = {IsShown = function() return true end}
assert(tracker:GetAnchor() == nil and not tracker.displacement)
root.defaultPosition, root.ownerX, root.ownerY = false, 1400, -180
root:SetScale(0.8)
root:ApplySystemAnchor()
EditModeManagerFrame = nil
baseX, baseTop = 1400, 900
checkAbove()
assert(root.editModeHeight == 800, "APR never edits the saved tracker height")
root:UpdateHeight()
checkAbove()
tracker:Release()
close(root:GetTop() * 0.8, 900, "Custom Edit Mode position is restored")
assert(root:GetHeight() == 800 and root:GetScale() == 0.8 and root.ignoreFramePositionManager == true)
-- An external anchor change must win on detach, even outside Edit Mode.
checkAbove()
root:SetPoint("TOP", UIParent, "TOPLEFT", 1500 / 0.8, -100 / 0.8)
tracker:Release()
close(root:GetTop() * 0.8, 980, "Do not overwrite an external move")
baseX, baseTop = 1500, 980
checkAbove()
profile.currentStepTrackerSide = "below"
tracker:GetAnchor()
assert(not tracker.displacement and root:GetHeight() == 800 and root:IsClampedToScreen(),
    "Switching to legacy below releases the above-only reservation")
print("Blizzard tracker: managed layout, screen clamp, complete stack/gaps, dynamic visibility, Edit Mode, scale, combat and restoration passed")
