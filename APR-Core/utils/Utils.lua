-- Shared table/string primitives, diagnostics and small event/message transport helpers.
-- Gameplay queries, route semantics and frame ownership belong to the corresponding domain modules.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Accept keyed tables as well as arrays; callers use both route shapes.
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

    if #normalized ~= 8 or not normalized:match("^%x+$") then
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

function APR:FormatMilliseconds(value, precise)
    return string.format(precise and "%.3f" or "%.2f", value) .. " " .. MILLISECONDS_ABBR
end

function APR:FormatSeconds(value)
    -- FontStrings resolve Blizzard's |4 singular/plural markers on the game client.
    return string.format(SECONDS_ABBR, math.floor(value + 0.5))
end

function APR:TrimString(text)
    if text == nil then
        return ""
    end

    if C_StringUtil and C_StringUtil.trim then
        return C_StringUtil.trim(text)
    end

    if C_StringUtil and C_StringUtil.Trim then
        return C_StringUtil.Trim(text)
    end

    return (tostring(text):match("^%s*(.-)%s*$"))
end

function APR:RemoveContiguousSpaces(text)
    if text == nil then
        return ""
    end

    if C_StringUtil and C_StringUtil.RemoveContiguousSpaces then
        return C_StringUtil.RemoveContiguousSpaces(text, 1)
    end

    return tostring(text):gsub("%s+", " ")
end

-- Objective text is literal, including punctuation that has meaning in Lua patterns.
function APR:ContainsText(haystack, needle)
    if haystack == nil or needle == nil then
        return false
    end

    return string.find(tostring(haystack), tostring(needle), 1, true) ~= nil
end

function APR:Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

-- Feature availability varies independently of the client's interface number.
-- The protected call is needed on clients without C_EventUtils, where unknown events throw.
function APR:RegisterSupportedEvent(frame, event)
    if C_EventUtils and C_EventUtils.IsEventValid then
        if not C_EventUtils.IsEventValid(event) then return false end
        frame:RegisterEvent(event)
        return true
    end
    return pcall(frame.RegisterEvent, frame, event)
end

function APR:StripHyperlinks(text)
    if text == nil then
        return ""
    end

    if C_StringUtil and C_StringUtil.StripHyperlinks then
        return C_StringUtil.StripHyperlinks(text)
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
            APR:Debug(msg, value, force)
        end
    elseif data then
        print(APR:WrapTextWithAppearanceColor(tostring(msg), "general", "accent") .. " - ",
            APR:WrapTextWithAppearanceColor(tostring(data), "general", "success"))
    else
        print(APR:WrapTextWithAppearanceColor(tostring(msg), "general", "accent"))
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
        local errorText = APR:WrapTextWithAppearanceColor(string.format(L["ERROR_MESSAGE"], errorMessage),
            "general", "error")
        if data then
            DEFAULT_CHAT_FRAME:AddMessage(errorText .. " - " .. tostring(data))
        else
            DEFAULT_CHAT_FRAME:AddMessage(errorText)
        end
        local color = APR:GetTextColor("general", "error")
        UIErrorsFrame:AddMessage(errorMessage, color[1], color[2], color[3], color[4], 5)
    end
end

--- Display zone detection debug info in chat
--- @param msg string
function APR:PrintZoneDebug(msg)
    if not self:ShouldLogDebug("zoneDetectionDebug") then
        return
    end
    if msg and type(msg) == "string" then
        DEFAULT_CHAT_FRAME:AddMessage(APR:WrapTextWithAppearanceColor("[ZoneDebug] " .. msg, "general", "warning"))
    end
end

--- Display info in chat
--- @param msg string
function APR:PrintInfo(msg, data)
    if not data then
        if msg and type(msg) == "string" then
            DEFAULT_CHAT_FRAME:AddMessage(APR:WrapTextWithAppearanceColor("APR: " .. msg, "general", "accent"))
        end
    else
        if type(data) == "table" then
            for key, value in pairs(data) do
                print(msg, " - ", key)
                APR:PrintInfo(msg, value)
            end
        elseif data then
            print(APR:WrapTextWithAppearanceColor(tostring(msg), "general", "accent") .. " - ",
                APR:WrapTextWithAppearanceColor(tostring(data), "general", "success"))
        else
            print(APR:WrapTextWithAppearanceColor(tostring(msg), "general", "accent"))
        end
    end
end

-- Diagnostic output only: cycles/deep branches become markers, so this is not an export format.
function APR:TableToDebugString(value, skipKey, depth, visited)
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
                keyPart = "[" .. string.format("%q", k) .. "]="
            elseif type(k) == "number" then
                keyPart = "[" .. k .. "]="
            end
        end

        local valuePart
        if type(v) == "table" then
            valuePart = self:TableToDebugString(v, skipKey, depth + 1, visited)
        elseif type(v) == "boolean" then
            valuePart = tostring(v)
        elseif type(v) == "number" then
            valuePart = tostring(v)
        else
            valuePart = string.format("%q", tostring(v))
        end
        table.insert(parts, keyPart .. valuePart)
    end

    visited[value] = nil

    return "{" .. table.concat(parts, ",") .. "}"
end

-- Diagnostic Lua retains keys and stable ordering. Work/depth are bounded for unexpected runtime data.
function APR:FormatDebugTable(value, entryLimit)
    -- Larger bounded captures may opt into a higher export budget without changing status defaults.
    entryLimit = self:Clamp(tonumber(entryLimit) or 10000, 1, 50000)
    local visited, entries = {}, 0
    local function available(item)
        return not self.CanAccessValue or self:CanAccessValue(item)
    end
    local function format(item, depth)
        if not available(item) then return '"<unavailable>"' end
        local kind = type(item)
        if kind == "string" then return string.format("%q", item) end
        if kind == "number" then
            return item == item and item ~= math.huge and item ~= -math.huge and tostring(item) or '"<non-finite>"'
        end
        if kind == "boolean" or kind == "nil" then return tostring(item) end
        if kind ~= "table" then return string.format("%q", "<" .. kind .. ">") end
        if self.CanAccessTable and not self:CanAccessTable(item) then return '"<unavailable>"' end
        if visited[item] then return '"<circular>"' end
        if depth >= 10 then return '"<max-depth>"' end
        if entries >= entryLimit then return '"<entry-limit>"' end
        visited[item] = true
        local keys, truncated, scanned = {}, false, 0
        for key in pairs(item) do
            if entries + scanned >= entryLimit then truncated = true; break end
            scanned = scanned + 1
            if available(key) and (type(key) == "number" or type(key) == "string") then
                keys[#keys + 1] = key
            end
        end
        entries = entries + scanned
        table.sort(keys, function(a, b)
            if type(a) == type(b) then return a < b end
            return type(a) == "number"
        end)
        local parts, indent = {}, string.rep("    ", depth + 1)
        for _, key in ipairs(keys) do
            -- Bracket every string key, including Lua keywords, so a complete plain-data report is valid Lua.
            local label = "[" .. (type(key) == "number" and tostring(key) or string.format("%q", key)) .. "]"
            parts[#parts + 1] = indent .. label .. " = " .. format(item[key], depth + 1) .. ","
        end
        if truncated then parts[#parts + 1] = indent .. "-- <entry-limit>" end
        visited[item] = nil
        if #parts == 0 then return "{}" end
        return "{\n" .. table.concat(parts, "\n") .. "\n" .. string.rep("    ", depth) .. "}"
    end
    return format(value, 0)
end

-- Copy route/profile data without sharing nested tables with SavedVariables.
-- Preserve cycles and repeated references, without metatables; use only for plain data.
function APR:DeepCopyTable(value, copies)
    if type(value) ~= "table" then return value end
    copies = copies or {}
    if copies[value] then return copies[value] end

    local copy = {}
    copies[value] = copy
    for key, child in pairs(value) do
        copy[self:DeepCopyTable(key, copies)] = self:DeepCopyTable(child, copies)
    end
    return copy
end

-- Fold complete UTF-8 characters, never individual bytes of accented letters.
local searchAccents = {
    ["à"] = "a",
    ["â"] = "a",
    ["ä"] = "a",
    ["á"] = "a",
    ["ã"] = "a",
    ["å"] = "a",
    ["À"] = "a",
    ["Â"] = "a",
    ["Ä"] = "a",
    ["Á"] = "a",
    ["Ã"] = "a",
    ["Å"] = "a",
    ["é"] = "e",
    ["è"] = "e",
    ["ê"] = "e",
    ["ë"] = "e",
    ["É"] = "e",
    ["È"] = "e",
    ["Ê"] = "e",
    ["Ë"] = "e",
    ["î"] = "i",
    ["ï"] = "i",
    ["í"] = "i",
    ["ì"] = "i",
    ["Î"] = "i",
    ["Ï"] = "i",
    ["Í"] = "i",
    ["Ì"] = "i",
    ["ô"] = "o",
    ["ö"] = "o",
    ["ó"] = "o",
    ["ò"] = "o",
    ["õ"] = "o",
    ["Ô"] = "o",
    ["Ö"] = "o",
    ["Ó"] = "o",
    ["Ò"] = "o",
    ["Õ"] = "o",
    ["ù"] = "u",
    ["û"] = "u",
    ["ü"] = "u",
    ["ú"] = "u",
    ["Ù"] = "u",
    ["Û"] = "u",
    ["Ü"] = "u",
    ["Ú"] = "u",
    ["ç"] = "c",
    ["Ç"] = "c",
    ["ñ"] = "n",
    ["Ñ"] = "n",
    ["ÿ"] = "y",
    ["ý"] = "y",
    ["Ÿ"] = "y",
    ["Ý"] = "y",
    ["œ"] = "oe",
    ["Œ"] = "oe",
    ["æ"] = "ae",
    ["Æ"] = "ae",
}

function APR:NormalizeSearchText(value)
    return ((value or ""):gsub("[%z\1-\127\194-\244][\128-\191]*", function(character)
        -- Combining diacritics (U+0300..U+036F), for decomposed input.
        if character:match("^\204[\128-\191]$") or character:match("^\205[\128-\175]$") then
            return ""
        end
        return searchAccents[character] or character
    end):lower())
end

--- Compare two ordered string lists.
---@param a table|nil
---@param b table|nil
---@return boolean
function APR:AreOrderedStringListsEqual(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    if #a ~= #b then
        return false
    end

    for i = 1, #a do
        if a[i] ~= b[i] then
            return false
        end
    end

    return true
end


-- Preserve APR's existing group protocol; keep transport framing out of window code.
function APR:SendAddonMessageSplit(prefix, fullMessage, channel, target)
    local payloadLength = 180 -- Leave room for the fragment header within WoW's 255-byte limit.
    local msgID = tostring(math.random(10000, 99999)) .. "-" .. GetTime() -- Unique message ID with timestamp
    local total = math.ceil(#fullMessage / payloadLength)
    APR:Debug("Splitting message", { msgID = msgID, totalParts = total })

    for i = 1, total do
        local startIdx = (i - 1) * payloadLength + 1
        local endIdx = math.min(i * payloadLength, #fullMessage)
        local part = fullMessage:sub(startIdx, endIdx)

        -- Format: <msgID>|<index>|<total>|<data>
        local fragment = msgID .. "|" .. i .. "|" .. total .. "|" .. part
        C_ChatInfo.SendAddonMessage(prefix, fragment, channel, target)
    end
end
