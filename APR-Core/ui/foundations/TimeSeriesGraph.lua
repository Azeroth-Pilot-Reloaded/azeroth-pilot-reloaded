-- Reusable fixed-size line/area graph. Missing values break the line; drawing never allocates new regions.
-- Hover follows UI scale and delegates metric-specific tooltip content to the caller.

APR.TimeSeriesGraph = {}
local Graph = APR.TimeSeriesGraph
Graph.__index = Graph
local POINTS, INSET, TOP_INSET = 120, 6, 22

function Graph:New(parent, color, tooltip)
    local graph = setmetatable({frame = APR.UI:Panel(parent), lines = {}, fills = {}, grids = {}, tooltip = tooltip}, self)
    local frame = graph.frame
    frame:EnableMouse(true)
    for index = 1, 12 do
        local grid = frame:CreateTexture(nil, "BACKGROUND")
        grid:SetColorTexture(color[1], color[2], color[3], 0.18)
        graph.grids[index] = grid
    end
    for index = 1, POINTS do
        local fill = frame:CreateTexture(nil, "ARTWORK")
        fill:SetColorTexture(color[1], color[2], color[3], 0.16)
        graph.fills[index] = fill
        local line = frame:CreateLine(nil, "OVERLAY")
        line:SetColorTexture(color[1], color[2], color[3], 1)
        line:SetThickness(2)
        graph.lines[index] = line
    end
    graph.marker = frame:CreateTexture(nil, "OVERLAY")
    graph.marker:SetColorTexture(1, 1, 1, 0.8)
    graph.marker:SetWidth(1)
    graph.marker:Hide()
    graph.maximumLabel = APR.UI:Label(frame, "", 11, "muted")
    graph.maximumLabel:SetPoint("TOPRIGHT", -8, -5)
    graph.zeroLabel = APR.UI:Label(frame, "0", 11, "muted")
    graph.zeroLabel:SetPoint("BOTTOMRIGHT", -8, 5)
    frame:SetScript("OnEnter", function()
        graph.hovered, graph.elapsed = true, 0
        graph:UpdateTooltip(true)
        frame:SetScript("OnUpdate", function(_, elapsed)
            graph.elapsed = graph.elapsed + elapsed
            if graph.elapsed >= 0.05 then graph.elapsed = 0; graph:UpdateTooltip() end
        end)
    end)
    local function leave()
        if graph.hovered then GameTooltip:Hide() end
        graph.hovered, graph.hoverIndex = nil, nil
        graph.marker:Hide()
        frame:SetScript("OnUpdate", nil)
    end
    frame:SetScript("OnLeave", leave)
    frame:HookScript("OnHide", leave)
    frame:HookScript("OnSizeChanged", function() graph:Draw() end)
    return graph
end

function Graph:SetData(points, key, minimumScale, format)
    self.points, self.key, self.maximum = points, key, minimumScale
    for _, point in ipairs(points) do self.maximum = math.max(self.maximum, point[key] or 0) end
    self.maximumLabel:SetText(format(self.maximum))
    self:Draw()
    self:UpdateTooltip(true)
end

function Graph:Draw()
    if not self.points then return end
    local frame = self.frame
    local width, height = math.max(1, frame:GetWidth() - INSET * 2), math.max(1, frame:GetHeight() - INSET - TOP_INSET)
    for index, grid in ipairs(self.grids) do
        grid:ClearAllPoints()
        if index <= 3 then
            grid:SetPoint("BOTTOMLEFT", INSET, INSET + height * index / 4)
            grid:SetSize(width, 1)
        else
            grid:SetPoint("BOTTOMLEFT", INSET + width * (index - 3) / 10, INSET)
            grid:SetSize(1, height)
        end
    end
    for index = 1, POINTS do
        local point, previous = self.points[index], self.points[index - 1]
        local value, previousValue = point and point[self.key], previous and previous[self.key]
        local fill, line = self.fills[index], self.lines[index]
        fill:Hide(); line:Hide()
        if value then
            local x = INSET + (index - 0.5) * width / POINTS
            local y = INSET + value / self.maximum * height
            fill:ClearAllPoints()
            fill:SetPoint("BOTTOMLEFT", INSET + (index - 1) * width / POINTS, INSET)
            fill:SetSize(width / POINTS, math.max(1, y - INSET))
            fill:Show()
            -- Isolated readings are short horizontal marks; never bridge missing samples.
            local x0 = previousValue and x - width / POINTS or x - width / POINTS / 2
            local y0 = previousValue and INSET + previousValue / self.maximum * height or y
            line:SetStartPoint("BOTTOMLEFT", frame, x0, y0)
            line:SetEndPoint("BOTTOMLEFT", frame, x, y)
            line:Show()
        end
    end
end

function Graph:UpdateTooltip(force)
    if not self.hovered or not self.points then return end
    local left = self.frame:GetLeft()
    if not left then return end
    local width = math.max(1, self.frame:GetWidth() - INSET * 2)
    local x = GetCursorPosition() / self.frame:GetEffectiveScale() - left - INSET
    local index = math.max(1, math.min(POINTS, math.floor(x / width * POINTS) + 1))
    if not force and index == self.hoverIndex then return end
    self.hoverIndex = index
    self.marker:ClearAllPoints()
    self.marker:SetPoint("BOTTOMLEFT", INSET + (index - 0.5) * width / POINTS, INSET)
    self.marker:SetHeight(math.max(1, self.frame:GetHeight() - INSET * 2))
    self.marker:Show()
    self.tooltip(self.frame, self.points[index], self.key)
end
