local fixture = dofile("tests/lua/navigation_fixture.lua")

-- Only project faction constraints here. Other predicates remain possible, so
-- missing quest or level observations cannot produce a false contradiction.
local function FactionPossible(requirements, faction)
    if not requirements then return true end
    if requirements.faction and requirements.faction ~= faction then return false end
    for _, child in ipairs(requirements.all or {}) do
        if not FactionPossible(child, faction) then return false end
    end
    if requirements.any then
        local possible = false
        for _, child in ipairs(requirements.any) do
            if FactionPossible(child, faction) then possible = true; break end
        end
        if not possible then return false end
    end
    local excluded = requirements.notCondition
    if excluded and excluded.faction then
        local factionOnly = true
        for key in pairs(excluded) do if key ~= "faction" then factionOnly = false; break end end
        if factionOnly and excluded.faction == faction then return false end
    end
    return true
end

local contradiction = { all = { { faction = "Alliance" }, { faction = "Horde" } } }
assert(not FactionPossible(contradiction, "Alliance") and not FactionPossible(contradiction, "Horde"))
local alternatives = { any = { { faction = "Alliance" }, { faction = "Horde" } } }
assert(FactionPossible(alternatives, "Alliance") and FactionPossible(alternatives, "Horde"))

local removed = {
    ["portal-crossing-114"] = true, ["portal-crossing-115"] = true,
    ["portal-crossing-116"] = true, ["portal-crossing-117"] = true,
}
local checked = 0
for _, profile in ipairs({ "retail", "forever" }) do
    fixture.profile = profile
    local data = fixture:Load()
    for _, connection in ipairs(data:GetConnections()) do
        assert(FactionPossible(connection.requirements, "Alliance")
            or FactionPossible(connection.requirements, "Horde"),
            connection.id .. " requires incompatible factions")
        if profile == "retail" then
            assert(not removed[connection.id], "Impossible legacy Tanaan transition was restored without evidence")
        end
        checked = checked + 1
    end
end
print("Navigation catalogue integrity: " .. checked .. " faction-consistent connections passed")
