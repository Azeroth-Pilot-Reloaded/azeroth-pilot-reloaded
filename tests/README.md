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
