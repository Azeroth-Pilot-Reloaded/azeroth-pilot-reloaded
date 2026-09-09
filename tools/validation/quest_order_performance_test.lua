-- Allocation regression test for repeated long-route redraws without the WoW client.
local frames, fonts, registrations = 0, 0, 0
local function noop() end
local methods = {
    Hide = function(self) self.hidden = true end,
    Show = function(self) self.hidden = false end,
    SetScript = function(self, key, value) self.scripts[key] = value end,
    SetText = function(self, text) self.text = text end,
    SetWidth = noop, SetPoint = noop, ClearAllPoints = noop, SetParent = noop,
    SetHeight = noop, SetWordWrap = noop, SetJustifyH = noop, EnableMouse = noop,
    GetHeight = function() return 30 end,
    GetStringHeight = function() return 12 end,
    RegisterEvent = noop,
}
local function widget() return setmetatable({ scripts = {} }, { __index = methods }) end
function methods:CreateFontString()
    fonts = fonts + 1
    return widget()
end
function CreateFrame()
    frames = frames + 1
    return widget()
end
APR = { ActiveRoute = "long-route", PlayerID = "test" }
function APR:RegisterFontString() registrations = registrations + 1 end
function APR:SetFontStringRole(font, role) font.role = role end
GameTooltip = { GetOwner = noop, Hide = noop }
dofile("APR-Core/utils/QuestOrderListUtils.lua")
local utils = APR.questOrderListUtils
local rows = {}
for pass = 1, 30 do
    local layout = { scrollChild = {}, frameWidth = 258, dataHeight = 0 }
    for i = 1, 1000 do
        rows[i] = utils:AddStepFrameWithQuest(layout, i, "Quest", {
            { questID = 1 }, { questID = 2 }, { questID = 3 },
        }, "gray", false)
    end
    for _, row in ipairs(rows) do utils:ReleaseStepFrame(row) end
end
assert(frames == 1000 and fonts == 5000 and registrations == 5000,
    "Thirty redraws must reuse frames and fonts after the first render")
local row = utils:AddStepFrameWithQuest({ scrollChild = {}, frameWidth = 258, dataHeight = 0 },
    1, "Completed", {}, "green", false)
assert(row.scripts.OnEnter == nil and row.scripts.OnLeave == nil, "A reused completed row has no stale tooltip")
assert(#row.questFonts == 0 and row.questFontPool[1].hidden, "Old quest detail lines are hidden")
assert(row.titleFont.text == "Completed" and row.titleFont.role == "success", "Reused text and color are updated")
print("Quest list: 30 x 1000 rows; only 1000 frames / 5000 fonts allocated")

-- Profiling is opt-in and retains at most 100 slow records in SavedVariables.
function LibStub() return { GetLocale = function() return {} end } end
function APR:NewModule() return {} end
local now = 0
function debugprofilestop() return now end
APRData = { test = { ["long-route"] = 17 }, PerformanceLog = { summary = {}, slow = {} } }
dofile("APR-Core/core/Commands.lua")
assert(APR:StartPerformanceSample() == nil, "Profiling is disabled by default")
APR.performanceLogging = true
for i = 1, 200 do
    local start = APR:StartPerformanceSample()
    now = now + 11
    APR:FinishPerformanceSample("Render", start, 1000)
end
assert(#APRData.PerformanceLog.slow == 100 and APRData.PerformanceLog.summary.Render.count == 200,
    "Performance logs are bounded while summary counts remain complete")
assert(APRData.PerformanceLog.summary.Render.totalMs == 2200, "Recorded durations are accumulated correctly")
print("Performance capture: disabled by default; slow-record ring bounded to 100 entries")

-- A full route remains available, but no frame processes the whole route at once.
local owner, rendered, batches, completed = {}, 0, 0, false
utils:StartRender(owner, function()
    for i = 1, 1224 do
        rendered = rendered + 1
        now = now + 1
        coroutine.yield()
    end
end, function() return true end, function(finished)
    batches = batches + 1
    completed = finished
end)
assert(rendered == 0, "Scheduling a render must not synchronously build the list")
while owner.renderFrame.scripts.OnUpdate do
    local before = rendered
    owner.renderFrame.scripts.OnUpdate()
    assert(rendered - before <= 3, "Each frame obeys the time budget between rows")
end
assert(rendered == 1224 and completed and batches > 1, "Every row is eventually rendered")
assert(owner.renderFrame.hidden, "An idle renderer performs no per-frame work")
utils:StartRender(owner, function() error("Stale route must never render") end,
    function() return false end, noop)
owner.renderFrame.scripts.OnUpdate()
assert(owner.renderFrame.scripts.OnUpdate == nil, "A stale route cancels the renderer")
utils:StartRender(owner, function() error("Replaced worker must never render") end,
    function() return true end, noop)
local replacementRan = false
utils:StartRender(owner, function() replacementRan = true end, function() return true end, noop)
owner.renderFrame.scripts.OnUpdate()
assert(replacementRan, "A new render replaces the pending worker")
print("Quest list scheduling: all 1224 rows rendered in bounded batches; stale/replaced work cancelled")

local timers, totals, updates, renders = {}, 0, 0, 0
C_Timer = { NewTimer = function(_, callback)
    timers[#timers + 1] = callback
    return { Cancel = noop }
end }
function APR:GetTotalSteps() totals = totals + 1 end
function APR:UpdateStep() updates = updates + 1 end
APR.questOrderList = { DelayedUpdate = function(_, force)
    assert(force, "Reputation changes must refresh conditional rows")
    renders = renders + 1
end }
dofile("APR-Core/core/Event.lua")
for _ = 1, 100 do APR.event.functions.reputation() end
assert(#timers == 1 and totals == 0, "A reputation burst schedules a single refresh")
timers[1]()
assert(totals == 1 and updates == 1 and renders == 1, "The resulting route state is evaluated once")
APR.event.functions.reputation()
assert(#timers == 2, "Later reputation changes are not lost")
print("Reputation refresh: 100 events coalesced into one route/list update")

-- Banked, already-complete delve objectives must not rebuild the current step on every log event.
dofile("APR-Core/features/questing/QuestHandler.lua")
APR.QUEST_STATUS = { COMPLETE = "complete", PROGRESS = "progress" }
APR.ActiveQuests = { [93427] = {
    status = "complete", title = "Banked reward", objectives = { { text = "Done", status = "complete" } },
} }
local objectiveText = "Done"
C_QuestLog = {
    GetNumQuestLogEntries = function() return 1 end,
    GetInfo = function() return { questID = 93427 } end,
    GetTitleForQuestID = function() return "Banked reward" end,
    IsComplete = function() return true end,
    GetNumQuestObjectives = function() return 1 end,
    GetQuestObjectives = function() return { { text = objectiveText, finished = true } } end,
}
APR.currentStep = { UpdateQuestStep = noop }
APR.fillersFrame = { UpdateFillerStep = noop }
APR.party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop }
APR.Debug, APR.UpdateQpartPart = noop, noop
updates = 0
function APR:UpdateStep() updates = updates + 1 end
for _ = 1, 100 do APR:UpdateQuest() end
assert(updates == 0, "An unchanged banked reward cannot force repeated step rebuilds")
objectiveText = "Changed"
APR:UpdateQuest()
assert(updates == 1, "Changed quest objectives still refresh the current step")
print("Banked reward: 100 unchanged quest-log updates cause no step rebuild")

-- Quest removal must synchronize the cache before one render, without routing inline.
dofile("APR-Core/utils/StepUtils.lua")
local overrides = 0
APR.ActiveQuests = { [1] = {}, [2] = { status = "progress", objectives = {} } }
C_QuestLog.GetInfo = function() return { questID = 2 } end
C_QuestLog.IsQuestFlaggedCompleted = function() return true end
function APR:GetQuestAndStepIds() return { 1 }, "Done" end
function APR:OverrideRouteData() overrides = overrides + 1 end
function APR:UpdateMapId() error("Quest removal must not run navigation synchronously") end
function APR:UpdateStep()
    assert(self.ActiveQuests[1] == nil, "Removed quest stays removed")
    assert(self.ActiveQuests[2].objectives[1].text == objectiveText, "Rendering sees synchronized objectives")
    updates = updates + 1
end
updates = 0
APR.event.functions.remove("QUEST_REMOVED", 1)
assert(updates == 1 and overrides == 1, "Quest removal renders once and preserves route overrides")
objectiveText = "Changed again"
updates = 0
APR:UpdateQuestAndStep()
assert(updates == 1, "A combined refresh renders once even when objectives changed")
print("Quest removal and combined refresh: one render with current quest data; no inline routing")
