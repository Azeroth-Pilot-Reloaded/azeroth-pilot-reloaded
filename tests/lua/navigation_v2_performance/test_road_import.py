"""Discover the synthetic road importer/factory contracts in the standard suite.

The same tests also run directly in Route-generator. Loading that owned test
module avoids duplicating invented fixtures or expected paths across projects.
No V1 runtime or maintained network is loaded.
"""
import importlib.util
from pathlib import Path
import sys
from unittest.mock import patch

from tests.lua.navigation_v2_sectors.test_export import exporter


def load_tests(loader, tests, pattern):
    root = Path(__file__).resolve().parents[3].parent / 'Route-generator'
    importer, sectors = exporter('import_roads'), exporter()
    spec = importlib.util.spec_from_file_location(
        'synthetic_road_factory_contracts', root / 'tests/navigation_v2/test_import_roads.py')
    module = importlib.util.module_from_spec(spec)
    with patch.dict(sys.modules, {'tools.navigation_v2.import_roads': importer,
                                 'tools.navigation_v2.sectors': sectors}):
        spec.loader.exec_module(module)
    return loader.loadTestsFromTestCase(module.RoadImportTests)
