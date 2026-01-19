local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR = {}
APR = _G.LibStub("AceAddon-3.0"):NewAddon(APR, "APR", "AceEvent-3.0")

-- Character
APR.Realm = string.gsub(GetRealmName(), " ", "")
APR.Faction = UnitFactionGroup("player") -- "Alliance", "Horde", "Neutral" or nil
APR.Level = UnitLevel("player")
APR.RaceLocale, APR.Race, APR.RaceID = UnitRace("player")
APR.Gender = UnitSex("player")
APR.MaxLevelChromie = 70
APR.MinBoostLvl = 60
APR.MaxBagSlots = 4
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

APR.HEXColor = {
    white = "ffffff",
    black = "000000",
    red = "ff3333",
    green = "00ff00"
}

-- Quest
APR.RouteList = {}
APR.RouteQuestStepList = {}
APR.MissingQuests = {}

function APR:OnInitialize()
    local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata

    -- Secret helpers + identity must be ready before using self.PlayerID.
    self:InitSecretUtils()
    self:InitIdentity()

    -- Init on TOC
    self.title = GetAddOnMetadata("APR", "Title")
    self.version = GetAddOnMetadata("APR", "Version")
    self.github = GetAddOnMetadata("APR", "X-Github")
    self.discord = GetAddOnMetadata("APR", "X-Discord")
    self.interfaceVersion = select(4, GetBuildInfo())
    -- // TODO Remove on release
    self.isMidnightPrePatchVersion = (tonumber(self.interfaceVersion) or 0) == 120000
    self.isBetaMidnightVersion = (tonumber(self.interfaceVersion) or 0) >= 120001

    self.ActiveQuests = {}
    self.IsInRouteZone = false
    self.MaxLevel = self.isBetaMidnightVersion and 90 or 80

    -- APR INIT NEW SETTING
    self:Love()
    self.settings:InitializeBlizOptions()
    self:ApplyLoveColors()

    -- APR Saved Data
    APRData = APRData or {}
    APRData.NPCList = APRData.NPCList or {}
    APRData.CustomRoute = APRData.CustomRoute or {}
    APRData[self.PlayerID] = APRData[self.PlayerID] or {}
    APRData[self.PlayerID].FirstLoad = APRData[self.PlayerID].FirstLoad == nil and true or
        APRData[self.PlayerID].FirstLoad
    APRData[self.PlayerID].BonusSkips = APRData[self.PlayerID].BonusSkips or {}
    APRData[self.PlayerID].WantedQuestList = APRData[self.PlayerID].WantedQuestList or {}

    APRCustomPath = APRCustomPath or {}
    APRTaxiNodes = APRTaxiNodes or {}
    APRTaxiNodesTimer = APRTaxiNodesTimer or {}
    APRZoneCompleted = APRZoneCompleted or {}
    APRScenarioMapIDCompleted = APRScenarioMapIDCompleted or {}
    APRScenarioCompleted = APRScenarioCompleted or {}
    APRItemLooted = APRItemLooted or {}

    APRTaxiNodes[self.PlayerID] = APRTaxiNodes[self.PlayerID] or {}
    APRCustomPath[self.PlayerID] = APRCustomPath[self.PlayerID] or {}
    APRZoneCompleted[self.PlayerID] = APRZoneCompleted[self.PlayerID] or {}
    APRScenarioMapIDCompleted[self.PlayerID] = APRScenarioMapIDCompleted[self.PlayerID] or {}
    APRScenarioCompleted[self.PlayerID] = APRScenarioCompleted[self.PlayerID] or {}
    APRItemLooted[self.PlayerID] = APRItemLooted[self.PlayerID] or {}

    APRGossipValidated = APRGossipValidated or {}
    APRGossipValidated[self.PlayerID] = APRGossipValidated[self.PlayerID] or {}

    -- Init current step frame
    self.currentStep:CurrentStepFrameOnInit()

    --Init Party frame
    self.party:PartyFrameOnInit()

    --Init AFK frame
    self.AFK:AFKFrameOnInit()

    -- Init Quest Order List frame
    self.questOrderList:QuestOrderListFrameOnInit()

    -- Init Map/Minimap lines & Icons
    self.map:OnInit()

    -- Init coordinate frame for dev
    self.coordinate:OnInit()

    -- Init route selection frame
    self.RouteSelection:RouteSelectionOnInit()

    -- Init Changelog frame
    self.changelog:OnInit()

    -- Init heirloom frame
    self.heirloom:HeirloomOnInit()

    -- Init Buff frame
    self.Buff:BuffFrameOnInit()

    -- APR Global Variables, UI oriented
    BINDING_HEADER_APR = self.title -- Header text for APR's main frame
    _G["BINDING_NAME_" .. "CLICK APR_ItemButton:LeftButton"] = L["USE_QUEST_ITEM"]

    -- Register tot party frame
    C_ChatInfo.RegisterAddonMessagePrefix("APRPartyRequest")
    C_ChatInfo.RegisterAddonMessagePrefix("APRPartyData")
    C_ChatInfo.RegisterAddonMessagePrefix("APRPartyDelete")

    -- Load saved custom routes
    self:LoadCustomRoutes()

    self.Arrow:Init()

    -- Register events
    self.event:MyRegisterEvent()
end

-- Secret/taint helpers (12.0.0+). Attached during OnInitialize.
function APR:InitSecretUtils()
    if _G.APRSecret and _G.APRSecret.Attach then
        _G.APRSecret:Attach(self)
    else
        self.Secret = {}
    end
end

function APR:InitIdentity()
    local userId = (self.SafeUnitGUID and self:SafeUnitGUID("player", "Unknown"))
    local username = (self.SafeUnitName and self:SafeUnitName("player", "Unknown"))
    self.UserID = userId
    self.Username = username
    if self.SafeConcat then
        self.PlayerID = self:SafeConcat(userId, username, "-", userId)
    else
        self.PlayerID = (username and userId) and (username .. "-" .. userId) or userId
    end

    if self.SafeUnitClass then
        local classLocal, className, classId = self:SafeUnitClass("player")
        if classLocal and className and classId then
            self.ClassLocalName, self.ClassName, self.ClassId = classLocal, className, classId
        end
    end
end
