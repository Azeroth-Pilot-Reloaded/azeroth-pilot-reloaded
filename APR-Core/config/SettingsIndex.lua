-- Indexes the existing AceConfig definitions, keeping setters, dependencies and descriptions authoritative.
-- The quick settings view edits only supported toggles; other controls open their advanced group.

APR.SettingsIndex = {}
local Index = APR.SettingsIndex
local essential = { enableAddon = 1, currentStepShow = 2, showArrow = 3, showQuestOrderList = 4,
    showGroup = 5, autoAcceptQuestRoute = 6, autoHandIn = 7, autoSkipCutScene = 8 }

local function Resolve(value, info)
    if type(value) == "function" then return value(info) end
    return value
end

function Index:Build()
    local records = {}
    local function visit(node, path, labels, inherited)
        local hidden = inherited.hidden or Resolve(node.hidden, path)
        if hidden then return end
        local state = { get = node.get or inherited.get, set = node.set or inherited.set,
            disabled = inherited.disabled or Resolve(node.disabled, path) }
        for key, option in pairs(node.args or {}) do
            local info, trail = {}, {}
            for i, value in ipairs(path) do info[i] = value end
            for i, value in ipairs(labels) do trail[i] = value end
            info[#info + 1] = key
            local name = tostring(Resolve(option.name, info) or key)
            if option.type == "group" then
                trail[#trail + 1] = name
                visit(option, info, trail, state)
            elseif option.type ~= "header" and option.type ~= "description" and not Resolve(option.hidden, info) then
                records[#records + 1] = { key = key, label = name, info = info,
                    description = Resolve(option.desc, info) or table.concat(trail, " / "),
                    search = APR:NormalizeSearchText(name .. " " .. table.concat(trail, " ") .. " " .. tostring(Resolve(option.desc, info) or "")),
                    option = option, get = option.get or state.get, set = option.set or state.set,
                    disabled = state.disabled or Resolve(option.disabled, info), priority = essential[key] }
            end
        end
    end
    visit(APR.settings.optionsTable or {}, {}, {}, {})
    table.sort(records, function(a, b)
        if (a.priority or 1000) ~= (b.priority or 1000) then return (a.priority or 1000) < (b.priority or 1000) end
        return a.search < b.search
    end)
    return records
end

function Index:Toggle(record)
    if InCombatLockdown() or record.disabled or record.option.type ~= "toggle" or
        record.option.confirm or type(record.set) ~= "function" or type(record.get) ~= "function" then return false end
    record.set(record.info, not record.get(record.info))
    return true
end

function Index:OpenAdvanced(record)
    local dialog = LibStub("AceConfigDialog-3.0")
    dialog:Open(APR.title)
    if record then
        local path = {}
        for i = 1, #record.info - 1 do path[i] = record.info[i] end
        if #path > 0 then dialog:SelectGroup(APR.title, unpack(path)) end
    end
end
