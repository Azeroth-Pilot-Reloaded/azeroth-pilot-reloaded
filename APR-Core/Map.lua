local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Initialize APR Map module
APR.map = APR:NewModule("MAP")

APR.Icons = {}
APR.MapIcons = {}

-- oldquest list
function APR.map:mapIcon()
    for CLi = 1, 20 do
        APR["Icons"][CLi] = CreateFrame("Frame", nil, UIParent)
        APR["Icons"][CLi]:SetFrameStrata("HIGH")
        APR["Icons"][CLi]:SetWidth(5)
        APR["Icons"][CLi]:SetHeight(5)
        local t = APR["Icons"][CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.blp")
        t:SetAllPoints(APR["Icons"][CLi])
        APR["Icons"][CLi].texture = t
        APR["Icons"][CLi]:SetPoint("CENTER", 0, 0)
        APR["Icons"][CLi]:Hide()
        APR["Icons"][CLi].P = 0
        APR["Icons"][CLi].A = 0
        APR["Icons"][CLi].D = 0
        APR["Icons"][CLi].texture:SetAlpha(APR.settings.profile.miniMapBlobAlpha)

        APR["MapIcons"][CLi] = CreateFrame("Frame", nil, UIParent)
        APR["MapIcons"][CLi]:SetFrameStrata("HIGH")
        APR["MapIcons"][CLi]:SetWidth(5)
        APR["MapIcons"][CLi]:SetHeight(5)
        local t = APR["MapIcons"][CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.blp")
        t:SetAllPoints(APR["MapIcons"][CLi])
        APR["MapIcons"][CLi].texture = t
        APR["MapIcons"][CLi]:SetPoint("CENTER", 0, 0)
        APR["MapIcons"][CLi]:Hide()
        APR["MapIcons"][CLi].P = 0
        APR["MapIcons"][CLi].A = 0
        APR["MapIcons"][CLi].D = 0
    end
end

-- quest handler
function APR.RemoveIcons()
    for CLi = 1, 20 do
        if (APR["Icons"][CLi].A == 1) then
            APR["Icons"][CLi].A = 0
            APR["Icons"][CLi].P = 0
            APR["Icons"][CLi].D = 0
            APR.HBDP:RemoveMinimapIcon("APR", APR["Icons"][CLi])
        end
    end
end

function APR.RemoveMapIcons()
    for CLi = 1, 20 do
        if (APR["MapIcons"][CLi].A == 1) then
            APR["MapIcons"][CLi].A = 0
            APR["MapIcons"][CLi].P = 0
            APR["MapIcons"][CLi].D = 0
            APR.HBDP:RemoveWorldMapIcon("APRMap", APR["MapIcons"][CLi])
        end
    end
end

-- pointiller
function APR:MoveIcons()
    local d_y, d_x = UnitPosition("player")
    if (IsInInstance() or not APR.settings.profile.showMiniMapBlobs or not d_y) then
        APR.RemoveIcons()
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
            if (APR["Icons"][CLi]["A"] == 1 and (APR["Icons"][CLi]["D"] == 0 or APR["Icons"][CLi]["D"] == 1)) then
                APR["Icons"][CLi]["P"] = APR["Icons"][CLi]["P"] + 0.02
                local test = 0.2
                if (APR["Icons"][CLi]["P"] > 0.399 and APR["Icons"][CLi]["P"] < 0.409) then
                    local set = 0
                    for CLi2 = 1, 20 do
                        if (set == 0 and APR["Icons"][CLi2]["A"] == 0) then
                            APR["Icons"][CLi2]["A"] = 1
                            APR["Icons"][CLi2]["D"] = 1
                            set = 1
                        end
                    end
                end
                if (APR["Icons"][CLi].P < 1) then
                    px2 = px - px2 * APR["Icons"][CLi]["P"]
                    py2 = py - py2 * APR["Icons"][CLi]["P"]
                    APR["Icons"][CLi]["D"] = 1
                    APR.HBDP:AddMinimapIconMap("APR", APR["Icons"][CLi], C_Map.GetBestMapForUnit('player'), px2, py2,
                        true, true)
                else
                    APR["Icons"][CLi]["A"] = 1
                    APR["Icons"][CLi]["P"] = 0
                    APR["Icons"][CLi]["D"] = 2
                    APR.HBDP:RemoveMinimapIcon("APR", APR["Icons"][CLi])
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
                APR.HBDP:RemoveMinimapIcon("APR", APR["Icons"][CLi])
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
                if (APR["Icons"][CLi]["A"] == 1 and (APR["Icons"][CLi]["D"] == 0 or APR["Icons"][CLi]["D"] == 2)) then
                    APR["Icons"][CLi]["P"] = APR["Icons"][CLi]["P"] + 0.02
                    local test = 0.2

                    if (APR["Icons"][CLi].P < 1) then
                        px2 = px - px2 * APR["Icons"][CLi]["P"]
                        py2 = py - py2 * APR["Icons"][CLi]["P"]
                        APR["Icons"][CLi]["D"] = 2
                        APR.HBDP:AddMinimapIconMap("APR", APR["Icons"][CLi], C_Map.GetBestMapForUnit('player'), px2, py2,
                            true, true)
                    else
                        APR["Icons"][CLi]["A"] = 0
                        APR["Icons"][CLi]["P"] = 0
                        if (totalCR == 3) then
                            APR["Icons"][CLi]["A"] = 1
                            APR["Icons"][CLi]["D"] = 3
                        elseif (totalCR == 2) then
                            APR["Icons"][CLi]["D"] = 1
                        elseif (totalCR == 1) then
                            APR["Icons"][CLi]["D"] = 1
                        end
                        APR.HBDP:RemoveMinimapIcon("APR", APR["Icons"][CLi])
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
                if (APR["Icons"][CLi]["A"] == 1 and (APR["Icons"][CLi]["D"] == 0 or APR["Icons"][CLi]["D"] == 3)) then
                    APR["Icons"][CLi]["P"] = APR["Icons"][CLi]["P"] + 0.02
                    local test = 0.2

                    if (APR["Icons"][CLi].P < 1) then
                        px2 = px - px2 * APR["Icons"][CLi]["P"]
                        py2 = py - py2 * APR["Icons"][CLi]["P"]
                        APR["Icons"][CLi]["D"] = 3
                        APR.HBDP:AddMinimapIconMap("APR", APR["Icons"][CLi], C_Map.GetBestMapForUnit('player'), px2, py2,
                            true, true)
                    else
                        APR["Icons"][CLi]["A"] = 0
                        APR["Icons"][CLi]["P"] = 0
                        APR["Icons"][CLi]["D"] = 0
                        APR.HBDP:RemoveMinimapIcon("APR", APR["Icons"][CLi])
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
                APR["Icons"][CLi]["A"] = 0
                APR["Icons"][CLi]["P"] = 0
                APR.HBDP:RemoveMinimapIcon("APR", APR["Icons"][CLi])
            else
                local px2, py2
                px2 = px - ix
                py2 = py - iy
                if (APR["Icons"][CLi]["A"] == 1) then
                    APR["Icons"][CLi]["P"] = APR["Icons"][CLi]["P"] + 0.02
                    local test = 0.2
                    if (APR["Icons"][CLi]["P"] > 0.39 and APR["Icons"][CLi]["P"] < 0.41) then
                        local set = 0
                        for CLi2 = 1, 20 do
                            if (set == 0 and APR["Icons"][CLi2]["A"] == 0) then
                                APR["Icons"][CLi2]["A"] = 1
                                set = 1
                            end
                        end
                    end
                    if (APR["Icons"][CLi].P < 1) then
                        px2 = px - px2 * APR["Icons"][CLi]["P"]
                        py2 = py - py2 * APR["Icons"][CLi]["P"]
                        APR.HBDP:AddMinimapIconMap("APR", APR["Icons"][CLi], C_Map.GetBestMapForUnit('player'), px2, py2,
                            true, true)
                    else
                        APR["Icons"][CLi]["A"] = 0
                        APR["Icons"][CLi]["P"] = 0
                        APR.HBDP:RemoveMinimapIcon("APR", APR["Icons"][CLi])
                    end
                end
            end
        end
    end
end

local function APR_MapDelay()
    Delaytime = 0
end
-- pointiller
function APR:MoveMapIcons()
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
        C_Timer.After(0.2, APR_MapDelay)
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
            if (APR["MapIcons"][CLi]["A"] == 1 and (APR["MapIcons"][CLi]["D"] == 0 or APR["MapIcons"][CLi]["D"] == 1)) then
                APR["MapIcons"][CLi]["P"] = APR["MapIcons"][CLi]["P"] + 0.02
                local test = 0.2
                if (APR["MapIcons"][CLi]["P"] > 0.399 and APR["MapIcons"][CLi]["P"] < 0.409) then
                    local set = 0
                    for CLi2 = 1, 20 do
                        if (set == 0 and APR["MapIcons"][CLi2]["A"] == 0) then
                            APR["MapIcons"][CLi2]["A"] = 1
                            APR["MapIcons"][CLi2]["D"] = 1
                            set = 1
                        end
                    end
                end
                if (APR["MapIcons"][CLi].P < 1) then
                    px2 = px - px2 * APR["MapIcons"][CLi]["P"]
                    py2 = py - py2 * APR["MapIcons"][CLi]["P"]
                    APR["MapIcons"][CLi]["D"] = 1
                    APR.HBDP:AddWorldMapIconMap("APRMap", APR["MapIcons"][CLi], SetMapIDs, px2, py2,
                        HBD_PINS_WORLDMAP_SHOW_PARENT)
                else
                    APR["MapIcons"][CLi]["A"] = 1
                    APR["MapIcons"][CLi]["P"] = 0
                    APR["MapIcons"][CLi]["D"] = 2
                    APR.HBDP:RemoveWorldMapIcon("APRMap", APR["MapIcons"][CLi])
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
                APR.HBDP:RemoveWorldMapIcon("APRMap", APR["MapIcons"][CLi])
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
                if (APR["MapIcons"][CLi]["A"] == 1 and (APR["MapIcons"][CLi]["D"] == 0 or APR["MapIcons"][CLi]["D"] == 2)) then
                    APR["MapIcons"][CLi]["P"] = APR["MapIcons"][CLi]["P"] + 0.02
                    local test = 0.2

                    if (APR["MapIcons"][CLi].P < 1) then
                        px2 = px - px2 * APR["MapIcons"][CLi]["P"]
                        py2 = py - py2 * APR["MapIcons"][CLi]["P"]
                        APR["MapIcons"][CLi]["D"] = 2
                        APR.HBDP:AddWorldMapIconMap("APRMap", APR["MapIcons"][CLi], SetMapIDs, px2, py2,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        APR["MapIcons"][CLi]["A"] = 0
                        APR["MapIcons"][CLi]["P"] = 0
                        if (totalCR == 3) then
                            APR["MapIcons"][CLi]["A"] = 1
                            APR["MapIcons"][CLi]["D"] = 3
                        elseif (totalCR == 2) then
                            APR["MapIcons"][CLi]["D"] = 1
                        elseif (totalCR == 1) then
                            APR["MapIcons"][CLi]["D"] = 1
                        end
                        APR.HBDP:RemoveWorldMapIcon("APRMap", APR["MapIcons"][CLi])
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
                if (APR["MapIcons"][CLi]["A"] == 1 and (APR["MapIcons"][CLi]["D"] == 0 or APR["MapIcons"][CLi]["D"] == 3)) then
                    APR["MapIcons"][CLi]["P"] = APR["MapIcons"][CLi]["P"] + 0.02
                    local test = 0.2

                    if (APR["MapIcons"][CLi].P < 1) then
                        px2 = px - px2 * APR["MapIcons"][CLi]["P"]
                        py2 = py - py2 * APR["MapIcons"][CLi]["P"]
                        APR["MapIcons"][CLi]["D"] = 3
                        APR.HBDP:AddWorldMapIconMap("APRMap", APR["MapIcons"][CLi], SetMapIDs, px2, py2,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        APR["MapIcons"][CLi]["A"] = 0
                        APR["MapIcons"][CLi]["P"] = 0
                        APR["MapIcons"][CLi]["D"] = 0
                        APR.HBDP:RemoveWorldMapIcon("APRMap", APR["MapIcons"][CLi])
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
                APR["MapIcons"][CLi]["A"] = 0
                APR["MapIcons"][CLi]["P"] = 0
                APR.HBDP:RemoveWorldMapIcon("APRMap", APR["MapIcons"][CLi])
            else
                local px2, py2
                px2 = px - ix
                py2 = py - iy
                if (APR["MapIcons"][CLi]["A"] == 1) then
                    APR["MapIcons"][CLi]["P"] = APR["MapIcons"][CLi]["P"] + 0.02
                    local test = 0.2
                    if (APR["MapIcons"][CLi]["P"] > 0.39 and APR["MapIcons"][CLi]["P"] < 0.41) then
                        local set = 0
                        for CLi2 = 1, 20 do
                            if (set == 0 and APR["MapIcons"][CLi2]["A"] == 0) then
                                APR["MapIcons"][CLi2]["A"] = 1
                                set = 1
                            end
                        end
                    end
                    if (APR["MapIcons"][CLi].P < 1) then
                        px2 = px - px2 * APR["MapIcons"][CLi]["P"]
                        py2 = py - py2 * APR["MapIcons"][CLi]["P"]
                        APR.HBDP:AddWorldMapIconMap("APRMap", APR["MapIcons"][CLi], SetMapIDs, px2, py2,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        APR["MapIcons"][CLi]["A"] = 0
                        APR["MapIcons"][CLi]["P"] = 0
                        APR.HBDP:RemoveWorldMapIcon("APRMap", APR["MapIcons"][CLi])
                    end
                end
            end
        end
    end
end

-- quest test
function APR.MakeMapOrderIcons(IdZs)
    if not APR.settings.profile.enableAddon then
        return
    end
    APR["MapZoneIcons"][IdZs] = CreateFrame("Frame", "MapZoneOrderIcons", UIParent)
    APR["MapZoneIcons"][IdZs]:SetFrameStrata("MEDIUM")
    APR["MapZoneIcons"][IdZs]:SetWidth(20)
    APR["MapZoneIcons"][IdZs]:SetHeight(20)
    APR["MapZoneIcons"][IdZs]:SetScale(0.8)
    local t = APR["MapZoneIcons"][IdZs]:CreateTexture(nil, "ARTWORK")
    t:SetTexture("Interface\\Addons\\APR-Core\\Img\\Icon.tga")
    t:SetAllPoints(APR["MapZoneIcons"][IdZs])
    APR["MapZoneIcons"]["FS" .. IdZs] = APR["MapZoneIcons"][IdZs]:CreateFontString("APRMapIconFS" .. IdZs, "ARTWORK",
        "ChatFontNormal")
    APR["MapZoneIcons"]["FS" .. IdZs]:SetParent(APR["MapZoneIcons"][IdZs])
    APR["MapZoneIcons"]["FS" .. IdZs]:SetPoint("CENTER", APR["MapZoneIcons"][IdZs], "CENTER", 0, 0)
    APR["MapZoneIcons"]["FS" .. IdZs]:SetWidth(30)
    APR["MapZoneIcons"]["FS" .. IdZs]:SetHeight(25)
    APR["MapZoneIcons"]["FS" .. IdZs]:SetJustifyH("CENTER")
    APR["MapZoneIcons"]["FS" .. IdZs]:SetFontObject("GameFontNormalSmall")
    APR["MapZoneIcons"]["FS" .. IdZs]:SetText(IdZs)
    APR["MapZoneIcons"]["FS" .. IdZs]:SetTextColor(1, 1, 1)
    APR["MapZoneIconsRed"][IdZs] = CreateFrame("Frame", "MapZoneOrderIconsRed", UIParent)
    APR["MapZoneIconsRed"][IdZs]:SetFrameStrata("MEDIUM")
    APR["MapZoneIconsRed"][IdZs]:SetWidth(20)
    APR["MapZoneIconsRed"][IdZs]:SetHeight(20)
    APR["MapZoneIconsRed"][IdZs]:SetScale(0.6)
    local t = APR["MapZoneIconsRed"][IdZs]:CreateTexture(nil, "HIGH")
    t:SetTexture("Interface\\Addons\\APR-Core\\Img\\RedIcon.tga")
    t:SetAllPoints(APR["MapZoneIconsRed"][IdZs])
    APR["MapZoneIconsRed"]["FS" .. IdZs] = APR["MapZoneIconsRed"][IdZs]:CreateFontString("APRMapIconFS" .. IdZs,
        "ARTWORK",
        "ChatFontNormal")
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetParent(APR["MapZoneIconsRed"][IdZs])
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetPoint("CENTER", APR["MapZoneIconsRed"][IdZs], "CENTER", 0, 0)
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetWidth(30)
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetHeight(25)
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetJustifyH("CENTER")
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetFontObject("GameFontNormalSmall")
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetText(IdZs)
    APR["MapZoneIconsRed"]["FS" .. IdZs]:SetTextColor(1, 1, 1)
end

function APR.MapOrderNumbers()
    APR.HBDP:RemoveAllWorldMapIcons("APRMapOrder")
    local CurStep = APRData[APR.Realm][APR.Name][APR.ActiveMap]
    if (APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and CurStep) then
        local znr = 0
        local SetMapIDs = WorldMapFrame:GetMapID()
        if (SetMapIDs == nil) then
            SetMapIDs = C_Map.GetBestMapForUnit("player")
        end
        for APR_index, APR_value in pairs(APR.QuestStepList[APR.ActiveMap]) do
            znr = znr + 1
            if (APR.QuestStepList[APR.ActiveMap][znr] and APR.QuestStepList[APR.ActiveMap][znr]["TT"] and CurStep < znr and CurStep > (znr - 11)) then
                if (not APR["MapZoneIcons"][znr]) then
                    APR.MakeMapOrderIcons(znr)
                end
                if (not APR.QuestStepList[APR.ActiveMap][znr]["CRange"]) then
                    ix, iy = APR:GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][znr]["TT"]["y"],
                        APR.QuestStepList[APR.ActiveMap][znr]["TT"]["x"], true)
                    if (CurStep < znr) then
                        APR.HBDP:AddWorldMapIconMap("APRMapOrder", APR["MapZoneIconsRed"][znr], SetMapIDs, ix, iy,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    else
                        APR.HBDP:AddWorldMapIconMap("APRMapOrder", APR["MapZoneIcons"][znr], SetMapIDs, ix, iy,
                            HBD_PINS_WORLDMAP_SHOW_PARENT)
                    end
                end
            end
        end
    end
end

APR_QH_EventFrame = CreateFrame("Frame")
APR_QH_EventFrame:RegisterEvent("QUEST_LOG_UPDATE")
APR_QH_EventFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "QUEST_LOG_UPDATE") then
        if (APR.settings.profile.showMap10s and WorldMapFrame:IsShown() and APR.ActiveMap and APRData[APR.Realm][APR.Name][APR.ActiveMap]) then
            local CurStep = APRData[APR.Realm][APR.Name][APR.ActiveMap]
            if (CurStep and MapIconUpdateStep ~= CurStep and CurStep > 1) then
                APR.MapOrderNumbers() -- TODO showMap10s : fix lua error showMap10s
            end
        end
    end
end)
