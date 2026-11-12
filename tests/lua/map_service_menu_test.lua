APR = {
    settings = {profile = {enableAddon = true}},
    NavigationData = {
        GetText = function(_, key) return key == "FIND_NEAREST" and "Nearest service" or key end,
        GetServiceChoices = function()
            return {{label = "Synthetic bank", query = {service = "bank"}}}
        end,
        IsServiceBranch = function() return false end,
    },
}
dofile("APR-Core/features/navigation/Services.lua")
local services = APR.Services
Menu = nil
assert(not services:RegisterMapMenu(), "Clients without the native extension API retain other service entry points")
local registered, callback = 0, nil
Menu = {ModifyMenu = function(tag, generator)
    assert(tag == "MENU_WORLD_MAP_TRACKING", "Extend the world-map tracking/filter menu")
    registered, callback = registered + 1, generator
end}
assert(services:RegisterMapMenu() and services:RegisterMapMenu() and registered == 1)
local function description()
    local menu = {items = {}, dividers = 0}
    function menu:CreateDivider() self.dividers = self.dividers + 1 end
    function menu:CreateButton(label, action)
        local child = description()
        child.label, child.action = label, action
        self.items[#self.items + 1] = child
        return child
    end
    return menu
end
local selected
function services:Find(query) selected = query.service end
local root = description()
callback({}, root)
assert(root.dividers == 1 and #root.items == 1)
assert(root.items[1].label == "APR - Nearest service")
assert(root.items[1].items[1].label == "Synthetic bank", "Use the existing service submenu builder")
root.items[1].items[1].action()
assert(selected == "bank", "Map selections invoke the same service search and guidance")

local cancelled = false
function services:Cancel() cancelled = true end
services.request = {}
root = description()
callback({}, root)
local submenu = root.items[1]
assert(submenu.items[2].label == "SERVICE_CANCEL", "Cancellation reflects the current search state")
submenu.items[2].action()
assert(cancelled)
services.request = nil

local picker = false
APR.Gamepad = {IsEnabled = function() return true end}
function services:ShowPicker() picker = true end
root = description()
callback({}, root)
assert(#root.items[1].items == 0 and root.items[1].action, "Controller mode uses APR's registered picker")
root.items[1].action()
assert(picker)

APR.settings.profile.enableAddon = false
root = description()
callback({}, root)
assert(#root.items == 0 and root.dividers == 0, "A disabled addon contributes no map menu entry")
APR.settings = nil
callback({}, root)
assert(#root.items == 0)
print("Map service menu: native registration, reuse, selection, cancellation, controller picker and disabled/missing settings passed")
