"""Verify installed terrain independently of the offline generator checkout."""
import hashlib
import json
from pathlib import Path
import unittest
from xml.etree import ElementTree


LIBRARY = Path(__file__).resolve().parents[2] / "APR-Core/libs/LibAPRNavigation-1.0"


class TerrainCatalogTests(unittest.TestCase):
    def test_loaded_files_and_generation_describe_the_same_pack(self):
        catalogue_xml = set((LIBRARY / "Data").glob("*/Terrain/Terrain.xml"))
        declared = {
            LIBRARY / node.attrib["file"].replace("\\", "/")
            for manifest in LIBRARY.glob("Terrain_*.xml")
            for node in ElementTree.parse(manifest).getroot()
            if node.attrib["file"].replace("\\", "/").startswith("Data/")
        }
        self.assertTrue(declared, "At least one client manifest must load a terrain catalogue")
        self.assertEqual(catalogue_xml, declared)
        for xml in declared:
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

                scripts = [node.attrib["file"].replace("\\", "/") for node in ElementTree.parse(xml).getroot()]
                if (root / "Groups.json").is_file():
                    groups = json.loads((root / "Groups.json").read_bytes())
                    self.assertEqual(groups["sourceManifestSha256"], source["packManifestSha256"])
                    self.assertEqual(groups["revision"], manifest["revision"])
                    self.assertCountEqual(groups["maps"], manifest["maps"])
                    self.assertCountEqual([Path(name).name for name in scripts], groups["files"])
                    self.assertCountEqual(scripts, [p.relative_to(root).as_posix() for p in root.rglob("*.lua")])
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
                self.assertCountEqual(scripts, [path.relative_to(root).as_posix() for path in root.rglob("*.lua")])
                for relative, expected in manifest["files"].items():
                    self.assertEqual(hashlib.sha256((root / relative).read_bytes()).hexdigest(), expected, relative)
