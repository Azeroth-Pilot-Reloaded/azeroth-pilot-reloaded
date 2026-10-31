-- Resolve actionable quest alternatives without inventing prerequisites or NPCs.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("unlocks", 2) then return end
local Instance = Lib.Instance
local MAX_PLANS = 16

local function Merge(a, b)
    local result, modes = {}, {}
    for index = 1, 2 do
        local goals = index == 1 and a or b
        for _, goal in ipairs(goals) do
            local previous = modes[goal.questID]
            -- A rewarded quest cannot also be held in the quest log.
            if previous and (previous == "questActive") ~= (goal.key == "questActive") then return end
            if not previous then
                result[#result + 1] = goal
                modes[goal.questID] = goal.key
            end
        end
    end
    return result
end

local function Plans(node)
    if not node then return {} end
    if not node.children then
        if node.unknown or node.negated or (node.key ~= "quest" and node.key ~= "questAccount"
            and node.key ~= "questActive") then return {} end
        return { { { key = node.key, questID = node.value } } }
    end
    local plans = node.key == "all" and { {} } or {}
    for _, child in ipairs(node.children) do
        local alternatives = Plans(child)
        if node.key == "all" then
            local combined = {}
            for _, a in ipairs(plans) do
                for _, b in ipairs(alternatives) do
                    local merged = Merge(a, b)
                    if merged then
                        combined[#combined + 1] = merged
                        if #combined == MAX_PLANS then break end
                    end
                end
                if #combined == MAX_PLANS then break end
            end
            -- Later conjunctions still apply to a full product; an empty one
            -- can never recover. Stop only work that cannot change this prefix.
            if #combined == 0 then return combined end
            plans = combined
        else
            for _, alternative in ipairs(alternatives) do
                plans[#plans + 1] = alternative
                if #plans == MAX_PLANS then return plans end
            end
        end
    end
    return plans
end

function Instance:GetQuestUnlockPlans(blockers)
    local result = {}
    for _, edge in ipairs(blockers or {}) do
        if edge.blockedRequirements and not edge.blockedActions then
            local character = {}
            for key, value in pairs(self.env.getCharacter and self.env.getCharacter() or {}) do character[key] = value end
            character.mapID = edge.from and edge.from.uiMapID
            local failure = self:GetRequirementFailures(edge.blockedRequirements, character)
            for _, goals in ipairs(Plans(failure)) do
                local possible = #goals > 0
                for _, goal in ipairs(goals) do
                    if goal.key == "questActive" and self.env.isQuestCompleted
                        and self.env.isQuestCompleted(goal.questID) == true then possible = false end
                end
                if possible then
                    result[#result + 1] = { edgeID = edge.id, instruction = edge.instruction,
                        requirements = edge.blockedRequirements, departureMapID = character.mapID, goals = goals }
                end
            end
        end
    end
    return result
end
