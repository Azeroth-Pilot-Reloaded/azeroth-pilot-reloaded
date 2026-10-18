-- Source wrappers cover locals and callbacks, including cached references.
-- No runtime debug hooks or modifications to Blizzard/third-party functions.
APRInstrumentation = {enabled = false, debug = false, registry = {}, registered = 0}
local D = APRInstrumentation
local main = {depth = 0, frames = {}, paused = 0}
local threads = setmetatable({}, {__mode = "k"})
local LOG_LIMIT = 1000

local function Context()
    local thread = coroutine.running()
    if not thread then return main end
    local context = threads[thread]
    if not context then
        context = {depth = 0, frames = {}, paused = 0, thread = thread}
        threads[thread] = context
    end
    return context
end

function D.CurrentName()
    local context = Context()
    local frame = context.frames[context.depth]
    return frame and frame.name
end

-- Bounded single-line values; never retain gameplay tables or call metamethods.
function D.Value(value, depth, visited)
    if canaccessvalue and not canaccessvalue(value) then return "<unavailable>" end
    if issecretvalue and issecretvalue(value) then return "<unavailable>" end
    local kind = type(value)
    if kind == "string" then return (value:gsub("[\r\n\t]", " "):gsub("|", "||")):sub(1, 240) end
    if kind == "number" or kind == "boolean" or kind == "nil" then return tostring(value) end
    if kind ~= "table" then return "<" .. kind .. ">" end
    if canaccesstable and not canaccesstable(value) then return "<unavailable>" end
    depth, visited = depth or 0, visited or {}
    if visited[value] then return "<cycle>" end
    if depth >= 2 then return "{…}" end
    visited[value] = true
    local entries, count = {}, 0
    for key, item in pairs(value) do
        count = count + 1
        if count > 8 then entries[#entries + 1] = "…"; break end
        entries[#entries + 1] = D.Value(key, depth + 1, visited) .. "=" .. D.Value(item, depth + 1, visited)
    end
    table.sort(entries)
    visited[value] = nil
    return "{" .. table.concat(entries, ", ") .. "}"
end

function D.ResetLog()
    APRData = APRData or {}
    APRData.DebugLog = {entries = {}, cursor = 0, count = 0, total = 0, startedAt = GetTime(), limit = LOG_LIMIT}
end

function D.Record(kind, source, message, data, duration, ownMs, failed)
    if not APRData or not APRData.DebugLog then D.ResetLog() end
    local log, now = APRData.DebugLog, GetTime()
    local route = APR and APR.ActiveRoute
    local progress = APR and APR.PlayerID and APRData[APR.PlayerID]
    local step = progress and route and progress[route]
    message = type(message) ~= "nil" and D.Value(message) or ""
    data = type(data) ~= "nil" and D.Value(data) or nil
    source = source or D.CurrentName() or "APR"
    local previous = log.entries[log.cursor]
    log.total = log.total + 1
    if previous and previous.kind == kind and previous.source == source and previous.message == message
        and previous.data == data and previous.route == route and previous.step == step and previous.failed == failed then
        previous.count, previous.lastAt = previous.count + 1, now
        previous.ms = (previous.ms or 0) + (duration or 0)
        previous.maxMs = math.max(previous.maxMs or 0, duration or 0)
        previous.selfMs = (previous.selfMs or 0) + (ownMs or 0)
        return previous
    end
    log.cursor = log.cursor % LOG_LIMIT + 1
    local entry = {time = now, lastAt = now, kind = kind, source = source, name = source,
        message = message, data = data, route = route, step = step, count = 1,
        ms = duration, selfMs = ownMs, maxMs = duration, failed = failed}
    log.entries[log.cursor], log.count = entry, math.min(LOG_LIMIT, log.count + 1)
    return entry
end

function D.Message(kind, message, data, force, categoryEnabled)
    if not D.enabled and not force and not categoryEnabled then return end
    local entry = D.Record(kind, nil, message, data)
    if APR and APR.performanceLogging then
        APR.performanceBreadcrumb, APR.performanceBreadcrumbAt = D.Value(message), GetTime()
    end
    if force and entry then
        print(string.format("[APR %s] %s%s", kind, entry.message, entry.data and (" | " .. entry.data) or ""))
    end
end

local function Begin(name)
    local context = Context()
    context.depth = context.depth + 1
    local frame = context.frames[context.depth] or {}
    context.frames[context.depth] = frame
    frame.name, frame.started, frame.paused = name, debugprofilestop(), context.paused
    frame.children, frame.depth = 0, context.depth
    frame.log = APRData and APRData.PerformanceLog
    return context, frame
end

local function End(context, frame, failure)
    -- Retire scopes unwound by a pcall inside a coroutine.
    while context.depth > frame.depth do End(context, context.frames[context.depth], "unwound") end
    local finished = debugprofilestop()
    local elapsed = math.max(0, finished - frame.started - (context.paused - frame.paused))
    local own = math.max(0, elapsed - frame.children)
    context.depth = frame.depth - 1
    local parent = context.frames[context.depth]
    if APR and APR.performanceLogging and APRData and frame.log == APRData.PerformanceLog then
        APR:RecordPerformanceDuration(frame.name, elapsed, nil, parent and parent.name, own, failure)
    end
    if D.debug or failure then
        D.Record(failure and "ERROR" or "CALL", frame.name, failure, nil, elapsed, own, failure ~= nil)
    end
    local overhead = math.max(0, debugprofilestop() - finished)
    if parent then parent.children = parent.children + elapsed + overhead end
    if APR and APR.performanceLogging and APRData and frame.log == APRData.PerformanceLog then
        frame.log.observerMs = (frame.log.observerMs or 0) + overhead
    end
    frame.log = nil -- Reused stack slots must not retain previous captures.
end

local function Finish(context, frame, ok, ...)
    End(context, frame, not ok and D.Value((...)) or nil)
    if not ok then error((...), 0) end
    return ...
end

local function FinishCoroutine(context, frame, ...)
    End(context, frame)
    return ...
end

local function FinishObserver(context, frame, ok, ...)
    D.suspended = false
    return Finish(context, frame, ok, ...)
end

function D.Wrap(name, original)
    if not D.registry[name] then D.registry[name], D.registered = true, D.registered + 1 end
    local observer = name:find("APR-Core/ui/panels/PerformanceDashboard.lua:", 1, true) == 1
        or name:find("APR-Core/ui/panels/PerformanceResources.lua:", 1, true) == 1
    return function(...)
        if not D.enabled or D.suspended then return original(...) end
        local context, frame = Begin(name)
        if observer and not context.thread then
            -- Measure the viewer as a root, without letting its own drawing and
            -- filtering overwrite the gameplay log it is trying to display.
            D.suspended = true
            return FinishObserver(context, frame, pcall(original, ...))
        end
        if context.thread then
            -- Lua 5.1 cannot yield through pcall; Resume handles escaping errors.
            return FinishCoroutine(context, frame, original(...))
        end
        return Finish(context, frame, pcall(original, ...))
    end
end

function D.Yield(...)
    if not D.enabled then return coroutine.yield(...) end
    local context = Context()
    context.suspendedAt = debugprofilestop()
    return coroutine.yield(...)
end

local function Resumed(thread, parent, started, ok, ...)
    local context = threads[thread]
    if not ok and context then
        while context.depth > 0 do End(context, context.frames[context.depth], D.Value((...))) end
    end
    if parent then parent.children = parent.children + math.max(0, debugprofilestop() - started) end
    return ok, ...
end

function D.Resume(thread, ...)
    if not D.enabled then return coroutine.resume(thread, ...) end
    local context = threads[thread]
    if context and context.suspendedAt then
        context.paused = context.paused + debugprofilestop() - context.suspendedAt
        context.suspendedAt = nil
    end
    local caller = Context()
    return Resumed(thread, caller.frames[caller.depth], debugprofilestop(), coroutine.resume(thread, ...))
end

local function ProtectedResult(context, depth, ok, ...)
    if not ok then
        while context.depth > depth do End(context, context.frames[context.depth], D.Value((...))) end
    end
    return ok, ...
end

-- APR-owned pcall sites restore coroutine scopes even when an error is caught.
function D.PCall(callback, ...)
    if not D.enabled then return pcall(callback, ...) end
    local context = Context()
    return ProtectedResult(context, context.depth, pcall(callback, ...))
end
