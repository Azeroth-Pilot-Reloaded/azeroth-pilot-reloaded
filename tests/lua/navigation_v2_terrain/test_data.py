"""Common content integrity rules for every discovered V2 terrain export."""
import base64
from pathlib import Path
import time
import unittest
import zlib
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

from .codec_support import decode
from tools.validation.check_package import validate_runtime_files

ROOT = Path(__file__).resolve().parents[3]


def library_scripts(root=ROOT):
    directory=root/'APR-Core/libs/LibAPRNavigation-2.0'
    return [directory/element.attrib['file'] for element in ET.parse(directory/'LibAPRNavigation.xml').iter()
            if element.tag.rsplit('}',1)[-1]=='Script']


def runtime(root=ROOT):
    lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)
    times = {key:[] for key in ('base64','inflate','cbor')}
    def measured(key, callback):
        def call(source):
            started=time.perf_counter()
            value=callback(source)
            times[key].append((time.perf_counter()-started)*1000)
            return value
        return call
    lua.globals().py_base64 = measured('base64',lambda s: base64.b64decode(s, validate=True))
    lua.globals().py_inflate = measured('inflate',lambda s: zlib.decompress(s, -15))
    lua.globals().py_cbor = measured('cbor',lambda s: lua.table_from(decode(s), recursive=True))
    lua.globals().py_decode_max = lambda: max((v for values in times.values() for v in values),default=0)
    lua.globals().py_block_decode_max = lambda: max((sum(values) for values in zip(*times.values())),default=0)
    lua.globals().py_clock = lambda: time.perf_counter()*1000
    lua.execute(b'''
        ns={}
        options={profileClock=function() return py_clock() end,
            decodeBase64=function(s) return py_base64(s) end,
            inflate=function(s) return py_inflate(s) end,
            deserialize=function(s) return py_cbor(s) end}
        function finishLoad(job)
            local maximum=0
            for i=1,100000 do
                local started=py_clock()
                local r=job:Step(64)
                maximum=math.max(maximum,py_clock()-started)
                if r.status~='running' then
                    r.diagnostics.externalMaxStepMs=maximum
                    r.diagnostics.injectedMaxDecodeMs=py_decode_max()
                    r.diagnostics.injectedMaxBlockDecodeMs=py_block_decode_max()
                    return r
                end
            end
            error('loader failed to terminate')
        end
        function loadSector(catalog,id)
            return finishLoad(assert(ns.NavigationV2Terrain.New(catalog,options)):Load(id))
        end
    ''')
    execute=lua.eval(b'function(source) assert(loadstring(source))("APR",ns) end')
    for path in library_scripts(root):
        execute(path.read_bytes())
    return lua


class TerrainDataTests(unittest.TestCase):
    def test_rfc_decoder(self):
        self.assertEqual(decode(bytes.fromhex('8400201818190100')), [0,-1,24,256])

    def test_runtime_data_reachable_from_each_client_toc(self):
        data=set((ROOT/'APR-Core/libs/LibAPRNavigation-2.0/Data').rglob('*.lua'))
        for game in ('Standard','Camelot'):
            with self.subTest(game=game):
                references=validate_runtime_files(ROOT,ROOT/'APR.toc',game)
                for path in data:
                    self.assertEqual(references[path.resolve()],1,path)

    def test_all_discovered_runtime_declarations(self):
        scripts=library_scripts()
        self.assertEqual(len(scripts),len(set(scripts)), 'Library scripts load exactly once')
        self.assertLessEqual(set((ROOT/'APR-Core/libs/LibAPRNavigation-2.0/Data').rglob('*.lua')),set(scripts))
        lua=runtime()
        catalog=lua.globals().ns[b'NavigationV2TerrainCatalog'] or lua.table()
        for key,sector in catalog.items():
            with self.subTest(sector=key):
                self.assertIsInstance(key,bytes)
                self.assertTrue(key)
                self.assertFalse(sector[b'complete'])
                self.assertIsInstance(sector[b'client'],bytes)
                self.assertIsInstance(sector[b'build'],bytes)
                self.assertIsInstance(sector[b'mapId'],int)
                self.assertGreaterEqual(sector[b'mapId'],0)
                self.assertEqual(list(sector[b'tile'].keys()),[1,2])
                self.assertTrue(all(type(v) is int and 0<=v<64 for v in sector[b'tile'].values()))
                nodes, edges = [], []
                blocks=sector[b'blocks']
                self.assertEqual(sorted(blocks.keys()),list(range(1,len(blocks)+1)))
                self.assertLessEqual(len(blocks),32)
                for index in range(1,len(blocks)+1):
                    block=blocks[index]
                    raw = zlib.decompress(base64.b64decode(block[b'payload'],validate=True),-15)
                    self.assertEqual(len(raw),block[b'rawBytes'])
                    self.assertLessEqual(len(raw),16384)
                    version, first, points, links = decode(raw)
                    self.assertEqual((version,first),(2,len(nodes)+1))
                    self.assertEqual((len(points),len(links)),(block[b'nodes'],block[b'edges']))
                    self.assertLessEqual(len(points),128)
                    self.assertLessEqual(len(links),768)
                    nodes.extend(points); edges.extend(links)
                for point in nodes:
                    self.assertEqual(len(point),3)
                    self.assertTrue(all(type(v) is int and -2147483647<=v<=2147483647 for v in point))
                for a,b,cost in edges:
                    self.assertTrue(1<=a<=len(nodes) and 1<=b<=len(nodes) and cost>=0)
                result = lua.globals().loadSector(catalog,key)
                self.assertEqual(result[b'status'],b'complete')
                self.assertEqual((len(result[b'graph'][b'nodes']),len(result[b'graph'][b'edges'])),(len(nodes),len(edges)))
