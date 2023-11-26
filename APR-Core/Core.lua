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

function APR.CheckCustomEmpty() -- TODO: Check that
    if (APR.settings.profile.debug) then
        print("Function: APR.CheckCustomEmpty()")
    end
    if not next(APRCustomPath[APR.Username .. "-" .. APR.Realm]) then
        APR.FP.GoToZone = nil
        APR.ActiveMap = nil
    end
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
                if (not APRCustomPath) then
                    APRCustomPath = {}
                end
                if (not APR_TaxiTimers) then
                    APR_TaxiTimers = {}
                end
                if (not APRCustomPath[APR.Username .. "-" .. APR.Realm]) then
                    APRCustomPath[APR.Username .. "-" .. APR.Realm] = {}
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
        local arg1, _ = ...;
        APR.Level = arg1
        if not IsTableEmpty(APRCustomPath[APR.Username .. "-" .. APR.Realm]) then
            if APR.Level == 50 then
                APR.questionDialog:CreateQuestionPopup(L["RESET_ROUTE_FOR_SL"], function()
                    APRCustomPath[APR.Username .. "-" .. APR.Realm] = {}
                    APR.routeconfig:GetSLPrefab()
                end)
            elseif APR.Level == 60 then
                APR.questionDialog:CreateQuestionPopup(L["RESET_ROUTE_FOR_DF"], function()
                    APRCustomPath[APR.Username .. "-" .. APR.Realm] = {}
                    APR.routeconfig:GetDFPrefab()
                end)
            end
        end
    end
end)
