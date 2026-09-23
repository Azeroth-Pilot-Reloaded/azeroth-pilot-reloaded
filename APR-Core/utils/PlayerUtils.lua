local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

--- Client family, independent of expansion names used by route categories.
function APR:GetGameVersion()
    local interfaceVersion = tonumber(self.interfaceVersion) or
        (GetBuildInfo and tonumber((select(4, GetBuildInfo())))) or 0
    if interfaceVersion >= 16000 and interfaceVersion < 17000 then
        return APR.GAME_VERSIONS.Forever
    end
    if interfaceVersion >= 100000 then
        return APR.GAME_VERSIONS.Retail
    end
    return APR.GAME_VERSIONS.Classic
end

function APR:IsPetBattleActive()
    return C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle() or false
end

function APR:IsHardcoreCharacter()
    return C_GameRules and C_GameRules.IsHardcoreActive and C_GameRules.IsHardcoreActive() or false
end

--- Numeric comparisons shared by resource and equipment route filters.
function APR:CompareRouteNumber(actual, operator, expected)
    actual, expected = tonumber(actual), tonumber(expected)
    if not actual or not expected then return false end
    if operator == "<" then return actual < expected end
    if operator == "<=" then return actual <= expected end
    if operator == ">" then return actual > expected end
    if operator == ">=" then return actual >= expected end
    if operator == "==" then return actual == expected end
    if operator == "~=" then return actual ~= expected end
    return false
end

function APR:MeetsItemCount(requirement)
    local getCount = C_Item and C_Item.GetItemCount or GetItemCount
    if not getCount then return false end
    local ids = requirement.itemIDs or { requirement.itemID }
    local total = 0
    for _, id in ipairs(ids) do
        local count = getCount(id, requirement.includeBank == true) or 0
        if count == 0 and requirement.includeUsableToys and PlayerHasToy and C_ToyBox and C_ToyBox.IsToyUsable
            and PlayerHasToy(id) and C_ToyBox.IsToyUsable(id) then
            count = 1
        end
        total = total + count
    end
    return self:CompareRouteNumber(total, requirement.operator or ">=", requirement.count)
end

function APR:MeetsEquippedItemStat(requirement)
    local slot, stat, value = requirement.slot, requirement.stat
    if stat == "QUALITY" and GetInventoryItemQuality then
        value = GetInventoryItemQuality("player", slot)
    elseif stat == "LEVEL" and GetInventoryItemID then
        local itemID = GetInventoryItemID("player", slot)
        local getInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
        if itemID and getInfo then value = select(4, getInfo(itemID)) end
    else
        local getStats = C_Item and C_Item.GetItemStats or GetItemStats
        local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
        local stats = link and getStats and getStats(link)
        value = stats and stats[stat]
    end
    if value == nil then return requirement.allowMissing == true end
    if requirement.precision and type(value) == "number" then
        local scale = 10 ^ requirement.precision
        value = math.floor(value * scale + 0.5) / scale
    end
    return self:CompareRouteNumber(value, requirement.operator or "==", requirement.value)
end

function APR:GetPlayerMaxLevel()
    if GetMaxLevelForPlayerExpansion then
        return GetMaxLevelForPlayerExpansion()
    end
    if GetMaxPlayerLevel then
        return GetMaxPlayerLevel()
    end
    return self:GetGameVersion() == APR.GAME_VERSIONS.Retail and 90 or 60
end

--- Check if a spell is known by the player (supports both classic and retail APIs).
-- We keep the dual API call path so the add-on works on multiple client versions without crashing.
function APR:IsSpellKnown(spellID)
    local IsSpellKnown = (C_SpellBook and C_SpellBook.IsSpellKnown) or _G.IsSpellKnown
    return IsSpellKnown and IsSpellKnown(spellID)
end

--- Check a spell or a list of alternative spells using the existing spellbook wrapper.
function APR:IsAnySpellKnown(spellIDs)
    if type(spellIDs) ~= "table" then
        return self:IsSpellKnown(spellIDs)
    end
    for _, spellID in ipairs(spellIDs) do
        if self:IsSpellKnown(spellID) then
            return true
        end
    end
    return false
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
    return self:HasAura(1232454) or self:HasAura(1213439)
end

--- Check whether the player has completed a given achievement.
-- This stays here because it is purely about player state rather than quest steps.
function APR:HasAchievement(achievementID)
    if not _G.GetAchievementInfo then return false end
    local _, _, _, completed = _G.GetAchievementInfo(achievementID)
    return completed
end

--- Lightweight aura presence check for the player.
function APR:HasAura(spellID)
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return false end
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
    return aura ~= nil
end

local function SafeReputationAPICall(api, factionID)
    if type(api) ~= "function" then
        return nil
    end

    local success, result = pcall(api, factionID)
    return success and result or nil
end

local function NormalizeReputationType(reputationType)
    if type(reputationType) ~= "string" then
        return nil
    end

    reputationType = string.lower(reputationType)
    if reputationType == "standing" then
        return APR.REPUTATION_TYPE.Standard
    end

    for _, supportedType in pairs(APR.REPUTATION_TYPE) do
        if reputationType == supportedType then
            return supportedType
        end
    end

    return nil
end

local function GetStandardReputationProgress(factionID, targetLevel)
    local getFactionData = C_Reputation and C_Reputation.GetFactionDataByID
    local factionData = SafeReputationAPICall(getFactionData, factionID)
    if not factionData and GetFactionInfoByID then
        local ok, name, _, reaction, minimum, maximum, standing = pcall(GetFactionInfoByID, factionID)
        if ok and name then
            factionData = { name = name, reaction = reaction, currentReactionThreshold = minimum,
                nextReactionThreshold = maximum, currentStanding = standing }
        end
    end
    if not factionData then
        return nil
    end

    return {
        factionID = factionID,
        targetLevel = targetLevel,
        type = APR.REPUTATION_TYPE.Standard,
        name = factionData.name,
        currentLevel = tonumber(factionData.reaction),
        currentValue = tonumber(factionData.currentStanding),
        minimumValue = tonumber(factionData.currentReactionThreshold),
        maximumValue = tonumber(factionData.nextReactionThreshold),
    }
end

local function GetRenownReputationProgress(factionID, targetLevel)
    local getMajorFactionData = C_MajorFactions and C_MajorFactions.GetMajorFactionData
    local majorFactionData = SafeReputationAPICall(getMajorFactionData, factionID)
    if not majorFactionData then
        return nil
    end

    local currentLevel = tonumber(majorFactionData.renownLevel)
    if currentLevel == nil then
        local getCurrentRenownLevel = C_MajorFactions and C_MajorFactions.GetCurrentRenownLevel
        currentLevel = tonumber(SafeReputationAPICall(getCurrentRenownLevel, factionID))
    end

    return {
        factionID = factionID,
        targetLevel = targetLevel,
        type = APR.REPUTATION_TYPE.Renown,
        name = majorFactionData.name,
        currentLevel = currentLevel,
        maxLevel = tonumber(majorFactionData.maxLevel),
        currentValue = tonumber(majorFactionData.renownReputationEarned),
        minimumValue = 0,
        maximumValue = tonumber(majorFactionData.renownLevelThreshold),
    }
end

local function GetFriendshipReputationProgress(factionID, targetLevel)
    local getFriendshipReputation = C_GossipInfo and C_GossipInfo.GetFriendshipReputation
    local friendshipData = SafeReputationAPICall(getFriendshipReputation, factionID)
    if not friendshipData then
        return nil
    end

    local friendshipFactionID = tonumber(friendshipData.friendshipFactionID)
    if friendshipFactionID and friendshipFactionID <= 0 then
        return nil
    end

    local getFriendshipRanks = C_GossipInfo and C_GossipInfo.GetFriendshipReputationRanks
    local friendshipRanks = SafeReputationAPICall(getFriendshipRanks, friendshipFactionID or factionID)

    return {
        factionID = factionID,
        friendshipFactionID = friendshipFactionID,
        targetLevel = targetLevel,
        type = APR.REPUTATION_TYPE.Friendship,
        name = friendshipData.name,
        currentLevel = friendshipRanks and tonumber(friendshipRanks.currentLevel) or nil,
        maxLevel = friendshipRanks and tonumber(friendshipRanks.maxLevel) or nil,
        currentLabel = friendshipData.reaction,
        currentValue = tonumber(friendshipData.standing),
        minimumValue = tonumber(friendshipData.reactionThreshold),
        maximumValue = tonumber(friendshipData.nextThreshold),
    }
end

--- Resolve a route reputation requirement into a common progress model.
-- If type is omitted, major factions and friendship reputations are detected before standard standings.
---@param requirement table|nil expects factionID, level, and optionally type
---@return table|nil progress
---@return number|nil factionID
---@return number|nil targetLevel
function APR:GetReputationRequirement(requirement)
    if type(requirement) ~= "table" then
        return nil, nil, nil
    end

    local factionID = tonumber(requirement.factionID)
    local targetLevel = tonumber(requirement.level)
    if not factionID or not targetLevel then
        return nil, factionID, targetLevel
    end

    local requestedType = NormalizeReputationType(requirement.type)
    if requirement.type ~= nil and not requestedType then
        return nil, factionID, targetLevel
    end

    local resolvers = {
        [APR.REPUTATION_TYPE.Renown] = GetRenownReputationProgress,
        [APR.REPUTATION_TYPE.Friendship] = GetFriendshipReputationProgress,
        [APR.REPUTATION_TYPE.Standard] = GetStandardReputationProgress,
    }

    if requestedType then
        local progress = resolvers[requestedType](factionID, targetLevel)
        return progress or {
            factionID = factionID,
            targetLevel = targetLevel,
            type = requestedType,
        }, factionID, targetLevel
    end

    local detectionOrder = {
        APR.REPUTATION_TYPE.Renown,
        APR.REPUTATION_TYPE.Friendship,
        APR.REPUTATION_TYPE.Standard,
    }
    for _, reputationType in ipairs(detectionOrder) do
        local progress = resolvers[reputationType](factionID, targetLevel)
        if progress then
            return progress, factionID, targetLevel
        end
    end

    return {
        factionID = factionID,
        targetLevel = targetLevel,
        type = APR.REPUTATION_TYPE.Standard,
    }, factionID, targetLevel
end

--- Return true once the requested standard standing, renown level, or friendship rank is reached.
---@param requirement table|nil expects factionID, level, and optionally type
---@return boolean
function APR:IsReputationLevelReached(requirement)
    local progress, _, targetLevel = self:GetReputationRequirement(requirement)
    local currentLevel = progress and tonumber(progress.currentLevel) or nil
    return currentLevel ~= nil and targetLevel ~= nil and currentLevel >= targetLevel
end

--- Return the localized Blizzard label for a reputation standing.
---@param level number|string|nil
---@return string
function APR:GetReputationStandingLabel(level)
    local standingID = tonumber(level)
    if not standingID then
        return UNKNOWN
    end

    local standingLabel = GetText and GetText("FACTION_STANDING_LABEL" .. standingID, UnitSex("player")) or nil
    return standingLabel or tostring(standingID)
end

--- Return the display label for a target level in any supported reputation system.
---@param progress table|nil
---@param targetLevel number|string|nil
---@return string
function APR:GetReputationLevelLabel(progress, targetLevel)
    if progress and progress.type == APR.REPUTATION_TYPE.Renown then
        return string.format("%s %s", LEVEL, tostring(targetLevel or UNKNOWN))
    end

    if progress and progress.type == APR.REPUTATION_TYPE.Friendship then
        return string.format("%s %s", RANK, tostring(targetLevel or UNKNOWN))
    end

    return self:GetReputationStandingLabel(targetLevel)
end

--- Build the localized display text shared by the current-step and route-list UIs.
---@param requirement table|nil expects factionID, level, and optionally type
---@return string
function APR:GetReputationStepText(requirement)
    local progress, factionID, targetLevel = self:GetReputationRequirement(requirement)
    local reputationLabel = progress and progress.type == APR.REPUTATION_TYPE.Renown and L["RENOWN"] or
        REPUTATION
    local factionName = progress and progress.name or
        string.format("%s %s", FACTION, factionID and tostring(factionID) or UNKNOWN)
    local targetLabel = self:GetReputationLevelLabel(progress, targetLevel)

    return string.format("%s: %s - %s", reputationLabel, factionName, targetLabel)
end

--- Progress within the current standing/rank, using the same data as step completion.
--- Unknown or capped ranges have no measurable bar; do not invent a zero total.
function APR:GetReputationBarProgress(requirement)
    local progress = self:GetReputationRequirement(requirement)
    if not progress or not progress.currentValue or not progress.minimumValue or not progress.maximumValue then
        return nil
    end
    local total = progress.maximumValue - progress.minimumValue
    if total <= 0 then return nil end
    local current = math.max(0, math.min(progress.currentValue - progress.minimumValue, total))
    local label = progress.currentLabel or self:GetReputationLevelLabel(progress, progress.currentLevel)
    return current, total, string.format("%s: %d / %d (%d%%)", label, current, total, math.floor(current / total * 100))
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
