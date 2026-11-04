"""Tiny export-to-wire-to-Lua contracts, not shipped route fixtures."""
import base64
import importlib.util
from pathlib import Path
import sys
import unittest
import zlib

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[3]
GEN = ROOT.parent / 'Route-generator'
sys.path.insert(0, str(GEN))
from tools.navigation_v2.export_roads import export_network
from tools.navigation_v2.sectors import lua_catalog

spec = importlib.util.spec_from_file_location('road_fixture_source', GEN / 'tests/navigation_v2/test_export_roads.py')
fixtures = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixtures)
fixture = fixtures.fixture


def runtime(pack):
    lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)
    lua.execute(b'ns={NavigationV2Graph={Budgets={sliceMs=1,cpuMs=100,elapsedMs=5000}}}')
    load = lua.eval(b'function(s)assert(loadstring(s))("test",ns)end')
    for name in ['RoadPages', 'RoadCollision']:
        load((ROOT / 'APR-Core/libs/LibAPRNavigation-2.0/Data' / (name + '.lua')).read_bytes())
    codec_spec = importlib.util.spec_from_file_location('road_wire_decoder', Path(__file__).with_name('codec_support.py'))
    codec = importlib.util.module_from_spec(codec_spec)
    codec_spec.loader.exec_module(codec)
    lua.globals().pack = lua.execute(lua_catalog(pack).encode())
    lua.globals().py_base64 = lambda s: base64.b64decode(s, validate=True)
    lua.globals().py_inflate = lambda s: zlib.decompress(s, -15)
    def binary(value):
        if isinstance(value, str):
            return value.encode('utf-8')
        if isinstance(value, list):
            return [binary(item) for item in value]
        if isinstance(value, dict):
            return {binary(key): binary(item) for key, item in value.items()}
        return value
    lua.globals().py_cbor = lambda s: lua.table_from(binary(codec.decode(s)), recursive=True)
    lua.execute(b'''
        options={clock=function()return 0 end,profileClock=function()return 0 end,
            decodeBase64=function(s)return py_base64(s)end,
            inflate=function(s)return py_inflate(s)end,
            deserialize=function(s)return py_cbor(s)end}
        reader=assert(ns.NavigationV2RoadPages.New(pack,options))
        function finish(job)
            for i=1,10000 do
                local state=job:Step(32)
                if state.status~='running' then return state end
            end
            error('Tiny page test did not terminate')
        end
    ''')
    return lua


class RoadPageTests(unittest.TestCase):
    def test_real_codec_row_and_shape_without_eager_decode(self):
        lua = runtime(export_network(*fixture()))
        lua.execute(b'''
            assert(reader:GetStats().loads==0)
            local row=finish(reader:Row('ground',2))
            assert(row.status=='complete' and row.row[1].state=='open')
            local before=reader:GetStats().loads
            assert(finish(reader:Row('ground',2)).status=='complete')
            assert(reader:GetStats().loads==before)
            local geometry=finish(reader:Slice(1,1.25,2.75))
            assert(geometry.status=='complete' and geometry.distance==12)
            assert(#geometry.points==3 and geometry.points[2][1]==1 and geometry.points[2][2]==9)
            assert(geometry.points[1][3]==nil)
            local reverse=finish(reader:Slice(1,2.75,1.25))
            assert(reverse.points[1][1]==7 and reverse.points[3][2]==3)
        ''')

    def test_missing_payload_and_cancel_are_not_available_rows(self):
        lua = runtime(export_network(*fixture()))
        lua.execute(b'''
            pack.masks[1].store.payloads=''
            local state=finish(reader:Row('ground',2))
            assert(state.status=='unknown' and state.reason=='page_missing')
            local job=reader:Slice(1,1,3)
            job:Step(1);assert(job:Cancel().status=='cancelled')
            assert(job:Step(32).status=='cancelled')
        ''')


if __name__ == '__main__':
    unittest.main()
