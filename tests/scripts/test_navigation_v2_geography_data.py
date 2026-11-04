"""Common contracts for every discovered geography authoring/export declaration."""
import json
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[2]
GEN=ROOT.parent/'Route-generator'
LIB=ROOT/'APR-Core/libs/LibAPRNavigation-2.0'
sys.path.insert(0,str(GEN))
try:
    from tools.navigation_v2 import import_geography as importer
    from tools.navigation_v2.import_transports import _plain
finally:
    sys.path.remove(str(GEN))


class GeographyContentTests(unittest.TestCase):
    def documents(self):
        paths=sorted((GEN/'data/navigation_v2').rglob('geography.json'))
        self.assertTrue(paths,'No geography authoring declarations discovered')
        return [(path,json.loads(path.read_text(encoding='utf-8'))) for path in paths]

    def test_all_discovered_declarations_share_schema_references_and_exact_export(self):
        for source,document in self.documents():
            with self.subTest(source=source):
                importer.validate(document)
                output=LIB/'Data'/document['client']/'Geography/Catalog.lua'
                self.assertEqual(output.read_text(encoding='utf-8'),importer.render(document))

    def test_every_discovered_geography_script_is_registered_exactly_once(self):
        scripts=[(LIB/element.attrib['file']).resolve() for element in ET.parse(LIB/'LibAPRNavigation.xml').iter()
                 if element.tag.rsplit('}',1)[-1]=='Script']
        paths=sorted((LIB/'Data').glob('*/Geography/*.lua'))
        self.assertTrue(paths,'No geography Lua declarations discovered')
        for path in paths:
            with self.subTest(path=path):
                self.assertEqual(scripts.count(path.resolve()),1)

    def test_every_exported_fact_round_trips_without_creating_an_engine(self):
        for source,document in self.documents():
            with self.subTest(source=source):
                lua=LuaRuntime();namespace=lua.table()
                output=LIB/'Data'/document['client']/'Geography/Catalog.lua'
                lua.execute(output.read_text(encoding='utf-8'),'content-contract',namespace)
                data=namespace.NavigationV2ForeverGeographyData
                self.assertFalse(data.complete)
                self.assertEqual(data.client,document['client'])
                for category in importer.GROUPS:
                    self.assertEqual(set(data[category].keys()),{record['id'] for record in document[category]})
                    for record in document[category]:
                        with self.subTest(category=category,id=record['id']):
                            self.assertEqual(_plain(data[category][record['id']]),record)
                for category in ('excluded','unknowns'):
                    self.assertEqual(_plain(data[category]),document[category])
                self.assertIsNone(namespace.LibAPRNavigationV2)

    def test_library_registration_is_reachable_from_each_discovered_addon_manifest(self):
        manifests=sorted(ROOT.glob('*.toc'))
        self.assertTrue(manifests,'No addon manifest discovered')
        target=(LIB/'LibAPRNavigation.xml').relative_to(ROOT).as_posix()
        for path in manifests:
            scripts=[line.strip().replace('\\','/') for line in path.read_text(encoding='utf-8-sig').splitlines()
                     if line.strip() and not line.lstrip().startswith('#')]
            with self.subTest(path=path):
                self.assertEqual(scripts.count(target),1)


if __name__=='__main__':
    unittest.main()
