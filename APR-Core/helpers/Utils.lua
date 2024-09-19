local L = LibStub("AceLocale-3.0"):GetLocale("APR")


-- Checks if the Player have flying rank 1, 2 or 3
function APR:CheckFlySkill()
    return IsSpellKnown(34090) or IsSpellKnown(34091) or IsSpellKnown(90265)
end

function APR:GetTargetID(unit)
    unit = unit or "target"
    local targetGUID = UnitGUID(unit)
    if targetGUID then
        local targetID = select(6, strsplit("-", targetGUID))
        return tonumber(targetID)
    end
    return nil
end

function APR:CheckDenyNPC(step)
    if (step and step.DenyNPC) then
        local npc_id, name = self:GetTargetID(), UnitName("target")
        if (npc_id and name) then
            if (npc_id == step.DenyNPC) then
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
function APR:Contains(list, x)
    if list then
        for _, v in pairs(list) do
            if v == x then return true end
        end
    end
    return false
end

function APR:IsTableEmpty(table)
    if (table) then
        return next(table) == nil
    end
    return false
end

function APR_AcceptQuest()
    AcceptQuest()
end

function APR_CloseQuest()
    CloseQuest()
end

function APR:TrimPlayerServer(CLPName)
    local CL_First = string.match(CLPName, "^(.-)-")
    return CL_First or CLPName
end

function APR:SplitQuestAndObjective(questID)
    local id, objective = questID:match("([^%-]+)%-([^%-]+)")
    if id and objective then
        return tonumber(id), tonumber(objective)
    end
    return tonumber(questID)
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

function APR:Love()
    local currentDate = C_DateAndTime.GetCurrentCalendarTime()
    if currentDate.month == 2 and currentDate.monthDay == 14 then
        APR.Color.blue = APR.Color.pink
        APR.Color.yellow = APR.Color.pink
    end
end

--- Check if we keep UI in instance
--- @return boolean true by default for open world
function APR:IsInstanceWithUI()
    local step = APR.ActiveRoute and self:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    local isInstance, instanceType = IsInInstance()

    if isInstance then
        return (step and step.InstanceQuest) or false
    end

    return true
end

function APR:IsScenarioInstance()
    local isIntance, type = IsInInstance()
    return isIntance and type == "scenario"
end

function APR:getStatus()
    APR.settings:CloseSettings()
    APR:showStatusReport()
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

function APR:IsMoPRemixCharacter()
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(424143)
    return aura ~= nil
end

function APR:ContainsScenarioStepCriteria(table, stepID, criteriaID, criteriaIndex)
    if not table then return false end
    for _, v in ipairs(table) do
        if v.stepID == stepID and v.criteriaID == criteriaID and v.criteriaIndex == criteriaIndex then
            return true
        end
    end
    return false
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
