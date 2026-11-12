# Quest reward fallback when no scoring profile is available

## Scope and decision

The quest consumer resolves the existing APR default scale before trying gear
comparisons. An absent scale is a known unavailable profile, not pending item
data. The consumer continues through the configured priorities, including manual
appearance decisions and vendor price. It does not invent a build or use the
bag-only conservative scoring policy.

Explicit Pawn choices remain authoritative: pending providers or unconfirmed
weights stop a requested gear priority. Available scorers still defer incomplete
item comparisons. Existing metadata/link checks, bounded retries, quest/context
cancellation and claim suppression remain in place.

Only the body of `SelectQuestReward` changes in production. No WoW/Pawn API
contract, client branch, UI, weights, SavedVariables or diagnostic definition
changes. Existing internal `GetDefaultScale` is reused on Retail and Forever
(interface 16001); synthetic integration cases exercise both client contexts.
Actual native interaction/security has not been tested in a running WoW client.

## Action log and evidence (2026-11-13)

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

No push is authorized. The commit includes only the quest consumer, its synthetic
reward tests and this journal; unrelated work remains in the checkout.
