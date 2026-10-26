-- Small invented action families; item/spell IDs belong to these fixtures.
local function inn(actions, random)
    -- GetHearthstoneAction uses this technical dispatch ID as its API contract.
    return { id = "item-hearthstone-alternatives", routeAction = "UseHS", kind = "item", from = { dynamic = "player" },
        to = { dynamic = "bind" }, actions = actions, selection = random and "random" or nil,
        cooldownGroup = "hearthstone" }
end
return {
    retail = { connections = {
        inn({ { type = "item", id = 1, useSpellID = 11 }, { type = "item", id = 2, useSpellID = 12 },
            { type = "item", id = 3, useSpellID = 13 },
            { type = "item", id = 8 },
            { type = "item", id = 4, useSpellID = 14, requirements = { raceID = 11 } } }, true),
        { id = "fixture-fixed-a", routeAction = "UseDalaHS", kind = "item", from = { dynamic = "player" },
            to = { instanceID = 0, uiMapID = 101, x = 100, y = 0 }, actions = { { type = "item", id = 5, useSpellID = 15 } } },
        { id = "fixture-fixed-b", routeAction = "UseGarrisonHS", kind = "item", from = { dynamic = "player" },
            to = { instanceID = 0, uiMapID = 102, x = 200, y = 0 }, actions = { { type = "item", id = 6, useSpellID = 16 } } },
        { id = "fixture-recall", kind = "spell", from = { dynamic = "player" }, to = { dynamic = "bind" },
            actions = { { type = "spell", id = 7 } } },
    } },
    forever = { connections = { inn({ { type = "item", id = 1, useSpellID = 11 } }) } },
}
