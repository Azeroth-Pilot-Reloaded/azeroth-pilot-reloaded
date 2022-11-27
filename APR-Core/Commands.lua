local app = select(2, ...);
local L = app.L;

-- Chat commands, such as /apr reset, /apr skip, /apr skipcamp
function APR_SlashCmd(APR_index)
	if (APR_index == "reset" or APR_index == "r") then
		--Command for making the quest rescan on completion and reset, including previously skipped steps
		print("APR: "..L["RESET_ZONE"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = 1
	elseif (APR_index == "forcereset" or APR_index == "fr") then 
		APR1 = nil;
		APR_ZoneComplete[APR.Name.."-"..APR.Realm]=nil;
		C_UI.Reload()
	elseif (APR_index == "showriding" or APR_index == "sr") then
		print("APR: "..L["SHOW_RIDING"])
		APR1[APR.Realm][APR.Name]["hideRidingSkill"] = 0
	elseif (APR_index == "hideriding" or APR_index == "hr") then
		print("APR: "..L["HIDE_RIDING"])
		APR1[APR.Realm][APR.Name]["hideRidingSkill"] = 1
	elseif (APR_index == "skip" or APR_index == "s") then
		-- Command for skipping the current quest step
		print("APR: "..L["SKIP"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
	elseif (APR_index == "rollback" or APR_index == "rb") then
		-- Command for rollback the current quest step
		print("APR: "..L["ROLLBACK"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] - 1
	elseif (APR_index == "skipcamp") then
		-- Command for skipping "camp" step
		print("APR: "..L["SKIPCAMP"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 14
	elseif (APR_index == "discord" or APR_index == "d") then
		print(DISCORD)
	elseif (APR_index == "help" or APR_index == "h") then
		print("Command list: ")
		print("/apr help, h")
		print("/apr reset, r")
		print("/apr forcereset, fr")
		print("/apr skip, s")
		print("/apr rollback, rb")
		print("/apr showriding, sr")
		print("/apr hideriding, hr")
		print("/apr discord, d")
		print(" ")
		print("Need help ? " ..DISCORD)
	else
		APR.SettingsOpen = 1
		APR.OptionsFrame.MainFrame:Show()
		APR.RemoveIcons()
		APR.BookingList["OpenedSettings"] = 1
	end
	APR.BookingList["UpdateQuest"] = 1
	APR.BookingList["PrintQStep"] = 1
end