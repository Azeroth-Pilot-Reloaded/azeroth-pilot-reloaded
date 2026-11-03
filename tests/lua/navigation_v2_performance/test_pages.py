"""Flat storage through real loaders/XML/jobs; invented packets only."""
import base64
import importlib.util
from pathlib import Path
import sys
import unittest
import random
from unittest.mock import patch

from tests.lua.navigation_v2_sectors.test_export import exporter
from tests.lua.navigation_v2_terrain.test_data import runtime


def cross_reader():
    path = Path(__file__).resolve().parents[3].parent/'Route-generator/tests/navigation_v2/test_pages.py'
    spec = importlib.util.spec_from_file_location('flat_pages_cross_reader',path)
    module = importlib.util.module_from_spec(spec)
    with patch.dict(sys.modules, {'tools.navigation_v2.pages': exporter('pages')}):
        spec.loader.exec_module(module)
    return module.decode_cbor


def lua_value(value):
    if isinstance(value,str): return value.encode('utf-8')
    if isinstance(value,list): return [lua_value(v) for v in value]
    if isinstance(value,dict): return {lua_value(k):lua_value(v) for k,v in value.items()}
    return value


def fixture(*, routing=True, nodes=6, node_limit=2, edges=None, unknown=None):
    sectors, compiler = exporter(), exporter('pages')
    # Three cheap forward steps beat the direct edge; reverse direction absent.
    edges = edges if edges is not None else [[i,i+1,100] for i in range(1,nodes)] + [[1,nodes,900]]
    parts = sectors.partition_graph([[i,0,0] for i in range(nodes)],edges,
                                    sector_id='garden',name='Jardin d’été 日本',
                                    node_limit=node_limit,complete=True)
    if unknown:
        from tests.lua.navigation_v2_sectors.test_prepared import modify_access
        modify_access(parts,*unknown,'unknown')
    bundle = sectors.build_catalog(parts['sectors'],parts['links'])
    if routing:
        bundle['routing'] = exporter('routing').prepare_routing(parts['sectors'],parts['links'])
        bundle['routingIdentity'] = bundle['routing']['identity']
    pack = compiler.compile_pages(bundle)
    lua = runtime()
    decode = cross_reader()
    lua.globals().py_cbor = lambda raw: lua.table_from(lua_value(decode(raw)),recursive=True)
    lua.globals().pack = lua.execute(sectors.lua_catalog(pack).encode())
    refs = ['%s:terrain:%s'%tuple(pair) for pair in parts['node_map']]
    lua.globals().refs = lua.table_from([r.encode() for r in refs])
    lua.execute(b'''
        testTime={cpu=0,tick=0,wall=0};decodeCalls=0
        options.clock=function()return testTime.wall end
        options.profileClock=function()return testTime.cpu end
        local decode=options.deserialize
        options.deserialize=function(s)
            decodeCalls=decodeCalls+1;testTime.cpu=testTime.cpu+testTime.tick
            if cancelOnDecode and activeJob then activeJob:Cancel() end
            if failOnDecode then return nil end
            return decode(s)
        end
        options.routing=pack.routing or nil;options.routingIdentity=pack.routingIdentity
        options.complete=true
        source,why=ns.LibAPRNavigationV2.NewSectorGraph(pack.bootstrap,pack,options)
        assert(source,why)
        planner=assert(ns.LibAPRNavigationV2.New(source,{
            clock=options.clock,profileClock=options.profileClock}))
        assert(decodeCalls==0,'factory decoded metadata')
        function plan(a,b)
            activeJob=planner:Plan({from=refs[a],to=refs[b]})
            return activeJob
        end
        function finish(job)
            for i=1,100000 do
                local r=job:Step(1)
                if r.status~='running' then return r end
            end
            error('job did not terminate')
        end
    ''')
    return lua,pack,bundle


class FlatRuntimeTests(unittest.TestCase):
    def test_flat_prepared_and_geometry_keep_independent_optimum(self):
        for prepared in (True,False):
            with self.subTest(prepared=prepared):
                lua,_,_ = fixture(routing=prepared)
                job = lua.globals().plan(1,6)
                self.assertEqual(lua.globals().decodeCalls,0)
                result = lua.globals().finish(job)
                self.assertEqual(result[b'status'],b'complete')
                self.assertEqual(result[b'estimatedSeconds'],0.5)
                self.assertEqual(len(result[b'segments']),5)
                self.assertGreater(lua.globals().decodeCalls,0)
                if prepared:
                    self.assertTrue(result[b'diagnostics'][b'certificateComplete'])
                reverse = lua.globals().finish(lua.globals().plan(6,1))
                self.assertEqual(reverse[b'status'],b'no_path')

    def test_cancel_during_metadata_and_budget_do_not_restart(self):
        lua,_,_ = fixture()
        result = lua.execute(b'cancelOnDecode=true;return finish(plan(1,6))')
        self.assertEqual(result[b'status'],b'cancelled')
        self.assertEqual(lua.globals().source[b'loader'][b'pages'][b'stats'][b'resident'],0)
        result = lua.execute(b'cancelOnDecode=false;testTime.tick=101;return finish(plan(1,6))')
        self.assertEqual((result[b'status'],result[b'reason']),(b'budget_exceeded',b'cpu_budget'))
        calls = lua.globals().decodeCalls
        self.assertEqual(lua.globals().activeJob.Step(lua.globals().activeJob)[b'status'],b'budget_exceeded')
        self.assertEqual(lua.globals().decodeCalls,calls)
        result = lua.execute(b'testTime.tick=0;return finish(plan(1,6))')
        self.assertEqual(result[b'status'],b'complete')

    def test_metadata_cache_eviction_and_encoded_survival(self):
        lua,pack,_ = fixture(nodes=12,node_limit=1)
        result = lua.globals().finish(lua.globals().plan(1,12))
        self.assertEqual(result[b'estimatedSeconds'],0.9) # direct is cheaper than1.1s
        result = lua.globals().finish(lua.globals().plan(2,12))
        self.assertEqual(result[b'estimatedSeconds'],1.0)
        pages = lua.globals().source[b'loader'][b'pages']
        self.assertLessEqual(pages[b'stats'][b'resident'],8)
        self.assertGreater(pages[b'stats'][b'evictions'],0)
        self.assertEqual(pages[b'pack'][b'payloads'],pack['payloads'].encode())
        self.assertEqual(lua.globals().finish(lua.globals().plan(1,3))[b'estimatedSeconds'],0.2)

    def test_decode_failure_recovery_and_stale_job_ownership(self):
        lua,_,_ = fixture()
        result=lua.execute(b'failOnDecode=true;return finish(plan(1,6))')
        self.assertEqual((result[b'status'],result[b'reason']),(b'unknown',b'decode_failed'))
        calls=lua.globals().decodeCalls
        lua.execute(b'activeJob:Step(64)')
        self.assertEqual(lua.globals().decodeCalls,calls)
        result=lua.execute(b'failOnDecode=false;return finish(plan(1,6))')
        self.assertEqual(result[b'estimatedSeconds'],0.5)
        units=lua.globals().source[b'loader'][b'pages'][b'stats'][b'bootstrapUnits']
        result=lua.execute(b'oldJob=plan(1,6);oldJob:Step(1);planner:Invalidate();newJob=plan(2,6);return finish(newJob)')
        self.assertEqual(result[b'estimatedSeconds'],0.4)
        self.assertEqual(lua.globals().oldJob.Step(lua.globals().oldJob)[b'status'],b'stale')
        self.assertEqual(lua.globals().source[b'loader'][b'pages'][b'stats'][b'bootstrapUnits'],units)

    def test_flat_index_range_failure_and_bootstrap_header_failure(self):
        lua,pack,_=fixture()
        raw=bytearray(base64.b64decode(pack['index']))
        ordinal=next(iter(pack['bootstrap'].values()))['metadata']
        offset=(ordinal-1)*19+6
        raw[offset:offset+4]=b'\xff'*4
        lua.globals().pack[b'index']=base64.b64encode(raw)
        result=lua.globals().finish(lua.globals().plan(1,6))
        self.assertEqual((result[b'status'],result[b'reason']),(b'invalid',b'invalid_flat_index'))
        lua,_,_=fixture()
        result=lua.execute(b'pack.routing.ordinals[pack.routing.names[1]]=999;return finish(plan(1,6))')
        self.assertEqual((result[b'status'],result[b'reason']),(b'invalid',b'invalid_flat_bootstrap'))

    def test_wrong_native_return_type_is_terminal(self):
        lua,_,_=fixture()
        result=lua.execute(b'''
            local pages=source.loader.pages
            pages.options.decodeBase64=function()return false end
            local read=pages:Read(1)
            return read:Advance()
        ''')
        self.assertEqual(result,(b'invalid',b'invalid_flat_decode'))

    def test_unknown_boundary_keeps_available_route_and_human_metadata(self):
        lua,_,_=fixture(unknown=(2,3))
        result=lua.globals().finish(lua.globals().plan(1,6))
        self.assertEqual(result[b'status'],b'complete')
        self.assertEqual(result[b'estimatedSeconds'],0.9)
        name=lua.execute(b'return source.loader.pages:Peek(pack.routing.names[1]).index.name')
        self.assertIn('Jardin d’été 日本'.encode(),name)
        result=lua.execute(b'activeJob=planner:Plan({from=refs[1],to=refs[6],via={refs[3]}});return finish(activeJob)')
        self.assertEqual(result[b'status'],b'unknown')
        self.assertIsNone(result[b'segments'])

    def test_tiny_directed_graphs_against_independent_oracle(self):
        from tests.lua.navigation_v2_sectors.test_prepared import shortest
        rng=random.Random(20021)
        for case in range(12):
            edges=[[a,b,rng.randrange(6)*100] for a in range(1,7) for b in range(1,7)
                   if a!=b and rng.random()<0.25]
            with self.subTest(case=case):
                lua,_,_=fixture(edges=edges)
                expected=shortest(6,edges,1,6)
                result=lua.globals().finish(lua.globals().plan(1,6))
                self.assertEqual(result[b'status'],b'no_path' if expected is None else b'complete')
                if expected is not None:
                    self.assertEqual(result[b'estimatedSeconds'],expected/1000)

    def test_interleaved_jobs_keep_only_their_active_metadata_after_eviction(self):
        lua,_,_=fixture(nodes=12,node_limit=1)
        first,second=lua.execute(b'''
            local a=planner:Plan({from=refs[1],to=refs[2]})
            local pending=false
            for i=1,2000 do
                assert(a:Step(1).status=='running')
                local state=a.search and a.search.loading
                if state and state.kind~='metadata' and state.sector then pending=true;break end
            end
            assert(pending,'fixture never began a flat row')
            local b=planner:Plan({from=refs[3],to=refs[12]})
            local second=finish(b)
            local sector=refs[2]:match('^([^:]+):')
            assert(not source.loader.pages:Peek(sector),'fixture did not evict pending metadata')
            return finish(a),second
        ''')
        self.assertEqual(first[b'estimatedSeconds'],0.1)
        self.assertEqual(second[b'estimatedSeconds'],0.9)

    def test_boundary_metadata_spans_more_than_one_chunk(self):
        edges=[[1,node,node*100] for node in range(2,21)]
        lua,_,_=fixture(nodes=20,node_limit=1,edges=edges)
        result=lua.globals().finish(lua.globals().plan(1,20))
        self.assertEqual(result[b'status'],b'complete')
        self.assertEqual(result[b'estimatedSeconds'],2.0)
        count=lua.execute(b'''
            local sector=refs[1]:match('^([^:]+):')
            local state={}
            for i=1,10000 do
                local metadata,status,reason=source.loader.pages:Ensure(state,sector)
                if metadata then return #metadata.index.links end
                assert(status=='running',reason)
            end
        ''')
        self.assertEqual(count,19)

    def test_extra_cbor_admission_matches_the_encoded_payload_ceiling(self):
        lua,pack,_=fixture(routing=False)
        # An unchanged inner geometry page, with a large opaque envelope field.
        wire=bytearray(base64.b64decode(pack['index']))
        extra=base64.b64encode(exporter('compact').cbor({'edges':1,'note':'x'*16400},metadata=True))
        self.assertLessEqual(len(extra),22000)
        wire[12:16]=len(pack['extras']).to_bytes(4,'big')
        wire[16:18]=len(extra).to_bytes(2,'big')
        lua.globals().pack[b'extras']=pack['extras'].encode()+extra
        lua.globals().pack[b'index']=base64.b64encode(wire)
        status,length=lua.execute(b'''
            local read=source.loader.pages:Read(1)
            for i=1,20 do
                local status=read:Advance()
                if status then return status,read.value and #read.value.note end
            end
        ''')
        self.assertEqual((status,length),(b'ready',16400))

    def test_empty_compiled_catalog_is_unknown_without_decoding(self):
        lua,_,_=fixture(routing=False)
        empty=exporter('pages').compile_pages({'index':{},'catalog':{}})
        lua.globals().empty=lua.execute(exporter().lua_catalog(empty).encode())
        result=lua.execute(b'''
            options.routing=nil
            local source,reason=ns.LibAPRNavigationV2.NewSectorGraph(empty.bootstrap,empty,options)
            assert(source,reason)
            local p=assert(ns.LibAPRNavigationV2.New(source,{clock=options.clock,profileClock=options.profileClock}))
            return finish(p:Plan({from='absent:terrain:1',to='other:terrain:1'}))
        ''')
        self.assertEqual((result[b'status'],result[b'reason']),(b'unknown',b'sector_absent'))
        self.assertEqual(lua.globals().decodeCalls,0)
