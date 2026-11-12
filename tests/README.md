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

Offline addon tests use synthetic localization labels. Do not snapshot companion
translation catalogs or assert their current keys, wording or cross-locale coverage.
Current translation exports are validated by the dedicated translation CI workflow.

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

Instrumentation checks compare Lua structure rather than exact generated text.
Formatting, comments, body edits and shifted trace line hints do not invalidate
coverage. Synthetic cases still reject missing/wrong wrappers, duplicate trace
identifiers, missing call adapters and incorrect manifest counts. They also cover
formatters moving diagnostic marker comments across authored table fields/operators.

`reward_scoring_test.lua` uses invented item variants and equipped configurations
for weighted gains, usability, unique-equipped categories and weapon replacement.
`pawn_rewards_test.lua` models the public Pawn API, scale mutations, explicit
choices, deferred offers and stale callbacks. Its scorer contract returns a scorer,
source state (`apr`, `pawn`, or `pending`) and a stable decision identity. Missing
selected providers retain their choice across reloads, and changed weights wait
for confirmation; bag offers pin that identity through scanning and acceptance.
All combinations of automatic quest rewards and character bag suggestions cover
weight confirmations, consumer opt-outs, combat deferral and stale callbacks.
`pawn_options_refresh_test.lua` uses the embedded AceConfig renderer with a custom host to check live settings
updates and cancellation. `quest_reward_selection_test.lua`
checks the real NPC selection lifecycle with controlled scores, priorities and
bounded item-data retries. `settings_select_test.lua` exercises the real APR
select through its AceGUI adapter, including value keys, ordering and pooled release.
None loads or freezes a shipped guide or Pawn's weights.

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
  Standalone steps containing only conditions and metadata are rejected: filters
  select an instruction but cannot render or complete a step on their own. The
  same rule covers ordinary, parallel and scenario steps.
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
`speedrun_prefab_test.lua` invokes the real browser button with invented Forever
graphs. It checks ranked successor selection with fallback from dead ends,
strict character/spec/quest predicates, future entry levels, prerequisite gates,
completed/partial progress, cyclic or incomplete chains, atomic refusal and the
unchanged Retail builder. Forever Speedrun metadata ranks successors by `index`;
`endLevel` explicitly declares an authored terminal milestone. Recommended
`levelRange` remains display-only and cannot certify a complete plan. These
priorities describe the authored fast path, not measured completion times.
`route_character_recommendations_test.lua` covers manual Forever entry with race
and class advice, live warnings and confirmation, strict factions/starters/Mage
AoE, nested predicates, localized label fallbacks and unchanged step filters.
`APR.PREFAB_TYPES.StartingZone` identifies all starters, including specialized
variants and hidden internal chapters. Manual Forever selection can waive their
race entry filter, with a live warning, when the declaration proves one matching
faction; class/spec, quest and level gates remain strict. Missing, neutral or
ambiguous factions retain race. Presets and automatic suggestions retain the
authored starting races, including when the player visits another starting map.
`starting_zone_prefab_scope_test.lua` checks that the default Forever starting
preset only queues ordinary routes, while AoE starts remain available through
their explicit leveling scope and hidden chapters are never queued automatically.
Presets and automatic suggestions retain the authored character recommendations,
while manual non-starter selection can waive them.
`forever_starting_races_test.lua` checks the shared entry projection, nested
faction proof and negations, unchanged action/parallel filters and Retail policy,
manual choice, natural automatic roots despite another starting map, complete
Leveling/Speedrun/dungeon branches, explicit AoE scope, reload, prerequisites and
atomic refusal after a class/faction change. Every guide in this fixture is invented.
`starter_race_advice_test.lua` checks matching and mismatching single/multiple
starting races, Skyborne, manual warnings, strict automatic race selection,
factions and specialized starter access.
`leveling_entry_advice_test.lua` checks manual entry below level 10 for ordinary
Forever leveling chapters, live warnings and unchanged automatic/action filters.
Starter, class and Mage AoE access retain their existing boundaries. Nested
`AnyOf`/`AllOf`/`Not` conditions retain faction and quest gates; levels beneath
`Not` remain strict so advice cannot change the meaning of a negated predicate.

`leveling_prefab_test.lua` drives the real Leveling button and stale popup
callbacks with synthetic characters and routes. It covers fractional/open
level boundaries, native Retail scaling and its missing/irrelevant-map fallback,
authored limits, future chapters, branch alternatives, bounded dead ends,
prerequisites, completion, variant choices and resuming starters at their entry
level. Availability and construction use the same read-only plan; refusal leaves
the existing path and progress intact. Forever uses authored conditions through
60 without querying Retail scaling. Ordinary Forever chapters explicitly declare
their Leveling participation independently of Speedrun's completion contract.

`prefab_buttons_test.lua` keeps catalogue support separate from current
availability: supported prefab buttons remain visible at the level cap, before
entry and after class/progress changes, with live enabled states and stable
layout. Unsupported client content stays hidden; stale callbacks retain the
existing path and progress.

`quest_log_suggestions_test.lua` covers the explicit journal search with synthetic
routes: access and level prefilters, bounded slices, unique quest counts, local
priority, objective entry instead of pickup, restart, cancellation, empty results
and stale selections. `quest_log_prefab_test.lua` drives its real browser button.
In both supported clients, also check native dialog wrapping, cancellation during
a long search and route activation from each entry choice; offline widgets cannot
certify rendering or actual frame times.

Popup layering is checked by the shared confirmation and selection suites, plus
the release-note, invitation and enlarged-image flows. Native shared frames must
return to their original strata on hide, including after repeated styling; APR
questions, messages, mandatory actions and copy dialogs render above the DIALOG
workspace. Check overlap in both clients with the workspace focused and raised.

Explicit Forever additions lazily store `APRData[player].RouteChoices[label]` to
preserve variants with shared labels. Existing paths need no migration: absent,
invalid or deleted choices use the usual resolver, which prefers a recommended
variant for legacy Forever labels. Declared label aliases migrate saved choices.
`route_label_migration_test.lua` covers ambiguous old titles, distinct new
variants, unqueued explicit choices, future chapters, completion, favorites and
unchanged progress/temporary-route keys. Historical completion receipts remain
available; `APRData[player].RouteCompletionMigrations` lazily records consumed
aliases so a later reset is not undone on the next login. No existing saved
tables or legacy entries are removed.
`route_level_column_test.lua` uses invented ranges/maps for numeric ascending and
descending sorts, unknown/open ranges, search aliases, per-build native-query
budgets, missing data, client isolation, recycled rows and narrow table geometry.
The common declaration schema validates optional `levelRange` bounds on every
discovered route. Level metadata is presentation only: signature golden tests
and the shared-definition fingerprint suite verify it cannot invalidate progress
or group compatibility.

Retail applies 10–70 to other leveling routes, 70–80 to The War Within and
80–90 to Midnight, narrowed by authored route requirements. Native map scaling
cannot replace those requested bands. Specialized introductions display valid
`C_Map.GetMapLevels` observations, refined by route-level conditions.
Observations refresh when the catalog is rebuilt, including after a
timeline change. Exile's Reach declares its documented 1–10 range. The shared
starting preset also includes hero/allied-race introductions and returning-player
tutorials: these use native/explicit levels, remaining unknown if none are available.
Explicit conditions can narrow these bounds. A city used for an introduction
cannot truncate its expansion's band to a single level. Blizzard's native
map-label code uses this API across the supported Retail versions, including
[11.2.7](https://github.com/Gethe/wow-ui-source/blob/11.2.7/Interface/AddOns/Blizzard_SharedMapDataProviders/AreaLabelDataProvider.lua)
and [12.1.5](https://github.com/Gethe/wow-ui-source/blob/12.1.5/Interface/AddOns/Blizzard_SharedMapDataProviders/AreaLabelDataProvider.lua).
The [new-player path](https://worldofwarcraft.blizzard.com/news/24266319/new-players-starter-guide-welcome-to-world-of-warcraft)
and [Midnight leveling announcement](https://worldofwarcraft.blizzard.com/en-us/news/24223575/watch-the-gamescom-2025-systems-download-panel-vod)
support TWW/Midnight's expansion bands. The 10–70 display for other Retail routes
is the requested selection policy, independent of current Chromie scaling. Forever
uses authored recommendations and conditions without querying Retail map levels.
In both real clients, check the level header, sorting, tooltips, favorite/path
retention after reload, narrow viewports and French/English labels; on Retail,
also compare the column before and after changing timelines. Mock widgets cannot
certify native font clipping, scaling data or actual client rendering.

`next_route_suggestions_test.lua` covers explicit leveling/dungeon continuations
on both clients, including level/XP boundaries, conditional branches, completion,
prerequisites and popup callbacks. Unlisted routes never become implicit successors.
`reward_groups_test.lua` varies group size and checks readiness, level/zone
boundaries, fallback hand-ins and character/account separation.

Navigation behavior can pass a synthetic declaration to `navigation_fixture:Load`
to load the real library/adapter without any shipped data. The shortcut,
mandatory-chain, passage-lifecycle and action-selection suites use this path.
`navigation_standalone_geography_test.lua` covers local Zone/Micro/Orphan maps
with no parent or a World/Cosmic parent on both profiles, including descendants,
separate islands/interiors, missing ancestry recovery and stable arrow guidance
through quest-log replanning.
`navigation_orphan_override_test.lua` checks verified outdoor map-type overrides
with invented cities and a parent-map portal on both profiles. It covers full
planner publication and preserves unverified Orphan, interior and world boundaries.
`navigation_unmapped_area_test.lua` covers verified world interiors without a
native UI map or projection: local quests, coordinate-free instructions,
mandatory exits, missing observations and recovery on both profiles. Authored
tram journeys retain their step at the departure platform and through loading;
only the destination radius advances to the next quest, once.
`navigation_instance_position_test.lua` uses invented mapless interiors and
restricted instances on both profiles: real exit planning, local/exterior
objectives, public instance identity without coordinates, stable work while
restricted, loading and recovery. It never treats an entrance landing as the
player's position. `arrow_visibility_test.lua` also rejects stale arrows during
that restriction.
The same instance-position cases cover party, raid, scenario, battleground and
arena types on Retail and Forever, plus an invented non-outdoor type to reject
a closed whitelist. Each case checks local/exterior objectives, formatted exit
names, stable work and recovery. `instance_travel_text_test.lua` checks entry
and exit templates for dungeon, raid, delve and scenario actions on both clients.
`navigation_transport_labels_test.lua` uses invented stops and cities to check
shared-interior travel labels in both directions, authored/library consistency,
world and radius boundaries, conflicting stops and late client names.
`navigation_unlock_test_catalog.lua` supplies an independent acquisition graph
with shared prerequisites, cycles, tracker progress and progressive activities;
the same graph exercises library and APR host lifecycles. The shortest-path oracle
also compares 200 generated graphs against exhaustive enumeration. Shipped
navigation data is checked separately for schema and catalog integrity across
client/faction/language combinations; no expected inventory counts are frozen.
`navigation_bind_candidates_test.lua` uses invented inns to verify localized
area IDs, legacy numeric keys, budgeted lookup, ambiguous destinations and learned
binds. The catalogue integrity suite validates every shipped bind position.

`merchant_sales_test.lua` exercises both auto-vendor and `SellItems` with native
junk selling and the container fallback: large inventories, delayed/rejected
sales, locks, missing item data, equipped targets and cancelled retries. In game,
verify both paths with full bags on Retail and Forever, confirm native junk
selling opens no popup, and close the merchant during a sale to check cancellation.
The route-sale opt-out also covers manual completion, equipped targets, stopping
retries and independence from ordinary auto-vendor on both merchant API paths.
In game, toggle route selling in Automation during a sale on Retail and Forever;
already submitted requests can finish, but no further sale should be requested.

`merchant_supplies_test.lua` uses invented items to check that supply opt-in only
controls automatic requests: instructions remain visible, manual partial/full
purchases complete correctly, carried stock and receipts prevent duplicate buys,
and mixed quest/supply lists retain their independent policies on both merchant
API variants. `merchant_supply_settings_test.lua` checks the disabled profile
default, Automation visibility and immediate opt-in at an open merchant. In game,
verify manual buying and skipping with the option off, then toggle it during a
partial purchase on Retail and Forever; quest purchases must remain automatic.

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
version-check owners of that same membership. Startup waits for the player to be
in the world, then gives native channels five seconds to settle; loading-screen
completion restarts that grace period. Slow login/reload fixtures retain the
native /1 and /2 slots, including retries, cancellation and missing readiness APIs.
Empty native lists, or gaps at /1 or /2 before a later channel, defer membership
without polling. Gaps after /2 are allowed, including when a community retains
a high channel number; joining must preserve every existing channel number.
After loading, a confirmed public zero from `GetChannelName(1)` permits one
`C_ChatInfo.ResetDefaultZoneChannels()` attempt per loaded UI session. Any channel
already occupying /1 vetoes that repair. Combat, chat restrictions, missing APIs
and unknown/opaque slot data defer it; native errors never cause a reset loop.
Native events (plus one coalesced read after a successful reset) resume joining
when the list is complete. An attempted join has one ten-second timeout. Map,
instance and chat-lockdown transitions retain membership while traffic is
suspended as needed. Channel permutations, chat-window modifications and roster
requests remain forbidden; only the explicitly guarded default-channel reset
is permitted.
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
`party_group_sync_test.lua` also checks world-entry handshakes without a roster
event, a receiver becoming ready after the first exchange, request cooldowns,
unchanged progress, current group channels and cancellation without idle traffic.
Regional-name fixtures also cover Forever surnames in roster, wire and display
identities, legacy first-name payloads, namesakes and unchanged SavedVariables keys.
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
`navigation_startup_requests_test.lua` exposes the same optional namespaces on
synthetic Retail, Forever and unsupported clients. Login, reload and house events
must not request unsupported/disabled initiatives or a calendar unused by the
catalogue; enabled Retail initiatives and required holiday refreshes still work.

The navigation performance tests use controlled clocks and API-call counters to
check the 1 ms planning budget, cache invalidation and cancellation. They cover
catalogue preparation, taxi indexing, search ingestion and guidance publication.
Timing benchmarks are separate from regression assertions because wall-clock
results depend on the host, client APIs, garbage collection and scheduling.
`navigation_controller_performance_test.lua` checks live-observation counts around
long-running jobs, bounded scheduling at high FPS, shared coordinate validation,
and rejection of changes made by providers or telemetry before publication.
`navigation_search_materialization_test.lua` checks that discarded transports
are not copied and selected segments remain independent of catalogue inputs.
`navigation_deferred_instructions_test.lua` checks selected/blocked labels (including zone entrances),
custom instruction keys, eager API compatibility, cancellation and bounded
publication work on synthetic Retail/Forever graphs.

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
`bank_transfer_test.lua` drives real route actions and bank/inventory events on
synthetic Retail, Forever and legacy containers. It covers reagent-bag receipts,
partial/full transfers, purchased personal tabs, separate keyring/account storage,
explicit deposits, late events, unavailable data, overlapping interactions and closure.
In both current clients, verify a withdrawal into the reagent bag and an explicit
deposit while an account-bank tab is selected; neither may reverse direction or
use account storage. Check a partial transfer with nearly full bags and close the
bank during a transfer. Native access, inventory timing and security require the
actual clients and are not certified by these fixtures.
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
Its real `UpdateStep` continuation case runs 25 then five passes: the cache batch
cannot publish intermediate geometry, and the final content commit retires demands.
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

`arrow_position_test.lua` checks UIParent coordinate round-trips at non-unit UI
scales, off-screen/invalid saved anchors, artwork bounds, display changes and
layout preview save/cancel behavior with synthetic geometry. It also checks
independent native identities, profile-owned persistence and artwork reattachment
after a legacy cached anchor. Scroll visibility checks include rounded native
anchor reads; release-note layout checks include widths resolved only after showing.
On Retail and
Forever, also check dragging, reload, the layout editor and a resolution/UI-scale
change in the actual client; simulated frames do not certify native rendering.

`screen_resize_bounds_test.lua` checks screen-sized resize limits in frame units,
including inherited scaling, stricter caller bounds, small or unavailable displays,
oversized restored frames, reopening and deferred updates after combat. Native
size notifications also cover height/width changes after initialization, synchronous
callback reentrancy, external window decorations and off-screen anchor recovery.

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
