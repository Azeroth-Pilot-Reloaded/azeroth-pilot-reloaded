local _G = _G

-- Locale
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Init APR setting module
APR.settings = APR:NewModule("Settings", "AceConsole-3.0")

-- Ace option config table
local aceConfig = _G.LibStub("AceConfig-3.0")
local aceDialog = _G.LibStub("AceConfigDialog-3.0")

-- Databroker support -- minimapIcon
local libDataBroker = LibStub("LibDataBroker-1.1")
local libDBIcon = LibStub("LibDBIcon-1.0")

local function GetProfileOption(info) return APR.settings.profile[info[#info]] end

local function SetProfileOption(info, value)
    APR.settings.profile[info[#info]] = value
end

function APR.settings:ResetSettings()
    SettingsDB:ResetProfile()
    self:RefreshProfile()
end

function APR.settings:InitializeBlizOptions()
    self:InitializeSettings()
    self:createBlizzOptions()
    self:CreateMiniMapButton()

    self:RegisterChatCommand("apr", self.ChatCommand)
end

function APR.settings:InitializeSettings()
    -- Default setting
    local settingsDBDefaults = {
        profile = {
            -- automation
            autoAccept = false,
            autoAcceptQuestRoute = true,
            pickupQuestLookahead = 10,
            autoHandIn = true,
            autoGossip = true,
            autoVendor = false,
            autoRepair = false,
            autoSkipCutScene = true,
            autoFlight = true,
            autoShareQuestWithFriend = false,
            firstAutoShareQuestWithFriend = true,
            autoSkipAllWaypoints = false,
            autoSkipWaypointsFly = false,
            -- reward
            autoHandInChoice = false,
            autoCosmeticMulti = false,
            autoTransmogMulti = false,
            rewardPriority1 = "ilvl",
            rewardPriority2 = "cosmetic",
            rewardPriority3 = "transmog",
            rewardPriority4 = "price",
            -- current step
            currentStepFrame = {},
            currentStepShow = true,
            currentStepLock = false,
            currentStepScale = 1,
            currentStepbackgroundColorAlpha = APR.Color.defaultLightBackdrop,
            currentStepProgressBarColor = { APR.Color.blue[1], APR.Color.blue[2], APR.Color.blue[3], 1 },
            currentStepAttachFrameToQuestLog = false,
            currentStepQuestButtonPositionRight = false,
            -- quest order list
            questOrderListFrame = {},
            showQuestOrderList = false,
            questOrderListLock = false,
            questOrderListSnapToCurrentStep = false,
            questOrderListScale = 1,
            questOrderListbackgroundColorAlpha = APR.Color.defaultLightBackdrop,
            -- arrow
            showArrow = true,
            lockArrow = false,
            arrowScale = 1,
            arrowFPS = 2,
            arrowleft = _G.GetScreenWidth() / 2.05,
            arrowtop = -(_G.GetScreenHeight() / 1.5),
            -- map
            mapMinimapSameColor = true,
            showMapLine = true,
            showMapLineColor = APR.Color.lightGreen,
            showMapLineThickness = 8,
            mapshowNextSteps = true,
            mapshowNextStepsColor = APR.Color.lightGreen,
            mapshowNextStepsCount = 2,
            mapshowNextStepsSize = 16,
            mapshowNextStepsTextScale = 1,
            mapshowNextStepsColorText = APR.Color.gold,
            -- minimap
            minimap = { minimapPos = 300 },
            enableMinimapButton = true,
            showMiniMapLine = true,
            showMiniMapLineColor = APR.Color.lightGreen,
            showMiniMapLineThickness = 2,
            minimapshowNextSteps = true,
            minimapshowNextStepsColor = APR.Color.lightGreen,
            minimapshowNextStepsCount = 2,
            minimapshowNextStepsSize = 16,
            minimapshowNextStepsTextScale = 1,
            minimapshowNextStepsColorText = APR.Color.gold,
            -- Heirloom
            heirloomFrame = {},
            heirloomWarning = false,
            --buff
            buffFrame = {},
            -- group
            groupFrame = {},
            showGroup = true,
            receiveGroupData = true,
            groupScale = 1,
            -- route
            routeSelectionFrame = {},
            routeSignature = {},
            --afk
            afkFrame = {},
            afkSnapToCurrentStep = false,
            afkBarColor = { APR.Color.blue[1], APR.Color.blue[2], APR.Color.blue[3], 1 },
            afkWidth = 250,
            afkHeight = 30,
            --debug
            debug = false,
            showEvent = false,
            enableAddon = true,
            changeLogFrame = {},
            showChangeLog = true,
            lastRecordedVersion = '',
            -- position
            coordinateFrame = {},
            coordinateShow = false,
        }
    }

    SettingsDB = LibStub("AceDB-3.0"):New("APRSettings", settingsDBDefaults)

    SettingsDB.RegisterCallback(self, "OnProfileChanged", "RefreshProfile")
    SettingsDB.RegisterCallback(self, "OnProfileCopied", "RefreshProfile")
    SettingsDB.RegisterCallback(self, "OnProfileReset", "RefreshProfile")
    self.profile = SettingsDB.profile
    LoadedProfileKey = SettingsDB.keys.profile
end

function APR.settings.ChatCommand(input)
    APR.command:SlashCmd(input)
end

function APR.settings:RefreshProfile()
    self.profile = SettingsDB.profile
    C_UI.Reload()
end

function APR.settings:createBlizzOptions()
    -- Setting definition
    local optionsWidth = 1.3
    local optionsWidthAutomation = 1.75
    local rewardValues = {
        ilvl = L["REWARD_PRIO_ILVL"],
        cosmetic = L["REWARD_PRIO_COSMETIC"],
        transmog = L["REWARD_PRIO_TRANSMOG"],
        price = L["REWARD_PRIO_PRICE"],
    }
    local optionsTable = {
        name = APR.title .. ' - ' .. APR.version,
        type = "group",
        args = {
            discordButton = {
                order = 1.1,
                name = L["JOIN_DISCORD"],
                type = "execute",
                width = 0.75,
                func = function()
                    APR.questionDialog:CreateEditBoxPopup(L["COPY_HELPER"], L["CLOSE"], APR.discord)
                end
            },
            githubButton = {
                order = 1.2,
                name = "Github",
                type = "execute",
                width = 0.75,
                func = function()
                    APR.questionDialog:CreateEditBoxPopup(L["COPY_HELPER"], L["CLOSE"], APR.github)
                end
            },
            buttonOffset = {
                order = 1.3,
                name = "",
                type = "description",
                width = 0.75,
            },
            statusButton = {
                order = 1.4,
                name = L["STATUS"],
                type = "execute",
                width = 0.75,
                func = function()
                    APR:getStatus()
                end
            },
            resetButton = {
                order = 1.5,
                name = L["RESET_SETTINGS"],
                type = "execute",
                width = 0.75,
                func = function()
                    APR.questionDialog:CreateQuestionPopup("RESET_SETTINGS",
                        nil,
                        function() APR.settings:ResetSettings() end
                    )
                end
            },
            header_Automation = {
                order = 2,
                type = "header",
                width = "full",
                name = L["AUTOMATION"],
            },
            group_Automation = {
                order = 3,
                type = "group",
                name = L["GENERAL_AUTOMATION"],
                inline = true,
                args = {
                    autoAccept = {
                        order = 3.1,
                        type = "toggle",
                        name = L["ACCEPT_Q"],
                        desc = L["ACCEPT_Q_DESC"],
                        width = optionsWidthAutomation,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            if (value) then self.profile.autoAcceptQuestRoute = false end
                        end
                    },
                    autoAcceptQuestRoute = {
                        order = 3.11,
                        type = "toggle",
                        name = L["ACCEPT_Q_ROUTE"],
                        desc = L["ACCEPT_Q_ROUTE_DESC"],
                        width = optionsWidthAutomation,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            if (value) then self.profile.autoAccept = false end
                        end
                    },
                    autoHandIn = {
                        order = 3.12,
                        type = "toggle",
                        name = L["TURN_IN_Q"],
                        desc = L["TURN_IN_Q_DESC"],
                        width = optionsWidthAutomation,
                        get = GetProfileOption,
                        set = SetProfileOption,
                    },
                    autoGossip = {
                        order = 3.21,
                        type = "toggle",
                        name = L["AUTO_SELECTION_OF_DIALOG"],
                        desc = L["AUTO_SELECTION_OF_DIALOG_DESC"],
                        width = optionsWidthAutomation,
                        get = GetProfileOption,
                        set = SetProfileOption,
                    },
                }
            },
            header_Preferences = {
                order = 4,
                type = "header",
                width = "full",
                name = L["PREFERENCES"],
            },
            group_Current_Step = {
                order = 4,
                type = "group",
                name = L["CURRENT_STEP"],
                args = {
                    currentStepShow = {
                        order = 5.1,
                        type = "toggle",
                        name = L["SHOW_QLIST"],
                        desc = L["SHOW_QLIST_DESC"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.currentStep:RefreshCurrentStepFrameAnchor()
                        end,
                        disabled = function()
                            return not self.profile.enableAddon
                        end,
                    },
                    currentStepAttachFrameToQuestLog = {
                        order = 5.11,
                        type = "toggle",
                        name = L["QLIST_ATTACH_QUESTLOG"],
                        desc = L["QLIST_ATTACH_QUESTLOG_DESC"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.currentStep:RefreshCurrentStepFrameAnchor()
                        end,
                        disabled = function()
                            return not self.profile.currentStepShow
                        end,
                    },
                    currentStepLock = {
                        order = 5.12,
                        type = "toggle",
                        name = L["LOCK_WINDOW"],
                        desc = L["LOCK_QLIST_WINDOW_DESC"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.currentStep:RefreshCurrentStepFrameAnchor()
                        end,
                        disabled = function()
                            return not self.profile.currentStepShow or self.profile
                                .currentStepAttachFrameToQuestLog or not self.profile.enableAddon
                        end,
                    },
                    currentStepbackgroundColorAlpha = {
                        order = 5.2,
                        type = "color",
                        name = L["BACKGROUND_COLOR_ALPHA"],
                        width = optionsWidth,
                        hasAlpha = true,
                        get = function()
                            return unpack(self.profile.currentStepbackgroundColorAlpha)
                        end,
                        set = function(info, r, g, b, a)
                            SetProfileOption(info, { r, g, b, a })
                            APR.currentStep:UpdateBackgroundColorAlpha()
                            APR.Buff:UpdateBackgroundColorAlpha()
                        end,
                        disabled = function()
                            return not self.profile.currentStepShow or not self.profile.enableAddon or
                                self.profile.currentStepAttachFrameToQuestLog
                        end,
                    },
                    currentStepProgressBarColor = {
                        order = 5.25,
                        type = "color",
                        name = L["PROGRESS_BAR_COLOR"],
                        width = optionsWidth,
                        hasAlpha = true,
                        get = function()
                            return unpack(self.profile.currentStepProgressBarColor)
                        end,
                        set = function(info, r, g, b, a)
                            SetProfileOption(info, { r, g, b, a })
                            APR.currentStep:UpdateProgressBarColor()
                        end,
                        disabled = function()
                            return not self.profile.currentStepShow or not self.profile.enableAddon
                        end,
                    },
                    currentStepQuestButtonPositionRight = {
                        order = 5.3,
                        type = "select",
                        name = L["CURRENT_STEP_QUEST_BUTTON_POSITION"],
                        desc = L["CURRENT_STEP_QUEST_BUTTON_POSITION_DESC"],
                        width = optionsWidth,
                        values = {
                            [false] = L["LEFT"],
                            [true] = L["RIGHT"]
                        },
                        get = function(info)
                            return GetProfileOption(info)
                        end,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            -- Force Rerender
                            APR:UpdateMapId()
                        end,
                        disabled = function()
                            return not self.profile.currentStepShow
                        end,
                    },
                    currentStepScale = {
                        order = 5.4,
                        type = "range",
                        name = L["QLIST_SCALE"],
                        desc = L["QLIST_SCALE_DESC"],
                        width = "full",
                        min = 0.01,
                        max = 2,
                        step = 0.05,
                        isPercent = true,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.currentStep:UpdateFrameScale()
                        end,
                        disabled = function()
                            return not self.profile.currentStepShow or self.profile
                                .currentStepAttachFrameToQuestLog or not self.profile.enableAddon
                        end,
                    },
                    resetCurrentStepPosition = {
                        name = L['RESET_CURRENT_STEP_FRAME_POSITION'],
                        order = 5.5,
                        type = 'execute',
                        width = "full",
                        func = function()
                            APR.currentStep:ResetPosition()
                        end,
                        disabled = function()
                            return not self.profile.currentStepShow or self.profile
                                .currentStepAttachFrameToQuestLog or not self.profile.enableAddon
                        end,
                    },
                },
            },
            group_quest_order_list_step = {
                order = 6,
                type = "group",
                name = L["QUEST_ORDER_LIST"],
                args = {
                    showQuestOrderList = {
                        order = 6.1,
                        type = "toggle",
                        name = L["SHOW_QORDERLIST"],
                        desc = L["SHOW_QORDERLIST_DESC"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.questOrderList:RefreshFrameAnchor()
                        end,
                        disabled = function()
                            return not self.profile.enableAddon
                        end,
                    },
                    questOrderListLock = {
                        order = 6.2,
                        type = "toggle",
                        name = L["LOCK_WINDOW"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.questOrderList:RefreshFrameAnchor()
                        end,
                        disabled = function()
                            return not self.profile.showQuestOrderList
                        end,
                    },
                    questOrderListSnapToCurrentStep = {
                        order = 6.25,
                        type = "toggle",
                        name = L["QORDERLIST_SNAP_TO_CURRENT_STEP"],
                        desc = L["QORDERLIST_SNAP_TO_CURRENT_STEP_DESC"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.questOrderList:RefreshFrameAnchor()
                        end,
                        disabled = function()
                            return not self.profile.showQuestOrderList or not self.profile.enableAddon
                        end,
                    },
                    questOrderListScale = {
                        order = 6.3,
                        type = "range",
                        name = L["QORDERLIST_SCALE"],
                        desc = L["QORDERLIST_SCALE_DESC"],
                        width = "full",
                        min = 0.01,
                        max = 2,
                        step = 0.05,
                        isPercent = true,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.questOrderList:UpdateFrameScale()
                        end,
                        disabled = function()
                            return not self.profile.showQuestOrderList or not self.profile.enableAddon
                        end,
                    },
                    questOrderListbackgroundColorAlpha = {
                        order = 6.4,
                        type = "color",
                        name = L["BACKGROUND_COLOR_ALPHA"],
                        width = optionsWidth,
                        hasAlpha = true,
                        get = function()
                            return unpack(self.profile.questOrderListbackgroundColorAlpha)
                        end,
                        set = function(info, r, g, b, a)
                            SetProfileOption(info, { r, g, b, a })
                            APR.questOrderList:UpdateBackgroundColorAlpha()
                        end,
                        disabled = function()
                            return not self.profile.showQuestOrderList or not self.profile.enableAddon
                        end,
                    },
                    resetCurrentStepPosition = {
                        name = L['RESET_QORDERLIST'],
                        order = 6.5,
                        type = 'execute',
                        width = optionsWidth,
                        func = function()
                            self.profile.questOrderListbackgroundColorAlpha = APR.Color.defaultLightBackdrop
                            APR.questOrderList:ResetPosition()
                        end,
                        disabled = function()
                            return not self.profile.showQuestOrderList or not self.profile.enableAddon
                        end,
                    },
                },
            },
            group_Arrow = {
                order = 7,
                type = "group",
                name = L["ARROW"],
                args = {
                    showArrow = {
                        order = 7.1,
                        type = "toggle",
                        name = L["SHOW_ARROW"],
                        desc = L["SHOW_ARROW_DESC"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            if value then APR.Arrow.Active = true end
                        end,
                        disabled = function()
                            return not self.profile.enableAddon
                        end,
                    },
                    lockArrow = {
                        order = 7.11,
                        type = "toggle",
                        name = L["LOCK_ARROW_WINDOW"],
                        desc = L["LOCK_ARROW_WINDOW_DESC"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = SetProfileOption,
                        disabled = function()
                            return not self.profile.showArrow
                        end,
                    },
                    arrowScale = {
                        order = 7.2,
                        type = "range",
                        name = L["ARROW_SCALE"],
                        desc = L["ARROW_SCALE_DESC"],
                        width = optionsWidth,
                        min = 0.01,
                        max = 3,
                        step = 0.05,
                        isPercent = true,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.ArrowFrame:SetScale(value)
                        end,
                        disabled = function()
                            return not self.profile.showArrow
                        end,
                    },
                    arrowFPS = {
                        order = 7.21,
                        type = "range",
                        name = L["UPDATE_ARROW"] .. ' X ' .. L["FPS"],
                        width = optionsWidth,
                        min = 1,
                        max = 100,
                        step = 1,
                        isPercent = false,
                        get = GetProfileOption,
                        set = SetProfileOption,
                        disabled = function()
                            return not self.profile.showArrow
                        end,
                    },
                    blank_arrowReset = {
                        order = 7.3,
                        type = "description",
                        name = "",
                        width = "full",
                    },
                    arrowReset = {
                        order = 7.4,
                        name = L["RESET_ARROW"],
                        type = "execute",
                        width = "full",
                        func = function()
                            self.profile.showArrow = true
                            self.profile.lockArrow = false
                            self.profile.arrowScale = 1
                            self.profile.arrowFPS = 2
                            self.profile.arrowleft = _G.GetScreenWidth() / 2.05
                            self.profile.arrowtop = -(_G.GetScreenHeight() / 1.5)
                            APR.ArrowFrame:SetScale(self.profile.arrowScale)
                            APR.ArrowFrameM:ClearAllPoints()
                            APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
                                self.profile.arrowleft,
                                self.profile.arrowtop)
                        end,
                        disabled = function()
                            return not self.profile.enableAddon
                        end,
                    },
                }
            },
            group_Advanced_Automation = {
                order = 8,
                type = "group",
                name = L["ADVANCED_AUTOMATION"],
                args = {
                    subgroup_advanced_automation = {
                        order = 8.1,
                        type = "group",
                        inline = true,
                        name = L["ADVANCED_AUTOMATION"],
                        args = {
                            autoSkipCutScene = {
                                order = 8.2,
                                type = "toggle",
                                name = L["SKIPPED_CUTSCENE"],
                                desc = L["SKIPPED_CUTSCENE_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                            },
                            autoFlight = {
                                order = 8.3,
                                type = "toggle",
                                name = L["AUTO_USE_FLIGHTPATHS"],
                                desc = L["AUTO_USE_FLIGHTPATHS_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                            },
                            autoVendor = {
                                order = 8.4,
                                type = "toggle",
                                name = L["AUTO_VENDOR"],
                                desc = L["AUTO_VENDOR_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                            },
                            autoRepair = {
                                order = 8.5,
                                type = "toggle",
                                name = L["AUTO_REPAIR"],
                                desc = L["AUTO_REPAIR_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                            },
                            pickupQuestLookahead = {
                                order = 8.6,
                                type = "range",
                                name = L["PICKUP_LOOKAHEAD"],
                                desc = L["PICKUP_LOOKAHEAD_DESC"],
                                width = "full",
                                min = 0,
                                max = 1000,
                                step = 1,
                                get = GetProfileOption,
                                set = SetProfileOption,
                            },
                        },
                    },
                    subgroup_reward_automation = {
                        order = 8.2,
                        type = "group",
                        inline = true,
                        name = L["REWARDS_OPTIONS"],
                        args = {
                            autoHandInChoice = {
                                order = 8.21,
                                type = "toggle",
                                name = L["AUTO_PICK_REWARD_ITEM"],
                                desc = L["AUTO_PICK_REWARD_ITEM_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                            },
                            rewardPriority1 = {
                                order = 8.22,
                                type = "select",
                                name = L["REWARD_PRIO"] .. " 1",
                                width = 1,
                                values = rewardValues,
                                get = GetProfileOption,
                                set = function(info, value) APR.settings:SetRewardPriority(info, value) end,
                                disabled = function()
                                    return not self.profile.autoHandInChoice
                                end,
                            },
                            rewardPriority2 = {
                                order = 8.23,
                                type = "select",
                                name = L["REWARD_PRIO"] .. " 2",
                                width = 1,
                                values = rewardValues,
                                get = GetProfileOption,
                                set = function(info, value) APR.settings:SetRewardPriority(info, value) end,
                                disabled = function()
                                    return not self.profile.autoHandInChoice
                                end,
                            },
                            rewardPriority3 = {
                                order = 8.24,
                                type = "select",
                                name = L["REWARD_PRIO"] .. " 3",
                                width = 1,
                                values = rewardValues,
                                get = GetProfileOption,
                                set = function(info, value) APR.settings:SetRewardPriority(info, value) end,
                                disabled = function()
                                    return not self.profile.autoHandInChoice
                                end,
                            },
                            rewardPriority4 = {
                                order = 8.25,
                                type = "select",
                                name = L["REWARD_PRIO"] .. " 4",
                                width = 1,
                                values = rewardValues,
                                get = GetProfileOption,
                                set = function(info, value) APR.settings:SetRewardPriority(info, value) end,
                                disabled = function()
                                    return not self.profile.autoHandInChoice
                                end,
                            },
                            autoCosmeticMulti = {
                                order = 8.26,
                                type = "toggle",
                                name = L["AUTO_MULTI_COSMETIC"],
                                desc = L["AUTO_MULTI_COSMETIC_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                                disabled = function()
                                    return not self.profile.autoHandInChoice
                                end,
                            },
                            autoTransmogMulti = {
                                order = 8.27,
                                type = "toggle",
                                name = L["AUTO_MULTI_TRANSMOG"],
                                desc = L["AUTO_MULTI_TRANSMOG_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                                disabled = function()
                                    return not self.profile.autoHandInChoice
                                end,
                            },
                        },
                    },
                    subgroup_waypoints = {
                        order = 8.3,
                        type = "group",
                        inline = true,
                        name = L["HEADER_WAYPOINT"],
                        args = {
                            autoSkipAllWaypoints = {
                                order = 8.31,
                                type = "toggle",
                                name = L["AUTO_SKIP_WAYPOINT"],
                                desc = L["AUTO_SKIP_WAYPOINT_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    if (value) then self.profile.autoSkipWaypointsFly = false end
                                end,
                            },
                            autoSkipWaypointsFly = {
                                order = 8.32,
                                type = "toggle",
                                name = L["AUTO_SKIP_WAYPOINT_FLY"],
                                desc = L["AUTO_SKIP_WAYPOINT_FLY_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    if (value) then self.profile.autoSkipAllWaypoints = false end
                                end,
                            },
                        },
                    },
                },
            },
            group_map_minimap = {
                order = 9,
                type = "group",
                name = L["MAP_MINIMAP"],
                args = {
                    group_map = {
                        order = 1,
                        type = "group",
                        inline = true,
                        name = L["MAP"],
                        args = {
                            showMapLine = {
                                order = 9.10,
                                type = "toggle",
                                name = L["MAP_LINE_SHOW"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    if not value then
                                        APR.map:RemoveMapLine()
                                    end
                                end
                            },
                            showMapLineThickness = {
                                order = 9.12,
                                type = "range",
                                name = L["MAP_LINE_THICKNESS"],
                                width = "full",
                                min = 0.5,
                                max = 50,
                                step = 0.5,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.map:UpdateMapLineStyle()
                                end,
                                disabled = function()
                                    return not self.profile.showMapLine
                                end,
                            },
                            mapblank0 = {
                                order = 9.13,
                                type = "description",
                                width = "full",
                                name = " ",
                            },
                            mapshowNextSteps = {
                                order = 9.14,
                                type = "toggle",
                                name = L["SHOW_STEPS_MAP"],
                                desc = L["SHOW_STEPS_MAP_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.map:AddMapPins()
                                end,
                            },
                            mapshowNextStepsCount = {
                                order = 9.15,
                                type = "range",
                                name = L["SHOW_STEPS_MAP_COUNT"],
                                min = 0,
                                max = 25,
                                step = 1,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.map:AddMapPins()
                                end,
                                disabled = function()
                                    return not self.profile.mapshowNextSteps
                                end,
                            },
                            mapshowNextStepsSize = {
                                order = 9.16,
                                type = "range",
                                name = L["MAP_STEP_ICON_SIZE"],
                                min = 1,
                                max = 100,
                                step = 1,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.map:UpdateMapIconsStyle()
                                end,
                                disabled = function()
                                    return not self.profile.mapshowNextSteps
                                end,
                            },
                        },
                    },
                    group_minimap = {
                        order = 2,
                        type = "group",
                        inline = true,
                        name = L["MINIMAP"],
                        args = {
                            enableMinimapButton = {
                                name = L["ENABLE_MINIMAP_BUTTON"],
                                desc = L["ENABLE_MINIMAP_BUTTON_DESC"],
                                type = "toggle",
                                width = "full",
                                order = 9.20,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    if value then
                                        libDBIcon:Show(APR.title)
                                    else
                                        libDBIcon:Hide(APR.title)
                                    end
                                end
                            },
                            minimapblank0 = {
                                order = 9.21,
                                type = "description",
                                width = "full",
                                name = " ",
                            },
                            showMiniMapLine = {
                                order = 9.22,
                                type = "toggle",
                                name = L["MINIMAP_LINE_SHOW"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    if not value then
                                        APR.map:RemoveMinimapLine()
                                    end
                                end
                            },
                            showMiniMapLineThickness = {
                                order = 9.23,
                                type = "range",
                                name = L["MINIMAP_LINE_THICKNESS"],
                                width = "full",
                                min = 0.5,
                                max = 50,
                                step = 0.5,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.map:UpdateMinimapLineStyle()
                                end,
                                disabled = function()
                                    return not self.profile.showMiniMapLine
                                end,
                            },
                            minimapblank1 = {
                                order = 9.24,
                                type = "description",
                                width = "full",
                                name = " ",
                            },
                            minimapshowNextSteps = {
                                order = 9.25,
                                type = "toggle",
                                name = L["SHOW_STEPS_MINIMAP"],
                                desc = L["SHOW_STEPS_MINIMAP_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.map:AddMapPins()
                                end,
                            },
                            minimapshowNextStepsCount = {
                                order = 9.26,
                                type = "range",
                                name = L["SHOW_STEPS_MAP_COUNT"],
                                min = 0,
                                max = 25,
                                step = 1,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.map:AddMapPins()
                                end,
                                disabled = function()
                                    return not self.profile.minimapshowNextSteps
                                end,
                            },
                            minimapshowNextStepsSize = {
                                order = 9.27,
                                type = "range",
                                name = L["MINIMAP_STEP_ICON_SIZE"],
                                min = 1,
                                max = 100,
                                step = 1,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.map:UpdateMiniMapIconsStyle()
                                end,
                                disabled = function()
                                    return not self.profile.minimapshowNextSteps
                                end,
                            },
                        }
                    },
                    group_map_color = {
                        order = 3,
                        type = "group",
                        inline = true,
                        name = L["COLOR_FONT"],
                        args = {
                            mapMinimapSameColor = {
                                order = 9.30,
                                type = "toggle",
                                name = L["MAP_MINIMAP_SAME_COLOR"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                            },
                            showMapLineColor = {
                                order = 9.31,
                                type = "color",
                                name = L["MAP_LINE_COLOR"],
                                hasAlpha = true,
                                get = function()
                                    return unpack(self.profile.showMapLineColor)
                                end,
                                set = function(info, r, g, b, a)
                                    SetProfileOption(info, { r, g, b, a })
                                    APR.map:UpdateMapLineStyle()
                                    if self.profile.mapMinimapSameColor then
                                        APR.map:UpdateMinimapLineStyle()
                                        self.profile.showMiniMapLineColor = self.profile.showMapLineColor
                                    end
                                end,
                                disabled = function()
                                    if self.profile.mapMinimapSameColor then
                                        return not self.profile.showMapLine and not self.profile.showMiniMapLine
                                    else
                                        return not self.profile.showMapLine
                                    end
                                end,
                            },
                            mapshowNextStepsColor = {
                                order = 9.32,
                                type = "color",
                                name = L["MAP_STEP_ICON_COLOR"],
                                hasAlpha = true,
                                get = function()
                                    return unpack(self.profile.mapshowNextStepsColor)
                                end,
                                set = function(info, r, g, b, a)
                                    SetProfileOption(info, { r, g, b, a })
                                    APR.map:UpdateMapIconsStyle()
                                    if self.profile.mapMinimapSameColor then
                                        APR.map:UpdateMiniMapIconsStyle()
                                        self.profile.minimapshowNextStepsColor = self.profile.mapshowNextStepsColor
                                    end
                                end,
                                disabled = function()
                                    if self.profile.mapMinimapSameColor then
                                        return not self.profile.mapshowNextSteps and
                                            not self.profile.minimapshowNextSteps
                                    else
                                        return not self.profile.mapshowNextSteps
                                    end
                                end,
                            },
                            mapshowNextStepsColorText = {
                                order = 9.33,
                                type = "color",
                                name = L["MAP_STEP_ICON_TEXT_COLOR"],
                                hasAlpha = true,
                                get = function()
                                    return unpack(self.profile.mapshowNextStepsColorText)
                                end,
                                set = function(info, r, g, b, a)
                                    SetProfileOption(info, { r, g, b, a })
                                    APR.map:UpdateMapIconsStyle()
                                    if self.profile.mapMinimapSameColor then
                                        APR.map:UpdateMiniMapIconsStyle()
                                        self.profile.minimapshowNextStepsColorText = self.profile
                                            .mapshowNextStepsColorText
                                    end
                                end,
                                disabled = function()
                                    if self.profile.mapMinimapSameColor then
                                        return not self.profile.mapshowNextSteps and
                                            not self.profile.minimapshowNextSteps
                                    else
                                        return not self.profile.mapshowNextSteps
                                    end
                                end,
                            },
                            showMiniMapLineColor = {
                                order = 9.31,
                                type = "color",
                                name = L["MINIMAP_LINE_COLOR"],
                                hasAlpha = true,
                                get = function()
                                    return unpack(self.profile.showMiniMapLineColor)
                                end,
                                set = function(info, r, g, b, a)
                                    SetProfileOption(info, { r, g, b, a })
                                    APR.map:UpdateMinimapLineStyle()
                                end,
                                disabled = function()
                                    return not self.profile.showMiniMapLine
                                end,
                                hidden = function()
                                    return self.profile.mapMinimapSameColor
                                end,
                            },
                            minimapshowNextStepsColor = {
                                order = 9.32,
                                type = "color",
                                name = L["MINIMAP_STEP_ICON_COLOR"],
                                hasAlpha = true,
                                get = function()
                                    return unpack(self.profile.minimapshowNextStepsColor)
                                end,
                                set = function(info, r, g, b, a)
                                    SetProfileOption(info, { r, g, b, a })
                                    APR.map:UpdateMiniMapIconsStyle()
                                end,
                                disabled = function()
                                    return not self.profile.minimapshowNextSteps
                                end,
                                hidden = function()
                                    return self.profile.mapMinimapSameColor
                                end,
                            },
                            minimapshowNextStepsColorText = {
                                order = 9.33,
                                type = "color",
                                name = L["MINIMAP_STEP_ICON_TEXT_COLOR"],
                                hasAlpha = true,
                                get = function()
                                    return unpack(self.profile.minimapshowNextStepsColorText)
                                end,
                                set = function(info, r, g, b, a)
                                    SetProfileOption(info, { r, g, b, a })
                                    APR.map:UpdateMiniMapIconsStyle()
                                end,
                                disabled = function()
                                    return not self.profile.minimapshowNextSteps
                                end,
                                hidden = function()
                                    return self.profile.mapMinimapSameColor
                                end,
                            },
                            blank_font = {
                                order = 10,
                                type = "description",
                                name = "",
                                width = "full",
                            },
                            mapshowNextStepsTextScale = {
                                order = 11.1,
                                type = "range",
                                name = L["MAP_STEP_ICON_TEXT_SIZE"],
                                min = 0.01,
                                max = 2,
                                step = 0.01,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.map:UpdateMiniMapIconsStyle()
                                end,
                                disabled = function()
                                    return not self.profile.mapshowNextSteps
                                end,
                            },
                            minimapshowNextStepsTextScale = {
                                order = 11.2,
                                type = "range",
                                name = L["MINIMAP_STEP_ICON_TEXT_SIZE"],
                                min = 0.01,
                                max = 2,
                                step = 0.01,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.map:UpdateMiniMapIconsStyle()
                                end,
                                disabled = function()
                                    return not self.profile.minimapshowNextSteps
                                end,
                            },

                        }
                    }
                }
            },
            group_Heirloom = {
                order = 10,
                type = "group",
                name = L["HEIRLOOM"],
                args = {
                    heirloomWarning = {
                        order = 10.1,
                        type = "toggle",
                        name = L["DISABLE_HEIRLOOM_WARNING"],
                        desc = L["DISABLE_HEIRLOOM_WARNING_DESC"],
                        width = "full",
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.heirloom:RefreshFrameAnchor()
                        end,
                        disabled = APR:IsRemixCharacter()
                    },
                }
            },
            group_AFK = {
                order = 10.5,
                type = "group",
                name = L["AFK"],
                args = {
                    afkSnapToCurrentStep = {
                        order = 10.51,
                        type = "toggle",
                        name = L["AFK_SNAP_TO_CURRENT_STEP"],
                        desc = L["AFK_SNAP_TO_CURRENT_STEP_DESC"],
                        width = "full",
                        get = GetProfileOption,
                        set = function(info, value)
                            local wasSnapped = self.profile.afkSnapToCurrentStep
                            SetProfileOption(info, value)
                            if value and not wasSnapped and self.profile.afkHeight == 30 then
                                self.profile.afkHeight = (APR.AFK and APR.AFK.defaultSnapHeight) or 15
                            end
                            APR.AFK:RefreshFrameAnchor()
                        end,
                    },
                    afkBarColor = {
                        order = 10.52,
                        type = "color",
                        name = L["AFK_BAR_COLOR"],
                        hasAlpha = true,
                        width = optionsWidth,
                        get = function()
                            return unpack(self.profile.afkBarColor)
                        end,
                        set = function(info, r, g, b, a)
                            SetProfileOption(info, { r, g, b, a })
                            APR.AFK:UpdateBarColor()
                        end,
                    },
                    afkFakeTimer = {
                        order = 10.525,
                        type = "execute",
                        name = function()
                            return APR.AFK and APR.AFK.fakeTimerActive and L["AFK_TEST_TIMER_STOP"] or
                                L["AFK_TEST_TIMER_START"]
                        end,
                        width = optionsWidth,
                        func = function()
                            APR.AFK:ToggleFakeTimer()
                        end,
                        disabled = function()
                            return not self.profile.enableAddon
                        end,
                    },
                    afkSize = {
                        order = 10.53,
                        type = "group",
                        inline = true,
                        name = "",
                        args = {
                            afkWidth = {
                                order = 10.531,
                                type = "range",
                                name = "AFK width",
                                min = 150,
                                max = 600,
                                step = 5,
                                width = optionsWidth,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.AFK:RefreshFrameAnchor()
                                end,
                                disabled = function()
                                    return self.profile.afkSnapToCurrentStep
                                end,
                            },
                            afkHeight = {
                                order = 10.532,
                                type = "range",
                                name = "AFK height",
                                min = 10,
                                max = 60,
                                step = 1,
                                width = optionsWidth,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.AFK:RefreshFrameAnchor()
                                end,
                            },
                        }
                    },
                    afkResetPosition = {
                        order = 10.55,
                        type = "execute",
                        name = L["RESET_POSITION"],
                        width = "full",
                        func = function()
                            APR.AFK:ResetPosition()
                        end,
                        disabled = function()
                            return self.profile.afkSnapToCurrentStep
                        end,
                    },
                }
            },
            group_Group = {
                order = 11,
                type = "group",
                name = L["GROUP"],
                args = {
                    autoShareQuestWithFriend = {
                        order = 11.1,
                        type = "toggle",
                        name = L["SHOW_GROUP_SHAREWITHFRIEND"],
                        desc = L["SHOW_GROUP_SHAREWITHFRIEND_DESC"],
                        width = "full",
                        get = GetProfileOption,
                        set = SetProfileOption,
                    },
                    showGroup = {
                        order = 11.2,
                        type = "toggle",
                        name = L["SHOW_GROUP_PROGRESS"],
                        desc = L["SHOW_GROUP_PROGRESS_DESC"],
                        width = "full",
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.party:RefreshPartyFrameAnchor()
                            APR.party:SendGroupMessage()
                        end,
                        disabled = function()
                            return not self.profile.enableAddon
                        end,
                    },
                    groupScale = {
                        order = 11.3,
                        type = "range",
                        name = L["GROUP_SCALE"],
                        desc = L["GROUP_SCALE_DESC"],
                        width = "full",
                        min = 0.01,
                        max = 1,
                        step = 0.05,
                        isPercent = true,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.party:UpdateFrameScale()
                        end,
                        disabled = function()
                            return not self.profile.showGroup
                        end,
                    },
                    resetPartyPosition = {
                        name = L['RESET_CURRENT_STEP_FRAME_POSITION'],
                        order = 11.4,
                        type = 'execute',
                        width = "full",
                        func = function()
                            APR.party:ResetPosition()
                        end,
                        disabled = function()
                            return not self.profile.showGroup or not self.profile.enableAddon
                        end,
                    },
                }
            },
            group_Debug = {
                order = 12,
                type = "group",
                name = L["ENABLE_AND_DEBUG"],
                args = {
                    subgroup_Enable = {
                        order = 1,
                        type = "group",
                        inline = true,
                        name = L["ENABLE_ADDON"],
                        args = {
                            enableAddon = {
                                order = 1.1,
                                type = "toggle",
                                name = L["ENABLE_ADDON"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    -- disabled addon
                                    self:ToggleAddon()
                                end,
                            },

                            showChangeLog = {
                                order = 1.2,
                                type = "toggle",
                                name = L["SHOW_CHANGELOG"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                            },
                            resetPartyPosition = {
                                name = L["SHOW_CHANGELOG"],
                                order = 1.3,
                                type = 'execute',
                                width = "full",
                                func = function()
                                    APR.changelog:ShowChangeLog()
                                end,
                            },
                        }
                    },
                    subgroup_debug = {
                        order = 2,
                        type = "group",
                        inline = true,
                        name = L["DEBUG"],
                        args = {
                            coordinateShow = {
                                order = 2.1,
                                type = "toggle",
                                name = L["COORD_COMMAND"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.coordinate:RefreshFrameAnchor()
                                end,
                                disabled = function()
                                    return not self.profile.enableAddon
                                end,
                            },
                            debug = {
                                order = 2.3,
                                type = "toggle",
                                name = L["DEBUG"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                                disabled = function()
                                    return not self.profile.enableAddon
                                end,
                            },
                            showEvent = {
                                order = 2.4,
                                type = "toggle",
                                name = L["SHOW_EVENT_DEBUG"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
                                disabled = function()
                                    return not self.profile.enableAddon
                                end,
                            },
                            receiveGroupData = {
                                order = 2.5,
                                type = "toggle",
                                name = L["RECEIVE_GROUP_DATA"],
                                desc = L["RECEIVE_GROUP_DATA_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    APR.party:HandleReceiveGroupDataToggle(value)
                                end,
                                disabled = function()
                                    return not self.profile.enableAddon
                                end,
                            },
                        }
                    },
                }
            },
        }
    }

    -- Register setting to the option table
    aceConfig:RegisterOptionsTable(APR.title, optionsTable)

    -- Add settings to bliz option
    APR.Options = aceDialog:AddToBlizOptions(APR.title, APR.title)

    -- Add setting route to bliz option
    aceConfig:RegisterOptionsTable(APR.title .. "/Route", APR.routeconfig:InitRouteConfig())
    APR.OptionsRoute = aceDialog:AddToBlizOptions(APR.title .. "/Route", L["ROUTE"], APR.title)

    -- add profile to bliz option
    aceConfig:RegisterOptionsTable(APR.title .. "/Profile", _G.LibStub("AceDBOptions-3.0"):GetOptionsTable(SettingsDB))
    aceDialog:AddToBlizOptions(APR.title .. "/Profile", L["PROFILES"], APR.title)

    -- Add about to bliz option
    APR.settings:CreateAboutOption()

    local category, layout = Settings.RegisterCanvasLayoutCategory(APR, APR.title);
    APR.settings.category = category
end

function APR.settings:CreateAboutOption()
    local function wrapHelp(text)
        return APR:WrapTextInColorCode(text, "eda55f")
    end

    local function wrapTranslator(text)
        return APR:WrapTextInColorCode(text, "5f9ea0")
    end

    local function commandLine(command, description)
        return wrapHelp(command) .. " - " .. description
    end

    local optionsTable = {
        name = L["ABOUT_HELP"],
        type = "group",
        args = {
            author = {
                order = 1,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = wrapHelp(L["AUTHOR"] .. ": ") .. "Neogeekmo/Neoldric",
            },
            dev = {
                order = 2,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = wrapHelp(L["DEV"] .. ": ") .. "Neogeekmo/Neoldric, Kamian",
            },
            route_designer = {
                order = 2.1,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = wrapHelp(L["ROUTE_DESIGNER"] .. ": ") .. "Pahonix, Ola, Clara",
            },
            support = {
                order = 2.2,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = wrapHelp(L["SUPPORT"] .. ": ") .. "NightofStarrs, Pahonix",
            },
            graphic = {
                order = 2.3,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = wrapHelp(L["GRAPHIC"] .. ": ") .. "Rycia, Neogeekmo/Neoldric",
            },
            Translator = {
                order = 2.4,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = wrapHelp(L["TRANSLATOR"] .. ": ") .. "\n" ..
                    "      " .. wrapTranslator(FRFR .. ": ") .. "Neogeekmo, Jmsche, Mania\n" ..
                    "      " .. wrapTranslator(DEDE .. ": ") .. "Kamian, Movion\n" ..
                    "      " .. wrapTranslator(ESMX .. ": ") .. "Jean\n" ..
                    "      " .. wrapTranslator(RURU .. ": ") .. "ZamestoTV",
            },
            version = {
                order = 2.5,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = wrapHelp(L["VERSION"] .. ": ") .. APR.version,
            },
            header_disable_Auto = {
                order = 3,
                type = "header",
                width = "full",
                name = L["DISABLED_AUTOMATION"],
            },
            blank1 = {
                order = 3.1,
                type = "description",
                width = "full",
                name = " ",
            },
            disable_Auto = {
                order = 3.2,
                type = "description",
                name = L["DISABLED_AUTOMATION_DESC"],
                width = "full",
                fontSize = "medium",
            },
            blank11 = {
                order = 3.3,
                type = "description",
                width = "full",
                name = " ",
            },
            header_help = {
                order = 4,
                type = "header",
                width = "full",
                name = L["HELP"],
            },
            blank0 = {
                order = 4.1,
                type = "description",
                width = "full",
                name = " ",
            },
            command = {
                order = 4.2,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = commandLine("/apr help, h", L["HELP_COMMAND"]) .. "\n" ..
                    commandLine("/apr", L["SHOW_MENU"]) .. "\n" ..
                    commandLine("/apr about", L["SHOW_ABOUT"]) .. "\n" ..
                    commandLine("/apr coord", L["COORD_COMMAND"]) .. "\n" ..
                    commandLine("/apr discord", L["DISCORD_COMMAND"]) .. "\n" ..
                    commandLine("/apr forcereset, fr", L["FORCERESET_COMMAND"]) .. "\n" ..
                    commandLine("/apr github", L["GITHUB_COMMAND"]) .. "\n" ..
                    commandLine("/apr qol", L["QOL_COMMAND"]) .. "\n" ..
                    commandLine("/apr reset, r", L["RESET_COMMAND"]) .. "\n" ..
                    commandLine("/apr resetcustom", L["RESET_CUSTOM_COMMAND"]) .. "\n" ..
                    commandLine("/apr rollback, rb", L["ROLLBACK_COMMAND"]) .. "\n" ..
                    commandLine("/apr route", L["ROUTE_COMMAND"]) .. "\n" ..
                    commandLine("/apr scribe, writer, 42", ";)") .. "\n" ..
                    commandLine("/apr skip, s, skippiedoodaa", L["SKIP_COMMAND"]) .. "\n" ..
                    commandLine("/apr status", L["STATUS_COMMAND"])
            },
            blank01 = {
                order = 4.3,
                type = "description",
                width = "full",
                name = " ",
            },
            header_Credit_legacy = {
                order = 5,
                type = "header",
                width = "full",
                name = L["LEGACY"],
            },
            blank2 = {
                order = 5.1,
                type = "description",
                width = "full",
                name = " ",
            },
            Zyrrael = {
                order = 5.2,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = L["WELCOME_ZYRR"] ..
                    " " .. L["LEGACY_TEAM"] .. " " .. "Deathmessinger, DesMephisto, BrutallStatic",
            },
        }
    }
    aceConfig:RegisterOptionsTable(APR.title .. "/About", optionsTable)
    aceDialog:AddToBlizOptions(APR.title .. "/About", L["ABOUT_HELP"], APR.title)
end

function APR.settings:CreateMiniMapButton()
    if not self.profile.enableMinimapButton then return end

    local minimapButton = libDataBroker:NewDataObject(APR.title, {
        type = "launcher",
        icon = "Interface\\AddOns\\APR\\APR-Core\\assets\\APR_logo",
        OnClick = function(_, button)
            if button == "RightButton" then
                self.profile.enableAddon = not self.profile.enableAddon
                self:ToggleAddon()
            else
                if SettingsPanel:IsShown() then
                    self:CloseSettings()
                else
                    self:OpenSettings(APR.title)
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            local toggleAddon = ''
            if self.profile.enableAddon then
                toggleAddon = APR:WrapTextInColorCode(" " .. L["DISABLE"], "cce0000f")
            else
                toggleAddon = APR:WrapTextInColorCode(" " .. L["ENABLE"], "00ff00")
            end
            tooltip:AddLine(APR.title)
            tooltip:AddLine(L["LEFT_CLICK"] .. ": " .. APR:WrapTextInColorCode(L["SHOW_MENU"], "eda55f"),
                unpack(APR.Color.white))
            tooltip:AddLine(L["RIGHT_CLICK"] .. ": " .. toggleAddon .. " " ..
                APR:WrapTextInColorCode(L["ADDON"], "eda55f"),
                unpack(APR.Color.white))
        end
    })

    libDBIcon:Register(APR.title, minimapButton, self.profile.minimap);
end

function APR.settings:ToggleAddon()
    APR:Debug("Function: APR.settings:ToggleAddon(), state: ", self.profile.enableAddon)
    if not self.profile.enableAddon then
        -- settings disable
        self.profile.showArrow = false
        APR.AFK:HideFrame()
        APR.ArrowFrame:Hide()
        APR.party:SendGroupMessageDelete()
    else
        -- settings
        self.profile.showArrow = true
        APR.Arrow.currentStep = 0
        APR.Arrow:SetCoord()
        APR.party:RequestData()
    end
    APR.currentStep:RefreshCurrentStepFrameAnchor()
    APR.questOrderList:RefreshFrameAnchor()
    APR.party:RefreshPartyFrameAnchor()
    APR.heirloom:RefreshFrameAnchor()
    APR.Buff:RefreshFrameAnchor()
    APR.RouteSelection:RefreshFrameAnchor()
    APR.map:ToggleMapPins()
end

function APR.settings:OpenSettings(name)
    if name == APR.title then
        if InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(APR.title)
        else
            Settings.OpenToCategory(self.category.ID)
        end
        APR.settings:OpenSettings(L["ROUTE"])
    end
    if APR.Options then
        if SettingsPanel then
            local category = SettingsPanel:GetCategoryList():GetCategory(APR.Options.name)
            if category then
                SettingsPanel:Open()
                SettingsPanel:SelectCategory(category)
                if APR.OptionsRoute and category:HasSubcategories() then
                    for _, subcategory in pairs(category:GetSubcategories()) do
                        if subcategory:GetName() == name then
                            SettingsPanel:SelectCategory(subcategory)
                            break
                        end
                    end
                end
            end
            return
        elseif InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(APR.Options)
            if APR.OptionsRoute then
                InterfaceOptionsFrame_OpenToCategory(APR.OptionsRoute)
            end
            return
        else
            Settings.OpenToCategory(self.category.ID)
        end
    end
end

function APR.settings:CloseSettings()
    if APR.Options then
        if SettingsPanel then
            local category = SettingsPanel:GetCategoryList():GetCategory(APR.Options.name)
            if category then
                SettingsPanel:Hide()
            end
            return
        end
    end
end

function APR.settings:SetRewardPriority(info, value)
    local key = info[#info] -- e.g. "rewardPriority2"
    local oldValue = self.profile[key]

    -- Check if another priority already has the value we want to select
    for i = 1, 4 do
        local otherKey = "rewardPriority" .. i
        if otherKey ~= key and self.profile[otherKey] == value then
            -- Swap the value
            self.profile[otherKey] = oldValue
        end
    end
    self.profile[key] = value
end
