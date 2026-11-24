# APR Terrain

Depuis la racine du dépôt sur Windows, lancez l’interface avec cette commande PowerShell.

```powershell
python tools/terrain_ui/server.py
```

Dans VS Code, ouvrez `server.py` et utilisez **Run Python File**. Le navigateur s’ouvre sur `http://127.0.0.1:8765/`. Gardez le terminal ouvert pendant la génération.

L’application détecte les produits Battle.net actifs dans les installations trouvées sur le PC. Passez `--wow "D:\Jeux\World of Warcraft"` pour ajouter un dossier et `--port 8766` si le port est déjà occupé.

- Le choix **Tous les continents et mondes** couvre toutes les cartes dont le client fournit la géométrie. Une sélection plus précise produit un pack des tuiles rattachées au périmètre.
- **Rechercher une carte** accepte un nom ou un identifiant. Utilisez un préfixe comme `MapID 0`, `UiMapID 37` ou `AreaID 18` pour préciser le type d’identifiant.
- **Français** et **English** changent l’interface immédiatement. Les noms de lieux proviennent du client sélectionné, avec un repli sur la langue disponible.
- Une pause attend le prochain point d’arrêt du moteur. L’estimation apparaît lorsque la progression permet de la calculer.
- **Journaux du moteur** permet de télécharger le journal intégral et le rapport JSON. Le rapport indique les tuiles exclues, leurs causes, les niveaux ou transitions impossibles à encoder et l’étape d’un éventuel échec.
- Les erreurs temporaires de lecture déclenchent une nouvelle lecture des tuiles concernées. **Relancer les cartes à traiter** reprend les cartes partielles ou en échec avec la même sélection et les mêmes réglages.
- Si le graphe d’une carte dépasse la capacité du format, le moteur retente la génération de toutes ses tuiles à la résolution inférieure. Le rapport JSON indique la résolution utilisée pour chaque carte générée.
- Lorsqu’un modèle de terrain est introuvable, le moteur vérifie les identifiants dans l’index CASC complet du build. Les références orphelines sont consignées dans le journal. Les fichiers présents dans l’index dont la lecture échoue continuent d’être signalés comme des erreurs.
- Les packs vérifiés sont installés dans `APR-Core/libs/LibAPRNavigation-1.0/Data/<profil>/Terrain/<ID de carte>`. Le manifeste `Terrain.xml` du profil référence celui de chaque carte, avec ses fichiers Lua dans `Nav/`.
- Les PTR utilisent un dossier par produit sous `Data/retail/Terrain`, comme `wowt/<ID de carte>`. Le build reste dans les métadonnées et contrôle le chargement en jeu. Un nouveau build réutilise le dossier de la carte.
- Une nouvelle sélection sur le même build reprend les tuiles déjà installées sur la carte et recalcule leurs raccords. Les fichiers de travail, `report.json` et `generation.log` sont dans `.cache/terrain-ui`.

Le script `python tools/generate_retail_graphs.py` publie également les packs Retail vérifiés dans cette structure. Utilisez `--cache-only` pour garder les résultats uniquement dans le cache de génération.

Le lanceur réutilise les sources et dépendances du générateur terrain préparé pour ce dépôt, notamment Rust, CascLib, les définitions WoWDBDefs et la liste locale des textures de route. La première exécution peut compiler le moteur local et récupérer les définitions publiques manquantes.
