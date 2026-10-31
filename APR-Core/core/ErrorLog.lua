-- Session-only diagnostics for errors whose message or stack references APR.
-- Repeated errors are grouped; neither locals nor unbounded histories are retained.
APR.ErrorLog = { entries = {}, limit = 100, revision = 0, provider = "unavailable" }
local Log = APR.ErrorLog
local capturing = false
local entriesByMessage = {}
local messagesFromAPR = {}
local connection
local nativePrevious, nativePending

local function Public(value)
    return not issecretvalue or not issecretvalue(value)
end

local function ReadableTable(value)
    return type(value) == "table" and Public(value)
end

local function PublicString(value, limit)
    if not Public(value) then return "" end
    return type(value) == "string" and value:sub(1, limit) or ""
end

local function PublicNumber(value)
    if Public(value) and type(value) == "number" and value == value and value > -math.huge and value < math.huge then
        return value
    end
end

local function Guard(collector, ...)
    if capturing then return end
    capturing = true
    -- Include argument collection, not just storage, in the diagnostics guard.
    pcall(collector, ...)
    capturing = false
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

local function Record(self, message, stack, occurrences, timestamp, attributedAddon)
    message, stack = PublicString(message, 4096), PublicString(stack, 12000)
    local entry = entriesByMessage[message]
    local source
    -- A retained message is immutable; generic messages still need a fresh stack attribution.
    if entry then source = messagesFromAPR[message] and "APR" else source = Related(message) end
    local fromMessage = source ~= nil
    source = source or Related(stack)
    -- Protected-action failures can contain only Blizzard paths. Preserve the
    -- client's explicit attribution without relying on translated error text.
    if not source and PublicString(attributedAddon, 128) == "APR" then source = "APR" end
    if not source then return end
    local now = PublicNumber(timestamp) or PublicNumber(time())
    if not now then return end
    if not entry then
        if #self.entries >= self.limit then
            local removed = table.remove(self.entries, 1)
            if removed then
                entriesByMessage[removed.message], messagesFromAPR[removed.message] = nil, nil
            end
        end
        entry = { message = message, stack = stack, source = source:match("([^/\\]+%.lua:%d+)") or "APR",
            count = 0, first = now }
        self.entries[#self.entries + 1] = entry
        entriesByMessage[message] = entry
        messagesFromAPR[message] = fromMessage or nil
    end
    occurrences = PublicNumber(occurrences)
    entry.count = occurrences and math.max(entry.count, occurrences) or entry.count + 1
    entry.last = now
    local route, player = APR.ActiveRoute, APR.PlayerID
    local routeName = PublicString(route, 4096)
    entry.route, entry.step = routeName ~= "" and routeName or nil, nil
    if routeName ~= "" and Public(player) and type(player) == "string" and ReadableTable(APRData) then
        local data = rawget(APRData, player)
        if ReadableTable(data) then entry.step = PublicNumber(rawget(data, route)) end
    end
    self.revision = self.revision + 1
end

function Log:Record(...)
    Guard(Record, self, ...)
end

local function ReadSession(provider)
    local getter = provider.GetSessionId
    if not Public(getter) then return end
    if type(getter) == "function" then return PublicNumber(getter(provider)) end
    if getter ~= nil then return end
    return false -- Older providers without a session getter retain their existing unfiltered behavior.
end

local function ReadBug(self, errorObject, provider, session)
    if not ReadableTable(provider) or not ReadableTable(errorObject) then return end
    if session == nil then session = ReadSession(provider) end
    if session == nil then return end
    if session ~= false and PublicNumber(errorObject.session) ~= session then return end
    Record(self, errorObject.message, errorObject.stack, PublicNumber(errorObject.counter), errorObject.time)
end

function Log:ReadBug(errorObject)
    Guard(ReadBug, self, errorObject, BugGrabber)
end

local function Disconnect(self)
    -- Stale callbacks keep only this small token, not the former provider/database graph.
    connection.provider = nil
    connection = nil
    self.provider = "unavailable"
end

local function ReadBoundBug(self, binding, value, byID)
    -- Binding identity is the generation token, including reconnection to the same provider object.
    if binding ~= connection then return end
    if not ReadableTable(BugGrabber) or binding.provider ~= BugGrabber then
        Disconnect(self)
        return
    end
    local provider = binding.provider
    if byID then
        if not Public(value) or (type(value) ~= "string" and type(value) ~= "number") then return end
        value = provider:GetErrorByID(value)
    end
    ReadBug(self, value, provider)
end

local function ConnectBugGrabber(self, provider, binding)
    if type(provider.setupCallbacks) == "function" then provider.setupCallbacks() end
    -- Legacy providers can also expose GetErrorByID; their explicit callback API takes priority.
    if type(provider.RegisterCallback) == "function" then
        provider.RegisterCallback(self, "BugGrabber_BugGrabbed", function(_, record)
            Guard(ReadBoundBug, self, binding, record, false)
        end)
    elseif type(provider.GetErrorByID) == "function" and ReadableTable(EventRegistry)
        and type(EventRegistry.RegisterCallback) == "function" then
        EventRegistry:RegisterCallback("BugGrabber.BugGrabbed", function(_, id)
            Guard(ReadBoundBug, self, binding, id, true)
        end, self)
    else
        return
    end
    connection = binding
    self.provider = "BugGrabber"
end

local function ImportBugs(self)
    local binding, provider = connection, connection.provider
    if binding.imported or type(provider.GetDB) ~= "function" then return end
    local database = provider:GetDB()
    if not ReadableTable(database) then return end
    -- Session readiness is checked before importing anything, so a retry cannot recount a partial import.
    local session = ReadSession(provider)
    if session == nil then return end
    local last = PublicNumber(#database)
    if not last then return end
    for offset = math.min(100, last) - 1, 0, -1 do
        -- An inaccessible record must not prevent the remaining bounded history from being collected.
        pcall(ReadBug, self, rawget(database, last - offset), provider, session)
    end
    binding.imported = true
end

local function CollectNative(self, message)
    if connection then
        if ReadableTable(BugGrabber) and connection.provider == BugGrabber then return end
        Disconnect(self)
    end
    if self.provider ~= "native" then
        if type(geterrorhandler) ~= "function" or geterrorhandler() ~= self.handler then return end
        self.provider = "native"
    end
    message = PublicString(message, 4096)
    local stack = ""
    -- Repeats retain their first stack; only generic text needs fresh native attribution.
    if not entriesByMessage[message] or not messagesFromAPR[message] then
        stack = debugstack and debugstack(3, 20, 20) or ""
    end
    Record(self, message, stack)
end

local function Connect(self)
    local provider = BugGrabber
    if connection and (not ReadableTable(provider) or connection.provider ~= provider) then
        Disconnect(self)
    end
    if not connection and ReadableTable(provider) then
        local binding = { provider = provider }
        pcall(ConnectBugGrabber, self, provider, binding)
        if binding ~= connection then binding.provider = nil end
    end
    if connection then
        ImportBugs(self) -- Failure/nil leaves the import pending for an existing startup event.
        return
    end
    if type(geterrorhandler) ~= "function" or type(seterrorhandler) ~= "function" then return end
    local current = geterrorhandler()
    if not self.handler then
        if type(current) ~= "function" then return end
        local previous = current
        nativePrevious, nativePending = previous, true
        self.handler = function(message, ...)
            Guard(CollectNative, self, message)
            return previous(message, ...)
        end
    end
    if current ~= self.handler and nativePending and current == nativePrevious then
        seterrorhandler(self.handler)
        current = geterrorhandler()
    end
    self.provider = current == self.handler and "native" or "unavailable"
    if self.provider == "native" then nativePending, nativePrevious = nil, nil end
end

function Log:Connect()
    Guard(Connect, self)
end

function Log:Clear()
    wipe(self.entries)
    wipe(entriesByMessage)
    wipe(messagesFromAPR)
    self.revision = self.revision + 1
end

-- Startup runs before APR initialization so its load errors can also be observed.
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_ACTION_BLOCKED")
events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
local function OnEvent(event, addonName, addonFunc)
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        if PublicString(addonName, 128) ~= "APR" then return end
        local stack = debugstack and debugstack(2, 20, 20) or ""
        Record(Log, event .. ": " .. PublicString(addonFunc, 512), stack, nil, nil, "APR")
        return
    end
    Connect(Log)
end
events:SetScript("OnEvent", function(_, event, addonName, addonFunc)
    Guard(OnEvent, event, addonName, addonFunc)
end)
Log:Connect()
