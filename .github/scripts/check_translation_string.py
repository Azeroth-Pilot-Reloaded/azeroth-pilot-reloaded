import os
import re

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

def load_words_from_file(file_path):
    if not os.path.isfile(file_path):
        raise FileNotFoundError(f"The file {file_path} does not exist.")
    with open(file_path, 'r', encoding='utf-8') as file:
        words = [line.strip() for line in file if line.strip()]
    return words

def check_words_in_lua_files(word_list, file_list):
    words_not_found = []

    for word in word_list:
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

def check_lua_files_in_word_list(word_list, directory):
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

word_file_path = './.github/scripts/wordList.txt'
directories = ['./Routes', './APR-Core']

word_list = load_words_from_file(word_file_path)

file_list = get_lua_files_from_directories(directories)

words_not_found = check_words_in_lua_files(word_list, file_list)

print("Translation not used:", words_not_found)

# Check Lua files in './Routes' for words not in word list
words_not_in_word_list = check_lua_files_in_word_list(word_list, './Routes')
print("Translation key not present on curseforge:", words_not_in_word_list)
