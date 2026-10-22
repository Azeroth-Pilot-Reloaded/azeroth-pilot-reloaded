-- A rendering-free navigation library. Game APIs and saved state belong to the
-- consumer's environment, so separate consumers never share character state.
local Lib = LibStub:NewLibrary("LibAPRNavigation-1.0", 12)
if not Lib then return end

Lib.datasets = Lib.datasets or {}
Lib.dataRevisions = Lib.dataRevisions or {}
Lib.modules = Lib.modules or {}
Lib.Instance = Lib.Instance or {}
local Instance = Lib.Instance
Instance.__index = Instance

local function Copy(value, seen)
    if type(value) ~= "table" then
        assert(type(value) ~= "function", "navigation data must be declarative")
        return value
    end
    seen = seen or {}
    assert(not seen[value], "cyclic navigation data")
    seen[value] = true
    local result = {}
    for key, child in pairs(value) do
        result[key] = Copy(child, seen)
    end
    seen[value] = nil
    return result
end
Lib.Copy = Copy

function Lib:BeginModule(name, revision)
    -- Several addons may embed the same library. Each module keeps the newest
    -- implementation without replacing instances already used by a consumer.
    if (self.modules[name] or 0) >= revision then return false end
    self.modules[name] = revision
    return true
end

local function NonnegativeNumber(value)
    return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

local function ValidatePosition(position)
    assert(type(position) == "table", "connection endpoint required")
    if position.dynamic then
        assert(position.dynamic == "player" or position.dynamic == "bind" or position.dynamic == "housing"
            or position.dynamic == "housing_exit" or position.dynamic == "camp", "unknown dynamic destination")
    else
        assert(type(position.x) == "number" and position.x == position.x and math.abs(position.x) < math.huge
            and type(position.y) == "number" and position.y == position.y and math.abs(position.y) < math.huge,
            "finite endpoint coordinates required")
        if position.space == "map" then
            assert(NonnegativeNumber(position.uiMapID) and position.x >= 0 and position.x <= 1
                and position.y >= 0 and position.y <= 1, "invalid map endpoint")
        else
            assert(NonnegativeNumber(position.instanceID) or
                (position.instanceID == nil and NonnegativeNumber(position.uiMapID)),
                "world instance or projection map required")
        end
    end
end

function Lib:RegisterData(profile, category, data, revision)
    assert(type(profile) == "string" and type(category) == "string", "profile and category required")
    assert(type(data) == "table", "data required")
    local key = profile .. ":" .. category
    revision = revision or 1
    if (self.dataRevisions[key] or 0) >= revision then return end
    local copy = Copy(data)
    for _, connection in ipairs(copy.connections or {}) do
        assert(type(connection.id) == "string" and type(connection.kind) == "string", "connection identity required")
        assert(connection.selection == nil or connection.selection == "random", "invalid action selection")
        assert(connection.reviewStatus == nil or connection.reviewStatus == "confirmed"
            or connection.reviewStatus == "candidate" or connection.reviewStatus == "disabled", "invalid review status")
        assert(connection.arrivalZTolerance == nil or NonnegativeNumber(connection.arrivalZTolerance), "invalid arrival height tolerance")
        ValidatePosition(connection.from)
        ValidatePosition(connection.to)
        assert(connection.seconds == nil or NonnegativeNumber(connection.seconds), "invalid travel duration")
        assert(connection.waitSeconds == nil or NonnegativeNumber(connection.waitSeconds), "invalid wait duration")
        assert(connection.copper == nil or NonnegativeNumber(connection.copper), "invalid fare")
    end
    for _, entrance in ipairs(copy.entrances or {}) do
        assert(type(entrance.id) == "string", "entrance identity required")
        assert(entrance.kind == "delve" or entrance.kind == "scenario" or entrance.kind == "dungeon"
            or entrance.kind == "raid", "invalid entrance kind")
        assert(entrance.reviewStatus == "confirmed" or entrance.reviewStatus == "candidate"
            or entrance.reviewStatus == "disabled", "entrance review status required")
        assert(type(entrance.interiorMapIDs) == "table" and (#entrance.interiorMapIDs > 0
            or NonnegativeNumber(entrance.instanceID)), "native interior identity required")
        for _, mapID in ipairs(entrance.interiorMapIDs) do
            assert(NonnegativeNumber(mapID) and mapID > 0 and mapID % 1 == 0, "invalid interior UI map")
        end
        if entrance.exterior then ValidatePosition(entrance.exterior) end
        assert(entrance.reviewStatus ~= "confirmed" or entrance.exterior, "confirmed exterior required")
    end
    local dataset = self.datasets[profile]
    if not dataset then
        dataset = {}
        self.datasets[profile] = dataset
    end
    dataset[category], self.dataRevisions[key] = copy, revision
end

function Lib:New(options)
    assert(type(options) == "table" and type(options.environment) == "table", "environment required")
    -- Data belongs to the instance. A consumer may adjust its catalogue without
    -- changing another addon's routes or character observations.
    local instance = setmetatable({
        profile = options.profile,
        env = options.environment,
        connections = {},
        entrances = {},
        entranceMaps = {},
        entranceInstances = {},
        entranceLookup = {},
        bindings = {},
        config = {},
        positions = {},
        mapInfos = {},
        regions = {},
        actionDefinitions = {},
    }, Instance)
    local categories = {}
    for category in pairs(self.datasets[options.profile] or {}) do
        categories[#categories + 1] = category
    end
    table.sort(categories)
    local ids, entranceIDs = {}, {}
    for _, category in ipairs(categories) do
        local data = self.datasets[options.profile][category]
        for _, connection in ipairs(data.connections or {}) do
            connection = Copy(connection)
            assert(type(connection.id) == "string" and not ids[connection.id], "duplicate or missing connection id")
            ids[connection.id] = true
            instance.connections[#instance.connections + 1] = connection
            for _, action in ipairs(connection.actions or {}) do
                instance.actionDefinitions[action.type .. ":" .. tostring(action.id)] = action
                if action.groupSpellID then
                    instance.actionDefinitions["spell:" .. action.groupSpellID] = {
                        type = "spell",
                        id = action.groupSpellID,
                        reagentID = action.groupReagentID,
                        requiresGroup = true,
                    }
                end
            end
        end
        for id, position in pairs(data.bindings or {}) do
            instance.bindings[id] = Copy(position)
        end
        for _, entrance in ipairs(data.entrances or {}) do
            entrance = Copy(entrance)
            assert(not entranceIDs[entrance.id], "duplicate entrance id")
            entranceIDs[entrance.id] = true
            if entrance.reviewStatus == "confirmed" and entrance.approach and #entrance.approach > 1 then
                -- Only the first observed point is reachable from the public
                -- walking graph. Every later point requires its preceding leg.
                for index, position in ipairs(entrance.approach) do
                    if index > 1 then position.noAutoconnect = true end
                    if index > 1 then
                        local id = entrance.id .. ":approach:" .. index
                        assert(not ids[id], "duplicate entrance approach id")
                        ids[id] = true
                        instance.connections[#instance.connections + 1] = {
                            id = id, kind = "passage", costMode = "ground",
                            from = entrance.approach[index - 1], to = position,
                            requirements = Copy(entrance.requirements),
                        }
                    end
                end
                entrance.exterior = Copy(entrance.approach[#entrance.approach])
            end
            instance.entrances[#instance.entrances + 1] = entrance
            if entrance.instanceID then
                local entries = instance.entranceInstances[entrance.instanceID]
                if not entries then entries = {}; instance.entranceInstances[entrance.instanceID] = entries end
                entries[#entries + 1] = entrance
            end
            for _, mapID in ipairs(entrance.interiorMapIDs) do
                local entries = instance.entranceMaps[mapID]
                if not entries then entries = {}; instance.entranceMaps[mapID] = entries end
                entries[#entries + 1] = entrance
            end
        end
        for key, value in pairs(data.config or {}) do
            if type(value) == "table" then
                instance.config[key] = instance.config[key] or {}
                for id, setting in pairs(value) do
                    instance.config[key][id] = Copy(setting)
                end
            else
                instance.config[key] = value
            end
        end
    end
    instance.supported = #categories > 0
    return instance
end

function Instance:GetProfile()
    if not self.supported then return nil end
    return {
        name = self.profile,
        threshold = self.config.threshold or 2000,
        skyridingThreshold = self.config.skyridingThreshold,
    }
end

function Instance:GetConfig() return self.config end
function Instance:GetBindings() return self.bindings end
function Instance:GetConnections() return self.connections end
function Instance:InvalidatePositionCache()
    self.groundMaps = nil
    -- Clear both projected positions and their map ancestry. Failed API reads
    -- are never cached, so a later frame can recover without an invalidation.
    self.positions = {}
    self.mapInfos = {}
    self.regions = {}
    self.entranceLookup = {}
end

function Instance:GetText(key)
    return Lib.GetText and Lib:GetText(key, self.env.getLocale and self.env.getLocale() or "enUS") or key
end

function Instance:GetHelpfulItems()
    local ids, result = {}, {}
    for _, connection in ipairs(self.connections) do
        for _, action in ipairs(connection.actions or {}) do
            if action.type == "item" and not ids[action.id] then
                ids[action.id] = true
                result[#result + 1] = action.id
            end
        end
    end
    table.sort(result)
    return result
end

function Instance:CreateSearch(options)
    return Lib.Engine:CreateSearch(options)
end
