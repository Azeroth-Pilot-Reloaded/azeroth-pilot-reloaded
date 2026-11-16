"""Preview or publish APR translation data without replacing other phrases.

Run with --apply to publish; the default only reads and validates the remote catalogs.
Credentials are read from CF_API_KEY or the repository .env and never printed.
"""
import argparse
import json
import os
from pathlib import Path
import sys
import re

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


LOCALES = {"enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW"}


def technical_tokens(value):
    """Formatting arguments and WoW markup are data, not translator prose."""
    return (printf_parameters(value), sorted(re.findall(r"\|(?:[cC][0-9a-fA-F]{8}|[rRhH]|[TA][^|]*\|[ta])", value)))


def prepare_payload(payload, catalogs, renames=None):
    if set(payload) != LOCALES or set(catalogs) != LOCALES:
        raise ValueError("Expected all eleven locales")
    result = {locale: dict(values) for locale, values in payload.items()}
    for old, new in (renames or {}).items():
        if old == new or not re.fullmatch(r"[A-Z][A-Z0-9_]*", new):
            raise ValueError("Invalid rename")
        for locale in LOCALES:
            if old not in catalogs[locale]:
                raise ValueError(f"{locale}: missing original translation for {old}")
            original = catalogs[locale][old]
            if new in result[locale] and result[locale][new] != original:
                raise ValueError(f"{locale}: rename would rewrite {new}")
            result[locale][new] = original
    source = result["enUS"]
    for locale, values in result.items():
        if values.keys() != source.keys():
            raise ValueError(f"{locale}: key coverage differs from English")
        for key, value in values.items():
            if not re.fullmatch(r"[A-Z][A-Z0-9_]*", key) or not isinstance(value, str) or not value.strip():
                raise ValueError(f"{locale}: invalid phrase {key}")
            if technical_tokens(value) != technical_tokens(source[key]):
                raise ValueError(f"{locale}: invalid format for {key}")
            if key in catalogs[locale] and catalogs[locale][key] != value:
                raise ValueError(f"{locale}: existing translations differ: {key}")
    return result


def publish(api, payload, apply=False, renames=None, export_dir=None):
    catalogs = {locale: api.export(locale) for locale in payload}
    payload = prepare_payload(payload, catalogs, renames)
    changes = {locale: {key: value for key, value in values.items() if key not in catalogs[locale]}
               for locale, values in payload.items()}
    for locale, values in changes.items():
        print(f"{locale}: {len(values)} new phrases", flush=True)
    if not apply:
        print("Preview complete. Use --apply to publish these phrases.")
        return
    for locale in ["enUS"] + [name for name in payload if name != "enUS"]:
        # Recheck immediately before each mutation; never overwrite concurrent translator edits.
        current = api.export(locale)
        if any(key in current and current[key] != value for key, value in payload[locale].items()):
            raise ValueError(f"{locale}: translations changed after preview")
        pending = {key: value for key, value in payload[locale].items() if key not in current}
        if pending:
            api.upload(locale, pending)
        actual = api.export(locale)
        if any(actual.get(key) != value for key, value in payload[locale].items()):
            raise ValueError(f"{locale}: re-export did not confirm all translations")
        if export_dir:
            export_dir.mkdir(parents=True, exist_ok=True)
            (export_dir / f"{locale}.json").write_text(json.dumps(actual, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"{locale}: all {len(payload['enUS'])} phrases verified", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--file", type=Path, default=Path(__file__).with_name("announcement-translations.json"))
    parser.add_argument("--renames", type=Path, help="JSON mapping of old keys to new keys; preserve remote values")
    parser.add_argument("--export-dir", type=Path, help="Save verified remote catalogs outside the generated locales")
    args = parser.parse_args()
    load_dotenv(ROOT / ".env")
    token = os.getenv("CF_API_KEY")
    if not token:
        raise ValueError("CF_API_KEY is required")
    payload = json.loads(args.file.read_text(encoding="utf-8"))
    renames = json.loads(args.renames.read_text(encoding="utf-8")) if args.renames else None
    api = CatalogAPI(618667, token, retries=1, timeout=30)
    publish(api, payload, args.apply, renames, args.export_dir)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Network errors can include request metadata. Keep credentials out of tool output.
        print(f"Import stopped ({type(error).__name__}); re-run the preview to inspect remote state.", file=sys.stderr)
        raise SystemExit(1)
