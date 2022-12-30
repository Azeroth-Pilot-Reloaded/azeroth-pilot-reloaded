local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("APR")

local QNumberLocal = 0
local APR_ArrowUpdateNr = 0
local ETAStep = 0
local APR_AntiTaxiLoop = 0
local Updateblock = 0
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local HBD = LibStub("HereBeDragons-2.0")
local APRWhereToGo
local CurMapShown
local Delaytime = 0
local APRGOSSIPCOUNT = 0
local QuestSpecial57710 = 0
local Quest2Special57710 = 0
APR.BookingList = {}
APR.HBDP = HBDP
APR.HBD = HBD
APR.ProgressbarIgnore = {
	["60520-2"] = 1,
	["57724-2"] = 1,
}
local APR_HSSpellIDs = {
	[8690] = 1,
	[298068] = 1,
	[278559] = 1,
	[278244] = 1,
	[286331] = 1,
	[286353] = 1,
	[94719] = 1,
	[285424] = 1,
	[286031] = 1,
	[285362] = 1,
	[136508] = 1,
	[75136] = 1,
	[39937] = 1,
	[231504] = 1,
	[308742] = 1,
}
local APR_GigglingBasket = {
	["One time, I managed to trick all the sylvari in a grove into thinking I was a member of their court! The other spriggans were all cheering my name for days!"] = "cheer",
	["Spriggans have our share of heroes too! The great hero Hollain was said to be able to split a mountain with a single thrust of his spear. Oh, to see such a display! How strong he must have been!"] = "flex",
	["Many seek us for our talents, but few can actually earn them. Some give gifts, always gratefully accepted. Some try to outwit us, usually failing. Some ask permission, and always thank us for our trouble."] = "thank",
	["The fae courts are very big on manners, you know. The slightest lapse in decorum can have... devastating consequences. Introductions are an important part of first impressions!"] = "introduce",
	["Oh, my feet are practically jumping with excitement! I could just dance for an eternity! Dance with me!"] = "dance",
	["We do so much to help out the people of the lands. I'm sure you've heard the stories. Mending shoes, growing fields, reuniting lost loves. But what do we get in return? Not so much as a word of praise! Hmph!"] = "praise",
	}
local APR_BonusObj = {
---- WoD Bonus Obj ----
	[36473] = 1,
	[36500] = 1,
	[36504] = 1,
	[34724] = 1,
	[36564] = 1,
	[34496] = 1,
	[36603] = 1,
	[35881] = 1,
	[37422] = 1,
	[34667] = 1,
	[36480] = 1,
	[36563] = 1,
	[36520] = 1,
	[35237] = 1,
	[34639] = 1,
	[34660] = 1,
	[36792] = 1,
	[35649] = 1,
	[36660] = 1,
---- Legion Bonus Obj ----
	[36811] = 1,
	[37466] = 1,
	[37779] = 1,
	[37965] = 1,
	[37963] = 1,
	[37495] = 1,
	[39393] = 1,
	[38842] = 1,
	[43241] = 1,
	[38748] = 1,
	[38716] = 1,
	[39274] = 1,
	[39576] = 1,
	[39317] = 1,
	[39371] = 1,
	[42373] = 1,
	[40316] = 1,
	[38442] = 1,
	[38343] = 1,
	[38939] = 1,
	[39998] = 1,
	[38374] = 1,
	[39119] = 1,
	[9785] = 1,
---- Duskwood ----
	[26623] = 1,
---- Hillsbrad Foothills ----
	[28489] = 1,
--- DH Start Area ----
	[39279] = 1,
	[39742] = 1,
---- BFA Bonus Obj ----
	[50005] = 1,
	[50009] = 1,
	[50080] = 1,
	[50448] = 1,
	[50133] = 1,
	[51534] = 1,
	[50779] = 1,
	[49739] = 1,
	[51689] = 1,
	[50497] = 1,
	[48093] = 1,
	[47996] = 1,
	[48934] = 1,
	[48852] = 1,
	[49406] = 1,
	[48588] = 1,
	[47756] = 1,
	[49529] = 1,
	[49300] = 1,
	[47797] = 1,
	[49315] = 1,
	[50178] = 1,
	[49918] = 1,
	[47527] = 1,
	[47647] = 1,
	[51900] = 1,
	[50805] = 1,
	[48474] = 1,
	[48525] = 1,
	[45972] = 1,
	[47969] = 1,
	[48181] = 1,
	[48680] = 1,
	[50091] = 1,
---- Shadowlands ----
	[60840] = 1,
	[59211] = 1,
	[62732] = 1,
	[62735] = 1,
	[59015] = 1,
}
local MapRects = {};
local TempVec2D = CreateVector2D(0,0);
local function GetPlayerMapPos(MapID, dx, dy)
	if (MapID and MapID == 1726 or MapID == 1727 or APRt_Zone == 1727) then
		return
	end
	--if (UnitPosition('player')) then
	--	return
	--end
    local R,P,_ = MapRects[MapID],TempVec2D;
    if not R then
        R = {};
        _, R[1] = C_Map.GetWorldPosFromMapPos(MapID,CreateVector2D(0,0));
        _, R[2] = C_Map.GetWorldPosFromMapPos(MapID,CreateVector2D(1,1));
        R[2]:Subtract(R[1]);
        MapRects[MapID] = R;
    end
	if (dx) then
		P.x, P.y = dx, dy
	else
		P.x, P.y = UnitPosition('player');
	end
	if (P.x) then
		P:Subtract(R[1]);
		return (1/R[2].y)*P.y, (1/R[2].x)*P.x;
	else
		return
	end
end
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
function APR:MoveIcons()
	local d_y, d_x = UnitPosition("player")
	if (IsInInstance() or APR1[APR.Realm][APR.Name]["Settings"]["ShowBlobs"] == 0 or not d_y) then
		APR.RemoveIcons()
		return
	end
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	local ix, iy
	if (APR.SettingsOpen == 1 and C_Map.GetBestMapForUnit('player')) then
		ix, iy = GetPlayerMapPos(C_Map.GetBestMapForUnit('player'), APR.ArrowActive_Y, APR.ArrowActive_X)
	elseif (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
		local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		local d_y, d_x = UnitPosition("player")
		if (steps and steps["TT"] and d_y and C_Map.GetBestMapForUnit('player')) then
			ix, iy = GetPlayerMapPos(C_Map.GetBestMapForUnit('player'), steps["TT"]["y"],steps["TT"]["x"])
		else
			return
		end
	else
		return
	end
	local steps
	if (APR.SettingsOpen == 1) then
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
		if (APR.QuestStepList[APR.ActiveMap][CurStep+1] and APR.QuestStepList[APR.ActiveMap][CurStep+1]["CRange"]) then
			totalCR = 3
		end
		if (not C_Map.GetBestMapForUnit('player')) then
			return
		end
		local px, py = GetPlayerMapPos(C_Map.GetBestMapForUnit('player'))
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
					APR.HBDP:AddMinimapIconMap("APR", APR["Icons"][CLi], C_Map.GetBestMapForUnit('player'), px2, py2, true, true)
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
		local px, py = GetPlayerMapPos(C_Map.GetBestMapForUnit('player'), APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["y"],APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["x"])
		local CLi, CLi2
		if (not APR.QuestStepList[APR.ActiveMap][CurStep+1] or APR.QuestStepList[APR.ActiveMap][CurStep+1]["ZoneDoneSave"] ) then
			for CLi = 1, 20 do
				APR.HBDP:RemoveMinimapIcon("APR", APR["Icons"][CLi])
			end
		else
			if (not C_Map.GetBestMapForUnit('player')) then
				return
			end
			local ix, iy = GetPlayerMapPos(C_Map.GetBestMapForUnit('player'), APR.QuestStepList[APR.ActiveMap][CurStep+1]["TT"]["y"],APR.QuestStepList[APR.ActiveMap][CurStep+1]["TT"]["x"])
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
						APR.HBDP:AddMinimapIconMap("APR", APR["Icons"][CLi], C_Map.GetBestMapForUnit('player'), px2, py2, true, true)
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
			local px, py = GetPlayerMapPos(C_Map.GetBestMapForUnit('player'), APR.QuestStepList[APR.ActiveMap][CurStep+1]["TT"]["y"],APR.QuestStepList[APR.ActiveMap][CurStep+1]["TT"]["x"])
			local CLi, CLi2
			local ix, iy = GetPlayerMapPos(C_Map.GetBestMapForUnit('player'), APR.QuestStepList[APR.ActiveMap][CurStep+2]["TT"]["y"],APR.QuestStepList[APR.ActiveMap][CurStep+2]["TT"]["x"])
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
						APR.HBDP:AddMinimapIconMap("APR", APR["Icons"][CLi], C_Map.GetBestMapForUnit('player'), px2, py2, true, true)
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
		local px, py = GetPlayerMapPos(C_Map.GetBestMapForUnit('player'))
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
						APR.HBDP:AddMinimapIconMap("APR", APR["Icons"][CLi], C_Map.GetBestMapForUnit('player'), px2, py2, true, true)
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
function APR:MoveMapIcons()
	local d_y, d_x = UnitPosition("player")
	if (IsInInstance() or APR1[APR.Realm][APR.Name]["Settings"]["ShowMapBlobs"] == 0 or not d_y) then
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
		C_Timer.After(0.1, APR_MapDelay)
		return
	end
	local SetMapIDs = WorldMapFrame:GetMapID()
	if (SetMapIDs == nil) then
		SetMapIDs = C_Map.GetBestMapForUnit("player")
	end
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	local ix, iy
	if (APR.SettingsOpen == 1) then
		return
	elseif (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
		local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		if (steps and steps["TT"]) then
			if (not SetMapIDs) then
				return
			end
			ix, iy = GetPlayerMapPos(SetMapIDs, steps["TT"]["y"],steps["TT"]["x"])
		else
			return
		end
	else
		return
	end
	local steps
	if (APR.SettingsOpen == 1) then
		return
	else
		steps = APR.QuestStepList[APR.ActiveMap][CurStep]
	end
	if (steps["CRange"]) then
		local CLi
		local totalCR = 1
		if (APR.QuestStepList[APR.ActiveMap][CurStep+1] and APR.QuestStepList[APR.ActiveMap][CurStep+1]["CRange"]) then
			totalCR = 3
		end
		if (not SetMapIDs) then
			return
		end
		local px, py = GetPlayerMapPos(SetMapIDs)
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
					APR.HBDP:AddWorldMapIconMap("APRMap", APR["MapIcons"][CLi], SetMapIDs, px2, py2, HBD_PINS_WORLDMAP_SHOW_PARENT)
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
		local px, py = GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["y"],APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["x"])
		local CLi, CLi2
		if (not APR.QuestStepList[APR.ActiveMap][CurStep+1] or APR.QuestStepList[APR.ActiveMap][CurStep+1]["ZoneDoneSave"]) then
			for CLi = 1, 20 do
				APR.HBDP:RemoveWorldMapIcon("APRMap", APR["MapIcons"][CLi])
			end
		else
			if (not SetMapIDs) then
				return
			end
			local ix, iy = GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep+1]["TT"]["y"],APR.QuestStepList[APR.ActiveMap][CurStep+1]["TT"]["x"])
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
						APR.HBDP:AddWorldMapIconMap("APRMap", APR["MapIcons"][CLi], SetMapIDs, px2, py2, HBD_PINS_WORLDMAP_SHOW_PARENT)
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
			local px, py = GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep+1]["TT"]["y"],APR.QuestStepList[APR.ActiveMap][CurStep+1]["TT"]["x"])
			local CLi, CLi2
			local ix, iy = GetPlayerMapPos(SetMapIDs, APR.QuestStepList[APR.ActiveMap][CurStep+2]["TT"]["y"],APR.QuestStepList[APR.ActiveMap][CurStep+2]["TT"]["x"])
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
						APR.HBDP:AddWorldMapIconMap("APRMap", APR["MapIcons"][CLi], SetMapIDs, px2, py2, HBD_PINS_WORLDMAP_SHOW_PARENT)
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
		local px, py = GetPlayerMapPos(SetMapIDs)
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
						APR.HBDP:AddWorldMapIconMap("APRMap", APR["MapIcons"][CLi], SetMapIDs, px2, py2, HBD_PINS_WORLDMAP_SHOW_PARENT)
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

APR.DubbleMacro = {}
APR.ButtonList = {}
APR.BreadCrumSkips = {}
APR.SetButtonVar = nil
APR.ButtonVisual = nil
local function APR_SettingsButtons()
	local CLi
	for CLi = 1, 3 do
		local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(6948)
		APR.QuestList2["BF"..CLi]["APR_Buttonptex"]:SetTexture(itemTexture)
		APR.QuestList2["BF"..CLi]["APR_Buttonntex"]:SetTexture(itemTexture)
		--APR.QuestList2["BF"..CLi]["APR_Button"]:SetNormalTexture(itemTexture)
		APR.QuestList2["BF"..CLi]["APR_Button"]:SetText("")
		local Topz = APR1[APR.Realm][APR.Name]["Settings"]["left"]
		local Topz2 = APR1[APR.Realm][APR.Name]["Settings"]["top"]
		APR.QuestList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT", Topz, Topz2)
		APR.QuestList2["BF"..CLi]:SetPoint("BOTTOMLEFT", APR.QuestList21, "BOTTOMLEFT",0,-((CLi * 38)+CLi))
		APR.QuestList2["BF"..CLi]:Show()
	end
end
function APR.ChkBreadcrums(qids)
	if (qids and APR.Breadcrums and APR.Breadcrums[qids]) then
		for APR_index,APR_value in pairs(APR.Breadcrums[qids]) do
			if ((APR.ActiveQuests[APR_value] or C_QuestLog.IsQuestFlaggedCompleted(APR_value) == true) and (not APR.ActiveQuests[qids])) then
				APR.BreadCrumSkips[qids] = qids
			end
		end
	end
end
local function APR_SendGroup()
	if (IsInGroup(LE_PARTY_CATEGORY_HOME) and APR1[APR.Realm][APR.Name][APR.ActiveMap] and (APR.LastSent ~= APR1[APR.Realm][APR.Name][APR.ActiveMap]) and (IsInInstance() == false)) then

		C_ChatInfo.SendAddonMessage("APRChat", APR1[APR.Realm][APR.Name][APR.ActiveMap], "PARTY");
		APR.LastSent = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	end
end
local function APR_LeaveQuest(QuestIDs)
	C_QuestLog.SetSelectedQuest(QuestIDs)
	C_QuestLog.AbandonQuest()
end
local function APR_ExitVhicle()
	VehicleExit()
end

local function APR_QAskPopWanted()
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	local steps
	if (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
		steps = APR.QuestStepList[APR.ActiveMap][CurStep]
	end
	local Qid = steps["QaskPopup"]
	if (C_QuestLog.IsQuestFlaggedCompleted(Qid) == true) then
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
		APR.BookingList["PrintQStep"] = 1
		APR.QuestList.SugQuestFrame:Hide()
	elseif (steps["QuestLineSkip"] and APR1[APR.Realm][APR.Name]["QlineSkip"][steps["QuestLineSkip"]] and APR1[APR.Realm][APR.Name]["QlineSkip"][steps["QuestLineSkip"]] == 0) then
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
		APR.BookingList["PrintQStep"] = 1
	else
		local SugGroupNr = steps["Group"]
		APR.QuestList.SugQuestFrameFS1:SetText(L["OPTIONAL"])
		APR.QuestList.SugQuestFrameFS2:SetText(L["SUGGESTED_PLAYERS"]..": "..SugGroupNr)
		APR.QuestList.SugQuestFrame:Show()
	end
end
function APR.QAskPopWantedAsk(APR_answer)
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	local steps
	if (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
		steps = APR.QuestStepList[APR.ActiveMap][CurStep]
	end
	if (APR_answer == "yes") then
		APR1[APR.Realm][APR.Name]["WantedQuestList"][steps["QaskPopup"]] = 1
		APR.QuestList.SugQuestFrame:Hide()
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
		APR.BookingList["PrintQStep"] = 1
	else
		APR.QuestList.SugQuestFrame:Hide()
		APR1[APR.Realm][APR.Name]["WantedQuestList"][steps["QaskPopup"]] = 0
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
		APR.BookingList["PrintQStep"] = 1
	end
end
local function APR_PrintQStep()
	if (APR1["Debug"]) then
		print("Function: APR_PrintQStep()")
	end
	if (IsInGroup() and APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"] == 1) then
	elseif (APR.PartyList.PartyFrames[1]:IsShown()) then
		for CLi = 1, 5 do
			APR.PartyList.PartyFrames[CLi]:Hide()
			APR.PartyList.PartyFrames2[CLi]:Hide()
		end
	end
	if (IsInInstance()) then
		for CLi = 1, 5 do
			APR.PartyList.PartyFrames[CLi]:Hide()
			APR.PartyList.PartyFrames2[CLi]:Hide()
		end
		APR.ZoneQuestOrder:Hide()
		return
	elseif (APR1[APR.Realm][APR.Name]["Settings"] and APR1[APR.Realm][APR.Name]["Settings"]["ShowQuestListOrder"] and APR1[APR.Realm][APR.Name]["Settings"]["ShowQuestListOrder"] == 1) then
		APR.ZoneQuestOrder:Show()
	end
	if (APR.ActiveMap and not APR1[APR.Realm][APR.Name][APR.ActiveMap]) then
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = 1
	end
	if (APR.ZoneTransfer == 1) then
	else
		if (APR.InCombat == 1) then
			APR.BookUpdAfterCombat = 1
		end
		local CLi
		for CLi = 1, 10 do
			if (not InCombatLockdown()) then
				if (APR.QuestList.QuestFrames["FS"..CLi]["Button"]:IsShown()) then
					APR.QuestList.QuestFrames["FS"..CLi]["Button"]:Hide()
				end
				if (APR.QuestList2["BF"..CLi]:IsShown() and APR.SettingsOpen ~= 1) then
					APR.QuestList2["BF"..CLi]:Hide()
				end
			end
		end
	end
	local LineNr = 0
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	-- Extra liners here
	local MissingQs = {}
	if (APR.Level ~= UnitLevel("player")) then
		APR.BookingList["UpdateMapId"] = 1
		APR.Level = UnitLevel("player")
	end
	if (APR1["Debug"]) then
		print("APR_PrintQStep() Step:".. CurStep)
	end
	APR_SendGroup()
	APR.FP.QuedFP = nil
	if (APR.SettingsOpen == 1) then
		if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 0 and APR.ZoneTransfer == 0) then
			return
		end
		for i=1,3 do
			LineNr = LineNr + 1
			APR.QuestList.QuestFrames["FS"..LineNr]:SetText("Test Quest number "..i)
			APR.QuestList.QuestFrames[LineNr]:Show()
			APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
			local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
			if (APRwidth and APRwidth > 400) then
				APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
			else
				APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
			end
		end
		return
	end

	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.ProgressText and APR.ProgressShown == 1) then
		APR.QuestList.QuestFrames["MyProgress"]:Show()
		APR.QuestList.QuestFrames["MyProgressFS"]:SetText(APR.ProgressText)
	else
		APR.QuestList.QuestFrames["MyProgress"]:Hide()
	end
	if (APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
		local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		local StepP, IdList
		if (APRExtraText and APR.ZoneTransfer == 0) then
			if (APRExtraText.Paths and APRExtraText.Paths[APR.ActiveMap] and APRExtraText.Paths[APR.ActiveMap][CurStep]) then
				LineNr = LineNr + 1
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(APRExtraText.Paths[APR.ActiveMap][CurStep])
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
			end
		end
		if (steps and steps["LoaPick"] and steps["LoaPick"] == 123 and ((APR.ActiveQuests[47440] or C_QuestLog.IsQuestFlaggedCompleted(47440)) or (APR.ActiveQuests[47439] or C_QuestLog.IsQuestFlaggedCompleted(47439)))) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			APR.BookingList["PrintQStep"] = 1
			return
		elseif (steps["PickedLoa"] and steps["PickedLoa"] == 2 and (APR.ActiveQuests[47440] or C_QuestLog.IsQuestFlaggedCompleted(47440))) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			APR.BookingList["PrintQStep"] = 1
			if (APR1["Debug"]) then
				print("PickedLoa Skip 2 step:".. CurStep)
			end
			return
		elseif (steps["PickedLoa"] and steps["PickedLoa"] == 1 and (APR.ActiveQuests[47439] or C_QuestLog.IsQuestFlaggedCompleted(47439))) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			APR.BookingList["PrintQStep"] = 1
			if (APR1["Debug"]) then
				print("PickedLoa Skip 1 step:".. CurStep)
			end
			return
		elseif (steps["PickUp"]) then
			StepP = "PickUp"
		elseif (steps["WarMode"]) then
			StepP = "WarMode"
		elseif (steps["DalaranToOgri"]) then
			StepP = "DalaranToOgri"
		elseif (steps["Qpart"]) then
			StepP = "Qpart"
		elseif (steps["Done"]) then
			StepP = "Done"
		elseif (steps["CRange"]) then
			StepP = "CRange"
		elseif (steps["ZonePick"]) then
			StepP = "ZonePick"
		elseif (steps["QpartPart"]) then
			StepP = "QpartPart"
		elseif (steps["DropQuest"]) then
			StepP = "DropQuest"
		elseif (steps["SetHS"]) then
			StepP = "SetHS"
		elseif (steps["UseHS"]) then
			StepP = "UseHS"
		elseif (steps["GetFP"]) then
			StepP = "GetFP"
		elseif (steps["UseFlightPath"]) then
			StepP = "UseFlightPath"
		elseif (steps["QaskPopup"]) then
			StepP = "QaskPopup"
		elseif (steps["Treasure"]) then
			StepP = "Treasure"
		elseif (steps["UseDalaHS"]) then
			StepP = "UseDalaHS"
		elseif (steps["UseGarrisonHS"]) then
			StepP = "UseGarrisonHS"
		elseif (steps["ZoneDone"]) then
			StepP = "ZoneDone"
		elseif (steps["TrainRidingSkill"]) then
			StepP = "TrainRiding"
		end
		if (steps["BreadCrum"]) then
			APR.ChkBreadcrums(steps["BreadCrum"])
		end
		if (C_QuestLog.IsQuestFlaggedCompleted(47440) == true) then
			APR1[APR.Realm][APR.Name]["LoaPick"] = 1
		elseif (C_QuestLog.IsQuestFlaggedCompleted(47439) == true) then
			APR1[APR.Realm][APR.Name]["LoaPick"] = 2
		end
		if (steps["LeaveQuest"]) then
			APR_LeaveQuest(steps["LeaveQuest"])
		end
		if (steps["LeaveQuests"]) then
			for APR_index,APR_value in pairs(steps["LeaveQuests"]) do
				APR_LeaveQuest(APR_value)
			end
		end
		if (APR1["Debug"]) then
			print(StepP)
		end
		if (steps["ZoneDoneSave"]) then
			local zeMApz
			if (APR.QuestStepListListing["Shadowlands"][APR.ActiveMap]) then
				zeMApz = APR.QuestStepListListing["Shadowlands"][APR.ActiveMap]
			elseif (APR.QuestStepListListing["Extra"][APR.ActiveMap]) then
				zeMApz = APR.QuestStepListListing["Extra"][APR.ActiveMap]
			elseif (APR.QuestStepListListing["MISC 1"][APR.ActiveMap]) then
				zeMApz = APR.QuestStepListListing["MISC 1"][APR.ActiveMap]
			elseif (APR.QuestStepListListing["MISC 2"][APR.ActiveMap]) then
				zeMApz = APR.QuestStepListListing["MISC 2"][APR.ActiveMap]
			elseif (APR.QuestStepListListing["Dragonflight"][APR.ActiveMap]) then
				zeMApz = APR.QuestStepListListing["Dragonflight"][APR.ActiveMap]
			elseif (APR.QuestStepListListing["Kalimdor"][APR.ActiveMap]) then
				zeMApz = APR.QuestStepListListing["Kalimdor"][APR.ActiveMap]
			elseif (APR.QuestStepListListing["SpeedRun"][APR.ActiveMap]) then
				zeMApz = APR.QuestStepListListing["SpeedRun"][APR.ActiveMap]
			elseif (APR.QuestStepListListing["EasternKingdom"][APR.ActiveMap]) then
				zeMApz = APR.QuestStepListListing["EasternKingdom"][APR.ActiveMap]
			elseif (APR.QuestStepListListingStartAreas["EasternKingdom"] and APR.QuestStepListListingStartAreas["EasternKingdom"][APR.ActiveMap]) then
				zeMApz = APR.QuestStepListListingStartAreas["EasternKingdom"][APR.ActiveMap]
			elseif (APR.QuestStepListListingStartAreas["Kalimdor"] and APR.QuestStepListListingStartAreas["Kalimdor"][APR.ActiveMap]) then
				zeMApz = APR.QuestStepListListingStartAreas["Kalimdor"][APR.ActiveMap]
			elseif (APR_Custom[APR.Name.."-"..APR.Realm] and APR_Custom[APR.Name.."-"..APR.Realm][APR.ActiveMap]) then
				zeMApz = APR_Custom[APR.Name.."-"..APR.Realm][APR.ActiveMap]
			end
			if (zeMApz) then
				APR_ZoneComplete[APR.Name.."-"..APR.Realm][zeMApz] = 1
				for CLi = 1, 19 do
					if (APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:GetText() == zeMApz) then
						APR.RoutePlan.FG1["Fxz2Custom"..CLi]["FS"]:SetText("")
						APR.RoutePlan.FG1["Fxz2Custom"..CLi]:Hide()
					end
				end
				APR.RoutePlanCheckPos()
				APR.CheckCustomEmpty()
				APR.BookingList["UpdateMapId"] = 1
			end
		end
		if (steps["SpecialLeaveVehicle"]) then
			C_Timer.After(1, APR_ExitVhicle)
			C_Timer.After(3, APR_ExitVhicle)
			C_Timer.After(5, APR_ExitVhicle)
			C_Timer.After(10, APR_ExitVhicle)
		end
		if (steps["VehicleExit"]) then
			VehicleExit()
		end
		if (steps["SpecialFlight"] and C_QuestLog.IsQuestFlaggedCompleted(steps["SpecialFlight"])) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			APR.BookingList["PrintQStep"] = 1
		end
		if (steps["GroupTask"] and APR1[APR.Realm][APR.Name]["WantedQuestList"][steps["GroupTask"]] and APR1[APR.Realm][APR.Name]["WantedQuestList"][steps["GroupTask"]] == 0) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			APR.BookingList["PrintQStep"] = 1
			return
		end
		if (steps["ETA"] and not steps["UseFlightPath"]) then
			if (ETAStep ~= CurStep) then
				APR.AFK_Timer(steps["ETA"])
				ETAStep = CurStep
			end
		end
		if (steps["UseGlider"] and APR.ZoneTransfer == 0) then
			if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1) then
				LineNr = LineNr + 1
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["USE_ITEM"]..": "..APR.GliderFunc())
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
			end
		end
		if (steps["Bloodlust"] and APR.ZoneTransfer == 0) then
			if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1) then
				LineNr = LineNr + 1
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars(L["BLOODLUST"]))
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
			end
		end
		if (steps["InVehicle"] and not UnitInVehicle("player") and APR.ZoneTransfer == 0) then
			LineNr = LineNr + 1
			APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["MOUNT_HORSE_SCARE_SPIDER"])
			APR.QuestList.QuestFrames[LineNr]:Show()
			APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
			local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
			if (APRwidth and APRwidth > 400) then
				APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
			else
				APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
			end
		elseif (steps["InVehicle"] and steps["InVehicle"] == 2 and UnitInVehicle("player") and APR.ZoneTransfer == 0) then
			LineNr = LineNr + 1
			APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["SCARE_SPIDER_INTO_LUMBERMILL"])
			APR.QuestList.QuestFrames[LineNr]:Show()
			APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
			local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
			if (APRwidth and APRwidth > 400) then
				APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
			else
				APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
			end
		end
		if (steps["ExtraActionB"] and APR.ZoneTransfer == 0) then
			local isFound, macroSlot = APR.MacroFinder()
			if isFound and macroSlot then
				if (steps["ExtraActionB"] == 6666) then
					APR.MacroUpdater(macroSlot, 6666666)
				else
					APR.MacroUpdater(macroSlot, 123123123)
				end
			end
		end
		if (steps["DalaranToOgri"] and APR.ZoneTransfer == 0) then
			if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1) then
				LineNr = LineNr + 1
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["GO_TO"].." Orgrimmar")
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
			end
		end

		if (APR.Level > 35 and APR.Level < 50) then
			if (APR.ActiveMap and APR.QuestStepListListing["Shadowlands"][APR.ActiveMap]) then
				local OnTime = 0
				-- 9 = WOD
				local chromieExpansionOption = C_ChromieTime.GetChromieTimeExpansionOption(9)
				if (chromieExpansionOption and chromieExpansionOption.alreadyOn == true) then
					OnTime = 1
				end
				if (OnTime == 0) then
					LineNr = LineNr + 1
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars(L["NOT_IN_CHROMIE_TIMELINE"]))
					APR.QuestList.QuestFrames[LineNr]:Show()
				end
			end
		end
		if (steps["DoIHaveFlight"]) then
			if (GetSpellBookItemInfo(GetSpellInfo(33391)) or GetSpellBookItemInfo(GetSpellInfo(90265)) or GetSpellBookItemInfo(GetSpellInfo(34090))) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["UpdateQuest"] = 1
				APR.BookingList["PrintQStep"] = 1
			end
		end
		-- check if you have the lvl and the skill in your spell book
		function DisplayRiding(text)
			if(APR1[APR.Realm][APR.Name]["hideRidingSkill"] == 0) then
				LineNr = LineNr + 1
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars(text))
				--skip waypoint button
				-- TODO : fix display button
				AddQuestListButton(L["SKIP_BUTTON"], LineNr, function(self, button)
					APR1[APR.Realm][APR.Name]["hideRidingSkill"] = 1
					APR.QuestList.QuestFrames["FS"..LineNr].Button:Hide()
					APR.QuestList.QuestFrames[LineNr]:Hide()
				end)
				APR.QuestList.QuestFrames[LineNr]:Show()
			end
		end
		if(not GetSpellBookItemInfo(GetSpellInfo(90265))) then
			if (APR.Level >= 40 and APR.Level < 60) then
				DisplayRiding(L["YOU_CAN_LEARN"].." "..L["MASTER_RIDING"])
			elseif (APR.Level >= 30 and APR.Level < 40 and not GetSpellBookItemInfo(GetSpellInfo(34090))) then
				local ridingText
				if (APR.Faction == "Alliance" and APR.ActiveMap and APR.ActiveMap == "A543-DesMephisto-Gorgrond") then
					ridingText = L["USE_HEARTHSTONE"].." "..L["GO_TO"].." Stormwind, "..L["YOU_CAN_LEARN"].." "..L["EXPERT_RIDING"]
				elseif (APR.Faction == "Horde" and APR.ActiveMap and APR.ActiveMap == "543-DesMephisto-Gorgrond-p1") then
					ridingText = L["USE_HEARTHSTONE"].." "..L["GO_TO"].." Orgrimmar, "..L["YOU_CAN_LEARN"].." "..L["EXPERT_RIDING"]
				else
					ridingText = L["YOU_CAN_LEARN"].." "..L["EXPERT_RIDING"]
				end
				DisplayRiding(ridingText)
			elseif (APR.Level >= 20 and APR.Level < 30 and not GetSpellBookItemInfo(GetSpellInfo(33391))) then
				DisplayRiding(L["YOU_CAN_LEARN"].." "..L["JOURNEYMAN_RIDING"])
			elseif (APR.Level >= 10 and APR.Level < 20 and not GetSpellBookItemInfo(GetSpellInfo(33388))) then
				DisplayRiding(L["YOU_CAN_LEARN"].." "..L["APPRENTICE_RIDING"])
			end
		end
		if ((steps["ExtraLine"] or steps["ExtraLineText"]) and APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
			LineNr = LineNr + 1
			local APRExtraLine = steps["ExtraLine"]
			local APRExtraText = steps["ExtraLineText"]
			if (steps["ExtraLineText"] and L[APRExtraText]) then
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars(L[APRExtraText]))
			elseif(steps["ExtraLineText"]) then
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars(APRExtraText))
			end
			if (APRExtraLine == 35) then
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars(L["LOA_INFO_1"]))
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
				LineNr = LineNr + 1
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars(L["LOA_INFO_2"]))
			end
			if (APRExtraLine == 13544) then
				local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(44886)
				if (itemLink and GetItemCount(itemLink)) then
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["KILL_FLEETFOOT"].." (".. GetItemCount(itemLink) .."/1)")
					if (GetItemCount(itemLink) and GetItemCount(itemLink) > 0) then
						APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
						APR.BookingList["UpdateQuest"] = 1
						APR.BookingList["PrintQStep"] = 1
					end
				end
			end
			if (APRExtraLine == 13595) then
				local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(44967)
				if (itemLink and GetItemCount(itemLink)) then
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["LOOT_WILDFIRE_BOTTLE"].." (".. GetItemCount(itemLink) .."/1)")
					if (GetItemCount(itemLink) and GetItemCount(itemLink) > 0) then
						APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
						APR.BookingList["UpdateQuest"] = 1
						APR.BookingList["PrintQStep"] = 1
					end
				end
			end
			if (APRExtraLine == 14358) then
				local zdsLine = 0
				local zdsLine2 = 0
				local zdsLine3 = 0
				if (GetItemInfo(48106) and GetItemCount(GetItemInfo(48106))) then
					if (GetItemCount(GetItemInfo(48106)) and GetItemCount(GetItemInfo(48106)) < 8) then
						APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] ".. GetItemCount(GetItemInfo(48106)) .."/8 "..L["LOOT_MELONFRUIT"])
						zdsLine = 1
						APR.QuestList.QuestFrames[LineNr]:Show()
						APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
						local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
						if (APRwidth and APRwidth > 400) then
							APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
						else
							APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
						end
					end
				end
				if (GetItemCount(GetItemInfo(48857))) then
					if (GetItemCount(GetItemInfo(48857)) and GetItemCount(GetItemInfo(48857)) < 10) then
						if (zdsLine == 1) then
							LineNr = LineNr + 1
						end
						APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] ".. GetItemCount(GetItemInfo(48857)) .."/10 "..L["KILL_SATYR_FLESH"])
						zdsLine2 = 1
						APR.QuestList.QuestFrames[LineNr]:Show()
						APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
						local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
						if (APRwidth and APRwidth > 400) then
							APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
						else
							APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
						end
					end
				end
				if (GetItemInfo(48943) and GetItemCount(GetItemInfo(48943))) then
					if (GetItemCount(GetItemInfo(48943)) and GetItemCount(GetItemInfo(48943)) < 20) then
						if (zdsLine2 == 1) then
							LineNr = LineNr + 1
						end
						APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] ".. GetItemCount(GetItemInfo(48943)) .."/20 "..L["LOOT_SATYR_SABER"])
						zdsLine3 = 1
						APR.QuestList.QuestFrames[LineNr]:Show()
						APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
						local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
						if (APRwidth and APRwidth > 400) then
							APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
						else
							APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
						end
					end
				end
				if (zdsLine == 0 and zdsLine2 == 0 and zdsLine3 == 0) then
					APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
					APR.BookingList["UpdateQuest"] = 1
					APR.BookingList["PrintQStep"] = 1
				end
			end
			if (APRExtraLine == 25654) then
				if (GetItemInfo(9530) and GetItemCount(GetItemInfo(9530))) then
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["LOOT_HARPYS_HORN"].."(".. GetItemCount(GetItemInfo(9530)) .."/1)")
					if (GetItemCount(GetItemInfo(9530)) and GetItemCount(GetItemInfo(9530)) > 0) then
						APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
						APR.BookingList["UpdateQuest"] = 1
						APR.BookingList["PrintQStep"] = 1
					end
				end
			end
			if (APRExtraLine == 27237) then
				local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(33044)
				if (itemLink and GetItemCount(itemLink)) then
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["OPEN_BAG"])
					if (GetItemCount(itemLink) and GetItemCount(itemLink) > 0) then
						APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
						APR.BookingList["UpdateQuest"] = 1
						APR.BookingList["PrintQStep"] = 1
					end
				end
			end
			APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
			APR.QuestList.QuestFrames[LineNr]:Show()
			local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
			if (APRwidth and APRwidth > 400) then
				APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
			else
				APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
			end
		end
		for i = 2, 4 do -- other ExtraLineText
			local extraLineTestX = "ExtraLineText"..i
			if ((steps[extraLineTestX]) and APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
				LineNr = LineNr + 1
				if (steps[extraLineTestX]) then
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars(steps[extraLineTestX]))
				end
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				APR.QuestList.QuestFrames[LineNr]:Show()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
			end
		end
		if (APR.ActiveQuests and APR.ActiveQuests[57867] and APR.ZoneTransfer == 0) then
			APR.QuestList.SweatOfOurBrowBuffFrame:Show()
		else
			APR.QuestList.SweatOfOurBrowBuffFrame:Hide()
		end
		if (StepP == "Qpart") then
			local IdList = steps["Qpart"]
			if (steps["QpartDB"]) then
				local ZeIDi = 0
				for hz=1, getn(steps["QpartDB"]) do
					local ZeQID = steps["QpartDB"][hz]
					if (C_QuestLog.IsQuestFlaggedCompleted(ZeQID) or APR.ActiveQuests[ZeQID]) then
						ZeIDi = ZeQID
						break
					end
				end
				local newList = {}
				for APR_index,APR_value in pairs(IdList) do
					newList = APR_value
					break
				end
				IdList = nil
				IdList = {}
				IdList[ZeIDi] = newList
			end
			if (steps["QSpecialz"] and APR.ActiveQuests["57657-2"]) then
				for i=1,40 do
					local name, rank, count, debuffType, duration, expirationTime, unitCaster, isStealable, asd, spellId  = UnitDebuff("player", i)
					if (spellId and spellId == 309806) then
						LineNr = LineNr + 1
						APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] "..count.."/30 "..L["GORMLINGS_COLLECTED"])
						APR.QuestList.QuestFrames[LineNr]:Show()
						local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
						if (APRwidth and APRwidth > 400) then
							APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
						else
							APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
						end
						if (count == 30) then
							APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
							APR.BookingList["UpdateQuest"] = 1
							APR.BookingList["PrintQStep"] = 1
						end
					end
				end
			end
			if (APR.ActiveQuests["57710-2"]) then
				if (Quest2Special57710 ~= APR.ActiveQuests["57710-2"]) then
					Quest2Special57710 = APR.ActiveQuests["57710-2"]
					QuestSpecial57710 = 0
				end
				if (QuestSpecial57710 == 0) then
					LineNr = LineNr + 1
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars(L["CLICK_ETERNAL_FLAME"]))
					APR.QuestList.QuestFrames[LineNr]:Show()
					local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
					if (APRwidth and APRwidth > 400) then
						APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
					else
						APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
					end
				end
			end
			local Flagged = 0
			local Total = 0
			for APR_index,APR_value in pairs(IdList) do
				for APR_index2,APR_value2 in pairs(APR_value) do
					Total = Total + 1
					local qid = APR_index.."-"..APR_index2
					if (C_QuestLog.IsQuestFlaggedCompleted(APR_index) or ((UnitLevel("player") == 121) and APR_BonusObj[APR_index]) or APR1[APR.Realm][APR.Name]["BonusSkips"][APR_index] or APR.BreadCrumSkips[APR_index]) then
						Flagged = Flagged + 1
					elseif (APR.ActiveQuests[qid] and APR.ActiveQuests[qid] == "C") then
						Flagged = Flagged + 1
					elseif (APR.ActiveQuests[qid]) then
						if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
							LineNr = LineNr + 1
							local ZeTExt
							if (APR.ActiveQuests["57713-4"] and UIWidgetTopCenterContainerFrame and UIWidgetTopCenterContainerFrame["widgetFrames"]) then
								for APR_index2,APR_value2 in APR.pairsByKeys(UIWidgetTopCenterContainerFrame["widgetFrames"]) do
									if (UIWidgetTopCenterContainerFrame["widgetFrames"][APR_index2]["Text"]) then
										ZeTExt = UIWidgetTopCenterContainerFrame["widgetFrames"][APR_index2]["Text"]:GetText()
										if (string.find(ZeTExt, "(%d+)(.*)")) then
											local _,_,ZeTExt2 = string.find(ZeTExt, "(%d+)(.*)")
											ZeTExt = ZeTExt2
										end
									end
								end
							end

							local checkpbar = C_QuestLog.GetQuestObjectives(APR_index)
						--	if (checkpbar and checkpbar[tonumber(APR_index2)] and checkpbar[tonumber(APR_index2)]["type"] and checkpbar[tonumber(APR_index2)]["type"] == "progressbar") then
						--		APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] "..GetQuestProgressBarPercent(APR_index).."/100 "..APR.ActiveQuests[qid])
							if (not string.find(APR.ActiveQuests[qid], "(.*)(%d+)(.*)") and checkpbar and checkpbar[tonumber(APR_index2)] and checkpbar[tonumber(APR_index2)]["type"] and checkpbar[tonumber(APR_index2)]["type"] == "progressbar") then
								APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] ["..GetQuestProgressBarPercent(APR_index).."%] "..APR.ActiveQuests[qid])
							elseif (ZeTExt) then
								APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] "..ZeTExt.."% - "..APR.ActiveQuests[qid])
							else
								APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] "..APR.ActiveQuests[qid])
							end
							APR.QuestList.QuestFrames[LineNr]:Show()
							APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
							local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
							if (APRwidth and APRwidth > 400) then
								APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
							else
								APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
							end
							if (steps["Button"] and steps["Button"][qid]) then
								if (not APR.SetButtonVar) then
									APR.SetButtonVar = {}
								end
								APR.SetButtonVar[qid] = LineNr
							end
							if (APR_BonusObj[APR_index]) then
								APR.QuestList.QuestFrames[LineNr]["BQid"] = APR_index
								APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Show()
							else
								APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
							end
						end
					elseif (not APR.ActiveQuests[APR_index] and not MissingQs[APR_index]) then
						if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
							if (APR_BonusObj[APR_index]) then
								LineNr = LineNr + 1
								APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["DO_BONUS_OBJECTIVE"]..": "..APR_index)
								APR.QuestList.QuestFrames[LineNr]:Show()
								APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
								local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
								if (APRwidth and APRwidth > 400) then
									APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
								else
									APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
								end
								MissingQs[APR_index] = 1
								if (APR_BonusObj[APR_index]) then
									APR.QuestList.QuestFrames[LineNr]["BQid"] = APR_index
									APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Show()
								else
									APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
								end
							else
								LineNr = LineNr + 1
								APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["ERROR"].." - "..L["MISSING_Q"]..": "..APR_index)
								APR.QuestList.QuestFrames[LineNr]:Show()
								APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
								local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
								if (APRwidth and APRwidth > 400) then
									APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
								else
									APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
								end
								MissingQs[APR_index] = 1
								if (APR_BonusObj[APR_index]) then
									APR.QuestList.QuestFrames[LineNr]["BQid"] = APR_index
									APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Show()
								else
									APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
								end
							end
						end
					end
				end
			end
			if (Flagged == Total and Flagged > 0) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		
		elseif (StepP == "PickUp") then
			IdList = steps["PickUp"]
			if (steps["PickDraenor"]) then
				if not EncounterJournal then
					EncounterJournal_LoadUI()
				end
				ToggleFrame(EncounterJournal)
			end
			if (steps["PickUpDB"]) then
				local Flagged = 0
				for hz=1, getn(steps["PickUpDB"]) do
					local ZeQID = steps["PickUpDB"][hz]
					if (C_QuestLog.IsQuestFlaggedCompleted(ZeQID) or APR.ActiveQuests[ZeQID]) then
						Flagged = ZeQID
					end
				end
				if (Flagged > 0) then
					APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
					APR.BookingList["UpdateQuest"] = 1
					APR.BookingList["PrintQStep"] = 1
				else
					if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
						LineNr = LineNr + 1
						APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["PICK_UP_Q"]..": 1")
						APR.QuestList.QuestFrames[LineNr]:Show()
						APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
						local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
						if (APRwidth and APRwidth > 400) then
							APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
						else
							APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
						end
					end
				end
			else
				local NrLeft = 0
				local Flagged = 0
				local Total = 0
				local NrLeft2 = 0
				local Flagged2 = 0
				local Total2 = 0
				for h=1, getn(IdList) do
					local theqid = IdList[h]
					Total = Total + 1
					if (not APR.ActiveQuests[theqid] and C_QuestLog.IsQuestFlaggedCompleted(theqid) == false) then
						NrLeft = NrLeft + 1
					end
					if (C_QuestLog.IsQuestFlaggedCompleted(theqid) or APR.ActiveQuests[theqid] or APR.BreadCrumSkips[theqid]) then
						Flagged = Flagged + 1
					end
				end
				if (steps["PickUp2"]) then
					IdList2 = steps["PickUp2"]
					for h=1, getn(IdList2) do
						local theqid = IdList2[h]
						Total2 = Total2 + 1
						if (not APR.ActiveQuests[theqid]) then
							NrLeft2 = NrLeft2 + 1
						end
						if (C_QuestLog.IsQuestFlaggedCompleted(theqid) or APR.ActiveQuests[theqid] or APR.BreadCrumSkips[theqid]) then
							Flagged2 = Flagged2 + 1
						end
					end
				end
				if (Total == Flagged) then
					APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
					if (APR1["Debug"]) then
						print("APR.PrintQStep:PickUp:Plus:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
					end
					APR.BookingList["UpdateQuest"] = 1
					APR.BookingList["PrintQStep"] = 1
				elseif (steps["PickUp2"] and Total2 == Flagged2) then
					APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
					if (APR1["Debug"]) then
						print("APR.PrintQStep:PickUp:Plus2:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
					end
					APR.BookingList["UpdateQuest"] = 1
					APR.BookingList["PrintQStep"] = 1
				else
					if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
						LineNr = LineNr + 1
						APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["PICK_UP_Q"]..": "..NrLeft)
						APR.QuestList.QuestFrames[LineNr]:Show()
						APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
						local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
						if (APRwidth and APRwidth > 400) then
							APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
						else
							APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
						end
					end
				end
			end
		elseif (StepP == "CRange") then
			IdList = steps["CRange"]
			if (C_QuestLog.IsQuestFlaggedCompleted(IdList) or APR.BreadCrumSkips[IdList]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				if (APR1["Debug"]) then
					print("APR.PrintQStep:CRange:Plus:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
				end
				APR.BookingList["UpdateQuest"] = 1
				APR.BookingList["PrintQStep"] = 1
			else
				if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
					LineNr = LineNr + 1
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(APR.CheckCRangeText())
					APR.QuestList.QuestFrames[LineNr]:Show()
--					APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
					APR.QuestList.QuestFrames[LineNr]["BQid"] = APR_index
					APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Show()
					local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
					if (APRwidth and APRwidth > 400) then
						APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
					else
						APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
					end
				end
			end
		elseif (StepP == "TrainRiding") then
			if (C_QuestLog.IsQuestFlaggedCompleted(steps["TrainRidingSkill"]) or CheckRidingSkill(steps["SpellInTab"])) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["UpdateQuest"] = 1
				APR.BookingList["PrintQStep"] = 1
			end
		elseif (StepP == "Treasure") then
			IdList = steps["Treasure"]
			if (C_QuestLog.IsQuestFlaggedCompleted(IdList)) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				if (APR1["Debug"]) then
					print("APR.PrintQStep:Treasure:Plus:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
				end
				APR.BookingList["UpdateQuest"] = 1
				APR.BookingList["PrintQStep"] = 1
			else
				if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
					LineNr = LineNr + 1
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["GET_TREASURE"])
					APR.QuestList.QuestFrames[LineNr]:Show()
					APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
					local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
					if (APRwidth and APRwidth > 400) then
						APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
					else
						APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
					end
				end
			end
		elseif (StepP == "DropQuest") then
			IdList = steps["DropQuest"]
			if (C_QuestLog.IsQuestFlaggedCompleted(IdList) or APR.ActiveQuests[IdList]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				if (APR1["Debug"]) then
					print("APR.PrintQStep:DropQuest:Plus:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
				end
				APR.BookingList["UpdateQuest"] = 1
				APR.BookingList["PrintQStep"] = 1
			end
		elseif (StepP == "Done") then
			IdList = steps["Done"]
			if (steps["DoneDB"]) then
				local Flagged = 0
				for hz=1, getn(steps["DoneDB"]) do
					local zEQID = steps["DoneDB"][hz]
					if (C_QuestLog.IsQuestFlaggedCompleted(zEQID) or APR.ActiveQuests[zEQID]) then
						IdList = nil
						IdList = {}
						tinsert(IdList,zEQID)
						break
					end
				end
			end
			local NrLeft = 0
			local Flagged = 0
			local Total = 0
			for h=1, getn(IdList) do
				Total = Total + 1
				local theqid = IdList[h]
				if (APR.ActiveQuests[theqid]) then
					NrLeft = NrLeft + 1
				end
				if (C_QuestLog.IsQuestFlaggedCompleted(theqid) or APR.BreadCrumSkips[theqid]) then
					Flagged = Flagged + 1
				end
				if (steps["Button"] and steps["Button"][tostring(theqid)]) then
					if (not APR.SetButtonVar) then
						APR.SetButtonVar = {}
					end
					APR.SetButtonVar[tostring(theqid)] = LineNr+1
				end
			end
			if (Total == Flagged) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			else
				if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
					LineNr = LineNr + 1
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["TURN_IN_Q"]..": "..NrLeft)
					APR.QuestList.QuestFrames[LineNr]:Show()
					APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
					local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
					if (APRwidth and APRwidth > 400) then
						APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
					else
						APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
					end
				end
			end
		elseif (StepP == "WarMode") then
			if (C_QuestLog.IsQuestFlaggedCompleted(steps["WarMode"]) or C_PvP.IsWarModeDesired() == true) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			else
				if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
					LineNr = LineNr + 1
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars(L["TURN_ON_WARMODE"], 3))
					APR.QuestList.QuestFrames[LineNr]:Show()
					APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
					local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
					if (APRwidth and APRwidth > 400) then
						APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
					else
						APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
					end
				end
				if (C_PvP.IsWarModeDesired() == false and C_PvP.CanToggleWarMode(toggle) == true) then
					C_PvP.ToggleWarMode()
					APR.BookingList["PrintQStep"] = 1
				end
			end
		elseif (StepP == "UseDalaHS") then
			if (C_QuestLog.IsQuestFlaggedCompleted(steps["UseDalaHS"])) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			else
				if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
					LineNr = LineNr + 1
					if (steps["Button"] and steps["Button"]["12112552-1"]) then
						if (not APR.SetButtonVar) then
							APR.SetButtonVar = {}
						end
						APR.SetButtonVar["12112552-1"] = LineNr
					end
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["USE_DALARAN_HEARTHSTONE"])
					APR.QuestList.QuestFrames[LineNr]:Show()
					APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
					local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
					if (APRwidth and APRwidth > 400) then
						APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
					else
						APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
					end
					APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Show()
				end
			end
		elseif (StepP == "UseGarrisonHS") then
			if (C_QuestLog.IsQuestFlaggedCompleted(steps["UseGarrisonHS"])) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			else
				if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
					LineNr = LineNr + 1
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["USE_GARRISON_HEARTHSTONE"])
					APR.QuestList.QuestFrames[LineNr]:Show()
					APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
					if (steps["Button"] and steps["Button"][tostring(steps["UseGarrisonHS"])]) then
						if (not APR.SetButtonVar) then
							APR.SetButtonVar = {}
						end
						APR.SetButtonVar[tostring(steps["UseGarrisonHS"])] = LineNr
					end
					local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
					if (APRwidth and APRwidth > 400) then
						APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
					else
						APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
					end
					APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Show()
				end
			end
		elseif (StepP == "ZonePick") then
			if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
				LineNr = LineNr + 1
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["PICK_ZONE"])
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
			end
		elseif (StepP == "SetHS") then
			if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
				LineNr = LineNr + 1
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["SET_HEARTHSTONE"])
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
			end
			if (C_QuestLog.IsQuestFlaggedCompleted(steps["SetHS"])) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			elseif (steps["HSZone"] and APR1[APR.Realm][APR.Name]["HSLoc"] and APR1[APR.Realm][APR.Name]["HSLoc"] == steps["HSZone"]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		elseif (StepP == "UseHS") then
			if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
				LineNr = LineNr + 1
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["USE_HEARTHSTONE"])
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
				if (not APR.SetButtonVar) then
					APR.SetButtonVar = {}
				end
				APR.SetButtonVar[steps["UseHS"]] = LineNr
			end
			if (C_QuestLog.IsQuestFlaggedCompleted(steps["UseHS"])) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		elseif (StepP == "GetFP") then
			if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
				APR.FP.GoToZone = nil
				LineNr = LineNr + 1
				APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["GET_FLIGHTPATH"])
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
			end
			if (C_QuestLog.IsQuestFlaggedCompleted(steps["GetFP"])) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		elseif (StepP == "UseFlightPath") then
			if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
				LineNr = LineNr + 1
				if (steps["Boat"]) then
					if (steps["Name"]) then
						APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["USE_BOAT"]..": "..steps["Name"])
					else
						APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["USE_BOAT"])
					end

				else
					if (steps["Name"]) then
						APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["USE_FLIGHTPATH"]..": "..steps["Name"])
					else
						APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["USE_FLIGHTPATH"])
					end
				end
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
			end
			if (steps["SkipIfOnTaxi"] and UnitOnTaxi("player")) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
			if (C_QuestLog.IsQuestFlaggedCompleted(steps["UseFlightPath"])) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		elseif (StepP == "QaskPopup") then
			if (C_QuestLog.IsQuestFlaggedCompleted(steps["QaskPopup"])) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			else
				APR_QAskPopWanted()
			end
		elseif (StepP == "QpartPart") then
			IdList = steps["QpartPart"]
			local Flagged = 0
			local Total = 0
			for APR_index,APR_value in pairs(IdList) do
				for APR_index2,APR_value2 in pairs(APR_value) do
					Total = Total + 1
					if (C_QuestLog.IsQuestFlaggedCompleted(APR_index)) then
						Flagged = Flagged + 1
					end
					local qid = APR_index.."-"..APR_index2
					if (APR.ActiveQuests[qid] and APR.ActiveQuests[qid] == "C") then
						Flagged = Flagged + 1
					elseif (APR.ActiveQuests[qid]) then
						if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
							LineNr = LineNr + 1
							APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] "..APR.ActiveQuests[qid])
							APR.QuestList.QuestFrames[LineNr]:Show()
							APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
							local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
							if (APRwidth and APRwidth > 400) then
								APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
							else
								APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
							end
							if (steps["Button"] and steps["Button"][qid]) then
								if (not APR.SetButtonVar) then
									APR.SetButtonVar = {}
								end
								APR.SetButtonVar[qid] = LineNr
							end
						end
					elseif (not APR.ActiveQuests[APR_index] and not MissingQs[APR_index]) then
						if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
							if (APR_BonusObj[APR_index]) then
								LineNr = LineNr + 1
								APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["DO_BONUS_OBJECTIVE"]..": "..APR_index)
								APR.QuestList.QuestFrames[LineNr]:Show()
								APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
								local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
								if (APRwidth and APRwidth > 400) then
									APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
								else
									APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
								end
								MissingQs[APR_index] = 1
								if (APR_BonusObj[APR_index]) then
									APR.QuestList.QuestFrames[LineNr]["BQid"] = APR_index
									APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Show()
								else
									APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
								end
							elseif (APR.ZoneTransfer == 0) then
								LineNr = LineNr + 1
								APR.QuestList.QuestFrames["FS"..LineNr]:SetText(L["ERROR"].." - "..L["MISSING_Q"]..": "..APR_index)
								APR.QuestList.QuestFrames[LineNr]:Show()
								APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
								local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
								if (APRwidth and APRwidth > 400) then
									APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
								else
									APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
								end
							end
						end
						MissingQs[APR_index] = 1
					end
				end
			end
			if (Flagged == Total) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			elseif (LineNr == 0) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			elseif (steps and steps["TrigText"]) then
				for APR_index,APR_value in pairs(steps["QpartPart"]) do
					for APR_index2,APR_value2 in pairs(APR_value) do
						if (APR.ActiveQuests[APR_index.."-"..tonumber(APR_index2)]) then
							if (string.find(APR.ActiveQuests[APR_index.."-"..tonumber(APR_index2)], steps["TrigText"])) then
								APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
								APR.BookingList["PrintQStep"] = 1
							elseif (steps["TrigText2"] and string.find(APR.ActiveQuests[APR_index.."-"..tonumber(APR_index2)], steps["TrigText2"])) then
								APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
								APR.BookingList["PrintQStep"] = 1
							elseif (steps["TrigText3"] and string.find(APR.ActiveQuests[APR_index.."-"..tonumber(APR_index2)], steps["TrigText3"])) then
								APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
								APR.BookingList["PrintQStep"] = 1
							end
						end
					end
				end
			end
		end
		if (steps["DroppableQuest"] and not C_QuestLog.IsQuestFlaggedCompleted(steps["DroppableQuest"]["Qid"]) and not APR.ActiveQuests[steps["DroppableQuest"]["Qid"]]) then
			if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
				LineNr = LineNr + 1
				local MobName = steps["DroppableQuest"]["Text"]
				if (APR.NPCList[steps["DroppableQuest"]["MobId"]]) then
					MobName = APR.NPCList[steps["DroppableQuest"]["MobId"]]
				end
				if (L[MobName]) then
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText("[".. LineNr .."] "..L[MobName].." - "..L["Q_DROP"])
				else
					APR.QuestList.QuestFrames["FS"..LineNr]:SetText("[".. LineNr .."] "..MobName.." - "..L["Q_DROP"])
				end
				APR.QuestList.QuestFrames[LineNr]:Show()
				APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
				local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
				if (APRwidth and APRwidth > 400) then
					APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
				else
					APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
				end
			end
		end
		if (steps["Fillers"] and APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1) then
			IdList = steps["Fillers"]
			for APR_index,APR_value in pairs(IdList) do
				for APR_index2,APR_value2 in pairs(APR_value) do
					if (C_QuestLog.IsQuestFlaggedCompleted(APR_index) == false and not APR1[APR.Realm][APR.Name]["BonusSkips"][APR_index]) then
						if ((UnitLevel("player") ~= 121) or (UnitLevel("player") == 121 and not APR_BonusObj[APR_index])) then
							local qid = APR_index.."-"..APR_index2
							if (APR.ActiveQuests[qid] and APR.ActiveQuests[qid] == "C") then
							elseif (APR.ActiveQuests[qid] and APR.ZoneTransfer == 0) then
								LineNr = LineNr + 1
								local checkpbar = C_QuestLog.GetQuestObjectives(APR_index)
								if (not string.find(APR.ActiveQuests[qid], "(.*)(%d+)(.*)") and checkpbar and checkpbar[tonumber(APR_index2)] and checkpbar[tonumber(APR_index2)]["type"] and checkpbar[tonumber(APR_index2)]["type"] == "progressbar") then
									APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] ["..GetQuestProgressBarPercent(APR_index).."%] "..APR.ActiveQuests[qid])
								else
									APR.QuestList.QuestFrames["FS"..LineNr]:SetText("["..LineNr.."] "..APR.ActiveQuests[qid])
								end
								APR.QuestList.QuestFrames[LineNr]:Show()
								APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
								local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
								if (APRwidth and APRwidth > 400) then
									APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
								else
									APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
								end
								if (steps["Button"] and steps["Button"][qid]) then
									if (not APR.SetButtonVar) then
										APR.SetButtonVar = {}
									end
									APR.SetButtonVar[qid] = LineNr
								end
								if (APR_BonusObj[APR_index]) then
									APR.QuestList.QuestFrames[LineNr]["BQid"] = APR_index
									APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Show()
								else
									APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
								end
							end
						end
					end
				end
			end
		end
		if (APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1) then
			APR.SetButton()
		end
		if (APR.QuestListShown ~= LineNr) then
			if (APR.QuestListShown > LineNr) then
				local FrameHideNr = APR.QuestListShown - LineNr
				local NewLine = LineNr
				local CLi
				for CLi = 1, FrameHideNr do
					NewLine = NewLine + CLi
					if (APR.QuestList.QuestFrames[NewLine]) then
						APR.QuestList.QuestFrames[NewLine]:Hide()
						if (not InCombatLockdown()) then
							APR.QuestList.QuestFrames["FS"..NewLine]["Button"]:Hide()
							APR.QuestList2["BF"..NewLine]:Hide()
						end
						if (APR1["Debug"]) then
							print("Hide:"..NewLine)
						end
					end
				end
			end
		end
		if (StepP == "ZoneDone" or (APR.ActiveMap == 862 and APR1[APR.Realm][APR.Name]["HordeD"] and APR1[APR.Realm][APR.Name]["HordeD"] == 1)) then
			local CLi
			for CLi = 1, 10 do
				APR.QuestList.QuestFrames[CLi]:Hide()
				APR.QuestList.QuestFrames["FS"..CLi]["Button"]:Hide()
				if (not InCombatLockdown()) then
					APR.QuestList2["BF"..CLi]:Hide()
				end
				if (APR1["Debug"]) then
					print("Hide:"..CLi)
				end
			end
			APR.ArrowActive = 0
		end
		APR.QuestListShown = LineNr
		APR.BookingList["SetQPTT"] = 1
		if (APR.ZoneQuestOrder:IsShown() == true) then
			APR.BookingList["UpdateZoneQuestOrderListL"] = 1
		end
	elseif (APRWhereToGo and APR1[APR.Realm][APR.Name]["Settings"]["ShowQList"] == 1 and APR.ZoneTransfer == 0) then
		LineNr = LineNr + 1
		APR.QuestList.QuestFrames["FS"..LineNr]:SetText(TextWithStars("APR: "..L["GO_TO"].." ".. APRWhereToGo, 2, true))
		APR.QuestList.QuestFrames[LineNr]:Show()
		APR.QuestList.QuestFrames["FS"..LineNr]["Button"]:Hide()
		local APRwidth = APR.QuestList.QuestFrames["FS"..LineNr]:GetStringWidth()
		if (APRwidth and APRwidth > 400) then
			APR.QuestList.QuestFrames[LineNr]:SetWidth(APRwidth+10)
		else
			APR.QuestList.QuestFrames[LineNr]:SetWidth(410)
		end
	end
	for CLi = 1, 10 do
		if (CLi > LineNr) then
			if (APR.QuestList.QuestFrames[CLi]:IsShown()) then
				APR.QuestList.QuestFrames[CLi]:Hide()
			end
		end
	end
end
function APR.TrimPlayerServer(CLPName)
	if (string.find(CLPName, "(.*)-(.*)")) then
		local _, _, CL_First, CL_Rest = string.find(CLPName, "(.*)-(.*)")
		return CL_First
	else
		return CLPName
	end
end
function APR.SetButton()
	if (APR1["Debug"]) then
		print("Function: APR.SetButton()")
	end
	if (APR.SettingsOpen == 1) then
		local CLi
		for CLi = 1, 3 do
			local Topz = APR1[APR.Realm][APR.Name]["Settings"]["left"]
			local Topz2 = APR1[APR.Realm][APR.Name]["Settings"]["top"]
			APR.QuestList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT", Topz, Topz2)
			APR.QuestList2["BF"..CLi]:SetPoint("BOTTOMLEFT", APR.QuestList21, "BOTTOMLEFT",0,-((CLi * 38)+CLi))
		end
		return
	end
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	local steps
	if (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
		steps = APR.QuestStepList[APR.ActiveMap][CurStep]
	end
	if (steps and steps["Button"] or (APR.Dinged100 == 1 and APR.Dinged100nr > 0)) then
		if (not InCombatLockdown()) then
			if (APR.SetButtonVar) then
				if (APR1["Debug"]) then
					print("SetButton")
				end
				APR.ButtonList = nil
				APR.ButtonList = {}
				local HideVar = {}
				for APR_index2,APR_value2 in pairs(APR.SetButtonVar) do
					for APR_index,APR_value in pairs(steps["Button"]) do
						if (APR1["Debug"]) then
							print(APR_index)
						end
						if (APR_index2 == APR_index or steps["UseHS"] or steps["UseGarrisonHS"]) then
							local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(APR_value)
							if (itemName and string.sub(itemName, 1, 1) and itemTexture) then
								HideVar[APR_value2] = APR_value2
								APR.ButtonList[APR_index] = APR_value2
								APR.QuestList2["BF"..APR_value2]["APR_Buttonptex"]:SetTexture(itemTexture)
								APR.QuestList2["BF"..APR_value2]["APR_Buttonntex"]:SetTexture(itemTexture)
								APR.QuestList2["BF"..APR_value2]["APR_Button"]:SetNormalTexture(itemTexture)
								APR.QuestList2["BF"..APR_value2]["APR_Button"]:SetText("")
								APR.QuestList2["BF"..APR_value2]["APR_Button"]:SetAttribute("type", "item");
								APR.QuestList2["BF"..APR_value2]["APR_Button"]:SetAttribute("item", "item:"..APR_value);
								APR.QuestList2["BF"..APR_value2]["APR_Button"]:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_CURSOR"); GameTooltip:SetItemByID(APR_value); GameTooltip:Show() end)
								APR.QuestList2["BF"..APR_value2]["APR_Button"]:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
								if (GetItemCount(itemLink) and GetItemCount(itemLink) > 0) then
									APR.QuestList2["BF"..APR_value2]:Show()
								else
									APR.QuestList2["BF"..APR_value2]:Hide()
								end
								local Topz = APR1[APR.Realm][APR.Name]["Settings"]["left"]
								local Topz2 = APR1[APR.Realm][APR.Name]["Settings"]["top"]
								APR.QuestList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT", Topz, Topz2)
								APR.QuestList2["BF"..APR_value2]:SetPoint("BOTTOMLEFT", APR.QuestList21, "BOTTOMLEFT",0,-((APR_value2 * 38)+APR_value2))
								if (not APR.ButtonVisual) then
									APR.ButtonVisual = {}
								end
								local _, spellID = GetItemSpell(APR_value)
								if (spellID) then
									APR.QuestStepList[APR.ActiveMap][CurStep]["ButtonSpellId"] = { [spellID] = APR_index }
								end
								APR.ButtonVisual[APR_value2] = APR_value2
								local isFound, macroSlot = APR.MacroFinder()
								if isFound and macroSlot then
									if (steps and steps["SpecialDubbleMacro"]) then
										if (not APR.DubbleMacro[1]) then
											APR.DubbleMacro[1] = itemName
										elseif (APR.DubbleMacro and APR.DubbleMacro[1] and not APR.DubbleMacro[2]) then
											APR.DubbleMacro[2] = itemName
										end
									else
										APR.DubbleMacro = nil
										APR.DubbleMacro = {}
									end
									APR.MacroUpdater(macroSlot, itemName)
								end
							end
						end
					end
				end
				for i=1, 10 do
					if (not HideVar[i] and APR.SettingsOpen ~= 1) then
						APR.QuestList2["BF"..i]:Hide()
					end
				end
				if (APR.Dinged100 == 1 and APR.Dinged100nr > 0) then
					local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(6948)
					if (itemName and string.sub(itemName, 1, 1) and itemTexture) then
						HideVar[APR.Dinged100nr] = APR.Dinged100nr
						APR.ButtonList[123451234] = APR.Dinged100nr
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Buttonptex"]:SetTexture(itemTexture)
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Buttonntex"]:SetTexture(itemTexture)
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetNormalTexture(itemTexture)
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetText("")
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetAttribute("type", "item");
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetAttribute("item", "item:6948");
						APR.QuestList2["BF"..APR.Dinged100nr]:Show()
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_CURSOR"); GameTooltip:SetItemByID(6948); GameTooltip:Show() end)
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
						local Topz = APR1[APR.Realm][APR.Name]["Settings"]["left"]
						local Topz2 = APR1[APR.Realm][APR.Name]["Settings"]["top"]
						APR.QuestList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT", Topz, Topz2)
						APR.QuestList2["BF"..APR.Dinged100nr]:SetPoint("BOTTOMLEFT", APR.QuestList21, "BOTTOMLEFT",0,-((APR.Dinged100nr * 38)+APR.Dinged100nr))
						if (not APR.ButtonVisual) then
							APR.ButtonVisual = {}
						end
						APR.ButtonVisual[APR.Dinged100nr] = APR.Dinged100nr
						local isFound, macroSlot = APR.MacroFinder()
						if isFound and macroSlot then
							if (steps and steps["SpecialDubbleMacro"]) then
								if (not APR.DubbleMacro[1]) then
									APR.DubbleMacro[1] = itemName
								elseif (APR.DubbleMacro and APR.DubbleMacro[1] and not APR.DubbleMacro[2]) then
									APR.DubbleMacro[2] = itemName
								end
							else
								APR.DubbleMacro = nil
								APR.DubbleMacro = {}
							end
							APR.MacroUpdater(macroSlot, itemName)
						end
					end
				end
			else
				if (steps and not steps["Button"] and APR.SettingsOpen ~= 1) then
					for i=1, 10 do
						APR.QuestList2["BF"..i]:Hide()
					end
				end
				if (APR.Dinged100 == 1 and APR.Dinged100nr > 0) then
					local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(6948)
					if (itemName and string.sub(itemName, 1, 1) and itemTexture) then
						APR.ButtonList[123451234] = APR.Dinged100nr
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Buttonptex"]:SetTexture(itemTexture)
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Buttonntex"]:SetTexture(itemTexture)
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetNormalTexture(itemTexture)
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetText("")
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetAttribute("type", "item");
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetAttribute("item", "item:6948");
						APR.QuestList2["BF"..APR.Dinged100nr]:Show()
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_CURSOR"); GameTooltip:SetItemByID(6948); GameTooltip:Show() end)
						APR.QuestList2["BF"..APR.Dinged100nr]["APR_Button"]:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
						local Topz = APR1[APR.Realm][APR.Name]["Settings"]["left"]
						local Topz2 = APR1[APR.Realm][APR.Name]["Settings"]["top"]
						APR.QuestList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT", Topz, Topz2)
						APR.QuestList2["BF"..APR.Dinged100nr]:SetPoint("BOTTOMLEFT", APR.QuestList21, "BOTTOMLEFT",0,-((APR.Dinged100nr * 38)+APR.Dinged100nr))
						if (not APR.ButtonVisual) then
							APR.ButtonVisual = {}
						end
						APR.ButtonVisual[APR.Dinged100nr] = APR.Dinged100nr
						local isFound, macroSlot = APR.MacroFinder()
						if isFound and macroSlot then
							APR.DubbleMacro = nil
							APR.DubbleMacro = {}
							APR.MacroUpdater(macroSlot, itemName)
						end
					end
				end
			end
			APR.SetButtonVar = nil
		end
	elseif (APR.ButtonVisual and not InCombatLockdown() and APR.SettingsOpen ~= 1) then
		for APR_index,APR_value in pairs(APR.ButtonVisual) do
			APR.QuestList2["BF"..APR_index]:Hide()
		end
		APR.ButtonVisual = nil
	end
	if (not InCombatLockdown()) then
		APR.QuestList20:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR1[APR.Realm][APR.Name]["Settings"]["left"], APR1[APR.Realm][APR.Name]["Settings"]["top"])
	end
end
function APR.CheckCRangeText()
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
	local i = 1
	while i  <= 15 do
		CurStep = CurStep + 1
		steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		if (steps and steps["FlightPath"]) then
			local Derp2 = "["..L["WAYPOINT"].."] - "..L["GET_FLIGHTPATH"]
			return Derp2
		elseif (steps and steps["UseFlightPath"]) then
			if (steps["Boat"]) then
				local Derp2 = "["..L["WAYPOINT"].."] - "..L["USE_BOAT"]
				return Derp2
			else
				local Derp2 = "["..L["WAYPOINT"].."] - "..L["USE_FLIGHTPATH"]
				return Derp2
			end
		elseif (steps and steps["PickUp"]) then
			local Derp2 = "["..L["WAYPOINT"].."] - "..L["ACCEPT_Q"]
			return Derp2
		elseif (steps and steps["Done"]) then
			local Derp2 = "["..L["WAYPOINT"].."] - "..L["TURN_IN_Q"]
			return Derp2
		elseif (steps and steps["Qpart"]) then
			local Derp2 ="["..L["WAYPOINT"].."] - "..L["COMPLETE_Q"]
			return Derp2
		elseif (steps and steps["SetHS"]) then
			local Derp2 = "["..L["WAYPOINT"].."] - "..L["SET_HEARTHSTONE"]
			return Derp2
		elseif (steps and steps["QpartPart"]) then
			local Derp2 = "["..L["WAYPOINT"].."] - "..L["COMPLETE_Q"]
			return Derp2
		end

		i = i + 1
	end
	local Derp2 = L["TRAVEL_TO"]
	return Derp2
end
local function APR_UpdateQuest()
	if (APR1["Debug"]) then
		print("Function: APR_UpdateQuest()")
	end
	local i = 1
	local UpdateQpart = 0
	if (not APRQuestNames) then
		APRQuestNames = {}
	end
	while C_QuestLog.GetTitleForLogIndex(i) do
		local ZeInfoz = C_QuestLog.GetInfo(i)
		if (ZeInfoz) then
			local questID = ZeInfoz["questID"]
			if (questID > 0) then
				local isHeader = ZeInfoz["isHeader"]
				local questTitle = C_QuestLog.GetTitleForQuestID(questID)
				local isComplete = C_QuestLog.IsComplete(questID)
				if (not isHeader) then
					APRQuestNames[questID] = questTitle
					local numObjectives = C_QuestLog.GetNumQuestObjectives(questID)
					if (not APR.ActiveQuests[questID]) then
						if (APR1["Debug"]) then
							print("New Q:"..questID)
						end
					end
					if (not isComplete) then
						isComplete = 0
						APR.ActiveQuests[questID] = "P"
					else
						isComplete = 1
						APR.ActiveQuests[questID] = "C"
					end
					if (numObjectives == 0) then
						if (isComplete == 1) then
							APR.ActiveQuests[questID.."-".."1"] = "C"
						else
							APR.ActiveQuests[questID.."-".."1"] = questTitle
						end
					else
						local ZeObject = C_QuestLog.GetQuestObjectives(questID)
						for h=1, numObjectives do
							local finished = ZeObject[h]["finished"]
							local text = ZeObject[h]["text"]
							if (finished == true) then
								finished = 1
							else
								finished = 0
							end
							if (finished == 1) then
								if (APR.ActiveQuests[questID.."-"..h] and APR.ActiveQuests[questID.."-"..h] ~= "C") then
									if (APR1["Debug"]) then
										print("Update:".."C")
									end
									Update = 1
								end
								APR.ActiveQuests[questID.."-"..h] = "C"
							elseif ((select(2,GetQuestObjectiveInfo(questID, 1, false)) == "progressbar") and text) then
								if (not APR.ProgressbarIgnore[questID.."-"..h]) then
									local APR_Mathstuff = tonumber(GetQuestProgressBarPercent(questID))
									APR_Mathstuff = floor((APR_Mathstuff + 0.5))
									text = "["..APR_Mathstuff.."%] " .. text
									if (not APR.ActiveQuests[questID.."-"..h]) then
										if (APR1["Debug"]) then
											print("New1:"..text)
										end
									end
								end
								if (APR.ActiveQuests[questID.."-"..h] and APR.ActiveQuests[questID.."-"..h] ~= text) then
									if (APR1["Debug"]) then
										print("Update:"..text)
									end
									Update = 1
									APR.ActiveQuests[questID.."-"..h] = text
								else
									APR.ActiveQuests[questID.."-"..h] = text
								end
							else
								if (not APR.ActiveQuests[questID.."-"..h]) then
									--print("New2:"..text)
								end
								if (APR.ActiveQuests[questID.."-"..h] and APR.ActiveQuests[questID.."-"..h] ~= text) then
									if (APR1["Debug"]) then
										print("Update:"..text)
									end
									Update = 1
									APR.ActiveQuests[questID.."-"..h] = text
								else
									APR.ActiveQuests[questID.."-"..h] = text
								end
							end
						end
					end
				end
			end
		else
			break
		end
	i = i + 1
	end
	if (Update == 1) then
		APR.BookingList["PrintQStep"] = 1
	end
end
function APR.MacroFinder()
	if (APR1["Debug"]) then
		print("Function: APR.MacroFinder()")
	end
	local global, character = GetNumMacros()
	for i=1, global do
		local name = GetMacroInfo(i)
		if name == "APR_MACRO" then
			return true, i
		end
	end
	return false, nil
end
function APR.CreateMacro()
	if InCombatLockdown() then
		return
	end
	if (APR1["Debug"]) then
		print("APR.CreateMacro()")
	end
	local global, character = GetNumMacros()
	local isFound, macroSlot = APR.MacroFinder()
	local APR_hasSpace = global < MAX_ACCOUNT_MACROS
	if APR_hasSpace then
		if not isFound and not InCombatLockdown() then
			CreateMacro("APR_MACRO",134400,"/script print('no button yet')")
		end
	else
		print("APR: No global macro space. Please delete a macro to create space.")
	end
end
function APR.MacroUpdater(macroSlot,itemName,APRextra)
	APR.MacroUpdaterVar[1] = macroSlot
	APR.MacroUpdaterVar[2] = itemName
	APR.MacroUpdaterVar[3] = APRextra
end
function APR.MacroUpdater2(macroSlot,itemName,APRextra)
	if (APR1["Debug"]) then
		print("Function: APR.MacroUpdater()")
	end
	local iconQuestionMark = 134400
	if (itemName) then
		if (itemName == 123123123) then
			EditMacro(macroSlot, "APR_MACRO",iconQuestionMark,"#showtooltip\n/click ExtraActionButton1")
		elseif (itemName == 6666666) then
			EditMacro(macroSlot, "APR_MACRO",iconQuestionMark,"#showtooltip\n/cast Summon Steward")
		elseif (APRextra == 65274) then
			EditMacro(macroSlot, "APR_MACRO",iconQuestionMark,"#showtooltip\n/script APR.SaveOldSlot()\n/use "..itemName)
		else
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			if (APR.DubbleMacro and APR.DubbleMacro[1] and APR.DubbleMacro[2] and steps and steps["SpecialDubbleMacro"]) then
				EditMacro(macroSlot, "APR_MACRO",iconQuestionMark,"#showtooltip\n/use "..APR.DubbleMacro[1].."\n/use "..APR.DubbleMacro[2])
			elseif (steps and steps["SpecialMacro"]) then
				EditMacro(macroSlot, "APR_MACRO",iconQuestionMark,"#showtooltip\n/target Serrik\n/use "..itemName)
			elseif (steps and steps["SpecialMacro2"]) then
				EditMacro(macroSlot, "APR_MACRO",iconQuestionMark,"#showtooltip\n/target Hrillik's\n/use "..itemName)
			else
				EditMacro(macroSlot, "APR_MACRO",iconQuestionMark,"#showtooltip\n/use "..itemName)
			end
		end
	else
		EditMacro(macroSlot, "APR_MACRO",iconQuestionMark,"/script print('no button yet')")
	end
end
function APR.GliderFunc()
	if (APR1["Debug"]) then
		print("Function: APR.GliderFunc()")
	end
	if (APR1["GliderName"]) then
		return APR1["GliderName"]
	else
		local itemName
		local DerpGot = 0
		for bag = 0,4 do
			for slot = 1,C_Container.GetContainerNumSlots(bag) do
				local itemID = C_Container.GetContainerItemID(bag, slot)
				if (itemID and itemID == 109076) then
					DerpGot = 1
					local itemLink = C_Container.GetContainerItemLink(bag,slot)
					itemName = GetItemInfo(itemLink)
				end
			end
		end
		if (DerpGot == 1) then
			APR1["GliderName"] = itemName
			return itemName
		else
			return "Goblin Glider Kit"
		end
	end
end
local function APR_QuestStepIds()
	if (APR.QuestStepList[APR.ActiveMap]) then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		if (CurStep and APR.QuestStepList[APR.ActiveMap][CurStep]) then
			local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			if (steps["PickUp"]) then
				return steps["PickUp"], "PickUp"
			elseif (steps["Qpart"]) then
				return steps["Qpart"], "Qpart"
			elseif (steps["Done"]) then
				return steps["Done"], "Done"
			else
				return
			end
		else
			return
		end
	else
		return
	end
end
local function APR_RemoveQuest(questID)
	APR.ActiveQuests[questID] = nil
	for APR_index,APR_value in pairs(APR.ActiveQuests) do
		if (string.find(APR_index, "(.*)-(.*)")) then
			local _, _, APR_First, APR_Rest = string.find(APR_index, "(.*)-(.*)")
			if (tonumber(APR_First) == questID) then
				APR.ActiveQuests[APR_index] = nil
			end
		end
	end
	local IdList, StepP = APR_QuestStepIds()
	if (StepP == "Done") then
		local NrLeft = 0
		for APR_index,APR_value in pairs(IdList) do
			if (C_QuestLog.IsQuestFlaggedCompleted(APR_value) or questID == APR_value) then
			else
				NrLeft = NrLeft + 1
			end
		end
		if (NrLeft == 0) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			if (APR1["Debug"]) then
				print("APR.RemoveQuest:Plus"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
			end
			APR.BookingList["UpdateQuest"] = 1
		end
	end
	APR.BookingList["PrintQStep"] = 1
end
local function APR_AddQuest(questID)
	APR.ActiveQuests[questID] = "P"
	local IdList, StepP = APR_QuestStepIds()
	if (StepP == "PickUp") then
		local NrLeft = 0
		for APR_index,APR_value in pairs(IdList) do
			if (not APRQuestNames[APR_value]) then
				APRQuestNames[APR_value] = 1
			end
			if (not APR.ActiveQuests[APR_value]) then
				NrLeft = NrLeft + 1
			end
		end
		if (NrLeft == 0) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			if (APR1["Debug"]) then
				print("APR.AddQuest:Plus"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
			end
			APR.BookingList["UpdateQuest"] = 1
		end
	end
	APR.BookingList["PrintQStep"] = 1
end
local function APR_UpdateMapId()
	if (APR1["Debug"]) then
		print("Function: APR_UpdateMapId()")
	end
	local OldMap = APR.ActiveMap
	local levelcheck = 0
	local levelcheck80 = 0
	local levelcheck90 = 0
	local levelcheck100 = 0
	local levelcheck110 = 0
	APR.Level = UnitLevel("player")
	APR.ActiveMap = C_Map.GetBestMapForUnit("player")
	local currentMapId, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
	if (Enum and Enum.UIMapType and Enum.UIMapType.Continent and currentMapId) then
		APR.ActiveMap = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent+1, TOP_MOST)
	end
	if (APR.ActiveMap and APR.ActiveMap["mapID"]) then
		APR.ActiveMap = APR.ActiveMap["mapID"]
	else
		APR.ActiveMap = C_Map.GetBestMapForUnit("player")
	end
	APRt_Zone = APR.ActiveMap
	if (APR.ActiveMap == 1671) then
		APR.ActiveMap = 1670
	elseif (APRt_Zone == 578) then
		APRt_Zone = 577
	elseif (APR.ActiveMap == "A543-DesMephisto-Gorgrond" and APRt_Zone == 535) then
		APRt_Zone = 543
	elseif (APRt_Zone == 1726 or APRt_Zone == 1727) then
		APRt_Zone = 1409
	end
	if (APR.ActiveQuests and APR.ActiveQuests[59974] and APR.ActiveMap == 1536) then
		APR.ActiveMap = 1670
	end
	if (OldMap and OldMap ~= APR.ActiveMap) then
		APR.BookingList["PrintQStep"] = 1
	end
	if (APR.ActiveMap == nil) then
		APR.ActiveMap = "NoZone"
	end

	if (APR.Faction == "Alliance") then
		APR.ActiveMap = "A"..APR.ActiveMap
	end
	if (APR.ActiveQuests and APR.ActiveQuests[32675] and APRt_Zone == 84 and APR.Faction == "Alliance") then
		APR.ActiveMap = "A84-LearnFlying"
	end
	if (APR.QuestStepListListingZone) then
		APR.BookingList["GetMeToNextZone"] = 1
	end
	if (APR.ZoneTransfer == 1) then
		APR.BookingList["ZoneTransfer"] = 1
	end
	if (not APR1[APR.Realm][APR.Name][APR.ActiveMap]) then
		APR1[APR.Realm][APR.Name][APR.ActiveMap] = 1
	end
	if (APR.ZoneQuestOrder:IsShown() == true) then
		APR.BookingList["UpdateZoneQuestOrderListL"] = 1
	end
	APR.BookingList["PrintQStep"] = 1
	C_Timer.After(0.1, APR_BookQStep)
end
local function APR_CheckZonePick()
	if (APR.ActiveMap == 862) then
		if (C_QuestLog.IsQuestFlaggedCompleted(50963) == false and (APR.ActiveQuests[47514] or C_QuestLog.IsQuestFlaggedCompleted(47514) == true)) then
			APR.BookingList["UpdateMapId"] = 1
			APR.BookingList["PrintQStep"] = 1
		elseif ((APR.ActiveQuests[47513] or C_QuestLog.IsQuestFlaggedCompleted(47513) == true) and C_QuestLog.IsQuestFlaggedCompleted(47315) == false) then
			APR.BookingList["UpdateMapId"] = 1
			APR.BookingList["PrintQStep"] = 1
		elseif ((APR.ActiveQuests[47512] or C_QuestLog.IsQuestFlaggedCompleted(47512) == true) and C_QuestLog.IsQuestFlaggedCompleted(47105) == false) then
			APR.BookingList["UpdateMapId"] = 1
			APR.BookingList["PrintQStep"] = 1
		elseif (C_QuestLog.IsQuestFlaggedCompleted(47105) == true and C_QuestLog.IsQuestFlaggedCompleted(47315) == true and C_QuestLog.IsQuestFlaggedCompleted(50963) == true) then
			APR.BookingList["UpdateMapId"] = 1
			APR.BookingList["PrintQStep"] = 1
		end
	end
end
local function APR_AcceptQuester()
	AcceptQuest()
end
local function APR_CheckDistance()
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	if (CurStep and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
		if (APR.QuestStepList[APR.ActiveMap][CurStep]["CRange"]) then
			APR.ArrowFrame.Button:Show()
			local plusnr = CurStep
			local Distancenr = 0
			local testad = true
			if (APR.QuestStepList[APR.ActiveMap][CurStep]["NoExtraRange"]) then
				testad = false
			end
			while testad do
				local oldx = APR.QuestStepList[APR.ActiveMap][plusnr]["TT"]["x"]
				local oldy = APR.QuestStepList[APR.ActiveMap][plusnr]["TT"]["y"]
				plusnr = plusnr + 1
				if (APR.QuestStepList[APR.ActiveMap][plusnr] and APR.QuestStepList[APR.ActiveMap][plusnr]["CRange"]) then
					local newx = APR.QuestStepList[APR.ActiveMap][plusnr]["TT"]["x"]
					local newy = APR.QuestStepList[APR.ActiveMap][plusnr]["TT"]["y"]
					local deltaX, deltaY = oldx - newx, newy - oldy
					local distance = (deltaX * deltaX + deltaY * deltaY)^0.5
					Distancenr = Distancenr + distance
				else
					if (APR.QuestStepList[APR.ActiveMap][plusnr] and APR.QuestStepList[APR.ActiveMap][plusnr]["TT"]) then
						local newx = APR.QuestStepList[APR.ActiveMap][plusnr]["TT"]["x"]
						local newy = APR.QuestStepList[APR.ActiveMap][plusnr]["TT"]["y"]
						local deltaX, deltaY = oldx - newx, newy - oldy
						local distance = (deltaX * deltaX + deltaY * deltaY)^0.5
						Distancenr = Distancenr + distance
					end
					return floor(Distancenr + 0.5)
				end
			end
		end
	end
	return 0
end
local function APR_SetQPTT()
	if (APR1["Debug"]) then
		print("Function: APR_SetQPTT()")
	end
	if (APR.SettingsOpen == 1) then
		return
	end
	local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
	if (QNumberLocal ~= CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep] and APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]) then
		APR.ArrowActive = 1
		APR.ArrowActive_X = APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["x"]
		APR.ArrowActive_Y = APR.QuestStepList[APR.ActiveMap][CurStep]["TT"]["y"]
		QNumberLocal = CurStep
		APR["Icons"][1].A = 1
		APR["MapIcons"][1].A = 1
	end
end
local function APR_PosTest()
	local d_y, d_x = UnitPosition("player")
	if (not d_y) then
		APR.ArrowFrame:Hide()
		APR.RemoveIcons()
	elseif (APR1 and APR1[APR.Realm][APR.Name] and APR1[APR.Realm][APR.Name]["Settings"] and APR1[APR.Realm][APR.Name]["Settings"]["ShowArrow"] == 0) then
		APR.ArrowActive = 0
		APR.ArrowFrame:Hide()

		APR.RemoveIcons()
	else
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		if (APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep] and APR.QuestStepList[APR.ActiveMap][CurStep]["AreaTriggerZ"]) then
			x = APR.QuestStepList[APR.ActiveMap][CurStep]["AreaTriggerZ"]["x"]
			y = APR.QuestStepList[APR.ActiveMap][CurStep]["AreaTriggerZ"]["y"]
			local deltaX, deltaY = d_x - x, y - d_y
			local distance = (deltaX * deltaX + deltaY * deltaY)^0.5
			if (APR.QuestStepList[APR.ActiveMap][CurStep]["AreaTriggerZ"]["R"] > distance) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				QNumberLocal = 0
				APR.BookingList["UpdateQuest"] = 1
				APR.BookingList["PrintQStep"] = 1
			end
		end
		if (((APR.ArrowActive == 0) or (APR.ArrowActive_X == 0) or (IsInInstance()) or not APR.QuestStepList) or (APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep] and APR.QuestStepList[APR.ActiveMap][CurStep]["NoArrows"])) then
			if (APR.ArrowFrame) then
				APR.ArrowActive = 0
				APR.ArrowFrame:Hide()
				APR.RemoveIcons()
			end
		else
			APR.ArrowFrame:Show()
			APR.ArrowFrame.Button:Hide()
			local d_y, d_x = UnitPosition("player")
			if (d_x and d_y and GetPlayerFacing()) then
				x = APR.ArrowActive_X
				y = APR.ArrowActive_Y
				local APR_ArrowActive_TrigDistance
				local PI2 = math.pi * 2
				local atan2 = math.atan2
				local twopi = math.pi * 2
				local deltaX, deltaY = d_x - x, y - d_y
				local distance = (deltaX * deltaX + deltaY * deltaY)^0.5
				local angle = atan2(-deltaX, deltaY)
				local player = GetPlayerFacing()
				angle = angle - player
				local perc = math.abs((math.pi - math.abs(angle)) / math.pi)
				if perc > 0.98 then
					APR.ArrowFrame.arrow:SetVertexColor(0,1,0)
				elseif perc > 0.49 then
					APR.ArrowFrame.arrow:SetVertexColor((1-perc)*2,1,0)
				else
					APR.ArrowFrame.arrow:SetVertexColor(1,perc*2,0)
				end
				local cell = floor(angle / twopi * 108 + 0.5) % 108
				local col = cell % 9
				local row = floor(cell / 9)
				APR.ArrowFrame.arrow:SetTexCoord((col * 56) / 512,((col + 1) * 56) / 512,(row * 42) / 512,((row + 1) * 42) / 512)
				APR.ArrowFrame.distance:SetText(floor(distance + APR_CheckDistance()) .. " "..L["YARDS"])
				local APR_ArrowActive_Distance = 0
				if (CurStep and APR.ActiveMap and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
					if (APR.QuestStepList[APR.ActiveMap][CurStep]["Trigger"]) then
						local d_y, d_x = UnitPosition("player")
						local APR_ArrowActive_Trigger_X = APR.QuestStepList[APR.ActiveMap][CurStep]["Trigger"]["x"]
						local APR_ArrowActive_Trigger_Y = APR.QuestStepList[APR.ActiveMap][CurStep]["Trigger"]["y"]
						local deltaX, deltaY = d_x - APR_ArrowActive_Trigger_X, APR_ArrowActive_Trigger_Y - d_y
						APR_ArrowActive_Distance = (deltaX * deltaX + deltaY * deltaY)^0.5
						APR_ArrowActive_TrigDistance = APR.QuestStepList[APR.ActiveMap][CurStep]["Range"]
						if (APR.QuestStepList[APR.ActiveMap][CurStep]["HIDEME"]) then
							APR.ArrowActive = 0
						end
					end
				end
				if (distance < 5 and APR_ArrowActive_Distance == 0) then
					APR.ArrowActive_X = 0
				elseif (APR_ArrowActive_Distance and APR_ArrowActive_TrigDistance and APR_ArrowActive_Distance < APR_ArrowActive_TrigDistance) then
					APR.ArrowActive_X = 0
					if (CurStep and APR.ActiveMap and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
						if (APR.QuestStepList[APR.ActiveMap][CurStep]["CRange"]) then
							APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
							QNumberLocal = 0
							APR.BookingList["UpdateQuest"] = 1
							APR.BookingList["PrintQStep"] = 1
						end
					end
				end
			end
		end
	end
end
local function APR_LoopBookingFunc()
	if (not APR.BookingList) then
		APR.BookingList = {}
	end
	if (APR.BookingList["OpenedSettings"]) then
		APR.BookingList["OpenedSettings"] = nil
		APR.ArrowActive = 1
		APR.ArrowActive_Y, APR.ArrowActive_X = UnitPosition("player")
		QNumberLocal = 0
		APR_SettingsButtons()
		if (APR.ArrowActive_Y) then
			APR.ArrowActive_Y = APR.ArrowActive_Y + 150
			APR.ArrowActive_X = APR.ArrowActive_X + 150
			APR["Icons"][1].A = 1
		end
		APR.BookingList["PrintQStep"] = 1
		if (APR1["Debug"]) then
			print("LoopBookingFunc:OpenedSettings")
		end
	elseif (APR.BookingList["ClosedSettings"]) then
		if (not InCombatLockdown()) then
			APR.BookingList["ClosedSettings"] = nil
			QNumberLocal = 0
			APR.ArrowActive = 0
			APR.RemoveIcons()
			local CLi
			for CLi = 1, 10 do
				APR.QuestList.QuestFrames[CLi]:Hide()
				APR.QuestList.QuestFrames["FS"..CLi]["Button"]:Hide()
				APR.QuestList2["BF"..CLi]:Hide()
			end
			APR.BookingList["UpdateQuest"] = 1
			APR.BookingList["PrintQStep"] = 1
		end
		if (APR1["Debug"]) then
			print("LoopBookingFunc:ClosedSettings")
		end
	elseif (APR.BookingList["GetMeToNextZone"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:GetMeToNextZone:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
		end
		APR.BookingList["GetMeToNextZone"] = nil
		APR.FP.GetMeToNextZone()
	elseif (APR.BookingList["UpdateMapId"]) then
		APR.BookingList["UpdateMapId"] = nil
		APR_UpdateMapId()
		if (APR1["Debug"]) then
			print("LoopBookingFunc:UpdateMapId:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
		end
	elseif (APR.BookingList["AcceptQuest"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:AcceptQuest")
		end
		APR.BookingList["AcceptQuest"] = nil
		C_Timer.After(0.2, APR_AcceptQuester)
	elseif (APR.BookingList["CompleteQuest"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:CompleteQuest")
		end
		APR.BookingList["CompleteQuest"] = nil
		CompleteQuest()
	elseif (APR.BookingList["CreateMacro"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:CreateMacro")
		end
		APR.BookingList["CreateMacro"] = nil
		APR_CreateMacro()
	elseif (APR.BookingList["AddQuest"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:AddQuest:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
		end
		APR_AddQuest(APR.BookingList["AddQuest"])
		APR.BookingList["AddQuest"] = nil
	elseif (APR.BookingList["RemoveQuest"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:RemoveQuest:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
		end
		APR_RemoveQuest(APR.BookingList["RemoveQuest"])
		APR.BookingList["RemoveQuest"] = nil
		APR.BookingList["UpdateMapId"] = 1
		APR.BookingList["PrintQStep"] = 1
	elseif (APR.BookingList["UpdateQuest"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:UpdateQuest:")
		end
		APR.BookingList["UpdateQuest"] = nil
		APR_UpdateQuest()
	elseif (APR.BookingList["PrintQStep"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:PrintQStep:")
		end
		APR.BookingList["PrintQStep"] = nil
		APR_PrintQStep()
	elseif (APR.BookingList["UpdateILVLGear"]) then
		APR.BookingList["UpdateILVLGear"] = nil
		APR_UpdateILVLGear()
		if (APR1["Debug"]) then
			print("LoopBookingFunc:UpdateILVLGear")
		end
	elseif (APR.BookingList["CheckSaveOldSlot"]) then
		APR.BookingList["CheckSaveOldSlot"] = nil
		APR_CheckSaveOldSlot()
	elseif (APR.BookingList["CheckZonePick"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:CheckZonePick:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
		end
		APR.BookingList["CheckZonePick"] = nil
		APR_CheckZonePick()
	elseif (APR.BookingList["ZoneTransfer"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:ZoneTransfer:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
		end
		APR.BookingList["ZoneTransfer"] = nil
		APR.FP.GetMeToNextZone()
	elseif (APR.BookingList["SetQPTT"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:SetQPTT:"..APR1[APR.Realm][APR.Name][APR.ActiveMap])
		end
		APR.BookingList["SetQPTT"] = nil
		APR_SetQPTT()
	elseif (APR.BookingList["TestTaxiFunc"]) then
		if (APR1["Debug"]) then
			print("LoopBookingFunc:TestTaxiFunc")
		end
		APR_AntiTaxiLoop = APR_AntiTaxiLoop + 1
		if (UnitOnTaxi("player")) then
			APR.BookingList["TestTaxiFunc"] = nil
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end
			if (steps and steps["UseFlightPath"]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			end
			APR.BookingList["PrintQStep"] = 1
			APR_AntiTaxiLoop = 0
		elseif (APR_AntiTaxiLoop == 50 or APR_AntiTaxiLoop == 100 or APR_AntiTaxiLoop == 150) then
			APR.BookingList["TestTaxiFunc"] = nil
		end
		if (APR_AntiTaxiLoop > 200) then
			print ("APR: Error - AntiTaxiLoop")
			APR.BookingList["TestTaxiFunc"] = nil
			APR_AntiTaxiLoop = 0
		end
	elseif (APR.BookingList["UpdateZoneQuestOrderListL"]) then
		APR.UpdateZoneQuestOrderList("LoadIn")
		APR.BookingList["UpdateZoneQuestOrderListL"] = nil
	elseif (APR.BookingList["SkipCutscene"]) then
		APR.BookingList["SkipCutscene"] = nil
		--CinematicFrame_CancelCinematic()
		C_Timer.After(1, CinematicFrame_CancelCinematic)
		C_Timer.After(3, CinematicFrame_CancelCinematic)
		if (APR1["Debug"]) then
			print("LoopBookingFunc:SkipCutscene")
		end
	elseif (APR.BookingList["GetMeToNextZone2"]) then
		APR.BookingList["GetMeToNextZone2"] = nil
		APR.FP.GetMeToNextZone2()
	elseif (APR.BookingList["ButtonSpellidchk"]) then
		for APR_index,APR_value in pairs(APR.BookingList["ButtonSpellidchk"]) do
			if (APR_value) then
				local _, duration = GetItemCooldown(APR_value)
				if (duration and duration > 0 and APR_index and APR.QuestList2 and APR.QuestList2["BF"..APR_index] and APR.QuestList2["BF"..APR_index]["APR_ButtonCD"]) then
					APR.QuestList2["BF"..APR_index]["APR_ButtonCD"]:SetCooldown(GetTime(), duration)
				end
			end
		end
		APR.BookingList["ButtonSpellidchk"] = nil
		if (APR1["Debug"]) then
			print("LoopBookingFunc:ButtonSpellidchk")
		end
	end
	if (APR1 and APR1[APR.Realm][APR.Name] and APR1[APR.Realm][APR.Name]["Settings"] and APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"] and APR_ArrowUpdateNr >= APR1[APR.Realm][APR.Name]["Settings"]["ArrowFPS"]) then
		APR_PosTest()
		APR_ArrowUpdateNr = 0
	else
		APR_ArrowUpdateNr = APR_ArrowUpdateNr + 1
	end
end
local function APR_BuyMerchFunc()
	local i
	for i=1,GetMerchantNumItems() do
		local link = GetMerchantItemLink(i)
		if (link) then
			local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(link, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
			if (tonumber(Id) == 160499) then
				BuyMerchantItem(i)
				MerchantFrame:Hide()
				return 1
			end
		end
	end
	return 0
end
local function APR_PopupFunc()
	if (GetNumAutoQuestPopUps() > 0) then
		local questID, popUpType = GetAutoQuestPopUp(1)
		if(popUpType == "OFFER") then
			ShowQuestOffer(1)
			ShowQuestOffer(questID)
		elseif (popUpType == "COMPLETE") then
			ShowQuestOffer(1)
			ShowQuestComplete(questID)
		end
	else
		C_Timer.After(1, APR_PopupFunc)
	end
end
function APR_BookQStep()
	APR.BookingList["UpdateQuest"] = 1
	APR.BookingList["PrintQStep"] = 1
	if (APR1["Debug"]) then
		print("Extra BookQStep")
	end
end
function APR_UpdMapIDz()
	APR.BookingList["UpdateMapId"] = 1
end
function APR_UpdQuestThing()
	local npc_id, name = GetTargetID(), UnitName("target")
	if (npc_id and name) then
		if (APR.ActiveQuests and APR.ActiveQuests["55981-3"] and APR.ActiveQuests["55981-3"] ~= "C" and npc_id == 153580) then
			DoEmote("HUG")
		elseif (APR.ActiveQuests and APR.ActiveQuests["55981-4"] and APR.ActiveQuests["55981-4"] ~= "C" and npc_id == 153580) then
			DoEmote("WAVE")
		elseif (APR.ActiveQuests and APR.ActiveQuests["59978-4"] and APR.ActiveQuests["59978-4"] ~= "C" and npc_id == 153580) then
			DoEmote("WAVE")
		end
	end
	APR.BookingList["UpdateQuest"] = 1
	APR.BookingList["PrintQStep"] = 1
	Updateblock = 0
	if (APR1["Debug"]) then
		print("Extra UpdQuestThing")
	end
end
function APR_UpdatezeMapId()
	APR.BookingList["UpdateMapId"] = 1
end
local function APR_ZoneResetQnumb()
	QNumberLocal = 0
	APR_SetQPTT()
end
function APR.GroupListingFunc(APR_StepStuffs, APR_GListName)
	if (not APR.GroupListSteps[1]) then
		APR.GroupListSteps[1] = {}
		APR.GroupListStepsNr = 1
	end
	APR.GroupListSteps[1]["Step"] = APR_StepStuffs
	APR.GroupListSteps[1]["Name"] = APR.Name
	if (APR_GListName ~= APR.Name) then
		local APRNews = 0
		for APR_index,APR_value in pairs(APR.GroupListSteps) do
			if (APR.GroupListSteps[APR_index]["Name"] == APR_GListName) then
				APR.GroupListSteps[APR_index]["Step"] = APR_StepStuffs
				APRNews = 1
			end
		end
		if (APRNews == 0) then
			APR.GroupListStepsNr = APR.GroupListStepsNr + 1
			APR.GroupListSteps[APR.GroupListStepsNr] = {}
			APR.GroupListSteps[APR.GroupListStepsNr]["Name"] = APR_GListName
			APR.GroupListSteps[APR.GroupListStepsNr]["Step"] = APR_StepStuffs
		end
	end
	APR.RepaintGroups()
end
function APR.RepaintGroups()
	if (IsInInstance()) then
		local CLi
		for CLi = 1, 5 do
			APR.PartyList.PartyFrames[CLi]:Hide()
			APR.PartyList.PartyFrames2[CLi]:Hide()
		end
	else
		if (not APR.GroupListSteps[1]) then
			APR.GroupListSteps[1] = {}
			APR.GroupListStepsNr = 1
		end
		APR.GroupListSteps[1]["Step"] = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		APR.GroupListSteps[1]["Name"] = APR.Name
		local CLi
		for CLi = 1, 5 do
			if (APR.GroupListSteps[CLi]) then
				APR.PartyList.PartyFramesFS1[CLi]:SetText(APR.GroupListSteps[CLi]["Name"])
				APR.PartyList.PartyFramesFS2[CLi]:SetText(APR.GroupListSteps[CLi]["Step"])
				local CLi2
				local Highnr = 0
				for CLi2 = 1, 5 do
					if (APR.GroupListSteps[CLi2] and APR.GroupListSteps[CLi2]["Step"] and APR.GroupListSteps[CLi] and APR.GroupListSteps[CLi]["Step"] and (APR.GroupListSteps[CLi2]["Step"] > APR.GroupListSteps[CLi]["Step"])) then
						Highnr = 1
					end
				end
				if (Highnr == 1) then
					APR.PartyList.PartyFramesFS2[CLi]:SetTextColor(1, 0, 0)
				else
					APR.PartyList.PartyFramesFS2[CLi]:SetTextColor(0, 1, 0)
				end
				APR.PartyList.PartyFrames[CLi]:Show()
				APR.PartyList.PartyFrames2[CLi]:Show()
			else
				APR.PartyList.PartyFrames[CLi]:Hide()
				APR.PartyList.PartyFrames2[CLi]:Hide()
			end
		end
	end
	if (APR1[APR.Realm][APR.Name]["Settings"]["ShowGroup"] == 0) then
		local CLi
		for CLi = 1, 5 do
			APR.PartyList.PartyFrames[CLi]:Hide()
			APR.PartyList.PartyFrames2[CLi]:Hide()
		end
	end
end
function APR.CheckSweatBuffz()
	for i=1,20 do
		local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId = UnitBuff("player", i)
		if (spellId and name) then
			if (spellId == 311103) then
				APR.SweatBuff[1] = 1
				APR.QuestList.SweatOfOurBrowBuffFrame.Traps.texture:SetColorTexture(0.1,0.5,0.1,1)
			end
			if (spellId == 311107) then
				APR.SweatBuff[2] = 1
				APR.QuestList.SweatOfOurBrowBuffFrame.Traps2.texture:SetColorTexture(0.1,0.5,0.1,1)
			end
			if (spellId == 311058) then
				APR.SweatBuff[3] = 1
				APR.QuestList.SweatOfOurBrowBuffFrame.Traps3.texture:SetColorTexture(0.1,0.5,0.1,1)
			end
		end
	end
end
APR.LoopBooking = CreateFrame("frame")
APR.LoopBooking:SetScript("OnUpdate", APR_LoopBookingFunc)

APR_QH_EventFrame = CreateFrame("Frame")
APR_QH_EventFrame:RegisterEvent ("QUEST_REMOVED")
APR_QH_EventFrame:RegisterEvent ("QUEST_ACCEPTED")
APR_QH_EventFrame:RegisterEvent ("UNIT_QUEST_LOG_CHANGED")
APR_QH_EventFrame:RegisterEvent ("ZONE_CHANGED")
APR_QH_EventFrame:RegisterEvent ("ZONE_CHANGED_NEW_AREA")
APR_QH_EventFrame:RegisterEvent ("UPDATE_MOUSEOVER_UNIT")
APR_QH_EventFrame:RegisterEvent ("GOSSIP_SHOW")
APR_QH_EventFrame:RegisterEvent ("GOSSIP_CLOSED")
APR_QH_EventFrame:RegisterEvent ("UI_INFO_MESSAGE")
APR_QH_EventFrame:RegisterEvent ("HEARTHSTONE_BOUND")
APR_QH_EventFrame:RegisterEvent ("UNIT_SPELLCAST_SUCCEEDED")
APR_QH_EventFrame:RegisterEvent ("UNIT_SPELLCAST_START")
APR_QH_EventFrame:RegisterEvent ("QUEST_PROGRESS")
APR_QH_EventFrame:RegisterEvent ("QUEST_DETAIL")
APR_QH_EventFrame:RegisterEvent ("QUEST_COMPLETE")
APR_QH_EventFrame:RegisterEvent ("QUEST_FINISHED")
APR_QH_EventFrame:RegisterEvent ("TAXIMAP_OPENED")
APR_QH_EventFrame:RegisterEvent ("MERCHANT_SHOW")
APR_QH_EventFrame:RegisterEvent ("QUEST_GREETING")
APR_QH_EventFrame:RegisterEvent ("ITEM_PUSH")
APR_QH_EventFrame:RegisterEvent ("QUEST_AUTOCOMPLETE")
APR_QH_EventFrame:RegisterEvent ("QUEST_ACCEPT_CONFIRM")
APR_QH_EventFrame:RegisterEvent ("UNIT_ENTERED_VEHICLE")
APR_QH_EventFrame:RegisterEvent ("QUEST_LOG_UPDATE")
APR_QH_EventFrame:RegisterEvent ("PLAYER_TARGET_CHANGED")
APR_QH_EventFrame:RegisterEvent ("PLAYER_REGEN_ENABLED")
APR_QH_EventFrame:RegisterEvent ("PLAYER_REGEN_DISABLED")
APR_QH_EventFrame:RegisterEvent ("CHAT_MSG_ADDON")
APR_QH_EventFrame:RegisterEvent ("CHAT_MSG_MONSTER_SAY")
APR_QH_EventFrame:RegisterEvent ("CHAT_MSG_COMBAT_XP_GAIN")
APR_QH_EventFrame:RegisterEvent ("LEARNED_SPELL_IN_TAB")
APR_QH_EventFrame:RegisterEvent ("UNIT_AURA")
APR_QH_EventFrame:RegisterEvent ("PLAYER_CHOICE_UPDATE")
APR_QH_EventFrame:RegisterEvent ("REQUEST_CEMETERY_LIST_RESPONSE")
APR_QH_EventFrame:RegisterEvent ("AJ_REFRESH_DISPLAY")
APR_QH_EventFrame:RegisterEvent ("UPDATE_UI_WIDGET")

APR_QH_EventFrame:SetScript("OnEvent", function(self, event, ...)
	if (event=="UPDATE_UI_WIDGET") then
		if (APR.ActiveQuests and APR.ActiveQuests["57713-4"]) then
			APR.BookingList["PrintQStep"] = 1
		end
	end
	if (event=="AJ_REFRESH_DISPLAY") then
	end
	if (event=="REQUEST_CEMETERY_LIST_RESPONSE") then
		APR.BookingList["UpdateMapId"] = 1
		C_Timer.After(1, APR_ZoneResetQnumb)
		C_Timer.After(1, APR_BookQStep)
	end
	if (event=="LEARNED_SPELL_IN_TAB") then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if (steps and steps["SpellInTab"]) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			APR.BookingList["UpdateQuest"] = 1
			APR.BookingList["PrintQStep"] = 1
		end
	end
	if (event=="QUEST_LOG_UPDATE") then
		C_Timer.After(0.1, APR_UpdQuestThing)
	end
	if (event=="UNIT_AURA") then
		local arg1, arg2, arg3, arg4 = ...;
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if (steps and steps["QSpecialz"] and APR.ActiveQuests and APR.ActiveQuests["57657-2"]) then
			APR.BookingList["PrintQStep"] = 1
		end
		if (arg1 == "player" and steps and steps["Debuffcount"]) then
			for i=1,20 do
				local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId = UnitBuff("player", i)
				if (spellId and name and count) then
					if (spellId == 69704 and count == 5) then
						APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
						APR.BookingList["UpdateQuest"] = 1
						APR.BookingList["PrintQStep"] = 1
					end
				end
			end
		end
		if (APR.SweatBuff[1] == 1 or APR.SweatBuff[2] == 1 or APR.SweatBuff[3] == 1) then
			local gotbuff1 = 0
			local gotbuff2 = 0
			local gotbuff3 = 0
			for i=1,20 do
				local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId = UnitBuff("player", i)
				if (spellId and name) then
					if (spellId == 311103) then
						gotbuff1 = 1
					elseif (spellId == 311107) then
						gotbuff2 = 1
					elseif (spellId == 311058) then
						gotbuff3 = 1
					end
				end
			end
			if (APR.SweatBuff[1] == 1) then
				if (gotbuff1 == 0) then
					APR.SweatBuff[1] = 0
					APR.QuestList.SweatOfOurBrowBuffFrame.Traps.texture:SetColorTexture(0.5,0.1,0.1,1)
				end
			end
			if (APR.SweatBuff[2] == 1) then
				if (gotbuff2 == 0) then
					APR.SweatBuff[2] = 0
					APR.QuestList.SweatOfOurBrowBuffFrame.Traps2.texture:SetColorTexture(0.5,0.1,0.1,1)
				end
			end
			if (APR.SweatBuff[3] == 1) then
				if (gotbuff3 == 0) then
					APR.SweatBuff[3] = 0
					APR.QuestList.SweatOfOurBrowBuffFrame.Traps3.texture:SetColorTexture(0.5,0.1,0.1,1)
				end
			end
		end
		if (arg1 == "player" and APR.ActiveQuests and APR.ActiveQuests[57867]) then
			APR.CheckSweatBuffz()
			C_Timer.After(2, APR.CheckSweatBuffz)
		end
	end
	if (event=="PLAYER_TARGET_CHANGED") then
		local npc_id, name = GetTargetID(), UnitName("target")
		if (npc_id and name) then
			if (APR.ActiveQuests and APR.ActiveQuests["55981-3"] and APR.ActiveQuests["55981-3"] ~= "C" and npc_id == 153580) then
				DoEmote("HUG")
			elseif (APR.ActiveQuests and APR.ActiveQuests["55981-4"] and APR.ActiveQuests["55981-4"] ~= "C" and npc_id == 153580) then
				DoEmote("WAVE")
			elseif (APR.ActiveQuests and APR.ActiveQuests["59978-4"] and APR.ActiveQuests["59978-4"] ~= "C" and npc_id == 153580) then
				DoEmote("WAVE")
			end
		end
	end
	if (event=="CHAT_MSG_COMBAT_XP_GAIN") then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if (steps and steps["Treasure"]) then
			APR.BookingList["UpdateQuest"] = 1
			APR.BookingList["PrintQStep"] = 1
			C_Timer.After(2, APR_BookQStep)
			C_Timer.After(4, APR_BookQStep)
		end
	end
	if (event=="UNIT_ENTERED_VEHICLE") then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if (steps and steps["MountVehicle"]) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			APR.BookingList["UpdateQuest"] = 1
			APR.BookingList["PrintQStep"] = 1
		end
	end
	if (event=="PLAYER_REGEN_ENABLED") then
		APR.InCombat = 0
		if (APR.BookUpdAfterCombat == 1) then
			APR.BookingList["PrintQStep"] = 1
		end
	end
	if (event=="PLAYER_REGEN_DISABLED") then
		APR.InCombat = 1
	end
	if (event=="CHAT_MSG_ADDON") then
		local arg1, arg2, arg3, arg4 = ...;
		if (arg1 == "APRChat" and arg3 == "PARTY") then
			APR.GroupListingFunc(tonumber(arg2), APR.TrimPlayerServer(arg4))
		end
	end
	if (event=="PLAYER_CHOICE_UPDATE") then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		local choiceInfo = C_PlayerChoice.GetCurrentPlayerChoiceInfo()
		if (choiceInfo and steps) then
			if (steps["Brewery"] or steps["SparringRing"]) then
				for i, option in ipairs(choiceInfo.options) do
					if (steps["Brewery"] == option.id or steps["SparringRing"] == option.id) then
						C_PlayerChoice.SendPlayerChoiceResponse(option.buttons[1].id)
						APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
						APR.BookingList["UpdateQuest"] = 1
						APR.BookingList["PrintQStep"] = 1
						break
					end
				end
			end
		end
	end
	if (event=="UNIT_ENTERED_VEHICLE") then
		local arg1, arg2, arg3, arg4, arg5 = ...;
		if (arg1 == "player") then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
				if (steps and steps["InVehicle"]) then
					APR.BookingList["PrintQStep"] = 1
				end
			end
		end
	end
	if (event=="QUEST_AUTOCOMPLETE") then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if(APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] == 1 and not IsControlKeyDown()) then
			if (steps and steps["SpecialNoAutoHandin"]) then
			else
				APR_PopupFunc()
			end
		end
	end
	if (event=="QUEST_ACCEPT_CONFIRM") then -- escort quest
		if (APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] == 1 and not IsControlKeyDown()) then
			APR.BookingList["AcceptQuest"] = 1
		end
	end
	if (event=="QUEST_GREETING" or event=="GOSSIP_SHOW") then
		-- Exit function if you press Ctrl key before the
		if IsControlKeyDown() then return end
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if (steps and steps["SpecialNoAutoHandin"]) then
			return
		end
		-- Deny NPC
		if (steps and steps["DenyNPC"]) then
			local npc_id, name = GetTargetID(), UnitName("target")
			if (npc_id and name) then
				if (npc_id == steps["DenyNPC"]) then
					C_GossipInfo.CloseGossip()
					print("APR: "..L["NOT_YET"])
				end
			end
		end
		local npc_id = GetTargetID()
		if (npc_id and (npc_id == 43733) and (npc_id == 45312)) then
			Dismount()
		end
		if (npc_id and ((npc_id == 141584) or (npc_id == 142063) or (npc_id == 25809) or (npc_id == 45400) or (npc_id == 87391))) then
			return
		end
		------------------------------------
		-- GOSSIP
		if(APR1[APR.Realm][APR.Name]["Settings"]["AutoGossip"] == 1) then
			-- GOSSIP HARDCODED
			if (steps and steps["Gossip"]) then
				if (steps["Gossip"] == 27373 or steps["Gossip"] == 34398) then
					SelectGossipOption(1)
					APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
					APR.BookingList["UpdateQuest"] = 1
					APR.BookingList["PrintQStep"] = 1
				end
				if (steps["Gossip"] == 3433398) then
					SelectGossipOption(2)
					APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
					APR.BookingList["UpdateQuest"] = 1
					APR.BookingList["PrintQStep"] = 1
				end
				if (steps["Gossip"] == 28202) then
					APRGOSSIPCOUNT = APRGOSSIPCOUNT + 1
					if (APRGOSSIPCOUNT == 1) then
						SelectGossipOption(1)
					elseif (APRGOSSIPCOUNT == 2) then
						if (APR.Race == "Gnome") then
							SelectGossipOption(1)
						elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
							SelectGossipOption(2)
						elseif (APR.Race == "NightElf") then
							SelectGossipOption(3)
						elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
							SelectGossipOption(4)
						end
					elseif (APRGOSSIPCOUNT == 3) then
						if (APR.Race == "Gnome") then
							SelectGossipOption(3)
						elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
							SelectGossipOption(4)
						elseif (APR.Race == "NightElf") then
							SelectGossipOption(2)
						elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
							SelectGossipOption(1)
						end
					elseif (APRGOSSIPCOUNT == 4) then
						if (APR.Race == "Gnome") then
							SelectGossipOption(4)
						elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
							SelectGossipOption(2)
						elseif (APR.Race == "NightElf") then
							SelectGossipOption(1)
						elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
							SelectGossipOption(3)
						end
					elseif (APRGOSSIPCOUNT == 5) then
						APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
						APR.BookingList["PrintQStep"] = 1
					end
				else
					SelectGossipOption(steps["Gossip"])
					-- Keep this code in case of API update on the gossip selection
					-- local info = C_GossipInfo.GetOptions()
					-- if next(info) then
					-- 	for i, v in pairs(info) do
					-- 		if(v.orderIndex+1 == steps["Gossip"]) then
					-- 			C_GossipInfo.SelectOption(v.gossipOptionID)
					-- 		end
					-- 	end
					-- else
					-- 	SelectGossipOption(steps["Gossip"])
					-- end
					--CHROMIE
					if (steps["ChromiePick"]) then
						local target = GetTargetID()
						if (target == 167032) then
							local extraText = L["SWITCH_TO_CHROMIE"].." ".. C_ChromieTime.GetChromieTimeExpansionOption(steps["ChromiePick"]).name
							APR.QuestList.QuestFrames["FS1"]:SetText(TextWithStars(extraText))
							C_Timer.After(3, function() _G.C_ChromieTime.SelectChromieTimeOption(steps["ChromiePick"]) end)
						end
					end
				end
			end
		end
		--PICKUP / HANDIN
		local availableQuests = C_GossipInfo.GetAvailableQuests()
		local activeQuests = C_GossipInfo.GetActiveQuests()
		if(APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] == 1) then
			if (event == "QUEST_GREETING") then
				for i = 1, GetNumAvailableQuests() do
					local title, isComplete = GetAvailableTitle(i)
					if title and not isComplete then
						return SelectAvailableQuest(i)
					end
				end
	
			elseif availableQuests then
				for titleIndex, questInfo in ipairs(availableQuests) do
					if questInfo.questID then
						return C_GossipInfo.SelectAvailableQuest(questInfo.questID)
					end
				end
			end
		end
		if(APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] == 1) then
			if (event == "QUEST_GREETING") then
				for i = 1, GetNumActiveQuests() do
					local title, isComplete = GetActiveTitle(i)
					if title and isComplete then
						return SelectActiveQuest(i)
					end
				end
			elseif activeQuests then
				for titleIndex, questInfo in ipairs(activeQuests) do
					if questInfo.title and questInfo.isComplete then
						if questInfo.questID then
							return C_GossipInfo.SelectActiveQuest(questInfo.questID)
						end
					end
				end
			end
		end
	end
	if (event=="ITEM_PUSH") then
		local arg1, arg2, arg3, arg4, arg5 = ...;
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		APR.BookingList["PrintQStep"] = 1
		C_Timer.After(1, APR_BookQStep)
	end
	if (event=="MERCHANT_SHOW") then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if (steps and steps["BuyMerchant"]) then
				if (not IsControlKeyDown() and APR_BuyMerchFunc() == 0) then
					C_Timer.After(0.1,print(APR_BuyMerchFunc()))
				end
		end
		if (APR1[APR.Realm][APR.Name]["Settings"]["AutoRepair"] == 1) then
			if (CanMerchantRepair()) then
				local repairAllCost, canRepair = GetRepairAllCost();
				if (canRepair and repairAllCost > 0) then
					local guildRepairedItems = false
					if (IsInGuild() and CanGuildBankRepair()) then
						local amount = GetGuildBankWithdrawMoney()
						local guildBankMoney = GetGuildBankMoney()
						amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)
						if (amount >= repairAllCost) then
							RepairAllItems(true);
							guildRepairedItems = true
							DEFAULT_CHAT_FRAME:AddMessage("APR: Equipment has been repaired by your Guild")
						end
					end
					if (repairAllCost <= GetMoney() and not guildRepairedItems) then
						RepairAllItems(false);
						print("APR: "..L["REPAIR_EQUIPEMENT"].." "..GetCoinTextureString(repairAllCost))
					end
				end
			end
		end
		if (APR1[APR.Realm][APR.Name]["Settings"]["AutoVendor"] == 1) then
			local APRtotal = 0
			for myBags = 0,4 do
				for bagSlots = 1, C_Container.GetContainerNumSlots(myBags) do
					local CurrentItemId = C_Container.GetContainerItemID(myBags, bagSlots)
					if CurrentItemId then
						local _, _, itemQuality, _, _, _, _, _, _, _, sellPrice = GetItemInfo(CurrentItemId)
						local itemInfo = C_Container.GetContainerItemInfo(myBags, bagSlots)
						if itemQuality == 0 and sellPrice > 0 and itemInfo.stackCount > 0 then
							APRtotal = APRtotal + (sellPrice * itemInfo.stackCount)
							C_Container.UseContainerItem(myBags, bagSlots)
						end
					end
				end
			end
			if APRtotal ~= 0 then
				print("APR:"..L["ITEM_SOLD"].." "..GetCoinTextureString(APRtotal))
			end
		end
	end
	if (event=="UI_INFO_MESSAGE") then
		local arg1, arg2, arg3, arg4, arg5 = ...;
		if (arg1 == 280) then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end
			if (steps and steps["GetFP"]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		end
		if (arg1 == 281) then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end
			if (steps and steps["GetFP"]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		end
		if (arg1 == 282) then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end
			if (steps and steps["GetFP"]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		end
		if (arg1 == 283) then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end
			if (steps and steps["GetFP"]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		end
	end
	if (event=="TAXIMAP_OPENED") then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if (steps and steps["GetFP"] and not IsControlKeyDown()) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			APR.BookingList["PrintQStep"] = 1
		end
	end
	if (event=="UNIT_SPELLCAST_SUCCEEDED") then
		local arg1, arg2, arg3, arg4, arg5 = ...;
		if ((arg1 == "player") and (APR_HSSpellIDs[arg3])) then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end
			if (steps and steps["UseHS"]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		end
		if (arg1 == "player") then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.ActiveMap and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end

			if (QuestSpecial57710 == 0 and arg3 == 310061) then
				QuestSpecial57710 = 1
				APR.BookingList["PrintQStep"] = 1
			end

			if (steps and steps["ButtonSpellId"]) then
				for APR_index,APR_value in pairs(steps["ButtonSpellId"]) do
					if (arg3 == APR_index) then
						for APR_index2,APR_value2 in pairs(APR.ButtonList) do
							if (APR_index2 == APR_value) then
								if (not APR.BookingList["ButtonSpellidchk"]) then
									APR.BookingList["ButtonSpellidchk"] = {}
								end
								APR.BookingList["ButtonSpellidchk"][APR_value2] = steps["Button"][APR_value]
							end
						end
					end
				end
			end

			if (steps and steps["SpellTrigger"]) then
				if (arg3 == steps["SpellTrigger"]) then
					APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
					APR.BookingList["PrintQStep"] = 1
				end
			end
		end
	end
	if (event=="UNIT_SPELLCAST_START") then
		local arg1, arg2, arg3, arg4, arg5 = ...;
		if ((arg1 == "player") and (arg3 == 171253)) then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end
			if (steps and steps["UseGarrisonHS"]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			end
		end
		if ((arg1 == "player") and (arg3 == 222695)) then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end
			if (steps and steps["UseDalaHS"]) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			end
		end
	end
	if (event=="HEARTHSTONE_BOUND") then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
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
		APR1[APR.Realm][APR.Name]["HSLoc"] = ZeMap
		if (steps and steps["SetHS"]) then
			APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
			APR.BookingList["PrintQStep"] = 1
		end
	end
	if (event=="QUEST_ACCEPTED") then
		local arg1, arg2, arg3, arg4, arg5 = ...;
		if (APR1["Debug"]) then
			print(L["Q_ACCEPTED"]..": ".. arg1)
		end
		C_Timer.After(0.1, APR_UpdMapIDz)
		C_Timer.After(3, APR_UpdMapIDz)
		if (arg2 and arg2 > 0 and not APR.ActiveQuests[arg2]) then
			APR.BookingList["AddQuest"] = arg2
		end
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		if (CurStep and APR.QuestStepList and APR.ActiveMap and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
			local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			if (steps and steps["ZonePick"]) then
				APR.BookingList["CheckZonePick"] = 1
			end
			if (steps and steps["LoaPick"] and steps["LoaPick"] == 123 and (APR.ActiveQuests[47440] or APR.ActiveQuests[47439])) then
				APR1[APR.Realm][APR.Name][APR.ActiveMap] = APR1[APR.Realm][APR.Name][APR.ActiveMap] + 1
				APR.BookingList["PrintQStep"] = 1
			end
		end
		C_Timer.After(0.1, APR_BookQStep)
		C_Timer.After(3, APR_BookQStep)
	end
	if (event=="QUEST_REMOVED") then
		if (APR1["Debug"]) then
			print(L["Q_REMOVED"])
		end
		local arg1, arg2, arg3, arg4, arg5 = ...;
		APR.BookingList["RemoveQuest"] = arg1
		if (APR.ActiveMap == arg1 and APR1[APR.Realm][APR.Name]["Settings"]["WQs"] == 1) then
			APR.WQFunc()
			APR.BookingList["UpdateMapId"] = 1
			APR1[APR.Realm][APR.Name][arg1] = nil
			APR.RemoveMapIcons()
		end
		APR1[APR.Realm][APR.Name]["QuestCounter2"] = APR1[APR.Realm][APR.Name]["QuestCounter2"] + 1
	end
	if (event=="UNIT_QUEST_LOG_CHANGED") then
		local arg1, arg2, arg3, arg4, arg5 = ...;
		if (arg1 == "player" and Updateblock == 0) then
			Updateblock = 1
			C_Timer.After(1, APR_UpdQuestThing)
		end
	end
	if (event=="ZONE_CHANGED") then
		QNumberLocal = 0
		if (APR.ZoneTransfer == 0) then
			C_Timer.After(2, APR_UpdatezeMapId)
			C_Timer.After(3, APR_ZoneResetQnumb)
			APR.BookingList["UpdateMapId"] = 1
		end
	end
	if (event=="ZONE_CHANGED_NEW_AREA") then
		if (APR.ZoneTransfer == 0) then
			C_Timer.After(2, APR_UpdatezeMapId)
			APR.BookingList["UpdateMapId"] = 1
		end
	end
	if (event=="GOSSIP_CLOSED") then
		APRGOSSIPCOUNT = 0
	end
	if (event=="QUEST_DETAIL") then -- Fired when the player is given a more detailed view of his quest.
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if (steps and steps["DenyNPC"]) then
			local npc_id, name = GetTargetID(), UnitName("target")
			if (npc_id and name) then
					if (npc_id == steps["DenyNPC"]) then
						C_GossipInfo.CloseGossip()
					end
			end
		end
		local target = GetTargetID()
		if (target) then
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			if (CurStep and APR.ActiveMap and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
				local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
				local APRDenied = 0
				if (steps and steps["DenyNPC"]) then
					local name = UnitName("target")
					if (target and name) then
						if (tonumber(target) == steps["DenyNPC"]) then
							APRDenied = 1
						end
					end
				end
				if (APRDenied == 1) then
					CloseQuest()
					print("APR: "..L["NOT_YET"])
				end
			end
		end
		if (GetQuestID() and (APR1[APR.Realm][APR.Name]["Settings"]["AutoAccept"] == 1) and (not IsControlKeyDown())) then
			if (QuestGetAutoAccept()) then
				CloseQuest()
			else
				QuestInfoDescriptionText:SetAlphaGradient(1, 1)
				QuestInfoDescriptionText:SetAlpha(1)
				APR.BookingList["AcceptQuest"] = 1
			end
		end
	end
	if (event=="QUEST_PROGRESS") then
		if (APR1["Debug"]) then
			print("QUEST_PROGRESS")
		end
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if (steps and steps["DenyNPC"]) then
			local npc_id, name = GetTargetID(), UnitName("target")
			if (npc_id and name) then
				if (npc_id == steps["DenyNPC"]) then
					C_GossipInfo.CloseGossip()
				end
			end
		end
		if (APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] == 1 and not IsControlKeyDown()) then
			if (steps and steps["SpecialNoAutoHandin"]) then
				return
			end
			APR.BookingList["CompleteQuest"] = 1
			if (APR1["Debug"]) then
				print("Complete")
			end
		end
	end
	if (event=="QUEST_COMPLETE") then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		local steps
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
			steps = APR.QuestStepList[APR.ActiveMap][CurStep]
		end
		if (steps and steps["DenyNPC"]) then
			local npc_id, name = GetTargetID(), UnitName("target")
			if (npc_id and name) then
				if (npc_id == steps["DenyNPC"]) then
					C_GossipInfo.CloseGossip()
				end
			end
		end
		if (GetNumQuestChoices() > 1) then
			if (APR1[APR.Realm][APR.Name]["Settings"]["AutoHandInChoice"] == 1) then
				local APR_GearIlvlList = {}
				for slots2 = 0,18 do
					local inventoryitemLink = GetInventoryItemLink("player", slots2)
					if (inventoryitemLink) then
						local _, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(inventoryitemLink)
						if (itemQuality == 7) then
							itemLevel = GetDetailedItemLevelInfo(inventoryitemLink)
						end
						if (itemEquipLoc and itemLevel) then
							if (itemEquipLoc == "INVTYPE_WEAPONOFFHAND") then
								itemEquipLoc = "INVTYPE_WEAPON"
							end
							if (itemEquipLoc == "INVTYPE_WEAPONMAINHAND") then
								itemEquipLoc = "INVTYPE_WEAPON"
							end
							if (itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_2HWEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_THROWN" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemEquipLoc == "INVTYPE_RELIC") then
								itemEquipLoc = "INVTYPE_WEAPON"
							end
							if (APR_GearIlvlList[itemEquipLoc]) then
								if (APR_GearIlvlList[itemEquipLoc] > itemLevel) then
									APR_GearIlvlList[itemEquipLoc] = itemLevel
								end
							else
								APR_GearIlvlList[itemEquipLoc] = itemLevel
							end
						end
					end
				end
				local APRTempGearList = {}
				local isweaponz = 0
				local APRColorof = 0
				for h=1, GetNumQuestChoices() do
					local questItemLink = GetQuestItemLink("choice", h)
					if(questItemLink) then
						local _, _, itemQuality, _, _, _, _, _, itemEquipLoc = GetItemInfo(questItemLink)
						local ilvl = GetDetailedItemLevelInfo(questItemLink)
						if (itemEquipLoc == "INVTYPE_WEAPONOFFHAND") then
							itemEquipLoc = "INVTYPE_WEAPON"
						end
						if (itemEquipLoc == "INVTYPE_WEAPONMAINHAND") then
							itemEquipLoc = "INVTYPE_WEAPON"
						end
						if (itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_2HWEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_THROWN" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemEquipLoc == "INVTYPE_RELIC") then
							itemEquipLoc = "INVTYPE_WEAPON"
							print(itemEquipLoc)
						end
						if (APR_GearIlvlList[itemEquipLoc]) then
							if (itemQuality > 2) then
								--APRColorof = itemQuality
							end
							APRTempGearList[h] = ilvl - APR_GearIlvlList[itemEquipLoc]
							print("Qilvl: "..itemQuality.." - "..itemEquipLoc.." - MySpot: "..APR_GearIlvlList[itemEquipLoc])
							if (itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_2HWEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_THROWN" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemEquipLoc == "INVTYPE_RELIC") then
								--isweaponz = 1
							end
						end
					end
				end
				-- temp remove
				isweaponz = 0
				APRColorof = 0
				if (APRColorof > 2) then
				elseif (isweaponz == 1) then
				else
					local PickOne = 0
					local PickOne2 = -99999
					for APR_indexx,APR_valuex in pairs(APRTempGearList) do
						if (APR_valuex > PickOne2) then
							PickOne = APR_indexx
							PickOne2 = APR_valuex
						end
					end
					if (PickOne > 0) then
						GetQuestReward(PickOne)
						--print("picked: "..PickOne)
					end
				end
			end
		else
			local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
			local steps
			if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap]) then
				steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			end
			if (APR1[APR.Realm][APR.Name]["Settings"]["AutoHandIn"] == 1 and not IsControlKeyDown()) then
				if (steps and steps["SpecialNoAutoHandin"]) then
					return
				end
				local npc_id = GetTargetID()
				if (npc_id and ((npc_id == 141584) or (npc_id == 142063) or (npc_id == 45400) or (npc_id == 25809) or (npc_id == 87391))) then
					return
				end
				GetQuestReward(1)
			end
		end
	end
	if (event=="CHAT_MSG_MONSTER_SAY") then
		local arg1, arg2, arg3, arg4 = ...;
		local npc_id, name = GetTargetID(), UnitName("target")
		if (npc_id and name) then
			if (npc_id == 159477) then
				if (APR_GigglingBasket[arg1]) then
					print("APR: "..L["DOING_EMOTE"]..": "..APR_GigglingBasket[arg1])
					DoEmote(APR_GigglingBasket[arg1])
				end
			end
		end
	end
	if (event=="UPDATE_MOUSEOVER_UNIT") then
		local CurStep = APR1[APR.Realm][APR.Name][APR.ActiveMap]
		if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveMap] and APR.QuestStepList[APR.ActiveMap][CurStep]) then
			local steps = APR.QuestStepList[APR.ActiveMap][CurStep]
			if (steps and steps["RaidIcon"]) then
				local guid = UnitGUID("mouseover")
				if (guid) then
					local _, _, _, _, _, npc_id, _ = strsplit("-", guid)
					if (npc_id and tonumber(steps["RaidIcon"]) == tonumber(npc_id)) then
						if (not GetRaidTargetIndex("mouseover")) then
							SetRaidTarget("mouseover",8)
						end
					end
				end
			elseif (steps and steps["DroppableQuest"]) then
				if (UnitGUID("mouseover") and UnitName("mouseover")) then
					local guid, name = UnitGUID("mouseover"), UnitName("mouseover")
					if (guid) then
						local type, _, _, _, _, npc_id, _ = strsplit("-", guid);
						if (type == "Creature" and npc_id and name and steps["DroppableQuest"]["MobId"] == tonumber(npc_id)) then
							if (APR.NPCList and not APR.NPCList[tonumber(npc_id)]) then
								APR.NPCList[tonumber(npc_id)] = name

							end
						end
					end
				end
			end
		end
	end
end)
