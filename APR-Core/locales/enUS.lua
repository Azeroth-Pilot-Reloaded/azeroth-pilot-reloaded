local L = LibStub("AceLocale-3.0"):NewLocale("APR", "enUS", true)
if not L then return end

L["CHECK_FOR_UPDATE"] = "Notify on new version"
L["NEW_VERSION_ALERT"] = "A new version has been installed: %s. Check the changelog for what's new!"

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="ignore")@
