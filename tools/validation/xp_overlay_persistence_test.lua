local function noop() end
local L = setmetatable({ USE_ITEM = "Use %s" }, { __index = function(_, key) return key end })
function LibStub() return setmetatable({ GetLocale = function() return L end }, { __index = function() return noop end }) end
APR = { RegisterFontString = noop, Debug = noop, version = "new", PlayerID = "player" }
function APR:NewModule() return {} end
dofile("APR-Core/utils/Utils.lua")
assert(APR:NormalizeSearchText("TRÉSOR à côté") == "tresor a cote")
assert(APR:NormalizeSearchText("Tre\204\129sor") == "tresor")
assert(APR:NormalizeSearchText("Œuf Æther ÇA") == "oeuf aether ca")
assert(APR:NormalizeSearchText("宝藏") == "宝藏")
assert(APR:NormalizeSearchText("trésor [1]"):find(APR:NormalizeSearchText("tresor [1]"), 1, true))

local auras, bags, unusable = {}, {}, {}
local level, combat, desired, active, pet = 87, false, false, false, false
function UnitLevel() return level end
function GetMaxLevelForPlayerExpansion() return 90 end
function InCombatLockdown() return combat end
function APR:HasAura(id) return auras[id] ~= nil end
C_PvP = { IsWarModeActive = function() return active end, IsWarModeDesired = function() return desired end }
C_PetBattles = { IsInBattle = function() return pet end }
C_Item = {
    GetItemCount = function(id, bank, uses, reagent, warband)
        assert(not bank and not uses and not reagent and not warband)
        return bags[id] or 0
    end,
    IsUsableItem = function(id) return not unusable[id] end,
    GetItemInfo = function(id) return "Item " .. id end,
    GetItemIconByID = function(id) return id end,
}
dofile("APR-Core/config/LevelProfiles.lua")
dofile("APR-Core/utils/RouteUtils.lua")
bags[239142], bags[93730], bags[171364] = 1, 1, 1
assert(#APR:GetLevelConsumableReminders() == 2, "Global list deduplicates alternative items")
auras[1221184], auras[46668] = {}, {}
assert(#APR:GetLevelConsumableReminders() == 0, "Any active aura variant suppresses its reminder")
auras = {}
unusable[239142] = true
assert(#APR:GetLevelConsumableReminders() == 1)
unusable = {}
level = 90
assert(#APR:GetLevelConsumableReminders() == 0)
level = 87

-- Model actual parent/child visibility and reject protected layout updates in combat.
local frames, timers = {}, {}
local methods = {}
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:SetAttribute(key, value) assert(not combat); self.attributes[key] = value end
function methods:Show() assert(not combat); self.shown = true end
function methods:Hide() assert(not combat); self.shown = false end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetText(value) self.text = value end
function methods:IsShown() return self.shown and (not rawget(self, "parent") or self.parent:IsShown()) end
local function object(parent)
    return setmetatable({ parent = parent, shown = true, scripts = {}, attributes = {} },
        { __index = function(_, key) return methods[key] or noop end })
end
function methods:CreateTexture() return object(self) end
function methods:CreateFontString() return object(self) end
function methods:GetNormalTexture()
    if not rawget(self, "normal") then self.normal = object(self) end
    return self.normal
end
function methods:GetPushedTexture()
    if not rawget(self, "pushed") then self.pushed = object(self) end
    return self.pushed
end
function CreateFrame(_, name, parent, template)
    local frame = object(parent)
    frame.template = template
    if template == "ObjectiveTrackerContainerHeaderTemplate" then
        frame.Text = object(frame)
        frame.MinimizeButton = object(frame)
    end
    frames[#frames + 1] = frame
    if name then _G[name] = frame end
    return frame
end
UIParent = object()
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
local function drain()
    while #timers > 0 do table.remove(timers, 1)() end
end
local function visibleRows()
    local count = 0
    for _, frame in ipairs(frames) do
        if rawget(frame, "label") and frame:IsShown() then count = count + 1 end
    end
    return count
end
APR.settings = { profile = { enableAddon = true, xpBuffFrame = {}, currentStepbackgroundColorAlpha = { 0, 0, 0, 0.5 } } }
dofile("APR-Core/utils/UIUtils.lua")
dofile("APR-Core/features/player/XPBuffOverlay.lua")
APR.XPBuffOverlay:Refresh()
assert(visibleRows() == 3, "Without a route: War Mode and two missing item buffs")
assert(APRXPBuffOverlay.Header.template == "ObjectiveTrackerContainerHeaderTemplate",
    "The overlay uses the same header as the other APR windows")
APRXPBuffOverlay.Header.MinimizeButton.scripts.OnClick()
assert(APR.settings.profile.showXPBuffOverlay == false and visibleRows() == 0)
APR.XPBuffOverlay:QueueRefresh()
drain()
assert(visibleRows() == 0, "Closing the overlay survives subsequent aura/bag events")
APR.settings.profile.showXPBuffOverlay = true
APR.XPBuffOverlay:Refresh()
local function DismissBonus(sourceName)
    for _, row in ipairs(frames) do
        if rawget(row, "bonusSource") == sourceName and row:IsShown() then
            row.dismissButton.scripts.OnClick()
            return
        end
    end
    error("Missing visible reminder: " .. sourceName)
end
DismissBonus("WarMode")
assert(visibleRows() == 2 and not APR.XPBuffOverlay:IsBonusEnabled("WarMode"),
    "War Mode can be ignored without hiding usable item bonuses")
DismissBonus("Darkmoon")
bags[93730] = 0
APR.XPBuffOverlay:Refresh()
assert(visibleRows() == 1, "Changing to the alternate hat cannot revive a dismissed bonus")
DismissBonus("MysteriousWisdom")
assert(visibleRows() == 0 and not APRXPBuffOverlay:IsShown(), "No empty panel when all reminders are hidden")
local restoredPreferences = {}
for name, hidden in pairs(APR.settings.profile.hiddenXPBonuses) do restoredPreferences[name] = hidden end
APR.settings.profile.hiddenXPBonuses = restoredPreferences
APR.XPBuffOverlay:Refresh()
assert(visibleRows() == 0, "Restoring persisted preferences keeps unwanted bonuses hidden")
assert(#APR:GetLevelConsumableReminders() == 2, "UI preferences do not alter the underlying bonus sources")
bags[93730] = 1
APR.XPBuffOverlay:SetBonusEnabled("WarMode", true)
APR.XPBuffOverlay:SetBonusEnabled("Darkmoon", true)
APR.XPBuffOverlay:SetBonusEnabled("MysteriousWisdom", true)
assert(visibleRows() == 3, "Options restore individual reminders without reloading")
C_Spell = { GetSpellInfo = function(id) return { name = "Spell " .. id } end }
local options = APR.XPBuffOverlay:GetBonusOptions()
assert(options.WarMode and options.Darkmoon and options.MysteriousWisdom and options.TenLands)
assert(not options.Timeways, "Only actionable reminders appear in the selection")
for _, frame in ipairs(frames) do
    if frame.template == "SecureActionButtonTemplate" then
        assert(frame.attributes.type == "item" and frame.attributes.item:match("^item:%d+$"))
    end
end
local allocated = #frames
auras[1221184], auras[136583], desired = {}, {}, true
APR.XPBuffOverlay:Refresh()
assert(visibleRows() == 0 and not APRXPBuffOverlay:IsShown(), "Buff gain removes the label and button together")
auras = {}
APR.XPBuffOverlay:Refresh()
assert(visibleRows() == 2 and #frames == allocated, "Expiry reuses existing secure buttons")
combat = true
auras[1221184] = {}
APR.XPBuffOverlay:QueueRefresh()
drain()
assert(visibleRows() == 2, "Combat defers protected layout changes")
combat = false
frames[1].scripts.OnEvent(frames[1], "PLAYER_REGEN_ENABLED")
drain()
assert(visibleRows() == 1, "Leaving combat refreshes from current state")
for _ = 1, 100 do APR.XPBuffOverlay:QueueRefresh() end
assert(#timers == 1, "Aura/bag bursts coalesce")
drain()
APR.settings.profile.showXPBuffOverlay = false
APR.XPBuffOverlay:Refresh()
assert(visibleRows() == 0)
APR.settings.profile.showXPBuffOverlay = true
pet = true
APR.XPBuffOverlay:Refresh()
assert(visibleRows() == 0)
pet, bags = false, {}
APR.XPBuffOverlay:Refresh()
assert(visibleRows() == 0, "No acquisition message for absent bag items")

auras, bags = {}, { [239142] = 1 }
APR.XPBuffOverlay:Refresh()
assert(visibleRows() == 1)
combat = true
DismissBonus("MysteriousWisdom")
assert(visibleRows() == 1 and not APR.XPBuffOverlay:IsBonusEnabled("MysteriousWisdom"),
    "Dismissing during combat saves the preference without touching protected layout")
combat = false
frames[1].scripts.OnEvent(frames[1], "PLAYER_REGEN_ENABLED")
drain()
assert(visibleRows() == 0, "Combat-end refresh applies the saved dismissal")

-- A scenario's runtime navigation remains shared with the arrow, not the definition.
APR.RouteQuestStepList = { route = { label = "Route", steps = { { DoScenario = { mapID = 1 }, Coord = { x = 1 } }, {} } } }
APR.ActiveRoute = "route"
function APR:GetRouteSteps(key) return self.RouteQuestStepList[key].steps end
function APR:GetRouteData(key) return self.RouteQuestStepList[key] end
dofile("APR-Core/utils/StepUtils.lua")
local runtime = APR:GetStep(1)
runtime.Coord, runtime.NoArrow = nil, true
assert(APR:GetStep(1) == runtime, "Arrow and event handlers see the same runtime navigation")
assert(APR.RouteQuestStepList.route.steps[1].Coord.x == 1 and not APR.RouteQuestStepList.route.steps[1].NoArrow)
APR:GetStep(2)
assert(APR:GetStep(1).Coord.x == 1, "Returning to a step starts from its definition")

assert(not APR:AreConditionalFiltersMet({ WarMode = 1 }), "Legacy War Mode slots are hidden from the guide")
local advanced = false
function APR:UpdateNextStep() advanced = true end
APRData = { player = { route = 1 } }
assert(APR:SkipStepCondition({ WarMode = 1 }) and advanced, "Missing War Mode never blocks progression")

-- Migration and ordinary reconnect preserve progress and activated parallel groups.
APRData = { player = { route = 2, ["route-RawTotalSteps"] = 2,
    ["route-ParallelStepsState"] = { groups = { [1] = { activationOrder = 1 } } } } }
APRCustomPath = { player = { "Route" } }
APRZoneCompleted = { player = {} }
APR.settings.profile.routeSignatures = { route = "another-character" }
APR.settings.profile.lastRecordedVersion = "old"
function APR:GetRouteSignature() return "definition-v1" end
function APR:GetRouteDisplayName() return "Route" end
function APR:GetRouteMapIDsAndName() return nil, nil, "route" end
APR.questionDialog = { CreateMessagePopup = noop }
APR:CheckCurrentRouteUpToDate("route")
assert(APRData.player.route == 2 and APRData.player["route-ParallelStepsState"].groups[1])
assert(APRData.player.RouteSignatures.route == "definition-v1")
APR.settings.profile.routeSignatures.route = "other-character-again"
APR:CheckCurrentRouteUpToDate("route")
assert(APRData.player.route == 2, "Shared profile changes never invalidate this character's progress")
function APR:GetRouteSignature() return "definition-v2" end
APR:CheckCurrentRouteUpToDate("route")
assert(APRData.player.route == nil, "A real definition change still invalidates outdated indexes")
assert(APRData.player["route-ParallelStepsState"] == nil)
print("PASS: accent search, global XP overlay, persistent bonus dismissal, aura variants, secure buttons, combat deferral and reconnect persistence")
