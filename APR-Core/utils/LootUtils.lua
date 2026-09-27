local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.lootUtils = APR.lootUtils or {}

APR.CurrencyLooted = APR.CurrencyLooted or {}

-- Bank counts are character data, independent of the active route. Refresh them
-- only while the bank is accessible; they remain available after closing/reloading.
function APR:SaveBankItemCounts()
    if not self.routeBankOpen or not APRData or not APRData[self.PlayerID] then return end
    local slots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local info = C_Container and C_Container.GetContainerItemInfo or GetContainerItemInfo
    if not slots or not info or (slots(-1) or 0) == 0 then return end
    local counts = {}
    local bags = {-1}
    for bag = (NUM_BAG_SLOTS or 4) + 1, (NUM_BAG_SLOTS or 4) + (NUM_BANKBAGSLOTS or 7) do bags[#bags + 1] = bag end
    for _, bag in ipairs(bags) do
        for slot = 1, slots(bag) or 0 do
            local item, count, _, _, _, _, _, _, _, id = info(bag, slot)
            if type(item) == "table" then id, count = item.itemID, item.stackCount end
            if id then counts[id] = (counts[id] or 0) + (count or 0) end
        end
    end
    APRData[self.PlayerID].BankItems = counts
end

function APR:GetCollectionItemCount(itemID)
    local fn = C_Item and C_Item.GetItemCount or GetItemCount
    if not fn then return 0 end
    local bags = fn(itemID, false) or 0
    local data = APRData and APRData[self.PlayerID]
    if data and data.BankItems then return bags + (data.BankItems[itemID] or 0) end
    return fn(itemID, true) or bags
end

function APR:IsRouteCollectionComplete(rule)
    return self:GetCollectionItemCount(rule.itemID) >= (rule.quantity or 1)
end

-- Current cash plus the theoretical vendor value of carried items. Never counts
-- bank contents, buys back items, or sells anything. Missing item data contributes
-- zero until GET_ITEM_INFO_RECEIVED refreshes the active objective.
function APR:GetLootMoneyProgress(rule)
    local cash, resale = GetMoney() or 0, 0
    local itemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    local function addItem(item, count)
        if not item or not itemInfo then return end
        local price = select(11, itemInfo(item))
        if type(price) == "number" and price > 0 then
            resale = resale + price * (count or 1)
        end
    end
    local slots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local info = C_Container and C_Container.GetContainerItemInfo or GetContainerItemInfo
    if slots and info then
        for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
            for slot = 1, slots(bag) or 0 do
                local item, count, _, _, _, _, link, _, noValue, id = info(bag, slot)
                if type(item) == "table" then
                    link, id, count, noValue = item.hyperlink, item.itemID, item.stackCount, item.hasNoValue
                end
                if not noValue then addItem(link or id, count) end
            end
        end
    end
    if GetInventoryItemLink or GetInventoryItemID then
        local selected = {}
        if rule.includeEquipped then
            for slot = 1, 19 do selected[slot] = true end
        else
            for _, slot in ipairs(rule.equippedSlots or {}) do selected[slot] = true end
        end
        for slot in pairs(selected) do
            local item = GetInventoryItemLink and GetInventoryItemLink("player", slot)
                or GetInventoryItemID and GetInventoryItemID("player", slot)
            addItem(item, GetInventoryItemCount and GetInventoryItemCount("player", slot) or 1)
        end
    end
    return cash, resale, math.max(1, tonumber(rule.copper) or 1)
end

function APR:FormatLootMoney(copper)
    local formatMoney = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
    return formatMoney and formatMoney(copper) or tostring(copper)
end

function APR:GetLootMoneyStepText(rule)
    return string.format(L["LOOT_MONEY"], self:FormatLootMoney(rule.copper))
end

----------------------------------------------------------------
-- MONEY HANDLING (gold / silver / copper)
-- Amount is already a delta in copper (from PLAYER_MONEY)
----------------------------------------------------------------
function APR.lootUtils:OnMoneyLooted(copperDelta)
    if not copperDelta or copperDelta <= 0 then return end

    -- Only track money if the current step requires it
    if APR.currentStep and APR.currentStep.LootMoney then
        APR.MoneyLooted = (APR.MoneyLooted or 0) + copperDelta
    end
end

----------------------------------------------------------------
-- CURRENCY HANDLING (Honor, Resources, etc.)
-- These are NOT money and use the currency system
----------------------------------------------------------------
function APR.lootUtils:OnCurrencyGained(currencyID, quantity)
    if not currencyID or not quantity or quantity <= 0 then return end

    APR.CurrencyLooted[currencyID] =
        (APR.CurrencyLooted[currencyID] or 0) + quantity
end

----------------------------------------------------------------
-- STEP DISPLAY REFRESH
-- Unified logic for quest items and normal items
----------------------------------------------------------------
function APR:RefreshLootStepDisplay(step)
    if step and step.LootItems then self:UpdateStep() end
end

function APR.lootUtils:GetLootKey(step, lootType, lootID)
    if not step or not APR.ActiveRoute then return nil end
    local stepIndex = step._index or 1
    return table.concat({
        APR.ActiveRoute,
        stepIndex,
        lootType,
        tostring(lootID or "NONE")
    }, "::")
end

function APR.lootUtils:MarkLootDone(step, lootType, lootID)
    local playerID = APR.PlayerID
    APRItemLooted[playerID] = APRItemLooted[playerID] or {}

    local key = self:GetLootKey(step, lootType, lootID)
    if key then
        APRItemLooted[playerID][key] = true
    end
end

function APR.lootUtils:IsLootDone(step, lootType, lootID)
    local playerID = APR.PlayerID
    local key = self:GetLootKey(step, lootType, lootID)
    return key and APRItemLooted[playerID] and APRItemLooted[playerID][key]
end
