-- Route hashing helpers (deterministic FNV-1a) used to fingerprint route definitions
local FNV_OFFSET = 2166136261
local FNV_PRIME = 16777619

local function HashByte(hash, byte)
    hash = bit.bxor(hash, byte)
    return bit.band(hash * FNV_PRIME, 0xFFFFFFFF)
end

local function HashValue(hash, value)
    local valueType = type(value)

    -- Tables are walked in sorted key order so the hash stays stable across runs
    if valueType == "table" then
        local keys = {}
        for key in pairs(value) do
            if key ~= "_index" then
                table.insert(keys, key)
            end
        end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

        hash = HashByte(hash, 123) -- delimiter
        for _, key in ipairs(keys) do
            hash = HashValue(hash, key)
            hash = HashValue(hash, value[key])
        end
        return HashByte(hash, 125) -- delimiter
    end

    -- Strings, numbers and booleans are stringified; other types are ignored on purpose
    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        local text = tostring(value)
        for i = 1, #text do
            hash = HashByte(hash, text:byte(i))
        end
        return HashByte(hash, 0)
    end

    return HashByte(hash, 0)
end

-- Build a stable signature for a route to spot changes even when step counts stay identical
function APR:GetRouteSignature(routeFileName)
    local steps = APR.RouteQuestStepList[routeFileName]
    if not steps then
        return nil
    end

    local hash = FNV_OFFSET
    for _, step in ipairs(steps) do
        hash = HashValue(hash, step)
    end

    return string.format("%08x", hash)
end
