local F = dofile("tests/lua/navigation_v2_waypoint/fixture.lua")
local session, wui, awp, env = F.Guidance()
env.combat = true
assert(session:SetTarget(F.Target()) == "combat" and awp.registrations == 0)
session:Clear()
env.combat = false
assert(session:Refresh() == "idle" and awp.registrations == 0)
session:SetTarget(F.Target())
awp:Flush()
session:Refresh()
env.combat = true
assert(session:Refresh() == "combat", "An active output pauses in combat too")
assert(session:Release() == "combat" and awp.record and #awp.clears == 0)
local target, suppressed = awp.provider.extractTarget()
assert(target == nil and suppressed == true, "Cancellation suppresses queued extraction even in combat")
env.combat = false
assert(session:Refresh() == "idle" and awp.record == nil and awp.provider == awp.original)

-- Failed cleanup blocks the handoff, retaining the objective for recovery.
session, wui, awp, env = F.Guidance()
local api = env.awp
session:SetTarget(F.Target())
awp:Flush()
session:Refresh()
awp.clearError, env.awp = true, nil
assert(session:Refresh() == "provider_error" and #wui.creates == 0 and awp.record)
awp.clearError = false
assert(session:Refresh() == "active" and #wui.creates == 1 and awp.record == nil)
session:Clear()

-- A replaced adapter and its route are foreign. No restore or deletion.
session, wui, awp, env = F.Guidance()
session:SetTarget(F.Target())
awp:Flush()
local foreign = { extractTarget = function() return nil, true end }
local foreignRecord = { guideSource = "someone-else", target = {} }
awp.provider, awp.record = foreign, foreignRecord
assert(session:Refresh() == "dismissed")
session:Release()
assert(awp.provider == foreign and awp.record == foreignRecord and #awp.clears == 0)

-- Provider publication failures cannot become an unchanged retry loop.
for _, field in ipairs({ "registrationError", "scheduleError" }) do
    session, wui, awp, env = F.Guidance()
    awp[field] = true
    assert(session:SetTarget(F.Target()) == "provider_error")
    local registrations, schedules = awp.registrations, #awp.schedules
    for _ = 1, 10 do assert(session:Refresh() == "provider_error") end
    assert(awp.registrations == registrations and #awp.schedules == schedules and #wui.creates == 0)
    awp[field] = false
    assert(session:SetTarget(F.Target("changed")) == "active")
    awp:Flush()
    assert(session:Clear() == "idle" and awp.record == nil)
end

-- Titles, subtext and raw titles share the coordinate-free boundary.
session, wui, awp, env = F.Guidance()
local data = F.Target()
data.title, data.rawTitle, data.subtext = "Gate 23, 67", "x=23 y=67", "Meet at 0.23 0.67"
data.semanticQuestID, data.aprQuestIDs = -4, { 123, false, 0, 456 }
session:SetTarget(data)
target = awp.provider.extractTarget()
assert(target.title == "Map pin" and target.rawTitle == "Map pin" and target.subtext == nil)
assert(target.semanticQuestID == nil and #target.aprQuestIDs == 2)
data.key, data.title, data.subtext = "floor", "Étage 2", "Atelier 9E"
session:SetTarget(data)
target = awp.provider.extractTarget()
assert(target.title == "Étage 2" and target.subtext == "Atelier 9E")
assert(session:SetTarget({ key = "action", title = "Use the portal" }) == "unlocated")
assert(awp.provider.extractTarget() == nil)

-- Public clear observation is synchronous: a queued evaluation cannot reopen
-- the action between host event delivery and a deferred refresh.
session, wui, awp, env = F.Guidance()
session:SetTarget(F.Target())
awp:Flush()
assert(session:ObserveProviderClear(env.awp, "other") == false)
assert(session:ObserveProviderClear({}, "apr") == false)
assert(session:ObserveProviderClear(env.awp, "apr") == true)
assert(awp.provider.extractTarget() == nil)
assert(session:Refresh() == "dismissed")
assert(session:SetTarget(F.Target()) == "dismissed")
assert(session:Dismiss() == "dismissed")

-- AWP has no unregister function: a newly created provider stays silent at
-- release and can be reused rather than blocking its own next execution.
session, wui, awp, env = F.Guidance()
awp.provider = nil
assert(session:SetTarget(F.Target()) == "active")
awp:Flush()
assert(session:Release() == "idle" and awp.provider.extractTarget() == nil)
assert(session:SetTarget(F.Target("reuse")) == "active")

-- A transient read failure is not evidence of lost ownership and must not
-- silently drop the captured publication while later reporting active.
session, wui, awp, env = F.Guidance()
session:SetTarget(F.Target())
awp:Flush()
local getter = env.awp.GetGuideTargetProvider
env.awp.GetGuideTargetProvider = function() error("transient read failure") end
assert(session:Refresh() == "provider_error")
env.awp.GetGuideTargetProvider = getter
assert(session:Refresh() == "active" and awp.provider.extractTarget() ~= nil)

-- Failed WUI cleanup must never create an AWP route alongside it.
session, wui, awp, env = F.Guidance()
local saved = env.awp
env.awp = nil
session:SetTarget(F.Target())
local clear = env.wui.ClearUserNavigation
env.wui.ClearUserNavigation = function() error("cleanup failure") end
env.awp = saved
assert(session:Refresh() == "provider_error" and wui.current and awp.registrations == 0)
env.wui.ClearUserNavigation = clear
assert(session:Refresh() == "active" and wui.current == nil and awp.registrations == 1)

-- A route source is a separate ownership boundary, even when the APR adapter
-- registration is still ours. Cancellation cannot remove a foreign record.
session, wui, awp, env = F.Guidance()
session:SetTarget(F.Target())
awp:Flush()
local foreignSource = { guideSource = "foreign-source", target = {} }
awp.record = foreignSource
assert(session:Clear() == "idle" and awp.record == foreignSource and #awp.clears == 0)
