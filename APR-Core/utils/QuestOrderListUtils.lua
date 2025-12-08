APR.questOrderListUtils = APR.questOrderListUtils or {}

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
    if color == "gray" then
        fontString:SetTextColor(unpack(APR.Color.gray))
    elseif color == "green" then
        fontString:SetTextColor(unpack(APR.Color.green))
    else
        fontString:SetTextColor(unpack(APR.Color.darkGray))
    end
    return fontString
end

function APR.questOrderListUtils:AddStepFrameWithQuest(layout, stepIndex, stepText, questInfo, color, isActiveStep)
    local container = CreateFrame("Frame", nil, layout.scrollChild, "BackdropTemplate")
    local indexStr = tostring(stepIndex)
    local offset = 14 + 7 * string.len(indexStr)
    local frameOffset = layout.frameOffset or 0
    container.offset = offset

    local indexFont = self:CreateTextFont(container, stepIndex, layout.frameWidth, color)
    local titleFont = self:CreateTextFont(container, stepText, layout.frameWidth - offset, color)
    indexFont:SetPoint("TOPLEFT", container, "TOPLEFT", 5, 0)
    titleFont:SetPoint("TOPLEFT", container, "TOPLEFT", offset, 0)

    container.indexFont = indexFont
    container.titleFont = titleFont
    container.questFonts = {}

    local questFontHeight = 0
    local activeQuestId
    for i, quest in pairs(questInfo or {}) do
        local questName = quest.questName and ' - ' .. quest.questName or ''
        local rawQuestId = quest.questID
        local questIdString = tostring(rawQuestId)
        local questText = questIdString .. questName
        local questFont = self:CreateTextFont(container, questText, layout.frameWidth - offset - 10 - 22) -- offset - 10 - scrollbar offset

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
    container.indexFont:SetFontObject("GameFontHighlight")
    container.titleFont:SetFontObject("GameFontHighlight")
    container.indexFont:SetTextColor(unpack(APR.Color.yellow))
    container.titleFont:SetTextColor(unpack(APR.Color.yellow))
    for _, questFont in pairs(container.questFonts) do
        questFont:SetTextColor(unpack(APR.Color.white))
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
