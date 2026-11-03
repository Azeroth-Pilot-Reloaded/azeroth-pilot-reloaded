"""Both client manifests must expose the opt-in position dependency closure."""
from pathlib import Path
import unittest

from tools.validation.check_package import validate_runtime_files

ROOT = Path(__file__).resolve().parents[2]


class PositionManifestTests(unittest.TestCase):
    def test_both_client_closures_load_world_and_adapter_before_host(self):
        for game in ("Standard", "Camelot"):
            with self.subTest(game=game):
                references = validate_runtime_files(ROOT, ROOT / "APR.toc", game)
                loaded = [path.relative_to(ROOT).as_posix() for path in references]
                world = "APR-Core/libs/LibAPRNavigation-2.0/Localization/World.lua"
                adapter = "APR-Core/features/navigation/NavigationV2Position.lua"
                host = "APR-Core/features/navigation/NavigationV2.lua"
                core = "APR-Core/libs/LibAPRNavigation-2.0/Navigation.lua"
                for path in [world, adapter, host, core]:
                    self.assertEqual(references[(ROOT / path).resolve()], 1, f"Dependency not loaded once: {path}")
                self.assertLess(loaded.index(world), loaded.index(core))
                self.assertLess(loaded.index(adapter), loaded.index(host))
