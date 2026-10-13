-- Real shared chrome joins the whole snapped chain and restores detached corners.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/route/QuestOrderListSupport.lua")
local profile = APR.settings.profile
profile.uiTheme = "modern"
profile.uiThemeCustomization = {rounded = true, radius = 8}
local hide, show = env.methods.Hide, env.methods.Show
function env.methods:Hide()
    local wasShown = self:IsShown(); hide(self)
    if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function env.methods:Show()
    local wasShown = self:IsShown(); show(self)
    if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
end
local function panel(name, withHeader)
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetSize(300, 80)
    APR:RegisterSkinTarget(frame, "panel")
    if withHeader then
        local header = CreateFrame("Frame", nil, frame)
        header:SetSize(300, 28)
        header.Background = header:CreateTexture()
        header.Text = header:CreateFontString()
        APR:RegisterSkinTarget(header, "header")
        frame.header = header.aprModernHeader
        frame.header:SetSize(300, 28) -- The fixture does not resolve SetAllPoints geometry.
    end
    return frame
end
local root = panel("CurrentStepScreenPanel", true)
local body = CreateFrame("Frame", nil, root, "BackdropTemplate")
body:SetSize(300, 80); root.aprContentBackdrop = body
APR:RegisterSkinTarget(body, "panel", {roundedGameplay = true})
local afk = panel("AfkFrameScreen")
local fillers = panel("FillersScreenPanel", true)
local quests = panel("QuestOrderListPanel", true)
for _, radius in ipairs({0, 8, 16}) do
    for _, frame in ipairs({afk, fillers, quests}) do APR:SetFrameSnapAnchor(frame, nil) end
    profile.uiThemeCustomization.radius = radius
    APR:RefreshRegisteredSkins(true)
    APR:SnapFrameToAnchor(afk, root, 80, 0)
    assert((afk.backdrop.insets and afk.backdrop.insets.top or 0) == 0,
        "The snapped AFK top stays square at every configured radius")
    assert((body.backdrop.insets and body.backdrop.insets.bottom or 0) == 0,
        "The Current Step bottom is square while a visible panel follows it")
    afk:Hide()
    assert((body.backdrop.insets and body.backdrop.insets.bottom or 0) == radius,
        "Hiding the last attached panel restores the Current Step bottom corners")
    afk:Show()
    APR:SnapFrameToAnchor(fillers, afk, 80, 22, 22)
    APR:SnapFrameToAnchor(quests, fillers, 80, 30)
    assert(fillers.header.backdrop.edgeSize == 1 and quests.header.backdrop.edgeSize == 1,
        "Every attached module header has square upper corners")
    assert((quests.backdrop.insets and quests.backdrop.insets.top or 0) == 0
        and (quests.backdrop.insets and quests.backdrop.insets.bottom or 0) == radius,
        "The last panel retains only its outer bottom corners")
    assert(afk.backdrop.edgeSize == 1, "A middle panel has no rounded joins")
    APR:SetFrameSnapAnchor(quests, nil)
    assert((quests.header.backdrop.insets and quests.header.backdrop.insets.top or 0) == radius,
        "Detaching a panel restores the header's configured radius")
end

local row = APR.questOrderListSupport:AddStepFrameWithQuest(
    {scrollChild = quests, frameWidth = 300, dataHeight = 0}, 23, "Pick up the quest", {}, "gray", true)
APR.questOrderListSupport:SetStepFrameState(row, "gray", true)
assert(not row.aprListRow and row:GetHeight() == row.titleFont:GetStringHeight(),
    "Quest Order List keeps its compact gameplay rows without settings separators or selection chrome")
local allocated = env.frames()
for _ = 1, 20 do
    APR:SetFrameSnapAnchor(quests, fillers)
    APR:SetFrameSnapAnchor(quests, nil)
end
assert(env.frames() == allocated, "Attaching/detaching reuses header and corner artwork")
print("Snapped theme: AFK/fillers/quest chain, radii 0/8/16, hidden panels, detach, bounded chrome and compact quest rows passed")
