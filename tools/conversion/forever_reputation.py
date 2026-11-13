"""Build APR reputation milestones from reviewed Forever activities.

Explicit authoring tool; never called by tests or addon startup. No third-party
quest IDs or scripts are executed. Source targets are cross-checked against the
local guide data before any output is written.
"""

import argparse
import json
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
STANDINGS = {"Hated": 1, "Hostile": 2, "Unfriendly": 3, "Neutral": 4,
             "Friendly": 5, "Honored": 6, "Revered": 7, "Exalted": 8}


def activity(en, fr):
    return {"enUS": en, "frFR": fr}


# No generic client GlobalString or existing APR instruction describes these
# Forever-specific activities. Proper faction names are translated with titles.
ACTIVITIES = {
    "city": activity(
        "Complete this city's leveling quests first. At level 60, visit its cloth quartermaster: donate 60 Wool Cloth, 60 Silk Cloth, 60 Mageweave Cloth and then 60 Runecloth once to unlock Additional Runecloth. Repeat the donation of 20 Runecloth for 50 reputation until the displayed standing. City reputation also spills over to the other cities of your faction. Buy cloth or farm level 50+ humanoids; repeatable Runecloth requires level 50.",
        "Terminez d'abord les quÃªtes de progression de cette capitale. Au niveau 60, voyez son intendant des Ã©toffes : donnez une fois 60 Ã©toffes de laine, 60 de soie, 60 de tisse-mage puis 60 Ã©toffes runiques pour dÃ©bloquer le don supplÃ©mentaire. RÃ©pÃ©tez le don de 20 Ã©toffes runiques pour 50 points jusqu'au palier affichÃ©. Les autres capitales de votre faction en bÃ©nÃ©ficient aussi. Achetez les Ã©toffes ou tuez des humanoÃ¯des de niveau 50 et plus ; le don rÃ©pÃ©table demande le niveau 50."),
    "av": activity(
        "Enter Alterac Valley from the Alterac Mountains gate or a battlemaster. Complete the camp's introductory quests and recover your banner from the faction cave to unlock the insignia. In each battle capture objectives, kill the enemy captain and general, and return armor scraps and your faction's other supplies. Repeat games and the three-Mark turn-in at your faction's Warbringer or Brigadier General until the displayed standing. Reserve Marks for gear if needed; upgrade your insignia at each new standing. Raid and battleground availability follows the server's release schedule.",
        "Entrez dans la vallÃ©e d'Alterac depuis la porte des montagnes d'Alterac ou un maÃ®tre de guerre. Faites les quÃªtes d'introduction du camp et rÃ©cupÃ©rez votre banniÃ¨re dans la grotte de votre faction pour dÃ©bloquer l'insigne. Ã€ chaque bataille, capturez les objectifs, tuez le capitaine et le gÃ©nÃ©ral adverses, rapportez les morceaux d'armure et les autres fournitures de votre faction. RÃ©pÃ©tez les parties et le don de trois marques au porteguerre ou au gÃ©nÃ©ral de brigade jusqu'au palier affichÃ©. Gardez des marques pour l'Ã©quipement si besoin ; amÃ©liorez l'insigne Ã  chaque palier. L'ouverture dÃ©pend du calendrier du serveur."),
    "ab": activity(
        "Queue for Arathi Basin at Refuge Pointe (Alliance) or Hammerfall (Horde). Take the introductory battle quest, capture bases and hold them to earn resources and reputation. Repeat battles and turn in three Arathi Basin Marks of Honor to your faction's battleground quest giver until the displayed standing. Do the four-base quest at Friendly and the five-base quest at Exalted when offered; keep Marks needed for gear. No Classic resource-to-reputation rate is assumed for Forever.",
        "Inscrivez-vous au bassin d'Arathi au refuge de l'OrniÃ¨re (Alliance) ou Ã  TrÃ©pas-d'Orgrim (Horde). Prenez la quÃªte d'introduction, capturez les bases et gardez-les pour gagner ressources et rÃ©putation. RÃ©pÃ©tez les batailles et rendez trois marques d'honneur du bassin d'Arathi au donneur de quÃªtes de votre faction jusqu'au palier affichÃ©. Faites la quÃªte des quatre bases Ã  Amical et celle des cinq bases Ã  ExaltÃ© lorsqu'elles sont proposÃ©es ; gardez les marques nÃ©cessaires Ã  l'Ã©quipement. Aucun taux de conversion Classic n'est supposÃ© pour Forever."),
    "wsg": activity(
        "Queue for Warsong Gulch at Silverwing Grove in Ashenvale (Alliance) or the Warsong camp in the northern Barrens (Horde). Capture flags with your team and repeat the three Warsong Mark turn-in to the faction's battleground quest giver. Continue until the displayed standing. Marks also buy Forever PvP gear: choose whether to spend or turn them in. Use the actual reputation bar rather than a Classic per-game estimate.",
        "Inscrivez-vous au goulet des Chanteguerres au bosquet d'Aile-argent en Orneval (Alliance) ou au camp Chanteguerre au nord des Tarides (Horde). Capturez les drapeaux avec votre Ã©quipe et rÃ©pÃ©tez le don de trois marques au donneur de quÃªtes du champ de bataille de votre faction. Continuez jusqu'au palier affichÃ©. Les marques achÃ¨tent aussi l'Ã©quipement JcJ de Forever : choisissez entre achat et don. Fiez-vous Ã  la barre rÃ©elle plutÃ´t qu'Ã  une estimation Classic par partie."),
    "islands": activity(
        "From level 30, queue for Darkspear Islands at Merchant Coast (Horde) or Northwatch Hold (Alliance). Take your bracket's battle quests from Nizook Boof or Brelinda McFarry and the Warbringer or Brigadier General. Hold the four bases and carry the central flag with your team. Repeat games and the mark turn-in actually offered by your quest giver until the displayed standing. Only the level 30-39 repeatable is documented: do not assume a higher-bracket quest ID or a fixed reputation rate. Exalted awards the battleground's Legacy challenge.",
        "DÃ¨s le niveau 30, inscrivez-vous aux Ã®les Darkspear Ã  la cÃ´te marchande (Horde) ou au fort du Nord (Alliance). Prenez les quÃªtes de votre tranche auprÃ¨s de Nizook Boof ou Brelinda McFarry et du porteguerre ou gÃ©nÃ©ral de brigade. Gardez les quatre bases et rapportez le drapeau central avec votre Ã©quipe. RÃ©pÃ©tez les parties et le don de marques rÃ©ellement proposÃ© jusqu'au palier affichÃ©. Seule la quÃªte rÃ©pÃ©table des niveaux 30-39 est documentÃ©e : ne supposez ni identifiant de quÃªte supÃ©rieur ni gain fixe. ExaltÃ© valide le dÃ©fi Legacy du champ de bataille."),
    "argent_low": activity(
        "Collect and equip the Argent Dawn Commission from the Bulwark (Horde) or Chillwind Camp (Alliance). Complete the Plaguelands quests and cauldron chain. Kill undead in the Plaguelands and run Stratholme or Scholomance; keep all scourgestones. Turn stones in to an Argent Dawn officer while wearing the Commission and use the Valor Tokens. Ordinary outdoor kills stop at the top of Friendly; use dungeon elites, bosses and stones to reach the next standing.",
        "Obtenez et Ã©quipez le brevet de l'Aube d'argent Ã  la Barricade (Horde) ou au camp du NoroÃ®t (Alliance). Faites les quÃªtes des Maleterres et la suite des chaudrons. Tuez les morts-vivants des Maleterres, parcourez Stratholme ou Scholomance et gardez toutes les pierres du FlÃ©au. Rendez-les Ã  un officier en portant le brevet et utilisez les marques de valeur. Les victimes ordinaires en extÃ©rieur cessent de compter Ã  la fin d'Amical ; utilisez les Ã©lites de donjon, les boss et les pierres pour passer le palier suivant."),
    "argent_high": activity(
        "Run Stratholme and Scholomance with the Argent Dawn Commission equipped. Save and turn in scourgestones, then use the Valor Tokens. Dungeon trash stops before Revered: bosses and stones provide the final point and all progress thereafter. Keep enough Valor Tokens for the Dawn mantle unlocks if wanted; repeat boss runs and stone turn-ins until the displayed standing.",
        "Parcourez Stratholme et Scholomance avec le brevet de l'Aube d'argent Ã©quipÃ©. Gardez et rendez les pierres du FlÃ©au, puis utilisez les marques de valeur. Les monstres ordinaires de donjon cessent de compter avant RÃ©vÃ©rÃ© : les boss et les pierres permettent le dernier point et toute progression ensuite. Gardez des marques pour dÃ©bloquer les mantelets si vous les voulez ; rÃ©pÃ©tez les boss et les dons jusqu'au palier affichÃ©."),
    "bloodsail": activity(
        "Warning: this makes the goblin towns hostile and removes access to their guards, vendors, inns and flight masters. Bind elsewhere and finish goblin business first. Set Booty Bay At War in the reputation panel; kill Booty Bay Bruisers on the path to the smithy above the tunnel. Do not kill Bloodsail pirates. Repeat until the displayed standing. At Neutral, Fleet Master Firallon on the Crimson Veil offers Dressing the Part. At Friendly, take Avast Ye, Scallywag from Pretty Boy Duncan, then Firallon's Avast Ye, Admiral: kill Baron Revilgaz and Fleet Master Seahorn and return for the hat. Friendly is the last reward threshold; Exalted is not supported by the documented available gains.",
        "Attention : les villes gobelines deviennent hostiles et leurs gardes, vendeurs, auberges et maÃ®tres de vol vous sont fermÃ©s. Liez votre pierre ailleurs et terminez vos affaires gobelines. Cochez En guerre pour Baie-du-Butin dans les rÃ©putations ; tuez ses cogneurs sur le chemin de la forge au-dessus du tunnel. Ne tuez pas les pirates de la Voile sanglante. RÃ©pÃ©tez jusqu'au palier affichÃ©. Ã€ Neutre, le maÃ®tre de la flotte Firallon propose la tenue sur le Voile cramoisi. Ã€ Amical, prenez la quÃªte de Duncan Â« le Beau Â», puis celle de Firallon : tuez le baron Revilgaz et le maÃ®tre de la flotte Corne-de-mer et revenez pour le chapeau. Amical est le dernier seuil de rÃ©compense ; les gains documentÃ©s ne permettent pas ExaltÃ©."),
    "brood_low": activity(
        "When Ahn'Qiraj is open, join a Temple of Ahn'Qiraj raid. Trash and the Twin Emperors give Brood reputation only up to 2,999/3,000 Neutral. Save Ancient Qiraji Artifacts and Qiraji Lord's Insignias for that cap. The optional Baristolth and Anachronos scepter chain gives extra reputation but is not required to enter the raid. At the cap, hand an artifact to Andorgos or an insignia to Kandrostrasz inside the Temple to reach Friendly.",
        "Quand Ahn'Qiraj est ouvert, rejoignez un raid au temple d'Ahn'Qiraj. Les monstres ordinaires et les empereurs jumeaux ne donnent de la rÃ©putation que jusqu'Ã  2 999/3 000 Ã  Neutre. Gardez les anciens artÃ©facts qiraji et les insignes de seigneur qiraji pour ce plafond. La suite facultative du sceptre de Baristolth et Anachronos donne aussi de la rÃ©putation mais n'est pas requise pour entrer. Au plafond, rendez un artÃ©fact Ã  Andorgos ou un insigne Ã  Kandrostrasz dans le temple pour passer Amical."),
    "brood_high": activity(
        "Repeat Temple of Ahn'Qiraj raids. Turn Ancient Qiraji Artifacts in to Andorgos (1,000 reputation) and Qiraji Lord's Insignias in to Kandrostrasz (500); C'Thun also continues to count. Temple trash no longer counts at Friendly. Ruins of Ahn'Qiraj bosses provide an alternative, smaller gain. Upgrade your chosen ring with Anachronos in Tanaris at each standing, bringing the previous ring. Continue until the displayed standing; raid access follows the server schedule.",
        "RÃ©pÃ©tez le temple d'Ahn'Qiraj. Rendez les anciens artÃ©facts qiraji Ã  Andorgos (1 000 points) et les insignes Ã  Kandrostrasz (500) ; C'Thun continue aussi de compter. Les monstres ordinaires du temple ne comptent plus Ã  Amical. Les boss des ruines d'Ahn'Qiraj offrent une autre source, plus faible. AmÃ©liorez l'anneau choisi auprÃ¨s d'Anachronos en Tanaris Ã  chaque palier en apportant le prÃ©cÃ©dent. Continuez jusqu'au palier affichÃ© ; l'accÃ¨s aux raids dÃ©pend du calendrier du serveur."),
    "cenarion_low": activity(
        "At Cenarion Hold in Silithus, complete the introductory Twilight quests. Kill Twilight cultists at the camps around the Hold until the top of Friendly, keeping Encrypted Twilight Texts. Use a text turn-in to cross into Honored. Save cultist disguise pieces for wind stones; complete the Hold's outdoor quest chains alongside the kills.",
        "Au fort CÃ©narien en Silithus, faites les premiÃ¨res quÃªtes du CrÃ©puscule. Tuez les sectateurs des camps autour du fort jusqu'Ã  la fin d'Amical en gardant les textes du CrÃ©puscule cryptÃ©s. Rendez des textes pour passer HonorÃ©. Gardez les Ã©lÃ©ments de dÃ©guisement pour les pierres des vents et faites les suites de quÃªtes en extÃ©rieur en parallÃ¨le."),
    "cenarion_high": activity(
        "Turn bundles of ten Encrypted Twilight Texts in to Bor Wildmane at Cenarion Hold. Farm the cultist camps for more texts; ordinary cultist kills no longer count. In a group, use complete Twilight disguises at lesser wind stones for Abyssal Crests and the repeatable crest turn-ins; higher summons need their additional medallions or rings. Ruins of Ahn'Qiraj kills and quests count when the raid opens. Repeat these activities until the displayed standing.",
        "Rendez les textes du CrÃ©puscule cryptÃ©s par dix Ã  Bor Wildmane au fort CÃ©narien. Retournez aux camps pour les textes ; les victimes ordinaires ne comptent plus. En groupe, utilisez un dÃ©guisement complet aux pierres des vents infÃ©rieures pour obtenir les blasons abyssaux et les rendre de faÃ§on rÃ©pÃ©tÃ©e ; les invocations supÃ©rieures demandent aussi leurs mÃ©daillons ou anneaux. Les victimes et quÃªtes des ruines d'Ahn'Qiraj comptent Ã  leur ouverture. RÃ©pÃ©tez ces activitÃ©s jusqu'au palier affichÃ©."),
    "centaur": activity(
        "Choose this clan only: killing its members damages its reputation. Alliance: Captain Pentigast at Nijel's Point; Horde: Gurda Wildmane. Complete Carved Centaur Totems first (five totems), then choose this clan's Buying Friendship and alliance quest. Complete its village and Kolkar quests. Farm Carved Centaur Totems from Kolkar or Maraudine and repeat Economic Warfare, five totems for 750 reputation. Do not rely on rival-clan kills past their uncertain cap; use totems through Exalted. At Honored, add the clan's Valley of Bones quests in Shen'dralas when offered. Magram's Conqueror's Crown prerequisite and helm source are unresolved: the repeatable totems remain the available route.",
        "Choisissez seulement ce clan : tuer ses membres diminue sa rÃ©putation. Alliance : capitaine Pentigast Ã  la combe de Nijel ; Horde : Gurda Wildmane. Rendez d'abord cinq totems sculptÃ©s, puis prenez l'achat d'amitiÃ© et la quÃªte d'alliance de ce clan. Faites les quÃªtes de son village et des Kolkar. RÃ©cupÃ©rez les totems sur les Kolkar ou les Maraudine et rÃ©pÃ©tez la guerre Ã©conomique : cinq totems pour 750 points. Ne comptez pas sur les victimes du clan rival au-delÃ  d'un plafond incertain ; utilisez les totems jusqu'Ã  ExaltÃ©. Ã€ HonorÃ©, ajoutez les quÃªtes de la vallÃ©e des Os en Shen'dralas lorsqu'elles sont proposÃ©es. Le prÃ©requis de couronne des Magram et la source du heaume restent inconnus : les totems rÃ©pÃ©tables restent la voie disponible."),
    "hydraxian_low": activity(
        "Visit Duke Hydraxis on his island in Azshara for the elemental and dungeon introduction, then Agent of Hydraxis. Kill Dust Stormers and Desert Rumblers in Silithus or Greater Obsidian Elementals in the Burning Steppes. They stop one point before Honored: cross the boundary with Huricanian, Lord Incendius in Blackrock Depths, Pyroguard Emberseer, or a Molten Core boss. A Molten Core raid is the faster alternative when available. At Honored, complete Hands of the Enemy and A Hero's Reward for the Aqual Quintessence.",
        "Voyez le duc Hydraxis sur son Ã®le en Azshara pour les quÃªtes d'Ã©lÃ©mentaires et de donjon, puis Agent d'Hydraxis. Tuez les tempÃ©tueux de poussiÃ¨re et les grondeurs du dÃ©sert en Silithus ou les grands Ã©lÃ©mentaires d'obsidienne des steppes Ardentes. Ils s'arrÃªtent un point avant HonorÃ© : passez le seuil avec Huricanian, le seigneur Incendius aux profondeurs de Rochenoire, le Pyrogarde ProphÃ¨te ardent ou un boss du CÅ“ur du Magma. Ce raid est plus rapide lorsqu'il est ouvert. Ã€ HonorÃ©, terminez les mains de l'ennemi et la rÃ©compense du hÃ©ros pour la quintessence aquatique."),
    "hydraxian_mid": activity(
        "Clear Molten Core repeatedly when open. Trash counts only to the last point of Honored; a boss carries you into Revered. Lord Incendius and Pyroguard Emberseer also count while Honored. Return to Duke Hydraxis at Revered for the reusable Eternal Quintessence. Raid lockouts limit repeats.",
        "Parcourez le CÅ“ur du Magma lorsqu'il est ouvert. Les monstres ordinaires comptent seulement jusqu'au dernier point d'HonorÃ© ; un boss permet de passer RÃ©vÃ©rÃ©. Le seigneur Incendius et le Pyrogarde ProphÃ¨te ardent comptent aussi Ã  HonorÃ©. Ã€ RÃ©vÃ©rÃ©, retournez au duc Hydraxis pour la quintessence Ã©ternelle rÃ©utilisable. Les verrouillages limitent les rÃ©pÃ©titions."),
    "hydraxian_high": activity(
        "At Revered, Molten Core trash gives no reputation. Repeat boss clears across raid resets. The seven lesser bosses stop one point before Exalted: Golemagg or Ragnaros supplies the final point. Do not try to finish the bar with outdoor elementals or trash.",
        "Ã€ RÃ©vÃ©rÃ©, les monstres ordinaires du CÅ“ur du Magma ne donnent plus de rÃ©putation. RÃ©pÃ©tez les boss au fil des rÃ©initialisations. Les sept boss mineurs s'arrÃªtent un point avant ExaltÃ© : Golemagg ou Ragnaros permet le dernier point. Les Ã©lÃ©mentaires extÃ©rieurs et les monstres ordinaires ne permettent pas de finir."),
    "kirin": activity(
        "Alliance only. Start An Alarming Request with Emissary Jacques in Southshore, then follow Archmage Modera's image for the sewer key and the City of Dalaran quests. Complete the dungeon and return to Modera and Celindra. At level 33, add Magus Olvek's book quest in Scarlet Monastery Library. Repeat City of Dalaran runs: its kills are reported to give Kirin Tor reputation, but neither rates nor a final cap are verified. Friendly unlocks Alvareaux's Azure recipes; the Exalted tabard is documented, but a continuous path beyond Friendly cannot yet be guaranteed. Alliance Skyborne already start Friendly.",
        "Alliance uniquement. Commencez la demande inquiÃ©tante auprÃ¨s de l'Ã©missaire Jacques Ã  Austrivage, puis suivez l'image de l'archimage Modera pour la clÃ© des Ã©gouts et les quÃªtes de la citÃ© de Dalaran. Faites le donjon et revenez Ã  Modera et Celindra. Au niveau 33, ajoutez la quÃªte du livre de Magus Olvek Ã  la bibliothÃ¨que du monastÃ¨re Ã‰carlate. RÃ©pÃ©tez la citÃ© : les victimes y donnent de la rÃ©putation selon les tÃ©moignages, mais ni les gains ni le plafond final ne sont vÃ©rifiÃ©s. Amical ouvre les recettes azur d'Alvareaux ; le tabard ExaltÃ© est documentÃ©, mais la progression au-delÃ  d'Amical n'est pas garantie. Les Skyborne de l'Alliance commencent dÃ©jÃ  Amicaux."),
    "merchant": activity(
        "Open a sealed writ or fill a Waylaid Crate to obtain your first Shipping Label. Deliver it to Marcy Baker at Three Corners (Alliance) or Dokimi at the Crossroads camp (Horde): 2,000 reputation once. Ordinary filled crates give Merchant's Favor, not reputation. Open Craftsman's Writs, craft or buy their goods and deliver them to the customer named by each writ: 75/125/200 reputation by rank, daily quests. At Friendly, buy a Forged Delivery Receipt for 15 Favor, convert an empty crate and use Crate Return for 50 reputation if the camp offers it. Repeat writs and available crate returns until the displayed standing; never substitute Favor for reputation. Higher-rank customers and the crate-return giver are incomplete in the source data.",
        "Ouvrez une commande scellÃ©e ou remplissez une caisse Ã©garÃ©e pour obtenir votre premiÃ¨re Ã©tiquette d'expÃ©dition. Apportez-la Ã  Marcy Baker aux Trois chemins (Alliance) ou Ã  Dokimi au camp de la CroisÃ©e (Horde) : 2 000 points une seule fois. Les caisses remplies ordinaires donnent de la faveur marchande, pas de rÃ©putation. Ouvrez les commandes d'artisan, fabriquez ou achetez les biens et livrez-les au client indiquÃ© : 75/125/200 points selon le rang, quÃªtes journaliÃ¨res. Ã€ Amical, achetez un reÃ§u falsifiÃ© pour 15 faveurs, convertissez une caisse vide et rendez-la pour 50 points si le camp le propose. RÃ©pÃ©tez commandes et retours disponibles jusqu'au palier affichÃ© ; ne confondez pas faveur et rÃ©putation. Les clients des rangs supÃ©rieurs et le donneur du retour de caisse manquent en partie dans les sources."),
    "nightclaw": activity(
        "Travel to Zephras Isle and follow Lotheluum's Unnerving Silence to Elegael in Shadowgale Forest. Complete her rescue and cultist chain; Vayn Moongaze inside Nightfang Den first wants ten Al'Aketh ears for Mercy Falls on Deaf Ears. After that, farm ears from the cultists at the Shrine of Akir or Gustberry Lowlands and return five at a time for More Al'Aketh Ears. Repeat through the displayed standing. No reputation comes directly from kills. The recorded reward is 1,000 per repeat, but high-level reduction reports conflict: use your actual bar. Vayn sells patterns at Friendly and Honored, the squirrel at Revered and the mantle at Exalted.",
        "Allez sur l'Ã®le de Zephras et suivez la quÃªte de Lotheluum jusqu'Ã  Elegael dans la forÃªt Shadowgale. Faites sa suite de sauvetage et de sectateurs ; Vayn Moongaze, dans l'antre Nightfang, demande d'abord dix oreilles d'Al'Aketh. Ensuite, rÃ©cupÃ©rez des oreilles sur les sectateurs du sanctuaire d'Akir ou des basses-terres Gustberry et rendez-les par cinq Ã  Vayn. RÃ©pÃ©tez jusqu'au palier affichÃ©. Les victimes ne donnent aucune rÃ©putation directe. La rÃ©compense enregistrÃ©e est de 1 000 points, mais les tÃ©moignages sur la rÃ©duction Ã  haut niveau divergent : fiez-vous Ã  votre barre. Vayn vend les patrons Ã  Amical et HonorÃ©, l'Ã©cureuil Ã  RÃ©vÃ©rÃ© et le mantelet Ã  ExaltÃ©."),
    "raven_low": activity(
        "Visit Ravenholdt Manor in the eastern Alterac Mountains. Kill Syndicate in the northern Arathi Highlands or at Durnholde and Strahnbrad. Kills stop at 11,999/12,000 Honored: save Heavy Junkboxes for the final point. Rogues may add their Ravenholdt introduction and class quests; other classes can grind reputation too.",
        "Allez au manoir de Ravenholdt, Ã  l'est des montagnes d'Alterac. Tuez les membres du Syndicat au nord des hautes-terres Arathies, Ã  Fort-de-Durn ou Strahnbrad. Les victimes s'arrÃªtent Ã  11 999/12 000 Ã  HonorÃ© : gardez les coffrets lourds pour le dernier point. Les voleurs peuvent ajouter leurs quÃªtes d'introduction et de classe ; les autres classes peuvent aussi progresser."),
    "raven_high": activity(
        "After Syndicate kills stop at the top of Honored, bring five Heavy Junkboxes per turn-in to Fahrad at Ravenholdt Manor. Forever's documented reward is 50 reputation, not Classic's 75. Rogues pickpocket level 50+ humanoids in Blackrock Depths or Lower Blackrock Spire; other classes buy the boxes. Keep boxes unopened or leave an item inside so they do not vanish. Repeat until Exalted; no Rogue-only route condition is required.",
        "Quand le Syndicat ne compte plus Ã  la fin d'HonorÃ©, rendez les coffrets lourds par cinq Ã  Fahrad au manoir. La rÃ©compense documentÃ©e de Forever est de 50 points, et non les 75 de Classic. Les voleurs les volent aux humanoÃ¯des de niveau 50 et plus aux profondeurs ou au pic infÃ©rieur de Rochenoire ; les autres classes les achÃ¨tent. Ne videz pas les coffrets : gardez-les fermÃ©s ou laissez un objet dedans. RÃ©pÃ©tez jusqu'Ã  ExaltÃ© ; ce parcours n'est pas rÃ©servÃ© aux voleurs."),
    "cartel": activity(
        "Zorbin Fandazzle on the central Feralas road serves even characters hated by goblin towns. Finish Zapped Giants and Fuel for the Zapping first; their repeats unlock at level 55. Shrink living coastal giants with his Ultra-Shrinker, then kill them for residue; kill coastal water elementals for cores. Repeat Again With the Zapped Giants (10 residue) or Refuel for the Zapping (6 cores): 25 reputation to every documented Cartel town. Alternative: free Knot Thimblejack in Dire Maul North using a Gordok Shackle Key. Repeat until the displayed standing. No removed Classic cloth-amends quests are used; Powderfuse spillover remains unverified.",
        "Zorbin Fandazzle, sur la route centrale de FÃ©ralas, sert mÃªme les personnages haÃ¯s des villes gobelines. Terminez d'abord ses quÃªtes des gÃ©ants et de carburant ; leurs rÃ©pÃ©titions se dÃ©bloquent au niveau 55. RÃ©duisez les gÃ©ants vivants de la cÃ´te avec son rÃ©ducteur, puis tuez-les pour les rÃ©sidus ; tuez les Ã©lÃ©mentaires d'eau pour les noyaux. RÃ©pÃ©tez le don de dix rÃ©sidus ou de six noyaux : 25 points Ã  chaque ville documentÃ©e du cartel. Autre choix : libÃ©rez NouÃ© DÃ©dodevie Ã  Hache-tripes Nord avec une clÃ© des entraves gordok. RÃ©pÃ©tez jusqu'au palier affichÃ©. Les anciens dons d'Ã©toffes supprimÃ©s ne sont pas utilisÃ©s ; le partage avec Powderfuse reste non vÃ©rifiÃ©."),
    "thorium_low": activity(
        "Complete Thorium Point's quests, then visit Master Smith Burninate there. While Neutral, repeat Restoring Fiery Flux Supplies: two Incendosaur Scales, one Coal and either four Iron Bars, four Kingsblood or ten Heavy Leather per turn-in. Buy Coal from Burninate and farm the Incendosaurs in the Cauldron; choose the cheapest material option. Stop this activity at Friendly.",
        "Faites les quÃªtes de la halte du Thorium, puis voyez le maÃ®tre forgeron Burninate. Ã€ Neutre, rÃ©pÃ©tez la restauration des rÃ©serves de flux : deux Ã©cailles d'incendosaure, un charbon et au choix quatre barres de fer, quatre sang-royal ou dix cuirs lourds. Achetez le charbon sur place, rÃ©cupÃ©rez les Ã©cailles dans le Chaudron et choisissez les matÃ©riaux les moins chers. Cette activitÃ© s'arrÃªte Ã  Amical."),
    "thorium_mid": activity(
        "At Friendly, Burninate offers Gaining Acceptance: turn in four Dark Iron Residue for 25 reputation. Farm Dark Iron dwarves in Blackrock Depths or buy residue. Repeat until Honored. Lokhtos's ore and Molten Core material turn-ins are also available if cheaper.",
        "Ã€ Amical, Burninate propose de gagner leur confiance : quatre rÃ©sidus de sombrefer pour 25 points. RÃ©cupÃ©rez-les sur les nains sombrefer aux profondeurs de Rochenoire ou achetez-les. RÃ©pÃ©tez jusqu'Ã  HonorÃ©. Les dons de minerai et de matÃ©riaux du CÅ“ur du Magma Ã  Lokhtos sont aussi possibles s'ils coÃ»tent moins cher."),
    "thorium_high": activity(
        "Visit Lokhtos Darkbargainer in the Grim Guzzler inside Blackrock Depths. Reach the East Garrison with the Shadowforge Key or through the Ring of Law, then open the Shadowforge Lock to lower the bridge. Repeat his material turn-ins: 10 Dark Iron Ore for 50 reputation, one Fiery Core, Lava Core or Blood of the Mountain for 200, or two Core Leather for 150. Ore is available before Molten Core opens. Repeat through Exalted; these turn-ins continue past Revered.",
        "Voyez Lokhtos Darkbargainer au Sinistre Ã©cluseur dans les profondeurs de Rochenoire. Gagnez la garnison est avec la clÃ© Ombreforge ou par l'arÃ¨ne, puis actionnez le verrou pour abaisser le pont. RÃ©pÃ©tez les dons : dix minerais de sombrefer pour 50 points, un noyau de feu, de lave ou un sang de la montagne pour 200, ou deux cuirs du Magma pour 150. Le minerai est disponible avant l'ouverture du CÅ“ur du Magma. Continuez jusqu'Ã  ExaltÃ© ; ces dons ne s'arrÃªtent pas Ã  RÃ©vÃ©rÃ©."),
    "timber_low": activity(
        "Start with Grazle in southern Felwood: Timbermaw Ally, Speak to Nafien and Deadwood of the North. Then follow Salfa at the Winterspring tunnel exit for Winterfall Activity. Kill Deadwood or Winterfall furbolgs and keep all Deadwood Headdress Feathers and Winterfall Spirit Beads. Never attack Timbermaw furbolgs in the tunnel. Repeat kills until the displayed standing; turn-ins can provide missing boundary points.",
        "Commencez chez Grazle au sud de Gangrebois : l'alliance grumegueule, le message Ã  Nafien et les Mort-bois du nord. Retrouvez ensuite Salfa Ã  la sortie du tunnel en Berceau-de-l'Hiver pour les Tombe-hiver. Tuez les Mort-bois ou les Tombe-hiver et gardez toutes les plumes et les perles. N'attaquez jamais les Grumegueules du tunnel. Continuez jusqu'au palier affichÃ© ; les dons permettent les points de passage manquants."),
    "timber_high": activity(
        "Ordinary Deadwood and Winterfall kills stop one point before Revered. Use saved feathers at Grazle or Nafien, or beads at Salfa, five for 50 reputation, to cross the boundary and continue through Exalted. Farm more at northern Felpaw Village or Winterfall Village; named furbolgs still count. Complete each ritual totem quest once when available. At Exalted, take The Root of All Evil from Gorn One Eye, summon and defeat Xandivious and return for Defender of the Timbermaw.",
        "Les victimes ordinaires Mort-bois et Tombe-hiver s'arrÃªtent un point avant RÃ©vÃ©rÃ©. Rendez les plumes Ã  Grazle ou Nafien, ou les perles Ã  Salfa, par cinq pour 50 points, pour passer le seuil et continuer jusqu'Ã  ExaltÃ©. RÃ©cupÃ©rez-en au village Gangrepatte nord ou au village Tombe-hiver ; les chefs comptent encore. Faites chaque quÃªte de totem une fois lorsqu'elle est disponible. Ã€ ExaltÃ©, prenez la quÃªte de Gorn One Eye, invoquez et tuez Xandivious puis revenez pour le DÃ©fenseur des Grumegueules."),
    "winter_low": activity(
        "Alliance, level 58+. Visit Rivern Frostwind atop Frostsaber Rock in northern Winterspring. Repeat Frostsaber Provisions: five Shardtooth Meat and five Chillwind Meat, which drop only with the quest active. At 1,500 Neutral, add Winterfall Intrusion: five Shamans and five Ursas at Winterfall Village east of Everlook. Each repeat gives 50 reputation. Take both on each trip and return to Rivern until the displayed standing. Keep Winterfall beads for Timbermaw reputation.",
        "Alliance, niveau 58 et plus. Retrouvez Rivern Frostwind au sommet du rocher des sabres-de-givre au nord du Berceau-de-l'Hiver. RÃ©pÃ©tez les provisions : cinq viandes d'ours et cinq de chimÃ¨re, obtenues uniquement avec la quÃªte active. Ã€ 1 500 Ã  Neutre, ajoutez l'intrusion : cinq chamans et cinq ursas au village Tombe-hiver Ã  l'est de Long-guet. Chaque quÃªte donne 50 points. Prenez les deux Ã  chaque trajet et revenez Ã  Rivern jusqu'au palier affichÃ©. Gardez les perles pour les Grumegueules."),
    "winter_high": activity(
        "Continue Rivern's meat and Winterfall repeats. At Honored, Rampaging Giants also unlocks: four Frostmaul Giants and four Preservers in Frostwhisper Gorge, best done in a group. Rotate the quests according to competition and repeat for 50 reputation each until Exalted. Then buy the Reins of the Winterspring Frostsaber from Rivern; no Horde trainer counterpart is documented for Forever.",
        "Continuez les provisions et les Tombe-hiver de Rivern. Ã€ HonorÃ©, ajoutez les gÃ©ants dÃ©chaÃ®nÃ©s : quatre gÃ©ants et quatre protecteurs Cognegivre dans la gorge du Blanc murmure, de prÃ©fÃ©rence en groupe. Alternez selon l'affluence et rÃ©pÃ©tez les quÃªtes Ã  50 points jusqu'Ã  ExaltÃ©. Achetez ensuite les rÃªnes du sabre-de-givre de Berceau-de-l'Hiver Ã  Rivern ; aucun Ã©quivalent Horde n'est documentÃ© pour Forever."),
    "zandalar": activity(
        "When Zul'Gurub is open, clear it with a raid. Trash and bosses continue to count through Exalted. Save coins and Hakkari bijous. On Yojamba Isle off north-west Stranglethorn, Vinchaxa takes the three matching coin sets; Altar of Zanza bijou destruction and Zandalar Honor Token use add reputation. Start A Bijou for Zanza with Vinchaxa before the repeatable destruction. Repeat raids and token turn-ins until the displayed standing. Upgrade your class necklace at each tier; keep 15 Honor Tokens for an Exalted shoulder signet if wanted.",
        "Ã€ l'ouverture de Zul'Gurub, parcourez le raid. Les monstres et boss continuent de compter jusqu'Ã  ExaltÃ©. Gardez les piÃ¨ces et les bijoux hakkari. Sur l'Ã®le de Yojamba, au nord-ouest de Strangleronce, Vinchaxa prend les trois ensembles de piÃ¨ces ; dÃ©truire les bijoux Ã  l'autel de Zanza et utiliser les marques d'honneur ajoute des points. Faites d'abord sa quÃªte d'introduction des bijoux. RÃ©pÃ©tez raids et dons jusqu'au palier affichÃ©. AmÃ©liorez le collier de classe Ã  chaque palier ; gardez quinze marques pour l'enchantement d'Ã©paules Ã  ExaltÃ© si vous le voulez."),
}


# source slug, faction ID, English title, French title, player faction, entry
# level, map ID, (standing, activity) milestones. Split opposing clans and PvP
# factions explicitly, so one route never requires incompatible reputations.
CATALOG = [
    ("argent-dawn", 529, "Argent Dawn", "Aube d'argent", None, 50, 1422,
     [(5, "argent_low"), (6, "argent_low"), (7, "argent_high"), (8, "argent_high")]),
    ("bloodsail-buccaneers", 87, "Bloodsail Buccaneers", "Voile sanglante", None, 55, 1434,
     [(4, "bloodsail"), (5, "bloodsail")]),
    ("brood-of-nozdormu", 910, "Brood of Nozdormu", "ProgÃ©niture de Nozdormu", None, 60, 1451,
     [(4, "brood_low"), (5, "brood_low"), (6, "brood_high"), (7, "brood_high"), (8, "brood_high")]),
    ("cenarion-circle", 609, "Cenarion Circle", "Cercle cÃ©narien", None, 60, 1451,
     [(6, "cenarion_low"), (7, "cenarion_high"), (8, "cenarion_high")]),
    ("centaur-clans", 92, "Gelkis Clan Centaur", "Centaures du clan Gelkis", None, 30, 1443,
     [(6, "centaur"), (7, "centaur"), (8, "centaur")]),
    ("centaur-clans", 93, "Magram Clan Centaur", "Centaures du clan Magram", None, 30, 1443,
     [(6, "centaur"), (7, "centaur"), (8, "centaur")]),
    ("hydraxian-waterlords", 749, "Hydraxian Waterlords", "Seigneurs des eaux hydraxiens", None, 60, 1447,
     [(6, "hydraxian_low"), (7, "hydraxian_mid"), (8, "hydraxian_high")]),
    ("kirin-tor", 2740, "Kirin Tor", "Kirin Tor", "Alliance", 30, 1416,
     [(5, "kirin")]),
    ("merchants-favor", 2586, "Azeroth Commerce Authority", "AutoritÃ© commerciale d'Azeroth", "Alliance", 10, 1433,
     [(5, "merchant"), (6, "merchant"), (7, "merchant"), (8, "merchant")]),
    ("merchants-favor", 2587, "Durotar Supply and Logistics", "Approvisionnement et logistique de Durotar", "Horde", 10, 1413,
     [(5, "merchant"), (6, "merchant"), (7, "merchant"), (8, "merchant")]),
    ("nightclaw-druids", 2758, "Nightclaw Druids", "Druides Nightclaw", None, 10, 2521,
     [(6, "nightclaw"), (7, "nightclaw"), (8, "nightclaw")]),
    ("ravenholdt", 349, "Ravenholdt", "Ravenholdt", None, 24, 1416,
     [(5, "raven_low"), (6, "raven_low"), (8, "raven_high")]),
    ("thorium-brotherhood", 59, "Thorium Brotherhood", "ConfrÃ©rie du thorium", None, 48, 1427,
     [(5, "thorium_low"), (6, "thorium_mid"), (7, "thorium_high"), (8, "thorium_high")]),
    ("timbermaw-hold", 576, "Timbermaw Hold", "Grumegueules", None, 48, 1448,
     [(3, "timber_low"), (4, "timber_low"), (5, "timber_low"), (6, "timber_low"), (7, "timber_high"), (8, "timber_high")]),
    ("wintersaber-trainers", 589, "Wintersaber Trainers", "Ã‰leveurs de sabres-d'hiver", "Alliance", 58, 1452,
     [(5, "winter_low"), (6, "winter_low"), (8, "winter_high")]),
    ("zandalar-tribe", 270, "Zandalar Tribe", "Tribu Zandalar", None, 60, 1434,
     [(5, "zandalar"), (6, "zandalar"), (7, "zandalar"), (8, "zandalar")]),
]

for slug, fid, en, fr, faction, map_id in [
    ("darnassus", 69, "Darnassus", "Darnassus", "Alliance", 1457),
    ("gnomeregan-exiles", 54, "Gnomeregan Exiles", "ExilÃ©s de Gnomeregan", "Alliance", 1455),
    ("ironforge", 47, "Ironforge", "Forgefer", "Alliance", 1455),
    ("stormwind", 72, "Stormwind", "Hurlevent", "Alliance", 1453),
    ("darkspear-trolls", 530, "Darkspear Trolls", "Trolls Sombrelance", "Horde", 1454),
    ("orgrimmar", 76, "Orgrimmar", "Orgrimmar", "Horde", 1454),
    ("thunder-bluff", 81, "Thunder Bluff", "Les Pitons-du-Tonnerre", "Horde", 1456),
    ("undercity", 68, "Undercity", "Fossoyeuse", "Horde", 1458),
]:
    CATALOG.append((slug, fid, en, fr, faction, 12, map_id, [(6, "city"), (7, "city"), (8, "city")]))

for slug, fid, en, fr, faction, level, map_id, act in [
    ("alterac-valley", 730, "Stormpike Guard", "Garde Foudrepique", "Alliance", 51, 1416, "av"),
    ("alterac-valley", 729, "Frostwolf Clan", "Clan Loup-de-givre", "Horde", 51, 1416, "av"),
    ("arathi-basin", 509, "The League of Arathor", "La Ligue d'Arathor", "Alliance", 20, 1417, "ab"),
    ("arathi-basin", 510, "The Defilers", "Les Profanateurs", "Horde", 20, 1417, "ab"),
    ("warsong-gulch", 890, "Silverwing Sentinels", "Sentinelles d'Aile-argent", "Alliance", 10, 1440, "wsg"),
    ("warsong-gulch", 889, "Warsong Outriders", "Voltigeurs Chanteguerre", "Horde", 10, 1413, "wsg"),
    ("darkspear-islands", 2798, "Darkspear Raiders", "Raiders Darkspear", "Horde", 30, 1413, "islands"),
    ("darkspear-islands", 2799, "Theramore Expeditionary Force", "Corps expÃ©ditionnaire de Theramore", "Alliance", 30, 1413, "islands"),
]:
    CATALOG.append((slug, fid, en, fr, faction, level, map_id, [(n, act) for n in range(5, 9)]))

for fid, en, fr in [(470, "Ratchet", "Cabestan"), (21, "Booty Bay", "Baie-du-Butin"),
                    (369, "Gadgetzan", "Gadgetzan"), (577, "Everlook", "Long-guet")]:
    CATALOG.append(("steamwheedle-cartel", fid, en, fr, None, 50, 1444,
                    [(n, "cartel") for n in range(5, 9)]))


# Established localized faction names; custom names retain their server spelling.
FACTION_NAMES = {
    "deDE": {
        "529": "Argentumdämmerung",
        "87": "Blutsegelbukaniere",
        "910": "Brut Nozdormus",
        "609": "Zirkel des Cenarius",
        "92": "Gelkisklan",
        "93": "Magramklan",
        "749": "Hydraxianer",
        "2740": "Kirin Tor",
        "349": "Rabenholdt",
        "59": "Thoriumbruderschaft",
        "576": "Holzschlundfeste",
        "589": "Wintersäblerausbilder",
        "270": "Stamm der Zandalari",
        "69": "Darnassus",
        "54": "Gnomeregangnome",
        "47": "Eisenschmiede",
        "72": "Sturmwind",
        "530": "Dunkelspeertrolle",
        "76": "Orgrimmar",
        "81": "Donnerfels",
        "68": "Unterstadt",
        "730": "Sturmlanzengarde",
        "729": "Frostwolfklan",
        "509": "Der Bund von Arathor",
        "510": "Die Entweihten",
        "890": "Silberschwingen",
        "889": "Kriegshymnenklan",
        "470": "Ratschet",
        "21": "Beutebucht",
        "369": "Gadgetzan",
        "577": "Ewige Warte"
    },
    "koKR": {
        "529": "은빛 여명회",
        "87": "붉은 해적단",
        "910": "노즈도르무 혈족",
        "609": "세나리온 의회",
        "92": "켄타우로스 - 겔키스 일족",
        "93": "켄타우로스 - 마그람 일족",
        "749": "히드락시안 물의 군주",
        "2740": "키린 토",
        "349": "라벤홀트 암살단",
        "59": "토륨 대장조합",
        "576": "나무구렁 요새",
        "589": "눈호랑이 조련사",
        "270": "잔달라 부족",
        "69": "다르나서스",
        "54": "놈리건",
        "47": "아이언포지",
        "72": "스톰윈드",
        "530": "검은창 트롤",
        "76": "오그리마",
        "81": "썬더 블러프",
        "68": "언더시티",
        "730": "스톰파이크 경비대",
        "729": "서리늑대 부족",
        "509": "아라소르 연맹",
        "510": "포세이큰 파멸단",
        "890": "은빛날개 파수대",
        "889": "전쟁노래 정찰대",
        "470": "톱니항",
        "21": "무법항",
        "369": "가젯잔",
        "577": "눈망루 마을"
    },
    "esES": {
        "529": "El Alba Argenta",
        "87": "Bucaneros Velasangre",
        "910": "Linaje de Nozdormu",
        "609": "Círculo Cenarion",
        "92": "Centauros del clan Gelkis",
        "93": "Centauros del clan Magram",
        "749": "Srs. del Agua de Hydraxis",
        "2740": "Kirin Tor",
        "349": "Ravenholdt",
        "59": "Hermandad del Torio",
        "576": "Bastión Fauces de Madera",
        "589": "Instructores de sableinvernales",
        "270": "Tribu Zandalar",
        "69": "Darnassus",
        "54": "Exiliados de Gnomeregan",
        "47": "Forjaz",
        "72": "Ventormenta",
        "530": "Trols Lanza Negra",
        "76": "Orgrimmar",
        "81": "Cima del Trueno",
        "68": "Entrañas",
        "730": "Guardia Pico Tormenta",
        "729": "Clan Lobo Gélido",
        "509": "Liga de Arathor",
        "510": "Los Rapiñadores",
        "890": "Centinelas Ala de Plata",
        "889": "Escoltas Grito de Guerra",
        "470": "Trinquete",
        "21": "Bahía del Botín",
        "369": "Gadgetzan",
        "577": "Vista Eterna"
    },
    "esMX": {
        "529": "El Alba Argenta",
        "87": "Bucaneros Velasangre",
        "910": "Linaje de Nozdormu",
        "609": "Círculo Cenarion",
        "92": "Centauros del clan Gelkis",
        "93": "Centauros del clan Magram",
        "749": "Srs. del Agua de Hydraxis",
        "2740": "Kirin Tor",
        "349": "Ravenholdt",
        "59": "Hermandad del Torio",
        "576": "Bastión Fauces de Madera",
        "589": "Instructores de sableinvernales",
        "270": "Tribu Zandalar",
        "69": "Darnassus",
        "54": "Exiliados de Gnomeregan",
        "47": "Forjaz",
        "72": "Ventormenta",
        "530": "Trols Lanza Negra",
        "76": "Orgrimmar",
        "81": "Cima del Trueno",
        "68": "Entrañas",
        "730": "Guardia Pico Tormenta",
        "729": "Clan Lobo Gélido",
        "509": "Liga de Arathor",
        "510": "Los Rapiñadores",
        "890": "Centinelas Ala de Plata",
        "889": "Escoltas Grito de Guerra",
        "470": "Trinquete",
        "21": "Bahía del Botín",
        "369": "Gadgetzan",
        "577": "Vista Eterna"
    },
    "ptBR": {
        "529": "Aurora Argêntea",
        "87": "Bucaneiros da Vela Sangrenta",
        "910": "Prole de Nozdormu",
        "609": "Círculo Cenariano",
        "92": "Clã dos Centauros Gelkis",
        "93": "Clã dos Centauros Magram",
        "749": "Senhores das Águas Hidraxianos",
        "2740": "Kirin Tor",
        "349": "Corvoforte",
        "59": "Irmandade do Tório",
        "576": "Domínio dos Presamatos",
        "589": "Treinadores de Sabres-do-inverno",
        "270": "Tribo Zandalar",
        "69": "Darnassus",
        "54": "Gnomeregan",
        "47": "Altaforja",
        "72": "Ventobravo",
        "530": "Trolls Lançanegra",
        "76": "Orgrimmar",
        "81": "Penhasco do Trovão",
        "68": "Cidade Baixa",
        "730": "Guarda de Lançatroz",
        "729": "Clã Lobo do Gelo",
        "509": "A Liga de Arathor",
        "510": "Os Profanadores",
        "890": "Sentinelas da Asa de Prata",
        "889": "Pioneiros do Brado Guerreiro",
        "470": "Vila Catraca",
        "21": "Angra do Butim",
        "369": "Geringontzan",
        "577": "Visteterna"
    },
    "itIT": {
        "529": "Alba d'Argento",
        "87": "Bucanieri Velerosse",
        "910": "Stirpe di Nozdormu",
        "609": "Circolo Cenariano",
        "92": "Centauri del Clan Gelkis",
        "93": "Centauri del Clan Magram",
        "749": "Seguaci di Idraxis",
        "2740": "Kirin Tor",
        "349": "Corvolesto",
        "59": "Fratellanza del Torio",
        "576": "Rifugio dei Mordilegno",
        "589": "Addestratori delle Fiere Glaciali",
        "270": "Tribù Zandalari",
        "69": "Darnassus",
        "54": "Esiliati di Gnomeregan",
        "47": "Forgiardente",
        "72": "Roccavento",
        "530": "Troll Lanciascura",
        "76": "Orgrimmar",
        "81": "Picco del Tuono",
        "68": "Sepulcra",
        "730": "Guardia dei Piccatonante",
        "729": "Clan Lupi Bianchi",
        "509": "Lega di Arathor",
        "510": "Profanatori",
        "890": "Sentinelle Alargentea",
        "889": "Predoni Cantaguerra",
        "470": "Porto Paranco",
        "21": "Baia del Bottino",
        "369": "Meccania",
        "577": "Lungavista"
    },
    "ruRU": {
        "529": "Серебряный Рассвет",
        "87": "Пираты Кровавого Паруса",
        "910": "Род Ноздорму",
        "609": "Круг Кенария",
        "92": "Кентавры из племени Гелкис",
        "93": "Кентавры из племени Маграм",
        "749": "Гидраксианские Повелители Вод",
        "2740": "Кирин-Тор",
        "349": "Черный Ворон",
        "59": "Братство Тория",
        "576": "Древобрюхи",
        "589": "Укротители ледопардов",
        "270": "Племя Зандалари",
        "69": "Дарнас",
        "54": "Изгнанники Гномрегана",
        "47": "Стальгорн",
        "72": "Штормград",
        "530": "Племя Черного Копья",
        "76": "Оргриммар",
        "81": "Громовой Утес",
        "68": "Подгород",
        "730": "Стража Грозовой Вершины",
        "729": "Азеротский клан Северного Волка",
        "509": "Лига Аратора",
        "510": "Осквернители",
        "890": "Среброкрылые Часовые",
        "889": "Всадники Песни Войны",
        "470": "Кабестан",
        "21": "Пиратская Бухта",
        "369": "Прибамбасск",
        "577": "Круговзор"
    },
    "zhCN": {
        "529": "银色黎明",
        "87": "血帆海盗",
        "910": "诺兹多姆的子嗣",
        "609": "塞纳里奥议会",
        "92": "吉尔吉斯半人马",
        "93": "玛格拉姆半人马",
        "749": "海达希亚水元素",
        "2740": "肯瑞托",
        "349": "拉文霍德",
        "59": "瑟银兄弟会",
        "576": "木喉要塞",
        "589": "冬刃豹训练师",
        "270": "赞达拉部族",
        "69": "达纳苏斯",
        "54": "诺莫瑞根流亡者",
        "47": "铁炉堡",
        "72": "暴风城",
        "530": "暗矛巨魔",
        "76": "奥格瑞玛",
        "81": "雷霆崖",
        "68": "幽暗城",
        "730": "雷矛卫队",
        "729": "霜狼氏族",
        "509": "阿拉索联军",
        "510": "污染者",
        "890": "银翼要塞",
        "889": "战歌氏族",
        "470": "棘齿城",
        "21": "藏宝海湾",
        "369": "加基森",
        "577": "永望镇"
    },
    "zhTW": {
        "529": "銀色黎明",
        "87": "血帆海盜",
        "910": "諾茲多姆的子嗣",
        "609": "塞納里奧議會",
        "92": "吉爾吉斯半人馬",
        "93": "瑪格拉姆半人馬",
        "749": "海達希亞水元素",
        "2740": "祈倫托",
        "349": "拉文霍德",
        "59": "瑟銀兄弟會",
        "576": "木喉要塞",
        "589": "冬刃豹訓練師",
        "270": "贊達拉部族",
        "69": "達納蘇斯",
        "54": "諾姆瑞根流亡者",
        "47": "鐵爐堡",
        "72": "暴風城",
        "530": "暗矛食人妖",
        "76": "奧格瑪",
        "81": "雷霆崖",
        "68": "幽暗城",
        "730": "雷矛衛隊",
        "729": "霜狼氏族",
        "509": "阿拉索聯軍",
        "510": "污染者",
        "890": "銀翼哨兵",
        "889": "戰歌先遣騎",
        "470": "棘齒城",
        "21": "藏寶海灣",
        "369": "加基森",
        "577": "永望鎮"
    }
}


# Compact translations retain the actionable method, prerequisite and cap. The
# longer English/French explanations are editorial variants of the same method.
COMPACT_TRANSLATIONS = {
    "deDE": """
city|Erledigt zuerst Stadtquests. Spendet beim Stoffrüstmeister einmal je 60 Wolle, Seide, Magiestoff und Runenstoff. Wiederholt ab Stufe 50 die Spende von 20 Runenstoff bis zum angezeigten Ruf.
av|Erledigt die Einführungsquests am Alteractal-Eingang. Erobert Ziele, besiegt Hauptmann und General, gebt Rüstungsfetzen und je drei Ehrenabzeichen ab. Wiederholt Schlachten bis zum angezeigten Ruf; verbessert eure Insignie.
ab|Meldet euch an der Zuflucht oder in Hammerfall zum Arathibecken an. Haltet Basen, erledigt Lagerquests und gebt je drei Ehrenabzeichen ab. Wiederholt bis zum angezeigten Ruf.
wsg|Meldet euch in Eschental oder im nördlichen Brachland zur Kriegshymnenschlucht an. Erobert Flaggen und gebt je drei Ehrenabzeichen beim Fraktionsquestgeber ab. Wiederholt bis zum angezeigten Ruf.
islands|Ab Stufe 30: Meldet euch bei Merchant Coast oder Northwatch Hold an. Haltet Basen und tragt Flaggen. Wiederholt Schlachten und angebotene Abzeichenquests; höhere Wiederholungsquests und Rufwerte sind unbestätigt.
argent_low|Holt und tragt die Anstecknadel der Argentumdämmerung. Erledigt die Pestland- und Kesselquests. Sammelt Geißelsteine in den Pestländern, Stratholme und Scholomance; gebt sie ab und nutzt die Ehrenmarken. Feldgegner enden vor Wohlwollend.
argent_high|Tragt die Anstecknadel in Stratholme und Scholomance. Wiederholt Bosse und Geißelsteinabgaben, nutzt die Ehrenmarken. Normale Instanzgegner enden vor Respektvoll; Bosse und Steine zählen weiter.
bloodsail|Warnung: Goblinstädte werden feindlich. Erklärt Beutebucht den Krieg und tötet Haudraufs, keine Piraten. Ab Neutral bietet Firallon Kleidung; ab Freundlich startet Duncans Admiralsquest. Ehrfürchtig ist nicht belegt.
brood_low|Wenn Ahn'Qiraj geöffnet ist, tötet Tempelgegner im Schlachtzug. Bewahrt Artefakte und Insignien auf: Gegner enden bei Neutral 2999/3000. Eine Abgabe bei Andorgos oder Kandrostrasz ermöglicht Freundlich.
brood_high|Wiederholt Ahn'Qiraj. Gebt Artefakte bei Andorgos und Insignien bei Kandrostrasz ab; C'Thun zählt weiter. Normale Tempelgegner enden vor Freundlich. Verbessert den gewählten Ring bei Anachronos.
cenarion_low|Erledigt die Einführungsquests der Burg Cenarius. Tötet Zwielichtkultisten und bewahrt Texte und Verkleidungen auf. Am Ende von Freundlich erreicht ihr Wohlwollend durch eine Textabgabe.
cenarion_high|Gebt Bor Wildmähne je zehn verschlüsselte Zwielichttexte. Wiederholt Windsteinbeschwörungen und Wappenabgaben in Gruppen. Auch die Ruinen von Ahn'Qiraj zählen nach Öffnung. Normale Kultistentötungen zählen nicht mehr.
centaur|Wählt diesen Clan; tötet niemals seine Mitglieder. Erledigt zuerst die Totemquest bei Pentigast oder Gurda, dann Freundschaftskauf und Allianzquest. Wiederholt Wirtschaftskrieg mit je fünf Totems bis Ehrfürchtig; Tötungsgrenzen sind unklar.
hydraxian_low|Besucht Herzog Hydraxis in Azshara. Erledigt seine Einführungsquests und tötet Elementare in Silithus. Vor Wohlwollend enden normale Tötungen: Huricanian, Incendius, Glutseher oder ein Kernboss liefert den letzten Punkt.
hydraxian_mid|Wiederholt den Geschmolzenen Kern. Normale Gegner enden vor Respektvoll; ein Boss überbrückt die Grenze. Incendius und Glutseher zählen ebenfalls bei Wohlwollend. Holt bei Respektvoll die Ewige Quintessenz von Hydraxis.
hydraxian_high|Wiederholt Kernbosse über Schlachtzugzurücksetzungen. Normale Gegner zählen nicht mehr. Die sieben kleineren Bosse enden einen Punkt vor Ehrfürchtig: Golemagg oder Ragnaros liefert den letzten Punkt.
kirin|Alliance: Folgt Jacques in Süderstade zu Modera und holt den Kanalschlüssel. Erledigt die Dalaran-Instanzquests und wiederholt die Instanz bis Freundlich. Weitere Rufgrenzen sind unbestätigt; verbündete Skyborne starten Freundlich.
merchant|Gebt das erste Versandetikett im Fraktionshandelslager ab. Erledigt tägliche Handwerksaufträge beim genannten Kunden. Ab Freundlich sind gefälschte Belege und Kistenrückgaben möglich. Gefüllte gewöhnliche Kisten geben Gunst, keinen Ruf. Wiederholt verfügbare Abgaben.
nightclaw|Folgt Lotheluum und Elegael auf Zephras. Gebt Vayn zuerst zehn Al'Aketh-Ohren, danach wiederholt fünf. Sammelt sie bei Kultisten am Schrein von Akir. Tötungen selbst geben keinen Ruf; mögliche Stufenabzüge sind unklar.
raven_low|Besucht Ravenholdt. Tötet Syndikatsmitglieder in Arathi, Durnholde oder Strahnbrad. Sie enden bei Wohlwollend 11999/12000. Bewahrt schwere Plunderkisten für später auf; die Rufroute ist nicht auf Schurken beschränkt.
raven_high|Gebt Fahrad in Ravenholdt wiederholt fünf schwere Plunderkisten: 50 Ruf. Schurken bestehlen Humanoide ab Stufe 50 in Schwarzfelsinstanzen; andere Klassen kaufen Kisten. Nicht vollständig leeren. Wiederholt bis Ehrfürchtig.
cartel|Erledigt Zorbins erste Riesen- und Treibstoffquests in Feralas. Wiederholt ab Stufe 55 die Abgaben von zehn Rückständen oder sechs Kernen. Alternative: Knot in Düsterbruch Nord befreien. Powderfuse-Rufteilung ist unbestätigt.
thorium_low|Besucht den Schmied in der Thoriumspitze. Gebt zwei Incendosaurierschuppen, eine Kohle und vier Eisenbarren, vier Königsblut oder zehn schweres Leder ab. Wiederholt nur bis Freundlich.
thorium_mid|Bei Freundlich nimmt der Schmied in der Thoriumspitze je vier Dunkeleisenrückstände für 25 Ruf. Sammelt sie in den Schwarzfelstiefen oder kauft sie. Wiederholt bis Wohlwollend.
thorium_high|Besucht Lokhtos im Grimmigen Säufer der Schwarzfelstiefen. Öffnet die Schattenschmiedesperre. Wiederholt Erz-, Kern-, Blut- oder Lederabgaben bis Ehrfürchtig; Dunkeleisenerz funktioniert auch vor Öffnung des Geschmolzenen Kerns.
timber_low|Erledigt Grazles, Nafiens und Salfas Einführungsquests. Tötet Totenwald- oder Winterfallfurbolgs, bewahrt Federn und Perlen auf. Tötet keine Holzschlundfurbolgs. Wiederholt bis zum angezeigten Ruf.
timber_high|Normale Furbolgs enden vor Respektvoll. Gebt Federn bei Grazle oder Nafien, Perlen bei Salfa ab: fünf für 50 Ruf. Wiederholt bis Ehrfürchtig; danach Gorns Xandivious-Quest für das Schmuckstück.
winter_low|Alliance, Stufe 58: Besucht Rivern auf dem Frostsäblerfelsen. Wiederholt fünf Bären- und fünf Schimärenfleisch. Ab Neutral 1500 zusätzlich fünf Winterfallschamanen und fünf Ursas. Beute nur bei aktiver Quest; je 50 Ruf.
winter_high|Wiederholt Riverns Fleisch- und Winterfallquests. Ab Wohlwollend kommen vier Frosthagelriesen und vier Bewahrer hinzu, am besten in Gruppe. Je 50 Ruf bis Ehrfürchtig; kauft dann den Frostsäbler bei Rivern.
zandalar|Wiederholt Zul'Gurub nach Öffnung. Gebt Münzsätze bei Vinchaxa auf Yojamba ab. Erledigt zuerst seine Schmuckeinführung, zerstört dann Hakkarischmuck am Zanza-Altar und nutzt Ehrenmarken. Gegner und Abgaben zählen bis Ehrfürchtig.
""",
    "esES": """
city|Completa primero las misiones de la ciudad. Dona una vez 60 de lana, seda, tejido mágico y paño rúnico al intendente. Desde nivel 50, repite donaciones de 20 paños rúnicos hasta el rango indicado.
av|Completa las misiones iniciales de Alterac. Captura objetivos, mata al capitán y general, entrega restos de armadura y tres marcas de honor. Repite batallas hasta el rango indicado y mejora tu insignia.
ab|Entra en Cuenca de Arathi desde Refugio de la Zaga o Sentencia. Mantén bases, completa misiones del campamento y entrega tres marcas de honor. Repite hasta el rango indicado.
wsg|Entra en Garganta Grito de Guerra desde Vallefresno o los Baldíos del norte. Captura banderas y entrega tres marcas al encargado de tu facción. Repite hasta el rango indicado.
islands|Desde nivel 30, entra desde Merchant Coast o Northwatch Hold. Mantén bases y lleva banderas. Repite partidas y entregas de marcas ofrecidas; las repetibles superiores y sus ganancias no están confirmadas.
argent_low|Consigue y equipa la comisión del Alba Argenta. Completa misiones de las Tierras de la Peste y calderos. Recoge piedras en Stratholme y Scholomance, entrégalas y usa las marcas. Las bajas exteriores terminan antes de Honorable.
argent_high|Lleva la comisión en Stratholme y Scholomance. Repite jefes y entregas de piedras; usa las marcas de valor. Los enemigos normales de mazmorra terminan antes de Venerado; jefes y piedras continúan.
bloodsail|Aviso: las ciudades goblin se volverán hostiles. Declara la guerra a Bahía del Botín y mata a sus guardias, no a piratas. Firallon ofrece ropa en Neutral; Duncan inicia el sombrero en Amistoso. Exaltado no está documentado.
brood_low|Cuando abra Ahn'Qiraj, mata enemigos del Templo en banda. Guarda artefactos e insignias: las bajas terminan en Neutral 2999/3000. Entrega uno a Andorgos o Kandrostrasz para llegar a Amistoso.
brood_high|Repite Ahn'Qiraj. Entrega artefactos a Andorgos e insignias a Kandrostrasz; C'Thun sigue contando. Los enemigos normales del Templo terminan antes de Amistoso. Mejora el anillo elegido con Anachronos.
cenarion_low|Completa las misiones iniciales del Fuerte Cenarion. Mata cultores crepusculares y guarda textos y disfraces. Al final de Amistoso, una entrega de textos permite llegar a Honorable.
cenarion_high|Entrega diez textos crepusculares a Bor Ferocrín. Repite invocaciones de piedras de viento y entregas de blasones en grupo. Las Ruinas de Ahn'Qiraj también cuentan al abrir. Las bajas normales de cultores ya no cuentan.
centaur|Elige este clan y no mates a sus miembros. Completa los tótems con Pentigast o Gurda, luego compra de amistad y alianza. Repite guerra económica con cinco tótems hasta Exaltado; el límite de bajas es incierto.
hydraxian_low|Visita al duque Hydraxis en Azshara. Completa la introducción y mata elementales en Silithus. Las bajas normales terminan antes de Honorable: Huricanian, Incendius, Brasadivino o un jefe del Núcleo da el último punto.
hydraxian_mid|Repite Núcleo de Magma. Los enemigos normales terminan antes de Venerado; un jefe cruza el límite. Incendius y Brasadivino también cuentan en Honorable. Recoge la Quintaesencia eterna de Hydraxis en Venerado.
hydraxian_high|Repite jefes del Núcleo entre reinicios de banda. Los enemigos normales ya no cuentan. Los siete jefes menores terminan un punto antes de Exaltado: Golemagg o Ragnaros da el último punto.
kirin|Alianza: sigue a Jacques en Costasur hasta Modera y consigue la llave de las cloacas. Completa las misiones y repite Ciudad de Dalaran hasta Amistoso. El límite posterior es incierto; los Skyborne aliados empiezan Amistosos.
merchant|Entrega la primera etiqueta de envío en el campamento comercial de tu facción. Completa encargos diarios con el cliente indicado. En Amistoso, usa recibos falsos y devoluciones disponibles. Las cajas ordinarias llenas dan favor, no reputación. Repite entregas.
nightclaw|Sigue a Lotheluum y Elegael en Zephras. Entrega diez orejas Al'Aketh a Vayn, luego repite de cinco en cinco. Consíguelas de cultores del santuario de Akir. Las bajas no dan reputación; la reducción por nivel es incierta.
raven_low|Visita Ravenholdt. Mata miembros de la Hermandad en Arathi, Durnholde o Strahnbrad hasta Honorable 11999/12000. Guarda cajas de trastos pesadas para después. La reputación no está limitada a pícaros.
raven_high|Entrega repetidamente cinco cajas de trastos pesadas a Fahrad: 50 puntos. Los pícaros roban a humanoides de nivel 50+ en Roca Negra; otras clases compran cajas. No las vacíes completamente. Continúa hasta Exaltado.
cartel|Completa las primeras misiones de gigantes y combustible de Zorbin en Feralas. Desde nivel 55, repite diez residuos o seis núcleos. Alternativa: libera a Knot en La Masacre norte. El reparto con Powderfuse no está confirmado.
thorium_low|Visita al herrero de Puesto del Torio. Entrega dos escamas de incendosaurio, un carbón y cuatro barras de hierro, cuatro sangrerregia o diez cueros pesados. Repite solamente hasta Amistoso.
thorium_mid|En Amistoso, el herrero de Puesto del Torio acepta cuatro residuos de hierro negro por 25 puntos. Consíguelos en Profundidades de Roca Negra o cómpralos. Repite hasta Honorable.
thorium_high|Visita a Lokhtos en el Tragapenas de Profundidades de Roca Negra. Abre la cerradura Forjatiniebla. Repite entregas de mineral, núcleos, sangre o cuero hasta Exaltado; el mineral funciona antes de abrir Núcleo de Magma.
timber_low|Completa las introducciones de Grazle, Nafien y Salfa. Mata fúrbolgs Muertobosque o Nevada y guarda plumas y abalorios. No mates a los Fauces de Madera. Repite hasta el rango indicado.
timber_high|Los fúrbolgs normales terminan antes de Venerado. Entrega plumas a Grazle o Nafien, abalorios a Salfa: cinco por 50 puntos. Repite hasta Exaltado; después completa la misión de Xandivious de Gorn para el abalorio.
winter_low|Alianza, nivel 58: visita a Rivern en Roca Sable de Hielo. Repite cinco carnes de oso y cinco de quimera. Desde Neutral 1500, añade cinco chamanes y cinco ursas Nevada. Requiere misión activa; 50 puntos cada entrega.
winter_high|Repite las misiones de carne y Nevada de Rivern. En Honorable añade cuatro gigantes y cuatro preservadores Machacahielo, preferiblemente en grupo. Cada misión da 50 puntos; en Exaltado compra el sable a Rivern.
zandalar|Repite Zul'Gurub cuando abra. Entrega juegos de monedas a Vinchaxa en Yojamba. Completa su introducción, destruye preseas Hakkari en el altar de Zanza y usa fichas de honor. Bajas y entregas cuentan hasta Exaltado.
""",
    "itIT": """
city|Completa prima le missioni cittadine. Dona una volta 60 lana, seta, telamagica e telarunica all'intendente. Dal livello 50 ripeti donazioni di 20 telarunica fino al grado indicato.
av|Completa l'introduzione di Alterac. Conquista obiettivi, uccidi capitano e generale, consegna frammenti d'armatura e tre marchi d'onore. Ripeti battaglie fino al grado indicato; migliora l'insegna.
ab|Entra nel Bacino d'Arathi da Rifugio o Requie del Martello. Mantieni le basi, completa le missioni e consegna tre marchi. Ripeti fino al grado indicato.
wsg|Entra nella Forra dei Cantaguerra da Valtetra o dalle Savane settentrionali. Cattura bandiere e consegna tre marchi al referente della fazione. Ripeti fino al grado indicato.
islands|Dal livello 30 entra da Merchant Coast o Northwatch Hold. Mantieni basi e trasporta bandiere. Ripeti partite e consegne di marchi offerte; missioni ripetibili superiori e valori di reputazione non sono confermati.
argent_low|Ottieni e indossa il distintivo dell'Alba d'Argento. Completa missioni delle Terre Infette e calderoni. Raccogli pietre a Stratholme e Scholomance, consegnale e usa i gettoni. Le uccisioni esterne terminano prima di Onorato.
argent_high|Indossa il distintivo a Stratholme e Scholomance. Ripeti boss e consegne di pietre, usa i gettoni. I nemici normali delle spedizioni terminano prima di Riverito; boss e pietre continuano.
bloodsail|Attenzione: le città dei goblin diventano ostili. Dichiara guerra a Baia del Bottino e uccidi guardie, non pirati. Firallon offre abiti a Neutrale; Duncan avvia il cappello ad Amichevole. Osannato non è documentato.
brood_low|Quando apre Ahn'Qiraj, uccidi nemici del Tempio in incursione. Conserva manufatti e insegne: le uccisioni terminano a Neutrale 2999/3000. Una consegna ad Andorgos o Kandrostrasz permette Amichevole.
brood_high|Ripeti Ahn'Qiraj. Consegna manufatti ad Andorgos e insegne a Kandrostrasz; C'Thun conta ancora. I nemici normali del Tempio terminano prima di Amichevole. Migliora l'anello scelto da Anachronos.
cenarion_low|Completa le missioni iniziali del Forte Cenariano. Uccidi cultisti del Crepuscolo e conserva testi e travestimenti. Al termine di Amichevole consegna testi per raggiungere Onorato.
cenarion_high|Consegna dieci testi del Crepuscolo a Bor. Ripeti evocazioni alle pietre del vento e consegne di stemmi in gruppo. Le Rovine di Ahn'Qiraj contano all'apertura. Le uccisioni normali dei cultisti non contano più.
centaur|Scegli questo clan e non ucciderne i membri. Completa i totem da Pentigast o Gurda, poi acquisto d'amicizia e alleanza. Ripeti guerra economica con cinque totem fino a Osannato; il limite delle uccisioni è incerto.
hydraxian_low|Visita il duca Hydraxis ad Azshara. Completa l'introduzione e uccidi elementali a Silitus. Si fermano prima di Onorato: Huricanian, Incendius, Ardente o un boss del Nucleo fornisce l'ultimo punto.
hydraxian_mid|Ripeti Nucleo Ardente. I nemici normali terminano prima di Riverito; un boss supera il limite. Incendius e Ardente contano anche a Onorato. A Riverito prendi la Quintessenza Eterna da Hydraxis.
hydraxian_high|Ripeti i boss del Nucleo ai ripristini dell'incursione. I nemici normali non contano più. I sette boss minori terminano un punto prima di Osannato: serve Golemagg o Ragnaros per finirlo.
kirin|Alleanza: segui Jacques a Riva del Sud fino a Modera e ottieni la chiave delle fogne. Completa le missioni e ripeti Città di Dalaran fino ad Amichevole. Il limite successivo è incerto; gli Skyborne alleati iniziano Amichevoli.
merchant|Consegna la prima etichetta al campo commerciale della fazione. Completa le commissioni giornaliere dal cliente indicato. Ad Amichevole usa ricevute false e restituzioni disponibili. Le casse normali piene danno favore, non reputazione. Ripeti le consegne.
nightclaw|Segui Lotheluum ed Elegael a Zephras. Consegna prima dieci orecchie Al'Aketh a Vayn, poi ripeti con cinque. Raccoglile dai cultisti del santuario di Akir. Le uccisioni non danno reputazione; la riduzione per livello è incerta.
raven_low|Visita Ravenholdt. Uccidi membri della Lega ad Arathi, Durnholde o Strahnbrad fino a Onorato 11999/12000. Conserva i forzieri pesanti. La reputazione non è riservata ai ladri.
raven_high|Consegna ripetutamente cinque forzieri pesanti a Fahrad: 50 punti. I ladri derubano umanoidi di livello 50+ a Roccianera; altre classi comprano i forzieri. Non svuotarli completamente. Continua fino a Osannato.
cartel|Completa le prime missioni di giganti e carburante di Zorbin a Feralas. Dal livello 55 ripeti dieci residui o sei nuclei. Alternativa: libera Knot a Maglio Infausto nord. La condivisione con Powderfuse non è confermata.
thorium_low|Visita il fabbro dell'Avamposto del Torio. Consegna due scaglie d'incendosauro, un carbone e quattro lingotti di ferro, quattro Sanguesacro o dieci cuoio pesante. Ripeti solo fino ad Amichevole.
thorium_mid|Ad Amichevole il fabbro dell'Avamposto del Torio accetta quattro residui di Ferroscuro per 25 punti. Trovali nei Sotterranei di Roccianera o comprali. Ripeti fino a Onorato.
thorium_high|Visita Lokhtos al Torvo Beone nei Sotterranei di Roccianera. Apri il meccanismo di Forgiascura. Ripeti consegne di minerale, nuclei, sangue o cuoio fino a Osannato; il minerale funziona prima dell'apertura del Nucleo.
timber_low|Completa le introduzioni di Grazle, Nafien e Salfa. Uccidi Mezzorsi Legnomorto o Freddoinverno e conserva piume e grani. Non uccidere i Mordilegno. Ripeti fino al grado indicato.
timber_high|I Mezzorsi normali terminano prima di Riverito. Consegna piume a Grazle o Nafien, grani a Salfa: cinque per 50 punti. Ripeti fino a Osannato; poi completa la missione Xandivious di Gorn per il monile.
winter_low|Alleanza, livello 58: visita Rivern alla Roccia delle Fiere Glaciali. Ripeti cinque carni d'orso e cinque di chimera. Da Neutrale 1500 aggiungi cinque sciamani e cinque urse Freddoinverno. Serve missione attiva; 50 punti a consegna.
winter_high|Ripeti carne e Freddoinverno di Rivern. A Onorato aggiungi quattro giganti e quattro preservatori Frostmaul, meglio in gruppo. Ogni missione dà 50 punti; a Osannato compra la fiera da Rivern.
zandalar|Ripeti Zul'Gurub all'apertura. Consegna gruppi di monete a Vinchaxa su Yojamba. Completa la sua introduzione, distruggi monili Hakkari all'altare di Zanza e usa gettoni d'onore. Uccisioni e consegne contano fino a Osannato.
""",
    "ptBR": """
city|Complete primeiro as missões da cidade. Doe uma vez 60 lãs, sedas, magitrama e runatrama ao intendente. A partir do nível 50, repita doações de 20 runatramas até o nível de reputação indicado.
av|Complete a introdução de Alterac. Capture objetivos, mate capitão e general, entregue pedaços de armadura e três marcas de honra. Repita batalhas até a reputação indicada e melhore sua insígnia.
ab|Entre na Bacia Arathi pelo Refúgio ou Martelo da Queda. Mantenha bases, complete missões do acampamento e entregue três marcas. Repita até a reputação indicada.
wsg|Entre na Ravina Brado Guerreiro pelo Vale Gris ou norte dos Sertões. Capture bandeiras e entregue três marcas ao responsável da facção. Repita até a reputação indicada.
islands|Do nível 30 em diante, entre por Merchant Coast ou Northwatch Hold. Mantenha bases e leve bandeiras. Repita partidas e entregas oferecidas; missões repetíveis superiores e ganhos não estão confirmados.
argent_low|Obtenha e equipe a Comissão da Aurora Argêntea. Complete missões das Terras Pestilentas e caldeirões. Recolha pedras em Stratholme e Scolomântia, entregue-as e use as marcas. Mortes externas param antes de Honrado.
argent_high|Use a Comissão em Stratholme e Scolomântia. Repita chefes e entregas de pedras; use as marcas de bravura. Inimigos comuns da masmorra param antes de Reverenciado; chefes e pedras continuam.
bloodsail|Aviso: cidades goblins ficarão hostis. Declare guerra a Angra do Butim e mate seus guardas, não piratas. Firallon oferece roupas em Tolerado; Duncan inicia o chapéu em Respeitado. Exaltado não é comprovado.
brood_low|Quando Ahn'Qiraj abrir, mate inimigos do Templo em raide. Guarde artefatos e insígnias: mortes param em Tolerado 2999/3000. Entregue um a Andorgos ou Kandrostrasz para alcançar Respeitado.
brood_high|Repita Ahn'Qiraj. Entregue artefatos a Andorgos e insígnias a Kandrostrasz; C'Thun continua contando. Inimigos comuns do Templo param antes de Respeitado. Melhore o anel escolhido com Anachronos.
cenarion_low|Complete a introdução do Forte Cenariano. Mate sectários do Crepúsculo e guarde textos e disfarces. No fim de Respeitado, entregue textos para alcançar Honrado.
cenarion_high|Entregue dez textos do Crepúsculo a Bor. Repita invocações nas pedras do vento e entregas de brasões em grupo. Ruínas de Ahn'Qiraj também contam quando abrirem. Mortes comuns de sectários não contam mais.
centaur|Escolha este clã e não mate seus membros. Complete os totens com Pentigast ou Gurda, depois compra de amizade e aliança. Repita guerra econômica com cinco totens até Exaltado; o limite de mortes é incerto.
hydraxian_low|Visite o duque Hydraxis em Azshara. Complete a introdução e mate elementais em Silithus. Mortes comuns param antes de Honrado: Huricanian, Incendius, Brasagume ou um chefe do Núcleo fornece o último ponto.
hydraxian_mid|Repita Núcleo Derretido. Inimigos comuns param antes de Reverenciado; um chefe cruza o limite. Incendius e Brasagume também contam em Honrado. Em Reverenciado pegue a Quintessência Eterna com Hydraxis.
hydraxian_high|Repita chefes do Núcleo após reinicializações. Inimigos comuns não contam mais. Os sete chefes menores param um ponto antes de Exaltado: Golemagg ou Ragnaros fornece o último ponto.
kirin|Aliança: siga Jacques em Costa Sul até Modera e obtenha a chave dos esgotos. Complete as missões e repita Cidade de Dalaran até Respeitado. O limite posterior é incerto; Skyborne aliados começam Respeitados.
merchant|Entregue a primeira etiqueta no acampamento comercial da facção. Complete encomendas diárias no cliente indicado. Em Respeitado use recibos falsos e devoluções disponíveis. Caixas comuns cheias dão favor, não reputação. Repita entregas.
nightclaw|Siga Lotheluum e Elegael em Zephras. Entregue dez orelhas Al'Aketh a Vayn, depois repita com cinco. Recolha-as dos sectários do santuário de Akir. Mortes não dão reputação; a redução por nível é incerta.
raven_low|Visite Ravenholdt. Mate membros do Sindicato em Arathi, Durnholde ou Strahnbrad até Honrado 11999/12000. Guarde caixas-fortes pesadas para depois. A reputação não é exclusiva de ladinos.
raven_high|Entregue repetidamente cinco caixas-fortes pesadas a Fahrad: 50 pontos. Ladinos furtam humanoides de nível 50+ em Rocha Negra; outras classes compram caixas. Não as esvazie completamente. Continue até Exaltado.
cartel|Complete as primeiras missões de gigantes e combustível de Zorbin em Feralas. Do nível 55 em diante, repita dez resíduos ou seis núcleos. Alternativa: liberte Knot em Gládio Cruel norte. O compartilhamento com Powderfuse não foi confirmado.
thorium_low|Visite o ferreiro do Posto de Tório. Entregue duas escamas de incendossauro, um carvão e quatro barras de ferro, quatro Sangue-real ou dez couros pesados. Repita somente até Respeitado.
thorium_mid|Em Respeitado, o ferreiro do Posto de Tório aceita quatro resíduos de Ferro Negro por 25 pontos. Consiga-os nas Abissais Negras ou compre-os. Repita até Honrado.
thorium_high|Visite Lokhtos no Glutão Implacável das Abissais Negras. Abra a trava da Forja das Sombras. Repita entregas de minério, núcleos, sangue ou couro até Exaltado; minério funciona antes de abrir Núcleo Derretido.
timber_low|Complete as introduções de Grazle, Nafien e Salfa. Mate pelursos de Lenhavil ou Invernoso e guarde penas e contas. Não mate os Presamatos. Repita até a reputação indicada.
timber_high|Pelursos comuns param antes de Reverenciado. Entregue penas a Grazle ou Nafien, contas a Salfa: cinco por 50 pontos. Repita até Exaltado; depois complete a missão de Xandivious de Gorn para o berloque.
winter_low|Aliança, nível 58: visite Rivern na Rocha Sabre-de-gelo. Repita cinco carnes de urso e cinco de quimera. De Tolerado 1500 em diante, acrescente cinco xamãs e cinco ursas Invernoso. Requer missão ativa; 50 pontos cada entrega.
winter_high|Repita carne e Invernoso de Rivern. Em Honrado acrescente quatro gigantes e quatro preservadores Frostmaul, preferencialmente em grupo. Cada missão dá 50 pontos; em Exaltado compre o sabre de Rivern.
zandalar|Repita Zul'Gurub quando abrir. Entregue conjuntos de moedas a Vinchaxa em Yojamba. Complete a introdução, destrua bijuterias Hakkari no altar de Zanza e use fichas de honra. Mortes e entregas contam até Exaltado.
""",
    "ruRU": """
city|Сначала выполните городские задания. Сдайте интенданту по 60 шерсти, шелка, магической и рунической ткани. С уровня 50 повторяйте сдачу 20 рунической ткани до указанного отношения.
av|Выполните вступительные задания Альтерака. Захватывайте цели, убивайте капитана и генерала, сдавайте обломки брони и по три почетных знака. Повторяйте бои до указанного отношения; улучшайте знак отличия.
ab|Вступайте в Низину Арати из Опорного пункта или Павшего Молота. Удерживайте базы, выполняйте задания лагеря и сдавайте по три знака. Повторяйте до указанного отношения.
wsg|Вступайте в Ущелье Песни Войны из Ясеневого леса или северных Степей. Захватывайте флаги и сдавайте по три знака представителю фракции. Повторяйте до указанного отношения.
islands|С уровня 30 вступайте через Merchant Coast или Northwatch Hold. Удерживайте базы и переносите флаги. Повторяйте бои и доступные сдачи знаков; задания старших диапазонов и величина награды не подтверждены.
argent_low|Получите и наденьте знак Серебряного Рассвета. Выполните задания Чумных земель и котлов. Собирайте камни в Стратхольме и Некроситете, сдавайте их и используйте знаки доблести. Обычные внешние враги перестают давать репутацию перед уважением.
argent_high|Носите знак в Стратхольме и Некроситете. Повторяйте убийства боссов и сдачу камней, используйте знаки доблести. Обычные враги подземелий перестают считаться перед почтением; боссы и камни продолжают.
bloodsail|Внимание: города гоблинов станут враждебными. Объявите войну Пиратской Бухте и убивайте вышибал, не пиратов. При равнодушии Фираллон дает одежду; при дружелюбии Дункан начинает задания шляпы. Превознесение не подтверждено.
brood_low|После открытия Ан'Киража убивайте врагов Храма в рейде. Сохраняйте артефакты и знаки: убийства заканчиваются на равнодушии 2999/3000. Сдача Андоргосу или Кандостразу позволяет достичь дружелюбия.
brood_high|Повторяйте Ан'Кираж. Сдавайте артефакты Андоргосу и знаки Кандостразу; К'Тун продолжает считаться. Обычные враги Храма заканчиваются перед дружелюбием. Улучшайте выбранное кольцо у Анахроноса.
cenarion_low|Выполните начальные задания Крепости Кенария. Убивайте сумеречных культистов, сохраняйте тексты и маскировку. В конце дружелюбия сдайте тексты для перехода к уважению.
cenarion_high|Сдавайте Бору по десять сумеречных текстов. В группе повторяйте призывы у ветровых камней и сдачу гербов. Руины Ан'Киража тоже считаются после открытия. Обычные убийства культистов уже не дают репутацию.
centaur|Выберите этот клан и не убивайте его членов. Выполните тотемы у Пентигаста или Гурды, затем покупку дружбы и союз. Повторяйте экономическую войну за пять тотемов до превознесения; предел убийств неизвестен.
hydraxian_low|Посетите герцога Гидраксиса в Азшаре. Выполните вступление и убивайте элементалей в Силитусе. Обычные убийства заканчиваются перед уважением: последний пункт дает Ураганий, Огнеус, Углевзор или босс Огненных Недр.
hydraxian_mid|Повторяйте Огненные Недра. Обычные враги заканчиваются перед почтением; босс переводит через границу. Огнеус и Углевзор тоже считаются при уважении. При почтении получите у Гидраксиса вечную квинтэссенцию.
hydraxian_high|Повторяйте боссов Недр после обновления рейда. Обычные враги больше не считаются. Семь младших боссов заканчиваются за пункт до превознесения: последний пункт дает Големагг или Рагнарос.
kirin|Альянс: следуйте от Жака в Южнобережье к Модере за ключом канализации. Выполните задания и повторяйте Город Даларан до дружелюбия. Дальнейший предел неизвестен; союзные Skyborne начинают с дружелюбия.
merchant|Сдайте первую этикетку в торговом лагере фракции. Выполняйте ежедневные ремесленные заказы у указанного клиента. При дружелюбии используйте доступные поддельные квитанции и возврат ящиков. Обычные полные ящики дают благосклонность, не репутацию. Повторяйте сдачи.
nightclaw|Следуйте за Lotheluum и Elegael на Zephras. Сдайте Vayn десять ушей Al'Aketh, затем повторяйте по пять. Собирайте их с культистов святилища Akir. Убийства не дают репутацию; снижение за уровень неизвестно.
raven_low|Посетите поместье Черного Ворона. Убивайте Синдикат в Арати, Дарнхольде или Странбраде до уважения 11999/12000. Сохраняйте тяжелые ларцы. Репутация доступна не только разбойникам.
raven_high|Повторно сдавайте Фахраду по пять тяжелых ларцов: 50 очков. Разбойники крадут их у гуманоидов уровня 50+ в Черной горе; остальные покупают. Не опустошайте полностью. Продолжайте до превознесения.
cartel|Выполните первые задания Зорбина на великанов и топливо в Фераласе. С уровня 55 повторяйте сдачу десяти остатков или шести ядер. Альтернатива: освобождайте Уззла в северном Забытом Городе. Репутация Powderfuse не подтверждена.
thorium_low|Посетите кузнеца на Пункте Тория. Сдавайте две чешуи пламезавра, уголь и четыре железных слитка, четыре королевской крови или десять толстой кожи. Повторяйте только до дружелюбия.
thorium_mid|При дружелюбии кузнец Пункта Тория принимает четыре окалины Черного Железа за 25 очков. Собирайте в Глубинах Черной горы или покупайте. Повторяйте до уважения.
thorium_high|Посетите Локтоса в трактире Глубин Черной горы. Откройте механизм Тенегорна. Повторяйте сдачу руды, ядер, крови или кожи до превознесения; руда доступна до открытия Огненных Недр.
timber_low|Выполните вступительные задания Гразла, Нафиэна и Сальфы. Убивайте фурболгов Мертвого Леса или Зимней Спячки, сохраняйте перья и бусы. Не убивайте Древобрюхов. Повторяйте до указанного отношения.
timber_high|Обычные фурболги заканчиваются перед почтением. Сдавайте перья Гразлу или Нафиэну, бусы Сальфе: пять за 50 очков. Повторяйте до превознесения; затем выполните задание Горна на Ксандивиуса ради аксессуара.
winter_low|Альянс, уровень 58: посетите Риверна на скале Ледопардов. Повторяйте по пять мяса медведя и химеры. С равнодушия 1500 добавьте пять шаманов и пять медведей Зимней Спячки. Нужны активные задания; по 50 очков.
winter_high|Повторяйте задания Риверна на мясо и фурболгов. При уважении добавьте четырех великанов и четырех охранителей Ледяного Молота, лучше в группе. Каждое задание дает 50; при превознесении купите ледопарда у Риверна.
zandalar|Повторяйте Зул'Гуруб после открытия. Сдавайте наборы монет Винчаксе на Йоджамбе. Выполните его вступление, уничтожайте драгоценности Хаккари на алтаре Занзы и используйте почетные жетоны. Убийства и сдачи работают до превознесения.
""",
    "koKR": """
city|먼저 도시 퀘스트를 완료하세요. 병참장교에게 양모, 비단, 마법 옷감, 룬무늬 옷감을 각각 60개씩 한 번 기부하세요. 50레벨부터 룬무늬 옷감 20개 기부를 표시된 평판까지 반복하세요.
av|알터랙 입문 퀘스트를 완료하세요. 거점을 점령하고 대장과 장군을 처치하며 방어구 조각과 훈장 세 개를 반납하세요. 표시된 평판까지 전투를 반복하고 계급장을 강화하세요.
ab|임시 주둔지나 해머폴에서 아라시 분지에 참가하세요. 거점을 지키고 야영지 퀘스트와 훈장 세 개 반납을 반복하여 표시된 평판을 달성하세요.
wsg|잿빛 골짜기나 북부 불모의 땅에서 전쟁노래 협곡에 참가하세요. 깃발을 쟁취하고 진영 담당자에게 훈장 세 개를 반납하세요. 표시된 평판까지 반복하세요.
islands|30레벨부터 Merchant Coast나 Northwatch Hold에서 참가하세요. 거점을 지키고 깃발을 운반하세요. 전투와 실제 제공되는 훈장 반납을 반복하세요. 상위 구간 반복 퀘스트와 평판 수치는 미확인입니다.
argent_low|은빛 여명회 위임봉을 받고 착용하세요. 역병지대와 가마솥 퀘스트를 완료하세요. 스트라솔름과 스칼로맨스에서 스컬지석을 모아 반납하고 명예 휘장을 사용하세요. 일반 야외 처치는 우호적 직전에 끝납니다.
argent_high|위임봉을 착용하고 스트라솔름과 스칼로맨스를 반복하세요. 우두머리 처치, 스컬지석 반납, 명예 휘장 사용을 반복하세요. 일반 던전 적은 매우 우호적 직전에 멈추지만 우두머리와 돌은 계속됩니다.
bloodsail|주의: 고블린 도시가 적대적이 됩니다. 무법항에 전쟁을 선포하고 경비병을 처치하되 해적은 죽이지 마세요. 중립에서 피랄론이 의상을, 약간 우호적에서 던컨이 모자 퀘스트를 제공합니다. 확고한 동맹 경로는 확인되지 않았습니다.
brood_low|안퀴라즈 개방 후 사원 공격대에 참가하세요. 적 처치는 중립 2999/3000에서 멈추므로 유물과 휘장을 보관하세요. 안도르고스나 칸드로스트라즈에게 반납하여 약간 우호적으로 넘어가세요.
brood_high|안퀴라즈를 반복하세요. 안도르고스에게 유물, 칸드로스트라즈에게 휘장을 반납하세요. 크툰은 계속 평판을 줍니다. 일반 사원 적은 약간 우호적 전까지입니다. 아나크로노스에게 선택한 반지를 강화하세요.
cenarion_low|세나리온 요새 입문 퀘스트를 완료하세요. 황혼의 망치단을 처치하고 문서와 변장을 보관하세요. 약간 우호적 마지막에는 문서를 반납하여 우호적으로 넘어가세요.
cenarion_high|보르 와일드메인에게 황혼의 문서 열 개씩 반납하세요. 파티로 바람의 돌 소환과 문장 반납을 반복하세요. 안퀴라즈 폐허도 개방 후 이용하세요. 일반 신도 처치는 더 이상 평판을 주지 않습니다.
centaur|이 부족을 선택하고 그 구성원을 죽이지 마세요. 펜티가스트나 구르다의 토템 퀘스트 후 우정 구매와 동맹 퀘스트를 완료하세요. 토템 다섯 개 경제전 반납을 확고한 동맹까지 반복하세요. 처치 한도는 불확실합니다.
hydraxian_low|아즈샤라의 군주 히드락시스를 방문하세요. 입문 퀘스트 후 실리더스 정령을 처치하세요. 일반 처치는 우호적 직전에 멈춥니다. 허리케니안, 인센디우스, 엠버시어 또는 화산 심장부 우두머리로 마지막 점수를 얻으세요.
hydraxian_mid|화산 심장부를 반복하세요. 일반 적은 매우 우호적 직전에 멈추므로 우두머리로 넘어가세요. 우호적에서는 인센디우스와 엠버시어도 가능합니다. 매우 우호적에서 히드락시스의 영원한 정수를 받으세요.
hydraxian_high|공격대 초기화마다 화산 심장부 우두머리를 처치하세요. 일반 적은 평판을 주지 않습니다. 작은 우두머리 일곱은 확고한 동맹 한 점 전에 멈추므로 골레마그나 라그나로스로 마무리하세요.
kirin|얼라이언스: 사우스쇼어의 Jacques에서 모데라까지 따라가 하수도 열쇠를 얻으세요. 퀘스트와 달라란 도시 던전을 약간 우호적까지 반복하세요. 이후 한도는 미확인입니다. 얼라이언스 Skyborne은 이미 약간 우호적입니다.
merchant|첫 배송 표지를 진영 무역 야영지에 반납하세요. 지정 고객의 일일 제작 주문을 완료하세요. 약간 우호적부터 위조 영수증과 가능한 상자 반납을 이용하세요. 일반 완성 상자는 호의만 주며 평판은 없습니다. 반납을 반복하세요.
nightclaw|Zephras의 Lotheluum과 Elegael을 따라가세요. Vayn에게 Al'Aketh 귀를 처음 열 개, 이후 다섯 개씩 반복 반납하세요. Akir 사당 신도에게서 모으세요. 처치 평판은 없으며 고레벨 감소는 불확실합니다.
raven_low|라벤홀트를 방문하세요. 아라시, 던홀드, 스트란브래드의 비밀결사대를 우호적 11999/12000까지 처치하세요. 견고한 보관함은 보관하세요. 도적이 아닌 직업도 평판을 올릴 수 있습니다.
raven_high|파라드에게 견고한 보관함 다섯 개를 반복 반납하여 50점씩 얻으세요. 도적은 검은바위의 50레벨 이상 인간형에게서 훔치고 다른 직업은 구매하세요. 내용물을 완전히 비우지 말고 확고한 동맹까지 반복하세요.
cartel|페랄라스 조르빈의 첫 거인 및 연료 퀘스트를 완료하세요. 55레벨부터 잔류물 열 개 또는 핵 여섯 개 반납을 반복하세요. 혈투의 전장 북쪽에서 노트 구출도 가능합니다. Powderfuse 평판 공유는 미확인입니다.
thorium_low|토륨 조합 거점 대장장이를 방문하세요. 인센도사우루스 비늘 두 개, 석탄 하나와 철 주괴 네 개, 왕꽃잎풀 네 개 또는 질긴 가죽 열 개를 반납하세요. 약간 우호적까지만 반복하세요.
thorium_mid|약간 우호적에서 거점 대장장이에게 검은무쇠 잔류물 네 개씩 반납하여 25점을 얻으세요. 검은바위 나락에서 모으거나 구매하세요. 우호적까지 반복하세요.
thorium_high|검은바위 나락 선술집의 로크토스를 방문하세요. 어둠괴철로 장치를 여세요. 광석, 핵, 피 또는 가죽 반납을 확고한 동맹까지 반복하세요. 검은무쇠 광석은 화산 심장부 개방 전에도 이용할 수 있습니다.
timber_low|그라즐, 나피엔, 살파의 입문 퀘스트를 완료하세요. 마른가지나 겨울눈 펄볼그를 처치하고 깃털과 구슬을 보관하세요. 나무구렁 펄볼그는 죽이지 마세요. 표시된 평판까지 반복하세요.
timber_high|일반 펄볼그는 매우 우호적 직전에 멈춥니다. 그라즐이나 나피엔에게 깃털, 살파에게 구슬을 다섯 개씩 반납하여 50점을 얻으세요. 확고한 동맹 후 고른의 잔디비우스 퀘스트로 장신구를 받으세요.
winter_low|얼라이언스 58레벨: 눈호랑이 바위의 리베른을 방문하세요. 곰과 키메라 고기 다섯 개씩 반복 반납하세요. 중립 1500부터 겨울눈 주술사와 펄볼그 다섯씩 추가하세요. 퀘스트가 활성화되어야 하며 각각 50점입니다.
winter_high|리베른의 고기 및 겨울눈 퀘스트를 반복하세요. 우호적에서 서리망치 거인과 수호자 넷씩 추가되며 파티를 권장합니다. 각각 50점으로 확고한 동맹까지 올린 뒤 리베른에게 눈호랑이를 구매하세요.
zandalar|개방 후 줄구룹을 반복하세요. 요잠바의 빈차샤에게 동전 세트를 반납하세요. 입문 퀘스트 후 잔자의 제단에서 학카리 장신구를 파괴하고 명예 징표를 사용하세요. 처치와 반납은 확고한 동맹까지 유효합니다.
""",
    "zhCN": """
city|先完成主城任务。向军需官各捐赠一次60份毛料、丝绸、魔纹布和符文布。50级起反复捐赠20份符文布，直到显示的声望等级。
av|完成奥特兰克入门任务。占领目标、击杀上尉和将军，交护甲碎片及三枚荣誉奖章。重复战场直到显示的声望等级，并升级徽记。
ab|从避难谷地或落锤镇加入阿拉希盆地。守住据点，完成营地任务，每次交三枚荣誉奖章，直到显示的声望等级。
wsg|从灰谷或贫瘠之地北部加入战歌峡谷。夺取旗帜，向本阵营任务NPC交三枚奖章。重复直到显示的声望等级。
islands|30级起从Merchant Coast或Northwatch Hold加入。守据点并运送旗帜，重复战斗和实际提供的奖章任务。高级区间的重复任务及声望数值尚未确认。
argent_low|领取并装备银色黎明委任徽章。完成瘟疫之地和瘟疫之锅任务。在斯坦索姆、通灵学院收集天灾石并上交，使用勇气勋章。普通野外击杀在尊敬前停止提供声望。
argent_high|装备委任徽章，反复击杀斯坦索姆和通灵学院首领，交天灾石并使用勇气勋章。普通副本怪在崇敬前停止，首领及天灾石继续有效。
bloodsail|警告：地精城市会敌对。对藏宝海湾勾选交战并击杀卫兵，不要杀海盗。中立时找菲拉伦领取服装，友善时找邓肯开始帽子任务。没有已证实的崇拜路线。
brood_low|安其拉开放后参加神殿团队。保存神器和徽记；普通击杀止于中立2999/3000。向安多葛斯或坎多斯特拉兹上交一次即可跨入友善。
brood_high|重复安其拉，向安多葛斯交神器，向坎多斯特拉兹交徽记；克苏恩仍提供声望。神殿普通怪止于友善前。各阶段找阿纳克洛斯升级所选戒指。
cenarion_low|完成塞纳里奥要塞入门任务。击杀暮光信徒并保留密文和伪装。在友善末端交密文以跨入尊敬。
cenarion_high|向鲍尔交十份暮光密文。组队重复风石召唤和徽章上交；安其拉废墟开放后也可使用。普通暮光信徒击杀已不再提供声望。
centaur|选择这个氏族，不要杀它的成员。先向彭迪加斯特或古尔达完成图腾任务，再做购买友谊和结盟。反复交五个图腾进行经济战直至崇拜；击杀上限尚不明确。
hydraxian_low|拜访艾萨拉的海达克西斯公爵。完成入门任务并击杀希利苏斯元素。普通击杀止于尊敬前，最后一点用飓风破坏者、伊森迪奥斯、艾博希尔或熔火之心首领完成。
hydraxian_mid|重复熔火之心。普通怪止于崇敬前，需首领跨越。尊敬阶段伊森迪奥斯和艾博希尔也有效。崇敬时向海达克西斯领取永恒精萃。
hydraxian_high|每次团队重置后重复熔火之心首领。普通怪已无效。七个小首领止于崇拜前一点，最后一点必须用古雷曼格或拉格纳罗斯。
kirin|仅联盟：从南海镇的Jacques跟随任务至茉德拉并取得下水道钥匙。完成任务并重复达拉然城副本至友善。后续上限未确认；联盟Skyborne初始友善。
merchant|把首张运单交给本阵营贸易营地。按订单向指定客户完成每日制作任务。友善后可用伪造收据和实际可交的退箱任务。普通装满的箱子只给商人好感，不给声望。重复有效上交。
nightclaw|在Zephras跟随Lotheluum和Elegael。先给Vayn十只Al'Aketh耳朵，之后每次交五只。从Akir神殿信徒收集。击杀本身不给声望，高等级衰减尚不明确。
raven_low|拜访拉文霍德。击杀阿拉希、敦霍尔德或斯坦恩布莱德的辛迪加，止于尊敬11999/12000。保留重垃圾箱；并非只有盗贼能提升声望。
raven_high|反复向法拉德交五个重垃圾箱，每次50点。盗贼可在黑石副本偷窃50级以上人形生物，其他职业购买。不要完全清空箱子，重复至崇拜。
cartel|先完成菲拉斯索尔宾的巨人和燃料任务。55级起反复交十份残渣或六个核心。也可在厄运之槌北区解救诺特。Powderfuse共享声望尚未证实。
thorium_low|拜访瑟银哨塔铁匠。每次交两份熏火龙鳞片、一份煤，以及四铁锭、四皇血草或十重皮之一。只重复至友善。
thorium_mid|友善时向瑟银哨塔铁匠交四份黑铁残油，每次25点。可在黑石深渊收集或购买，重复至尊敬。
thorium_high|拜访黑石深渊黑铁酒吧的罗克图斯，开启暗炉机关。反复交矿石、核心、山脉之血或熔火犬皮至崇拜。黑铁矿石在熔火之心开放前即可使用。
timber_low|完成格拉兹、纳菲恩和萨尔法的入门任务。击杀死木或冬泉熊怪，保留羽毛和念珠。不要杀木喉熊怪。重复至显示的声望等级。
timber_high|普通熊怪止于崇敬前。向格拉兹或纳菲恩交羽毛，向萨尔法交念珠，每五个50点。重复至崇拜后完成高恩的克萨维斯任务领取饰品。
winter_low|联盟58级：拜访霜刀石上的雷沃。反复交五份熊肉和五份奇美拉肉。中立1500起加上五个冬泉萨满和五个巨熊怪。需接任务才掉落，每次50点。
winter_high|继续雷沃的肉和冬泉任务。尊敬后可加四个霜槌巨人和四个保卫者，建议组队。每次50点至崇拜，再向雷沃购买霜刃豹。
zandalar|祖尔格拉布开放后反复参加。向尤亚姆巴岛的温卡萨交硬币组，先做宝石入门任务，再在赞扎祭坛摧毁哈卡莱宝石并使用荣誉勋章。击杀和上交均有效至崇拜。
""",
    "zhTW": """
city|先完成主城任務。向軍需官各捐贈一次60份毛料、絲綢、魔紋布和符文布。50級起反覆捐贈20份符文布，直到顯示的聲望等級。
av|完成奧特蘭克入門任務。佔領目標、擊殺上尉和將軍，交護甲碎片及三枚榮譽獎章。重複戰場直到顯示的聲望等級，並升級徽記。
ab|從避難谷地或落錘鎮加入阿拉希盆地。守住據點，完成營地任務，每次交三枚榮譽獎章，直到顯示的聲望等級。
wsg|從梣谷或貧瘠之地北部加入戰歌峽谷。奪取旗幟，向本陣營任務NPC交三枚獎章。重複直到顯示的聲望等級。
islands|30級起從Merchant Coast或Northwatch Hold加入。守據點並運送旗幟，重複戰鬥和實際提供的獎章任務。高級區間的重複任務及聲望數值尚未確認。
argent_low|領取並裝備銀色黎明委任徽章。完成瘟疫之地和瘟疫之鍋任務。在斯坦索姆、通靈學院收集天譴石並上交，使用勇氣勳章。普通野外擊殺在尊敬前停止提供聲望。
argent_high|裝備委任徽章，反覆擊殺斯坦索姆和通靈學院首領，交天譴石並使用勇氣勳章。普通副本怪在崇敬前停止，首領及天譴石繼續有效。
bloodsail|警告：哥布林城市會敵對。對藏寶海灣勾選交戰並擊殺衛兵，不要殺海盜。中立時找菲拉倫領取服裝，友善時找鄧肯開始帽子任務。沒有已證實的崇拜路線。
brood_low|安其拉開放後參加神殿團隊。保存神器和徽記；普通擊殺止於中立2999/3000。向安多葛斯或坎多斯特拉茲上交一次即可跨入友善。
brood_high|重複安其拉，向安多葛斯交神器，向坎多斯特拉茲交徽記；克蘇恩仍提供聲望。神殿普通怪止於友善前。各階段找阿納克羅斯升級所選戒指。
cenarion_low|完成塞納里奧要塞入門任務。擊殺暮光信徒並保留密文和偽裝。在友善末端交密文以跨入尊敬。
cenarion_high|向鮑爾交十份暮光密文。組隊重複風石召喚和徽章上交；安其拉廢墟開放後也可使用。普通暮光信徒擊殺已不再提供聲望。
centaur|選擇這個氏族，不要殺它的成員。先向彭迪加斯特或古爾達完成圖騰任務，再做購買友誼和結盟。反覆交五個圖騰進行經濟戰直至崇拜；擊殺上限尚不明確。
hydraxian_low|拜訪艾薩拉的海達克西斯公爵。完成入門任務並擊殺希利蘇斯元素。普通擊殺止於尊敬前，最後一點用颶風破壞者、伊森迪奧斯、艾博希爾或熔火之心首領完成。
hydraxian_mid|重複熔火之心。普通怪止於崇敬前，需首領跨越。尊敬階段伊森迪奧斯和艾博希爾也有效。崇敬時向海達克西斯領取永恆精萃。
hydraxian_high|每次團隊重置後重複熔火之心首領。普通怪已無效。七個小首領止於崇拜前一點，最後一點必須用古雷曼格或拉格納羅斯。
kirin|僅聯盟：從南海鎮的Jacques跟隨任務至茉德拉並取得下水道鑰匙。完成任務並重複達拉然城副本至友善。後續上限未確認；聯盟Skyborne初始友善。
merchant|把首張運單交給本陣營貿易營地。按訂單向指定客戶完成每日製作任務。友善後可用偽造收據和實際可交的退箱任務。普通裝滿的箱子只給商人好感，不給聲望。重複有效上交。
nightclaw|在Zephras跟隨Lotheluum和Elegael。先給Vayn十隻Al'Aketh耳朵，之後每次交五隻。從Akir神殿信徒收集。擊殺本身不給聲望，高等級衰減尚不明確。
raven_low|拜訪拉文霍德。擊殺阿拉希、敦霍爾德或斯坦恩布萊德的辛迪加，止於尊敬11999/12000。保留重垃圾箱；並非只有盜賊能提升聲望。
raven_high|反覆向法拉德交五個重垃圾箱，每次50點。盜賊可在黑石副本偷竊50級以上人形生物，其他職業購買。不要完全清空箱子，重複至崇拜。
cartel|先完成菲拉斯索爾賓的巨人和燃料任務。55級起反覆交十份殘渣或六個核心。也可在厄運之槌北區解救諾特。Powderfuse共享聲望尚未證實。
thorium_low|拜訪瑟銀哨塔鐵匠。每次交兩份燻火龍鱗片、一份煤，以及四鐵錠、四皇血草或十重皮之一。只重複至友善。
thorium_mid|友善時向瑟銀哨塔鐵匠交四份黑鐵殘油，每次25點。可在黑石深淵收集或購買，重複至尊敬。
thorium_high|拜訪黑石深淵黑鐵酒吧的羅克圖斯，開啟暗爐機關。反覆交礦石、核心、山脈之血或熔火犬皮至崇拜。黑鐵礦石在熔火之心開放前即可使用。
timber_low|完成格拉茲、納菲恩和薩爾法的入門任務。擊殺死木或冬泉熊怪，保留羽毛和念珠。不要殺木喉熊怪。重複至顯示的聲望等級。
timber_high|普通熊怪止於崇敬前。向格拉茲或納菲恩交羽毛，向薩爾法交念珠，每五個50點。重複至崇拜後完成高恩的克薩維斯任務領取飾品。
winter_low|聯盟58級：拜訪霜刀石上的雷沃。反覆交五份熊肉和五份奇美拉肉。中立1500起加上五個冬泉薩滿和五個巨熊怪。需接任務才掉落，每次50點。
winter_high|繼續雷沃的肉和冬泉任務。尊敬後可加四個霜槌巨人和四個保衛者，建議組隊。每次50點至崇拜，再向雷沃購買霜刃豹。
zandalar|祖爾格拉布開放後反覆參加。向尤亞姆巴島的溫卡薩交硬幣組，先做寶石入門任務，再在贊扎祭壇摧毀哈卡萊寶石並使用榮譽勳章。擊殺和上交均有效至崇拜。
""",
}


def all_activities():
    result = {key: dict(value) for key, value in ACTIVITIES.items()}
    for locale, block in COMPACT_TRANSLATIONS.items():
        translated = dict(line.split('|', 1) for line in block.strip().splitlines())
        if set(translated) != set(result):
            raise ValueError(f"Activity translation mismatch for {locale}")
        for key, value in translated.items():
            result[key][locale] = value
    for value in result.values():
        value['esMX'] = value['esES']
    return result


CUSTOM_FACTION_NAMES = {
    'deDE': ['Handelsbehörde von Azeroth', 'Versorgung und Logistik von Durotar', 'Nachtklauendruiden', 'Dunkelspeerräuber', 'Expeditionsstreitmacht von Theramore'],
    'esES': ['Autoridad de Comercio de Azeroth', 'Suministros y Logística de Durotar', 'Druidas Garra Nocturna', 'Asaltantes Lanza Negra', 'Fuerza Expedicionaria de Theramore'],
    'itIT': ['Autorità Commerciale di Azeroth', 'Rifornimenti e Logistica di Durotar', 'Druidi Artiglio Notturno', 'Predoni Lanciascura', 'Corpo di Spedizione di Theramore'],
    'ptBR': ['Autoridade Comercial de Azeroth', 'Suprimentos e Logística de Durotar', 'Druidas Garra da Noite', 'Saqueadores Lançanegra', 'Força Expedicionária de Theramore'],
    'ruRU': ['Торговое управление Азерота', 'Снабжение и логистика Дуротара', 'Друиды Ночного Когтя', 'Налетчики Черного Копья', 'Тераморский экспедиционный корпус'],
    'koKR': ['아제로스 상업 협회', '듀로타 보급 및 병참', '밤발톱 드루이드', '검은창 약탈자', '테라모어 원정군'],
    'zhCN': ['艾泽拉斯贸易局', '杜隆塔尔后勤补给局', '夜爪德鲁伊', '暗矛掠夺者', '塞拉摩远征军'],
    'zhTW': ['艾澤拉斯貿易局', '杜洛塔後勤補給局', '夜爪德魯伊', '暗矛掠奪者', '塞拉摩遠征軍'],
}


def localized_name(locale, fid, en, fr):
    if locale == 'frFR':
        return fr
    locale = 'esES' if locale == 'esMX' else locale
    custom_ids = (2586, 2587, 2758, 2798, 2799)
    if fid in custom_ids and locale in CUSTOM_FACTION_NAMES:
        return CUSTOM_FACTION_NAMES[locale][custom_ids.index(fid)]
    return FACTION_NAMES.get(locale, {}).get(str(fid), en)


def read_targets(text):
    """Read only documented reputation declarations, never embedded scripts."""
    return {(int(fid), STANDINGS[standing]) for fid, standing in re.findall(
        r"^\s*rep\s+(\d+)\s+(Hated|Hostile|Unfriendly|Neutral|Friendly|Honored|Revered|Exalted)\b",
        text, re.MULTILINE)}


class MapPoint(tuple):
    """A source map point, converted by APR at route declaration time."""


class WorldPoint(tuple):
    """An existing world point with its navigation map retained separately."""


def point(map_id, x, y):
    return MapPoint((map_id, x, y))


def lua(value):
    if isinstance(value, MapPoint):
        return 'APR.worldCoordinateConverter:ConvertMapCoordinate(' + ', '.join(map(str, value)) + ')'
    if isinstance(value, WorldPoint):
        return lua({'x': value[1], 'y': value[2]})
    if value is True:
        return 'true'
    if value is False:
        return 'false'
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, (list, tuple)):
        return '{ ' + ', '.join(lua(item) for item in value) + ' }'
    if isinstance(value, dict):
        return '{ ' + ', '.join((key if isinstance(key, str) and key.isidentifier() else '[' + lua(key) + ']')
                               + ' = ' + lua(item) for key, item in value.items()) + ' }'
    raise TypeError(f'Unsupported authored value: {value!r}')


def located(step, destination):
    if destination:
        step.update(Coord=destination, Zone=destination[0])
    return step


def quest(qid, giver, objectives=(), receiver=None, filters=None, prerequisite=None,
          npc=None, receiver_npc=None, starter=None, repeatable=False):
    """One native quest traversal, never an invented automatic repeat loop.

    Repeatable quests deliberately have no permanent completion predicates.
    Objective tuples contain the actual quest objective indexes and destinations.
    """
    filters = dict(filters or {})
    pickup = dict(filters, PickUp=[qid], IsQuestNotOnQuest=qid)
    if not repeatable:
        pickup['IsQuestUncompleted'] = qid
    if prerequisite:
        pickup['IsQuestCompleted'] = prerequisite
    if starter:
        pickup.update(Button={str(qid): starter},
                      ItemCount={'itemID': starter, 'count': 1, 'includeBank': False})
    elif giver:
        pickup['Range'] = 5
    if npc:
        pickup['RaidIcon'] = [{'npcID': npc, 'questID': qid}]
    result = [located(pickup, giver)]
    for parts, destination, options in objectives:
        step = dict(filters, Qpart={qid: list(parts)}, IsQuestOnQuest=qid,
                    Not={'IsQuestReadyForTurnIn': qid})
        step.update(options)
        result.append(located(step, destination))
    done = dict(filters, Done=[qid], IsQuestOnQuest=qid)
    if receiver_npc or (npc and not receiver):
        done['RaidIcon'] = [{'npcID': receiver_npc or npc, 'questID': qid}]
    result.append(located(done, receiver or giver))
    return result


def objective(parts, destination, **options):
    return (parts, destination, options)


CITY_POINTS = {
    69: point(1457, 64.02, 23), 54: point(1455, 74.09, 48.22),
    47: point(1455, 43.22, 31.57), 72: point(1453, 53.93, 81.67),
    530: point(1454, 37.7, 87.9), 76: point(1454, 63.6, 51.23),
    81: point(1456, 43.05, 42.72), 68: point(1458, 71.66, 29.23),
}

ACTIVITY_POINTS = {
    'argent_low': point(1422, 36.97, 57.26),
    'argent_high': point(1423, 26.5, 10.4),
    'bloodsail': point(1434, 29, 75.6),
    'brood_low': point(1451, 29, 92.8), 'brood_high': point(1451, 29, 92.8),
    'cenarion_low': point(1451, 39, 44), 'cenarion_high': point(1451, 48.57, 37.78),
    'hydraxian_low': point(1451, 19.84, 22.23),
    'hydraxian_mid': point(1427, 32.1, 94.7), 'hydraxian_high': point(1427, 32.1, 94.7),
    'kirin': point(1416, 8.5, 59.3),
    'nightclaw': point(2521, 63.8, 36.03),
    'raven_low': point(1417, 27.1, 30.6), 'raven_high': point(1416, 84.45, 80.32),
    'cartel': point(1444, 44.81, 43.423),
    'thorium_low': point(1427, 38.77, 28.5), 'thorium_mid': point(1427, 38.77, 28.5),
    # The precise location inside the dungeon is not established here. Point at
    # its entrance rather than fabricate a map pin for the bar.
    'thorium_high': point(1427, 32.1, 94.7),
    'timber_low': point(1448, 63.08, 8.82), 'timber_high': point(1452, 27.74, 34.5),
    'winter_low': point(1452, 49.94, 9.84), 'winter_high': point(1452, 49.94, 9.84),
    'zandalar': WorldPoint((1434, 1295.6, -11840.9)),
}


def native_plan(fid):
    """Reviewed one-time unlocks and initial repeatable traversals by milestone.

    Keys are target standings; 0 runs at entry, 9 after the final milestone.
    No current repeatable turn-in is ever used as a permanent prerequisite.
    """
    plan = {0: []}
    add = lambda steps, before=0: plan.setdefault(before, []).extend(steps)
    if fid == 529:
        alternatives = [5401, 5405, 5503]
        for faction, qid, giver, npc in [
            ('Alliance', 5401, point(1422, 42.97, 83.55), 10840),
            ('Horde', 5405, point(1420, 83.19, 68.45), 10839),
        ]:
            steps = quest(qid, giver, filters={'Faction': faction}, npc=npc)
            steps[0]['Not'] = {'AnyOf': [
                {'IsOneOfQuestsCompleted': alternatives},
                {'ItemCount': {'itemIDs': [12846, 13209, 19812], 'count': 1, 'includeBank': True}},
            ]}
            add(steps)
        add([{'EquipItem': {'itemID': 12846, 'slot': 13},
              'ItemCount': {'itemID': 12846, 'count': 1, 'includeBank': False},
              'Not': {'AnyOf': [{'EquippedItem': {'slot': slot, 'itemID': item}}
                               for slot in (13, 14) for item in (12846, 13209, 19812)]},
              'Note': ['EQUIP_ARGENT_DAWN_COMMISSION_COLLECT_SCOURGESTONES']}])
    elif fid == 609:
        add(quest(8318, point(1451, 48.57, 37.78),
                  [objective([1], point(1451, 39, 44))], npc=15306))
    elif fid == 59:
        add(quest(7722, point(1427, 38.77, 28.5),
                  [objective([1], point(1427, 40.39, 35.73))], npc=14624))
    elif fid == 749:
        duke = point(1447, 79.28, 73.69)
        add(quest(6804, duke, [objective([1], point(1423, 44, 41), Button={'6804-1': 17310})], npc=13278))
        add(quest(6805, duke, [objective([1, 2], point(1451, 19.84, 22.23))], npc=13278))
        # Raid continuation comes after the attainable outdoor Honored stage;
        # it must not prevent players from using the outdoor reputation path.
        steps = quest(6821, duke,
                      [objective([1], point(1428, 26.4, 24.5), GroupTask=6821)], npc=13278)
        steps[0]['IsQuestsCompleted'] = [6804, 6805]
        add(steps, 7)
        add(quest(6822, duke, [objective([1, 2, 3, 4], point(1427, 32.1, 94.7), GroupTask=6822)],
                  prerequisite=6821, npc=13278), 7)
        add(quest(6823, duke, prerequisite=6822, npc=13278), 7)
        add(quest(6824, duke, [objective([1, 2, 3, 4], point(1427, 32.1, 94.7), GroupTask=6824)],
                  prerequisite=6823, npc=13278), 7)
    elif fid == 576:
        grazle, nafien, salfa = point(1448, 50.93, 85.01), point(1448, 64.77, 8.13), point(1452, 27.74, 34.5)
        add(quest(8460, grazle, [objective([1, 2, 3], point(1448, 48.32, 92.99))], npc=11554))
        add(quest(8462, grazle, receiver=nafien, prerequisite=8460, npc=11554, receiver_npc=15395))
        add(quest(8461, nafien, [objective([1, 2, 3], point(1448, 63.08, 8.82))], prerequisite=8462, npc=15395))
        # The hostile tunnel is crossed only after the first attainable standing.
        add(quest(8465, nafien, receiver=salfa, prerequisite=8461, npc=15395, receiver_npc=11556), 4)
        add(quest(8464, salfa, [objective([1, 2, 3], point(1452, 67.03, 35.57))], prerequisite=8465, npc=11556), 4)
    elif fid == 589:
        rivern = point(1452, 49.94, 9.84)
        add(quest(4970, rivern, [objective([1, 2], point(1452, 58, 19))], npc=10618, repeatable=True), 5)
        add(quest(5201, rivern, [objective([1, 2], point(1452, 67.03, 35.57))], npc=10618, repeatable=True), 6)
        add(quest(5981, rivern, [objective([1, 2], point(1452, 62.19, 68.75), GroupTask=5981)],
                  npc=10618, repeatable=True), 8)
    elif fid == 349:
        # The letter is optional and Rogue-only; all classes retain the grind.
        add(quest(6681, None, [objective([1], point(1424, 78.62, 17.96))],
                  receiver=point(1416, 84.45, 80.32), filters={'Class': 'ROGUE'},
                  receiver_npc=6707, starter=17126))
    elif fid == 270:
        add(quest(8240, ACTIVITY_POINTS['zandalar'],
                  [objective([1], None, NoArrow=True,
                             ExtraLineText=['FOREVER_REPUTATION_ACTIVITY_ZANDALAR'])], npc=15070))
    elif fid in (92, 93):
        for faction, totem_quest, buying_quest, giver, npc in [
            ('Alliance', 93224, 93227 if fid == 92 else 93226, point(1443, 66.7, 10.9), 5396),
            ('Horde', 93225, 94873 if fid == 92 else 94872, point(1443, 56.3, 59.7), 5412),
        ]:
            add(quest(totem_quest, giver, [objective([1], point(1443, 69.5, 44))],
                      filters={'Faction': faction}, npc=npc))
            add(quest(buying_quest, giver,
                      receiver=point(1443, 35.6, 92) if fid == 92 else point(1443, 75, 68.2),
                      filters={'Faction': faction}, prerequisite=totem_quest, npc=npc,
                      receiver_npc=253139 if fid == 93 else None))
    elif fid in (470, 21, 369, 577):
        zorbin = point(1444, 44.81, 43.423)
        add(quest(7003, zorbin, [objective([1], point(1444, 37.8, 22), Button={'7003-1': 18904})], npc=14637))
        add(quest(7721, zorbin, [objective([1], point(1444, 34.4, 35.6))], npc=14637))
    elif fid == 2740:
        modera = point(1421, 68.6, 45.2)
        add(quest(92432, point(1424, 48.3, 60.1), receiver=modera, npc=247264, receiver_npc=269127))
        add(quest(92458, modera, [objective([1], point(1416, 8.5, 59.3), GroupTask=92458)],
                  prerequisite=92432, npc=269127))
        add(quest(92457, modera, [objective([1, 2, 3], point(1416, 8.5, 59.3), GroupTask=92457)],
                  prerequisite=92432, npc=269127))
    elif fid == 2758:
        lotheluum, elegael, vayn = point(2521, 63.973, 75.095), point(2521, 61.76, 39.14), point(2521, 63.8, 36.03)
        steps = quest(94484, lotheluum, receiver=elegael, npc=252359, receiver_npc=257944)
        steps[0]['IsQuestUncompleted'] = 94484
        steps[0]['Not'] = {'AnyOf': [{'IsQuestCompleted': 94493}, {'IsQuestOnQuest': 94493}]}
        add(steps)
        ear_steps = quest(93165, vayn, [objective([1], point(2521, 63.835, 37.435))], npc=254151)
        add(ear_steps[:1])
        for qid, destination in [(94485, point(2521, 58.27, 38.33)),
                                 (94486, point(2521, 58.27, 38.33)),
                                 (94487, point(2521, 63.835, 37.435))]:
            steps = quest(qid, elegael, [objective([1], destination)], npc=257944)
            steps[0]['AnyOf'] = [{'IsQuestCompleted': 94484}, {'IsQuestCompleted': 94493}]
            add(steps)
        steps = quest(94488, elegael, [objective([1], point(2521, 65.54, 36.3))], npc=257944)
        steps[0]['IsQuestsCompleted'] = [94485, 94486, 94487]
        add(steps)
        steps = quest(94489, elegael, [objective([2], point(2521, 64.49, 34.74), GossipOptionIDs=[137859])], npc=257944)
        steps[0]['IsQuestsCompleted'] = [94485, 94486, 94487]
        rescues = []
        for count, destination in [(2, point(2521, 64.25, 31.93)),
                                    (4, point(2521, 65.93, 33.55)),
                                    (7, point(2521, 64.745, 34.925))]:
            rescues.append(located({'QpartPart': {94489: [1]}, 'TrigText': f'{count}/',
                                    'IsQuestOnQuest': 94489, 'Not': {'IsQuestReadyForTurnIn': 94489},
                                    'Note': ['NOT_MOVE_DURING_INTERACTION']}, destination))
        steps[1:1] = rescues
        add(steps)
        add([located({'LootItems': [{'itemID': 265476, 'quantity': 1, 'includeBank': False}],
                      'IsQuestUncompleted': 94490, 'IsQuestNotOnQuest': 94490}, point(2521, 65.54, 36.3))])
        add(quest(94490, None, receiver=elegael, starter=265476, receiver_npc=257944))
        add(ear_steps[1:])
        steps = quest(94491, elegael, receiver=lotheluum, npc=257944, receiver_npc=252359)
        steps[0]['IsQuestsCompleted'] = [94488, 94489, 94490]
        add(steps)
    elif fid == 87:
        firallon = point(1434, 30.6, 90.6)
        add(quest(9272, firallon, npc=2546), 5)
        add(quest(1036, point(1434, 27.6, 69.6), receiver=firallon, npc=2545, receiver_npc=2546), 9)
        add(quest(4621, firallon, [objective([1, 2], point(1434, 27.2, 76.9), GroupTask=4621)],
                  prerequisite=1036, npc=2546), 9)
    return plan


def validate_native_quests(entry, source_text):
    declared = {int(match) for match in re.findall(r'^\s*(?:accept|turnin)\s+(\d+)\b', source_text, re.MULTILINE)}
    referenced = set()
    for group in native_plan(entry[1]).values():
        for step in group:
            for action in ('PickUp', 'Done'):
                referenced.update(step.get(action, []))
            referenced.update(step.get('Qpart', {}))
            referenced.update(step.get('QpartPart', {}))
    if referenced - declared:
        raise ValueError(f'Undocumented native quests in {entry[0]}: {sorted(referenced - declared)}')


def render_route(entry):
    slug, fid, en, fr, faction, level, map_id, stages = entry
    key = f"FOREVER_REPUTATION_TITLE_{fid}"
    route_id = f"Forever-Reputation-{fid}"
    lines = ['local L = LibStub("AceLocale-3.0"):GetLocale("APR")', '',
             '-- Generated by tools/conversion/forever_reputation.py; edit the reviewed catalog there.',
             f'APR.RouteQuestStepList["{route_id}"] = {{',
             '    expansion = APR.EXPANSIONS.Forever,',
             '    gameVersion = APR.GAME_VERSIONS.Forever,',
             '    category = APR.CATEGORIES.Reputation,',
             f'    label = L["{key}"],',
             '    autoStartOnMap = false,',
             f'    mapID = {map_id},',
             f'    levelRange = {{ min = {level}, max = 60 }},',
             f'    conditions = {{ MinLevel = {level}' + (f', Faction = "{faction}"' if faction else '') + ' },',
             '    steps = {']
    index = 0
    plan = native_plan(fid)

    def append_native(steps, standing=None):
        nonlocal index
        for authored in steps:
            step = dict(authored)
            if standing:
                step['SkipForReputation'] = {'factionID': fid, 'level': standing, 'type': 'standard'}
            index += 1
            step['_index'] = index
            lines.append('        ' + lua(step) + ',')

    append_native(plan.get(0, []), stages[-1][0])
    for standing, act in stages:
        append_native(plan.get(standing, []), standing)
        index += 1
        lines.extend(['        {',
                      f'            Reputation = {{ factionID = {fid}, level = {standing}, type = APR.REPUTATION_TYPE.Standard }},',
                      f'            ExtraLineText = {{ "FOREVER_REPUTATION_ACTIVITY_{act.upper()}" }},',
                      f'            _index = {index},'])
        destination = CITY_POINTS.get(fid) if act == 'city' else ACTIVITY_POINTS.get(act)
        if act == 'centaur':
            destination = point(1443, 35.6, 92) if fid == 92 else point(1443, 75, 68.2)
        if destination:
            lines.extend([f'            Coord = {lua(destination)},', f'            Zone = {destination[0]},'])
        lines.append('        },')
    append_native(plan.get(9, []))
    lines.extend([f'        {{ RouteCompleted = true, _index = {index + 1} }},', '    },', '}', ''])
    return '\n'.join(lines)


def build(source_dir, output_dir, translations_path):
    """Validate the entire input before writing only explicitly named outputs."""
    activities = all_activities()
    exports = {locale: {} for locale in next(iter(activities.values()))}
    outputs = []
    covered = set()
    seen_ids = set()
    for entry in CATALOG:
        slug, fid, en, fr, faction, level, map_id, stages = entry
        if fid in seen_ids:
            raise ValueError(f"Duplicate faction ID {fid}")
        seen_ids.add(fid)
        source = source_dir / (slug + '.guide')
        source_text = source.read_text(encoding='utf-8-sig')
        targets = read_targets(source_text)
        validate_native_quests(entry, source_text)
        for standing, act in stages:
            if (fid, standing) not in targets:
                raise ValueError(f"Undocumented target {fid}/{standing} in {source}")
            for locale in exports:
                exports[locale][f"FOREVER_REPUTATION_ACTIVITY_{act.upper()}"] = activities[act][locale]
        for locale in exports:
            name = localized_name(locale, fid, en, fr)
            exports[locale][f"FOREVER_REPUTATION_TITLE_{fid}"] = f"Forever - {name}"
        outputs.append(render_route(entry))
        covered.add(slug)
    discovered = {p.stem for p in source_dir.glob('*.guide')}
    if discovered != covered:
        raise ValueError(f"Source coverage changed: missing={discovered-covered}, absent={covered-discovered}")
    output_dir.mkdir(parents=True, exist_ok=True)
    translations_path.parent.mkdir(parents=True, exist_ok=True)
    (output_dir / 'Forever_Reputations.lua').write_text('\n'.join(outputs), encoding='utf-8')
    translations_path.write_text(json.dumps(exports, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return len(outputs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True, help='Directory containing the reviewed .guide data')
    parser.add_argument('--output', type=Path, default=ROOT / 'Routes/Forever/Reputation')
    parser.add_argument('--translations', type=Path,
                        default=ROOT / 'tools/localization/forever-reputation-translations.json')
    args = parser.parse_args()
    count = build(args.source, args.output, args.translations)
    print(f"Wrote {count} reputation routes; shared manifests and addon locales were not modified.")


if __name__ == '__main__':
    main()
