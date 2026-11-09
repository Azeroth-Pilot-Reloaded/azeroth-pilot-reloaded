local env = dofile("tests/lua/route_ui_test_env.lua")
local methods, profile = env.methods, APR.settings.profile
local tracker = APR.QuestTracker
local stub = LibStub
function LibStub(name, ...)
    if name == "LibSharedMedia-3.0" then return { Fetch = function() return "tracker-font" end } end
    return stub(name, ...)
end
function APR:CanAccessValue(value) return type(value) ~= "table" end
function methods:GetCenter() return self.point and self.point[4] or 600, self:GetTop() - self:GetHeight() / 2 end
function methods:GetTop() return self.point and self.point[5] or 900 end
function methods:GetBottom() return self:GetTop() - self:GetHeight() end
function methods:StartMoving()
    self.moving = true
    self.starts = (self.starts or 0) + 1
end
function methods:StopMovingOrSizing()
    self.moving = false
    self.stops = (self.stops or 0) + 1
end
function methods:RegisterEvent(event)
    self.events = self.events or {}
    self.events[event] = true
end
function methods:UnregisterEvent(event) self.events[event] = nil end
function APR.currentStep:GetContentHeight() return 100 end
profile.enableAddon, profile.currentStepAttachFrameToQuestLog = true, true
profile.currentStepTrackerSide = "above"
profile.currentStepLock = false
CurrentStepFrameHeader:SetHeight(22)
CurrentStepScreenPanel:SetSize(250, 100)
local header = CurrentStepFrameHeader.scripts
local independentPosition = { point = "CENTER", x = 10, y = 20 }
profile.currentStepFrame = independentPosition

for _, provider in ipairs({ "questie", "kaliel" }) do
    Questie_BaseFrame, Questie, _G["!KalielsTrackerFrame"] = nil, nil, nil
    local root = env.widget(UIParent)
    root:SetSize(300, 100)
    root:SetPoint("TOP", UIParent, "BOTTOMLEFT", 600, 900)
    if provider == "questie" then
        Questie_BaseFrame = root
        Questie = { db = { profile = { trackerEnabled = true } } }
    else
        _G["!KalielsTrackerFrame"] = root
        root.Background = env.widget(root)
        root.Background:SetHeight(100)
        root.SetPoint, root.ClearAllPoints =
            function() error("Locked setter") end, function() error("Locked setter") end
    end
    profile.currentStepTrackerOffset = { x = 15, y = -20 }
    APR.currentStep:RefreshQuestTrackerAnchor()
    local gap = provider == "kaliel" and 4 or 12
    assert(root.point[5] == 880 - 122 - gap)
    header.OnMouseDown(CurrentStepFrameHeader, "LeftButton")
    assert(tracker.drag and tracker.dragProxy.moving, "Above: APR header starts group dragging")
    local starts = tracker.dragProxy.starts
    header.OnDragStart(CurrentStepFrameHeader)
    assert(tracker.dragProxy.starts == starts, "Mouse and drag events must not restart the move")
    tracker.dragProxy:SetPoint("TOP", UIParent, "BOTTOMLEFT", 655, 828)
    tracker.dragProxy.scripts.OnUpdate()
    assert(profile.currentStepTrackerOffset.x == 55 and profile.currentStepTrackerOffset.y == -50)
    assert(CurrentStepScreenPanel.point[4] == 655 and CurrentStepScreenPanel.point[5] == 828)
    assert(root.point[4] == 655 and root.point[5] == 850 - 122 - gap, "Tracker follows during the drag")
    local applied = root.point[5]
    tracker.dragProxy.scripts.OnUpdate()
    assert(root.point[5] == applied, "A stationary cursor must not accumulate displacement")
    header.OnMouseUp(CurrentStepFrameHeader, "LeftButton")
    header.OnDragStop(CurrentStepFrameHeader)
    assert(not tracker.drag and not tracker.dragProxy.moving and not tracker.dragProxy.scripts.OnUpdate)
    assert(not tracker.dragProxy.events.PLAYER_REGEN_DISABLED, "Inactive drag leaves no event listener")
    tracker:Release()
    assert(root.point[4] == 600 and root.point[5] == 900, "Detach restores provider placement")
    APR.currentStep:RefreshQuestTrackerAnchor()
    assert(root.point[4] == 655 and root.point[5] == applied, "Saved group offset survives reattachment")

    header.OnDragStart(CurrentStepFrameHeader)
    env.setCombat(true)
    tracker.dragProxy:SetPoint("TOP", UIParent, "BOTTOMLEFT", 100, 100)
    tracker.dragProxy.scripts.OnEvent(tracker.dragProxy, "PLAYER_REGEN_DISABLED")
    assert(not tracker.drag and not tracker.dragProxy.moving)
    assert(
        profile.currentStepTrackerOffset.x == 55 and root.point[5] == applied,
        "Combat cannot mutate attached frames"
    )
    header.OnDragStart(CurrentStepFrameHeader)
    assert(not tracker.drag, "Combat rejects a new drag")
    env.setCombat(false)
    profile.currentStepLock = true
    header.OnDragStart(CurrentStepFrameHeader)
    assert(not tracker.drag, "APR lock is respected")
    profile.currentStepLock = false
    header.OnDragStart(CurrentStepFrameHeader)
    local replacement = {}
    for key, value in pairs(profile) do
        replacement[key] = value
    end
    APR.settings.profile = replacement
    tracker.dragProxy:SetPoint("TOP", UIParent, "BOTTOMLEFT", 100, 100)
    tracker.dragProxy.scripts.OnUpdate()
    assert(
        not tracker.drag and profile.currentStepTrackerOffset.x == 55 and replacement.currentStepTrackerOffset.x == 55,
        "Profile changes cancel without writing either profile"
    )
    APR.settings.profile = profile
    tracker:Release()
    profile.currentStepTrackerSide = "below"
    header.OnDragStart(CurrentStepFrameHeader)
    assert(not tracker.drag, "Below retains native tracker movement")
    profile.currentStepTrackerSide = "above"
    profile.currentStepTrackerOffset = nil
    tracker:GetAnchor()
    methods.SetPoint(root, "TOP", UIParent, "BOTTOMLEFT", 500, 700)
    root.isMoving = true
    tracker:GetAnchor()
    assert(root.point[4] == 500 and root.point[5] == 700, "Never restore old anchors during a native move")
    root.isMoving = false
    tracker:GetAnchor()
    tracker:Release()
    assert(root.point[4] == 500 and root.point[5] == 700, "Native move establishes a new baseline")
end
assert(
    profile.currentStepFrame == independentPosition and independentPosition.x == 10 and independentPosition.y == 20,
    "Attached dragging must preserve the independent APR position"
)
assert(not CurrentStepScreenPanel.starts, "Attached dragging moves only the unprotected proxy")
profile.currentStepAttachFrameToQuestLog = false
header.OnMouseDown(CurrentStepFrameHeader, "LeftButton")
header.OnDragStart(CurrentStepFrameHeader)
assert(CurrentStepScreenPanel.moving and CurrentStepScreenPanel.starts == 1)
header.OnMouseUp(CurrentStepFrameHeader, "LeftButton")
header.OnDragStop(CurrentStepFrameHeader)
assert(not CurrentStepScreenPanel.moving and CurrentStepScreenPanel.stops == 1, "Independent drag stops exactly once")
print("Tracker dragging: both providers, live grouping, persistence, locks, native moves and combat passed")
