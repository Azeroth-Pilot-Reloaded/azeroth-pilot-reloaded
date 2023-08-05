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

-- TMP variable for route bouton
local auto_path_helper = false
local custom_path = false

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
            autoSkipCutScene = true, -- CutScene
            autoFlight = true,
            -- current step
            showCurrentStep = true,     --showQList
            lockCurrentStep = false,    --Lock
            currentStepScale = 0.5,     --Scale
            -- quest order list
            showQuestOrderList = false, --ShowQuestListOrder
            questOrderListScale = 1,    --OrderListScale
            --Quest button (not working)
            questButtonDetatch = false, -- QuestButtonDetatch
            questButtonsScale = 0.5,    -- QuestButtons
            -- arrow
            showArrow = true,
            lockArrow = false,
            arrowScale = 1,
            arrowFPS = 2,
            arrowleft = _G.GetScreenWidth() / 2.05,
            arrowtop = -(_G.GetScreenHeight() / 1.5),
            -- minimap
            showMiniMapBlobs = true, -- showBlobs
            miniMapBlobAlpha = 0.5,  -- miniMapBlobAlpha
            enableMinimapButton = true,
            minimap = { minimapPos = 250 },
            -- map
            showMapBlobs = true,
            showMap10s = false,
            -- Heirloom
            heirloomWarning = true, -- DisableHeirloomWarning
            -- group
            showGroup = false,
            groupScale = 0.5,
            -- route
            greetings = true, --Greetings2
            -- position
            leftLiz = 150,
            topLiz = -150,
            questListButtonLeft = 150,              -- left
            questListButtonTop = -150,              -- top
            partyLeft = _G.GetScreenWidth() / 2.5,  -- Partyleft
            partyTop = -(_G.GetScreenHeight() / 4), -- Partytop
            sugQuestLeft = 150,                     -- Sugleft
            sugQuestTop = -150,                     -- Sugtop
            --debug
            configMode = false,
            debug = false,
        }
    }

    SettingsDB = LibStub("AceDB-3.0"):New("APRSettings", settingsDBDefaults)

    SettingsDB.RegisterCallback(self, "OnProfileChanged", "RefreshProfile")
    SettingsDB.RegisterCallback(self, "OnProfileCopied", "RefreshProfile")
    SettingsDB.RegisterCallback(self, "OnProfileReset", "RefreshProfile")
    self.profile = SettingsDB.profile
    LoadedProfileKey = SettingsDB.keys.profile -- TODO macro
end

function APR.settings.ChatCommand(input)
    APR:SlashCmd(input)
end

function APR.settings:RefreshProfile()
    self.profile = SettingsDB.profile
    -- C_UI.Reload()
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
                    _G.StaticPopup_Show("Discord_Link")
                end
            },
            githubButton = {
                order = 1.2,
                name = "Github",
                type = "execute",
                width = 0.75,
                func = function()
                    _G.StaticPopup_Show("Github_Link")
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
                    self:ResetSettings()
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
                    showCurrentStep = {
                        order = 5.1,
                        type = "toggle",
                        name = L["SHOW_QLIST"],
                        desc = L["SHOW_QLIST_DESC"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            if not value then
                                for CLi = 1, 10 do
                                    APR.QuestList.QuestFrames[CLi]:Hide()
                                    APR.QuestList.QuestFrames["FS" .. CLi].Button:Hide()
                                    APR.QuestList2["BF" .. CLi]:Hide()
                                end
                            end
                        end
                    },
                    lockCurrentStep = {
                        order = 5.11,
                        type = "toggle",
                        name = L["LOCK_QLIST_WINDOW"],
                        desc = L["LOCK_QLIST_WINDOW_DESC"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = SetProfileOption,
                        disabled = function()
                            return not self.profile.showCurrentStep
                        end,
                    },
                    currentStepScale = {
                        order = 5.2,
                        type = "range",
                        name = L["QLIST_SCALE"],
                        desc = L["QLIST_SCALE_DESC"],
                        width = 'full',
                        min = 0.01,
                        max = 2,
                        step = 0.05,
                        isPercent = true,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            APR.QuestList.ButtonParent:SetScale(value)
                            APR.QuestList.ListFrame:SetScale(value)
                            APR.QuestList21:SetScale(value)
                        end,
                        disabled = function()
                            return not self.profile.showCurrentStep
                        end,
                    },
                    blank_questButtonDetatch = {
                        order = 5.3,
                        type = "description",
                        name = "",
                        width = "full",
                    },
                    questButtonDetatch = {
                        order = 5.4,
                        type = "toggle",
                        name = L["DETACH_Q_ITEM_BTN"],
                        desc = L["DETACH_Q_ITEM_BTN_DESC"],
                        width = optionsWidth,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            if not value then
                                APR.QuestList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
                                    APR.settings.profile.questListButtonLeft,
                                    APR.settings.profile.questListButtonTop)
                                for CLi = 1, 3 do
                                    APR.QuestList2["BF" .. CLi]:SetPoint("BOTTOMLEFT", APR.QuestList21, "BOTTOMLEFT", 0,
                                        -((CLi * 38) + CLi))
                                    APR.QuestList2["BF" .. CLi].APR_Button:SetScale(1)
                                end
                            end
                        end,
                        disabled = function()
                            return not self.profile.showCurrentStep
                        end,
                        hidden = false -- to hide useless/broken settings
                    },
                    questButtonsScale = {
                        order = 5.41,
                        type = "range",
                        name = L["Q_BTN_SCALE"],
                        desc = L["Q_BTN_SCALE_DESC"],
                        width = optionsWidth,
                        min = 0.01,
                        max = 2,
                        step = 0.05,
                        isPercent = true,
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            for CLi = 1, 20 do
                                APR.QuestList2["BF" .. CLi].APR_Button:SetScale(value)
                            end
                        end,
                        disabled = function()
                            return not self.profile.showCurrentStep or not self.profile.questButtonDetatch
                        end,
                        hidden = false -- to hide useless/broken settings
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
                        width = "full",
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            if value then
                                APR.UpdateZoneQuestOrderList("LoadIn")
                                APR.ZoneQuestOrder:Show()
                            else
                                APR.ZoneQuestOrder:Hide()
                            end
                        end
                    },
                    questOrderListScale = {
                        order = 6.2,
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
                            APR.ZoneQuestOrder:SetScale(value)
                        end,
                        disabled = function()
                            return not self.profile.showQuestOrderList
                        end,
                    },
                    resetQuestOrderList = {
                        name = L["RESET_QORDERLIST"],
                        order = 6.3,
                        type = 'execute',
                        width = "full",
                        func = function()
                            APR.ZoneQuestOrder:ClearAllPoints()
                            APR.ZoneQuestOrder:SetPoint("CENTER", UIParent, "CENTER", 1, 1)
                        end
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
                            if value then APR.ArrowActive = 1 end
                        end
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
                        end
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
                            showMapBlobs = {
                                order = 9.4,
                                type = "toggle",
                                name = L["SHOW_BLOBS_ON_MAP"],
                                desc = L["SHOW_BLOBS_ON_MAP_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    if not value then
                                        APR:MoveMapIcons()
                                    end
                                end
                            },
                            showMap10s = {
                                order = 9.41,
                                type = "toggle",
                                name = L["SHOW_STEPS_MAP"],
                                desc = L["SHOW_STEPS_MAP_DESC"], --TODO Disabled need fix looking for todo showMap10s
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    if not value then
                                        APR.HBDP:RemoveAllWorldMapIcons("APRMapOrder")
                                    end
                                end,
                                disabled = true
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
                                order = 9.1,
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
                            showMiniMapBlobs = {
                                order = 9.2,
                                type = "toggle",
                                name = L["SHOW_BLOBS_ON_MINIMAP"],
                                desc = L["SHOW_BLOBS_ON_MINIMAP_DESC"],
                                width = "full",
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    if not value then
                                        APR.RemoveIcons()
                                    end
                                end
                            },
                            miniMapBlobAlpha = {
                                order = 9.21,
                                type = "range",
                                name = L["MINIMAP_BLOB_ALPHA"],
                                desc = L["MINIMAP_BLOB_ALPHA_DESC"],
                                width = "full",
                                min = 0.01,
                                max = 1,
                                step = 0.05,
                                isPercent = true,
                                get = GetProfileOption,
                                set = function(info, value)
                                    SetProfileOption(info, value)
                                    for CLi = 1, 20 do
                                        APR.Icons[CLi].texture:SetAlpha(value)
                                    end
                                end,
                                disabled = function()
                                    return not self.profile.showMiniMapBlobs
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
                            APR.BookingList.PrintQStep = 1
                        end,
                        disabled = true, --TODO Fix HEIRLOOM
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
                            if not value then
                                for CLi = 1, 5 do
                                    APR.PartyList.PartyFrames[CLi]:Hide()
                                    APR.PartyList.PartyFrames2[CLi]:Hide()
                                end
                            end
                        end
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
                            -- SET Scale
                        end,
                        disabled = function()
                            return not self.profile.showGroup
                        end,
                        hidden = true --TODO SCALE
                    },
                }
            },
            header_Debug = {
                order = 12,
                type = "group",
                name = L["DEBUG"],
                args = {
                    debug = {
                        order = 3.1,
                        type = "toggle",
                        name = L["DEBUG"],
                        width = "full",
                        get = GetProfileOption,
                        set = SetProfileOption,
                    },
                    configMode = {
                        order = 3.2,
                        type = "toggle",
                        name = L["CONFIG_MODE"],
                        desc = L["CONFIG_MODE_DESC"],
                        width = "full",
                        get = GetProfileOption,
                        set = function(info, value)
                            SetProfileOption(info, value)
                            if (value) then
                                APR.SettingsOpen = true
                                APR.BookingList["OpenedSettings"] = true
                            else
                                APR.SettingsOpen = false
                                APR.BookingList["ClosedSettings"] = true
                            end
                        end
                    },
                }
            },
        }
    }

    -- Register setting to the option table
    aceConfig:RegisterOptionsTable(APR.title, optionsTable)

    -- Add settings to bliz option
    APR.Options = aceDialog:AddToBlizOptions(APR.title)

    -- Add setting route to bliz option
    APR.settings:CreateRouteOption()

    -- add profile to bliz option
    aceConfig:RegisterOptionsTable(APR.title .. "/Profile", _G.LibStub("AceDBOptions-3.0"):GetOptionsTable(SettingsDB))
    aceDialog:AddToBlizOptions(APR.title .. "/Profile", L["PROFILES"], APR.title)

    -- Add about to bliz option
    APR.settings:CreateAboutOption()
end

function APR.settings:CreateRouteOption()
    local optionsTable = {
        name = L["ROUTE"],
        type = "group",
        args = {
            header_route = {
                order = 2,
                type = "header",
                width = "full",
                name = L["ROUTE_HELPER"],
            },
            auto_path_helper = {
                order = 2.1,
                name = L["AUTO_PATH_HELPER"],
                type = "execute",
                width = 1.8,
                func = function()
                    auto_path_helper = not auto_path_helper
                    if auto_path_helper then
                        APR.LoadInOptionFrame:Show()
                        APR.BookingList["ClosedSettings"] = true
                    else
                        APR.LoadInOptionFrame:Hide()
                    end
                end
            },
            custom_path = {
                order = 2.2,
                name = L["CUSTOM_PATH"],
                type = "execute",
                width = 1.8,
                func = function()
                    custom_path = not custom_path
                    if custom_path then
                        APR.RoutePlan.FG1:Show()
                        APR.BookingList["ClosedSettings"] = true
                    else
                        APR.RoutePlan.FG1:Hide()
                    end
                end
            },
        }
    }
    aceConfig:RegisterOptionsTable(APR.title .. "/Route", optionsTable)
    aceDialog:AddToBlizOptions(APR.title .. "/Route", L["ROUTE"], APR.title)
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
            blank21 = {
                order = 4.3,
                type = "description",
                width = "full",
                name = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
            },
            NEED_HELP = {
                order = 5,
                type = "description",
                fontSize = "medium",
                name = L["NEED_HELP"],
                width = 0.75,
            },
            discordButton = {
                order = 5.1,
                name = L["JOIN_DISCORD"],
                type = "execute",
                width = 0.75,
                func = function()
                    _G.StaticPopup_Show("Discord_Link")
                end
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
        icon = "Interface\\AddOns\\APR-Core\\img\\APR_logo",
        OnClick = function()
            _G.InterfaceOptionsFrame_OpenToCategory(APR.title)
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(APR.title)
            tooltip:AddLine(L["CLICK"] .. ": |cffeda55f" .. L["SHOW_MENU"] .. "|r", 1, 1, 1)
        end
    })

    libDBIcon:Register(APR.title, minimapButton, self.profile.minimap);
end

--Discord frame
_G.StaticPopupDialogs["Discord_Link"] = {
    text = L["COPY_HELPER"],
    hasEditBox = 1,
    button1 = L["CLOSE"],
    OnShow = function(self)
        if APR.discord then
            local box = getglobal(self:GetName() .. "EditBox")
            if box then
                box:SetWidth(275)
                box:SetText(APR.discord)
                box:HighlightText()
                box:SetFocus()
            end
        end
    end,

    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}
-- Github Frame
_G.StaticPopupDialogs["Github_Link"] = {
    text = L["COPY_HELPER"],
    hasEditBox = 1,
    button1 = L["CLOSE"],
    OnShow = function(self)
        if APR.github then
            local box = getglobal(self:GetName() .. "EditBox")
            if box then
                box:SetWidth(275)
                box:SetText(APR.github)
                box:HighlightText()
                box:SetFocus()
            end
        end
    end,

    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}
