-- Native pet-battle events reach the real panel owners and preserve live content.
-- Stateful native widgets reject protected mutations; routes/quests are invented.
local env = dofile("tests/lua/addon_journey_quest_env.lua")
local state = { pet = false, grouped = false, sent = {}, frames = {}, registrations = 0, timers = 0 }
function IsInGroup(category) return state.grouped and category == nil end
function IsInRaid() return false end
function UnitName(unit)
    if unit == "player" then return "Local", "Realm" end
    if unit == "party1" then return "Peer", "Realm" end
end
function GetNormalizedRealmName() return "Realm" end
function UnitPosition() return 0, 0, 0, 1 end
function GetPlayerFacing() return 0 end
function PlayerHasToy() return false end
C_PetBattles = { IsInBattle = function() return state.pet end }
C_Heirloom = {GetHeirloomItemIDs = function() return {880001} end,
    PlayerHasHeirloom = function(id) return id == 880001 end}
C_ToyBox = {}
C_ChatInfo = { SendAddonMessage = function(prefix, payload, channel)
    state.sent[#state.sent + 1] = { prefix, payload, channel }
    return true
end }
C_Spell = { GetSpellInfo = function(id) return { name = "Synthetic spell " .. id, iconID = 123 } end }
C_UnitAuras = { GetPlayerAuraBySpellID = function(id)
    if id == 8802 then return { auraInstanceID = state.auraID or 71, icon = 123 } end
end }
Enum = Enum or {}
Enum.UIMapType = { Zone = 3 }
C_Map.GetMapInfo = function(id) return { mapID = id, name = "Synthetic map", mapType = 3, parentMapID = 0 } end
APR.Username, APR.navigation = "Local-Realm", nil
APRSecret:Attach(APR)
APR.Color.white, APR.Color.midGray = { 1, 1, 1 }, { .5, .5, .5 }
APR.Color.defaultLightBackdrop = { .1, .1, .1, 1 }
APR.settings.db = { char = { instanceUiPromptShown = true } }

-- Use the actual serializer and group presentation, not the journey's group sink.
local originalLibStub = LibStub
strmatch = string.match
LibStub = nil
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
dofile("APR-Core/libs/AceSerializer-3.0/AceSerializer-3.0.lua")
local serializer = LibStub("AceSerializer-3.0")
function LibStub(name, ...)
    if name == "AceSerializer-3.0" then return serializer end
    return originalLibStub(name, ...)
end

local nativeCreateFrame, register = CreateFrame, env.methods.RegisterEvent
function env.methods:RegisterEvent(event)
    state.registrations = state.registrations + 1
    register(self, event)
end
function env.methods:UnregisterEvent(event) if self.events then self.events[event] = nil end end
function CreateFrame(kind, name, parent, template)
    local frame = nativeCreateFrame(kind, name, parent, template)
    state.frames[#state.frames + 1] = frame
    if template == "ObjectiveTrackerContainerHeaderTemplate" then
        frame.Text, frame.MinimizeButton = frame:CreateFontString(), env.widget(frame)
        frame.MinimizeButton:SetNormalTexture("native collapse")
        frame.MinimizeButton:SetPushedTexture("native pressed")
    elseif template == "UIPanelButtonTemplate,BackdropTemplate" then
        frame.Left, frame.Middle, frame.Right = env.widget(frame), env.widget(frame), env.widget(frame)
        frame:SetNormalTexture("native button")
        frame:SetHighlightTexture("native highlight")
    end
    return frame
end
local nativeNewTimer = C_Timer.NewTimer
function C_Timer.NewTimer(delay, callback)
    state.timers = state.timers + 1
    return nativeNewTimer(delay, callback)
end
dofile("APR-Core/utils/ProfileUtils.lua")
dofile("APR-Core/utils/InstanceUtils.lua")
dofile("APR-Core/utils/NavigationZones.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/features/group/PartyProtocol.lua")
dofile("APR-Core/features/group/Party.lua")
dofile("APR-Core/ui/route/QuestOrderListSupport.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/ui/route/QuestOrderList.lua")
dofile("APR-Core/ui/route/QuestOrderListRows.lua")
dofile("APR-Core/features/player/Heirloom.lua")
dofile("APR-Core/features/player/Buff.lua")
dofile("APR-Core/ui/route/RouteSelection.lua")
dofile("APR-Core/features/navigation/Arrow.lua")

local profile, current = APR.settings.profile, APR.currentStep
profile.showQuestOrderList, profile.questOrderListSnapToCurrentStep = true, false
profile.questOrderListScale, profile.questOrderListFrame = 1, {}
profile.questOrderListbackgroundColorAlpha = { 0, 0, 0, 1 }
profile.showGroup, profile.receiveGroupData, profile.groupScale, profile.groupFrame = true, true, 1, {}
profile.heirloomWarning, profile.showArrow, profile.arrowFPS = false, true, 5
profile.heirloomFrame, profile.buffFrame, profile.arrowScale = {}, {}, 1
APR.RouteQuestStepList = { pet = { label = "Synthetic pet-event guide", mapID = 10, expansion = APR.EXPANSIONS.Custom,
    steps = { { Qpart = { [8801] = { 1 } }, Coord = { x = 300, y = 400 },
            Buffs = { { spellId = 8802, tooltipMessage = "Synthetic tracked buff" } } },
        { Note = "Synthetic next instruction" } } } }
APRData.player.pet, APRCustomPath.player, APR.ActiveRoute = 1, { "Synthetic pet-event guide" }, "pet"
function APR.routeconfig:HasRouteInCustomPath(label)
    label = label or (APR.RouteQuestStepList[APR.ActiveRoute] or {}).label
    for _, entry in ipairs(APRCustomPath[APR.PlayerID] or {}) do if entry == label then return true end end
    return false
end
H.quest(8801, "Gather 0/3")

local function drain()
    for _ = 1, 120 do
        local work = false
        for _, owner in ipairs({ APR.questOrderList, APR.questOrderList.virtualList }) do
            local frame = owner.renderFrame
            if frame and frame.scripts.OnUpdate then frame.scripts.OnUpdate(); work = true end
        end
        if #H.timers > 0 then H.frame(.2); work = true end
        if not work then return end
    end
    error("Pet-event integration left recurring UI/timer work")
end
local function dispatch(event, ...)
    H.emit(event, ...)
    -- These are real panel-owned native watchers, separate from Event's pool.
    local count = #state.frames
    for index = 1, count do
        local frame = state.frames[index]
        if frame.events and frame.events[event] and frame.scripts.OnEvent then
            frame.scripts.OnEvent(frame, event, ...)
        end
    end
    assert(#H.errors == 0, table.concat(H.errors, "\n"))
end
local function visibility(main, ordinary, heirloom)
    assert(CurrentStepScreenPanel:IsShown() == main, "Current-step visibility")
    assert(PartyScreenPanel:IsShown() == ordinary, "Group-progress visibility")
    assert(QuestOrderListPanel:IsShown() == ordinary, "Route-order visibility")
    assert(HeirloomPanel:IsShown() == heirloom, "Heirloom visibility")
    assert(BuffFrameScreen:IsShown() == ordinary, "Tracked-buff visibility")
    assert(APR.ArrowFrame:IsShown() == ordinary, "Arrow reacts to the same native event")
end
local function listenerCount(event)
    local count = 0
    for _, frame in pairs(APR.event.framePool) do
        if frame.events and frame.events[event] then count = count + 1 end
    end
    return count
end
local function assertProgress()
    assert(APR.ActiveRoute == "pet" and APRData.player.pet == 1,
        "Visibility events must not complete, skip or deactivate the route")
end

APR:UpdateQuestAndStep()
APR.heirloom:RefreshFrameAnchor()
APR.Arrow:SetArrowActive(true, 300, 400)
state.grouped = true
local peer = { username = "Peer-Realm", routeFileName = "pet", route = "Synthetic pet-event guide",
    currentStep = 1, totalSteps = 2, stepFrameDetails = { questSteps = { { text = "Peer 0/3" } } } }
APR.party.GroupListSteps[peer.username] = peer
APR.party:UpdateTeamMate(peer, "In sync", "success", false)
APR.party:ReOrderTeam()
APR.currentStep:RefreshCurrentStepFrameAnchor()
drain()
local row, peerRow, buff = current.questsList["8801-1"], APR.party.teamList[peer.username], APR.Buff.auras[1]
assert(row and row.font:GetText():find("Gather 0/3", 1, true), "Actual quest renderer supplies current content")
assert(peerRow.fontName:GetText():find("Peer", 1, true) and peerRow.fontIndex:GetText() == "1")
assert(buff.auraId == 71 and #APR.heirloom.buttons > 0)
local heirloomButton = APR.heirloom.buttons[1]
local function assertOrderContent()
    local list = APR.questOrderList
    assert(list.renderComplete and list.currentRouteKey == "pet" and list.currentStepIndex == 1)
    assert(#list.stepList == 2 and list.stepList[1].rawIndex == 1 and list.stepList[1].isActiveStep,
        "The actual order renderer publishes the current synthetic objective")
    assert(list.stepList[2].stepText:find("Synthetic next instruction", 1, true),
        "Restored order content contains the independently authored next instruction")
end
visibility(true, true, true)
assertOrderContent()
assert(listenerCount("PET_BATTLE_OPENING_START") == 1 and listenerCount("PET_BATTLE_CLOSE") == 1,
    "Both pet events must have exactly one production dispatcher")

state.pet = true
dispatch("PET_BATTLE_OPENING_START")
visibility(false, false, false)
assertProgress()
assert(current.questsList["8801-1"] == row and APR.party.teamList[peer.username] == peerRow)
drain()
local frames, fonts, registrations, timers = env.frames(), env.fonts(), state.registrations, state.timers
for _ = 1, 100 do dispatch("PET_BATTLE_OPENING_START") end
drain()
assert(env.frames() == frames and env.fonts() == fonts, "Opening bursts reuse all existing panel content")
assert(state.registrations == registrations and state.timers == timers,
    "Opening bursts do not install listeners, polling or deferred timer chains")
visibility(false, false, false)

-- Real quest/aura events still update the hidden owners. Close publishes the
-- current state rather than restoring an obsolete screenshot of the guide.
H.objective(8801, "Gather 2/3", false)
state.auraID = 72
dispatch("QUEST_LOG_UPDATE")
dispatch("UNIT_AURA", "player", {})
drain()
assertProgress()
assert(current.questsList["8801-1"].font:GetText():find("Gather 2/3", 1, true))
assert(APR.Buff.auras[1].auraId == 72)
state.pet = false
dispatch("PET_BATTLE_CLOSE")
visibility(true, true, true)
drain()
assert(APR.heirloom.buttons[1] == heirloomButton and APR.Buff.auras[1] == buff)
assert(APR.party.teamList[peer.username] == peerRow)
assertOrderContent()
frames, fonts, registrations, timers = env.frames(), env.fonts(), state.registrations, state.timers
for _ = 1, 100 do dispatch("PET_BATTLE_CLOSE") end
drain()
assert(env.frames() == frames and env.fonts() == fonts, "Close bursts reuse rows and icons")
assert(state.registrations == registrations and state.timers == timers,
    "Close bursts do not create recurring timers or additional listeners")
assertProgress()

-- Native capabilities and the client/profile policy remain authoritative after
-- close. An unavailable pet API is a supported false result, not a stale lock.
APR.interfaceVersion = 16000
dispatch("PET_BATTLE_CLOSE")
visibility(true, true, false)
state.pet = true
dispatch("PET_BATTLE_OPENING_START")
visibility(false, false, false)
C_PetBattles = nil
dispatch("PET_BATTLE_CLOSE")
visibility(true, true, false)
APR.interfaceVersion, state.pet = 120105, false
C_PetBattles = { IsInBattle = function() return state.pet end }
profile.heirloomWarning = true
dispatch("PET_BATTLE_CLOSE")
visibility(true, true, false)
profile.heirloomWarning = false
dispatch("PET_BATTLE_CLOSE")
drain()
visibility(true, true, true)

-- A secure action makes mutating the current-step parent in combat illegal in
-- this native boundary. The real Event and panel watchers flush deferred work.
current:AddStepButton("8801-1", 9901, "item")
assert(row.IconButton and row.IconButton.secure)
env.setCombat(true)
state.pet = true
dispatch("PET_BATTLE_OPENING_START")
visibility(true, false, true)
assert(current.pendingAnchorRefresh and APR.heirloom._pendingCombatRefresh and APR.RouteSelection.pendingRefresh)
env.setCombat(false)
dispatch("PLAYER_REGEN_ENABLED")
drain()
visibility(false, false, false)
assert(not current.pendingAnchorRefresh and not APR.heirloom._pendingCombatRefresh and not APR.RouteSelection.pendingRefresh)
env.setCombat(true)
state.pet = false
dispatch("PET_BATTLE_CLOSE")
visibility(false, true, false)
env.setCombat(false)
dispatch("PLAYER_REGEN_ENABLED")
drain()
visibility(true, true, true)
assertProgress()

-- Disabled dispatch cannot revive hidden panels. Cleanup removes the native
-- listeners; re-registration reuses Event's existing pool exactly once.
state.pet = true
dispatch("PET_BATTLE_OPENING_START")
drain()
local petFrame = APR.event.framePool.petCombatUI
assert(petFrame and petFrame.callback)
local callback = petFrame.callback
profile.enableAddon = false
state.pet = false
dispatch("PET_BATTLE_CLOSE")
visibility(false, false, false)
APR.event:OnDisable()
assert(listenerCount("PET_BATTLE_OPENING_START") == 0 and listenerCount("PET_BATTLE_CLOSE") == 0)
assert(not petFrame.scripts.OnEvent and not petFrame.callback)
APR.event.EventHandler({ tag = "petCombatUI", callback = callback }, "PET_BATTLE_CLOSE")
visibility(false, false, false)
drain()
profile.enableAddon = true
APR.event:RegisterEvents()
assert(APR.event.framePool.petCombatUI == petFrame)
assert(listenerCount("PET_BATTLE_OPENING_START") == 1 and listenerCount("PET_BATTLE_CLOSE") == 1)
dispatch("PET_BATTLE_CLOSE")
drain()
visibility(true, true, true)
assertProgress()

-- With no selected/saved route, the actual lazy route-selection card is the
-- current content. Its identity, button and empty progress policy survive pets.
APR.ActiveRoute, APRCustomPath.player = nil, {}
current:Reset()
current:RefreshCurrentStepFrameAnchor()
local card = APR.RouteSelection.frame
assert(card and card:IsShown() and card.button.scripts.OnClick and not current.progressBar:IsShown())
state.pet = true
dispatch("PET_BATTLE_OPENING_START")
assert(not CurrentStepScreenPanel:IsShown() and not card:IsShown())
state.pet = false
dispatch("PET_BATTLE_CLOSE")
assert(CurrentStepScreenPanel:IsShown() and card:IsShown() and APR.RouteSelection.frame == card)
assert(not current.progressBar:IsShown() and not APR.ArrowFrame:IsShown() and not BuffFrameScreen:IsShown())
profile.currentStepShow = false
dispatch("PET_BATTLE_CLOSE")
assert(not CurrentStepScreenPanel:IsShown() and not card:IsShown(), "Close respects the user's hidden-guide preference")
drain()
assert(#H.errors == 0 and #H.timers == 0, "The integration finishes without failed callbacks or pending timer chains")
