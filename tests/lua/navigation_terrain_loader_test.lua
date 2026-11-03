-- Internal terrain sources construct only the exact indexed geometry on demand.
local root = "APR-Core/features/navigation/NavigationTerrain.lua"
local function Fixture(omitSources)
    local t = { now = 0, loads = {}, build = "12.1.5", buildNumber = "42", profile = "retail" }
    local data = { terrainDatasets = {} }
    local packs = {
        { id = "west", file = "NavigationData/fixture-west.lua", revision = 4,
            bounds = { minX = 0, maxX = 100, minY = 0, maxY = 100 } },
        { id = "east", file = "NavigationData/fixture-east.lua", revision = 7,
            bounds = { minX = 100, maxX = 200, minY = 0, maxY = 100 } },
    }
    APR = { NavigationTerrainIndex = { schema = 1, profiles = {
        retail = { builds = { ["12.1.5.42"] = true }, worlds = { [9] = { packs = packs } } },
        forever = { builds = { ["1.60.1.77"] = true }, worlds = { [3] = { packs = packs } } },
    } } }
    function APR:GetGameVersion() return t.profile end
    function GetBuildInfo() return t.build, t.buildNumber end
    function GetTime() return t.now end
    local opaque = {}
    function issecretvalue(value) return rawequal(value, opaque) end
    LibStub = setmetatable({}, { __call = function() return data end })
    local function Forbidden() error("Internal terrain sources must not use addon or combat APIs") end
    C_AddOns = { LoadAddOn = Forbidden, IsAddOnLoaded = Forbidden }
    LoadAddOn, IsAddOnLoaded, InCombatLockdown = Forbidden, Forbidden, Forbidden
    function t:Register(profile, world, pack, revision)
        data.terrainDatasets[profile] = data.terrainDatasets[profile] or {}
        local record = data.terrainDatasets[profile][world] or { packs = {} }
        data.terrainDatasets[profile][world] = record
        record.packs[pack.id] = { revision = revision or pack.revision,
            data = { format = 1, profile = profile, build = self.build .. "." .. self.buildNumber } }
    end
    function t:Factory(profile, world, pack)
        return function()
            self.loads[#self.loads + 1] = pack.id
            if self.throw then error(self.throw == true and "synthetic constructor failure" or self.throw, 0) end
            if self.reenter then
                self.reentrantState = self.loader:RequestData(profile, world, { x = 25, y = 75 })
            end
            if not self.noRegistration then self:Register(profile, world, pack, self.registrationRevision) end
        end
    end
    dofile(root)
    t.loader, t.data, t.packs, t.opaque = APR.NavigationTerrain, data, packs, opaque
    if not omitSources then
        for _, pack in ipairs(packs) do
            t.loader:RegisterSource("retail", 9, pack.id, pack.revision, t:Factory("retail", 9, pack))
            t.loader:RegisterSource("forever", 3, pack.id, pack.revision, t:Factory("forever", 3, pack))
        end
    end
    return t
end

local t = Fixture()
assert(t.loader:HasData("retail", 9) and t.loader:HasData("retail") and not t.loader:HasData("retail", 10))
assert(#t.loads == 0 and next(t.data.terrainDatasets) == nil,
    "Registering sources and checking inventory cannot construct geometry")
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready"
    and #t.loads == 1 and t.loads[1] == "west")
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready" and #t.loads == 1,
    "Matching registered terrain is reused without constructing another table")
assert(t.loader:RequestData("retail", 9, { x = 125, y = 75 }) == "ready" and t.loads[2] == "east")
assert(t.loader:RequestData("retail", 9, { x = 300, y = 75 }) == "missing" and #t.loads == 2,
    "An uncovered point cannot fabricate geometry")
t.data.terrainDatasets = {}
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready" and #t.loads == 3,
    "A source remains available when its previous registration is discarded")

t = Fixture()
assert(t.loader:RequestData("retail", 9) == "planning" and #t.loads == 1,
    "A wide request constructs at most one source per invocation")
assert(t.loader:RequestData("retail", 9) == "ready" and #t.loads == 2)
t = Fixture()
t.reenter = true
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready"
    and t.reentrantState == "planning" and #t.loads == 1,
    "A reentrant request cannot invoke the same constructor recursively")

t = Fixture()
t.throw = true
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing")
assert(t.loader.lastFailure and t.loader.lastFailure.packID == "west"
    and t.loader.lastFailure.file == "NavigationData/fixture-west.lua"
    and t.loader.lastFailure.sourceError == "synthetic constructor failure",
    "A failed internal source retains its identity and actual error for diagnostics")
t.throw, t.now = nil, 2
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready" and t.loader.lastFailure == nil,
    "Recovery clears stale failure diagnostics")

for _, failure in ipairs({ "throw", "noRegistration" }) do
    t = Fixture()
    t[failure] = true
    local status, reason = t.loader:RequestData("retail", 9, { x = 25, y = 75 })
    assert(status == "missing" and reason == (failure == "throw" and "terrain_source_failed" or "terrain_registration_missing"))
    assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing" and #t.loads == 1,
        "Failed construction is not retried every frame")
    t[failure], t.now = nil, 2
    assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready" and #t.loads == 2,
        "A transient source failure remains retryable")
end
t = Fixture()
t.throw = t.opaque
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing"
    and t.loader.lastFailure.sourceError == nil, "Opaque exceptions cannot enter diagnostic text")
t = Fixture()
t.registrationRevision = 3
local status, reason = t.loader:RequestData("retail", 9, { x = 25, y = 75 })
assert(status == "missing" and reason == "terrain_registration_missing",
    "A constructor cannot satisfy the index by registering a different revision")
t.registrationRevision, t.now = nil, 2
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready")

t = Fixture(true)
status, reason = t.loader:RequestData("retail", 9, { x = 25, y = 75 })
assert(status == "missing" and reason == "terrain_source_unavailable" and #t.loads == 0)
t.loader:RegisterSource("retail", 9, "west", 3, t:Factory("retail", 9, t.packs[1]))
status, reason = t.loader:RequestData("retail", 9, { x = 25, y = 75 })
assert(status == "missing" and reason == "terrain_source_revision_mismatch" and #t.loads == 0,
    "A factory with a different indexed revision cannot run")
assert(t.loader:RegisterSource("retail", 9, "west", 4, t:Factory("retail", 9, t.packs[1])))
assert(not t.loader:RegisterSource("retail", 9, "west", 3, function() error("old source") end)
    and not t.loader:RegisterSource("retail", 9, "west", 4, function() error("duplicate source") end))
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready" and #t.loads == 1,
    "A newer matching source replaces an older source without duplicate overrides")

t = Fixture()
t.noRegistration = true
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing")
t.noRegistration, t.packs[1].revision = nil, 5
t.loader:RegisterSource("retail", 9, "west", 5, t:Factory("retail", 9, t.packs[1]))
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready" and #t.loads == 2,
    "Replacing a failed source clears its previous retry delay")

for _, throws in ipairs({ false, true }) do
    t = Fixture(true)
    local pack = t.packs[1]
    t.loader:RegisterSource("retail", 9, pack.id, pack.revision, function()
        t.loads[#t.loads + 1] = "retired"
        t:Register("retail", 9, pack, 4)
        pack.revision = 5
        t.loader:RegisterSource("retail", 9, pack.id, 5, t:Factory("retail", 9, pack))
        if throws then error("retired constructor failed", 0) end
        assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready",
            "The replacement may complete before its retired caller returns")
    end)
    status, reason = t.loader:RequestData("retail", 9, { x = 25, y = 75 })
    assert(status == "planning" and reason == "terrain_loading"
        and next(t.loader.attempts) == nil and t.loader.lastFailure == nil,
        "A replaced constructor cannot publish success, failure or a retry delay after it returns")
    assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready" and #t.loads == 2,
        "The replacement source remains immediately available after either retired outcome")
end

t = Fixture()
for _, invalid in ipairs({ "unknown", "forever" }) do assert(t.loader:RequestData(invalid, 9) == "missing") end
t.buildNumber = "43"
assert(t.loader:RequestData("retail", 9) == "missing" and #t.loads == 0,
    "An unlisted client build cannot construct another build's geometry")
t.build = t.opaque
assert(t.loader:RequestData("retail", 9) == "missing" and #t.loads == 0,
    "Opaque client metadata cannot reach string operations")
t = Fixture()
APR.NavigationTerrainIndex = nil
assert(not t.loader:HasData("retail", 9) and t.loader:RequestData("retail", 9) == "missing")

t = Fixture()
t.profile, t.build, t.buildNumber = "forever", "1.60.1", "77"
assert(t.loader:RequestData("forever", 3, { x = 25, y = 75 }) == "ready"
    and t.data.terrainDatasets.forever[3].packs.west
    and not t.data.terrainDatasets.retail,
    "An identical pack name in another profile uses its own source and world")
t = Fixture(true)
APR.NavigationTerrainIndex.profiles.retail.worlds[10] = { packs = t.packs }
t.loader:RegisterSource("retail", 10, "west", 4, t:Factory("retail", 10, t.packs[1]))
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing" and #t.loads == 0)
assert(t.loader:RequestData("retail", 10, { x = 25, y = 75 }) == "ready"
    and t.data.terrainDatasets.retail[10].packs.west and not t.data.terrainDatasets.retail[9],
    "Source identity includes its native world")

for _, invalid in ipairs({
    { "unknown", 9, "west", 4, function() end },
    { "retail", -1, "west", 4, function() end },
    { "retail", 1.5, "west", 4, function() end },
    { "retail", 9, "", 4, function() end },
    { "retail", 9, "west", -1, function() end },
    { "retail", 9, "west", math.huge, function() end },
    { "retail", 9, "west", 4, "encoded-data" },
}) do
    t = Fixture(true)
    assert(not pcall(t.loader.RegisterSource, t.loader, unpack(invalid)), "Malformed source registration must fail")
    assert(next(t.loader.sources) == nil and #t.loads == 0)
end
for _, file in ipairs({ "../outside.lua", "/absolute.lua", "C:/outside.lua", "NavigationData\\west.lua", "west.txt" }) do
    t = Fixture()
    t.packs[1].file = file
    assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing" and #t.loads == 0,
        "Malformed indexed paths cannot authorize source construction")
end
print("Terrain loader: internal lazy factories, source identities, exact builds/revisions, bounded work and failure recovery passed")
