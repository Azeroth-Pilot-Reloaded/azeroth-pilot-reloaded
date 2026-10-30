-- Combat casts must not invalidate transport graphs or query world geometry.
local function Run(profile, nativeUnits)
    local fixture = dofile("tests/lua/navigation_fixture.lua")
    fixture.profile = profile
    local createFrame = CreateFrame
    CreateFrame = function(...)
        local frame = createFrame(...)
        if nativeUnits then
            function frame:RegisterUnitEvent(event, unit)
                self.events[event] = unit
            end
        end
        return frame
    end
    local tickerCount = 0
    C_Timer = { NewTicker = function(_, callback)
        tickerCount = tickerCount + 1
        return { callback = callback, Cancel = function(self) self.cancelled = true end }
    end }
    local connections = {
        { id = "inn-item", kind = "item", routeAction = "UseHS",
            from = { dynamic = "player" }, to = { dynamic = "bind" },
            actions = { { type = "item", id = 2001, useSpellID = 3001 } } },
        { id = "inn-recall", kind = "spell", from = { dynamic = "player" }, to = { dynamic = "bind" },
            actions = { { type = "spell", id = 3002 } } },
    }
    for index = 1, 1000 do
        connections[#connections + 1] = { id = "physical-" .. index, kind = "portal",
            from = { space = "world", instanceID = 0, uiMapID = 20, x = index, y = 0 },
            to = { space = "world", instanceID = 1, uiMapID = 21, x = index, y = 0 } }
    end
    local data = fixture:Load({ connections = connections })
    local idleTickers = tickerCount
    local adapter, env = APR.NavigationAdapter, APR.NavigationAdapter.environment
    assert(adapter.frame.events.UNIT_SPELLCAST_SUCCEEDED == (nativeUnits and "player" or true),
        "Player-only native registration has an explicit legacy fallback")
    local invalidations, geometryReads, itemReads, connectionReads = 0, 0, 0, 0
    APR.navigation = { ForceRefresh = function() invalidations = invalidations + 1 end }
    local mapForUnit = C_Map.GetBestMapForUnit
    C_Map.GetBestMapForUnit = function(...)
        geometryReads = geometryReads + 1
        return mapForUnit(...)
    end
    C_Map.GetMapArtID = function() geometryReads = geometryReads + 1; return 1 end
    local effect = 4001
    C_Item.GetItemSpell = function(id)
        assert(id == 2001)
        itemReads = itemReads + 1
        return "Synthetic recall", effect
    end
    for _, definition in ipairs(data.connections) do
        setmetatable(definition, { __index = function(_, key)
            if key == "routeAction" then connectionReads = connectionReads + 1 end
        end })
    end
    local function Cast(unit, spell)
        adapter.frame:OnEvent("UNIT_SPELLCAST_SUCCEEDED", unit, "synthetic-cast", spell)
    end
    for index = 1, 500 do Cast("raid1", 3001); Cast("target", index) end
    assert(invalidations == 0 and geometryReads == 0 and itemReads == 0 and connectionReads == 0,
        "Foreign combat bursts stop before catalogue, item and geometry reads even on fallback clients")
    for index = 1, 500 do Cast("player", 800000 + index) end
    assert(invalidations == 0 and geometryReads == 0 and itemReads == 0 and tickerCount == idleTickers,
        "Ordinary player casts cannot dirty the graph or create landing observers")
    local indexedReads = connectionReads
    assert(indexedReads >= 1000, "The synthetic physical catalogue was actually visited during initial indexing")
    for index = 1, 500 do Cast("player", 900000 + index) end
    assert(connectionReads == indexedReads,
        "Repeated combat casts use the indexed action subset without rescanning physical connections")
    Cast("player", 3001)
    assert(invalidations == 0 and adapter.pendingBindLanding and tickerCount == idleTickers + 1,
        "A declared hearth effect still starts the landing observer")
    local firstTicker = adapter.bindTicker
    Cast("player", 3002)
    assert(invalidations == 0 and firstTicker.cancelled and tickerCount == idleTickers + 2,
        "A learned inn recall replaces its earlier observer")
    APR._hearthstoneSelection = { id = 2001 }
    Cast("player", 4001)
    assert(invalidations == 0 and itemReads > 0 and tickerCount == idleTickers + 3,
        "A selected item's native effect remains supported")
    effect = 4002
    local before = tickerCount
    Cast("player", 4001)
    assert(tickerCount == before, "An obsolete dynamic item effect must not match cached spell data")
    Cast("player", 4002)
    assert(tickerCount == before + 1, "Late native item data is resolved again when selected")
    local originalConnections = data.connections
    originalConnections[1].actions[1].useSpellID = 3003
    assert(data:IsTravelActionSpell("UseHS", 3003) and not data:IsTravelActionSpell("UseHS", 3001),
        "The index retains live definition references rather than freezing action parameters")
    originalConnections[1].actions[1].useSpellID = 3001
    originalConnections[#originalConnections + 1] = { kind = "spell", to = { dynamic = "bind" },
        actions = { { type = "spell", id = 6001 } } }
    assert(data:IsTravelActionSpell("UseHS", 6001), "Appending an action rebuilds the structural index")
    data.connections = { { kind = "spell", routeAction = "OtherRecall", to = { dynamic = "player" },
        actions = { { type = "spell", id = 7001 } } } }
    assert(data:IsTravelActionSpell("OtherRecall", 7001) and not data:IsTravelActionSpell("UseHS", 6001),
        "Replacing the connection source cannot retain an obsolete matching action")
    data.connections = originalConnections
    local step = { kind = "action", actionType = "spell", parameters = 5001,
        _unlockStepID = "synthetic-unlock", _unlockObservationToken = 1 }
    env.watchUnlockAction(step)
    before = invalidations
    Cast("party1", 5001)
    assert(not env.isUnlockActionComplete(step) and invalidations == before)
    Cast("player", 5001)
    assert(env.isUnlockActionComplete(step) and invalidations == before,
        "A watched player action retains unlock completion")
    Cast("player", 312370)
    assert(APRNavigationCharacterSettings.campLocation.x == 100,
        "The native camp spell still records the current character's position")
    local opaque = {}
    APR.CanAccessValue = function(_, value) return not rawequal(value, opaque) end
    before = invalidations
    Cast(opaque, 3001); Cast("player", opaque)
    assert(invalidations == before, "Opaque cast payloads are rejected before comparison or indexing")
    C_Timer = nil
end

Run("retail", true)
Run("retail", false)
Run("forever", true)
Run("forever", false)
print("Navigation combat events: scoped casts, indexed action matching, live recalls and structural refresh passed")
