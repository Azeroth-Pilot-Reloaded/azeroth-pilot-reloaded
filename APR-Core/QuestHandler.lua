local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")


local APR_ArrowUpdateNr = 0
local ETAStep = 0
local Updateblock = 0
local APRGOSSIPCOUNT = 0

-- //TODO Create Step option to ignore progress bar (maybe quets update?)
APR.ProgressbarIgnore = {
    ["60520-2"] = 1,
    ["57724-2"] = 1,
}

-- //TODO create Spell DB
local APR_HSSpellIDs = {
    [8690] = 1,
    [298068] = 1,
    [278559] = 1,
    [278244] = 1,
    [286331] = 1,
    [286353] = 1,
    [94719] = 1,
    [285424] = 1,
    [286031] = 1,
    [285362] = 1,
    [136508] = 1,
    [75136] = 1,
    [39937] = 1,
    [231504] = 1,
    [308742] = 1,
}

-- //TODO create step option for emote
-- //TODO create step option for emote + trigger
local APR_GigglingBasket = {
    [L["GIGGLING_BASKET_ONE_TIME"]] = "cheer",
    [L["GIGGLING_BASKET_SPRIGGANS"]] = "flex",
    [L["GIGGLING_BASKET_MANY"]] = "thank",
    [L["GIGGLING_BASKET_FAE"]] = "introduce",
    [L["GIGGLING_BASKET_FEET"]] = "dance",
    [L["GIGGLING_BASKET_HELP"]] = "praise",
}

-- //TODO check what is that shit
local APR_BonusObj = {
    ---- WoD Bonus Obj ----
    [36473] = 1,
    [36500] = 1,
    [36504] = 1,
    [34724] = 1,
    [36564] = 1,
    [34496] = 1,
    [36603] = 1,
    [35881] = 1,
    [37422] = 1,
    [34667] = 1,
    [36480] = 1,
    [36563] = 1,
    [36520] = 1,
    [35237] = 1,
    [34639] = 1,
    [34660] = 1,
    [36792] = 1,
    [35649] = 1,
    [36660] = 1,
    ---- Legion Bonus Obj ----
    [36811] = 1,
    [37466] = 1,
    [37779] = 1,
    [37965] = 1,
    [37963] = 1,
    [37495] = 1,
    [39393] = 1,
    [38842] = 1,
    [43241] = 1,
    [38748] = 1,
    [38716] = 1,
    [39274] = 1,
    [39576] = 1,
    [39317] = 1,
    [39371] = 1,
    [42373] = 1,
    [40316] = 1,
    [38442] = 1,
    [38343] = 1,
    [38939] = 1,
    [39998] = 1,
    [38374] = 1,
    [39119] = 1,
    [9785] = 1,
    ---- Duskwood ----
    [26623] = 1,
    ---- Hillsbrad Foothills ----
    [28489] = 1,
    --- DH Start Area ----
    [39279] = 1,
    [39742] = 1,
    ---- BFA Bonus Obj ----
    [50005] = 1,
    [50009] = 1,
    [50080] = 1,
    [50448] = 1,
    [50133] = 1,
    [51534] = 1,
    [50779] = 1,
    [49739] = 1,
    [51689] = 1,
    [50497] = 1,
    [48093] = 1,
    [47996] = 1,
    [48934] = 1,
    [48852] = 1,
    [49406] = 1,
    [48588] = 1,
    [47756] = 1,
    [49529] = 1,
    [49300] = 1,
    [47797] = 1,
    [49315] = 1,
    [50178] = 1,
    [49918] = 1,
    [47527] = 1,
    [47647] = 1,
    [51900] = 1,
    [50805] = 1,
    [48474] = 1,
    [48525] = 1,
    [45972] = 1,
    [47969] = 1,
    [48181] = 1,
    [48680] = 1,
    [50091] = 1,
    ---- Shadowlands ----
    [60840] = 1,
    [59211] = 1,
    [62732] = 1,
    [62735] = 1,
    [59015] = 1,
}

APR.BreadCrumSkips = {}

function APR.ChkBreadcrums(qids)
    if (qids and APR.Breadcrums and APR.Breadcrums[qids]) then
        for APR_index, APR_value in pairs(APR.Breadcrums[qids]) do
            if ((APR.ActiveQuests[APR_value] or C_QuestLog.IsQuestFlaggedCompleted(APR_value) == true) and (not APR.ActiveQuests[qids])) then
                APR.BreadCrumSkips[qids] = qids
            end
        end
    end
end

local function APR_LeaveQuest(QuestIDs)
    C_QuestLog.SetSelectedQuest(QuestIDs)
    C_QuestLog.AbandonQuest()
end

local function APR_ExitVhicle()
    VehicleExit()
end

local function APR_QAskPopWanted()
    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    local steps
    if CurStep and APR.ActiveRoute and APR.RouteQuestStepList and APR.RouteQuestStepList[APR.ActiveRoute] and APR.RouteQuestStepList[APR.ActiveRoute][CurStep] then
        steps = APR.RouteQuestStepList[APR.ActiveRoute][CurStep]
    end

    local Qid = steps["QaskPopup"]
    if not C_QuestLog.IsQuestFlaggedCompleted(Qid) and not steps["QuestLineSkip"] then
        local SugGroupNr = steps["Group"]
        local dialogText = L["OPTIONAL"] .. " - " .. L["SUGGESTED_PLAYERS"] .. ": " .. SugGroupNr

        APR.questionDialog:CreateQuestionPopup(
            dialogText,
            function()
                APRData[APR.PlayerID]["WantedQuestList"][Qid] = 1
                _G.UpdateNextStep()
            end,
            function()
                APRData[APR.PlayerID]["WantedQuestList"][Qid] = 0
                _G.UpdateNextStep()
            end
        )
    else
        _G.UpdateNextStep()
    end
end

local function SkipStepCondition(steps)
    -- Skip steps if not Faction or Race or Class or Achievement
    if (
            (steps["Faction"] and steps["Faction"] ~= APR.Faction) or
            (steps["Race"] and steps["Race"] ~= APR.Race) or
            (steps["Class"] and steps["Class"] ~= APR.ClassName) or
            (steps["HasAchievement"] and not _G.HasAchievement(steps["HasAchievement"])) or
            (steps["DontHaveAchievement"] and _G.HasAchievement(steps["DontHaveAchievement"]))
        ) then
        -- Counter for skipper step in the current route
        APRData[APR.PlayerID][APR.ActiveRoute .. '-SkippedStep'] = (APRData[APR.PlayerID]
            [APR.ActiveRoute .. '-SkippedStep'] or 0) + 1
        _G.UpdateNextStep()
        return true
    end
    return false
end

local function APR_UpdateStep()
    if not APR.settings.profile.enableAddon then
        return
    end
    if (APR.settings.profile.debug) then
        print("Function: APR_UpdateStep()")
    end
    if (IsInGroup() and APR.settings.profile.showGroup and not IsInInstance()) then
        APR.party:ShowFrame()
    elseif (APR.party:IsShowFrame()) then
        APR.party:RemoveTeam()
        APR.party:HideFrame()
    end
    if (APR.ActiveRoute and not APRData[APR.PlayerID][APR.ActiveRoute]) then
        APRData[APR.PlayerID][APR.ActiveRoute] = 1
    end

    -- //TODO Return if not in the right zone (check why no data on zone change with the return)
    if APR.IsInRouteZone then
        if (APR.InCombat) then
            APR.BookUpdAfterCombat = true
        end
        if (not InCombatLockdown()) then
            APR.currentStep:RemoveQuestStepsAndExtraLineTexts()
            APR.currentStep:Disable()
        end
    end

    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    -- Extra liners here
    local MissingQs = {}
    if (APR.settings.profile.debug) then
        print("APR_UpdateStep() Step:", CurStep)
    end
    APR.party:SendGroupMessage()

    if (APR.RouteQuestStepList and APR.RouteQuestStepList[APR.ActiveRoute] and APR.RouteQuestStepList[APR.ActiveRoute][CurStep]) then
        local steps = APR.RouteQuestStepList[APR.ActiveRoute][CurStep]
        local IdList

        APR.currentStep:ButtonEnable()
        APR:SendMessage("APR_MAP_UPDATE")

        if (SkipStepCondition(steps)) then
            return
        end

        if (APR.ActiveQuests and APR.ActiveQuests[57867] and APR.IsInRouteZone) then
            APR.SweatOfOurBrowBuffFrame:Show()
        else
            APR.SweatOfOurBrowBuffFrame:Hide()
        end
        if (APR.ActiveRoute) then
            local function checkChromieTimeline(id)
                local chromieExpansionOption = C_ChromieTime.GetChromieTimeExpansionOption(id)
                if (not chromieExpansionOption) then
                    APR.currentStep:AddExtraLineText("NOT_IN_CHROMIE_TIMELINE", L["NOT_IN_CHROMIE_TIMELINE"])
                elseif (chromieExpansionOption.alreadyOn == false) then
                    APR.currentStep:AddExtraLineText("SWITCH_TO_CHROMIE" .. chromieExpansionOption.name,
                        L["SWITCH_TO_CHROMIE"] .. " " .. chromieExpansionOption.name)
                end
            end
            -- Uncomment if needed for new route
            -- if (APR.RouteList.Cataclysm[APR.ActiveRoute]) then
            --     checkChromieTimeline(5)
            -- end
            -- if (APR.RouteList.TheBurningCrusade[APR.ActiveRoute]) then
            --     checkChromieTimeline(6)
            -- end
            -- if (APR.RouteList.WrathOfTheLichKing[APR.ActiveRoute]) then
            --     checkChromieTimeline(7)
            -- end
            -- if (APR.RouteList.MistsOfPandaria[APR.ActiveRoute]) then
            --     checkChromieTimeline(8)
            -- end
            if (APR.RouteList.WarlordsOfDraenor[APR.ActiveRoute]) then
                checkChromieTimeline(9)
            end
            -- if (APR.RouteList.Legion[APR.ActiveRoute]) then
            --     checkChromieTimeline(10)
            -- end
            -- if (APR.RouteList.BattleForAzeroth[APR.ActiveRoute]) then
            --     checkChromieTimeline(15)
            -- end
            -- if (APR.RouteList.Shadowlands[APR.ActiveRoute]) then
            --     checkChromieTimeline(14)
            -- end
        end
        -- Check for ExtraLineText
        for key, value in pairs(steps) do
            if string.match(key, "ExtraLineText+") and APR.IsInRouteZone then
                local APRExtraLine = steps[key]
                if (L[APRExtraLine]) then
                    APR.currentStep:AddExtraLineText(APRExtraLine, L[APRExtraLine])
                end
            end
        end
        -- //TODO REWORK ExtraLine
        if (steps["ExtraLine"] and APR.IsInRouteZone) then
            local APRExtraLine = steps["ExtraLine"]
            local fleetfootItemID = 44886
            local wildfireBottleItemID = 44967
            local harpysHornItemID = 9530
            local extraLineQuests = {
                [13544] = {
                    itemID = fleetfootItemID,
                    description = L["KILL_FLEETFOOT"],
                    count = 1,
                },
                [13595] = {
                    itemID = wildfireBottleItemID,
                    description = L["LOOT_WILDFIRE_BOTTLE"],
                    count = 1,
                },
                [25654] = {
                    itemID = harpysHornItemID,
                    description = L["LOOT_HARPYS_HORN"],
                    count = 1,
                }
            }
            for questID, questInfo in pairs(extraLineQuests) do
                if APRExtraLine == questID then
                    local itemCount = GetItemCount(questInfo.itemID)
                    if itemCount < questInfo.count then
                        APR.currentStep:UpdateQuestSteps(questID,
                            questInfo.description .. " (" .. itemCount .. "/" .. questInfo.count .. ")", questInfo
                            .itemID)
                    else
                        _G.NextQuestStep()
                        return
                    end
                    break
                end
            end

            if (APRExtraLine == 14358) then
                local melonFruitItemID = 48106
                local satyrFleshItemID = 48857
                local satyrSaberItemID = 48943
                local requiredMelonFruitCount = 8
                local requiredSatyrFleshCount = 10
                local requiredSatyrSaberCount = 20

                local melonFruitCount = GetItemCount(melonFruitItemID)
                local satyrFleshCount = GetItemCount(satyrFleshItemID)
                local satyrSaberCount = GetItemCount(satyrSaberItemID)
                if melonFruitCount < requiredMelonFruitCount then
                    APR.currentStep:UpdateQuestSteps(14358,
                        L["LOOT_MELONFRUIT"] .. "( " .. melonFruitCount .. "/" .. requiredMelonFruitCount .. ")",
                        melonFruitItemID)
                end
                if satyrFleshCount < requiredSatyrFleshCount then
                    APR.currentStep:UpdateQuestSteps(14358,
                        L["KILL_SATYR_FLESH"] .. " (" .. satyrFleshCount .. "/" .. requiredSatyrFleshCount .. ")",
                        satyrFleshItemID)
                end
                if satyrSaberCount < requiredSatyrSaberCount then
                    APR.currentStep:UpdateQuestSteps(14358,
                        L["LOOT_SATYR_SABER"] .. " (" .. satyrSaberCount .. "/" .. requiredSatyrSaberCount .. ")",
                        satyrSaberItemID)
                end
                if melonFruitCount == requiredMelonFruitCount and satyrFleshCount == requiredSatyrFleshCount and satyrSaberCount == requiredSatyrSaberCount then
                    _G.NextQuestStep()
                    return
                end
            end
        end
        if (steps and steps["LoaPick"] and steps["LoaPick"] == 123 and ((APR.ActiveQuests[47440] or C_QuestLog.IsQuestFlaggedCompleted(47440)) or (APR.ActiveQuests[47439] or C_QuestLog.IsQuestFlaggedCompleted(47439)))) then
            _G.UpdateNextStep()
            return
        elseif (steps["PickedLoa"] and steps["PickedLoa"] == 2 and (APR.ActiveQuests[47440] or C_QuestLog.IsQuestFlaggedCompleted(47440))) then
            _G.UpdateNextStep()
            if (APR.settings.profile.debug) then
                print("PickedLoa Skip 2 step:" .. CurStep)
            end
            return
        elseif (steps["PickedLoa"] and steps["PickedLoa"] == 1 and (APR.ActiveQuests[47439] or C_QuestLog.IsQuestFlaggedCompleted(47439))) then
            _G.UpdateNextStep()
            if (APR.settings.profile.debug) then
                print("PickedLoa Skip 1 step:" .. CurStep)
            end
            return
        end
        if (steps["BreadCrum"]) then
            APR.ChkBreadcrums(steps["BreadCrum"])
        end
        if (C_QuestLog.IsQuestFlaggedCompleted(47440) == true) then
            APRData[APR.PlayerID]["LoaPick"] = 1
        elseif (C_QuestLog.IsQuestFlaggedCompleted(47439) == true) then
            APRData[APR.PlayerID]["LoaPick"] = 2
        end
        if (steps["LeaveQuest"]) then
            APR_LeaveQuest(steps["LeaveQuest"])
        end
        if (steps["LeaveQuests"]) then
            for _, questID in pairs(steps["LeaveQuests"]) do
                APR_LeaveQuest(questID)
            end
        end
        if (steps["ZoneDoneSave"]) then
            local index, currentRouteName = next(APRCustomPath[APR.PlayerID])

            -- Force reset heirloom to show heirloom taximap (not avalaible in exile reach)
            if currentRouteName == "01-10 Exile's Reach" then
                APR.settings.profile.heirloomWarning = false
                APR.heirloom:RefreshFrameAnchor()
            end
            APRZoneCompleted[APR.PlayerID][currentRouteName] = true
            tremove(APRCustomPath[APR.PlayerID], index)
            APR.routeconfig:CheckIsCustomPathEmpty()
            APR.routeconfig:SendMessage("APR_Custom_Path_Update")
            APR.BookingList["UpdateMapId"] = true
        end
        if (steps["SpecialLeaveVehicle"]) then
            C_Timer.After(1, APR_ExitVhicle)
            C_Timer.After(3, APR_ExitVhicle)
            C_Timer.After(5, APR_ExitVhicle)
            C_Timer.After(10, APR_ExitVhicle)
        end
        if (steps["VehicleExit"]) then
            VehicleExit()
        end
        if (steps["SpecialFlight"] and C_QuestLog.IsQuestFlaggedCompleted(steps["SpecialFlight"])) then
            _G.UpdateNextStep()
            return
        end
        if (steps["GroupTask"] and APRData[APR.PlayerID]["WantedQuestList"][steps["GroupTask"]] and APRData[APR.PlayerID]["WantedQuestList"][steps["GroupTask"]] == 0) then
            _G.UpdateNextStep()
            return
        end
        if (steps["ETA"] and not steps["UseFlightPath"] and not steps["SpecialETAHide"]) then
            if (ETAStep ~= CurStep) then
                APR.AFK:SetAfkTimer(steps["ETA"])
                ETAStep = CurStep
            end
        end
        if (steps["SpecialETAHide"]) then
            APR.AFK:HideFrame()
        end
        if (steps["UseGlider"] and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("USE_ITEM_GLIDER", L["USE_ITEM"] .. ": " .. APR.GliderFunc())
        end
        if (steps["Bloodlust"] and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("BLOODLUST", L["BLOODLUST"])
        end
        if (steps["InVehicle"] and not UnitInVehicle("player") and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("MOUNT_HORSE_SCARE_SPIDER", L["MOUNT_HORSE_SCARE_SPIDER"])
        elseif (steps["InVehicle"] and steps["InVehicle"] == 2 and UnitInVehicle("player") and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("SCARE_SPIDER_INTO_LUMBERMILL", L["SCARE_SPIDER_INTO_LUMBERMILL"])
        end
        if (steps["DoIHaveFlight"]) then
            if (CheckRidingSkill(33391) or CheckRidingSkill(90265) or CheckRidingSkill(34090)) then
                _G.NextQuestStep()
                return
            end
        end
        if (steps["Qpart"]) then
            local IdList = steps["Qpart"]
            if (steps["QpartDB"]) then
                local ZeIDi = 0
                for hz = 1, getn(steps["QpartDB"]) do
                    local ZeQID = steps["QpartDB"][hz]
                    if (C_QuestLog.IsQuestFlaggedCompleted(ZeQID) or APR.ActiveQuests[ZeQID]) then
                        ZeIDi = ZeQID
                        break
                    end
                end
                local newList = {}
                for APR_index, APR_value in pairs(IdList) do
                    newList = APR_value
                    break
                end
                IdList = nil
                IdList = {}
                IdList[ZeIDi] = newList
            end

            local Flagged = 0
            local Total = 0
            for APR_index, APR_value in pairs(IdList) do
                for APR_index2, APR_value2 in pairs(APR_value) do
                    Total = Total + 1
                    local qid = APR_index .. "-" .. APR_index2
                    if (C_QuestLog.IsQuestFlaggedCompleted(APR_index) or ((UnitLevel("player") == APR.MaxLevel) and APR_BonusObj[APR_index]) or APRData[APR.PlayerID]["BonusSkips"][APR_index] or APR.BreadCrumSkips[APR_index]) then
                        Flagged = Flagged + 1
                    elseif (APR.ActiveQuests[qid] and APR.ActiveQuests[qid] == "C") then
                        Flagged = Flagged + 1
                    elseif (APR.ActiveQuests[qid]) then
                        if (APR.IsInRouteZone) then
                            local ZeTExt
                            -- //TODO: WWWWWWWWWWWWWTTTTTTTTTTTTTTFFFFFFFFFFFFFFF ???
                            if (APR.ActiveQuests["57713-4"] and UIWidgetTopCenterContainerFrame and UIWidgetTopCenterContainerFrame["widgetFrames"]) then
                                for APR_index2, APR_value2 in PairsByKeys(UIWidgetTopCenterContainerFrame["widgetFrames"]) do
                                    if (UIWidgetTopCenterContainerFrame["widgetFrames"][APR_index2]["Text"]) then
                                        ZeTExt = UIWidgetTopCenterContainerFrame["widgetFrames"][APR_index2]["Text"]
                                            :GetText()
                                        if (string.find(ZeTExt, "(%d+)(.*)")) then
                                            local _, _, ZeTExt2 = string.find(ZeTExt, "(%d+)(.*)")
                                            ZeTExt = ZeTExt2
                                        end
                                    end
                                end
                            end

                            local checkpbar = C_QuestLog.GetQuestObjectives(APR_index)
                            if (not string.find(APR.ActiveQuests[qid], "(.*)(%d+)(.*)") and checkpbar and checkpbar[tonumber(APR_index2)] and checkpbar[tonumber(APR_index2)]["type"] and checkpbar[tonumber(APR_index2)]["type"] == "progressbar") then
                                APR.currentStep:UpdateQuestSteps(APR_index,
                                    "(" .. GetQuestProgressBarPercent(APR_index) .. "%) " .. APR.ActiveQuests[qid],
                                    APR_index2)
                            elseif (ZeTExt) then
                                APR.currentStep:UpdateQuestSteps(APR_index, ZeTExt .. "% - " .. APR.ActiveQuests[qid],
                                    APR_index2)
                            else
                                APR.currentStep:UpdateQuestSteps(APR_index, APR.ActiveQuests[qid], APR_index2)
                            end
                        end
                    elseif (not APR.ActiveQuests[APR_index] and not MissingQs[APR_index]) then
                        if (APR.IsInRouteZone) then
                            if (APR_BonusObj[APR_index]) then
                                APR.currentStep:UpdateQuestSteps(APR_index, L["DO_BONUS_OBJECTIVE"] ..
                                    ": " .. APR_index, APR_index2)
                                MissingQs[APR_index] = 1
                            else
                                APR.currentStep:UpdateQuestSteps(APR_index, L["ERROR"] ..
                                    " - " .. L["MISSING_Q"] ..
                                    ": " .. APR_index, APR_index2)
                                MissingQs[APR_index] = 1
                            end
                        end
                    end
                end
            end
            if (Flagged == Total and Flagged > 0) then
                _G.UpdateNextStep()
                return
            end
        elseif (steps["ExitTutorial"]) then
            if C_QuestLog.IsOnQuest(steps["ExitTutorial"]) then
                _G.NextQuestStep()
                return
            end
        elseif (steps["PickUp"]) then
            IdList = steps["PickUp"]
            local pickUpDB = steps["PickUpDB"]
            if pickUpDB then
                local flaggedQuest = 0
                for _, questID in ipairs(pickUpDB) do
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.ActiveQuests[questID] then
                        flaggedQuest = questID
                        break
                    end
                end
                if flaggedQuest > 0 then
                    _G.NextQuestStep()
                    return
                elseif APR.IsInRouteZone then
                    APR.currentStep:UpdateQuestSteps(steps["PickUp"][1], L["PICK_UP_Q"] .. ": 1", "PickUp")
                end
            else
                local pickupLeft = #IdList
                local Flagged = 0
                for _, questID in ipairs(IdList) do
                    if not (APR.ActiveQuests[questID] or C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.BreadCrumSkips[questID]) then
                        pickupLeft = pickupLeft - 1
                    end
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.ActiveQuests[questID] or APR.BreadCrumSkips[questID] then
                        Flagged = Flagged + 1
                    end
                end
                if #IdList == Flagged then
                    if APR.settings.profile.debug then
                        print("APR.UpdateStep:PickUp:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                    end
                    _G.NextQuestStep()
                    return
                elseif APR.IsInRouteZone then
                    APR.currentStep:UpdateQuestSteps(steps["PickUp"][1],
                        L["PICK_UP_Q"] .. ": " .. pickupLeft .. "/" .. #IdList, "PickUp")
                end
            end
        elseif (steps["CRange"]) then
            IdList = steps["CRange"]
            if (C_QuestLog.IsQuestFlaggedCompleted(IdList) or APR.BreadCrumSkips[IdList]) then
                if (APR.settings.profile.debug) then
                    print("APR.UpdateStep:CRange:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                end
                _G.NextQuestStep()
                return
            elseif APR.IsInRouteZone then
                APR.currentStep:AddExtraLineText("CRange" .. IdList, APR.CheckCRangeText(), true)
            end
        elseif (steps["Treasure"]) then
            IdList = steps["Treasure"]
            if (C_QuestLog.IsQuestFlaggedCompleted(IdList)) then
                if (APR.settings.profile.debug) then
                    print("APR.UpdateStep:Treasure:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                end
                _G.NextQuestStep()
                return
            elseif APR.IsInRouteZone then
                APR.currentStep:UpdateQuestSteps(IdList, L["GET_TREASURE"], "Treasure")
            end
        elseif (steps["DropQuest"]) then
            IdList = steps["DropQuest"]
            if (C_QuestLog.IsQuestFlaggedCompleted(IdList) or APR.ActiveQuests[IdList]) then
                if (APR.settings.profile.debug) then
                    print("APR.UpdateStep:DropQuest:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                end
                _G.NextQuestStep()
                return
            end
        elseif (steps["Done"]) then
            local doneList = steps["Done"]
            local doneDBList = steps["DoneDB"]
            if doneDBList then
                for _, questID in ipairs(doneDBList) do
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.ActiveQuests[questID] then
                        doneList = { questID }
                        break
                    end
                end
            end

            local questLeft = #doneList
            local Flagged = 0

            for _, questID in ipairs(doneList) do
                if APR.ActiveQuests[questID] then
                    questLeft = questLeft - 1
                end
                if C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.BreadCrumSkips[questID] then
                    Flagged = Flagged + 1
                end
            end

            if #doneList == Flagged then
                if APR.settings.profile.debug then
                    print("APR.UpdateStep:Done:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                end
                _G.UpdateNextStep()
                return
            elseif APR.IsInRouteZone then
                APR.currentStep:UpdateQuestSteps(doneList[1], L["TURN_IN_Q"] .. ": " .. questLeft .. "/" .. #doneList,
                    "Done")
            end
        elseif (steps["WarMode"]) then
            if (C_QuestLog.IsQuestFlaggedCompleted(steps["WarMode"]) or C_PvP.IsWarModeDesired() == true) then
                if APR.settings.profile.debug then
                    print("APR.UpdateStep:WarMode:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                end
                _G.UpdateNextStep()
                return
            elseif APR.IsInRouteZone then
                APR.currentStep:UpdateQuestSteps(steps["WarMode"], L["TURN_ON_WARMODE"], "WarMode")
                if (C_PvP.IsWarModeDesired() == false and C_PvP.CanToggleWarModeInArea()) then
                    C_PvP.ToggleWarMode()
                    APR.BookingList["UpdateStep"] = true
                end
            end
        elseif steps["UseHS"] or steps["UseDalaHS"] or steps["UseGarrisonHS"] then
            local questKey, questText, useHSKey

            if steps["UseHS"] then
                questKey = steps["UseHS"]
                questText = L["USE_HEARTHSTONE"]
                useHSKey = "UseHS"
            elseif steps["UseDalaHS"] then
                questKey = steps["UseDalaHS"]
                questText = L["USE_DALARAN_HEARTHSTONE"]
                useHSKey = "UseDalaHS"
            else
                questKey = steps["UseGarrisonHS"]
                questText = L["USE_GARRISON_HEARTHSTONE"]
                useHSKey = "UseGarrisonHS"
            end

            if APR.IsInRouteZone then
                APR.currentStep:UpdateQuestSteps(questKey, questText, useHSKey)
            end

            if C_QuestLog.IsQuestFlaggedCompleted(questKey) then
                _G.UpdateNextStep()
                return
            end
        elseif (steps["SetHS"]) then
            if APR.IsInRouteZone then
                APR.currentStep:UpdateQuestSteps(steps["SetHS"], L["SET_HEARTHSTONE"], "SetHS")
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(steps["SetHS"])) then
                _G.UpdateNextStep()
                return
            end
        elseif (steps["GetFP"]) then
            if APR.IsInRouteZone then
                APR.currentStep:UpdateQuestSteps(steps["GetFP"], L["GET_FLIGHTPATH"], "GetFP")
            end
            if HasTaxiNode(steps["GetFP"]) then
                _G.UpdateNextStep()
                return
            end
        elseif (steps["UseFlightPath"]) then
            if APR.IsInRouteZone then
                local questText = (steps.Boat and L["USE_BOAT"] or L["USE_FLIGHTPATH"]) ..
                    ": " .. (APRTaxiNodes[APR.PlayerID][steps.NodeID] or steps.Name)
                APR.currentStep:UpdateQuestSteps(steps["UseFlightPath"], questText, "UseFlightPath")
            end
            if C_QuestLog.IsQuestFlaggedCompleted(steps["UseFlightPath"]) then
                _G.UpdateNextStep()
                return
            end
        elseif (steps["QaskPopup"]) then
            if (C_QuestLog.IsQuestFlaggedCompleted(steps["QaskPopup"])) then
                _G.UpdateNextStep()
                return
            else
                APR_QAskPopWanted()
            end
        elseif steps["QpartPart"] then
            local IdList = steps["QpartPart"]
            local Flagged = 0
            local Total = 0
            local HasTriggerTextValid = false
            for questId, objectives in pairs(IdList) do
                for objectiveId, _ in pairs(objectives) do
                    Total = Total + 1
                    local qid = questId .. "-" .. objectiveId
                    local questText = APR.ActiveQuests[qid]

                    if questText == "C" or C_QuestLog.IsQuestFlaggedCompleted(questId) then
                        Flagged = Flagged + 1
                    elseif questText then
                        if APR.IsInRouteZone then
                            APR.currentStep:UpdateQuestSteps(questId, questText, objectiveId)
                        end
                    elseif not MissingQs[questId] then
                        if APR.IsInRouteZone then
                            local questTextToAdd = APR_BonusObj[questId] and (L["DO_BONUS_OBJECTIVE"] .. ": " .. questId) or
                                (L["ERROR"] .. " - " .. L["MISSING_Q"] .. ": " .. questId)
                            APR.currentStep:UpdateQuestSteps(questId, questTextToAdd, objectiveId)
                            MissingQs[questId] = 1
                        end
                    end

                    for key, trigerText in pairs(steps) do
                        if key and trigerText and questText then
                            if string.match(key, "TrigText+") and string.find(questText or '', trigerText) then
                                HasTriggerTextValid = true
                            end
                        end
                    end
                end
            end

            if Flagged == Total or HasTriggerTextValid then
                _G.UpdateNextStep()
                return
            end
        end
        if steps["DroppableQuest"] then
            local questData = steps["DroppableQuest"]
            local Qid = questData["Qid"]

            if not C_QuestLog.IsQuestFlaggedCompleted(Qid) and not APR.ActiveQuests[Qid] then
                if APR.IsInRouteZone then
                    local MobId = questData["MobId"]
                    local MobName = APRData.NPCList[MobId] or questData["Text"]
                    local questText = L["Q_DROP"] .. " - " .. MobName

                    APR.currentStep:UpdateQuestSteps(Qid, questText, "DroppableQuest")
                end
            end
        end
        if steps["Fillers"] then
            local IdList = steps["Fillers"]
            for questId, objectives in pairs(IdList) do
                for objectiveId, _ in pairs(objectives) do
                    local qid = questId .. "-" .. objectiveId
                    if C_QuestLog.IsQuestFlaggedCompleted(questId) == false and not APRData[APR.PlayerID]["BonusSkips"][questId] then
                        if APR.ActiveQuests[qid] and APR.ActiveQuests[qid] ~= "C" and APR.IsInRouteZone then
                            local checkpbar = C_QuestLog.GetQuestObjectives(questId)
                            local questText = APR.ActiveQuests[qid]
                            if not string.find(questText, "(.*)(%d+)(.*)") and checkpbar and checkpbar[tonumber(objectiveId)] and checkpbar[tonumber(objectiveId)]["type"] and checkpbar[tonumber(objectiveId)]["type"] == "progressbar" then
                                questText = "(" .. GetQuestProgressBarPercent(questId) .. "%) " .. questText
                            end
                            APR.currentStep:UpdateQuestSteps(questId, questText, objectiveId)
                        end
                    end
                end
            end
        end
        if steps["Grind"] then
            if APR.Level < steps["Grind"] then
                APR.currentStep:AddExtraLineText("GRIND", L["GRIND"] .. " " .. steps["Grind"])
            else
                _G.UpdateNextStep()
            end
        end

        -- Set Quest Item Button
        APR.SetButton()
        if (steps["ZoneDone"] or (APR.ActiveRoute == 862 and APRData[APR.PlayerID]["HordeD"] and APRData[APR.PlayerID]["HordeD"] == 1)) then
            APR.currentStep:Disable()
            APR.ArrowActive = false
        end
        APR.BookingList["SetQPTT"] = true
        APR.questOrderList:AddStepFromRoute()
        -- set Progress bar with the right total
        APR.currentStep:SetProgressBar(CurStep)
    else
        APR.routeconfig:CheckIsCustomPathEmpty()
    end
end

function APR.SetButton()
    if InCombatLockdown() or not APR.IsInRouteZone then
        return
    end
    if (APR.settings.profile.debug) then
        print("Function: APR.SetButton()")
    end
    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if not CurStep or not APR.ActiveRoute or not APR.RouteQuestStepList or not APR.RouteQuestStepList[APR.ActiveRoute] then
        return
    end

    local steps = APR.RouteQuestStepList[APR.ActiveRoute][CurStep]
    if not steps then
        return
    end

    if steps["UseHS"] then
        APR.currentStep:AddStepButton(steps["UseHS"] .. "-" .. "UseHS", 6948)
    elseif steps["UseGarrisonHS"] then
        APR.currentStep:AddStepButton(steps["UseGarrisonHS"] .. "-" .. "UseGarrisonHS", 110560)
    elseif steps["Button"] then
        for APR_index, APR_value in pairs(steps["Button"]) do
            APR.currentStep:AddStepButton(APR_index, APR_value, 'item')
        end
    elseif steps["SpellButton"] then
        for APR_index, APR_value in pairs(steps["SpellButton"]) do
            APR.currentStep:AddStepButton(APR_index, APR_value, 'spell')
        end
    end
end

function APR.CheckCRangeText()
    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    local waypoints = {
        ["FlightPath"] = L["GET_FLIGHTPATH"],
        ["UseFlightPath"] = L["USE_FLIGHTPATH"],
        ["Boat"] = L["USE_BOAT"],
        ["PickUp"] = L["ACCEPT_Q"],
        ["Done"] = L["TURN_IN_Q"],
        ["Qpart"] = L["COMPLETE_Q"],
        ["SetHS"] = L["SET_HEARTHSTONE"],
        ["QpartPart"] = L["COMPLETE_Q"]
    }

    for i = CurStep, #APR.RouteQuestStepList[APR.ActiveRoute] do
        local step = APR.RouteQuestStepList[APR.ActiveRoute][i]
        if step then
            for waypoint, _ in pairs(waypoints) do
                if step[waypoint] then
                    return "[" .. L["WAYPOINT"] .. "] - " .. waypoints[waypoint]
                end
            end
        end
    end

    return L["TRAVEL_TO"] .. " - " .. L["WAYPOINT"]
end

local function APR_UpdateQuest()
    if (APR.settings.profile.debug) then
        print("Function: APR_UpdateQuest()")
    end

    local i = 1
    local Update = 0

    while true do
        local questInfo = C_QuestLog.GetInfo(i)
        if not questInfo then
            break
        end

        local questID = questInfo.questID
        if questID > 0 and not questInfo.isHeader then
            local questTitle = C_QuestLog.GetTitleForQuestID(questID)
            local isComplete = C_QuestLog.IsComplete(questID)
            local numObjectives = C_QuestLog.GetNumQuestObjectives(questID)

            if not APR.ActiveQuests[questID] then
                if (APR.settings.profile.debug) then
                    print("New Q:" .. questID)
                end
            end

            if not isComplete then
                isComplete = 0
                APR.ActiveQuests[questID] = "P"
            else
                isComplete = 1
                APR.ActiveQuests[questID] = "C"
            end

            if numObjectives == 0 then
                local objectiveKey = questID .. "-" .. "1"
                APR.ActiveQuests[objectiveKey] = isComplete == 1 and "C" or questTitle
            else
                local questObjectives = C_QuestLog.GetQuestObjectives(questID)
                for h = 1, numObjectives do
                    local objective = questObjectives[h]
                    local finished = objective.finished
                    local text = objective.text
                    local objectiveKey = questID .. "-" .. h

                    if finished then
                        if APR.ActiveQuests[objectiveKey] and APR.ActiveQuests[objectiveKey] ~= "C" then
                            if (APR.settings.profile.debug) then
                                print("Update: C")
                            end
                            Update = 1
                        end
                        APR.ActiveQuests[objectiveKey] = "C"
                    else
                        if select(2, GetQuestObjectiveInfo(questID, 1, false)) == "progressbar" and text then
                            if not APR.ProgressbarIgnore[objectiveKey] then
                                local progressPercent = tonumber(GetQuestProgressBarPercent(questID))
                                progressPercent = floor(progressPercent + 0.5)
                                text = "(" .. progressPercent .. "%) " .. text
                            end
                        end

                        if APR.ActiveQuests[objectiveKey] and APR.ActiveQuests[objectiveKey] ~= text then
                            if (APR.settings.profile.debug) then
                                print("Update: " .. text)
                            end
                            Update = 1
                        end
                        APR.ActiveQuests[objectiveKey] = text
                    end
                end
            end
        end
        i = i + 1
    end

    if (Update == 1) then
        APR.BookingList["UpdateStep"] = true
    end
end

function APR.GliderFunc()
    if (APR.settings.profile.debug) then
        print("Function: APR.GliderFunc()")
    end

    if APRData["GliderName"] then
        return APRData["GliderName"]
    end

    local itemName = L["GOBLIN_GLIDER"]
    local DerpGot = 0

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if (itemID and itemID == 109076) then
                DerpGot = 1
                local itemLink = C_Container.GetContainerItemLink(bag, slot)
                itemName = GetItemInfo(itemLink)
                break
            end
        end
        if DerpGot == 1 then
            APRData["GliderName"] = itemName
            return itemName
        end
    end

    return itemName
end

local function APR_QuestStepIds()
    if not APR.RouteQuestStepList[APR.ActiveRoute] then
        return
    end

    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if not CurStep or not APR.RouteQuestStepList[APR.ActiveRoute][CurStep] then
        return
    end

    local steps = APR.RouteQuestStepList[APR.ActiveRoute][CurStep]
    if steps["PickUp"] then
        return steps["PickUp"], "PickUp"
    elseif steps["Qpart"] then
        return steps["Qpart"], "Qpart"
    elseif steps["Done"] then
        return steps["Done"], "Done"
    end
end

local function APR_RemoveQuest(questID)
    if not questID then
        return
    end
    APR.ActiveQuests[questID] = nil

    for stepIndex, _ in pairs(APR.ActiveQuests) do
        local questId, _ = string.match(stepIndex, "(%d+)-(%d+)")
        if questId and tonumber(questId) == questID then
            APR.ActiveQuests[stepIndex] = nil
        end
    end

    local IdList, StepP = APR_QuestStepIds()
    if StepP == "Done" then
        local NrLeft = 0
        for _, questId in pairs(IdList) do
            if not C_QuestLog.IsQuestFlaggedCompleted(questId) and questID ~= questId then
                NrLeft = NrLeft + 1
            end
        end
        if NrLeft == 0 then
            _G.UpdateNextQuest()
            if APR.settings.profile.debug then
                print("APR.RemoveQuest:Plus" .. APRData[APR.PlayerID][APR.ActiveRoute])
            end
        end
    end

    APR.BookingList["UpdateMapId"] = true
    APR.BookingList["UpdateStep"] = true
end

local function APR_AddQuest(questID)
    APR.ActiveQuests[questID] = "P"
    local IdList, StepP = APR_QuestStepIds()
    if StepP == "PickUp" then
        local NrLeft = 0
        for _, questId in pairs(IdList) do
            if (not APR.ActiveQuests[questId]) then
                NrLeft = NrLeft + 1
            end
        end
        if (NrLeft == 0) then
            _G.UpdateNextQuest()
            if (APR.settings.profile.debug) then
                print("APR.AddQuest:Plus" .. APRData[APR.PlayerID][APR.ActiveRoute])
            end
        end
    end
    APR.BookingList["UpdateStep"] = true
end

local function APR_UpdateMapId()
    if (APR.settings.profile.debug) then
        print("Function: APR_UpdateMapId()")
    end
    OverrideDataForLesMecsPasCapablesDeSuivreUneFleche() -- Lumbermill Wod route
    APR.BookingList["GetMeToRightZone"] = true
end


local function APR_LoopBookingFunc()
    if not APR.settings.profile.enableAddon then
        return
    end
    -- Actions list
    local bookingActions = {
        GetMeToRightZone = function() APR.transport:GetMeToRightZone() end,
        UpdateMapId = function() APR_UpdateMapId() end,
        AddQuest = function() APR_AddQuest(APR.BookingList["AddQuest"]) end,
        RemoveQuest = function() APR_RemoveQuest(APR.BookingList["RemoveQuest"]) end,
        UpdateQuest = function() APR_UpdateQuest() end,
        UpdateStep = function() APR_UpdateStep() end,
        SetQPTT = function() APR.Arrow:SetQPTT() end
    }

    for action, func in pairs(bookingActions) do
        if APR.BookingList[action] then
            if APR.settings.profile.debug then
                print("LoopBookingFunc:" .. action .. ":" .. (APRData[APR.PlayerID][APR.ActiveRoute] or ""))
            end
            APR.BookingList[action] = nil
            func()
        end
    end

    if APR_ArrowUpdateNr >= APR.settings.profile.arrowFPS then
        APR.Arrow:CalculPosition()
        APR_ArrowUpdateNr = 0
    else
        APR_ArrowUpdateNr = APR_ArrowUpdateNr + 1
    end
end

local function APR_BuyMerchFunc(itemID)
    if not itemID then return end
    for i = 1, GetMerchantNumItems() do
        local id = GetMerchantItemID(i)
        if tonumber(id) == itemID then
            BuyMerchantItem(i)
            MerchantFrame:Hide()
            break
        end
    end
end

local function APR_PopupFunc()
    if (GetNumAutoQuestPopUps() > 0) then
        local questID, popUpType = GetAutoQuestPopUp(1)
        if (popUpType == "OFFER") then
            ShowQuestOffer(1)
            ShowQuestOffer(questID)
        elseif (popUpType == "COMPLETE") then
            ShowQuestOffer(1)
            ShowQuestComplete(questID)
        end
    else
        C_Timer.After(1, APR_PopupFunc)
    end
end

function APR_UpdQuestThing()
    local npc_id, name = GetTargetID(), UnitName("target")
    if (npc_id and name) then
        if (APR.ActiveQuests and APR.ActiveQuests["55981-3"] and APR.ActiveQuests["55981-3"] ~= "C" and npc_id == 153580) then
            DoEmote("HUG")
        elseif (APR.ActiveQuests and APR.ActiveQuests["55981-4"] and APR.ActiveQuests["55981-4"] ~= "C" and npc_id == 153580) then
            DoEmote("WAVE")
        elseif (APR.ActiveQuests and APR.ActiveQuests["59978-4"] and APR.ActiveQuests["59978-4"] ~= "C" and npc_id == 153580) then
            DoEmote("WAVE")
        end
    end
    _G.UpdateQuestAndStep()
    Updateblock = 0
    if (APR.settings.profile.debug) then
        print("Extra UpdQuestThing")
    end
end

local function APR_ZoneResetQnumb()
    APR.Arrow.currentStep = 0
    APR.Arrow:SetQPTT()
end

APR.LoopBooking = CreateFrame("frame")
APR.LoopBooking:SetScript("OnUpdate", APR_LoopBookingFunc)

APR_QH_EventFrame = CreateFrame("Frame")
APR_QH_EventFrame:RegisterEvent("QUEST_REMOVED")
APR_QH_EventFrame:RegisterEvent("QUEST_ACCEPTED")
APR_QH_EventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
APR_QH_EventFrame:RegisterEvent("ZONE_CHANGED")
APR_QH_EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
APR_QH_EventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
APR_QH_EventFrame:RegisterEvent("GOSSIP_SHOW")
APR_QH_EventFrame:RegisterEvent("GOSSIP_CLOSED")
APR_QH_EventFrame:RegisterEvent("UI_INFO_MESSAGE")
APR_QH_EventFrame:RegisterEvent("HEARTHSTONE_BOUND")
APR_QH_EventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
APR_QH_EventFrame:RegisterEvent("UNIT_SPELLCAST_START")
APR_QH_EventFrame:RegisterEvent("QUEST_PROGRESS")
APR_QH_EventFrame:RegisterEvent("QUEST_DETAIL")
APR_QH_EventFrame:RegisterEvent("QUEST_COMPLETE")
APR_QH_EventFrame:RegisterEvent("QUEST_FINISHED")
APR_QH_EventFrame:RegisterEvent("TAXIMAP_OPENED")
APR_QH_EventFrame:RegisterEvent("MERCHANT_SHOW")
APR_QH_EventFrame:RegisterEvent("QUEST_GREETING")
APR_QH_EventFrame:RegisterEvent("ITEM_PUSH")
APR_QH_EventFrame:RegisterEvent("QUEST_AUTOCOMPLETE")
APR_QH_EventFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
APR_QH_EventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
APR_QH_EventFrame:RegisterEvent("QUEST_LOG_UPDATE")
APR_QH_EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
APR_QH_EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
APR_QH_EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
APR_QH_EventFrame:RegisterEvent("CHAT_MSG_ADDON")
APR_QH_EventFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
APR_QH_EventFrame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
APR_QH_EventFrame:RegisterEvent("UNIT_AURA")
APR_QH_EventFrame:RegisterEvent("PLAYER_CHOICE_UPDATE")
APR_QH_EventFrame:RegisterEvent("REQUEST_CEMETERY_LIST_RESPONSE")
APR_QH_EventFrame:RegisterEvent("UPDATE_UI_WIDGET")
APR_QH_EventFrame:RegisterEvent("PET_BATTLE_OPENING_START")
APR_QH_EventFrame:RegisterEvent("PET_BATTLE_CLOSE")
APR_QH_EventFrame:RegisterEvent("GROUP_JOINED")
APR_QH_EventFrame:RegisterEvent("GROUP_LEFT")

APR_QH_EventFrame:SetScript("OnEvent", function(self, event, ...)
    if APR.settings.profile.showEvent then
        print("EVENT: QuestHandler - ", event)
    end
    if not APR.settings.profile.enableAddon then
        return
    end
    local autoAccept = APR.settings.profile.autoAccept
    local autoAcceptRoute = APR.settings.profile.autoAcceptQuestRoute
    local steps = GetSteps(APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute] or nil)
    if (event == "UPDATE_UI_WIDGET") then
        if (APR.ActiveQuests and APR.ActiveQuests["57713-4"]) then
            APR.BookingList["UpdateStep"] = true
        end
    end
    if (event == "REQUEST_CEMETERY_LIST_RESPONSE") then
        APR.BookingList["UpdateMapId"] = true
        C_Timer.After(1, APR_ZoneResetQnumb)
        C_Timer.After(1, UpdateQuestAndStep)
    end
    if (event == "QUEST_LOG_UPDATE") then
        C_Timer.After(0.2, APR_UpdQuestThing)
    end
    if (event == "UNIT_AURA") then
        local arg1, arg2, arg3, arg4 = ...;
        if (arg1 == "player" and steps and steps["Debuffcount"]) then
            for i = 1, 20 do
                local _, _, count, _, _, _, _, _, _, spellId = UnitBuff("player", i)
                if (spellId and count) then
                    if (spellId == 69704 and count == 5) then
                        _G.NextQuestStep()
                    end
                end
            end
        end
        if (APR.SweatBuff[1] or APR.SweatBuff[2] or APR.SweatBuff[3]) then
            local gotbuff1 = false
            local gotbuff2 = false
            local gotbuff3 = false
            for i = 1, 20 do
                local _, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)

                if (spellId == 311103) then
                    gotbuff1 = true
                elseif (spellId == 311107) then
                    gotbuff2 = true
                elseif (spellId == 311058) then
                    gotbuff3 = true
                end
            end
            if (APR.SweatBuff[1]) then
                if (not gotbuff1) then
                    APR.SweatBuff[1] = false
                    APR.SweatOfOurBrowBuffFrame.Traps.texture:SetColorTexture(0.5, 0.1, 0.1, 1)
                end
            end
            if (APR.SweatBuff[2]) then
                if (not gotbuff2) then
                    APR.SweatBuff[2] = false
                    APR.SweatOfOurBrowBuffFrame.Traps2.texture:SetColorTexture(0.5, 0.1, 0.1, 1)
                end
            end
            if (APR.SweatBuff[3]) then
                if (not gotbuff3) then
                    APR.SweatBuff[3] = false
                    APR.SweatOfOurBrowBuffFrame.Traps3.texture:SetColorTexture(0.5, 0.1, 0.1, 1)
                end
            end
        end
        if (arg1 == "player" and APR.ActiveQuests and APR.ActiveQuests[57867]) then
            APR.CheckSweatBuffz()
            C_Timer.After(2, APR.CheckSweatBuffz)
        end
        if steps and steps.Button then
            APR.currentStep:UpdateStepButtonCooldowns()
        end
    end
    if (event == "PLAYER_TARGET_CHANGED") then -- //TODO rework for custom target and action
        local npc_id, name = GetTargetID(), UnitName("target")
        if (npc_id and name) then
            if (APR.ActiveQuests and APR.ActiveQuests["55981-3"] and APR.ActiveQuests["55981-3"] ~= "C" and npc_id == 153580) then
                DoEmote("HUG")
            elseif (APR.ActiveQuests and APR.ActiveQuests["55981-4"] and APR.ActiveQuests["55981-4"] ~= "C" and npc_id == 153580) then
                DoEmote("WAVE")
            elseif (APR.ActiveQuests and APR.ActiveQuests["59978-4"] and APR.ActiveQuests["59978-4"] ~= "C" and npc_id == 153580) then
                DoEmote("WAVE")
            end
        end
    end
    if (event == "CHAT_MSG_COMBAT_XP_GAIN") then
        if (steps and steps["Treasure"]) then
            _G.UpdateQuestAndStep()
            C_Timer.After(2, UpdateQuestAndStep)
            C_Timer.After(4, UpdateQuestAndStep)
        end
    end
    if (event == "PLAYER_REGEN_ENABLED") then
        APR.InCombat = false
        if (APR.BookUpdAfterCombat) then
            APR.BookingList["UpdateStep"] = true
        end
    end
    if (event == "PLAYER_REGEN_DISABLED") then
        APR.InCombat = true
    end
    if (event == "CHAT_MSG_ADDON") then
        local arg1, arg2, arg3, arg4 = ...;
        if (arg1 == "APRChat" and arg3 == "PARTY") then
            APR.party:UpdateGroupListing(tonumber(arg2), TrimPlayerServer(arg4))
        end
    end
    if (event == "PLAYER_CHOICE_UPDATE") then
        local choiceInfo = C_PlayerChoice.GetCurrentPlayerChoiceInfo()
        if (choiceInfo and steps) then
            if (steps["Brewery"] or steps["SparringRing"]) then
                for i, option in ipairs(choiceInfo.options) do
                    if (steps["Brewery"] == option.id or steps["SparringRing"] == option.id) then
                        C_PlayerChoice.SendPlayerChoiceResponse(option.buttons[1].id)
                        _G.NextQuestStep()
                        break
                    end
                end
            end
        end
    end
    if (event == "UNIT_ENTERED_VEHICLE") then
        local arg1, arg2, arg3, arg4, arg5 = ...;
        if (arg1 == "player") then
            if (steps and steps["InVehicle"]) then
                APR.BookingList["UpdateStep"] = true
            end
        end
        if (steps and steps["MountVehicle"]) then
            _G.NextQuestStep()
        end
    end
    if (event == "QUEST_AUTOCOMPLETE") then
        if IsModifierKeyDown() then return end
        if (APR.settings.profile.autoHandIn) then
            APR_PopupFunc()
        end
    end
    if (event == "QUEST_ACCEPT_CONFIRM") then -- escort quest
        if IsModifierKeyDown() then return end
        if (autoAccept or autoAcceptRoute) then
            C_Timer.After(0.2, APR_AcceptQuest)
        end
    end
    if (event == "QUEST_GREETING" or event == "GOSSIP_SHOW") then
        -- Exit function if you press Ctrl/shift/alt key before the
        if IsModifierKeyDown() then return end
        -- Deny NPC
        CheckDenyNPC(steps)
        local npc_id = GetTargetID()
        if (npc_id and (npc_id == 43733) and (npc_id == 45312)) then
            Dismount()
        end
        if (npc_id and ((npc_id == 141584) or (npc_id == 142063) or (npc_id == 25809) or (npc_id == 45400) or (npc_id == 87391))) then
            return
        end
        ------------------------------------
        -- FlightPath
        if steps and (steps["UseFlightPath"] or steps["GetFP"]) and not steps["NoAutoFlightMap"] then
            local gossipOption = C_GossipInfo.GetOptions()
            if next(gossipOption) then
                for _, gossip in pairs(gossipOption) do
                    if gossip.icon == 132057 then
                        C_GossipInfo.SelectOption(gossip.gossipOptionID)
                    end
                end
            end
        end
        ------------------------------------
        -- GOSSIP
        if (APR.settings.profile.autoGossip) then
            -- GOSSIP HARDCODED
            if (steps and steps["Gossip"]) then
                if (steps["Gossip"] == 27373 or steps["Gossip"] == 34398) then
                    C_GossipInfo.SelectOptionByIndex(1)
                    _G.NextQuestStep()
                end
                if (steps["Gossip"] == 3433398) then
                    C_GossipInfo.SelectOptionByIndex(2)
                    _G.NextQuestStep()
                end
                if (steps["Gossip"] == 28202) then
                    APRGOSSIPCOUNT = APRGOSSIPCOUNT + 1
                    if (APRGOSSIPCOUNT == 1) then
                        C_GossipInfo.SelectOptionByIndex(1)
                    elseif (APRGOSSIPCOUNT == 2) then
                        if (APR.Race == "Gnome") then
                            C_GossipInfo.SelectOptionByIndex(1)
                        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
                            C_GossipInfo.SelectOptionByIndex(2)
                        elseif (APR.Race == "NightElf") then
                            C_GossipInfo.SelectOptionByIndex(3)
                        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
                            C_GossipInfo.SelectOptionByIndex(4)
                        end
                    elseif (APRGOSSIPCOUNT == 3) then
                        if (APR.Race == "Gnome") then
                            C_GossipInfo.SelectOptionByIndex(3)
                        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
                            C_GossipInfo.SelectOptionByIndex(4)
                        elseif (APR.Race == "NightElf") then
                            C_GossipInfo.SelectOptionByIndex(2)
                        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
                            C_GossipInfo.SelectOptionByIndex(1)
                        end
                    elseif (APRGOSSIPCOUNT == 4) then
                        if (APR.Race == "Gnome") then
                            C_GossipInfo.SelectOptionByIndex(4)
                        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
                            C_GossipInfo.SelectOptionByIndex(2)
                        elseif (APR.Race == "NightElf") then
                            C_GossipInfo.SelectOptionByIndex(1)
                        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
                            C_GossipInfo.SelectOptionByIndex(3)
                        end
                    elseif (APRGOSSIPCOUNT == 5) then
                        _G.UpdateNextStep()
                    end
                else
                    local info = C_GossipInfo.GetOptions()
                    if next(info) then
                        if steps["GossipOptionID"] then
                            C_GossipInfo.SelectOption(steps["GossipOptionID"])
                        else
                            for i, v in pairs(info) do
                                if (v.orderIndex + 1 == steps["Gossip"]) then
                                    C_GossipInfo.SelectOption(v.gossipOptionID)
                                end
                            end
                        end
                    else
                        C_GossipInfo.SelectOptionByIndex(steps["Gossip"])
                    end
                    --CHROMIE
                    if (steps["ChromiePick"]) then
                        local target = GetTargetID()
                        if (target == 167032) then
                            local extraText = L["SWITCH_TO_CHROMIE"] ..
                                " " .. C_ChromieTime.GetChromieTimeExpansionOption(steps["ChromiePick"]).name
                            APR.currentStep:AddExtraLineText('ChromiePick', extraText)
                            C_Timer.After(1,
                                function() _G.C_ChromieTime.SelectChromieTimeOption(steps["ChromiePick"]) end)
                        end
                    end
                end
            end
        end
        --PICKUP / HANDIN
        local availableQuests = C_GossipInfo.GetAvailableQuests()
        local activeQuests = C_GossipInfo.GetActiveQuests()
        -- Handin
        if (APR.settings.profile.autoHandIn) then
            if (event == "QUEST_GREETING") then
                for i = 1, GetNumActiveQuests() do
                    local title, isComplete = GetActiveTitle(i)
                    if title and isComplete then
                        return SelectActiveQuest(i)
                    end
                end
            elseif activeQuests then
                for titleIndex, questInfo in ipairs(activeQuests) do
                    if questInfo.title and questInfo.isComplete then
                        if questInfo.questID then
                            return C_GossipInfo.SelectActiveQuest(questInfo.questID)
                        end
                    end
                end
            end
        end
        -- Pickup
        if autoAcceptRoute or autoAccept then
            local hasNoRouteMap = not APR.RouteQuestStepList[APR.ActiveRoute]
            if (event == "QUEST_GREETING") then
                local numAvailableQuests = GetNumAvailableQuests()
                for i = 1, numAvailableQuests do
                    local _, _, _, _, questID = GetAvailableQuestInfo(i)
                    if (autoAcceptRoute and (IsARouteQuest(questID) or hasNoRouteMap)) or autoAccept then
                        return SelectAvailableQuest(i)
                    elseif (i == numAvailableQuests and IsPickupStep()) then
                        C_Timer.After(0.2, APR_CloseQuest)
                    end
                end
            elseif availableQuests then
                for titleIndex, questInfo in ipairs(availableQuests) do
                    if questInfo.questID then
                        if (autoAcceptRoute and (IsARouteQuest(questInfo.questID) or hasNoRouteMap)) or autoAccept then
                            return C_GossipInfo.SelectAvailableQuest(questInfo.questID)
                        end
                    end
                end
            end
        end
    end
    if (event == "ITEM_PUSH") then
        APR.BookingList["UpdateStep"] = true
        C_Timer.After(1, UpdateQuestAndStep)
    end
    if (event == "MERCHANT_SHOW") then
        if IsModifierKeyDown() then return end
        if (steps and steps["BuyMerchant"]) then
            C_Timer.After(0.2, APR_BuyMerchFunc(steps["BuyMerchant"]))
        end
        if (APR.settings.profile.autoRepair) then
            if (CanMerchantRepair()) then
                local repairAllCost, canRepair = GetRepairAllCost();
                if (canRepair and repairAllCost > 0) then
                    local guildRepairedItems = false
                    if (IsInGuild() and CanGuildBankRepair()) then
                        local amount = GetGuildBankWithdrawMoney()
                        local guildBankMoney = GetGuildBankMoney()
                        amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)
                        if (amount >= repairAllCost) then
                            RepairAllItems(true);
                            guildRepairedItems = true
                            DEFAULT_CHAT_FRAME:AddMessage("APR: Equipment has been repaired by your Guild")
                        end
                    end
                    if (repairAllCost <= GetMoney() and not guildRepairedItems) then
                        RepairAllItems(false);
                        print("APR: " .. L["REPAIR_EQUIPEMENT"] .. " " .. GetCoinTextureString(repairAllCost))
                    end
                end
            end
        end
        if (APR.settings.profile.autoVendor) then
            local APRtotal = 0
            for myBags = 0, 4 do
                for bagSlots = 1, C_Container.GetContainerNumSlots(myBags) do
                    local CurrentItemId = C_Container.GetContainerItemID(myBags, bagSlots)
                    if CurrentItemId then
                        local _, _, itemQuality, _, _, _, _, _, _, _, sellPrice = GetItemInfo(CurrentItemId)
                        local itemInfo = C_Container.GetContainerItemInfo(myBags, bagSlots)
                        if itemQuality == 0 and sellPrice > 0 and itemInfo.stackCount > 0 then
                            APRtotal = APRtotal + (sellPrice * itemInfo.stackCount)
                            C_Container.UseContainerItem(myBags, bagSlots)
                        end
                    end
                end
            end
            if APRtotal ~= 0 then
                print("APR:" .. L["ITEM_SOLD"] .. " " .. GetCoinTextureString(APRtotal))
            end
        end
    end
    if (event == "UI_INFO_MESSAGE") then
        local arg1, arg2, arg3, arg4, arg5 = ...;
        if Contains({ 280, 281, 282, 283 }, arg1) then
            if (steps and steps["GetFP"]) then
                _G.UpdateNextStep()
            end
        end
    end
    if (event == "TAXIMAP_OPENED") then
        if IsModifierKeyDown() then return end
        if (steps and steps["GetFP"]) then
            _G.UpdateNextStep()
            CloseTaxiMap() -- auto Close the taxi map after getting the FP
        end
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local arg1, arg2, arg3, arg4, arg5 = ...

        if (arg1 == "player") and steps then
            if (APR_HSSpellIDs[arg3] and steps.UseHS) or (steps.SpellTrigger and arg3 == steps.SpellTrigger) then
                _G.UpdateNextStep()
            end
            if steps.Button then
                APR.currentStep:UpdateStepButtonCooldowns()
            end
        end
    end
    if (event == "UNIT_SPELLCAST_START") then
        local arg1, arg2, arg3, arg4, arg5 = ...;
        if ((arg1 == "player") and (arg3 == 171253)) then
            if (steps and steps["UseGarrisonHS"]) then
                APRData[APR.PlayerID][APR.ActiveRoute] = APRData[APR.PlayerID][APR.ActiveRoute] + 1
            end
        end
        if ((arg1 == "player") and (arg3 == 222695)) then
            if (steps and steps["UseDalaHS"]) then
                APRData[APR.PlayerID][APR.ActiveRoute] = APRData[APR.PlayerID][APR.ActiveRoute] + 1
            end
        end
    end
    if (event == "HEARTHSTONE_BOUND") then
        if (steps and steps["SetHS"]) then
            _G.UpdateNextStep()
        end
    end
    if (event == "QUEST_ACCEPTED") then
        local arg1, arg2, arg3, arg4, arg5 = ...;
        if (APR.settings.profile.debug) then
            print(L["Q_ACCEPTED"] .. ": " .. arg1)
        end
        APR.BookingList["UpdateMapId"] = true
        C_Timer.After(3, APR_UpdateMapId)
        if (arg2 and arg2 > 0 and not APR.ActiveQuests[arg2]) then
            APR.BookingList["AddQuest"] = arg2
        end
        if (steps and steps["LoaPick"] and steps["LoaPick"] == 123 and (APR.ActiveQuests[47440] or APR.ActiveQuests[47439])) then
            _G.UpdateNextStep()
        end
        C_Timer.After(0.2, UpdateQuestAndStep)
        C_Timer.After(3, UpdateQuestAndStep)
    end
    if (event == "QUEST_REMOVED") then
        if (APR.settings.profile.debug) then
            print(L["Q_REMOVED"])
        end
        local arg1, arg2, arg3, arg4, arg5 = ...;
        APR.BookingList["RemoveQuest"] = arg1
        if (APR.ActiveRoute == arg1) then
            APR.BookingList["UpdateMapId"] = true
            APRData[APR.PlayerID][arg1] = nil
            APR.map:RemoveMapLine()
        end
        APRData[APR.PlayerID]["QuestCounter2"] = APRData[APR.PlayerID]["QuestCounter2"] + 1
    end
    if (event == "UNIT_QUEST_LOG_CHANGED") then
        local arg1, arg2, arg3, arg4, arg5 = ...;
        if (arg1 == "player" and Updateblock == 0) then
            Updateblock = 1
            C_Timer.After(1, APR_UpdQuestThing)
        end
    end
    if (event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA") then
        APR.Arrow.currentStep = 0
        C_Timer.After(3, APR_ZoneResetQnumb)
        APR.BookingList["UpdateMapId"] = true
    end
    if (event == "GOSSIP_CLOSED") then
        APRGOSSIPCOUNT = 0
    end
    if (event == "QUEST_DETAIL") then -- Fired when the player is given a more detailed view of his quest.
        if IsModifierKeyDown() then return end
        -- Deny NPC
        CheckDenyNPC(steps)
        local questID = GetQuestID()
        local hasNoRouteMap = not APR.RouteQuestStepList[APR.ActiveRoute]
        if questID then
            if not autoAcceptRoute and not autoAccept then
                return
            elseif (QuestGetAutoAccept()) then
                C_Timer.After(0.2, APR_CloseQuest)
            elseif (autoAcceptRoute and (IsARouteQuest(questID) or hasNoRouteMap)) or autoAccept then
                C_Timer.After(0.2, APR_AcceptQuest)
            elseif IsPickupStep() then
                C_Timer.After(0.2, APR_CloseQuest)
                print("APR: " .. L["NOT_YET"])
            end
        end
    end
    if (event == "QUEST_PROGRESS") then
        if IsModifierKeyDown() then return end
        -- Deny NPC
        CheckDenyNPC(steps)
        if (APR.settings.profile.autoHandIn) then
            CompleteQuest()
        end
    end
    if (event == "QUEST_COMPLETE") then
        if IsModifierKeyDown() then return end
        -- Deny NPC
        CheckDenyNPC(steps)
        if (GetNumQuestChoices() > 1) then
            if (APR.settings.profile.autoHandInChoice) then
                -- Get the player ilvl stuff
                local APR_GearIlvlList = {}
                for playerSlot = 0, 18 do
                    local inventoryitemLink = GetInventoryItemLink("player", playerSlot)
                    if (inventoryitemLink) then
                        local _, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(inventoryitemLink)
                        if (itemQuality == 7) then
                            itemLevel = GetDetailedItemLevelInfo(inventoryitemLink)
                        end
                        if (itemEquipLoc and itemLevel) then
                            if (itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or
                                    itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or
                                    itemEquipLoc == "INVTYPE_WEAPON" or
                                    itemEquipLoc == "INVTYPE_SHIELD" or
                                    itemEquipLoc == "INVTYPE_2HWEAPON" or
                                    itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or
                                    itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or
                                    itemEquipLoc == "INVTYPE_HOLDABLE" or
                                    itemEquipLoc == "INVTYPE_RANGED" or
                                    itemEquipLoc == "INVTYPE_THROWN" or
                                    itemEquipLoc == "INVTYPE_RANGEDRIGHT" or
                                    itemEquipLoc == "INVTYPE_RELIC"
                                ) then
                                itemEquipLoc = "INVTYPE_WEAPON"
                            end
                            if (APR_GearIlvlList[itemEquipLoc]) then
                                if (APR_GearIlvlList[itemEquipLoc] > itemLevel) then
                                    APR_GearIlvlList[itemEquipLoc] = itemLevel
                                end
                            else
                                APR_GearIlvlList[itemEquipLoc] = itemLevel
                            end
                        end
                    end
                end

                -- Get quest reward ilvl
                local APRTempGearList = {}
                for h = 1, GetNumQuestChoices() do
                    local questItemLink = GetQuestItemLink("choice", h)
                    if (questItemLink) then
                        local _, _, itemQuality, _, _, _, _, _, itemEquipLoc = GetItemInfo(questItemLink)
                        local ilvl = GetDetailedItemLevelInfo(questItemLink)
                        if (itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or
                                itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or
                                itemEquipLoc == "INVTYPE_WEAPON" or
                                itemEquipLoc == "INVTYPE_SHIELD" or
                                itemEquipLoc == "INVTYPE_2HWEAPON" or
                                itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or
                                itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or
                                itemEquipLoc == "INVTYPE_HOLDABLE" or
                                itemEquipLoc == "INVTYPE_RANGED" or
                                itemEquipLoc == "INVTYPE_THROWN" or
                                itemEquipLoc == "INVTYPE_RANGEDRIGHT" or
                                itemEquipLoc == "INVTYPE_RELIC"
                            ) then
                            itemEquipLoc = "INVTYPE_WEAPON"
                        end
                        if (APR_GearIlvlList[itemEquipLoc]) then
                            APRTempGearList[h] = ilvl - APR_GearIlvlList[itemEquipLoc]
                            print("Qilvl: " ..
                                itemQuality .. " - " .. itemEquipLoc .. " - MySpot: " .. APR_GearIlvlList[itemEquipLoc])
                        end
                    end
                end

                -- Choose the reward
                local PickOne = 0
                local PickOne2 = -99999
                for APR_indexx, APR_valuex in pairs(APRTempGearList) do
                    if (APR_valuex > PickOne2) then
                        PickOne = APR_indexx
                        PickOne2 = APR_valuex
                    end
                end
                if (PickOne > 0) then
                    GetQuestReward(PickOne)
                end
            end
        else
            if (APR.settings.profile.autoHandIn) then
                local npc_id = GetTargetID()
                if (npc_id and ((npc_id == 141584) or (npc_id == 142063) or (npc_id == 45400) or (npc_id == 25809) or (npc_id == 87391))) then
                    return
                end
                GetQuestReward(1)
            end
        end
    end
    if (event == "CHAT_MSG_MONSTER_SAY") then -- //TODO rework chat quest message for all languages
        local arg1, arg2, arg3, arg4 = ...;
        local npc_id, name = GetTargetID(), UnitName("target")
        if (npc_id and name) then
            if (npc_id == 159477) then
                if (APR_GigglingBasket[arg1]) then
                    print("APR: " .. L["DOING_EMOTE"] .. ": " .. APR_GigglingBasket[arg1])
                    DoEmote(APR_GigglingBasket[arg1])
                end
            end
        end
    end
    if (event == "UPDATE_MOUSEOVER_UNIT") then
        if (steps and steps["RaidIcon"]) then
            local guid = UnitGUID("mouseover")
            if (guid) then
                local _, _, _, _, _, npc_id, _ = strsplit("-", guid)
                if (npc_id and tonumber(steps["RaidIcon"]) == tonumber(npc_id)) then
                    if (not GetRaidTargetIndex("mouseover")) then
                        SetRaidTarget("mouseover", 8)
                    end
                end
            end
        elseif (steps and steps["DroppableQuest"]) then
            if (UnitGUID("mouseover") and UnitName("mouseover")) then
                local guid, name = UnitGUID("mouseover"), UnitName("mouseover")
                if (guid) then
                    local type, _, _, _, _, npc_id, _ = strsplit("-", guid);
                    if (type == "Creature" and npc_id and name and steps["DroppableQuest"]["MobId"] == tonumber(npc_id)) then
                        if (APRData.NPCList and not APRData.NPCList[tonumber(npc_id)]) then
                            APRData.NPCList[tonumber(npc_id)] = name
                        end
                    end
                end
            end
        end
    end
    if event == "PET_BATTLE_OPENING_START" or event == "PET_BATTLE_CLOSE" then
        APR.currentStep:RefreshCurrentStepFrameAnchor()
        APR.party:RefreshPartyFrameAnchor()
        APR.questOrderList:RefreshFrameAnchor()
        APR.heirloom:RefreshFrameAnchor()
        APR.RouteSelection:RefreshFrameAnchor()
    end
    if event == "GROUP_JOINED" then
        APR.party:SendGroupMessage()
    end
    if event == "GROUP_LEFT" then
        APR.party:RemoveTeam()
        APR.party:SendGroupMessage()
    end
end)
