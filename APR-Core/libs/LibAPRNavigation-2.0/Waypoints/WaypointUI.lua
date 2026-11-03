-- Optional output boundary. No WoW globals, timers, search or quest progression.
local _, namespace = ...
local Finite = namespace.NavigationV2Graph.Finite
local WaypointUI, Session = {}, {}
Session.__index = Session
local VISUAL = { "iconTexture", "iconType", "r", "g", "b", "requestRecolor" }
local ARRIVAL_RADIUS = 5
local POSITION_TOLERANCE = 0.0000001
local COORDINATE_NUMBER = "[%+%-]?%d[%d%.,eE%+%-%%]*"

local function Text(value, fallback)
    if type(value) ~= "string" then return fallback end
    -- Reject coordinate presentations as a whole; ordinary title numbers and
    -- adjacent letters (floor 2, workshop 9E) must keep their original meaning.
    local lower = value:lower()
    if lower:find("worldmap:", 1, true) or lower:find("/way%f[%W]") then return fallback end
    value = value:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|[TtAa].-|[TtAa]", ""):gsub("|r", "")
        :gsub("%s+", " "):match("^%s*(.-)%s*$")
    lower = value:lower()
    if value:find(COORDINATE_NUMBER .. "%s*[,;:/]%s*" .. COORDINATE_NUMBER)
        or value:find(COORDINATE_NUMBER .. "%s+" .. COORDINATE_NUMBER)
        or lower:find("%f[%a][xy]%s*[:=]%s*[%+%-]?%d") then return fallback end
    if value == "" then return fallback end
    return value
end

local function Capture(target, fallback)
    if type(target) ~= "table" or type(target.key) ~= "string" or target.key == "" then
        return nil, "invalid_target"
    end
    local result = { key = target.key, name = Text(target.title, fallback) }
    local pos = target.position
    if type(pos) == "table" and Finite(pos.mapID) and pos.mapID > 0 and pos.mapID % 1 == 0
        and Finite(pos.x) and pos.x >= 0 and pos.x <= 1 and Finite(pos.y) and pos.y >= 0 and pos.y <= 1 then
        result.mapID, result.x, result.y = pos.mapID, pos.x, pos.y
    end
    if type(target.iconTexture) == "string" or Finite(target.iconTexture) then result.iconTexture = target.iconTexture end
    if target.iconType == "TEXTURE" or target.iconType == "ATLAS" then result.iconType = target.iconType end
    for _, key in ipairs({ "r", "g", "b" }) do
        if Finite(target[key]) and target[key] >= 0 and target[key] <= 1 then result[key] = target[key] end
    end
    if type(target.requestRecolor) == "boolean" then result.requestRecolor = target.requestRecolor end
    return result
end

local function Same(a, b)
    if not a or not b then return a == b end
    for _, key in ipairs({ "key", "name", "mapID", "x", "y" }) do
        if a[key] ~= b[key] then return false end
    end
    for _, key in ipairs(VISUAL) do if a[key] ~= b[key] then return false end end
    return true
end

local function Provider(session)
    local ok, api = pcall(session.getProvider)
    if not ok then return nil, "provider_error" end
    if type(api) ~= "table" or type(api.GetUserNavigation) ~= "function"
        or type(api.IsUserNavigationTracked) ~= "function" or type(api.NewUserNavigation) ~= "function"
        or type(api.ClearUserNavigation) ~= "function" then return nil, "provider_unavailable" end
    return api
end

local function Owns(session, current)
    local owned = session.owned
    return owned and type(current) == "table" and current.flags == session.flag
        and current.mapID == owned.mapID and Finite(current.x) and Finite(current.y)
        and math.abs(current.x - owned.x) < POSITION_TOLERANCE and math.abs(current.y - owned.y) < POSITION_TOLERANCE
        and current.name == owned.name
end

local function Release(session)
    if not session.owned then return true end
    local api = session.owned.api
    local ok, current = pcall(api.GetUserNavigation)
    if not ok then return nil end
    if Owns(session, current) then
        local trackedOK, tracked = pcall(api.IsUserNavigationTracked)
        if not trackedOK then return nil end
        -- A different native waypoint can coexist briefly with WUI's stale data.
        -- Never clear it, and never advance WUI's stored foreign pin queue.
        if not pcall(api.ClearUserNavigation, tracked ~= true, true) then return nil end
    end
    session.owned = nil
    return true
end

function WaypointUI.New(options)
    if type(options) ~= "table" or type(options.getProvider) ~= "function"
        or type(options.inCombat) ~= "function"
        or (options.canPublish ~= nil and type(options.canPublish) ~= "function") then return nil, "invalid_options" end
    local session = setmetatable({ getProvider = options.getProvider, inCombat = options.inCombat,
        canPublish = options.canPublish,
        defaultTitle = Text(options.defaultTitle, "APR"), status = "idle" }, Session)
    -- Unique across independent library consumers, without a global mutable owner.
    session.flag = "APR:NAV2:" .. tostring(session)
    return session
end

function Session:GetStatus() return self.status end

local function Publish(session, api)
    local target = session.target
    local options = { name = target.name, mapID = target.mapID, x = target.x * 100, y = target.y * 100,
        flags = session.flag, stripCoordinates = true, fromWUI = false, suppressAudio = true,
        suppressPathfinding = true }
    for _, key in ipairs(VISUAL) do options[key] = target[key] end
    -- Record the expected handle before calling a provider that may throw after
    -- creating its marker. Read-back, not its optional return value, proves ownership.
    session.owned = { api = api, mapID = target.mapID, x = target.x, y = target.y, name = target.name }
    session.attempted = true
    local ok = pcall(api.NewUserNavigation, options)
    local readOK, current = pcall(api.GetUserNavigation)
    if not ok or not readOK then return "provider_error" end
    if not Owns(session, current) then session.owned = nil; return "provider_rejected" end
    return "active"
end

function Session:Refresh()
    local combatOK, combat = pcall(self.inCombat)
    if not combatOK or combat ~= false then self.status = "combat"; return self.status end
    if self.release then
        if not Release(self) then self.status = "provider_error"; return self.status end
        self.release = nil
    end
    if self.terminal then self.status = self.terminal; return self.status end
    if not self.target then self.status = "idle"; return self.status end
    if not self.target.mapID then self.status = "unlocated"; return self.status end
    if self.owned then
        local ok, current = pcall(self.owned.api.GetUserNavigation)
        if not ok then self.status = "provider_error"; return self.status end
        if not Owns(self, current) then
            self.owned, self.terminal, self.status = nil, "dismissed", "dismissed"
            return self.status
        end
        local trackedOK, tracked = pcall(self.owned.api.IsUserNavigationTracked)
        if not trackedOK then self.status = "provider_error"; return self.status end
        if tracked ~= true then
            self.terminal, self.release = "dismissed", true
            return self:Refresh()
        end
        if not self.attemptFailed then self.status = "active" end
        return self.status
    end
    if self.attempted then return self.status end
    local api, reason = Provider(self)
    if not api then self.status = reason; return self.status end
    local ok, current = pcall(api.GetUserNavigation)
    if not ok then self.status = "provider_error"; return self.status end
    if current ~= nil then self.status = "occupied"; return self.status end
    if self.canPublish then
        local allowedOK, allowed = pcall(self.canPublish)
        if not allowedOK then self.status = "provider_error"; return self.status end
        if allowed ~= true then self.status = "occupied"; return self.status end
    end
    self.status = Publish(self, api)
    self.attemptFailed = self.status ~= "active"
    return self.status
end

function Session:SetTarget(target)
    local captured, reason = Capture(target, self.defaultTitle)
    if not captured then return reason end
    if Same(self.target, captured) then return self:Refresh() end
    local sameIdentity = self.target and self.target.key == captured.key
    self.target, self.release, self.attempted, self.attemptFailed = captured, self.owned ~= nil, nil, nil
    if not sameIdentity then self.terminal = nil end
    return self:Refresh()
end

function Session:Clear()
    self.target, self.terminal, self.attempted, self.attemptFailed = nil, nil, nil, nil
    self.release = self.owned ~= nil
    return self:Refresh()
end

function Session:Arrive()
    if self:Refresh() ~= "active" then return self.status end
    self.terminal, self.release = "arrived", true
    return self:Refresh()
end

-- A native arrival event is evidence only for our current tracked map point.
function Session:ObserveArrival(mapID, x, y, distance)
    if self:Refresh() ~= "active" then return self.status end
    local target = self.target
    if mapID == target.mapID and Finite(x) and Finite(y) and Finite(distance) and distance >= 0 and distance <= ARRIVAL_RADIUS
        and math.abs(x - target.x) < POSITION_TOLERANCE and math.abs(y - target.y) < POSITION_TOLERANCE then
        return self:Arrive()
    end
    return self.status
end

namespace.NavigationV2WaypointUI = WaypointUI
return WaypointUI
