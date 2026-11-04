-- Cumulative consumptions shared by taxi and personal transports. Pure Lua 5.1.
local _, ns = ...
local Finite = ns.NavigationV2Graph.Finite
local Resources = {}
local MAX_RESOURCES = 32

function Resources.Capture(source,declared)
    if source == nil then source = {} end
    if type(source) ~= 'table' then return nil, 'invalid_resources' end
    if declared~=nil and type(declared)~='table' then return nil,'invalid_resources' end
    local result, count = {}, 0
    for key, value in pairs(source) do
        count = count + 1
        if count>MAX_RESOURCES then return nil,'resource_limit_exceeded' end
        if type(key) ~= 'string' or not key:match('%S')
            or not Finite(value) or value < 0 or value % 1 ~= 0
            or value > ns.NavigationV2Graph.SAFE_INTEGER then return nil, 'invalid_resources' end
        result[key] = value
    end
    for key in pairs(declared or {}) do
        if result[key]==nil then count=count+1 end
        if count>MAX_RESOURCES then return nil,'resource_limit_exceeded' end
    end
    return result
end

-- Replace an observer's complete contribution, including quantities now unknown.
-- Money-only callers own only money and cannot remove inventory contributions.
function Resources.Merge(base,observed,owned)
    local result,reason=Resources.Capture(base)
    if not result then return nil,reason end
    local contribution
    contribution,reason=Resources.Capture(observed)
    if not contribution then return nil,reason end
    for key in pairs(owned) do result[key]=contribution[key] end
    return Resources.Capture(result,owned)
end

-- Missing is unknown, never zero. Zero consumption requires no observation.
-- Timed personal groups use the shared cooldown decision instead of a permanent
-- spent budget. Path reconstruction reports their usage counts separately.
function Resources.Spend(balances, spent, consumption, timed)
    local result = {}
    for key, value in pairs(spent) do result[key] = value end
    for key, amount in pairs(consumption or {}) do
        if amount > 0 and not (timed and timed[key]) then
            local total = (result[key] or 0) + amount
            if not Finite(total) or total > ns.NavigationV2Graph.SAFE_INTEGER then return nil, 'resource_overflow' end
            if balances[key] == nil then return nil, 'resources_unknown' end
            if total > balances[key] then return nil, 'resources_insufficient' end
            result[key] = total
        end
    end
    return result
end

function Resources.Dominates(a, b)
    if a.cost > b.cost then return false end
    for key, value in pairs(a.spent) do if value > (b.spent[key] or 0) then return false end end
    return true
end

ns.NavigationV2Resources = Resources
return Resources
