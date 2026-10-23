"""Coverage and Lua semantics for the generated whole-addon instrumentation."""
import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime
from tools.validation.instrument_lua import ROOT, clean, instrument, run


class InstrumentationTests(unittest.TestCase):
    def test_production_paths_with_debug_enabled(self):
        for name in ('current_step_render', 'quest_order_performance', 'arrow_visibility',
                     'arrow_action_text', 'arrow_action_settings', 'action_text_source',
                     'event_lifecycle', 'npc_interaction_chain', 'party_group_sync', 'secret_compatibility', 'reputation_scheduling',
                     'step_progression', 'navigation_scheduling', 'route_path_performance',
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
        self.assertGreater(sum(count for _, count, _ in coverage), 2000)

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
