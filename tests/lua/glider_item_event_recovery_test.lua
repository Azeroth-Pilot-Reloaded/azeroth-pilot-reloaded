-- Native item-data arrival must replace the displayed fallback instruction.
-- The dispatcher, option selection, item-name producer and renderer are real.
local function noop() end
local locale = { USE_ITEM = "Use %s", GOBLIN_GLIDER = "Invented pending glider" }
function LibStub() return { GetLocale = function() return locale end } end
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
function wipe(values) for key in pairs(values) do values[key] = nil end end
local errors, timers = {}, {}
function geterrorhandler() return function(message) errors[#errors + 1] = message end end
C_Timer = { NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
APR = { PlayerID = "invented-player", ActiveRoute = "invented-glider",
    settings = { profile = { enableAddon = true } }, Buff = { RemoveAllBuffIcon = noop } }
APRData = { [APR.PlayerID] = { ["invented-glider"] = 1, ["invented-other"] = 1 } }
function APR:NewModule() return {} end
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/utils/PlayerUtils.lua")
dofile("APR-Core/features/questing/StepInstructions.lua")
dofile("APR-Core/core/Event.lua")
local routes = { ["invented-glider"] = { steps = { { UseGlider = true } } },
    ["invented-other"] = { steps = { { Note = "Invented unrelated action" } } } }
function APR:GetRouteData(route) return routes[route] end
function APR:GetStep(index) return routes[self.ActiveRoute].steps[index] end
function APR:GetCurrentStep() return self:GetStep(APRData[self.PlayerID][self.ActiveRoute]) end
APR.IsInstanceWithUI = function() return true end
APR.RefreshInstanceUIVisibility, APR.MaybePromptInstanceUIPreference = noop, noop
APR.StartPerformanceSample, APR.FinishPerformanceSample = noop, noop
APR.Debug, APR.DebugEvent, APR.ResetQuestTitleRequests = noop, noop, noop
APR.RefreshLevelProfileTargets = noop
APR.npcInteraction = { Track = noop, Clear = noop }
APRSecret = { CanAccessValue = function() return true end }
local label, renders, nativeName, fail = nil, 0, nil, false
APR.currentStep = { UpdateStepButtonUsability = noop, AddExtraLineText = function(_, key, text)
    assert(key == "USE_ITEM_GLIDER")
    label = text
end }
C_Item = { GetItemInfo = function(id)
    assert(id == 109076, "The producer queries the client glider item contract")
    if fail then error("Invented item-data failure") end
    return nativeName
end }
function APR:UpdateStep()
    renders, label = renders + 1, nil
    self.stepHandlers.RenderRequirements(self:GetStep(APRData[self.PlayerID][self.ActiveRoute]), true, 1)
end
local function dispatch(event)
    APR.event.EventHandler({ tag = "inventory", callback = APR.event.functions.inventory }, event)
    assert(#errors == 0, errors[1])
end
local function flush()
    local timer = assert(APR.event.stepRefreshTimer, "Item data arrival must queue the active glider instruction")
    assert(timer.delay == 0.1)
    timer.callback()
    assert(not APR.event.stepRefreshTimer)
end

APR:UpdateStep()
assert(label == "Use Invented pending glider" and APRData.GliderName == nil)
nativeName = "Invented ready wing"
local before = #timers
for _ = 1, 200 do dispatch("GET_ITEM_INFO_RECEIVED") end
assert(#timers == before + 1 and renders == 1, "Item bursts coalesce without synchronous redraws")
flush()
assert(label == "Use Invented ready wing" and APRData.GliderName == nativeName and renders == 2)
before = #timers
for _, event in ipairs({ "BAG_UPDATE_DELAYED", "CURSOR_CHANGED", "TOYS_UPDATED" }) do dispatch(event) end
assert(#timers == before, "Unrelated inventory notifications need no glider-only redraw")

APRData.GliderName, nativeName, fail = nil, nil, true
dispatch("GET_ITEM_INFO_RECEIVED")
flush()
assert(label == "Use Invented pending glider" and APRData.GliderName == nil)
fail, nativeName = false, "Invented recovered wing"
dispatch("GET_ITEM_INFO_RECEIVED")
flush()
assert(label == "Use Invented recovered wing" and APRData.GliderName == nativeName)
dispatch("GET_ITEM_INFO_RECEIVED")
APR.ActiveRoute = "invented-other"
flush()
assert(label == nil and APRData[APR.PlayerID]["invented-glider"] == 1,
    "A queued refresh renders the new route without advancing the previous one")
before = #timers
dispatch("GET_ITEM_INFO_RECEIVED")
assert(#timers == before, "Other steps keep the scoped native-data refresh contract")
APR.ActiveRoute, APR.settings.profile.enableAddon = "invented-glider", false
dispatch("GET_ITEM_INFO_RECEIVED")
assert(#timers == before, "Disabled addons do not restart instruction rendering")
print("Glider item-data recovery: real event, producer, renderer, bursts, failures and context changes passed")
