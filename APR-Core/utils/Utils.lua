local L = LibStub("AceLocale-3.0"):GetLocale("APR")

--[[
    Technical-only helpers.
    Gameplay and feature-specific utilities now live in dedicated files to keep this module focused on reusable primitives.
]]

--[[
    Function: APR:Contains
    Description:
      Determines whether a specified value exists within a given list.

    Parameters:
      list (table) - A table representing the list to be searched.
      x (any) - The value to locate in the list.

    Returns:
      boolean - True if the value x is found in the list, otherwise false.
]]
function APR:Contains(list, x)
    if list then
        for _, v in pairs(list) do
            if v == x then return true end
        end
    end
    return false
end

function APR:ContainsAny(list, candidates)
    if not list or not candidates then
        return false
    end
    for _, candidate in ipairs(candidates) do
        if self:Contains(list, candidate) then
            return true
        end
    end
    return false
end

function APR:IsTableEmpty(table)
    return table and next(table) == nil or false
end

local function NormalizeHexColorCode(hex)
    if not hex then
        return nil
    end

    local normalized = tostring(hex)
    normalized = normalized:gsub("^|c", ""):gsub("^|C", "")
    normalized = normalized:gsub("^#", "")

    if #normalized == 6 then
        normalized = "ff" .. normalized
    end

    if #normalized ~= 8 then
        return nil
    end

    return normalized
end

local HEXA_RGBA_CACHE = {}

function APR:WrapTextInColorCode(text, hex)
    if text == nil then
        return ""
    end

    local normalized = NormalizeHexColorCode(hex)
    local asText = tostring(text)

    if not normalized then
        return asText
    end

    if C_ColorUtil and C_ColorUtil.WrapTextInColorCode then
        return C_ColorUtil.WrapTextInColorCode(asText, normalized)
    end

    return "|c" .. normalized .. asText .. "|r"
end

function APR:TrimString(text)
    if text == nil then
        return ""
    end

    if StringUtil and StringUtil.trim then
        return StringUtil.trim(text)
    end

    if StringUtil and StringUtil.Trim then
        return StringUtil.Trim(text)
    end

    return (tostring(text):match("^%s*(.-)%s*$"))
end

function APR:RemoveContiguousSpaces(text)
    if text == nil then
        return ""
    end

    if StringUtil and StringUtil.RemoveContiguousSpaces then
        return StringUtil.RemoveContiguousSpaces(text)
    end

    return tostring(text):gsub("%s+", " ")
end

function APR:EscapeLuaPattern(text)
    if text == nil then
        return ""
    end

    if StringUtil and StringUtil.EscapeLuaPatterns then
        return StringUtil.EscapeLuaPatterns(text)
    end

    return (tostring(text):gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1"))
end

function APR:ContainsText(haystack, needle)
    if haystack == nil or needle == nil then
        return false
    end

    local haystackText = tostring(haystack)
    local needleText = tostring(needle)
    local escapedNeedle = APR:EscapeLuaPattern(needleText)
    return string.find(haystackText, escapedNeedle) ~= nil
end

function APR:StripHyperlinks(text)
    if text == nil then
        return ""
    end

    if StringUtil and StringUtil.StripHyperlinks then
        return StringUtil.StripHyperlinks(text)
    end

    return tostring(text)
end

function APR:GetSettingsProfile()
    return self.settings and self.settings.profile or nil
end

function APR:ShouldLogDebug(settingKey, force)
    local profile = self:GetSettingsProfile()
    if not profile then
        return false
    end

    if force then
        return true
    end

    if settingKey then
        return profile[settingKey] and true or false
    end

    return profile.debug and true or false
end

--- Validate a map ID is non-nil and non-zero
--- @param mapID number|nil Map ID to validate
--- @return boolean True if mapID is valid (non-nil and ~= 0)
function APR:IsValidMapID(mapID)
    return mapID ~= nil and mapID ~= 0
end

function APR:Debug(msg, data, force)
    if not self:ShouldLogDebug(nil, force) then
        return
    end
    if type(data) == "table" then
        for key, value in pairs(data) do
            print(msg, " - ", key)
            APR:Debug(msg, value)
        end
    elseif data then
        print(APR:WrapTextInColorCode(tostring(msg), "00bfff") .. " - ",
            APR:WrapTextInColorCode(tostring(data), "00ff00"))
    else
        print(APR:WrapTextInColorCode(tostring(msg), "00bfff"))
    end
end

function APR:DebugEvent(msg, data)
    if self:ShouldLogDebug("showEvent") then
        APR:Debug(msg, data, true)
    end
end

--- Display error in chat
--- @param errorMessage string
--- @param data any
function APR:PrintError(errorMessage, data)
    if (errorMessage and type(errorMessage) == "string") then
        local errorText = APR:WrapTextInColorCode(L["ERROR"] .. ": " .. errorMessage, "ff0000")
        if data then
            DEFAULT_CHAT_FRAME:AddMessage(errorText .. " - ", data)
        else
            DEFAULT_CHAT_FRAME:AddMessage(errorText)
        end
        UIErrorsFrame:AddMessage(errorMessage, 1, 0, 0, 1, 5)
    end
end

--- Display zone detection debug info in chat
--- @param msg string
function APR:PrintZoneDebug(msg)
    if not self:ShouldLogDebug("zoneDetectionDebug") then
        return
    end
    if msg and type(msg) == "string" then
        DEFAULT_CHAT_FRAME:AddMessage(APR:WrapTextInColorCode("[ZoneDebug] " .. msg, "ffff00"))
    end
end

--- Display info in chat
--- @param msg string
function APR:PrintInfo(msg, data)
    if not data then
        if msg and type(msg) == "string" then
            DEFAULT_CHAT_FRAME:AddMessage(APR:WrapTextInColorCode("APR: " .. msg, "00ecff"))
        end
    else
        if type(data) == "table" then
            for key, value in pairs(data) do
                print(msg, " - ", key)
                APR:PrintInfo(msg, value)
            end
        elseif data then
            print(APR:WrapTextInColorCode(tostring(msg), "00ecff") .. " - ",
                APR:WrapTextInColorCode(tostring(data), "00ff00"))
        else
            print(APR:WrapTextInColorCode(tostring(msg), "00ecff"))
        end
    end
end

-- Convert a lua table into a lua syntactically correct string
function APR:tableToString(value, skipKey, depth, visited)
    if type(value) ~= "table" then
        return tostring(value)
    end

    depth = depth or 0
    visited = visited or {}
    if visited[value] then
        return "\"<circular>\""
    end
    if depth > 10 then
        return "\"<max-depth>\""
    end

    visited[value] = true

    local parts = {}
    for k, v in pairs(value) do
        local keyPart = ""
        if not skipKey then
            if type(k) == "string" then
                keyPart = "[\"" .. k .. "\"]="
            elseif type(k) == "number" then
                keyPart = "[" .. k .. "]="
            end
        end

        local valuePart
        if type(v) == "table" then
            valuePart = self:tableToString(v, skipKey, depth + 1, visited)
        elseif type(v) == "boolean" then
            valuePart = tostring(v)
        elseif type(v) == "number" then
            valuePart = tostring(v)
        else
            valuePart = "\"" .. tostring(v) .. "\""
        end
        table.insert(parts, keyPart .. valuePart)
    end

    visited[value] = nil

    return "{" .. table.concat(parts, ",") .. "}"
end

function APR:HexaToRGBA(hex)
    if hex == nil then
        return nil
    end

    local normalized = tostring(hex):gsub("#", "")
    if #normalized ~= 6 and #normalized ~= 8 then
        return nil
    end

    local cached = HEXA_RGBA_CACHE[normalized]
    if cached then
        return cached
    end

    local r = tonumber(normalized:sub(1, 2), 16)
    local g = tonumber(normalized:sub(3, 4), 16)
    local b = tonumber(normalized:sub(5, 6), 16)
    local a = 255

    if #normalized == 8 then
        a = tonumber(normalized:sub(7, 8), 16)
    end

    if not r or not g or not b or not a then
        return nil
    end

    local rgba = { r / 255, g / 255, b / 255, a / 255 }
    HEXA_RGBA_CACHE[normalized] = rgba
    return rgba
end

function APR:ExtractColorAndText(text)
    local colorHex, message = string.match(text, "^%[COLOR:#?(%x+)%]%s*(.+)")
    if colorHex then
        return colorHex, message
    else
        return nil, text
    end
end

function APR:titleCase(str)
    return (str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

---Copies a table from source to a new table
---@param source table The source table to copy
---@return table A shallow copy of the source table
function APR:copyTable(source)
    if type(source) ~= "table" then
        return source
    end

    local result = {}
    for key, value in pairs(source) do
        result[key] = APR:copyTable(value)
    end
    return result
end
