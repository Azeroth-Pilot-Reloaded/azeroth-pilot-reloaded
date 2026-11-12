# Automatic quest rewards

Enable automatic quest rewards in APR's reward options. The **Item Upgrade**
priority compares stat scores against equipped items. Existing priority orders
are retained; their historical SavedVariables value `ilvl` now selects this
comparison. Appearance and vendor-price priorities still apply in their chosen
order when there is no positive upgrade.

The shared APR selector offers its leveling baseline and Pawn scales belonging
to the character's class, including every specialization of that class. Custom
imports without class metadata are included only when Pawn enables them for this
character; unclassified provider scales are excluded. A Pawn choice belongs to the
character and specialization, so changing an account-wide APR profile does not select another character's scale. APR uses
the exact reward and equipped-item links, including bonus and scaling variants.
It selects the largest positive replacement gain, with reward order breaking ties.
It never equips the item automatically.

## APR baseline

`RewardScoring.lua` contains independently authored leveling weights. Every class
has a fallback, while native specialization data supplies the main attribute and
role when available. Secondary attributes and survival stats contribute smaller
amounts; tanks value survival more, physical profiles value weapon DPS, and
Forever profiles can value mana regeneration. These are general leveling
estimates. Special effects, set bonuses, caps and encounter mechanics require a
more specific scale or manual choice.

The comparison rejects unusable equipment and accounts for the actual slots
replaced: rings and trinkets, unique-equipped restrictions, main/off hand and
two-handed configurations, including legal moves of equipped weapons between
hands. An unknown score or item record suspends the choice
instead of treating it as zero. Five bounded retries belong to the open quest
interaction; closing the interaction, changing quest/profile/step, disabling
automation or holding a modifier prevents a delayed hand-in. Persistent missing
data leaves the quest available for manual selection.

Weapon gains compare the complete before/after hand configurations, including
the new contribution of any retained weapon that changes hands. APR's simple
baseline gives offhand weapon DPS half its main-hand contribution; attributes,
armor, shields and frills retain their full stat contribution. This models base
weapon attacks, not talent modifiers or individual techniques. The existing
client/capability checks still govern dual wield, Titan's Grip, two-handed pairs
and Forever's independent ranged slot. No class weights are imported or revised.

Bag suggestions execute a permutation only when its first configuration cannot
lower the original score. They verify all equipped slots after that action before
issuing the second action in the same user click. A failed or unconfirmed action
stops the plan; timers and events never continue equipping. A permutation needing
a temporary downgrade remains a manual operation, even if its final configuration
would improve a quest reward's score.

## Pawn integration

Pawn is optional. APR reads its scale list and delegates scoring to
`PawnGetItemData(exactLink)` and `PawnGetSingleValueFromItem(item, scaleName)`;
the base score is used consistently for rewards and equipped items. APR does not
change Pawn scales or its visible-scale preferences. Its own slot comparisons
remain independent of Pawn's tracked best items.

Pawn's public scalar API has no destination-hand parameter. APR therefore rejects
permutations that move a retained weapon when using that provider, rather than
assuming its score can be transferred between hands. Direct replacements remain
available. APR does not reconstruct Pawn's contextual weapon scores or copy its
weights.

Recommendations respect the selected scale's `DoNotShow1HUpgrades` (including
shields and held offhands) and `DoNotShow2HUpgrades`. These are suggestion filters,
not equipment capabilities: they never zero the equipped baseline. `IsOffHand`
at Pawn's ignore threshold prevents a generic weapon from being recommended in
the offhand; it does not prohibit shields/frills. Native dual-wield checks remain
independent. `PawnIsArmorBestTypeForPlayer` supplies the class/level/client armor
policy, including Retail specialization and Forever's broader pre-specialization
choices. An unavailable armor check cannot authorize an armor recommendation.

Weapon suggestion toggles change decision identities and refresh bags via their
public Pawn setter. Level changes refresh the armor context with scoped
`UNIT_LEVEL` handling. Old scorers reject stale settings/levels. These settings
do not change weights and therefore do not trigger a weight-confirmation offer.
Explicitly selected hidden scales remain usable. APR does not adopt Pawn's
tracked-inventory comparisons or its current-weapon-handedness shortcut: APR
continues comparing complete legal replacements against equipment actually worn.

Secure post-hooks observe scale edits/imports, and a coalesced snapshot detects
actual changes. Custom scales added or modified while automatic rewards are
active trigger an in-game offer to use that version. Combat defers the offer.
Accepting a stale offer cannot select a deleted or subsequently edited scale.
Declining a version is remembered. A changed or unavailable selected scale
suspends weighted recommendations until it is explicitly selected or confirmed;
selecting APR explicitly releases that pending choice. A popup that cannot be
shown, is replaced, or is hidden by the client leaves its version pending. A native popup closure triggers a coalesced
retry; only an explicit user refusal is remembered. The visible reward settings
refresh their catalog, selected scale and status after these changes. No recurring
polling or per-frame scan is used.

## API references and verification

- [Pawn API and scale mutations](https://github.com/VgerMods/Pawn/blob/5bcfda4076ec2beeb8ada58ed396a2d8ba296181/Pawn.lua):
  `PawnIsReady`, `PawnGetAllScalesEx`, `PawnGetAllStatValues`, item scoring.
  Pawn 2.14.1 declares Retail and Forever support. Its code/weight tables are not
  bundled or copied into APR.
- [Pawn recommendation rules](https://github.com/VgerMods/Pawn/blob/main/Pawn.lua),
  [scale templates](https://github.com/VgerMods/Pawn/blob/main/ScaleTemplates.lua)
  and [client armor thresholds](https://github.com/VgerMods/Pawn/blob/main/Core.lua)
  were checked for this integration (Pawn 2.1402). No Pawn weights are copied.
- Blizzard's [Retail quest choices](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestInfo.lua)
  and [Forever quest choices](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Vanilla/QuestInfo.lua)
  use the fifth `GetQuestItemInfo` result for reward usability.
- `C_Item.GetItemInfo`, `GetItemStats`, `IsEquippableItem`, `GetItemUniqueness`,
  `C_PlayerInfo.CanUseItem` and specialization data were checked against current
  Retail/Forever sources and the oldest supported Retail branch (11.2.7).
  Optional functions have explicit runtime guards.

Synthetic tests cover scoring, replacement configurations, exact variants, Pawn
mutation lifecycles and delayed quest interactions. Before release, check the
settings and a real hand-in on both clients, with Pawn absent and installed;
import/edit/delete a scale, switch specialization and reload. Simulated API
tests do not certify native item data, game rendering or combat restrictions.
