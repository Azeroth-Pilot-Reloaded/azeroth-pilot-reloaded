-- Run from the repository root with Lua 5.1, or with the Python runner beside this file.
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub()
    return { GetLocale = function() return locale end }
end
function tContains(values, value)
    for _, entry in ipairs(values) do
        if entry == value then return true end
    end
    return false
end
function wipe(value)
    for key in pairs(value) do value[key] = nil end
end
function CreateVector2D(x, y) return { x = x, y = y } end
function CreateFrame()
    return { RegisterEvent = function() end, SetScript = function() end }
end
function debugprofilestop() return 0 end

local level, zone = 80, 2393
local achievement = true
local spells, active, complete, account = {}, {}, {}, {}
local ready = {}
function UnitLevel() return math.floor(level) end
C_SpellBook = { IsSpellKnown = function(id) return spells[id] == true end }
C_QuestLog = {
    IsOnQuest = function(id) return active[id] == true end,
    IsComplete = function(id) return ready[id] == true end,
    IsQuestFlaggedCompleted = function(id) return complete[id] == true end,
    IsQuestFlaggedCompletedOnAccount = function(id) return account[id] == true end,
}
C_Map = {
    GetBestMapForUnit = function() return zone end,
    GetWorldPosFromMapPos = function(mapID, point)
        return 1, { x = 1000 + mapID + point.y * 100, y = -2000 - point.x * 100 }
    end,
}
APR = {
    RouteQuestStepList = {},
    LevelRequirementProfiles = { MidnightDelves = { levels = { [0] = 89 } } },
    PlayerID = "test",
    Faction = "Alliance",
}
function APR:NewModule() return {} end
function APR:Contains(values, value) return tContains(values, value) end
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/data/zones/ScenarioEntrances.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/PlayerUtils.lua")
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/utils/RouteManager.lua")
dofile("APR-Core/features/navigation/WorldCoordinateConverter.lua")
dofile("APR-Core/core/Event.lua")
function APR:GetPlayerEffectiveLevel() return level end
function APR:IsDelveRoute() return false end
function APR:HasAchievement() return achievement end
APRData = { test = {} }
APRCustomPath = { test = {} }
APRZoneCompleted = { test = {} }

local count = 0
local function check(value, message)
    count = count + 1
    assert(value, message)
end

local routeKey = "2393-Midnight-Speedrun-alt"
dofile("Routes/Midnight/Midnight.lua")
dofile("Routes/Midnight/Midnight-Speedrun-alt.lua")
local route = APR.RouteQuestStepList[routeKey]
check(route and route.mapID == 2393, "Route is registered")
check(route.conditions.HasAchievement == 42045, "Adventure Mode requires the account campaign")
check(route.steps[1].WarMode == 91281 and route.steps[2].PickUp[1] == 91281 and route.steps[11].Done[1] == 94993,
    "The supplied introduction stays at the beginning")
check(route.steps[#route.steps].RouteCompleted, "RouteCompleted is the last main step")

local introKey = "2432-Midnight-Intro"
local intro = APR.RouteQuestStepList[introKey]
check(intro.conditions.DontHaveAchievement == 42045, "The Midnight introduction is hidden after the account unlock")
APRCustomPath.test = {}
check(APR:AddRouteToCustomPathByKey("2393-Eversong-Woods") == false,
    "A missing target route cannot modify the custom path in the isolated test")
APR.RouteQuestStepList["test-midnight-zone"] = {
    label = "Test Midnight zone", requiredRoute = { introKey }, conditions = { Level = 80 },
}
check(not APR:IsRequiredRouteApplicable(introKey), "The account achievement waives the hidden introduction")
check(APR:AddRouteToCustomPathByKey("test-midnight-zone"), "The Midnight zone can be added for an eligible alt")
check(#APRCustomPath.test == 1 and APRCustomPath.test[1] == "Test Midnight zone",
    "The hidden introduction is not inserted into the alt custom path")
achievement = false
APRCustomPath.test = {}
check(APR:IsRequiredRouteApplicable(introKey), "A first character still requires the introduction")
check(APR:AddRouteToCustomPathByKey("test-midnight-zone"), "The first-character path is assembled")
check(#APRCustomPath.test == 2 and APRCustomPath.test[1] == intro.label
    and APRCustomPath.test[2] == "Test Midnight zone", "The applicable introduction is prepended")
APRZoneCompleted.test[intro.label] = true
APRCustomPath.test = {}
check(not APR:IsRequiredRouteApplicable(introKey), "A personally completed introduction is already satisfied")
check(APR:AddRouteToCustomPathByKey("test-midnight-zone") and #APRCustomPath.test == 1,
    "A completed introduction is not inserted again")
APRZoneCompleted.test[intro.label] = nil
APR.RouteQuestStepList["test-soft-required"] = {
    label = "Soft requirement", conditions = { Level = 90, Zones = { 9999 } },
}
APR.RouteQuestStepList["test-soft-target"] = {
    label = "Soft target", requiredRoute = { "test-soft-required" },
}
APRCustomPath.test = {}
check(APR:IsRequiredRouteApplicable("test-soft-required"), "Level and zone never waive a required route")
check(APR:AddRouteToCustomPathByKey("test-soft-target") and #APRCustomPath.test == 2,
    "A temporarily disabled required route remains in the path")
achievement = true

local professionNote
for _, step in ipairs(route.steps) do
    if step.Note == "MIDNIGHT_ALT_NO_PRIMARY_PROFESSION" then professionNote = step end
end
check(professionNote and #professionNote.DontHaveSpell == 11, "All eleven primary professions are covered")
check(APR:AreConditionalFiltersMet(professionNote), "No primary profession shows the note")
for _, spellID in ipairs(professionNote.DontHaveSpell) do
    spells[spellID] = true
    check(not APR:AreConditionalFiltersMet(professionNote), "A primary profession hides the note: " .. spellID)
    check(not APR:EvaluateRouteConditions({ DontHaveSpell = { spellID } }), "Route filters use the same spell test")
    spells[spellID] = nil
end
for _, spellID in ipairs({ 131474, 264632, 78670 }) do
    spells[spellID] = true
    check(APR:AreConditionalFiltersMet(professionNote), "Secondary professions do not hide the note")
    spells[spellID] = nil
end
spells[2575] = true
check(not APR:AreConditionalFiltersMet({ DontHaveSpell = 2575 }), "Scalar spell condition")
spells[2575] = nil

local questID = 93384
account[questID] = true
check(not APR:IsQuestReadyForTurnIn(questID), "Warband completion alone cannot activate a hand-in")
active[questID] = true
check(not APR:IsQuestReadyForTurnIn(questID), "An unfinished quest cannot activate a hand-in")
ready[questID] = true
check(APR:IsQuestReadyForTurnIn(questID), "A ready quest on this character activates a hand-in")
check(APR:EvaluateRouteConditions({ IsQuestReadyForTurnIn = questID }), "Readiness works for route conditions")
complete[questID] = true
check(not APR:IsQuestReadyForTurnIn(questID), "A spent reward does not activate again")
complete[questID] = nil

APR.ActiveRoute = routeKey
APRData.test[routeKey] = 11
level, zone = 87.99, 2393
check(#APR:GetRouteSteps(routeKey) == #route.steps, "No premature parallel activation")
check(APR:IsQuestTurnInDeferred(questID), "Automation preserves a pending reward")
local progressed, rewarded, popup = 0, 0, 0
function APR:GetSettingsProfile() return { autoHandIn = true } end
function IsModifierKeyDown() return false end
function GetQuestID() return questID end
function CompleteQuest() progressed = progressed + 1 end
function GetQuestReward() rewarded = rewarded + 1 end
function APR:PopupAutocompleteQuest() popup = popup + 1 end
function APR.event:TalkToDenyNpcLogic() end
APR.event.functions.done("QUEST_PROGRESS")
APR.event.functions.done("QUEST_COMPLETE")
APR.event.functions.done("QUEST_AUTOCOMPLETE", questID)
check(progressed == 0 and rewarded == 0 and popup == 0, "All automatic hand-in entry points defer the reward")

level, zone = 89, 2413
check(#APR:GetRouteSteps(routeKey) == #route.steps, "A group remains pending outside its reward zone")
zone = 2393
local effective = APR:GetRouteSteps(routeKey)
check(#effective == #route.steps + 1, "A level jump past 88 still activates the reward")
check(effective[11].Done[1] == questID, "Ready hand-in inserts at the current progression point")
check(effective[12] == route.steps[11], "The interrupted main step is retained")
check(not APR:IsQuestTurnInDeferred(questID), "An activated reward can be turned in")
APR.event.functions.done("QUEST_PROGRESS")
check(progressed == 1, "Automatic hand-in resumes when eligible")
check(#APR:GetRouteSteps(routeKey) == #effective, "A group is inserted only once")
complete[questID] = true
active[questID], ready[questID] = nil, nil
check(#APR:GetRouteSteps(routeKey) == #effective, "Quest-log changes do not shift saved progression")
APR:InvalidateEffectiveRouteStepsCache(routeKey)
check(#APR:GetRouteSteps(routeKey) == #effective, "Reloaded parallel state preserves the effective route")

check(APR:GetParallelStepsInsertionIndex(2, {
    {}, { InstanceQuest = true }, { InstanceQuest = true }, { InstanceQuest = true }, {},
}) == 5, "A parallel group waits for the entire instance block")

local coord = APR.worldCoordinateConverter:ConvertMapCoordinate(2393, 25, 75)
check(coord.x == -2025 and coord.y == 3468, "Converter preserves APR's swapped world axes")
check(APR.worldCoordinateConverter:ConvertMapCoordinate(2393, -1, 75) == nil, "Invalid map percentages are rejected")
local projection = C_Map.GetWorldPosFromMapPos
C_Map.GetWorldPosFromMapPos = function() return nil end
check(APR.worldCoordinateConverter:ConvertMapCoordinate(2393, 25, 75) == nil,
    "A missing game projection never produces fabricated world coordinates")
C_Map.GetWorldPosFromMapPos = projection

local pickups, handins, indexes = {}, {}, {}
local function inspectStep(step)
    check(not indexes[step._index], "Unique packaged step index")
    indexes[step._index] = true
    for _, id in ipairs(step.PickUp or {}) do pickups[id] = (pickups[id] or 0) + 1 end
    for _, id in ipairs(step.Done or {}) do handins[id] = (handins[id] or 0) + 1 end
    if step.EnterScenario then
        check(APR.ScenarioEntrances[step.EnterScenario.mapID] ~= nil, "The scenario has a recorded exterior entrance")
    end
    if step.Coord then
        check(type(step.Coord.x) == "number" and type(step.Coord.y) == "number", "Every coordinate is numeric")
        local usesPortalMapCoordinates = step.TakePortal and step.Zone == 2541
        check(usesPortalMapCoordinates or
            not (step.Coord.x >= 0 and step.Coord.x <= 100 and step.Coord.y >= 0 and step.Coord.y <= 100),
            "No unconverted map percentages are used as world coordinates")
    end
end
for _, step in ipairs(route.steps) do inspectStep(step) end
for _, group in ipairs(route.parallelSteps) do
    for _, step in ipairs(group.steps) do inspectStep(step) end
end
local levelGatedDelveQuests = {
    [93372] = true, [93384] = true, [93385] = true, [93386] = true, [93409] = true,
    [93410] = true, [93416] = true, [93421] = true, [93427] = true, [93428] = true,
}
for id, total in pairs(pickups) do
    check(total == 1 or (id == 94993 and total == 2) or (levelGatedDelveQuests[id] and total == 2),
        "Only level-gated delve paths may repeat a quest pickup")
    check(handins[id] ~= nil, "Every accepted quest has a hand-in: " .. id)
end
for id, total in pairs(handins) do
    check(total == 1 or (id == 91281 and total == 2), "No duplicate quest reward outside the faction-specific introduction")
    check(pickups[id] ~= nil, "Every hand-in has a pickup: " .. id)
end
for _, id in ipairs({ 88985, 90615, 91375, 91557, 94370, 94388, 94393, 94396, 94867 }) do
    check(not pickups[id], "Optional breadcrumb cannot block a partially quested alt: " .. id)
end
for _, id in ipairs({ 93372, 93384, 93385, 93386, 93409, 93410, 93416, 93421, 93427, 93428 }) do
    local found = false
    for _, group in ipairs(route.parallelSteps) do
        if group.conditions.IsQuestReadyForTurnIn == id then
            found = group.conditions.MinLevel == "MidnightDelves"
        end
    end
    check(found, "Every delve reward uses a persistent minimum-level parallel group")
end
-- Exercise the real scenario handler with a reserved reward after a reload.
dofile("APR-Core/features/questing/QuestHandler.lua")
local scenarioStep, parentMap
local function noop() end
APR.StartPerformanceSample, APR.FinishPerformanceSample = noop, noop
APR.settings = { profile = { enableAddon = true } }
APR.currentStep = {
    previousState = {}, Reset = noop, ButtonEnable = noop, PrepareRaidIcon = noop,
    AddQuestSteps = function() error("SCENARIO_STAY", 0) end,
}
APR.currentStepImagePreview = { ClearPreviewImages = noop }
APR.Arrow = { SetCoord = noop }
APR.AFK = { lastStep = 1 }
APR.IsInRouteZone = true
APRScenarioMapIDCompleted = { test = {} }
APRData.test[routeKey] = 1
APR.ActiveRoute = routeKey
APR.ResetMissingQuests, APR.Debug, APR.SendMessage = noop, noop, noop
APR.MaybeSojournerPrompt, APR.CheckSojournerPartySync = noop, noop
function UnitIsDeadOrGhost() return false end
function APR:GetCurrentStepToken() return "scenario-test" end
function APR:GetStep() return scenarioStep end
function APR:SkipStepCondition() return false end
function APR:ShouldSojournerSkipStep() return false end
function APR:GetMapInfoCached() return { name = "Test delve" } end
function APR:GetScenarioZoneInfo(id) return self.ScenarioEntrances[id] end
function APR:GetPlayerParentMapID() return parentMap end
function APR:UpdateNextStep() error("SCENARIO_ADVANCE", 0) end
format = string.format
local function scenarioResult(field, currentMap, expected)
    scenarioStep = { [field] = { questID = 93427, mapID = 2528 } }
    zone = currentMap
    local ok, result = pcall(APR.UpdateStep, APR)
    check(not ok and result == expected, field .. ": " .. tostring(result))
end
active[93427], ready[93427] = true, true
scenarioResult("EnterScenario", 2405, "SCENARIO_ADVANCE")
scenarioResult("DoScenario", 2405, "SCENARIO_ADVANCE")
scenarioResult("LeaveScenario", 2405, "SCENARIO_ADVANCE")
scenarioResult("LeaveScenario", 2528, "SCENARIO_STAY")
parentMap = 2528
scenarioResult("LeaveScenario", 2571, "SCENARIO_STAY")
ready[93427] = nil
scenarioResult("EnterScenario", 2571, "SCENARIO_ADVANCE")
parentMap = nil
scenarioResult("DoScenario", 2528, "SCENARIO_STAY")
active[93427], account[93427] = nil, true
scenarioResult("EnterScenario", 2405, "SCENARIO_STAY")

-- A suggested guide replaces nearby DoScenario while retaining its quest setup.
level = 80
dofile("APR-Core/utils/DelveRouteUtils.lua")
local context = { mapID = 2528, scenarioID = 123, sessionKey = "test" }
local prompts, accept, decline = 0, nil, nil
function APR:GetCurrentDelveContext() return context end
function APR:GetPrimaryCustomPathRouteKey() return "test-parent" end
APR.UpdateStep, APR.UpdateMapId = noop, noop
function APR:GetTotalSteps() return 0 end
APR.questionDialog = {
    CreateQuestionPopup = function(_, _, _, onAccept, onDecline)
        prompts, accept, decline = prompts + 1, onAccept, onDecline
    end,
}
local setup = { PickUp = { 93427 }, InstanceQuest = true }
local completion = { DoScenario = { questID = 93427, mapID = 2528 }, InstanceQuest = true }
local after = { Qpart = { [93427] = { 1 } } }
local guideStep = { Note = "Guide" }
APR.RouteQuestStepList["test-parent"] = { steps = { setup, completion, after } }
APR.RouteQuestStepList["test-delve"] = {
    delve = {}, scenarios = { { scenarioID = 123, steps = { guideStep } } },
}
APR.ActiveRoute, APRData.test["test-parent"] = "test-parent", 1
APR:RefreshTemporaryDelveRoute()
check(prompts == 1 and APR.ActiveRoute == "test-parent", "InstanceQuest allows a suggestion without automatic acceptance")
APR:RefreshTemporaryDelveRoute()
check(prompts == 1, "A pending suggestion is not repeated")
accept()
local injected = APR:GetRouteSteps("test-delve")
check(#injected == 2 and injected[1] == setup and injected[2] == guideStep,
    "The pickup precedes the inserted guide and DoScenario is replaced")
APR.RouteQuestStepList["test-parent"].parallelSteps = {
    { conditions = { MinLevel = 88 }, steps = { { Done = { 93427 } } } },
}
check(APR:IsQuestTurnInDeferred(93427), "The injected guide preserves the parent route's reserved rewards")
APR.RouteQuestStepList["test-parent"].parallelSteps = nil
check(APRData.test["test-parent"] == 1, "The parent is not prematurely advanced")
APRData.test["test-delve"] = 2
APR:InvalidateEffectiveRouteStepsCache()
check(APR:GetRouteSteps("test-delve")[1] == setup, "Saved insertion survives cache reconstruction")
APR:ClearTemporaryRoute()
check(APRData.test["test-parent"] == 2, "Early exit preserves completed setup but keeps unfinished DoScenario")
APR:ActivateTemporaryRoute("test-delve", { mapID = 2528, scenarioID = 123, sessionKey = "test" })
APR:ClearTemporaryRoute({ completed = true, preserveSessionKey = true })
check(APR.ActiveRoute == "test-parent" and APRData.test["test-parent"] == 3,
    "Guide completion resumes after the replaced DoScenario")
APR:RefreshTemporaryDelveRoute()
check(prompts == 1, "A completed guide is not proposed again inside the same delve")
APR.RouteQuestStepList["test-parent"].steps = { setup, {}, {}, {}, {}, completion, after }
APRData.test["test-parent"] = 1
local startIndex, replaceIndex = APR:GetDelveInsertionPoint("test-parent", 2528)
check(startIndex == 1 and replaceIndex == 6, "The fifth upcoming step is included in the lookahead")
APR.RouteQuestStepList["test-parent"].steps = { setup, {}, {}, {}, {}, {}, completion }
startIndex, replaceIndex = APR:GetDelveInsertionPoint("test-parent", 2528)
check(startIndex == 1 and replaceIndex == nil, "A farther DoScenario cannot consume intervening main steps")
APR:ActivateTemporaryRoute("test-delve", { mapID = 2528, scenarioID = 123, sessionKey = "test" })
check(#APR:GetRouteSteps("test-delve") == 1, "Without a nearby DoScenario the guide starts immediately")
APR:ClearTemporaryRoute({ completed = true })
check(APRData.test["test-parent"] == 1, "Insertion at the current position preserves that main step")
APR:RefreshTemporaryDelveRoute()
decline()
APR:RefreshTemporaryDelveRoute()
check(prompts == 2 and APR.ActiveRoute == "test-parent", "Declining leaves the parent active without repeated prompts")
context = { mapID = 2528, scenarioID = 999, sessionKey = "unrecorded" }
APR:RefreshTemporaryDelveRoute()
check(prompts == 2, "An unrecorded scenario variant is not offered an unrelated guide")

print("Midnight alt: " .. count .. " checks passed")
