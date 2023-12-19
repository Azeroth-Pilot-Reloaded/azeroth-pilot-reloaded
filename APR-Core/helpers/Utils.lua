local L = LibStub("AceLocale-3.0"):GetLocale("APR")

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

--- Contain data in list
---@param list array list
---@param x object object to check if in the list
---@return true|false Boolean
function Contains(list, x)
    if list then
        for _, v in pairs(list) do
            if v == x then return true end
        end
    end
    return false
end

function IsTableEmpty(table)
    if (table) then
        return next(table) == nil
    end
    return false
end

-- //TODO: Remove this shit
function PairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0
    local iter = function()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function APR_AcceptQuest()
    AcceptQuest()
end

function APR_CloseQuest()
    CloseQuest()
end

function TrimPlayerServer(CLPName)
    local CL_First = string.match(CLPName, "^(.-)-")
    return CL_First or CLPName
end

--- Display error in chat
--- @param errorMessage string
function APR:PrintError(errorMessage)
    if (errorMessage and type(errorMessage) == "string") then
        local redColorCode = "|cffff0000"
        DEFAULT_CHAT_FRAME:AddMessage(redColorCode .. L["ERROR"] .. ": " .. errorMessage .. "|r")
    end
end

--- Display info in chat
--- @param infoMessage string
function APR:PrintInfo(infoMessage)
    if (infoMessage and type(infoMessage) == "string") then
        local lightBlueColorCode = "|cff00bfff"
        DEFAULT_CHAT_FRAME:AddMessage(lightBlueColorCode .. "APR: " .. infoMessage .. "|r")
    end
end
