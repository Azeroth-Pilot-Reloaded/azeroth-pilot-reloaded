local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Virtual counters for quest loot that is not stored in bags.
APR.QuestVirtualItemCount = APR.QuestVirtualItemCount or {}

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
                local bagCount = C_Item.GetItemCount(itemID, true) or 0
                local virtualCount = APR.QuestVirtualItemCount[itemID] or 0
                local currentQuantity = math.max(bagCount, virtualCount)

                if currentQuantity >= requiredQuantity and not tContains(APRItemLooted[APR.PlayerID], itemID) then
                    tinsert(APRItemLooted[APR.PlayerID], itemID)
                end

                local isDone = (currentQuantity >= requiredQuantity) or tContains(APRItemLooted[APR.PlayerID], itemID)
                if not isDone then
                    allDone = false
                end

                local itemName = C_Item.GetItemInfo(itemID) or UNKNOWN
                local label = format(L["LOOT_ITEM"], itemName)
                if requiredQuantity > 1 then
                    label = label .. " (" .. currentQuantity .. "/" .. requiredQuantity .. ")"
                end

                APR.currentStep:UpdateQuestStep(itemID, label, itemID)
            end
        end
    end

    local hasRequirements = (step.LootItems and #step.LootItems > 0)
    if hasRequirements and allDone then
        APR:UpdateNextStep()
    end
end

