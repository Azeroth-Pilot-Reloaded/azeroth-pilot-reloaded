-- Synthetic character and item stats; no guide or addon data.
APR = { GAME_VERSIONS = { Forever = "forever" } }
local context = {client="forever", classID=11, pawnSpec=2, primary="Agility", role="DAMAGER", key="fixture"}
local level, race, interface = 25, "Human", 16001
function APR:GetRewardBuildContext() return context end
function APR:GetGameVersion() return context.client end
function UnitClass() return "Fixture", "DRUID", context.classID end
function UnitLevel() return level end
function UnitRace() return race, race end
function GetBuildInfo() return "fixture", "fixture", "fixture", interface end
local stats = {}
C_Item = { GetItemStats = function(link) return stats[link] end }
dofile("APR-Core/features/questing/RewardScoring.lua")
local scoring = APR.RewardScoring
stats.physical = {ITEM_MOD_AGILITY_SHORT=10}
stats.caster = {ITEM_MOD_SPELL_POWER_SHORT=20}
local scale = assert(scoring:GetDefaultScale())
assert(scale.score("physical") > scale.score("caster"), "A physical build must prefer useful agility over spell power")
context.pawnSpec = nil
assert(scoring:GetDefaultScale() == nil, "An unresolved hybrid build must abstain")
context.pawnSpec = 2
level = 0
assert(scoring:GetDefaultScale() == nil, "Unavailable level must abstain")
level, interface = 25, 99999
assert(scoring:GetDefaultScale() == nil, "Unknown client patch must abstain")

-- Discover declarations; all entries obey the same integrity and level boundaries.
for patchID, patch in pairs(scoring.profilePatches) do
    for classID, builds in pairs(scoring.profiles[patch.client]) do
        for build, declaration in ipairs(builds) do
            local c = {client=patch.client, classID=classID, pawnSpec=build, key="fixture:"..build}
            local p = scoring:ResolveProfile(c, 20, nil, patchID)
            if classID == 12 and build == 3 and patchID < 120000 then
                assert(p == nil)
            else
                assert(p and p.role == declaration[2] and p.weights[p.primaryStat] > 0)
                for stat, weight in pairs(p.weights) do
                    assert(type(stat)=="string" and type(weight)=="number" and weight >= 0 and weight < math.huge)
                end
                assert(scoring:ResolveProfile(c, 1, nil, patchID))
                assert(scoring:ResolveProfile(c, patch.maximum-1, nil, patchID))
                assert(scoring:ResolveProfile(c, patch.maximum, nil, patchID) == nil)
            end
            assert(scoring:ResolveProfile(c, -1, nil, patchID) == nil)
        end
    end
end
-- A synthetic declaration isolates selection, racial marginal gains and copying.
scoring.profiles.forever[91] = {{"healer", "HEALER"}, {"feral", "DAMAGER"}, {"bear", "TANK"}}
local c = {client="forever", classID=91, pawnSpec=1, key="invented"}
local neutral = assert(scoring:ResolveProfile(c, 29, nil, 16001))
local human = assert(scoring:ResolveProfile(c, 29, "Human", 16001))
assert(math.abs(human.weights.Spirit / neutral.weights.Spirit - 1.1) < 0.00001)
assert(human.weights.Intellect == neutral.weights.Intellect)
local tauren = assert(scoring:ResolveProfile(c, 29, "Tauren", 16001))
assert(math.abs(tauren.weights.Stamina / neutral.weights.Stamina - 1.05) < 0.00001)
local dwarf = assert(scoring:ResolveProfile(c, 29, "Dwarf", 16001))
assert(dwarf.weights.Hit == neutral.weights.Hit, "Flat racial hit is not an item contribution")
assert(scoring:ResolveProfile(c, 30, nil, 16001).weights.Stamina < neutral.weights.Stamina)
human.weights.Intellect = 999
assert(scoring:ResolveProfile(c, 29, "Human", 16001).weights.Intellect == neutral.weights.Intellect)
c.pawnSpec = 2
local physical = assert(scoring:ResolveProfile(c, 29, nil, 16001))
c.pawnSpec = 3
local mitigation = assert(scoring:ResolveProfile(c, 29, nil, 16001))
assert(mitigation.weights.Armor > physical.weights.Armor and mitigation.weights.Stamina > physical.weights.Stamina)
assert(physical.weights.SpellPower == 0 and physical.weights.Healing == 0)
c.pawnSpec = 99
assert(scoring:ResolveProfile(c, 29, nil, 16001) == nil)
context.pawnSpec, interface, level = 2, 16001, 25
local original = assert(scoring:GetDefaultScale())
assert(original.weights.Hit > 0, "Do not zero hit based on a cap on currently equipped gear")
level = 60
UNAVAILABLE = "Unavailable fixture"
assert(scoring:GetProfileDescription():find(UNAVAILABLE, 1, true), "Unavailable APR must be visible in settings status")
scoring.profiles.forever[91] = nil

-- The real bag consumer pins prompts to the effective APR model, not just APR mode.
function APR:NewModule() return {} end
LibStub = function() return {GetLocale=function() return {} end} end
APR.PawnRewards = {GetScorer=function() return nil, "apr", "selected-apr" end}
dofile("APR-Core/features/player/BagUpgrades.lua")
level, race = 29, "Human"
local _, earlyIdentity = APR.BagUpgrades:GetScale()
level = 30
local _, laterIdentity = APR.BagUpgrades:GetScale()
assert(earlyIdentity ~= laterIdentity, "Level band changes must invalidate an APR prompt identity")
race = "Tauren"
local _, racialIdentity = APR.BagUpgrades:GetScale()
assert(racialIdentity ~= laterIdentity, "Effective racial model changes must invalidate an APR prompt identity")
