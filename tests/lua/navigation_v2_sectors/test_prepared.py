"""Prepared routing uses the actual factory/search, without decoding geometry."""
import unittest
import random
import base64
import zlib

from .test_export import exporter
from tests.lua.navigation_v2_terrain.test_data import runtime
from tests.lua.navigation_v2_terrain.codec_support import decode


def prepared(nodes, edges, *, landmarks=2, node_limit=2, edit_parts=None, edit_atlas=None,
             identity=None, complete=True, enabled=True):
    sectors, routing = exporter(), exporter('routing')
    parts = sectors.partition_graph(nodes, edges, sector_id='garden', name='Garden paths',
                                    complete=complete, node_limit=node_limit)
    if edit_parts:
        edit_parts(parts)
    data = sectors.build_catalog(parts['sectors'], parts['links'])
    atlas = routing.prepare_routing(parts['sectors'], parts['links'], landmarks=landmarks)
    if edit_atlas:
        # Deliberate fault injection after the mandatory producer audit, not a
        # valid import path (real imports must call verify_routing again).
        edit_atlas(atlas, parts)
    lua = runtime()
    lua.globals().bundle = lua.execute(sectors.lua_catalog(data).encode())
    lua.globals().atlas = lua.execute(sectors.lua_catalog(atlas).encode())
    lua.globals().refs = lua.execute(sectors.lua_catalog([
        '%s:terrain:%s' % tuple(pair) for pair in parts['node_map']]).encode())
    lua.globals().expectedIdentity = identity.encode() if identity else None
    lua.globals().complete = complete
    lua.globals().enabled = enabled
    lua.execute(b'''
        testTime={cpu=0,tick=0,wall=0}
        options.profileClock=function()local n=testTime.cpu;testTime.cpu=n+testTime.tick;return n end
        local deserialize=options.deserialize
        options.deserialize=function(s)
            if testTime.cancelOnDecode and activeJob then activeJob:Cancel();return nil end
            return deserialize(s)
        end
        options.routing=enabled and atlas or nil
        options.routingIdentity=expectedIdentity or atlas.identity
        options.complete=complete
        local geometry=enabled and setmetatable({}, {__index=function()error('Geometry decoded')end}) or bundle.catalog
        source,createReason=ns.LibAPRNavigationV2.NewSectorGraph(bundle.index,geometry,options)
        if source then planner,createReason=ns.LibAPRNavigationV2.New(source,{
            clock=function()return testTime.wall end,profileClock=options.profileClock}) end
        function plan(a,b,via)
            local points={}
            for _,v in ipairs(via or {})do points[#points+1]=refs[v] end
            activeJob=planner:Plan({from=refs[a],to=refs[b],via=points})
            return activeJob
        end
        function finish(job,operations)
            for i=1,100000 do
                local result=job:Step(operations or 3)
                if result.status~='running' then return result end
            end
            error('job did not terminate')
        end
    ''')
    return lua, parts, atlas


def shortest(count, edges, start, goal, via=()):
    """Exhaustive independent simple-state relaxation, including mandatory state."""
    import heapq
    distance, queue = {}, [(0, start, 0)]
    while queue:
        cost, node, passed = heapq.heappop(queue)
        while passed < len(via) and node == via[passed]:
            passed += 1
        key = node, passed
        if cost >= distance.get(key, float('inf')):
            continue
        distance[key] = cost
        if node == goal and passed == len(via):
            return cost
        for a, b, weight in edges:
            if a == node:
                heapq.heappush(queue, (cost + weight, b, passed))


def modify_access(parts, a, b, access):
    source, target = parts['node_map'][a - 1], parts['node_map'][b - 1]
    for link in parts['links']:
        if link['from'] == source and link['to'] == target:
            link['access'] = access


def change_witness(atlas, parts, node, transform):
    sector, local = parts['node_map'][node - 1]
    blocks = atlas['sectors'][sector]['witnessBlocks'][0][1]
    block = blocks[(local - 1) // atlas['witnessRowsPerBlock']]
    raw = decode(zlib.decompress(base64.b64decode(block['payload']), -15))
    transform(raw[2][local - raw[1]])
    encoded = exporter('routing').cbor(raw)
    compressor = zlib.compressobj(9, zlib.DEFLATED, -15)
    block['payload'] = base64.b64encode(compressor.compress(encoded) + compressor.flush()).decode()
    block['rawBytes'] = len(encoded)


class PreparedRoutingRuntimeTests(unittest.TestCase):
    def test_search_compares_integer_ledger_before_seconds_rounding(self):
        lua=runtime()
        result=lua.execute(b'''
            -- Controlled prepared-engine interface, separate from the UINT32
            -- per-wire-edge contract: exercise safe-integer accumulation.
            local long=9007199254740002
            local graph={partitioned=true,integerCosts=true,complete=true}
            local rows={s={{id='long',from='s',to='t',milliseconds=long,seconds=long/1000},
                {id='via',from='s',to='m',milliseconds=long-100,seconds=(long-100)/1000}},
                m={{id='last',from='m',to='t',milliseconds=99,seconds=.099}},t={}}
            function graph:Locate(id)return id end
            function graph:Ensure()return {} end
            function graph:Estimate()return 0 end
            function graph:ReadEdge(_,node,cursor)return rows[node][cursor] end
            local search=ns.NavigationV2Search.New(graph,{from='s',to='t',via={}},{expanded=0,relaxed=0})
            for i=1,100 do
                local status=search:Advance()
                if status=='complete' then return search.segments end
            end
            error('synthetic integer ledger did not terminate')
        ''')
        self.assertEqual(len(result),2)
        self.assertEqual(result[1][b'edgeId'],b'via')

    def test_non_landmark_endpoints_certificate_and_search_fallback(self):
        edges = [[1, 2, 1], [2, 3, 10], [3, 4, 10], [4, 5, 1], [5, 1, 1]]
        lua, parts, atlas = prepared([[0, 0, 0]] * 5, edges, node_limit=1)
        reverse = {tuple(pair): i for i, pair in enumerate(parts['node_map'], 1)}
        roots = {reverse[atlas['names'][s - 1], n] for s, n in atlas['landmarkNodes']}
        self.assertNotIn(2, roots)
        self.assertNotIn(4, roots)
        result = lua.globals().finish(lua.globals().plan(2, 4))
        self.assertEqual(result[b'estimatedSeconds'], .020)
        self.assertTrue(result[b'diagnostics'][b'certificateComplete'])
        # Neither landmark lies on this cheap connection; existence of a more
        # expensive witness is insufficient, so the ordinary engine must search.
        edges = [[1, 2, 10], [1, 3, 10], [2, 3, 1], [2, 6, 100], [3, 6, 100]]
        lua, parts, atlas = prepared([[0, 0, 0]] * 6, edges, node_limit=1)
        result = lua.globals().finish(lua.globals().plan(2, 3))
        self.assertEqual(result[b'estimatedSeconds'], .001)
        self.assertFalse(result[b'diagnostics'][b'certificateComplete'])
        self.assertGreater(result[b'diagnostics'][b'expanded'], 0)

    def test_directed_parallel_zero_cycles_and_via_match_independent_oracle(self):
        rng = random.Random(710)
        for case in range(24):
            count = rng.randint(4, 8)
            edges = [[a, b, rng.randint(0, 8)] for a in range(1, count + 1)
                     for b in range(1, count + 1) if rng.random() < .28]
            if edges:
                edges.append(list(edges[0]))
            lua, _, _ = prepared([[0, 0, 0]] * count, edges, landmarks=case % 4, node_limit=2)
            for a, b, via in ((1, count, ()), (2, count - 1, ()), (count, 1, (2,))):
                with self.subTest(case=case, source=a, target=b, via=via):
                    result = lua.globals().finish(lua.globals().plan(a, b, lua.table_from(via)))
                    expected = shortest(count, edges, a, b, via)
                    self.assertEqual(result[b'status'], b'no_path' if expected is None else b'complete')
                    if expected is not None:
                        self.assertEqual(result[b'estimatedSeconds'], expected / 1000)
                    if via:
                        self.assertFalse(result[b'diagnostics'][b'certificateComplete'])

    def test_unknown_or_unavailable_witness_never_overrides_known_route(self):
        edges = [[1, 2, 1], [2, 4, 1], [1, 3, 5], [3, 4, 5]]
        for access in ('unknown', 'unavailable'):
            lua, _, _ = prepared([[0, 0, 0]] * 4, edges, node_limit=1,
                                  edit_parts=lambda p: modify_access(p, 2, 4, access))
            result = lua.globals().finish(lua.globals().plan(1, 4))
            self.assertEqual(result[b'estimatedSeconds'], .010)
            self.assertEqual(result[b'diagnostics'][b'certificateRejected'], b'witness_unavailable')
        for access, status in (('unknown', b'unknown'), ('unavailable', b'no_path')):
            lua, _, _ = prepared([[0, 0, 0]] * 3, [[1, 2, 1], [2, 3, 1]], node_limit=1,
                                  edit_parts=lambda p: modify_access(p, 2, 3, access))
            result = lua.globals().finish(lua.globals().plan(1, 3))
            self.assertEqual(result[b'status'], status)
            self.assertIsNone(result[b'segments'])

    def test_more_expensive_and_zero_cycle_witnesses_fall_back(self):
        nodes = [[0, 0, 0]] * 4
        edges = [[1, 2, 1], [2, 4, 1], [1, 3, 5], [3, 4, 5], [4, 4, 0]]
        def wrong(atlas, parts):
            sector, node = parts['node_map'][2]
            link = next(i for i, link in enumerate(exporter().build_catalog(parts['sectors'], parts['links'])['index'][sector]['links'], 1)
                        if link['to'] == parts['node_map'][3][1] and link['sector'] == parts['node_map'][3][0])
            change_witness(atlas, parts, 4, lambda row: row.__setitem__(slice(None), [atlas['ordinals'][sector], node, 5, 0, -link]))
        lua, _, _ = prepared(nodes, edges, node_limit=1, edit_atlas=wrong)
        result = lua.globals().finish(lua.globals().plan(1, 4))
        self.assertEqual(result[b'estimatedSeconds'], .002)
        self.assertEqual(result[b'diagnostics'][b'certificateRejected'], b'witness_cost_mismatch')
        def cycle(atlas, parts):
            sector, local = parts['node_map'][3]
            change_witness(atlas, parts, 4, lambda row: row.__setitem__(slice(None), [atlas['ordinals'][sector], local, 0, 0, 1]))
        lua, _, _ = prepared(nodes, edges, node_limit=1, edit_atlas=cycle)
        result = lua.globals().finish(lua.globals().plan(1, 4))
        self.assertEqual(result[b'estimatedSeconds'], .002)
        self.assertEqual(result[b'diagnostics'][b'certificateRejected'], b'witness_cycle')

    def test_identity_changes_and_explicit_disabling(self):
        nodes, edges = [[0, 0, 0]] * 3, [[1, 2, 10], [2, 3, 10], [1, 3, 100]]
        _, _, old = prepared(nodes, edges)
        edges[-1][-1] = 1
        lua, _, new = prepared(nodes, edges, identity=old['identity'])
        self.assertNotEqual(old['identity'], new['identity'])
        self.assertIsNone(lua.globals().source)
        self.assertEqual(lua.globals().createReason, b'routing_identity_mismatch')
        lua, _, _ = prepared(nodes, edges, enabled=False)
        result = lua.globals().finish(lua.globals().plan(1, 3))
        self.assertEqual(result[b'estimatedSeconds'], .001)

    def test_cancel_stale_budgets_and_reconstruction_are_resumable(self):
        lua, _, _ = prepared([[0, 0, 0]] * 12, [[i, i + 1, 1] for i in range(1, 12)], node_limit=3)
        lua.execute(b'''
            local j=plan(1,12)
            for i=1,100 do
                j:Step(1)
                if j.search and j.search.loading then break end
            end
            local pending=j.search.loading.job
            assert(j:Cancel().status=='cancelled' and pending.cancelled)
            assert(j:Step().status=='cancelled')
            j=plan(1,12);j:Step(1);planner:Invalidate();assert(j:Step().status=='stale')
            j=plan(1,12)
            for i=1,1000 do j:Step(1);if j.search and j.search.build then break end end
            assert(j.search and j.search.build)
            assert(j:Step(1).status=='running' and j:Cancel().status=='cancelled')
            assert(finish(plan(1,12)).estimatedSeconds==.011)
            j=plan(1,12);testTime.wall=5;assert(j:Step().reason=='elapsed_budget')
            testTime.wall=0
            j=plan(1,12);testTime.tick=100
            local r=j:Step(1);assert(r.status=='budget_exceeded' and r.reason=='cpu_budget')
            local n=planner.preparation.compiled.stats.nativeDecodes
            assert(j:Step()==r and planner.preparation.compiled.stats.nativeDecodes==n)
        ''')
        lua, _, _ = prepared([[0, 0, 0]] * 3, [[1, 2, 1], [2, 3, 1]])
        lua.execute(b'''
            testTime.cancelOnDecode=true
            local j=plan(1,3)
            assert(finish(j).status=='cancelled')
            testTime.cancelOnDecode=false
            assert(finish(plan(1,3)).estimatedSeconds==.002)
        ''')

    def test_missing_data_and_malformed_values_are_not_disconnection(self):
        nodes, edges = [[0, 0, 0]] * 3, [[1, 2, 1], [2, 3, 1]]
        def missing_route(atlas, parts):
            atlas['sectors'][parts['node_map'][0][0]]['blocks'] = []
        lua, _, _ = prepared(nodes, edges, landmarks=0, edit_atlas=missing_route)
        result = lua.globals().finish(lua.globals().plan(1, 3))
        self.assertEqual(result[b'status'], b'unknown')
        self.assertEqual(result[b'reason'], b'routing_block_absent')
        self.assertIsNone(result[b'segments'])
        def missing_witness(atlas, parts):
            atlas['sectors'][parts['node_map'][2][0]]['witnessBlocks'] = []
        lua, _, _ = prepared(nodes, edges, edit_atlas=missing_witness)
        result = lua.globals().finish(lua.globals().plan(1, 3))
        self.assertEqual(result[b'estimatedSeconds'], .002)
        self.assertEqual(result[b'diagnostics'][b'certificateRejected'], b'routing_block_absent')
        lua, _, _ = prepared(nodes, edges, node_limit=3)
        lua.execute(b'planner.preparation.compiled.options.deserialize=function()return {1,1,{false,{},{}}}end')
        result = lua.globals().finish(lua.globals().plan(1, 1))
        self.assertEqual(result[b'status'], b'invalid')
        self.assertEqual(result[b'reason'], b'invalid_routing_row')
        lua, _, _ = prepared(nodes, [], complete=False)
        self.assertEqual(lua.globals().finish(lua.globals().plan(1, 3))[b'status'], b'unknown')

    def test_interleaved_queries_cache_bounds_and_deferred_decode(self):
        lua, _, _ = prepared([[0, 0, 0]] * 20, [[i, i + 1, 1] for i in range(1, 20)], node_limit=3)
        lua.execute(b'''
            local graph=planner.preparation.compiled
            assert(graph.stats.nativeDecodes==0)
            local a,b=plan(1,20),plan(2,19,{10})
            assert(graph.stats.nativeDecodes==0,'Plan does not decode pages')
            for i=1,10000 do
                local x,y=a:Step(1),b:Step(2)
                assert(graph.stats.residentRows<=graph.maxRows)
                assert(graph.stats.potentialRows<=1024 and graph.stats.witnessRows<=1024)
                if x.status~='running' and y.status~='running' then
                    assert(x.status=='complete' and y.status=='complete')
                    assert(x.estimatedSeconds==.019 and y.estimatedSeconds==.017)
                    break
                end
            end
            assert(a:GetResult().status=='complete' and b:GetResult().status=='complete')
            graph.atlas.sectors.unrelated=setmetatable({}, {__index=function()error('World scan')end})
            local s=assert(ns.LibAPRNavigationV2.NewSectorGraph(bundle.index,bundle.catalog,options))
            local p=assert(ns.LibAPRNavigationV2.New(s,{clock=function()return 0 end,profileClock=options.profileClock}))
            local job=p:Plan({from=refs[1],to=refs[20]})
            assert(p.preparation.compiled.stats.nativeDecodes==0)
            assert(finish(job).estimatedSeconds==.019)
        ''')
    def test_prepared_rows_reuse_search_without_geometry(self):
        sectors = exporter()
        routing = exporter('routing')
        parts = sectors.partition_graph([[0, 0, 0]] * 6,
            [[1, 2, 3], [1, 2, 8], [2, 3, 0], [3, 2, 0], [3, 4, 5], [4, 5, 7], [5, 6, 2]],
            sector_id='garden', name='Garden paths', complete=True, node_limit=2)
        data = sectors.build_catalog(parts['sectors'], parts['links'])
        atlas = routing.prepare_routing(parts['sectors'], parts['links'], rows_per_block=1)
        lua = runtime()
        self.assertIsNotNone(lua.globals().ns[b'NavigationV2Routing'], 'Shipping XML loads prepared routing')
        lua.globals().bundle = lua.execute(sectors.lua_catalog(data).encode())
        lua.globals().atlas = lua.execute(sectors.lua_catalog(atlas).encode())
        lua.globals().origin = ('%s:terrain:%s' % tuple(parts['node_map'][0])).encode()
        lua.globals().destination = ('%s:terrain:%s' % tuple(parts['node_map'][-1])).encode()
        result = lua.execute(b'''
            options.routing=atlas
            options.routingIdentity=atlas.identity
            options.complete=true
            local geometry=setmetatable({}, {__index=function()error('Geometry must not be read by routing')end})
            local source=assert(ns.LibAPRNavigationV2.NewSectorGraph(bundle.index,geometry,options))
            local p=assert(ns.LibAPRNavigationV2.New(source,{clock=function()return 0 end,
                profileClock=options.profileClock}))
            assert(p.preparation.compiled.routing)
            local job=p:Plan({from=origin,to=destination})
            for i=1,1000 do
                local r=job:Step(3)
                if r.status~='running' then
                    assert(p.preparation.compiled.stats.residentRows<=p.preparation.compiled.maxRows)
                    assert(p.preparation.compiled.stats.edgesValidated>0)
                    return r
                end
            end
            error('prepared route did not terminate')
        ''')
        self.assertEqual(result[b'status'], b'complete')
        self.assertAlmostEqual(result[b'estimatedSeconds'], .017)
        self.assertEqual(len(result[b'segments']), 5)
