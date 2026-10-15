-- Startup release notes are a standalone window; Options remains the place to revisit them.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local UI = APR.UI
APR.ReleaseNotesWindow = {}
local Window = APR.ReleaseNotesWindow

function Window:IsBlockingOnboarding()
    return self.pending or (self.frame and self.frame:IsShown()) or false
end

function Window:WatchStartup()
    if not self.watcher then
        self.watcher = CreateFrame("Frame")
        self.watcher:SetScript("OnEvent", function() self:ScheduleShow() end)
    end
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PET_BATTLE_CLOSE"}) do
        APR:RegisterSupportedEvent(self.watcher, event)
    end
end

function Window:ScheduleShow()
    if not self.pending or self.queued then return end
    self.queued = true
    C_Timer.After(1, function()
        self.queued = nil
        if self.pending then self:Show() end
    end)
end

function Window:QueueShow()
    self.pending = true
    self:WatchStartup()
    self:ScheduleShow()
end

function Window:Create()
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    local minWidth, minHeight = math.min(560, screenWidth - 40), math.min(430, screenHeight - 60)
    -- The reference layout occupies about a third of the screen width and 70%
    -- of its height, centered horizontally and slightly above the screen center.
    local width = math.max(minWidth, math.min(screenWidth * 0.32, screenWidth - 40))
    local height = math.max(minHeight, math.min(screenHeight * 0.70, screenHeight - 60))
    local profile = APR:GetSettingsProfile()
    local saved = profile.uiWindows and profile.uiWindows.APRReleaseNotesWindow
    -- Capture these before UI:Window's initial Hide saves its temporary geometry.
    local savedWidth, savedHeight = tonumber(saved and saved.width), tonumber(saved and saved.height)
    local savedPoint = saved and saved.point
    -- Reuse movement, resizing and saved geometry, with artwork replacing the
    -- utility window's title bar and separate logo entirely.
    local frame = UI:Window("APRReleaseNotesWindow", "", width, height, "library")
    self.frame = frame
    frame:SetResizeBounds(minWidth, minHeight)
    frame:SetSize(math.max(minWidth, math.min(savedWidth or width, screenWidth - 40)),
        math.max(minHeight, math.min(savedHeight or height, screenHeight - 60)))
    local position = profile.uiWindows.APRReleaseNotesWindow
    position.width, position.height = frame:GetSize()
    if not savedPoint then
        local offset = math.min(screenHeight * 0.065, math.max(0, (screenHeight - frame:GetHeight()) / 2 - 32))
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, offset)
        LibStub("LibWindow-1.1").SavePosition(frame)
    end
    frame:SetFrameStrata("DIALOG")
    frame.close:Hide()
    frame.close:SetEnabled(false)
    local banner = frame.header
    self.banner = banner
    banner.Text:Hide()
    -- Slice the original artwork only across its top edge. Small masked corner
    -- tiles keep an exact 8 UI-unit radius at every window size, with square
    -- bottom corners and the original medallion/lettering completely intact.
    local artwork = {}
    banner.artwork = artwork
    for _, name in ipairs({"above", "left", "center", "right", "below"}) do
        local texture = banner:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture("Interface\\AddOns\\APR\\APR-Core\\assets\\header.blp")
        texture:SetSnapToPixelGrid(false)
        texture:SetTexelSnappingBias(0)
        artwork[name] = texture
    end
    banner.image = artwork.below
    for _, name in ipairs({"left", "right"}) do
        local mask = banner:CreateMaskTexture(nil, "BACKGROUND")
        local file = name == "right" and "rounded-fill-top-right.tga" or "rounded-fill.tga"
        mask:SetTexture("Interface\\AddOns\\APR\\APR-Core\\assets\\ui\\" .. file, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(artwork[name])
        artwork[name]:AddMaskTexture(mask)
    end
    local function sizeBanner()
        local width = math.max(2, frame:GetWidth())
        local height = width / 4
        -- In the 1024x256 artwork, the straight banner starts at row 18.
        -- Align that edge with the window; the medallion protrudes above it.
        local overhang = width * 18 / 1024
        local lift = 8
        banner:ClearAllPoints()
        banner:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, overhang + lift - 1)
        banner:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, overhang + lift - 1)
        banner:SetHeight(height)
        frame:SetClampRectInsets(0, 0, overhang + lift, 0)
        local radius = math.min(8, width / 2, height - overhang)
        local u, top, bottom = radius / width, 18 / 256, (overhang + radius) / height
        local function tile(name, x, y, w, h, left, right, first, last)
            local texture = artwork[name]
            texture:SetPoint("TOPLEFT", banner, "TOPLEFT", x, -y)
            texture:SetSize(w, h)
            texture:SetTexCoord(left, right, first, last)
        end
        tile("above", 0, 0, width, overhang, 0, 1, 0, top)
        tile("left", 0, overhang, radius, radius, 0, u, top, bottom)
        tile("center", radius, overhang, width - 2 * radius, radius, u, 1 - u, top, bottom)
        tile("right", width - radius, overhang, radius, radius, 1 - u, 1, top, bottom)
        tile("below", 0, overhang + radius, width, height - overhang - radius, 0, 1, bottom, 1)
    end
    frame:HookScript("OnSizeChanged", sizeBanner)
    sizeBanner()
    frame.content:ClearAllPoints()
    frame.content:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 16, -16)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 16)
    self.reader = setmetatable({rows = {}}, {__index = APR.ReleaseNotesPanel})
    self.reader:CreateNotes(frame.content)
    self.reader.notes.title:SetText(L["UI_RELEASE_WINDOW_TITLE"])
    self.reader.notes:SetPoint("TOPLEFT")
    self.reader.notes:SetPoint("BOTTOMRIGHT", 0, 46)
    local options = UI:Button(frame.content, string.format(L["UI_RELEASE_WINDOW_OPTIONS"], GAMEOPTIONS_MENU), 200,
        function() self:Hide(); APR.Workspace:Show("options", "changelog") end)
    self.options = options
    options:SetPoint("BOTTOMLEFT")
    local close = UI:Button(frame.content, CLOSE, 120, function() self:Hide() end)
    self.close = close
    close:SetPoint("BOTTOMRIGHT")
    frame:HookScript("OnHide", function()
        if APR.LayoutEditor and APR.LayoutEditor.QueueOnboarding then APR.LayoutEditor.QueueOnboarding() end
    end)
end

function Window:Show()
    if InCombatLockdown() or (IsLoggedIn and not IsLoggedIn()) or not UIParent:IsShown()
        or (APR.IsPetBattleActive and APR:IsPetBattleActive()) then
        self.pending = true
        self:WatchStartup()
        return false
    end
    if not self.frame then self:Create() end
    self.reader:RefreshNotes()
    self.frame:Show()
    self.frame:Raise()
    self.pending = nil
    APR.settings.profile.lastReleaseNotesVersion = APR.version
    if self.watcher then self.watcher:UnregisterAllEvents() end
    return true
end

function Window:Hide()
    self.pending = nil
    if self.watcher then self.watcher:UnregisterAllEvents() end
    if self.frame then self.frame:Hide() end
end
