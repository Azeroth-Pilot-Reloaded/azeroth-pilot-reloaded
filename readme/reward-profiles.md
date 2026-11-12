# APR reward profiles

Reviewed 2026-11-12. Model revision: Forever hotfix context 2026-11-10;
Retail interface contexts 11.2.7 through the supported 12.1.5 declarations.

## Purpose and availability

These are **APR-authored, estimated leveling baselines**, not imported addon
scales, simulation results, BiS lists or mathematically optimal weights. A guide's
ordering does not determine numerical exchange rates. Equal template values
across builds mean shared estimates, not evidence of equal marginal DPS.
Pawn's automatic/explicit selection and confirmation remain authoritative.
APR is used only when that provider's existing contract selects APR.

Selection uses `APR:GetRewardBuildContext()` (client, class and Pawn build index),
not the context's descriptive primary attribute as a numeric weight. In Forever,
choose the character's build in reward settings. Auto/unresolved builds abstain;
APR does not infer Feral versus caster from a class-wide specialization or form.
Retail uses the native build selected by the shared context. Unknown classes,
builds, missing levels and unrecognized interface versions abstain. Unknown
future versions require a review, not silently reused Classic/Retail weights.

Forever supports levels 1-59 on interface 16001; Retail supports 1-79 on 110207
and 1-89 on the declared 120000/120001/120005/120007/120100/120105 interfaces.
A selected build is still required for these full profiles below level 10. APR deliberately abstains at
the level cap (60/80/90 respectively): these estimates do not support endgame
optimization. Settings status appends Blizzard's localized UNAVAILABLE string
when no APR scale can be resolved. Compatible Pawn scales remain usable there.
This is a visible restriction compared with the former universal default.

Levels 1-29 use 1.5 times the base Stamina estimate for Forever; levels 30-59
use the base. This is an APR leveling-survival preference, **not** a simulated
breakpoint or a claim about a talent learned at level 30. No endgame boss hit,
expertise or defense caps are applied to leveling. In particular, currently
being hit-capped does not remove item hit's value: a replacement can lose hit.
A nonlinear, target-aware cap model is outside this baseline.

## Coverage matrix

Each entry has its own client/class/build declaration. All use shared model
estimates unless an override is stated; these are not 68 distinct optimized sets.

| Class | Forever build -> model | Retail build -> model |
|---|---|---|
| Warrior | Arms/Fury: strength; Protection: strength tank | Arms/Fury: strength; Protection: strength tank |
| Paladin | Holy: healer; Protection: protection tank; Retribution: retribution | Holy: healer; Protection: strength tank; Retribution: strength |
| Hunter | Beast Mastery/Marksmanship/Survival: hunter | Beast Mastery/Marksmanship/Survival: agility |
| Rogue | Assassination/Combat/Subtlety: agility | Assassination/Outlaw/Subtlety: agility |
| Priest | Discipline/Holy: healer; Shadow: caster | Discipline/Holy: healer; Shadow: caster |
| Death Knight | unavailable | Blood: strength tank; Frost/Unholy: strength |
| Shaman | Elemental: caster; Enhancement: enhancement; Restoration: healer | Elemental: caster; Enhancement: agility; Restoration: healer |
| Mage | Arcane/Fire/Frost: caster | Arcane/Fire/Frost: caster |
| Warlock | Affliction/Demonology/Destruction: caster | Affliction/Demonology/Destruction: caster |
| Monk | unavailable | Brewmaster: agility tank; Mistweaver: healer; Windwalker: agility |
| Druid | Balance: caster; Feral DPS: feral; Feral tank: bear; Restoration: healer | Balance: caster; Feral: agility; Guardian: agility tank; Restoration: healer |
| Demon Hunter | unavailable | Havoc: agility; Vengeance: agility tank; Devourer: caster (12.x only) |
| Evoker | unavailable | Devastation/Augmentation: caster; Preservation: healer |

Forever physical Feral profiles assign **zero** to spell power and healing.
Bear prioritizes survival more than the damage model. Both retain weapon DPS:
Forever changed weapon damage and procs in forms; Classic Era assumptions do
not apply. Enhancement uses a distinct Strength-led post-November-10 estimate,
with secondary Intellect/SP value; it does not use Retail Agility or the older
November-4 guide's Intellect-led recommendation. Individual talent ranks and
experimental hybrids (Shockadin, Elehance, Fury-prot, etc.) are not modeled.
Select an appropriate custom Pawn scale for those builds.

## Coefficients and race

The declarations in RewardScoring.lua are the single numeric source. Primary
is normalized to 1. Base Crit/Haste estimates are 0.25; modern Mastery/Versatility
are 0.25. Retail Feral and Devourer use estimated Mastery 0.35, Haste 0.30,
Crit 0.25, Versatility 0.20, reflecting the cited general single-target priorities.
Other secondary distinctions are intentionally not invented. Stamina is 0.15
(0.7 tank); Armor is 0.005 (0.04 tank). Forever model conversions retain useful
AP, SP, regeneration and off-attributes; Retail removes those legacy conversions.
Tank weights represent an APR survival preference, not encounter mitigation sims.

Two Forever racial marginal effects are applied: Human Spirit multiplies the
Spirit coefficient by 1.10; Tauren Endurance multiplies Stamina's health value by
1.05. Other races get the unmodified model. Flat racial hit/crit/haste bonuses
are not added to every item; Orc pet damage, active racials, Gnome resource pool,
Skyborne regeneration and Retail racials need a richer marginal model, so no
unsupported coefficient adjustment is claimed. No weapon-skill racial table.

## Sources and licensing

Public sources consulted; no RXP, Zygor or other local addons were inspected.
No addon weight tables or implementation code were copied.

- [Blizzard Forever Druid deep dive](https://news.blizzard.com/en-us/article/24301515/world-of-warcraft-forever-class-deep-dives-hunter-and-druid): weapon DPS/procs work in forms.
- [Blizzard racial tuning, October 26](https://eu.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-3-november/631316/7): Human Spirit 10%, Tauren health only, other racial revisions.
- [Blizzard November 10 tuning announcement](https://us.forums.blizzard.com/en/wow/t/class-tuning-incoming-november-10/2404092): Strength/AP direction for leveling Enhancement.
- [Blizzard hotfixes](https://worldofwarcraft.blizzard.com/en-us/news/24315281/wow-forever-hotfixes-november-5-2026): Mental Dexterity conversion reduced. Search-indexed primary text was available; the full article returned HTTP 403 during review. Exact talent-rank simulation is not claimed.
- [Icy Veins Forever Feral](https://www.icy-veins.com/wow-forever/feral-druid-melee-dps-and-tank-pve-stat-priority): damage versus mitigation, Strength/AP, Agility, weapon DPS; its raid caps are not leveling requirements.
- [Icy Veins Forever Enhancement](https://www.icy-veins.com/wow-forever/enhancement-shaman-melee-dps-pve-stat-priority): hybrid mechanisms; November 4 priorities predate the subsequent tuning.
- [Icy Veins Forever Holy](https://www.icy-veins.com/wow-forever/holy-paladin-healer-pve-stat-priority) and [Retribution](https://www.icy-veins.com/wow-forever/retribution-paladin-melee-dps-pve-stat-priority): healing and hybrid build distinctions, provisional level-60 context.
- [Icy Veins Retail Feral](https://www.icy-veins.com/wow/feral-druid-pve-dps-stat-priority) and [Devourer](https://www.icy-veins.com/wow/devourer-demon-hunter-pve-dps-stat-priority): primary/secondary priorities, not numeric APR coefficients.
- [Pawn on CurseForge](https://www.curseforge.com/wow/addons/pawn), [public source](https://github.com/VgerMods/Pawn): separate Forever and Retail providers; restrictive CC BY-NC-ND license, no table reuse.
- [GearMatic changelog](https://www.curseforge.com/wow/addons/gearmatic/files/9478468): published WoWSims weights cover only 15/28 Forever profiles; priority-based coverage is broader. All Rights Reserved: no reuse.
- [GearedForever](https://www.curseforge.com/wow/addons/gearedforever): GPLv3 level/class/build comparison reference; no data or code imported.
- [Forever Leveling BiS](https://www.curseforge.com/wow/addons/forever-leveling-bis): leveling comparison reference, All Rights Reserved. No coefficients extracted or reused; the current public page did not expose a verifiable numeric weight methodology.
- [MythicSim priorities](https://www.mythicsim.com/wow-forever/stat-priority): reference-build derivatives, not universal leveling coefficients. [Open engine](https://github.com/sage3648/mythicsim-forever-engine) is MIT; no code imported. Its refusal of unsupported contexts informed APR's availability boundary.
- [Forever level cap](https://worldofwarcraft.blizzard.com/en-us/news/24315820), [Midnight level cap](https://news.blizzard.com/en-us/article/24264417/world-of-warcraft-midnighttm-now-live).
- Context7: GetBuildInfo fourth return is the interface number; UnitRace second return is the stable English token, on Mainline/Classic. Shared build identification is owned by ProfileUtils, not duplicated here.

## Limits and maintenance

Stats-only comparisons cannot guarantee the best proc, trinket, set, weapon-speed
interaction, pet scaling, school-specific damage item or encounter-dependent
choice. AP/ranged AP and several rating aliases still share the existing
extractor's representation. The model does not distinguish ranged/melee weaving,
individual abilities, buffs, talents, target levels or diminishing returns.
Those limits also prevent claiming every listed build has its best possible
weights. Manual choice or a suitable Pawn scale is preferable for those cases.

Review after each client patch or relevant hotfix, check source dates against
actual tuning, then update the declared patch revision and estimates together.
Never silently extend interface compatibility. Changes invalidate comparisons
through profile key/revision/level band and effective weights. Existing bag
PLAYER_LEVEL_UP and world/build refresh paths rescan; no permanent listener was
added. Regression fixtures cover synthetic items, missing contexts, boundaries,
independent copies, race modifiers, hand execution and comparison identity.

## Implementation and validation log (2026-11-12)

- Read repository/RTK/UB Mode/Windows-tool/test policies; waited for the explicit
  exclusive-write signal and verified base 6417619e on fix/ui-error.
- Inspected the shared context and public sources; rejected copying restricted
  addon tables and rejected the outdated pre-hotfix Enhancement premise.
- Added a synthetic physical-versus-SP behavior test; observed its intended red
  failure before replacing the class-wide hybrid weights with declarations.
- Added a real bag-consumer identity test; observed the intended red failure
  before including effective APR weights/profile/level band in prompt identity.
- Preserved existing equipment assertions. Integration fixtures now explicitly
  provide patch/build selections and persist that selection across simulated
  reloads. Replaced the former generic hybrid Spirit assertion with a selected
  Enhancement hybrid SP assertion; no universal Spirit requirement is claimed.
- Instrumented only RewardScoring.lua with the existing helper. Its manifest
  function count was unchanged; no unrelated source/library was regenerated.
- Targeted profile, equipment, bag/Pawn, NPC and instrumentation tests passed.
- Executed crapper --no-coverage, dryer --threshold 0.8 and mutator --scan through
  the bundled Windows launcher on both changed production files. All report no
  supported source files: Lua is unsupported. No CRAP/mutation success is claimed.
- Initial full run: 638 tests, four errors (three missing explicit fixture
  contexts, plus the newly added red identity case). Corrected those contracts.
- Next full run: 638 tests, one unrelated route-hook ordering assertion failed.
  The seven route-hook tests then passed isolated with no source/test changes.
- Final unchanged confirmation: `.venv/Scripts/python.exe tests/run.py`, 638
  tests passed in 125.069 seconds. Executed outside sandbox with TEMP/TMP at
  `.venv/tmp-reward-profiles`; logs under `.venv/reward-profiles-*.log` are local.
  The intermittent hook failure's underlying cause remains unestablished.
- git diff --check passed. The ten predecessor units are present; the external
  PartyFinderWorld commit was preserved, not included in this revision.

## Conservative armor in Forever bags and quest rewards

Bag suggestions and quest gear selection share a conservative policy when a supported Forever
leveling character has no selected build. It can propose usable armor for a
confirmed empty slot or replace worn armor when the candidate loses no raw stat,
does not reduce armor or stamina, and strictly increases armor or stamina.
Armor aliases are normalized; unknown stats are retained rather than assigned
guessed weights. Negative, missing and secret stats prevent a proof. A pure SP
increase, lost primary attribute or armor/stamina tradeoff is insufficient.
This policy cannot choose weapons/offhands or fill jewelry, shirts/tabards.
Common uniqueness and native usability checks still apply.
An item ID without a loaded equipped link
does not prove an empty slot. The same checks run again on the explicit equip
click. No equip action is authorized by an equipment event or timer.

This is a partial-order proof, not an inferred build or DPS estimate. Only after
that proof, armor and stamina contribute sorting points inside this policy;
they never compensate for a lost stat. The dialog omits weighted-source and
score claims. All observed stat values enter comparison/refusal identities.
The historical `GetEmptyArmorScale` entry point returns this shared policy.
Full APR
profiles and Pawn scores retain their existing meaning. Any resolved Pawn
scorer, including zero armor valuation or a negative recommendation filter,
remains authoritative. An explicit pending Pawn choice blocks this policy.
No saved build or Pawn preference is changed, and unchanged refusals persist.

Automatic Pawn selection uses visible, class-compatible sources from
`PawnGetAllScalesEx`. A proven build/role remains a constraint. With no Forever
build, exactly one visible class scale can identify the source; multiple visible
builds never use a name/order tie-break. This matters because Pawn's normal
Forever class-wide setup can enable all three class scales. Auto mode with an
ambiguous source and explicitly selected APR both use the dominance
policy when no full APR profile exists; no complete profile is invented.

Quest gear selection uses the same proof before later appearance/vendor priorities.
`GetUpgrade` additionally exposes normalized raw stat gains as `plan.armorDelta`
for dominance comparisons. A reward must strictly dominate every other proven
upgrade in those gains to win; a sole proven upgrade wins without a competing
alternative. Equal gains and incomparable tradeoffs remain manual. Armor+Stamina
sorting points never rank quest choices. With no proof, later configured priorities
still apply; absent an explicit fallback, partial/unavailable scoring cannot claim
an arbitrary first reward. Earlier manual appearance priorities, profession gates,
pending explicit Pawn and bounded item-data retries retain their existing behavior.

`/apr gear` reports that a search started, or the disabled, combat, dead or
unavailable scoring state. A partial-policy scan with no proven improvement
reports unavailable comparison capability instead of claiming that no upgrade
exists. Only this explicit command prints feedback; automatic event scans stay
silent. Labels use existing translation keys; no translation key was added.

The public [Pawn source](https://github.com/VgerMods/Pawn/blob/main/Pawn.lua)
documents per-character `IsVisible` in `PawnGetAllScalesEx`, provider activity
filtering, and class-wide visibility in `PawnEnableAllScalesForClass`. No Pawn
weights or implementation were copied.

### Starter regression action log (2026-11-12)

- Read AGENTS.md, RTK.md, tests/README.md, UB Mode and its Windows-tool reference;
  verified clean base d5b98180 and kept the authorized checkout/branch.
- Traced the real Forever context through Pawn, APR defaults, bag scanning and
  the real slash command. No chosen build made GetDefaultScale return nil and
  StartScan exit without offering empty-slot armor.
- Added a synthetic level-three Paladin journey with armor-only boots, real
  modules and commands. Observed its intended red failure at the missing offer.
- Added the separate bag-only empty-armor scale and retained all native usability,
  uniqueness, bag readiness, combat and explicit-click execution guards.
- Added a negative-stamina case; observed its intended red failure, then rejected
  every negative or unreadable stat before applying conservative benefit scores.
- Covered explicit equip, removal/equipment events, persisted refusal, refreshed
  comparison, occupied/pending slots, stamina-only benefit, speculative SP,
  non-armor destinations, explicit zero-valued Pawn, pending Pawn, command
  feedback and silent automatic scans. The six focused suites passed.
- Checked API contracts with Context7 (GetItemStats, GetInventoryItemLink/ID)
  and public Blizzard UI source Mainline/Classic ItemDocumentation. Reused the
  existing C_Item/global adapter and native APIs; no protected-action mechanism
  or external addon source/table was imported.
- Ran crapper --no-coverage, dryer --threshold 0.8 and mutator --scan via the
  bundled Windows launcher for the three production files. All reported no
  supported source files: Lua remains unsupported. No CRAP or mutation score
  is claimed.
- Regenerated instrumentation only for the changed scorer/bag files and their
  manifest after the checker identified exactly those files. Preserved existing
  wrappers/IDs and formatting after generation to keep the diff scoped to new
  functions. The structural checker passes (3,475 functions in 126 files).
  UTF-8 writes used Python; libraries were not changed.
- Full required command `.venv/Scripts/python.exe tests/run.py`: **639 tests
  passed in 144.826 seconds**, outside the Windows sandbox with the already
  created `.venv/tmp-starter-gear` directory assigned to TEMP/TMP. Full output
  is in local `.venv/starter-gear-full.log`.
- A separate instrumentation run initially hit a sandbox temporary-directory
  permission error (12 other tests passed). The exact failing read-only fixture
  passed with workspace TEMP/TMP; the complete suite above also passed it.
- Final `git diff --check` passed. One dedicated local commit is authorized;
  no push. Native clicks/rendering, combat security and real client item-data
  timing remain manual checks; offline fixtures do not certify them.

Native Retail/Forever client verification remains required; simulated Lua APIs
do not certify live rendering, security restrictions or numerical optimality.
