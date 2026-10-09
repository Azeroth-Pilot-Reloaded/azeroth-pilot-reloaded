-- Blizzard exposes one lazy launcher, with no nested settings; all editing happens in the workspace.
dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/config/Config.lua")
APR.title = "APR"
local registrations, opened, closed = 0, 0, 0
local category = {GetID = function() return 42 end}
Settings = {
    RegisterCanvasLayoutCategory = function(panel, name)
        assert(panel == APR.Options and name == APR.title)
        return category
    end,
    RegisterAddOnCategory = function(value) assert(value == category); registrations = registrations + 1 end,
    OpenToCategory = function(id) assert(id == 42); opened = opened + 1 end,
}
APR.settings:CreateBlizzardLauncher()
APR.settings:CreateBlizzardLauncher()
assert(registrations == 1 and not APR.Options.logo, "One category; visual content is lazy")
APR.Options.scripts.OnShow()
local logo, button = APR.Options.logo, APR.Options.open
APR.Options.scripts.OnShow()
assert(APR.Options.logo == logo and APR.Options.open == button, "Reopening cannot duplicate controls")
assert(APR.Options.title:GetText() == APR.title)
APR.settings:OpenSettings(APR.title)
assert(opened == 1)
SettingsPanel = {Hide = function() closed = closed + 1 end}
local workspaceOpens = 0
APR.Workspace = {Show = function(_, page)
    assert(page == "options"); workspaceOpens = workspaceOpens + 1
    SettingsPanel:Hide()
end, Hide = function() end}
button.scripts.OnClick(button)
assert(workspaceOpens == 1 and closed == 1, "Launcher opens APR and closes Blizzard")

-- Legacy clients register the same simple panel rather than loading AceConfig categories.
APR.Options, APR.settings.category, Settings, SettingsPanel, APR.Workspace = nil, nil, nil, nil, nil
InterfaceOptions_AddCategory = function(panel) assert(panel == APR.Options); registrations = registrations + 1 end
APR.settings:CreateBlizzardLauncher()
assert(registrations == 2)
function InterfaceOptionsFrame_OpenToCategory(panel) assert(panel == APR.Options); opened = opened + 1 end
APR.settings:OpenSettings(APR.title)
assert(opened == 2)
InterfaceOptionsFrame = {Hide = function() closed = closed + 1 end}
APR.settings:CloseSettings()
assert(closed == 2)
print("Blizzard settings: one lazy launcher, workspace handoff and modern/legacy registration passed")
