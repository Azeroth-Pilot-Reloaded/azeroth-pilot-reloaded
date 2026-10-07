-- Shared helpers must preserve saved data and work before character initialization.
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
APR = {}
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/ProfileUtils.lua")
dofile("APR-Core/utils/StepUtils.lua")

local child = { enabled = false }
local original = { first = child, second = child }
original.self = original
original[child] = "table key"
local copy = APR:DeepCopyTable(original)
assert(copy ~= original and copy.first ~= child and copy.first == copy.second)
assert(copy.self == copy and copy[copy.first] == "table key" and copy.first.enabled == false)
copy.first.enabled = true
assert(child.enabled == false and APR:DeepCopyTable(false) == false)

assert(APR:ContainsText("Cast [A+B] (50%)", "[A+B] (50%)"))
assert(not APR:ContainsText("Cast AAAB", "A+B"))
assert(APR:WrapTextInColorCode("text", "zzzzzz") == "text")
assert(APR:WrapTextInColorCode("text", "#123abc") == "|cff123abctext|r")
assert(APR:Clamp(-1, 0, 2) == 0 and APR:Clamp(3, 0, 2) == 2)
local diagnostic = APR:TableToDebugString({ ['quoted"key'] = 'line\n"two"' })
local roundTrip = assert(loadstring("return " .. diagnostic))()
assert(roundTrip['quoted"key'] == 'line\n"two"')

local messages = {}
function APR:WrapTextWithAppearanceColor(text) return text end
local realPrint = print
print = function(...) messages[#messages + 1] = { ... } end
APR.settings = { profile = { debug = false } }
APR:Debug("nested", { value = "visible" }, true)
print = realPrint
assert(#messages == 2 and messages[2][2] == "visible", "Forced debug must reach nested values")

assert(APR:GetCurrentStep() == nil and APR:GetCharacterSettings() == nil)
APR.PlayerID, APR.ActiveRoute = "player", "route"
local source = { Note = "Original" }
APR.RouteQuestStepList = { route = { steps = { source } } }
function APR:GetRouteSteps(key) return self.RouteQuestStepList[key].steps end
APRData = { player = { route = 1 } }
local step, index, steps = APR:GetCurrentStep()
assert(step ~= source and index == 1 and steps[1] == source)
step.NoArrow = true
assert(APR:GetCurrentStep() == step and source.NoArrow == nil)
APR.RouteQuestStepList.route.steps[1] = { Note = "Replacement" }
assert(APR:GetCurrentStep().Note == "Replacement" and APR:GetCurrentStep() ~= step)
APRData.player.route = 2
assert(APR:GetCurrentStep() == nil)
APRData = nil
assert(APR:GetCurrentStep() == nil)

local character = { showHeirloomWarning = false }
APR.settings.db = { char = character }
SettingsDB = { char = { showHeirloomWarning = true } } -- Another addon's generic global.
APR.GAME_VERSIONS = { Forever = "forever" }
function APR:GetGameVersion() return "retail" end
assert(APR:GetHeirloomWarning() == false)
APR:SetRouteSuggestionDontAsk(true)
assert(character.routeSuggestionDontAsk and not SettingsDB.char.routeSuggestionDontAsk)
local saved = { char = { player = character }, profiles = { Default = { size = 15 }, Other = {} }, profileKeys = { player = "Other" } }
APRSettings = saved
local reloads = 0
C_UI = { Reload = function() reloads = reloads + 1 end }
APR:ResetAllProfilesToDefault()
assert(reloads == 1 and not next(APRSettings.profileKeys) and not APRSettings.profiles.Other)
assert(APRSettings.profiles.Default.size == 15 and APRSettings.char.player.showHeirloomWarning == false)
APRSettings.char.player.showHeirloomWarning = true
assert(saved.char.player.showHeirloomWarning == false)
print("Core utilities: isolated copies, cycles, literal text, diagnostics, current-step ownership and AceDB scope passed")
