local env = dofile("tests/lua/route_ui_test_env.lua")
function GetLocale() return "enUS" end
UIParent:SetSize(1920, 1080)
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
local window = APR.UI:Window("APRTestWindow", "Test", 1000, 700)
assert(window:GetWidth() == 1000 and not window:IsShown())
window:Show()
window:SetSize(1100, 740)
window:Hide()
window.scripts.OnHide(window) -- This fixture invokes lifecycle scripts explicitly.
assert(APR.settings.profile.uiWindows.APRTestWindow.width == 1100)
assert(APR.settings.profile.uiWindows.APRTestWindow.height == 740)
local panel = APR.UI:Panel(window)
APR.settings.profile.uiTheme = "modern"
assert(select(2, APR:GetTheme()) == "modern", "The modern theme can be selected independently of addons")
APR.settings.profile.uiTheme = "wow"
local legacy = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
APR:SetPanelColor(legacy, {0.1, 0.2, 0.3, 0})
APR:RegisterSkinTarget(legacy, "panel")
assert(legacy:GetBackdrop() == nil and legacy.backdropColor[4] == 0)
function env.methods:EnableMouse(enabled) self.mouseEnabled = enabled end
function env.methods:SetAltArrowKeyMode(enabled) self.altArrowMode = enabled end
function env.methods:SetHitRectInsets(...) self.hitInsets = {...} end
function env.methods:HighlightText(first, last)
    self.highlighted = true
    self.selection = {first or 0, last or #(self:GetText() or "")}
end
APR.UI:ShowTextReport("Export", string.rep("Line of report text\n", 200))
local report = APR.UI.reportWindow
local editor, viewport = report.edit, report.scroll
assert(editor.mouseEnabled and editor.altArrowMode == false,
    "Export text accepts mouse selection and ordinary arrow-key navigation")
assert(editor.selection[1] == 0 and editor.selection[2] == #editor:GetText(),
    "Opening an export still selects the complete report")
viewport:SetSize(600, 200)
viewport.scripts.OnSizeChanged(viewport)
editor:HighlightText(8, 25)
local selected = editor:GetText():sub(9, 25)
editor.scripts.OnCursorChanged(editor, 0, -600, 1, 14)
assert(viewport:GetVerticalScroll() == 414, "The caret scrolls into view below the viewport")
viewport.scripts.OnVerticalScroll(viewport, viewport:GetVerticalScroll())
assert(editor.hitInsets[3] == 414 and editor.hitInsets[4] == editor:GetHeight() - 614,
    "Only the visible portion of a long export may receive mouse input")
viewport.scripts.OnSizeChanged(viewport)
assert(editor:GetText():sub(editor.selection[1] + 1, editor.selection[2]) == selected,
    "Scrolling or resizing preserves the user's partial selection")
editor.scripts.OnCursorChanged(editor, 0, -12, 1, 14)
assert(viewport:GetVerticalScroll() == 12, "The caret scrolls back up without selecting all text")
editor.scripts.OnEscapePressed(editor)
editor:SetFocus()
assert(editor.selection[1] == 8 and editor.selection[2] == 25, "Refocusing does not replace the selection")
editor:SetText("Edited excerpt")
editor.scripts.OnTextChanged(editor, true)
assert(editor:GetText() == "Edited excerpt" and viewport:GetVerticalScroll() == 0,
    "Edits are retained and shortening the report removes stale scrolling")
assert(editor:GetHeight() >= viewport:GetHeight(), "Short exports still have a full-height input area")
APR.UI:ShowTextReport("Link", "https://example.com")
assert(editor.selection[2] == #editor:GetText(), "A newly opened report selects its own content again")

env.setCombat(true)
local deferred = APR.UI:Panel(window)
assert(deferred:GetBackdrop() == nil)
env.setCombat(false)
APR:RefreshRegisteredSkins()
assert(deferred:GetBackdrop() ~= nil)
local externalCalls = 0
APR:RegisterSkinProvider("Test", function() externalCalls = externalCalls + 1 end, function() return true end)
assert(externalCalls > 0)
assert(not panel.aprRoundedFill.enabled and not panel.aprRoundedFill.pieces[1]:IsShown(),
    "An external skin must not retain native corner fills behind its own backdrop")

local scroll = CreateFrame("ScrollFrame", nil, UIParent)
scroll:SetSize(400, 400)
local allocations, bindings = 0, 0
local list = APR.VirtualList:New(scroll, function(parent)
    allocations = allocations + 1
    return CreateFrame("Frame", nil, parent)
end, function(row, item)
    assert(row:GetWidth() == scroll:GetWidth(), "Binding sees the viewport width, including on new or recycled rows")
    bindings = bindings + 1; row.value = item.key
end, function(item) return item.height end)
local items = {}
for i = 1, 10000 do items[i] = { key = i, height = i % 2 == 0 and 60 or 40 } end
list:SetItems(items)
assert(allocations <= 12)
for i = 1, 10000, 97 do
    list:ScrollToIndex(i)
    assert(list.active[i] and list.active[i].value == i)
end
assert(allocations <= 14, "10000 models cannot allocate 10000 frames")
local count = allocations
list:SetItems(items, true)
assert(allocations == count, "Rebuilding reuses the viewport pool")
scroll:SetWidth(640)
list:RefreshVisible(true)
local previousBindings = bindings
list:SetItems(items, false, 5000)
assert(list.active[5000] and scroll:GetVerticalScroll() == list.offsets[5000],
    "Publishing a route starts at the requested step")
local visibleRows = 0
for _, row in pairs(list.active) do
    visibleRows = visibleRows + 1
    assert(row.value >= 4999, "No rows from the beginning of the route are bound before following progress")
end
assert(bindings - previousBindings == visibleRows, "Publishing binds only the destination viewport once")
list:SetItems({ { key = "replacement", height = 100 } })
assert(list.active[1].value == "replacement" and scroll:GetVerticalScroll() == 0)
GameTooltip:SetOwner(list.active[1])
GameTooltip:Show()
list:SetItems({ { key = "updated", height = 100 } })
assert(not GameTooltip:IsShown(), "Rebinding a visible row cannot keep its previous item's tooltip")
list:SetItems({})
assert(next(list.active) == nil and list.child:GetHeight() == 1)
assert(list:IndexAt(0) == 0)
local parentVisible = false
function scroll:IsVisible() return parentVisible and self:IsShown() end
local beforeHidden = bindings
list:SetItems(items, false, 5000)
assert(bindings == beforeHidden and next(list.active) == nil,
    "A list beneath a hidden panel prepares its offsets without binding invisible rows")
parentVisible = true
scroll.scripts.OnShow(scroll)
assert(list.active[5000] and bindings > beforeHidden,
    "Showing the parent binds the destination viewport with the prepared data")
local shownRows = 0
for _ in pairs(list.active) do shownRows = shownRows + 1 end
assert(bindings - beforeHidden == shownRows, "Opening a hidden list binds its viewport once")
print("UI foundations: WoW surfaces/external skins, combat deferral and bounded 10000-row viewport passed")

-- Simulated expensive bindings prove the viewport itself obeys a frame budget,
-- including replacement/scrolling while only part of the old viewport is bound.
local clockMs, samples, scans = 0, {}, 0
function debugprofilestop() return clockMs end
function APR:StartPerformanceSample() return clockMs end
function APR:FinishPerformanceSample(name, started)
    samples[#samples + 1] = { name = name, elapsed = clockMs - started }
end
local originalBind = list.bindRow
list.bindRow = function(...)
    clockMs = clockMs + 1
    return originalBind(...)
end
local originalHeight = list.rowHeight
list.rowHeight = function(...)
    scans = scans + 1
    return originalHeight(...)
end
list:SetRenderBudget(2, "TestViewportBatch")
local checkpoints = 0
local prepared = list:PrepareItems(items, function() checkpoints = checkpoints + 1 end)
assert(checkpoints == #items and scans == #items, "Offset preparation can yield for every model")
local oldBindings = bindings
list:SetItems(items, false, 5000, prepared)
assert(scans == #items and bindings == oldBindings,
    "Publication neither scans prepared models again nor binds visible rows inline")
for _, row in pairs(list.active) do assert(not row:IsShown(), "Old generations cannot remain clickable") end
local function viewportTick()
    local before = bindings
    list.renderFrame.scripts.OnUpdate()
    assert(bindings - before <= 2, "A 2 ms batch binds at most two simulated 1 ms rows")
end
viewportTick()
assert(list.renderFrame.scripts.OnUpdate, "A partially bound viewport continues on the next frame")
list:ScrollToIndex(8000)
local batchCount = 0
while list.renderFrame.scripts.OnUpdate do
    viewportTick()
    batchCount = batchCount + 1
    assert(batchCount < 20)
end
assert(list.active[8000].value == 8000 and not list.active[5000], "Scrolling retargets the pending viewport")
for _, sample in ipairs(samples) do assert(sample.elapsed <= 2) end
list:SetItems(items, false, 3000, prepared)
viewportTick()
list:SetItems({ { key = "latest", height = 100 } })
while list.renderFrame.scripts.OnUpdate do viewportTick() end
assert(list.active[1].value == "latest" and not list.active[3000], "Replacement discards pending old rows")
list:RefreshVisible(true)
parentVisible = false
viewportTick()
assert(not list.renderFrame.scripts.OnUpdate, "Hidden viewports stop per-frame work")
parentVisible = true
scroll.scripts.OnShow(scroll)
while list.renderFrame.scripts.OnUpdate do viewportTick() end
assert(list.active[1]:IsShown(), "Reopening resumes the current viewport")
list.bindRow = function() error("binder failed") end
list:RefreshVisible(true)
assert(not pcall(list.renderFrame.scripts.OnUpdate))
assert(not list.rendering and not list.renderFrame.scripts.OnUpdate, "Failed bindings release and stop their worker")
list.bindRow = originalBind
list:RefreshVisible(true)
while list.renderFrame.scripts.OnUpdate do viewportTick() end
assert(list.active[1].value == "latest", "A failed binder can recover on the next refresh")
list:SetItems({})
while list.renderFrame.scripts.OnUpdate do viewportTick() end
assert(not next(list.active), "Removing the list cancels all old visible content")
print("Virtual list: prepared offsets, 2 ms viewport batches, scrolling, replacement, visibility and error recovery passed")

-- An indexed, fixed-height catalog does not need an item/offset allocation for
-- every entry. Its getter is touched only by visible-row binding.
local sourceScroll = CreateFrame("ScrollFrame", nil, UIParent)
sourceScroll:SetSize(320, 260)
local sourceReads, sourceRows = 0, 0
local source = {count = 100000, get = function(_, index)
    sourceReads = sourceReads + 1
    assert(index >= 1 and index <= 100000)
    return "Value " .. index
end}
local sourceList = APR.VirtualList:New(sourceScroll, function(owner)
    sourceRows = sourceRows + 1
    return CreateFrame("Frame", nil, owner)
end, function(row, item) row.value = item end, 26)
sourceList:SetSource(source, false, 5000)
assert(sourceList.active[5000].value == "Value 5000" and sourceScroll:GetVerticalScroll() == 129974)
assert(sourceList.height == 2600000 and sourceList:GetCount() == 100000
    and sourceList:GetOffset(5000) == 129974 and #sourceList.offsets == 1)
assert(sourceRows <= 13 and sourceReads <= 13, "Opening a large source reads and creates only its viewport")
assert(sourceList:IndexAt(-30) == 1 and sourceList:IndexAt(2600000) == 100000)
local beforeSourceRows, beforeSourceReads = sourceRows, sourceReads
sourceList:ScrollToIndex(90000)
assert(sourceList.active[90000].value == "Value 90000" and not sourceList.active[5000])
assert(sourceRows <= beforeSourceRows + 1 and sourceReads - beforeSourceReads <= 13,
    "Scrolling a large source reuses rows without traversing the catalog")
sourceList:SetItems({{key = "array"}}, false)
-- The same binder accepts either source strings or ordinary model tables.
assert(sourceList.active[1].value.key == "array" and not sourceList.source and sourceList:GetCount() == 1,
    "Returning to array mode drops the borrowed source and restores offsets")
sourceList:SetSource({count = 0, get = function() error("An empty source must never be queried") end})
assert(sourceList:IndexAt(0) == 0 and not next(sourceList.active) and sourceList.child:GetHeight() == 1)
sourceList.bindRow = function(row, item) clockMs = clockMs + 1; row.value = item end
sourceList:SetRenderBudget(2, "SourceViewportBatch")
local readsBeforeBudget = sourceReads
sourceList:SetSource(source, false, 5000)
assert(sourceReads == readsBeforeBudget, "Budgeted publication defers even its viewport reads")
sourceList.renderFrame.scripts.OnUpdate()
assert(sourceReads - readsBeforeBudget == 2 and sourceList.renderFrame.scripts.OnUpdate)
sourceList:SetSource({count = 2, get = function(_, index)
    assert(index <= 2, "A replaced source cannot receive stale indexes")
    return "Small " .. index
end})
for _, row in pairs(sourceList.active) do assert(not row:IsShown()) end
while sourceList.renderFrame.scripts.OnUpdate do sourceList.renderFrame.scripts.OnUpdate() end
assert(sourceList.active[1].value == "Small 1" and sourceList.active[2].value == "Small 2"
    and not sourceList.active[5000], "Source replacement retargets an unfinished render batch")

-- Select setup/selected captions never open or scan a catalog. A source getter
-- supplies primitive option values, so only visible rows need labels.
local providerCalls, optionReads, selectedValue = 0, 0, nil
function env.methods:IsVisible() return self:IsShown() and (not self.parent or self.parent:IsVisible()) end
local sourceCount = 10000
local selector = APR.UI:Select(UIParent, 320, function(value) selectedValue = value end)
function selector:GetBottom() return 600 end
function selector:GetTop() return 630 end
selector:SetSourceProvider(function()
    providerCalls = providerCalls + 1
    return {count = sourceCount, get = function(_, index)
        optionReads = optionReads + 1
        return "item:" .. index
    end}
end, function(value) return value and "Caption " .. value or "" end, 280)
selector:SetValue("item:5000", "Selected synthetic audio")
assert(providerCalls == 0 and optionReads == 0 and selector:GetText() == "Selected synthetic audio")
local framesBeforeSelect = env.frames()
selector.scripts.OnClick(selector)
-- The opened viewport now has its actual height immediately: at most eleven
-- intersecting rows plus overscan may be read, regardless of catalog size.
assert(providerCalls == 1 and optionReads <= 13 and selector.menu:GetHeight() <= 280)
assert(env.frames() - framesBeforeSelect < 40, "Opening ten thousand choices only creates viewport controls")
local menuList = selector.menu.list
menuList.scroll:SetSize(286, 260)
menuList:RefreshVisible(true)
local framesAfterViewport, readsAfterViewport = env.frames(), optionReads
menuList:ScrollToIndex(7500)
assert(menuList.active[7500].item == "item:7500" and optionReads - readsAfterViewport <= 13)
assert(env.frames() <= framesAfterViewport + 4, "Scrolling retains the small visible-row pool")
menuList.active[7500].scripts.OnClick(menuList.active[7500])
assert(selectedValue == "item:7500" and selector.value == selectedValue
    and selector:GetText() == "Caption item:7500" and not selector.menu:IsShown())
sourceCount = 3
selector:SetWidth(440)
selector.scripts.OnClick(selector)
assert(providerCalls == 2 and selector.menu:GetWidth() == 440 and menuList:GetCount() == 3
    and not menuList.active[7500] and menuList.active[1].item == "item:1",
    "Reopening gets the current source and width without retaining stale large-catalog rows")
selector:SetSourceProvider(nil)
assert(not selector.menu:IsShown() and not menuList.source and menuList:GetCount() == 0,
    "Widget release can drop the borrowed source and close the menu")
selector:SetOptions({{value = "ordinary", label = "Ordinary choice"}}, "ordinary")
selector.scripts.OnClick(selector)
assert(selector:GetText() == "Ordinary choice" and menuList:GetCount() == 1)
menuList.active[1].scripts.OnClick(menuList.active[1])
assert(selectedValue == "ordinary" and providerCalls == 2, "Array selectors retain their existing callbacks")
print("Virtual catalog: bounded source reads/rows, direct captions, lazy opens, scrolling, refreshed sources and array fallback passed")
