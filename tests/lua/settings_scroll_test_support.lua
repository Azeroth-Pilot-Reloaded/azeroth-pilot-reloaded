-- Keep the form fixture's small UI controls, but use the real shared scroll
-- factory for the options viewport, including its native slider contract.
return function(env)
    local ui = APR.UI
    dofile("APR-Core/ui/foundations/Widgets.lua")
    ui.Scroll = APR.UI.Scroll
    APR.UI = ui
    local methods = env.methods
    local getWidth, getHeight = methods.GetWidth, methods.GetHeight
    -- Native dimensions are independent of AceGUI's .width/.height caches.
    local setWidth, setSize, clearPoints = methods.SetWidth, methods.SetSize, methods.ClearAllPoints
    function methods:GetWidth() return self.nativeWidth or getWidth(self) end
    function methods:GetHeight() return self.nativeHeight or getHeight(self) end
    function methods:SetWidth(width)
        self.nativeWidth = width
        setWidth(self, width)
    end
    function methods:SetSize(width, height)
        self.nativeWidth, self.nativeHeight = width, height
        setSize(self, width, height)
    end
    function methods:ClearAllPoints()
        clearPoints(self)
        self.point = nil
    end
    local create = CreateFrame
    function CreateFrame(kind, name, parent, template)
        local frame = create(kind, name, parent, template)
        frame.nativeWidth, frame.nativeHeight = frame:GetWidth(), frame:GetHeight()
        frame.template = template
        if template == "UIPanelScrollFrameTemplate" then
            frame.ScrollBar:SetScript("OnValueChanged", function(_, value) frame:SetVerticalScroll(value) end)
        end
        return frame
    end
    local setHeight = methods.SetHeight
    function methods:SetHeight(height)
        local changed = self:GetHeight() ~= height
        self.nativeHeight = height
        setHeight(self, height)
        if changed and self.template == "UIPanelScrollFrameTemplate" and self.scripts.OnSizeChanged then
            self.scripts.OnSizeChanged(self, self:GetWidth(), height)
        end
        local parent = self:GetParent()
        if changed and parent and parent.template == "UIPanelScrollFrameTemplate"
            and parent:GetScrollChild() == self and parent.scripts.OnScrollRangeChanged then
            parent.scripts.OnScrollRangeChanged(parent, 0, parent:GetVerticalScrollRange())
        end
    end
end
