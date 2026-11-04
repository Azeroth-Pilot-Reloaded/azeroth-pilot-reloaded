"""Calibration contracts use independent, invented costs and observations."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


class CalibrationTests(unittest.TestCase):
    def test_contracts(self):
        paths = sorted(Path(__file__).parent.glob("*_test.lua"))
        self.assertTrue(paths, "No calibration contracts discovered")
        for path in paths:
            with self.subTest(suite=path.name):
                LuaRuntime(unpack_returned_tuples=True).execute(
                    path.read_text(encoding="utf-8"), name="@" + path.as_posix()
                )
