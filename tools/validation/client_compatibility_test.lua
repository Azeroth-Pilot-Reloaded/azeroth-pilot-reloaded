-- Client filtering is hard visibility, regardless of otherwise valid level conditions.
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
APR = { RouteQuestStepList = {}, interfaceVersion = 16001, Faction = "Horde" }
function APR:NewModule() return {} end
function APR:IsDelveRoute() return false end
function UnitLevel() return 12 end
function tContains(values, value)
    for _, entry in ipairs(values) do if entry == value then return true end end
    return false
end
C_Map = { GetBestMapForUnit = function() return 1411 end }
dofile("APR-Core/utils/PlayerUtils.lua")
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/data/models/Classes.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/utils/RouteManager.lua")

-- GetBuildInfo returns fields after the interface number as well. The fallback
-- must pass only that number to tonumber, including during file loading.
GetBuildInfo = function() return "12.1.0", "build", "date", "120105", "extra" end
APR.interfaceVersion = nil
assert(APR:GetGameVersion() == "retail")
assert(APR:IsInterfaceVersion(120105))
assert(APR:IsInterfaceVersion(120100))
assert(not APR:IsInterfaceVersion(120106))
assert(not APR:IsInterfaceVersion("invalid"))
assert(APR:IsExactInterfaceVersion(120105))
assert(not APR:IsExactInterfaceVersion(120100))
assert(not APR:IsExactInterfaceVersion(120106))
assert(not APR:IsExactInterfaceVersion("invalid"))
local fallbackTabs = APR:GetRouteSelectionExpansions()
assert(#fallbackTabs == #APR.EXPANSION_ORDER_KEYS - 1)
APR.interfaceVersion = 16001
APR.RouteQuestStepList.retail = { label = "Retail", expansion = APR.EXPANSIONS.Vanilla, conditions = { Level = 10 } }
APR.RouteQuestStepList.forever = { label = "Forever", expansion = APR.EXPANSIONS.Forever, conditions = { Level = 10 } }
APR.RouteQuestStepList.saved = { label = "Saved", expansion = APR.EXPANSIONS.Custom, gameVersion = "retail" }
APR.RouteQuestStepList.shared = { label = "Shared", expansion = APR.EXPANSIONS.Custom }
APR.RouteQuestStepList.versioned = { label = "Versioned", expansion = APR.EXPANSIONS.Vanilla,
    conditions = { Level = 10, InterfaceVersion = 120100 } }
APR.RouteQuestStepList.exactVersioned = { label = "Exact versioned", expansion = APR.EXPANSIONS.Vanilla,
    conditions = { Level = 10, InterfaceVersionExact = 120105 } }
assert(APR:GetGameVersion() == "forever")
local tabs = APR:GetRouteSelectionExpansions()
assert(#tabs == 2 and tabs[1] == APR.EXPANSIONS.Forever and tabs[2] == APR.EXPANSIONS.Custom)
assert(APR:GetRouteVisibility("retail") == "hidden")
assert(APR:GetRouteVisibility("saved") == "hidden")
assert(APR:GetRouteVisibility("forever") == "visible")
assert(APR:GetRouteVisibility("shared") == "visible")
assert(APR:GetRouteData("retail") == nil)
assert(not APR:IsRequiredRouteApplicable("retail"))
APR.RouteQuestStepList.forever.conditions.Level = 20
assert(APR:GetRouteVisibility("forever") == "disabled", "Compatible routes still obey soft level locks")
APR.interfaceVersion = 120105
tabs = APR:GetRouteSelectionExpansions()
assert(#tabs == #APR.EXPANSION_ORDER_KEYS - 1)
for _, tab in ipairs(tabs) do assert(tab ~= APR.EXPANSIONS.Forever) end
assert(APR:GetRouteVisibility("retail") == "visible")
assert(APR:GetRouteVisibility("forever") == "hidden", "Client mismatch must not become a level lock")
assert(APR:GetRouteVisibility("saved") == "visible")
assert(APR:GetRouteVisibility("versioned") == "visible")
assert(APR:GetRouteVisibility("exactVersioned") == "visible")
assert(APR:AreConditionalFiltersMet({ InterfaceVersionExact = 120105 }))
assert(not APR:AreConditionalFiltersMet({ InterfaceVersionExact = 120106 }))
APR.RouteQuestStepList.versioned.conditions.InterfaceVersion = 120106
assert(APR:GetRouteVisibility("versioned") == "hidden")
APR.interfaceVersion = 120106
assert(APR:GetRouteVisibility("versioned") == "visible")
assert(APR:GetRouteVisibility("exactVersioned") == "hidden")
assert(not APR:AreConditionalFiltersMet({ InterfaceVersionExact = 120105 }))
APR.interfaceVersion = 11508
assert(APR:GetRouteVisibility("retail") == "hidden")
assert(APR:GetRouteVisibility("forever") == "hidden")
APR.interfaceVersion = 16001
assert(APR:GetPlayerMaxLevel() == 60)
assert(APR:GetClassSpecName() == nil)
assert(APR:IsPetBattleActive() == false)
assert(APR:HasAchievement(1) == false)
assert(APR:IsRemixCharacter() == false)
GetMaxLevelForPlayerExpansion = function() return 70 end
assert(APR:GetPlayerMaxLevel() == 70)
C_PetBattles = { IsInBattle = function() return true end }
assert(APR:IsPetBattleActive())
C_UnitAuras = { GetPlayerAuraBySpellID = function(id) if id == 1232454 then return {} end end }
assert(APR:IsRemixCharacter())

-- Saved route client metadata survives the existing import path.
APRData = { CustomRoute = { Imported = { label = "Imported", gameVersion = "forever", steps = {} } } }
APR:LoadCustomRoutes()
assert(APR.RouteQuestStepList.Imported.gameVersion == "forever")

-- Popup options must omit incompatible expansions, including unavailable placeholders.
APR.routeconfig = {}
APR.Level = 12
tinsert = table.insert
dofile("APR-Core/config/Config_Route_Prefabs.lua")
local popupOptions
APR.questionDialog = { CreateSelectionPopup = function(_, _, _, options) popupOptions = options end }
APR.routeconfig:OpenLevelingPopup()
assert(#popupOptions == 1 and popupOptions[1].key == APR.EXPANSIONS.Forever)
APR.routeconfig:GetPlayerSpecRoute("Starter") -- no specialization API on Forever
APR.interfaceVersion = 120105
APR.routeconfig:OpenLevelingPopup()
assert(#popupOptions > 1)
for _, option in ipairs(popupOptions) do assert(option.key ~= APR.EXPANSIONS.Forever) end
APR.interfaceVersion = 16001

-- Unknown events never prevent shared quest events from registering.
local registered = {}
function CreateFrame()
    return {
        RegisterEvent = function(_, event)
            if event == "ACTIVE_DELVE_DATA_UPDATE" then error("Unknown event") end
            registered[event] = true
        end,
        SetScript = function() end,
    }
end
C_EventUtils = { IsEventValid = function(event) return event ~= "ACTIVE_DELVE_DATA_UPDATE" end }
dofile("APR-Core/core/Event.lua")
APR.event:MyRegisterEvent()
assert(registered.QUEST_ACCEPTED and registered.QUEST_LOG_UPDATE)
assert(not registered.ACTIVE_DELVE_DATA_UPDATE)
C_EventUtils = nil
APR.event:MyRegisterEvent()
assert(registered.HEARTHSTONE_BOUND)
print("Client compatibility: visibility, saved routes, API fallbacks and event registration passed")
