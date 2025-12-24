--[[
    NPC/target related helpers separated from generic utilities so gameplay logic stays grouped.
]]

--- Extract numeric NPC ID from a unit GUID.
-- The default unit is the current target, but we allow overriding so mouseover or other units can be inspected.
function APR:GetTargetID(unit)
    unit = unit or "target"
    local targetGUID = UnitGUID(unit)
    if targetGUID then
        local targetID = select(6, strsplit("-", targetGUID))
        return tonumber(targetID)
    end
    return nil
end

--- Prevent interactions with forbidden NPCs declared on a step.
-- The function is intentionally defensive: it checks the current target and exits early when no match exists.
function APR:CheckDenyNPC(step)
    if (step and step.DenyNPC) then
        local npc_id, name = self:GetTargetID(), UnitName("target")
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
            DoEmote(step.Emote) -- //TODO rework for 12.0.0
        end
    end
end
