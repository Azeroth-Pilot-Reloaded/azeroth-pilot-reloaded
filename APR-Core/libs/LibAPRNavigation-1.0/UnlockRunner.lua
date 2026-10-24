-- Native, declarative unlock guidance. No APR route registry, engine, globals,
-- frames or saved variables are read. The consumer owns scheduling and storage.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("unlock_runner", 7) then return end
local Instance, Copy = Lib.Instance, Lib.Copy
local MAX_STEPS = 4096
local Session = {}
Session.__index = Session
local Complete

-- These properties cannot be changed by an unlock itinerary. Other predicates
-- are actionable only when the catalogue actually supplies a matching recipe.
local fixed = { faction = true, class = true, classID = true, raceID = true, maxLevel = true }
local function Applicable(data, requirements, character, expected)
    if expected == nil then expected = true end
    if type(requirements) ~= "table" then return requirements == nil end
    for key, value in pairs(requirements) do
        local possible = true
        if fixed[key] then
            local state = data:CheckRequirements({ [key] = value }, character)
            possible = state == nil or state == expected
        elseif key == "notCondition" then
            possible = Applicable(data, value, character, not expected)
        elseif key == "all" or key == "any" then
            local conjunction = (key == "all") == expected
            possible = conjunction
            for _, child in ipairs(value) do
                local childPossible = Applicable(data, child, character, expected)
                if conjunction and not childPossible then possible = false; break end
                if not conjunction and childPossible then possible = true; break end
            end
        end
        if expected and not possible then return false end
        if not expected and possible then return true end
    end
    -- Mutable predicates may become true or false; do not infer a missing
    -- prerequisite from a character restriction in a different OR branch.
    return expected
end

Lib.RequirementsApplicable = Applicable

local function AcceptanceSourced(step)
    local acceptance = step.acceptance or {}
    if #(acceptance.blockingGaps or {}) > 0 then return false end
    local advisory = { prerequisites_unverified = true }
    for _, gap in ipairs(acceptance.advisoryGaps or {}) do advisory[gap] = true end
    if acceptance.blockingGaps == nil then
        for _, gap in ipairs(acceptance.gaps or {}) do if not advisory[gap] then return false end end
    end
    if acceptance.known == true then return true end
    -- 'known' describes completeness of extraction, not the existence of an
    -- observed server offer. A sourced starter and target support guidance;
    -- remaining gaps stay on the action for the consumer to display.
    return (step.position ~= nil or step.positionOptional == true)
        and type(acceptance.sources) == "table" and #acceptance.sources > 0
        and (step.positionOptional == true or (type(acceptance.starterNPCIDs) == "table" and #acceptance.starterNPCIDs > 0))
end

local function Character(data, mapID)
    local character = Copy(data.env.getCharacter and data.env.getCharacter() or {})
    if mapID then character.mapID = mapID end
    return character
end

function Instance:GetUnlockCoverage()
    return Copy(self.unlockCoverage or {})
end

function Instance:GetUnlockRoutes()
    return Copy(self.unlockRoutes or {})
end

function Instance:GetUnlockSources() return Copy(self.unlockSources or {}) end

local function RecipeMatches(recipe, goal)
    local function equal(a, b)
        if type(a) ~= type(b) then return false end
        if type(a) ~= "table" then return a == b end
        for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
        for k in pairs(b) do if a[k] == nil then return false end end
        return true
    end
    local value = goal.value
    if value == nil then value = goal.questID end
    return recipe.goal.key == goal.key and (recipe.goal.negated == true) == (goal.negated == true)
        and equal(recipe.goal.value, value)
end

local function GoalIdentity(goal)
    local function encode(value)
        if type(value) ~= "table" then
            local text = tostring(value)
            return type(value) .. #text .. ":" .. text
        end
        local keys, values = {}, {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b) return encode(a) < encode(b) end)
        for _, key in ipairs(keys) do values[#values + 1] = encode(key) .. encode(value[key]) end
        return "table{" .. table.concat(values, ";") .. "}"
    end
    local value = goal.value
    if value == nil then value = goal.questID end
    return goal.key .. ":" .. tostring(goal.negated == true) .. ":" .. encode(value)
end

local function GoalRequirements(goal)
    local requirements = { [goal.key] = goal.value }
    return goal.negated and { notCondition = requirements } or requirements
end

local function StepIdentity(data, recipe, index, step)
    local source = step.sourceID and data.unlockSources and data.unlockSources[step.sourceID]
    return table.concat({ recipe.id, index, step.kind, step.questID or 0, step.sourceStep or 0,
        source and source.sha256 or "" }, ":")
end

local hearthTravel = { hearthstone = true, dalaran_hearthstone = true, garrison_hearthstone = true }
local function TravelHint(step, following)
    -- An authored hearth trip describes a means of reaching the next recorded
    -- actor. The journey planner can choose that means from the actual bind,
    -- or another route. Neither a cast nor this bypass proves an arrival.
    return step.kind == "transport" and step.transport and hearthTravel[step.transport.type]
        and not step.arrival and not step.completeWhen and following and following.position
        and following.kind ~= "missing"
end

local function AccessPlans(data, blockers, checkpoint, overflow)
    local function expand(node)
        checkpoint()
        if not node then return {} end
        if not node.children then
            if node.unknown or fixed[node.key] then return {} end
            -- Rewarded quests cannot be uncompleted, even if a malformed
            -- catalogue claims to provide an inverse recipe.
            if node.negated and (node.key == "quest" or node.key == "questAccount" or node.key == "achievement") then return {} end
            return { { { key = node.key, value = Copy(node.value),
                negated = node.negated == true,
                questID = (node.key == "quest" or node.key == "questActive" or node.key == "questAccount") and node.value or nil } } }
        end
        local result = node.key == "all" and { {} } or {}
        for _, child in ipairs(node.children) do
            local alternatives = expand(child)
            if node.key == "all" then
                local combined = {}
                for _, a in ipairs(result) do
                    for _, b in ipairs(alternatives) do
                        local goals = Copy(a)
                        for _, goal in ipairs(b) do goals[#goals + 1] = Copy(goal) end
                        if #combined < 64 then combined[#combined + 1] = goals else overflow() end
                        checkpoint()
                    end
                end
                result = combined
            else
                for _, alternative in ipairs(alternatives) do
                    if #result < 64 then result[#result + 1] = alternative else overflow() end
                end
            end
        end
        return result
    end
    local result = {}
    for _, edge in ipairs(blockers or {}) do
        if edge.blockedRequirements and not edge.blockedActions then
            local character = Character(data, edge.from and edge.from.uiMapID)
            local failure = data:GetRequirementFailures(edge.blockedRequirements, character)
            for _, goals in ipairs(expand(failure)) do
                if #goals > 0 then
                    result[#result + 1] = { edgeID = edge.id, instruction = edge.instruction,
                        requirements = Copy(edge.blockedRequirements), departureMapID = character.mapID, goals = goals }
                end
            end
        end
    end
    return result
end

-- A coroutine bounds catalogue scans, recipe copying and conjunction expansion.
-- Unknown or non-actionable leaves remain explicit missing data.
function Instance:CreateUnlockBuild(blockers, options)
    options = options or {}
    local job = { status = "planning", clock = options.clock }
    local cache = options.preflightCache or {}
    local function checkpoint() coroutine.yield() end
    job.worker = coroutine.create(function()
        local plans, missing = {}, {}
        local recipes = cache.recipes
        if not recipes then
            recipes = {}
            for _, recipe in ipairs(self.unlockRoutes or {}) do
                local identity = GoalIdentity(recipe.goal)
                recipes[identity] = recipes[identity] or {}
                table.insert(recipes[identity], recipe)
                checkpoint()
            end
            cache.recipes = recipes
        end
        -- Rank the first unfinished actions with a monotone AND/OR worklist.
        -- A goal improves at most twice (missing -> pending -> actionable).
        -- Recursive DFS revisited unsolved shared prerequisites exponentially,
        -- especially when acquisition recipes introduced cycles and diamonds.
        cache.scoresByMap = cache.scoresByMap or {}
        local scoresByMap = cache.scoresByMap
        local function buildScores(character, goal)
            local map = character.mapID or false
            local state = scoresByMap[map]
            if not state then
                state = { entries = {}, dependents = {}, goalScores = {}, discovered = {} }
                scoresByMap[map] = state
            end
            local entries, dependents, goalScores = state.entries, state.dependents, state.goalScores
            local queue, queued, pending = {}, {}, {}
            local function discover(identity)
                if state.discovered[identity] then return end
                state.discovered[identity] = true
                for _, recipe in ipairs(recipes[identity] or {}) do
                    pending[#pending + 1] = recipe
                    checkpoint()
                end
            end
            discover(GoalIdentity(goal))
            local function failure(requirements)
                local allowed, invalid = self:CheckRequirements(requirements, character)
                if invalid then return { score = 10000 } end
                if allowed == true then return { score = 0 } end
                return self:GetRequirementFailures(requirements, character)
            end
            local function dependencies(node, seen)
                if not node or node.score or node.unknown then return end
                if node.children then
                    for _, child in ipairs(node.children) do dependencies(child, seen) end
                elseif not fixed[node.key] and not (node.negated and (node.key == "quest"
                    or node.key == "questAccount" or node.key == "achievement")) then
                    seen[GoalIdentity(node)] = true
                end
            end
            local function evaluate(node)
                if not node then return 0 end
                if node.score then return node.score end
                if node.unknown then return 100 end
                if node.children then
                    local score = node.key == "all" and 0 or 10000
                    for _, child in ipairs(node.children) do
                        local value = evaluate(child)
                        if node.key == "all" then score = math.max(score, value)
                        else score = math.min(score, value) end
                    end
                    return score
                end
                if fixed[node.key] or (node.negated and (node.key == "quest" or node.key == "questAccount"
                    or node.key == "achievement")) then return 10000 end
                return goalScores[GoalIdentity(node)] or 10000
            end
            -- Follow only failed guards reachable from this goal. Unrelated
            -- campaigns must neither poll client APIs nor enter the worklist.
            -- The map-local graph can grow when a nested detour asks for a new
            -- goal; its previous fixed point remains valid for existing nodes.
            local pendingIndex = 1
            while pendingIndex <= #pending do
                local recipe = pending[pendingIndex]
                pendingIndex = pendingIndex + 1
                local entry = { recipe = recipe, guards = {}, base = 0 }
                local available = self:CheckRequirements(recipe.availability, character)
                if not Applicable(self, recipe.requirements, character)
                    or (options.exhaustedRecipes and options.exhaustedRecipes[recipe.id]) then entry.base = 10000
                elseif available ~= true and not (options.selectedRecipes and options.selectedRecipes[recipe.id]) then
                    entry.base = available == nil and 100 or 10000
                else
                    entry.guards[#entry.guards + 1] = failure(recipe.requirements)
                    local pending = false
                    for index, step in ipairs(recipe.steps) do
                        checkpoint()
                        local remember = not step.completeWhen and (step.kind == "waypoint" or step.kind == "scenario"
                            or step.kind == "transport" or step.kind == "action")
                        if not TravelHint(step, recipe.steps[index + 1])
                            and not (remember and options.observedSteps and options.observedSteps[StepIdentity(self, recipe, index, step)])
                            and Complete(self, step, character) ~= true and Applicable(self, step.requirements, character) then
                            pending = true
                            entry.guards[#entry.guards + 1] = failure(step.requirements)
                            if step.kind == "missing" then entry.base = 10000
                            elseif step.kind == "accept" then
                                local offered = self.env.isQuestAvailable and self.env.isQuestAvailable(step.questID, step.acceptance)
                                if offered ~= true then
                                    entry.guards[#entry.guards + 1] = failure(step.acceptance and step.acceptance.requirements)
                                    if offered == false or not AcceptanceSourced(step) then entry.base = 10000 end
                                end
                            end
                            break
                        end
                    end
                    if not pending then entry.base = recipe.guidanceQuestID and 100 or 10000 end
                end
                entries[recipe.id] = entry
                local seen = {}
                for _, guard in ipairs(entry.guards) do dependencies(guard, seen) end
                for identity in pairs(seen) do
                    dependents[identity] = dependents[identity] or {}
                    table.insert(dependents[identity], entry)
                    discover(identity)
                end
                queue[#queue + 1], queued[recipe.id] = entry, true
                checkpoint()
            end
            local cursor = 1
            while cursor <= #queue do
                local entry = queue[cursor]
                cursor, queued[entry.recipe.id] = cursor + 1, nil
                local score = entry.base
                for _, guard in ipairs(entry.guards) do score = math.max(score, evaluate(guard)) end
                entry.score = score
                job.scoredRecipes = (job.scoredRecipes or 0) + 1
                local identity = GoalIdentity(entry.recipe.goal)
                if score < (goalScores[identity] or 10000) then
                    goalScores[identity] = score
                    for _, dependent in ipairs(dependents[identity] or {}) do
                        if not queued[dependent.recipe.id] then
                            queue[#queue + 1], queued[dependent.recipe.id] = dependent, true
                        end
                        checkpoint()
                    end
                end
                checkpoint()
            end
            return entries
        end
        local function scoreRecipe(recipe, character)
            local state = scoresByMap[character.mapID or false]
            if not state or not state.discovered[GoalIdentity(recipe.goal)] then
                buildScores(character, recipe.goal)
                state = scoresByMap[character.mapID or false]
            end
            return state.entries[recipe.id].score
        end
        local alternatives = AccessPlans(self, blockers, checkpoint, function() job.truncated = true end)
        for _, plan in ipairs(alternatives) do
            local steps, recipeIDs, valid, prerequisitesKnown = {}, {}, true, true
            local viability = 0
            local completedGoals, activeGoals = {}, {}
            for _, goal in ipairs(plan.goals) do
                if goal.key == "questActive" and not goal.negated then
                    activeGoals[goal.value] = true
                    if self.env.isQuestCompleted and self.env.isQuestCompleted(goal.value) == true then valid = false end
                elseif goal.key == "quest" then completedGoals[goal.value] = true end
            end
            for id in pairs(activeGoals) do if completedGoals[id] then valid = false end end
            for _, goal in ipairs(plan.goals) do
                if not valid then break end
                local best, bestScore
                local character = Character(self, plan.departureMapID)
                for _, recipe in ipairs(recipes[GoalIdentity(goal)] or {}) do
                    if RecipeMatches(recipe, goal) then
                        local available = self:CheckRequirements(recipe.availability, character)
                        local selected = options.selectedRecipes and options.selectedRecipes[recipe.id] == true
                        if available == nil and not selected then job.waitingData = true end
                        if not (options.exhaustedRecipes and options.exhaustedRecipes[recipe.id])
                            and (available == true or selected)
                            and Applicable(self, recipe.requirements, character) then
                            local score = scoreRecipe(recipe, character, {}, 0)
                            local selected = options.selectedRecipes and options.selectedRecipes[recipe.id] == true
                            local bestSelected = best and options.selectedRecipes and options.selectedRecipes[best.id] == true
                            if not best or score < bestScore or (score == bestScore and
                                ((selected and not bestSelected) or (selected == bestSelected and #recipe.steps < #best.steps))) then
                                best, bestScore = recipe, score
                            end
                        end
                    end
                    checkpoint()
                end
                if not best then
                    missing[#missing + 1] = { key = goal.key, value = Copy(goal.value), reason = "missing_guidance" }
                    valid = false
                    break
                end
                recipeIDs[#recipeIDs + 1] = best.id
                viability = math.max(viability, bestScore)
                if best.prerequisitesKnown == false then prerequisitesKnown = false end
                for index, step in ipairs(best.steps) do
                    if #steps >= MAX_STEPS then valid = false; break end
                    local copy = Copy(step)
                    copy._unlockRecipeID, copy._unlockRecipeRequirements = best.id, Copy(best.requirements)
                    copy._unlockGoal, copy._unlockGuidanceQuestID = Copy(best.goal), best.guidanceQuestID
                    copy._unlockAvailability, copy._unlockProgressive = Copy(best.availability), best.progressive
                    copy._unlockStepID = StepIdentity(self, best, index, step)
                    copy._unlockObservationToken = options.observationToken
                    steps[#steps + 1] = copy
                    checkpoint()
                end
            end
            if valid and #steps > 0 then
                local result = Copy(plan)
                result.steps, result.recipeIDs = steps, recipeIDs
                result.viability = viability
                result.prerequisitesKnown = prerequisitesKnown
                result.missingSteps = 0
                for _, step in ipairs(steps) do
                    if step.kind == "missing" then result.missingSteps = result.missingSteps + 1 end
                end
                plans[#plans + 1] = result
            end
            checkpoint()
        end
        if job.truncated then missing[#missing + 1] = { reason = "alternative_limit" } end
        if job.waitingData then missing[#missing + 1] = { reason = "pending_availability" } end
        if #plans == 0 and #missing == 0 then missing[1] = { reason = "unverified_or_unactionable_requirements" } end
        table.sort(plans, function(a, b)
            if a.viability ~= b.viability then return a.viability < b.viability end
            if a.missingSteps ~= b.missingSteps then return a.missingSteps < b.missingSteps end
            if #a.steps ~= #b.steps then return #a.steps < #b.steps end
            return tostring(a.edgeID) < tostring(b.edgeID)
        end)
        return plans, missing
    end)
    function job:Step(maxOperations, milliseconds)
        if self.status ~= "planning" then return self.status, self.plans, self.missing end
        self.workLastStep = 0
        maxOperations = math.max(0, math.floor(maxOperations or 64))
        milliseconds = math.max(0, milliseconds or 1)
        if maxOperations == 0 or milliseconds == 0 then return self.status end
        local deadline = self.clock and self.clock() + milliseconds
        for operation = 1, maxOperations do
            if operation > 1 and deadline and self.clock() >= deadline then break end
            self.workLastStep = self.workLastStep + 1
            local ok, plans, missing = coroutine.resume(self.worker)
            if not ok then self.status, self.worker = "failed", nil; error(plans, 0) end
            if coroutine.status(self.worker) == "dead" then
                self.status, self.plans, self.missing, self.worker = "ready", plans, missing, nil
                break
            end
        end
        return self.status, self.plans, self.missing
    end
    function job:Cancel()
        -- A cancelled coroutine may have only partly extended the dependency
        -- graph. No later detour may reuse that unfinished fixed point.
        if self.status == "planning" then cache.scoresByMap = nil end
        self.status, self.worker, self.plans = "cancelled", nil, nil
    end
    return job
end

function Instance:GetUnlockStepText(step)
    local customText
    if step.kind == "transport" and step.transport then
        local arrival = Copy(step.arrival or {})
        arrival.uiMapID = arrival.uiMapID or step.transport.destinationMapID
        local kind = step.transport.type
        local key = "NAVIGATION_UNLOCK_" .. kind
        if self:GetText(key) ~= key then customText = self:GetText(key)
        elseif kind == "flight" and step.transport.nodeID then
            local name = self.env.getFlightNodeName and self.env.getFlightNodeName(step.transport.nodeID)
            customText = string.format(self:GetText("USE_FLIGHTPATH"), name or tostring(step.transport.nodeID))
        else customText = self:GetInstruction(kind, nil, arrival) end
    end
    if step.kind == "scenario" and self.env.getScenarioCriteria then
        local info = self.env.getScenarioCriteria(step.scenario)
        if info and info.description then customText = info.description end
    end
    if step.kind == "action" then
        local kind, parameters = step.actionType, step.parameters
        if kind == "item" or kind == "spell" then
            local id = type(parameters) == "number" and parameters or type(parameters) == "table"
                and (parameters.id or parameters.itemID or parameters.spellID)
            local getter = kind == "item" and self.env.getItemName or self.env.getSpellName
            local name = id and getter and getter(id)
            customText = string.format(self:GetText(kind == "item" and "USE_ITEM" or "USE_SPELL"),
                name or (id and tostring(id)) or self:GetText("UNKNOWN"))
        else
            local key = "NAVIGATION_UNLOCK_" .. tostring(kind)
            if self:GetText(key) ~= key then customText = self:GetText(key) end
        end
    end
    local id = step.questID or step.npcID or (type(step.parameters) == "table" and step.parameters.npcID)
    local getter = step.questID and self.env.getQuestName or self.env.getNPCName
    local name = id and getter and getter(id)
    local label = name and (name .. " [" .. id .. "]") or (id and tostring(id) or self:GetText("UNKNOWN"))
    if customText and step.kind == "action" and step.actionType == "npc_activity" then
        customText = string.format(customText, label)
    end
    local text = customText or string.format(self:GetText("NAVIGATION_UNLOCK_" .. step.kind), label)
    if step.kind == "accept" then
        local starters = step.acceptance and step.acceptance.starterNPCIDs or {}
        local npcID = step.npcID or (#starters == 1 and starters[1])
        local npcName = npcID and self.env.getNPCName and self.env.getNPCName(npcID)
        if npcName then
            text = text .. "\n" .. string.format(self:GetText("NAVIGATION_UNLOCK_interact"), npcName .. " [" .. npcID .. "]")
        end
    end
    if step.kind == "objective" and self.env.getQuestObjectiveText then
        local names = {}
        for _, index in ipairs(step.objectiveIndices or {}) do
            local objective = self.env.getQuestObjectiveText(id, index)
            if objective then names[#names + 1] = objective end
        end
        if #names > 0 then text = text .. ": " .. table.concat(names, "; ") end
    end
    for _, action in ipairs(step.useActions or {}) do
        local getter = action.type == "item" and self.env.getItemName or self.env.getSpellName
        local name = getter and getter(action.id) or tostring(action.id)
        text = text .. "\n" .. string.format(self:GetText(action.type == "item" and "USE_ITEM" or "USE_SPELL"), name)
    end
    for _, purchase in ipairs(step.purchaseActions or {}) do
        if purchase.itemID then
            local name = self.env.getItemName and self.env.getItemName(purchase.itemID) or tostring(purchase.itemID)
            text = text .. "\n" .. string.format(self:GetText("NAVIGATION_UNLOCK_buy"),
                name .. " (" .. tostring(purchase.quantity or 1) .. ")")
        end
    end
    return text
end

local function Reached(data, position, radius)
    local live = data.env.getPlayerPosition and data.env.getPlayerPosition()
    if not live or not position then return nil end
    if position.uiMapID and live.uiMapID ~= position.uiMapID then return false end
    if position.x == nil and position.y == nil then return position.uiMapID ~= nil and true or nil end
    local target = data:NormalizeLocation(position)
    if not target then return nil end
    if live.instanceID ~= target.instanceID then return false end
    if target.z ~= nil and (live.z == nil or math.abs(live.z - target.z) > 5) then return false end
    return data:CanWalk(live, target) == true and (live.x-target.x)^2 + (live.y-target.y)^2 <= (radius or 5)^2
end

local function ProgressMet(thresholds, quantity, total)
    if type(quantity) ~= "number" or type(total) ~= "number" or total <= 0 then return nil end
    for _, threshold in ipairs(thresholds or {}) do
        if threshold.percent and quantity / total * 100 >= threshold.percent then return true end
        if threshold.count and total == threshold.total and quantity >= threshold.count then return true end
    end
    return false
end

function Instance:CreateUnlockSession(options)
    assert(type(options) == "table" and type(options.destination) == "table", "original destination required")
    local blockers = {}
    for _, edge in ipairs(options.blockers or {}) do
        -- Diagnostic edges can also carry canStart closures and search labels.
        -- Persist only their declarative access evidence.
        blockers[#blockers + 1] = { id = edge.id, from = edge.from and Copy(edge.from), instruction = edge.instruction,
            blockedRequirements = edge.blockedRequirements and Copy(edge.blockedRequirements),
            blockedActions = edge.blockedActions and Copy(edge.blockedActions) }
    end
    Lib.unlockObservationSequence = (Lib.unlockObservationSequence or 0) + 1
    local session = setmetatable({ data = self, destination = Copy(options.destination), clock = options.clock or self.env.clock,
        observationToken = Lib.unlockObservationSequence,
        blockers = blockers, cursor = 1, status = "planning", observedSteps = options.observedSteps or {},
        exhaustedRecipes = options.exhaustedRecipes or {} }, Session)
    session.selectedRecipes = options.selectedRecipes or {}
    session.preflightCache = options.preflightCache or {}
    session.build = self:CreateUnlockBuild(session.blockers, { clock = session.clock,
        observedSteps = session.observedSteps, observationToken = session.observationToken,
        exhaustedRecipes = session.exhaustedRecipes, selectedRecipes = session.selectedRecipes, preflightCache = session.preflightCache })
    return session
end

function Session:Cancel()
    if self.build then self.build:Cancel() end
    if self.child then self.child:Cancel() end
    self.build, self.child, self.action, self.status = nil, nil, nil, "cancelled"
end

function Session:Retry()
    if self.status == "cancelled" or self.status == "resume" then return end
    self.preflightCache.scoresByMap = nil
    if self.child then self.child:Retry() end
    -- Keep an acquisition already in progress: availability is a selection
    -- predicate, not an action guard (a rewarded source quest may be followed
    -- by using its item). Reconsider alternatives when the chosen path blocks.
    if self.plan and (self.status == "missing_data" or (self.status == "waiting_data"
        and not (self.action and self.action.reason == "tracker_not_observed"))) then
        if self.child then self.child:Cancel() end
        self.plan, self.child, self.action, self.acceptanceBlockers = nil, nil, nil, nil
        self.cursor = 1
    end
    if not self.plan and not self.build then
        self.build = self.data:CreateUnlockBuild(self.blockers, { clock = self.clock, observedSteps = self.observedSteps,
            observationToken = self.observationToken, exhaustedRecipes = self.exhaustedRecipes,
            selectedRecipes = self.selectedRecipes, preflightCache = self.preflightCache })
        self.status = "planning"
    end
end

function Session:GetBlockers()
    if self.child then return self.child:GetBlockers() end
    return Copy(self.acceptanceBlockers or self.blockers)
end

function Session:BeginDetour(blockers, options)
    if self.child then return self.child:BeginDetour(blockers, options) end
    if self.status ~= "action" or not self.action or (self.depth or 0) >= 32 then return false, "unavailable" end
    local ancestors = Copy(self.ancestors or {})
    if self.plan.edgeID then ancestors[self.plan.edgeID] = true end
    for _, edge in ipairs(blockers or {}) do
        if not edge.id or ancestors[edge.id] then return false, "cyclic_unlock" end
    end
    self.child = self.data:CreateUnlockSession({ destination = self.plan.steps[self.cursor].position or self.destination, blockers = blockers,
        clock = options and options.clock, observedSteps = self.observedSteps,
        exhaustedRecipes = self.exhaustedRecipes, selectedRecipes = self.selectedRecipes, preflightCache = self.preflightCache })
    self.child.ancestors, self.child.depth = ancestors, (self.depth or 0) + 1
    return true
end

function Session:ResolveRequirements(requirements, id, step, character)
    local allowed, invalid = self.data:CheckRequirements(requirements, character)
    if invalid then return false, "missing_data", invalid end
    if allowed == nil then return false, "waiting_data", "pending_requirements" end
    if allowed == true then return true end
    local blocker = { id = id, from = character.mapID and { uiMapID = character.mapID },
        instruction = self.data:GetUnlockStepText(step), blockedRequirements = Copy(requirements) }
    self.acceptanceBlockers = { blocker }
    local ancestors = Copy(self.ancestors or {})
    if self.plan.edgeID then ancestors[self.plan.edgeID] = true end
    if ancestors[id] or (self.depth or 0) >= 32 then return false, "missing_data", "cyclic_quest_prerequisites" end
    self.child = self.data:CreateUnlockSession({ blockers = { blocker }, destination = step.position or self.destination,
        clock = self.clock, observedSteps = self.observedSteps,
        exhaustedRecipes = self.exhaustedRecipes, selectedRecipes = self.selectedRecipes, preflightCache = self.preflightCache })
    ancestors[id] = true
    self.child.ancestors, self.child.depth = ancestors, (self.depth or 0) + 1
    return false, "planning"
end

function Session:CheckAcceptance(step, character)
    local data = self.data
    local offered = data.env.isQuestAvailable and data.env.isQuestAvailable(step.questID, step.acceptance)
    local acceptance = step.acceptance or {}
    local function state(value)
        if value == nil then return "unknown" end
        return value and "passed" or "blocked"
    end
    local evidence = { questID = step.questID, offer = offered == nil and "unknown" or (offered and "offered" or "unavailable"),
        known = acceptance.known == true, complete = acceptance.complete == true,
        requirements = state(data:CheckRequirements(acceptance.requirements, character)), conditions = {} }
    local function observe(requirements, negated)
        for key, value in pairs(requirements or {}) do
            if #evidence.conditions >= 32 then evidence.truncated = true; return end
            if key == "all" or key == "any" then
                for _, child in ipairs(value) do observe(child, negated) end
            elseif key == "notCondition" then observe(value, not negated)
            else
                local actual = data:CheckRequirements({ [key] = value }, character)
                if negated and actual ~= nil then actual = not actual end
                local entry = { key = key, state = state(actual), negated = negated == true }
                if type(value) == "table" then
                    entry.id = value.id or value.factionID or value.mapID
                else entry.value = value end
                evidence.conditions[#evidence.conditions + 1] = entry
            end
        end
    end
    observe(acceptance.requirements)
    if data.env.getQuestAvailabilityEvidence then evidence.server = Copy(data.env.getQuestAvailabilityEvidence(step.questID)) end
    self.acceptanceEvidence = evidence
    -- A current server offer is direct evidence, including valid character skips.
    if offered == true then self.acceptanceBlockers = nil; return true end
    local questName = data.env.getQuestName and data.env.getQuestName(step.questID)
    local questLabel = questName and (questName .. " [" .. step.questID .. "]") or tostring(step.questID)
    local blocker = { id = "quest-acceptance:" .. step.questID,
        instruction = string.format(data:GetText("NAVIGATION_UNLOCK_accept_unverified"), questLabel),
        blockedRequirements = Copy(acceptance.requirements or {}) }
    self.acceptanceBlockers = { blocker }
    local allowed, status, reason = self:ResolveRequirements(acceptance.requirements, blocker.id, step, character)
    if not allowed then return false, status, reason end
    if AcceptanceSourced(step) and offered ~= false then
        self.acceptanceBlockers = nil
        return true
    end
    return false, "missing_data",
        offered == false and "quest_unavailable" or "quest_availability_unverified"
end

Complete = function(data, step, character)
    if step.skipWhen and data:CheckRequirements(step.skipWhen, character) == true then return true end
    if step.completeWhen then return data:CheckRequirements(step.completeWhen, character) end
    if step.kind == "scenario" then
        local info = data.env.getScenarioCriteria and data.env.getScenarioCriteria(step.scenario)
        if not info then return nil end
        if info.completed == true then return true end
        if #(step.progressAny or {}) > 0 then return ProgressMet(step.progressAny, info.quantity, info.totalQuantity) end
        return info.completed
    elseif step.kind == "transport" then
        if step.arrival then return Reached(data, step.arrival, step.arrival.radius or step.radius) end
        return data.env.isUnlockActionComplete and data.env.isUnlockActionComplete(step)
    elseif step.kind == "action" then
        return data.env.isUnlockActionComplete and data.env.isUnlockActionComplete(step)
    end
    local id, env = step.questID, data.env
    if id then
        local rewarded = env.isQuestCompleted and env.isQuestCompleted(id)
        if rewarded == true then return true end
        if step.kind == "accept" then
            local active = env.isQuestActive and env.isQuestActive(id)
            if active == true then return true end
            if rewarded == nil then return nil end
            return active
        end
        if step.kind == "turnin" then
            if rewarded == false then return false end
            return nil
        end
        if step.kind == "objective" then
            local ready = env.isQuestReadyForTurnIn and env.isQuestReadyForTurnIn(id)
            if ready == true then return true end
            local unknown = false
            for _, index in ipairs(step.objectiveIndices or {}) do
                local done = env.isQuestObjectiveCompleted and env.isQuestObjectiveCompleted(id, index)
                if done ~= true and #(step.progressAny or {}) > 0 and env.getQuestObjectiveProgress then
                    local quantity, total = env.getQuestObjectiveProgress(id, index)
                    done = ProgressMet(step.progressAny, quantity, total)
                end
                if done == false then return false end
                if done == nil then unknown = true end
            end
            if unknown or #(step.objectiveIndices or {}) == 0 then return nil end
            return true
        end
    end
    if step.kind == "waypoint" then
        if step.arrival then return Reached(data, step.arrival, step.arrival.radius or step.radius) end
        if step.zoneStepTrigger then
            local trigger = step.zoneStepTrigger
            return Reached(data, { space = "world", uiMapID = trigger.mapID, instanceID = trigger.instanceID,
                x = trigger.y, y = trigger.x, z = trigger.z }, trigger.Range or step.radius)
        end
        local unknown = false
        for _, position in ipairs(step.positions or { step.position }) do
            local reached = Reached(data, position, step.radius)
            if reached == true then return true end
            if reached == nil then unknown = true end
        end
        if unknown then return nil end
        return false
    end
    return false
end

-- Return the next action and its observed position. Walking to it never accepts,
-- completes or rewards a quest. Only live observations advance quest actions.
function Session:Step(maxOperations, milliseconds)
    if self.status == "cancelled" or self.status == "resume" then return self.status, self.action, Copy(self.destination) end
    if self.plan and self.data:CheckRequirements(self.plan.requirements, Character(self.data, self.plan.departureMapID)) == true then
        if self.child then self.child:Cancel(); self.child = nil end
        self.status, self.action = "resume", nil
        return "resume", nil, Copy(self.destination)
    end
    if self.child then
        local current = self.plan and self.plan.steps[self.cursor]
        local env = self.data.env
        local goalDone = current and current._unlockGoal and self.data:CheckRequirements(GoalRequirements(current._unlockGoal),
            Character(self.data, self.plan.departureMapID)) == true
        if goalDone or (current and current.kind == "accept" and (
            (env.isQuestCompleted and env.isQuestCompleted(current.questID) == true)
            or (env.isQuestActive and env.isQuestActive(current.questID) == true)
            or (env.isQuestAvailable and env.isQuestAvailable(current.questID, current.acceptance) == true))) then
            self.child:Cancel()
            self.child = nil
            self.preflightCache.scoresByMap = nil
            return "planning"
        end
        local status, action = self.child:Step(maxOperations, milliseconds)
        if status ~= "resume" then self.status = status; return status, action, Copy(self.destination) end
        self.child = nil
        self.preflightCache.scoresByMap = nil
        -- Resume the parent on the next slice so nested work shares its budget.
        return "planning"
    end
    if not self.plan then
        for _, edge in ipairs(self.blockers) do
            if edge.blockedRequirements and not edge.blockedActions
                and self.data:CheckRequirements(edge.blockedRequirements, Character(self.data, edge.from and edge.from.uiMapID)) == true then
                if self.build then self.build:Cancel() end
                self.build, self.status, self.action = nil, "resume", nil
                return "resume", nil, Copy(self.destination)
            end
        end
        if not self.build then return self.status, nil, Copy(self.destination) end
    end
    if self.build then
        local status, plans, missing = self.build:Step(maxOperations, milliseconds)
        if status == "planning" then return "planning" end
        self.build, self.missing = nil, missing
        self.plan = plans and plans[1]
        if not self.plan then
            self.status = "missing_data"
            for _, gap in ipairs(missing or {}) do
                if gap.reason == "pending_availability" then self.status = "waiting_data"; break end
            end
            return self.status, nil, Copy(self.destination)
        end
        for _, id in ipairs(self.plan.recipeIDs) do self.selectedRecipes[id] = true end
        -- Discovery and progression share one caller allowance, rather than
        -- each spending another millisecond in the same frame.
        return "planning"
    end
    local data, plan = self.data, self.plan
    local character = Character(data, plan.departureMapID)
    local allowed = data:CheckRequirements(plan.requirements, character)
    if allowed == true then
        self.status, self.action = "resume", nil
        return "resume", nil, Copy(self.destination)
    end
    local deadline = self.clock and self.clock() + (milliseconds or 1)
    for operation = 1, math.max(1, maxOperations or 64) do
        if operation > 1 and deadline and self.clock() >= deadline then self.status = "planning"; return self.status end
        local step = plan.steps[self.cursor]
        if not step then
            local previous = plan.steps[#plan.steps]
            if previous and previous._unlockGuidanceQuestID then
                local questID = previous._unlockGuidanceQuestID
                self.status = "waiting_data"
                self.action = { kind = "interact", questID = questID, positionOptional = true,
                    waitingData = true, reason = "tracker_not_observed",
                    label = string.format(data:GetText("NAVIGATION_UNLOCK_tracker_wait"),
                        (data.env.getQuestName and data.env.getQuestName(questID)) or tostring(questID)) }
                return self.status, self.action, Copy(self.destination)
            end
            -- A reward source can make progress without reaching a numerical
            -- threshold. Select another still-available source instead of
            -- repeating that quest or declaring the condition unachievable.
            local acquisition, acquisitionPending = false, false
            for _, previous in ipairs(plan.steps) do
                if (previous._unlockProgressive or previous._unlockAvailability) and previous._unlockGoal then
                    local state = data:CheckRequirements(GoalRequirements(previous._unlockGoal), character)
                    if state == false then
                        self.exhaustedRecipes[previous._unlockRecipeID] = true
                        self.selectedRecipes[previous._unlockRecipeID] = nil
                        acquisition = true
                    elseif state == nil then acquisitionPending = true end
                end
            end
            if acquisition then
                self.preflightCache.scoresByMap = nil
                self.plan, self.action, self.cursor, self.status = nil, nil, 1, "planning"
                self.build = data:CreateUnlockBuild(self.blockers, { clock = self.clock, observedSteps = self.observedSteps,
                    observationToken = self.observationToken, exhaustedRecipes = self.exhaustedRecipes,
                    selectedRecipes = self.selectedRecipes, preflightCache = self.preflightCache })
                return "planning"
            end
            if acquisitionPending then
                self.status, self.action = "waiting_data", nil
                return self.status, nil, Copy(self.destination)
            end
            self.status, self.action = allowed == nil and "waiting_data" or "missing_data", nil
            return self.status, nil, Copy(self.destination)
        end
        -- Step restrictions refer to the live player, unlike the passage gate.
        local liveCharacter = Character(data)
        local remember = not step.completeWhen and (step.kind == "waypoint" or step.kind == "scenario"
            or step.kind == "transport" or step.kind == "action")
        local goalDone = step._unlockGoal and data:CheckRequirements(GoalRequirements(step._unlockGoal), character) == true
        local done = goalDone or (remember and self.observedSteps[step._unlockStepID]) or Complete(data, step, liveCharacter)
        local travelHint = TravelHint(step, plan.steps[self.cursor + 1])
        local eligible = Applicable(data, step.requirements, liveCharacter)
        if eligible and done ~= true and not travelHint then
            local guards = { step._unlockRecipeRequirements or {}, step.requirements or {} }
            for index, guard in ipairs(guards) do
                local ready, status, reason = self:ResolveRequirements(guard,
                    "unlock-requirement:" .. tostring(step._unlockRecipeID) .. ":" .. index .. ":" .. self.cursor,
                    step, liveCharacter)
                if not ready then
                    self.status, self.action = status, nil
                    self.requirementReason = reason
                    return status, nil, Copy(self.destination)
                end
            end
        end
        if eligible == true and done ~= true and step.questID and step.kind ~= "accept" and step.kind ~= "missing"
            and data.env.isQuestCompleted and data.env.isQuestCompleted(step.questID) == false
            and data.env.isQuestActive and data.env.isQuestActive(step.questID) == false then
            -- An abandoned quest must be accepted again at its observed start.
            for index = self.cursor - 1, 1, -1 do
                local previous = plan.steps[index]
                if previous.kind == "accept" and previous.questID == step.questID
                    and data:CheckRequirements(previous.requirements, liveCharacter) == true then
                    self.cursor, step = index, previous
                    done = Complete(data, step, liveCharacter)
                    break
                end
            end
        end
        if eligible == false or done == true or travelHint then
            if done == true then self.preflightCache.scoresByMap = nil end
            if remember and done == true then self.observedSteps[step._unlockStepID] = true end
            self.cursor = self.cursor + 1
        else
            if step.kind == "accept" then
                local available, status, reason = self:CheckAcceptance(step, liveCharacter)
                if not available then
                    self.status = status
                    self.action = { kind = "missing", questID = step.questID, reason = reason,
                        requirements = step.acceptance and Copy(step.acceptance.requirements),
                        gaps = step.acceptance and Copy(step.acceptance.gaps),
                        label = string.format(data:GetText(reason == "quest_unavailable" and "NAVIGATION_UNLOCK_accept_unavailable"
                            or "NAVIGATION_UNLOCK_accept_unverified"),
                            (data.env.getQuestName and data.env.getQuestName(step.questID) or tostring(step.questID))
                                .. " [" .. step.questID .. "]") }
                    return self.status, self.action, Copy(self.destination)
                end
            end
            self.acceptanceBlockers = nil
            self.action = Copy(step)
            if step.kind == "accept" and not self.action.npcID and step.acceptance
                and #(step.acceptance.starterNPCIDs or {}) == 1 then self.action.npcID = step.acceptance.starterNPCIDs[1] end
            self.action.prerequisitesKnown = plan.prerequisitesKnown
            self.action.label = data:GetUnlockStepText(step)
            if step.kind == "action" and data.env.watchUnlockAction then data.env.watchUnlockAction(step) end
            if step.kind == "missing" then
                self.status = "missing_data"
            elseif not step.position and not step.positionOptional then
                self.status = "missing_data"
            else
                if not step.noArrow then
                    local live = data.env.getPlayerPosition and data.env.getPlayerPosition()
                    local bestDistance
                    for _, position in ipairs(step.positions or { step.position }) do
                        local target = data:NormalizeLocation(position)
                        if target then
                            local distance = live and live.instanceID == target.instanceID and live.uiMapID == target.uiMapID
                                and ((live.x-target.x)^2 + (live.y-target.y)^2) or math.huge
                            if not self.action.target or distance < bestDistance then
                                self.action.target, bestDistance = target, distance
                            end
                        end
                    end
                end
                self.action.positionOptional = step.positionOptional or step.noArrow == true
                self.status = (self.action.target or self.action.positionOptional) and "action" or "waiting_data"
                -- Unknown quest flags do not erase the known position, but are
                -- exposed separately so a host cannot treat them as completion.
                self.action.waitingData = done == nil
            end
            return self.status, self.action, Copy(self.destination)
        end
    end
    self.status = "planning"
    return self.status
end

function Session:ExportState()
    return { schema = 1, destination = Copy(self.destination), blockers = Copy(self.blockers), observedSteps = Copy(self.observedSteps),
        selectedRecipes = Copy(self.selectedRecipes), exhaustedRecipes = Copy(self.exhaustedRecipes) }
end

function Instance:RestoreUnlockSession(state, options)
    assert(type(state) == "table" and state.schema == 1, "invalid unlock state")
    options = options or {}
    -- Re-evaluate all quest flags after reload; never trust a saved cursor.
    return self:CreateUnlockSession({ destination = state.destination, blockers = state.blockers, clock = options.clock,
        observedSteps = Copy(state.observedSteps or {}), selectedRecipes = Copy(state.selectedRecipes or {}),
        exhaustedRecipes = Copy(state.exhaustedRecipes or {}) })
end
