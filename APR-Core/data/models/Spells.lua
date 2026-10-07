-- Declares hearthstone/toy spell mappings and tracked class buffs.
-- Item IDs drive secure actions; spell IDs identify aura and cast completion events.

APR.hearthStoneSpellID = {
    556,     -- Astral Recall
    8690,    -- Hearthstone
    23442,   -- Dimensional Ripper - Everlook
    23453,   -- Ultrasafe Transporter - Gadgetzan
    28148,   -- Portal: Karazhan
    35745,   -- Socrethar's Teleportation Stone
    36890,   -- Dimensional Ripper - Area 52
    39937,   -- There's No Place Like Home
    41234,   -- Blessed Medallion of Karabor
    46149,   -- Darnarian's Scroll of Teleportation
    48129,   -- Scroll of Recall
    49844,   -- Direbrew's Remote
    54403,   -- Scourgestone
    54406,   -- Teleport: Dalaran
    59317,   -- The Schools of Arcane Magic - Mastery (spires atop the Violet Citadel)
    60320,   -- Scroll of Recall II
    60321,   -- Scroll of Recall III
    66238,   -- Argent Crusader's Tabard
    67833,   -- Wormhole Generator: Northrend
    71436,   -- Boots of the Bay
    73324,   -- Jaina's Locket
    75136,   -- Ethereal Portal
    80256,   -- Potion of Deepholm
    82674,   -- The Last Relic of Argus
    85609,   -- Gidwin's Hearthstone
    89157,   -- Cloak of Coordination: Stormwind
    89158,   -- Cloak of Coordination: Orgrimmar
    89597,   -- Baradin's Wardens Tabard
    89598,   -- Shroud of Cooperation: Orgrimmar
    94719,   -- The Innkeeper's Daughter
    96333,   -- Hero's Hearthstone
    96334,   -- Veteran's Hearthstone
    126755,  -- Wormhole Generator: Pandaria
    126956,  -- Lorewalker's Lodestone
    134026,  -- Vol'jin's Hearthstone
    136508,  -- Dark Portal
    139432,  -- Teleport: Brawl'gar Arena
    139437,  -- Teleport: Bizmo's Brewpub
    140295,  -- Kirin Tor Beacon
    140300,  -- Sunreaver Beacon
    145430,  -- Call of the Mists
    163830,  -- Wormhole Centrifuge
    172644,  -- Draenor Archaeologist's Lodestone
    175604,  -- Bladespire Relic
    175608,  -- Relic of Karabor
    176766,  -- Scroll of Risky Recall
    189838,  -- Admiral's Compass
    190809,  -- Hunter's Seeking Crystal
    190810,  -- Master Hunter's Seeking Crystal
    193669,  -- Beginner's Guide to Dimensional Rifting
    196079,  -- Recall
    196080,  -- Recall
    197104,  -- Orgrimmar Portal Stone
    197107,  -- Stormwind Portal Stone
    199978,  -- Intra-Dalaran Wormhole Generator
    200061,  -- Summon Reaves
    216138,  -- Emblem of Margoss
    220746,  -- Scroll of Teleport: Ravenholdt
    220989,  -- Empowered Ring of the Kirin Tor
    222695,  -- Dalaran Hearthstone (toy)
    223805,  -- Adept's Guide to Dimensional Rifting
    225428,  -- Scroll of Town Portal: Shala'nir
    225434,  -- Scroll of Town Portal: Sashj'tar
    225435,  -- Scroll of Town Portal: Kal'delar
    225436,  -- Scroll of Town Portal: Faronaar
    225440,  -- Scroll of Town Portal: Lian'tril
    231054,  -- Violet Seal of the Grand Magus
    231504,  -- Tome of Town Portal (diablo 3 event)
    231505,  -- Scroll of Town Portal (Diablo 3 event)
    250796,  -- Wormhole Generator: Argus
    253937,  -- Flight Master's Whistle
    259731,  -- Scroll of Town Portal (Ar'gorok in Arathi)
    267381,  -- Zuldazar Hearthstone
    278212,  -- Scroll of Town Portal (Stromgarde in Arathi)
    278244,  -- Greatfather Winter's Hearthstone
    278559,  -- Headless Horseman's Hearthstone
    279741,  -- Scroll of Luxurious Recall
    285362,  -- Lunar Elder's Hearthstone
    285424,  -- Peddlefeet's Lovely Hearthstone
    286031,  -- Noble Gardener's Hearthstone
    286331,  -- Fire Eater's Hearthstone
    286353,  -- Brewfest Reveler's Hearthstone
    289283,  -- Commander's Signet of Battle
    289284,  -- Captain's Signet of Command
    291981,  -- Ultrasafe Transporter: Mechagon
    298068,  -- Holographic Digitalization Hearthstone
    299083,  -- Wormhole Generator: Kul Tiras
    299084,  -- Wormhole Generator: Zandalar
    300047,  -- Montebank's Colorful Cloak
    302906,  -- Alluring Bloom
    308742,  -- Eternal Traveler's Hearthstone
    308841,  -- Cracked Hearthstone
    311643,  -- Faol's Hearthstone
    311678,  -- Nexus Teleport Scroll
    311705,  -- Gilded Hearthstone
    311712,  -- Tirisfal Camp Scroll
    311749,  -- Glowing Hearthstone
    311897,  -- Mossy Hearthstone
    324031,  -- Wormhole Generator: Shadowlands
    325624,  -- Cypher of Relocation (Ve'nari's Refuge)
    326064,  -- Night Fae Hearthstone
    335671,  -- Scroll of Teleport: Theater of Pain
    340200,  -- Necrolord Hearthstone
    342122,  -- Venthyr Sinstone
    345393,  -- Kyrian Hearthstone
    346060,  -- Necrolord Hearthstone
    346167,  -- Attendant's Pocket Portal: Bastion
    346168,  -- Attendant's Pocket Portal: Oribos
    346170,  -- Attendant's Pocket Portal: Ardenweald
    346171,  -- Attendant's Pocket Portal: Maldraxxus
    346173,  -- Attendant's Pocket Portal: Revendreth
    363799,  -- Dominated Hearthstone
    366945,  -- Enlightened Hearthstone
    367013,  -- Broker Translocation Matrix
    367891,  -- Cartel Xy's Proof of Initiation
    368788,  -- Lilian's Hearthstone
    375357,  -- Timewalker's Hearthstone
    376300,  -- Ring-Bound Hourglass
    386379,  -- Wyrmhole Generator: Dragon Isles
    390783,  -- Aylaag Windstone Fragment
    391042,  -- Ohn'ir Windsage's Hearthstone
    395792,  -- Thrall's Hearthstone
    396591,  -- Lucky Tortollan Charm
    401802,  -- Stone of the Hearth
    405521,  -- Morqut Hearth Totem
    406714,  -- Scroll of Teleport: Zskera Vaults
    409147,  -- Niffen Diggin' Mitts
    410137,  -- Lost Dragonscale (1)
    410148,  -- Lost Dragonscale (2)
    412555,  -- Path of the Naaru
    420418,  -- Deepdweller's Earthen Hearthstone
    422284,  -- Hearthstone of the Flame
    430265,  -- Tess's Peacebloom
    431644,  -- Stone of the Hearth
    438606,  -- Draenic Hologem
    448126,  -- Generate Wormhole,
    450410,  -- Dalaran Hearthstone (1 charge quest item)
    460271,  -- Teleportation Scroll (1 charge quest item)
    463481,  -- Notorious Thread's Hearthstone
    464106,  -- Relic of Crystal Connections
    467470,  -- Delve-O Bot 7001
    1217281, -- Redeployment Module
    1220729, -- Explosive Hearthstone
    1221356, -- Hellscream's Reach Tabard
    1221357, -- Wrap of Unity: Orgrimmar
    1221359, -- Shroud of Cooperation: Stormwind
    1221360, -- Wrap of Unity: Stormwind
    1223041, -- Gallagio Loyalty Rewards Card
    1225967, -- Nostwin's Voucher
    1234526, -- Delver's Mana-Bound Ethergate
    1239107, -- Shadowguard Translocator
    1240219, -- P.O.S.T. Master's Express Hearthstone
    1242509, -- Cosmic Hearthstone
    1248495, -- Temple of Zin-Malor Scroll
    1250878, -- Timerunner's Hearthstone
    1261979, -- Lightcalled Hearthstone
    1270583, -- Naaru's Enfold
    1270814, -- Preyseeker's Hearthstone
    1273401, -- Corewarden's Hearthstone
}

-- Only toys that return to the player's inn; fixed-destination teleports do not belong here.
-- Verified against item use effects and the HearthRoulette / Random Hearthstone Toy Continued
-- catalogs on 2026-09-29. Keep their cast spells in hearthStoneSpellID for UseHS completion.
APR.hearthStoneToyItemIDs = {
    54452,  -- Ethereal Portal
    64488,  -- The Innkeeper's Daughter
    93672,  -- Dark Portal
    142542, -- Tome of Town Portal
    162973, -- Greatfather Winter's Hearthstone
    163045, -- Headless Horseman's Hearthstone
    165669, -- Lunar Elder's Hearthstone
    165670, -- Peddlefeet's Lovely Hearthstone
    165802, -- Noble Gardener's Hearthstone
    166746, -- Fire Eater's Hearthstone
    166747, -- Brewfest Reveler's Hearthstone
    168907, -- Holographic Digitalization Hearthstone
    172179, -- Eternal Traveler's Hearthstone
    180290, -- Night Fae Hearthstone
    182773, -- Necrolord Hearthstone
    183716, -- Venthyr Sinstone
    184353, -- Kyrian Hearthstone
    188952, -- Dominated Hearthstone
    190196, -- Enlightened Hearthstone
    190237, -- Broker Translocation Matrix
    193588, -- Timewalker's Hearthstone
    200630, -- Ohn'ir Windsage's Hearthstone
    206195, -- Path of the Naaru
    208704, -- Deepdweller's Earthen Hearthstone
    209035, -- Hearthstone of the Flame
    210455, -- Draenic Hologem
    212337, -- Stone of the Hearth
    228940, -- Notorious Thread's Hearthstone
    235016, -- Redeployment Module
    236687, -- Explosive Hearthstone
    245970, -- P.O.S.T. Master's Express Hearthstone
    246565, -- Cosmic Hearthstone
    257736, -- Lightcalled Hearthstone
    263489, -- Naaru's Enfold
    263933, -- Preyseeker's Hearthstone
    265100, -- Corewarden's Hearthstone
}

APR.zuldazarHSSpellID = 267381
APR.garrisonHSSpellID = 171253
APR.dalaHSSpellID = 222695

APR.garrisonHSItemID = 110560
