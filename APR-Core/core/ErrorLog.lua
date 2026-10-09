-- Session-only diagnostics for errors whose message or stack references APR.
-- Repeated errors are grouped; neither locals nor unbounded histories are retained.
APR.ErrorLog = { entries = {}, limit = 100, revision = 0, provider = "unavailable" }
local Log = APR.ErrorLog
local capturing = false

local function PublicString(value, limit)
    if issecretvalue and issecretvalue(value) then return "" end
    return type(value) == "string" and value:sub(1, limit) or ""
end

local function Related(text)
    for line in text:gmatch("[^\n]+") do
        local path = line:lower():gsub("\\", "/")
        -- Our observing handler is on every stack; it must not attribute unrelated errors to APR.
        if not path:find("apr/core/errorlog.lua", 1, true) and not path:find("apr-core/core/errorlog.lua", 1, true)
            and (path:find("addons/apr/", 1, true) or path:find("@apr/", 1, true)) then
            return line
        end
    end
end

function Log:Record(message, stack, occurrences, timestamp)
    message, stack = PublicString(message, 4096), PublicString(stack, 12000)
    local source = Related(message) or Related(stack)
    if not source then return end
    local entry
    for _, candidate in ipairs(self.entries) do
        if candidate.message == message then entry = candidate; break end
    end
    local now = type(timestamp) == "number" and timestamp or time()
    if not entry then
        if #self.entries >= self.limit then table.remove(self.entries, 1) end
        entry = { message = message, stack = stack, source = source:match("([^/\\]+%.lua:%d+)") or "APR",
            count = 0, first = now }
        self.entries[#self.entries + 1] = entry
    end
    entry.count = type(occurrences) == "number" and math.max(entry.count, occurrences) or entry.count + 1
    entry.last = now
    entry.route = APR.ActiveRoute
    entry.step = APRData and APR.PlayerID and APR.ActiveRoute and APRData[APR.PlayerID] and APRData[APR.PlayerID][APR.ActiveRoute]
    self.revision = self.revision + 1
end

local function Capture(message, stack, count, timestamp)
    if capturing then return end
    capturing = true
    -- Diagnostics must never prevent WoW or an installed error handler from showing the original error.
    pcall(Log.Record, Log, message, stack, count, timestamp)
    capturing = false
end

function Log:ReadBug(errorObject)
    if type(errorObject) ~= "table" then return end
    if BugGrabber.GetSessionId and errorObject.session ~= BugGrabber:GetSessionId() then return end
    Capture(errorObject.message, errorObject.stack, errorObject.counter, errorObject.time)
end

function Log:Connect()
    if BugGrabber and self.provider ~= "BugGrabber" then
        if BugGrabber.GetErrorByID and EventRegistry then
            EventRegistry:RegisterCallback("BugGrabber.BugGrabbed", function(_, id)
                local ok, record = pcall(BugGrabber.GetErrorByID, BugGrabber, id)
                if ok then self:ReadBug(record) end
            end, self)
        else
            if BugGrabber.setupCallbacks then BugGrabber.setupCallbacks() end
            if not BugGrabber.RegisterCallback then return end
            BugGrabber.RegisterCallback(self, "BugGrabber_BugGrabbed", function(_, record) self:ReadBug(record) end)
        end
        self.provider = "BugGrabber"
        local database = BugGrabber.GetDB and BugGrabber:GetDB()
        if type(database) == "table" then
            for index = math.max(1, #database - 99), #database do self:ReadBug(database[index]) end
        end
        return
    end
    if self.handler or self.provider == "BugGrabber" or not geterrorhandler or not seterrorhandler then return end
    local previous = geterrorhandler()
    if type(previous) ~= "function" then return end
    self.handler = function(message, ...)
        if self.provider == "native" and not capturing then
            local stack = debugstack and debugstack(3, 20, 20) or ""
            Capture(message, stack)
        end
        return previous(message, ...)
    end
    seterrorhandler(self.handler)
    self.provider = geterrorhandler() == self.handler and "native" or "unavailable"
end

function Log:Clear()
    wipe(self.entries)
    self.revision = self.revision + 1
end

-- Startup runs before APR initialization so its load errors can also be observed.
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function() Log:Connect() end)
Log:Connect()
