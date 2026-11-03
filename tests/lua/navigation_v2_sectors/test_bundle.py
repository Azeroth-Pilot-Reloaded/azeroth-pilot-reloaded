"""Delivered exporter/import gate -> actual XML, public Source and APR opt-in host."""
import base64
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import zlib

from .test_export import ROOT, exporter
from tests.lua.navigation_v2_terrain.codec_support import decode
from tests.lua.navigation_v2_terrain.test_data import runtime


def export_fixture(folder):
    module=exporter('generate')
    args=SimpleNamespace(client=folder/'client',output=folder/'export',casc='dll',recast=Path('native'),
        wdt=1,map=1,x=0,y=0,build='fixture',block_nodes=1,sector_id='garden',name='Garden paths')
    mesh={'vertices':[[0,0,0]],'polygons':[[0,0,0]]}
    with patch.object(module,'verify_build'),patch.object(module,'storage_snapshot',return_value={'files':1}),\
         patch.object(module,'Storage'),patch.object(module,'read_scene',return_value=([],[],{'cells':256},{})),\
         patch.object(module,'_native_mesh',return_value=mesh),\
         patch.object(module,'portal_graph',return_value=([[0,0,0]]*3,[[1,2,1],[2,3,1]])):
        module.generate(args)
    return module,args.output


class PreparedBundleTests(unittest.TestCase):
    def test_generated_bundle_enters_actual_source_and_host_explicitly(self):
        with tempfile.TemporaryDirectory() as directory:
            module,folder=export_fixture(Path(directory))
            receipt=module.audit_export(folder)
            mapping=json.loads((folder/'node-map.json').read_text())
            lua=runtime()
            lua.globals().bundleSource=(folder/'SectorBundle.lua').read_bytes()
            lua.globals().hostSource=(ROOT/'APR-Core/features/navigation/NavigationV2.lua').read_bytes()
            lua.globals().refs=lua.table_from([('%s:terrain:%s'%tuple(r)).encode() for r in mapping])
            lua.globals().expected=receipt['identity'].encode()
            result=lua.execute(b'''
                local foreignIndex,foreignCatalog,foreignBundle={},{},{}
                ns.NavigationV2SectorIndex={foreign=foreignIndex}
                ns.NavigationV2TerrainCatalog={foreign=foreignCatalog}
                ns.NavigationV2SectorBundles={foreign=foreignBundle}
                local load=assert(loadstring(bundleSource))
                load('APR',ns)
                local bundle=assert(ns.NavigationV2SectorBundles.garden)
                assert(ns.NavigationV2SectorIndex.foreign==foreignIndex)
                assert(ns.NavigationV2TerrainCatalog.foreign==foreignCatalog)
                assert(ns.NavigationV2SectorBundles.foreign==foreignBundle)
                local first=next(bundle.index)
                local kept=ns.NavigationV2SectorIndex[first]
                assert(not pcall(load,'APR',ns))
                assert(ns.NavigationV2SectorIndex[first]==kept)
                -- Even a bundle-registry-only collision must leave no partial insert.
                ns.NavigationV2SectorIndex={};ns.NavigationV2TerrainCatalog={}
                assert(not pcall(load,'APR',ns))
                assert(next(ns.NavigationV2SectorIndex)==nil and next(ns.NavigationV2TerrainCatalog)==nil)
                APR={navigation={legacy=true}}
                local legacy=APR.navigation
                assert(loadstring(hostSource))('APR',ns)
                assert(not APR.NavigationV2.enabled)
                options.routing=bundle.routing;options.routingIdentity=expected
                local source=assert(ns.LibAPRNavigationV2.NewSectorGraph(bundle.index,bundle.catalog,options))
                assert(source.routing==bundle.routing)
                assert(APR.NavigationV2:EnableSectors(bundle.index,bundle.catalog,options,{
                    clock=function()return 0 end,profileClock=options.profileClock}))
                assert(APR.navigation==legacy)
                APR.NavigationV2:Plan({from=refs[1],to=refs[3]})
                for i=1,10000 do
                    local result=APR.NavigationV2:Step(3)
                    if result.status~='running' then
                        assert(result.status=='complete' and result.estimatedSeconds==0.002)
                        APR.NavigationV2:Disable()
                        assert(APR.navigation==legacy)
                        return result
                    end
                end
                error('host did not terminate')
            ''')
            self.assertEqual(len(result[b'segments']),2)

    def test_serialized_import_rejects_fictitious_local_witness_and_stale_context(self):
        with tempfile.TemporaryDirectory() as directory:
            module,folder=export_fixture(Path(directory))
            path=folder/'manifest.json'
            original=path.read_text()
            manifest=json.loads(original)
            sector=manifest['routing']['names'][0]
            # Three nodes occupy one small sector. The false 1->3(2) copies
            # serial 1 and satisfies the distance bound, but is not a source edge.
            block=manifest['routing']['sectors'][sector]['witnessBlocks'][0][1][0]
            raw=decode(zlib.decompress(base64.b64decode(block['payload']),-15))
            raw[2][2]=[1,1,2,0,1]
            encoded=exporter('routing').cbor(raw)
            compressor=zlib.compressobj(9,zlib.DEFLATED,-15)
            block.update(rawBytes=len(encoded),payload=base64.b64encode(compressor.compress(encoded)+compressor.flush()).decode())
            path.write_text(json.dumps(manifest))
            with self.assertRaisesRegex(ValueError,'routing_witness_edge_absent'):
                module.audit_export(folder)
            for key,value in (('movementCosts',{'walk_speed':1}),('coverage',{'cells':255}),
                              ('sources',{'fake':{'sha256':'changed'}}),('routingIdentity','0'*64)):
                manifest=json.loads(original);manifest[key]=value
                path.write_text(json.dumps(manifest))
                with self.subTest(key=key),self.assertRaisesRegex(ValueError,'routing_source_mismatch'):
                    module.audit_export(folder)
            path.write_text(original)
            self.assertEqual(module.audit_export(folder)['edges'],2)
