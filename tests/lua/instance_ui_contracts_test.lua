-- Instance policy must reach the real guide panels and preference callbacks.
-- All routes, objectives and character records here are invented.
local env = dofile("tests/lua/addon_journey_quest_env.lua")
local function noop() end
local state = { inside = false, kind = "none", prompts = {}, dispatched = 0 }
function IsInInstance() return state.inside, state.kind end
APR.settings.db = { char = { instanceUiPromptShown = true } }
dofile("APR-Core/utils/ProfileUtils.lua")
dofile("APR-Core/utils/InstanceUtils.lua")
dofile("APR-Core/ui/route/QuestOrderListSupport.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/ui/route/QuestOrderList.lua")
dofile("APR-Core/ui/route/QuestOrderListRows.lua")

local profile = APR.settings.profile
profile.currentStepScale, profile.questOrderListScale = 1, 1
profile.questOrderListFrame, profile.questOrderListbackgroundColorAlpha = {}, { 0, 0, 0, 1 }
profile.showQuestOrderList, profile.questOrderListSnapToCurrentStep = true, false
profile.forceHideUiInPartyRaid, profile.currentStepShow, profile.enableAddon = false, true, true
APR.routeconfig.HasRouteInCustomPath = function() return true end
APR:ActivateRoute(nil)
APR.RouteQuestStepList = {
    contract = { label = "Synthetic instance guide", mapID = 10, expansion = APR.EXPANSIONS.Custom,
        steps = {
            { Note = "Ordinary objective", Fillers = { [9103] = { 1 } } },
            { Note = "Explicit instance objective", InstanceQuest = true, Fillers = { [9103] = { 1 } } },
        } },
    replacement = { label = "Synthetic replacement guide", mapID = 10, expansion = APR.EXPANSIONS.Custom,
        steps = { { Note = "Replacement ordinary objective", Fillers = { [9103] = { 1 } } } } },
}
APRData.player.contract, APRData.player.replacement = 1, 1
APRCustomPath.player = { "Synthetic instance guide" }
H.quest(9103, "Optional objective 0/3")
assert(APR:ActivateRoute("contract"))

-- Exercise the production QuestionPopup adapter through its native boundary.
StaticPopupDialogs = {}
function StaticPopup_Hide() end
function StaticPopup_Show(name)
    local dialog = StaticPopupDialogs[name]
    assert(dialog and type(dialog.OnAccept) == "function" and type(dialog.OnCancel) == "function")
    state.prompts[#state.prompts + 1] = { name = name, dialog = dialog }
    return env.widget(UIParent)
end
APR.StyleStaticPopup = noop

local event = { tag = "instance_contract", callback = function() state.dispatched = state.dispatched + 1 end }
local function emit()
    APR.event.EventHandler(event, "GROUP_ROSTER_UPDATE")
    assert(#H.errors == 0, table.concat(H.errors, "\n"))
end
local function drain()
    for _ = 1, 100 do
        local work = false
        for _, owner in ipairs({ APR.questOrderList, APR.questOrderList.virtualList }) do
            local frame = owner.renderFrame
            if frame and frame.scripts.OnUpdate then frame.scripts.OnUpdate(); work = true end
        end
        if #H.timers > 0 then H.frame(0.2); work = true end
        if not work then return end
    end
    error("A small synthetic instance guide must settle its UI work")
end
local function panels(main, fillers, order)
    assert(CurrentStepScreenPanel:IsShown() == main, "Main guide visibility violates the instance/user policy")
    assert(FillersScreenPanel:IsShown() == fillers, "Optional objectives must follow their guide's visibility")
    assert(QuestOrderListPanel:IsShown() == order, "The independent route-order panel must follow its own settings")
end
local function refresh()
    APR:RefreshInstanceUIVisibility()
    drain()
end
local function selectStep(index)
    APR:SetRouteProgress("contract", index, "manual")
    APR:UpdateQuestAndStep()
end
local function enter(kind)
    state.inside, state.kind = kind ~= "none", kind
end

-- Expected outcomes are authored independently of IsInstanceWithUI. PvP wins
-- even over an InstanceQuest override; that override wins over a raid preference.
for _, case in ipairs({
    { "none", 1, false, true }, { "none", 1, true, true },
    { "party", 1, false, true }, { "party", 1, true, false },
    { "raid", 1, false, true }, { "raid", 1, true, false },
    { "party", 2, true, true }, { "raid", 2, true, true },
    { "pvp", 1, false, false }, { "pvp", 2, false, false },
    { "arena", 1, false, false }, { "arena", 2, true, false },
    { "scenario", 1, true, true },
}) do
    enter(case[1])
    profile.forceHideUiInPartyRaid = case[3]
    selectStep(case[2])
    local before = state.dispatched
    emit()
    assert(APR:IsInstanceWithUI() == case[4], "Unexpected UI policy for " .. case[1])
    assert(APR:IsScenarioInstance() == (case[1] == "scenario"))
    assert(state.dispatched - before == ((case[1] == "pvp" or case[1] == "arena") and 0 or 1),
        "PvP events must not run ordinary guide handlers")
    refresh()
    panels(case[4], case[4], case[4])
end
assert(#state.prompts == 0, "An already answered character must not be prompted again")

-- Activation/deactivation and progress changes are evaluated live, rather than
-- reusing the previous dungeon step or its visibility override.
enter("party")
profile.forceHideUiInPartyRaid = true
selectStep(2); refresh(); panels(true, true, true)
assert(APR:ActivateRoute("replacement"))
APRCustomPath.player = { "Synthetic replacement guide" }
APR:UpdateQuestAndStep(); emit(); refresh(); panels(false, false, false)
assert(APR:ActivateRoute(nil))
assert(not APR:IsInstanceWithUI(), "A party cannot show an inactive ordinary guide")
emit(); refresh(); panels(false, false, false)
-- World UI is allowed again, but the route-order list has no active route.
enter("none"); emit(); refresh(); panels(true, true, false)
APRCustomPath.player = { "Synthetic instance guide" }
assert(APR:ActivateRoute("contract"))
selectStep(1)

-- Eligibility does not consume the one-time prompt in the world, PvP, scenarios,
-- without a selected route, or on an explicit instance objective.
local character = APR.settings.db.char
character.instanceUiPromptShown = false
for _, kind in ipairs({ "none", "pvp", "arena", "scenario" }) do enter(kind); emit() end
assert(not character.instanceUiPromptShown and #state.prompts == 0)
enter("raid")
APR:ActivateRoute(nil); emit()
assert(not character.instanceUiPromptShown and #state.prompts == 0)
APR:ActivateRoute("contract"); selectStep(2); emit()
assert(not character.instanceUiPromptShown and #state.prompts == 0)
selectStep(1); emit()
assert(character.instanceUiPromptShown and #state.prompts == 1)
local prompt = state.prompts[1]
assert(prompt.name == "APR_INSTANCE_UI_PREFERENCE" and type(prompt.dialog.text) == "string" and #prompt.dialog.text > 0)
for _ = 1, 50 do emit() end
assert(#state.prompts == 1, "Repeated instance/group events share the one character prompt")

-- An answer applies to the currently displayed step, not the ordinary step
-- that originally opened the prompt. The instance override remains authoritative.
selectStep(2); emit()
prompt.dialog.OnCancel()
assert(profile.forceHideUiInPartyRaid == true)
drain(); panels(true, true, true)
selectStep(1); emit(); refresh(); panels(false, false, false)
-- Preferences survive exits/returns without another prompt.
enter("none"); emit(); refresh(); panels(true, true, true)
enter("party"); emit(); refresh(); panels(false, false, false)
assert(#state.prompts == 1)
selectStep(2); emit(); refresh(); panels(true, true, true)
selectStep(1); emit(); refresh(); panels(false, false, false)

-- A different character has an independent prompt receipt even when it shares
-- the profile. Its answer updates that profile and the currently owned panels.
local secondCharacter = { instanceUiPromptShown = false }
APR.settings.db.char, APR.PlayerID = secondCharacter, "other-player"
APRData[APR.PlayerID] = { contract = 1, BonusSkips = {}, WantedQuestList = {} }
APRCustomPath[APR.PlayerID], APRZoneCompleted[APR.PlayerID] = { "Synthetic instance guide" }, {}
emit()
assert(character.instanceUiPromptShown and secondCharacter.instanceUiPromptShown and #state.prompts == 2)
state.prompts[2].dialog.OnAccept()
assert(profile.forceHideUiInPartyRaid == false)
drain(); panels(true, true, true)
enter("raid"); emit(); refresh(); panels(true, true, true)
assert(#state.prompts == 2)

-- Visibility settings remain independent of instance eligibility. Disabling the
-- addon rejects event dispatch; the public refresh applies the toggle to panels.
profile.enableAddon = false
local dispatched, prompts = state.dispatched, #state.prompts
emit(); refresh(); panels(false, false, false)
assert(state.dispatched == dispatched and #state.prompts == prompts)
profile.enableAddon, profile.currentStepShow = true, false
assert(APR:IsInstanceWithUI())
refresh(); panels(false, false, true)
profile.currentStepShow, profile.showQuestOrderList = true, false
refresh(); panels(true, true, false)
profile.showQuestOrderList = true
refresh(); panels(true, true, true)

-- Protected current-step parents defer geometry during combat. Instance policy
-- still changes immediately; fillers use alpha until the post-combat refresh.
local row = APR.currentStep.fillersList["9103-1"]
assert(row)
APR.currentStep:AddStepButton("9103-1", 44, "item")
env.setCombat(true)
enter("pvp")
assert(not APR:IsInstanceWithUI())
local hides = CurrentStepScreenPanel.hideCount
refresh()
assert(APR.currentStep.pendingAnchorRefresh and CurrentStepScreenPanel.hideCount == hides)
assert(APR.fillersFrame.pendingRefresh and FillersScreenPanel.alpha == 0)
assert(not QuestOrderListPanel:IsShown())
env.setCombat(false)
refresh(); panels(false, false, false)
enter("none"); refresh(); panels(true, true, true)
assert(not APR.currentStep.pendingAnchorRefresh and not APR.fillersFrame.pendingRefresh)

-- Optional result/settings/owner data supported by the module must not invent
-- prompts. IsInInstance itself is a required client API, rather than optional.
secondCharacter.instanceUiPromptShown = false
state.inside, state.kind = nil, nil
assert(APR:IsInstanceWithUI() and not APR:IsScenarioInstance())
APR:MaybePromptInstanceUIPreference()
assert(not secondCharacter.instanceUiPromptShown and #state.prompts == prompts)
enter("party")
APR.settings.profile = nil
assert(APR:IsInstanceWithUI())
APR:MaybePromptInstanceUIPreference()
APR.settings.profile = profile
local database = APR.settings.db
APR.settings.db = nil
APR:MaybePromptInstanceUIPreference()
APR.settings.db = database
local data = APRData
APRData = nil
assert(not APR:IsInstanceWithUI())
APR:MaybePromptInstanceUIPreference()
APRData = data
assert(not secondCharacter.instanceUiPromptShown and #state.prompts == prompts)
local main, fillers, order = APR.currentStep, APR.fillersFrame, APR.questOrderList
local remainingRefreshes = 0
APR.currentStep, APR.fillersFrame = nil, nil
APR.questOrderList = { RefreshFrameAnchor = function() remainingRefreshes = remainingRefreshes + 1 end }
APR:RefreshInstanceUIVisibility()
assert(remainingRefreshes == 1, "Absent optional panels cannot suppress a remaining owner's refresh")
APR.currentStep, APR.fillersFrame, APR.questOrderList = main, fillers, order

local recorded = { { stepID = 61, criteriaID = 71, criteriaIndex = 1 },
    { stepID = 61, criteriaID = 72, criteriaIndex = 2 } }
assert(APR:ContainsScenarioStepCriteria(recorded, 61, 71, 1))
assert(not APR:ContainsScenarioStepCriteria(recorded, 62, 71, 1))
assert(not APR:ContainsScenarioStepCriteria(recorded, 61, 72, 1))
assert(not APR:ContainsScenarioStepCriteria(recorded, 61, 71, 2))
assert(not APR:ContainsScenarioStepCriteria(nil, 61, 71, 1))
print("Instance UI: native instance states, real panels/events/prompts, character receipts, overrides, settings, combat and missing optional data passed")
