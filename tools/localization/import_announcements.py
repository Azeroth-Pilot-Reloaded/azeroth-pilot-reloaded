"""Preview or publish APR's announcement translations without replacing other phrases.

Run with --apply to publish; the default only reads and validates the remote catalogs.
Credentials are read from CF_API_KEY or the repository .env and never printed.
"""
import argparse
import json
import os
from pathlib import Path
import sys

from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".github/scripts"))
from archive_changelog import CurseForge
from localization_quality import parse_catalog, printf_parameters


class CatalogAPI(CurseForge):
    def export(self, locale):
        response = self.request("get", "/export", f"Export {locale}", params={
            "lang": locale, "export-type": "TableAdditions", "table-name": "L",
            "unlocalized": "Ignore", "escape-non-ascii-characters": "false",
            "true-if-value-equals-key": "false",
        })
        response.encoding = "utf-8"
        if "<html" in response.text.lower():
            raise ValueError("Unexpected HTML export")
        catalog = parse_catalog(response.text)
        if not catalog:
            raise ValueError("Empty localization export")
        return catalog


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    load_dotenv(ROOT / ".env")
    token = os.getenv("CF_API_KEY")
    if not token:
        raise ValueError("CF_API_KEY is required")
    payload = json.loads(Path(__file__).with_name("announcement-translations.json").read_text(encoding="utf-8"))
    source = payload["enUS"]
    for locale, values in payload.items():
        if values.keys() != source.keys():
            raise ValueError(f"{locale}: key coverage differs from English")
        for key, value in values.items():
            if not value.strip() or printf_parameters(value) != printf_parameters(source[key]):
                raise ValueError(f"{locale}: invalid format for {key}")
    api = CatalogAPI(618667, token, retries=1, timeout=30)
    # Preflight every locale before writing any phrase. Existing differing values require review.
    changes = {}
    for locale, values in payload.items():
        before = api.export(locale)
        conflicts = [key for key, value in values.items() if key in before and before[key] != value]
        if conflicts:
            raise ValueError(f"{locale}: existing translations differ: {', '.join(conflicts)}")
        changes[locale] = {key: value for key, value in values.items() if key not in before}
        print(f"{locale}: {len(changes[locale])} new phrases", flush=True)
    if not args.apply:
        print("Preview complete. Use --apply to publish these phrases.")
        return
    for locale in ["enUS"] + [name for name in payload if name != "enUS"]:
        if changes[locale]:
            api.upload(locale, changes[locale])
        actual = api.export(locale)
        if any(actual.get(key) != value for key, value in payload[locale].items()):
            raise ValueError(f"{locale}: re-export did not confirm all translations")
        print(f"{locale}: all {len(source)} phrases verified", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Network errors can include request metadata. Keep credentials out of tool output.
        print(f"Import stopped ({type(error).__name__}); re-run the preview to inspect remote state.", file=sys.stderr)
        raise SystemExit(1)
