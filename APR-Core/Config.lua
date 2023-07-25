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
    SettingsDB = nil
    self:InitializeSettings()
    self:RefreshProfile()
end

function APR.settings:InitializeBlizOptions()
    self:InitializeSettings()
    self:createBlizzOptions()

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
            -- map
            showMapBlobs = true,
            showMap10s = false,
            -- Heirloom
            heirloomWarning = true, -- DisableHeirloomWarning
            -- group
            showGroup = false,
            -- route
            auto_path_helper = false,
            custom_path = false,
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
    APR:SlashCmd(input)
end

function APR.settings:RefreshProfile()
    self.profile = SettingsDB.profile

    if LoadedProfileKey ~= SettingsDB.keys.profile then
        print("Profile changed, Reload UI for settings to take effect")
    end
    C_UI.Reload()
end

function APR.settings:createBlizzOptions()
    -- Setting definition
    local optionsWidth = 1.75
    local optionsTable = {
        name = APR.title .. ' - ' .. APR.version,
        type = "group",
        args = {
            discordButton = {
                order = 1,
                name = "Join Discord", --TODO
                type = "execute",
                width = "normal",
                func = function()
                    _G.StaticPopup_Show("Discord_Link")
                end
            },
            githubButton = {
                order = 1.1,
                name = "Github", --TODO
                type = "execute",
                width = "normal",
                func = function()
                    _G.StaticPopup_Show("Github_Link")
                end
            },
            header_route = {
                order = 2,
                type = "header",
                width = "full",
                name = "Route Helper", --TODO
            },
            auto_path_helper = {
                order = 2.1,
                name = L["AUTO_PATH_HELPER"], --TODO
                type = "execute",
                width = "normal",
                func = function()
                    self.profile.auto_path_helper = not self.profile.auto_path_helper
                    if self.profile.auto_path_helper then
                        APR.LoadInOptionFrame:Show()
                        APR.BookingList["ClosedSettings"] = 1
                    else
                        APR.LoadInOptionFrame:Hide()
                    end
                end
            },
            custom_path = {
                order = 2.2,
                name = L["CUSTOM_PATH"], --TODO
                type = "execute",
                width = "normal",
                func = function()
                    self.profile.custom_path = not self.profile.custom_path
                    if self.profile.custom_path then
                        APR.RoutePlan.FG1:Show()
                        APR.BookingList["ClosedSettings"] = 1
                    else
                        APR.RoutePlan.FG1:Hide()
                    end
                end
            },
            header_automation = {
                order = 3,
                type = "header",
                width = "full",
                name = "Automation", --TODO
            },
            autoAccept = {
                order = 3.1,
                type = "toggle",
                name = L["ACCEPT_Q"],
                desc = "ACCEPT_Q_DESC", --TODO
                width = optionsWidth,
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
                desc = "ACCEPT_Q_ROUTE_DESC", --TODO
                width = optionsWidth,
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
                desc = "TURN_IN_Q_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = SetProfileOption,
            },
            autoHandInChoice = {
                order = 3.2,
                type = "toggle",
                name = L["AUTO_PICK_REWARD_ITEM"],
                desc = "AUTO_PICK_REWARD_ITEM_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = SetProfileOption,
            },
            autoGossip = {
                order = 3.21,
                type = "toggle",
                name = L["AUTO_SELECTION_OF_DIALOG"],
                desc = "AUTO_SELECTION_OF_DIALOG_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = SetProfileOption,
            },
            autoSkipCutScene = {
                order = 3.22,
                type = "toggle",
                name = L["SKIPPED_CUTSCENE"],
                desc = "SKIPPED_CUTSCENE_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = SetProfileOption,
            },
            autoVendor = {
                order = 3.3,
                type = "toggle",
                name = L["AUTO_VENDOR"],
                desc = "AUTO_VENDOR_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = SetProfileOption,
            },
            autoRepair = {
                order = 3.31,
                type = "toggle",
                name = L["AUTO_REPAIR"],
                desc = "AUTO_REPAIR_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = SetProfileOption,
            },
            autoFlight = {
                order = 3.32,
                type = "toggle",
                name = L["AUTO_USE_FLIGHTPATHS"],
                desc = "AUTO_USE_FLIGHTPATHS_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = SetProfileOption,
            },
            header_current_step = {
                order = 4,
                type = "header",
                width = "full",
                name = "Current Step", --TODO
            },
            showCurrentStep = {
                order = 4.1,
                type = "toggle",
                name = L["SHOW_QLIST"],
                desc = "SHOW_QLIST_DESC", --TODO
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
                order = 4.11,
                type = "toggle",
                name = L["LOCK_QLIST_WINDOW"],
                desc = "LOCK_QLIST_WINDOW_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = SetProfileOption,
            },
            activeTargetScale = {
                order = 4.2,
                type = "range",
                name = L["QLIST_SCALE"],
                desc = "QLIST_SCALE_DESC", --TODO
                width = optionsWidth,
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
                end
            },
            header_quest_order_list_step = {
                order = 5,
                type = "header",
                width = "full",
                name = "Quest Order List", --TODO
            },
            showQuestOrderList = {
                order = 5.1,
                type = "toggle",
                name = L["SHOW_QORDERLIST"],
                desc = "SHOW_QORDERLIST_DESC", --TODO
                width = optionsWidth,
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
                order = 5.2,
                type = "range",
                name = L["QORDERLIST_SCALE"],
                desc = "QORDERLIST_SCALE_DESC", --TODO
                width = optionsWidth,
                min = 0.01,
                max = 2,
                step = 0.05,
                isPercent = true,
                get = GetProfileOption,
                set = function(info, value)
                    SetProfileOption(info, value)
                    APR.ZoneQuestOrder:SetScale(value)
                end
            },
            resetQuestOrderList = {
                name = L["RESET_QORDERLIST"],
                order = 5.3,
                type = 'execute',
                func = function()
                    APR.ZoneQuestOrder:ClearAllPoints()
                    APR.ZoneQuestOrder:SetPoint("CENTER", UIParent, "CENTER", 1, 1)
                end
            },
            header_arrow = {
                order = 6,
                type = "header",
                width = "full",
                name = "Arrow", --TODO
            },
            showArrow = {
                order = 6.1,
                type = "toggle",
                name = L["SHOW_ARROW"],
                desc = "SHOW_ARROW_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = function(info, value)
                    SetProfileOption(info, value)
                    if value then APR.ArrowActive = 1 end
                end
            },
            lockArrow = {
                order = 6.11,
                type = "toggle",
                name = L["LOCK_ARROW_WINDOW"],
                desc = "LOCK_ARROW_WINDOW_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = SetProfileOption,
            },
            arrowScale = {
                order = 6.2,
                type = "range",
                name = L["ARROW_SCALE"],
                desc = "ARROW_SCALE_DESC", --TODO
                width = optionsWidth,
                min = 0.01,
                max = 3,
                step = 0.05,
                isPercent = true,
                get = GetProfileOption,
                set = function(info, value)
                    SetProfileOption(info, value)
                    APR.ArrowFrame:SetScale(value)
                end
            },
            arrowFPS = {
                order = 6.21,
                type = "range",
                name = L["UPDATE_ARROW"],
                desc = "UPDATE_ARROW_DESC", --TODO
                width = optionsWidth,
                min = 1,
                max = 100,
                step = 1,
                isPercent = false,
                get = GetProfileOption,
                set = SetProfileOption,
            },
            arrowReset = {
                order = 6.3,
                name = L["RESET_ARROW"], --TODO
                type = "execute",
                width = "normal",
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
            header_map_minimap = {
                order = 7,
                type = "header",
                width = "full",
                name = "Map & Minimap", --TODO
            },
            showMapBlobs = {
                order = 7.1,
                type = "toggle",
                name = L["SHOW_BLOBS_ON_MAP"],
                desc = "SHOW_BLOBS_ON_MAP_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = function(info, value)
                    SetProfileOption(info, value)
                    if not value then
                        APR:MoveMapIcons()
                    end
                end
            },
            showMap10s = {
                order = 7.11,
                type = "toggle",
                name = L["SHOW_STEPS_MAP"],
                desc = "SHOW_STEPS_MAP_DESC", --TODO Disabled need fix looking for todo showMap10s
                width = optionsWidth,
                get = GetProfileOption,
                set = function(info, value)
                    SetProfileOption(info, value)
                    if not value then
                        APR.HBDP:RemoveAllWorldMapIcons("APRMapOrder")
                    end
                end,
                disabled = true
            },
            showMiniMapBlobs = {
                order = 7.2,
                type = "toggle",
                name = L["SHOW_BLOBS_ON_MINIMAP"],
                desc = "SHOW_BLOBS_ON_MINIMAP_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = function(info, value)
                    SetProfileOption(info, value)
                    if not value then
                        APR.RemoveIcons()
                    end
                end
            },
            miniMapBlobAlpha = {
                order = 7.21,
                type = "range",
                name = L["MINIMAP_BLOB_ALPHA"],
                desc = "MINIMAP_BLOB_ALPHA_DESC", --TODO
                width = optionsWidth,
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
                end
            },
            enableMinimapButton = {
                name = "Enable Minimap Button", --TODO
                desc = "Add main options menu to minimap",
                type = "toggle",
                width = optionsWidth,
                order = 7.3,
                set = function(info, value)
                    SetProfileOption(info, value)
                    if value then
                        libDBIcon:Show(APR.title)
                    else
                        libDBIcon:Hide(APR.title)
                    end
                end
            },
            header_other = {
                order = 8,
                type = "header",
                width = "full",
                name = "Other", --TODO
            },
            showGroup = {
                order = 8.1,
                type = "toggle",
                name = L["SHOW_GROUP_PROGRESS"],
                desc = "SHOW_GROUP_PROGRESS_DESC", --TODO
                width = optionsWidth,
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
            heirloomWarning = {
                order = 8.2,
                type = "toggle",
                name = L["DISABLE_HEIRLOOM_WARNING"],
                desc = "DISABLE_HEIRLOOM_WARNING_DESC", --TODO
                width = optionsWidth,
                get = GetProfileOption,
                set = function(info, value)
                    SetProfileOption(info, value)
                    APR.BookingList.PrintQStep = 1
                end,
                disabled = true,
                hidden = false -- to hide useless/broken settings
            },
            questButtonDetatch = {
                order = 8.3,
                type = "toggle",
                name = L["DETACH_Q_ITEM_BTN"],
                desc = "DETACH_Q_ITEM_BTN_DESC", --TODO
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
                hidden = false -- to hide useless/broken settings
            },
            questButtonsScale = {
                order = 8.31,
                type = "range",
                name = L["Q_BTN_SCALE"],
                desc = "Q_BTN_SCALE_DESC", --TODO
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
                    return not self.profile.questButtonDetatch
                end,
                hidden = false -- to hide useless/broken settings
            },
            resetButton = {
                order = 8.4,
                name = "Reset option", --TODO
                type = "execute",
                width = "normal",
                func = function()
                    self:ResetSettings()
                end
            },
        }
    }

    -- Register setting to the option table
    aceConfig:RegisterOptionsTable(APR.title, optionsTable)

    -- Add setting frame to bliz option
    APR.Options = aceDialog:AddToBlizOptions(APR.title)

    -- Get setting frop profile
    aceConfig:RegisterOptionsTable(APR.title .. "/Profile", _G.LibStub("AceDBOptions-3.0"):GetOptionsTable(SettingsDB))
    aceDialog:AddToBlizOptions(APR.title .. "/Profile", "PROFILS", APR.title) -- TODO
end

function APR.settings:UpdateMinimapButton()
    if not self.profile.enableMinimapButton then return end

    if not self.minimapFrame then
        self.minimapFrame = CreateFrame("Frame", "APR_MMMenuFrame",
            UIParent,
            "UIDropDownMenuTemplate")
    end

    local minimapButton = libDataBroker:NewDataObject(APR.title, {
        type = "launcher",
        icon = "Interface\\AddOns\\APR-Core\\img\\APR_logo",
        OnClick = function(_, button)
            APR.InterfaceOptionsFrame_OpenToCategory(APR.title)
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(APR.title)
            tooltip:AddLine("|cff909090Click: |cffffcc00Show Menu|r") -- TODO
        end
    })

    libDBIcon:Register(APR.title, minimapButton, self.profile.minimap);
end

--Discord frame
_G.StaticPopupDialogs["Discord_Link"] = {
    text = "Press Ctrl+C to copy the URL to your clipboard", --TODO
    hasEditBox = 1,
    button1 = "OK",
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
    text = "Press Ctrl+C to copy the URL to your clipboard", --TODO
    hasEditBox = 1,
    button1 = "OK",
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
