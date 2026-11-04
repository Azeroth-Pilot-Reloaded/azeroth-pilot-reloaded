-- AWP's APR guide-provider boundary. Never publishes a native/TomTom waypoint.
local _, namespace = ...
local Target = namespace.NavigationV2WaypointTarget
local AWP, Bridge = {}, {}
Bridge.__index = Bridge
local PROVIDER = "apr"
local REQUIRED = { "GetGuideTargetProvider", "RegisterGuideTargetProvider", "GetGuideRouteState",
    "ClearGuideRouteState", "ScheduleGuideProviderEvaluation" }

function AWP.New(getProvider)
    return setmetatable({ getProvider = getProvider }, Bridge)
end

function Bridge:Available()
    if not self.getProvider then return nil end
    local ok, api = pcall(self.getProvider)
    if not ok or type(api) ~= "table" then return nil end
    for _, key in ipairs(REQUIRED) do if type(api[key]) ~= "function" then return nil end end
    return api
end

local function Owns(bridge)
    local ok, current = pcall(bridge.api.GetGuideTargetProvider, PROVIDER)
    if not ok then return nil, "provider_error" end
    return current == bridge.adapter
end

local function Output(bridge)
    if not bridge.published then return nil, true end
    local result = Target.Copy(bridge.published)
    result.title, result.rawTitle = result.name, result.rawTitle or result.name
    result.key, result.name = nil, nil
    result.guideProvider, result.kind, result.source = PROVIDER, "guide_goal", bridge.source
    return result, false
end

function Bridge:Connect(api)
    if self.api == api and self.adapter then
        local owned, reason = Owns(self)
        return owned, reason or (not owned and "dismissed" or nil)
    end
    local ok, original = pcall(api.GetGuideTargetProvider, PROVIDER)
    if not ok then return nil, "provider_error" end
    if original ~= nil and type(original) ~= "table" then return nil, "provider_unavailable" end
    if original and original.aprNavigationV2Owner then return nil, "occupied" end
    local adapter = {}
    for key, value in pairs(original or {}) do adapter[key] = value end
    self.api, self.original, self.adapter = api, original, adapter
    self.source = "apr.nav2:" .. tostring(self)
    adapter.aprNavigationV2Owner = self
    adapter.label, adapter.displayName = adapter.label or "APR", adapter.displayName or "APR"
    adapter.isLoaded = function() return true end
    adapter.getVisibilityState = function() return "visible" end
    adapter.getActivationToken = function() return self.published and self.published.key end
    adapter.extractTarget = function() return Output(self) end
    -- The native APR debug callback extracts legacy positions. Supply only text.
    adapter.getDebugLines = function() return { "APR Navigation V2" } end
    local registered, accepted = pcall(api.RegisterGuideTargetProvider, PROVIDER, adapter)
    if not registered or accepted ~= true then return nil, "provider_error" end
    return true
end

function Bridge:Publish(target, api)
    local connected, reason = self:Connect(api)
    if not connected then return reason end
    local stopped, stopReason = self:IsStopped()
    if stopped == nil then return stopReason end
    if stopped then return "dismissed" end
    self.published, self.seenRecord = target, nil
    local ok, accepted = pcall(api.ScheduleGuideProviderEvaluation, PROVIDER, "apr_navigation_v2")
    if not ok or accepted ~= true then self.published = nil; return "provider_error" end
    return "active"
end

function Bridge:Refresh()
    local owned, reason = Owns(self)
    if owned == nil then return reason end
    if not owned then self.published = nil; return "dismissed" end
    local stopped, stopReason = self:IsStopped()
    if stopped == nil then return stopReason end
    if stopped then self.published = nil; return "dismissed" end
    local ok, record = pcall(self.api.GetGuideRouteState, PROVIDER)
    if not ok then return "provider_error" end
    if record ~= nil then
        if type(record) ~= "table" or record.guideSource ~= self.source then return "occupied" end
        self.seenRecord = true
    elseif self.seenRecord then
        self.published = nil
        return "dismissed"
    end
    return "active"
end

function Bridge:IsStopped()
    if type(self.api.IsRoutingEnabled) ~= "function" then return false end
    local ok, enabled = pcall(self.api.IsRoutingEnabled)
    if not ok then return nil, "provider_error" end
    return enabled == false
end

function Bridge:IsOwner(api)
    return self.api == api and self.adapter ~= nil and Owns(self) == true
end

function Bridge:Suppress()
    self.published = nil
end

function Bridge:Clear()
    -- Pending AWP evaluations consult this adapter, never a captured old target.
    self.published, self.seenRecord = nil, nil
    if not self.api or not self.adapter then return true end
    local owned, reason = Owns(self)
    if owned == nil then return nil, reason end
    if not owned then return true end
    local ok, record = pcall(self.api.GetGuideRouteState, PROVIDER)
    if not ok then return nil, "provider_error" end
    if type(record) == "table" and record.guideSource == self.source then
        if not pcall(self.api.ClearGuideRouteState, PROVIDER) then return nil, "provider_error" end
    end
    return true
end

function Bridge:Release()
    local cleared, reason = self:Clear()
    if not cleared then return nil, reason end
    if not self.api then return true end
    local owned, why = Owns(self)
    if owned == nil then return nil, why end
    if owned and self.original then
        local ok, accepted = pcall(self.api.RegisterGuideTargetProvider, PROVIDER, self.original)
        if not ok or accepted ~= true then return nil, "provider_error" end
    end
    -- AWP exposes no unregister operation. With no previous APR adapter, keep
    -- this silent registration reusable by the same owner after re-enabling.
    if owned and not self.original then return true end
    self.api, self.adapter, self.original = nil, nil, nil
    return true
end

namespace.NavigationV2AzerothWaypoint = AWP
return AWP
