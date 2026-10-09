-- Builds presentation-only views of the authoritative AceConfig definitions.
-- Option keys and callbacks are preserved, including AceDB profile actions and confirmation dialogs.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.WorkspaceOptions = {}
local Model = APR.WorkspaceOptions

local positionResets = {
    resetCurrentStepPosition = true, fillersFrameResetPosition = true,
    arrowReset = true, afkResetPosition = true, resetPartyPosition = true,
}

local function CopyOption(option)
    local copy = {}
    for key, value in pairs(option) do copy[key] = value end
    if option.args then
        copy.args, copy.inline = {}, true
        for key, child in pairs(option.args) do
            if not (child.type == "description" and type(child.name) == "string" and not child.name:find("%S")) then
                copy.args[key] = CopyOption(child)
            end
        end
    elseif option.type == "toggle" or option.type == "range" or option.type == "color"
        or option.type == "select" or option.type == "multiselect"
        or (option.type == "input" and not option.multiline) then
        copy.width = "full"
    elseif option.type == "execute" then
        copy.width = option.dialogControl == "APRSettingsAction" and "full" or 1.5
    end
    -- Full-width spacers create a separate action row, including inside nested groups.
    if copy.args then
        local spacing = {}
        for key, child in pairs(copy.args) do
            if positionResets[key] and child.type == "execute" then
                child.order = 10000
                spacing[key .. "Spacing"] = {type = "description", name = " ", width = "full", order = 9999}
            end
        end
        for key, spacer in pairs(spacing) do copy.args[key] = spacer end
    end
    return copy
end

local function Group(name, args, order)
    return {type = "group", name = name, args = args, inline = true, order = order or 1}
end

-- Gameplay categories expose display, placement and typography as separate tabs.
local function PanelOptions(source, mainKey, placementKeys)
    local options = CopyOption(source)
    local main = options.args[mainKey]
    main.name, main.order = DISPLAY, 1
    local placement = CopyOption(main)
    placement.name, placement.order, placement.args = L["UI_SETTINGS_PLACEMENT"], 2, {}
    for _, key in ipairs(placementKeys) do
        placement.args[key], main.args[key] = main.args[key], nil
        if positionResets[key] then
            placement.args[key .. "Spacing"], main.args[key .. "Spacing"] = main.args[key .. "Spacing"], nil
        end
    end
    options.args.placement = placement
    for key, group in pairs(options.args) do
        if key:find("TextAppearance$") then group.order = 3 end
    end
    return options
end

local function ProfileOptions(source)
    local options = CopyOption(source)
    local args = options.args
    -- Keep AceDB's handler, validation, profile lists and confirmations on the same root.
    -- Its standalone explanatory paragraphs become descriptions beside their controls.
    local function action(key, description)
        local option = args[key]
        if option then
            option.dialogControl, option.width = "APRSettingsAction", "full"
            option.desc = description or option.desc
        end
    end
    action("reset", args.descreset and args.descreset.name)
    local bulkExplanation = args.reset_all_profiles and args.reset_all_profiles.confirmText
    if type(bulkExplanation) == "string" then bulkExplanation = bulkExplanation:match("[^\r\n]+") end
    action("reset_all_profiles", bulkExplanation)
    options.args = {
        active = Group(args.current and args.current.name or source.name, {choose = args.choose}, 1),
        setup = Group(L["UI_PROFILE_SETUP"], {new = args.new, copyfrom = args.copyfrom}, 2),
        management = Group(L["UI_PROFILE_MANAGEMENT"], {
            delete = args.delete, reset = args.reset, reset_all_profiles = args.reset_all_profiles,
        }, 3),
    }
    if args.reset then args.reset.order = 90 end
    return options
end

function Model:Build(settings)
    local source = settings.optionsTable.args
    local debug = source.group_Debug.args
    local sections = {}
    local function category(id, options)
        local entry = {id = id, label = options.name, options = CopyOption(options)}
        sections[#sections + 1] = entry
        return entry
    end
    local function section(id, label, entries)
        local args = {}
        for order, entry in ipairs(entries) do
            local option = CopyOption(entry[2])
            option.order = order
            args[entry[1]] = option
        end
        sections[#sections + 1] = {id = id, label = label, options = Group(label, args)}
    end
    local advanced = source.group_Advanced_Automation.args
    local main = CopyOption(source.group_Automation)
    local comfort = CopyOption(advanced.subgroup_advanced_automation)
    comfort.name, comfort.order = L["UI_AUTOMATION_COMFORT"], 2
    main.order = 1
    -- Quest-specific preferences belong with accepting quests and choosing routes.
    for _, key in ipairs({"pickupQuestLookahead", "sojournerSkipCampaign"}) do
        main.args[key], comfort.args[key] = comfort.args[key], nil
    end
    section("automation", L["AUTOMATION"], {
        {"main", Group(GENERAL, {quests = main, comfort = comfort})},
        {"subgroup_waypoints", advanced.subgroup_waypoints},
        {"group_gossip_automation", source.group_gossip_automation},
        {"group_reward_automation", source.group_reward_automation},
    })

    local current = PanelOptions(source.group_Current_Step, "subgroup_CurrentStep", {
        "currentStepAttachFrameToQuestLog", "currentStepTrackerSide", "currentStepMatchTrackerStyle", "currentStepLock", "currentStepScale",
        "currentStepQuestButtonPositionRight", "resetCurrentStepPosition",
    })
    current.args.subgroup_FillersFrame = nil
    local afk = CopyOption(source.group_AFK)
    for key, option in pairs(afk.args.subgroup_AFK.args.afkSize.args) do afk.args.subgroup_AFK.args[key] = option end
    afk.args.subgroup_AFK.args.afkSize = nil
    category("group_Current_Step", current)
    category("group_FillersFrame", source.group_Current_Step.args.subgroup_FillersFrame)
    category("group_quest_order_list_step", source.group_quest_order_list_step)
    category("group_Arrow", source.group_Arrow)
    category("group_map_minimap", source.group_map_minimap)
    local afkSection = category("group_AFK", afk)
    afkSection.actions = {{key = "afkFakeTimer", option = afkSection.options.args.subgroup_AFK.args.afkFakeTimer}}
    afkSection.options.args.subgroup_AFK.args.afkFakeTimer = nil
    category("group_Group", source.group_Group)
    category("group_Heirloom", source.group_Heirloom)
    category("group_XP_Buff", source.group_XP_Buff.args.subgroup_XP_Buff)
    section("appearance", L["UI_APPEARANCE"], {
        {"theme", Group(L["UI_THEME"], {uiSkin = debug.subgroup_Enable.args.uiSkin})},
        {"group_GlobalTextAppearance", source.group_GlobalTextAppearance},
    })
    sections[#sections].actions = {{key = "layoutEditor", option = CopyOption(debug.layoutEditor)}}
    sections[#sections + 1] = {id = "profiles", label = L["PROFILES"], options = ProfileOptions(settings.profileOptions)}
    sections[#sections + 1] = {id = "changelog", label = L["UI_RELEASE_NOTES"], options = Group(L["UI_RELEASE_NOTES"], {
        showChangeLog = CopyOption(debug.subgroup_Enable.args.showChangeLog),
        checkForUpdate = CopyOption(debug.subgroup_Enable.args.checkForUpdate),
    })}
    local diagnostics = category("debug", debug.subgroup_debug)
    diagnostics.options.args.enableAddon = CopyOption(debug.subgroup_Enable.args.enableAddon)
    diagnostics.options.args.enableAddon.order = 0
    return sections
end

-- One persistent action for the whole options workspace, outside every category's form.
function Model:ResetAction(settings)
    return CopyOption(settings.optionsTable.args.resetButton)
end

-- Split long pages by the task the player is performing; option definitions remain shared with AceConfig.
function Model:Views(section)
    local options = CopyOption(section.options)
    if section.id == "profiles" then
        -- These forms use inline sections on a single page, without intermediate tabs.
        return {{id = "general", label = section.label, options = options}}
    end
    local groups, direct = {}, {}
    for key, option in pairs(options.args) do
        if option.type == "group" then groups[#groups + 1] = {key = key, option = option}
        else direct[key] = option end
    end
    table.sort(groups, function(a, b)
        local aOrder, bOrder = a.option.order or 0, b.option.order or 0
        return aOrder == bOrder and a.key < b.key or aOrder < bOrder
    end)
    local views = {}
    local function view(id, label, args, group)
        local root = {}
        for key, value in pairs(options) do root[key] = value end
        for key, value in pairs(group or {}) do root[key] = value end
        root.args = args
        views[#views + 1] = {id = id, label = label, options = root}
    end
    if next(direct) then view("general", GENERAL, direct) end
    for _, group in ipairs(groups) do
        view(group.key, group.option.name, group.option.args, group.option)
    end
    if #views == 0 then view("general", section.label, options.args) end
    return views
end
