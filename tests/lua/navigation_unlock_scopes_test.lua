-- Regressions across physical portals, multi-destination spells and toys.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local quests, account, achievements, active, accountReads = {}, {}, {}, {}, {}
C_QuestLog.IsQuestFlaggedCompleted = function(id) return quests[id] == true end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function(id)
    accountReads[id] = (accountReads[id] or 0) + 1
    return account[id] == true
end
C_QuestLog.IsOnQuest = function(id) return active[id] == true end
GetAchievementInfo = function(id) return id, "Client name", 0, achievements[id] == true end
local data = fixture:Load()
local definitions = {}
for _, connection in ipairs(data.connections) do definitions[connection.id] = connection end
local character = { faction = "Alliance", class = "MAGE", raceID = 1, level = 90, indoors = false }
local function Check(id)
    return data:CheckRequirements(assert(definitions[id]).requirements, character)
end

-- Unlock every Manapoof destination on another character. Faction and direction
-- remain separate constraints, and a missing API must not become permission.
local petQuests = { gnomeregan = 54185, deadmines = 46291, ["blackrock-depths"] = 58457,
    stratholme = 56491, ["wailing-caverns"] = 45423 }
for destination, quest in pairs(petQuests) do
    local id = "additional-pet-travel-boralus-" .. destination
    assert(Check(id) == false)
    account[quest] = true
    assert(Check(id) == true, "Account reward missing: " .. destination)
    character.faction = "Horde"
    assert(Check(id) == false, "Account progress cannot bypass faction")
    character.faction = "Alliance"
end
local start = data:NormalizeLocation({ instanceID = 0, uiMapID = 2395, x = 1, y = 2 })
data:BuildEdges({ start = start, playerPosition = start })
accountReads = {}
data:BuildEdges({ start = start, playerPosition = start })
for _, quest in pairs(petQuests) do
    assert(accountReads[quest] == 1, "Share account queries across all NPCs and directions")
end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = nil
assert(Check("additional-pet-travel-boralus-gnomeregan") == nil)
quests[54185] = true
assert(Check("additional-pet-travel-boralus-gnomeregan") == true)

assert(not Check("additional-dornogal-undermine"))
achievements[40900] = true
assert(Check("additional-dornogal-undermine") == true, "Undermine campaign achievement opens the account alternative")
character.level = 20
assert(Check("additional-dornogal-undermine") == false, "The achievement must not bypass the level requirement")
character.level = 90

-- Owning a reward on the account must not skip this character's introductions.
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function() return true end
assert(Check("item-140192-to-dalaran") == false, "Dalaran hearthstone retains its character introduction")
assert(Check("item-110560-to-lunarfall") == false, "The character still needs a garrison")
quests[44184] = true
assert(Check("item-140192-to-dalaran"))
character.class = "DRUID"
assert(Check("additional-dreamway-moonglade") == false, "Class-hall progress is personal")
quests[40645] = true
assert(Check("additional-dreamway-moonglade"))

-- Mole Machine has one learned spell but separately discovered destinations.
character.raceID = 34
local locked, opened
for _, connection in ipairs(data.connections) do
    local requirement = connection.requirements
    if connection.kind == "spell" and requirement and requirement.raceID == 34 and requirement.quest then
        if not opened then
            opened = connection
            quests[requirement.quest] = true
        elseif requirement.quest ~= opened.requirements.quest then locked = connection; break end
    end
end
assert(opened and locked and Check(opened.id) and Check(locked.id) == false,
    "A learned racial spell does not unlock every destination or borrow account discovery")
assert(data:CheckRequirements({ notCondition = { achievement = 999 } }, character) == true)
GetAchievementInfo = nil
assert(data:CheckRequirements({ notCondition = { achievement = 999 } }, character) == nil,
    "An unavailable achievement API cannot authorize an obsolete quest phase")
print("Travel unlock scopes: account portals, character introductions, levels, multi-destination discovery and unknown data passed")
