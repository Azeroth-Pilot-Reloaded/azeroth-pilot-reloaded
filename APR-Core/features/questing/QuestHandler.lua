-- Schedules bounded step-update batches and commits row transactions; domain handlers own the actual content.

-- Automatic completions request another pass instead of nesting UpdateStep calls.
-- Bound each batch so a long run of completed objectives also yields to the UI.
function APR:UpdateStep()
    self.stepUpdatePending = true
    if self.stepUpdateRunning then return end
    if self.stepUpdateTimer then
        self.stepUpdateTimer:Cancel()
        self.stepUpdateTimer = nil
    end

    self.stepUpdateRunning = true
    local started = debugprofilestop()
    local passes = 0
    repeat
        self.stepUpdatePending = false
        local profileStart = self:StartPerformanceSample()
        if self.currentStep.BeginContentUpdate then self.currentStep:BeginContentUpdate() end
        local ok, err = pcall(self.RenderCurrentStep, self)
        if self.currentStep.EndContentUpdate then
            local rendered, renderError = pcall(self.currentStep.EndContentUpdate, self.currentStep,
                ok and not self.stepUpdatePending)
            if not rendered then ok, err = false, renderError end
        end
        self:FinishPerformanceSample("UpdateStepPass", profileStart)
        if not ok then
            self.stepUpdateRunning = false
            self.stepUpdatePending = false
            error(err, 0)
        end
        passes = passes + 1
    until not self.stepUpdatePending or passes >= 25 or debugprofilestop() - started >= 3
    self.stepUpdateRunning = false

    if self.stepUpdatePending then
        local context = self:CaptureStepContext()
        self.stepUpdateTimer = C_Timer.NewTimer(0, function()
            self.stepUpdateTimer = nil
            if self:IsStepContextCurrent(context) then self:UpdateStep() end
        end)
    end
end
