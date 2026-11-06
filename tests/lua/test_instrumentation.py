"""Coverage and Lua semantics for the generated whole-addon instrumentation."""
import unittest
import tempfile
from pathlib import Path
from unittest.mock import patch
from lupa.lua51 import LuaRuntime
from tools.validation.instrument_lua import ROOT, HEADER, BASE_HEADER, clean, equivalent, instrument, run


class InstrumentationTests(unittest.TestCase):
    def test_production_paths_with_debug_enabled(self):
        for name in ('current_step_render', 'quest_order_performance', 'arrow_visibility',
                     'arrow_action_text', 'arrow_action_settings', 'action_text_source',
                     'event_lifecycle', 'npc_interaction_chain', 'merchant_sales', 'party_group_sync', 'version_shared_channel',
                     'secret_compatibility', 'reputation_scheduling',
                     'step_progression', 'navigation_scheduling', 'navigation_unlock_routes',
                     'navigation_map_projection', 'navigation_projection_cache', 'route_path_performance',
                     'navigation_forever_performance', 'navigation_forever_projection',
                     'ui_foundations', 'route_panels_render', 'waypoint_integration'):
            with self.subTest(suite=name):
                runtime = LuaRuntime(unpack_returned_tuples=True)
                runtime.execute('function GetTime() return 0 end; function debugprofilestop() return 0 end')
                runtime.execute((ROOT / 'APR-Core/core/Diagnostics.lua').read_text(encoding='utf-8-sig'))
                runtime.execute('APRInstrumentation.enabled=true; APRInstrumentation.debug=true')
                runtime.execute((ROOT / f'tests/lua/{name}_test.lua').read_text(encoding='utf-8-sig'))

    def test_every_owned_function_is_instrumented(self):
        changed, coverage = run()
        self.assertEqual(changed, [], 'Run python tools/validation/instrument_lua.py --write')
        self.assertTrue(coverage, 'No owned Lua functions discovered')

    def test_formatting_and_body_edits_do_not_require_regeneration(self):
        generated, _, _ = instrument('local function read() return 7 end\nreturn read()\n', 'fixture.lua')
        edited = generated.replace('return 7', '-- A body edit shifts every later line.\nlocal value = 9\nreturn value')
        edited = edited.replace('function(_, fn) return fn end', 'function (_, fn)\n    return fn\nend')
        edited = edited.replace(';', '').replace('APRTrace(', 'APRTrace (\n')
        edited = edited.replace('"fixture.lua:', "'fixture.lua:").replace('#1"', "#1'")
        expected, names, _ = instrument(edited, 'fixture.lua')
        self.assertEqual(len(names), 1, 'The formatted header must not become an owned function')
        self.assertNotEqual(edited, expected, 'The fixture must have stale line hints/formatting')
        self.assertTrue(equivalent(edited, expected))
        runtime = LuaRuntime(unpack_returned_tuples=True)
        self.assertEqual(runtime.execute(edited), 9)

    def test_legacy_header_is_removed_after_formatting(self):
        source = 'local function read() return 3 end\n'
        generated, _, _ = instrument(source, 'fixture.lua')
        legacy = generated.replace(HEADER, BASE_HEADER)
        legacy = legacy.replace('function(_, fn) return fn end', 'function(_, fn)\n return fn\nend')
        self.assertEqual(clean(legacy), source)

    def test_formatter_can_move_markers_across_authored_tokens(self):
        formatted = HEADER + '''
local callbacks = {
    --[[APR_DIAG]]
    read = APRTrace("fixture.lua:10:callback#1", --[[/APR_DIAG]]
        function() return 7 end --[[APR_DIAG]]
    ) --[[/APR_DIAG]]
}
local read = callbacks.missing --[[APR_DIAG]]
    or APRTrace("fixture.lua:20:callback#2", --[[/APR_DIAG]]
        function() return callbacks.read() end --[[APR_DIAG]]
    ) --[[/APR_DIAG]]
return read()
'''
        restored = clean(formatted)
        self.assertIn('read = ', restored)
        self.assertIn('or ', restored)
        runtime = LuaRuntime(unpack_returned_tuples=True)
        self.assertEqual(runtime.execute(restored), 7)
        expected, names, _ = instrument(formatted, 'fixture.lua')
        self.assertEqual(len(names), 2)
        self.assertTrue(equivalent(formatted, expected))
        self.assertEqual(runtime.execute(expected), 7)

    def test_missing_or_incorrect_wrappers_still_fail(self):
        source = 'local function read() return 3 end\nlocal callback = function() return read() end\n'
        generated, _, _ = instrument(source, 'fixture.lua')
        cases = {
            'missing wrappers': HEADER + source,
            'new uninstrumented function': generated + 'local function added() return 4 end\n',
            'wrong binding': generated.replace(', read)', ', callback)'),
            'wrong source': generated.replace('"fixture.lua:', '"other.lua:'),
            'wrong function label': generated.replace(':read#', ':other#'),
        }
        for name, edited in cases.items():
            with self.subTest(case=name):
                self.assertFalse(equivalent(edited, instrument(edited, 'fixture.lua')[0]))

    def test_duplicate_callback_identifiers_still_fail(self):
        generated, names, _ = instrument('local first = function() end\nlocal second = function() end\n', 'fixture.lua')
        edited = generated.replace(names[1], names[0])
        self.assertFalse(equivalent(edited, instrument(edited, 'fixture.lua')[0]))

    def test_coroutine_and_protected_call_adapters_remain_required(self):
        source = 'local function work() pcall(error, "test"); coroutine.yield(3) end\ncoroutine.resume(work)\n'
        generated, _, _ = instrument(source, 'fixture.lua')
        for alias, original in (('APRPCall', 'pcall'), ('APRYield', 'coroutine.yield'), ('APRResume', 'coroutine.resume')):
            with self.subTest(alias=alias):
                # Leave the header intact, but remove an adapter at its call site.
                edited = generated.replace(alias + '--[=[', original + '--[=[')
                self.assertFalse(equivalent(edited, instrument(edited, 'fixture.lua')[0]))

    def test_repository_check_is_read_only_and_manifest_is_structural(self):
        with tempfile.TemporaryDirectory() as directory, patch('tools.validation.instrument_lua.ROOT', Path(directory)):
            root = Path(directory)
            source = root / 'APR-Core/core/Fixture.lua'
            source.parent.mkdir(parents=True)
            source.write_text('local function read() return 3 end\n', encoding='utf-8')
            self.assertEqual(run()[0], ['APR-Core/core/Fixture.lua', 'APR-Core/core/DiagnosticManifest.lua'])
            run(write=True)
            manifest = source.with_name('DiagnosticManifest.lua')
            manifest.write_text(manifest.read_text(encoding='utf-8').replace(' = ', '=\n').replace('"', "'"), encoding='utf-8')
            source.write_text(source.read_text(encoding='utf-8').replace('return 3', '\nreturn 5'), encoding='utf-8')
            before = {path: path.read_bytes() for path in (source, manifest)}
            self.assertEqual(run()[0], [])
            self.assertEqual(run(write=True)[0], [], 'Valid formatted files must not be rewritten')
            self.assertEqual({path: path.read_bytes() for path in before}, before)
            manifest.write_text(manifest.read_text(encoding='utf-8').replace('instrumented=\n1', 'instrumented=\n2'), encoding='utf-8')
            self.assertEqual(run()[0], ['APR-Core/core/DiagnosticManifest.lua'])
            self.assertEqual(source.read_bytes(), before[source])

    def test_generated_code_compiles(self):
        runtime = LuaRuntime(unpack_returned_tuples=True)
        compile_lua = runtime.eval('function(s,n) local f,e=loadstring(s,n); return e end')
        for root in ('APR-Core', 'Routes'):
            for path in (ROOT / root).rglob('*.lua'):
                if 'libs' not in path.parts:
                    with self.subTest(path=path):
                        self.assertIsNone(compile_lua(path.read_text(encoding='utf-8-sig'), '@' + path.as_posix()))

    def test_manifest_order_is_platform_independent(self):
        _, coverage = run()
        paths = [path for path, _, _ in coverage]
        self.assertEqual(paths, sorted(paths), 'Coverage must use case-sensitive POSIX ordering on Windows and Linux')

    def test_callbacks_recursion_comments_and_yields(self):
        source = '''
-- function fake() end
local text = [=[function ignored() end]=]
local function recurse(n)
    if n == 0 then return 1 end
    return n * recurse(n-1)
end
local object = {}
function object:read(value) return self, value, nil, false end
local callback = function() return recurse(5) end
local thread = coroutine.create(function()
    coroutine.yield(3)
    return callback()
end)
assert(select(2, coroutine.resume(thread)) == 3)
assert(select(2, coroutine.resume(thread)) == 120)
assert(select('#', object:read(7)) == 4)
return callback, object, text
'''
        generated, names, _ = instrument(source, 'fixture.lua')
        self.assertEqual(clean(generated), source)
        self.assertEqual(instrument(generated, 'fixture.lua')[0], generated)
        self.assertEqual(len(names), 4)
        runtime = LuaRuntime(unpack_returned_tuples=True)
        runtime.execute('APR={}; APRData={}; function GetTime() return 0 end; function debugprofilestop() return 0 end')
        runtime.execute((ROOT / 'APR-Core/core/Diagnostics.lua').read_text(encoding='utf-8'))
        runtime.execute('APRInstrumentation.enabled=true; APRInstrumentation.debug=true')
        callback, _, _ = runtime.execute(generated)
        self.assertEqual(callback(), 120)
        self.assertIsNone(runtime.eval('APRInstrumentation.CurrentName()'))


if __name__ == '__main__':
    unittest.main()
