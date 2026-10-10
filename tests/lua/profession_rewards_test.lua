local function noop() end
function LibStub() return { GetLocale = function() return {} end } end
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
APR = { NewModule = function() return {} end }
dofile('APR-Core/data/models/Enums.lua')
dofile('APR-Core/data/models/Items.lua')
local client = APR.GAME_VERSIONS.Forever
function APR:GetGameVersion() return client end
dofile('APR-Core/utils/QuestUtils.lua')
dofile('APR-Core/core/Event.lua')
local choices, rewarded = {}, 0
local profile = { autoHandIn = true, autoHandInChoice = true }
function GetNumQuestChoices() return #choices end
function GetQuestItemLink(_, index)
    if choices[index] then return '|Hitem:' .. choices[index] .. '|h[Reward]|h' end
end
function GetQuestItemInfo() return nil end
function GetQuestID() return 4402 end
function IsModifierKeyDown() return false end
function GetQuestReward() rewarded = rewarded + 1 end
function APR:IsQuestTurnInDeferred() return false end
function APR:GetSettingsProfile() return profile end
APR.event.TalkToDenyNpcLogic = noop
Enum = { ItemQuality = { Heirloom = 7 }, InventoryType = setmetatable({}, {__index = function(_, key) return key end}) }
for _, book in ipairs({247840, 247841, 247846}) do
    choices = {1, book}
    APR.event.functions.done('QUEST_COMPLETE')
    assert(rewarded == 0, 'A profession choice must never reach GetQuestReward')
    choices = {book}
    APR.event.functions.done('QUEST_COMPLETE')
    assert(rewarded == 0, 'Even a single profession book remains a manual reward')
end
choices = {false, 1}
assert(APR:RequiresManualQuestReward(), 'Uncached choices must not fall through to an arbitrary reward')
choices = {1}
assert(not APR:RequiresManualQuestReward(), 'Ordinary rewards retain automation')
APR.event.functions.done('QUEST_COMPLETE')
assert(rewarded == 1 and profile.autoHandIn and profile.autoHandInChoice, 'User settings stay enabled')
choices = {}
APR.event.functions.done('QUEST_COMPLETE')
assert(rewarded == 2, 'Quests without choices still turn in automatically')
client = APR.GAME_VERSIONS.Retail
choices = {247840}
assert(not APR:RequiresManualQuestReward(), 'Forever item IDs must not change unrelated Retail rewards')
print('Profession rewards: manual books, uncached data, normal rewards and unchanged settings passed')
