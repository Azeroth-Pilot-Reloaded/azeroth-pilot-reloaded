local hooks, scripts, timers = {}, {}, {}
local frame
function hooksecurefunc(name, callback) hooks[name] = callback end
CinematicFrame = { HookScript = function(_, name, callback) scripts[name] = callback end }
function CreateFrame()
    frame = { RegisterEvent = function() end, SetScript = function(_, _, callback) scripts.event = callback end }
    return frame
end
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
Enum = { CinematicType = { GameMovie = 1 } }
local modifier, movies, cinematics = false, 0, 0
function IsModifierKeyDown() return modifier end
function CinematicFinished() movies = movies + 1 end
function CinematicFrame_CancelCinematic() cinematics = cinematics + 1 end
local profile, step = nil, nil
APR = { GetSettingsProfile = function() return profile end, GetCurrentStep = function() return step end }
dofile("APR-Core/features/player/Cutscenes.lua")
hooks.MovieFrame_PlayMovie()
assert(#timers == 0, "Before initialization, skip hooks must leave movies alone")
profile = { enableAddon = true, autoSkipCutScene = true }
step = { Dontskipvid = true }
hooks.MovieFrame_PlayMovie(); scripts.event(frame, "CINEMATIC_START")
assert(#timers == 0, "The same route flag protects movies and cinematics")
step = nil
hooks.MovieFrame_PlayMovie(); scripts.event(frame, "CINEMATIC_START")
assert(#timers == 2)
for _, callback in ipairs(timers) do callback() end
assert(movies == 1 and cinematics == 1)
profile.enableAddon = false
hooks.MovieFrame_PlayMovie()
assert(#timers == 2)
profile.enableAddon = true
hooks.MovieFrame_PlayMovie()
profile.enableAddon = false
timers[3]()
assert(movies == 1, "A pending skip must respect disabling APR")
profile.enableAddon, modifier = true, true
hooks.MovieFrame_PlayMovie(); scripts.event(frame, "CINEMATIC_START")
assert(#timers == 3)
print("Cutscenes: startup, shared route protection, modifier override and delayed disable passed")
