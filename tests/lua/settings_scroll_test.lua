local context = dofile("tests/lua/settings_widgets_test.lua")
local gui, host, dialog = context.gui, context.host, context.dialog
dofile("tests/lua/settings_scroll_test_support.lua")(context.env)
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIContainer-ScrollFrame.lua")

-- Use the real AceGUI scrollbar callback; the generic frame fixture does not
-- normally emit OnValueChanged when SetValue is called.
local methods = context.env.methods
function methods:GetValue() return self.value or 0 end
-- AceGUI clears its Lua height cache on release; native GetHeight still
-- returns a number independently of that cache.
local getHeight = methods.GetHeight
function methods:GetHeight() return getHeight(self) or 0 end
local setNativeScroll = methods.SetVerticalScroll
function methods:SetVerticalScroll(value)
    local previous = self:GetVerticalScroll()
    setNativeScroll(self, value)
    if previous ~= value and self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self, value) end
end
local setValue = methods.SetValue
function methods:SetValue(value)
    local previous = self:GetValue()
    setValue(self, value)
    if previous ~= value and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end

local function createScroll()
    dialog:FeedGroup("APR/Workspace/Options/synthetic", { kind = "ScrollFrame" }, host)
    local scroll = host.children[1].children[1]
    scroll.scrollframe:SetHeight(200)
    return scroll
end
local scroll = createScroll()
assert(scroll.scrollframe.template == "UIPanelScrollFrameTemplate", "Options use the same native template as RouteBrowser")
local contentHeight = 100
gui:RegisterLayout("SyntheticScrollContent", function(content)
    content.obj:LayoutFinished(nil, contentHeight)
end)
scroll:SetLayout("SyntheticScrollContent")
local status = { offset = 900, scrollvalue = 900 }
scroll:SetStatusTable(status)
for _, height in ipairs({ 0, 100, 200 }) do
    contentHeight = height
    scroll:DoLayout()
    assert(not scroll.scrollbar:IsShown(), "Fitting content needs no scrollbar")
    assert(status.offset == 0 and status.scrollvalue == 0, "Short content must clear stale saved scrolling")
    scroll:MoveScroll(-1)
    assert(status.offset == 0, "The mouse wheel cannot hide short content")
end
contentHeight = 1000
scroll:DoLayout()
assert(scroll.scrollbar:IsShown(), "Long content must remain scrollable")
scroll.scrollbar:SetValue(600)
assert(status.offset == 600, "The scrollbar reaches an independently chosen pixel position")
assert(scroll.scrollframe:GetVerticalScroll() == 600, "Scrollbar input must move the native viewport")
local _, _, _, _, anchorOffset = scroll.content:GetPoint()
assert(anchorOffset == nil or anchorOffset == 0, "The content cannot also move through AceGUI's anchor translation")
scroll.scrollframe:SetVerticalScroll(400)
assert(status.offset == 400 and scroll.scrollbar:GetValue() == 400, "Native navigation keeps the same saved offset and thumb")
scroll.scrollframe:SetVerticalScroll(5000)
assert(scroll.scrollframe:GetVerticalScroll() == 800, "Native input cannot scroll into empty space")
scroll:SetScroll(-100)
assert(status.offset == 0, "Negative positions cannot move content below the viewport")
scroll:SetScroll(2000)
assert(status.offset == 800, "Oversized positions stop at the last visible page")
contentHeight = 400
scroll:DoLayout()
assert(status.offset == 200, "Shrinking long content clamps the old position to the new bottom")
scroll.scrollframe:SetHeight(600)
scroll:FixScroll()
assert(not scroll.scrollbar:IsShown() and status.offset == 0, "A larger viewport restores all content")
contentHeight = 1000
scroll.scrollframe:SetHeight(200)
scroll:DoLayout()
scroll:MoveScroll(-1)
assert(status.offset == 40, "Normal wheel scrolling still advances one line")

local native = gui:Create("ScrollFrame")
assert(not native.aprSettingsScroll, "Other addons retain their unmodified AceGUI widgets")
gui:Release(native)
local previous = scroll
scroll = createScroll()
assert(scroll == previous and scroll.aprSettingsScroll, "APR retains its correction when reusing pooled widgets")
assert(status.offset == 40, "Returning a viewport to its pool preserves the form's saved position")
assert(scroll.scrollframe:GetVerticalScroll() == 0, "Reacquiring the widget cannot inherit a native offset")

-- Exercise real Flow/InlineGroup measurement rather than supplying a content
-- height. Every row uses invented labels and the real APR row presentation.
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIContainer-InlineGroup.lua")
scroll:ReleaseChildren()
scroll:SetWidth(600)
scroll.scrollframe:SetSize(600, 200)
scroll:SetLayout("Flow")
local group = gui:Create("InlineGroup")
group:SetFullWidth(true)
group:SetLayout("Flow")
scroll:AddChild(group)
for index = 1, 2 do
    local row = gui:Create("CheckBox")
    row:SetUserData("option", { name = "Invented preference " .. index })
    row:SetLabel("Invented preference " .. index)
    row:SetFullWidth(true)
    group:AddChild(row)
end
APR.SettingsRows:Apply(scroll)
assert(scroll.content:GetWidth() == 600, "The native child needs a real width, independently of AceGUI's Lua width cache")
assert(scroll.content:GetHeight() == 153, "Two 52-pixel rows plus Flow gaps and group margins are measured")
assert(not scroll.scrollbar:IsShown(), "A fully measured short form has no scrollbar")
scroll.scrollframe:SetWidth(800)
scroll.content.width = 800
scroll.scrollframe.scripts.OnSizeChanged(scroll.scrollframe)
assert(scroll.content:GetWidth() == 800, "A resize must reach the real frame even when the Lua cache is already up to date")
scroll.scrollframe:SetWidth(600)
scroll.scrollframe.scripts.OnSizeChanged(scroll.scrollframe)
assert(scroll.content:GetWidth() == 600 and scroll.content.width == 600, "Physical and layout widths stay synchronized")
scroll:MoveScroll(-1)
assert(scroll.scrollframe:GetVerticalScroll() == 0, "A short measured form stays visible after wheel input")

-- External skins use AceGUI's shared pool: correct APR's active instance and
-- restore the library behavior when it goes back to another addon.
function APR:GetSkinProviderName() return "EllesmereUI" end
local shared = createScroll()
assert(shared.aprNativeScroll, "Externally skinned APR settings also use native scrolling")
host:ReleaseChildren()
assert(not shared.aprNativeScroll and not shared.aprSettingsScroll, "Shared widgets regain their original scrolling on release")
local constructor = gui.WidgetRegistry.ScrollFrame
gui:RegisterWidgetType("ScrollFrame", function()
    local widget = constructor()
    widget.content:Hide()
    return widget
end, gui:GetWidgetVersion("ScrollFrame") + 1)
local hiddenContent = createScroll()
assert(hiddenContent.content:IsShown(), "Adopting an initially hidden content frame must explicitly show it")
print("Settings scroll: fitting content, wheel, bounds, shrinking, resize and pool isolation passed")
