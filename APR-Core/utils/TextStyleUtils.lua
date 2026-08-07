local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LSM = LibStub("LibSharedMedia-3.0")

APR.TextStyleUtils = APR.TextStyleUtils or {}
local TextStyleUtils = APR.TextStyleUtils

TextStyleUtils.GLOBAL_PROFILE_KEY = APR.GLOBAL_TEXT_APPEARANCE_KEY or "globalTextAppearance"

TextStyleUtils.BASE_TEXT_COLORS = {
    { key = "color", name = L["TEXT_COLOR"] },
}

TextStyleUtils.FRAME_TEXT_COLORS = {
    { key = "color",        name = L["TEXT_COLOR"] },
    { key = "accentColor",  name = L["ACCENT_TEXT_COLOR"] },
    { key = "successColor", name = L["SUCCESS_TEXT_COLOR"] },
    { key = "warningColor", name = L["WARNING_TEXT_COLOR"] },
    { key = "errorColor",   name = L["ERROR_TEXT_COLOR"] },
    { key = "mutedColor",   name = L["MUTED_TEXT_COLOR"] },
}

local TEXT_STYLE_FLAGS = {
    ["NONE"] = L["FONT_STYLE_NONE"],
    ["OUTLINE"] = L["FONT_STYLE_OUTLINE"],
    ["THICKOUTLINE"] = L["FONT_STYLE_THICK_OUTLINE"],
    ["MONOCHROME"] = L["FONT_STYLE_MONOCHROME"],
    ["MONOCHROME,OUTLINE"] = L["FONT_STYLE_MONOCHROME_OUTLINE"],
}

function TextStyleUtils:GetFontValues()
    local values = {}
    for name in pairs(LSM:HashTable("font")) do
        values[name] = name
    end
    return values
end

function TextStyleUtils:GetAppearance(profileKey)
    local profile = APR:GetSettingsProfile()
    return profile and profile[profileKey]
end

function TextStyleUtils:SetAppearanceValue(profileKey, key, value, scope)
    local appearance = self:GetAppearance(profileKey)
    if not appearance then return end

    appearance[key] = value
    APR:RefreshTextAppearance(scope)
end

function TextStyleUtils:CreateAppearanceOptions(profileKey, scope, order, colorOptions, includeInheritance, inline)
    local args = {}
    local nextOrder = 1

    if includeInheritance then
        args.useGlobal = {
            order = nextOrder,
            type = "toggle",
            name = L["USE_GLOBAL_TEXT_STYLE"],
            desc = L["USE_GLOBAL_TEXT_STYLE_DESC"],
            width = "full",
            get = function()
                local appearance = self:GetAppearance(profileKey)
                return appearance and appearance.useGlobal ~= false
            end,
            set = function(_, value)
                local appearance = self:GetAppearance(profileKey)
                if appearance and not value then
                    local globalAppearance = self:GetAppearance(self.GLOBAL_PROFILE_KEY)
                    if globalAppearance then
                        appearance.font = globalAppearance.font
                        appearance.size = globalAppearance.size
                        appearance.flags = globalAppearance.flags
                    end
                end
                self:SetAppearanceValue(profileKey, "useGlobal", value, scope)
            end,
        }
        nextOrder = nextOrder + 1
    end

    local function IsTypographyInherited()
        local appearance = self:GetAppearance(profileKey)
        return includeInheritance and appearance and appearance.useGlobal ~= false
    end

    local function GetDisplayedTypography()
        local appearance = self:GetAppearance(profileKey)
        if IsTypographyInherited() then
            return self:GetAppearance(self.GLOBAL_PROFILE_KEY) or appearance
        end
        return appearance
    end

    args.font = {
        order = nextOrder,
        type = "select",
        name = L["FONT_FACE"],
        desc = L["FONT_FACE_DESC"],
        width = "full",
        values = function()
            return self:GetFontValues()
        end,
        get = function()
            local appearance = GetDisplayedTypography()
            return appearance and appearance.font
        end,
        set = function(_, value)
            self:SetAppearanceValue(profileKey, "font", value, scope)
        end,
        disabled = IsTypographyInherited,
    }
    nextOrder = nextOrder + 1

    args.flags = {
        order = nextOrder,
        type = "select",
        name = L["FONT_STYLE"],
        width = "full",
        values = TEXT_STYLE_FLAGS,
        get = function()
            local appearance = GetDisplayedTypography()
            return appearance and appearance.flags or "NONE"
        end,
        set = function(_, value)
            self:SetAppearanceValue(profileKey, "flags", value, scope)
        end,
        disabled = IsTypographyInherited,
    }
    nextOrder = nextOrder + 1

    args.size = {
        order = nextOrder,
        type = "range",
        name = L["FONT_SIZE"],
        min = 6,
        max = 32,
        step = 1,
        width = "full",
        get = function()
            local appearance = GetDisplayedTypography()
            return appearance and appearance.size or 12
        end,
        set = function(_, value)
            self:SetAppearanceValue(profileKey, "size", value, scope)
        end,
        disabled = IsTypographyInherited,
    }
    nextOrder = nextOrder + 1

    for _, definition in ipairs(colorOptions or {}) do
        local colorKey = definition.key
        args[colorKey] = {
            order = nextOrder,
            type = "color",
            name = definition.name,
            desc = definition.desc,
            hasAlpha = true,
            width = 1,
            get = function()
                local appearance = self:GetAppearance(profileKey)
                local color = appearance and appearance[colorKey] or { 1, 1, 1, 1 }
                return unpack(color)
            end,
            set = function(_, r, g, b, a)
                self:SetAppearanceValue(profileKey, colorKey, { r, g, b, a }, scope)
            end,
        }
        nextOrder = nextOrder + 1
    end

    return {
        order = order,
        type = "group",
        name = L["TEXT_APPEARANCE"],
        inline = inline ~= false,
        args = args,
    }
end
