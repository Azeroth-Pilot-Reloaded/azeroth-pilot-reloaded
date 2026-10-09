-- Product help and live installation facts, with links at the top and readable contributor credits.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local UI = APR.UI
APR.AboutPanel = {}
local About = APR.AboutPanel

local function TextList(panel, top)
    local scroll = UI:Scroll(panel)
    scroll:SetPoint("TOPLEFT", 14, -top); scroll:SetPoint("BOTTOMRIGHT", -28, 12)
    local content = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(content)
    local list = {scroll = scroll, content = content, rows = {}}
    function list:Layout()
        local width, y = math.max(1, self.scroll:GetWidth()), 0
        self.content:SetWidth(width)
        for _, row in ipairs(self.rows) do
            if row:IsShown() then
                row:ClearAllPoints(); row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -y)
                row:SetWidth(width)
                row.title:SetWidth(width - 8); row.text:SetWidth(width - 8)
                local titleHeight = math.max(18, row.title:GetStringHeight())
                row.text:ClearAllPoints(); row.text:SetPoint("TOPLEFT", 0, -titleHeight - 5)
                local height = titleHeight + row.text:GetStringHeight() + 25
                row:SetHeight(height); y = y + height
            end
        end
        self.content:SetHeight(math.max(1, y))
    end
    function list:SetItems(items)
        for _, row in ipairs(self.rows) do row:Hide() end
        for index, item in ipairs(items) do
            local row = self.rows[index]
            if not row then
                row = CreateFrame("Frame", nil, self.content)
                row.title = UI:Label(row, "", 13, "accent"); row.title:SetPoint("TOPLEFT")
                row.text = UI:Label(row, "", 12)
                self.rows[index] = row
            end
            row.title:SetText(item.title); row.text:SetText(item.text); row:Show()
        end
        self.scroll:SetVerticalScroll(0)
        self:Layout()
    end
    scroll:HookScript("OnSizeChanged", function() list:Layout() end)
    return list
end

function About:SetPage(id)
    self.page = id
    UI:SetButtonActive(self.guideTab, id == "guide")
    UI:SetButtonActive(self.commandsTab, id == "commands")
    if id == "commands" then
        local items = {}
        for _, command in ipairs(APR.command:GetHelpEntries()) do
            items[#items + 1] = {title = command[1], text = command[2]}
        end
        self.help:SetItems(items)
    else
        self.help:SetItems({
            {title = L["ROUTE_SELECTION"], text = L["UI_ABOUT_ROUTES_HELP"]},
            {title = L["UI_LAYOUT_TITLE"], text = L["UI_LAYOUT_HELP"]},
            {title = L["DISABLED_AUTOMATION"], text = L["DISABLED_AUTOMATION_DESC"]},
            {title = L["STATUS"], text = L["UI_ABOUT_STATUS_HELP"]},
        })
    end
end

function About:Refresh()
    if not self.frame then return end
    local version = APR.version or UNKNOWN
    if version:find("@project%-version@") then version = L["UI_DEVELOPMENT_BUILD"] end
    local routes, expansions, authors = APR.AboutData:GetRouteSummary()
    self.version:SetText(L["UI_STATUS_ADDON_VERSION"] .. ": " .. version)
    local client = APR:GetGameVersion():gsub("^%l", string.upper)
    self.installation:SetText(client .. " · " .. select(1, GetBuildInfo()) .. " · " ..
        (APR:GetSkinProviderName() or "WoW"))
    self.routeCount:SetText(string.format(L["UI_ABOUT_ROUTE_COUNT"], routes, expansions))
    local credits = APR.AboutData:GetCredits()
    if authors ~= "" then credits[#credits + 1] = {title = L["UI_ABOUT_LOADED_AUTHORS"], text = authors} end
    self.credits:SetItems(credits)
    self:SetPage(self.page or "guide")
end

function About:Create(parent)
    self.frame = UI:Page(parent)
    local root = self.frame.content
    local previous
    for _, link in ipairs({
        {label = "Discord", width = 125, action = function() UI:ShowTextReport("Discord", APR.discord) end},
        {label = "GitHub", width = 125, action = function() UI:ShowTextReport("GitHub", APR.github) end},
        {label = "Wiki", width = 100, action = function() UI:ShowTextReport("Wiki", APR.github .. "/wiki") end},
        {label = L["UI_RELEASE_NOTES"], width = 220, action = function() APR.Workspace:Show("options", "changelog") end},
    }) do
        local button = UI:Button(root, link.label, link.width, link.action)
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 8, 0) else button:SetPoint("TOPLEFT") end
        previous = button
    end
    self.facts = UI:Panel(root, "borderedPanel", "stone")
    self.facts:SetPoint("TOPLEFT", 0, -44); self.facts:SetPoint("TOPRIGHT", 0, -44); self.facts:SetHeight(86)
    self.version = UI:Label(self.facts, "", 14)
    self.version:SetPoint("TOPLEFT", 14, -12); self.version:SetPoint("TOPRIGHT", -14, -12)
    self.installation = UI:Label(self.facts, "", 12, "muted")
    self.installation:SetPoint("TOPLEFT", 14, -36); self.installation:SetPoint("TOPRIGHT", -14, -36)
    self.routeCount = UI:Label(self.facts, "", 12)
    self.routeCount:SetPoint("TOPLEFT", 14, -59); self.routeCount:SetPoint("TOPRIGHT", -14, -59)
    self.helpPanel = UI:Panel(root, "borderedPanel", "inset")
    self.helpPanel:SetPoint("TOPLEFT", 0, -142); self.helpPanel:SetPoint("BOTTOMLEFT")
    self.creditsPanel = UI:Section(root, L["UI_ABOUT_CONTRIBUTORS"], "stone")
    self.creditsPanel:SetPoint("TOPLEFT", self.helpPanel, "TOPRIGHT", 12, 0)
    self.creditsPanel:SetPoint("BOTTOMRIGHT")
    self.guideTab = UI:Button(self.helpPanel, L["HELP"], 150, function() self:SetPage("guide") end)
    self.guideTab:SetPoint("TOPLEFT", 12, -12)
    self.commandsTab = UI:Button(self.helpPanel, L["UI_ABOUT_COMMANDS"], 160, function() self:SetPage("commands") end)
    self.commandsTab:SetPoint("LEFT", self.guideTab, "RIGHT", 8, 0)
    self.help = TextList(self.helpPanel, 56)
    self.credits = TextList(self.creditsPanel, 44)
    local function layout() self.helpPanel:SetWidth(math.floor(root:GetWidth() * 0.58) - 6) end
    root:HookScript("OnSizeChanged", layout)
    self.frame:HookScript("OnShow", function() layout(); self:Refresh() end)
    layout()
end
