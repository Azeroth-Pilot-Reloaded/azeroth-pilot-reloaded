local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture:Load()
local allowed = {repair = true, auction = true, bank = true, stable = true, vendor = true,
    trainer = true, class = true, weapon = true, inn = true, mailbox = true}
for profile, records in pairs(LibStub("LibAPRNavigation-1.0").serviceLocations) do
    local seen = {}
    for _, record in ipairs(records) do
        assert(allowed[record.service], "Unsupported service")
        assert(type(record.mapID) == "number" and record.mapID > 0)
        assert(type(record.mapName) == "string" and record.mapName ~= "" and record.mapName ~= "Unknown map")
        assert(type(record.name) == "string" and record.name ~= "")
        assert(type(record.x) == "number" and record.x >= 0 and record.x <= 100)
        assert(type(record.y) == "number" and record.y >= 0 and record.y <= 100)
        assert(record.faction == "A" or record.faction == "H" or record.faction == "B" or record.faction == "AH")
        assert(not record.sources and not record.source and not record.provenance)
        if record.npcID then assert(type(record.npcID) == "number" and record.npcID > 0) end
        if record.objectID then assert(type(record.objectID) == "number" and record.objectID > 0) end
        if record.z then assert(type(record.z) == "number") end
        if record.spellIDs then
            assert(type(record.spellIDs) == "table")
            local spells = {}
            for index, spellID in pairs(record.spellIDs) do
                assert(type(index) == "number" and index >= 1 and index <= #record.spellIDs and index % 1 == 0)
                assert(type(spellID) == "number" and spellID > 0 and spellID % 1 == 0)
                assert(not spells[spellID], "Duplicate trainer capability")
                spells[spellID] = true
            end
        end
        if record.skill then assert(type(record.skillName) == "string" and record.skillName ~= "") end
        if record.service == "class" then assert(type(record.class) == "string") end
        if record.service == "trainer" and profile == "retail" then
            assert(type(record.expansion) == "number" and record.expansion >= 0 and record.expansion <= 11)
            assert(type(record.expansionName) == "string" and record.expansionName ~= "")
        end
        local key = table.concat({record.service, record.npcID or record.objectID or 0, record.mapID,
            record.x, record.y, record.faction, record.skill or 0, record.class or "", record.expansion or -1}, ":")
        assert(not seen[key], "Duplicate service location")
        seen[key] = true
    end
end
print("Service catalogs: common coordinate, identity, readable-name, specialization, faction and duplicate contracts passed")
