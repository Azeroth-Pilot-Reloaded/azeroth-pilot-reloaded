"""Common integrity rules for retained V1 DATA and normalized editable V2 facts."""
import hashlib
import json
import math
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]
GEN = ROOT.parent/'Route-generator'
LIB = ROOT/'APR-Core/libs/LibAPRNavigation-2.0'
sys.path.insert(0, str(GEN))
try:
    from tools.navigation_v2 import import_geography, import_transports
finally:
    sys.path.remove(str(GEN))


def table_literal(value):
    """Check the explicit table-entry encoding without coercing numeric keys."""
    if isinstance(value, list):
        for child in value:
            table_literal(child)
    elif isinstance(value, dict):
        assert set(value) == {'tableEntries'}
        assert isinstance(value['tableEntries'], list)
        keys = set()
        for pair in value['tableEntries']:
            assert isinstance(pair, list) and len(pair) == 2
            key, child = pair
            assert type(key) in (str, int, float, bool)
            if type(key) in (int, float):
                assert math.isfinite(key)
            identity = (type(key), key)
            assert identity not in keys
            keys.add(identity)
            table_literal(child)
    else:
        assert type(value) in (str, int, float, bool)
        if type(value) in (int, float):
            assert math.isfinite(value)


def lua_shape(value):
    if isinstance(value, dict):
        return {key:lua_shape(child) for key, child in value.items()} if value else []
    if isinstance(value, list):
        return [lua_shape(child) for child in value]
    return value


def literal_namespace(content):
    return LuaRuntime(register_eval=False, register_builtins=False).execute('''return function(code)
        local ns={};setfenv(assert(loadstring(code)),{})(nil,ns);return ns
    end''')(content)


class DeclarationDataTests(unittest.TestCase):
    def catalogs(self):
        paths = sorted((GEN/'data/navigation_v2').glob('*/declarations/catalog.json'))
        self.assertTrue(paths, 'No canonical declaration catalog discovered')
        return paths

    def test_retained_tables_and_file_references_are_lossless_and_self_consistent(self):
        for index in self.catalogs():
            document = json.loads(index.read_text(encoding='utf-8'))
            self.assertEqual(document['format'], 'v1-declarative-facts-catalog/1')
            self.assertEqual(document['client'], index.parents[1].name)
            self.assertFalse(document['complete'])
            self.assertEqual(document['authorization'], 'unknown')
            declared = set()
            for row in document['files']:
                with self.subTest(source=row['path']):
                    path = (index.parent/row['path']).resolve()
                    self.assertTrue(path.is_relative_to(index.parent.resolve()))
                    self.assertNotIn(row['path'], declared)
                    declared.add(row['path'])
                    raw = path.read_bytes()
                    self.assertEqual(len(raw), row['bytes'])
                    self.assertEqual(hashlib.sha256(raw).hexdigest(), row['canonicalSha256'])
                    self.assertEqual(row['encoding'], 'lua-table-entries-v1')
                    self.assertEqual(len(bytes.fromhex(row['sourceSha256'])), 32)
                    retained = json.loads(raw)
                    table_literal(retained)
                    collections = {key:(len(child['tableEntries']) if isinstance(child, dict) else len(child))
                                   for key, child in retained['tableEntries'] if isinstance(child, (dict, list))}
                    self.assertEqual(row['collectionCounts'], collections)
            discovered = {p.relative_to(index.parent).as_posix() for p in (index.parent/'SourceFacts').glob('*.json')}
            self.assertEqual(declared, discovered)

    def test_normalized_facts_share_the_existing_schemas_and_export_only_literals(self):
        importers = {'geography':import_geography, 'transports':import_transports}
        for index in self.catalogs():
            document = json.loads(index.read_text(encoding='utf-8'))
            for family, row in document['normalized'].items():
                with self.subTest(family=family, catalog=index):
                    path = (index.parent/row['path']).resolve()
                    self.assertTrue(path.is_relative_to(index.parent.resolve()))
                    raw = path.read_bytes()
                    self.assertEqual(hashlib.sha256(raw).hexdigest(), row['canonicalSha256'])
                    facts = json.loads(raw)
                    self.assertEqual(row['counts'], {key:len(value) for key, value in facts.items()
                                                   if isinstance(value, list)})
                    importer = importers[family]
                    importer.validate(facts)
                    self.assertEqual(facts['client'], document['client'])
                    expected = dict(facts)
                    groups = importer.GROUPS if family == 'geography' else ('routes','excluded')
                    for group in groups:
                        expected[group] = {record['id']:record for record in facts[group]}
                    namespace = literal_namespace(importer.render(facts))
                    self.assertEqual(set(namespace.keys()), {'NavigationV2'+facts['client'].title()+family.title()+'Data'})
                    actual = next(iter(namespace.values()))
                    self.assertEqual(lua_shape(import_transports._plain(actual)), lua_shape(expected))
                    self.assertIsNone(namespace.LibAPRNavigationV2)

    def test_addon_loads_one_bounded_metadata_projection_per_discovered_catalog(self):
        scripts = [e.attrib['file'] for e in ET.parse(LIB/'LibAPRNavigation.xml').iter()
                   if e.tag.rsplit('}',1)[-1] == 'Script']
        for index in self.catalogs():
            document = json.loads(index.read_text(encoding='utf-8'))
            path = LIB/'Data'/document['client']/'Declarations/Catalog.lua'
            self.assertEqual(scripts.count(path.relative_to(LIB).as_posix()), 1)
            self.assertLessEqual(path.stat().st_size, 65536)
            self.assertFalse(document['runtimeAdmission'])
            namespace = literal_namespace(path.read_text(encoding='utf-8'))
            expected = {'NavigationV2'+document['client'].title()+'DeclarationsData':document}
            self.assertEqual(lua_shape(import_transports._plain(namespace)), lua_shape(expected))


if __name__ == '__main__':
    unittest.main()
