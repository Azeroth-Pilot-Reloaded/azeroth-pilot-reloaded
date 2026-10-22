local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load()
dofile("APR-Core/data/models/Spells.lua")
dofile("APR-Core/utils/PlayerUtils.lua")
local owned, restricted, cooling, bagCount = {}, {}, false, 0
function PlayerHasToy(id) return owned[id] == true end
C_ToyBox = { IsToyUsable = function(id) return not restricted[id] end }
C_Item.GetItemCount = function(id) return id == 6948 and bagCount or 0 end
C_Item.IsUsableItem = function() return true end
C_Item.GetItemCooldown = function() return cooling and 1 or 0, cooling and 1800 or 0, 1 end
local currentStep = {}
APR.GetCurrentStep = function() return currentStep end
local originalPosition = data.env.getDynamicPosition
data.env.getDynamicPosition = function(kind)
    if kind == "bind" then return { instanceID = 0, uiMapID = 2395, x = 400, y = 500 } end
    return originalPosition(kind)
end
local definition, count = nil, 0
for _, candidate in ipairs(data.connections) do
    if candidate.id == "item-hearthstone-alternatives" then definition, count = candidate, count + 1 end
    if candidate.id:find("recall%-to%-bind$") then
        assert(candidate.requirements.maxLevel == 49 and candidate.actions[1].consumable
            and candidate.cooldownGroup == "scroll-recall", "Recall scrolls retain their safe level, consumption and independent cooldown")
        assert(data:CheckRequirements(candidate.requirements, { level = 90 }) == false)
        assert(data:CheckRequirements(candidate.requirements, { level = 49 }) == true)
    end
end
assert(count == 1 and definition.selection == "random", "There is one random inn-hearth edge, regardless of race")
local options = {}
for _, option in ipairs(definition.actions) do assert(not options[option.id]); options[option.id] = option end
for _, id in ipairs(APR.hearthStoneToyItemIDs) do assert(options[id], "Every APR UseHS toy is a library alternative: " .. id) end
assert(not options[140192] and not options[110560], "Fixed-destination hearthstones cannot return to the inn")
local nextChoice = 1
data.env.random = function(size) assert(nextChoice <= size); return nextChoice end
for _, id in ipairs(APR.hearthStoneToyItemIDs) do
    if id ~= 210455 then
        owned = { [id] = true }
        local action = data:GetHearthstoneAction()
        assert(action and action.data == id, "A toy-only character can use every available inn variant: " .. id)
    end
end
owned = { [54452] = true, [263933] = true }
nextChoice = 1
local first = data:GetHearthstoneAction()
nextChoice = 2
local second = data:GetHearthstoneAction()
assert(first.data ~= second.data and owned[first.data] and owned[second.data],
    "Random selection includes all available variants, with no bag hearthstone")
nextChoice = 1
local selected = APR:GetHearthstoneItemID()
nextChoice = 2
assert(APR:GetHearthstoneItemID() == selected, "Repeated renders keep the secure action stable")
currentStep = {}
assert(APR:GetHearthstoneItemID() ~= selected, "A new authored step can choose another available variant")
C_Item.GetItemSpell = function(id) return "New toy effect", 999000 + id end
local chosen = APR:GetHearthstoneItemID()
assert(APR:IsHearthstoneSpell(999000 + chosen) and not APR:IsHearthstoneSpell(999999),
    "The selected variant's client cast effect extends the historical UseHS spell list")
currentStep = {}
assert(not APR:IsHearthstoneSpell(999000 + chosen), "An obsolete selection cannot complete a new step")
nextChoice, owned = 1, { [210455] = true }
assert(not data:GetHearthstoneAction(), "Ownership cannot bypass the Draenei variant's race requirement")
function UnitRace() return "Draenei", "Draenei", 11 end
assert(data:GetHearthstoneAction().data == 210455)
owned, restricted = { [54452] = true, [263933] = true }, { [54452] = true }
assert(data:GetHearthstoneAction().data == 263933, "Random selection excludes unusable owned toys")
cooling = true
assert(not data:GetHearthstoneAction(), "Cooldowns prevent navigation from offering a hearthstone")
assert(data:GetHearthstoneAction(true).data == 263933, "Authored UseHS retains the owned button to display its cooldown")
cooling = false
local start = { instanceID = 0, uiMapID = 2395, x = 0, y = 0 }
local edges, metadata = data:BuildEdges({ start = start, playerPosition = start })
local hearthEdges = 0
for _, edge in ipairs(edges) do
    if edge.id == "retail:item-hearthstone-alternatives:forward" then
        hearthEdges = hearthEdges + 1
        assert(edge.action.data == 263933 and edge.resources["cooldown:hearthstone"] == 1)
    end
end
assert(hearthEdges == 1 and metadata.resources["cooldown:hearthstone"] == 1)
print("Hearthstone variants: complete UseHS toy coverage, random usable choices, stable buttons, race/cooldown restrictions and one shared resource passed")
