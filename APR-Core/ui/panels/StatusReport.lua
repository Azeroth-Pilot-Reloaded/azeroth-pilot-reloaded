-- Workspace diagnostic overview and bounded Lua-error table; exports are independent snapshots.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local UI = APR.UI
local NO_ACTIVE = L["UI_STATUS_NO_ACTIVE_ROUTE"]
-- VAS_REALM_LABEL belongs to optional store UI and can be absent during normal gameplay.
local REALM_LABEL = (FRIENDS_LIST_REALM or UNKNOWN):gsub("%s*：%s*$", ""):gsub("%s*:%s*$", "")
local hideIdentity = true
APR.StatusPanel = {}
local Panel = APR.StatusPanel

local function GetCurrentStepInfo()
    local step, index = APR:PeekCurrentStep()
    if not index then return NO_ACTIVE end
    local _, action = APR:GetStepString(step)
    return tostring(index) .. ", " .. (action or UNKNOWN)
end

local function PublicNumber(value)
    if not APR:CanAccessValue(value) then return end
    if type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then
        return value
    end
end

function APR:getStatusReportInfos()
    local coordinates, worldCoordinates
    -- Coordinates can be unavailable or restricted in instances; guard before arithmetic.
    if self:IsInstanceWithUI() then
        local mapID = C_Map and C_Map.GetBestMapForUnit and PublicNumber(C_Map.GetBestMapForUnit("player"))
        if mapID and C_Map.GetPlayerMapPosition then
            local position = C_Map.GetPlayerMapPosition(mapID, "player")
            if self:CanAccessValue(position) and position then
                local x, y = PublicNumber(position.x), PublicNumber(position.y)
                if x and y then coordinates = self.coordinate:RoundCoords(x * 100, y * 100, 2) end
            end
        end
        if UnitPosition then
            -- WoW returns north/south first; APR displays east/west as X.
            local y, x = UnitPosition("player")
            x, y = PublicNumber(x), PublicNumber(y)
            if x and y then worldCoordinates = self.coordinate:RoundCoords(x, y, 2) end
        end
    end
    local currentStep = GetCurrentStepInfo()
    local continentID = self:GetContinent()
    local continent = continentID and self:GetMapInfoCached(continentID)
    local infoTable = {
        aprVersion = { L["UI_STATUS_ADDON_VERSION"], APR.version or UNKNOWN },
        wowVersion = { L["UI_STATUS_CLIENT_VERSION"], select(1, GetBuildInfo()) },
        clientLanguage = { LANGUAGE, GetLocale() },
        currentTime = { L["UI_STATUS_DATE"], date() },
        serverType = { L["UI_STATUS_SERVER_TYPE"], GetCVar("portal") or UNKNOWN },
        currentRoute = { L["ROUTE"], APR.ActiveRoute or NO_ACTIVE },
        currentStep = { L["CURRENT_STEP"], currentStep or NO_ACTIVE },
        currentZone = { ZONE, GetRealZoneText() or UNKNOWN },
        currentContinent = { CONTINENT, continent and continent.name or UNKNOWN },
        currentCoords = { L["UI_STATUS_COORDINATES"], coordinates or UNKNOWN },
        currentWorldCoords = { L["UI_STATUS_WORLD_COORDINATES"], worldCoordinates or UNKNOWN },
        charFaction = { FACTION, APR.Faction or UNKNOWN },
        charLevel = { LEVEL, APR.Level or UNKNOWN },
        charClass = { CLASS, APR:GetClassNameById(APR.ClassId) or UNKNOWN }
    }

    if not hideIdentity then
        infoTable.charName = { NAME, self.Username or UNKNOWN }
        infoTable.charRealm = { REALM_LABEL, GetRealmName() or UNKNOWN }
    end
    return infoTable
end

-- Redact after formatting as well: character identifiers can also appear in an error stack or step data.
function APR:RedactStatusText(text)
    if not hideIdentity then return text end
    for _, value in ipairs({self.PlayerID or "", self.UserID or "", self.Username or "", GetRealmName() or ""}) do
        if self:CanAccessValue(value) and type(value) == "string" and #value > 1 then
            local pattern = value:gsub("([^%w])", "%%%1")
            text = text:gsub(pattern, function() return "<hidden>" end)
        end
    end
    return text
end

local function MarkdownText(value)
    if not APR:CanAccessValue(value) then return UNKNOWN end
    -- Redact before escaping so realm names containing Markdown punctuation are still matched.
    local text = APR:RedactStatusText(tostring(value))
    return (text:gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("([\\`*_%[%]<>#|~])", "\\%1"))
end

local function AddField(lines, label, value, depth)
    local indent = string.rep("  ", depth or 0)
    local text = MarkdownText(value):gsub("\n", "\n" .. indent .. "  ")
    lines[#lines + 1] = indent .. "- **" .. MarkdownText(label):gsub("\n", " ") .. "**: " .. text
end

-- Retain the runtime step's keys in a readable list; bound unexpected tables like FormatDebugTable.
local function AddStepData(lines, step)
    local visited, entries, limit = {}, 0, 20000
    local function append(key, value, depth)
        if not APR:CanAccessValue(value) then
            AddField(lines, key, UNKNOWN, depth)
        elseif type(value) ~= "table" then
            AddField(lines, key, type(value) == "boolean" and tostring(value) or value, depth)
        elseif APR.CanAccessTable and not APR:CanAccessTable(value) then
            AddField(lines, key, UNKNOWN, depth)
        elseif visited[value] or depth >= 10 or entries >= limit then
            AddField(lines, key, visited[value] and "<circular>" or depth >= 10 and "<max-depth>" or "<entry-limit>", depth)
        else
            local keys, truncated = {}, false
            for childKey in pairs(value) do
                if entries >= limit then truncated = true; break end
                entries = entries + 1
                if APR:CanAccessValue(childKey) and (type(childKey) == "string" or type(childKey) == "number") then
                    keys[#keys + 1] = childKey
                end
            end
            table.sort(keys, function(a, b)
                if type(a) == type(b) then return a < b end
                return type(a) == "number"
            end)
            AddField(lines, key, #keys == 0 and not truncated and "{}" or "", depth)
            visited[value] = true
            for _, childKey in ipairs(keys) do append(childKey, value[childKey], depth + 1) end
            if truncated then AddField(lines, "…", "<entry-limit>", depth + 1) end
            visited[value] = nil
        end
    end
    append(L["CURRENT_STEP"], step, 0)
end

function APR:ExportStatusReport()
    Panel.exportedError = nil
    local info = self:getStatusReportInfos()
    info.charName = info.charName or {NAME, NARRATION_STATUS_HIDDEN}
    info.charRealm = info.charRealm or {REALM_LABEL, NARRATION_STATUS_HIDDEN}
    local lines = {"# Azeroth Pilot Reloaded — " .. MarkdownText(L["STATUS"])}
    local function section(title, keys)
        lines[#lines + 1] = "\n## " .. MarkdownText(title) .. "\n"
        for _, key in ipairs(keys or {}) do AddField(lines, info[key][1], info[key][2]) end
    end
    section(L["UI_STATUS_ADDON_CLIENT"], {"aprVersion", "wowVersion", "clientLanguage", "serverType", "currentTime"})
    AddField(lines, L["UI_THEME"], self:GetSkinProviderName() or "WoW")
    section(L["ROUTE"], {"currentRoute", "currentStep", "currentContinent", "currentZone", "currentCoords", "currentWorldCoords"})
    section(CHARACTER, {"charName", "charRealm", "charFaction", "charClass", "charLevel"})
    AddField(lines, L["UI_REDACT"], hideIdentity and YES or NO)

    local step = self:PeekCurrentStep()
    if step then
        section(L["UI_STATUS_STEP_DATA"])
        AddStepData(lines, step)
    end

    local log = self.ErrorLog
    local errors = log and log.entries or {}
    section(L["UI_LUA_ERRORS"] .. " (" .. #errors .. ")")
    AddField(lines, L["UI_STATUS_ERROR_CAPTURE"], log and log.provider or "unavailable")
    lines[#lines + 1] = "\n" .. MarkdownText(L["UI_ERRORS_HELP"])
    if #errors == 0 then
        lines[#lines + 1] = "\n" .. MarkdownText(log and log.provider ~= "unavailable" and L["UI_ERRORS_EMPTY"] or L["UI_ERRORS_UNAVAILABLE"])
    end
    for index, entry in ipairs(errors) do
        lines[#lines + 1] = "\n### " .. index .. ". " .. MarkdownText(entry.source or "APR") .. "\n"
        lines[#lines + 1] = UI:FormatCodeBlock(self:RedactStatusText(self:FormatDebugTable(entry)), "lua")
    end
    UI:ShowTextReport(L["STATUS_EXPORT"], table.concat(lines, "\n"), self.StatusFrame)
end

local groups = {
    {title = L["UI_STATUS_ADDON_CLIENT"], width = 0.27, rows = {
        {"aprVersion", "wowVersion"}, {"serverType", "clientLanguage"}, {"currentTime"},
    }},
    {title = L["ROUTE"], width = 0.46, rows = {
        {"currentRoute", "currentCoords"}, {"currentStep", "currentWorldCoords"}, {"currentContinent"}, {"currentZone"},
    }},
    {title = CHARACTER, width = 0.27, rows = {
        {"charName", "charRealm"}, {"charFaction"}, {"charClass"}, {"charLevel"},
    }},
}

function Panel:Refresh()
    if not self.frame then return end
    local info = APR:getStatusReportInfos()
    info.charName = info.charName or {NAME, NARRATION_STATUS_HIDDEN}
    info.charRealm = info.charRealm or {REALM_LABEL, NARRATION_STATUS_HIDDEN}
    for key, field in pairs(self.fields) do
        local item = info[key]
        field.label:SetText(item[1])
        field.value:SetText(tostring(item[2]))
    end
    UI:SetButtonActive(self.identity, hideIdentity)
    self.identity.icon:SetShown(hideIdentity)
    self:RefreshErrors()
    self:Layout()
end

function Panel:RefreshErrors()
    local log = APR.ErrorLog
    local rows = {}
    for index = #(log and log.entries or {}), 1, -1 do rows[#rows + 1] = log.entries[index] end
    self.errors:SetItems(rows, true)
    self.empty:SetShown(#rows == 0)
    self.empty:SetText(log and log.provider ~= "unavailable" and L["UI_ERRORS_EMPTY"] or L["UI_ERRORS_UNAVAILABLE"])
    self.errorPanel.title:SetText(L["UI_LUA_ERRORS"] .. " (" .. #rows .. ")")
    self.revision = log and log.revision
end

function Panel:Layout()
    if not self.frame or not self.groups or self.layingOut then return end
    self.layingOut = true
    local width = math.max(1, self.infoScroll:GetWidth())
    local padding, gap = 14, 12
    local available = math.max(1, width - gap * (#groups - 1))
    local x, maximum = 0, 0
    for index, group in ipairs(self.groups) do
        local definition = groups[index]
        local column = available * definition.width
        local innerWidth = math.max(1, column - padding * 2)
        group.card:ClearAllPoints()
        group.card:SetPoint("TOPLEFT", self.infoContent, "TOPLEFT", x, 0)
        group.card:SetWidth(column)
        group.title:SetWidth(innerWidth)
        local y = padding + group.title:GetStringHeight() + 18
        for _, row in ipairs(definition.rows) do
            local fieldWidth = math.max(1, (innerWidth - gap * (#row - 1)) / #row)
            local labelHeight, valueHeight = 0, 0
            -- Measure at the final width; translated labels and route identifiers may wrap.
            for _, key in ipairs(row) do
                local field = self.fields[key]
                field.label:SetWidth(fieldWidth)
                field.value:SetWidth(fieldWidth)
                labelHeight = math.max(labelHeight, field.label:GetStringHeight())
                valueHeight = math.max(valueHeight, field.value:GetStringHeight())
            end
            for fieldIndex, key in ipairs(row) do
                local field = self.fields[key]
                local left = padding + (fieldIndex - 1) * (fieldWidth + gap)
                field.label:ClearAllPoints()
                field.label:SetPoint("TOPLEFT", group.card, "TOPLEFT", left, -y)
                field.value:ClearAllPoints()
                field.value:SetPoint("TOPLEFT", group.card, "TOPLEFT", left, -(y + labelHeight + 5))
            end
            y = y + labelHeight + 5 + valueHeight + 16
        end
        maximum, x = math.max(maximum, y - 16 + padding), x + column + gap
    end
    for _, group in ipairs(self.groups) do group.card:SetHeight(maximum) end
    self.infoContent:SetSize(width, maximum)
    -- Fit the cards when possible; retain a usable error table when large fonts need scrolling.
    local height = math.min(maximum + 52, math.max(160, self.frame.content:GetHeight() - 240))
    self.infoPanel:SetHeight(height)
    self.errorPanel:ClearAllPoints()
    self.errorPanel:SetPoint("TOPLEFT", self.infoPanel, "BOTTOMLEFT", 0, -12)
    self.errorPanel:SetPoint("BOTTOMRIGHT", self.frame.content, "BOTTOMRIGHT", 0, 48)
    self.layingOut = false
end

function Panel:Create(parent)
    self.frame = parent and UI:Page(parent) or UI:Window("APRStatusReport", L["STATUS"], 1120, 780, "library", "logo")
    APR.StatusFrame = self.frame
    local root = self.frame.content
    self.infoPanel = UI:Section(root, OVERVIEW)
    self.infoPanel:SetPoint("TOPLEFT"); self.infoPanel:SetPoint("TOPRIGHT")
    self.infoScroll = UI:Scroll(self.infoPanel)
    self.infoScroll:SetPoint("TOPLEFT", 14, -42); self.infoScroll:SetPoint("BOTTOMRIGHT", -28, 10)
    self.infoContent = CreateFrame("Frame", nil, self.infoScroll)
    self.infoScroll:SetScrollChild(self.infoContent)
    self.groups, self.fields = {}, {}
    for index, definition in ipairs(groups) do
        local card = UI:Panel(self.infoContent, "borderedPanel", "library")
        local group = {card = card, title = UI:Label(card, definition.title, 13, "accent")}
        group.title:SetPoint("TOPLEFT", 14, -14)
        group.title:SetWordWrap(true)
        group.title:SetNonSpaceWrap(true)
        self.groups[index] = group
        for _, row in ipairs(definition.rows) do
            for _, key in ipairs(row) do
                local field = {label = UI:Label(card, "", 11), value = UI:Label(card, "", 14)}
                field.label:SetAlpha(0.72)
                field.label:SetWordWrap(true)
                field.label:SetNonSpaceWrap(true)
                field.value:SetWordWrap(true)
                field.value:SetNonSpaceWrap(true)
                self.fields[key] = field
            end
        end
    end
    self.errorPanel = UI:Section(root, L["UI_LUA_ERRORS"])
    local source = UI:Label(self.errorPanel, SOURCE, 11, "muted")
    source:SetPoint("TOPLEFT", 12, -40)
    local count = UI:Label(self.errorPanel, L["UI_ERROR_COUNT"], 11, "muted")
    count:SetPoint("TOPLEFT", 190, -40)
    local last = UI:Label(self.errorPanel, L["UI_ERROR_LAST"], 11, "muted")
    last:SetPoint("TOPLEFT", 260, -40)
    local message = UI:Label(self.errorPanel, L["UI_ERROR_MESSAGE"], 11, "muted")
    message:SetPoint("TOPLEFT", 350, -40)
    local scroll = UI:Scroll(self.errorPanel)
    scroll:SetPoint("TOPLEFT", 10, -65); scroll:SetPoint("BOTTOMRIGHT", -28, 35)
    self.errors = APR.VirtualList:New(scroll, function(container)
        local row = UI:Button(container, "", 1, function(button)
            if button.item then
                self.exportedError = button.item
                UI:ShowTextReport(L["UI_LUA_ERRORS"], APR:RedactStatusText(APR:FormatDebugTable(button.item)), self.frame, "lua")
            end
        end, "flat")
        row.source = UI:Label(row, "", 11, "error"); row.source:SetPoint("LEFT", 4, 0); row.source:SetWidth(170)
        row.count = UI:Label(row, "", 11); row.count:SetPoint("LEFT", 184, 0); row.count:SetWidth(58)
        row.last = UI:Label(row, "", 11); row.last:SetPoint("LEFT", 254, 0); row.last:SetWidth(82)
        row.message = UI:Label(row, "", 11); row.message:SetPoint("LEFT", 344, 0); row.message:SetPoint("RIGHT", -8, 0)
        row.source:SetWordWrap(false); row.message:SetWordWrap(false)
        UI:Tooltip(row, function() return row.item and APR:RedactStatusText(row.item.message) end, L["UI_ERROR_OPEN"])
        return row
    end, function(row, entry)
        row.source:SetText(entry.source)
        row.count:SetText(entry.count)
        row.last:SetText(date("%H:%M:%S", entry.last))
        row.message:SetText(APR:RedactStatusText(entry.message):gsub("[\r\n]+", " "))
    end, 28)
    self.empty = UI:Label(self.errorPanel, "", 12, "muted")
    self.empty:SetPoint("TOPLEFT", 16, -84); self.empty:SetPoint("TOPRIGHT", -32, -84)
    local note = UI:Label(self.errorPanel, L["UI_ERRORS_HELP"], 11, "muted")
    note:SetPoint("BOTTOMLEFT", 12, 10); note:SetPoint("BOTTOMRIGHT", -12, 10)
    self.identity = UI:Button(root, L["UI_REDACT"], 350, function()
        hideIdentity = not hideIdentity
        self:Refresh()
        local report = UI.reportWindow
        if report and report:IsShown() and report.reportOwner == self.frame then
            if self.exportedError then
                UI:ShowTextReport(L["UI_LUA_ERRORS"], APR:RedactStatusText(APR:FormatDebugTable(self.exportedError)), self.frame, "lua")
            else APR:ExportStatusReport() end
        end
    end)
    UI:ButtonIcon(self.identity, "check", 16)
    self.identity:SetPoint("BOTTOMLEFT")
    local refresh = UI:Button(root, REFRESH, 150, function() self:Refresh() end)
    refresh:SetPoint("LEFT", self.identity, "RIGHT", 10, 0)
    local export = UI:Button(root, L["STATUS_EXPORT"], 190, function() self.exportedError = nil; APR:ExportStatusReport() end)
    export:SetPoint("BOTTOMRIGHT")
    self.frame.IdentityButton, self.frame.CopyButton = self.identity, export
    self.frame:SetScript("OnShow", function()
        self:Refresh()
        self.elapsed = 0
        self.frame:SetScript("OnUpdate", function(_, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed < 1 then return end
            self.elapsed = 0
            if APR.ErrorLog and self.revision ~= APR.ErrorLog.revision then self:RefreshErrors() end
        end)
    end)
    self.frame:HookScript("OnHide", function() self.frame:SetScript("OnUpdate", nil) end)
    root:HookScript("OnSizeChanged", function() self:Layout() end)
    self.infoScroll:HookScript("OnSizeChanged", function() self:Layout() end)
    self:Refresh()
end

function APR:RefreshStatusTextLayout() Panel:Layout() end
function APR:updateStatusFrame() Panel:Refresh() end
function APR:showStatusReport()
    if APR.Workspace then return APR.Workspace:Show("status") end
    if not Panel.frame then Panel:Create() end
    Panel.frame:Show(); Panel:Refresh()
end
function APR:closeStatusReport()
    if APR.Workspace then APR.Workspace:Hide()
    elseif Panel.frame then Panel.frame:Hide() end
end
