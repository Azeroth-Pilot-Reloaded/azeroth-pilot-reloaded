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

-- Exercise the actual route library across empty/populated path changes.
local locale = setmetatable({}, {__index = function(_, key) return key end})
local originalLibStub = LibStub
function LibStub(name)
    if name == "AceLocale-3.0" then return {GetLocale = function() return locale end} end
    return originalLibStub(name)
end
function GetLocale() return "enUS" end
APR.PlayerID, APR.EXPANSIONS = "test", {Test = "Test"}
APR.CATEGORIES = {Leveling = "Leveling"}
function APR:NormalizeSearchText(text) return (text or ""):lower() end
function APR:GetRouteVisibility() return "visible" end
function APR:GetUnmetConditions() return {} end
APR.RouteQuestStepList = {first = {label = "First", expansion = "Test"}, second = {label = "Second", expansion = "Test"}}
APRCustomPath, APRData, APRZoneCompleted = {test = {}}, {test = {}}, {test = {}}
dofile("APR-Core/config/Config_Route.lua")
APR.routeconfig.SendMessage = function() end
APR.routeconfig.SendCustomPathUpdate = function() end
dofile("APR-Core/ui/foundations/InterfaceStrings.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/features/questing/RouteCatalog.lua")
dofile("APR-Core/ui/route/RouteBrowser.lua")
UIParent:SetSize(1920, 1080)
local browser = APR.RouteBrowser
browser.filters.facet = "path"
browser:Show()
APRCustomPath.test = {"First", "Second"}
browser:Refresh(true)
frames, fonts = env.frames(), env.fonts()
for index = 1, 100 do
    APRCustomPath.test = index % 2 == 0 and {"First", "Second"} or {}
    browser:Refresh(true)
end
assert(env.frames() == frames and env.fonts() == fonts, "Path changes reuse the visible rows")
APRCustomPath.test = {"Second", "First"}
browser:Refresh(true)
local row = browser.list.active[1]
row.scripts.OnClick(row)
assert(browser.selected.label == "Second")
browser.down.scripts.OnClick()
assert(APRCustomPath.test[1] == "First" and APRCustomPath.test[2] == "Second",
    "Reused controls act on the current route and path position")

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
