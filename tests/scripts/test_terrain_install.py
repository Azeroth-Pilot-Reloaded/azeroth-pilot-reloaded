"""Verify publishing without modifying the repository's terrain data."""

from hashlib import sha256
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch
from lupa.lua51 import LuaRuntime

from tools.terrain_ui.install import Installation, xml_file
from tools.terrain_ui.native import read_json, write_json


class TerrainInstallTests(unittest.TestCase):
    def setUp(self):
        folder = TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.root = Path(folder.name)
        self.library = self.root / "library"
        self.destination = Installation({"product": "wow", "build": "12.0.0.12345"}, self.library)

    def pack(self, name, keys, product="wow", build="12.0.0.12345"):
        source = self.root / name
        (source / "Nav").mkdir(parents=True)
        files = {
            "Nav/Nav7.lua": b'L._TerrainPackStages[7]={["cx0"]=0,["cy0"]=0,["ny"]=3}\n',
            "Nav/Nav7_00001.lua": b"".join(f"D.packed.grid[{key}]={{}}\n".encode() for key in keys)
            + f'L:RegisterTerrainData("{product}",7,D,1)\n'.encode(),
        }
        for relative, data in files.items():
            (source / relative).write_bytes(data)
        write_json(source / "PACK.json", {
            "grid": {"product": product, "build": build}, "maps": {"7": {"clusters": len(keys)}},
            "profile": product, "loadOrder": list(files),
            "files": {relative: sha256(data).hexdigest() for relative, data in files.items()},
        })
        write_json(source / "Generation.json", {"product": product, "clientBuild": build, "maps": [7],
            "packManifestSha256": sha256((source / "PACK.json").read_bytes()).hexdigest()})
        return source

    def install(self, source, check=lambda _: None):
        return self.destination.publish(source, 7, set(), check, lambda: None)

    def test_adds_coverage_with_a_build_guard_and_keeps_index_on_failure(self):
        first = self.install(self.pack("first", [1]))
        self.assertEqual(first.relative_to(self.library).as_posix(), "Data/retail/Terrain/7")
        self.assertEqual(self.destination.protected_tiles(7, None), {"31_31"})
        old_index = self.destination.index.read_bytes()

        with self.assertRaisesRegex(ValueError, "installed more tiles"):
            self.install(self.pack("smaller", [5]))
        self.assertEqual(self.destination.index.read_bytes(), old_index)

        extended = self.pack("extended", [1, 5])

        def fail_check(_):
            raise ValueError("Verification failed")
        with self.assertRaisesRegex(ValueError, "Verification failed"):
            self.install(extended, fail_check)
        self.assertEqual(self.destination.index.read_bytes(), old_index)

        def fail_index(path, entries):
            if path == self.destination.index:
                raise OSError("Index could not be updated")
            xml_file(path, entries)

        old_manifest = (first / "PACK.json").read_bytes()
        with patch("tools.terrain_ui.install.xml_file", side_effect=fail_index):
            with self.assertRaisesRegex(OSError, "Index could not be updated"):
                self.install(extended)
        self.assertEqual((first / "PACK.json").read_bytes(), old_manifest)
        self.assertEqual(self.destination.index.read_bytes(), old_index)

        second = self.install(extended)
        self.assertEqual(first, second)
        self.assertEqual(self.destination.protected_tiles(7, None), {"31_31", "30_30"})
        lua = (second / "Nav/Nav7_00001.lua").read_text(encoding="utf-8")
        self.assertIn('MatchesGeneratedTerrain("retail","12.0.0.12345")', lua)
        self.assertIn('RegisterTerrainData("retail",7,D,1,true)', lua)
        self.assertEqual(self.destination.index.read_bytes(), old_index)
        self.assertFalse(self.destination.paths(7)[1].exists())

    def test_new_build_replaces_map_in_place_and_ptr_has_its_own_directory(self):
        first = self.install(self.pack("live", [1]))
        build = "12.0.1.12346"
        ptr = Installation({"product": "wowt", "build": build}, self.library)
        ptr_pack = self.pack("ptr", [5], "wowt", build)
        self.assertEqual(ptr.publish(ptr_pack, 7, set(), lambda _: None, lambda: None), first.parent / "wowt/7")
        current = Installation({"product": "wow", "build": build}, self.library)
        updated = self.pack("updated", [9], "wow", build)
        self.assertEqual(current.protected_tiles(7, None), set())
        with self.assertRaisesRegex(ValueError, "Another product"):
            current.publish(updated, 7, set(), lambda _: None, lambda: None)

        build = "12.0.2.12347"
        current = Installation({"product": "wow", "build": build}, self.library)
        updated = self.pack("next", [9], "wow", build)
        self.assertEqual(current.publish(updated, 7, set(), lambda _: None, lambda: None), first)
        self.assertEqual(read_json(first / "Generation.json")["clientBuild"], build)
        self.assertEqual(current.protected_tiles(7, None), {"29_29"})
        self.assertEqual(current.catalogue()[1].keys(), {("wow", 7), ("wowt", 7)})

    def test_forever_retains_shipped_scripts_when_a_map_is_installed(self):
        build = "1.60.1.12345"
        forever = Installation({"product": "wowf", "build": build}, self.library)
        forever.root.mkdir(parents=True)
        base = [("Script", "Nav/Nav0.lua"), ("Script", "Nav/Nav0_00001.lua")]
        xml_file(forever.index, base)
        source = self.pack("forever", [1], "wowf", build)
        target = forever.publish(source, 7, set(), lambda _: None, lambda: None)
        self.assertEqual(target.relative_to(self.library).as_posix(), "Data/forever/Terrain/7")
        self.assertEqual(forever.catalogue(), (base, {("wowf", 7): target}))

    def test_runtime_loads_only_the_exact_retail_build(self):
        runtime = LuaRuntime()
        runtime.execute("""
            local fixture = dofile("tests/lua/terrain_runtime_fixture.lua")
            lib = fixture.load()
            retail = setmetatable({profile="retail",env={}}, lib.Instance)
            forever = setmetatable({profile="forever",env={}}, lib.Instance)
            function GetBuildInfo() return "12.0.0","12345","",120000 end
            assert(not lib:MatchesGeneratedTerrain("retail", "12.0.0.54321"))
            assert(not lib:MatchesGeneratedTerrain("forever", "12.0.0.12345"))
            lib:RegisterTerrainData("retail", 7, fixture.map(), 1)
            assert(retail:GetWalkingProvider() == nil)
            assert(lib:MatchesGeneratedTerrain("retail", "12.0.0.12345"))
            local partial = fixture.map()
            partial.nx = 2
            lib:RegisterTerrainData("retail", 7, partial, 1, true)
            local provider = assert(retail:GetWalkingProvider())
            assert(provider:HasMap(7))
            local covered = {instanceID=7,x=10,y=10}
            local hole = {instanceID=7,x=600,y=10}
            assert(provider:HasWalkingCoverage(covered))
            assert(not provider:HasWalkingCoverage(hole))
            assert(not provider:RequiresWalkingProof(covered,hole))
            assert(forever:GetWalkingProvider() == nil)
        """)
