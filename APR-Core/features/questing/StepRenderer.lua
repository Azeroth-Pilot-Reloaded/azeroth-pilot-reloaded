-- Coordinates one current-step pass in route order; scheduling and quest-log synchronization live separately.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local handlers = APR.stepHandlers

-- Preserve route action precedence, including mixed legacy step definitions.
function handlers.RenderPrimary(step, showStepDetails, currentStepIndex)
    if step.LootMoney then
        return handlers.LootMoney(step, showStepDetails, currentStepIndex)
    elseif (step.Qpart) then
        return handlers.Qpart(step, showStepDetails, currentStepIndex)
    elseif (step.ExitTutorial) then
        return handlers.ExitTutorial(step, showStepDetails, currentStepIndex)
    elseif (step.PickUp) then
        return handlers.PickUp(step, showStepDetails, currentStepIndex)
    elseif step.TakePortal then
        return handlers.TakePortal(step, showStepDetails, currentStepIndex)
    elseif (step.Waypoint) then
        return handlers.Waypoint(step, showStepDetails, currentStepIndex)
    elseif (step.Treasure) then
        return handlers.Treasure(step, showStepDetails, currentStepIndex)
    elseif (step.DropQuest) then
        return handlers.DropQuest(step, showStepDetails, currentStepIndex)
    elseif (step.Done) then
        return handlers.Done(step, showStepDetails, currentStepIndex)
    elseif step.UseItem then
        return handlers.UseItem(step, showStepDetails, currentStepIndex)
    elseif step.UseSpell then
        return handlers.UseSpell(step, showStepDetails, currentStepIndex)
    elseif step.UseHS or step.UseDalaHS or step.UseGarrisonHS or step.UseSpell then
        return handlers.UseHS(step, showStepDetails, currentStepIndex)
    elseif (step.SetHS) then
        return handlers.SetHS(step, showStepDetails, currentStepIndex)
    elseif (step.GetFP) then
        return handlers.GetFP(step, showStepDetails, currentStepIndex)
    elseif (step.UseFlightPath) then
        return handlers.UseFlightPath(step, showStepDetails, currentStepIndex)
    elseif (step.Group) then
        return handlers.Group(step, showStepDetails, currentStepIndex)
    elseif step.QpartPart then
        return handlers.QpartPart(step, showStepDetails, currentStepIndex)
    elseif step.Achievement then
        return handlers.Achievement(step, showStepDetails, currentStepIndex)
    elseif step.GossipOptionIDs and not APR:HasAnyMainStepOption(step) then
        return handlers.GossipOptionIDs(step, showStepDetails, currentStepIndex)
    end
end

function APR:RenderCurrentStep()
    if not APR.settings.profile.enableAddon then
        return
    end

    if (APR.ActiveRoute and not APRData[APR.PlayerID][APR.ActiveRoute]) then
        APRData[APR.PlayerID][APR.ActiveRoute] = 1
    end

    local currentStepIndex = APRData[APR.PlayerID][APR.ActiveRoute]
    local currentStepToken = APR:GetCurrentStepToken(APR.ActiveRoute, currentStepIndex)

    APR:ResetMissingQuests()

    if UnitIsDeadOrGhost("player") then
        local deathStep = APR:GetStep(currentStepIndex)
        if deathStep and deathStep.DeathSkip and APR.HandleRouteAction and APR:AreConditionalFiltersMet(deathStep) then
            APR:HandleRouteAction(deathStep)
            return
        end
        APR:Debug("Function: APR:UpdateStep() -  Player is dead - guide to corpse")
        APR:GuideToCorpse()
        return
    end

    if APR.farstrider then
        APR.farstrider:ScheduleRouteCheck(currentStepToken)
    end

    APR:Debug("APR.UpdateStep:Current Step:", currentStepIndex)

    local step = APR:GetStep(currentStepIndex)
    if step then
        local showStepDetails = APR.IsInRouteZone or
            (APR.farstrider and APR.farstrider.showOutOfZoneStepContent)

        if APR.IsInRouteZone then
            APR.currentStep:Reset()
        elseif showStepDetails then
            APR.currentStep:RemoveStepContentPreservingNavigationUi()
        end
        APR.currentStep.previousState.currentStepToken = currentStepToken

        APR.currentStep:ButtonEnable()
        APR:SendMessage("APR_MAP_UPDATE")

        -- Hide the AFK frame only if the step has changed
        if APR.AFK.lastStep ~= currentStepIndex then
            APR.AFK:HideFrame()
        end

        if APR:SkipStepCondition(step) then
            return
        end

        -- Sojourner campaign auto-skip: skip campaign steps on eligible Sojourner routes
        if APR:ShouldSojournerSkipStep(step) then
            APRData[APR.PlayerID][APR.ActiveRoute .. '-SkippedStep'] = (APRData[APR.PlayerID]
                [APR.ActiveRoute .. '-SkippedStep'] or 0) + 1
            APR:UpdateNextStep()
            return
        end

        -- Sojourner first-encounter popup (when setting is OFF)
        APR:MaybeSojournerPrompt(step)

        -- Sojourner party sync mismatch check
        APR:CheckSojournerPartySync()
        APR.currentStep:PrepareRaidIcon(step)

        -- set the arrow coord before the step logic to avoid double completion
        APR.Arrow.currentStep = 0
        APR.Arrow:SetCoord()

        if (APR.ActiveRoute) then
            local function checkChromieTimeline(id)
                if APR.Level >= APR.MaxLevelChromie then return end
                local chromieExpansionOption = C_ChromieTime.GetChromieTimeExpansionOption(id)
                if (not chromieExpansionOption) then
                    APR.currentStep:AddExtraLineText("NOT_IN_CHROMIE_TIMELINE", L["NOT_IN_CHROMIE_TIMELINE"])
                elseif (chromieExpansionOption.alreadyOn == false) then
                    APR.currentStep:AddExtraLineText("SWITCH_TO_CHROMIE" .. chromieExpansionOption.name,
                        string.format(L["SWITCH_TO_CHROMIE"], chromieExpansionOption.name))
                end
            end

            local activeRouteData = APR.RouteQuestStepList[APR.ActiveRoute]
            local activeExpansion = activeRouteData and activeRouteData.expansion

            -- Uncomment if needed for new route
            -- if activeExpansion == APR.EXPANSIONS.Cataclysm then
            --     checkChromieTimeline(5)
            -- end
            -- if activeExpansion == APR.EXPANSIONS.TheBurningCrusade then
            --     checkChromieTimeline(6)
            -- end
            -- if activeExpansion == APR.EXPANSIONS.WrathOfTheLichKing then
            --     checkChromieTimeline(7)
            -- end
            -- if activeExpansion == APR.EXPANSIONS.MistsOfPandaria then
            --     checkChromieTimeline(8)
            -- end
            if activeExpansion == APR.EXPANSIONS.WarlordsOfDraenor then
                checkChromieTimeline(9)
            end
            -- if activeExpansion == APR.EXPANSIONS.Legion then
            --     checkChromieTimeline(10)
            -- end
            if activeExpansion == APR.EXPANSIONS.BattleForAzeroth then
                checkChromieTimeline(15)
            end
            if activeExpansion == APR.EXPANSIONS.Shadowlands then
                checkChromieTimeline(14)
            end
        end

        -- Check for ExtraLineText
        local extraLines = {}
        for key, value in pairs(step) do
            if type(key) == "string" and string.match(key, "ExtraLineText+") and showStepDetails then
                table.insert(extraLines, { key = key, text = value })
            end
        end
        table.sort(extraLines, function(a, b) return a.key < b.key end)
        for i, line in ipairs(extraLines) do
            for textIndex, text in ipairs(APR:ResolveStepTextList(line.text)) do
                -- Identify the field and list position, never the raw value (which can be a table).
                local key = i .. "_" .. line.key .. "_" .. textIndex
                APR.currentStep:AddExtraLineText(key, text.text, text.color)
            end
        end

        if showStepDetails and step.Note then
            local noteLines = APR:ResolveStepTextList(step.Note)
            for index, note in ipairs(noteLines) do
                APR.currentStep:AddExtraLineText(
                    "NOTE_" .. tostring(index),
                    note.text,
                    note.color,
                    false
                )
            end
        end

        if showStepDetails and step.Emote then
            APR.currentStep:AddQuestSteps("EMOTE", string.format(L["PERFORM_EMOTE"], step.Emote.emote),
                "Emote", false, true)
            APR.currentStep:AddStepButton("EMOTE-Emote", step.Emote.emote, "emote")
        end

        if showStepDetails and step.PreviewImages then
            APR.currentStepImagePreview:SetPreviewImages(APR.currentStep, step)
        else
            APR.currentStepImagePreview:ClearPreviewImages(APR.currentStep)
        end

        if step.ExtraActionB then
            APR.currentStep:AddExtraLineText("USE_EXTRAACTIONBUTTON", L["USE_EXTRAACTIONBUTTON"])
        end

        -- For old ExtraLine step option
        handlers.HandleExtraLine(step.ExtraLine)


        -- REWORK LOA (BfA Loa pick)
        if step.PickedLoa and step.PickedLoa == 2 and (APR.ActiveQuests[47440] or C_QuestLog.IsQuestFlaggedCompleted(47440)) then
            APR:UpdateNextStep()
            APR:Debug("PickedLoa Skip 2 step:" .. currentStepIndex)
            return
        elseif step.PickedLoa and step.PickedLoa == 1 and (APR.ActiveQuests[47439] or C_QuestLog.IsQuestFlaggedCompleted(47439)) then
            APR:UpdateNextStep()
            APR:Debug("PickedLoa Skip 1 step:" .. currentStepIndex)
            return
        end

        handlers.RenderScenarioTravel(step, currentStepIndex)

        if handlers.RenderRequirements(step, showStepDetails, currentStepIndex) then return end

        if step.DropQuest or step.DroppableQuest then
            APR:UseDroppedQuestItem(step)
        end

        -- Qpart (objectives)
        if APR.HandleRouteAction and APR:HandleRouteAction(step) then
            APR:SetButton()
            APR.questOrderList:DelayedUpdate()
            APR.currentStep:SetProgressBar(currentStepIndex)
            APR.party:SendGroupMessage()
            APR.party:RefreshPartyFrameAnchor()
            return
        end
        if handlers.RenderPrimary(step, showStepDetails, currentStepIndex) then return end

        if handlers.RenderScenarioProgress(step) then return end

        if step.DroppableQuest then
            local questData = step.DroppableQuest
            local Qid = questData.Qid

            if not C_QuestLog.IsQuestFlaggedCompleted(Qid) and not APR.ActiveQuests[Qid] then
                if showStepDetails then
                    APR:GetQuestTitle(Qid)
                    local MobId = questData.MobId
                    local MobName = APRData.NPCList[MobId] or questData.Text
                    local questText = format(L["Q_DROP"], MobName)

                    APR.currentStep:AddQuestSteps(Qid, questText, "DroppableQuest")
                end
            end
        end

        if step.Grind then
            if APR:GetPlayerEffectiveLevel() < APR:ResolveLevelRequirement(step.Grind) then
                APR.currentStep:AddQuestSteps("GRIND", APR:GetGrindStepText(step.Grind), "Grind")
            else
                APR:UpdateNextStep()
                return
            end
        elseif step.Reputation then
            if APR:IsReputationLevelReached(step.Reputation) then
                APR:UpdateNextStep()
                return
            else
                APR.currentStep:AddReputationStep(step.Reputation)
            end
        end
        if step.ResetRoute then
            if showStepDetails then
                APR.currentStep:AddQuestSteps("RESET_ROUTE", L["RESET_ROUTE"], "ResetRoute", false, true)
            end
            APR.questionDialog:CreateQuestionPopup("RESET", "RESET" .. "?", function()
                APRData[APR.PlayerID][APR.ActiveRoute] = 1
                APR:PrintInfo(APR:WrapTextWithAppearanceColor("APR", "general", "accent") .. " Route Reseted")
                APR:UpdateQuestAndStep()
            end)
        end
        if (step.RouteCompleted) then
            if APR:IsTemporaryRouteActive() then
                APR:ClearTemporaryRoute({ completed = true, preserveSessionKey = true })
                return
            end
            local index, currentRouteName = next(APRCustomPath[APR.PlayerID])

            -- Force reset heirloom to show heirloom taximap (not avalaible in exile reach)
            if currentRouteName == "01-10 Exile's Reach" then
                APR:SetHeirloomWarning(false)
                APR.heirloom:RefreshFrameAnchor()
            end

            -- Capture the completed route key BEFORE removing it
            local completedRouteKey = APR.ActiveRoute

            -- Define the route completion finalization as a callback
            local function finalizeRouteCompletion()
                APRZoneCompleted[APR.PlayerID][currentRouteName] = true
                tremove(APRCustomPath[APR.PlayerID], index)
                APR.routeconfig:CheckIsCustomPathEmpty()
                APR.routeconfig:SendMessage("APR_Custom_Path_Update")
                C_Timer.After(1, function() APR.routeconfig:SendMessage("APR_Custom_Path_Update") end)
            end

            -- Suggest next routes immediately; finalize after selection/skip/cancel
            APR:SuggestNextRoutes(completedRouteKey, finalizeRouteCompletion)
            return
        end


        -- Set Quest Item Button
        APR:SetButton()
        APR.questOrderList:DelayedUpdate()
        -- set Progress bar with the right total
        APR.currentStep:SetProgressBar(currentStepIndex)

        -- update for group
        APR.party:SendGroupMessage()
        APR.party:RefreshPartyFrameAnchor()
    else
        APR.currentStep.previousState.currentStepToken = nil
        APR:Debug("APR.UpdateStep:No step found for current step:", currentStepIndex)

        if APR:IsTemporaryRouteActive() then
            APR:ClearTemporaryRoute({ completed = true, preserveSessionKey = true })
            return
        end

        APR.routeconfig:CheckIsCustomPathEmpty()
    end
end
