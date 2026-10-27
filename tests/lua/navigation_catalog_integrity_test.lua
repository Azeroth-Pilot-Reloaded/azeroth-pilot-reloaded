local fixture = dofile("tests/lua/navigation_fixture.lua")

-- Only project faction constraints here. Other predicates remain possible, so
-- missing quest or level observations cannot produce a false contradiction.
local function FactionPossible(requirements, faction)
    if not requirements then return true end
    if requirements.faction and requirements.faction ~= faction then return false end
    for _, child in ipairs(requirements.all or {}) do
        if not FactionPossible(child, faction) then return false end
    end
    if requirements.any then
        local possible = false
        for _, child in ipairs(requirements.any) do
            if FactionPossible(child, faction) then possible = true; break end
        end
        if not possible then return false end
    end
    local excluded = requirements.notCondition
    if excluded and excluded.faction then
        local factionOnly = true
        for key in pairs(excluded) do if key ~= "faction" then factionOnly = false; break end end
        if factionOnly and excluded.faction == faction then return false end
    end
    return true
end

local contradiction = { all = { { faction = "Alliance" }, { faction = "Horde" } } }
assert(not FactionPossible(contradiction, "Alliance") and not FactionPossible(contradiction, "Horde"))
local alternatives = { any = { { faction = "Alliance" }, { faction = "Horde" } } }
assert(FactionPossible(alternatives, "Alliance") and FactionPossible(alternatives, "Horde"))

local checked = 0
for _, profile in ipairs({ "retail", "forever" }) do
    fixture.profile = profile
    local data = fixture:Load()
    local function inspect(requirements)
        for key, value in pairs(requirements or {}) do
            if key == "all" or key == "any" then
                for _, child in ipairs(value) do inspect(child) end
            elseif key == "notCondition" then inspect(value)
            else
                local _, reason = data:CheckRequirements({ [key] = value }, { faction = "Alliance", level = 90, class = "MAGE" })
                assert(not reason, "A declared condition needs a runtime evaluator: " .. key .. " / " .. tostring(reason))
            end
        end
    end
    local seen = {}
    for _, requirements in pairs(data:GetConfig().MapRequirements or {}) do inspect(requirements) end
    for group, definition in pairs(data:GetConfig().PhaseGroups or {}) do
        assert(type(group) == "string" and type(definition.sides) == "table")
        for _, side in ipairs(definition.sides) do
            assert(type(side.phase) == "string" and type(side.mapID) == "number" and type(side.artID) == "number")
        end
        for mapID, phase in pairs(definition.localMaps or {}) do
            assert(type(mapID) == "number" and type(phase) == "string")
        end
    end
    for holiday, icons in pairs(data:GetConfig().Holidays or {}) do
        assert(type(holiday) == "string" and type(icons) == "table")
        for icon, active in pairs(icons) do assert(type(icon) == "number" and active == true) end
    end
    for _, connection in ipairs(data:GetConnections()) do
        assert(not seen[connection.id], "Duplicate connection: " .. connection.id)
        seen[connection.id] = true
        inspect(connection.requirements)
        assert(FactionPossible(connection.requirements, "Alliance")
            or FactionPossible(connection.requirements, "Horde"),
            connection.id .. " requires incompatible factions")
        for _, action in ipairs(connection.actions or {}) do
            assert(action.type == "item" or action.type == "spell" or action.type == "housing"
                or action.type == "housing_return", connection.id)
            if action.type == "item" or action.type == "spell" then
                assert(type(action.id) == "number" and action.id > 0 and action.id % 1 == 0, connection.id)
            end
        end
        checked = checked + 1
    end
    for _, recipe in ipairs(data:GetUnlockRoutes()) do
        inspect(recipe.requirements)
        inspect(recipe.availability)
        for _, step in ipairs(recipe.steps) do
            inspect(step.requirements)
            inspect(step.completeWhen)
            inspect(step.acceptance and step.acceptance.requirements)
        end
    end
    for mapID, id in pairs(data:GetConfig().ZoneRoutes or {}) do
        assert(data.connectionLookup[id], "Zone " .. mapID .. " references an unknown connection: " .. id)
    end
    local edges = data:BuildEdges({ playerPosition = { instanceID = 0, uiMapID = 2395, x = 0, y = 0 } })
    for _, edge in ipairs(edges) do
        local id = edge.id:match("^[^:]+:(.*):forward$") or edge.id:match("^[^:]+:(.*):reverse$")
        local definition = id and data.connectionLookup[id]
        if definition then
            assert(not definition.disabled and (not definition.reviewStatus or definition.reviewStatus == "confirmed"),
                "Unreviewed/disabled records cannot publish usable connections: " .. id)
        end
    end
end
print("Navigation catalogue integrity: " .. checked .. " faction-consistent connections passed")
