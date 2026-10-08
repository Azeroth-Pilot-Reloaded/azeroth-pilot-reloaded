-- Real AceLocale proxies verify checkout fallbacks and the priority of CurseForge substitutions.
strmatch = string.match
local function LoadLocale(language, packaged)
    LibStub = nil
    function GetLocale() return language end
    function geterrorhandler() return function(message) error(message) end end
    dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
    dofile("APR-Core/libs/AceLocale-3.0/AceLocale-3.0.lua")
    for _, locale in ipairs({"enUS", "frFR"}) do
        local handle = assert(io.open("APR-Core/locales/" .. locale .. ".lua", "r"))
        local code = handle:read("*a"); handle:close()
        if packaged then
            code = code:gsub("%-%-@localization%b()@", function()
                return 'L["UI_PERFORMANCE"] = "CurseForge ' .. locale .. '"'
            end)
        end
        assert(loadstring(code))()
    end
    APR = {}
    dofile("APR-Core/ui/foundations/InterfaceStrings.lua")
    return LibStub("AceLocale-3.0"):GetLocale("APR")
end

local english = LoadLocale("enUS")
assert(APR:LocalizeUI("PERFORMANCE") == "Performance")
assert(APR:LocalizeUI("MEMORY_MIB_FORMAT", 12.5) == "12.50 MiB")
local french = LoadLocale("frFR")
assert(APR:LocalizeUI("PERFORMANCE") == "Performances")
assert(APR:LocalizeUI("MEMORY_MIB_FORMAT", 12.5) == "12.50 Mio")
assert(APR:LocalizeUI("COPY_HINT") == "Sélectionne le rapport, puis appuie sur Ctrl+C.")
assert(APR:LocalizeUI("PERCENT_FORMAT", 12.5) == "12.50 %")
assert(APR:LocalizeUI("PERF_SUMMARY_FORMAT", 2, 1, 0.5, 0.8):find("Moyenne : 0.500 ms", 1, true))
for key, value in pairs(english) do
    assert(type(value) == "string" and type(rawget(french, key)) == "string", "Missing French translation: " .. key)
end

LoadLocale("deDE")
assert(APR:LocalizeUI("PERFORMANCE") == "Performance", "Untranslated locales fall back to English")
local german = LibStub("AceLocale-3.0"):NewLocale("APR", "deDE")
german.UI_PERFORMANCE = "Leistung"
assert(APR:LocalizeUI("PERFORMANCE") == "Leistung", "Other CurseForge locales must reach the UI")
LoadLocale("enGB")
assert(APR:LocalizeUI("PERFORMANCE") == "Performance")
LoadLocale("enUS", true)
assert(APR:LocalizeUI("PERFORMANCE") == "CurseForge enUS", "The default proxy must see packaged English first")
LoadLocale("frFR", true)
assert(APR:LocalizeUI("PERFORMANCE") == "CurseForge frFR", "Packaged French must override checkout defaults")

-- Identical translated asset labels must not collapse the set of files being validated.
local translated = LibStub("AceLocale-3.0"):NewLocale("APR", "frFR")
for _, key in ipairs({"UI_ASSET_LOGO", "UI_ASSET_CHANGELOG", "UI_ASSET_MAP", "UI_ASSET_ARROW"}) do
    translated[key] = "Ressource"
end
dofile("APR-Core/utils/UIUtils.lua")
local checked = {}
function APR:ResolveUIFileAsset(asset, _, context)
    assert(context == "Ressource")
    checked[asset] = true
end
APR:ValidateBundledUIAssets()
local count = 0
for _ in pairs(checked) do count = count + 1 end
assert(count == 4)
print("Localization: real AceLocale, EN/FR defaults, informal French, formatting and CurseForge override priority passed")
