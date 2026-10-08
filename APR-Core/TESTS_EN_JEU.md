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
| APR natif, thème Forever | À tester | À tester |
| APR natif, thème Moderne bleu canard | À tester | À tester |
| APR natif, thème Contraste élevé | À tester | À tester |
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
| S02 | Ouvrir `/apr`. | Accueil avec réglages essentiels, Routes, Placement, Performances et Diagnostic. |
| S03 | Modifier affichage du guide, flèche, groupe et liste des étapes. | Le comportement correspond aux mêmes options dans les réglages avancés. |
| S04 | Activer l'acceptation des quêtes de route, puis l'acceptation de toutes les quêtes dans les options avancées. | Les options mutuellement exclusives restent cohérentes. |
| S05 | Rechercher une option de navigation, une couleur et une option absente. | Résultats pertinents ; accès à la catégorie avancée ; message clair sans résultat. |
| S06 | Désactiver APR depuis l'accueil, puis le réactiver. | Les fonctions de jeu suivent l'activation ; l'accueil reste accessible. |
| S07 | Changer de profil AceDB, puis reload. | Les réglages, favoris, thème et positions suivent le profil ; les préférences personnage gardent leur scope. |
| S08 | Ouvrir/fermer plusieurs fois ; fermer avec Échap. | Pas de saisie clavier capturée après fermeture, ni multiplication de fenêtres. |

## 2. Bibliothèque et parcours

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| R01 | `/apr route`, sélectionner Midnight puis plusieurs catégories. | Liste filtrée, fiche lisible et nombre de résultats cohérent. |
| R02 | Rechercher un nom avec/sans accents, plusieurs mots et un auteur. | Recherche littérale dans nom, clé, extension, catégorie et auteur. Les filtres actifs restent appliqués. |
| R03 | Onglet Communauté sur un personnage Alliance éligible à la route 10–70. | La route `84-EclipseGlaives-10-to-70` porte l'auteur EclipseGlaives ; les autres routes sans métadonnée explicite affichent APR. |
| R04 | Même recherche sur un personnage incompatible. | Une route incompatible reste masquée. L'onglet Communauté ne contourne pas les conditions de faction/client. |
| R05 | Ajouter/retirer un favori, changer de filtre, fermer puis reload. | Le favori est conservé dans le profil, sans changer la progression. |
| R06 | Inspecter une route sous le niveau requis ou hors de sa zone requise. | Fiche consultable, raison d'indisponibilité affichée, ajout désactivé. |
| R07 | Ajouter une route avec des prérequis non terminés. | Les prérequis applicables sont ajoutés avant elle, sans doublon. |
| R08 | Onglet Mon parcours : monter, descendre, retirer une route. | Ordre sauvegardé correct ; les boutons agissent sur la sélection actuelle, y compris après défilement. |
| R09 | Retirer la dernière route. | Guide sans route, flèche arrêtée et invitation au choix d'un parcours ; aucune erreur. |
| R10 | Ouvrir les parcours prédéfinis leveling, quêtes et speedrun. Annuler puis accepter le remplacement speedrun. | L'annulation conserve le parcours ; l'acceptation utilise les constructeurs existants. |
| R11 | Modifier/importer une route avec le recorder, bibliothèque ouverte puis fermée. | Catalogue actualisé ; une modification de route active relance le moteur, une autre n'y touche pas. |
| R12 | Garder dans un parcours une route devenue indisponible/supprimée. | Elle reste visible dans Mon parcours et peut être retirée. |
| R13 | Redimensionner, déplacer, fermer puis reload. Tester une largeur proche du minimum. | Position/dimensions conservées et fenêtre accessible ; titres longs lisibles dans la fiche/infobulle. |

## 3. Progression, callbacks et annulation

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| Q01 | Enchaîner prise de quête, objectif et restitution. | Chaque étape attend sa vraie condition puis avance une seule fois. |
| Q02 | Terminer plusieurs étapes déjà satisfaites d'une longue route. | Avance automatique par lots sans blocage prolongé de l'interface. |
| Q03 | Sauter manuellement une étape puis utiliser `/apr undo` immédiatement, ou le bouton du diagnostic. | Retour à l'index précédant ce saut, puis réévaluation normale des conditions. Aucun état de quête WoW n'est restauré. |
| Q04 | Sauter une étape, puis progresser automatiquement ou changer de route. | L'ancien saut n'est plus annulable ; pas de retour dans une autre route. |
| Q05 | Faire deux sauts manuels puis annuler. | Un seul niveau d'annulation : le dernier saut. |
| Q06 | Ouvrir un choix de quête de groupe ; changer de route avant de répondre. | L'ancien callback ne modifie pas la nouvelle étape. |
| Q07 | Terminer une route et choisir/annuler la suggestion suivante ; tester aussi une suggestion déjà dans le parcours. | Une seule finalisation, parcours cohérent, aucune boucle de popup. |
| Q08 | Entrer/sortir d'une route temporaire ou d'un gouffre ; progresser dans un scénario disponible. | Progression temporaire et retour au parcours principal conservés. |
| Q09 | Satisfaire une condition de groupe parallèle, réputation ou niveau. | Insertion/visibilité et liste des étapes correspondent à l'état réel. |
| Q10 | Étapes disponibles d'objet/sort, foyer, portail/taxi, achat, banque, équipement, réparation. | Même action et mêmes gardes qu'avant découpage ; aucune action métier en consultant la liste future. |

## 4. Explication et rapport

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| D01 | Cliquer `?` dans le guide ou `/apr status`, sans route puis avec APR désactivé. | Explication adaptée, aucune erreur de nil. |
| D02 | Étape d'objectif avec quête absente, puis quête dans le journal. | Quête absente distinguée d'un objectif restant ou de données encore indisponibles. |
| D03 | S'éloigner de la zone d'étape ; tester une étape d'action non liée à une quête. | Indication de guidage hors zone ou texte réel de l'action attendue. Pas de cause inventée. |
| D04 | Ouvrir le diagnostic plusieurs fois sur une route à groupes parallèles. | L'ouverture ne déclenche ni action, ni insertion, ni progression. |
| D05 | Actualiser et exporter ; faire Ctrl+C après sélection du rapport. | Client/build, route/étape, raisons, transitions, zone, skin et mesures sont copiables. |
| D06 | Activer/désactiver l'inclusion d'identité. | Nom et royaume absents par défaut et présents seulement sur demande. Les textes libres de routes ne sont pas anonymisés. |
| D07 | Fermer pendant des notifications de quêtes. | Le rafraîchissement différé est annulé ; aucun travail périodique de cette fenêtre fermée. |

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

Les durées sont celles des appels APR instrumentés. Les appels imbriqués se
recouvrent : additionner leurs durées ne donne pas le CPU total de l'addon.
Une micro-mesure Lua hors jeu ne garantit pas l'absence de lag en situation réelle.

## 7. Placement, thèmes et combat

| ID | Manipulation | Résultat attendu |
| --- | --- | --- |
| U01 | Placement : déplacer plusieurs contours puis Annuler/Échap. | Les positions réelles restent inchangées. |
| U02 | Refaire le déplacement puis Enregistrer et reload. | Positions conservées ; fenêtres liées suivent leur guide. |
| U03 | Recentrer les fenêtres, puis Annuler ; refaire et Enregistrer. | Prévisualisation réversible, puis récupération effective à l'écran. |
| U04 | Entrer en combat pendant l'édition. | Édition fermée et modifications non enregistrées ; aucun déplacement de parent protégé. |
| U05 | Ouvrir réglages/diagnostic pendant un combat. | Pas d'erreur ; actions incompatibles désactivées/différées. |
| U06 | Tester les quatre thèmes en intégration APR, avec guide, groupe, liste, images et popups. | Contraste lisible, contenu préservé, boutons fonctionnels et fonds cohérents. |
| U07 | Replier guide/liste, changer de thème, déplier. | Le fond replié reste transparent ; contenu et boutons réapparaissent correctement. |
| U08 | Personnaliser les couleurs WoW, choisir un autre thème puis revenir à WoW. | Les couleurs demandées et les fonds d'origine sont retrouvés. |
| U09 | Sélectionner un skin externe et recharger via le bouton. | Le fournisseur choisi possède l'apparence ; aucun cumul de bordures/skins. |
| U10 | Modifier les couleurs/polices EUI puis rouvrir les panneaux APR. | Contrôles APR actualisés ; options d'autres addons intactes. |
| U11 | Images de route, zoom, boutons d'objets/sorts et barres sous les skins. | Images non effacées, ratio conservé, attributs sécurisés et clics préservés. |
| U12 | Tester à échelles UI 0,8 / 1,0 / 1,2 si le client le permet, textes FR longs, petite fenêtre et autre résolution. | Pas de texte essentiel inaccessible, ni boutons superposés ; fenêtres ramenées à l'écran. |

## Critères de validation

Aucune erreur Lua ni erreur de protection imputable à APR ; progression et
parcours corrects ; rendu lisible sur les configurations retenues ; aucune fuite
de contrôles après ouvertures et défilements répétés. Les cas non applicables
doivent être justifiés, pas marqués comme réussis.

Pour un KO : joindre l'ID du cas, les versions exactes, le rapport de diagnostic,
le résultat attendu/obtenu et, si pertinent, une capture de performances exportée.
