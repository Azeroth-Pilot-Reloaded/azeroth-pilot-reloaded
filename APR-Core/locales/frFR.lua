if GetLocale() ~= "frFR" then return; end
local app = select(2, ...);
local L = app.L;

-- Author: Neogeekmo

L = {
	["ACCEPT_Q"] = "Acceptez la quête",
	["AFK"] = "AFK",
	["ALL_Q"] = "Toutes les quêtes",
	["APPRENTICE_RIDING"] = "Apprenti cavalier",
	--[[Translation missing --]]
	["AROUND_COOKPOT"] = "Pick-up each quest around the nearby cooking pot",
	["ARROW_OPTION"] = "Options flèche",
	["ARROW_SCALE"] = "Taille de la flèche",
	--[[Translation missing --]]
	["ASSULT_SKIP"] = "The NPC won't be there if an assault is active! If so, skip ahead",
	--[[Translation missing --]]
	["AT_FLIGHTPATH"] = "At the flightpath",
	--[[Translation missing --]]
	["AT_GAZLOWE"] = "At Gazlowe",
	["AUTO_PATH_HELPER"] = "Options Route",
	["AUTO_PICK_REWARD_ITEM"] = "Choix des récompenses en fonction du ilvl",
	["AUTO_REPAIR"] = "Réparation automatique",
	["AUTO_SELECTION_OF_DIALOG"] = "Sélection automatique des dialogues",
	["AUTO_VENDOR"] = "Vendre automatiquement les objets gris",
	--[[Translation missing --]]
	["BANNER_IN_HUTS"] = "The banner is in one of the huts",
	["BENEATH_HANDIN"] = "Allez à la surface si vous ne pouvez pas rendre",
	--[[Translation missing --]]
	["BEWARE_TWO_LEVEL"] = "Be aware of the two level \"??'s\"",
	["BLOODLUST"] = "Un bon moment pour utiliser la BL",
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
	["CLICK_BUFFS_IN_ZONE"] = "Il y a des buffs récupérables partout dans la zone",
	["CLICK_ETERNAL_FLAME"] = "Cliquez sur La flamme éternelle",
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
	["CLOSE"] = "Fermer",
	--[[Translation missing --]]
	["CLOSE_JAINA"] = "Stay close to Jaina's proximity, or she won't move",
	["CLOSEST_FP"] = "Point de vol le plus proche",
	["COMPLETE_Q"] = "Quête terminée",
	["CUSTOM_PATH"] = "Route custome",
	--[[Translation missing --]]
	["DAGGER_DOOR"] = "Get the Shadowmoon Sacrificial Dagger by the door",
	--[[Translation missing --]]
	["DALARAN_CRATER_PORTAL"] = "Use the Dalaran Crater portal",
	["DECLINE_Q"] = "Déclinez les quêtes",
	--[[Translation missing --]]
	["DEMENTORS_DROPS_BOOKS"] = "Shadowborne Dementor's drop Shadow Council Spellbooks",
	["DESTINATION"] = "Destination",
	["DETACH_Q_ITEM_BTN"] = "Détacher le bouton d'objet de quête",
	["DISABLE_HEIRLOOM_WARNING"] = "Désactiver l'avertissement de l'héritage",
	["DISABLED_ADDON_LIST"] = "est désactivé dans votre liste d'addon!",
	["DO_BONUS_OBJECTIVE"] = "Faite l'objectif bonus",
	--[[Translation missing --]]
	["DO_NOT_LOOT_HYDRA"] = "Do not loot the Devouring Hydra's until you have skinned them, or they will dissapear",
	["DO_NOT_USE_GLIDER"] = "ATTENTION NE SURTOUT PAS UTILISER DE PLANEUR GOBELIN",
	["DOING_EMOTE"] = "Faites l'Emote",
	["DOTS_EXPIRE"] = "Attendre la fin des dégâts avant de cliquer sur l'autel",
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
	["ERROR"] = "Erreur",
	["EXPERT_RIDING"] = "Expert cavalier",
	["EXTRA"] = "Extra",
	["EXTRA_ACTION_BUTTON_NOT_NEEDED"] = "La technique supplémentaire n'est pas nécessaire",
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
	["FRESHLEAF_BUFF"] = "Buff Vertefeuille",
	--[[Translation missing --]]
	["GAZLOWE_PORTAL"] = "Wait for Gazlowe to exit the portal to turn-in the quest(s)",
	["GENERAL_OPTION"] = "Options Général",
	--[[Translation missing --]]
	["GET_CROSSBOW"] = "Get Crossbow",
	--[[Translation missing --]]
	["GET_CROWBAR"] = "Get Crowbar from Treasure hunters",
	--[[Translation missing --]]
	["GET_EGG"] = "Get Egg",
	["GET_FLIGHPATH"] = "Prenez le point de vol",
	["GET_FLIGHT_POINT"] = "Prenez le point de vol",
	["GET_JOURNEYMAN_RIDING"] = "Vous pouvez apprendre Compagnon cavalier",
	--[[Translation missing --]]
	["GET_KEY_CAVE"] = "Get the key in the cave",
	["GET_TREASURE"] = "Prenez le trésor",
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
	["GO_PORTAL_ROOM"] = "Allez à la salle des portails",
	--[[Translation missing --]]
	["GO_SINFALL"] = "Go Into Sinfall",
	--[[Translation missing --]]
	["GO_SOUTH"] = "Go South",
	["GO_TO"] = "Allez à",
	--[[Translation missing --]]
	["GO_WEST"] = "go West",
	--[[Translation missing --]]
	["GOHEAD_NO_RP"] = "You can run ahead if you don't want to RP walk",
	--[[Translation missing --]]
	["GORLASH_PATROLLS"] = "Gorlash patrolls",
	["GORMLINGS_COLLECTED"] = "Gormelins récupérés",
	["GOSSAMER_THREAD_BUFF"] = "Buff Fil de tulle",
	--[[Translation missing --]]
	["GRAB_HEAL_DMG_BUFF"] = "Grab the healing haste and damage buffs (Big Circles)",
	--[[Translation missing --]]
	["GRAB_WEAPON_ON_GROUND"] = "Grab your weapon on the ground when you're disarmed!",
	["GROUP"] = "Groupe",
	["GROUP_Q"] = "Recherchez un groupe pour les quêtes",
	--[[Translation missing --]]
	["HALFWAY_UP_CLIFF"] = "Halfway up the cliff wall",
	--[[Translation missing --]]
	["HAMMER_ON_GONGS"] = "Hurl Kyrian Hammer on the gongs!",
	["HAND_IN_Q"] = "Rendez la quête",
	--[[Translation missing --]]
	["HANDIN_NEWS_TALADOR"] = "Handin news from Talador",
	--[[Translation missing --]]
	["HANGING_UNDERNEATH_CLIFF"] = "Hanging underneath cliff",
	["HARP_TRAP"] = "Harpe étrangement intacte",
	--[[Translation missing --]]
	["HE_PATROLS"] = "He Patrols",
	--[[Translation missing --]]
	["HEAD_SOUTHEAST"] = "Head Southeast",
	--[[Translation missing --]]
	["HERB_BAG_DOWNSTAIRS"] = "Herb bag downstairs",
	["HIDE_RIDING"] = "Cacher les messages d'apprentissage de compétence de monture",
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
	["ITEM_SOLD"] = "La camelote a été vendu pour",
	--[[Translation missing --]]
	["JOLS_COMMANDS"] = "Follow Jol's commands",
	["JOURNEYMAN_RIDING"] = "Compagnon cavalier",
	["JUMP"] = "Sautez",
	["JUMP_OFF"] = "Sautez",
	["JUMP_OFF_BRIDGE"] = "Sautez du pont",
	["KAJAMITE"] = "Morceaux de Kaja'mite: 10% de bonus de dégâts",
	--[[Translation missing --]]
	["KALIRI_EGG"] = "Kaliri Egg",
	--[[Translation missing --]]
	["KEEP_TRICKSTER_TARGETED"] = "Keep Trickster targeted for auto-Emotes (English Client Only)",
	["KEYBINDS"] = "Raccourcis clavier",
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
	["LOA_INFO_1"] = "Totem de Gonk: 40% de vitesse de déplacement pendant 30s",
	["LOA_INFO_2"] = "Totem de Pa'Ku: Voiyage entre 6 différents totem en Zuldazar",
	["LOAD"] = "Chargement",
	["LOADED"] = "Chargé",
	["LOCK_ARROW_WINDOW"] = "Verrouiller la flèche",
	["LOCK_QLIST_WINDOW"] = "Verrouiller la fenêtre de liste de quêtes",
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
	["LOOT_HARPYS_HORN"] = "Récupérez la corne sur les Harpies",
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
	["MASTER_RIDING"] = "Maître cavalier",
	--[[Translation missing --]]
	["MAXOMILLIAN_PRAY"] = "Let Maxomillian pray to Furys",
	["Minimap_BLOB_ALPHA"] = "Transparence des pointillers sur la minicarte",
	--[[Translation missing --]]
	["MINING_PICK"] = "Mining Pick",
	["MISSING_Q"] = "Quête manquante",
	["MOUNT_HORSE_SCARE_SPIDER"] = "Monter à cheval et effrayer les araignées",
	--[[Translation missing --]]
	["MOUNTING_DESPAWNS_SWARMER"] = "Mounting de-spawns the swarmer",
	["MOVE_ZONE"] = "Clic droit ou clic/déposer la zone dans la colonnes routes",
	["NAME"] = "Nom",
	["NEDD_BUFF_DISARM_TRAP"] = "Buff nécessaires pour désarmer les pièges",
	--[[Translation missing --]]
	["NEED_CHECK_FPS"] = "Need to check FPs",
	--[[Translation missing --]]
	["NET_PILLAGER"] = "Net a Pillager and drag it to camp",
	--[[Translation missing --]]
	["NO_WAYPOINTS_GARRISON"] = "No waypoints are available while you complete the quest(s)",
	--[[Translation missing --]]
	["NORTH_OUTPOST"] = "North of your Outpost",
	["NOT_IN_CHROMIE_TIMELINE"] = "Vous n'êtes pas dans une ligne temporelle de Chromie:",
	--[[Translation missing --]]
	["NOT_SKIP_VIDEO"] = "Don't skip video",
	["NOT_YET"] = "Pas le moment!",
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
	["OPEN_BAG"] = "Ouvrez le sac",
	["OPTIONAL"] = "Facultatif",
	--[[Translation missing --]]
	["OUT_CAVE"] = "Exit cave",
	--[[Translation missing --]]
	["OUT_WEST_GATE"] = "Outside West gate",
	--[[Translation missing --]]
	["PICK_ARSENAL"] = "Pick Arsenal",
	["PICK_ROUTE"] = "Sélectionnez une route",
	--[[Translation missing --]]
	["PICK_UP_LETTER"] = "Pick up letter from mail",
	["PICK_UP_Q"] = "Prenez les quêtes",
	["PICK_ZONE"] = "Sélectionnez une zone",
	--[[Translation missing --]]
	["PLACE_LIGHTWELLS"] = "Place Lightwells around the corpsebeasts",
	--[[Translation missing --]]
	["PLACE_MEAT"] = "Open quest bag place meat use pheromones",
	["PORTAL_WILL_APPEAR"] = "Un portail va apparaître",
	--[[Translation missing --]]
	["PUS_PET_ABILITY"] = "Use Pet ability (Call to Arms) to Enlist Troops",
	["Q_ACCEPTED"] = "Quête acceptée",
	["Q_BTN_SCALE"] = "Taille du bouton de quête",
	["Q_DROP"] = "Récupérez la quête",
	["Q_OPTIONS"] = "Options quête",
	["Q_OUT_SCREEN"] = "Réinitialisation! Liste de quête en dehors de l'écran!",
	["Q_PART"] = "Faites la quete",
	["Q_REMOVED"] = "Quête supprimée",
	["Q_TEXT"] = "Texte des quêtes",
	["QLIST_SCALE"] = "Taille de la fenêtre de liste de quêtes",
	["QORDERLIST_SCALE"] = "Taille de la fenêtre d'ordre des quêtes",
	["REDUCED_DAMAGE_INFO_1"] = "Attendez que ses buffs disparaissent",
	["REPAIR_EQUIPEMENT"] = "La réparation de l'équipement a coûté",
	["RESET"] = "Réinitialiser",
	["RESET_ARROW"] = "Réinitialiser la flèche",
	["RESET_QORDERLIST"] = "Réinitialiser la liste des quêtes",
	["RESET_ZONE"] = "Zone réinitialisée",
	--[[Translation missing --]]
	["RIDE_NISHA"] = "Ride Nisha",
	--[[Translation missing --]]
	["RING_IN_WATER"] = "Small ring In the water",
	["ROLLBACK"] = "Retour à l'étape passée",
	["ROUTE_COMPLETED"] = "Guide terminée",
	["ROUTE_NOT_FOUND"] = "Route introuvable pour",
	["RUN_FOREST_RUN"] = "N'ATTENDEZ PAS, COUREZ VERS LA DIRECTION INDIQUÉE!!!",
	["RUN_WAYPOINT"] = "Allez au point de passage",
	["SAIL_TO"] = "Naviguer vers",
	--[[Translation missing --]]
	["SALVAGE_FLOATING_DEBRIS"] = "Salvage floating debris",
	--[[Translation missing --]]
	["SAVAGE_FIGHT_CLUB"] = "Chose The Savage Fight Club",
	["SCARE_SPIDER_INTO_LUMBERMILL"] = "Effrayer les araignées dans la scierie",
	--[[Translation missing --]]
	["SCENARIO"] = "Do the scenario",
	--[[Translation missing --]]
	["SCOUTING_MAP"] = "From the scouting map",
	--[[Translation missing --]]
	["SEARCH_CENTAUR_TENTS"] = "Search the Centaur tents",
	["SET_HEARTHSTONE"] = "Fixez votre foyer",
	["SETTINGS"] = "Réglages",
	--[[Translation missing --]]
	["SHACKLE_HUT"] = "Click the shackle in the Hut",
	--[[Translation missing --]]
	["SHIMMERDUST_BUFF"] = "Shimmerdust Pile buff",
	["SHOW_ARROW"] = "Afficher la flèche",
	["SHOW_BLOBS_ON_MAP"] = "Afficher les pointillers sur la carte",
	["SHOW_BLOBS_ON_Minimap"] = "Afficher les pointillers sur la minicarte",
	["SHOW_GROUP_PROGRESS"] = "Afficher la progression du groupe",
	["SHOW_QLIST"] = "Afficher la liste de quêtes",
	["SHOW_QORDERLIST"] = "Afficher la fenêtre d'ordre des quêtes",
	["SHOW_RIDING"] = "Afficher les messages d'apprentissage de compétence de monture",
	["SHOW_STEPS_MAP"] = "Afficher 10 étapes sur la carte",
	["SHUMMERDUST_BUFF"] = "Buff Tas de poussière scintillante",
	["SKIP"] = "Etape passée",
	["SKIP_BUTTON"] = "Passer",
	["SKIP_WAYPOINT"] = "Sauter le point de passage",
	--[[Translation missing --]]
	["SKIP_WAYPOINT_IF_YOU_GLIDE"] = "If you can glide, skip the waypoint and glide to the to quest(s) mobs",
	["SKIPCAMP"] = "Etape du camp passée",
	["SKIPPED_CUTSCENE"] = "Passer les cinématiques",
	["SOULWEB_TRAP"] = "Âmetoile étrangement intacte",
	--[[Translation missing --]]
	["SPEAK_DEATHLY_USHER"] = "Speak to Deathly Usher",
	["SPEAR_DOWN_THE_UFO"] = "S'il vole, utilisez la lance pour l'attirer",
	["SPEEDRUN"] = "Speed Run",
	["SUGGESTED_PLAYERS"] = "Joueurs suggérés",
	--[[Translation missing --]]
	["SWITCH_TIMELINE"] = "Time to switch timeline at chromie",
	--[[Translation missing --]]
	["SWITCH_TO"] = "Chromie switch to timeline",
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
	["TALK_TO"] = "Parlez à ",
	["TALK_TO_NPC_TO_RIDE_BOAT"] = "Parler au PNJ pour monter sur le bateau",
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
	["TOP_OF_BOAT"] = "Il est en haut du bateau",
	--[[Translation missing --]]
	["TOP_OF_MOUNTAIN"] = "Ontop of the mountain",
	--[[Translation missing --]]
	["TOP_TOWER_OVER_EDGE"] = "Ontop of the tower over the edge",
	["TOTEM_DAMAGE_BUFF"] = "Se tenir proche du totem pour avoir le bonus de dégâts",
	["TRAIN_APPRENTICE_RIDING"] = "Vous pouvez apprendre Apprenti cavalier",
	["TRAIN_RIDING"] = "Apprennez la compétence de monture",
	["TRAVEL_TO"] = "Voyagez vers",
	--[[Translation missing --]]
	["TREASURE_CAVE"] = "Treasure in cave",
	--[[Translation missing --]]
	["TREASURE_NORTH_SHIP"] = "Treasure is North of ship",
	--[[Translation missing --]]
	["TREASURE_TOP_TOWER"] = "Treasure is ontop of the tower",
	["TURN_IN_Q"] = "Rendre la quête",
	["TURN_ON_WARMODE"] = "Activez le Mode Guerre dans la fenêtre de vos talents",
	--[[Translation missing --]]
	["UNDERNEATH"] = "Underneath",
	--[[Translation missing --]]
	["UNDERNEATH_BRIDGE"] = "Underneath bridge",
	["UNTOUCHED_BASKET"] = "Pannier étrangement intacte",
	--[[Translation missing --]]
	["UP_CRANE"] = "Up in the crane",
	--[[Translation missing --]]
	["UP_ELEVATOR"] = "Go up the Elevator",
	--[[Translation missing --]]
	["UP_TOWER"] = "Up the Tower",
	--[[Translation missing --]]
	["UP_TREE"] = "Up in the tree",
	["UPDATE_ARROW"] = "Mise à jour de flèche tous les",
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
	["USE_BANNER_ON_CORPSES"] = "Utilisez la bannière sur les cadavres",
	--[[Translation missing --]]
	["USE_BARRELS"] = "Use the barrels to weaken Mucksquint",
	["USE_BOAT"] = "Prenez le bateau pour",
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
	["USE_DALARAN_HEARTHSTONE"] = "Utilisez la pierre de foyer de Dalaran",
	--[[Translation missing --]]
	["USE_DISGUISE"] = "Use Disguise",
	--[[Translation missing --]]
	["USE_ELEVATOR"] = "Use the elevator",
	["USE_FLIGHTPATH"] = "Volez vers",
	["USE_GARRISON_HEARTHSTONE"] = "Utilisez la Pierre de foyer de fief",
	--[[Translation missing --]]
	["USE_GATE"] = "Use Gate",
	--[[Translation missing --]]
	["USE_GATE_MALDRAXXUS"] = "Use Gate to Maldraxxus",
	--[[Translation missing --]]
	["USE_GATEWAY"] = "Use the gateway",
	--[[Translation missing --]]
	["USE_GLAIVE_THROWER"] = "Use Glaive Thrower",
	["USE_HEARTHSTONE"] = "Utilisez votre pierre de foyer",
	["USE_ITEM"] = "Utilisez l'objet",
	--[[Translation missing --]]
	["USE_JAVELINS_TO_SPEED"] = "Loot and use Javelins to speed up killing",
	--[[Translation missing --]]
	["USE_MOUNT"] = "Use Mount",
	--[[Translation missing --]]
	["USE_ORB_CANYON_ETTIN"] = "Use Orb on a Canyon Ettin then save Oslow",
	["USE_ORGRIMMAR_PORTAL"] = "Prend le portail pour Orgrimmar",
	--[[Translation missing --]]
	["USE_PHASEBLOOD_POTION"] = "Use Phaseblood Potion on Mark",
	["USE_PORTAL"] = "Utilisez le portail",
	["USE_PORTAL_TO"] = "Utilisez le portail vers",
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
	["WAIT_FOR_NPC"] = "Attendez que le PNJ se mette en place",
	--[[Translation missing --]]
	["WALK_BLADEGUARD_KAJA"] = "Walk with Bladeguard Kaja",
	["WAYPOINT"] = "Point de passage",
	["WEAPON_PICK_DOESNT_MATTER"] = "Qu'importe l'arme que vous choisissez",
	["YARDS"] = "mètres",
	--[[Translation missing --]]
	["YES_TO_EXIT_TUTORIAL"] = "Yes To Exit Tutorial",
	["YOU_CAN_LEARN"] = "Vous pouvez apprendre",
	["ZONE"] = "Zone",
	["ZONE_DONE"] = "Zone terminée"
}
