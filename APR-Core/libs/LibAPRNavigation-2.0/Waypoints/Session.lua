-- One execution target, at most one output. All dependencies are injected.
local _, namespace = ...
local Target = namespace.NavigationV2WaypointTarget
local Session, Guidance = {}, {}
Session.__index = Session

function Guidance.New(options)
    if type(options) ~= "table" or (options.getAzerothWaypoint ~= nil
        and type(options.getAzerothWaypoint) ~= "function") then return nil, "invalid_options" end
    local wui, reason = namespace.NavigationV2WaypointUI.New(options)
    if not wui then return nil, reason end
    return setmetatable({ wui = wui,
        awp = namespace.NavigationV2AzerothWaypoint.New(options.getAzerothWaypoint),
        inCombat = options.inCombat, canPublish = options.canPublish,
        defaultTitle = Target.Text(options.defaultTitle, "APR"), status = "idle" }, Session)
end

function Session:GetStatus() return self.status end

local function Retire(session)
    local status = session.wui:Clear()
    if status ~= "idle" then return nil, status end
    local cleared, reason = session.awp:Clear()
    if not cleared then return nil, reason end
    session.carrier, session.release, session.attemptFailure = nil, nil, nil
    return true
end

local function Select(session)
    if session.carrier and not session.attemptFailure then
        local current = session.carrier == "awp" and session.awp:Refresh() or session.wui:Refresh()
        if current == "dismissed" or current == "arrived" then return current end
        if current == "provider_error" then return current end
    end
    local api = session.awp:Available()
    local selected = api and "awp" or "wui"
    if session.carrier and (session.carrier ~= selected or (selected == "awp" and session.awp.api ~= api)) then
        local retired, reason = Retire(session)
        if not retired then return reason end
    end
    if selected == "wui" then
        session.carrier = selected
        -- WUI validates independently; reconstruct its public target envelope.
        local target = Target.Copy(session.target)
        target.title, target.position = target.name, { mapID = target.mapID, x = target.x, y = target.y }
        return session.wui:SetTarget(target)
    end
    if session.carrier == "awp" then return session.attemptFailure or session.awp:Refresh() end
    if session.canPublish then
        local ok, allowed = pcall(session.canPublish)
        if not ok then return "provider_error" end
        if allowed ~= true then return "occupied" end
    end
    session.carrier = "awp"
    local status = session.awp:Publish(session.target, api)
    if status ~= "active" then session.attemptFailure = status end
    return status
end

function Session:Refresh()
    local ok, combat = pcall(self.inCombat)
    if not ok or combat ~= false then self.status = "combat"; return self.status end
    if self.release then
        local retired, reason = Retire(self)
        if not retired then self.status = reason; return self.status end
    end
    if self.releasing then
        local released, reason = self.awp:Release()
        if not released then self.status = reason; return self.status end
        self.releasing = nil
    end
    if self.terminal then self.status = self.terminal
    elseif not self.target then self.status = "idle"
    elseif not self.target.mapID then self.status = "unlocated"
    else
        self.status = Select(self)
        if self.status == "dismissed" or self.status == "arrived" then
            self.terminal, self.release = self.status, true
            return self:Refresh()
        end
    end
    return self.status
end

function Session:SetTarget(target)
    local captured, reason = Target.Capture(target, self.defaultTitle)
    if not captured then return reason end
    if Target.Same(self.target, captured) then return self:Refresh() end
    if not self.target or self.target.key ~= captured.key then self.terminal = nil end
    self.awp:Suppress()
    self.target, self.release = captured, true
    return self:Refresh()
end

function Session:Clear()
    self.awp:Suppress()
    self.target, self.terminal = nil, nil
    self.release = true
    return self:Refresh()
end

function Session:Dismiss()
    self.awp:Suppress()
    self.terminal, self.release = "dismissed", true
    return self:Refresh()
end

-- The host can observe the provider's public clear function without polling.
-- Our own clear suppresses publication first, so it cannot dismiss a new target.
function Session:ObserveProviderClear(api, provider)
    if provider ~= "apr" or not self.awp.published or not self.awp:IsOwner(api) then return false end
    self.awp:Suppress()
    self.terminal, self.release, self.status = "dismissed", true, "dismissed"
    return true
end

function Session:ObserveProviderReplacement(api)
    if self.awp.api ~= api or not self.awp.published or self.awp:IsOwner(api) then return false end
    self.awp:Suppress()
    self.terminal, self.release, self.status = "dismissed", true, "dismissed"
    return true
end

function Session:ObserveProviderStop(api)
    if not self.awp.published or not self.awp:IsOwner(api) or self.awp:IsStopped() ~= true then return false end
    self.awp:Suppress()
    self.terminal, self.release, self.status = "dismissed", true, "dismissed"
    return true
end

function Session:Release()
    self.releasing = true
    return self:Clear()
end

function Session:Arrive()
    if self:Refresh() ~= "active" then return self.status end
    self.terminal, self.release = "arrived", true
    return self:Refresh()
end

function Session:ObserveArrival(mapID, x, y, distance)
    if self:Refresh() ~= "active" or self.carrier ~= "wui" then return self.status end
    self.status = self.wui:ObserveArrival(mapID, x, y, distance)
    if self.status == "arrived" then self.terminal = "arrived" end
    return self.status
end

namespace.NavigationV2WaypointSession = Guidance
return Guidance
