local L = LibStub("AceLocale-3.0"):GetLocale("APR")

--- Check if a spell is known by the player (supports both classic and retail APIs).
function APR:IsSpellKnown(spellID)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(spellID)
    end
    -- Fallback for older APIs (will show deprecated warning but necessary for compatibility)
    return false
end

--- Check if the player owns at least one copy of an item (bags/bank).
function APR:PlayerHasItem(itemID)
    if C_Item and C_Item.GetItemCount then
        local count = C_Item.GetItemCount(itemID, true)
        return (count and count > 0) and true or false
    end
    return false
end

function APR:GetSpellName(spellID)
    local spellInfo = (C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)) or nil
    local name = spellInfo and spellInfo.name or GetSpellInfo(spellID)
    return name or ("Spell " .. tostring(spellID))
end

-- Safe item name getter (supports C_Item and GetItemInfo fallback).
function APR:GetItemName(itemID)
    if C_Item and C_Item.GetItemNameByID then
        return C_Item.GetItemNameByID(itemID) or ("Item " .. tostring(itemID))
    end
    return "Item " .. tostring(itemID)
end

-- Checks if the Player have flying rank 1, 2 or 3
function APR:CheckFlySkill()
    return APR:IsSpellKnown(34090) or APR:IsSpellKnown(34091) or APR:IsSpellKnown(90265)
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
                APR:Debug("APR:CheckDenyNPC() - Deny NPC found")

                C_GossipInfo.CloseGossip()
                C_Timer.After(0.3, function() APR:CloseQuest() end)
                APR:NotYet()
            end
        end
    end
end

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

function APR:IsTableEmpty(table)
    if (table) then
        return next(table) == nil
    end
    return false
end

function APR:AcceptQuest()
    AcceptQuest()
end

function APR:CloseQuest()
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

function APR:Debug(msg, data, force)
    if not APR.settings.profile.debug and not force then
        return
    end
    if type(data) == "table" then
        for key, value in pairs(data) do
            print(msg, " - ", key)
            APR:Debug(msg, value)
        end
    elseif data then
        print("|cff00bfff" .. msg .. "|r - ", "|cff00ff00" .. tostring(data) .. "|r")
    else
        print("|cff00bfff" .. msg .. "|r")
    end
end

function APR:DebugEvent(msg, data)
    if APR.settings.profile.showEvent then
        APR:Debug(msg, data, true)
    end
end

--- Display error in chat
--- @param errorMessage string
--- @param data any
function APR:PrintError(errorMessage, data)
    if (errorMessage and type(errorMessage) == "string") then
        local redColorCode = "|cffff0000"
        if data then
            DEFAULT_CHAT_FRAME:AddMessage(redColorCode .. L["ERROR"] .. ": " .. errorMessage .. "|r - ", data)
        else
            DEFAULT_CHAT_FRAME:AddMessage(redColorCode .. L["ERROR"] .. ": " .. errorMessage .. "|r")
        end
        UIErrorsFrame:AddMessage(errorMessage, 1, 0, 0, 1, 5)
    end
end

--- Display info in chat
--- @param msg string
function APR:PrintInfo(msg, data)
    if not data then
        if msg and type(msg) == "string" then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ecff" .. "APR: " .. msg .. "|r")
        end
    else
        if type(data) == "table" then
            for key, value in pairs(data) do
                print(msg, " - ", key)
                APR:PrintInfo(msg, value)
            end
        elseif data then
            print("|cff00ecff" .. msg .. "|r - ", "|cff00ff00" .. tostring(data) .. "|r")
        else
            print("|cff00ecff" .. msg .. "|r")
        end
    end
end

--- Performs the "Love" action for the APR module.
-- Updates APR color scheme for Saint Valentin (Feb 14th).
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

function APR:IsRemixCharacter()
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(1232454) or
        C_UnitAuras.GetPlayerAuraBySpellID(1213439) -- SpellID for "Remix" buff
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

function APR:titleCase(str)
    return (str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

function APR:ResetRoute(targetedRoute)
    APR:Debug("Function: APR:ResetRoute()", targetedRoute)
    APRData[APR.PlayerID][targetedRoute] = 1
    APRData[APR.PlayerID][targetedRoute .. '-SkippedStep'] = 0
    APR:GetTotalSteps(targetedRoute)
    APR.transport:GetMeToRightZone()
    APR:PrintInfo(L["RESET_ROUTE"])
end

function APR:UpdateMapId()
    APR:Debug("Function: APR:UpdateMapId()")
    APR:OverrideRouteData() -- Lumbermill Wod route
    APR.transport:GetMeToRightZone()
end

--- Uses a glider item if available in the player's inventory.
function APR:UseGlider()
    APR:Debug("Function: APR.UseGlider()")

    if APRData.GliderName then
        return APRData.GliderName
    end

    local itemName = L["GOBLIN_GLIDER"]
    local DerpGot = 0

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local containerItemID = C_Container.GetContainerItemID(bag, slot) or 0
            if (containerItemID == 109076) then
                DerpGot = 1
                local itemLink = C_Container.GetContainerItemLink(bag, slot)
                local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(
                    itemLink)
                itemName = itemEquipLoc
                break
            end
        end
        if DerpGot == 1 then
            APRData.GliderName = itemName
            return itemName
        end
    end

    return itemName
end

function APR:DoEmote(step)
    if step and step.Emote then
        local npc_id = APR:GetTargetID() or APR:GetTargetID("mouseover")
        if npc_id == 153580 then -- Gorgroth for quest
            DoEmote(step.Emote)
        end
    end
end


function APR:SkipStepCondition(step)
    -- Skip steps if not Faction or Race or Class or Achievement
    if APR:StepFilterQuestHandler(step) then
        -- Counter for skipper step in the current route
        APRData[APR.PlayerID][APR.ActiveRoute .. '-SkippedStep'] = (APRData[APR.PlayerID]
            [APR.ActiveRoute .. '-SkippedStep'] or 0) + 1
        APR:UpdateNextStep()
        return true
    end
    return false
end

function APR:NotYet()
    APR:PrintInfo(L["NOT_YET"])
    UIErrorsFrame:AddMessage(L["NOT_YET"], 1, 153 / 255, 102 / 255, 1, 5)
end

function APR:GuideToCorpse()
    local currentMapID = APR:GetPlayerParentMapID()
    local corpsePosition = C_DeathInfo.GetCorpseMapPosition(currentMapID)
    local worldCorpsePosition
    if corpsePosition then
        _, worldCorpsePosition = C_Map.GetWorldPosFromMapPos(currentMapID, corpsePosition)
    end

    if worldCorpsePosition then
        APR.currentStep:Reset()
        APR.Arrow:SetArrowActive(true, worldCorpsePosition.y, worldCorpsePosition.x)
        APR.currentStep:AddExtraLineText("DEAD_GUIDE", L["DEAD_GUIDE"], APR.HEXColor.red)
    end
end
