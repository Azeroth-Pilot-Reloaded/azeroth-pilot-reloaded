"""Discover the independent terrain contracts without importing older generators."""
from pathlib import Path
import importlib.util
import unittest


class TerrainGeneratorTests(unittest.TestCase):
    def test_generator_contracts(self):
        root = Path(__file__).resolve().parents[3] / 'Route-generator'
        if not (root/'tests/navigation_v2').is_dir():
            self.skipTest('Separate Route-generator checkout is not present')
        import sys
        sys.path.insert(0, str(root))
        try:
            for path in sorted((root / 'tests/navigation_v2').glob('test_*.py')):
                spec = importlib.util.spec_from_file_location('nav04_' + path.stem, path)
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                result = unittest.TestResult()
                unittest.defaultTestLoader.loadTestsFromModule(module).run(result)
                self.assertEqual(result.errors + result.failures, [], path.name)
        finally:
            sys.path.remove(str(root))
