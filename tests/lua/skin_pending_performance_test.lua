-- Reusing one protected control must not refresh the entire UI after combat.
local combat, events = false, nil
function InCombatLockdown() return combat end
function CreateFrame()
    local frame = {RegisterEvent = function() end}
    function frame:SetScript(_, callback) self.callback = callback end
    events = frame
    return frame
end
APR = {settings = {profile = {uiTheme = "wow"}}}
local skins, regions, fonts, bars, text = 0, 0, 0, 0, 0
function APR:ApplyNativeTheme(frame)
    assert(not combat)
    skins = skins + 1
    frame.styled = true
end
function APR:RefreshThemeRegions() regions = regions + 1 end
function APR:ApplyAllTextStyles() fonts = fonts + 1 end
function APR:RefreshStatusBarColors() bars = bars + 1 end
function APR:RefreshTextAppearance() text = text + 1 end
dofile("APR-Core/integrations/SkinRegistry.lua")
local controls = {}
for i = 1, 1000 do
    controls[i] = {}
    APR:RegisterSkinTarget(controls[i], "button")
end
assert(skins == 1000)
combat = true
for i = 1, 100 do APR:RegisterSkinTarget(controls[1], "button") end
local newControl = {}
APR:RegisterSkinTarget(newControl, "button")
assert(APR:AreSkinsPending() and not newControl.styled and skins == 1000)
combat = false
events.callback()
assert(newControl.styled and skins == 1001 and not APR:AreSkinsPending())
assert(regions == 0 and fonts == 0 and bars == 0,
    "Deferred control registration must never restyle every font/region/window")
events.callback()
assert(skins == 1001 and fonts == 0, "Further combat exits do no appearance work")

-- An actual appearance change during combat must still update all targets once.
combat = true
APR:RefreshRegisteredSkins(true)
APR:RefreshRegisteredSkins(true)
assert(APR:AreSkinsPending() and skins == 1001)
combat = false
events.callback()
assert(skins == 2002 and regions == 1 and fonts == 1 and bars == 1)
assert(not APR:AreSkinsPending())
events.callback()
assert(regions == 1 and fonts == 1 and bars == 1)
APR.nativeTextRefreshPending = true
events.callback()
assert(text == 1 and not APR.nativeTextRefreshPending, "Explicit text refresh remains supported")
print("Skin combat recovery: one deferred control avoids 1,000-target refresh; explicit theme changes still apply once")
