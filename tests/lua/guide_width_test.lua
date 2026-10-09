local env = dofile("tests/lua/route_ui_test_env.lua")
local step, profile = APR.currentStep, APR.settings.profile
profile.enableAddon, profile.currentStepShow = true, true
function APR:ShouldHideFrames() return false end
function APR:IsPetBattleActive() return false end
function APR:IsInstanceWithUI() return true end
dofile("APR-Core/ui/route/FillersFrame.lua")
step:PreviousNextStepButton()
step:AddQuestSteps(1, "Objective", 1)
step:AddQuestStepsWithDetails("details", "Quests", {2, 3})
step:AddExtraLineText("note", "Description")
step:ProgressBar("route", 10, 1)
APR.fillersFrame:AddFillerStep(4, "Bonus", 1)
local objective, detail = step.questsList["1-1"], step.questsList.details
local note, filler = step.questsExtraTextList.note, step.fillersList["4-1"]
step:SetContentWidth(340)
APR.fillersFrame:SetContentWidth(340)
assert(CurrentStepScreenPanel:GetWidth() == 340 and FillersScreenPanel:GetWidth() == 340)
assert(objective:GetWidth() == 340 and objective.font:GetWidth() == 308)
assert(note.font:GetWidth() == 308 and detail.detailFonts[1]:GetWidth() == 299)
assert(filler:GetWidth() == 340 and filler.font:GetWidth() == 308)
assert(step.progressBar:GetWidth() == 248)

-- Width changes must apply to rows returned from the pools as well as visible rows.
step:ReleaseRow(step.questsList, "details")
step:ReleaseRow(step.fillersList, "4-1")
step:SetContentWidth(289)
APR.fillersFrame:SetContentWidth(289)
step:AddQuestStepsWithDetails("reused", "New quests", {5, 6})
APR.fillersFrame:AddFillerStep(7, "Other bonus", 1)
assert(step.questsList.reused == detail and detail:GetWidth() == 289)
assert(detail.detailFonts[1]:GetWidth() == 248 and detail.detailFonts[2]:GetWidth() == 248)
assert(step.fillersList["7-1"] == filler and filler:GetWidth() == 289 and filler.font:GetWidth() == 257)
step:AddQuestSteps(8, "New objective", 1)
assert(step.questsList["8-1"].font:GetWidth() == 257, "New rows use the current width, not the initial 250")
env.setCombat(true)
step:SetContentWidth(250)
APR.fillersFrame:SetContentWidth(250)
assert(CurrentStepScreenPanel:GetWidth() == 289 and FillersScreenPanel:GetWidth() == 289)
env.setCombat(false)
step:SetContentWidth(250)
APR.fillersFrame:SetContentWidth(250)
assert(objective.font:GetWidth() == 218 and detail.detailFonts[1]:GetWidth() == 209)
assert(step.progressBar:GetWidth() == 158 and filler.font:GetWidth() == 218)
print("Guide width: existing/new/pooled rows, details, progress, fillers, combat and native restoration passed")
