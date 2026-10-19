local L = setmetatable({ MANUAL_SKIP = "Manually skip this step if it does not complete automatically" },
    { __index = function(_, key) return key end })
BOSS, ENTER_DUNGEON, LEAVE_ZONE = "Boss", "Enter Dungeon", "Leave %s"
function LibStub() return { GetLocale = function() return L end } end
local eventHandler
function CreateFrame()
    return { RegisterEvent = function() end, SetScript = function(_, _, fn) eventHandler = fn end }
end
local inside, instanceID, instanceType = false, 0, "none"
function IsInInstance() return inside, instanceType end
function GetInstanceInfo() return "instance", instanceType, 0, "", 0, 0, false, instanceID end
local step = { EnterInstance = { dungeonKey = "RFC" }, Dungeon = "RFC", InstanceQuest = true }
local advanced, refreshes, labels = 0, 0, {}
APR = { PlayerID = "one", ActiveRoute = "rfc", stepHandlers = {}, currentStep = {},
    settings = { profile = { enableAddon = true } } }
APRData = { one = { rfc = 1 }, two = { rfc = 1 } }
function APR:GetCurrentStep() return step end
function APR:UpdateNextStep() advanced = advanced + 1 end
function APR:UpdateStep() refreshes = refreshes + 1 end
function APR.currentStep:AddQuestSteps(_, text) table.insert(labels, text) end
dofile("APR-Core/utils/DungeonUtils.lua")
dofile("APR-Core/features/questing/StepTravelHandlers.lua")

-- New dungeon travel must never call the scenario APIs or pass a nil quest ID.
APR.stepHandlers.RenderScenarioTravel(step, 1)
assert(advanced == 0 and labels[1] == "Enter Dungeon: Ragefire Chasm")
inside, instanceID, instanceType = true, 2999, "party"
APR.stepHandlers.RenderScenarioTravel(step, 1)
assert(advanced == 0, "An unrelated instance cannot satisfy entry")
instanceID = 389
APR.stepHandlers.RenderScenarioTravel(step, 1)
assert(advanced == 1 and APR:IsInDungeonStepContext(step))

-- Death observed on an earlier quest step counts at the later boss checkpoint.
step = { Dungeon = "RFC", InstanceQuest = true, Qpart = { [5723] = { 1 } } }
assert(APR:RecordDungeonDeath("Creature-0-1-389-2-11520-00001"))
step = { Dungeon = "RFC", InstanceQuest = true,
    KillNPC = { dungeonKey = "RFC", npcID = 11520, name = "Taragaman" } }
APR:RenderDungeonKill(step, true)
assert(advanced == 2)
local saved = APR:GetDungeonRun("rfc", "RFC")
APR:ObserveDungeonLocation(step)
assert(saved == APR:GetDungeonRun("rfc", "RFC") and saved.kills[11520], "Reload/refresh retains run credit")

APR.PlayerID = "two"
APR:RenderDungeonKill(step, true)
assert(advanced == 2, "Other characters have separate runs")
APR.PlayerID = "one"
instanceID = 43
assert(not APR:RecordDungeonDeath("Creature-0-1-43-2-11520-00001"))
APR:RenderDungeonKill(step, true)
assert(advanced == 2, "Matching NPC ID in the wrong instance cannot count")
instanceID = 389
assert(not APR:RecordDungeonDeath("Player-1-11520"))
assert(not APR:RecordDungeonDeath("Creature-0-1-389-2-11319-00001"), "Trash kills do not grow the saved run")

-- A different instance is not an exit; an exterior world zone is.
step = { Dungeon = "RFC", LeaveInstance = { dungeonKey = "RFC" }, InstanceQuest = true }
instanceID = 43
APR:RenderDungeonTravel(step)
assert(advanced == 2)
inside, instanceID, instanceType = false, 0, "none"
APR:RenderDungeonTravel(step)
assert(advanced == 3)
assert(not APR:RecordDungeonDeath("Creature-0-1-389-2-11520-00001"))

-- Re-entering at the portal checkpoint creates a fresh run; previous kills expire.
step = { Dungeon = "RFC", EnterInstance = { dungeonKey = "RFC" }, InstanceQuest = true }
APR:ObserveDungeonLocation(step)
inside, instanceID, instanceType = true, 389, "party"
APR:ObserveDungeonLocation(step)
assert(not APR:GetDungeonRun("rfc", "RFC").kills[11520])

-- Explicit resets work even if progress was already at step one.
APR:RecordDungeonDeath("Creature-0-1-389-2-11520-00001")
dofile("APR-Core/features/questing/StepTransitions.lua")
APR:SetRouteProgress("rfc", 1, "reset")
assert(not APR:GetDungeonRun("rfc", "RFC"))

-- Combat-log handling accepts death evidence only, not damage or target changes.
local subevent = "SWING_DAMAGE"
function CombatLogGetCurrentEventInfo()
    return 0, subevent, false, nil, nil, nil, nil, "Creature-0-1-389-2-11520-00001"
end
eventHandler(nil, "COMBAT_LOG_EVENT_UNFILTERED")
assert(not APR:GetDungeonRun("rfc", "RFC"))
subevent = "UNIT_DIED"
eventHandler(nil, "COMBAT_LOG_EVENT_UNFILTERED")
assert(APR:GetDungeonRun("rfc", "RFC").kills[11520])

-- Custom Forever boss IDs normalize only inside the correct instance.
APR.ActiveRoute = "dm"
step = { Dungeon = "DM", KillNPC = { dungeonKey = "DM", npcID = 644, name = "Rhahk'Zor" } }
inside, instanceID, instanceType = true, 36, "party"
assert(APR:RecordDungeonDeath("Creature-0-1-36-2-274298-00001"))
assert(APR:GetDungeonRun("dm", "DM").kills[644])
assert(not APR:GetDungeonRun("dm", "DM").kills[274298], "Alias credit uses the canonical checkpoint")
instanceID = 3065
assert(not APR:RecordDungeonDeath("Creature-0-1-3065-2-274298-00001"))
step = { Dungeon = "HOT", EnterInstance = { dungeonKey = "HOT" } }
assert(APR:IsInDungeonStepContext(step))
instanceID = 16919
assert(not APR:IsInDungeonStepContext(step), "A dungeon AreaID is not its instance ID")
