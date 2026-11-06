local env = dofile("tests/lua/route_ui_test_env.lua")
local nativeOwner, nativeGenerator, nativeCalls, padCalls = nil, nil, 0, 0
MenuUtil = {
    CreateContextMenu = function(owner, generator)
        nativeOwner, nativeGenerator = owner, generator
        nativeCalls = nativeCalls + 1
    end,
}
local button = CurrentStepFrameSettingsButton
local click = button.scripts.OnClick
click(button, "LeftButton")
assert(
    nativeOwner == button and nativeGenerator == APR.GetMenu and nativeCalls == 1,
    "Mouse clients keep the full guide context menu and its original owner"
)

local enabled = true
APR.Gamepad = {
    IsEnabled = function() return enabled end,
    RunAction = function(_, action)
        assert(action == "menu")
        padCalls = padCalls + 1
    end,
}
click(button, "LeftButton")
APR.currentStep:ShowHeaderMenu(CurrentStepFrameHeader)
assert(
    padCalls == 2 and nativeCalls == 1,
    "Gear and header actions directly open the APR gamepad popup without creating a native context menu"
)
enabled = false
click(button, "LeftButton")
assert(nativeCalls == 2 and padCalls == 2, "Leaving gamepad mode restores the mouse context menu")
print("Gamepad header: gear/header entry points, native menu exclusion and mouse mode fallback passed")
