# Diagnostic du transport Group Finder

L’adhésion APR et la livraison des messages addon sont deux observations distinctes.
`Success` signifie que l’API a accepté l’envoi. Une absence de réponse laisse le
transport inconnu. Seul `NOT_ALLOWED_IN_CHANNEL` pour APR, avec le numéro encore
valide et une tentative datant de cinq secondes maximum, déclenche le repli.
Le contrôle de version partage cet état et cesse ses envois `CHANNEL` bloqués.

## Canaux globaux et locaux

Retail et Forever utilisent la même sélection de transport : les recherches
locales privilégient un canal de zone, les recherches monde utilisent le canal
global. Un canal local indisponible provoque un repli vers le canal global.
Retail conserve `APR` comme canal global, sans séparation par faction, et utilise
`APRZ<mapID>` pour les zones. Forever conserve `APRAlliance` / `APRHorde` et
leurs variantes `Z<mapID>`. Le numéro de carte correspond à la grande zone :
un changement de sous-zone conserve le canal et la recherche en cours.

Un changement de grande zone remplace le canal local et relance une recherche
locale active ; une recherche monde reste en cours. Les anciens canaux de zone
APR conservés après un rechargement sont libérés. Les règles d’adhésion, de
roster, de repli privé et de déconnexion ci-dessous sont communes aux deux clients.

## Adhésion vérifiée au démarrage et à la recherche

Pour un Group Finder actif, le démarrage (y compris `/reload`) et les recherches
vérifient l’adhésion réelle avec `GetChannelName("APR")`. Un état Lua « ready »
ne remplace pas cette vérification. Si APR manque, le gestionnaire le rejoint,
puis confirme le résultat avec une nouvelle lecture native. L’appel de jonction
seul ne constitue pas une confirmation.

Une reprise vérifiée reste bornée à trois appels de jonction, dans une fenêtre
de 36 secondes incluant le délai de démarrage et les réponses asynchrones. La
liste des canaux conserve son nombre réel de valeurs retournées même lorsque
certains champs sont `nil`. La désactivation du propriétaire et le départ du
jeu annulent les vérifications différées. Une adhésion confirmée arrête le suivi ;
une recherche explicite peut réessayer après un échec borné.

## Commandes dans le client

Demander la liste : `/chatlist APR`, ou `/run ListChannelByName("APR")`.
Le compteur ci-dessous lit uniquement les données actuellement connues du client :

```lua
/run for i=1,GetNumDisplayChannels() do local n,h,_,id,c=GetChannelDisplayInfo(i);if not h and n and n:lower()=="apr" then print("APR",id,"membres",c or "?") end end
```

Le numéro de canal (`id`) n’est pas l’index d’affichage (`i`). L’index est
retrouvé par nom et numéro natif à chaque recherche et pendant le chargement ;
une modification de l’ordre de la liste réoriente la demande en cours. Si APR
est déjà sélectionné mais son cache est vide après une reconnexion, une brève
bascule par un autre canal texte rejoint relance la demande native.
 Le roster utilise
`C_ChatInfo.GetChannelRosterInfo(i, membre)`. APR demande son chargement avec
`SetSelectedDisplayChannel`, conserve cette sélection pendant le chargement
asynchrone, puis rétablit la sélection précédente à la réception ou au délai
limite. Une interaction de l’utilisateur avec les canaux prend la priorité.
L’effectif d’un événement APR vérifié est également utilisable lorsque le cache
de `GetChannelDisplayInfo` renvoie encore `nil`. Les événements
`CHANNEL_COUNT_UPDATE` et `CHANNEL_ROSTER_UPDATE` permettent de
reprendre une lecture incomplète. Après dix secondes, le parcours utilise les
membres effectivement disponibles ; aucun nom manquant n’est inventé.

Le tableau de diagnostic existant expose client/build/interface, faction,
identité des règles, adhésion, transport addon, numéro APR, effectif connu,
disponibilité du roster, notices et compteurs TX/RX. Son journal conserve les
retours natifs, les refus et les réceptions, dont les échos.

## Sondes manuelles

Le préfixe réservé `APRDiagV1` est indépendant de `APRFindV1`. Espacer les sondes
d’au moins cinq secondes et consulter les lignes `probe` du diagnostic :

```lua
/run print(APR.CommunicationChannel:Probe("CHANNEL"))
/run print(APR.CommunicationChannel:Probe("WHISPER",GetUnitName("player",true)))
/run print(APR.CommunicationChannel:Probe("WHISPER","Nom complet du joueur"))
```

Pour comparer avec `SendAddonMessageLogged`, ajouter un troisième argument `true` :

```lua
/run print(APR.CommunicationChannel:Probe("CHANNEL",nil,true))
/run print(APR.CommunicationChannel:Probe("WHISPER",GetUnitName("player",true),true))
```

La sonde distante nécessite cette version d’APR active chez le destinataire.
Une sonde whisper reçue d’un autre joueur obtient une réponse dédiée, limitée à
une toutes les cinq secondes. Aucun message public visible n’est envoyé.
L’écho vers soi confirme seulement ce trajet local ; il ne certifie pas les
échanges entre joueurs, factions ou rulesets.

## Parcours privé et résultats

Après un refus confirmé, si l’adhésion et le roster fonctionnent encore, APR
photographie les identités accessibles, exclut le personnage local et déduplique.
Il parcourt des lots de 24 destinataires, à quatre requêtes maximum par seconde,
en attendant aussi la file ChatThrottleLib. Le contexte War Mode alternatif
partage ce débit. Les dix secondes de réponse commencent après les derniers
envois du lot. Les départs individuels et versions sans prise en charge peuvent
rester sans réponse ; le parcours continue.

Le bouton de recherche devient **Annuler**, pendant la préparation, la recherche
publique et le parcours privé. Le compteur indique interrogés/total
et résultats ; les réponses apparaissent dans la liste défilante habituelle.
Le protocole `Q/P/D/W` reste inchangé. Les requêtes de non-amis sont acceptées
uniquement après vérification de leur adhésion APR native. Les réponses du
parcours doivent correspondre au destinataire interrogé et à l’identifiant du lot.
Visibilité, langues et compatibilité restent appliquées.

La limite de trente réponses et le cache ordinaire restent inchangés pour les
recherches publiques. Le parcours privé garde ses résultats pendant toute sa
durée, puis 120 secondes après son arrêt ou sa fin. Une présence de plus de
120 secondes affiche son âge en couleur d’avertissement ; son action devient
**Actualiser**. Une réponse fraîche est nécessaire avant de pouvoir inviter.
Une actualisation ne déclenche jamais automatiquement une invitation.

Les refus « joueur introuvable » des whispers automatiques récemment envoyés
sont conservés dans le diagnostic et filtrés du chat. Le filtre compare le
GlobalString localisé exact avec les destinataires réellement envoyés, expire
après cinq secondes et se retire quand cette courte fenêtre est vide. Les
autres messages système et destinataires restent visibles ; un paquet encore
en file, jamais envoyé, ne crée aucune entrée de filtrage.

Arrêt, filtres, désactivation, changement de contexte et départ du jeu invalident
les callbacks et les envois en file. Les recherches automatiques ne chevauchent
pas le parcours. Sans roster, APR indique l’indisponibilité du canal ; les
transports amis/Battle.net restent utilisables.

## Annulation et préférences

L’annulation explicite libère immédiatement le délai de recherche manuelle, y
compris pendant le chargement du roster. Une nouvelle recherche peut démarrer
sans attendre. Le transport privé garde son débit de quatre requêtes par seconde,
même entre deux parcours rapidement annulés et relancés. Une recherche terminée
conserve son délai habituel.

La préférence de recherche automatique reste dans le profil AceDB sélectionné :
elle est restaurée au prochain chargement et réactive sa planification. Arrêter
une recherche ne désactive pas cette préférence. Les notifications de découverte
sont activées par défaut ; une désactivation explicitement sauvegardée est
respectée.

## Déconnexion

`PLAYER_CAMPING` et `PLAYER_QUITING` suspendent les échanges et quittent APR
immédiatement, y compris lorsqu’il était rejoint avant APR. `LOGOUT_CANCEL`
restaure l’adhésion quittée pour les propriétaires encore actifs, sans
relancer la recherche annulée. Le déplacement et le post-hook sécurisé de
`CancelLogout` couvrent aussi l’annulation native. Si la fenêtre de décompte
observée disparaît avant son expiration (par exemple en se relevant), une
surveillance temporaire bornée couvre également l’absence d’événement d’annulation.
Elle cesse avant la fin naturelle du décompte et lors du dernier nettoyage.
Une reprise limitée à dix
secondes et trois tentatives attend la fin des restrictions ou un départ natif
encore en attente ; elle s’arrête dès que l’adhésion est confirmée.
Les libérations ordinaires préservent la propriété
initiale du canal. `PLAYER_LOGOUT` réalise le dernier nettoyage. Les événements
de zone ne sont pas des événements de départ. Une coupure brutale ne garantit
pas la transmission du départ.

## Sources et compatibilité

Contrats examinés dans les branches Blizzard publiées par Gethe :

- [Roster, règles de canal et événements Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua)
- [Même système Retail](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua)
- [Sélection native Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Channels/Classic/ChannelList.lua)
- [Lecture native Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Channels/Classic/ChannelRoster.lua)
- [Règles et identité du mode Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/GameRulesDocumentation.lua)

Les indicateurs `HardcoreRuleset`, `PvPRuleset`, `RPRuleset` sont lus seulement
s’ils existent et retournent un booléen public. Forever ajoute l’identité native
`GetCurrentGameModeRecordID` lorsqu’elle est disponible. Si les indicateurs sont
incomplets et l’identité indisponible, la compatibilité reste inconnue et la
découverte est suspendue. Les noms régionaux complets Forever sont conservés.

Les contrats `GetChannelRosterInfo`, `SendAddonMessageLogged`, préfixes, événements
de roster/notices, `IsGameRuleActive` et `GetCurrentGameModeRecordID` ont aussi été
comparés dans les références `11.2.7`, `12.0.0`, `12.0.1`, `12.0.5`, `12.0.7`,
`12.1.0` et `12.1.5` : ils y sont déclarés.

Les fonctions ajoutées sont vérifiées avant appel ; les événements passent par
`APR:RegisterSupportedEvent`, qui consulte les capacités du client. L’absence
d’un getter/setter de sélection empêche de modifier celle-ci ; un roster déjà
en cache peut néanmoins être lu. Les interfaces déclarées dans `APR.toc` incluent
Forever 16001 et Retail 110207/120000/120001/120005/120007/120100/120105 : les tests
simulés et les sources ne certifient pas leur comportement effectif en jeu.

Le [signalement Reddit](https://www.reddit.com/r/wowaddons/comments/1xoko82/wow_forever_addon_channel_returns_success/)
reste un témoignage, à reproduire sur notre client. Les
[règles Forever Blizzard](https://worldofwarcraft.blizzard.com/en-us/news/24302070)
exigent même faction et ruleset pour grouper ; la portée des canaux et whispers
entre rulesets nécessite une mesure séparée.

## Validation en jeu restante

1. Sur un personnage : commandes de roster, sondes normales/logged, numérotation,
   écho, refus éventuel, `/logout` puis annulation, `/quit` puis annulation.
2. Sur deux personnages non amis : réception réelle, réponse privée, visibilité,
   langues, arrêt, revalidation d’une présence ancienne puis invitation explicite.
3. Répéter sur des rulesets distincts et sur chaque client ciblé ; consigner build,
   faction et identité du mode. Ne pas extrapoler le diagnostic solo.

Le bouton de découverte affiche un halo doré pulsant tant que la recherche
automatique est activée, y compris entre les scans. Une animation alpha native
(0,25 à 0,85, aller-retour en 1,8 seconde) évite un traitement Lua par image.
Le halo s’arrête à la désactivation ou au masquage du bouton ; les mises à jour
du compteur ne redémarrent pas son cycle. Le schéma UI Blizzard déclare Alpha,
BOUNCE et IN_OUT sur Forever et toutes les versions Retail ciblées ci-dessus.

La réouverture de la fenêtre conserve tout scan en cours (roster, requête ou
attente du transport). En mode automatique, elle ne déclenche aucune recherche
supplémentaire et respecte le minuteur existant ; seul le mode manuel inactif
lance sa recherche initiale à l’ouverture.
