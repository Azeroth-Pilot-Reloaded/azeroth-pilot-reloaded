-- Turn declarative connections into usable edges for one character snapshot.
-- Each build owns its API cache and yields between connection directions.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("catalog", 13) then return end
local Instance = Lib.Instance
local EdgeBuild = {}
EdgeBuild.__index = EdgeBuild

local instructionKeys = {
    portal = "USE_PORTAL_TO",
    boat = "USE_BOAT",
    zeppelin = "USE_ZEPPELIN_TO",
    tram = "ENTER_TRAM",
    flight = "USE_FLIGHTPATH",
    elevator = "TRAVEL_TO",
}

local function Format(template, name)
    if template:find("%%") then
        local ok, value = pcall(string.format, template, name)
        if ok then return value end
    end
    return template .. " " .. name
end

function Instance:GetInstruction(kind, action, destination)
    local destinationName = self:GetDisplayMapName(destination)
    if action and (action.type == "spell" or action.type == "item") then
        local getter = action.type == "spell" and self.env.getSpellName or self.env.getItemName
        local actionName = getter and getter(action.data) or self:GetText("UNKNOWN")
        local key = action.type == "spell" and "USE_SPELL" or "USE_ITEM"
        -- Parentheses also render in client fonts without an arrow glyph.
        return Format(self:GetText(key), actionName) .. " (" .. destinationName .. ")"
    end
    local template = self:GetText(instructionKeys[kind] or "RUN_WAYPOINT")
    return Format(template, destinationName)
end

local function MarkPending(metadata, reason)
    if reason == "pending_data" or reason == "restricted" then
        metadata.waitingData = true
    end
end

function Instance:SelectAction(definition, character, metadata)
    if not definition.actions then return nil, true end
    local alternatives = definition.selection == "random" and {} or nil
    for _, option in ipairs(definition.actions) do
        local allowed = self:CheckRequirements(option.requirements, character)
        if allowed == nil then metadata.waitingData = true end
        if allowed == true then
            local actionID, reagentID = option.id, option.reagentID
            local usable, reason
            if option.groupSpellID and character.inGroup then
                usable, reason = self:GetActionUsability("spell", option.groupSpellID, character, metadata.ignoreCooldown)
                MarkPending(metadata, reason)
                if usable then
                    actionID, reagentID = option.groupSpellID, option.groupReagentID
                end
            end
            if not usable then
                usable, reason = self:GetActionUsability(option.type, actionID, character, metadata.ignoreCooldown)
                MarkPending(metadata, reason)
            end
            if usable then
                local selected = {
                    type = option.type,
                    data = actionID,
                    reagentID = reagentID,
                    reagentCount = option.reagentCount,
                    consumable = option.consumable,
                }
                if not alternatives then return selected, true end
                alternatives[#alternatives + 1] = selected
            end
        end
    end
    if alternatives and #alternatives > 0 then
        local random = self.env.random or math.random
        return alternatives[random(#alternatives)], true
    end
    return nil, false
end

function Instance:GetHearthstoneAction(ignoreCooldown)
    for _, definition in ipairs(self.connections) do
        if definition.id == "item-hearthstone-alternatives" then
            local character = self.env.getCharacter and self.env.getCharacter() or {}
            if self:CheckRequirements(definition.requirements, character) ~= true then return nil end
            return self:SelectAction(definition, character, { ignoreCooldown = ignoreCooldown })
        end
    end
end

local nilKey = {}
local unknownResult = {}
local snapshotQueries = {
    "isQuestCompleted", "isQuestCompletedOnAccount", "isQuestActive", "isAchievementCompleted", "hasAura", "hasToy", "getGarrisonLevel",
    "getDynamicPosition", "getItemCount", "getActionUsability", "getActionCastSeconds",
    "getSpellInfo", "getSpellName", "getItemName", "getAreaName", "getMapInfo", "getMapArtID", "getLocale", "getGlobalText",
}

local function MemoizeQuery(callback)
    local results = {}
    return function(first, second)
        local firstKey = first == nil and nilKey or first
        local secondKey = second == nil and nilKey or second
        local row = results[firstKey]
        if not row then
            row = {}
            results[firstKey] = row
        end
        local result = row[secondKey]
        if not result then
            -- Keep nil and false answers too. A single build must not ask the
            -- client repeatedly for the same unavailable spell, item or quest.
            result = { callback(first, second) }
            row[secondKey] = result
        end
        return result[1], result[2]
    end
end

local function SnapshotEnvironment(environment)
    local snapshot = setmetatable({}, { __index = environment })
    for _, name in ipairs(snapshotQueries) do
        if environment[name] then
            snapshot[name] = MemoizeQuery(environment[name])
        end
    end
    return snapshot
end

local function GetActionDuration(instance, definition, action)
    local waitSeconds = definition.waitSeconds or 0
    -- Portals without a verified duration share the loading estimate used by
    -- personal teleports. Legacy routing weights are not elapsed seconds.
    if not action and definition.kind == "portal" and definition.seconds == nil then
        return (instance.config.actionLoadingSeconds or 5) + waitSeconds, "profile-estimated-loading"
    end
    local seconds = (definition.seconds or 0) + waitSeconds
    if not action then return seconds, definition.durationSource or "catalog-estimate" end

    local castSeconds
    if instance.env.getActionCastSeconds then
        castSeconds = instance.env.getActionCastSeconds(action.type, action.data)
    elseif action.type == "spell" and instance.env.getSpellInfo then
        local info = instance.env.getSpellInfo(action.data)
        if info and type(info.castTime) == "number" then
            castSeconds = info.castTime / 1000
        end
    end
    local loadingSeconds = instance.config.actionLoadingSeconds or 0
    if type(castSeconds) == "number" and castSeconds >= 0 and castSeconds < math.huge then
        return castSeconds + loadingSeconds + waitSeconds, "client-cast-estimated-loading"
    end
    if definition.seconds == nil and (action.type == "spell" or action.type == "item") then
        local fallback = action.type == "spell" and instance.config.defaultSpellCastSeconds
            or instance.config.defaultItemCastSeconds
        return (fallback or 10) + loadingSeconds + waitSeconds, "profile-estimate"
    end
    return seconds, "catalog-estimate"
end

local function CreateDepartureCheck(owner, snapshot, requirements, character)
    local resultsByMap = {}
    local departure = setmetatable({}, { __index = function(_, key)
        if key ~= "mapID" then return character[key] end
    end })
    return function(position, live)
        if not position then return nil end
        if live then
            -- Retained routes must see current quests, inventory and location.
            -- Snapshot caches are only for planning this particular route.
            local current = character
            if owner.env.getCharacter then current = owner.env.getCharacter() or {} end
            local currentDeparture = setmetatable({ mapID = position.uiMapID }, { __index = function(_, key)
                if key ~= "mapID" then return current[key] end
            end })
            return owner:CheckRequirements(requirements, currentDeparture)
        end

        local mapKey = position.uiMapID or nilKey
        local cached = resultsByMap[mapKey]
        if cached ~= nil then
            if cached == unknownResult then return nil end
            return cached
        end
        -- Character requirements vary only with the simulated departure map.
        -- Reuse that answer when search explores another label on the same map.
        departure.mapID = position.uiMapID
        local allowed = snapshot:CheckRequirements(requirements, departure)
        resultsByMap[mapKey] = allowed == nil and unknownResult or allowed
        return allowed
    end
end

function EdgeBuild:PrepareDefinition(definition)
    if definition.disabled or (definition.reviewStatus and definition.reviewStatus ~= "confirmed") then return nil end
    local allowed = self.snapshot:CheckPlanningRequirements(definition.requirements, self.character)
    if allowed == nil then self.metadata.waitingData = true end
    if not allowed then return { blockedRequirements = definition.requirements } end

    local action, usable = self.snapshot:SelectAction(definition, self.character, self.metadata)
    if not usable then return { blockedActions = definition.actions } end
    local prepared = { action = action }
    if definition.requirements then
        prepared.canStart = CreateDepartureCheck(self.owner, self.snapshot, definition.requirements, self.character)
    end
    return prepared
end

local function IsUnknownOptionalPosition(definition)
    return definition.dynamic == "bind" or definition.dynamic == "camp" or definition.dynamic == "housing" or definition.dynamic == "housing_exit"
end

function EdgeBuild:AddResources(edge, definition, action)
    local group = definition.cooldownGroup or (action.type .. ":" .. tostring(action.data or "housing"))
    local cooldown = "cooldown:" .. group
    edge.resources = { [cooldown] = 1 }
    self.metadata.resources[cooldown] = 1

    local itemID = action.reagentID or (action.consumable and action.data)
    if itemID then
        local count = self.snapshot:GetItemCount(itemID)
        if count == nil then
            self.metadata.waitingData = true
            count = 0
        end
        local resource = "item:" .. itemID
        self.metadata.resources[resource] = count
        edge.resources[resource] = action.reagentCount or 1
    end
end

function EdgeBuild:AddDirection(definition, prepared, source, destination, suffix)
    local blockedRequirements = prepared.blockedRequirements
    local from = self.snapshot:ResolvePosition(source, self.context)
    local to = self.snapshot:ResolvePosition(destination, self.context)
    if not from or not to then
        self.metadata.skipped = self.metadata.skipped + 1
        -- An unobserved bind or house is an unavailable optional shortcut.
        -- A missing map projection may become available after loading.
        if (not from and not IsUnknownOptionalPosition(source)) or (not to and not destination.dynamic) then
            self.metadata.waitingData = true
        end
        return
    end

    -- Fixed transports depart from their recorded entrance, not from the
    -- player's initial map. Personal actions are checked at each search node.
    if source.dynamic ~= "player" and prepared.canStart then
        local allowed = prepared.canStart(from)
        if allowed == nil then self.metadata.waitingData = true end
        if allowed ~= true then blockedRequirements = definition.requirements end
    end

    local seconds, durationSource
    if definition.costMode == "ground" then
        local dx, dy = to.x - from.x, to.y - from.y
        local speed = self.context.walkSpeedFor and self.context.walkSpeedFor(from, to) or self.context.walkSpeed or 7
        local dz = type(from.z) == "number" and type(to.z) == "number" and to.z - from.z or 0
        if from.instanceID ~= to.instanceID then
            -- Coordinates in different world instances cannot be subtracted.
            seconds = definition.seconds or self.snapshot.config.passageSeconds or 30
            durationSource = "estimated-world-transition"
        else
            seconds = math.max(1, math.sqrt(dx * dx + dy * dy + dz * dz) / speed)
        end
        durationSource = durationSource or "catalog-estimate"
    else
        -- Resolve endpoints before requesting cast information. An unavailable
        -- bind or house does not need a duration, and both directions share it.
        if prepared.seconds == nil then
            prepared.seconds, prepared.durationSource = GetActionDuration(self.snapshot, definition, prepared.action)
        end
        seconds, durationSource = prepared.seconds, prepared.durationSource
    end
    local edge = {
        id = self.owner.profile .. ":" .. definition.id .. suffix,
        from = from,
        to = to,
        kind = definition.kind,
        seconds = seconds,
        copper = definition.copper or 0,
        mandatory = true,
        durationSource = durationSource,
        action = prepared.action,
        sourceFree = source.dynamic == "player",
        rawDynamicDestination = destination.dynamic ~= nil,
        arrivalZTolerance = definition.arrivalZTolerance,
        verifiedBuild = definition.verifiedBuild,
        canStart = prepared.canStart,
    }
    edge.instruction = self.snapshot:GetInstruction(edge.kind, edge.action, to)
    if blockedRequirements or prepared.blockedActions then
        edge.blockedRequirements, edge.blockedActions = blockedRequirements, prepared.blockedActions
        edge.canStart = nil
        local personal = prepared.blockedActions or definition.actions or source.dynamic == "player"
        local key = personal and "blockedActionEdges" or "blockedEdges"
        self.metadata[key] = self.metadata[key] or {}
        self.metadata[key][#self.metadata[key] + 1] = edge
    else
        if edge.action then self:AddResources(edge, definition, edge.action) end
        self.edges[#self.edges + 1] = edge
    end
end

function EdgeBuild:Advance()
    local definition = self.definitions[self.index]
    if self.reverse then
        self:AddDirection(definition, self.prepared, definition.to, definition.from, ":reverse")
        self.reverse, self.prepared = false, nil
        self.index = self.index + 1
        return
    end

    local prepared = self:PrepareDefinition(definition)
    if prepared then
        self:AddDirection(definition, prepared, definition.from, definition.to, ":forward")
        if definition.bidirectional then
            self.reverse, self.prepared = true, prepared
            return
        end
    end
    self.index = self.index + 1
end

function EdgeBuild:GetResult()
    if self.status == "ready" then return self.edges, self.metadata end
    return nil, self.metadata
end

function EdgeBuild:Cancel()
    if self.status ~= "planning" then return end
    self.status = "cancelled"
    -- Releasing references is constant time; the collector can reclaim the
    -- abandoned build without a synchronous walk through every partial edge.
    self.edges, self.snapshot, self.prepared = nil, nil, nil
end

function EdgeBuild:Step(maxOperations, maxMilliseconds)
    if self.status == "planning" then
        maxOperations = maxOperations or 32
        maxMilliseconds = maxMilliseconds or 1
        local deadline = self.clock and (self.clock() + math.max(0, maxMilliseconds))
        local operations = 0
        -- One operation handles one direction or one rejected definition.
        -- A frame may stop between the two directions of the same connection.
        while self.index <= #self.definitions and operations < maxOperations do
            if deadline and self.clock() >= deadline then break end
            self:Advance()
            operations = operations + 1
        end
        if self.index > #self.definitions then self.status = "ready" end
    end
    local edges, metadata = self:GetResult()
    return self.status, edges, metadata
end

function Instance:CreatePlanningSnapshot(context)
    local environment = SnapshotEnvironment(self.env)
    local snapshot = setmetatable({ env = environment, dynamicPositions = {} }, { __index = self })
    local character = Lib.Copy(self.env.getCharacter and self.env.getCharacter() or {})
    if context and context.inGroup ~= nil then character.inGroup = context.inGroup end
    return snapshot, character
end

function Instance:CreateEdgeBuild(context)
    context = context or {}
    local metadata = {
        waitingData = false,
        resources = Lib.Copy(context.resources or {}),
        skipped = 0,
        profile = self.profile,
    }
    local build = setmetatable({
        owner = self,
        definitions = context.connectionID and { self.connectionLookup[context.connectionID] } or self.connections,
        context = context,
        metadata = metadata,
        edges = {},
        index = 1,
        status = "planning",
        clock = context.clock or self.env.clock,
    }, EdgeBuild)
    if not self.supported or (context.profile and context.profile ~= self.profile) then
        metadata.waitingData = true
        metadata.reason = self.supported and "profile_mismatch" or "unsupported_client"
        build.status = "ready"
        return build
    end

    -- Each builder owns its API answers and character snapshot. Shared map
    -- projections remain safe because only successful static geometry is cached.
    build.snapshot, build.character = self:CreatePlanningSnapshot(context)
    return build
end

function Instance:BuildEdges(context)
    -- Compatibility helper for callers that intentionally want a synchronous
    -- result. Frame schedulers should retain a CreateEdgeBuild job instead.
    local build = self:CreateEdgeBuild(context)
    while build.status == "planning" do build:Step(1024, math.huge) end
    return build:GetResult()
end
