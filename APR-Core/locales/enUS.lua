local L = LibStub("AceLocale-3.0"):NewLocale("APR", "enUS", true)
if not L then return end

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="ignore")@

-- Panel placement. Native labels and existing APR keys are reused by the controls.
L["UI_LAYOUT_TITLE"] = "Place your panels"
L["UI_LAYOUT_HELP"] = "Drag the previews, including hidden panels. Save applies their positions; Cancel keeps your layout."
L["UI_LAYOUT_RECOVER"] = "Bring previews back on screen"
L["UI_LAYOUT_LINKED"] = "Drag to detach this panel when you save."
L["UI_LAYOUT_FREE"] = "Drag this preview, then save its position."
L["UI_LAYOUT_COMBAT"] = "You can arrange your panels after combat."
