local F = dofile("tests/lua/navigation_v2_waypoint/fixture.lua")
local session, wui, awp, env = F.Guidance()
local target = F.Target()
target.title, target.subtext = "Étage 2", "Speak to the keeper"
target.semanticKind, target.semanticQuestID = "quest", 123
target.iconHintKind, target.iconHintQuestID = "quest", 123
target.aprStepKey, target.aprQuestIDs = "accept", { 123, 456 }
assert(session:SetTarget(target) == "active")
assert(#wui.creates == 0 and awp.registrations == 1, "AWP must take priority with both addons")
local bridge = awp.provider
assert(bridge.icon == "APR-logo" and bridge.iconSize == 16 and bridge.installHooks == awp.original.installHooks)
local published, suppressed = bridge.extractTarget()
assert(not suppressed and published.mapID == 42 and published.x == 0.23 and published.y == 0.67)
assert(published.title == "Étage 2" and published.rawTitle == "Étage 2" and published.subtext == target.subtext)
assert(published.guideProvider == "apr" and published.kind == "guide_goal")
assert(published.semanticKind == "quest" and published.semanticQuestID == 123)
assert(published.iconHintKind == "quest" and published.iconHintQuestID == 123)
assert(published.aprQuestIDs[2] == 456 and published.aprStepKey == "accept")
assert(bridge.getActivationToken() == target.key and bridge.getVisibilityState() == "visible")
target.title, target.aprQuestIDs[1] = "caller mutation", 999
published.aprQuestIDs[2] = 999
assert(bridge.extractTarget().title == "Étage 2" and bridge.extractTarget().aprQuestIDs[1] == 123)
assert(bridge.extractTarget().aprQuestIDs[2] == 456, "Provider snapshots must be isolated too")
awp:Flush()
assert(session:Refresh() == "active" and #awp.schedules == 1)
assert(session:ObserveArrival(42, 0.23, 0.67, 0) == "active", "A native event cannot prove AWP arrival")
assert(session:Clear() == "idle" and awp.record == nil)
local absent, blocked = bridge.extractTarget()
assert(absent == nil and blocked == true, "APR's own AWP hooks cannot restore legacy targets")
assert(session:Release() == "idle" and awp.provider == awp.original)

-- Neither addon, a single addon, and late availability retain one objective.
session, wui, awp, env = F.Guidance()
env.awp, env.wui = nil, nil
assert(session:SetTarget(F.Target()) == "provider_unavailable")
env.awp = select(1, F.AWP())
assert(session:Refresh() == "active" and #wui.creates == 0, "AWP works without WUI")
session:Clear()
session, wui, awp, env = F.Guidance()
local saved = env.awp
env.awp = nil
assert(session:SetTarget(F.Target()) == "active" and #wui.creates == 1)
env.awp = saved
assert(session:Refresh() == "active" and wui.current == nil and #wui.clears == 1)
assert(#awp.schedules == 1, "Late AWP retires WUI before publishing")
awp:Flush()
env.awp = nil
assert(session:Refresh() == "active" and #wui.creates == 2 and awp.record == nil)
assert(awp.provider.extractTarget() == nil, "Fallback suppresses stale APR hooks")
env.awp = saved
assert(session:Refresh() == "active" and wui.current == nil)

-- Incomplete AWP fails closed to WUI; a foreign WUI marker survives selection.
session, wui, awp, env = F.Guidance()
env.awp = { GetGuideTargetProvider = function() return awp.original end }
assert(session:SetTarget(F.Target()) == "active" and #wui.creates == 1)
session:Clear()
env.awp = nil
wui.current = { flags = "foreign" }
assert(session:SetTarget(F.Target("foreign")) == "occupied")
assert(wui.current.flags == "foreign")

-- Closing the provider's published route is sticky for this action, also when
-- its title changes or AWP later vanishes. It must never reopen through WUI.
session, wui, awp, env = F.Guidance()
session:SetTarget(F.Target())
awp:Flush()
session:Refresh()
awp.record = nil
assert(session:Refresh() == "dismissed")
env.awp = nil
local renamed = F.Target()
renamed.title = "A changed instruction"
assert(session:SetTarget(renamed) == "dismissed" and #wui.creates == 0)
assert(session:SetTarget(F.Target("next")) == "active" and #wui.creates == 1)

-- An already dismissed WUI target cannot resurrect through newly loaded AWP.
session, wui, awp, env = F.Guidance()
saved, env.awp = env.awp, nil
session:SetTarget(F.Target())
wui.current = nil
env.awp = saved
assert(session:Refresh() == "dismissed" and awp.registrations == 0)

-- A second consumer cannot acquire or release another V2 session's adapter.
session, wui, awp, env = F.Guidance()
session:SetTarget(F.Target())
local library = F.Load()
local other = assert(library.NewWaypointSession({
    getProvider = function() return nil end, getAzerothWaypoint = function() return env.awp end,
    inCombat = function() return false end,
}))
assert(other:SetTarget(F.Target()) == "occupied")
other:Release()
assert(awp.provider.aprNavigationV2Owner and awp.provider.extractTarget())
session:Release()

-- AWP's existing manual authority remains in control; this publication is a
-- passive guide projection, and clearing it cannot destroy the manual target.
session, wui, awp, env = F.Guidance()
local manual = { source = "another addon", title = "Foreign destination" }
awp.manual = manual
session:SetTarget(F.Target())
awp:Flush()
assert(awp.record and awp.rendered == manual)
session:Clear()
assert(awp.record == nil and awp.manual == manual and awp.rendered == manual)
