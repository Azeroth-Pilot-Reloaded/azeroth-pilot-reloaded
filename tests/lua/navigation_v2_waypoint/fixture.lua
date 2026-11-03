local F = dofile("tests/lua/navigation_v2/fixture.lua")

function F.Provider()
    local state = { creates = {}, clears = {}, pins = { foreign = {} }, tracked = true }
    local api = {}
    function api.GetUserNavigation() return state.current end
    function api.IsUserNavigationTracked() return state.tracked end
    function api.NewUserNavigation(options)
        assert(type(options) == "table", "WUI functions use dot calls")
        state.creates[#state.creates + 1] = options
        if state.reject then return nil end
        -- WUI takes percentages and returns normalized positions and copied flags.
        local current = {}
        for key, value in pairs(options) do current[key] = value end
        current.x, current.y = options.x / 100, options.y / 100
        state.current = current
        return current
    end
    function api.ClearUserNavigation(preserve, suppressAdvance)
        state.clears[#state.clears + 1] = { preserve = preserve, suppressAdvance = suppressAdvance }
        state.current = nil
    end
    function api.ClearAllPins() error("Foreign pins must never be cleared") end
    function api.ClearDestination() error("Foreign tracking must never be cleared") end
    return api, state
end

function F.Target(key)
    return { key = key or "gate", position = { mapID = 42, x = 0.23, y = 0.67 },
        title = "Enter the gate", iconTexture = "APR-icon", iconType = "TEXTURE",
        r = 0.2, g = 0.4, b = 0.8, requestRecolor = true }
end

function F.Session()
    local library = F.Load()
    assert(type(library.NewWaypointSession) == "function", "V2 must expose its optional WUI session")
    local api, state = F.Provider()
    local env = { api = api, combat = false }
    local session = assert(library.NewWaypointSession({
        getProvider = function() return env.api end,
        inCombat = function() return env.combat end,
        defaultTitle = "Map pin",
    }))
    return session, state, env
end

return F
