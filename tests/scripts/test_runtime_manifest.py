"""Every owned core Lua source must be reachable through the client manifests."""
from pathlib import Path
import unittest

from tools.validation.check_package import read_manifest

ROOT = Path(__file__).resolve().parents[2]


def visit_manifest(path, reached):
    path = path.resolve()
    if path in reached:
        return
    reached.add(path)
    if path.suffix != ".xml":
        return
    for element in read_manifest(path).iter():
        if element.tag.rsplit("}", 1)[-1] not in ("Include", "Script"):
            continue
        reference = element.attrib.get("file")
        if reference:
            relative = Path(reference.replace("\\", "/"))
            nested = path.parent / relative
            visit_manifest(nested if nested.is_file() else ROOT / relative, reached)


def loaded_core_sources(toc):
    reached = set()
    for line in toc.read_text(encoding="utf-8-sig").splitlines():
        entry = line.strip().replace("\\", "/")
        if entry.startswith("APR-Core/"):
            visit_manifest(ROOT / entry, reached)
    return reached


class RuntimeManifestTests(unittest.TestCase):
    def test_all_owned_core_sources_are_loaded(self):
        sources = {p.resolve() for p in (ROOT / "APR-Core").rglob("*.lua")
                   if "libs" not in p.relative_to(ROOT).parts}
        tocs = sorted(ROOT.glob("APR*.toc"))
        self.assertTrue(tocs)
        for toc in tocs:
            with self.subTest(toc=toc.name):
                reached = loaded_core_sources(toc)
                self.assertEqual(sorted(p.relative_to(ROOT).as_posix() for p in sources - reached), [],
                                 "Owned runtime Lua files must be loaded by the TOC or its XML includes")
