"""Publishing contracts use synthetic phrases, never freeze the live catalogs."""
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("translation_import", ROOT / "tools/localization/import_announcements.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class FakeAPI:
    def __init__(self):
        self.catalogs = {locale: {"OLD_ACTION": "Keep %s |cfffffffftext|r"} for locale in module.LOCALES}
        self.writes = []
        self.drop = False

    def export(self, locale):
        return dict(self.catalogs[locale])

    def upload(self, locale, values):
        self.writes.append((locale, values))
        if not self.drop:
            self.catalogs[locale].update(values)


class TranslationImportTests(unittest.TestCase):
    def payload(self):
        return {locale: {"NEW_ACTION": "Action %s"} for locale in module.LOCALES}

    def test_preview_and_publish_verify_every_locale(self):
        api = FakeAPI()
        module.publish(api, self.payload())
        self.assertEqual(api.writes, [])
        module.publish(api, self.payload(), apply=True)
        self.assertEqual(len(api.writes), 11)
        self.assertEqual(api.writes[0][0], "enUS")
        self.assertTrue(all(values == {"NEW_ACTION": "Action %s"} for _, values in api.writes))
        module.publish(api, self.payload(), apply=True)
        self.assertEqual(len(api.writes), 11, "Repeated publication must be idempotent")

    def test_rename_preserves_each_existing_language(self):
        api = FakeAPI()
        for index, locale in enumerate(sorted(module.LOCALES)):
            api.catalogs[locale]["OLD_ACTION"] = f"Language {index} %s"
        payload = {locale: {} for locale in module.LOCALES}
        module.publish(api, payload, True, {"OLD_ACTION": "NAMED_ACTION"})
        for catalog in api.catalogs.values():
            self.assertEqual(catalog["NAMED_ACTION"], catalog["OLD_ACTION"])

    def test_conflicts_and_formatting_stop_before_publication(self):
        for mutation in ("conflict", "argument", "markup", "locale", "rename"):
            with self.subTest(mutation=mutation):
                api, payload = FakeAPI(), self.payload()
                renames = None
                if mutation == "conflict": api.catalogs["frFR"]["NEW_ACTION"] = "Existing %s"
                if mutation == "argument": payload["frFR"]["NEW_ACTION"] = "Action %d"
                if mutation == "markup": payload["frFR"]["NEW_ACTION"] = "|cffffffffAction %s|r"
                if mutation == "locale": del payload["frFR"]
                if mutation == "rename": renames = {"OLD_ACTION": "NEW_ACTION"}
                with self.assertRaises(ValueError): module.publish(api, payload, True, renames)
                self.assertEqual(api.writes, [])

    def test_failed_reexport_stops_remaining_uploads(self):
        api = FakeAPI()
        api.drop = True
        with self.assertRaisesRegex(ValueError, "re-export"):
            module.publish(api, self.payload(), True)
        self.assertEqual(len(api.writes), 1)
