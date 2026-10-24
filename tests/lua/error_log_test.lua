-- Diagnostics must preserve the previous handler, reject unrelated/restricted data and stay bounded.
local env = dofile("tests/lua/route_ui_test_env.lua")
local forwarded, handler, now = 0, nil, 100
handler = function() forwarded = forwarded + 1; return "forwarded" end
function geterrorhandler() return handler end
function seterrorhandler(value) handler = value end
function time() return now end
function debugstack() return "Interface/AddOns/APR/APR-Core/core/ErrorLog.lua:1\nInterface/AddOns/Other/Core.lua:1" end
function issecretvalue(value) return type(value) == "table" and value.secret end
local createFrame, observer, registered = CreateFrame, nil, {}
function CreateFrame(...)
    observer = createFrame(...)
    function observer:RegisterEvent(event) registered[event] = true end
    return observer
end
dofile("APR-Core/core/ErrorLog.lua")
assert(registered.ADDON_ACTION_BLOCKED and registered.ADDON_ACTION_FORBIDDEN,
    "Protected-action diagnostics must subscribe to both native events")
local log = APR.ErrorLog
assert(handler("Other error") == "forwarded" and forwarded == 1 and #log.entries == 0)
assert(handler("Interface/AddOns/APR/APR-Core/core/Core.lua:12: test") == "forwarded")
now = 105
handler("Interface/AddOns/APR/APR-Core/core/Core.lua:12: test")
assert(#log.entries == 1 and log.entries[1].count == 2 and log.entries[1].last == 105)
log:Record("Another addon", "Interface/AddOns/APR/APR-Core/features/questing/RouteManager.lua:5")
assert(#log.entries == 2, "A stack reference is retained as a potential APR error")
log:Record({secret = true}, {secret = true})
assert(#log.entries == 2)
for index = 1, 200 do log:Record("Interface/AddOns/APR/Test.lua:" .. index .. ": " .. string.rep("x", 5000), string.rep("s", 20000)) end
assert(#log.entries == 100 and #log.entries[100].message <= 4096 and #log.entries[100].stack <= 12000)
local callback
local bug = {message = "Interface/AddOns/APR/Test.lua:999", stack = "trace", counter = 7, time = 123, session = 1}
BugGrabber = {GetErrorByID = function(_, id) assert(id == "id"); return bug end,
    GetSessionId = function() return 1 end, GetDB = function() return {bug} end}
EventRegistry = {RegisterCallback = function(_, event, cb) assert(event == "BugGrabber.BugGrabbed"); callback = cb end}
log:Connect()
assert(log.provider == "BugGrabber" and log.entries[100].count == 7)
bug.counter = 8; callback(nil, "id")
assert(log.entries[100].count == 8, "BugGrabber counts are not double-counted")
local count = #log.entries
handler("Interface/AddOns/APR/Other.lua:1")
assert(#log.entries == count and forwarded == 4, "The previous handler still receives errors after BugGrabber takes over")

-- A Blizzard-only stack must still be captured when the native event names APR.
-- This remains active with BugGrabber, which reports each bad addon only once.
log:Clear()
APR.ActiveRoute, APR.PlayerID = "test-route", "test-player"
APRData = { ["test-player"] = { ["test-route"] = 12 } }
function debugstack() return "Interface/AddOns/Blizzard_GuildControlUI/Blizzard_GuildControlUI.lua:312" end
local onEvent = observer.scripts.OnEvent
onEvent(observer, "ADDON_ACTION_FORBIDDEN", "APR", "IsUserOAuthed()")
assert(#log.entries == 1 and log.entries[1].message == "ADDON_ACTION_FORBIDDEN: IsUserOAuthed()")
assert(log.entries[1].source == "APR" and log.entries[1].route == "test-route" and log.entries[1].step == 12)
onEvent(observer, "ADDON_ACTION_FORBIDDEN", "APR", "IsUserOAuthed()")
assert(#log.entries == 1 and log.entries[1].count == 2, "Repeated native failures must be counted")
onEvent(observer, "ADDON_ACTION_BLOCKED", "APR", "Frame:RegisterEvent()")
assert(#log.entries == 2, "Both protected-action events must be retained")
onEvent(observer, "ADDON_ACTION_FORBIDDEN", "APR-Recorder", "IsUserOAuthed()")
onEvent(observer, "ADDON_ACTION_FORBIDDEN", "Other", "IsUserOAuthed()")
onEvent(observer, "ADDON_ACTION_FORBIDDEN", {secret = true}, "IsUserOAuthed()")
assert(#log.entries == 2, "Other addons and inaccessible attribution must be ignored")
onEvent(observer, "ADDON_ACTION_FORBIDDEN", "APR", {secret = true})
assert(log.entries[3].message == "ADDON_ACTION_FORBIDDEN: ", "Secret arguments must not be converted")
assert(forwarded == 4, "Observing native events must not interfere with error handlers")
print("Errors: handler chaining, APR attribution, restricted strings, bounded storage and BugGrabber counts passed")
