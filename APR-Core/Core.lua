--[[
		GLOBAL VARIABLES
		Usable within any APR-NAMEHERE addon, or any addon in general,
		as everything here unless defined local is globally usable outside of this file.
]]--

local app = select(2, ...);
local L = app.L;

APR = {}
APR.Name = UnitName("player")
APR.Realm = string.gsub(GetRealmName(), " ", "")
APR.Faction = UnitFactionGroup("player") -- "Horde" or "Alliance"
APR.Level = UnitLevel("player")
APR.Class = {}
APR.QuestStepList = {}
APR.Heirlooms = 0

APR.SweatBuff = {}
APR.SweatBuff[1] = 0
APR.SweatBuff[2] = 0
APR.SweatBuff[3] = 0

APR.RaceLocale, APR.Race = UnitRace("player")
APR.Class[1],APR.Class[2],APR.Class[3] = UnitClass("player")
APR.QuestList = {} --where the quest parts go
APR.NPCList = {}
APR.Gender = UnitSex("player")
APR.Icons = {}
APR.MapIcons = {}
APR.Breadcrums = {}
APR.ActiveQuests = {}
APR.RegisterChat = C_ChatInfo.RegisterAddonMessagePrefix("APRChat")
APR.LastSent = 0
APR.GroupListSteps = {}
APR.GroupListStepsNr = 1
APR.Version = tonumber(GetAddOnMetadata("APR-Core", "Version"))
local CoreLoadin = 0
APR.AfkTimerVar = 0
APR.QuestListLoadin = 0
APR.ZoneTransfer = 0
APR.BookingList = {}
APR.MapZoneIcons = {}
APR.MapZoneIconsRed = {}
APR.SettingsOpen = 0
APR.InCombat = 0
APR.ProgressShown = 0
APR.BookUpdAfterCombat = 0
APR.QuestListShown = 0
APR.MapLoaded = 0
APR.WQActive = 0
APR.WQSpecialActive = 0

APR.Dinged60 = 0
APR.Dinged60nr = 0
APR.Dinged80 = 0
APR.Dinged80nr = 0
APR.Dinged90 = 0
APR.Dinged90nr = 0
APR.Dinged100 = 0
APR.Dinged100nr = 0
APR.Dinged110 = 0
APR.Dinged1100nr = 0

APR.ArrowActive = 0
APR.ArrowActive_X = 0
APR.ArrowActive_Y = 0
APR.MiniMap_X = 0
APR.MiniMap_Y = 0
APR.MacroUpdaterVar = {}

--[[ -- Useless
	local zzloaded, zzreason = LoadAddOn("APR-Test")
	if (zzloaded) then
			APR.ErrorzFrame = CreateFrame("Frame")
			APR_ErrorrzInTimer = APR.ErrorzFrame:CreateAnimationGroup()
			APR_ErrorrzInTimer.anim = APR_ErrorrzInTimer:CreateAnimation()
			APR_ErrorrzInTimer.anim:SetDuration(3)
			APR_ErrorrzInTimer:SetLooping("REPEAT")
			APR_ErrorrzInTimer:SetScript("OnLoop", function(self, event, ...)
				print("APR-Core: Error - Please disable or delete: APR-Test")
				print("APR-Core: It will not be used anymore.")
				print("------------------------------------------")
			end)
			APR_ErrorrzInTimer:Play()
	end
]]--

function APR.AutoPathOnBeta(ChoiceZ) -- Finds the path to objective probably
	local ZeMap = C_Map.GetBestMapForUnit("player")
	local currentMapId, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
	if (Enum and Enum.UIMapType and Enum.UIMapType.Continent and currentMapId) then
		ZeMap = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent+1, TOP_MOST)
	end
	if (ZeMap and ZeMap["mapID"]) then
		ZeMap = ZeMap["mapID"]
	else
		ZeMap = C_Map.GetBestMapForUnit("player")
	end
	if (ChoiceZ == 1 and (ZeMap == 1409 or ZeMap == 1726 or ZeMap == 1727 or ZeMap == 1728) and APR.Faction == "Alliance") then
		APR_Custom[APR.Name.."-"..APR.Realm] = nil
		APR_Custom[APR.Name.."-"..APR.Realm] = {}
		for CLi = 1, 19 do
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
		end
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"01-10 Exile's Reach")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(1/8) 10-50 Stormwind")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(2/8) 10-50 Tanaan Jungle")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(3/8) 10-50 Shadowmoon")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(4/8) 10-50 Gorgrond")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(5/8) 10-50 Talador")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(6/8) 10-50 Shadowmoon")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(7/8) 10-50 Talador")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(8/8) 10-50 Spires of Arak")
	elseif (ChoiceZ == 1 and APR.Level < 50 and APR.Level > 9 and APR.Faction == "Alliance") then
		APR_Custom[APR.Name.."-"..APR.Realm] = nil
		APR_Custom[APR.Name.."-"..APR.Realm] = {}
		for CLi = 1, 19 do
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
		end
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(1/8) 10-50 Stormwind")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(2/8) 10-50 Tanaan Jungle")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(3/8) 10-50 Shadowmoon")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(4/8) 10-50 Gorgrond")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(5/8) 10-50 Talador")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(6/8) 10-50 Shadowmoon")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(7/8) 10-50 Talador")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(8/8) 10-50 Spires of Arak")
	elseif (ChoiceZ == 1 and (ZeMap == 1409 or ZeMap == 1726 or ZeMap == 1727 or ZeMap == 1728) and APR.Faction == "Horde") then
		APR_Custom[APR.Name.."-"..APR.Realm] = nil
		APR_Custom[APR.Name.."-"..APR.Realm] = {}
		for CLi = 1, 19 do
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
		end
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"01-10 Exile's Reach")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(1/6) 10-50 Orgrimmar")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(2/6) 10-50 Tanaan Jungle")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(3/6) 10-50 Frostfire Ridge")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(4/6) 10-50 Gorgrond")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(5/6) 10-50 Talador")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(6/6) 10-50 Spires of Arak")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(7-extra) 10-50 Nagrand")
	elseif (ChoiceZ == 1 and APR.Level < 50 and APR.Level > 9 and APR.Faction == "Horde") then
		APR_Custom[APR.Name.."-"..APR.Realm] = nil
		APR_Custom[APR.Name.."-"..APR.Realm] = {}
		for CLi = 1, 19 do
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
		end
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(1/6) 10-50 Orgrimmar")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(2/6) 10-50 Tanaan Jungle")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(3/6) 10-50 Frostfire Ridge")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(4/6) 10-50 Gorgrond")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(5/6) 10-50 Talador")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(6/6) 10-50 Spires of Arak")
		tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"(7-extra) 10-50 Nagrand")
	elseif (ZeMap == 1409 or ZeMap == 1726 or ZeMap == 1727) then
		APR_Custom[APR.Name.."-"..APR.Realm] = nil
		APR_Custom[APR.Name.."-"..APR.Realm] = {}
	elseif (ChoiceZ == 1) then
		APR_Custom[APR.Name.."-"..APR.Realm] = nil
		APR_Custom[APR.Name.."-"..APR.Realm] = {}
		for CLi = 1, 19 do
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
		end
	elseif (ChoiceZ == 2) then
		APR_Custom[APR.Name.."-"..APR.Realm] = nil
		APR_Custom[APR.Name.."-"..APR.Realm] = {}
		for CLi = 1, 19 do
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(59770) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"50 The Maw Intro")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(59773) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"50-50 Oribos (Start-Bastion)")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(60056) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"50-52 Bastion (Full)")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(57386) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"52 Oribos (Bastion-Maldraxxus)")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(59874) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"52-54 Maldraxxus (Full)")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(59897) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"54 Oribos (Maldraxxus-Maw)")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(61190) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"54-55 The Maw")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(59974) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"55 Oribos (Maw-Maldraxxus)")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(60737) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"55-55 Maldraxxus")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(60338) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"56 Oribos (Maldrax-Ardenw)")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(58724) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"56-57 Ardenweald (Full)")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(57025) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"57 Oribos (Ardenw-Revend)")
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(57689) == false) then
			tinsert(APR_Custom[APR.Name.."-"..APR.Realm],"57-60 Revendreth (Full)")
		end
	end
	for CLi = 1, 19 do
		if (APR_Custom[APR.Name.."-"..APR.Realm] and APR_Custom[APR.Name.."-"..APR.Realm][CLi]) then
			if (APR_ZoneComplete[APR.Name.."-"..APR.Realm][APR_Custom[APR.Name.."-"..APR.Realm][CLi]]) then
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
			else
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText(APR_Custom[APR.Name.."-"..APR.Realm][CLi])
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Show()
			end
		else
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
		end
	end
	APR1[APR.Realm][APR.Name]["Settings"]["Beta1"] = 1
	APR.RoutePlanCheckPos()
	APR.CheckPosMove()
	APR.BookingList["UpdateMapId"] = 1
end
function APR.getContinent() -- Getting the continent the player is on and its info
	if (APR1["Debug"]) then
		print("Function: APR.getContinent()")
	end
    local mapID = C_Map.GetBestMapForUnit("player")
	if (mapID == 378) then
		return 378
    elseif(mapID) then
        local info = C_Map.GetMapInfo(mapID)
        if(info) then
            while(info and info['mapType'] and info['mapType'] > 2) do
                info = C_Map.GetMapInfo(info['parentMapID'])
            end
            if(info and info['mapType'] == 2) then
                return info['mapID']
            end
        end
    end
end
-- APR Global Variables, UI oriented
BINDING_HEADER_AzerothAutoPilot = "Azeroth Pilot Reloaded" -- Header text for APR's main frame
BINDING_NAME_APR_MACRO = "Quest Item 1"

APR.AfkFrame = CreateFrame("frame", "APR_AfkFrames", UIParent)
APR.AfkFrame:SetWidth(190)
APR.AfkFrame:SetHeight(40)
APR.AfkFrame:SetPoint("CENTER", UIParent, "CENTER",0,150)
APR.AfkFrame:EnableMouse(true)
APR.AfkFrame:SetMovable(true)

--AFK Frame Stuff.. not sure what the AFK frame is yet
local t = APR.AfkFrame:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.AfkFrame)
APR.AfkFrame.texture = t

APR.AfkFrame:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		APR.AfkFrame:StartMoving();
		APR.AfkFrame.isMoving = true;
	end
end)
APR.AfkFrame:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" and APR.AfkFrame.isMoving then
		APR.AfkFrame:StopMovingOrSizing();
		APR.AfkFrame.isMoving = false;
	end
end)
APR.AfkFrame:SetScript("OnHide", function(self)
	if ( APR.AfkFrame.isMoving ) then
		APR.AfkFrame:StopMovingOrSizing();
		APR.AfkFrame.isMoving = false;
	end
end)
APR.AfkFrame.Fontstring = APR.AfkFrame:CreateFontString("APRAFkFont","ARTWORK", "ChatFontNormal")
APR.AfkFrame.Fontstring:SetParent(APR.AfkFrame)
APR.AfkFrame.Fontstring:SetPoint("LEFT", APR.AfkFrame, "LEFT", 10, 0)
APR.AfkFrame.Fontstring:SetFontObject("GameFontNormalLarge")
APR.AfkFrame.Fontstring:SetText("AFK:")
APR.AfkFrame.Fontstring:SetJustifyH("LEFT")
APR.AfkFrame.Fontstring:SetTextColor(1, 1, 0)
APR.AfkFrame:Hide()
-- Likely deals with automatically skipping cutscenes using PlayMovie_hook
local PlayMovie_hook = MovieFrame_PlayMovie
MovieFrame_PlayMovie = function(...)

	if (IsControlKeyDown() or (APR1[APR.Realm][APR.Name]["Settings"]["CutScene"] == 0)) then
		PlayMovie_hook(...) --MovieFrame_PlayMovie, as previously stated
	else
		print("APR: "..L["SKIPPED_CUTSCENE"])
		GameMovieFinished()
	end
end

--Something to do with AFK frame/timer probably
function APR.AFK_Timer(APR_AFkTimeh)
	APR.AfkTimerVar = APR_AFkTimeh + floor(GetTime())
	APR.ArrowEventAFkTimer:Play()
end
function APR.pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0
    local iter = function ()
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
     end
     return iter
end

--Resets settings for APR?
function APR.ResetSettings()
	APR1[APR.Realm][APR.Name]["Settings"] = {}
	APR1[APR.Realm][APR.Name]["Settings"]["left"] = 150
	APR1[APR.Realm][APR.Name]["Settings"]["top"] = -150
	APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = 150
	APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = -150
	APR1[APR.Realm][APR.Name]["Settings"]["Scale"] = UIParent:GetScale()
	APR1[APR.Realm][APR.Name]["Settings"]["Lock"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["Hide"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["alpha"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"] = 150
	APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"] = -150
	APR1[APR.Realm][APR.Name]["Settings"]["Hcampleft"] = 150
	APR1[APR.Realm][APR.Name]["Settings"]["Hcamptop"] = -150
	APR1[APR.Realm][APR.Name]["Settings"]["CutScene"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["ChooseQuests"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] = UIParent:GetScale()
	APR1[APR.Realm][APR.Name]["Settings"]["AutoHandInChoice"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["AutoVendor"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["AutoRepair"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["AutoGossip"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["BannerShow"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ShowBlobs"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"] = 2
	APR1[APR.Realm][APR.Name]["Settings"]["DisableHeirloomWarning"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["MiniMapBlobAlpha"] = 1
	APR1[APR.Realm][APR.Name]["Settings"]["OrderListScale"] = 1
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 0) then
		APR.OptionsFrame.ShowQListCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.ShowQListCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"] == 0) then
		APR.OptionsFrame.ShowGroupCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.ShowGroupCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoGossip"] == 0) then
		APR.OptionsFrame.AutoGossipCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoGossipCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoVendor"] == 0) then
		APR.OptionsFrame.AutoVendorCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoVendorCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoRepair"] == 0) then
		APR.OptionsFrame.AutoRepairCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoRepairCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["Lock"] == 0) then
		APR.OptionsFrame.LockQuestListCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.LockQuestListCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["CutScene"] == 0) then
		APR.OptionsFrame.CutSceneCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.CutSceneCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] == 0) then
		APR.OptionsFrame.AutoAcceptCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoAcceptCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] == 0) then
		APR.OptionsFrame.AutoHandInCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoHandInCheckButton:SetChecked(true)
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["AutoHandInChoice"] == 0) then
		APR.OptionsFrame.AutoHandInChoiceCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.AutoHandInChoiceCheckButton:SetChecked(true)
	end
	-- UI stuff regarding questlist and options frame
	APR.QuestList.ButtonParent:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["Scale"])
	APR.QuestList.ListFrame:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["Scale"])
	APR.QuestList21:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["Scale"])
	APR.OptionsFrame.QuestListScaleSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["Scale"] * 100)
	APR.OptionsFrame.ArrowScaleSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] * 100)

	APR.QuestList.MainFrame:ClearAllPoints()
	APR.QuestList.MainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
	APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"])
	APR.ArrowFrameM:ClearAllPoints()
	APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"], APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"])
	APR.ZoneQuestOrder:ClearAllPoints()
	APR.ZoneQuestOrder:SetPoint("CENTER", UIParent, "CENTER",1,1)
	APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] = UIParent:GetScale()
	APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] = 0
	APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"] = 2
	APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"] = GetScreenWidth() / 2.05
	APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"] = -(GetScreenHeight() / 1.5)
	APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"])
	APR.ArrowFrameM:ClearAllPoints()
	APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"], APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"])
	APR.OptionsFrame.ArrowFpsSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"])
	if (APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] == 0) then
		APR.OptionsFrame.LockArrowCheckButton:SetChecked(false)
	else
		APR.OptionsFrame.LockArrowCheckButton:SetChecked(true)
	end
	APR.OptionsFrame.ArrowScaleSlider:SetValue(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] * 100)
end
-- Chat commands, such as /apr reset, /apr skip, /apr skipcamp
local function APR_SlashCmd(APR_index)
	if (APR_index == "reset") then --Command for making the quest rescan on completion and reset, including previously skipped steps
		print("APR: Resetting Zone.")
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = 1
		APR.BookingList["UpdateQuest"] = 1
		APR.BookingList["PrintQStep"] = 1
	elseif (APR_index == "skip") then
		print("APR: Skipping Quest Step.") -- Command for skipping the current quest step
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
		APR.BookingList["UpdateQuest"] = 1
		APR.BookingList["PrintQStep"] = 1
	elseif (APR_index == "skipcamp") then
		print("APR: Skipping Camp Step.") -- Command for skipping "camp" step
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 14
		APR.BookingList["UpdateQuest"] = 1
		APR.BookingList["PrintQStep"] = 1
	else
		APR.SettingsOpen = 1
		APR.OptionsFrame.MainFrame:Show()
		APR.RemoveIcons()
		APR.BookingList["OpenedSettings"] = 1
	end
end
--More UI stuff, to do with arrowframe
	--Arrowframe is the "arrow" that looks like the tomtom one
APR.ArrowFrameM = CreateFrame("Button", "APR_Arrow", UIParent)
APR.ArrowFrameM:SetHeight(1)
APR.ArrowFrameM:SetWidth(1)
APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
APR.ArrowFrameM:EnableMouse(true)
APR.ArrowFrameM:SetMovable(true)

APR.ArrowFrame = CreateFrame("Button", "APR_Arrow", UIParent)
APR.ArrowFrame:SetHeight(42)
APR.ArrowFrame:SetWidth(56)
APR.ArrowFrame:SetPoint("TOPLEFT", APR.ArrowFrameM, "TOPLEFT", 0, 0)
APR.ArrowFrame:EnableMouse(true)
APR.ArrowFrame:SetMovable(true)
APR.ArrowFrame.arrow = APR.ArrowFrame:CreateTexture(nil, "OVERLAY")
APR.ArrowFrame.arrow:SetTexture("Interface\\Addons\\APR-Core\\Img\\Arrow.blp")
APR.ArrowFrame.arrow:SetAllPoints()
APR.ArrowFrame.distance = APR.ArrowFrame:CreateFontString("distance", "ARTWORK", "ChatFontNormal")
APR.ArrowFrame.distance:SetFontObject("GameFontNormalSmall")
APR.ArrowFrame.distance:SetPoint("TOP", APR.ArrowFrame, "BOTTOM", 0, 0)
APR.ArrowFrame:Hide()
APR.ArrowFrame:SetScript("OnMouseDown", function(self, button) --Mouse clicking arrowframe
	if button == "LeftButton" and not APR.ArrowFrameM.isMoving and APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] == 0 then
		APR.ArrowFrameM:StartMoving();
		APR.ArrowFrameM.isMoving = true;
	end
end)
--Mouse unclicking arrowframe (releasing mouse)
APR.ArrowFrame:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" and APR.ArrowFrameM.isMoving then
		APR.ArrowFrameM:StopMovingOrSizing();
		APR.ArrowFrameM.isMoving = false;
		APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"] = APR.ArrowFrameM:GetLeft()
		APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"] = APR.ArrowFrameM:GetTop() - GetScreenHeight()
		APR.ArrowFrameM:ClearAllPoints()
		APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"], APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"])
	end
end)
--When arrowframe hides
APR.ArrowFrame:SetScript("OnHide", function(self)
	if ( APR.ArrowFrameM.isMoving ) then
		APR.ArrowFrameM:StopMovingOrSizing(); -- prevent it from moving or rescaling in the background, it cant be seen anyways
		APR.ArrowFrameM.isMoving = false;
		APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"] = APR.ArrowFrameM:GetLeft()
		APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"] = APR.ArrowFrameM:GetTop() - GetScreenHeight()
		APR.ArrowFrameM:ClearAllPoints()
		APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"], APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"])
	end
end)

APR.ArrowFrame.Button = CreateFrame("Button", "APR_ArrowActiveButton", APR_ArrowFrame)
APR.ArrowFrame.Button:SetWidth(85)
APR.ArrowFrame.Button:SetHeight(17)
APR.ArrowFrame.Button:SetParent(APR.ArrowFrame)
APR.ArrowFrame.Button:SetPoint("BOTTOM", APR.ArrowFrame, "BOTTOM", 0, -30)
APR.ArrowFrame.Button:SetScript("OnMouseDown", function(self, button)
	APR.ArrowFrame.Button:Hide()
	print("APR: Skipping Waypoint")
	APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
	APR.ArrowActive_X = 0
	APR.ArrowActive_Y = 0
	APR.BookingList["UpdateQuest"] = 1
	APR.BookingList["PrintQStep"] = 1
end)

local t = APR.ArrowFrame.Button:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
t:SetAllPoints(APR.ArrowFrame.Button)
APR.ArrowFrame.Button.texture = t

APR.ArrowFrame.Fontstring = APR.ArrowFrame:CreateFontString("CLSettingsFS2212","ARTWORK", "ChatFontNormal")
APR.ArrowFrame.Fontstring:SetParent(APR.ArrowFrame.Button)
APR.ArrowFrame.Fontstring:SetPoint("CENTER", APR.ArrowFrame.Button, "CENTER", 0, 0)

APR.ArrowFrame.Fontstring:SetFontObject("GameFontNormalSmall")
APR.ArrowFrame.Fontstring:SetText("Skip waypoint")
APR.ArrowFrame.Fontstring:SetTextColor(1, 1, 0)
APR.ArrowFrame.Button:Hide()

function APR.RoutePlanLoadIn() --Loads RoutePlan and option frame. RoutePlan is gui that pops when you hit "Custom Path" and a gui comes up allowing you to order them

	if (APR1["Debug"]) then
		print("Function: APR.RoutePlanLoadIn()")
	end

	APR.LoadInOptionFrame = CreateFrame("frame", "APR_LoadInOptionFrame", UIParent)
	APR.LoadInOptionFrame:SetWidth(350)
	APR.LoadInOptionFrame:SetHeight(130)
	APR.LoadInOptionFrame:SetMovable(true)
	APR.LoadInOptionFrame:EnableMouse(true)
	APR.LoadInOptionFrame:SetFrameStrata("LOW")
	APR.LoadInOptionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
	local t = APR.LoadInOptionFrame:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.LoadInOptionFrame)
	APR.LoadInOptionFrame.texture = t

	APR.LoadInOptionFrame:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				APR.LoadInOptionFrame:StartMoving();
				APR.LoadInOptionFrame.isMoving = true;
			end
	end)
	APR.LoadInOptionFrame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and APR.LoadInOptionFrame.isMoving then
			APR.LoadInOptionFrame:StopMovingOrSizing();
			APR.LoadInOptionFrame.isMoving = false;
		end
	end)
	APR.LoadInOptionFrame:SetScript("OnHide", function(self)
		if ( APR.LoadInOptionFrame.isMoving ) then
			APR.LoadInOptionFrame:StopMovingOrSizing();
			APR.LoadInOptionFrame.isMoving = false;
		end
	end)
	APR.LoadInOptionFrame["FS"] = APR.LoadInOptionFrame:CreateFontString("APR_LoadInOptionFrameFS","ARTWORK", "ChatFontNormal")
	APR.LoadInOptionFrame["FS"]:SetParent(APR.LoadInOptionFrame)
	APR.LoadInOptionFrame["FS"]:SetPoint("TOP",APR.LoadInOptionFrame,"TOP",0,0)
	APR.LoadInOptionFrame["FS"]:SetWidth(165)
	APR.LoadInOptionFrame["FS"]:SetHeight(20)
	APR.LoadInOptionFrame["FS"]:SetJustifyH("CENTER")
	APR.LoadInOptionFrame["FS"]:SetFontObject("GameFontNormalLarge")
	APR.LoadInOptionFrame["FS"]:SetText("APR: Pick Route")
	APR.LoadInOptionFrame["B1"] = CreateFrame("Button", "APR_LoadInOptionFrameButton1", APR.LoadInOptionFrame, "UIPanelButtonTemplate")
	APR.LoadInOptionFrame["B1"]:SetWidth(140)
	APR.LoadInOptionFrame["B1"]:SetHeight(30)
	APR.LoadInOptionFrame["B1"]:SetText("Speed Run")
	APR.LoadInOptionFrame["B1"]:SetPoint("TOPLEFT", APR.LoadInOptionFrame, "TOPLEFT", 20, -35)
	APR.LoadInOptionFrame["B1"]:SetNormalFontObject("GameFontNormalLarge")
	APR.LoadInOptionFrame["B1"]:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			APR.AutoPathOnBeta(1)
			APR.LoadInOptionFrame:Hide()
		end
	end)

	APR.LoadInOptionFrame["B2"] = CreateFrame("Button", "APR_LoadInOptionFrameButton2", APR.LoadInOptionFrame, "UIPanelButtonTemplate")
	APR.LoadInOptionFrame["B2"]:SetWidth(140)
	APR.LoadInOptionFrame["B2"]:SetHeight(30)
	APR.LoadInOptionFrame["B2"]:SetText("All Quests")
APR.LoadInOptionFrame["B2"]:Hide()
	APR.LoadInOptionFrame["B2"]:SetPoint("TOPRIGHT", APR.LoadInOptionFrame, "TOPRIGHT", -20, -35)
	APR.LoadInOptionFrame["B2"]:SetNormalFontObject("GameFontNormalLarge")
	APR.LoadInOptionFrame["B2"]:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			APR.AutoPathOnBeta(2)
			APR.LoadInOptionFrame:Hide()
		end
	end)
	APR.LoadInOptionFrame["B3"] = CreateFrame("Button", "APR_LoadInOptionFrameButton3", APR.LoadInOptionFrame, "UIPanelButtonTemplate")
	APR.LoadInOptionFrame["B3"]:SetWidth(140)
	APR.LoadInOptionFrame["B3"]:SetHeight(30)
	APR.LoadInOptionFrame["B3"]:SetText("Custom Path")
	APR.LoadInOptionFrame["B3"]:SetPoint("BOTTOM", APR.LoadInOptionFrame, "BOTTOM", 0, 25)
	APR.LoadInOptionFrame["B3"]:SetNormalFontObject("GameFontNormalLarge")
	APR.LoadInOptionFrame["B3"]:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			APR.RoutePlan.FG1:Show()
			APR.LoadInOptionFrame:Hide()
		end
	end)

	APR.RoutePlan = CreateFrame("frame", "APR.RoutePlanMainFraexg1", UIParent)
	APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
	APR.RoutePlan:SetWidth(1)
	APR.RoutePlan:SetHeight(1)
	APR.RoutePlan:SetMovable(true)
	APR.RoutePlan:EnableMouse(true)
	APR.RoutePlan:SetFrameStrata("LOW")
	APR.RoutePlan.FG1 = CreateFrame("frame", "APR.RoutePlanMainFramexg1", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1:SetWidth(1)
	APR.RoutePlan.FG1:SetHeight(1)
	APR.RoutePlan.FG1:SetMovable(true)
	APR.RoutePlan.FG1:EnableMouse(true)
	APR.RoutePlan.FG1:SetFrameStrata("LOW")
	APR.RoutePlan.FG1:SetPoint("TOPLEFT", APR.RoutePlan, "TOPLEFT", 0, 0)
	APR.RoutePlan.FG1:SetScale(0.9)

	APR.RoutePlan.FG1.F22 = CreateFrame("frame", "APR.RoutePlanMainFr22ame3", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.F22:SetWidth(165)
	APR.RoutePlan.FG1.F22:SetHeight(275)
	APR.RoutePlan.FG1.F22:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.F22:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 165, 0)
	local t = APR.RoutePlan.FG1.F22:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.RoutePlan.FG1.F22)
	APR.RoutePlan.FG1.F22.texture = t

	APR.RoutePlan.FG1.F22:SetScript("OnMouseDown", function(self, button) -- When mouse pressed
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
				APR.RoutePlan:ClearAllPoints()
				APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
			end
	end)

	APR.RoutePlan.FG1.F22:SetScript("OnMouseUp", function(self, button) -- When mouse released after being pressed
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.F22:SetScript("OnHide", function(self) -- prevent routeplan from being movable or resizable when hidden, since you can't see it anyways
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)

	APR.RoutePlan.FG1.xg2 = CreateFrame("frame", "APR.RoutePlanMainFr22ame3x2", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.xg2:SetWidth(165)
	APR.RoutePlan.FG1.xg2:SetHeight(275)
	APR.RoutePlan.FG1.xg2:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.xg2:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 0, 0)

	local t = APR.RoutePlan.FG1.xg2:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.RoutePlan.FG1.xg2)
	APR.RoutePlan.FG1.xg2.texture = t

	APR.RoutePlan.FG1.xg2:SetScript("OnMouseDown", function(self, button)--When mouse pressed
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
				APR.RoutePlan:ClearAllPoints()
				APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
			end
	end)

	APR.RoutePlan.FG1.xg2:SetScript("OnMouseUp", function(self, button) -- When mouse released after being pressed
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.xg2:SetScript("OnHide", function(self) -- prevent routeplan from being movable or resizable when hidden, since you can't see it anyways
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)

		APR.RoutePlan.FG1.HelpText = CreateFrame("frame", "APR.RoutePlanMainFsramex2xxxshlp", APR.RoutePlan.FG1)
		APR.RoutePlan.FG1.HelpText:SetWidth(250)
		APR.RoutePlan.FG1.HelpText:SetHeight(20)
		APR.RoutePlan.FG1.HelpText:SetMovable(true)
		APR.RoutePlan.FG1.HelpText:EnableMouse(true)
		APR.RoutePlan.FG1.HelpText:SetFrameStrata("HIGH")
		APR.RoutePlan.FG1.HelpText:SetResizable(true)
		APR.RoutePlan.FG1.HelpText:SetScale(0.7)
		APR.RoutePlan.FG1.HelpText:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1.xg2, "BOTTOMLEFT", 20,-15)
	--[[ stuff original author commented out
		APR.RoutePlan.FG1["Fxz"..CLi]:SetBackdrop( {
		bgFile = "Interface\\Buttons\\WHITE8X8", tile = false, tileSize=0,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
		});
	]]--
		local t = APR.RoutePlan.FG1.HelpText:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\Buttons\\WHITE8X8")
		t:SetAllPoints(APR.RoutePlan.FG1.HelpText)
		t:SetColorTexture(0.1,0.1,0.4,1)
		APR.RoutePlan.FG1.HelpText.texture = t
		APR.RoutePlan.FG1.HelpText.FS = APR.RoutePlan.FG1.HelpText:CreateFontString("APR.RoutePlan_Fx3x_FFGs1Shlp","ARTWORK", "ChatFontNormal")
		APR.RoutePlan.FG1.HelpText.FS:SetParent(APR.RoutePlan.FG1.HelpText)
		APR.RoutePlan.FG1.HelpText.FS:SetPoint("TOP",APR.RoutePlan.FG1.HelpText,"TOP",0,1)
		APR.RoutePlan.FG1.HelpText.FS:SetWidth(250)
		APR.RoutePlan.FG1.HelpText.FS:SetHeight(20)
		APR.RoutePlan.FG1.HelpText.FS:SetJustifyH("CENTER")
		APR.RoutePlan.FG1.HelpText.FS:SetFontObject("GameFontNormal")
		APR.RoutePlan.FG1.HelpText.FS:SetText("Right-click or drag to move routes")

	APR.RoutePlan.FG1.F24 = CreateFrame("frame", "APR.RoutePlanMainFr22ame4", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.F24:SetWidth(165)
	APR.RoutePlan.FG1.F24:SetHeight(275)
	APR.RoutePlan.FG1.F24:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.F24:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 495, 0)

	local t = APR.RoutePlan.FG1.F24:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.RoutePlan.FG1.F24)
	APR.RoutePlan.FG1.F24.texture = t

	APR.RoutePlan.FG1.F24:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
				APR.RoutePlan:ClearAllPoints()
				APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
			end
	end)
	APR.RoutePlan.FG1.F24:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.F24:SetScript("OnHide", function(self)
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)

	APR.RoutePlan.FG1.xg3 = CreateFrame("frame", "APR.RoutePlanMainFr22ame3x3", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.xg3:SetWidth(165)
	APR.RoutePlan.FG1.xg3:SetHeight(275)
	APR.RoutePlan.FG1.xg3:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.xg3:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 330, 0)

	local t = APR.RoutePlan.FG1.xg3:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.RoutePlan.FG1.xg3)
	APR.RoutePlan.FG1.xg3.texture = t

	APR.RoutePlan.FG1.xg3:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
				APR.RoutePlan:ClearAllPoints()
				APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
			end
	end)
	APR.RoutePlan.FG1.xg3:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.xg3:SetScript("OnHide", function(self)
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)

	APR.RoutePlan.FG1.F23 = CreateFrame("frame", "APR.RoutePlanMainFr22ame13", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.F23:SetWidth(165)
	APR.RoutePlan.FG1.F23:SetHeight(20)
	APR.RoutePlan.FG1.F23:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.F23:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1, "BOTTOMLEFT", 330, 0)

	local t = APR.RoutePlan.FG1.F23:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.RoutePlan.FG1.F23)
	APR.RoutePlan.FG1.F23.texture = t

	APR.RoutePlan.FG1.F23:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
			end
	end)
	APR.RoutePlan.FG1.F23:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.F23:SetScript("OnHide", function(self)
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)
	APR.RoutePlan.FG1.F23["FS"] = APR.RoutePlan.FG1.F23:CreateFontString("APR.RoutePlan_Fxx3x_FFGs1S","ARTWORK", "ChatFontNormal")
	APR.RoutePlan.FG1.F23["FS"]:SetParent(APR.RoutePlan.FG1.F23)
	APR.RoutePlan.FG1.F23["FS"]:SetPoint("TOP",APR.RoutePlan.FG1.F23,"TOP",0,0)
	APR.RoutePlan.FG1.F23["FS"]:SetWidth(165)
	APR.RoutePlan.FG1.F23["FS"]:SetHeight(20)
	APR.RoutePlan.FG1.F23["FS"]:SetJustifyH("CENTER")
	APR.RoutePlan.FG1.F23["FS"]:SetFontObject("GameFontNormal")
	APR.RoutePlan.FG1.F23["FS"]:SetText("Eastern Kingdoms")
	APR.RoutePlan.FG1.Fx1 = CreateFrame("frame", "APR.RoutePlanMainFr22amex1", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.Fx1:SetWidth(165)
	APR.RoutePlan.FG1.Fx1:SetHeight(20)
	APR.RoutePlan.FG1.Fx1:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.Fx1:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1, "BOTTOMLEFT", 165, 0)

	local t = APR.RoutePlan.FG1.Fx1:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.RoutePlan.FG1.Fx1)
	APR.RoutePlan.FG1.Fx1.texture = t

	APR.RoutePlan.FG1.Fx1:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
			end
	end)
	APR.RoutePlan.FG1.Fx1:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.Fx1:SetScript("OnHide", function(self)
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)
	APR.RoutePlan.FG1.Fx1["FS"] = APR.RoutePlan.FG1.Fx1:CreateFontString("APR.RoutePlan_Fxx3x_FFGs1Sx1","ARTWORK", "ChatFontNormal")
	APR.RoutePlan.FG1.Fx1["FS"]:SetParent(APR.RoutePlan.FG1.Fx1)
	APR.RoutePlan.FG1.Fx1["FS"]:SetPoint("TOP",APR.RoutePlan.FG1.Fx1,"TOP",0,0)
	APR.RoutePlan.FG1.Fx1["FS"]:SetWidth(165)
	APR.RoutePlan.FG1.Fx1["FS"]:SetHeight(20)
	APR.RoutePlan.FG1.Fx1["FS"]:SetJustifyH("CENTER")
	APR.RoutePlan.FG1.Fx1["FS"]:SetFontObject("GameFontNormal")
	APR.RoutePlan.FG1.Fx1["FS"]:SetText("Kalimdor")

	APR.RoutePlan.FG1.Fx2x2 = CreateFrame("frame", "APR.RoutePlanMainFr22amex2x2", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.Fx2x2:SetWidth(165)
	APR.RoutePlan.FG1.Fx2x2:SetHeight(20)
	APR.RoutePlan.FG1.Fx2x2:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.Fx2x2:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1, "BOTTOMLEFT", 495, 0)

	APR.RoutePlan.FG1.Fx2 = CreateFrame("frame", "APR.RoutePlanMainFr22amex2", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.Fx2:SetWidth(165)
	APR.RoutePlan.FG1.Fx2:SetHeight(20)
	APR.RoutePlan.FG1.Fx2:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.Fx2:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1, "BOTTOMLEFT", 495, 0)

	local t = APR.RoutePlan.FG1.Fx2:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.RoutePlan.FG1.Fx2)
	APR.RoutePlan.FG1.Fx2.texture = t

	APR.RoutePlan.FG1.Fx2:SetScript("OnMouseDown", function(self, button) --While right mouse button is clicked, allow the route plan to be moved around
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
			end
	end)
	APR.RoutePlan.FG1.Fx2:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.Fx2:SetScript("OnHide", function(self)
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)
	APR.RoutePlan.FG1.Fx2["FS"] = APR.RoutePlan.FG1.Fx2:CreateFontString("APR.RoutePlan_Fxx3x_FFGs1Sx1","ARTWORK", "ChatFontNormal")
	APR.RoutePlan.FG1.Fx2["FS"]:SetParent(APR.RoutePlan.FG1.Fx2)
	APR.RoutePlan.FG1.Fx2["FS"]:SetPoint("TOP",APR.RoutePlan.FG1.Fx2,"TOP",0,0)
	APR.RoutePlan.FG1.Fx2["FS"]:SetWidth(165)
	APR.RoutePlan.FG1.Fx2["FS"]:SetHeight(20)
	APR.RoutePlan.FG1.Fx2["FS"]:SetJustifyH("CENTER")
	APR.RoutePlan.FG1.Fx2["FS"]:SetFontObject("GameFontNormal")
	APR.RoutePlan.FG1.Fx2["FS"]:SetText("Shadowlands")

----------------------- SpeedFrame Start ---------------

	APR.RoutePlan.FG1.F26 = CreateFrame("frame", "APR.RoutePlanMainFr22ame411", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.F26:SetWidth(165)
	APR.RoutePlan.FG1.F26:SetHeight(275)
	APR.RoutePlan.FG1.F26:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.F26:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 660, 0)

	local t = APR.RoutePlan.FG1.F26:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.RoutePlan.FG1.F26)
	APR.RoutePlan.FG1.F26.texture = t

	APR.RoutePlan.FG1.F26:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
				APR.RoutePlan:ClearAllPoints()
				APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
			end
	end)
	APR.RoutePlan.FG1.F26:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.F26:SetScript("OnHide", function(self)
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)
	APR.RoutePlan.FG1.F25x3 = CreateFrame("frame", "APR.RoutePlanMainFr22ameF25x2", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.F25x3:SetWidth(165)
	APR.RoutePlan.FG1.F25x3:SetHeight(20)
	APR.RoutePlan.FG1.F25x3:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.F25x3:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1, "BOTTOMLEFT", 660, 0)

	APR.RoutePlan.FG1.F25 = CreateFrame("frame", "APR.RoutePlanMainFr22ame3x1", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.F25:SetWidth(165)
	APR.RoutePlan.FG1.F25:SetHeight(20)
	APR.RoutePlan.FG1.F25:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.F25:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 660, 0)
	APR.RoutePlan.FG1.F25:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
				APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
				APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
				APR.RoutePlan:ClearAllPoints()
				APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
			end
	end)
	APR.RoutePlan.FG1.F25:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.F25:SetScript("OnHide", function(self)
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)

	APR.RoutePlan.FG1.Fx3 = CreateFrame("frame", "APR.RoutePlanMainFr22amex3", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.Fx3:SetWidth(165)
	APR.RoutePlan.FG1.Fx3:SetHeight(20)
	APR.RoutePlan.FG1.Fx3:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.Fx3:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1, "BOTTOMLEFT", 660, 0)

	local t = APR.RoutePlan.FG1.Fx3:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.RoutePlan.FG1.Fx3)
	APR.RoutePlan.FG1.Fx3.texture = t

	APR.RoutePlan.FG1.Fx3:SetScript("OnMouseDown", function(self, button) -- On right mouse clicked, start moving the frame
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
			end
	end)
	APR.RoutePlan.FG1.Fx3:SetScript("OnMouseUp", function(self, button) --On let go
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.Fx3:SetScript("OnHide", function(self)
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)
	APR.RoutePlan.FG1.Fx3["FS"] = APR.RoutePlan.FG1.Fx3:CreateFontString("APR.RoutePlan_Fxx3x_FFGs1Sx3","ARTWORK", "ChatFontNormal")
	APR.RoutePlan.FG1.Fx3["FS"]:SetParent(APR.RoutePlan.FG1.Fx3)
	APR.RoutePlan.FG1.Fx3["FS"]:SetPoint("TOP",APR.RoutePlan.FG1.Fx3,"TOP",0,0)
	APR.RoutePlan.FG1.Fx3["FS"]:SetWidth(165)
	APR.RoutePlan.FG1.Fx3["FS"]:SetHeight(20)
	APR.RoutePlan.FG1.Fx3["FS"]:SetJustifyH("CENTER")
	APR.RoutePlan.FG1.Fx3["FS"]:SetFontObject("GameFontNormal")
	APR.RoutePlan.FG1.Fx3["FS"]:SetText("Speed Runs")

	local zenr = APR.NumbRoutePlan("SpeedRun")
	for CLi = 1, zenr do
		APR.RoutePlan.FG1["Fx3z"..CLi] = CreateFrame("frame", "APR.RoutePlanMainFsramex2x3xxs"..CLi, APR.RoutePlan.FG1)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetWidth(225)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetHeight(20)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetMovable(true)
		APR.RoutePlan.FG1["Fx3z"..CLi]:EnableMouse(true)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetFrameStrata("HIGH")
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetResizable(true)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetScale(0.7)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 0, -(20*CLi))
		--[[ Code by original author commented
			APR.RoutePlan.FG1["Fx3z"..CLi]:SetBackdrop( {
				bgFile = "Interface\\Buttons\\WHITE8X8", tile = false, tileSize=0,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
			});
		]]--

local t = APR.RoutePlan.FG1["Fx3z"..CLi]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\Buttons\\WHITE8X8")
t:SetAllPoints(APR.RoutePlan.FG1["Fx3z"..CLi])
t:SetColorTexture(0.1,0.1,0.4,1)
APR.RoutePlan.FG1["Fx3z"..CLi].texture = t

		APR.RoutePlan.FG1["Fx3z"..CLi]:SetScript("OnMouseDown", function(self, button)
				if button == "LeftButton" then
					APR.RoutePlan.FG1["Fx3z"..CLi]:StartMoving();
					APR.RoutePlan.FG1["Fx3z"..CLi].isMoving = true;
				elseif button == "RightButton" then
					local zenew = getn(APR_Custom[APR.Name.."-"..APR.Realm]) + 1
					if (zenew < 19 or zenew == 19) then
						tinsert(APR_Custom[APR.Name.."-"..APR.Realm],APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:GetText())
						APR.RoutePlan.FG1["Fxz2Custom"..zenew]["FS"]:SetText(APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:GetText())
						APR.RoutePlan.FG1["Fxz2Custom"..zenew]:Show()
					end
					APR.RoutePlanCheckPos()
					APR.CheckCustomEmpty()
				end
		end)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and APR.RoutePlan.FG1["Fx3z"..CLi].isMoving then
				APR.RoutePlan.FG1["Fx3z"..CLi]:StopMovingOrSizing();
				APR.RoutePlan.FG1["Fx3z"..CLi].isMoving = false;
				APR.CheckPosMove(5)
				APR.RoutePlanCheckPos()
				APR.CheckCustomEmpty()
			end
		end)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetScript("OnHide", function(self)
			if ( APR.RoutePlan.FG1.isMoving ) then
				APR.RoutePlan.FG1:StopMovingOrSizing();
				APR.RoutePlan.FG1.isMoving = false;
			end
		end)
		--APR.RoutePlan.FG1["Fx3z"..CLi]:SetBackdropColor(0.1,0.1,0.4,1)
		APR.RoutePlan.FG1["Fx3z"..CLi]["FS"] = APR.RoutePlan.FG1["Fx3z"..CLi]:CreateFontString("APR.RoutePlan_Fx3x_FFGs3S"..CLi,"ARTWORK", "ChatFontNormal")
		APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:SetParent(APR.RoutePlan.FG1["Fx3z"..CLi])
		APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:SetPoint("TOP",APR.RoutePlan.FG1["Fx3z"..CLi],"TOP",0,1)
		APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:SetWidth(210)
		APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:SetHeight(20)
		APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:SetJustifyH("LEFT")
		APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:SetFontObject("GameFontNormal")
		APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:SetText("")
	end

----------------------- SpeedFrame End ---------------

	APR.RoutePlan.FG1["CloseButton"] = CreateFrame("Button", "APR_RoutePlan_FG1_CloseButton", APR.RoutePlan.FG1, "UIPanelButtonTemplate")
	APR.RoutePlan.FG1["CloseButton"]:SetWidth(25)
	APR.RoutePlan.FG1["CloseButton"]:SetHeight(25)
	APR.RoutePlan.FG1["CloseButton"]:SetText("X")
	APR.RoutePlan.FG1["CloseButton"]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1, "TOPRIGHT", 840, 25)
	APR.RoutePlan.FG1["CloseButton"]:SetNormalFontObject("GameFontNormalLarge")
	APR.RoutePlan.FG1["CloseButton"]:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			APR.RoutePlan.FG1:Hide()
		end
	end)
APR.RoutePlan.FG1:Hide()

	APR.RoutePlan.FG1.Fx0 = CreateFrame("frame", "APR.RoutePlanMainFr22amex0", APR.RoutePlan.FG1)
	APR.RoutePlan.FG1.Fx0:SetWidth(165)
	APR.RoutePlan.FG1.Fx0:SetHeight(20)
	APR.RoutePlan.FG1.Fx0:SetFrameStrata("LOW")
	APR.RoutePlan.FG1.Fx0:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1, "BOTTOMLEFT", 0, 0)

	local t = APR.RoutePlan.FG1.Fx0:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	t:SetAllPoints(APR.RoutePlan.FG1.Fx0)
	APR.RoutePlan.FG1.Fx0.texture = t

	APR.RoutePlan.FG1.Fx0:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				APR.RoutePlan:StartMoving();
				APR.RoutePlan.isMoving = true;
			else
				APR.RoutePlan:StopMovingOrSizing();
				APR.RoutePlan.isMoving = false;
			end
	end)
	APR.RoutePlan.FG1.Fx0:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" and APR.RoutePlan.isMoving then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
			APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = APR.RoutePlan:GetLeft()
			APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = APR.RoutePlan:GetTop() - GetScreenHeight()
			APR.RoutePlan:ClearAllPoints()
			APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"], APR1[APR.Realm][APR.Name]["Settings"]["topLiz"])
		end
	end)
	APR.RoutePlan.FG1.Fx0:SetScript("OnHide", function(self)
		if ( APR.RoutePlan.isMoving ) then
			APR.RoutePlan:StopMovingOrSizing();
			APR.RoutePlan.isMoving = false;
		end
	end)
	APR.RoutePlan.FG1.Fx0["FS"] = APR.RoutePlan.FG1.Fx0:CreateFontString("APR.RoutePlan_Fxx3x_FFGs1Sx1","ARTWORK", "ChatFontNormal")
	APR.RoutePlan.FG1.Fx0["FS"]:SetParent(APR.RoutePlan.FG1.Fx0)
	APR.RoutePlan.FG1.Fx0["FS"]:SetPoint("TOP",APR.RoutePlan.FG1.Fx0,"TOP",0,0)
	APR.RoutePlan.FG1.Fx0["FS"]:SetWidth(165)
	APR.RoutePlan.FG1.Fx0["FS"]:SetHeight(20)
	APR.RoutePlan.FG1.Fx0["FS"]:SetJustifyH("CENTER")
	APR.RoutePlan.FG1.Fx0["FS"]:SetFontObject("GameFontNormal")
	APR.RoutePlan.FG1.Fx0["FS"]:SetText("Custom Path")

	local zenr = APR.NumbRoutePlan("EasternKingdom")
	for CLi = 1, zenr do
		APR.RoutePlan.FG1["Fxz"..CLi] = CreateFrame("frame", "APR.RoutePlanMainFsramex2xxxs"..CLi, APR.RoutePlan.FG1)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetWidth(225)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetHeight(20)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetMovable(true)
		APR.RoutePlan.FG1["Fxz"..CLi]:EnableMouse(true)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetFrameStrata("HIGH")
		APR.RoutePlan.FG1["Fxz"..CLi]:SetResizable(true)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetScale(0.7)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 0, -(20*CLi))
		--[[ Stuff written by original author originally commented
			APR.RoutePlan.FG1["Fxz"..CLi]:SetBackdrop( {
			bgFile = "Interface\\Buttons\\WHITE8X8", tile = false, tileSize=0,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
			});
		]]--
local t = APR.RoutePlan.FG1["Fxz"..CLi]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\Buttons\\WHITE8X8")
t:SetAllPoints(APR.RoutePlan.FG1["Fxz"..CLi])
t:SetColorTexture(0.1,0.1,0.4,1)
APR.RoutePlan.FG1["Fxz"..CLi].texture = t

		APR.RoutePlan.FG1["Fxz"..CLi]:SetScript("OnMouseDown", function(self, button) --On clicked, move stuff
				if button == "LeftButton" then
					APR.RoutePlan.FG1["Fxz"..CLi]:StartMoving();
					APR.RoutePlan.FG1["Fxz"..CLi].isMoving = true;
				elseif button == "RightButton" then
					local zenew = getn(APR_Custom[APR.Name.."-"..APR.Realm]) + 1
					if (zenew < 19 or zenew == 19) then
						tinsert(APR_Custom[APR.Name.."-"..APR.Realm],APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:GetText())
						APR.RoutePlan.FG1["Fxz2Custom"..zenew]["FS"]:SetText(APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:GetText())
						APR.RoutePlan.FG1["Fxz2Custom"..zenew]:Show()
					end
					APR.RoutePlanCheckPos()
					APR.CheckCustomEmpty()
				end
		end)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and APR.RoutePlan.FG1["Fxz"..CLi].isMoving then
				APR.RoutePlan.FG1["Fxz"..CLi]:StopMovingOrSizing();
				APR.RoutePlan.FG1["Fxz"..CLi].isMoving = false;
				APR.CheckPosMove(1)
				APR.RoutePlanCheckPos()
				APR.CheckCustomEmpty()
			end
		end)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetScript("OnHide", function(self)
			if ( APR.RoutePlan.FG1.isMoving ) then
				APR.RoutePlan.FG1:StopMovingOrSizing();
				APR.RoutePlan.FG1.isMoving = false;
			end
		end)
		--APR.RoutePlan.FG1["Fxz"..CLi]:SetBackdropColor(0.1,0.1,0.4,1)
		APR.RoutePlan.FG1["Fxz"..CLi]["FS"] = APR.RoutePlan.FG1["Fxz"..CLi]:CreateFontString("APR.RoutePlan_Fx3x_FFGs1S"..CLi,"ARTWORK", "ChatFontNormal")
		APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:SetParent(APR.RoutePlan.FG1["Fxz"..CLi])
		APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:SetPoint("TOP",APR.RoutePlan.FG1["Fxz"..CLi],"TOP",0,1)
		APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:SetWidth(210)
		APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:SetHeight(20)
		APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:SetJustifyH("LEFT")
		APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:SetFontObject("GameFontNormal")
		APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:SetText("Group "..CLi)
	end

	local zenr = APR.NumbRoutePlan("Kalimdor")
	for CLi = 1, zenr do
		APR.RoutePlan.FG1["Fxzx2"..CLi] = CreateFrame("frame", "APR.RoutePlanMainFsramex2xxx2s"..CLi, APR.RoutePlan.FG1)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetWidth(225)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetHeight(20)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetMovable(true)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:EnableMouse(true)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetFrameStrata("HIGH")
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetResizable(true)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetScale(0.7)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 0, -(20*CLi))
		--[[ Stuff commented by original author
			APR.RoutePlan.FG1["Fxzx2"..CLi]:SetBackdrop( {
			bgFile = "Interface\\Buttons\\WHITE8X8", tile = false, tileSize=0,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
			});
		]]--
local t = APR.RoutePlan.FG1["Fxzx2"..CLi]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\Buttons\\WHITE8X8")
t:SetAllPoints(APR.RoutePlan.FG1["Fxzx2"..CLi])
t:SetColorTexture(0.1,0.1,0.4,1)
APR.RoutePlan.FG1["Fxzx2"..CLi].texture = t

		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetScript("OnMouseDown", function(self, button) --On clicked
				if button == "LeftButton" then
					APR.RoutePlan.FG1["Fxzx2"..CLi]:StartMoving();
					APR.RoutePlan.FG1["Fxzx2"..CLi].isMoving = true;
				elseif button == "RightButton" then
					local zenew = getn(APR_Custom[APR.Name.."-"..APR.Realm]) + 1
					if (zenew < 19 or zenew == 19) then
						tinsert(APR_Custom[APR.Name.."-"..APR.Realm],APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:GetText())
						APR.RoutePlan.FG1["Fxz2Custom"..zenew]["FS"]:SetText(APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:GetText())
						APR.RoutePlan.FG1["Fxz2Custom"..zenew]:Show()
					end
					APR.RoutePlanCheckPos()
					APR.CheckCustomEmpty()
				end
		end)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetScript("OnMouseUp", function(self, button) -- On click release
			if button == "LeftButton" and APR.RoutePlan.FG1["Fxzx2"..CLi].isMoving then
				APR.RoutePlan.FG1["Fxzx2"..CLi]:StopMovingOrSizing();
				APR.RoutePlan.FG1["Fxzx2"..CLi].isMoving = false;
				APR.CheckPosMove(3)
				APR.RoutePlanCheckPos()
				APR.CheckCustomEmpty()
			end
		end)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetScript("OnHide", function(self) -- Prevent from moving while hidden
			if ( APR.RoutePlan.FG1.isMoving ) then
				APR.RoutePlan.FG1:StopMovingOrSizing();
				APR.RoutePlan.FG1.isMoving = false;
			end
		end)
		--APR.RoutePlan.FG1["Fxzx2"..CLi]:SetBackdropColor(0.1,0.1,0.4,1)
		APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"] = APR.RoutePlan.FG1["Fxzx2"..CLi]:CreateFontString("APR.RoutePlan_Fx3x_FFGs1S"..CLi,"ARTWORK", "ChatFontNormal")
		APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:SetParent(APR.RoutePlan.FG1["Fxzx2"..CLi])
		APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:SetPoint("TOP",APR.RoutePlan.FG1["Fxzx2"..CLi],"TOP",0,1)
		APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:SetWidth(210)
		APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:SetHeight(20)
		APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:SetJustifyH("LEFT")
		APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:SetFontObject("GameFontNormal")
		APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:SetText("Group "..CLi)
	end

	local zenr = APR.NumbRoutePlan("Shadowlands")
	for CLi = 1, zenr do
		APR.RoutePlan.FG1["Fxzx3"..CLi] = CreateFrame("frame", "APR.RoutePlanMainFsramex2xx3x2s"..CLi, APR.RoutePlan.FG1)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetWidth(225)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetHeight(20)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetMovable(true)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:EnableMouse(true)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetFrameStrata("HIGH")
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetResizable(true)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetScale(0.7)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 0, -(20*CLi))
		--[[ Stuff from original author
			APR.RoutePlan.FG1["Fxzx3"..CLi]:SetBackdrop( {
				bgFile = "Interface\\Buttons\\WHITE8X8", tile = false, tileSize=0,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
			});
		]]
--APR.RoutePlan.FG1["Fxzx3"..CLi]:Hide()

local t = APR.RoutePlan.FG1["Fxzx3"..CLi]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\Buttons\\WHITE8X8")
t:SetAllPoints(APR.RoutePlan.FG1["Fxzx3"..CLi])
t:SetColorTexture(0.1,0.1,0.4,1)
APR.RoutePlan.FG1["Fxzx3"..CLi].texture = t

		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetScript("OnMouseDown", function(self, button) -- On clicked
				if button == "LeftButton" then
					APR.RoutePlan.FG1["Fxzx3"..CLi]:StartMoving();
					APR.RoutePlan.FG1["Fxzx3"..CLi].isMoving = true;
				elseif button == "RightButton" then
					local zenew = getn(APR_Custom[APR.Name.."-"..APR.Realm]) + 1
					if (zenew < 19 or zenew == 19) then
						tinsert(APR_Custom[APR.Name.."-"..APR.Realm],APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:GetText())
						APR.RoutePlan.FG1["Fxz2Custom"..zenew]["FS"]:SetText(APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:GetText())
						APR.RoutePlan.FG1["Fxz2Custom"..zenew]:Show()
					end
					APR.RoutePlanCheckPos()
					APR.CheckCustomEmpty()
				end
		end)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetScript("OnMouseUp", function(self, button) -- On click release
			if button == "LeftButton" and APR.RoutePlan.FG1["Fxzx3"..CLi].isMoving then
				APR.RoutePlan.FG1["Fxzx3"..CLi]:StopMovingOrSizing();
				APR.RoutePlan.FG1["Fxzx3"..CLi].isMoving = false;
				APR.CheckPosMove(4)
				APR.RoutePlanCheckPos()
				APR.CheckCustomEmpty()
			end
		end)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetScript("OnHide", function(self) --Prevent moving on hide
			if ( APR.RoutePlan.FG1.isMoving ) then
				APR.RoutePlan.FG1:StopMovingOrSizing();
				APR.RoutePlan.FG1.isMoving = false;
			end
		end)
		--APR.RoutePlan.FG1["Fxzx3"..CLi]:SetBackdropColor(0.1,0.1,0.4,1)
		APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"] = APR.RoutePlan.FG1["Fxzx3"..CLi]:CreateFontString("APR.RoutePlan_Fx3x_FFGs1S"..CLi,"ARTWORK", "ChatFontNormal")
		APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:SetParent(APR.RoutePlan.FG1["Fxzx3"..CLi])
		APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:SetPoint("TOP",APR.RoutePlan.FG1["Fxzx3"..CLi],"TOP",0,1)
		APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:SetWidth(210)
		APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:SetHeight(20)
		APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:SetJustifyH("LEFT")
		APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:SetFontObject("GameFontNormal")
		APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:SetText("Group "..CLi)
	end

	for CLi = 1, 19 do
		APR.RoutePlan.FG1["FxzCustom"..CLi] = CreateFrame("frame", "APR.RoutePlanMainFsramex2xxxsc"..CLi, APR.RoutePlan.FG1)
		APR.RoutePlan.FG1["FxzCustom"..CLi]:SetWidth(25)
		APR.RoutePlan.FG1["FxzCustom"..CLi]:SetHeight(20)
		APR.RoutePlan.FG1["FxzCustom"..CLi]:SetMovable(true)
		APR.RoutePlan.FG1["FxzCustom"..CLi]:EnableMouse(true)
		APR.RoutePlan.FG1["FxzCustom"..CLi]:SetFrameStrata("HIGH")
		APR.RoutePlan.FG1["FxzCustom"..CLi]:SetResizable(true)
		APR.RoutePlan.FG1["FxzCustom"..CLi]:SetScale(0.7)
		APR.RoutePlan.FG1["FxzCustom"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", -15, -((20*CLi)-17))
		--APR.RoutePlan.FG1["FxzCustom"..CLi]:SetBackdrop( {
		--	bgFile = "Interface\\Buttons\\WHITE8X8", tile = false, tileSize=0,
		--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		--	tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
		--});
local t = APR.RoutePlan.FG1["FxzCustom"..CLi]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\Buttons\\WHITE8X8")
t:SetAllPoints(APR.RoutePlan.FG1["FxzCustom"..CLi])
t:SetColorTexture(0.1,0.1,0.4,1)
APR.RoutePlan.FG1["FxzCustom"..CLi].texture = t

		--APR.RoutePlan.FG1["FxzCustom"..CLi]:SetBackdropColor(0,0.9,0,1)
		APR.RoutePlan.FG1["FxzCustom"..CLi]["FS"] = APR.RoutePlan.FG1["FxzCustom"..CLi]:CreateFontString("APR.RoutePlan_Fx3x_FFGs1S"..CLi,"ARTWORK", "ChatFontNormal")
		APR.RoutePlan.FG1["FxzCustom"..CLi]["FS"]:SetParent(APR.RoutePlan.FG1["FxzCustom"..CLi])
		APR.RoutePlan.FG1["FxzCustom"..CLi]["FS"]:SetPoint("TOP",APR.RoutePlan.FG1["FxzCustom"..CLi],"TOP",0,1)
		APR.RoutePlan.FG1["FxzCustom"..CLi]["FS"]:SetWidth(25)
		APR.RoutePlan.FG1["FxzCustom"..CLi]["FS"]:SetHeight(20)
		APR.RoutePlan.FG1["FxzCustom"..CLi]["FS"]:SetJustifyH("CENTER")
		APR.RoutePlan.FG1["FxzCustom"..CLi]["FS"]:SetFontObject("GameFontNormal")
		APR.RoutePlan.FG1["FxzCustom"..CLi]["FS"]:SetText(CLi)

		APR.RoutePlan.FG1["Fxz2Custom"..CLi] = CreateFrame("frame", "APR.RoutePlanMainFsramex2xc2x"..CLi, APR.RoutePlan.FG1)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetWidth(225)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetHeight(20)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetMovable(true)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:EnableMouse(true)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetFrameStrata("HIGH")
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetResizable(true)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetScale(0.7)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1, "TOPLEFT", 0, -(20*CLi))
		--[[ Stuff from original maintainer
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetBackdrop( {
				bgFile = "Interface\\Buttons\\WHITE8X8", tile = false, tileSize=0,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 10, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
			});
		]]
local t = APR.RoutePlan.FG1["Fxz2Custom"..CLi]:CreateTexture(nil,"BACKGROUND")
t:SetTexture("Interface\\Buttons\\WHITE8X8")
t:SetAllPoints(APR.RoutePlan.FG1["Fxz2Custom"..CLi])
t:SetColorTexture(0.1,0.1,0.4,1)
APR.RoutePlan.FG1["Fxz2Custom"..CLi].texture = t

		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetScript("OnMouseDown", function(self, button)
				if button == "LeftButton" then
					APR.RoutePlan.FG1["Fxz2Custom"..CLi]:StartMoving();
					APR.RoutePlan.FG1["Fxz2Custom"..CLi].isMoving = true;
				end
		end)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and APR.RoutePlan.FG1["Fxz2Custom"..CLi].isMoving then
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]:StopMovingOrSizing();
				APR.RoutePlan.FG1["Fxz2Custom"..CLi].isMoving = false;
				APR.CheckPosMove(2)
				APR.RoutePlanCheckPos()
				APR.CheckCustomEmpty()
			else
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
				APR.FP.QuedFP = nil
				APR.CheckPosMove(2)
				APR.RoutePlanCheckPos()
				APR.CheckCustomEmpty()
			end
		end)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetScript("OnHide", function(self)
			if ( APR.RoutePlan.FG1.isMoving ) then
				APR.RoutePlan.FG1:StopMovingOrSizing();
				APR.RoutePlan.FG1.isMoving = false;
			end
		end)
		--APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetBackdropColor(0.1,0.1,0.4,1)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"] = APR.RoutePlan.FG1["Fxz2Custom"..CLi]:CreateFontString("APR.RoutePlan_Fx3x_FFGs21Sx"..CLi,"ARTWORK", "ChatFontNormal")
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetParent(APR.RoutePlan.FG1["Fxz2Custom"..CLi])
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetPoint("TOP",APR.RoutePlan.FG1["Fxz2Custom"..CLi],"TOP",0,1)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetWidth(210)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetHeight(20)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetJustifyH("LEFT")
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetFontObject("GameFontNormal")
		if (APR_Custom[APR.Name.."-"..APR.Realm] and APR_Custom[APR.Name.."-"..APR.Realm][CLi]) then
			if (APR_ZoneComplete[APR.Name.."-"..APR.Realm][APR_Custom[APR.Name.."-"..APR.Realm][CLi]]) then
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
			else
				if (APR_Custom[APR.Name.."-"..APR.Realm] and APR_Custom[APR.Name.."-"..APR.Realm][CLi]) then
					local zew = APR.QuestStepListListingZone[APR_Custom[APR.Name.."-"..APR.Realm][CLi]]
					if (APR["EasternKingdomDB"] and APR["EasternKingdomDB"][zew] and IsAddOnLoaded("APR-EasternKingdoms") == false) then
						local loaded, reason = LoadAddOn("APR-Vanilla")
						if (not loaded) then
							if (reason == "DISABLED") then
								print("APR: APR - Eastern Kingdoms is Disabled in your Addon-List!")
							end
						end
					end
					if (APR["BattleForAzeroth"] and APR["BattleForAzeroth"][zew] and IsAddOnLoaded("APR-BattleForAzeroth") == false) then
						local loaded, reason = LoadAddOn("APR-BattleForAzeroth")
						if (not loaded) then
							if (reason == "DISABLED") then
								print("APR: APR - BattleForAzeroth is Disabled in your Addon-List!")
							end
						end
					end
					if (APR["Kalimdor"] and APR["Kalimdor"][zew] and IsAddOnLoaded("APR-Kalimdor") == false) then
						local loaded, reason = LoadAddOn("APR-Vanilla")
						if (not loaded) then
							if (reason == "DISABLED") then
								print("APR: APR - Vanilla is Disabled in your Addon-List!")
							end
						end
					end
					if (APR["Legion"] and APR["Legion"][zew] and IsAddOnLoaded("APR-Legion") == false) then
						local loaded, reason = LoadAddOn("APR-Legion")
						if (not loaded) then
							if (reason == "DISABLED") then
								print("APR: APR - Legion is Disabled in your Addon-List!")
							end
						end
					end
					if (APR["ShadowlandsDB"] and APR["ShadowlandsDB"][zew] and IsAddOnLoaded("APR-Shadowlands") == false) then
						local loaded, reason = LoadAddOn("APR-Shadowlands")
						if (not loaded) then
							if (reason == "DISABLED") then
								print("APR: APR - Shadowlands is Disabled in your Addon-List!")
							end
						end
					end
				end
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText(APR_Custom[APR.Name.."-"..APR.Realm][CLi])
				APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Show()
			end
		else
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
			APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
		end
	end
	local zenr2 = 0
	local dzer = {}
	local dzer2 = {}
	if (APR.QuestStepListListingStartAreas["Kalimdor"]) then
		for APR_index2,APR_value2 in APR.pairsByKeys(APR.QuestStepListListingStartAreas["Kalimdor"]) do
			dzer2[APR_value2] = APR_index2
		end
		for APR_index2,APR_value2 in APR.pairsByKeys(dzer2) do
			zenr2 = zenr2 + 1
			APR.RoutePlan.FG1["Fxzx2"..zenr2]["FS"]:SetText(APR_index2)
		end
	end
	if (APR.QuestStepListListing and APR.QuestStepListListing["Kalimdor"]) then
		for APR_index2,APR_value2 in APR.pairsByKeys(APR.QuestStepListListing["Kalimdor"]) do
			dzer[APR_value2] = APR_index2
		end
		for APR_index2,APR_value2 in APR.pairsByKeys(dzer) do
			zenr2 = zenr2 + 1
			APR.RoutePlan.FG1["Fxzx2"..zenr2]["FS"]:SetText(APR_index2)
		end
	end
	zenr2 = 0
	dzer = nil
	dzer = {}
	dzer2 = nil
	dzer2 = {}

	if (APR.QuestStepListListingStartAreas["EasternKingdom"]) then
		for APR_index2,APR_value2 in APR.pairsByKeys(APR.QuestStepListListingStartAreas["EasternKingdom"]) do
			dzer2[APR_value2] = APR_index2
		end
		for APR_index2,APR_value2 in APR.pairsByKeys(dzer2) do
			zenr2 = zenr2 + 1
			APR.RoutePlan.FG1["Fxz"..zenr2]["FS"]:SetText(APR_index2)
		end
	end
	if (APR.QuestStepListListing and APR.QuestStepListListing["EasternKingdom"]) then
		for APR_index2,APR_value2 in APR.pairsByKeys(APR.QuestStepListListing["EasternKingdom"]) do
			dzer[APR_value2] = APR_index2
		end
		for APR_index2,APR_value2 in APR.pairsByKeys(dzer) do
			zenr2 = zenr2 + 1
			APR.RoutePlan.FG1["Fxz"..zenr2]["FS"]:SetText(APR_index2)
		end
	end
	zenr2 = 0
	dzer = nil
	dzer = {}
	dzer2 = nil
	dzer2 = {}
	if (APR.QuestStepListListing and APR.QuestStepListListing["Shadowlands"]) then
		for APR_index2,APR_value2 in APR.pairsByKeys(APR.QuestStepListListing["Shadowlands"]) do
			dzer[APR_value2] = APR_index2
		end
		for APR_index2,APR_value2 in APR.pairsByKeys(dzer) do
			zenr2 = zenr2 + 1
			APR.RoutePlan.FG1["Fxzx3"..zenr2]["FS"]:SetText(APR_index2)
			--APR.RoutePlan.FG1["Fxzx3"..zenr2]["FS"]:SetText("")
		end
	end
	zenr2 = 0
	dzer = nil
	dzer = {}
	dzer2 = nil
	dzer2 = {}
	if (APR.QuestStepListListing and APR.QuestStepListListing["SpeedRun"]) then
		for APR_index2,APR_value2 in APR.pairsByKeys(APR.QuestStepListListing["SpeedRun"]) do
			dzer[APR_value2] = APR_index2
		end
		for APR_index2,APR_value2 in APR.pairsByKeys(dzer) do
			zenr2 = zenr2 + 1
			--APR.RoutePlan.FG1["Fx3z"..zenr2]["FS"]:SetText(APR_index2)
			APR.RoutePlan.FG1["Fx3z"..zenr2]["FS"]:SetText("")
		end
	end

	APR.RoutePlanCheckPos()
	APR.CheckPosMove()
end

function APR.CheckPosMove(zeActivz)
	if (APR1["Debug"]) then
		print("Function: APR.CheckPosMove()")
	end
	local zenr = APR.NumbRoutePlan("EasternKingdom")
	local zenr2 = APR.NumbRoutePlan("Kalimdor")
	local zenr3 = APR.NumbRoutePlan("Shadowlands")
	local zenr4 = APR.NumbRoutePlan("SpeedRun")
	local ZeBreak = 0
	local zfrom
	local zto
	for CLi = 1, zenr do
		local ZeMTop = APR.RoutePlan.FG1["Fxz"..CLi]:GetTop()
		local ZeMBottom = APR.RoutePlan.FG1["Fxz"..CLi]:GetBottom()
		local ZeMLeft = APR.RoutePlan.FG1["Fxz"..CLi]:GetLeft()
		local ZeMRight = APR.RoutePlan.FG1["Fxz"..CLi]:GetRight()
		local ZeMHeight = ((ZeMTop - ZeMBottom) / 2)+ZeMTop
		local ZeMWidth = ((ZeMRight - ZeMLeft) / 2)+ZeMLeft
		for CLi2 = 1, 19 do
			local zsda = APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop()+(APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop()-APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetBottom())
			local zsda2 = APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft()+(APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetRight()-APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft())

			if (ZeMHeight > APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop() and ZeMHeight < zsda) then
				if (ZeMWidth > APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft() and ZeMWidth < zsda2) then
					zfrom = CLi
					zto = CLi2
					ZeBreak = 1
				end
			end
			if (ZeBreak == 1) then
				break
			end
		end
		if (ZeBreak == 1) then
			break
		end
	end
	for CLi = 1, zenr2 do
		local ZeMTop = APR.RoutePlan.FG1["Fxzx2"..CLi]:GetTop()
		local ZeMBottom = APR.RoutePlan.FG1["Fxzx2"..CLi]:GetBottom()
		local ZeMLeft = APR.RoutePlan.FG1["Fxzx2"..CLi]:GetLeft()
		local ZeMRight = APR.RoutePlan.FG1["Fxzx2"..CLi]:GetRight()
		local ZeMHeight = ((ZeMTop - ZeMBottom) / 2)+ZeMTop
		local ZeMWidth = ((ZeMRight - ZeMLeft) / 2)+ZeMLeft
		for CLi2 = 1, 19 do
			local zsda = APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop()+(APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop()-APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetBottom())
			local zsda2 = APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft()+(APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetRight()-APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft())

			if (ZeMHeight > APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop() and ZeMHeight < zsda) then
				if (ZeMWidth > APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft() and ZeMWidth < zsda2) then
					zfrom = CLi
					zto = CLi2
					ZeBreak = 1
				end
			end
			if (ZeBreak == 1) then
				break
			end
		end
		if (ZeBreak == 1) then
			break
		end
	end
	for CLi = 1, zenr3 do
		local ZeMTop = APR.RoutePlan.FG1["Fxzx3"..CLi]:GetTop()
		local ZeMBottom = APR.RoutePlan.FG1["Fxzx3"..CLi]:GetBottom()
		local ZeMLeft = APR.RoutePlan.FG1["Fxzx3"..CLi]:GetLeft()
		local ZeMRight = APR.RoutePlan.FG1["Fxzx3"..CLi]:GetRight()
		local ZeMHeight = ((ZeMTop - ZeMBottom) / 2)+ZeMTop
		local ZeMWidth = ((ZeMRight - ZeMLeft) / 2)+ZeMLeft
		for CLi2 = 1, 19 do
			local zsda = APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop()+(APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop()-APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetBottom())
			local zsda2 = APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft()+(APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetRight()-APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft())

			if (ZeMHeight > APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop() and ZeMHeight < zsda) then
				if (ZeMWidth > APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft() and ZeMWidth < zsda2) then
					zfrom = CLi
					zto = CLi2
					ZeBreak = 1
				end
			end
			if (ZeBreak == 1) then
				break
			end
		end
		if (ZeBreak == 1) then
			break
		end
	end
	for CLi = 1, zenr4 do
		local ZeMTop = APR.RoutePlan.FG1["Fx3z"..CLi]:GetTop()
		local ZeMBottom = APR.RoutePlan.FG1["Fx3z"..CLi]:GetBottom()
		local ZeMLeft = APR.RoutePlan.FG1["Fx3z"..CLi]:GetLeft()
		local ZeMRight = APR.RoutePlan.FG1["Fx3z"..CLi]:GetRight()
		local ZeMHeight = ((ZeMTop - ZeMBottom) / 2)+ZeMTop
		local ZeMWidth = ((ZeMRight - ZeMLeft) / 2)+ZeMLeft
		for CLi2 = 1, 19 do
			local zsda = APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop()+(APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop()-APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetBottom())
			local zsda2 = APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft()+(APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetRight()-APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft())

			if (ZeMHeight > APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetTop() and ZeMHeight < zsda) then
				if (ZeMWidth > APR.RoutePlan.FG1["Fxz2Custom"..CLi2]:GetLeft() and ZeMWidth < zsda2) then
					zfrom = CLi
					zto = CLi2
					ZeBreak = 1
				end
			end
			if (ZeBreak == 1) then
				break
			end
		end
		if (ZeBreak == 1) then
			break
		end
	end
	if (zeActivz == 1 and zfrom and zto) then
		if (APR.RoutePlan.FG1["Fxz2Custom"..zto]["FS"]:GetText() ~= nil) then
			local zerpd = 20
			for CLi2z = 1, 19 do
				zerpd = zerpd - 1
				if (zerpd ~= 1 and zerpd > zto) then
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]["FS"]:SetText(APR.RoutePlan.FG1["Fxz2Custom"..zerpd-1]["FS"]:GetText())
				end
				if (APR.RoutePlan.FG1["Fxz2Custom"..zerpd]["FS"]:GetText()) then
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]:Show()
				else
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]:Hide()
				end
			end
		end
		APR.RoutePlan.FG1["Fxz2Custom"..zto]["FS"]:SetText(APR.RoutePlan.FG1["Fxz"..zfrom]["FS"]:GetText())
		APR.RoutePlan.FG1["Fxz2Custom"..zto]:Show()
	elseif (zeActivz == 2 and zfrom and zto) then
		APR.RoutePlan.FG1["Fxz2Custom"..zto]["FS"]:SetText("")
		APR.RoutePlan.FG1["Fxz2Custom"..zto]:Hide()
	elseif (zeActivz == 3 and zfrom and zto) then
		if (APR.RoutePlan.FG1["Fxz2Custom"..zto]["FS"]:GetText() ~= nil) then
			local zerpd = 20
			for CLi2z = 1, 19 do
				zerpd = zerpd - 1
				if (zerpd ~= 1 and zerpd > zto) then
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]["FS"]:SetText(APR.RoutePlan.FG1["Fxz2Custom"..zerpd-1]["FS"]:GetText())
				end
				if (APR.RoutePlan.FG1["Fxz2Custom"..zerpd]["FS"]:GetText()) then
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]:Show()
				else
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]:Hide()
				end
			end
		end
		APR.RoutePlan.FG1["Fxz2Custom"..zto]["FS"]:SetText(APR.RoutePlan.FG1["Fxzx2"..zfrom]["FS"]:GetText())
		APR.RoutePlan.FG1["Fxz2Custom"..zto]:Show()
	elseif (zeActivz == 4 and zfrom and zto) then
		if (APR.RoutePlan.FG1["Fxz2Custom"..zto]["FS"]:GetText() ~= nil) then
			local zerpd = 20
			for CLi2z = 1, 19 do
				zerpd = zerpd - 1
				if (zerpd ~= 1 and zerpd > zto) then
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]["FS"]:SetText(APR.RoutePlan.FG1["Fxz2Custom"..zerpd-1]["FS"]:GetText())
				end
				if (APR.RoutePlan.FG1["Fxz2Custom"..zerpd]["FS"]:GetText()) then
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]:Show()
				else
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]:Hide()
				end
			end
		end
		APR.RoutePlan.FG1["Fxz2Custom"..zto]["FS"]:SetText(APR.RoutePlan.FG1["Fxzx3"..zfrom]["FS"]:GetText())
		APR.RoutePlan.FG1["Fxz2Custom"..zto]:Show()
	end
	if (zeActivz == 5 and zfrom and zto) then
		if (APR.RoutePlan.FG1["Fxz2Custom"..zto]["FS"]:GetText() ~= nil) then
			local zerpd = 20
			for CLi2z = 1, 19 do
				zerpd = zerpd - 1
				if (zerpd ~= 1 and zerpd > zto) then
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]["FS"]:SetText(APR.RoutePlan.FG1["Fxz2Custom"..zerpd-1]["FS"]:GetText())
				end
				if (APR.RoutePlan.FG1["Fxz2Custom"..zerpd]["FS"]:GetText()) then
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]:Show()
				else
					APR.RoutePlan.FG1["Fxz2Custom"..zerpd]:Hide()
				end
			end
		end
		APR.RoutePlan.FG1["Fxz2Custom"..zto]["FS"]:SetText(APR.RoutePlan.FG1["Fx3z"..zfrom]["FS"]:GetText())
		APR.RoutePlan.FG1["Fxz2Custom"..zto]:Show()
	end
	for CLi = 1, zenr do
		local zeTex = APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:GetText()
		local ZeMatch = 0
		for CLi2 = 1, 19 do
			if (APR.RoutePlan.FG1["Fxz2Custom"..CLi2]["FS"]:GetText() == zeTex) then
				APR.RoutePlan.FG1["Fxz"..CLi]:Hide()
				ZeMatch = 1
			end
		end
		if (ZeMatch == 0) then
			if (APR_ZoneComplete[APR.Name.."-"..APR.Realm][APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:GetText()]) then
				APR.RoutePlan.FG1["Fxz"..CLi]:Hide()
				APR.FP.GoToZone = nil
				APR.ActiveMap = nil
			else
				APR.RoutePlan.FG1["Fxz"..CLi]:Show()
			end
		end
	end
	for CLi = 1, zenr2 do
		local zeTex = APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:GetText()
		local ZeMatch = 0
		for CLi2 = 1, 19 do
			if (APR.RoutePlan.FG1 and APR.RoutePlan.FG1["Fxz2Custom"..CLi2] and APR.RoutePlan.FG1["Fxz2Custom"..CLi2]["FS"] and APR.RoutePlan.FG1["Fxz2Custom"..CLi2]["FS"]:GetText() == zeTex) then
				APR.RoutePlan.FG1["Fxzx2"..CLi]:Hide()
				ZeMatch = 1
			end
		end
		if (ZeMatch == 0) then
			if (APR_ZoneComplete[APR.Name.."-"..APR.Realm][APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:GetText()]) then
				APR.RoutePlan.FG1["Fxzx2"..CLi]:Hide()
				APR.FP.GoToZone = nil
				APR.ActiveMap = nil
			else
				APR.RoutePlan.FG1["Fxzx2"..CLi]:Show()
			end
		end
	end
	for CLi = 1, zenr3 do
		local zeTex = APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:GetText()
		local ZeMatch = 0
		for CLi2 = 1, 19 do
			if (APR.RoutePlan.FG1["Fxz2Custom"..CLi2]["FS"]:GetText() == zeTex) then
				APR.RoutePlan.FG1["Fxzx3"..CLi]:Hide()
				ZeMatch = 1
			end
		end
		if (ZeMatch == 0) then
			if (APR_ZoneComplete[APR.Name.."-"..APR.Realm][APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:GetText()]) then
				APR.RoutePlan.FG1["Fxzx3"..CLi]:Hide()
				APR.FP.GoToZone = nil
				APR.ActiveMap = nil
			else
				APR.RoutePlan.FG1["Fxzx3"..CLi]:Show()
			end
		end
		if (APR_Custom[APR.Name.."-"..APR.Realm] and APR_Custom[APR.Name.."-"..APR.Realm][CLi]) then
			local zew = APR.QuestStepListListingZone[APR_Custom[APR.Name.."-"..APR.Realm][CLi]]
			if (APR["EasternKingdomDB"] and APR["EasternKingdomDB"][zew] and IsAddOnLoaded("APR-EasternKingdoms") == false) then
				local loaded, reason = LoadAddOn("APR-Vanilla")
						if (not loaded) then
							if (reason == "DISABLED") then
								print("APR: APR - Eastern Kingdoms is Disabled in your Addon-List!")
							end
						end
					end
					if (APR["Kalimdor"] and APR["Kalimdor"][zew] and IsAddOnLoaded("APR-Kalimdor") == false) then
						local loaded, reason = LoadAddOn("APR-Vanilla")
						if (not loaded) then
							if (reason == "DISABLED") then
								print("APR: APR - Vanilla is Disabled in your Addon-List!")
							end
						end
					end
					if (APR["BattleForAzeroth"] and APR["BattleForAzeroth"][zew] and IsAddOnLoaded("APR-BattleForAzeroth") == false) then
						local loaded, reason = LoadAddOn("APR-BattleForAzeroth")
						if (not loaded) then
							if (reason == "DISABLED") then
								print("APR: APR - BattleForAzeroth is Disabled in your Addon-List!")
							end
						end
					end
					if (APR["Legion"] and APR["Legion"][zew] and IsAddOnLoaded("APR-Legion") == false) then
						local loaded, reason = LoadAddOn("APR-Legion")
						if (not loaded) then
							if (reason == "DISABLED") then
								print("APR: APR - Legion is Disabled in your Addon-List!")
							end
						end
					end
			if (APR["ShadowlandsDB"] and APR["ShadowlandsDB"][zew] and IsAddOnLoaded("APR-Shadowlands") == false) then
				local loaded, reason = LoadAddOn("APR-Shadowlands")
				if (not loaded) then
					if (reason == "DISABLED") then
						print("APR: APR - Shadowlands is Disabled in your Addon-List!")
					end
				end
			end
		end
	end
	for CLi = 1, zenr4 do
		local zeTex = APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:GetText()
		local ZeMatch = 0
		for CLi2 = 1, 19 do
			if (APR.RoutePlan.FG1["Fxz2Custom"..CLi2]["FS"]:GetText() == zeTex) then
				APR.RoutePlan.FG1["Fx3z"..CLi]:Hide()
				ZeMatch = 1
			end
		end
		if (ZeMatch == 0) then
			if (APR_ZoneComplete[APR.Name.."-"..APR.Realm][APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:GetText()]) then
				APR.RoutePlan.FG1["Fx3z"..CLi]:Hide()
				APR.FP.GoToZone = nil
				APR.ActiveMap = nil
			else
				APR.RoutePlan.FG1["Fx3z"..CLi]:Show()
			end
		end
		if (APR_Custom[APR.Name.."-"..APR.Realm] and APR_Custom[APR.Name.."-"..APR.Realm][CLi]) then
			local zew = APR.QuestStepListListingZone[APR_Custom[APR.Name.."-"..APR.Realm][CLi]]
			if (APR["ShadowlandsDB"] and APR["ShadowlandsDB"][zew] and IsAddOnLoaded("APR-Shadowlands") == false) then
				local loaded, reason = LoadAddOn("APR-Shadowlands")
				if (not loaded) then
					if (reason == "DISABLED") then
						print("APR: APR - Shadowlands is Disabled in your Addon-List!")
					end
				end
			end
		end
	end
end
function APR.CheckCustomEmpty()
	if (APR1["Debug"]) then
		print("Function: APR.CheckCustomEmpty()")
	end
	local zeemp = 0
	for CLi = 1, 19 do
		if (APR.RoutePlan.FG1["Fxz2Custom"..CLi]:IsVisible()) then
			zeemp = 1
		end
	end
	if (zeemp == 0) then
		APR.FP.GoToZone = nil
		APR.ActiveMap = nil
	end
end
function APR.RoutePlanCheckPos() --Check current position for route plan
	if (APR1["Debug"]) then
		print("Function: APR.RoutePlanCheckPos()")
	end
	local zenr = APR.NumbRoutePlan("EasternKingdom")
	local ZeHide = {}
	for CLi = 1, 19 do
		if (APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:GetText() and APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:GetText() ~= "") then
			ZeHide[APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:GetText()] = 1
		end
	end
	for CLi = 1, zenr do
		APR.RoutePlan.FG1["Fxz"..CLi]:ClearAllPoints()
		APR.RoutePlan.FG1["Fxz"..CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1.F23, "TOPRIGHT", -10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.FG1.F23, "BOTTOMRIGHT", 10, -(20*CLi)+10-10)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1.F23, "BOTTOMLEFT", 10, -(20*CLi)+10-10)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1.F23, "BOTTOMRIGHT", -10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1.F23, "TOPLEFT", 10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetWidth(225)
		APR.RoutePlan.FG1["Fxz"..CLi]:SetHeight(20)
		if (ZeHide and ZeHide[APR.RoutePlan.FG1["Fxz"..CLi]["FS"]:GetText()]) then
			APR.RoutePlan.FG1["Fxz"..CLi]:Hide()
		end
	end
	local zenr = APR.NumbRoutePlan("Kalimdor")
	for CLi = 1, zenr do
		APR.RoutePlan.FG1["Fxzx2"..CLi]:ClearAllPoints()
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1.Fx1, "TOPRIGHT", -10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.FG1.Fx1, "BOTTOMRIGHT", 10, -(20*CLi)+10-10)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1.Fx1, "BOTTOMLEFT", 10, -(20*CLi)+10-10)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1.Fx1, "BOTTOMRIGHT", -10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1.Fx1, "TOPLEFT", 10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetWidth(225)
		APR.RoutePlan.FG1["Fxzx2"..CLi]:SetHeight(20)
		if (ZeHide and ZeHide[APR.RoutePlan.FG1["Fxzx2"..CLi]["FS"]:GetText()]) then
			APR.RoutePlan.FG1["Fxzx2"..CLi]:Hide()
		end
	end
	local zenr = APR.NumbRoutePlan("Shadowlands")
	for CLi = 1, zenr do
		APR.RoutePlan.FG1["Fxzx3"..CLi]:ClearAllPoints()
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1.Fx2x2, "TOPRIGHT", -10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.FG1.Fx2x2, "BOTTOMRIGHT", 10, -(20*CLi)+10-10)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1.Fx2x2, "BOTTOMLEFT", 10, -(20*CLi)+10-10)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1.Fx2x2, "BOTTOMRIGHT", -10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1.Fx2x2, "TOPLEFT", 10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetWidth(225)
		APR.RoutePlan.FG1["Fxzx3"..CLi]:SetHeight(20)
		if (ZeHide and ZeHide[APR.RoutePlan.FG1["Fxzx3"..CLi]["FS"]:GetText()]) then
			APR.RoutePlan.FG1["Fxzx3"..CLi]:Hide()
		end
	end
	local zenr = APR.NumbRoutePlan("SpeedRun")
	for CLi = 1, zenr do
		APR.RoutePlan.FG1["Fx3z"..CLi]:ClearAllPoints()
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1.F25x3, "TOPRIGHT", -10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.FG1.F25x3, "BOTTOMRIGHT", 10, -(20*CLi)+10-10)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1.F25x3, "BOTTOMLEFT", 10, -(20*CLi)+10-10)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1.F25x3, "BOTTOMRIGHT", -10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1.F25x3, "TOPLEFT", 10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetWidth(225)
		APR.RoutePlan.FG1["Fx3z"..CLi]:SetHeight(20)
--		if (ZeHide and ZeHide[APR.RoutePlan.FG1["Fx3z"..CLi]["FS"]:GetText()]) then
			APR.RoutePlan.FG1["Fx3z"..CLi]:Hide()
--		end
	end
	APR_Custom[APR.Name.."-"..APR.Realm] = nil
	APR_Custom[APR.Name.."-"..APR.Realm] = {}
	for CLi = 1, 19 do
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:ClearAllPoints()
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1.Fx0, "TOPRIGHT", -10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetPoint("BOTTOMRIGHT", APR.RoutePlan.FG1.Fx0, "BOTTOMRIGHT", 10, -(20*CLi)+10-10)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetPoint("BOTTOMLEFT", APR.RoutePlan.FG1.Fx0, "BOTTOMLEFT", 10, -(20*CLi)+10-10)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetPoint("TOPRIGHT", APR.RoutePlan.FG1.Fx0, "BOTTOMRIGHT", -10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetPoint("TOPLEFT", APR.RoutePlan.FG1.Fx0, "TOPLEFT", 10, -(20*CLi)-10)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetWidth(225)
		APR.RoutePlan.FG1["Fxz2Custom"..CLi]:SetHeight(20)
		if (APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:GetText() ~= "") then
			APR_Custom[APR.Name.."-"..APR.Realm][CLi] = APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:GetText()
		end
	end
	APR.BookingList["UpdateMapId"] = 1
end
function APR.NumbRoutePlan(Continz)
	local zenr = 0

	if (Continz == "EasternKingdom") then
		if (APR.QuestStepListListingStartAreas["EasternKingdom"]) then
			for APR_index2,APR_value2 in pairs(APR.QuestStepListListingStartAreas["EasternKingdom"]) do
				zenr = zenr + 1
			end
		end
		if (APR.QuestStepListListing["EasternKingdom"]) then
			for APR_index2,APR_value2 in pairs(APR.QuestStepListListing["EasternKingdom"]) do
				zenr = zenr + 1
			end
		end
	elseif (Continz == "Kalimdor") then
		if (APR.QuestStepListListingStartAreas["Kalimdor"]) then
			for APR_index2,APR_value2 in pairs(APR.QuestStepListListingStartAreas["Kalimdor"]) do
				zenr = zenr + 1
			end
		end
		if (APR.QuestStepListListing["Kalimdor"]) then
			for APR_index2,APR_value2 in pairs(APR.QuestStepListListing["Kalimdor"]) do
				zenr = zenr + 1
			end
		end
	elseif (Continz == "BrokenIsles") then
		if (APR.QuestStepListListingStartAreas["BrokenIsles"]) then
			for APR_index2,APR_value2 in pairs(APR.QuestStepListListingStartAreas["BrokenIsles"]) do
				zenr = zenr + 1
			end
		end
	elseif (Continz == "SpeedRun") then
		if (APR.QuestStepListListing["SpeedRun"]) then
			for APR_index2,APR_value2 in pairs(APR.QuestStepListListing["SpeedRun"]) do
				zenr = zenr + 1
			end
		end
	elseif (Continz == "Shadowlands") then
		if (APR.QuestStepListListing["Shadowlands"]) then
			for APR_index2,APR_value2 in pairs(APR.QuestStepListListing["Shadowlands"]) do
				zenr = zenr + 1
			end
		end
	end
	return zenr
end

function APR.TimeFPs(CurrentFP, DestFP)
	if (not APR_TaxiTimers[CurrentFP.."-"..DestFP]) then
		APR.TaxiTimerCur = CurrentFP
		APR.TaxiTimerDes = DestFP
		APR_TaxicTimer:Play()
	else
		APR.AFK_Timer(APR_TaxiTimers[CurrentFP.."-"..DestFP])
	end
end

APR.CoreEventFrame = CreateFrame("Frame")
APR.CoreEventFrame:RegisterEvent ("ADDON_LOADED")
APR.CoreEventFrame:RegisterEvent ("CINEMATIC_START")

APR.CoreEventFrame:SetScript("OnEvent", function(self, event, ...)
	if (event=="ADDON_LOADED") then
		local arg1, arg2, arg3, arg4, arg5 = ...;
		if (arg1 ~= "APR-Core") then
			return
		end
		if (not APR1) then
			APR1 = {}
		end
		if (not APR1[APR.Realm]) then
			APR1[APR.Realm] = {}
		end
		if (not APR1[APR.Realm][APR.Name]) then
			APR1[APR.Realm][APR.Name] = {}
		end
		if (not APR1[APR.Realm][APR.Name]["BonusSkips"]) then
			APR1[APR.Realm][APR.Name]["BonusSkips"] = {}
		end
		APR.ZoneQuestOrderList() --Where steps go

		APR_TaxicTimer = APR.CoreEventFrame:CreateAnimationGroup()
		APR_TaxicTimer.anim = APR_TaxicTimer:CreateAnimation()
		APR_TaxicTimer.anim:SetDuration(1)
		APR_TaxicTimer:SetLooping("REPEAT")
		APR_TaxicTimer:SetScript("OnLoop", function(self, event, ...)
			if (APR.TaxiTimerCur and APR.TaxiTimerDes and UnitOnTaxi("player")) then
				if (not APR_TaxiTimers[APR.TaxiTimerCur.."-"..APR.TaxiTimerDes]) then
					APR_TaxiTimers[APR.TaxiTimerCur.."-"..APR.TaxiTimerDes] = 3
				end
				APR_TaxiTimers[APR.TaxiTimerCur.."-"..APR.TaxiTimerDes] = APR_TaxiTimers[APR.TaxiTimerCur.."-"..APR.TaxiTimerDes] + 1
			else
				APR.TaxiTimerCur = nil
				APR.TaxiTimerDes = nil
				APR_TaxicTimer:Stop()
			end
		end)

		APR_LoadInTimer = APR.CoreEventFrame:CreateAnimationGroup()
		APR_LoadInTimer.anim = APR_LoadInTimer:CreateAnimation()
		APR_LoadInTimer.anim:SetDuration(2)
		APR_LoadInTimer:SetLooping("REPEAT")
		APR_LoadInTimer:SetScript("OnLoop", function(self, event, ...)
			if (CoreLoadin == 1 and APR.QuestListLoadin == 1) then
				if (not APR_Transport) then
					APR_Transport = {}
				end
				if (not APR_Custom) then
					APR_Custom = {}
				end
				if (not APR_TaxiTimers) then
					APR_TaxiTimers = {}
				end
				if (not APR_Custom[APR.Name.."-"..APR.Realm]) then
					APR_Custom[APR.Name.."-"..APR.Realm] = {}
				end
				if (not APR_ZoneComplete) then
					APR_ZoneComplete = {}
				end
				if (not APR_ZoneComplete[APR.Name.."-"..APR.Realm]) then
					APR_ZoneComplete[APR.Name.."-"..APR.Realm] = {}
				end
				if (not APR_Transport["FPs"]) then
					APR_Transport["FPs"] = {}
				end
				if (not APR_Transport["FPs"][APR.Faction]) then
					APR_Transport["FPs"][APR.Faction] = {}
				end
				if (APR.getContinent() and not APR_Transport["FPs"][APR.Faction][APR.getContinent()]) then
					APR_Transport["FPs"][APR.Faction][APR.getContinent()] = {}
				end
				if (APR.getContinent() and not APR_Transport["FPs"][APR.Faction][APR.getContinent()][APR.Name.."-"..APR.Realm]) then
					APR_Transport["FPs"][APR.Faction][APR.getContinent()][APR.Name.."-"..APR.Realm] = {}
				end
				local CLi
				if (APR.getContinent() and not APR_Transport["FPs"][APR.Faction][APR.getContinent()][APR.Name.."-"..APR.Realm]["Conts"]) then
					APR_Transport["FPs"][APR.Faction][APR.getContinent()][APR.Name.."-"..APR.Realm]["Conts"] = {}
				end
				APR.LoadOptionsFrame()
				APR.BookingList["UpdateMapId"] = 1
				APR.BookingList["UpdateQuest"] = 1
				APR.BookingList["PrintQStep"] = 1
				APR.BookingList["Heirloomscheck"] = 1
				APR.CreateMacro()
				APR.RoutePlanLoadIn()
				if (not APR1[APR.Realm][APR.Name]["FirstLoadz"]) then
					APR.LoadInOptionFrame:Show()
					APR1[APR.Realm][APR.Name]["FirstLoadz"] = 1
				else
					APR.LoadInOptionFrame:Hide()
				end
				print("APR Loaded")
				APR_LoadInTimer:Stop()
				C_Timer.After(4, APR_UpdatezeMapId)
				C_Timer.After(5, APR_BookQStep)
				APR.RegisterChat = C_ChatInfo.RegisterAddonMessagePrefix("APRChat")
				--APR.FP.ToyFPs()
				local CQIDs = C_QuestLog.GetAllCompletedQuestIDs()
				APR1[APR.Realm][APR.Name]["QuestCounter"] = getn(CQIDs)
				APR1[APR.Realm][APR.Name]["QuestCounter2"] = APR1[APR.Realm][APR.Name]["QuestCounter"]
				APR_QidsTimer:Play()
			end
		end)
		APR_LoadInTimer:Play()
		APR.RegisterChat = C_ChatInfo.RegisterAddonMessagePrefix("APRChat")

		APR_QidsTimer = APR.CoreEventFrame:CreateAnimationGroup()
		APR_QidsTimer.anim = APR_QidsTimer:CreateAnimation()
		APR_QidsTimer.anim:SetDuration(1)
		APR_QidsTimer:SetLooping("REPEAT")
		APR_QidsTimer:SetScript("OnLoop", function(self, event, ...)
			if (APR1[APR.Realm][APR.Name]["QuestCounter2"] ~= APR1[APR.Realm][APR.Name]["QuestCounter"]) then
				APR.BookingList["PrintQStep"] = 1
				APR1[APR.Realm][APR.Name]["QuestCounter"] = APR1[APR.Realm][APR.Name]["QuestCounter2"]

			end
			if (not InCombatLockdown() and APR.MacroUpdaterVar[1]) then
				local macroSlot = APR.MacroUpdaterVar[1]
				local itemName = APR.MacroUpdaterVar[2]
				local APRextra = APR.MacroUpdaterVar[3]
				APR.MacroUpdater2(macroSlot,itemName,APRextra)
				APR.MacroUpdaterVar = nil
				APR.MacroUpdaterVar = {}
			end
		end)

		APR_IconTimer = APR.CoreEventFrame:CreateAnimationGroup()
		APR_IconTimer.anim = APR_IconTimer:CreateAnimation()
		APR_IconTimer.anim:SetDuration(0.05)
		APR_IconTimer:SetLooping("REPEAT")
		APR_IconTimer:SetScript("OnLoop", function(self, event, ...)
			if (APR.Icons and APR.Icons[1]) then
				if (APR1[APR.Realm][APR.Name]["Settings"]["ShowBlobs"] == 1) then
					APR:MoveIcons()
				end
			end
			if (APR.MapIcons and APR.MapIcons[1]) then
				if (APR1[APR.Realm][APR.Name]["Settings"]["ShowMapBlobs"] == 1) then
					APR:MoveMapIcons()
				end
			end
		end)
		APR_IconTimer:Play()

		if (not APR1[APR.Realm][APR.Name]["LoaPick"]) then
			APR1[APR.Realm][APR.Name]["LoaPick"] = 0
		end
			if (not APR1[APR.Realm][APR.Name]["QlineSkip"]) then
				APR1[APR.Realm][APR.Name]["QlineSkip"] = {}
			end
			if (not APR1[APR.Realm][APR.Name]["SkippedBonusObj"]) then
				APR1[APR.Realm][APR.Name]["SkippedBonusObj"] = {}
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]) then
				APR1[APR.Realm][APR.Name]["Settings"] = {}
				APR1[APR.Realm][APR.Name]["Settings"]["left"] = GetScreenWidth() / 1.6
				APR1[APR.Realm][APR.Name]["Settings"]["top"] = -(GetScreenHeight() / 5)
				APR1[APR.Realm][APR.Name]["Settings"]["Scale"] = UIParent:GetScale()
				APR1[APR.Realm][APR.Name]["Settings"]["Lock"] = 0
				APR1[APR.Realm][APR.Name]["Settings"]["Hide"] = 0
				APR1[APR.Realm][APR.Name]["Settings"]["alpha"] = 1
				APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"] = GetScreenWidth() / 2.05
				APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"] = -(GetScreenHeight() / 1.5)
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["leftLiz"] = 150
				APR1[APR.Realm][APR.Name]["Settings"]["topLiz"] = -150
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"] = 2
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["QuestButtons"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["QuestButtons"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["MiniMapBlobAlpha"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["MiniMapBlobAlpha"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["QuestButtonDetatch"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["QuestButtonDetatch"] = 0
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["ShowQuestListOrder"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["ShowQuestListOrder"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["OrderListScale"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["OrderListScale"] = 1
			end
			if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQuestListOrder"] == 1) then
				APR.ZoneQuestOrder:Show()
			else
				APR.ZoneQuestOrder:Hide()
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["ShowBlobs"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["ShowBlobs"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["ShowMap10s"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["ShowMap10s"] = 0
			end

			if (not APR1[APR.Realm][APR.Name]["Settings"]["ShowMapBlobs"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["ShowMapBlobs"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["DisableHeirloomWarning"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["DisableHeirloomWarning"] = 0
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["LockArrow"] = 0
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["AutoGossip"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["AutoGossip"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["AutoFlight"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["AutoFlight"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["Hcampleft"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["Hcampleft"] = GetScreenWidth() / 1.6
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["Hcamptop"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["Hcamptop"] = -(GetScreenHeight() / 5)
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["CutScene"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["CutScene"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] = 1
			end
			APR1[APR.Realm][APR.Name]["Settings"]["AutoShareQ"] = 0
			if (not APR1[APR.Realm][APR.Name]["Settings"]["ChooseQuests"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["ChooseQuests"] = 0
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"] = UIParent:GetScale()
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["AutoHandInChoice"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["AutoHandInChoice"] = 0
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["Greetings"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["Greetings"] = 0
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["Greetings3"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["Greetings3"] = 0
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["AutoVendor"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["AutoVendor"] = 0
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["AutoRepair"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["AutoRepair"] = 0
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["ShowArrow"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["ShowArrow"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"]) then
				APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] = 1
			end
			if (not APR1[APR.Realm][APR.Name]["APR_DoWarCampaign"]) then
				APR1[APR.Realm][APR.Name]["APR_DoWarCampaign"] = 0
			end

			if (not APR1[APR.Realm][APR.Name]["WantedQuestList"]) then
				APR1[APR.Realm][APR.Name]["WantedQuestList"] = {}
			end
			APR.ZoneQuestOrder:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["OrderListScale"])
			APR.ArrowFrame:SetScale(APR1[APR.Realm][APR.Name]["Settings"]["ArrowScale"])
			APR.ArrowFrameM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["arrowleft"], APR1[APR.Realm][APR.Name]["Settings"]["arrowtop"])

			APR.ButtonBookingTimer = APR.CoreEventFrame:CreateAnimationGroup()
			APR.ButtonBookingTimer.anim = APR.ButtonBookingTimer:CreateAnimation()
			APR.ButtonBookingTimer.anim:SetDuration(5)
			APR.ButtonBookingTimer:SetLooping("REPEAT")
			APR.ButtonBookingTimer:SetScript("OnLoop", function(self, event, ...)
				APR.SetButton()
			end)
			APR.ButtonBookingTimer:Play()
			APR.LoadInTimer = APR.CoreEventFrame:CreateAnimationGroup()
			APR.LoadInTimer.anim = APR.LoadInTimer:CreateAnimation()
			APR.LoadInTimer.anim:SetDuration(10)
			APR.LoadInTimer:SetLooping("REPEAT")
			APR.LoadInTimer:SetScript("OnLoop", function(self, event, ...)
				APR.BookingList["PrintQStep"] = 1
				APR.LoadInTimer:Stop()
			end)
			APR.LoadInTimer:Play()
			APR.ArrowEventAFkTimer = APR.CoreEventFrame:CreateAnimationGroup()
			APR.ArrowEventAFkTimer.anim = APR.ArrowEventAFkTimer:CreateAnimation()
			APR.ArrowEventAFkTimer.anim:SetDuration(0.1)
			APR.ArrowEventAFkTimer:SetLooping("REPEAT")
			APR.ArrowEventAFkTimer:SetScript("OnLoop", function(self, event, ...)
				local ZeTime = APR.AfkTimerVar - floor(GetTime())
				if (ZeTime > 0) then

					APR.AfkFrame.Fontstring:SetText("AFK: " .. string.format(SecondsToTime(ZeTime)))
					local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
					if (APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
						local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
						if (steps and steps["SpecialETAHide"]) then
							APR.AfkFrame:Hide()
						else
							APR.AfkFrame:Show()
						end
					else
						APR.AfkFrame:Show()
					end
				else
					APR.ArrowEventAFkTimer:Stop()
					APR.AfkFrame:Hide()
				end
			end)
		SlashCmdList["APR_Cmd"] = APR_SlashCmd
		SLASH_APR_Cmd1 = "/APR" -- Prefix for slash commands, ex. /apr reset, /apr skip
		CoreLoadin = 1
	elseif (event=="CINEMATIC_START") then --Cutscene skip when cinematic starts
		if (not IsControlKeyDown()) then  -- unless control key is down
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end
			if (APR1[APR.Realm][APR.Name]["Settings"]["CutScene"] == 1 and (steps and not steps["Dontskipvid"]) and (APR.ActiveQuests and not APR.ActiveQuests[52042])) then
				APR.BookingList["SkipCutscene"] = 1
			end
		end
	end
end)
