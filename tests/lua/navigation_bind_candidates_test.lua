local fixture = dofile("tests/lua/navigation_fixture.lua")

for _, profile in ipairs({ "forever", "retail" }) do
    fixture.profile, fixture.bindName = profile, "Auberge du test"
    APRNavigationCharacterSettings = nil
    local data = fixture:Load({
        bindings = {
            [101] = { space = "world", instanceID = 0, uiMapID = 2395, x = 20, y = 30 },
            firstInn = { areaID = 202, space = "map", uiMapID = 2395, x = 0.35, y = 0.45 },
        }
    })
    local adapter = APR.NavigationAdapter
    local reads = {}
    C_Map.GetAreaInfo = function(id)
        assert(type(id) == "number", "Candidate keys must never be passed as client area IDs")
        reads[id] = (reads[id] or 0) + 1
        if id == 101 then return "Ancienne auberge" end
        if id == 202 then return "Auberge du test" end
    end
    local lookup = adapter:CreatePreparation()
    assert(not next(reads), "Preparing a catalogue does not scan its names synchronously")
    assert(lookup:Step(1) == "planning")
    local calls = (reads[101] or 0) + (reads[202] or 0)
    assert(calls == 1, "The operation budget includes named candidates")
    while lookup:Step(1) == "planning" do end
    local position = assert(data:GetBindPosition())
    assert(position.x == 3500 and position.y == 4500 and position.uiMapID == 2395,
        "Explicit area IDs resolve localized inn names and normalize map coordinates")
    assert(reads[101] == 1 and reads[202] == 1)
    for _ = 1, 10 do assert(data:GetBindPosition().x == 3500) end
    assert(reads[202] == 1, "Hearth variants reuse the resolved catalogue")

    fixture.bindName = "Ancienne auberge"
    assert(data:GetBindPosition().x == 20, "Numeric area keys without explicit areaID remain compatible")
    fixture.bindName = "Auberge du test"
    data:GetBindings().secondInn = { areaID = 202, space = "map", uiMapID = 2395, x = 0.7, y = 0.8 }
    assert(not data:GetBindPosition(), "Distant inns sharing the very same area ID stay ambiguous")
    adapter.frame:OnEvent("HEARTHSTONE_BOUND")
    assert(data:GetBindPosition().x == 100, "A confirmed bind disambiguates multiple candidates")

    APRNavigationCharacterSettings.bindLocation = nil
    adapter.bindLookup = nil
    data:GetBindings().secondInn.x, data:GetBindings().secondInn.y = 0.3503, 0.4504
    assert(data:GetBindPosition(), "Two observations exactly five yards apart can describe the same inn")
    adapter.bindLookup = nil
    data:GetBindings().secondInn.y = 0.4505
    assert(not data:GetBindPosition(), "Candidates beyond the shared-position tolerance remain ambiguous")

    fixture.bindName = "Auberge inconnue"
    assert(not data:GetBindPosition(), "An unknown bind cannot inherit the previous catalogue result")
    adapter.frame:OnEvent("HEARTHSTONE_BOUND")
    assert(data:GetBindPosition().x == 100, "A new unlisted inn is learned from the client bind event")
end
print("Bind candidates: localized IDs, legacy keys, budget, cache, ambiguity, tolerance and observed fallback passed")
