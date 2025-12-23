import json
import os
import requests
import asyncio
from dotenv import load_dotenv
from datetime import datetime, timezone
from typing import Dict

from curseforge_localization_fetch import fetch_localization_stats
from curseforge_localization_states_scrape import fetch_localization_states

load_dotenv()

#############################################################################
# Configuration
#############################################################################

PROJECT_ID = 618667
STATE_FILE = ".github/scripts/localization-state.json"
REPING_DELAY_DAYS = 7
REFERENCE_LOCALE = "enUS"

CF_API_KEY = os.getenv("CF_API_KEY")
DISCORD_WEBHOOK = os.getenv("DISCORD_WEBHOOK")

# Optional: frFR,deDE,ruRU
LOCALES_ENV = os.getenv("LOCALES")

# Enable dry-run mode
DRY_RUN = os.getenv("DRY_RUN", "false").lower() == "true"

#############################################################################
# Locale configuration
#############################################################################

LOCALE_CONFIG = {
    "deDE": {
        "role_id": "1407822750747201587",
        "emoji": ":flag_de:",  # Germany
        "singular": "fehlende Übersetzung",
        "plural": "fehlende Übersetzungen",
        "review": "in Prüfung",
    },
    # "esES": {
    #     "role_id": "1453078040325263520",
    #     "emoji": ":flag_es:",  # Spain
    #     "singular": "traducción faltante",
    #     "plural": "traducciones faltantes",
    #     "review": "en revisión",
    # },
    # "esMX": {
    #     "role_id": "1407823805530771578",
    #     "emoji": ":flag_mx:",  # Mexico (Latin American Spanish)
    #     "singular": "traducción faltante",
    #     "plural": "traducciones faltantes",
    #     "review: "en revisión",
    # },
    "frFR": {
        "role_id": "1407822386807443547",
        "emoji": ":flag_fr:",  # France
        "singular": "traduction manquante",
        "plural": "traductions manquantes",
        "review": "en relecture",
    },
    # "itIT": {
    #     "role_id": "1453078205216063670",
    #     "emoji": ":flag_it:",  # Italy
    #     "singular": "traduzione mancante",
    #     "plural": "traduzioni mancanti",
    #     "review": "in revisione",
    # },
    # "koKR": {
    #     "role_id": "1453078288644702281",
    #     "emoji": ":flag_kr:",  # South Korea
    #     "singular": "누락된 번역",
    #     "plural": "누락된 번역들",
    #     "review": "검토 중",
    # },
    # "ptBR": {
    #     "role_id": "1453078323348377692",
    #     "emoji": ":flag_br:",  # Brazil
    #     "singular": "tradução ausente",
    #     "plural": "traduções ausentes",
    #     "review": "em revisão",
    # },
    "ruRU": {
        "role_id": "1447171991432986654",
        "emoji": ":flag_ru:",  # Russia
        "form_1": "отсутствующий перевод",
        "form_2": "отсутствующих перевода",
        "form_5": "отсутствующих переводов",
        "review": "на проверке",
    },
    # "zhCN": {
    #     "role_id": "1453078364767129621",
    #     "emoji": ":flag_cn:",  # China (Simplified Chinese)
    #     "singular": "缺少的翻译",
    #     "plural": "缺少的翻译",
    #     "review": "审核中",
    # },
    # "zhTW": {
    #     "role_id": "1453078418588700714",
    #     "emoji": ":flag_tw:",  # Taiwan (Traditional Chinese)
    #     "singular": "缺少的翻譯",
    #     "plural": "缺少的翻譯",
    #     "review": "審核中",
    # },
}


#############################################################################
# State handling
#############################################################################

def load_state() -> Dict[str, Dict]:
    if not os.path.exists(STATE_FILE):
        return {}
    with open(STATE_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def save_state(state: Dict[str, Dict]) -> None:
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)


def days_since(date_str: str | None) -> int:
    if not date_str:
        return 9999
    return (datetime.now(timezone.utc) - datetime.fromisoformat(date_str)).days

#############################################################################
# Business rules
#############################################################################

def should_ping(previous: Dict | None, missing: int, review: int) -> bool:
    """
    Ping rules:
    - No ping if missing == 0 AND review == 0
    - Ping if missing or review count changed
    - Ping if unchanged for >= REPING_DELAY_DAYS
    """
    if missing == 0 and review == 0:
        return False

    if not previous:
        return True

    if previous.get("missing") != missing or previous.get("review") != review:
        return True

    return days_since(previous.get("last_ping")) >= REPING_DELAY_DAYS

#############################################################################
# Pluralization
#############################################################################

def pluralize_ru(count: int, cfg: dict) -> str:
    """
    Russian pluralization rules:
    - 1, 21, 31... -> form_1
    - 2-4, 22-24... -> form_2
    - 0, 5-20, 11-14... -> form_5
    """
    if count % 10 == 1 and count % 100 != 11:
        return cfg["form_1"]
    if count % 10 in (2, 3, 4) and count % 100 not in (12, 13, 14):
        return cfg["form_2"]
    return cfg["form_5"]


def pluralize(locale: str, count: int) -> str:
    cfg = LOCALE_CONFIG[locale]
    if locale == "ruRU":
        return pluralize_ru(count, cfg)
    return cfg["singular"] if count == 1 else cfg["plural"]


def review_phrase(locale: str, count: int) -> str:
    cfg = LOCALE_CONFIG[locale]
    review = cfg.get("review", "under review")
    return review

#############################################################################
# Message building
#############################################################################

def build_need_text(locale: str, missing: int, review: int) -> str:
    parts = []

    if missing > 0:
        parts.append(f"**{missing}** {pluralize(locale, missing)}")

    if review > 0:
        parts.append(f"**{review}** {review_phrase(locale, review)}")

    return " and ".join(parts)


def build_detail_message(locale: str, missing: int, review: int) -> str:
    cfg = LOCALE_CONFIG[locale]
    role = f"<@&{cfg['role_id']}>"
    emoji = cfg["emoji"]
    need_text = build_need_text(locale, missing, review)

    return f"{emoji} {role} - {need_text}"


def build_summary_line(summary: Dict[str, str]) -> str:
    count = len(summary)
    details = ", ".join(f"{k}: {v}" for k, v in summary.items())
    plural = "locale needs" if count == 1 else "locales need"

    return f"📊 Localization status: {count} {plural} attention ({details})"

#############################################################################
# Console-safe printing (Windows)
#############################################################################

def safe_print(text: str) -> None:
    try:
        print(text)
    except UnicodeEncodeError:
        print(text.encode("cp1252", errors="replace").decode("cp1252"))

#############################################################################
# Discord
#############################################################################

def post_to_discord(lines: list[str]) -> None:
    if DRY_RUN:
        print("DRY-RUN mode enabled. Message that would be sent:\n")
        for line in lines:
            safe_print(line)
        return

    payload = {
        "username": "Azeroth Pilot Reloaded - Localization",
        "content": "\n".join(lines),
    }

    response = requests.post(DISCORD_WEBHOOK, json=payload, timeout=20)
    response.raise_for_status()

#############################################################################
# Main
#############################################################################

def main():
    state = load_state()

    watched_locales = (
        [l.strip() for l in LOCALES_ENV.split(",")]
        if LOCALES_ENV
        else list(LOCALE_CONFIG.keys())
    )

    # Fetch data sources
    stats = fetch_localization_stats(
        project_id=PROJECT_ID,
        api_token=CF_API_KEY,
        locales=watched_locales,
        reference_locale=REFERENCE_LOCALE,
    )

    review_states = asyncio.run(fetch_localization_states())

    summary_data: Dict[str, str] = {}
    detail_lines: list[str] = []

    for locale in watched_locales:
        if locale not in LOCALE_CONFIG or locale not in stats:
            continue

        missing = stats[locale]["missing"]
        review = review_states.get(locale, {}).get("review", 0)

        previous = state.get(locale)

        if should_ping(previous, missing, review):
            summary_data[locale[:2].upper()] = (
                f"{missing}M/{review}R"
                if review > 0 and missing > 0
                else f"{missing}M"
                if missing > 0
                else f"{review}R"
            )

            detail_lines.append(
                build_detail_message(locale, missing, review)
            )

            state[locale] = {
                "missing": missing,
                "review": review,
                "last_ping": datetime.now(timezone.utc).isoformat(),
            }
        else:
            state[locale] = previous or {
                "missing": missing,
                "review": review,
                "last_ping": None,
            }

    if detail_lines:
        summary_line = build_summary_line(summary_data)
        post_to_discord([summary_line, "", *detail_lines])
        if not DRY_RUN:
            print("Discord notification sent")
    else:
        print("No ping needed")

    save_state(state)


if __name__ == "__main__":
    main()
