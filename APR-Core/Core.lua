local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR = {}
APR = _G.LibStub("AceAddon-3.0"):NewAddon(APR, "APR", "AceEvent-3.0")

-- Character
APR.UserID = UnitGUID("player")
APR.Username = UnitName("player")
APR.Realm = string.gsub(GetRealmName(), " ", "")
APR.Faction = UnitFactionGroup("player") -- "Alliance", "Horde", "Neutral" or nil
APR.Level = UnitLevel("player")
APR.RaceLocale, APR.Race, APR.RaceID = UnitRace("player")
APR.ClassLocalName, APR.ClassName, APR.ClassId = UnitClass("player")
APR.Gender = UnitSex("player")
APR.MaxLevel = 70
APR.MaxLevelChromie = 60
APR.MinBoostLvl = 60
APR.PlayerID = APR.Username .. "-" .. APR.UserID
APR.Color = {
    white = { 1, 1, 1 },
    black = { 0, 0, 0 },
    red = { 1, 0, 0 },
    yellow = { 1, 1, 0 },
    gold = { 1, 209 / 255, 0, 1 },
    green = { 0, 1, 0 },
    lightGreen = { 80 / 255, 200 / 255, 120 / 255, 0.8 },
    blue = { 0, 87 / 255, 183 / 255 },
    pink = { 1, 87 / 255, 183 / 255 },
    darkblue = { 0, 0.5, 0.5 },
    gray = { 105 / 255, 105 / 255, 105 / 255 },
    grayAlpha = { 105 / 255, 105 / 255, 105 / 255, 0.4 },
    midGray = { 0.5, 0.5, 0.5 },
    darkGray = { 0.2, 0.2, 0.2 },
    defaultBackdrop = { 0, 0, 0, 0.75 },
    defaultLightBackdrop = { 0, 0, 0, 0.4 }
}
-- APR.Season = C_Seasons and C_Seasons.HasActiveSeason() and C_Seasons.GetActiveSeason() // For classic


-- Quest
APR.RouteList = {}
APR.RouteQuestStepList = {}

function APR:OnInitialize()
    local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata

    -- Init on TOC
    APR.title = GetAddOnMetadata("APR", "Title")
    APR.version = GetAddOnMetadata("APR", "Version")
    APR.github = GetAddOnMetadata("APR", "X-Github")
    APR.discord = GetAddOnMetadata("APR", "X-Discord")
    APR.interfaceVersion = select(4, GetBuildInfo())

    APR.ActiveQuests = {}
    APR.IsInRouteZone = false

    -- BookingList
    APR.BookingList = {}
    APR.InCombat = false
    APR.BookUpdAfterCombat = false

    -- APR INIT NEW SETTING
    APR:Love()
    APR.settings:InitializeBlizOptions()

    -- APR Saved Data
    APRData = APRData or {}
    APRData.NPCList = APRData.NPCList or {}
    APRData[APR.PlayerID] = APRData[APR.PlayerID] or {}
    APRData[APR.PlayerID].FirstLoad = APRData[APR.PlayerID].FirstLoad == nil and true or
        APRData[APR.PlayerID].FirstLoad

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

    -- Init route selection frame
    APR.RouteSelection:RouteSelectionOnInit()

    -- Init Changelog frame
    APR.changelog:OnInit()

    -- Init heirloom frame
    APR.heirloom:HeirloomOnInit()

    -- Init Buff frame
    APR.Buff:BuffFrameOnInit()

    -- APR Global Variables, UI oriented
    BINDING_HEADER_APR = APR.title -- Header text for APR's main frame
    _G["BINDING_NAME_" .. "CLICK APRItemButton:LeftButton"] = L["USE_QUEST_ITEM"]

    -- Register tot party frame
    C_ChatInfo.RegisterAddonMessagePrefix("APRPartyData")
    C_ChatInfo.RegisterAddonMessagePrefix("APRPartyDelete")
end

APR.CoreEventFrame = CreateFrame("Frame")
APR.CoreEventFrame:RegisterEvent("ADDON_LOADED")
APR.CoreEventFrame:SetScript("OnEvent", function(self, event, ...)
    if APR.settings.profile.showEvent then
        print("EVENT: Core - ", event)
    end
    if (event == "ADDON_LOADED") then
        local arg1, arg2, arg3, arg4, arg5 = ...;
        if (arg1 ~= "APR-Core") then
            return
        end

        if (not APRData[APR.PlayerID]["BonusSkips"]) then
            APRData[APR.PlayerID]["BonusSkips"] = {}
        end

        if (not APRData[APR.PlayerID]["WantedQuestList"]) then
            APRData[APR.PlayerID]["WantedQuestList"] = {}
        end

        APR_LoadInTimer = APR.CoreEventFrame:CreateAnimationGroup()
        APR_LoadInTimer.anim = APR_LoadInTimer:CreateAnimation()
        APR_LoadInTimer.anim:SetDuration(2)
        APR_LoadInTimer:SetLooping("NONE")
        APR_LoadInTimer:SetScript("OnFinished", function(self, event, ...)
            if (not APRTaxiNodes) then
                APRTaxiNodes = {}
            end
            if (not APRTaxiNodes[APR.PlayerID]) then
                APRTaxiNodes[APR.PlayerID] = {}
            end

            if (not APRTaxiNodesTimer) then
                APRTaxiNodesTimer = {}
            end

            if (not APRCustomPath) then
                APRCustomPath = {}
            end
            if (not APRCustomPath[APR.PlayerID]) then
                APRCustomPath[APR.PlayerID] = {}
            end
            if (not APRZoneCompleted) then
                APRZoneCompleted = {}
            end
            if (not APRZoneCompleted[APR.PlayerID]) then
                APRZoneCompleted[APR.PlayerID] = {}
            end

            APR.BookingList["UpdateMapId"] = true
            APR.BookingList["UpdateQuest"] = true

            APR.RouteSelection:RefreshFrameAnchor()
            local CQIDs = C_QuestLog.GetAllCompletedQuestIDs()
            APRData[APR.PlayerID]["QuestCounter"] = getn(CQIDs)
            APRData[APR.PlayerID]["QuestCounter2"] = APRData[APR.PlayerID]["QuestCounter"]
            APR_QidsTimer:Play()
            APR:PrintInfo("APR " .. L["LOADED"])
            APR_LoadInTimer:Stop()
            APR.heirloom:RefreshFrameAnchor()
        end)
        APR_LoadInTimer:Play()

        APR_QidsTimer = APR.CoreEventFrame:CreateAnimationGroup()
        APR_QidsTimer.anim = APR_QidsTimer:CreateAnimation()
        APR_QidsTimer.anim:SetDuration(1)
        APR_QidsTimer:SetLooping("REPEAT")
        APR_QidsTimer:SetScript("OnLoop", function(self, event, ...)
            if (APRData[APR.PlayerID]["QuestCounter2"] ~= APRData[APR.PlayerID]["QuestCounter"]) then
                APR.BookingList["UpdateStep"] = true
                APRData[APR.PlayerID]["QuestCounter"] = APRData[APR.PlayerID]["QuestCounter2"]
            end
        end)

        -- //TODO ARROW REWORK
        APR.ArrowFrame:SetScale(APR.settings.profile.arrowScale)
        APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.arrowleft,
            APR.settings.profile.arrowtop)
        APR.BookingList["UpdateStep"] = true
    end
end)
