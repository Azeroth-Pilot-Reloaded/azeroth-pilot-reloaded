"""Real package closure for both supported clients, without guide fixtures."""
from pathlib import Path
import unittest

from tools.validation.check_package import validate_runtime_files

ROOT = Path(__file__).resolve().parents[2]


class ConditionsManifestTests(unittest.TestCase):
    def test_condition_dependencies_precede_their_consumers(self):
        for game in ("Standard", "Camelot"):
            with self.subTest(game=game):
                references = validate_runtime_files(ROOT, ROOT / "APR.toc", game)
                loaded = [path.relative_to(ROOT).as_posix() for path in references]
                core = "APR-Core/libs/LibAPRNavigation-2.0/Conditions.lua"
                graph = "APR-Core/libs/LibAPRNavigation-2.0/Graph.lua"
                adapter = "APR-Core/features/navigation/NavigationV2Conditions.lua"
                host = "APR-Core/features/navigation/NavigationV2.lua"
                for path in (core, graph, adapter, host):
                    self.assertEqual(references[(ROOT / path).resolve()], 1, f"Dependency not loaded once: {path}")
                self.assertLess(loaded.index(core), loaded.index(graph))
                self.assertLess(loaded.index(adapter), loaded.index(host))

    def test_prepared_witness_cannot_bypass_required_phase(self):
        from tests.lua.navigation_v2_sectors.test_prepared import prepared

        for phase, expected in (("live", b"complete"), ("other", b"no_path"), (None, b"unknown")):
            with self.subTest(phase=phase):
                lua, _, _ = prepared([[0, 0, 0]] * 3, [[1, 2, 1], [2, 3, 1], [1, 3, 10]], node_limit=1)
                lua.globals().observedPhase = phase.encode() if phase else None
                lua.execute(b"""
                    source.requirements={phase='live'}
                    planner=assert(ns.LibAPRNavigationV2.New(source,{
                        clock=function()return 0 end,profileClock=options.profileClock,
                        conditionObservation={sequence=1,worldState='ready',phase=observedPhase}}))
                """)
                result = lua.globals().finish(lua.globals().plan(1, 3))
                self.assertEqual(result[b"status"], expected)
                self.assertFalse(result[b"diagnostics"][b"certificateComplete"])
                if phase == "live":
                    self.assertEqual(result[b"estimatedSeconds"], .002)
                    self.assertGreater(result[b"diagnostics"][b"expanded"], 0)
