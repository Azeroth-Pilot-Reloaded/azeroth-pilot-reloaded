-- Captured execution target shared by optional output providers. No WoW globals.
local _, namespace = ...
local Finite = namespace.NavigationV2Graph.Finite
local Target = {}
local COORDINATE_NUMBER = "[%+%-]?%d[%d%.,eE%+%-%%]*"
local TEXT_FIELDS = { "subtext", "rawTitle", "semanticKind", "semanticTravelType", "iconHintKind",
    "aprStepKey", "aprTitleSource", "aprSubtextSource", "liveRouteLegKind" }

function Target.Text(value, fallback)
    if type(value) ~= "string" then return fallback end
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

local function PositiveID(value)
    return Finite(value) and value > 0 and value % 1 == 0
end

function Target.Capture(target, fallback)
    if type(target) ~= "table" or type(target.key) ~= "string" or target.key == "" then
        return nil, "invalid_target"
    end
    local result = { key = target.key, name = Target.Text(target.title, fallback) }
    local pos = target.position
    if type(pos) == "table" and PositiveID(pos.mapID)
        and Finite(pos.x) and pos.x >= 0 and pos.x <= 1 and Finite(pos.y) and pos.y >= 0 and pos.y <= 1 then
        result.mapID, result.x, result.y = pos.mapID, pos.x, pos.y
    end
    if type(target.iconTexture) == "string" or Finite(target.iconTexture) then result.iconTexture = target.iconTexture end
    if target.iconType == "TEXTURE" or target.iconType == "ATLAS" then result.iconType = target.iconType end
    for _, key in ipairs({ "r", "g", "b" }) do
        if Finite(target[key]) and target[key] >= 0 and target[key] <= 1 then result[key] = target[key] end
    end
    if type(target.requestRecolor) == "boolean" then result.requestRecolor = target.requestRecolor end
    for _, key in ipairs(TEXT_FIELDS) do result[key] = Target.Text(target[key]) end
    for _, key in ipairs({ "semanticQuestID", "iconHintQuestID" }) do
        if PositiveID(target[key]) then result[key] = target[key] end
    end
    if type(target.aprQuestIDs) == "table" then
        result.aprQuestIDs = {}
        for _, id in ipairs(target.aprQuestIDs) do
            if PositiveID(id) then result.aprQuestIDs[#result.aprQuestIDs + 1] = id end
        end
    end
    return result
end

function Target.Copy(value)
    local result = {}
    for key, item in pairs(value) do result[key] = type(item) == "table" and Target.Copy(item) or item end
    return result
end

function Target.Same(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do if not Target.Same(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

namespace.NavigationV2WaypointTarget = Target
return Target
