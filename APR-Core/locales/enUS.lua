local L = LibStub("AceLocale-3.0"):NewLocale("APR", "enUS", true)
if not L then return end

L["AUTO_BUY_SUPPLIES"] = "Auto-buy weapons and consumables"
L["AUTO_BUY_SUPPLIES_DESC"] = "Automatically buy weapons, ammunition, food, drink and other consumables marked as supplies in the route. Disabled by default. When disabled, purchase instructions remain visible for manual buying or skipping. Quest purchases are unaffected."

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="ignore")@
