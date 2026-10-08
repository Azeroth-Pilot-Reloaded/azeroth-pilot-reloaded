local env = dofile("tests/lua/route_browser_test_env.lua")
local browser, catalog = APR.RouteBrowser, APR.RouteCatalog
local resets, checks, notifications = 0, 0, 0
function APR:ResetRoute() resets = resets + 1 end
function APR:CheckRouteChanges() checks = checks + 1 end
function APR.routeconfig:SendCustomPathUpdate() notifications = notifications + 1; browser:Refresh(true) end
function APR:GetTotalSteps() error("Browsing must not build an effective route") end
-- Saved progress, not path membership or a full-looking counter, determines the route's color.
local function firstRecord()
    for _, record in ipairs(catalog:Build()) do if record.key == "first" then return record end end
end
assert(firstRecord().progressState == "notStarted")
APRCustomPath.test = {"First by Someone"}
APRData.test.first = 1
assert(firstRecord().progressState == "notStarted", "An initialized/queued route has not necessarily started")
APR.ActiveRoute = "first"
assert(firstRecord().progressState == "inProgress" and firstRecord().status == "1 / ?")
APR.ActiveRoute = nil
APRData.test.first, APRData.test["first-TotalSteps"] = 10, 10
assert(firstRecord().progressState == "inProgress", "The last step still needs its completion action")
APRData.test["first-SkippedStep"] = 3
assert(firstRecord().status == "7 / 10")
APRZoneCompleted.test["First by Someone"] = true
assert(firstRecord().progressState == "completed")
APRCustomPath.test, APRData.test, APRZoneCompleted.test = {}, {}, {}
-- Disabled routes stay below available ones for every column/direction, including filtered favorites.
local records = catalog:Build()
for _, record in ipairs(records) do record.favorite = true end
for _, column in ipairs({"label", "category", "author", "status"}) do
    for _, descending in ipairs({false, true}) do
        local sorted = catalog:Filter(records, {sort = column, descending = descending, favorites = true})
        assert(#sorted == 3 and sorted[1].visibility == "visible" and sorted[2].visibility == "visible")
        assert(sorted[3].key == "second", "Availability must take priority over column sorting")
    end
end
local descending = catalog:Filter(records, {sort = "label", descending = true})
assert(descending[1].key == "old" and descending[2].key == "first", "Column sorting still applies within the available group")
browser:Show()
assert(browser.filters.expansion == "Midnight" and #browser.list.items == 2)
assert(browser.list.rowHeight == 26 and browser.prefabs[1].point[5] > browser.scroll.point[5])
assert(browser.headers.label.icon:IsShown() and not browser.headers.author.icon:IsShown())
assert(browser.frame.close.icon and browser.frame.resize.icon, "Window actions cannot depend on font glyphs")
assert(browser.list.active[1].name.role == "routeNotStarted")
assert(browser.list.active[2].name.role == "muted" and browser.list.active[2].progressMarker:IsShown(),
    "Disabled names stay gray while the progress marker remains readable")
assert(#browser.legend.items == 3)
-- The primary buttons dispatch to the existing prefab flows, including their expansion chooser.
local preset
function APR.routeconfig:GetSpeedRunPrefab() preset = "speedrun"; assert(#APRCustomPath.test == 0) end
function APR.routeconfig:OpenLevelingPopup() preset = "leveling" end
function APR.routeconfig:OpenAllQuestsPopup() preset = "all" end
APRCustomPath.test = {"Existing path"}
browser.prefabs[1].scripts.OnClick()
assert(preset == "speedrun")
browser.prefabs[2].scripts.OnClick()
assert(preset == "leveling")
browser.prefabs[3].scripts.OnClick()
assert(preset == "all")
browser.list.active[1].scripts.OnClick(browser.list.active[1], "LeftButton")
assert(#APRCustomPath.test == 0 and notifications == 0, "Selection alone must never activate a route")
APRData.test.first = 4
browser.list.active[1].scripts.OnClick(browser.list.active[1], "RightButton")
assert(APRCustomPath.test[1] == "First by Someone" and checks == 1 and resets == 0 and notifications == 1)
catalog:ChangePath(browser.pathList.items[1], "remove")
env.setShift(true)
browser.list.active[1].scripts.OnClick(browser.list.active[1], "RightButton")
assert(resets == 1 and checks == 1)
env.setShift(false)
local blocked = browser.list.active[2]
blocked.scripts.OnClick(blocked, "RightButton")
assert(#APRCustomPath.test == 1 and not blocked.add:IsEnabled())
blocked.favorite.scripts.OnClick()
browser.favorites.scripts.OnClick()
assert(#browser.list.items == 1 and browser.list.items[1].key == "second")
assert(APR.settings.profile.routeFavorites.second and notifications == 3, "Favorites do not mutate the path")
browser.favorites.scripts.OnClick()
browser.category.options[1].value = false
browser.filters.category = "Daily"; browser:Refresh()
assert(#browser.list.items == 1)
browser.filters.query = "no matching route"; browser:Refresh()
assert(#browser.list.items == 0 and browser.filters.category == "Daily", "Empty search results must not discard the type filter")
browser.filters.query = ""
browser.filters.category = nil
browser.search:SetText("writer"); browser.search.scripts.OnTextChanged(browser.search) -- Search resolves authors across expansions.
assert(not browser.filters.expansion and #browser.list.items == 1 and browser.list.items[1].key == "old")
browser.search:SetText(""); browser.search.scripts.OnTextChanged(browser.search)
assert(browser.filters.expansion == "Midnight")
browser:SetScope("community")
assert(#browser.list.items == 1 and browser.list.items[1].community)
browser:SetScope("Old")
assert(#browser.list.items == 1 and browser.list.items[1].key == "old")
browser:SetScope("all")
-- Prerequisites and saved path order remain owned by the existing route engine.
APR.RouteQuestStepList.old.requiredRoute = "first"
APRCustomPath.test = {}
assert(catalog:ChangePath(browser.list.items[2], "add"))
assert(APRCustomPath.test[1] == "First by Someone" and APRCustomPath.test[2] == "Older route")
local row = browser.pathList.active[2]
assert(row.up.icon and row.down.icon and row.remove.icon)
row.up.scripts.OnClick()
assert(APRCustomPath.test[1] == "Older route")
browser.pathList.active[1].down.scripts.OnClick()
assert(APRCustomPath.test[2] == "Older route", "Recycled actions resolve the current index")
APRCustomPath.test = {"Removed route"}
browser:Refresh(true)
assert(browser.pathList.items[1].visibility == "hidden")
assert(not browser.pathList.active[1].progressMarker:IsShown(), "A missing route has unknown progress")
browser.pathList.active[1].remove.scripts.OnClick()
assert(#APRCustomPath.test == 0, "Unknown saved routes must remain removable")
-- Long catalogs recycle a bounded viewport through filtering, sorting and scrolling.
for i = 1, 1500 do APR.RouteQuestStepList["generated" .. i] = {label = string.format("Route %04d", i), expansion = "Midnight", category = "Campaign"} end
browser:SetScope("Midnight"); browser:Refresh(true)
browser.list:ScrollToIndex(700); browser.list:ScrollToIndex(1)
local frames, fonts = env.frames(), env.fonts()
for i = 1, 100 do browser.list:ScrollToIndex(i * 10) end
assert(env.frames() == frames and env.fonts() == fonts, "Scrolling must not allocate a widget for every route")
local size = 0
for _ in pairs(browser.list.active) do size = size + 1 end
assert(size <= math.ceil(browser.scroll:GetHeight() / 26) + 3)
local scroll = browser.scroll:GetVerticalScroll()
catalog:ToggleFavorite(browser.list.items[700]); browser:Refresh()
assert(browser.scroll:GetVerticalScroll() == scroll, "A favorite action keeps the reader's place")
browser:SetScope("all")
assert(browser.scroll:GetVerticalScroll() == 0, "Changing scope starts at the top")
browser.frame:SetSize(900, 600); browser:Layout()
assert(not browser.headers.author:IsShown() and not browser.headers.status:IsShown() and browser.pathScroll:GetWidth() > 180)
assert(browser.catalogPanel.point[4] + browser.catalogPanel:GetWidth() < browser.pathPanel.point[4])
assert(browser.headers.status.point[4] + browser.headers.status:GetWidth() < browser.catalogPanel:GetWidth())
browser.frame:SetSize(1500, 900); browser:Layout()
assert(browser.headers.author:IsShown() and browser.headers.status:IsShown())
assert(browser.frame.logo:GetWidth() == 61 and browser.frame.close:IsShown())
local bar = browser.scroll.ScrollBar
assert(bar:GetThumbTexture():GetWidth() == 6 and bar.ScrollUpButton:GetNormalTexture():GetWidth() == 16)
assert(bar.ScrollDownButton:GetDisabledTexture().alpha == 0.25)
APR:RegisterSkinProvider("Test skin", function() end, function() return true end)
assert(browser.frame.logo:IsShown(), "Late skin registration preserves the logo")
APRCustomPath.test = {"First by Someone", "Older route"}
browser:Refresh(true)
local beforeClear = notifications
browser.clearPath.scripts.OnClick()
assert(#APRCustomPath.test == 2 and notifications == beforeClear)
APR.UI.selectionDialog.cancelButton.scripts.OnClick()
assert(#APRCustomPath.test == 2 and notifications == beforeClear, "Cancel must keep the existing custom path")
browser.clearPath.scripts.OnClick()
APR.UI.selectionDialog.acceptButton.scripts.OnClick()
assert(#APRCustomPath.test == 0 and notifications == beforeClear + 1)
print("Route browser: prefab priority, expansion/type/community/favorites, resume/reset, prerequisites, path order, missing routes and bounded dense rows passed")
