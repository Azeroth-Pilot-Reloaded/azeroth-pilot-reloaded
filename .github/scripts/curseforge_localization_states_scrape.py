import asyncio
import re
from typing import Dict

from bs4 import BeautifulSoup
from pydoll.browser import Chrome
from pydoll.browser.options import ChromiumOptions
from pydoll.constants import By

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

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/122.0.0.0 Safari/537.36"
)

def safe_print(text: str) -> None:
    try:
        print(text)
    except UnicodeEncodeError:
        print(text.encode("cp1252", errors="replace").decode("cp1252"))


def build_browser_options() -> ChromiumOptions:
    options = ChromiumOptions()
    options.headless = True
    options.start_timeout = 30
    options.block_notifications = True
    options.block_popups = True
    options.password_manager_enabled = False
    options.set_accept_languages("en-US,en")

    for arg in [
        "--disable-blink-features=AutomationControlled",
        "--disable-dev-shm-usage",
        "--disable-gpu",
        "--disable-extensions",
        "--no-sandbox",
        "--window-size=1920,1080",
        f"--user-agent={USER_AGENT}",
    ]:
        try:
            options.add_argument(arg)
        except Exception:
            pass

    return options


def extract_first_int(text: str) -> int | None:
    match = re.search(r"\d[\d,]*", text)
    if not match:
        return None
    return int(match.group(0).replace(",", ""))


async def fetch_localization_states() -> Dict[str, Dict]:
    """
    Scrape CurseForge localization overview page using Pydoll.

    Notes:
    - Headless Chrome with safer defaults
    - Cloudflare challenges may block access in CI
    """

    browser = Chrome(options=build_browser_options())
    tab = None

    try:
        # Start browser
        tab = await browser.start()

        # Navigate to CurseForge
        await tab.enable_auto_solve_cloudflare_captcha()
        await tab.go_to(LOCALIZATION_URL, timeout=60)

        # Wait for JS-rendered localization blocks
        found = await tab.find_or_wait_element(
            By.CSS_SELECTOR,
            "div.language-state",
            timeout=30,
            raise_exc=False,
        )

        # Get final DOM
        html = await tab.page_source
        html_lower = html.lower()
        if "just a moment" in html_lower or "cf-challenge" in html_lower:
            safe_print("Cloudflare challenge detected; page content blocked")
            return {}

        if not found:
            safe_print("Localization blocks not found (DOM change or blocked)")
            return {}

    except Exception as e:
        safe_print(f"⚠️ Pydoll error: {e}")
        return {}

    finally:
        # CRITICAL on Windows: close TAB first, then browser
        if tab is not None:
            try:
                await tab.close()
            except Exception:
                pass

        try:
            await browser.stop()
        except Exception:
            try:
                await browser.close()
            except Exception:
                pass

    # -------------------------
    # Parse HTML
    # -------------------------
    soup = BeautifulSoup(html, "html.parser")
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

        for box in state_block.select("div.language-box"):
            p_tags = box.find_all("p")
            if len(p_tags) < 2:
                continue

            language_name = p_tags[0].get_text(strip=True)
            info_text = p_tags[-1].get_text(strip=True)

            locale = LANG_NAME_TO_LOCALE.get(language_name)
            if not locale:
                continue

            entry: Dict[str, object] = {"state": state}

            if state == "needs_review":
                review_count = extract_first_int(info_text)
                if review_count is not None:
                    entry["review"] = review_count

            result[locale] = entry

    return result
