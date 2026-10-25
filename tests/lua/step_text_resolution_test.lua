local locale = setmetatable({
    SYNTHETIC_HINT = "Translated hint",
    SYNTHETIC_EMPTY_HINT = "",
    SYNTHETIC_COLOR_HINT = "[COLOR:#00ff00]Translated color hint",
}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
APR = {}
dofile("APR-Core/utils/StepUtils.lua")

AprRCData = { ExtraLineTexts = { SYNTHETIC_HINT = "Recorder hint", RECORDER_HINT = "Recorder only" } }
SYNTHETIC_HINT = "Blizzard hint"
assert(APR:ResolveStepText("SYNTHETIC_HINT") == "Blizzard hint", "WoW display strings take priority")
for _, nonText in ipairs({ false, true, 12, {}, function() end, "" }) do
    SYNTHETIC_HINT = nonText
    assert(APR:ResolveStepText("SYNTHETIC_HINT") == "Translated hint", "Non-text globals cannot shadow localization")
end
for _, formatted in ipairs({ "Blizzard %s", "Blizzard %d", "Blizzard %02.3f", "Blizzard %1$s", "Blizzard 100%%" }) do
    SYNTHETIC_HINT = formatted
    assert(APR:ResolveStepText("SYNTHETIC_HINT") == "Translated hint", "Global formats require their own arguments")
end
SYNTHETIC_HINT = "Blizzard 40%"
assert(APR:ResolveStepText("SYNTHETIC_HINT") == "Blizzard 40%", "A literal percentage does not require arguments")
SYNTHETIC_HINT = nil
assert(APR:ResolveStepText("SYNTHETIC_HINT") == "Translated hint")
assert(APR:ResolveStepText("RECORDER_HINT") == "Recorder only", "Recorder text remains a fallback")
assert(APR:ResolveStepText("Untranslated advice") == "Untranslated advice")
assert(APR:ResolveStepText("SYNTHETIC_EMPTY_HINT") == nil, "An explicit empty translation remains hidden")
assert(APR:ResolveStepText("") == nil and APR:ResolveStepText(nil) == nil)
assert(APR:ResolveStepText(42) == "42")
local text, color = APR:ResolveStepText("SYNTHETIC_COLOR_HINT")
assert(text == "Translated color hint" and color == "00ff00")
SYNTHETIC_COLOR_HINT = "[COLOR:#ff0000]Blizzard color hint"
text, color = APR:ResolveStepText("SYNTHETIC_COLOR_HINT")
assert(text == "Blizzard color hint" and color == "ff0000", "Color parsing follows the selected display text")
local lines = APR:ResolveStepTextList({ "SYNTHETIC_EMPTY_HINT", "SYNTHETIC_COLOR_HINT", "RECORDER_HINT" })
assert(#lines == 2 and lines[1].color == "ff0000" and lines[2].text == "Recorder only")
AprRCData = nil
assert(APR:ResolveStepText("RECORDER_HINT") == "RECORDER_HINT")
print("Step text: WoW globals, locale, Recorder, literals, empty strings and colors passed")
