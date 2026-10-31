-- Format structured access failures without depending on a host UI or locale library.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("diagnostics", 5) then return end
local Instance = Lib.Instance

-- Append each line once, rather than copying every descendant's lines through
-- each ancestor. The destination belongs to this call, including reentrant hosts.
local function Describe(self, node, lines, depth, parentKey)
    -- Implicit conjunctions often wrap a single alternative. They carry no
    -- extra meaning and must not add another visual level.
    while node.children and #node.children == 1 do node = node.children[1] end
    depth = depth or 2
    if node.children then
        if parentKey and node.key ~= parentKey then depth = depth + 2 end
        for index, child in ipairs(node.children) do
            if index > 1 then
                local join = self:GetText(node.key == "any" and "NAVIGATION_OR" or "NAVIGATION_AND")
                lines[#lines + 1] = { kind = "operator", text = string.rep(" ", depth) .. join:match("^%s*(.-)%s*$") }
            end
            Describe(self, child, lines, depth, node.key)
        end
        return
    end
    local key, value = node.key, node.value
    local name, display
    if key == "quest" or key == "questAccount" or key == "questActive" then
        name = self.env.getQuestName and self.env.getQuestName(value)
    elseif key == "achievement" then
        name = self.env.getAchievementName and self.env.getAchievementName(value)
    elseif key == "toyID" then name = self.env.getItemName and self.env.getItemName(value)
    elseif key == "auraSpellID" or key == "spellKnown" or key == "spell" then name = self.env.getSpellName and self.env.getSpellName(value) end
    if (key == "currency" or key == "reputation" or key == "item" or key == "skill") and type(value) == "table" then
        local id = value.id or value.factionID
        local getter = key == "currency" and self.env.getCurrencyName
            or key == "reputation" and self.env.getReputationName
            or key == "item" and self.env.getItemName or key == "skill" and self.env.getSkillName
        name = getter and getter(id)
        display = name and (name .. " [" .. tostring(id) .. "]") or tostring(id)
        local minimum = value.amount or value.count or value.standing or value.minStanding
            or value.minCount or value.min or value.level or value.minNativeValue
        if minimum ~= nil then display = display .. " ≥ " .. tostring(minimum) end
        if value.minAmount ~= nil or value.minStandingAmount ~= nil then
            display = display .. " (≥ " .. tostring(value.minStandingAmount or value.minAmount) .. ")"
        end
        if value.maxNativeValue ~= nil then display = display .. " ≤ " .. tostring(value.maxNativeValue) end
    end
    if type(value) == "boolean" then value = self:GetText(value and "NAVIGATION_YES" or "NAVIGATION_NO") end
    if type(value) == "table" then
        local ids = {}
        for _, id in ipairs(value) do ids[#ids + 1] = tostring(id) end
        value = #ids > 0 and table.concat(ids, ", ") or value.minLevel or value.artID
            or (value.group and (value.group .. ": " .. tostring(value.phase))) or value.id or "?"
    end
    local label = self:GetText("NAVIGATION_REQUIRES_" .. key)
    local text = string.format(label, display or (name and (name .. " [" .. tostring(value) .. "]") or tostring(value)))
    if node.negated then text = self:GetText("NAVIGATION_NEGATED") .. text end
    if node.unknown then text = self:GetText("NAVIGATION_UNKNOWN_REQUIREMENT") .. text end
    lines[#lines + 1] = { kind = "requirement", text = string.rep(" ", depth) .. "- " .. text }
end

function Instance:GetBlockedRouteText(blockers)
    local lines, seen = { { kind = "status", text = self:GetText("PATH_NOT_FOUND") } }, {}
    for _, edge in ipairs(blockers or {}) do
        local reasons = {}
        if edge.blockedRequirements then
            local current = self.env.getCharacter and self.env.getCharacter() or {}
            local character = {}
            for key, value in pairs(current) do if key ~= "mapID" then character[key] = value end end
            character.mapID = edge.from and edge.from.uiMapID
            local failure = self:GetRequirementFailures(edge.blockedRequirements, character)
            if failure then
                local description = {}
                Describe(self, failure, description)
                reasons[#reasons + 1] = description
            end
        end
        for _, option in ipairs(edge.blockedActions or {}) do
            local usable, reason = self:GetActionUsability(option.type, option.id)
            if not usable then
                local getter = option.type == "spell" and self.env.getSpellName or self.env.getItemName
                local name = getter and getter(option.id) or "?"
                local reasonKey = "NAVIGATION_ACTION_" .. (reason or "unavailable")
                local reasonText = self:GetText(reasonKey)
                if not reasonText or reasonText == reasonKey then reasonText = self:GetText("NAVIGATION_ACTION_unavailable") end
                reasons[#reasons + 1] = { { kind = "requirement",
                    text = "  - " .. name .. " [" .. tostring(option.id) .. "]: " .. reasonText } }
            end
        end
        local passage = { { kind = "spacer", text = "" },
            { kind = "passage", text = edge.instruction or self:GetText("PATH_NOT_FOUND") } }
        for index, reason in ipairs(reasons) do
            if index > 1 then
                passage[#passage + 1] = { kind = "operator",
                    text = "  " .. self:GetText("NAVIGATION_AND"):match("^%s*(.-)%s*$") }
            end
            for _, line in ipairs(reason) do passage[#passage + 1] = line end
        end
        local identity = {}
        for _, line in ipairs(passage) do identity[#identity + 1] = line.text end
        local signature = table.concat(identity, "\n")
        if #reasons > 0 and not seen[signature] then
            for _, line in ipairs(passage) do lines[#lines + 1] = line end
            seen[signature] = true
        end
    end
    if #lines == 1 then
        lines[#lines + 1] = { kind = "spacer", text = "" }
        lines[#lines + 1] = { kind = "requirement", text = self:GetText("NAVIGATION_NO_KNOWN_PASSAGE") }
    end
    local text = {}
    for _, line in ipairs(lines) do text[#text + 1] = line.text end
    -- Plain text stays usable outside WoW. Consumers may style the semantic
    -- lines without parsing translated strings or changing the explanation.
    return table.concat(text, "\n"), lines
end
