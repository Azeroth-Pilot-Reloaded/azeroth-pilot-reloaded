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

    def terrain_catalogue(self):
        self.write("APR-Core/features/navigation/TerrainIndex.lua", """
APR.NavigationTerrainIndex = {schema=1,profiles={
retail={builds={["12.1.5.42"]=true},worlds={
    [9]={packs={{id="west",revision=4,file="NavigationData/example-retail/ground.lua"}}}
}},
forever={builds={["1.60.1.42"]=true},worlds={
    [17]={packs={{id="east",revision=3,file="NavigationData/example-forever/ground.lua"}}}
}}}}
""")
        self.write("APR-Core/features/navigation/NavigationTerrain.lua", "-- synthetic factory registry\n")
        for name in ("APR.toc", "APR_Mainline.toc", "APR_Camelot.toc"):
            toc = self.root / name
            toc.write_text(toc.read_text(encoding="utf8")
                           + "APR-Core/features/navigation/TerrainIndex.lua\n"
                           + "APR-Core/features/navigation/NavigationTerrain.lua\n"
                           + "NavigationData/Terrain_[Game].xml\n", encoding="utf8")
        chunks = {}
        for profile, game in (("retail", "Standard"), ("forever", "Camelot")):
            relative = f"NavigationData/example-{profile}/ground.lua"
            self.write(relative, "-- synthetic terrain factory\n")
            self.write(f"NavigationData/Terrain_{game}.xml", f'<Ui><Script file="{relative}"/></Ui>')
            chunks[profile] = self.root / relative
        return chunks

    def test_accepts_internal_client_selected_terrain_from_release_or_addon_root(self):
        self.terrain_catalogue()
        validate(self.release)
        validate(self.root)

    def test_rejects_missing_internal_terrain_chunk(self):
        chunks = self.terrain_catalogue()
        chunks["retail"].unlink()
        with self.assertRaisesRegex(AssertionError, "Missing runtime dependency"):
            validate(self.release)

    def test_rejects_unreferenced_indexed_terrain_chunk(self):
        self.terrain_catalogue()
        self.write("NavigationData/Terrain_Standard.xml", "<Ui/>")
        with self.assertRaisesRegex(AssertionError, "indexed terrain chunk once"):
            validate(self.release)

    def test_rejects_duplicate_chunk_or_manifest_includes(self):
        self.terrain_catalogue()
        manifest = self.root / "NavigationData/Terrain_Standard.xml"
        original = manifest.read_text(encoding="utf8")
        for extra in ('<Script file="example-retail/ground.lua"/>',
                      '<Script file="example-retail/../example-retail/ground.lua"/>',
                      '<Include file="duplicate.xml"/>'):
            with self.subTest(extra=extra):
                self.write("NavigationData/duplicate.xml", original)
                manifest.write_text(original.replace("</Ui>", extra + "</Ui>"), encoding="utf8")
                with self.assertRaisesRegex(AssertionError, "indexed terrain chunk once"):
                    validate(self.release)
        manifest.write_text(original, encoding="utf8")
        toc = self.root / "APR_Mainline.toc"
        toc.write_text(toc.read_text(encoding="utf8") + "NavigationData/Terrain_Standard.xml\n", encoding="utf8")
        with self.assertRaisesRegex(AssertionError, "indexed terrain chunk once"):
            validate(self.release)

    def test_rejects_a_chunk_loaded_for_the_wrong_client(self):
        self.terrain_catalogue()
        path = self.root / "NavigationData/Terrain_Camelot.xml"
        source = path.read_text(encoding="utf8")
        path.write_text(source.replace("</Ui>", '<Script file="example-retail/ground.lua"/></Ui>'), encoding="utf8")
        with self.assertRaisesRegex(AssertionError, "wrong client profile"):
            validate(self.release)

    def test_rejects_unindexed_internal_terrain(self):
        self.terrain_catalogue()
        self.write("NavigationData/unlisted.lua", "-- unknown factory\n")
        with self.assertRaisesRegex(AssertionError, "Unindexed internal terrain"):
            validate(self.release)

    def test_rejects_standalone_sibling_terrain_addons(self):
        self.terrain_catalogue()
        extra = self.release / "APR_NavData_Unexpected"
        extra.mkdir()
        with self.assertRaisesRegex(AssertionError, "Standalone terrain addon"):
            validate(self.release)

    def test_rejects_nested_terrain_tocs(self):
        self.terrain_catalogue()
        self.write("NavigationData/example-retail/Example.toc", "## LoadOnDemand: 1\n")
        with self.assertRaisesRegex(AssertionError, "Standalone library TOC"):
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
        self.terrain_catalogue()
        toc = self.root / "APR_Camelot.toc"
        toc.write_text(toc.read_text(encoding="utf8").replace("APR-Core/features/navigation/TerrainIndex.lua\n", ""), encoding="utf8")
        with self.assertRaisesRegex(AssertionError, "terrain index"):
            validate(self.release)

    def test_rejects_terrain_loader_missing_or_after_its_factories(self):
        self.terrain_catalogue()
        toc = self.root / "APR_Camelot.toc"
        original = toc.read_text(encoding="utf8")
        loader = "APR-Core/features/navigation/NavigationTerrain.lua\n"
        for source, message in ((original.replace(loader, ""), "terrain loader once"),
                                (original.replace(loader, "") + loader, "loader must precede")):
            with self.subTest(message=message):
                toc.write_text(source, encoding="utf8")
                with self.assertRaisesRegex(AssertionError, message):
                    validate(self.release)
        toc.write_text(original, encoding="utf8")

    def test_rejects_cyclic_xml_includes(self):
        self.write("APR-Core/libs/LibAPRNavigation-1.0/Catalogue.xml", '<Ui><Include file="Catalogue.xml"/></Ui>')
        with self.assertRaisesRegex(AssertionError, "Cyclic runtime manifest"):
            validate(self.release)

    def test_rejects_malformed_terrain_declarations(self):
        self.terrain_catalogue()
        path = self.root / "APR-Core/features/navigation/TerrainIndex.lua"
        original = path.read_text(encoding="utf8")
        for before, after in (
            ("schema=1", "schema=2"),
            ("retail={", "unknown={"),
            ('["12.1.5.42"]=true', '["12.1.5.42"]=false'),
            ("[9]=", "[-1]="),
            ('id="west"', 'id=""'),
            ('id="west"', 'id="west",addon="APR_NavData_Old"'),
            ("revision=4", "revision=-1"),
            ("revision=4", "revision=true"),
            ('file="NavigationData/example-retail/ground.lua"', 'file="../ground.lua"'),
            ('file="NavigationData/example-retail/ground.lua"', 'file="/NavigationData/ground.lua"'),
            ('file="NavigationData/example-retail/ground.lua"', 'file="OtherData/ground.lua"'),
            ('file="NavigationData/example-retail/ground.lua"', 'file="NavigationData/example-retail/../ground.lua"'),
            ('file="NavigationData/example-retail/ground.lua"', 'file="NavigationData/ground.json"'),
            ("packs={{", "packs={[2]={"),
        ):
            with self.subTest(change=(before, after)):
                path.write_text(original.replace(before, after), encoding="utf8")
                with self.assertRaises(AssertionError):
                    validate(self.release)
        path.write_text(original, encoding="utf8")
