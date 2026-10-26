local fixture = dofile("tests/lua/navigation_fixture.lua")
local count = 0
for _, profile in ipairs({ "retail", "forever" }) do
    for _, faction in ipairs({ "Alliance", "Horde" }) do
        for _, locale in ipairs({ "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }) do
            fixture.profile, fixture.faction, fixture.locale = profile, faction, locale
            local data = fixture:Load()
            assert(data.profile == profile and #data:GetConnections() > 0)
            local registered = {}
            for _, dataset in pairs(LibStub("LibAPRNavigation-1.0").datasets[profile]) do
                for _, connection in ipairs(dataset.connections or {}) do registered[connection.id] = true end
                for _, entrance in ipairs(dataset.entrances or {}) do
                    if entrance.reviewStatus == "confirmed" then
                        for index = 2, #(entrance.approach or {}) do registered[entrance.id .. ":approach:" .. index] = true end
                    end
                end
            end
            for _, raw in ipairs(data:GetConnections()) do
                assert(registered[raw.id], "A connection cannot leak from another profile: " .. raw.id)
                registered[raw.id] = nil
            end
            assert(next(registered) == nil, "Every registered connection is included")
            local edges = data:BuildEdges({ playerPosition = { x = 100, y = 200, instanceID = 0, uiMapID = 2395 } })
            for _, edge in ipairs(edges) do
                assert(edge.id:find(profile .. ":", 1, true) == 1 and edge.seconds >= 0 and edge.copper >= 0)
                assert(edge.from.instanceID ~= nil and edge.to.instanceID ~= nil)
                assert(edge.kind ~= "flight", "Only LibTaxiData supplies flight routing")
            end
            count = count + 1
        end
    end
end
assert(not _G.FarstriderLibData and not _G.FarstriderLib_API and not _G.FarstriderLibData_API)
local buildInfo = GetBuildInfo
GetBuildInfo = function() return "1.15.9", "1", "", 11509 end
local unsupported = fixture:Load()
local unsupportedEdges, metadata = unsupported:BuildEdges({})
assert(unsupported.profile == "unsupported" and not unsupported:GetProfile() and #unsupported:GetConnections() == 0)
assert(#unsupportedEdges == 0 and metadata.waitingData and metadata.reason == "unsupported_client",
    "Unsupported clients must never fall back to another client's world coordinates")
GetBuildInfo = buildInfo
print("Navigation catalogue profiles: " .. count .. " client/faction/language combinations passed")
