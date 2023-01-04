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
    local mountSkillIDs = {90265, 34090, 33391, 33388}
    for _, skill in pairs(mountSkillIDs) do
        if(GetSpellBookItemInfo(GetSpellInfo(skill))) then
            return true 
        elseif (skill == skillID ) then
            return GetSpellBookItemInfo(GetSpellInfo(skillID))
        end
    end
end

function GetTargetID(unit) 
    unit = unit or "target"
	local target = UnitGUID(unit)
	if (target and string.find(target, "(.*)-(.*)")) then
		local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-",target)
		return tonumber(npc_id)
	end
	return nil
end

function NumToBool(value)
    return value==1
end
function Booltonumber(value)
    return value and 1 or 0
end
