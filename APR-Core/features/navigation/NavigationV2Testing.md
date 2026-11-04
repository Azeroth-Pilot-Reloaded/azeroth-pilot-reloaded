# V2 dans le guidage APR

Après rechargement de l’interface, V1 reste le moteur par défaut.

- `/apr navengine v2` : utiliser V2 pour le guidage de l’étape APR courante.
- `/apr navengine v1` : revenir à V1 et annuler le calcul V2 en cours.
- `/apr navengine` : afficher le moteur sélectionné.
- `/apr navbench` : ouvrir le banc de comparaison indépendant du moteur de guidage.

Le choix vaut pour la session et ne modifie pas les réglages enregistrés.
La route APR doit être active et l’addon activé. La flèche et les étapes utilisent
le contrôleur APR existant ; le calcul V2 ne fait pas avancer les quêtes.

Pour ce mode d’essai, les sorts, objets, portails et transports sont à utiliser
manuellement. L’arrivée observée permet ensuite de poursuivre l’itinéraire.
Le mode ne crée aucun bouton sécurisé et ne déclenche aucune action protégée.

Forever utilise les données V1 de terrain, chemins, collisions et transports.
Retail utilise les passages et transports déclarés avec les modes réellement
disponibles, dont la monture draconique. Un fait ou un raccord indisponible est
signalé ; V2 ne remplace pas silencieusement son résultat par un calcul V1.

Les calculs sont coopératifs et bornés : 1 ms par tranche, 100 ms CPU cumulées,
5 s écoulées, préparation et recherche comprises. L’ETA du trajet est distincte
du temps de calcul. Les vérifications automatisées utilisent des positions et
des API contrôlées ; elles ne certifient pas un parcours dans le client du jeu.
