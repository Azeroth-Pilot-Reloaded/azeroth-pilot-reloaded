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
            autoHandIn = true,
            autoHandInChoice = false,
            autoGossip = true,
            autoVendor = false,
            autoRepair = false,
            autoSkipCutScene = false,
            autoFlight = true,
            -- current step
            currentStepFrame = {},
            currentStepShow = true,
            currentStepLock = false,
            currentStepScale = 1,
            currentStepbackgroundColorAlpha = { 0, 0, 0, 0.4 },
            currentStepAttachFrameToQuestLog = false,
            currentStepQuestButtonPositionRight = false,
            -- quest order list
            questOrderListFrame = {},
            showQuestOrderList = false,
            questOrderListLock = false,
            questOrderListScale = 1,
            questOrderListbackgroundColorAlpha = { 0, 0, 0, 0.4 },
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
            showMapLineColor = { 80 / 255, 200 / 255, 120 / 255, 0.8 },
            showMapLineThickness = 8,
            mapshowNextSteps = true,
            mapshowNextStepsColor = { 80 / 255, 200 / 255, 120 / 255, 0.8 },
            mapshowNextStepsCount = 2,
            mapshowNextStepsSize = 16,
            mapshowNextStepsTextScale = 1,
            mapshowNextStepsColorText = { 1, 209 / 255, 0, 1 },
            -- minimap
            minimap = { minimapPos = 250 },
            enableMinimapButton = true,
            showMiniMapLine = true,
            showMiniMapLineColor = { 80 / 255, 200 / 255, 120 / 255, 0.8 },
            showMiniMapLineThickness = 2,
            minimapshowNextSteps = true,
            minimapshowNextStepsColor = { 80 / 255, 200 / 255, 120 / 255, 0.8 },
            minimapshowNextStepsCount = 2,
            minimapshowNextStepsSize = 16,
            minimapshowNextStepsTextScale = 1,
            minimapshowNextStepsColorText = { 1, 209 / 255, 0, 1 },
            -- Heirloom
            heirloomFrame = {},
            heirloomWarning = false,
            -- group
            groupFrame = {},
            showGroup = true,
            groupScale = 1,
            -- route
            routeSelectionFrame = {},
            --afk
            afkFrame = {},
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
                width = 1.35,
            },
            resetButton = {
                order = 1.4,
                name = L["RESET_SETTINGS"],
                type = "execute",
                width = 0.75,
                func = function()
                    APR.questionDialog:CreateQuestionPopup(
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
                        end,
                        disabled = function()
                            return not self.profile.currentStepShow or not self.profile.enableAddon or
                                self.profile.currentStepAttachFrameToQuestLog
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
                            APR.BookingList["UpdateMapId"] = true
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
                            self.profile.questOrderListbackgroundColorAlpha = { 0, 0, 0, 0.4 }
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
                    autoSkipCutScene = {
                        order = 8.1,
                        type = "toggle",
                        name = L["SKIPPED_CUTSCENE"],
                        desc = L["SKIPPED_CUTSCENE_DESC"],
                        width = "full",
                        get = GetProfileOption,
                        set = SetProfileOption,
                        disabled = true -- wait for a change on blizz side
                    },
                    autoFlight = {
                        order = 8.2,
                        type = "toggle",
                        name = L["AUTO_USE_FLIGHTPATHS"],
                        desc = L["AUTO_USE_FLIGHTPATHS_DESC"],
                        width = "full",
                        get = GetProfileOption,
                        set = SetProfileOption,
                    },
                    autoHandInChoice = {
                        order = 8.3,
                        type = "toggle",
                        name = L["AUTO_PICK_REWARD_ITEM"],
                        desc = L["AUTO_PICK_REWARD_ITEM_DESC"],
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
                    },
                }
            },
            group_Group = {
                order = 11,
                type = "group",
                name = L["GROUP"],
                args = {
                    showGroup = {
                        order = 11.1,
                        type = "toggle",
                        name = L["SHOW_GROUP_PROGRESS"],
                        desc = L["SHOW_GROUP_PROGRESS_DESC"],
                        width = "full",
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.party:RefreshPartyFrameAnchor()
                        end,
                        disabled = function()
                            return not self.profile.enableAddon
                        end,
                    },
                    groupScale = {
                        order = 11.2,
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
                        order = 11.3,
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
                            debug = {
                                order = 2.1,
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
                                order = 2.2,
                                type = "toggle",
                                name = L["SHOW_EVENT_DEBUG"],
                                width = "full",
                                get = GetProfileOption,
                                set = SetProfileOption,
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
end

function APR.settings:CreateAboutOption()
    local optionsTable = {
        name = L["ABOUT_HELP"],
        type = "group",
        args = {
            dev = {
                order = 1,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = "|cffeda55f" .. L["WELCOME_DEV"] .. ": |r" .. "Neogeekmo, Rycia, 8goldbow",
            },
            route_designer = {
                order = 1.1,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = "|cffeda55f" .. L["ROUTE_DESIGNER"] .. ": |r" .. "Pahonix, Ola",
            },
            support = {
                order = 1.2,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = "|cffeda55f" .. L["WELCOME_SUP"] .. ": |r" .. "NightofStarrs, Pahonix",
            },
            version = {
                order = 1.2,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = "|cffeda55f" .. L["VERSION"] .. ": |r" .. APR.version,
            },
            header_help = {
                order = 2,
                type = "header",
                width = "full",
                name = L["HELP"],
            },
            blank0 = {
                order = 2.1,
                type = "description",
                width = "full",
                name = " ",
            },
            command = {
                order = 2.2,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = "|cffeda55f/apr help, h |r- " .. L["HELP_COMMAND"] .. "\n" ..
                    "|cffeda55f/apr reset, r |r- " .. L["RESET_COMMAND"] .. "\n" ..
                    "|cffeda55f/apr forcereset, fr |r- " .. L["FORCERESET_COMMAND"] .. "\n" ..
                    "|cffeda55f/apr skip, s, skippiedoodaa |r- " .. L["SKIP_COMMAND"] .. "\n" ..
                    "|cffeda55f/apr rollback, rb |r- " .. L["ROLLBACK_COMMAND"] .. "\n" ..
                    "|cffeda55f/apr scribe, writer |r- ;) \n" ..
                    "|cffeda55f/apr discord |r- " .. L["DISCORD_COMMAND"] .. "\n" ..
                    "|cffeda55f/apr github |r- " .. L["GITHUB_COMMAND"]
            },
            blank01 = {
                order = 2.3,
                type = "description",
                width = "full",
                name = " ",
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
            header_Credit_legacy = {
                order = 4,
                type = "header",
                width = "full",
                name = L["LEGACY"],
            },
            blank2 = {
                order = 4.1,
                type = "description",
                width = "full",
                name = " ",
            },
            Zyrrael = {
                order = 4.2,
                type = "description",
                width = "full",
                fontSize = "medium",
                name = L["WELCOME_ZYRR"] .. " " .. L["LEGACY_TEAM"] .. " Deathmessinger, DesMephisto, BrutallStatic",
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
        icon = "Interface\\AddOns\\APR-Core\\assets\\APR_logo",
        OnClick = function(_, button)
            if button == "RightButton" then
                self.profile.enableAddon = not self.profile.enableAddon
                self:ToggleAddon()
            else
                APR.settings:OpenSettings(APR.title)
            end
        end,
        OnTooltipShow = function(tooltip)
            local toggleAddon = ''
            if self.profile.enableAddon then
                toggleAddon = "|ccce0000f " .. L["DISABLE"] .. "|r"
            else
                toggleAddon = "|c33ecc00f " .. L["ENABLE"] .. "|r"
            end
            tooltip:AddLine(APR.title)
            tooltip:AddLine(L["LEFT_CLICK"] .. ": |cffeda55f" .. L["SHOW_MENU"] .. "|r", 1, 1, 1)
            tooltip:AddLine(L["RIGHT_CLICK"] .. ": " .. toggleAddon .. "|cffeda55f " .. L["ADDON"] .. "|r", 1, 1, 1)
        end
    })

    libDBIcon:Register(APR.title, minimapButton, self.profile.minimap);
end

function APR.settings:ToggleAddon()
    if not self.profile.enableAddon then
        -- settings disable
        self.profile.showArrow = false
        APR.AFK:HideFrame()
        APR.ArrowFrame:Hide()
    else
        -- settings
        self.profile.showArrow = true
    end
    APR.currentStep:RefreshCurrentStepFrameAnchor()
    APR.questOrderList:RefreshFrameAnchor()
    APR.party:RefreshPartyFrameAnchor()
    APR.heirloom:RefreshFrameAnchor()
    APR.RouteSelection:RefreshFrameAnchor()
    APR.map:ToggleMapPins()
end

function APR.settings:OpenSettings(name)
    if name == APR.title then
        InterfaceOptionsFrame_OpenToCategory(APR.title)
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
        end
    end
end
