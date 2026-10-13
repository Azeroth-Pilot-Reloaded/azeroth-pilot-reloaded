-- Every APR-triggered reload is accepted through the same themed confirmation.
-- Callers defer their settings/data changes until acceptance, so Cancel is a true no-op.
function APR:RequestReload(action, text, owner)
    if self.reloadConfirmationAccepted then
        if action then return action() end
        return true
    end
    local L = LibStub("AceLocale-3.0"):GetLocale("APR")
    local finished = false
    return self.UI:ShowConfirmationDialog(text or L["UI_RELOAD_CONFIRM"], function()
        if finished then return end
        finished = true
        self.reloadConfirmationAccepted = true
        local ok, result = pcall(function() if action then return action() end end)
        self.reloadConfirmationAccepted = nil
        if not ok then error(result, 0) end
        if result == false then return end
        if C_UI and C_UI.Reload then C_UI.Reload() else ReloadUI() end
    end, function() finished = true end, owner)
end

-- AceDB's callbacks run inside the accepted action and must not ask a second time.
function APR:ConfirmProfileOptions(source)
    local options = {}
    for key, value in pairs(source) do options[key] = value end
    options.args = {}
    for key, value in pairs(source.args) do
        local copy = {}
        for field, setting in pairs(value) do copy[field] = setting end
        options.args[key] = copy
    end
    for _, key in ipairs({"new", "choose", "copyfrom", "reset"}) do
        local option = options.args[key]
        if option then
            local method = option.type == "execute" and "func" or "set"
            local original = option[method]
            option[method] = function(...)
                local args = {...}
                local count = select("#", ...)
                if (key == "new" or key == "choose") and args[2] == self.settings.db:GetCurrentProfile() then return end
                self:RequestReload(function()
                    if type(original) == "string" then source.handler[original](source.handler, unpack(args, 1, count))
                    else original(unpack(args, 1, count)) end
                end)
            end
            option.confirm = false
        end
    end
    return options
end
