# Midnight alt: normal Silvermoon introduction

The alt route now handles the character who finishes the Sunwell introduction
without taking the skip and switches guides in or before Silvermoon.

Verified chain (all level 80, no class restrictions in ATT):

- 86852 -> 86733 -> 86734.
- 86735 is Alliance; 86736 is Horde. Both follow 86734.
- 86737 follows the city tour and leads to Fairbreeze.
- 94871 is an Adventure Mode breadcrumb to the same destination.

Evidence: local AllTheThings `db/Standard/Categories/Zones.lua`, the APR
`2393-Eversong-Woods-Campaign-Only` route, FollowTheArrow `EversongWoods.lua` and
`SunwellIntro.lua`, and Wowhead's retail quest tooltips:
`https://nether.wowhead.com/tooltip/quest/86735?dataEnv=1&locale=0`
(also checked 86733, 86734, 86736, 86737, 94871 and 86852).

Implementation:

- Append a conditional parallel group; retain the existing ten delve groups and
  all main-step indices. APR latches the group after activation, so handing in an
  intermediate quest does not remove the remaining introduction.
- Detect active city quests or character-specific predecessor completion. The
  fallback for a completed normal intro excludes completed adventure breadcrumbs.
  Account achievement 42045 alone never selects the city branch.
- Copy the 37 city steps from APR's campaign route, keeping world coordinates,
  faction restrictions and gossip IDs. Add Alliance objective 5 at the same
  Reliquary position recorded for Horde; FTA confirms both visit the same NPC.
  Do not invent an Alliance gossip option ID.
- Obtain the projector for 86737 before the normal alt circuit. Objective 2
  (listening) is omitted in both APR and FTA; objective 3 completes on reaching
  Fairbreeze. A second parallel group turns in 86737 once ready in Eversong.
- Suppress the intro-skip dialogue after 86852. Suppress early adventure-map
  steps while 86737 is active or complete. Hand in 94871 only if it is in the log.
- Continue with existing quests 86738/86739/86740. No new XP threshold is imposed
  on the prerequisite chain or its Fairbreeze reward.

Validation: `silvermoon_intro_test.lua` exercises fresh skip, completed Sunwell,
partial city progress, completed city chain, both factions' seven tour objectives,
breadcrumb suppression and deferred Fairbreeze reward. The regular performance
suite and Lua lint also run. The old full-route snapshot has unrelated historical
assumptions and is not the basis for these checks.

In-game checks still needed: exact quest flags set by Blizzard's skip (including
switching guides before accepting 94993), Alliance Reliquary interaction, and the
86737 ready event on arrival at Fairbreeze. These are not reproduced by mocked APIs.
