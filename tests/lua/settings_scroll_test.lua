local context = dofile("tests/lua/settings_widgets_test.lua")
local gui, host, dialog = context.gui, context.host, context.dialog
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIContainer-ScrollFrame.lua")

-- Use the real AceGUI scrollbar callback; the generic frame fixture does not
-- normally emit OnValueChanged when SetValue is called.
local methods = context.env.methods
function methods:GetValue() return self.value or 0 end
-- AceGUI clears its Lua height cache on release; native GetHeight still
-- returns a number independently of that cache.
local getHeight = methods.GetHeight
function methods:GetHeight() return getHeight(self) or 0 end
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
local contentHeight = 100
gui:RegisterLayout("SyntheticScrollContent", function(content)
    content.obj:LayoutFinished(nil, contentHeight)
end)
scroll:SetLayout("SyntheticScrollContent")
local status = { offset = 900, scrollvalue = 900 }
scroll:SetStatusTable(status)
for _, height in ipairs({ 0, 100, 200, 201, 202 }) do
    contentHeight = height
    scroll:DoLayout()
    assert(not scroll.scrollbar:IsShown(), "Content fitting within two pixels needs no scrollbar")
    assert(status.offset == 0 and status.scrollvalue == 0, "Short content must clear stale saved scrolling")
    scroll:MoveScroll(-1)
    assert(status.offset == 0, "The mouse wheel cannot hide short content")
end
contentHeight = 1000
scroll:DoLayout()
assert(scroll.scrollbar:IsShown(), "Long content must remain scrollable")
scroll.scrollbar:SetValue(750)
assert(status.offset == 600, "The scrollbar reaches an independently chosen pixel position")
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
assert(status.offset == 45, "Normal wheel scrolling still advances one line")

local native = gui:Create("ScrollFrame")
assert(not native.aprSettingsScroll, "Other addons retain their unmodified AceGUI widgets")
gui:Release(native)
local previous = scroll
scroll = createScroll()
assert(scroll == previous and scroll.aprSettingsScroll, "APR retains its correction when reusing pooled widgets")
print("Settings scroll: fitting content, wheel, bounds, shrinking, resize and pool isolation passed")
