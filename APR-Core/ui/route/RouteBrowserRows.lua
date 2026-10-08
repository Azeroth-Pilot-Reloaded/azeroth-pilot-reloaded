-- Compact, recycled route rows. Every callback reads the currently bound record, including tooltips.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local UI = APR.UI
APR.RouteBrowserRows = {}
local Rows = APR.RouteBrowserRows

function Rows:Tooltip(row, path)
    local record = row.item
    if not record then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    APR:SetTooltipText(GameTooltip, record.label, "general", "accent")
    local author, community, description = APR:GetRouteAttribution(record.key)
    APR:AddTooltipLine(GameTooltip, string.format(L["AUTHOR"], author), "general", "base", true)
    APR:AddTooltipLine(GameTooltip, SOURCE .. " " .. (community and CLUB_FINDER_COMMUNITY_TYPE or "APR"), "general",
        "muted", true)
    if record.expansion ~= "" then
        APR:AddTooltipLine(GameTooltip, record.expansion .. " · " .. record.category, "general", "base", true)
    end
    local progress = APR.RouteCatalog.progressStates[record.progressState]
    if progress then APR:AddTooltipLine(GameTooltip, progress.label, "general", progress.role, true) end
    if record.status ~= "" and (not progress or record.status ~= progress.label) then
        APR:AddTooltipLine(GameTooltip, record.status, "general", "base", true)
    end
    if record.queued then APR:AddTooltipLine(GameTooltip, L["CUSTOM_PATH"], "general", "accent", true) end
    if description then APR:AddTooltipLine(GameTooltip, description, "general", "base", true) end
    if record.visibility == "hidden" then
        APR:AddTooltipLine(GameTooltip, UNAVAILABLE, "general", "warning", true)
    else
        for _, condition in ipairs(APR:GetUnmetConditions(record.key)) do
            APR:AddTooltipLine(GameTooltip, condition, "general", "warning", true)
        end
    end
    APR:AddTooltipLine(GameTooltip, L[path and "REMOVE_ZONE_FROM_CUSTOM_PATH" or "UI_ROUTE_SHORTCUTS"], "general",
        "muted", true)
    GameTooltip:Show()
end

function Rows:Create(parent, browser, path)
    local row = CreateFrame("Button", nil, parent)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints()
    row.progressMarker = row:CreateTexture(nil, "ARTWORK")
    row.progressMarker:SetPoint("LEFT", 0, 0)
    row.progressMarker:SetSize(2, 14)
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    APR:RegisterThemeRegion(highlight, "accent", 0.10)
    row.name = UI:Label(row, "", 12)
    row.name:SetWordWrap(false)
    row:SetScript("OnEnter", function() self:Tooltip(row, path) end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            APR.RouteCatalog:ChangePath(row.item, path and "remove" or "add", not path and IsShiftKeyDown())
        else
            browser.selectedKey = row.item.key
            browser.list:RefreshVisible(true)
            browser.pathList:RefreshVisible(true)
        end
    end)
    if path then
        row.index = UI:Label(row, "", 11, "muted")
        row.up = UI:IconButton(row, "up", 24, function() APR.RouteCatalog:ChangePath(row.item, "up") end)
        row.down = UI:IconButton(row, "down", 24, function() APR.RouteCatalog:ChangePath(row.item, "down") end)
        UI:Tooltip(row.up, function() return string.format(NARRATION_MOVE_UP_IN_LIST, row.item.label) end)
        UI:Tooltip(row.down, function() return string.format(NARRATION_MOVE_DOWN_IN_LIST, row.item.label) end)
        row.remove = UI:IconButton(row, "remove", 24, function() APR.RouteCatalog:ChangePath(row.item, "remove") end)
        UI:Tooltip(row.remove, REMOVE)
    else
        row.favorite = UI:IconButton(row, "favorite", 24, function()
            APR.RouteCatalog:ToggleFavorite(row.item)
            browser:Refresh()
        end, "flat")
        UI:Tooltip(row.favorite, FAVORITES)
        row.category = UI:Label(row, "", 11)
        row.author = UI:Label(row, "", 11)
        row.status = UI:Label(row, "", 11)
        for _, field in ipairs({ "category", "author", "status" }) do row[field]:SetWordWrap(false) end
        row.add = UI:IconButton(row, "add", 24,
            function() APR.RouteCatalog:ChangePath(row.item, "add", IsShiftKeyDown()) end)
        UI:Tooltip(row.add, ADD, L["UI_ROUTE_SHORTCUTS"])
    end
    return row
end

local function Place(region, parent, left, width)
    region:ClearAllPoints()
    region:SetPoint("LEFT", parent, "LEFT", left, 0)
    region:SetSize(math.max(1, width), 24)
end

-- Narrow windows prioritize names; authors and progress remain available in tooltips.
function Rows:Columns(width)
    local author = width >= 610 and 110 or 0
    local status, category = width >= 500 and 74 or 0, 108
    local name = math.max(90, width - author - category - status - 58)
    return {
        name = { 28, name },
        category = { 28 + name, category },
        author = { 28 + name + category, author },
        status = { 28 + name + category + author, status },
        add = { width - 26, 24 }
    }
end

function Rows:Bind(row, record, index, browser, path)
    local selected = browser.selectedKey == record.key
    APR:RegisterThemeRegion(row.background, selected and "selection" or "stripe",
        selected and 0.3 or index % 2 == 0 and 0.22 or 0)
    local width = row:GetWidth()
    local progress = APR.RouteCatalog.progressStates[record.progressState]
    local role = record.visibility == "visible" and progress and progress.role or "muted"
    row.progressMarker:SetShown(progress ~= nil)
    if progress then APR:RegisterThemeRegion(row.progressMarker, progress.role) end
    row.name:SetText(record.label)
    APR:SetFontStringRole(row.name, role)
    if path then
        row.index:SetText(tostring(index))
        Place(row.index, row, 4, 24)
        Place(row.name, row, 28, width - 104)
        Place(row.up, row, width - 74, 24)
        Place(row.down, row, width - 50, 24)
        Place(row.remove, row, width - 26, 24)
        row.up:SetEnabled(index > 1)
        row.down:SetEnabled(index < #APR.RouteCatalog:GetPath())
    else
        local columns = self:Columns(width)
        for _, key in ipairs({ "name", "category", "author", "status", "add" }) do
            Place(row[key], row, unpack(columns[key]))
            if key ~= "add" then row[key]:SetWidth(math.max(1, columns[key][2] - 8)) end
        end
        Place(row.favorite, row, 0, 24)
        UI:SetIcon(row.favorite.icon, record.favorite and "favorite" or "favorite-outline")
        row.favorite.icon:SetAlpha(record.favorite and 1 or 0.7)
        row.category:SetText(record.category)
        row.author:SetText(record.author)
        APR:SetFontStringRole(row.author, record.community and "accent" or "base")
        row.author:SetShown(columns.author[2] > 0)
        row.status:SetShown(columns.status[2] > 0)
        row.status:SetText(record.status)
        APR:SetFontStringRole(row.status, progress and progress.role or "muted")
        row.add:SetEnabled(record.visibility == "visible" and not record.queued)
    end
end
