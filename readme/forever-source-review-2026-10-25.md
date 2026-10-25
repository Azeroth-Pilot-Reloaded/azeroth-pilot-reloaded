# Revue des sources Forever — 25 octobre 2026

Référence APR avant revue : `5526e68c`. Sources locales :
`../RXPGuides_crack/Guides/Forever`, comparées au snapshot du 18 octobre conservé
dans Route-generator. Les sources ne sont pas modifiées.
Les corrections du convertisseur sont dans le commit local `a8982a7` de
Route-generator ; les modifications antérieures de ce dépôt restent hors de
ce commit.

## Changements retenus

- **Skyborne** : intégration des acceptations et branches de quêtes réellement
  nouvelles, réorganisation de la visite Horde 98512 dans le circuit côtier,
  prérequis de premiers soins et trajet précis dans Hurlevent. Les corrections
  APR de classes, retours, sauts de mort et quêtes facultatives restent en place.
  Route ordinaire : 1 057 → 1 075 étapes ; Mage : 571 → 581.
- **Westfall** : retrait des trois actions de la quête 102. La source désactive
  maintenant explicitement son acceptation, son objectif et son rendu. Les
  autres actions du parcours sont conservées.
- **Silverpine** : livre 210177 et quête 79096 pendant les visites existantes
  des Mage, Priest et Warlock ; reprise possible au PNJ si le livre est déjà
  possédé. QuestieDB confirme le donneur au sol, le PNJ et l'objet : aucune
  conversion en quête lâchée par un monstre. Des objectifs 447 facultatifs
  accompagnent neuf branches de combat ou trajet existantes. Aucune nouvelle
  phrase. Route : 490 → 494 étapes.

Les métadonnées, préfabriqués et actions parallèles des routes modifiées sont
conservés. Les exports bruts ne remplacent pas les parcours maintenus : plusieurs
perdraient des achats facultatifs, branches, retours ou textes déjà traduits.

## Changements écartés après comparaison avec APR

- Durotar 99048/99049 est déjà universel : les treize combinaisons Orc/Troll et
  les deux parcours Mage contiennent la chaîne complète une seule fois.
  L'avancer au premier circuit côtier anticiperait le niveau minimum 9 ; retirer
  les filtres de branches créerait des répétitions.
- Night Elf 1–10 et Mulgore n'ont aucun changement de gameplay ; les sources Mage
  dédiées ne changent que leurs en-têtes.
- La nouvelle section Loch Modan est incluse dans Darkshore. Elle ne devient
  pas une route autonome supplémentaire. Les gardes de quêtes déjà garanties
  par les rendus APR précédents ne sont pas recopiées. Deux marqueurs `step`
  auxquels il manque `<<` sont corrigés uniquement pour leurs sélecteurs connus,
  afin de conserver les branches de classes séparées.
- Les familles ordinaires, avec donjons et quêtes de donjons du nouveau bundle
  sont séparées avant conversion. Les chapitres Horde maintenus gardent la
  source dédiée `_02` déjà revue. `_02`, `_03` et `_04` sont inchangés ; `_01`
  contient de véritables itinéraires alternatifs qui nécessitent leur propre
  évaluation. Leur présence ne démontre pas un gain de temps.
- Le lot étendu contient 42 IDs candidats absents d'APR. Par exemple, 98027 est
  proposé avant le minimum de niveau 25 relevé dans les données locales ;
  certaines nouvelles escortes ont un coût inconnu et trois IDs de chaîne
  manquent dans QuestieDB. Ces nouveautés restent dans un inventaire documenté,
  sans les ajouter comme obligations au parcours maintenu.
- Les variations de couleur, noms de récompenses, liens de tutoriels et conseils
  qui répètent une action native n'ajoutent aucun texte au parcours.

## Traductions et comparaison des textes

`ResolveStepText` préfère une Global String WoW utilisable sans argument, puis
le catalogue APR/CurseForge, puis les textes Recorder. Une globale vide, une
fonction ou une chaîne de format ne masque pas la traduction.

Le catalogue CurseForge courant a été lu sans écriture : 3 712 clés, onze langues.
Le convertisseur accepte `APR_LOCALES_DIR`, décode les chaînes échappées et
réutilise 26 équivalences supplémentaires relues. La dernière sérialisation
relocalise aussi les notes réinjectées par les politiques : huit textes exacts
déjà traduits échappaient auparavant à ce traitement.

Les comparaisons `difflib` à 85–90 % servent uniquement au triage. Numéros de
Buzzbox, quantités, négations, potions et effets différents restent distincts.
Les consignes de déclenchement, accès ou danger sont conservées quand un objectif
de quête ne les explique pas.

Une seule nouvelle clé est nécessaire : `CANCEL_CARRY_AURA_IF_BIRD_ATTACKS`, pour
annuler l'aura de portage si un oiseau attaque. Son meilleur rapprochement avec
le catalogue courant n'est que de 49 %. Sa définition reste dans **enUS local,
exclu du commit** ; elle reste à publier/traduire dans CurseForge. Les deux
textes console TBC déjà signalés par le contrôle initial restent hors périmètre.

## Vérifications et reproduction

Les modes du convertisseur sont exécutés séparément, avec sorties privées :

```powershell
# Depuis Route-generator ; APR_LOCALES_DIR peut désigner un export CF local vérifié.
.venv/Scripts/python.exe tools/route_conversion/convert_collection.py --regular-1x --output <preview>/starters/routes --reports <preview>/starters/reports
.venv/Scripts/python.exe tools/route_conversion/convert_collection.py --include-extended --continuations --output <preview>/continuations/routes --reports <preview>/continuations/reports
.venv/Scripts/python.exe tools/route_conversion/convert_collection.py --include-extended --mage-aoe-only --output <preview>/mage/routes --reports <preview>/mage/reports
```

Les exports couvrent les familles existantes : 17 routes de départ, 66 chapitres
suivants et 18 Mage, plus la déclaration interne conservée. Les deux départs
manuels, la variante Paluns et les 22 routes de donjons restent présents dans APR.
Leurs clés ne sont pas supprimées pour correspondre à un export partiel.

Vérifications : schéma Lua 5.1, indices, conservation des champs hors modifications,
branches par personnage, refus des sources/empreintes inconnues pour Skyborne,
idempotence des politiques et suites APR. Les 588 tests APR passent ; les
329 tests ciblés du convertisseur et 169 tests de routes passent également après
la dernière correction d'ordre : sortie de la tour des Mages avant les visites
Druide/Chasseur, sans changement du trajet Mage. La suite globale historique du
convertisseur signale déjà, avant intégration des routes, 11 échecs et 8 erreurs
sur 458 tests : anciennes variantes retirées, instantanés et hypothèses de
catalogue périmés. Elle n'est pas présentée comme validée. Les régressions des
transformations concernées sont exécutées séparément.

Les avertissements de l'export brut des départs restent visibles : absence d'un
prochain rendu pour certaines navigations, seuils de niveau de quêtes de classe,
marqueurs visuels et commandes d'interface propres au guide source. Les parcours
maintenus et la réconciliation Skyborne servent de référence ; ces avertissements
ne sont ni transformés en prose à traduire, ni présentés comme une validation
complète de l'export brut. Les deux autres modes ont zéro anomalie de conversion.

Les rapports détaillés et exports de ce passage restent dans
`.cache/source-refresh-20261025/`. Les contrôles hors jeu ne mesurent pas un gain
chronométré et ne certifient pas les trajets ou crédits de quêtes dans WoW.

## Optimisations encore à examiner

- Remplacer progressivement les instantanés historiques de tests par des
  invariants de progression et des jeux de données isolés ; séparer les contrôles
  des familles de routes pour éviter les hypothèses de catalogue périmées.
- Évaluer séparément les nouvelles quêtes et escortes des itinéraires `_01`,
  avec prérequis, minimum de niveau, temps de détour et taux de butin. Ajouter
  une quête sans ces coûts ne suffit pas à améliorer une route.
- Conserver les gains déjà obtenus : collecte opportuniste pendant les combats,
  conseils redondants supprimés et réutilisation exacte des traductions jusque
  dans le dernier rendu. Les donjons feront l'objet de l'étape 2.
