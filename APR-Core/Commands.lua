local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.command = APR:NewModule("Command")
-- Chat commands, such as /apr reset, /apr skip, /apr skipcamp
function APR.command:SlashCmd(input)
    local inputText = string.lower(input)
    if not APR.settings.profile.enableAddon then
        APR.settings:OpenSettings(APR.title)
        print(L["ADDON"] .. ' ' .. L["DISABLE"])
    end
    if (inputText == "reset" or inputText == "r") then
        --Command to reset the current route
        APR:ResetRoute(APR.ActiveRoute)
    elseif inputText == "resetcustom" then
        APRData.CustomRoute = {}
        C_UI.Reload()
    elseif (inputText == "forcereset" or inputText == "fr") then
        APRData[APR.PlayerID] = {}
        APRZoneCompleted[APR.PlayerID] = {}
        APRCustomPath[APR.PlayerID] = {}
        C_UI.Reload()
    elseif (inputText == "skip" or inputText == "s" or inputText == "skippiedoodaa") then
        -- Command for skipping the current quest step
        print("APR: " .. L["SKIP"])
        APR:NextQuestStep()
        APR.BookingList["UpdateMapId"] = true
    elseif (inputText == "rollback" or inputText == "rb") then
        -- Command for rollback the current quest step
        print("APR: " .. L["ROLLBACK"])
        APR:PreviousQuestStep()
        APR.BookingList["UpdateMapId"] = true
    elseif (inputText == "qol") then
        APR.settings.profile.showQuestOrderList = not APR.settings.profile.showQuestOrderList
        APR.questOrderList:RefreshFrameAnchor()
    elseif (inputText == "discord") then
        _G.StaticPopup_Show("Discord_Link")
    elseif (inputText == "status") then
        APR:getStatus()
    elseif (inputText == "github") then
        _G.StaticPopup_Show("Github_Link")
    elseif (inputText == "scribe" or inputText == "writer") then
        APR.questionDialog:CreateMessagePopup(L["SCRIBE_HEADER"] .. "\n\n" .. L["SCRIBE"], L["CLOSE"])
    elseif inputText == 'coord' then
        APR.settings.profile.coordinateShow = not APR.settings.profile.coordinateShow
        APR.coordinate:RefreshFrameAnchor()
    elseif inputText == 'route' then
        APR.settings:OpenSettings(L["ROUTE"])
    elseif inputText == 'about' then
        APR.settings:OpenSettings(L["ABOUT_HELP"])
    elseif inputText == '42' then
        PlaySoundFile("Interface\\Addons\\APR\\APR-Core\\assets\\42.mp3")
        UIErrorsFrame:AddMessage(L["42_COMMAND"], 1.0, 1.0, 0.0, 1.0, UIERRORS_HOLD_TIME)
    elseif (inputText == "help" or inputText == "h") then
        print(L["COMMAND_LIST"] .. ":")
        print("|cffeda55f/apr |r- " .. L["SHOW_MENU"])
        print("|cffeda55f/apr about |r- " .. L["SHOW_ABOUT"])
        print("|cffeda55f/apr coord |r- " .. L["COORD_COMMAND"])
        print("|cffeda55f/apr discord |r- " .. L["DISCORD_COMMAND"])
        print("|cffeda55f/apr forcereset, fr |r- " .. L["FORCERESET_COMMAND"])
        print("|cffeda55f/apr github |r- " .. L["GITHUB_COMMAND"])
        print("|cffeda55f/apr help, h |r- " .. L["HELP_COMMAND"])
        print("|cffeda55f/apr qol |r- " .. L["QOL_COMMAND"])
        print("|cffeda55f/apr reset, r |r- " .. L["RESET_COMMAND"])
        print("|cffeda55f/apr resetcustom |r- " .. L["RESET_CUSTOM_COMMAND"])
        print("|cffeda55f/apr rollback, rb |r- " .. L["ROLLBACK_COMMAND"])
        print("|cffeda55f/apr route |r- " .. L["ROUTE_COMMAND"])
        print("|cffeda55f/apr scribe, writer |r- ;)")
        print("|cffeda55f/apr skip, s, skippiedoodaa |r- " .. L["SKIP_COMMAND"])
        print("|cffeda55f/apr status |r- " .. L["STATUS_COMMAND"])
    else
        APR.settings:OpenSettings(APR.title)
    end
end
