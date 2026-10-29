"""Runtime companion strings obey the same contract in every declared locale."""

from pathlib import Path
import re
import sys
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".github/scripts"))

import localization_quality as quality


class PartyFinderLocalizationTests(unittest.TestCase):
    def test_declared_locales_cover_companion_strings_and_preserve_formats(self):
        manifest = ROOT / "APR-Core/locales/locales.xml"
        paths = [manifest.parent / node.attrib["file"] for node in ET.parse(manifest).getroot()
                 if node.tag.rsplit("}", 1)[-1] == "Script"]
        self.assertTrue(paths, "The locale manifest must declare its runtime dictionaries")
        catalogs = {}
        for path in paths:
            # Initialization and packager directives are outside the literal catalog.
            assignments = "\n".join(line for line in path.read_text(encoding="utf-8-sig").splitlines()
                                    if re.match(r'^L\["GF_', line))
            catalogs[path.stem] = quality.parse_catalog(assignments, path.stem)
        reference = catalogs["enUS"]
        for locale, catalog in catalogs.items():
            with self.subTest(locale=locale):
                self.assertEqual(set(catalog), set(reference))
            for key, value in catalog.items():
                with self.subTest(locale=locale, key=key):
                    self.assertTrue(value.strip())
                    self.assertEqual(quality.printf_parameters(value, formatted=True),
                                     quality.printf_parameters(reference[key], formatted=True))
                    self.assertEqual(value.count("\n"), reference[key].count("\n"))
                    markup, issues = quality.wow_markup(value)
                    self.assertEqual(issues, [])
                    self.assertEqual(markup, quality.wow_markup(reference[key])[0])
