-- Reusable service discovery. All client observations and taxi data are injected.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("services", 13) then return end
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
    if direction == 1 and queue[cursor].approachOnly then return end
    local index = cursor + direction
    if index == #queue + 1 then return index end -- Explicitly dismiss the final destination.
    if index < 1 or index > #queue then return end
    local step = queue[index]
    if step.canStart and step.canStart(position, true) ~= true then return end
    if step.kind ~= "walk" and step.sourceFree then return index end
    -- The arrow will resume at this bend (or the boarding point). A shared
    -- access region alone cannot prove that the player can reach it.
    local target = step.from
    if step.kind == "walk" then target = (step.path and step.path[step.pathCursor or 2]) or step.to end
    if not target or self:CanWalk(position, target) ~= true then return end
    local provider = self.profile == "forever" and self.GetWalkingProvider and self:GetWalkingProvider()
    if provider and provider.RequiresWalkingProof and provider:RequiresWalkingProof(position, target) then
        if position.z == nil then
            position = Lib.Copy(position)
            position.z = provider.GetServiceOriginHeight and provider:GetServiceOriginHeight(position, queue[cursor])
                or (provider.GetGuidanceHeight and provider:GetGuidanceHeight(position))
        end
        if target.z == nil and provider.GetGuidanceHeight then
            target = Lib.Copy(target)
            target.z = provider:GetGuidanceHeight(target)
        end
        if not provider.CanFollowWalkingSegment or provider:CanFollowWalkingSegment(position, target) ~= true then return end
    end
    return index
end
local function Number(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function HorizontalSeconds(a, b, speed)
    if a.instanceID ~= b.instanceID then return math.huge end
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2) / speed
end

-- Keep every point that could participate in a journey within the trial
-- time limit. Walking uses its speed ceiling, ignores walls and height, and
-- every transport is assumed affordable and usable. Source-free actions may
-- depart immediately. These relaxations can only enlarge the retained set.
local function ScreenServiceRoutes(request, limit)
    local speed = request.walkingSpeedCeiling
    local start = {point = request.start, seconds = 0}
    local reached, pending, labels = {}, {start}, {}
    local work = 0
    local function checkpoint()
        work = work + 1
        if work == 16 then work = 0; coroutine.yield() end
    end
    while #pending > 0 do
        local best = 1
        for i = 2, #pending do
            checkpoint()
            if pending[i].seconds < pending[best].seconds then best = i end
        end
        local label = pending[best]
        pending[best] = pending[#pending]
        pending[#pending] = nil
        if label == start or labels[label.point] == label then
            reached[#reached + 1] = label
            label.radiusSquared = ((limit - label.seconds) * speed)^2
            for _, group in ipairs(request.edgeGroups) do
                for _, edge in ipairs(group) do
                    checkpoint()
                    if not edge.hearthstone and Number(edge.seconds) and edge.seconds >= 0
                        and edge.from and Number(edge.from.x) and Number(edge.from.y)
                        and edge.to and Number(edge.to.x) and Number(edge.to.y) then
                        local boarding = edge.sourceFree and 0 or HorizontalSeconds(label.point, edge.from, speed)
                        local seconds = label.seconds + boarding + edge.seconds
                        local previous = labels[edge.to]
                        -- If a previously reached origin already covers the
                        -- landing at this time, its entire remaining circle
                        -- is covered too (horizontal triangle inequality).
                        local improves = seconds <= limit and (not previous or seconds < previous.seconds)
                        if improves then
                            for _, origin in ipairs(reached) do
                                checkpoint()
                                if origin.seconds + HorizontalSeconds(origin.point, edge.to, speed) <= seconds then
                                    improves = false
                                    break
                                end
                            end
                        end
                        if improves then
                            local arrival = {point = edge.to, seconds = seconds}
                            labels[edge.to], pending[#pending + 1] = arrival, arrival
                        end
                    end
                end
            end
        end
    end
    local function within(point)
        if not point or not Number(point.x) or not Number(point.y) then return false end
        for _, label in ipairs(reached) do
            checkpoint()
            local p = label.point
            if p.instanceID == point.instanceID and (point.x - p.x)^2 + (point.y - p.y)^2 <= label.radiusSquared then
                return true
            end
        end
        return false
    end
    local goals, indices, groups = {}, {}, {}
    for i, goal in ipairs(request.goals) do
        if within(goal) then
            goals[#goals + 1], indices[#indices + 1] = goal, i
        end
    end
    if #goals == 0 or #goals == #request.goals then return end
    for n, group in ipairs(request.edgeGroups) do
        local keep = {}
        for _, edge in ipairs(group) do
            -- Even an expensive transport can contribute an intermediate
            -- walking waypoint. Preserve both endpoints if either is nearby.
            if within(edge.from) or within(edge.to) then keep[#keep + 1] = edge end
        end
        groups[n] = keep
    end
    return {goals = goals, indices = indices, edgeGroups = groups}
end

-- Find nearby services using ordinary travel first. A recall must not turn a
-- distant service into the "nearest" one. Only refine the selected destination
-- when reaching it without a hearthstone takes more than ten minutes.
function Instance:CreateServiceRouteSearch(options)
    local baseline = {}
    for key, value in pairs(options) do baseline[key] = value end
    baseline.excludeHearthstones = true
    baseline.serviceWalking = self.profile == "forever"
    return setmetatable({navigator = self, options = options, status = "planning", phase = "baseline",
        active = self:CreateSearch(baseline)}, ServiceRoute)
end

function ServiceRoute:Cancel()
    if self.active then self.active:Cancel() end
    self.status, self.active = "cancelled", nil
    self.entryWalkPreview = nil
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
    if self.phase == "baseline" then self.entryWalkPreview = self.active.entryWalkPreview end
    if status == "planning" then return status end
    if status == "cancelled" then self:Cancel(); return self.status end
    self.unresolvedSurface = self.unresolvedSurface or self.active.unresolvedSurface
    self.unresolvedStartSurface = self.unresolvedStartSurface or self.active.unresolvedStartSurface
    if self.phase == "baseline" then
        self.baseline = result
        local threshold = self.options.hearthstoneThresholdSeconds or HEARTHSTONE_THRESHOLD_SECONDS
        if (status == "ready" and result.totalSeconds > threshold)
            or (status == "no_path" and not self.options.waitingData) then
            local request = {}
            for key, value in pairs(self.options) do request[key] = value end
            request.excludeHearthstones = false
            request.serviceWalking = self.navigator.profile == "forever"
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
    if status == "no_path" and self.unresolvedSurface then status = "waiting_data" end
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

-- Reuse the library's profession/weapon definitions for initial learning.
-- Higher profession ranks and recipes need exact capability evidence; their
-- spell names are not stable identifiers and must never be guessed by the host.
function Instance:GetTrainingServiceQuery(spellID, professionOnly)
    for _, skill in ipairs(PROFESSIONS) do
        if skill[2] == spellID then return {service = "trainer", skill = skill[1]} end
    end
    if not professionOnly then
        for _, skill in ipairs(WEAPONS) do
            if skill[2] == spellID then return {service = "weapon", skill = skill[1]} end
        end
    end
    return {service = professionOnly and "trainer" or "class", spellIDs = spellID and {spellID} or nil,
        requireSpellEvidence = professionOnly == true}
end

local FACTION_SIDE = {Alliance = "A", Horde = "H"}
function Instance:ServiceMatches(record, query, character)
    if record.service ~= query.service then return false end
    if query.npcID and record.npcID ~= query.npcID then return false end
    if query.skill and record.skill ~= query.skill then return false end
    if query.expansion ~= nil and record.expansion ~= query.expansion then return false end
    if record.faction ~= nil and record.faction ~= "B" and record.faction ~= "AH" then
        if not character.faction then return nil end
        if record.faction ~= FACTION_SIDE[character.faction] then return false end
    end
    if record.service == "class" then
        if not record.class then return false end
        if not character.class then return nil end
        if record.class ~= character.class then return false end
    end
    if record.requirements then
        if not self.CheckRequirements then return nil end
        local available = self:CheckRequirements(record.requirements, character)
        if available ~= true then return available end
    end
    -- Exact spell IDs also identify profession ranks and recipes. A profession
    -- category alone cannot certify that a trainer teaches the requested rank.
    if query.spellIDs then
        if type(record.spellIDs) ~= "table" then
            if query.requireSpellEvidence then return nil end
        else
            for _, wanted in ipairs(query.spellIDs) do
                local found = false
                for _, taught in ipairs(record.spellIDs) do
                    if wanted == taught then found = true; break end
                end
                if not found then return false end
            end
        end
    end
    return true
end

function Instance:IsServiceArrival(position, target, radius)
    radius = radius or 5
    if not position or not target or position.instanceID ~= target.instanceID then return false end
    if not Number(position.x) or not Number(position.y) or not Number(target.x) or not Number(target.y) then return false end
    if (position.x - target.x)^2 + (position.y - target.y)^2 > radius^2 then return false end
    if self:CanWalk(position, target) ~= true then return false end
    if self.IsSameAccessRegion and self:IsSameAccessRegion(position, target) ~= true then return false end
    local provider = (target.sharedFloorChord or self.profile == "forever")
        and self.GetWalkingProvider and self:GetWalkingProvider()
    if target.sharedFloorChord then
        return provider and provider.CanFollowWalkingSegment
            and provider:CanFollowWalkingSegment(position, target) == true or false
    end
    if provider and provider.RequiresWalkingProof and provider:RequiresWalkingProof(position, target) then
        if position.z == nil and provider.GetGuidanceHeight then
            position = Lib.Copy(position)
            position.z = provider:GetGuidanceHeight(position)
        end
        if not Number(position.z) then return false end
        -- Interaction height can differ slightly from its walkable floor.
        -- Keep the interaction tolerance and check the final physical link.
        if target.z ~= nil and (not Number(target.z) or math.abs(position.z - target.z) > radius) then return false end
        local ground = provider.GetGuidanceHeight and provider:GetGuidanceHeight(target)
        if Number(ground) and (target.z == nil or math.abs(ground - target.z) <= radius) then
            target = Lib.Copy(target)
            target.z = ground
        end
        if not Number(target.z) or math.abs(position.z - target.z) > radius then return false end
        return provider.CanFollowWalkingSegment and provider:CanFollowWalkingSegment(position, target) == true or false
    end
    return target.z == nil or (Number(target.z) and Number(position.z) and math.abs(position.z - target.z) <= radius)
end

function Instance:CreateServiceSearch(options)
    options = type(options) == "table" and options or {}
    local query = {}
    for key, value in pairs(options.query or {}) do query[key] = value end
    local character = {}
    for key, value in pairs(options.character or (self.env.getCharacter and self.env.getCharacter()) or EMPTY) do character[key] = value end
    local job = setmetatable({navigator = self, options = options, query = query, character = character,
        status = "planning", phase = "candidate", candidates = {}, goals = {},
        walkingProvider = options.walkingProvider or (self.GetWalkingProvider and self:GetWalkingProvider())}, Job)
    job.start = options.start
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
        if job.source == Lib.serviceLocations[self.profile] then
            -- Registered declarations are immutable until the next revision.
            -- Build the index in slices and publish it only after a complete scan.
            local index = self.serviceIndex
            if index and index.source == job.source then
                job.source = index.groups[query.service] or EMPTY
            else
                job.index = {source = job.source, groups = {}}
            end
            job.positionCache = self.positions
        end
    end
    return job
end

function Job:Cancel()
    self.status = "cancelled"
    if self.active and self.active.Cancel then self.active:Cancel() end
    self.active, self.source = nil, nil
    self.screen, self.routeRequest, self.index = nil, nil, nil
end

function Job:GetResult() return self.result, self.status end

function Job:PrepareRoute()
    local context = {}
    for field, value in pairs(self.options) do context[field] = value end
    context.goal, context.playerPosition = self.goals[1], self.start
    context.deferInstructions = true
    self.context, self.phase = context, "prepare"
    self.active = context.adapter and context.adapter.CreatePreparation and context.adapter:CreatePreparation(context) or nil
end

function Job:Advance(operations, milliseconds)
    local nav, options = self.navigator, self.options
    if self.phase == "screen" then
        local ok, window = coroutine.resume(self.screen)
        if ok and coroutine.status(self.screen) ~= "dead" then return end
        self.screen, self.phase = nil, "search"
        if not ok or not window then
            self.active = nav:CreateServiceRouteSearch(self.routeRequest)
            return
        end
        local trial = {}
        for key, value in pairs(self.routeRequest) do trial[key] = value end
        trial.goals, trial.edgeGroups = window.goals, window.edgeGroups
        trial.serviceWalking, trial.excludeHearthstones = true, true
        self.trialIndices, self.active = window.indices, nav:CreateSearch(trial)
        return
    end
    if self.phase == "origin" then
        local status, z = self.active:Step(operations, milliseconds)
        if status == "planning" then return end
        if status == "cancelled" then self:Cancel(); return end
        if Number(z) then
            self.start = Lib.Copy(self.start)
            self.start.z = z
        end
        self:PrepareRoute()
        return
    end
    if self.phase == "candidate" then
        if self.index then
            -- Indexing declarations performs no host calls. Batch these small
            -- table reads, but keep projections and availability checks sliced.
            local count = math.min(operations, 64)
            for i = 1, count do
                local key, record = next(self.source, self.cursor)
                self.cursor = key
                if not key then
                    nav.serviceIndex = self.index
                    self.source, self.index = self.index.groups[self.query.service] or EMPTY, nil
                    return i
                end
                if type(record) == "table" and record.service then
                    local group = self.index.groups[record.service]
                    if not group then group = {}; self.index.groups[record.service] = group end
                    group[#group + 1] = record
                end
            end
            return count
        end
        local key, record = next(self.source, self.cursor)
        self.cursor = key
        if key == nil then
            if self.nearestIndex then
                local index = self.nearestIndex
                self.result = {record = self.candidates[index], target = self.goals[index], byCoordinates = true}
                self.status = "ready"
            elseif #self.goals == 0 then
                self.status = self.waitingData and "waiting_data" or "no_path"
            elseif nav.profile == "forever" and options.activeWalk and options.activeWalk.kind == "walk"
                and options.activeWalk.path and self.start.z == nil
                and self.walkingProvider and self.walkingProvider.CreateServiceOriginJob then
                self.phase = "origin"
                self.active = self.walkingProvider:CreateServiceOriginJob(self.start, options.activeWalk, options.clock)
            else
                self:PrepareRoute()
            end
            return
        end
        local candidate, target
        if self.query.service == "flight" then
            local provider = options.flightProvider
            if nav.profile == "forever" and provider.IsFlightMasterCandidate and not provider:IsFlightMasterCandidate(record) then return end
            -- Some scheduled vehicles have visible taxi nodes, but no
            -- discoverable flight point or ride mount for either faction.
            if nav.profile == "forever" and type(record) == "table" and record.characterBitNumber == 0
                and record.hordeMountCreatureID == 0 and record.allianceMountCreatureID == 0 then return end
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
        else
            local matches = nav:ServiceMatches(record, self.query, self.character)
            if matches == nil then self.waitingData = true end
            if matches then
                target = self.positionCache and self.positionCache[record]
                if not target then
                    target = nav:NormalizeLocation({space = "map", uiMapID = record.mapID,
                        x = record.x / 100, y = record.y / 100, z = record.z, floor = record.floor})
                    if self.positionCache and target and target.region then self.positionCache[record] = target end
                end
                candidate = record
                if not target then self.waitingData = true end
            end
        end
        if target and candidate then
            if not Number(target.x) or not Number(target.y) or not Number(target.instanceID) then
                self.waitingData = true
                return
            end
            self.candidates[#self.candidates + 1] = candidate
            self.goals[#self.goals + 1] = target
            if options.nearestByCoordinates and target.instanceID == self.start.instanceID then
                local distanceSquared = (self.start.x - target.x)^2 + (self.start.y - target.y)^2
                if not self.nearestSquared or distanceSquared < self.nearestSquared then
                    self.nearestSquared, self.nearestIndex = distanceSquared, #self.goals
                end
            end
            if options.batchTerrainWork and Number(options.walkingSpeedCeiling) and options.walkingSpeedCeiling > 0 then
                local seconds = HorizontalSeconds(self.start, target, options.walkingSpeedCeiling)
                self.nearestSeconds = math.min(self.nearestSeconds or math.huge, seconds)
            end
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
        if self.trialIndices then
            -- An actual route below the limit certifies the reduction: every
            -- competing route as fast as this one was included. On failure or
            -- overrun the full search still owns all goals, edges and recalls.
            if status ~= "ready" or not result or not self.trialIndices[result.goalIndex]
                or not Number(result.totalSeconds) or result.totalSeconds > self.trialLimit then
                self.trialIndices, self.active = nil, nav:CreateServiceRouteSearch(self.routeRequest)
                return
            end
            result.goalIndex = self.trialIndices[result.goalIndex]
            result.withoutHearthstoneSeconds, result.hearthstoneAllowed = result.totalSeconds, false
        end
        if status == "ready" and result and result.goalIndex then
            local index = result.goalIndex
            self.result = {record = self.candidates[index], target = self.goals[index],
                totalSeconds = result.totalSeconds, itinerary = result}
            if self.navigator.profile == "forever" then
                local first, last = result.segments[1], result.segments[#result.segments]
                if first and first.path then self.result.origin = first.path[1] end
                if last and last.path and self.result.target.z == nil then
                    self.result.target = Lib.Copy(self.result.target)
                    self.result.target.z = last.path[#last.path].z
                end
            end
            self.status = "ready"
        else
            self.status = (self.waitingData or status == "waiting_data") and "waiting_data" or "no_path"
            if self.active.unresolvedStartSurface then self.reason = "origin_surface" end
        end
        self.active, self.edges, self.taxiEdges = nil, nil, nil
        self.routeRequest = nil
        return
    end
    -- Only confirmed taxi edges participate. No unknown-flight probe can win a service ranking.
    self.routeRequest = {start = self.start, goals = self.goals,
        batchTerrainWork = options.batchTerrainWork,
        waitingData = self.waitingData,
        walkingProvider = self.walkingProvider, faction = self.character.faction,
        walkingSpeedCeiling = options.walkingSpeedCeiling,
        hearthstoneThresholdSeconds = options.hearthstoneThresholdSeconds,
        clock = options.clock, walkSpeed = options.walkSpeed or 7, walkSpeedAt = options.walkSpeedAt,
        walkSpeedFor = options.walkSpeedFor, flight = options.flight, budget = options.budget or 0,
        resources = self.metadata.resources, edgeGroups = {self.edges, self.taxiEdges},
        canWalk = function(a, b) return nav:CanWalk(a, b) end,
        walkingRegionFor = nav.GetPositionRegion and function(p) return nav:GetPositionRegion(p) end,
        walkingIsTransitive = true}
    if self.navigator.profile == "forever" and #self.goals >= 32 and self.nearestSeconds then
        local recallThreshold = options.hearthstoneThresholdSeconds or HEARTHSTONE_THRESHOLD_SECONDS
        self.trialLimit = math.min(recallThreshold, math.max(15, self.nearestSeconds * 1.5))
        self.phase = "screen"
        self.screen = coroutine.create(function() return ScreenServiceRoutes(self.routeRequest, self.trialLimit) end)
    else
        self.phase, self.active = "search", nav:CreateServiceRouteSearch(self.routeRequest)
    end
end

function Job:Step(maxOperations, maxMilliseconds)
    if self.status ~= "planning" then return self.status, self.result, self.reason end
    maxOperations = Number(maxOperations) and math.max(0, math.floor(maxOperations)) or 64
    local clock = self.options.clock
    local budget = Number(maxMilliseconds) and math.max(0, maxMilliseconds) or 1
    if maxOperations == 0 or budget == 0 then return self.status, self.result, self.reason end
    local deadline = clock and clock() + budget
    local remaining = maxOperations
    while remaining > 0 do
        if deadline and clock() >= deadline then break end
        -- Keep provider/search stages inside one shared slice, including candidate scanning.
        local phase = self.phase
        local used = self:Advance(remaining, deadline and math.max(0, deadline - clock()) or budget)
        remaining = remaining - (used or 1)
        if self.status ~= "planning" or (phase ~= "candidate" and phase ~= "screen") then break end
    end
    return self.status, self.result, self.reason
end
