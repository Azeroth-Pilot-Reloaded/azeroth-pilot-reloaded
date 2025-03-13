import os
import re
import requests
from dotenv import load_dotenv
from termcolor import colored
import sys

load_dotenv()

#############################################################################
#############################################################################

def fetch_translations_from_curseforge(api_url, api_key):
    headers = {
        'X-API-TOKEN': api_key
    }
    response = requests.get(api_url, headers=headers)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch translations: {response.status_code}")

    return response.text

def set_localization_url(slug, cf_token, project_site):
    if slug and cf_token and project_site:
        return f"{project_site}/api/projects/{slug}/localization/export?export-type=GlobalStrings&unlocalized=Ignore"
    return None

def get_locales_keys(locales):
    keys = []
    lines = locales.split('\n')
    for line in lines:
        if re.match(r'^[A-Z0-9_]', line):
            if '=' in line:
                key = line.split('=')[0].strip()
                keys.append(key)
    return keys

def get_lua_files_from_directories(directories):
    lua_files = []
    for directory in directories:
        for root, dirs, files in os.walk(directory):
            # Exclu 'libs'
            dirs[:] = [d for d in dirs if d != 'libs']

            for file in files:
                if file.endswith('.lua'):
                    lua_files.append(os.path.join(root, file))
    return lua_files

def load_string_from_file(file_path):
    if not os.path.isfile(file_path):
        raise FileNotFoundError(f"The file {file_path} does not exist.")
    with open(file_path, 'r', encoding='utf-8') as file:
        words = [line.strip() for line in file if line.strip()]
    return words


def check_string_in_lua_files(word_list, file_list, banned_list):
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

def print_list_with_color(title, items, color):
    print(colored(title, color))
    for item in items:
        print(colored(f"- {item}", color))

#############################################################################
#############################################################################


# Load environment variables
slug = 618667
cf_token = os.getenv('CF_TOKEN')
project_site = "https://wow.curseforge.com"
directories = ['./Routes', './APR-Core']

# Define banned list
banned_list = ['_42_COMMAND']

# Generate CurseForge API URL
api_url = set_localization_url(slug, cf_token, project_site)
if not api_url:
    raise Exception("Missing CurseForge API token and/or project id is invalid.")

# Fetch translations from CurseForge
locales = fetch_translations_from_curseforge(api_url, cf_token)
word_list = get_locales_keys(locales)


# Fetch Lua files from directories
file_list = get_lua_files_from_directories(directories)

words_not_found = check_string_in_lua_files(word_list, file_list, banned_list)
words_not_in_locales = check_route_string_existing_in_locales(word_list, './Routes')

print_list_with_color("Translation not used:", words_not_found, 'yellow')
print_list_with_color("Translation key not present on curseforge:", words_not_in_locales, 'red')

if words_not_in_locales:
    sys.exit(1)
