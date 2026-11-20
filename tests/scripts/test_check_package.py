"""Check the package validator using a minimal unpacked release fixture."""

from pathlib import Path
from contextlib import chdir
import base64
import struct
import tempfile
import unittest
import zlib

from tools.validation.check_package import validate, validate_terrain_companions


class PackageValidationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for name, interface in (("APR.toc", 120105), ("APR_Mainline.toc", 120105), ("APR_Camelot.toc", 16001)):
            self.write(name, f"## Interface: {interface}\nAPR-Core/libs/LibAPRNavigation-1.0/LibAPRNavigation.xml\nRoutes/RouteList_[Game].xml\n")
        for game, flavor in (("Standard", "Standard"), ("Camelot", "Vanilla")):
            self.write(f"Routes/{game}.lua", "-- route fixture\n")
            self.write(f"Routes/RouteList_{game}.xml", f'<Ui><Script file="Routes/{game}.lua"/></Ui>')
        self.write("APR-Core/libs/LibAPRNavigation-1.0/LibAPRNavigation.xml", '<Ui><Include file="Catalogue.xml"/></Ui>')
        self.write("APR-Core/libs/LibAPRNavigation-1.0/Catalogue.xml", '<Ui/>')

    def write(self, relative, content):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def test_accepts_client_selected_manifests(self):
        validate(self.root)

    def test_rejects_missing_route(self):
        (self.root / "Routes/Camelot.lua").unlink()
        with self.assertRaises(AssertionError):
            validate(self.root)

    def test_rejects_shared_client_route(self):
        self.write("Routes/RouteList_Camelot.xml", '<Ui><Script file="Routes/Standard.lua"/></Ui>')
        with self.assertRaisesRegex(AssertionError, "both client families"):
            validate(self.root)

    def test_rejects_shipped_tests(self):
        (self.root / "tests").mkdir()
        with self.assertRaisesRegex(AssertionError, "Development files must not be distributed: tests"):
            validate(self.root)

    def test_rejects_development_files_in_runtime_folders(self):
        for relative in ("APR-Core/README.md", "APR-Core/assets/ui/mdi/plus.svg",
                         "APR-Core/assets/ui/mdi/manifest.json", "APR-Core/libs/Library/Library.toc"):
            with self.subTest(path=relative):
                self.write(relative, "development source")
                with self.assertRaises(AssertionError):
                    validate(self.root)
                (self.root / relative).unlink()

    def test_rejects_missing_nested_runtime_dependency(self):
        self.write("APR-Core/libs/LibAPRNavigation-1.0/Catalogue.xml", '<Ui><Include file="nested.xml"/></Ui>')
        self.write("APR-Core/libs/LibAPRNavigation-1.0/nested.xml", '<Ui><Script file="missing.lua"/></Ui>')
        with self.assertRaisesRegex(AssertionError, "Missing runtime dependency"):
            validate(self.root)

    def test_keeps_runtime_artwork_and_license_notices(self):
        for relative in ("APR-Core/assets/ui/logo.tga", "APR-Core/assets/Arrow-APR.tga",
                         "LICENSE", "APR-Core/assets/ui/mdi/LICENSE", "APR-Core/libs/Library/LICENSE"):
            self.write(relative, "runtime artwork or license")
        validate(self.root)

    def test_accepts_wow_shared_schema_prefix(self):
        self.write("APR-Core/libs/LibAPRNavigation-1.0/Catalogue.xml",
                   '<Ui xsi:schemaLocation="http://www.blizzard.com/wow/ui/ UI.xsd">'
                   '<Script file="embedded.lua"/></Ui>')
        self.write("APR-Core/libs/LibAPRNavigation-1.0/embedded.lua", "-- embedded runtime dependency\n")
        validate(self.root)
        (self.root / "APR-Core/libs/LibAPRNavigation-1.0/embedded.lua").unlink()
        with self.assertRaises(AssertionError):
            validate(self.root)

    def terrain_manifests(self):
        library = "APR-Core/libs/LibAPRNavigation-1.0"
        self.write(f"{library}/Catalogue.xml", '<Ui><Include file="Terrain_[Game].xml"/></Ui>')
        self.write(f"{library}/Terrain_Standard.xml", '<Ui/>')
        self.write(f"{library}/Terrain_Camelot.xml",
                   '<Ui><Script file="Terrain.lua"/><Include file="Data/forever/Terrain/Terrain.xml"/></Ui>')
        self.write(f"{library}/Terrain.lua", "-- synthetic terrain provider\n")
        self.write(f"{library}/Data/forever/Terrain/Terrain.xml", '<Ui><Script file="Patch.lua"/></Ui>')
        self.write(f"{library}/Data/forever/Terrain/Patch.lua", "-- synthetic packed map\n")
        return library

    def test_accepts_terrain_loaded_only_by_forever(self):
        self.terrain_manifests()
        validate(self.root)

    def test_partitioned_release_requires_matching_on_demand_companions(self):
        data = base64.b64encode(zlib.compress(struct.pack('<IIIHH', 1, 3, 0, 1, 7))).decode()
        self.write("APR/Index-4.lua", f'I.pages={{"{data}"}}\nL:RegisterTerrainPartitionIndex("forever",4,8,D,I)\n')
        group = "APR_NavData_Forever_4_3"
        toc = f"{group}/{group}_Camelot.toc"
        script = f"{group}/World-4-Group-3.lua"
        manifest = "## LoadOnDemand: 1\n## Dependencies: APR\nWorld-4-Group-3.lua\n"
        addon = self.root / "APR"
        def check():
            validate_terrain_companions(addon, {addon / "Index-4.lua"})
        with self.assertRaisesRegex(AssertionError, "Missing terrain companion"):
            check()
        self.write(toc, manifest)
        self.write(script, 'L:RegisterTerrainPartitionPages("forever",4,7,3,D)\n')
        with self.assertRaisesRegex(AssertionError, "revision"):
            check()
        self.write(script, 'L:RegisterTerrainPartitionPages("forever",4,8,3,D)\n')
        check()
        self.write(toc, manifest.replace("LoadOnDemand: 1", "LoadOnDemand: 0"))
        with self.assertRaisesRegex(AssertionError, "Invalid terrain TOC"):
            check()

    def test_accepts_relative_package_directory(self):
        self.terrain_manifests()
        with chdir(self.root.parent):
            validate(Path(self.root.name))

    def test_rejects_terrain_runtime_loaded_by_retail(self):
        library = self.terrain_manifests()
        self.write(f"{library}/Terrain_Standard.xml", '<Ui><Script file="Terrain.lua"/></Ui>')
        with self.assertRaisesRegex(AssertionError, "Retail.*terrain"):
            validate(self.root)

    def test_rejects_nested_terrain_data_loaded_by_retail(self):
        library = self.terrain_manifests()
        self.write(f"{library}/Terrain_Standard.xml",
                   '<Ui><Include file="Data/forever/Terrain/Terrain.xml"/></Ui>')
        with self.assertRaisesRegex(AssertionError, "Retail.*terrain"):
            validate(self.root)

    def test_rejects_missing_forever_terrain_provider(self):
        library = self.terrain_manifests()
        self.write(f"{library}/Terrain_Camelot.xml",
                   '<Ui><Include file="Data/forever/Terrain/Terrain.xml"/></Ui>')
        with self.assertRaisesRegex(AssertionError, "Forever.*terrain provider"):
            validate(self.root)
