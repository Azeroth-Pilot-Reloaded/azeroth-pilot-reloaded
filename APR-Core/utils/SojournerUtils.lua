local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Session-level guard: one party-mismatch warning per route per session.
-- Keyed by route name, set to true after the popup is shown.
local sojournerPartySyncWarned = {}

---------------------------------------------------------------------------------------
-- Sojourner Campaign Auto-Skip Utility
--
-- When a route has category = Sojourner and a sojournerAchievementID,
-- campaign-tagged steps (IsCampaignQuest = true) can be auto-skipped.
-- The feature only activates when the player has earned the achievement.
--
-- On the first campaign step encountered, if the setting is disabled, a
-- one-time popup asks the player whether to enable auto-skip.
--
-- When in a party, a mismatch warning is shown if group members on the
-- same Sojourner route have different auto-skip states.
---------------------------------------------------------------------------------------

--- Check whether the current active route is a Sojourner route with a
--- sojournerAchievementID and the player has earned that achievement.
---@return boolean eligible true when auto-skip CAN apply
---@return table|nil routeData the route table (for further inspection)
function APR:IsSojournerSkipEligible()
    local routeData = self.RouteQuestStepList and self.RouteQuestStepList[self.ActiveRoute]
    if not routeData then return false, nil end
    if routeData.category ~= APR.CATEGORIES.Sojourner then return false, nil end

    local achievementID = routeData.sojournerAchievementID
    if not achievementID then return false, nil end

    if not self:HasAchievement(achievementID) then return false, nil end

    return true, routeData
end

--- Route-aware check for use in step counting / progress display.
--- Returns true when the sojourner skip setting is enabled AND the
--- given route qualifies for sojourner campaign skipping.
---@param route string|nil route key (defaults to ActiveRoute)
---@return boolean
function APR:IsSojournerSkipActive(route)
    route = route or self.ActiveRoute
    local profile = self:GetSettingsProfile()
    if not profile or not profile.sojournerSkipCampaign then return false end

    local routeData = self.RouteQuestStepList and self.RouteQuestStepList[route]
    if not routeData then return false end
    if routeData.category ~= APR.CATEGORIES.Sojourner then return false end

    local achievementID = routeData.sojournerAchievementID
    if not achievementID then return false end

    return self:HasAchievement(achievementID)
end

--- Determine if a step should be auto-skipped because it is a campaign
--- step on an eligible Sojourner route and the setting is enabled.
---@param step table the current step
---@return boolean shouldSkip
function APR:ShouldSojournerSkipStep(step)
    if not step then return false end

    local profile = self:GetSettingsProfile()
    if not profile or not profile.sojournerSkipCampaign then return false end

    if not self:IsStepCampaignQuest(step) then return false end

    local eligible = self:IsSojournerSkipEligible()
    return eligible
end

---------------------------------------------------------------------------------------
-- First-encounter popup
---------------------------------------------------------------------------------------

--- Show a one-time popup when the player hits the first campaign step on a
--- Sojourner route and the auto-skip option is currently disabled.
--- The popup is only shown once per route (tracked in char DB).
---@param step table the current step
function APR:MaybeSojournerPrompt(step)
    if not step then return end
    if not self:IsStepCampaignQuest(step) then return end

    local profile = self:GetSettingsProfile()
    if not profile then return end

    -- Already enabled – nothing to prompt
    if profile.sojournerSkipCampaign then return end

    local eligible, routeData = self:IsSojournerSkipEligible()
    if not eligible or not routeData then return end

    -- Only prompt once per route per character
    local charDB = SettingsDB and SettingsDB.char
    if not charDB then return end
    charDB.sojournerSkipPromptShown = charDB.sojournerSkipPromptShown or {}
    if charDB.sojournerSkipPromptShown[self.ActiveRoute] then return end
    charDB.sojournerSkipPromptShown[self.ActiveRoute] = true

    local achieveName = select(2, GetAchievementInfo(routeData.sojournerAchievementID)) or "?"
    local routeLabel = routeData.label or self.ActiveRoute

    local text = string.format(
        L["SOJOURNER_PROMPT_TEXT"] .. "\n\n" .. L["SOJOURNER_SETTING_FOOTER"],
        routeLabel,
        achieveName
    )

    self.questionDialog:CreateQuestionPopup(
        "APR_SOJOURNER_SKIP_PROMPT",
        text,
        function() -- Accept: enable auto-skip
            profile.sojournerSkipCampaign = true
            APR:UpdateStep()
        end,
        nil, -- Cancel: do nothing, keep playing normally
        L["SOJOURNER_PROMPT_ACCEPT"],
        L["SOJOURNER_PROMPT_DECLINE"],
        true
    )
end

---------------------------------------------------------------------------------------
-- Party sync check
---------------------------------------------------------------------------------------

--- Compare the local sojournerSkipCampaign setting against group members
--- who are on the same Sojourner route. If there is a mismatch, show a
--- warning popup listing each member and their state.
function APR:CheckSojournerPartySync()
    if not IsInGroup() then return end

    -- Only warn once per route per session
    if sojournerPartySyncWarned[self.ActiveRoute] then return end

    local eligible = self:IsSojournerSkipEligible()
    if not eligible then return end

    local profile = self:GetSettingsProfile()
    if not profile then return end

    local myState = profile.sojournerSkipCampaign and true or false
    local mismatched = {}

    local groupList = self.party and self.party.GroupListSteps
    if not groupList then return end

    for username, data in pairs(groupList) do
        if username ~= self.Username and data.routeFileName == self.ActiveRoute then
            local theirState = data.sojournerSkipCampaign and true or false
            if theirState ~= myState then
                table.insert(mismatched, {
                    name = username,
                    state = theirState,
                })
            end
        end
    end

    if #mismatched == 0 then return end

    -- Build descriptive text
    local lines = {}
    table.insert(lines, L["SOJOURNER_PARTY_MISMATCH_HEADER"])
    table.insert(lines, "")

    -- Local player line
    local myLabel = myState
        and APR:WrapTextInColorCode(L["SOJOURNER_PROMPT_ACCEPT"], "00ff00")
        or APR:WrapTextInColorCode(L["SOJOURNER_PROMPT_DECLINE"], "ff6060")
    table.insert(lines, APR.Username .. ": " .. myLabel)

    -- Remote players
    for _, entry in ipairs(mismatched) do
        local stateLabel = entry.state
            and APR:WrapTextInColorCode(L["SOJOURNER_PROMPT_ACCEPT"], "00ff00")
            or APR:WrapTextInColorCode(L["SOJOURNER_PROMPT_DECLINE"], "ff6060")
        table.insert(lines, entry.name .. ": " .. stateLabel)
    end

    table.insert(lines, "")
    table.insert(lines, L["SOJOURNER_SETTING_FOOTER"])

    sojournerPartySyncWarned[self.ActiveRoute] = true
    self.questionDialog:CreateMessagePopup(table.concat(lines, "\n"), OKAY)
end
