# Azeroth Pilot Reloaded - Route and Step Options Reference

## Table of Contents

1. [Route Definition Options](#route-definition-options)
2. [Action / Progression Options](#action--progression-options)
3. [Navigation and Targeting](#navigation-and-targeting)
4. [Automation and Display](#automation-and-display)
5. [Filters and Conditions](#filters-and-conditions)
6. [Miscellaneous and Legacy](#miscellaneous-and-legacy)
7. [Example Route](#example-route)
8. [Configurable Level Profiles](#configurable-level-profiles)
9. [Midnight Delver's Call Profile](#midnight-delvers-call-profile)
10. [XP Consumables and Optional Reminders](#xp-consumables-and-optional-reminders)

## Route Definition Options

| Option | Description | Expected Syntax |
| --- | --- | --- |
| `category` | Route category enum. Common values are leveling, speedrun, campaign, etc. | `category = APR.CATEGORIES.Leveling` |
| `conditions` | Route selection rules; see the supported scopes in Filters and Conditions. | `conditions = { Level = 80, Faction = "Alliance" }` |
| `expansion` | Expansion enum used to group the route in the UI. | `expansion = APR.EXPANSIONS.Midnight` |
| `gameVersion` | Client family: `"retail"`, `"forever"` or `"classic"`. Incompatible routes are hidden and unavailable. | `gameVersion = "forever"` |
| `label` | Display name shown in the route list. | `label = "Midnight - Speedrun"` |
| `mapID` | Main map ID for the route. Used as route metadata and zone fallback. | `mapID = 2393` |
| `nextRoute` | Follow-up route keys. Conditional entries must also pass the target route's selection rules. | `nextRoute = { "Shared", { route = "Class", conditions = { Class = "MAGE" } } }` |
| `parallelSteps` | Insert eligible groups at the current position, or after the current `InstanceQuest` block. Inserted groups remain even if conditions change. | `parallelSteps = { { conditions = { MinLevel = 88 }, steps = { ... } } }` |
| `prefab` | Prefab membership and ordering. Entry conditions select membership without hiding manual route selection. | `prefab = { [APR.PREFAB_TYPES.Speedrun] = { index = 20, conditions = { Class = "MAGE" } } }` |
| `requiredRoute` | Required route keys. Applicable unfinished requirements are added before this route; hard visibility failures waive them, temporary level/spec/zone restrictions do not. | `requiredRoute = { "2432-Midnight-Intro" }` |
| `steps` | Main ordered list of route steps. | `steps = { { PickUp = { 86733 } }, ... }` |
| `legacyLabels` | Previous labels recognized when resolving saved route names. | `legacyLabels = { "Old route label" }` |
| `autoStartOnMap` | Allows starter-route detection on the route's map. | `autoStartOnMap = true` |
| `notSkippable` | Prioritize this starter route and protect it from automatic prefab reset suggestions. | `notSkippable = true` |
| `hiddenFromSelection` | Hide the route from manual route selection. | `hiddenFromSelection = true` |
| `temporary` | Temporary guide that preserves the parent route for resuming afterward. | `temporary = true` |
| `sojournerAchievementID` | Completed Sojourner achievement that allows campaign auto-skip when the player enables that setting. | `sojournerAchievementID = 61576` |
| `scenarios` | Scenario variants for an instance route; each has `scenarioID`, `steps` and optional `label`/`index`. | `scenarios = { { scenarioID = 3101, steps = { ... } } }` |
| `delve` | Marks a route as a Delve guide. | `delve = {}` |

A file may register several independent `APR.RouteQuestStepList["route-key"] = { ... }` entries. Follow-up routes, prerequisites and prefabs reference these keys, not file names.

### Parallel reward groups

| Case | Required behavior / syntax |
| --- | --- |
| Ready, unturned-in quest | `conditions = { IsQuestOnQuest = 93384, IsQuestReadyForTurnIn = 93384, IsQuestUncompleted = 93384 }` |
| Reward available above a threshold | Use `MinLevel`, rather than `BeLvl`, and add `Zones` when activation should wait for a visit to the reward map. |
| Independent rewards | Use separate groups for independently available hand-ins; a single `Done` list waits for every quest. |
| Pending hand-ins | Automatic turn-ins listed in pending groups wait for activation; manual turn-ins and the modifier override remain available. |
| Side objectives | Use `Fillers` during other steps; add a `Qpart` before `Done` for unfinished objectives. |
| Character restrictions | Keep shared eligibility on the route; child steps and prefabs need only additional restrictions. |

## Action / Progression Options

An action waits for completion; a failed step condition skips the step. Use one main action per step.

| Option | Description | Expected Syntax |
| --- | --- | --- |
| `Achievement` | Track an achievement or criterion. Prefer `criteriaID` over positional `criteriaIndex`; if both are given, the ID wins. | `Achievement = { achievementID = 61960, criteriaID = 111471 }` or `{ achievementID = 61576 }` |
| `BankDeposit` | Move every listed bag stack into the open Classic character bank and bank bags; excludes guild, reagent and warband banks. | `BankDeposit = { items = { 4371, 5465 } }` |
| `BankWithdraw` | Move every listed Classic character-bank stack into bags while the bank is open. | `BankWithdraw = { items = { 4371 } }` |
| `BuyMerchant` | Buy quantities from the open merchant as a main or secondary action. `MerchantNPC` restricts the merchant; place junk sales before purchases. | `BuyMerchant = { { itemID = 4371, quantity = 1 } }` |
| `ChromiePick` | Selects a specific Chromie Time timeline by option ID. | `ChromiePick = 8` |
| `DeathSkip` | Wait for death, confirm resurrection at a spirit healer, then finish on resurrection. Does not kill the character or accept an ordinary player resurrection as completion. | `DeathSkip = true, Hardcore = false` |
| `DestroyItems` | Delete every bag stack of the listed items and wait until absent; no quantity limit. | `DestroyItems = { items = { 12345 } }` |
| `EquipItem` | Show the localized item name and an item button; complete once the specified slot contains the item. Use possession and level conditions for deferred parallel reminders. | `EquipItem = { itemID = 2030, slot = 16 }` |
| `Done` | Quests to turn in. The step completes once all listed quests are handed in. If using `DoneDB`, keep a base `Done` field as well. | `Done = { 12345, 12400 }` |
| `DoneDB` | Alternative quest IDs counted as the same hand-in. Requires `Done`. | `DoneDB = { 12345, 54321 }` |
| `DoScenario` | Indicates that the player should complete the scenario. | `DoScenario = { questID = 86912, mapID = 2505 }` |
| `DroppableQuest` | Defines passive or active dropped-quest tracking. When used without `DropQuest`, it behaves like a filler hint. | `DroppableQuest = { Qid = 41234, MobId = 133713, Text = "Fel Marauder" }` |
| `DropQuest` | Quest obtained from a mob drop. Must be paired with a corresponding `DroppableQuest`. | `DropQuest = 48876` |
| `Emote` | Requires performing an emote on a target or at a step. | `Emote = { emote = "salute", npcID = 12345 }` |
| `EnterInstance` | Guides the player into an instance. | `EnterInstance = { questID = 12345, mapID = 2505 }` |
| `EnterScenario` | Guides the player to a scenario entrance. | `EnterScenario = { questID = 86636, mapID = 2502 }` |
| `ExitTutorial` | Exile's Reach specific step that auto-skips if the exit quest is no longer tracked. | `ExitTutorial = 59985` |
| `Fillers` | Optional side objectives that can progress during any step without blocking the route. | `Fillers = { [49529] = { 1 }, [49897] = { 1 } }` |
| `GetFP` | Learn a flight path node. | `GetFP = 2395` |
| `Grind` | Wait until the level/XP threshold is reached; supports numbers, absolute XP and named profiles. | `Grind = 60` |
| `Group` | Marks an optional group quest and shows a popup (`questID`, `Number`). | `Group = { questID = 51384, Number = 3 }` |
| `GroupTask` | Associates the step with `WantedQuestList` to store the player's decision for a group quest. | `GroupTask = 51384` |
| `LearnProfession` | Checks if a specific profession spell is learned. | `LearnProfession = 2259` |
| `LearnSkill` | Train spells at a trainer. Waits if unavailable or unaffordable; add the required `MinLevel` and class filters. | `LearnSkill = { spellID = 6673 }, MinLevel = 1` |
| `LeaveInstance` | Prompts to leave the instance once objectives are done. | `LeaveInstance = { questID = 12345, mapID = 2505 }` |
| `LeaveQuest` | Abandons a single quest from the quest log. | `LeaveQuest = 38254` |
| `LeaveQuests` | Abandons multiple quests from the quest log. | `LeaveQuests = { 38254, 38257 }` |
| `LeaveScenario` | Prompts to leave the scenario once objectives are done. | `LeaveScenario = { questID = 86912, mapID = 2505 }` |
| `LootItems` | Wait for each quantity (default 1) in bags plus the saved character bank. A completed `questID` also satisfies its entry; no virtual loot or remembered counts. | `LootItems = { { questID = 86644, itemID = 244143, quantity = 1 } }` |
| `LootMoney` | Wait for cash plus carried items' estimated vendor value to reach `copper`; shows a progress bar. Excludes banks and uncached prices. See resource fields below. | `LootMoney = { copper = 10, includeEquipped = true }` |
| `MountVehicle` | Automatically validates when a mount / boarding event is detected. | `MountVehicle = true` |
| `Note` | Informational step accepting a string or array of strings. Seen notes are remembered and can auto-skip on later resets / revisits. | `Note = { "Open the map", "Follow the bridge north" }` |
| `NpcDismount` | Automatically dismounts to talk to the targeted NPC. | `NpcDismount = 43733` |
| `PickUp` | List of quest IDs to pick up. The step remains active until all quests are in the log. If using `PickUpDB`, keep a base `PickUp` field as well. | `PickUp = { 39688 }` |
| `PickUpDB` | Alternative quest IDs for the same pickup step (class / faction variants). Requires `PickUp`. | `PickUpDB = { 39688, 39694, 40255, 40256 }` |
| `Qpart` | Quest objectives to complete, mapped by quest ID and objective index. | `Qpart = { [12345] = { 1, 2 } }` |
| `QpartDB` | Alternative quest IDs for the same `Qpart` block. Requires `Qpart`. | `QpartDB = { 12345, 12346 }` |
| `QpartPart` | Splits a single objective into guided sub-parts. Commonly paired with `TrigText`. Supports fraction and percentage style progress markers. | `QpartPart = { [12345] = { 1 } }, TrigText = "1/3"` |
| `Reputation` | Wait for the target standing, renown or friendship rank; shows progress within the current rank. See reputation types below. | `Reputation = { factionID = 2590, type = APR.REPUTATION_TYPE.Renown, level = 10 }` |
| `ResetRoute` | Shows a confirmation popup that resets the active route back to step 1. | `ResetRoute = true` |
| `RouteCompleted` | Marks the route as finished and triggers route completion flow. Must stay as the last step. | `RouteCompleted = true` |
| `Scenario` | Fine-grained scenario objective tracking (`scenarioID`, `stepID`, `criteriaID`, etc.), optionally tied to a quest ID. | `Scenario = { criteriaID = 106007, criteriaIndex = 1, scenarioID = 3101, stepID = 15911, questID = 86820 }` |
| `SellItems` | Sell listed stacks and/or grey junk at the open merchant. `npcID` restricts the vendor; no quantity limit. Junk uses the localized default label; put extra advice in `Note`. | `SellItems = { items = { 7073, 7074 }, npcID = 54 }` or `SellItems = { junk = true }` |
| `SetHS` | Step to set the Hearthstone. | `SetHS = 31732` |
| `TameBeast` | Offer the tame spell and target button; validate a successful cast started on the specified NPC. | `TameBeast = { npcID = 2163, spellID = 1515 }` |
| `Treasure` | Treasure or vignette step. The addon tracks the treasure's anchor quest, with optional item details for the tooltip. | `Treasure = { questID = 89105, itemID = 238553 }` |
| `UseDalaHS` | Dalaran Hearthstone variant. | `UseDalaHS = 44184` |
| `UseFlightPath` | Step for using a flight master. Validates once the flight is complete. | `UseFlightPath = 39580` |
| `UseGarrisonHS` | Garrison Hearthstone variant. | `UseGarrisonHS = 110560` |
| `UseHS` | Step to use the Hearthstone. | `UseHS = 31732` |
| `UseItem` | Standalone item-use action. `questID` is required; APR resolves the use spell from the item unless `itemSpellID` is supplied. Use `Button` when the item supports another objective. | `UseItem = { questID = 42008, itemID = 173430, itemSpellID = 254294 }` |
| `UseSpell` | Standalone spell-cast action. `questID` is required. Use `SpellButton` when the spell supports another objective. | `UseSpell = { questID = 42476, spellID = 193759 }` |
| `VehicleExit` | Forces exiting a vehicle. | `VehicleExit = true` |
| `WarMode` | Ask the player to enable War Mode; completes when it is desired. The quest ID supplies the label. XP bonuses require active War Mode. | `WarMode = 60361` |

### Action details

| Applies to | Detail |
| --- | --- |
| `LearnSkill`: named spells | `spellID = 6673` or `spellIDs = { 6673, 100 }` supplies localized names; optional `npcID` restricts the trainer. |
| `LearnSkill`: all services | `LearnSkill = { allAvailable = true, npcID = 911 }`; trainer ID required. Use `text` for advice when no spell IDs are supplied. |
| `SellItems`, `BankDeposit`, `BankWithdraw`, `DestroyItems` | Process full stacks; pause in combat or on locked slots and leave foreign cursor items alone. |
| `TameBeast`, item handling | Cached NPC/item names take priority; `text` or `Text` can supply fallback advice. These fields accept localization keys or literal text. |
| Selling then buying | Use successive steps with the same coordinates and character restrictions. Put an already-owned-item purchase filter only on the purchase. |
| `LootItems`, `Collection` | Character-bank counts are saved while the bank is accessible and reused after closing/reloading. Moving items between bags and bank does not increase the combined count. |
| `Achievement` legacy criterion | `Achievement = { achievementID = 61576, criteriaIndex = 1 }` tracks by position; prefer a stable `criteriaID`. |
| `LootMoney` | Use it as the main objective. `Money` checks spendable cash; it is not a replacement for this collection objective. |

## Navigation and Targeting

| Option | Description | Expected Syntax |
| --- | --- | --- |
| `Boat` | Indicates the player should take a boat instead of flying. Requires `UseFlightPath`. | `Boat = true` |
| `Coord` | World coordinates used by the arrow (`x`, `y` in WoW units). | `Coord = { x = 4298.4, y = -864.1 }` |
| `Coords` | Multiple coordinate variants for the same step. Typically paired with `Zones`; each entry should include its own `Zone`. | `Coords = { { Zone = 84, x = 797.7, y = -8624.9 }, { Zone = 85, x = -4436, y = 1590.3 } }` |
| `EmoteETA` | Duration in seconds of the AFK countdown, started once after the matching step emote is performed via the button, chat command or APR. Displaying the step does not start it. | `EmoteETA = 60` |
| `ETA` | Estimated AFK timer duration in seconds. | `ETA = 75` |
| `GossipETA` | Starts an AFK timer after gossip confirmation. | `GossipETA = 45` |
| `InstanceQuest` | Marks instance steps; delays automatic Delve suggestions. A nearby matching `DoScenario` is replaced by the guide while preserving preceding setup steps. | `InstanceQuest = true` |
| `IsAdventureMap` | Allows auto-accepting quests from the Adventure Map. | `IsAdventureMap = true` |
| `Name` | Optional custom name to override the taxi node name. | `Name = "Krasus' Landing"` |
| `NoArrow` | Hides the navigation arrow for this step. | `NoArrow = true` |
| `NoAutoFlightMap` | Prevents automatic flight / gossip selection for this step. | `NoAutoFlightMap = true` |
| `NodeID` | Flight path node ID used on `UseFlightPath` steps. | `NodeID = 1719` |
| `NonSkippableWaypoint` | Prevents the step from being skipped manually. | `NonSkippableWaypoint = true` |
| `Range` | Distance in yards from `Coord` to consider the location reached. | `Range = 45` |
| `SingleWaypointDisplayDistance` | Display only the distance to the next waypoint instead of the remaining waypoint chain. | `SingleWaypointDisplayDistance = true` |
| `SpecialETAHide` | Hides the AFK timer even if `ETA` is set. | `SpecialETAHide = true` |
| `SpellETA` | Start the AFK timer after the successful cast of `spellID`, or the use spell of `itemID`. | `SpellETA = { spellID = 123, seconds = 30 }` |
| `TakePortal` | Use a portal; completes at `mapID` or when the linked quest is completed. Destination names come from the map ID. | `TakePortal = { questID = 81888, mapID= 85 }` |
| `Waypoint` | Quest-related waypoint displayed until completion. | `Waypoint = 44543` |
| `WaypointDB` | Alternative waypoint quests that allow skipping if already completed. Requires `Waypoint`. | `WaypointDB = { 44543, 44544 }` |
| `Zone` | Expected map ID for the step. | `Zone = 627` |
| `Zones` | Multiple valid map IDs for a single step. Also acts as a condition: the step is only considered valid when the player is in one of those maps. | `Zones = { 84, 85 }` |
| `ZoneStepTrigger` | Automatically validates the step when entering the specified radius. | `ZoneStepTrigger = { x = 4098.2, y = -712.4, Range = 25 }` |

### Map coordinate conversion

| Input / result | Behavior |
| --- | --- |
| Recorded `Coord` | Prefer existing APR world coordinates. Never place map percentages directly in `Coord`. |
| Map percentages | `Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(2393, 52.54, 78.88)`; inputs range from 0 to 100. |
| Conversion | Uses the in-game map API; returns swapped APR world axes rounded to one decimal, or `nil` if unavailable. Verify in game before saving static coordinates. |

## Automation and Display

| Option | Description | Expected Syntax |
| --- | --- | --- |
| `Bloodlust` | Adds a reminder to use Heroism / Bloodlust. | `Bloodlust = true` |
| `Buffs` | List of buff spell IDs to recommend. | `Buffs = { { spellId = 311103, tooltipMessage = "FRESHLEAF_BUFF" } }` |
| `Button` | Associates items to use with objectives (`"QuestID-Objective"` -> `itemID`). Can also be used with non-objective steps by using only the quest ID as the key. | `Button = { ["30778-1"] = 81356 }` |
| `DenyNPC` | NPC ID whose gossip should be closed automatically. | `DenyNPC = 209914` |
| `Dontskipvid` | Prevents automatic skipping of cutscenes or videos. | `Dontskipvid = true` |
| `ExtraActionB` | Prompts use of the special extra action button. | `ExtraActionB = true` |
| `ExtraLineText*` | Additional helper lines displayed in the current step panel. Supports numbered variants such as `ExtraLineText2`, `ExtraLineText3`, etc. Accepts localization keys or literal text. | `ExtraLineText = "Interact with the second console"` |
| `GossipOptionIDs` | Automatically select dialogue by option ID, rather than position. | `GossipOptionIDs = { 51901, 51902 }` |
| `InVehicle` | Indicates vehicle status (`1` = enter, `2` = stay in vehicle). | `InVehicle = 1` |
| `MerchantNPC` | Limit the step purchase to this merchant NPC. | `MerchantNPC = 54` |
| `NoAutoAccept` | Keep the quest pickup visible but require manual acceptance. | `NoAutoAccept = true` |
| `NoAutoTurnIn` | Keep the quest hand-in visible but require manual interaction. | `NoAutoTurnIn = true` |
| `PreviewImages` | Displays one or more clickable image previews in the current step panel. Relative paths are resolved from `APR-Core/assets/`; full `Interface\\...` paths are also accepted. | `PreviewImages = { "routeHelper\\86644.jpg" }` |
| `RaidIcon` | NPC ID to mark with a raid icon. | `RaidIcon = 241743` |
| `SpellButton` | Spell buttons keyed by quest ID or `questID-objective`. Prefer numeric spell IDs; names must be understood by the client language. | `SpellButton = { ["49939-1"] = 294197 }` |
| `SpellTrigger` | Automatically completes the step when the given spell is cast. | `SpellTrigger = 306719` |
| `TrigText*` | Text fragments used as completion triggers (`TrigText`, `TrigText2`, etc.). | `TrigText = "Restore the console"` |
| `UseGlider` | Displays available gliders for controlled jumps. | `UseGlider = true` |
| `IsCampaignQuest` | Marks the step as part of a campaign. | `IsCampaignQuest = true` |

## Filters and Conditions

Conditions on the same table combine with AND. Use `AnyOf` for alternatives, `AllOf` for repeated predicates and `Not` to invert a whole condition table.

| Scope | Supported conditions / result |
| --- | --- |
| Steps and `parallelSteps[].conditions` | All filters below; group conditions control insertion, while a failed step filter skips that step. |
| Route `conditions`: visibility | `InterfaceVersion`, `InterfaceVersionExact`, `DontHaveSpell`, `IsQuestReadyForTurnIn`, `HasAchievement`, `DontHaveAchievement`, `Faction`, `Race`, `Class`, `ClassNot`, `Event`, `AlliedRace`, `IsQuestCompleted`, `IsQuestUncompleted`. Failure hides the route. |
| Route `conditions`: availability | Numeric `Level`, `MinLevel`, `MaxLevel`, `BeLvl`, plus `ClassSpec` and `Zones`. Failure disables the route. |
| Route-level `AnyOf` | Alternatives use step filters; failure hides the route, including failures of nested level conditions. |
| Conditional `nextRoute` / `prefab` entries | Use step filters; these affect the suggestion or prefab membership. |

| Option | Description | Expected Syntax |
| --- | --- | --- |
| `AlliedRace` | Restricts based on whether the character is an allied race. | `AlliedRace = true` |
| `AllOf` | Require every enclosed condition table to match. Useful for repeated predicates such as several quest-presence checks. | `AllOf = { { IsQuestNotOnQuest = 10 }, { IsQuestNotOnQuest = 20 } }` |
| `AnyOf` | Requires at least one alternative condition table to match, in addition to all other conditions on the step/group. An empty list never matches. | `AnyOf = { { IsQuestOnQuest = 86733 }, { IsQuestCompleted = 86852, IsQuestUncompleted = 86733 } }` |
| `BeLvl` | Exact effective level check. The player must be at least this level, but below the next whole level. | `BeLvl = 88` |
| `Class` | Require one or more classes; accepts tokens or class IDs. | `Class = { "HUNTER", "ROGUE" }` |
| `ClassNot` | Exclude one or more classes; route mismatches hide the route. | `ClassNot = APR.Classes.Evoker` |
| `ClassSpec` | Restricts to a specialization ID. For routes, failing this condition makes the route disabled rather than hidden. | `ClassSpec = APR.Specs["Mage - Frost"]` |
| `Collection` | Require at least `quantity` items (default 1) in bags plus the saved character bank, using the same count as `LootItems`. | `Collection = { itemID = 5465, quantity = 50 }` |
| `DontHaveAchievement` | Visible only if the achievement is missing. | `DontHaveAchievement = 9924` |
| `DontHaveAura` | Requires the aura to be absent. | `DontHaveAura = 32182` |
| `DontHaveSpell` | Requires a spell to be unknown by both the player and pet. With a list, **none** of the listed spells may be known. Uses the same spellbook wrapper as `HasSpell`. | `DontHaveSpell = { 264211, 264434 }` |
| `EquippedItem` | Require one slot entry or a nonempty list (every entry must pass). Omit `itemID` for any item; `invert = true` negates that entry. | `EquippedItem = { slot = 16, itemID = 2493 }` |
| `EquippedItemStat` | Compare a slot's stat token, `QUALITY` or `LEVEL`. A nonempty list requires every entry to pass. See resource fields below. | `EquippedItemStat = { slot = 16, stat = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", operator = "<", value = 3.5 }` |
| `Event` | Restricts to a specific APR event mode, such as Remix. | `Event = APR.EVENTS.Remix` |
| `Faction` | Restricts to a faction (`"Alliance"` or `"Horde"`). | `Faction = "Horde"` |
| `Gender` | Restricts to a gender (`1` neutral, `2` male, `3` female). | `Gender = 3` |
| `Hardcore` | Require Hardcore (`true`) or non-Hardcore (`false`). Clients without `C_GameRules.IsHardcoreActive` count as non-Hardcore. | `Hardcore = false` |
| `HasAchievement` | Requires a specific achievement. | `HasAchievement = 12593` |
| `HasAura` | Requires a specific buff or aura. | `HasAura = 178207` |
| `HasSpell` | Requires the player or pet to know a specific spell. | `HasSpell = 34090` |
| `InterfaceVersion` | Minimum client interface version; route mismatches hide the route. | `InterfaceVersion = 110200` |
| `IsOneOfQuestsCompleted` | Requires at least one quest in the list to be completed. | `IsOneOfQuestsCompleted = { 31588, 31589 }` |
| `IsOneOfQuestsCompletedOnAccount` | Account-wide variant of `IsOneOfQuestsCompleted`. | `IsOneOfQuestsCompletedOnAccount = { 49929, 49930 }` |
| `IsOneOfQuestsUncompleted` | Requires none of the listed quests to be completed (negates `IsOneOfQuestsCompleted`). | `IsOneOfQuestsUncompleted = { 31588, 31589 }` |
| `IsOneOfQuestsUncompletedOnAccount` | Account-wide variant of `IsOneOfQuestsUncompleted`. | `IsOneOfQuestsUncompletedOnAccount = { 49929, 49930 }` |
| `IsQuestCompleted` | Requires a single quest to be completed. | `IsQuestCompleted = 35049` |
| `IsQuestNotOnQuest` | Requires the quest to be absent from this character's current log. Combine with `IsQuestUncompleted` to exclude completed quests too. | `IsQuestNotOnQuest = 86737` |
| `IsQuestOnQuest` | Requires the quest in this character's current log; account completion is not sufficient. | `IsQuestOnQuest = 86737` |
| `IsQuestReadyForTurnIn` | True for a quest in this character's log with completed objectives, or a quest already turned in by this character. A list requires every quest to be ready. | `IsQuestReadyForTurnIn = 93384` |
| `IsQuestsCompleted` | Requires all listed quests to be completed. | `IsQuestsCompleted = { 31821, 31822 }` |
| `IsQuestsCompletedOnAccount` | Account-wide variant of `IsQuestsCompleted`. | `IsQuestsCompletedOnAccount = { 49929, 49930 }` |
| `IsQuestsUncompleted` | Requires at least one listed quest to still be incomplete. | `IsQuestsUncompleted = { 31821, 31822 }` |
| `IsQuestsUncompletedOnAccount` | Account-wide variant of `IsQuestsUncompleted`. | `IsQuestsUncompletedOnAccount = { 49929, 49930 }` |
| `IsQuestUncompleted` | Requires a single quest to be incomplete. | `IsQuestUncompleted = 35049` |
| `ItemCount` | Compare current item counts, summing `itemIDs` if supplied. Includes equipped items; optional bank/toy counting. See resource fields below. | `ItemCount = { itemIDs = { 6948 }, operator = ">=", count = 1 }` |
| `Level` | Minimum level/XP threshold; see level requirement forms below. | `Level = 80` |
| `MaxLevel` | Maximum level/XP threshold, inclusive. | `MaxLevel = 69` |
| `MinLevel` | Minimum level/XP threshold; keeps rewards eligible at higher levels. | `MinLevel = 10` |
| `Money` | Compare cash actually owned, in copper. See resource fields below. | `Money = { operator = ">=", copper = 10000 }` |
| `VendorMoney` | Compare cash plus carried items' estimated vendor value; uses the same inventory/equipment rules as `LootMoney`. | `VendorMoney = { copper = 102, equippedSlots = { 16 } }` |
| Named level profile | Dynamic threshold for step `Level`, `MinLevel`, `MaxLevel`, `SkipForLvl` and `Grind`; see Configurable Level Profiles. | `MinLevel = "MidnightDelves"` |
| `Not` | Invert the complete enclosed condition table. | `Not = { HasSpell = 6673 }` |
| `OnlyInZones` | Shows and executes the step only in one of these current player map IDs; otherwise skips it. Does not set navigation coordinates. | `OnlyInZones = { 2541 }` |
| `PickedLoa` | Specifies the chosen Loa in Zandalar (`1` = Bwonsamdi, `2` = Rezan). | `PickedLoa = 1` |
| `QuestLineSkip` | Prevents the optional group popup if a questline is intentionally skipped. | `QuestLineSkip = 51226` |
| `Race` | Require one or more races; accepts names or race IDs. | `Race = { "Orc", "Troll" }` |
| `ReputationLevel` | Shows the step only after the requested standing, renown level, or friendship rank has been reached. | `ReputationLevel = { factionID = 2590, type = APR.REPUTATION_TYPE.Renown, level = 10 }` |
| `Skill` | Compare learned skill rank, or its cap with `maximum = true`. Accepts a key, skill ID or localized `name`; default rank is 1 and operator is `>=`. | `Skill = { skill = "cooking", rank = 50, operator = ">=" }` |
| `SkipForLvl` | Skips the step once the player's effective level is greater than or equal to the given value. | `SkipForLvl = 89.18` |
| `SkipForPrimaryProfessions` | Skip once at least X primary professions are learned (positive integer). `2` keeps the step with zero or one profession. Cooking, fishing, first aid and archaeology never count. | `SkipForPrimaryProfessions = 2` |
| `SkipForReputation` | Hides and skips the step once the requested standing, renown level, or friendship rank has been reached. | `SkipForReputation = { factionID = 2773, type = APR.REPUTATION_TYPE.Friendship, level = 5 }` |
| `SkipInZones` | Hides and skips the step in any of these current player map IDs. Does not set navigation coordinates. | `SkipInZones = { 2393 }` |
| `InterfaceVersionExact` | Require an exact client interface version. | `InterfaceVersionExact = 120100` |

### Resource and equipment fields

| Option | Fields / defaults |
| --- | --- |
| Comparisons | `<`, `<=`, `>`, `>=`, `==`, `~=`. Missing numeric data fails the comparison unless explicitly allowed. |
| `Money` | Required `copper >= 0`; optional `operator`, default `>=`. |
| `LootMoney`, `VendorMoney` | Required `copper` (positive for `LootMoney`, nonnegative for `VendorMoney`). Bags include stack quantities and reagent bags; banks and unsellable items are excluded. Uncached vendor prices count as zero. |
| Vendor equipment value | Equipment excluded by default. `includeEquipped = true` includes all gear; `equippedSlots = { 16 }` includes selected slots. This estimates value without selling or unequipping anything. `VendorMoney.operator` defaults to `>=`. |
| `ItemCount` | Required `count >= 0` and `itemID` or `itemIDs`. Default `operator = ">="`. `includeBank = true` adds bank items; `includeUsableToys = true` counts an owned usable toy when its item count is zero. |
| `EquippedItem` | Required `slot`; optional `itemID` and `invert`. A list must be nonempty and all entries must pass. |
| `EquippedItemStat` | Required `slot`, `stat`, `value`; default `operator = "=="`. `precision` rounds before comparison; `allowMissing = true` accepts unavailable stats. Options apply per list entry. |
| Collection objective vs filter | `LootItems = { { itemID = 2589, quantity = 10 } }` waits for ten cloth; `ItemCount = { itemID = 2589, count = 10 }` skips another action unless ten are already owned. |
| Primary-profession threshold | `SkipForPrimaryProfessions = 1` skips a reminder once any primary profession is learned; `2` skips only once two are learned. Learning or unlearning refreshes the condition. |

### Level requirement forms

| Form | Meaning / supported fields |
| --- | --- |
| `MinLevel = 10` | Whole level threshold. |
| `Grind = 87.5` | Level 87 with at least 50% XP progress. |
| `MinLevel = "MidnightDelves"` | Named dynamic threshold from the configured active XP bonuses. |
| `Grind = { level = 3, xp = 325 }` | Level 3 with at least 325 XP into that level. |
| `Grind = { level = 4, xp = -700 }` | At most 700 XP remaining before level 4. |
| Supported fields | Step `Grind`, `Level`, `MinLevel`, `MaxLevel`, `SkipForLvl`. Route-selection level thresholds remain numeric; `BeLvl` does not accept profiles or absolute XP tables. |
| Absolute XP validation | Finite integers: `level >= 1`, signed `xp`. Uses the current client's XP range for the relevant level; out-of-range targets clamp to its boundaries. Missing XP data delays completion. |

### Reputation types

| Field | Meaning |
| --- | --- |
| `factionID` | Required faction ID. |
| `level` | Required target standing/renown/friendship rank; reaching a higher rank also satisfies it. |
| `type` | Optional; prefer an explicit type. If absent, detects renown, then friendship, then standard standing. |

| Constant | Meaning of `level` |
| --- | --- |
| `APR.REPUTATION_TYPE.Friendship` | Friendship rank number shown for the NPC faction. |
| `APR.REPUTATION_TYPE.Renown` | Renown level shown on the major faction track. |
| `APR.REPUTATION_TYPE.Standard` | Standard standing ID from `1` through `8`. |

| Constant | Standing ID |
| --- | --- |
| `APR.REPUTATION_STANDING.Exalted` | `8` |
| `APR.REPUTATION_STANDING.Friendly` | `5` |
| `APR.REPUTATION_STANDING.Hated` | `1` |
| `APR.REPUTATION_STANDING.Honored` | `6` |
| `APR.REPUTATION_STANDING.Hostile` | `2` |
| `APR.REPUTATION_STANDING.Neutral` | `4` |
| `APR.REPUTATION_STANDING.Revered` | `7` |
| `APR.REPUTATION_STANDING.Unfriendly` | `3` |

## Miscellaneous and Legacy

| Option | Description | Expected Syntax |
| --- | --- | --- |
| `_index` | Internal index auto-generated during route packaging. Do not edit manually. | `_index = 128` |
| `ExtraLine` | Legacy field for displaying a static localized helper line. | `ExtraLine = 13544` |
| `Gossip` | Legacy field for automatically selecting a gossip option by index. | `Gossip = 2` |

## Example Route

```lua
APR.RouteQuestStepList["Forever-Training-Example"] = {
    label = "Training example",
    gameVersion = "forever",
    mapID = 1411,
    conditions = { Faction = "Horde", Class = "MAGE" },
    steps = {
        {
            LearnSkill = { spellID = 7411 },
            MinLevel = 5,
            SkipForPrimaryProfessions = 2,
            Coord = { x = -4960.0, y = -791.3 },
            Zone = 1411,
        },
        { PickUp = { 96873 }, Skill = { skillID = 333, rank = 1 }, Zone = 1411 },
        { RouteCompleted = true },
    },
}
```

## Configurable Level Profiles

Definitions live in `APR-Core/config/LevelProfiles.lua`. Reload after editing.

| Definition / field | Meaning |
| --- | --- |
| `APR.LevelBonusSources` | Reusable XP-bonus sources referenced by name in profiles. |
| Source `auras` / `isActive` | Any listed active aura OR a true predicate activates the source once. Item ownership alone never activates a bonus. |
| Source `bonus` | Percentage contributed while active. |
| Source `achievementBonuses` | Achievement ID → percentage; highest completed tier wins, while the source must still be active. |
| Source `auraBonuses` | Aura ID → percentage or stack-count tiers. Selects the highest active variant and highest matched stack tier; missing/restricted counts use one application. |
| Source `minLevel` / `maxLevelExclusive` | Inclusive minimum and exclusive maximum; sources outside their range contribute nothing. |
| Source `items` | Usable item IDs offered as optional reminders when the source's aura is absent. |
| `APR.LevelRequirementProfiles` | Named profiles with `bonuses = { "SourceName", ... }` and `levels = { [0] = 88, [20] = 87.25 }`. |
| Profile `levels` | `[0]` required. Greatest bonus breakpoint not exceeding the active total wins; no interpolation (12% uses 10%, if the next row is 20%). |
| Unknown source/profile | Raises an error rather than silently dropping the threshold. |
| Refresh and progression | Bonuses refresh as auras, achievements, levels and world state change. Updates do not rewind skipped steps or remove inserted parallel groups. |

## Midnight Delver's Call Profile

| Use | Syntax / detail |
| --- | --- |
| Activate reward groups | `MinLevel = "MidnightDelves"` in group conditions. |
| Stop questing at the threshold | `SkipForLvl = "MidnightDelves"` on questing steps. |
| Wait before the hand-in circuit | `Grind = "MidnightDelves"`. Keep reward steps and final fallback quests capped at 90. |
| Calibration | Configured empirical thresholds include a rounded 4% margin after a full hand-in ended 22,072 XP short of level 90. They depend on collecting the intended rewards. |
| Active sources | `MidnightMentorship`, `WindsOfMysteriousFortune`, `WarMode`, `Timeways`, `MysteriousWisdom`, `Darkmoon`. |

The profile is an empirical estimate for all ten pending Delver's Call rewards.
A route report reached approximately 89.5 from 87.8 with six rewards, leaving four
Silvermoon rewards unspent. With the reported 5% mentorship, 10% potion and the
configured 15% War Mode bonus, the provisional full-tour target is **87.30 at 30%**.
This anchor is an estimate, not a measured ten-quest completion threshold.

For lower bonuses, convert the anchor into absolute XP instead of subtracting
fixed fractions of a level. The [published Midnight XP table](https://www.icy-veins.com/wow/news/players-need-nearly-5-million-xp-to-hit-level-90-in-midnight/)
gives 548,535 XP for 87-88, 570,590 for 88-89 and 592,980 for 89-90.
Thus the anchor leaves `0.70 * 548535 + 570590 + 592980 = 1547544.5` XP to earn.
For total bonus `b`, use `1547544.5 * (1 + b / 100) / 1.30` as the provisional
reward budget, convert the remaining XP back to a starting level, and round the
start upward to the next 5% of a level.

| Total active bonus | Required level |
| ------------------ | -------------- |
| 0%                 | 88.00          |
| 5%                 | 87.85          |
| 10%                | 87.75          |
| 15%                | 87.65          |
| 20%                | 87.55          |
| 25%                | 87.45          |
| 30%                | 87.30          |
| 35%                | 87.30          |

This keeps the base reward budget constant. Although reward XP scales with level,
it does **not** invent a per-quest scaling curve or count extra XP from starting
later. It assumes all ten rewards and the configured bonuses remain applicable;
missing rewards, different effective bonuses and the approximate report can change
the result. Validate these targets in game before treating them as guarantees.

The 35% tier is capped at 87.30 so more bonus never raises the required level.
The 40-110% tiers retain their older estimates and margins in
`APR-Core/config/LevelProfiles.lua`. Their original anchors included the
[community report](https://www.reddit.com/r/wow/comments/1u8haw4/delvers_call_quests_turnins_now_take_you_from/)
with 25% mentorship plus War Mode. That report did not specify the War Mode
percentage; this profile uses the requested fixed value of 15%.

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
Add Timeways and consumables to the total bonus before looking up the configured
breakpoint; do not subtract fixed level fractions. A total of 90% currently targets
84.68. These higher-bonus estimates still need in-game validation with all ten rewards.

## XP Consumables and Optional Reminders

| Source | Items | Auras | Configured bonus / restriction |
| --- | --- | --- | --- |
| `Darkmoon` | 93730, 171364 | 136583, 46668 | 10%; aura variants do not stack. |
| `MysteriousWisdom` | 239142 | 1221184 | 10%. |
| `TenLands` | 166750, 166751 | 289982 | 10%; below level 50. Available for lower-level profiles. |

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
lower-level profiles. Two additional 10% sources extend Midnight's table
to 110% total / target 83.68; this is extrapolated and not a verified completion level.
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
    { slot = 16, stat = "QUALITY", operator = "<", value = 7, precision = 1, allowMissing = true },
    { slot = 16, stat = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", operator = "<", value = 1.9, precision = 1, allowMissing = true },
},
EquippedItem = {
    { slot = 16, itemID = 2493 },
    { slot = 17, invert = true },
},
Hardcore = false,
```

Equipment condition lists use AND: every entry must pass. `invert`, `precision` and
`allowMissing` apply to their own entry. Single-object conditions remain supported;
use `AnyOf` for alternatives and `Not` to negate the whole list. Lists must not be empty.

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
