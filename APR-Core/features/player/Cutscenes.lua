-- Installs movie/cinematic skip hooks, respecting addon settings, modifiers and Dontskipvid.
-- Delayed skips recheck preferences before touching the cinematic.

local function ShouldSkipCutscene(step)
    if IsModifierKeyDown() then
        return false
    end
    local profile = APR:GetSettingsProfile()
    if not profile or not profile.enableAddon or not profile.autoSkipCutScene then
        return false
    end
    if step and step.Dontskipvid then
        return false
    end
    return true
end

local function CancelCurrentMovie(step)
    if not ShouldSkipCutscene(step) then
        return
    end

    -- Defer past Blizzard's setup; recheck settings in case the addon was disabled.
    C_Timer.After(0, function()
        if ShouldSkipCutscene(APR:GetCurrentStep()) then
            CinematicFinished(Enum.CinematicType.GameMovie, true, false)
        end
    end)
end

hooksecurefunc("MovieFrame_PlayMovie", function(...)
    local step = APR:GetCurrentStep()
    CancelCurrentMovie(step)
end)

CinematicFrame:HookScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        if CinematicFrame:IsShown() and CinematicFrame.closeDialog and CinematicFrameCloseDialogConfirmButton then
            CinematicFrameCloseDialog:Hide()
        end
    end
end)

CinematicFrame:HookScript("OnKeyUp", function(self, key)
    if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
        if CinematicFrame:IsShown() and CinematicFrame.closeDialog and CinematicFrameCloseDialogConfirmButton then
            CinematicFrameCloseDialogConfirmButton:Click()
        end
    end
end)

APR.SceneCutterEventFrame = CreateFrame("Frame")
APR.SceneCutterEventFrame:RegisterEvent("CINEMATIC_START")
APR.SceneCutterEventFrame:SetScript("OnEvent", function(self, event, ...)
    local step = APR:GetCurrentStep()
    if not ShouldSkipCutscene(step) then return end
    C_Timer.After(0.5, function()
        if ShouldSkipCutscene(APR:GetCurrentStep()) then CinematicFrame_CancelCinematic() end
    end)
end)
