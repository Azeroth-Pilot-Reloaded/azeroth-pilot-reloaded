# Quest reward fallback when no scoring profile is available

## Scope and decision

The quest consumer resolves the existing APR default scale before trying gear
comparisons. On supported Forever characters without a build it can also reuse
the armor-dominance proof shared with bag suggestions. A sole proven upgrade wins;
multiple upgrades can be compared by normalized whole-equipment stat gains.
Only a reward strictly dominating every alternative wins; ties/tradeoffs remain
manual. With no proof, later configured appearance/price priorities still apply.
No build or conversion rates between different statistics are invented.

Explicit Pawn choices remain authoritative: pending providers or unconfirmed
weights stop a requested gear priority. Available scorers still defer incomplete
item comparisons. Existing metadata/link checks, bounded retries, quest/context
cancellation and claim suppression remain in place.

Production behavior changes in `SelectQuestReward` and the existing shared scorer,
which exposes the proof's stat gains as `plan.armorDelta`. No WoW/Pawn API
contract, client branch, UI, weights, SavedVariables or diagnostic definition
changes. Existing internal `GetDefaultScale` is reused on Retail and Forever
(interface 16001); synthetic integration cases exercise both client contexts.
Actual native interaction/security has not been tested in a running WoW client.

## First-fix action log and evidence (2026-11-13)

1. Recorded initial HEAD `d4500e397dc54dcc492ed1bb73fdfcba2705caad` and status.
   Existing PartyFinder, RouteManager, DiagnosticManifest, configuration and
   associated test edits belong to other work and are excluded from this fix.
2. Read repository guidance, RTK, test policy, UB Mode and Windows launcher
   instructions; inspected the supplied diagnostic as evidence. Reproduced the
   repeated retry mechanism rather than modifying any route from its trace.
3. Extended the real NPC/Pawn/RewardScoring integration fixture with an invented
   level-three Forever character without a build and multiple class Pawn scales.
   Before the fix the focused suite failed at
   `An unavailable build must allow the configured price fallback in apr`.
4. Resolved APR scale availability inside the existing gear-priority branch and
   skipped comparisons when no scale exists. Kept the Pawn pending gate first.
5. The focused reward-selection, Pawn and scoring suites passed (3 tests).
   Additional no-build coverage passes for APR/auto/Pawn-absent price selection,
   appearance/manual priority, delayed metadata recovery, cancelled quest retries,
   bounded explicit-Pawn pending and available Pawn scoring against a different
   vendor-price winner. Existing tests cover quantity, eligibility, delayed
   scoring, changed weights, options, professions and stale callbacks.
6. Ran bundled UB `crapper --no-coverage`, `dryer --threshold 0.8` and
   `mutator --scan` on NPCInteraction.lua. They reported no source files to
   analyze/mutate: Lua is unsupported. This provides no CRAP score, duplication
   assessment or mutation score; behavioral tests are the executable evidence.
7. Created `.venv/reward-test-tmp` and launched the full repository suite outside
   the sandbox with TEMP/TMP pointing to that existing directory, for Windows
   asyncio socket tests. Full suite passed: **658 tests in 150.449 seconds**,
   zero failures/errors, exit 0; includes the final reward regression fixture.
   Local output: `.venv/reward-test-results.log` (untracked runtime evidence).
8. `git diff --check` passed. Reviewed the minimal production diff and preserved
   all diagnostic wrappers/IDs. The dedicated journal is explicitly force-added
   because the repository ignores `docs/*`; no ignore policy changes are needed.
   Commit paths are explicit to exclude any unrelated staged work. Verified the
   final commit file list and remaining foreign edits after committing.

The first fix committed only the quest consumer, its synthetic reward tests and
this journal, leaving unrelated work in the checkout. No push is authorized.

## Follow-up: conservative quest gear proof (2026-11-13)

- Initial HEAD: `75c18529ab79d5c14cfb6725bc9ee421098e7098`; checkout clean.
  Re-read repository, test, RTK and UB Windows guidance. Prior external changes
  are now committed and are outside this follow-up.
- The new diagnostic contains a single selection/default-scale evaluation and no
  retry calls. That is consistent with a manual appearance-priority exit, not an
  exception or another item-loading retry loop. Native `GetQuestReward` is not
  instrumented: its absence from the report alone cannot prove it was not called.
- Red test using real NPC/Pawn/context/scoring modules, level-three Forever,
  Default APR/auto and three visible class Pawn providers: a non-upgrade wrist
  reward and proven belt improvement returned `choice=nil, ready=true` instead
  of choosing the belt before manual transmog. These are controlled synthetic
  cases, not assertions about the screenshot's unobserved equipment/stats.
- Reused `GetEmptyArmorScale` after an unavailable full APR profile, behind the
  explicit Pawn pending gate. No bag weights or armor-proof algorithm was copied.
  Extended the existing proof result with normalized gain vectors in the returned
  plan so different reward slots can be compared without guessed weights.
- Additional red cases exposed arbitrary first-item fallback with gear-only
  preferences and a need to compare two proven improvements. Corrected those
  cases: no proof/no explicit fallback stays manual; strictly dominating gains
  win, equal/incomparable gains stay manual. Synthetic empty-wrist coverage does
  not assume that the screenshot's wrist slot was occupied.
- Focused reward/Pawn/scorer/starter-bag/dominance suites pass (5 tests), including
  negative stats, losses in other stats, unsupported weapons, prior manual
  appearance/profession gates, pending Pawn, late stats/usability and stale quests.
- Context7 resolution found no matching Pawn library. Reviewed the public
  [Pawn source](https://github.com/VgerMods/Pawn/blob/main/Pawn.lua#L3999-L4037):
  the armor-type filter is not a sufficient explanation for a missing low-level
  cloth upgrade arrow. No new Pawn/native API, transmog filter or equipment-type
  rule was added; runtime client contracts remain the existing Retail/16001 paths.
- Bundled UB crapper, dryer (threshold 0.8) and mutator scan ran on both changed
  production Lua files; Lua is unsupported, so no complexity, duplication or
  mutation score is claimed. Full-suite results and commit verification follow.
- User subsequently confirmed the wrist slot was occupied. The reproduction
  models that mechanism with independently invented stats; the screenshot's
  exact worn/reward stat values remain unobserved. Empty wrists are also covered.
- Added bounded `APR:Debug` messages on existing quest-selection/claim paths.
  Selection reports index/readiness/source/reason and choice count; a separate
  message records the native claim attempt. Manual transmog, incomparable gear,
  pending Pawn/data and a refused/repeated claim are now distinguishable in
  future captures. No new diagnostic definitions, private item data or timers.
  The selector's first two return values are unchanged; extra reason/source
  values are diagnostic metadata. A red diagnostic-contract test preceded this
  addition; focused tests now verify both decision and claim messages.
- Final required `.venv/Scripts/python.exe tests/run.py` passed **658 tests in
  157.067 seconds**, exit 0, with pre-created `.venv/reward-test-tmp` assigned to
  TEMP/TMP outside the Windows sandbox. Local output is
  `.venv/reward-dominance-results.log`. Earlier full runs before the final
  diagnostic addition also passed (658 tests in 140.947 and 137.685 seconds).
- Final `git diff --check` passes. The follow-up commit is explicitly restricted
  to NPCInteraction.lua, RewardScoring.lua, the synthetic quest reward suite,
  readme/reward-profiles.md and this journal. All existing wrappers/IDs are
  preserved; no manifest regeneration, dependency edit or push is required.
- Limits: simulated native APIs verify the decision, bounded retry and unique
  claim attempt. Native refusal, actual worn-item values and the real client's
  resulting quest completion still require an in-game check. Future captures
  now show which decision/claim state was reached, rather than inferring it from
  an uninstrumented native function.
