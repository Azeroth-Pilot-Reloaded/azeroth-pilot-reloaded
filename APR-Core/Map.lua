local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local hbdPins = LibStub("HereBeDragons-Pins-2.0")
local hbd = LibStub("HereBeDragons-2.0")

-- Initialize APR Map module
APR.map = APR:NewModule("MAP", "AceEvent-3.0")
APR.map:RegisterMessage("APR_MAP_UPDATE", function()
    APR.map:AddMapPins()
end)

local COSMIC_MAP_ID = 946
local WORLD_MAP_ID = 947

local cos, sin, max = math.cos, math.sin, math.max
local MinimapRadiusAPI = C_Minimap and C_Minimap.GetViewRadius

-- THX HereBeDragons
local minimap_size = {
    indoor = {
        [0] = 300, -- scale
        [1] = 240, -- 1.25
        [2] = 180, -- 5/3
        [3] = 120, -- 2.5
        [4] = 80,  -- 3.75
        [5] = 50,  -- 6
    },
    outdoor = {
        [0] = 466 + 2 / 3, -- scale
        [1] = 400,         -- 7/6
        [2] = 333 + 1 / 3, -- 1.4
        [3] = 266 + 2 / 6, -- 1.75
        [4] = 200,         -- 7/3
        [5] = 133 + 1 / 3, -- 3.5
    },
}

local minimap_shapes = {
    -- { upper-left, lower-left, upper-right, lower-right }
    ["SQUARE"]                = { false, false, false, false },
    ["CORNER-TOPLEFT"]        = { true, false, false, false },
    ["CORNER-TOPRIGHT"]       = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"]     = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"]    = { false, false, false, true },
    ["SIDE-LEFT"]             = { true, true, false, false },
    ["SIDE-RIGHT"]            = { false, false, true, true },
    ["SIDE-TOP"]              = { true, false, true, false },
    ["SIDE-BOTTOM"]           = { false, true, false, true },
    ["TRICORNER-TOPLEFT"]     = { true, true, true, false },
    ["TRICORNER-TOPRIGHT"]    = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"]  = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { false, true, true, true },
}

---------------------------------------------------------------------------------------
---------------------------------- Dotted Lines ---------------------------------------
---------------------------------------------------------------------------------------
local minimapLine, MapLineFrame, MapLine, MapStartPoint, MapEndPoint
local minimapShape, minimapWidth, minimapHeight, rotateMinimap, indoors, zoom, mapRadius
local WorldMapButton = WorldMapFrame:GetCanvas()

local function UpdateMinimapData()
    minimapShape = GetMinimapShape and minimap_shapes[GetMinimapShape() or "ROUND"]
    minimapWidth = Minimap:GetWidth() / 2
    minimapHeight = Minimap:GetHeight() / 2
    rotateMinimap = GetCVar("rotateMinimap") == "1"
    indoors = GetCVar("minimapZoom") + 0 == Minimap:GetZoom() and "outdoor" or "indoor"
    zoom = Minimap:GetZoom()
    if MinimapRadiusAPI then
        mapRadius = C_Minimap.GetViewRadius()
    else
        mapRadius = minimap_size[indoors][zoom] / 2
    end
    if not APR.settings.profile.showMiniMapLine then
        APR.map:RemoveMinimapLine()
    end
end

function APR.map:OnInit()
    -- Init Minimap Line
    minimapLine = Minimap:CreateLine()
    minimapLine:SetColorTexture(unpack(APR.Color.red))
    minimapLine:SetStartPoint("CENTER", Minimap, 0, 0)
    minimapLine:SetEndPoint("CENTER", Minimap, 0, 0)
    minimapLine:SetColorTexture(unpack(APR.settings.profile.showMiniMapLineColor))
    minimapLine:SetThickness(APR.settings.profile.showMiniMapLineThickness)
    --Init Minimap Data
    UpdateMinimapData()

    --Init Map Line
    MapLineFrame = CreateFrame('frame', nil, WorldMapButton)
    MapLineFrame:SetAllPoints()
    MapLineFrame:SetFrameLevel(15000)

    -- These frames are essentially just placeholders to anchor our line to
    MapStartPoint = CreateFrame('frame', nil, MapLineFrame)
    MapStartPoint:SetSize(1, 1)
    MapEndPoint = CreateFrame('frame', nil, MapLineFrame)
    MapEndPoint:SetSize(1, 1)

    MapLine = MapLineFrame:CreateLine(nil, 'OVERLAY')
    MapLine:Hide()
    MapLine:SetColorTexture(unpack(APR.settings.profile.showMapLineColor))
    MapLine:SetThickness(APR.settings.profile.showMapLineThickness)
    MapLine:SetStartPoint('CENTER', MapStartPoint, 0, 0)
    MapLine:SetEndPoint('CENTER', MapEndPoint, 0, 0)

    -- Init Anim for updating lines
    APR.map.stepLines = APR.map.eventFrame:CreateAnimationGroup()
    APR.map.stepLines.anim = APR.map.stepLines:CreateAnimation()
    APR.map.stepLines.anim:SetDuration(0.1)
    APR.map.stepLines:SetLooping("REPEAT")
    APR.map.stepLines:SetScript("OnLoop", function(self, event, ...)
        if (APR.settings.profile.showMiniMapLine) then
            APR.map:UpdateMinimapLine()
        end
        if (APR.settings.profile.showMapLine) then
            APR.map:UpdateLine()
        end
    end)
    APR.map.stepLines:Play()
end

local function PositionMinimapLine(ox, oy)
    if not minimapLine:IsShown() then
        minimapLine:Show()
    end

    local py, px = UnitPosition("player")

    if not px or not py then
        APR.map:RemoveMinimapLine()
        return
    end
    local deltaX, deltaY = ox - px, oy - py
    -- handle rotation
    if rotateMinimap then
        local facing = GetPlayerFacing()
        local mapSin, mapCos = sin(facing), cos(facing)
        local dx, dy = deltaX, deltaY
        deltaX = dx * mapCos - dy * mapSin
        deltaY = dx * mapSin + dy * mapCos
    end

    -- different minimap shapes
    local isRound = true
    if minimapShape and not (deltaX == 0 or deltaY == 0) then
        isRound = (deltaX < 0) and 1 or 3
        if deltaY < 0 then
            isRound = minimapShape[isRound]
        else
            isRound = minimapShape[isRound + 1]
        end
    end

    -- adapt delta position to the map radius
    local diffX = deltaX / mapRadius
    local diffY = deltaY / mapRadius

    -- calculate distance from the center of the map
    local dist
    if isRound then
        dist = (diffX * diffX + diffY * diffY) / 0.9 ^ 2
    else
        dist = max(diffX * diffX, diffY * diffY) / 0.9 ^ 2
    end

    if dist > 1 then
        dist = dist ^ 0.5
        diffX = diffX / dist
        diffY = diffY / dist
    end

    minimapLine:SetEndPoint("CENTER", Minimap, -diffX * minimapWidth, diffY * minimapHeight)
end

function APR.map:RemoveMinimapLine()
    minimapLine:Hide()
end

function APR.map:UpdateMinimapLine()
    if not APR.settings.profile.enableAddon or not APR.settings.profile.showMiniMapLine or APR.Arrow.x == 0 or not APR:IsInInstanceQuest() then
        self:RemoveMinimapLine()
        return
    end
    if APR.Arrow.Active then
        PositionMinimapLine(APR.Arrow.x, APR.Arrow.y)
        return
    end
    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if CurStep and APR.ActiveRoute and APR.RouteQuestStepList and APR.RouteQuestStepList[APR.ActiveRoute] then
        local steps = APR.RouteQuestStepList[APR.ActiveRoute][CurStep]
        if steps and steps.Coord then
            PositionMinimapLine(steps.Coord.x, steps.Coord.y)
            return
        end
    end
end

function APR.map:RemoveMapLine()
    MapLine:Hide()
end

function APR.map:UpdateLine()
    if not APR.settings.profile.enableAddon or not APR.settings.profile.showMapLine or not WorldMapFrame:IsShown() or APR.Arrow.x == 0 then
        self:RemoveMapLine()
        return
    end
    if WorldMapFrame:GetMapID() == COSMIC_MAP_ID or WorldMapFrame:GetMapID() == WORLD_MAP_ID or not APR:IsInInstanceQuest() then
        self:RemoveMapLine()
        return
    end

    local mapID = WorldMapFrame:GetMapID()
    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if CurStep and APR.ActiveRoute and APR.RouteQuestStepList and APR.RouteQuestStepList[APR.ActiveRoute] then
        local steps = APR.RouteQuestStepList[APR.ActiveRoute][CurStep]
        if steps and steps.Coord then
            local mapHeight, mapWidth = WorldMapButton:GetHeight(), WorldMapButton:GetWidth()
            local playerPos = C_Map.GetPlayerMapPosition(mapID, "player")

            local ox, oy
            if APR.Arrow.Active then
                ox, oy = APR:GetPlayerMapPos(mapID, APR.Arrow.y, APR.Arrow.x)
            else
                ox, oy = APR:GetPlayerMapPos(mapID, steps.Coord.y, steps.Coord.x)
            end
            if not playerPos then
                self:RemoveMapLine()
                return
            end

            MapStartPoint:ClearAllPoints()
            MapEndPoint:ClearAllPoints()
            MapStartPoint:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', playerPos.x * mapWidth, playerPos.y * -mapHeight)
            MapEndPoint:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', ox * mapWidth, oy * -mapHeight)
            MapLine:Show()
            return
        end
    end
end

function APR.map:UpdateMapLineStyle()
    MapLine:SetColorTexture(unpack(APR.settings.profile.showMapLineColor))
    MapLine:SetThickness(APR.settings.profile.showMapLineThickness)
end

function APR.map:UpdateMinimapLineStyle()
    minimapLine:SetColorTexture(unpack(APR.settings.profile.showMiniMapLineColor))
    minimapLine:SetThickness(APR.settings.profile.showMiniMapLineThickness)
end

---------------------------------------------------------------------------------------
--------------------------------- Map/Minimap Icons------------------------------------
---------------------------------------------------------------------------------------
APR.map.pinlist = {}
APR.map.minimapPinlist = {}
function APR.map:CreatePin(index, step, size, color, textColor, textScale)
    local pinFrame = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    pinFrame:SetFrameLevel(16000)
    pinFrame:SetSize(size, size)
    pinFrame:EnableMouse()
    pinFrame:Hide()

    pinFrame.icon = pinFrame:CreateTexture(nil, "OVERLAY")
    pinFrame.icon:SetTexture("Interface\\Addons\\APR-Core\\assets\\Icon.tga")
    pinFrame.icon:SetAllPoints(pinFrame)
    pinFrame.icon:SetVertexColor(unpack(color))

    pinFrame.text = pinFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalCenter")
    pinFrame.text:SetPoint("CENTER", pinFrame, "CENTER", 0, 0)
    pinFrame.text:SetText(index)
    pinFrame.text:SetTextColor(unpack(textColor))
    pinFrame.text:SetTextScale(textScale)

    -- GameTooltip
    -- pinFrame:SetScript("OnEnter", function(self)
    --     local string, key = GetStepString(step)
    --     GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    --     GameTooltip:AddLine(index .. " - " .. string)
    --     GameTooltip:AddLine(step[key],
    --         1,
    --         1, 1)
    --     GameTooltip:Show()
    --     -- " - |cffeda55f" .. C_QuestLog.GetTitleForQuestID(step[key]) or 'unkown' .. "|r"
    -- end)
    -- pinFrame:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    return pinFrame
end

function APR.map:UpdateMapIconsStyle()
    for _, pin in pairs(self.pinlist) do
        pin:SetSize(APR.settings.profile.mapshowNextStepsSize, APR.settings.profile.mapshowNextStepsSize)
        pin.icon:SetVertexColor(unpack(APR.settings.profile.mapshowNextStepsColor))
        pin.text:SetTextColor(unpack(APR.settings.profile.mapshowNextStepsColorText))
        pin.text:SetTextScale(APR.settings.profile.mapshowNextStepsTextScale)
    end
end

function APR.map:UpdateMiniMapIconsStyle()
    for _, pin in pairs(self.minimapPinlist) do
        pin:SetSize(APR.settings.profile.minimapshowNextStepsSize, APR.settings.profile.minimapshowNextStepsSize)
        pin.icon:SetVertexColor(unpack(APR.settings.profile.minimapshowNextStepsColor))
        pin.text:SetTextColor(unpack(APR.settings.profile.minimapshowNextStepsColorText))
        pin.text:SetTextScale(APR.settings.profile.minimapshowNextStepsTextScale)
    end
end

function APR.map:RemoveMapIcons()
    for id, pin in pairs(self.pinlist) do
        pin:Hide()
        pin:ClearAllPoints()
        pin = nil
    end
    hbdPins:RemoveAllWorldMapIcons(self.pinlist)
end

function APR.map:RemoveMiniMapIcons()
    for id, pin in pairs(self.minimapPinlist) do
        pin:Hide()
        pin:ClearAllPoints()
        pin = nil
    end
    hbdPins:RemoveAllMinimapIcons(self.minimapPinlist)
end

function APR.map:AddMapPins()
    self:RemoveMapIcons()
    self:RemoveMiniMapIcons()
    if not APR.settings.profile.enableAddon or not APR.settings.profile.mapshowNextSteps and not APR.settings.profile.minimapshowNextSteps or not CheckIsInRouteZone() then
        return
    end

    local needDisplayWorldPin = true
    local mapID = WorldMapFrame:GetMapID()
    local playermapID = C_Map.GetBestMapForUnit("player")
    if APR.settings.profile.mapshowNextSteps then
        local playerPos = C_Map.GetPlayerMapPosition(mapID, "player")
        if not playerPos then
            needDisplayWorldPin = false
        end
    end

    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if APR.ActiveRoute and APR.RouteQuestStepList and APR.RouteQuestStepList[APR.ActiveRoute] and CurStep then
        local mapshowNextStepsCount = APR.settings.profile.mapshowNextStepsCount
        local minimapshowNextStepsCount = APR.settings.profile.minimapshowNextStepsCount
        local mapStepDisplayed = 0
        local minimapStepDisplayed = 0
        for stepIndex, steps in pairs(APR.RouteQuestStepList[APR.ActiveRoute]) do
            if steps.Coord and (stepIndex >= CurStep) and (stepIndex <= CurStep + math.max(mapshowNextStepsCount, minimapshowNextStepsCount)) then
                if not self.pinlist[stepIndex] then
                    self.pinlist[stepIndex] = self:CreatePin(stepIndex, steps, APR.settings.profile.mapshowNextStepsSize,
                        APR.settings.profile.mapshowNextStepsColor, APR.settings.profile.mapshowNextStepsColorText,
                        APR.settings.profile.mapshowNextStepsTextScale)
                end
                if not self.minimapPinlist[stepIndex] then
                    self.minimapPinlist[stepIndex] = self:CreatePin(stepIndex, steps,
                        APR.settings.profile.minimapshowNextStepsSize, APR.settings.profile.minimapshowNextStepsColor,
                        APR.settings.profile.minimapshowNextStepsColorText,
                        APR.settings.profile.minimapshowNextStepsTextScale)
                end

                local x, y = APR:GetPlayerMapPos(needDisplayWorldPin and mapID or playermapID, steps.Coord.y,
                    steps.Coord.x)
                if x and y then
                    if APR.settings.profile.mapshowNextSteps and needDisplayWorldPin then
                        if mapshowNextStepsCount > mapStepDisplayed then
                            hbdPins:AddWorldMapIconMap(self.pinlist, self.pinlist[stepIndex], mapID, x, y, 3)
                            mapStepDisplayed = mapStepDisplayed + 1
                        end
                    else
                        self:RemoveMapIcons()
                    end
                    if APR.settings.profile.minimapshowNextSteps then
                        if minimapshowNextStepsCount > minimapStepDisplayed then
                            hbdPins:AddMinimapIconMap(self.minimapPinlist, self.minimapPinlist[stepIndex], mapID, x, y,
                                true,
                                true)
                            minimapStepDisplayed = minimapStepDisplayed + 1
                        end
                    else
                        self:RemoveMiniMapIcons()
                    end
                end
            end
        end
    end
end

function APR.map:ToggleMapPins()
    self:AddMapPins()
end

---------------------------------------------------------------------------------------
------------------------------------ Map Event ----------------------------------------
---------------------------------------------------------------------------------------

APR.map.eventFrame = CreateFrame("Frame")
APR.map.eventFrame:RegisterEvent("CVAR_UPDATE")
APR.map.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
APR.map.eventFrame:RegisterEvent("MINIMAP_UPDATE_ZOOM")
APR.map.eventFrame:RegisterEvent("ZONE_CHANGED")
APR.map.eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
APR.map.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
APR.map.eventFrame:RegisterEvent("NEW_WMO_CHUNK")
APR.map.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

APR.map.eventFrame:SetScript("OnEvent", function(self, event, ...)
    if APR.settings.profile.showEvent then
        print("EVENT: Map - ", event)
    end
    if not APR.settings.profile.enableAddon then
        APR.map:RemoveMapIcons()
        return
    end

    if event == "CVAR_UPDATE" then
        local cvar, value = ...
        if cvar == "rotateMinimap" or cvar == "ROTATE_MINIMAP" then
            rotateMinimap = (value == "1")
        end
    elseif event == "PLAYER_LOGIN" then
        rotateMinimap = GetCVar("rotateMinimap") == "1"
    elseif event == "MINIMAP_UPDATE_ZOOM"
        or event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "NEW_WMO_CHUNK"
        or event == "PLAYER_ENTERING_WORLD" then
        UpdateMinimapData()
    elseif (event == "QUEST_LOG_UPDATE") then
        APR.map:AddMapPins()
    end
end)
