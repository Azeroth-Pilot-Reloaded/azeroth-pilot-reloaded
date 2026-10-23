-- Use the real AceLocale write proxies: NewLocale returns a registration proxy,
-- so reading/rawget on that proxy cannot detect imported translations.
local keys = { "NAVIGATION_CALCULATING", "NAVIGATION_WAITING", "NAVIGATION_CONSULT_TAXI" }
local function loadLocale(locale, published)
    local library
    LibStub = setmetatable({ NewLibrary = function() library = {}; return library end },
        { __call = function() return library end })
    function GetLocale() return locale end
    function geterrorhandler() return function(message) error(message) end end
    dofile("APR-Core/libs/AceLocale-3.0/AceLocale-3.0.lua")
    for _, language in ipairs({ "enUS", "frFR" }) do
        local file = assert(io.open("APR-Core/locales/" .. language .. ".lua"))
        local source = file:read("*a"); file:close()
        local import = ""
        if published then
            for _, key in ipairs(keys) do import = import .. "L[" .. string.format("%q", key) .. "] = " ..
                string.format("%q", "CurseForge " .. language .. " " .. key) .. "\n" end
        end
        source = source:gsub("%-%-@localization.-@", function() return import end)
        assert(loadstring(source))()
    end
    dofile("APR-Core/config/LocaleDefaults.lua")
    return library:GetLocale("APR")
end
local tocFile = assert(io.open("APR.toc"))
local toc = tocFile:read("*a"); tocFile:close()
assert(toc:find("APR-Core/locales/locales.xml", 1, true) <
    toc:find("APR-Core/config/LocaleDefaults.lua", 1, true), "Fallbacks load after all imported translations")
for _, locale in ipairs({ "enUS", "frFR" }) do
    local translated = loadLocale(locale, true)
    for _, key in ipairs(keys) do
        assert(translated[key] == "CurseForge " .. locale .. " " .. key, "Published translations must win: " .. key)
    end
    local defaults = loadLocale(locale, false)
    for _, key in ipairs(keys) do assert(type(rawget(defaults, key)) == "string" and defaults[key] ~= key) end
    for key in pairs(defaults) do
        if key:find("^NAVIGATION_") then
            assert(key == keys[1] or key == keys[2] or key == keys[3], "Navigation library strings cannot remain in APR: " .. key)
        end
    end
    for _, key in ipairs({ "NAVIGATION_WAYPOINT", "NAVIGATION_TRANSPORT", "NAVIGATION_FLY_TO", "NAVIGATION_VERIFY_TAXI" }) do
        assert(rawget(defaults, key) == nil, "Existing APR translations must not be duplicated: " .. key)
    end
end
print("Navigation locale defaults: published CurseForge values win; source defaults and reused APR keys remain compatible")
