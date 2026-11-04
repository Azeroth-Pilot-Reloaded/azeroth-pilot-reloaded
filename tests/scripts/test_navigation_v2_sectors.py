"""Run the new offline sector exporter without loading other generator suites."""
from pathlib import Path
import importlib.util
import sys
import unittest


class SectorGeneratorTests(unittest.TestCase):
    def test_generator_contracts(self):
        root = Path(__file__).resolve().parents[3] / 'Route-generator'
        if not root.is_dir():
            self.skipTest('Separate Route-generator checkout is not present')
        sys.path.insert(0, str(root))
        try:
            for name in ('sectors','routing'):
                path = root / ('tests/navigation_v2/test_'+name+'.py')
                spec = importlib.util.spec_from_file_location('nav07_'+name, path)
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                result = unittest.TestResult()
                unittest.defaultTestLoader.loadTestsFromModule(module).run(result)
                self.assertEqual(result.errors + result.failures, [])
        finally:
            sys.path.remove(str(root))
