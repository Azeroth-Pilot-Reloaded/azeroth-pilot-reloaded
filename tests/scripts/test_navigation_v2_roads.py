"""Discover the isolated roads provider contracts and exporter tests."""
from pathlib import Path
import importlib.util
import unittest


ROOT = Path(__file__).resolve().parents[2]


def load_tests(loader, tests, pattern):
    family = ROOT / 'tests/lua/navigation_v2_roads'
    for path in sorted(family.glob('test_*.py')):
        spec = importlib.util.spec_from_file_location('roads_' + path.stem, path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        tests.addTests(loader.loadTestsFromModule(module))
    path = ROOT.parent / 'Route-generator/tests/navigation_v2/test_export_roads.py'
    spec = importlib.util.spec_from_file_location('road_export_contracts', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    tests.addTests(loader.loadTestsFromModule(module))
    return tests
