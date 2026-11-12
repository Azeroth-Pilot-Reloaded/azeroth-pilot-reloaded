dofile("tests/lua/route_ui_test_env.lua")
local oldStub = LibStub
function LibStub(name)
    local library = oldStub(name)
    library.GetLocale = function() return setmetatable({}, {__index = function(_, key) return key end}) end
    return library
end
dofile("APR-Core/ui/route/CurrentStep.lua")
local populated, opened = false, nil
function APR:WrapTextWithAppearanceColor(text) return text end
APR.Services = {GetText = function(_, key) return key end, PopulateMenu = function(_, menu) populated = menu.label == "FIND_NEAREST" end}
APR.Workspace = {Show = function(_, page) opened = page end}
local actions = {}
local root = {}
function root:CreateTitle() end
function root:CreateDivider() end
function root:CreateCheckbox() end
function root:CreateRadio() end
function root:SetEnabled() end
function root:CreateButton(label, callback)
    local item = setmetatable({label = label, callback = callback}, {__index = root})
    actions[#actions + 1] = item
    return item
end
APR.GetMenu({}, root)
assert(actions[1].label == "SHOW_MENU" and actions[2].label == "ROUTE")
assert(actions[3].label == "STATUS" and actions[4].label == "FIND_NEAREST" and populated)
actions[3].callback()
assert(opened == "status")
for _, item in ipairs(actions) do
    assert(item.label ~= "GF_TITLE" and item.label ~= "ABOUT_HELP" and item.label ~= "PROFILES")
end
assert(#actions > 4, "Existing window settings remain reachable")
print("Header services: ordered launchers, removed shortcuts, existing window settings and status action passed")
