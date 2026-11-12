-- The reusable service API runs with no APR, frames, client globals or SavedVariables.
local library = dofile("tests/lua/navigation_engine_fixture.lua")
function LibStub() return library end
dofile("APR-Core/libs/LibAPRNavigation-1.0/Services.lua")
APR, APRData = nil, nil
local character = {faction = "Horde", class = "PRIEST"}
local nav = setmetatable({profile = "forever", env = {}, serviceLocations = {
    {service = "inn", npcID = 21, name = "Nearby but locked", mapID = 3, x = 1, y = 0, faction = "H"},
    {service = "inn", npcID = 22, name = "Accessible", mapID = 1, x = 4, y = 0, faction = "H"},
    {service = "inn", npcID = 23, name = "Opposing faction", mapID = 1, x = 0, y = 0, faction = "A"},
}}, {__index = library.Instance})
function nav:GetText(key) return key end
function nav:NormalizeLocation(point)
    return {x = point.x * 100, y = point.y * 100, instanceID = 0, uiMapID = point.uiMapID}
end
function nav:CanWalk(a, b) return a.uiMapID == b.uiMapID and a.instanceID == b.instanceID end
function nav:CreateEdgeBuild()
    return {Step = function() return "ready", {}, {} end}
end
local start = {x = 0, y = 0, instanceID = 0, uiMapID = 1}
local job = nav:CreateServiceSearch({start = start, query = {service = "inn"}, character = character, walkSpeed = 2})
character.faction = "Alliance" -- Jobs own the character snapshot used for ranking.
local status, result
for _ = 1, 100 do
    status, result = job:Step(1, 1)
    if status ~= "planning" then break end
end
assert(status == "ready" and result.record.npcID == 22 and result.totalSeconds == 2)
assert(nav:IsServiceArrival({x = 4, y = 0, instanceID = 0, uiMapID = 1}, result.target))
assert(not nav:IsServiceArrival({x = 4, y = 0, instanceID = 0, uiMapID = 3}, result.target))
assert(not nav:IsServiceArrival({x = 4, y = 0, z = 20, instanceID = 0, uiMapID = 1}, {x = 4, y = 0, z = 0, instanceID = 0, uiMapID = 1}))
local missing = nav:CreateServiceSearch({start = start, query = {service = "flight"}})
assert(missing:Step() == "unavailable" and missing.reason == "taxi_unavailable")
local cancelled = nav:CreateServiceSearch({start = start, query = {service = "inn"}})
cancelled:Cancel()
assert(cancelled:Step() == "cancelled")
local empty = nav:CreateServiceSearch({start = start, query = {service = "mailbox"}})
while empty:Step(1) == "planning" do end
assert(empty.status == "no_path")
local clock = 0
local budgeted = nav:CreateServiceSearch({start = start, query = {service = "inn"},
    clock = function() clock = clock + 0.6; return clock end})
budgeted:Step(4096, 1)
assert(budgeted.status == "planning", "A shared time budget must yield before scanning all candidates")
local second = setmetatable({profile = "retail", env = {}, serviceLocations = {}}, {__index = library.Instance})
function second:GetText(key) return key end
assert(#second:GetServiceChoices() < #nav:GetServiceChoices())
assert(not second:IsServiceBranch({service = "trainer", skill = 171, expansion = 0}))
local many, builds = {}, 0
for index = 1, 700 do
    many[index] = {service = "bank", name = "Synthetic bank", mapID = 1, x = 80, y = 0}
end
many[701] = {service = "bank", name = "Fastest bank", mapID = 1, x = 1, y = 0}
nav.serviceLocations = many
function nav:CreateEdgeBuild()
    builds = builds + 1
    return {Step = function() return "ready", {}, {} end}
end
local complete = nav:CreateServiceSearch({start = start, query = {service = "bank"}, walkSpeed = 1})
complete:Step(0, 1)
assert(complete.cursor == nil and builds == 0, "A zero operation budget does no work")
complete:Step(64, 0)
assert(complete.cursor == nil and builds == 0, "A zero time budget does no work")
for _ = 1, 10000 do
    if complete:Step(32, 1) ~= "planning" then break end
end
assert(complete.status == "ready" and complete.result.record == many[701])
assert(builds == 1, "All candidates share a single transport graph and shortest-time search")
print("Reusable service search: standalone consumer, immutable character snapshot, accessibility, time ranking, arrival, cancellation and shared budget passed")
