-- Route quantities are additional purchases unless targetStock explicitly requests carried stock.
-- Completion waits for loot events; inventory deltas only prevent duplicate purchase requests.

local currentPurchaseTracking, currentPurchaseItems, currentPurchaseContext, purchaseCompleted

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
    currentPurchaseTracking = {}
    for _, item in ipairs(BuyMerchant) do
        local carried = self:GetCollectionItemCount(item.itemID, false)
        local required = item.quantity or 1
        if item.targetStock then required = math.max(0, required - carried) end
        currentPurchaseTracking[item.itemID] = { required = required, purchased = 0, initialCarried = carried }
    end
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
    for i = 1, GetMerchantNumItems() do
        local id = GetMerchantItemID(i)
        for _, item in ipairs(BuyMerchant) do
            if tonumber(id) == item.itemID then
                local tracked = currentPurchaseTracking[item.itemID]
                local carried = self:GetCollectionItemCount(item.itemID, false)
                local delivered = math.max(tracked.purchased, carried - tracked.initialCarried)
                local quantity = math.max(0, tracked.required - delivered)
                if item.targetStock then quantity = math.min(quantity, math.max(0, (item.quantity or 1) - carried)) end
                if quantity > 0 then
                    BuyMerchantItem(i, quantity)
                    APR:Debug("Purchase requested: itemID=" .. item.itemID .. ", quantity=" .. quantity)
                end
            end
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
