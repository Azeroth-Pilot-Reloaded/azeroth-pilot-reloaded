local L = LibStub("AceLocale-3.0"):NewLocale("APR", "enUS", true)
if not L then return end

-- New concepts without a compatible GlobalString or existing CurseForge key.
-- Defaults also make these settings usable before the next locale export.
L["REWARD_WEIGHT_SCALE"] = "Stat weight scale"
L["REWARD_WEIGHT_SCALE_DESC"] = "Use APR leveling weights for your current class and specialization, or select a Pawn scale for this character and specialization."
L["REWARD_WEIGHT_DEFAULT_DESC"] = "APR leveling weights: %s. Primary attributes and role guide this estimate; special effects and set bonuses are not evaluated."
L["REWARD_PAWN_CHANGED"] = "Pawn scale \"%s\" was added or changed. Use it for automatic quest rewards in APR?"
L["REWARD_PAWN_UNAVAILABLE"] = "Pawn scale \"%s\" is unavailable or has changed. APR weights are being used until you select or confirm a scale."

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="ignore")@
