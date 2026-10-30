-- Real embedded communications libraries over a deterministic, caller-owned WoW environment.
local DirectEnv = {}
local nativeXpcall = xpcall

function DirectEnv.Install(env)
    strmatch, strfind, strsub, strlen = string.match, string.find, string.sub, string.len
    local oldLibStub = LibStub
    local locale = oldLibStub and oldLibStub("AceLocale-3.0", true)
    LibStub, ChatThrottleLib = nil, nil
    dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
    if locale then
        local library = LibStub:NewLibrary("AceLocale-3.0", 1)
        for key, value in pairs(locale) do library[key] = value end
    end
    table.wipe = table.wipe or function(value) for key in pairs(value) do value[key] = nil end end
    securecallfunction = function(callback, ...) return callback(...) end
    if not select(2, xpcall(function(value) return value end, function() end, true)) then
        xpcall = function(callback, handler, ...)
            local args = {n = select("#", ...), ...}
            return nativeXpcall(function() return callback(unpack(args, 1, args.n)) end, handler)
        end
    end
    GetFramerate = function() return env.framerate or 60 end
    geterrorhandler = function()
        return function(message)
            env.libraryErrors = env.libraryErrors or {}
            env.libraryErrors[#env.libraryErrors + 1] = message
        end
    end
    Ambiguate = function(name) return name end
    DEFAULT_CHAT_FRAME = {AddMessage = function() end}
    SendChatMessage, BNSendGameData = function() end, function() end
    C_ChatInfo.SendChatMessage = C_ChatInfo.SendChatMessage or function() end
    C_ChatInfo.SendAddonMessageLogged = C_ChatInfo.SendAddonMessageLogged or function() end
    -- The base fixture controls hooks used by other APR features. CTL's native
    -- hooks are not needed for the deterministic bandwidth explicitly set here.
    local originalCreate = CreateFrame
    CreateFrame = function(...)
        local frame = originalCreate(...)
        frame.GetScript = frame.GetScript or function(self, name) return self.scripts[name] end
        frame.Show = frame.Show or function(self) self.shown = true end
        frame.Hide = frame.Hide or function(self) self.shown = false end
        frame.IsShown = frame.IsShown or function(self) return self.shown == true end
        return frame
    end
    dofile("APR-Core/libs/HereBeDragons/CallbackHandler-1.0/CallbackHandler-1.0.lua")
    dofile("APR-Core/libs/AceComm-3.0/ChatThrottleLib.lua")
    dofile("APR-Core/libs/AceComm-3.0/AceComm-3.0.lua")
    env.directCTL, env.directAceComm = ChatThrottleLib, LibStub("AceComm-3.0")
    ChatThrottleLib.HardThrottlingBeginTime = GetTime() - 100
    ChatThrottleLib.avail = 4000
    function env:PumpDirect(elapsed)
        local script = self.directCTL.Frame:GetScript("OnUpdate")
        if self.directCTL.Frame:IsShown() then script(self.directCTL.Frame, elapsed or 1) end
    end
    return env.directCTL, env.directAceComm
end

return DirectEnv
