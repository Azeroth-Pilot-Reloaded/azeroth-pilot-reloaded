import json
import os
from pathlib import Path
from struct import pack
from subprocess import CalledProcessError
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from tools.generate_retail_graphs import enable_recovery, prepare_results
from tools.terrain_ui.casc_root import RootFileIds
from tools.terrain_ui.job import DEFAULTS, Generation


class TerrainRecoveryTests(unittest.TestCase):
    def setUp(self):
        directory = TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        temporary = Path(directory.name)
        self.world = {"id": 601, "name": {"en": "Fixture"}, "tiles": {"1_1": 1, "1_2": 2, "1_3": 3, "1_4": 4}}
        client = {"id": "fixture", "product": "wow", "build": "12.0.0.1", "buildKey": "fixture-key"}
        with patch("tools.terrain_ui.job.WORKSPACE", temporary):
            self.job = Generation(client, {"worlds": {"601": self.world}, "tree": []}, {}, DEFAULTS)
        self.job.world = self.world
        self.geometry = temporary / "geometry"
        self.geometry.mkdir()

    def extract(self, directory, tiles):
        entries = []
        for y, issues in tiles.items():
            file = f"1_{y}.json"
            (directory / file).write_text(json.dumps({"triangles": [], "textureCells": [],
                "complete": not issues, "errors": issues}), encoding="utf-8")
            entries.append({"x": 1, "y": y, "file": file})
        (directory / "metadata.json").write_text('{"buildKey":"fixture-key"}', encoding="utf-8")
        (directory / "index.json").write_text(json.dumps({"product": "wow", "build": "12.0.0.1",
            "metadata": "metadata.json", "maps": [{"id": 601, "tiles": entries}]}), encoding="utf-8")

    def test_retries_temporary_tiles_and_preserves_structural_and_missing_errors(self):
        long_error = "x" * 1000
        model_error = "WMO 7 doodad 8: model FileDataID 9: M3DT collision: " + long_error
        self.extract(self.geometry, {1: [], 2: ["[WinError 32] archive sharing violation"], 3: [model_error]})
        _, accepted, errors = self.job.inspect_extraction(self.geometry, set(self.world["tiles"]))
        self.job.report_tile_errors(errors, "extraction")
        self.assertEqual(set(accepted), {"1_1"})

        def retry(arguments, _env):
            self.assertEqual(arguments[-2:], ["--tile", "1_2"])
            self.extract(arguments[-3], {2: []})

        with patch.object(self.job, "command", side_effect=retry) as replay:
            self.job.recover_extraction(["reader"], {}, self.geometry, accepted, errors)
        replay.assert_called_once()
        self.assertEqual(accepted["1_2"]["file"], "retry/1_2.json")
        self.assertEqual(set(accepted), {"1_1", "1_2"})
        self.assertEqual(errors, {"1_3": [model_error], "1_4": ["No geometry emitted for the requested tile"]})
        self.assertIn(model_error, (self.job.folder / "generation.log").read_text(encoding="utf-8"))

    def test_only_unfinished_maps_are_available_for_retry(self):
        self.job.ids = [601, 602, 603]
        self.job.results = [{"world": 601, "status": "complete"}, {"world": 602, "status": "partial"},
                            {"world": 603, "status": "failed"}]
        self.job.state, self.job.phase = "partial", "finished"
        self.assertEqual(self.job.retry_worlds(), set())
        self.job.finished = 1
        self.assertEqual(self.job.retry_worlds(), {602, 603})

    def test_capacity_retry_keeps_geometry_and_uses_next_supported_resolution(self):
        failures = [ValueError("map 601: graph fields: destination page (1, 2) local portal index 4390 exceeds 4094"),
                    ValueError("map 601: surface fields: wire integer 262163 exceeds 3 digits"), None]
        self.job.settings = DEFAULTS | {"cells": 256}
        args = ["generator", "--geometry", self.geometry]
        with patch.object(self.job, "command", side_effect=failures) as command:
            self.assertEqual(self.job.generate_pack(args, {}), 64)
        self.assertEqual([call.args[0] for call in command.call_args_list],
                         [[*args, "--cells", cells] for cells in ("256", "128", "64")])

    def test_generation_does_not_retry_other_failures_or_go_below_minimum_resolution(self):
        for settings, message in ((DEFAULTS, "map 601: geometry is incomplete"),
                                  (DEFAULTS | {"cells": 64}, "surface fields: wire integer 262163 exceeds 3 digits")):
            self.job.settings = settings
            with patch.object(self.job, "command", side_effect=ValueError(message)) as command:
                with self.assertRaisesRegex(ValueError, message):
                    self.job.generate_pack(["generator"], {})
            command.assert_called_once()

    def test_terminal_runner_uses_same_capacity_recovery(self):
        args = SimpleNamespace(generator=self.geometry)
        logfile = self.geometry / "run.log"
        attempts = []

        def run(command, path):
            attempts.append(command)
            if command[-1] == "128":
                path.write_text("apr-terrain: map 601: graph fields: local portal index 4100 exceeds 4094\n",
                                encoding="utf-8")
                raise CalledProcessError(1, command)

        engine = SimpleNamespace(run=run)
        binaries = self.geometry / "bin"
        with patch.dict(os.environ, {"APR_CASCLIB_DLL": "test.dll"}), patch(
                "tools.generate_retail_graphs.prepare_binaries", return_value=(binaries, None)):
            enable_recovery(args, self.geometry, engine)
        base = [binaries / "apr-terrain.exe", "generate", "--geometry", self.geometry, "--cells"]
        engine.run([*base, 128], logfile)
        self.assertEqual(attempts, [[*base, "128"], [*base, "64"]])
        self.assertIn("sur toutes les tuiles", logfile.read_text(encoding="utf-8"))

    def test_terminal_runner_retries_cached_graph_that_omits_transitions(self):
        manifest = self.geometry / "packs/601/PACK.json"
        manifest.parent.mkdir(parents=True)
        manifest.touch()
        record = self.geometry / "results/601.json"
        record.parent.mkdir()
        record.write_text(json.dumps({"status": "complete", "expectedTiles": 4, "packedTiles": 4,
            "statistics": {"unrepresentableDirectedEdges": 11},
            "pack": str(manifest.parent.relative_to(self.geometry)), "packSha256": "fixture-hash"}), encoding="utf-8")
        engine = SimpleNamespace(digest=lambda path: "fixture-hash",
                                 write=lambda path, data: path.write_text(json.dumps(data), encoding="utf-8"))
        dry_run = prepare_results(self.geometry, engine, {601: self.world}, None, restore=False)
        self.assertEqual(dry_run[601]["status"], "partial")
        self.assertEqual(json.loads(record.read_text(encoding="utf-8"))["status"], "complete")
        prepare_results(self.geometry, engine, {601: self.world}, None, restore=True)
        self.assertEqual(json.loads(record.read_text(encoding="utf-8"))["status"], "partial")


class TerrainRootIndexTests(unittest.TestCase):
    def root(self, version):
        def group(flags, deltas):
            size = len(deltas)
            header = (pack("<III", size, flags, 16) if version == 1
                      else pack("<4IB", size, 16, flags, 0, 0))
            keys = b"k" * (size * 16)
            name_hashes = b"h" * (size * 8) if not flags else b""
            return header + pack(f"<{size}I", *deltas) + keys + name_hashes

        return (pack("<4s4I", b"TSFM", 20, version, 4, 2) + group(0x10000000, (7, 3))
                + group(0, (1, 10)))

    def test_complete_root_distinguishes_unregistered_models_from_unreadable_models(self):
        for version in (1, 2):
            root = RootFileIds(self.root(version))
            self.assertTrue(all(key in root for key in (1, 7, 11, 12)))
            self.assertTrue(all(key not in root for key in (2, 6, 8, 10, 13)))

    def test_cannot_prove_absence_from_truncated_or_inconsistent_root(self):
        complete = self.root(2)
        for invalid in (complete[:15], complete[:-20], complete + b"extra", self.root(3),
                        complete[:12] + pack("<I", 5) + complete[16:]):
            with self.assertRaises(ValueError):
                RootFileIds(invalid)
