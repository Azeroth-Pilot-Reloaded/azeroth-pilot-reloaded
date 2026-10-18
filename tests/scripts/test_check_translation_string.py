import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / ".github/scripts"))

import check_translation_string as script


class CheckTranslationStringTests(unittest.TestCase):
    def test_set_localization_url_includes_export_params(self):
        url = script.set_localization_url(
            618667,
            "token",
            "https://wow.curseforge.com",
            locale="frFR",
            unlocalized="ShowBlankAsComment",
        )

        self.assertEqual(
            url,
            "https://wow.curseforge.com/api/projects/618667/localization/export?export-type=TableAdditions&lang=frFR&unlocalized=ShowBlankAsComment&table-name=L&escape-non-ascii-characters=false&true-if-value-equals-key=false",
        )

    def test_get_locales_kv_table_additions_parses_commented_entries(self):
        sample = '''
        -- L["MISSING_KEY"] = "fallback"
        L["READY_KEY"] = "hello"
        L["QUOTED_KEY"] = "O\'Reilly"
        '''

        self.assertEqual(
            script.get_locales_kv_table_additions(sample),
            [
                ("MISSING_KEY", "fallback"),
                ("READY_KEY", "hello"),
                ("QUOTED_KEY", "O'Reilly"),
            ],
        )


if __name__ == "__main__":
    unittest.main()
