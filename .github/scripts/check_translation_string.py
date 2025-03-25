import os
import re
import requests
import difflib
import sys
import argparse
from dotenv import load_dotenv
from termcolor import colored

load_dotenv()

#############################################################################
# Functions to fetch and parse localization data from CurseForge
#############################################################################

def fetch_translations_from_curseforge(api_url, api_key):
    """
    Fetches the localization file from CurseForge using the provided API URL and API key.
    """
    headers = {
        'X-API-TOKEN': api_key
    }
    response = requests.get(api_url, headers=headers)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch translations: {response.status_code}")
    return response.text

def set_localization_url(slug, cf_token, project_site):
    """
    Constructs the CurseForge API URL for localization export.
    """
    if slug and cf_token and project_site:
        return f"{project_site}/api/projects/{slug}/localization/export?export-type=GlobalStrings&unlocalized=Ignore"
    return None

#############################################################################
# Functions to process localization files (keys and texts)
#############################################################################

def get_locales_kv(locales):
    """
    Extracts key and text value pairs from the locales file.
    It assumes the format KEY = "value" or KEY = 'value'.
    Returns a list of tuples (key, text).
    """
    kv_list = []
    lines = locales.split('\n')
    for line in lines:
        if re.match(r'^[A-Z0-9_]', line) and '=' in line:
            parts = line.split('=', 1)
            key = parts[0].strip()
            value = parts[1].strip()
            value = re.sub(r'^["\']|["\']$', '', value)
            kv_list.append((key, value))
    return kv_list

#############################################################################
# Functions to work with Lua files
#############################################################################

def get_lua_files_from_directories(directories):
    """
    Recursively collects all .lua files from the given directories,
    excluding directories named 'libs'.
    """
    lua_files = []
    for directory in directories:
        for root, dirs, files in os.walk(directory):
            # Exclude 'libs' directory
            dirs[:] = [d for d in dirs if d != 'libs']
            for file in files:
                if file.endswith('.lua'):
                    lua_files.append(os.path.join(root, file))
    return lua_files

def load_string_from_file(file_path):
    """
    Loads and returns a list of non-empty lines from a file.
    """
    if not os.path.isfile(file_path):
        raise FileNotFoundError(f"The file {file_path} does not exist.")
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = [line.strip() for line in file if line.strip()]
    return lines

def check_string_in_lua_files(word_list, file_list, banned_list):
    """
    Checks if each word in the word_list (excluding those in banned_list)
    is present in at least one of the given Lua files.
    """
    words_not_found = []
    for word in word_list:
        if word in banned_list:
            continue
        word_found = False
        for file_path in file_list:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
                if word in content:
                    word_found = True
                    break
        if not word_found:
            words_not_found.append(word)
    return words_not_found

def check_route_string_existing_in_locales(word_list, directory):
    """
    Checks for extra route strings defined in Lua files within the given directory.
    """
    lua_files = get_lua_files_from_directories([directory])
    words_not_found = []
    pattern = re.compile(r'ExtraLineText\d* = "([^"]+)"')
    for file_path in lua_files:
        with open(file_path, 'r', encoding='utf-8') as file:
            for line in file:
                match = pattern.search(line)
                if match:
                    word = match.group(1)
                    if word not in word_list and word not in words_not_found:
                        words_not_found.append(word)
    return words_not_found

#############################################################################
# Functions to check similar translations with keys
#############################################################################

def check_similar_texts_kv(kv_list, threshold=0.8):
    """
    Checks for pairs of texts that are too similar based on the provided threshold.
    Returns a list of tuples: (key1, text1, key2, text2, similarity_ratio)
    """
    similar_pairs = []
    n = len(kv_list)
    for i in range(n):
        key1, text1 = kv_list[i]
        for j in range(i + 1, n):
            key2, text2 = kv_list[j]
            ratio = difflib.SequenceMatcher(None, text1, text2).ratio()
            if ratio >= threshold:
                similar_pairs.append((key1, text1, key2, text2, ratio))
    return similar_pairs

#############################################################################
# Utility function to print lists with colors
#############################################################################

def print_list_with_color(title, items, color):
    """
    Prints the list of items with a colored title and bullet points.
    """
    print(colored(title, color))
    for item in items:
        print(colored(f"- {item}", color))
    print()  # Newline for better readability

#############################################################################
# Main script execution
#############################################################################

def main():
    # Set up command-line argument parsing
    parser = argparse.ArgumentParser(description="Localization check script for CurseForge")
    parser.add_argument("--skip-similarity-check", action="store_true",
                        help="Skip the similarity check for translation texts (useful for GitHub actions)")
    args = parser.parse_args()

    # Load environment variables and configure settings
    slug = 618667
    cf_token = os.getenv('CF_TOKEN')
    project_site = "https://wow.curseforge.com"
    directories = ['./Routes', './APR-Core']
    banned_list = ['_42_COMMAND']

    # Build the API URL for CurseForge localization export
    api_url = set_localization_url(slug, cf_token, project_site)
    if not api_url:
        raise Exception("Missing CurseForge API token and/or project id is invalid.")

    # Fetch translations from CurseForge
    locales = fetch_translations_from_curseforge(api_url, cf_token)

    # Extract key/value pairs from the locales file
    kv_list = get_locales_kv(locales)
    # Also extract just the keys for Lua file checks
    word_list = [kv[0] for kv in kv_list]

    # Check for translation keys that are not used in Lua files
    file_list = get_lua_files_from_directories(directories)
    words_not_found = check_string_in_lua_files(word_list, file_list, banned_list)

    # Check for extra route strings in Lua files that are not present in locales
    words_not_in_locales = check_route_string_existing_in_locales(word_list, './Routes')

    # Optionally check for similar translation texts with keys
    if not args.skip_similarity_check:
        similar_translations = check_similar_texts_kv(kv_list, threshold=0.9)
        if similar_translations:
            print(colored("Similar translation texts found (similarity ratio >= 90%):", 'magenta'))
            for key1, text1, key2, text2, ratio in similar_translations:
                print(colored(f"- Key '{key1}' ('{text1}') and Key '{key2}' ('{text2}') (ratio: {ratio:.2f})", 'magenta'))
            print()  # Newline for readability
    else:
        print(colored("Skipping similarity check as per argument.", 'cyan'))

    # Print results with colored output
    print_list_with_color("Translation keys not used in Lua files:", words_not_found, 'yellow')
    print_list_with_color("Translation keys not present on CurseForge (Extra route strings):", words_not_in_locales, 'red')

    # Exit with error code if missing translations are found in locales
    if words_not_in_locales:
        sys.exit(1)

if __name__ == "__main__":
    main()
