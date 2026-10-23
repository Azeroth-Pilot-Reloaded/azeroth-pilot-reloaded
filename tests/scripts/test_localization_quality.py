"""Boundary coverage for safe exports, runtime format arguments and WoW tags."""

from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / ".github/scripts"))

import localization_quality as quality


class CatalogParsingTests(unittest.TestCase):
    def test_curseforge_table_initializer_is_accepted_without_allowing_setup_code(self):
        text = 'L = L or {}\nL["READY"] = "Bonjour"'
        self.assertEqual(quality.parse_catalog(text, "frFR"), {"READY": "Bonjour"})
        for initializer in ('L = os.getenv("secret")', 'L = L or {run()}', 'L = {}',
                            'L = L or {}\nrun()', 'L = L or {}\nL = L or {}'):
            with self.subTest(initializer=initializer), self.assertRaises(quality.CatalogParseError):
                quality.parse_catalog(initializer + '\nL["READY"] = "Bonjour"')

    def test_only_active_translated_entries_count(self):
        text = '''-- L["COMMENTED"] = "fallback"
--[=[ L["LONG_COMMENT"] = "fallback" ]=]
L["READY"] = "Bonjour"
L["EMPTY"] = ""
L["WHITESPACE"] = "  "
L["SAME"] = true
L["New Changelog"] = ""
L["Prev Changelog"] = ""
'''
        self.assertEqual(quality.parse_catalog(text, "frFR"), {
            "READY": "Bonjour", "SAME": "SAME", "New Changelog": "", "Prev Changelog": "",
        })

    def test_escaped_keys_utf8_bytes_long_strings_and_trailing_comments(self):
        text = r'''L["quote\" key"] = "D\195\169j\195\160 \"vu\"\\\n" -- trailing
L['single\' key'] = [=[
Première ligne
deuxième ]] ligne
]=]; L[ [=[long key]=] ] = "value"
'''
        self.assertEqual(quality.parse_catalog(text), {
            'quote" key': 'Déjà "vu"\\\n', "single' key": "Première ligne\ndeuxième ]] ligne\n",
            "long key": "value",
        })

    def test_empty_foreign_catalog_is_valid_but_empty_reference_fails(self):
        for text in ("", "\ufeff \n", '-- L["NO_TRANSLATION"] = ""', 'L["EMPTY"] = ""'):
            with self.subTest(text=text):
                self.assertEqual(quality.parse_catalog(text, "frFR", allow_empty=True), {})
                with self.assertRaises(quality.CatalogParseError):
                    quality.parse_catalog(text)

    def test_invalid_html_truncated_or_non_literal_exports_are_rejected(self):
        invalid = [
            '<html>Unavailable</html>', '<html>\nL["X"]="spoof"\n</html>',
            'L["A"] = "unterminated', 'L["A"] = [=[unterminated',
            'L["A"] = "bad\\999"', 'L["A"] = "first" .. "second"',
            'L["A"] = false', 'L["A"] = nil', 'L["A"] = os.getenv("secret")',
            'L["A"] = "one"\nL["A"] = "two"',
            'L["A"] = ""\nL["A"] = "two"', 'L[""] = "value"',
            'L["A"] = "one"\nalert("extra code")', '--[=[unterminated',
        ]
        for text in invalid:
            with self.subTest(text=text), self.assertRaises(quality.CatalogParseError):
                quality.parse_catalog(text, "frFR", allow_empty=True)


class PlaceholderTests(unittest.TestCase):
    def evaluate(self, english, translated):
        return quality.evaluate_catalogs({"enUS": {"KEY": english}, "frFR": {"KEY": translated}})["diagnostics"]

    def test_preserves_order_types_flags_width_precision_and_escaped_percent(self):
        self.assertEqual(self.evaluate("%s earns %08d / %+.2f%%", "%s gagne %d / %10.3f%%"), [])
        self.assertEqual(self.evaluate("%i", "%d"), [])
        self.assertEqual(quality.printf_parameters("%#x %q %02d %-12s %%"), (("x", "q", "d", "s"), []))
        self.assertEqual(quality.printf_parameters("%sname %ditems"), (("s", "d"), []))
        for english, translated in (("%s %d", "%d %s"), ("%s %d", "%s"),
                                    ("%d", "%s"), ("No parameter", "%s")):
            with self.subTest(english=english, translated=translated):
                findings = self.evaluate(english, translated)
                self.assertEqual([finding["code"] for finding in findings], ["placeholder_mismatch"])
                self.assertEqual(findings[0]["severity"], "error")

    def test_malformed_printf_parameters_in_a_formatted_value_fail(self):
        for translated in ("%1$s", "%*s", "%ld", "%s %Q", "%s %"):
            with self.subTest(translated=translated):
                findings = self.evaluate("%s", translated)
                self.assertIn("invalid_placeholder", [finding["code"] for finding in findings])

    def test_literal_percent_and_prose_are_not_printf_parameters(self):
        for english, translated in (("100%", "100%"), ("100% complete", "100% terminé"),
                                    ("50% of players", "50% des joueurs"),
                                    ("100%failure", "100%failure"),
                                    ("%s: 100% complete", "%s : 100% terminé"),
                                    ("%s: 100% complete", "%s : 100% réussi"),
                                    ("%s: 100% complete", "%s：100%已完成"),
                                    ("%s: 100% complete", "%s : 100%déjà"),
                                    ("At least 25% more", "Au moins 25% en plus")):
            with self.subTest(english=english):
                self.assertEqual(self.evaluate(english, translated), [])

    def test_date_percent_markers_do_not_become_numeric_format_arguments(self):
        for english, translated in (("%Y-%m-%d", "%d/%m/%Y"),
                                    ("Date: %Y-%m-%d at %H:%M", "Date : %d/%m/%Y à %H:%M"),
                                    ("%Y年%m月%d日", "%d/%m/%Y")):
            with self.subTest(english=english):
                self.assertEqual(quality.printf_parameters(english), ((), []))
                self.assertEqual(self.evaluate(english, translated), [])

    def test_real_localized_numeric_percent_prose_does_not_consume_format_arguments(self):
        phrases = {
            "FRENCH_EXPERIENCE": ("5% experience", "5% d'expérience"),
            "FRENCH_XP": ("10% additional XP", "10 % d'XP supplémentaires"),
            "SPANISH_HEALTH": ("30% health or less", "30% o menos salud"),
            "PORTUGUESE_EXPERIENCE": ("5% experience", "5% a experiência"),
            "GERMAN_HEALTH": ("a mob at 5% health", "einen 5 %igen Mob"),
            "NBSP_HEALTH": ("a mob at 5% health", "einen 5\u00a0%igen Mob"),
            "NBSP_XP": ("10% additional XP", "10\u00a0% d'XP supplémentaires"),
        }
        result = quality.evaluate_catalogs({
            "enUS": {key: source for key, (source, _translation) in phrases.items()},
            "frFR": {key: translation for key, (_source, translation) in phrases.items()},
        })
        self.assertEqual(result["diagnostics"], [])
        self.assertEqual(quality.printf_parameters("5%s and 5%d"), (("s", "d"), []))
        self.assertEqual(self.evaluate("Tame %s", "Dompter %")[0]["code"], "invalid_placeholder")
        self.assertIn("placeholder_mismatch", [item["code"] for item in self.evaluate("Tame %s", "Dompter %")])

    def test_source_format_errors_are_reported_once_in_reference_locale(self):
        findings = self.evaluate("%s %", "%s")
        self.assertEqual([(item["locale"], item["code"]) for item in findings], [("enUS", "invalid_placeholder")])
        for text in ("%1$s", "%*s", "%ld", "%10Q"):
            with self.subTest(text=text):
                self.assertTrue(quality.printf_parameters(text)[1])


class MarkupTests(unittest.TestCase):
    def test_balanced_colors_links_textures_atlases_and_escaped_pipes(self):
        text = "|| literal |cffaabbcc|Hitem:123|h[Name]|h|r |TInterface\\Icons\\Test:16|t |Aatlas:16:16|a"
        counts, issues = quality.wow_markup(text)
        self.assertEqual(issues, [])
        self.assertEqual(dict(counts), {"color": 1, "link": 1, "texture": 1, "atlas": 1})
        self.assertEqual(quality.wow_markup("||cBAD ||r ||H ||h ||T ||t ||A ||a"), ({}, []))
        self.assertEqual(quality.wow_markup("|cnHIGHLIGHT_FONT_COLOR:text|r")[1], [])

    def test_unclosed_or_orphan_markup_fails(self):
        invalid = ("|cffff0000red", "red|r", "|c12345red|r", "|Hitem:1|h[label]",
                   "|Hitem:1|h|Hitem:2|hlabel|h", "orphan|h", "|Ticon:16", "orphan|t",
                   "|Aatlas:16", "orphan|a", "|T|t", "|A|a", "|Ticon||t", "|H|hlabel|h")
        for text in invalid:
            with self.subTest(text=text):
                self.assertTrue(quality.wow_markup(text)[1])

    def test_missing_whole_markup_pair_is_detected_even_when_target_is_balanced(self):
        findings = quality.evaluate_catalogs({
            "enUS": {"KEY": "|cffff0000|Ticon:16|tLabel|r"}, "frFR": {"KEY": "Libellé"},
        })["diagnostics"]
        self.assertEqual([item["code"] for item in findings], ["markup_mismatch"])

    def test_localized_hyperlink_label_and_color_choice_are_allowed(self):
        findings = quality.evaluate_catalogs({
            "enUS": {"KEY": "|cffff0000|Hitem:1|h[Name]|h|r"},
            "frFR": {"KEY": "|cff00ff00|Hitem:1|h[Nom]|h|r"},
        })["diagnostics"]
        self.assertEqual(findings, [])


class CoverageTests(unittest.TestCase):
    def test_coverage_counts_reference_keys_only_and_missing_translation_is_error(self):
        result = quality.evaluate_catalogs({
            "enUS": {"A": "A", "B": "B"}, "frFR": {"A": "Un", "EXTRA": "unused"}, "deDE": {},
        })
        rows = {row["locale"]: row for row in result["coverage"]}
        self.assertEqual((rows["frFR"]["total"], rows["frFR"]["translated"], rows["frFR"]["missing"], rows["frFR"]["percent"]), (2, 1, 1, 50.0))
        self.assertEqual(rows["deDE"]["translated"], 0)
        self.assertEqual(len(result["diagnostics"]), 3)
        self.assertTrue(all(item["severity"] == "error" for item in result["diagnostics"]))
        self.assertTrue(all(item["line"] == 0 and item["path"] == f'CurseForge/{item["locale"]}' for item in result["diagnostics"]))

    def test_used_key_scope_only_limits_diagnostics_and_does_not_inflate_coverage(self):
        result = quality.evaluate_catalogs({
            "enUS": {"USED": "%s", "OLD": "%d", "MISSING": "Text"},
            "frFR": {"USED": "%d", "OLD": "%s"},
        }, used_keys={"USED", "UNKNOWN"})
        self.assertEqual([(item["key"], item["code"]) for item in result["diagnostics"]], [("USED", "placeholder_mismatch")])
        self.assertEqual(next(row for row in result["coverage"] if row["locale"] == "frFR")["missing"], 1)

    def test_no_reference_is_an_error_and_zero_keys_have_complete_coverage(self):
        with self.assertRaises(quality.CatalogParseError):
            quality.evaluate_catalogs({"frFR": {}})
        self.assertEqual(quality.evaluate_catalogs({"enUS": {}, "frFR": {}})["coverage"][0]["percent"], 100.0)


class NavigationCatalogTests(unittest.TestCase):
    def test_own_library_locales_are_validated_with_real_file_and_line(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / quality.NAVIGATION_PATH
            path.parent.mkdir(parents=True)
            path.write_text('''local Lib = LibStub("LibAPRNavigation-1.0")
Lib.locales = {
    enUS = { ["TRAVEL"] = "Go to %s", ["LABEL"] = "Label" },
    frFR = { ["TRAVEL"] = "Aller à %d" },
}
Lib.locales.enGB = Lib.locales.enUS
''', encoding="utf-8")
            result = quality.evaluate_local_catalogs(directory)
        self.assertEqual([(item["code"], item["line"]) for item in result["diagnostics"]],
                         [("missing_translation", 4), ("placeholder_mismatch", 4)])
        self.assertTrue(all(item["path"] == quality.NAVIGATION_PATH for item in result["diagnostics"]))
        self.assertTrue(all(row["source"] == "LibAPRNavigation" for row in result["coverage"]))

    def test_absent_library_in_historical_base_is_valid(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(quality.evaluate_local_catalogs(directory), {"coverage": [], "diagnostics": []})

    def test_removed_locale_table_is_still_checked_if_addon_ships_that_language(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / quality.NAVIGATION_PATH
            path.parent.mkdir(parents=True)
            path.write_text('Lib.locales = { enUS = { ["A"] = "A" } }', encoding="utf-8")
            locales = Path(directory) / "APR-Core/locales"
            locales.mkdir()
            (locales / "frFR.lua").write_text("-- packaged locale", encoding="utf-8")
            result = quality.evaluate_local_catalogs(directory)
        french = next(row for row in result["coverage"] if row["locale"] == "frFR")
        self.assertEqual((french["translated"], french["missing"]), (0, 1))
        self.assertEqual([(item["locale"], item["code"]) for item in result["diagnostics"]],
                         [("frFR", "missing_translation")])

    def test_current_repository_navigation_translations_have_no_quality_errors(self):
        result = quality.evaluate_local_catalogs(Path(__file__).resolve().parents[2])
        self.assertGreater(len(result["coverage"]), 1)
        self.assertEqual(result["diagnostics"], [])

    def test_duplicate_or_truncated_navigation_tables_are_rejected(self):
        for text in ('Lib.locales = { enUS = { ["A"]="one", ["A"]="two" } }',
                     'Lib.locales = { enUS = { ["A"]="one" }',
                     'Lib.locales = { enUS = { ["A"] = someFunction() } }'):
            with self.subTest(text=text), self.assertRaises(quality.CatalogParseError):
                quality._navigation_catalogs(text)


if __name__ == "__main__":
    unittest.main()
