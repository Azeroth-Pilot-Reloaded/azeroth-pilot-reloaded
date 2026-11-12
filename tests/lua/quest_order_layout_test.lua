-- Synthetic native geometry distinguishes wrapped bounds from string metrics.
local env = dofile("tests/lua/route_ui_test_env.lua")
local createFont = env.methods.CreateFontString
function env.methods:CreateFontString(...)
    local font = createFont(self, ...)
    font.isLayoutFont = true
    return font
end
local getHeight = env.methods.GetHeight
function env.methods:GetHeight()
    if self.isLayoutFont and self.height == 0 then
        return math.max(1, math.ceil(#tostring(self.text or "") * 6 / self.width)) * 12
    end
    return getHeight(self)
end
function env.methods:GetStringHeight() return 12 end

dofile("APR-Core/ui/route/QuestOrderListSupport.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
local support = APR.questOrderListSupport
local parent = CreateFrame("Frame", nil, UIParent)
local quests = {
    { questID = 101, questName = string.rep("x", 54) },
    { questID = 102, questName = "Short" },
}
local layout = { scrollChild = parent, frameWidth = 236, frameOffset = 10, dataHeight = 0 }
local row = support:AddStepFrameWithQuest(layout, 1, "Turn in", quests, "gray", false)
assert(row:GetHeight() == 69, "Reserve both detail lines, the title gap and bottom padding")
assert(row.questFonts[1].point[5] == -17)
assert(row.questFonts[2].point[5] == -44, "The second detail starts below the wrapped first detail")
local nextRow = support:AddStepFrame(layout, 2, "Next", "gray", false)
assert(nextRow.point[5] == -69, "The next step starts below all details")
assert(nextRow:GetHeight() == 22, "Rows without details keep their original spacing")

-- Reusing a row must discard any old explicit height and adapt to its new width.
layout.container, layout.dataHeight, layout.frameWidth = row, 0, 136
row.questFonts[1]:SetHeight(12)
support:AddStepFrameWithQuest(layout, 1, "Turn in", quests, "gray", false)
assert(row:GetHeight() == 93, "Narrowing expands the wrapped detail to four lines")
assert(row.questFonts[2].point[5] == -68)
layout.frameWidth = 436
support:AddStepFrameWithQuest(layout, 1, "Turn in", quests, "gray", false)
assert(row:GetHeight() == 57, "Widening shrinks the same pooled detail to one line")
support:AddStepFrameWithQuest(layout, 1, "Turn in", {}, "gray", false)
assert(row:GetHeight() == 22 and not row.questFontPool[1]:IsShown())

-- Measurement models and visible rows must agree, including a wrapped title.
layout.container, layout.frameWidth, layout.dataHeight = nil, 236, 0
layout.collectModels = true
local model = support:AddStepFrameWithQuest(layout, 1, string.rep("t", 40), quests, "gray", false)
local tail = support:AddStepFrame(layout, 2, "Next", "gray", false)
assert(model.height == 81, "A two-line title also contributes its full rendered height")
local scroll = CreateFrame("ScrollFrame", nil, parent)
scroll:SetSize(236, 300)
local list = APR.VirtualList:New(scroll,
    function(child) return CreateFrame("Frame", nil, child) end,
    function(visibleRow, item)
        support:BindStepModel(visibleRow, item, scroll:GetScrollChild())
    end,
    function(item) return item.height end)
list:SetItems({ model, tail })
assert(list.offsets[2] == 81 and list.height == 103)
assert(model.frame:GetHeight() == 81)
assert(model.frame.questFonts[2].point[5] == -56)
assert(tail.frame.point[5] == -81, "Virtualized rows use the complete model height")
