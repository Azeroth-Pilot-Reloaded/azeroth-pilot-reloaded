local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local hbdPins = LibStub("HereBeDragons-Pins-2.0")

-- Initialize APR Map module
APR.map = APR:NewModule("MAP", "AceEvent-3.0")
APR.map:RegisterMessage("APR_MAP_UPDATE", function()
    APR.map:AddMapPins()
end)
---------------------------------------------------------------------------------------
---------------------------------- Dotted Lines ---------------------------------------
---------------------------------------------------------------------------------------

APR.map.minimapLine = {}
APR.map.line = {}

function APR.map:mapIcon()
    for CLi = 1, 20 do
        APR.map.minimapLine[CLi] = APR.map:CreateIcon(APR.map.minimapLine)
        APR.map.line[CLi] = APR.map:CreateIcon(APR.map.line)
    end
end

-- Icon varibles:
--   IsActive -> icon IsActive
--   Progress -> icon position
--   State ->
--      0: The icon is in an initial state or is not moving.
--      1: The icon is moving towards its destination.
--      2 : The icon has completed its movement and is inactive.
--      3 : Another status value specific to your code.
function APR.map:CreateIcon(parent)
    local icon = CreateFrame("Frame", nil, UIParent)
    icon:SetFrameStrata("HIGH")
    icon:SetWidth(5)
    icon:SetHeight(5)

    local texture = icon:CreateTexture(nil, "BACKGROUND")
    texture:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.blp")
    texture:SetAllPoints(icon)

    icon.texture = texture
    icon:SetPoint("CENTER", 0, 0)
    icon:Hide()
    icon.IsActive = false
    icon.Progress = 0
    icon.State = 0
    icon.texture:SetAlpha(APR.settings.profile.miniMapBlobAlpha)

    table.insert(parent, icon)

    return icon
end

-- quest handler
function APR.map:RemoveMinimapLine()
    for CLi = 1, 20 do
        if (self.minimapLine[CLi].IsActive) then
            self.minimapLine[CLi].IsActive = false
            self.minimapLine[CLi].Progress = 0
            self.minimapLine[CLi].State = 0
            hbdPins:RemoveMinimapIcon("APR", self.minimapLine[CLi])
        end
    end
end

function APR.map:RemoveMapLine()
    for CLi = 1, 20 do
        if (self.line[CLi].IsActive) then
            self.line[CLi].IsActive = false
            self.line[CLi].Progress = 0
            self.line[CLi].State = 0
            hbdPins:RemoveWorldMapIcon("APRMap", self.line[CLi])
        end
    end
end

function APR.map:MoveMinimapLine()
    if not APR.settings.profile.showMiniMapBlobs or IsInInstance() then
        self:RemoveMinimapLine()
        return
    end

    local playerMap = C_Map.GetBestMapForUnit("player")
    if not playerMap then
        return
    end

    local CurStep = APRData[APR.Realm][APR.Username][APR.ActiveMap]
    local ix, iy

    if CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep] then
        local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
        if steps and steps["TT"] then
            ix, iy = APR:GetPlayerMapPos(playerMap, steps["TT"]["y"], steps["TT"]["x"])
        else
            return
        end
    else
        return
    end

    local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
    if steps["CRange"] then
        local totalCR = 1

        if APR.QuestStepList[APR.ActiveMap][CurStep + 1] and APR.QuestStepList[APR.ActiveMap][CurStep + 1]["CRange"] then
            totalCR = 3
        end

        for CLi = 1, 20 do
            local px, py = APR:GetPlayerMapPos(playerMap)
            if not px then
                self.minimapLine[CLi].IsActive = false
                self.minimapLine[CLi].Progress = 0
                hbdPins:RemoveMinimapIcon("APR", self.minimapLine[CLi])
            else
                local px2, py2 = px - ix, py - iy

                if self.minimapLine[CLi].IsActive and (self.minimapLine[CLi].State == 0 or self.minimapLine[CLi].State == 1) then
                    self.minimapLine[CLi].Progress = self.minimapLine[CLi].Progress + 0.02

                    if self.minimapLine[CLi].Progress > 0.399 and self.minimapLine[CLi].Progress < 0.409 then
                        local set = 0
                        for CLi2 = 1, 20 do
                            if set == 0 and not self.minimapLine[CLi2].IsActive then
                                self.minimapLine[CLi2].IsActive = true
                                self.minimapLine[CLi2].State = 1
                                set = 1
                            end
                        end
                    end

                    if self.minimapLine[CLi].Progress < 1 then
                        px2 = px - px2 * self.minimapLine[CLi].Progress
                        py2 = py - py2 * self.minimapLine[CLi].Progress
                        self.minimapLine[CLi].State = 1
                        hbdPins:AddMinimapIconMap("APR", self.minimapLine[CLi], playerMap, px2, py2, true, true)
                    else
                        self.minimapLine[CLi].IsActive = true
                        self.minimapLine[CLi].Progress = 0
                        self.minimapLine[CLi].State = 2
                        hbdPins:RemoveMinimapIcon("APR", self.minimapLine[CLi])
                    end
                end
            end
        end

        if not APR.QuestStepList[APR.ActiveMap][CurStep + 1] or APR.QuestStepList[APR.ActiveMap][CurStep + 1]["ZoneDoneSave"] then
            for CLi = 1, 20 do
                hbdPins:RemoveMinimapIcon("APR", self.minimapLine[CLi])
            end
        else
            local ix, iy = APR:GetPlayerMapPos(playerMap, APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["x"])
            for CLi = 1, 20 do
                local px, py = APR:GetPlayerMapPos(playerMap)
                if not px then
                    self.minimapLine[CLi].IsActive = false
                    self.minimapLine[CLi].Progress = 0
                    hbdPins:RemoveMinimapIcon("APR", self.minimapLine[CLi])
                else
                    local px2, py2 = px - ix, py - iy

                    if self.minimapLine[CLi].IsActive and (self.minimapLine[CLi].State == 0 or self.minimapLine[CLi].State == 2) then
                        self.minimapLine[CLi].Progress = self.minimapLine[CLi].Progress + 0.02

                        if self.minimapLine[CLi].Progress < 1 then
                            px2 = px - px2 * self.minimapLine[CLi].Progress
                            py2 = py - py2 * self.minimapLine[CLi].Progress
                            self.minimapLine[CLi].State = 2
                            hbdPins:AddMinimapIconMap("APR", self.minimapLine[CLi], playerMap, px2, py2, true, true)
                        else
                            self.minimapLine[CLi].IsActive = false
                            self.minimapLine[CLi].Progress = 0

                            if totalCR == 3 then
                                self.minimapLine[CLi].IsActive = true
                                self.minimapLine[CLi].State = 3
                            elseif totalCR == 2 then
                                self.minimapLine[CLi].State = 1
                            elseif totalCR == 1 then
                                self.minimapLine[CLi].State = 1
                            end

                            hbdPins:RemoveMinimapIcon("APR", self.minimapLine[CLi])
                        end
                    end
                end
            end
        end

        if totalCR == 3 then
            local ix, iy = APR:GetPlayerMapPos(playerMap, APR.QuestStepList[APR.ActiveMap][CurStep + 2]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 2]["TT"]["x"])
            for CLi = 1, 20 do
                local px, py = APR:GetPlayerMapPos(playerMap, APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["y"],
                    APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["x"])
                if not px then
                    self.minimapLine[CLi].IsActive = false
                    self.minimapLine[CLi].Progress = 0
                    hbdPins:RemoveMinimapIcon("APR", self.minimapLine[CLi])
                else
                    local px2, py2 = px - ix, py - iy

                    if self.minimapLine[CLi].IsActive and (self.minimapLine[CLi].State == 0 or self.minimapLine[CLi].State == 3) then
                        self.minimapLine[CLi].Progress = self.minimapLine[CLi].Progress + 0.02

                        if self.minimapLine[CLi].Progress < 1 then
                            px2 = px - px2 * self.minimapLine[CLi].Progress
                            py2 = py - py2 * self.minimapLine[CLi].Progress
                            self.minimapLine[CLi].State = 3
                            hbdPins:AddMinimapIconMap("APR", self.minimapLine[CLi], playerMap, px2, py2, true, true)
                        else
                            self.minimapLine[CLi].IsActive = false
                            self.minimapLine[CLi].Progress = 0
                            self.minimapLine[CLi].State = 0
                            hbdPins:RemoveMinimapIcon("APR", self.minimapLine[CLi])
                        end
                    end
                end
            end
        end
    else
        local px, py = APR:GetPlayerMapPos(playerMap)
        for CLi = 1, 20 do
            if not px then
                self.minimapLine[CLi].IsActive = false
                self.minimapLine[CLi].Progress = 0
                hbdPins:RemoveMinimapIcon("APR", self.minimapLine[CLi])
            else
                local px2, py2 = px - ix, py - iy

                if self.minimapLine[CLi].IsActive then
                    self.minimapLine[CLi].Progress = self.minimapLine[CLi].Progress + 0.02

                    if self.minimapLine[CLi].Progress > 0.39 and self.minimapLine[CLi].Progress < 0.41 then
                        local set = 0
                        for CLi2 = 1, 20 do
                            if set == 0 and not self.minimapLine[CLi2].IsActive then
                                self.minimapLine[CLi2].IsActive = true
                                set = 1
                            end
                        end
                    end

                    if self.minimapLine[CLi].Progress < 1 then
                        px2 = px - px2 * self.minimapLine[CLi].Progress
                        py2 = py - py2 * self.minimapLine[CLi].Progress
                        hbdPins:AddMinimapIconMap("APR", self.minimapLine[CLi], playerMap, px2, py2, true, true)
                    else
                        self.minimapLine[CLi].IsActive = false
                        self.minimapLine[CLi].Progress = 0
                        hbdPins:RemoveMinimapIcon("APR", self.minimapLine[CLi])
                    end
                end
            end
        end
    end
end

local function MapDelay()
    Delaytime = 0
end

function APR.map:MoveMapLine()
    if IsInInstance() or not APR.settings.profile.showMapBlobs or not UnitPosition("player") then
        self:RemoveMapLine()
        return
    end

    if Delaytime == 1 or (WorldMapFrame:GetMapID() and WorldMapFrame:GetMapID() == 946) then
        return
    end

    if CurMapShown ~= WorldMapFrame:GetMapID() then
        CurMapShown = WorldMapFrame:GetMapID()
        Delaytime = 1
        C_Timer.After(0.2, MapDelay)
        return
    end

    local SetMapIDs = WorldMapFrame:GetMapID() or C_Map.GetBestMapForUnit("player")

    if not SetMapIDs then
        return
    end

    local CurStep = APRData[APR.Realm][APR.Username][APR.ActiveMap]

    if not (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
        return
    end

    local steps = APR.QuestStepList[APR.ActiveMap][CurStep]

    if not (steps and steps["TT"]) then
        return
    end

    local ix, iy = APR:GetPlayerMapPos(SetMapIDs, steps["TT"]["y"], steps["TT"]["x"])

    local steps = APR.QuestStepList[APR.ActiveMap][CurStep]

    if steps["CRange"] then
        local totalCR = 1

        if APR.QuestStepList[APR.ActiveMap][CurStep + 1] and APR.QuestStepList[APR.ActiveMap][CurStep + 1]["CRange"] then
            totalCR = 3
        end

        local px, py = APR:GetPlayerMapPos(SetMapIDs)

        if not px then
            return
        end

        for CLi = 1, 20 do
            local px2, py2 = px - ix, py - iy

            if self.line[CLi].IsActive and (self.line[CLi].State == 0 or self.line[CLi].State == 1) then
                self.line[CLi].Progress = self.line[CLi].Progress + 0.02

                if self.line[CLi].Progress > 0.399 and self.line[CLi].Progress < 0.409 then
                    local set = 0
                    for CLi2 = 1, 20 do
                        if set == 0 and not self.line[CLi2].IsActive then
                            self.line[CLi2].IsActive = true
                            self.line[CLi2].State = 1
                            set = 1
                        end
                    end
                end

                if self.line[CLi].Progress < 1 then
                    px2 = px - px2 * self.line[CLi].Progress
                    py2 = py - py2 * self.line[CLi].Progress
                    self.line[CLi].State = 1
                    hbdPins:AddWorldMapIconMap("APRMap", self.line[CLi], SetMapIDs, px2, py2,
                        HBD_PINS_WORLDMAP_SHOW_PARENT)
                else
                    self.line[CLi].IsActive = true
                    self.line[CLi].Progress = 0
                    self.line[CLi].State = 2
                    hbdPins:RemoveWorldMapIcon("APRMap", self.line[CLi])
                end
            end
        end

        local px, py = APR:GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["y"],
            APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["x"])

        if not APR.QuestStepList[APR.ActiveMap][CurStep + 1] or APR.QuestStepList[APR.ActiveMap][CurStep + 1]["ZoneDoneSave"] then
            for CLi = 1, 20 do
                hbdPins:RemoveWorldMapIcon("APRMap", self.line[CLi])
            end
        else
            local ix, iy = APR:GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["x"])

            for CLi = 1, 20 do
                local px2, py2 = px - ix, py - iy

                if self.line[CLi].IsActive == 1 and (self.line[CLi].State == 0 or self.line[CLi].State == 2) then
                    self.line[CLi].Progress = self.line[CLi].Progress + 0.02

                    if self.line[CLi].Progress < 1 then
                        px2 = px - px2 * self.line[CLi].Progress
                        py2 = py - py2 * self.line[CLi].Progress
                        self.line[CLi].State = 2
                        hbdPins:AddWorldMapIconMap("APRMap", self.line[CLi], SetMapIDs, px2, py2,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        self.line[CLi].IsActive = false
                        self.line[CLi].Progress = 0
                        if totalCR == 3 then
                            self.line[CLi].IsActive = true
                            self.line[CLi].State = 3
                        elseif totalCR == 2 then
                            self.line[CLi].State = 1
                        elseif totalCR == 1 then
                            self.line[CLi].State = 1
                        end
                        hbdPins:RemoveWorldMapIcon("APRMap", self.line[CLi])
                    end
                end
            end
        end

        if totalCR == 3 then
            local px, py = APR:GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["x"])
            local ix, iy = APR:GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep + 2]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 2]["TT"]["x"])

            for CLi = 1, 20 do
                local px2, py2 = px - ix, py - iy

                if self.line[CLi].IsActive and (self.line[CLi].State == 0 or self.line[CLi].State == 3) then
                    self.line[CLi].Progress = self.line[CLi].Progress + 0.02

                    if self.line[CLi].Progress < 1 then
                        px2 = px - px2 * self.line[CLi].Progress
                        py2 = py - py2 * self.line[CLi].Progress
                        self.line[CLi].State = 3
                        hbdPins:AddWorldMapIconMap("APRMap", self.line[CLi], SetMapIDs, px2, py2,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        self.line[CLi].IsActive = false
                        self.line[CLi].Progress = 0
                        self.line[CLi].State = 0
                        hbdPins:RemoveWorldMapIcon("APRMap", self.line[CLi])
                    end
                end
            end
        end
    else
        local px, py = APR:GetPlayerMapPos(SetMapIDs)

        for CLi = 1, 20 do
            if not px then
                self.line[CLi].IsActive = false
                self.line[CLi].Progress = 0
                hbdPins:RemoveWorldMapIcon("APRMap", self.line[CLi])
            else
                local px2, py2 = px - ix, py - iy

                if self.line[CLi].IsActive then
                    self.line[CLi].Progress = self.line[CLi].Progress + 0.02

                    if self.line[CLi].Progress > 0.39 and self.line[CLi].Progress < 0.41 then
                        local set = 0
                        for CLi2 = 1, 20 do
                            if set == 0 and not self.line[CLi2].IsActive then
                                self.line[CLi2].IsActive = true
                                set = 1
                            end
                        end
                    end

                    if self.line[CLi].Progress < 1 then
                        px2 = px - px2 * self.line[CLi].Progress
                        py2 = py - py2 * self.line[CLi].Progress
                        hbdPins:AddWorldMapIconMap("APRMap", self.line[CLi], SetMapIDs, px2, py2,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        self.line[CLi].IsActive = false
                        self.line[CLi].Progress = 0
                        hbdPins:RemoveWorldMapIcon("APRMap", self.line[CLi])
                    end
                end
            end
        end
    end
end

function APR.map:ToggleLine()
    if not APR.settings.profile.enableAddon then
        for CLi = 1, 20 do
            self.minimapLine[CLi]:Hide()
            self.line[CLi]:Hide()
        end
        return
    else
        for CLi = 1, 20 do
            self.minimapLine[CLi]:Show()
            self.line[CLi]:Show()
        end
    end
end

---------------------------------------------------------------------------------------
--------------------------------- Map/Minimap Icons------------------------------------
---------------------------------------------------------------------------------------
APR.map.pinlist = {}
APR.map.minimapPinlist = {}
function APR.map:CreatePin(index, step)
    local pinFrame = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    pinFrame:SetSize(16, 16)
    pinFrame:EnableMouse()
    pinFrame:Hide()

    pinFrame.icon = pinFrame:CreateTexture(nil, "ARTWORK")
    pinFrame.icon:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.tga")
    pinFrame.icon:SetAllPoints(pinFrame)

    pinFrame.text = pinFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalCenter")
    pinFrame.text:SetPoint("CENTER", pinFrame, "CENTER", 0, 0)
    pinFrame.text:SetText(index)

    -- -- GameTooltip
    -- pinFrame:SetScript("OnEnter", function(self)
    --     GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    --     GameTooltip:AddLine(index .. " - " .. APR:GetStepString(step), 1, 1, 1)
    --     GameTooltip:Show()
    -- end)
    -- pinFrame:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    return pinFrame
end

function APR.map:RemoveMapIcons()
    for id, pin in pairs(self.minimapPinlist) do
        pin:Hide()
        pin:ClearAllPoints()
        pin = nil
    end
    for id, pin in pairs(self.pinlist) do
        pin:Hide()
        pin:ClearAllPoints()
        pin = nil
    end
    hbdPins:RemoveAllWorldMapIcons(APR.title)
    hbdPins:RemoveAllMinimapIcons(APR.title)
end

function APR.map:AddMapPins()
    self:RemoveMapIcons()

    local CurStep = APRData[APR.Realm][APR.Username][APR.ActiveMap]
    local mapID = WorldMapFrame:GetMapID() or C_Map.GetBestMapForUnit("player")

    if APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and CurStep then
        for stepIndex, steps in pairs(APR.QuestStepList[APR.ActiveMap]) do
            if steps["TT"] and (stepIndex > CurStep) and (stepIndex < CurStep + 11) then
                if not self.pinlist[stepIndex] then
                    self.pinlist[stepIndex] = self:CreatePin(stepIndex, steps)
                    self.minimapPinlist[stepIndex] = self:CreatePin(stepIndex, steps)
                end

                if not steps["CRange"] then
                    local x, y = APR:GetPlayerMapPos(mapID, steps["TT"]["y"], steps["TT"]["x"], true)
                    if APR.settings.profile.mapshow10NextStep then
                        hbdPins:AddWorldMapIconMap(APR.title, self.pinlist[stepIndex], mapID, x, y, 3)
                    end
                    if APR.settings.profile.minimapshow10NextStep then
                        hbdPins:AddMinimapIconMap(APR.title, self.minimapPinlist[stepIndex], mapID, x, y, true, true)
                    end
                end
            end
        end

        -- Display current step pin
        local currentStep = APR.QuestStepList[APR.ActiveMap][CurStep]
        if currentStep and currentStep["TT"] then
            if not self.pinlist[stepIndex] then
                self.pinlist[CurStep] = self:CreatePin(CurStep, currentStep)
                self.minimapPinlist[CurStep] = self:CreatePin(CurStep, currentStep)
            end
            local x, y = APR:GetPlayerMapPos(mapID, currentStep["TT"]["y"], currentStep["TT"]["x"], true)
            hbdPins:AddWorldMapIconMap(APR.title, self.pinlist[CurStep], mapID, x, y, 3)
            hbdPins:AddMinimapIconMap(APR.title, self.minimapPinlist[CurStep], mapID, x, y, true, true)
        end
    end
end

---------------------------------------------------------------------------------------
------------------------------------ Map Event ----------------------------------------
---------------------------------------------------------------------------------------


APR.map.eventFrame = CreateFrame("Frame")
APR.map.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
APR.map.eventFrame:RegisterEvent("ADDON_LOADED")
APR.map.eventFrame:SetScript("OnEvent", function(self, event, ...)
    if not APR.settings.profile.enableAddon then
        APR.map:RemoveMapIcons()
        return
    end
    if (event == "QUEST_LOG_UPDATE") then
        APR.map:AddMapPins()
    end
    if (event == "ADDON_LOADED") then
        APR.map.dottedLine = self:CreateAnimationGroup()
        APR.map.dottedLine.anim = APR.map.dottedLine:CreateAnimation()
        APR.map.dottedLine.anim:SetDuration(0.1)
        APR.map.dottedLine:SetLooping("REPEAT")
        APR.map.dottedLine:SetScript("OnLoop", function(self, event, ...)
            if next(APR.map.minimapLine) then
                if (APR.settings.profile.showMiniMapBlobs) then
                    APR.map:MoveMinimapLine()
                end
            end
            if next(APR.map.line) then
                if (APR.settings.profile.showMapBlobs) then
                    APR.map:MoveMapLine()
                end
            end
        end)
        APR.map.dottedLine:Play()
    end
end)
