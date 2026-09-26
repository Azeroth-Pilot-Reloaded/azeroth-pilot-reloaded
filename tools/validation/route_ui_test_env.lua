-- Stateful widgets catch visible teardown and protected-parent mutations, not
-- just final text. Run from the repository root with Lua 5.1 or the Python runner.
local function noop() end
local combat, frames, fonts, layouts = false, 0, 0, 0
local methods = {}
local function widget(parent)
    return setmetatable({ parent = parent, shown = true, scripts = {}, height = 12, width = 250,
        hideCount = 0, anchors = 0 }, { __index = function(_, key)
        return methods[key] or ((key:match("^Set") or key:match("^Register") or
            key:match("^Enable") or key:match("^Disable") or key == "Clear") and noop or nil)
    end })
end
local function protected(frame)
    if frame.secure then return true end
    for _, child in ipairs(frame.children or {}) do if protected(child) then return true end end
    return false
end
local function check(frame) assert(not combat or not protected(frame), "Protected mutation in combat") end
function methods:SetScript(key, fn) self.scripts[key] = fn end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:GetStringHeight() return math.max(1, math.ceil(#(self.text or "") / 30)) * 12 end
function methods:SetHeight(height) check(self); self.height = height end
function methods:GetHeight() return self.height end
function methods:SetWidth(width) self.width = width end
function methods:GetWidth() return self.width end
function methods:GetScale() return self.scale or 1 end
function methods:SetScale(value) check(self); self.scale = value end
function methods:GetParent() return self.parent end
function methods:SetScrollChild(child) self.scrollChild = child; self.swaps = (self.swaps or 0) + 1 end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetVerticalScrollRange() return math.max(0, (self.scrollChild and self.scrollChild:GetHeight() or 0) - self.height) end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:GetOwner() return self.owner end
function methods:SetOwner(owner) self.owner = owner end
function methods:ClearAllPoints() check(self); self.anchors = self.anchors + 1 end
function methods:SetPoint(...) check(self); self.point = { ... } end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetParent(parent) check(self); self.parent = parent end
function methods:Hide() check(self); self.shown = false; self.hideCount = self.hideCount + 1 end
function methods:Show() check(self); self.shown = true end
function methods:IsShown() return self.shown end
function methods:IsProtected() return self.secure end
function methods:CreateFontString() fonts = fonts + 1; return widget(self) end
function methods:CreateTexture() return widget(self) end
function methods:SetNormalTexture() self.normal = widget(self) end
function methods:GetNormalTexture() return self.normal end
function methods:GetHighlightTexture() return nil end
function methods:GetPushedTexture() return nil end
function methods:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
function methods:SetValue(value) self.value = value end
function methods:SetAlpha(alpha) self.alpha = alpha end
function CreateFrame(_, name, parent, template)
    frames = frames + 1
    local frame = widget(parent)
    frame.secure = template and template:find("SecureActionButtonTemplate") ~= nil
    if parent then
        parent.children = parent.children or {}
        table.insert(parent.children, frame)
    end
    if name then _G[name] = frame end
    return frame
end
function InCombatLockdown() return combat end
function hooksecurefunc() end
function wipe(t) for key in pairs(t) do t[key] = nil end end
function LibStub() return {
    GetLocale = function() return {} end,
    SetScale = function(frame, scale) frame:SetScale(scale) end,
    RegisterConfig = noop, SavePosition = noop, RestorePosition = noop,
} end
UIParent, GameTooltip = widget(), widget()
APR = {
    Color = { defaultBackdrop = { 0, 0, 0, 1 }, blue = { 0, 0.5, 1 } }, Debug = noop,
    settings = { profile = { currentStepShow = true, currentStepbackgroundColorAlpha = { 0, 0, 0, 1 } } },
    SetupHeaderDrag = noop, SetupFrameDrag = noop, SetupMinimizeButton = noop, RegisterFontString = noop,
    fillersFrame = { RemoveFillerSteps = noop },
    questOrderList = { ApplySnapAnchor = function() layouts = layouts + 1 end },
    GetQuestObjectiveProgressPercent = noop, AddQuestTooltipDetails = function(_, _, id, data)
        GameTooltip.questID, GameTooltip.details = id, data
    end,
    FindRaidIconUnitToken = noop, BuildRaidIconMacro = function() return "/target NPC" end,
    GetRouteActionUsability = function() return true end,
}
function APR:NewModule() return {} end
function APR:GetSettingsProfile() return self.settings.profile end
function APR:SetupMinimizeButton(header, parent, collapse, expand)
    header.MinimizeButton:SetScript("OnClick", function()
        if parent.collapsed then
            expand()
            parent.collapsed = false
        else
            collapse()
            parent.collapsed = true
        end
    end)
end
function APR:CreateStandardFrame(name, parent) return CreateFrame("Frame", name, parent) end
function APR:CreateFrameHeader(name, parent)
    local frame = CreateFrame("Frame", name, parent)
    frame.MinimizeButton = widget(frame)
    return frame
end
function APR:CreateStepTextContainer(parent, width, text, _, _, _, dash)
    local row = CreateFrame("Frame", nil, parent)
    row.font = row:CreateFontString()
    row.font:SetText((dash ~= false and "- " or "") .. text)
    return row
end
C_Item = { GetItemInfo = function(id) return "Item " .. id, nil, nil, nil, nil, nil, nil, nil, nil, 123 end }
C_QuestLog = { GetTitleForQuestID = function(id) return "Quest " .. id end }
UNKNOWN = "Unknown"
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/ui/route/CurrentStep.lua")
dofile("APR-Core/ui/route/CurrentStepRows.lua")

return {
    frames = function() return frames end,
    fonts = function() return fonts end,
    layouts = function() return layouts end,
    setCombat = function(value) combat = value end,
    methods = methods,
    widget = widget,
}
