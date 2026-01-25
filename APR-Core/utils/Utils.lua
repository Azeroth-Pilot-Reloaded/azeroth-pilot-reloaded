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

function APR:Debug(msg, data, force)
    if not APR.settings.profile.debug and not force then
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
    if APR.settings.profile.showEvent then
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
function APR:tableToString(table, skipKey)
    local result = "{"
    for k, v in pairs(table) do
        if not skipKey then
            -- Check the key type (ignore any numerical keys - assume its an array)
            if type(k) == "string" then
                result = result .. "[\"" .. k .. "\"]" .. "="
            end
        end
        -- Check the value type
        if type(v) == "table" then
            result = result .. APR:tableToString(v)
        elseif type(v) == "boolean" then
            result = result .. tostring(v)
        else
            result = result .. "\"" .. v .. "\""
        end
        result = result .. ","
    end
    -- Remove leading commas from the result
    if result ~= "" then
        result = result:sub(1, result:len() - 1)
    end
    return result .. "}"
end

function APR:HexaToRGBA(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 and #hex ~= 8 then
        return nil
    end

    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local a = 1

    if #hex == 8 then
        a = tonumber(hex:sub(7, 8), 16) / 255
    end

    return { r, g, b, a }
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
