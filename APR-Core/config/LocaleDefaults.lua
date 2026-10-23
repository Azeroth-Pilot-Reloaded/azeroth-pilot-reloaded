-- Load after imported translations. AceLocale's default write proxy only fills
-- missing entries, so packaged translations always take precedence.
local L = LibStub("AceLocale-3.0"):NewLocale("APR", "enUS", true)
L["NAVIGATION_CALCULATING"] = "Calculating route..."
L["NAVIGATION_WAITING"] = "Waiting for navigation..."
L["NAVIGATION_CONSULT_TAXI"] = "Consult the flight master"
