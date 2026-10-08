# Recette manuelle APR-Core

État initial : **aucun scénario ci-dessous n'a été exécuté dans WoW par l'agent**.
Ces tests sont à réaliser manuellement. Les tests Lua hors jeu ne valident ni
le rendu Blizzard, ni le taint, ni les restrictions des boutons protégés.

## Préparation et compte rendu

Utiliser un personnage avec quelques quêtes et un parcours disponibles. Noter
le commit, la version APR, la version exacte du client, la langue, la résolution,
l'échelle UI et les versions des skins. Activer les erreurs Lua avec
`/console scriptErrors 1`. Conserver une copie de ses SavedVariables si l'on
souhaite retrouver exactement son parcours et ses préférences après la recette.

Pour chaque cas, noter **OK / KO / non applicable**, les étapes de reproduction,
l'erreur Lua éventuelle et une capture manuelle pour les problèmes de disposition.
`/apr status` fournit un rapport copiable ; l'identité est masquée par défaut.

| Configuration | Client 12.1.5 | Client 1.60.1 |
| --- | --- | --- |
| APR natif, thème WoW | À tester | À tester |
| ElvUI seul, intégration activée | À tester | Si cette version d'ElvUI prend ce client en charge |
| EllesmereUI seul, intégration activée | À tester | Si cette version d'EUI prend ce client en charge |
| Les deux présents, intégration Automatique | À tester : ElvUI prioritaire | Selon disponibilité des deux addons |
| Les skins présents, intégration APR | À tester après reload | Selon disponibilité |

Faire toute la recette moteur sur les deux clients. Rejouer les cas d'affichage,
combat, placement et fermeture pour chaque combinaison visuelle disponible.
Un addon tiers absent du client n'est pas une régression d'APR.

## 1. Démarrage et réglages

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| S01 | Connexion puis `/reload`, avec et sans route active. | Aucune erreur ; progression et options conservées. |
| S02 | Ouvrir `/apr` puis `/apr route`. | Options Blizzard/AceConfig et catalogue AceGUI d’origine ; aucun bouton Performances dans les réglages, aucun nouvel accueil ni bibliothèque. |
| S03 | Modifier affichage du guide, flèche, groupe et liste des étapes. | Options historiques présentes et comportement inchangé. |
| S04 | Activer l'acceptation des quêtes de route, puis l'acceptation de toutes les quêtes dans les options avancées. | Les options mutuellement exclusives restent cohérentes. |
| S05 | Parcourir les catégories d’automatisation, navigation, polices et couleurs. | Toutes les options historiques sont accessibles dans leur catégorie. |
| S06 | Désactiver puis réactiver APR depuis les options. | Les fonctions de jeu suivent l’activation ; les réglages restent accessibles. |
| S07 | Changer de profil AceDB puis reload, y compris un profil provenant de la branche UI. | Réglages et positions conservés ; seul le thème natif WoW est utilisé sur audit-clean. |
| S08 | Ouvrir/fermer plusieurs fois ; fermer avec Échap. | Pas de saisie clavier capturée après fermeture, ni multiplication de fenêtres. |

## 2. Sélection de routes AceGUI et parcours

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| R01 | Ouvrir `/apr route`, changer d’extension et consulter catégorie/progression. | Catalogue historique en colonnes, parcours personnalisé et boutons de parcours prédéfinis présents. |
| R02 | Chercher une route avec/sans accents puis effacer la recherche. | Recherche historique fonctionnelle, liste initiale retrouvée après effacement. |
| R03 | Cliquer les en-têtes Nom, Catégorie et Statut. | Tri et sens de tri cohérents ; interactions des lignes toujours correctes. |
| R04 | Consulter le catalogue sur un personnage de faction/client incompatible avec certaines routes. | Routes incompatibles masquées selon les conditions existantes. |
| R05 | Faire un clic droit sur une route déjà commencée. | Vérification des modifications de route et ajout/reprise conservant la progression. |
| R06 | Survoler une route désactivée, puis tenter de l’ajouter. | Infobulle avec conditions manquantes ; ajout désactivé. |
| R07 | Ajouter une route avec des prérequis non terminés. | Les prérequis applicables sont ajoutés avant elle, sans doublon. |
| R08 | Dans le parcours personnalisé, monter, descendre et retirer plusieurs routes. | Ordre correct ; les boutons recyclés agissent sur leur route actuelle. |
| R09 | Retirer la dernière route. | Guide sans route, flèche arrêtée et invitation au choix d'un parcours ; aucune erreur. |
| R10 | Sur un parcours de test, utiliser les boutons Leveling, Toutes les quêtes, Speedrun puis vider le parcours. | Constructeurs et boîtes de choix historiques fonctionnels ; Speedrun conserve son comportement historique de remplacement. |
| R11 | Modifier/importer une route via le recorder, options ouvertes puis fermées. | Catalogue actualisé ; la route active est réévaluée lorsque nécessaire. |
| R12 | Faire Maj + clic droit sur une route de test. | Progression de cette route réinitialisée puis route ajoutée au parcours. |
| R13 | Alterner parcours vide/rempli et onglets d’extension pendant plusieurs ouvertures. | Pas de lignes périmées, de doublons de contrôles ni de clic visant une ancienne route. |
| R14 | Survoler une route APR sans auteur, EclipseGlaives, puis une route importée avec auteurs/description ; répéter dans le parcours personnalisé et sur une route désactivée. | Auteur depuis les données (APR par défaut), origine et description si présente ; prérequis et indications de clic conservés. Après tri/recyclage, métadonnées de la bonne route. |

## 3. Progression, callbacks et annulation

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| Q01 | Enchaîner prise de quête, objectif et restitution. | Chaque étape attend sa vraie condition puis avance une seule fois. |
| Q02 | Terminer plusieurs étapes déjà satisfaites d'une longue route. | Avance automatique par lots sans blocage prolongé de l'interface. |
| Q03 | Sauter manuellement une étape puis cliquer immédiatement le bouton rollback du guide ; répéter avec `/apr rollback`. | Retour à l’index précédant ce saut, même si plusieurs étapes ont été traversées immédiatement. Sans saut annulable, rollback conserve le retour à l’étape précédente. Aucun état de quête WoW n’est restauré. |
| Q04 | Sauter une étape, puis progresser automatiquement ou changer de route. | L'ancien saut n'est plus annulable ; pas de retour dans une autre route. |
| Q05 | Faire deux sauts manuels puis annuler. | Un seul niveau d'annulation : le dernier saut. |
| Q06 | Ouvrir un choix de quête de groupe ; changer de route avant de répondre. | L'ancien callback ne modifie pas la nouvelle étape. |
| Q07 | Terminer une route et choisir/annuler la suggestion suivante ; tester aussi une suggestion déjà dans le parcours. | Une seule finalisation, parcours cohérent, aucune boucle de popup. |
| Q08 | Entrer/sortir d'une route temporaire ou d'un gouffre ; progresser dans un scénario disponible. | Progression temporaire et retour au parcours principal conservés. |
| Q09 | Satisfaire une condition de groupe parallèle, réputation ou niveau. | Insertion/visibilité et liste des étapes correspondent à l'état réel. |
| Q10 | Étapes disponibles d'objet/sort, foyer, portail/taxi, achat, banque, équipement, réparation. | Même action et mêmes gardes qu'avant découpage ; aucune action métier en consultant la liste future. |

## 4. Statut historique et export Lua

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| D01 | Ouvrir `/apr status` ou le bouton Statut des réglages, puis fermer. | Ancienne fenêtre compacte avec logo et trois sections : addon/client, route, personnage. Fermeture et réouverture des réglages comme auparavant. |
| D02 | Examiner le guide et son menu contextuel. | Aucun bouton `?`, aucune entrée d’explication ni d’annulation supplémentaire ; bouton rollback historique conservé. |
| D03 | Comparer le contenu au statut historique avec une route active. | Version APR/client, langue, région, date, route/index/action, continent/zone/coordonnées et classe/niveau/faction présents. Aucune explication d’attente ni section moteur ajoutée. |
| D04 | Ouvrir le statut plusieurs fois sur une route à groupes parallèles, puis sans route et avec APR désactivé. | Aucune action, insertion ni progression provoquée par la lecture ; absence de route indiquée sans erreur. |
| D05 | Exporter le rapport et utiliser Copier le rapport puis Ctrl+C. | Fenêtre défilante, noms des clés conservés, indentation et retours à la ligne. Informations du statut présentes. |
| D06 | Basculer le bouton de masquage puis exporter dans chacun des deux états. | Nom et royaume masqués par défaut ; affichés dans le statut et inclus dans l’export uniquement lorsque le masquage est désactivé. |
| D07 | Exporter avec identité visible puis réactiver le masquage dans le statut resté ouvert. | Identité retirée immédiatement du statut et du rapport déjà ouvert. Un export de performances ouvert séparément n’est pas remplacé. |
| D08 | Sélectionner le rapport puis modifier la police des textes APR ou progresser dans le guide. | Texte et sélection de l’export préservés ; aucun rafraîchissement périodique ajouté au statut. |
| D09 | Ouvrir le statut dans une instance ou sans position disponible. | Coordonnées indisponibles signalées selon le comportement historique ; aucune coordonnée inventée ni erreur Lua. |

## 5. Groupe

Utiliser un second joueur ou un second client contrôlé manuellement, avec une
version APR compatible. Les charges malformées sont couvertes par les tests Lua ;
il n'est pas nécessaire d'injecter des messages artificiels dans un groupe réel.

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| G01 | Groupe à deux, même route puis routes différentes. | Noms, progression et infobulles cohérents. |
| G02 | Tester des joueurs de royaumes différents ; inviter/quitter/rejoindre. | Pas de confusion d'identité, de doublon persistant ou d'attribution au mauvais expéditeur. |
| G03 | Objectifs contenant plusieurs lignes, puis changement rapide d'étape. | Fragments assemblés correctement ; pas de mélange entre deux messages ou deux joueurs. |
| G04 | Désactiver réception des données de groupe. | La préférence est respectée. Aucun spam d'erreurs ni de refus dans le chat. |
| G05 | Capture de performances pendant une minute de progression de groupe normale. | Mesure `PartyValidate` consultable. Comparer capture arrêtée/active ; noter les pics reproductibles. |

## 6. Liste des étapes et performances

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| P01 | Afficher une route de plus de 1 000 étapes ; défiler début/milieu/fin. | Pas de lignes vides/stales ; survols correspondant aux bonnes quêtes. |
| P02 | Survoler une ligne puis défiler loin et revenir. | L'infobulle recyclée n'affiche pas l'ancienne quête. |
| P03 | Défilement manuel puis simple actualisation ; ensuite véritable progression. | Actualisation stable ; progression suit la nouvelle étape. |
| P04 | Redimensionner la liste, changer la taille de police et terminer un objectif de collecte. | Hauteurs recalculées, détails passés repliés et aucune superposition. |
| P05 | Changer de route ou masquer la liste pendant sa construction. | Aucun ancien rendu ne remplace la nouvelle route ; le travail obsolète est annulé. |
| P06 | `/apr perf` avant capture, puis Démarrer. | État vide lisible ; appels, cumuls, moyennes, maxima, histogrammes au survol et graphique alimentés. |
| P07 | Changer tri/recherche et passer aux appels lents/compteurs. | Tri cohérent, appels lents récents en premier, compteurs de cache visibles lorsqu'ils sont sollicités. |
| P08 | Fermer le dashboard en capture, puis le rouvrir et arrêter. | Capture poursuivie sans ticker de fenêtre ; après arrêt, chiffres et graphique figés. |
| P09 | Laisser une capture dépasser 120 secondes ; exporter. | Fenêtre glissante de 120 secondes, au plus 100 appels lents et 65 noms par famille de mesures. |
| P10 | Effacer puis démarrer une nouvelle capture. | Anciennes mesures effacées ; l'effacement seul n'active pas une capture arrêtée. |
| P11 | Faire reload après une capture. | Données conservées dans `APRData.PerformanceLog`, capture inactive au nouveau login. |
| P12 | Survoler début/milieu/fin du graphique, y compris une seconde vide, à plusieurs échelles UI. | Bonne seconde sélectionnée ; appels, cumul, moyenne, maximum, appels lents et contexte du pic dans l’infobulle. Aucun chiffre inventé sur un ancien relevé. |
| P13 | Alterner maximum, cumul et appels par seconde. | Axe et hauteur des barres correspondent à la mesure ; les barres restent dans le graphique. |
| P14 | Figer le graphique, continuer à jouer puis reprendre. | Graphique et infobulles figés ; capture et tableaux continuent ; reprise sur les 120 dernières secondes. |
| P15 | Figer puis effacer/démarrer une nouvelle capture ; fermer sous le curseur. | Ancien graphique libéré, nouveau relevé visible, infobulle et marqueur masqués à la fermeture. |

Les durées sont celles des appels APR instrumentés. Les appels imbriqués se
recouvrent : additionner leurs durées ne donne pas le CPU total de l'addon.
Une micro-mesure Lua hors jeu ne garantit pas l'absence de lag en situation réelle.

## 7. Fenêtres WoW, skins et combat

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| U01 | Déplacer les fenêtres de jeu par leurs en-têtes et reload. | Positions historiques conservées avec LibWindow. |
| U02 | Modifier les ancrages guide/fillers/AFK/liste depuis les options. | Fenêtres liées positionnées selon les mêmes réglages qu’avant le retour UI. |
| U03 | Utiliser les actions historiques de remise à zéro des positions dans les options. | Fenêtres récupérables à l’écran ; aucun éditeur de contours supplémentaire. |
| U04 | Entrer en combat avec le statut puis exporter et masquer les identifiants. | Lecture, export et masquage fonctionnels ; aucun déplacement de parent protégé ni action de quête déclenchée. |
| U05 | Ouvrir réglages/statut pendant un combat. | Pas d'erreur ; actions incompatibles désactivées/différées. |
| U06 | Examiner guide, groupe, liste, images, popups, statut et performances en APR natif. | Aspect WoW, couleurs personnalisées conservées, actions fonctionnelles. |
| U07 | Replier/déplier guide et liste. | Fonds repliés transparents et contenu correctement restauré. |
| U08 | Charger un ancien profil utilisant Moderne/Forever/Contraste. | Sur audit-clean, le thème effectif reste WoW ; aucun choix de thème expérimental dans les réglages. |
| U09 | Activer ElvUI ou EllesmereUI dans les options historiques puis reload. | Un seul fournisseur applique le skin ; aucun cumul de bordures. |
| U10 | Modifier les couleurs/polices EUI puis rouvrir les panneaux APR. | Contrôles APR actualisés ; options d'autres addons intactes. |
| U11 | Images de route, zoom, boutons d'objets/sorts et barres sous les skins. | Images non effacées, ratio conservé, attributs sécurisés et clics préservés. |
| U12 | Tester à échelles UI 0,8 / 1,0 / 1,2 si le client le permet, textes FR longs, petite fenêtre et autre résolution. | Pas de texte essentiel inaccessible, ni boutons superposés ; fenêtres ramenées à l'écran. |

## Critères de validation

Aucune erreur Lua ni erreur de protection imputable à APR ; progression et
parcours corrects ; rendu lisible sur les configurations retenues ; aucune fuite
de contrôles après ouvertures et défilements répétés. Les cas non applicables
doivent être justifiés, pas marqués comme réussis.

Pour un KO : joindre l'ID du cas, les versions exactes, le rapport de statut,
le résultat attendu/obtenu et, si pertinent, une capture de performances exportée.
