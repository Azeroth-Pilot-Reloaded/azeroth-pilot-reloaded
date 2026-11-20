"""Run the generator's integration contracts against this checkout when available."""
import importlib.util
import os
from pathlib import Path
import unittest


APR = Path(__file__).resolve().parents[2]
GENERATOR = Path(os.environ.get("APR_ROUTE_GENERATOR", APR.parent / "Route-generator"))
suite_file = GENERATOR / "tools/apr-terrain/tests/test_tool_contracts.py"
if not suite_file.is_file():
    if os.environ.get("APR_TERRAIN_BIN"):
        raise FileNotFoundError(f"Point APR_ROUTE_GENERATOR to the checkout containing {suite_file.name}")
    raise unittest.SkipTest("Native tool contracts live in the Route-generator checkout")

spec = importlib.util.spec_from_file_location("apr_native_tool_contracts", suite_file)
contracts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(contracts)
TerrainToolsTests = contracts.TerrainToolsTests
