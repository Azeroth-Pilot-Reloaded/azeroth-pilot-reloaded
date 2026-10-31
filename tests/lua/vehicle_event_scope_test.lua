-- Native unit filtering and the RegisterEvent fallback must agree about whose
-- boarding observation can change this player's progress. No live route data.
local noop = function() end
local opaque = {}
function canaccessvalue(value) return value ~= opaque end
function LibStub() return { GetLocale = function() return {} end } end
function GetTime() return 0 end
function debugprofilestop() return 0 end
function wipe(values) for key in pairs(values) do values[key] = nil end end

local function fixture(nativeFiltering)
    local state = { errors = {}, refreshes = 0, nextCalls = 0, questRefreshes = 0, observations = 0, timers = {} }
    function geterrorhandler() return function(message) state.errors[#state.errors + 1] = message end end
    function CreateFrame()
        local frame = { events = {}, scripts = {} }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:SetScript(name, callback) self.scripts[name] = callback end
        if nativeFiltering then
            function frame:RegisterUnitEvent(event, unit)
                self.units = self.units or {}; self.units[event] = unit
                self:RegisterEvent(event)
            end
        end
        return frame
    end
    C_Timer = { NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        state.timers[#state.timers + 1] = timer
        return timer
    end }
    C_EventUtils = { IsEventValid = function() return true end }
    APR = { PlayerID = "player", ActiveRoute = "carriage", ActiveQuests = {},
        settings = { profile = { enableAddon = true } }, NewModule = function() return {} end,
        RouteQuestStepList = {
            carriage = { steps = { { MountVehicle = true }, { Note = "Boarding complete" } } },
            other = { steps = { { Note = "Another context" } } },
        }, Debug = noop, DebugEvent = noop, StartPerformanceSample = noop, FinishPerformanceSample = noop,
        IsInstanceWithUI = function() return true end, RefreshInstanceUIVisibility = noop,
        MaybePromptInstanceUIPreference = noop,
        npcInteraction = { Track = function() state.observations = state.observations + 1 end } }
    APRData = { player = { carriage = 1, other = 1 } }
    dofile("APR-Core/utils/SecretUtils.lua")
    dofile("APR-Core/utils/Utils.lua")
    dofile("APR-Core/features/questing/StepTransitions.lua")
    dofile("APR-Core/core/Event.lua")
    function APR:GetCurrentStep()
        local definition = self.RouteQuestStepList[self.ActiveRoute]
        return definition and definition.steps[APRData.player[self.ActiveRoute]]
    end
    function APR:UpdateStep()
        state.refreshes = state.refreshes + 1
        local hook = state.refreshHook
        state.refreshHook = nil
        if hook then hook() end
    end
    function APR:UpdateQuestAndStep()
        state.questRefreshes = state.questRefreshes + 1
        self:UpdateStep()
    end
    function APR:NextQuestStep()
        state.nextCalls = state.nextCalls + 1
        return self:AdvanceStep("quests")
    end
    APR.event:RegisterEvents()
    local receiver = APR.event.framePool.vehicle
    assert(receiver.events.UNIT_ENTERED_VEHICLE and receiver.events.UNIT_EXITED_VEHICLE)
    if nativeFiltering then
        assert(receiver.units.UNIT_ENTERED_VEHICLE == "player" and receiver.units.UNIT_EXITED_VEHICLE == "player")
    else assert(not receiver.units, "A client adapter without RegisterUnitEvent uses ordinary event registration") end
    function state:Emit(event, unit, ...)
        assert(receiver.events[event])
        -- Deliberately deliver foreign units even for the natively filtered
        -- receiver, to exercise the independent defensive handler contract.
        receiver.scripts.OnEvent(receiver, event, unit, ...)
        assert(#self.errors == 0, table.concat(self.errors, "\n"))
    end
    function state:Reset(step)
        APR.ActiveRoute, APRData.player.carriage, APRData.player.other = "carriage", 1, 1
        APR.RouteQuestStepList.carriage.steps = { step, { Note = "Boarding complete" } }
        self.refreshes, self.nextCalls, self.questRefreshes, self.observations, self.refreshHook = 0, 0, 0, 0, nil
    end
    return state
end

for _, nativeFiltering in ipairs({ true, false }) do
    local state = fixture(nativeFiltering)
    for _, unit in ipairs({ "party1", "pet", "raid7", "vehicle", "target" }) do
        for _, event in ipairs({ "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE" }) do
            state:Reset({ MountVehicle = true, InVehicle = 1 })
            state:Emit(event, unit)
            assert(APRData.player.carriage == 1 and state.nextCalls == 0 and state.refreshes == 0
                and state.questRefreshes == 0 and state.observations == 0,
                "Another unit's vehicle event cannot inspect or mutate the player's step")
        end
    end
    for _, event in ipairs({ "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE" }) do
        state:Reset({ MountVehicle = true, InVehicle = 1 })
        state:Emit(event, nil)
        state:Emit(event, opaque)
        assert(APRData.player.carriage == 1 and state.nextCalls == 0 and state.refreshes == 0,
            "The native contract requires a unit; absent or inaccessible payloads cannot prove boarding")
    end

    state:Reset({ MountVehicle = true })
    state:Emit("UNIT_ENTERED_VEHICLE", "player", true, true, 5, "synthetic-vehicle", true, false)
    assert(APRData.player.carriage == 2 and state.nextCalls == 1 and state.questRefreshes == 1
        and state.refreshes == 1, "The player's completed entry retains normal quest/step progression")

    state:Reset({ MountVehicle = true })
    state:Emit("UNIT_EXITED_VEHICLE", "player")
    assert(APRData.player.carriage == 1 and state.nextCalls == 0 and state.refreshes == 0,
        "Leaving a vehicle never satisfies a request to board it")

    for _, event in ipairs({ "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE" }) do
        state:Reset({ InVehicle = 2 })
        state:Emit(event, "player")
        assert(APRData.player.carriage == 1 and state.refreshes == 1 and state.nextCalls == 0,
            "Entering and leaving refresh the player's current InVehicle presentation without inventing progress")
    end

    state:Reset({ MountVehicle = true, InVehicle = 1 })
    state:Emit("UNIT_ENTERED_VEHICLE", "player")
    assert(APRData.player.carriage == 2 and state.nextCalls == 1 and state.refreshes == 2,
        "A combined instruction preserves both the state refresh and one valid boarding transition")

    for _, replace in ipairs({
        function() APR:ActivateRoute("other", "manual") end,
        function() APR:SetRouteProgress("carriage", 2, "manual") end,
        function() APR.RouteQuestStepList.carriage = { steps = { { MountVehicle = true }, {} } } end,
    }) do
        state:Reset({ MountVehicle = true, InVehicle = 1 })
        state.refreshHook = replace
        state:Emit("UNIT_ENTERED_VEHICLE", "player")
        assert(state.refreshes == 1 and state.nextCalls == 0 and state.questRefreshes == 0,
            "A refresh which replaces route, progress or definition retires the old boarding context")
        assert(APRData.player.other == 1)
    end

    -- Only events with a native unit payload belong in the dispatcher's unit
    -- filter. Payload-free vehicle notifications must still reach their owner.
    local unitless = 0
    APR.event.EventHandler({ tag = "vehicle", callback = function() unitless = unitless + 1 end }, "VEHICLE_UPDATE")
    assert(unitless == 1, "The unit filter must not drop native payload-free notifications")
    local beforeRefreshes, beforeCalls = state.refreshes, state.nextCalls
    APR.event.EventHandler({ tag = "vehicle", callback = APR.event.functions.vehicle }, "VEHICLE_UPDATE")
    assert(state.refreshes == beforeRefreshes and state.nextCalls == beforeCalls,
        "A payload-free notification is not an entered-vehicle confirmation")
    assert(#state.errors == 0 and #state.timers == 0, "Vehicle handling is synchronous and owns no stale delayed actions")
end
print("Vehicle events: player entry/exit, foreign/missing/opaque units, changed contexts and unit-filter fallback passed")
