local fixture = dofile("tests/lua/navigation_fixture.lua")
local catalogs = dofile("tests/lua/navigation_travel_action_test_catalog.lua")
local data = fixture:Load(catalogs.retail)
dofile("APR-Core/utils/PlayerUtils.lua")
local owned, restricted, cooling, bagCount = {}, {}, false, 0
function PlayerHasToy(id) return owned[id] == true end
C_ToyBox = { IsToyUsable = function(id) return not restricted[id] end }
C_Item.GetItemCount = function(id) return id == 1 and bagCount or 0 end
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

end
assert(count == 1 and definition.selection == "random", "There is one random inn-hearth edge, regardless of race")
local options = {}
for _, option in ipairs(definition.actions) do assert(not options[option.id]); options[option.id] = option end
assert(#definition.actions == 5, "The fixture includes declared effects and a client-resolved variant")
assert(not options[5] and not options[6], "Fixed-destination hearthstones cannot return to the inn")
local nextChoice = 1
data.env.random = function(size) assert(nextChoice <= size); return nextChoice end
for id in pairs(options) do
    if id ~= 4 then
        owned = { [id] = true }
        local action = data:GetHearthstoneAction()
        assert(action and action.data == id, "A toy-only character can use every available inn variant: " .. id)
    end
end
owned = { [2] = true, [3] = true }
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
    "The selected variant's client cast effect is resolved by the library")
currentStep = {}
assert(not APR:IsHearthstoneSpell(999000 + chosen), "An obsolete selection cannot complete a new step")
nextChoice, owned = 1, { [4] = true }
assert(not data:GetHearthstoneAction(), "Ownership cannot bypass the Draenei variant's race requirement")
function UnitRace() return "Draenei", "Draenei", 11 end
assert(data:GetHearthstoneAction().data == 4)
owned, restricted = { [2] = true, [3] = true }, { [2] = true }
assert(data:GetHearthstoneAction().data == 3, "Random selection excludes unusable owned toys")
cooling = true
assert(not data:GetHearthstoneAction(), "Cooldowns prevent navigation from offering a hearthstone")
assert(data:GetHearthstoneAction(true).data == 3, "Authored UseHS retains the owned button to display its cooldown")
cooling = false
local start = { instanceID = 0, uiMapID = 2395, x = 0, y = 0 }
local edges, metadata = data:BuildEdges({ start = start, playerPosition = start })
local hearthEdges = 0
for _, edge in ipairs(edges) do
    if edge.id == "retail:item-hearthstone-alternatives:forward" then
        hearthEdges = hearthEdges + 1
        assert(edge.action.data == 3 and edge.resources["cooldown:hearthstone"] == 1)
    end
end
assert(hearthEdges == 1 and metadata.resources["cooldown:hearthstone"] == 1)
local dalaran, garrison = data:GetTravelAction("UseDalaHS"), data:GetTravelAction("UseGarrisonHS")
assert(dalaran.type == "item" and dalaran.data == 5)
assert(garrison.type == "item" and garrison.data == 6)
assert(data:IsTravelActionSpell("UseDalaHS", 15) and data:IsTravelActionSpell("UseGarrisonHS", 16))
assert(not data:IsTravelActionSpell("UseHS", 15) and not data:IsTravelActionSpell("UseHS", 16),
    "Fixed destinations cannot complete a return-to-inn instruction")
assert(data:IsTravelActionSpell("UseHS", 7), "A learned recall still completes an inn return")
fixture.profile = "forever"
local forever = fixture:Load(catalogs.forever)
assert(forever:GetTravelAction("UseHS").data == 1 and forever:IsTravelActionSpell("UseHS", 11))
assert(not forever:GetTravelAction("UseDalaHS") and not forever:GetTravelAction("UseGarrisonHS"))
print("Hearthstone variants: complete UseHS toy coverage, random usable choices, stable buttons, race/cooldown restrictions and one shared resource passed")
