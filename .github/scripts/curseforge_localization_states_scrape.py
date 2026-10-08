from typing import Dict, List
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from pydoll import Chrome, ChromiumOptions

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


def build_browser_options() -> ChromiumOptions:
    options = ChromiumOptions()
    options.headless = True
    options.start_timeout = 30
    options.block_notifications = True
    options.block_popups = True
    options.password_manager_enabled = False
    options.set_accept_languages("en-US,en")

    # Keep Chrome's native User-Agent so its version and platform stay consistent.
    for arg in [
        "--disable-blink-features=AutomationControlled",
        "--disable-dev-shm-usage",
        "--disable-gpu",
        "--disable-extensions",
        "--no-sandbox",
        "--window-size=1920,1080",
    ]:
        try:
            options.add_argument(arg)
        except Exception:
            pass

    return options


def parse_language_counts(html: str) -> Dict[str, int]:
    """Count both untranslated and review-pending phrases on a language page."""
    soup = BeautifulSoup(html, "html.parser")
    counts = {"missing": 0, "review": 0}
    seen: set[str] = set()

    for phrase in soup.select('li[data-target="phrase"]'):
        phrase_id = phrase.get("data-phrase-id")
        unique_id = str(phrase_id) if phrase_id else str(phrase)
        if unique_id in seen:
            continue
        seen.add(unique_id)

        classes = set(phrase.get("class", []))
        if "needs-translation" in classes:
            counts["missing"] += 1
        elif "needs-review" in classes:
            counts["review"] += 1

    return counts


def parse_overview(html: str) -> Dict[str, Dict]:
    """Extract locale states and language-page links from the overview HTML."""
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

            locale = LANG_NAME_TO_LOCALE.get(p_tags[0].get_text(strip=True))
            if not locale:
                continue

            link = box.find("a", href=True)
            result[locale] = {
                "state": state,
                "href": link["href"] if link else None,
            }

    return result


async def fetch_localization_states(locales: List[str] | None = None) -> Dict[str, Dict]:
    """
    Scrape CurseForge localization overview page using Pydoll.

    Notes:
    - Headless Chrome with safer defaults
    - Cloudflare challenges may block access in CI
    - Missing counts raise an error so the workflow cannot report a false success
    """

    browser = Chrome(options=build_browser_options())
    tab = None

    try:
        # Start browser
        tab = await browser.start()

        # Pydoll 3 handles Turnstile per navigation, not in the background.
        async with tab.expect_cloudflare_turnstile():
            await tab.go_to(LOCALIZATION_URL, timeout=60)

        # Wait for JS-rendered localization blocks
        found = await tab.query(
            "div.language-state",
            timeout=30,
            raise_exc=False,
        )

        # Get final DOM
        overview_html = await tab.page_source()
        html_lower = overview_html.lower()
        if "just a moment" in html_lower or "cf-challenge" in html_lower:
            raise RuntimeError("Cloudflare challenge detected; page content blocked")

        if not found:
            raise RuntimeError("Localization blocks not found (DOM change or blocked)")

        result = parse_overview(overview_html)
        if not result:
            raise RuntimeError("No localization states found in the overview")
        requested_locales = locales or list(result.keys())

        # The overview assigns only one bucket to each locale even when its
        # phrases contain both states. Count the phrase classes independently.
        for locale in requested_locales:
            entry = result.get(locale)
            if not entry or not entry.get("href"):
                raise RuntimeError(f"Localization page link not found for {locale}")

            async with tab.expect_cloudflare_turnstile():
                await tab.go_to(urljoin(LOCALIZATION_URL, entry["href"]), timeout=60)
            phrases_found = await tab.query(
                'li[data-target="phrase"]',
                timeout=30,
                raise_exc=False,
            )
            if not phrases_found:
                raise RuntimeError(f"Localization phrases not found for {locale}")

            entry.update(parse_language_counts(await tab.page_source()))

        return result

    except Exception as e:
        raise RuntimeError(f"Could not fetch CurseForge localization states: {e}") from e

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
