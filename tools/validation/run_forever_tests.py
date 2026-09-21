"""Run the focused Forever checks without unrelated Midnight test prerequisites."""
from pathlib import Path
import os
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]
TESTS = (
    'farstrider_data_test.lua',
    'taxi_discovery_test.lua',
    'forever_travel_test.lua',
    'client_compatibility_test.lua', 'xp_requirements_test.lua',
    'reputation_progress_test.lua', 'route_resource_filters_test.lua',
    'route_action_usage_test.lua', 'forever_native_actions_test.lua',
    'area_navigation_test.lua', 'forever_routes_test.lua', 'step_progression_test.lua',
)

def main():
    os.chdir(ROOT)
    compiler = LuaRuntime().eval('function(source, name) local f, e = loadstring(source, name); return f ~= nil, e end')
    files = sorted((ROOT / 'APR-Core').rglob('*.lua')) + sorted((ROOT / 'Routes/Forever').glob('*.lua'))
    for path in files:
        ok, error = compiler(path.read_text(encoding='utf-8-sig'), str(path.relative_to(ROOT)))
        assert ok, error
    print(f'Lua 5.1 syntax: {len(files)} files passed', flush=True)
    for name in TESTS:
        runtime = LuaRuntime(unpack_returned_tuples=True)
        runtime.execute((ROOT / 'tools/validation' / name).read_text(encoding='utf-8'))
    print(f'Forever: {len(TESTS)} focused Lua suites passed', flush=True)

if __name__ == '__main__':
    main()
