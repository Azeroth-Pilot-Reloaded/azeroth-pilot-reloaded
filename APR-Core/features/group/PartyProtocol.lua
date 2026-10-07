-- Validates only the fields consumed by the group UI, with a fixed row budget.
-- Never walk arbitrary received tables: unknown fields are discarded after deserialization.

APR.PartyProtocol = {}
local protocol = APR.PartyProtocol
local MAX_INDEX, MAX_ROWS = 1000000, 128

local function IsInteger(value, minimum)
    return type(value) == "number" and value == value and value >= minimum
        and value <= MAX_INDEX and value % 1 == 0
end

local function Text(value, limit)
    if type(value) ~= "string" or #value > limit then return nil end
    -- Tooltip text is data, never texture/atlas instructions supplied by another player.
    return value:gsub("|H.-|h(.-)|h", "%1"):gsub("|[TA].-|[ta]", "")
        :gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("[%z\1-\8\11\12\14-\31]", "")
end

local function NameParts(value)
    if type(value) ~= "string" or #value == 0 or #value > 128 or value:find("[%c|]") then return end
    local name, realm = value:match("^([^%-]+)%-(.+)$")
    return name or value, realm and realm:gsub("%s", "")
end

function protocol.PlayerKey(value)
    local name, realm = NameParts(value)
    if not name then return end
    local home = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName and GetRealmName() or ""
    return name .. "-" .. (realm or home:gsub("%s", ""))
end

-- Sender is authoritative. Legacy peers may send only a character name in their payload.
function protocol.NormalizeSnapshot(data, sender)
    if type(data) ~= "table" then return nil, "payload_type" end
    local name, realm = NameParts(sender)
    local claimed, claimedRealm = NameParts(data.username)
    if not name or claimed ~= name or (claimedRealm and protocol.PlayerKey(data.username) ~= protocol.PlayerKey(sender)) then
        return nil, "sender_mismatch"
    end
    local home = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName and GetRealmName() or ""
    local displayName = realm and realm ~= home:gsub("%s", "") and (name .. "-" .. realm) or name
    local result = { username = displayName, sender = protocol.PlayerKey(sender) }
    for _, field in ipairs({ "route", "routeFileName" }) do
        if data[field] ~= nil then
            result[field] = Text(data[field], 256)
            if not result[field] then return nil, "route_type" end
        end
    end
    if data.sojournerSkipCampaign ~= nil and type(data.sojournerSkipCampaign) ~= "boolean" then return nil, "campaign_type" end
    result.sojournerSkipCampaign = data.sojournerSkipCampaign == true
    if data.currentStep ~= nil and not IsInteger(data.currentStep, 0) then return nil, "step_range" end
    if data.totalSteps ~= nil and not IsInteger(data.totalSteps, 0) then return nil, "total_range" end
    if data.currentStep and data.totalSteps and data.totalSteps > 0 and data.currentStep > data.totalSteps + 1 then
        return nil, "progress_range"
    end
    result.currentStep, result.totalSteps = data.currentStep, data.totalSteps
    local details = data.stepFrameDetails
    if details == nil then return result end
    if type(details) ~= "table" then return nil, "details_type" end
    result.stepFrameDetails = {}
    if details.progress ~= nil then
        if type(details.progress) ~= "table" then return nil, "progress_type" end
        local progress = {}
        for _, field in ipairs({ "index", "step", "total" }) do
            local value = details.progress[field]
            if value ~= nil and not IsInteger(value, 0) then return nil, "progress_range" end
            progress[field] = value
        end
        result.stepFrameDetails.progress = progress
    end
    local remaining = MAX_ROWS
    for _, field in ipairs({ "extraLines", "questSteps", "fillerSteps" }) do
        local rows = details[field]
        if rows ~= nil then
            if type(rows) ~= "table" then return nil, "rows_type" end
            local clean = {}
            result.stepFrameDetails[field] = clean
            for index = 1, MAX_ROWS + 1 do
                local row = rows[index]
                if row == nil then break end
                remaining = remaining - 1
                if remaining < 0 or type(row) ~= "table" then return nil, "row_budget" end
                local text = Text(row.text, 1024)
                if not text then return nil, "row_text" end
                local entry = { text = text }
                clean[#clean + 1] = entry
                if row.subSteps ~= nil then
                    if type(row.subSteps) ~= "table" then return nil, "substeps_type" end
                    entry.subSteps = {}
                    for subIndex = 1, MAX_ROWS + 1 do
                        local sub = row.subSteps[subIndex]
                        if sub == nil then break end
                        remaining = remaining - 1
                        if remaining < 0 or type(sub) ~= "table" then return nil, "row_budget" end
                        local subText = Text(sub.text, 1024)
                        if not subText then return nil, "row_text" end
                        entry.subSteps[#entry.subSteps + 1] = { text = subText }
                    end
                end
            end
        end
    end
    return result
end
