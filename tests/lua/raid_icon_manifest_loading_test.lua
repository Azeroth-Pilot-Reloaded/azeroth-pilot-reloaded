-- The isolated UI fixture loads modules directly. Replay this startup slice
-- from the real TOC so it cannot hide an omitted production module.
local env = dofile("tests/lua/route_ui_test_env.lua")
APR.RaidIconButtons = nil
local modules = {
    ["APR-Core/ui/route/CurrentStep.lua"] = true,
    ["APR-Core/ui/route/CurrentStepRows.lua"] = true,
    ["APR-Core/ui/route/FillersFrame.lua"] = true,
    ["APR-Core/ui/route/RaidIconButtons.lua"] = true,
}
for entry in io.lines("APR.toc") do
    entry = entry:match("^%s*(.-)%s*$"):gsub("\\", "/")
    if modules[entry] then dofile(entry) end
end
function APR:ShouldHideFrames() return false end
function APR:GetSnapAnchorFrame() return CurrentStepScreenPanel, 100 end
APR.settings.profile.currentStepScale, APR.settings.profile.fillersFrame = 1, {}
local step = APR.currentStep
step.UpdateStepButtonCooldowns, step.UpdateStepButtonUsability = function() end, function() end
step:PreviousNextStepButton()
step:BeginContentUpdate()
step:Reset()
step:PrepareRaidIcon({ RaidIcon = { 101, 202 } })
step:AddQuestSteps(1, "Synthetic startup objective", 1)
step:EndContentUpdate(true)
assert(APR.RaidIconButtons and #step.raidIconButtons == 2,
    "The client TOC must initialize the target rail before the first completed render")
assert(step.raidIconButtons[1]:GetParent() == step.questsList["1-1"]:GetParent())
step:UpdateRaidIconButtonMacro()
assert(step.raidIconButtons[1]:GetAttribute("type1") == "macro",
    "Event-driven name refresh must use the initialized production module")
print("RaidIcon startup: TOC load sequence initializes the filler rail before render and event refresh")
