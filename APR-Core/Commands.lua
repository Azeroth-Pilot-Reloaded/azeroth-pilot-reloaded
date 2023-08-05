local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Chat commands, such as /apr reset, /apr skip, /apr skipcamp
function APR:SlashCmd(input)
    if (input == "reset" or input == "r") then
        --Command for making the quest rescan on completion and reset, including previously skipped steps
        print("APR: " .. L["RESET_ZONE"])
        APRData[APR.Realm][APR.Name][APR.ActiveMap] = 1
    elseif (input == "forcereset" or input == "fr") then
        APRData = {};
        APR_ZoneComplete[APR.Name .. "-" .. APR.Realm] = nil;
        C_UI.Reload()
    elseif (input == "skip" or input == "s" or input == "skippiedoodaa") then
        -- Command for skipping the current quest step
        print("APR: " .. L["SKIP"])
        APRData[APR.Realm][APR.Name][APR.ActiveMap] = APRData[APR.Realm][APR.Name][APR.ActiveMap] + 1
    elseif (input == "rollback" or input == "rb") then
        -- Command for rollback the current quest step
        print("APR: " .. L["ROLLBACK"])
        APRData[APR.Realm][APR.Name][APR.ActiveMap] = APRData[APR.Realm][APR.Name][APR.ActiveMap] - 1
    elseif (input == "discord") then
        _G.StaticPopup_Show("Discord_Link")
    elseif (input == "github") then
        _G.StaticPopup_Show("Github_Link")
    elseif (input == "scribe" or input == "writer") then
        _G.StaticPopup_Show("Scribe")
    elseif (input == "help" or input == "h") then
        print(L["COMMAND_LIST"] .. ":")
        print("|cffeda55f/apr help, h |r- " .. L["HELP_COMMAND"])
        print("|cffeda55f/apr reset, r |r- " .. L["RESET_COMMAND"])
        print("|cffeda55f/apr forcereset, fr |r- " .. L["FORCERESET_COMMAND"])
        print("|cffeda55f/apr skip, s, skippiedoodaa |r- " .. L["SKIP_COMMAND"])
        print("|cffeda55f/apr rollback, rb |r- " .. L["ROLLBACK_COMMAND"])
        print("|cffeda55f/apr discord |r- " .. L["DISCORD_COMMAND"])
        print("|cffeda55f/apr github |r- " .. L["GITHUB_COMMAND"])
    else
        _G.InterfaceOptionsFrame_OpenToCategory(APR.title)
    end
    APR.BookingList["UpdateQuest"] = 1
    APR.BookingList["PrintQStep"] = 1
end

-- Scribe Frame - Astérix et Obélix : Mission Cléopâtre
_G.StaticPopupDialogs["Scribe"] = {
    text = L["SCRIBE_HEADER"] .. "\n\n" .. L["SCRIBE"],
    button1 = L["CLOSE"],
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}
