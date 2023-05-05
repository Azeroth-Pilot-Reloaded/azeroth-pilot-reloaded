local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("APR")

--[[
Return a string with surrounding stars

TextWithStars("hello")          -- "\*\* hello \*\*"

TextWithStars("hello", 3)       -- "\*\*\* hello \*\*\*"

TextWithStars("hello", 4, true) -- "\*\*\*\* hello"

TextWithStars("hello", 0)       -- "hello"
]]
function TextWithStars(text, count, onlyLeft)
    count = count or 2;

    if count < 1 then
        return text;
    end

    onlyLeft = onlyLeft or false;

    local stars = string.rep("*", count);

    if onlyLeft then
        return stars .. " " .. text;
    end

    return stars .. " " .. text .. " " .. stars;
end

function CheckRidingSkill(skillID)
    local mountSkillIDs = { 90265, 34090, 33391, 33388 }
    for _, skill in pairs(mountSkillIDs) do
        if (GetSpellBookItemInfo(GetSpellInfo(skill))) then
            return true
        elseif (skill == skillID) then
            return GetSpellBookItemInfo(GetSpellInfo(skillID))
        end
    end
end

function GetTargetID(unit)
    unit = unit or "target"
    local target = UnitGUID("target")
    if (target and string.find(target, "(.*)-(.*)")) then
        local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", target)
        return tonumber(npc_id)
    end
    return nil
end

function CheckDenyNPC(steps)
    if (steps and steps["DenyNPC"]) then
        local npc_id, name = GetTargetID(), UnitName("target")
        if (npc_id and name) then
            if (npc_id == steps["DenyNPC"]) then
                C_GossipInfo.CloseGossip()
                C_Timer.After(0.3, APR_CloseQuest)
                print("APR: " .. L["NOT_YET"])
            end
        end
    end
end

function GetSteps(CurStep)
    if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
        return APR.QuestStepList[APR.ActiveMap][CurStep]
    end
    return nil
end

function IsARouteQuest(questId)
    local steps = GetSteps(APR1[APR.Realm][APR.Name][APR.ActiveMap])
    if (steps) then
        local questIds = steps["PickUp"]
        local questIdsDB = steps["PickUpDB"]
        if (Contains(questIds, questId) or Contains(questIdsDB, questId)) then
            return true
        else
            return false
        end
    end
    return false
end

function NumToBool(value)
    return value == 1
end

function Booltonumber(value)
    return value and 1 or 0
end

function Contains(list, x)
    if list then
        for _, v in pairs(list) do
            if v == x then return true end
        end
    end
    return false
end

function APR_AcceptQuest()
    AcceptQuest()
end

function APR_CloseQuest()
    CloseQuest()
end
