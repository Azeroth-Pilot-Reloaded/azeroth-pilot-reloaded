"""Verify installed terrain independently of the offline generator checkout."""
import hashlib
import json
from pathlib import Path
import re
import unittest
from xml.etree import ElementTree

from tools.terrain_ui.catalog import select, with_world_scopes

LIBRARY = Path(__file__).resolve().parents[2] / "APR-Core/libs/LibAPRNavigation-1.0"


class TerrainCatalogTests(unittest.TestCase):
    def test_map_id_can_select_one_world_inside_a_geographic_group(self):
        data = {
            "worlds": {"501": {"id": 501, "name": {"en": "First map"}},
                       "502": {"id": 502, "name": {"en": "Second map"}}},
            "tree": [{"id": "ui:120", "name": {"en": "Continent"},
                      "zones": [{"id": "122", "name": {"en": "Shared zone"}, "worlds": [501, 502]}]},
                     {"id": "world:502", "name": {"en": "Second map"}, "world": 502, "zones": []}],
        }
        extended = with_world_scopes(data)
        self.assertEqual(select(extended, {"continent": "map:501"})[:2], ([501], [{"en": "First map"}]))
        self.assertEqual(select(extended, {"continent": "ui:120"})[0], [501, 502])
        self.assertEqual(select(extended, {"continent": "world:502"})[0], [502])
        self.assertEqual(len(extended["tree"]), len(data["tree"]) + 1)

    def test_generated_catalogues_publish_complete_packs_in_load_order(self):
        for index in (LIBRARY / "Data").glob("*/Terrain/Terrain.xml"):
            profile = index.parent.parent.name
            published = set()
            clients = set()
            for entry in ElementTree.parse(index).getroot():
                if entry.tag.rsplit("}", 1)[-1] == "Script":
                    continue
                relative = Path(entry.attrib["file"])
                self.assertRegex(relative.as_posix(), r"^(?:wow(?:t|xptr|_beta)/)?(?:0|[1-9][0-9]*)/Terrain\.xml$")
                world = relative.parent.name
                self.assertNotIn(relative, published)
                published.add(relative)
                with self.subTest(profile=profile, pack=relative):
                    xml = index.parent / relative
                    root = xml.parent
                    manifest_bytes = (root / "PACK.json").read_bytes()
                    manifest = json.loads(manifest_bytes)
                    generation = json.loads((root / "Generation.json").read_bytes())
                    self.assertEqual(hashlib.sha256(manifest_bytes).hexdigest(), generation["packManifestSha256"])
                    product = relative.parts[0] if len(relative.parts) == 3 else {"retail": "wow", "forever": "wowf"}.get(profile, profile)
                    build = generation["clientBuild"]
                    self.assertRegex(build, r"^\d+(?:\.\d+){2,}$")
                    self.assertEqual(product, generation["product"])
                    self.assertEqual((product, build), (manifest["grid"]["product"], manifest["grid"]["build"]))
                    self.assertEqual(profile, manifest["profile"])
                    key = build, world
                    self.assertNotIn(key, clients)
                    clients.add(key)
                    self.assertEqual(generation["maps"], [int(world)])
                    self.assertEqual(set(manifest["maps"]), {world})
                    tiles = json.loads((root / "Tiles.json").read_bytes())
                    self.assertEqual(len(set(tiles)), manifest["maps"][world]["clusters"])
                    order = [node.attrib["file"] for node in ElementTree.parse(xml).getroot()]
                    self.assertEqual(order, manifest["loadOrder"])
                    self.assertCountEqual(order, manifest["files"])
                    for name in order:
                        contents = (root / name).read_bytes()
                        self.assertEqual(hashlib.sha256(contents).hexdigest(), manifest["files"][name])
                        if manifest["profile"] in {"retail", "forever"}:
                            guard = f'MatchesGeneratedTerrain("{manifest["profile"]}","{build}")'.encode("ascii")
                            self.assertIn(guard, contents.split(b"\n", 2)[1])
            directories = [*index.parent.glob("[0-9]*/Terrain.xml"), *index.parent.glob("wow*/[0-9]*/Terrain.xml")]
            self.assertEqual(published, {path.relative_to(index.parent) for path in directories})

    def test_loaded_files_and_generation_describe_the_same_pack(self):
        catalogue_xml = {path for path in (LIBRARY / "Data").glob("*/Terrain/Terrain.xml")
                         if path.parent.parent.name in {"forever", "retail"}}
        declared = {
            LIBRARY / node.attrib["file"].replace("\\", "/")
            for manifest in LIBRARY.glob("Terrain_*.xml")
            for node in ElementTree.parse(manifest).getroot()
            if (relative := node.attrib["file"].replace("\\", "/")).startswith("Data/")
            and "/Terrain/" in relative
        }
        self.assertTrue(declared, "At least one client manifest must load a terrain catalogue")
        self.assertEqual(catalogue_xml, declared)
        for xml in declared:
            if not (xml.parent / "PACK.json").is_file():
                self.assertTrue(all(node.tag.rsplit("}", 1)[-1] == "Include" for node in ElementTree.parse(xml).getroot()))
                continue
            with self.subTest(profile=xml.parent.parent.name):
                root = xml.parent
                manifest_bytes = (root / "PACK.json").read_bytes()
                manifest = json.loads(manifest_bytes)
                source = json.loads((root / "Generation.json").read_bytes())
                self.assertEqual(hashlib.sha256(manifest_bytes).hexdigest(), source["packManifestSha256"])
                self.assertEqual((manifest["grid"]["product"], manifest["grid"]["build"]),
                                 (source["product"], source["clientBuild"]))
                self.assertEqual((manifest["cells"], manifest["format"]), (source["cells"], source["mapFormat"]))
                self.assertCountEqual(manifest["maps"], map(str, source["maps"]))

                scripts = [node.attrib["file"].replace("\\", "/") for node in ElementTree.parse(xml).getroot()
                           if node.tag.rsplit("}", 1)[-1] == "Script"]
                shipped = [path.relative_to(root).as_posix() for path in root.rglob("*.lua")
                           if not re.match(r"^(?:[0-9]+|\.install)/", path.relative_to(root).as_posix())]
                if (root / "Groups.json").is_file():
                    groups = json.loads((root / "Groups.json").read_bytes())
                    self.assertEqual(groups["sourceManifestSha256"], source["packManifestSha256"])
                    self.assertEqual(groups["revision"], manifest["revision"])
                    self.assertCountEqual(groups["maps"], manifest["maps"])
                    self.assertCountEqual([Path(name).name for name in scripts], groups["files"])
                    self.assertCountEqual(scripts, shipped)
                    for relative in scripts:
                        expected = groups["files"][Path(relative).name]
                        file = root / relative
                        self.assertEqual(hashlib.sha256(file.read_bytes()).hexdigest(), expected, relative)
                        if "maxGroupBytes" in groups and relative.startswith("Groups/"):
                            self.assertLessEqual(file.stat().st_size, groups["maxGroupBytes"], relative)
                    first_group = next(i for i, name in enumerate(scripts) if name.startswith("Groups/"))
                    self.assertTrue(all(not name.startswith("Index-") for name in scripts[first_group:]))
                    continue
                self.assertEqual(scripts, manifest.get("loadOrder", list(manifest["files"])),
                                 "Lua scripts must load in pack order")
                self.assertCountEqual(scripts, manifest["files"])
                self.assertCountEqual(scripts, shipped)
                for relative, expected in manifest["files"].items():
                    self.assertEqual(hashlib.sha256((root / relative).read_bytes()).hexdigest(), expected, relative)
