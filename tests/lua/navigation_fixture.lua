-- Small client surface for exercising the real owned catalogues and helpers.
local fixture = { profile = "retail", locale = "enUS", faction = "Alliance", items = {}, spells = {}, time = 1 }
local function noop() end
strmatch = string.match
function GetBuildInfo()
    local version = fixture.profile == "forever" and "1.60.1" or "12.1.0"
    local interface = fixture.interface or (fixture.profile == "forever" and 16001 or 120100)
    -- Keep a trailing string so callers cannot accidentally forward it to tonumber.
    return version, "1", "", interface, "extra"
end
function GetLocale() return fixture.locale end
function UnitFactionGroup() return fixture.faction end
function UnitRace() return "Human", "Human", 1 end
function UnitClassBase() return "Mage", 8 end
function UnitLevel() return 90 end
function GetExpansionLevel() return 11 end
function GetBindLocation() return fixture.bindName or "Elwynn Forest" end
function IsInGroup() return fixture.inGroup == true end
function IsIndoors() return false end
function IsInInstance() return false end
function PlayerHasToy() return false end
function GetSubZoneText() return "" end
function GetTime() return fixture.time end
function UnitPosition()
    local position = fixture.player or { x = 100, y = 200, z = 0, instanceID = 0 }
    return position.x, position.y, position.z, position.instanceID
end
function CreateVector2D(x, y) return { x = x, y = y } end
function CreateFrame()
    local frame = { events = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript(key, callback) self[key] = callback end
    return frame
end
function wipe(t) for k in pairs(t) do t[k] = nil end end
WOW_PROJECT_MAINLINE, WOW_PROJECT_ID = 1, 1
Enum = { UIMapType = { World = 0, Continent = 2, Zone = 3, Dungeon = 4, Micro = 5 } }
C_Item = { GetItemCount = function(id) return fixture.items[id] or 0 end }
C_Spell = { GetSpellInfo = function(id) return fixture.spellName and { name = fixture.spellName } end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return true end }
fixture.maps = {
    [947] = { mapID = 947, mapType = 0, parentMapID = 0 },
    [13] = { mapID = 13, mapType = 2, parentMapID = 947 },
    [12] = { mapID = 12, mapType = 2, parentMapID = 947 },
    [1414] = { mapID = 1414, mapType = 2, parentMapID = 947 },
    [1415] = { mapID = 1415, mapType = 2, parentMapID = 947 },
    [2395] = { mapID = 2395, mapType = 3, parentMapID = 13 },
    [2393] = { mapID = 2393, mapType = 3, parentMapID = 2395 },
    [2413] = { mapID = 2413, mapType = 3, parentMapID = 13 },
    [2405] = { mapID = 2405, mapType = 3, parentMapID = 13 },
}
C_Map = {
    GetAreaInfo = function(id) return "Area " .. id end,
    GetBestMapForUnit = function() return fixture.currentMap or 2395 end,
    GetMapInfo = function(id)
        return fixture.maps[id] or { mapID = id, mapType = 3, parentMapID = fixture.profile == "forever" and 1415 or 13, name = "Map " .. id }
    end,
    GetWorldPosFromMapPos = function(id, pos) return id == 2413 and 2694 or 0, { x = pos.x * 10000, y = pos.y * 10000 } end,
    GetMapPosFromWorldPos = function(instance) return instance == 2694 and 2413 or instance == 2771 and 2405 or 2395, {} end,
}
function fixture:Load()
    APR = {}
    function APR:GetRouteActionUsability(kind, id) return self.fixture[kind == "item" and "items" or "spells"][id] ~= nil end
    APR.fixture = self
    LibStub = nil
    dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
    local locale = LibStub:NewLibrary("AceLocale-3.0", 1)
    function locale:GetLocale() return fixture.translations or {} end
    local root = "APR-Core/libs/LibAPRNavigation-1.0/"
    local file = assert(io.open(root .. "LibAPRNavigation.xml"))
    local xml = file:read("*a"); file:close()
    for path in xml:gmatch('file="([^"]+)"') do dofile(root .. path) end
    dofile("APR-Core/features/navigation/NavigationAdapter.lua")
    return APR.NavigationData
end
return fixture
