APR.questOrderListUtils = APR.questOrderListUtils or {}
APR.questOrderListUtils.framePool = {}

local REPUTATION_STATE_KEYS = { "Reputation", "ReputationLevel", "SkipForReputation" }

local function appendReputationState(parts, conditions)
    if type(conditions) ~= "table" then return end

    for _, key in ipairs(REPUTATION_STATE_KEYS) do
        local requirement = conditions[key]
        if type(requirement) == "table" then
            parts[#parts + 1] = table.concat({
                key,
                tostring(requirement.factionID or ""),
                tostring(requirement.level or ""),
                tostring(requirement.type or ""),
                APR:IsReputationLevelReached(requirement) and "1" or "0",
            }, ":")
        end
    end

    for _, alternative in ipairs(conditions.AnyOf or {}) do
        appendReputationState(parts, alternative)
    end
end

-- Only threshold changes affect the Quest Order List: reputation progress itself
-- is not displayed. This lets UPDATE_FACTION ignore unrelated reputation gains.
function APR.questOrderListUtils:GetReputationStateSignature(steps)
    local parts = {}
    for _, step in ipairs(steps or {}) do
        appendReputationState(parts, step)
    end
    return table.concat(parts, "|")
end

function APR.questOrderListUtils:CancelRender(owner)
    owner.renderRequest = nil
    if owner.renderFrame then
        owner.renderFrame:SetScript("OnUpdate", nil)
        owner.renderFrame:Hide()
    end
end

-- Resume between rows, with at most one budgeted batch per rendered game frame.
function APR.questOrderListUtils:StartRender(owner, worker, isValid, afterBatch)
    self:CancelRender(owner)
    owner.renderFailed = nil
    owner.renderFrame = owner.renderFrame or CreateFrame("Frame")
    local thread = coroutine.create(worker)
    owner.renderFrame:SetScript("OnUpdate", function()
        if not isValid() then
            self:CancelRender(owner)
            return
        end
        local started = debugprofilestop()
        local profileStart = APR:StartPerformanceSample()
        repeat
            local ok, err = coroutine.resume(thread)
            if not ok then
                self:CancelRender(owner)
                owner.renderFailed = true
                geterrorhandler()(err)
                return
            end
        until coroutine.status(thread) == "dead" or debugprofilestop() - started >= 3
        local finished = coroutine.status(thread) == "dead"
        if finished then self:CancelRender(owner) end
        afterBatch(finished)
        APR:FinishPerformanceSample("QuestOrderListBatch", profileStart)
    end)
    owner.renderFrame:Show()
end

function APR.questOrderListUtils:ReleaseStepFrame(container)
    if container.inPool then return end
    container.inPool = true
    container:Hide()
    container:ClearAllPoints()
    container:SetScript("OnEnter", nil)
    container:SetScript("OnLeave", nil)
    container:EnableMouse(false)
    if GameTooltip:GetOwner() == container then GameTooltip:Hide() end
    self.framePool[#self.framePool + 1] = container
end

function APR.questOrderListUtils:SetStepFrameState(container, color, isCurrentStep)
    if not container then return end

    local titleRole = isCurrentStep and "warning" or (color == "green" and "success" or "muted")
    APR:SetFontStringRole(container.indexFont, titleRole)
    APR:SetFontStringRole(container.titleFont, titleRole)
    for _, questFont in ipairs(container.questFonts or {}) do
        APR:SetFontStringRole(questFont, isCurrentStep and "base" or "muted")
    end
end

function APR.questOrderListUtils:CollapseStepDetails(container)
    if not container or not container.questFonts or #container.questFonts == 0 then
        return false
    end

    for _, questFont in ipairs(container.questFonts) do
        questFont:Hide()
    end
    container.questFonts = {}
    container:SetScript("OnEnter", nil)
    container:SetScript("OnLeave", nil)
    container:EnableMouse(false)
    if GameTooltip:GetOwner() == container then GameTooltip:Hide() end
    return true
end

local function bindUncompletedStepTooltip(container, questInfo)
    container:SetScript("OnEnter", nil)
    container:SetScript("OnLeave", nil)
    container:EnableMouse(false)
    if not container or not questInfo or #questInfo == 0 then
        return
    end

    container:EnableMouse(true)
    container:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        for index, quest in ipairs(questInfo) do
            local questID, objectiveIndex = APR:SplitQuestAndObjective(quest.questID)
            if index > 1 then
                GameTooltip:AddLine(" ")
            end
            if questID then
                APR:AddQuestTooltipDetails(GameTooltip, questID, {
                    objectiveIndex = objectiveIndex,
                    includeCampaign = true,
                    includeStoryline = true,
                })
            end
        end
        GameTooltip:Show()
    end)
    container:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

function APR.questOrderListUtils:IsQuestCompleted(questID)
    return C_QuestLog.IsQuestFlaggedCompleted(questID)
end

function APR.questOrderListUtils:IsQuestCompletedOrActive(questID)
    return self:IsQuestCompleted(questID) or APR.ActiveQuests[questID]
end

function APR.questOrderListUtils:CreateTextFont(parent, text, width, color)
    local fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontString:SetWordWrap(true)
    fontString:SetJustifyH("LEFT")
    fontString:SetText(text)
    fontString:SetWidth(width)
    local role = color == "green" and "success" or "muted"
    APR:RegisterFontString(fontString, "questOrderList", { role = role })
    return fontString
end

function APR.questOrderListUtils:AddStepFrameWithQuest(layout, stepIndex, stepText, questInfo, color, isActiveStep)
    local container = table.remove(self.framePool) or CreateFrame("Frame", nil, layout.scrollChild, "BackdropTemplate")
    container.inPool = nil
    container:SetParent(layout.scrollChild)
    local indexStr = tostring(stepIndex)
    local offset = 14 + 7 * string.len(indexStr)
    local frameOffset = layout.frameOffset or 0
    container.offset = offset

    local function reuseFont(font, text, width, fontColor)
        if not font then return self:CreateTextFont(container, text, width, fontColor) end
        font:SetText(text)
        font:SetWidth(width)
        font:ClearAllPoints()
        APR:SetFontStringRole(font, fontColor == "green" and "success" or "muted")
        font:Show()
        return font
    end
    local indexFont = reuseFont(container.indexFont, stepIndex, layout.frameWidth, color)
    local titleFont = reuseFont(container.titleFont, stepText, layout.frameWidth - offset - 5, color)
    indexFont:SetPoint("TOPLEFT", container, "TOPLEFT", 5, 0)
    titleFont:SetPoint("TOPLEFT", container, "TOPLEFT", offset, 0)

    container.indexFont = indexFont
    container.titleFont = titleFont
    container.questFontPool = container.questFontPool or {}
    container.questFonts = {}

    local questFontHeight = 0
    local activeQuestId
    local signature = { tostring(stepIndex), tostring(stepText), color or "gray", tostring(isActiveStep) }
    for i, quest in ipairs(questInfo or {}) do
        local questName = quest.questName and ' - ' .. quest.questName or ''
        local rawQuestId = quest.questID
        local questIdString = tostring(rawQuestId)
        local questText = questIdString .. questName
        local questFont = reuseFont(container.questFontPool[i], questText, layout.frameWidth - offset - 15)
        signature[#signature + 1] = questText
        container.questFontPool[i] = questFont

        if isActiveStep then
            local dashIndex = string.find(questIdString, "-")
            if dashIndex then
                activeQuestId = string.sub(questIdString, 1, dashIndex - 1)
            else
                activeQuestId = rawQuestId or questIdString
            end
        end

        questFont:SetPoint("TOPLEFT", container, "TOPLEFT", offset + 10,
            -titleFont:GetStringHeight() - 5 - questFontHeight)
        questFontHeight = questFontHeight + questFont:GetStringHeight() + 3
        container.questFonts[i] = questFont
    end
    for i = #container.questFonts + 1, #container.questFontPool do container.questFontPool[i]:Hide() end
    if layout.signatureParts then
        for _, value in ipairs(signature) do
            layout.signatureParts[#layout.signatureParts + 1] = #value .. ":" .. value
        end
    end

    container:SetWidth(layout.frameWidth)
    container:SetHeight(titleFont:GetStringHeight() + questFontHeight + frameOffset)
    container:SetPoint("TOPLEFT", layout.scrollChild, "TOPLEFT", 0, layout.dataHeight)
    layout.dataHeight = layout.dataHeight - container:GetHeight()

    bindUncompletedStepTooltip(container, color == "gray" and questInfo or nil)

    container:Show()

    return container, activeQuestId
end

function APR.questOrderListUtils:AddStepFrame(layout, stepIndex, stepText, color, isActiveStep)
    return self:AddStepFrameWithQuest(layout, stepIndex, stepText, {}, color, isActiveStep)
end

function APR.questOrderListUtils:UpdateContainerLayout(container, layout)
    if not container then return 0 end

    local frameWidth = layout.frameWidth
    local frameOffset = layout.frameOffset
    local offset = container.offset or 0

    container:SetWidth(frameWidth)
    container.indexFont:SetWidth(frameWidth)
    container.titleFont:SetWidth(frameWidth - offset - 5)

    local questFontHeight = 0
    for _, questFont in ipairs(container.questFonts) do
        questFont:SetWidth(frameWidth - offset - 15)
        questFont:SetPoint("TOPLEFT", container, "TOPLEFT", offset + 10,
            -container.titleFont:GetStringHeight() - 5 - questFontHeight)
        questFontHeight = questFontHeight + questFont:GetStringHeight() + 3
    end

    local containerHeight = container.titleFont:GetStringHeight() + questFontHeight + frameOffset
    container:SetHeight(containerHeight)
    container:SetPoint("TOPLEFT", layout.scrollChild, "TOPLEFT", 0, layout.dataHeight)
    layout.dataHeight = layout.dataHeight - containerHeight

    return containerHeight
end

function APR.questOrderListUtils:CancelScroll(scrollFrame)
    if scrollFrame.aprScrollTimer then
        scrollFrame.aprScrollTimer:Cancel()
        scrollFrame.aprScrollTimer = nil
    end
end

function APR.questOrderListUtils:SetCurrentStepIndicator(stepList, scrollFrame, stepindex, followStep)
    local container = stepList[stepindex]
    if not container then return end
    self:SetStepFrameState(container, "gray", true)
    self:CancelScroll(scrollFrame)
    if followStep == false then return end
    scrollFrame.aprScrollTimer = C_Timer.NewTimer(0, function()
        scrollFrame.aprScrollTimer = nil
        if scrollFrame:GetVerticalScrollRange() > 0 then
            local yOffset = 0
            for i = 1, stepindex - 1 do
                local prevContainer = stepList[i]
                yOffset = yOffset + (prevContainer and prevContainer:GetHeight() or 0)
            end
            scrollFrame:SetVerticalScroll(math.min(yOffset, scrollFrame:GetVerticalScrollRange()))
        end
    end)
end
