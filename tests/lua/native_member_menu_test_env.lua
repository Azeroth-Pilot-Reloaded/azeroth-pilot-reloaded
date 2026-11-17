-- Model only the native popup boundary; Blizzard retains ownership of group actions.
local state = { hooks = {}, opened = 0 }
Menu = { ModifyMenu = function(tag, callback) state.hooks[tag] = callback end }
function UnitPopup_OpenMenu(which, context)
    state.opened = state.opened + 1
    local root = { nativeActions = { "native-leader", "native-whisper", "native-uninvite" }, additions = {} }
    function root:CreateDivider() self.divider = true end
    function root:CreateButton(label, callback)
        local action = { label = label, callback = callback }
        function action:SetEnabled(value) self.enabled = value end
        self.additions[#self.additions + 1] = action
        return action
    end
    state.which, state.context, state.root = which, context, root
    local modify = state.hooks["MENU_UNIT_" .. which]
    if modify then modify(nil, root, context) end
    return root
end
return state
