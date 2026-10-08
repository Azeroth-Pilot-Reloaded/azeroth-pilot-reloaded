-- Recycles only visible rows, using prefix heights and binary search for variable-height data.
-- Callers own row content and model creation; scrolling never scans the complete dataset.

APR.VirtualList = {}
local List = APR.VirtualList
List.__index = List

function List:New(scrollFrame, createRow, bindRow, rowHeight, child)
    local list = setmetatable({ scroll = scrollFrame, createRow = createRow, bindRow = bindRow,
        rowHeight = rowHeight or 56, items = {}, offsets = { 0 }, rows = {}, active = {}, height = 0, generation = 0 }, self)
    list.child = child or CreateFrame("Frame", nil, scrollFrame)
    list.child:SetSize(1, 1)
    scrollFrame:SetScrollChild(list.child)
    scrollFrame:HookScript("OnVerticalScroll", function() list:RefreshVisible() end)
    scrollFrame:HookScript("OnSizeChanged", function() list:RefreshVisible(true) end)
    scrollFrame:HookScript("OnShow", function() list:RefreshVisible(true) end)
    scrollFrame:HookScript("OnHide", function() if GameTooltip then GameTooltip:Hide() end end)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        list:ScrollTo(scrollFrame:GetVerticalScroll() - delta * 40)
    end)
    return list
end

function List:IndexAt(offset)
    local first, last = 1, #self.items
    while first <= last do
        local middle = math.floor((first + last) / 2)
        if self.offsets[middle + 1] <= offset then first = middle + 1 else last = middle - 1 end
    end
    return math.min(first, #self.items)
end

function List:ScrollTo(offset)
    local maximum = math.max(0, self.height - self.scroll:GetHeight())
    offset = math.max(0, math.min(maximum, offset))
    self.scroll:SetVerticalScroll(offset)
    if self.scroll.ScrollBar then self.scroll.ScrollBar:SetValue(offset) end
    self:RefreshVisible()
end

function List:ScrollToIndex(index)
    if self.offsets[index] then self:ScrollTo(self.offsets[index]) end
end

function List:SetItems(items, preserveScroll)
    self.items, self.offsets = items or {}, { 0 }
    self.generation = self.generation + 1
    local height = 0
    for index, item in ipairs(self.items) do
        height = height + math.max(1, type(self.rowHeight) == "function" and self.rowHeight(item, index) or self.rowHeight)
        self.offsets[index + 1] = height
    end
    self.height = height
    self.child:SetHeight(math.max(1, height))
    self:ScrollTo(preserveScroll and self.scroll:GetVerticalScroll() or 0)
end

function List:RefreshVisible(force)
    if self.rendering or not self.scroll:IsShown() then return end
    self.rendering = true
    local ok, message = pcall(self.RenderVisible, self, force)
    self.rendering = nil
    if not ok then error(message, 0) end
end

-- Always release the reentrancy guard, including when a caller's row binder fails.
function List:RenderVisible(force)
    local width = math.max(1, self.scroll:GetWidth())
    self.child:SetWidth(width)
    local offset = self.scroll:GetVerticalScroll()
    local first = math.max(1, self:IndexAt(offset) - 1)
    local last = math.min(#self.items, self:IndexAt(offset + self.scroll:GetHeight()) + 1)
    for index, row in pairs(self.active) do
        if index < first or index > last then
            if GameTooltip and GameTooltip:GetOwner() == row then GameTooltip:Hide() end
            row:Hide()
            if row.onRecycle then row:onRecycle() end
            row.item, row.boundGeneration = nil, nil
            self.rows[#self.rows + 1] = row
            self.active[index] = nil
        end
    end
    for index = first, last do
        local row = self.active[index]
        if not row then
            row = table.remove(self.rows) or self.createRow(self.child)
            self.active[index] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.child, "TOPLEFT", 0, -self.offsets[index])
        row:SetSize(width, self.offsets[index + 1] - self.offsets[index])
        if force or row.boundGeneration ~= self.generation or row.boundIndex ~= index or row.boundWidth ~= width then
            row.item = self.items[index]
            self.bindRow(row, row.item, index)
            -- A binder may use a shared renderer that sets its own geometry.
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.child, "TOPLEFT", 0, -self.offsets[index])
            row:SetSize(width, self.offsets[index + 1] - self.offsets[index])
            row.boundGeneration, row.boundIndex, row.boundWidth = self.generation, index, width
        end
        row:Show()
    end
end
