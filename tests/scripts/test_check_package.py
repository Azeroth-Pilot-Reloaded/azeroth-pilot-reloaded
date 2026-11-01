"""Check the package validator using a minimal unpacked release fixture."""

from pathlib import Path
import tempfile
import unittest

from tools.validation.check_package import validate


class PackageValidationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.release = Path(self.directory.name)
        self.root = self.release / "APR"
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

    def terrain_pack(self):
        addon = "APR_NavData_Test_9"
        self.write("APR-Core/features/navigation/TerrainIndex.lua", '''
APR.NavigationTerrainIndex = {schema=1,profiles={retail={builds={["12.1.5.42"]=true},worlds={
    [9]={packs={{id="west",addon="APR_NavData_Test_9",revision=4,file="Terrain_1.lua"}}}
}}}}
''')
        for name in ("APR.toc", "APR_Mainline.toc", "APR_Camelot.toc"):
            toc = self.root / name
            toc.write_text(toc.read_text(encoding="utf8") + "APR-Core/features/navigation/TerrainIndex.lua\n", encoding="utf8")
        pack = self.release / addon
        pack.mkdir()
        toc = ("## Interface: 120105\n## LoadOnDemand: 1\n## Dependencies: APR\n"
               "## X-APR-Terrain-Profile: retail\n## X-APR-Terrain-World: 9\nTerrain_1.lua\n")
        (pack / (addon + ".toc")).write_text(toc, encoding="utf8")
        (pack / "Terrain_1.lua").write_text("-- synthetic terrain chunk\n", encoding="utf8")
        return pack, pack / (addon + ".toc")

    def test_accepts_indexed_sibling_terrain_addon_from_release_root(self):
        self.terrain_pack()
        validate(self.release)
        validate(self.root)

    def test_rejects_missing_terrain_addon(self):
        pack, _ = self.terrain_pack()
        pack.rename(self.release / "NotTheIndexedPack")
        with self.assertRaisesRegex(AssertionError, "Missing terrain addon"):
            validate(self.release)

    def test_rejects_non_lod_wrong_profile_world_or_dependency(self):
        replacements = (
            ("## LoadOnDemand: 1", "## LoadOnDemand: 0", "LoadOnDemand"),
            ("## Dependencies: APR", "## Dependencies: Other", "dependency"),
            ("## X-APR-Terrain-Profile: retail", "## X-APR-Terrain-Profile: forever", "profile"),
            ("## X-APR-Terrain-World: 9", "## X-APR-Terrain-World: 10", "world"),
            ("## Interface: 120105", "## Interface: 16001", "interface"),
        )
        _, toc = self.terrain_pack()
        original = toc.read_text(encoding="utf8")
        for before, after, message in replacements:
            with self.subTest(change=message):
                toc.write_text(original.replace(before, after), encoding="utf8")
                with self.assertRaisesRegex(AssertionError, message):
                    validate(self.release)
        toc.write_text(original, encoding="utf8")

    def test_rejects_missing_or_unreferenced_terrain_chunk(self):
        pack, toc = self.terrain_pack()
        chunk = pack / "Terrain_1.lua"
        chunk.unlink()
        with self.assertRaisesRegex(AssertionError, "Missing runtime dependency"):
            validate(self.release)
        chunk.write_text("-- chunk", encoding="utf8")
        toc.write_text(toc.read_text(encoding="utf8").replace("Terrain_1.lua", ""), encoding="utf8")
        with self.assertRaisesRegex(AssertionError, "indexed terrain chunk"):
            validate(self.release)

    def test_rejects_undeclared_terrain_addon(self):
        self.terrain_pack()
        extra = self.release / "APR_NavData_Unexpected"
        extra.mkdir()
        with self.assertRaisesRegex(AssertionError, "Undeclared terrain addon"):
            validate(self.release)

    def test_terrain_index_has_no_access_to_external_runtime(self):
        self.write("APR-Core/features/navigation/TerrainIndex.lua", 'APR.NavigationTerrainIndex = io.open("outside")')
        with self.assertRaisesRegex(AssertionError, "Invalid terrain index"):
            validate(self.release)

    def test_terrain_index_infinite_loop_is_bounded(self):
        self.write("APR-Core/features/navigation/TerrainIndex.lua", "while true do end")
        with self.assertRaisesRegex(AssertionError, "Invalid terrain index"):
            validate(self.release)

    def test_rejects_terrain_index_omitted_from_a_client_manifest(self):
        self.terrain_pack()
        toc = self.root / "APR_Camelot.toc"
        toc.write_text(toc.read_text(encoding="utf8").replace("APR-Core/features/navigation/TerrainIndex.lua\n", ""), encoding="utf8")
        with self.assertRaisesRegex(AssertionError, "terrain index"):
            validate(self.release)

    def test_rejects_malformed_terrain_declarations(self):
        self.terrain_pack()
        path = self.root / "APR-Core/features/navigation/TerrainIndex.lua"
        original = path.read_text(encoding="utf8")
        for before, after in (
            ("schema=1", "schema=2"),
            ("retail={", "unknown={"),
            ('["12.1.5.42"]=true', '["12.1.5.42"]=false'),
            ("[9]=", "[-1]="),
            ('id="west"', 'id=""'),
            ('addon="APR_NavData_Test_9"', 'addon="../outside"'),
            ("revision=4", "revision=-1"),
            ("revision=4", "revision=true"),
            ('file="Terrain_1.lua"', 'file="../Terrain_1.lua"'),
            ('file="Terrain_1.lua"', 'file="Terrain_1.json"'),
            ("packs={{", "packs={[2]={"),
        ):
            with self.subTest(change=(before, after)):
                path.write_text(original.replace(before, after), encoding="utf8")
                with self.assertRaises(AssertionError):
                    validate(self.release)
        path.write_text(original, encoding="utf8")
