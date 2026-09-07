APR.questOrderListUtils = APR.questOrderListUtils or {}
APR.questOrderListUtils.framePool = {}

function APR.questOrderListUtils:CancelRender(owner)
    if owner.renderFrame then
        owner.renderFrame:SetScript("OnUpdate", nil)
        owner.renderFrame:Hide()
    end
end

-- Resume between rows, with at most one budgeted batch per rendered game frame.
function APR.questOrderListUtils:StartRender(owner, worker, isValid, afterBatch)
    self:CancelRender(owner)
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
                owner.currentStepIndex = nil
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
    container:Hide()
    container:ClearAllPoints()
    container:SetScript("OnEnter", nil)
    container:SetScript("OnLeave", nil)
    container:EnableMouse(false)
    if GameTooltip:GetOwner() == container then GameTooltip:Hide() end
    self.framePool[#self.framePool + 1] = container
end

local function bindUncompletedStepTooltip(container, questInfo)
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
    local titleFont = reuseFont(container.titleFont, stepText, layout.frameWidth - offset, color)
    indexFont:SetPoint("TOPLEFT", container, "TOPLEFT", 5, 0)
    titleFont:SetPoint("TOPLEFT", container, "TOPLEFT", offset, 0)

    container.indexFont = indexFont
    container.titleFont = titleFont
    container.questFontPool = container.questFontPool or {}
    for _, font in ipairs(container.questFontPool) do font:Hide() end
    container.questFonts = {}

    local questFontHeight = 0
    local activeQuestId
    for i, quest in pairs(questInfo or {}) do
        local questName = quest.questName and ' - ' .. quest.questName or ''
        local rawQuestId = quest.questID
        local questIdString = tostring(rawQuestId)
        local questText = questIdString .. questName
        local questFont = reuseFont(container.questFontPool[i], questText, layout.frameWidth - offset - 10 - 22)
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
        questFontHeight = questFontHeight + questFont:GetStringHeight()
        container.questFonts[i] = questFont
    end

    container:SetWidth(layout.frameWidth)
    container:SetHeight(titleFont:GetStringHeight() + questFontHeight + frameOffset)
    container:SetPoint("TOPLEFT", layout.scrollChild, "TOPLEFT", 0, layout.dataHeight)
    layout.dataHeight = layout.dataHeight - container:GetHeight()

    if color == "gray" then
        bindUncompletedStepTooltip(container, questInfo)
    end

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
    container.titleFont:SetWidth(frameWidth - offset)

    local questFontHeight = 0
    for _, questFont in ipairs(container.questFonts) do
        questFont:SetWidth(frameWidth - offset - 10 - 22) -- offset - 10 - scrollbar offset
        questFont:SetPoint("TOPLEFT", container, "TOPLEFT", offset + 10,
            -container.titleFont:GetStringHeight() - 5 - questFontHeight)
        questFontHeight = questFontHeight + questFont:GetStringHeight()
    end

    local containerHeight = container.titleFont:GetStringHeight() + questFontHeight + frameOffset
    container:SetHeight(containerHeight)
    container:SetPoint("TOPLEFT", layout.scrollChild, "TOPLEFT", 0, layout.dataHeight)
    layout.dataHeight = layout.dataHeight - containerHeight

    return containerHeight
end

function APR.questOrderListUtils:SetCurrentStepIndicator(stepList, scrollFrame, stepindex)
    local container = stepList[stepindex]
    if not container then return end
    APR:SetFontStringRole(container.indexFont, "warning")
    APR:SetFontStringRole(container.titleFont, "warning")
    for _, questFont in pairs(container.questFonts) do
        APR:SetFontStringRole(questFont, "base")
    end

    C_Timer.After(0.1, function()
        if scrollFrame:GetVerticalScrollRange() > 0 then
            local yOffset = 0
            for i = 1, stepindex - 1 do
                local prevContainer = stepList[i]
                yOffset = yOffset + (prevContainer and prevContainer:GetHeight() or 0)
            end
            scrollFrame:SetVerticalScroll(yOffset)
        end
    end)
end
