# Terrain Retail déjà présent dans V1

Les 48 déclarations de `NavigationData/Terrain_Standard.xml` sont conservées
intégralement dans `Route-generator/data/navigation_v2/retail/terrain/Surveys/*.json`.
Elles contiennent 11 304 nœuds, 23 296 liaisons, 80 597 ancrages et 159 900 points
de polyligne source. Aucune nouvelle collecte ni lecture d'algorithme V1 n'a servi
à cet import. Les captures historiques et les refus initiaux sont conservés.

Chaque JSON garde l'enregistrement public complet : `client`, `world`, `uid`,
`registrationHash`, `sourceSha256` et `data`. L'empreinte du Lua historique reste
distincte de celle de l'édition JSON courante. La copie initiale refuse d'écraser
une édition différente. Les règles Git locales maintiennent les fins de ligne LF
pour préserver ces empreintes entre plateformes.

Les 48 conversions produisent 122 869 nœuds et 132 757 arcs développés. Tous les
accès restent inconnus. Les 2 070 références externes et 34 transitions explicites
entre identités d'espace restent des lacunes, sans pont implicite. Les portions
locales convertibles restent présentes. Une transition d'espace, d'étage ou de
phase n'est pas une conjonction de deux identités sur une seule observation ;
elle porte le motif `identity_transition_unbound`, son index de segment et ses
deux références de positions. Géométrie, identités, contraintes et coût source
sont conservés. Des contraintes contradictoires seules ne créent pas de transition.

Les résultats dérivés sont dans
`.cache/navigation_v2/retail/terrain/Surveys/*.facts.json`. Ils sont reproductibles
avec l'API publique `tools.navigation_v2.import_terrain.convert_terrain_data`,
`identifier` et `name` du catalogue, `max_nodes=65536`, `max_arcs=262144` et
`walk_speed=7`. Ces bornes hors jeu ne modifient pas les budgets du moteur.
Les JSON canoniques sont les données éditables ; ne pas les remplacer par une
nouvelle copie historique lors d'une régénération.

`catalog.json` contient les références, empreintes et compteurs. `Catalog.lua`
est sa projection de métadonnées scalaires pour l'addon, sans points, arcs ou
charge utile cachée. Le Lua est limité à 65 536 octets et l'index à 1 MiB.
Le catalogue reste `facts-only`, `complete=false`, `authorization=unknown`.
Son chargement n'admet pas les géométries dans le planificateur et n'active pas V2.
V1 reste le moteur par défaut. Le build historique `12.1.5.70688` ne prouve pas
la compatibilité avec un autre build, la couverture physique ou une bascule.

Preuves : `.scratch/libaprnavigation-2/reports/NAV-20/retail-terrain-batch-20261104/`,
`reports/ORCHESTRATOR/retail-identity-transition/` et
`reports/ORCHESTRATOR/V1-retail-terrain-canonical-promotion/` dans le dépôt APR.
