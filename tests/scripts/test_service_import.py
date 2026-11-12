"""The explicit importer operates only on synthetic temporary catalogs."""
import contextlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
TOOL = ROOT / "APR-Core/libs/LibAPRNavigation-1.0/tools/import_services.py"
spec = importlib.util.spec_from_file_location("service_import", TOOL)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ServiceImportTests(unittest.TestCase):
    def test_safe_import_names_expansions_and_placeholder_rejection(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            base = root / "ZygorGuidesViewer"
            for folder in ("Data-Retail", "Libs-Retail/LibRover-1.0"):
                (base / folder).mkdir(parents=True, exist_ok=True)
            (base / "Data-Retail/NPCData.lua").write_text('''
ZGV._NPCData = {
 ["TrainerAlchemy"] = [[
 -- MIDNIGHT --
 901=sB|m501|x20|y30 -- Fictional Town (Test Alchemist)
 902=sB|m501|x25|y35|cdo_not_execute() -- Fictional Town (Restricted)
 ]],
 ["Flight master"] = [[
 903=sB|m501|x10|y10
 ]],
}
''', encoding="utf-8")
            (base / "Libs-Retail/LibRover-1.0/data.lua").write_text(
                '["Fictional Town"] = {[0]=501, [1]=502}', encoding="utf-8")
            (base / "Libs-Retail/LibRover-1.0/data_inns.lua").write_text('''
["Fictional Town"]={
 {npcid=0,x=10,y=10},
 {npcid=904,npc="Test Innkeeper",x=12,y=14,faction="B"},
}
''', encoding="utf-8")
            compiler = module.Compiler()
            compiler.zygor(root, "retail")
            output = root / "compiled"
            with contextlib.redirect_stdout(io.StringIO()):
                compiler.write(output, {"records": {}})
            lua = (output / "retail/Services.lua").read_text(encoding="utf-8")
            self.assertIn('name="Test Alchemist"', lua)
            self.assertIn('mapName="Fictional Town"', lua)
            self.assertIn('skillName="Alchemy"', lua)
            self.assertIn('expansionName="Midnight"', lua)
            self.assertIn('name="Test Innkeeper"', lua)
            self.assertNotIn("902", lua)
            self.assertNotIn("903", lua)
            self.assertNotIn("npcID=0", lua)
            self.assertNotIn("source", lua.lower())
            self.assertNotIn("provenance", lua.lower())
            self.assertNotIn("do_not_execute", lua)
            self.assertEqual(sorted(p.name for p in output.rglob("*") if p.is_file()), ["Services.lua", "Services.lua"])

    def test_deduplication_preserves_distinct_spawns_and_filters(self):
        compiler = module.Compiler()
        record = dict(service="repair", id=7, mapID=501, x=20, y=30, faction="A")
        compiler.add("forever", record, "first")
        compiler.add("forever", dict(record, name="Test Smith"), "second")
        self.assertEqual(len(compiler.records["forever"]), 1)
        self.assertEqual(next(iter(compiler.records["forever"].values()))["name"], "Test Smith")
        compiler.add("forever", dict(record, x=25), "third")
        compiler.add("forever", dict(record, faction="H"), "fourth")
        self.assertEqual(len(compiler.records["forever"]), 3)
        compiler.add("forever", dict(record, x=101), "invalid")
        self.assertEqual(len(compiler.records["forever"]), 3)
