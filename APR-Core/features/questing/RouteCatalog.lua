-- Read-only route records for browsing: no effective-step construction or route activation.
-- Path mutations reuse the route engine's prerequisites and its single update notification.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.RouteCatalog = {}
local Catalog = APR.RouteCatalog
Catalog.progressStates = {
    notStarted = {label = L["UI_ROUTE_NOT_STARTED"], role = "routeNotStarted"},
    inProgress = {label = L["UI_ROUTE_IN_PROGRESS"], role = "routeInProgress"},
    completed = {label = L["ROUTE_COMPLETED"], role = "routeCompleted"},
}

function Catalog:GetPath()
    return APRCustomPath[APR.PlayerID] or {}
end

function Catalog:Build()
    local records, known, queued = {}, {}, {}
    local progress = APRData[APR.PlayerID] or {}
    local completed = APRZoneCompleted[APR.PlayerID] or {}
    local favorites = APR:GetSettingsProfile().routeFavorites or {}
    for _, label in ipairs(self:GetPath()) do queued[label] = true end
    for key, data in pairs(APR.RouteQuestStepList) do
        if type(data) == "table" and data.label and not data.temporary and not data.hiddenFromSelection then
            local visibility = APR:GetRouteVisibility(key)
            if visibility ~= "hidden" or queued[data.label] then
                local author, community, description = APR:GetRouteAttribution(key)
                local record = {key = key, label = data.label, expansion = data.expansion or APR.EXPANSIONS.Custom,
                    category = data.category or APR.CATEGORIES.Leveling, author = author, community = community,
                    description = description, visibility = visibility, favorite = favorites[key] == true}
                -- Queuing or resetting initializes step 1 without starting the route.
                -- Only the engine's completion flag confirms completion, not an x/x counter.
                local started = APR.ActiveRoute == key or (type(progress[key]) == "number" and progress[key] > 1)
                record.progressState = completed[data.label] and "completed" or started and "inProgress" or "notStarted"
                record.status = self.progressStates[record.progressState].label
                if record.progressState == "inProgress" and type(progress[key]) == "number" then
                    local step = math.max(0, progress[key] - (progress[key .. "-SkippedStep"] or 0))
                    local total = progress[key .. "-TotalSteps"]
                    record.status = tostring(step) .. " / " .. (total and tostring(total) or "?")
                end
                record.search = APR:NormalizeSearchText(table.concat({record.label, key, record.expansion, record.category, author}, " "))
                record.sortName = APR:NormalizeSearchText(record.label)
                records[#records + 1], known[data.label] = record, true
            end
        end
    end
    -- A deleted/imported route remains removable from the saved path.
    for label in pairs(queued) do
        if not known[label] then
            records[#records + 1] = {key = "missing:" .. label, label = label, expansion = "", category = "", author = "APR",
                visibility = "hidden", status = UNAVAILABLE, search = APR:NormalizeSearchText(label), sortName = APR:NormalizeSearchText(label)}
        end
    end
    return records
end

function Catalog:Matches(record, filters, ignoreCategory)
    if record.visibility == "hidden" then return false end
    if filters.expansion and filters.expansion ~= record.expansion then return false end
    if filters.community and not record.community then return false end
    if filters.favorites and not record.favorite then return false end
    if not ignoreCategory and filters.category and record.category ~= filters.category then return false end
    for word in APR:NormalizeSearchText(filters.query or ""):gmatch("%S+") do
        if not record.search:find(word, 1, true) then return false end
    end
    return true
end

function Catalog:Filter(records, filters)
    local result = {}
    for _, record in ipairs(records) do
        if self:Matches(record, filters) then result[#result + 1] = record end
    end
    local key, descending = filters.sort or "label", filters.descending
    table.sort(result, function(a, b)
        -- Availability stays first even when the player reverses a column's sort order.
        if (a.visibility == "visible") ~= (b.visibility == "visible") then return a.visibility == "visible" end
        local left, right = APR:NormalizeSearchText(a[key] or ""), APR:NormalizeSearchText(b[key] or "")
        if left ~= right then
            if descending then return left > right end
            return left < right
        end
        if a.sortName ~= b.sortName then return a.sortName < b.sortName end
        return a.key < b.key
    end)
    return result
end

function Catalog:GetCategories(records, filters)
    local options, seen = {{value = false, label = ALL}}, {}
    local scope = {expansion = filters.expansion, community = filters.community}
    for _, record in ipairs(records) do
        if self:Matches(record, scope, true) and not seen[record.category] then
            seen[record.category] = true
            options[#options + 1] = {value = record.category, label = record.category}
        end
    end
    table.sort(options, function(a, b)
        if a.value == false then return b.value ~= false end
        if b.value == false then return false end
        return a.label < b.label
    end)
    return options, seen
end

function Catalog:GetNavigation(records)
    local counts, total, community = {}, 0, 0
    for _, record in ipairs(records) do
        if record.visibility ~= "hidden" then
            total = total + 1
            if record.community then community = community + 1 end
            counts[record.expansion] = (counts[record.expansion] or 0) + 1
        end
    end
    local result = {{value = "all", label = ALL, count = total},
        {value = "community", label = CLUB_FINDER_COMMUNITY_TYPE, count = community},
        {heading = true, label = EXPANSION_FILTER_TEXT}}
    local expansions = APR:GetRouteSelectionExpansions()
    -- The most recent expansion is nearest to the primary actions; Custom remains last.
    for index = #expansions, 1, -1 do
        local expansion = expansions[index]
        if expansion ~= APR.EXPANSIONS.Custom then
            result[#result + 1] = {value = expansion, label = expansion, count = counts[expansion] or 0}
        end
    end
    if counts[APR.EXPANSIONS.Custom] then
        result[#result + 1] = {value = APR.EXPANSIONS.Custom, label = APR.EXPANSIONS.Custom, count = counts[APR.EXPANSIONS.Custom]}
    end
    return result
end

function Catalog:GetPathRecords(records)
    local byLabel, result = {}, {}
    for _, record in ipairs(records) do byLabel[record.label] = record end
    for _, label in ipairs(self:GetPath()) do
        if byLabel[label] then result[#result + 1] = byLabel[label] end
    end
    return result
end

function Catalog:ToggleFavorite(record)
    if not record or record.visibility == "hidden" then return end
    local profile = APR:GetSettingsProfile()
    profile.routeFavorites = profile.routeFavorites or {}
    profile.routeFavorites[record.key] = not profile.routeFavorites[record.key] or nil
    record.favorite = profile.routeFavorites[record.key] == true
end

function Catalog:ChangePath(record, action, restart)
    if not record then return false end
    local path, index = self:GetPath()
    for i, label in ipairs(path) do if label == record.label then index = i; break end end
    if action == "add" then
        if index or APR:GetRouteVisibility(record.key) ~= "visible" then return false end
        if restart then APR:ResetRoute(record.key)
        elseif APRData[APR.PlayerID][record.key] then APR:CheckRouteChanges(record.key) end
        if not APR:AddRouteToCustomPathByKey(record.key) then return false end
    elseif action == "remove" and index then table.remove(path, index)
    elseif action == "up" and index and index > 1 then path[index - 1], path[index] = path[index], path[index - 1]
    elseif action == "down" and index and index < #path then path[index + 1], path[index] = path[index], path[index + 1]
    else return false end
    APR.routeconfig:SendCustomPathUpdate()
    return true
end
