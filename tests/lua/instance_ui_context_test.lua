-- Delayed instance-preference replies belong to the profile and character that
-- opened them. Invented routes exercise the real popup and protected panels.
local env = dofile("tests/lua/addon_journey_quest_env.lua")
local function noop() end
local state = { inside = true, kind = "party", prompts = {}, refreshes = 0 }
function IsInInstance() return state.inside, state.kind end
APR.settings.db = { char = {} }
dofile("APR-Core/utils/ProfileUtils.lua")
dofile("APR-Core/utils/InstanceUtils.lua")

local refresh = APR.RefreshInstanceUIVisibility
function APR:RefreshInstanceUIVisibility()
    state.refreshes = state.refreshes + 1
    return refresh(self)
end
StaticPopupDialogs = {}
function StaticPopup_Hide() end
function StaticPopup_Show(name)
    local dialog = assert(StaticPopupDialogs[name])
    state.prompts[#state.prompts + 1] = dialog
    return env.widget(UIParent)
end
APR.StyleStaticPopup = noop

local template = APR.settings.profile
local function profile(hide)
    local result = {}
    for key, value in pairs(template) do result[key] = value end
    result.forceHideUiInPartyRaid = hide
    return result
end
local sequence = 0
local function character()
    sequence = sequence + 1
    local id, record = "instance-character-" .. sequence, {}
    APRData[id] = { context = 1, BonusSkips = {}, WantedQuestList = {} }
    APRCustomPath[id], APRZoneCompleted[id] = { "Invented context route" }, {}
    return id, record
end
local function use(currentProfile, id, record)
    APR.settings.profile, APR.settings.db.char, APR.PlayerID = currentProfile, record, id
end
local function enter(kind)
    state.inside, state.kind = kind ~= "none", kind
end
local function prompt()
    local before = #state.prompts
    APR:MaybePromptInstanceUIPreference()
    assert(#state.prompts == before + 1, "An unanswered eligible character must get a fresh dialog")
    assert(APR.settings.db.char.instanceUiPromptShown)
    return state.prompts[#state.prompts]
end
local function panels(shown)
    assert(CurrentStepScreenPanel:IsShown() == shown, "The current character must own the current-step panel")
    assert(FillersScreenPanel:IsShown() == shown, "Optional objectives must use the current profile")
end
APR:ActivateRoute(nil)
APR.RouteQuestStepList = {
    context = { label = "Invented context route", mapID = 10, expansion = APR.EXPANSIONS.Custom,
        steps = {
            { Note = "Ordinary instruction", Fillers = { [8201] = { 1 } } },
            { Note = "Instance instruction", InstanceQuest = true, Fillers = { [8201] = { 1 } } },
        } },
}
local initialID, initialCharacter = character()
use(profile(false), initialID, initialCharacter)
H.quest(8201, "Optional collection 0/2")
assert(APR:ActivateRoute("context"))
local function step(index)
    APR:SetRouteProgress("context", index, "manual")
    APR:UpdateQuestAndStep()
end
step(1)

-- Each guard is independently necessary. Same-character profile replacement,
-- replaced character storage and changed player identity all obsolete a reply.
for _, answer in ipairs({ "OnAccept", "OnCancel" }) do
    for _, change in ipairs({ "profile", "character", "player", "database", "settings" }) do
        local initialHide = answer == "OnAccept"
        local oldProfile, id, record = profile(initialHide), character()
        use(oldProfile, id, record)
        local dialog = prompt()
        local newProfile = profile(initialHide)
        local settings, database = APR.settings, APR.settings.db
        if change == "profile" then APR.settings.profile = newProfile
        elseif change == "character" then APR.settings.db.char = {}
        elseif change == "player" then APR.PlayerID = "other-player"
        elseif change == "database" then APR.settings.db = nil
        else APR.settings = nil end
        local before = state.refreshes
        dialog[answer]()
        assert(oldProfile.forceHideUiInPartyRaid == initialHide,
            "A stale " .. answer .. " must not mutate its old " .. change .. " context")
        assert(newProfile.forceHideUiInPartyRaid == initialHide)
        assert(state.refreshes == before, "A stale reply must not refresh unrelated panels")
        assert(record.instanceUiPromptShown, "Rejecting a stale reply must retain the character receipt")
        APR.settings, settings.db = settings, database
    end
end

-- A profile switch does not consume another receipt for the same character.
-- A new character sharing the replacement profile gets its own live dialog.
local oldProfile, newProfile = profile(false), profile(false)
local oldID, oldCharacter = character()
use(oldProfile, oldID, oldCharacter)
local oldDialog = prompt()
APR.settings.profile = newProfile
local count = #state.prompts
APR:MaybePromptInstanceUIPreference()
assert(#state.prompts == count and oldCharacter.instanceUiPromptShown)
local newID, newCharacter = character()
use(newProfile, newID, newCharacter)
local newDialog = prompt()
assert(newDialog ~= oldDialog)
local before = state.refreshes
oldDialog.OnCancel()
assert(not oldProfile.forceHideUiInPartyRaid and not newProfile.forceHideUiInPartyRaid)
assert(state.refreshes == before)
newDialog.OnCancel()
assert(newProfile.forceHideUiInPartyRaid and state.refreshes == before + 1)
panels(false)

-- The preference stays shared by profile; the receipt stays per character.
local sharedID, sharedCharacter = character()
use(newProfile, sharedID, sharedCharacter)
prompt().OnAccept()
assert(not newProfile.forceHideUiInPartyRaid)
panels(true)
use(newProfile, newID, newCharacter)
APR:RefreshInstanceUIVisibility()
panels(true)
count = #state.prompts
APR:MaybePromptInstanceUIPreference()
assert(#state.prompts == count)

-- A valid reply after instance exit persists the preference but uses world
-- visibility now. Returning to the raid applies it without another prompt.
local exitID, exitCharacter = character()
use(newProfile, exitID, exitCharacter)
enter("raid")
local exitDialog = prompt()
enter("none")
exitDialog.OnCancel()
assert(newProfile.forceHideUiInPartyRaid)
panels(true)
enter("raid")
APR:RefreshInstanceUIVisibility()
panels(false)
count = #state.prompts
APR:MaybePromptInstanceUIPreference()
assert(#state.prompts == count)

-- Changing the displayed step does not obsolete a valid profile preference.
local stepID, stepCharacter = character()
use(newProfile, stepID, stepCharacter)
local stepDialog = prompt()
step(2)
stepDialog.OnCancel()
assert(newProfile.forceHideUiInPartyRaid)
panels(true)
step(1)
APR:RefreshInstanceUIVisibility()
panels(false)

-- A live reply during combat uses the existing protected-panel deferral; an
-- obsolete reply in that same combat must not queue work for another profile.
local combatProfile = profile(false)
local combatID, combatCharacter = character()
use(combatProfile, combatID, combatCharacter)
APR:RefreshInstanceUIVisibility()
local combatDialog = prompt()
APR.currentStep:AddStepButton("8201-1", 44, "item")
env.setCombat(true)
local hides = CurrentStepScreenPanel.hideCount
combatDialog.OnCancel()
assert(combatProfile.forceHideUiInPartyRaid)
assert(APR.currentStep.pendingAnchorRefresh and CurrentStepScreenPanel.hideCount == hides)
assert(APR.fillersFrame.pendingRefresh and FillersScreenPanel.alpha == 0)
local replacement = profile(false)
APR.settings.profile = replacement
before = state.refreshes
combatDialog.OnAccept()
assert(combatProfile.forceHideUiInPartyRaid and not replacement.forceHideUiInPartyRaid)
assert(state.refreshes == before)
env.setCombat(false)
APR.settings.profile = combatProfile
APR:RefreshInstanceUIVisibility()
panels(false)
assert(not APR.currentStep.pendingAnchorRefresh and not APR.fillersFrame.pendingRefresh)
assert(#H.errors == 0, table.concat(H.errors, "\n"))

-- Absent scenario history needs no iterable container. Existing histories remain
-- live: appends, in-place edits and removals must not need cache invalidation.
local originalIpairs, iterations = ipairs, 0
ipairs = function(values) iterations = iterations + 1; return originalIpairs(values) end
for _ = 1, 10000 do
    assert(not APR:ContainsScenarioStepCriteria(nil, 21, 31, 1))
    assert(not APR:ContainsScenarioStepCriteria(false, 21, 31, 1))
end
ipairs = originalIpairs
assert(iterations == 0, "Missing scenario history must return without iterator work")
local history = {}
assert(not APR:ContainsScenarioStepCriteria(history, 21, 31, 1))
history[1] = { stepID = 21, criteriaID = 31, criteriaIndex = 1 }
assert(APR:ContainsScenarioStepCriteria(history, 21, 31, 1))
history[1].criteriaIndex = 2
assert(not APR:ContainsScenarioStepCriteria(history, 21, 31, 1))
assert(APR:ContainsScenarioStepCriteria(history, 21, 31, 2))
history[1] = nil
assert(not APR:ContainsScenarioStepCriteria(history, 21, 31, 2))
print("Instance context: stale profile/character replies rejected, live dialogs/exit/combat preserved; 20000 absent histories without iterator work")
