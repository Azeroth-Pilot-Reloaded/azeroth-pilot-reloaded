-- Planning uses the consumer's environment and never shares character state.
-- Optional waypoint output is isolated in WaypointUI.lua.
local Lib = LibStub:NewLibrary("LibAPRNavigation-1.0", 26)
if not Lib then return end

Lib.datasets = Lib.datasets or {}
Lib.dataRevisions = Lib.dataRevisions or {}
Lib.modules = Lib.modules or {}
Lib.Instance = Lib.Instance or {}
local Instance = Lib.Instance
Instance.__index = Instance

local function Copy(value, seen)
    local kind = type(value)
    if kind ~= "table" then
        assert(kind ~= "function", "navigation data must be declarative")
        return value
    end
    seen = seen or {}
    assert(not seen[value], "cyclic navigation data")
    seen[value] = true
    local result = {}
    for key, child in pairs(value) do
        -- Most catalogue fields are scalars. Recurse only into tables while
        -- retaining the declarative-data check for every value.
        local childKind = type(child)
        if childKind == "table" then
            result[key] = Copy(child, seen)
        else
            assert(childKind ~= "function", "navigation data must be declarative")
            result[key] = child
        end
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
    local recipeIDs = {}
    for _, recipe in ipairs(copy.unlockRoutes or {}) do
        assert(type(recipe.id) == "string" and not recipeIDs[recipe.id], "unique unlock identity required")
        recipeIDs[recipe.id] = true
        assert(type(recipe.goal) == "table" and type(recipe.goal.key) == "string"
            and recipe.goal.value ~= nil, "unlock goal required")
        assert(type(recipe.steps) == "table" and #recipe.steps > 0 and #recipe.steps <= 4096, "bounded unlock steps required")
        for _, step in ipairs(recipe.steps) do
            assert(step.kind == "accept" or step.kind == "turnin" or step.kind == "objective"
                or step.kind == "waypoint" or step.kind == "missing" or step.kind == "interact"
                or step.kind == "scenario" or step.kind == "transport" or step.kind == "action", "unknown unlock action")
            if step.kind == "accept" or step.kind == "turnin" or step.kind == "objective" then
                assert(NonnegativeNumber(step.questID) and step.questID > 0 and step.questID % 1 == 0, "unlock quest required")
            end
            if step.acceptance ~= nil then
                assert(type(step.acceptance) == "table" and type(step.acceptance.known) == "boolean"
                    and type(step.acceptance.requirements) == "table", "invalid quest acceptance metadata")
                if step.acceptance.autoAccept == true then step.autoAccept = true end
            end
            if step.position then ValidatePosition(step.position) end
            for _, position in ipairs(step.positions or {}) do ValidatePosition(position) end
            if not step.position and #(step.positions or {}) > 0 then step.position = Copy(step.positions[1]) end
            if step.kind ~= "missing" and not step.position then
                local sourced = step.sourceID ~= nil or (type(step.source) == "string" and step.source ~= "")
                    or #(step.acceptance and step.acceptance.sources or {}) > 0
                assert(sourced and (step.positionOptional == true or step.noArrow == true or step.autoAccept == true),
                    "sourced positionless unlock action required")
                assert(step.kind ~= "accept" or step.autoAccept == true, "sourced auto acceptance required")
                step.positionOptional = true
            end
            assert(step.radius == nil or NonnegativeNumber(step.radius), "invalid unlock radius")
            for _, threshold in ipairs(step.progressAny or {}) do
                assert(type(threshold) == "table" and ((NonnegativeNumber(threshold.percent) and threshold.percent <= 100)
                    or (NonnegativeNumber(threshold.count) and NonnegativeNumber(threshold.total) and threshold.total > 0)),
                    "numeric unlock progress required")
            end
            if step.arrival then
                assert(type(step.arrival) == "table", "invalid unlock arrival")
                if step.arrival.x ~= nil or step.arrival.y ~= nil then ValidatePosition(step.arrival) end
            end
            if step.kind == "scenario" then assert(type(step.scenario) == "table", "scenario identity required") end
            if step.kind == "transport" then assert(type(step.transport) == "table", "transport identity required") end
            if step.kind == "action" then assert(type(step.actionType) == "string", "action identity required") end
            if step.kind == "interact" then assert(type(step.completeWhen) == "table", "observed interaction completion required") end
            for _, action in ipairs(step.useActions or {}) do
                assert((action.type == "item" or action.type == "spell") and NonnegativeNumber(action.id)
                    and action.id > 0 and action.id % 1 == 0, "invalid unlock use action")
            end
            if step.kind == "objective" then
                assert(type(step.objectiveIndices) == "table" and #step.objectiveIndices > 0, "unlock objective indices required")
                for _, index in ipairs(step.objectiveIndices) do
                    assert(NonnegativeNumber(index) and index > 0 and index % 1 == 0, "invalid unlock objective index")
                end
            end
        end
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
        waypointOptions = type(options.waypoints) == "table" and Copy(options.waypoints) or {},
        connections = {},
        connectionLookup = {},
        unlockRoutes = {},
        unlockSources = {},
        unlockCoverage = {},
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
    local ids, entranceIDs, unlockIDs = {}, {}, {}
    for _, category in ipairs(categories) do
        local data = self.datasets[options.profile][category]
        local sourceOffset = #instance.unlockSources
        for _, recipe in ipairs(data.unlockRoutes or {}) do
            assert(not unlockIDs[recipe.id], "duplicate unlock id")
            unlockIDs[recipe.id] = true
            local copy = Copy(recipe)
            for _, step in ipairs(copy.steps) do
                if step.sourceID then step.sourceID = step.sourceID + sourceOffset end
            end
            instance.unlockRoutes[#instance.unlockRoutes + 1] = copy
        end
        for _, source in ipairs(data.unlockSources or {}) do
            instance.unlockSources[#instance.unlockSources + 1] = Copy(source)
        end
        if data.unlockCoverage then instance.unlockCoverage = Copy(data.unlockCoverage) end
        for _, connection in ipairs(data.connections or {}) do
            connection = Copy(connection)
            assert(type(connection.id) == "string" and not ids[connection.id], "duplicate or missing connection id")
            ids[connection.id] = true
            instance.connections[#instance.connections + 1] = connection
            instance.connectionLookup[connection.id] = connection
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
                        local connection = {
                            id = id, kind = "passage", costMode = "ground",
                            from = entrance.approach[index - 1], to = position,
                            requirements = Copy(entrance.requirements),
                        }
                        instance.connections[#instance.connections + 1] = connection
                        instance.connectionLookup[id] = connection
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
    if (options.waypoints == true or (type(options.waypoints) == "table" and options.waypoints.enabled ~= false)
        or options.waypointUI == true)
        and instance.SetWaypointUIEnabled then
        instance:SetWaypointUIEnabled(true)
    end
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
    self.mapAccessRequirements = nil
    -- Clear both projected positions and their map ancestry. Failed API reads
    -- are never cached, so a later frame can recover without an invalidation.
    self.positions = {}
    self.mapInfos = {}
    self.regions = {}
    self.entranceLookup = {}
    self.zoneGraph = nil
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
