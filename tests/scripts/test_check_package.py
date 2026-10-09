"""Check the package validator using a minimal unpacked release fixture."""

from pathlib import Path
import tempfile
import unittest

from tools.validation.check_package import validate


class PackageValidationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for name, interface in (("APR.toc", 120105), ("APR_Mainline.toc", 120105), ("APR_Camelot.toc", 16001)):
            self.write(name, f"## Interface: {interface}\nAPR-Core/libs/FarstriderLibData_[Game].xml\nRoutes/RouteList_[Game].xml\n")
        for game, flavor in (("Standard", "Standard"), ("Camelot", "Vanilla")):
            self.write(f"Routes/{game}.lua", "-- route fixture\n")
            self.write(f"Routes/RouteList_{game}.xml", f'<Ui><Script file="Routes/{game}.lua"/></Ui>')
            entries = ["FarstriderLibData.xml",
                       f"FarstriderLibData/Areas/{flavor}/FarstriderLibData_Areas.xml",
                       f"FarstriderLibData/Waypoints/{flavor}/FarstriderLibData_Waypoints.xml",
                       "FarstriderLibData_Finalizer.xml"]
            self.write(f"APR-Core/libs/FarstriderLibData_{game}.xml",
                       "<Ui>" + "".join(f'<Include file="{entry}"/>' for entry in entries) + "</Ui>")
            for entry in entries:
                self.write(f"APR-Core/libs/{entry}", "<Ui/>")

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
        self.write("APR-Core/libs/FarstriderLibData.xml", '<Ui><Include file="nested.xml"/></Ui>')
        self.write("APR-Core/libs/nested.xml", '<Ui><Script file="missing.lua"/></Ui>')
        with self.assertRaisesRegex(AssertionError, "Missing runtime dependency"):
            validate(self.root)

    def test_keeps_runtime_artwork_and_license_notices(self):
        for relative in ("APR-Core/assets/ui/logo.tga", "APR-Core/assets/Arrow-APR.tga",
                         "LICENSE", "APR-Core/assets/ui/mdi/LICENSE", "APR-Core/libs/Library/LICENSE"):
            self.write(relative, "runtime artwork or license")
        validate(self.root)

    def test_accepts_wow_shared_schema_prefix(self):
        self.write("APR-Core/libs/FarstriderLibData.xml",
                   '<Ui xsi:schemaLocation="http://www.blizzard.com/wow/ui/ UI.xsd">'
                   '<Script file="embedded.lua"/></Ui>')
        self.write("APR-Core/libs/embedded.lua", "-- embedded runtime dependency\n")
        validate(self.root)
        (self.root / "APR-Core/libs/embedded.lua").unlink()
        with self.assertRaises(AssertionError):
            validate(self.root)
