local currentPurchaseTracking

function APR:StartPurchaseTracking(BuyMerchant)
    if not BuyMerchant then return end
    currentPurchaseTracking = {} -- init or reset
    for _, item in ipairs(BuyMerchant) do
        currentPurchaseTracking[item.itemID] = { required = item.quantity, purchased = 0 }
    end
end

function APR:CheckPurchaseCompletion()
    for itemID, info in pairs(currentPurchaseTracking) do
        if info.purchased < info.required then
            return
        end
    end
    UpdateNextStep()
end

function APR:UpdatePurchaseTracking(itemID, quantity)
    if currentPurchaseTracking[itemID] then
        currentPurchaseTracking[itemID].purchased = currentPurchaseTracking[itemID].purchased + quantity
        APR:CheckPurchaseCompletion()
    end
end

function APR:BuyMerchFunc(BuyMerchant)
    if not BuyMerchant or #BuyMerchant == 0 then return end
    if APR.settings.profile.debug then
        for _, item in ipairs(BuyMerchant) do
            print("APR:BuyMerchFunc: itemID=" .. item.itemID .. ", quantity=" .. (item.quantity or 1))
        end
    end
    for i = 1, GetMerchantNumItems() do
        local id = GetMerchantItemID(i)
        for _, item in ipairs(BuyMerchant) do
            if tonumber(id) == item.itemID then
                BuyMerchantItem(i, item.quantity or 1)
                if APR.settings.profile.debug then
                    print("Purchase made: itemID=" .. item.itemID .. ", quantity=" .. (item.quantity or 1))
                end
            end
        end
    end
    CloseMerchant()
end

function APR:GetQuantityfromLootMessage(message)
    local quantity = 1 -- by default the quantity if not specified is 1
    local quantityPattern = "x(%d+)"
    local extractedQuantity = message:match(quantityPattern)
    if extractedQuantity then
        quantity = tonumber(extractedQuantity)
    end
    return quantity
end
