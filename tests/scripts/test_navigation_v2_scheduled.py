"""Synthetic scheduled-transport contracts, without a game client or V1."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


class ScheduledTransportTests(unittest.TestCase):
    def test_contracts(self):
        suites = sorted((Path(__file__).parents[1] / "lua/navigation_v2_scheduled").glob("*_test.lua"))
        self.assertTrue(suites, "No scheduled-transport contracts discovered")
        for path in suites:
            with self.subTest(suite=path.name):
                LuaRuntime(unpack_returned_tuples=True).execute(
                    path.read_text(encoding="utf-8"), name="@" + path.as_posix()
                )

    def test_scheduled_overlay_disables_stale_prepared_routes(self):
        from tests.lua.navigation_v2_sectors.test_prepared import prepared

        lua, _, _ = prepared(
            [[0, 0, 0]] * 3, [[1, 2, 60000], [2, 3, 60000], [1, 3, 100000]], node_limit=1
        )
        lua.execute(b'''
            local static = finish(plan(1, 3))
            assert(static.status == 'complete' and static.estimatedSeconds == 100)
            local fixture = dofile('tests/lua/navigation_v2_scheduled/fixture.lua')
            local route = fixture.Route()
            route.from,route.to,route.access = refs[2],refs[3],'available'
            route.costs = {approach=0,boarding=0,ride=1,loading=0,disembark=0,final=0}
            route.wait = {mode='known',seconds=0}
            local dynamic = assert(ns.LibAPRNavigationV2.New(source,{
                scheduled={route},clock=function()return 100 end,profileClock=options.profileClock}))
            local result = finish(dynamic:Plan({from=refs[1],to=refs[3]}))
            assert(result.status == 'complete' and result.optimal and result.estimatedSeconds == 61,
                'Static witness/potential100 must not hide the scheduled route61')
            assert(#result.segments == 2 and result.segments[2].kind == 'scheduled')
            assert(dynamic.preparation.compiled.stats.geometryLoads == 0,
                'Audited adjacency remains usable without loading terrain geometry')
            assert(dynamic.preparation.compiled.stats.edgesValidated > 0)
            assert(dynamic:SetScheduled({route},{[route.id]={ride=200}}))
            assert(not dynamic:IsCurrent(result))
            local changed = finish(dynamic:Plan({from=refs[1],to=refs[3]}))
            assert(changed.status == 'complete' and changed.estimatedSeconds == 100)
        ''')
