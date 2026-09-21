local currentPurchaseTracking

function APR:StartPurchaseTracking(BuyMerchant)
    if not BuyMerchant then return end
    currentPurchaseTracking = {} -- init or reset
    for _, item in ipairs(BuyMerchant) do
        local required = item.quantity or 1
        currentPurchaseTracking[item.itemID] = { required = required, purchased = 0 }
    end
end

function APR:CheckPurchaseCompletion()
    if not currentPurchaseTracking then return false end
    for itemID, info in pairs(currentPurchaseTracking) do
        if info.purchased < info.required then
            return false
        end
    end
    self:UpdateNextStep()
    return true
end

function APR:UpdatePurchaseTracking(itemID, quantity)
    if currentPurchaseTracking and currentPurchaseTracking[itemID] then
        currentPurchaseTracking[itemID].purchased = currentPurchaseTracking[itemID].purchased + quantity
        APR:CheckPurchaseCompletion()
    end
end

function APR:BuyItemFromMerchant(BuyMerchant)
    if not BuyMerchant or #BuyMerchant == 0 then return end
    if APR:CheckPurchaseCompletion() then return end
    local hasPurchasedAnyRequiredItem = false
    if APR.settings.profile.debug then
        for _, item in ipairs(BuyMerchant) do
            APR:Debug("APR:BuyMerchFunc: itemID=" .. item.itemID .. ", quantity=" .. (item.quantity or 1))
        end
    end
    for i = 1, GetMerchantNumItems() do
        local id = GetMerchantItemID(i)
        for _, item in ipairs(BuyMerchant) do
            if tonumber(id) == item.itemID then
                local quantity = item.quantity or 1
                if quantity > 0 then BuyMerchantItem(i, quantity) end
                hasPurchasedAnyRequiredItem = true
                APR:Debug("Purchase made: itemID=" .. item.itemID .. ", quantity=" .. (item.quantity or 1))
            end
        end
    end
    if hasPurchasedAnyRequiredItem then
        APR:CheckPurchaseCompletion()
    end
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
