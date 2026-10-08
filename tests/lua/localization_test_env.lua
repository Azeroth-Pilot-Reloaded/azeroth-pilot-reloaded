-- UI tests use placeholder labels, independent of packaged translations.
local originalLibStub = LibStub
local locale = originalLibStub("AceLocale-3.0"):GetLocale("APR")
setmetatable(locale, {__index = function(_, key) return key end})
locale.AUTHOR = "%s"
for _, key in ipairs({
    "ACCEPT", "CANCEL", "CHARACTER", "CLASS", "CLOSE", "CLUB_FINDER_COMMUNITY_TYPE", "CONTINENT",
    "CONVERT", "D_MINUTES", "FACTION", "FRAMERATE_LABEL", "HUD_EDIT_MODE_SETTING_CHAT_FRAME_HEIGHT",
    "HUD_EDIT_MODE_SETTING_CHAT_FRAME_WIDTH", "INTERFACE_LABEL", "LANGUAGE", "LEVEL", "MAXIMUM",
    "MILLISECONDS_ABBR", "NAME", "NARRATION_STATUS_HIDDEN", "NO", "OTHER", "OVERVIEW", "SEARCH",
    "SECONDS_ABBR", "SOURCE", "TOTAL", "UNAVAILABLE", "VAS_REALM_LABEL", "YES", "ZONE",
}) do
    _G[key] = key
end
local aceLocale = {GetLocale = function() return locale end}
function LibStub(name, ...)
    if name == "AceLocale-3.0" then return aceLocale end
    return originalLibStub(name, ...)
end
return locale
