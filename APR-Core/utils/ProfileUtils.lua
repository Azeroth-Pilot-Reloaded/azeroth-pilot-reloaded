--[[
    ProfileUtils.lua

    Utilities for handling profile and character-specific settings.
    Provides helper functions to manage per-character overrides on shared profile settings.
]]

--- Get the effective heirloom warning value for the current character.
-- Checks character-specific override first, then falls back to profile setting.
-- @return boolean - true to hide the heirloom warning, false to show it
function APR:GetHeirloomWarning()
    if SettingsDB and SettingsDB.char and SettingsDB.char.showHeirloomWarning ~= nil then
        return SettingsDB.char.showHeirloomWarning
    end
    return APR.settings.profile.heirloomWarning
end

--- Set the heirloom warning value for the current character.
-- Sets at character level to override the shared profile value.
-- @param value boolean - true to hide the heirloom warning, false to show it
function APR:SetHeirloomWarning(value)
    -- Set at character level to override profile
    if SettingsDB and SettingsDB.char then
        SettingsDB.char.showHeirloomWarning = value
    end
end

--- Get whether route suggestion popup is disabled for this character.
-- @return boolean - true to disable route suggestion popup, false to show it
function APR:GetRouteSuggestionDontAsk()
    if SettingsDB and SettingsDB.char and SettingsDB.char.routeSuggestionDontAsk ~= nil then
        return SettingsDB.char.routeSuggestionDontAsk
    end
    return false
end

--- Set whether route suggestion popup is disabled for this character.
-- @param value boolean
function APR:SetRouteSuggestionDontAsk(value)
    if SettingsDB and SettingsDB.char then
        SettingsDB.char.routeSuggestionDontAsk = value and true or false
    end
end

--- Resets all stored profiles to their default configuration.
--- This restores default settings for every profile managed by APR.
--- @return nil
function APR:ResetAllProfilesToDefault()
    local saved = APRSettings or {}
    local charCopy = APR:copyTable(saved.char or (SettingsDB and SettingsDB.sv and SettingsDB.sv.char) or {})
    local defaultProfileCopy = APR:copyTable(
        (saved.profiles and saved.profiles.Default) or
        (SettingsDB and SettingsDB.sv and SettingsDB.sv.profiles and SettingsDB.sv.profiles.Default) or
        {}
    )

    APRSettings = {
        char = charCopy,
        profileKeys = {},
        profiles = {
            Default = defaultProfileCopy,
        },
    }
    C_UI.Reload()
end
