import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / ".github/scripts"))

from localization_source import analyze_sources, scan_sources, tokenize_lua


class LuaLocalizationTokenizerTests(unittest.TestCase):
    def test_comments_long_strings_quotes_and_positions(self):
        source = '-- L["COMMENT"]\n--[=[ L["BLOCK"] ]=]\nL[\'A\\\'B\'] .. [==[\nlong ]=] text\n]==]'
        tokens = tokenize_lua(source)
        strings = [token for token in tokens if token.kind == "string"]
        self.assertEqual([token.value for token in strings], ["A'B", "long ]=] text\n"])
        self.assertEqual([token.line for token in strings], [3, 3])
        for token in tokens:
            self.assertTrue(source[token.offset:token.end])
            self.assertGreater(token.end, token.offset)

    def test_lua_escapes_and_utf8_byte_escapes(self):
        source = r'''"D\195\169j\xC3\xA0 \u{1F600}\n\t\\\"" 'a\z  
        b' '' 傷'''
        strings = [token.value for token in tokenize_lua(source) if token.kind == "string"]
        self.assertEqual(strings, ['Déjà 😀\n\t\\"', 'ab', ''])

    def test_escaped_newline_updates_following_locations(self):
        tokens = tokenize_lua('"a\\\r\nb"\nL["KEY"]')
        self.assertEqual(tokens[0].value, "a\nb")
        self.assertEqual(tokens[1].line, 3)

    def test_unterminated_or_invalid_input_does_not_silently_parse(self):
        for source in ('"unfinished', '--[=[ unfinished', '[==[unfinished', '"bad\\999"',
                       '"bad\\xGG"', '"bad\\q"', '"bad\nnewline"'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                tokenize_lua(source)

    def test_no_execution_or_interpretation(self):
        tokens = tokenize_lua('os.execute("never run"); L["KEY"]')
        self.assertEqual([token.value for token in tokens if token.kind == "string"], ["never run", "KEY"])


class LocalizationSourceTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)

    def write(self, path, source):
        file = self.root / path
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(source, encoding="utf-8")

    def scan(self):
        return scan_sources(self.root)

    def findings(self, keys):
        return analyze_sources(self.scan(), set(keys))

    def test_exact_runtime_lookups_and_locations(self):
        self.write("APR-Core/Test.lua", '''-- L["COMMENT"]
local arbitrary = "UNRELATED"
local longer = "SHORT_KEY_LONGER"
L["DEFINED"] = "fallback"
print(L["KEY"], L['SINGLE'], L.DOTTED, L[ [=[LONG]=] ], L["CON" .. "CAT"])
''')
        scan = self.scan()
        self.assertEqual({entry["key"] for entry in scan["references"]}, {"KEY", "SINGLE", "DOTTED", "LONG", "CONCAT"})
        self.assertTrue(all(entry["line"] == 5 for entry in scan["references"]))
        findings = analyze_sources(scan, {"KEY", "SHORT_KEY", "COMMENT", "DEFINED", "UNRELATED"})
        self.assertEqual({entry["key"] for entry in findings if entry["code"] == "unused_key"},
                         {"SHORT_KEY", "COMMENT", "DEFINED", "UNRELATED"})
        missing = [entry for entry in findings if entry["code"] == "missing_key"]
        self.assertEqual({entry["key"] for entry in missing}, {"SINGLE", "DOTTED", "LONG", "CONCAT"})
        self.assertTrue(all(entry["severity"] == "error" and entry["path"] == "APR-Core/Test.lua" for entry in missing))

    def test_locale_definitions_vendors_and_tests_are_not_usage(self):
        for path in ("APR-Core/locales/enUS.lua", "APR-Core/libs/vendor.lua", "APR-Core/vendor/test.lua",
                     "tests/fixture.lua", "Other/addon.lua"):
            self.write(path, 'print(L["IGNORED"])')
        self.assertEqual(self.scan()["references"], [])

    def test_comments_and_long_strings_cannot_inject_lookups(self):
        self.write("APR-Core/Test.lua", '''--[==[ L["COMMENT"] ]==]
local quoted = [=[ L["STRING"] ]=]
local short = "L[\\\"ESCAPED\\\"]"
print(L["REAL"])
''')
        self.assertEqual([entry["key"] for entry in self.scan()["references"]], ["REAL"])

    def test_note_extra_line_lists_and_text_objects(self):
        self.write("Routes/Test.lua", '''local data = {
Note = {"NOTE_ONE", 'NOTE_TWO', {text="NOTE_THREE", color="ff00ff"}},
ExtraLineText2 = {"EXTRA_ONE", {text='EXTRA_TWO', color="COLOR_VALUE"}},
["ExtraLineText"] = [=[LONG_EXTRA]=],
LearnSkill = {Text = "TRAIN_TEXT", spellID=123},
Note = "[COLOR:#ff0011]COLOR_KEY",
label = L["ROUTE_LABEL"] .. " (1-10)",
}
''')
        scan = self.scan()
        self.assertEqual({entry["key"] for entry in scan["references"]},
                         {"NOTE_ONE", "NOTE_TWO", "NOTE_THREE", "EXTRA_ONE", "EXTRA_TWO", "LONG_EXTRA",
                          "TRAIN_TEXT", "COLOR_KEY", "ROUTE_LABEL"})
        findings = analyze_sources(scan, {"NOTE_ONE", "ROUTE_LABEL"})
        self.assertTrue(all(entry["code"] == "missing_key" for entry in findings))
        self.assertTrue(any(entry["line"] == 5 and entry["key"] == "TRAIN_TEXT" for entry in findings))

    def test_uncatalogued_route_prose_is_an_error_and_existing_prose_keys_are_valid(self):
        self.write("Routes/Test.lua", '''local steps = {
Note = {"Talk to the guard", "EXISTING_PROSE", " ", "Go inside"},
ExtraLineText = "MISSING_SYMBOL",
label = "Plain route label",
}''')
        findings = self.findings({"EXISTING_PROSE", "Talk to the guard"})
        self.assertEqual({entry["key"] for entry in findings if entry["code"] == "raw_text"},
                         {"Go inside", "Plain route label"})
        self.assertEqual({entry["key"] for entry in findings if entry["severity"] == "error"},
                         {"MISSING_SYMBOL", "Go inside", "Plain route label"})

    def test_hardcoded_fallbacks_are_errors_with_lookup_key_and_location(self):
        self.write("APR-Core/Test.lua", '''local a = L["BRACKET"] or "English label"
local b = L.DOTTED or 'English description'
local c = rawget(L, "RAW") or
    [=[English tooltip]=]
local d = L.NON_LATIN or "日本語"
''')
        findings = self.findings({"BRACKET", "DOTTED", "RAW", "NON_LATIN"})
        self.assertEqual({entry["code"] for entry in findings}, {"hardcoded_fallback"})
        self.assertEqual({(entry["key"], entry["line"]) for entry in findings},
                         {("BRACKET", 1), ("DOTTED", 2), ("RAW", 4), ("NON_LATIN", 5)})
        self.assertTrue(all(entry["severity"] == "error" and entry["path"] == "APR-Core/Test.lua"
                            for entry in findings))

    def test_parenthesized_chained_and_conditional_fallbacks(self):
        self.write("APR-Core/Test.lua", '''local a = ((L.WRAPPED)) or ("English")
local b = rawget(L, "CHAIN") or anotherValue or "English"
local c = (L.INNER or nil) or (enabled and "English" or "Other English")
local d = L.CONCAT or "English " .. name
local e = L.NESTED or (otherValue or "English")
local f = L.NEXT or false or "not"
''')
        findings = self.findings({"WRAPPED", "CHAIN", "INNER", "CONCAT", "NESTED", "NEXT"})
        self.assertEqual({entry["key"] for entry in findings},
                         {"WRAPPED", "CHAIN", "INNER", "CONCAT", "NESTED", "NEXT"})
        self.assertTrue(all(entry["code"] == "hardcoded_fallback" for entry in findings))

    def test_structural_guards_and_translated_fallbacks_are_allowed(self):
        self.write("APR-Core/Test.lua", '''local a = L["FIRST"] or ""
local b = (rawget(L, "SECOND")) or ('')
local c = L.FIRST or L.SECOND
local d = L.FIRST or translated
local e = L.FIRST or getName("This is an argument, not a returned label")
local f = L.FIRST or C_Spell.GetSpellName(12345)
local metric = kb and string.format("%.2f", kb / 1024) .. " " .. L.FIRST or "-"
local count = value and L.SECOND or "0"
''')
        self.assertEqual(self.findings({"FIRST", "SECOND"}), [])

    def test_fallback_detection_cannot_be_injected_by_comments_or_strings(self):
        self.write("APR-Core/Test.lua", '''-- L["COMMENT"] or "English"
local quoted = [=[ L.QUOTED or "English" ]=]
local escaped = "L[\\\"ESCAPED\\\"] or \\\"English\\\""
local real = L.REAL -- or "commented fallback"
local nextStatement = "Unrelated next statement"
print(L.REAL) or "A call result is not the localization lookup"
if L.REAL then print("Unrelated branch") end
local separate = L.REAL; local another = "Unrelated"
''')
        self.assertEqual(self.findings({"REAL"}), [])

    def test_runtime_hardcoded_locale_definitions_are_errors(self):
        self.write("APR-Core/config/LocaleDefaults.lua", '''L["FIRST"] = "English"
L.SECOND = true
L["THIRD"] = ("English")
L["PRE" .. "FIX"] = [=[English]=]
L[dynamic] = "English"
L.EMPTY = ""
L.CLEAR = nil
L.COPY = otherTranslation
''')
        findings = self.scan()["diagnostics"]
        self.assertEqual({(entry["key"], entry["line"]) for entry in findings},
                         {("FIRST", 1), ("SECOND", 2), ("THIRD", 3), ("PREFIX", 4), ("dynamic", 5)})
        self.assertTrue(all(entry["code"] == "hardcoded_locale_definition" and entry["severity"] == "error"
                            for entry in findings))
        self.assertEqual(self.scan()["references"], [])

    def test_runtime_locale_definition_check_respects_catalog_vendor_and_test_exclusions(self):
        for path in ("APR-Core/locales/enUS.lua", "APR-Core/libs/vendor.lua", "APR-Core/vendor/test.lua",
                     "tests/fixture.lua", "Other/addon.lua"):
            self.write(path, 'L["DEFINITION"] = "English"; L["SENTINEL"] = true')
        self.assertEqual(self.scan()["diagnostics"], [])

    def test_conditional_literals_only_count_result_branches(self):
        self.write("APR-Core/Test.lua", '''print(L[kind == "item" and "USE_ITEM" or "USE_SPELL"])
print(L[enabled and "ON" or ("DIS" .. "ABLED")])''')
        self.assertEqual({entry["key"] for entry in self.scan()["references"]},
                         {"USE_ITEM", "USE_SPELL", "ON", "DISABLED"})
        self.assertEqual(self.scan()["diagnostics"], [])

    def test_rawget_literal_is_an_exact_lookup(self):
        self.write("APR-Core/Test.lua", '''print(rawget(L, "RAW_KEY"), rawget(other, "UNRELATED"))''')
        self.assertEqual([entry["key"] for entry in self.scan()["references"]], ["RAW_KEY"])

    def test_rawget_dynamic_requires_review_except_known_route_resolver(self):
        self.write("APR-Core/Test.lua", '''print(rawget(L, dynamic))''')
        self.write("APR-Core/utils/StepUtils.lua", '''return rawget(L, key)''')
        self.assertEqual([entry["key"] for entry in self.scan()["diagnostics"]], ["dynamic"])

    def test_unknown_dynamic_does_not_suppress_unused_keys(self):
        self.write("APR-Core/Test.lua", '''print(L[prefix .. suffix], L["FAMILY_" .. kind], L[nested[index]])''')
        scan = self.scan()
        self.assertEqual(scan["dynamic_patterns"], [])
        findings = analyze_sources(scan, {"FAMILY_ONE", "FAMILY_TWO"})
        self.assertEqual(len([entry for entry in findings if entry["code"] == "unresolved_dynamic"]), 3)
        self.assertEqual(len([entry for entry in findings if entry["code"] == "unused_key"]), 2)

    def test_modeled_action_table_supports_added_and_removed_actions(self):
        self.write("APR-Core/features/questing/RouteActions.lua", '''local actionKeys = {"NewAction", "SellItems"}
local label = L[key:upper()]''')
        scan = self.scan()
        self.assertEqual({entry["key"] for entry in scan["references"]}, {"NEWACTION", "SELLITEMS"})
        self.assertEqual(scan["diagnostics"], [])
        self.assertEqual([entry["key"] for entry in analyze_sources(scan, {"NEWACTION", "SELLITEMS", "OLD_ACTION"})],
                         ["OLD_ACTION"])

    def test_modeled_data_consumers_reference_exact_fields_only(self):
        self.write("APR-Core/config/AboutData.lua", '''local credits = {
{label="AUTHOR", names="UNRELATED"}, {label="TRANSLATOR", names="People"}}
print(L[credit.label])''')
        scan = self.scan()
        self.assertEqual({entry["key"] for entry in scan["references"]}, {"AUTHOR", "TRANSLATOR"})
        self.assertEqual(scan["diagnostics"], [])

    def test_modeled_emote_keys_are_dictionary_keys_not_actions(self):
        self.write("APR-Core/core/Event.lua", '''local gigglingBasket = {
["BASKET_ONE"]="cheer", ["BASKET_TWO"]="flex"}
print(L[key])''')
        self.assertEqual({entry["key"] for entry in self.scan()["references"]}, {"BASKET_ONE", "BASKET_TWO"})

    def test_modeled_binding_map_and_tooltip_helper(self):
        self.write("APR-Core/integrations/Gamepad.lua", '''for action,label in pairs({MENU="MENU_KEY",STEP="STEP_KEY"}) do print(L[label]) end''')
        self.write("APR-Core/features/player/XPBuffOverlay.lua", '''local function SetDismissTooltip(button,message) print(L[message]) end
SetDismissTooltip(button,"DISMISS_KEY")''')
        self.assertEqual({entry["key"] for entry in self.scan()["references"]}, {"MENU_KEY", "STEP_KEY", "DISMISS_KEY"})
        self.assertEqual(self.scan()["diagnostics"], [])

    def test_malformed_source_is_reported_without_publishing_contents(self):
        self.write("APR-Core/Test.lua", '\nprint(L["SECRET_INVALID_STRING])')
        findings = self.findings(set())
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0]["code"], "source_parse")
        self.assertEqual(findings[0]["severity"], "error")
        self.assertEqual(findings[0]["line"], 2)
        self.assertTrue(findings[0]["operational"])
        self.assertNotIn("SECRET", findings[0]["message"])

    def test_all_diagnostics_have_common_schema(self):
        self.write("APR-Core/Test.lua", 'print(L["MISSING"], L[dynamic])')
        for entry in self.findings({"UNUSED"}):
            self.assertEqual(set(entry), {"code", "severity", "key", "path", "line", "locale", "message"})
            self.assertEqual(entry["locale"], "enUS")
            self.assertNotIn("\\", entry["path"])


if __name__ == "__main__":
    unittest.main()
