-- Exterior trigger and landing are distinct. The interior trigger near
-- this landing is not a verified exit.
local naxxramasEntrance = {
    space = "world",
    instanceID = 0,
    uiMapID = 1423,
    x = 3133.1499,
    y = -3730.29,
    z = 138.659,
}
local naxxramasAttunement = { minLevel = 60, questsAny = { 9121, 9122, 9123 } }
local questGiver = { space = "world", instanceID = 0, uiMapID = 1423, x = 2296.01, y = -5340.98, z = 90.8799 }
local unlockRoutes = {}

for _, branch in ipairs({
    { questID = 9121, standing = 6, objectives = { 1, 2, 3 } },
    { questID = 9122, standing = 7, objectives = { 1, 2 } },
    { questID = 9123, standing = 8 },
}) do
    local eligibility = { minLevel = 60, reputation = { id = 529, standing = branch.standing } }
    if branch.standing < 8 then
        eligibility.notCondition = { reputation = { id = 529, standing = branch.standing + 1 } }
    end
    local steps = {
        {
            kind = "accept",
            questID = branch.questID,
            position = questGiver,
            acceptance = {
                known = true,
                complete = false,
                requirements = eligibility,
                starterNPCIDs = { 16116 },
            },
        },
    }
    if branch.objectives then
        steps[#steps + 1] = {
            kind = "objective",
            questID = branch.questID,
            objectiveIndices = branch.objectives,
            positionOptional = true,
            source = "Routes/Forever/Raids/Forever_Raids_naxxramas_dread_citadel.lua",
        }
    end
    steps[#steps + 1] = { kind = "turnin", questID = branch.questID, position = questGiver }
    unlockRoutes[#unlockRoutes + 1] = {
        id = "quest:" .. branch.questID,
        goal = { key = "quest", value = branch.questID },
        availability = eligibility,
        prerequisitesKnown = false,
        steps = steps,
    }
end

LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "raid_access", {
    entrances = {
        {
            id = "entrance-forever-naxxramas",
            kind = "raid",
            reviewStatus = "confirmed",
            instanceID = 533,
            exterior = naxxramasEntrance,
            requirements = naxxramasAttunement,
            interiorMapIDs = {},
        },
    },
    connections = {
        {
            id = "passage-eastern-plaguelands-to-naxxramas",
            kind = "passage",
            from = naxxramasEntrance,
            to = { space = "world", instanceID = 533, x = 3005.87, y = -3435.01, z = 293.882 },
            requirements = { all = { naxxramasAttunement, { inRaid = true } } },
            seconds = 5,
        },
    },
    unlockRoutes = unlockRoutes,
}, 1)
