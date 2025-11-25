local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

--- Check if a spell is known by the player (supports both classic and retail APIs).
-- We keep the dual API call path so the add-on works on multiple client versions without crashing.
function APR:IsSpellKnown(spellID)
    local IsSpellKnown = (C_SpellBook and C_SpellBook.IsSpellKnown) or _G.IsSpellKnown
    return IsSpellKnown and IsSpellKnown(spellID)
end

--- Check if the player owns at least one copy of an item (bags/bank).
-- This is used by higher-level steps to gate actions that require consumables.
function APR:PlayerHasItem(itemID)
    local GetItemCount = C_Item and C_Item.GetItemCount or _G.GetItemCount
    if not GetItemCount then return false end
    local count = GetItemCount(itemID, true)
    return (count and count > 0) and true or false
end

function APR:GetSpellName(spellID)
    local spellInfo = (C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)) or nil
    local name = spellInfo and spellInfo.name or GetSpellInfo(spellID)
    return name or ("Spell " .. tostring(spellID))
end

--- Safe item name getter (supports C_Item and GetItemInfo fallback).
function APR:GetItemName(itemID)
    local name = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID))
        or (GetItemInfo and select(1, GetItemInfo(itemID)))
    return name or ("Item " .. tostring(itemID))
end

--- Checks if the Player have flying rank 1, 2 or 3.
function APR:CheckFlySkill()
    return APR:IsSpellKnown(34090) or APR:IsSpellKnown(34091) or APR:IsSpellKnown(90265)
end

--- Remove the server suffix from a player name when present (used for cleaner displays).
function APR:TrimPlayerServer(CLPName)
    local CL_First = string.match(CLPName, "^(.-)-")
    return CL_First or CLPName
end

--- Detect Remix-specific characters based on the dedicated aura.
-- This stays separated from general aura logic because it is strictly tied to the Remix event.
function APR:IsRemixCharacter()
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(1232454) or
        C_UnitAuras.GetPlayerAuraBySpellID(1213439) -- SpellID for "Remix" buff
    return aura ~= nil
end

--- Check whether the player has completed a given achievement.
-- This stays here because it is purely about player state rather than quest steps.
function APR:HasAchievement(achievementID)
    local _, _, _, completed = _G.GetAchievementInfo(achievementID)
    return completed
end

--- Lightweight aura presence check for the player.
function APR:HasAura(spellID)
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
    return aura ~= nil
end

--- Uses a glider item if available in the player's inventory.
-- The inventory scan is intentionally verbose so we can easily debug issues with missing glider items.
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
