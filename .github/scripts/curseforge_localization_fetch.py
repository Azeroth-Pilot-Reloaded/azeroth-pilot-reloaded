import re
from typing import Dict, List, Tuple
import requests


#############################################################################
# CurseForge localization export helpers
#############################################################################

def set_localization_export_url(
    project_id: int,
    locale: str,
    export_type: str = "TableAdditions",
    unlocalized: str = "ShowBlankAsComment",
    table_name: str = "L",
    escape_non_ascii_characters: bool = False,
    true_if_value_equals_key: bool = False,
) -> str:
    """
    Build the CurseForge localization export URL.

    Notes:
    - unlocalized can be: ShowPrimary, ShowPrimaryAsComment, ShowBlankAsComment, Ignore
      (see CurseForge docs)
    """
    esc = "true" if escape_non_ascii_characters else "false"
    tie = "true" if true_if_value_equals_key else "false"

    return (
        f"https://wow.curseforge.com/api/projects/{project_id}/localization/export"
        f"?export-type={export_type}"
        f"&lang={locale}"
        f"&unlocalized={unlocalized}"
        f"&table-name={table_name}"
        f"&escape-non-ascii-characters={esc}"
        f"&true-if-value-equals-key={tie}"
    )


def fetch_localization_export(api_url: str, api_token: str) -> str:
    """
    Fetch localization export text from CurseForge.
    """
    headers = {"X-Api-Token": api_token}  # doc says X-Api-Token (case-insensitive)
    response = requests.get(api_url, headers=headers, timeout=20)
    response.raise_for_status()
    return response.text


#############################################################################
# Parsing helpers (TableAdditions / lua_additive_table)
#############################################################################

ParsedEntry = Tuple[str, str, bool]  # (key, value, commented)


def parse_table_additions(locales_text: str) -> List[ParsedEntry]:
    """
    Parse TableAdditions export.
    Handles both:
      L["Key"] = "Value"
      -- L["Key"] = "Value"     (commented => unlocalized in ShowBlankAsComment mode)

    Returns: list of (key, value, commented)
    """

    kv_list: List[ParsedEntry] = []

    # Matches optional comment prefix then L["..."]
    # Example:
    #   L["Key"] = "Value"
    #   -- L["Key"] = "Value"
    key_pattern = re.compile(r'^(--\s*)?L\[\s*["\'](.*?)["\']\s*\]\s*=\s*(.*)$')

    for raw_line in locales_text.splitlines():
        line = raw_line.strip()
        if not line:
            continue

        m = key_pattern.match(line)
        if not m:
            continue

        commented = bool(m.group(1))
        key = m.group(2)
        rhs = m.group(3).strip()

        # Extract a quoted value if present: "..." or '...'
        # If value is not quoted (rare), keep empty string to avoid false positives.
        vm = re.match(r'["\'](.*?)["\']', rhs)
        value = vm.group(1) if vm else ""

        kv_list.append((key, value, commented))

    return kv_list


#############################################################################
# Public API: fetch localization stats
#############################################################################

def fetch_localization_stats(
    project_id: int,
    api_token: str,
    locales: List[str],
    reference_locale: str = "enUS",
) -> Dict[str, Dict[str, int]]:
    """
    Fetch localization stats for the given locales using CurseForge export endpoint.

    Strategy:
    - Use reference_locale to compute total key count (total phrases).
    - For each locale, export with unlocalized=ShowBlankAsComment
      so missing translations appear as commented lines.
    - Count translated as "not commented".

    Returns:
    {
        "frFR": {"translated": 123, "total": 150, "missing": 27},
        ...
    }
    """

    # Always use ShowBlankAsComment so totals/translation are comparable
    # and missing phrases are visible as commented lines.
    def export(locale: str) -> str:
        url = set_localization_export_url(
            project_id=project_id,
            locale=locale,
            export_type="TableAdditions",
            unlocalized="ShowBlankAsComment",
            table_name="L",
            escape_non_ascii_characters=False,
            true_if_value_equals_key=False,
        )
        return fetch_localization_export(url, api_token)

    # Reference locale defines the total set of keys
    ref_text = export(reference_locale)
    ref_entries = parse_table_additions(ref_text)

    reference_keys = {key for key, _val, _commented in ref_entries}
    total_keys = len(reference_keys)

    stats: Dict[str, Dict[str, int]] = {}

    for locale in locales:
        text = export(locale)
        entries = parse_table_additions(text)

        # Build a quick lookup per key (keep first occurrence)
        by_key: Dict[str, bool] = {}
        for key, _val, commented in entries:
            if key in reference_keys and key not in by_key:
                by_key[key] = commented

        # If a key from reference isn't present at all, treat as missing.
        translated = 0
        for key in reference_keys:
            commented = by_key.get(key, True)
            if not commented:
                translated += 1

        missing = total_keys - translated

        stats[locale] = {
            "translated": translated,
            "total": total_keys,
            "missing": missing,
        }

    return stats
