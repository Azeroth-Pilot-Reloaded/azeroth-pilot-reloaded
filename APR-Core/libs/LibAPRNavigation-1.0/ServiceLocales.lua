local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("service-locales", 1) then return end
local english = {
    ["FIND_NEAREST"] = "Find nearest" ,
    ["SERVICE_CANCEL"] = "Cancel detour" ,
    ["SERVICE_SEARCHING"] = "Searching for the nearest accessible service…" ,
    ["SERVICE_WAITING_DATA"] = "Service locations or access data are not available yet." ,
    ["SERVICE_TAXI_UNAVAILABLE"] = "Flight master search requires available LibTaxiData data." ,
    ["SERVICE_NOT_FOUND"] = "No accessible service was found for this search." ,
    ["SERVICE_FLIGHT"] = "Flight master" ,
    ["SERVICE_CLASS"] = "Class trainer" ,
    ["SERVICE_TRAINER"] = "Profession trainer" ,
    ["SERVICE_WEAPON"] = "Weapon master" ,
    ["SERVICE_VENDOR"] = "Merchant" ,
    ["SERVICE_REPAIR"] = "Repair" ,
    ["SERVICE_INN"] = "Innkeeper" ,
    ["SERVICE_BANK"] = "Bank" ,
    ["SERVICE_MAILBOX"] = "Mailbox" ,
    ["SERVICE_AUCTION"] = "Auction house" ,
    ["SERVICE_STABLE"] = "Stable master" ,
}
local french = {
    ["FIND_NEAREST"] = "Trouver le plus proche" ,
    ["SERVICE_CANCEL"] = "Annuler le détour" ,
    ["SERVICE_SEARCHING"] = "Recherche du service accessible le plus proche…" ,
    ["SERVICE_WAITING_DATA"] = "Les localisations ou les données d'accès ne sont pas encore disponibles." ,
    ["SERVICE_TAXI_UNAVAILABLE"] = "La recherche des maîtres de vol nécessite les données de LibTaxiData." ,
    ["SERVICE_NOT_FOUND"] = "Aucun service accessible ne correspond à cette recherche." ,
    ["SERVICE_FLIGHT"] = "Maître de vol" ,
    ["SERVICE_CLASS"] = "Maître de classe" ,
    ["SERVICE_TRAINER"] = "Maître de métier" ,
    ["SERVICE_WEAPON"] = "Maître d'armes" ,
    ["SERVICE_VENDOR"] = "Marchand" ,
    ["SERVICE_REPAIR"] = "Réparation" ,
    ["SERVICE_INN"] = "Aubergiste" ,
    ["SERVICE_BANK"] = "Banque" ,
    ["SERVICE_MAILBOX"] = "Boîte aux lettres" ,
    ["SERVICE_AUCTION"] = "Hôtel des ventes" ,
    ["SERVICE_STABLE"] = "Maître des écuries" ,
}
for locale, strings in pairs(Lib.locales) do
    for key, value in pairs(english) do strings[key] = (locale == "frFR" and french[key]) or value end
end
