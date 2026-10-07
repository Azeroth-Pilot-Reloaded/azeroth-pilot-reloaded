# APR-Core : architecture et audit

Audit du 8 octobre 2026. Périmètre : **69 fichiers Lua propres au cœur**, 11
entrées de localisation, médias et dépendances chargées. Les définitions de
`Routes/` servent à vérifier les consommateurs ; elles ne sont pas modifiées.
Les changements extérieurs au cœur concernent le manifeste, les tests et les
références de validation nécessaires aux déplacements.

Principe de maintenance : **lisibilité, lisibilité, lisibilité**. Un helper est
partagé lorsqu'il exprime le même contrat pour plusieurs consommateurs. Les
contrôleurs de fenêtres, abonnements et états métier restent dans leur domaine.
Les commentaires expliquent les contraintes et effets de bord ; ils ne répètent
pas les noms des accesseurs.

## Chargement et circulation des données

[`APR.toc`](../APR.toc) définit l'ordre de chargement. Les dossiers décrivent les
responsabilités, pas cet ordre : une fonction peut référencer un module chargé
plus tard si elle n'est appelée qu'après l'initialisation.

1. Bibliothèques, données Farstrider sélectionnées par client et AceLocale.
2. `SecretUtils`, création de l'objet AceAddon `APR`, registre des skins et adaptateur taxi.
3. Helpers, fondations visuelles, moteur de routes et modèles.
4. Configuration, événements, fonctionnalités, fenêtres et intégrations visuelles.
5. Enregistrement des routes du client, puis appel AceAddon à `OnInitialize`.
6. Identité, AceDB et sauvegardes, puis initialisation des fenêtres et abonnements.

```mermaid
flowchart TD
    Settings[Configuration / AceDB] --> Events[Événements regroupés]
    Game[API WoW] --> Events
    Routes[Définitions de routes] --> Engine[RouteManager / DelveRoutes]
    Engine --> Filters[RouteUtils / RouteConditions]
    Filters --> Step[StepUtils : étape en mémoire]
    Events --> Quest[QuestHandler : quêtes et progression]
    Step --> Quest
    Quest --> Current[CurrentStep / Rows / Fillers]
    Engine --> Preview[QuestOrderList / Rows / Support]
    Step --> Navigation[Farstrider / Arrow / Map]
    Navigation --> Taxi[LibTaxiData / HereBeDragons]
    Current --> Registry[SkinRegistry / TextStyles / StatusBars]
    Preview --> Registry
    Registry --> Skins[ElvUI ou EllesmereUI]
```

`GetRouteSteps` construit la liste effective : scénarios, groupes parallèles et
routes temporaires. `GetStep` renvoie une copie superficielle pour les ajustements
de navigation. `GetCurrentStep` résout la progression sauvegardée et partage cette
copie avec la flèche et les événements. **Les tables imbriquées d'une définition
restent en lecture seule.**

## Cartographie des fichiers

### Initialisation et configuration

| Fichier | Responsabilité |
| --- | --- |
| [core/Core.lua](core/Core.lua) | Objet AceAddon, identité, sauvegardes et initialisation des modules. |
| [core/Event.lua](core/Event.lua) | Événements, regroupement des notifications et callbacks différés. |
| [core/Commands.lua](core/Commands.lua) | `/apr` et capture de performances bornée, activée explicitement. |
| [core/VersionCheck.lua](core/VersionCheck.lua) | Versions client/addon et annonces au groupe, sans requêtes web. |
| [config/Config.lua](config/Config.lua) | Défauts AceDB, options AceConfig, profils et bouton de minicarte. |
| [config/Config_Route.lua](config/Config_Route.lua) | Catalogue, recherche, tri, parcours personnalisé et recyclage des lignes. |
| [config/Config_Route_Prefabs.lua](config/Config_Route_Prefabs.lua) | Parcours prédéfinis construits depuis les métadonnées et conditions. |
| [config/LevelProfiles.lua](config/LevelProfiles.lua) | Données des bonus XP et profils de seuils ; aucun rendu. |

### Modèles

| Fichier | Responsabilité |
| --- | --- |
| [data/models/Classes.lua](data/models/Classes.lua) | Identifiants classe/spécialisation et clés de routes indépendantes de la langue. |
| [data/models/Enums.lua](data/models/Enums.lua) | Clients, catégories, extensions et ordres partagés. |
| [data/models/Quest.lua](data/models/Quest.lua) | Priorité des actions principales et règles quêtes/dialogues. |
| [data/models/Spells.lua](data/models/Spells.lua) | Correspondances objets/sorts des pierres de foyer, jouets et buffs. |
| [data/zones/ScenarioEntrances.lua](data/zones/ScenarioEntrances.lua) | Entrées de scénarios pour le guidage extérieur. |

### Fonctionnalités et moteur de routes

| Fichier | Responsabilité et contrat |
| --- | --- |
| [features/questing/RouteManager.lua](features/questing/RouteManager.lua) | Compatibilité, prérequis et cache des étapes effectives ; visibilité distincte de disponibilité. |
| [features/questing/DelveRoutes.lua](features/questing/DelveRoutes.lua) | Gouffres, scénarios et insertion/restauration des routes temporaires. |
| [features/questing/RouteSuggestions.lua](features/questing/RouteSuggestions.lua) | Index des premières quêtes déclenchant une suggestion de route. |
| [features/questing/QuestHandler.lua](features/questing/QuestHandler.lua) | Cache des quêtes, rendu de l'étape et progression automatique par lots. |
| [features/questing/RouteActions.lua](features/questing/RouteActions.lua) | Inventaire, banque, réparation, apprentissage, mort et domptage ; vérification du contexte avant action. |
| [features/questing/Gossip.lua](features/questing/Gossip.lua) | Dialogues automatiques, règles NPC et délais. |
| [features/navigation/Arrow.lua](features/navigation/Arrow.lua) | Orientation, distance, visibilité et arrivée, à cadence configurable. |
| [features/navigation/FlightPath.lua](features/navigation/FlightPath.lua) | Découvertes taxi et sélection du vol demandé par la route. |
| [features/navigation/Map.lua](features/navigation/Map.lua) | Marqueurs et lignes carte/minicarte avec HereBeDragons. |
| [features/navigation/WorldCoordinateConverter.lua](features/navigation/WorldCoordinateConverter.lua) | Conversion/export auteur sur copie détachée ; géométrie des zones de collecte. |
| [features/player/AFK.lua](features/player/AFK.lua) | Compte à rebours et ancrage ; aucun `OnUpdate` une fois arrêté. |
| [features/player/Buff.lua](features/player/Buff.lua) | Buffs de route via AuraContainer ou requêtes individuelles selon les capacités. |
| [features/player/Heirloom.lua](features/player/Heirloom.lua) | Rappels héritages/enchantements et boutons sécurisés réutilisés. |
| [features/player/XPBuffOverlay.lua](features/player/XPBuffOverlay.lua) | Rappels XP applicables, actions sécurisées et masquage persistant. |
| [features/player/Cutscenes.lua](features/player/Cutscenes.lua) | Films/cinématiques ; modificateurs, réglages et `Dontskipvid`. |
| [features/group/Party.lua](features/group/Party.lua) | Progression du groupe, envoi limité en fréquence et fragments entrants. |

### Intégrations

| Fichier | Frontière externe |
| --- | --- |
| [integrations/TaxiData.lua](integrations/TaxiData.lua) | Façade `LibTaxiData_API`, contrôle des capacités et diagnostic au login. |
| [integrations/Farstrider.lua](integrations/Farstrider.lua) | Graphe vers instructions/flèche, cache des chemins et prédicats de compatibilité. |
| [integrations/ForeverTravel.lua](integrations/ForeverTravel.lua) | Liaisons aériennes observées sur Forever, propres au personnage. |
| [integrations/SkinRegistry.lua](integrations/SkinRegistry.lua) | Registre faible des contrôles APR, fournisseur unique et application hors combat. |
| [integrations/ElvUISkin.lua](integrations/ElvUISkin.lua) | Apparence ElvUI et fonds des panneaux ancrés. |
| [integrations/EllesmereUISkin.lua](integrations/EllesmereUISkin.lua) | API publique EUI, polices et couleurs du thème actualisées. |
| [integrations/EllesmereUISettings.lua](integrations/EllesmereUISettings.lua) | Pool AceGUI privé : le skin APR ne se propage pas aux autres addons. |

### Interface

| Fichier | Responsabilité et contrat |
| --- | --- |
| [ui/foundations/TextStyles.lua](ui/foundations/TextStyles.lua) | Héritage des styles, couleurs sémantiques et registre faible des textes/tooltips. |
| [ui/foundations/StatusBars.lua](ui/foundations/StatusBars.lua) | Barres natives ; APR possède les couleurs, les skins fournissent la texture. |
| [ui/route/CurrentStep.lua](ui/route/CurrentStep.lua) | Fenêtre, barres, boutons sécurisés et changements différés après combat. |
| [ui/route/CurrentStepRows.lua](ui/route/CurrentStepRows.lua) | Transactions, rapprochement par clé, recyclage et disposition des lignes. |
| [ui/route/CurrentStepImagePreview.lua](ui/route/CurrentStepImagePreview.lua) | Miniatures et fenêtres réutilisées ; zoom, déplacement et ratio réel. |
| [ui/route/FillersFrame.lua](ui/route/FillersFrame.lua) | Objectifs facultatifs, transaction de contenu et ancrage des panneaux. |
| [ui/route/QuestOrderList.lua](ui/route/QuestOrderList.lua) | Liste complète, deux buffers et publication d'un rendu terminé. |
| [ui/route/QuestOrderListRows.lua](ui/route/QuestOrderListRows.lua) | Présentation des actions futures, sans exécuter d'action métier. |
| [ui/route/QuestOrderListSupport.lua](ui/route/QuestOrderListSupport.lua) | Pool, coroutine, signatures de réputation et défilement. |
| [ui/route/QuestionPopUp.lua](ui/route/QuestionPopUp.lua) | Confirmations, saisies et sélections avec callbacks renouvelés. |
| [ui/route/RouteSelection.lua](ui/route/RouteSelection.lua) | Invitation au choix d'une route quand le parcours est inutilisable. |
| [ui/panels/Coordinates.lua](ui/panels/Coordinates.lua) | Coordonnées destinées aux auteurs et position de fenêtre sauvegardée. |
| [ui/panels/ChangeLog.lua](ui/panels/ChangeLog.lua) | Notes de version et mise en forme. |
| [ui/panels/StatusReport.lua](ui/panels/StatusReport.lua) | Rapport copiable sans modification de progression. |

### Utilitaires partagés

| Fichier | Contrat partagé |
| --- | --- |
| [utils/Utils.lua](utils/Utils.lua) | Tables/chaînes, copie profonde, diagnostics, événements compatibles et fragmentation sortante. |
| [utils/SecretUtils.lua](utils/SecretUtils.lua) | Accessibilité des valeurs/tables et identité sûre ; chargé avant APR. |
| [utils/PlayerUtils.lua](utils/PlayerUtils.lua) | Client, capacités, sorts, ressources, réputation et disponibilité des actions. |
| [utils/ProfileUtils.lua](utils/ProfileUtils.lua) | Scope personnage AceDB et préférences surchargeant le profil. |
| [utils/TextStyleUtils.lua](utils/TextStyleUtils.lua) | Contrôles AceConfig de style ; rendu dans `TextStyles`. |
| [utils/UIUtils.lua](utils/UIUtils.lua) | Frames, déplacement, ancrage, tooltips, images et validation d'assets. |
| [utils/TargetUtils.lua](utils/TargetUtils.lua) | Identité NPC publique, émotes et macro de marqueur de raid. |
| [utils/QuestUtils.lua](utils/QuestUtils.lua) | Titres asynchrones, pool d'acceptation, objectifs et achèvement. |
| [utils/StepUtils.lua](utils/StepUtils.lua) | Étape courante, progression, textes, coordonnées et zones. |
| [utils/RouteUtils.lua](utils/RouteUtils.lua) | Filtres, seuils XP, imports, signatures sauvegardées et clés/libellés. |
| [utils/RouteConditions.lua](utils/RouteConditions.lua) | Compétences et conditions imbriquées pour exécution/prévisualisation. |
| [utils/RouteHashUtils.lua](utils/RouteHashUtils.lua) | Empreinte déterministe des définitions, non cryptographique. |
| [utils/SojournerUtils.lua](utils/SojournerUtils.lua) | Saut de campagne, rappel personnage et cohérence du groupe. |
| [utils/InstanceUtils.lua](utils/InstanceUtils.lua) | Visibilité en instance et préférence initiale du personnage. |
| [utils/NavigationUtils.lua](utils/NavigationUtils.lua) | Corps du joueur et découvertes taxi normalisées. |
| [utils/PlayerPositionUtils.lua](utils/PlayerPositionUtils.lua) | Position et ordre des axes à la frontière WoW/APR. |
| [utils/ZoneDetectionUtils.lua](utils/ZoneDetectionUtils.lua) | Cache de cartes, ascendants/descendants et zone joueur. |
| [utils/BuyMerchantUtils.lua](utils/BuyMerchantUtils.lua) | Quantités achetées et messages de butin localisés. |
| [utils/LootUtils.lua](utils/LootUtils.lua) | Collections, banque mémorisée et valeur de vente, sans vendre. |

## Dépendances, médias et points d'entrée

| Dépendance | Usage |
| --- | --- |
| LibStub / CallbackHandler | Bibliothèques et callbacks internes Ace3/HBD. |
| AceAddon / AceEvent | Modules, cycle de vie et messages de parcours/catalogue. |
| AceDB / AceDBOptions | Profils et scope personnage ; objet vivant `APR.settings.db`. |
| AceConfig / Registry / Dialog / Cmd | Options ; sous-bibliothèques chargées par les XML AceConfig. |
| AceGUI | Options et convertisseur ; recyclage et pool privé pour EUI. |
| AceConsole | Enregistrement de `/apr`. |
| AceLocale | 11 locales, anglais par défaut ; chaînes injectées au packaging. |
| AceSerializer | Sérialisation de progression pour le groupe. |
| HereBeDragons / Pins | Coordonnées et marqueurs carte/minicarte. |
| FarstriderLib / Data | Graphe et données ; manifeste `Standard` ou `Camelot`, puis finalisation. |
| LibTaxiData | Dépendance externe requise par `.pkgmeta`, facultative dans le TOC pour l'ordre de chargement. |
| LibDataBroker / LibDBIcon | Lanceur de minicarte. |
| LibSharedMedia | Résolution des polices. |
| LibWindow | Positions et échelles des fenêtres. |
| ElvUI / EllesmereUI | Facultatifs ; l'absence des deux conserve le rendu natif. |

AceComm, AceBucket, AceHook, AceTab et AceTimer ne sont plus chargés par
`embeds.xml` : aucun consommateur exécuté n'a été trouvé dans APR ou les autres
bibliothèques embarquées. Leurs sources fournisseur restent intactes dans `libs/`.
Les bibliothèques fournisseur ne sont pas renommées ou annotées comme le code APR.

Les huit médias de `assets/` couvrent logo, en-tête, flèche, icône de carte, son
`/apr 42` et trois illustrations `routeHelper/`. Les noms d'illustrations peuvent
venir des routes/du recorder : l'absence d'appel direct dans le cœur ne prouve
pas qu'un média est inutilisé.

Entrées externes : `/apr`, bindings XML, callbacks AceAddon/AceDB, événements WoW,
messages du groupe et imports de routes. `RegisterCustomRoute`, les anciennes
listes plates et `AprRCData.ExtraLineTexts` restent pris en charge. Les noms des
options et SavedVariables sont conservés.

## Sauvegardes et caches

| État | Propriétaire et durée |
| --- | --- |
| `APRSettings` | AceDB : profils visuels/automation et préférences personnage. |
| `APRData` | Progression par `PlayerID`, imports, NPC, état temporaire/parallèle, banque et performances. |
| `APRCustomPath` / `APRZoneCompleted` | Parcours ordonné et routes terminées par personnage. |
| `APRTaxiNodes` / `APRTaxiNodesTimer` | Découvertes et mesures de trajet ; anciens noms normalisés en booléens. |
| `APRScenarioCompleted` / `APRScenarioMapIDCompleted` | Progression des scénarios par personnage. |
| `APRItemLooted` / `APRGossipValidated` | État historique des objets/dialogues ; clés conservées pour les chemins de progression existants. |
| `FarstriderLibData_CharacterSettings` | Sauvegarde personnage de la bibliothèque de déplacement. |
| Caches mémoire | Étapes, titres, XP, cartes, chemins, widgets et skins ; invalidation par leur propriétaire. |

La copie profonde d'import (`DeepCopyTable`) isole les sauvegardes. La copie
superficielle d'exécution (`GetStep`) partage les ajustements de navigation.
Modifier une signature de route peut invalider la progression existante : ce
n'est pas une simple optimisation locale.

## Nettoyages et corrections appliqués

- Six contrôleurs déplacés hors de `utils` : coordonnées, cinématiques,
  suggestions, moteur de routes, gouffres et support de liste.
- Copie profonde commune, avec cycles et références partagées, pour convertisseur,
  imports et profils ; lookup d'étape, bornage, comparaison de listes et noms de sorts partagés.
- Assets dans `UIUtils`, textes d'étapes dans `StepUtils`, capacités objets/sorts
  dans `PlayerUtils`. Recherche textuelle littérale sans motif et validation hexadécimale.
- Suppression des helpers sans consommateur identifié, du suivi de devises sans
  lecteur, des simulations de groupe non exposées et des hooks d'images inaccessibles.
  Les méthodes appelées indirectement par AceAddon sont conservées.
- Renommages : `HasRouteInCustomPath`, `UpdateQpartPartWithQuestText`,
  `HandleMessageFragment`, `UpdatePosition`, `RegisterEvents`, `TableToDebugString`
  et `questOrderListSupport`.
- Fin des globales génériques `SettingsDB`, `LoadedProfileKey`, `UpdateGroupStep` :
  état rattaché à son module ou au scope local.
- Timers annulés via leur handle ; erreurs de callbacks transmises au gestionnaire WoW.
- Signatures de réputation parcourant aussi `AllOf` et `Not` pour invalider les listes périmées.
- Fragments isolés par expéditeur, index/tailles validés, doublons ignorés,
  expiration nettoyée à l'assemblage et arrêt du ticker devenu inutile.
- `Dontskipvid` protège films et cinématiques ; les skips différés revérifient les préférences.
- Icône des réglages EUI indépendante de DamageMeters ; images ElvUI gérées par le registre commun.

## Compatibilité 12.1.5 / 1.60.1

La famille du client utilise le numéro d'interface, mais **les appels API sont
sélectionnés par capacité**. Forever n'est pas assimilé à l'ancienne API Classic
à cause de son numéro `1.x`.

Points examinés : `C_Item`, `C_Spell`, `C_Container`, compétences structurées
`C_SkillInfo`, valeurs secrètes, AuraContainer, DurationObject, événements
facultatifs et ressources UI. Les anciens globals restent des replis lorsque
l'API moderne manque. Les tables générées ne sont pas exhaustives : les appels
de carte d'aventure ont aussi été recoupés dans le FrameXML Blizzard.

Sources consultées :

- [Changements 12.1.5](https://warcraft.wiki.gg/wiki/Patch_12.1.5/API_changes).
- [Page 1.60.1 demandée](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes) :
  accès direct refusé pendant l'audit ; son contenu n'est pas présenté comme vérifié.
- [Sources Blizzard PTR, a89e9d0ceb7f](https://github.com/Gethe/wow-ui-source/tree/a89e9d0ceb7f/Interface/AddOns/Blizzard_APIDocumentationGenerated)
  et [Forever, 15666a6e6793](https://github.com/Gethe/wow-ui-source/tree/15666a6e6793/Interface/AddOns/Blizzard_APIDocumentationGenerated).
- [Carte d'aventure Blizzard](https://github.com/Gethe/wow-ui-source/tree/a89e9d0ceb7f/Interface/AddOns/Blizzard_AdventureMap).
- [API publique EllesmereUI, 52e68688b68b](https://github.com/EllesmereGaming/EllesmereUI/blob/52e68688b68bfaeba4af4cbf2cb702aa35a541a8/SKINNING_API.md)
  et [API développeur ElvUI](https://elvui.dev/developer-api/).

Cela vérifie les contrats utilisés et les replis disponibles, pas le rendu,
le taint ni toutes les restrictions natives d'un client réel. Les sentinelles
des tests Lua ne reproduisent pas les valeurs secrètes WoW.

## UI/UX et skins

- Un seul fournisseur peint un contrôle : priorité ElvUI si les deux sont activés.
  Un changement de fournisseur nécessite un reload.
- APR possède les boutons sécurisés, attributs et callbacks ; le skin modifie
  l'apparence. Les changements protégés attendent la fin du combat.
- Primitives publiques EUI et actualisation des accents/polices ; couleurs des
  barres conservées selon les options APR.
- Pool AceGUI APR isolé, sans contamination des options d'autres addons.
- Ancrage au suivi de quêtes conservant l'isolation des frames Blizzard ;
  hiérarchie tenant compte des fillers et de l'AFK.
- Contenu visible, lignes et défilement conservés pendant les rafraîchissements.
  La liste prépare son buffer par lots ; un élément coûteux peut toutefois
  dépasser à lui seul le budget d'un lot.

Les rendus spécialisés de l'étape, de la liste future et du groupe sont conservés :
leurs informations et interactions diffèrent. Les fusionner dans une grande
fabrique paramétrable réduirait la lisibilité.

## Validation et évolution

Depuis la racine :

```powershell
.venv\Scripts\python.exe tests\run.py
```

Régressions ajoutées : copies/sauvegardes, lookup d'étape, isolation AceDB, timers,
erreurs, réputation imbriquée, cinématiques et assemblage des messages. Les
fixtures chargent les helpers déplacés dans le même ordre relatif que le TOC ;
les assertions de rendu, progression et recyclage sont conservées.

Résultat de l'audit : **39/39 suites Lua réussies ; 155/156 tests réussis** dans
la validation complète. L'unique échec est
`RouteHookTests.test_manual_no_stage_leaves_index_untouched`, reproduit aussi
avec les scripts, hooks et `StepUtils.lua` extraits de `HEAD` avant refonte.
Ce défaut préexistant du test/outillage Git reste hors périmètre ; les routes
ne sont pas modifiées pour le contourner.

À vérifier en jeu sur les deux clients : login/reload, PNJ/banque/taxi, changement
de route/profil, combat, cinématique protégée, groupe, longue liste défilée et
images. Répéter en natif, avec ElvUI, avec EUI puis avec les deux. Contrôler les
erreurs Lua/taint et la lisibilité à plusieurs échelles avec des objectifs longs.

Prochains découpages possibles : blocs d'options de `Config.lua`, familles
d'événements de `Event.lua` et présentations de `QuestHandler.lua`. Ils demandent
des contrats explicites pour l'état partagé et des régressions de comportement ;
un déplacement mécanique de gros blocs ne suffit pas. Les formats de parcours,
sauvegardes et signatures doivent rester compatibles avec le recorder.

## Annexe : API WoW référencées dans le cœur

Inventaire statique de 124 références d'appels et tests de disponibilité `C_*`
dans 43 namespaces, hors code fournisseur. Une référence ne signifie pas que
la fonction est disponible ou appelée sur les deux clients. Les globals
historiques et les méthodes de widgets complètent ces interfaces.

| Namespace | Fonctions référencées |
| --- | --- |
| `C_AddOns` | `GetAddOnMetadata` |
| `C_AdventureMap` | `Close`, `GetNumZoneChoices`, `StartQuest` |
| `C_BattleNet` | `GetFriendAccountInfo` |
| `C_CampaignInfo` | `IsCampaignQuest` |
| `C_ChatInfo` | `PerformEmote`, `RegisterAddonMessagePrefix`, `SendAddonMessage` |
| `C_ChromieTime` | `GetChromieTimeExpansionOption`, `SelectChromieTimeOption` |
| `C_ColorUtil` | `WrapTextInColorCode` |
| `C_Container` | `GetContainerItemID`, `GetContainerItemInfo`, `GetContainerItemLink`, `GetContainerItemQuestInfo`, `GetContainerNumSlots`, `GetItemCooldown`, `UseContainerItem` |
| `C_CreatureInfo` | `GetCreatureID` |
| `C_CurrencyInfo` | `GetCoinTextureString` |
| `C_DateAndTime` | `GetCurrentCalendarTime` |
| `C_DeathInfo` | `GetCorpseMapPosition` |
| `C_EventUtils` | `IsEventValid` |
| `C_FriendList` | `GetFriendInfoByIndex`, `GetNumFriends` |
| `C_GameRules` | `IsHardcoreActive` |
| `C_GossipInfo` | `CloseGossip`, `GetActiveQuests`, `GetAvailableQuests`, `GetFriendshipReputation`, `GetFriendshipReputationRanks`, `GetNumActiveQuests`, `GetNumAvailableQuests`, `GetOptions`, `SelectActiveQuest`, `SelectAvailableQuest`, `SelectOption`, `SelectOptionByIndex` |
| `C_Item` | `DoesItemExist`, `DoesItemMatchSpellItemCondition`, `GetDetailedItemLevelInfo`, `GetItemCooldown`, `GetItemCount`, `GetItemID`, `GetItemIconByID`, `GetItemInfo`, `GetItemInfoInstant`, `GetItemSpell`, `GetItemStats`, `IsUsableItem` |
| `C_MajorFactions` | `GetCurrentRenownLevel`, `GetMajorFactionData` |
| `C_Map` | `GetBestMapForUnit`, `GetMapChildrenInfo`, `GetMapInfo`, `GetMapPosFromWorldPos`, `GetPlayerMapPosition`, `GetWorldPosFromMapPos` |
| `C_Minimap` | `GetViewRadius` |
| `C_NamePlate` | `GetNamePlates` |
| `C_PetBattles` | `IsInBattle` |
| `C_PlayerChoice` | `GetCurrentPlayerChoiceInfo`, `SendPlayerChoiceResponse` |
| `C_PlayerInteractionManager` | `ConfirmationInteraction` |
| `C_PvP` | `CanToggleWarMode`, `CanToggleWarModeInArea`, `IsWarModeActive`, `IsWarModeDesired` |
| `C_QuestLine` | `GetQuestLineInfo` |
| `C_QuestLog` | `AbandonQuest`, `AddQuestWatch`, `GetInfo`, `GetLogIndexForQuestID`, `GetMapForQuestPOIs`, `GetNumQuestLogEntries`, `GetNumQuestObjectives`, `GetQuestObjectives`, `GetTitleForQuestID`, `IsComplete`, `IsOnQuest`, `IsPushableQuest`, `IsQuestFlaggedCompleted`, `IsQuestFlaggedCompletedOnAccount`, `ReadyForTurnIn`, `RequestLoadQuestByID`, `SetSelectedQuest` |
| `C_Reputation` | `GetFactionDataByID` |
| `C_ScenarioInfo` | `GetCriteriaInfoByStep`, `GetInfo`, `GetScenarioInfo`, `GetScenarioStepInfo` |
| `C_SkillInfo` | `GetNumSkillLines`, `GetSkillLineInfo`, `GetSkillLineInfoByID` |
| `C_SpecializationInfo` | `GetSpecialization`, `GetSpecializationInfo` |
| `C_Spell` | `GetSpellCooldown`, `GetSpellCooldownDuration`, `GetSpellDescriptionForItemLocation`, `GetSpellInfo`, `GetSpellSubtext`, `GetSpellTexture`, `IsSpellUsable`, `TargetSpellChecksItemCondition` |
| `C_SpellBook` | `IsSpellInSpellBook`, `IsSpellKnown` |
| `C_StringUtil` | `RemoveContiguousSpaces`, `StripHyperlinks`, `Trim`, `trim` |
| `C_SuperTrack` | `SetSuperTrackedQuestID` |
| `C_TaskQuest` | `GetQuestZoneID` |
| `C_TaxiMap` | `GetAllTaxiNodes` |
| `C_Timer` | `After`, `NewTicker`, `NewTimer` |
| `C_ToyBox` | `GetToyInfo`, `IsToyUsable` |
| `C_TransmogCollection` | `GetItemInfo`, `PlayerHasTransmog` |
| `C_UI` | `Reload` |
| `C_UIFileAsset` | `IsKnownFile` |
| `C_UnitAuras` | `GetPlayerAuraBySpellID` |

Templates utilisés : `ActionButtonTemplate`, `BackdropTemplate`, `CooldownFrameTemplate`, `CustomAuraContainerTemplate`, `InputBoxTemplate`, `ObjectiveTrackerContainerHeaderTemplate`, `ObjectiveTrackerModuleHeaderTemplate`, `SecureActionButtonTemplate`, `StaticPopupButtonTemplate`, `UIPanelButtonTemplate`, `UIPanelScrollFrameTemplate`.
