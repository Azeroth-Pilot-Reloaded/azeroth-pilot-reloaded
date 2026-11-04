"""Discover public synthetic reader tests and metadata-only V1 manifest contracts."""
import importlib.util
import hashlib
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

from tests.lua.navigation_v2_sectors.test_export import exporter


def road_reader():
    with patch.dict(sys.modules, {'tools.navigation_v2.import_roads': exporter('import_roads')}):
        return exporter('import_road_data')


class ManifestMetadataTests(unittest.TestCase):
    def test_every_declared_road_source_has_bounded_metadata(self):
        root = Path(__file__).resolve().parents[3]
        reader = road_reader()
        entries = reader.discover_road_data(root/'APR-Core/libs/LibAPRNavigation-1.0/LibAPRNavigation.xml')
        for entry in entries:
            with self.subTest(source=entry['relative']):
                self.assertIn(entry['kind'], ('roads', 'collision'))
                self.assertGreater(entry['bytes'], 0)
                self.assertLessEqual(entry['bytes'], reader.MAX_SOURCE_BYTES)
                self.assertRegex(entry['sha256'], r'^[0-9a-f]{64}$')

    def test_every_discovered_canonical_capture_and_index_reference_is_valid(self):
        root=Path(__file__).resolve().parents[3].parent/'Route-generator/data/navigation_v2/forever/roads'
        reader=road_reader()
        for group in ('Networks','Collision'):
            for path in sorted((root/group).glob('*.json')):
                with self.subTest(source=path.name):
                    reader.read_road_capture(group+'/'+path.name,root=root)
        index=root/'catalog.json'
        if index.is_file():
            document=json.loads(index.read_text(encoding='utf-8'))
            self.assertEqual(document['format'],'v1-road-data-catalog/1')
            self.assertEqual(document['client'],'forever')
            self.assertFalse(document['complete'])
            self.assertEqual(document['authorization'],'unknown')
            paths={entry['path'] for entry in document['files']}
            for entry in document['files']:
                with self.subTest(reference=entry['path']):
                    capture=reader.read_road_capture(entry['path'],root=root)
                    self.assertEqual(entry['sourceSha256'],capture['sourceSha256'])
                    self.assertEqual(entry['canonicalSha256'],hashlib.sha256((root/entry['path']).read_bytes()).hexdigest())
            for identifier,item in document['networks'].items():
                with self.subTest(network=identifier):
                    self.assertEqual(item['id'],identifier)
                    self.assertEqual(item['status'],'facts-only')
                    self.assertEqual(item['authorization'],'unknown')
                    self.assertFalse(item['complete'])
                    self.assertIn(item['sourcePath'],paths)
                    self.assertTrue(all(type(value) in (str,bool,int) for value in item.values()))


def load_tests(loader, tests, pattern):
    root = Path(__file__).resolve().parents[3].parent / 'Route-generator'
    roads, sectors = exporter('import_roads'), exporter()
    with patch.dict(sys.modules, {'tools.navigation_v2.import_roads': roads,
                                 'tools.navigation_v2.sectors': sectors}):
        reader = exporter('import_road_data')
        spec = importlib.util.spec_from_file_location(
            'synthetic_v1_road_data_contracts', root/'tests/navigation_v2/test_import_road_data.py')
        module = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, {'tools.navigation_v2.import_road_data': reader}):
            spec.loader.exec_module(module)
        tests.addTests(loader.loadTestsFromTestCase(module.RoadDataTests))
        tests.addTests(loader.loadTestsFromTestCase(module.RoadCanonicalTests))
    return tests
