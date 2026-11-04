"""Execute movement contracts in fresh Lua 5.1 runtimes."""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


class MovementTests(unittest.TestCase):
    def run_contract(self, name):
        path = Path(__file__).with_name(name + "_test.lua")
        LuaRuntime(unpack_returned_tuples=True).execute(
            path.read_text(encoding="utf-8"), name="@" + path.as_posix()
        )

    def test_profile(self):
        self.run_contract("profile")

    def test_observation(self):
        self.run_contract("observation")

    def test_planner(self):
        self.run_contract("planner")

    def test_oracle(self):
        self.run_contract("oracle")

    def test_host_snapshot(self):
        self.run_contract("host_snapshot")

    def test_host_lifecycle(self):
        self.run_contract("host_lifecycle")

    def test_host_relocation(self):
        self.run_contract("host_relocation")

    def test_host_loading(self):
        self.run_contract("host_loading")

    def test_host_relocation_dirty(self):
        self.run_contract("host_relocation_dirty")

    def test_host_unconfirmed_dirty(self):
        self.run_contract("host_unconfirmed_dirty")
