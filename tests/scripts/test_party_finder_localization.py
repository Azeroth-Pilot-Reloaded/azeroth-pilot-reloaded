"""Packager locale bindings and recorded companion export contracts, offline."""

from pathlib import Path
import re
import sys
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".github/scripts"))

import localization_quality as quality
import localization_source as source


EXPORTS = ROOT / "tests/fixtures/companion_localization"


def declared_paths():
    manifest = ROOT / "APR-Core/locales/locales.xml"
    return [manifest.parent / node.attrib["file"] for node in ET.parse(manifest).getroot()
            if node.tag.rsplit("}", 1)[-1] == "Script"]


class PartyFinderLocalizationTests(unittest.TestCase):
    def assert_catalog_contract(self, catalogs):
        self.assertIn("enUS", catalogs)
        reference = catalogs["enUS"]
        self.assertTrue(reference, "A real English companion catalog is required")
        for locale, catalog in catalogs.items():
            with self.subTest(locale=locale):
                self.assertEqual(set(catalog), set(reference))
            for key, value in catalog.items():
                with self.subTest(locale=locale, key=key):
                    self.assertTrue(value.strip())
                    parameters, errors = quality.printf_parameters(value, formatted=True)
                    self.assertEqual(errors, [])
                    self.assertEqual(parameters, quality.printf_parameters(reference[key], formatted=True)[0])
                    self.assertEqual(value.count("\n"), reference[key].count("\n"))
                    markup, issues = quality.wow_markup(value)
                    self.assertEqual(issues, [])
                    self.assertEqual(markup, quality.wow_markup(reference[key])[0])

    def test_declared_locales_cover_companion_strings_and_preserve_formats(self):
        paths = declared_paths()
        self.assertTrue(paths, "The locale manifest must declare its runtime dictionaries")
        catalogs = {}
        for path in paths:
            # CurseForge expands source directives only when packaging. Recorded
            # TableAdditions exports keep the actual multilingual format/markup
            # assertions executable offline instead of parsing an empty stub.
            assignments = "\n".join(line for line in path.read_text(encoding="utf-8-sig").splitlines()
                                    if re.match(r'^L\["GF_', line))
            if not assignments:
                assignments = (EXPORTS / path.name).read_text(encoding="utf-8-sig")
            catalogs[path.stem] = quality.parse_catalog(assignments, path.stem)
        self.assert_catalog_contract(catalogs)
        reference = catalogs["enUS"]
        used = {entry["key"] for entry in source.scan_sources(ROOT)["references"]
                if entry["key"].startswith("GF_")}
        self.assertTrue(used)
        self.assertEqual(used - set(reference), set(), "New runtime keys need a refreshed CurseForge export")

    def test_source_locale_bindings_match_the_declared_packager_languages(self):
        paths = declared_paths()
        self.assertEqual(len(paths), len({path.stem for path in paths}))
        for path in paths:
            with self.subTest(locale=path.stem):
                text = path.read_text(encoding="utf-8-sig")
                declarations = re.findall(r'--@localization\((.*?)\)@', text)
                self.assertEqual(len(declarations), 1)
                options = dict(re.findall(r'([\w-]+)="([^"]*)"', declarations[0]))
                self.assertEqual(options, {"locale": path.stem, "format": "lua_additive_table",
                                           "handle-unlocalized": "ignore"})
                self.assertRegex(text, r'NewLocale\("APR",\s*"' + re.escape(path.stem) + r'"')
                self.assertTrue((EXPORTS / path.name).is_file())

    def test_export_contract_accepts_localized_prose_and_rejects_broken_data(self):
        reference = {"GF_EXAMPLE": "Count %d\n|cffffffff%s|r", "GF_LABEL": "Ready"}
        translated = {"GF_EXAMPLE": "Nombre %d\n|cffffffff%s|r", "GF_LABEL": "Prêt"}
        self.assert_catalog_contract({"enUS": reference, "frFR": translated})
        broken = {
            "missing key": {"GF_LABEL": "Prêt"},
            "blank string": {**translated, "GF_LABEL": " "},
            "wrong parameter": {**translated, "GF_EXAMPLE": "Nombre %s\n|cffffffff%s|r"},
            "missing newline": {**translated, "GF_EXAMPLE": "Nombre %d |cffffffff%s|r"},
            "unclosed color": {**translated, "GF_EXAMPLE": "Nombre %d\n|cffffffff%s"},
            "changed markup": {**translated, "GF_EXAMPLE": "Nombre %d\n%s"},
        }
        # Use an independent TestCase: subTest inside the contract helper must
        # propagate failures here rather than record them on this running test.
        checker = PartyFinderLocalizationTests()
        for label, catalog in broken.items():
            with self.subTest(case=label), self.assertRaises(AssertionError):
                checker.assert_catalog_contract({"enUS": reference, "frFR": catalog})
