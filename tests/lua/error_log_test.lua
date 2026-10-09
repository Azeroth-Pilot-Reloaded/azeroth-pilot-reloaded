-- Diagnostics must preserve the previous handler, reject unrelated/restricted data and stay bounded.
local env = dofile("tests/lua/route_ui_test_env.lua")
local forwarded, handler, now = 0, nil, 100
handler = function() forwarded = forwarded + 1; return "forwarded" end
function geterrorhandler() return handler end
function seterrorhandler(value) handler = value end
function time() return now end
function debugstack() return "Interface/AddOns/APR/APR-Core/core/ErrorLog.lua:1\nInterface/AddOns/Other/Core.lua:1" end
function issecretvalue(value) return type(value) == "table" and value.secret end
dofile("APR-Core/core/ErrorLog.lua")
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
print("Errors: handler chaining, APR attribution, restricted strings, bounded storage and BugGrabber counts passed")
