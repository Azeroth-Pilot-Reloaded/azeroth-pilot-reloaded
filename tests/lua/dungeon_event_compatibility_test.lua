-- Loading the shared dungeon helpers on Retail must never attempt protected
-- combat-log registration, even when the event and its reader still exist.
function LibStub() return { GetLocale = function() return {} end } end
function CombatLogGetCurrentEventInfo() error("Retail must not read the combat log") end
C_EventUtils = { IsEventValid = function() return true end }
local registered, eventHandler
function CreateFrame()
    return {
        RegisterEvent = function(_, event)
            assert(event ~= "COMBAT_LOG_EVENT_UNFILTERED", "Protected registration attempted")
            registered[event] = true
        end,
        SetScript = function(_, script, handler)
            assert(script == "OnEvent")
            eventHandler = handler
        end,
    }
end

local observed, refreshed = 0, 0
APR = { ActiveRoute = "dungeon", settings = { profile = { enableAddon = true } } }
function APR:GetCurrentStep() return { Dungeon = "RFC" } end
function APR:UpdateStep() refreshed = refreshed + 1 end

-- Camelot constants can be present or absent on another client. In particular,
-- two missing project constants must not accidentally compare as Forever.
for _, project in ipairs({ { 1, 14 }, { 1 }, {} }) do
    WOW_PROJECT_ID, WOW_PROJECT_CAMELOT = project[1], project[2]
    registered = {}
    dofile("APR-Core/utils/DungeonUtils.lua")
    assert(registered.ZONE_CHANGED_NEW_AREA and registered.PLAYER_ENTERING_WORLD)
    assert(APR.ForeverDungeons.RFC and APR.RenderDungeonKill, "Shared helpers must remain available")
    function APR:ObserveDungeonLocation() observed = observed + 1 end
    eventHandler(nil, "ZONE_CHANGED_NEW_AREA")
    eventHandler(nil, "PLAYER_ENTERING_WORLD")
end
assert(observed == 6 and refreshed == 6, "Safe location events must continue refreshing dungeon steps")
