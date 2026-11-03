local F = dofile("tests/lua/navigation_v2_waypoint/fixture.lua")
local host, wui, awp, env, api = F.Host()
assert(env.hooks == 0 and next(env.events) == nil)
host:Enable(F.Graph())
assert(host:SetTarget(F.Target(), env.context) == "active")
assert(awp.registrations == 1 and #wui.creates == 0, "Real opt-in host must choose AWP")
env:Flush()
env:Fire("NAVIGATION_DESTINATION_REACHED", true)
assert(host:GetWaypointStatus() == "active", "Native distance is not AWP arrival")
assert(host:DismissTarget() == "dismissed" and awp.record == nil)
assert(host:SetTarget(F.Target(), env.context) == "dismissed")

-- Combat blocks switching carriers; the regeneration event performs cleanup
-- before AWP schedules its first route evaluation.
host, wui, awp, env, api = F.Host()
host:Enable(F.Graph())
AzerothWaypointNS = nil
host:SetTarget(F.Target(), env.context)
env.combat, AzerothWaypointNS = true, api
env:Fire("ADDON_LOADED", "AzerothWaypoint")
env:Flush()
assert(host:GetWaypointStatus() == "combat" and wui.current and awp.registrations == 0)
env.combat = false
env:Fire("PLAYER_REGEN_ENABLED")
env:Flush()
assert(host:GetWaypointStatus() == "active" and not wui.current and awp.record)

-- An invalid step context cancels output while preserving quest authority.
env.context = "next-step"
env:Fire("SUPER_TRACKING_CHANGED")
env:Flush()
assert(host:GetWaypointStatus() == "idle" and awp.record == nil and env.questCalls == 0)

-- AWP-only operation still respects an existing native marker.
host, wui, awp, env, api = F.Host()
host:Enable(F.Graph())
WaypointUIAPI = nil
env.native = { uiMapID = 42, position = { x = 0.8, y = 0.8 } }
assert(host:SetTarget(F.Target(), env.context) == "occupied" and awp.registrations == 0)
env.native = nil
env:Fire("USER_WAYPOINT_UPDATED")
env:Flush()
assert(host:GetWaypointStatus() == "active" and awp.record and #wui.creates == 0)
assert(host:SetTarget(F.Target("next"), env.context) == "active")
env:Flush()
api.ClearGuideRouteState("apr")
assert(awp.provider.extractTarget() == nil, "Public closure suppresses extraction synchronously")
env:Flush()
assert(host:GetWaypointStatus() == "dismissed" and next(env.events) == nil)
local hooks = env.hooks
host:SetTarget(F.Target("third"), env.context)
env:Flush()
assert(env.hooks == hooks, "Observers are installed once per namespace")
env.combat = true
host:Disable()
assert(awp.record and awp.provider.extractTarget() == nil and env.events.PLAYER_REGEN_ENABLED)
env.combat = false
env:Fire("PLAYER_REGEN_ENABLED")
assert(awp.record == nil and awp.provider == awp.original and next(env.events) == nil)
assert(env.questCalls == 0)

-- None -> WUI -> both -> WUI uses real host events, never two outputs.
host, wui, awp, env, api = F.Host()
host:Enable(F.Graph())
AzerothWaypointNS, WaypointUIAPI = nil, nil
assert(host:SetTarget(F.Target(), env.context) == "provider_unavailable")
local wuiAPI, wuiState = F.Provider()
WaypointUIAPI = { Navigation = wuiAPI }
env:Fire("ADDON_LOADED", "WaypointUI")
env:Flush()
assert(host:GetWaypointStatus() == "active" and #wuiState.creates == 1 and wuiState.current)
host:ClearTarget()
-- Use the native-carrying WUI from this host's fixture for the handoff.
host, wui, awp, env, api = F.Host()
host:Enable(F.Graph())
AzerothWaypointNS = nil
assert(host:SetTarget(F.Target(), env.context) == "active" and wui.current)
AzerothWaypointNS = api
env:Fire("ADDON_LOADED", "AzerothWaypoint")
env:Flush()
assert(host:GetWaypointStatus() == "active" and wui.current == nil and awp.record)
AzerothWaypointNS = nil
env:Fire("PLAYER_ENTERING_WORLD")
env:Flush()
assert(host:GetWaypointStatus() == "active" and wui.current and awp.record == nil)
assert(env.questCalls == 0)

-- Replacement is a foreign provider; never restore over it or clear its route.
host, wui, awp, env, api = F.Host()
host:Enable(F.Graph())
host:SetTarget(F.Target(), env.context)
env:Flush()
local foreign = { extractTarget = function() return nil, true end }
api.RegisterGuideTargetProvider("apr", foreign)
local foreignRecord = { guideSource = "foreign" }
awp.record = foreignRecord
env:Flush()
assert(host:GetWaypointStatus() == "dismissed" and awp.provider == foreign)
host:Disable()
assert(awp.record == foreignRecord and awp.provider == foreign)

-- AWP routing off is an explicit stop, not absence permitting WUI fallback.
host, wui, awp, env, api = F.Host()
host:Enable(F.Graph())
host:SetTarget(F.Target(), env.context)
env:Flush()
awp.routingEnabled = false
api.RecomputeCarrier()
assert(awp.provider.extractTarget() == nil)
env:Flush()
assert(host:GetWaypointStatus() == "dismissed" and awp.record == nil and #wui.creates == 0)
awp.routingEnabled = true
api.RecomputeCarrier()
assert(host:SetTarget(F.Target(), env.context) == "dismissed")
