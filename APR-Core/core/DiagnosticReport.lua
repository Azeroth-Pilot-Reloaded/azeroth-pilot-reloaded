-- Human-readable export. Keep formatting outside the measured code path.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local function Scope(name)
    return (name or "APR"):gsub("APR%-Core/", ""):gsub("#%d+$", "")
end

local function FormatResourceNumber(value)
    return value and string.format("%.3f", value) or "-"
end

function APR:FormatDiagnosticEntry(entry, start)
    local context = entry.route and (" | " .. entry.route .. " / " .. tostring(entry.step or "?")) or ""
    local repeats = entry.count > 1 and string.format(" ×%d (%.3fs, max %.3f ms)", entry.count,
        (entry.lastAt or entry.time) - entry.time, entry.maxMs or 0) or ""
    local duration = entry.ms and string.format(" | %.3f ms (self %.3f)", entry.ms, entry.selfMs or entry.ms) or ""
    return string.format("+%08.3fs [%-5s] %s%s%s%s%s%s", entry.time - start,
        entry.kind, Scope(entry.source), entry.message ~= "" and (" | " .. entry.message) or "",
        entry.data and (" | " .. entry.data) or "", duration, repeats, context)
end

function APR:BuildDiagnosticReport()
    local perf, debug = APRData and APRData.PerformanceLog, APRData and APRData.DebugLog
    local lines = { "APR - " .. L["UI_DIAGNOSTIC_REPORT"], L["UI_PERF_CAPTURE_HELP"], "" }
    local currentRevision = APRInstrumentation and APRInstrumentation.revision or "unknown"
    lines[#lines + 1] = "Diagnostics revision: " .. currentRevision
    if perf then
        local debugMode = perf.debugCallsDuringCapture
        lines[#lines + 1] = "Capture revision: " .. (perf.diagnosticRevision or "unknown (older capture)")
            .. " | debug calls during capture: " .. (debugMode == nil and "unknown" or debugMode and "yes" or "no")
    end
    if debug then lines[#lines + 1] = "Journal revision: " .. (debug.revision or "unknown (older journal)") end
    local covered, files, helpers = 0, 0, 0
    for _, file in pairs(APRInstrumentation and APRInstrumentation.coverage or {}) do
        covered, files = covered + file.instrumented, files + 1
        helpers = helpers + file.diagnosticHelpers
    end
    lines[#lines + 1] = string.format(L["UI_DIAGNOSTIC_COVERAGE"], covered, files, helpers)
    local exclusions = {}
    for path, reason in pairs(APRInstrumentation and APRInstrumentation.excluded or {}) do
        exclusions[#exclusions + 1] = "  " .. path .. ": " .. reason
    end
    for path, reason in pairs(APRInstrumentation and APRInstrumentation.observers or {}) do
        exclusions[#exclusions + 1] = "  " .. path .. ": " .. reason
    end
    table.sort(exclusions)
    for _, text in ipairs(exclusions) do lines[#lines + 1] = text end
    if perf then
        local duration = math.max(0, (perf.stoppedAt or perf.lastAt or perf.startedAt) - perf.startedAt)
        lines[#lines + 1] = string.format("Capture: %.3f s | recorder overhead: %.3f ms (%.2f%% of wall time)",
            duration, perf.observerMs or 0, duration > 0 and (perf.observerMs or 0) / (duration * 10) or 0)
        lines[#lines + 1] = "\n" .. L["UI_RESOURCE_CALLS_TAB"] .. " - " .. L["UI_PERF_SELF_TIME"]
        lines[#lines + 1] = "calls | self ms | total ms | max ms | source"
        for _, row in ipairs(self:GetPerformanceRows("summary", "selfMs")) do
            lines[#lines + 1] = string.format("%6d | %9s | %9.3f | %8.3f | %s", row.count,
                row.selfMs and string.format("%.3f", row.selfMs) or "-", row.totalMs, row.maxMs, Scope(row.name))
        end
        lines[#lines + 1] = "\n" .. L["UI_COUNTERS"]
        for _, row in ipairs(self:GetPerformanceRows("counters")) do
            lines[#lines + 1] = string.format("%8d | %s", row.count, row.name)
        end
        lines[#lines + 1] = "\n" .. L["UI_RESOURCE_TAB"]
        lines[#lines + 1] = "time | CPU ms/frame (average) | client peak ms | FPS | memory KB | route / step"
        local resources = perf.resources
        if resources then
            for offset = resources.count - 1, 0, -1 do
                local sample = resources.samples[(resources.cursor - offset - 1) % 600 + 1]
                lines[#lines + 1] = string.format("+%.3fs | %s | %s | %s | %s | %s / %s",
                    sample.time - perf.startedAt, FormatResourceNumber(sample.cpuMs), FormatResourceNumber(sample.peakFrameMs),
                    FormatResourceNumber(sample.fps), FormatResourceNumber(sample.memoryKB),
                    sample.route or "-", tostring(sample.step or "?"))
            end
        end
        lines[#lines + 1] = "\n" .. L["UI_SLOW_CALLS"]
        local slow = self:GetPerformanceRows("slow")
        for i = #slow, 1, -1 do
            local row = slow[i]
            lines[#lines + 1] = string.format("+%.3fs | %.3f ms | %s | %s / %s\n  <- %s%s",
                row.time - perf.startedAt, row.ms, Scope(row.name), row.route or "-", tostring(row.step or "?"),
                Scope(row.parent), row.breadcrumb and (" | " .. row.breadcrumb) or "")
        end
        lines[#lines + 1] = "\n" .. L["UI_RESOURCE_FRAME_SPIKES"]
        lines[#lines + 1] =
        "Previous-frame APR roots include capture overhead; correlation is not proof of causation. Missing attribution is unknown, not zero."
        local frames = perf.frames
        if frames then
            for offset = #frames.samples - 1, 0, -1 do
                local row = frames.samples[(frames.cursor - offset - 1) % 100 + 1]
                lines[#lines + 1] = string.format("+%.3fs | %.3f ms | baseline %.3f ms | %s / %s",
                    row.time - perf.startedAt, row.ms, row.baselineMs, row.route or "-", tostring(row.step or "?"))
                if row.aprMs then
                    lines[#lines + 1] = string.format("  APR %.3f ms / %d roots at +%.3fs | largest %.3f ms: %s",
                        row.aprMs, row.aprCalls, row.aprAt - perf.startedAt, row.aprPeakMs, Scope(row.aprSource))
                end
            end
        end
    end
    lines[#lines + 1] = "\n" .. L["UI_DIAGNOSTIC_LOG"]
    if debug then
        lines[#lines + 1] = string.format(L["UI_DIAGNOSTIC_RETAINED"], debug.count, debug.total)
        lines[#lines + 1] = string.format(
            "%d fast calls aggregated by source over 1 s; all calls remain counted in performance metrics.",
            debug.aggregatedCalls or 0)
        local rows = self:GetDiagnosticRows()
        for i = #rows, 1, -1 do lines[#lines + 1] = self:FormatDiagnosticEntry(rows[i], debug.startedAt) end
    end
    local finder = self.partyFinder
    if finder and finder.GetTrafficRows then
        lines[#lines + 1] = "\nAPRFindV1 | time | TX/RX | kind | channel | peer | result | payload"
        local channel = self.CommunicationChannel
        lines[#lines + 1] = "APR channel: " .. tostring(channel and channel.status) .. " / " .. tostring(channel and channel.id)
        for _, row in ipairs(finder:GetTrafficRows()) do
            lines[#lines + 1] = string.format("%.3f | %s | %s | %s | %s | %s | %s", row.time,
                row.direction, row.kind, row.channel, row.peer, row.result, row.wire)
        end
    end
    return table.concat(lines, "\n")
end
