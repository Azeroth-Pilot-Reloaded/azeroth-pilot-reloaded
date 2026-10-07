-- Resolves character-specific preferences and profile resets through APR-owned AceDB state.
-- Persisted setting names stay stable even when internal Lua names change.

-- Keep AceDB character scope behind APR so integrations never depend on a generic global.
function APR:GetCharacterSettings()
    local database = self.settings and self.settings.db
    return database and database.char
end

--- Get the effective heirloom warning value for the current character.
-- Checks character-specific override first, then falls back to profile setting.
-- @return boolean - true to hide the heirloom warning, false to show it
function APR:GetHeirloomWarning()
    if self:GetGameVersion() == self.GAME_VERSIONS.Forever then
        return true
    end
    local character = self:GetCharacterSettings()
    if character and character.showHeirloomWarning ~= nil then
        return character.showHeirloomWarning
    end
    return APR.settings.profile.heirloomWarning
end

--- Set the heirloom warning value for the current character.
-- Sets at character level to override the shared profile value.
-- @param value boolean - true to hide the heirloom warning, false to show it
function APR:SetHeirloomWarning(value)
    -- Set at character level to override profile
    local character = self:GetCharacterSettings()
    if character then
        character.showHeirloomWarning = value
    end
end

--- Get whether route suggestion popup is disabled for this character.
-- @return boolean - true to disable route suggestion popup, false to show it
function APR:GetRouteSuggestionDontAsk()
    local character = self:GetCharacterSettings()
    if character and character.routeSuggestionDontAsk ~= nil then
        return character.routeSuggestionDontAsk
    end
    return false
end

--- Set whether route suggestion popup is disabled for this character.
-- @param value boolean
function APR:SetRouteSuggestionDontAsk(value)
    local character = self:GetCharacterSettings()
    if character then
        character.routeSuggestionDontAsk = value and true or false
    end
end

-- Reset character-to-profile assignments while retaining the saved Default profile
-- and character-only preferences; routes/progress live in separate SavedVariables.
--- @return nil
function APR:ResetAllProfilesToDefault()
    local saved = APRSettings or {}
    local database = self.settings and self.settings.db
    local charCopy = APR:DeepCopyTable(saved.char or (database and database.sv and database.sv.char) or {})
    local defaultProfileCopy = APR:DeepCopyTable(
        (saved.profiles and saved.profiles.Default) or
        (database and database.sv and database.sv.profiles and database.sv.profiles.Default) or
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
