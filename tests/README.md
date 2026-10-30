# Tests

From the repository root, using Python 3.13+ and Node.js 24:

```sh
python -m pip install -r tests/requirements.txt
python tests/run.py
```

Run a single family with `--suite scripts`, `--suite lua` or `--suite routes`.
The standard `python -m unittest discover -s tests -t . -v` command works too.
All suites run even when one fails, and any failure produces a nonzero exit code.
Tests require no credentials, running WoW client, browser, or external API calls.

## Testing policy

Engine tests describe behavior using small synthetic inputs. Shipped routes and
navigation catalogs are editable content, not regression fixtures. Do not assert
that a named guide exists, has a fixed label/count, contains a particular quest,
boss order, coordinate or optional condition, or takes a particular world tour.
A valid rename, removed optional guard, or edited guide must not require changing
an engine test. Never copy a live guide or its expected quest list into a fixture.

Use two complementary layers:

- **Behavior:** synthetic routes, characters, items and transport graphs with
  independently chosen expected results. Cover both acceptance and rejection,
  boundaries, state changes, persistence and cancellation. Exact values and
  counts are useful here because the fixture controls them.
- **Content contracts:** discover all current declarations and apply the same
  schema/integrity checks to every entry. Check supported fields, value types,
  required references and internal consistency. Optional authoring choices stay
  optional; do not invent minimum content counts or per-guide exceptions.

For a reported route bug, identify the engine rule involved and reproduce it
with a minimal invented guide. For example, test that one ready reward can
activate an `AnyOf` group despite absent siblings; do not list a live guide's
reward IDs or require it to retain that particular group. If only authored
content changed, run the common route validator instead of adding a regression
that locks in the edit. API-specific item/spell identifiers are appropriate when
the identifier itself is the client contract being tested.

Tests never repair tracked sources. Generators and repair tools are exercised on
temporary fixtures; content validation only reports invalid input. Keep tests
deterministic and run the complete suite before finishing. Repository-wide agent
instructions are in [AGENTS.md](../AGENTS.md).

- `scripts/test_*.py`: TOC updates, localization notifications, package validation
  and PR report behavior against a mocked GitHub API. The latter uses Node.js.
- `lua/*_test.lua`: automatically discovered addon regression suites, each in its
  own Lua 5.1 runtime via `lupa.lua51`.
  `route_ui_test_env.lua` is shared test support, not an executable suite.
  `lua/test_reload_confirmation.py` checks reload call sites using Python file
  discovery, so the Lua runtime does not need `io.popen` or Git.
- `routes/test_syntax.py`: loads **every** `Routes/**/*.lua` file in an isolated
  Lua 5.1 environment, then validates every route with `route_schema.py`.
  Unknown options, constants, nested fields and invalid values fail the suite.
  One common test visits every declaration using subtests. Errors identify the
  file, route and field (Lua errors also include the line).
  Core files are compiled separately. Both client manifests must register all
  route files exactly once.
- `routes/test_schema.py`: valid/invalid examples of every option and condition,
  nested conditions, metadata, scenarios, prefabs and strict loader failures.
  Also checks that engine condition names and primary actions have schema rules.

All routes use the same validation rules, including Forever and Speedrun Alt.
`route_conditions_test.lua` tests predicates against synthetic player state;
`route_engine_test.lua` tests parallel insertion, prerequisites, aliases, scenario
transitions and temporary routes with synthetic guides. `native_route_actions_test.lua`
tests action handlers. `level_requirements_test.lua` covers bonus profiles and absolute XP.
The Forever compatibility command reuses the common route suite.

`route_prefab_test_env.lua` supplies invented guides for prefab ordering,
character eligibility, future chapters, popup scope and label/progress tests.
`reward_groups_test.lua` varies group size and checks readiness, level/zone
boundaries, fallback hand-ins and character/account separation.

Navigation behavior can pass a synthetic declaration to `navigation_fixture:Load`
to load the real library/adapter without any shipped data. The shortcut,
mandatory-chain, passage-lifecycle and action-selection suites use this path.
`navigation_unlock_test_catalog.lua` supplies an independent acquisition graph
with shared prerequisites, cycles, tracker progress and progressive activities;
the same graph exercises library and APR host lifecycles. The shortest-path oracle
also compares 200 generated graphs against exhaustive enumeration. Shipped
navigation data is checked separately for schema and catalog integrity across
client/faction/language combinations; no expected inventory counts are frozen.

`merchant_sales_test.lua` exercises both auto-vendor and `SellItems` with native
junk selling and the container fallback: large inventories, delayed/rejected
sales, locks, missing item data, equipped targets and cancelled retries. In game,
verify both paths with full bags on Retail and Forever, confirm native junk
selling opens no popup, and close the merchant during a sale to check cancellation.

`memory_recycling_test.lua` covers changing current steps and actions, repeated
combat transitions, image previews, route configuration lists and heirloom buttons.
Widget allocations stop after the reusable pools are warmed up; cached callbacks
are rebound to the current content.

`skill_api_test.lua` verifies structured `C_SkillInfo` results and prefers modern
APIs even when legacy globals exist. `navigation_catalog_profiles_test.lua` also loads Forever
with Retail's project ID and checks its pre-Cataclysm transport connections.
`secret_compatibility_test.lua` rejects opaque aura payloads and NPC/cast values;
its sentinels cannot reproduce the client's native secret-value or taint rules.

When adding an engine option, update `route_schema.py` and its positive/negative
examples. Route-level conditions only admit fields evaluated by `RouteManager`;
step/parallel conditions also support recursive `AnyOf`, `AllOf` and `Not`.
Legacy empty quest lists and unfinished scenario lists are valid declarations;
the schema does not impose quest ordering or require a guide to be complete.

Add Python tests as `test_*.py` or Lua suites as `*_test.lua`; no runner list needs
updating. Put new Python subdirectories under a package containing `__init__.py`.
The focused commands in `tools/validation/run_lua_tests.py` remain available. Detailed coverage and
in-game checks are documented in `tools/validation/README.md`.

Mocks validate addon behavior, not actual game rendering or API compatibility.
The `party_finder_*` suites use invented players and routes to cover private
discovery, multilingual policies, bounded queues/caches, timer cancellation,
native-invitation correlation, sound cooldowns and pooled companion rows. Verify
channel/whisper delivery, flags and secure invitation dialogs in the actual
Retail and Forever clients before releasing the feature.
`party_finder_world_test.lua` and `party_finder_load_test.lua` use controlled
memberships/populations to exercise all discovery filters on the single stable
`APR` channel. `communication_channel_test.lua` and
`version_shared_channel_integration_test.lua` exercise independent discovery and
version-check owners of that same membership. Startup is delayed by two seconds;
joining has one ten-second timeout. Map, instance and chat-lockdown transitions
retain membership, while traffic is suspended as needed. No channel permutation,
native-channel reset, chat-window modification or roster request is permitted.
Prejoined channels are not owned or left, and a manual leave requires an explicit
retry. Version queries/replies keep their prefix, persisted cache, suppression
and one bounded twelve-second startup retry; no `APRVersion` channel is joined.
Version ingress has its own sixty-four-packet per-second budget before any
version parsing or sender normalization. Profile/toggle changes immediately
release or reacquire that owner's reference without disturbing discovery.

All discovery searches have a sixty-second minimum interval. Automatic scans
yield after a recently observed query, including another zone's query; manual
searches are not starved by a busy channel. Each search accepts thirty results.
Cached channel counts admit a best-effort sample targeting twenty-four world
responses; unknown counts suppress world responses. Local matches are not
excluded by sampling against the entire channel population. Instead their
population-aware delays spread replies up to nine seconds, allowing early
completion/cancellation of crowded searches. Presence attempts are spaced by
five seconds across all filters, including offline/failed attempts.

Public discovery work is bounded before decoding to sixteen normal packets plus
four cancellation/withdrawal packets per second; private decoding is capped at
sixty-four. Queued discovery replies and queued direct messages each have a
thirty-two-entry bound. The shared fixture loads the actual embedded AceComm and
ChatThrottleLib. `party_finder_direct_test.lua` verifies native send results,
expiry/revocation at eventual dispatch, other addons' untouched traffic and
multipart rejection before AceComm can allocate a spool for APR's tiny packets.
The adapter explicitly checks the inspected AceComm14/CTL32 queue contracts;
unfamiliar contracts refuse private sends. Library files and Blizzard API
functions are never modified. Cancelled CTL records continue to count toward the
bound until CTL retires them, including after discovery is disabled/re-enabled.

Load fixtures include thousands of public/private messages, coalesced event
bursts, a small matching zone in a large population, and stale queued presence
after cancellation, hiding, disabling, policy/context changes, instance entry,
lockdown and expiry. These local budgets and best-effort sampling do not guarantee
a complete directory or eliminate network reception as population grows. In-game
checks must include both clients, mixed addon releases, native channel numbering,
different zones, server/faction reach, missing counts and chat restrictions. The
wire protocol remains compatible, but discovery peers must use the new shared
channel; this release does not join legacy channels as a bridge. Group version
checks continue to communicate with older APR releases.
UI tests use placeholder labels and do not validate localized wording or load
translation catalogs. Text assertions cover synthetic data and behavior only.
`settings_audio_test.lua` covers responsive sound-event cards and the real AceGUI
audio adapter with a synthetic 10,000-sound catalog: no catalog access when the
page opens, bounded visible rows, late registrations, callbacks and pooled release.
It also checks the shared-font adapter's current catalog and unprefixed saved names.
`font_media_test.lua` checks every declared text scope against synthetic shared
fonts, late registration, inheritance and missing-font resolution. Shared-media
registration tests discover bundled audio files and validate their registrations
and manifest order with the embedded library.
`ui_foundations_test.lua` covers indexed catalogs without dense rows or offsets,
including scrolling, source replacement and fallback to ordinary variable-height lists.
`party_finder_lifecycle_test.lua` covers invisible idle operation, temporary manual/automatic
search membership, refused sends, cancelled fingerprints, coalesced expiry and renewed invitation rows.
Protocol/invitation/UI fixtures also cover translated presentation, changed invitation nonces,
route context and combat-deferred disabling without persistent listeners.
`native_settings_test.lua` checks the restored Blizzard settings entry points;
`memory_recycling_test.lua` also covers route right-click/Shift-right-click and
disabled routes. `route_metadata_tooltip_test.lua` checks data-only attribution,
APR fallback, descriptions and recycled catalogue/custom-path tooltips.
`status_report_test.lua` checks the historical status, identity masking,
formatted Lua and selection preservation. `step_transitions_test.lua` checks
rollback undo and its normal previous-step fallback. `performance_dashboard_test.lua`
checks scaled graph hover, peak context, frozen timelines and bounded captures.
`tools/validation/check_package.py` still needs an unpacked release to validate a
real package; its automated tests use a minimal package fixture.

The `navigation_*` suites exercise directed travel, cumulative fare/reagent
budgets, access regions, transient guidance, quote changes, confirmed taxi
measurements, stale callbacks and shared preview geometry. Package validation
also checks that no retired navigation module is loaded.

`navigation_conditional_access_test.lua` uses a synthetic city and timelines to
cover required elevators, per-map restrictions, observer detours, unknown phase
evidence, event closure and initiative rotation. `navigation_conditional_adapter_test.lua`
checks native calendar argument order, viewed-month offsets, exact server-time
boundaries, unavailable responses and neighborhood identity without live APIs.

The navigation performance tests use controlled clocks and API-call counters to
check the 1 ms planning budget, cache invalidation and cancellation. They cover
catalogue preparation, taxi indexing, search ingestion and guidance publication.
Timing benchmarks are separate from regression assertions because wall-clock
results depend on the host, client APIs, garbage collection and scheduling.

`quest_cache_performance_test.lua` uses 150 synthetic objectives to check stable
record identities, zero unchanged layouts, percentage-only updates and shrinking
objective lists. `bank_refresh_performance_test.lua` checks burst coalescing,
close-time snapshots and stale/disabled callbacks. `quest_autocomplete_lifecycle_test.lua`
covers bounded retry chains, duplicate bursts, delayed native data and cancellation.
`route_cache_performance_test.lua` checks 1,000 warm reads without activation-key
sorting/formatting or scenario reconstruction, including in-place mutations,
same-length scenario changes and a missing scenario's bounded fallback cache.
`navigation_combat_events_performance_test.lua` covers Retail/Forever with native
unit registration and its fallback: combat bursts reuse the travel-action index,
while recalls, live item effects, catalogue extension/replacement, camp locations,
unlock observations and opaque payload rejection retain their behavior.
`diagnostic_value_performance_test.lua` counts sanitization input bytes for large
strings, including nested payloads, whitespace, pipe escaping and output boundaries.
The route-panel and idle-tracker suites also assert zero route scans while the
list is collapsed, cancellation of pending work, current-progress recovery and
no recurring appearance probes while the guide is hidden or detached.
`inventory_action_performance_test.lua` checks one fresh bag snapshot per action
label render, unknown/incomplete bank data, empty actions and future previews.
`loot_money_performance_test.lua` checks one price lookup per exact item variant
within an estimate, including late data and modern/legacy container APIs.
The AFK lifecycle suite also checks dormant hides and coalesced show/hide bursts.
`party_roster_performance_test.lua` covers frame-local roster reuse, native roster
notifications, realm identities and party/raid/reset transitions.
`party_finder_filter_performance_test.lua` checks compiled language policies over
200 synthetic candidates, bilingual/unknown cases, changed preferences and expiry.
`party_text_performance_test.lua` bounds scans of malformed link/art markup while
preserving labels, complete tags, colors, control filtering and text limits.
`route_suggestions_performance_test.lua` checks startup work in operation/time
slices, oversized quest fields, queued requests, deterministic choices,
cancellation, preferences and partial-index cleanup/recovery after errors.
`performance_rows_performance_test.lua` checks reusable viewer rows, independent
export snapshots and clean filtering/mode/reset transitions. The dashboard suite
also checks indexed publication and zero repeated row builds for stopped captures.
`temporary_route_cache_performance_test.lua` checks one reusable temporary-prefix
snapshot, parent/scenario edits, range and character changes, invalidation and
completion without repeated effective-route reconstruction.
`navigation_mount_performance_test.lua` checks candidate reuse across replans,
live ownership/usability, missing/opaque responses and Retail/Forever fallbacks.
`quest_order_dense_step_performance_test.lua` puts 300 objectives in one step and
charges synthetic API/font costs: model preparation, viewport binding and later
state/collapse updates remain budgeted. It covers partial-row visibility,
replacement, scrolling, cancellation, pooling and error recovery with capture on.
`release_notes_layout_performance_test.lua` checks coalesced font/resize callbacks,
hidden ancestors, stale requests, immediate content publication and reopening.
`diagnostic_coroutine_lifecycle_test.lua` uses Lua 5.1 weak observations and explicit
test-only collections to verify retired workers can be freed while owned suspended
workers still resume and completed timings remain available.
`gamepad_geometry_performance_test.lua` counts rectangle queries in nested scroll
frames and checks clipping, live movement/scaling, disabled controls and reveal.
`gamepad_action_membership_performance_test.lua` repeats 20,000 warm registrations
without registry scans or secure writes, then checks immediate reordering, action
kind changes and rejected/retried combat registration.
`changelog_parser_performance_test.lua` checks linear scan/copy work for malformed
links and whitespace-heavy headings, with independent formatting expectations.
`navigation_catalog_action_budget_test.lua` puts 500 alternatives in one invented
transport definition and covers per-alternative budgets, shared random selection,
missing observations, cancellation and the direct single-action path.
`navigation_resource_dominance_budget_test.lua` compares 500-resource arrivals
inside the search budget: equivalent/better/incomparable labels, relevant or
ignored future consumables, operation boundaries and suspended cancellation.
`party_snapshot_budget_performance_test.lua` bounds optional group-tooltip
construction before copying/sorting dense rows. It preserves progress, complete
ordinary exports, exact row/byte limits, all-or-nothing overflow and nil/empty
containers, including real serialization/send/receive.
`quest_objective_layout_batch_performance_test.lua` changes 100 main and 100
optional objectives through the real cache and widgets. Layout/action-text
publication is shared across the refresh, including nesting, error recovery,
deferred reads, an existing content owner and unchanged refreshes during combat.
`map_pin_lifecycle_performance_test.lua` advances 200 invented steps with bounded
world/minimap pin pools, then checks live tooltips/numbering, route replacement,
display limits, burst coalescing, direct refreshes, resize and disable/re-enable.
`route_prerequisite_graph_performance_test.lua` expands shared diamonds once per
declaration while retaining prerequisite order, cycles, missing routes, duplicate
labels, current character eligibility and a fresh traversal after errors.
`route_label_budget_performance_test.lua` resolves invented aliases and duplicate
labels without sorting, budgets completed-route lookups, and rejects imports,
renames or catalogue replacement during suspension before saved-state publication.
`test_route_hash_startup.py` checks historical signature bytes with LuaBitOp's
double-number normalization, cooperative hashing and atomic startup publication.
It covers cancellation, errors, replacement and explicit progress/reset choices.
Native level/scenario evidence stays observable; NPC/taxi actions wait, visible
NPC pages reconcile afterward, and duplicate completion receipts advance once.
`test_route_validation_toggle.py` calls the real settings toggle during suspended
validation, then checks resumption, preserved reset/clear intentions and stale
callbacks without re-registering gameplay events.
It also executes the real instrumented startup worker with debug/performance
capture enabled and checks coroutine-stack release and one completed timing.
Escort confirmations recheck validation, route context, enabled settings and
modifiers when their delayed callback runs.
Event lifecycle tests also cover native/fallback player filters and foreign addon
traffic; the XP overlay fixture checks zero unchanged UI writes and dormant
inactive/combat scheduling with an independent invented bonus source.

`addon_quest_journey_test.lua` connects the real event dispatcher, suggestion
index, route conditions, quest cache, renderer and step transitions through an
invented quest chain. `test_addon_journey_quest.py` adds real suggestion-popup
actions and CurrentStep/FillersFrame widgets: conditional parallel insertion,
optional-objective removal, missing native data and cancelled/resumed signature
validation with one native completion. Neither fixture loads a shipped guide.
`group_instance_journey_test.lua` composes real Party/Finder/World/Invites, codecs,
core events and temporary-route lifecycles on Retail/Forever: private/world
search, invitation/roster, party/instance channels, raid/scenario/delve transitions,
early/complete exit, reload, missing maps and parent/custom-path restoration.
`navigation_journey_integration_test.lua` uses the real controller, adapter,
planner, taxi and library on both profiles. It joins access changes, wrong worlds,
movement, geometry invalidation, event bursts, manual boarding, portals, combat,
teleport/loading, consumed cooldowns, death, cancellation and temporary detours.
These journeys supplement the smaller behavior/boundary suites; native APIs and
widgets remain simulated and do not certify actual client security or rendering.

`navigation_search_action_performance_test.lua` covers personal teleports from
a separate world, cooldowns no future leg can consume, shared reagents, later-map
actions and 160 independently enumerated feasible-path oracles. Operation counts
bound the dense fixture without requiring a particular machine speed.

`navigation_travel_time_test.lua` drives APR's real controller, planner and a
synthetic transport catalogue. It compares a long approach to a physical portal
with a personal spell or item, then changes distance, movement speed and action
availability. Cast, loading and arrival costs decide the winner; ordinary travel
must not stop at an access-only physical itinerary.

`navigation_controller_lifecycle_test.lua` also retains full synthetic trips
across expected spell, item and portal arrivals. It tests missing loading data,
consumed cooldowns, repeated native world-event retries, arrival/event ordering,
stale candidates and final completion without another provider build. Wrong
worlds, maps, access keys, floors, altitude, distance, changed objectives and
closed future gates must still trigger fresh planning.
Loading coverage interleaves native world events with quest/bag updates and
partially refreshed map/world positions, including events before the world
handler and arrivals after the cast timeout. A bounded settling window must
not keep an unconfirmed crossing forever. The adapter/controller integration
uses real geography checks; report snapshots expose the continuation decision
and controller revision without serializing its private queue or graph.
Native departure/loading-screen coverage holds a published route through a
90-second loading interval, in both return-event orders, while position/action
and death observations are unavailable. It rejects stale candidate publication
and retains explicit skip, clear and disable semantics. House-list updates
cancel unrelated background candidates without clearing non-housing guidance;
published housing actions retain their stricter invalidation tests.
`navigation_travel_time_test.lua` also reproduces a city teleport whose native
map temporarily reports the parent continent. It uses the real adapter,
geography and controller, retains the queue/cursor with zero provider rebuilds,
and checks refinement to the city after geometry refresh. An ancestor map is
accepted only with matching world/coordinates and proven walking access. Wrong
continents, sibling maps, floors, private access and isolated interiors cannot
use that fallback; interiors still require their native arrival evidence.
Housing recovery in the same synthetic controller test asserts that a usable
native return appears with zero catalogue/taxi/search preparation, even for a
visitor with no recorded return point. Repeated neighborhood geometry events
keep that instruction. Local housing objectives and unavailable/unknown return
actions use normal routing. An action-only escape cannot masquerade as a free
complete journey; actual outside-world arrival resumes the authored objective
without advancing its quest cursor.

On both Retail and Forever, manually verify a flight with a connection, a boat
or zeppelin, a secure travel button, death/resurrection and reload during
guidance. Check the 2,000-yard threshold (10,000 with usable Retail skyriding),
restricted entries including Silvermoon/Harandar, and Forever ground crossings.
Finish a quest during travel, then use skip/back/undo and confirm authored route
progress remains correct. Check five waypoints followed by a pickup: six line
segments remain visible regardless of the next-marker limit, including map
changes and rotating minimap. Confirm labels use the client's language in at
least French and English. These checks need the actual clients and are not
certified by simulated WoW APIs.

## Pull requests

`PR Tests` runs the three test families on opening, reopening, marking ready for
review, and every subsequent push (`synchronize`). Draft PRs skip all test jobs;
conversion back to draft cancels a pending run. Each new push cancels the previous
run for that PR. Counts and outcomes appear in the Actions job summaries.

`PR Test Report` updates one bot comment with each family's status, the tested
commit, and links to the logs and counts, even when tests fail. It ignores closed,
draft, unrelated and outdated PR results. It uses `workflow_run` to support fork
PRs without giving PR code a writable token. The reporting job executes no PR
code and consumes no artifacts.

The report workflow must be merged into the repository's default branch before
GitHub triggers it. See [GitHub's workflow_run documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run).
