local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")

-- Model native range notifications after child attachment, content changes
-- and viewport resize. Keep those events independent of the APR callbacks.
local methods = env.methods
function hooksecurefunc(object, key, callback)
    local original = object[key]
    object[key] = function(...)
        original(...)
        callback(...)
    end
end
-- Native GetPoint returns all explicit anchors; model both edges so hiding a
-- scrollbar must increase the usable viewport, not just its visibility flag.
local setPoint, getPoint, getWidth = methods.SetPoint, methods.GetPoint, methods.GetWidth
function methods:SetPoint(...)
    setPoint(self, ...)
    local anchor = { getPoint(self) }
    self.testPoints = self.testPoints or {}
    local index
    for current, value in ipairs(self.testPoints) do
        if value[1] == anchor[1] then index = current end
    end
    self.testPoints[index or #self.testPoints + 1] = anchor
end
function methods:GetNumPoints() return #(self.testPoints or {}) end
function methods:GetPoint(index) return unpack((self.testPoints or {})[index or 1] or {}) end
function methods:GetWidth()
    if self.ScrollBar and self.testPoints then
        local left, right
        for _, anchor in ipairs(self.testPoints) do
            if anchor[1]:find("LEFT") then left = anchor[4] end
            if anchor[1]:find("RIGHT") then right = anchor[4] end
        end
        if left and right then return self:GetParent():GetWidth() + right - left end
    end
    return getWidth(self)
end
UIParent:SetSize(1000, 600)
local setChild, setHeight = methods.SetScrollChild, methods.SetHeight
local function rangeChanged(scroll)
    local callback = scroll and scroll.scripts.OnScrollRangeChanged
    if callback then callback(scroll, 0, scroll:GetVerticalScrollRange()) end
end
function methods:SetScrollChild(child)
    setChild(self, child)
    rangeChanged(self)
end
function methods:SetHeight(height)
    setHeight(self, height)
    if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self, self:GetWidth(), height) end
    local parent = self:GetParent()
    if parent and parent:GetScrollChild() == self then rangeChanged(parent) end
end
local show = methods.Show
function methods:Show()
    local wasShown = self:IsShown()
    show(self)
    if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
end

for _, profile in ipairs({ "Retail", "Forever" }) do
    local scroll = APR.UI:Scroll(UIParent)
    scroll:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 12, -10)
    scroll:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -30, 10)
    scroll:SetHeight(200)
    assert(not scroll.ScrollBar:IsShown(), profile .. ": no child means no scrollbar")
    assert(scroll:GetWidth() == 980, "The hidden scrollbar's 22-pixel column belongs to the content")
    local child = CreateFrame("Frame", nil, scroll)
    child:SetHeight(100)
    scroll:SetScrollChild(child)
    assert(not scroll.ScrollBar:IsShown(), profile .. ": short content has no scrollbar")
    child:SetHeight(200)
    assert(not scroll.ScrollBar:IsShown(), "Exact fit needs no scrollbar")
    child:SetHeight(201)
    assert(scroll.ScrollBar:IsShown() and scroll.ScrollBar.maximum == 1, "Real overflow enables scrolling")
    assert(scroll:GetWidth() == 958, "A visible scrollbar reserves exactly its original column")
    child:SetHeight(1000)
    scroll:SetVerticalScroll(700)
    child:SetHeight(400)
    assert(scroll:GetVerticalScroll() == 200 and scroll.ScrollBar.value == 200, "Content shrinking clamps to its new bottom")
    scroll:SetHeight(600)
    assert(scroll:GetVerticalScroll() == 0 and not scroll.ScrollBar:IsShown(), "Viewport growth clears obsolete scrolling")
    assert(scroll:GetWidth() == 980, "Hiding the scrollbar restores the full content width")
    for _ = 1, 20 do scroll.scripts.OnSizeChanged(scroll) end
    assert(scroll:GetWidth() == 980, "Repeated layout cannot accumulate extra width")
    scroll.ScrollBar:Show()
    assert(not scroll.ScrollBar:IsShown(), "A later skin cannot reveal an unusable scrollbar")
    child:SetHeight(0)
    assert(not scroll.ScrollBar:IsShown(), "Empty results hide the scrollbar")
    child:SetHeight(1000)
    assert(scroll.ScrollBar:IsShown() and scroll.ScrollBar.maximum == 400, "New results restore scrolling")
    local unrelated = CreateFrame("ScrollFrame", nil, UIParent, "UIPanelScrollFrameTemplate")
    assert(unrelated.ScrollBar:IsShown(), "Other addons' native templates remain untouched")
end
print("Shared scroll visibility: empty, fit, overflow, content/viewport resize, late skins and native isolation passed")
