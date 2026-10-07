-- FarstriderLibData~Data.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

local L = FarstriderLibData.L

local Util = {}
FarstriderLibData.Util = Util

local lastPlayerLocation = nil

---@return Location playerLocation
function Util.GetPlayerLocation()
    local uiMapId = C_Map.GetBestMapForUnit("player")
    if not uiMapId then
        return lastPlayerLocation or { mapId = 0, pos = { x = 0.5, y = 0.5, z = 0 }, isUI = true }
    end

    local uiMapCoords = C_Map.GetPlayerMapPosition(uiMapId, "player")

    if not uiMapCoords then
        local mapInfo = C_Map.GetMapInfo(uiMapId)
        local parentMapId = mapInfo and mapInfo.parentMapID
        if parentMapId then
            uiMapId = parentMapId

            local instanceId = EJ_GetInstanceForMap(uiMapId)
            local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(parentMapId)
            if instanceId and dungeonEntrances then
                for _, entrance in ipairs(dungeonEntrances) do
                    if entrance.journalInstanceID == instanceId then
                        uiMapId = parentMapId
                        uiMapCoords = entrance.position
                        break
                    end
                end
            end
        end
    end

    if not uiMapCoords then
        uiMapCoords = { x = 0.5, y = 0.5 }
    end

    lastPlayerLocation = { mapId = uiMapId, pos = { x = uiMapCoords.x, y = uiMapCoords.y, z = 0 }, isUI = true }
    return lastPlayerLocation
end

---@return Location
function Util.GetBindingLocation()
    local loc = FarstriderLibData.Areas[FarstriderLibData.AreaL[GetBindLocation()]]
    return { mapId = loc.mapId, pos = { x = loc.pos.x, y = loc.pos.y, z = loc.pos.z }, isUI = false }
end

---@type table<number, ItemMixin>
local itemCache = {}

---@param itemId number
---@return ItemMixin
function Util.GetItem(itemId)
    if not itemCache[itemId] then
        itemCache[itemId] = Item:CreateFromItemID(itemId)
    end

    return itemCache[itemId]
end

---@param itemId number
---@return string itemName
function Util.GetItemNameSafe(itemId)
    return Util.GetItem(itemId):GetItemName() or L["Item_" .. itemId]
end

---@type table<number, SpellMixin>
local spellCache = {}

function Util.GetSpell(spellId)
    if not spellCache[spellId] then
        spellCache[spellId] = Spell:CreateFromSpellID(spellId)
    end

    return spellCache[spellId]
end

function Util.GetSpellNameSafe(spellId)
    return Util.GetSpell(spellId):GetSpellName() or L["Spell_" .. spellId]
end

--- Returns whether the player can currently use a given spell.
---@param spellId number
---@return boolean
function Util.CanUseSpell(spellId)
    if not spellId then return false end

    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        if InCombatLockdown() then return false end
    end

    if not C_SpellBook.IsSpellInSpellBook(spellId) then return false end

    local chargeInfo = C_Spell.GetSpellCharges(spellId)
    if chargeInfo and chargeInfo.currentCharges > 0 then return true end

    return C_Spell.GetSpellCooldown(spellId).duration <= 0
end

--- Returns whether the player has a learned toy AND can actually use it.
--- `PlayerHasToy` only reports ownership, not usability — engineering-gated toys
--- (wormhole generators, dimensional rippers, etc.) report `PlayerHasToy = true`
--- regardless of profession/specialization. `C_ToyBox.IsToyUsable` reflects the
--- game's own requirement check (profession, specialization, skill level, class,
--- faction), so we defer to it when available.
---@param itemId number
---@return boolean
local function HasUsableToy(itemId)
    if not PlayerHasToy(itemId) then return false end
    if C_ToyBox and C_ToyBox.IsToyUsable then
        local usable = C_ToyBox.IsToyUsable(itemId)
        -- IsToyUsable returns nil while toy data is still loading; treat nil as
        -- usable so a transient load state doesn't drop a valid travel option.
        if usable == false then return false end
    end
    return true
end

--- Returns whether the player can currently use a given item.
---@param itemId number
---@return boolean
function Util.CanUseItem(itemId)
    if not itemId then return false end
    if not (HasUsableToy(itemId) or (C_Item.GetItemCount(itemId) > 0 and C_Item.IsUsableItem(itemId))) then return false end

    if C_Item.GetItemCooldown then
        if select(2, C_Item.GetItemCooldown(itemId)) <= 0 then return true end
    elseif C_Container then
        if select(2, C_Container.GetItemCooldown(itemId)) <= 0 then return true end
    end

    local chargeInfo = C_Spell.GetSpellCharges(C_Item.GetItemSpell(itemId))
    if chargeInfo and chargeInfo.currentCharges > 0 then return true end

    return false
end

---Returns true if the player's current bind location is supported, false otherwise
---@return boolean
function Util.IsBindLocationSupported()
    return FarstriderLibData.AreaL[GetBindLocation()] ~= nil
end
