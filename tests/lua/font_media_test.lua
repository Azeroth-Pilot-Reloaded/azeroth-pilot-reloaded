local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local originalLibStub = LibStub
local names, paths, listReads, fetchReads = {}, {}, 0, 0
for index = 1, 10000 do
    local name = string.format("Synthetic shared font %05d", index)
    names[index], paths[name] = name, "Interface\\AddOns\\InventedMedia\\font" .. index .. ".ttf"
end
local defaultFont = names[1]
local media = {
    GetDefault = function() return defaultFont end,
    HashTable = function() error("Appearance pages must not copy the shared font catalog") end,
    List = function(_, kind)
        assert(kind == "font")
        listReads = listReads + 1
        return names
    end,
    Fetch = function(_, kind, name, noDefault)
        assert(kind == "font")
        fetchReads = fetchReads + 1
        return paths[name] or (not noDefault and paths[defaultFont]) or nil
    end,
}
function LibStub(name, ...)
    if name == "LibSharedMedia-3.0" then return media end
    return originalLibStub(name, ...)
end
function APR:ResolveUIFileAsset(path) return path end
function env.methods:SetFont(path, size, flags)
    self.font, self.fontSize, self.fontFlags = path, size, flags
    return true
end
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/TextStyles.lua")
dofile("APR-Core/utils/TextStyleUtils.lua")
local utils, profile = APR.TextStyleUtils, APR.settings.profile
profile.globalTextAppearance = APR:CreateTextAppearanceDefaults(false)
local values = utils:GetFontValues()
assert(values == utils:GetFontValues() and next(values) == nil)
assert(values[names[9999]] == names[9999] and values[false] == nil and values[""] == nil)
assert(values["A missing saved font"] == "A missing saved font",
    "An unavailable saved preference remains legible without catalog enumeration")
assert(listReads == 0 and fetchReads == 0, "Page labels do not list or resolve any media files")

-- Every declared text scope uses the same live catalog without a maintained
-- fixture inventory of guide names or separate hand-written font lists.
for scope, key in pairs(APR.TEXT_APPEARANCE_SCOPES) do
    local inherited = scope ~= "general"
    if inherited then profile[key] = APR:CreateTextAppearanceDefaults(true) end
    local option = utils:CreateAppearanceOptions(key, scope, 1, nil, inherited).args.font
    assert(option.dialogControl == "APRSettingsFontSelect" and option.values() == values)
    assert(option.values()[option.get()] == profile.globalTextAppearance.font)
end
assert(listReads == 0 and fetchReads == 0, "Building all appearance sections never scans the media index")
assert(utils:GetFontCatalog() == names and #utils:GetFontCatalog() == 10000)
local lateName = "A later addon font"
paths[lateName] = "Interface\\AddOns\\LaterMedia\\late.ttf"
table.insert(names, 1, lateName)
local current = utils:GetFontCatalog()
assert(current == names and current[1] == lateName and #current == 10001,
    "The next opening receives late media without invalidating copies or retaining listeners")
assert(values[lateName] == lateName)

-- Preserve global inheritance, and resolve newly shared paths through the
-- production renderer rather than interpreting font names as file paths.
profile.globalTextAppearance.font = lateName
profile.currentStepTextAppearance = APR:CreateTextAppearanceDefaults(true)
local option = utils:CreateAppearanceOptions("currentStepTextAppearance", "currentStep", 1, nil, true).args
assert(option.font.disabled() and option.font.get() == lateName)
local font = CreateFrame("Frame", nil, UIParent):CreateFontString()
APR:RegisterFontString(font, "currentStep")
assert(font.font == paths[lateName])
option.useGlobal.set(nil, false)
option.font.set(nil, "Synthetic shared font 09999")
assert(not option.font.disabled() and font.font == paths["Synthetic shared font 09999"])
assert(profile.globalTextAppearance.font == lateName, "A frame font override never changes global typography")
local savedMissing = "A font from a later loading addon"
option.font.set(nil, savedMissing)
assert(font.font == paths[defaultFont], "Absent shared fonts keep the renderer's normal fallback")
paths[savedMissing] = "Interface\\AddOns\\LaterMedia\\restored.ttf"
APR:RefreshTextAppearance("currentStep")
assert(font.font == paths[savedMissing], "A previously missing font resolves after late registration and refresh")

media.List = nil
local empty = utils:GetFontCatalog()
assert(type(empty) == "table" and #empty == 0 and empty == utils:GetFontCatalog())
media.List = function() return false end
assert(utils:GetFontCatalog() == empty, "Optional unavailable media data keeps a stable empty picker")
print("Shared fonts: lazy labels, all text scopes, borrowed late-registration catalog, inheritance and native path resolution passed")

-- Native setters invalidate text measurements even when their inputs are unchanged.
local fontWrites, colorWrites = 0, 0
function font:GetFont() return self.font, self.fontSize, self.fontFlags end
function font:GetTextColor() return unpack(self.testColor or {}) end
function font:SetTextColor(...) colorWrites = colorWrites + 1; self.testColor = {...} end
local setFont = font.SetFont
function font:SetFont(...) fontWrites = fontWrites + 1; return setFont(self, ...) end
APR:ApplyTextStyle(font)
fontWrites, colorWrites = 0, 0
for _ = 1, 1000 do APR:ApplyTextStyle(font) end
assert(fontWrites == 0 and colorWrites == 0, "Unchanged styles cannot repeatedly invalidate native fonts/colors")
font.fontSize, font.testColor = 99, {0.11, 0.22, 0.33, 0.44}
APR:ApplyTextStyle(font)
assert(fontWrites == 1 and colorWrites == 1 and font.fontSize ~= 99,
    "An external skin changing a reused font is detected and repaired")
