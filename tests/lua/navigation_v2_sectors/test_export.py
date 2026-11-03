"""Actual CBOR/Deflate/Base64 exporter -> Lua planner, with an independent oracle."""
import heapq
import importlib.util
from pathlib import Path
import random
import sys
import unittest

from tests.lua.navigation_v2_terrain.test_data import runtime


ROOT = Path(__file__).resolve().parents[3]


def exporter(module_name='sectors'):
    root = ROOT.parent / 'Route-generator'
    if not root.is_dir():
        raise unittest.SkipTest('Separate Route-generator checkout is not present')
    sys.path.insert(0, str(root))
    try:
        spec = importlib.util.spec_from_file_location(
            'tools.navigation_v2.nav07_export_' + module_name, root / ('tools/navigation_v2/' + module_name + '.py'))
        # Relative compact import uses the actual project-owned V2 module.
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        sys.path.remove(str(root))


def minimum_cost(edges, start, goal):
    """Independent heap search on fixture declarations, never on Lua output."""
    queue, best = [(0, start)], {start: 0}
    while queue:
        cost, node = heapq.heappop(queue)
        if cost != best[node]:
            continue
        if node == goal:
            return cost / 1000
        for origin, target, weight in edges:
            candidate = cost + weight
            if origin == node and candidate < best.get(target, float('inf')):
                best[target] = candidate
                heapq.heappush(queue, (candidate, target))


class SectorExportRoundTrip(unittest.TestCase):
    def test_new_partition_matches_directed_original_graph_oracle(self):
        module = exporter()
        rng = random.Random(708)
        for case in range(24):
            nodes = [[0, 0, 0] for _ in range(rng.randint(5, 18))]
            edges = [[a, b, rng.randint(0, 20) * 1000] for a in range(1, len(nodes) + 1)
                     for b in range(1, len(nodes) + 1) if rng.random() < .17]
            parts = module.partition_graph(nodes, edges, sector_id='orchard', name='Orchard paths',
                                           complete=True, node_limit=3, block_nodes=2)
            lua = runtime()
            lua.globals().exported = lua.execute(module.lua_catalog(module.build_catalog(
                parts['sectors'], parts['links'], block_nodes=2)).encode())
            source_sector, source_node = parts['node_map'][0]
            target_sector, target_node = parts['node_map'][-1]
            lua.globals().origin = f'{source_sector}:terrain:{source_node}'.encode()
            lua.globals().destination = f'{target_sector}:terrain:{target_node}'.encode()
            result = lua.execute(b'''
                options.complete=true
                options.cacheSize=1
                local source=assert(ns.LibAPRNavigationV2.NewSectorGraph(exported.index,exported.catalog,options))
                local p=assert(ns.LibAPRNavigationV2.New(source,{clock=function()return 0 end,
                    profileClock=options.profileClock,budgets={cpuMs=1000}}))
                local job=p:Plan({from=origin,to=destination})
                for i=1,10000 do
                    local r=job:Step(3)
                    if r.status~='running' then return r end
                end
                error('partitioned graph did not terminate')
            ''')
            expected = minimum_cost(edges, 1, len(nodes))
            with self.subTest(case=case):
                self.assertEqual(result[b'status'], b'no_path' if expected is None else b'complete')
                self.assertEqual(result[b'estimatedSeconds'], expected)

    def test_random_small_directed_graphs_match_independent_cost_oracle(self):
        module = exporter()
        rng = random.Random(707)
        for case in range(36):
            sectors = {name: {'name': label, 'complete': True,
                             'nodes': [[0, 0, 0], [7000, 0, 0]], 'edges': []}
                       for name, label in (('garden', 'Garden path'), ('market', 'Market square'),
                                           ('river', 'River bank'))}
            nodes = [(name, node) for name in sectors for node in (1, 2)]
            links, oracle_edges = [], []
            for i, origin in enumerate(nodes):
                for j, target in enumerate(nodes):
                    if i == j or rng.random() > .23:
                        continue
                    weight = rng.randint(0, 12) * 1000
                    oracle_edges.append((origin, target, weight))
                    if origin[0] == target[0]:
                        sectors[origin[0]]['edges'].append([origin[1], target[1], weight])
                    else:
                        links.append({'id': f'passage-{i}-{j}', 'name': 'Surveyed passage',
                                      'from': list(origin), 'to': list(target), 'milliseconds': weight})
            expected = minimum_cost(oracle_edges, nodes[0], nodes[-1])
            lua = runtime()
            lua.eval(b'function(s) assert(loadstring(s))("test",ns) end')(
                (ROOT / 'APR-Core/libs/LibAPRNavigation-2.0/Data/Sectors.lua').read_bytes())
            lua.globals().exported = lua.execute(module.lua_catalog(module.build_catalog(sectors, links)).encode())
            result = lua.execute(b'''
                local source=assert(ns.NavigationV2Sectors.Source(exported.index,exported.catalog,{
                    profileClock=options.profileClock,decodeBase64=options.decodeBase64,
                    inflate=options.inflate,deserialize=options.deserialize,complete=true,cacheSize=1}))
                local p=assert(ns.LibAPRNavigationV2.New(source,{clock=function()return 0 end,
                    profileClock=options.profileClock,budgets={cpuMs=1000}}))
                local j=p:Plan({from='garden:terrain:1',to='river:terrain:2'})
                for i=1,10000 do
                    local r=j:Step(7)
                    assert(p.preparation.compiled.stats.resident<=1)
                    if r.status~='running' then return r end
                end
                error('round trip did not terminate')
            ''')
            with self.subTest(case=case):
                if expected is None:
                    self.assertEqual(result[b'status'], b'no_path')
                    self.assertIsNone(result[b'segments'])
                else:
                    self.assertEqual(result[b'status'], b'complete')
                    self.assertEqual(result[b'estimatedSeconds'], expected)
                    path_cost = sum(segment[b'seconds'] for segment in result[b'segments'].values())
                    self.assertEqual(path_cost, expected)

    def test_human_names_survive_utf8_lua51_and_control_escaping(self):
        module = exporter()
        labels = ['Vallée des rêves', 'Gate "east"\\north\n7', '门口']
        lua = runtime()
        result = lua.execute(module.lua_catalog({'labels': labels}).encode('utf-8'))
        self.assertEqual(list(result[b'labels'].values()), [label.encode() for label in labels])
