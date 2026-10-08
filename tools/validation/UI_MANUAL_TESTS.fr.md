# Validation manuelle de la sélection de routes

À exécuter dans WoW après `/reload`, sur Retail et Forever. Les tests Lua
simulent les contrôles ; ils ne valident pas le rendu du client.

## Apparence et interactions

- Ouvre `/apr route`. Vérifie le médaillon APR dans l'angle : logo net,
  cercle intact, aucun chevauchement avec le titre ou les parcours prédéfinis.
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
- Ouvre `/apr layout`, prévisualise un déplacement, annule puis recommence en
  validant. Vérifie que les positions ne sont enregistrées qu'à la validation.

En cas d'anomalie, conserve une capture, la version du client, le skin actif,
l'échelle d'interface et les étapes qui permettent de reproduire le problème.
