# Terrain Forever déjà présent dans V1

Les déclarations éditables sont conservées intégralement dans
`Route-generator/data/navigation_v2/forever/terrain/Surveys/*.json`.
Il s'agit des 32 fichiers déclarés par `NavigationData/Terrain_Camelot.xml` :
11 652 nœuds, 27 820 liaisons, 115 270 ancrages et 214 276 points de polyligne
dans les données d'origine. Aucune nouvelle collecte ni aucun algorithme V1
n'a été utilisé. Les identités de monde, portée, étage et phase restent celles
des déclarations, sans rapprochement automatique par coordonnées.

Chaque JSON garde l'enregistrement public complet : `client`, `world`, `uid`,
`registrationHash`, `sourceSha256` et `data`. Le SHA du Lua historique est
distinct du SHA de l'édition JSON courante. La copie initiale ne remplace jamais
une édition existante. Les frontières `terrainBoundary`, les points `sharedPoint`,
les références de paquets voisins, les conditions et les géométries sont conservés.

Les conversions utilisent l'API publique neuve
`tools.navigation_v2.import_terrain.convert_terrain_data`, avec `identifier` et
`name` du catalogue, `max_nodes=65536`, `max_arcs=262144` et `walk_speed=7`.
Ces bornes sont explicites hors jeu ; les défauts du moteur restent inchangés.
Les sorties dérivées reproductibles sont dans
`.cache/navigation_v2/forever/terrain/Surveys/*.facts.json`. Elles ne constituent
pas les données éditables et leur absence dans un nouveau checkout est normale.

Les 32 conversions initiales produisent 172 452 nœuds et 186 412 arcs développés,
avec 2 208 références externes non résolues. Ces références restent des lacunes,
sans pont implicite. Tous les accès de ce premier graphe restent inconnus.
Ce constat décrit les **anciens dérivés**, pas une absence de liaisons V1 :
le contrat public du format 1 déclare déjà ces liaisons et leurs polylignes.
Le traducteur traite maintenant une liaison ground valide sans champ `access`
comme disponible dans le modèle déclaré. Les accès unknown/unavailable et disabled
explicites, les conditions, la hauteur et les coûts restent contrôlés ; une
référence collision opaque demeure conservatrice. Ce n'est pas une nouvelle
validation physique ni une permission de relier des points proches.

`tools.navigation_v2.terrain_links.resolve_terrain_links(registrations, ...)`
normalise les liaisons inter-paquets d'une collection fournie, par client, UID,
nœud et neighborScopeID exacts. Il retourne `sources`, `links`, `gaps`, `counts`.
Chaque link conserve ses deux références, positions, polyligne complète,
faits (dont sharedPoint, conditions et bidirectional), accès et coût explicite
ou modèle. Chaque gap conserve la déclaration complète et sa cause. Les
contraintes des sources/portées et des nœuds restent accessibles ; leur vérité
n'est pas inventée. Le sens inverse n'est jamais déduit de coordonnées égales.
Les liens nuls déclarés sont valides lorsque leur géométrie est cohérente.
Bornes offline : 128 sources et 262 144 candidats au maximum ; annulation
optionnelle sans résultat partiel trompeur. Cette API ne lit ni n'écrit de fichier.

L'audit en lecture seule des canoniques a trouvé les cibles exactes des 2 208
références dans les 32 relevés : 2 204 coutures nulles et quatre connexions
non nulles avec leurs polylignes. L'unité de normalisation a été vérifiée avec
des collections inventées ; aucun export massif ou catalogue n'a été réécrit.
Le convertisseur d'un fichier isolé continue à signaler ses références externes
sans contexte comme lacunes. Le futur packaging doit utiliser la collection,
sans confondre ce manque de contexte local avec du terrain source manquant.

Le build historique `1.60.1.70707` ne prouve pas la compatibilité du terrain avec
un autre build. Les mentions de couverture dans les données d'origine sont
conservées comme faits de provenance, sans devenir une validation physique V2.

`catalog.json` contient les références et empreintes des éditions courantes,
ainsi que les métadonnées et compteurs de conversion. `Catalog.lua` en est la
projection scalaire pour l'addon : pas de points, d'arcs ni de charge utile cachée.
Sa taille est limitée à 65 536 octets, celle de l'index à 1 MiB. Pour modifier une
déclaration, éditer le JSON puis recalculer conversion, empreinte et métadonnées ;
ne pas écraser l'édition maintenue avec une nouvelle copie historique.

Le catalogue reste `facts-only`, `complete=false`, `authorization=unknown`.
Son inscription au manifeste n'admet pas ces géométries dans le planificateur et
n'active pas V2. V1 reste le moteur par défaut. Les tickets de couverture physique,
les critères de performance et la bascule ne sont pas déclarés terminés.

Preuves initiales : `.scratch/libaprnavigation-2/reports/NAV-20/forever-terrain-batch-20261104/`,
`forever-terrain-reconversion-20261104/` et
`reports/ORCHESTRATOR/V1-terrain-canonical-promotion/` dans le dépôt APR.
