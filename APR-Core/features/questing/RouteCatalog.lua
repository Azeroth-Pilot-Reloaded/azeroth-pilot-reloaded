-- Builds searchable route records without activating routes or evaluating their effective steps.
-- Authorship is explicit metadata, never inferred from filenames or Git commit authors.

APR.RouteCatalog = {}
local Catalog = APR.RouteCatalog
-- Maintainer-approved attribution; the exception is named explicitly in the route's own label.
local provenance = { ["84-EclipseGlaives-10-to-70"] = {author = "EclipseGlaives", community = true} }

local function AuthorText(data, attribution)
    if type(data.author) == "string" and data.author ~= "" then return data.author end
    local names = {}
    for _, name in ipairs(type(data.authors) == "table" and data.authors or {}) do
        if type(name) == "string" and name ~= "" then names[#names + 1] = name end
    end
    return #names > 0 and table.concat(names, ", ") or attribution and attribution.author or "APR"
end

function Catalog:Build()
    local records = {}
    local progress = APRData and APRData[APR.PlayerID] or {}
    local completed = APRZoneCompleted and APRZoneCompleted[APR.PlayerID] or {}
    local favorites = APR.settings.profile.routeFavorites or {}
    local queued, known = {}, {}
    for _, label in ipairs(APRCustomPath[APR.PlayerID] or {}) do queued[label] = true end
    for key, data in pairs(APR.RouteQuestStepList) do
        if type(data) == "table" and data.label and not data.temporary and not data.hiddenFromSelection then
            local visibility = APR:GetRouteVisibility(key)
            if visibility ~= "hidden" or queued[data.label] then
                known[data.label] = true
                local attribution = provenance[key]
                local record = { key = key, label = data.label, expansion = data.expansion or "",
                    category = data.category or APR.CATEGORIES.Leveling, author = AuthorText(data, attribution),
                    community = data.community == true or data.source == "community" or attribution and attribution.community,
                    visibility = visibility,
                    favorite = favorites[key] == true, completed = completed[data.label] == true,
                    progress = progress[key] or 0, total = #(data.steps or {}), description = data.description }
                record.search = APR:NormalizeSearchText(table.concat({record.label, key, record.expansion,
                    record.category, record.author}, " "))
                records[#records + 1] = record
            end
        end
    end
    -- Removed/imported routes must remain removable from an existing saved path.
    for label in pairs(queued) do
        if not known[label] then
            records[#records + 1] = { key = "missing:" .. label, label = label, expansion = "", category = "",
                author = APR:LocalizeUI("AUTHOR_UNKNOWN"), visibility = "hidden", progress = 0, total = 0,
                search = APR:NormalizeSearchText(label) }
        end
    end
    table.sort(records, function(a, b)
        local left, right = APR:NormalizeSearchText(a.label), APR:NormalizeSearchText(b.label)
        return left == right and a.key < b.key or left < right
    end)
    return records
end

-- Path order is authoritative; filtering never changes SavedVariables or starts a route.
function Catalog:Filter(records, filters)
    filters = filters or {}
    local result, pathIndex = {}, {}
    for index, label in ipairs(APRCustomPath[APR.PlayerID] or {}) do pathIndex[label] = index end
    local query = APR:NormalizeSearchText(filters.query or "")
    for _, record in ipairs(records) do
        record.pathIndex = pathIndex[record.label]
        local matches = (not filters.expansion or filters.expansion == record.expansion)
            and (record.visibility ~= "hidden" or filters.facet == "path")
            and (not filters.category or filters.category == record.category)
            and (filters.facet ~= "community" or record.community)
            and (filters.facet ~= "favorites" or record.favorite)
            and (filters.facet ~= "path" or record.pathIndex)
        for word in query:gmatch("%S+") do
            if not record.search:find(word, 1, true) then matches = false; break end
        end
        if matches then result[#result + 1] = record end
    end
    if filters.facet == "path" then table.sort(result, function(a, b) return a.pathIndex < b.pathIndex end) end
    return result
end

function Catalog:GetOptions(records, field, title)
    local options, seen = { { label = title, value = false } }, {}
    for _, record in ipairs(records) do
        local value = record[field]
        if value ~= "" and not seen[value] then
            seen[value] = true
            options[#options + 1] = { label = value, value = value }
        end
    end
    table.sort(options, function(a, b)
        if a.value == false then return b.value ~= false end
        if b.value == false then return false end
        return a.label < b.label
    end)
    return options
end

-- Reuse dependency-aware insertion and the existing path notification for all mutations.
function Catalog:ChangePath(record, action)
    local path = APRCustomPath[APR.PlayerID]
    if not record or not path then return false end
    local index
    for i, label in ipairs(path) do if label == record.label then index = i; break end end
    if action == "add" then
        if APR:GetRouteVisibility(record.key) ~= "visible" then return false end
        APR:AddRouteToCustomPathByKey(record.key)
    elseif action == "remove" and index then
        table.remove(path, index)
    elseif action == "up" and index and index > 1 then
        path[index - 1], path[index] = path[index], path[index - 1]
    elseif action == "down" and index and index < #path then
        path[index + 1], path[index] = path[index], path[index + 1]
    else return false end
    APR.routeconfig:SendCustomPathUpdate()
    return true
end
