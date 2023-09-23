-- Likely deals with automatically skipping cutscenes using PlayMovie_hook
local PlayMovie_hook = MovieFrame_PlayMovie
MovieFrame_PlayMovie = function(...)
    if (IsModifierKeyDown() or not APR.settings.profile.autoSkipCutScene) then
        PlayMovie_hook(...) --MovieFrame_PlayMovie, as previously stated
    else
        GameMovieFinished()
    end
end
APR.SceneCutterEventFrame = CreateFrame("Frame")
APR.SceneCutterEventFrame:RegisterEvent("CINEMATIC_START")
APR.SceneCutterEventFrame:SetScript("OnEvent", function(self, event, ...)
    if not APR.settings.profile.enableAddon or not APR.settings.profile.autoSkipCutScene or IsModifierKeyDown() then return end
    if CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] then
        local step = APR.QuestStepList[APR.ActiveMap][APRData[APR.Realm][APR.Name][APR.ActiveMap]]
        if step and step["Dontskipvid"] then
            return
        end
    end
    C_Timer.After(3, CinematicFrame_CancelCinematic)
end)
