local L = LibStub("AceLocale-3.0"):NewLocale("APR", "enUS", true)
if not L then return end

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="ignore")@

-- Panel placement. Native labels and existing APR keys are reused by the controls.
L["UI_LAYOUT_TITLE"] = "Place your panels"
L["UI_LAYOUT_HELP"] = "Drag the previews, including hidden panels. Save applies their positions; Cancel keeps your layout."
L["UI_LAYOUT_LINKED"] = "Drag to detach this panel when you save."
L["UI_LAYOUT_FREE"] = "Drag this preview, then save its position."
L["UI_LAYOUT_COMBAT"] = "You can arrange your panels after combat."

-- Route browser guidance; common labels come from WoW or existing APR keys.
L["UI_ROUTE_PREFABS"] = "Start with a ready-made path"
L["UI_ROUTE_SEARCH_HELP"] = "Search all expansions by route, author or type. Clear the search to return to your expansion."
L["UI_ROUTE_NO_RESULTS"] = "No routes match these filters."
L["UI_ROUTE_PATH_EMPTY"] = "Choose a preset above, or add routes with + or right-click."
L["UI_ROUTE_IN_PROGRESS"] = "In progress"
L["UI_ROUTE_NOT_STARTED"] = "Not started"
