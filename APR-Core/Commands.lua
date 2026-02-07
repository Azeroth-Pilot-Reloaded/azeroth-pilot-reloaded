local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.command = APR:NewModule("Command")
-- Chat commands, such as /apr reset, /apr skip, /apr skipcamp
function APR.command:SlashCmd(input)
    local normalizedInput = APR:TrimString(input or "")
    normalizedInput = APR:RemoveContiguousSpaces(normalizedInput)
    local inputText = string.lower(normalizedInput)
    if not APR.settings.profile.enableAddon then
        APR.settings:OpenSettings(APR.title)
        APR:PrintInfo(L["ADDON"] .. ' ' .. L["DISABLE"])
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
        APR:PrintInfo(L["SKIP"])
        APR:NextQuestStep()
        APR:UpdateMapId()
    elseif (inputText == "rollback" or inputText == "rb") then
        -- Command for rollback the current quest step
        APR:PrintInfo(L["ROLLBACK"])
        APR:PreviousQuestStep()
        APR:UpdateMapId()
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
    elseif inputText == 'zoneinfo' or inputText == 'zi' then
        -- Print detailed zone detection information
        local report = APR:GetZoneDetectionReport()
        local msg = string.format(L["ZONEINFO_COMMAND_REPORT"],
            report.playerCurrent or 0,
            report.playerParent or 0,
            report.playerContinent or 0,
            table.concat(report.playerHierarchy or {}, ", "),
            report.specialContent and "YES" or "NO",
            report.cacheValid and "YES" or "NO"
        )
        APR:PrintInfo(msg)
    elseif inputText == 'zonecache' then
        -- Clear zone detection caches
        APR:InvalidatePlayerZoneCache()
        APR:InvalidateMapInfoCache()
        APR:PrintInfo(L["ZONECACHE_COMMAND_RESULT"])
    elseif (inputText == "help" or inputText == "h") then
        local helpColor = "eda55f"
        local function printHelp(command, description)
            print(APR:WrapTextInColorCode(command, helpColor) .. " - " .. description)
        end

        APR:PrintInfo(L["COMMAND_LIST"] .. ":")
        printHelp("/apr", L["SHOW_MENU"])
        printHelp("/apr about", L["SHOW_ABOUT"])
        printHelp("/apr coord", L["COORD_COMMAND"])
        printHelp("/apr debugzone", "Toggle zone detection debug mode")
        printHelp("/apr discord", L["DISCORD_COMMAND"])
        printHelp("/apr forcereset, fr", L["FORCERESET_COMMAND"])
        printHelp("/apr github", L["GITHUB_COMMAND"])
        printHelp("/apr help, h", L["HELP_COMMAND"])
        printHelp("/apr qol", L["QOL_COMMAND"])
        printHelp("/apr reset, r", L["RESET_COMMAND"])
        printHelp("/apr resetcustom", L["RESET_CUSTOM_COMMAND"])
        printHelp("/apr rollback, rb", L["ROLLBACK_COMMAND"])
        printHelp("/apr route", L["ROUTE_COMMAND"])
        printHelp("/apr scribe, writer", ";)")
        printHelp("/apr skip, s, skippiedoodaa", L["SKIP_COMMAND"])
        printHelp("/apr status", L["STATUS_COMMAND"])
        printHelp("/apr zoneinfo", L["ZONEINFO_COMMAND"])
        printHelp("/apr zonecache", L["ZONECACHE_COMMAND"])
    else
        APR.settings:OpenSettings(APR.title)
    end
end
