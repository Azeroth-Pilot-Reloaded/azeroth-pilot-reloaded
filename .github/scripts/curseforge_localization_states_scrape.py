import asyncio
from typing import Dict

from bs4 import BeautifulSoup
from pydoll.browser import Chrome

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

def safe_print(text: str) -> None:
    try:
        print(text)
    except UnicodeEncodeError:
        print(text.encode("cp1252", errors="replace").decode("cp1252"))


async def fetch_localization_states() -> Dict[str, Dict]:
    """
    Scrape CurseForge localization overview page using Pydoll (PyPI version).

    IMPORTANT:
    - No headless / args supported in this Pydoll version
    - Chrome MUST be installed on the system
    - Headless is automatic on CI (GitHub Actions)
    """

    browser = Chrome()
    tab = None

    try:
        # Start browser (NO ARGUMENTS supported)
        tab = await browser.start()

        # Navigate to CurseForge
        await tab.go_to(LOCALIZATION_URL, timeout=30)

        # Wait for JS-rendered localization blocks
        try:
            await tab.wait_for_selector("div.language-state", timeout=25)
        except TimeoutError:
            safe_print("⚠️ Localization blocks not found (Cloudflare or DOM change)")
            return {}

        # Get final DOM
        html = await tab.html

    except Exception as e:
        safe_print(f"⚠️ Pydoll error: {e}")
        return {}

    finally:
        # 🔴 CRITICAL on Windows: close TAB first, then browser
        if tab is not None:
            try:
                await tab.close()
            except Exception:
                pass

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
                parts = info_text.split()
                if parts and parts[0].isdigit():
                    entry["review"] = int(parts[0])

            result[locale] = entry

    return result
