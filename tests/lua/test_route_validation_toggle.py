"""Exercise the actual settings toggle while startup validation is suspended."""

from pathlib import Path
import unittest
from unittest import mock

from tests.lua import test_route_hash_startup as startup


ROOT = Path(__file__).resolve().parents[2]


class RouteValidationToggleTests(unittest.TestCase):
    def test_escort_confirmation_rechecks_validation_context_and_settings(self):
        runtime = startup.RouteHashStartupTests().runtime()
        runtime.execute(r'''
H.fixture()
local accepted, modified = 0, false
function IsModifierKeyDown() return modified end
function APR:AcceptQuest() accepted = accepted + 1 end
APR.navigation.RequestUpdate = function() end
C_Timer.After = C_Timer.NewTimer
APR.settings.profile.autoAccept = true
local frame = { tag = "accept", callback = APR.event.functions.accept }
APR.event.EventHandler(frame, "QUEST_ACCEPT_CONFIRM")
assert(#H.timers == 1)
APR.event:ValidateStartupRoutes("long", H.complete)
local count = #H.timers
APR.event.EventHandler(frame, "QUEST_ACCEPT_CONFIRM")
assert(#H.timers == count, "Validation must not queue an escort acceptance")
H.tick()
assert(accepted == 0, "An acceptance queued before validation must stop while it is pending")
H.drain()
H.timers = {}

APR.event.EventHandler(frame, "QUEST_ACCEPT_CONFIRM")
assert(APR:ActivateRoute("short"))
H.tick()
assert(accepted == 0, "A delayed confirmation cannot accept on a changed route")
APR.event.EventHandler(frame, "QUEST_ACCEPT_CONFIRM")
APR.settings.profile.enableAddon = false
H.tick()
assert(accepted == 0, "Disabling automation cancels a previously queued confirmation")
APR.settings.profile.enableAddon = true
APR.event.EventHandler(frame, "QUEST_ACCEPT_CONFIRM")
modified = true
H.tick()
assert(accepted == 0, "A newly held modifier still blocks the delayed action")
modified = false
APR.routeValidationFailed = true
APR.event.EventHandler(frame, "QUEST_ACCEPT_CONFIRM")
assert(#H.timers == 0, "Failed validation must also leave escort acceptance dormant")
APR.routeValidationFailed = nil
APR.event.EventHandler(frame, "QUEST_ACCEPT_CONFIRM")
H.tick()
assert(accepted == 1, "A current enabled confirmation still accepts exactly once")
''')

    def test_startup_coroutine_with_diagnostic_capture_enabled(self):
        make_runtime = startup.LuaRuntime

        def with_instrumentation(*args, **kwargs):
            runtime = make_runtime(*args, **kwargs)
            runtime.execute((ROOT / "APR-Core/core/Diagnostics.lua").read_text(encoding="utf-8-sig"))
            return runtime

        with mock.patch.object(startup, "LuaRuntime", side_effect=with_instrumentation):
            runtime = startup.RouteHashStartupTests().runtime()
        for path in ("Performance.lua", "PerformanceScopes.lua"):
            runtime.execute((ROOT / "APR-Core/core" / path).read_text(encoding="utf-8-sig"))
        runtime.execute(r'''
H.fixture()
APR:SetPerformanceCapture(true)
APR:SetDebugCapture(true)
APR.event:ValidateStartupRoutes("long", H.complete)
H.tick()
assert(APR.routeValidationPending and not APRInstrumentation.CurrentName(),
    "A suspended hash worker must release the caller's diagnostic stack")
assert(H.drain() > 1 and H.ready == 1 and #H.errors == 0)
assert(not APRInstrumentation.CurrentName() and not APRData.player.long,
    "Instrumented yields resume, commit once and leave no active diagnostic frame")
local found = false
for name, record in pairs(APRData.PerformanceLog.summary) do
    if name:find("APR:CheckCurrentRouteUpToDate", 1, true) then
        found = true
        assert(record.count == 1 and record.totalMs >= 0)
    end
end
assert(found, "The completed startup scan remains represented in diagnostic timings")
APR:SetDebugCapture(false)
APR:SetPerformanceCapture(false)
''')

    def test_settings_toggle_preserves_pending_intentions_and_resumes_once(self):
        runtime = startup.RouteHashStartupTests().runtime()
        runtime.execute(r'''
local function noop() end
function APR:NewModule(name)
    assert(name == "Settings")
    return self.settings
end
local ui = { HideFrame = noop, Hide = noop, SendGroupMessageDelete = noop,
    SetCoord = noop, RequestData = noop, RefreshCurrentStepFrameAnchor = noop,
    RefreshFrameAnchor = noop, RefreshPartyFrameAnchor = noop, Refresh = noop,
    ToggleMapPins = noop }
for _, key in ipairs({ "AFK", "ArrowFrame", "Arrow", "party", "currentStep", "questOrderList",
    "heirloom", "Buff", "XPBuffOverlay", "coordinate", "RouteSelection", "map" }) do
    APR[key] = ui
end
''')
        runtime.execute((ROOT / "APR-Core/config/Config.lua").read_text(encoding="utf-8-sig"),
                        name="@APR-Core/config/Config.lua")
        runtime.execute(r'''
H.fixture()
APR.event:ValidateStartupRoutes("long", H.complete)
local obsolete = H.timers[1]
H.tick()
APR:ResetRoute("short")
APR:ClearSavedRouteData("long")
APR.settings.profile.enableAddon = false
APR.settings:ToggleAddon()
assert(not APR.routeValidationPending and not APR.event.routeValidationJob
    and APR.routeValidationFailed and APR.event.routeValidationResume,
    "Disabling through the actual settings control suspends unfinished validation")
obsolete.callback()
assert(H.ready == 0 and APRData.player.short == 1)

APR.settings.profile.enableAddon = true
APR.settings:ToggleAddon()
assert(APR.routeValidationPending and not APR.routeValidationFailed,
    "The actual enable control must restart validation without RegisterEvents")
H.drain()
assert(H.ready == 1 and APRData.player.short == 1,
    "A manual reset survives cancellation and resumed startup")
assert(APRData.player.long == nil and APRData.player["long-RawTotalSteps"] == nil
    and APRData.player.RouteSignatures.long == nil,
    "A manual clear is not resurrected when startup resumes")
assert(not APR.event.routeValidationResume and not APR.routeValidationFailed)
APR.settings:ToggleAddon()
assert(not APR.routeValidationPending and H.ready == 1,
    "Enabling an already initialized addon creates no duplicate job or continuation")
APR.settings.profile.enableAddon = false
APR.settings:ToggleAddon()
APR.settings.profile.enableAddon = true
APR.settings:ToggleAddon()
assert(not APR.routeValidationPending and not APR.routeValidationFailed and H.ready == 1)
''')


if __name__ == "__main__":
    unittest.main()
