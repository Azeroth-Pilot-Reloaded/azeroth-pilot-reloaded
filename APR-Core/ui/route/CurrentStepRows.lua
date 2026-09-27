local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local CurrentStep = APR.currentStep
local Layout = CurrentStep.layout
local WIDTH, TOP_OFFSET = Layout.width, Layout.topOffset
local PADDING, INDENT, DETAIL_GAP = Layout.padding, Layout.indent, Layout.detailGap

-- Rows keep their identity across refreshes. A pass marks obsolete content and
-- retires it only after its replacement has been rendered, then lays out once.
function CurrentStep:BeginContentUpdate()
    self.contentUpdateActive = true
end

function CurrentStep:TouchRow(container)
    if container then container.stale = nil end
end

function CurrentStep:ReleaseRow(list, key)
    local container = list[key]
    if not container then return end
    list[key] = nil
    self.pendingRemoval[key] = nil
    self.pendingButtonRequests[key] = nil
    self.pendingRaidIconRequests[key] = nil
    self.pendingButtonResets[key] = nil
    if self:CanSafelyHide(container) then
        container:SetScript("OnEnter", nil)
        container:SetScript("OnLeave", nil)
        container:Hide()
        container:ClearAllPoints()
        self:ResetSecureStepButton(container, key)
        self:ResetSecureRaidIconButton(container, key)
    else
        self:SoftHide(container)
        -- Store the actual retired frame, never a key that a replacement reuses.
        table.insert(self.pendingContainerDestroy, container)
    end
    self.layoutDirty = true
    if list == self.fillersList and APR.fillersFrame then APR.fillersFrame.layoutDirty = true end
end

function CurrentStep:EndContentUpdate(success)
    self.contentUpdateActive = false
    for _, list in ipairs({ self.questsExtraTextList, self.questsList, self.fillersList }) do
        for key, container in pairs(list) do
            if success and container.stale then
                self:ReleaseRow(list, key)
            elseif success and container.refreshActions then
                if not container.actionSeen then
                    self.pendingButtonRequests[key] = nil
                    self:ResetSecureStepButton(container, key)
                end
                if not container.raidSeen then
                    self.pendingRaidIconRequests[key] = nil
                    self:ResetSecureRaidIconButton(container, key)
                end
            end
            container.stale, container.refreshActions = nil, nil
        end
    end
    if self.layoutDirty then self:ReOrderQuestSteps() end
    if APR.fillersFrame and APR.fillersFrame.FlushPendingLayout then APR.fillersFrame:FlushPendingLayout() end
end

local function MarkOrRelease(self, list, preserve)
    for key, container in pairs(list) do
        if not preserve or not preserve(key) then
            if self.contentUpdateActive then
                container.stale = true
                container.refreshActions = true
                container.actionSeen, container.raidSeen = nil, nil
            else
                self:ReleaseRow(list, key)
            end
        end
    end
end

function CurrentStep:RemoveQuestStepsAndExtraLineTexts(removeTextOnly)
    if not removeTextOnly then MarkOrRelease(self, self.questsList) end
    MarkOrRelease(self, self.questsExtraTextList)
    self:ReOrderQuestSteps()
end

function CurrentStep:RemoveStepContentPreservingNavigationUi()
    MarkOrRelease(self, self.questsList, function(key) return APR:IsNavigationQuestUiKey(key) end)
    MarkOrRelease(self, self.questsExtraTextList, function(key) return APR:IsNavigationExtraTextUiKey(key) end)
    if APR.fillersFrame then APR.fillersFrame:RemoveFillerSteps() end
    self:ReOrderQuestSteps()
end

local function SetText(font, text)
    if font:GetText() ~= text then font:SetText(text) end
end

local function MeasureRow(container)
    if not container.font then return end
    local height = container.font:GetStringHeight() + 10
    if container.rowKind == "divider" then
        height = 12
    elseif container.progressBarOnly then
        height = 30
    elseif container.detailFonts then
        for index, font in ipairs(container.detailFonts) do
            if index <= #container.subTexts then
                if font.layoutOffset ~= height then
                    font:ClearAllPoints()
                    font:SetPoint("TOPLEFT", container, "TOPLEFT", INDENT, -height)
                    font.layoutOffset = height
                end
                height = height + font:GetStringHeight() + DETAIL_GAP
            end
        end
        height = height + 5
    else
        height = height + (container.extraContentHeight or 0)
    end
    if container.IconButton or container.RaidIconButton then height = math.max(height, 30) end
    if container:GetHeight() ~= height then
        if CurrentStep:CanSafelyHide(container) then
            container:SetHeight(height)
        else
            CurrentStep.layoutDirty = true
        end
    end
end

local function AcquireRow(self, list, key, kind, text, extra, color, dash)
    local role = color and APR:ResolveTextColorRole(color, "title") or (extra and "title" or "base")
    local container = list[key]
    if container and (container.rowKind ~= kind or container.hiddenInCombat) then
        self:ReleaseRow(list, key)
        container = nil
    end
    if not container then
        container = APR:CreateStepTextContainer(CurrentStepFrame_StepHolder, WIDTH, text or "", extra,
            color, APR.settings.profile.currentStepbackgroundColorAlpha, dash, "currentStep")
        container.rowKind, container.key = kind, key
        container.font:ClearAllPoints()
        container.font:SetPoint("TOPLEFT", PADDING, -5)
        container.font:SetWidth(WIDTH - PADDING * 2)
        container.textRole = role
        APR:RegisterFontString(container.font, "currentStep", {
            role = role,
            onApplied = function() MeasureRow(container) end,
        })
        list[key] = container
    end
    self:TouchRow(container)
    container.showLeadingDash = dash ~= false
    SetText(container.font, (container.showLeadingDash and "- " or "") .. (text or ""))
    if container.textRole ~= role then
        if APR.SetFontStringRole then APR:SetFontStringRole(container.font, role) end
        container.textRole = role
    end
    MeasureRow(container)
    return container
end

local function QuestTooltip(container)
    GameTooltip:SetOwner(container, "ANCHOR_BOTTOM")
    APR:AddQuestTooltipDetails(GameTooltip, container.questID, {
        isScenario = container.isScenario,
        objectiveIndex = container.objectiveIndex,
        objectiveText = container.objectiveText,
        includeCampaign = not container.isScenario,
        includeStoryline = not container.isScenario,
    })
    GameTooltip:Show()
end

local function HideTooltip() GameTooltip:Hide() end

function CurrentStep:AddQuestSteps(questID, text, objectiveIndex, isScenario, noTooltip, dash, color)
    local profile = APR:GetSettingsProfile()
    if not profile or not profile.currentStepShow then return end
    local key = questID .. "-" .. (objectiveIndex or 0)
    local container = AcquireRow(self, self.questsList, key, "objective", text, false, color, dash)
    container.questID, container.objectiveIndex = questID, objectiveIndex
    container.objectiveText, container.isScenario = text, isScenario
    container:SetScript("OnEnter", not noTooltip and QuestTooltip or nil)
    container:SetScript("OnLeave", not noTooltip and HideTooltip or nil)
    container.isQuestObjective = not isScenario and not noTooltip and tonumber(objectiveIndex) ~= nil
    self:UpdateQuestObjectiveProgressBar(container, questID, objectiveIndex)
    self:MaybeAttachRaidIconButton(key)
    self:ReOrderQuestSteps()
end

function CurrentStep:UpdateQuestStep(questID, text, objectiveIndex)
    if not APR.settings.profile.currentStepShow then return end
    local container = self.questsList[questID .. "-" .. objectiveIndex]
    if not container then return end
    container.objectiveText = text
    SetText(container.font, (container.showLeadingDash and "- " or "") .. text)
    self:UpdateQuestObjectiveProgressBar(container, questID, objectiveIndex)
    MeasureRow(container)
    self:ReOrderQuestSteps()
end

local function ResolveDetail(entry)
    local questID, itemID, name
    if type(entry) == "table" then
        questID, itemID = entry.questID, entry.itemID or entry.ItemID
        name = entry.questName or entry.itemName
    else
        questID = entry
    end
    if not name and itemID then name = C_Item.GetItemInfo(itemID) end
    if not name and questID then name = C_QuestLog.GetTitleForQuestID(questID) end
    return { questID = questID, itemID = itemID, name = name or UNKNOWN,
        text = "- " .. (name or (tostring(itemID or questID or UNKNOWN) .. " - " .. UNKNOWN)) }
end

local function DetailTooltip(font)
    GameTooltip:SetOwner(font, "ANCHOR_BOTTOM")
    if font.questID then
        APR:AddQuestTooltipDetails(GameTooltip, font.questID, { includeCampaign = true, includeStoryline = true })
    else
        APR:AddTooltipLine(GameTooltip, L["QUEST_INFO"], "currentStep", "base")
    end
    GameTooltip:Show()
end

function CurrentStep:AddQuestStepsWithDetails(key, text, entries)
    if not APR.settings.profile.currentStepShow then return end
    local container = AcquireRow(self, self.questsList, key, "details", text, true, nil, false)
    container.detailFonts = container.detailFonts or {}
    container.subTexts = {}
    for index, entry in ipairs(entries) do
        local detail = ResolveDetail(entry)
        container.subTexts[index] = detail
        local font = container.detailFonts[index]
        if not font then
            font = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            font:SetWordWrap(true)
            font:SetWidth(WIDTH - INDENT - PADDING)
            font:SetJustifyH("LEFT")
            APR:RegisterFontString(font, "currentStep", { role = "base" })
            container.detailFonts[index] = font
        end
        font.questID = detail.questID
        SetText(font, detail.text)
        font:SetScript("OnEnter", DetailTooltip)
        font:SetScript("OnLeave", HideTooltip)
        font:Show()
    end
    for index = #entries + 1, #container.detailFonts do
        local font = container.detailFonts[index]
        font:Hide()
        font:SetText("")
        font.questID = nil
        font:SetScript("OnEnter", nil)
        font:SetScript("OnLeave", nil)
    end
    MeasureRow(container)
    self:MaybeAttachRaidIconButton(key)
    self:ReOrderQuestSteps()
end

function CurrentStep:AddExtraLineText(key, text, color, dash)
    if not APR.settings.profile.currentStepShow then return end
    local navigation = APR.farstrider
    local redirected = navigation and navigation.showOutOfZoneStepContent and
        navigation.NavigationDividerStepKey and self.questsList[navigation.NavigationDividerStepKey] and
        key ~= navigation.ErrorDestinationLineKey
    local questKey = "04_EXTRA_LINE_" .. tostring(key) .. "-EXTRA"
    local list, rowKey = self.questsExtraTextList, key
    if redirected then
        self:ReleaseRow(self.questsExtraTextList, key)
        list, rowKey = self.questsList, questKey
    else
        self:ReleaseRow(self.questsList, questKey)
    end
    local container = AcquireRow(self, list, rowKey, "extra", text, true, color, false)
    container._isManagedExtraLine = true
    container._rawExtraLineText, container._manualLeadingDash = text, dash
    self:MaybeAttachRaidIconButton(rowKey)
    self:ReOrderQuestSteps()
end

local function AddDivider(self, list, key)
    if not APR.settings.profile.currentStepShow then return end
    local container = AcquireRow(self, list, key, "divider", "", true, nil, false)
    if not container.dividerLine then
        container.font:Hide()
        local line = container:CreateTexture(nil, "ARTWORK")
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetHeight(1)
        line:SetPoint("LEFT", container, "LEFT", PADDING, 0)
        line:SetPoint("RIGHT", container, "RIGHT", -PADDING, 0)
        line:SetVertexColor(0.78, 0.66, 0.35, 0.95)
        container.dividerLine = line
        if APR.RegisterSkinTarget then APR:RegisterSkinTarget(container, "divider") end
    end
    container:SetHeight(12)
    self:ReOrderQuestSteps()
end

function CurrentStep:AddExtraLineDivider(key) AddDivider(self, self.questsExtraTextList, key) end
function CurrentStep:AddQuestDivider(key) AddDivider(self, self.questsList, key) end

local function OrderedRows(list, firstKey)
    local rows = {}
    for key, container in pairs(list) do
        if not container.hiddenInCombat and not container.stale then
            rows[#rows + 1] = { key = key, container = container }
        end
    end
    table.sort(rows, function(a, b)
        if a.key == firstKey then return b.key ~= firstKey end
        if b.key == firstKey then return false end
        return tostring(a.key) < tostring(b.key)
    end)
    return rows
end

function CurrentStep:ReOrderQuestSteps()
    self.layoutDirty = true
    if self.contentUpdateActive or not APR.settings.profile.currentStepShow then return end
    self.layoutDirty = false
    local firstKey = APR.farstrider and APR.farstrider.ErrorDestinationLineKey or "00_ERROR_DESTINATION"
    local groups = { OrderedRows(self.questsExtraTextList, firstKey), OrderedRows(self.questsList) }
    local autoCount = 0
    for _, rows in ipairs(groups) do
        for _, entry in ipairs(rows) do
            local row = entry.container
            if row._isManagedExtraLine and row._manualLeadingDash == nil then autoCount = autoCount + 1 end
        end
    end
    local offset = TOP_OFFSET
    for _, rows in ipairs(groups) do
        for _, entry in ipairs(rows) do
            local row = entry.container
            if row._isManagedExtraLine then
                local dash = row._manualLeadingDash
                if dash == nil then dash = autoCount > 1 end
                row.showLeadingDash = dash
                SetText(row.font, (dash and "- " or "") .. row._rawExtraLineText)
            end
            if row.rowKind ~= "divider" then MeasureRow(row) end
            -- Secure descendants also protect their parent's anchors in combat.
            if row.layoutOffset ~= offset then
                if self:CanSafelyHide(row) then
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", CurrentStepScreenPanel, "TOPLEFT", 0, -offset)
                    row.layoutOffset = offset
                else
                    self.layoutDirty = true
                end
            end
            offset = offset + row:GetHeight()
        end
    end
    self.FrameHeight = offset
    if APR.questOrderList and APR.questOrderList.ApplySnapAnchor then APR.questOrderList:ApplySnapAnchor() end
end

function CurrentStep:ReOrderExtraLineText() self:ReOrderQuestSteps() end
function CurrentStep:RefreshTextLayout() self:ReOrderQuestSteps() end
