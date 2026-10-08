-- Load the checked-in locale defaults into the lightweight UI fixtures.
-- The dedicated localization suite exercises the real AceLocale write proxies and packager priority.
local originalLibStub = LibStub
local locale = originalLibStub("AceLocale-3.0"):GetLocale("APR")
local active = GetLocale and GetLocale() or "enUS"
local aceLocale = {
    GetLocale = function() return locale end,
    NewLocale = function(_, _, language, isDefault)
        if isDefault or language == active then return locale end
    end,
}
function LibStub(name, ...)
    if name == "AceLocale-3.0" then return aceLocale end
    return originalLibStub(name, ...)
end
dofile("APR-Core/locales/enUS.lua")
dofile("APR-Core/locales/frFR.lua")
return locale
