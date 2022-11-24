if (APR.Faction == "Horde") then

APR.QuestStepListListingStartAreas = {}
APR.QuestStepListListingStartAreas["Kalimdor"] = {}
APR.QuestStepListListingStartAreas["EasternKingdom"] = {}
if (APR.Race == "Goblin" and APR.Level < 33) then
	APR.QuestStepListListingStartAreas["Kalimdor"] = {
		["194-Kezan"] = "01-30 Goblin Start (Kezan)",
		["174-LostIsles"] = "01-30 Goblin Start (Lost Isles)",
	}
elseif (APR.Race == "Orc") then
	APR.QuestStepListListingStartAreas["Kalimdor"]["1-ValleyOfTrialsOrc"] = "01-10 Orc Start"
elseif (APR.Race == "Scourge") then
	APR.QuestStepListListingStartAreas["EasternKingdom"]["18-TirisfalGladesUndead"] = "01-10 Scourge Start"
elseif (APR.Race == "BloodElf") then
	APR.QuestStepListListingStartAreas["EasternKingdom"]["94-EversongWoodsBloodElf"] = "01-10 Blood Elf Start"
elseif (APR.Class[3] == 1 and APR.Race == "Troll") then
	APR.QuestStepListListingStartAreas["Kalimdor"]["1-EchoIslesTrollWar"] = "01-10 Troll Start"
elseif (APR.Class[3] == 3 and APR.Race == "Troll") then
	APR.QuestStepListListingStartAreas["Kalimdor"]["1-EchoIslesTrollHunter"] = "01-10 Troll Start"
elseif (APR.Class[3] == 4 and APR.Race == "Troll") then
	APR.QuestStepListListingStartAreas["Kalimdor"]["1-EchoIslesTrollRogue"] = "01-10 Troll Start"
elseif (APR.Class[3] == 5 and APR.Race == "Troll") then
	APR.QuestStepListListingStartAreas["Kalimdor"]["1-EchoIslesTrollPriest"] = "01-10 Troll Start"
elseif (APR.Class[3] == 7 and APR.Race == "Troll") then
	APR.QuestStepListListingStartAreas["Kalimdor"]["1-EchoIslesTrollShaman"] = "01-10 Troll Start"
elseif (APR.Class[3] == 8 and APR.Race == "Troll") then
	APR.QuestStepListListingStartAreas["Kalimdor"]["1-EchoIslesTrollMage"] = "01-10 Troll Start"
elseif (APR.Class[3] == 9 and APR.Race == "Troll") then
	APR.QuestStepListListingStartAreas["Kalimdor"]["1-EchoIslesTrollWarlock"] = "01-10 Troll Start"
elseif (APR.Class[3] == 10 and APR.Race == "Troll") then
	APR.QuestStepListListingStartAreas["Kalimdor"]["1-EchoIslesTrollMonk"] = "01-10 Troll Start"
elseif (APR.Class[3] == 11 and APR.Race == "Troll") then
	APR.QuestStepListListingStartAreas["Kalimdor"]["1-EchoIslesTrollDruid"] = "01-10 Troll Start"
end

APR.QuestStepListListingZone = {
	["01-10 Orc Start"] = 1,
	["01-10 Troll Start"] = 1,
	["01-10 Scourge Start"] = 18,
	["01-10 Blood Elf Start"] = 94,
	["01-30 Goblin Start (Kezan)"] = 194,
	["01-30 Goblin Start (Lost Isles)"] = 174,
	["01-30 Death Knight Start"] = 23,
	["01-30 Demon Hunter Start"] = 672,
	["50 The Maw Intro"] = 1648,
	["50-52 Bastion (Full)"] = 1533,
	["56-57 Ardenweald (Full)"] = 1565,
	["57 Oribos (Ardenw-Revend)"] = 1670,
	["57-60 Revendreth (Full)"] = 1525,
	["52-54 Maldraxxus (Full)"] = 1536,
	["52 Oribos (Bastion-Maldraxxus)"] = 1670,
	["56 Oribos (Maldrax-Ardenw)"] = 1670,
	["01-10 Exile's Reach"] = 1409,
	["50-50 Oribos (Start-Bastion)"] = 1670,
	["54 Oribos (Maldraxxus-Maw)"] = 1670,
	["54-55 The Maw"] = 1543,
	["55 Oribos (Maw-Maldraxxus)"] = 1670,
	["55-55 Maldraxxus"] = 1536,
	["01-30 Durotar (Full)"] = 1,
	["10-30 Northern Barrens"] = 10,
	["10-30 Southern Barrens"] = 199,

	["SL-IntroQline"] = 85,
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

	["Test1"] = 1533,
	["(1/7) 10-50 Orgrimmar"] = 85,
	["(2/7) 10-50 Tanaan Jungle"] = 577,
	["(3/7) 10-50 Frostfire Ridge"] = 525,
	["(4/7) 10-50 Gorgrond"] = 543,
	["(5/7) 10-50 Talador"] = 535,
	["(6/7) 10-50 Spires of Arak"] = 542,
	["(7/7) 10-50 Nagrand"] = 550,

	["Legion - Azsuna"] = 630,
	["Legion - Val'Sharah"] = 641,
	["Legion - Stormheim"] = 634,
	
	["10-10 BFA Intro"] = 85,
	["10-10 BFA intro 2"] = 1012,
	["10-10 BFA intro 2"] = 862,
	["10-50 Zuldazar"] = 862,
	["20-50 Nazmir"] = 863,
	["30-30 Naz-end Vol-begin"] = 862,
	["30-50 Vol'dun"] = 864,
	["WIP - Silverpine Forest"] = 21,
	["WIP - Hillsbrad Foothills"] = 25,
	["WIP - Western Plaguelands"] = 22,
	["DEV - HStoryMode Only (Not Enough XP)"] = 1670,
	["WIP - Dragonflight intro"] = 85,
	["WIP - WakingShores"] = 2022,
	["WIP-The Jade Forest"] = 371,
	["WIP-Kun-Lai Summit"] = 379,
	["WIP-Highmountain"] = 650,
}
APR.QuestStepListListing = {}

APR.QuestStepListListing["MISC 1"] = {
	["630-Azsuna"] = "Legion - Azsuna",
	["641-ValSharah"] = "Legion - Val'Sharah",
	["634-Stormheim"] = "Legion - Stormheim",
	["1-Orgrimmar"] = "10-10 BFA Intro",
	["862-Zuldazar"] = "10-10 BFA intro 2",
	["862-Zuldazar-1"] = "10-50 Zuldazar",
	["863-Nazmir"] = "20-50 Nazmir",
	["862-Zuldazar-2"] = "30-30 Naz-end Vol-begin",
	["864-Vol'dun"] = "30-50 Vol'dun",
	
	
}
if (APR.Class[3] == 12) then
APR.QuestStepListListing["MISC 1"]["672-Mardum"] = "01-30 Demon Hunter Start"
end
if (APR.Level < 10) then
	APR.QuestStepListListing["MISC 1"]["1409-Exile's Reach"] = "01-10 Exile's Reach"
end

APR.QuestStepListListing["MISC 2"] = {
	["371-The Jade Forest"] = "WIP-The Jade Forest",
	["379-Kun-Lai Summit"] = "WIP-Kun-Lai Summit",
	["650-Highmountain"] = "WIP-Highmountain",
	
}

APR.QuestStepListListing["Extra"] = {
	["85-DesMephisto-Orgrimmar-p1"] = "(1/7) 10-50 Orgrimmar",
	["577-DesMephisto-TanaanJungle"] = "(2/7) 10-50 Tanaan Jungle",
	["525-DesMephisto-FrostfireRidge-p1"] = "(3/7) 10-50 Frostfire Ridge",
	["543-DesMephisto-Gorgrond-p1"] = "(4/7) 10-50 Gorgrond",
	["535-DesMephisto-Talador-p1"] = "(5/7) 10-50 Talador",
	["542-DesMephisto-SpiresOfArak"] = "(6/7) 10-50 Spires of Arak",
	["550-DesMephisto-Nagrand"] = "(7/7) 10-50 Nagrand",
}

APR.QuestStepListListing["Shadowlands"] = {
	["85-IntroQline"] = "SL-IntroQline",
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
	["Shadowlands-StoryOnly-H"] = "DEV - HStoryMode Only (Not Enough XP)",
}


APR.QuestStepListListing["Kalimdor"] = {
	["1-Durotar"] = "01-30 Durotar (Full)",
	["10-NorthernBarrens"] = "10-30 Northern Barrens",
	["199-SouthernBarrens"] = "10-30 Southern Barrens",
	
	
}

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
	["1533-Bastion-NonStoryMode-1"] = "Test1",
	["630-Azsuna"] = "Legion - Azsuna",
	["641-ValSharah"] = "Legion - Val'Sharah",
	["634-Stormheim"] = "Legion - Stormheim",
	["1-Orgrimmar"] = "10-10 BFA Intro",
	["862-Zuldazar"] = "10-10 BFA intro 2",
	["862-Zuldazar-1"] = "10-50 Zuldazar",
	["863-Nazmir"] = "20-50 Nazmir",
	["862-Zuldazar-2"] = "30-30 Naz-end Vol-begin",
	["864-Vol'dun"] = "30-50 Vol'dun",
	["85-DesMephisto-Orgrimmar-p1"] = "(1/7) 10-50 Orgrimmar",
	["577-DesMephisto-TanaanJungle"] = "(2/7) 10-50 Tanaan Jungle",
	["525-DesMephisto-FrostfireRidge-p1"] = "(3/7) 10-50 Frostfire Ridge",
	["543-DesMephisto-Gorgrond-p1"] = "(4/7) 10-50 Gorgrond",
	["535-DesMephisto-Talador-p1"] = "(5/7) 10-50 Talador",
	["542-DesMephisto-SpiresOfArak"] = "(6/7) 10-50 Spires of Arak",
	["550-DesMephisto-Nagrand"] = "(7/7) 10-50 Nagrand",
	["DF01H-85-Orgrimmar"] = "WIP - Dragonflight intro",
	["DF02H-2022-WakingShores"] = "WIP - WakingShores",
	["371-The Jade Forest"] = "WIP-The Jade Forest",
	["379-Kun-Lai Summit"] = "WIP-Kun-Lai Summit",
	["650-Highmountain"] = "WIP-Highmountain",
	["672-Mardum"] = "01-30 Demon Hunter Start",
	["1409-Exile's Reach"] = "01-10 Exile's Reach",
}

APR.QuestStepListListing["EasternKingdom"] = {
	["DEV-Western Plaguelands"] = "WIP - Western Plaguelands",
	["DEV-Silverpine"] = "WIP - Silverpine Forest",
	["DEV-Hillsbrad"] = "WIP - Hillsbrad Foothills",
	
}

APR.QuestStepListListing["Dragonflight"] = {
	["DF01H-85-Orgrimmar"] = "WIP - Dragonflight intro",
	["DF02H-2022-WakingShores"] = "WIP - WakingShores",
}

APR["BattleForAzeroth"] = {}
APR["BattleForAzeroth"][85] = 1
APR["BattleForAzeroth"][862] = 1
APR["BattleForAzeroth"][863] = 1
APR["BattleForAzeroth"][864] = 1

APR["Kalimdor"] = {}
APR["Kalimdor"][1] = 1
APR["Kalimdor"][10] = 1
APR["Kalimdor"][199] = 1
APR["Kalimdor"][94] = 1

APR["EasternKingdom"] = {}
APR["EasternKingdom"][21] = 1
APR["EasternKingdom"][25] = 1
APR["EasternKingdom"][22] = 1

APR["Shadowlands"] = {}
APR["Shadowlands"][1409] = 1
APR["Shadowlands"][1525] = 1
APR["Shadowlands"][1533] = 1
APR["Shadowlands"][1536] = 1
APR["Shadowlands"][1565] = 1
APR["Shadowlands"][1613] = 1
APR["Shadowlands"][1670] = 1

APR["Legion"] = {}
APR["Legion"][630] = 1
APR["Legion"][634] = 1
APR["Legion"][641] = 1


end
