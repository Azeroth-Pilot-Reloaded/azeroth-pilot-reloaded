-- The host loads only indexed terrain packs; registration remains library-owned.
local root = "APR-Core/features/navigation/NavigationTerrain.lua"
local function Fixture()
    local t = { now = 0, loads = {}, build = "12.1.5", buildNumber = "42", profile = "retail" }
    local data = { terrainDatasets = {} }
    local packs = {
        { id = "west", addon = "FixtureWest", revision = 4, bounds = { minX = 0, maxX = 100, minY = 0, maxY = 100 } },
        { id = "east", addon = "FixtureEast", revision = 7, bounds = { minX = 100, maxX = 200, minY = 0, maxY = 100 } },
    }
    APR = { NavigationTerrainIndex = { schema = 1, profiles = {
        retail = { builds = { ["12.1.5.42"] = true }, worlds = { [9] = { packs = packs } } },
        forever = { builds = { ["1.60.1.77"] = true }, worlds = { [3] = { packs = packs } } },
    } } }
    function APR:GetGameVersion() return t.profile end
    function GetBuildInfo() return t.build, t.buildNumber end
    function GetTime() return t.now end
    function InCombatLockdown() return t.combat == true end
    local opaque = {}
    function issecretvalue(value) return rawequal(value, opaque) end
    LibStub = setmetatable({}, { __call = function() return data end })
    function t:Register(pack, revision)
        data.terrainDatasets[self.profile] = data.terrainDatasets[self.profile] or {}
        local world = self.profile == "retail" and 9 or 3
        local record = data.terrainDatasets[self.profile][world] or { packs = {} }
        data.terrainDatasets[self.profile][world] = record
        record.packs[pack.id] = { revision = revision or pack.revision,
            data = { format = 1, profile = self.profile, build = self.build .. "." .. self.buildNumber } }
    end
    C_AddOns = {
        IsAddOnLoaded = function() return t.loading or t.loaded or false, t.loaded or false end,
        LoadAddOn = function(name)
            assert(not t.combat, "No addon load is attempted in combat")
            t.loads[#t.loads + 1] = name
            if t.throw then error("native loader failed") end
            if t.fail then return nil, "MISSING" end
            if not t.noRegistration then
                for _, pack in ipairs(packs) do if pack.addon == name then t:Register(pack) end end
            end
            return true
        end,
    }
    dofile(root)
    t.loader, t.data, t.packs, t.opaque = APR.NavigationTerrain, data, packs, opaque
    return t
end

local t = Fixture()
assert(t.loader:HasData("retail", 9) and t.loader:HasData("retail") and not t.loader:HasData("retail", 10))
assert(#t.loads == 0, "The presence check must remain a cheap metadata-only operation")
local status = t.loader:RequestData("retail", 9, { x = 25, y = 75 })
assert(status == "ready" and #t.loads == 1 and t.loads[1] == "FixtureWest")
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready" and #t.loads == 1,
    "Already registered terrain must not load another addon")
assert(t.loader:RequestData("retail", 9, { x = 125, y = 75 }) == "ready" and t.loads[2] == "FixtureEast")
assert(t.loader:RequestData("retail", 9, { x = 300, y = 75 }) == "missing" and #t.loads == 2,
    "A known world without coverage at this point must not fabricate data")

t = Fixture()
assert(t.loader:RequestData("retail", 9) == "planning" and #t.loads == 1,
    "A request spanning several addons loads at most one per invocation")
assert(t.loader:RequestData("retail", 9) == "ready" and #t.loads == 2)

t = Fixture()
t.combat = true
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "planning" and #t.loads == 0)
t.combat = false
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready")
t.combat = true
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready",
    "Combat does not hide data already registered safely")

t = Fixture()
t.fail = true
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing")
assert(t.loader.lastFailure and t.loader.lastFailure.addon == "FixtureWest"
    and t.loader.lastFailure.nativeReason == "MISSING", "A native load failure must retain its actual cause for diagnostics")
t.fail, t.now = nil, 2
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready" and t.loader.lastFailure == nil,
    "A recovered native load clears stale failure diagnostics")

for _, failure in ipairs({ "fail", "throw", "noRegistration" }) do
    t = Fixture()
    t[failure] = true
    assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing")
    assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing" and #t.loads == 1,
        "An unavailable pack must not be retried every frame")
    t[failure], t.now = nil, 2
    assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "ready" and #t.loads == 2,
        "Transient loading failures remain retryable")
end

t = Fixture()
t.loading = true
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "planning" and #t.loads == 0)
t.loading, t.loaded = false, true
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing" and #t.loads == 0,
    "A loaded addon without its expected registration cannot claim terrain coverage")

t = Fixture()
t:Register(t.packs[1], 3)
t.loaded = true
assert(t.loader:RequestData("retail", 9, { x = 25, y = 75 }) == "missing",
    "A different registered terrain revision is incompatible")

t = Fixture()
for _, invalid in ipairs({ "unknown", "forever" }) do
    assert(t.loader:RequestData(invalid, 9) == "missing")
end
t.buildNumber = "43"
assert(t.loader:RequestData("retail", 9) == "missing" and #t.loads == 0,
    "An unlisted build cannot use another build's geometry")
t.build = t.opaque
assert(t.loader:RequestData("retail", 9) == "missing" and #t.loads == 0,
    "Opaque client metadata must not reach string operations")
t = Fixture()
C_AddOns = nil
assert(t.loader:RequestData("retail", 9) == "missing")
APR.NavigationTerrainIndex = nil
assert(not t.loader:HasData("retail", 9) and t.loader:RequestData("retail", 9) == "missing")

t = Fixture()
t.profile, t.build, t.buildNumber = "forever", "1.60.1", "77"
assert(t.loader:RequestData("forever", 3, { x = 25, y = 75 }) == "ready",
    "The Forever profile uses its own build identity and world namespace")
t = Fixture()
t.profile,t.build,t.buildNumber="forever","1.60.1","77"
local modern=C_AddOns
LoadAddOn=modern.LoadAddOn
IsAddOnLoaded=function(name)return modern.IsAddOnLoaded(name) end
C_AddOns=nil
assert(t.loader:RequestData("forever",3,{x=25,y=75})=="ready",
    "Clients exposing only the legacy addon-loading API retain the same validated lazy terrain contract")
t.data.terrainDatasets,t.loading={},true
assert(t.loader:RequestData("forever",3,{x=25,y=75})=="planning",
    "A legacy alias exposing two loading states must preserve the unfinished state")
LoadAddOn,IsAddOnLoaded=nil,nil
print("Terrain loader: lazy packs, exact builds/revisions, missing data, combat, failures and retry bounds passed")
