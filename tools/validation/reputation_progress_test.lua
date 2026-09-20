local function noop() end
local L = { RENOWN = "Renown" }
function LibStub() return { GetLocale = function() return L end } end
UNKNOWN, REPUTATION, FACTION, LEVEL, RANK = "Unknown", "Reputation", "Faction", "Level", "Rank"
function UnitSex() return 2 end
function GetText(key) return key end
function InCombatLockdown() return false end
hooksecurefunc = noop
APR = { Color = { defaultBackdrop = { 0, 0, 0, 1 }, blue = { 0, 0.5, 1 } }, Debug = noop }
function APR:NewModule() return {} end
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/utils/PlayerUtils.lua")
local faction = { name = "Faction", reaction = 5, currentStanding = 4500,
    currentReactionThreshold = 3000, nextReactionThreshold = 9000 }
C_Reputation = { GetFactionDataByID = function() return faction end }
local requirement = { factionID = 76, level = 6, type = "standard" }
local current, total, text = APR:GetReputationBarProgress(requirement)
assert(current == 1500 and total == 6000 and text:find("25%%"))
assert(not APR:IsReputationLevelReached(requirement))
faction.reaction, faction.currentStanding = 6, 9200
faction.currentReactionThreshold, faction.nextReactionThreshold = 9000, 21000
assert(APR:IsReputationLevelReached(requirement))
current, total = APR:GetReputationBarProgress(requirement)
assert(current == 200 and total == 12000, "Standing changes reset the displayed rank range")
faction.currentStanding, faction.currentReactionThreshold, faction.nextReactionThreshold = -5000, -6000, -3000
current, total = APR:GetReputationBarProgress(requirement)
assert(current == 1000 and total == 3000, "Negative standings have a positive local range")
C_MajorFactions = { GetMajorFactionData = function()
    return { name = "Major", renownLevel = 4, renownReputationEarned = 1250, renownLevelThreshold = 2500 }
end }
local renown = { factionID = 100, level = 5, type = "renown" }
current, total = APR:GetReputationBarProgress(renown)
assert(current == 1250 and total == 2500)
C_GossipInfo = {
    GetFriendshipReputation = function() return { friendshipFactionID = 200, name = "Friend", reaction = "Buddy",
        standing = 500, reactionThreshold = 200, nextThreshold = 800 } end,
    GetFriendshipReputationRanks = function() return { currentLevel = 2, maxLevel = 6 } end,
}
local friend = { factionID = 200, level = 3, type = "friendship" }
current, total, text = APR:GetReputationBarProgress(friend)
assert(current == 300 and total == 600 and text:find("Buddy"))
C_Reputation = nil
function GetFactionInfoByID() return "Legacy", "", 5, 3000, 9000, 6000 end
current, total = APR:GetReputationBarProgress(requirement)
assert(current == 3000 and total == 6000, "Legacy client API uses the same model")
GetFactionInfoByID = nil
assert(APR:GetReputationBarProgress(requirement) == nil)

-- Load the actual frame module, exercising parent visibility, reuse and font relayout.
local methods, bars = {}, 0
local function object(parent)
    return setmetatable({ parent = parent, shown = true, scripts = {}, height = 12 },
        { __index = function(_, key)
            return methods[key] or ((key:match("^Set") or key:match("^Get") or key:match("^Clear")
                or key:match("^Register") or key:match("^Enable")) and noop or nil)
        end })
end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:SetText(value) self.text = value end
function methods:GetStringHeight() return self.height end
function methods:SetHeight(value) self.height = value end
function methods:GetHeight() return self.height end
function methods:SetParent(parent) self.parent = parent end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
function methods:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
function methods:SetValue(value) self.value = value end
function methods:CreateFontString() return object(self) end
function methods:CreateTexture() return object(self) end
function methods:GetNormalTexture() return object(self) end
function CreateFrame(kind, name, parent, template)
    local frame = object(parent)
    if kind == "StatusBar" then bars = bars + 1 end
    if template == "ObjectiveTrackerContainerHeaderTemplate" then
        frame.Text, frame.MinimizeButton = object(frame), object(frame)
    end
    if name then _G[name] = frame end
    return frame
end
UIParent = object()
APR.settings = { profile = { currentStepShow = true, currentStepbackgroundColorAlpha = { 0, 0, 0, 1 } } }
function APR:GetSettingsProfile() return self.settings.profile end
function APR:RegisterFontString(font, _, options) font.onApplied = options.onApplied end
APR.SetupHeaderDrag, APR.SetupMinimizeButton = noop, noop
dofile("APR-Core/utils/UIUtils.lua")
APR.SetupHeaderDrag, APR.SetupMinimizeButton = noop, noop
dofile("APR-Core/ui/route/CurrentStep.lua")
APR.currentStep.CanSafelyHide = function() return true end
APR.currentStep.MaybeAttachRaidIconButton = noop
APR.currentStep.ResetSecureStepButton, APR.currentStep.ResetSecureRaidIconButton = noop, noop
APR.currentStep:AddReputationStep(renown)
local bar = APR.currentStep.reputationBar
assert(bar:IsShown() and bar.value == 1250 and bar.maximum == 2500)
local container = APR.currentStep.questsList["REPUTATION-100-Reputation"]
assert(not container.scripts.OnEnter, "A faction ID must not open a quest tooltip")
container.font.height = 30
container.font.onApplied(container.font)
assert(container:GetHeight() == 65, "Font updates preserve space for the bar")
APR.currentStep:RefreshTextLayout()
assert(container:GetHeight() == 65)
for _ = 1, 20 do APR.currentStep:AddReputationStep(friend) end
assert(bars == 1 and APR.currentStep.reputationBar == bar and bar.value == 300)
CurrentStepFrame_StepHolder:Hide()
assert(not bar:IsShown(), "Collapsing the step hides the bar through its parent")
CurrentStepFrame_StepHolder:Show()
APR.currentStep:RemoveQuestStepsAndExtraLineTexts()
assert(not bar:IsShown(), "Leaving the step clears its bar")
APR.currentStep:AddReputationStep(requirement)
assert(not bar:IsShown(), "Unavailable API data does not display misleading progress")
print("Reputation progress: standard, legacy, renown, friendship, bounds, reuse, layout and cleanup passed")
