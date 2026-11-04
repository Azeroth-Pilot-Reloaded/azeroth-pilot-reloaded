"""Standard APR discovery of the public synthetic V1-terrain/V2-factory examples."""
import importlib.util
import hashlib
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

from tests.lua.navigation_v2_sectors.test_export import exporter


class TerrainCanonicalMetadataTests(unittest.TestCase):
    def test_discovered_canonical_surveys_convert_with_declared_metadata(self):
        root = Path(__file__).resolve().parents[3].parent/'Route-generator'
        importer = exporter('import_terrain')
        for index in sorted((root/'data/navigation_v2').glob('*/terrain/catalog.json')):
            document = json.loads(index.read_text(encoding='utf-8'))
            self.assertEqual(document['format'], 'v1-terrain-data-catalog/1')
            self.assertEqual(document['client'], index.parents[1].name)
            self.assertFalse(document['complete'])
            self.assertEqual(document['authorization'], 'unknown')
            declared = {row['path']:row for row in document['files']}
            discovered = {p.relative_to(index.parent).as_posix() for p in (index.parent/'Surveys').glob('*.json')}
            self.assertEqual(set(declared), discovered)
            self.assertEqual(len(document['files']), len(declared))
            referenced = set()
            for identifier, item in document['surveys'].items():
                with self.subTest(survey=identifier):
                    path = (index.parent/item['sourcePath']).resolve()
                    self.assertTrue(path.is_relative_to(index.parent.resolve()))
                    self.assertIn(item['sourcePath'], declared)
                    self.assertNotIn(item['sourcePath'], referenced)
                    referenced.add(item['sourcePath'])
                    raw = path.read_bytes()
                    capture = json.loads(raw)
                    info = declared[item['sourcePath']]
                    self.assertEqual(info['bytes'], len(raw))
                    self.assertEqual(item['canonicalSha256'], hashlib.sha256(raw).hexdigest())
                    self.assertEqual(info['canonicalSha256'], item['canonicalSha256'])
                    self.assertEqual(info['sourceSha256'], capture['sourceSha256'])
                    self.assertEqual(item['sourceSha256'], capture['sourceSha256'])
                    self.assertEqual(capture['client'], document['client'])
                    self.assertEqual(item['uid'], capture['uid'])
                    self.assertEqual(item['worldID'], capture['world'])
                    self.assertEqual(item['registrationHash'], capture['registrationHash'])
                    self.assertEqual(item['build'], capture['data']['build'])
                    self.assertEqual(item['id'], identifier)
                    self.assertEqual(item['status'], 'facts-only')
                    self.assertFalse(item['complete'])
                    self.assertEqual(item['authorization'], 'unknown')
                    self.assertTrue(all(type(v) in (str,int,bool) for v in item.values()))
                    converted = importer.convert_terrain_data(capture, identifier=identifier,
                        name=item['name'], walk_speed=7, **document['conversionOptions'])
                    self.assertEqual(item['conversion'], 'converted')
                    for count, values in [('sourceNodes',capture['data']['nodes']),
                                          ('sourceEdges',capture['data']['edges']),
                                          ('sourceAnchors',capture['data'].get('anchors',[])),
                                          ('expandedNodes',converted['graph']['nodes']),
                                          ('expandedArcs',converted['graph']['edges']),
                                          ('anchors',converted['anchors']),('gaps',converted['gaps'])]:
                        self.assertEqual(item[count],len(values))
                    del converted
            self.assertEqual(referenced, discovered)

    def test_discovered_addon_catalogs_are_exact_bounded_metadata_projections(self):
        apr = Path(__file__).resolve().parents[3]
        library = apr/'APR-Core/libs/LibAPRNavigation-2.0'
        scripts = [e.attrib['file'] for e in ET.parse(library/'LibAPRNavigation.xml').iter()
                   if e.tag.rsplit('}',1)[-1]=='Script']
        for path in sorted((library/'Data').glob('*/Terrain/Catalog.lua')):
            with self.subTest(catalog=path):
                self.assertEqual(scripts.count(path.relative_to(library).as_posix()),1)
                self.assertLessEqual(path.stat().st_size,65536)
                client = path.parents[1].name
                index = apr.parent/'Route-generator/data/navigation_v2'/client/'terrain/catalog.json'
                self.assertLessEqual(index.stat().st_size,1024*1024)
                document = json.loads(index.read_text(encoding='utf-8'))
                expected = {k:v for k,v in document.items() if k not in ('files','conversionOptions')}
                lua = LuaRuntime()
                namespace = lua.execute('''return function(source)
                    local ns={}
                    setfenv(assert(loadstring(source)),{})(nil,ns)
                    return ns
                end''')(path.read_text(encoding='utf-8'))
                def plain(table):
                    return {k:plain(v) if lua.eval('type')(v)=='table' else v for k,v in table.items()}
                self.assertEqual(plain(namespace),{'NavigationV2'+client.capitalize()+'TerrainData':expected})


def synthetic_suite(loader):
    """Lightweight public contracts; excludes canonical whole-corpus conversion."""
    root = Path(__file__).resolve().parents[3].parent / 'Route-generator'
    importer, roads, sectors = exporter('import_terrain'), exporter('import_roads'), exporter()
    spec = importlib.util.spec_from_file_location(
        'synthetic_v1_terrain_factory_contracts', root / 'tests/navigation_v2/test_import_terrain.py')
    module = importlib.util.module_from_spec(spec)
    with patch.dict(sys.modules, {'tools.navigation_v2.import_terrain': importer,
                                 'tools.navigation_v2.import_roads': roads,
                                 'tools.navigation_v2.sectors': sectors}):
        spec.loader.exec_module(module)
        links = exporter('terrain_links')
        link_spec = importlib.util.spec_from_file_location(
            'synthetic_terrain_link_contracts', root / 'tests/navigation_v2/test_terrain_links.py')
        link_module = importlib.util.module_from_spec(link_spec)
        with patch.dict(sys.modules, {'tests.navigation_v2.test_import_terrain': module,
                                     'tools.navigation_v2.terrain_links': links}):
            link_spec.loader.exec_module(link_module)
            suite = loader.loadTestsFromModule(module)
            suite.addTests(loader.loadTestsFromModule(link_module))
    return suite


def load_tests(loader, tests, pattern):
    tests.addTests(synthetic_suite(loader))
    return tests
