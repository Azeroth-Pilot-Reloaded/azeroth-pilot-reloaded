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

## Pawn integration

Pawn is optional. APR reads its scale list and delegates scoring to
`PawnGetItemData(exactLink)` and `PawnGetSingleValueFromItem(item, scaleName)`;
the base score is used consistently for rewards and equipped items. APR does not
change Pawn scales or its visible-scale preferences. Its own slot comparisons
remain independent of Pawn's tracked best items.

Secure post-hooks observe scale edits/imports, and a coalesced snapshot detects
actual changes. Custom scales added or modified while automatic rewards are
active trigger an in-game offer to use that version. Combat defers the offer.
Accepting a stale offer cannot select a deleted or subsequently edited scale.
Declining a version is remembered. A changed or unavailable selected scale uses
APR weights until explicitly selected or confirmed; a deleted selection falls
back to APR. A popup that cannot be shown, is replaced, or is hidden by the
client leaves its version pending. A native popup closure triggers a coalesced
retry; only an explicit user refusal is remembered. The visible reward settings
refresh their catalog, selected scale and status after these changes. No recurring
polling or per-frame scan is used.

## API references and verification

- [Pawn API and scale mutations](https://github.com/VgerMods/Pawn/blob/5bcfda4076ec2beeb8ada58ed396a2d8ba296181/Pawn.lua):
  `PawnIsReady`, `PawnGetAllScalesEx`, `PawnGetAllStatValues`, item scoring.
  Pawn 2.14.1 declares Retail and Forever support. Its code/weight tables are not
  bundled or copied into APR.
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
