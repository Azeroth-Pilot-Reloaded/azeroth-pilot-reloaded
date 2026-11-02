"""Discover shipped terrain and check runtime contracts, without fixing itineraries."""

import hashlib
import json
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime, lua_type

from tools.validation.check_package import (
    read_terrain_index,
    terrain_array,
    terrain_declarations,
    toc_metadata,
)


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "NavigationData"
INDEX = ROOT / "APR-Core/features/navigation/TerrainIndex.lua"
LIBRARY = ROOT / "APR-Core/libs/LibAPRNavigation-1.0"


def plain(value):
    if lua_type(value) == "table":
        return {key: plain(child) for key, child in value.items()}
    return value


class NavigationTerrainDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.index = read_terrain_index(INDEX)
        cls.declarations = terrain_declarations(cls.index)
        cls.runtime = LuaRuntime(unpack_returned_tuples=True, register_eval=False, register_builtins=False)
        cls.runtime.execute("strmatch = string.match")
        stub = ROOT / "APR-Core/libs/HereBeDragons/LibStub/LibStub.lua"
        cls.runtime.execute(stub.read_text(encoding="utf-8-sig"))
        for name in ("Core.lua", "Geography.lua", "Search.lua", "Terrain.lua", "TerrainHeight.lua"):
            cls.runtime.execute((LIBRARY / name).read_text(encoding="utf-8-sig"), name="@" + name)
        cls.lib = cls.runtime.eval('(LibStub("LibAPRNavigation-1.0"))')
        cls.runtime.execute('''
            terrainRegistrations = {}
            local lib = LibStub("LibAPRNavigation-1.0")
            local register = lib.RegisterTerrainData
            function lib:RegisterTerrainData(profile, world, data, revision, id)
                terrainRegistrations[#terrainRegistrations+1] = {
                    profile=profile, world=world, revision=revision or 1, id=id or "default",
                    build=data.build, dataProfile=data.profile, dataWorld=data.worldID, scope=data.scope }
                return register(self, profile, world, data, revision, id)
            end
        ''')
        for path in sorted({DATA / pack["addon"] / pack["file"] for _, _, pack in cls.declarations}):
            cls.runtime.execute(path.read_text(encoding="utf-8-sig"), name="@" + path.relative_to(ROOT).as_posix())

    def test_discovered_addons_and_chunk_manifests(self):
        expected_addons = {pack["addon"] for _, _, pack in self.declarations}
        actual_addons = {toc.parent.name for toc in DATA.glob("*/*.toc")}
        self.assertEqual(expected_addons, actual_addons)
        expected_chunks = {DATA / pack["addon"] / pack["file"] for _, _, pack in self.declarations}
        self.assertEqual(expected_chunks, set(DATA.rglob("*.lua")))
        for profile, world, pack in self.declarations:
            with self.subTest(profile=profile, world=world, pack=pack["id"]):
                directory = DATA / pack["addon"]
                toc = directory / (pack["addon"] + ".toc")
                metadata = toc_metadata(toc)
                self.assertEqual(metadata.get("loadondemand"), "1")
                self.assertEqual(metadata.get("x-apr-terrain-profile"), profile)
                self.assertEqual(metadata.get("x-apr-terrain-world"), str(world))
                self.assertIn("APR", [part.strip() for part in metadata.get("dependencies", "").split(",")])
                entries = [line.strip().replace("\\", "/") for line in toc.read_text(encoding="utf-8-sig").splitlines()
                           if line.strip() and not line.strip().startswith("#")]
                self.assertEqual(entries.count(pack["file"]), 1)
                self.assertEqual(set(entries), {item["file"] for _, _, item in self.declarations if item["addon"] == pack["addon"]})

    def test_registered_identities_builds_and_exact_scopes(self):
        expected = {(profile, world, pack["id"]): pack for profile, world, pack in self.declarations}
        registrations = terrain_array(self.runtime.globals().terrainRegistrations)
        self.assertEqual(len(registrations), len(expected))
        seen = set()
        for registration in registrations:
            key = (registration["profile"], registration["world"], registration["id"])
            with self.subTest(identity=key):
                self.assertIn(key, expected)
                self.assertNotIn(key, seen)
                seen.add(key)
                pack = expected[key]
                profile = self.index["profiles"][key[0]]
                self.assertEqual(registration["revision"], pack["revision"])
                self.assertEqual(registration["dataProfile"], key[0])
                self.assertIn(registration["dataWorld"], (None, key[1]))
                self.assertIs(profile["builds"][registration["build"]], True)
                indexed = next(item for item in terrain_array(profile["worlds"][key[1]]["packs"]) if item["id"] == key[2])
                self.assertEqual(plain(registration["scope"]), plain(indexed["scope"]))
                if registration["scope"] is not None:
                    self.assertIs(self.lib.Terrain.ScopeValid(registration["scope"]), True)
                source = self.lib.terrainDatasets[key[0]][key[1]]["packs"][key[2]]["data"]
                terrain_array(source["nodes"])
                for edge in terrain_array(source["edges"]):
                    if edge["polyline"] is not None:
                        terrain_array(edge["polyline"])
                for anchor in terrain_array(source["anchors"]) if source["anchors"] is not None else ():
                    for field in ("path", "reversePath"):
                        if anchor[field] is not None:
                            terrain_array(anchor[field])
        self.assertEqual(seen, set(expected))

    def test_every_registered_graph_compiles_with_the_real_engine(self):
        compile_world = self.runtime.eval('''function(profile, world)
            local lib = LibStub("LibAPRNavigation-1.0")
            local instance = lib:New({profile=profile, environment={}})
            -- No attachment is requested: all indexed world geometry still
            -- passes the real node/edge/path/anchor compilation phases.
            local point={instanceID=world,x=0,y=0,z=0,noAutoconnect=true}
            local build=instance:CreateTerrainEdgeBuild({start=point,goal=point,
                movementProfile={canGround=true,canSteady=true,canSkyriding=true}})
            for _=1,100000 do
                local status=build:Step(512,100)
                if status~="planning" then
                    local nodes,anchors=0,0
                    for _ in pairs(build.nodes) do nodes=nodes+1 end
                    for _,worldAnchors in pairs(build.anchors) do anchors=anchors+#worldAnchors end
                    return status,build.reason,build.coverage.missingData,build.coverage.waitingData,
                        #build.packs,nodes,anchors
                end
            end
            error("Terrain data compilation exceeded its bounded work allowance")
        end''')
        for profile, world in sorted({(profile, world) for profile, world, _ in self.declarations}):
            with self.subTest(profile=profile, world=world):
                status, reason, missing, waiting, compiled_packs, nodes, anchors = compile_world(profile, world)
                self.assertEqual(status, "ready", reason)
                self.assertFalse(missing)
                self.assertFalse(waiting)
                sources = self.lib.terrainDatasets[profile][world]["packs"]
                self.assertEqual(compiled_packs, len(list(sources.keys())))
                expected_nodes = sum(len(terrain_array(pack["data"]["nodes"])) for pack in sources.values())
                expected_anchors = sum(len(terrain_array(pack["data"]["anchors"]))
                                       for pack in sources.values() if pack["data"]["anchors"] is not None)
                self.assertEqual(nodes, expected_nodes)
                self.assertEqual(anchors, expected_nodes + expected_anchors)

    def test_optional_manifest_hashes_and_region_metadata(self):
        manifest_path = DATA / "manifest.json"
        if not manifest_path.exists():
            return
        manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
        self.assertEqual(manifest["schema"], 1)
        self.assertRegex(manifest["readerSha256"], r"^[0-9a-f]{64}$")
        identity = manifest["identity"]
        self.assertIs(self.index["profiles"][identity["profile"]]["builds"][identity["build"]], True)
        self.assertTrue(identity["product"] and identity["buildKey"])
        files = manifest["files"]
        expected_files = {path.relative_to(DATA).as_posix() for path in DATA.rglob("*") if path.suffix in (".lua", ".toc")}
        self.assertEqual(set(files), expected_files)
        for relative, expected_hash in files.items():
            with self.subTest(file=relative):
                path = DATA / relative
                self.assertTrue(path.resolve().is_relative_to(DATA.resolve()))
                self.assertRegex(expected_hash, r"^[0-9a-f]{64}$")
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), expected_hash)
        scopes = {(world, json.dumps(plain(pack["scope"]), sort_keys=True))
                  for profile, world, declaration in self.declarations if profile == identity["profile"]
                  for pack in terrain_array(self.index["profiles"][identity["profile"]]["worlds"][world]["packs"])
                  if pack["id"] == declaration["id"] and pack["scope"] is not None}
        regions = {(region["worldID"], json.dumps(region["scope"], sort_keys=True)) for region in manifest["regions"]}
        self.assertEqual(regions, scopes)
