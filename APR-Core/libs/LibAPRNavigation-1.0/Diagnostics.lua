-- Format structured access failures without depending on a host UI or locale library.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("diagnostics", 1) then return end
local Instance = Lib.Instance

function Instance:GetBlockedRouteText(blockers)
    local function localText(key) return self:GetText(key) end
    local function describe(node)
        if node.children then
            local values = {}
            for _, child in ipairs(node.children) do values[#values + 1] = describe(child) end
            return "(" .. table.concat(values, node.key == "any" and localText("NAVIGATION_OR") or localText("NAVIGATION_AND")) .. ")"
        end
        local key, value = node.key, node.value
        local name
        if key == "quest" or key == "questAccount" or key == "questActive" then
            name = self.env.getQuestName and self.env.getQuestName(value)
        elseif key == "achievement" then
            name = self.env.getAchievementName and self.env.getAchievementName(value)
        elseif key == "toyID" then name = self.env.getItemName(value)
        elseif key == "auraSpellID" then name = self.env.getSpellName(value) end
        if type(value) == "boolean" then value = self:GetText(value and "NAVIGATION_YES" or "NAVIGATION_NO") end
        if type(value) == "table" then
            local ids = {}
            for _, id in ipairs(value) do ids[#ids + 1] = tostring(id) end
            value = #ids > 0 and table.concat(ids, ", ") or value.minLevel or value.artID or "?"
        end
        local label = localText("NAVIGATION_REQUIRES_" .. key)
        local text = string.format(label, name and (name .. " [" .. tostring(value) .. "]") or tostring(value))
        if node.negated then text = localText("NAVIGATION_NEGATED") .. text end
        if node.unknown then text = localText("NAVIGATION_UNKNOWN_REQUIREMENT") .. text end
        return text
    end
    local lines, seen = {}, {}
    for _, edge in ipairs(blockers or {}) do
        local reasons = {}
        if edge.blockedRequirements then
            local current = self.env.getCharacter and self.env.getCharacter() or {}
            local character = {}
            for key, value in pairs(current) do if key ~= "mapID" then character[key] = value end end
            character.mapID = edge.from and edge.from.uiMapID
            local failure = self:GetRequirementFailures(edge.blockedRequirements, character)
            if failure then reasons[#reasons + 1] = describe(failure) end
        end
        for _, option in ipairs(edge.blockedActions or {}) do
            local usable, reason = self:GetActionUsability(option.type, option.id)
            if not usable then
                local getter = option.type == "spell" and self.env.getSpellName or self.env.getItemName
                local name = getter and getter(option.id) or "?"
                local reasonKey = "NAVIGATION_ACTION_" .. (reason or "unavailable")
                local reasonText = localText(reasonKey)
                if not reasonText or reasonText == reasonKey then reasonText = localText("NAVIGATION_ACTION_unavailable") end
                reasons[#reasons + 1] = name .. " [" .. tostring(option.id) .. "]: " .. reasonText
            end
        end
        local line = (edge.instruction or localText("PATH_NOT_FOUND")) .. ": " .. table.concat(reasons, localText("NAVIGATION_AND"))
        if #reasons > 0 and not seen[line] then lines[#lines + 1], seen[line] = line, true end
    end
    if #lines == 0 then return localText("PATH_NOT_FOUND") .. "\n" .. localText("NAVIGATION_NO_KNOWN_PASSAGE") end
    return localText("PATH_NOT_FOUND") .. "\n" .. table.concat(lines, "\n")
end
