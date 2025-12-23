import cloudscraper
from bs4 import BeautifulSoup
from typing import Dict

# URL CurseForge localization
LOCALIZATION_URL = (
    "https://www.curseforge.com/wow/addons/azeroth-pilot-reloaded/localization"
)

# Lang name → locale code map
LANG_NAME_TO_LOCALE = {
    "French": "frFR",
    "German": "deDE",
    "Russian": "ruRU",
    "Spanish": "esES",
    "Latin American Spanish": "esMX",
    "Italian": "itIT",
    "Korean": "koKR",
    "Brazilian Portuguese": "ptBR",
    "Simplified Chinese": "zhCN",
    "Traditional Chinese": "zhTW",
}

#############################################################################
# Scraping with cloudscraper + captcha guard
#############################################################################

# User-agent config — good practice for cloudscraper
DEFAULT_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/122.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Referer": "https://www.curseforge.com/",
    "Upgrade-Insecure-Requests": "1",
}

def safe_print(text: str) -> None:
    try:
        print(text)
    except UnicodeEncodeError:
        print(text.encode("cp1252", errors="replace").decode("cp1252"))


def fetch_localization_states() -> Dict[str, Dict]:
    """
    Scrape CurseForge localization overview page.

    Returns:
        {
          "frFR": {"state": "needs_review", "review": 1},
          "deDE": {"state": "needs_translation"},
          "ruRU": {"state": "complete"},
        }
    """

    # Create scraper instance
    scraper = cloudscraper.create_scraper(
        interpreter="nodejs",
        delay=10,
        browser={
            "browser": "chrome",
            "platform": "ios",
            "desktop": False,
        }
    )

    # Set headers
    scraper.headers.update(DEFAULT_HEADERS)

    try:
        response = scraper.get(LOCALIZATION_URL, timeout=30)
    except Exception as e:
        # If cloudscraper throws, bail out safely
        safe_print(f"⚠️ Error fetching CurseForge localization page: {e}")
        return {}

    # Check status
    if response.status_code != 200:
        safe_print(f"⚠️ Unexpected status code {response.status_code} for localization page")
        return {}

    text = response.text

    #############################
    # CAPTCHA / challenge guard
    #############################

    # Basic heuristic: CurseForge challenge pages often contain 'captcha'
    # or 'Cloudflare' or require JS — we detect a form with id "challenge-form"
    lower = text.lower()
    if "captcha" in lower or "cloudflare" in lower or "challenge-form" in lower:
        safe_print("⚠️ Detected Cloudflare challenge / captcha instead of localization page")
        return {}

    #############################
    # Parse the HTML
    #############################

    soup = BeautifulSoup(text, "html.parser")
    result: Dict[str, Dict] = {}

    for state_block in soup.select("div.language-state"):
        title = state_block.find("h2")
        if not title:
            continue

        title_text = title.get_text(strip=True).lower()

        if "needs review" in title_text:
            state = "needs_review"
        elif "needs translation" in title_text:
            state = "needs_translation"
        elif "complete" in title_text:
            state = "complete"
        else:
            continue

        # Each language box in the block
        for box in state_block.select("div.language-box"):
            # First <p> = language name
            name_el = box.find("p")
            # Last <p> = translated / review info
            info_el = box.find_all("p")[-1]

            if not name_el or not info_el:
                continue

            language_name = name_el.get_text(strip=True)
            locale = LANG_NAME_TO_LOCALE.get(language_name)
            if not locale:
                # Skip languages we don't map
                continue

            entry: Dict[str, object] = {"state": state}

            if state == "needs_review":
                text_info = info_el.get_text(strip=True)
                parts = text_info.split()
                if parts and parts[0].isdigit():
                    # e.g. "1 under review"
                    entry["review"] = int(parts[0])

            result[locale] = entry

    return result
