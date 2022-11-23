if GetLocale() ~= "ruRU" then return; end
local app = select(2, ...);
local L = app.L;

L = {
	["ACCEPT_Q"] = "Взять задание",
	--[[Translation missing --]]
	["AFK"] = "AFK",
	--[[Translation missing --]]
	["ALL_Q"] = "All quest(s)",
	--[[Translation missing --]]
	["APPRENTICE_RIDING"] = "Apprentice Riding",
	--[[Translation missing --]]
	["ARROW_OPTION"] = "Arrow Options",
	--[[Translation missing --]]
	["ARROW_SCALE"] = "Arrow Scale",
	--[[Translation missing --]]
	["ASSULT_SKIP"] = "The NPC won't be there if an assault is active! If so, skip ahead",
	--[[Translation missing --]]
	["AT_FLIGHTPATH"] = "At the flightpath",
	--[[Translation missing --]]
	["AT_GAZLOWE"] = "At Gazlowe",
	--[[Translation missing --]]
	["AUTO_PATH_HELPER"] = "Auto Path Helper",
	--[[Translation missing --]]
	["AUTO_PICK_REWARD_ITEM"] = "Auto-pick the quest reward by iLvl",
	--[[Translation missing --]]
	["AUTO_REPAIR"] = "Auto-repair",
	--[[Translation missing --]]
	["AUTO_SELECTION_OF_DIALOG"] = "Auto-selection of dialog",
	--[[Translation missing --]]
	["AUTO_VENDOR"] = "Auto-sell gray items",
	--[[Translation missing --]]
	["BANNER_IN_HUTS"] = "The banner is in one of the huts",
	--[[Translation missing --]]
	["BENEATH_HANDIN"] = "Re-enter into the area if you can't turn-in the quest(s)",
	--[[Translation missing --]]
	["BEWARE_TWO_LEVEL"] = "Be aware of the two level \"??'s\"",
	--[[Translation missing --]]
	["BLOODLUST"] = "It's a good time to Bloodlust",
	--[[Translation missing --]]
	["BOTTOM_CAVE"] = "Go to the bottom of the Fissure of Fury",
	--[[Translation missing --]]
	["BREWERY"] = "Brewery",
	--[[Translation missing --]]
	["BUY_BOTTLE_OF_GROG"] = "Buy a Bottle of Grog from Daisy",
	--[[Translation missing --]]
	["BUY_ELYSIAN_THREAD"] = "Buy an Elysian Thread from Caretaker Mirene, close to Klystere",
	--[[Translation missing --]]
	["BUY_MALT_OFF_INNKEEPER"] = "Buy a Rhapsody Malt from Innkeeper Belm",
	--[[Translation missing --]]
	["BY_ROCK"] = "Go by the rock",
	--[[Translation missing --]]
	["CALL_BOARD"] = "Go to the Heroes Call board",
	--[[Translation missing --]]
	["CANNERY_BAG_DISGUISE"] = "Open the Cannary's Cache and use the Clever Plant Disguise Kit and Tagg Mosshide",
	--[[Translation missing --]]
	["CAVES_AROUND_TREE"] = "Go through the caves around the big tree",
	--[[Translation missing --]]
	["CHEST_DOWN_HOLE"] = "Grab the chest down the hole",
	--[[Translation missing --]]
	["CHEST_INSIDE_BUILDING"] = "Grab the chest inside the building",
	--[[Translation missing --]]
	["CHEST_INSIDE_HUT"] = "Grab the chest inside the hut",
	--[[Translation missing --]]
	["CLICK_BUFFS_IN_ZONE"] = "There's several clickable buffs around the zone",
	--[[Translation missing --]]
	["CLICK_ETERNAL_FLAME"] = "Click the Eternal Flame",
	--[[Translation missing --]]
	["CLICK_GONG"] = "Click on the Challenge Gong",
	--[[Translation missing --]]
	["CLICK_INCENSE"] = "Click the incense on ground",
	--[[Translation missing --]]
	["CLICK_ON_NPC"] = "Click on Zen'Kiki so he pulls the Captive Plaguebears",
	--[[Translation missing --]]
	["CLICK_SHACKLE"] = "Click the shackles",
	--[[Translation missing --]]
	["CLICK_THE_VISION"] = "Click the Vision of Sailor's Memory",
	--[[Translation missing --]]
	["CLOSE"] = "Close",
	--[[Translation missing --]]
	["CLOSE_JAINA"] = "Stay close to Jaina's proximity, or she won't move",
	--[[Translation missing --]]
	["CLOSEST_FP"] = "Go to the closest flight point",
	--[[Translation missing --]]
	["COMPLETE_Q"] = "Complete the quest(s)",
	--[[Translation missing --]]
	["CUSTOM_PATH"] = "Custom Path",
	--[[Translation missing --]]
	["DAGGER_DOOR"] = "Get the Shadowmoon Sacrificial Dagger by the door",
	--[[Translation missing --]]
	["DALARAN_CRATER_PORTAL"] = "Use the Dalaran Crater portal",
	["DECLINE_Q"] = "Отклонить квест",
	--[[Translation missing --]]
	["DEMENTORS_DROPS_BOOKS"] = "Shadowborne Dementor's drop Shadow Council Spellbooks",
	--[[Translation missing --]]
	["DESTINATION"] = "Destination",
	--[[Translation missing --]]
	["DETACH_Q_ITEM_BTN"] = "Detatch the Quest Item buttons",
	--[[Translation missing --]]
	["DISABLE_HEIRLOOM_WARNING"] = "Disable Heirloom Warning",
	--[[Translation missing --]]
	["DISABLED_ADDON_LIST"] = "is disabled in your Add-on list",
	--[[Translation missing --]]
	["DO_BONUS_OBJECTIVE"] = "Do the Bonus Objective",
	--[[Translation missing --]]
	["DO_NOT_LOOT_HYDRA"] = "Do not loot the Devouring Hydra's until you have skinned them, or they will dissapear",
	--[[Translation missing --]]
	["DO_NOT_USE_GLIDER"] = "Do not use gliders",
	--[[Translation missing --]]
	["DOING_EMOTE"] = "Do the emote",
	--[[Translation missing --]]
	["DOTS_EXPIRE"] = "Let your debuffs expire before clicking the Shrine of Thunder",
	--[[Translation missing --]]
	["DOWN_ELEVATOR"] = "Go down the elevator",
	--[[Translation missing --]]
	["DOWNSTAIRS"] = "Downstairs",
	--[[Translation missing --]]
	["DROPS_FROM_THISTLEFURS"] = "Troll Charm's drop from Thistlefur Avengers",
	--[[Translation missing --]]
	["EMPTY_GREAT_HALL"] = "Go into the empty lot to the right of the Great Hall",
	--[[Translation missing --]]
	["ENTER_MIRROR"] = "Enter the mirror",
	--[[Translation missing --]]
	["EQUIP_GOGGLES"] = "Equip the Goggles of Gem Hunting and find Elven Gems",
	--[[Translation missing --]]
	["ERROR"] = "Error",
	--[[Translation missing --]]
	["EXPERT_RIDING"] = "Expert Riding",
	--[[Translation missing --]]
	["EXTRA"] = "Extra",
	--[[Translation missing --]]
	["EXTRA_ACTION_BUTTON_NOT_NEEDED"] = "You don't need to use the extra action button",
	--[[Translation missing --]]
	["FALSEBOTTOMED_JAR"] = "Find the False Jar",
	--[[Translation missing --]]
	["FILL_VIAL"] = "Fill the Empty Moonwell Vial",
	--[[Translation missing --]]
	["FIND_CURIER"] = "Find the Forsaken Courier along the road",
	--[[Translation missing --]]
	["FLY_BACK"] = "Fly back",
	--[[Translation missing --]]
	["FLY_BACK_OVER"] = "Fly back over",
	--[[Translation missing --]]
	["FLY_GREAT_SEAL"] = "Fly to the Great Seal",
	--[[Translation missing --]]
	["FLY_NISHA"] = "Fly with Nisha",
	--[[Translation missing --]]
	["FLY_OVER_MOUNTAIN"] = "Fly over the mountain",
	--[[Translation missing --]]
	["FLY_TO"] = "Fly to",
	--[[Translation missing --]]
	["FLYING_AROUND_THE_FOREST"] = "Stinglasher is flying around the forest",
	--[[Translation missing --]]
	["FOLLOW_ZOLANI"] = "Stay close to Zolani's proximity, or she won't move",
	--[[Translation missing --]]
	["FRESHLEAF_BUFF"] = "Freshleaf buff",
	--[[Translation missing --]]
	["GAZLOWE_PORTAL"] = "Wait for Gazlowe to exit the portal to turn-in the quest(s)",
	--[[Translation missing --]]
	["GENERAL_OPTION"] = "General Options",
	--[[Translation missing --]]
	["GET_CROSSBOW"] = "Get Crossbow",
	--[[Translation missing --]]
	["GET_CROWBAR"] = "Get Crowbar from Treasure hunters",
	--[[Translation missing --]]
	["GET_EGG"] = "Get Egg",
	["GET_FLIGHTPATH"] = "Найти пункт полёта",
	--[[Translation missing --]]
	["GET_JOURNEYMAN_RIDING"] = "Get Journeyman Riding",
	--[[Translation missing --]]
	["GET_KEY_CAVE"] = "Get the key in the cave",
	--[[Translation missing --]]
	["GET_TREASURE"] = "Get Treasure",
	--[[Translation missing --]]
	["GET_WEAPONS_CACHE"] = "Get Weapons Cache",
	--[[Translation missing --]]
	["GIVERS_AROUND_AREA"] = "The Quest givers wander around the area",
	--[[Translation missing --]]
	["GO_BLASTEDLANDS"] = "Go To BlastedLands",
	--[[Translation missing --]]
	["GO_CAVE"] = "Go to the Fissure of Fury",
	--[[Translation missing --]]
	["GO_EAST"] = "go East",
	--[[Translation missing --]]
	["GO_INTO_HUT"] = "Go into the Hut",
	--[[Translation missing --]]
	["GO_NORTH"] = "Go North",
	--[[Translation missing --]]
	["GO_NORTH_WEST_GARRISON"] = "Go North West of Garrison",
	--[[Translation missing --]]
	["GO_NORTHWEST"] = "Go Northwest",
	--[[Translation missing --]]
	["GO_PORTAL_ROOM"] = "Go to Portal Room",
	--[[Translation missing --]]
	["GO_SINFALL"] = "Go Into Sinfall",
	--[[Translation missing --]]
	["GO_SOUTH"] = "Go South",
	--[[Translation missing --]]
	["GO_TO"] = "Go To",
	--[[Translation missing --]]
	["GO_WEST"] = "go West",
	--[[Translation missing --]]
	["GOHEAD_NO_RP"] = "You can run ahead if you don't want to RP walk",
	--[[Translation missing --]]
	["GORLASH_PATROLLS"] = "Gorlash patrolls",
	--[[Translation missing --]]
	["GORMLINGS_COLLECTED"] = "gormlings collected",
	--[[Translation missing --]]
	["GOSSAMER_THREAD_BUFF"] = "Gossamer Thread buff",
	--[[Translation missing --]]
	["GRAB_HEAL_DMG_BUFF"] = "Grab the healing haste and damage buffs (Big Circles)",
	--[[Translation missing --]]
	["GRAB_WEAPON_ON_GROUND"] = "Grab your weapon on the ground when you're disarmed!",
	--[[Translation missing --]]
	["GROUP"] = "Group",
	--[[Translation missing --]]
	["GROUP_Q"] = "Ask for group quest",
	--[[Translation missing --]]
	["HALFWAY_UP_CLIFF"] = "Halfway up the cliff wall",
	--[[Translation missing --]]
	["HAMMER_ON_GONGS"] = "Hurl Kyrian Hammer on the gongs!",
	--[[Translation missing --]]
	["HANDIN_NEWS_TALADOR"] = "Handin news from Talador",
	--[[Translation missing --]]
	["HANGING_UNDERNEATH_CLIFF"] = "Hanging underneath cliff",
	--[[Translation missing --]]
	["HARP_TRAP"] = "Suspiciously Untouched Harp",
	--[[Translation missing --]]
	["HE_PATROLS"] = "He Patrols",
	--[[Translation missing --]]
	["HEAD_SOUTHEAST"] = "Head Southeast",
	--[[Translation missing --]]
	["HERB_BAG_DOWNSTAIRS"] = "Herb bag downstairs",
	--[[Translation missing --]]
	["HIDE_RIDING"] = "Hide mount skill learning messages",
	--[[Translation missing --]]
	["HORN_DOWNSTAIRS"] = "Horn downstairs",
	--[[Translation missing --]]
	["HORN_ON_THE_GROUND"] = "When he stops taking damage click on the horn on the ground and use it",
	--[[Translation missing --]]
	["HS_ORIBOS_OR_FLY"] = "Use HS to Oribos or fly there",
	--[[Translation missing --]]
	["IGNORE_MOBS_FAST"] = "Can ignore mobs (if you're fast)",
	--[[Translation missing --]]
	["IN_BOAT"] = "In Boat",
	--[[Translation missing --]]
	["IN_HOUSE"] = "In the house",
	--[[Translation missing --]]
	["IN_HUT"] = "In the Hut",
	--[[Translation missing --]]
	["IN_NEST_MUSTHROOM"] = "In nest ontop of Musthroom",
	--[[Translation missing --]]
	["IN_THE_BASEMENT"] = "In the basement",
	--[[Translation missing --]]
	["IN_THE_LAKE"] = "In the Lake",
	--[[Translation missing --]]
	["IN_TOWER"] = "In the Tower",
	--[[Translation missing --]]
	["IN_WATER"] = "In the water",
	--[[Translation missing --]]
	["IN_WATER_PILLAR"] = "In the water by pillar",
	--[[Translation missing --]]
	["INSIDE"] = "Inside",
	--[[Translation missing --]]
	["INSIDE_BUILDING"] = "Inside the building",
	--[[Translation missing --]]
	["INSIDE_CAVE"] = "Go inside the Fissure of Fury",
	--[[Translation missing --]]
	["INSIDE_HEARTHFIRE_TAVERN"] = "Inside Hearthfire Tavern",
	--[[Translation missing --]]
	["INSIDE_SHACK"] = "Inside the shack",
	--[[Translation missing --]]
	["INTO_MINE"] = "Into the Mine",
	--[[Translation missing --]]
	["ITEM_SOLD"] = "Items were sold for",
	--[[Translation missing --]]
	["JOLS_COMMANDS"] = "Follow Jol's commands",
	--[[Translation missing --]]
	["JOURNEYMAN_RIDING"] = "Journeyman Riding",
	--[[Translation missing --]]
	["JUMP"] = "Jump",
	--[[Translation missing --]]
	["JUMP_OFF"] = "Jump off",
	--[[Translation missing --]]
	["JUMP_OFF_BRIDGE"] = "Jump off bridge",
	--[[Translation missing --]]
	["KAJAMITE"] = "Kaja’mite Chunks 10% dmg buff",
	--[[Translation missing --]]
	["KALIRI_EGG"] = "Kaliri Egg",
	--[[Translation missing --]]
	["KEEP_TRICKSTER_TARGETED"] = "Keep Trickster targeted for auto-Emotes (English Client Only)",
	--[[Translation missing --]]
	["KEYBINDS"] = "Set Keybind",
	--[[Translation missing --]]
	["KILL_BLOOD_ELVES"] = "Kill Blood elves",
	--[[Translation missing --]]
	["KILL_BLOODFANG_STALKER"] = "Killing a Bloodfang Stalker spawns a quest",
	--[[Translation missing --]]
	["KILL_BRISTLELIMBS"] = "Kill Bristlelimbs to summon Chief",
	--[[Translation missing --]]
	["KILL_CENTAURS"] = "Kill centaurs untill Krom'zar appears",
	--[[Translation missing --]]
	["KILL_DARK_IRONS"] = "Kill Dark irons untill boss spawns",
	--[[Translation missing --]]
	["KILL_EXPLOSIVE_HATRED"] = "Kill Explosive Hatreds to disable shield",
	--[[Translation missing --]]
	["KILL_FLEETFOOT"] = "Kill Fleetfoot and loot his tail",
	--[[Translation missing --]]
	["KILL_NAGA"] = "Kill naga",
	--[[Translation missing --]]
	["KILL_NPCS_FASTER_YSERA_DIES"] = "The faster you kill the NPCs the faster Ysera dies",
	--[[Translation missing --]]
	["KILL_PAINMASTER"] = "Kill Painmaster on the wagon",
	--[[Translation missing --]]
	["KILL_SAPPER"] = "Kill Sapper",
	--[[Translation missing --]]
	["KILL_SATYR_FLESH"] = "Kill Satyrs for Satyr Flesh",
	--[[Translation missing --]]
	["KILL_WINTERFALL_MOBS"] = "Kill Winterfall mobs",
	--[[Translation missing --]]
	["KITE_GROMLINGS"] = "Click and kite Gromlings to Wildseed",
	--[[Translation missing --]]
	["LEAVE_GARRISON_SOUTH"] = "Leave Garrison Go South - chest on wall",
	--[[Translation missing --]]
	["LEAVE_TUTORIAL"] = "Leave Tutorial",
	--[[Translation missing --]]
	["LEFT_STAIRS"] = "Left of stairs",
	--[[Translation missing --]]
	["LISTEN"] = "Listen",
	--[[Translation missing --]]
	["LOA_INFO_1"] = "Gonk: 40% move speed and half fall damage for 30sec",
	--[[Translation missing --]]
	["LOA_INFO_2"] = "Pa'Ku: Travel Zuldazar - 6 differents places ",
	--[[Translation missing --]]
	["LOAD"] = "Load",
	--[[Translation missing --]]
	["LOADED"] = "Loaded",
	--[[Translation missing --]]
	["LOCK_ARROW_WINDOW"] = "Lock Arrow Window",
	--[[Translation missing --]]
	["LOCK_QLIST_WINDOW"] = "Lock the QuestList Window",
	--[[Translation missing --]]
	["LOOT_BAG"] = "Loot bag",
	--[[Translation missing --]]
	["LOOT_BELONGINGS"] = "Loot Belongings",
	--[[Translation missing --]]
	["LOOT_COCONUT"] = "Loot Coconut",
	--[[Translation missing --]]
	["LOOT_DAGGER"] = "Loot Dagger",
	--[[Translation missing --]]
	["LOOT_FEMUR"] = "Loot femur underneath big rock",
	--[[Translation missing --]]
	["LOOT_HARPYS_HORN"] = "Loot Horn from Harpys",
	--[[Translation missing --]]
	["LOOT_JAR"] = "Loot Jar",
	--[[Translation missing --]]
	["LOOT_LANTERN"] = "Loot lantern",
	--[[Translation missing --]]
	["LOOT_MELONFRUIT"] = "Loot Melonfruit",
	--[[Translation missing --]]
	["LOOT_PAMELA_HEAD"] = "Loot: Pamela's Doll's Head Left and Right Side and combine them",
	--[[Translation missing --]]
	["LOOT_SATYR_SABER"] = "Loot weaponracks for Satyr Sabers",
	--[[Translation missing --]]
	["LOOT_SKULLS_AND_SUMMON"] = "Loot skulls in room and summon",
	--[[Translation missing --]]
	["LOOT_TUSKS"] = "Loot the Tusks",
	--[[Translation missing --]]
	["LOOT_WILDFIRE_BOTTLE"] = "Loot Bottle of Wildfire from table",
	--[[Translation missing --]]
	["MAP_WALL"] = "From the Map on the wall",
	--[[Translation missing --]]
	["MASTER_RIDING"] = "Master Riding",
	--[[Translation missing --]]
	["MAXOMILLIAN_PRAY"] = "Let Maxomillian pray to Furys",
	--[[Translation missing --]]
	["MINIMAP_BLOB_ALPHA"] = "Set Minimap blobs alpha",
	--[[Translation missing --]]
	["MINING_PICK"] = "Mining Pick",
	--[[Translation missing --]]
	["MISSING_Q"] = "Missing quest(s)",
	--[[Translation missing --]]
	["MOUNT_HORSE_SCARE_SPIDER"] = "Mount a Horse and scare Spiders",
	--[[Translation missing --]]
	["MOUNTING_DESPAWNS_SWARMER"] = "Mounting de-spawns the swarmer",
	--[[Translation missing --]]
	["MOVE_ZONE"] = "Right-click or drag zone to move routes",
	--[[Translation missing --]]
	["NAME"] = "Name",
	--[[Translation missing --]]
	["NEDD_BUFF_DISARM_TRAP"] = "Needed buffs for Disarming Traps",
	--[[Translation missing --]]
	["NEED_CHECK_FPS"] = "Need to check FPs",
	--[[Translation missing --]]
	["NET_PILLAGER"] = "Net a Pillager and drag it to camp",
	--[[Translation missing --]]
	["NO_WAYPOINTS_GARRISON"] = "No waypoints are available while you complete the quest(s)",
	--[[Translation missing --]]
	["NORTH_OUTPOST"] = "North of your Outpost",
	--[[Translation missing --]]
	["NOT_IN_CHROMIE_TIMELINE"] = "You are not in Chromie Time!",
	--[[Translation missing --]]
	["NOT_SKIP_VIDEO"] = "Don't skip video",
	--[[Translation missing --]]
	["NOT_YET"] = "Not Yet!",
	--[[Translation missing --]]
	["NPC_DROP_Q"] = "If the NPC's aren't talking to each other immediately, then abandon the quest and pick it up again",
	--[[Translation missing --]]
	["NPC_TOP_TOWER"] = "NPC is ontop of the tower",
	--[[Translation missing --]]
	["NPC_ZENKIKI"] = "Click on the npc (Zen'Kiki) so he pulls Hawks",
	--[[Translation missing --]]
	["ON_BUILDING"] = "On the Building",
	--[[Translation missing --]]
	["ON_CHAINED_OUTCAST"] = "on the chained outcast",
	--[[Translation missing --]]
	["ON_CLIFF"] = "Ontop Cliff",
	--[[Translation missing --]]
	["ONLY_ONE_WAIT_NPC"] = "Only one can do the quest at a time so you might have to wait for npc to respawn",
	--[[Translation missing --]]
	["OPEN_BAG"] = "Open Bag",
	["OPTIONAL"] = "необязательнo",
	--[[Translation missing --]]
	["OUT_CAVE"] = "Exit cave",
	--[[Translation missing --]]
	["OUT_WEST_GATE"] = "Outside West gate",
	--[[Translation missing --]]
	["PICK_ARSENAL"] = "Pick Arsenal",
	--[[Translation missing --]]
	["PICK_ROUTE"] = "Pick Route",
	--[[Translation missing --]]
	["PICK_UP_LETTER"] = "Pick up letter from mail",
	--[[Translation missing --]]
	["PICK_UP_Q"] = "Pick up the quest(s)",
	--[[Translation missing --]]
	["PICK_ZONE"] = "Pick Zone",
	--[[Translation missing --]]
	["PLACE_LIGHTWELLS"] = "Place Lightwells around the corpsebeasts",
	--[[Translation missing --]]
	["PLACE_MEAT"] = "Open quest bag place meat use pheromones",
	--[[Translation missing --]]
	["PORTAL_WILL_APPEAR"] = "Portal will Appear",
	--[[Translation missing --]]
	["PUS_PET_ABILITY"] = "Use Pet ability (Call to Arms) to Enlist Troops",
	--[[Translation missing --]]
	["Q_ACCEPTED"] = "Quest(s) accepted",
	--[[Translation missing --]]
	["Q_BTN_SCALE"] = "Quest Buttons Scale",
	--[[Translation missing --]]
	["Q_DROP"] = "Quest Drop",
	--[[Translation missing --]]
	["Q_OPTIONS"] = "Quest Options",
	--[[Translation missing --]]
	["Q_PART"] = "Do part of the quest",
	--[[Translation missing --]]
	["Q_REMOVED"] = "Quest removed",
	--[[Translation missing --]]
	["Q_TEXT"] = "Quests Text",
	--[[Translation missing --]]
	["QLIST_OUT_SCREEN"] = "The QuestList is off the screen! Resetting its position...",
	--[[Translation missing --]]
	["QLIST_SCALE"] = "QuestList Scale",
	--[[Translation missing --]]
	["QORDERLIST_SCALE"] = "Quest Order List Scale",
	--[[Translation missing --]]
	["REDUCED_DAMAGE_INFO_1"] = "Wait until his stack of buffs are gone",
	--[[Translation missing --]]
	["REPAIR_EQUIPEMENT"] = "Equipment has been repaired for",
	--[[Translation missing --]]
	["RESET"] = "reset",
	--[[Translation missing --]]
	["RESET_ARROW"] = "Reset Arrow",
	--[[Translation missing --]]
	["RESET_QORDERLIST"] = "Reset QuestOrderList",
	--[[Translation missing --]]
	["RESET_ZONE"] = "Resetting Zone",
	--[[Translation missing --]]
	["RIDE_NISHA"] = "Ride Nisha",
	--[[Translation missing --]]
	["RING_IN_WATER"] = "Small ring In the water",
	--[[Translation missing --]]
	["ROLLBACK"] = "Rollback Quest Step",
	--[[Translation missing --]]
	["ROUTE_COMPLETED"] = "Route Completed",
	--[[Translation missing --]]
	["ROUTE_NOT_FOUND"] = "Route Not found for",
	--[[Translation missing --]]
	["RUN_FOREST_RUN"] = "DON’T WAIT RUN THIS WAY!!!",
	--[[Translation missing --]]
	["RUN_WAYPOINT"] = "Run to the waypoint",
	--[[Translation missing --]]
	["SAIL_TO"] = "Sail to",
	--[[Translation missing --]]
	["SALVAGE_FLOATING_DEBRIS"] = "Salvage floating debris",
	--[[Translation missing --]]
	["SAVAGE_FIGHT_CLUB"] = "Chose The Savage Fight Club",
	--[[Translation missing --]]
	["SCARE_SPIDER_INTO_LUMBERMILL"] = "Scare Spiders into the Lumbermill",
	--[[Translation missing --]]
	["SCENARIO"] = "Do the scenario",
	--[[Translation missing --]]
	["SCOUTING_MAP"] = "From the scouting map",
	--[[Translation missing --]]
	["SEARCH_CENTAUR_TENTS"] = "Search the Centaur tents",
	["SET_HEARTHSTONE"] = "Установить камень возвращения",
	["SETTINGS"] = "Настройки",
	--[[Translation missing --]]
	["SHACKLE_HUT"] = "Click the shackle in the Hut",
	--[[Translation missing --]]
	["SHIMMERDUST_BUFF"] = "Shimmerdust Pile buff",
	--[[Translation missing --]]
	["SHOW_ARROW"] = "Show Arrow",
	--[[Translation missing --]]
	["SHOW_BLOBS_ON_MAP"] = "Show Green blobs on map",
	--[[Translation missing --]]
	["SHOW_BLOBS_ON_MINIMAP"] = "Show Green blobs on minimap",
	--[[Translation missing --]]
	["SHOW_GROUP_PROGRESS"] = "Show Group Progress",
	--[[Translation missing --]]
	["SHOW_QLIST"] = "Show QuestList",
	--[[Translation missing --]]
	["SHOW_QORDERLIST"] = "Show Quest Order List",
	--[[Translation missing --]]
	["SHOW_RIDING"] = "Show mount skill learning messages",
	--[[Translation missing --]]
	["SHOW_STEPS_MAP"] = "Show 10 steps on map",
	--[[Translation missing --]]
	["SHUMMERDUST_BUFF"] = "",
	--[[Translation missing --]]
	["SKIP"] = "Skipping Quest Step",
	--[[Translation missing --]]
	["SKIP_BUTTON"] = "Skip",
	--[[Translation missing --]]
	["SKIP_WAYPOINT"] = "Skip to the waypoint",
	--[[Translation missing --]]
	["SKIP_WAYPOINT_IF_YOU_GLIDE"] = "If you can glide, skip the waypoint and glide to the to quest(s) mobs",
	--[[Translation missing --]]
	["SKIPCAMP"] = "Skipping Camp Step",
	["SKIPPED_CUTSCENE"] = "Пропущенная видеозапись",
	--[[Translation missing --]]
	["SOULWEB_TRAP"] = "Suspiciously Untouched Soulweb",
	--[[Translation missing --]]
	["SPEAK_DEATHLY_USHER"] = "Speak to Deathly Usher",
	--[[Translation missing --]]
	["SPEAR_DOWN_THE_UFO"] = "He is flying use spear to pull him",
	--[[Translation missing --]]
	["SPEEDRUN"] = "Speed Run",
	["SUGGESTED_PLAYERS"] = "Рекомендуемые игроки",
	--[[Translation missing --]]
	["SWITCH_TO_CHROMIE"] = "Go to Chromie and change your timeline",
	--[[Translation missing --]]
	["TAKE_BOAT_TO_SEEKERS_OUTPOST"] = "Take Boat to Seeker's Outpost",
	--[[Translation missing --]]
	["TALK_DREAD_RIDER_CULLEN"] = "Talk to Dread-Rider Cullen",
	--[[Translation missing --]]
	["TALK_EFFIGY"] = "Talk to Effigy",
	--[[Translation missing --]]
	["TALK_ENSIGN_WARD"] = "Talk to Ensign Ward",
	--[[Translation missing --]]
	["TALK_ERUL"] = "Talk to Erul Dawnbrook",
	--[[Translation missing --]]
	["TALK_GRAND_AMIRAL_JES_TERETH"] = "Talk to Grand Admiral Jes-Tereth",
	--[[Translation missing --]]
	["TALK_HALANNIA"] = "Talk to Halannia",
	--[[Translation missing --]]
	["TALK_JHASH"] = "Talk to Jhash for a ride",
	--[[Translation missing --]]
	["TALK_JORNUN"] = "Talk to Jornun to Ride",
	--[[Translation missing --]]
	["TALK_KING_RASTAKHAN"] = "Talk to King Rastakhan",
	--[[Translation missing --]]
	["TALK_NISHA"] = "Talk to Nisha",
	--[[Translation missing --]]
	["TALK_ORKUS"] = "Talk to Orkus after RP and then loot Plans",
	--[[Translation missing --]]
	["TALK_ROKHAN_RIDE_DOWN"] = "Speak to Rokhan for a ride down",
	--[[Translation missing --]]
	["TALK_ROKHAN_RIDE_ZULJAN"] = "Speak to Rokhan for a ride to Zul'jan",
	--[[Translation missing --]]
	["TALK_SASSY"] = "Talk to Sassy Hardwrench for a ride",
	--[[Translation missing --]]
	["TALK_SENTINEL_AVANA"] = "Talk to Sentinel Avana",
	--[[Translation missing --]]
	["TALK_STEWARD"] = "Talk to Steward",
	--[[Translation missing --]]
	["TALK_SWELLTHRASHER"] = "Talk to Swellthrasher",
	--[[Translation missing --]]
	["TALK_THELARON"] = "Talk to Thelaron",
	--[[Translation missing --]]
	["TALK_TO"] = "Talk to",
	--[[Translation missing --]]
	["TALK_TO_NPC_TO_RIDE_BOAT"] = "Talk to NPC to ride boat",
	--[[Translation missing --]]
	["TAVERN"] = "Tavern",
	--[[Translation missing --]]
	["TELEPORT_UP_AND_JUMP"] = "Teleport up and jump in the ring",
	--[[Translation missing --]]
	["TO_GAZLOWE"] = "To Gazlowe",
	--[[Translation missing --]]
	["TO_ROKHAN_GAZLOWE"] = "Turn in to Rokhan and Gazlowe",
	--[[Translation missing --]]
	["TO_WARMASTER_ZOG"] = "To Warmaster Zog inside the Great Hall",
	--[[Translation missing --]]
	["TOP_BIG_MUSHROOM"] = "Ontop the big mushroom",
	--[[Translation missing --]]
	["TOP_BOAT"] = "He is Up top of the boat",
	--[[Translation missing --]]
	["TOP_OF_BOAT"] = "",
	--[[Translation missing --]]
	["TOP_OF_MOUNTAIN"] = "Ontop of the mountain",
	--[[Translation missing --]]
	["TOP_TOWER_OVER_EDGE"] = "Ontop of the tower over the edge",
	--[[Translation missing --]]
	["TOTEM_DAMAGE_BUFF"] = "Stand in totem for dmg buff",
	--[[Translation missing --]]
	["TRAIN_APPRENTICE_RIDING"] = "Train Apprentice Riding",
	--[[Translation missing --]]
	["TRAIN_RIDING"] = "Train Riding",
	["TRAVEL_TO"] = "Отправиться к",
	--[[Translation missing --]]
	["TREASURE_CAVE"] = "Treasure in cave",
	--[[Translation missing --]]
	["TREASURE_NORTH_SHIP"] = "Treasure is North of ship",
	--[[Translation missing --]]
	["TREASURE_TOP_TOWER"] = "Treasure is ontop of the tower",
	["TURN_IN_Q"] = "Выполнить задание",
	--[[Translation missing --]]
	["TURN_ON_WARMODE"] = "Turn on War Mode for extra experience!",
	--[[Translation missing --]]
	["UNDERNEATH"] = "Underneath",
	--[[Translation missing --]]
	["UNDERNEATH_BRIDGE"] = "Underneath bridge",
	--[[Translation missing --]]
	["UNTOUCHED_BASKET"] = "Suspiciously Untouched Basket",
	--[[Translation missing --]]
	["UP_CRANE"] = "Up in the crane",
	--[[Translation missing --]]
	["UP_ELEVATOR"] = "Go up the Elevator",
	--[[Translation missing --]]
	["UP_TOWER"] = "Up the Tower",
	--[[Translation missing --]]
	["UP_TREE"] = "Up in the tree",
	--[[Translation missing --]]
	["UPDATE_ARROW"] = "Update Arrow every",
	--[[Translation missing --]]
	["UPSTAIRS"] = "Go Upstairs",
	--[[Translation missing --]]
	["UPSTAIRS_AND_JUMP"] = "Go upstairs and jump over on the ledge",
	--[[Translation missing --]]
	["UPSTAIRS_BED"] = "Upstairs in bed",
	--[[Translation missing --]]
	["UPTOP"] = "Uptop",
	--[[Translation missing --]]
	["USE_ASTRANAAR_THROWER"] = "Use Astranaar Thrower",
	--[[Translation missing --]]
	["USE_BANNER_ON_CORPSES"] = "Use Banner on Corpses",
	--[[Translation missing --]]
	["USE_BARRELS"] = "Use the barrels to weaken Mucksquint",
	["USE_BOAT"] = "Плыть на корабле в",
	--[[Translation missing --]]
	["USE_BRANCH_ON_GORMS"] = "Use the branch on large hostile Gorms before you kill them",
	--[[Translation missing --]]
	["USE_CANNON"] = "Use cannon to get back",
	--[[Translation missing --]]
	["USE_CART"] = "Use Cart",
	--[[Translation missing --]]
	["USE_CHAIR"] = "Use Chair",
	--[[Translation missing --]]
	["USE_CLAW"] = "Use the Claw",
	--[[Translation missing --]]
	["USE_COVENANT_ABILITY"] = "Use your Soulshape covenant ability",
	--[[Translation missing --]]
	["USE_DALARAN_HEARTHSTONE"] = "Use Dalaran Hearthstone",
	--[[Translation missing --]]
	["USE_DISGUISE"] = "Use Disguise",
	--[[Translation missing --]]
	["USE_ELEVATOR"] = "Use the elevator",
	["USE_FLIGHTPATH"] = "Лететь в",
	--[[Translation missing --]]
	["USE_GARRISON_HEARTHSTONE"] = "Use Garrison Hearthstone",
	--[[Translation missing --]]
	["USE_GATE"] = "Use Gate",
	--[[Translation missing --]]
	["USE_GATE_MALDRAXXUS"] = "Use Gate to Maldraxxus",
	--[[Translation missing --]]
	["USE_GATEWAY"] = "Use the gateway",
	--[[Translation missing --]]
	["USE_GLAIVE_THROWER"] = "Use Glaive Thrower",
	["USE_HEARTHSTONE"] = "Использовать камень возвращения",
	["USE_ITEM"] = "Использовать предмет",
	--[[Translation missing --]]
	["USE_JAVELINS_TO_SPEED"] = "Loot and use Javelins to speed up killing",
	--[[Translation missing --]]
	["USE_MOUNT"] = "Use Mount",
	--[[Translation missing --]]
	["USE_ORB_CANYON_ETTIN"] = "Use Orb on a Canyon Ettin then save Oslow",
	--[[Translation missing --]]
	["USE_ORGRIMMAR_PORTAL"] = "Use Orgrimmar Portal",
	--[[Translation missing --]]
	["USE_PHASEBLOOD_POTION"] = "Use Phaseblood Potion on Mark",
	--[[Translation missing --]]
	["USE_PORTAL"] = "Use Portal",
	--[[Translation missing --]]
	["USE_PORTAL_TO"] = "Use Portal to",
	--[[Translation missing --]]
	["USE_QITEM_DUNGEON"] = "Use quest item inside dungeon",
	--[[Translation missing --]]
	["USE_SOULBREAKER"] = "Use Soulbreaker Traps for extra dmg",
	--[[Translation missing --]]
	["USE_SOULSHAPE"] = "Use Soulshape",
	--[[Translation missing --]]
	["USE_TAVERN_HEARTHSTONE"] = "Use Tavern Hearthstone to camp",
	--[[Translation missing --]]
	["USE_TELEPORT"] = "Use teleport",
	--[[Translation missing --]]
	["USE_WHISTLE_ON_RAMS"] = "use /whistle on rams",
	--[[Translation missing --]]
	["WAIT_FOR_NPC"] = "Wait for NPC to get in place",
	--[[Translation missing --]]
	["WALK_BLADEGUARD_KAJA"] = "Walk with Bladeguard Kaja",
	--[[Translation missing --]]
	["WAYPOINT"] = "Waypoint",
	--[[Translation missing --]]
	["WEAPON_PICK_DOESNT_MATTER"] = "Doesn't matter what weapon you pick",
	--[[Translation missing --]]
	["YARDS"] = "yards",
	--[[Translation missing --]]
	["YES_TO_EXIT_TUTORIAL"] = "Yes To Exit Tutorial",
	--[[Translation missing --]]
	["YOU_CAN_LEARN"] = "You can now learn",
	--[[Translation missing --]]
	["ZONE"] = "Zone",
	--[[Translation missing --]]
	["ZONE_DONE"] = "Zone Done"
}
