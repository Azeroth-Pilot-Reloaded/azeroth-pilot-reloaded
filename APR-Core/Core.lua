local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local DF = _G["DetailsFramework"]

APR = {}
APR = _G.LibStub("AceAddon-3.0"):NewAddon(APR, "APR", "AceEvent-3.0")

local CoreLoadin = false

-- Character
APR.Username = UnitName("player")
APR.Realm = string.gsub(GetRealmName(), " ", "")
APR.Faction = UnitFactionGroup("player") -- "Alliance", "Horde", "Neutral" or nil
APR.Level = UnitLevel("player")
APR.MaxLevel = 70
APR.RaceLocale, APR.Race, APR.RaceID = UnitRace("player")
APR.ClassLocalName, APR.ClassName, APR.ClassId = UnitClass("player")
APR.Gender = UnitSex("player")

-- Quest
APR.QuestStepList = {}
APR.QuestStepListListing = {}
APR.QuestStepListListingStartAreas = {}

function APR:OnInitialize()
    -- Init on TOC
    APR.title = C_AddOns.GetAddOnMetadata("APR", "Title")
    APR.version = C_AddOns.GetAddOnMetadata("APR", "Version")
    APR.github = C_AddOns.GetAddOnMetadata("APR", "X-Github")
    APR.discord = C_AddOns.GetAddOnMetadata("APR", "X-Discord")

    APR.ActiveQuests = {}
    APR.NPCList = {}

    APR.Breadcrums = {}
    APR.IsInRouteZone = false
    APR.ProgressShown = false

    -- BookingList
    APR.BookingList = {}
    APR.InCombat = false
    APR.BookUpdAfterCombat = false

    -- Buff
    APR.SweatBuff = {}
    APR.SweatBuff[1] = false -- TODO REWORK SweatOfOurBrowBuffFrame
    APR.SweatBuff[2] = false -- TODO REWORK SweatOfOurBrowBuffFrame
    APR.SweatBuff[3] = false -- TODO REWORK SweatOfOurBrowBuffFrame

    -- APR INIT NEW SETTING
    APR.settings:InitializeBlizOptions()

    -- APR Saved Data
    APRData = APRData or {}
    APRData[APR.Realm] = APRData[APR.Realm] or {}
    APRData[APR.Realm][APR.Username] = APRData[APR.Realm][APR.Username] or {}
    APRData[APR.Realm][APR.Username].FirstLoad = APRData[APR.Realm][APR.Username].FirstLoad == nil and true or
        APRData[APR.Realm][APR.Username].FirstLoad

    -- Init current step frame
    APR.currentStep:CurrentStepFrameOnInit()

    --Init Party frame
    APR.party:PartyFrameOnInit()

    --Init AFK frame
    APR.AFK:AFKFrameOnInit()

    -- Init Quest Order List frame
    APR.questOrderList:QuestOrderListFrameOnInit()

    -- Init Map/Minimap lines & Icons
    APR.map:OnInit()

    -- Init coordinate frame for dev
    APR.coordinate:PartyFrameOnInit()

    -- Init Changelog frame
    APR.changelog:OnInit()

    -- APR Global Variables, UI oriented
    BINDING_HEADER_APR = APR.title -- Header text for APR's main frame
    _G["BINDING_NAME_" .. "CLICK APRItemButton:LeftButton"] = L["USE_QUEST_ITEM"]

    -- Register tot party frame
    C_ChatInfo.RegisterAddonMessagePrefix("APRChat")
end

function APR.CheckPosMove(zeActivz)
    if (APR.settings.profile.debug) then
        print("Function: APR.CheckPosMove()")
    end
    local zenr = APR.NumbRoutePlan("EasternKingdom")
    local zenr2 = APR.NumbRoutePlan("Kalimdor")
    local zenr3 = APR.NumbRoutePlan("Shadowlands")
    local zenr4 = APR.NumbRoutePlan("SpeedRun")
    local zenr5 = APR.NumbRoutePlan("Extra")
    local zenr6 = APR.NumbRoutePlan("Dragonflight")
    local zenr7 = APR.NumbRoutePlan("MISC 1")
    local zenr8 = APR.NumbRoutePlan("MISC 2")
    local ZeBreak = 0
    local zfrom
    local zto

    for CLi = 1, zenr do
        local ZeMTop = APR.RoutePlan.Custompath["EK3" .. CLi]:GetTop()
        local ZeMBottom = APR.RoutePlan.Custompath["EK3" .. CLi]:GetBottom()
        local ZeMLeft = APR.RoutePlan.Custompath["EK3" .. CLi]:GetLeft()
        local ZeMRight = APR.RoutePlan.Custompath["EK3" .. CLi]:GetRight()
        local ZeMHeight = ((ZeMTop - ZeMBottom) / 2) + ZeMTop
        local ZeMWidth = ((ZeMRight - ZeMLeft) / 2) + ZeMLeft
        for CLi2 = 1, 19 do
            local zsda = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetBottom())
            local zsda2 = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetRight() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft())

            if (ZeMHeight > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() and ZeMHeight < zsda) then
                if (ZeMWidth > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() and ZeMWidth < zsda2) then
                    zfrom = CLi
                    zto = CLi2
                    ZeBreak = 1
                end
            end
            if (ZeBreak == 1) then
                break
            end
        end
        if (ZeBreak == 1) then
            break
        end
    end

    for CLi = 1, zenr2 do
        local ZeMTop = APR.RoutePlan.Custompath["KAL3" .. CLi]:GetTop()
        local ZeMBottom = APR.RoutePlan.Custompath["KAL3" .. CLi]:GetBottom()
        local ZeMLeft = APR.RoutePlan.Custompath["KAL3" .. CLi]:GetLeft()
        local ZeMRight = APR.RoutePlan.Custompath["KAL3" .. CLi]:GetRight()
        local ZeMHeight = ((ZeMTop - ZeMBottom) / 2) + ZeMTop
        local ZeMWidth = ((ZeMRight - ZeMLeft) / 2) + ZeMLeft
        for CLi2 = 1, 19 do
            local zsda = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetBottom())
            local zsda2 = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetRight() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft())

            if (ZeMHeight > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() and ZeMHeight < zsda) then
                if (ZeMWidth > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() and ZeMWidth < zsda2) then
                    zfrom = CLi
                    zto = CLi2
                    ZeBreak = 1
                end
            end
            if (ZeBreak == 1) then
                break
            end
        end
        if (ZeBreak == 1) then
            break
        end
    end

    for CLi = 1, zenr3 do
        local ZeMTop = APR.RoutePlan.Custompath["SL3" .. CLi]:GetTop()
        local ZeMBottom = APR.RoutePlan.Custompath["SL3" .. CLi]:GetBottom()
        local ZeMLeft = APR.RoutePlan.Custompath["SL3" .. CLi]:GetLeft()
        local ZeMRight = APR.RoutePlan.Custompath["SL3" .. CLi]:GetRight()
        local ZeMHeight = ((ZeMTop - ZeMBottom) / 2) + ZeMTop
        local ZeMWidth = ((ZeMRight - ZeMLeft) / 2) + ZeMLeft
        for CLi2 = 1, 19 do
            local zsda = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetBottom())
            local zsda2 = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetRight() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft())

            if (ZeMHeight > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() and ZeMHeight < zsda) then
                if (ZeMWidth > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() and ZeMWidth < zsda2) then
                    zfrom = CLi
                    zto = CLi2
                    ZeBreak = 1
                end
            end
            if (ZeBreak == 1) then
                break
            end
        end
        if (ZeBreak == 1) then
            break
        end
    end

    for CLi = 1, zenr4 do
        local ZeMTop = APR.RoutePlan.Custompath["SPR3" .. CLi]:GetTop()
        local ZeMBottom = APR.RoutePlan.Custompath["SPR3" .. CLi]:GetBottom()
        local ZeMLeft = APR.RoutePlan.Custompath["SPR3" .. CLi]:GetLeft()
        local ZeMRight = APR.RoutePlan.Custompath["SPR3" .. CLi]:GetRight()
        local ZeMHeight = ((ZeMTop - ZeMBottom) / 2) + ZeMTop
        local ZeMWidth = ((ZeMRight - ZeMLeft) / 2) + ZeMLeft
        for CLi2 = 1, 19 do
            local zsda = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetBottom())
            local zsda2 = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetRight() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft())

            if (ZeMHeight > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() and ZeMHeight < zsda) then
                if (ZeMWidth > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() and ZeMWidth < zsda2) then
                    zfrom = CLi
                    zto = CLi2
                    ZeBreak = 1
                end
            end
            if (ZeBreak == 1) then
                break
            end
        end
        if (ZeBreak == 1) then
            break
        end
    end

    for CLi = 1, zenr5 do
        local ZeMTop = APR.RoutePlan.Custompath["EX3" .. CLi]:GetTop()
        local ZeMBottom = APR.RoutePlan.Custompath["EX3" .. CLi]:GetBottom()
        local ZeMLeft = APR.RoutePlan.Custompath["EX3" .. CLi]:GetLeft()
        local ZeMRight = APR.RoutePlan.Custompath["EX3" .. CLi]:GetRight()
        local ZeMHeight = ((ZeMTop - ZeMBottom) / 2) + ZeMTop
        local ZeMWidth = ((ZeMRight - ZeMLeft) / 2) + ZeMLeft
        for CLi2 = 1, 19 do
            local zsda = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetBottom())
            local zsda2 = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetRight() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft())

            if (ZeMHeight > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() and ZeMHeight < zsda) then
                if (ZeMWidth > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() and ZeMWidth < zsda2) then
                    zfrom = CLi
                    zto = CLi2
                    ZeBreak = 1
                end
            end
            if (ZeBreak == 1) then
                break
            end
        end
        if (ZeBreak == 1) then
            break
        end
    end

    for CLi = 1, zenr6 do
        local ZeMTop = APR.RoutePlan.Custompath["DF3" .. CLi]:GetTop()
        local ZeMBottom = APR.RoutePlan.Custompath["DF3" .. CLi]:GetBottom()
        local ZeMLeft = APR.RoutePlan.Custompath["DF3" .. CLi]:GetLeft()
        local ZeMRight = APR.RoutePlan.Custompath["DF3" .. CLi]:GetRight()
        local ZeMHeight = ((ZeMTop - ZeMBottom) / 2) + ZeMTop
        local ZeMWidth = ((ZeMRight - ZeMLeft) / 2) + ZeMLeft
        for CLi2 = 1, 19 do
            local zsda = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetBottom())
            local zsda2 = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetRight() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft())

            if (ZeMHeight > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() and ZeMHeight < zsda) then
                if (ZeMWidth > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() and ZeMWidth < zsda2) then
                    zfrom = CLi
                    zto = CLi2
                    ZeBreak = 1
                end
            end
            if (ZeBreak == 1) then
                break
            end
        end
        if (ZeBreak == 1) then
            break
        end
    end

    for CLi = 1, zenr7 do
        local ZeMTop = APR.RoutePlan.Custompath["MISC3" .. CLi]:GetTop()
        local ZeMBottom = APR.RoutePlan.Custompath["MISC3" .. CLi]:GetBottom()
        local ZeMLeft = APR.RoutePlan.Custompath["MISC3" .. CLi]:GetLeft()
        local ZeMRight = APR.RoutePlan.Custompath["MISC3" .. CLi]:GetRight()
        local ZeMHeight = ((ZeMTop - ZeMBottom) / 2) + ZeMTop
        local ZeMWidth = ((ZeMRight - ZeMLeft) / 2) + ZeMLeft
        for CLi2 = 1, 19 do
            local zsda = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetBottom())
            local zsda2 = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetRight() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft())

            if (ZeMHeight > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() and ZeMHeight < zsda) then
                if (ZeMWidth > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() and ZeMWidth < zsda2) then
                    zfrom = CLi
                    zto = CLi2
                    ZeBreak = 1
                end
            end
            if (ZeBreak == 1) then
                break
            end
        end
        if (ZeBreak == 1) then
            break
        end
    end

    for CLi = 1, zenr8 do
        local ZeMTop = APR.RoutePlan.Custompath["MISC23" .. CLi]:GetTop()
        local ZeMBottom = APR.RoutePlan.Custompath["MISC23" .. CLi]:GetBottom()
        local ZeMLeft = APR.RoutePlan.Custompath["MISC23" .. CLi]:GetLeft()
        local ZeMRight = APR.RoutePlan.Custompath["MISC23" .. CLi]:GetRight()
        local ZeMHeight = ((ZeMTop - ZeMBottom) / 2) + ZeMTop
        local ZeMWidth = ((ZeMRight - ZeMLeft) / 2) + ZeMLeft
        for CLi2 = 1, 19 do
            local zsda = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetBottom())
            local zsda2 = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() +
                (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetRight() - APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft())

            if (ZeMHeight > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetTop() and ZeMHeight < zsda) then
                if (ZeMWidth > APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]:GetLeft() and ZeMWidth < zsda2) then
                    zfrom = CLi
                    zto = CLi2
                    ZeBreak = 1
                end
            end
            if (ZeBreak == 1) then
                break
            end
        end
        if (ZeBreak == 1) then
            break
        end
    end

    if (zeActivz == 1 and zfrom and zto) then
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:GetText() ~= nil) then
            local zerpd = 20
            for CLi2z = 1, 19 do
                zerpd = zerpd - 1
                if (zerpd ~= 1 and zerpd > zto) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:SetText(APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd - 1]
                        ["FS"]
                        :GetText())
                end
                if (APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:GetText()) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Show()
                else
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Hide()
                end
            end
        end
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:SetText(APR.RoutePlan.Custompath["EK3" .. zfrom]["FS"]:GetText())
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]:Show()
    elseif (zeActivz == 2 and zfrom and zto) then
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:GetText() ~= nil) then
            local zerpd = 20
            for CLi2z = 1, 19 do
                zerpd = zerpd - 1
                if (zerpd ~= 1 and zerpd > zto) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:SetText(APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd - 1]
                        ["FS"]
                        :GetText())
                end
                if (APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:GetText()) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Show()
                else
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Hide()
                end
            end
        end
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:SetText(APR.RoutePlan.Custompath["KAL3" .. zfrom]["FS"]:GetText())
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]:Show()
    elseif (zeActivz == 3 and zfrom and zto) then
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:GetText() ~= nil) then
            local zerpd = 20
            for CLi2z = 1, 19 do
                zerpd = zerpd - 1
                if (zerpd ~= 1 and zerpd > zto) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:SetText(APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd - 1]
                        ["FS"]
                        :GetText())
                end
                if (APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:GetText()) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Show()
                else
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Hide()
                end
            end
        end
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:SetText(APR.RoutePlan.Custompath["SL3" .. zfrom]["FS"]:GetText())
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]:Show()
    elseif (zeActivz == 4 and zfrom and zto) then
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:GetText() ~= nil) then
            local zerpd = 20
            for CLi2z = 1, 19 do
                zerpd = zerpd - 1
                if (zerpd ~= 1 and zerpd > zto) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:SetText(APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd - 1]
                        ["FS"]
                        :GetText())
                end
                if (APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:GetText()) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Show()
                else
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Hide()
                end
            end
        end
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:SetText(APR.RoutePlan.Custompath["SPR3" .. zfrom]["FS"]:GetText())
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]:Show()
    elseif (zeActivz == 5 and zfrom and zto) then
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:GetText() ~= nil) then
            local zerpd = 20
            for CLi2z = 1, 19 do
                zerpd = zerpd - 1
                if (zerpd ~= 1 and zerpd > zto) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:SetText(APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd - 1]
                        ["FS"]
                        :GetText())
                end
                if (APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:GetText()) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Show()
                else
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Hide()
                end
            end
        end
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:SetText(APR.RoutePlan.Custompath["EX3" .. zfrom]["FS"]:GetText())
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]:Show()
    elseif (zeActivz == 6 and zfrom and zto) then
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:GetText() ~= nil) then
            local zerpd = 20
            for CLi2z = 1, 19 do
                zerpd = zerpd - 1
                if (zerpd ~= 1 and zerpd > zto) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:SetText(APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd - 1]
                        ["FS"]
                        :GetText())
                end
                if (APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:GetText()) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Show()
                else
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Hide()
                end
            end
        end
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:SetText(APR.RoutePlan.Custompath["DF3" .. zfrom]["FS"]:GetText())
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]:Show()
    elseif (zeActivz == 7 and zfrom and zto) then
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:GetText() ~= nil) then
            local zerpd = 20
            for CLi2z = 1, 19 do
                zerpd = zerpd - 1
                if (zerpd ~= 1 and zerpd > zto) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:SetText(APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd - 1]
                        ["FS"]
                        :GetText())
                end
                if (APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:GetText()) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Show()
                else
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Hide()
                end
            end
        end
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:SetText(APR.RoutePlan.Custompath["MISC3" .. zfrom]["FS"]:GetText())
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]:Show()
    elseif (zeActivz == 8 and zfrom and zto) then
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:GetText() ~= nil) then
            local zerpd = 20
            for CLi2z = 1, 19 do
                zerpd = zerpd - 1
                if (zerpd ~= 1 and zerpd > zto) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:SetText(APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd - 1]
                        ["FS"]
                        :GetText())
                end
                if (APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]["FS"]:GetText()) then
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Show()
                else
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zerpd]:Hide()
                end
            end
        end
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]["FS"]:SetText(APR.RoutePlan.Custompath["MISC23" .. zfrom]["FS"]:GetText())
        APR.RoutePlan.Custompath["Fxz2Custom" .. zto]:Show()
    end

    for CLi = 1, zenr do
        local zeTex = APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:GetText()
        local ZeMatch = 0
        for CLi2 = 1, 19 do
            if (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]["FS"]:GetText() == zeTex) then
                APR.RoutePlan.Custompath["EK3" .. CLi]:Hide()
                ZeMatch = 1
            end
        end
        if (ZeMatch == 0) then
            if (APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:GetText()]) then
                APR.RoutePlan.Custompath["EK3" .. CLi]:Hide()
                APR.FP.GoToZone = nil
                APR.ActiveMap = nil
            else
                APR.RoutePlan.Custompath["EK3" .. CLi]:Show()
            end
        end
    end

    for CLi = 1, zenr2 do
        local zeTex = APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:GetText()
        local ZeMatch = 0
        for CLi2 = 1, 19 do
            if (APR.RoutePlan.Custompath and APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2] and APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]["FS"] and APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]["FS"]:GetText() == zeTex) then
                APR.RoutePlan.Custompath["KAL3" .. CLi]:Hide()
                ZeMatch = 1
            end
        end
        if (ZeMatch == 0) then
            if (APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:GetText()]) then
                APR.RoutePlan.Custompath["KAL3" .. CLi]:Hide()
                APR.FP.GoToZone = nil
                APR.ActiveMap = nil
            else
                APR.RoutePlan.Custompath["KAL3" .. CLi]:Show()
            end
        end
    end

    for CLi = 1, zenr3 do
        local zeTex = APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:GetText()
        local ZeMatch = 0
        for CLi2 = 1, 19 do
            if (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]["FS"]:GetText() == zeTex) then
                APR.RoutePlan.Custompath["SL3" .. CLi]:Hide()
                ZeMatch = 1
            end
        end
        if (ZeMatch == 0) then
            if (APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:GetText()]) then
                APR.RoutePlan.Custompath["SL3" .. CLi]:Hide()
                APR.FP.GoToZone = nil
                APR.ActiveMap = nil
            else
                APR.RoutePlan.Custompath["SL3" .. CLi]:Show()
            end
        end
        if (APR_Custom[APR.Username .. "-" .. APR.Realm] and APR_Custom[APR.Username .. "-" .. APR.Realm][CLi]) then
            local zew = APR.QuestStepListListingZone[APR_Custom[APR.Username .. "-" .. APR.Realm][CLi]]
            if (APR["EasternKingdom"] and APR["EasternKingdom"][zew] and C_AddOns.IsAddOnLoaded("APR-Vanilla") == false) then
                local loaded, reason = C_AddOns.LoadAddOn("APR-Vanilla")
                if not loaded then
                    if reason == "DISABLED" then
                        print("APR: APR-Vanilla " .. L["DISABLED_ADDON_LIST"])
                    end
                end
            end
            if (APR["Kalimdor"] and APR["Kalimdor"][zew] and C_AddOns.IsAddOnLoaded("APR-Vanilla") == false) then
                local loaded, reason = C_AddOns.LoadAddOn("APR-Vanilla")
                if (not loaded) then
                    if (reason == "DISABLED") then
                        print("APR: APR-Vanilla " .. L["DISABLED_ADDON_LIST"])
                    end
                end
            end
            if (APR["BattleForAzeroth"] and APR["BattleForAzeroth"][zew] and C_AddOns.IsAddOnLoaded("APR-BattleForAzeroth") == false) then
                local loaded, reason = C_AddOns.LoadAddOn("APR-BattleForAzeroth")
                if (not loaded) then
                    if (reason == "DISABLED") then
                        print("APR: APR-BattleForAzeroth " .. L["DISABLED_ADDON_LIST"])
                    end
                end
            end
            if (APR["Legion"] and APR["Legion"][zew] and C_AddOns.IsAddOnLoaded("APR-Legion") == false) then
                local loaded, reason = C_AddOns.LoadAddOn("APR-Legion")
                if (not loaded) then
                    if (reason == "DISABLED") then
                        print("APR: APR - Legion " .. L["DISABLED_ADDON_LIST"])
                    end
                end
            end
            if (APR["Shadowlands"] and APR["Shadowlands"][zew] and C_AddOns.IsAddOnLoaded("APR-Shadowlands") == false) then
                local loaded, reason = C_AddOns.LoadAddOn("APR-Shadowlands")
                if (not loaded) then
                    if (reason == "DISABLED") then
                        print("APR: APR - Shadowlands " .. L["DISABLED_ADDON_LIST"])
                    end
                end
            end
        end
    end

    for CLi = 1, zenr4 do
        local zeTex = APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:GetText()
        local ZeMatch = 0
        for CLi2 = 1, 19 do
            if (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]["FS"]:GetText() == zeTex) then
                APR.RoutePlan.Custompath["SPR3" .. CLi]:Hide()
                ZeMatch = 1
            end
        end
        if (ZeMatch == 0) then
            if (APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:GetText()]) then
                APR.RoutePlan.Custompath["SPR3" .. CLi]:Hide()
                APR.FP.GoToZone = nil
                APR.ActiveMap = nil
            else
                APR.RoutePlan.Custompath["SPR3" .. CLi]:Show()
            end
        end
        if (APR_Custom[APR.Username .. "-" .. APR.Realm] and APR_Custom[APR.Username .. "-" .. APR.Realm][CLi]) then
            local zew = APR.QuestStepListListingZone[APR_Custom[APR.Username .. "-" .. APR.Realm][CLi]]
            if (APR["ShadowlandsDB"] and APR["ShadowlandsDB"][zew] and C_AddOns.IsAddOnLoaded("APR-Shadowlands") == false) then
                local loaded, reason = C_AddOns.LoadAddOn("APR-Shadowlands")
                if (not loaded) then
                    if (reason == "DISABLED") then
                        print("APR: APR - Shadowlands " .. L["DISABLED_ADDON_LIST"])
                    end
                end
            end
        end
    end

    for CLi = 1, zenr5 do
        local zeTex = APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:GetText()
        local ZeMatch = 0
        for CLi2 = 1, 19 do
            if (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]["FS"]:GetText() == zeTex) then
                APR.RoutePlan.Custompath["EX3" .. CLi]:Hide()
                ZeMatch = 1
            end
        end
        if (ZeMatch == 0) then
            if (APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:GetText()]) then
                APR.RoutePlan.Custompath["EX3" .. CLi]:Hide()
                APR.FP.GoToZone = nil
                APR.ActiveMap = nil
            else
                APR.RoutePlan.Custompath["EX3" .. CLi]:Show()
            end
        end
    end

    for CLi = 1, zenr6 do
        local zeTex = APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:GetText()
        local ZeMatch = 0
        for CLi2 = 1, 19 do
            if (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]["FS"]:GetText() == zeTex) then
                APR.RoutePlan.Custompath["DF3" .. CLi]:Hide()
                ZeMatch = 1
            end
        end
        if (ZeMatch == 0) then
            if (APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:GetText()]) then
                APR.RoutePlan.Custompath["DF3" .. CLi]:Hide()
                APR.FP.GoToZone = nil
                APR.ActiveMap = nil
            else
                APR.RoutePlan.Custompath["DF3" .. CLi]:Show()
            end
        end
    end

    for CLi = 1, zenr7 do
        local zeTex = APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:GetText()
        local ZeMatch = 0
        for CLi2 = 1, 19 do
            if (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]["FS"]:GetText() == zeTex) then
                APR.RoutePlan.Custompath["MISC3" .. CLi]:Hide()
                ZeMatch = 1
            end
        end
        if (ZeMatch == 0) then
            if (APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:GetText()]) then
                APR.RoutePlan.Custompath["MISC3" .. CLi]:Hide()
                APR.FP.GoToZone = nil
                APR.ActiveMap = nil
            else
                APR.RoutePlan.Custompath["MISC3" .. CLi]:Show()
            end
        end
    end

    for CLi = 1, zenr8 do
        local zeTex = APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:GetText()
        local ZeMatch = 0
        for CLi2 = 1, 19 do
            if (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi2]["FS"]:GetText() == zeTex) then
                APR.RoutePlan.Custompath["MISC23" .. CLi]:Hide()
                ZeMatch = 1
            end
        end
        if (ZeMatch == 0) then
            if (APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:GetText()]) then
                APR.RoutePlan.Custompath["MISC23" .. CLi]:Hide()
                APR.FP.GoToZone = nil
                APR.ActiveMap = nil
            else
                APR.RoutePlan.Custompath["MISC23" .. CLi]:Show()
            end
        end
    end
end

function APR.CheckCustomEmpty()
    if (APR.settings.profile.debug) then
        print("Function: APR.CheckCustomEmpty()")
    end
    local zeemp = 0
    for CLi = 1, 19 do
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:IsVisible()) then
            zeemp = 1
        end
    end
    if (zeemp == 0) then
        APR.FP.GoToZone = nil
        APR.ActiveMap = nil
    end
end

--Check current position for route plan
function APR.RoutePlanCheckPos()
    if (APR.settings.profile.debug) then
        print("Function: APR.RoutePlanCheckPos()")
    end
    local zenr = APR.NumbRoutePlan("EasternKingdom")
    local ZeHide = {}
    for CLi = 1, 19 do
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:GetText() and APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:GetText() ~= "") then
            ZeHide[APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:GetText()] = 1
        end
    end
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["EK3" .. CLi]:ClearAllPoints()
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.EKT, "TOPRIGHT", -10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.Custompath.EKT, "BOTTOMRIGHT", 10,
            -(20 * CLi) + 10 -
            10)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath.EKT, "BOTTOMLEFT", 10,
            -(20 * CLi) + 10 - 10)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.EKT, "BOTTOMRIGHT", -10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath.EKT, "TOPLEFT", 10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetHeight(20)
        if (ZeHide and ZeHide[APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:GetText()]) then
            APR.RoutePlan.Custompath["EK3" .. CLi]:Hide()
        end
    end
    local zenr = APR.NumbRoutePlan("Kalimdor")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["KAL3" .. CLi]:ClearAllPoints()
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.KALT, "TOPRIGHT", -10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.Custompath.KALT, "BOTTOMRIGHT", 10,
            -(20 * CLi) + 10 -
            10)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath.KALT, "BOTTOMLEFT", 10,
            -(20 * CLi) + 10 -
            10)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.KALT, "BOTTOMRIGHT", -10,
            -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath.KALT, "TOPLEFT", 10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetHeight(20)
        if (ZeHide and ZeHide[APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:GetText()]) then
            APR.RoutePlan.Custompath["KAL3" .. CLi]:Hide()
        end
    end
    local zenr = APR.NumbRoutePlan("Shadowlands")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["SL3" .. CLi]:ClearAllPoints()
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.SLT, "TOPRIGHT", -10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.Custompath.SLT, "BOTTOMRIGHT", 10,
            -(20 * CLi) + 10 -
            10)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath.SLT, "BOTTOMLEFT", 10,
            -(20 * CLi) + 10 - 10)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.SLT, "BOTTOMRIGHT", -10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath.SLT, "TOPLEFT", 10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetHeight(20)
        if (ZeHide and ZeHide[APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:GetText()]) then
            APR.RoutePlan.Custompath["SL3" .. CLi]:Hide()
        end
    end
    local zenr = APR.NumbRoutePlan("Extra")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["EX3" .. CLi]:ClearAllPoints()
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.EXTT, "TOPRIGHT", -10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.Custompath.EXTT, "BOTTOMRIGHT", 10,
            -(20 * CLi) + 10 -
            10)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath.EXTT, "BOTTOMLEFT", 10,
            -(20 * CLi) + 10 -
            10)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.EXTT, "BOTTOMRIGHT", -10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath.EXTT, "TOPLEFT", 10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetHeight(20)
        if (ZeHide and ZeHide[APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:GetText()]) then
            APR.RoutePlan.Custompath["EX3" .. CLi]:Hide()
        end
    end
    local zenr = APR.NumbRoutePlan("MISC 1")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["MISC3" .. CLi]:ClearAllPoints()
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.MISC1T, "TOPRIGHT", -10,
            -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.Custompath.MISC1T, "BOTTOMRIGHT", 10,
            -(20 * CLi) + 10 - 10)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath.MISC1T, "BOTTOMLEFT", 10,
            -(20 * CLi) + 10 -
            10)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.MISC1T, "BOTTOMRIGHT", -10,
            -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath.MISC1T, "TOPLEFT", 10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetHeight(20)
        if (ZeHide and ZeHide[APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:GetText()]) then
            APR.RoutePlan.Custompath["MISC3" .. CLi]:Hide()
        end
    end
    local zenr = APR.NumbRoutePlan("MISC 2")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["MISC23" .. CLi]:ClearAllPoints()
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.MISC2T, "TOPRIGHT", -10,
            -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.Custompath.MISC2T, "BOTTOMRIGHT", 10,
            -(20 * CLi) + 10 - 10)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath.MISC2T, "BOTTOMLEFT", 10,
            -(20 * CLi) +
            10 - 10)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.MISC2T, "BOTTOMRIGHT", -10,
            -(20 * CLi) -
            10)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath.MISC2T, "TOPLEFT", 10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetHeight(20)
        if (ZeHide and ZeHide[APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:GetText()]) then
            APR.RoutePlan.Custompath["MISC23" .. CLi]:Hide()
        end
    end
    local zenr = APR.NumbRoutePlan("Dragonflight")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["DF3" .. CLi]:ClearAllPoints()
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.DFT, "TOPRIGHT", -10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.Custompath.DFT, "BOTTOMRIGHT", 10,
            -(20 * CLi) + 10 -
            10)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath.DFT, "BOTTOMLEFT", 10,
            -(20 * CLi) + 10 - 10)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.DFT, "BOTTOMRIGHT", -10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath.DFT, "TOPLEFT", 10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetHeight(20)
        if (ZeHide and ZeHide[APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:GetText()]) then
            APR.RoutePlan.Custompath["DF3" .. CLi]:Hide()
        end
    end
    local zenr = APR.NumbRoutePlan("SpeedRun")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["SPR3" .. CLi]:ClearAllPoints()
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.F25x3, "TOPRIGHT", -10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.Custompath.F25x3, "BOTTOMRIGHT", 10,
            -(20 * CLi) + 10 -
            10)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath.F25x3, "BOTTOMLEFT", 10,
            -(20 * CLi) + 10 -
            10)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.F25x3, "BOTTOMRIGHT", -10,
            -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath.F25x3, "TOPLEFT", 10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetHeight(20)
        if (ZeHide and ZeHide[APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:GetText()]) then
            APR.RoutePlan.Custompath["SPR3" .. CLi]:Hide()
        end
    end
    APR_Custom[APR.Username .. "-" .. APR.Realm] = nil
    APR_Custom[APR.Username .. "-" .. APR.Realm] = {}

    for CLi = 1, 19 do
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:ClearAllPoints()
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.CPT, "TOPRIGHT", -10,
            -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.Custompath.CPT, "BOTTOMRIGHT", 10,
            -(20 * CLi) + 10 - 10)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath.CPT, "BOTTOMLEFT", 10,
            -(20 * CLi) + 10 - 10)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath.CPT, "BOTTOMRIGHT", -10,
            -(20 * CLi) -
            10)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath.CPT, "TOPLEFT", 10, -(20 * CLi) - 10)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetHeight(20)
        if (APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:GetText() ~= "") then
            APR_Custom[APR.Username .. "-" .. APR.Realm][CLi] = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:GetText()
        end
    end
    APR.BookingList["UpdateMapId"] = true
end

function APR.NumbRoutePlan(Continz)
    local zenr = 0

    if (Continz == "EasternKingdom") then
        if (APR.QuestStepListListingStartAreas["EasternKingdom"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListingStartAreas["EasternKingdom"]) do
                zenr = zenr + 1
            end
        end
        if (APR.QuestStepListListing["EasternKingdom"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListing["EasternKingdom"]) do
                zenr = zenr + 1
            end
        end
    elseif (Continz == "Kalimdor") then
        if (APR.QuestStepListListingStartAreas["Kalimdor"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListingStartAreas["Kalimdor"]) do
                zenr = zenr + 1
            end
        end
        if (APR.QuestStepListListing["Kalimdor"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListing["Kalimdor"]) do
                zenr = zenr + 1
            end
        end
    elseif (Continz == "Extra") then
        if (APR.QuestStepListListing["Extra"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListing["Extra"]) do
                zenr = zenr + 1
            end
        end
    elseif (Continz == "MISC 1") then
        if (APR.QuestStepListListing["MISC 1"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListing["MISC 1"]) do
                zenr = zenr + 1
            end
        end
    elseif (Continz == "MISC 2") then
        if (APR.QuestStepListListing["MISC 2"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListing["MISC 2"]) do
                zenr = zenr + 1
            end
        end
    elseif (Continz == "Dragonflight") then
        if (APR.QuestStepListListing["Dragonflight"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListing["Dragonflight"]) do
                zenr = zenr + 1
            end
        end
    elseif (Continz == "BrokenIsles") then
        if (APR.QuestStepListListingStartAreas["BrokenIsles"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListingStartAreas["BrokenIsles"]) do
                zenr = zenr + 1
            end
        end
    elseif (Continz == "SpeedRun") then
        if (APR.QuestStepListListing["SpeedRun"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListing["SpeedRun"]) do
                zenr = zenr + 1
            end
        end
    elseif (Continz == "Shadowlands") then
        if (APR.QuestStepListListing["Shadowlands"]) then
            for APR_index2, APR_value2 in pairs(APR.QuestStepListListing["Shadowlands"]) do
                zenr = zenr + 1
            end
        end
    end
    return zenr
end

APR.CoreEventFrame = CreateFrame("Frame")
APR.CoreEventFrame:RegisterEvent("ADDON_LOADED")
APR.CoreEventFrame:RegisterEvent("PLAYER_LEVEL_UP")
APR.CoreEventFrame:SetScript("OnEvent", function(self, event, ...)
    if APR.settings.profile.showEvent then
        print("EVENT: Core - ", event)
    end
    if (event == "ADDON_LOADED") then
        local arg1, arg2, arg3, arg4, arg5 = ...;
        if (arg1 ~= "APR-Core") then
            return
        end

        if (not APRData[APR.Realm][APR.Username]["BonusSkips"]) then
            APRData[APR.Realm][APR.Username]["BonusSkips"] = {}
        end

        APR_LoadInTimer = APR.CoreEventFrame:CreateAnimationGroup()
        APR_LoadInTimer.anim = APR_LoadInTimer:CreateAnimation()
        APR_LoadInTimer.anim:SetDuration(2)
        APR_LoadInTimer:SetLooping("REPEAT")
        APR_LoadInTimer:SetScript("OnLoop", function(self, event, ...)
            if (CoreLoadin) then
                if (not APR_Transport) then
                    APR_Transport = {}
                end
                if (not APR_Custom) then
                    APR_Custom = {}
                end
                if (not APR_TaxiTimers) then
                    APR_TaxiTimers = {}
                end
                if (not APR_Custom[APR.Username .. "-" .. APR.Realm]) then
                    APR_Custom[APR.Username .. "-" .. APR.Realm] = {}
                end
                if (not APR_ZoneComplete) then
                    APR_ZoneComplete = {}
                end
                if (not APR_ZoneComplete[APR.Username .. "-" .. APR.Realm]) then
                    APR_ZoneComplete[APR.Username .. "-" .. APR.Realm] = {}
                end
                if (not APR_Transport["FPs"]) then
                    APR_Transport["FPs"] = {}
                end
                if (not APR_Transport["FPs"][APR.Faction]) then
                    APR_Transport["FPs"][APR.Faction] = {}
                end
                if (APR:GetContinent() and not APR_Transport["FPs"][APR.Faction][APR:GetContinent()]) then
                    APR_Transport["FPs"][APR.Faction][APR:GetContinent()] = {}
                end
                if (APR:GetContinent() and not APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Username .. "-" .. APR.Realm]) then
                    APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Username .. "-" .. APR.Realm] = {}
                end
                if (APR:GetContinent() and not APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Username .. "-" .. APR.Realm]["Conts"]) then
                    APR_Transport["FPs"][APR.Faction][APR:GetContinent()][APR.Username .. "-" .. APR.Realm]["Conts"] = {}
                end

                APR.BookingList["UpdateMapId"] = true
                APR.BookingList["UpdateQuest"] = true
                APR.BookingList["PrintQStep"] = true
                APR.RoutePlanLoadIn()
                if (APRData[APR.Realm][APR.Username].FirstLoad) then
                    -- APR.LoadInOptionFrame:Show()
                    APRData[APR.Realm][APR.Username].FirstLoad = false
                else
                    -- APR.LoadInOptionFrame:Hide()
                end
                print("APR " .. L["LOADED"])
                APR_LoadInTimer:Stop()
                C_Timer.After(4, APR_BookingUpdateMapId)
                C_Timer.After(5, UpdateQuestAndStep)
                --APR.FP.ToyFPs()
                local CQIDs = C_QuestLog.GetAllCompletedQuestIDs()
                APRData[APR.Realm][APR.Username]["QuestCounter"] = getn(CQIDs)
                APRData[APR.Realm][APR.Username]["QuestCounter2"] = APRData[APR.Realm][APR.Username]["QuestCounter"]
                APR_QidsTimer:Play()
                APR_LoadInTimer:Stop()
            end
        end)
        APR_LoadInTimer:Play()

        APR_QidsTimer = APR.CoreEventFrame:CreateAnimationGroup()
        APR_QidsTimer.anim = APR_QidsTimer:CreateAnimation()
        APR_QidsTimer.anim:SetDuration(1)
        APR_QidsTimer:SetLooping("REPEAT")
        APR_QidsTimer:SetScript("OnLoop", function(self, event, ...)
            if (APRData[APR.Realm][APR.Username]["QuestCounter2"] ~= APRData[APR.Realm][APR.Username]["QuestCounter"]) then
                APR.BookingList["UpdateStep"] = true
                APRData[APR.Realm][APR.Username]["QuestCounter"] = APRData[APR.Realm][APR.Username]["QuestCounter2"]
            end
        end)

        if (not APRData[APR.Realm][APR.Username]["LoaPick"]) then
            APRData[APR.Realm][APR.Username]["LoaPick"] = 0
        end
        if (not APRData[APR.Realm][APR.Username]["routeChoiceIndex"]) then
            APRData[APR.Realm][APR.Username]["routeChoiceIndex"] = 0
        end
        if (not APRData[APR.Realm][APR.Username]["WantedQuestList"]) then
            APRData[APR.Realm][APR.Username]["WantedQuestList"] = {}
        end

        -- TODO ARROW REWORK
        APR.ArrowFrame:SetScale(APR.settings.profile.arrowScale)
        APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.arrowleft,
            APR.settings.profile.arrowtop)

        APR.BookingList["UpdateStep"] = true
        CoreLoadin = true
    end
    if (event == "PLAYER_LEVEL_UP") then
        if not IsTableEmpty(APR_Custom[APR.Username .. "-" .. APR.Realm]) then
            if APR.Level == 50 then
                APR.questionDialog:CreateQuestionPopup(L["RESET_ROUTE_FOR_SL"], function()
                    wipe(APR_Custom[APR.Username .. "-" .. APR.Realm])
                    APR.routeconfig:setAutoPathForRoute(APRData[APR.Realm][APR.Username]["routeChoiceIndex"])
                end)
            elseif APR.Level == 60 then
                APR.questionDialog:CreateQuestionPopup(L["RESET_ROUTE_FOR_DF"], function()
                    wipe(APR_Custom[APR.Username .. "-" .. APR.Realm])
                    APR.routeconfig:setAutoPathForRoute(APRData[APR.Realm][APR.Username]["routeChoiceIndex"])
                end)
            end
        end
    end
end)
