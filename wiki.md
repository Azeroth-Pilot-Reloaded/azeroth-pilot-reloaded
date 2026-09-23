# Azeroth Pilot Reloaded - Route and Step Options Reference

---

## Table of Contents

1. [Route Definition Options](#route-definition-options)
2. [Action / Progression Options](#action--progression-options)
3. [Navigation and Targeting](#navigation-and-targeting)
4. [Automation and Display](#automation-and-display)
5. [Filters and Conditions](#filters-and-conditions)
6. [Miscellaneous and Legacy](#miscellaneous-and-legacy)
7. [Example Route](#example-route)
8. [Example Step](#example-step)
9. [Configurable Level Profiles](#configurable-level-profiles)
10. [Midnight Delver's Call Profile](#midnight-delvers-call-profile)
11. [XP Consumables and Optional Reminders](#xp-consumables-and-optional-reminders)

---

## Route Definition Options

| Option          | Description                                                                                                                                                                                                                                                                                                                                                                 | Expected Syntax                                                        |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `category`      | Route category enum. Common values are leveling, speedrun, campaign, etc.                                                                                                                                                                                                                                                                                                   | `category = APR.CATEGORIES.Leveling`                                   |
| `conditions`    | Route visibility / availability rules. Uses the same condition keys documented in [Filters and Conditions](#filters-and-conditions).                                                                                                                                                                                                                                        | `conditions = { Level = 80, Faction = "Alliance" }`                    |
| `expansion`     | Expansion enum used to group the route in the UI.                                                                                                                                                                                                                                                                                                                           | `expansion = APR.EXPANSIONS.Midnight`                                  |
| `gameVersion`   | Client family (`"retail"`, `"forever"`, `"classic"`). An incompatible route is hidden and unavailable to route access, not merely disabled. Preserved on saved custom routes. Built-in file loading is selected by the packager.                                                                                                                                            | `gameVersion = "forever"`                                              |
| `label`         | Display name shown in the route list.                                                                                                                                                                                                                                                                                                                                       | `label = "Midnight - Speedrun"`                                        |
| `mapID`         | Main map ID for the route. Used as route metadata and zone fallback.                                                                                                                                                                                                                                                                                                        | `mapID = 2393`                                                         |
| `nextRoute`     | Suggested follow-up route keys after completion.                                                                                                                                                                                                                                                                                                                            | `nextRoute = { "2395-The-War-of-Light-and-Shadow" }`                   |
| `parallelSteps` | Conditional step groups containing `conditions` and `steps`. Activation inserts the group into the active route. Use `Fillers` for optional quest progress alongside the current objective. | `parallelSteps = { { conditions = { BeLvl = 88 }, steps = { ... } } }` |
| `prefab`        | Optional prefab defaults keyed by prefab type.                                                                                                                                                                                                                                                                                                                              | `prefab = { [APR.PREFAB_TYPES.Speedrun] = 20 }`                        |
| `requiredRoute` | Route key or list of route keys that must be completed first. When the route is added to the custom path, unfinished required routes whose hard conditions apply are auto-added before it. A requirement hidden by faction, class, event, achievement or quest conditions is treated as not applicable; temporary level, specialization and zone conditions never waive it. | `requiredRoute = { "2432-Midnight-Intro" }`                            |
| `steps`         | Main ordered list of route steps.                                                                                                                                                                                                                                                                                                                                           | `steps = { { PickUp = { 86733 } }, ... }`                              |
| `XPConsumables` | Named level profile whose missing consumable buffs should be suggested alongside the current step. Also supported on individual steps; `false` disables the inherited reminder.                                                                                                                                                                                             | `XPConsumables = "MidnightDelves"`                                     |

Notes:

- A Lua file may register multiple routes with separate `APR.RouteQuestStepList["route-key"] = { ... }` assignments. Each route keeps its own `steps`, conditions, metadata and completion step. The manifest loads the file once; `nextRoute` and prefabs refer to route keys, not file names.
- Forever files group guides by the first zone named in their titles, with starting-area aliases such as Northshire/Elwynn Forest. Guides without a named zone use their starting map. This file organization does not change route `mapID` or merge the routes' progression.
- `parallelSteps` groups are inserted at the player's current progression point when activated.
- If the player is currently inside a block of `InstanceQuest` steps, groups using insertion are inserted after that block.
- `parallelSteps[].conditions` use the same keys as normal route / step conditions.
- Use `MinLevel` for rewards that remain available above a threshold; `BeLvl = 88` only matches level 88.
- For a strictly ready, unturned-in quest, combine `IsQuestOnQuest`, `IsQuestReadyForTurnIn` and `IsQuestUncompleted`. The existing readiness helper also returns true for a quest already completed by this character.
- APR defers automatic hand-ins listed in pending parallel groups until their group conditions are met. Manual turn-ins and the modifier-key override remain available. Once inserted, a group keeps its position even if its activation conditions later change.
- Add `Zones` to a group's conditions when it should wait for the player's next visit to the reward zone. Use a separate group for each independently available reward; grouping unrelated `Done` quests can otherwise block on an absent quest.

For opportunistic quest objectives, add `Fillers` to the relevant main steps or
let the player collect items while completing other quests. Add a `Qpart` before
`Done` to finish any objectives still missing. Source labels and dependencies are
resolved by the converter; routes do not need source identifiers or task windows.
Keep character restrictions on the route when it already guarantees eligibility;
do not repeat them on child steps or prefabs.

---

## Action / Progression Options

| Option            | Description                                                                                                                                                                                                                                                                  | Expected Syntax                                                                                             |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `Achievement`     | Tracks a whole achievement or one of its criteria. Prefer the stable `criteriaID`; `criteriaIndex` remains available for legacy data.                                                                                                                                        | `Achievement = { achievementID = 61960, criteriaID = 111471 }`                                              |
| `BankDeposit` | Move all stacks of the listed items from bags into the open character bank. | `BankDeposit = { items = { 4371, 5465 } }` |
| `BankWithdraw` | Move all stacks of the listed items from the open character bank into bags. | `BankWithdraw = { items = { 4371 } }` |
| `BuyMerchant` | Buy the specified quantity from a merchant as a main or secondary action. Optional `MerchantNPC` limits the merchant. | `BuyMerchant = { { itemID = 4371, quantity = 1 } }` |
| `ChromiePick`     | Selects a specific Chromie Time timeline by option ID.                                                                                                                                                                                                                       | `ChromiePick = 8`                                                                                           |
| `DeathSkip` | Wait for death, confirm resurrection at a spirit healer, then finish on resurrection. Does not kill the character or accept an ordinary player resurrection as completion. | `DeathSkip = true, Hardcore = false` |
| `DestroyItems` | Delete all bag stacks of the explicitly listed items and wait until absent. | `DestroyItems = { items = { 12345 } }` |
| `EquipItem` | Show the localized item name and an item button; complete once the specified slot contains the item. Use possession and level conditions for deferred parallel reminders. | `EquipItem = { itemID = 2030, slot = 16 }` |
| `Done`            | Quests to turn in. The step completes once all listed quests are handed in. If using `DoneDB`, keep a base `Done` field as well.                                                                                                                                             | `Done = { 12345, 12400 }`                                                                                   |
| `DoneDB`          | Alternative quest IDs counted as the same hand-in. Requires `Done`.                                                                                                                                                                                                          | `DoneDB = { 12345, 54321 }`                                                                                 |
| `DoScenario`      | Indicates that the player should complete the scenario.                                                                                                                                                                                                                      | `DoScenario = { questID = 86912, mapID = 2505 }`                                                            |
| `DroppableQuest`  | Defines passive or active dropped-quest tracking. When used without `DropQuest`, it behaves like a filler hint.                                                                                                                                                              | `DroppableQuest = { Qid = 41234, MobId = 133713, Text = "Fel Marauder" }`                                   |
| `DropQuest`       | Quest obtained from a mob drop. Must be paired with a corresponding `DroppableQuest`.                                                                                                                                                                                        | `DropQuest = 48876`                                                                                         |
| `Emote`           | Requires performing an emote on a target or at a step.                                                                                                                                                                                                                       | `Emote = { emote = "salute", npcID = 12345 }`                                                                                          |
| `EnterInstance`   | Guides the player into an instance.                                                                                                                                                                                                                                          | `EnterInstance = { questID = 12345, mapID = 2505 }`                                                         |
| `EnterScenario`   | Guides the player to a scenario entrance.                                                                                                                                                                                                                                    | `EnterScenario = { questID = 86636, mapID = 2502 }`                                                         |
| `ExitTutorial`    | Exile's Reach specific step that auto-skips if the exit quest is no longer tracked.                                                                                                                                                                                          | `ExitTutorial = 59985`                                                                                      |
| `Fillers`         | Optional side objectives that can progress during any step without blocking the route.                                                                                                                                                                                       | `Fillers = { [49529] = { 1 }, [49897] = { 1 } }`                                                            |
| `GetFP`           | Learn a flight path node.                                                                                                                                                                                                                                                    | `GetFP = 2395`                                                                                              |
| `Grind`           | Requires reaching a specific player level before proceeding.                                                                                                                                                                                                                 | `Grind = 60`                                                                                                |
| `Group`           | Marks an optional group quest and shows a popup (`questID`, `Number`).                                                                                                                                                                                                       | `Group = { questID = 51384, Number = 3 }`                                                                   |
| `GroupTask`       | Associates the step with `WantedQuestList` to store the player's decision for a group quest.                                                                                                                                                                                 | `GroupTask = 51384`                                                                                         |
| `LearnProfession` | Checks if a specific profession spell is learned.                                                                                                                                                                                                                            | `LearnProfession = 2259`                                                                                    |
| `LearnSkill` | Learn the specified spell(s) from a trainer; optionally buy every available service from the specified trainer. Distinct from the profession-only reminder `LearnProfession`. | `LearnSkill = { spellID = 6673 }` or `{ spellIDs = { 6673, 100 }, npcID = 911 }` or `{ allAvailable = true, npcID = 911 }` |
| `LeaveInstance`   | Prompts to leave the instance once objectives are done.                                                                                                                                                                                                                      | `LeaveInstance = { questID = 12345, mapID = 2505 }`                                                         |
| `LeaveQuest`      | Abandons a single quest from the quest log.                                                                                                                                                                                                                                  | `LeaveQuest = 38254`                                                                                        |
| `LeaveQuests`     | Abandons multiple quests from the quest log.                                                                                                                                                                                                                                 | `LeaveQuests = { 38254, 38257 }`                                                                            |
| `LeaveScenario`   | Prompts to leave the scenario once objectives are done.                                                                                                                                                                                                                      | `LeaveScenario = { questID = 86912, mapID = 2505 }`                                                         |
| `LootItems` | Wait until each item reaches `quantity` (default 1), counting items in bags and the saved character bank. Optional `questID` also accepts a quest already turned in. No virtual loot or remembered completion count. | `LootItems = { { questID = 86644, itemID = 244143, quantity = 1 } }` |
| `LootMoney` | Wait until cash plus carried items' vendor value reaches `copper`. Displays a progress bar. Optionally includes all equipped gear or selected `equippedSlots`. | `LootMoney = { copper = 10, includeEquipped = true }` |
| `MountVehicle`    | Automatically validates when a mount / boarding event is detected.                                                                                                                                                                                                           | `MountVehicle = true`                                                                                       |
| `Note` | Informational step accepting a string or array of strings. Seen notes are remembered and can auto-skip on later resets / revisits. | `Note = { "Open the map", "Follow the bridge north" }` |
| `NpcDismount`     | Automatically dismounts to talk to the targeted NPC.                                                                                                                                                                                                                         | `NpcDismount = 43733`                                                                                       |
| `PickUp`          | List of quest IDs to pick up. The step remains active until all quests are in the log. If using `PickUpDB`, keep a base `PickUp` field as well.                                                                                                                              | `PickUp = { 39688 }`                                                                                        |
| `PickUpDB`        | Alternative quest IDs for the same pickup step (class / faction variants). Requires `PickUp`.                                                                                                                                                                                | `PickUpDB = { 39688, 39694, 40255, 40256 }`                                                                 |
| `Qpart`           | Quest objectives to complete, mapped by quest ID and objective index.                                                                                                                                                                                                        | `Qpart = { [12345] = { 1, 2 } }`                                                                            |
| `QpartDB`         | Alternative quest IDs for the same `Qpart` block. Requires `Qpart`.                                                                                                                                                                                                          | `QpartDB = { 12345, 12346 }`                                                                                |
| `QpartPart`       | Splits a single objective into guided sub-parts. Commonly paired with `TrigText`. Supports fraction and percentage style progress markers.                                                                                                                                   | `QpartPart = { [12345] = { 1 } }, TrigText = "1/3"`                                                         |
| `Reputation`      | Requires reaching a standard standing, renown level, or friendship rank with a faction before proceeding.                                                                                                                                                                    | `Reputation = { factionID = 2590, type = APR.REPUTATION_TYPE.Renown, level = 10 }`                          |
| `ResetRoute`      | Shows a confirmation popup that resets the active route back to step 1.                                                                                                                                                                                                      | `ResetRoute = true`                                                                                         |
| `RouteCompleted`  | Marks the route as finished and triggers route completion flow. Must stay as the last step.                                                                                                                                                                                  | `RouteCompleted = true`                                                                                     |
| `Scenario`        | Fine-grained scenario objective tracking (`scenarioID`, `stepID`, `criteriaID`, etc.), optionally tied to a quest ID.                                                                                                                                                        | `Scenario = { criteriaID = 106007, criteriaIndex = 1, scenarioID = 3101, stepID = 15911, questID = 86820 }` |
| `SellItems` | Sell listed items, or grey junk, while the merchant window is open. Optional NPC check. | `SellItems = { items = { 7073, 7074 }, npcID = 54 }` or `{ junk = true }` |
| `SetHS`           | Step to set the Hearthstone.                                                                                                                                                                                                                                                 | `SetHS = 31732`                                                                                             |
| `TameBeast` | Offer the tame spell and target button; validate a successful cast started on the specified NPC. | `TameBeast = { npcID = 2163, spellID = 1515 }` |
| `Treasure`        | Treasure or vignette step. The addon tracks the treasure's anchor quest, with optional item details for the tooltip.                                                                                                                                                         | `Treasure = { questID = 89105, itemID = 238553 }`                                                           |
| `UseDalaHS`       | Dalaran Hearthstone variant.                                                                                                                                                                                                                                                 | `UseDalaHS = 44184`                                                                                         |
| `UseFlightPath`   | Step for using a flight master. Validates once the flight is complete.                                                                                                                                                                                                       | `UseFlightPath = 39580`                                                                                     |
| `UseGarrisonHS`   | Garrison Hearthstone variant.                                                                                                                                                                                                                                                | `UseGarrisonHS = 110560`                                                                                    |
| `UseHS`           | Step to use the Hearthstone.                                                                                                                                                                                                                                                 | `UseHS = 31732`                                                                                             |
| `UseItem` | Standalone item-use action. `questID` is required; APR resolves the use spell from the item unless `itemSpellID` is supplied. Use `Button` when the item supports another objective. | `UseItem = { questID = 42008, itemID = 173430, itemSpellID = 254294 }` |
| `UseSpell` | Standalone spell-cast action. `questID` is required. Use `SpellButton` when the spell supports another objective. | `UseSpell = { questID = 42476, spellID = 193759 }` |
| `VehicleExit`     | Forces exiting a vehicle.                                                                                                                                                                                                                                                    | `VehicleExit = true`                                                                                        |
| `WarMode`         | Instructs the player to enable War Mode manually in Blizzard's UI. The quest ID is a label, not a completion condition. Completes when `C_PvP.IsWarModeDesired()` is true. APR never calls the protected activation functions. XP bonuses still require `IsWarModeActive()`. | `WarMode = 60361`                                                                                           |

An action waits for completion; a condition controls whether it applies. Use one main action per step.

Names available directly from IDs must not be duplicated in route text: `LearnSkill`
uses localized spell names from `spellID`/`spellIDs`, and `TakePortal` uses the
localized destination from `mapID`. Training without spell IDs can still use `text`.
For cache-dependent names, keep `text` as a fallback: taming prefers the NPC name
in `APRData.NPCList`, while selling, bank transfers and destruction prefer item
names once all listed items are cached. Until then, the action's fallback remains
visible. These lookups never overwrite route data, so the fallback remains available
for other characters. As with `DroppableQuest.Text`, cached names take priority;
both `text` and `Text` are accepted by these action tables.

Bank transfers use the Classic character
bank and its bank bags, not guild, reagent or warband banks. Selling, transferring
and destruction process one full stack at a time, pause in combat, and never touch
a foreign cursor item or locked slot. These actions do not accept a quantity limit.
Bank/merchant actions require their window to be open. Training waits if the
requested service cannot yet be learned or afforded.

`LootItems` and the `Collection` condition share the same inventory count.
Character bank contents are saved when the bank is accessible and refreshed after
changes, then used after closing the bank or reloading. Transfers between bags
and bank do not increase the combined count. There is no source-specific counting
mode or adjustment based on skill ranks or quest objectives.

```lua
LootItems = { { itemID = 5465, quantity = 50 } }
```

Text-only source collections remain advice rather than mandatory inventory gates.

### Achievement Examples

Use `criteriaID` whenever it is available. It identifies the criterion directly and remains valid if Blizzard changes
the order of an achievement's criteria.

```lua
-- Preferred: track one criterion by its stable ID.
{
    Achievement = {
        achievementID = 61960,
        criteriaID = 111471,
    },
}

-- Legacy fallback: track one criterion by its position in the achievement.
{
    Achievement = {
        achievementID = 61576,
        criteriaIndex = 1,
    },
}

-- Track completion of the whole achievement.
{
    Achievement = {
        achievementID = 61576,
    },
}
```

When both `criteriaID` and `criteriaIndex` are provided, APR uses `criteriaID`. The criterion label is displayed in the
current-step panel, and the step advances automatically when the criterion or achievement is completed.

### Money and vendor-value objectives

`LootMoney` waits until current money plus the theoretical vendor value of carried
items reaches `copper`. The current-step bar displays **cash + resale / target**
and fills using their sum. Bags include stack quantities and the reagent bag when
available; bank contents and items with no vendor value are excluded. Uncached
item prices count as zero until item information becomes available.

```lua
{
    Coord = { x = -4299.05, y = -494.9 },
    Zone = 1411,
    Range = 30,
    LootMoney = {
        copper = 10,
        equippedSlots = { 1, 3, 5, 6, 7, 8, 9, 10, 15 }, -- armor only
    },
    Note = { "Kill Mottled Boars and loot items to sell." },
    Class = { "SHAMAN", "WARRIOR" },
}
```

Equipment is excluded by default. Set `includeEquipped = true` to include all
equipped gear, or `equippedSlots` to include selected inventory slots. This only
estimates resale value; it does not sell or unequip items. The step automatically
advances at `cash + resale >= copper`, with updates on money, bags, equipment and
item-data events. Use this as the main objective, without `Waypoint` or a `Money`
skip filter. `Money` remains a condition on cash actually owned, for purchases
and other steps that require spending money.

### Reputation Examples

Reputation requirements use a faction ID, a target `level`, and optionally a reputation `type`. The requirement is
satisfied when the player reaches that level or any higher level. APR supports standard standings, major-faction
renown levels, and friendship/NPC ranks.

```lua
-- Standard reputation: block until Honored with Stormwind.
{
    Reputation = {
        factionID = 72,
        type = APR.REPUTATION_TYPE.Standard,
        level = APR.REPUTATION_STANDING.Honored,
    },
}

-- Major faction: block until Renown 10 with the Council of Dornogal.
{
    Reputation = {
        factionID = 2590,
        type = APR.REPUTATION_TYPE.Renown,
        level = 10,
    },
}

-- Friendship/NPC reputation: block until rank 5 with Captain Tokka.
{
    Reputation = {
        factionID = 2773,
        type = APR.REPUTATION_TYPE.Friendship,
        level = 5,
    },
}
```

Available reputation types are:

| Constant                         | Meaning of `level`                                |
| -------------------------------- | ------------------------------------------------- |
| `APR.REPUTATION_TYPE.Friendship` | Friendship rank number shown for the NPC faction. |
| `APR.REPUTATION_TYPE.Renown`     | Renown level shown on the major faction track.    |
| `APR.REPUTATION_TYPE.Standard`   | Standard standing ID from `1` through `8`.        |

The `type` field can be omitted. APR then detects renown first, friendship/NPC reputation second, and standard
reputation last. Specifying it is recommended in route files because it makes the intended meaning of `level`
unambiguous.

For standard reputations, the available standing constants are:

| Constant                             | Standing ID |
| ------------------------------------ | ----------: |
| `APR.REPUTATION_STANDING.Exalted`    |         `8` |
| `APR.REPUTATION_STANDING.Friendly`   |         `5` |
| `APR.REPUTATION_STANDING.Hated`      |         `1` |
| `APR.REPUTATION_STANDING.Honored`    |         `6` |
| `APR.REPUTATION_STANDING.Hostile`    |         `2` |
| `APR.REPUTATION_STANDING.Neutral`    |         `4` |
| `APR.REPUTATION_STANDING.Revered`    |         `7` |
| `APR.REPUTATION_STANDING.Unfriendly` |         `3` |

Raw standing IDs from `1` through `8` are also accepted for standard reputations, but the named constants are
preferred. Renown levels and friendship ranks use their numeric value directly.

---

## Navigation and Targeting

| Option                          | Description                                                                                                                                                                                                                                                                                                                                                                                       | Expected Syntax                                                                            |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `Boat`                          | Indicates the player should take a boat instead of flying. Requires `UseFlightPath`.                                                                                                                                                                                                                                                                                                              | `Boat = true`                                                                              |
| `Coord`                         | World coordinates used by the arrow (`x`, `y` in WoW units).                                                                                                                                                                                                                                                                                                                                      | `Coord = { x = 4298.4, y = -864.1 }`                                                       |
| `Coords`                        | Multiple coordinate variants for the same step. Typically paired with `Zones`; each entry should include its own `Zone`.                                                                                                                                                                                                                                                                          | `Coords = { { Zone = 84, x = 797.7, y = -8624.9 }, { Zone = 85, x = -4436, y = 1590.3 } }` |
| `EmoteETA` | Start the AFK timer after the step emote is performed. | `EmoteETA = 30` |
| `ETA`                           | Estimated AFK timer duration in seconds.                                                                                                                                                                                                                                                                                                                                                          | `ETA = 75`                                                                                 |
| `GossipETA`                     | Starts an AFK timer after gossip confirmation.                                                                                                                                                                                                                                                                                                                                                    | `GossipETA = 45`                                                                           |
| `InstanceQuest`                 | Marks the step as taking place inside an instance. Automatic Delve suggestions wait while the current step has this flag. Once eligible, accepting a suggestion preserves parent-route steps before a matching `DoScenario` at the current step or within the next five steps, then replaces that scenario step with the guide. Without a nearby match, the guide starts before the current step. | `InstanceQuest = true`                                                                     |
| `IsAdventureMap`                | Allows auto-accepting quests from the Adventure Map.                                                                                                                                                                                                                                                                                                                                              | `IsAdventureMap = true`                                                                    |
| `Name`                          | Optional custom name to override the taxi node name.                                                                                                                                                                                                                                                                                                                                              | `Name = "Krasus' Landing"`                                                                 |
| `NoArrow`                       | Hides the navigation arrow for this step.                                                                                                                                                                                                                                                                                                                                                         | `NoArrow = true`                                                                           |
| `NoAutoFlightMap`               | Prevents automatic flight / gossip selection for this step.                                                                                                                                                                                                                                                                                                                                       | `NoAutoFlightMap = true`                                                                   |
| `NodeID`                        | Flight path node ID used on `UseFlightPath` steps.                                                                                                                                                                                                                                                                                                                                                | `NodeID = 1719`                                                                            |
| `NonSkippableWaypoint`          | Prevents the step from being skipped manually.                                                                                                                                                                                                                                                                                                                                                    | `NonSkippableWaypoint = true`                                                              |
| `Range`                         | Distance in yards from `Coord` to consider the location reached.                                                                                                                                                                                                                                                                                                                                  | `Range = 45`                                                                               |
| `SingleWaypointDisplayDistance` | Changes the arrow distance display so it only shows the distance to the next waypoint / coord instead of summing the whole remaining chain.                                                                                                                                                                                                                                                       | `SingleWaypointDisplayDistance = true`                                                     |
| `SpecialETAHide`                | Hides the AFK timer even if `ETA` is set.                                                                                                                                                                                                                                                                                                                                                         | `SpecialETAHide = true`                                                                    |
| `SpellETA` | Start the AFK timer after the successful cast of `spellID`, or the use spell of `itemID`. | `SpellETA = { spellID = 123, seconds = 30 }` |
| `TakePortal`                    | Step requiring the player to use a portal. The step validates once the target zone is reached or the linked quest is already completed.                                                                                                                                                                                                                                                           | `TakePortal = { questID = 81888, mapID= 85 }`                                              |
| `Waypoint`                      | Quest-related waypoint displayed until completion.                                                                                                                                                                                                                                                                                                                                                | `Waypoint = 44543`                                                                         |
| `WaypointDB`                    | Alternative waypoint quests that allow skipping if already completed. Requires `Waypoint`.                                                                                                                                                                                                                                                                                                        | `WaypointDB = { 44543, 44544 }`                                                            |
| `Zone`                          | Expected map ID for the step.                                                                                                                                                                                                                                                                                                                                                                     | `Zone = 627`                                                                               |
| `Zones`                         | Multiple valid map IDs for a single step. Also acts as a condition: the step is only considered valid when the player is in one of those maps.                                                                                                                                                                                                                                                    | `Zones = { 84, 85 }`                                                                       |
| `ZoneStepTrigger`               | Automatically validates the step when entering the specified radius.                                                                                                                                                                                                                                                                                                                              | `ZoneStepTrigger = { x = 4098.2, y = -712.4, Range = 25 }`                                 |

---

## Automation and Display

| Option            | Description                                                                                                                                                                  | Expected Syntax                                                       |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `Bloodlust`       | Adds a reminder to use Heroism / Bloodlust.                                                                                                                                  | `Bloodlust = true`                                                    |
| `Buffs`           | List of buff spell IDs to recommend.                                                                                                                                         | `Buffs = { { spellId = 311103, tooltipMessage = "FRESHLEAF_BUFF" } }` |
| `Button`          | Associates items to use with objectives (`"QuestID-Objective"` -> `itemID`). Can also be used with non-objective steps by using only the quest ID as the key.                | `Button = { ["30778-1"] = 81356 }`                                    |
| `DenyNPC`         | NPC ID whose gossip should be closed automatically.                                                                                                                          | `DenyNPC = 209914`                                                    |
| `Dontskipvid`     | Prevents automatic skipping of cutscenes or videos.                                                                                                                          | `Dontskipvid = true`                                                  |
| `ExtraActionB`    | Prompts use of the special extra action button.                                                                                                                              | `ExtraActionB = true`                                                 |
| `ExtraLineText*`  | Additional helper lines displayed in the current step panel. Supports numbered variants such as `ExtraLineText2`, `ExtraLineText3`, etc.                                     | `ExtraLineText = "Interact with the second console"`                  |
| `GossipOptionIDs` | Automate dialogue selection using actual option IDs, never option positions. Never emit `Gossip`. | `GossipOptionIDs = { 51901, 51902 }` |
| `InVehicle`       | Indicates vehicle status (`1` = enter, `2` = stay in vehicle).                                                                                                               | `InVehicle = 1`                                                       |
| `MerchantNPC` | Limit the step purchase to this merchant NPC. | `MerchantNPC = 54` |
| `NoAutoAccept` | Keep the quest pickup visible but require manual acceptance. | `NoAutoAccept = true` |
| `NoAutoTurnIn` | Keep the quest hand-in visible but require manual interaction. | `NoAutoTurnIn = true` |
| `PreviewImages`   | Displays one or more clickable image previews in the current step panel. Relative paths are resolved from `APR-Core/assets/`; full `Interface\\...` paths are also accepted. | `PreviewImages = { "routeHelper\\86644.jpg" }`                        |
| `RaidIcon`        | NPC ID to mark with a raid icon.                                                                                                                                             | `RaidIcon = 241743`                                                   |
| `SpellButton` | Spell buttons keyed only by quest ID or `questID-ObjectiveIndex`. Prefer a numeric spell ID; a spell name understood by the client is also accepted. Names in another language require a verified ID. | `SpellButton = { ["49939-1"] = 294197 }` |
| `SpellTrigger`    | Automatically completes the step when the given spell is cast.                                                                                                               | `SpellTrigger = 306719`                                               |
| `TrigText*`       | Text fragments used as completion triggers (`TrigText`, `TrigText2`, etc.).                                                                                                  | `TrigText = "Restore the console"`                                    |
| `UseGlider`       | Displays available gliders for controlled jumps.                                                                                                                             | `UseGlider = true`                                                    |

---

## Filters and Conditions

These filters are evaluated directly on steps and inside `parallelSteps[].conditions`.
Route-level `conditions` support a narrower subset: `InterfaceVersion`, `DontHaveSpell`,
`IsQuestReadyForTurnIn`, achievement, faction, race, class, event, allied-race, and
single-quest completion checks, plus numeric `Level`, `MinLevel`, `MaxLevel`, `BeLvl`,
`ClassSpec`, and `Zones`. Route-level `Race`, `Class`, and `ClassNot` accept a
single value or a list, including class tokens and numeric class IDs. Failed
race/class requirements hide the route completely.
Route-level `AnyOf` also accepts alternative native condition tables. Each
alternative uses the step-condition evaluator, and the result is a hard visibility
requirement (including level checks nested inside an alternative). Top-level
level, specialization and `Zones` checks retain their disabled-route behavior.
Other keys in this table, including quest-log presence, reputation, resource and
zone include/exclude filters, are step/parallel-group filters unless nested in
route-level `AnyOf`.

| Option                              | Description                                                                                                                                                             | Expected Syntax                                                                                    |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `AlliedRace`                        | Restricts based on whether the character is an allied race.                                                                                                             | `AlliedRace = true`                                                                                |
| `AllOf` | Require every enclosed condition table to match. Useful for repeated predicates such as several quest-presence checks. | `AllOf = { { IsQuestNotOnQuest = 10 }, { IsQuestNotOnQuest = 20 } }` |
| `AnyOf`                             | Requires at least one alternative condition table to match, in addition to all other conditions on the step/group. An empty list never matches.                         | `AnyOf = { { IsQuestOnQuest = 86733 }, { IsQuestCompleted = 86852, IsQuestUncompleted = 86733 } }` |
| `BeLvl`                             | Exact effective level check. The player must be at least this level, but below the next whole level.                                                                    | `BeLvl = 88`                                                                                       |
| `Class`                             | Restricts to one or more classes.                                                                                                                                       | `Class = { "HUNTER", "ROGUE" }`                                                                    |
| `ClassNot`                          | Inverse class filter. Hides / disables the step or route for the listed class or classes.                                                                               | `ClassNot = APR.Classes.Evoker`                                                                    |
| `ClassSpec`                         | Restricts to a specialization ID. For routes, failing this condition makes the route disabled rather than hidden.                                                       | `ClassSpec = APR.Specs["Mage - Frost"]`                                                            |
| `Collection` | Require at least `quantity` items (default 1) in bags plus the saved character bank, using the same count as `LootItems`. | `Collection = { itemID = 5465, quantity = 50 }` |
| `DontHaveAchievement`               | Visible only if the achievement is missing.                                                                                                                             | `DontHaveAchievement = 9924`                                                                       |
| `DontHaveAura`                      | Requires the aura to be absent.                                                                                                                                         | `DontHaveAura = 32182`                                                                             |
| `DontHaveSpell`                     | Requires a spell to be unknown. With a list, **none** of the listed spells may be known. Uses the same spellbook wrapper as `HasSpell`.                                 | `DontHaveSpell = { 264211, 264434 }`                                                               |
| `EquippedItem` | Require the exact item in a slot. Omit `itemID` to accept any equipped item; `invert = true` negates the test. | `EquippedItem = { slot = 16, itemID = 2493 }` |
| `EquippedItemStat` | Keeps the step eligible only when the equipped item in `slot` satisfies the comparison. `stat` accepts an item-stat token, `"QUALITY"` or `"LEVEL"`; `value` is the threshold. `operator` defaults to `"=="` (same operators as `Money`). Optional `precision` rounds to that many decimal places; `allowMissing = true` accepts unavailable stats. Otherwise missing data fails the filter. | `EquippedItemStat = { slot = 16, stat = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", operator = "<", value = 3.5 }` |
| `Event`                             | Restricts to a specific APR event mode, such as Remix.                                                                                                                  | `Event = APR.EVENTS.Remix`                                                                         |
| `Faction`                           | Restricts to a faction (`"Alliance"` or `"Horde"`).                                                                                                                     | `Faction = "Horde"`                                                                                |
| `Gender`                            | Restricts to a gender (`1` neutral, `2` male, `3` female).                                                                                                              | `Gender = 3`                                                                                       |
| `Hardcore` | Restricts the step to Hardcore (`true`) or non-Hardcore (`false`) characters using `C_GameRules.IsHardcoreActive`. A missing API is treated as non-Hardcore. A mismatch skips the step. | `Hardcore = false` |
| `HasAchievement`                    | Requires a specific achievement.                                                                                                                                        | `HasAchievement = 12593`                                                                           |
| `HasAura`                           | Requires a specific buff or aura.                                                                                                                                       | `HasAura = 178207`                                                                                 |
| `HasSpell`                          | Requires the player to know a specific spell.                                                                                                                           | `HasSpell = 34090`                                                                                 |
| `IsCampaignQuest`                   | Marks the step as part of a campaign.                                                                                                                                   | `IsCampaignQuest = true`                                                                           |
| `IsOneOfQuestsCompleted`            | Requires at least one quest in the list to be completed.                                                                                                                | `IsOneOfQuestsCompleted = { 31588, 31589 }`                                                        |
| `IsOneOfQuestsCompletedOnAccount`   | Account-wide variant of `IsOneOfQuestsCompleted`.                                                                                                                       | `IsOneOfQuestsCompletedOnAccount = { 49929, 49930 }`                                               |
| `IsOneOfQuestsUncompleted`          | Requires at least one quest in the list to be incomplete.                                                                                                               | `IsOneOfQuestsUncompleted = { 31588, 31589 }`                                                      |
| `IsOneOfQuestsUncompletedOnAccount` | Account-wide variant of `IsOneOfQuestsUncompleted`.                                                                                                                     | `IsOneOfQuestsUncompletedOnAccount = { 49929, 49930 }`                                             |
| `IsQuestCompleted`                  | Requires a single quest to be completed.                                                                                                                                | `IsQuestCompleted = 35049`                                                                         |
| `IsQuestNotOnQuest`                 | Requires the quest to be absent from this character's current log. Combine with `IsQuestUncompleted` to exclude completed quests too.                                   | `IsQuestNotOnQuest = 86737`                                                                        |
| `IsQuestOnQuest`                    | Requires the quest in this character's current log; account completion is not sufficient.                                                                               | `IsQuestOnQuest = 86737`                                                                           |
| `IsQuestReadyForTurnIn`             | True for a quest in this character's log with completed objectives, or a quest already turned in by this character.                                                                | `IsQuestReadyForTurnIn = 93384`                                                                    |
| `IsQuestsCompleted`                 | Requires all listed quests to be completed.                                                                                                                             | `IsQuestsCompleted = { 31821, 31822 }`                                                             |
| `IsQuestsCompletedOnAccount`        | Account-wide variant of `IsQuestsCompleted`.                                                                                                                            | `IsQuestsCompletedOnAccount = { 49929, 49930 }`                                                    |
| `IsQuestsUncompleted`               | Requires at least one listed quest to still be incomplete.                                                                                                              | `IsQuestsUncompleted = { 31821, 31822 }`                                                           |
| `IsQuestsUncompletedOnAccount`      | Account-wide variant of `IsQuestsUncompleted`.                                                                                                                          | `IsQuestsUncompletedOnAccount = { 49929, 49930 }`                                                  |
| `IsQuestUncompleted`                | Requires a single quest to be incomplete.                                                                                                                               | `IsQuestUncompleted = 35049`                                                                       |
| `ItemCount` | Eligibility filter on current item counts, not a collection objective. Accepts `itemID` or an `itemIDs` list whose counts are summed, required `count`, and `operator` (default `">="`; same operators as `Money`). Optional `includeBank = true` includes bank items; `includeUsableToys = true` counts an owned usable toy when its item count is zero. Otherwise the step is skipped. Does not use virtual loot or remembered completion. | `ItemCount = { itemIDs = { 6948 }, operator = ">=", count = 1 }` |
| `Level`                             | Minimum player level required.                                                                                                                                          | `Level = 80`                                                                                       |
| `MaxLevel`                          | Maximum level allowed.                                                                                                                                                  | `MaxLevel = 69`                                                                                    |
| `MinLevel`                          | Explicit minimum level.                                                                                                                                                 | `MinLevel = 10`                                                                                    |
| `Money` | Keeps the step eligible only when the player's current money satisfies the comparison; otherwise skips it. `copper` is in copper, `operator` defaults to `">="`. Operators: `<`, `<=`, `>`, `>=`, `==`, `~=`. Does not wait to earn money. | `Money = { operator = ">=", copper = 10000 }` |
| Named level profile                 | Dynamic threshold supported by step-level `Level`, `MinLevel`, `MaxLevel`, `SkipForLvl`, and `Grind`. `"MidnightDelves"` is the built-in profile; see the policy below. | `MinLevel = "MidnightDelves"`                                                                      |
| `Not` | Invert the complete enclosed condition table. | `Not = { HasSpell = 6673 }` |
| `OnlyInZones`                       | Shows and executes the step only in one of these current player map IDs; otherwise skips it. Does not set navigation coordinates.                                       | `OnlyInZones = { 2541 }`                                                                           |
| `PickedLoa`                         | Specifies the chosen Loa in Zandalar (`1` = Bwonsamdi, `2` = Rezan).                                                                                                    | `PickedLoa = 1`                                                                                    |
| `QuestLineSkip`                     | Prevents the optional group popup if a questline is intentionally skipped.                                                                                              | `QuestLineSkip = 51226`                                                                            |
| `Race`                              | Restricts to one or more races.                                                                                                                                         | `Race = { "Orc", "Troll" }`                                                                        |
| `ReputationLevel`                   | Shows the step only after the requested standing, renown level, or friendship rank has been reached.                                                                    | `ReputationLevel = { factionID = 2590, type = APR.REPUTATION_TYPE.Renown, level = 10 }`            |
| `Skill` | Compare the skill rank; `maximum = true` compares its cap. Accepts a skill key, numeric skill ID or localized `name`; `operator` defaults to `>=`. | `Skill = { skill = "cooking", rank = 50, operator = ">=" }` |
| `SkipForLvl`                        | Skips the step once the player's effective level is greater than or equal to the given value.                                                                           | `SkipForLvl = 89.18`                                                                               |
| `SkipForReputation`                 | Hides and skips the step once the requested standing, renown level, or friendship rank has been reached.                                                                | `SkipForReputation = { factionID = 2773, type = APR.REPUTATION_TYPE.Friendship, level = 5 }`       |
| `SkipInZones`                       | Hides and skips the step in any of these current player map IDs. Does not set navigation coordinates.                                                                   | `SkipInZones = { 2393 }`                                                                           |

Combine distinct predicates with `AllOf`; invert a complete predicate with `Not`.

`ReputationLevel` and `SkipForReputation` are step filters and can also be used inside
`parallelSteps[].conditions`. They are not evaluated as route-selection conditions.

```lua
-- Visible only once Renown 10 with the Council of Dornogal has been reached.
{
    PickUp = { 12345 },
    ReputationLevel = {
        factionID = 2590,
        type = APR.REPUTATION_TYPE.Renown,
        level = 10,
    },
}

-- Visible only while the player is below friendship rank 5 with Captain Tokka.
{
    PickUp = { 12346 },
    SkipForReputation = {
        factionID = 2773,
        type = APR.REPUTATION_TYPE.Friendship,
        level = 5,
    },
}
```

---

## Miscellaneous and Legacy

### Source map coordinates

Prefer recorded APR world coordinates when an equivalent step exists. For a new point available only as map percentages, the existing world-coordinate converter exposes:

```lua
{
    Done = { 93385 },
    Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(2393, 52.54, 78.88),
    Zone = 2393,
}
```

`ConvertMapCoordinate(mapID, mapX, mapY)` accepts percentages from 0 to 100 and uses
`C_Map.GetWorldPosFromMapPos` in the client. It returns an APR world-coordinate table,
including APR's swapped world axes and one-decimal rounding. It returns `nil` when
the input or projection is unavailable; never substitute unconverted percentages.
These calls require the game map API and must be checked in game before recording
their results as static coordinates. They do not reproject existing APR coordinates.

For a profession reminder, list all eleven primary-profession spell IDs in
`DontHaveSpell`. Do not include cooking, fishing or archaeology, which are secondary
professions. Optional `LearnProfession` steps can continue using `HasSpell` with the
corresponding base-profession spell.

| Option      | Description                                                                 | Expected Syntax     |
| ----------- | --------------------------------------------------------------------------- | ------------------- |
| `_index`    | Internal index auto-generated during route packaging. Do not edit manually. | `_index = 128`      |
| `ExtraLine` | Legacy field for displaying a static localized helper line.                 | `ExtraLine = 13544` |
| `Gossip`    | Legacy field for automatically selecting a gossip option by index.          | `Gossip = 2`        |

---

## Example Route

```lua
APR.RouteQuestStepList["2393-Midnight-Speedrun"] = {
    label = "Midnight - Speedrun",
    expansion = APR.EXPANSIONS.Midnight,
    category = APR.CATEGORIES.Leveling,
    mapID = 2393,
    conditions = { Level = 80 },
    requiredRoute = { "2432-Midnight-Intro" },
    nextRoute = { "2395-The-War-of-Light-and-Shadow" },
    parallelSteps = {
        {
            conditions = { BeLvl = 88 },
            steps = {
                {
                    Done = { 93384 },
                    Coord = { x = -4816.2, y = 8315.6 },
                    Zone = 2395,
                },
            },
        },
    },
    steps = {
        {
            PickUp = { 86733 },
            Coord = { x = -4614.4, y = 10085.4 },
            IsCampaignQuest = true,
            Zone = 2424,
        },
        {
            RouteCompleted = true,
        },
    },
}
```

---

## Example Step

```lua
{
    LootItems = {
        { questID = 86644, itemID = 244143, quantity = 1 },
    },
    Coord = { x = -4672.3, y = 7802.5 },
    Zone = 2395,
    SingleWaypointDisplayDistance = true,
    ExtraLineText = "Loot the first focus",
    PreviewImages = { "routeHelper\\86644.jpg" },
    _index = 101,
},
{
    Note = {
        "The second focus is hidden behind the broken arch.",
        "Click the preview image above if you need a visual reference.",
    },
    Coord = { x = -4661.8, y = 7791.9 },
    Zone = 2395,
    _index = 102,
},
{
    TakePortal = { questID = 81888, mapID= 85 },
    Coord = { x = -8908.1, y = 555.2 },
    Zone = 84,
    _index = 103,
}
```

## Configurable Level Profiles

Manage all named targets in `APR-Core/config/LevelProfiles.lua`:

- `APR.LevelBonusSources` defines reusable aura IDs and bonus percentages. Any aura
  in `auras` activates the source once. For `achievementBonuses`, only the highest
  completed tier counts, and the source still requires an active aura.
  Optional `minLevel` is inclusive; `maxLevelExclusive` excludes its boundary.
  `Below80Mentorship` uses achievements 19470, 19460, 19475, 19476, 19477
  for 5/10/15/20/25% below level 80. `MidnightMentorship` uses 42328 through
  42332 from level 80 up to, but excluding, 90. Both require aura 430191.
  A profile may list both sources: their non-overlapping ranges prevent stacking.
  Cached targets are recalculated when the player's level changes.
  A source may alternatively define `isActive = function() ... end`. Its predicate
  OR any listed aura activates the source once. `WarMode` uses
  `C_PvP.IsWarModeActive()` with a configurable 15% bonus.
  `auraBonuses` maps spell IDs to percentages or tables of application count ->
  percentage. The highest bonus among active variants counts once. Stack tables
  select the highest matched tier; missing/zero/restricted counts use one application.
- `APR.LevelRequirementProfiles` defines each profile's `bonuses` and `levels`.
  `levels[0]` is required and is the fallback without bonuses. The engine selects
  the greatest bonus breakpoint less than or equal to the active total. There is
  no interpolation; a 12% total uses the 10% row if the next breakpoint is 20%.

For example, add another entry to `APR.LevelRequirementProfiles`:

```lua
OtherRoute = {
    bonuses = { "WindsOfMysteriousFortune" },
    levels = {
        [0] = 88,
        [20] = 87.25,
    },
},
```

Then use `MinLevel = "OtherRoute"`, `SkipForLvl = "OtherRoute"`, or
`Grind = "OtherRoute"` in steps or parallel conditions as appropriate.
The shared step evaluator also supports profiles in `Level` and `MaxLevel`;
route-selection level conditions remain numeric.
Numeric requirements remain supported. Unknown profile/source names raise an
error so typos cannot silently remove a level restriction. Reload after editing
the configuration. Cached profiles refresh on aura/achievement/world events,
with at most one guide update when several profiles change together.

## Midnight Delver's Call Profile

Use `MinLevel = "MidnightDelves"` in a parallel group's conditions,
`SkipForLvl = "MidnightDelves"` on questing steps that should stop at that threshold,
and `Grind = "MidnightDelves"` for the final wait before the hand-in circuit.
All three use the player's fractional level, so 87.5 means level 87 with 50% XP.
Keep actual reward steps and the final fallback quests capped at level 90.

This empirical policy uses two anchors: 5% mentorship + 15% War Mode -> 88,
and 25% mentorship + 15% War Mode -> 87. The linear estimate is
`target = 89 - totalBonus / 20`: every extra five percentage points lowers the
target by 0.25 levels. Values outside 20-40% are extrapolated, including targets
below 87. This is not an exact quest XP prediction or a guarantee with missing rewards.

| Mentorship | No event / no War Mode | Event only | War Mode only | Event + War Mode |
| ---------- | ---------------------- | ---------- | ------------- | ---------------- |
| 0%         | 89                     | 88         | 88.25         | 87.25            |
| 5%         | 88.75                  | 87.75      | 88            | 87               |
| 10%        | 88.5                   | 87.5       | 87.75         | 86.75            |
| 15%        | 88.25                  | 87.25      | 87.5          | 86.5             |
| 20%        | 88                     | 87         | 87.25         | 86.25            |
| 25%        | 87.75                  | 86.75      | 87            | 86               |

The [community report](https://www.reddit.com/r/wow/comments/1u8haw4/delvers_call_quests_turnins_now_take_you_from/)
assumes all ten rewards and 25% mentorship + War Mode. It does not specify the
War Mode percentage; 15% is the configured value requested for this profile.

The event contributes 20% only while aura 1287282 OR 1214848 is present. Both
variants together still contribute only 20%. No calendar dates or permanent event
bonus are assumed. Mentorship requires aura 430191; the highest completed Midnight
achievement from 42328 through 42332 supplies 5%, 10%, 15%, 20%, or 25% respectively.
War Mode contributes 15% only while active, not merely requested. Rested XP and
other bonuses are not included in this policy.

Timeways is also included when its aura is present. Knowledge variants 1269517
and 423860 grant 5/10/15% at 1/2/3 applications, transforming at four to 30%.
Mastery variants 1269518, 1229050, 1258528, 471544 and 423861 grant 30%. Only the highest Timeways
bonus counts, even if multiple variants or Knowledge and Mastery coexist.
See [Blizzard's event description](https://worldofwarcraft.blizzard.com/en-us/news/24264422)
and [Mastery 1269518](https://www.wowhead.com/spell=1269518/mastery-of-timeways).
The table above excludes Timeways and consumables: subtract 0.25/0.5/0.75/1.5 levels for its
5/10/15/30% bonus. The configured total now reaches 90%, targeting 84.5 by linear
extrapolation; these early thresholds need in-game validation with all ten rewards.

## XP Consumables and Optional Reminders

Add `items = { itemID, ... }` to a source in `APR.LevelBonusSources`, alongside
its aura IDs, bonus percentage and any level limits. Add that source's name to
the desired profile's `bonuses`. Inventory alone never contributes XP: the aura
must be active. Multiple item variants of one source never add extra bonus.

Set `XPConsumables = "MidnightDelves"` on a route (enabled on the Midnight alt
route), or on an individual step with any profile name. A step can override the
route with another profile or disable reminders using `XPConsumables = false`.
This renders an optional localized use-item line and the existing secure item
button alongside the main instructions; it does not insert, complete or block steps.

Reminders require an item in the character's bags, usable according to
`C_Item.IsUsableItem`, with no equivalent source aura active, within the source's
level range and below the character's expansion level cap. Banks are excluded.
Only the first usable owned variant per source is shown. Bag and aura updates
remove/re-enable reminders as needed, including buff expiry. Unchanged reminders
do not rebuild the guide; reminder-only changes do not rebuild the route list.
Buttons use APR's existing combat-lockdown handling and require a player click.

Verified catalog:

| Source           | Items          | Auras         | Bonus / restriction                      |
| ---------------- | -------------- | ------------- | ---------------------------------------- |
| Darkmoon         | 93730, 171364  | 136583, 46668 | 10%; WHEE! and hat variants do not stack |
| MysteriousWisdom | 239142         | 1221184       | 10%                                      |
| TenLands         | 166750, 166751 | 289982        | 10%; below level 50 only                 |

MidnightDelves includes MysteriousWisdom and Darkmoon. TenLands is available for
lower-level profiles. Two additional 10% sources extend Midnight's linear table
to 110% total / target 83.5; this is extrapolated and not a verified completion level.
These sources use the same bonus model as the rest of the profile.

Sources: [Bottle of Mysterious Wisdom](https://www.wowhead.com/item=239142/bottle-of-mysterious-wisdom),
[Darkmoon hat and WHEE!](https://worldofwarcraft.blizzard.com/en-us/news/21508135/building-reputation-with-allied-races),
[Ten Lands level limit](https://worldofwarcraft.blizzard.com/en-us/news/24242432).
Legacy items 86574, 120182 and 128312 have no XP use effect in current retail
tooltips and are excluded. This is an explicit verified catalog, not automatic
tooltip-based discovery of every item. Add future verified consumables here.

The target is cached in memory and refreshed on player aura changes, achievements,
War Mode status, zone transitions, and entering the world. Unchanged targets do not rebuild the guide. The displayed
Grind label includes the fractional XP percentage. Standard APR progression still
applies: changing buffs does not rewind skipped steps or remove activated parallel
groups. Quest readiness, turn-in zone and campaign prerequisites remain required.

## Reputation progress in the current step

An active `Reputation = { factionID = 76, level = 6 }` step displays a reputation
bar below its objective text. Optional `type = "standard"`, `"renown"` or
`"friendship"` selects the system explicitly; automatic detection is unchanged.
The objective names the final target; the bar shows points and percentage within
the current standing/rank. It updates through the existing reputation events,
resets its range when the rank changes and disappears when leaving the step.
Missing or zero-width API ranges hide the bar without changing step completion.
This works with the existing route syntax; no additional step option is required.

## Absolute XP requirements

Step fields `Grind`, `Level`, `MinLevel`, `MaxLevel` and `SkipForLvl` also accept
`{ level = N, xp = signedInteger }`. This extends the existing level resolver;
numeric levels, fractional levels and named level profiles keep their behavior.

```lua
{ Grind = { level = 3, xp = 325 } }, -- Level 3 with at least 325 XP
{ Grind = { level = 4, xp = -700 } }, -- At most 700 XP remaining before level 4
{ PickUp = { 123 }, SkipForLvl = { level = 3, xp = 325 } },
```

A positive offset counts XP into `level`; a negative offset counts backwards
from reaching `level`. Both values must be finite integers, with `level >= 1`.
The resolver uses the current client's `UnitXPMax` while the player is at the
relevant level, so the route does not embed another client's XP table. Thresholds
outside that level's XP range are clamped to its boundaries. Missing XP data
delays completion until the total becomes available. These structures apply to
step fields only, not route visibility conditions or `BeLvl`.

## Resource conditions and Hardcore routes

Steps can use these filters with the existing `AnyOf` composition:

```lua
Money = { operator = ">=", copper = 10000 },
ItemCount = { itemIDs = { 6948 }, operator = ">=", count = 1 },
EquippedItemStat = {
    slot = 16, stat = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT",
    operator = "<", value = 3.5,
},
Hardcore = false,
```

Operators are `<`, `<=`, `>`, `>=`, `==` and `~=`. `Money` uses copper, not gold.
`ItemCount` accepts either `itemID` or a summed `itemIDs` list; the default operator
is `>=`. Equipped items are included by the game API. `includeBank = true` includes
bank items; `includeUsableToys = true` counts an owned usable toy when its item count
is zero. `EquippedItemStat` reads a stat token, `QUALITY` or `LEVEL` from an equipment
slot. Optional `precision` rounds before comparing; `allowMissing = true` keeps
the step eligible when the equipment stat is unavailable. Otherwise missing data
does not satisfy a resource filter. These are step filters, not route visibility
conditions. Like other step filters, failing them skips the step; they do not wait
for the player to acquire resources.

Use `LootItems` to **collect** items and track progress; use `ItemCount` to
**condition another action** on the current inventory. For example,
`LootItems = { { itemID = 2589, quantity = 10 } }` waits for ten Linen Cloth,
whereas `ItemCount = { itemID = 2589, count = 10 }` only allows the step when the
player already has at least ten, and skips it otherwise. `LootItems` checks each
entry separately and can use virtual loot or remembered completion; `ItemCount`
can sum several item IDs, supports comparisons such as `<` and `==`, and uses
the current count. They are not interchangeable.

`Hardcore = true/false` uses `C_GameRules.IsHardcoreActive`; clients without that
API are treated as non-Hardcore. Source death shortcuts are restricted to
non-Hardcore characters. Voluntary self-found choices remain explicit review notes.
Money, bag and equipment events refresh relevant active steps through a coalesced
timer. Unrelated steps do not rebuild on those events.

Follow-up suggestions can mix existing string keys and conditional entries:

```lua
nextRoute = {
    "Forever-Shared-Route",
    { route = "Forever-Class-Route", conditions = { Class = "MAGE" } },
},
```

The target must pass normal route visibility requirements and the entry's
conditions must pass the existing step filter evaluator. This preserves class
branches without duplicating a complete route.

Prefab entries accept either the existing numeric index or an index with native
conditions. The conditions select membership in that prefab without hiding the
route from manual selection:

```lua
prefab = {
    [APR.PREFAB_TYPES.Leveling] = { index = 10, conditions = { Race = { "Orc", "Troll" } } },
    [APR.PREFAB_TYPES.Speedrun] = { index = 10, conditions = { Race = { "Orc", "Troll" } } },
},
```
