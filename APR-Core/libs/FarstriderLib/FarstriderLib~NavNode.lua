-- FarstriderLib~NavNode.lua
-- Navigation graph node used by the Dijkstra pathfinding engine.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end

---@class NavNode
---@field getLocation fun(): Location  Returns this node's position
---@field isDynamic boolean            True for nodes whose position is resolved at runtime
---@field noAutoconnect? boolean       True if this node should not receive auto-generated TRAVEL edges
---@field wizardsSanctum? boolean      True for Wizard's Sanctum interior nodes (flag 0x40)
---@field key NavKey                   Deterministic identifier ("mapId:x:y:z" or "dynamic:suffix")
---@field edges NavEdge[]              Permanent outgoing edges
---@field tempEdges NavEdge[]          Temporary edges added per-query (cleared after each search)

local NavNode = {}
NavNode.__index = NavNode
FarstriderLib.NavNode = NavNode

--- Build a deterministic string key from a map ID and position.
--- Quantizes coordinates to `precision` decimal places to merge nearby points.
---@param mapId number
---@param pos Vec3
---@param precision? number  Decimal places to keep (default 4)
---@return NavKey
function NavNode.makeNavKey(mapId, pos, precision)
    precision = precision or 4   -- default to 4 decimal places
    local scale = 10 ^ precision -- e.g. 10⁴ = 10000

    -- multiply & round to nearest integer
    local xi = math.floor(pos.x * scale + 0.5)
    local yi = math.floor(pos.y * scale + 0.5)
    local zi = math.floor(pos.z + 0.5)

    -- string‑format your final key
    return string.format("%d:%d:%d:%d", mapId, xi, yi, zi)
end

--- Create a static NavNode at a fixed map position.
---@param mapId number
---@param pos Vec3
---@param isUI? boolean  True if `pos` is in UI-map space
---@param edges? NavEdge[]
---@return NavNode
function NavNode.create(mapId, pos, isUI, edges)
    local key = NavNode.makeNavKey(mapId, pos)
    local loc = { mapId = mapId, pos = pos, isUI = isUI }
    local self = setmetatable({
        getLocation = function() return loc end,
        isDynamic   = false,
        mapId       = mapId,
        pos         = pos,
        key         = key,
        edges       = edges or {},
        tempEdges   = {}
    }, NavNode)
    return self
end

--- Create a dynamic NavNode whose position is resolved at runtime.
---@param getLoc fun(): Location  Callable that returns the current location
---@param suffix string           Key suffix, e.g. "from" or "to"
---@param edges? NavEdge[]
---@return NavNode
function NavNode.createDynamic(getLoc, suffix, edges)
    local key = "dynamic:" .. suffix
    local self = setmetatable({
        getLocation = getLoc,
        isDynamic   = true,
        key         = key,
        edges       = edges or {},
        tempEdges   = {}
    }, NavNode)
    return self
end

---@return string
function NavNode:__tostring()
    local loc = self:getLocation()
    return string.format("NavNode<%s map=%d (%.4f, %.4f)>", self.key, loc.mapId or 0, loc.pos.x or 0, loc.pos.y or 0)
end

--- Iterate over all edges (permanent + temporary) via a coroutine.
---@param self NavNode
---@return fun(): NavEdge
function NavNode.iterateAllEdges(self)
    return coroutine.wrap(function()
        if self.edges then
            for _, edge in ipairs(self.edges) do
                coroutine.yield(edge)
            end
        end
        if self.tempEdges then
            for _, tempEdge in ipairs(self.tempEdges) do
                coroutine.yield(tempEdge)
            end
        end
    end)
end

return NavNode
