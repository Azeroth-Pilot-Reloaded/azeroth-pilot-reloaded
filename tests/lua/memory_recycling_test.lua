-- Keep widgets rooted through their parents, as the WoW client does.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("APR-Core/utils/Utils.lua")
local step = APR.currentStep
step:PreviousNextStepButton()
local function render(id, item)
    step:BeginContentUpdate()
    step:Reset()
    step:PrepareRaidIcon({ RaidIcon = 100 + id })
    step:AddQuestSteps(id, "Objective " .. id, 1)
    step:AddStepButton(id .. "-1", item or id, "item")
    step:AddQuestStepsWithDetails("PickUp", "Pick up", { id })
    step:EndContentUpdate(true)
end
render(1); render(2); render(1)
local frames, fonts = env.frames(), env.fonts()
for index = 1, 1000 do render(index % 2 + 1) end
assert(env.frames() == frames and env.fonts() == fonts,
    "Changing objectives, items and raid icons must reuse rows, buttons, cooldowns and fonts")
local row = step.questsList["1-1"]
local button = row.IconButton
for index = 1, 1000 do step:AddStepButton("1-1", index, "item") end
assert(row.IconButton == button and env.frames() == frames, "Changing an action must reuse its secure button")

env.setCombat(true)
render(2)
local replacement = step.questsList["2-1"]
assert(row.hiddenInCombat and not row.inRowPool, "Protected rows stay out of the pool during combat")
step:FlushPendingContainers()
assert(not row.inRowPool, "Cleanup cannot mutate protected frames during combat")
env.setCombat(false)
step:FlushPendingContainers()
step:ProcessPendingStepButtons()
assert(row.inRowPool and step.questsList["2-1"] == replacement,
    "Deferred recycling preserves the replacement and returns the retired row to the pool")

local currentID = 2
function APR:UpdateStep() render(currentID) end
local function combatPass()
    env.setCombat(true)
    currentID = currentID % 2 + 1
    render(currentID)
    env.setCombat(false)
    step:FlushPendingContainers()
    step:ProcessPendingStepButtons()
end
combatPass(); combatPass()
frames, fonts = env.frames(), env.fonts()
for _ = 1, 100 do combatPass() end
assert(env.frames() == frames and env.fonts() == fonts,
    "Repeated combat transitions must preserve plain placeholders and reuse existing secure rows")
APR.UpdateStep = nil

step:AddQuestDivider("divider")
local divider = step.questsList.divider
step:ReleaseRow(step.questsList, "divider")
step:AddQuestDivider("divider-reused")
assert(step.questsList["divider-reused"] == divider and not divider.font:IsShown(),
    "Recycling a divider must preserve its hidden text region")
step:ReleaseRow(step.questsList, "divider-reused")

function APR:NormalizePreviewImages(value) return value.PreviewImages end
function APR:ResolveUIFileAsset(path) return path end
function APR:AreOrderedStringListsEqual(a, b)
    if #a ~= #b then return false end
    for index, value in ipairs(a) do if b[index] ~= value then return false end end
    return true
end
dofile("APR-Core/ui/route/CurrentStepImagePreview.lua")
APR.currentStepImagePreview:ConfigureCurrentStepPreview(CurrentStepFrame_StepHolder, 250)
local function previewPass(count)
    APR.currentStepImagePreview:ClearPreviewImages(step)
    local paths = {}
    for index = 1, count do paths[index] = "image-" .. index end
    APR.currentStepImagePreview:SetPreviewImages(step, { PreviewImages = paths })
end
previewPass(3); previewPass(1)
frames = env.frames()
for index = 1, 100 do previewPass(index % 3 + 1) end
assert(env.frames() == frames, "Image rows and thumbnail buttons are recycled after changing images")
APR.currentStepImagePreview:ClearPreviewImages(step)

-- Exercise the real configuration widgets with changing rows and callbacks.
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
APR.Color.grayAlpha = { 0.4, 0.4, 0.4, 0.4 }
APR.PlayerID, APR.EXPANSIONS = "test", { Test = "Test" }
APR.PREFAB_TYPES = { Leveling = "Leveling", AllQuests = "AllQuests", Speedrun = "Speedrun" }
function APR:GetRouteSelectionExpansions() return { "Test" } end
function APR:NormalizeSearchText(text) return (text or ""):lower() end
function APR:GetRouteVisibility() return "visible" end
function APR:GetRouteData(key) return self.RouteQuestStepList[key] end
function APR:Contains(list, value) for _, entry in ipairs(list) do if entry == value then return true end end end
APR.RouteQuestStepList = { first = { label = "First", expansion = "Test" }, second = { label = "Second", expansion = "Test" } }
APRCustomPath, APRData, APRZoneCompleted = { test = {} }, { test = {} }, { test = {} }
tinsert, tremove = table.insert, table.remove
dofile("APR-Core/config/Config_Route.lua")
local custom = { frame = env.widget() }
custom.frame.contentFrame, custom.frame.scrollFrame = env.widget(), env.widget()
local catalogue = { frame = env.widget() }
SetCustomPathListFrame(custom); SetRouteListTab(catalogue, "Test")
APRCustomPath.test = { "First", "Second" }
SetCustomPathListFrame(custom); SetRouteListTab(catalogue, "Test")
APRCustomPath.test = {}
SetCustomPathListFrame(custom); SetRouteListTab(catalogue, "Test")
frames, fonts = env.frames(), env.fonts()
for index = 1, 100 do
    APRCustomPath.test = index % 2 == 0 and { "First", "Second" } or {}
    SetCustomPathListFrame(custom); SetRouteListTab(catalogue, "Test")
end
assert(env.frames() == frames and env.fonts() == fonts, "Route lists recycle both empty and populated views")
assert(#custom.fontStringsContainer == 2 and #catalogue.fontStringsContainer == 1,
    "Active lists retain only the displayed rows")
local oldSecond = custom.fontStringsContainer[2]
APRCustomPath.test = { "Second", "First" }
SetCustomPathListFrame(custom)
assert(custom.fontStringsContainer[1] == oldSecond and oldSecond.nameText:GetText() == "Second")
APR.routeconfig.SendMessage = function() end
oldSecond.downButton.scripts.OnClick()
assert(APRCustomPath.test[1] == "First" and APRCustomPath.test[2] == "Second",
    "Reused buttons target their current route and position")

-- Preserve the catalog's right-click add/resume and Shift-right-click reset gestures.
APRCustomPath.test = {}
APRData.test.first, APRData.test["first-TotalSteps"] = 2, 10
local shift, resets, checks, added = false, 0, 0, 0
function IsShiftKeyDown() return shift end
function APR:ResetRoute(key) assert(key == "first"); resets = resets + 1 end
function APR:CheckRouteChanges(key) assert(key == "first"); checks = checks + 1 end
function APR:AddRouteToCustomPathByKey(key) assert(key == "first"); added = added + 1 end
SetRouteListTab(catalogue, "Test")
local first = catalogue.fontStringsContainer[1]
first.scripts.OnMouseDown(first, "LeftButton")
assert(added == 0)
first.scripts.OnMouseDown(first, "RightButton")
assert(added == 1 and checks == 1 and resets == 0)
shift = true
first.scripts.OnMouseDown(first, "RightButton")
assert(added == 2 and checks == 1 and resets == 1)
function APR:GetRouteVisibility(key) return key == "first" and "disabled" or "visible" end
SetRouteListTab(catalogue, "Test")
assert(catalogue.fontStringsContainer[1].scripts.OnMouseDown == nil, "Disabled routes cannot be added by right click")

-- The actual heirloom module must keep a bounded set of buttons per toy.
local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template)
    local frame = createFrame(kind, name, parent, template)
    if template == "ObjectiveTrackerContainerHeaderTemplate" then
        frame.Text = frame:CreateFontString()
        frame.MinimizeButton = createFrame("Button", nil, frame)
        frame.MinimizeButton:SetNormalTexture("normal")
        frame.MinimizeButton.SetPushedTexture = frame.MinimizeButton.SetNormalTexture
        frame.MinimizeButton:SetPushedTexture("pushed")
        frame.MinimizeButton.GetPushedTexture = frame.MinimizeButton.GetNormalTexture
    end
    return frame
end
APR.Color.defaultLightBackdrop = { 0, 0, 0, 0.4 }
dofile("APR-Core/features/player/Heirloom.lua")
function APR:GetHeirloomWarning() return false end
C_Map = { GetBestMapForUnit = function() return 84 end }
APR.Faction = "Alliance"
local toys = {}
function PlayerHasToy(id) return toys[id] end
C_ToyBox = { GetToyInfo = function(id) return id, "Toy", 123 end }
APR.heirloom:AddHeirloomIcons()
toys[150743] = true
APR.heirloom:AddHeirloomIcons()
frames = env.frames()
for index = 1, 100 do
    toys[150743] = index % 2 == 0
    APR.heirloom:AddHeirloomIcons()
end
assert(#APR.heirloom.buttons == 2 and env.frames() == frames, "Toy visibility changes reuse existing buttons")
print("Memory recycling: 1000 step/action changes, combat deferral, 100 catalogue/path redraws and 100 heirloom refreshes passed")
