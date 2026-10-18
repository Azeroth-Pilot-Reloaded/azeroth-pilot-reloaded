-- Lifecycle for source instrumentation. Cached callbacks keep their identity.
function APR:SetPerformanceScopes(enabled)
    local diagnostic = APRInstrumentation
    if not diagnostic then return end
    diagnostic.enabled = enabled == true or diagnostic.debug
    local log = APRData and APRData.PerformanceLog
    if log then
        log.coverage, log.excluded, log.observers = diagnostic.coverage, diagnostic.excluded, diagnostic.observers
        log.registeredFunctions = diagnostic.registered
    end
end

function APR:SetDebugCapture(enabled)
    local diagnostic = APRInstrumentation
    if not diagnostic then return end
    diagnostic.debug = enabled == true
    diagnostic.enabled = diagnostic.debug or self.performanceLogging == true
    self.debugLogging = diagnostic.debug
    if self.settings and self.settings.profile then self.settings.profile.debug = diagnostic.debug end
    if enabled then diagnostic.ResetLog() end
end

function APR:RecordPerformanceBreadcrumb(message)
    if not self.performanceLogging then return end
    self.performanceBreadcrumb = APRInstrumentation and APRInstrumentation.Value(message) or tostring(message):sub(1, 240)
    self.performanceBreadcrumbAt = GetTime()
end

function APR:GetDiagnosticRows(query)
    local log, rows = APRData and APRData.DebugLog, {}
    if not log then return rows end
    query = string.lower(query or "")
    for offset = 0, log.count - 1 do
        local entry = log.entries[(log.cursor - offset - 1) % log.limit + 1]
        local text = entry.source .. " " .. entry.kind .. " " .. entry.message .. " " .. (entry.data or "")
            .. " " .. (entry.route or "")
        if text:lower():find(query, 1, true) then rows[#rows + 1] = entry end
    end
    return rows
end
