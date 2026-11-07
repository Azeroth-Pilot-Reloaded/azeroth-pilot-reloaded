local fixture = dofile("tests/lua/gamepad_test.lua")
local env, ui, pad = fixture.env, APR.currentStep, fixture.pad
dofile("APR-Core/utils/SecretUtils.lua")
dofile("APR-Core/utils/TargetUtils.lua")
APRData = { NPCList = { [101] = "Premier", [202] = "Deuxième", [303] = "Troisième", [404] = "Quatrième" } }
function APR:GetGameVersion() return "forever" end
function APR:ShouldHideFrames() return false end
function APR:GetSnapAnchorFrame() return CurrentStepScreenPanel, 90 end
function UnitExists() return false end
function GetRaidTargetIndex() return nil end
function SetRaidTarget() error("Native markers must not be called from addon Lua") end
local profile = APR.settings.profile
profile.currentStepShow, profile.fillersFrame, profile.currentStepScale = true, {}, 1
profile.fillersFrameSnapToCurrentStep = false
profile.currentStepbackgroundColorAlpha = {0,0,0,1}
dofile("APR-Core/ui/route/FillersFrame.lua")
ui:PreviousNextStepButton()
ui.UpdateStepButtonCooldowns, ui.UpdateStepButtonUsability = function() end, function() end
local function render(ids, failed)
    ui:BeginContentUpdate()
    ui:Reset()
    ui:PrepareRaidIcon({ RaidIcon = ids })
    ui:AddQuestSteps(10, "Main objective", 1)
    ui:AddStepButton("10-1", 500, "item")
    ui:EndContentUpdate(not failed)
end
render({ 101, 202, 101, 303 })
local buttons = ui.raidIconButtons
assert(buttons and #buttons == 3, "Each unique NPC ID needs its own filler-attached target button")
assert(not ui.questsList["10-1"].RaidIconButton, "The current-step row must not own the skull rail")
assert(not APR.fillersFrame.Frame:IsShown(), "Main quest targets do not open the optional-objectives window")
for i, button in ipairs(buttons) do
    assert(button:GetParent() == ui.questsList["10-1"]:GetParent(), "Target buttons belong to the filler host")
    assert(button.npcID == ({101,202,303})[i])
    assert(button:GetNormalTexture().texture == "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. ({8,7,6})[i],
        "Visible skull, cross and square agree with the native marker slots")
    local point, relative, relativePoint, x, y = button:GetPoint()
    if i == 1 then
        assert(relative == ui.questsList["10-1"].IconButton and point == "RIGHT" and relativePoint == "LEFT")
    else
        assert(relative == buttons[i-1] and point == "RIGHT" and relativePoint == "LEFT" and x < 0 and y == 0,
            "Raid icons form a horizontal row")
    end
    local macro = button:GetAttribute("macrotext")
    assert(macro:find("/targetexact " .. APRData.NPCList[button.npcID], 1, true))
    assert(macro:find("!" .. (9-i), 1, true), "Each ID retains its authored marker slot")
    assert(#macro <= 255 and not macro:find("/run", 1, true))
end
local action = ui.questsList["10-1"].IconButton
assert(select(3,action:GetPoint()) == "LEFT", "Item/spell controls retain horizontal placement")
APR.fillersFrame:AddFillerStep(90, "Optional action", 1)
ui:AddStepButton("90-1", 501, "item")
local optionalAction = ui.fillersList["90-1"].IconButton
local targetX, actionX = select(4, buttons[1]:GetPoint()), select(4, optionalAction:GetPoint())
assert(select(2, buttons[1]:GetPoint()) == action and select(5, buttons[1]:GetPoint()) == 0,
    "Targets remain horizontally attached to their main action independently of optional controls")
local allocated, first, second = env.frames(), buttons[1], buttons[2]
render({101,202,303})
assert(env.frames() == allocated and ui.raidIconButtons[1] == first, "Equivalent refreshes reuse secure controls")
local cycle = pad.targetCycleProxy
assert(cycle and APR_TargetCycleButton == cycle, "The second binding owns an independent secure proxy")
-- Simulate only native commands, without any NPC-ID authorization in the simulator.
local world, selected = {}, nil
for id, name in pairs(APRData.NPCList) do world[name] = { id = id } end
local function executeNative(macro)
    for line in (macro or ""):gmatch("[^\n]+") do
        local name = line:match("^/targetexact (.+)$")
        local marker = tonumber(line:match("^/targetmarker %[@target,exists,nodead%] !(%d)$"))
        if line == "/cleartarget" then selected = nil
        elseif name then selected = world[name] or selected
        elseif marker and selected and not selected.marker then selected.marker = marker
        elseif line == "/stopmacro [exists,nodead]" and selected then break end
    end
end
local function cycleClick()
    cycle:secureClick("LeftButton", true)
    local macro = cycle:GetAttribute("macrotext")
    executeNative(macro)
    return macro
end
assert(cycle:GetAttribute("useOnKeyDown") == true and #cycle.clicks == 1 and cycle.clicks[1] == "AnyDown",
    "One hardware key-down executes once regardless of the player's action-bar CVar")
for _, name in ipairs({"Premier", "Deuxième", "Troisième", "Premier"}) do
    assert(cycleClick():find("/targetexact " .. name,1,true), "Every cycle press targets immediately in 1,2,3,1 order")
    assert(selected == world[name] and selected.marker, "The selected native macro actually targets and marks on this press")
end
fixture.selectAction(pad.targetProxy)
local aggregate = pad.targetProxy:GetAttribute("macrotext")
assert(aggregate:find("Premier",1,true) and aggregate:find("Deuxième",1,true), "The original target+skull binding keeps its multi-NPC search")
local slot = cycle:GetAttribute("cycleIndex")
fixture.selectAction(pad.targetProxy)
assert(cycle:GetAttribute("cycleIndex") == slot, "The original binding does not advance the cycle")
local last = cycle:GetAttribute("macrotext")
cycle:secureClick("LeftButton",false)
assert(cycle:GetAttribute("macrotext") == last, "Key release cannot advance the rotation a second time")
env.setCombat(true)
assert(cycleClick():find("Deuxième",1,true), "The preloaded secure cycle also advances in combat")
assert(selected.id == 202, "Combat rotation targets on the same press")
render({404})
assert(ui.raidIconButtons[1] == first and first.npcID == 101, "Protected target geometry/data stay frozen in combat")
assert(cycleClick():find("Troisième",1,true), "A combat-deferred refresh cannot replace the active secure set")
env.setCombat(false)
ui:ProcessPendingStepButtons()
assert(#ui.raidIconButtons == 1 and first.npcID == 404 and not second:IsShown(), "Only the latest desired set is reconciled after combat")
assert(cycleClick():find("Quatrième",1,true), "A changed set restarts the cycle and targets immediately")
render({101,202},true)
assert(first.npcID == 404, "An interrupted render does not publish a partial target set")
render({101,202})
cycleClick()
assert(selected.id == 101, "A changed multi-NPC list restarts at its first ID")
render({101,202})
cycleClick()
assert(selected.id == 202, "An unchanged refresh must not reset the rotation")
-- Numeric authored order survives double digits; later IDs remain targetable without a marker slot.
local many = {}
for index=1,12 do
    local id = 600+index
    many[index], APRData.NPCList[id] = id, "Creature " .. index
    world[APRData.NPCList[id]] = {id=id}
end
render(many)
for index=1,12 do
    cycleClick()
    assert(selected and selected.id == 600+index, "Cycle order must not become lexicographic at index10")
    if index>8 then assert(not selected.marker, "NPCs beyond eight marker slots remain safely targetable") end
end
cycleClick()
assert(selected.id == 601, "A longer cycle wraps to its first ID")
-- Missing localized names produce visible placeholders but never a stale executable macro.
render({9999,202})
assert(#ui.raidIconButtons == 2 and ui.raidIconButtons[1]:GetAttribute("type1") == nil)
cycleClick()
assert(selected.id == 202, "Rotation skips an unresolved name instead of reusing an old target payload")
APRData.NPCList[9999], world["Discovered"] = "Discovered", {id=9999}
ui:UpdateRaidIconButtonMacro()
cycleClick()
assert(selected.id == 9999, "Newly learned localized names refresh individual and aggregate macros")
profile.currentStepQuestButtonPositionRight = true
render({101,202})
local point, relative, relativePoint = first:GetPoint()
assert(point == "LEFT" and relativePoint == "RIGHT" and relative == ui.questsList["10-1"].IconButton,
    "The configured right-side layout stays horizontal beside the quest action")
render({})
assert(#ui.raidIconButtons == 0 and fixture.selectAction(pad.targetProxy) == nil, "Empty steps clear standalone targets")
assert(cycleClick() == nil, "Empty rotation clears its previous macro")
assert(not APR.fillersFrame.Frame:IsShown(), "A target-only host hides when its last target is removed")
print("Filler target rail: per-ID vertical stack, native markers, independent binding cycle, combat, reconciliation and pooling passed")

local function renderBound(firstPresent, secondPresent)
    ui:BeginContentUpdate()
    ui:Reset()
    ui:PrepareRaidIcon({RaidIcon = {
        {npcID=101, questID=50, objectiveIndex=1},
        {npcID=202, questID=50, objectiveIndex=2},
    }})
    ui:AddQuestSteps(60, "Unrelated quest", 1)
    if firstPresent then APR.fillersFrame:AddFillerStep(50, "First objective", 1) end
    if secondPresent then APR.fillersFrame:AddFillerStep(50, "Second objective", 2) end
    ui:EndContentUpdate(true)
end
renderBound(true,true)
cycleClick()
assert(selected.id == 101)
renderBound(false,true)
assert(#ui.raidIconButtons == 1 and ui.raidIconButtons[1]:GetAttribute("apr-target-index") == 2)
cycleClick()
assert(selected.id == 202, "The controller cycle must exclude the completed objective")
fixture.selectAction(pad.targetProxy)
local remainingMacro = pad.targetProxy:GetAttribute("macrotext")
assert(remainingMacro:find("!7",1,true) and not remainingMacro:find("Premier",1,true),
    "General targeting searches only the surviving NPC and retains its cross")
renderBound(false,false)
assert(cycleClick() == nil and fixture.selectAction(pad.targetProxy) == nil,
    "Both controller bindings must lose their stale macros when all bound objectives disappear")
