-- Exercise the host's real action checks independently of catalogue fixtures.
local toyID = 253629
local owned, usable, cooldown, bagQueries = true, true, false, 0
local secret = {}
APR = {}
function LibStub() return { GetLocale = function() return {} end } end
function PlayerHasToy(id) return owned and id == toyID end
function APR:CanAccessValue(value) return value ~= secret end
C_ToyBox = { IsToyUsable = function() return usable end }
C_Item = {
    GetItemCount = function() bagQueries = bagQueries + 1; return 0 end,
    IsUsableItem = function() return true end,
    GetItemCooldown = function() return cooldown and 10 or 0, cooldown and 900 or 0, 1 end,
}
dofile("APR-Core/utils/PlayerUtils.lua")

assert(APR:GetRouteActionUsability("item", toyID), "A usable learned toy needs no copy in bags")
assert(bagQueries == 0, "Do not query bag inventory for an owned toy")
usable = nil
local allowed, reason = APR:GetRouteActionUsability("item", toyID)
assert(not allowed and reason == "pending_data", "Unknown toy usability must wait for the client")
usable = false
allowed, reason = APR:GetRouteActionUsability("item", toyID)
assert(not allowed and reason == "unusable", "An account-owned toy can still be unavailable to this character")
usable, cooldown = true, true
allowed, reason = APR:GetRouteActionUsability("item", toyID)
assert(not allowed and reason == "cooldown", "Toys use the item cooldown before entering a route")
assert(APR:GetRouteActionUsability("item", toyID, true), "UI availability may inspect ownership without the cooldown")
C_Item.GetItemCooldown = function() return secret, 900, 1 end
allowed, reason = APR:GetRouteActionUsability("item", toyID)
assert(not allowed and reason == "restricted", "Restricted item timings cannot be treated as ready")
owned = false
allowed, reason = APR:GetRouteActionUsability("item", toyID)
assert(not allowed and reason == "missing", "An unlearned toy without a bag copy is unavailable")

PlayerHasToy, C_ToyBox, C_Item = nil, nil, nil
function GetItemCount() return 1 end
function GetItemCooldown() return 0, 0, 1 end
assert(APR:GetRouteActionUsability("item", 6948), "Legacy clients keep bag item and cooldown support")
print("Navigation toys: collection ownership, character usability, pending data, cooldowns and legacy items passed")
