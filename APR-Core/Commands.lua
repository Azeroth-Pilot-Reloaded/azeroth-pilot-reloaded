local app = select(2, ...);
local L = app.L;

-- Chat commands, such as /apr reset, /apr skip, /apr skipcamp
function APR_SlashCmd(APR_index)
	if (APR_index == "reset") then
		--Command for making the quest rescan on completion and reset, including previously skipped steps
		print("APR: "..L["RESET_ZONE"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = 1
	elseif (APR_index == "forcereset") then 
		APR1 = nil;
		APR_ZoneComplete[APR.Name.."-"..APR.Realm]=nil;
		C_UI.Reload()
	elseif (APR_index == "showriding") then
		print("APR: "..L["SHOW_RIDING"])
		APR1[APR.Realm][APR.Name]["hideRidingSkill"] = 0
	elseif (APR_index == "hideriding") then
		print("APR: "..L["HIDE_RIDING"])
		APR1[APR.Realm][APR.Name]["hideRidingSkill"] = 1
	elseif (APR_index == "skip") then
		-- Command for skipping the current quest step
		print("APR: "..L["SKIP"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
	elseif (APR_index == "rollback") then
		-- Command for rollback the current quest step
		print("APR: "..L["ROLLBACK"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] - 1
	elseif (APR_index == "skipcamp") then
		-- Command for skipping "camp" step
		print("APR: "..L["SKIPCAMP"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 14
	else
		APR.SettingsOpen = 1
		APR.OptionsFrame.MainFrame:Show()
		APR.RemoveIcons()
		APR.BookingList["OpenedSettings"] = 1
	end
	APR.BookingList["UpdateQuest"] = 1
	APR.BookingList["PrintQStep"] = 1
end