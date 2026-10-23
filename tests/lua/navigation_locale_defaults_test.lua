-- Navigation state text is supplied exclusively by CurseForge imports.
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
    return library:GetLocale("APR")
end
local tocFile = assert(io.open("APR.toc"))
local toc = tocFile:read("*a"); tocFile:close()
assert(toc:find("APR-Core/locales/locales.xml", 1, true), "CurseForge imports must be loaded")
assert(not toc:find("APR-Core/config/LocaleDefaults.lua", 1, true),
    "Runtime English defaults must not be loaded")
for _, locale in ipairs({ "enUS", "frFR" }) do
    local translated = loadLocale(locale, true)
    for _, key in ipairs(keys) do
        assert(translated[key] == "CurseForge " .. locale .. " " .. key,
            "Navigation text must come from the published translation: " .. key)
    end
    local missing = loadLocale(locale, false)
    for _, key in ipairs(keys) do
        assert(rawget(missing, key) == nil, "Missing imports must not be hidden by English defaults: " .. key)
    end
end
print("Navigation localization: imported translations only, without runtime English defaults")
