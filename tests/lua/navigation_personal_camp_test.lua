local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.spells[312372] = true
fixture.player = { x = 100, y = 200, z = 0, instanceID = 0 }
function UnitRace() return "Vulpera", "Vulpera", 35 end
APRNavigationCharacterSettings = nil
-- These spell IDs are client event contracts; the connection is synthetic.
local data = fixture:Load({ connections = { { id = "fixture-camp", kind = "spell",
    from = { dynamic = "player" }, to = { dynamic = "camp" },
    actions = { { type = "spell", id = 312372 } }, requirements = { raceID = 35 },
} } })
local function Edges() return data:BuildEdges({ playerPosition = fixture.player }) end
local edges, metadata = Edges()
assert(#edges == 0 and not metadata.waitingData, "An unobserved personal camp is an unavailable optional shortcut")
local adapter = APR.NavigationAdapter
adapter.frame.OnEvent(nil, "UNIT_SPELLCAST_SUCCEEDED", "party1", nil, 312370)
assert(not adapter:GetCharacterSettings().campLocation, "Another player's camp must never become this character's destination")
fixture.player = { x = 123, y = 456, z = 12, instanceID = 0 }
adapter.frame.OnEvent(nil, "UNIT_SPELLCAST_SUCCEEDED", "player", nil, 312370)
fixture.player.x = 999
edges = Edges()
assert(#edges == 1 and edges[1].to.x == 123 and edges[1].to.y == 456 and edges[1].to.z == 12,
    "Only the successful camp cast fixes the destination, detached from later player movement")
assert(edges[1].action.data == 312372)
fixture.spells[312372] = nil
assert(#Edges() == 0, "Learning, cooldown and usability remain authoritative after a camp is observed")
print("Personal camp: unknown destination, other-player rejection, successful observation, detached position and action usability passed")
