local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.locale, fixture.faction, fixture.currentMap = "frFR", "Horde", 85

-- Extra build fields must not become tonumber's optional base argument when
-- the adapter loads. Exercise both numeric and string interface versions.
local cases = {
    { version = "12.1.5", interface = 120105, profile = "retail" },
    { version = "12.1.5", interface = "120105", profile = "retail" },
    { version = "1.60.1", interface = 16001, profile = "forever" },
    { version = "1.60.1", interface = "16001", profile = "forever" },
    { version = "1.15.9", interface = 11509, profile = "unsupported" },
    { version = "unknown", interface = "invalid", profile = "unsupported" },
    { version = "unknown", profile = "unsupported" },
}
for _, case in ipairs(cases) do
    GetBuildInfo = function()
        return case.version, "build", "date", case.interface, "extra", true
    end
    local data = fixture:Load()
    assert(data.profile == case.profile, "Unexpected navigation profile for " .. case.version)
    assert(APR.NavigationEngine == LibStub("LibAPRNavigation-1.0").Engine)
end

GetBuildInfo = nil
assert(fixture:Load().profile == "unsupported", "A missing build API must not select a client dataset")

print("Navigation client detection tests passed")
