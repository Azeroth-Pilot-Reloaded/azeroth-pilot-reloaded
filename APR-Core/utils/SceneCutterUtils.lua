local function ShouldSkipCutscene(step)
    if IsModifierKeyDown() then
        return false
    end
    if not APR.settings.profile.autoSkipCutScene then
        return false
    end
    if step and step.Dontskipvidthen then
        return false
    end
    return true
end

local function CancelCurrentMovie(step)
    if not ShouldSkipCutscene(step) then
        return
    end

    -- Mimic the old behaviour by finishing the movie immediately.
    -- Using hooksecurefunc keeps MovieFrame_PlayMovie protected.
    C_Timer.After(0, function()
        CinematicFinished(Enum.CinematicType.GameMovie, true, false)
    end)
end

hooksecurefunc("MovieFrame_PlayMovie", function(...)
    local step = APR:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
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
    if not APR.settings.profile.enableAddon or not APR.settings.profile.autoSkipCutScene or IsModifierKeyDown() then return end
    local step = APR:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    if step and step.Dontskipvid then
        return
    end
    C_Timer.After(0.5, CinematicFrame_CancelCinematic)
end)
