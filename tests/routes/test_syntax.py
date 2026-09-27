"""Validate every packaged route with the same Lua grammar and declaration schema."""

from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

from tests.routes.route_loader import load_routes
from tests.routes.route_schema import RouteSchema


ROOT = Path(__file__).resolve().parents[2]
ROUTES = ROOT / "Routes"


class RouteSyntaxTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = load_routes()
        cls.schema = RouteSchema(cls.catalog)
        cls.runtime = LuaRuntime(unpack_returned_tuples=True)
        cls.compile_source = cls.runtime.eval(
            "function(source, name) local chunk, err = loadstring(source, name); "
            "return chunk ~= nil, err end"
        )

    def test_core_lua_syntax(self):
        files = sorted((ROOT / "APR-Core").rglob("*.lua"))
        self.assertTrue(files, "No addon Lua files found")
        for path in files:
            with self.subTest(file=path.relative_to(ROOT).as_posix()):
                valid, error = self.compile_source(path.read_text(encoding="utf-8-sig"), "@" + path.as_posix())
                self.assertTrue(valid, error)

    def test_client_manifests_reference_existing_unique_routes(self):
        registered = set()
        for client in ("Standard", "Camelot"):
            manifest = ROUTES / f"RouteList_{client}.xml"
            entries = [element.attrib["file"] for element in ET.parse(manifest).getroot()]
            self.assertTrue(entries, f"Empty manifest: {manifest.name}")
            self.assertEqual(len(entries), len(set(entries)), f"Duplicate entries in {manifest.name}")
            self.assertFalse(registered.intersection(entries), "Clients must load separate routes")
            for entry in entries:
                with self.subTest(manifest=manifest.name, route=entry):
                    path = (ROOT / entry).resolve()
                    self.assertTrue(path.is_relative_to(ROUTES))
                    self.assertEqual(path.suffix, ".lua")
                    self.assertTrue(path.is_file(), f"Missing route: {entry}")
            registered.update(entries)
        self.assertEqual(registered, {path.relative_to(ROOT).as_posix() for path in FILES},
                         "Every route file must be registered in a client manifest")


def make_syntax_test(path):
    def test(self):
        name = path.relative_to(ROOT).as_posix()
        for key, source in self.catalog.sources.items():
            if source == name:
                with self.subTest(route=key):
                    self.schema.validate(key, self.catalog.routes[key])
    return test


FILES = sorted(ROUTES.rglob("*.lua"))
if not FILES:
    raise RuntimeError("No Lua route files found")
for index, path in enumerate(FILES):
    name = f"test_route_{index:03d}_" + path.stem.replace("-", "_")
    setattr(RouteSyntaxTests, name, make_syntax_test(path))
