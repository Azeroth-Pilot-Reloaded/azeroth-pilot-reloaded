--[[
    NPC/target related helpers separated from generic utilities so gameplay logic stays grouped.
]]

--- Extract numeric NPC ID from a unit GUID.
-- The default unit is the current target, but we allow overriding so mouseover or other units can be inspected.
function APR:GetTargetID(unit)
    unit = unit or "target"
    if UnitCreatureID then
        return UnitCreatureID(unit)
    end
    local targetGUID = APR:SafeUnitGUID(unit)
    if targetGUID then
        local targetID = C_CreatureInfo.GetCreatureID and C_CreatureInfo.GetCreatureID(targetGUID) or
            select(6, strsplit("-", targetGUID))
        return tonumber(targetID)
    end
    return nil
end

--- Prevent interactions with forbidden NPCs declared on a step.
-- The function is intentionally defensive: it checks the current target and exits early when no match exists.
function APR:CheckDenyNPC(step)
    if (step and step.DenyNPC) then
        local npc_id, name = self:GetTargetID(), APR:SafeUnitName("target")
        if (npc_id and name) then
            if (npc_id == step.DenyNPC) then
                APR:Debug("APR:CheckDenyNPC() - Deny NPC found")

                C_GossipInfo.CloseGossip()
                C_Timer.After(0.3, function() APR:CloseQuest() end)
                APR:NotYet()
            end
        end
    end
end

--- Trigger a conditional emote on specific NPCs required by a quest step.
function APR:DoEmote(step)
    if step and step.Emote then
        local npc_id = APR:GetTargetID() or APR:GetTargetID("mouseover")
        if npc_id == 153580 then -- Gorgroth for quest
            APR:PerformEmote(step.Emote)
        end
    end
end

--- Perform an emote with a 12.0+ compatible API and legacy fallback.
function APR:PerformEmote(emote)
    if not emote then
        return
    end
    if C_ChatInfo and C_ChatInfo.PerformEmote then
        C_ChatInfo.PerformEmote(emote)
    else
        DoEmote(emote)
    end
end

---Scans a unit to check if it is an NPC and retrieves NPC information.
---@param unit string The unit token to scan (e.g., "target", "mouseover")
---@param source string The source or context of the scan request
---@return boolean|table Returns true if unit is an NPC with data, false otherwise
function APR:ScanUnitForNPC(unit, source)
    if not unit then return end
    if not UnitExists(unit) then return end
    if UnitIsPlayer(unit) then return end

    if not (UnitCanAttack("player", unit) or UnitIsFriend("player", unit)) then
        return
    end

    local npcID = APR:GetTargetID(unit)
    if not npcID or APRData.NPCList[npcID] then return end

    local name = APRSecret:SafeUnitName(unit, nil)
    if not name or name == UNKNOWN then return end

    APRData.NPCList[npcID] = name

    APR:Debug("NPC map", { npcID, name, source })
end

--- Gets the raid icon NPC name for a given NPC ID.
--- @param npcID number The NPC ID to look up
--- @return string|nil The raid icon NPC name, or nil if not found
function APR:GetRaidIconNpcName(npcID)
    if not npcID then
        return nil
    end
    return APRData and APRData.NPCList and APRData.NPCList[npcID] or nil
end

--- Finds the unit token for a raid target with the specified NPC ID.
---
--- @param npcID number The NPC ID to search for among raid targets.
--- @return string|nil unitToken The unit token (e.g., "raid1", "raid2") if found, nil otherwise.
---
--- @usage
--- local token = APR:FindRaidIconUnitToken(12345)
--- if token then
---     print("Found unit: " .. token)
--- end
function APR:FindRaidIconUnitToken(npcID)
    if not npcID then return nil end

    if APR:GetTargetID("target") == npcID then
        return "target"
    end

    if not C_NamePlate or not C_NamePlate.GetNamePlates then
        return nil
    end

    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = plate and plate.namePlateUnitToken
        if unit and APR:GetTargetID(unit) == npcID then
            return unit
        end
    end

    return nil
end

--- Builds a raid icon macro for a specific NPC.
--- @param npcID number The NPC ID to create the macro for
--- @param unitToken string The unit token (e.g., "target", "focus") to apply the macro to
--- @return string The generated macro string
function APR:BuildRaidIconMacro(npcID, unitToken)
    local lines = {}

    if unitToken then
        table.insert(lines, "/target [@" .. unitToken .. ",exists]")
        table.insert(lines, "/tm 8")
        return table.concat(lines, "\n")
    end

    local name = APRData.NPCList[npcID]
    if name then
        table.insert(lines, "/targetexact " .. name)
        table.insert(lines, "/tm 8")
        return table.concat(lines, "\n")
    end

    return ""
end
