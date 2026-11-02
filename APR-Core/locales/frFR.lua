local L = LibStub("AceLocale-3.0"):NewLocale("APR", "frFR")
if not L then return end

L["REWARD_WEIGHT_SCALE"] = "Échelle de poids des statistiques"
L["REWARD_WEIGHT_SCALE_DESC"] = "Utilisez les poids de leveling APR adaptés à votre classe et spécialisation, ou une échelle Pawn pour ce personnage et cette spécialisation."
L["REWARD_WEIGHT_DEFAULT_DESC"] = "Poids de leveling APR : %s. Cette estimation repose sur les attributs principaux et le rôle ; les effets spéciaux et bonus d’ensemble ne sont pas évalués."
L["REWARD_PAWN_CHANGED"] = "L’échelle Pawn « %s » a été ajoutée ou modifiée. L’utiliser pour les récompenses de quêtes automatiques dans APR ?"
L["REWARD_PAWN_UNAVAILABLE"] = "L’échelle Pawn « %s » est indisponible ou a changé. Les poids APR sont utilisés jusqu’à la sélection ou la confirmation d’une échelle."

-- Translator: Neogeekmo
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="ignore")@
