-- Run the actual purchase engine for the deficits used by Forever route buys.
local bags, calls, advances, epoch = {}, {}, 0, 1
APR={settings={profile={debug=false}},Debug=function() end,
    CaptureStepContext=function() return epoch end,
    IsStepContextCurrent=function(_,context) return context==epoch end,
    GetCollectionItemCount=function(_,id,bank) assert(bank==false);return bags[id] or 0 end,
    UpdateNextStep=function() advances=advances+1 end}
local goods
function GetMerchantNumItems() return #goods end
function GetMerchantItemID(i) return goods[i].itemID end
function BuyMerchantItem(i,count)
    local id=goods[i].itemID
    calls[#calls+1]={id=id,count=count}
    bags[id]=(bags[id] or 0)+count
end
dofile('APR-Core/utils/BuyMerchantUtils.lua')
for _,spec in ipairs({{3030,2600},{1179,40},{12251,1},{17031,2}}) do
    for _,stock in ipairs({0,math.floor(spec[2]/2),spec[2],spec[2]+1}) do
        epoch=epoch+1; advances=0;calls={};bags={[spec[1]]=stock}
        goods={{itemID=spec[1],quantity=spec[2],targetStock=true}}
        APR:StartPurchaseTracking(goods)
        APR:BuyItemFromMerchant(goods)
        if stock>=spec[2] then
            assert(#calls==0 and advances==1,'Full stock must never purchase again')
        else
            assert(#calls==1 and calls[1].count==spec[2]-stock,'Only missing carried stock is bought')
            assert(advances==0,'Inventory change alone must wait for the loot receipt')
            APR:StartPurchaseTracking(goods)
            APR:BuyItemFromMerchant(goods)
            assert(#calls==1,'Reopening before receipt must not duplicate the purchase')
            APR:UpdatePurchaseTracking(spec[1],spec[2]-stock)
            assert(advances==1)
            APR:UpdatePurchaseTracking(spec[1],spec[2]-stock)
            assert(advances==1,'Duplicate receipt must not advance twice')
        end
    end
end
epoch=epoch+1;bags={};calls={};advances=0
goods={{itemID=159,quantity=10}}
APR:StartPurchaseTracking(goods);APR:BuyItemFromMerchant(goods)
assert(calls[1].count==10,'Explicit additional quantities keep their original meaning')
epoch=epoch+1
APR:UpdatePurchaseTracking(159,10)
assert(advances==0,'A stale receipt must not advance another step')
-- The actual merchant event must enforce the NPC attached to the route buy.
local function noop() end
function LibStub() return {GetLocale=function() return {} end} end
function IsModifierKeyDown() return false end
function geterrorhandler() return error end
function CreateFrame() return {RegisterEvent=noop,SetScript=noop,UnregisterEvent=noop} end
APR.NewModule=function() return {} end
APR.settings.profile.enableAddon=true
APR.GetSettingsProfile=function(self) return self.settings.profile end
APR.IsInstanceWithUI=function() return true end
APR.RefreshInstanceUIVisibility=noop;APR.MaybePromptInstanceUIPreference=noop
APR.DebugEvent=noop;APR.StartPerformanceSample=noop;APR.FinishPerformanceSample=noop
local npc=999
APR.GetTargetID=function(_,unit) assert(unit=='npc');return npc end
goods={{itemID=12251,quantity=1,targetStock=true}}
APR.GetCurrentStep=function() return {BuyMerchant=goods,MerchantNPC=4884} end
dofile('APR-Core/core/Event.lua')
local event={tag='merchant',callback=APR.event.functions.merchant}
bags={};calls={};epoch=epoch+1;advances=0
APR.event.EventHandler(event,'MERCHANT_SHOW')
assert(#calls==0,'A different merchant must never start this purchase')
npc=4884
APR.event.EventHandler(event,'MERCHANT_SHOW')
assert(#calls==1 and calls[1].id==12251 and advances==0,'The right NPC purchases and waits for receipt')
APR:UpdatePurchaseTracking(12251,1)
assert(advances==1)
print('Merchant stock: zero/partial/full bags, additional quantities, receipt waits and reopen/stale guards passed')
