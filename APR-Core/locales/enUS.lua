local name, app = ...;

L = {
	["ACCEPT_Q"] = "Accept the quest(s)",
	["AFK"] = "AFK",
	["ALL_Q"] = "All quest(s)",
	["APPRENTICE_RIDING"] = "Apprentice Riding",
	["AROUND_COOKPOT"] = "Pick-up each quest around the nearby cooking pot",
	["ARROW_OPTION"] = "Arrow Options",
	["ARROW_SCALE"] = "Arrow Scale",
	["ASSULT_SKIP"] = "The NPC won't be there if an assault is active! If so, skip ahead",
	["AT_FLIGHTPATH"] = "At the flightpath",
	["AT_GAZLOWE"] = "At Gazlowe",
	["AUTO_PATH_HELPER"] = "Auto Path Helper",
	["AUTO_PICK_REWARD_ITEM"] = "Auto-pick the quest reward by iLvl",
	["AUTO_REPAIR"] = "Auto-repair",
	["AUTO_SELECTION_OF_DIALOG"] = "Auto-selection of dialog",
	["AUTO_VENDOR"] = "Auto-sell gray items",
	["BANNER_IN_HUTS"] = "The banner is in one of the huts",
	["BENEATH_HANDIN"] = "Re-enter into the area if you can't turn-in the quest(s)",
	["BEWARE_TWO_LEVEL"] = "Be aware of the two level \"??'s\"",
	["BLOODLUST"] = "It's a good time to Bloodlust",
	["BOTTOM_CAVE"] = "Go to the bottom of the Fissure of Fury",
	["BREWERY"] = "Brewery",
	["BUY_BOTTLE_OF_GROG"] = "Buy a Bottle of Grog from Daisy",
	["BUY_ELYSIAN_THREAD"] = "Buy an Elysian Thread from Caretaker Mirene, close to Klystere",
	["BUY_MALT_OFF_INNKEEPER"] = "Buy a Rhapsody Malt from Innkeeper Belm",
	["BY_ROCK"] = "Go by the rock",
	["CALL_BOARD"] = "Go to the Heroes Call board",
	["CANNERY_BAG_DISGUISE"] = "Open the Cannary's Cache and use the Clever Plant Disguise Kit and Tagg Mosshide",
	["CAVES_AROUND_TREE"] = "Go through the caves around the big tree",
	["CHEST_DOWN_HOLE"] = "Grab the chest down the hole",
	["CHEST_INSIDE_BUILDING"] = "Grab the chest inside the building",
	["CHEST_INSIDE_HUT"] = "Grab the chest inside the hut",
	["CLICK_BUFFS_IN_ZONE"] = "There's several clickable buffs around the zone",
	["CLICK_ETERNAL_FLAME"] = "Click the Eternal Flame",
	["CLICK_GONG"] = "Click on the Challenge Gong",
	["CLICK_INCENSE"] = "Click the incense on ground",
	["CLICK_ON_NPC"] = "Click on Zen'Kiki so he pulls the Captive Plaguebears",
	["CLICK_SHACKLE"] = "Click the shackles",
	["CLICK_THE_VISION"] = "Click the Vision of Sailor's Memory",
	["CLOSE"] = "Close",
	["CLOSE_JAINA"] = "Stay close to Jaina's proximity, or she won't move",
	["CLOSEST_FP"] = "Go to the closest flight point",
	["COMPLETE_Q"] = "Complete the quest(s)",
	["CUSTOM_PATH"] = "Custom Path",
	["DAGGER_DOOR"] = "Get the Shadowmoon Sacrificial Dagger by the door",
	["DALARAN_CRATER_PORTAL"] = "Use the Dalaran Crater portal",
	["DECLINE_Q"] = "Decline the quest(s)",
	["DEMENTORS_DROPS_BOOKS"] = "Shadowborne Dementor's drop Shadow Council Spellbooks",
	["DESTINATION"] = "Destination",
	["DETACH_Q_ITEM_BTN"] = "Detatch the Quest Item buttons",
	["DISABLE_HEIRLOOM_WARNING"] = "Disable Heirloom Warning",
	["DISABLED_ADDON_LIST"] = "is disabled in your Add-on list",
	["DO_BONUS_OBJECTIVE"] = "Do the Bonus Objective",
	["DO_NOT_LOOT_HYDRA"] = "Do not loot the Devouring Hydra's until you have skinned them, or they will dissapear",
	["DO_NOT_USE_GLIDER"] = "Do not use gliders",
	["DOING_EMOTE"] = "Do the emote",
	["DOTS_EXPIRE"] = "Let your debuffs expire before clicking the Shrine of Thunder",
	["DOWN_ELEVATOR"] = "Go down the elevator",
	["DOWNSTAIRS"] = "Downstairs",
	["DROPS_FROM_THISTLEFURS"] = "Troll Charm's drop from Thistlefur Avengers",
	["EMPTY_GREAT_HALL"] = "Go into the empty lot to the right of the Great Hall",
	["ENTER_MIRROR"] = "Enter the mirror",
	["EQUIP_GOGGLES"] = "Equip the Goggles of Gem Hunting and find Elven Gems",
	["ERROR"] = "Error",
	["EXPERT_RIDING"] = "Expert Riding",
	["EXTRA"] = "Extra",
	["EXTRA_ACTION_BUTTON_NOT_NEEDED"] = "You don't need to use the extra action button",
	["FALSEBOTTOMED_JAR"] = "Find the False Jar",
	["FILL_VIAL"] = "Fill the Empty Moonwell Vial",
	["FIND_CURIER"] = "Find the Forsaken Courier along the road",
	["FLY_BACK"] = "Fly back",
	["FLY_BACK_OVER"] = "Fly back over",
	["FLY_GREAT_SEAL"] = "Fly to the Great Seal",
	["FLY_NISHA"] = "Fly with Nisha",
	["FLY_OVER_MOUNTAIN"] = "Fly over the mountain",
	["FLY_TO"] = "Fly to",
	["FLYING_AROUND_THE_FOREST"] = "Stinglasher is flying around the forest",
	["FOLLOW_ZOLANI"] = "Stay close to Zolani's proximity, or she won't move",
	["FRESHLEAF_BUFF"] = "Freshleaf buff",
	["GAZLOWE_PORTAL"] = "Wait for Gazlowe to exit the portal to turn-in the quest(s)",
	["GENERAL_OPTION"] = "General Options",
	["GET_CROSSBOW"] = "Get Crossbow",
	["GET_CROWBAR"] = "Get Crowbar from Treasure hunters",
	["GET_EGG"] = "Get Egg",
	["GET_FLIGHPATH"] = "Get Flightpath",
	["GET_FLIGHT_POINT"] = "Get Flight Point",
	["GET_JOURNEYMAN_RIDING"] = "Get Journeyman Riding",
	["GET_KEY_CAVE"] = "Get the key in the cave",
	["GET_TREASURE"] = "Get Treasure",
	["GET_WEAPONS_CACHE"] = "Get Weapons Cache",
	["GIVERS_AROUND_AREA"] = "The Quest givers wander around the area",
	["GO_BLASTEDLANDS"] = "Go To BlastedLands",
	["GO_CAVE"] = "Go to the Fissure of Fury",
	["GO_EAST"] = "go East",
	["GO_INTO_HUT"] = "Go into the Hut",
	["GO_NORTH"] = "Go North",
	["GO_NORTH_WEST_GARRISON"] = "Go North West of Garrison",
	["GO_NORTHWEST"] = "Go Northwest",
	["GO_PORTAL_ROOM"] = "Go to Portal Room",
	["GO_SINFALL"] = "Go Into Sinfall",
	["GO_SOUTH"] = "Go South",
	["GO_TO"] = "Go To",
	["GO_WEST"] = "go West",
	["GOHEAD_NO_RP"] = "You can run ahead if you don't want to RP walk",
	["GORLASH_PATROLLS"] = "Gorlash patrolls",
	["GORMLINGS_COLLECTED"] = "gormlings collected",
	["GOSSAMER_THREAD_BUFF"] = "Gossamer Thread buff",
	["GRAB_HEAL_DMG_BUFF"] = "Grab the healing haste and damage buffs (Big Circles)",
	["GRAB_WEAPON_ON_GROUND"] = "Grab your weapon on the ground when you're disarmed!",
	["GROUP"] = "Group",
	["GROUP_Q"] = "Ask for group quest",
	["HALFWAY_UP_CLIFF"] = "Halfway up the cliff wall",
	["HAMMER_ON_GONGS"] = "Hurl Kyrian Hammer on the gongs!",
	["HAND_IN_Q"] = "Hand in the quest(s)",
	["HANDIN_NEWS_TALADOR"] = "Handin news from Talador",
	["HANGING_UNDERNEATH_CLIFF"] = "Hanging underneath cliff",
	["HARP_TRAP"] = "Suspiciously Untouched Harp",
	["HE_PATROLS"] = "He Patrols",
	["HEAD_SOUTHEAST"] = "Head Southeast",
	["HERB_BAG_DOWNSTAIRS"] = "Herb bag downstairs",
	["HIDE_RIDING"] = "Hide mount skill learning messages",
	["HORN_DOWNSTAIRS"] = "Horn downstairs",
	["HORN_ON_THE_GROUND"] = "When he stops taking damage click on the horn on the ground and use it",
	["HS_ORIBOS_OR_FLY"] = "Use HS to Oribos or fly there",
	["IGNORE_MOBS_FAST"] = "Can ignore mobs (if you're fast)",
	["IN_BOAT"] = "In Boat",
	["IN_HOUSE"] = "In the house",
	["IN_HUT"] = "In the Hut",
	["IN_NEST_MUSTHROOM"] = "In nest ontop of Musthroom",
	["IN_THE_BASEMENT"] = "In the basement",
	["IN_THE_LAKE"] = "In the Lake",
	["IN_TOWER"] = "In the Tower",
	["IN_WATER"] = "In the water",
	["IN_WATER_PILLAR"] = "In the water by pillar",
	["INSIDE"] = "Inside",
	["INSIDE_BUILDING"] = "Inside the building",
	["INSIDE_CAVE"] = "Go inside the Fissure of Fury",
	["INSIDE_HEARTHFIRE_TAVERN"] = "Inside Hearthfire Tavern",
	["INSIDE_SHACK"] = "Inside the shack",
	["INTO_MINE"] = "Into the Mine",
	["ITEM_SOLD"] = "Items were sold for",
	["JOLS_COMMANDS"] = "Follow Jol's commands",
	["JOURNEYMAN_RIDING"] = "Journeyman Riding",
	["JUMP"] = "Jump",
	["JUMP_OFF"] = "Jump off",
	["JUMP_OFF_BRIDGE"] = "Jump off bridge",
	["KAJAMITE"] = "Kaja’mite Chunks 10% dmg buff",
	["KALIRI_EGG"] = "Kaliri Egg",
	["KEEP_TRICKSTER_TARGETED"] = "Keep Trickster targeted for auto-Emotes (English Client Only)",
	["KEYBINDS"] = "Set Keybind",
	["KILL_BLOOD_ELVES"] = "Kill Blood elves",
	["KILL_BLOODFANG_STALKER"] = "Killing a Bloodfang Stalker spawns a quest",
	["KILL_BRISTLELIMBS"] = "Kill Bristlelimbs to summon Chief",
	["KILL_CENTAURS"] = "Kill centaurs untill Krom'zar appears",
	["KILL_DARK_IRONS"] = "Kill Dark irons untill boss spawns",
	["KILL_EXPLOSIVE_HATRED"] = "Kill Explosive Hatreds to disable shield",
	["KILL_FLEETFOOT"] = "Kill Fleetfoot and loot his tail",
	["KILL_NAGA"] = "Kill naga",
	["KILL_NPCS_FASTER_YSERA_DIES"] = "The faster you kill the NPCs the faster Ysera dies",
	["KILL_PAINMASTER"] = "Kill Painmaster on the wagon",
	["KILL_SAPPER"] = "Kill Sapper",
	["KILL_SATYR_FLESH"] = "Kill Satyrs for Satyr Flesh",
	["KILL_WINTERFALL_MOBS"] = "Kill Winterfall mobs",
	["KITE_GROMLINGS"] = "Click and kite Gromlings to Wildseed",
	["LEAVE_GARRISON_SOUTH"] = "Leave Garrison Go South - chest on wall",
	["LEAVE_TUTORIAL"] = "Leave Tutorial",
	["LEFT_STAIRS"] = "Left of stairs",
	["LISTEN"] = "Listen",
	["LOA_INFO_1"] = "Gonk: 40% move speed and half fall damage for 30sec",
	["LOA_INFO_2"] = "Pa'Ku: Travel Zuldazar - 6 differents places ",
	["LOAD"] = "Load",
	["LOADED"] = "Loaded",
	["LOCK_ARROW_WINDOW"] = "Lock Arrow Window",
	["LOCK_QLIST_WINDOW"] = "Lock the QuestList Window",
	["LOOT_BAG"] = "Loot bag",
	["LOOT_BELONGINGS"] = "Loot Belongings",
	["LOOT_COCONUT"] = "Loot Coconut",
	["LOOT_DAGGER"] = "Loot Dagger",
	["LOOT_FEMUR"] = "Loot femur underneath big rock",
	["LOOT_HARPYS_HORN"] = "Loot Horn from Harpys",
	["LOOT_JAR"] = "Loot Jar",
	["LOOT_LANTERN"] = "Loot lantern",
	["LOOT_MELONFRUIT"] = "Loot Melonfruit",
	["LOOT_PAMELA_HEAD"] = "Loot: Pamela's Doll's Head Left and Right Side and combine them",
	["LOOT_SATYR_SABER"] = "Loot weaponracks for Satyr Sabers",
	["LOOT_SKULLS_AND_SUMMON"] = "Loot skulls in room and summon",
	["LOOT_TUSKS"] = "Loot the Tusks",
	["LOOT_WILDFIRE_BOTTLE"] = "Loot Bottle of Wildfire from table",
	["MAP_WALL"] = "From the Map on the wall",
	["MASTER_RIDING"] = "Master Riding",
	["MAXOMILLIAN_PRAY"] = "Let Maxomillian pray to Furys",
	["minimap_BLOB_ALPHA"] = "Set minimap blobs alpha",
	["MINING_PICK"] = "Mining Pick",
	["MISSING_Q"] = "Missing quest(s)",
	["MOUNT_HORSE_SCARE_SPIDER"] = "Mount a Horse and scare Spiders",
	["MOUNTING_DESPAWNS_SWARMER"] = "Mounting de-spawns the swarmer",
	["MOVE_ZONE"] = "Right-click or drag zone to move routes",
	["NAME"] = "Name",
	["NEDD_BUFF_DISARM_TRAP"] = "Needed buffs for Disarming Traps",
	["NEED_CHECK_FPS"] = "Need to check FPs",
	["NET_PILLAGER"] = "Net a Pillager and drag it to camp",
	["NO_WAYPOINTS_GARRISON"] = "No waypoints are available while you complete the quest(s)",
	["NORTH_OUTPOST"] = "North of your Outpost",
	["NOT_IN_CHROMIE_TIMELINE"] = "You are not in Chromie Time!",
	["NOT_SKIP_VIDEO"] = "Don't skip video",
	["NOT_YET"] = "Not Yet!",
	["NPC_DROP_Q"] = "If the NPC's aren't talking to each other immediately, then abandon the quest and pick it up again",
	["NPC_TOP_TOWER"] = "NPC is ontop of the tower",
	["NPC_ZENKIKI"] = "Click on the npc (Zen'Kiki) so he pulls Hawks",
	["ON_BUILDING"] = "On the Building",
	["ON_CHAINED_OUTCAST"] = "on the chained outcast",
	["ON_CLIFF"] = "Ontop Cliff",
	["ONLY_ONE_WAIT_NPC"] = "Only one can do the quest at a time so you might have to wait for npc to respawn",
	["OPEN_BAG"] = "Open Bag",
	["OPTIONAL"] = "Optional",
	["OUT_CAVE"] = "Exit cave",
	["OUT_WEST_GATE"] = "Outside West gate",
	["PICK_ARSENAL"] = "Pick Arsenal",
	["PICK_ROUTE"] = "Pick Route",
	["PICK_UP_LETTER"] = "Pick up letter from mail",
	["PICK_UP_Q"] = "Pick up the quest(s)",
	["PICK_ZONE"] = "Pick Zone",
	["PLACE_LIGHTWELLS"] = "Place Lightwells around the corpsebeasts",
	["PLACE_MEAT"] = "Open quest bag place meat use pheromones",
	["PORTAL_WILL_APPEAR"] = "Portal will Appear",
	["PUS_PET_ABILITY"] = "Use Pet ability (Call to Arms) to Enlist Troops",
	["Q_ACCEPTED"] = "Quest(s) accepted",
	["Q_BTN_SCALE"] = "Quest Buttons Scale",
	["Q_DROP"] = "Quest Drop",
	["Q_OPTIONS"] = "Quest Options",
	["Q_OUT_SCREEN"] = "The QuestList is off the screen! Resetting its position...",
	["Q_PART"] = "Do part of the quest",
	["Q_REMOVED"] = "Quest removed",
	["Q_TEXT"] = "Quests Text",
	["QLIST_SCALE"] = "QuestList Scale",
	["QORDERLIST_SCALE"] = "Quest Order List Scale",
	["REDUCED_DAMAGE_INFO_1"] = "Wait until his stack of buffs are gone",
	["REPAIR_EQUIPEMENT"] = "Equipment has been repaired for",
	["RESET"] = "reset",
	["RESET_ARROW"] = "Reset Arrow",
	["RESET_QORDERLIST"] = "Reset QuestOrderList",
	["RESET_ZONE"] = "Resetting Zone",
	["RIDE_NISHA"] = "Ride Nisha",
	["RING_IN_WATER"] = "Small ring In the water",
	["ROLLBACK"] = "Rollback Quest Step",
	["ROUTE_COMPLETED"] = "Route Completed",
	["ROUTE_NOT_FOUND"] = "Route Not found for",
	["RUN_FOREST_RUN"] = "DON’T WAIT RUN THIS WAY!!!",
	["RUN_WAYPOINT"] = "Run to the waypoint",
	["SAIL_TO"] = "Sail to",
	["SALVAGE_FLOATING_DEBRIS"] = "Salvage floating debris",
	["SAVAGE_FIGHT_CLUB"] = "Chose The Savage Fight Club",
	["SCARE_SPIDER_INTO_LUMBERMILL"] = "Scare Spiders into the Lumbermill",
	["SCENARIO"] = "Do the scenario",
	["SCOUTING_MAP"] = "From the scouting map",
	["SEARCH_CENTAUR_TENTS"] = "Search the Centaur tents",
	["SET_HEARTHSTONE"] = "Set Hearthstone",
	["SETTINGS"] = "Settings",
	["SHACKLE_HUT"] = "Click the shackle in the Hut",
	["SHIMMERDUST_BUFF"] = "Shimmerdust Pile buff",
	["SHOW_ARROW"] = "Show Arrow",
	["SHOW_BLOBS_ON_MAP"] = "Show Green blobs on map",
	["SHOW_BLOBS_ON_minimap"] = "Show Green blobs on minimap",
	["SHOW_GROUP_PROGRESS"] = "Show Group Progress",
	["SHOW_QLIST"] = "Show QuestList",
	["SHOW_QORDERLIST"] = "Show Quest Order List",
	["SHOW_RIDING"] = "Show mount skill learning messages",
	["SHOW_STEPS_MAP"] = "Show 10 steps on map",
	--[[Translation missing --]]
	["SHUMMERDUST_BUFF"] = "",
	["SKIP"] = "Skipping Quest Step",
	["SKIP_BUTTON"] = "Skip",
	["SKIP_WAYPOINT"] = "Skip to the waypoint",
	["SKIP_WAYPOINT_IF_YOU_GLIDE"] = "If you can glide, skip the waypoint and glide to the to quest(s) mobs",
	["SKIPCAMP"] = "Skipping Camp Step",
	["SKIPPED_CUTSCENE"] = "Skip cutscene",
	["SOULWEB_TRAP"] = "Suspiciously Untouched Soulweb",
	["SPEAK_DEATHLY_USHER"] = "Speak to Deathly Usher",
	["SPEAR_DOWN_THE_UFO"] = "He is flying use spear to pull him",
	["SPEEDRUN"] = "Speed Run",
	["SUGGESTED_PLAYERS"] = "Suggested Players",
	["SWITCH_TIMELINE"] = "Time to switch timeline at chromie",
	["SWITCH_TO"] = "Chromie switch to timeline",
	["TAKE_BOAT_TO_SEEKERS_OUTPOST"] = "Take Boat to Seeker's Outpost",
	["TALK_DREAD_RIDER_CULLEN"] = "Talk to Dread-Rider Cullen",
	["TALK_EFFIGY"] = "Talk to Effigy",
	["TALK_ENSIGN_WARD"] = "Talk to Ensign Ward",
	["TALK_ERUL"] = "Talk to Erul Dawnbrook",
	["TALK_GRAND_AMIRAL_JES_TERETH"] = "Talk to Grand Admiral Jes-Tereth",
	["TALK_HALANNIA"] = "Talk to Halannia",
	["TALK_JHASH"] = "Talk to Jhash for a ride",
	["TALK_JORNUN"] = "Talk to Jornun to Ride",
	["TALK_KING_RASTAKHAN"] = "Talk to King Rastakhan",
	["TALK_NISHA"] = "Talk to Nisha",
	["TALK_ORKUS"] = "Talk to Orkus after RP and then loot Plans",
	["TALK_ROKHAN_RIDE_DOWN"] = "Speak to Rokhan for a ride down",
	["TALK_ROKHAN_RIDE_ZULJAN"] = "Speak to Rokhan for a ride to Zul'jan",
	["TALK_SASSY"] = "Talk to Sassy Hardwrench for a ride",
	["TALK_SENTINEL_AVANA"] = "Talk to Sentinel Avana",
	["TALK_STEWARD"] = "Talk to Steward",
	["TALK_SWELLTHRASHER"] = "Talk to Swellthrasher",
	["TALK_THELARON"] = "Talk to Thelaron",
	["TALK_TO"] = "Talk to",
	["TALK_TO_NPC_TO_RIDE_BOAT"] = "Talk to NPC to ride boat",
	["TAVERN"] = "Tavern",
	["TELEPORT_UP_AND_JUMP"] = "Teleport up and jump in the ring",
	["TO_GAZLOWE"] = "To Gazlowe",
	["TO_ROKHAN_GAZLOWE"] = "Turn in to Rokhan and Gazlowe",
	["TO_WARMASTER_ZOG"] = "To Warmaster Zog inside the Great Hall",
	["TOP_BIG_MUSHROOM"] = "Ontop the big mushroom",
	["TOP_BOAT"] = "He is Up top of the boat",
	--[[Translation missing --]]
	["TOP_OF_BOAT"] = "",
	["TOP_OF_MOUNTAIN"] = "Ontop of the mountain",
	["TOP_TOWER_OVER_EDGE"] = "Ontop of the tower over the edge",
	["TOTEM_DAMAGE_BUFF"] = "Stand in totem for dmg buff",
	["TRAIN_APPRENTICE_RIDING"] = "Train Apprentice Riding",
	["TRAIN_RIDING"] = "Train Riding",
	["TRAVEL_TO"] = "Travel to",
	["TREASURE_CAVE"] = "Treasure in cave",
	["TREASURE_NORTH_SHIP"] = "Treasure is North of ship",
	["TREASURE_TOP_TOWER"] = "Treasure is ontop of the tower",
	["TURN_IN_Q"] = "Turn-in the quest(s)",
	["TURN_ON_WARMODE"] = "Turn on War Mode for extra experience!",
	["UNDERNEATH"] = "Underneath",
	["UNDERNEATH_BRIDGE"] = "Underneath bridge",
	["UNTOUCHED_BASKET"] = "Suspiciously Untouched Basket",
	["UP_CRANE"] = "Up in the crane",
	["UP_ELEVATOR"] = "Go up the Elevator",
	["UP_TOWER"] = "Up the Tower",
	["UP_TREE"] = "Up in the tree",
	["UPDATE_ARROW"] = "Update Arrow every",
	["UPSTAIRS"] = "Go Upstairs",
	["UPSTAIRS_AND_JUMP"] = "Go upstairs and jump over on the ledge",
	["UPSTAIRS_BED"] = "Upstairs in bed",
	["UPTOP"] = "Uptop",
	["USE_ASTRANAAR_THROWER"] = "Use Astranaar Thrower",
	["USE_BANNER_ON_CORPSES"] = "Use Banner on Corpses",
	["USE_BARRELS"] = "Use the barrels to weaken Mucksquint",
	["USE_BOAT"] = "Use Boat",
	["USE_BRANCH_ON_GORMS"] = "Use the branch on large hostile Gorms before you kill them",
	["USE_CANNON"] = "Use cannon to get back",
	["USE_CART"] = "Use Cart",
	["USE_CHAIR"] = "Use Chair",
	["USE_CLAW"] = "Use the Claw",
	["USE_COVENANT_ABILITY"] = "Use your Soulshape covenant ability",
	["USE_DALARAN_HEARTHSTONE"] = "Use Dalaran Hearthstone",
	["USE_DISGUISE"] = "Use Disguise",
	["USE_ELEVATOR"] = "Use the elevator",
	["USE_FLIGHTPATH"] = "Use Flightpath",
	["USE_GARRISON_HEARTHSTONE"] = "Use Garrison Hearthstone",
	["USE_GATE"] = "Use Gate",
	["USE_GATE_MALDRAXXUS"] = "Use Gate to Maldraxxus",
	["USE_GATEWAY"] = "Use the gateway",
	["USE_GLAIVE_THROWER"] = "Use Glaive Thrower",
	["USE_HEARTHSTONE"] = "Use Hearthstone",
	["USE_ITEM"] = "Use Item",
	["USE_JAVELINS_TO_SPEED"] = "Loot and use Javelins to speed up killing",
	["USE_MOUNT"] = "Use Mount",
	["USE_ORB_CANYON_ETTIN"] = "Use Orb on a Canyon Ettin then save Oslow",
	["USE_ORGRIMMAR_PORTAL"] = "Use Orgrimmar Portal",
	["USE_PHASEBLOOD_POTION"] = "Use Phaseblood Potion on Mark",
	["USE_PORTAL"] = "Use Portal",
	["USE_PORTAL_TO"] = "Use Portal to",
	["USE_QITEM_DUNGEON"] = "Use quest item inside dungeon",
	["USE_SOULBREAKER"] = "Use Soulbreaker Traps for extra dmg",
	["USE_SOULSHAPE"] = "Use Soulshape",
	["USE_TAVERN_HEARTHSTONE"] = "Use Tavern Hearthstone to camp",
	["USE_TELEPORT"] = "Use teleport",
	["USE_WHISTLE_ON_RAMS"] = "use /whistle on rams",
	["WAIT_FOR_NPC"] = "Wait for NPC to get in place",
	["WALK_BLADEGUARD_KAJA"] = "Walk with Bladeguard Kaja",
	["WAYPOINT"] = "Waypoint",
	["WEAPON_PICK_DOESNT_MATTER"] = "Doesn't matter what weapon you pick",
	["YARDS"] = "yards",
	["YES_TO_EXIT_TUTORIAL"] = "Yes To Exit Tutorial",
	["YOU_CAN_LEARN"] = "You can now learn",
	["ZONE"] = "Zone",
	["ZONE_DONE"] = "Zone Done"
}
