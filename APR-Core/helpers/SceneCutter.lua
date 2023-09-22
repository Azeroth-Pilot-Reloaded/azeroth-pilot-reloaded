-- Likely deals with automatically skipping cutscenes using PlayMovie_hook
local PlayMovie_hook = MovieFrame_PlayMovie
MovieFrame_PlayMovie = function(...)
    if (IsModifierKeyDown() or not APR.settings.profile.autoSkipCutScene) then
        PlayMovie_hook(...) --MovieFrame_PlayMovie, as previously stated
    else
        print("APR: " .. L["SKIPPED_CUTSCENE"])
        GameMovieFinished()
    end
end

CinematicFrame:HookScript("OnShow", function(self, ...)
    if not APR.settings.profile.enableAddon or not APR.settings.profile.autoSkipCutScene or IsModifierKeyDown() then return end
    if CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] then
        local step = APR.QuestStepList[APR.ActiveMap][APRData[APR.Realm][APR.Name][APR.ActiveMap]]
        if step and step["Dontskipvid"] then
            return
        end
    end
    CinematicFrame_CancelCinematic()
end)
