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

- `scripts/test_*.py`: TOC updates, localization notifications, package validation
  and PR report behavior against a mocked GitHub API. The latter uses Node.js.
- `lua/*_test.lua`: automatically discovered addon regression suites, each in its
  own Lua 5.1 runtime via `lupa.lua51`.
  `route_ui_test_env.lua` is shared test support, not an executable suite.
- `routes/test_syntax.py`: loads **every** `Routes/**/*.lua` file in an isolated
  Lua 5.1 environment, then validates every route with `route_schema.py`.
  Unknown options, constants, nested fields and invalid values fail the suite.
  Errors identify the file, route and field (Lua errors also include the line).
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
`tools/validation/check_package.py` still needs an unpacked release to validate a
real package; its automated tests use a minimal package fixture.

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
