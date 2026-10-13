-- Registers APR-owned controls at creation so one selected provider can skin late and pooled widgets.
-- Skin application waits for combat to end; providers must preserve secure actions and APR callbacks.

-- APR-owned controls register at creation, including anonymous and pooled widgets.
-- Providers change appearance only; callbacks, item attributes and layout stay owned by APR.
local targets = setmetatable({}, { __mode = "k" })
local provider
local providers = {}
local pending = false

-- No default for uiTheme: old profiles retain their existing integration preference.
function APR:GetSelectedSkinName()
    local profile = self.GetSettingsProfile and self:GetSettingsProfile() or (self.settings and self.settings.profile)
    if profile and profile.uiTheme == "ElvUI" and _G.ElvUI then return "ElvUI" end
    if profile and profile.uiTheme == "EllesmereUI" and _G.EllesmereUI
        and type(_G.EllesmereUI.RegisterSkin) == "function" then return "EllesmereUI" end
    if profile and self.Themes and self.Themes[profile.uiTheme] then return profile.uiTheme end
    if profile and (profile.uiTheme == "wow" or profile.uiTheme == "modern") then return profile.uiTheme end
    if _G.ElvUI and (not profile or profile.elvuiSkin ~= false) then return "ElvUI" end
    if _G.EllesmereUI and type(_G.EllesmereUI.RegisterSkin) == "function"
        and (not profile or profile.ellesmereuiSkin ~= false) then return "EllesmereUI" end
    return "wow"
end

local scopeRoots = {CurrentStepScreenPanel = "currentStep", FillersScreenPanel = "fillers",
    QuestOrderListPanel = "questOrderList", AfkFrameScreen = "afk", PartyScreenPanel = "party",
    HeirloomPanel = "heirloom", BuffFrameScreen = "buff", CoordinateScreenPanel = "coordinates"}

function APR:GetSkinScope(frame)
    for _ = 1, 12 do
        if not frame then return end
        for name, scope in pairs(scopeRoots) do if frame == _G[name] then return scope end end
        frame = frame.GetParent and frame:GetParent()
    end
end

function APR:GetAppearanceProvider(scope)
    local choice = self.QuestTracker and self.QuestTracker.GetAppearanceProvider and self.QuestTracker:GetAppearanceProvider(scope)
    return choice or self:GetSelectedSkinName()
end

-- Skins keep persistent texture hooks; changing their scope needs a clean rebuild.
function APR:AppearanceNeedsReload(previous, current)
    local function needsRebuild(name)
        return name == "ElvUI" or name == "EllesmereUI" or
            (self.Themes and self.Themes[name] and self.Themes[name].style == "modern")
    end
    return current ~= previous and (needsRebuild(previous) or needsRebuild(current))
end

function APR:ReloadChangedTrackerAppearance(scope, previous)
    if not self:AppearanceNeedsReload(previous, self:GetAppearanceProvider(scope)) then return false end
    self:RequestReload()
    return true
end

-- Determine the future provider without publishing the proposed setting or touching frame geometry.
function APR:ChangeTrackerOption(scope, key, value, onChanged, prepare)
    local profile = self:GetSettingsProfile()
    local previous = self:GetAppearanceProvider(scope)
    local oldValue = profile[key]
    profile[key] = value
    local ok, current = pcall(self.GetAppearanceProvider, self, scope)
    profile[key] = oldValue
    if not ok then error(current, 0) end
    local function apply()
        if self:GetSettingsProfile() ~= profile then return false end
        if prepare then prepare() end
        profile[key] = value
        return true
    end
    if self:AppearanceNeedsReload(previous, current) then
        self:RequestReload(apply)
        return true
    end
    if apply() and onChanged then onChanged() end
    return false
end

function APR:IsSkinProviderUsed(name)
    if self:GetSelectedSkinName() == name then return true end
    local profile = self.GetSettingsProfile and self:GetSettingsProfile()
    return profile and profile.currentStepAttachFrameToQuestLog and profile.currentStepTrackerAppearance == name
end

local function TargetProvider(frame, target)
    local name = APR:GetAppearanceProvider(target.options.scope or APR:GetSkinScope(frame))
    return providers[name] or (provider and provider.name ~= "ElvUI" and provider.name ~= "EllesmereUI" and provider)
end

local function ApplyTarget(frame, target)
    if InCombatLockdown() then
        pending = true
        return
    end
    local selected = TargetProvider(frame, target)
    if not selected or not selected.enabled() then
        if APR.ApplyNativeTheme and not target.nativeApplied then
            APR:ApplyNativeTheme(frame, target.kind, target.options)
            target.nativeApplied = true
        end
        return
    end
    if target.applied then return end
    if target.nativeApplied and APR.RestoreNativeTheme then APR:RestoreNativeTheme(frame) end
    selected.apply(frame, target.kind, target.options)
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

function APR:RefreshRegisteredSkins(refreshNative)
    if refreshNative then
        for _, target in pairs(targets) do target.nativeApplied = nil end
    end
    if InCombatLockdown() then pending = true; return end
    pending = false
    for frame, target in pairs(targets) do ApplyTarget(frame, target) end
    if self.RefreshThemeRegions then self:RefreshThemeRegions() end
    if self.ApplyAllTextStyles then self:ApplyAllTextStyles() end
    if self.RefreshStatusBarColors then self:RefreshStatusBarColors() end
end

function APR:GetSkinProviderName(scope)
    local selected = providers[self:GetAppearanceProvider(scope)]
        or (provider and provider.name ~= "ElvUI" and provider.name ~= "EllesmereUI" and provider)
    return selected and selected.enabled() and selected.name or nil
end

function APR:AreSkinsPending() return pending end

function APR:RegisterSkinProvider(name, apply, enabled)
    -- A reload is required to change providers; never stack two skins on a control.
    if provider and provider.name ~= name and
        not ((name == "ElvUI" or name == "EllesmereUI") and
            (provider.name == "ElvUI" or provider.name == "EllesmereUI")) then return false end
    provider = { name = name, apply = apply, enabled = enabled }
    providers[name] = provider
    self:RefreshRegisteredSkins()
    return true
end

-- Only the small set of APR windows is enumerated, never UIParent or quest rows.
function APR:RegisterStaticSkinTargets()
    for _, name in ipairs({ "CurrentStepScreenPanel", "FillersScreenPanel", "QuestOrderListPanel",
        "CoordinateScreenPanel", "PartyScreenPanel",
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
            self:RegisterSkinTarget(header.MinimizeButton, "headerButton", {
                parent = header:GetParent(),
                close = name == "RouteSelectionFrameHeader" or name == "HeirloomFrameHeader",
            })
        end
    end
    self:RegisterSkinTarget(_G.CurrentStepFrameSettingsButton, "settings")
    for _, name in ipairs({ "QuestOrderListFrame_ScrollFrame" }) do
        local scroll = _G[name]
        self:RegisterSkinTarget(scroll and (scroll.ScrollBar or _G[name .. "ScrollBar"]), "scrollbar")
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
    if pending then APR:RefreshRegisteredSkins() end
    if APR.nativeTextRefreshPending then
        APR.nativeTextRefreshPending = nil
        if APR.RefreshTextAppearance then APR:RefreshTextAppearance() end
    end
end)
