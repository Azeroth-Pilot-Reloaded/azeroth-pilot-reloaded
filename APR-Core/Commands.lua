local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("APR")

-- Chat commands, such as /apr reset, /apr skip, /apr skipcamp
function APR_SlashCmd(APR_index)
	if (APR_index == "reset" or APR_index == "r") then
		--Command for making the quest rescan on completion and reset, including previously skipped steps
		print("APR: " .. L["RESET_ZONE"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = 1
	elseif (APR_index == "forcereset" or APR_index == "fr") then
		APR1 = nil;
		APR_ZoneComplete[APR.Name .. "-" .. APR.Realm] = nil;
		C_UI.Reload()
	elseif (APR_index == "showriding" or APR_index == "sr") then
		print("APR: " .. L["SHOW_RIDING"])
		APR1[APR.Realm][APR.Name]["hideRidingSkill"] = 0
	elseif (APR_index == "hideriding" or APR_index == "hr") then
		print("APR: " .. L["HIDE_RIDING"])
		APR1[APR.Realm][APR.Name]["hideRidingSkill"] = 1
	elseif (APR_index == "skip" or APR_index == "s" or APR_index == "skippiedoodaa") then
		-- Command for skipping the current quest step
		print("APR: " .. L["SKIP"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
	elseif (APR_index == "rollback" or APR_index == "rb") then
		-- Command for rollback the current quest step
		print("APR: " .. L["ROLLBACK"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] - 1
	elseif (APR_index == "skipcamp") then
		-- Command for skipping "camp" step
		print("APR: " .. L["SKIPCAMP"])
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 14
	elseif (APR_index == "discord" or APR_index == "d") then
		print(DISCORD)
	elseif (APR_index == "help" or APR_index == "h") then
		print(L["COMMAND_LIST"] .. ":")
		print("|cffeda55f/apr help, h |r- " .. L["HELP_COMMAND"])
		print("|cffeda55f/apr reset, r |r- " .. L["RESET_COMMAND"])
		print("|cffeda55f/apr forcereset, fr |r- " .. L["FORCERESET_COMMAND"])
		print("|cffeda55f/apr skip, s, skippiedoodaa |r- " .. L["SKIP_COMMAND"])
		print("|cffeda55f/apr rollback, rb |r- " .. L["ROLLBACK_COMMAND"])
		print("|cffeda55f/apr showriding, sr |r- " .. L["RIDING_SHOW_COMMAND"])
		print("|cffeda55f/apr hideriding, hr |r- " .. L["RIDING_HIDE_COMMAND"])
		print("|cffeda55f/apr discord, d |r- " .. L["DISCORD_COMMAND"])
		print(" ")
		print(L["NEED_HELP"] .. " " .. DISCORD)
	else
		APR.SettingsOpen = 1
		APR.OptionsFrame.MainFrame:Show()
		APR.RemoveIcons()
		APR.BookingList["OpenedSettings"] = 1
	end
	APR.BookingList["UpdateQuest"] = 1
	APR.BookingList["PrintQStep"] = 1
end
