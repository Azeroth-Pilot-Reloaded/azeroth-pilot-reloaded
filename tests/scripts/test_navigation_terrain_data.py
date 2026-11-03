"""Discover shipped terrain and check runtime contracts, without fixing itineraries."""

import hashlib
import json
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime, lua_type

from tools.validation.check_package import (
    read_terrain_index,
    terrain_array,
    terrain_declarations,
)


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "NavigationData"
INDEX = ROOT / "APR-Core/features/navigation/TerrainIndex.lua"
LIBRARY = ROOT / "APR-Core/libs/LibAPRNavigation-1.0"


def plain(value):
    if lua_type(value) == "table":
        return {key: plain(child) for key, child in value.items()}
    return value


def library_scripts(directory):
    """Use the shipped load order, including newly declared library modules."""
    xml = ET.parse(directory / "LibAPRNavigation.xml")
    return [directory / item.attrib["file"].replace("\\", "/")
            for item in xml.iter() if item.tag.rsplit("}", 1)[-1] == "Script"]


def manifest_profiles(manifest):
    if manifest["schema"] == 1:
        return {manifest["identity"]["profile"]: manifest}
    assert manifest["schema"] == 2, "Unsupported terrain manifest schema"
    assert isinstance(manifest["profiles"], dict), "Manifest profiles must be keyed by identity"
    return manifest["profiles"]


class NavigationTerrainDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.index = read_terrain_index(INDEX)
        cls.declarations = terrain_declarations(cls.index)
        cls.runtime = LuaRuntime(unpack_returned_tuples=True, register_eval=False, register_builtins=False)
        cls.runtime.execute("strmatch = string.match")
        stub = ROOT / "APR-Core/libs/HereBeDragons/LibStub/LibStub.lua"
        cls.runtime.execute(stub.read_text(encoding="utf-8-sig"))
        cls.scripts = library_scripts(LIBRARY)
        for path in cls.scripts:
            assert path.resolve().is_relative_to(LIBRARY.resolve()), "Library script escaped its directory"
            cls.runtime.execute(path.read_text(encoding="utf-8-sig"), name="@" + path.relative_to(ROOT).as_posix())
        cls.lib = cls.runtime.eval('(LibStub("LibAPRNavigation-1.0"))')
        cls.runtime.execute('''
            terrainRegistrations = {}
            terrainSources = {}
            APR = { NavigationTerrain = {} }
            function APR.NavigationTerrain:RegisterSource(profile, world, id, revision, factory)
                assert(type(factory) == "function", "Terrain source must be a deferred factory")
                terrainSources[#terrainSources+1] = {
                    profile=profile, world=world, id=id, revision=revision, factory=factory }
            end
            local lib = LibStub("LibAPRNavigation-1.0")
            local register = lib.RegisterTerrainData
            function lib:RegisterTerrainData(profile, world, data, revision, id)
                terrainRegistrations[#terrainRegistrations+1] = {
                    profile=profile, world=world, revision=revision or 1, id=id or "default",
                    build=data.build, dataProfile=data.profile, dataWorld=data.worldID, scope=data.scope,
                    neighborScopeIDs=data.neighborScopeIDs }
                return register(self, profile, world, data, revision, id)
            end
        ''')
        for path in sorted({ROOT / pack["file"] for _, _, pack in cls.declarations}):
            cls.runtime.execute(path.read_text(encoding="utf-8-sig"), name="@" + path.relative_to(ROOT).as_posix())
        cls.startup_registrations = len(terrain_array(cls.runtime.globals().terrainRegistrations))
        cls.runtime.execute('for _,source in ipairs(terrainSources) do source.factory() end')

    def test_discovered_profile_metadata_is_loaded_by_the_library(self):
        declared = set(self.scripts)
        self.assertEqual(len(declared), len(self.scripts), "Library scripts must load exactly once")
        self.assertLessEqual(set((LIBRARY / "Data").rglob("*.lua")), declared)

    def test_discovered_internal_chunks_and_client_manifests(self):
        self.assertEqual(list(DATA.rglob("*.toc")), [], "Internal terrain is part of APR, not separate addons")
        expected_chunks = {ROOT / pack["file"] for _, _, pack in self.declarations}
        self.assertEqual(expected_chunks, set(DATA.rglob("*.lua")))
        for profile, game in (("retail", "Standard"), ("forever", "Camelot")):
            with self.subTest(profile=profile):
                xml = ET.parse(DATA / ("Terrain_" + game + ".xml"))
                entries = [item.attrib["file"].replace("\\", "/") for item in xml.iter()
                           if item.tag.rsplit("}", 1)[-1] == "Script"]
                self.assertEqual(len(entries), len(set(entries)), "Each terrain source loads once")
                self.assertEqual(set(entries), {pack["file"] for candidate, _, pack in self.declarations if candidate == profile})

    def test_sources_defer_geometry_and_match_every_indexed_identity(self):
        self.assertEqual(self.startup_registrations, 0, "Loading source functions must not create terrain tables")
        expected = {(profile, world, pack["id"]): pack["revision"] for profile, world, pack in self.declarations}
        sources = terrain_array(self.runtime.globals().terrainSources)
        declared = {(source["profile"], source["world"], source["id"]): source["revision"] for source in sources}
        self.assertEqual(len(sources), len(declared), "Terrain factories have unique identities")
        self.assertEqual(declared, expected)

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
                registered_neighbors = registration["neighborScopeIDs"]
                indexed_neighbors = indexed["neighborScopeIDs"]
                own_scope = registration["scope"]["id"] if registration["scope"] is not None else None
                local_neighbors = self.runtime.table_from(plain(indexed_neighbors), recursive=True) if indexed_neighbors is not None else None
                self.assertIs(self.lib.Terrain.NeighborIDsValid(local_neighbors, own_scope), True)
                self.assertEqual(set(terrain_array(registered_neighbors)) if registered_neighbors is not None else set(),
                                 set(terrain_array(indexed_neighbors)) if indexed_neighbors is not None else set())
                if registration["scope"] is not None:
                    self.assertIs(self.lib.Terrain.ScopeValid(registration["scope"]), True)
                    world_scopes = {entry["scope"]["id"] for entry in terrain_array(profile["worlds"][key[1]]["packs"])
                                    if entry["scope"] is not None}
                    self.assertLessEqual(set(terrain_array(indexed_neighbors)) if indexed_neighbors is not None else set(), world_scopes)
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

    def test_all_logical_spaces_and_identified_points_share_valid_worlds_and_metadata(self):
        validate = self.runtime.eval('''function(profile)
            local lib = LibStub("LibAPRNavigation-1.0")
            local instance = lib:New({profile=profile,environment={}})
            local spaces=instance.config.NavigationSpaces or {}
            local byID={}
            for _,space in ipairs(spaces) do
                assert(lib.ValidateNavigationSpace(space),"Invalid navigation space: "..tostring(space.id))
                assert(not byID[space.id],"Duplicate navigation space: "..space.id)
                byID[space.id]=space
            end
            local function ancestry(space)
                local chain,seen={},{}
                while space do
                    assert(not seen[space.id] and #chain<50,"Cyclic or excessive space ancestry: "..space.id)
                    seen[space.id]=true;chain[#chain+1]=space
                    if not space.parentSpace then break end
                    local parent=byID[space.parentSpace]
                    assert(parent,"Unknown parent space: "..space.parentSpace)
                    assert(parent.worldID==space.worldID,"Parent space world mismatch: "..space.id)
                    space=parent
                end
                return chain
            end
            for _,space in ipairs(spaces) do ancestry(space) end
            local function point(raw,world)
                if raw.spaceID==nil then return end
                local space=byID[raw.spaceID]
                assert(space,"Unknown point space: "..tostring(raw.spaceID))
                assert(space.worldID==instance:GetWorldInstanceID(raw.instanceID or world),
                    "Point space world mismatch: "..space.id)
                if raw.spaceKind~=nil then assert(raw.spaceKind==space.kind,"Point space kind mismatch: "..space.id) end
                for _,field in ipairs({"groundOnly","noFly","requiresExit","indoor"}) do
                    assert(raw[field]==nil or type(raw[field])=="boolean","Point flag must be boolean: "..space.id.."/"..field)
                end
                local effectiveFloor
                for _,ancestor in ipairs(ancestry(space)) do
                    effectiveFloor=effectiveFloor or ancestor.floor
                    if ancestor.accessKey~=nil then
                        assert(raw.accessKey==nil or raw.accessKey==ancestor.accessKey,"Point space access mismatch: "..space.id)
                    end
                    if ancestor.groundOnly then
                        assert(raw.groundOnly~=false and raw.noFly~=false,"Point contradicts ground-only space: "..space.id)
                    end
                    if ancestor.requiresExit then
                        assert(raw.requiresExit~=false,"Point contradicts required space exit: "..space.id)
                    end
                end
                if effectiveFloor~=nil then
                    assert(raw.floor==nil or raw.floor==effectiveFloor,"Point space floor mismatch: "..space.id)
                end
                local bounds=space.bounds
                if bounds and raw.x and raw.y and raw.z then
                    assert(raw.x>=bounds.minX and raw.x<=bounds.maxX and raw.y>=bounds.minY and raw.y<=bounds.maxY
                        and raw.z>=bounds.minZ and raw.z<=bounds.maxZ,"Point falls outside its explicit space: "..space.id)
                end
            end
            local function visit(value,world)
                if type(value)~="table" then return end
                point(value,world)
                for _,child in pairs(value) do if type(child)=="table" then visit(child,world) end end
            end
            for world,entry in pairs(lib.terrainDatasets[profile] or {}) do
                for _,pack in pairs(entry.packs) do visit(pack.data,world) end
            end
            return true
        end''')
        for profile in sorted(set(self.lib.datasets.keys()) | set(self.index["profiles"].keys())):
            with self.subTest(profile=profile):
                self.assertIs(validate(profile), True)

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

    def assert_manifest_profile(self, profile, record):
        self.assertRegex(record["readerSha256"], r"^[0-9a-f]{64}$")
        identity = record["identity"]
        self.assertEqual(identity["profile"], profile)
        self.assertIs(self.index["profiles"][profile]["builds"][identity["build"]], True)
        self.assertIsInstance(identity["product"], str)
        self.assertIsInstance(identity["buildKey"], str)
        self.assertTrue(identity["product"] and identity["buildKey"])

    def assert_manifest_files(self, files, directory):
        expected_files = {path.relative_to(directory).as_posix() for path in directory.rglob("*")
                          if path.suffix in (".lua", ".xml")}
        self.assertEqual(set(files), expected_files)
        for relative, expected_hash in files.items():
            path = directory / relative
            self.assertTrue(path.resolve().is_relative_to(directory.resolve()), relative)
            self.assertRegex(expected_hash, r"^[0-9a-f]{64}$")
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), expected_hash, relative)

    def assert_space_catalogue(self, profile, catalogue):
        relative = catalogue["file"]
        path = ROOT / relative
        self.assertTrue(path.resolve().is_relative_to(ROOT.resolve()))
        self.assertEqual(path, LIBRARY / "Data" / profile / "NavigationSpaces.lua")
        self.assertIn(path, self.scripts)
        self.assertRegex(catalogue["sha256"], r"^[0-9a-f]{64}$")
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), catalogue["sha256"])

    def test_manifest_profile_schemas_and_temporary_file_integrity(self):
        legacy = {"schema": 1, "identity": {"profile": "invented"}}
        current = {"schema": 2, "profiles": {"invented": {"identity": {"profile": "invented"}}}}
        self.assertEqual(manifest_profiles(legacy), {"invented": legacy})
        self.assertEqual(manifest_profiles(current), current["profiles"])
        with self.assertRaisesRegex(AssertionError, "Unsupported"):
            manifest_profiles({"schema": 3})
        with self.assertRaisesRegex(AssertionError, "keyed"):
            manifest_profiles({"schema": 2, "profiles": []})
        # Only temporary inputs are modified: shipped content remains read-only.
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            chunk = directory / "Synthetic.lua"
            chunk.write_bytes(b"synthetic geometry")
            digest = hashlib.sha256(chunk.read_bytes()).hexdigest()
            self.assert_manifest_files({"Synthetic.lua": digest}, directory)
            with self.assertRaises(AssertionError):
                self.assert_manifest_files({}, directory)
            with self.assertRaises(AssertionError):
                self.assert_manifest_files({"Synthetic.lua": "0" * 64}, directory)

    def test_optional_manifest_hashes_and_region_metadata(self):
        manifest_path = DATA / "manifest.json"
        if not manifest_path.exists():
            return
        manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
        profiles = manifest_profiles(manifest)
        self.assertTrue(profiles)
        for profile, record in profiles.items():
            with self.subTest(profile=profile):
                self.assert_manifest_profile(profile, record)
                if manifest["schema"] == 2:
                    self.assert_space_catalogue(profile, record["spaceCatalogue"])
        if manifest["schema"] == 2:
            self.assertEqual(set(profiles), set(self.index["profiles"].keys()))
        files = manifest["files"]
        self.assert_manifest_files(files, DATA)
        if manifest["schema"] == 1:
            profile = manifest["identity"]["profile"]
            scopes = {(world, json.dumps(plain(pack["scope"]), sort_keys=True))
                      for candidate, world, declaration in self.declarations if candidate == profile
                      for pack in terrain_array(self.index["profiles"][profile]["worlds"][world]["packs"])
                      if pack["id"] == declaration["id"] and pack["scope"] is not None}
            regions = {(region["worldID"], json.dumps(region["scope"], sort_keys=True)) for region in manifest["regions"]}
            self.assertEqual(regions, scopes)
