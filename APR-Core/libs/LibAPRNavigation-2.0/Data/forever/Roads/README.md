# Routes et collisions Forever reprises de V1

Les données éditables sont dans le dépôt voisin :
`Route-generator/data/navigation_v2/forever/roads/Networks/*.json` et
`Collision/*.json`. Les 60 captures JSON initiales conservent exactement les
déclarations V1 existantes : 30 réseaux et 478 masques. Aucune nouvelle collecte
ni lecture des algorithmes V1 n’a été nécessaire à leur promotion.

Chaque fichier garde le format `v1-road-data-capture/1`. Le contenu `data` de
chaque déclaration reste éditable. `sourceSha256` identifie le Lua d’origine ;
le SHA canonique de l’édition courante est recalculé séparément lors de l’export.
La commande d’import initial ne remplace jamais une édition existante. Modifier
les données canoniques, puis exporter : ne pas relancer une copie écrasante du
Lua historique sur une édition maintenue.

Depuis `Route-generator`, régénérer les métadonnées avec :

```powershell
python -m tools.navigation_v2.import_road_data export-catalog --root data/navigation_v2/forever/roads --output ../azeroth-pilot-reloaded/APR-Core/libs/LibAPRNavigation-2.0/Data/forever/Roads/Catalog.lua --max-nodes 65536 --max-edges 65536
```

`catalog.json` est l’index dérivé : références de fichiers, SHA d’origine et de
l’édition, révisions, en-têtes de collisions et état de conversion. L’export
redécouvre les JSON présents et réutilise le sérialiseur Lua existant. Le Lua
chargé par le manifeste ne contient que des métadonnées scalaires sur les réseaux,
sans points, arcs, cellules ou charge utile cachée. Sa limite est 65 536 octets ;
l’index JSON est limité à 1 MiB. Les remplacements sont atomiques par fichier,
sans transaction OS commune entre l’index et le Lua.

La première promotion du 4 novembre 2026 produit 30 déclarations de graphes,
dont les quatre réseaux précédemment refusés par les petites bornes. Les défauts
du convertisseur restent 4 096 nœuds et 8 192 arcs ; les bornes 65 536/65 536
sont un choix explicite hors jeu. Les quatre résultats supplémentaires sont
des sorties dérivées dans `.cache/navigation_v2/forever/roads/Networks/`,
reproductibles depuis les JSON canoniques. Ils ne remplacent pas ces derniers.

`conversion="converted"` indique uniquement une conversion de déclarations,
pas un trajet admis ou une couverture physique vérifiée. Les hauteurs, conditions,
phases et permissions manquantes restent inconnues. Un masque ouvert ou une
référence voisine ne crée aucune autorisation de marche. Les refus de compilation
des secteurs pour contraintes ou hauteurs non représentables restent légitimes.

Le catalogue addon reste `facts-only`, `complete=false`, `authorization=unknown`.
Son chargement n’active aucun planificateur et ne publie pas les géométries dans
le runtime. V1 reste le moteur par défaut. La couverture physique Arathi, les
autres fiches de terrain et la bascule V2 ne sont pas déclarées terminées.

Les preuves de capture initiale, de promotion et des quatre reconversions sont
conservées dans `.scratch/libaprnavigation-2/reports/FZ-arathi-highlands/` et
`reports/ORCHESTRATOR/V1-road-canonical-promotion/` du dépôt APR. La revue ROOT
vérifie les octets des captures, les SHA des sources V1, les 23 pins, l’égalité
du Lua et de sa projection JSON, les limites de taille et les sorties dérivées.
