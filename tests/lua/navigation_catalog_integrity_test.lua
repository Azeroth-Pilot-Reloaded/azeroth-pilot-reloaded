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
            if FactionPossible(child, faction) then
                possible = true; break
            end
        end
        if not possible then return false end
    end
    local excluded = requirements.notCondition
    if excluded and excluded.faction then
        local factionOnly = true
        for key in pairs(excluded) do if key ~= "faction" then
                factionOnly = false; break
            end end
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
            elseif key == "notCondition" then
                inspect(value)
            else
                local _, reason = data:CheckRequirements({ [key] = value },
                    { faction = "Alliance", level = 90, class = "MAGE" })
                assert(not reason, "A declared condition needs a runtime evaluator: " .. key .. " / " .. tostring(reason))
            end
        end
    end
    local seen = {}
    for id, position in pairs(data:GetBindings()) do
        local areaID = position.areaID or id
        assert(type(areaID) == "number" and areaID > 0 and areaID % 1 == 0,
            "A bind candidate needs a positive client area ID: " .. tostring(id))
        assert(type(id) == "number" or (type(id) == "string" and id ~= ""), "Invalid bind candidate key")
        assert(position.space == "map" or position.space == "world", "Explicit bind coordinate space required")
        for _, axis in ipairs({ "x", "y" }) do
            local value = position[axis]
            assert(type(value) == "number" and value == value and math.abs(value) < math.huge,
                "Finite bind coordinate required: " .. tostring(id))
        end
        if position.space == "map" then
            assert(type(position.uiMapID) == "number" and position.uiMapID > 0 and position.uiMapID % 1 == 0
                and position.x >= 0 and position.x <= 1 and position.y >= 0 and position.y <= 1,
                "Invalid bind map position: " .. tostring(id))
        else
            assert(type(position.instanceID) == "number" and position.instanceID >= 0 and position.instanceID % 1 == 0,
                "Invalid bind world instance: " .. tostring(id))
        end
        assert(position.z == nil or (type(position.z) == "number" and position.z == position.z
            and math.abs(position.z) < math.huge), "Invalid bind altitude")
    end
    local overrides = data:GetConfig().WorldInstanceOverrides or {}
    for phased, world in pairs(overrides) do
        assert(type(phased) == "number" and phased > 0 and phased % 1 == 0
            and type(world) == "number" and world > 0 and world % 1 == 0
            and phased ~= world and overrides[world] == nil,
            "World-space overrides must resolve directly to a distinct canonical world")
    end
    local unmappedInstances = {}
    for mapID, area in pairs(data:GetConfig().UnmappedAreas or {}) do
        assert(type(mapID) == "number" and mapID > 0 and mapID % 1 == 0
            and type(area) == "table", "Unmapped areas need a positive guide map identity")
        for key in pairs(area) do
            assert(key == "instanceID" or key == "areaID", "Unsupported unmapped area field: " .. key)
        end
        assert(type(area.instanceID) == "number" and area.instanceID > 0 and area.instanceID % 1 == 0,
            "Unmapped areas need a dedicated world instance")
        assert(type(area.areaID) == "number" and area.areaID > 0 and area.areaID % 1 == 0,
            "Unmapped areas need a client-localized area identity")
        local world = data:GetWorldInstanceID(area.instanceID)
        assert(not unmappedInstances[world], "A mapless world instance cannot identify multiple guide maps")
        unmappedInstances[world] = true
    end
    for kind, stops in pairs(data:GetConfig().TransportDestinations or {}) do
        assert(type(kind) == "string" and kind ~= "" and type(stops) == "table")
        for _, stop in ipairs(stops) do
            for key in pairs(stop) do
                assert(key == "instanceID" or key == "x" or key == "y" or key == "radius" or key == "mapID",
                    "Unsupported transport destination field: " .. key)
            end
            assert(type(stop.instanceID) == "number" and stop.instanceID >= 0 and stop.instanceID % 1 == 0,
                "Transport destination coordinates need a world instance")
            for _, key in ipairs({ "x", "y", "radius" }) do
                assert(type(stop[key]) == "number" and stop[key] == stop[key] and math.abs(stop[key]) < math.huge,
                    "Transport destination needs finite " .. key)
            end
            assert(stop.radius > 0 and type(stop.mapID) == "number" and stop.mapID > 0 and stop.mapID % 1 == 0,
                "Transport destinations need a positive radius and display map")
        end
    end
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
        if connection.instructionKey then
            for locale, strings in pairs(LibStub("LibAPRNavigation-1.0").locales) do
                assert(type(strings[connection.instructionKey]) == "string" and strings[connection.instructionKey] ~= "",
                    connection.id .. " needs its interaction instruction in " .. locale)
            end
        end
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
