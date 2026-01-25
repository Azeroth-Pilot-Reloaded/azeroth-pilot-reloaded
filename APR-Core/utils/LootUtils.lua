local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.lootUtils = APR.lootUtils or {}

-- Virtual counters for quest loot that is not stored in bags
APR.QuestVirtualItemCount = APR.QuestVirtualItemCount or {}
APR.CurrencyLooted = APR.CurrencyLooted or {}

----------------------------------------------------------------
-- ITEM LOOT HANDLING
-- Handles both quest items and normal items
-- Quest items that do not enter bags are tracked virtually
----------------------------------------------------------------
function APR.lootUtils:OnItemLooted(itemID, quantity)
    if not itemID then return end
    quantity = quantity or 1

    -- Bag count after loot (bags may already be updated)
    local bagCount = C_Item.GetItemCount(itemID, true) or 0

    -- Some quest items never enter bags
    -- If bag count is zero, track them virtually
    if bagCount == 0 then
        APR.QuestVirtualItemCount[itemID] =
            (APR.QuestVirtualItemCount[itemID] or 0) + quantity
    end
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
    if not step then
        return
    end

    local allDone = true

    if step.LootItems then
        for _, lootItem in ipairs(step.LootItems) do
            local itemID = lootItem.itemID
            local requiredQuantity = math.max(lootItem.quantity or 1, 1)

            if itemID then
                -- Real bag count (normal items)
                local bagCount = C_Item.GetItemCount(itemID, true) or 0
                -- Virtual count (quest items that do not enter bags)
                local virtualCount = APR.QuestVirtualItemCount[itemID] or 0

                -- Use the highest value to avoid double counting
                local currentQuantity = math.max(bagCount, virtualCount)

                -- Step-scoped completion check (prevents cross-route/step false positives)
                local isDone =
                    (currentQuantity >= requiredQuantity)
                    or APR.lootUtils:IsLootDone(step, "ITEM", itemID)

                -- If requirement is met, mark this loot objective done for THIS route+step
                if currentQuantity >= requiredQuantity and not isDone then
                    APR.lootUtils:MarkLootDone(step, "ITEM", itemID)
                    isDone = true
                elseif currentQuantity >= requiredQuantity then
                    -- Ensure it is marked done even if we reached the count without having marked it before
                    APR.lootUtils:MarkLootDone(step, "ITEM", itemID)
                end

                if not isDone then
                    allDone = false
                end

                -- UI label
                local itemName = C_Item.GetItemInfo(itemID) or UNKNOWN
                local label = format(L["LOOT_ITEM"], itemName)
                if requiredQuantity > 1 then
                    label = label .. " (" .. currentQuantity .. "/" .. requiredQuantity .. ")"
                end

                -- Update the step line (stable key = itemID)
                APR.currentStep:UpdateQuestStep(itemID, label, itemID)
            end
        end
    end

    -- Move to next step if all loot requirements are completed
    local hasRequirements = (step.LootItems and #step.LootItems > 0)
    if hasRequirements and allDone then
        APR:UpdateNextStep()
    end
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
