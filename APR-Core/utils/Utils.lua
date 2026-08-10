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

    if C_StringUtil and C_StringUtil.trim then
        return C_StringUtil.trim(text)
    end

    if C_StringUtil and C_StringUtil.Trim then
        return C_StringUtil.Trim(text)
    end

    return (tostring(text):match("^%s*(.-)%s*$"))
end

--- Wrap a text by words using a max character count per line.
--- @param text string|number|nil
--- @param maxCharsPerLine number|nil
--- @return string
function APR:WrapTextByWords(text, maxCharsPerLine)
    if text == nil then
        return ""
    end

    local limit = tonumber(maxCharsPerLine)
    local asText = tostring(text)
    if not limit or limit < 1 or #asText <= limit then
        return asText
    end

    local wrappedLines = {}
    for sourceLine in asText:gmatch("[^\n]+") do
        local line = sourceLine
        while #line > limit do
            local breakAt = nil
            for i = limit, 1, -1 do
                if line:sub(i, i) == " " then
                    breakAt = i
                    break
                end
            end

            if not breakAt then
                breakAt = limit
            end

            local head = line:sub(1, breakAt):gsub("%s+$", "")
            if head ~= "" then
                tinsert(wrappedLines, head)
            end

            line = line:sub(breakAt + 1):gsub("^%s+", "")
        end

        if line ~= "" then
            tinsert(wrappedLines, line)
        end
    end

    if #wrappedLines == 0 then
        return asText
    end

    return table.concat(wrappedLines, "\n")
end

function APR:NormalizeBoolean(value)
    if value == nil then
        return nil
    end

    if type(value) == "boolean" then
        return value
    end

    if type(value) == "number" then
        return value ~= 0
    end

    if type(value) == "string" then
        local normalized = string.lower(value)
        if normalized == "true" or normalized == "1" or normalized == "yes" then
            return true
        end
        if normalized == "false" or normalized == "0" or normalized == "no" then
            return false
        end
    end

    return nil
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

function APR:EscapeLuaPattern(text)
    if text == nil then
        return ""
    end

    if C_StringUtil and C_StringUtil.EscapeLuaPatterns then
        return C_StringUtil.EscapeLuaPatterns(text)
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

local reportedInvalidUIAssets = {}
local knownUIAssetCache = {}

--- Check a texture, font or other UI file without breaking clients before 12.0.7.
--- On clients without C_UIFileAsset, the asset is trusted and the caller keeps its legacy behavior.
---@param asset number|string|nil
---@return boolean isKnown
---@return boolean validationAvailable
function APR:IsUIFileAssetKnown(asset)
    if asset == nil or asset == "" then
        return false, C_UIFileAsset ~= nil and type(C_UIFileAsset.IsKnownFile) == "function"
    end

    if not C_UIFileAsset or type(C_UIFileAsset.IsKnownFile) ~= "function" then
        return true, false
    end

    if knownUIAssetCache[asset] ~= nil then
        return knownUIAssetCache[asset], true
    end

    local ok, isKnown = pcall(C_UIFileAsset.IsKnownFile, asset)
    knownUIAssetCache[asset] = ok and isKnown == true
    return knownUIAssetCache[asset], true
end

--- Validate a UI file and optionally fall back to another one.
--- Invalid assets are reported once so a bad font or route image has an actionable failure mode.
---@param asset number|string|nil
---@param fallback number|string|nil
---@param context string|nil
---@return number|string|nil
function APR:ResolveUIFileAsset(asset, fallback, context)
    local isKnown, validationAvailable = self:IsUIFileAssetKnown(asset)
    if isKnown or not validationAvailable then
        return asset
    end

    local diagnosticKey = tostring(context or "UI") .. ":" .. tostring(asset)
    if not reportedInvalidUIAssets[diagnosticKey] then
        reportedInvalidUIAssets[diagnosticKey] = true
        local message = string.format("Unknown UI asset (%s): %s", context or "UI", tostring(asset))
        if self.PrintError then
            self:PrintError(message)
        else
            self:PrintInfo(message)
        end
    end

    if fallback ~= nil then
        local fallbackIsKnown, fallbackValidationAvailable = self:IsUIFileAssetKnown(fallback)
        if fallbackIsKnown or not fallbackValidationAvailable then
            return fallback
        end
    end

    return nil
end

--- Validate the small set of files required for APR's main UI.
--- Route preview images and configured fonts are validated lazily when used.
function APR:ValidateBundledUIAssets()
    for context, asset in pairs({
        ["addon logo"] = "Interface\\AddOns\\APR\\APR-Core\\assets\\APR_logo.blp",
        ["change log header"] = "Interface\\AddOns\\APR\\APR-Core\\assets\\header.blp",
        ["map icon"] = "Interface\\AddOns\\APR\\APR-Core\\assets\\Icon.tga",
        ["navigation arrow"] = "Interface\\AddOns\\APR\\APR-Core\\assets\\Arrow.blp",
    }) do
        self:ResolveUIFileAsset(asset, nil, context)
    end
end

local function GetOwnedItemLocation(itemID)
    if not itemID or not ItemLocation or not C_Item or not C_Item.GetItemID then
        return nil
    end

    local function matches(itemLocation)
        return itemLocation and itemLocation:IsValid() and C_Item.DoesItemExist(itemLocation) and
            C_Item.GetItemID(itemLocation) == itemID
    end

    local firstEquippedSlot = _G.INVSLOT_FIRST_EQUIPPED or 1
    local lastEquippedSlot = _G.INVSLOT_LAST_EQUIPPED or 19
    for slot = firstEquippedSlot, lastEquippedSlot do
        local itemLocation = ItemLocation:CreateFromEquipmentSlot(slot)
        if matches(itemLocation) then
            return itemLocation
        end
    end

    if not C_Container or not C_Container.GetContainerNumSlots then
        return nil
    end

    local firstBag = Enum and Enum.BagIndex and Enum.BagIndex.Backpack or 0
    local lastBag = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag or 4
    for bag = firstBag, lastBag do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
            if matches(itemLocation) then
                return itemLocation
            end
        end
    end

    return nil
end

--- Return the 12.1 item-targeting context for an owned route item, when a spell is targeting an item.
--- Older clients simply return nil and retain the pre-12.1 tooltip.
---@param itemID number
---@return table|nil
function APR:GetTargetSpellItemContext(itemID)
    if not C_Spell or type(C_Spell.TargetSpellChecksItemCondition) ~= "function" or
        not C_Item or type(C_Item.DoesItemMatchSpellItemCondition) ~= "function" or
        not C_Spell.TargetSpellChecksItemCondition() then
        return nil
    end

    local itemLocation = GetOwnedItemLocation(tonumber(itemID))
    if not itemLocation then
        return { matches = false }
    end

    local matches = C_Item.DoesItemMatchSpellItemCondition(itemLocation)
    local cursorType, _, _, targetSpellID = GetCursorInfo()
    local description
    if cursorType == "spell" and targetSpellID and type(C_Spell.GetSpellDescriptionForItemLocation) == "function" then
        description = C_Spell.GetSpellDescriptionForItemLocation(targetSpellID, itemLocation)
    end

    return {
        description = description,
        itemLocation = itemLocation,
        matches = matches == true,
        spellID = targetSpellID,
    }
end

--- Evaluate a route action using non-secret booleans whenever cooldown restrictions are active.
---@param actionType string
---@param actionID number|string
---@param ignoreCooldown boolean|nil
---@return boolean usable
---@return string|nil reason
function APR:GetRouteActionUsability(actionType, actionID, ignoreCooldown)
    actionID = tonumber(actionID)
    if not actionID then
        return false, "invalid"
    end

    if actionType == "spell" then
        if not C_Spell or not C_Spell.GetSpellInfo or not C_Spell.GetSpellInfo(actionID) then
            return false, "unknown"
        end
        if self.IsSpellKnown and not self:IsSpellKnown(actionID) then
            return false, "unknown"
        end

        if C_Spell.IsSpellUsable then
            local isUsable = C_Spell.IsSpellUsable(actionID)
            if isUsable == false then
                return false, "unusable"
            end
        end

        if ignoreCooldown then
            return true
        end

        local cooldownInfo = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(actionID) or nil
        if not cooldownInfo then
            return true
        end

        -- isActive was added in 12.0.1 specifically as a never-secret decision value.
        if cooldownInfo.isActive ~= nil then
            return cooldownInfo.isActive == false, cooldownInfo.isActive and "cooldown" or nil
        end

        -- 12.0.0 has DurationObject support but predates the never-secret isActive field.
        if C_Spell.GetSpellCooldownDuration then
            local cooldownDuration = C_Spell.GetSpellCooldownDuration(actionID)
            if cooldownDuration and cooldownDuration.IsZero then
                local isZero = cooldownDuration:IsZero()
                if isZero then
                    return true
                end
                return false, "cooldown"
            end
        end

        -- Legacy fallback: compare values only when the client says they are accessible.
        local duration = cooldownInfo.duration
        if self.CanAccessValue and not self:CanAccessValue(duration) then
            return false, "restricted"
        end
        return type(duration) ~= "number" or duration <= 0, type(duration) == "number" and duration > 0 and
            "cooldown" or nil
    end

    if actionType == "item" then
        local hasToy = PlayerHasToy and PlayerHasToy(actionID) or false
        if hasToy and C_ToyBox and C_ToyBox.IsToyUsable and C_ToyBox.IsToyUsable(actionID) == false then
            hasToy = false
        end

        local itemCount = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(actionID) or 0
        if not hasToy and itemCount <= 0 then
            return false, "missing"
        end

        if C_Item and C_Item.IsUsableItem then
            local isUsable = C_Item.IsUsableItem(actionID)
            if isUsable == false then
                return false, "unusable"
            end
        end

        if ignoreCooldown then
            return true
        end

        local startTime, duration, enabled
        if C_Item and C_Item.GetItemCooldown then
            startTime, duration, enabled = C_Item.GetItemCooldown(actionID)
        elseif C_Container and C_Container.GetItemCooldown then
            startTime, duration, enabled = C_Container.GetItemCooldown(actionID)
        end

        local cooldownEnabled = enabled == true or enabled == 1
        local isActive = cooldownEnabled and type(startTime) == "number" and startTime > 0 and
            type(duration) == "number" and duration > 0
        return not isActive, isActive and "cooldown" or nil
    end

    return false, "invalid"
end

function APR:GetRouteActionStatusText(reason)
    local messages = {
        cooldown = _G.SPELL_FAILED_NOT_READY,
        invalid = _G.SPELL_FAILED_BAD_TARGETS,
        missing = _G.ERR_ITEM_NOT_FOUND or _G.SPELL_FAILED_ITEM_NOT_FOUND,
        restricted = _G.SPELL_FAILED_NOT_READY,
        unknown = _G.SPELL_FAILED_NOT_KNOWN,
        unusable = _G.SPELL_FAILED_NOT_HERE or _G.SPELL_FAILED_NOT_READY,
    }
    return messages[reason]
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
            DEFAULT_CHAT_FRAME:AddMessage(errorText .. " - ", data)
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

function APR:ResolveStepText(rawValue)
    if rawValue == nil then
        return nil, nil
    end

    local key = tostring(rawValue)
    local aprRCData = rawget(_G, "AprRCData")
    local message = rawget(L, key) or
        (aprRCData and aprRCData.ExtraLineTexts and rawget(aprRCData.ExtraLineTexts, key)) or
        key

    if not message or message == "" then
        return nil, nil
    end

    local colorHex, formattedMessage = self:ExtractColorAndText(message)
    return formattedMessage, colorHex
end

function APR:ResolveStepTextList(rawValue)
    local resolved = {}

    local function addResolvedText(value)
        local text, color = self:ResolveStepText(value)
        if text and text ~= "" then
            table.insert(resolved, {
                text = text,
                color = color,
            })
        end
    end

    if type(rawValue) == "table" then
        for _, value in ipairs(rawValue) do
            addResolvedText(value)
        end
    else
        addResolvedText(rawValue)
    end

    return resolved
end

function APR:titleCase(str)
    return (str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

--- Returns a stable string key that uniquely identifies a Note step's content.
--- Used to track which Note-only steps the player has already seen, even across resets.
---@param step table The step table to derive the key from
---@return string|nil key A stable string key, or nil if the step has no Note
function APR:GetNoteStepKey(step)
    if not step or not step.Note then return nil end
    if type(step.Note) == "table" then
        local parts = {}
        for i, v in ipairs(step.Note) do
            parts[i] = tostring(v)
        end
        return table.concat(parts, "\0")
    end
    return tostring(step.Note)
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
