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
                       f"libs/FarstriderLibData/Areas/{flavor}/FarstriderLibData_Areas.xml",
                       f"libs/FarstriderLibData/Waypoints/{flavor}/FarstriderLibData_Waypoints.xml",
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
        with self.assertRaisesRegex(AssertionError, "Tests must not be distributed"):
            validate(self.root)
