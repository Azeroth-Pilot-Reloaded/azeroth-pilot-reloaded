-- Stateful widgets catch visible teardown and protected-parent mutations, not
-- just final text. Run from the repository root with Lua 5.1 or the Python runner.
local function noop() end
local combat, frames, fonts, layouts = false, 0, 0, 0
local methods = {}
local function widget(parent)
    return setmetatable({ parent = parent, shown = true, scripts = {}, height = 12, width = 250,
        hideCount = 0, anchors = 0 }, { __index = function(_, key)
        return methods[key] or ((key:match("^Set") or key:match("^Register") or
            key:match("^Enable") or key:match("^Disable") or key == "Clear") and noop or nil)
    end })
end
local function protected(frame)
    if frame.secure then return true end
    for _, child in ipairs(frame.children or {}) do if protected(child) then return true end end
    return false
end
local function check(frame) assert(not combat or not protected(frame), "Protected mutation in combat") end
function methods:SetScript(key, fn) self.scripts[key] = fn end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:GetStringHeight() return math.max(1, math.ceil(#(self.text or "") / 30)) * 12 end
function methods:SetHeight(height) check(self); self.height = height end
function methods:GetHeight() return self.height end
function methods:SetWidth(width) self.width = width end
function methods:GetWidth() return self.width end
function methods:ClearAllPoints() check(self); self.anchors = self.anchors + 1 end
function methods:SetPoint(...) check(self); self.point = { ... } end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetParent(parent) check(self); self.parent = parent end
function methods:Hide() check(self); self.shown = false; self.hideCount = self.hideCount + 1 end
function methods:Show() check(self); self.shown = true end
function methods:IsShown() return self.shown end
function methods:IsProtected() return self.secure end
function methods:CreateFontString() fonts = fonts + 1; return widget(self) end
function methods:CreateTexture() return widget(self) end
function methods:SetNormalTexture() self.normal = widget(self) end
function methods:GetNormalTexture() return self.normal end
function methods:GetHighlightTexture() return nil end
function methods:GetPushedTexture() return nil end
function methods:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
function methods:SetValue(value) self.value = value end
function methods:SetAlpha(alpha) self.alpha = alpha end
function CreateFrame(_, name, parent, template)
    frames = frames + 1
    local frame = widget(parent)
    frame.secure = template and template:find("SecureActionButtonTemplate") ~= nil
    if parent then
        parent.children = parent.children or {}
        table.insert(parent.children, frame)
    end
    if name then _G[name] = frame end
    return frame
end
function InCombatLockdown() return combat end
function hooksecurefunc() end
function wipe(t) for key in pairs(t) do t[key] = nil end end
function LibStub() return { GetLocale = function() return {} end } end
UIParent, GameTooltip = widget(), widget()
APR = {
    Color = { defaultBackdrop = { 0, 0, 0, 1 }, blue = { 0, 0.5, 1 } }, Debug = noop,
    settings = { profile = { currentStepShow = true, currentStepbackgroundColorAlpha = { 0, 0, 0, 1 } } },
    SetupHeaderDrag = noop, SetupMinimizeButton = noop, RegisterFontString = noop,
    fillersFrame = { RemoveFillerSteps = noop },
    questOrderList = { ApplySnapAnchor = function() layouts = layouts + 1 end },
    GetQuestObjectiveProgressPercent = noop, AddQuestTooltipDetails = function(_, _, id, data)
        GameTooltip.questID, GameTooltip.details = id, data
    end,
    FindRaidIconUnitToken = noop, BuildRaidIconMacro = function() return "/target NPC" end,
    GetRouteActionUsability = function() return true end,
}
function APR:NewModule() return {} end
function APR:GetSettingsProfile() return self.settings.profile end
function APR:CreateStandardFrame(name, parent) return CreateFrame("Frame", name, parent) end
function APR:CreateFrameHeader(name, parent)
    local frame = CreateFrame("Frame", name, parent)
    frame.MinimizeButton = widget(frame)
    return frame
end
function APR:CreateStepTextContainer(parent, width, text, _, _, _, dash)
    local row = CreateFrame("Frame", nil, parent)
    row.font = row:CreateFontString()
    row.font:SetText((dash ~= false and "- " or "") .. text)
    return row
end
C_Item = { GetItemInfo = function(id) return "Item " .. id, nil, nil, nil, nil, nil, nil, nil, nil, 123 end }
C_QuestLog = { GetTitleForQuestID = function(id) return "Quest " .. id end }
UNKNOWN = "Unknown"
dofile("APR-Core/ui/route/CurrentStep.lua")
dofile("APR-Core/ui/route/CurrentStepRows.lua")
local step = APR.currentStep
step.UpdateStepButtonCooldowns, step.UpdateStepButtonUsability = noop, noop
step:PreviousNextStepButton()

local function render(text, details)
    step:BeginContentUpdate()
    step:Reset()
    step:PrepareRaidIcon({})
    step:AddExtraLineText("hint", "Follow the road")
    step:AddQuestSteps(1, text, 1)
    step:AddStepButton("1-1", 50, "item")
    step:AddQuestStepsWithDetails("PickUp", "Pick up", details or { 2, 3 })
    step:EndContentUpdate(true)
end
render("Collect 0/10")
local row, hint, detail = step.questsList["1-1"], step.questsExtraTextList.hint, step.questsList.PickUp
local button = row.IconButton
local initialFrames, initialFonts, initialLayouts = frames, fonts, layouts
local anchors = row.anchors
for _ = 1, 100 do render("Collect 0/10") end
assert(step.questsList["1-1"] == row and step.questsExtraTextList.hint == hint)
assert(step.questsList.PickUp == detail and row.IconButton == button)
assert(frames == initialFrames and fonts == initialFonts, "Unchanged refreshes allocate no widgets")
assert(row.hideCount == 0 and button.hideCount == 0, "Unchanged rows and actions never blink")
assert(row.anchors == anchors, "Unchanged row anchors are not reset")
assert(layouts - initialLayouts == 100, "A complete refresh performs exactly one layout")

render(string.rep("Long objective ", 10), { 4 })
assert(row:GetHeight() > 30 and row.font.width == 218, "Wrapped objective grows within the margins")
assert(detail.detailFonts[1].width == 209 and not detail.detailFonts[2]:IsShown())
row.scripts.OnEnter(row)
assert(GameTooltip.details.objectiveText == row.objectiveText, "Tooltip reads the latest objective")
detail.detailFonts[1].scripts.OnEnter(detail.detailFonts[1])
assert(GameTooltip.questID == 4, "Reused detail tooltips follow their new quest")

step:ProgressBar("a", 10, 2)
local progress, before = step.progressBar, frames
step:ProgressBar("b", 50, 20)
assert(step.progressBar == progress and frames == before and progress.maximum == 50)
CurrentStepScreenPanel.collapsed = true
step:ProgressBar("b", 60, 21)
assert(not progress:IsShown(), "Refresh respects collapse")
CurrentStepScreenPanel.collapsed = false
step:ProgressBar("b", 60, 21)
assert(progress:IsShown())

APR.GetQuestObjectiveProgressPercent = function() return 45 end
step:UpdateQuestStep(1, "Rescue the villagers", 1)
assert(row.font:IsShown() and row.questProgressBar.value == 45, "Percent progress keeps its objective label")
APR.GetQuestObjectiveProgressPercent = noop
step:UpdateQuestStep(1, "Done", 1)
assert(not row.questProgressBar:IsShown() and row:GetHeight() == 30)

combat = true
render("Changed in combat")
assert(row.IconButton == button and row.hideCount == 0)
step:BeginContentUpdate()
step:Reset()
step:AddQuestSteps(2, "Next objective", 1)
step:EndContentUpdate(true)
assert(not step.questsList["1-1"] and row.hiddenInCombat, "Retired secure row is deferred by identity")
step:AddQuestSteps(1, "Replacement using the same key", 1)
local replacement = step.questsList["1-1"]
combat = false
step:FlushPendingContainers()
step:ProcessPendingStepButtons()
assert(step.questsList["1-1"] == replacement and replacement:IsShown(), "Combat cleanup preserves replacements")

step:BeginContentUpdate()
step:Reset()
step:EndContentUpdate(false)
assert(step.questsList["1-1"] == replacement and not step.contentUpdateActive,
    "An interrupted or failed pass retains content and releases the batching guard")
step:BeginContentUpdate()
step:Reset()
step:AddQuestSteps(1, "Recovered", 1)
step:EndContentUpdate(true)
assert(not step.questsList["2-1"], "Successful refresh removes obsolete content")

-- Actions removed by a later combat refresh must not be resurrected by an
-- earlier queued request when PLAYER_REGEN_ENABLED drains pending work.
step:AddStepButton("1-1", 50, "item")
combat = true
step:AddStepButton("1-1", 51, "item")
step:BeginContentUpdate()
step:Reset()
step:AddQuestSteps(1, "No item needed anymore", 1)
step:EndContentUpdate(true)
assert(not step.pendingButtonRequests["1-1"])
combat = false
step:ProcessPendingStepButtons()
assert(not replacement.IconButton)
combat = true
step:UpdateQuestStep(1, string.rep("Long text ", 20), 1)
assert(step.layoutDirty, "Rows with retired secure children still defer geometry changes")
combat = false
step:FlushPendingContainers()

APR.IsNavigationQuestUiKey = function(_, key) return key == "01_NAV" end
APR.IsNavigationExtraTextUiKey = function(_, key) return key == "00_DEST" end
APR.farstrider = { showOutOfZoneStepContent = true, NavigationDividerStepKey = "01_NAV",
    ErrorDestinationLineKey = "00_DEST" }
step:AddQuestDivider("01_NAV")
step:AddExtraLineText("00_DEST", "Destination", nil, false)
step:AddExtraLineText("route-hint", "Hint", nil, false)
local navigation, destination = step.questsList["01_NAV"], step.questsExtraTextList["00_DEST"]
local redirected = step.questsList["04_EXTRA_LINE_route-hint-EXTRA"]
step:BeginContentUpdate()
step:RemoveStepContentPreservingNavigationUi()
step:AddExtraLineText("route-hint", "Updated hint", nil, false)
step:EndContentUpdate(true)
assert(step.questsList["01_NAV"] == navigation and step.questsExtraTextList["00_DEST"] == destination)
assert(step.questsList["04_EXTRA_LINE_route-hint-EXTRA"] == redirected)
assert(destination.layoutOffset < navigation.layoutOffset and navigation.layoutOffset < redirected.layoutOffset)
assert(redirected.font:GetText() == "Updated hint", "Explicit dash preference survives redirection")
APR.farstrider = nil

-- Preview rows participate in reconciliation, and missing texture dimensions
-- must not leave a perpetual layout loop running on every client frame.
function APR:NormalizePreviewImages(value) return value.PreviewImages end
function APR:ResolveUIFileAsset(path) return path end
function APR:AreOrderedStringListsEqual(a, b)
    if #a ~= #b then return false end
    for index, value in ipairs(a) do if b[index] ~= value then return false end end
    return true
end
dofile("APR-Core/ui/route/CurrentStepImagePreview.lua")
APR.currentStepImagePreview:ConfigureCurrentStepPreview(CurrentStepFrame_StepHolder, 250)
local previewStep = { PreviewImages = { "test-image" } }
APR.currentStepImagePreview:SetPreviewImages(step, previewStep)
local preview
for _, container in pairs(step.questsList) do if container.previewButtons then preview = container end end
assert(preview)
step:BeginContentUpdate()
step:Reset()
APR.currentStepImagePreview:SetPreviewImages(step, previewStep)
step:EndContentUpdate(true)
assert(step.questsList[preview.key] == preview and preview.hideCount == 0)
local previewButton, beforeProbeLayouts = preview.previewButtons[1], layouts
for _ = 1, 20 do
    if previewButton.scripts.OnUpdate then previewButton.scripts.OnUpdate(previewButton, 0.05) end
end
assert(not previewButton.scripts.OnUpdate and layouts == beforeProbeLayouts,
    "Missing image dimensions stop probing without repeated layout")
print("Current step: 100 refreshes without allocations or hide/show; single layout, wrapping, tooltips, progress, combat and recovery passed")
