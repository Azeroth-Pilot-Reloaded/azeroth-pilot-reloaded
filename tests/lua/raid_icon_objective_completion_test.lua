local env = dofile("tests/lua/route_ui_test_env.lua")
local ui = APR.currentStep
ui.UpdateStepButtonCooldowns, ui.UpdateStepButtonUsability = function() end, function() end
ui:PreviousNextStepButton()
function APR:ShouldHideFrames() return false end
function APR:GetSnapAnchorFrame() return CurrentStepScreenPanel, 90 end
APR.settings.profile.fillersFrame, APR.settings.profile.currentStepScale = {}, 1
APR.settings.profile.fillersFrameSnapToCurrentStep = false
dofile("APR-Core/ui/route/FillersFrame.lua")

for _, optional in ipairs({ false, true }) do
    local function render(completed)
        ui:BeginContentUpdate()
        ui:Reset()
        ui:PrepareRaidIcon({ RaidIcon = { { npcID = 101, questID = 40, objectiveIndex = 1 } } })
        if not completed then
            if optional then
                APR.fillersFrame:AddFillerStep(40, "First creature: 1/2", 1)
            else
                ui:AddQuestSteps(40, "First creature: 1/2", 1)
            end
        end
        ui:AddQuestSteps(50, "Another objective: 0/3", 1)
        ui:EndContentUpdate(true)
    end

    render(false)
    local list = optional and ui.fillersList or ui.questsList
    local key, row
    for candidateKey, candidate in pairs(list) do
        if candidate.questID == 40 then key, row = candidateKey, candidate end
    end
    local button = ui.raidIconButtons[1]
    assert(row and button.questHost == row)
    assert(not row.IconButton and not row.RaidIconButton and not row.hasSecureControls,
        "The raid button is a sibling anchored to the objective, not a child tracked by the row")

    -- Model the client contract absent from the basic widget mock: a secure
    -- sibling's anchor implicitly protects this row, on both client profiles.
    local originalIsProtected = row.IsProtected
    row.IsProtected = function(self)
        local _, relative = button:GetPoint()
        return relative == self, false
    end
    local locked = false
    local originalMethods = {}
    for _, method in ipairs({ "Hide", "Show", "ClearAllPoints", "SetHeight", "EnableMouse" }) do
        local original = row[method]
        originalMethods[method] = original
        row[method] = function(self, ...)
            assert(not locked or not self:IsProtected(), "Implicitly protected objective mutated in combat: " .. method)
            return original(self, ...)
        end
    end

    env.setCombat(true)
    locked = true
    render(true)
    assert(not list[key] and row.hiddenInCombat and row.alpha < 0.01,
        "Completed objective text must disappear immediately during combat")
    assert(ui.questsList["50-1"].objectiveText == "Another objective: 0/3",
        "Unfinished objectives remain visible")
    assert(not row.inRowPool, "The protected row must wait for combat to end before recycling")

    locked = false
    env.setCombat(false)
    ui:FlushPendingContainers()
    ui:ProcessPendingStepButtons()
    assert(row.inRowPool and not row:IsShown(), "Combat end finishes recycling the retired objective")
    assert(#ui.raidIconButtons == 0, "The completed objective's target is retired after combat")
    row.IsProtected = originalIsProtected
    for method, original in pairs(originalMethods) do row[method] = original end
end

print("Raid icons: implicitly protected main/optional objectives disappear in combat and recycle afterward")
