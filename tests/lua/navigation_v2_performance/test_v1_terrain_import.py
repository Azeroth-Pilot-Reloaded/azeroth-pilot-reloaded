"""Standard APR discovery of the public synthetic V1-terrain/V2-factory examples."""
import importlib.util
from pathlib import Path
import sys
from unittest.mock import patch

from tests.lua.navigation_v2_sectors.test_export import exporter


def load_tests(loader, tests, pattern):
    root = Path(__file__).resolve().parents[3].parent / 'Route-generator'
    importer, roads, sectors = exporter('import_terrain'), exporter('import_roads'), exporter()
    spec = importlib.util.spec_from_file_location(
        'synthetic_v1_terrain_factory_contracts', root / 'tests/navigation_v2/test_import_terrain.py')
    module = importlib.util.module_from_spec(spec)
    with patch.dict(sys.modules, {'tools.navigation_v2.import_terrain': importer,
                                 'tools.navigation_v2.import_roads': roads,
                                 'tools.navigation_v2.sectors': sectors}):
        spec.loader.exec_module(module)
    return loader.loadTestsFromModule(module)
