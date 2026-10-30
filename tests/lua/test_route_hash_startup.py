"""Compatibility fingerprints and atomic, cooperative startup validation."""

from pathlib import Path
import struct
import unittest

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[2]


def _signed(value):
    value &= 0xFFFFFFFF
    return value - 0x100000000 if value >= 0x80000000 else value


def _bit_number(value):
    # LuaBitOp's double-number normalization uses this IEEE-754 conversion.
    # A modulo-32 mock would silently change the addon's historical hashes:
    # FNV's intermediate products exceed the exact-integer range of doubles.
    low = struct.unpack("<I", struct.pack("<d", float(value) + 6755399441055744.0)[:4])[0]
    return _signed(low)


ENV = r'''
local function noop() end
H = { clock = 0, charge = 0, bytes = 0, timers = {}, errors = {}, renders = 0, ready = 0 }
H.negativePrefix = #string.format("%x", -1) > 8 and "ffffffff" or ""
local nativeBand = bit.band
bit.band = function(a, b)
    H.bytes = H.bytes + 1
    H.clock = H.clock + H.charge
    return nativeBand(a, b)
end
function GetTime() return H.clock / 1000 end
function IsModifierKeyDown() return false end
function debugprofilestop() return H.clock end
function geterrorhandler() return function(err) H.errors[#H.errors + 1] = err end end
function wipe(values) for key in pairs(values) do values[key] = nil end end
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
function CreateFrame()
    return { events = {}, scripts = {}, RegisterEvent = function(self, event) self.events[event] = true end,
        SetScript = function(self, name, fn) self.scripts[name] = fn end,
        UnregisterAllEvents = noop }
end
C_Timer = { NewTimer = function(delay, callback)
    local timer = { callback = callback, delay = delay, Cancel = function(self) self.cancelled = true end }
    H.timers[#H.timers + 1] = timer
    return timer
end }
APR = { PlayerID = "player", ActiveRoute = "long", version = "new", RouteQuestStepList = {},
    EXPANSIONS = { Custom = "custom" }, GAME_VERSIONS = {}, settings = { profile = { enableAddon = true } },
    NewModule = function() return {} end, Debug = noop, PrintInfo = noop,
    DebugEvent = noop, IsInstanceWithUI = function() return true end, MaybePromptInstanceUIPreference = noop,
    RefreshInstanceUIVisibility = noop,
    GetCurrentStep = noop,
    StartPerformanceSample = noop, FinishPerformanceSample = noop,
    currentStep = {}, npcInteraction = { Clear = noop, QueueResume = noop, Track = noop },
    IsSojournerSkipActive = function() return false end, StepFilterQoL = function() return true end,
    GetGameVersion = noop, ResetQuestTitleRequests = noop,
    questionDialog = { CreateMessagePopup = function() H.popups = (H.popups or 0) + 1 end },
}
function APR:GetSettingsProfile() return self.settings.profile end
function APR:RegisterSupportedEvent(frame, event) frame:RegisterEvent(event); return true end
function APR:RenderCurrentStep() H.renders = H.renders + 1 end
function APR:GetCurrentRouteMapIDsAndName() return nil, 0, H.selection or self.ActiveRoute end
APRData, APRCustomPath, APRZoneCompleted = { player = {} }, { player = {} }, { player = {} }
'''


class RouteHashStartupTests(unittest.TestCase):
    def runtime(self):
        runtime = LuaRuntime(unpack_returned_tuples=True)
        runtime.globals().bit = runtime.table_from({
            "bxor": lambda left, right: _signed(_bit_number(left) ^ _bit_number(right)),
            "band": lambda left, right: _signed(_bit_number(left) & _bit_number(right)),
        })
        runtime.execute(ENV)
        for path in (
            "utils/RouteHashUtils.lua", "utils/RouteUtils.lua", "features/questing/RouteManager.lua",
            "features/questing/DelveRoutes.lua", "features/questing/StepTransitions.lua",
            "features/questing/QuestHandler.lua", "features/navigation/Navigation.lua", "core/Event.lua",
        ):
            runtime.execute((ROOT / "APR-Core" / path).read_text(encoding="utf-8-sig"), name="@APR-Core/" + path)
        runtime.execute(r'''
function APR:GetCurrentRouteMapIDsAndName() return nil, 0, H.selection or self.ActiveRoute end
function APR:GetRouteDisplayName(key) return key end
function APR:GetRouteMapIDsAndName(key) return nil, 0, key end
function H.fixture()
    APR.RouteQuestStepList = { long = { steps = { { Note = string.rep("x", 4096) } } },
        short = { steps = { { Note = "A" } } } }
    APR.ActiveRoute, H.selection = "long", "long"
    APRData.player = { long = 7, short = 4, ["long-RawTotalSteps"] = 1, ["short-RawTotalSteps"] = 1,
        RouteSignatures = { long = "outdated", short = "outdated" },
        ["long-ParallelStepsState"] = { groups = {} } }
    APRCustomPath.player, APRZoneCompleted.player = { "long", "short" }, { short = true }
    H.charge, H.clock, H.bytes, H.ready, H.timers, H.errors = 0.01, 0, 0, 0, {}, {}
end
function H.tick()
    local pending = H.timers
    H.timers = {}
    local before = H.clock
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
    local elapsed = H.clock - before
    H.largest = math.max(H.largest or 0, elapsed)
    assert(elapsed < 3.3, "The 2 ms batch stops after at most one 128-byte chunk")
end
function H.drain()
    local count = 0
    while APR.routeValidationPending do
        H.tick(); count = count + 1
        assert(count < 1000, "Startup validation must complete")
    end
    return count
end
function H.complete(route)
    assert(not APR.routeValidationPending and not APR.event.routeValidationJob)
    H.ready, H.readyRoute = H.ready + 1, route
end
''')
        return runtime

    def test_historical_golden_signatures_and_checkpoint_equivalence(self):
        runtime = self.runtime()
        runtime.execute(r'''
-- Golden bytes were independently enumerated in sorted-key order and evaluated
-- with the historical LuaBitOp double normalization, never using HashValue.
APR.RouteQuestStepList = {
    empty = { steps = {} }, note = { steps = { { Note = "A" } } },
    scalars = { steps = { [1] = "a", [2] = false, [10] = 23 } },
    parallel = { steps = {}, parallelSteps = {
        { conditions = { MinLevel = 5 }, steps = { { Note = "P" } } },
    } }, legacy = { { Note = "A" } },
}
local expected = { empty = H.negativePrefix .. "ec1c201f", note = H.negativePrefix .. "eb639929", scalars = "187b576a",
    parallel = "5ffc825c", legacy = H.negativePrefix .. "eb639929" }
for name, golden in pairs(expected) do
    assert(APR:GetRouteSignature(name) == golden, name .. " changed its persisted compatibility fingerprint")
    local calls = 0
    assert(APR:GetRouteSignature(name, function() calls = calls + 1 end) == golden)
end
APR.RouteQuestStepList.note.steps[1]._index = 12345
APR.RouteQuestStepList.note.label = "Renamed display label"
assert(APR:GetRouteSignature("note") == expected.note)
assert(APR:GetRouteSignature("missing") == nil)
local long = { steps = { { Note = string.rep("a", 1025) } } }
APR.RouteQuestStepList.long = long
local signature = APR:GetRouteSignature("long")
local thread = coroutine.create(function() return APR:GetRouteSignature("long", coroutine.yield) end)
local ok, result, yields = true, nil, 0
repeat ok, result = coroutine.resume(thread); assert(ok); yields = yields + 1
until coroutine.status(thread) == "dead"
assert(result == signature and yields > 8, "Long strings must yield within the byte loop without changing their signature")
''')

    def test_bounded_startup_and_atomic_publication_with_barriers(self):
        runtime = self.runtime()
        runtime.execute(r'''
H.fixture()
local before = H.clock
APR:CheckCurrentRouteUpToDate("long")
assert(H.clock - before > 40, "The unsliced legacy call reproduces the long single-frame fingerprint scan")
H.fixture()
APR.event:ValidateStartupRoutes("long", H.complete)
local token = APR.routeValidationPending
local callbacks = #H.timers
APR:UpdateStep()
APR.navigation:Update()
APR.navigation:RequestUpdate()
assert(H.renders == 0 and #H.timers == callbacks and APRData.player.long == 7)
assert(not APR:AdvanceStep(false) and not APR:CommitManualSkip(8))
assert(not APR:SetRouteProgress("long", 8, "automatic"))
assert(not APR:ActivateTemporaryRoute("short") and not APR:ClearTemporaryRoute())
local observations = 0
APR.event.EventHandler({ tag = "test", callback = function()
    observations = observations + 1
    assert(not APR:AdvanceStep(false))
end }, "TEST")
assert(observations == 1, "Native events remain observable while their step transitions wait")
H.tick()
assert(APR.routeValidationPending == token and APRData.player.long == 7 and APRData.player.short == 4
    and APRData.player.RouteSignatures.long == "outdated" and APRData.player.RouteSignatures.short == "outdated"
    and APRZoneCompleted.player.short, "No partial reset or fingerprint can escape a yielded scan")
assert(H.drain() > 10 and H.ready == 1 and H.readyRoute == "long")
assert(APRData.player.long == nil and APRData.player.short == nil and not APRZoneCompleted.player.short)
assert(APRData.player["long-ParallelStepsState"] == nil and APRData.player["long-RawTotalSteps"] == 1)
assert(APRData.player.RouteSignatures.short == H.negativePrefix .. "eb639929")
APR:UpdateStep()
assert(H.renders == 1, "The renderer resumes after validation releases its barrier")
''')

    def test_cancel_error_retry_and_stale_callbacks(self):
        runtime = self.runtime()
        runtime.execute(r'''
H.fixture()
APR.event:ValidateStartupRoutes("long", H.complete)
local stale = H.timers[1]
H.tick()
APR.event:ValidateStartupRoutes("long", H.complete)
local replacement = APR.routeValidationPending
stale.callback()
assert(APR.routeValidationPending == replacement and H.ready == 0)
APR.event:CancelRouteValidation()
assert(not APR.routeValidationPending and APRData.player.long == 7 and H.ready == 0)
stale.callback()
assert(H.ready == 0)

local real = APR.GetRouteSignature
APR.GetRouteSignature = function(self, name, checkpoint)
    local result = real(self, name, checkpoint)
    error("synthetic fingerprint failure after hashing " .. name)
end
APR.event:ValidateStartupRoutes("long", H.complete)
H.drain()
assert(#H.errors == 1 and H.errors[1]:find("synthetic fingerprint failure", 1, true))
assert(H.ready == 0 and APRData.player.long == 7 and APRData.player.short == 4
    and APRData.player.RouteSignatures.long == "outdated" and APRZoneCompleted.player.short,
    "A hash failure cannot publish any planned cleanup")
APR.GetRouteSignature = real
APR.event:ValidateStartupRoutes("long", H.complete)
H.drain()
assert(H.ready == 1 and APRData.player.long == nil)

H.fixture()
APR.event:ValidateStartupRoutes("long", H.complete)
H.tick()
APR.settings.profile.enableAddon = false
H.tick()
assert(not APR.routeValidationPending and H.ready == 0 and APRData.player.long == 7)
APR.settings.profile.enableAddon = true
APR.event:ValidateStartupRoutes("long", H.complete)
H.tick()
APRData.player = { long = 99 }
H.tick()
assert(not APR.routeValidationPending and H.ready == 0 and APRData.player.long == 99)
''')

    def test_selection_reset_clear_and_replaced_definition_during_validation(self):
        runtime = self.runtime()
        runtime.execute(r'''
H.fixture()
APR.event:ValidateStartupRoutes("long", H.complete)
H.tick()
H.selection, APRCustomPath.player = "short", { "short" }
assert(APR:ActivateRoute("short"))
APR:ResetRoute("short")
assert(APRData.player.short == 1 and APR.routeValidationPending.manualResets.short)
APR:ClearSavedRouteData("long")
H.drain()
assert(H.ready == 1 and H.readyRoute == "short" and APR.ActiveRoute == "short")
assert(APRData.player.short == 1 and APRData.player.RouteSignatures.short == H.negativePrefix .. "eb639929")
assert(APRData.player.long == nil and APRData.player["long-RawTotalSteps"] == nil
    and APRData.player.RouteSignatures.long == nil, "Explicitly cleared entries must never be resurrected")

H.fixture()
APR.event:ValidateStartupRoutes("long", H.complete)
H.tick()
APR.RouteQuestStepList.long = { steps = { { Note = "B" } } }
H.drain()
assert(H.ready == 1 and APRData.player.RouteSignatures.long == "3f461f76",
    "Replacing a definition discards the old scan before publishing its signature")
H.fixture()
APR.event:ValidateStartupRoutes("long", H.complete)
H.tick()
APR:ClearSavedRouteData("short")
APR:ResetRoute("short")
H.drain()
assert(APRData.player.short == 1 and APRData.player.RouteSignatures.short == H.negativePrefix .. "eb639929",
    "The latest explicit reset supersedes an earlier clear")
''')

    def test_failed_once_retry_is_bounded_and_preserves_user_intentions(self):
        runtime = self.runtime()
        runtime.execute(r'''
H.fixture()
local real, attempts = APR.GetRouteSignature, 0
APR.GetRouteSignature = function(self, name, checkpoint)
    attempts = attempts + 1
    if attempts == 1 then error("transient synthetic failure") end
    return real(self, name, checkpoint)
end
APR.event:ValidateStartupRoutes("long", H.complete)
H.drain()
assert(APR.routeValidationFailed and #H.errors == 1 and H.ready == 0)
APR:UpdateStep(); APR.navigation:Update(); assert(H.renders == 0)
APR:ResetRoute("short")
APR:ClearSavedRouteData("long")
H.selection, APRCustomPath.player = "short", { "short" }
APR:ActivateRoute("short")
H.tick(); H.drain()
assert(not APR.routeValidationFailed and H.ready == 1 and H.readyRoute == "short")
assert(APRData.player.short == 1 and APRData.player.long == nil and APRData.player["long-RawTotalSteps"] == nil
    and APRData.player.RouteSignatures.long == nil)

H.fixture()
APR.GetRouteSignature = function() error("permanent synthetic failure") end
APR.event:ValidateStartupRoutes("long", H.complete)
H.drain(); H.tick(); H.drain()
assert(#H.errors == 2 and APR.routeValidationFailed and H.ready == 0 and #H.timers == 0,
    "Permanent failures stop after one asynchronous retry")
APR.GetRouteSignature = real
assert(APR.event:ResumeRouteValidation())
H.drain()
assert(H.ready == 1 and not APR.routeValidationFailed)
''')

    def test_nil_replacements_clear_revision_and_in_place_source_swap(self):
        runtime = self.runtime()
        runtime.execute(r'''
H.fixture()
APRData.player.RouteSignatures.unrelated = "keep only until explicitly replaced"
APRZoneCompleted.player.Other = true
local thread = coroutine.create(function() return APR:CheckCurrentRouteUpToDate("long", coroutine.yield) end)
assert(coroutine.resume(thread))
APRData.player.RouteSignatures, APRZoneCompleted.player = nil, nil
local ok, result
repeat ok, result = coroutine.resume(thread); assert(ok) until coroutine.status(thread) == "dead"
assert(result == false and APRData.player.RouteSignatures == nil and APRZoneCompleted.player == nil,
    "Replacing captured dictionaries with nil must not resurrect either old table")

H.fixture()
local real, hashed = APR.GetRouteSignature, nil
APR.GetRouteSignature = function(self, name, checkpoint)
    local signature = real(self, name, checkpoint)
    hashed = name
    return signature
end
thread = coroutine.create(function()
    return APR:CheckCurrentRouteUpToDate("long", function() if hashed then coroutine.yield() end end)
end)
assert(coroutine.resume(thread))
assert(hashed)
local cleared = hashed
APR:ClearSavedRouteData(cleared)
repeat ok, result = coroutine.resume(thread); assert(ok) until coroutine.status(thread) == "dead"
assert(result == false and APRData.player.RouteSignatures[cleared] == nil
    and APRData.player[cleared .. "-RawTotalSteps"] == nil,
    "The checkpoint API also rejects plans invalidated by a direct explicit clear")
APR.GetRouteSignature = real

H.fixture()
APR.event:ValidateStartupRoutes("long", H.complete)
H.tick()
APR.RouteQuestStepList.long.steps = { { Note = "B" } }
H.drain()
assert(H.ready == 1 and APRData.player.RouteSignatures.long == "3f461f76",
    "Swapping steps inside an unchanged definition object must restart the fingerprint scan")
''')

    def test_native_observations_taxi_and_npc_reconciliation(self):
        runtime = self.runtime()
        runtime.execute((ROOT / "APR-Core/features/questing/NPCInteraction.lua").read_text(encoding="utf-8-sig"))
        runtime.execute((ROOT / "APR-Core/features/navigation/FlightPath.lua").read_text(encoding="utf-8-sig"))
        runtime.execute(r'''
H.fixture()
local npc = APR.npcInteraction
local step = { UseFlightPath = true, NodeID = 20 }
APR.GetCurrentStep = function() return step end
QuestFrameDetailPanel = { IsVisible = function() return true end }
QuestFrameGreetingPanel = { IsVisible = function() return true end }
npc:Track("detail", "QUEST_DETAIL")
local before = npc.interaction
local cancelled, autocompleteCancelled = 0, 0
npc.resumeTimer = { Cancel = function() cancelled = cancelled + 1 end }
npc.vendorTimer = { Cancel = function() cancelled = cancelled + 1 end }
APR.CancelAutocompleteQuest = function() autocompleteCancelled = autocompleteCancelled + 1 end
APR.event:ValidateStartupRoutes("long", H.complete)
assert(cancelled == 2 and autocompleteCancelled == 1 and npc.interaction == before
    and not npc.interaction.context, "Pending actions are cancelled while the visible NPC observation survives")
npc:HandleQuestDetail("QUEST_DETAIL", {})
npc:HandleQuestDone("QUEST_COMPLETE", {})
npc:HandleGossip("GOSSIP_SHOW", {})
npc:HandleQuestGreeting("QUEST_GREETING", {})
npc:HandleMerchantPurchase({ BuyMerchant = { { itemID = 1 } } })
npc:HandleMerchant("MERCHANT_SHOW", {})
assert(APR.routeMerchantOpen, "Merchant visibility is observed without buying, repairing or selling")
npc:HandleMerchant("MERCHANT_CLOSED", {})
assert(not APR.routeMerchantOpen)

local resets, scheduled = 0, 0
APR.routeconfig = { CheckRouteResetOnLvlUp = function() resets = resets + 1 end, SendMessage = function() end }
APR.event.EventHandler({ tag = "lvlUp", callback = APR.event.functions.lvlUp }, "PLAYER_LEVEL_UP", 42)
assert(APR.Level == 42 and resets == 1 and H.renders == 0)
APRData.player.TemporaryRouteState = { routeKey = "long" }
APRScenarioMapIDCompleted = { player = {} }
C_Map = { GetBestMapForUnit = function() return 70 end }
APR.GetScenarioZoneInfo = function() return nil end
APR.ScheduleDelveRouteRefresh = function() scheduled = scheduled + 1 end
function tContains(values, wanted) for _, value in ipairs(values) do if value == wanted then return true end end end
tinsert = table.insert
APR.event.EventHandler({ tag = "scenario", callback = APR.event.functions.scenario }, "SCENARIO_COMPLETED")
assert(APRData.player.TemporaryRouteState.scenarioCompleted and APRScenarioMapIDCompleted.player[1] == 70
    and scheduled == 1, "One-shot native scenario evidence is retained while progression is blocked")

Enum = { FlightPathState = { Current = 1, Reachable = 2, Unreachable = 3 } }
function GetTaxiMapID() return 1 end
C_TaxiMap = { GetAllTaxiNodes = function() return { { nodeID = 10, state = 1 }, { nodeID = 20, state = 2 } } end }
APRTaxiNodes = { player = {} }
local taxiObservations = 0
APR.taxiData = { ObserveTaxiMap = function() taxiObservations = taxiObservations + 1 end,
    CanTake = function() error("Cannot pay for an unvalidated flight") end, CloseTaxiMap = function() end }
function TakeTaxiNode() error("Cannot take an unvalidated flight") end
APR.settings.profile.autoFlight = true
APR.flightPath.eventFrame.scripts.OnEvent(nil, "TAXIMAP_OPENED")
assert(taxiObservations == 1 and APRTaxiNodes.player[10] and APRTaxiNodes.player[20])

local resumed = 0
npc.HandleQuestDetail = function(_, _, fresh) assert(fresh == step); resumed = resumed + 1 end
H.drain()
npc:QueueResume(); H.tick()
assert(resumed == 1, "An NPC page opened before validation resumes against a fresh checked context")
H.fixture()
APR.event:ValidateStartupRoutes("long", H.complete)
npc:Track("greeting", "QUEST_GREETING")
assert(not npc.interaction.context)
npc.HandleQuestGreeting = function() resumed = resumed + 1 end
H.drain(); npc:QueueResume(); H.tick()
assert(resumed == 2, "An NPC page opened during validation also reconciles after success")
''')

    def test_one_native_advance_receipt_is_coalesced_and_revalidated(self):
        runtime = self.runtime()
        runtime.execute(r'''
H.fixture()
APRData.player.long, APRData.player.short = 1, 1
APRData.player.RouteSignatures.long = APR:GetRouteSignature("long")
APRData.player.RouteSignatures.short = APR:GetRouteSignature("short")
APR.event:ValidateStartupRoutes("long", H.complete)
for _ = 1, 100 do assert(not APR:AdvanceStep(false)) end
assert(APRData.player.long == 1 and APR.routeValidationPending.advance.index == 1)
APR.event:CancelRouteValidation(true)
assert(APR.event:ResumeRouteValidation())
H.drain()
assert(H.ready == 1 and APRData.player.long == 2, "100 duplicate native completions advance exactly once after validation")

H.fixture()
APRData.player.long = 1
APRData.player.RouteSignatures.long = APR:GetRouteSignature("long")
APR.event:ValidateStartupRoutes("long", H.complete)
APR:AdvanceStep(false)
APR:ResetRoute("long")
assert(not APR.routeValidationPending.advance)
H.drain()
assert(APRData.player.long == 1, "An explicit reset to the same index retires the earlier native receipt")

H.fixture()
APR.event:ValidateStartupRoutes("long", H.complete)
APR:AdvanceStep(false)
H.drain()
assert(APRData.player.long == nil, "A changed fingerprint rejects the old step's native completion")
''')
