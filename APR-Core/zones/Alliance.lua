if (APR.Faction == "Alliance") then

APR.QuestStepListListingStartAreas = {}

APR.QuestStepListListingZone = {
	["01-10 Dwarf Start"] = 27,
	["01-10 Human Start"] = 37,
	["01-10 Gnome Start"] = 27,
	["01-10 Draenei Start"] = 97,
	["01-10 Night Elf Start"] = 57,
	["01-10 Worgen Start"] = 179,
	["01-30 Demon Hunter Start"] = 672,
	["01-30 Dun Morogh (Full)"] = 27,
	["01-30 Elwynn Forest (Full)"] = 37,
	["10-30 Loch Modan (Full)"] = 48,
	["10-30 Westfall (Full)"] = 52,
	["10-30 Darkshore (Full)"] = 62,
	["15-30 Ashenvale (Full)"] = 63,
	["01-10 Azuremyst Isle (Full)"] = 97,
	["01-30 Bloodmyst Isle (Full)"] = 106,
	["20-30 Wetlands (Full)"] = 56,
	["25-30 Burning Steppes (Full)"] = 36,
	["20-30 Arathi Highlands (Full)"] = 14,
	["20-30 The Hinterlands (Full)"] = 26,
	["20-30 Western Plaguelands (Full)"] = 22,
	["25-30 Swamp of Sorrows (Full)"] = 51,
	["25-30 Blasted Lands (Full)"] = 17,
	["25-30 Eastern Plaguelands (Full)"] = 23,
	["25-30 Felwood (Full)"] = 77,
	["20-30 Duskwood (Full)"] = 47,
	["15-30 Redridge Mountauns (Full)"] = 49,
	["25-30 Winterspring (Full)"] = 83,
	["20-30 Stonetalon Mountains (Full)"] = 65,
	["20-30 Southern Barrens (Full)"] = 199,
	["20-30 Dustwallow Marsh (Full)"] = 70,
	["20-30 Desolace (Full)"] = 66,
	["20-30 Feralas (Full)"] = 69,
	["25-30 Thousand Needles (Full)"] = 64,
	["25-30 Tanaris (Full)"] = 71,
	["25-30 Un'Goro Crater (Full)"] = 78,
	["25-30 Silithus (Full)"] = 81,
	["01-30 Teldrassil (Full)"] = 57,
	["25-30 Badlands (Full)"] = 15,
	["25-30 Searing Gorge (Full)"] = 32,
	["20-30 Northern Stranglethorn (Full)"] = 224,
	["20-30 Cape of Stranglethorn (F)"] = 224,
	["01-10 Exile's Reach"] = 1409,
	["50 The Maw Intro"] = 1648,
	["50-50 Oribos (Start-Bastion)"] = 1670,
	["54 Oribos (Maldraxxus-Maw)"] = 1670,
	["54-55 The Maw"] = 1543,
	["55 Oribos (Maw-Maldraxxus)"] = 1670,
	["55-55 Maldraxxus"] = 1536,
	["56 Oribos (Maldrax-Ardenw)"] = 1670,
	["57 Oribos (Ardenw-Revend)"] = 1670,
	["SL-IntroQline"] = 84,
	["Z-00-TheMaw-Story"] = 1648,
	["Z-01-Oribos-Story"] = 1670,
	["Z-02-Bastion-Story"] = 1533,
	["Z-03-Oribos-Story"] = 1670,
	["Z-04-Maldraxxus-Story"] = 1536,
	["Z-05-Oribos-Story"] = 1670,
	["Z-06-The Maw-Story"] = 1543,
	["Z-07-Oribos-Story"] = 1670,
	["Z-08-Maldraxxus-Story"] = 1536,
	["Z-09-Oribos-Story"] = 1670,
	["Z-10-Ardenweald-Story"] = 1565,
	["Z-11-Oribos-Story"] = 1670,
	["Z-12-Revendreth-Story"] = 1525,
	["Z-13-The Maw-Story"] = 1543,
	["Z-14-Revendreth-Story"] = 1525,
	["Z-15-Oribos-Story"] = 1670,
	["(1/8) 10-50 Stormwind"] = 84,
	["(2/8) 10-50 Tanaan Jungle"] = 577,
	["(3/8) 10-50 Shadowmoon"] = 539,
	["(4/8) 10-50 Gorgrond"] = 543,
	["(5/8) 10-50 Talador"] = 535,
	["(6/8) 10-50 Shadowmoon"] = 539,
	["(7/8) 10-50 Talador"] = 535,
	["(8/8) 10-50 Spires of Arak"] = 542,
	["Legion - Azsuna"] = 630,
	["Legion - Val'Sharah"] = 641,
	["Legion - Stormheim"] = 634,
	["BFA 10-10 INTRO Test"] = 84,
	["BFA 10-50 Tiragarde Sound Test"] = 895,
	["BFA 30-50 Stormsong Valley Test"] = 942,
	["BFA 20-50 Dustvar Test"] = 896,
	["DEV - AStoryMode Only (Not Enough XP)"] = 1670,
	["DF01 - Dragonflight Stormwind"] = 84,
	["DF02 - Waking Shores - Alliance"] = 2022,
	["DF03 - Waking Shores - Neutral"] = 2022,
	["DF04 - Ohn'Ahran Plains"] = 2023,
	["DF05 - Azure Span"] = 2024,
	["DF06 - Thaldraszus"] = 2025,
}

APR.QuestStepListListing = {}
APR.QuestStepListListing["MISC 1"] = {
	["A630-Azsuna"] = "Legion - Azsuna",
	["A641-ValSharah"] = "Legion - Val'Sharah",
	["A634-Stormheim"] = "Legion - Stormheim",
	["A84-Stormwind"] = "BFA 10-10 INTRO Test",
	["A895-Tiragarde Sound"] = "BFA 10-50 Tiragarde Sound Test",
	["A942-Stormsong Valley"] = "BFA 30-50 Stormsong Valley Test",
	["A896-Dustvar"] = "BFA 20-50 Dustvar Test",

}
if (APR.Class[3] == 12) then
APR.QuestStepListListing["MISC 1"]["672-Mardum"] = "01-30 Demon Hunter Start"
elseif (APR.Level < 2) then
	APR.QuestStepListListing["MISC 1"]["1409-Exile's Reach"] = "01-10 Exile's Reach"
elseif (APR.Faction == "Neutral" and APR.race == 24 and APR.Level == 1) then
	APR.QuestStepListListing["MISC 1"]["378-WanderingIsle"] = "01-30 Pandaren Start"
end
APR.QuestStepListListing["MISC 2"] = {


}
APR.QuestStepListListing["Extra"] = {
	["A84-DesMephisto-Stormwind-War"] = "(1/8) 10-50 Stormwind",
	["A577-DesMephisto-TanaanJungle"] = "(2/8) 10-50 Tanaan Jungle",
	["A539-DesMephisto-Shadowmoon1"] = "(3/8) 10-50 Shadowmoon",
	["A543-DesMephisto-Gorgrond"] = "(4/8) 10-50 Gorgrond",
	["A535-DesMephisto-Talador"] = "(5/8) 10-50 Talador",
	["A539-DesMephisto-Shadowmoon2"] = "(6/8) 10-50 Shadowmoon",
	["A535-DesMephisto-Talador2"] = "(7/8) 10-50 Talador",
	["A542-DesMephisto-SpiresOfArak"] = "(8/8) 10-50 Spires of Arak",

}
APR.QuestStepListListing["Shadowlands"] = {
	["Shadowlands-StoryOnly-A"] = "DEV - AStoryMode Only (Not Enough XP)",
	["84-IntroQline"] = "SL-IntroQline",
	["1648-Z0-TheMaw-Story"] = "Z-00-TheMaw-Story",
	["1670-Z1-Oribos-Story"] = "Z-01-Oribos-Story",
	["1533-Z2-Bastion-Story"] = "Z-02-Bastion-Story",
	["1613-Z3-Oribos-Story"] = "Z-03-Oribos-Story",
	["1536-Z4-Maldraxxus-Story"]= "Z-04-Maldraxxus-Story",
	["1670-Z5-Oribos-Story"] = "Z-05-Oribos-Story",
	["1543-Z6-TheMaw-Story"] = "Z-06-The Maw-Story",
	["1670-Z7-Oribos-Story"] = "Z-07-Oribos-Story",
	["1536-Z8-Maldraxxus-Story"] = "Z-08-Maldraxxus-Story",
	["1670-Z9-Oribos-Story"] = "Z-09-Oribos-Story",
	["1565-Z10-Ardenweald-Story"] = "Z-10-Ardenweald-Story",
	["1671-Z11-Oribos-Story"] = "Z-11-Oribos-Story",
	["1525-Z12-Revendreth-Story"] = "Z-12-Revendreth-Story",
	["1543-Z13-TheMaw-Story"] = "Z-13-The Maw-Story",
	["1525-Z14-Revendreth-Story"] = "Z-14-Revendreth-Story",
	["1671-Z15-Oribos-Story"] = "Z-15-Oribos-Story",
	
}
APR.QuestStepListListing["Kalimdor"] = {
	["A97-AzuremystIsle"] = "01-10 Azuremyst Isle (Full)",
	["A106-BloodmystIsle"] = "01-30 Bloodmyst Isle (Full)",
	["A62-Darkshore"] = "10-30 Darkshore (Full)",
	["A63-Ashenvale"] = "15-30 Ashenvale (Full)",
	["A77-Felwood"] = "25-30 Felwood (Full)",
	["A83-Winterspring"] = "25-30 Winterspring (Full)",
	["A65-StonetalonMountains"] = "20-30 Stonetalon Mountains (Full)",
	["A199-SouthernBarrens"] = "20-30 Southern Barrens (Full)",
	["A70-DustwallowMarsh"] = "20-30 Dustwallow Marsh (Full)",
	["A66-Desolace"] = "20-30 Desolace (Full)",
	["A69-Feralas"] = "20-30 Feralas (Full)",
	["A64-ThousandNeedles"] = "25-30 Thousand Needles (Full)",
	["A71-Tanaris"] = "25-30 Tanaris (Full)",
	["A78-UnGoroCrater"] = "25-30 Un'Goro Crater (Full)",
	["A81-Silithus"] = "25-30 Silithus (Full)",
	["A57-Teldrassil"] = "01-30 Teldrassil (Full)",
	
}
if (APR.Race == "NightElf") then
	APR.QuestStepListListing["Kalimdor"]["A57-ShadowglenNightElf"] = "01-10 Night Elf Start"
elseif (APR.Race == "Draenei") then
	APR.QuestStepListListing["Kalimdor"]["A97-AmmenVale"] = "01-10 Draenei Start"
end
APR.QuestStepListListing["SpeedRun"] = {
	["1648-Z0-TheMaw-Story"] = "Z-00-TheMaw-Story",
	["1670-Z1-Oribos-Story"] = "Z-01-Oribos-Story",
	["1533-Z2-Bastion-Story"] = "Z-02-Bastion-Story",
	["1613-Z3-Oribos-Story"] = "Z-03-Oribos-Story",
	["1536-Z4-Maldraxxus-Story"]= "Z-04-Maldraxxus-Story",
	["1670-Z5-Oribos-Story"] = "Z-05-Oribos-Story",
	["1543-Z6-TheMaw-Story"] = "Z-06-The Maw-Story",
	["1670-Z7-Oribos-Story"] = "Z-07-Oribos-Story",
	["1536-Z8-Maldraxxus-Story"] = "Z-08-Maldraxxus-Story",
	["1670-Z9-Oribos-Story"] = "Z-09-Oribos-Story",
	["1565-Z10-Ardenweald-Story"] = "Z-10-Ardenweald-Story",
	["1671-Z11-Oribos-Story"] = "Z-11-Oribos-Story",
	["1525-Z12-Revendreth-Story"] = "Z-12-Revendreth-Story",
	["1543-Z13-TheMaw-Story"] = "Z-13-The Maw-Story",
	["1525-Z14-Revendreth-Story"] = "Z-14-Revendreth-Story",
	["1671-Z15-Oribos-Story"] = "Z-15-Oribos-Story",
}
APR.QuestStepListListing["EasternKingdom"] = {
	["A27-Kharanos"] = "01-30 Dun Morogh (Full)",
	["A48-LochModan"] = "10-30 Loch Modan (Full)",
	["A37-ElwynnForest"] = "01-30 Elwynn Forest (Full)",
	["A52-Westfall"] = "10-30 Westfall (Full)",
	["A51-SwampofSorrows"] = "25-30 Swamp of Sorrows (Full)",
	["A17-BlastedLands"] = "25-30 Blasted Lands (Full)",
	["A56-Wetlands"] = "20-30 Wetlands (Full)",
	["A36-BurningSteppes"] = "25-30 Burning Steppes (Full)",
	["A14-ArathiHighlands"] = "20-30 Arathi Highlands (Full)",
	["A26-TheHinterlands"] = "20-30 The Hinterlands (Full)",
	["A22-WesternPlaguelands"] = "20-30 Western Plaguelands (Full)",
	["A23-EasternPlaguelands"] = "25-30 Eastern Plaguelands (Full)",
	["A47-Duskwood"] = "20-30 Duskwood (Full)",
	["A49-RedridgeMountauns"] = "15-30 Redridge Mountauns (Full)",
	["A15-Badlands"] = "25-30 Badlands (Full)",
	["A32-SearingGorge"] = "25-30 Searing Gorge (Full)",
	["A224-NorthernStranglethorn"] = "20-30 Northern Stranglethorn (Full)",
	["A224-TheCapeofStranglethorn"] = "20-30 Cape of Stranglethorn (F)",
		
}
if (APR.Race == "Dwarf") then
	APR.QuestStepListListing["EasternKingdom"]["A27-ColdridgeValleyDwarf"] = "01-10 Dwarf Start" 
elseif (APR.Race == "Human") then
	APR.QuestStepListListing["EasternKingdom"]["A37-NorthshireHuman"] = "01-10 Human Start"
elseif (APR.Race == "Gnome") then
	APR.QuestStepListListing["EasternKingdom"]["A27-NewTinkertown"] = "01-10 Gnome Start"
elseif (APR.Race == "Worgen") then
	APR.QuestStepListListing["EasternKingdom"]["A179-Gilneas"] = "01-10 Worgen Start"
end
APR.QuestStepListListing["Dragonflight"] = {

	["DF01A-84-Stormwind"] = "DF01 - Dragonflight Stormwind",
	["DF03A-2022-WakingShores"] = "DF02 - Waking Shores - Alliance",
	["DF03N-2022-WakingShores"] = "DF03 - Waking Shores - Neutral",
	["DF04-2023-OhnahranPlains"] = "DF04 - Ohn'Ahran Plains",
	["DF05-2024-AzureSpan"] = "DF05 - Azure Span",
	["DF06A-2025-Thaldraszus"] = "DF06 - Thaldraszus",
	
}

APR["EasternKingdom"] = {}
APR["EasternKingdom"][14] = 1
APR["EasternKingdom"][15] = 1
APR["EasternKingdom"][17] = 1
APR["EasternKingdom"][22] = 1
APR["EasternKingdom"][23] = 1
APR["EasternKingdom"][26] = 1
APR["EasternKingdom"][27] = 1
APR["EasternKingdom"][32] = 1
APR["EasternKingdom"][36] = 1
APR["EasternKingdom"][37] = 1
APR["EasternKingdom"][47] = 1
APR["EasternKingdom"][48] = 1
APR["EasternKingdom"][49] = 1
APR["EasternKingdom"][51] = 1
APR["EasternKingdom"][52] = 1
APR["EasternKingdom"][56] = 1
APR["EasternKingdom"][179] = 1
APR["EasternKingdom"][224] = 1

APR["Shadowlands"] = {}
APR["Shadowlands"][1648] = 1
APR["Shadowlands"][1409] = 1
APR["Shadowlands"][1525] = 1
APR["Shadowlands"][1533] = 1
APR["Shadowlands"][1536] = 1
APR["Shadowlands"][1565] = 1
APR["Shadowlands"][1613] = 1
APR["Shadowlands"][1670] = 1
APR["Shadowlands"][1728] = 1

APR["Legion"] = {}
APR["Legion"][630] = 1
APR["Legion"][634] = 1
APR["Legion"][641] = 1

APR["Kalimdor"] = {}
APR["Kalimdor"][57] = 1
APR["Kalimdor"][97] = 1
APR["Kalimdor"][672] = 1
APR["Kalimdor"][106] = 1
APR["Kalimdor"][62] = 1
APR["Kalimdor"][63] = 1
APR["Kalimdor"][77] = 1
APR["Kalimdor"][83] = 1
APR["Kalimdor"][65] = 1
APR["Kalimdor"][199] = 1
APR["Kalimdor"][70] = 1
APR["Kalimdor"][66] = 1
APR["Kalimdor"][69] = 1
APR["Kalimdor"][64] = 1
APR["Kalimdor"][71] = 1
APR["Kalimdor"][78] = 1
APR["Kalimdor"][81] = 1


APR["Dragonflight"] = {}
APR["Dragonflight"][2109] = 1
APR["Dragonflight"][2022] = 1
APR["Dragonflight"][2023] = 1
APR["Dragonflight"][2024] = 1
APR["Dragonflight"][2025] = 1
end
