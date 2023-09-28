local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local hbdPins = LibStub("HereBeDragons-Pins-2.0")

-- Initialize APR Map module
APR.map = APR:NewModule("MAP")

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
    icon.P = 0
    icon.A = 0
    icon.D = 0
    icon.texture:SetAlpha(APR.settings.profile.miniMapBlobAlpha)

    table.insert(parent, icon)

    return icon
end

-- quest handler
function APR.map:RemoveMinimapLine()
    for CLi = 1, 20 do
        if (APR.map.minimapLine[CLi].A == 1) then
            APR.map.minimapLine[CLi].A = 0
            APR.map.minimapLine[CLi].P = 0
            APR.map.minimapLine[CLi].D = 0
            hbdPins:RemoveMinimapIcon("APR", APR.map.minimapLine[CLi])
        end
    end
end

function APR.map:RemoveMapLine()
    for CLi = 1, 20 do
        if (APR.map.line[CLi].A == 1) then
            APR.map.line[CLi].A = 0
            APR.map.line[CLi].P = 0
            APR.map.line[CLi].D = 0
            hbdPins:RemoveWorldMapIcon("APRMap", APR.map.line[CLi])
        end
    end
end

-- pointiller
function APR.map:MoveMinimapLine()
    local d_y, d_x = UnitPosition("player")
    if (IsInInstance() or not APR.settings.profile.showMiniMapBlobs or not d_y) then
        APR.map:RemoveMinimapLine()
        return
    end
    local CurStep = APRData[APR.Realm][APR.Name][APR.ActiveMap]
    local ix, iy
    if (APR.SettingsOpen and C_Map.GetBestMapForUnit('player')) then
        ix, iy = APR:GetPlayerMapPos(C_Map.GetBestMapForUnit('player'), APR.ArrowActive_Y, APR.ArrowActive_X)
    elseif (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
        local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
        local d_y, d_x = UnitPosition("player")
        if (steps and steps["TT"] and d_y and C_Map.GetBestMapForUnit('player')) then
            ix, iy = APR:GetPlayerMapPos(C_Map.GetBestMapForUnit('player'), steps["TT"]["y"], steps["TT"]["x"])
        else
            return
        end
    else
        return
    end
    local steps
    if (APR.SettingsOpen) then
        steps = {}
        steps["TT"] = {}
        steps["TT"]["y"] = APR.ArrowActive_Y
        steps["TT"]["x"] = APR.ArrowActive_X
    else
        steps = APR.QuestStepList[APR.ActiveMap][CurStep]
    end
    if (steps["CRange"]) then
        local CLi
        local totalCR = 1
        if (APR.QuestStepList[APR.ActiveMap][CurStep + 1] and APR.QuestStepList[APR.ActiveMap][CurStep + 1]["CRange"]) then
            totalCR = 3
        end
        if (not C_Map.GetBestMapForUnit('player')) then
            return
        end
        local px, py = APR:GetPlayerMapPos(C_Map.GetBestMapForUnit('player'))
        if (not px) then
            return
        end
        local CLi, CLi2
        for CLi = 1, 20 do
            local px2, py2
            px2 = px - ix
            py2 = py - iy
            if (APR.map.minimapLine[CLi]["A"] == 1 and (APR.map.minimapLine[CLi]["D"] == 0 or APR.map.minimapLine[CLi]["D"] == 1)) then
                APR.map.minimapLine[CLi]["P"] = APR.map.minimapLine[CLi]["P"] + 0.02
                local test = 0.2
                if (APR.map.minimapLine[CLi]["P"] > 0.399 and APR.map.minimapLine[CLi]["P"] < 0.409) then
                    local set = 0
                    for CLi2 = 1, 20 do
                        if (set == 0 and APR.map.minimapLine[CLi2]["A"] == 0) then
                            APR.map.minimapLine[CLi2]["A"] = 1
                            APR.map.minimapLine[CLi2]["D"] = 1
                            set = 1
                        end
                    end
                end
                if (APR.map.minimapLine[CLi].P < 1) then
                    px2 = px - px2 * APR.map.minimapLine[CLi]["P"]
                    py2 = py - py2 * APR.map.minimapLine[CLi]["P"]
                    APR.map.minimapLine[CLi]["D"] = 1
                    hbdPins:AddMinimapIconMap("APR", APR.map.minimapLine[CLi], C_Map.GetBestMapForUnit('player'), px2,
                        py2,
                        true, true)
                else
                    APR.map.minimapLine[CLi]["A"] = 1
                    APR.map.minimapLine[CLi]["P"] = 0
                    APR.map.minimapLine[CLi]["D"] = 2
                    hbdPins:RemoveMinimapIcon("APR", APR.map.minimapLine[CLi])
                end
            end
        end
        if (not C_Map.GetBestMapForUnit('player')) then
            return
        end
        local px, py = APR:GetPlayerMapPos(C_Map.GetBestMapForUnit('player'),
            APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["y"], APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["x"])
        local CLi, CLi2
        if (not APR.QuestStepList[APR.ActiveMap][CurStep + 1] or APR.QuestStepList[APR.ActiveMap][CurStep + 1]["ZoneDoneSave"]) then
            for CLi = 1, 20 do
                hbdPins:RemoveMinimapIcon("APR", APR.map.minimapLine[CLi])
            end
        else
            if (not C_Map.GetBestMapForUnit('player')) then
                return
            end
            local ix, iy = APR:GetPlayerMapPos(C_Map.GetBestMapForUnit('player'),
                APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]
                ["x"])
            for CLi = 1, 20 do
                local px2, py2
                px2 = px - ix
                py2 = py - iy
                if (APR.map.minimapLine[CLi]["A"] == 1 and (APR.map.minimapLine[CLi]["D"] == 0 or APR.map.minimapLine[CLi]["D"] == 2)) then
                    APR.map.minimapLine[CLi]["P"] = APR.map.minimapLine[CLi]["P"] + 0.02
                    local test = 0.2

                    if (APR.map.minimapLine[CLi].P < 1) then
                        px2 = px - px2 * APR.map.minimapLine[CLi]["P"]
                        py2 = py - py2 * APR.map.minimapLine[CLi]["P"]
                        APR.map.minimapLine[CLi]["D"] = 2
                        hbdPins:AddMinimapIconMap("APR", APR.map.minimapLine[CLi], C_Map.GetBestMapForUnit('player'),
                            px2, py2,
                            true, true)
                    else
                        APR.map.minimapLine[CLi]["A"] = 0
                        APR.map.minimapLine[CLi]["P"] = 0
                        if (totalCR == 3) then
                            APR.map.minimapLine[CLi]["A"] = 1
                            APR.map.minimapLine[CLi]["D"] = 3
                        elseif (totalCR == 2) then
                            APR.map.minimapLine[CLi]["D"] = 1
                        elseif (totalCR == 1) then
                            APR.map.minimapLine[CLi]["D"] = 1
                        end
                        hbdPins:RemoveMinimapIcon("APR", APR.map.minimapLine[CLi])
                    end
                end
            end
        end
        if (totalCR == 3) then
            if (not C_Map.GetBestMapForUnit('player')) then
                return
            end
            local px, py = APR:GetPlayerMapPos(C_Map.GetBestMapForUnit('player'),
                APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]
                ["x"])
            local CLi, CLi2
            local ix, iy = APR:GetPlayerMapPos(C_Map.GetBestMapForUnit('player'),
                APR.QuestStepList[APR.ActiveMap][CurStep + 2]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 2]["TT"]
                ["x"])
            for CLi = 1, 20 do
                local px2, py2
                px2 = px - ix
                py2 = py - iy
                if (APR.map.minimapLine[CLi]["A"] == 1 and (APR.map.minimapLine[CLi]["D"] == 0 or APR.map.minimapLine[CLi]["D"] == 3)) then
                    APR.map.minimapLine[CLi]["P"] = APR.map.minimapLine[CLi]["P"] + 0.02
                    local test = 0.2

                    if (APR.map.minimapLine[CLi].P < 1) then
                        px2 = px - px2 * APR.map.minimapLine[CLi]["P"]
                        py2 = py - py2 * APR.map.minimapLine[CLi]["P"]
                        APR.map.minimapLine[CLi]["D"] = 3
                        hbdPins:AddMinimapIconMap("APR", APR.map.minimapLine[CLi], C_Map.GetBestMapForUnit('player'),
                            px2, py2,
                            true, true)
                    else
                        APR.map.minimapLine[CLi]["A"] = 0
                        APR.map.minimapLine[CLi]["P"] = 0
                        APR.map.minimapLine[CLi]["D"] = 0
                        hbdPins:RemoveMinimapIcon("APR", APR.map.minimapLine[CLi])
                    end
                end
            end
        end
    else
        if (not C_Map.GetBestMapForUnit('player')) then
            return
        end
        local px, py = APR:GetPlayerMapPos(C_Map.GetBestMapForUnit('player'))
        local CLi, CLi2
        for CLi = 1, 20 do
            if (not px) then
                APR.map.minimapLine[CLi]["A"] = 0
                APR.map.minimapLine[CLi]["P"] = 0
                hbdPins:RemoveMinimapIcon("APR", APR.map.minimapLine[CLi])
            else
                local px2, py2
                px2 = px - ix
                py2 = py - iy
                if (APR.map.minimapLine[CLi]["A"] == 1) then
                    APR.map.minimapLine[CLi]["P"] = APR.map.minimapLine[CLi]["P"] + 0.02
                    local test = 0.2
                    if (APR.map.minimapLine[CLi]["P"] > 0.39 and APR.map.minimapLine[CLi]["P"] < 0.41) then
                        local set = 0
                        for CLi2 = 1, 20 do
                            if (set == 0 and APR.map.minimapLine[CLi2]["A"] == 0) then
                                APR.map.minimapLine[CLi2]["A"] = 1
                                set = 1
                            end
                        end
                    end
                    if (APR.map.minimapLine[CLi].P < 1) then
                        px2 = px - px2 * APR.map.minimapLine[CLi]["P"]
                        py2 = py - py2 * APR.map.minimapLine[CLi]["P"]
                        hbdPins:AddMinimapIconMap("APR", APR.map.minimapLine[CLi], C_Map.GetBestMapForUnit('player'),
                            px2, py2,
                            true, true)
                    else
                        APR.map.minimapLine[CLi]["A"] = 0
                        APR.map.minimapLine[CLi]["P"] = 0
                        hbdPins:RemoveMinimapIcon("APR", APR.map.minimapLine[CLi])
                    end
                end
            end
        end
    end
end

local function MapDelay()
    Delaytime = 0
end
-- pointiller
function APR.map:MoveMapLine()
    local d_y, d_x = UnitPosition("player")
    if (IsInInstance() or not APR.settings.profile.showMapBlobs or not d_y) then
        return
    end
    if (Delaytime == 1) then
        return
    end
    if (WorldMapFrame:GetMapID() and WorldMapFrame:GetMapID() == 946) then
        return
    end
    if (CurMapShown ~= WorldMapFrame:GetMapID()) then
        CurMapShown = WorldMapFrame:GetMapID()
        Delaytime = 1
        C_Timer.After(0.2, MapDelay)
        return
    end
    local SetMapIDs = WorldMapFrame:GetMapID()
    if (SetMapIDs == nil) then
        SetMapIDs = C_Map.GetBestMapForUnit("player")
    end
    local CurStep = APRData[APR.Realm][APR.Name][APR.ActiveMap]
    local ix, iy
    if (APR.SettingsOpen) then
        return
    elseif (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
        local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
        if (steps and steps["TT"]) then
            if (not SetMapIDs) then
                return
            end
            ix, iy = APR:GetPlayerMapPos(SetMapIDs, steps["TT"]["y"], steps["TT"]["x"])
        else
            return
        end
    else
        return
    end
    local steps
    if (APR.SettingsOpen) then
        return
    else
        steps = APR.QuestStepList[APR.ActiveMap][CurStep]
    end
    if (steps["CRange"]) then
        local CLi
        local totalCR = 1
        if (APR.QuestStepList[APR.ActiveMap][CurStep + 1] and APR.QuestStepList[APR.ActiveMap][CurStep + 1]["CRange"]) then
            totalCR = 3
        end
        if (not SetMapIDs) then
            return
        end
        local px, py = APR:GetPlayerMapPos(SetMapIDs)
        if (not px) then
            return
        end
        local CLi, CLi2
        for CLi = 1, 20 do
            local px2, py2
            px2 = px - ix
            py2 = py - iy
            if (APR.map.line[CLi]["A"] == 1 and (APR.map.line[CLi]["D"] == 0 or APR.map.line[CLi]["D"] == 1)) then
                APR.map.line[CLi]["P"] = APR.map.line[CLi]["P"] + 0.02
                local test = 0.2
                if (APR.map.line[CLi]["P"] > 0.399 and APR.map.line[CLi]["P"] < 0.409) then
                    local set = 0
                    for CLi2 = 1, 20 do
                        if (set == 0 and APR.map.line[CLi2]["A"] == 0) then
                            APR.map.line[CLi2]["A"] = 1
                            APR.map.line[CLi2]["D"] = 1
                            set = 1
                        end
                    end
                end
                if (APR.map.line[CLi].P < 1) then
                    px2 = px - px2 * APR.map.line[CLi]["P"]
                    py2 = py - py2 * APR.map.line[CLi]["P"]
                    APR.map.line[CLi]["D"] = 1
                    hbdPins:AddWorldMapIconMap("APRMap", APR.map.line[CLi], SetMapIDs, px2, py2,
                        HBD_PINS_WORLDMAP_SHOW_PARENT)
                else
                    APR.map.line[CLi]["A"] = 1
                    APR.map.line[CLi]["P"] = 0
                    APR.map.line[CLi]["D"] = 2
                    hbdPins:RemoveWorldMapIcon("APRMap", APR.map.line[CLi])
                end
            end
        end
        if (not SetMapIDs) then
            return
        end
        local px, py = APR:GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["y"],
            APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["x"])
        local CLi, CLi2
        if (not APR.QuestStepList[APR.ActiveMap][CurStep + 1] or APR.QuestStepList[APR.ActiveMap][CurStep + 1]["ZoneDoneSave"]) then
            for CLi = 1, 20 do
                hbdPins:RemoveWorldMapIcon("APRMap", APR.map.line[CLi])
            end
        else
            if (not SetMapIDs) then
                return
            end
            local ix, iy = APR:GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["x"])
            for CLi = 1, 20 do
                local px2, py2
                px2 = px - ix
                py2 = py - iy
                if (APR.map.line[CLi]["A"] == 1 and (APR.map.line[CLi]["D"] == 0 or APR.map.line[CLi]["D"] == 2)) then
                    APR.map.line[CLi]["P"] = APR.map.line[CLi]["P"] + 0.02
                    local test = 0.2

                    if (APR.map.line[CLi].P < 1) then
                        px2 = px - px2 * APR.map.line[CLi]["P"]
                        py2 = py - py2 * APR.map.line[CLi]["P"]
                        APR.map.line[CLi]["D"] = 2
                        hbdPins:AddWorldMapIconMap("APRMap", APR.map.line[CLi], SetMapIDs, px2, py2,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        APR.map.line[CLi]["A"] = 0
                        APR.map.line[CLi]["P"] = 0
                        if (totalCR == 3) then
                            APR.map.line[CLi]["A"] = 1
                            APR.map.line[CLi]["D"] = 3
                        elseif (totalCR == 2) then
                            APR.map.line[CLi]["D"] = 1
                        elseif (totalCR == 1) then
                            APR.map.line[CLi]["D"] = 1
                        end
                        hbdPins:RemoveWorldMapIcon("APRMap", APR.map.line[CLi])
                    end
                end
            end
        end
        if (totalCR == 3) then
            if (not SetMapIDs) then
                return
            end
            local px, py = APR:GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 1]["TT"]["x"])
            local CLi, CLi2
            local ix, iy = APR:GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep + 2]["TT"]["y"],
                APR.QuestStepList[APR.ActiveMap][CurStep + 2]["TT"]["x"])
            for CLi = 1, 20 do
                local px2, py2
                px2 = px - ix
                py2 = py - iy
                if (APR.map.line[CLi]["A"] == 1 and (APR.map.line[CLi]["D"] == 0 or APR.map.line[CLi]["D"] == 3)) then
                    APR.map.line[CLi]["P"] = APR.map.line[CLi]["P"] + 0.02
                    local test = 0.2

                    if (APR.map.line[CLi].P < 1) then
                        px2 = px - px2 * APR.map.line[CLi]["P"]
                        py2 = py - py2 * APR.map.line[CLi]["P"]
                        APR.map.line[CLi]["D"] = 3
                        hbdPins:AddWorldMapIconMap("APRMap", APR.map.line[CLi], SetMapIDs, px2, py2,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        APR.map.line[CLi]["A"] = 0
                        APR.map.line[CLi]["P"] = 0
                        APR.map.line[CLi]["D"] = 0
                        hbdPins:RemoveWorldMapIcon("APRMap", APR.map.line[CLi])
                    end
                end
            end
        end
    else
        if (not SetMapIDs) then
            return
        end
        local px, py = APR:GetPlayerMapPos(SetMapIDs)
        local CLi, CLi2
        for CLi = 1, 20 do
            if (not px) then
                APR.map.line[CLi]["A"] = 0
                APR.map.line[CLi]["P"] = 0
                hbdPins:RemoveWorldMapIcon("APRMap", APR.map.line[CLi])
            else
                local px2, py2
                px2 = px - ix
                py2 = py - iy
                if (APR.map.line[CLi]["A"] == 1) then
                    APR.map.line[CLi]["P"] = APR.map.line[CLi]["P"] + 0.02
                    local test = 0.2
                    if (APR.map.line[CLi]["P"] > 0.39 and APR.map.line[CLi]["P"] < 0.41) then
                        local set = 0
                        for CLi2 = 1, 20 do
                            if (set == 0 and APR.map.line[CLi2]["A"] == 0) then
                                APR.map.line[CLi2]["A"] = 1
                                set = 1
                            end
                        end
                    end
                    if (APR.map.line[CLi].P < 1) then
                        px2 = px - px2 * APR.map.line[CLi]["P"]
                        py2 = py - py2 * APR.map.line[CLi]["P"]
                        hbdPins:AddWorldMapIconMap("APRMap", APR.map.line[CLi], SetMapIDs, px2, py2,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        APR.map.line[CLi]["A"] = 0
                        APR.map.line[CLi]["P"] = 0
                        hbdPins:RemoveWorldMapIcon("APRMap", APR.map.line[CLi])
                    end
                end
            end
        end
    end
end

function APR.map:ToggleLine()
    if not APR.settings.profile.enableAddon then
        for CLi = 1, 20 do
            APR.map.minimapLine[CLi]:Hide()
            APR.map.line[CLi]:Hide()
        end
        return
    else
        for CLi = 1, 20 do
            APR.map.minimapLine[CLi]:Show()
            APR.map.line[CLi]:Show()
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
    for id, pin in pairs(APR.map.minimapPinlist) do
        pin:Hide()
        pin:ClearAllPoints()
        pin = nil
    end
    for id, pin in pairs(APR.map.pinlist) do
        pin:Hide()
        pin:ClearAllPoints()
        pin = nil
    end
    hbdPins:RemoveAllWorldMapIcons(APR.title)
end

function APR.map:AddMapPins()
    self:RemoveMapIcons()
    if not APR.settings.profile.showMap10s then
        return
    end

    local CurStep = APRData[APR.Realm][APR.Name][APR.ActiveMap]
    local mapID = WorldMapFrame:GetMapID() or C_Map.GetBestMapForUnit("player")

    if APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and CurStep then
        for stepIndex, steps in pairs(APR.QuestStepList[APR.ActiveMap]) do
            if steps["TT"] and (stepIndex >= CurStep) and (stepIndex < CurStep + 11) then
                if not APR.map.pinlist[stepIndex] then
                    self.pinlist[stepIndex] = self:CreatePin(stepIndex, steps)
                    self.minimapPinlist[stepIndex] = self:CreatePin(stepIndex, steps)
                end

                if not steps["CRange"] then
                    local x, y = APR:GetPlayerMapPos(mapID, steps["TT"]["y"], steps["TT"]["x"], true)
                    hbdPins:AddWorldMapIconMap(APR.title, APR.map.pinlist[stepIndex], mapID, x, y, 3)
                    -- hbdPins:AddMinimapIconMap(APR.title, APR.map.minimapPinlist[stepIndex], mapID, x, y, true, true)
                end
            end
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
