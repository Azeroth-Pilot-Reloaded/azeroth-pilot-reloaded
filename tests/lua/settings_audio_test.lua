local fixture = dofile("tests/lua/settings_widgets_test.lua")
local env, gui = fixture.env, fixture.gui
function GetLocale() return "enUS" end
function env.methods:GetBottom() return 600 end
function env.methods:GetTop() return 630 end
function env.methods:GetEffectiveScale() return 1 end
UIParent:SetSize(1920, 1080)
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")

-- The real AceGUI adapter must leave even a large media index untouched until
-- the player opens a menu. Labels still use the saved value before that point.
local names, catalogReads, labelReads = {}, 0, 0
for i = 1, 10000 do names[i] = string.format("Synthetic sound %05d", i) end
local values = setmetatable({default = "Default"}, {__index = function(_, value)
    labelReads = labelReads + 1
    return type(value) == "string" and value:sub(1, 6) == "media:" and value:sub(7) or nil
end})
APR.partyFinder = {GetSoundCatalog = function() catalogReads = catalogReads + 1; return names end}
local selectors = {}
for i = 1, 7 do
    local selector = gui:Create("APRSettingsSoundSelect")
    selector:SetLabel("Synthetic event " .. i)
    selector:SetList(values)
    selector:SetValue("media:Synthetic sound 09999")
    assert(selector.text:GetText() == "Synthetic sound 09999" and not selector.select.menu)
    selectors[i] = selector
end
assert(catalogReads == 0 and labelReads <= 7,
    "Opening notification settings cannot enumerate or build the media catalog for each event")
local selector, changes = selectors[1], {}
selector:SetCallback("OnValueChanged", function(_, _, value) changes[#changes + 1] = value end)
selector.select:GetScript("OnClick")(selector.select)
assert(catalogReads == 1 and selector.select.menu:IsShown())
assert(selector.select.menu:GetHeight() <= 280 and selector.select.menu.list:GetCount() == 10001)
local active = selector.select.menu.list.active
local rowCount = 0
for _ in pairs(active) do rowCount = rowCount + 1 end
assert(rowCount <= 13, "A media menu only owns its visible viewport and small overscan")
local row = active[2]
row:GetScript("OnClick")(row)
assert(#changes == 1 and changes[1] == "media:Synthetic sound 00001")
assert(selector:GetValue() == changes[1] and not selector.select.menu:IsShown())
selector:SetValue("media:Unavailable saved sound")
assert(selector.text:GetText() == "Unavailable saved sound" and #changes == 1,
    "Programmatic refresh preserves a saved label without firing a setting change")
selector:SetDisabled(true)
assert(not selector.select:IsEnabled())
selector:SetDisabled(false)
table.insert(names, 1, "A later registered sound")
selector.select:GetScript("OnClick")(selector.select)
assert(catalogReads == 2 and selector.select.menu.list:GetCount() == 10002)
local pooled = selector
for _, control in ipairs(selectors) do gui:Release(control) end
assert(not pooled.select.menu:IsShown() and pooled.select.menu.list:GetCount() == 0,
    "Releasing a settings page closes its menu and drops the borrowed source")
selector = gui:Create("APRSettingsSoundSelect")
selector:SetList(values); selector:SetValue("default")
assert(catalogReads == 2 and selector.text:GetText() == "Default")
gui:Release(selector)

-- Font names stay native profile values; every shared font, including a late
-- registration, is read from the current catalog only when its menu opens.
local fonts, fontReads = {"First shared font", "Shared font with a long label", "第三方字体"}, 0
local fontValues = setmetatable({}, {__index = function(_, name) return name end})
APR.TextStyleUtils = {GetFontCatalog = function() fontReads = fontReads + 1; return fonts end}
local font = gui:Create("APRSettingsFontSelect")
font:SetLabel("Font family"); font:SetList(fontValues); font:SetValue("Shared font with a long label")
assert(fontReads == 0 and catalogReads == 2 and not font.select.menu)
assert(font.text:GetText() == "Shared font with a long label")
table.insert(fonts, "A font registered after the page opened")
font:SetCallback("OnValueChanged", function(_, _, value) changes[#changes + 1] = value end)
font.select:GetScript("OnClick")(font.select)
assert(fontReads == 1 and catalogReads == 2 and font.select.menu.list:GetCount() == 4,
    "Font menus use the full current font catalog rather than the sound catalog or a stale page snapshot")
font.select.menu.list:ScrollToIndex(4)
local fontRow = font.select.menu.list.active[4]
fontRow:GetScript("OnClick")(fontRow)
assert(changes[#changes] == fonts[4] and font:GetValue() == fonts[4],
    "Font selection saves the shared font name without adding an audio prefix")
gui:Release(font)
assert(not font.select.menu:IsShown() and font.select.menu.list:GetCount() == 0)

-- Synthetic event cards use the actual settings row pass and AceGUI Flow.
-- This catches overlap, card wrapping and stale custom layouts after reuse.
local function Group()
    local group = gui:Create("InlineGroup")
    function group:OnWidthSet(width)
        self.content.width = math.max(1, width - 20)
        self.content:SetWidth(self.content.width)
    end
    function group:LayoutFinished(_, height) self:SetHeight(height + 40) end
    group:SetLayout("Flow")
    return group
end
local grid, cards = Group(), {}
for i = 1, 3 do
    local card = Group()
    card:SetWidth(700)
    local enabled = gui:Create("CheckBox")
    enabled:SetLabel("Enable event " .. i)
    enabled:SetUserData("option", {arg = {aprInline = true, aprSoundEvent = i, aprSoundWidth = 0.625}})
    card:AddChild(enabled)
    local preview = gui:Create("Button")
    preview:SetUserData("option", {arg = {aprInline = true, aprSoundEvent = i, aprSoundWidth = 0.375}})
    preview:SetHeight(28)
    card:AddChild(preview)
    local sound = gui:Create("APRSettingsSoundSelect")
    sound:SetLabel("Audio"); sound:SetList(values); sound:SetValue("default")
    sound:SetUserData("option", {arg = {aprInline = true, aprSoundEvent = i, aprSoundWidth = 1}})
    card:AddChild(sound)
    grid:AddChild(card)
    cards[i] = card
end
grid:SetWidth(820)
APR.SettingsRows:Apply(grid)
assert(cards[1].frame.point[5] == cards[2].frame.point[5]
    and cards[2].frame.point[4] > cards[1].frame.point[4], "Wide forms display two events on one row")
assert(cards[3].frame.point[5] < cards[1].frame.point[5], "The third event begins the next row")
assert(cards[2].frame.point[4] == cards[1].frame:GetWidth() + 12, "Cards reserve a clear column gap")
local allocated = env.frames()
grid:SetWidth(500); grid:DoLayout()
assert(cards[1].frame.point[4] == 0 and cards[2].frame.point[4] == 0
    and cards[2].frame.point[5] < cards[1].frame.point[5], "Narrow forms use a single readable column")
assert(cards[1].children[3].select:GetWidth() <= cards[1].content:GetWidth())
grid:SetWidth(820); grid:DoLayout()
assert(env.frames() == allocated and catalogReads == 2, "Resizing cards creates no widgets or media work")
for _, card in ipairs(cards) do
    for _, child in ipairs(card.children) do child:SetUserData("option", {name = "Ordinary setting"}) end
end
APR.SettingsRows:Apply(grid)
assert(not grid.aprSoundGrid and not cards[1].aprSoundCard,
    "Pooled containers return to ordinary settings layout without sound-card metadata")
gui:Release(grid)
print("Notification audio: lazy real AceGUI selector, viewport rows, selection/release, late media and responsive event cards passed")
