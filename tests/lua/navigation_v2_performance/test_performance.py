"""Behavioral limits, independent of maintained route/terrain content."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


class NavigationPerformanceTests(unittest.TestCase):
    def test_contracts(self):
        for path in sorted(Path(__file__).parent.glob("*_test.lua")):
            with self.subTest(suite=path.name):
                LuaRuntime(unpack_returned_tuples=True).execute(
                    path.read_text(encoding="utf-8"), name="@" + path.as_posix())

    def test_witnesses_share_the_memory_ceiling(self):
        from tests.lua.navigation_v2_sectors.test_prepared import prepared
        edges = [edge for i in range(1, 20) for edge in ([i, i+1, 1], [i+1, i, 1])]
        lua, _, _ = prepared([[i, 0, 0] for i in range(20)], edges, node_limit=20)
        result = lua.execute(b'''
            planner=assert(ns.LibAPRNavigationV2.New(source,{
                clock=function()return 0 end,profileClock=function()return 0 end,limits={labels=4}}))
            return finish(plan(1,20))
        ''')
        self.assertEqual((result[b'status'], result[b'reason']), (b'budget_exceeded', b'label_limit'))
        self.assertIsNone(result[b'segments'])
        self.assertEqual(result[b'diagnostics'][b'witnessLabels'], 4)
        result = lua.execute(b'''
            planner=assert(ns.LibAPRNavigationV2.New(source,{
                clock=function()return 0 end,profileClock=function()return 0 end,limits={labels=64}}))
            return finish(plan(1,20))
        ''')
        self.assertEqual(result[b'status'], b'complete')
        self.assertEqual(result[b'estimatedSeconds'], 0.019)
        self.assertEqual(len(result[b'segments']), 19)

    def test_compiled_fixture_residency(self):
        from tests.lua.navigation_v2_sectors.test_export import exporter
        sectors, routing = exporter(), exporter('routing')
        nodes = [[i, 0, 0] for i in range(1024)]
        edges = [edge for i in range(1, 1024) for edge in ([i, i+1, 1], [i+1, i, 1])]
        parts = sectors.partition_graph(nodes, edges, sector_id='corridor', name='Corridor',
                                        complete=True, node_limit=128)
        bundle = sectors.build_catalog(parts['sectors'], parts['links'])
        bundle['routing'] = routing.prepare_routing(parts['sectors'], parts['links'])
        lua = LuaRuntime(encoding=None)
        lua.execute(b"collectgarbage('collect')")
        before = lua.eval(b"collectgarbage('count')")
        lua.globals().bundle = lua.execute(sectors.lua_catalog(bundle).encode())
        lua.execute(b"collectgarbage('collect')")
        retained = lua.eval(b"collectgarbage('count')") - before
        self.assertLess(retained, 192, '1024-node compiled fixture exceeded192KiB before any decoded cache')
