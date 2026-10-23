-- Load the real entrance catalogue without replacing an APR suite's AceLocale
-- mock or APR object. Client observations stay in that suite's environment.
return function(profile)
    local globals = { assert = assert, error = error, ipairs = ipairs, pairs = pairs, next = next,
        type = type, tonumber = tonumber, tostring = tostring, select = select, pcall = pcall,
        unpack = unpack, rawget = rawget, rawset = rawset, setmetatable = setmetatable,
        getmetatable = getmetatable, math = math, string = string, table = table, strmatch = string.match }
    globals._G = globals
    local function load(path)
        local chunk = assert(loadfile(path)); setfenv(chunk, globals); return chunk()
    end
    load("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
    local root = "APR-Core/libs/LibAPRNavigation-1.0/"
    local file = assert(io.open(root .. "LibAPRNavigation.xml"))
    local xml = file:read("*a"); file:close()
    for path in xml:gmatch('file="([^"]+)"') do load(root .. path) end
    local environment = {
        getMapInfo = function(id)
            local observed = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
            if observed and observed.mapType and observed.parentMapID then return observed end
            return { mapID = id, mapType = id == 13 and 2 or 3, parentMapID = id == 13 and 947 or 13 }
        end,
        mapToWorld = function(id, x, y)
            if not C_Map or not C_Map.GetWorldPosFromMapPos then return nil end
            local world, point = C_Map.GetWorldPosFromMapPos(id, { x = x, y = y })
            if point then return world, point.x, point.y end
        end,
        getCharacter = function()
            return { faction = APR.Faction or "Alliance", level = UnitLevel and UnitLevel() or 90,
                mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"),
                indoors = false, inInstance = false }
        end,
        isQuestCompleted = function(id) return C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted(id) end,
        isQuestActive = function(id) return C_QuestLog and C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(id) end,
    }
    local data = globals.LibStub("LibAPRNavigation-1.0"):New({ profile = profile or "retail", environment = environment })
    APR.NavigationData = data
    return data
end
