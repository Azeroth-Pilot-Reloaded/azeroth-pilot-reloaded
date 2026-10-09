-- Routes /apr commands to their gameplay, settings and diagnostic owners.
-- Commands delegate gameplay and UI work to their owning modules.

local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.command = APR:NewModule("Command")

-- Shared by chat help and the About page; each entry corresponds to a supported command below.
function APR.command:GetHelpEntries()
    return {
        {"/apr", L["SHOW_MENU"]},
        {"/apr about", L["SHOW_ABOUT"]},
        {"/apr coord", L["COORD_COMMAND"]},
        {"/apr discord", L["DISCORD_COMMAND"]},
        {"/apr forcereset, fr", L["FORCERESET_COMMAND"]},
        {"/apr github", L["GITHUB_COMMAND"]},
        {"/apr help, h", L["HELP_COMMAND"]},
        {"/apr layout", L["UI_LAYOUT_TITLE"]},
        {"/apr qol", L["QOL_COMMAND"]},
        {"/apr reset, r", L["RESET_COMMAND"]},
        {"/apr resetcustom", L["RESET_CUSTOM_COMMAND"]},
        {"/apr rollback, rb", L["ROLLBACK_COMMAND"]},
        {"/apr route", L["ROUTE_COMMAND"]},
        {"/apr scribe, writer", L["SCRIBE_HEADER"]},
        {"/apr skip, s, skippiedoodaa", L["SKIP_COMMAND"]},
        {"/apr step", L["CURRENT_STEP"]},
        {"/apr status", L["STATUS_COMMAND"]},
        {"/apr zoneinfo, zi", L["ZONEINFO_COMMAND"]},
        {"/apr zonecache", L["ZONECACHE_COMMAND"]},
        {"/apr perf", L["UI_PERFORMANCE"]},
        {"/apr perf on", L["UI_CAPTURE"]},
        {"/apr perf off", L["UI_STOP"]},
        {"/apr worldcoords, wc", L["UI_STATUS_WORLD_COORDINATES"]},
    }
end
-- Chat commands, such as /apr reset, /apr skip, /apr skipcamp
function APR.command:SlashCmd(input)
    local normalizedInput = APR:TrimString(input or "")
    normalizedInput = APR:RemoveContiguousSpaces(normalizedInput)
    local inputText = string.lower(normalizedInput)
    if not APR.settings.profile.enableAddon then
        APR.settings:OpenSettings(APR.title)
        APR:PrintInfo(L["ADDON"] .. ' ' .. L["DISABLE"])
    end
    if inputText == "layout" then
        APR.LayoutEditor:Show()
    elseif inputText == "perf on" then
        APR:SetPerformanceCapture(true)
        APR:PrintInfo(L["UI_PERF_CAPTURE_STARTED"])
    elseif inputText == "perf off" then
        APR:SetPerformanceCapture(false)
        APR:PrintInfo(L["UI_PERF_CAPTURE_STOPPED"])
    elseif inputText == "perf" then
        APR.PerformanceDashboard:Show()
    elseif (inputText == "step") then
        APR:PrintInfo(L["CURRENT_STEP"], APR:GetCurrentStep())
    elseif (inputText == "reset" or inputText == "r") then
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
        APR:SkipQuestStep()
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
        APR.UI:ShowTextReport("Discord", APR.discord)
    elseif (inputText == "status") then
        APR:getStatus()
    elseif (inputText == "github") then
        APR.UI:ShowTextReport("GitHub", APR.github)
    elseif (inputText == "scribe" or inputText == "writer") then
        APR.questionDialog:CreateMessagePopup(L["SCRIBE_HEADER"] .. "\n\n" .. L["SCRIBE"], CLOSE)
    elseif inputText == 'coord' then
        APR.settings.profile.coordinateShow = not APR.settings.profile.coordinateShow
        APR.coordinate:RefreshFrameAnchor()
    elseif inputText == 'worldcoords' or inputText == 'wc' then
        APR.worldCoordinateConverter:Show()
    elseif inputText == 'route' then
        APR.settings:OpenSettings(L["ROUTE"])
    elseif inputText == 'about' then
        APR.settings:OpenSettings(L["ABOUT_HELP"])
    elseif inputText == '42' then
        PlaySoundFile("Interface\\Addons\\APR\\APR-Core\\assets\\sound\\42.mp3")
        local color = APR:GetTextColor("general", "warning")
        UIErrorsFrame:AddMessage(L["42_COMMAND"], color[1], color[2], color[3], color[4], UIERRORS_HOLD_TIME)
    elseif inputText == 'zoneinfo' or inputText == 'zi' then
        -- Print detailed zone detection information
        local report = APR:GetZoneDetectionReport()
        local msg = string.format(L["ZONEINFO_COMMAND_REPORT"],
            report.playerCurrent or 0,
            report.playerParent or 0,
            report.playerContinent or 0,
            table.concat(report.playerHierarchy or {}, ", "),
            report.specialContent and YES or NO,
            report.cacheValid and YES or NO
        )
        APR:PrintInfo(msg)
    elseif inputText == 'zonecache' then
        -- Clear zone detection caches
        APR:InvalidatePlayerZoneCache()
        APR:InvalidateMapInfoCache()
        APR:PrintInfo(L["ZONECACHE_COMMAND_RESULT"])
    elseif (inputText == "help" or inputText == "h") then
        local function printHelp(command, description)
            print(APR:WrapTextWithAppearanceColor(command, "general", "accent") .. " - " .. description)
        end

        APR:PrintInfo(L["COMMAND_LIST"])
        for _, entry in ipairs(self:GetHelpEntries()) do printHelp(entry[1], entry[2]) end
    else
        APR.settings:OpenSettings(APR.title)
    end
end
