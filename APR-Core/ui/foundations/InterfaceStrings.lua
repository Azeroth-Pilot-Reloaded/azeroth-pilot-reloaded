-- Formats UI translations registered through AceLocale and the CurseForge locale files.
-- Keep source text in locales, so every supported client language uses the same fallback chain.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function APR:LocalizeUI(key, ...)
    local text = L["UI_" .. key]
    if select("#", ...) > 0 then return string.format(text, ...) end
    return text
end
