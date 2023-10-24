local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.command = APR:NewModule("Command")
-- Chat commands, such as /apr reset, /apr skip, /apr skipcamp
function APR.command:SlashCmd(input)
    if not APR.settings.profile.enableAddon then
        _G.InterfaceOptionsFrame_OpenToCategory(APR.title)
    end
    if (input == "reset" or input == "r") then
        --Command for making the quest rescan on completion and reset, including previously skipped steps
        print("APR: " .. L["RESET_ZONE"])
        APRData[APR.Realm][APR.Username][APR.ActiveMap] = 1
        C_UI.Reload()
    elseif (input == "forcereset" or input == "fr") then
        APRData = {};
        APR_ZoneComplete[APR.Username .. "-" .. APR.Realm] = nil;
        C_UI.Reload()
    elseif (input == "skip" or input == "s" or input == "skippiedoodaa") then
        -- Command for skipping the current quest step
        print("APR: " .. L["SKIP"])
        NextQuestStep()
    elseif (input == "rollback" or input == "rb") then
        -- Command for rollback the current quest step
        print("APR: " .. L["ROLLBACK"])
        PreviousQuestStep()
    elseif (input == "discord") then
        _G.StaticPopup_Show("Discord_Link")
    elseif (input == "github") then
        _G.StaticPopup_Show("Github_Link")
    elseif (input == "scribe" or input == "writer") then
        APR.questionDialog:CreateMessagePopup(L["SCRIBE_HEADER"] .. "\n\n" .. L["SCRIBE"], L["CLOSE"])
    elseif input == 'coord' then
        APR.settings.profile.coordinateShow = not APR.settings.profile.coordinateShow
        APR.coordinate:RefreshFrameAnchor()
    elseif input == 'route' then
        _G.InterfaceOptionsFrame_OpenToCategory(APR.title .. "/Route")
    elseif input == '42' then
        PlaySoundFile("Interface\\Addons\\APR-Core\\assets\\42.mp3")
        UIErrorsFrame:AddMessage(L["42_COMMAND"], 1.0, 1.0, 0.0, 1.0, UIERRORS_HOLD_TIME)
    elseif (input == "help" or input == "h") then
        print(L["COMMAND_LIST"] .. ":")
        print("|cffeda55f/apr help, h |r- " .. L["HELP_COMMAND"])
        print("|cffeda55f/apr route |r- " .. L["ROUTE_COMMAND"])
        print("|cffeda55f/apr reset, r |r- " .. L["RESET_COMMAND"])
        print("|cffeda55f/apr forcereset, fr |r- " .. L["FORCERESET_COMMAND"])
        print("|cffeda55f/apr skip, s, skippiedoodaa |r- " .. L["SKIP_COMMAND"])
        print("|cffeda55f/apr rollback, rb |r- " .. L["ROLLBACK_COMMAND"])
        print("|cffeda55f/apr coord |r- " .. L["COORD_COMMAND"])
        print("|cffeda55f/apr scribe, writer |r- ;)")
        print("|cffeda55f/apr discord |r- " .. L["DISCORD_COMMAND"])
        print("|cffeda55f/apr github |r- " .. L["GITHUB_COMMAND"])
    else
        _G.InterfaceOptionsFrame_OpenToCategory(APR.title)
    end
end
