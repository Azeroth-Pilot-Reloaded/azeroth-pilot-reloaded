"""Joined quest journeys through native events, real popup actions and rendering."""

from pathlib import Path
import unittest

from tests.lua import test_route_hash_startup as startup


ROOT = Path(__file__).resolve().parents[2]


class AddonJourneyQuestTests(unittest.TestCase):
    def runtime(self):
        # Reuse the native-bit adapter only. The journey fixture replaces its
        # API surface and reloads every participating production module.
        runtime = startup.RouteHashStartupTests().runtime()
        runtime.execute((ROOT / "tests/lua/addon_journey_quest_env.lua").read_text(encoding="utf-8"))
        return runtime

    def test_accept_suggest_condition_parallel_filler_reward_and_startup_resume(self):
        runtime = self.runtime()
        runtime.execute(r'''
H.quest(702, "Optional 0/5")
H.quest(701, "Main 0/3")
APR:InitRouteTriggersSuggestion()
local cancelled = APR._routeTriggerBuild.timer
for _ = 1, 20 do H.emit("QUEST_ACCEPTED", 701) end
assert(not APRRouteTriggerPopup and not APR.ActiveRoute)
APR:InitRouteTriggersSuggestion()
assert(cancelled.cancelled)
cancelled.callback()
H.settle()
assert(APRRouteTriggerPopup:IsShown() and #APRRouteTriggerPopup.routeButtons == 1)
assert(APRRouteTriggerPopup.routeButtons[1]:GetText() == "Synthetic quest path")
APRRouteTriggerPopup.cancelButton.scripts.OnClick()
assert(not APRRouteTriggerPopup:IsShown() and APR.ActiveRoute == nil)
H.emit("QUEST_ACCEPTED", 701)
APRRouteTriggerPopup.routeButtons[1].scripts.OnClick()
assert(APR.ActiveRoute == "journey" and APRCustomPath.player[1] == "Synthetic quest path")
for _ = 1, 30 do H.emit("QUEST_LOG_UPDATE") end
H.emit("UNIT_QUEST_LOG_CHANGED", "party1")
H.settle()
assert(APRData.player.journey == 3 and APRData.player["journey-SkippedStep"] == 1,
    "Accepted pickup advances, and real faction filtering skips exactly its synthetic excluded step")
assert(APR.currentStep.questsList["701-1"].objectiveText == "Main 0/3")
assert(APR.currentStep.fillersList["702-1"].objectiveText == "Optional 0/5")

H.quest(703, "Parallel 0/1")
H.emit("QUEST_LOG_UPDATE"); H.settle()
H.items[901] = 2
for _ = 1, 20 do H.emit("BAG_UPDATE_DELAYED") end
H.settle()
assert(APRData.player.journey == 3 and APR:GetCurrentStep().Qpart[703],
    "The inventory event activates the real conditional parallel group before the current objective")
local state = APRData.player["journey-ParallelStepsState"]
assert(state and state.activationSequence == 1)
for _ = 1, 30 do H.emit("BAG_UPDATE_DELAYED") end
H.settle()
assert(state.activationSequence == 1 and APRData.player.journey == 3,
    "Duplicate inventory bursts neither insert the same group twice nor advance its unfinished quest")

H.missingObjectives[702] = true
H.emit("QUEST_LOG_UPDATE"); H.settle()
assert(APRData.player.journey == 3 and APR.currentStep.fillersList["702-1"],
    "Unavailable optional objectives retain a pending cache fallback without advancing the main route")
H.missingObjectives[702] = nil
H.objective(702, "Optional 5/5", true)
H.emit("QUEST_LOG_UPDATE"); H.settle()
assert(not APR.currentStep.fillersList["702-1"] and APRData.player.journey == 3,
    "Finishing a filler removes its actual row without advancing the unrelated active quest")
H.objective(703, "Parallel 1/1", true)
for _ = 1, 20 do H.emit("QUEST_LOG_UPDATE") end
H.settle()
assert(APRData.player.journey == 4 and APR:GetCurrentStep().Qpart[701])
local reads = H.questReads
for _ = 1, 50 do H.emit("QUEST_LOG_UPDATE") end
H.settle()
assert(APRData.player.journey == 4 and H.questReads == reads + 1,
    "A quest-log burst synchronizes once and cannot consume the next unfinished step")

H.missingInfo[2], APR.ActiveQuests[701] = true, nil
H.emit("QUEST_LOG_UPDATE"); H.settle()
assert(APRData.player.journey == 4, "A temporarily missing native quest record cannot complete an objective")
H.missingInfo[2] = nil
H.emit("QUEST_LOG_UPDATE"); H.settle()
H.objective(701, "Main 3/3", true)
H.emit("QUEST_LOG_UPDATE"); H.settle()
assert(APRData.player.journey == 5 and APR:GetCurrentStep().Done[1] == 701)
H.rewarded[701], H.quests[701].onQuest = true, false
H.emit("QUEST_REMOVED", 701)
H.settle()
assert(APRData.player.journey == 6 and APR:GetCurrentStep().SetHS == 10)

local ready = 0
APR.event:ValidateStartupRoutes("journey", function(route)
    assert(route == "journey" and not APR.routeValidationPending)
    ready = ready + 1
    APR:UpdateQuestAndStep()
end)
H.frame(0)
assert(APR.routeValidationPending and APRData.player.journey == 6)
for _ = 1, 20 do H.emit("HEARTHSTONE_BOUND") end
assert(APRData.player.journey == 6 and APR.routeValidationPending.advance.index == 6)
local stale = APR.event.routeValidationJob.timer
APR.event:CancelRouteValidation(true)
assert(APR.event:ResumeRouteValidation())
stale.callback()
H.settle()
assert(ready == 1 and APRData.player.journey == 7 and APR:GetCurrentStep().Note == "Synthetic finish",
    "A single native completion survives cancelled startup work and advances once after real signature validation")
assert(not APR.stepUpdateTimer and not APR.stepUpdateRunning and not APR.event.routeValidationJob and #H.errors == 0)
''')
