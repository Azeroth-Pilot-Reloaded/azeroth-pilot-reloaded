-- Route quantities are additional purchases unless targetStock explicitly requests carried stock.
-- Completion waits for loot events; inventory deltas only prevent duplicate purchase requests.

local currentPurchaseTracking, currentPurchaseItems, currentPurchaseContext, purchaseCompleted, purchaseRequested

-- Per-item conditions allow one merchant visit to serve different weapons or
-- classes. Stock targets describe what to carry, not an additional purchase.
function APR:GetMerchantPurchaseQuantity(item)
    if item.questID and C_QuestLog.IsQuestFlaggedCompleted(item.questID) then return 0 end
    if item.conditions and not self:AreConditionalFiltersMet(item.conditions) then return 0 end
    local quantity = item.quantityFromItemID and self:GetCollectionItemCount(item.quantityFromItemID, false)
        or item.quantity or 1
    if item.bagSlots then
        local slots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
        local bagItem = C_Container and C_Container.GetContainerItemID or GetContainerItemID
        if not slots or not bagItem then return 0 end
        local upgrades, loose = 0, 0
        for bag = 1, (NUM_BAG_SLOTS or 4) do
            if (slots(bag) or 0) < item.bagSlots then upgrades = upgrades + 1 end
        end
        -- Bags already equipped are not spare bags; count only carried copies.
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            for slot = 1, slots(bag) or 0 do
                if bagItem(bag, slot) == item.itemID then loose = loose + 1 end
            end
        end
        return math.max(0, math.min(quantity, upgrades) - loose)
    end
    if item.targetStock then
        quantity = math.max(0, quantity - self:GetCollectionItemCount(item.itemID, false))
    end
    return quantity
end

local function IsPurchaseContextCurrent(self)
    return not currentPurchaseContext or self:IsStepContextCurrent(currentPurchaseContext)
end

function APR:StartPurchaseTracking(BuyMerchant)
    if not BuyMerchant then return end
    -- Reopening a merchant or refreshing the same step retains its partial delivery.
    if currentPurchaseItems == BuyMerchant and currentPurchaseTracking and IsPurchaseContextCurrent(self) then return end
    currentPurchaseItems = BuyMerchant
    currentPurchaseContext = self.CaptureStepContext and self:CaptureStepContext()
    purchaseCompleted = false
    purchaseRequested = false
    currentPurchaseTracking = {}
    for _, item in ipairs(BuyMerchant) do
        local carried = self:GetCollectionItemCount(item.itemID, false)
        local required = self:GetMerchantPurchaseQuantity(item)
        currentPurchaseTracking[item.itemID] = { required = required, purchased = 0, initialCarried = carried }
    end
end

-- Cash/bag filters describe entry eligibility. Once a request is made, money
-- and inventory events must not skip the current step before its loot receipts.
function APR:HasPendingMerchantPurchase(items)
    return currentPurchaseItems == items and currentPurchaseTracking and purchaseRequested
        and not purchaseCompleted and IsPurchaseContextCurrent(self) or false
end

function APR:CheckPurchaseCompletion()
    if not currentPurchaseTracking or not IsPurchaseContextCurrent(self) then return false end
    if purchaseCompleted then return true end
    for _, info in pairs(currentPurchaseTracking) do
        if info.purchased < info.required then return false end
    end
    purchaseCompleted = true
    self:UpdateNextStep()
    return true
end

function APR:UpdatePurchaseTracking(itemID, quantity)
    if purchaseCompleted or not IsPurchaseContextCurrent(self) then return end
    if currentPurchaseTracking and currentPurchaseTracking[itemID] then
        currentPurchaseTracking[itemID].purchased = currentPurchaseTracking[itemID].purchased + quantity
        self:CheckPurchaseCompletion()
    end
end

function APR:BuyItemFromMerchant(BuyMerchant)
    if not BuyMerchant or #BuyMerchant == 0 or currentPurchaseItems ~= BuyMerchant
        or not IsPurchaseContextCurrent(self) then return end
    if self:CheckPurchaseCompletion() then return end
    if APR.settings.profile.debug then
        for _, item in ipairs(BuyMerchant) do
            APR:Debug("APR:BuyMerchFunc: itemID=" .. item.itemID .. ", quantity=" .. (item.quantity or 1))
        end
    end
    local found, budget = {}, GetMoney and GetMoney()
    for i = 1, GetMerchantNumItems() do
        local id = GetMerchantItemID(i)
        for _, item in ipairs(BuyMerchant) do
            if tonumber(id) == item.itemID then
                found[item.itemID] = true
                local tracked = currentPurchaseTracking[item.itemID]
                local carried = self:GetCollectionItemCount(item.itemID, false)
                local delivered = math.max(tracked.purchased, carried - tracked.initialCarried)
                local quantity = math.max(0, tracked.required - delivered)
                if item.targetStock then quantity = math.min(quantity, self:GetMerchantPurchaseQuantity(item)) end
                if item.optional or item.reserveCopper then
                    local price, bundleSize, available, extendedCost
                    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
                        local info = C_MerchantFrame.GetItemInfo(i)
                        if info then
                            price, bundleSize, available, extendedCost = info.price, info.stackCount, info.numAvailable,
                                info.hasExtendedCost
                        end
                    elseif GetMerchantItemInfo then
                        local _, _, p, size, stock, _, _, extended = GetMerchantItemInfo(i)
                        price, bundleSize, available, extendedCost = p, size, stock, extended
                    end
                    -- Optional advice must never force a currency purchase or
                    -- spend the money reserved for a later trainer/quest.
                    if type(price) == "number" and type(bundleSize) == "number" and bundleSize > 0
                        and type(budget) == "number" and not extendedCost then
                        if price > 0 then
                            quantity = math.min(quantity, math.floor(math.max(0, budget - (item.reserveCopper or 0))
                                / (price / bundleSize)))
                        end
                        if type(available) == "number" and available >= 0 then quantity = math.min(quantity, available) end
                        budget = budget - quantity * price / bundleSize
                    else
                        quantity = 0
                    end
                    if item.optional then tracked.required = delivered + quantity end
                end
                if quantity > 0 then
                    purchaseRequested = true
                    BuyMerchantItem(i, quantity)
                    APR:Debug("Purchase requested: itemID=" .. item.itemID .. ", quantity=" .. quantity)
                end
            end
        end
    end
    for _, item in ipairs(BuyMerchant) do
        if item.optional and not found[item.itemID] then
            local tracked = currentPurchaseTracking[item.itemID]
            tracked.required = tracked.purchased
        end
    end
    self:CheckPurchaseCompletion()
end

function APR:GetQuantityfromLootMessage(message)
    local quantity = 1 -- by default the quantity if not specified is 1
    local quantityPattern = "x(%d+)"
    local sanitizedMessage = APR:StripHyperlinks(message)
    local extractedQuantity = sanitizedMessage:match(quantityPattern)
    if extractedQuantity then
        quantity = tonumber(extractedQuantity)
    end
    return quantity
end
