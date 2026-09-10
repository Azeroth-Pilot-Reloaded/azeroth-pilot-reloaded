-- APR-owned controls register at creation, including anonymous and pooled widgets.
-- Providers change appearance only; callbacks, item attributes and layout stay owned by APR.
local targets = setmetatable({}, { __mode = "k" })
local provider
local pending = false

local function ApplyTarget(frame, target)
    if not provider or not provider.enabled() or target.applied then return end
    if InCombatLockdown() then
        pending = true
        return
    end
    provider.apply(frame, target.kind, target.options)
    target.applied = true
end

function APR:RegisterSkinTarget(frame, kind, options)
    if not frame then return end
    local target = targets[frame]
    if not target then
        target = { kind = kind, options = options or {} }
        targets[frame] = target
    end
    ApplyTarget(frame, target)
end

function APR:RefreshRegisteredSkins()
    if InCombatLockdown() then pending = true; return end
    pending = false
    for frame, target in pairs(targets) do ApplyTarget(frame, target) end
end

function APR:RegisterSkinProvider(name, apply, enabled)
    -- A reload is required to change providers; never stack two skins on a control.
    if provider and provider.name ~= name then return false end
    provider = { name = name, apply = apply, enabled = enabled }
    self:RefreshRegisteredSkins()
    return true
end

-- Only the small set of APR windows is enumerated, never UIParent or quest rows.
function APR:RegisterStaticSkinTargets()
    for _, name in ipairs({ "CurrentStepScreenPanel", "FillersScreenPanel", "QuestOrderListPanel",
        "CoordinateScreenPanel", "RouteSelectionPanel", "ChangeLogFrame", "PartyScreenPanel",
        "HeirloomPanel", "BuffFrameScreen", "AfkFrameScreen" }) do
        self:RegisterSkinTarget(_G[name], "panel", { preserveBackground = true })
    end
    for _, name in ipairs({ "CurrentStepFrameHeader", "FillersFrameHeader",
        "QuestOrderListFrame_StepHolderHeader", "RouteSelectionFrameHeader", "PartyFrameHeader",
        "HeirloomFrameHeader", "BuffFrameHeader" }) do
        local header = _G[name]
        if header then
            self:RegisterSkinTarget(header, "header")
            -- These retain APR's collapse/expand atlas state and click handlers.
            self:RegisterSkinTarget(header.MinimizeButton, "headerButton")
        end
    end
    self:RegisterSkinTarget(_G.CurrentStepFrameSettingsButton, "settings")
    self:RegisterSkinTarget(_G.OpenSettingsButton, "button")
    for _, name in ipairs({ "QuestOrderListFrame_ScrollFrame", "ChangeLogScrollFrame" }) do
        local scroll = _G[name]
        self:RegisterSkinTarget(scroll and (scroll.ScrollBar or _G[name .. "ScrollBar"]), "scrollbar")
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
    if pending then APR:RefreshRegisteredSkins() end
end)
