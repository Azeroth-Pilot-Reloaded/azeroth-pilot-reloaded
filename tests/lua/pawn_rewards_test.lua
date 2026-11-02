-- Pawn is an optional scorer. Invented scales exercise its public contracts,
-- explicit selection and mutation lifecycle without shipping external weights.
local function newEnvironment(saved, pawnScales)
    local env = { now = 0, timers = {}, prompts = {}, hooks = {}, ready = true, spec = 101,
        combat = false, class = "MAGE", statsReads = 0, itemCalls = {} }
    DEFAULT = "Default"
    local strings = {
        REWARD_PAWN_CHANGED = "Use changed scale %s?",
        REWARD_PAWN_UNAVAILABLE = "Unavailable %s; APR is active",
        REWARD_WEIGHT_SCALE_DESC = "Select a scale",
        REWARD_WEIGHT_DEFAULT_DESC = "Default weights for %s",
    }
    env.notifications = {}
    LibStub = function() return { GetLocale = function() return strings end } end
    APR = { settings = { db = { char = saved or {} },
        profile = { enableAddon = true, autoHandIn = true, autoHandInChoice = true } },
        questionDialog = {}, RewardScoring = { GetProfileDescription = function() return "Synthetic caster" end } }
    function APR:GetSettingsProfile() return self.settings.profile end
    function env:RenderOptions()
        self.visibleOptions = { values = self.module:GetScaleOptions(),
            choice = self.module:GetSelectedScale(), status = self.module:GetStatusText() }
    end
    function env:OpenOptions()
        self.optionsOpen = true
        APR.OptionsPanel = { view = { app = "Synthetic/options/rewards" },
            frame = { IsShown = function() return self.optionsOpen end,
                IsVisible = function() return self.optionsOpen and not self.optionsAncestorHidden end } }
        function APR.OptionsPanel:QueueRefresh()
            if not self.frame:IsVisible() or env.optionTimer then return end
            local panel, view = self, self.view
            env.optionTimer = C_Timer.NewTimer(0, function()
                env.optionTimer = nil
                if APR.OptionsPanel ~= panel or panel.view ~= view or not panel.frame:IsVisible() then return end
                env.notifications[#env.notifications + 1] = view.app
                env:RenderOptions()
            end)
        end
        self:RenderOptions()
    end
    function APR:NewModule(name, mixin)
        assert(name == "PawnRewards" and mixin == "AceEvent-3.0")
        return {
            events = {},
            RegisterEvent = function(self, event, method) self.events[event] = method end,
            UnregisterEvent = function(self, event) self.events[event] = nil end,
            UnregisterAllEvents = function(self) self.events = {} end,
        }
    end
    function UnitClass() return "Synthetic mage", env.class end
    C_SpecializationInfo = {
        GetSpecialization = function() return env.spec and 1 end,
        GetSpecializationInfo = function() return env.spec end,
    }
    GetSpecialization, GetSpecializationInfo = nil, nil
    function InCombatLockdown() return env.combat end
    issecretvalue = function(value) return value == env.secret end
    function hooksecurefunc(name, callback)
        env.hooks[name] = (env.hooks[name] or 0) + 1
        local original = _G[name]
        _G[name] = function(...)
            local result = { original(...) }
            callback(...)
            return unpack(result)
        end
    end
    C_Timer = { NewTimer = function(delay, callback)
        local timer = { at = env.now + delay, callback = callback,
            Cancel = function(self) self.cancelled = true end }
        env.timers[#env.timers + 1] = timer
        return timer
    end }
    function env:Advance(seconds)
        local untilTime = self.now + seconds
        for _ = 1, 1000 do
            local nextTimer
            for _, timer in ipairs(self.timers) do
                if not timer.cancelled and not timer.fired and timer.at <= untilTime
                    and (not nextTimer or timer.at < nextTimer.at) then nextTimer = timer end
            end
            if not nextTimer then self.now = untilTime; return end
            self.now, nextTimer.fired = nextTimer.at, true
            nextTimer.callback()
        end
        error("Timer chain failed to settle")
    end
    function env:Event(event, ...)
        local method = self.module.events[event]
        if method then self.module[method](self.module, event, ...) end
    end
    function StaticPopup_OnHide() end
    local function hidePrompt(prompt)
        if env.visible ~= prompt then return end
        env.visible = nil
        StaticPopup_OnHide(prompt)
    end
    function APR.questionDialog:CreateQuestionPopup(name, text, accept, cancel)
        env.popupAttempts = (env.popupAttempts or 0) + 1
        if env.popupBlocked then cancel(nil, nil); return end
        local prompt = { name = name, which = name, text = text }
        prompt.accept = function() accept(prompt, nil); hidePrompt(prompt) end
        prompt.cancel = function() cancel(prompt, nil, "clicked"); hidePrompt(prompt) end
        prompt.override = function() hidePrompt(prompt); cancel(prompt, nil, "override") end
        env.prompts[#env.prompts + 1] = prompt
        env.visible = prompt
        return prompt
    end
    function StaticPopup_Hide(name)
        local prompt = env.visible
        if prompt and prompt.name == name then hidePrompt(prompt) end
    end
    PawnCommon = { Scales = pawnScales or {
        Custom = { Values = { Intellect = 2, Haste = 0.5 }, NormalizationFactor = 1 },
        Hidden = { Values = { Intellect = 3 } },
        Provider = { Values = { Intellect = 4 }, Provider = "Synthetic" },
    } }
    function PawnIsReady() return env.ready end
    function PawnGetAllScalesEx()
        local list = {}
        for name, scale in pairs(PawnCommon.Scales) do
            list[#list + 1] = { Name = name, LocalizedName = name .. " label",
                IsVisible = name ~= "Hidden", IsProvider = scale.Provider ~= nil }
        end
        return list
    end
    function PawnGetAllStatValues(name)
        env.statsReads = env.statsReads + 1
        return PawnCommon.Scales[name] and PawnCommon.Scales[name].Values
    end
    function PawnGetItemData(link)
        env.itemCalls[#env.itemCalls + 1] = link
        if env.missing then return end
        return { UnenchantedStats = { Intellect = 10 }, link = link }
    end
    function PawnGetSingleValueFromItem(item, name)
        if env.badScore then return 25, env.badScore end
        return 999, item.UnenchantedStats.Intellect * PawnCommon.Scales[name].Values.Intellect
    end
    function PawnInitialize() env.ready = true end
    function PawnRecalculateScaleTotal() end
    function PawnSetStatValue(name, stat, value) PawnCommon.Scales[name].Values[stat] = value end
    function PawnAddEmptyScale(name) PawnCommon.Scales[name] = { Values = {} } end
    function PawnAddDefaultScale(name) PawnCommon.Scales[name] = { Values = { Intellect = 1 } } end
    function PawnImportScale(name, weight) PawnCommon.Scales[name] = { Values = { Intellect = weight } } end
    function PawnDeleteScale(name) PawnCommon.Scales[name] = nil end
    function PawnRenameScale(old, new) PawnCommon.Scales[new] = PawnCommon.Scales[old]; PawnCommon.Scales[old] = nil end
    function PawnDuplicateScale(old, new)
        local values = {}; for stat, weight in pairs(PawnCommon.Scales[old].Values) do values[stat] = weight end
        PawnCommon.Scales[new] = { Values = values }
    end
    function PawnSetScaleNormalizationFactor(name, value) PawnCommon.Scales[name].NormalizationFactor = value end
    function PawnResetScales() for name, scale in pairs(PawnCommon.Scales) do if not scale.Provider then PawnCommon.Scales[name] = nil end end end
    PawnResetProviderScales, PawnResetScalesCore, PawnAddPluginScale = nil, nil, nil
    dofile("APR-Core/integrations/Pawn.lua")
    env.module = APR.PawnRewards
    env.module:OnEnable()
    return env
end

local env = newEnvironment()
local module = env.module
assert(#env.prompts == 0, "An existing custom-scale catalog is an initial baseline, not a batch of new imports")
local options = module:GetScaleOptions()
assert(options.apr == "Default (APR)" and options["pawn:Hidden"] == "Hidden label (Pawn)" and options["pawn:Provider"],
    "Hidden user scales and active provider scales remain selectable")
assert(module:GetSelectedScale() == "apr" and module:GetScorer() == nil)
assert(module:GetStatusText() == "Default weights for Synthetic caster")
assert(not module:SetSelectedScale("missing") and module:SetSelectedScale("Hidden"))
local scorer = module:GetScorer()
local score, ready = scorer("item:700001:0:0:0:0:0:42")
assert(score == 30 and ready and env.itemCalls[1] == "item:700001:0:0:0:0:0:42",
    "Pawn receives the exact variant and APR uses its base score, even for a hidden scale")
env.missing = true
score, ready = scorer("item:700002")
assert(score == nil and ready == false, "Missing native/Pawn data cannot become a zero-score choice")
env.missing, env.badScore = false, math.huge
score, ready = scorer("item:700002")
assert(score == nil and not ready)
env.badScore, env.secret = {}, {}
env.badScore = env.secret
score, ready = scorer("item:700002")
assert(score == nil and not ready, "Opaque or nonnumeric values cannot enter reward comparisons")
env.badScore = nil
assert(PawnCommon.Scales.Hidden.Values.Intellect == 3 and PawnCommon.Scales.Custom.NormalizationFactor == 1,
    "Reading catalog and scores never changes Pawn's values")

env.spec = 102
assert(module:GetSelectedScale() == "apr")
assert(module:SetSelectedScale("Custom"))
env.spec = 101
assert(module:GetSelectedScale() == "pawn:Hidden", "Selections belong to a character and specialization")
env.spec = nil
assert(module:SetSelectedScale("Provider"))
env:Event("PLAYER_SPECIALIZATION_CHANGED", "party1")
assert(not module.refreshTimer)
assert(APR.settings.db.char.rewardPawnScales["class:MAGE"].name == "Provider",
    "Clients without a current spec retain a class selection")

-- Repeated edits coalesce and the selected scorer stops immediately, before the timer.
env = newEnvironment(); module = env.module
module:SetSelectedScale("Custom")
scorer = module:GetScorer()
local beforeTimers = #env.timers
for value = 1, 100 do PawnSetStatValue("Custom", "Intellect", value) end
assert(#env.timers == beforeTimers + 1 and #env.prompts == 0)
assert(module:GetSelectedScale() == "apr" and module:GetScorer() == nil)
score, ready = scorer("item:700003")
assert(score == nil and not ready, "An already obtained scorer cannot use newly edited weights without confirmation")
env:Advance(0.25)
assert(#env.prompts == 1)
env.prompts[1].accept()
assert(module:GetSelectedScale() == "pawn:Custom")
score, ready = module:GetScorer()("item:700003")
assert(score == 1000 and ready)
env:Advance(1)
assert(#env.prompts == 1, "An accepted fingerprint never prompts again")
assert(env.hooks.PawnSetStatValue == 1 and env.hooks.PawnInitialize == 1,
    "Refreshing settings must not multiply permanent secure hooks")

PawnSetScaleNormalizationFactor("Custom", 2)
env:Advance(0.25)
assert(#env.prompts == 2 and module:GetSelectedScale() == "apr",
    "Normalization changes are detected even without a weight-table edit")
env.prompts[2].cancel()
assert(module:GetSelectedScale() == "apr")
local saved = APR.settings.db.char
local pawnScales = PawnCommon.Scales
env = newEnvironment(saved, pawnScales); module = env.module
module:RefreshSettings()
assert(#env.prompts == 0 and module:GetSelectedScale() == "apr",
    "A declined fingerprint stays declined across reloads with the same Pawn values")
module:SetSelectedScale("Hidden")
PawnImportScale("New", 7); env:Advance(0.25)
local imported = env.prompts[#env.prompts]
imported.cancel(); env:Advance(1)
assert(module:GetSelectedScale() == "pawn:Hidden", "Declining an unrelated import preserves the selected scale")
local promptCount = #env.prompts
module:RefreshSettings()
assert(#env.prompts == promptCount, "A declined imported fingerprint is remembered")

-- UI callbacks revalidate the current item, spec, settings and lifecycle.
PawnSetStatValue("Hidden", "Intellect", 6); env:Advance(0.25)
local obsolete = env.prompts[#env.prompts]
PawnSetStatValue("Hidden", "Intellect", 9)
obsolete.accept()
assert(module:GetSelectedScale() == "apr", "A stale confirmation cannot accept a later edit")
env:Advance(0.25)
local current = env.prompts[#env.prompts]
assert(current ~= obsolete)
obsolete.cancel()
current.accept()
assert(module:GetSelectedScale() == "pawn:Hidden")
env:Advance(1)
PawnImportScale("SpecChanged", 5); env:Advance(0.25)
obsolete = env.prompts[#env.prompts]
env.spec = 222
obsolete.accept()
assert(module:GetSelectedScale() == "apr" and not APR.settings.db.char.rewardPawnScales["spec:222"],
    "A dialog opened for another specialization cannot set the new specialization's choice")
module:RefreshSettings()
env.prompts[#env.prompts].cancel(); env:Advance(1)
env.spec = 101
PawnDeleteScale("Hidden"); env:Advance(0.25)
assert(module:GetSelectedScale() == "apr" and not APR.settings.db.char.rewardPawnScales["spec:101"],
    "Deleting a selected scale retires its saved selection")

-- Disabled preferences and combat defer proposals without losing the changes.
for _, flag in ipairs({ "enableAddon", "autoHandIn", "autoHandInChoice" }) do
    env = newEnvironment(); module = env.module
    APR.settings.profile[flag] = false
    module:RefreshSettings()
    PawnImportScale("Later", 8); env:Advance(1)
    assert(#env.prompts == 0)
    APR.settings.profile[flag] = true
    module:RefreshSettings()
    assert(#env.prompts == 1, "Enabling automatic rewards can offer a change made while disabled: " .. flag)
    APR.settings.profile[flag] = false
    env.prompts[1].accept()
    assert(module:GetSelectedScale() == "apr", "A disabled action cannot be revived by an old callback")
end
env = newEnvironment(); module = env.module
env.combat = true
PawnImportScale("Combat", 8); env:Advance(1)
assert(#env.prompts == 0 and module.events.PLAYER_REGEN_ENABLED)
env.combat = false; env:Event("PLAYER_REGEN_ENABLED")
assert(#env.prompts == 1 and not module.events.PLAYER_REGEN_ENABLED)
env.prompts[1].cancel(); env:Advance(1)
PawnImportScale("Delayed", 9)
local staleTimer = module.refreshTimer
module:OnDisable()
module:OnEnable()
local pendingPrompt = module.prompt
staleTimer.callback()
assert(module.prompt == pendingPrompt and next(module.events),
    "A cancelled timer cannot consume a newly enabled module's work")
module:OnDisable()
local count = #env.timers
PawnSetStatValue("Custom", "Intellect", 4)
assert(#env.timers == count and not next(module.events), "Disabled integrations have no listeners or scheduled work")

-- Pawn initializes at PLAYER_LOGIN and may also load after APR.
env = newEnvironment(); module = env.module
env.ready = false; module:RefreshSettings()
assert(module:GetScorer() == nil)
module:OnDisable(); module:OnEnable()
assert(module.events.ADDON_LOADED and module.events.PLAYER_LOGIN)
PawnInitialize(); env:Advance(0.25)
assert(module.ready and not module.events.ADDON_LOADED and not module.events.PLAYER_LOGIN)
assert(module:SetSelectedScale("Custom"))
env.ready = false
assert(module:GetSelectedScale() == "apr" and module:GetScorer() == nil)
assert(module:GetStatusText():find("Unavailable", 1, true))
env.ready = true
assert(module:GetSelectedScale() == "pawn:Custom", "Unavailable Pawn retains an explicit compatible choice for its return")
local scoringAPI = PawnGetSingleValueFromItem
PawnGetSingleValueFromItem = nil
assert(module:GetSelectedScale() == "apr" and module:GetScorer() == nil,
    "An incompatible partial Pawn API cannot masquerade as the active scorer")
PawnGetSingleValueFromItem = scoringAPI
module:RefreshSettings()
scorer = module:GetScorer()
module:OnDisable()
score, ready = scorer("item:700003")
assert(score == nil and not ready and module:GetScorer() == nil,
    "Captured scorers are inert after their integration is disabled")
module:OnEnable()

-- UI identifiers cannot collide with arbitrary user-defined scale names.
PawnImportScale("apr", 12)
PawnImportScale("pawn:apr", 13)
env:Advance(0.25)
options = module:GetScaleOptions()
assert(options.apr == "Default (APR)" and options["pawn:apr"] and options["pawn:pawn:apr"])
assert(module:SetSelectedScale("pawn:apr") and module:GetSelectedScale() == "pawn:apr")
assert(APR.settings.db.char.rewardPawnScales["spec:101"].name == "apr")
score, ready = module:GetScorer()("item:700004")
assert(score == 120 and ready)
assert(module:SetSelectedScale("pawn:pawn:apr"))
score, ready = module:GetScorer()("item:700004")
assert(score == 130 and ready)
module:SetSelectedScale("apr")
assert(module:GetSelectedScale() == "apr")

PawnImportScale("ProfileChanged", 9); env:Advance(0.25)
obsolete = env.prompts[#env.prompts]
APR.settings.profile = { enableAddon = true, autoHandIn = true, autoHandInChoice = true }
obsolete.accept()
assert(module:GetSelectedScale() == "apr" and not module.prompt,
    "A profile replacement invalidates its old dialog even when automatic rewards remain enabled")
print("Pawn rewards: exact public scores, per-spec choices, mutation proposals, stale callbacks and optional-addon lifecycle passed")


-- An allocation failure is not a user refusal and does not poll for a free slot.
env = newEnvironment(); module = env.module
assert(module:SetSelectedScale("Custom"))
local accepted = APR.settings.db.char.rewardPawnScales["spec:101"].fingerprint
local seen = APR.settings.db.char.rewardPawnSeen.fingerprints.Custom
env.popupBlocked = true
PawnSetStatValue("Custom", "Intellect", 15)
env:Advance(0.25)
local record = APR.settings.db.char.rewardPawnScales["spec:101"]
assert(record and record.fingerprint == accepted,
    "A popup that was never displayed cannot retire the accepted scale")
assert(APR.settings.db.char.rewardPawnSeen.fingerprints.Custom == seen,
    "A failed allocation cannot persist a declined fingerprint")
local attempts = env.popupAttempts
env:Advance(30)
assert(env.popupAttempts == attempts and not module.refreshTimer,
    "Waiting for a popup slot stays dormant without a native closure")
env.popupBlocked = false
StaticPopup_OnHide({ which = "OTHER_DIALOG" })
env:Advance(0.25)
assert(#env.prompts == 1, "Freeing a popup slot must offer the pending version")
env.prompts[1].accept(); env:Advance(1)
assert(module:GetSelectedScale() == "pawn:Custom")

-- Programmatic hides and replacements also leave the version pending.
for _, close in ipairs({"override", "hide"}) do
    env = newEnvironment(); module = env.module
    module:SetSelectedScale("Custom")
    accepted = APR.settings.db.char.rewardPawnScales["spec:101"].fingerprint
    PawnSetStatValue("Custom", "Intellect", 16); env:Advance(0.25)
    local offered = env.prompts[1]
    if close == "override" then offered.override() else StaticPopup_Hide(offered.name) end
    env:Advance(0.25)
    assert(APR.settings.db.char.rewardPawnScales["spec:101"].fingerprint == accepted,
        "Programmatic closure preserves the accepted version: " .. close)
    assert(#env.prompts == 2, "A closed unacknowledged offer is displayed again: " .. close)
    env.prompts[2].cancel(); env:Advance(1)
    assert(module:GetSelectedScale() == "apr" and #env.prompts == 2,
        "An explicit refusal resolves the version without another offer")
end

-- Retired or disabled work cannot be revived by unrelated popup traffic.
for _, retire in ipairs({"disabled", "deleted", "choice"}) do
    env = newEnvironment(); module = env.module
    env.popupBlocked = true
    PawnImportScale("Waiting", 7); env:Advance(0.25)
    if retire == "disabled" then module:OnDisable()
    elseif retire == "deleted" then PawnDeleteScale("Waiting"); env:Advance(0.25)
    else module:SetSelectedScale("apr") end
    attempts = env.popupAttempts
    env.popupBlocked = false
    StaticPopup_OnHide({ which = "OTHER_DIALOG" }); env:Advance(1)
    assert(env.popupAttempts == attempts and #env.prompts == 0,
        "Popup availability cannot revive retired work: " .. retire)
end


-- The open settings view consumes refreshed values, choice and status together.
env = newEnvironment(); module = env.module
env:OpenOptions()
assert(env.visibleOptions.choice == "apr" and not env.visibleOptions.values["pawn:VisibleNow"])
PawnImportScale("VisibleNow", 9); env:Advance(0.25)
assert(env.visibleOptions.values["pawn:VisibleNow"],
    "An imported scale appears in the existing open selector")
env.prompts[1].accept(); env:Advance(0.25)
assert(env.visibleOptions.choice == "pawn:VisibleNow" and env.visibleOptions.status:find("VisibleNow", 1, true),
    "Accepting a scale publishes its choice and status to the same view")
PawnDeleteScale("VisibleNow"); env:Advance(0.25)
assert(not env.visibleOptions.values["pawn:VisibleNow"] and env.visibleOptions.choice == "apr"
    and env.visibleOptions.status == "Default weights for Synthetic caster",
    "Deleting a selected scale removes its row and publishes the fallback")
module:SetSelectedScale("Custom"); env:Advance(0)
assert(env.visibleOptions.choice == "pawn:Custom", "Explicit choices update the current view")
local notifications = #env.notifications
for _ = 1, 20 do module:GetScaleOptions(); module:GetSelectedScale(); module:GetStatusText() end
assert(#env.notifications == notifications, "Rendering settings cannot recursively publish another refresh")
env.optionsOpen = false
PawnImportScale("HiddenView", 4); env:Advance(0.25)
assert(#env.notifications == notifications, "Hidden settings do not rebuild controls")
env:OpenOptions()
assert(env.visibleOptions.values["pawn:HiddenView"], "Reopening reads the latest catalog normally")

notifications = #env.notifications
env.optionsAncestorHidden = true
PawnImportScale("HiddenAncestor", 5); env:Advance(0.25)
assert(#env.notifications == notifications,
    "An open control under a hidden workspace does not rebuild")
