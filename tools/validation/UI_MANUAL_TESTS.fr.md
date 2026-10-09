# Validation manuelle de l’interface APR

À exécuter dans WoW après `/reload`, sur Retail et Forever. Les tests Lua
simulent les contrôles ; ils ne valident pas le rendu du client.

## Ancrages et première utilisation

- Sur une installation vierge, le placement s’ouvre après l’entrée en jeu, hors combat.
  Annule ou valide : il ne doit pas revenir au prochain `/reload`, changement de profil
  ou sur un autre personnage. Une installation existante ne reçoit pas cet assistant.
- Ouvre `/apr layout` avec AFK, objectifs secondaires et liste des étapes attachés,
  y compris lorsqu’ils sont masqués. Les aperçus suivent l’ordre étape → AFK → objectifs
  secondaires → liste. Glisse un membre : tout le groupe suit. Valide puis recharge :
  les attaches sont conservées. Annuler/Echap ne modifie ni positions ni attaches.
- Déplace une fenêtre indépendante à différentes échelles. Sa position supérieure
  gauche après validation doit correspondre à l’aperçu, même si son contenu est vide.
- Affiche/masque plusieurs fois la liste attachée, avec/sans objectifs secondaires et
  avec/sans minuterie AFK. Elle retrouve sa place sans déplacer l’étape courante.
- Dans Étape courante → Placement, active l’ancrage puis « Au-dessus ». Fais varier
  la hauteur des objectifs, de la liste et de la minuterie : APR garde son haut fixe,
  le suivi des quêtes descend/remonte selon la hauteur totale. « En dessous » suit le
  dernier élément visible du suivi. Les profils précédemment attachés restent dessous.
- Recommence avec Blizzard, Questie puis Kaliel’s Tracker (référence intégrée : 8.7.2).
  Vérifie le redimensionnement du suivi, sa réduction, son mode de déplacement et ses
  changements d’échelle. Chez Kaliel, les boutons d’objets doivent suivre leur suivi.
- Sans addon de suivi, place APR « Au-dessus » du journal Blizzard rempli. Affiche/masque
  la liste des étapes, la barre AFK et les objectifs secondaires, puis change leur
  espacement : « Tous les objectifs » reste sous le dernier panneau APR, sans chevauchement.
  Ajoute/retire une quête et déclenche un recalcul de l’interface Blizzard : le journal
  ne doit pas reprendre la place réservée. Réduire APR restitue la hauteur disponible.
- Détache APR : le journal Blizzard retrouve sa position et sa hauteur. Recommence avec
  la position Blizzard par défaut, puis une position/échelle personnalisée dans le mode
  édition. Entrer en mode édition restitue le journal avant son déplacement ; le nouvel
  emplacement est repris ensuite. Vérifie aussi après un combat et un changement de côté.
- Avec Kaliel limité aux bords de l’écran et une hauteur maximale de 600, affiche une
  longue liste APR au-dessus : le journal reste sous le dernier panneau APR et sa zone
  défilante utilise l’espace restant. Ajoute/retire une quête puis réduis/développe APR :
  pas de retour du journal par-dessus APR. Vérifie aussi l’ancrage inférieur de Kaliel.
- Détache APR après ces changements : Kaliel retrouve sa position, sa hauteur maximale
  et sa limitation aux bords. Recommence après un déplacement dans ses propres options,
  avec une échelle différente et après un combat. Ses réglages enregistrés restent identiques.
- Recommence avec APR « En dessous » et un journal rempli : Kaliel conserve son haut
  mais réduit sa zone défilante pour réserver l’étape, les objectifs et la liste APR.
  Réduis/masque des panneaux APR : le journal récupère la hauteur libérée. L’écart entre
  les deux ensembles reste compact (4 points), au-dessus comme en dessous.
- Avec l’apparence Kaliel active, change sa largeur puis son échelle : les bords des fonds
  APR/Kaliel restent alignés, les textes utilisent la nouvelle largeur et les en-têtes,
  icônes, images et barres restent à l’intérieur. Vérifie les boutons carré +/−, livre
  (menu APR) et les flèches Kaliel ; aucune roue dentée ni flèche Blizzard ne doit rester.
  Désactive l’intégration : les dimensions et les contrôles APR sont restaurés.
- Déplace le groupe attaché depuis l’éditeur APR, au-dessus puis en dessous : le suivi
  se déplace aussi. Détache APR : le suivi retrouve sa position propre. Une modification
  effectuée ensuite dans l’éditeur du suivi ne doit pas être écrasée par APR.
- Active/désactive « Reprendre l’apparence du suivi des quêtes » : police, en-têtes,
  fond et bordures reprennent le suivi sélectionné puis reviennent au style APR.
  Vérifie aussi avec ElvUI/EllesmereUI et avec chaque panneau détaché individuellement.
- Avec Kaliel, change la police, les couleurs et le style d’en-tête (y compris « Aucun ») :
  APR reprend ces réglages. Le fond est continu derrière tout le groupe, sans bandes plus
  opaques sous chaque ligne. Les boutons de réduction et navigation restent fonctionnels ;
  désactiver l’intégration restaure les fonds et contrôles APR, même après une réduction.
- Entre en combat avec un objet de quête utilisable : aucun déplacement protégé ni
  erreur de taint. Les changements de disposition en attente s’appliquent à la sortie.

## Apparence et interactions

- Ouvre `/apr route`. Vérifie le médaillon APR dans l'angle : logo net,
  cercle intact, aucun chevauchement avec le titre ou les parcours prédéfinis.
- Le médaillon doit couvrir le coin supérieur gauche, sans angle de bordure visible
  au travers du cercle. Déplace la fenêtre contre les bords gauche et supérieur :
  le logo entier doit rester à l’écran, y compris son contour argenté.
- Vérifie les coins arrondis de la fenêtre, des panneaux, des boutons et des champs,
  y compris en redimensionnant. Aucun fond carré ne doit dépasser dans les coins.
- Vérifie les fonds marron très foncé et la lisibilité des textes secondaires.
  Réduis puis agrandis la fenêtre et essaie plusieurs échelles d'interface.
- Survole les actions : ajout, retrait, montée, descente, favori et fermeture.
  Les icônes doivent être fines, sans carré décoratif, avec une infobulle lisible.
- Ajoute trois routes, change leur ordre puis retire-en une. Vérifie que les
  flèches aux extrémités et l'ajout d'une route déjà présente sont désactivés.
- Active puis désactive un favori : étoile pleine puis vide. Filtre les favoris,
  change d'extension et vérifie les métadonnées dans les infobulles.
- Déroule le filtre Type. Clique hors du menu, puis essaie Échap et le choix
  « Tous ». Le menu doit se fermer correctement sans bloquer le clic extérieur.
- Fais défiler les listes avec la molette, les flèches et le curseur. Atteins
  les deux extrémités, puis filtre une liste devenue trop courte pour défiler.
- Ferme et rouvre la fenêtre. Vérifie sa position, sa taille et ses contrôles.

## Logique conservée et intégrations

- Vérifie les trois parcours prédéfinis en haut : Speedrun, montée en niveau et
  toutes les quêtes. Annule une confirmation avant d'en valider une.
- Vérifie le clic droit pour ajouter/reprendre et Maj + clic droit pour
  recommencer, ainsi que les prérequis d'une route bloquée.
- Refais les contrôles visuels sans skin, avec ElvUI puis avec EllesmereUI
  (séparément, après rechargement). Les icônes et les actions doivent rester
  visibles, sans bordures natives superposées à celles du skin.
- Entre en combat avec le filtre ouvert, puis rouvre-le en combat : le clavier
  doit rester utilisable et aucune action protégée ne doit être bloquée.
- Le filtre Type affiche tous les types lorsque la hauteur disponible le permet.
  Déplace la fenêtre près du bas de l’écran : la liste s’ouvre au-dessus si nécessaire.
  Le défilement ne doit apparaître que si tous les types ne tiennent pas à l’écran.
  Vérifie aussi avec une échelle d’interface différente.
- Ouvre `/apr layout`, prévisualise un déplacement, annule puis recommence en
  validant. Vérifie que les positions ne sont enregistrées qu'à la validation.

En cas d'anomalie, conserve une capture, la version du client, le skin actif,
l'échelle d'interface et les étapes qui permettent de reproduire le problème.

## Navigation commune et options

- Dans Options Blizzard > Extensions, APR doit avoir une seule entrée, sans
  sous-catégories. La page affiche uniquement le logo, le nom et le bouton
  d’ouverture. Clique dessus : Blizzard se ferme et les options APR s’ouvrent.
  Ferme et rouvre la page Blizzard : aucun contrôle ne doit être dupliqué.
- Ouvre les réglages depuis la minicarte, le guide puis `/apr`. Vérifie les onglets
  Route, Statut, À propos et Options. `/apr route` et `/apr status` doivent ouvrir
  la bonne page de la même fenêtre.
- Dans Options > Debug, active « Afficher l’onglet Performances », puis désactive-le.
  Le changement doit être immédiat. `/apr perf` doit fonctionner dans les deux cas,
  sans démarrer une capture à l’ouverture.
- Change plusieurs fois d’onglet et de catégorie. Vérifie que les filtres de routes,
  la catégorie des options et le sous-onglet Perf sont conservés. Ferme par la croix
  puis par Échap ; rouvre et vérifie la position et la taille.
- Essaie une fenêtre de 940 × 740, puis agrandis-la. Parcours toutes les catégories
  avec la molette, notamment Debug en bas. Les options longues doivent rester
  lisibles et les menus déroulants doivent apparaître au-dessus des panneaux.
- Les onglets principaux doivent être attachés **au-dessus du bord supérieur**,
  sans pousser le logo, le titre ou la croix vers le bas. Déplace la fenêtre au
  sommet de l’écran : les onglets doivent rester accessibles.
- Leur partie basse passe légèrement derrière le cadre : aucune bordure inférieure
  des onglets ne doit traverser l’en-tête. Vérifie les clics et le survol après
  plusieurs changements d’onglet, avec et sans l’onglet Performances.
- Dans Route, agrandis la hauteur : les trois listes doivent s’allonger jusqu’à
  la légende et aux raccourcis, sans grande bande vide au bas de la fenêtre.
- Vérifie les quatorze catégories, dans cet ordre : Automatisation, Étape courante,
  Objectifs secondaires, Liste des étapes, Flèche, Carte & minicarte, AFK, Groupe,
  Héritage, Bonus d’XP, Apparence, Profils, Notes de mise à jour, Debug.
  Il n’y a plus de catégorie Général, Suivi de route, Navigation ou Progression et groupe.
- Bonus d’XP possède sa propre page : vérifie l’activation de l’encart et la sélection
  individuelle des bonus suggérés.
- Dans Étape courante, Affichage, Disposition et Apparence des textes sont des
  sous-onglets. Les libellés restent à gauche ; les
  contrôles sont alignés à droite. Les textes longs passent à la ligne sans
  toucher le contrôle ou la ligne suivante. Change de catégorie puis reviens :
  le sous-onglet choisi doit être conservé.
- Dans Disposition, « Réinitialise la position » doit être en bas des réglages,
  séparé de la dernière ligne par une marge visible. Vérifie la même disposition
  pour Objectifs secondaires, Liste des étapes, Flèche, AFK et Groupe, sans texture
  rouge au survol ou au clic.
  Ouvre ensuite la catégorie Objectifs secondaires : ses réglages
  occupent une page indépendante. Attache puis détache les objectifs de l’étape
  courante : la réinitialisation doit se désactiver puis se réactiver immédiatement.
  Un clic sur le bouton désactivé ne doit pas modifier la position.
- Vérifie la valeur sélectionnée de « Position du bouton de quête », puis change-la.
  Le texte et la flèche doivent rester visibles après un changement de catégorie,
  y compris sur une liste désactivée dans Apparence des textes.
- Ouvre une liste dans les options, clique dans une zone vide puis sur un autre
  contrôle : la liste se ferme et le contrôle reçoit le clic. Vérifie aussi le clic
  droit extérieur, la réouverture, la sélection d’une valeur et le changement de
  catégorie. Le clic sur la liste ou son bouton ne doit pas la fermer prématurément.
  Refais le test avec ElvUI et EllesmereUI.
- Dans Flèche > Style de la flèche, Classique reste sélectionné sur un ancien profil
  et sur un profil neuf. Choisis APR, puis Classique : le visuel change immédiatement
  sans modification de l’ancrage enregistré, changement de cible ou validation d’une étape.
  À 100 %, APR est 80 % plus grand qu’avant ; Classique garde sa taille habituelle.
  Les curseurs « Taille de la flèche » et « Taille du texte » sont indépendants :
  agrandis la flèche sans modifier la distance, puis le texte sans modifier la flèche.
  Le bouton de passage reste sous la distance et sa zone cliquable suit la taille du texte.
  Un ancien profil à 200 % doit conserver sa taille de texte au premier chargement.
  Vérifie les deux tailles après changement de profil, réinitialisation et reload,
  avec puis sans héritage de la typographie générale, sous WoW, ElvUI et EllesmereUI.
  Tourne sur place : les directions, couleurs vert/jaune/rouge et distances doivent
  correspondre pour les deux styles. Vérifie l’arrivée sur un point de passage,
  le bouton de passage manuel, les trajets Farstrider et la restauration après reload.
- Sur les curseurs Taille et Espacement, les bornes sont sous la barre et la valeur
  courante à droite. Vérifie les pourcentages, les valeurs numériques et leur mise
  à jour après saisie, déplacement et réouverture, à 940 × 740 puis en grand format.
  Refais ces contrôles avec le rendu natif, ElvUI et EllesmereUI.
- Dans Debug, « Activer l’addon » est le premier réglage ; il permet aussi de réactiver
  l’addon. « Réinitialise les options » garde exactement sa place en haut à droite
  dans chaque catégorie et sous-onglet, y compris les notes de mise à jour.
  Annule sa confirmation : les réglages doivent être conservés.
- Automatisation est sélectionnée à la première ouverture. Elle possède quatre
  sous-onglets : Général, Points de passage, Dialogue et Récompenses. Général réunit
  les anciens réglages principaux et avancés dans deux encarts : Automatisation
  principale et Confort de jeu. Les préférences de quête restent dans le premier.
  Leur fond doit être identique à celui des encarts des notes de mise à jour.
- Dans Automatisation > Points de passage, active successivement les deux options
  de passage automatique : elles doivent rester mutuellement exclusives.
  Carte & minicarte conserve sa catégorie indépendante, avec Carte, Minicarte et
  Couleurs. Change de catégorie puis reviens : le dernier sous-onglet reste sélectionné.
- Dans AFK, le bouton de test est à droite des sous-onglets, y compris Apparence des textes. Lance puis arrête le
  test : son libellé doit changer immédiatement. Réduis la fenêtre pour vérifier
  qu’il ne chevauche pas les onglets, puis teste aussi avec l’addon désactivé.
- Vérifie les réglages de chaque catégorie : cases, curseurs, couleurs, listes,
  boutons et confirmations. Accepter toutes les quêtes et accepter celles de la
  route doivent rester mutuellement exclusifs. Annule une réinitialisation.
- Coche puis décoche une option et clique aussi sur son libellé. La coche doit
  rester visible au-dessus du fond et correspondre à la valeur enregistrée, même
  après avoir changé d’onglet. Vérifie aussi une case désactivée par une autre
  option. Saisis une valeur dans un curseur, puis utilise sa poignée et sa molette.
- Dans Apparence, Thème précède Apparence des textes. La liste des thèmes propose
  World of Warcraft, puis ElvUI/EllesmereUI lorsque les addons compatibles sont chargés.
  Les anciens profils conservent leur skin. Annule un changement de thème : aucune
  préférence ne doit changer. Accepte ensuite un changement : le rechargement applique
  le skin choisi. Reviens au thème WoW, puis teste avec les deux intégrations chargées.
- Dans Apparence > Apparence des textes, change une police et sa taille, puis reviens aux
  options précédentes. Vérifie l’absence de contrôles coupés ou superposés.
- Dans Profils, crée un profil de test, copie un profil puis retourne à ton profil
  habituel. Le rechargement existant doit appliquer ses réglages, y compris Perf.
- Profils présente trois encarts sur une seule page : profil actuel, création et
  copie, gestion des profils. Le nom du profil doit suivre les changements. Les
  explications ne sont pas répétées au-dessus des lignes ; les actions de gestion
  ont un bouton « Appliquer » à droite, distinct de leur description. À petite
  largeur, les explications passent à la ligne et la page défile si nécessaire.
- Sur un profil de test, vérifie la réinitialisation. Annule une suppression de
  profil pour vérifier sa conservation, puis valide la suppression de ce seul
  profil inactif. Le bouton concernant tous les personnages doit conserver sa
  confirmation complète ; annule-la pour préserver tes profils habituels.
- Le champ « Nouveau » doit avoir une seule bordure, alignée sur la zone de saisie.
  Il a exactement la même largeur et le même bord droit que les listes déroulantes.
  Tape un nom puis valide par Entrée ; recommence avec le bouton OK qui apparaît
  sous le champ, à droite, sans déplacer les lignes suivantes. Vérifie aussi un
  nom invalide, puis le retour dans Profils après un changement de catégorie.
- Clique directement sur « Place tes fenêtres » depuis Apparence. Les réglages
  doivent se fermer, sans erreur AceConfig `rootframe`. Déplace un aperçu puis
  annule : les réglages se rouvrent sur Apparence et la position n’est pas enregistrée.
  Recommence en validant : les réglages se rouvrent et la position est appliquée.
  Vérifie aussi le retour avec Échap et la croix, puis relance le placement pour
  confirmer que les contrôles restent utilisables. Refais ce parcours avec ElvUI
  puis EllesmereUI. En combat, le bouton de placement doit être désactivé et
  redevenir disponible à la sortie du combat.
- Dans Notes de mise à jour, le premier encart contient les deux cases d’affichage
  et de notification, puis le lien GitHub visible, sélectionné dès l’ouverture
  pour Ctrl+C. Le bouton permet de le sélectionner à nouveau ; une saisie ne doit
  pas modifier l’adresse.
  Le deuxième encart affiche les versions récentes et précédentes, avec son propre
  défilement. Les titres, listes imbriquées, emphases et fragments de code sont mis
  en forme ; les délimiteurs Markdown ne doivent pas rester affichés. Les blocs de
  code conservent leur contenu littéral. Essaie la petite fenêtre et les trois skins.
  Après une nouvelle version, l’affichage automatique doit ouvrir cette même catégorie.
- Dans À propos, vérifie les contributeurs, les auteurs de routes, les liens,
  les commandes et l’aide à l’automatisation.
- Discord, GitHub, Wiki et Notes de mise à jour sont en haut. Vérifie la version,
  le client, le skin et le nombre de routes/extensions chargées. Les crédits sont
  en texte clair, les titres en couleur d’accent. Compare Commandes à `/apr help` :
  la source est commune, y compris `/apr perf` et `/apr layout`.
- Ouvre les liens depuis À propos, puis avec `/apr discord` et `/apr github` :
  l’URL complète doit être sélectionnée et prête pour Ctrl+C, même si la fenêtre
  affichait déjà un autre lien ou rapport. Vérifie aussi la copie de coordonnées
  et le résultat d’une conversion avec `/apr worldcoords`.

## Statut, erreurs et export

- Avec puis sans route active, vérifie le bloc d’informations : versions APR/WoW,
  langue, serveur, date, route, étape courante, continent, zone, coordonnées de carte
  et du monde, nom, royaume, faction, niveau et classe. Essaie aussi une instance.
- Dans la vue d’ensemble, les trois cartes distinguent les libellés discrets des
  valeurs plus grandes placées dessous. Essaie une route au nom long à 940 × 740,
  puis agrandis la fenêtre : tout le texte doit rester lisible, sans couper les
  identifiants ni chevaucher le champ suivant. Vérifie aussi avec une police plus
  grande et avec chaque skin : le défilement doit donner accès à toutes les valeurs
  tout en laissant le tableau d’erreurs accessible en dessous.
- Le nom et le royaume sont masqués par défaut. Bascule le bouton et vérifie les
  informations affichées, les infobulles d’erreur et les rapports ouverts.
- Ouvre Statut immédiatement après `/reload`, avant toute visite de la boutique
  WoW. Le royaume doit porter son libellé et afficher « Masqué », sans erreur Lua.
- Exporte le statut : une fenêtre séparée contient du Markdown avec des sections
  pour le client, la route, le personnage et les données de l’étape. Les libellés
  sont en gras et les données imbriquées de l’étape utilisent des listes. Seules
  les erreurs sont dans des blocs de code `lua`, un par erreur. Sans erreur, aucun
  bloc de code ne doit apparaître ; une collecte indisponible est signalée.
  Tout le texte est sélectionné dès l’ouverture : Ctrl+C suffit. Vérifie le rendu
  après collage dans Discord ou GitHub, ainsi que l’absence de tes identifiants
  lorsque le masquage est activé, dans les valeurs, l’étape et les piles d’appels.
  Le détail d’une erreur reste un bloc Lua sélectionné, prêt à copier.
- Dans la zone de saisie de l’export, sélectionne un passage à la souris, puis
  ajuste-le avec Maj + flèches et copie uniquement ce passage. Le curseur doit
  rester visible en parcourant un long rapport ; redimensionner la fenêtre ne
  doit pas sélectionner à nouveau tout le texte. Vérifie que tu peux modifier
  l’extrait avant de le copier, avec les skins WoW, ElvUI et EllesmereUI.
- Actualise le statut pendant que tu sélectionnes un rapport : la sélection ne doit
  pas être remplacée. Seul le changement du masquage régénère le rapport de statut
  ouvert ; il ne doit pas modifier un rapport de performances.
- Pour exercer la capture sans provoquer une panne de route, exécute manuellement :
  `/run geterrorhandler()("Interface/AddOns/APR/Test.lua:1: APR UI diagnostic test")`.
  C’est un message de test transmis au gestionnaire d’erreurs, pas une erreur réelle.
  Répète-le et vérifie le compteur, la dernière heure, la source et le détail au clic.
- Refais le test sans puis avec BugGrabber/BugSack. Le gestionnaire habituel doit
  toujours recevoir le message ; APR ne doit pas doubler son compteur. Un message
  sans référence APR ne doit pas être ajouté. Après `/reload`, la liste APR repart
  sur la session courante. Elle conserve au maximum 100 erreurs regroupées.
- Si un autre gestionnaire remplace celui de WoW sans relayer les erreurs, la capture
  native peut devenir incomplète. La présence d’APR dans une pile indique un lien
  possible, elle ne suffit pas à identifier le responsable.

## Performances et skins

- Démarre une capture, navigue normalement, puis consulte CPU et mémoire. Survole les
  graphiques, change la durée, fige et reprends l’affichage. Ferme la fenêtre : une
  capture démarrée doit continuer jusqu’à son arrêt explicite.
- Dans Appels mesurés, essaie la recherche et le tri par nombre, total, moyenne et
  maximum. Vérifie aussi les appels lents, leurs infobulles et les compteurs. Exporte
  un rapport, efface les mesures, puis vérifie l’état vide.
- Répète les pages Options, Statut, À propos, Perf et la copie de rapport avec le
  rendu WoW, ElvUI et EllesmereUI, séparément. Vérifie cases cochées, menus, champs,
  curseurs, titres et contraste. Les réglages d’un autre addon doivent conserver
  leur propre apparence après avoir ouvert puis fermé ceux d’APR.
- Entre en combat avec la fenêtre ouverte, change de page, ferme puis rouvre-la.
  Vérifie l’absence d’action protégée bloquée ; le déplacement et le redimensionnement
  conservent leur restriction existante hors combat.

## Nouvelles traductions à importer dans CurseForge

Les libellés existants sont réutilisés. Options, Général, Actualiser et Source utilisent
les chaînes WoW `GAMEOPTIONS_MENU`, `GENERAL`, `REFRESH` et `SOURCE`.

| Clé | Anglais | Français |
| --- | --- | --- |
| `UI_RELEASE_NOTES` | Release notes | Notes de mise à jour |
| `UI_SHOW_PERF_TAB` | Show the Performance tab | Afficher l’onglet Performances |
| `UI_SHOW_PERF_TAB_DESC` | Add Performance to the top navigation. /apr perf remains available. This does not start a capture. | Ajoute Performances à la navigation du haut. /apr perf reste disponible. Cette option ne démarre pas de capture. |
| `UI_LUA_ERRORS` | Lua errors related to APR | Erreurs Lua liées à APR |
| `UI_ERRORS_EMPTY` | No errors related to APR have been recorded this session. | Aucune erreur liée à APR n’a été enregistrée pendant cette session. |
| `UI_ERRORS_UNAVAILABLE` | Error capture is unavailable. An error handler may prevent APR from observing errors. | La collecte des erreurs est indisponible. Un gestionnaire d’erreurs peut empêcher APR de les observer. |
| `UI_ERRORS_HELP` | This session only · Up to 100 grouped errors · An APR reference in a stack does not prove APR caused the error. | Session actuelle · 100 erreurs regroupées au maximum · La présence d’APR dans une pile d’appels ne prouve pas qu’il est responsable de l’erreur. |
| `UI_ERROR_LAST` | Last seen | Dernière fois |
| `UI_ERROR_MESSAGE` | Message | Message |
| `UI_ERROR_COUNT` | Occurrences | Occurrences |
| `UI_ERROR_OPEN` | Click to view and copy the message, stack and route context. | Clique pour consulter et copier le message, la pile d’appels et le contexte de la route. |
| `UI_SETTINGS_PLACEMENT` | Placement | Disposition |
| `UI_APPEARANCE` | Appearance | Apparence |
| `UI_THEME` | Theme | Thème |
| `UI_THEME_DESC` | Choose APR's appearance. ElvUI and EllesmereUI are available when their addons are loaded. Changing the theme reloads the interface. | Choisis l’apparence d’APR. ElvUI et EllesmereUI sont disponibles lorsque leurs addons sont chargés. Changer de thème recharge l’interface. |
| `UI_THEME_CONFIRM` | Reload the interface to apply this theme? | Recharger l’interface pour appliquer ce thème ? |
| `UI_AUTOMATION_COMFORT` | Gameplay convenience | Confort de jeu |
| `UI_ARROW_STYLE` | Arrow style | Style de la flèche |
| `UI_ARROW_STYLE_DESC` | Change the arrow's appearance. Direction, distance, heading colors and waypoint behavior stay the same. | Change l’apparence de la flèche. La direction, la distance, les couleurs d’orientation et le passage des points de passage restent identiques. |
| `UI_ARROW_CLASSIC` | Classic (default) | Classique (par défaut) |
| `UI_ARROW_TEXT_SCALE` | Text size | Taille du texte |
| `UI_ARROW_TEXT_SCALE_DESC` | Resize the distance text and skip button without changing the arrow. | Agrandis ou réduis la distance et le bouton de passage sans changer la taille de la flèche. |
| `UI_PROFILE_SETUP` | Create and copy | Création et copie |
| `UI_PROFILE_MANAGEMENT` | Profile management | Gestion des profils |
| `UI_ABOUT_CONTRIBUTORS` | Contributors | Contributeurs |
| `UI_ABOUT_COMMANDS` | Commands | Commandes |
| `UI_DEVELOPMENT_BUILD` | Development build | Version de développement |
| `UI_ABOUT_ROUTE_COUNT` | %d loaded routes · %d expansions | %d routes chargées · %d extensions |
| `UI_ABOUT_LOADED_AUTHORS` | Authors of loaded routes | Auteurs des routes chargées |
| `UI_ABOUT_ROUTES_HELP` | Start with a preset, or browse routes by expansion. Use search, type filters and favorites to build your path. Hover over a route to see its author and requirements. | Commence par un parcours prédéfini ou explore les routes par extension. Utilise la recherche, les filtres de type et les favoris pour composer ton parcours. Survole une route pour consulter son auteur et ses prérequis. |
| `UI_ABOUT_STATUS_HELP` | Open Status to inspect your current route and step, review APR-related errors and export a report. Character identifiers are hidden by default. Performance capture is available with /apr perf. | Ouvre Statut pour consulter ta route et ton étape en cours, examiner les erreurs liées à APR et exporter un rapport. Les identifiants du personnage sont masqués par défaut. La capture des performances est accessible avec /apr perf. |
