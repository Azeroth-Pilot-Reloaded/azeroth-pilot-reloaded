-- Reusable service discovery. All client observations and taxi data are injected.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("services", 3) then return end
local Instance = Lib.Instance
Lib.serviceLocations = Lib.serviceLocations or {}
local PROFESSIONS = {
    {171, 2259, "Alchemy"}, {164, 2018, "Blacksmithing"}, {185, 2550, "Cooking"},
    {333, 7411, "Enchanting"}, {202, 4036, "Engineering"}, {129, 3273, "First Aid"},
    {356, 7620, "Fishing"}, {182, 2366, "Herbalism"}, {165, 2108, "Leatherworking"},
    {186, 2575, "Mining"}, {393, 8613, "Skinning"}, {197, 3908, "Tailoring"},
    {773, 45357, "Inscription"}, {755, 25229, "Jewelcrafting"}, {794, 78670, "Archaeology"},
}
local WEAPONS = {
    {43, 201, "Swords"}, {55, 202, "Two-Handed Swords"}, {44, 196, "Axes"},
    {172, 197, "Two-Handed Axes"}, {54, 198, "Maces"}, {160, 199, "Two-Handed Maces"},
    {229, 200, "Polearms"}, {136, 227, "Staves"}, {173, 1180, "Daggers"},
    {473, 15590, "Fist Weapons"}, {45, 264, "Bows"}, {226, 5011, "Crossbows"},
    {46, 266, "Guns"}, {176, 2567, "Thrown"},
}
local CATEGORIES = {
    {"flight", "MINIMAP_TRACKING_FLIGHTMASTER", false, "SERVICE_FLIGHT"}, {"class", "MINIMAP_TRACKING_CLASS_TRAINER", true, "SERVICE_CLASS"},
    {"trainer", "MINIMAP_TRACKING_PROFESSION_TRAINER", false, "SERVICE_TRAINER"}, {"weapon", "MINIMAP_TRACKING_WEAPONMASTER", true, "SERVICE_WEAPON"},
    {"vendor", "MERCHANT", true, "SERVICE_VENDOR"}, {"repair", "MINIMAP_TRACKING_REPAIR", false, "SERVICE_REPAIR"},
    {"inn", "MINIMAP_TRACKING_INNKEEPER", false, "SERVICE_INN"}, {"bank", "MINIMAP_TRACKING_BANKER", false, "SERVICE_BANK"},
    {"mailbox", "MINIMAP_TRACKING_MAILBOX", false, "SERVICE_MAILBOX"}, {"auction", "MINIMAP_TRACKING_AUCTIONEER", false, "SERVICE_AUCTION"},
    {"stable", "MINIMAP_TRACKING_STABLEMASTER", true, "SERVICE_STABLE"},
}

local EXPANSIONS = { [0] = "Classic", "The Burning Crusade", "Wrath of the Lich King", "Cataclysm",
    "Mists of Pandaria", "Warlords of Draenor", "Legion", "Battle for Azeroth", "Shadowlands",
    "Dragonflight", "The War Within", "Midnight" }
local EMPTY = {}
local Job = {}
Job.__index = Job
local ServiceRoute = {}
ServiceRoute.__index = ServiceRoute
local HEARTHSTONE_THRESHOLD_SECONDS = 600

-- Progress belongs to the published itinerary, independently of any guide.
function Instance:GetServiceProgress(queue, cursor)
    queue = queue or EMPTY
    local count = #queue
    local index = math.min(math.max(cursor or 1, 1), count)
    return index, count, queue[index] and queue[index].label
end

function Instance:GetServiceStepCursor(queue, cursor, direction, position)
    if direction ~= 1 and direction ~= -1 then return end
    if not queue or not queue[cursor or 0] or not position then return end
    local index = cursor + direction
    if index == #queue + 1 then return index end -- Explicitly dismiss the final destination.
    if index < 1 or index > #queue then return end
    local step = queue[index]
    if step.canStart and step.canStart(position, true) ~= true then return end
    -- A manual advance can omit a waypoint, but cannot invent a crossing.
    if step.kind == "walk" then
        if step.to and self:CanWalk(position, step.to) == true then return index end
    elseif step.sourceFree then
        return index
    elseif step.from and self:CanWalk(position, step.from) == true then
        return index
    end
end
local function Number(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

-- Find nearby services using ordinary travel first. A recall must not turn a
-- distant service into the "nearest" one. Only refine the selected destination
-- when reaching it without a hearthstone takes more than ten minutes.
function Instance:CreateServiceRouteSearch(options)
    local baseline = {}
    for key, value in pairs(options) do baseline[key] = value end
    baseline.excludeHearthstones = true
    return setmetatable({navigator = self, options = options, status = "planning", phase = "baseline",
        active = self:CreateSearch(baseline)}, ServiceRoute)
end

function ServiceRoute:Cancel()
    if self.active then self.active:Cancel() end
    self.status, self.active = "cancelled", nil
end

function ServiceRoute:GetResult() return self.result, self.status end

function Instance:IsServiceItineraryAllowed(queue, cursor, result)
    if result.hearthstoneAllowed then return true end
    for index = cursor or 1, #queue do
        if queue[index].hearthstone then return false end
    end
    return true
end

function ServiceRoute:Step(maxOperations, maxMilliseconds)
    if self.status ~= "planning" then return self.status, self.result end
    local status, result = self.active:Step(maxOperations, maxMilliseconds)
    if status == "planning" then return status end
    if status == "cancelled" then self:Cancel(); return self.status end
    if self.phase == "baseline" then
        self.baseline = result
        local threshold = self.options.hearthstoneThresholdSeconds or HEARTHSTONE_THRESHOLD_SECONDS
        if (status == "ready" and result.totalSeconds > threshold)
            or (status == "no_path" and not self.options.waitingData) then
            local request = {}
            for key, value in pairs(self.options) do request[key] = value end
            request.excludeHearthstones = false
            if result and result.goalIndex then
                self.goalIndex = result.goalIndex
                request.goal, request.goals = request.goals[result.goalIndex], nil
            end
            self.active, self.phase = self.navigator:CreateSearch(request), "recall"
            return "planning"
        end
    elseif self.baseline then
        if status ~= "ready" or result.totalSeconds >= self.baseline.totalSeconds then result = self.baseline end
        status = "ready"
        if self.goalIndex then result.goalIndex = self.goalIndex end
    end
    if result then
        result.withoutHearthstoneSeconds = self.baseline and self.baseline.totalSeconds or math.huge
        result.hearthstoneAllowed = self.phase == "recall"
    end
    self.status, self.result, self.active = status, result, nil
    return status, result
end

function Lib:RegisterServiceLocations(profile, records, revision)
    assert(profile == "forever" or profile == "retail", "unknown service profile")
    assert(type(records) == "table", "service locations must be a table")
    revision = revision or 1
    self.serviceRevisions = self.serviceRevisions or {}
    if (self.serviceRevisions[profile] or 0) >= revision then return end
    self.serviceLocations[profile], self.serviceRevisions[profile] = records, revision
end

function Instance:GetServiceLocations()
    return self.serviceLocations or Lib.serviceLocations[self.profile] or EMPTY
end

function Instance:IsServiceBranch(query)
    return not query or ((query.service == "trainer" or query.service == "weapon") and not query.skill)
        or (query.service == "trainer" and self.profile == "retail" and query.expansion == nil)
end

function Instance:GetServiceChoices(query)
    local choices = {}
    if not query then
        for _, category in ipairs(CATEGORIES) do
            if not category[3] or self.profile == "forever" then
                choices[#choices + 1] = {globalKey = category[2], label = self:GetText(category[4]), query = {service = category[1]}}
            end
        end
    elseif (query.service == "trainer" or query.service == "weapon") and not query.skill then
        for _, skill in ipairs(query.service == "trainer" and PROFESSIONS or WEAPONS) do
            local id = skill[1]
            if query.service == "weapon" or (self.profile == "forever" and id ~= 773 and id ~= 755 and id ~= 794)
                or (self.profile == "retail" and id ~= 129) then
                local name = self.env.getSpellName and self.env.getSpellName(skill[2])
                if name == self:GetText("UNKNOWN") then name = nil end
                choices[#choices + 1] = {label = name or skill[3], query = {service = query.service, skill = id}}
            end
        end
    elseif query.service == "trainer" and self.profile == "retail" and query.expansion == nil then
        local expansions = {}
        for _, record in ipairs(self:GetServiceLocations()) do
            if record.service == "trainer" and record.skill == query.skill and record.expansion ~= nil then
                expansions[record.expansion] = true
            end
        end
        for expansion = 0, 11 do
            if expansions[expansion] then
                choices[#choices + 1] = {globalKey = "EXPANSION_NAME" .. expansion, label = EXPANSIONS[expansion],
                    query = {service = "trainer", skill = query.skill, expansion = expansion}}
            end
        end
    end
    return choices
end

function Instance:ServiceMatches(record, query, character)
    local side = ({Alliance = "A", Horde = "H"})[character.faction]
    if record.faction ~= nil and record.faction ~= "B" and record.faction ~= "AH" and record.faction ~= side then return false end
    if record.service ~= query.service then return false end
    if query.skill and record.skill ~= query.skill then return false end
    if query.expansion ~= nil and record.expansion ~= query.expansion then return false end
    if record.service == "class" and record.class ~= character.class then return false end
    if record.requirements and (not self.CheckRequirements or self:CheckRequirements(record.requirements, character) ~= true) then return false end
    return true
end

function Instance:IsServiceArrival(position, target, radius)
    radius = radius or 5
    if not position or not target or position.instanceID ~= target.instanceID then return false end
    if not Number(position.x) or not Number(position.y) or not Number(target.x) or not Number(target.y) then return false end
    if (position.x - target.x)^2 + (position.y - target.y)^2 > radius^2 then return false end
    if target.z ~= nil and (not Number(position.z) or math.abs(position.z - target.z) > radius) then return false end
    if self:CanWalk(position, target) ~= true then return false end
    return not self.IsSameAccessRegion or self:IsSameAccessRegion(position, target) == true
end

function Instance:CreateServiceSearch(options)
    options = type(options) == "table" and options or {}
    local query = {}
    for key, value in pairs(options.query or {}) do query[key] = value end
    local character = {}
    for key, value in pairs(options.character or (self.env.getCharacter and self.env.getCharacter()) or EMPTY) do character[key] = value end
    local job = setmetatable({navigator = self, options = options, query = query, character = character,
        status = "planning", phase = "candidate", candidates = {}, goals = {}}, Job)
    if not Number(options.start and options.start.x) or not Number(options.start and options.start.y) then
        job.status, job.reason = "waiting_data", "position"
    elseif query.service == "flight" then
        local provider = options.flightProvider
        if not provider or not provider.GetAllNodes or not provider.IsNodeAvailable or not provider.GetNodeWorldPosition then
            job.status, job.reason = "unavailable", "taxi_unavailable"
        else
            job.source = provider:GetAllNodes()
            if type(job.source) ~= "table" then job.status, job.reason = "unavailable", "taxi_unavailable" end
        end
    else
        job.source = self:GetServiceLocations()
    end
    return job
end

function Job:Cancel()
    self.status = "cancelled"
    if self.active and self.active.Cancel then self.active:Cancel() end
    self.active, self.source = nil, nil
end

function Job:GetResult() return self.result, self.status end

function Job:Advance(operations, milliseconds)
    local nav, options = self.navigator, self.options
    if self.phase == "candidate" then
        local key, record = next(self.source, self.cursor)
        self.cursor = key
        if key == nil then
            if #self.goals == 0 then
                self.status = self.waitingData and "waiting_data" or "no_path"
            else
                local context = {}
                for field, value in pairs(options) do context[field] = value end
                context.goal, context.playerPosition = self.goals[1], options.start
                context.deferInstructions = true
                self.context, self.phase = context, "prepare"
                self.active = options.adapter and options.adapter.CreatePreparation and options.adapter:CreatePreparation(context) or nil
            end
            return
        end
        local candidate, target
        if self.query.service == "flight" then
            local provider = options.flightProvider
            local available = provider:IsNodeAvailable(key)
            local visible = not provider.IsNodeVisible or provider:IsNodeVisible(key)
            if available == nil or visible == nil then self.waitingData = true end
            if available == true and visible == true then
                local point = provider:GetNodeWorldPosition(key)
                target = point and nav:NormalizeLocation(point)
                candidate = {service = "flight", nodeID = key, name = provider.GetNodeName and provider:GetNodeName(key),
                    mapID = target and target.uiMapID}
                if not target then self.waitingData = true end
            end
        elseif nav:ServiceMatches(record, self.query, self.character) then
            target = nav:NormalizeLocation({space = "map", uiMapID = record.mapID,
                x = record.x / 100, y = record.y / 100, z = record.z})
            candidate = record
            if not target then self.waitingData = true end
        end
        if target and candidate then
            self.candidates[#self.candidates + 1] = candidate
            self.goals[#self.goals + 1] = target
        end
        return
    end
    if self.phase == "prepare" then
        if self.active then
            local status = self.active:Step(operations, milliseconds)
            if status == "planning" then return end
            if status == "cancelled" then self:Cancel(); return end
        end
        self.phase, self.active = "catalogue", nav:CreateEdgeBuild(self.context)
        return
    end
    local status, result, metadata = self.active:Step(operations, milliseconds)
    if status == "planning" then return end
    if status == "cancelled" then self:Cancel(); return end
    self.waitingData = self.waitingData or (metadata and metadata.waitingData)
    if self.phase == "catalogue" then
        self.edges, self.metadata = result or EMPTY, metadata or {}
        local taxi = options.taxiData
        if taxi and taxi.CreateEdgeBuild then
            self.phase, self.active = "taxi", taxi:CreateEdgeBuild(self.context)
            return
        end
        self.taxiEdges = EMPTY
    elseif self.phase == "taxi" then
        self.taxiEdges = result or EMPTY
    elseif self.phase == "search" then
        if status == "ready" and result and result.goalIndex then
            local index = result.goalIndex
            self.result = {record = self.candidates[index], target = self.goals[index],
                totalSeconds = result.totalSeconds, itinerary = result}
            self.status = "ready"
        else
            self.status = self.waitingData and "waiting_data" or "no_path"
        end
        self.active, self.edges, self.taxiEdges = nil, nil, nil
        return
    end
    -- Only confirmed taxi edges participate. No unknown-flight probe can win a service ranking.
    self.active = nav:CreateServiceRouteSearch({start = options.start, goals = self.goals,
        waitingData = self.waitingData,
        hearthstoneThresholdSeconds = options.hearthstoneThresholdSeconds,
        clock = options.clock, walkSpeed = options.walkSpeed or 7, walkSpeedAt = options.walkSpeedAt,
        walkSpeedFor = options.walkSpeedFor, budget = options.budget or 0,
        resources = self.metadata.resources, edgeGroups = {self.edges, self.taxiEdges},
        canWalk = function(a, b) return nav:CanWalk(a, b) end,
        walkingRegionFor = nav.GetPositionRegion and function(p) return nav:GetPositionRegion(p) end,
        walkingIsTransitive = true})
    self.phase = "search"
end

function Job:Step(maxOperations, maxMilliseconds)
    if self.status ~= "planning" then return self.status, self.result, self.reason end
    maxOperations = Number(maxOperations) and math.max(0, math.floor(maxOperations)) or 64
    local clock = self.options.clock
    local budget = Number(maxMilliseconds) and math.max(0, maxMilliseconds) or 1
    if maxOperations == 0 or budget == 0 then return self.status, self.result, self.reason end
    local deadline = clock and clock() + budget
    for _ = 1, maxOperations do
        if deadline and clock() >= deadline then break end
        -- Keep provider/search stages inside one shared slice, including candidate scanning.
        local phase = self.phase
        self:Advance(maxOperations, deadline and math.max(0, deadline - clock()) or budget)
        if self.status ~= "planning" or phase ~= "candidate" then break end
    end
    return self.status, self.result, self.reason
end
